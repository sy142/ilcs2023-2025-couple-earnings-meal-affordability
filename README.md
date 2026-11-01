# Division of couples' labor earnings and meal-affordability deprivation in Türkiye (ILCS 2023–2025)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23860674.svg)](https://doi.org/10.5281/zenodo.23860674)

This repository contains the analysis code and aggregated outputs of a study of how the division of labor earnings between spouses is related to meal-affordability deprivation of their households. It uses the cross-sectional microdata of the 2023–2025 Income and Living Conditions Survey (ILCS), the Turkish implementation of EU-SILC. The unit of analysis is the reference couple of each household. Couples are classified by earner structure (husband-only, dual-earner and wife-only earner couples) and, among dual-earner couples, by the wife's share of the couple's net labor earnings. The analytic sample is restricted to a rectangular common support of the estimated earner-structure probabilities. Food deprivation is modeled with a weighted (pseudo-posterior) Bayesian multilevel logistic model (brms with CmdStan) with intercepts for NUTS-2 regions and for linkage chains of households observed in more than one survey year. Probabilities are standardized to the covariates of the common-support sample, marginalizing over the chain intercepts by Gauss–Hermite quadrature, and summarized as prespecified comparisons against a region of practical equivalence of ±2 percentage points. Secondary analyses (husband's status, survey years), sensitivity analyses and post hoc analyses of a time channel within the household (work intensity of the spouses, other adults in the household) are included. The outcome is the inability to afford a meal with meat, chicken or fish, or a vegetarian equivalent, every second day (a single material deprivation item). A manuscript based on this repository is under review.

## Data

The ILCS microdata were obtained from the Turkish Statistical Institute (TurkStat) under its microdata user agreement. Under the confidentiality provisions of Statistical Law No. 5429 they cannot be redistributed. This repository contains no microdata and no household-level intermediate files: the data files, model objects, posterior draws and caches that the code writes to `R_Data ve Python Data/` are not included. Researchers can obtain the microdata by applying through TurkStat's official microdata procedures.

The code expects one person-level file that merges the 2023, 2024 and 2025 cross-sectional ILCS household and individual files (239,985 person records; 266 variables, 81 of them derived): `R_Data ve Python Data/GYKA_2023_2025_birlesik.xlsx` (a copy at the repository root is used first). The workbook has four sheets: `veri` (the data), `sozluk` (the data dictionary, whose `okuma_turu` column gives the column types used when reading), `kodlar` (value codes) and `dogrulama` (official TurkStat indicators reproduced from the data, used for validation). It is read once and stored as `R_Data ve Python Data/gyka_2023_2025.parquet`; later runs read the parquet file. The validation checks are in `Results/dogrulama_kontrolleri.csv`.

## Repository structure

- `Codes/`
  - `analiz.R`: single entry point. Reads and validates the data, identifies the reference couple, builds the linkage chains, estimates the common support, fits and checks the Bayesian models, standardizes the probabilities and writes all tables, machine-readable results and figure data.
  - `figurler.py`, `figur_stili.py`: all figures, drawn from the figure data; `etiketler.json`: labels shared by the R tables and the figures.
  - `xlsx_simge.py`: real subscripts and superscripts in `Results/tablolar_tumu.xlsx`; `python_ortam.py`: records the Python environment.
  - `sayilar_karsilastir.py`: compares two `sayilar.json` files field by field.
  - `README_kodlar.md`: run guide in Turkish (order, durations, caches, seeds).
- `Results/`
  - `Table1`, `Table2` (`.docx`, `.csv`) and `tablolar_tumu.xlsx` (all tables in one workbook).
  - `sayilar.json`: every number reported in the manuscript, in machine-readable form.
  - Estimates: `E_tahminleri_ana.csv`, `E_capa_duyarliligi.csv`, `duyarlilik_E.csv`, `ikincil_*.csv`, `zaman_kanali_X1.csv`, `zaman_kanali_X2.csv`, `katsayilar_M1_M3.csv`.
  - Protocol and definitions: `model_protokolu.csv` (model-fitting protocol, checks and decisions), `model_ozetleri.txt`, `dogrulama_kontrolleri.csv`, `degisken_tanimlari.csv`, `akis_sayilari.csv`, `spline_dugumleri.json`, `strobe_akis.md`.
  - Environment: `sessionInfo.txt`, `python_ortam.txt`, `paket_atiflari.txt`.
  - `Supplementary/`: Supplementary Tables S1–S21 (`.docx`, `.csv`).
  - `denetim/`: aggregated audit files (linkage, feasibility, common support, diagnostics, posterior predictive checks, the Stan code of the main model).
  - `log/`: run logs and durations.
- `Figures/`: Figures 1–3 and `Supplementary/` Figures S1–S6 (PNG at 600 dpi, PDF with embedded fonts, LZW-compressed TIFF); `figur_altyazilari.md` (caption drafts); `kontrol/` (150-dpi previews with simulated deuteranopia, protanopia and grayscale); `figur_verileri/` (the aggregated data from which every figure is drawn).
- `docs/`: `analysis_plan_TR.md` (analysis plan, 28 October 2026), `analysis_plan_addendum_TR.md` (addendum for the post hoc time-channel analyses, 1 November 2026), `CHANGELOG.md`. The plan and the addendum are in Turkish.

Tables and figures of the manuscript:

| Item | Content | Files |
|---|---|---|
| Table 1 | Characteristics of couple households by earner structure | `Results/Table1.*` |
| Table 2 | Prespecified comparisons before (M1) and after (M2) adding income terms | `Results/Table2.*` |
| Table S1 | Definitions of the derived variables | `Results/Supplementary/TableS1.*` |
| Table S2 | Sample flow by survey year | `Results/Supplementary/TableS2.*` |
| Table S3 | Household-years, events and effective sample sizes by year and earner structure | `Results/Supplementary/TableS3.*` |
| Table S4 | Links between survey years and agreement of linked records | `Results/Supplementary/TableS4.*` |
| Table S5 | Linkage-chain lengths and outcome patterns | `Results/Supplementary/TableS5.*` |
| Table S6 | Couples whose spouse has no individual record | `Results/Supplementary/TableS6.*` |
| Table S7 | Common-support bounds and household-years outside the common support | `Results/Supplementary/TableS7.*` |
| Table S8 | Convergence diagnostics of the Bayesian models | `Results/Supplementary/TableS8.*` |
| Table S9 | Posterior predictive checks of the main model | `Results/Supplementary/TableS9.*` |
| Table S10 | Sensitivity to the estimation approach | `Results/Supplementary/TableS10.*` |
| Table S11 | Sensitivity to the sample, period and definitions | `Results/Supplementary/TableS11.*` |
| Table S12 | Software, versions and roles | `Results/Supplementary/TableS12.*` |
| Table S13 | Characteristics of all eligible couple households | `Results/Supplementary/TableS13.*` |
| Table S14 | Characteristics of eligible couples outside the common support | `Results/Supplementary/TableS14.*` |
| Table S15 | Comparisons in M1–M3 with regions of practical equivalence of ±1 and ±3 points | `Results/Supplementary/TableS15.*` |
| Table S16 | Coefficients of M1–M3 | `Results/Supplementary/TableS16.*` |
| Table S17 | Wife-only earner couples by the husband's status | `Results/Supplementary/TableS17.*` |
| Table S18 | Single-earner comparisons by survey year | `Results/Supplementary/TableS18.*` |
| Table S19 | Work intensity of the spouses (post hoc) | `Results/Supplementary/TableS19.*` |
| Table S20 | Work-intensity model (X1; post hoc) | `Results/Supplementary/TableS20.*` |
| Table S21 | Other adults in the household (X2; post hoc) | `Results/Supplementary/TableS21.*` |
| Figure 1 | Study design and analytic sample | `Figures/Figure1.*` |
| Figure 2 | Standardized probabilities by earner structure and the wife's share | `Figures/Figure2.*` |
| Figure 3 | Wife-only earner couples by the husband's status; sensitivity of the comparisons | `Figures/Figure3.*` |
| Figure S1 | Overlap of the estimated category probabilities (common support) | `Figures/Supplementary/FigureS1.*` |
| Figure S2 | Prior predictive checks and the linkage-chain variance | `Figures/Supplementary/FigureS2.*` |
| Figure S3 | Posterior predictive checks | `Figures/Supplementary/FigureS3.*` |
| Figure S4 | Single-earner comparisons by survey year | `Figures/Supplementary/FigureS4.*` |
| Figure S5 | Sensitivity of the prespecified comparisons | `Figures/Supplementary/FigureS5.*` |
| Figure S6 | Work intensity and other adults in the household (post hoc) | `Figures/Supplementary/FigureS6.*` |

Following TurkStat's guidance on the reliability of estimates, no estimate is reported for cells with fewer than 20 unweighted household-years, and cells with 20–50 are flagged; complementary suppression prevents suppressed cells from being derived from other cells or tables. Analyses added after the main results were seen are marked ^p in the tables.

## How to run

All commands are run from the repository root. The data analysis needs the microdata (see Data); the figures can be redrawn from the files in this repository.

```
Rscript Codes/analiz.R
python3 Codes/figurler.py
```

- `analiz.R` writes the parquet file and caches to `R_Data ve Python Data/` and all outputs to `Results/` and `R_Data ve Python Data/figur_verileri/`. It calls Python for `xlsx_simge.py` (`~/veri-ortami/bin/python3` if present, otherwise `python3`).
- `figurler.py` reads the figure data from `R_Data ve Python Data/figur_verileri/` if that folder exists, otherwise from `Figures/figur_verileri/`. A single figure: `python3 Codes/figurler.py 2` or `python3 Codes/figurler.py S3`.
- `EK1_YALNIZ=1 Rscript Codes/analiz.R` runs the whole analysis but writes only Tables S19–S21 (numbers, protocol and figure data are updated in both modes). It was used while the post hoc analyses were added, so that the other tables were left unchanged.
- Caches (`R_Data ve Python Data/onbellek/`): fitted models are stored under names that carry a summary of the sampling settings and are refitted only when the Stan code or data change (`file_refit = "on_change"`); standardized probabilities, posterior predictive checks, the prior predictive simulation and the survey bootstrap are stored under content hashes of the data, scenarios and code. Deleting the folder gives a clean run.
- Durations on an 18-core Apple silicon Mac with 64 GB of memory: a clean run from the raw file with empty caches took 4 h 24 min (35 Bayesian models; 4 chains × 4 threads per model); a run from valid caches takes about 15–35 min; the figures, including the previews, take about 10 s. The four post hoc models, fitted later, took 61–108 min each while the processor was shared with other work.

## Environment

- R 4.6.1 (Apple Accelerate BLAS); brms 2.23.0, cmdstanr 0.9.0, CmdStan 2.40.0, rstan 2.32.7, posterior 1.7.0, survey 4.5, nnet 7.3-20, statmod 1.5.2; data.table, arrow, flextable, officer and openxlsx for data handling and tables.
- Python 3.13 with matplotlib, numpy, pandas, pillow, openpyxl and colorspacious (simulated color-vision deficiency in the previews).
- Font: Source Sans 3 (SIL Open Font License), installed as TrueType so that it is embedded in the PDFs; the figure code falls back to IBM Plex Sans or Gill Sans.
- Exact versions: `Results/sessionInfo.txt`, `Results/python_ortam.txt`; packages, their roles and citations: `Results/paket_atiflari.txt` and Table S12.

## Reproducibility

- Seeds are fixed (R 20261028; prior predictive simulation 20261029; Bayesian models 20261030; pilot 20261031; posterior predictive checks 20261032; survey bootstrap 20261033), and within-chain parallelization uses a static partition (`threading(4, static = TRUE)`), so the draws do not depend on thread scheduling.
- A clean run from the raw file with empty caches (29–30 October 2026) reproduced all 35 models and every field of `Results/sayilar.json` exactly on the same software and hardware.
- The four post hoc models (work-intensity model, its fixed-knot version and the two other-adult models) were fitted once with the same settings and have not been re-run.
- The tables in this release were rewritten from the caches on 1 November 2026 without refitting any model; `Results/denetim/tablo_yeniden_yazim_farklari.csv` lists every difference from the previous files.

## Citation

Citation details will be added when the manuscript is published.

Authors:
- Salim Yılmaz, Acıbadem Mehmet Ali Aydınlar University (ORCID [0000-0003-2405-5084](https://orcid.org/0000-0003-2405-5084))
- Ahmet Murat Günal, Haliç University (ORCID [0000-0001-9109-1080](https://orcid.org/0000-0001-9109-1080))

## License

The code is released under the MIT License (`LICENSE`). The aggregated outputs (tables, figures and results files) may be reused with attribution.
