#!/usr/bin/env bash
# Собирает неподписанный IPA для установки через Sideloadly или AltStore.
# Требуется macOS с установленным Xcode и CocoaPods.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS-сборка возможна только на macOS." >&2
  exit 1
fi

flutter pub get
flutter build ios --release --no-codesign

APP_PATH="build/ios/iphoneos/Runner.app"
PAYLOAD_DIR="build/ios/ipa_payload"
IPA_PATH="$PWD/build/ios/norma-unsigned.ipa"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Не найден $APP_PATH — сборка не удалась." >&2
  exit 1
fi

rm -rf "$PAYLOAD_DIR" "$IPA_PATH"
mkdir -p "$PAYLOAD_DIR/Payload"
cp -R "$APP_PATH" "$PAYLOAD_DIR/Payload/"
(cd "$PAYLOAD_DIR" && zip -qry "$IPA_PATH" Payload)

echo "Готово: $IPA_PATH"
