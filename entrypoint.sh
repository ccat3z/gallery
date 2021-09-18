#! /bin/bash

set -e

log () {
    echo -e "\e[36m>>>\e[0m $*"
}

DCIM_PATH="${DCIM_PATH:=/data}"
MEDIA_FOLDER=/var/lib/gallery

[ -d "$MEDIA_FOLDER" ] || mkdir -p "$MEDIA_FOLDER"

MEDIA_SUBFOLDERS_COUNT=0
while IFS= read -r -d '' src
do
  MEDIA_SUBFOLDERS_COUNT=$((MEDIA_SUBFOLDERS_COUNT + 1))

  dir=$(basename "$src")
  tgt=$MEDIA_FOLDER/$dir
  log "Loading sub directory '$dir'..."

  if [ -f "$src/gocryptfs.conf" ]; then
    passwd_var=GOCRYPTFS_PASS_$dir
    passwd="${!passwd_var}"
    [ -d "$tgt" ] || mkdir -p "$tgt"
    gocryptfs -fg -passfile <(echo "$passwd") -ro "$src" "$tgt" &
    continue
  fi

  ln -sTf "$src" "$tgt"
done < <(find "$DCIM_PATH" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -print0)

if [ "$MEDIA_SUBFOLDERS_COUNT" = 0 ]; then
  log "No subfolder found"
  exit 1
fi

cd /app

# For debug
if [ -n "$*" ]; then
    exec "$@"
fi

node ./src/backend/index --expose-gc --config-path=/app/data/config/config.json \
    --Client-authenticationRequired=false \
    --Client-Sharing-enabled=false \
    --Server-Media-folder="$MEDIA_FOLDER" &

wait -n
