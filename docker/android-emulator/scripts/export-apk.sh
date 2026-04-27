#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <package.name> [output_dir]"
  exit 1
fi

PACKAGE_NAME="$1"
OUTPUT_DIR="${2:-/home/docker-projects/android-emulator/apk-exports}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$OUTPUT_DIR/$PACKAGE_NAME"

echo "Connecting ADB client in ws-scrcpy container..."
docker compose -f "$SERVICE_DIR/docker-compose.yml" exec -T ws-scrcpy sh -lc "adb connect android-emulator:5555 >/dev/null 2>&1 || true"

echo "Resolving APK paths for $PACKAGE_NAME ..."
APK_PATHS="$(docker compose -f "$SERVICE_DIR/docker-compose.yml" exec -T ws-scrcpy sh -lc "adb shell pm path \"$PACKAGE_NAME\" | tr -d '\r'" | sed -n 's/^package://p')"

if [[ -z "$APK_PATHS" ]]; then
  echo "No APK paths found. Is the app installed in the emulator?"
  exit 1
fi

echo "$APK_PATHS" | while IFS= read -r apk_path; do
  apk_file="$(basename "$apk_path")"
  echo "Pulling $apk_path ..."
  docker compose -f "$SERVICE_DIR/docker-compose.yml" exec -T ws-scrcpy sh -lc "adb pull \"$apk_path\" /tmp/$apk_file >/dev/null"
  docker compose -f "$SERVICE_DIR/docker-compose.yml" cp "ws-scrcpy:/tmp/$apk_file" "$OUTPUT_DIR/$PACKAGE_NAME/$apk_file" >/dev/null
  docker compose -f "$SERVICE_DIR/docker-compose.yml" exec -T ws-scrcpy sh -lc "rm -f /tmp/$apk_file"
done

echo "APK export completed: $OUTPUT_DIR/$PACKAGE_NAME"
