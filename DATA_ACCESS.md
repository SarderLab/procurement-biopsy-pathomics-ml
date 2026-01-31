# Data and Model Access

## Large Files

Due to GitHub file size limitations, the following files are hosted on Google Drive:

### Dataset
- **File**: `Renal_Data.csv` (1.1 MB)
- **Download**: [Google Drive Link](https://drive.google.com/file/d/18T2Y90xwVOwHA8zlleTDXX3crGFYoMmy/view?usp=drive_link)
- **Description**: Complete dataset with donor features, pathomic features, and outcomes

After downloading, place this file in the `data/` directory.

### Pre-trained Models

All model files are hosted on Google Drive:

1. **random_forest_model_optimal_eGFR.rds** (734 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1fXCbiJqoQYTqJE9LqpZc2LgvmYiViPcf/view?usp=drive_link)
   - Random forest for eGFR prediction
   
2. **random_forest_model_optimal_DGF.rds** (75 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1v6PLM9a6fFVmShFmnjtCcMGnz1h9fjwl/view?usp=drive_link)
   - Random forest for DGF prediction
   
3. **KDPI_model_eGFR.rds** (7 KB)
   - **Download**: [Google Drive Link](https://drive.google.com/file/d/1ash39JB202ONFXdyEy6VSxaxZOBLY4n4/view?usp=drive_link)
   - Baseline KDPI linear regression model

After downloading, place these files in the `models/` directory.

## Data Dictionary

The dataset includes:
- Recipient demographic and clinical data
- Donor demographic and clinical variables
- KDPI scores
- Remuzzi classifications
- AI-derived pathomic features from kidney biopsies
- Computational morphometric features
- Glomerular and vascular granular features
- Outcome variables: 1-year eGFR and Delayed Graft Function (DGF)
