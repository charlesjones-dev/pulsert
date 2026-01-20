#!/usr/bin/env python3
"""
Generate PulseRT app icon with pink background and "RT" initials.

Usage: python3 generate-icon.py

If Pillow is not installed, the script will create a virtual environment
and install it automatically.
"""

import os
import subprocess
import sys


def ensure_pillow():
    """Ensure Pillow is available, installing in venv if needed."""
    try:
        from PIL import Image, ImageDraw, ImageFont
        return Image, ImageDraw, ImageFont
    except ImportError:
        pass

    # Check if we're already in our venv
    venv_path = os.path.join(os.path.dirname(__file__), ".venv")
    venv_python = os.path.join(venv_path, "bin", "python3")

    if sys.executable == venv_python:
        # We're in the venv but Pillow still not available
        print("Installing Pillow...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "-q"])
        from PIL import Image, ImageDraw, ImageFont
        return Image, ImageDraw, ImageFont

    # Create venv if it doesn't exist
    if not os.path.exists(venv_path):
        print("Creating virtual environment...")
        subprocess.check_call([sys.executable, "-m", "venv", venv_path])

    # Re-run this script in the venv
    print("Running in virtual environment...")
    os.execv(venv_python, [venv_python, __file__] + sys.argv[1:])


Image, ImageDraw, ImageFont = ensure_pillow()

# Icon sizes for macOS app icon
SIZES = [16, 32, 64, 128, 256, 512, 1024]

# Colors
BG_COLOR = "#FF6B9D"
FG_COLOR = "#FFFFFF"

OUTPUT_DIR = "PulseRT/Resources/Assets.xcassets/AppIcon.appiconset"


def create_icon(size: int) -> Image.Image:
    """Create a single icon at the specified size."""
    img = Image.new("RGBA", (size, size), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Calculate font size (roughly 45% of icon size for good proportions)
    font_size = int(size * 0.45)

    # Try to use SF Pro or fall back to system fonts
    font = None
    font_paths = [
        "/System/Library/Fonts/SFNSText.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/SF-Pro-Text-Bold.otf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]

    for font_path in font_paths:
        if os.path.exists(font_path):
            try:
                font = ImageFont.truetype(font_path, font_size)
                break
            except (IOError, OSError):
                continue

    if font is None:
        # Fall back to default font
        font = ImageFont.load_default()

    text = "RT"

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]  # Adjust for font baseline

    # Draw the text
    draw.text((x, y), text, fill=FG_COLOR, font=font)

    return img


def main():
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"Generating icons in {OUTPUT_DIR}...")

    # Generate icons at each size
    for size in SIZES:
        img = create_icon(size)
        filename = f"icon_{size}x{size}.png"
        filepath = os.path.join(OUTPUT_DIR, filename)
        img.save(filepath, "PNG")
        print(f"  Created {filename}")

    # Create Contents.json for Xcode asset catalog
    contents = """{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_64x64.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_1024x1024.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

    contents_path = os.path.join(OUTPUT_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        f.write(contents)
    print(f"  Created Contents.json")

    # Create Assets.xcassets Contents.json
    assets_contents = """{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
    assets_dir = "PulseRT/Resources/Assets.xcassets"
    with open(os.path.join(assets_dir, "Contents.json"), "w") as f:
        f.write(assets_contents)

    print("\nIcon generation complete!")


if __name__ == "__main__":
    main()
