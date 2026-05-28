#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="worktree-base"
THEME_NAME="clone-theme"

cd "$(dirname "$0")"

echo "==> brew dependencies"
command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh"; exit 1; }
for pkg in composer wget pipx; do
  brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg"
done
brew list ddev >/dev/null 2>&1 || brew install ddev/ddev/ddev

echo "==> shot-scraper (headless Chrome screenshot tool)"
command -v shot-scraper >/dev/null || pipx install shot-scraper
shot-scraper install

echo "==> scaffold Bedrock"
if [ ! -f composer.json ]; then
  composer create-project roots/bedrock . --no-interaction --no-install
  composer install
fi

echo "==> generate .env from template + salts"
if [ ! -f .env ]; then
  cp .env.example .env
  SALTS=$(curl -sS https://roots.io/salts.html | sed -n "s/^.*\(define('[A-Z_]*',\s*'[^']*'\)).*/\1)/p")
  if [ -n "$SALTS" ]; then
    # Bedrock uses .env-style key=value, not define(); convert
    echo "$SALTS" | sed -E "s/define\('([A-Z_]+)',\s*'([^']*)'\);/\1='\2'/" >> .env
  fi
fi

echo "==> DDEV start"
ddev start

echo "==> WP core install"
ddev wp core install \
  --url="https://${PROJECT_NAME}.ddev.site/wp" \
  --title="WP Clone Studio" \
  --admin_user=admin \
  --admin_password=admin \
  --admin_email=admin@example.com \
  --skip-email || true

echo "==> Sage 11 theme"
if [ ! -d "web/app/themes/${THEME_NAME}" ]; then
  (cd web/app/themes && composer create-project roots/sage "${THEME_NAME}" --no-interaction)
  (cd "web/app/themes/${THEME_NAME}" && npm install && npm run build)
  ddev wp theme activate "${THEME_NAME}"
fi

echo "==> quality tooling"
composer require --dev \
  wp-coding-standards/wpcs:^3 \
  szepeviktor/phpstan-wordpress \
  dealerdirect/phpcodesniffer-composer-installer || true

echo
echo "Done."
echo "Site:  https://${PROJECT_NAME}.ddev.site"
echo "Admin: https://${PROJECT_NAME}.ddev.site/wp/wp-admin  (admin/admin)"
echo
echo "Next:  /wp-clone <old-site-url>   # to start cloning"
