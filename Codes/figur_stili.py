import io
import json
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import font_manager
from matplotlib import patheffects as pe
from PIL import Image

KOK = Path(__file__).resolve().parents[1]
VERI = KOK / "R_Data ve Python Data" / "figur_verileri"
if not VERI.is_dir():
    VERI = KOK / "Figures" / "figur_verileri"
SONUC = KOK / "Results"
FIG = KOK / "Figures"
FIG_EK = FIG / "Supplementary"
KONTROL = FIG / "kontrol"
ETIKET = json.loads((KOK / "Codes" / "etiketler.json").read_text(encoding="utf-8"))

MM = 1 / 25.4
CM = 1 / 2.54
TAM = 170 * MM
TEK = 85 * MM

MUREKKEP = "#2B2B2B"
SOLUK = "#6B6B6B"
IZGARA = "#E6E6E6"
ROPE = "#F1ECE2"
REFERANS = "#9A9A9A"
ZEMIN = "#FFFFFF"
IKINCIL = SOLUK

TON = {"M": ["#F6D7C1", "#E5B18D", "#CC8650", "#B5651D", "#8C4300"],
       "D": ["#C4E6E3", "#8FCBC6", "#4EAAA3", "#0D968F", "#00716B"],
       "F": ["#F8D1E7", "#E7A7CC", "#CD77AB", "#8C2D6C", "#640649"]}
RENK_G = {g: t[3] for g, t in TON.items()}
ACIK_G = {g: t[0] for g, t in TON.items()}
KOYU_G = {g: t[4] for g, t in TON.items()}
ISARET_G = {"M": "s", "D": "o", "F": "D"}
GRI = ["#EDEDED", "#D2D2D2", "#B4B4B4", "#8E8E8E", "#5E5E5E"]
HALE = [pe.withStroke(linewidth=2.6, foreground="white")]

BOY = {"panel": 11, "eksen": 9, "tik": 8, "etiket": 8.5, "lejant": 8, "kucuk": 7, "alt_sinir": 6.5}
CIZGI = {"eksen": 0.8, "izgara": 0.5, "a95": 1.0, "a80": 2.6, "medyan": 1.8, "kenar": 0.8, "referans": 0.8}
ALFA_BANT = {50: 0.45, 80: 0.28, 95: 0.14}
ISARET_BOY = 6.0
YAZI_TIPLERI = ("Source Sans 3", "IBM Plex Sans", "Gill Sans")


def yazi_tipi():
    mevcut = {f.name for f in font_manager.fontManager.ttflist}
    for ad in YAZI_TIPLERI:
        if ad in mevcut:
            return ad
    return "DejaVu Sans"


def stil_kur():
    ad = yazi_tipi()
    mpl.rcParams.update({
        "font.family": ad,
        "font.weight": 400,
        "mathtext.fontset": "custom",
        "mathtext.rm": ad,
        "mathtext.sf": ad,
        "mathtext.it": f"{ad}:italic",
        "mathtext.bf": f"{ad}:semibold",
        "mathtext.cal": ad,
        "font.size": BOY["tik"],
        "axes.titlesize": BOY["eksen"],
        "axes.titleweight": 400,
        "axes.labelsize": BOY["eksen"],
        "axes.labelweight": 400,
        "xtick.labelsize": BOY["tik"],
        "ytick.labelsize": BOY["tik"],
        "legend.fontsize": BOY["lejant"],
        "axes.edgecolor": MUREKKEP,
        "axes.labelcolor": MUREKKEP,
        "axes.linewidth": CIZGI["eksen"],
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "axes.grid.axis": "y",
        "axes.axisbelow": True,
        "axes.unicode_minus": True,
        "grid.color": IZGARA,
        "grid.linewidth": CIZGI["izgara"],
        "xtick.color": MUREKKEP,
        "ytick.color": MUREKKEP,
        "xtick.direction": "out",
        "ytick.direction": "out",
        "xtick.major.width": CIZGI["eksen"],
        "ytick.major.width": CIZGI["eksen"],
        "xtick.major.size": 3,
        "ytick.major.size": 3,
        "text.color": MUREKKEP,
        "legend.frameon": False,
        "legend.handlelength": 1.8,
        "figure.facecolor": ZEMIN,
        "axes.facecolor": ZEMIN,
        "savefig.facecolor": ZEMIN,
        "figure.constrained_layout.w_pad": 2 * MM,
        "figure.constrained_layout.h_pad": 2 * MM,
        "figure.constrained_layout.wspace": 0.02,
        "figure.constrained_layout.hspace": 0.02,
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "lines.solid_capstyle": "butt",
    })
    return ad


def panel_etiketi(ax, harf, baslik=None, x=0.0, y=1.0, dy=7):
    ax.annotate(f"({harf})", xy=(x, y), xycoords="axes fraction", xytext=(0, dy), textcoords="offset points",
                ha="left", va="bottom", fontsize=BOY["panel"], fontweight=600, color=MUREKKEP, annotation_clip=False)
    if baslik:
        ax.annotate(baslik, xy=(x, y), xycoords="axes fraction", xytext=(21, dy + 0.5), textcoords="offset points",
                    ha="left", va="bottom", fontsize=BOY["eksen"], color=MUREKKEP, annotation_clip=False)


def panel_etiketi_fig(fig, harf, x, y, baslik=None):
    fig.text(x, y, f"({harf})", fontsize=BOY["panel"], fontweight=600, ha="left", va="top", color=MUREKKEP)
    if baslik:
        fig.text(x + 0.034 * (170 * MM) / fig.get_figwidth(), y - 0.002, baslik, fontsize=BOY["eksen"], ha="left", va="top", color=MUREKKEP)


def nokta_aralik(ax, y, r, renk, isaret="o", acik=False, yatay=True, boy=ISARET_BOY, z=3, kesikli=False):
    a95 = (r["alt"], r["ust"])
    a80 = (r["alt80"], r["ust80"]) if "alt80" in r and np.isfinite(r["alt80"]) else None
    stil = (0, (3, 1.6)) if kesikli else "-"
    if yatay:
        ax.plot(a95, (y, y), color=renk, lw=CIZGI["a95"], ls=stil, zorder=z, solid_capstyle="butt")
        if a80 and not kesikli:
            ax.plot(a80, (y, y), color=renk, lw=CIZGI["a80"], zorder=z, solid_capstyle="butt")
        ax.plot(r["tahmin"], y, isaret, ms=boy, mfc="white" if acik else renk, mec=renk, mew=1.1, zorder=z + 1)
    else:
        ax.plot((y, y), a95, color=renk, lw=CIZGI["a95"], ls=stil, zorder=z, solid_capstyle="butt")
        if a80 and not kesikli:
            ax.plot((y, y), a80, color=renk, lw=CIZGI["a80"], zorder=z, solid_capstyle="butt")
        ax.plot(y, r["tahmin"], isaret, ms=boy, mfc="white" if acik else renk, mec=renk, mew=1.1, zorder=z + 1)


def bant_ic_ice(ax, x, veri, renk, z=2):
    for duzey, alt, ust in ((95, "alt", "ust"), (80, "alt80", "ust80"), (50, "alt50", "ust50")):
        if alt in veri and ust in veri:
            ax.fill_between(x, veri[alt], veri[ust], color=renk, alpha=ALFA_BANT[duzey], lw=0, zorder=z)
    ax.plot(x, veri["tahmin"], color=renk, lw=CIZGI["medyan"], zorder=z + 1, solid_capstyle="round")


def referans_cizgisi(ax, deger, yon="v", z=1):
    (ax.axvline if yon == "v" else ax.axhline)(deger, color=REFERANS, lw=CIZGI["referans"], ls=(0, (3, 2)), zorder=z)


def cakisma_denetle(fig, ad, pay=1.0):
    fig.canvas.draw()
    rnd = fig.canvas.get_renderer()
    tick_yazi, gorunur = set(), set()
    for ax in fig.axes:
        for eksen, sinir in ((ax.xaxis, sorted(ax.get_xlim())), (ax.yaxis, sorted(ax.get_ylim()))):
            for tk in eksen.get_major_ticks() + eksen.get_minor_ticks():
                for lb in (tk.label1, tk.label2):
                    tick_yazi.add(id(lb))
                    if tk.get_visible() and lb.get_visible() and sinir[0] - 1e-9 <= tk.get_loc() <= sinir[1] + 1e-9:
                        gorunur.add(id(lb))
    yazilar = [t for t in fig.findobj(mpl.text.Text) if t.get_visible() and t.get_text().strip() and t.get_alpha() != 0 and (id(t) not in tick_yazi or id(t) in gorunur)]
    kutular = []
    for t in yazilar:
        try:
            kutular.append((t, t.get_window_extent(rnd).expanded(1.0, 1.0)))
        except Exception:
            continue
    bulunan = []
    for i in range(len(kutular)):
        for j in range(i + 1, len(kutular)):
            a, b = kutular[i][1], kutular[j][1]
            if a.width <= 0 or b.width <= 0:
                continue
            gx = min(a.x1, b.x1) - max(a.x0, b.x0)
            gy = min(a.y1, b.y1) - max(a.y0, b.y0)
            if gx > pay and gy > pay:
                bulunan.append((kutular[i][0].get_text()[:40], kutular[j][0].get_text()[:40]))
    gw, gh = fig.bbox.width, fig.bbox.height
    for tt, kt in kutular:
        if kt.x0 < -pay or kt.y0 < -pay or kt.x1 > gw + pay or kt.y1 > gh + pay:
            print(f"UYARI {ad}: figür sınırından taşan yazı: {tt.get_text()[:40]!r}")
    for x, y in bulunan:
        print(f"UYARI {ad}: yazı çakışması: {x!r} ~ {y!r}")
    for ax in fig.axes:
        cizgiler = [sp.get_window_extent(rnd) for sp in ax.spines.values() if sp.get_visible()]
        for t in ax.texts:
            if not (t.get_visible() and t.get_text().strip()):
                continue
            kt = t.get_window_extent(rnd)
            for c in cizgiler:
                if min(kt.x1, c.x1) - max(kt.x0, c.x0) > 0 and min(kt.y1, c.y1) - max(kt.y0, c.y0) > 0:
                    print(f"UYARI {ad}: eksen çizgisine binen yazı: {t.get_text()[:40]!r}")
                    bulunan.append((t.get_text()[:40], "eksen"))
                    break
    kucuk = sorted({round(t.get_fontsize(), 2) for t in yazilar if t.get_fontsize() < BOY["alt_sinir"] - 1e-6})
    if kucuk:
        print(f"UYARI {ad}: {BOY['alt_sinir']} pt altında yazı: {kucuk}")
    return bulunan


def renk_korlugu(yol):
    from colorspacious import cspace_convert
    im = np.asarray(Image.open(yol).convert("RGB")).astype(float) / 255
    for ad, tur in (("doteranopi", "deuteranomaly"), ("protanopi", "protanomaly")):
        sim = np.clip(cspace_convert(im, {"name": "sRGB1+CVD", "cvd_type": tur, "severity": 100}, "sRGB1"), 0, 1)
        Image.fromarray((sim * 255).round().astype("uint8")).save(yol.with_name(yol.name.replace("_onizleme", f"_{ad}")))
    Image.open(yol).convert("L").save(yol.with_name(yol.name.replace("_onizleme", "_gri")))


def kaydet(fig, ad, ek=False):
    cakisma_denetle(fig, ad)
    klasor = FIG_EK if ek else FIG
    klasor.mkdir(parents=True, exist_ok=True)
    KONTROL.mkdir(parents=True, exist_ok=True)
    fig.savefig(klasor / f"{ad}.png", dpi=600)
    fig.savefig(klasor / f"{ad}.pdf", dpi=600)
    tampon = io.BytesIO()
    fig.savefig(tampon, format="png", dpi=600)
    tampon.seek(0)
    Image.open(tampon).convert("RGB").save(klasor / f"{ad}.tiff", compression="tiff_lzw", dpi=(600, 600))
    fig.savefig(KONTROL / f"{ad}_onizleme.png", dpi=150)
    renk_korlugu(KONTROL / f"{ad}_onizleme.png")
    plt.close(fig)
    return [klasor / f"{ad}.{u}" for u in ("png", "pdf", "tiff")]
