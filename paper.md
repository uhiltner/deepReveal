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
date: 08 July 2026
bibliography: paper.bib
repository: "https://github.com/uhiltner/deepReveal"
archive_doi: "10.5281/zenodo.19607469"
---

# Summary

Neural networks (NNs) are increasingly adopted in the ecological and environmental sciences as powerful tools for modeling complex, nonlinear relationships [@lecun2015deep]. Their ability to learn from large, heterogeneous datasets makes them attractive for tasks such as predicting species distributions, forest structure, and ecosystem dynamics [@reichstein2019deep]. However, NNs' opacity — often referred to as the "black box" problem — remains a significant barrier to their adoption in scientific communities where interpretability and mechanistic understanding are paramount [@rudin2019stop].

`deepReveal` is an R package that provides a comprehensive and flexible framework for conducting sensitivity analyses on Keras-based neural network models. It is designed for researchers who have already trained a model and want to systematically understand *what* drives its predictions, *how* it responds to changes in input variables, and *if* a simpler model with fewer features would perform comparably. The package provides four complementary analytical workflows: (1) permutation feature importance, (2) feature value sensitivity, (3) feature set comparison, and (4) ecological benchmarking of distributional predictions. Unlike the first three, Workflow 4 needs no Python or Keras environment, so ecologists without a deep-learning toolchain can run it; it lets researchers evaluate whether a model's distributional predictions match not just the expected aggregate error but also the ecologically meaningful structural archetype of the reference distribution. All four workflows share a consistent interface and produce publication-quality output.

# Statement of Need

Existing R packages for model interpretability, such as `iml` [@molnar2018iml], `DALEX` [@biecek2018dalex], and `vip` [@greenwell2020vip], are primarily designed for tabular prediction models with scalar outputs, such as a single predicted value or class. These packages do not natively support models with multivariate, distributional outputs, which are common in ecological applications. In these applications, the prediction target is a distribution itself, such as a stem size distribution (SSD), a species abundance distribution, or a size-class frequency.

`deepReveal` was developed to fill this gap. Its core metric is the Kullback-Leibler (KL) divergence [@kullback1951information], an information-theoretic measure appropriate for comparing probability distributions — the natural output type of many ecological NNs. This makes `deepReveal` specifically suited to ecological and environmental modeling contexts where the model output is a vector of relative frequencies or probability densities rather than a single scalar.

A further gap exists at the evaluation stage: `iml`, `DALEX`, and `vip`, like most interpretability tooling, offer no means of benchmarking a distributional prediction against an ecologically meaningful reference. For forest ecology applications this is a substantial omission, because whether a model correctly recovers the *structural type* of a stand — even-aged, all-aged, or two-cohort — is often more informative to a forest manager than any single aggregate error metric. `deepReveal` closes this gap by pairing theoretical reference distributions for canonical forest archetypes with an archetype classifier and a multi-metric evaluation suite.

`deepReveal` is built around the Keras/TensorFlow ecosystem via the R packages `keras` and `keras3`, and it natively handles the complexities of loading models with custom loss functions, which is a common requirement in applied research.

# Functionality

The package provides the following core functions:

**Workflow 1: Analyze a pre-trained model**

- `permutation_feature_importance()`: Calculates feature importance by systematically shuffling each input variable and measuring the resulting performance degradation using a user-supplied metric function (e.g., KL divergence or RMSE), returning a ranked data frame and a ggplot2 bar chart.
- `feature_value_sensitivity()`: Quantifies how model predictions change as a key feature varies across its observed range (range-response analysis) and how sensitive predictions are to small, user-defined perturbations in feature values (error-effect analysis).
- `analyze_and_visualize_predictions()`: Produces diagnostic scatter plots and histogram comparisons of observed versus predicted distributions for user-selected model instances.

**Workflow 2: Training and evaluation**

- `compile_fit_predict_nn()`: Orchestrates a complete training cycle — model compilation, fitting, and prediction — from a user-defined model architecture function and a configuration list.

**Workflow 3: Feature set comparison**

- `run_feature_set_sensitivity_training()`: Retrains the model using user-defined feature subsets to assess the effect of feature selection on predictive performance.
- `plot_feature_set_val_loss_heatmap()`: Visualizes validation loss across all tested feature subsets as an annotated heatmap.
- `generate_feature_set_prediction_plots()`: Generates detailed prediction diagnostic plots for each feature subset model.

**Workflow 4: Ecological benchmarking of distributional predictions**

Because it requires no Python or Keras installation, this workflow can also benchmark distributional predictions from models trained entirely outside `deepReveal`, not only those produced by Workflows 1–3.

- `generate_ssd_weibull()`, `generate_ssd_reverse_j()`, `generate_ssd_bimodal()`: These functions generate theoretical reference SSDs corresponding to the three canonical forest structural archetypes — even-aged (Weibull), all-aged (reverse-J), and two-cohort (bimodal) — for a target stem density and basal area. A constrained least-squares solver [@cao1999stand] fits each reference distribution so that it conserves both stem density (N) and basal area (BA) exactly, ensuring the reference is stand-realistic rather than merely shape-matched.
- `classify_ssd()`: Classifies an observed or predicted SSD into one of four ecological archetypes (Unimodal, Reverse-J, Bimodal, Irregular) using peak detection and rank correlation, so that model evaluation can be stratified by structural type.
- `compute_prediction_metrics()`: Computes a four-metric tibble — Kullback-Leibler divergence, Jensen-Shannon divergence, RMSE, and $R^2$ — enabling systematic evaluation of predicted SSDs against theoretical or empirical reference distributions.
- `jsd_divergence()`: Computes the Jensen-Shannon divergence [@lin1991divergence], a symmetric, bounded ($[0, \ln 2]$) alternative to KL divergence that remains well-defined when predicted or reference bins are zero.
- `perturb_features()`: Applies multiplicative perturbations to selected input features, supporting noise-robustness analysis that simulates field measurement uncertainty.
- `stand_qmd()`, `stand_basal_area()`: Compute quadratic mean diameter and basal area from a discretized SSD, providing stand-level summary statistics consistent with standard forest mensuration [@bailey1973quantifying].

The package includes fully anonymized example data (`deepReveal_example_data`), as well as a pre-trained Keras model [@hiltner2026bridging] derived from the Swiss Experimental Forest Management (EFM) network [@forrester2019efm; @forrester2021efm], enabling users to reproduce Workflows 1–3 without access to proprietary data; Workflow 4's reference-archetype functions require no external data at all.

# Application

`deepReveal` was developed as the analytical foundation of the @hiltner2026bridging study, which uses a deep neural network to predict detailed SSDs from aggregated forest stand data. In that study, `deepReveal` was used to: (1) identify the primary drivers of stem size distribution predictions among stand structural and environmental variables; (2) demonstrate that the NN learned ecologically plausible, nonlinear relationships between forest structure and size distribution; and (3) compare feature sets systematically to show that a parsimonious nine-feature *Forester Field Set* achieved superior predictive performance ($R^2 = 0.95$) by effectively filtering out ecological noise compared to a 37-feature comprehensive benchmark model.

Workflow 4 formed the analytical core of the external validation reported in the @hiltner2026bridging supplementary material, which benchmarked the same model against 105 European marteloscope plots from the Integrate+/TreMs network [@zudin2022trems; @kraus2022gbif]. `classify_ssd()` classified each plot's observed SSD into its structural archetype, the matching `generate_ssd_*()` function generated theoretical reference distributions, and `compute_prediction_metrics()` and `jsd_divergence()` evaluated prediction quality per archetype. This archetype-stratified evaluation showed where the model's distributional predictions held up outside its original training network and where structural type, rather than aggregate error alone, explained the remaining discrepancies.

# Acknowledgements

The author would like to thank Jonas Glatthorn (WSL) and Harald Bugmann (ETH Zurich) for their scientific guidance throughout this work. This research was funded by the Swiss National Center for Climate Services (NCCS) via the Federal Office of Meteorology and Climatology MeteoSwiss through the project "NCCS-Impacts" under contract no. 126002225 and by the Velux Foundation through the project "ProForest-DSS" under contract no. 2347. AI-assisted tools (Anthropic's Claude, DeepL) were used to assist with code development and manuscript drafting; all AI-assisted content was reviewed and verified by the author, who takes full responsibility for the accuracy and integrity of the package and this paper.

# References
