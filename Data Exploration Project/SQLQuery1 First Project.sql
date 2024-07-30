/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From portfolio_project..CovidDeaths
Where continent is not null 
order by 3,4


-- Selecting Data to start with :-

Select Location, date, total_cases, new_cases, total_deaths, population
From portfolio_project..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths (Death percentage):-

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From portfolio_project..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Population (Infection rate) :-

Select Location, date, Population, total_cases,  (total_cases/population)*100 as Infection_rate
From portfolio_project..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate :-

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From portfolio_project..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From portfolio_project..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Showing contintents with the highest death count per population


Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From portfolio_project..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From portfolio_project..CovidDeaths
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations (TotalPeopleVaccinated) :-

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalPeopleVaccinated
From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE for Vaccination Rate:-

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalPeopleVaccinated
From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 as Vaccination_Rate
From PopvsVac



-- Using Temp Table for Vaccination Rate:-

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalPeopleVaccinated

From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as Vaccination_Rate
From #PercentPopulationVaccinated


--Creating View :-

create view TotalPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as TotalPeopleVaccinated

From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select * from TotalPopulationVaccinated

