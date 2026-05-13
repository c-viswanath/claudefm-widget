"""
ClaudeFM icon: pixel-art octopus (matches user's terracotta mascot)
with a pixelated blue headphone added on top.
Outputs icon_preview.png + AppIcon.icns.
"""
import os, subprocess, shutil
from PIL import Image, ImageDraw

# ── Palette ──────────────────────────────────────────────────────────────────
ORANGE  = (213, 115, 85, 255)   # terracotta — matches the mascot exactly
WHITE   = (255, 255, 255, 255)  # eye holes
BG      = ( 15,  15,  18, 255)  # near-black app-icon background
BLUE    = ( 66, 153, 225, 255)  # headphone main
BLUE_D  = ( 40, 108, 175, 255)  # headphone ear-cup inner (darker)
EMPTY   = (  0,   0,   0,   0)  # transparent

# ── Pixel-art grid ────────────────────────────────────────────────────────────
# Each letter = one "pixel" block
# B=body  E=eye(white)  .=empty  H=headphone-band  P=ear-cup(dark)
#
#  column →  0  1  2  3  4  5  6  7  8  9 10 11 12 13
GRID = [
    ".  .  H  H  H  H  H  H  H  H  H  H  .  .",   # 0  headphone band
    ".  H  P  .  .  .  .  .  .  .  .  P  H  .",   # 1  ear-cup gap
    ".  H  P  B  B  B  B  B  B  B  B  P  H  .",   # 2  ear-cup + body
    ".  .  .  B  E  E  B  B  E  E  B  .  .  .",   # 3  eyes
    ".  .  .  B  E  E  B  B  E  E  B  .  .  .",   # 4  eyes
    "B  B  .  B  B  B  B  B  B  B  B  .  B  B",   # 5  arms
    "B  B  .  B  B  B  B  B  B  B  B  .  B  B",   # 6  arms
    ".  .  .  B  B  B  B  B  B  B  B  .  .  .",   # 7  body
    ".  .  .  B  B  B  B  B  B  B  B  .  .  .",   # 8  body
    ".  .  .  B  .  B  .  .  B  .  B  .  .  .",   # 9  legs
    ".  .  .  B  .  B  .  .  B  .  B  .  .  .",   #10  legs
    ".  .  .  B  .  B  .  .  B  .  B  .  .  .",   #11  legs
]

COLOR_MAP = {'.': EMPTY, 'B': ORANGE, 'E': WHITE, 'H': BLUE, 'P': BLUE_D}

GRID_W = 14
GRID_H = len(GRID)

# ── Helpers ───────────────────────────────────────────────────────────────────

def rounded_rect(draw, x0, y0, x1, y1, r, fill):
    draw.rectangle([x0+r, y0, x1-r, y1], fill=fill)
    draw.rectangle([x0, y0+r, x1, y1-r], fill=fill)
    for cx, cy in [(x0, y0), (x1-2*r, y0), (x0, y1-2*r), (x1-2*r, y1-2*r)]:
        draw.ellipse([cx, cy, cx+2*r, cy+2*r], fill=fill)

def parse_grid(grid_lines):
    rows = []
    for line in grid_lines:
        rows.append([c for c in line.split() if c])
    return rows

def draw_octopus(pixel: int) -> Image.Image:
    rows = parse_grid(GRID)
    w = GRID_W * pixel
    h = GRID_H * pixel
    img = Image.new('RGBA', (w, h), EMPTY)
    draw = ImageDraw.Draw(img)
    for r, row in enumerate(rows):
        for c, cell in enumerate(row):
            color = COLOR_MAP.get(cell, EMPTY)
            if color[3] == 0:
                continue
            draw.rectangle([c*pixel, r*pixel, (c+1)*pixel-1, (r+1)*pixel-1], fill=color)
    return img

# ── Compose final icon ────────────────────────────────────────────────────────

def make_icon(size=1024) -> Image.Image:
    icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)

    # Dark rounded-square background (like macOS app icons)
    br = int(size * 0.22)
    rounded_rect(draw, 0, 0, size, size, br, BG)

    # Scale octopus to ~72% of icon width, centred slightly above middle
    octo_w = int(size * 0.72)
    pixel_size = octo_w // GRID_W          # keeps pixel art crisp (integer)
    octo_w = pixel_size * GRID_W
    octo_h = pixel_size * GRID_H

    octo = draw_octopus(pixel_size)

    # Paste centred, shifted up slightly so legs don't clip
    px = (size - octo_w) // 2
    py = (size - octo_h) // 2 - int(size * 0.02)
    icon.paste(octo, (px, py), octo)

    return icon

# ── Export ────────────────────────────────────────────────────────────────────

SIZES = [16, 32, 64, 128, 256, 512, 1024]

def export(out_dir="."):
    base = make_icon(1024)
    preview = os.path.join(out_dir, "icon_preview.png")
    base.save(preview)
    print(f"  icon_preview.png")

    iconset = os.path.join(out_dir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    for sz in SIZES:
        base.resize((sz, sz), Image.NEAREST).save(
            os.path.join(iconset, f"icon_{sz}x{sz}.png"))
        if sz <= 512:
            base.resize((sz*2, sz*2), Image.NEAREST).save(
                os.path.join(iconset, f"icon_{sz}x{sz}@2x.png"))

    r = subprocess.run(
        ["iconutil", "--convert", "icns", iconset,
         "--output", os.path.join(out_dir, "AppIcon.icns")],
        capture_output=True, text=True)
    if r.returncode != 0:
        print("iconutil error:", r.stderr)
    else:
        print("  AppIcon.icns")
    shutil.rmtree(iconset)

if __name__ == "__main__":
    export(".")
    print("Done.")
