#!/bin/sh
set -e

# Defaults (can be overridden via environment variables in compose)
: "${APP_DB:=app_db}"
: "${APP_USER:=app_user}"
: "${APP_PASSWORD:=app_password}"

echo "Initializing application database and user..."

# Use the bootstrap superuser to run setup against the initial database
psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname   "$POSTGRES_DB" <<-EOSQL
DO $$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '${APP_USER}') THEN
      CREATE ROLE ${APP_USER} LOGIN PASSWORD '${APP_PASSWORD}';
   END IF;
END
$$;

-- Ensure ownership and privileges on the application database
ALTER DATABASE "${APP_DB}" OWNER TO ${APP_USER};
GRANT ALL PRIVILEGES ON DATABASE "${APP_DB}" TO ${APP_USER};
EOSQL

# Ensure schema ownership and default privileges inside the app DB
psql -v ON_ERROR_STOP=1 \
  --username "$POSTGRES_USER" \
  --dbname   "$APP_DB" <<-EOSQL
ALTER SCHEMA public OWNER TO ${APP_USER};
GRANT ALL ON SCHEMA public TO ${APP_USER};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${APP_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${APP_USER};
EOSQL

echo "Initialization complete."
