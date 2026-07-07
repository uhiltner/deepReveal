# Validation — Batch 1: Distribution Metrics + SSD Classifier
Validator: independent (not plan author)
Source read: `01_data_processing_funs_CONSOLIDATED.R` lines 55–241
deepReveal read: `R/sensitivity_functions.R` (full; grepped for jsd/classify_ssd/smooth_ssd/find_ssd)

| Item | Verdict | Evidence (file:line) | Reasoning | Recommended action |
|---|---|---|---|---|
| **E1** `jsd_divergence()` ← `jsd_nats()` | **VALID** | `01_CONSOLIDATED.R:67–74`; `sensitivity_functions.R:1819–1867` | `jsd_nats` exists at line 67. Body is 7 lines of pure base-R math; zero function calls. deepReveal's `kl_divergence_metric()` (L1819) is KL-only, row-wise on matrices via `philentropy::distance()`. No JSD function exists in deepReveal (grep: zero hits). Plan's contrast is accurate. **Naming note:** dropping "nats" loses the unit qualifier — `log()` means results are in nats, upper bound ln(2) ≈ 0.693, not bits (upper bound 1.0). | Consider retaining unit in name (`jsd_nats()`) or documenting in `@return`: "scalar in nats, bounded [0, ln(2)]". Not a blocker. |
| **E2** `classify_ssd()` ← `classify_ssd_structure()` | **VALID** | `01_CONSOLIDATED.R:187–241`; helpers at L106–133 | `classify_ssd_structure` exists at L187. Calls only `smooth_ssd_relative()` (same file, L106) and `find_ssd_peaks()` (same file, L126). All other logic is base R. No ForClim column names or global objects. deepReveal: zero hits for "classify_ssd"/"smooth_ssd"/"find_ssd". **Portability note:** `sparse_limit=50`, `class1_dom_limit=0.90`, `threshold_secondary=0.15`, and Spearman ρ < −0.80 were calibrated for a 10-class DBH scheme. Code is dynamic (uses `length`, `seq_along`) but defaults are not portable to arbitrary bin counts without recalibration. | Add a note in `@details` that default thresholds are calibrated for 10-class SSDs. Not a porting blocker. |
| **H1** `smooth_ssd_()` ← `smooth_ssd_relative()` | **VALID** | `01_CONSOLIDATED.R:106–113` | Function exists. Body is a 7-line loop: only `numeric()`, `length()`, and arithmetic. Zero function calls, zero package dependencies. | None. |
| **H2** `find_ssd_peaks_()` ← `find_ssd_peaks()` | **VALID** | `01_CONSOLIDATED.R:126–133` | Function exists. Body is a 7-line loop: only `logical()`, `length()`, `which()`. Zero function calls, zero package dependencies. | None. |

**Batch 1 summary: 4/4 VALID.** No blockers. Two non-blocking documentation notes (unit qualifier for E1; 10-class calibration caveat for E2).
