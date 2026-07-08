# deepReveal R Package

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19607469.svg)](https://doi.org/10.5281/zenodo.19607469)

`deepReveal` is an R package for conducting comprehensive sensitivity analyses on Keras-based neural network models. It provides a flexible framework to move from a "black box" model to an interpretable tool for scientific inquiry, allowing researchers to build trust and gain deeper insights from their models.

Neural networks are powerful tools, but their complexity can make them difficult to interpret. `deepReveal` is designed to address this challenge by providing a systematic workflow to answer critical modeling questions:

- **Feature Importance:** Which input variables are the primary drivers of the model's predictions?
- **Model Behavior:** How do predictions change in response to key drivers? Are the learned relationships linear, non-linear, or threshold-based?
- **Model Parsimony:** Could a simpler model with fewer inputs achieve comparable performance?
- **Ecological Benchmarking:** Do predicted distributions conform to expected structural archetypes (even-aged, all-aged, two-cohort)? How do predictions compare to theoretical reference distributions, quantified across multiple complementary metrics (KL divergence, Jensen-Shannon divergence, RMSE, R²)?

## Core Features

### Sensitivity Analysis (v0.1.0)

- **`permutation_feature_importance()`**: Assesses the global importance of each input feature by measuring how model performance degrades when the feature's values are randomly shuffled.
- **`feature_value_sensitivity()`**: Explores the learned functional relationships by showing how model predictions respond as key features are varied across their range.
- **`compile_fit_predict_nn()`**: A flexible training engine to build, compile, fit, and predict with custom or pre-defined Keras model architectures.
- **`run_feature_set_sensitivity_training()`**: Automates the process of retraining models on different subsets of features to systematically test for model parsimony.
- **`plot_feature_set_val_loss_heatmap()`**: Visualizes the results of `run_feature_set_sensitivity_training()` as a heatmap of minimum validation loss per feature set, ordered from best to worst performing and annotated with global feature importance.
- **`generate_feature_set_prediction_plots()`**: Batch-processes all feature-set training results, calling `analyze_and_visualize_predictions()` for each model to produce a complete set of per-feature-set evaluation outputs in separate subdirectories.
- **`analyze_and_visualize_predictions()`**: Generates diagnostic plots and statistics (R², RMSE, KL divergence per class) for a deep evaluation of model performance.
- **`kl_divergence_metric()`**: Row-wise Kullback-Leibler divergence loss, usable as a custom `metric_function` in all sensitivity functions.

### Forest Structure Analysis (v0.2.0)

These functions require no Python/Keras environment and operate on stem size distributions (SSDs) as pure R computations. They complement the sensitivity analysis workflow by enabling ecological interpretation of model predictions.

- **`generate_ssd_weibull()` / `generate_ssd_reverse_j()` / `generate_ssd_bimodal()`**: Generate theoretical reference SSDs for three canonical forest archetypes (even-aged, all-aged selection forest, two-cohort) given a target stem density and basal area. A constrained least-squares solver guarantees exact conservation of both N and BA.
- **`classify_ssd()`**: Classifies an observed or predicted SSD into one of four ecological archetypes (Unimodal, Reverse-J, Bimodal, Irregular) based on peak detection and Spearman rank correlation. Useful for building archetype-level confusion tables across a test set.
- **`compute_prediction_metrics()`**: Computes a comprehensive four-metric tibble (KL divergence, Jensen-Shannon divergence, RMSE, R²) for batch evaluation of model predictions. Complements the visual diagnostics in `analyze_and_visualize_predictions()`.
- **`jsd_divergence()`**: Symmetric, bounded [0, ln 2] Jensen-Shannon divergence between two probability vectors. Unlike KL divergence, JSD is robust to zero predictions and directly comparable across stands with different stem densities and structures.
- **`perturb_features()`**: Applies multiplicative perturbations to selected raw features and re-scales them for model input. Designed for noise-robustness analysis: vary a feature by ±10% and measure metric degradation via `compute_prediction_metrics()`.
- **`stand_qmd()` / `stand_basal_area()`**: Compute quadratic mean diameter and total basal area from SSD inputs; used internally by the generators and available for stand-level structural summaries.
- **`SG_DBH_BREAKS` / `SG_DBH_MIDPOINTS` / `SG_DBH_THETA`**: Exported constants defining the 10-class DBH discretisation (8 cm lower bound, open upper class at 50 cm).

## Installation

There are two ways to install the package.

### From GitLab (Recommended)

You can install the development version of `deepReveal` directly from GitLab using the `devtools` package.

```r
# install.packages("devtools")
devtools::install_gitlab("ites-fe/deepReveal")
```

### From Local Source

If you have cloned this repository to your local machine, you can build and install the package from source using standard R tools:

```r
# From the parent directory of deepReveal/:
install.packages("deepReveal", repos = NULL, type = "source")
```

## Example Usage

### Sensitivity analysis (v0.1.0 functions)

The following workflow identifies the most important input features of the pre-trained example model included with the package.

```r
library(deepReveal)
library(ggplot2)

# 1. Set up paths to the package's example data and model
temp_dir <- tempdir()
data("deepReveal_example_data")
model_data_path <- file.path(temp_dir, "deepReveal_example_data.RData")
save(deepReveal_example_data, file = model_data_path)

model_path <- system.file("extdata", "deepReveal_example_model.keras",
                          package = "deepReveal")

# 2. Run Permutation Feature Importance (PFI) analysis
pfi_output <- permutation_feature_importance(
  model_path         = model_path,
  model_data_name    = "deepReveal_example_data",
  model_data_path    = model_data_path,
  input_feature_set  = "full.inputs",
  metric_function    = kl_divergence_metric,
  higher_is_better   = FALSE,  # lower KL is better
  n_permutations     = 10,
  seed               = 123
)

print(pfi_output$plot)
```

### Forest structure analysis (v0.2.0 functions, no Keras required)

```r
library(deepReveal)

# Generate three theoretical reference SSDs (400 stems/ha, 28 m²/ha BA)
N <- 400; BA <- 28
ssd_weibull   <- generate_ssd_weibull(c_shape = 2.5, N_target = N, BA_target = BA)
ssd_reverse_j <- generate_ssd_reverse_j(q = 1.3,    N_target = N, BA_target = BA)
ssd_bimodal   <- generate_ssd_bimodal(r1 = 0.5, r2 = 1.5,
                                      N_target = N, BA_target = BA)

# Classify each into an ecological archetype
classify_ssd(ssd_weibull,   stem_number = N)$category  # "Unimodal"
classify_ssd(ssd_reverse_j, stem_number = N)$category  # "Reverse-J"
classify_ssd(ssd_bimodal,   stem_number = N)$category  # "Bimodal"

# Compare two SSDs using Jensen-Shannon divergence (symmetric, bounded [0, ln2])
jsd_divergence(ssd_weibull / sum(ssd_weibull),
               ssd_reverse_j / sum(ssd_reverse_j))

# Compute a full prediction quality tibble (KL, JSD, RMSE, R²)
pred_ssd <- generate_ssd_weibull(c_shape = 3.5, N_target = N, BA_target = BA)
compute_prediction_metrics(
  true_abs = ssd_weibull,
  pred_rel = pred_ssd / sum(pred_ssd),
  N_total  = N
)
```

## Citation

The archived v0.1.0 release is available on Zenodo:

> Hiltner, U. (2025). deepReveal: A Framework for Sensitivity Analysis of Neural Networks (v0.1.0). Zenodo. https://doi.org/10.5281/zenodo.19607469

A BibTeX entry:

```bibtex
@software{hiltner2025deepreveal,
  title   = {{deepReveal}: A Framework for Sensitivity Analysis of Neural Networks},
  author  = {Hiltner, Ulrike},
  year    = {2025},
  version = {0.1.0},
  doi     = {10.5281/zenodo.19607469},
  url     = {https://doi.org/10.5281/zenodo.19607469}
}
```

The current development version is **0.2.0**. A new Zenodo release will accompany the corresponding manuscript publication.

This package was developed in conjunction with the following scientific article:

> Hiltner, U., Glatthorn, J., and Bugmann, H. (in preparation). Bridging data gaps in forestry: Neural Network prediction of stem size distributions from aggregated inventories. Journal TBD.

## Development

This package was developed at ETH Zurich, Forest Ecology, Switzerland. For a detailed guide on all functionalities, see the package vignette (`vignette("deepReveal-introduction")`).
