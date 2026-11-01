import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.legend_handler import HandlerTuple
from matplotlib.lines import Line2D
from matplotlib.patches import PathPatch, Rectangle
from matplotlib.path import Path as MPath

from figur_stili import (ALFA_BANT, BOY, CIZGI, ETIKET, GRI, HALE, ISARET_BOY, ISARET_G, KOYU_G, MM, MUREKKEP, REFERANS, RENK_G, ROPE, SOLUK, TAM,
                         TON, VERI, bant_ic_ice, kaydet, nokta_aralik, panel_etiketi, panel_etiketi_fig, referans_cizgisi, stil_kur)

stil_kur()
E_SIRA = ["E1", "E2", "E3a", "E3b"]
ISARETLI = {"E1", "E2", "E3a"}
HANCER = "$^{\\dagger}$"


def oku(ad):
    return pd.read_csv(VERI / f"{ad}.csv")


def bin_ayir(n):
    return f"{int(n):,}"


def E_et(k):
    return ETIKET["E_mathtext"][k] + (HANCER if k in ISARETLI else "")


def bant(ax, x0, a0, b0, x1, a1, b1, renk, alfa=1.0, z=1):
    xm = (x0 + x1) / 2
    kod = [MPath.MOVETO, MPath.CURVE4, MPath.CURVE4, MPath.CURVE4, MPath.LINETO, MPath.CURVE4, MPath.CURVE4, MPath.CURVE4, MPath.CLOSEPOLY]
    nok = [(x0, a0), (xm, a0), (xm, a1), (x1, a1), (x1, b1), (xm, b1), (xm, b0), (x0, b0), (x0, a0)]
    ax.add_patch(PathPatch(MPath(nok, kod), facecolor=renk, edgecolor="none", alpha=alfa, zorder=z))


def dugum(ax, x, ust, alt, renk, gen=0.055, z=3):
    ax.add_patch(Rectangle((x - gen / 2, alt), gen, ust - alt, facecolor=renk, edgecolor="none", zorder=z))


def bant_lejant():
    return tuple(Rectangle((0, 0), 1, 1, facecolor=RENK_G["D"], alpha=ALFA_BANT[d], lw=0) for d in (95, 80, 50))


def aralik_lejant(renk=MUREKKEP, isaret="o", acik=False):
    return (Line2D([0], [0], color=renk, lw=CIZGI["a95"]), Line2D([0], [0], color=renk, lw=CIZGI["a80"]),
            Line2D([0], [0], color=renk, lw=0, marker=isaret, ms=ISARET_BOY - 1, mfc="white" if acik else renk, mec=renk))


def orman_ekseni(ax):
    ax.grid(axis="y", visible=False)
    ax.grid(axis="x", visible=True)


def figur1():
    a = oku("fig1a_akis").set_index("dugum")["n"]
    fig = plt.figure(figsize=(TAM, 160 * MM))
    ax = fig.add_axes([0.0, 0.35, 1.0, 0.65])
    ax.set_xlim(-0.66, 6.12)
    ax.set_ylim(-0.04, 1.27)
    ax.axis("off")
    k = 0.84 / a["tum"]
    ana, ana_bant, dis_bant, dis_dugum = GRI[4], GRI[1], GRI[0], GRI[2]
    xs = [0, 0.95, 1.9, 2.85, 3.8, 4.75]
    ust = 1.0
    y = ust
    yil_ara = []
    for yy in (2023, 2024, 2025):
        h = a[f"yil_{yy}"] * k
        dugum(ax, xs[0], y, y - h, ana)
        yil_ara.append((y, y - h))
        ax.text(xs[0] - 0.06, y - h / 2 + 0.006, f"{yy}", ha="right", va="bottom", fontsize=BOY["etiket"] + 0.5, fontweight=600)
        ax.text(xs[0] - 0.06, y - h / 2 - 0.006, bin_ayir(a[f"yil_{yy}"]), ha="right", va="top", fontsize=BOY["tik"], color=SOLUK)
        y = y - h - 0.02
    tum_ust, tum_alt = ust, ust - a["tum"] * k
    yb = tum_ust
    for (u0, a0) in yil_ara:
        h = u0 - a0
        bant(ax, xs[0] + 0.03, u0, a0, xs[1] - 0.03, yb, yb - h, ana_bant)
        yb -= h

    def baslik(x, ad, n):
        ax.text(x, ust + 0.025, bin_ayir(n), ha="center", va="bottom", fontsize=BOY["eksen"], fontweight=600)
        ax.text(x, ust + 0.092, ad, ha="center", va="bottom", fontsize=BOY["tik"], color=SOLUK, linespacing=1.15)

    def dis_etiket(x, yo, ana_metin, n, alt=None):
        ax.text(x + 0.06, yo + 0.006, ana_metin, ha="left", va="bottom", fontsize=BOY["tik"], color=SOLUK, linespacing=1.2)
        ax.text(x + 0.06, yo - 0.006, bin_ayir(n), ha="left", va="top", fontsize=BOY["tik"], color=MUREKKEP, fontweight=600)
        if alt:
            ax.text(x + 0.06, yo - 0.062, alt, ha="left", va="top", fontsize=BOY["kucuk"] + 0.5, color=SOLUK, linespacing=1.3)

    dugum(ax, xs[1], tum_ust, tum_alt, ana)
    baslik(xs[1], "All\nhousehold-years", a["tum"])
    c_h = a["cift"] * k
    u_h = a["uygun"] * k
    q_h = a["Q"] * k
    bant(ax, xs[1] + 0.03, tum_ust, tum_ust - c_h, xs[2] - 0.03, ust, ust - c_h, ana_bant)
    d2 = a["dis_cift_yok"] * k
    t2_ust = ust - c_h - 0.07
    bant(ax, xs[1] + 0.03, tum_ust - c_h, tum_alt, xs[2] - 0.03, t2_ust, t2_ust - d2, dis_bant)
    dugum(ax, xs[2], t2_ust, t2_ust - d2, dis_dugum, gen=0.03)
    dis_etiket(xs[2], t2_ust - d2 - 0.02, "No co-resident\nspouse or\nambiguous\nspouse link", a["dis_cift_yok"])
    dugum(ax, xs[2], ust, ust - c_h, ana)
    baslik(xs[2], "With a\nreference couple", a["cift"])
    bant(ax, xs[2] + 0.03, ust, ust - u_h, xs[3] - 0.03, ust, ust - u_h, ana_bant)
    d3n = a["dis_yas"] + a["dis_kazanc_yok"] + a["dis_kayit_negatif"]
    d3 = d3n * k
    t3_ust = ust - u_h - 0.05
    bant(ax, xs[2] + 0.03, ust - u_h, ust - c_h, xs[3] - 0.03, t3_ust, t3_ust - d3, dis_bant)
    dugum(ax, xs[3], t3_ust, t3_ust - d3, dis_dugum, gen=0.03)
    dis_etiket(xs[3], t3_ust - d3 / 2, "Age, record or earnings criteria", d3n,
               f"age {bin_ayir(a['dis_yas'])}\nno record or negative earnings {bin_ayir(a['dis_kayit_negatif'])}\nno positive couple earnings {bin_ayir(a['dis_kazanc_yok'])}")
    dugum(ax, xs[3], ust, ust - u_h, ana)
    baslik(xs[3], "Eligible\ncouples", a["uygun"])
    bant(ax, xs[3] + 0.03, ust, ust - q_h, xs[4] - 0.03, ust, ust - q_h, ana_bant)
    d4 = a["dis_Q"] * k
    t4_ust = ust - q_h - 0.05
    bant(ax, xs[3] + 0.03, ust - q_h, ust - u_h, xs[4] - 0.03, t4_ust, t4_ust - d4, dis_bant)
    dugum(ax, xs[4], t4_ust, t4_ust - d4, dis_dugum, gen=0.03)
    dis_etiket(xs[4], t4_ust - d4 * 0.68, "Outside\ncommon support", a["dis_Q"])
    dugum(ax, xs[4], ust, ust - q_h, MUREKKEP)
    baslik(xs[4], "Common\nsupport (Q)", a["Q"])
    yk = ust
    yh = ust
    for g in ("M", "D", "F"):
        h = a[f"Q_{g}"] * k
        hg = max(h, 0.012)
        bant(ax, xs[4] + 0.03, yk, yk - h, xs[5] - 0.03, yh, yh - hg, TON[g][1], alfa=0.75)
        dugum(ax, xs[5], yh, yh - hg, RENK_G[g])
        ax.text(xs[5] + 0.06, yh - hg / 2 + 0.006, ETIKET["G"][g], ha="left", va="bottom", fontsize=BOY["etiket"], color=KOYU_G[g], fontweight=600)
        ax.text(xs[5] + 0.06, yh - hg / 2 - 0.006, f"{bin_ayir(a[f'Q_{g}'])}  ·  {a[f'Q_pay_{g}']:.1f}%", ha="left", va="top", fontsize=BOY["tik"], color=SOLUK)
        yk -= h
        yh -= max(hg, 0.035) + 0.08
    zk = sorted(int(i.split("_")[-1]) for i in a.index if i.startswith("Q_zincir_"))
    zx0 = xs[5] - 0.16
    zy = [0.12, 0.06, 0.0][:len(zk)]
    zmax = max(a[f"Q_zincir_{z}"] for z in zk)
    zL = 0.52
    ax.text(zx0, 0.22, f"Linkage chains in Q · {bin_ayir(a['Q_zincir'])}", ha="left", va="bottom", fontsize=BOY["tik"], color=MUREKKEP, fontweight=600)
    ax.text(zx0, 0.21, "by household-years per chain", ha="left", va="top", fontsize=BOY["kucuk"] + 0.5, color=SOLUK)
    for z, yz, ton in zip(zk, zy, (TON["D"][2], TON["D"][3], TON["D"][4])):
        n = a[f"Q_zincir_{z}"]
        x_b = zx0 + 0.42
        ax.plot([x_b, x_b + zL * n / zmax], [yz, yz], color=ton, lw=1.6, solid_capstyle="butt")
        ax.plot(x_b + zL * n / zmax, yz, "o", ms=4.6, color=ton)
        ax.text(x_b - 0.03, yz, f"{z} record{'s' if z > 1 else ''}", ha="right", va="center", fontsize=BOY["kucuk"] + 0.5, color=SOLUK)
        ax.text(x_b + zL * n / zmax + 0.09, yz, bin_ayir(n), ha="left", va="center", fontsize=BOY["kucuk"] + 0.5, color=SOLUK)
    panel_etiketi_fig(fig, "a", 0.012, 0.995)

    bx = fig.add_axes([0.0, 0.0, 1.0, 0.33])
    bx.set_xlim(0, 1)
    bx.set_ylim(0, 1)
    bx.axis("off")
    x0, x1 = 0.25, 0.75
    xM, xF = 0.10, 0.90
    ye = 0.40
    hb = 0.33
    gb = 0.030
    bx.plot([x0, x1], [ye, ye], color=RENK_G["D"], lw=2.4, solid_capstyle="butt", zorder=2)
    for xx in (x0, x1):
        bx.plot(xx, ye, ISARET_G["D"], ms=6, mfc="white", mec=RENK_G["D"], mew=1.4, zorder=3)
    for xa in ((xM + x0) / 2, (x1 + xF) / 2):
        bx.plot([xa, xa], [ye - 0.06, ye + 0.075 + hb], color=GRI[1], lw=0.7, zorder=1)
    for s, et in ((0.1, "$s$ = 0.1"), (0.5, "$s$ = 0.5"), (0.9, "$s$ = 0.9")):
        xx = x0 + s * (x1 - x0)
        bx.plot(xx, ye, ISARET_G["D"], ms=5, color=RENK_G["D"], zorder=3)
        bx.text(xx, ye - 0.065, et, ha="center", va="top", fontsize=BOY["tik"], color=SOLUK)
        bx.add_patch(Rectangle((xx - gb / 2, ye + 0.075), gb, hb * (1 - s), facecolor=RENK_G["M"], edgecolor="white", lw=0.9))
        bx.add_patch(Rectangle((xx - gb / 2, ye + 0.075 + hb * (1 - s)), gb, hb * s, facecolor=RENK_G["F"], edgecolor="white", lw=0.9))
    for xx, g, sifir in ((xM, "M", r"$E_{\mathrm{wife}}$ = 0"), (xF, "F", r"$E_{\mathrm{husband}}$ = 0")):
        bx.add_patch(Rectangle((xx - gb / 2, ye + 0.075), gb, hb, facecolor=RENK_G[g], edgecolor="white", lw=0.9))
        bx.plot(xx, ye, ISARET_G[g], ms=6.5, color=RENK_G[g], zorder=3)
        bx.text(xx, ye - 0.065, sifir, ha="center", va="top", fontsize=BOY["tik"], color=SOLUK)
        bx.text(xx, ye - 0.19, ETIKET["G"][g], ha="center", va="top", fontsize=BOY["etiket"] + 0.5, fontweight=600, color=KOYU_G[g])
        bx.text(xx, ye - 0.275, "a separate category", ha="center", va="top", fontsize=BOY["tik"], color=SOLUK, fontstyle="italic")
    bx.text((x0 + x1) / 2, ye - 0.19, "Dual-earner couples", ha="center", va="top", fontsize=BOY["etiket"] + 0.5, fontweight=600, color=KOYU_G["D"])
    bx.text((x0 + x1) / 2, ye - 0.275, r"wife's share $s = E_{\mathrm{wife}}\,/\,(E_{\mathrm{wife}} + E_{\mathrm{husband}})$, $0 < s < 1$", ha="center", va="top", fontsize=BOY["tik"], color=SOLUK)
    bx.add_patch(Rectangle((0.285, 0.905), 0.015, 0.05, facecolor=RENK_G["M"], edgecolor="none"))
    bx.text(0.306, 0.93, "Husband's net labor earnings", va="center", fontsize=BOY["lejant"], color=MUREKKEP)
    bx.add_patch(Rectangle((0.555, 0.905), 0.015, 0.05, facecolor=RENK_G["F"], edgecolor="none"))
    bx.text(0.576, 0.93, "Wife's net labor earnings", va="center", fontsize=BOY["lejant"], color=MUREKKEP)
    panel_etiketi_fig(fig, "b", 0.012, 0.335)
    return kaydet(fig, "Figure1")


def figur2():
    eg = oku("fig2a_egri")
    nk = oku("fig2a_noktalar").set_index("senaryo")
    yg = oku("fig2a_pay_yogunlugu")
    E = oku("fig2b_E").set_index("buyukluk")
    fig = plt.figure(figsize=(TAM, 92 * MM))
    ax = fig.add_axes([0.085, 0.215, 0.50, 0.68])
    ic = eg[eg["destek_ici"]]
    tum_deg = np.r_[ic["alt"], ic["ust"], [nk.loc[g, "alt"] for g in ("M", "F", "D0.90")], [nk.loc[g, "ust"] for g in ("M", "F", "D0.90")]]
    ymin = np.floor(tum_deg.min() / 5) * 5 - 5
    ymax = np.ceil(tum_deg.max() / 5) * 5
    yuk = (ymax - ymin) * 0.16
    ax.fill_between(yg["s"], ymin, ymin + yuk * yg["yogunluk"] / yg["yogunluk"].max(), facecolor=TON["D"][0], edgecolor=TON["D"][4], lw=CIZGI["kenar"], zorder=1)
    bant_ic_ice(ax, ic["s"].to_numpy(), ic, RENK_G["D"])
    for s in (0.1, 0.5, 0.9):
        ax.axvline(s, color=REFERANS, lw=0.6, ls=(0, (1.2, 2.4)), zorder=1)
    nokta_aralik(ax, 0.9, nk.loc["D0.90"], RENK_G["D"], isaret=ISARET_G["D"], acik=True, yatay=False)
    ax.text(0.885, ic["alt"].min() - (ymax - ymin) * 0.03, "beyond the central\n95% of observed\nshares", fontsize=BOY["tik"], color=SOLUK, ha="right", va="top", linespacing=1.15)
    for g, xx in (("M", -0.16), ("F", 1.13)):
        nokta_aralik(ax, xx, nk.loc[g], RENK_G[g], isaret=ISARET_G[g], yatay=False, boy=ISARET_BOY + 1)
        ax.text(xx, nk.loc[g, "ust"] + (ymax - ymin) * 0.025, ETIKET["G"][g].replace(" earner", "\nearner"), ha="center", va="bottom", fontsize=BOY["etiket"], color=KOYU_G[g], fontweight=600, linespacing=1.1)
    ax.text(ic["s"].iloc[0] + 0.01, ic["ust"].iloc[0] + (ymax - ymin) * 0.02, "Dual-earner", ha="left", va="bottom", fontsize=BOY["etiket"], color=KOYU_G["D"], fontweight=600, path_effects=HALE)
    ax.set_xlim(-0.36, 1.25)
    ax.set_ylim(ymin, ymax)
    ax.yaxis.set_major_locator(plt.MultipleLocator(5))
    ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f"{v:.0f}"))
    ax.set_xticks([0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0])
    ax.set_xticklabels(["0", "0.1", "0.25", "0.5", "0.75", "0.9", "1"])
    ax.spines["bottom"].set_bounds(0, 1)
    ax.set_xlabel("Wife's share of the couple's net labor earnings (dual-earner couples)", labelpad=4)
    ax.set_ylabel("Standardized probability of food deprivation (%)")
    ax.text(0.27, ymin + yuk * 1.05, "distribution of shares", ha="center", va="bottom", fontsize=BOY["tik"], color=SOLUK)
    panel_etiketi(ax, "a", x=-0.13)
    bx = fig.add_axes([0.78, 0.215, 0.205, 0.68])
    yy = np.arange(len(E_SIRA))[::-1]
    deg = np.r_[E.loc[E_SIRA, "alt"], E.loc[E_SIRA, "ust"], -2.5, 2.5]
    lim = max(abs(deg.min()), abs(deg.max())) * 1.12
    bx.axvspan(-2, 2, color=ROPE, lw=0, zorder=0)
    referans_cizgisi(bx, 0)
    for y0, k in zip(yy, E_SIRA):
        nokta_aralik(bx, y0, E.loc[k], MUREKKEP, acik=k in ISARETLI)
    bx.set_yticks(yy)
    bx.set_yticklabels([E_et(k) + "\n" + ETIKET["E_kisa"][k].replace("vs. ", "vs.\n") for k in E_SIRA], linespacing=1.15)
    bx.set_xlim(-lim, lim)
    bx.set_ylim(-0.6, len(E_SIRA) - 0.15)
    bx.set_xlabel("Difference (percentage points)")
    orman_ekseni(bx)
    bx.text(2.2, len(E_SIRA) - 0.22, "±2 points", ha="left", va="top", fontsize=BOY["tik"], color=SOLUK, path_effects=HALE, zorder=4)
    panel_etiketi(bx, "b", x=-0.95)
    tut = [bant_lejant(), aralik_lejant(), aralik_lejant(acik=True)]
    fig.legend(tut, ["50/80/95% credible bands", "Median, 80% and 95% credible intervals", "Relies on the share of 0.9 (†)"], loc="lower center", ncol=3,
               bbox_to_anchor=(0.5, 0.0), handler_map={tuple: HandlerTuple(ndivide=None, pad=0)}, handlelength=2.6, columnspacing=1.6)
    return kaydet(fig, "Figure2")


def figur3():
    kd = oku("fig3a_koca_durumu")
    du = oku("fig3b_duyarlilik")
    fig = plt.figure(figsize=(TAM, 148 * MM))
    sira = [k for k in ["emekli", "issiz", "diger", "calisti"] if k in set(kd.loc[kd["n"] >= 20, "kategori"])]
    kd = kd.set_index("kategori").loc[sira]
    yy = np.arange(len(sira))[::-1]
    a1 = fig.add_axes([0.25, 0.665, 0.29, 0.265])
    a2 = fig.add_axes([0.60, 0.665, 0.385, 0.265], sharey=a1)
    for y0, k in zip(yy, sira):
        r = kd.loc[k]
        a1.plot(r["ham_yayginlik"], y0, "|", ms=12, mew=2.6, color=RENK_G["F"], zorder=3)
        a1.text(r["ham_yayginlik"] + 3, y0, f"{r['ham_yayginlik']:.1f}", ha="left", va="center", fontsize=BOY["tik"], color=SOLUK)
        nokta_aralik(a2, y0, r, RENK_G["F"], isaret=ISARET_G["F"], acik=True)
    a1.set_xlim(0, np.ceil((kd["ham_yayginlik"].max() + 12) / 10) * 10)
    a1.set_xlabel("Crude weighted prevalence (%)")
    a1.set_yticks(yy)
    a1.set_yticklabels([f"{ETIKET['koca_durumu'][k]}\nn = {int(kd.loc[k, 'n']):,}" + ("$^{a}$" if kd.loc[k, "n"] <= 50 else "") for k in sira], linespacing=1.2)
    a1.set_ylim(-0.6, len(sira) - 0.4)
    orman_ekseni(a1)
    lim2 = np.r_[kd["alt"], kd["ust"], -2, 2]
    a2.axvspan(-2, 2, color=ROPE, lw=0, zorder=0)
    referans_cizgisi(a2, 0)
    a2.xaxis.set_major_locator(plt.MultipleLocator(5))
    a2.set_xlim(5 * np.floor((min(lim2.min(), -5) - 0.5) / 5), max(lim2.max(), 5) + 1.2)
    a2.set_xlabel("Standardized $E_{\\mathrm{3a},k}$" + HANCER + " (percentage points)")
    plt.setp(a2.get_yticklabels(), visible=False)
    orman_ekseni(a2)
    panel_etiketi(a1, "a", baslik="Wife-only earner couples, by the husband's status in the income year", x=-0.86)
    kisa = ETIKET["duyarlilik_kisa"]
    satirlar = [("M2", kisa["M2"], 8.2, False), (None, "Sample and period", 7.15, True), ("A1_2025", kisa["A1_2025"], 6.5, False), ("A3_ucret", kisa["A3_ucret"], 5.7, False),
                (None, "Estimation approach", 4.65, True), ("B10_agirliksiz", kisa["B10_agirliksiz"], 4.0, False), ("B11_survey", kisa["B11_survey"], 3.2, False),
                (None, "Target population", 2.15, True), ("A9_tum_uygun", kisa["A9_tum_uygun"], 1.5, False)]
    veri_sat = [r for r in satirlar if r[0] is not None]
    genis = 0.735 / 4
    for j, k in enumerate(E_SIRA):
        ax = fig.add_axes([0.25 + j * (genis + 0.008), 0.165, genis, 0.335])
        sec = du[du["buyukluk"] == k].set_index("kod")
        kodlar = [r[0] for r in veri_sat if r[0] in sec.index]
        deg = np.r_[sec.loc[kodlar, "alt"], sec.loc[kodlar, "ust"], -2.5, 2.5]
        pay = 0.08 * (deg.max() - deg.min())
        ax.axvspan(-2, 2, color=ROPE, lw=0, zorder=0)
        ax.axvline(0, color=MUREKKEP, lw=0.6, zorder=1)
        referans_cizgisi(ax, sec.loc["M2", "tahmin"])
        for kod, et, y0, baslik in veri_sat:
            if kod not in sec.index:
                continue
            r = sec.loc[kod]
            if kod == "B11_survey":
                nokta_aralik(ax, y0, r, MUREKKEP, isaret="D", acik=True, kesikli=True, boy=ISARET_BOY - 0.5)
            else:
                nokta_aralik(ax, y0, r, MUREKKEP, acik=k in ISARETLI)
        ax.set_xlim(deg.min() - pay, deg.max() + pay)
        ax.set_ylim(0.9, 8.8)
        ax.set_yticks([r[2] for r in veri_sat])
        if j == 0:
            ax.set_yticklabels([r[1] for r in veri_sat])
            ax.get_yticklabels()[0].set_fontweight(600)
            for _, et, y0, baslik in satirlar:
                if baslik:
                    ax.text(-0.045, y0, et, transform=ax.get_yaxis_transform(), ha="right", va="center", fontsize=BOY["tik"], color=SOLUK, fontstyle="italic")
        else:
            ax.set_yticklabels([])
        orman_ekseni(ax)
        ax.set_title(E_et(k), fontsize=BOY["eksen"] + 0.5, pad=4)
        ax.xaxis.set_major_locator(plt.MaxNLocator(4))
        if j == 0:
            panel_etiketi(ax, "b", baslik="Sensitivity of the comparisons", x=-1.25, dy=19)
    fig.text(0.25 + 0.37, 0.092, "Difference (percentage points)", ha="center", fontsize=BOY["eksen"])
    leg = [aralik_lejant(), aralik_lejant(acik=True), Line2D([0], [0], color=MUREKKEP, lw=CIZGI["a95"], ls=(0, (3, 1.6)), marker="D", ms=ISARET_BOY - 1.5, mfc="white"),
           Line2D([0], [0], color=REFERANS, lw=CIZGI["referans"], ls=(0, (3, 2)))]
    fig.legend(leg, ["Median, 80% and 95% CrI", "Relies on the share of 0.9 (†)", "Survey-weighted estimate, 95% CI", "Main-model estimate"], loc="lower center", ncol=2,
               bbox_to_anchor=(0.5, 0.0), handler_map={tuple: HandlerTuple(ndivide=None, pad=0)}, handlelength=2.4, columnspacing=1.3)
    return kaydet(fig, "Figure3")


def figurS_ortusme():
    yo = oku("figS_ortusme")
    sn = oku("figS_ortusme_sinirlar").set_index("k")
    kat = ["M", "D_dusuk", "D_orta", "D_yuksek", "F"]
    baslik = {"M": "Husband-only", "D_dusuk": "Dual 0.05–0.15", "D_orta": "Dual 0.45–0.55", "D_yuksek": "Dual 0.85–0.95", "F": "Wife-only"}
    oran = np.array([0.001, 0.05, 0.5, 0.95])
    renk5 = {"M": RENK_G["M"], "D_dusuk": TON["D"][1], "D_orta": TON["D"][3], "D_yuksek": TON["D"][4], "F": RENK_G["F"]}
    cizgi5 = {"M": "-", "D_dusuk": (0, (4, 1.6)), "D_orta": "-", "D_yuksek": (0, (1.2, 1.2)), "F": (0, (6, 1.5, 1.2, 1.5))}
    fig, axs = plt.subplots(1, 5, figsize=(TAM, 72 * MM), sharey=True, layout="constrained")
    for ax, k, harf in zip(axs, kat, "abcde"):
        for g in kat:
            x = yo[(yo["k"] == k) & (yo["G"] == g)]
            ax.plot(x["logit"], x["yogunluk"] / x["yogunluk"].max(), color=renk5[g], lw=1.4, ls=cizgi5[g])
        ax.axvspan(sn.loc[k, "logit_alt"], sn.loc[k, "logit_ust"], color=ROPE, lw=0, zorder=0)
        ax.set_xlim(np.log(1e-4 / (1 - 1e-4)), np.log(0.995 / 0.005))
        ax.set_xticks(np.log(oran / (1 - oran)))
        ax.set_xticklabels(["0.001", "0.05", "0.5", "0.95"])
        ax.set_yticks([])
        ax.spines["left"].set_visible(False)
        ax.grid(False)
        panel_etiketi(ax, harf, baslik=baslik[k])
    axs[2].set_xlabel("Estimated probability of the category (logit scale)")
    leg = [Line2D([0], [0], color=renk5[g], lw=1.6, ls=cizgi5[g]) for g in kat] + [Rectangle((0, 0), 1, 1, color=ROPE)]
    fig.legend(leg, [baslik[g] for g in kat] + ["Common support"], loc="outside lower center", ncol=3, handlelength=2.4, columnspacing=1.6)
    return kaydet(fig, "FigureS1", ek=True)


def figurS_oncel_sigma():
    oo = oku("figS_oncel_ongoru")
    sg = oku("figS_sigma_zincir")
    fig, axs = plt.subplots(1, 3, figsize=(TAM, 72 * MM), layout="constrained")
    axs[0].hist(oo["yayginlik"], bins=40, range=(0, 100), color=GRI[3], edgecolor="white", lw=0.4)
    axs[0].set_xlabel("Prior predictive weighted prevalence (%)")
    axs[0].set_ylabel("Draws")
    axs[1].hist(oo["E4"], bins=50, color=GRI[3], edgecolor="white", lw=0.4)
    axs[1].set_xlabel("Prior predictive $E_{4}$ (percentage points)")
    axs[1].set_ylabel("Draws")
    axs[2].set_ylabel("Density")
    axs[2].plot(sg["sigma"], sg["prior_hn1"] * 3, color=REFERANS, lw=1.3, ls=(0, (3, 2)), label="Prior HN(0, 1) ×3")
    kuyruk = lambda x: np.where(x > np.nanmax(x) * 1e-3, x, np.nan)
    axs[2].fill_between(sg["sigma"], 0, kuyruk(sg["posterior"]), color=TON["D"][0], lw=0)
    axs[2].plot(sg["sigma"], kuyruk(sg["posterior"]), color=RENK_G["D"], lw=CIZGI["medyan"], label="Posterior, HN(0, 1)")
    sdos = VERI / "figS_sigma_zincir_duyarlilik.csv"
    ust_sinir = sg.loc[sg["posterior"] > sg["posterior"].max() * 0.01, "sigma"].max()
    if sdos.exists():
        sd = pd.read_csv(sdos)
        for kod, et, cizgi in (("B14_sigma2", "Posterior, HN(0, 2)", (0, (4, 1.5))), ("B14b_sigma5", "Posterior, HN(0, 5)", (0, (1, 1.2)))):
            x = sd[sd["model"] == kod]
            if len(x):
                axs[2].plot(x["sigma"], kuyruk(x["posterior"].to_numpy()), color=MUREKKEP, lw=1.2, ls=cizgi, label=et)
                ust_sinir = max(ust_sinir, x.loc[x["posterior"] > x["posterior"].max() * 0.01, "sigma"].max())
    axs[2].set_xlabel("Linkage-chain SD, $\\sigma_{\\mathrm{chain}}$")
    axs[2].set_xlim(0, ust_sinir + 0.4)
    for ax, harf in zip(axs, "abc"):
        panel_etiketi(ax, harf)
    tut, et = axs[2].get_legend_handles_labels()
    fig.legend(tut, et, loc="outside lower center", ncol=4, handlelength=2.4, columnspacing=1.6)
    return kaydet(fig, "FigureS2", ek=True)


def ppc_etiket(kontrol, grup):
    kisa = {"M": "Husband-\nonly", "D": "Dual", "F": "Wife-\nonly"}
    if kontrol == "G_yil":
        g, yil = grup.split(" ")
        return f"{kisa[g]}\n{yil}"
    if kontrol == "pay":
        if grup in ("M", "F"):
            return kisa[grup]
        a, b = grup.replace("D ", "").strip("[)]").split(", ")
        return f"Dual\n{a}–{b}"
    return grup


def figurS_ppc():
    pp = oku("figS_ppc")
    fig = plt.figure(figsize=(TAM, 125 * MM))
    sira = {"G_yil": [f"{g} {y}" for g in ("M", "D", "F") for y in (2023, 2024, 2025)],
            "pay": ["M", "D [0, 0.2)", "D [0.2, 0.4)", "D [0.4, 0.6)", "D [0.6, 0.8)", "D [0.8, 1]", "F"]}
    sec = [("G_yil", "Earner structure × survey year"), ("pay", "Earner structure and wife's share"), ("ibbs2", "NUTS-2 region")]
    konum = [[0.085, 0.60, 0.41, 0.32], [0.575, 0.60, 0.41, 0.32], [0.085, 0.19, 0.57, 0.25]]
    pay_renk = {"M": TON["M"][2], "D [0, 0.2)": TON["D"][0], "D [0.2, 0.4)": TON["D"][1], "D [0.4, 0.6)": TON["D"][2], "D [0.6, 0.8)": TON["D"][3], "D [0.8, 1]": TON["D"][4], "F": TON["F"][2]}
    for (k, baslik), kn, harf in zip(sec, konum, "abc"):
        ax = fig.add_axes(kn)
        x = pp[(pp["kontrol"] == k)].set_index("grup")
        x = x.loc[sira[k]] if k in sira else x
        i = np.array([0, 1, 2, 3.6, 4.6, 5.6, 7.2, 8.2, 9.2]) if k == "G_yil" else np.arange(len(x))
        renkler = [TON[g.split(" ")[0]][2] for g in x.index] if k == "G_yil" else ([pay_renk[g] for g in x.index] if k == "pay" else [GRI[2]] * len(x))
        ax.vlines(i, x["rep_alt"], x["rep_ust"], colors=renkler, lw=4.2, zorder=1)
        ax.plot(i, x["gozlenen"], "o", ms=4.2, color=MUREKKEP, zorder=2)
        ax.set_xticks(i)
        if k == "G_yil":
            ax.set_xticklabels([g.split(" ")[1] for g in x.index])
            for xm, g in zip((1, 4.6, 8.2), ("M", "D", "F")):
                ax.text(xm, -0.19, ETIKET["G"][g], transform=ax.get_xaxis_transform(), ha="center", va="top", fontsize=BOY["tik"], color=KOYU_G[g], fontweight=600)
        else:
            ax.set_xticklabels([ppc_etiket(k, g) for g in x.index], rotation=90 if k == "ibbs2" else 0, linespacing=1.1, fontsize=BOY["kucuk"])
        ax.set_ylabel("Weighted prevalence (%)")
        panel_etiketi(ax, harf, baslik=baslik)
    zdos = VERI / "figS_ppc_zincir.csv"
    z = pd.read_csv(zdos) if zdos.exists() else pp[pp["kontrol"] == "zincir_ici_ayni_sonuc"]
    z_sira = [m for m in ("M2", "B14_sigma2", "B14b_sigma5", "B12_zincirsiz") if m in set(z["model"])]
    z = z.set_index("model").loc[z_sira].reset_index()
    z_et = {"M2": "Main\nHN(0, 1)", "B14_sigma2": "HN(0, 2)", "B14b_sigma5": "HN(0, 5)", "B12_zincirsiz": "No chain\nterm"}
    ax = fig.add_axes([0.74, 0.19, 0.245, 0.25])
    for j, r in z.iterrows():
        ax.plot([j, j], [r["rep_alt"], r["rep_ust"]], color=GRI[2], lw=4.2)
    g0 = z["gozlenen"].iloc[0]
    ax.axhline(g0, color=MUREKKEP, lw=1.2)
    ax.text(len(z) - 0.5, g0 + 0.4, "observed", ha="right", va="bottom", fontsize=BOY["tik"], color=MUREKKEP)
    ax.set_ylim(min(z["rep_alt"].min(), g0) - 1.5, max(z["rep_ust"].max(), g0) + 2.5)
    ax.set_xticks(range(len(z)))
    ax.set_xticklabels([z_et.get(m, m) for m in z["model"]], fontsize=BOY["kucuk"], linespacing=1.1)
    ax.set_xlim(-0.6, len(z) - 0.4)
    ax.set_ylabel("Same outcome in both records (%)")
    panel_etiketi(ax, "d", baslik="Two-record chains")
    leg = [Line2D([0], [0], color=MUREKKEP, marker="o", lw=0, ms=4.5), Line2D([0], [0], color=GRI[2], lw=4.2)]
    fig.legend(leg, ["Observed", "95% posterior predictive interval (category tone)"], loc="lower center", ncol=2, bbox_to_anchor=(0.5, 0.0))
    return kaydet(fig, "FigureS3", ek=True)


def figurS_orman():
    du = oku("figS_duyarlilik_orman")
    kodlar = list(dict.fromkeys(du["kod"]))
    fig, axs = plt.subplots(1, 5, figsize=(TAM, (40 + 4.8 * len(kodlar)) * MM), sharey=True, layout="constrained")
    yy = np.arange(len(kodlar))[::-1]
    sonra = set(du.loc[du["sonradan"].astype(str).str.upper() == "TRUE", "kod"]) if "sonradan" in du else set()
    for ax, k, harf in zip(axs, E_SIRA + ["E4"], "abcde"):
        sec = du[du["buyukluk"] == k].set_index("kod").loc[kodlar]
        deg = np.r_[sec["alt"], sec["ust"], -2.5, 2.5]
        pay = 0.06 * (deg.max() - deg.min())
        ax.set_xlim(deg.min() - pay, deg.max() + pay)
        ax.axvspan(-2, 2, color=ROPE, lw=0, zorder=0)
        ax.axvline(0, color=MUREKKEP, lw=0.6, zorder=1)
        referans_cizgisi(ax, sec.loc["M2", "tahmin"])
        for y0, kod in zip(yy, kodlar):
            nokta_aralik(ax, y0, sec.loc[kod], MUREKKEP, acik=k in ISARETLI, boy=ISARET_BOY - 1)
        orman_ekseni(ax)
        ax.xaxis.set_major_locator(plt.MaxNLocator(4))
        panel_etiketi(ax, harf, baslik=E_et(k))
    axs[0].set_yticks(yy)
    axs[0].set_yticklabels([ETIKET["duyarlilik"].get(k, k) + ("$^{\\mathrm{p}}$" if k in sonra else "") for k in kodlar])
    axs[0].get_yticklabels()[0].set_fontweight(600)
    axs[2].set_xlabel("Difference (percentage points)")
    leg = [aralik_lejant(), aralik_lejant(acik=True), Line2D([0], [0], color=REFERANS, lw=CIZGI["referans"], ls=(0, (3, 2)))]
    fig.legend(leg, ["Median, 80% and 95% CrI", "Relies on the share of 0.9 (†)", "Main-model estimate"], loc="outside lower center", ncol=3,
               handler_map={tuple: HandlerTuple(ndivide=None, pad=0)}, handlelength=2.4, columnspacing=1.6)
    return kaydet(fig, "FigureS5", ek=True)


def figurS_yil():
    yE = oku("figS_yil")
    tek = oku("figS_duyarlilik_orman")
    tek_kod = {2023: "A2_2023", 2024: "A2_2024", 2025: "A1_2025"}
    fig, axs = plt.subplots(1, 3, figsize=(TAM, 72 * MM), sharey=True, layout="constrained")
    for ax, k, harf in zip(axs, ["E3a", "E3b", "E4"], "abc"):
        x = yE[yE["buyukluk"] == k]
        ax.axhspan(-2, 2, color=ROPE, lw=0)
        referans_cizgisi(ax, 0, yon="h")
        for j, (_, r) in enumerate(x.iterrows()):
            nokta_aralik(ax, j - 0.13, r, MUREKKEP, acik=k in ISARETLI, yatay=False)
            t = tek[(tek["kod"] == tek_kod[int(r["yil"])]) & (tek["buyukluk"] == k)]
            if len(t):
                nokta_aralik(ax, j + 0.13, t.iloc[0], GRI[3], isaret="s", acik=k in ISARETLI, yatay=False)
        ax.set_xticks(range(len(x)))
        ax.set_xticklabels([str(int(v)) for v in x["yil"]])
        ax.set_xlim(-0.6, len(x) - 0.4)
        panel_etiketi(ax, harf, baslik=E_et(k))
    axs[0].set_ylabel("Difference (percentage points)")
    axs[1].text(0.04, 0.13, "Year-deviation model (circles)", transform=axs[1].transAxes, ha="left", va="bottom", fontsize=BOY["etiket"], color=MUREKKEP, fontweight=600)
    axs[1].text(0.04, 0.05, "Single-year models (squares)", transform=axs[1].transAxes, ha="left", va="bottom", fontsize=BOY["etiket"], color=GRI[4], fontweight=600)
    return kaydet(fig, "FigureS4", ek=True)


def figurS_zaman():
    kt = oku("figS6a_kadin_tze").set_index("grup")
    eg = oku("figS6b_tze_egrileri")
    xa = oku("figS6c_yetiskin")
    fig, axs = plt.subplots(1, 3, figsize=(TAM, 92 * MM), layout="constrained", gridspec_kw={"width_ratios": [1.2, 1, 1.1]})
    gr = ["M", "D1", "D2", "D3", "Dc", "F"]
    et = {"M": "Husband-only", "D1": "Dual, < 0.40", "D2": "Dual, 0.40–0.60", "D3": "Dual, > 0.60", "Dc": "Dual, 0.05–0.15", "F": "Wife-only"}
    rk = {"M": ("M", 1, 4), "D1": ("D", 1, 4), "D2": ("D", 2, 4), "D3": ("D", 3, 4), "Dc": ("D", 0, 4), "F": ("F", 1, 4)}
    ax = axs[0]
    yy = np.arange(len(gr))[::-1]
    for y0, g in zip(yy, gr):
        r = kt.loc[g]
        aile, acik, koyu = rk[g]
        ax.plot([r["p10"], r["p90"]], [y0, y0], color=TON[aile][koyu], lw=CIZGI["a95"], zorder=2)
        ax.add_patch(Rectangle((r["p25"], y0 - 0.28), max(r["p75"] - r["p25"], 0.05), 0.56, facecolor=TON[aile][acik], edgecolor=TON[aile][koyu], lw=CIZGI["kenar"], zorder=3))
        ax.plot([r["p50"], r["p50"]], [y0 - 0.28, y0 + 0.28], color=TON[aile][koyu], lw=CIZGI["medyan"], zorder=4)
    ax.set_yticks(yy)
    ax.set_yticklabels([et[g] for g in gr])
    ax.set_xlim(-0.5, 12.5)
    ax.set_xticks([0, 3, 6, 9, 12])
    ax.set_xlabel("Wife's full-time-equivalent months")
    orman_ekseni(ax)
    panel_etiketi(ax, "a", baslik="Wife's work")
    bx = axs[1]
    son = {es: eg[eg["es"] == es].sort_values("tze")["tahmin"].iloc[-1] for es in ("kadin", "koca")}
    ara = max(1.3 - abs(son["kadin"] - son["koca"]), 0) / 2
    kay = {"kadin": ara if son["kadin"] >= son["koca"] else -ara, "koca": -ara if son["kadin"] >= son["koca"] else ara}
    for es, renk, ad, aile in (("kadin", RENK_G["D"], "Wife", "D"), ("koca", GRI[4], "Husband", None)):
        x = eg[eg["es"] == es].sort_values("tze")
        bant_ic_ice(bx, x["tze"].to_numpy(), x, renk)
        bx.text(12.3, x["tahmin"].iloc[-1] + kay[es], ad, ha="left", va="center", fontsize=BOY["etiket"], color=KOYU_G["D"] if aile else GRI[4], fontweight=600)
    bx.set_xlim(0, 15.6)
    bx.set_xticks([0, 3, 6, 9, 12])
    bx.spines["bottom"].set_bounds(0, 12)
    bx.set_xlabel("Full-time-equivalent months")
    bx.set_ylabel("Standardized probability (%)")
    panel_etiketi(bx, "b", baslik="Dual-earner (X1)")
    cx = axs[2]
    satir = [("E3b", 1), ("E3b", 0), ("E4", 1), ("E4", 0)]
    yc = np.array([3.4, 2.6, 1.0, 0.2])
    for y0, (k, a) in zip(yc, satir):
        r = xa[(xa["buyukluk"] == k) & (xa["deger"] == a)].iloc[0]
        nokta_aralik(cx, y0, r, MUREKKEP if a == 1 else GRI[3])
    cx.axvspan(-2, 2, color=ROPE, lw=0, zorder=0)
    referans_cizgisi(cx, 0)
    cx.set_yticks(yc)
    cx.set_yticklabels([f"{ETIKET['E_mathtext'][k]}, A = {a}" for k, a in satir])
    cx.set_ylim(-0.4, 4.0)
    orman_ekseni(cx)
    cx.set_xlabel("Difference (percentage points)")
    panel_etiketi(cx, "c", baslik="Other adult (X2)")
    tut = [bant_lejant(), aralik_lejant()]
    fig.legend(tut, ["50/80/95% credible bands", "Median, 80% and 95% CrI"], loc="outside lower center", ncol=2, handler_map={tuple: HandlerTuple(ndivide=None, pad=0)},
               handlelength=2.6, columnspacing=1.6)
    return kaydet(fig, "FigureS6", ek=True)


FIGURLER = {"1": figur1, "2": figur2, "3": figur3, "S1": figurS_ortusme, "S2": figurS_oncel_sigma, "S3": figurS_ppc, "S4": figurS_yil, "S5": figurS_orman, "S6": figurS_zaman}

if __name__ == "__main__":
    secim = sys.argv[1:] or list(FIGURLER)
    for k in secim:
        if k == "S6" and not (VERI / "figS6b_tze_egrileri.csv").exists():
            print("S6 verisi yok, atlandı")
            continue
        for p in FIGURLER[k]():
            print(p.relative_to(p.parents[1]) if p.suffix == ".png" else "", end="")
        print(" ", k)
