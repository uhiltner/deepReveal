#' @title Perform Permutation Feature Importance for a Keras Model
#'
#' @description This function calculates feature importance for a trained Keras
#'   model using a permutation-based approach. It systematically shuffles each
#'   predictor variable, measures the resulting decrease in model performance
#'   using a specified metric (e.g., KL divergence), and ranks features by their
#'   importance. The function handles loading the model and data, performs the
#'   permutations, and can save a publication-quality bar plot of the results.
#'
#' @details The importance of a feature is quantified as the average change in
#'   the performance metric when that feature's values are permuted. If
#'   `higher_is_better = TRUE` (e.g., for R-squared), importance is calculated as
#'   `(baseline_performance - permuted_performance)`. If `FALSE` (e.g., for an
#'   error metric like KL divergence or RMSE), importance is calculated as
#'   `(permuted_performance - baseline_performance)`. A positive importance score
#'   always indicates that the feature contributes positively to the model's performance.
#'
#' @section Handling Custom Loss Functions:
#'   If the Keras model was trained with a custom loss function, this function
#'   can load it correctly, provided the loss function follows the structure of
#'   a weighted sum of KL divergence and Mean Absolute Error. To enable this,
#'   the `custom_loss_alpha` parameter must be provided with the same alpha
#'   value that was used during training.
#'
#' @section Python Backend Setup:
#' This function requires a working Python environment with the TensorFlow
#' library installed. It is designed to work with either the `keras` or `keras3`
#' R package. It is recommended that users install one of these packages and
#' configure their Python environment before use (e.g., via `keras::install_keras()`).
#'
#' @param model_path A string specifying the full path to the saved Keras model
#'   in the `.keras` directory format.
#' @param model_data_path A string specifying the full path to the `.RData` file
#'   containing the data object specified in `model_data_name`.
#' @param model_data_name A string specifying the name of the R object within the
#'   `.RData` file that contains the data (e.g., "model_data").
#' @param custom_loss_alpha An optional numeric value. If the model was trained with the custom
#'   combined KLD+MAE loss, provide the alpha weight used during training here.
#'   Defaults to `NULL`, assuming a standard loss function.
#' @param input_feature_set A string identifying the set of input features to use.
#'   This can be a key like "full.inputs" to use `loaded_data_object$input_features`,
#'   a name of a list element within `loaded_data_object$feature_sets`, or a
#'   character vector of feature names.
#' @param target_features An optional character vector of target feature names.
#'   If `NULL` (the default), the function attempts to retrieve them from
#'   `loaded_data_object$target_features`.
#' @param metric_function A function used to calculate the model's performance metric.
#'   This function must accept two arguments, `(y_true, y_pred)`, and return a single
#'   numeric value. Required.
#' @param higher_is_better A logical value. Set to `TRUE` if a higher score from
#'   `metric_function` indicates better model performance (e.g., R-squared), or
#'   `FALSE` if a lower score is better (e.g., RMSE, KL divergence).
#'   Defaults to `TRUE`.
#' @param feature_labels An optional named character vector to provide user-friendly
#'   labels for features in the output plot. The names should be the raw feature
#'   names (e.g., `c("stem_number.ha" = "Stem Number / ha")`). If `NULL`, raw
#'   feature names are used. Defaults to `NULL`.
#' @param plot_filename An optional string for the desired filename of the output
#'   plot (e.g., "pfi_plot.pdf"). If `NULL`, the plot is not saved to disk.
#'   Defaults to `NULL`.
#' @param plot_save_path A string for the directory path where the plot will be saved.
#'   Required if `plot_filename` is not `NULL`.
#' @param bar_color The fill color for the bars in the plot. Can be "orange",
#'   "grey", or a custom hex color code (e.g., "#1f77b4"). Defaults to "grey".
#' @param n_permutations An integer specifying the number of permutations to
#'   perform for each feature. Defaults to 5.
#' @param seed An optional integer to set the random seed for reproducibility.
#'   Defaults to `NULL`.
#' @param plot_width The width of the saved plot. Defaults to 8.
#' @param plot_height The height of the saved plot. Defaults to 8.
#' @param plot_units A string specifying the units for plot dimensions (e.g., "cm", "in").
#'   Defaults to "cm".
#'
#' @return A list containing:
#'   \item{results}{A data frame with two columns: `Feature` and `Importance`, sorted from most to least important.}
#'   \item{plot}{The ggplot object for the feature importance plot. Can be further customized.}
#'
#' @importFrom ggplot2 ggplot aes geom_bar coord_flip labs theme_classic theme element_text rel margin element_line element_blank ggsave
#' @importFrom stats predict na.omit
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' # This is a conceptual example demonstrating how to use the function
#' # with the example data and model provided in the 'deepReveal' package.
#'
#' # We assume a metric function `kl_divergence_metric` is defined.
#' # kl_divergence_metric <- function(y_true, y_pred) { ... }
#'
#' # Path to the example Keras model included in the package
#' model_path <- system.file("extdata", "deepReveal_example_model.keras",
#'                           package = "deepReveal")
#'
#' # To use this function, the example data needs to be saved to a temporary
#' # .RData file first, as the function reads data from a path.
#' data("deepReveal_example_data")
#' temp_data_path <- file.path(tempdir(), "model_data.RData")
#' save(deepReveal_example_data, file = temp_data_path)
#'
#' # Run the permutation feature importance
#' # For a model with a custom loss, specify custom_loss_alpha
#' pfi_output <- permutation_feature_importance(
#'   model_path = model_path,
#'   model_data_name = "deepReveal_example_data",
#'   model_data_path = temp_data_path,
#'   custom_loss_alpha = 0.1, # Example alpha for custom loss
#'   input_feature_set = "full.inputs",
#'   metric_function = kl_divergence_metric,
#'   higher_is_better = FALSE,
#'   n_permutations = 10,
#'   seed = 123
#' )
#'
#' # View the results data frame
#' head(pfi_output$results)
#'
#' # Display the plot
#' print(pfi_output$plot)
#' }
#' @export
permutation_feature_importance <- function(model_path,
                                           model_data_path,
                                           model_data_name,
                                           custom_loss_alpha = NULL, # MODIFIED: Added parameter
                                           input_feature_set,
                                           target_features = NULL,
                                           metric_function,
                                           higher_is_better = TRUE,
                                           feature_labels = NULL,
                                           plot_filename = NULL,
                                           plot_save_path = NULL,
                                           bar_color = "grey",
                                           n_permutations = 5,
                                           seed = NULL,
                                           plot_width = 8,
                                           plot_height = 8,
                                           plot_units = "cm") {

  # --- 0. Argument validation ---
  if (missing(metric_function) || !is.function(metric_function)) {
    stop("`metric_function` must be a function and is a required argument.")
  }
  if (!is.numeric(n_permutations) || length(n_permutations) != 1 || n_permutations < 1) {
    stop("`n_permutations` must be a single positive integer.")
  }
  n_permutations <- as.integer(n_permutations)
  if (!is.null(plot_filename) && is.null(plot_save_path)) {
    stop("`plot_save_path` must be provided when `plot_filename` is specified.")
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is needed for plotting. Please install it.", call. = FALSE)
  }

  # --- 1. Set seed ---
  if (!is.null(seed)) set.seed(seed)

  # --- 2. Load Model ---
  message(paste("Loading model from:", model_path))
  if (!file.exists(model_path)) stop(paste("Model file not found at:", model_path))

  model <- NULL

  load_model_func <- NULL

  # This block dynamically loads the model using the appropriate package
  # to avoid R CMD check NOTEs for suggested packages.
  if (requireNamespace("keras3", quietly = TRUE)) {
    message("Using 'keras3' package to load model.")
    load_model_func <- get("load_model", asNamespace("keras3"))
    loss_kl_divergence <- get("loss_kl_divergence", asNamespace("keras3"))
    loss_mean_absolute_error <- get("loss_mean_absolute_error", asNamespace("keras3"))
  } else if (requireNamespace("keras", quietly = TRUE)) {
    message("Using 'keras' package as a fallback to load model.")
    load_model_func <- get("load_model", asNamespace("keras"))
    loss_kl_divergence <- get("loss_kullback_leibler_divergence", asNamespace("keras"))
    loss_mean_absolute_error <- get("loss_mean_absolute_error", asNamespace("keras"))
  } else {
    stop("Neither 'keras3' nor 'keras' package is available to load the model.")
  }

  tryCatch({
    if (!is.null(custom_loss_alpha)) {
      message("Defining custom loss function for model loading...")
      loss_combined_kld_mae <- function(y_true, y_pred) {
        kld_loss <- loss_kl_divergence(y_true, y_pred)
        mae_loss <- loss_mean_absolute_error(y_true, y_pred)
        (custom_loss_alpha * kld_loss) + ((1 - custom_loss_alpha) * mae_loss)
      }
      model <- load_model_func(
        model_path,
        custom_objects = c("custom_loss" = loss_combined_kld_mae)
      )
    } else {
      model <- load_model_func(model_path)
    }
    message("Model loaded successfully.")
  }, error = function(e) {
    stop(paste("Failed to load model. Error:", e$message))
  })

  if (is.null(model)) stop("Model could not be loaded.")

  # --- 3. Load Data ---
  message(paste("Loading data from:", model_data_path))
  if (!file.exists(model_data_path)) stop(paste("Data file not found at:", model_data_path))
  data_env <- new.env(); load(model_data_path, envir = data_env)
  if (!model_data_name %in% ls(envir = data_env)) stop(paste("Object '", model_data_name, "' not found in loaded RData file."))
  loaded_data_object <- data_env[[model_data_name]]; message("Data loaded successfully.")
  if (is.null(loaded_data_object$test_data)) stop(paste0("`test_data` not found in '", model_data_name, "' object."))
  test_data_df <- loaded_data_object$test_data
  if (!is.data.frame(test_data_df) && !is.matrix(test_data_df)) stop("`test_data` must be a data frame or matrix.")

  # --- 4. Determine Target Features ---
  actual_target_features <- NULL
  if (!is.null(target_features)) {
    if (is.character(target_features) && length(target_features) > 0) {
      actual_target_features <- target_features
      message("Using `target_features` from function call.")
    } else {
      stop("Provided `target_features` must be a character vector.")
    }
  } else {
    if (!is.null(loaded_data_object$target_features)) {
      actual_target_features <- loaded_data_object$target_features
      message(paste("Using `target_features` from '", model_data_name, "$target_features'.", sep=""))
    } else {
      stop(paste0("`target_features` not in call and not in '", model_data_name, "$target_features'."))
    }
  }

  # --- 5. Determine Actual Input Features ---
  actual_input_features <- NULL
  if (is.character(input_feature_set) && length(input_feature_set) > 1) {
    actual_input_features <- input_feature_set
    message("Using `input_feature_set` directly as the vector of feature names.")
  } else if (is.character(input_feature_set) && length(input_feature_set) == 1) {
    if (input_feature_set %in% names(loaded_data_object)) {
      actual_input_features <- loaded_data_object[[input_feature_set]]
      message(paste("Using input features from `", model_data_name, "$", input_feature_set, "`.", sep=""))
    } else if (!is.null(loaded_data_object$feature_sets) && input_feature_set %in% names(loaded_data_object$feature_sets)) {
      actual_input_features <- loaded_data_object$feature_sets[[input_feature_set]]
      message(paste("Using input feature set key '", input_feature_set, "' from `", model_data_name, "$feature_sets`.", sep=""))
    }
  }

  if (is.null(actual_input_features)) {
    if (!is.null(loaded_data_object$input_features)) {
      actual_input_features <- loaded_data_object$input_features
      message(paste("Using `input_features` from `", model_data_name, "$input_features` as fallback.", sep=""))
    } else {
      stop("Could not determine `actual_input_features`.")
    }
  }

  # --- 6. Prepare test_x and test_y ---
  missing_inputs <- actual_input_features[!actual_input_features %in% colnames(test_data_df)]
  if (length(missing_inputs) > 0) {
    stop(paste("Input features not found in `test_data_df`:", paste(missing_inputs, collapse=", ")))
  }
  missing_targets <- actual_target_features[!actual_target_features %in% colnames(test_data_df)]
  if (length(missing_targets) > 0) {
    stop(paste("Target features not found in `test_data_df`:", paste(missing_targets, collapse=", ")))
  }
  test_x <- as.matrix(test_data_df[, actual_input_features, drop = FALSE])
  test_y <- as.matrix(test_data_df[, actual_target_features, drop = FALSE])
  message(paste("Prepared test_x (", nrow(test_x), "x", ncol(test_x), ") and test_y (", nrow(test_y), "x", ncol(test_y), ").", sep=""))

  # --- 7. Calculate baseline performance ---
  message("Calculating baseline performance...")
  baseline_predictions <- stats::predict(model, test_x) #baseline_predictions <- stats::predict(model, test_x)
  baseline_performance <- metric_function(test_y, baseline_predictions)
  message(paste("Baseline performance:", round(baseline_performance, 4)))

  # --- 8. Initialize importances ---
  feature_importances_raw <- vector("list", length(actual_input_features))
  names(feature_importances_raw) <- actual_input_features

  # --- 9. Permutation loop ---
  message("Starting permutation importance calculation...")
  for (j in seq_along(actual_input_features)) {
    current_feature_name <- actual_input_features[j]
    message(paste("  Permuting feature:", current_feature_name, "(", j, "/", length(actual_input_features), ")"))
    permuted_performances_for_feature <- numeric(n_permutations)
    for (i in 1:n_permutations) {
      test_x_permuted <- test_x
      test_x_permuted[, j] <- sample(test_x_permuted[, j])
      permuted_predictions <- as.matrix(stats::predict(model, test_x_permuted))#permuted_predictions <- stats::predict(model, test_x_permuted)
      permuted_performances_for_feature[i] <- metric_function(test_y, permuted_predictions)
    }
    avg_permuted_performance <- mean(permuted_performances_for_feature, na.rm = TRUE)

    if (higher_is_better) {
      feature_importances_raw[[current_feature_name]] <- baseline_performance - avg_permuted_performance
    } else {
      feature_importances_raw[[current_feature_name]] <- avg_permuted_performance - baseline_performance
    }
  }
  message("Permutation importance calculation complete.")

  final_importances_vec <- unlist(feature_importances_raw)
  sorted_indices <- order(final_importances_vec, decreasing = TRUE, na.last = TRUE)
  results_df <- data.frame(Feature = names(final_importances_vec)[sorted_indices],
                           Importance = final_importances_vec[sorted_indices],
                           row.names = NULL)

  # --- 10. Plotting (Enhanced for Publication) ---
  message("Generating plot...")
  plot_df <- results_df

  # Apply custom labels if provided
  if (!is.null(feature_labels)) {
    if (!is.character(feature_labels) || is.null(names(feature_labels))) {
      warning("`feature_labels` should be a named character vector. Ignoring.")
    } else {
      matched_indices <- match(plot_df$Feature, names(feature_labels))
      plot_df$Feature[!is.na(matched_indices)] <- feature_labels[stats::na.omit(matched_indices)]
    }
  }

  fill_color <- switch(tolower(bar_color), "orange" = "#E69F00", "grey" = "#666666", bar_color)
  if (is.null(fill_color)) {
    warning(paste("`bar_color` '", bar_color, "' not recognized. Defaulting to grey.", sep=""))
    fill_color <- "#666666"
  }

  plot_df$Feature <- factor(plot_df$Feature, levels = rev(plot_df$Feature))

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = .data$Feature, y = .data$Importance)) +
    ggplot2::geom_bar(stat = "identity", fill = fill_color, width = 0.7, na.rm = TRUE) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = NULL, y = "Importance (Change in Performance)") +
    ggplot2::theme_classic(base_size = 10) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", size = ggplot2::rel(1.2)),
      axis.title.x = ggplot2::element_text(size = ggplot2::rel(1), margin = ggplot2::margin(t = 10)),
      axis.text = ggplot2::element_text(color = "black"),
      panel.grid.major.x = ggplot2::element_line(color = "grey90", linetype = "dotted"),
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  if (!is.null(plot_filename)) {
    if (!dir.exists(plot_save_path)) {
      message(paste("Creating directory:", plot_save_path))
      dir.create(plot_save_path, recursive = TRUE)
    }
    full_plot_path <- file.path(plot_save_path, plot_filename)
    ggplot2::ggsave(
      filename = full_plot_path, plot = p,
      width = plot_width, height = plot_height, units = plot_units, dpi = 300
    )
    message(paste("Plot saved to:", full_plot_path))
  }

  # --- 11. Return Results ---
  return(invisible(list(
    results = results_df,
    plot = p
  )))
}



#' @title Analyze and Plot Feature Value Sensitivity for a Keras Model
#'
#' @description Performs two types of sensitivity analysis for a trained Keras
#'   model to explore its response to variations in its most important input
#'   features. It generates and saves two plots: a "range-response" plot and an
#'   "error effect" (percentage change) plot.
#'
#' @details This function is a core component of the sensitivity analysis
#'   framework.
#'   1.  **Range-Response Analysis:** Varies each top feature across its full
#'       observed range (min to max) in the test data, while holding other
#'       features at their baseline (mean) values. It plots the direct model
#'       predictions for each target variable, showing the learned functional
#'       relationship. The x-axis is normalized to [0,1] for comparability.
#'   2.  **Error Effect Analysis:** Varies each top numeric feature by fixed
#'       percentages (e.g., +/- 10%, +/- 20%) from its mean value. It plots the
#'       resulting percentage change in the model's predictions, simulating the
#'       impact of measurement errors or small shifts in input data.
#'
#' @section Handling Custom Loss Functions:
#'   # NEW: Added section for clarity
#'   If the Keras model was trained with a custom loss function, this function
#'   can load it correctly, provided the loss function follows the structure of
#'   a weighted sum of KL divergence and Mean Absolute Error. To enable this,
#'   the `custom_loss_alpha` parameter must be provided with the same alpha
#'   value that was used during training.
#'
#' @section Python Backend Setup:
#' This function requires a working Python environment with TensorFlow installed.
#' It is designed to work with either the `keras` or `keras3` R package.
#'
#' @param model_path A string specifying the full path to the saved Keras model
#'   in the `.keras` directory format.
#' @param model_data_path A string specifying the full path to the `.RData` file
#'   containing the data object.
#' @param model_data_name A string specifying the name of the R object within the
#'   `.RData` file. This object must contain `test_data`, `input_features`, and `target_features`.
#' @param custom_loss_alpha # NEW: An optional numeric value. If the model was trained with the custom
#'   combined KLD+MAE loss, provide the alpha weight used during training here.
#'   Defaults to `NULL`, assuming a standard loss function.
#' @param importance_results A data frame with a 'Feature' column, typically the
#'   output from `permutation_feature_importance()`, used to select top features.
#' @param top_n_features An integer specifying the number of top features from
#'   `importance_results` to analyze. Defaults to 5.
#' @param target_features An optional character vector of target feature names.
#'   If `NULL` (the default), the function retrieves them from `loaded_data_object$target_features`.
#' @param features_to_exclude An optional character vector of target features to
#'   exclude from the analysis and plots. Defaults to `NULL`.
#' @param target_labels An optional named character vector to provide user-friendly
#'   labels for target variables in plots. The names must correspond to the raw
#'   target feature names (e.g., `c("stems.ha_dbhclass10" = "DBH: (8, 11.5] cm")`).
#'   If `NULL`, raw feature names are used. Defaults to `NULL`.
#' @param n_steps_per_feature An integer specifying the number of steps for the
#'   range-response analysis. Defaults to 20.
#' @param percent_changes A numeric vector of relative changes for the error
#'   effect analysis (e.g., c(-0.2, -0.1, 0.1, 0.2)). Defaults to `c(-0.20, -0.10, 0.10, 0.20)`.
#' @param plot_filename_base An optional string used as the base for output plot
#'   filenames. Suffixes ("_range_response.pdf", "_error_effect.pdf") are appended.
#'   If `NULL`, plots are not saved to disk. Defaults to `NULL`.
#' @param plot_save_path A string for the directory path where plots will be saved.
#'   Required if `plot_filename_base` is not `NULL`.
#' @param line_color_palette A string specifying the color palette. Can be a
#'   `viridis` option, an `RColorBrewer` palette, a single color, or a vector
#'   of hex codes. Defaults to "turbo".
#' @param plot_width The width of the saved plots. Defaults to 17.
#' @param plot_height The height of the saved plots. Defaults to 20.
#' @param plot_units A string specifying the units for plot dimensions ("cm", "in").
#'   Defaults to "cm".
#' @param seed An optional integer to set the random seed. Defaults to `NULL`.
#'
#' @return An invisible list containing:
#'   \item{range_sensitivity_data}{Data frame from the range-response analysis.}
#'   \item{percent_change_data}{Data frame from the error effect analysis.}
#'   \item{range_plot}{The ggplot object for the range-response plot.}
#'   \item{percent_change_plot}{The ggplot object for the error effect plot.}
#'
#' @importFrom dplyr select all_of bind_rows mutate case_when mutate_all
#' @importFrom magrittr %>%
#' @importFrom tidyr pivot_longer
#' @importFrom ggplot2 ggplot aes geom_line geom_point facet_wrap labs theme_classic theme element_text rel margin guide_legend scale_shape_manual scale_x_continuous guides geom_bar position_dodge element_rect element_line element_blank unit ggsave scale_fill_manual scale_color_manual
#' @importFrom stats setNames predict
#' @importFrom viridis scale_fill_viridis scale_color_viridis
#' @importFrom RColorBrewer brewer.pal brewer.pal.info
#' @importFrom rlang .data
#' @importFrom utils head
#'
#' @examples
#' \dontrun{
#' # Assume pfi_results is available from permutation_feature_importance()
#' # pfi_results <- permutation_feature_importance(...)
#'
#' # Path to the example Keras model
#' model_path <- system.file("extdata", "deepReveal_example_model.keras", package = "deepReveal")
#'
#' # Create a temporary data file path
#' data("deepReveal_example_data")
#' temp_data_path <- file.path(tempdir(), "model_data.RData")
#' save(deepReveal_example_data, file = temp_data_path)
#'
#' # Define custom labels for a more readable plot legend
#' custom_labels <- c("stems.ha_dbhclass10" = "DBH: (8, 11.5] cm",
#'                    "stems.ha_dbhclass27" = "DBH: (25, 30] cm",
#'                    "stems.ha_dbhclass42" = "DBH: (40, 45] cm")
#'
#' sensitivity_output <- feature_value_sensitivity(
#'   model_path = model_path,
#'   model_data_name = "deepReveal_example_data",
#'   model_data_path = temp_data_path,
#'   custom_loss_alpha = 0.1, # Example for a model with a custom loss
#'   importance_results = pfi_results,
#'   top_n_features = 4,
#'   target_labels = custom_labels,
#'   features_to_exclude = "stems.ha_dbhclass4",
#'   plot_filename_base = "feature_sensitivity_example",
#'   plot_save_path = tempdir(),
#'   seed = 123
#' )
#'
#' # The plot objects are returned and can be displayed
#' print(sensitivity_output$range_plot)
#' print(sensitivity_output$percent_change_plot)
#' }
#' @export
feature_value_sensitivity <- function(model_path,
                                      model_data_path,
                                      model_data_name,
                                      custom_loss_alpha = NULL, # MODIFIED: Added parameter
                                      importance_results,
                                      top_n_features = 5,
                                      target_features = NULL,
                                      features_to_exclude = NULL,
                                      target_labels = NULL,
                                      n_steps_per_feature = 20,
                                      percent_changes = c(-0.20, -0.10, 0.10, 0.20),
                                      plot_filename_base = NULL,
                                      plot_save_path = NULL,
                                      line_color_palette = "turbo",
                                      plot_width = 17,
                                      plot_height = 20,
                                      plot_units = "cm",
                                      seed = NULL) {

  # --- 0. Argument validation and Setup ---
  if (!is.data.frame(importance_results) || !"Feature" %in% colnames(importance_results)) stop("`importance_results` must be a data frame with a 'Feature' column.")
  if (!is.null(plot_filename_base) && is.null(plot_save_path)) stop("`plot_save_path` must be provided when `plot_filename_base` is specified.")
  pkg_needed <- c("ggplot2", "dplyr", "tidyr", "stringr")
  for (pkg in pkg_needed) if (!requireNamespace(pkg, quietly = TRUE)) stop(paste("Package '", pkg, "' is needed."), call. = FALSE)
  if (!is.null(seed)) set.seed(seed)

  # --- 1. Load Model (CMD Check Safe) ---
  message(paste("Loading model from:", model_path))
  if (!file.exists(model_path)) stop(paste("Model file not found at:", model_path))

  model <- NULL

  load_model_func <- NULL
  if (requireNamespace("keras3", quietly = TRUE)) {
    message("Using 'keras3' package to load model.")
    load_model_func <- get("load_model", asNamespace("keras3"))
    loss_kl_divergence <- get("loss_kl_divergence", asNamespace("keras3"))
    loss_mean_absolute_error <- get("loss_mean_absolute_error", asNamespace("keras3"))
  } else if (requireNamespace("keras", quietly = TRUE)) {
    message("Using 'keras' package as a fallback to load model.")
    load_model_func <- get("load_model", asNamespace("keras"))
    loss_kl_divergence <- get("loss_kullback_leibler_divergence", asNamespace("keras"))
    loss_mean_absolute_error <- get("loss_mean_absolute_error", asNamespace("keras"))
  } else {
    stop("Neither 'keras3' nor 'keras' package is available to load the model.")
  }

  tryCatch({
    if (!is.null(custom_loss_alpha)) {
      message("Defining custom loss function for model loading...")
      loss_combined_kld_mae <- function(y_true, y_pred) {
        kld_loss <- loss_kl_divergence(y_true, y_pred)
        mae_loss <- loss_mean_absolute_error(y_true, y_pred)
        (custom_loss_alpha * kld_loss) + ((1 - custom_loss_alpha) * mae_loss)
      }
      model <- load_model_func(
        model_path,
        custom_objects = c("custom_loss" = loss_combined_kld_mae)
      )
    } else {
      model <- load_model_func(model_path)
    }
    message("Model loaded successfully.")
  }, error = function(e) {
    stop(paste("Failed to load model. Error:", e$message))
  })
  if (is.null(model)) stop("Model could not be loaded.")


  # --- 2. Load and Prepare Data ---
  message(paste("Loading data from:", model_data_path))
  data_env <- new.env(); load(model_data_path, envir = data_env)
  loaded_data_object <- data_env[[model_data_name]]
  test_data_df <- loaded_data_object$test_data
  actual_input_features <- loaded_data_object$input_features
  if(is.null(actual_input_features)) stop("`input_features` not found in the loaded data object.")

  # --- 3. Determine and Filter Target Features ---
  all_target_features <- target_features
  if (is.null(all_target_features)) {
    all_target_features <- loaded_data_object$target_features
    if(is.null(all_target_features)) stop("`target_features` not provided and not found in the loaded data object.")
  }

  if (!is.null(features_to_exclude)) {
    original_count <- length(all_target_features)
    all_target_features <- all_target_features[!all_target_features %in% features_to_exclude]
    message(paste("Excluded", original_count - length(all_target_features), "features based on `features_to_exclude`."))
  }
  if (length(all_target_features) == 0) stop("No target features remaining to analyze.")


  # --- 4. Select Top N Features for Analysis ---
  features_to_analyze <- head(importance_results$Feature, top_n_features)
  message(paste("Selected top", length(features_to_analyze), "features:", paste(features_to_analyze, collapse=", ")))

  # --- 5. Baseline Instance and Predictions ---
  baseline_instance_list <- sapply(test_data_df[, actual_input_features, drop=FALSE], function(col) if(is.numeric(col)) mean(col, na.rm=TRUE) else col[1], simplify=FALSE)
  baseline_instance_df <- as.data.frame(baseline_instance_list)[, actual_input_features, drop=FALSE]
  baseline_predictions_matrix <- stats::predict(model, as.matrix(baseline_instance_df))
  colnames(baseline_predictions_matrix) <- loaded_data_object$target_features
  baseline_predictions_df <- as.data.frame(baseline_predictions_matrix)[, all_target_features, drop=FALSE]

  # --- 6. Perform Range-Based Sensitivity Analysis ---
  message("Starting range-based sensitivity analysis...")
  all_range_data_list <- list()
  for (feature in features_to_analyze) {
    if (!is.numeric(test_data_df[[feature]])) {
      warning(paste("Feature '", feature,"' not numeric. Skipping range sensitivity.")); next
    }
    min_val <- min(test_data_df[[feature]], na.rm=TRUE); max_val <- max(test_data_df[[feature]], na.rm=TRUE)
    val_seq <- seq(min_val, max_val, length.out=n_steps_per_feature)
    temp_data <- lapply(val_seq, function(v) {
      instance <- baseline_instance_df; instance[[feature]] <- v
      preds_matrix <- stats::predict(model, as.matrix(instance))
      colnames(preds_matrix) <- loaded_data_object$target_features
      preds_df <- as.data.frame(preds_matrix)[, all_target_features, drop=FALSE]
      preds_df$Varied_Feature <- feature
      preds_df$Varied_Feature_Value <- v
      preds_df$Varied_Feature_Value_Normalized <- if(max_val == min_val) 0.5 else (v - min_val) / (max_val - min_val)
      return(preds_df)
    })
    all_range_data_list[[feature]] <- dplyr::bind_rows(temp_data)
  }
  final_range_df <- dplyr::bind_rows(all_range_data_list)

  # --- 7. Perform Percentage-Change Sensitivity Analysis ---
  message("Starting percentage-change sensitivity analysis...")
  all_percent_change_list <- list()
  for (feature in features_to_analyze) {
    if (!is.numeric(test_data_df[[feature]])) {
      warning(paste("Feature '", feature,"' not numeric. Skipping % change sensitivity.")); next
    }
    mean_val <- baseline_instance_df[[feature]]
    temp_data <- lapply(percent_changes, function(pc) {
      instance <- baseline_instance_df; instance[[feature]] <- mean_val * (1 + pc)
      preds_matrix <- stats::predict(model, as.matrix(instance))
      colnames(preds_matrix) <- loaded_data_object$target_features
      preds_df <- as.data.frame(preds_matrix)[, all_target_features, drop=FALSE]
      baseline_no_zero <- dplyr::mutate_all(baseline_predictions_df, ~ifelse(abs(.) < 1e-9, NA_real_, .))
      percent_change_preds <- (preds_df - baseline_predictions_df) / baseline_no_zero * 100
      percent_change_preds$Varied_Feature <- feature
      percent_change_preds$Percent_Change_Input <- pc * 100
      return(percent_change_preds)
    })
    all_percent_change_list[[feature]] <- dplyr::bind_rows(temp_data)
  }
  final_percent_change_df <- dplyr::bind_rows(all_percent_change_list)

  # --- 8. Prepare Plotting Labels ---
  if (!is.null(target_labels) && is.character(target_labels) && !is.null(names(target_labels))) {
    plot_labels <- target_labels[names(target_labels) %in% all_target_features]
  } else {
    plot_labels <- stats::setNames(all_target_features, all_target_features)
  }
  sorted_plot_labels <- plot_labels[order(names(plot_labels))]

  # --- 9. Plotting Helpers ---
  apply_color_scale_to_plot <- function(p, num_colors, palette, is_fill = FALSE) {
    scale_func <- if (is_fill) ggplot2::scale_fill_manual else ggplot2::scale_color_manual
    viridis_func <- if (is_fill) viridis::scale_fill_viridis else viridis::scale_color_viridis

    if (palette %in% c("viridis", "plasma", "turbo", "magma", "inferno", "cividis")) {
      p <- p + viridis_func(discrete = TRUE, option = palette, name = "Target Variable", labels = sorted_plot_labels)
    } else if (suppressWarnings(palette %in% rownames(RColorBrewer::brewer.pal.info))) {
      colors <- RColorBrewer::brewer.pal(n = num_colors, name = palette)
      p <- p + scale_func(values = colors, name = "Target Variable", labels = sorted_plot_labels)
    } else { # Assume it's a hex code or single color name
      p <- p + scale_func(values = rep(palette, num_colors), name = "Target Variable", labels = sorted_plot_labels)
    }
    return(p)
  }

  # --- 10. Generate Plots ---
  # Range-Response Plot
  range_plot_data <- final_range_df %>%
    tidyr::pivot_longer(cols = all_of(all_target_features), names_to = "Target_Variable", values_to = "Predicted_Value") %>%
    dplyr::mutate(
      Target_Variable_Formatted = factor(.data$Target_Variable, levels = names(sorted_plot_labels), labels = sorted_plot_labels),
      Varied_Feature = factor(.data$Varied_Feature, levels = features_to_analyze)
    )

  num_targets <- length(sorted_plot_labels)
  shape_vals <- rep(c(16,17,15,3,7,8,18,1:2,4:6), length.out = num_targets)

  range_plot <- ggplot2::ggplot(range_plot_data, ggplot2::aes(x=.data$Varied_Feature_Value_Normalized, y=.data$Predicted_Value, group=.data$Target_Variable_Formatted, color=.data$Target_Variable_Formatted, shape=.data$Target_Variable_Formatted)) +
    ggplot2::geom_line(linewidth=0.5) + ggplot2::geom_point(size=2, alpha=0.8) +
    ggplot2::facet_wrap(~.data$Varied_Feature, scales="free_y") +
    ggplot2::labs(x="Normalized Feature Value (0 = Min, 1 = Max)", y="Predicted Target Value", color="Target Variable", shape="Target Variable") +
    ggplot2::theme_classic(base_size=10) +
    ggplot2::theme(legend.position="bottom") +
    ggplot2::scale_shape_manual(values=shape_vals, name="Target Variable", labels = sorted_plot_labels)
  range_plot <- apply_color_scale_to_plot(range_plot, num_targets, line_color_palette, is_fill = FALSE)

  # Percent-Change Plot
  percent_plot_data <- final_percent_change_df %>%
    tidyr::pivot_longer(cols = all_of(all_target_features), names_to = "Target_Variable", values_to = "Percent_Change_Prediction") %>%
    dplyr::mutate(
      Target_Variable_Formatted = factor(.data$Target_Variable, levels = names(sorted_plot_labels), labels = sorted_plot_labels),
      Varied_Feature = factor(.data$Varied_Feature, levels = features_to_analyze),
      Percent_Change_Input_Factor = factor(paste0(.data$Percent_Change_Input, "%"), levels = paste0(sort(unique(.data$Percent_Change_Input)), "%"))
    )

  percent_change_plot <- ggplot2::ggplot(percent_plot_data, ggplot2::aes(x=.data$Target_Variable_Formatted, y=.data$Percent_Change_Prediction, fill=.data$Percent_Change_Input_Factor)) +
    ggplot2::geom_bar(stat="identity", position=ggplot2::position_dodge(width=0.9)) +
    ggplot2::facet_wrap(~.data$Varied_Feature, scales="free_y") +
    ggplot2::labs(x="Target Variable", y="% Change in Prediction", fill="Input Change") +
    ggplot2::theme_classic(base_size=10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1), legend.position = "bottom")

  # --- 11. Save plots if requested ---
  if(!is.null(plot_filename_base)) {
    if (!dir.exists(plot_save_path)) {
      message(paste("Creating directory:", plot_save_path))
      dir.create(plot_save_path, recursive = TRUE)
    }
    full_range_path <- file.path(plot_save_path, paste0(plot_filename_base, "_range_response.pdf"))
    ggplot2::ggsave(full_range_path, range_plot, width = plot_width, height = plot_height, units = plot_units)
    message(paste("Range sensitivity plot saved to:", full_range_path))

    full_percent_path <- file.path(plot_save_path, paste0(plot_filename_base, "_error_effect.pdf"))
    ggplot2::ggsave(full_percent_path, percent_change_plot, width = plot_width, height = plot_height, units = plot_units)
    message(paste("Percent change plot saved to:", full_percent_path))
  }

  # --- 12. Return Results ---
  return(invisible(list(
    range_sensitivity_data = final_range_df,
    percent_change_data = final_percent_change_df,
    range_plot = range_plot,
    percent_change_plot = percent_change_plot
  )))
}


#' @title Run and Evaluate Neural Network Training for Multiple Feature Sets
#'
#' @description This function serves as a sensitivity analysis tool to evaluate
#'   model performance across different subsets of input features. It iterates
#'   through a provided list of feature sets, retrains a neural network for
#'   each, and saves the results.
#'
#' @details The function systematically trains a new model for each feature set
#'   using a consistent neural network architecture and hyperparameters, as
#'   defined in the `nn_config`. It extracts key performance indicators like the
#'   minimum validation loss and saves predictions for later analysis. Optionally,
#'   the fully trained Keras model for each feature set can be saved to disk.
#'
#' @section Python Backend Setup:
#'   This function orchestrates the training of Keras models and therefore
#'   requires a working Python environment with TensorFlow installed. It is
#'   designed to work with either the `keras` or `keras3` R package.
#'
#' @param model_data_path A string specifying the full path to the main `.RData`
#'   file.
#' @param model_data_name A string specifying the name of the R object within the
#'   `.RData` file (e.g., "model_data"). This object must contain `train_data`,
#'   `val_data`, `test_data`, `input_features`, and `target_features`.
#' @param feature_sets_list A named list where each element is a character vector
#'   representing a subset of input feature names to be used for training.
#' @param nn_config # MODIFIED: A list of parameters to be passed to the
#'   `compile_fit_predict_nn_func`. This list must contain either an `architecture`
#'   string (e.g., "manuscript_model_v3") OR a `build_model_func` function. It
#'   should also include `build_params`, `fit_params`, `loss`, etc.
#' @param compile_fit_predict_nn_func The user-provided function that handles the
#'   entire NN training and prediction workflow, typically `deepReveal::compile_fit_predict_nn`.
#' @param stand_id_col A string specifying the name of the column in the data
#'   splits that contains the unique stand identifier. Defaults to "inventory_id".
#' @param base_model_name_prefix A string prefix used for internal model naming
#'   and for the filenames of saved models. Defaults to "fs_sensitivity_model_".
#' @param output_rdata_path A string specifying the full path where the main
#'   results list will be saved as an `.RData` file.
#' @param save_trained_models_path An optional string specifying a directory path.
#'   If provided, the trained Keras model for each feature set will be saved in
#'   `.keras` format in this directory. Defaults to `NULL`.
#' @param feature_set_model_data_save_path An optional string specifying a
#'   directory path. If provided, an `.RData` file containing the specific data
#'   configuration for each feature set will be saved here. Defaults to `NULL`.
#'
#' @return The path to the saved `output_rdata_path` file, invisibly.
#'
#' @examples
#' \dontrun{
#' # This is a conceptual example of the full workflow.
#' # Assumes deepReveal_example_data is loaded and saved to a temp file.
#' temp_data_path <- file.path(tempdir(), "model_data_for_fs_sens.RData")
#'
#' # 1. Define feature sets to test (e.g., from PFI results)
#' feature_sets <- list(
#'   Top2 = c("stem_number.ha", "basal_area.m2.ha"),
#'   Top4 = c("stem_number.ha", "basal_area.m2.ha", "hmax.m", "conifer_share.prct")
#' )
#'
#' # 2. Define the neural network configuration using the built-in model
#' nn_configuration <- list(
#'   architecture = "manuscript_model_v3",
#'   build_params = list(lambda1 = 1e-5, lambda2 = 1e-5, activation = "relu"),
#'   fit_params = list(epochs = 50, batch_size = 2),
#'   loss = "kl_divergence",
#'   seed = 42
#' )
#'
#' # 3. Run the feature set sensitivity training
#' run_feature_set_sensitivity_training(
#'   model_data_name = "deepReveal_example_data",
#'   model_data_path = temp_data_path,
#'   feature_sets_list = feature_sets,
#'   nn_config = nn_configuration,
#'   output_rdata_path = file.path(tempdir(), "fs_sensitivity_results.RData"),
#'   save_trained_models_path = file.path(tempdir(), "fs_models"),
#'   compile_fit_predict_nn_func = deepReveal::compile_fit_predict_nn
#' )
#' }
#' @export
run_feature_set_sensitivity_training <- function(model_data_path,
                                                 model_data_name,
                                                 feature_sets_list,
                                                 nn_config,
                                                 compile_fit_predict_nn_func,
                                                 stand_id_col = "inventory_id",
                                                 base_model_name_prefix = "fs_sensitivity_model_",
                                                 output_rdata_path,
                                                 save_trained_models_path = NULL,
                                                 feature_set_model_data_save_path = NULL) {

  # --- 0. Argument Validation ---
  if (!is.list(feature_sets_list) || is.null(names(feature_sets_list))) stop("`feature_sets_list` must be a named list.")
  if (!is.function(compile_fit_predict_nn_func)) stop("`compile_fit_predict_nn_func` must be a function.")

  if (!dir.exists(dirname(output_rdata_path))) {
    dir.create(dirname(output_rdata_path), recursive = TRUE)
  }
  if (!is.null(save_trained_models_path) && !dir.exists(save_trained_models_path)) {
    dir.create(save_trained_models_path, recursive = TRUE)
  }
  if (!is.null(feature_set_model_data_save_path) && !dir.exists(feature_set_model_data_save_path)) {
    dir.create(feature_set_model_data_save_path, recursive = TRUE)
  }

  # --- 1. Load Main Data Object ---
  message(paste("Loading main data from:", model_data_path))
  data_env <- new.env(); load(model_data_path, envir = data_env)
  main_model_data <- data_env[[model_data_name]]

  for(split_name in c("train_data", "val_data", "test_data")){
    if(is.null(main_model_data[[split_name]])) stop(paste("`main_model_data` missing", split_name))
    if (!stand_id_col %in% colnames(main_model_data[[split_name]])) {
      stop(paste0("`main_model_data$", split_name, "` must contain the stand ID column: '", stand_id_col, "'"))
    }
  }

  # --- 2. Loop Through Feature Sets ---
  all_results_list <- list()

  for (set_name in names(feature_sets_list)) {
    current_input_features <- feature_sets_list[[set_name]]
    message(paste("\nProcessing feature set:", set_name))

    cols_for_nn <- c(current_input_features, main_model_data$target_features)
    current_train_df <- main_model_data$train_data[, cols_for_nn, drop = FALSE]
    current_val_df <- main_model_data$val_data[, cols_for_nn, drop = FALSE]
    current_test_df <- main_model_data$test_data[, cols_for_nn, drop = FALSE]

    nn_args <- c(
      list(
        train_data = current_train_df, validation_data = current_val_df,
        test_data = current_test_df, input_features = current_input_features,
        target_features = main_model_data$target_features
      ),
      nn_config
    )

    nn_output <- tryCatch({
      do.call(compile_fit_predict_nn_func, nn_args)
    }, error = function(e) {
      warning(paste("Error training NN for set '", set_name, "': ", e$message), call. = FALSE)
      return(NULL)
    })

    if (is.null(nn_output)) next

    # --- 3. Process and Store Results ---
    true_values_df <- as.data.frame(main_model_data$test_data[, main_model_data$target_features, drop = FALSE])
    inventory_ids_for_set <- main_model_data$test_data[[stand_id_col]]
    predicted_values_df <- nn_output$predictions

    min_val_loss <- NA_real_
    if (!is.null(nn_output$history$metrics$val_loss)) {
      min_val_loss <- min(nn_output$history$metrics$val_loss, na.rm = TRUE)
    }

    if (!is.null(save_trained_models_path) && !is.null(nn_output$model)) {
      sane_set_name <- gsub("[^A-Za-z0-9_.-]", "_", set_name)
      model_filename <- paste0(base_model_name_prefix, sane_set_name, "_model.keras")
      model_save_path <- file.path(save_trained_models_path, model_filename)

      save_model_func <- NULL
      if (requireNamespace("keras3", quietly = TRUE)) {
        save_model_func <- get("save_model", asNamespace("keras3"))
      } else if (requireNamespace("keras", quietly = TRUE)) {
        save_model_func <- get("save_model", asNamespace("keras"))
      }

      if(!is.null(save_model_func)){
        tryCatch({
          save_model_func(nn_output$model, filepath = model_save_path)
          message(paste("Saved trained model for set '", set_name, "' to: ", model_save_path))
        }, error = function(e){
          warning(paste("Failed to save model: ", e$message), call. = FALSE)
        })
      } else {
        warning("Could not save model: neither 'keras3' nor 'keras' is available.", call. = FALSE)
      }
    }

    all_results_list[[set_name]] <- list(
      feature_set_name = set_name, inventory_ids = inventory_ids_for_set,
      true_values = true_values_df, predicted_values = predicted_values_df,
      input_features_used = current_input_features,
      min_val_loss = min_val_loss
    )
    message(paste("Completed processing for feature set:", set_name))
  }

  # --- 4. Save Aggregated Results ---
  message(paste("\nSaving all feature set sensitivity training results to:", output_rdata_path))
  save(all_results_list, file = output_rdata_path)

  return(invisible(output_rdata_path))
}


#' @title Plot a Heatmap of Minimum Validation Loss Across Feature Sets
#'
#' @description This function loads the results from
#'   `run_feature_set_sensitivity_training` and generates a heatmap to visualize
#'   the minimum validation loss (`min_val_loss`) achieved by models trained
#'   with different feature sets.
#'
#' @details The heatmap organizes feature sets (columns) from best-performing
#'   (lowest average validation loss) to worst-performing. The input features
#'   (rows) are ordered by their global importance. Each colored tile indicates
#'   that a feature was part of a given set, with the color intensity representing
#'   the validation loss. The function can also annotate the `min_val_loss` value
#'   for each feature set's column.
#'
#' @param sensitivity_results_rdata_path A string specifying the full path to the
#'   `.RData` file created by `run_feature_set_sensitivity_training`.
#' @param importance_results A data frame with 'Feature' and 'Importance' columns,
#'   used to order the features on the y-axis of the heatmap.
#' @param plot_filename An optional string for the desired filename of the output
#'   plot. If `NULL`, the plot is not saved to disk. Defaults to `NULL`.
#' @param plot_save_path A string for the directory path where the plot will be
#'   saved. Required if `plot_filename` is provided.
#' @param heatmap_color_palette A string specifying the color palette for the
#'   heatmap fill. See `ggplot2` documentation for options. Defaults to "turbo".
#' @param plot_title An optional main title for the plot. Defaults to `NULL`.
#' @param x_axis_label A string for the x-axis title. Defaults to a descriptive
#'   label about feature set ordering.
#' @param y_axis_label A string for the y-axis title. Defaults to a descriptive
#'   label about feature importance ordering.
#' @param legend_title A string for the legend title. Defaults to "Min. Validation Loss".
#' @param show_annotation A logical value indicating whether to display the
#'   minimum validation loss value as text on the heatmap. Defaults to `TRUE`.
#' @param plot_width The width of the saved plot. Defaults to 17.
#' @param plot_height The height of the saved plot. If `NULL` (default), the height
#'   is calculated automatically based on the number of features.
#' @param plot_units A string specifying the units for plot dimensions ("cm", "in").
#'   Defaults to "cm".
#'
#' @return An invisible list containing:
#'   \item{plot_data}{The data frame used for plotting.}
#'   \item{plot}{The ggplot object for the heatmap, which can be further customized.}
#'
#' @importFrom dplyr %>% bind_rows group_by summarise arrange desc pull filter mutate first
#' @importFrom ggplot2 ggplot aes geom_tile geom_text labs theme_minimal theme element_blank element_text rel element_rect margin scale_fill_gradient2 scale_fill_gradient guide_colorbar scale_fill_distiller ggsave
#' @importFrom viridis scale_fill_viridis
#' @importFrom RColorBrewer brewer.pal.info
#' @importFrom rlang .data
#'
#' @export
plot_feature_set_val_loss_heatmap <- function(sensitivity_results_rdata_path,
                                              importance_results,
                                              plot_filename = NULL,
                                              plot_save_path = NULL,
                                              heatmap_color_palette = "turbo",
                                              plot_title = NULL,
                                              x_axis_label = "Feature Set (Ordered by Avg. Min Validation Loss)",
                                              y_axis_label = "Input Feature (Ordered by Permutation Importance)",
                                              legend_title = "Min. Validation Loss",
                                              show_annotation = TRUE,
                                              plot_width = 17,
                                              plot_height = NULL,
                                              plot_units = "cm") {

  # --- 0. Argument Validation ---
  if (!file.exists(sensitivity_results_rdata_path)) stop("Sensitivity results file not found.")
  if (!is.data.frame(importance_results) || !all(c("Feature", "Importance") %in% colnames(importance_results))) stop("`importance_results` must have 'Feature' and 'Importance' columns.")
  if (!is.null(plot_filename) && is.null(plot_save_path)) stop("`plot_save_path` must be provided with `plot_filename`.")

  # --- 1. Load Sensitivity Results ---
  message(paste("Loading sensitivity results from:", sensitivity_results_rdata_path))
  load_env <- new.env(); load(sensitivity_results_rdata_path, envir = load_env)
  all_results_list <- load_env$all_results_list

  # --- 2. Prepare Data for Heatmap ---
  plot_data_list <- lapply(names(all_results_list), function(set_name) {
    res <- all_results_list[[set_name]]
    if(is.null(res$input_features_used)) return(NULL)
    data.frame(Feature_Set=set_name, Input_Feature=res$input_features_used, Min_Val_Loss=res$min_val_loss)
  })
  plot_data <- dplyr::bind_rows(plot_data_list)
  plot_data <- plot_data[!is.na(plot_data$Min_Val_Loss), ]

  avg_loss_per_set <- plot_data %>%
    dplyr::group_by(.data$Feature_Set) %>%
    dplyr::summarise(Avg_Min_Val_Loss = mean(.data$Min_Val_Loss, na.rm = TRUE)) %>%
    dplyr::arrange(.data$Avg_Min_Val_Loss)
  plot_data$Feature_Set <- factor(plot_data$Feature_Set, levels = avg_loss_per_set$Feature_Set)

  ordered_features <- importance_results %>% dplyr::arrange(dplyr::desc(.data$Importance)) %>% dplyr::pull(.data$Feature)
  plot_data$Input_Feature <- factor(plot_data$Input_Feature, levels = rev(ordered_features))

  # --- 3. Generate Heatmap ---
  message("Generating validation loss heatmap...")
  heatmap_plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$Feature_Set, y = .data$Input_Feature, fill = .data$Min_Val_Loss)) +
    ggplot2::geom_tile(color = "grey50", linewidth = 0.25) +
    ggplot2::labs(
      title = plot_title, x = x_axis_label, y = y_axis_label, fill = legend_title
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 60, hjust = 1),
      axis.title = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )

  if (show_annotation) {
    annotation_data <- plot_data %>%
      dplyr::group_by(.data$Feature_Set) %>%
      dplyr::summarise(
        Min_Loss_To_Display = dplyr::first(.data$Min_Val_Loss),
        Annotation_Label = sprintf("%.3f", .data$Min_Loss_To_Display)
      ) %>%
      dplyr::mutate(Input_Feature_For_Annotation = factor(rev(levels(plot_data$Input_Feature))[1], levels = levels(plot_data$Input_Feature)))

    heatmap_plot <- heatmap_plot +
      ggplot2::geom_text(data = annotation_data,
                         aes(x = .data$Feature_Set, # <-- THIS LINE WAS ADDED
                             label = .data$Annotation_Label,
                             y = .data$Input_Feature_For_Annotation),
                         color = "white", size = 2.2, inherit.aes = FALSE)
  }

  current_limits <- range(plot_data$Min_Val_Loss, na.rm = TRUE)
  palette_name_lower <- tolower(heatmap_color_palette)

  if (palette_name_lower %in% c("viridis", "plasma", "turbo", "magma", "inferno", "cividis")) {
    heatmap_plot <- heatmap_plot + viridis::scale_fill_viridis(
      option = palette_name_lower, name = legend_title, limits = current_limits,
      guide = ggplot2::guide_colorbar(direction = "horizontal", title.position = "top")
    )
  } else if (suppressWarnings(palette_name_lower %in% tolower(rownames(RColorBrewer::brewer.pal.info)))) {
    palette_info <- RColorBrewer::brewer.pal.info[tolower(rownames(RColorBrewer::brewer.pal.info)) == palette_name_lower, ]
    direction <- if(palette_info$category == "seq") 1 else -1
    heatmap_plot <- heatmap_plot + ggplot2::scale_fill_distiller(
      palette = heatmap_color_palette, direction = direction, name = legend_title,
      limits = current_limits,
      guide = ggplot2::guide_colorbar(direction = "horizontal", title.position = "top")
    )
  } else if (is.character(heatmap_color_palette) && length(heatmap_color_palette) %in% c(2,3)) {
    if(length(heatmap_color_palette) == 2){
      heatmap_plot <- heatmap_plot + ggplot2::scale_fill_gradient(
        low = heatmap_color_palette[1], high = heatmap_color_palette[2], name = legend_title,
        limits = current_limits, guide = ggplot2::guide_colorbar(direction = "horizontal", title.position = "top")
      )
    } else {
      heatmap_plot <- heatmap_plot + ggplot2::scale_fill_gradient2(
        low = heatmap_color_palette[1], mid = heatmap_color_palette[2], high = heatmap_color_palette[3],
        midpoint = median(plot_data$Min_Val_Loss, na.rm = TRUE), name = legend_title,
        limits = current_limits, guide = ggplot2::guide_colorbar(direction = "horizontal", title.position = "top")
      )
    }
  } else {
    warning(paste("Palette '", heatmap_color_palette, "' not recognized. Using ggplot default."))
  }

  # --- 4. Save Plot ---
  if (!is.null(plot_filename)) {
    if (is.null(plot_height)) {
      num_y <- length(levels(plot_data$Input_Feature))
      plot_height <- max(8, 5 + num_y * 0.45)
    }
    if (!dir.exists(plot_save_path)) dir.create(plot_save_path, recursive = TRUE)
    full_plot_path <- file.path(plot_save_path, plot_filename)
    ggplot2::ggsave(filename = full_plot_path, plot = heatmap_plot, width = plot_width, height = plot_height, units = plot_units)
    message(paste("Validation loss heatmap saved to:", full_plot_path))
  }

  return(invisible(list(plot_data = plot_data, plot = heatmap_plot)))
}



#' @title Generate Detailed Prediction Plots for Each Feature Set
#'
#' @description This function orchestrates the generation of detailed evaluation
#'   plots and statistics for each model trained with a different feature set. It
#'   loads the results from `run_feature_set_sensitivity_training` and then,
#'   for each feature set, calls a user-provided analysis and visualization
#'   function to create detailed outputs.
#'
#' @details This function acts as a batch processor. It loops through the list
#'   of results, prepares the necessary data (e.g., joining predictions with
#'   true values), and then passes this data to the
#'   `analyze_and_visualize_predictions_func` for detailed plotting and statistical
#'   analysis. It creates a separate subdirectory for each feature set.
#'
#' @param sensitivity_results_rdata_path A string specifying the full path to
#'   the `.RData` file produced by `run_feature_set_sensitivity_training`.
#' @param analyze_and_visualize_predictions_func The function that
#'   will perform the detailed analysis and plotting for a single model's
#'   predictions. It is passed as an argument to maintain modularity.
#' @param plot_save_path_base A string specifying the base directory where
#'   subdirectories for each feature set's plots will be created.
#' @param stand_id_col A string specifying the name of the column in the data
#'   that contains the unique stand identifier. Defaults to "inventory_id".
#' @param stemsstand_csv_path An optional string specifying the full path to a
#'   raw stems data file (e.g., "stemsStands.csv"), which can be used by the
#'   `analyze_and_visualize_predictions_func` for creating detailed plots. If
#'   `NULL`, this data is not loaded. Defaults to `NULL`.
#' @param features_to_exclude An optional character vector of target features to
#'   exclude from the analysis and plots. This is passed down to the analysis
#'   function. Defaults to `NULL`.
#' @param num_stands_for_histograms An integer specifying the number of stands to
#'   randomly sample for generating detailed histogram plots. Defaults to 16.
#' @param stand_sampling_seed An optional integer to set the random seed for
#'   reproducible sampling of stands for histogram generation. Defaults to `NULL`.
#' @param plot_options A list of common plotting parameters (e.g., widths, heights)
#'   to be passed down to the `analyze_and_visualize_predictions_func`.
#'
#' @return An invisible list where each element contains the statistics
#'   returned by `analyze_and_visualize_predictions_func` for each
#'   successfully processed feature set.
#'
#' @importFrom dplyr inner_join filter
#' @importFrom readr read_csv
#' @importFrom stringr str_sort
#'
#' @examples
#' \dontrun{
#' # Assume results_rdata_path is available from previous steps and
#' # analyze_and_visualize_predictions_func is a defined function.
#'
#' # Run the plot generation function, specifying a different stand ID column
#' all_stats <- generate_feature_set_prediction_plots(
#'   sensitivity_results_rdata_path = "path/to/fs_sensitivity_results.RData",
#'   analyze_and_visualize_predictions_func = analyze_and_visualize_predictions,
#'   stemsstand_csv_path = "path/to/your/stemsStands_data.csv",
#'   plot_save_path_base = "path/to/save/all_feature_set_plots/",
#'   stand_id_col = "PlotID",
#'   features_to_exclude = "stems.ha_dbhclass_lowest",
#'   num_stands_for_histograms = 12,
#'   stand_sampling_seed = 456
#' )
#' }
#' @export
generate_feature_set_prediction_plots <- function(
    sensitivity_results_rdata_path,
    analyze_and_visualize_predictions_func,
    plot_save_path_base,
    stand_id_col = "inventory_id",
    stemsstand_csv_path = NULL,
    features_to_exclude = NULL,
    num_stands_for_histograms = 16,
    stand_sampling_seed = NULL,
    plot_options = list(
      scatterplot_width = 17, scatterplot_panel_height = 5, ncol_scatter = 3,
      histogram_width = 17, histogram_panel_height = 5, ncol_hist = 4,
      plot_units = "cm"
    )) {

  # --- 0. Argument Validation ---
  if (!file.exists(sensitivity_results_rdata_path)) stop("Sensitivity results file not found.")
  if (!is.function(analyze_and_visualize_predictions_func)) stop("`analyze_and_visualize_predictions_func` must be a function.")
  if (!dir.exists(plot_save_path_base)) {
    dir.create(plot_save_path_base, recursive = TRUE)
  }

  # --- 1. Load Sensitivity Results ---
  message(paste("Loading sensitivity results from:", sensitivity_results_rdata_path))
  load_env <- new.env(); load(sensitivity_results_rdata_path, envir = load_env)
  all_results_list <- load_env$all_results_list

  # --- 2. Load auxiliary stemsstand data if path is provided ---
  test_data_stemsstand_full <- NULL
  if (!is.null(stemsstand_csv_path)) {
    if(file.exists(stemsstand_csv_path)){
      message(paste("Loading stemsstand data from:", stemsstand_csv_path))
      test_data_stemsstand_full <- readr::read_csv(stemsstand_csv_path, show_col_types = FALSE)
      if (!stand_id_col %in% colnames(test_data_stemsstand_full)) {
        stop(paste0("`stemsstand_csv_path` file must contain the stand ID column: '", stand_id_col, "'"))
      }
      test_data_stemsstand_full[[stand_id_col]] <- as.character(test_data_stemsstand_full[[stand_id_col]])
    } else {
      warning("`stemsstand_csv_path` provided but file not found. Skipping.")
    }
  }

  all_set_stats <- list()

  # --- 3. Loop Through Each Feature Set's Results ---
  for (set_name in names(all_results_list)) {
    message(paste("\nGenerating detailed plots for feature set:", set_name))
    result_item <- all_results_list[[set_name]]

    # --- 3a. Prepare `test_data_with_predictions` ---
    current_target_features <- colnames(result_item$true_values)

    true_df_with_id <- result_item$true_values
    true_df_with_id[[stand_id_col]] <- as.character(result_item$inventory_ids)

    pred_df_with_id <- result_item$predicted_values
    pred_df_with_id[[stand_id_col]] <- as.character(result_item$inventory_ids)

    current_test_data_with_predictions <- dplyr::inner_join(
      as.data.frame(true_df_with_id),
      as.data.frame(pred_df_with_id),
      by = stand_id_col
    )

    # --- 3b. Filter test_data.stemsstand for the current set ---
    current_test_data_stemsstand <- NULL
    if (!is.null(test_data_stemsstand_full)) {
      current_test_data_stemsstand <- test_data_stemsstand_full %>%
        dplyr::filter(.data[[stand_id_col]] %in% result_item$inventory_ids)
    }

    # --- 3c. Select stands for histograms ---
    unique_ids_in_set <- unique(as.character(result_item$inventory_ids))
    num_to_sample <- min(num_stands_for_histograms, length(unique_ids_in_set))

    if (!is.null(stand_sampling_seed)) {
      set.seed(stand_sampling_seed)
    }
    current_selected_stands <- if (num_to_sample > 0) sample(unique_ids_in_set, num_to_sample) else character(0)

    # --- 3d. Create subdirectory and define filenames ---
    sane_set_name <- gsub("[^A-Za-z0-9_.-]", "_", set_name)
    current_plot_save_path <- file.path(plot_save_path_base, sane_set_name)
    if (!dir.exists(current_plot_save_path)) dir.create(current_plot_save_path, recursive = TRUE)

    # --- 3e. Call the analysis and visualization function ---
    message(paste("  Calling analysis function for set:", set_name))

    # MODIFIED: The arguments are now assembled correctly, passing plot_options as a single list.
    avp_args <- list(
      test_data_with_predictions = current_test_data_with_predictions,
      test_data_stemsstand = current_test_data_stemsstand,
      target_features = current_target_features,
      features_to_exclude = features_to_exclude,
      selected_stands = current_selected_stands,
      stand_id_col = stand_id_col,
      scatterplot_filename = file.path(current_plot_save_path, paste0("preds_vs_true_", sane_set_name, "_scatter.pdf")),
      histogram_filename = file.path(current_plot_save_path, paste0("preds_vs_true_", sane_set_name, "_selected_hist.pdf")),
      dbhclass_stats_filename = file.path(current_plot_save_path, paste0("stats_", sane_set_name, "_per_dbhclass.csv")),
      stand_stats_filename = file.path(current_plot_save_path, paste0("stats_", sane_set_name, "_per_stand.csv")),
      plot_options = plot_options
    )

    set_stats <- tryCatch({
      do.call(analyze_and_visualize_predictions_func, avp_args)
    }, error = function(e) {
      warning(paste("Error in analyze_and_visualize_predictions_func for set '", set_name, "': ", e$message), call. = FALSE); return(NULL)
    })

    if(!is.null(set_stats)) all_set_stats[[set_name]] <- set_stats
  }

  message("\nDetailed prediction analysis and plotting for all feature sets complete.")
  return(invisible(all_set_stats))
}

#' @title Analyze and Visualize Prediction Results
#'
#' @description Performs a comprehensive analysis of prediction results. It
#'   calculates accuracy metrics (R-squared, RMSE, KL Divergence), generates
#'   and saves publication-quality plots, and produces detailed
#'   statistics files.
#'
#' @details This function is the primary tool for evaluating and visualizing the
#'   outputs from the `compile_fit_predict_nn` function. It takes a data frame
#'   of true and predicted values and produces:
#'   \itemize{
#'     \item A grid of scatterplots comparing true vs. predicted values for each
#'       target variable.
#'     \item A grid of histograms comparing true and predicted distributions for
#'       a user-specified subset of stands.
#'     \item CSV files with detailed performance statistics aggregated per target
#'       class and per stand.
#'   }
#'
#' @param test_data_with_predictions A data frame containing an identifier column,
#'   true target values, and predicted values with a `_pred` suffix. This is
#'   typically created by merging the test set with the `predictions` output
#'   from `compile_fit_predict_nn`.
#' @param target_features A character vector of the target variable column names.
#' @param selected_stands A character vector of stand IDs to be plotted in detail
#'   in the histogram grid.
#' @param stand_id_col A string specifying the name of the column that contains
#'   the unique stand identifier. Defaults to "inventory_id".
#' @param test_data_stemsstand An optional data frame with auxiliary data for plot
#'   annotations. Must contain the `stand_id_col` and any columns needed for
#'   annotations (e.g., `stem_number.ha`). Defaults to `NULL`.
#' @param features_to_exclude An optional character vector of target features to
#'   exclude from analysis and plotting. Defaults to `NULL`.
#' @param target_labels An optional named character vector to provide user-friendly
#'   labels for target variables in plots. Names must match `target_features`.
#'   If `NULL`, raw feature names are used. Defaults to `NULL`.
#' @param target_order An optional character vector specifying the desired order of
#'   target variables for plotting. If `NULL`, a default sort is used. Defaults to `NULL`.
#' @param scatterplot_filename Optional. Full path and filename for the scatterplot PDF.
#' @param histogram_filename Optional. Full path and filename for the histogram PDF.
#' @param dbhclass_stats_filename Optional. Full path for the per-class statistics CSV file.
#' @param stand_stats_filename Optional. Full path for the per-stand statistics CSV file.
#' @param plot_options A list of plotting parameters (e.g., widths, heights, `ncol`).
#'
#' @return A list containing three data frames:
#'   \item{class_stats}{Statistics aggregated per target class.}
#'   \item{stand_stats}{Statistics aggregated per stand.}
#'   \item{plots}{A list of all generated ggplot objects.}
#'
#' @importFrom dplyr group_by summarize filter c_across all_of pull distinct left_join rename ends_with
#' @importFrom ggplot2 ggplot aes theme_bw coord_fixed geom_point geom_abline geom_ribbon labs theme element_text scale_fill_manual geom_col annotate
#' @importFrom cowplot plot_grid draw_label get_legend
#' @importFrom stats cor var na.omit median setNames as.formula
#' @importFrom tidyr pivot_longer
#' @importFrom utils write.csv
#' @importFrom rlang .data :=
#' @importFrom stringr str_sort
#' @importFrom philentropy KL
#' @importFrom Metrics rmse
#' @importFrom magrittr %>%
#' @importFrom entropy KL.empirical
#'
#' @examples
#' \dontrun{
#' # This example shows the complete workflow: training a model with the
#' # built-in architecture and then visualizing its predictions.
#'
#' # 1. Load data and packages
#' library(deepReveal)
#' data("deepReveal_example_data")
#'
#' # 2. Prepare data for training
#' # The example data has 7 instances. We'll use 5 for training/validation and 2 for testing.
#' full_data <- deepReveal_example_data$train_data # Use the largest split for demonstration
#' train_and_val_data <- full_data[1:5, ]
#' test_data <- full_data[6:7, ]
#'
#' input_features <- deepReveal_example_data$input_features
#' target_features <- deepReveal_example_data$target_features
#'
#' # 3. Train the model using the built-in "manuscript_model_v3"
#' nn_params <- list(
#'   architecture = "manuscript_model_v3",
#'   build_params = list(lambda1 = 1e-5, lambda2 = 1e-5),
#'   fit_params = list(epochs = 20, batch_size = 1), # Small params for a small dataset
#'   loss = "kl_divergence",
#'   seed = 123
#' )
#'
#' training_results <- compile_fit_predict_nn(
#'   train_data = train_and_val_data,
#'   validation_data = train_and_val_data, # Using same data for simplicity
#'   test_data = test_data,
#'   input_features = input_features,
#'   target_features = target_features,
#'   nn_config = nn_params
#' )
#'
#' # 4. Prepare the prediction data frame for visualization
#' test_data_with_preds <- dplyr::bind_cols(
#'   test_data,
#'   training_results$predictions
#' )
#'
#' # 5. Run the visualization function
#' # We will select the two test stands for the histogram plot.
#' stands_to_plot <- test_data$inventory_id
#'
#' viz_output <- analyze_and_visualize_predictions(
#'   test_data_with_predictions = test_data_with_preds,
#'   target_features = target_features,
#'   selected_stands = stands_to_plot,
#'   stand_id_col = "inventory_id"
#' )
#'
#' # Display the generated scatterplot
#' print(viz_output$plots$scatterplot)
#' }
#' @export
analyze_and_visualize_predictions <- function(
    test_data_with_predictions,
    target_features,
    selected_stands,
    stand_id_col = "inventory_id",
    test_data_stemsstand = NULL,
    features_to_exclude = NULL,
    target_labels = NULL,
    target_order = NULL,
    scatterplot_filename = NULL,
    histogram_filename = NULL,
    dbhclass_stats_filename = NULL,
    stand_stats_filename = NULL,
    plot_options = list(
      scatterplot_width = 17, scatterplot_panel_height = 5, ncol_scatter = 3,
      histogram_width = 17, histogram_panel_height = 5, ncol_hist = 4,
      plot_units = "cm"
    )) {

  # --- 0. Initial Setup & Validation ---
  if (!requireNamespace("Metrics", quietly = TRUE)) stop("Package 'Metrics' is required.")
  if (!requireNamespace("entropy", quietly = TRUE)) stop("Package 'entropy' is required for per-class KL divergence.")

  # --- 1. Calculate Per-Stand Statistics ---
  stand_stats_df <- test_data_with_predictions %>%
    dplyr::group_by(.data[[stand_id_col]]) %>%
    dplyr::summarize(
      R2 = {
        true <- dplyr::c_across(dplyr::all_of(target_features))
        pred <- dplyr::c_across(paste0(target_features, "_pred"))
        if(stats::var(true, na.rm = TRUE) > 1e-9 && stats::var(pred, na.rm = TRUE) > 1e-9) stats::cor(true, pred)^2 else NA_real_
      },
      RMSE = Metrics::rmse(dplyr::c_across(dplyr::all_of(target_features)), dplyr::c_across(paste0(target_features, "_pred"))),
      MSE = Metrics::mse(dplyr::c_across(dplyr::all_of(target_features)), dplyr::c_across(paste0(target_features, "_pred"))),
      MAE = Metrics::mae(dplyr::c_across(dplyr::all_of(target_features)), dplyr::c_across(paste0(target_features, "_pred"))),
      .groups = "drop"
    )

  # --- 2. Calculate Per-Class Statistics ---
  class_stats_list <- lapply(target_features, function(feature) {
    pred_col <- paste0(feature, "_pred")
    true_vals <- test_data_with_predictions[[feature]]
    pred_vals <- test_data_with_predictions[[pred_col]]

    # Column-wise normalization for KL
    norm_true <- (true_vals + 1) / sum(true_vals + 1)
    norm_pred <- (pred_vals + 1) / sum(pred_vals + 1)
    kl_div <- entropy::KL.empirical(norm_true, norm_pred)

    data.frame(
      Target_Feature = feature,
      R2 = if(stats::var(true_vals) > 1e-9 && stats::var(pred_vals) > 1e-9) stats::cor(true_vals, pred_vals)^2 else NA,
      RMSE = Metrics::rmse(true_vals, pred_vals),
      MSE = Metrics::mse(true_vals, pred_vals),
      MAE = Metrics::mae(true_vals, pred_vals),
      KL = kl_div
    )
  })
  class_stats_df <- dplyr::bind_rows(class_stats_list)

  # --- 3. Prepare for Plotting ---
  plot_order <- target_order
  if (is.null(plot_order)) {
    plot_order <- stringr::str_sort(target_features, numeric = TRUE)
  }

  plot_labels <- target_labels
  if (is.null(plot_labels)) {
    plot_labels <- stats::setNames(plot_order, plot_order)
  }
  ordered_labels <- plot_labels[plot_order]

  # --- 4. Generate Scatterplots ---
  scatter_data <- test_data_with_predictions %>%
    tidyr::pivot_longer(cols = dplyr::all_of(target_features), names_to = "Target_Feature", values_to = "True_Value") %>%
    tidyr::pivot_longer(cols = dplyr::ends_with("_pred"), names_to = "Pred_Feature_Name", values_to = "Pred_Value") %>%
    dplyr::filter(paste0(.data$Target_Feature, "_pred") == .data$Pred_Feature_Name) %>%
    dplyr::mutate(Target_Feature = factor(.data$Target_Feature, levels = plot_order, labels = ordered_labels))

  scatterplot <- ggplot2::ggplot(scatter_data, ggplot2::aes(x = .data$True_Value, y = .data$Pred_Value)) +
    ggplot2::geom_point(alpha = 0.4, size = 1) +
    ggplot2::geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    ggplot2::facet_wrap(~Target_Feature, scales = "free", ncol = plot_options$ncol_scatter) +
    ggplot2::labs(x = "True Value", y = "Predicted Value", title = "True vs. Predicted Values per Target Class") +
    ggplot2::theme_bw()

  # --- 5. Generate Histograms for Selected Stands ---
  hist_data_long <- test_data_with_predictions %>%
    dplyr::filter(.data[[stand_id_col]] %in% selected_stands) %>%
    tidyr::pivot_longer(
      cols = c(dplyr::all_of(target_features), dplyr::all_of(paste0(target_features, "_pred"))),
      names_to = "Variable",
      values_to = "Value"
    ) %>%
    dplyr::mutate(
      Type = ifelse(grepl("_pred$", .data$Variable), "Predicted", "True"),
      Target_Feature = gsub("_pred$", "", .data$Variable),
      Target_Feature = factor(.data$Target_Feature, levels = plot_order, labels = ordered_labels)
    )

  histogram_plot <- ggplot2::ggplot(hist_data_long, ggplot2::aes(x = .data$Target_Feature, y = .data$Value, fill = .data$Type)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::facet_wrap(stats::as.formula(paste0("~", stand_id_col)), ncol = plot_options$ncol_hist) +
    ggplot2::labs(x = "Target Class", y = "Value", fill = "Data Type", title = "True vs. Predicted Distributions for Selected Stands") +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  # --- 6. Save Files if Filenames are Provided ---
  if (!is.null(stand_stats_filename)) {
    utils::write.csv(stand_stats_df, stand_stats_filename, row.names = FALSE)
    message(paste("Stand statistics saved to:", stand_stats_filename))
  }
  if (!is.null(dbhclass_stats_filename)) {
    utils::write.csv(class_stats_df, dbhclass_stats_filename, row.names = FALSE)
    message(paste("Class statistics saved to:", dbhclass_stats_filename))
  }
  if (!is.null(scatterplot_filename)) {
    num_rows <- ceiling(length(plot_order) / plot_options$ncol_scatter)
    height <- num_rows * plot_options$scatterplot_panel_height
    ggplot2::ggsave(scatterplot_filename, scatterplot, width = plot_options$scatterplot_width, height = height, units = plot_options$plot_units)
    message(paste("Scatterplot saved to:", scatterplot_filename))
  }
  if (!is.null(histogram_filename)) {
    num_rows_hist <- ceiling(length(selected_stands) / plot_options$ncol_hist)
    height_hist <- num_rows_hist * plot_options$histogram_panel_height
    ggplot2::ggsave(histogram_filename, histogram_plot, width = plot_options$histogram_width, height = height_hist, units = plot_options$plot_units)
    message(paste("Histogram plot saved to:", histogram_filename))
  }

  # --- 7. Return Results ---
  return(invisible(list(
    class_stats = class_stats_df,
    stand_stats = stand_stats_df,
    plots = list(scatterplot = scatterplot, histogram = histogram_plot)
  )))
}

#' @title Compile, Fit, and Predict with a Keras Neural Network
#'
#' @description This function provides a flexible workflow to compile, fit, and
#'   generate predictions from a Keras model. It can operate in two modes:
#'   1.  **Generic Mode (Default):** The user provides their own model-building
#'       function (`build_model_func`) for maximum flexibility.
#'   2.  **Built-in Mode:** The user specifies a pre-defined architecture via the
#'       `architecture` parameter (e.g., "manuscript_model_v3") to easily
#'       replicate a specific model without writing a custom function.
#'
#' @details This function is designed to be the central training engine for the
#'   package. The `deepReveal_example_data`, which contains sample instances,
#'   can be used to test either mode.
#'
#' @section Python Backend Setup:
#'   This function requires a working Python environment with TensorFlow
#'   installed. It is designed to work with either the `keras` or `keras3` R
#'   package, which must be installed by the user.
#'
#' @param train_data A data frame or matrix with the training data.
#' @param validation_data A data frame or matrix with the validation data.
#' @param test_data A data frame or matrix with the test data.
#' @param input_features A character vector specifying the names of the input features.
#' @param target_features A character vector specifying the names of the target features.
#' @param architecture An optional string to select a pre-defined model
#'   architecture. Currently, the only option is "manuscript_model_v3". If set,
#'   `build_model_func` is ignored. Defaults to `NULL`.
#' @param build_model_func A user-defined function to build a Keras model, used
#'   only when `architecture` is `NULL`. The function must accept `input_shape`
#'   and `output_units` as its first two arguments.
#' @param build_params A list of parameters to be passed to the `build_model_func`.
#'   This is where you define hyperparameters for your architecture (e.g.,
#'   `units1`, `activation`, `dropout_rate`). Defaults to an empty list.
#'   If using a `build_model_func`, these are passed to it. If using a built-in
#'   `architecture`, this list must contain necessary hyperparameters (e.g.,
#'   `lambda1`, `lambda2`, `activation`).
#' @param fit_params A list of parameters to be passed to the `keras::fit()`
#'   method (e.g., `epochs`, `batch_size`, `callbacks`). Defaults to a list
#'   with 70 epochs and a batch size of 16.
#' @param loss A string specifying a standard Keras loss (e.g., "kl_divergence")
#'   OR an R function object defining a custom loss. The custom function must
#'   accept `(y_true, y_pred)` as arguments. Defaults to "kl_divergence".
#' @param optimizer A string or a Keras optimizer object. Defaults to "adam".
#' @param metrics A list of metrics to be evaluated during training. Defaults
#'   to `list('mse')`.
#' @param seed An integer to set the seed for reproducibility. Defaults to 13.
#'
#' @return A list containing:
#'   \item{model}{The trained Keras model object.}
#'   \item{history}{The training history object from `fit()`.}
#'   \item{predictions}{A data frame containing the model's predictions on the test set.}
#'
#' @importFrom stats predict
#'
#' @examples
#' \dontrun{
#' # --- Example 1: Using the built-in architecture ---
#' # (Assumes deepReveal_example_data is loaded and split into train_df, etc.)
#'
#' # Define hyperparameters for the built-in model
#' built_in_params <- list(
#'   activation = "relu",
#'   lambda1 = 0.0001,
#'   lambda2 = 0.0001
#' )
#'
#' model_results_v3 <- compile_fit_predict_nn(
#'   train_data = train_df,
#'   validation_data = val_df,
#'   test_data = test_df,
#'   input_features = your_input_features,
#'   target_features = your_target_features,
#'   architecture = "manuscript_model_v3", # Select the built-in model
#'   build_params = built_in_params,
#'   fit_params = list(epochs = 50, batch_size = 2), # Use a small batch for 7 instances
#'   loss = "softmax", # Or your custom loss function
#'   seed = 123
#' )
#'
#' # Example 2. Define a custom function to build your desired Keras model.
#' # This function can be as simple or complex as needed.
#' create_my_nn <- function(input_shape, output_units, units1 = 64, activation = "relu") {
#'   # Check for Keras package availability
#'   if (requireNamespace("keras3", quietly = TRUE)) {
#'     keras_pkg <- "keras3"
#'   } else if (requireNamespace("keras", quietly = TRUE)) {
#'     keras_pkg <- "keras"
#'   } else {
#'     stop("A Keras package ('keras' or 'keras3') is required.")
#'   }
#'
#'   # Dynamically get functions to avoid direct dependencies
#'   keras_model_sequential <- get("keras_model_sequential", asNamespace(keras_pkg))
#'   layer_dense <- get("layer_dense", asNamespace(keras_pkg))
#'
#'   model <- keras_model_sequential(name = "MyCustomModel") %>%
#'     layer_dense(units = units1, activation = activation, input_shape = input_shape) %>%
#'     layer_dense(units = output_units, activation = 'softmax') # Example output layer
#'
#'   return(model)
#' }
#'
#' # 2. Prepare dummy data (replace with your actual data)
#' # (See previous function examples for data preparation)
#'
#' # 3. Define parameters for the model building and fitting
#' my_build_params <- list(units1 = 128, activation = "tanh")
#' my_fit_params <- list(epochs = 10, batch_size = 32)
#'
#' # 4. Run the training workflow
#' model_results_custom <- compile_fit_predict_nn(
  #'   train_data = train_df,
  #'   validation_data = val_df,
  #'   test_data = test_df,
  #'   input_features = your_input_features,
  #'   target_features = your_target_features,
  #'   architecture = NULL, # Explicitly use custom mode
  #'   build_model_func = create_my_nn,
  #'   build_params = list(units1 = 32),
  #'   fit_params = list(epochs = 50, batch_size = 2),
  #'   seed = 456
  #' )
#'
#' # Inspect results
#' summary(model_results_custom$model)
#' plot(model_results_custom$history)
#' head(model_results_custom$predictions)
#' }
#' @export
compile_fit_predict_nn <- function(train_data,
                                   validation_data,
                                   test_data,
                                   input_features,
                                   target_features,
                                   architecture = NULL,
                                   build_model_func = NULL,
                                   build_params = list(),
                                   fit_params = list(epochs = 70, batch_size = 16),
                                   loss = "kl_divergence",
                                   optimizer = "adam",
                                   metrics = list('mse'),
                                   seed = 13) {

  # --- 0. Argument Validation & Setup ---
  if (is.null(architecture) && !is.function(build_model_func)) {
    stop("You must provide a function to `build_model_func` or specify a built-in `architecture`.")
  }
  if (!is.null(architecture) && is.function(build_model_func)) {
    warning("Both `architecture` and `build_model_func` were provided. The built-in `architecture` will be used.")
  }
  # Check for Keras package availability
  if (requireNamespace("keras3", quietly = TRUE)) {
    keras_pkg <- "keras3"
  } else if (requireNamespace("keras", quietly = TRUE)) {
    keras_pkg <- "keras"
  } else {
    stop("A Keras package ('keras' or 'keras3') is required to run this function.")
  }

  # Dynamically get Keras functions
  # Dynamically get Keras functions
  set_random_seed <- get("set_random_seed", asNamespace(keras_pkg))
  keras_model_sequential <- get("keras_model_sequential", asNamespace(keras_pkg))
  layer_dense <- get("layer_dense", asNamespace(keras_pkg))
  regularizer_l2 <- get("regularizer_l2", asNamespace(keras_pkg))
  compile <- get("compile", asNamespace(keras_pkg))
  fit <- get("fit", asNamespace(keras_pkg))

  # --- 1. Set Seeds for Reproducibility ---
  set.seed(seed)
  set_random_seed(seed)

  # --- 2. Prepare Data ---
  train_x <- as.matrix(train_data[, input_features, drop = FALSE])
  train_y <- as.matrix(train_data[, target_features, drop = FALSE])
  val_x <- as.matrix(validation_data[, input_features, drop = FALSE])
  val_y <- as.matrix(validation_data[, target_features, drop = FALSE])
  test_x <- as.matrix(test_data[, input_features, drop = FALSE])

  input_shape <- ncol(train_x)
  output_units <- ncol(train_y)

  # --- 3. Build Model using User-Provided Function ---
  model <- NULL
  if (!is.null(architecture)) {
    message(paste("Building model using built-in architecture:", architecture))

    if (architecture == "manuscript_model_v3") {
      # This is the architecture from your project script's model_version = 3
      # It uses hyperparameters from the build_params list

      # Helper for rounding units safely
      safe_round_units <- function(val) { max(1, round(val)) }

      # Extract params or use defaults
      act_func <- build_params$activation %||% "relu"
      l2_lambda1 <- build_params$lambda1 %||% 0.0001
      l2_lambda2 <- build_params$lambda2 %||% 0.0001

      model <- keras_model_sequential(name = paste0("manuscript_v3_seed", seed)) %>%
        layer_dense(
          units = safe_round_units(3.0 * output_units),
          activation = act_func,
          input_shape = input_shape,
          kernel_regularizer = regularizer_l2(l2_lambda1)
        ) %>%
        layer_dense(
          units = safe_round_units(2.5 * output_units),
          activation = act_func,
          kernel_regularizer = regularizer_l2(l2_lambda2)
        ) %>%
        layer_dense(units = safe_round_units(2.0 * output_units), activation = act_func) %>%
        layer_dense(units = safe_round_units(1.5 * output_units), activation = act_func) %>%
        layer_dense(units = output_units, activation = 'softmax')

    } else {
      stop(paste("Unknown built-in architecture:", architecture))
    }
  } else {
    message("Building model using user-provided function...")
    build_args <- c(list(input_shape = input_shape, output_units = output_units), build_params)
    model <- tryCatch({
      do.call(build_model_func, build_args)
    }, error = function(e) {
      stop("Error executing `build_model_func`: ", e$message, call. = FALSE)
    })
  }

  if (is.null(model) || !inherits(model, "keras.src.models.model.Model")) {
    stop("Model building failed or did not return a valid Keras model object.")
  }

  # --- 4. Compile Model ---
  message("Compiling model...")
  compile(
    object = model,
    optimizer = optimizer,
    loss = loss,
    metrics = metrics
  )

  # --- 5. Fit Model ---
  message("Fitting model...")
  fit_args <- c(
    list(
      object = model,
      x = train_x,
      y = train_y,
      validation_data = list(val_x, val_y),
      verbose = 1
    ),
    fit_params
  )

  history <- do.call(fit, fit_args)

  # --- 6. Predict on Test Data ---
  message("Generating predictions...")
  predictions_matrix <- stats::predict(model, test_x)
  predictions_df <- as.data.frame(predictions_matrix)
  colnames(predictions_df) <- paste0(target_features, "_pred")

  print(summary(model))

  # --- 7. Return Results ---
  return(list(
    model = model,
    history = history,
    predictions = predictions_df
  ))
}


#' @title Calculate Mean Kullback-Leibler (KL) Divergence Metric
#'
#' @description Calculates the Kullback-Leibler (KL) divergence between true
#'   and predicted probability distributions on a row-wise basis and returns the
#'   mean divergence. This function is designed to be used as a custom
#'   `metric_function` in analyses like `permutation_feature_importance`.
#'
#' @details This function treats each row of the input matrices (`true_y`, `pred_y`)
#'   as a separate probability distribution. For each row, it calculates the
#'   KL divergence DKL(P || Q) and returns the mean of these values.
#'
#' @param true_y A numeric matrix of non-negative true target values.
#' @param pred_y A numeric matrix of non-negative predicted target values.
#' @param smoothing_value A small positive constant added to all values before
#'   normalization. Defaults to `1e-9`.
#'
#' @return A single numeric value representing the mean KL divergence.
#'
#' @importFrom philentropy distance
#'
#' @export
kl_divergence_metric <- function(true_y, pred_y, smoothing_value = 1e-9) {
  # --- 0. Validation ---
  if (!requireNamespace("philentropy", quietly = TRUE)) {
    stop("Package 'philentropy' is required. Please install it.", call. = FALSE)
  }
  if (any(true_y < 0, na.rm = TRUE) || any(pred_y < 0, na.rm = TRUE)) {
    warning("Input values contain negative numbers.")
  }

  # --- 1. Ensure inputs are matrices ---
  if (!is.matrix(true_y)) true_y <- as.matrix(true_y)
  if (!is.matrix(pred_y)) pred_y <- as.matrix(pred_y)

  if (ncol(true_y) != ncol(pred_y) || nrow(true_y) != nrow(pred_y)) {
    stop(paste0("Dimensions of true_y (", nrow(true_y), "x", ncol(true_y),
                ") and pred_y (", nrow(pred_y), "x", ncol(pred_y), ") must match."))
  }

  if (nrow(true_y) == 0) {
    return(NA_real_)
  }

  # --- 2. Calculate KL Divergence for each row ---
  kl_divergences_per_row <- vapply(1:nrow(true_y), function(i) {

    current_true <- true_y[i, ]
    current_pred <- pred_y[i, ]

    if(all(is.na(current_true)) || all(is.na(current_pred))) return(NA_real_)

    smoothed_true <- current_true + smoothing_value
    smoothed_pred <- current_pred + smoothing_value

    norm_true <- smoothed_true / sum( smoothed_true, na.rm = TRUE)
    norm_pred <- smoothed_pred / sum( smoothed_pred, na.rm = TRUE)

    prob_matrix <- rbind(norm_true, norm_pred)

    # --- THIS IS THE CORRECTED LINE ---
    # Use distance() for a direct comparison, which reliably returns a single number.
    return(suppressMessages(philentropy::distance(prob_matrix, method = "kullback-leibler", unit = "log")))

  }, FUN.VALUE = numeric(1))

  # --- 3. Return the mean of the KL divergences ---
  mean_kl <- mean(kl_divergences_per_row, na.rm = TRUE)

  return(mean_kl)
}
