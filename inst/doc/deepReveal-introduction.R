## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)


## ----load-packages, eval=TRUE-------------------------------------------------
library(deepReveal)
library(ggplot2) 
library(dplyr)


## ----load-data, eval=TRUE-----------------------------------------------------
# Create a clean temporary directory for this session's outputs
temp_dir <- tempdir()

# Load the example data object from the package
data("deepReveal_example_data")

# Save the data object to a temporary file
model_data_path <- file.path(temp_dir, "deepReveal_example_data.RData")
save(deepReveal_example_data, file = model_data_path)

# Get the full, absolute file path to the model inside the package.
# The system.file() function is the standard R way to do this.
model_path <- system.file("extdata", "deepReveal_example_model.keras",
                          package = "deepReveal")


## ----load-model, eval=FALSE---------------------------------------------------
# # Note: Loading the model requires a working Python/TensorFlow environment
# # with either the 'keras' or 'keras3' R package installed.
# # Install with: keras3::install_keras() or tensorflow::install_tensorflow()
# #
# # Once set up, load the model as follows:
# loaded_model <- keras3::load_model(model_path)
# 
# # Inspect the model architecture:
# # summary(loaded_model)


## ----run-pfi, eval=FALSE------------------------------------------------------
# # We will use the Kullback-Leibler (KL) divergence as our performance metric,
# # as it is well-suited for comparing probability distributions like SSDs.
# metric_func <- kl_divergence_metric
# 
# # Run the PFI analysis. The function returns a list containing the
# # results data frame and the ggplot object.
# pfi_output <- permutation_feature_importance(
#   model_path = model_path,
#   model_data_name = "deepReveal_example_data",
#   model_data_path = model_data_path,
#   input_feature_set = "full.inputs",
#   metric_function = metric_func,
#   plot_filename = "pfi_benchmark_model.pdf",
#   plot_save_path = temp_dir,
#   bar_color = "orange2",
#   higher_is_better = FALSE, # Lower KL divergence is better
#   n_permutations = 10,
#   seed = 123
# )
# # Display the most important features
# #head(pfi_output$results)
# 
# # Display the generated plot
# #print(pfi_output$plot)
# 


## ----run-fvs, eval=FALSE------------------------------------------------------
# # Use the results from the PFI analysis to select the top features
# pfi_results <- pfi_output$results
# 
# # For more readable plots, we can provide custom labels for our target variables.
# # The names of the vector must match the raw feature names.
# # 1. Get the raw target feature names from the example data
# target_names <- deepReveal_example_data$target_features
# 
# # 2. Create a complete, named list of custom labels
# custom_target_labs_full <- c(
#   "stems.ha_dbhclass10" = "DBH: (8, 11.5] cm",
#   "stems.ha_dbhclass13" = "DBH: (11.5, 15] cm",
#   "stems.ha_dbhclass17" = "DBH: (15, 20] cm",
#   "stems.ha_dbhclass22" = "DBH: (20, 25] cm",
#   "stems.ha_dbhclass27" = "DBH: (25, 30] cm",
#   "stems.ha_dbhclass32" = "DBH: (30, 35] cm",
#   "stems.ha_dbhclass37" = "DBH: (35, 40] cm",
#   "stems.ha_dbhclass42" = "DBH: (40, 45] cm",
#   "stems.ha_dbhclass47" = "DBH: (45, 50] cm",
#   "stems.ha_dbhclass52" = "DBH: >50 cm"
# )
# # Ensure the names of your labels vector match the target_names
# names(custom_target_labs_full) <- target_names
# 
# # Run the sensitivity analysis on the top 4 features
# sensitivity_output <- feature_value_sensitivity(
#   model_path = model_path,
#   model_data_name = "deepReveal_example_data",
#   model_data_path = model_data_path,
#   importance_results = pfi_results,
#   top_n_features = 4,
#   target_labels = custom_target_labs_full,
#   plot_filename_base = "feature_sensitivity_example",
#   plot_save_path = temp_dir,
#   seed = 123
# )
# 
# # You can now view the returned plot objects
# #print(sensitivity_output$range_plot)
# #print(sensitivity_output$percent_change_plot)
# 


## ----define-and-train-custom-model, eval=FALSE--------------------------------
# # Step 1: Define a function that creates a Keras model.
# # It must accept `input_shape` and `output_units` as arguments.
# create_simple_nn <- function(input_shape, output_units, units1 = 32, activation = "relu") {
#   if (requireNamespace("keras3", quietly = TRUE)) {
#     k_pkg <- "keras3"
#   } else if (requireNamespace("keras", quietly = TRUE)) {
#     k_pkg <- "keras"
#   } else {
#     stop("A Keras package ('keras' or 'keras3') is required.")
#   }
#   keras_model_sequential <- get("keras_model_sequential", asNamespace(k_pkg))
#   layer_dense <- get("layer_dense", asNamespace(k_pkg))
# 
#   model <- keras_model_sequential(name = "MySimpleModel") %>%
#     layer_dense(units = units1, activation = activation, input_shape = input_shape) %>%
#     layer_dense(units = output_units, activation = 'softmax')
#   return(model)
# }
# 
# # Step 2: Load the data into the environment.
# data("deepReveal_example_data")
# model_data <- deepReveal_example_data
# 
# # The example data contains 387 training, 26 validation, and 70 test instances.
# train_df <- model_data$train_data
# val_df <- model_data$val_data
# test_df <- model_data$test_data
# 
# input_features <- model_data$input_features
# target_features <- model_data$target_features
# 
# # Step 3: Run the training function.
# training_results <- compile_fit_predict_nn(
#   train_data = train_df,
#   validation_data = val_df,
#   test_data = test_df,
#   input_features = input_features,
#   target_features = target_features,
#   build_model_func = create_simple_nn,
#   build_params = list(units1 = 20, activation = "relu"),
#   fit_params = list(epochs = 10, batch_size = 8),
#   loss = "kl_divergence",
#   seed = 123
# )
# 


## ----visualize-custom-model, eval=FALSE---------------------------------------
# # --- Visualization 1: Plotting Training History and 1:1 plot ---
# 
# # Helper function to plot loss vs. validation loss
# plot_training_history <- function(history) {
#   history_df <- as.data.frame(history$metrics)
#   history_df$epoch <- 1:nrow(history_df)
# 
#   ggplot(history_df, aes(x = epoch)) +
#     geom_line(aes(y = loss, color = "Training Loss")) +
#     geom_line(aes(y = val_loss, color = "Validation Loss")) +
#     labs(title = "Model Training History", x = "Epoch", y = "Loss") +
#     scale_color_manual(name = "Metric", values = c("Training Loss" = "blue", "Validation Loss" = "magenta")) +
#     theme_bw() +
#     theme(legend.position = "bottom")
# }
# 
# # Plot the history from our training results
# #plot_training_history(training_results$history)
# 
# 
# # --- Visualization 2: Detailed Prediction Analysis ---
# 
# # First, combine the test data with the model's predictions
# test_data_with_preds <- dplyr::bind_cols(
#   test_df,
#   training_results$predictions
# )
# 
# # Select some stands to see in the detailed histogram plot
# stands_to_plot <- utils::head(test_df$inventory_id, 4)
# 
# # Run the detailed visualization and analysis function
# viz_output <- analyze_and_visualize_predictions(
#   test_data_with_predictions = test_data_with_preds,
#   target_features = target_features,
#   selected_stands = stands_to_plot,
#   stand_id_col = "inventory_id"
# )
# 
# # Print the generated scatterplot (target feature level) and histogram (target across instance level)
# #print(viz_output$plots$scatterplot)
# #print(viz_output$plots$histogram)
# 


## ----run-fs-training, eval=FALSE----------------------------------------------
# # This configuration is a RECIPE to build new models that replicate the
# # architecture from the original manuscript. It is NOT used to load a file.
# nn_config_builtin <- list(
#   architecture = "manuscript_model_v3",
#   build_params = list(lambda1 = 1e-5, lambda2 = 1e-5, activation = "relu"),
#   fit_params = list(epochs = 10, batch_size = 16),
#   loss = "kl_divergence",
#   seed = 42
# )
# 
# # Define the feature sets to test, based on our PFI results from Part 1
# feature_sets_list <- list(
#   Top2_Features = head(pfi_output$results$Feature, 2),
#   Top4_Features = head(pfi_output$results$Feature, 4),
#   Top8_Features = head(pfi_output$results$Feature, 8)
# )
# 
# # Define where to save the results
# fs_training_results_path <- file.path(temp_dir, "fs_training_results.RData")
# 
# # Run the automated training workflow. Note: This is computationally intensive.
# # The function does not return a large object directly into your R environment.
# # This is a deliberate design choice for robustness. Training multiple neural networks
# # can be a very long and memory-intensive process: your work is save, memory is managed, the workflow is modular.
# run_feature_set_sensitivity_training(
#   model_data_name = "deepReveal_example_data",
#   model_data_path = model_data_path,
#   feature_sets_list = feature_sets_list,
#   compile_fit_predict_nn_func = compile_fit_predict_nn,
#   nn_config = nn_config_builtin,
#   output_rdata_path = fs_training_results_path,
#   save_trained_models_path = file.path(temp_dir, "fs_models")
# )
# 


## ----plot-heatmap, eval=FALSE-------------------------------------------------
# # This code visualizes the results from the .RData file generated above.
# heatmap_output <- plot_feature_set_val_loss_heatmap(
#   sensitivity_results_rdata_path = fs_training_results_path,
#   importance_results = pfi_output$results, # Use PFI results from Part 1 for ordering
#   plot_filename = "feature_set_heatmap.pdf",
#   plot_save_path = temp_dir,
#   plot_title = "Model Performance Across Feature Subsets"
# )
# 
# #print(heatmap_output$plot)
# 


## ----generate-detailed-plots, eval=FALSE--------------------------------------
# # This function creates a new subdirectory for each feature set,
# # containing detailed prediction plots and statistics.
# 
# # Define a base path for the output plots
# detailed_plots_path <- file.path(temp_dir, "detailed_feature_set_plots")
# 
# # Run the plot generation function
# all_set_stats <- generate_feature_set_prediction_plots(
#   sensitivity_results_rdata_path = fs_training_results_path,
#   analyze_and_visualize_predictions_func = analyze_and_visualize_predictions,
#   plot_save_path_base = detailed_plots_path,
#   stand_id_col = "inventory_ids",
#   num_stands_for_histograms = 4
# )
# 
# 
# # The function saves all plots to disk. You can inspect the `all_set_stats`
# # object to see the aggregated statistics for each model.
# head(all_set_stats$Top4_Features$class_stats)
# print(all_set_stats$Top2_Features$plots$scatterplot)
# print(all_set_stats$Top2_Features$plots$histogram)
# 

