# Author: Karl Bien Madrid
"""Shrink Karl's uploaded enemy art into game-ready sprites.

Crops each image to its visible pixels and fits it in 192x192, keeping
transparency. Reads the originals from the repository's top folder and writes
game/art/enemies/<name>.png. Run: python3 -I game/tools/import_enemy_art.py
"""
import os
import sys
from PIL import Image

MAX_SIZE = 192
# Uploaded file name -> sprite name. "Evil Bakunawa.png" is really Evil Berberoka.
SOURCES = {
    "Evil Tyanak.png": "evil_tyanak",
    "Evil Tikbalang.png": "evil_tikbalang",
    "Evil Kapre.png": "evil_kapre",
    "Evil Manananggal.png": "evil_manananggal",
    "Evil White Lady.png": "evil_white_lady",
    "Evil Nuno sa Punso.png": "evil_nuno_sa_punso",
    "Evil Diwata.png": "evil_diwata",
    "Evil Bakunawa.png": "evil_berberoka",
}


def main() -> int:
    game_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    repo_dir = os.path.dirname(game_dir)
    out_dir = os.path.join(game_dir, "art", "enemies")
    os.makedirs(out_dir, exist_ok=True)
    for source, name in SOURCES.items():
        image = Image.open(os.path.join(repo_dir, source)).convert("RGBA")
        image = image.crop(image.getchannel("A").getbbox())
        image.thumbnail((MAX_SIZE, MAX_SIZE), Image.LANCZOS)
        path = os.path.join(out_dir, name + ".png")
        image.save(path, optimize=True)
        print(f"{name:22s} {image.size}  {os.path.getsize(path) // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
