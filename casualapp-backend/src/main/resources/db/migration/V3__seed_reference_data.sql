-- V3__seed_reference_data.sql

-- Roles vocabulary
INSERT INTO roles (role_name)
VALUES
  ('Banquet Waiter'),
  ('Kitchen Helper'),
  ('Bartender')
ON CONFLICT (role_name) DO NOTHING;

-- Venues (district_id is a placeholder UUID since districts table not defined yet)
INSERT INTO venues (name, district_id, address_text)
VALUES
  ('Harbour View Hotel', '00000000-0000-0000-0000-000000000001', '1 Test Street, Central'),
  ('Kowloon Bay Convention Center', '00000000-0000-0000-0000-000000000002', '99 Example Road, Kowloon Bay')
ON CONFLICT (name) DO NOTHING;

-- Create 2 published jobs posted by the coordinator
WITH coord AS (
  SELECT user_id FROM users WHERE phone_number = '+85290000010'
),
v1 AS (
  SELECT venue_id FROM venues WHERE name = 'Harbour View Hotel'
),
v2 AS (
  SELECT venue_id FROM venues WHERE name = 'Kowloon Bay Convention Center'
),
r_waiter AS (
  SELECT role_id FROM roles WHERE role_name = 'Banquet Waiter'
),
r_kitchen AS (
  SELECT role_id FROM roles WHERE role_name = 'Kitchen Helper'
)
INSERT INTO jobs (
  venue_id, role_id, posted_by_user_id,
  start_at, end_at, cutoff_at, lock_at, status,
  total_slots, reserved_slots,
  pay_amount, pay_unit, payment_method,
  job_type, job_description, dress_code_text,
  created_at, published_at
)
SELECT
  v1.venue_id, r_waiter.role_id, coord.user_id,
  now() + interval '2 days',
  now() + interval '2 days' + interval '6 hours',
  now() + interval '1 days',
  now() + interval '2 days' - interval '2 hours',
  'PUBLISHED',
  6, 2,
  700.00, 'PER_SHIFT', 'FPS',
  'Banquet', 'Banquet event shift', 'Black pants, black shoes',
  now(), now()
FROM coord, v1, r_waiter
ON CONFLICT DO NOTHING;

WITH coord AS (
  SELECT user_id FROM users WHERE phone_number = '+85290000010'
),
v2 AS (
  SELECT venue_id FROM venues WHERE name = 'Kowloon Bay Convention Center'
),
r_kitchen AS (
  SELECT role_id FROM roles WHERE role_name = 'Kitchen Helper'
)
INSERT INTO jobs (
  venue_id, role_id, posted_by_user_id,
  start_at, end_at, cutoff_at, lock_at, status,
  total_slots, reserved_slots,
  pay_amount, pay_unit, payment_method,
  job_type, job_description,
  created_at, published_at
)
SELECT
  v2.venue_id, r_kitchen.role_id, coord.user_id,
  now() + interval '3 days',
  now() + interval '3 days' + interval '5 hours',
  now() + interval '2 days',
  now() + interval '3 days' - interval '2 hours',
  'PUBLISHED',
  4, 1,
  650.00, 'PER_SHIFT', 'TRANSFER',
  'Kitchen', 'Kitchen helper shift',
  now(), now()
FROM coord, v2, r_kitchen
ON CONFLICT DO NOTHING;