# Validation — Batch 3: Analysis Functions + Refactoring Needs
Validator: independent (not plan author)
Source read: `03d_branch1_efi_validation.R`; `03c_branch1_synthetic_validation.R`
deepReveal read: `R/sensitivity_functions.R` (checked `analyze_and_visualize_predictions`, `feature_value_sensitivity`)

| Item | Verdict | Evidence (file:line) | Reasoning | Recommended action |
|---|---|---|---|---|
| **E6.1** `compute_plot_metrics()` (first source for merge) | **VALID** | `03d:451–463` | Exists at L451, signature `(true_abs, pred_rel)`. Returns a **named list** `list(kl, jsd, rmse, r2)` — not a tibble. The plan's "one-row tibble" is a proposed interface change for the ported version, not a description of the source; this is intentional and confirmed by the author. | Port + convert return type to tibble as planned. |
| **E6.2** `compute_noise_metrics()` (second source for merge) | **VALID** | `03c:1175–1188` | Exists at L1175, signature `(preds_matrix, stands, n_stands)`. Reads `stands[[j]]$ssd_stems_ha` (L1178) and `stands[[j]]$N_stems_ha` (L1179) from the list — scope-leak confirmed. | R1 refactor is real and necessary. |
| **E6 — overlap check vs `analyze_and_visualize_predictions()`** | **FALSE-POSITIVE** | `sensitivity_functions.R:1388–1405` | `analyze_and_visualize_predictions()` takes a pre-merged data frame + `target_features`, `selected_stands`, etc. and produces scatter plots, histogram grids, CSVs. Completely different interface and purpose. No overlap with `(true_abs, pred_rel)` or `(preds_matrix, stands)` signatures. | No action needed; proceed with porting. |
| **E6 — merge & return type** | **NEEDS-DECISION** | `03d:463` (named list); `03c:1180–1188` (data.frame via rbind) | The two sources return different types. `compute_plot_metrics()` returns a named list; `compute_noise_metrics()` returns a data.frame. The plan's "one-row tibble (confirmed by author)" is the stated decision — explicitly confirm this before implementation begins. | **Author to confirm:** merged `compute_prediction_metrics()` always returns a one-row tibble with columns `kl`, `jsd`, `rmse`, `r2`? |
| **E7** `perturb_features()` ← `apply_feature_noise()` | **VALID** | `03c:1156–1172` | Exists at L1156. Signature `(features_raw, perturb_feats, multipliers, scalers, feature_order)` matches plan exactly. Applies multiplicative noise, re-scales via training scalers. | Port as-is. R2 is a false-positive (see below). |
| **E7 — overlap check vs `feature_value_sensitivity()`** | **FALSE-POSITIVE** | `sensitivity_functions.R:486–718` | `feature_value_sensitivity()` creates one baseline instance, varies one feature at a time over a range or fixed percentage. `apply_feature_noise()` applies multiplicative noise draws across the full dataset and re-scales. Different purpose (exploration vs. error-propagation) and different interface. | No action needed; proceed. |
| **R1** Scope-leak in `compute_noise_metrics()` | **VALID** | `03c:1175, 1178–1179` | Confirmed: reads `stands[[j]]$ssd_stems_ha` and `stands[[j]]$N_stems_ha` from a project-specific `stands` list. For a generic deepReveal function, these must be replaced with explicit `true_ssd_matrix` (n_stands × 10 matrix) and `N_vec` (length-n_stands numeric). | Implement as planned. |
| **R2** Scope-leak of `FFS_TO_SCALE` in `apply_feature_noise()` | **FALSE-POSITIVE** | `03c:1156–1172` (full body); grep for `FFS_TO_SCALE` in 03c → zero hits | `FFS_TO_SCALE` does not appear anywhere in `03c_branch1_synthetic_validation.R` — neither in the function body nor elsewhere in the file. The scaling gate is already `if (feat_name %in% names(scalers$min))` at L1166, using the `scalers` parameter. The function is already clean. | **Skip this refactor.** No scope-leak exists; no change needed. |
| **R3** SSD generators read `DBH_BREAKS`/`DBH_MIDPOINTS` from global scope | **WRONG-FIX** | `01b:39–40`, `01b:276–278` | **Two errors in the plan's claim:** (1) Constants are named `SG_DBH_BREAKS`/`SG_DBH_MIDPOINTS` (not `DBH_BREAKS`/`DBH_MIDPOINTS`). (2) They appear as **default parameter values** in the function signatures (`dbh_rep = SG_DBH_MIDPOINTS`, `breaks_cm = SG_DBH_BREAKS`), not as hidden reads inside the function body — the functions are already parameterized. "Promote to required arguments" would break the convenience API without solving the underlying problem. The actual issue is that `SG_DBH_BREAKS`/`SG_DBH_MIDPOINTS` are defined in the `01b` script (L39–40) and won't exist in deepReveal's namespace. | **Correct fix:** export `SG_DBH_BREAKS`, `SG_DBH_MIDPOINTS`, `SG_DBH_THETA` as documented package-level constants in deepReveal (e.g., `R/ssd_constants.R`). Leave parameter defaults pointing to them. Do NOT remove the defaults. |

---

**Batch 3 summary:**
- 4 VALID (E6.1, E6.2, E7, R1)
- 3 FALSE-POSITIVE (E6-overlap-check, E7-overlap-check, R2)
- 1 WRONG-FIX (R3)
- 1 NEEDS-DECISION (E6 merge/return-type — author already indicated "one-row tibble"; needs explicit pre-implementation confirmation)

**Only R3's proposed fix is wrong.** The real fix is to create deepReveal package constants, not to make DBH arguments required.
