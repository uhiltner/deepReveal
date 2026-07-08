# Vignette Plan Validation — Summary

**Plan:** `docs/reviews/v0.2.0-vignette-plan.md`  
**Date:** 2026-07-08  
**Validator batch:** 1 of 1

---

## Results

| Item | Verdict | One-line finding |
|------|---------|-----------------|
| V1 | VALID | `stems.ha_dbhclass*` columns are proportions summing to 1 ✓ |
| V2 | **FALSE-POSITIVE** | `stem_number.ha` is normalised (range 0.59–0.90), not absolute stems/ha; `compute_prediction_metrics` silently returns all-NA |
| V3 | **FALSE-POSITIVE** | `classify_ssd()` requires `ssd_abs` (absolute counts) + required arg `stem_number`; returns a list, not a string |
| V4 | VALID | Signature `(true_abs, pred_rel, N_total)` confirmed; blocked by V2 until absolute N is resolved |
| V5 | VALID | All 10 `_pred` columns exist in `top_model_predictions` ✓ |
| V6 | VALID | `perturb_features` signature confirmed; no scalers in example data → `eval=FALSE` correct ✓ |

---

## Corrected approach for V2 and V3

Both false positives share the same root cause: **`deepReveal_example_data` contains no unscaled absolute stem density**. All stem/ha columns are min-max normalised. The fixes reroute both subsections to use the generators (which produce absolute counts with known N) instead of test-data proportions.

### V2 fix — `compute_prediction_metrics` (subsection 4.3)

Replace the `eval=TRUE` chunk that reads `preds$stem_number.ha` with a self-contained generator-based example:

```r
# compute_prediction_metrics requires absolute stem counts.
# Generators produce SSDs with exactly known N and BA — ideal for a self-contained example.
N        <- 400   # stems/ha
true_abs <- generate_ssd_weibull(c_shape = 2.5, N_target = N, BA_target = 28)

# Simulate a "predicted" distribution — a slightly different Weibull shape
pred_ssd <- generate_ssd_weibull(c_shape = 3.0, N_target = N, BA_target = 28)
pred_rel <- pred_ssd / sum(pred_ssd)   # normalise to proportions

metrics <- compute_prediction_metrics(
  true_abs = true_abs,
  pred_rel = pred_rel,
  N_total  = N
)
print(metrics)
```

This is `eval=TRUE` (pure R, no keras), pedagogically clear (controlled comparison between two
shapes), and explicitly teaches the required input format. Add a prose note: "In a real
validation workflow, `true_abs` would come from field-measured stem counts per DBH class and
`pred_rel` from the model's softmax output."

### V3 fix — `classify_ssd` (subsection 4.2)

Replace the test-data chunk with classification of the reference SSDs generated in 4.1:

```r
# Uses N and the generated SSDs from subsection 4.1
arch_weibull   <- classify_ssd(ssd_weibull,   stem_number = N)
arch_reverse_j <- classify_ssd(ssd_reverse_j, stem_number = N)
arch_bimodal   <- classify_ssd(ssd_bimodal,   stem_number = N)

cat("Weibull generator produces:   ", arch_weibull$category, "\n")
cat("Reverse-J generator produces: ", arch_reverse_j$category, "\n")
cat("Bimodal generator produces:   ", arch_bimodal$category, "\n")
```

This is `eval=TRUE`, uses carry-forward variables from 4.1 (idiomatic for a vignette with
sequential sections), and serves the additional purpose of confirming generators produce the
expected archetypes. The return type is a **list** — access the archetype string via `$category`.

The test-data confusion-matrix example (classifying 70 predicted distributions) becomes
`eval=FALSE` since it requires absolute N which is not in `deepReveal_example_data`.

---

## `jsd_divergence` — no change needed (eval=TRUE works as-is)

JSD operates on proportions directly. The chunk comparing two stands' predicted distributions
works without any modification:

```r
p <- as.numeric(preds[1, pred_cols])
q <- as.numeric(preds[2, pred_cols])
cat("JSD (stand 1 vs 2):", round(jsd_divergence(p, q), 4), "nats\n")
# Also: observed vs predicted for same stand
cat("JSD (obs vs pred, stand 1):", round(jsd_divergence(
  as.numeric(preds[1, obs_cols]),
  as.numeric(preds[1, pred_cols])), 4), "nats\n")
```
