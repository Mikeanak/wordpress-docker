#!/usr/bin/env bash
set -euo pipefail
# Seed WordPress with a landing page and featured image
WP_PATH=${WP_PATH:-/var/www/wordpress}
CONTENT_DIR=${CONTENT_DIR:-/opt/content}
SITE_URL=${SITE_URL:-http://localhost:8080}

cd "$WP_PATH"

# Import media and capture its URL
ATTACH_ID=$(wp --allow-root media import "$CONTENT_DIR/john-doe.png" --title="John Doe" --porcelain)
IMAGE_URL=$(wp --allow-root post get "$ATTACH_ID" --field=guid)


# Build page content with inlined CSS and substituted image URL, write to temp file
HTML=$(cat "$CONTENT_DIR/landing-page.html")
HTML=${HTML//\{\{IMAGE_URL\}\}/$IMAGE_URL}
CSS=$(cat "$CONTENT_DIR/style.css")
TMP_PAGE=$(mktemp)
echo "<style>${CSS}</style>${HTML}" > "$TMP_PAGE"


# Pass post content as a value to --post_content
PAGE_ID=$(wp --allow-root post create --post_type=page --post_title="John Doe" --post_status=publish --porcelain --post_content="$(<"$TMP_PAGE")")

rm -f "$TMP_PAGE"

wp --allow-root post meta update "$PAGE_ID" _thumbnail_id "$ATTACH_ID"
wp --allow-root option update show_on_front page
wp --allow-root option update page_on_front "$PAGE_ID"
