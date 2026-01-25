# World Layoffs (2022+) - SQL Data Cleaning Project

This project cleans the Kaggle **Layoffs 2022** dataset using SQL (MySQL syntax).  
It follows a typical data-cleaning workflow: **staging → de-duplication → standardization → null handling → remove unusable rows**.

## Dataset
Source: Kaggle — “Layoffs 2022” dataset (loaded into `world_layoffs.layoffs`).

## What this script does

### 1) Create a staging table
- Copies raw data from `world_layoffs.layoffs` into `world_layoffs.layoffs_staging`
- Keeps the original table untouched for safety and repeatability

### 2) Remove duplicates
- Builds `world_layoffs.layoffs_staging2` with an extra `row_num` using `ROW_NUMBER() OVER (...)`
- Deletes duplicate rows where `row_num > 1`

### 3) Standardize and fix common issues
- Converts blank `industry` values to `NULL`
- Fills missing `industry` by matching rows with the same `company` + `location`
- Normalizes crypto-related industry values to `Crypto`
- Removes trailing period in `country` (e.g., `United States.` → `United States`)
- Converts `date` from text to a proper `DATE`

### 4) Remove unusable rows
- Deletes rows where **both** `total_laid_off` and `percentage_laid_off` are `NULL`
- Drops helper column `row_num`

## Output
A cleaned table:
- `world_layoffs.layoffs_staging2`

This table is ready for EDA and analytics.

## How to run
1. Import the Kaggle dataset into MySQL as `world_layoffs.layoffs`
2. Open the SQL script: `data_cleaning_rewrite.sql`
3. Run it top-to-bottom in MySQL Workbench (or any MySQL client)

## Notes
- The script is written for **MySQL 8+** (window functions required).
- If you want the cleaned output in a different table name (e.g., `layoffs_clean`), rename the final table at the end.


**Autor** Randy Philip
