#!/usr/bin/env python3
"""Copy the travel-poster JPGs into the iOS asset catalog, downsampled.

The posters are authored at 750x1050 and live in
`web-app/galactic-weather/public/posters/`, named after the world
("Tatooine.jpg"). iOS cannot read that directory, so the Credits screen needs
its own copies as imagesets under `Assets.xcassets/Posters/`.

They are downsampled on the way in. The Credits strip draws them around 120pt
wide, so even @3x needs ~360px; shipping the full 750px would add ~3.2 MB to the
app binary to render at less than half that. This is the same reasoning that
took the planet art from 208 MB to 8.9 MB — see `downsample-art.py`.

The web originals are never modified. Nothing on web uses them yet, and they are
the masters.

Imagesets are named `poster-<worldId>` rather than `<worldId>`, because the
planet backdrops already own the bare world id in the same catalog and asset
names have to be unique across it.

  python3 scripts/sync-poster-art.py
  python3 scripts/sync-poster-art.py --width 640

Needs Pillow (`pip install Pillow`). Idempotent; safe to re-run after adding a
poster.
"""
import argparse
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow is required: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "web-app/galactic-weather/public/posters"
CATALOG = ROOT / "ios-app/galacticweather/galacticweather/Resources/Assets.xcassets/Posters"
WORLDS_TS = ROOT / "web-app/galactic-weather/src/lib/atlas/worlds.ts"

GROUP_CONTENTS = {"info": {"author": "xcode", "version": 1}}


def known_world_ids() -> set[str]:
    """Ids from the web catalog, which is the source of truth for both platforms."""
    text = WORLDS_TS.read_text(encoding="utf8")
    return set(re.findall(r'id:\s*"([^"]+)"', text))


def world_id_for(stem: str) -> str:
    """"Tatooine" -> "tatooine", "Ahch-To" -> "ahch-to", "Yavin 4" -> "yavin-4"."""
    return stem.strip().lower().replace(" ", "-")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--width", type=int, default=480,
                        help="target width in px (default 480)")
    args = parser.parse_args()

    if not SOURCE.is_dir():
        sys.exit(f"No poster directory at {SOURCE}")

    posters = sorted(SOURCE.glob("*.jpg")) + sorted(SOURCE.glob("*.jpeg"))
    if not posters:
        sys.exit(f"No posters found in {SOURCE}")

    ids = known_world_ids()
    CATALOG.mkdir(parents=True, exist_ok=True)
    (CATALOG / "Contents.json").write_text(json.dumps(GROUP_CONTENTS, indent=2) + "\n")

    unknown, total_before, total_after = [], 0, 0

    for path in posters:
        world_id = world_id_for(path.stem)
        if world_id not in ids:
            # Loud rather than silent: a mismatch here produces an imageset no
            # code will ever reference, which looks like "the poster just
            # doesn't show up" at runtime.
            unknown.append(f"{path.name} -> {world_id!r}")
            continue

        name = f"poster-{world_id}"
        imageset = CATALOG / f"{name}.imageset"
        imageset.mkdir(exist_ok=True)
        destination = imageset / f"{name}.jpg"

        with Image.open(path) as image:
            image = image.convert("RGB")
            before = image.size
            if image.width > args.width:
                height = round(image.height * args.width / image.width)
                image = image.resize((args.width, height), Image.LANCZOS)
            image.save(destination, "JPEG", quality=85, optimize=True)

        (imageset / "Contents.json").write_text(
            json.dumps(
                {
                    "images": [
                        {"filename": destination.name, "idiom": "universal", "scale": "1x"}
                    ],
                    "info": {"author": "xcode", "version": 1},
                },
                indent=2,
            )
            + "\n"
        )

        size_before = path.stat().st_size
        size_after = destination.stat().st_size
        total_before += size_before
        total_after += size_after
        print(f"  {name:22} {before[0]}x{before[1]} -> {image.width}x{image.height}  "
              f"{size_before // 1024} KB -> {size_after // 1024} KB")

    if unknown:
        print("\nSkipped — filename does not match any world id in worlds.ts:")
        for line in unknown:
            print(f"  {line}")

    print(f"\n{total_before // 1024} KB -> {total_after // 1024} KB in the app bundle")
    print("Run `xcodegen generate` (or ./scripts/test-all.sh) to pick up new files.")
    return 1 if unknown else 0


if __name__ == "__main__":
    raise SystemExit(main())
