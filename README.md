# Procurement Biopsy Pathomics for Kidney Allograft Outcome Prediction

**Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes**

This repository contains code and models for the ComPRePS (Comprehensive Prediction System) framework, which predicts kidney transplant outcomes using machine learning methods integrating procurement biopsy pathomics and clinical data. The analysis focuses on two primary outcomes:
1. **1-year estimated Glomerular Filtration Rate (eGFR)** - continuous outcome
2. **Delayed Graft Function (DGF)** - binary outcome

## Repository Contents

```
procurement-biopsy-pathomics-ml/
├── R/                          # R scripts for analysis
│   ├── Create_Train_Test_Exclusion_Data.R
│   ├── Binary_Internal_Validation_Metrics.R
│   ├── Continuous_Internal_Validation_Metrics.R
│   ├── Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R
│   ├── Visualize_MSE_or_C_training.R
│   ├── Helper_CV_Functions.R
│   └── CKD_Helper_Functions.R
├── models/                     # Saved trained models
│   ├── random_forest_model_optimal_eGFR.rds
│   ├── random_forest_model_optimal_DGF.rds
│   └── KDPI_model_eGFR.rds
├── data/                       # Dataset
│   └── Renal_Data.csv
└── README.md
```

## Data and Models

### Dataset
- **File**: `data/Renal_Data.csv`
- Contains donor clinical factors, pathomic features, and transplant outcomes
- Features include: donor demographics, clinical variables, KDPI scores, and image-derived features

### Pre-trained Models
Three models are available in the `models/` directory:

1. **random_forest_model_optimal_eGFR.rds** (734 KB)
   - Random forest model for predicting 1-year eGFR
   - Trained on MRMR-selected features with optimized hyperparameters

2. **random_forest_model_optimal_DGF.rds** (75 KB)
   - Random forest model for predicting delayed graft function
   - Binary classification model

3. **KDPI_model_eGFR.rds** (7 KB)
   - Baseline linear regression model using KDPI alone
   - Used as a comparator to the random forest model

## Requirements

### R Packages
```r
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
  "mRMRe"
))
```

### R Version
- Tested on R version 4.0 or higher

## Related Publication

This repository contains code and models for:

**Rubin, J., et al. (2026). Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes.** *[Journal Name]*.

Repository: https://github.com/jeremysrubin/procurement-biopsy-pathomics-ml

## Workflow Overview

### 1. Data Preparation and Feature Selection
**Script**: `R/Create_Train_Test_Exclusion_Data.R`

This script:
- Performs train/test split (80/20) stratified by outcome
- Removes features with missing values
- Applies MRMR (minimum Redundancy Maximum Relevance) feature selection
- Handles multicategorical variables
- Saves processed datasets for downstream analysis

**Key function**:
```r
generate_training_testing_exclusion_data(
  input.file.name = "data/Renal_Data.csv",
  num.MRMR.features = 30,  # Number of features to select
  outcome = "C",            # "C" for eGFR, "B" for DGF
  train.sub.name = "train_indices.csv",
  test.sub.name = "test_indices.csv",
  make.split = TRUE         # TRUE for first run with DGF outcome
)
```

**Important**: Run this function first with DGF outcome (`outcome = "B"`, `make.split = TRUE`) to create the train/test split, then use the same split for eGFR prediction.

### 2. Model Training and Cross-Validation

**Scripts**:
- `R/Binary_Internal_Validation_Metrics.R` - for DGF prediction
- `R/Continuous_Internal_Validation_Metrics.R` - for eGFR prediction

These scripts:
- Perform 5-fold cross-validation
- Tune random forest hyperparameters (nodesize)
- Compare random forest against KDPI baseline
- Generate internal validation metrics

**Helper functions**:
- `R/Helper_CV_Functions.R` - Cross-validation utilities
- `R/CKD_Helper_Functions.R` - CKD staging and visualization

### 3. Final Model Training and Evaluation
**Script**: `R/Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R`

This is the main analysis script that:
- Trains optimal random forest model on full training set
- Saves trained models (the .rds files in `models/`)
- Evaluates performance on held-out test set
- Generates predictions for excluded kidneys
- Creates visualizations:
  - Feature importance plots
  - CKD stage distributions
  - ROC curves (for DGF)
  - Predicted vs. true eGFR scatterplots

**Usage**:
```r
# Set outcome type at line 28
outcome <- "C"  # "C" for eGFR, "B" for DGF

# Source required functions
source("R/Helper_CV_Functions.R")
source("R/CKD_Helper_Functions.R")

# Run the script
set.seed(382025)
# Script will automatically load data and generate all outputs
```

### 4. Visualization
**Script**: `R/Visualize_MSE_or_C_training.R`

Visualizes cross-validation performance across different hyperparameter settings.

## Using the Pre-trained Models

### Load a model
```r
# For eGFR prediction
rf_model <- readRDS("models/random_forest_model_optimal_eGFR.rds")

# For DGF prediction
dgf_model <- readRDS("models/random_forest_model_optimal_DGF.rds")
```

### Make predictions
```r
# Prepare your data with the same features used during training
# (See feature selection output from Step 1)

# eGFR prediction
predicted_eGFR <- predict(rf_model, newdata = your_test_data)

# DGF prediction (probabilities)
dgf_probs <- predict(dgf_model, newdata = your_test_data, type = "prob")
```

## Key Features

### Feature Selection
- Uses MRMR algorithm for feature selection
- Handles both continuous and categorical predictors
- Ensures all levels of multicategorical variables are retained
- Filters features by missingness (keeps only complete features)

### Model Comparison
All models are compared against a KDPI baseline:
- **For eGFR**: Linear regression using KDPI
- **For DGF**: KDPI score alone (no model)

### Evaluation Metrics
- **eGFR (continuous)**: Mean Squared Error (MSE)
- **DGF (binary)**: AUC, sensitivity, specificity, Youden's index

### CKD Staging
The analysis includes visualization of Chronic Kidney Disease (CKD) staging:
- Stage 1: eGFR ≥ 90
- Stage 2: eGFR 60-89
- Stage 3a: eGFR 45-59
- Stage 3b: eGFR 30-44
- Stage 4: eGFR 15-29
- Stage 5: eGFR < 15

## Reproducibility Notes

### Random Seeds
All random processes use seed `382025` for reproducibility:
- Train/test splitting
- MRMR feature selection
- Cross-validation folds
- Random forest training
- Feature importance calculation

### Known Limitations
The exact results may vary slightly from the published analysis due to:
- Stochastic nature of random forest algorithm
- Bootstrap resampling in cross-validation
- Computational differences across systems

This is expected and normal for machine learning methods involving randomness.

## File Descriptions

| File | Purpose |
|------|---------|
| `Create_Train_Test_Exclusion_Data.R` | Data preprocessing, feature selection, train/test split |
| `Binary_Internal_Validation_Metrics.R` | Cross-validation for DGF prediction |
| `Continuous_Internal_Validation_Metrics.R` | Cross-validation for eGFR prediction |
| `Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R` | Final model training and evaluation |
| `Visualize_MSE_or_C_training.R` | Visualization of CV performance |
| `Helper_CV_Functions.R` | Cross-validation utility functions |
| `CKD_Helper_Functions.R` | CKD classification and plotting functions |

## Citation

If you use this code or models in your research, please cite:

**Rubin, J., et al. (2026). Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes.** *[Journal Name]*.

```bibtex
@article{rubin2026compreps,
  title={Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes},
  author={Rubin, Jeremy and [Collaborator Names]},
  journal={[Journal Name]},
  year={2026},
  note={Code and models available at: https://github.com/jeremysrubin/procurement-biopsy-pathomics-ml}
}
```

## Author

Jeremy Rubin

## License

[Add your license here]

## Contact

For questions or issues, please open an issue on GitHub or contact [your email].

## Acknowledgments

This work involved collaboration with trauma surgeons, pathologists, and nephrologists at [institution name].
