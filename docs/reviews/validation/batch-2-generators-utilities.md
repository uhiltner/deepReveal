# Validation — Batch 2: SSD Generators + Utilities
Validator: independent (not plan author)
Source read: `01b_data_processing_funs.R` (459 lines)
deepReveal read: `R/sensitivity_functions.R` (1868 lines); `R/globals.R`; `R/data.R`
Pre-check: grep across entire deepReveal `R/` for all proposed names → zero matches (no reinvention)

| Item | Verdict | Evidence (file:line) | Reasoning | Recommended action |
|---|---|---|---|---|
| **E3** `generate_ssd_weibull()` | **VALID** | `01b:276–284` | Exists at L276. All 4 claimed dependencies confirmed in same file: `dG_from_N_BA` (L61), `siipilehto_b` (L90), `weibull_class_probs` (L108), `cao_baldwin_2c` (L177). **Plan's "global scope reads" is imprecise:** `SG_DBH_MIDPOINTS` and `SG_DBH_BREAKS` appear as default parameter values (`dbh_rep = SG_DBH_MIDPOINTS`, `breaks_cm = SG_DBH_BREAKS`), not hardcoded body reads. Refactor still needed (update defaults on port). Second-order hidden global: `generate_ssd_weibull` calls `weibull_class_probs` without forwarding `theta`, so `SG_DBH_THETA` propagates through H5's own default. | Port as-is; update `SG_DBH_MIDPOINTS`/`SG_DBH_BREAKS` defaults. Document `theta` propagation via H5. |
| **E4** `generate_ssd_reverse_j()` | **VALID** (with false-positive sub-claim) | `01b:309–313` | Exists at L309. **FALSE-POSITIVE sub-claim:** `dG_from_N_BA` is listed as a dependency but is never called in this function body. Actual dependencies: `bdq_seed_counts` (L147) + `cao_baldwin_2c` (L177). Function body is just two lines. `SG_DBH_MIDPOINTS` appears as default parameter value only. | Remove `dG_from_N_BA` from E4 dependency checklist. Otherwise port with `bdq_seed_counts` + `cao_baldwin_2c`. |
| **E5** `generate_ssd_bimodal()` ← `generate_ssd_bimodal_gauss()` | **WRONG-FIX** | `01b:422–458`, `01b:434` | Exists at L422. **Three errors in plan:** (1) Phantom dependency on `generate_ssd_weibull` — the fallback at L435–438 calls `siipilehto_b`+`weibull_class_probs`+`cao_baldwin_2c` directly; `generate_ssd_weibull` is never called; no circular dependency exists. (2) Phantom dependency on `BA_from_ssd` — never called in the body. (3) **Critical unmentioned body-level global:** line 434 reads `SG_DBH_THETA` directly as `mu1 < SG_DBH_THETA + sigma`. This is NOT a default value — `theta` has no corresponding parameter. This will cause `object 'SG_DBH_THETA' not found` in deepReveal. | **Must fix before porting:** add `theta_cm = 8L` parameter to function signature; replace `SG_DBH_THETA` at L434 with `theta_cm`. Remove phantom deps from checklist. Real deps: `dG_from_N_BA`, `siipilehto_b`, `weibull_class_probs`, `cao_baldwin_2c`. |
| **H3** `cao_baldwin_solver_()` ← `cao_baldwin_2c()` | **VALID** | `01b:177–249` | Exists at L177. Nested helpers `.solve_cls_2c` and `.bracketing_fallback` defined inside body. `dG` computed inline. Only base R used. Default `midpoints_cm = SG_DBH_MIDPOINTS` (L178) is a parameter default only. | Port as-is; update `SG_DBH_MIDPOINTS` default. |
| **H4** `siipilehto_scale_()` ← `siipilehto_b()` | **VALID** | `01b:90–92` | Exists at L90. Single formula `d_gM / ((-log(0.5))^(1/c_shape))`. No globals, no external calls. | Port verbatim. |
| **H5** `weibull_class_probs_()` ← `weibull_class_probs()` | **VALID** (with wrong characterization) | `01b:108–128` | Exists at L108. **Plan's claim is factually wrong on one point:** `dbh_midpoints` is NOT a parameter and is not used in this function — the plan appears to have confused it with another function. The function computes CDF differences; midpoints play no role. Actual parameters: `b_shape` (required), `c_shape` (required), `breaks_cm = SG_DBH_BREAKS` (L110), `theta = SG_DBH_THETA` (L109). `theta` is already parameterized — better than plan described. | Correct plan characterization. Port with updated `SG_DBH_BREAKS` and `SG_DBH_THETA` defaults. |
| **H6** `deliocourt_seeds_()` ← `bdq_seed_counts()` | **VALID** | `01b:147–153` | Exists at L147. Parameters `function(N_target, q, n_classes = 10L)` match exactly. Pure arithmetic, no globals, no external calls. | Port verbatim. |
| **U1** `stand_qmd()` ← `dG_from_N_BA()` | **VALID** | `01b:61–63` | Exists at L61. Formula `sqrt(4 * BA_target / (pi * N_target)) * 100` confirmed (mathematically identical to plan). No deps, no globals. | Port verbatim. |
| **U2** `stand_basal_area()` ← `BA_from_ssd()` | **VALID** | `01b:72–74` | Exists at L72. `counts` is required; `midpoints_cm` is a parameter with default `SG_DBH_MIDPOINTS`. Plan's "(not globals)" is technically correct (it is a parameter) but calling without `midpoints_cm` silently uses the project global. | Update `SG_DBH_MIDPOINTS` default on port. |

---

## Hidden Globals Summary

| Constant | Where it appears | Nature | Risk |
|---|---|---|---|
| `SG_DBH_BREAKS` | E3 L277, H5 L110, H3 L178 | Default parameter value | LOW — parameterized; update default on port |
| `SG_DBH_MIDPOINTS` | E3 L278, H3 L178, U2 L72 | Default parameter value | LOW — parameterized; update default on port |
| `SG_DBH_THETA` | H5 L109, E3 (via H5) | Default parameter value | LOW — already parameterized |
| `SG_DBH_THETA` | **E5 L434 — body-level read** | **Hardcoded body read** | **HIGH — will fail in deepReveal; must fix before porting** |

**Batch 2 summary: 7/9 VALID, 1 WRONG-FIX (E5), 1 VALID-with-false-positive-sub-claim (E4).**
E5 is the only blocker — requires adding `theta_cm` parameter before porting.
