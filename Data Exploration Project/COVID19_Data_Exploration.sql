/*
============================================================
COVID-19 DATA EXPLORATION
============================================================

Skills Used:
- Joins
- CTEs
- Temporary Tables
- Window Functions
- Aggregate Functions
- Creating Views
- Data Type Conversion
- Data Analysis

Database:
portfolio_project

Tables:
- CovidDeaths
- CovidVaccinations
============================================================
*/


/*
============================================================
1. INITIAL DATA EXPLORATION
============================================================
*/

SELECT *
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 3, 4;


/*
============================================================
2. SELECTING DATA TO START WITH
============================================================
*/

SELECT
    Location,
    Date,
    Total_Cases,
    New_Cases,
    Total_Deaths,
    Population
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, Date;


/*
============================================================
3. TOTAL CASES VS TOTAL DEATHS
   Calculate the percentage of cases that resulted in death.
============================================================
*/

SELECT
    Location,
    Date,
    Total_Cases,
    Total_Deaths,
    (Total_Deaths * 100.0 / NULLIF(Total_Cases, 0)) AS Death_Percentage
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, Date;


/*
============================================================
4. TOTAL CASES VS POPULATION
   Calculate the percentage of the population infected.
============================================================
*/

SELECT
    Location,
    Date,
    Population,
    Total_Cases,
    (Total_Cases * 100.0 / NULLIF(Population, 0)) AS Infection_Rate
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, Date;


/*
============================================================
5. COUNTRIES WITH THE HIGHEST INFECTION RATE
============================================================
*/

SELECT
    Location,
    Population,
    MAX(Total_Cases) AS Highest_Infection_Count,
    MAX(Total_Cases * 100.0 / NULLIF(Population, 0)) AS Percent_Population_Infected
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY Percent_Population_Infected DESC;


/*
============================================================
6. COUNTRIES WITH THE HIGHEST DEATH COUNT
============================================================
*/

SELECT
    Location,
    MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Death_Count DESC;


/*
============================================================
7. CONTINENTS WITH THE HIGHEST DEATH COUNT
============================================================
*/

SELECT
    Continent,
    MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY Total_Death_Count DESC;


/*
============================================================
8. GLOBAL NUMBERS
   Calculate total cases, total deaths, and global
   death percentage.
============================================================
*/

SELECT
    SUM(New_Cases) AS Total_Cases,
    SUM(CAST(New_Deaths AS INT)) AS Total_Deaths,
    SUM(CAST(New_Deaths AS INT)) * 100.0
        / NULLIF(SUM(New_Cases), 0) AS Death_Percentage
FROM portfolio_project..CovidDeaths
WHERE Continent IS NOT NULL;


/*
============================================================
9. TOTAL POPULATION VS VACCINATIONS
   Calculate the rolling number of people vaccinated
   for each location.
============================================================
*/

SELECT
    dea.Continent,
    dea.Location,
    dea.Date,
    dea.Population,
    vac.New_Vaccinations,
    SUM(CONVERT(INT, vac.New_Vaccinations))
        OVER (
            PARTITION BY dea.Location
            ORDER BY dea.Date
        ) AS Total_People_Vaccinated
FROM portfolio_project..CovidDeaths AS dea
JOIN portfolio_project..CovidVaccinations AS vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL
ORDER BY dea.Location, dea.Date;


/*
============================================================
10. USING CTE FOR VACCINATION RATE
============================================================
*/

WITH PopvsVac AS
(
    SELECT
        dea.Continent,
        dea.Location,
        dea.Date,
        dea.Population,
        vac.New_Vaccinations,

        SUM(CONVERT(INT, vac.New_Vaccinations))
            OVER (
                PARTITION BY dea.Location
                ORDER BY dea.Date
            ) AS Rolling_People_Vaccinated

    FROM portfolio_project..CovidDeaths AS dea
    JOIN portfolio_project..CovidVaccinations AS vac
        ON dea.Location = vac.Location
        AND dea.Date = vac.Date
    WHERE dea.Continent IS NOT NULL
)

SELECT
    *,
    (Rolling_People_Vaccinated * 100.0
        / NULLIF(Population, 0)) AS Vaccination_Rate
FROM PopvsVac;


/*
============================================================
11. USING TEMPORARY TABLE FOR VACCINATION RATE
============================================================
*/

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    Rolling_People_Vaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
(
    Continent,
    Location,
    Date,
    Population,
    New_Vaccinations,
    Rolling_People_Vaccinated
)

SELECT
    dea.Continent,
    dea.Location,
    dea.Date,
    dea.Population,
    vac.New_Vaccinations,

    SUM(CONVERT(INT, vac.New_Vaccinations))
        OVER (
            PARTITION BY dea.Location
            ORDER BY dea.Date
        ) AS Rolling_People_Vaccinated

FROM portfolio_project..CovidDeaths AS dea
JOIN portfolio_project..CovidVaccinations AS vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;


SELECT
    *,
    (Rolling_People_Vaccinated * 100.0
        / NULLIF(Population, 0)) AS Vaccination_Rate
FROM #PercentPopulationVaccinated;


/*
============================================================
12. CREATING A VIEW
============================================================
*/

CREATE OR ALTER VIEW TotalPopulationVaccinated AS

SELECT
    dea.Continent,
    dea.Location,
    dea.Date,
    dea.Population,
    vac.New_Vaccinations,

    SUM(CONVERT(INT, vac.New_Vaccinations))
        OVER (
            PARTITION BY dea.Location
            ORDER BY dea.Date
        ) AS Total_People_Vaccinated

FROM portfolio_project..CovidDeaths AS dea
JOIN portfolio_project..CovidVaccinations AS vac
    ON dea.Location = vac.Location
    AND dea.Date = vac.Date
WHERE dea.Continent IS NOT NULL;


/*
============================================================
13. VIEW RESULTS
============================================================
*/

SELECT *
FROM TotalPopulationVaccinated;
