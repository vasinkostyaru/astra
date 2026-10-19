#!/usr/bin/env bash
# Собирает debug APK и ставит его на подключённый телефон. Без release и подписи.
set -euo pipefail
cd "$(dirname "$0")/.."
ADB=~/Android/Sdk/platform-tools/adb
mkdir -p build
godot --headless --path . --import >/dev/null 2>&1
godot --headless --path . --export-debug "Android" build/avgust-debug.apk
"$ADB" install -r build/avgust-debug.apk
"$ADB" shell monkey -p com.vasinkostya.avgust -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
echo "Готово: игра установлена и запущена."
