-- V1__init.sql

-- UUID generator
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Case-insensitive phone numbers (optional but helpful)
CREATE EXTENSION IF NOT EXISTS citext;

-- ---------- ENUMS ----------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('WORKER', 'COORDINATOR', 'ADMIN');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
    CREATE TYPE user_status AS ENUM ('ACTIVE', 'DISABLED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
    CREATE TYPE job_status AS ENUM ('DRAFT', 'PUBLISHED', 'LOCKED', 'COMPLETED', 'CANCELLED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'signup_state') THEN
    CREATE TYPE signup_state AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'REMOVED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'signup_fill_type') THEN
    CREATE TYPE signup_fill_type AS ENUM ('NORMAL', 'RESERVED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pay_unit') THEN
    CREATE TYPE pay_unit AS ENUM ('PER_SHIFT', 'HOURLY');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE payment_method AS ENUM ('FPS', 'TRANSFER', 'CASH');
  END IF;
END$$;

-- ---------- USERS ----------
CREATE TABLE IF NOT EXISTS users (
  user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number   CITEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  role           user_role NOT NULL,
  status         user_status NOT NULL DEFAULT 'ACTIVE',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Worker-only 1:1
CREATE TABLE IF NOT EXISTS worker_profile (
  user_id     UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  real_name   TEXT NULL,
  hkid        TEXT NULL,
  level_id    UUID NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Optional uniqueness if you require HKID unique
CREATE UNIQUE INDEX IF NOT EXISTS uq_worker_profile_hkid
  ON worker_profile(hkid)
  WHERE hkid IS NOT NULL;

-- ---------- VENUES ----------
CREATE TABLE IF NOT EXISTS venues (
  venue_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL UNIQUE,
  district_id   UUID NOT NULL,
  address_text  TEXT NULL
);

-- ---------- ROLES (job role vocabulary) ----------
CREATE TABLE IF NOT EXISTS roles (
  role_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_name  TEXT NOT NULL UNIQUE
);

-- ---------- JOBS ----------
CREATE TABLE IF NOT EXISTS jobs (
  job_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id            UUID NOT NULL REFERENCES venues(venue_id),
  role_id             UUID NOT NULL REFERENCES roles(role_id),
  posted_by_user_id   UUID NOT NULL REFERENCES users(user_id),

  start_at            TIMESTAMPTZ NOT NULL,
  end_at              TIMESTAMPTZ NOT NULL,
  cutoff_at           TIMESTAMPTZ NOT NULL,
  lock_at             TIMESTAMPTZ NOT NULL,
  status              job_status NOT NULL DEFAULT 'DRAFT',

  total_slots         INT NOT NULL,
  reserved_slots      INT NOT NULL DEFAULT 0,

  pay_amount          NUMERIC(10,2) NOT NULL,
  pay_unit            pay_unit NOT NULL DEFAULT 'PER_SHIFT',
  payment_method      payment_method NOT NULL,

  job_type                    TEXT NULL,
  job_description             TEXT NULL,
  dress_code_text             TEXT NULL,
  special_requests_text       TEXT NULL,
  offers_text                 TEXT NULL,
  language_requirements_text  TEXT NULL,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at        TIMESTAMPTZ NULL,

  CONSTRAINT ck_jobs_time_window CHECK (start_at < end_at),
  CONSTRAINT ck_jobs_slots_min CHECK (total_slots >= 1),
  CONSTRAINT ck_jobs_reserved_nonneg CHECK (reserved_slots >= 0),
  CONSTRAINT ck_jobs_reserved_le_total CHECK (reserved_slots <= total_slots),
  CONSTRAINT ck_jobs_cutoff_le_start CHECK (cutoff_at <= start_at),
  CONSTRAINT ck_jobs_lock_le_start CHECK (lock_at <= start_at)
);

CREATE INDEX IF NOT EXISTS ix_jobs_time ON jobs(start_at, end_at);

-- ---------- JOB SIGNUPS ----------
CREATE TABLE IF NOT EXISTS job_signups (
  signup_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id              UUID NOT NULL REFERENCES jobs(job_id) ON DELETE CASCADE,
  worker_user_id      UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

  state               signup_state NOT NULL,
  fill_type           signup_fill_type NOT NULL,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

  actioned_by_user_id UUID NULL REFERENCES users(user_id),
  action_reason       TEXT NULL,

  CONSTRAINT uq_job_signups_job_worker UNIQUE (job_id, worker_user_id)
);

CREATE INDEX IF NOT EXISTS ix_job_signups_worker_state_job
  ON job_signups(worker_user_id, state, job_id);

CREATE INDEX IF NOT EXISTS ix_job_signups_job_state_fill
  ON job_signups(job_id, state, fill_type);

-- ---------- JOB ATTENDANCE ----------
CREATE TABLE IF NOT EXISTS job_attendance (
  attendance_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id              UUID NOT NULL REFERENCES jobs(job_id) ON DELETE CASCADE,
  worker_user_id      UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

  status              TEXT NOT NULL,
  late_minutes        INT NULL,
  notes               TEXT NULL,

  recorded_by_user_id UUID NOT NULL REFERENCES users(user_id),
  recorded_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT uq_job_attendance_job_worker UNIQUE (job_id, worker_user_id),
  CONSTRAINT ck_attendance_late_minutes_nonneg CHECK (late_minutes IS NULL OR late_minutes >= 0)
);

-- ---------- EVENT LOG (append-only) ----------
CREATE TABLE IF NOT EXISTS event_log (
  event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type      TEXT NOT NULL,
  actor_user_id   UUID NULL REFERENCES users(user_id),
  target_table    TEXT NOT NULL,
  target_id       UUID NOT NULL,

  job_id          UUID NULL REFERENCES jobs(job_id) ON DELETE SET NULL,
  worker_user_id  UUID NULL REFERENCES users(user_id) ON DELETE SET NULL,

  message         TEXT NOT NULL,
  metadata_json   JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_event_log_target ON event_log(target_table, target_id, created_at);
CREATE INDEX IF NOT EXISTS ix_event_log_job ON event_log(job_id, created_at);
CREATE INDEX IF NOT EXISTS ix_event_log_worker ON event_log(worker_user_id, created_at);
CREATE INDEX IF NOT EXISTS ix_event_log_type ON event_log(event_type, created_at);

-- ---------- AUTH SESSIONS (for JWT refresh, single-device) ----------
CREATE TABLE IF NOT EXISTS user_sessions (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,

  refresh_token_hash TEXT NOT NULL,
  refresh_expires_at TIMESTAMPTZ NOT NULL,

  revoked_at         TIMESTAMPTZ NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at       TIMESTAMPTZ NULL,

  user_agent         TEXT NULL,
  ip_address         TEXT NULL,

  CONSTRAINT uq_user_sessions_user_id UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS ix_user_sessions_refresh_expires_at
  ON user_sessions(refresh_expires_at);