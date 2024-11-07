/*

COVID 19 Statistics Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Link to Dataset: https://ourworldindata.org/covid-deaths 
Data CSV Files: CovidDeaths.csv and CovidVaccinations.csv

*/


-- Taking a first glance at the data we are going to be working with

 SELECT *
 FROM [Portfolio].[dbo].[CovidDeaths]

 SELECT *
 FROM [Portfolio].[dbo].[CovidVaccinations]

 /*
 Looking at the data, noticed there are blank continents.
 When "location" is a continent, "continent" will be left out blank.
 */


 -- Filter Data that we are going to be using
 -- We are going to be focusing on statistics by countries

 SELECT location, date, total_cases, new_cases, total_deaths, population
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE continent != ''
 ORDER BY location, date


 --Data Exploration
 --Total Cases vs Total Deaths
 --Shows probability of dying if you contracted COVID in your country, per day

 SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE continent != ''
 ORDER BY location, date

 -- Selecting data from my hometown

 SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE location = 'Dominican Republic'
 AND continent != ''
 --ORDER BY location, date
 ORDER BY DeathPercentage desc

 -- In the Dominican Republic, the highest probability of dying was around 5% within the first two months of the pandemic


 --Total Cases vs Population
 --Shows what percentage of population got COVID

 SELECT location, date, population, total_cases,(total_cases/population)*100 AS InfectedPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE location = 'Dominican Republic'
 AND continent != ''
 ORDER BY location, date

 -- In the Dominican Republic, the peak of infected population was ~2.5%


 -- Countries with Highest Infection Rate compared to Population

 SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 --WHERE location = 'Dominican Republic'
 WHERE continent != ''
 GROUP BY location, population
 ORDER BY InfectedPercentage desc

 -- Andorra, Montenegro and Czechia are Top 3 in Highest Infection Rate


 -- Countries with Highest Death Count per Population

 SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
 FROM [Portfolio].[dbo].[CovidDeaths]
 --WHERE location = 'Dominican Republic'
 WHERE continent != ''
 GROUP BY location
 ORDER BY TotalDeathCount desc

 -- Some fields in  original data needed data type conversion to perform calculations
 -- Higher population countries came in first



 -- GROUPING DATA BY CONTINENT

 --Showing the continents with the highest death count per population

 SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
 FROM [Portfolio].[dbo].[CovidDeaths]
 --WHERE location = 'Dominican Republic'
 WHERE continent = ''
 GROUP BY location
 ORDER BY TotalDeathCount desc



 -- GLOBAL NUMBERS

 --Daily Statistics
 SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE continent != ''
 GROUP BY date
 ORDER BY 1, 2
 --ORDER BY DeathPercentage DESC

 -- TOP 3 days came in February 2020, due to small amount of total cases probability of dying was really high. Around 22-28%


 --Total Numbers

 SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
 FROM [Portfolio].[dbo].[CovidDeaths]
 WHERE continent != ''
 ORDER BY 1, 2

 -- In average, the probability of dying was ~2%



 -- Total Population vs Vaccinations
 -- Shows Running Total of Population that has recieved at least one Covid Vaccine

 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 , SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningTotalVaccinations
 --, (RunningTotalVaccinations/population)*100
 FROM Portfolio..CovidDeaths dea
 JOIN Portfolio..CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac. date
 WHERE dea.continent != ''
 ORDER BY 2,3


 
 -- Using CTE to perform Calculation on Partition By in previous query
 -- Shows proportion of population vaccinated for COVID

 WITH PopvsVac (continent, location, date, population, new_vaccinations, RunningTotalVaccinations)
 AS
 (
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 , SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningTotalVaccinations
 --, (RunningTotalVaccinations/population)*100
 FROM Portfolio..CovidDeaths dea
 JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac. date
 WHERE dea.continent != ''
 --ORDER BY 2,3
 )
 SELECT *, (RunningTotalVaccinations/population)*100 AS VaccinatedPercentage
 FROM PopvsVac



--Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RunningTotalVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 , SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningTotalVaccinations
 --, (RunningTotalVaccinations/population)*100
 FROM Portfolio..CovidDeaths dea
 JOIN Portfolio..CovidVaccinations vac
 ON dea.location = vac.location
 AND dea.date = vac. date
 WHERE dea.continent != ''
 --ORDER BY 2,3

 SELECT *, (RunningTotalVaccinations/population)*100 AS VaccinatedPercentage
 FROM #PercentPopulationVaccinated




 --Creating View to store previous data for later visualizations

 CREATE VIEW PercentPopulationVaccinated AS
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
 , SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RunningTotalVaccinations
 --, (RunningTotalVaccinations/population)*100
 FROM Portfolio..CovidDeaths dea
 JOIN Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac. date
 WHERE dea.continent != ''
 

SELECT *
FROM PercentPopulationVaccinated


-- View to keep global numbers easy to consult

CREATE VIEW ContinentsTotalDeaths AS
SELECT location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM [Portfolio].[dbo].[CovidDeaths]
WHERE continent = ''
GROUP BY location


SELECT *
FROM ContinentsTotalDeaths