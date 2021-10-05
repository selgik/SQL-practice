-- PLEASE REVIEW README FOR DETAILS --

-- 1. BASIC SELECT
-- Comment: .. omits the middle part within the full address
SELECT location, date, total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
;

-- 2. REVIEW DEATH RATE
-- Comment (1): '%???%' enter the country name and run query
-- Comment (2): order by 1,2 <-- numbers represents the column. If coulmn name is too long, use numbers. 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Perc
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%singapore%'
ORDER BY 1,2
;

-- 3. REVIEW INFECTION RATE PER POPULATION
-- Comment: Actually, alias (Infect_Perc) can be improved. Make it more self-explanatory alias.
SELECT location, date, total_cases, population, (total_cases/population)*100 AS Infect_Perc
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%singapore%'
ORDER BY 1,2
;

-- 4. COUNTRIES RANKED BY THE INFECTION RATE
-- Comment (1): total_cases is showing as running total, hence max(total_cases) will be accumulated total cases. 
-- Comment (2): If I want to show total 5 countries, I might have added LIMIT 5 after ORDER BY clause. 
SELECT location, MAX(total_cases) AS currentinf, population, (MAX(total_cases)/population)*100 AS current_inf_perc
FROM PortfolioProject..CovidDeaths
GROUP BY population, location
ORDER BY 4 DESC
;

-- 5. COUNTRIES WITH DEATH COUNT PER POPULATION 
-- Comment (1): column total_deaths is in varchar, hence it needs to be updated as integer for calculation --> CAST(X AS int)
-- Comment (2): in the raw data, continent name (ex. Asia) appeared under location. In order to filter country, those items need to be eliminated with NOT NULL.
SELECT location, MAX(CAST(total_deaths AS INT)) AS md
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY md DESC
;

-- 6. CHECK THE CONTINENT WITH THE HIGHEST DEATH COUNTS
-- Comment (1): Review item 5. Comment (2) as to why continent is null is used.
-- Comment (2): why not group sum(cast(total_deaths)? Because it's derived column. 
-- (NEEDS TO BE REVIEWED) WHY THIS CODE DIDN'T WORK OUT?
-- SELECT continent, sum(cast(total_deaths AS int)) AS TotalDeathCount
-- FROM PortfolioProject..CovidDeaths
-- WHERE continent IS NOT NULL
-- GROUP BY continent
-- ORDER BY TotalDeathCount DESC
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;

-- 7. VERIFY ITEM#6
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent='Oceania'
GROUP BY location
ORDER BY TotalDeathCount DESC
;

-- 8. CONTINENT WITH HIGHTEST DATE COUNTS
-- NEEDS REVIEW: WHERE continent IS NOT NULL
SELECT continent, SUM(MAX(CAST(total_deaths AS INT))) AS final
FROM PortfolioProject..CovidDeaths
GROUP BY continent
;

-- 9. SHOW TOTAL CASES,  DEATTH, DEATH RATE
SELECT SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deatsh, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS perc
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- 10. SHOW TOTAL CASES PER DAY
-- Comment: by adding date, we will see total sum of cases, deaths and death rate per day
SELECT date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_death, 
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100 AS perc
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- 11. PARTITION BY 
-- Comment: similar to group by, but this function assigns the aggregated results to all columns.
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	ac.new_vaccinations, 
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS running_total
	-- Why ORDER BY dea.date? Without it, it will show the total number of vaccinatin. Adding order by date, will show running total.
FROM PortfolioProject..CovidDeaths dea 
	JOIN PortfolioProject..Vaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
;

-- 12-1. PREPARE TO USE CTE
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS running_total
	-- If you are trying to add below it will give error, as we can't use table we've just created
	-- (running_total/population)*100
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..Vaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
;

-- 12-2 CTE: DO A FURTEHR CALCULATION
-- Comment: defined columns within WITH CTE () needs to match with actual CTE columns in terms of number and format
WITH populVSVac_cte (continent, location, date, population, new_vaccinations, rollingpplvacinated)
AS
	(
	SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS running_total
	FROM PortfolioProject..CovidDeaths dea 
	JOIN PortfolioProject..Vaccination vac
	ON dea.location=vac.location AND dea.date=vac.date
	WHERE dea.continent IS NOT NULL
	)
select *, (rollingpplvacinated/population)*100 as vaccinated_perc
from populVSVac_cte
;

-- 13. TEMP TABLE
-- Comment: why DROP? If the table exists, temp won't be created. To overwrite, better to have habit of DROP TABLE when using TEMP table.

DROP TABLE IF EXISTS #percentppvaccinated
CREATE TABLE #percentppvaccinated 
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
running_total numeric
) -- STEP 1: Create

INSERT INTO #percentppvaccinated 
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS running_total
FROM PortfolioProject..CovidDeaths dea 
JOIN PortfolioProject..Vaccination vac
	ON dea.location=vac.location
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL -- STEP 2: Insert

SELECT *, (running_total/population)*100 AS vaccinated_perc
FROM #percentppvaccinated 
;

-- 14. CREATE VIEW TO STORE DATA FOR LATER USE.
CREATE VIEW percentppvaccinated AS

	SELECT dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS running_total
	FROM PortfolioProject..CovidDeaths dea 
	JOIN PortfolioProject..Vaccination vac
		ON dea.location=vac.location
		AND dea.date=vac.date
	WHERE dea.continent IS NOT NULL

SELECT * FROM percentppvaccinated 
;

-- END --
