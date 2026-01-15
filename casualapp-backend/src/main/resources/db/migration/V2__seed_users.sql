-- V2__seed_admins.sql
-- Example-only seed for testing.
-- Seeds 2 ADMIN accounts.
-- NOTE: Replace the password hashes with real BCrypt hashes that your app uses.

INSERT INTO users (phone_number, password_hash, role, status)
VALUES
  ('+85290000001', '{BCrypt}$2a$10$ipNJOIKdQ9kZMT6HF1yq9.S6UiDxiWJDNvpXKxyBSXK4rf7S.DEnK', 'ADMIN', 'ACTIVE'),
  ('+85290000002', '{BCrypt}$2a$10$ipNJOIKdQ9kZMT6HF1yq9.S6UiDxiWJDNvpXKxyBSXK4rf7S.DEnK', 'ADMIN', 'ACTIVE')
ON CONFLICT (phone_number) DO UPDATE
SET
  password_hash = EXCLUDED.password_hash,
  role          = EXCLUDED.role,
  status        = EXCLUDED.status;