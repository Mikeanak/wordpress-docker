#!/usr/bin/env bash
set -euo pipefail

log(){ echo "[entrypoint] $*"; }

ENV_FILE=${ENV_FILE:-/config/env.yaml}
WP_PATH=${WP_PATH:-/var/www/wordpress}
CONTENT_DIR=${CONTENT_DIR:-/opt/content}
PMA_DIR=${PMA_DIR:-/var/www/phpmyadmin}
SITE_URL_DEFAULT=${SITE_URL:-http://localhost:8080}

parse_env() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "Env file $ENV_FILE not found" >&2
    exit 1
  fi
  eval "$(python3 - <<'PY'
import os, yaml, sys
path=os.environ.get('ENV_FILE')
with open(path) as f:
    data=yaml.safe_load(f) or {}
required=['db_host','db_port','db_name','db_user','db_password']
missing=[k for k in required if not data.get(k)]
if missing:
    sys.exit(f"Missing keys in env yaml: {', '.join(missing)}")
for k,v in data.items():
    env_key=k.upper()
    print(f'export {env_key}="{v}"')
PY
  )"
  : "${DB_PORT:=3306}"
  : "${SITE_URL:=$SITE_URL_DEFAULT}"
  export DB_PORT SITE_URL
}

wait_for_db() {
  log "Waiting for MySQL at $DB_HOST:$DB_PORT..."
  for i in {1..30}; do
    if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -e "select 1" "$DB_NAME" >/dev/null 2>&1; then
      log "MySQL is ready"
      return
    fi
    sleep 2
  done
  echo "Could not connect to database after retries" >&2
  exit 1
}

configure_phpmyadmin() {
  # export blowfish secret if saved at build time
  if [ -z "${PMA_BLOWFISH_SECRET:-}" ] && [ -f /opt/pma-blowfish-secret.txt ]; then
    export PMA_BLOWFISH_SECRET="$(cat /opt/pma-blowfish-secret.txt)"
  fi
  cat > "$PMA_DIR/config.inc.php" <<'PHP'
<?php
$cfg['blowfish_secret'] = getenv('PMA_BLOWFISH_SECRET');
$i = 1;
$cfg['Servers'][$i]['host'] = getenv('DB_HOST');
$cfg['Servers'][$i]['port'] = getenv('DB_PORT');
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['AllowNoPassword'] = false;
?>
PHP
}

configure_wp() {
  cd "$WP_PATH"
  if [ ! -f wp-config.php ]; then
    log "Generating wp-config.php"
    wp --allow-root config create --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASSWORD" --dbhost="$DB_HOST:$DB_PORT" --skip-check --force
    wp --allow-root config set WP_HOME "$SITE_URL" --type=constant
    wp --allow-root config set WP_SITEURL "$SITE_URL" --type=constant
    wp --allow-root config set FS_METHOD "direct" --type=constant
    wp --allow-root config set WP_DEBUG false --type=constant --raw
    log "WP config created"
  fi
}

seed_wordpress() {
  cd "$WP_PATH"
  if ! wp --allow-root core is-installed >/dev/null 2>&1; then
    log "Installing WordPress core"
    log "SITE_URL: $SITE_URL"
    log "WP_ADMIN_USER: ${WP_ADMIN_USER:-admin}"
    log "WP_ADMIN_PASSWORD: ${WP_ADMIN_PASSWORD:-changeme123!}"
    log "WP_ADMIN_EMAIL: ${WP_ADMIN_EMAIL:-admin@example.com}"
    wp --allow-root core install --url="$SITE_URL" --title="John Doe" \
      --admin_user="${WP_ADMIN_USER:-admin}" \
      --admin_password="${WP_ADMIN_PASSWORD:-changeme123!}" \
      --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}"
  fi
  log "Seeding WordPress with landing page and featured image"
  bash /opt/scripts/seed_photo.sh
}

restore_db() {
  local tarball="$1"
  bash /opt/scripts/restore_db.sh "$tarball"
}

main() {
  parse_env
  configure_phpmyadmin
  chown -R www-data:www-data "$WP_PATH"

  RESTORE=""
  SKIP_DB=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --restore)
        RESTORE="$2"; shift 2;;
      --skip-db|--no-db)
        SKIP_DB=true; shift;;
      *)
        break;;
    esac
  done

  if [ "$SKIP_DB" = false ]; then
    wait_for_db
    configure_wp
    if [ -n "$RESTORE" ]; then
      restore_db "$RESTORE"
    else
      seed_wordpress
    fi
  else
    log "Skipping DB init per flag"
  fi

  log "Starting Apache"
  exec apache2-foreground
}

main "$@"
