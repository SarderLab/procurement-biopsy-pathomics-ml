# Script Documentation

Detailed documentation for each R script in the repository.

---

## Data Preparation

### `Create_Train_Test_Exclusion_Data.R`

**Purpose**: Main data preprocessing and feature selection pipeline

**Key Function**: `generate_training_testing_exclusion_data()`

**Parameters**:
- `input.file.name`: Path to raw data CSV
- `num.MRMR.features`: Number of features to select (default: 30)
- `outcome`: "C" for eGFR (continuous) or "B" for DGF (binary)
- `train.sub.name`: Filename to save/load training indices
- `test.sub.name`: Filename to save/load testing indices  
- `make.split`: TRUE to create new split, FALSE to use existing

**What it does**:
1. Loads raw kidney transplant data
2. Creates 80/20 train/test split (stratified by outcome)
3. Removes date columns and unwanted variables
4. Handles KDPI scores separately for baseline comparison
5. Processes donor variables (categorical → dummy coding)
6. Removes features with any missing values
7. Performs MRMR feature selection
8. Handles multicategorical variables (keeps all levels together)
9. Saves processed data for both transplanted and excluded kidneys

**Outputs**:
- `[outcome]_features_outcome_KDPI_train.csv`: Training features + outcome + KDPI
- `[outcome]_features_outcome_KDPI_test.csv`: Testing features + outcome + KDPI
- `[outcome]_features_excluded_with_slide_num.csv`: Features for excluded kidneys
- `[outcome]_rec_train_code.csv`: Training recipient codes
- `[outcome]_rec_test_code.csv`: Testing recipient codes
- `train_indices.csv`: Training set indices (first run only)
- `test_indices.csv`: Testing set indices (first run only)

**Important Notes**:
- Run with DGF outcome FIRST (`outcome="B"`, `make.split=TRUE`) to create train/test split
- Then use same split for eGFR (`outcome="C"`, `make.split=FALSE`)
- All random processes use seed 382025

---

## Internal Validation and Hyperparameter Tuning

### `Binary_Internal_Validation_Metrics.R`

**Purpose**: Internal validation for DGF (binary outcome) prediction

**What it does**:
1. Loads training data for DGF prediction
2. Sets up hyperparameter grid for random forest:
   - Node sizes: 1, 5, 9
   - Number of trees: 500 (fixed)
3. Performs 5-fold cross-validation for each hyperparameter
4. Evaluates using C-statistic (AUC)
5. Compares against KDPI baseline
6. Uses bootstrap resampling (100 iterations) for stable estimates
7. Saves optimal hyperparameters and performance metrics

**Outputs**:
- `nodesize_best_rf_DGF.csv`: Optimal node size
- `C_stats_all_nodesizes_DGF.csv`: Performance across all hyperparameters
- `training_DGF_prob.csv`: Predicted DGF probabilities on training data
- Visualization plots (when `Visualize_MSE_or_C_training.R` is run)

### `Continuous_Internal_Validation_Metrics.R`

**Purpose**: Internal validation for eGFR (continuous outcome) prediction

**What it does**:
1. Loads training data for eGFR prediction
2. Same hyperparameter grid as binary version (node sizes: 1, 5, 9)
3. Performs 5-fold cross-validation
4. Evaluates using Mean Squared Error (MSE)
5. Compares against KDPI linear regression baseline
6. Bootstrap resampling (100 iterations) for stable estimates
7. Tracks CKD stage distributions across bootstraps

**Outputs**:
- `nodesize_best_rf_eGFR.csv`: Optimal node size
- `MSE_all_nodesizes_eGFR.csv`: Performance across hyperparameters
- `training_eGFR_rf_and_KDPI.csv`: Predicted eGFRs on training data
- `CKD_staging_median_bootstrap.csv`: Median CKD stage distributions across bootstraps

---

## Visualization

### `Visualize_MSE_or_C_training.R`

**Purpose**: Visualize internal validation performance across hyperparameters

**What it does**:
1. Loads saved internal validation results
2. Reads performance metrics for each node size
3. Creates line plot showing:
   - X-axis: Node size
   - Y-axis: MSE (eGFR) or C-statistic (DGF)
   - Separate lines for each machine learning model and KDPI baseline
4. Highlights the optimal number of MRMR-selected features across all algorithms (the point on the graph with the lowest MSE or highest AUC)

**Configuration**:
Change outcome type at top of script:
```r
outcome <- "C"  # or "B" for DGF
```

**Usage**: Run after internal validation scripts

---

## Final Model Training and Evaluation

### `Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R`

**Purpose**: Main analysis script - trains final models and evaluates on test set

**Configuration** (line 28):
```r
outcome <- "C"  # Change to "B" for DGF
```

**For eGFR (outcome = "C")**:

What it does:
1. Loads optimal hyperparameters from internal validation
2. Trains final RF model on full training set
3. Trains KDPI linear regression baseline
4. Saves both models as .rds files
5. Evaluates on held-out test set
6. Generates predictions for excluded kidneys
7. Creates visualizations:
   - Predicted vs. true eGFR scatterplots (RF and KDPI)
   - CKD stage distributions (training and test)
   - Feature importance bar plot

Outputs:
- `random_forest_model_optimal_eGFR.rds`: Trained RF model
- `KDPI_model_eGFR.rds`: Trained KDPI model
- `test_MSEs_rf_KDPI.csv`: Test set performance metrics
- `Predicted_eGFR_rf_train_rec_code.csv`: Training predictions
- `Predicted_eGFR_rf_test_rec_code.csv`: Test predictions
- `rf_predictions_excluded_eGFR.csv`: Predictions for excluded kidneys
- Multiple plots (saved as plot windows)

**For DGF (outcome = "B")**:

What it does:
1. Same model training process
2. Evaluates using AUC instead of MSE
3. Creates ROC curves
4. Calculates Youden's index (optimal threshold)
5. Generates probability predictions

Outputs:
- `random_forest_model_optimal_DGF.rds`: Trained RF model
- `test_AUCs_rf_KDPI.csv`: Test set AUC values
- `DGF_Youden_Index.csv`: Optimal classification threshold
- `Predicted_DGF_rf_train_rec_code.csv`: Training probabilities
- `Predicted_DGF_rf_test_rec_code.csv`: Test probabilities
- `rf_predictions_excluded_DGF.csv`: Probabilities for excluded kidneys
- ROC curve plot
- Feature importance plot

**Feature Importance**:
- Uses permutation importance via `permimp` package
- Negative values set to 0 (indicates no predictive value)
- L1 normalization for interpretability
- Shows top 15 features

---

## Helper Functions

### `Helper_CV_Functions.R`

**Key Functions**:

1. `CV.make.folds(nTrain)`
   - Creates 5 random folds for cross-validation
   - Ensures roughly equal fold sizes
   - Returns list of 5 index vectors

2. `CV.avg.all.folds(X.train, Y.train, algorithm, outcome, lambda)`
   - Performs 5-fold CV for a given algorithm
   - For binary outcomes: ensures each fold has both classes
   - Computes average performance across folds
   - Supports: random forest, LASSO, ridge, elastic net, KDPI

3. Algorithm-specific training functions:
   - `CV.train.rf.binary()` / `CV.train.rf.continuous()`
   - `CV.train.lasso()`, `CV.train.ridge()`, `CV.train.enet()`
   - `CV.train.baseline.KDPI.binary()` / `CV.train.baseline.KDPI.continuous()`

**Usage**: Sourced by the internal validation scripts

### `CKD_Helper_Functions.R`

**Key Functions**:

1. `classify_ckd(egfr)`
   - Takes eGFR value(s)
   - Returns CKD stage classification
   - Stages: 1 (≥90), 2 (60-89), 3a (45-59), 3b (30-44), 4 (15-29), 5 (<15)

2. `get_ckd_frequencies(egfr_vector)`
   - Takes vector of eGFR values
   - Returns frequency table of CKD stages
   - Ensures all stages present (with 0s if needed)

3. `plot_CKD_distributions(CKD_df, cohort)`
   - Takes 3×6 data frame (true/RF/KDPI × 6 CKD stages)
   - `cohort`: "train" or "test" for plot title
   - Creates side-by-side bar plots comparing distributions
   - Uses ggplot2 with custom styling

**Usage**: Sourced by the main analysis script for CKD visualizations

---

## Typical Workflow

### First Time Setup (DGF)
```r
# 1. Generate train/test split
source("R/Create_Train_Test_Exclusion_Data.R")
result <- generate_training_testing_exclusion_data(
  "data/Renal_Data.csv", 30, "B", 
  "train_indices.csv", "test_indices.csv", TRUE
)

# 2. Internal validation (required)
source("R/Binary_Internal_Validation_Metrics.R")

# 3. Visualize internal validation results
source("R/Visualize_MSE_or_C_training.R")

# 4. Train final model and evaluate
source("R/Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R")
```

### eGFR Analysis (using same train/test split)
```r
# 1. Process data with existing split
source("R/Create_Train_Test_Exclusion_Data.R")
result <- generate_training_testing_exclusion_data(
  "data/Renal_Data.csv", 30, "C",
  "train_indices.csv", "test_indices.csv", FALSE
)

# 2-4: Same as above, updating outcome in each script
```

---

## Dependencies by Script

### All Scripts
- Base R
- Common: `dplyr`, `ggplot2`

### Create_Train_Test_Exclusion_Data.R
- `caret` (for stratified splitting)
- `mRMRe` (for feature selection)
- `stringr` (string manipulation)

### Binary/Continuous_Internal_Validation_Metrics.R
- `randomForest`
- `glmnet` (LASSO/ridge, though not used in final models)
- `permimp` (variable importance)

### Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R
- `randomForest`
- `permimp`
- `pROC` (ROC curves, AUC)
- `tidyr`, `gridExtra` (visualization)
