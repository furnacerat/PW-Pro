#!/bin/bash

# Configuration
SOURCE_IMAGE="$1"
TARGET_DIR="$2"

if [ -z "$SOURCE_IMAGE" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <source_image> <target_dir>"
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Define sizes
# Each entry: "filename|size"
ICON_SIZES=(
    "icon-20@2x.png|40"
    "icon-20@3x.png|60"
    "icon-29@2x.png|58"
    "icon-29@3x.png|87"
    "icon-40@2x.png|80"
    "icon-40@3x.png|120"
    "icon-60@2x.png|120"
    "icon-60@3x.png|180"
    "icon-76.png|76"
    "icon-76@2x.png|152"
    "icon-83.5@2x.png|167"
    "icon-1024.png|1024"
)

for entry in "${ICON_SIZES[@]}"; do
    IFS="|" read -r filename size <<< "$entry"
    echo "Generating $filename ($size x $size)..."
    sips -s format png -z "$size" "$size" "$SOURCE_IMAGE" --out "$TARGET_DIR/$filename" > /dev/null
done

# Create Contents.json
cat <<EOF > "$TARGET_DIR/Contents.json"
{
  "images" : [
    {
      "idiom" : "iphone",
      "size" : "20x20",
      "scale" : "2x",
      "filename" : "icon-20@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "20x20",
      "scale" : "3x",
      "filename" : "icon-20@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "2x",
      "filename" : "icon-29@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "29x29",
      "scale" : "3x",
      "filename" : "icon-29@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "2x",
      "filename" : "icon-40@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "40x40",
      "scale" : "3x",
      "filename" : "icon-40@3x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "2x",
      "filename" : "icon-60@2x.png"
    },
    {
      "idiom" : "iphone",
      "size" : "60x60",
      "scale" : "3x",
      "filename" : "icon-60@3x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "1x",
      "filename" : "icon-20.png"
    },
    {
      "idiom" : "ipad",
      "size" : "20x20",
      "scale" : "2x",
      "filename" : "icon-20@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "1x",
      "filename" : "icon-29.png"
    },
    {
      "idiom" : "ipad",
      "size" : "29x29",
      "scale" : "2x",
      "filename" : "icon-29@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "1x",
      "filename" : "icon-40.png"
    },
    {
      "idiom" : "ipad",
      "size" : "40x40",
      "scale" : "2x",
      "filename" : "icon-40@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "76x76",
      "scale" : "1x",
      "filename" : "icon-76.png"
    },
    {
      "idiom" : "ipad",
      "size" : "76x76",
      "scale" : "2x",
      "filename" : "icon-76@2x.png"
    },
    {
      "idiom" : "ipad",
      "size" : "83.5x83.5",
      "scale" : "2x",
      "filename" : "icon-83.5@2x.png"
    },
    {
      "idiom" : "ios-marketing",
      "size" : "1024x1024",
      "scale" : "1x",
      "filename" : "icon-1024.png"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

# Add missing 1x icons for iPad just in case
sips -s format png -z 20 20 "$SOURCE_IMAGE" --out "$TARGET_DIR/icon-20.png" > /dev/null
sips -s format png -z 29 29 "$SOURCE_IMAGE" --out "$TARGET_DIR/icon-29.png" > /dev/null
sips -s format png -z 40 40 "$SOURCE_IMAGE" --out "$TARGET_DIR/icon-40.png" > /dev/null

echo "Done! Icons generated in $TARGET_DIR"
