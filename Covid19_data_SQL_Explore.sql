
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidProject..CovidDeaths
Order by 1,2

--Looking at Total Cases and Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercent
From CovidProject..CovidDeaths
Where Location like '%Vietnam%'
Order by 1,2

--Looking at Total Case with Population
-- Showing what percentage of population got covid

Select Location, date, total_cases, population, (total_cases/population)*100 as gotCovidPercent
From CovidProject..CovidDeaths
Order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

Select Location, MAX(total_cases) as HighestInfection, population, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidProject..CovidDeaths
Group by location, population
Order by PercentPopulationInfected DESC

--Showing Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
where continent is not null
Group by location
Order by TotalDeathCount DESC

-- Showing continents with highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidProject..CovidDeaths
where continent is not null
Group by continent
Order by TotalDeathCount DESC


-- Global numbers

 Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
 SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
From CovidProject..CovidDeaths
-- Where Location like '%Vietnam%'
where continent is not null
Order by 1,2



Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(Convert(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidProject..CovidDeaths  dea
Join CovidProject..CovidVaccinations  vac
	On dea.location = vac.location
	and  dea.date= vac.date
Where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..CovidDeaths dea
Join CovidProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    CovidProject..CovidDeaths dea
JOIN 
    CovidProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

SELECT *, 
    (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- Creating View to store data for later visualizations

DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    CovidProject..CovidDeaths dea
JOIN 
    CovidProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
