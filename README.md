# deepReveal R Package

`deepReveal` is an R package for conducting comprehensive sensitivity analyses on Keras-based neural network models. It provides a flexible framework to move from a "black box" model to an interpretable tool for scientific inquiry, allowing researchers to build trust and gain deeper insights from their models.

Neural networks are powerful tools, but their complexity can make them difficult to interpret. `deepReveal` is designed to address this challenge by providing a systematic workflow to answer critical modeling questions:

- **Feature Importance:** Which input variables are the primary drivers of the model's predictions?
- **Model Behavior:** How do predictions change in response to key drivers? Are the learned relationships linear, non-linear, or threshold-based?
- **Model Parsimony:** Could a simpler model with fewer inputs achieve comparable performance?

## Core Features

The package provides a suite of functions to cover the full sensitivity analysis workflow:

- **`permutation_feature_importance()`**: Assesses the global importance of each input feature by measuring how model performance degrades when the feature's values are randomly shuffled.
- **`feature_value_sensitivity()`**: Explores the learned functional relationships by showing how model predictions respond as key features are varied across their range.
- **`compile_fit_predict_nn()`**: A flexible training engine to build, compile, fit, and predict with custom or pre-defined Keras model architectures.
- **`run_feature_set_sensitivity_training()`**: Automates the process of retraining models on different subsets of features to systematically test for model parsimony.
- **`analyze_and_visualize_predictions()`**: Generates a rich set of diagnostic plots (e.g., scatterplots, histograms) and statistics (e.g., R², RMSE, KL Divergence per class) to perform a deep evaluation of model performance.

## Installation

There are two ways to install the package.

### From GitLab (Recommended)

You can install the development version of `deepReveal` directly from GitLab using the `devtools` package. This is the simplest method for most users.

```
# install.packages("devtools")
devtools::install_gitlab("ites-fe/deepReveal")
```

### From Local Source

If you have cloned this repository to your local machine, you can build the package from source. The repository includes a `build_workflow.R` script that automates the entire process. Running this script will:

1. Document the package functions.
2. Run a comprehensive check for errors.
3. Build the final package bundle (`.tar.gz` file).
4. Build the package's PDF manual.

The resulting `.tar.gz` and `.pdf` files will be saved in the directory that contains the `deepReveal/` project folder.

## Example Usage

Here is a simple workflow to analyze the pre-trained example model included with the package. This demonstrates how to identify the most important input features.

```
library(deepReveal)
library(ggplot2)

# 1. Set up paths to the package's example data and model
temp_dir <- tempdir()
data("deepReveal_example_data")
model_data_path <- file.path(temp_dir, "deepReveal_example_data.RData")
save(deepReveal_example_data, file = model_data_path)

model_path <- system.file("extdata", "deepReveal_example_model.keras",
                          package = "deepReveal")

# 2. Define the performance metric (Kullback-Leibler divergence)
# This uses the package's built-in row-wise KL divergence function.
metric_func <- kl_divergence_metric

# 3. Run Permutation Feature Importance (PFI) analysis
pfi_output <- permutation_feature_importance(
  model_path = model_path,
  model_data_name = "deepReveal_example_data",
  model_data_path = model_data_path,
  input_feature_set = "full.inputs",
  metric_function = metric_func,
  higher_is_better = FALSE, # Lower KL is better
  n_permutations = 10,
  seed = 123
)

# 4. Print the resulting importance plot
print(pfi_output$plot)
```

## Citation

To cite this package in your work, please use:

> Hiltner, U. (2025). deepReveal: A Framework for Sensitivity Analysis of Neural Networks. R package version 0.1.0.

A BibTeX entry for LaTeX users is:

```
@Manual{,
  title = {deepReveal: A Framework for Sensitivity Analysis of Neural Networks},
  author = {Ulrike Hiltner},
  year = {2025},
  note = {R package version 0.1.0},
}
```

This package was developed in conjunction with the following scientific article, which is currently in preparation:

> Hiltner, U., Glatthorn, J., and Bugmann, H. (in preparation). Bridging data gaps in forestry: Neural Network prediction of stem size distributions from aggregated inventories. Journal TBD.

## Development

This package was developed at ETH Zurich, Forest Ecology, Switzerland. For a detailed guide on all functionalities, please see the package vignette.