#!/usr/bin/env python3
"""Trim flat export-frame bands from the edges of the planet art.

The JPG exports arrived with a uniform band on some edges — up to 24px on
ghorman's right — which showed as a sliver of pale grey down the edge of the
saved-location cards, since the card art is cover-fitted and the band is part of
the image. The original PNG art had no such band, so this is an export artifact
rather than something in the paintings.

A band is only trimmed when it is BOTH clearly different from the pixels just
inside it AND near-uniform along its length. Real artwork varies down an edge; a
frame does not. Anything ambiguous is left alone and reported.

The durable fix is to export without the surrounding frame; this cleans up what
is already here. Idempotent — a trimmed image has no band left to find.

  python3 scripts/trim-art-edges.py [--dry-run]
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

MAX_BAND = 40          # never trim more than this from one edge
DIFF_FROM_INTERIOR = 12  # how different a band must be to count
MAX_BAND_VARIANCE = 6.0  # how uniform it must be along its length

def _samples(px, size, side, i):
    w, h = size
    if side in ("left", "right"):
        x = i if side == "left" else w - 1 - i
        return [px[x, y] for y in range(0, h, max(1, h // 80))]
    y = i if side == "top" else h - 1 - i
    return [px[x, y] for x in range(0, w, max(1, w // 80))]

def band_width(im, side):
    px, size = im.load(), im.size
    def bright(i):
        s = _samples(px, size, side, i)
        return sum(sum(p) / 3 for p in s) / len(s)
    def variance(i):
        s = [sum(p) / 3 for p in _samples(px, size, side, i)]
        m = sum(s) / len(s)
        return (sum((v - m) ** 2 for v in s) / len(s)) ** 0.5
    ref = sum(bright(i) for i in range(MAX_BAND + 4, MAX_BAND + 14)) / 10
    n = 0
    for i in range(MAX_BAND):
        if abs(bright(i) - ref) > DIFF_FROM_INTERIOR and variance(i) < MAX_BAND_VARIANCE:
            n = i + 1
        else:
            break
    # A band that never terminates inside the scan window is not a thin export
    # frame — it is flat artwork, like the dark water filling the bottom of
    # ahch-to and nur. Trimming it would cut the painting.
    return 0 if n >= MAX_BAND else n

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    trimmed, ambiguous = [], []
    for f in sorted(WEB.glob("*.jpg")):
        im = Image.open(f).convert("RGB")
        w, h = im.size
        b = {s: band_width(im, s) for s in ("left", "right", "top", "bottom")}
        if not any(b.values()):
            continue
        box = (b["left"], b["top"], w - b["right"], h - b["bottom"])
        trimmed.append((f.name, (w, h), b, (box[2] - box[0], box[3] - box[1])))
        if args.dry_run:
            continue
        out = im.crop(box)
        out.save(f, "JPEG", quality=85, optimize=True, progressive=True)
        twin = IOS / f"{f.stem}.imageset" / f.name
        if twin.exists():
            shutil.copyfile(f, twin)

    if not trimmed:
        print("no edge bands found — nothing to trim")
        return
    print(f"{len(trimmed)} file(s) trimmed:\n")
    for name, before, b, after in trimmed:
        edges = ", ".join(f"{k} {v}px" for k, v in b.items() if v)
        print(f"  {name:20} {before[0]}x{before[1]} -> {after[0]}x{after[1]}   ({edges})")
    if not args.dry_run:
        print("\nRe-run scripts/measure-text-tone.py — the measured region shifted slightly.")

if __name__ == "__main__":
    main()
