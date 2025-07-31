utils::globalVariables(c(
  # --- Add these two lines for the keras NOTE ---
  "load_model",
  "save_model",

  # --- Keep all the previous variables for dplyr/ggplot2 ---
  ".", ".data", "Feature", "Importance", "Target_Variable_Formatted",
  "Predicted_Value", "Varied_Feature_Value_Normalized", "plot_id",
  "Percent_Change_Input_Factor", "Percent_Change_Prediction", "new_plot_id",
  "inventory_id", "KL", "R2", "RMSE", "MSE", "metric", "value",
  "true", "pred", "x_ribbon", "ymin_ribbon", "ymax_ribbon",
  "dbh_axis_labels_all", "dbh_midpoints_numeric_all", "df_to_save_dbh_stats",
  "final_percent_change_df", "final_range_sensitivity_df",
  "generate_combined_histogram_set", "map_dbh_midpoint_to_label",
  "stand_stats", "standstats_to_inspect_df", "Avg_Min_Val_Loss",
  "Feature_Set", "Input_Feature", "Min_Val_Loss", "Annotation_Label",
  "Input_Feature_For_Annotation", "Min_Loss_To_Display", "inventory_year_structure",
  "R2_calc", "RMSE_calc", "MSE_calc", "KL_calc",
  "Pred_Feature_Name", "Pred_Value", "Target_Feature", "True_Value",
  "Type", "Value", "Variable"
))
