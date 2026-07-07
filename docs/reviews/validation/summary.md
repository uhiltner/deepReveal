# Validation Summary — deepReveal v0.2.0 Porting Plan
Date: 2026-07-07
Validators: 3 independent agents (not plan author)
Artifacts: batch-1-distribution-classification.md, batch-2-generators-utilities.md, batch-3-analysis-refactoring.md

## Consolidated Verdicts

| ID | Item | Verdict |
|---|---|---|
| E1 | `jsd_divergence()` ← `jsd_nats()` | ✅ VALID |
| E2 | `classify_ssd()` ← `classify_ssd_structure()` | ✅ VALID |
| E3 | `generate_ssd_weibull()` | ✅ VALID |
| E4 | `generate_ssd_reverse_j()` | ✅ VALID (plan has 1 wrong dependency listed) |
| E5 | `generate_ssd_bimodal()` ← `generate_ssd_bimodal_gauss()` | ⚠️ WRONG-FIX — source fix required before porting |
| E6 | `compute_prediction_metrics()` (merged) | ✅ VALID + 🔷 NEEDS-DECISION on return type |
| E7 | `perturb_features()` ← `apply_feature_noise()` | ✅ VALID |
| H1 | `smooth_ssd_()` | ✅ VALID |
| H2 | `find_ssd_peaks_()` | ✅ VALID |
| H3 | `cao_baldwin_solver_()` | ✅ VALID |
| H4 | `siipilehto_scale_()` | ✅ VALID |
| H5 | `weibull_class_probs_()` | ✅ VALID (plan mis-described `dbh_midpoints` — not a parameter) |
| H6 | `deliocourt_seeds_()` | ✅ VALID |
| U1 | `stand_qmd()` | ✅ VALID |
| U2 | `stand_basal_area()` | ✅ VALID |
| R1 | Scope-leak in `compute_noise_metrics()` | ✅ VALID — real refactor needed |
| R2 | Scope-leak of `FFS_TO_SCALE` in `apply_feature_noise()` | ❌ FALSE-POSITIVE — function is already clean |
| R3 | SSD generators read `DBH_BREAKS`/`DBH_MIDPOINTS` from globals | ⚠️ WRONG-FIX — wrong constant names, wrong pattern, wrong proposed fix |

**Score: 14 VALID · 2 WRONG-FIX · 1 FALSE-POSITIVE · 1 NEEDS-DECISION**

---

## Items That Must Be Addressed Before Implementation

### E5 — `generate_ssd_bimodal_gauss()` has an unresolved body-level global
**Problem:** Line 434 of `01b_data_processing_funs.R` reads `SG_DBH_THETA` directly inside the function body (not as a default value). This will cause `object 'SG_DBH_THETA' not found` in deepReveal if ported as-is. Additionally, the plan listed two phantom dependencies (`generate_ssd_weibull` and `BA_from_ssd`) that are never called — the circular dependency concern was unfounded.

**Correct fix:** Before porting, add `theta_cm = 8L` to `generate_ssd_bimodal_gauss()`'s signature in `01b_data_processing_funs.R` and replace the bare `SG_DBH_THETA` at L434 with `theta_cm`. Real dependencies: `dG_from_N_BA`, `siipilehto_b`, `weibull_class_probs`, `cao_baldwin_2c`.

### R3 — Plan misidentifies the pattern and proposes the wrong fix
**Problem (two errors):** (1) Constants are `SG_DBH_BREAKS`/`SG_DBH_MIDPOINTS`/`SG_DBH_THETA`, not `DBH_BREAKS`/`DBH_MIDPOINTS`. (2) They already appear as default parameter values, not as hidden body reads — the functions are already parameterized. Promoting them to required arguments would remove convenience defaults without solving anything.

**Correct fix:** Create a `R/ssd_constants.R` file in deepReveal exporting `SG_DBH_BREAKS`, `SG_DBH_MIDPOINTS`, and `SG_DBH_THETA` as documented package constants. The generator functions' parameter defaults will then resolve correctly inside the package namespace.

### R2 — False alarm, skip this refactor
`FFS_TO_SCALE` does not appear in `03c_branch1_synthetic_validation.R` at all. The function `apply_feature_noise()` already uses `names(scalers$min)` as its scaling gate. No refactor needed before porting E7.

---

## One Decision Needed Before Implementation

**E6 return type** — The two source functions return different types: `compute_plot_metrics()` returns a named list; `compute_noise_metrics()` returns a data.frame. The plan states "one-row tibble (confirmed by author)" — explicitly confirm this before implementation, as both source call sites will need updating.

---

## Non-Blocking Notes (Documentation Quality)
- **E1 naming:** `jsd_divergence()` silently drops the unit. Function uses natural log → results in nats, bounded [0, ln(2)]. Document in `@return` or rename to `jsd_nats()`.
- **E2 thresholds:** Default thresholds (`sparse_limit`, `class1_dom_limit`, etc.) were calibrated for 10-class DBH SSDs. Document in `@details`.
- **E4 dependency list:** `dG_from_N_BA` is not used in `generate_ssd_reverse_j()`. Remove from checklist.
- **H5 characterization:** `weibull_class_probs()` has no `dbh_midpoints` parameter (midpoints are not used); `theta` is already a parameter. Correct the function description.
