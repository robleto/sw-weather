#!/usr/bin/env python3
"""Downsample the planet art in place, and sync the iOS imageset copies.

The source art arrives at ~4000px wide, which is far more than either platform
displays: 43 files averaging 4.8 MB and peaking at 15 MB, ~199 MB total. That is
shipped app size on iOS and page weight on web.

Note the art is landscape (ratio ~1.3) but cover-fits portrait phone screens, so
HEIGHT is the binding dimension there. At --width 2048 the height lands ~1540px
and a 2868px-tall phone upscales it ~1.8x. That is usually invisible on flat,
painterly artwork; if it is not, re-run with a larger --width (or pass
--height to constrain the short edge instead).

The originals are recoverable from git history — this overwrites in place.

  python3 scripts/downsample-art.py            # 2048px wide
  python3 scripts/downsample-art.py --width 2732
  python3 scripts/downsample-art.py --height 2048
"""
import argparse, shutil, sys
from pathlib import Path
try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow required: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
WEB = ROOT / "web-app/galactic-weather/public/planets"
IOS = ROOT / "ios-app/galacticweather/galacticweather/Resources/Assets.xcassets/Planets"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--width", type=int, default=2048)
    ap.add_argument("--height", type=int, default=None,
                    help="constrain the short edge instead of the long one")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    files = sorted(f for f in WEB.iterdir()
                   if f.suffix.lower() in (".png", ".jpg", ".jpeg"))
    if not files:
        sys.exit(f"no art found in {WEB}")

    before = sum(f.stat().st_size for f in files)
    skipped, resized = [], []
    for f in files:
        im = Image.open(f)
        w, h = im.size
        if args.height:
            scale = args.height / h
        else:
            scale = args.width / w
        if scale >= 1:
            skipped.append(f.name)
            continue
        target = (round(w * scale), round(h * scale))
        if args.dry_run:
            resized.append((f.name, (w, h), target, None))
            continue
        out = im.convert("RGB").resize(target, Image.LANCZOS)
        if f.suffix.lower() == ".png":
            out.save(f, "PNG", optimize=True)
        else:
            # 85 is ample for flat painterly art and an order of magnitude
            # smaller than PNG for the same pixels.
            out.save(f, "JPEG", quality=85, optimize=True, progressive=True)
        # iOS keeps its own copy inside the imageset
        twin = IOS / f"{f.stem}.imageset" / f.name
        if twin.exists():
            shutil.copyfile(f, twin)
        resized.append((f.name, (w, h), target, f.stat().st_size))

    after = sum(f.stat().st_size for f in files)
    print(f"{len(resized)} resized, {len(skipped)} already small enough")
    if resized and resized[0][3] is not None:
        biggest = sorted(resized, key=lambda r: -r[3])[:3]
        for n, src, dst, sz in biggest:
            print(f"  largest now: {n:20} {src[0]}x{src[1]} -> {dst[0]}x{dst[1]}  {sz/1e6:.1f} MB")
    print(f"\ntotal {before/1e6:.0f} MB -> {after/1e6:.0f} MB "
          f"({100*(1-after/before):.0f}% smaller)")
    print(f"mean per file {before/len(files)/1e6:.1f} MB -> {after/len(files)/1e6:.1f} MB")
    if not args.dry_run:
        print("\nRe-run scripts/measure-text-tone.py — the tone is measured from this art.")

if __name__ == "__main__":
    main()
