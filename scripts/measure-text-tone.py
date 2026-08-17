#!/usr/bin/env python3
"""Recompute per-world text tone from the planet art, and rewrite both catalogs.

Text in the landed view sits directly on the planet photo — there is no scrim
and no text-shadow — so whether light or dark text is readable depends on the
image, not on the world's `primary`. This measures the region the text actually
occupies (roughly 10-45% down, horizontally centred, matching
`.weatherSection { padding: 10vh 5vw }`) and writes two fields per world:

  textTone   "light" | "dark" — the kind of text the art needs
  textColor  the concrete color to use, hue-preserving

Light text keeps the world's existing `headline`, so worlds that already read
well are untouched. A world only switches to dark text when light text drops
below WCAG AA for large text (3:1) against the measured region; the dark color
is then that world's own hue darkened until it clears 4.5:1.

Needs Pillow, and only when the art changes:  pip install Pillow
Then:  python3 scripts/measure-text-tone.py
"""
import colorsys, re, sys
from pathlib import Path
try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow required: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
TS = ROOT / "web-app/galactic-weather/src/lib/atlas/worlds.ts"
SWIFT = ROOT / "ios-app/galacticweather/galacticweather/Atlas/Worlds.swift"
ART = ROOT / "web-app/galactic-weather/public/planets"

MIN_CONTRAST = 3.0    # WCAG AA for large text — the floor every world must clear
AIM_CONTRAST = 3.0    # the same bar: the readout is large text, so 3.0 is the
                      # applicable standard. Aiming higher forced a third of the
                      # catalog to flat white and threw away its color.

def _srgb(c):
    c /= 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
def relum(rgb):
    return 0.2126*_srgb(rgb[0]) + 0.7152*_srgb(rgb[1]) + 0.0722*_srgb(rgb[2])
def lum_hex(h):
    return relum(tuple(int(h[i:i+2], 16) for i in (1, 3, 5)))
def contrast(a, b):
    hi, lo = sorted([a, b], reverse=True)
    return (hi + 0.05) / (lo + 0.05)

def region_luminance(world):
    im = Image.open(ART / f"{world}.png").convert("RGB").resize((200, 157))
    W, H = im.size
    px = list(im.crop((int(.20*W), int(.10*H), int(.80*W), int(.45*H))).getdata())
    return sum(relum(p) for p in px) / len(px)

def shift_lightness(hex_color, bg, darker):
    """Push a color's lightness toward black or white, keeping hue and
    saturation, until it clears AIM_CONTRAST against `bg` — or until it runs out
    of range, in which case return the most extreme value available."""
    r, g, b = [int(hex_color[i:i+2], 16)/255 for i in (1, 3, 5)]
    h, l0, s = colorsys.rgb_to_hls(r, g, b)
    best, best_c = hex_color, contrast(lum_hex(hex_color), bg)
    steps = 60
    for i in range(1, steps + 1):
        l = l0 * (1 - i/steps) if darker else l0 + (1 - l0) * (i/steps)
        rgb = tuple(round(c*255) for c in colorsys.hls_to_rgb(h, l, s))
        hx = "#%02X%02X%02X" % rgb
        c = contrast(relum(rgb), bg)
        if c > best_c: best, best_c = hx, c
        if c >= AIM_CONTRAST: return hx, c
    return best, best_c

def main():
    ts = TS.read_text()
    rows = re.findall(r'id: "([a-z0-9-]+)",\n\t\tname: "[^"]+",\n\t\tdescription: "[^"]+",'
                      r'\n\t\tclimate: "[a-z]+",\n\t\tcolor: \{ primary: "#[0-9A-Fa-f]{6}", '
                      r'headline: "(#[0-9A-Fa-f]{6})" \}', ts)
    if not rows: sys.exit("could not parse worlds.ts")
    out, changed, weak = {}, [], []
    for world, headline in rows:
        bg = region_luminance(world)
        # Tone is decided by what the art can carry, not by the current headline.
        # Pure white is the lightest text available; if even that cannot clear the
        # floor, the art is too bright for light text and the world goes dark.
        tone = "light" if contrast(1.0, bg) >= MIN_CONTRAST else "dark"
        have = contrast(lum_hex(headline), bg)
        if have >= AIM_CONTRAST:
            colour, got = headline, have      # already fine — leave it exactly as is
        else:
            colour, got = shift_lightness(headline, bg, darker=(tone == "dark"))
        out[world] = (tone, colour)
        if colour != headline:
            changed.append((world, bg, tone, headline, colour, got))
        if got < MIN_CONTRAST:
            weak.append((world, bg, colour, got))

    # Line-based insertion: find each world's `color:` line and put the two new
    # lines directly after it. Simpler and easier to verify than regex surgery.
    for path, colour_marker, fmt in [
        (TS, "\t\tcolor: { primary:", '\t\ttextTone: "%s",\n\t\ttextColor: "%s",'),
        (SWIFT, "        color: WorldColor(primary:", '        textTone: .%s,\n        textColor: "%s",'),
    ]:
        lines = path.read_text().split("\n")
        out_lines, current = [], None
        for line in lines:
            m = re.search(r'id: "([a-z0-9-]+)"', line)
            if m and m.group(1) in out:
                current = m.group(1)
            # drop any previously generated fields so this is idempotent
            if re.match(r'\s*text(Tone|Color)[:=]', line):
                continue
            out_lines.append(line)
            if current and line.strip().startswith(colour_marker.strip()):
                tone, color = out[current]
                out_lines.append(fmt % (tone, color))
                current = None
        text = "\n".join(out_lines)
        if path is SWIFT:
            # Swift argument lists: `color:` needs a comma once something follows
            # it, and the last argument must not carry a trailing comma.
            text = re.sub(r'(color: WorldColor\([^\n]*\))(\n\s+textTone:)', r'\1,\2', text)
            text = re.sub(r'(\n\s+textColor: "#[0-9A-Fa-f]{6}"),(\n\s+\))', r'\1\2', text)
        path.write_text(text)
        print("updated", path.name)

    dark = [w for w, (t, _) in out.items() if t == "dark"]
    print(f"{len(out)} worlds measured; {len(dark)} need dark text; "
          f"{len(changed)} colors adjusted\n")
    for w, bg, tone, old, new, c in sorted(changed, key=lambda r: -r[1]):
        print(f"  {w:17} region {bg:.3f}  {tone:5}  {old} -> {new}  ({c:.1f}:1)")
    if weak:
        print("\nBELOW the %.1f:1 floor — art may need a scrim:" % MIN_CONTRAST)
        for w, bg, c_, got in weak:
            print(f"  {w:17} region {bg:.3f}  {c_}  ({got:.2f}:1)")

if __name__ == "__main__":
    main()
