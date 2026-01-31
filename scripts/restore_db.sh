#!/usr/bin/env bash
set -euo pipefail
# Restore database from a tarball containing dump.sql
TARBALL=${1:?"usage: restore_db.sh <path-to-tar.gz>"}
ENV_FILE=${ENV_FILE:-/config/env.yaml}

if [ ! -f "$ENV_FILE" ]; then
  echo "Env file $ENV_FILE not found" >&2
  exit 1
fi

# Parse env.yaml for DB connection
export $(python3 - <<'PY'
import os, yaml
path=os.environ['ENV_FILE']
data=yaml.safe_load(open(path)) or {}
required=['db_host','db_port','db_name','db_user','db_password']
missing=[k for k in required if not data.get(k)]
if missing:
    raise SystemExit(f"Missing keys: {', '.join(missing)}")
for k,v in data.items():
    print(f"{k.upper()}={v}")
PY
)

if [ ! -f "$TARBALL" ]; then
  echo "Tarball $TARBALL not found" >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

tar -xzf "$TARBALL" -C "$TMPDIR"
DUMP="$TMPDIR/dump.sql"
if [ ! -f "$DUMP" ]; then
  echo "dump.sql not found inside tarball" >&2
  exit 1
fi

mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$DUMP"
