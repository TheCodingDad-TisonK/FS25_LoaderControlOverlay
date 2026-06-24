"""
Generate the mod icon for FS25_LoaderControlOverlay.

Renders a clean, modern front-loader + control-pad motif at 4x and
downsamples to 256x256, then writes icon.dds (DXT5) and icon_source.png.

Run:  py tools/make_icon.py
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT_DIR = Path(__file__).resolve().parent.parent
S = 256
SS = 4              # supersample factor
W = S * SS

# palette
BG_TOP    = (18, 24, 32)
BG_BOT    = (9, 12, 17)
ACCENT    = (76, 190, 255)     # electric blue
ACCENT2   = (255, 158, 61)     # amber (loader)
WHITE     = (236, 242, 248)
DIM       = (120, 130, 142)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def rounded_mask(size, radius):
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return m


def load_font(sz):
    for name in ("arialbd.ttf", "Arialbd.ttf", "arial.ttf", "segoeuib.ttf"):
        try:
            return ImageFont.truetype(name, sz)
        except Exception:
            continue
    return ImageFont.load_default()


def main():
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # vertical gradient background
    for y in range(W):
        d.line([(0, y), (W, y)], fill=lerp(BG_TOP, BG_BOT, y / W) + (255,))

    # subtle accent glow lower-left
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-W * 0.2, W * 0.55, W * 0.6, W * 1.25], fill=ACCENT + (60,))
    glow = glow.filter(ImageFilter.GaussianBlur(W * 0.06))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)

    # --- front loader silhouette (boom rising to a bucket) ---
    # tractor body block (left)
    d.rounded_rectangle([W * 0.10, W * 0.55, W * 0.36, W * 0.74], radius=W * 0.02, fill=lerp(WHITE, BG_BOT, 0.55) + (255,))
    # wheel
    d.ellipse([W * 0.11, W * 0.66, W * 0.23, W * 0.78], fill=(20, 24, 30, 255))
    d.ellipse([W * 0.135, W * 0.685, W * 0.205, W * 0.755], fill=DIM + (255,))
    # boom arm
    d.line([(W * 0.30, W * 0.62), (W * 0.62, W * 0.40)], fill=ACCENT2 + (255,), width=int(W * 0.035))
    d.ellipse([W * 0.285, W * 0.605, W * 0.325, W * 0.645], fill=ACCENT2 + (255,))
    # bucket
    bx, by = W * 0.60, W * 0.36
    d.polygon([
        (bx, by), (bx + W * 0.16, by - W * 0.01),
        (bx + W * 0.155, by + W * 0.075), (bx + W * 0.02, by + W * 0.11),
    ], fill=ACCENT2 + (255,))

    # --- control pad motif (top-right): joystick dot on a pad ---
    pad = [W * 0.66, W * 0.16, W * 0.86, W * 0.36]
    d.rounded_rectangle(pad, radius=W * 0.02, outline=ACCENT + (255,), width=int(W * 0.006))
    cx, cy = (pad[0] + pad[2]) / 2, (pad[1] + pad[3]) / 2
    # crosshair
    d.line([(cx, pad[1] + W * 0.02), (cx, pad[3] - W * 0.02)], fill=ACCENT + (90,), width=int(W * 0.004))
    d.line([(pad[0] + W * 0.02, cy), (pad[2] - W * 0.02, cy)], fill=ACCENT + (90,), width=int(W * 0.004))
    # joystick dot (offset up = raising)
    dotr = W * 0.028
    d.ellipse([cx - dotr, cy - dotr - W * 0.04, cx + dotr, cy + dotr - W * 0.04], fill=ACCENT + (255,))

    # accent frame
    d.rounded_rectangle([W * 0.02, W * 0.02, W - W * 0.02, W - W * 0.02],
                        radius=W * 0.10, outline=ACCENT + (140,), width=int(W * 0.008))

    # title text
    font = load_font(int(W * 0.085))
    text = "LOADER CONTROL"
    tb = d.textbbox((0, 0), text, font=font)
    tw = tb[2] - tb[0]
    d.text(((W - tw) / 2, W * 0.80), text, font=font, fill=WHITE + (255,))

    # downsample
    img = img.resize((S, S), Image.LANCZOS)

    # rounded corners
    mask = rounded_mask(S, int(S * 0.10))
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)

    png_path = OUT_DIR / "icon_source.png"
    out.save(png_path)
    print("wrote", png_path)

    dds_path = OUT_DIR / "icon.dds"
    try:
        out.save(dds_path, "DDS", pixel_format="DXT5")
    except Exception as e:
        print("DXT5 save failed (%s), trying default DDS" % e)
        out.save(dds_path, "DDS")
    print("wrote", dds_path)


if __name__ == "__main__":
    main()
