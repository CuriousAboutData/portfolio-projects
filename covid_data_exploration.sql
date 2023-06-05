SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
WHERE continent <> ''
ORDER BY 1,2 

-- Total Cases vs Total Deaths, and Likelihood of Dying

SELECT location, date, total_cases, total_deaths, 
	(CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0))*100 as death_percentage
FROM dbo.CovidDeaths
WHERE Location like '%Hun%'
	AND continent <> ''
ORDER BY 1,2

-- Total Cases vs Population

SELECT Location, date, total_cases, population,
	(CAST(total_cases AS float) / NULLIF(CAST(population AS float), 0))*100 as infection_percentage
FROM dbo.CovidDeaths
WHERE Location like '%Hun%'
	AND continent <> ''
ORDER BY 1,2

-- countries w/ highest infection rate compared to population

SELECT Location, MAX(total_cases) as HighestInfectionCount, Population,
	MAX((CAST(total_cases AS float) / NULLIF(CAST(population AS float), 0)))*100 as infection_percentage
FROM dbo.CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population
ORDER BY InfectionPercentage DESC

SELECT Location, MAX(CAST(total_deaths AS float)) as total_deaths
FROM CovidDeaths
WHERE continent <> ''
GROUP BY Location
ORDER BY TotalDeaths DESC

-- break things down by continent
-- continents with highest death count 

SELECT continent, MAX(CAST(total_deaths AS float)) as total_deaths
FROM CovidDeaths
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeaths DESC

-- global numbers

SELECT SUM(CAST(new_cases AS float)) AS TotalCases, SUM(CAST(new_deaths AS float)) AS total_deaths, 
	  (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float)))*100 as death_percentage
FROM CovidDeaths
WHERE continent <> ''
ORDER BY 1,2

-- population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3

-- CTE

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''
)
SELECT *, (rolling_people_vaccinated/Population)*100 AS rolling_people_vaccinated
FROM pop_vs_vac

-- temp table to perform calculation on partition by in previous query

DROP TABLE if exists #people_vaccinated
CREATE TABLE #people_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #people_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (rolling_people_vaccinated/Population)*100 AS rolling_vaccination_percentage
FROM #people_vaccinated

CREATE VIEW people_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location 
ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM CovidDeaths dea
	JOIN CovidVaccinations vac
ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent <> ''

SELECT * FROM people_vaccinated 
