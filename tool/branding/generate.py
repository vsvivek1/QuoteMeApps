#!/usr/bin/env python3
"""Placeholder brand asset generator for "I Want USA" and "I Want India".

Reads branding/<country>/sizes.json + colors.json and renders every placeholder
file listed in sizes.json (PNG via Pillow, SVG written as text), then emits:

  * lib/core/theme/brand_colors.g.dart        (BrandColors.usa / BrandColors.india)
  * flutter_launcher_icons-<flavor>.yaml       (one per flavor, repo root)
  * flutter_native_splash-<flavor>.yaml        (one per flavor, repo root)
  * branding/<country>/README.md

Usage:
  python3 -m pip install Pillow        # once
  python3 tool/branding/generate.py               # both countries
  python3 tool/branding/generate.py --country usa # one country

No fonts are bundled: the script uses DejaVu Sans (Latin) and any installed
Devanagari-capable font (Noto Sans Devanagari, FreeSans, ...) found via
fontconfig, falling back to Pillow's built-in font. Final artwork should use
Inter + Noto Sans Devanagari (see branding/shared/fonts/README.md).

To swap in a final logo later: replace the mark geometry below (or the PNGs),
re-run this script, then re-run flutter_launcher_icons / flutter_native_splash.
"""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFont, features
except ImportError:  # pragma: no cover
    sys.exit('Pillow is required: python3 -m pip install Pillow')

ROOT = Path(__file__).resolve().parents[2]
BRANDING = ROOT / 'branding'
COUNTRIES = ['usa', 'india']
ENVS = ['Dev', 'Staging', 'Prod']
BADGE = {'usa': 'USA', 'india': 'IN'}
SHORT = {'usa': 'USA', 'india': 'India'}

# --------------------------------------------------------------------------
# Copy (placeholder marketing text). {app} -> app name.
# --------------------------------------------------------------------------
COPY = {
    'need': ('Got a need? Get quotes.', 'Post what you want. Local sellers compete to quote.'),
    'buyers': ('Post once. Compare quotes.', 'Tell {app} what you want and let sellers come to you.'),
    'sellers': ('Sell to people who already want it', 'Get matched to real requests near you. Quote in a tap.'),
    'appliances': ('Appliances, quoted to you', 'ACs, fridges, washers: post it, get local prices.'),
    'home_services': ('Home services, on request', 'Plumbers, cleaners, painters quote on your job.'),
    'event': ('Launch week', 'Post your first request and get quotes within hours.'),
    'download': ('Get the {app} app', 'Post what you want. Get quotes fast.'),
    'seller_week': ('Seller of the week', '{{SELLER_NAME}} - {{CITY}}'),
    'festival': ('{{FESTIVAL}} offers, quoted to you', 'Post what you need this season. Sellers compete.'),
    'brand': (None, None),
}
SCREEN_CAPTIONS = {
    'en-US': ['Post what you want', 'Get quotes from local sellers'],
    'en-IN': ['Post what you want', 'Get quotes from local sellers'],
    'es-US': ['Publica lo que quieres', 'Recibe cotizaciones de vendedores locales'],
    'hi-IN': ['जो चाहिए, पोस्ट करें', 'स्थानीय विक्रेताओं से कोटेशन पाएं'],
}
MOCK = {
    'usa': {'request': 'I want a 65" TV mounted this weekend', 'prices': ['$120', '$135', '$149'],
            'sellers': ['Bay Area Mounts', 'QuickFix Pros', 'Main St. AV']},
    'india': {'request': 'I want a 1.5 ton split AC installed', 'prices': ['₹2,400', '₹2,650', '₹2,800'],
              'sellers': ['Sharma Electricals', 'CoolAir Services', 'Om Sai Traders']},
}
HIGHLIGHT_LABELS = {'requests': 'Requests', 'quotes': 'Quotes', 'sellers': 'Sellers', 'offers': 'Offers',
                    'help': 'Help'}

# --------------------------------------------------------------------------
# Mark geometry, unit square (0..1). Speech bubble + upward arrow + country badge.
# --------------------------------------------------------------------------
BUBBLE = (0.20, 0.18, 0.80, 0.64)
BUBBLE_R = 0.12
TAIL = [(0.29, 0.60), (0.45, 0.60), (0.26, 0.77)]
ARROW_HEAD = [(0.50, 0.265), (0.355, 0.41), (0.645, 0.41)]
ARROW_SHAFT = (0.452, 0.395, 0.548, 0.555)
BADGE_Y = (0.69, 0.83)
BADGE_RIGHT = 0.80
BADGE_PAD = 0.045
BADGE_FONT = 0.092


# --------------------------------------------------------------------------
# Colours / contrast
# --------------------------------------------------------------------------
def rgb(h: str):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(h: str) -> float:
    c = [x / 255 for x in rgb(h)]
    c = [x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def contrast(a: str, b: str) -> float:
    x, y = sorted([lum(a), lum(b)])
    return (y + 0.05) / (x + 0.05)


CONTRAST_PAIRS = [('primary', 'onPrimary'), ('primaryContainer', 'onPrimaryContainer'),
                  ('secondary', 'onSecondary'), ('surface', 'onSurface'), ('surface', 'primary'),
                  ('surfaceVariant', 'onSurfaceVariant'), ('error', 'onError')]


def check_contrast(colors: dict) -> list:
    rows = []
    for mode in ('light', 'dark'):
        m = colors[mode]
        for bg, fg in CONTRAST_PAIRS:
            r = contrast(m[bg], m[fg])
            rows.append((mode, bg, fg, m[bg], m[fg], r))
            if r < 4.5:
                raise SystemExit('AA contrast failure in %s %s/%s: %.2f' % (mode, bg, fg, r))
    return rows


# --------------------------------------------------------------------------
# Fonts (nothing bundled)
# --------------------------------------------------------------------------
_FONT_CACHE: dict = {}


def _fc_files(pattern: str) -> list:
    try:
        out = subprocess.run(['fc-list', pattern, 'file'], capture_output=True, text=True, timeout=20).stdout
    except Exception:
        return []
    return sorted({l.split(':')[0].strip() for l in out.splitlines() if l.strip()})


def _font_path(kind: str):
    if kind in _FONT_CACHE:
        return _FONT_CACHE[kind]
    if kind == 'deva':
        cands = ['/usr/share/fonts/truetype/noto/NotoSansDevanagari-Bold.ttf',
                 '/usr/share/fonts/opentype/noto/NotoSansDevanagari-Bold.ttf',
                 '/usr/share/fonts/truetype/freefont/FreeSansBold.ttf']
        cands += [f for f in _fc_files(':charset=0915') if 'unifont' not in f.lower()]
    elif kind == 'bold':
        cands = ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
                 '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
                 '/Library/Fonts/Arial Bold.ttf', 'C:/Windows/Fonts/arialbd.ttf']
        cands += _fc_files(':style=Bold:lang=en')
    else:
        cands = ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
                 '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
                 '/Library/Fonts/Arial.ttf', 'C:/Windows/Fonts/arial.ttf']
        cands += _fc_files(':style=Regular:lang=en')
    path = next((c for c in cands if Path(c).exists()), None)
    _FONT_CACHE[kind] = path
    return path


def font(size: float, bold: bool = True, text: str = ''):
    size = max(6, int(round(size)))
    deva = any('\u0900' <= ch <= '\u097f' for ch in text)
    kind = 'deva' if deva else ('bold' if bold else 'regular')
    path = _font_path(kind) or _font_path('bold')
    key = (path, size)
    if key in _FONT_CACHE:
        return _FONT_CACHE[key]
    if path:
        kw = {}
        if deva and features.check('raqm'):
            kw['layout_engine'] = ImageFont.Layout.RAQM
        f = ImageFont.truetype(path, size, **kw)
    else:
        f = ImageFont.load_default(size)
    _FONT_CACHE[key] = f
    return f


def text_w(t: str, f) -> float:
    b = f.getbbox(t)
    return b[2] - b[0]


def wrap(t: str, f, maxw: float) -> list:
    words, lines, cur = t.split(), [], ''
    for w in words:
        nxt = (cur + ' ' + w).strip()
        if cur and text_w(nxt, f) > maxw:
            lines.append(cur)
            cur = w
        else:
            cur = nxt
    if cur:
        lines.append(cur)
    return lines


def wrap_balanced(t: str, f, maxw: float) -> list:
    """Wrap to the minimum line count, then narrow the width so lines are similar length."""
    lines = wrap(t, f, maxw)
    if len(lines) < 2:
        return lines
    lo, hi = maxw * 0.4, maxw
    for _ in range(14):
        mid = (lo + hi) / 2
        if len(wrap(t, f, mid)) <= len(lines):
            hi = mid
        else:
            lo = mid
    return wrap(t, f, hi)


def fit(t: str, maxw: float, maxh: float, start: float, bold=True, max_lines=3, min_size=8):
    """Largest font size where wrapped text fits maxw x maxh. Returns (font, lines, line_height)."""
    size = start
    while size >= min_size:
        f = font(size, bold, t)
        lines = wrap_balanced(t, f, maxw)
        lh = size * 1.22
        if len(lines) <= max_lines and all(text_w(l, f) <= maxw for l in lines) and lh * len(lines) <= maxh:
            return f, lines, lh
        size *= 0.93
    f = font(min_size, bold, t)
    return f, wrap(t, f, maxw)[:max_lines], min_size * 1.22


def draw_lines(d: ImageDraw.ImageDraw, lines, f, lh, x, y, fill, align='left'):
    anchor = {'left': 'la', 'center': 'ma', 'right': 'ra'}[align]
    for i, l in enumerate(lines):
        d.text((x, y + i * lh), l, font=f, fill=fill, anchor=anchor)
    return y + lh * len(lines)


# --------------------------------------------------------------------------
# Mark rendering
# --------------------------------------------------------------------------
def badge_box(text: str):
    f = font(BADGE_FONT * 1000, True, text)
    w = text_w(text, f) / 1000 + 2 * BADGE_PAD
    w = max(w, BADGE_Y[1] - BADGE_Y[0])
    return (BADGE_RIGHT - w, BADGE_Y[0], BADGE_RIGHT, BADGE_Y[1])


def outline_points(badge: str | None):
    pts = []
    x0, y0, x1, y1 = BUBBLE
    r = BUBBLE_R
    for cx, cy, a0 in [(x0 + r, y0 + r, 180), (x1 - r, y0 + r, 270), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90)]:
        for k in range(10):
            a = math.radians(a0 + 9 * k)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    pts += TAIL
    if badge:
        bx0, by0, bx1, by1 = badge_box(badge)
        br = (by1 - by0) / 2
        for cx, a0 in [(bx0 + br, 90), (bx1 - br, 270)]:
            for k in range(19):
                a = math.radians(a0 + 10 * k)
                pts.append((cx + br * math.cos(a), (by0 + br) + br * math.sin(a)))
    return pts


def mark_transform(n: int, badge, fit_mode: str, value: float, center=None):
    """Return (k, ox, oy) mapping unit coords p -> p*k + o."""
    pts = outline_points(badge)
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    if fit_mode == 'circle':  # farthest outline point within circle of diameter `value` px
        far = max(math.hypot(x - cx, y - cy) for x, y in pts)
        k = (value / 2) / far
    else:  # 'box': bbox longest side = value px
        k = value / max(max(xs) - min(xs), max(ys) - min(ys))
    tx, ty = center if center else (n / 2, n / 2)
    return k, tx - cx * k, ty - cy * k


def mark_masks(n: int, badge, tf):
    k, ox, oy = tf
    P = lambda x, y: (x * k + ox, y * k + oy)
    shape = Image.new('L', (n, n), 0)
    cut = Image.new('L', (n, n), 0)
    bmask = Image.new('L', (n, n), 0)
    btext = Image.new('L', (n, n), 0)
    d = ImageDraw.Draw(shape)
    d.rounded_rectangle([*P(*BUBBLE[:2]), *P(*BUBBLE[2:])], radius=BUBBLE_R * k, fill=255)
    d.polygon([P(*p) for p in TAIL], fill=255)
    dc = ImageDraw.Draw(cut)
    dc.polygon([P(*p) for p in ARROW_HEAD], fill=255)
    dc.rectangle([*P(*ARROW_SHAFT[:2]), *P(*ARROW_SHAFT[2:])], fill=255)
    if badge:
        bx0, by0, bx1, by1 = badge_box(badge)
        ImageDraw.Draw(bmask).rounded_rectangle([*P(bx0, by0), *P(bx1, by1)], radius=(by1 - by0) / 2 * k, fill=255)
        f = font(BADGE_FONT * k, True, badge)
        ImageDraw.Draw(btext).text(P((bx0 + bx1) / 2, (by0 + by1) / 2), badge, font=f, fill=255, anchor='mm')
    return shape, cut, bmask, btext


def _layer(img, color, mask):
    lay = Image.new('RGBA', img.size, rgb(color) + (0,))
    lay.putalpha(mask)
    return Image.alpha_composite(img, lay)


def render_mark(n: int, fg: str, cut: str | None, badge: str | None = None, badge_fg: str | None = None,
                badge_cut: str | None = None, fit_mode='box', value=None, bg: str | None = None, ss: int = 4):
    """RGBA n x n image with the mark. cut=None -> arrow/badge text are transparent holes."""
    ss = max(1, min(ss, 6000 // max(n, 1)))
    N = n * ss
    value = (value if value is not None else n * 0.8) * ss
    tf = mark_transform(N, badge, fit_mode, value)
    shape, cutm, bmask, btext = mark_masks(N, badge, tf)
    img = Image.new('RGBA', (N, N), (rgb(bg) + (255,)) if bg else (0, 0, 0, 0))
    if cut:
        img = _layer(img, fg, shape)
        img = _layer(img, cut, ImageChops.multiply(cutm, shape))
    else:
        if bg:
            raise ValueError('use cut colour with bg')
        img = _layer(img, fg, ImageChops.subtract(shape, cutm))
    if badge:
        bfg = badge_fg or fg
        if badge_cut:
            img = _layer(img, bfg, bmask)
            img = _layer(img, badge_cut, ImageChops.multiply(btext, bmask))
        else:
            img = _layer(img, bfg, ImageChops.subtract(bmask, btext))
    return img.resize((n, n), Image.LANCZOS) if ss > 1 else img


# --------------------------------------------------------------------------
# SVG writers (hand-written vector equivalents of the geometry above)
# --------------------------------------------------------------------------
def _f(x):
    return ('%.2f' % x).rstrip('0').rstrip('.')


def svg_mark_group(badge, tf, fg, cut_fill=None, badge_fg=None, mask_id='m'):
    """Returns (defs, body). With cut_fill=None, arrow and badge text are knocked out with a mask."""
    k, ox, oy = tf
    P = lambda x, y: '%s,%s' % (_f(x * k + ox), _f(y * k + oy))
    X = lambda x: _f(x * k + ox)
    Y = lambda y: _f(y * k + oy)
    bx0, by0, bx1, by1 = BUBBLE
    bubble = ('<rect x="%s" y="%s" width="%s" height="%s" rx="%s"/>'
              % (X(bx0), Y(by0), _f((bx1 - bx0) * k), _f((by1 - by0) * k), _f(BUBBLE_R * k)))
    tail = '<polygon points="%s"/>' % ' '.join(P(*p) for p in TAIL)
    sx0, sy0, sx1, sy1 = ARROW_SHAFT
    arrow = ('<polygon points="%s"/><rect x="%s" y="%s" width="%s" height="%s"/>'
             % (' '.join(P(*p) for p in ARROW_HEAD), X(sx0), Y(sy0), _f((sx1 - sx0) * k), _f((sy1 - sy0) * k)))
    badge_shape = badge_text = ''
    if badge:
        a0, b0, a1, b1 = badge_box(badge)
        badge_shape = ('<rect x="%s" y="%s" width="%s" height="%s" rx="%s"/>'
                       % (X(a0), Y(b0), _f((a1 - a0) * k), _f((b1 - b0) * k), _f((b1 - b0) / 2 * k)))
        badge_text = ('<text x="%s" y="%s" text-anchor="middle" dominant-baseline="central" '
                      'font-family="Inter, \'DejaVu Sans\', Arial, sans-serif" font-weight="700" font-size="%s">%s</text>'
                      % (X((a0 + a1) / 2), Y((b0 + b1) / 2), _f(BADGE_FONT * k), badge))
    defs, body = '', ''
    if cut_fill:
        body += '<g fill="%s">%s%s</g><g fill="%s">%s</g>' % (fg, bubble, tail, cut_fill, arrow)
        if badge:
            body += '<g fill="%s">%s</g><g fill="%s">%s</g>' % (badge_fg or fg, badge_shape, cut_fill, badge_text)
    else:
        defs = ('<mask id="%s" maskUnits="userSpaceOnUse"><rect x="-10000" y="-10000" width="20000" height="20000" '
                'fill="#fff"/><g fill="#000">%s%s</g></mask>' % (mask_id, arrow, badge_text))
        body = '<g fill="%s" mask="url(#%s)">%s%s</g>' % (fg, mask_id, bubble, tail)
        if badge:
            body += '<g fill="%s" mask="url(#%s)">%s</g>' % (badge_fg or fg, mask_id, badge_shape)
    return defs, body


def svg_doc(w, h, defs, body, title):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n'
            '<title>%s</title>\n<defs>%s</defs>\n%s\n</svg>\n' % (w, h, w, h, escape(title), defs, body))


# --------------------------------------------------------------------------
# PNG layouts
# --------------------------------------------------------------------------
def save_png(img: Image.Image, path: Path, alpha: bool = False):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not alpha and img.mode != 'RGB':
        flat = Image.new('RGB', img.size, (255, 255, 255))
        flat.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
        img = flat
    if alpha and img.mode != 'RGBA':
        img = img.convert('RGBA')
    img.save(path, 'PNG', optimize=True)


def safe_rect(w, h, safe):
    l, t, r, b = safe or [round(w * 0.06), round(h * 0.06), round(w * 0.06), round(h * 0.06)]
    return l, t, w - r, h - b


def wordmark_parts(country):
    return 'I Want', SHORT[country]


def draw_wordmark(d, x, y, height, country, c_main, c_accent, anchor='lm'):
    """Draw 'I Want USA' with the country part in accent colour. Returns width."""
    a, b = wordmark_parts(country)
    f = font(height, True, a)
    sp = text_w('I Want ', f)
    total = sp + text_w(b, f)
    if anchor == 'mm':
        x -= total / 2
    d.text((x, y), a, font=f, fill=c_main, anchor='lm')
    d.text((x + sp, y), b, font=f, fill=c_accent, anchor='lm')
    return total


def wordmark_width(height, country):
    a, b = wordmark_parts(country)
    f = font(height, True, a)
    return text_w('I Want ', f) + text_w(b, f)


def render_logo_full(w, h, country, pal, variant):
    """Horizontal lockup: mark + wordmark on transparent."""
    if variant == 'white':
        fg = main = acc = '#FFFFFF'
    elif variant == 'black':
        fg = main = acc = '#0F172A'
    elif variant == 'dark':
        fg, main, acc = pal['dark']['primary'], pal['dark']['onSurface'], pal['dark']['primary']
    else:
        fg, main, acc = pal['light']['primary'], pal['light']['onSurface'], pal['light']['primary']
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    sc = 1.0
    while True:  # shrink until the lockup fits the canvas width with a margin
        ms = int(h * 0.9 * sc)
        th = h * 0.36 * sc
        tw = wordmark_width(th, country)
        gap = h * 0.08 * sc
        total = ms + gap + tw
        if total <= w * 0.94:
            break
        sc *= 0.97
    m = render_mark(ms, fg, None, value=ms * 0.94)
    x0 = (w - total) / 2
    img.alpha_composite(m, (int(x0), int((h - ms) / 2)))
    draw_wordmark(ImageDraw.Draw(img), x0 + ms + gap, h / 2 + th * 0.04, th, country, main, acc)
    return img


def lockup(img, d, x, y, height, country, mark_fg, mark_cut, main, acc, align='left', badge=None):
    """Mark + wordmark on an opaque canvas. Returns width used."""
    ms = int(height)
    m = render_mark(ms, mark_fg, mark_cut, badge=badge, badge_fg=mark_fg, badge_cut=mark_cut, value=ms * 0.96)
    th = height * 0.42
    tw = wordmark_width(th, country)
    gap = height * 0.14
    total = ms + gap + tw
    if align == 'center':
        x -= total / 2
    img.alpha_composite(m, (int(x), int(y)))
    draw_wordmark(d, x + ms + gap, y + height / 2 + th * 0.04, th, country, main, acc)
    return total


def render_graphic(W, H, country, pal, entry, app_name, sub_override=None, head_override=None):
    S = 2 if max(W, H) <= 2600 else 1
    w, h = W * S, H * S
    L = pal['light']
    bg, on = L['primary'], L['onPrimary']
    img = Image.new('RGBA', (w, h), rgb(bg) + (255,))
    d = ImageDraw.Draw(img)
    l, t, r, b = [v * S for v in safe_rect(W, H, entry.get('safe'))]
    sw, sh = r - l, b - t
    # subtle decorative circles outside the safe content (purely graphic)
    dec = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dec)
    R = max(w, h) * 0.45
    dd.ellipse([w - R * 0.9, -R * 0.9, w + R * 1.1, R * 1.1], fill=(255, 255, 255, 18))
    dd.ellipse([-R * 0.6, h - R * 0.5, R * 0.8, h + R * 0.9], fill=(255, 255, 255, 12))
    img = Image.alpha_composite(img, dec)
    d = ImageDraw.Draw(img)
    head, sub = COPY.get(entry.get('copy', 'need'), COPY['need'])
    head = head_override or head
    sub = sub_override or sub
    head = head and head.format(app=app_name) if head and '{{' not in head else head
    sub = sub and sub.format(app=app_name) if sub and '{{' not in sub else sub
    aspect = sw / sh
    if head is None:  # brand lockup only
        lh = min(sh * 0.8, sw / 4.2)
        lockup(img, d, l + sw / 2, t + (sh - lh) / 2, lh, country, on, bg, on, on, align='center')
        return img.resize((W, H), Image.LANCZOS).convert('RGB') if S > 1 else img.convert('RGB')
    if aspect >= 1.5:  # wide: mark left, text right
        ms = min(sh * 0.78, sw * 0.28)
        m = render_mark(int(ms), on, bg, badge=BADGE[country], badge_fg=on, badge_cut=bg, value=int(ms) * 0.96)
        img.alpha_composite(m, (int(l), int(t + (sh - ms) / 2)))
        tx = l + ms + sw * 0.05
        tw = r - tx
        wm_h = min(sh * 0.11, tw * 0.07)
        fh, hl, hlh = fit(head, tw, sh * 0.5, start=min(sh * 0.2, tw * 0.11), max_lines=2)
        show_sub = sh > 140 * S
        fs, sl, slh = fit(sub, tw, sh * 0.26, start=fh.size * 0.48, bold=False, max_lines=2) if show_sub else (None, [], 0)
        block = wm_h * 1.6 + hlh * len(hl) + (slh * len(sl) + fh.size * 0.3 if sl else 0)
        y = t + (sh - block) / 2
        draw_wordmark(d, tx, y + wm_h / 2, wm_h, country, on, on)
        y += wm_h * 1.6
        y = draw_lines(d, hl, fh, hlh, tx, y, on)
        if sl:
            draw_lines(d, sl, fs, slh, tx, y + fh.size * 0.3, on)
    else:  # tall / square: stacked, centred
        cx = l + sw / 2
        ms = min(sw * 0.42, sh * 0.30)
        fh, hl, hlh = fit(head, sw * 0.92, sh * 0.34, start=min(sw * 0.11, sh * 0.09), max_lines=3)
        fs, sl, slh = fit(sub, sw * 0.86, sh * 0.18, start=fh.size * 0.46, bold=False, max_lines=3)
        wm_h = fh.size * 0.42
        gap = fh.size * 0.5
        block = ms + gap + wm_h + gap * 1.4 + hlh * len(hl) + gap * 0.6 + slh * len(sl)
        y = t + (sh - block) / 2
        m = render_mark(int(ms), on, bg, badge=BADGE[country], badge_fg=on, badge_cut=bg, value=int(ms) * 0.96)
        img.alpha_composite(m, (int(cx - ms / 2), int(y)))
        y += ms + gap
        draw_wordmark(d, cx, y + wm_h / 2, wm_h, country, on, on, anchor='mm')
        y += wm_h + gap * 1.4
        y = draw_lines(d, hl, fh, hlh, cx, y, on, align='center')
        draw_lines(d, sl, fs, slh, cx, y + gap * 0.6, on, align='center')
    out = img.resize((W, H), Image.LANCZOS) if S > 1 else img
    return out.convert('RGB')


def render_video_template(W, H, country, pal, entry, app_name):
    img = render_graphic(W, H, country, pal, entry, app_name).convert('RGBA')
    ov = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    l, t, r, b = safe_rect(W, H, entry.get('safe'))
    shade = (15, 23, 42, 110)
    d.rectangle([0, 0, W, t], fill=shade)
    d.rectangle([0, b, W, H], fill=shade)
    d.rectangle([0, t, l, b], fill=shade)
    d.rectangle([r, t, W, b], fill=shade)
    d.rectangle([l, t, r, b], outline=(255, 255, 255, 160), width=3)
    f = font(28, True)
    d.text((W / 2, t / 2), 'UI overlay - keep clear', font=f, fill=(255, 255, 255, 220), anchor='mm')
    d.text((W / 2, (b + H) / 2), 'Captions / buttons - keep clear', font=f, fill=(255, 255, 255, 220), anchor='mm')
    return Image.alpha_composite(img, ov).convert('RGB')


def render_profile(W, country, pal, entry):
    L = pal['light']
    d_ = entry.get('safe_circle', W)
    if entry.get('transparent'):
        img = Image.new('RGBA', (W, W), (0, 0, 0, 0))
        disc = render_mark(W, L['primary'], None, badge=None, value=W * 0.98)
        return Image.alpha_composite(img, disc)
    return render_mark(W, L['onPrimary'], L['primary'], badge=BADGE[country], badge_fg=L['onPrimary'],
                       badge_cut=L['primary'], fit_mode='circle', value=d_ * 0.78, bg=L['primary'])


def render_icon(W, country, pal, badge=True):
    L = pal['light']
    return render_mark(W, L['onPrimary'], L['primary'], badge=BADGE[country] if badge else None,
                       badge_fg=L['onPrimary'], badge_cut=L['primary'], value=W * 0.70, bg=L['primary'])


def render_highlight(W, H, country, pal, entry):
    L = pal['light']
    S = 2
    img = Image.new('RGBA', (W * S, H * S), rgb(L['primary']) + (255,))
    d = ImageDraw.Draw(img)
    cd = entry.get('safe_circle', 700) * S
    cx, cy = W * S / 2, H * S / 2
    d.ellipse([cx - cd / 2, cy - cd / 2, cx + cd / 2, cy + cd / 2], fill=rgb(L['onPrimary']) + (255,))
    ms = int(cd * 0.42)
    m = render_mark(ms, L['primary'], L['onPrimary'], value=ms * 0.96)
    img.alpha_composite(m, (int(cx - ms / 2), int(cy - cd * 0.30)))
    label = HIGHLIGHT_LABELS.get(entry.get('label'), entry.get('label', '').title())
    f, lines, lh = fit(label, cd * 0.7, cd * 0.18, start=cd * 0.13, max_lines=1)
    draw_lines(d, lines, f, lh, cx, cy + cd * 0.16, L['primary'], align='center')
    return img.resize((W, H), Image.LANCZOS).convert('RGB')


def render_screenshot(W, H, country, pal, locale, idx, caption, app_name):
    L = pal['light']
    S = 1 if W > 1500 else 2
    w, h = W * S, H * S
    img = Image.new('RGBA', (w, h), rgb(L['primaryContainer']) + (255,))
    d = ImageDraw.Draw(img)
    mx = w * 0.08
    # caption
    fcap, cl, clh = fit(caption, w - 2 * mx, h * 0.14, start=w * 0.085, max_lines=2)
    y = h * 0.06
    draw_lines(d, cl, fcap, clh, w / 2, y, L['onPrimaryContainer'], align='center')
    # device panel
    px0, py0, px1 = w * 0.11, h * 0.24, w * 0.89
    py1 = h + w * 0.1
    rad = w * 0.07
    d.rounded_rectangle([px0 - w * 0.018, py0 - w * 0.018, px1 + w * 0.018, py1], radius=rad + w * 0.018,
                        fill=rgb('#0F172A'))
    d.rounded_rectangle([px0, py0, px1, py1], radius=rad, fill=rgb(L['surface']))
    pw = px1 - px0
    u = pw / 100  # panel unit
    # app bar
    d.rounded_rectangle([px0, py0, px1, py0 + 22 * u], radius=rad, fill=rgb(L['primary']))
    d.rectangle([px0, py0 + 12 * u, px1, py0 + 22 * u], fill=rgb(L['primary']))
    ms = int(11 * u)
    m = render_mark(ms, L['onPrimary'], L['primary'], value=ms * 0.96)
    img.alpha_composite(m, (int(px0 + 5 * u), int(py0 + 8 * u)))
    draw_wordmark(d, px0 + 18 * u, py0 + 13.5 * u, 5.2 * u, country, L['onPrimary'], L['onPrimary'])
    y = py0 + 30 * u
    mk = MOCK[country]
    fb, fr = font(4.6 * u, True), font(4.0 * u, False)
    if idx == 0:
        d.text((px0 + 6 * u, y), 'What do you want?', font=fb, fill=rgb(L['onSurface']), anchor='la')
        y += 9 * u
        d.rounded_rectangle([px0 + 6 * u, y, px1 - 6 * u, y + 30 * u], radius=3 * u, outline=rgb(L['outline']),
                            width=max(2, int(0.5 * u)))
        ft, tl, tlh = fit(mk['request'], pw - 20 * u, 24 * u, start=4.4 * u, bold=False, max_lines=3)
        draw_lines(d, tl, ft, tlh, px0 + 10 * u, y + 4 * u, L['onSurface'])
        y += 38 * u
        cx = px0 + 6 * u
        for chip in ['Electronics', 'This weekend', 'Nearby']:
            cw = text_w(chip, fr) + 8 * u
            d.rounded_rectangle([cx, y, cx + cw, y + 9 * u], radius=4.5 * u, fill=rgb(L['surfaceVariant']))
            d.text((cx + cw / 2, y + 4.5 * u), chip, font=fr, fill=rgb(L['onSurfaceVariant']), anchor='mm')
            cx += cw + 3 * u
        y += 18 * u
        for i in range(3):
            d.rounded_rectangle([px0 + 6 * u, y, px0 + 26 * u, y + 20 * u], radius=3 * u, fill=rgb(L['surfaceVariant']))
            d.rounded_rectangle([px0 + 32 * u, y + 3 * u, px1 - (20 + 10 * i) * u, y + 7 * u], radius=2 * u,
                                fill=rgb('#E2E8F0'))
            d.rounded_rectangle([px0 + 32 * u, y + 12 * u, px1 - 40 * u, y + 15 * u], radius=1.5 * u,
                                fill=rgb('#F1F5F9'))
            y += 26 * u
        y += 4 * u
        d.rounded_rectangle([px0 + 6 * u, y, px1 - 6 * u, y + 14 * u], radius=7 * u, fill=rgb(L['primary']))
        d.text(((px0 + px1) / 2, y + 7 * u), 'Post request', font=fb, fill=rgb(L['onPrimary']), anchor='mm')
    else:
        d.text((px0 + 6 * u, y), '3 quotes for your request', font=fb, fill=rgb(L['onSurface']), anchor='la')
        y += 10 * u
        for i, (seller, price) in enumerate(zip(mk['sellers'], mk['prices'])):
            d.rounded_rectangle([px0 + 5 * u, y, px1 - 5 * u, y + 30 * u], radius=4 * u, fill=rgb(L['surface']),
                                outline=rgb('#E2E8F0'), width=max(2, int(0.4 * u)))
            d.ellipse([px0 + 9 * u, y + 7 * u, px0 + 25 * u, y + 23 * u], fill=rgb(L['primaryContainer']))
            d.text((px0 + 17 * u, y + 15 * u), seller[0], font=fb, fill=rgb(L['onPrimaryContainer']), anchor='mm')
            fp = font(5.4 * u, True, price)
            avail = (px1 - 9 * u - text_w(price, fp) - 3 * u) - (px0 + 30 * u)
            fsel, _, _ = fit(seller, avail, 8 * u, start=4.6 * u, max_lines=1)
            d.text((px0 + 30 * u, y + 11 * u), seller, font=fsel, fill=rgb(L['onSurface']), anchor='lm')
            d.text((px0 + 30 * u, y + 20 * u), '★ 4.%d  ·  %d min ago' % (8 - i, 5 + 7 * i), font=fr,
                   fill=rgb(L['onSurfaceVariant']), anchor='lm')
            d.text((px1 - 9 * u, y + 11 * u), price, font=font(5.4 * u, True, price), fill=rgb(L['primary']),
                   anchor='rm')
            y += 35 * u
        y += 4 * u
        d.rounded_rectangle([px0 + 6 * u, y, px1 - 6 * u, y + 14 * u], radius=7 * u, fill=rgb(L['primary']))
        d.text(((px0 + px1) / 2, y + 7 * u), 'Accept best quote', font=fb, fill=rgb(L['onPrimary']), anchor='mm')
    # placeholder tag
    ft = font(2.8 * u, False)
    d.text((w / 2, h * 0.215), 'PLACEHOLDER  ·  %s  ·  %s' % (app_name, locale), font=ft,
           fill=rgb(L['onPrimaryContainer']), anchor='mm')
    out = img.resize((W, H), Image.LANCZOS) if S > 1 else img
    return out.convert('RGB')


# --------------------------------------------------------------------------
# SVG templates
# --------------------------------------------------------------------------
def svg_template(entry, country, pal, app_name):
    W, H = entry['w'], entry['h']
    L = pal['light']
    l, t, r, b = safe_rect(W, H, entry.get('safe'))
    sw, sh = r - l, b - t
    head, sub = COPY[entry.get('copy', 'need')]
    head = (head or '').replace('{app}', app_name)
    sub = (sub or '').replace('{app}', app_name)
    ms = min(sw * 0.36, sh * 0.26)
    k, ox, oy = mark_transform(int(ms), BADGE[country], 'box', ms * 0.96)
    cx = l + sw / 2
    tf = (k, ox + cx - ms / 2, oy + t + sh * 0.06)
    defs, body = svg_mark_group(BADGE[country], tf, L['onPrimary'], cut_fill=L['primary'], badge_fg=L['onPrimary'])
    fs_h = min(sw * 0.085, sh * 0.07)
    y_wm = t + sh * 0.06 + ms + fs_h * 0.9
    y_h = y_wm + fs_h * 1.8
    font_stack = "Inter, 'Noto Sans Devanagari', 'DejaVu Sans', Arial, sans-serif"
    parts = [
        '<rect width="%d" height="%d" fill="%s"/>' % (W, H, L['primary']),
        '<g id="mark">%s</g>' % body,
        '<text id="wordmark" x="%s" y="%s" text-anchor="middle" font-family="%s" font-weight="700" font-size="%s" '
        'fill="%s">%s</text>' % (_f(cx), _f(y_wm), font_stack, _f(fs_h * 0.55), L['onPrimary'], escape(app_name)),
        '<text id="headline" x="%s" y="%s" text-anchor="middle" font-family="%s" font-weight="700" font-size="%s" '
        'fill="%s">{{HEADLINE}}</text>' % (_f(cx), _f(y_h), font_stack, _f(fs_h), L['onPrimary']),
        '<text id="subline" x="%s" y="%s" text-anchor="middle" font-family="%s" font-weight="400" font-size="%s" '
        'fill="%s">{{SUBLINE}}</text>' % (_f(cx), _f(y_h + fs_h * 1.3), font_stack, _f(fs_h * 0.5), L['onPrimary']),
        '<g id="cta"><rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"/>'
        '<text x="%s" y="%s" text-anchor="middle" dominant-baseline="central" font-family="%s" font-weight="700" '
        'font-size="%s" fill="%s">{{CTA}}</text></g>' % (
            _f(cx - sw * 0.3), _f(b - sh * 0.16), _f(sw * 0.6), _f(sh * 0.09), _f(sh * 0.045), L['onPrimary'],
            _f(cx), _f(b - sh * 0.115), font_stack, _f(fs_h * 0.5), L['primary']),
        '<rect id="safe-zone-guide" x="%d" y="%d" width="%d" height="%d" fill="none" stroke="#FFFFFF" '
        'stroke-dasharray="12 8" stroke-width="2" opacity="0" />' % (l, t, sw, sh),
    ]
    comment = ('<!-- %s template for %s. Replace {{HEADLINE}} (e.g. "%s"), {{SUBLINE}} (e.g. "%s") and {{CTA}} '
               '(e.g. "Post a request"). Keep text inside #safe-zone-guide (set its opacity to 1 to see it). '
               'Generated by tool/branding/generate.py. -->' % (
                   Path(entry['path']).stem, app_name, escape(head), escape(sub)))
    return svg_doc(W, H, defs, comment + '\n' + '\n'.join(parts), '%s %s template' % (app_name, Path(entry['path']).stem))


# --------------------------------------------------------------------------
# Config / code emitters
# --------------------------------------------------------------------------
def emit_dart(pals: dict):
    def c(h):
        return 'Color(0xFF%s)' % h.lstrip('#').upper()

    out = ['// GENERATED from branding/<country>/colors.json — do not edit.',
           '// Sources: branding/usa/colors.json, branding/india/colors.json',
           '// Regenerate with: python3 tool/branding/generate.py',
           '',
           "import 'package:flutter/painting.dart';",
           '',
           '/// Brand colours per country app. Light values + `*Dark` values for the dark theme.',
           'class BrandColors {',
           '  const BrandColors({',
           '    required this.primary,', '    required this.secondary,', '    required this.surface,',
           '    required this.error,', '    required this.primaryDark,', '    required this.secondaryDark,',
           '    required this.surfaceDark,', '    required this.errorDark,',
           '  });', '',
           '  final Color primary;', '  final Color secondary;', '  final Color surface;', '  final Color error;',
           '  final Color primaryDark;', '  final Color secondaryDark;', '  final Color surfaceDark;',
           '  final Color errorDark;', '']
    for country in COUNTRIES:
        p = pals[country]
        out += ['  /// %s (%s)' % (p['app_name'], p.get('accent_name', '')),
                '  static const %s = BrandColors(' % country,
                '    primary: %s,' % c(p['light']['primary']),
                '    secondary: %s,' % c(p['light']['secondary']),
                '    surface: %s,' % c(p['light']['surface']),
                '    error: %s,' % c(p['light']['error']),
                '    primaryDark: %s,' % c(p['dark']['primary']),
                '    secondaryDark: %s,' % c(p['dark']['secondary']),
                '    surfaceDark: %s,' % c(p['dark']['surface']),
                '    errorDark: %s,' % c(p['dark']['error']),
                '  );', '']
    out[-1:] = ['}', '']
    path = ROOT / 'lib/core/theme/brand_colors.g.dart'
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(out))
    return path


def emit_flavor_configs(country: str, pal: dict):
    base = 'branding/%s' % country
    L, D = pal['light'], pal['dark']
    files = []
    for env in ENVS:
        flavor = country + env
        hdr = ('# GENERATED by tool/branding/generate.py from %s/ - do not edit; edit the branding folder and regenerate.\n'
               '# Flavor "%s" (Android productFlavors %s + %s -> source set android/app/src/%s/; iOS scheme/xcconfig %s).\n'
               % (base, flavor, country, env.lower(), flavor, flavor))
        icons = hdr + (
            '# Run: dart run flutter_launcher_icons   (picks up every flutter_launcher_icons-<flavor>.yaml)\n'
            'flutter_launcher_icons:\n'
            '  android: "ic_launcher"\n'
            '  ios: true\n'
            '  image_path: "{b}/app_icon/icon_1024.png"\n'
            '  remove_alpha_ios: true\n'
            '  adaptive_icon_background: "{b}/app_icon/android_adaptive_background.png"\n'
            '  adaptive_icon_foreground: "{b}/app_icon/android_adaptive_foreground.png"\n'
            '  adaptive_icon_monochrome: "{b}/app_icon/android_monochrome.png"\n'
            '  # iOS 18+ dark / tinted variants (flutter_launcher_icons >= 0.14.2)\n'
            '  image_path_ios_dark_transparent: "{b}/app_icon/ios_dark.png"\n'
            '  image_path_ios_tinted_grayscale: "{b}/app_icon/ios_tinted.png"\n'
            '  desaturate_tinted_to_grayscale_ios: true\n'
            '  web:\n'
            '    generate: false\n'
            '  windows:\n'
            '    generate: false\n'
            '  macos:\n'
            '    generate: false\n').format(b=base)
        splash = hdr + (
            '# Run: dart run flutter_native_splash:create --flavors usaDev,usaStaging,usaProd,indiaDev,indiaStaging,indiaProd\n'
            'flutter_native_splash:\n'
            '  color: "{bg}"\n'
            '  image: {b}/splash/splash_logo.png\n'
            '  color_dark: "{bgd}"\n'
            '  image_dark: {b}/splash/splash_logo_dark.png\n'
            '  android_12:\n'
            '    image: {b}/splash/android12_splash_icon.png\n'
            '    color: "{bg}"\n'
            '    image_dark: {b}/splash/android12_splash_icon.png\n'
            '    color_dark: "{bgd}"\n'
            '  android: true\n'
            '  ios: true\n'
            '  web: false\n'
            '  fullscreen: false\n').format(b=base, bg=L['surface'], bgd=D['surface'])
        for name, txt in [('flutter_launcher_icons-%s.yaml' % flavor, icons),
                          ('flutter_native_splash-%s.yaml' % flavor, splash)]:
            (ROOT / name).write_text(txt)
            files.append(ROOT / name)
    return files


def emit_country_readme(country, pal, rows, sizes, count):
    L, D = pal['light'], pal['dark']
    lines = [
        '# %s brand kit' % pal['app_name'], '',
        '> Placeholder assets, generated by `tool/branding/generate.py`. Swap the mark/colours for final designs and '
        're-run the generator; file names and sizes stay the same, so no code changes are needed.', '',
        '- **Brand name:** %s (sibling of %s)' % (pal['app_name'],
                                                   'I Want India' if country == 'usa' else 'I Want USA'),
        '- **Accent:** %s `%s` (dark theme `%s`)' % (pal.get('accent_name', ''), L['primary'], D['primary']),
        '- **Icon badge:** "%s" pill in the bottom-right of the mark' % BADGE[country],
        '- **Locales:** %s' % ', '.join(sizes['locales']),
        '- **Fonts:** Inter (Latin)%s; see `../shared/fonts/README.md`' % (
            ' + Noto Sans Devanagari (Hindi)' if country == 'india' else ''),
        '- **Sizes checked:** %s (`sizes.json`, %d entries -> %d files)' % (sizes['checked'], len(sizes['assets']),
                                                                             count), '',
        '## Colours (`colors.json`)', '',
        '| Role | Light | Dark |', '|---|---|---|',
    ]
    for k in L:
        lines.append('| %s | `%s` | `%s` |' % (k, L[k], D[k]))
    lines += ['', '## Contrast (WCAG 2.x, AA needs >= 4.5:1 for body text)', '',
              '| Mode | Background | Foreground | Ratio |', '|---|---|---|---|']
    for mode, bg, fg, bgv, fgv, r in rows:
        lines.append('| %s | %s `%s` | %s `%s` | %.2f:1 |' % (mode, bg, bgv, fg, fgv, r))
    if pal.get('$note'):
        lines += ['', '_Note:_ ' + pal['$note']]
    lines += ['', '## Usage rules', '',
              '- One brand colour plus neutrals (Material 3). Do not introduce extra accent colours.',
              '- Text on the accent is always `onPrimary`; never place body text on `#E8590C`-style light saffron.',
              '- Keep clear space around the mark of at least 25% of its height; never stretch, rotate or recolour it '
              'outside the palette.',
              '- On photos use `logo/logo_full_white.png` (dark photos) or `logo/logo_full_black.png` (light photos).',
              '- Keep text inside the safe zones listed in `sizes.json` (stories, reels, TikTok, YouTube banner).',
              '- The app reads colours from `lib/core/theme/brand_colors.g.dart`, generated from this file.', '',
              '## Regenerate', '', '```sh', 'python3 tool/branding/generate.py --country %s' % country,
              'dart run flutter_launcher_icons',
              'dart run flutter_native_splash:create --flavors %s' % ','.join(country + e for e in ENVS), '```', '',
              'Store screenshots here are placeholder frames; real ones are captured by the integration_test '
              'screenshot driver / fastlane and copied over these paths. Videos are not generated '
              '(see the README.md placeholders in `store/apple/app_previews/` and `ads/tiktok_ads/`).', '']
    (BRANDING / country / 'README.md').write_text('\n'.join(lines))


# --------------------------------------------------------------------------
# Main per-country render
# --------------------------------------------------------------------------
def expand(entry, locales):
    p = entry['path']
    if '{locale}' not in p:
        yield p, None, 0
        return
    for loc in locales:
        if '{n}' in p:
            for i in range(entry.get('count', 1)):
                yield p.replace('{locale}', loc).replace('{n}', '%02d' % (i + 1)), loc, i
        else:
            yield p.replace('{locale}', loc), loc, 0


def render_country(country: str):
    base = BRANDING / country
    sizes = json.loads((base / 'sizes.json').read_text())
    pal = json.loads((base / 'colors.json').read_text())
    rows = check_contrast(pal)
    app = pal['app_name']
    L, D = pal['light'], pal['dark']
    badge = BADGE[country]
    n = 0
    for e in sizes['assets']:
        kind, W, H = e['kind'], e['w'], e['h']
        for rel, loc, idx in expand(e, sizes['locales']):
            out = base / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            n += 1
            if kind == 'text':
                out.write_text(e['content'].replace('{locale}', loc or ''))
            elif kind == 'svg_mark':
                tf = mark_transform(W, badge, 'box', W * 0.8)
                defs, body = svg_mark_group(badge, tf, L['primary'])
                out.write_text(svg_doc(W, H, defs, body, '%s mark' % app))
            elif kind == 'svg_full':
                dark = e.get('theme') == 'dark'
                fg, main = (D['primary'], D['onSurface']) if dark else (L['primary'], L['onSurface'])
                sc = 1.0
                while True:
                    ms, th, gap = H * 0.9 * sc, H * 0.36 * sc, H * 0.08 * sc
                    tw = wordmark_width(th, country)
                    if ms + gap + tw <= W * 0.94:
                        break
                    sc *= 0.97
                x0 = (W - (ms + gap + tw)) / 2
                tf = mark_transform(int(ms), None, 'box', ms * 0.94, center=(x0 + ms / 2, H / 2))
                defs, body = svg_mark_group(None, tf, fg)
                a, b = wordmark_parts(country)
                body += ('\n<text x="%s" y="%s" dominant-baseline="central" font-family="Inter, \'DejaVu Sans\', Arial, '
                         'sans-serif" font-weight="700" font-size="%s"><tspan fill="%s">%s </tspan><tspan fill="%s">%s'
                         '</tspan></text>' % (_f(x0 + ms + gap), _f(H / 2), _f(th), main, a, fg, b))
                out.write_text(svg_doc(W, H, defs, body, '%s logo' % app))
            elif kind == 'svg_favicon':
                tf = mark_transform(W, None, 'box', W * 0.74)
                defs, body = svg_mark_group(None, tf, L['onPrimary'], cut_fill=L['primary'])
                body = '<rect width="%d" height="%d" rx="%s" fill="%s"/>' % (W, H, _f(W * 0.22), L['primary']) + body
                out.write_text(svg_doc(W, H, defs, body, app))
            elif kind == 'svg_template':
                out.write_text(svg_template(e, country, pal, app))
            elif kind == 'logo_mark':
                save_png(render_mark(W, L['primary'], None, badge=badge, value=W * 0.8), out, alpha=True)
            elif kind == 'logo_full':
                save_png(render_logo_full(W, H, country, pal, e.get('variant', 'light')), out, alpha=True)
            elif kind == 'icon':
                save_png(render_icon(W, country, pal), out)
            elif kind == 'icon_rgba':
                save_png(render_icon(W, country, pal), out, alpha=True)
            elif kind == 'favicon':
                img = Image.new('RGBA', (W * 8, W * 8), (0, 0, 0, 0))
                ImageDraw.Draw(img).rounded_rectangle([0, 0, W * 8 - 1, W * 8 - 1], radius=W * 8 * 0.22,
                                                      fill=rgb(L['primary']))
                img.alpha_composite(render_mark(W * 8, L['onPrimary'], L['primary'], value=W * 8 * 0.78, ss=1))
                save_png(img.resize((W, W), Image.LANCZOS), out, alpha=True)
            elif kind == 'adaptive_fg':
                save_png(render_mark(W, L['onPrimary'], L['primary'], badge=badge, badge_fg=L['onPrimary'],
                                     badge_cut=L['primary'], fit_mode='circle', value=e['safe_circle']), out, alpha=True)
            elif kind == 'adaptive_bg':
                save_png(Image.new('RGB', (W, H), rgb(L['primary'])), out)
            elif kind == 'monochrome':
                save_png(render_mark(W, '#FFFFFF', None, badge=badge, fit_mode='circle', value=e['safe_circle']),
                         out, alpha=True)
            elif kind == 'ios_dark':
                save_png(render_mark(W, D['primary'], None, badge=badge, value=W * 0.70), out, alpha=True)
            elif kind == 'ios_tinted':
                img = Image.new('RGBA', (W, W), (0, 0, 0, 255))
                img.alpha_composite(render_mark(W, '#FFFFFF', None, badge=badge, value=W * 0.70))
                save_png(img.convert('L').convert('RGBA'), out, alpha=True)
            elif kind == 'splash_logo':
                fg = D['primary'] if e.get('theme') == 'dark' else L['primary']
                save_png(render_mark(W, fg, None, badge=badge, value=W * 0.9), out, alpha=True)
            elif kind == 'android12_icon':
                d_ = e['safe_circle']
                img = Image.new('RGBA', (W * 2, W * 2), (0, 0, 0, 0))
                c = W
                ImageDraw.Draw(img).ellipse([c - d_, c - d_, c + d_, c + d_], fill=rgb(L['primary']))
                img = img.resize((W, W), Image.LANCZOS)
                img.alpha_composite(render_mark(W, L['onPrimary'], L['primary'], badge=badge, badge_fg=L['onPrimary'],
                                                badge_cut=L['primary'], fit_mode='circle', value=d_ * 0.80))
                save_png(img, out, alpha=True)
            elif kind == 'graphic':
                save_png(render_graphic(W, H, country, pal, e, app), out)
            elif kind == 'video_template':
                save_png(render_video_template(W, H, country, pal, e, app), out)
            elif kind == 'profile':
                save_png(render_profile(W, country, pal, e), out, alpha=bool(e.get('transparent')))
            elif kind == 'highlight':
                save_png(render_highlight(W, H, country, pal, e), out)
            elif kind == 'screenshot':
                if e.get('copy'):
                    cap = COPY[e['copy']][0].format(app=app)
                    if loc and not loc.startswith('en'):
                        cap = SCREEN_CAPTIONS[loc][idx % 2]
                else:
                    cap = SCREEN_CAPTIONS.get(loc, SCREEN_CAPTIONS['en-US'])[idx % 2]
                save_png(render_screenshot(W, H, country, pal, loc, idx % 2, cap, app), out)
            else:
                raise SystemExit('Unknown kind %r in %s' % (kind, e['path']))
    emit_country_readme(country, pal, rows, sizes, n)
    cfgs = emit_flavor_configs(country, pal)
    return pal, rows, n, cfgs


def write_shared(pals):
    shared = BRANDING / 'shared'
    shared.mkdir(parents=True, exist_ok=True)
    tf = mark_transform(1024, None, 'box', 820)
    defs, body = svg_mark_group(None, tf, 'currentColor')
    (shared / 'mark.svg').write_text(svg_doc(1024, 1024, defs, body, 'I Want mark (shared, uses currentColor)'))
    save_png(render_mark(1024, '#0F172A', None, value=820), shared / 'mark_1024.png', alpha=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--country', choices=COUNTRIES, action='append')
    args = ap.parse_args()
    countries = args.country or COUNTRIES
    pals = {}
    for c in COUNTRIES:
        pals[c] = json.loads((BRANDING / c / 'colors.json').read_text())
        check_contrast(pals[c])
    write_shared(pals)
    for c in countries:
        pal, rows, n, cfgs = render_country(c)
        print('%-6s %4d files  primary %s on %s = %.2f:1' % (c, n, pal['light']['primary'], pal['light']['onPrimary'],
                                                               contrast(pal['light']['primary'],
                                                                        pal['light']['onPrimary'])))
    dart = emit_dart(pals)
    print('wrote', dart.relative_to(ROOT))
    print('fonts: latin=%s devanagari=%s raqm=%s' % (_font_path('bold'), _font_path('deva'), features.check('raqm')))


if __name__ == '__main__':
    main()
