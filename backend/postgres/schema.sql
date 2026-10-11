-- PostgreSQL shape matching the tablet SQLite schema.
-- Not applied by the app. Intended for a later Supabase project.
-- Application ids are UUID strings generated on the device.

CREATE TABLE products (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  sku text,
  created_at timestamptz NOT NULL
);

CREATE TABLE fridges (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  min_celsius double precision NOT NULL,
  max_celsius double precision NOT NULL
);

CREATE TABLE refrigeration_logs (
  id uuid PRIMARY KEY,
  movement_id uuid NOT NULL,
  product_id uuid NOT NULL REFERENCES products (id),
  product_name_snapshot text NOT NULL,
  fridge_id uuid NOT NULL REFERENCES fridges (id),
  event_type text NOT NULL CHECK (event_type IN ('check_in', 'check_out')),
  temperature_celsius double precision NOT NULL,
  occurred_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL
);

CREATE INDEX refrigeration_logs_movement_id_idx
  ON refrigeration_logs (movement_id);

CREATE TABLE alerts (
  id uuid PRIMARY KEY,
  severity text NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  kind text NOT NULL CHECK (kind IN ('temperature_out_of_range')),
  product_id uuid REFERENCES products (id),
  log_id uuid REFERENCES refrigeration_logs (id),
  message text NOT NULL,
  created_at timestamptz NOT NULL,
  acknowledged_at timestamptz
);

CREATE TABLE sync_outbox (
  id uuid PRIMARY KEY,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  operation text NOT NULL CHECK (operation IN ('insert')),
  payload_json jsonb NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'in_flight', 'synced', 'failed')),
  attempt_count integer NOT NULL DEFAULT 0,
  last_error text,
  created_at timestamptz NOT NULL
);

CREATE INDEX sync_outbox_status_created_at_idx
  ON sync_outbox (status, created_at);

CREATE VIEW open_holdings AS
SELECT
  ci.movement_id,
  ci.product_id,
  ci.product_name_snapshot AS product_name,
  ci.fridge_id,
  f.name AS fridge_name,
  ci.temperature_celsius AS check_in_temperature_celsius,
  ci.occurred_at AS checked_in_at
FROM refrigeration_logs ci
JOIN fridges f ON f.id = ci.fridge_id
WHERE ci.event_type = 'check_in'
  AND NOT EXISTS (
    SELECT 1
    FROM refrigeration_logs co
    WHERE co.movement_id = ci.movement_id
      AND co.event_type = 'check_out'
  );

CREATE OR REPLACE FUNCTION prevent_refrigeration_log_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'refrigeration_logs are immutable';
END;
$$;

CREATE TRIGGER refrigeration_logs_no_update
BEFORE UPDATE ON refrigeration_logs
FOR EACH ROW EXECUTE FUNCTION prevent_refrigeration_log_mutation();

CREATE TRIGGER refrigeration_logs_no_delete
BEFORE DELETE ON refrigeration_logs
FOR EACH ROW EXECUTE FUNCTION prevent_refrigeration_log_mutation();
