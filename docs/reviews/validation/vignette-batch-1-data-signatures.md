# Vignette Plan Validation — Batch 1: Data & Function Signatures

**Reviewer**: independent second reviewer (Claude Code)
**Date**: 2026-07-08
**Scope**: Items V1–V6 from the proposed vignette plan for the `deepReveal` R package
**Files read**:
- `R/sensitivity_functions.R` (2535 lines; functions in lines 2017–2535)
- `data/deepReveal_example_data.rda` (inspected via Rscript --vanilla)

---

## Verdict table

| Item | Verdict | Evidence (file:line or command output) | Reasoning | Action needed |
|------|---------|----------------------------------------|-----------|---------------|
| V1 | **VALID** | R output: `Row 1 target sum: 1`; values `0.000, 0.000, 0.068, 0.248, 0.356, 0.184, 0.096, 0.036, 0.008, 0.004` | The 10 `stems.ha_dbhclass*` columns in `top_model_predictions` are proportions summing exactly to 1 per row. The claim is correct. | None. |
| V2 | **FALSE-POSITIVE** | R output: `stem_number.ha range: 0.593451 0.8950865`; `stem_number.ha_raw range: 0.05273313 0.469184`; `train_data$stem_number.ha_raw range: 0.003612017 0.8522895` | `stem_number.ha` is a min-max normalized value in [0, 1], NOT absolute stems/ha. The plan asserts "expected range: hundreds per hectare" — the real range is 0.59–0.90. Using `preds$stem_number.ha[i]` as the multiplier to recover absolute counts produces values < 1, causing `compute_prediction_metrics` to return all-NA (its guard: `if (N_total < 1) return(na_row)`). No unscaled absolute stem density column exists in `deepReveal_example_data`. | **STOP — do not build as-is.** The vignette must either (a) obtain actual absolute stem density from elsewhere (not available in `deepReveal_example_data`) or (b) reframe the demonstration around proportions only, skipping the absolute-count conversion. The conversion formula `true_abs = preds[i, target_cols] * preds$stem_number.ha[i]` will silently produce meaningless sub-1 values. |
| V3 | **FALSE-POSITIVE** | `sensitivity_functions.R:2017–2021` (signature: `classify_ssd(ssd_abs, stem_number, ...)`); examples at line 2012: `classify_ssd(c(400, 200, ...), stem_number = 788)`; R runtime test: `ERROR: argument "stem_number" is missing, with no default` | Three separate errors in the plan's proposed code `classify_ssd(as.numeric(preds[1, target_cols]))`: (1) the first argument `ssd_abs` must be **absolute stem counts**, not proportions — the Roxygen docs and examples make this explicit; (2) `stem_number` is a **required** argument with no default, so the call errors immediately; (3) the function returns a **named list** (`$category`, `$n_peaks`, `$spearman_rho`, etc.), not a bare string — the plan's claim that it "returns one of the strings" is misleading. | **STOP — do not build as-is.** Correct call requires: `classify_ssd(ssd_abs = absolute_counts_vector, stem_number = total_stems_ha)`. Since absolute values are unavailable from V2's finding, this function cannot be demonstrated on `top_model_predictions` without external data. If only proportions are available, the caller must multiply by a valid total before passing. Access the result string as `result$category`. |
| V4 | **VALID** | `sensitivity_functions.R:2459–2460`: `compute_prediction_metrics <- function(true_abs, pred_rel, N_total = sum(true_abs))`; function body lines 2465–2476 confirm `pred_rel` is a proportions vector (multiplied by `N_total` internally) | The signature matches the plan's claim exactly. `pred_rel` is indeed a proportions-vector input. The call pattern `compute_prediction_metrics(true_abs = observed_proportions * N, pred_rel = predicted_proportions)` is structurally correct **if N is a valid absolute total**. The function itself is correctly described. | The signature is sound. However, because V2 shows `stem_number.ha` is not a valid N, any call that derives N from that column will produce `N_total < 1` → all-NA output. Fix V2 first, then V4's call pattern will work. |
| V5 | **VALID** | R output: `pred_cols exist in preds: TRUE`; column list (positions 130–139) confirms `stems.ha_dbhclass10_pred` through `stems.ha_dbhclass52_pred` all present | All 10 `_pred` columns exist in `top_model_predictions`. Row sums of `_pred` columns: range `0.9999999–1.0000000` — they are also proportions. | None. |
| V6 | **VALID** | `sensitivity_functions.R:2520–2521`: `perturb_features <- function(features_raw, perturb_feats, multipliers, scalers, feature_order)`; R output: `Names in deepReveal_example_data: "train_data" "val_data" "test_data" "input_features" "target_features" "top_seed" "top_model_predictions" "top_model_metrics"` | Signature matches the plan's claim exactly. `deepReveal_example_data` contains 8 named elements; `scalers` is not among them. `eval=FALSE` is therefore correctly justified. | None for the eval=FALSE rationale. Note for documentation: `scalers` must come from the model-training artefact (not bundled in the example data), so the vignette should explain where users would obtain it in a real workflow. |

---

## Summary

### Items requiring immediate action before the vignette can be built

**V2 — FALSE-POSITIVE (HIGH SEVERITY)**
`top_model_predictions$stem_number.ha` is a min-max normalized feature (range 0.59–0.90), not absolute stems/ha. No column in `deepReveal_example_data` carries unscaled absolute stem density. The plan's conversion formula `true_abs = preds[i, target_cols] * preds$stem_number.ha[i]` produces near-zero values; `compute_prediction_metrics` silently returns all-NA when `N_total < 1`. **The vignette code block that computes absolute counts and passes them to `compute_prediction_metrics` will appear to run but will output only NAs.**

**V3 — FALSE-POSITIVE (HIGH SEVERITY)**
`classify_ssd(as.numeric(preds[1, target_cols]))` will throw a hard R error at runtime: `argument "stem_number" is missing, with no default`. Even if `stem_number` were supplied, the function expects absolute stem counts (not proportions), and returns a list, not a bare string. **This code block will crash the vignette.**

### Items that are sound

V1, V4 (signature only), V5, and V6 are all confirmed valid against the actual source code and data.

### Cascade note

V4's call to `compute_prediction_metrics` is syntactically correct but depends on having a valid absolute N (broken by V2). Once V2 is resolved — either by sourcing actual absolute stem density externally or by redesigning the demonstration around proportions — V4's pattern will work without modification.
