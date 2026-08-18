#!/usr/bin/env python3
"""Downsample the planet art in place, and sync the iOS imageset copies.

The source art arrives at ~4000px wide, which is more than either platform
displays: 43 files averaging 4.8 MB and peaking at 15 MB, ~199 MB total. That is
shipped app size on iOS and page weight on web.

CONSTRAIN HEIGHT, NOT WIDTH. The art is landscape (ratio ~1.3) and cover-fits
portrait phone screens, so height is the binding dimension and width is what
gets cropped away. An earlier default of --width 2048 left the height at ~1612px,
which the tallest iPhone (1320x2868) upscaled 1.78x while cropping 64% of the
width — only ~742 of 2048 columns were ever on screen, so ~1.2 MP of source was
being stretched over a 3.16 MP display. That read as visibly fuzzy artwork on
TestFlight, which is what retired the old default: the originals were always
tall enough, the pixels were discarded here.

So the default height clears the tallest current iPhone backing store and
nothing upscales. Raise it if a taller device ships; measure before lowering it.

Quality 90 rather than 85 because this artwork carries film grain, and grain is
what JPEG handles worst — the two interact, since upscaling magnifies exactly
the artifacts q85 introduces.

The originals are recoverable from git history — this overwrites in place.

  python3 scripts/downsample-art.py                # 2868px tall, q90
  python3 scripts/downsample-art.py --height 2622
  python3 scripts/downsample-art.py --quality 92
  python3 scripts/downsample-art.py --width 2048   # constrain the long edge instead
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
    ap.add_argument("--height", type=int, default=2868,
                    help="target height; the binding dimension on portrait phones")
    ap.add_argument("--width", type=int, default=None,
                    help="constrain the long edge instead (rarely what you want)")
    ap.add_argument("--quality", type=int, default=90)
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
        scale = args.width / w if args.width else args.height / h
        if scale >= 1:
            # Never upscale here — that only inflates bytes without adding
            # detail. But short of the target means the device does the
            # upscaling instead, which is the fuzz this script exists to avoid,
            # so it is reported rather than passed over in silence.
            skipped.append((f.name, (w, h)))
            continue
        target = (round(w * scale), round(h * scale))
        if args.dry_run:
            resized.append((f.name, (w, h), target, None))
            continue
        out = im.convert("RGB").resize(target, Image.LANCZOS)
        if f.suffix.lower() == ".png":
            out.save(f, "PNG", optimize=True)
        else:
            # JPEG is an order of magnitude smaller than PNG for these pixels;
            # see --quality in the module docstring for why 90 and not 85.
            out.save(f, "JPEG", quality=args.quality, optimize=True, progressive=True)
        # iOS keeps its own copy inside the imageset
        twin = IOS / f"{f.stem}.imageset" / f.name
        if twin.exists():
            shutil.copyfile(f, twin)
        resized.append((f.name, (w, h), target, f.stat().st_size))

    after = sum(f.stat().st_size for f in files)
    axis = f"--width {args.width}" if args.width else f"--height {args.height}"
    print(f"{len(resized)} resized to {axis} q{args.quality}, {len(skipped)} left at native size")
    if resized and resized[0][3] is not None:
        biggest = sorted(resized, key=lambda r: -r[3])[:3]
        for n, src, dst, sz in biggest:
            print(f"  largest now: {n:20} {src[0]}x{src[1]} -> {dst[0]}x{dst[1]}  {sz/1e6:.1f} MB")
    # Anything still short of the target gets upscaled on the device instead.
    if not args.width:
        short = [(n, s) for n, s in skipped if s[1] < args.height]
        if short:
            print(f"\n{len(short)} file(s) SHORTER than --height {args.height} — the device "
                  f"will upscale these, so re-export them taller:")
            for n, s in short:
                print(f"  {n:20} {s[0]}x{s[1]}   {args.height / s[1]:.2f}x upscale on a "
                      f"{args.height}px screen")
    print(f"\ntotal {before/1e6:.0f} MB -> {after/1e6:.0f} MB "
          f"({100*(1-after/before):.0f}% smaller)")
    print(f"mean per file {before/len(files)/1e6:.1f} MB -> {after/len(files)/1e6:.1f} MB")
    if not args.dry_run:
        print("\nRe-run scripts/measure-text-tone.py — the tone is measured from this art.")

if __name__ == "__main__":
    main()
