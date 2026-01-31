# Data and Model Access

## Large Files

Due to GitHub file size limitations, the following files are hosted externally:

### Dataset
- **File**: `Renal_Data.csv` (1.1 MB)
- **Location**: [Google Drive link will be added]
- **Description**: Complete dataset with donor features, pathomic features, and outcomes
- **MD5 checksum**: [To be added for verification]

After downloading, place this file in the `data/` directory.

### Pre-trained Models

All model files are included in this repository under the `models/` directory:

1. **random_forest_model_optimal_eGFR.rds** (734 KB)
   - Random forest for eGFR prediction
   
2. **random_forest_model_optimal_DGF.rds** (75 KB)
   - Random forest for DGF prediction
   
3. **KDPI_model_eGFR.rds** (7 KB)
   - Baseline KDPI linear regression model

These can be loaded directly from the repository.

## Alternative Hosting (Optional)

If you prefer to host the dataset elsewhere:

### Google Drive
1. Upload `Renal_Data.csv` to Google Drive
2. Share with "Anyone with the link can view"
3. Get the shareable link
4. Update the README.md with the link

### Zenodo (Recommended for Research Data)
1. Create a Zenodo account
2. Upload dataset as a new upload
3. Publish and get DOI
4. Add DOI to README.md

### OSF (Open Science Framework)
1. Create OSF project
2. Upload data files
3. Make public
4. Add OSF link to README.md

## File Verification

To verify file integrity after downloading:

### On macOS/Linux:
```bash
md5 data/Renal_Data.csv
```

### On Windows:
```powershell
certutil -hashfile data\Renal_Data.csv MD5
```

Expected MD5 checksum: [To be added]

## Data Dictionary

For detailed information about variables in `Renal_Data.csv`, see the main README.md.

The dataset includes:
- Recipient demographic and clinical data
- Donor demographic and clinical variables
- KDPI scores
- Remuzzi classifications
- AI-derived pathomic features from kidney biopsies
- Computational morphometric features
- Glomerular and vascular granular features
- Outcome variables: 1-year eGFR and Delayed Graft Function (DGF)
