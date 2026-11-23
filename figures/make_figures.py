"""Draw figures/summary.png: second-pass risk premia and daily five-factor R².

All numbers are constants copied from the R output files in results/;
the raw data are not redistributed, so nothing is read from disk.
Run from the repository root: python figures/make_figures.py
"""
from pathlib import Path

import matplotlib.pyplot as plt

# Shared style
BLUE, GRAY, ACCENT = "#1f4e79", "#9aa5b1", "#d98c1f"
INK, MUTED, GRID = "#1a1a1a", "#5f6b78", "#e9ecef"
FS_TITLE, FS_LABEL, FS_SMALL = 12, 9, 8
plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": FS_SMALL,
    "axes.linewidth": 0.6,
    "axes.edgecolor": INK,
    "xtick.direction": "out",
    "ytick.direction": "out",
    "xtick.major.width": 0.6,
    "ytick.major.width": 0.6,
    "xtick.major.size": 3,
    "ytick.major.size": 3,
    "xtick.color": INK,
    "ytick.color": INK,
})

# Second pass, FF5 + ICRF, 25 portfolios, monthly 1970-01 to 2018-11:
# (factor, estimate, std. error) as printed. The Fama-French factors are in percent
# per month; the ICRF series is in decimal units, so its row is multiplied by 100.
ICRF_SCALE = 100
PREMIA = [
    ("ICRF", -0.01999, 0.02110),    # results/02_two_pass_regression_output.txt line 13
    ("Mkt-RF", -0.36278, 0.43377),  # line 14
    ("SMB", 0.18921, 0.07007),      # line 15
    ("HML", 0.27506, 0.06922),      # line 16
    ("RMW", 0.30351, 0.20885),      # line 17
    ("CMA", 0.27680, 0.26707),      # line 18
]
DF_RESID = 18       # results/02_two_pass_regression_output.txt line 22 ("on 18 degrees of freedom")
T_975_DF18 = 2.101  # 0.975 quantile of Student's t with 18 df (for the 95% interval)

# Daily five-factor time-series R² (portfolio, sample, R² as printed)
R2 = [
    ("SMALL LoBM", "Full sample", "0.887"),   # results/01_five_factor_regression_output.txt line 29
    ("SMALL LoBM", "Before 2000", "0.8959"),  # line 53
    ("SMALL LoBM", "2000 onward", "0.8895"),  # line 77
    ("BIG HiBM", "Full sample", "0.8582"),    # line 100
    ("BIG HiBM", "Before 1980", "0.7831"),    # line 124
    ("BIG HiBM", "1981-1999", "0.8461"),      # line 148
]


def clean(ax, grid_axis):
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    getattr(ax, f"{grid_axis}axis").grid(True, color=GRID, lw=0.6, zorder=0)
    ax.set_axisbelow(True)
    ax.tick_params(axis="both", labelsize=FS_SMALL)


def label(fig, x, y, letter, title):
    fig.text(x, y, letter, fontsize=FS_LABEL, fontweight="bold", color=INK,
             ha="left", va="center")
    fig.text(x + 0.022, y, title, fontsize=FS_LABEL, color=INK, ha="left", va="center")


def main():
    fig = plt.figure(figsize=(8, 4.5), dpi=200, facecolor="white")
    fig.text(0.02, 0.945, "Second-pass risk premia for the Fama-French five factors and "
             "the intermediary capital factor",
             fontsize=FS_TITLE, fontweight="bold", color=INK, ha="left", va="center")
    fig.text(0.02, 0.885, "Two-pass regression on 25 size/book-to-market portfolios, "
             "monthly 1970-01 to 2018-11; daily R² from five-factor regressions",
             fontsize=FS_LABEL, color=MUTED, ha="left", va="center")

    # a: second-pass risk premia with 95% intervals
    ax = fig.add_axes([0.085, 0.10, 0.50, 0.64])
    ax.axhline(0, color=GRAY, lw=0.6, zorder=1)
    for i, (name, est, se) in enumerate(PREMIA):
        c = ACCENT if name == "ICRF" else BLUE
        text = f"{est:.3f}"
        if name == "ICRF":
            est, se = est * ICRF_SCALE, se * ICRF_SCALE
            text = f"{est:.2f}"
        ax.errorbar([i], [est], yerr=[T_975_DF18 * se], fmt="o", color=c, ms=5.5,
                    elinewidth=1.2, capsize=3, capthick=1.2, zorder=3)
        ax.annotate(text.replace("-", "\u2212"), (i, est), xytext=(8, 0),
                    textcoords="offset points", ha="left", va="center",
                    fontsize=FS_SMALL, color=INK)
    ax.set_xticks(range(len(PREMIA)), [p[0] for p in PREMIA], fontsize=FS_SMALL)
    ax.set_xlim(-0.5, len(PREMIA) - 0.3)
    ax.set_ylim(-7.2, 3.2)
    ax.set_yticks([-6, -4, -2, 0, 2])
    ax.set_ylabel("Risk premium (% per month)", fontsize=FS_LABEL, color=INK)
    clean(ax, "y")

    # b: daily R² by portfolio and sub-period
    bx = fig.add_axes([0.765, 0.10, 0.21, 0.64])
    ys = [6.4, 5.4, 4.4, 2.6, 1.6, 0.6]
    for y, (port, sample, r2) in zip(ys, R2):
        c = BLUE if sample == "Full sample" else GRAY
        bx.barh([y], [float(r2)], height=0.7, color=c, zorder=2)
        bx.text(float(r2) + 0.02, y, r2, ha="left", va="center", fontsize=FS_SMALL, color=INK)
    bx.set_yticks(ys, [r[1] for r in R2], fontsize=FS_SMALL)
    for y, port in [(7.35, "SMALL LoBM"), (3.55, "BIG HiBM")]:
        bx.text(-0.035, y, port, ha="right", va="center", fontsize=FS_SMALL,
                fontweight="bold", color=INK, transform=bx.get_yaxis_transform())
    bx.set_ylim(0, 7.8)
    bx.set_xlim(0, 1.2)
    bx.set_xticks([0, 0.5, 1.0], ["0", "0.5", "1.0"])
    bx.set_xlabel("R²", fontsize=FS_LABEL, color=INK)
    clean(bx, "x")
    bx.tick_params(axis="y", length=0)

    label(fig, 0.02, 0.795, "a", "Second-pass risk premia, FF5 + ICRF (95% CI)")
    label(fig, 0.625, 0.795, "b", "Daily five-factor R²")

    out = Path(__file__).resolve().parent / "summary.png"
    fig.savefig(out, dpi=200, facecolor="white")


if __name__ == "__main__":
    main()
