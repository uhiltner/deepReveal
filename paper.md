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
archive_doi: "10.5281/zenodo.19607469"
---

# Summary

Neural networks (NNs) are being adopted more and more in the ecological and environmental sciences as powerful tools for modeling complex, nonlinear relationships [@lecun2015deep]. Their ability to learn from large, heterogeneous datasets makes them attractive for tasks such as predicting species distributions, forest structure, and ecosystem dynamics [@reichstein2019deep]. However, NNs' opacity — often referred to as the "black box" problem — remains a significant barrier to their adoption in scientific communities where interpretability and mechanistic understanding are paramount [@rudin2019stop].

`deepReveal` is an R package that provides a comprehensive and flexible framework for conducting sensitivity analyses on Keras-based neural network models. It is designed for researchers who have already trained a model and want to systematically understand *what* drives its predictions, *how* it responds to changes in input variables, and *if* a simpler model with fewer features would perform comparably. The package provides three complementary analytical workflows: (1) permutation feature importance, (2) feature value sensitivity, and (3) feature set comparison. All three workflows have a consistent interface and produce publication-quality output.

# Statement of Need

Existing R packages for model interpretability, such as `iml` [@molnar2018iml], `DALEX` [@biecek2018dalex], and `vip` [@greenwell2020vip], are primarily designed for tabular prediction models with scalar outputs, such as a single predicted value or class. These packages do not natively support models with multivariate, distributional outputs, which are common in ecological applications. In these applications, the prediction target is a distribution itself, such as a stem size distribution (SSD), a species abundance distribution, or a size-class frequency.

`deepReveal` was developed to fill this gap. Its core metric is the Kullback-Leibler (KL) divergence [@kullback1951information], an information-theoretic measure that is appropriate for comparing probability distributions — the natural output type of many ecological NNs. This makes `deepReveal` specifically suited to ecological and environmental modeling contexts where the model output is a vector of relative frequencies or probability densities rather than a single scalar.

Furthermore, `deepReveal` is built around the Keras/TensorFlow ecosystem via the R packages `keras` and `keras3` R packages, and it natively handles the complexities of loading models with custom loss functions, which is a common requirement in applied research.

# Functionality

The package provides the following core functions:

**Workflow 1: Analyze a pre-trained model**

- `permutation_feature_importance()`: This function calculates feature importance by systematically shuffling each input variable and measuring the resulting performance degradation using a user-supplied metric function (e.g., KL divergence or RMSE). The results are returned as a ranked data frame and a ggplot2 bar chart.
- `feature_value_sensitivity()`: This function quantifies how model predictions change as a key feature varies across its observed range (range-response analysis) and how sensitive predictions are to small, user-defined perturbations in feature values (error-effect analysis).
- `analyze_and_visualize_predictions()`: This function produces diagnostic scatter plots and histogram comparisons of observed versus predicted distributions for user-selected model instances.

**Workflow 2: Training and evaluation**

- `compile_fit_predict_nn()`: This function orchestrates a complete training cycle — model compilation, fitting, and prediction — from a user-defined model architecture function and a configuration list.

**Workflow 3: Feature set comparison**

- `run_feature_set_sensitivity_training()`: It retrains the model using user-defined feature subsets to assess the effect of feature selection on predictive performance.
- `plot_feature_set_val_loss_heatmap()`: Visualizes validation loss across all tested feature subsets as an annotated heatmap.
- `generate_feature_set_prediction_plots()`: Generates detailed prediction diagnostic plots for each feature subset model.

The package includes fully anonymized example data (`deepReveal_example_data`), as well as a pre-trained  Keras model [@hiltner2026bridging] derived from the Swiss Experimental Forest Management (EFM) network [@forrester2019efm; @forrester2021efm], enabling users to reproduce all workflows without access to proprietary data.

# Application

`deepReveal` was developed as the analytical foundation of the @hiltner2026bridging study, which uses a deep neural network to predict detailed SSDs from aggregated forest stand data. In that study, `deepReveal` was used to: (1) identify the primary drivers of stem size distribution predictions among stand structural and environmental variables; (2) demonstrate that the NN learned ecologically plausible, nonlinear relationships between forest structure and size distribution; and (3) compare feature sets systematically to show that a parsimonious nine-feature *Forester Field Set* achieved superior predictive performance ($R^2 = 0.95$) by effectively filtering out ecological noise compared to a 37-feature comprehensive benchmark model.

# Acknowledgements

The author would like to thank Jonas Glatthorn (WSL) and Harald Bugmann (ETH Zurich) for their scientific guidance throughout this work. This research was funded by the Swiss National Center for Climate Services (NCCS) via the Federal Office of Meteorology and Climatology MeteoSwiss through the project "NCCS-Impacts" under contract no. 126002225.

# References
