# Author: Jeremy Rubin
# Date: 1/30/16
# Code to visualize internal validation performance of KDPI and machine learning models to predict 1-year eGFR or DGF

library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(ggplot2)

# Directory that contains results per run of either Binary_Internal_Validation_Metrics.R 
# or Continuous_Internal_Validation_Metrics.R for a single number of MRMR-selected features
# Assumed file structure name: x_MRMR_features_training_C/MSE_results.csv
# where x is a number 1-100 (but can vary this in practice), and C/MSE depends
# on whether you ran the results for 1-year eGFR or DGF
# Rownames are "Number of MRMR features","Outcome","Number of training subjects",
# Lasso, "Ridge", "Elastic net", "Random forest", and "KDPI"
# Column name defaults to "x" from internal validation code 
# Outcome is "1_yr_eGFR" for predicting eGFR outcome and "DGF" for DGF outcome 
# Results for machine learning models and KDPI rows are C-statistics for DGF files
# and MSEs for eGFR files 
results_dir <- "Training_Model_Results"

read_results_file <- function(file) {
  
  df <- read_csv(file, show_col_types = FALSE, col_names = c("key", "value"))
  
  # Convert from long format to wide
  df_wide <- df %>%
    pivot_wider(names_from = key, values_from = value)
  
  # Keep only what you care about
  df_clean <- df_wide %>%
    transmute(
      `Number of MRMR features` = as.numeric(`Number of MRMR features`),
      Lasso = as.numeric(Lasso),
      Ridge = as.numeric(Ridge),
      `Elastic net` = as.numeric(`Elastic net`),
      `Random forest` = as.numeric(`Random forest`),
      KDPI = as.numeric(KDPI)
    )
  
  return(df_clean)
}

# File lists
all_files <- list.files(results_dir, full.names = TRUE)

dgf_files <- all_files[str_detect(all_files, "_C_results\\.csv$")]
egfr_files <- all_files[str_detect(all_files, "_MSE_results\\.csv$")]

# Combine + sort
cstat_data <- bind_rows(lapply(dgf_files, read_results_file)) %>%
  arrange(`Number of MRMR features`)

mse_data <- bind_rows(lapply(egfr_files, read_results_file)) %>%
  arrange(`Number of MRMR features`)

### Code for visualizing MSE/C-statistic for machine learning models and KDPI 
### as a function of the number of MRMR-selected features 
### and identify the machine learning model and specific number of MRMR-selected features
# at which there is the lowest MSE or greatest C-statistic 

# Long format
mse_long <- mse_data %>%
  pivot_longer(cols = -`Number of MRMR features`, 
               names_to = "Algorithm", 
               values_to = "MSE")

cstat_long <- cstat_data %>%
  pivot_longer(cols = -`Number of MRMR features`, 
               names_to = "Algorithm", 
               values_to = "C_stat")

# Clean algorithm names (if needed)
mse_long$Algorithm <- gsub("\\.", " ", mse_long$Algorithm)
cstat_long$Algorithm <- gsub("\\.", " ", cstat_long$Algorithm)

## Fix algorithm order for consistent legend/colors 
mse_long$Algorithm <- factor(mse_long$Algorithm,
                             levels = c("Elastic net", "KDPI", "Lasso", "Random forest", "Ridge")
)

cstat_long$Algorithm <- factor(cstat_long$Algorithm,
                               levels = c("Elastic net", "KDPI", "Lasso", "Random forest", "Ridge")
)

# Find point in graph with the lowest MSE
best_mse_row <- mse_long %>%
  slice_min(MSE, n = 1)

# Find point in graph with the greatest AUC
best_cstat_row <- cstat_long %>%
  slice_max(C_stat, n = 1)

# MSE plot
p1 <- ggplot(mse_long, 
             aes(x = `Number of MRMR features`, y = MSE, color = Algorithm)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_point(data = best_mse_row, 
             aes(x = `Number of MRMR features`, y = MSE),
             shape = 8, size = 5, color = "red", inherit.aes = FALSE) +
  labs(title = "MSE vs. Number of Top MRMR-selected Features",
       x = "Number of Top MRMR-selected Features",
       y = "Mean Squared Error") +
  theme_minimal(base_size = 13)

# C-statistic plot
p2 <- ggplot(cstat_long, 
             aes(x = `Number of MRMR features`, y = C_stat, color = Algorithm)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_point(data = best_cstat_row, 
             aes(x = `Number of MRMR features`, y = C_stat),
             shape = 8, size = 5, color = "red", inherit.aes = FALSE) +
  labs(title = "C-statistic vs. Number of Top MRMR-selected Features",
       x = "Number of Top MRMR-selected Features",
       y = "C-statistic") +
  theme_minimal(base_size = 13)

# Display
print(p1)
print(p2)
