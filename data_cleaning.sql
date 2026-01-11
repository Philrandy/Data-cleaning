SELECT *
FROM world_layoffs.layoffs;

-- ------------------------------------------------------------
-- 1) Create a staging table (keeps raw table unchanged)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS world_layoffs.layoffs_staging;

CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;

-- ------------------------------------------------------------
-- 2) Remove duplicates using ROW_NUMBER()
--    (Create a second staging table with helper row_num)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS world_layoffs.layoffs_staging2;

CREATE TABLE world_layoffs.layoffs_staging2 (
  company                TEXT,
  location               TEXT,
  industry               TEXT,
  total_laid_off          INT,
  percentage_laid_off     TEXT,
  `date`                  TEXT,
  stage                  TEXT,
  country                TEXT,
  funds_raised_millions    INT,
  row_num                 INT
);

INSERT INTO world_layoffs.layoffs_staging2
(
  company,
  location,
  industry,
  total_laid_off,
  percentage_laid_off,
  `date`,
  stage,
  country,
  funds_raised_millions,
  row_num
)
SELECT
  company,
  location,
  industry,
  total_laid_off,
  percentage_laid_off,
  `date`,
  stage,
  country,
  funds_raised_millions,
  ROW_NUMBER() OVER (
    PARTITION BY
      company,
      location,
      industry,
      total_laid_off,
      percentage_laid_off,
      `date`,
      stage,
      country,
      funds_raised_millions
  ) AS row_num
FROM world_layoffs.layoffs_staging;

-- Delete duplicates (keep row_num = 1)
DELETE
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

-- ------------------------------------------------------------
-- 3) Standardize data / fix common quality issues
-- ------------------------------------------------------------

-- 3.1) Make blanks easier to work with
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- 3.2) Fill missing industry from other rows with same company + location
UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
  ON t1.company = t2.company
 AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- 3.3) Normalize crypto labels (e.g., "Crypto Currency", "CryptoCurrency", etc.)
UPDATE world_layoffs.layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3.4) Remove trailing period from country values
UPDATE world_layoffs.layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%.';

-- 3.5) Convert date text -> DATE
UPDATE world_layoffs.layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL AND `date` <> '';

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ------------------------------------------------------------
-- 4) Remove unusable rows
--    (Rows where both total_laid_off and percentage_laid_off are NULL)
-- ------------------------------------------------------------
DELETE
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- ------------------------------------------------------------
-- 5) Drop helper column
-- ------------------------------------------------------------
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;

-- Final check
SELECT *
FROM world_layoffs.layoffs_staging2;
