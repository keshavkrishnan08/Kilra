#!/usr/bin/env python3
"""Generate Symptly app icons — teal-to-violet gradient with cartoonish ECG + wellness ring."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

OUTPUT_DIR = "Symptly/Assets.xcassets/AppIcon.appiconset"

# App colors
TEAL = (0, 196, 154)
TEAL_LIGHT = (51, 223, 187)
VIOLET = (124, 92, 252)
VIOLET_LIGHT = (155, 130, 250)
WHITE = (255, 255, 255)
DARK_BG = (17, 19, 24)
DARK_SURFACE = (26, 29, 36)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient(draw, size, c1, c2, angle_deg=135):
    """Draw a diagonal linear gradient."""
    angle = math.radians(angle_deg)
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    max_proj = abs(cos_a * size) + abs(sin_a * size)

    for y in range(size):
        for x in range(size):
            proj = (x * cos_a + y * sin_a)
            t = max(0, min(1, (proj + max_proj / 2) / max_proj))
            draw.point((x, y), fill=lerp_color(c1, c2, t))


def draw_ecg_line(draw, cx, cy, scale, color, width=3):
    """Draw a stylized ECG/heartbeat line — cartoonish with rounded peaks."""
    w = width
    points = []
    # Flat start
    seg_w = scale * 0.7
    x_start = cx - seg_w
    y_base = cy

    # Build ECG waveform points
    pts = [
        (-0.70, 0.0),
        (-0.40, 0.0),
        (-0.30, 0.08),
        (-0.22, -0.08),
        (-0.15, 0.0),
        (-0.08, 0.0),
        (-0.03, 0.05),
        (0.00, -0.45),   # Big spike up
        (0.06, 0.22),    # Dip down
        (0.12, 0.0),
        (0.18, -0.12),   # Small bump
        (0.24, 0.0),
        (0.40, 0.0),
        (0.70, 0.0),
    ]

    scaled = [(cx + p[0] * scale * 2, cy + p[1] * scale * 2) for p in pts]

    # Draw with thick rounded line
    for i in range(len(scaled) - 1):
        draw.line([scaled[i], scaled[i + 1]], fill=color, width=w)

    # Draw round caps at each point
    r = w // 2
    for p in scaled:
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)


def draw_wellness_ring(draw, cx, cy, radius, thickness, start_deg, end_deg, color, alpha_img=None):
    """Draw an arc segment (wellness ring style)."""
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.arc(bbox, start=start_deg, end=end_deg, fill=color, width=thickness)


def draw_glow_circle(img, cx, cy, radius, color, intensity=0.3):
    """Draw a soft glow behind an element."""
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for r in range(radius, 0, -2):
        alpha = int(255 * intensity * (r / radius) ** 0.5 * (1 - r / radius))
        c = color + (alpha,)
        glow_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 4))
    img.paste(Image.alpha_composite(Image.new("RGBA", img.size, (0, 0, 0, 0)), glow), (0, 0), glow)


def draw_sparkle(draw, x, y, size, color):
    """Draw a small 4-point star sparkle."""
    s = size
    draw.line([(x, y - s), (x, y + s)], fill=color, width=max(1, s // 4))
    draw.line([(x - s, y), (x + s, y)], fill=color, width=max(1, s // 4))
    # Diagonal arms (thinner)
    ds = int(s * 0.6)
    dw = max(1, s // 6)
    draw.line([(x - ds, y - ds), (x + ds, y + ds)], fill=color, width=dw)
    draw.line([(x + ds, y - ds), (x - ds, y + ds)], fill=color, width=dw)


def generate_light_icon(size=1024):
    """Generate the main (light) app icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background gradient (teal → violet, diagonal)
    bg = Image.new("RGB", (size, size))
    bg_draw = ImageDraw.Draw(bg)
    draw_gradient(bg_draw, size, TEAL, VIOLET)
    img.paste(bg, (0, 0))
    draw = ImageDraw.Draw(img)

    s = size  # shorthand
    cx, cy = s // 2, s // 2

    # Subtle radial glow in center
    draw_glow_circle(img, cx, int(cy * 0.92), int(s * 0.35), WHITE, intensity=0.12)
    draw = ImageDraw.Draw(img)

    # Wellness ring (partial circle) — upper area
    ring_cy = int(s * 0.42)
    ring_r = int(s * 0.22)
    ring_thick = max(int(s * 0.028), 3)

    # Background ring (subtle white)
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=0, end=360, fill=WHITE + (60,), width=ring_thick
    )
    # Progress ring (bright white, ~75% fill)
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=-90, end=180, fill=WHITE, width=ring_thick
    )

    # Score number inside ring
    score_size = int(s * 0.11)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", score_size)
        small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(score_size * 0.35))
    except (OSError, IOError):
        font = ImageFont.load_default()
        small_font = font

    # Draw "78" score
    text = "78"
    bbox_t = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox_t[2] - bbox_t[0], bbox_t[3] - bbox_t[1]
    draw.text((cx - tw // 2, ring_cy - th // 2 - int(s * 0.01)), text, fill=WHITE, font=font)

    # ECG heartbeat line below the ring
    ecg_y = int(s * 0.68)
    ecg_scale = int(s * 0.18)
    ecg_width = max(int(s * 0.022), 2)
    draw_ecg_line(draw, cx, ecg_y, ecg_scale, WHITE, width=ecg_width)

    # Small heart at the ECG peak
    heart_x = cx
    heart_y = int(ecg_y - ecg_scale * 0.45 * 2 - s * 0.02)
    hs = int(s * 0.035)
    # Simple heart shape using two circles + triangle
    draw.ellipse([heart_x - hs, heart_y - hs // 2, heart_x, heart_y + hs // 2], fill=WHITE)
    draw.ellipse([heart_x, heart_y - hs // 2, heart_x + hs, heart_y + hs // 2], fill=WHITE)
    draw.polygon([
        (heart_x - hs, heart_y + hs // 4),
        (heart_x + hs, heart_y + hs // 4),
        (heart_x, heart_y + hs)
    ], fill=WHITE)

    # Sparkles for cartoonish feel
    sparkle_color = WHITE + (200,)
    sparkle_positions = [
        (int(s * 0.18), int(s * 0.25), int(s * 0.025)),
        (int(s * 0.82), int(s * 0.20), int(s * 0.020)),
        (int(s * 0.15), int(s * 0.72), int(s * 0.018)),
        (int(s * 0.85), int(s * 0.65), int(s * 0.022)),
        (int(s * 0.75), int(s * 0.82), int(s * 0.015)),
        (int(s * 0.28), int(s * 0.85), int(s * 0.017)),
    ]
    for sx, sy, ss in sparkle_positions:
        draw_sparkle(draw, sx, sy, ss, WHITE)

    # Small dots scattered
    dot_positions = [
        (int(s * 0.22), int(s * 0.48), int(s * 0.008)),
        (int(s * 0.78), int(s * 0.45), int(s * 0.006)),
        (int(s * 0.35), int(s * 0.15), int(s * 0.005)),
        (int(s * 0.65), int(s * 0.88), int(s * 0.007)),
    ]
    for dx, dy, dr in dot_positions:
        draw.ellipse([dx - dr, dy - dr, dx + dr, dy + dr], fill=WHITE + (150,))

    return img


def generate_dark_icon(size=1024):
    """Generate the dark mode icon variant."""
    img = Image.new("RGBA", (size, size), DARK_BG + (255,))
    draw = ImageDraw.Draw(img)

    s = size
    cx, cy = s // 2, s // 2

    # Subtle gradient glow in background
    draw_glow_circle(img, cx, int(cy * 0.85), int(s * 0.45), TEAL, intensity=0.08)
    draw_glow_circle(img, int(cx * 1.1), int(cy * 0.5), int(s * 0.3), VIOLET, intensity=0.06)
    draw = ImageDraw.Draw(img)

    # Wellness ring
    ring_cy = int(s * 0.42)
    ring_r = int(s * 0.22)
    ring_thick = max(int(s * 0.028), 3)

    # Background ring (dim)
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=0, end=360, fill=(44, 48, 57, 180), width=ring_thick
    )
    # Gradient-like progress ring (teal section + violet section)
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=-90, end=90, fill=TEAL, width=ring_thick
    )
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=90, end=180, fill=VIOLET_LIGHT, width=ring_thick
    )

    # Score number
    score_size = int(s * 0.11)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", score_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    text = "78"
    bbox_t = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox_t[2] - bbox_t[0], bbox_t[3] - bbox_t[1]
    draw.text((cx - tw // 2, ring_cy - th // 2 - int(s * 0.01)), text, fill=TEAL_LIGHT, font=font)

    # ECG line
    ecg_y = int(s * 0.68)
    ecg_scale = int(s * 0.18)
    ecg_width = max(int(s * 0.022), 2)
    draw_ecg_line(draw, cx, ecg_y, ecg_scale, TEAL, width=ecg_width)

    # Heart at peak
    heart_x = cx
    heart_y = int(ecg_y - ecg_scale * 0.45 * 2 - s * 0.02)
    hs = int(s * 0.035)
    draw.ellipse([heart_x - hs, heart_y - hs // 2, heart_x, heart_y + hs // 2], fill=TEAL_LIGHT)
    draw.ellipse([heart_x, heart_y - hs // 2, heart_x + hs, heart_y + hs // 2], fill=TEAL_LIGHT)
    draw.polygon([
        (heart_x - hs, heart_y + hs // 4),
        (heart_x + hs, heart_y + hs // 4),
        (heart_x, heart_y + hs)
    ], fill=TEAL_LIGHT)

    # Sparkles in accent colors
    sparkle_data = [
        (int(s * 0.18), int(s * 0.25), int(s * 0.025), TEAL_LIGHT),
        (int(s * 0.82), int(s * 0.20), int(s * 0.020), VIOLET_LIGHT),
        (int(s * 0.15), int(s * 0.72), int(s * 0.018), TEAL_LIGHT),
        (int(s * 0.85), int(s * 0.65), int(s * 0.022), VIOLET_LIGHT),
        (int(s * 0.75), int(s * 0.82), int(s * 0.015), TEAL_LIGHT),
        (int(s * 0.28), int(s * 0.85), int(s * 0.017), VIOLET_LIGHT),
    ]
    for sx, sy, ss, sc in sparkle_data:
        draw_sparkle(draw, sx, sy, ss, sc)

    return img


def generate_tinted_icon(size=1024):
    """Generate the tinted (monochrome) icon variant."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    s = size
    cx, cy = s // 2, s // 2

    # Tinted icons should be monochrome — iOS applies the tint color
    # Use white with varying alpha for depth
    FG = (255, 255, 255)
    FG_DIM = (255, 255, 255, 120)

    # Light background fill
    draw.rectangle([0, 0, s, s], fill=(255, 255, 255, 25))

    # Wellness ring
    ring_cy = int(s * 0.42)
    ring_r = int(s * 0.22)
    ring_thick = max(int(s * 0.028), 3)

    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=0, end=360, fill=(255, 255, 255, 60), width=ring_thick
    )
    draw.arc(
        [cx - ring_r, ring_cy - ring_r, cx + ring_r, ring_cy + ring_r],
        start=-90, end=180, fill=FG, width=ring_thick
    )

    # Score
    score_size = int(s * 0.11)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", score_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    text = "78"
    bbox_t = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox_t[2] - bbox_t[0], bbox_t[3] - bbox_t[1]
    draw.text((cx - tw // 2, ring_cy - th // 2 - int(s * 0.01)), text, fill=FG, font=font)

    # ECG line
    ecg_y = int(s * 0.68)
    ecg_scale = int(s * 0.18)
    ecg_width = max(int(s * 0.022), 2)
    draw_ecg_line(draw, cx, ecg_y, ecg_scale, FG, width=ecg_width)

    # Heart
    heart_x = cx
    heart_y = int(ecg_y - ecg_scale * 0.45 * 2 - s * 0.02)
    hs = int(s * 0.035)
    draw.ellipse([heart_x - hs, heart_y - hs // 2, heart_x, heart_y + hs // 2], fill=FG)
    draw.ellipse([heart_x, heart_y - hs // 2, heart_x + hs, heart_y + hs // 2], fill=FG)
    draw.polygon([
        (heart_x - hs, heart_y + hs // 4),
        (heart_x + hs, heart_y + hs // 4),
        (heart_x, heart_y + hs)
    ], fill=FG)

    # Sparkles
    for sx, sy, ss in [
        (int(s * 0.18), int(s * 0.25), int(s * 0.025)),
        (int(s * 0.82), int(s * 0.20), int(s * 0.020)),
        (int(s * 0.85), int(s * 0.65), int(s * 0.022)),
    ]:
        draw_sparkle(draw, sx, sy, ss, FG)

    return img


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Generating light icon (1024x1024)...")
    light = generate_light_icon(1024)
    light.save(os.path.join(OUTPUT_DIR, "icon_1024.png"), "PNG")

    print("Generating dark icon (1024x1024)...")
    dark = generate_dark_icon(1024)
    dark.save(os.path.join(OUTPUT_DIR, "icon_dark_1024.png"), "PNG")

    print("Generating tinted icon (1024x1024)...")
    tinted = generate_tinted_icon(1024)
    tinted.save(os.path.join(OUTPUT_DIR, "icon_tinted_1024.png"), "PNG")

    # Generate additional sizes from the 1024 master
    extra_sizes = [180, 167, 152, 120, 87, 80, 76, 60, 58, 40, 29]
    for sz in extra_sizes:
        resized = light.resize((sz, sz), Image.LANCZOS)
        resized.save(os.path.join(OUTPUT_DIR, f"icon_{sz}.png"), "PNG")
        print(f"  Generated {sz}x{sz}")

    print(f"\nAll icons saved to {OUTPUT_DIR}/")
    print("Done!")


if __name__ == "__main__":
    main()
