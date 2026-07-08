#' @title Example Data for the deepReveal Package
#'
#' @description A small, anonymized subset of the data used in Hiltner et al.
#'   (in prep) for demonstrating the functionalities of the `deepReveal` package.
#'   It mimics the structure of the full `model_data` object used in the original
#'   study.
#'
#' @details This dataset is derived from the Swiss Experimental Forest Management
#'   (EFM) network. It contains a sample of 30 plots and includes data splits
#'   for training, validation, and testing, as well as metadata about the input
#'   and target features used for the benchmark NN model. All numeric values have
#'   been slightly modified with random noise to ensure full anonymization.
#'
#' @format A list named `deepReveal_example_data` with 8 elements:
#' \describe{
#'   \item{train_data}{A data frame with the training subset. Contains an
#'     anonymized `inventory_id` column, plus all input and target features.}
#'   \item{val_data}{A data frame with the validation subset.}
#'   \item{test_data}{A data frame with the test subset.}
#'   \item{input_features}{A character vector listing the 37 predictor variable names.}
#'   \item{target_features}{A character vector listing the 10 target variable names
#'     (SSD DBH classes from 8 cm to >50 cm).}
#'   \item{top_seed}{An integer representing the random seed used for the benchmark
#'     model training, ensuring reproducibility.}
#'   \item{top_model_predictions}{A data frame containing the benchmark model's
#'     predictions for the stands included in the `test_data` subset.}
#'   \item{top_model_metrics}{A data frame containing the training history metrics
#'     (e.g., loss, val_loss) for the benchmark model.}
#' }
#'
#' @source Derived and anonymized from the Swiss Experimental Forest Management (EFM)
#'   plot network, provided by the Swiss Federal Institute for Forest, Snow and
#'   Landscape Research (WSL). Original data as used in Hiltner et al. (in prep).
"deepReveal_example_data"
