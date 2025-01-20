--  DATA CLEANING
 
 
-- 1. DELETE DUPLICATES
-- 2. STANDARDIZATION
-- 3. DEAL WITH NULL VALUE
-- 4. DELETE COLUMN

SELECT *
FROM layoffs;

-- Create a duplicate table

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

Insert into layoffs_staging
SELECT *
FROM layoffs;

-- 1. DELETE DUPLICATES

SELECT *, 
ROW_NUMBER() Over(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() Over(
PARTITION BY company,location,  industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE Row_Num>1;

WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() Over(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE Row_Num  > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `Row_Num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
SELECT *
FROM layoffs_staging2
WHERE row_num >1;

INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() Over(
PARTITION BY company,location,  industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE Row_Num >1;

SELECT *
FROM layoffs_staging2;

-- Standardizing DATA

SELECT company, (Trim(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = Trim(company);

SELECT Distinct(industry)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT Distinct(country)
FROM layoffs_staging2
ORDER BY 1;

SELECT distinct(country), TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country like 'United states%';

-- Convert text to Date

SELECT `date`,
STR_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;


-- DEAL With NULL and Blank value

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry = 'NULL'
WHERE industry = '';

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
   ON t1.company = t2.company
   AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
   ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- DELETE COLUMN 

ALTER TABLE layoffs_staging2
DROP COLUMN Row_Num;


-- EXPLORATORY DATA ANALYSIS

SELECT *
FROM layoffs_staging2;

-- Maximum lay offs in a single day

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;


SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC limit 10;


-- Top 10 company with highest lay offs

SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC limit 10;


-- layoffs Date range

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Top 10 industries with highest layoff 

SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC limit 10;

-- Top 10 country lay offs Data

SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC limit 10;


-- layoff Year Wise

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- Highest layoff in Stagewise

SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC limit 5;

-- Rolling total laid off

SELECT SUBSTRING(`date`,6,2) AS `month`,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `month`;

SELECT SUBSTRING(`date`,1,7) AS `month`,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `month`
ORDER BY 1 ASC;

WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `month`,SUM(total_laid_off) AS total_off
FROM layoffs_staging2
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`, total_off,
SUM(total_off) OVER(ORDER BY `month`) 
FROM Rolling_Total;

SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

WITH Company_Year (company, years, total_laid_off) As 
(
SELECT company,YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC
),  Company_year_rank As
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM Company_Year
)
SELECT *
FROM Company_year_rank
WHERE ranking <= 5;



















