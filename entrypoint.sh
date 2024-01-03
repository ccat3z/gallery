#! /bin/bash

set -e

log () {
    echo -e "\e[36m>>>\e[0m $*"
}

MEDIA_FOLDER=/app/data/images

if [ -z "$GALLERY_PATH" ]; then
    log "\$GALLERY_PATH is empty"
    exit 1
fi
[ -d "$MEDIA_FOLDER" ] || mkdir -p "$MEDIA_FOLDER"

MEDIA_SUBFOLDERS_COUNT=0
while IFS= read -r -d '' src
do
  MEDIA_SUBFOLDERS_COUNT=$((MEDIA_SUBFOLDERS_COUNT + 1))

  dir=$(basename "$src")
  tgt=$MEDIA_FOLDER/$dir
  log "Loading sub directory '$dir'..."

  [ -d "$tgt" ] || mkdir -p "$tgt"
  if [ -f "$src/gocryptfs.conf" ]; then
    passwd_var=GOCRYPTFS_PASS_$dir
    passwd="${!passwd_var}"
    gocryptfs \
        -passfile <(echo "$passwd") \
        -rw \
        -allow_other \
        "$src" "$tgt"
  else
    mount --bind "$src" "$tgt"
  fi
done < <(find "$GALLERY_PATH" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -print0)

if [ "$MEDIA_SUBFOLDERS_COUNT" = 0 ]; then
  log "No subfolder found"
  exit 1
fi

exec node ./src/backend/index --expose-gc --config-path=/app/data/config/config.json
