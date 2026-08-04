#!/bin/bash
# Сборка .pkg для загрузки в App Store Connect.
set -euo pipefail

cd "$(dirname "$0")"

APP_SIGNING_IDENTITY="${APP_STORE_APP_SIGNING_IDENTITY:-}"
INSTALLER_SIGNING_IDENTITY="${APP_STORE_INSTALLER_SIGNING_IDENTITY:-}"

if [ -z "$APP_SIGNING_IDENTITY" ] || [ -z "$INSTALLER_SIGNING_IDENTITY" ]; then
  cat <<'EOF'
Нужны сертификаты Mac App Store:

  APP_STORE_APP_SIGNING_IDENTITY="3rd Party Mac Developer Application: ..."
  APP_STORE_INSTALLER_SIGNING_IDENTITY="3rd Party Mac Developer Installer: ..."

Пример:

  APP_STORE_APP_SIGNING_IDENTITY="3rd Party Mac Developer Application: Your Name (TEAMID)" \
  APP_STORE_INSTALLER_SIGNING_IDENTITY="3rd Party Mac Developer Installer: Your Name (TEAMID)" \
  ./build_app_store_pkg.sh
EOF
  exit 2
fi

SIGNING_IDENTITY="$APP_SIGNING_IDENTITY" ./build_app.sh

mkdir -p dist
productbuild \
  --component Translator.app /Applications \
  --sign "$INSTALLER_SIGNING_IDENTITY" \
  dist/Translator-AppStore.pkg

echo "✓ App Store package: $(pwd)/dist/Translator-AppStore.pkg"
