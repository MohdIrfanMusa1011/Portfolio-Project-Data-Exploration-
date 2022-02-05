SELECT * 
FROM CovidDeaths
order by 3,4

SELECT * 
FROM CovidVaccinations
order by 3,4

--Select Data that we are going to be using
--There is a reason why we did the WHERE statement here, some issue with the data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- Looking at total cases vs total deaths in Singapore
-- Shows the likelihood of dying if you get infected
-- I round up the Death_Percentage to 2 d.p. to present the data better

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS Death_Percentage
FROM CovidDeaths
WHERE location = 'Singapore'
AND continent is not null
ORDER BY 1,2

-- Looking at total cases vs population in Singapore
-- Shows the percentage of population that got covid

SELECT location, date, total_cases, population, ROUND((total_cases/population)*100,2) AS Infection_Percentage
FROM CovidDeaths
WHERE location = 'Singapore'
AND continent is not null
ORDER BY 1,2

--Looking at countries with highest infection count & highest infection rate compared to population

SELECT location, population, MAX (total_cases) AS Infection_Count ,MAX (ROUND((total_cases/population)*100,2)) AS Infection_Percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

--Showing countries with Highest Death Count per Population
--Since data type for total_deaths is not int (check under Porfolio Project >> Tables >> CovidDeaths >> Columns) , need to convert to INTEGER using CAST statement
--After quering, there is a problem with location, the continent column is null and the continent is in the location column  

SELECT location, MAX (cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC

--After quering, there is a problem with location, when the continent is in the location(country) column, in the continent column the continent is null
-- Below query can show it

SELECT * 
FROM CovidDeaths
WHERE location IN ('World', 'Upper middle income', 'High income', 'Asia')
order by 3,4

--To solve this we can use WHERE statement, so that we can return only the country

SELECT * 
FROM CovidDeaths
WHERE continent is not null
order by 3,4

-- After identifying the problem, now we can do the query

SELECT location, MAX (cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Exploring the data by continent
--Showing continent with the highest death count per population

SELECT continent, MAX (cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers per day
--We use SUM (New_Cases) because it adds up with the (total_cases) and we can use Aggregate function on it and we can see the total cases per day for every location

SELECT date, SUM (new_cases), SUM (new_deaths)
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Since new_deaths is in VARCHAR data type, we need to convert using CAST to INT to do SUM on it
--Create a global (SUM) death percentage column by dividing new_death/new_case
--Round up to 2 d.p.
--Select Global case, global death, global percentage

SELECT date, SUM (new_cases) AS Total_Case, SUM (CAST(new_deaths AS INT)) AS Total_Deaths,  ROUND (SUM (CAST(new_deaths AS INT))/SUM (new_cases)*100,2) AS Death_Percentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Global total cases, deaths, percentage
SELECT SUM (new_cases) AS Total_Case, SUM (CAST(new_deaths AS INT)) AS Total_Deaths,  
ROUND (SUM (CAST(new_deaths AS INT))/SUM (new_cases)*100,2) AS Death_Percentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at total population vs vaccination
--Need to change data type to INT for number of new_vaccination using CONVERT statement to do SUM
--Error encounter when using CONVERT (INT, ), since the data is too large, need to use CONVERT (BIGINT, )

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Since the new column AccumulativeVacCount can't be divided by population (error), because AccumulativeVacCount is not a 
--real column to show vac %, need to use CTE
--(AccumulationVacCount/population)*100 is to show vac percentage

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
--(AccumulationVacCount/population)*100
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Use CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, AccumulationVacCount)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
--(AcculationVacCount/population)*100
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3 (cannot be in CTE)
)

select *, (AccumulationVacCount/Population)*100
from PopvsVac


--Use TEMP TABLE


CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
AccumulationVacCount numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
--(AcculationVacCount/population)*100
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3 (cannot be in CTE)

select *, (AccumulationVacCount/Population)*100
from #PercentPopulationVaccinated


--Use DROP TABLE IF EXISTS on TEMP TABLE to remove error when we made alteration on the TEMP TABLE query, because the table still exist
--To drop the table and make a change on the temp table, use DROP TABLE IF EXISTS

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
AccumulationVacCount numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
--(AcculationVacCount/population)*100
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3 (cannot be in CTE)

select *, (AccumulationVacCount/Population)*100
from #PercentPopulationVaccinated

--creating VIEWS to store date for visualization

CREATE VIEW PercentPopulationVaccinated

AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS AccumulationVacCount
--(AcculationVacCount/population)*100
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

-- After creating VIEWS, can go to VIEW >> refresh to see the table, and the table we can select
--Can set the views aside so that we can use it or connect to TABLEAU for Visualization

SELECT * FROM PercentPopulationVaccinated








