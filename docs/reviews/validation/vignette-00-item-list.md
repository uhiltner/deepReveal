# Vignette Plan — Item List for Validation

**Plan:** `docs/reviews/v0.2.0-vignette-plan.md`  
**Date:** 2026-07-08  
**Validator batch:** 1 (single batch, all data/signature claims)

---

## Items

| ID | Claim | Files to check | Risk if wrong |
|----|-------|----------------|---------------|
| V1 | `preds[i, target_cols]` (the 10 `stems.ha_dbhclass*` columns without `_pred`) in `top_model_predictions` contain **proportions** (sum ≈ 1), not absolute stems/ha | `data/deepReveal_example_data.rda` | compute_prediction_metrics chunk multiplies by N — double-counts if already absolute |
| V2 | `preds$stem_number.ha` (no `_raw` suffix) gives actual **absolute** stems/ha (hundreds per hectare), not a scaled/normalised value | `data/deepReveal_example_data.rda` | Code chunk produces nonsense absolute counts |
| V3 | `classify_ssd()` accepts a **proportion vector** (sums to ~1) and returns one of four archetype strings | `R/sensitivity_functions.R` | Function fails or mis-classifies if it expects absolute counts |
| V4 | `compute_prediction_metrics()` signature is `(true_abs, pred_rel, N_total = sum(true_abs))` where `pred_rel` is proportions | `R/sensitivity_functions.R` | Wrong calling convention in vignette chunk |
| V5 | `paste0(target_cols, "_pred")` resolves to actual column names present in `top_model_predictions` | `data/deepReveal_example_data.rda` | Column-not-found error in eval=TRUE chunk |
| V6 | `perturb_features()` signature is `(features_raw, perturb_feats, multipliers, scalers, feature_order)` | `R/sensitivity_functions.R` | Wrong usage pattern shown to users |

## No new UI components (R package — not applicable)
