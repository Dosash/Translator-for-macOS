#!/bin/bash
# Сборка Translator.app из Swift-пакета.
set -euo pipefail
cd "$(dirname "$0")"

echo "→ Компиляция (release)…"
swift build -c release

APP="Translator.app"
BINARY=".build/release/Translator"

if [ ! -f AppIcon.icns ]; then
  echo "→ Генерация иконки приложения…"
  swift make_icon.swift
fi

echo "→ Сборка бандла $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Translator"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"
xattr -cr "$APP" 2>/dev/null || true

echo "→ Подпись…"
IDENTITY=$(security find-identity -v -p codesigning | awk -F '"' '/Apple Development/ {print $2; exit}')
if [ -n "$IDENTITY" ]; then
  # Постоянный сертификат: разрешения macOS переживают пересборки.
  echo "  Сертификат: $IDENTITY"
  codesign --force --sign "$IDENTITY" "$APP"
else
  echo "  Сертификат не найден — одноразовая (ad-hoc) подпись."
  codesign --force --sign - "$APP"
fi

# Обновляем кэш системных служб, чтобы «Перевести выделенный текст»
# появилась в меню Службы без перелогина.
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo "✓ Готово: $(pwd)/$APP"
echo "  Запуск: open \"$APP\""
