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
- **Download**: [Google Drive Link](https://drive.google.com/file/d/18T2Y90xwVOwHA8zlleTDXX3crGFYoMmy/view?usp=drive_link)
- Contains donor clinical factors, pathomic features, and transplant outcomes
- Features include: donor demographics, clinical variables, KDPI scores, and image-derived features

### Pre-trained Models
Three models are available for download:

1. **random_forest_model_optimal_eGFR.rds** (734 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1fXCbiJqoQYTqJE9LqpZc2LgvmYiViPcf/view?usp=drive_link)
   - Random forest model for predicting 1-year eGFR
   - Trained on MRMR-selected features with optimized hyperparameters

2. **random_forest_model_optimal_DGF.rds** (75 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1v6PLM9a6fFVmShFmnjtCcMGnz1h9fjwl/view?usp=drive_link)
   - Random forest model for predicting delayed graft function
   - Trained on MRMR-selected features with optimized hyperparameters

3. **KDPI_model_eGFR.rds** (7 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1ash39JB202ONFXdyEy6VSxaxZOBLY4n4/view?usp=drive_link)
   - Baseline linear regression model using KDPI alone
   - Used for comparison to machine learning models

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
  "mRMRe",
  "foreach",
  "doParallel"
))
```

### R Version
- Tested on R version 4.0 or higher

## Related Publication

This repository contains code and models for:

**Rodrigues, L., Paul, A.S., Rubin, J., Magdy, H., Gupta, A., Pardinhas, C., Pimenta, C., Fernandes, B., Simões, I., Sousa, V., Figueirerdo, A., Alves, R., Zee, J., Sarder, P. (in preparation). Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes.**

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

### 2. Model Training and Internal Validation

**Scripts**:
- `R/Binary_Internal_Validation_Metrics.R` - for DGF prediction
- `R/Continuous_Internal_Validation_Metrics.R` - for eGFR prediction

These scripts:
- Loop over 1–100 MRMR-selected features automatically
- Perform 5-fold cross-validation with 100 bootstrap resamples (parallelized across available CPU cores)
- Tune random forest hyperparameters (nodesize: 1, 5, 9)
- Compare random forest against KDPI baseline
- Generate internal validation metrics and save one results file per MRMR feature count

**Helper functions**:
- `R/Helper_CV_Functions.R` - Cross-validation utilities
- `R/CKD_Helper_Functions.R` - CKD staging and visualization

### 3. Visualization of Internal Validation Results
**Script**: `R/Visualize_MSE_or_C_training.R`

Visualizes internal validation performance, showing separate lines for each machine learning model and KDPI baseline. Highlights the optimal number of MRMR-selected features across all algorithms (the point on the graph with the lowest MSE or highest AUC).

### 4. Final Model Training and Evaluation
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

## Reproducibility Notes

### Random Seeds
All random processes use seed `382025` for reproducibility:
- Train/test splitting
- MRMR feature selection
- Cross-validation folds
- Random forest training
- Feature importance calculation (permutation importance)

### Results Variability
Results may vary slightly from the published analysis due to:
- Differences in training/testing cohorts
- Bootstrap resampling procedures
- Optimization of machine learning models over hyperparameters
- Cross-validation procedures
- Randomness in MRMR feature selection
- Permutation-based feature importance calculations

This variability is expected and inherent to machine learning methods involving stochastic processes.

## Evaluation Metrics
- **eGFR (continuous)**: Mean Squared Error (MSE)
- **DGF (binary)**: AUC, sensitivity, specificity, Youden's index

## CKD Staging
The analysis includes visualization of Chronic Kidney Disease (CKD) staging:
- Stage 1: eGFR ≥ 90
- Stage 2: eGFR 60-89
- Stage 3a: eGFR 45-59
- Stage 3b: eGFR 30-44
- Stage 4: eGFR 15-29
- Stage 5: eGFR < 15

## File Descriptions

| File | Purpose |
|------|---------|
| `Create_Train_Test_Exclusion_Data.R` | Data preprocessing, feature selection, train/test split |
| `Binary_Internal_Validation_Metrics.R` | Internal validation for DGF prediction |
| `Continuous_Internal_Validation_Metrics.R` | Internal validation for eGFR prediction |
| `Model_Saving_and_Test_Performance_Metrics_with_Exclusion.R` | Final model training and evaluation |
| `Visualize_MSE_or_C_training.R` | Visualization of internal validation performance |
| `Helper_CV_Functions.R` | Cross-validation utility functions |
| `CKD_Helper_Functions.R` | CKD classification and plotting functions |

## Citation

If you use this code or models in your research, please cite:

**Rodrigues, L., Paul, A.S., Rubin, J., Magdy, H., Gupta, A., Pardinhas, C., Pimenta, C., Fernandes, B., Simões, I., Sousa, V., Figueirerdo, A., Alves, R., Zee, J., Sarder, P. (in preparation). Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes.**

```bibtex
@article{rodrigues2026compreps,
  title={Multimodal ComPRePS: Integrating High-dimensional Procurement Biopsy Pathomics and Clinical Data for Prediction of Allograft Outcomes},
  author={Rodrigues, Luis and Paul, Anindya S. and Rubin, Jeremy and Magdy, Haitham and Gupta, Akshita and Pardinhas, Clara and Pimenta, Carolina and Fernandes, Beatriz and Simões, Ilda and Sousa, Vitor and Figueirerdo, Arnaldo and Alves, Rui and Zee, Jarcy and Sarder, Pinaki},
  journal={In preparation},
  year={2026},
  note={Code and models available at: https://github.com/jeremysrubin/procurement-biopsy-pathomics-ml}
}
```

## Author

Jeremy Rubin

## Contact

For questions or issues, please open an issue on GitHub or contact jrub@umd.edu.
