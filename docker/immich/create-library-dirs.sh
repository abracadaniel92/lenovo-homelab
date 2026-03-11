#!/bin/bash
# Create Immich library subdirs and .immich markers on the 3TB path.
# Run once: sudo ./create-library-dirs.sh

set -e
BASE="${1:-/mnt/ssd_1tb/immich-library}"
for dir in upload library thumbs encoded-video profile backups; do
  mkdir -p "$BASE/$dir"
  touch "$BASE/$dir/.immich"
done
echo "Created subdirs and .immich markers under $BASE"
ls -la "$BASE"
