#!/usr/bin/env bash


CONFIG="$1/config.json"



wallpaper_path=$(jq -r '.wallpaper_path' "$CONFIG")
cache_path=$(jq -r '.cache_path' "$CONFIG")
cache_batch_size=$(jq -r '.cache_batch_size' "$CONFIG")

mkdir -p "$cache_path"

echo "Wallpaper path: $wallpaper_path"
echo "Cache path: $cache_path"

find "$wallpaper_path" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" \
\) | while read -r img; do

    filename=$(basename "$img")
    out="$cache_path/$filename"

    if [[ -f "$out" ]]; then
        continue
    fi

    echo "Generating thumbnail for $filename"


    # Tiles are 500px tall and cropped (PreserveAspectCrop), so thumbs need >= 500px height.
    # x1000> = 2x headroom for sharpness; '>' only shrinks, never upscales small sources.
    # `magick` replaces the IM6 `convert` alias (deprecated in ImageMagick 7).
    magick "$img" -thumbnail 'x1000>' -strip -quality 90 "$out" &

    # Only limit jobs if batch_size > 0
    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n
        done
    fi

done

wait

echo "Thumbnail generation complete."
