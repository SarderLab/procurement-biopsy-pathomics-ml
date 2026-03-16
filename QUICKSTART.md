# Quick Start Guide

## Running the Full Analysis Pipeline

Follow these steps to reproduce the analysis from scratch:

### Step 1: Install Dependencies
```r
# Install required packages
install.packages(c(
  "randomForest",
  "permimp", 
  "ggplot2",
  "pROC",
  "dplyr",
  "tidyr",
  "gridExtra",
  "stringr",
  "caret",
  "foreach",
  "doParallel"
))

# Install mRMRe (may require special installation)
# For macOS/Linux:
# install.packages("mRMRe")
# For Windows, you may need to install from source or use BiocManager
```

### Step 2: Set Working Directory
```r
setwd("path/to/procurement-biopsy-pathomics-ml")
```

### Step 3: Run Data Preprocessing (First Time - DGF)
```r
source("R/Create_Train_Test_Exclusion_Data.R")

# Generate train/test split using DGF outcome
# This creates train_indices.csv and test_indices.csv
result_dgf <- generate_training_testing_exclusion_data(
  input.file.name = "data/Renal_Data.csv",
  num.MRMR.features = 30,
  outcome = "B",  # DGF (binary)
  train.sub.name = "train_indices.csv",
  test.sub.name = "test_indices.csv", 
  make.split = TRUE  # Create new split
)
```

### Step 4: Run Data Preprocessing for eGFR
```r
# Use the same train/test split for eGFR
result_egfr <- generate_training_testing_exclusion_data(
  input.file.name = "data/Renal_Data.csv",
  num.MRMR.features = 30,
  outcome = "C",  # eGFR (continuous)
  train.sub.name = "train_indices.csv",
  test.sub.name = "test_indices.csv",
  make.split = FALSE  # Use existing split
)
```

### Step 5: Internal Validation (Required for Hyperparameter Tuning)

Both scripts automatically loop over 1–100 MRMR-selected features and parallelize the bootstrap resampling across available CPU cores — no manual configuration needed.

For DGF:
```r
source("R/Binary_Internal_Validation_Metrics.R")
# Loops over num.MRMR.features = 1:100, saving one results file per iteration
```

For eGFR:
```r
source("R/Continuous_Internal_Validation_Metrics.R")
# Loops over num.MRMR.features = 1:100, saving one results file per iteration
```

### Step 6: Visualize Internal Validation Results
```r
source("R/Visualize_MSE_or_C_training.R")

# For eGFR prediction - edit outcome variable in the script:
# outcome <- "C"

# For DGF prediction - edit outcome variable in the script:
# outcome <- "B"

# Run the script for each outcome type
```

### Step 7: Train Final Models and Generate Results
```r
source("R/Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R")

# For eGFR prediction - edit line 28 in the script:
# outcome <- "C"

# For DGF prediction - edit line 28 in the script:
# outcome <- "B"

# Run the script for each outcome type
```

## Expected Outputs

Running the full pipeline will generate:

### Model Files
- `random_forest_model_optimal_eGFR.rds`
- `random_forest_model_optimal_DGF.rds`
- `KDPI_model_eGFR.rds`

### Performance Metrics
- `test_MSEs_rf_KDPI.csv` (for eGFR)
- `test_AUCs_rf_KDPI.csv` (for DGF)
- `DGF_Youden_Index.csv` (optimal threshold)

### Predictions
- `Predicted_eGFR_rf_train_rec_code.csv`
- `Predicted_eGFR_rf_test_rec_code.csv`
- `Predicted_DGF_rf_train_rec_code.csv`
- `Predicted_DGF_rf_test_rec_code.csv`
- `rf_predictions_excluded_eGFR.csv`
- `rf_predictions_excluded_DGF.csv`

### Visualizations
The scripts automatically generate plots including:
- Feature importance bar plots
- CKD stage distribution comparisons
- ROC curves (for DGF)
- Predicted vs. true eGFR scatterplots

## Troubleshooting

### "Cannot find file" errors
Make sure you're in the correct working directory and all required files are present.

### Missing package errors
Install any missing packages using `install.packages("package_name")`

### Results Variability
Results may vary from the published analysis due to:
- Differences in training/testing cohorts
- Bootstrap resampling procedures
- Optimization of machine learning models over hyperparameters
- Cross-validation procedures
- Randomness in MRMR feature selection
- Permutation-based feature importance calculations

This variability is expected and inherent to machine learning methods involving stochastic processes.

### MRMR installation issues
The `mRMRe` package can be tricky to install. Try:
```r
# Option 1: From CRAN
install.packages("mRMRe")

# Option 2: From Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("mRMRe")
```

## Questions?

Open an issue on GitHub or contact jrub@umd.edu.
