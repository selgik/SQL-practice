--select location, date, total_cases, total_deaths, population
--from PortfolioProject..CovidDeaths

-- Looking at total cases vs total deaths
-- SHows likelyhood of dying of covid 19

--select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Perc
--from PortfolioProject..CovidDeaths
--where location like '%singapore%'
--order by 1,2
--;

--Looking at total cases vs population
-- Shows what percentage of population got covid 

--select location, date, total_cases, population, (total_cases/population)*100 as Infect_Perc
--from PortfolioProject..CovidDeaths
--where location like '%singapore%'
--order by 1,2
--;

---- Top countires with highest infection rate
--select location, max(total_cases) as currentinf, population, (max(total_cases)/population)*100 as current_inf_perc
--from PortfolioProject..CovidDeaths
--group by population, location
--order by 4 desc
--;

---- Showing countries with death count per population
--select location, max(cast(total_deaths as int)) as md
--from PortfolioProject..CovidDeaths
--where continent is not null
--group by location
--order by md desc
--;

--Check by continent
--1. I don't know why it's wrong
--select continent, sum(cast(total_deaths as int)) as TotalDeathCount
--from PortfolioProject..CovidDeaths
--where continent is not null
--group by continent
--order by TotalDeathCount desc
;
--2. this is correct syntax
--select location, max(cast(total_deaths as int)) as TotalDeathCount
--from PortfolioProject..CovidDeaths
--where continent is  null
--group by location
--order by TotalDeathCount desc
--;
--3. to verify
--select location, max(cast(total_deaths as int)) as TotalDeathCount
--from PortfolioProject..CovidDeaths
--where continent='Oceania'
--group by location
--order by TotalDeathCount desc
--;

---- Show the continent with the highest death count
--select continent, sum(max(cast(total_deaths as int))) as final
--from PortfolioProject..CovidDeaths
--group by continent
--;

---- Global numbers (1)
--select sum(new_cases) as total_cases, 
--sum(cast(new_deaths as int)) as total_deatsh, 
--sum(cast(new_deaths as int))/sum(new_cases) *100 as perc
--from PortfolioProject..CovidDeaths
--where continent is not null
--order by 1,2


---- Global numbers (2) if you add date, you will see total sum per day
--select date, sum(new_cases) as total_cases, 
--sum(cast(new_deaths as int)) as total_deatsh, 
--sum(cast(new_deaths as int))/sum(new_cases) *100 as perc
--from PortfolioProject..CovidDeaths
--where continent is not null
--group by date
--order by 1,2

--select dea.continent, dea.location, dea.date, vac.new_vaccinations
--,sum(convert(int, vac.new_vaccinations)) 
--over (partition by dea.location
--order by dea.date) as running_total
----dea.date) without order by, it shows total number of vaccinatin. Adding order by date, will show running total.
--from PortfolioProject..CovidDeaths dea 
--join PortfolioProject..Vaccination vac
--	on dea.location=vac.location
--	and dea.date=vac.date
--where dea.continent is not null
--order by 2,3
--;

---- Exercise: using the aggregated value (cts, temp)
--select dea.continent, dea.location, dea.date, vac.new_vaccinations
--,sum(convert(int, vac.new_vaccinations)) 
--over (partition by dea.location
--order by dea.date) as running_total
--, (running_total/population)*100 -- error, we can't use the table we've just created.
--from PortfolioProject..CovidDeaths dea 
--join PortfolioProject..Vaccination vac
--	on dea.location=vac.location
--	and dea.date=vac.date
--where dea.continent is not null
--order by 2,3
;


---- Use CTE: now we can use further calcuations
--with populVSVac_cte (continent, location, date, population, new_vaccinations, rollingpplvacinated)
--as
--(
--select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,sum(convert(int, vac.new_vaccinations)) 
--over (partition by dea.location
--order by dea.date) as running_total
--from PortfolioProject..CovidDeaths dea 
--join PortfolioProject..Vaccination vac
--	on dea.location=vac.location
--	and dea.date=vac.date
--where dea.continent is not null
--)
--select *, (rollingpplvacinated/population)*100 as vaccinated_perc
--from populVSVac_cte



---- Temp Table: 
--drop table if exists #percentppvaccinated
--create table #percentppvaccinated 
--(
--continent nvarchar(255),
--location nvarchar(255),
--date datetime,
--population numeric,
--new_vaccination numeric,
--running_total numeric
--)

--insert into #percentppvaccinated 
--select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--,sum(convert(int, vac.new_vaccinations)) 
--over (partition by dea.location
--order by dea.date) as running_total
--from PortfolioProject..CovidDeaths dea 
--join PortfolioProject..Vaccination vac
--	on dea.location=vac.location
--	and dea.date=vac.date
--where dea.continent is not null

--select *, (running_total/population)*100 as vaccinated_perc
--from #percentppvaccinated

-- Create VIEW to store data for later visualisation

create view percentppvaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(convert(int, vac.new_vaccinations)) 
over (partition by dea.location
order by dea.date) as running_total
from PortfolioProject..CovidDeaths dea 
join PortfolioProject..Vaccination vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null

select * from percentppvaccinated