# --- Step 0: Load Necessary Libraries ---
# Make sure you have these packages installed and loaded
library(dplyr)
library(stringr)

# --- Step 1: Configuration ---
# You can adjust these parameters
N_PLOTS_TO_SAMPLE <- 50 # Number of unique plots to include in the example
NOISE_FACTOR <- 0.01     # e.g., 0.01 means +/- 1% random noise will be added

# Ensure model_data is loaded in your environment
load(file = 'C:/Users/ulhiltner/NCCS/initforclim/AnalysisR_dbhClass4cm/OutputData/benchmark_v2_stand_manual3_dev_model_data.RData' ) # '../model_results.v2.stand.manual3.RData' C:\Users\ulhiltner\NCCS\initforclim\AnalysisR_dbhClass4cm\OutputData
model_data <- model_data_for_benchmark
if (!exists("model_data")) {
  stop("Please load your 'model_data' list object into the R environment first.")
}

# --- Step 2: Extract All Unique Original Plot IDs ---
message("Identifying unique plot IDs from train, validation, and test sets...")

all_inventories <- dplyr::bind_rows(
  model_data$train_data,
  model_data$val_data,
  model_data$test_data
) %>%
  dplyr::mutate(plot_id = sub("_.*", "", inventory_id))

unique_plot_ids <- unique(all_inventories$plot_id)

if (length(unique_plot_ids) < N_PLOTS_TO_SAMPLE) {
  warning(paste("Requested", N_PLOTS_TO_SAMPLE, "plots, but only", length(unique_plot_ids), "are available. Using all available plots."))
  N_PLOTS_TO_SAMPLE <- length(unique_plot_ids)
}

# --- Step 3: Sample a Subset of Plot IDs ---
message(paste("Randomly sampling", N_PLOTS_TO_SAMPLE, "plots for the example dataset..."))
set.seed(42) # For reproducible sampling
sampled_plot_ids <- sample(unique_plot_ids, N_PLOTS_TO_SAMPLE)

# --- Step 4: Create Anonymization Map ---
message("Creating anonymization map for plot IDs...")

anonymization_map <- tibble::tibble(
  plot_id = sampled_plot_ids,
  new_plot_id = paste0("Plot", stringr::str_pad(1:N_PLOTS_TO_SAMPLE, 3, pad = "0"))
)

# --- Step 5: Define a Helper Function to Process Each Data Split ---
process_data_split <- function(df, sampled_ids, id_map, input_cols, target_cols, noise) {
  df_processed <- df %>%
    dplyr::mutate(plot_id = sub("_.*", "", inventory_id)) %>%
    dplyr::filter(plot_id %in% sampled_ids) %>%
    dplyr::left_join(id_map, by = "plot_id") %>%
    dplyr::mutate(
      inventory_year_structure = stringr::str_extract(inventory_id, "_[0-9_]+$"),
      inventory_id = paste0(new_plot_id, inventory_year_structure)
    )

  essential_cols <- c("inventory_id", input_cols, target_cols)
  df_subset <- df_processed %>%
    dplyr::select(dplyr::all_of(essential_cols))

  numeric_features <- names(df_subset)[sapply(df_subset, is.numeric)]
  df_final <- df_subset %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(numeric_features),
                                ~ .x * (1 + stats::runif(n(), -noise, noise))))

  return(df_final)
}

# --- Step 6: Process Train, Validation, and Test Data Splits---
message("Processing train, validation, and test data splits...")
example_train_data <- process_data_split(model_data$train_data, sampled_plot_ids, anonymization_map, model_data$input_features, model_data$target_features, NOISE_FACTOR)
example_val_data <- process_data_split(model_data$val_data, sampled_plot_ids, anonymization_map, model_data$input_features, model_data$target_features, NOISE_FACTOR)
example_test_data <- process_data_split(model_data$test_data, sampled_plot_ids, anonymization_map, model_data$input_features, model_data$target_features, NOISE_FACTOR)

# --- Step 7: Process Benchmark Model Results to Match the Sampled Data ---
message("Filtering and anonymizing benchmark model predictions...")

# Get the original inventory_ids that were included in our example test set
original_test_ids <- model_data$test_data %>%
  dplyr::mutate(plot_id = sub("_.*", "", inventory_id)) %>%
  dplyr::filter(plot_id %in% sampled_plot_ids) %>%
  dplyr::pull(inventory_id)

# Filter the original top_model_predictions using these original IDs
if (!is.null(model_data$top_model_predictions)) {
  example_top_model_predictions <- model_data$top_model_predictions %>%
    dplyr::filter(inventory_id %in% original_test_ids)
} else {
  example_top_model_predictions <- NULL
}

# Define a helper function to anonymize the inventory_id in the filtered results
anonymize_results_df <- function(df, id_map) {
  if (is.null(df) || nrow(df) == 0) return(df)
  df %>%
    dplyr::mutate(plot_id = sub("_.*", "", inventory_id)) %>%
    dplyr::inner_join(id_map, by = "plot_id") %>%
    dplyr::mutate(
      inventory_year_structure = stringr::str_extract(inventory_id, "_[0-9_]+$"),
      inventory_id = paste0(new_plot_id, inventory_year_structure)
    ) %>%
    dplyr::select(-plot_id, -new_plot_id)
}

# Apply anonymization ONLY to the predictions data frame
example_top_model_predictions <- anonymize_results_df(example_top_model_predictions, anonymization_map)

# For top_model_metrics, we just carry it over directly without filtering or anonymizing
if (!is.null(model_data$top_model_metrics)) {
  example_top_model_metrics <- model_data$top_model_metrics
} else {
  example_top_model_metrics <- NULL
}


# --- Step 8: Create the Final, Complete Example Data Object ---
message("Assembling final example data object...")

deepReveal_example_data <- list(
  train_data = example_train_data,
  val_data = example_val_data,
  test_data = example_test_data,
  input_features = model_data$input_features,
  target_features = model_data$target_features,
  top_seed = model_data$top_seed,
  top_model_predictions = example_top_model_predictions, # The subsetted & anonymized predictions
  top_model_metrics = example_top_model_metrics      # The original, unfiltered metrics
)

# --- Step 9: Save the Example Data Object Correctly ---
# Make sure the deepReveal_example_data object is in your R environment
# Define the path to your R package directory
package_path <- paste0(getwd()) #"path/to/your/deepReveal"

# Use usethis::use_data(), specifying the package path
usethis::use_data(deepReveal_example_data, overwrite = TRUE)


message("Done! The 'deepReveal_example_data' list is now complete and ready in your R environment.")
message("Run 'usethis::use_data(deepReveal_example_data, overwrite = TRUE)' to save it to your package.")
print(str(deepReveal_example_data, max.level = 2))
