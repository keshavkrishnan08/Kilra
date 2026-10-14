#!/usr/bin/env python3
"""Generate App Store marketing screenshots for Symptly (6.5" iPhone, 1242×2688)."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

OUTPUT_DIR = "screenshots"
W, H = 1242, 2688

# App colors
TEAL = (0, 196, 154)
TEAL_DARK = (0, 153, 119)
VIOLET = (124, 92, 252)
VIOLET_LIGHT = (155, 130, 250)
WHITE = (255, 255, 255)
BG_LIGHT = (250, 249, 246)
DARK_BG = (17, 19, 24)
TEXT_PRIMARY = (28, 37, 52)
TEXT_SECONDARY = (74, 85, 104)
TEXT_TERTIARY = (136, 150, 171)


def get_fonts():
    """Load system fonts with fallbacks."""
    paths = [
        "/System/Library/Fonts/SFPro-Bold.otf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]
    regular_paths = [
        "/System/Library/Fonts/SFPro-Regular.otf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
    ]

    bold = None
    for p in paths:
        try:
            bold = ImageFont.truetype(p, 72)
            break
        except (OSError, IOError):
            continue
    if not bold:
        bold = ImageFont.load_default()

    regular = None
    for p in regular_paths:
        try:
            regular = ImageFont.truetype(p, 42)
            break
        except (OSError, IOError):
            continue
    if not regular:
        regular = ImageFont.load_default()

    return bold, regular


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient_rect(draw, bbox, c1, c2, vertical=True):
    x1, y1, x2, y2 = bbox
    steps = y2 - y1 if vertical else x2 - x1
    for i in range(steps):
        t = i / max(steps - 1, 1)
        c = lerp_color(c1, c2, t)
        if vertical:
            draw.line([(x1, y1 + i), (x2, y1 + i)], fill=c)
        else:
            draw.line([(x1 + i, y1), (x1 + i, y2)], fill=c)


def draw_rounded_rect(draw, bbox, radius, fill):
    x1, y1, x2, y2 = bbox
    draw.rounded_rectangle(bbox, radius=radius, fill=fill)


def draw_phone_frame(img, screenshot_path, x, y, phone_w, phone_h, corner_r=40):
    """Draw a phone mockup with a screenshot inside."""
    draw = ImageDraw.Draw(img)

    # Phone bezel (dark frame)
    bezel_pad = 8
    draw.rounded_rectangle(
        [x - bezel_pad, y - bezel_pad, x + phone_w + bezel_pad, y + phone_h + bezel_pad],
        radius=corner_r + 6,
        fill=(30, 30, 35)
    )

    # Screen area
    draw.rounded_rectangle(
        [x, y, x + phone_w, y + phone_h],
        radius=corner_r,
        fill=BG_LIGHT
    )

    # Load and paste screenshot if exists
    if os.path.exists(screenshot_path):
        shot = Image.open(screenshot_path).convert("RGBA")
        shot = shot.resize((phone_w, phone_h), Image.LANCZOS)

        # Create rounded mask
        mask = Image.new("L", (phone_w, phone_h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, phone_w, phone_h], radius=corner_r, fill=255)

        img.paste(shot, (x, y), mask)
    else:
        # Draw placeholder screen content
        draw_placeholder_screen(draw, x, y, phone_w, phone_h)

    # Dynamic island notch
    notch_w = 180
    notch_h = 50
    notch_x = x + (phone_w - notch_w) // 2
    notch_y = y + 14
    draw.rounded_rectangle(
        [notch_x, notch_y, notch_x + notch_w, notch_y + notch_h],
        radius=25,
        fill=(15, 15, 18)
    )


def draw_placeholder_screen(draw, x, y, w, h):
    """Draw a representative app screen when no screenshot is available."""
    # Status bar area
    draw.rectangle([x, y, x + w, y + 80], fill=BG_LIGHT)

    # Wellness score circle
    cx = x + w // 2
    cy = y + h // 3
    r = 100
    draw.arc([cx - r, cy - r, cx + r, cy + r], 0, 360, fill=(229, 227, 222), width=8)
    draw.arc([cx - r, cy - r, cx + r, cy + r], -90, 180, fill=TEAL, width=8)


def draw_sparkle(draw, x, y, size, color):
    s = size
    draw.line([(x, y - s), (x, y + s)], fill=color, width=max(2, s // 3))
    draw.line([(x - s, y), (x + s, y)], fill=color, width=max(2, s // 3))
    ds = int(s * 0.6)
    draw.line([(x - ds, y - ds), (x + ds, y + ds)], fill=color, width=max(1, s // 5))
    draw.line([(x + ds, y - ds), (x - ds, y + ds)], fill=color, width=max(1, s // 5))


def draw_floating_pill(draw, x, y, text, icon_color, font):
    """Draw a floating pill/badge decoration."""
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    pad_x, pad_y = 28, 14
    pill_w = tw + pad_x * 2 + 24
    pill_h = th + pad_y * 2

    # Shadow
    draw.rounded_rectangle(
        [x + 4, y + 4, x + pill_w + 4, y + pill_h + 4],
        radius=pill_h // 2,
        fill=(0, 0, 0, 30)
    )
    # Pill background
    draw.rounded_rectangle(
        [x, y, x + pill_w, y + pill_h],
        radius=pill_h // 2,
        fill=WHITE
    )
    # Icon dot
    dot_r = 8
    draw.ellipse(
        [x + pad_x - 4, y + pill_h // 2 - dot_r, x + pad_x - 4 + dot_r * 2, y + pill_h // 2 + dot_r],
        fill=icon_color
    )
    # Text
    draw.text((x + pad_x + 20, y + pad_y - 2), text, fill=TEXT_PRIMARY, font=font)


def draw_ecg_decoration(draw, x, y, width, color, line_w=4):
    """Draw a decorative ECG line."""
    pts = [
        (0.0, 0.0), (0.15, 0.0), (0.2, 0.05), (0.25, -0.05),
        (0.3, 0.0), (0.38, 0.0), (0.42, 0.03),
        (0.46, -0.35), (0.52, 0.18), (0.56, 0.0),
        (0.62, -0.08), (0.68, 0.0), (0.85, 0.0), (1.0, 0.0)
    ]
    scaled = [(x + p[0] * width, y + p[1] * width * 0.5) for p in pts]
    for i in range(len(scaled) - 1):
        draw.line([scaled[i], scaled[i + 1]], fill=color, width=line_w)


def create_screenshot(index, headline, subtitle, bg_c1, bg_c2, decorations_fn):
    """Create a single marketing screenshot."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background gradient
    draw_gradient_rect(draw, [0, 0, W, H], bg_c1, bg_c2)

    bold_font, regular_font = get_fonts()

    # Headline text
    headline_y = 140
    for i, line in enumerate(headline.split("\n")):
        bbox = draw.textbbox((0, 0), line, font=bold_font)
        tw = bbox[2] - bbox[0]
        draw.text(((W - tw) // 2, headline_y + i * 90), line, fill=WHITE, font=bold_font)

    # Subtitle
    sub_y = headline_y + len(headline.split("\n")) * 90 + 20
    bbox = draw.textbbox((0, 0), subtitle, font=regular_font)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2, sub_y), subtitle, fill=WHITE + (200,), font=regular_font)

    # Phone mockup area
    phone_w = 620
    phone_h = 1340
    phone_x = (W - phone_w) // 2
    phone_y = sub_y + 120

    # Draw phone
    draw_phone_frame(img, "", phone_x, phone_y, phone_w, phone_h, corner_r=48)
    draw = ImageDraw.Draw(img)

    # Draw app-specific content on the phone screen
    decorations_fn(draw, phone_x, phone_y, phone_w, phone_h)

    # Floating decorations around the phone
    return img


def screen_home(draw, px, py, pw, ph):
    """Draw home screen content."""
    # Greeting
    try:
        title_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 32)
        body_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
        score_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 64)
        small_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except:
        title_f = body_f = score_f = small_f = ImageFont.load_default()

    y = py + 90
    draw.text((px + 40, y), "GOOD MORNING", fill=TEXT_TERTIARY, font=small_f)
    draw.text((px + 40, y + 24), "Hey there", fill=TEXT_PRIMARY, font=title_f)

    # Wellness score card
    card_y = y + 90
    draw.rounded_rectangle(
        [px + 30, card_y, px + pw - 30, card_y + 280],
        radius=24, fill=WHITE
    )

    # Score ring
    cx = px + pw // 2
    cy = card_y + 130
    r = 70
    draw.arc([cx - r, cy - r, cx + r, cy + r], 0, 360, fill=(229, 227, 222), width=8)
    draw.arc([cx - r, cy - r, cx + r, cy + r], -90, 190, fill=TEAL, width=8)
    draw.text((cx - 30, cy - 30), "78", fill=TEXT_PRIMARY, font=score_f)
    draw.text((cx - 20, cy + 38), "/100", fill=TEXT_TERTIARY, font=small_f)
    draw.text((cx - 50, card_y + 240), "Wellness Score", fill=TEXT_SECONDARY, font=body_f)

    # Quick actions row
    qa_y = card_y + 310
    actions = ["Log", "Check-in", "Meds", "Journal"]
    for i, label in enumerate(actions):
        ax = px + 40 + i * (pw - 80) // 4
        draw.rounded_rectangle([ax, qa_y, ax + 110, qa_y + 90], radius=16, fill=WHITE)
        draw.ellipse([ax + 38, qa_y + 12, ax + 72, qa_y + 46], fill=TEAL + (30,))
        draw.text((ax + 20, qa_y + 58), label, fill=TEXT_SECONDARY, font=small_f)

    # Today's symptoms header
    ts_y = qa_y + 120
    draw.text((px + 40, ts_y), "Today's Symptoms", fill=TEXT_PRIMARY, font=body_f)

    # Symptom entries
    symptoms = [("Headache", "7/10", (239, 68, 68)), ("Fatigue", "5/10", (251, 191, 36)), ("Brain Fog", "4/10", (139, 92, 246))]
    for i, (name, sev, color) in enumerate(symptoms):
        ey = ts_y + 40 + i * 70
        draw.rounded_rectangle([px + 30, ey, px + pw - 30, ey + 58], radius=14, fill=WHITE)
        draw.ellipse([px + 46, ey + 14, px + 76, ey + 44], fill=color + (40,))
        draw.text((px + 90, ey + 16), name, fill=TEXT_PRIMARY, font=body_f)
        draw.text((px + pw - 110, ey + 16), sev, fill=color, font=body_f)


def screen_insights(draw, px, py, pw, ph):
    """Draw insights screen content."""
    try:
        title_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
        body_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
        small_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
        big_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 52)
    except:
        title_f = body_f = small_f = big_f = ImageFont.load_default()

    y = py + 90
    draw.text((px + 40, y), "Insights", fill=TEXT_PRIMARY, font=title_f)

    # Section header
    y += 60
    draw.text((px + 40, y), "WELLNESS SCORE", fill=TEXT_TERTIARY, font=small_f)

    # Score card with ring
    cy = y + 100
    draw.rounded_rectangle([px + 30, y + 30, px + pw - 30, y + 200], radius=20, fill=WHITE)
    cx = px + 120
    r = 50
    draw.arc([cx - r, cy - r, cx + r, cy + r], 0, 360, fill=(229, 227, 222), width=7)
    draw.arc([cx - r, cy - r, cx + r, cy + r], -90, 200, fill=TEAL, width=7)
    draw.text((cx - 22, cy - 22), "78", fill=TEAL, font=title_f)
    draw.text((px + 200, cy - 30), "Good", fill=TEAL, font=title_f)
    draw.text((px + 200, cy + 6), "+3 from last week", fill=TEXT_TERTIARY, font=small_f)

    # Chart section header
    y += 230
    draw.text((px + 40, y), "SYMPTOM ANALYTICS", fill=TEXT_TERTIARY, font=small_f)

    # Donut chart card
    y += 30
    draw.rounded_rectangle([px + 30, y, px + pw - 30, y + 260], radius=20, fill=WHITE)
    draw.text((px + 50, y + 16), "Severity Distribution", fill=TEXT_PRIMARY, font=body_f)

    # Draw donut segments
    dcx = px + pw // 2
    dcy = y + 150
    dr = 65
    colors = [(34, 197, 94), (234, 179, 8), (249, 115, 22), (239, 68, 68)]
    labels = ["Mild", "Moderate", "Severe", "Critical"]
    angles = [0, 120, 220, 300]
    for i in range(4):
        start = angles[i] - 90
        end = (angles[(i + 1) % 4] if i < 3 else 360) - 90
        draw.arc([dcx - dr, dcy - dr, dcx + dr, dcy + dr], start, end, fill=colors[i], width=22)

    # Legend
    for i, (label, color) in enumerate(zip(labels, colors)):
        lx = px + 50 + (i % 2) * (pw // 2 - 30)
        ly = y + 220 + (i // 2) * 22
        draw.ellipse([lx, ly, lx + 10, ly + 10], fill=color)
        draw.text((lx + 16, ly - 2), label, fill=TEXT_SECONDARY, font=small_f)

    # Correlation card
    y += 280
    draw.text((px + 40, y), "CORRELATIONS", fill=TEXT_TERTIARY, font=small_f)
    y += 30
    draw.rounded_rectangle([px + 30, y, px + pw - 30, y + 120], radius=20, fill=WHITE)
    draw.ellipse([px + 50, y + 30, px + 90, y + 70], fill=(96, 165, 250, 50))
    draw.text((px + 110, y + 28), "Low pressure days show", fill=TEXT_PRIMARY, font=body_f)
    draw.text((px + 110, y + 54), "1.2 higher avg severity", fill=TEAL, font=body_f)
    draw.text((px + 110, y + 82), "Weather Impact", fill=TEXT_TERTIARY, font=small_f)


def screen_journal(draw, px, py, pw, ph):
    """Draw journal screen content."""
    try:
        title_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
        body_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
        small_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
    except:
        title_f = body_f = small_f = ImageFont.load_default()

    y = py + 90
    draw.text((px + 40, y), "Journal", fill=TEXT_PRIMARY, font=title_f)
    draw.text((px + 40, y + 40), "Your health diary", fill=TEXT_TERTIARY, font=body_f)

    # Filter chips
    y += 90
    chips = ["All", "Favorites", "Exercise", "Sleep"]
    cx = px + 40
    for i, chip in enumerate(chips):
        cw = len(chip) * 14 + 30
        fill = TEAL if i == 0 else (244, 243, 240)
        text_c = WHITE if i == 0 else TEXT_SECONDARY
        draw.rounded_rectangle([cx, y, cx + cw, y + 36], radius=18, fill=fill)
        draw.text((cx + 15, y + 8), chip, fill=text_c, font=small_f)
        cx += cw + 10

    # Mood streak
    y += 60
    draw.text((px + 40, y), "Mood This Week", fill=TEXT_SECONDARY, font=body_f)
    y += 30
    days = ["M", "T", "W", "T", "F", "S", "S"]
    moods = [3, 4, 4, 2, 3, 5, 4]
    mood_colors = [(239, 68, 68), (249, 115, 22), (234, 179, 8), (34, 197, 94), (0, 196, 154)]
    for i, (d, m) in enumerate(zip(days, moods)):
        dx = px + 50 + i * ((pw - 100) // 7)
        draw.ellipse([dx, y, dx + 36, y + 36], fill=mood_colors[m - 1] + (40,))
        draw.text((dx + 12, y + 8), d, fill=mood_colors[m - 1], font=small_f)

    # Journal entries
    entries = [
        ("Rough morning", "Woke up with a headache...", "2h ago", 2),
        ("Feeling better", "The new medication seems...", "Yesterday", 4),
        ("Doctor visit notes", "Dr. Chen recommended...", "2 days ago", 3),
    ]
    y += 70
    for title, preview, time, mood in entries:
        draw.rounded_rectangle([px + 30, y, px + pw - 30, y + 110], radius=16, fill=WHITE)
        # Mood indicator
        mc = mood_colors[mood - 1]
        draw.rounded_rectangle([px + 44, y + 14, px + 48, y + 96], radius=2, fill=mc)
        draw.text((px + 64, y + 16), title, fill=TEXT_PRIMARY, font=body_f)
        draw.text((px + 64, y + 44), preview, fill=TEXT_TERTIARY, font=small_f)
        draw.text((px + 64, y + 72), time, fill=TEXT_TERTIARY + (150,), font=small_f)
        y += 126


def screen_logging(draw, px, py, pw, ph):
    """Draw symptom logging screen content."""
    try:
        title_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
        body_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 18)
        small_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
        big_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
    except:
        title_f = body_f = small_f = big_f = ImageFont.load_default()

    y = py + 90
    draw.text((px + 40, y), "Log Symptom", fill=TEXT_PRIMARY, font=title_f)

    # Severity slider area
    y += 70
    draw.text((px + 40, y), "How severe is it?", fill=TEXT_SECONDARY, font=body_f)
    y += 50
    draw.rounded_rectangle([px + 30, y, px + pw - 30, y + 200], radius=20, fill=WHITE)

    # Big severity number
    draw.text((px + pw // 2 - 30, y + 20), "7", fill=TEAL, font=big_f)
    draw.text((px + pw // 2 + 25, y + 45), "/10", fill=TEXT_TERTIARY, font=body_f)

    # Severity bar
    bar_y = y + 110
    draw.rounded_rectangle([px + 60, bar_y, px + pw - 60, bar_y + 8], radius=4, fill=(229, 227, 222))
    bar_fill_w = int((pw - 120) * 0.7)
    draw.rounded_rectangle([px + 60, bar_y, px + 60 + bar_fill_w, bar_y + 8], radius=4, fill=TEAL)
    # Thumb
    thumb_x = px + 60 + bar_fill_w
    draw.ellipse([thumb_x - 14, bar_y - 10, thumb_x + 14, bar_y + 18], fill=TEAL)
    draw.ellipse([thumb_x - 6, bar_y - 2, thumb_x + 6, bar_y + 10], fill=WHITE)

    # Labels
    draw.text((px + 60, bar_y + 20), "Mild", fill=TEXT_TERTIARY, font=small_f)
    draw.text((px + pw - 120, bar_y + 20), "Severe", fill=TEXT_TERTIARY, font=small_f)

    # Duration chips
    y += 230
    draw.text((px + 40, y), "Duration", fill=TEXT_SECONDARY, font=body_f)
    y += 35
    durations = ["Minutes", "Hours", "Half Day", "All Day"]
    cx = px + 40
    for i, dur in enumerate(durations):
        dw = len(dur) * 12 + 30
        sel = i == 1
        fill = TEAL if sel else (244, 243, 240)
        text_c = WHITE if sel else TEXT_SECONDARY
        draw.rounded_rectangle([cx, y, cx + dw, y + 36], radius=18, fill=fill)
        draw.text((cx + 15, y + 8), dur, fill=text_c, font=small_f)
        cx += dw + 10

    # Triggers
    y += 60
    draw.text((px + 40, y), "Triggers", fill=TEXT_SECONDARY, font=body_f)
    y += 35
    triggers = ["Stress", "Poor Sleep", "Coffee", "Weather"]
    cx = px + 40
    for i, trig in enumerate(triggers):
        tw = len(trig) * 12 + 30
        sel = i in [0, 2]
        fill = VIOLET + (30,) if sel else (244, 243, 240)
        text_c = VIOLET if sel else TEXT_SECONDARY
        draw.rounded_rectangle([cx, y, cx + tw, y + 36], radius=18, fill=fill)
        draw.text((cx + 15, y + 8), trig, fill=text_c, font=small_f)
        cx += tw + 10

    # Notes
    y += 60
    draw.text((px + 40, y), "Notes", fill=TEXT_SECONDARY, font=body_f)
    y += 35
    draw.rounded_rectangle([px + 30, y, px + pw - 30, y + 100], radius=16, fill=WHITE)
    draw.text((px + 50, y + 16), "Started after lunch meeting...", fill=TEXT_TERTIARY, font=small_f)


def screen_score(draw, px, py, pw, ph):
    """Draw the score reveal screen."""
    try:
        big_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
        body_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
        small_f = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except:
        big_f = body_f = small_f = ImageFont.load_default()

    # Dark background for score reveal
    draw.rounded_rectangle([px, py, px + pw, py + ph], radius=48, fill=BG_LIGHT)

    # Centered score ring
    cx = px + pw // 2
    cy = py + ph // 2 - 80

    # Background glow
    for r in range(120, 0, -3):
        alpha = int(20 * (r / 120))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=TEAL + (alpha,))

    # Ring
    r = 110
    draw.arc([cx - r, cy - r, cx + r, cy + r], 0, 360, fill=(229, 227, 222), width=6)
    draw.arc([cx - r, cy - r, cx + r, cy + r], -90, 190, fill=TEAL, width=6)

    # Particles
    for i in range(8):
        angle = math.radians(i * 45)
        pr = 140
        px2 = int(cx + math.cos(angle) * pr)
        py2 = int(cy + math.sin(angle) * pr)
        draw.ellipse([px2 - 3, py2 - 3, px2 + 3, py2 + 3], fill=TEAL + (100,))

    # Score number
    draw.text((cx - 50, cy - 40), "78", fill=TEXT_PRIMARY, font=big_f)
    draw.text((cx - 30, cy + 50), "out of 100", fill=TEXT_TERTIARY, font=small_f)
    draw.text((cx - 70, cy + 100), "Your Wellness Score", fill=TEXT_PRIMARY, font=body_f)
    draw.text((cx - 85, cy + 135), "Based on your health profile", fill=TEXT_TERTIARY, font=small_f)


def add_decorations(img, draw, headline_lines, phone_y, bold_font, regular_font):
    """Add floating decorations around the phone."""
    try:
        pill_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
    except:
        pill_font = ImageFont.load_default()

    # Sparkles
    sparkle_positions = [
        (120, phone_y + 200, 18, WHITE + (180,)),
        (W - 130, phone_y + 150, 14, WHITE + (150,)),
        (80, phone_y + 800, 12, WHITE + (120,)),
        (W - 90, phone_y + 700, 16, WHITE + (160,)),
        (160, phone_y + 1100, 10, WHITE + (100,)),
        (W - 160, phone_y + 1000, 13, WHITE + (140,)),
    ]
    for sx, sy, ss, sc in sparkle_positions:
        draw_sparkle(draw, sx, sy, ss, sc[:3])

    # Floating dots
    dots = [
        (60, phone_y + 400, 8), (W - 70, phone_y + 500, 6),
        (100, phone_y + 600, 5), (W - 100, phone_y + 900, 7),
    ]
    for dx, dy, dr in dots:
        draw.ellipse([dx - dr, dy - dr, dx + dr, dy + dr], fill=WHITE + (80,))


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    bold_font, regular_font = get_fonts()

    screenshots = [
        (
            "Track Your\nHealth Journey",
            "Smart symptom tracking powered by AI",
            TEAL_DARK, VIOLET,
            screen_home,
        ),
        (
            "Discover Hidden\nPatterns",
            "AI-powered insights from your data",
            (20, 80, 120), TEAL_DARK,
            screen_insights,
        ),
        (
            "Your Private\nHealth Diary",
            "Journal your wellness journey",
            VIOLET, TEAL_DARK,
            screen_journal,
        ),
        (
            "Log Symptoms\nin Seconds",
            "Detailed tracking made effortless",
            TEAL, (30, 60, 100),
            screen_logging,
        ),
        (
            "Your Personalized\nWellness Score",
            "See where you stand at a glance",
            (30, 40, 60), TEAL,
            screen_score,
        ),
    ]

    for i, (headline, subtitle, bg1, bg2, screen_fn) in enumerate(screenshots):
        print(f"Generating screenshot {i + 1}/{len(screenshots)}: {headline.split(chr(10))[0]}...")

        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Background gradient
        draw_gradient_rect(draw, [0, 0, W, H], bg1, bg2)

        # Headline
        headline_y = 140
        lines = headline.split("\n")
        for j, line in enumerate(lines):
            bbox = draw.textbbox((0, 0), line, font=bold_font)
            tw = bbox[2] - bbox[0]
            draw.text(((W - tw) // 2, headline_y + j * 90), line, fill=WHITE, font=bold_font)

        # Subtitle
        sub_y = headline_y + len(lines) * 90 + 20
        bbox = draw.textbbox((0, 0), subtitle, font=regular_font)
        tw = bbox[2] - bbox[0]
        draw.text(((W - tw) // 2, sub_y), subtitle, fill=WHITE + (200,), font=regular_font)

        # Phone mockup
        phone_w = 580
        phone_h = 1260
        phone_x = (W - phone_w) // 2
        phone_y = sub_y + 130

        # Phone bezel
        bezel = 10
        draw.rounded_rectangle(
            [phone_x - bezel, phone_y - bezel, phone_x + phone_w + bezel, phone_y + phone_h + bezel],
            radius=52, fill=(25, 25, 30)
        )
        # Screen
        draw.rounded_rectangle(
            [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
            radius=44, fill=BG_LIGHT
        )

        # Draw screen content
        screen_fn(draw, phone_x, phone_y, phone_w, phone_h)

        # Dynamic island
        ni_w = 140
        ni_h = 40
        ni_x = phone_x + (phone_w - ni_w) // 2
        ni_y = phone_y + 12
        draw.rounded_rectangle([ni_x, ni_y, ni_x + ni_w, ni_y + ni_h], radius=20, fill=(15, 15, 18))

        # Decorations
        add_decorations(img, draw, lines, phone_y, bold_font, regular_font)

        # ECG line decoration at bottom
        ecg_y = phone_y + phone_h + 50
        if ecg_y + 80 < H:
            draw_ecg_decoration(draw, 100, ecg_y, W - 200, WHITE + (40,), line_w=3)

        # Save
        img = img.convert("RGB")
        img.save(os.path.join(OUTPUT_DIR, f"screenshot_{i + 1}.png"), "PNG", quality=95)

    print(f"\nAll {len(screenshots)} screenshots saved to {OUTPUT_DIR}/")
    print("Sizes: 1242×2688 (iPhone 6.5\")")


if __name__ == "__main__":
    main()
