"""Generate AxisMind app icon (512x512 PNG) using Pillow."""
from PIL import Image, ImageDraw
import math

SIZE = 512
OUTPUT = "assets/axismind_icon.png"

# Colors
BG_DARK = (26, 26, 46)
BG_LIGHT = (22, 33, 62)
MOON_COLOR = (240, 230, 211)
MOON_DOT = (212, 196, 168)
LOTUS_GOLD = (232, 197, 71)
LOTUS_GOLD_DIM = (232, 197, 71)
STAR_COLOR = (232, 197, 71)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# --- Background rounded rect ---
def rounded_rect(d, xy, r, fill):
    x0, y0, x1, y1 = xy
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=fill)

# Draw background with gradient approximation
cx, cy = SIZE // 2, SIZE // 2
for y in range(SIZE):
    t = y / SIZE
    r = int(BG_DARK[0] + (BG_LIGHT[0] - BG_DARK[0]) * t)
    g = int(BG_DARK[1] + (BG_LIGHT[1] - BG_DARK[1]) * t)
    b = int(BG_DARK[2] + (BG_LIGHT[2] - BG_DARK[2]) * t)
    for x in range(SIZE):
        # Check if inside rounded rect
        rx, ry = 96, 96
        if x >= rx and x < SIZE - rx and y >= ry and y < SIZE - ry:
            img.putpixel((x, y), (r, g, b))
        elif x < rx and y < ry:
            if (x - rx) ** 2 + (y - ry) ** 2 <= rx ** 2:
                img.putpixel((x, y), (r, g, b))
        elif x >= SIZE - rx and y < ry:
            if (x - (SIZE - rx)) ** 2 + (y - ry) ** 2 <= rx ** 2:
                img.putpixel((x, y), (r, g, b))
        elif x < rx and y >= SIZE - ry:
            if (x - rx) ** 2 + (y - (SIZE - ry)) ** 2 <= rx ** 2:
                img.putpixel((x, y), (r, g, b))
        elif x >= SIZE - rx and y >= SIZE - ry:
            if (x - (SIZE - rx)) ** 2 + (y - (SIZE - ry)) ** 2 <= rx ** 2:
                img.putpixel((x, y), (r, g, b))
        elif x >= rx and x < SIZE - rx:
            img.putpixel((x, y), (r, g, b))
        elif y >= ry and y < SIZE - ry:
            img.putpixel((x, y), (r, g, b))

# --- Outer glow ring ---
draw.ellipse([cx - 180, cy - 180, cx + 180, cy + 180], outline=(232, 197, 71, 38), width=1)

# --- Inner glow ring ---
draw.ellipse([cx - 140, cy - 140, cx + 140, cy + 140], outline=(232, 197, 71, 25), width=1)

# --- Moon (circle) ---
draw.ellipse([cx - 100, cy - 100, cx + 100, cy + 100], fill=MOON_COLOR)

# --- Moon texture dots ---
dots = [(220, 230, 4), (240, 210, 2.5), (280, 240, 3), (260, 280, 2), (230, 270, 1.5)]
for dx, dy, r in dots:
    draw.ellipse([dx - r, dy - r, dx + r, dy + r], fill=MOON_DOT + (100,))

# --- Lotus petals ---
def draw_lotus_petal(d, cx, cy, tip_dx, tip_dy, mid_left_dx, mid_left_dy, mid_right_dx, mid_right_dy, base_dx, base_dy, color, alpha):
    """Draw a lotus petal as a filled path."""
    tip = (cx + tip_dx, cy + tip_dy)
    mid_left = (cx + mid_left_dx, cy + mid_left_dy)
    mid_right = (cx + mid_right_dx, cy + mid_right_dy)
    base = (cx + base_dx, cy + base_dy)

    # Use polygon approximation
    points = []
    steps = 20
    for i in range(steps + 1):
        t = i / steps
        # Quadratic bezier: B(t) = (1-t)^2*P0 + 2(1-t)*t*P1 + t^2*P2
        # Left side: tip -> mid_left -> base
        if t <= 0.5:
            tt = t * 2
            x = (1 - tt) ** 2 * tip[0] + 2 * (1 - tt) * tt * mid_left[0] + tt ** 2 * base[0]
            y = (1 - tt) ** 2 * tip[1] + 2 * (1 - tt) * tt * mid_left[1] + tt ** 2 * base[1]
        else:
            tt = (t - 0.5) * 2
            x = (1 - tt) ** 2 * base[0] + 2 * (1 - tt) * tt * mid_right[0] + tt ** 2 * tip[0]
            y = (1 - tt) ** 2 * base[1] + 2 * (1 - tt) * tt * mid_right[1] + tt ** 2 * tip[1]
        points.append((x, y))

    fill_color = color[:3] + (int(255 * alpha),)
    d.polygon(points, fill=fill_color)

# Center petal
draw_lotus_petal(draw, cx, cy, 0, 54, -26, 10, 26, 10, 0, -56, LOTUS_GOLD, 0.85)

# Left petals
draw_lotus_petal(draw, cx, cy, -26, 40, -35, 5, -26, 10, -61, -41, LOTUS_GOLD, 0.6)
draw_lotus_petal(draw, cx, cy, -16, 20, -30, 0, -16, 20, -76, -26, LOTUS_GOLD, 0.35)

# Right petals
draw_lotus_petal(draw, cx, cy, 26, 40, 35, 5, 26, 10, 61, -41, LOTUS_GOLD, 0.6)
draw_lotus_petal(draw, cx, cy, 16, 20, 30, 0, 16, 20, 76, -26, LOTUS_GOLD, 0.35)

# --- Stars ---
stars = [(160, 140, 2), (350, 130, 1.5), (380, 180, 1), (140, 200, 1.5),
         (370, 300, 1), (150, 320, 1.2), (200, 150, 1), (310, 160, 1.3)]
for sx, sy, r in stars:
    draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=STAR_COLOR + (153,))

# --- Sparkle crosses ---
def draw_sparkle(d, x, y, size, alpha):
    c = STAR_COLOR + (int(255 * alpha),)
    d.line([(x, y - size), (x, y + size)], fill=c, width=1)
    d.line([(x - size, y), (x + size, y)], fill=c, width=1)

draw_sparkle(draw, 340, 150, 3, 0.5)
draw_sparkle(draw, 170, 170, 3, 0.4)
draw_sparkle(draw, 360, 250, 3, 0.3)

# Save
img.save(OUTPUT, "PNG")
print(f"Icon saved to {OUTPUT}")
print(f"Size: {img.size}")
