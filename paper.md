---
title: 'deepReveal: A Framework for Sensitivity Analysis of Neural Networks in Ecological Research'
tags:
  - R
  - neural networks
  - sensitivity analysis
  - feature importance
  - ecology
  - forest modeling
authors:
  - name: Ulrike Hiltner
    orcid: 0000-0001-5663-7068
    affiliation: 1
affiliations:
  - name: Forest Ecology Group, ETH Zurich, Switzerland
    index: 1
date: 16 April 2026
bibliography: paper.bib
repository: "https://github.com/uhiltner/deepReveal"
---

# Summary

Neural networks (NNs) are increasingly adopted in ecological and environmental sciences as powerful tools for modeling complex, non-linear relationships [@lecun2015deep]. Their ability to learn from large, heterogeneous datasets makes them attractive for tasks such as predicting species distributions, forest structure, and ecosystem dynamics [@reichstein2019deep]. However, the opacity of NNs — commonly referred to as the "black box" problem — remains a significant barrier to their uptake in scientific communities where interpretability and mechanistic understanding are paramount [@rudin2019stop].

`deepReveal` is an R package that provides a comprehensive and flexible framework for conducting sensitivity analyses on Keras-based neural network models. It is designed for researchers who have already trained a model and want to systematically understand *what* drives its predictions, *how* it responds to changes in input variables, and *whether* a simpler, more parsimonious model with fewer features would perform comparably. The package provides three complementary analytical workflows: (1) Permutation Feature Importance, (2) Feature Value Sensitivity, and (3) Feature Set Comparison, all with a consistent interface and publication-quality output.

# Statement of Need

Existing R packages for model interpretability — such as `iml` [@molnar2018iml], `DALEX` [@biecek2018dalex], and `vip` [@greenwell2020vip] — are primarily designed for tabular prediction models with scalar outputs (e.g., a single predicted value or class). They do not natively support models with multivariate, distributional outputs, which are common in ecological applications where the prediction target is itself a distribution, such as a stem size distribution (SSD), a species abundance distribution, or a size-class frequency.

`deepReveal` was developed to fill this gap. Its core metric is the Kullback-Leibler (KL) divergence [@kullback1951information], an information-theoretic measure that is appropriate for comparing probability distributions — the natural output type of many ecological NNs. This makes `deepReveal` specifically suited to ecological and environmental modeling contexts where the model output is a vector of relative frequencies or probability densities rather than a single scalar.

Furthermore, `deepReveal` is built around the Keras/TensorFlow ecosystem via the `keras` and `keras3` R packages, and natively handles the complexities of loading models with custom loss functions — a common requirement in applied research.

# Functionality

The package provides the following core functions:

**Workflow 1: Analyzing a Pre-Trained Model**

- `permutation_feature_importance()`: Calculates feature importance by systematically shuffling each input variable and measuring the resulting performance degradation using a user-supplied metric function (e.g., KL divergence, RMSE). Results are returned as a ranked data frame and a ggplot2 bar chart.
- `feature_value_sensitivity()`: Quantifies how model predictions change as a key feature varies across its observed range (range-response analysis) and how sensitive predictions are to small, user-defined perturbations in feature values (error-effect analysis).
- `analyze_and_visualize_predictions()`: Produces diagnostic scatter plots and histogram comparisons of observed vs. predicted distributions for user-selected model instances.

**Workflow 2: Training and Evaluation**

- `compile_fit_predict_nn()`: Orchestrates a complete training cycle — model compilation, fitting, and prediction — from a user-defined model architecture function and a configuration list.

**Workflow 3: Feature Set Comparison**

- `run_feature_set_sensitivity_training()`: Systematically retrains the model using user-defined feature subsets to assess the effect of feature selection on predictive performance.
- `plot_feature_set_val_loss_heatmap()`: Visualizes validation loss across all tested feature subsets as an annotated heatmap.
- `generate_feature_set_prediction_plots()`: Generates detailed prediction diagnostic plots for each feature subset model.

The package includes fully anonymized example data (`deepReveal_example_data`) and a pre-trained example Keras model derived from the Swiss Experimental Forest Management (EFM) network [@forrester2019efm; @forrester2021efm], enabling users to reproduce all workflows without access to proprietary data.

# Application

`deepReveal` was developed as the analytical backbone of @hiltner2026bridging, a study that predicts detailed forest stem size distributions from aggregated inventory data using a deep neural network. In that work, `deepReveal` was used to: (1) identify which stand structural and environmental variables were the primary drivers of stem size distribution predictions; (2) demonstrate that the neural network learned ecologically plausible, non-linear relationships between forest structure and size distribution; and (3) systematically compare feature sets to show that a parsimonious 9-feature Forester Field Set achieved superior predictive performance ($R^2 = 0.95$) compared to a 37-feature comprehensive benchmark model by effectively filtering out ecological noise.

# Acknowledgements

The author thanks Jonas Glatthorn and Harald Bugmann (ETH Zurich) for scientific guidance throughout this work. This research was funded by the Swiss National Center for Climate Services (NCCS) via the Federal Office of Meteorology and Climatology MeteoSwiss through the project "NCCS-Impacts" under contract no. 126002225.

# References
