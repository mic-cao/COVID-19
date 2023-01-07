Select *
From PortfolioProject..CovidDeaths
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4

-- review table dimensions
SELECT COUNT(*) as rows
FROM PortfolioProject..CovidDeaths
SELECT count(*) as columns
FROM information_schema.columns
WHERE table_name = 'CovidDeaths';

SELECT COUNT(*) as rows
FROM PortfolioProject..CovidVaccinations 
SELECT count(*) as columns
FROM information_schema.columns
WHERE table_name = 'CovidVaccinations';

-- review data type of each column
Select column_name, data_type from information_schema.columns 
where table_name = 'CovidDeaths'

Select column_name, data_type from information_schema.columns 
where table_name = 'CovidVaccinations' 

-- select data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2 

-- looking at total cases vs total deaths
Select location, date, total_cases, total_deaths, 
	total_deaths/total_cases*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2 

-- looking at total cases vs population
-- shows what percentage of population got covid
Select location, date, total_cases, population, 
	total_cases/population*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2 

-- looking at countries with highest infection rate compared to population
Select location, population, MAX(total_cases) as HighestInfectionCount, 
	MAX(total_cases/population*100) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by location, population
order by PercentPopulationInfected desc

-- show countries with the highest death count
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc

-- break down by continent
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
	and location not in ('World', 'European Union', 'International')
	and location not like '%income%'
Group by location
order by TotalDeathCount desc

-- global numbers
Select date, SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1,2 

-- looking at total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (Partition by dea.location Order by dea.location, dea.date) 
			as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

-- using CTE
; With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (Partition by dea.location Order by dea.location, dea.date) 
			as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- using temp table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (Partition by dea.location Order by dea.location, dea.date) 
			as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
Select *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated

-- create View to store data for later visualizations
Exec('
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (Partition by dea.location Order by dea.location, dea.date) 
			as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location	
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
')
Select *
From PercentPopulationVaccinated



-- create more Views to be used for Tableau
-- 1.
Exec('
Create View Table1 as
Select SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
')
Select *
From Table1

-- 2. 
Exec('
Create View Table2 as
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null 
	and location not in (''World'', ''European Union'', ''International'')
	and location not like ''%income%''
Group by location
--order by TotalDeathCount desc
')
Select *
From Table2

-- 3.
Exec('
Create View Table3 as
Select Location, Population, 
	MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
--order by PercentPopulationInfected desc
')
Select *
From Table3

--

-- 4.
Exec('
Create View Table4 as
Select Location, Population, date, 
	MAX(total_cases) as HighestInfectionCount,  
	Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population, date
--order by PercentPopulationInfected desc
')
Select *
From Table4