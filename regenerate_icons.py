#!/usr/bin/env python3
"""
Regenerate all Symptly custom icons with stroke-width="2".

Each icon is a 24x24 SVG converted to PDF via rsvg-convert,
placed into the corresponding .imageset folder in Assets.xcassets.
"""

import os
import subprocess
import sys
import tempfile

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ASSETS_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "Symptly", "Assets.xcassets"
)

STROKE_WIDTH = "2"
SW = STROKE_WIDTH  # shorthand

# Common SVG wrapper ----------------------------------------------------------

def svg_wrap(inner: str, *, fill: str = "none") -> str:
    """Wrap inner SVG elements in a 24x24 SVG root."""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
        f'viewBox="0 0 24 24" fill="{fill}" stroke="#000000" '
        f'stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round">'
        f'{inner}</svg>'
    )

def svg_wrap_nofill(inner: str) -> str:
    return svg_wrap(inner, fill="none")

# ---------------------------------------------------------------------------
# SVG definitions for every icon
# ---------------------------------------------------------------------------

ICONS: dict[str, str] = {}

# === TAB ICONS =============================================================

# Home: simple house outline
ICONS["ss.tab.home"] = svg_wrap(
    '<path d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9.5z"/>'
    '<polyline points="9 21 9 14 15 14 15 21"/>'
)

# Home fill: house with fill
ICONS["ss.tab.home.fill"] = (
    f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
    f'viewBox="0 0 24 24" fill="#000000" stroke="#000000" '
    f'stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round">'
    f'<path d="M3 9.5L12 3l9 6.5V20a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9.5z"/>'
    f'<rect x="9" y="14" width="6" height="7" fill="white" stroke="none"/>'
    f'</svg>'
)

# History: clock with counter-clockwise arrow
ICONS["ss.tab.history"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<polyline points="12 7 12 12 15 15"/>'
    '<path d="M3 12a9 9 0 0 1 9-9" fill="none"/>'
)

# Plus: circle with plus
ICONS["ss.tab.plus"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="12" y1="8" x2="12" y2="16"/>'
    '<line x1="8" y1="12" x2="16" y2="12"/>'
)

# Insights: bar chart
ICONS["ss.tab.insights"] = svg_wrap(
    '<line x1="18" y1="20" x2="18" y2="10"/>'
    '<line x1="12" y1="20" x2="12" y2="4"/>'
    '<line x1="6" y1="20" x2="6" y2="14"/>'
)

# Settings: gear outline
ICONS["ss.tab.settings"] = svg_wrap(
    '<circle cx="12" cy="12" r="3"/>'
    '<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06'
    'a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09'
    'a1.65 1.65 0 0 0-1.08-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83'
    'l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09'
    'a1.65 1.65 0 0 0 1.51-1.08 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83'
    'l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09'
    'a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83'
    'l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09'
    'a1.65 1.65 0 0 0-1.51 1z"/>'
)

# Settings fill: same gear but filled
ICONS["ss.tab.settings.fill"] = (
    f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
    f'viewBox="0 0 24 24" fill="#000000" stroke="#000000" '
    f'stroke-width="{SW}" stroke-linecap="round" stroke-linejoin="round">'
    f'<path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06'
    f'a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09'
    f'a1.65 1.65 0 0 0-1.08-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83'
    f'l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09'
    f'a1.65 1.65 0 0 0 1.51-1.08 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83'
    f'l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09'
    f'a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83'
    f'l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09'
    f'a1.65 1.65 0 0 0-1.51 1z"/>'
    f'<circle cx="12" cy="12" r="3" fill="white"/>'
    f'</svg>'
)

# === NAVIGATION =============================================================

ICONS["ss.chevron.left"] = svg_wrap('<polyline points="15 18 9 12 15 6"/>')
ICONS["ss.chevron.right"] = svg_wrap('<polyline points="9 6 15 12 9 18"/>')
ICONS["ss.xmark"] = svg_wrap(
    '<line x1="18" y1="6" x2="6" y2="18"/>'
    '<line x1="6" y1="6" x2="18" y2="18"/>'
)
ICONS["ss.arrow.up"] = svg_wrap(
    '<line x1="12" y1="19" x2="12" y2="5"/>'
    '<polyline points="5 12 12 5 19 12"/>'
)
ICONS["ss.arrow.downright"] = svg_wrap(
    '<line x1="7" y1="7" x2="17" y2="17"/>'
    '<polyline points="17 7 17 17 7 17"/>'
)
ICONS["ss.arrow.right"] = svg_wrap(
    '<line x1="5" y1="12" x2="19" y2="12"/>'
    '<polyline points="12 5 19 12 12 19"/>'
)

# === ACTIONS ================================================================

ICONS["ss.checkmark"] = svg_wrap('<polyline points="20 6 9 17 4 12"/>')
ICONS["ss.checkmark.circle"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<polyline points="9 12 11 14 16 9"/>'
)
ICONS["ss.magnifying"] = svg_wrap(
    '<circle cx="11" cy="11" r="7"/>'
    '<line x1="16.5" y1="16.5" x2="21" y2="21"/>'
)
ICONS["ss.bell"] = svg_wrap(
    '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>'
    '<path d="M13.73 21a2 2 0 0 1-3.46 0"/>'
)
ICONS["ss.bell.badge"] = svg_wrap(
    '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>'
    '<path d="M13.73 21a2 2 0 0 1-3.46 0"/>'
    '<circle cx="18" cy="4" r="3" fill="#000000" stroke="none"/>'
)
ICONS["ss.pencil"] = svg_wrap(
    '<path d="M17 3a2.83 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/>'
)
ICONS["ss.trash"] = svg_wrap(
    '<polyline points="3 6 5 6 21 6"/>'
    '<path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>'
    '<line x1="10" y1="11" x2="10" y2="17"/>'
    '<line x1="14" y1="11" x2="14" y2="17"/>'
)
ICONS["ss.export"] = svg_wrap(
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>'
    '<polyline points="17 8 12 3 7 8"/>'
    '<line x1="12" y1="3" x2="12" y2="15"/>'
)
ICONS["ss.import"] = svg_wrap(
    '<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>'
    '<polyline points="7 10 12 15 17 10"/>'
    '<line x1="12" y1="15" x2="12" y2="3"/>'
)
ICONS["ss.signout"] = svg_wrap(
    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>'
    '<polyline points="16 17 21 12 16 7"/>'
    '<line x1="21" y1="12" x2="9" y2="12"/>'
)
ICONS["ss.lock"] = svg_wrap(
    '<rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>'
    '<path d="M7 11V7a5 5 0 0 1 10 0v4"/>'
)
ICONS["ss.link"] = svg_wrap(
    '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>'
    '<path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>'
)

# === HEALTH / BODY ==========================================================

# ECG: heartbeat line
ICONS["ss.ecg"] = svg_wrap(
    '<polyline points="2 12 6 12 8 8 10 16 12 10 14 14 16 12 22 12"/>'
)

# Headache: head outline with pain lines
ICONS["ss.headache"] = svg_wrap(
    '<path d="M12 2a8 8 0 0 0-8 8c0 3 1.5 5 3 6.5V20a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-3.5'
    'c1.5-1.5 3-3.5 3-6.5a8 8 0 0 0-8-8z"/>'
    '<line x1="9" y1="9" x2="9" y2="13"/>'
    '<line x1="15" y1="9" x2="15" y2="13"/>'
)

# Back pain: spine with pain indicator
ICONS["ss.backpain"] = svg_wrap(
    '<path d="M12 2v20"/>'
    '<path d="M8 6c2 0 2 2 4 2s2-2 4-2"/>'
    '<path d="M8 12c2 0 2 2 4 2s2-2 4-2"/>'
    '<path d="M8 18c2 0 2 2 4 2s2-2 4-2"/>'
)

# Joint pain: two bones meeting
ICONS["ss.jointpain"] = svg_wrap(
    '<circle cx="12" cy="12" r="3"/>'
    '<line x1="5" y1="5" x2="9.5" y2="9.5"/>'
    '<line x1="14.5" y1="14.5" x2="19" y2="19"/>'
    '<circle cx="5" cy="5" r="2"/>'
    '<circle cx="19" cy="19" r="2"/>'
)

# Chest pain: heart with pain lines
ICONS["ss.chestpain"] = svg_wrap(
    '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78'
    'L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/>'
    '<line x1="12" y1="10" x2="12" y2="16"/>'
    '<line x1="9" y1="13" x2="15" y2="13"/>'
)

# Muscle ache: flexed arm
ICONS["ss.muscleache"] = svg_wrap(
    '<path d="M4 17L7 7c.5-2 2-3 3.5-2.5S12 6 12 8l-1 4"/>'
    '<path d="M12 12c1-1 3-1 4 0l4 5c1 1.5 0 3-1.5 3H8c-1.5 0-2.5-1-2-2.5L8 13"/>'
)

# Abdominal: stomach area
ICONS["ss.abdominal"] = svg_wrap(
    '<path d="M12 3c4 0 7 3 7 7 0 5-3 8-5 10a3 3 0 0 1-4 0c-2-2-5-5-5-10 0-4 3-7 7-7z"/>'
)

# Nausea: queasy face
ICONS["ss.nausea"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 15c0 0 1.5-1 4-1s4 1 4 1" fill="none"/>'
    '<path d="M8 15c0 0 1.5 1 4 1s4-1 4-1" fill="none"/>'
)

# Bloating: expanded circle with arrows
ICONS["ss.bloating"] = svg_wrap(
    '<circle cx="12" cy="12" r="7"/>'
    '<line x1="12" y1="5" x2="12" y2="2"/>'
    '<line x1="12" y1="22" x2="12" y2="19"/>'
    '<line x1="5" y1="12" x2="2" y2="12"/>'
    '<line x1="22" y1="12" x2="19" y2="12"/>'
)

# Acid reflux: stomach with upward flame
ICONS["ss.acidreflux"] = svg_wrap(
    '<path d="M7 14c0 3 2 6 5 6s5-3 5-6-2-4-5-4-5 1-5 4z"/>'
    '<path d="M12 10V4"/>'
    '<path d="M10 6l2-2 2 2"/>'
)

# Constipation: blocked/slow indicator
ICONS["ss.constipation"] = svg_wrap(
    '<circle cx="12" cy="14" r="6"/>'
    '<line x1="12" y1="8" x2="12" y2="4"/>'
    '<line x1="9" y1="5" x2="15" y2="5"/>'
    '<line x1="9" y1="3" x2="15" y2="3"/>'
)

# Diarrhea: downward wavy lines
ICONS["ss.diarrhea"] = svg_wrap(
    '<path d="M7 4c0 2 2 3 5 3s5-1 5-3"/>'
    '<path d="M7 9c0 2 2 3 5 3s5-1 5-3"/>'
    '<line x1="9" y1="14" x2="9" y2="20"/>'
    '<line x1="12" y1="14" x2="12" y2="21"/>'
    '<line x1="15" y1="14" x2="15" y2="19"/>'
)

# Dizziness: spiral
ICONS["ss.dizziness"] = svg_wrap(
    '<path d="M12 12m-2 0a2 2 0 1 0 4 0"/>'
    '<path d="M12 10a4 4 0 0 1 4 4"/>'
    '<path d="M16 14a6 6 0 0 1-6 6"/>'
    '<path d="M10 20a8 8 0 0 1-8-8"/>'
    '<path d="M2 12a10 10 0 0 1 10-10"/>'
)

# Brain fog: cloud with question mark
ICONS["ss.brainfog"] = svg_wrap(
    '<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>'
    '<line x1="12" y1="16" x2="12" y2="16.01"/>'
    '<path d="M10 12a2 2 0 1 1 2 2v1"/>'
)

# Numbness: hand with waves
ICONS["ss.numbness"] = svg_wrap(
    '<path d="M18 11V6a2 2 0 0 0-4 0v5"/>'
    '<path d="M14 11V4a2 2 0 0 0-4 0v7"/>'
    '<path d="M10 10V6a2 2 0 0 0-4 0v8c0 4 3 7 7 7h1c4 0 7-3 7-7v-3a2 2 0 0 0-4 0"/>'
    '<path d="M6 9c-1 0-2-.5-2-1.5S5 6 6 6"/>'
)

# Tremors: shaking hand
ICONS["ss.tremors"] = svg_wrap(
    '<path d="M14 4a2 2 0 0 0-4 0v9"/>'
    '<path d="M18 7a2 2 0 0 0-4 0v6"/>'
    '<path d="M10 6a2 2 0 0 0-4 0v8c0 4 3 7 7 7 4 0 7-3 7-7V9a2 2 0 0 0-4 0"/>'
    '<path d="M3 12l2 1 2-1 2 1"/>'
)

# Anxiety: mind with lightning bolt
ICONS["ss.anxiety"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<path d="M13 8l-3 5h4l-3 5"/>'
)

# Depression: sad face
ICONS["ss.depression"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 16c1-1 2.5-2 4-2s3 1 4 2" fill="none"/>'
)

# Insomnia: moon with X (no sleep)
ICONS["ss.insomnia"] = svg_wrap(
    '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>'
    '<line x1="17" y1="2" x2="21" y2="6"/>'
    '<line x1="21" y1="2" x2="17" y2="6"/>'
)

# Mood swings: up/down arrows
ICONS["ss.moodswings"] = svg_wrap(
    '<line x1="7" y1="18" x2="7" y2="6"/>'
    '<polyline points="4 9 7 6 10 9"/>'
    '<line x1="17" y1="6" x2="17" y2="18"/>'
    '<polyline points="14 15 17 18 20 15"/>'
)

# Shortness of breath: lungs with alert
ICONS["ss.shortbreath"] = svg_wrap(
    '<path d="M8 19c-3 0-5-2-5-5 0-2 1-3 2-4l3-5V3"/>'
    '<path d="M16 19c3 0 5-2 5-5 0-2-1-3-2-4l-3-5V3"/>'
    '<line x1="12" y1="14" x2="12" y2="18"/>'
    '<line x1="12" y1="20" x2="12.01" y2="20"/>'
)

# Cough: mouth with air puffs
ICONS["ss.cough"] = svg_wrap(
    '<path d="M6 12a4 4 0 0 1 4-4h2a4 4 0 0 1 0 8h-2"/>'
    '<circle cx="18" cy="8" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="20" cy="11" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="21" cy="14" r="1" fill="#000000" stroke="none"/>'
)

# Wheezing: wavy air lines
ICONS["ss.wheezing"] = svg_wrap(
    '<path d="M3 8c2-2 4 0 6-2s4 0 6-2 4 0 6-2"/>'
    '<path d="M3 14c2-2 4 0 6-2s4 0 6-2 4 0 6-2"/>'
    '<path d="M3 20c2-2 4 0 6-2s4 0 6-2 4 0 6-2"/>'
)

# Congestion: nose with block
ICONS["ss.congestion"] = svg_wrap(
    '<path d="M8 2v6c0 3 2 5 4 6 2-1 4-3 4-6V2"/>'
    '<path d="M6 14c-1 1-2 3-2 5h16c0-2-1-4-2-5"/>'
    '<line x1="10" y1="19" x2="14" y2="19"/>'
)

# Rash: dotted patch
ICONS["ss.rash"] = svg_wrap(
    '<rect x="4" y="4" width="16" height="16" rx="3"/>'
    '<circle cx="9" cy="9" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="15" cy="9" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="9" cy="15" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="15" cy="15" r="1" fill="#000000" stroke="none"/>'
    '<circle cx="12" cy="12" r="1" fill="#000000" stroke="none"/>'
)

# Itching: scratching lines
ICONS["ss.itching"] = svg_wrap(
    '<path d="M5 7l4 4-4 4"/>'
    '<path d="M10 7l4 4-4 4"/>'
    '<path d="M15 7l4 4-4 4"/>'
)

# Dry skin: cracked surface
ICONS["ss.dryskin"] = svg_wrap(
    '<rect x="3" y="3" width="18" height="18" rx="3"/>'
    '<path d="M8 3v8l4 4 4-4V3"/>'
    '<line x1="12" y1="15" x2="12" y2="21"/>'
)

# Fatigue: battery low
ICONS["ss.fatigue"] = svg_wrap(
    '<rect x="2" y="7" width="18" height="10" rx="2"/>'
    '<line x1="22" y1="11" x2="22" y2="13"/>'
    '<rect x="4" y="9" width="4" height="6" rx="1" fill="#000000" stroke="none"/>'
)

# Low energy: gauge at low
ICONS["ss.lowenergy"] = svg_wrap(
    '<path d="M12 2a10 10 0 0 0-10 10h20a10 10 0 0 0-10-10z" fill="none"/>'
    '<line x1="12" y1="12" x2="7" y2="8"/>'
    '<circle cx="12" cy="12" r="1" fill="#000000" stroke="none"/>'
)

# Weakness: broken barbell
ICONS["ss.weakness"] = svg_wrap(
    '<line x1="4" y1="12" x2="20" y2="12"/>'
    '<rect x="2" y="8" width="4" height="8" rx="1"/>'
    '<rect x="18" y="8" width="4" height="8" rx="1"/>'
    '<path d="M11 10l2 4"/>'
)

# === CATEGORY ICONS =========================================================

# Pain category: lightning bolt
ICONS["ss.cat.pain"] = svg_wrap(
    '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>'
)

# Digestive: stomach
ICONS["ss.cat.digestive"] = svg_wrap(
    '<path d="M12 3c4 0 7 3 7 7 0 5-3 8-5 10a3 3 0 0 1-4 0c-2-2-5-5-5-10 0-4 3-7 7-7z"/>'
    '<path d="M12 7v4" />'
)

# Neuro: brain
ICONS["ss.cat.neuro"] = svg_wrap(
    '<path d="M12 2C8 2 5 5 5 9c0 2 .5 3 1.5 4S8 15 8 17v1a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-1'
    'c0-2 .5-2 1.5-4S19 11 19 9c0-4-3-7-7-7z"/>'
    '<line x1="9" y1="21" x2="15" y2="21"/>'
    '<path d="M12 2v6"/>'
    '<path d="M9 8c1.5 1 4.5 1 6 0"/>'
)

# Mental: brain with heart
ICONS["ss.cat.mental"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<path d="M14.5 9a2 2 0 0 0-2.5 1 2 2 0 0 0-2.5-1 2.2 2.2 0 0 0 0 3.5L12 15l2.5-2.5'
    'a2.2 2.2 0 0 0 0-3.5z" fill="none"/>'
)

# Respiratory: lungs
ICONS["ss.cat.respiratory"] = svg_wrap(
    '<path d="M8 19c-3 0-5-2-5-5 0-2 1-3 2-4l3-5V3"/>'
    '<path d="M16 19c3 0 5-2 5-5 0-2-1-3-2-4l-3-5V3"/>'
    '<line x1="12" y1="3" x2="12" y2="19"/>'
)

# Skin: shield/skin patch
ICONS["ss.cat.skin"] = svg_wrap(
    '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>'
)

# Energy: battery
ICONS["ss.cat.energy"] = svg_wrap(
    '<rect x="2" y="7" width="18" height="10" rx="2"/>'
    '<line x1="22" y1="11" x2="22" y2="13"/>'
    '<path d="M11 10l-2 4h4l-2-4z" fill="none"/>'
)

# === MOOD ICONS =============================================================

# Mood 1: very sad
ICONS["ss.mood.1"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 17c1-2 2.5-3 4-3s3 1 4 3" fill="none"/>'
)

# Mood 2: somewhat sad
ICONS["ss.mood.2"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 16c1-1 2.5-2 4-2s3 1 4 2" fill="none"/>'
)

# Mood 3: neutral
ICONS["ss.mood.3"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<line x1="8" y1="15" x2="16" y2="15"/>'
)

# Mood 4: somewhat happy
ICONS["ss.mood.4"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 14c1 1 2.5 2 4 2s3-1 4-2" fill="none"/>'
)

# Mood 5: very happy
ICONS["ss.mood.5"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<line x1="9" y1="9" x2="9.01" y2="9"/>'
    '<line x1="15" y1="9" x2="15.01" y2="9"/>'
    '<path d="M8 13c1 2 2.5 3 4 3s3-1 4-3" fill="none"/>'
)

# === MISC ICONS =============================================================

# Sun
ICONS["ss.sun"] = svg_wrap(
    '<circle cx="12" cy="12" r="5"/>'
    '<line x1="12" y1="1" x2="12" y2="3"/>'
    '<line x1="12" y1="21" x2="12" y2="23"/>'
    '<line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>'
    '<line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>'
    '<line x1="1" y1="12" x2="3" y2="12"/>'
    '<line x1="21" y1="12" x2="23" y2="12"/>'
    '<line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>'
    '<line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>'
)

# Moon with ZZZ
ICONS["ss.moon.zzz"] = svg_wrap(
    '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>'
    '<path d="M17 4h3l-3 3h3"/>'
)

# Flame
ICONS["ss.flame"] = svg_wrap(
    '<path d="M12 2c-3 4-6 7-6 11a6 6 0 0 0 12 0c0-4-3-7-6-11z"/>'
)

# Sparkles
ICONS["ss.sparkles"] = svg_wrap(
    '<path d="M12 2l2 5 5 2-5 2-2 5-2-5-5-2 5-2z"/>'
    '<path d="M19 13l1 2.5 2.5 1-2.5 1-1 2.5-1-2.5L15.5 16.5l2.5-1z"/>'
)

# Crown
ICONS["ss.crown"] = svg_wrap(
    '<path d="M2 18l3-11 5 5 2-8 2 8 5-5 3 11z"/>'
    '<line x1="2" y1="18" x2="22" y2="18"/>'
)

# Star
ICONS["ss.star"] = svg_wrap(
    '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>'
)

# Question mark
ICONS["ss.question"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/>'
    '<line x1="12" y1="17" x2="12.01" y2="17"/>'
)

# Envelope
ICONS["ss.envelope"] = svg_wrap(
    '<rect x="2" y="4" width="20" height="16" rx="2"/>'
    '<polyline points="22 4 12 13 2 4"/>'
)

# Hand raised
ICONS["ss.hand.raised"] = svg_wrap(
    '<path d="M18 10V6a2 2 0 0 0-4 0v4"/>'
    '<path d="M14 10V4a2 2 0 0 0-4 0v6"/>'
    '<path d="M10 10V6a2 2 0 0 0-4 0v8c0 5 3.5 8 8 8 4.5 0 8-3 8-8v-3a2 2 0 0 0-4 0"/>'
)

# Document
ICONS["ss.doc"] = svg_wrap(
    '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>'
    '<polyline points="14 2 14 8 20 8"/>'
)

# Document richtext
ICONS["ss.doc.richtext"] = svg_wrap(
    '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>'
    '<polyline points="14 2 14 8 20 8"/>'
    '<line x1="8" y1="13" x2="16" y2="13"/>'
    '<line x1="8" y1="17" x2="13" y2="17"/>'
)

# Document search
ICONS["ss.doc.search"] = svg_wrap(
    '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h5"/>'
    '<polyline points="14 2 14 8 20 8"/>'
    '<circle cx="17" cy="17" r="3"/>'
    '<line x1="19.5" y1="19.5" x2="22" y2="22"/>'
)

# Globe
ICONS["ss.globe"] = svg_wrap(
    '<circle cx="12" cy="12" r="10"/>'
    '<line x1="2" y1="12" x2="22" y2="12"/>'
    '<path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10'
    ' 15.3 15.3 0 0 1 4-10z"/>'
)

# Apple
ICONS["ss.apple"] = svg_wrap(
    '<path d="M12 3c-1-2-4-2-5-1s-1 3 0 5c-2 0-4 2-4 5s2 7 5 9c1 0 2 0 4-1 2 1 3 1 4 1'
    ' 3-2 5-6 5-9s-2-5-4-5c1-2 1-4 0-5s-4-1-5 1z"/>'
    '<path d="M12 3V1"/>'
)

# Person
ICONS["ss.person"] = svg_wrap(
    '<circle cx="12" cy="7" r="4"/>'
    '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>'
)

# Person 2: two people
ICONS["ss.person.2"] = svg_wrap(
    '<circle cx="9" cy="7" r="3"/>'
    '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>'
    '<circle cx="17" cy="7" r="3"/>'
    '<path d="M23 21v-2a4 4 0 0 0-3-3.87"/>'
)

# List
ICONS["ss.list"] = svg_wrap(
    '<line x1="8" y1="6" x2="21" y2="6"/>'
    '<line x1="8" y1="12" x2="21" y2="12"/>'
    '<line x1="8" y1="18" x2="21" y2="18"/>'
    '<line x1="3" y1="6" x2="3.01" y2="6"/>'
    '<line x1="3" y1="12" x2="3.01" y2="12"/>'
    '<line x1="3" y1="18" x2="3.01" y2="18"/>'
)

# Equal sign
ICONS["ss.equal"] = svg_wrap(
    '<line x1="5" y1="9" x2="19" y2="9"/>'
    '<line x1="5" y1="15" x2="19" y2="15"/>'
)

# Clock
ICONS["ss.clock"] = svg_wrap(
    '<circle cx="12" cy="12" r="9"/>'
    '<polyline points="12 7 12 12 16 14"/>'
)

# Face ID
ICONS["ss.faceid"] = svg_wrap(
    '<path d="M4 8V6a2 2 0 0 1 2-2h2"/>'
    '<path d="M16 4h2a2 2 0 0 1 2 2v2"/>'
    '<path d="M20 16v2a2 2 0 0 1-2 2h-2"/>'
    '<path d="M8 20H6a2 2 0 0 1-2-2v-2"/>'
    '<line x1="9" y1="9" x2="9" y2="11"/>'
    '<line x1="15" y1="9" x2="15" y2="11"/>'
    '<path d="M9 15c.5 1 1.5 1.5 3 1.5s2.5-.5 3-1.5"/>'
)

# Figure run
ICONS["ss.figure.run"] = svg_wrap(
    '<circle cx="13" cy="4" r="2"/>'
    '<path d="M7 21l3-7 3 2v6"/>'
    '<path d="M10 14L7 9l5-1 3 3"/>'
)

# Figure walk
ICONS["ss.figure.walk"] = svg_wrap(
    '<circle cx="12" cy="4" r="2"/>'
    '<path d="M9 21l2-7"/>'
    '<path d="M15 21l-2-7"/>'
    '<path d="M11 14l-3-5 4-1 3 3"/>'
)

# Head brain
ICONS["ss.head.brain"] = svg_wrap(
    '<path d="M12 2C8 2 5 5 5 9c0 2 .5 3 1.5 4S8 15 8 17v1a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-1'
    'c0-2 .5-2 1.5-4S19 11 19 9c0-4-3-7-7-7z"/>'
    '<line x1="9" y1="21" x2="15" y2="21"/>'
    '<path d="M9 10c1 1 2 1 3 0s2-1 3 0"/>'
)

# Heart
ICONS["ss.heart"] = svg_wrap(
    '<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78'
    'L12 21.23l8.84-8.84a5.5 5.5 0 0 0 0-7.78z"/>'
)

# Calendar
ICONS["ss.calendar"] = svg_wrap(
    '<rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>'
    '<line x1="16" y1="2" x2="16" y2="6"/>'
    '<line x1="8" y1="2" x2="8" y2="6"/>'
    '<line x1="3" y1="10" x2="21" y2="10"/>'
)

# Calendar badge
ICONS["ss.calendar.badge"] = svg_wrap(
    '<rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>'
    '<line x1="16" y1="2" x2="16" y2="6"/>'
    '<line x1="8" y1="2" x2="8" y2="6"/>'
    '<line x1="3" y1="10" x2="21" y2="10"/>'
    '<circle cx="18" cy="5" r="3" fill="#000000" stroke="none"/>'
)

# Bed: sleep/rest
ICONS["ss.bed"] = svg_wrap(
    '<path d="M2 12h20v6H2z"/>'
    '<path d="M2 18v2"/>'
    '<path d="M22 18v2"/>'
    '<path d="M2 12V7a2 2 0 0 1 2-2h2a3 3 0 0 1 3 3v4"/>'
    '<line x1="9" y1="12" x2="22" y2="12"/>'
)

# Briefcase
ICONS["ss.briefcase"] = svg_wrap(
    '<rect x="2" y="7" width="20" height="14" rx="2" ry="2"/>'
    '<path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2"/>'
    '<line x1="2" y1="13" x2="22" y2="13"/>'
)

# Cloud
ICONS["ss.cloud"] = svg_wrap(
    '<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>'
)

# Cloud sun
ICONS["ss.cloud.sun"] = svg_wrap(
    '<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>'
    '<line x1="18" y1="2" x2="18" y2="4"/>'
    '<line x1="22" y1="6" x2="20.5" y2="7.5"/>'
    '<line x1="23" y1="12" x2="21" y2="12"/>'
)

# Pills
ICONS["ss.pills"] = svg_wrap(
    '<path d="M6.5 3.5a4.95 4.95 0 0 0-3 8.5l7 7a4.95 4.95 0 0 0 8.5-3 4.95 4.95 0 0 0-1.5-5.5'
    'L10.5 3.5a4.95 4.95 0 0 0-4 0z"/>'
    '<line x1="8.5" y1="8.5" x2="15.5" y2="15.5"/>'
    '<circle cx="18" cy="6" r="3"/>'
)

# Fork knife
ICONS["ss.fork.knife"] = svg_wrap(
    '<line x1="7" y1="2" x2="7" y2="22"/>'
    '<path d="M4 2v5c0 2 1.5 3 3 3s3-1 3-3V2"/>'
    '<line x1="17" y1="2" x2="17" y2="22"/>'
    '<path d="M14 2v7c0 2 1.5 3 3 3"/>'
)

# Wind
ICONS["ss.wind"] = svg_wrap(
    '<path d="M9.59 4.59A2 2 0 1 1 11 8H2"/>'
    '<path d="M12.59 19.41A2 2 0 1 0 14 16H2"/>'
    '<path d="M17.73 7.73A2.5 2.5 0 1 1 19.5 12H2"/>'
)


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

def convert_svg_to_pdf(svg_content: str, pdf_path: str) -> bool:
    """Convert SVG string to PDF using rsvg-convert."""
    try:
        proc = subprocess.run(
            ["rsvg-convert", "-f", "pdf", "-o", pdf_path],
            input=svg_content.encode("utf-8"),
            capture_output=True,
            timeout=30,
        )
        if proc.returncode != 0:
            print(f"  ERROR rsvg-convert: {proc.stderr.decode()}")
            return False
        return True
    except FileNotFoundError:
        print("rsvg-convert not found!")
        return False


def main() -> None:
    if not os.path.isdir(ASSETS_DIR):
        print(f"Assets directory not found: {ASSETS_DIR}")
        sys.exit(1)

    # Verify rsvg-convert is available
    try:
        subprocess.run(["rsvg-convert", "--version"], capture_output=True, check=True)
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("ERROR: rsvg-convert is not available. Install librsvg:")
        print("  brew install librsvg")
        sys.exit(1)

    success_count = 0
    fail_count = 0
    skip_count = 0

    for icon_name, svg_content in sorted(ICONS.items()):
        imageset_dir = os.path.join(ASSETS_DIR, f"{icon_name}.imageset")
        if not os.path.isdir(imageset_dir):
            print(f"  SKIP  {icon_name}, imageset directory not found")
            skip_count += 1
            continue

        pdf_filename = f"{icon_name}.pdf"
        pdf_path = os.path.join(imageset_dir, pdf_filename)

        ok = convert_svg_to_pdf(svg_content, pdf_path)
        if ok:
            print(f"  OK    {icon_name}")
            success_count += 1
        else:
            print(f"  FAIL  {icon_name}")
            fail_count += 1

    print(f"\nDone: {success_count} succeeded, {fail_count} failed, {skip_count} skipped")
    print(f"Total icon definitions: {len(ICONS)}")

    # List any imageset dirs that we did NOT generate
    all_imagesets = set()
    for entry in os.listdir(ASSETS_DIR):
        if entry.startswith("ss.") and entry.endswith(".imageset"):
            name = entry[:-len(".imageset")]
            all_imagesets.add(name)

    defined = set(ICONS.keys())
    missing = all_imagesets - defined
    if missing:
        print(f"\nWARNING: {len(missing)} imageset(s) have no SVG definition:")
        for m in sorted(missing):
            print(f"  - {m}")


if __name__ == "__main__":
    main()
