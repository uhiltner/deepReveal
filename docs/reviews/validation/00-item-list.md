# Validation Item List — deepReveal v0.2.0 Porting Plan
Generated: 2026-07-07

## New Exports (E1–E7)

| ID | Source function | Source file:line | Proposed deepReveal name | Justification stated? |
|---|---|---|---|---|
| E1 | `jsd_nats()` | 01_CONSOLIDATED:67 | `jsd_divergence()` | Yes — KL metric row-wise on matrices; JSD is symmetric+bounded, different purpose |
| E2 | `classify_ssd_structure()` | 01_CONSOLIDATED:187 | `classify_ssd()` | Yes — new analytical capability; 4-class archetype; no ForClim schema |
| E3 | `generate_ssd_weibull()` | 01b:276 | `generate_ssd_weibull()` | Yes — synthetic stress-test scaffolding; depends on H3–H5 in same file |
| E4 | `generate_ssd_reverse_j()` | 01b:309 | `generate_ssd_reverse_j()` | Yes — de Liocourt SSD type; depends on H6, H3 |
| E5 | `generate_ssd_bimodal_gauss()` | 01b:422 | `generate_ssd_bimodal()` | Yes — bimodal with fallback; depends on H3–H5, E3 (claimed fallback) |
| E6 | `compute_plot_metrics()` (03d:451) merged with `compute_noise_metrics()` (03c:1175) | — | `compute_prediction_metrics()` | Yes — not covered by `analyze_and_visualize_predictions()`; returns one-row tibble |
| E7 | `apply_feature_noise()` | 03c:1156 | `perturb_features()` | Yes — not covered by `feature_value_sensitivity()`; different interface and purpose |

## Utility Exports (U1–U2)

| ID | Source function | Source file:line | Proposed deepReveal name | Justification stated? |
|---|---|---|---|---|
| U1 | `dG_from_N_BA()` | 01b:61 | `stand_qmd()` | Yes — QMD formula; used by E3/E4/E5 |
| U2 | `BA_from_ssd()` | 01b:72 | `stand_basal_area()` | Yes — BA from stems×midpoints; used by E5 (claimed) |

## Internal Helpers (H1–H6)

| ID | Source function | Source file:line | Proposed deepReveal name | Unexported? |
|---|---|---|---|---|
| H1 | `smooth_ssd_relative()` | 01_CONSOLIDATED:106 | `smooth_ssd_()` | Yes |
| H2 | `find_ssd_peaks()` | 01_CONSOLIDATED:126 | `find_ssd_peaks_()` | Yes |
| H3 | `cao_baldwin_2c()` | 01b:177 | `cao_baldwin_solver_()` | Yes |
| H4 | `siipilehto_b()` | 01b:90 | `siipilehto_scale_()` | Yes |
| H5 | `weibull_class_probs()` | 01b:108 | `weibull_class_probs_()` | Yes |
| H6 | `bdq_seed_counts()` | 01b:147 | `deliocourt_seeds_()` | Yes |

## Required Refactors (R1–R3)

| ID | Claimed problem | Claimed fix |
|---|---|---|
| R1 | `compute_noise_metrics()` reads `stands[[j]]$ssd_stems_ha` / `$N_stems_ha` from list parameter | Replace with explicit `true_ssd_matrix` + `N_vec` arguments |
| R2 | `apply_feature_noise()` reads `FFS_TO_SCALE` from enclosing scope | Promote to explicit argument |
| R3 | SSD generators read `DBH_BREAKS`/`DBH_MIDPOINTS` from global scope | Promote to required arguments |
