#!/bin/sh
set -e

echo "Waiting for Postgres at $DB_HOST:$DB_PORT..."
until pg_isready -h "${DB_HOST:-db}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" >/dev/null 2>&1; do
  sleep 1
done
echo "Postgres is ready."

mix ecto.create || true
mix ecto.migrate || true

exec mix phx.server

