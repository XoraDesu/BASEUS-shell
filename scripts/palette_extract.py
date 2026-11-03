#!/usr/bin/env python3
"""
BASEUS — Matugen Palette Extraction Bridge
Copyright (c) 2026 xoradesu — MIT License

Governed by DEC-011, DEC-014, and DESIGN.md §27–28:
- Exactly 4 primary colors: dominant, secondary, accent, neutral
- 5-step tonal surface luminance hierarchy: surfaceContainerLowest, surfaceContainerLow,
  surfaceContainer, surfaceContainerHigh, surfaceContainerHighest
- Hairline border tokens: outline, outlineVariant, borderSubtle
- Validates WCAG AA contrast ratio (>= 4.5:1) for text readability
- Uses matugen CLI if available, falls back to deterministic extraction
"""

import colorsys
import hashlib
import json
import os
import shutil
import subprocess
import sys


def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join(c * 2 for c in hex_str)
    return tuple(int(hex_str[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def rgb_to_hex(r, g, b):
    return f"#{int(round(r * 255)):02x}{int(round(g * 255)):02x}{int(round(b * 255)):02x}"


def relative_luminance(r, g, b):
    def channel(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast_ratio(rgb1, rgb2):
    l1 = relative_luminance(*rgb1)
    l2 = relative_luminance(*rgb2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def deterministic_fallback(image_path):
    """Generate a calibrated, harmonious 4-color Wabi-sabi palette from path/content hash."""
    seed = os.path.basename(image_path).encode("utf-8")
    if os.path.isfile(image_path):
        try:
            with open(image_path, "rb") as f:
                seed = f.read(4096)
        except Exception:
            pass

    digest = hashlib.sha256(seed).hexdigest()
    h1 = int(digest[0:4], 16) % 360 / 360.0  # Dominant hue
    h2 = (h1 + 0.08) % 1.0                  # Secondary analogous
    h3 = (h1 + 0.52) % 1.0                  # Accent complementary/split

    # Wabi-sabi calibration: restrained saturation, dark neutral canvas
    dominant = colorsys.hls_to_rgb(h1, 0.68, 0.55)
    secondary = colorsys.hls_to_rgb(h2, 0.72, 0.45)
    accent = colorsys.hls_to_rgb(h3, 0.75, 0.65)
    neutral = colorsys.hls_to_rgb(h1, 0.12, 0.18)  # Deep base tone

    # 5-Step Tonal Surfaces
    surface_lowest = colorsys.hls_to_rgb(h1, 0.09, 0.14)
    surface_low = colorsys.hls_to_rgb(h1, 0.12, 0.15)
    surface_container = colorsys.hls_to_rgb(h1, 0.16, 0.16)
    surface_high = colorsys.hls_to_rgb(h1, 0.19, 0.18)
    surface_highest = colorsys.hls_to_rgb(h1, 0.22, 0.20)

    # Hairline borders
    outline = colorsys.hls_to_rgb(h1, 0.24, 0.22)
    outline_variant = (
        surface_container[0] * 0.55 + outline[0] * 0.45,
        surface_container[1] * 0.55 + outline[1] * 0.45,
        surface_container[2] * 0.55 + outline[2] * 0.45,
    )

    # Text roles
    text_primary = (0.75, 0.79, 0.95)
    text_secondary = (0.60, 0.65, 0.80)

    # Ensure contrast against all surfaces (check against highest luminance surface)
    cr = contrast_ratio(text_primary, surface_highest)
    if cr < 4.5:
        text_primary = (0.94, 0.96, 0.99)
        cr = contrast_ratio(text_primary, surface_highest)

    return {
        "dominant": rgb_to_hex(*dominant),
        "secondary": rgb_to_hex(*secondary),
        "accent": rgb_to_hex(*accent),
        "neutral": rgb_to_hex(*neutral),
        "surfaceContainerLowest": rgb_to_hex(*surface_lowest),
        "surfaceContainerLow": rgb_to_hex(*surface_low),
        "surfaceContainer": rgb_to_hex(*surface_container),
        "surfaceContainerHigh": rgb_to_hex(*surface_high),
        "surfaceContainerHighest": rgb_to_hex(*surface_highest),
        "surfaceSolid": rgb_to_hex(*surface_container),
        "surfaceElevated": rgb_to_hex(*surface_high),
        "surfaceHighlight": rgb_to_hex(*surface_highest),
        "surfaceRecessed": rgb_to_hex(*surface_lowest),
        "surfaceBase": rgb_to_hex(*surface_low),
        "outline": rgb_to_hex(*outline),
        "outlineVariant": rgb_to_hex(*outline_variant),
        "borderSubtle": rgb_to_hex(*outline),
        "textPrimary": rgb_to_hex(*text_primary),
        "textSecondary": rgb_to_hex(*text_secondary),
        "contrastRatio": round(cr, 2),
        "source": "fallback"
    }


def extract_with_matugen(image_path):
    matugen_bin = shutil.which("matugen")
    if not matugen_bin:
        return None

    try:
        cmd = [matugen_bin, "image", image_path, "--json", "hex"]
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True, timeout=10)
        data = json.loads(out)
        colors = data.get("colors", {}).get("dark", {})
        if not colors:
            return None

        dominant_hex = colors.get("primary", "#7aa2f7")
        secondary_hex = colors.get("secondary", "#bb9af7")
        accent_hex = colors.get("tertiary", "#7dcfff")
        neutral_hex = colors.get("surface", "#1a1b26")

        lowest_hex = colors.get("surface_container_lowest", "#13131a")
        low_hex = colors.get("surface_container_low", "#16161e")
        container_hex = colors.get("surface_container", "#1f2335")
        high_hex = colors.get("surface_container_high", "#24283b")
        highest_hex = colors.get("surface_container_highest", "#292e42")

        outline_hex = colors.get("outline", "#292e42")
        outline_var_hex = colors.get("outline_variant", "#24283b")

        text_primary_hex = colors.get("on_surface", "#c0caf5")
        text_secondary_hex = colors.get("on_surface_variant", "#9aa5ce")

        cr = contrast_ratio(hex_to_rgb(text_primary_hex), hex_to_rgb(highest_hex))
        if cr < 4.5:
            text_primary_hex = "#f0f4fc"
            cr = contrast_ratio(hex_to_rgb(text_primary_hex), hex_to_rgb(highest_hex))

        return {
            "dominant": dominant_hex,
            "secondary": secondary_hex,
            "accent": accent_hex,
            "neutral": neutral_hex,
            "surfaceContainerLowest": lowest_hex,
            "surfaceContainerLow": low_hex,
            "surfaceContainer": container_hex,
            "surfaceContainerHigh": high_hex,
            "surfaceContainerHighest": highest_hex,
            "surfaceSolid": container_hex,
            "surfaceElevated": high_hex,
            "surfaceHighlight": highest_hex,
            "surfaceRecessed": lowest_hex,
            "surfaceBase": low_hex,
            "outline": outline_hex,
            "outlineVariant": outline_var_hex,
            "borderSubtle": outline_hex,
            "textPrimary": text_primary_hex,
            "textSecondary": text_secondary_hex,
            "contrastRatio": round(cr, 2),
            "source": "matugen"
        }
    except Exception:
        return None


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing wallpaper path argument"}))
        sys.exit(1)

    wallpaper_path = sys.argv[1]
    mock_mode = "--mock" in sys.argv or os.environ.get("BASEUS_SIMULATION") == "1"

    palette = None
    if not mock_mode:
        palette = extract_with_matugen(wallpaper_path)

    if not palette:
        palette = deterministic_fallback(wallpaper_path)

    print(json.dumps(palette))


if __name__ == "__main__":
    main()
