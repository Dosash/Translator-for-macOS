#!/bin/bash
# Сборка Translator.app из Swift-пакета.
set -euo pipefail
cd "$(dirname "$0")"

echo "→ Компиляция (release, universal: arm64 + x86_64)…"
swift build -c release --arch arm64 --arch x86_64

APP="Translator.app"
# При сборке с несколькими --arch SwiftPM кладёт universal-бинарник
# в .build/apple/Products/Release, а не в .build/release.
if [ -f ".build/apple/Products/Release/Translator" ]; then
  BINARY=".build/apple/Products/Release/Translator"
else
  BINARY=".build/release/Translator"
fi
ENTITLEMENTS="Translator.entitlements"
PRIVACY_MANIFEST="Sources/Translator/Resources/PrivacyInfo.xcprivacy"

if [ ! -f AppIcon.icns ]; then
  echo "→ Генерация иконки приложения…"
  swift make_icon.swift
fi

echo "→ Сборка бандла ${APP}…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Translator"
cp Info.plist "$APP/Contents/Info.plist"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
if [ -f "$PRIVACY_MANIFEST" ]; then
  cp "$PRIVACY_MANIFEST" "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
fi
printf 'APPL????' > "$APP/Contents/PkgInfo"
xattr -cr "$APP" 2>/dev/null || true

echo "→ Архитектуры бинарника:"
lipo -info "$APP/Contents/MacOS/Translator" || true

echo "→ Подпись…"
IDENTITY="${SIGNING_IDENTITY:-}"
if [ -z "$IDENTITY" ]; then
  IDENTITY=$(security find-identity -v -p codesigning | awk -F '"' '/Apple Development/ {print $2; exit}')
fi

SIGN_ARGS=(--force --options runtime)
if [ -f "$ENTITLEMENTS" ]; then
  SIGN_ARGS+=(--entitlements "$ENTITLEMENTS")
fi

if [ -n "$IDENTITY" ]; then
  # Постоянный сертификат: разрешения macOS переживают пересборки.
  echo "  Сертификат: $IDENTITY"
  codesign "${SIGN_ARGS[@]}" --sign "$IDENTITY" "$APP"
else
  echo "  Сертификат не найден — одноразовая (ad-hoc) подпись."
  codesign "${SIGN_ARGS[@]}" --sign - "$APP"
fi

# Обновляем кэш системных служб, чтобы «Перевести выделенный текст»
# появилась в меню Службы без перелогина.
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo "✓ Готово: $(pwd)/$APP"
echo "  Запуск: open \"$APP\""
