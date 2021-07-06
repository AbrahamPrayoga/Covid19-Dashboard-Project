copy coviddeath from 'E:\Bram\Data Science\Covid-19 Analysis\CovidDeaths.csv' delimiter ',' CSV header;
copy covidvaccine from 'E:\Bram\Data Science\Covid-19 Analysis\CovidVaccines.csv' delimiter ',' CSV header;

select * from coviddeath;

select location, date, total_cases, new_cases, total_deaths, population
from coviddeath
order by 1,2 asc;

-- how many countries observed?
-- nb: continent null = location is either World, or accumulation of every continent
select count(distinct location) 
from coviddeath
where continent is not null;


-- Total Covid cases of every country until 02/7
select location, max(total_cases) as Total_case 
from coviddeath
where continent is not null
group by 1
having max(total_cases) > 0 
order by max(total_cases)-1 desc ;

-- Total Vaccinated using additional vaccinated because the total_vaccinations give so much nulls. 
-- we are using TEMP TABLE
drop table if exists PercentPopulationVaccinated; 
Create table PercentPopulationVaccinated
(
	continent varchar(50),
	location varchar(50),
	date date,
	population varchar(50),
	additional_vaccinations bigint,
	total_people_vaccinated bigint,
	percentage_pop_vaccinated decimal
);
Insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as PeopleVaccinated,
(sum(vac.new_vaccinations) over (partition by dea.location order by dea.date))/(cast(dea.population as decimal))*100 as percentage_pop_vaccinated
from coviddeath dea join covidvaccine vac
	on dea.location = vac.location 
	and dea.date = vac.date
Select * from PercentPopulationVaccinated;


			   
-- 1. Table 1 Country
-- Total Covid cases, death, percentage_population_infected, death_percentage and vaccinated until 02/07 per country
select dea.location, dea.population, dea.total_cases, dea.total_deaths, vac.total_people_vaccinated,
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected,
vac.percentage_pop_vaccinated,
(cast(dea.total_deaths as decimal)/cast(dea.total_cases as decimal))*100 as death_prob_because_infected 
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null and dea.date = (select max(date)-1 from coviddeath)
order by dea.total_deaths desc

-- Total Covid cases, death, death_percentage and vaccinated until 02/07 per continent
-- select dea.location, dea.total_cases, dea.total_deaths, 
-- (cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected,
-- (cast(dea.total_deaths as decimal)/cast(dea.total_cases as decimal))*100 as death_percentage, 
-- vac.percentage_pop_vaccinated
-- from coviddeath dea join PercentPopulationVaccinated vac on
-- 	dea.location = vac.location and
-- 	dea.date = vac.date
-- where dea.continent is null --and dea.location not in ('World', 'International', 'European Union') 
-- and dea.date = (select max(date) from coviddeath)
-- order by death_percentage desc

-- 2. Table 2 Continent
-- Total Covid cases, death, death_percentage and vaccinated until 02/07 per continent
-- the PercentPopulationVaccinated dont have continent, so we are using total
select dea.location, dea.total_cases, dea.total_deaths, vac.total_people_vaccinated, 
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected, 
(cast(vac.total_people_vaccinated as decimal)/dea.population)*100 as percent_population_vaccinated,
(cast(dea.total_deaths as decimal)/cast(dea.total_cases as decimal))*100 as death_prob_because_infected
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date
where dea.continent is null and dea.date = (select max(date)-1 from coviddeath)
and dea.location not in ('World', 'International', 'European Union')
order by total_deaths desc


-- 3. Table 3 Country over date
-- Total cases, total death (Death Percentage) over time
-- show the chance of dying when we infected by Covid-19
select dea.continent, dea.location, dea.date, dea.population, dea.total_cases, 
dea.total_deaths, vac.total_people_vaccinated, dea.new_cases, dea.new_deaths, vac.additional_vaccinations,
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected,
vac.percentage_pop_vaccinated,
(cast(dea.total_deaths as float(1)) / cast(dea.total_cases as float(1))) * 100 as death_prob_because_infected
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date 
where dea.continent is not null
order by 2,3

-- 4. Table 4 Continent over date
select dea.location, dea.date, dea.population, dea.total_cases, 
dea.total_deaths, vac.total_people_vaccinated, dea.new_cases, dea.new_deaths, vac.additional_vaccinations,
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected,
vac.percentage_pop_vaccinated,
(cast(dea.total_deaths as float(1)) / cast(dea.total_cases as float(1))) * 100 as death_prob_because_infected
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date 
where dea.continent is null and dea.location not in ('World', 'International', 'European Union')
order by 1,2

-- 5. Table 5 World
select dea.location, dea.total_cases, dea.total_deaths, vac.total_people_vaccinated, 
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected, 
(cast(vac.total_people_vaccinated as decimal)/dea.population)*100 as percent_population_vaccinated,
(cast(dea.total_deaths as decimal)/cast(dea.total_cases as decimal))*100 as death_prob_because_infected
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date
where dea.continent is null and dea.date = (select max(date)-1 from coviddeath)
and dea.location like 'World'

-- 6. Table 6 World over date
select dea.location, dea.date, dea.population, dea.total_cases, 
dea.total_deaths, vac.total_people_vaccinated, dea.new_cases, dea.new_deaths, vac.additional_vaccinations,
(cast(dea.total_cases as decimal)/dea.population)*100 as percent_population_infected,
vac.percentage_pop_vaccinated,
(cast(dea.total_deaths as float(1)) / cast(dea.total_cases as float(1))) * 100 as death_prob_because_infected
from coviddeath dea join PercentPopulationVaccinated vac on
	dea.location = vac.location and
	dea.date = vac.date 
where dea.continent is null and dea.location like 'World'
order by 1,2

-- Currently Total cases, total death (Death Percentage), total vaccines by 02/7 in Indonesia
-- show the chance of dying when we infected by Covid-19 in Indonesia
select dea.total_cases, dea.total_deaths, vac.total_vaccinations 
from coviddeath dea join covidvaccine vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.location like 'Indonesia' and dea.date = (select max(date) - 1 from coviddeath)


-- Additional cases vs additional death (Death Percentage) over time in Indonesia
-- show the chance of dying when we infected by Covid-19 in Indonesia
select location, date, new_cases, new_deaths 
from coviddeath


-- Total cases per population every country
-- showing the percentage of population infected by covid
select location, population, max(total_cases) as total_current_case, (cast(max(total_cases) as float(1)) / cast(population as float(1))) * 100 as PercentPopulationInfected
from coviddeath
where continent is not null
group by 1,2
having population > 0
order by PercentPopulationInfected desc;


-- Total death caused by Covid in every Country
-- showing Percentage Population die caused by Covid
select location, population, max(total_deaths) as total_current_death
from coviddeath
where continent is not null
group by 1,2
having population > 0 
order by total_current_death desc;


-- Total case happened in every continent
-- showing the number of cases take place for every continent
select location, max(total_cases) as total_cases
from coviddeath
where continent is null
group by 1
having max(total_cases) > 0 and
	location not in ('World', 'International', 'European Union')
order by total_cases desc;
-- validate by this
select continent, location, max(total_cases) as total_cases
from coviddeath
where continent is not null
group by 1,2 
order by continent, location;


-- Total deaths caused by covid for every continents
-- Show total death happened caused by covid in continents
select location, max(total_deaths) as total_death
from coviddeath
where continent is null
group by 1
having location not in ('World', 'International', 'European Union')
order by total_death desc;
-- validate by this
select continent, location, max(total_deaths) as total_death 
from coviddeath
where continent is not null
group by 1,2
order by continent, location;


-- Trend of additional cases and death per day globally
select date, new_cases, new_deaths
from coviddeath
where continent is null and location like 'World';

-- validate
select date, sum(new_cases) as cases_per_day, sum(new_deaths) as deaths_per_day
from coviddeath
where continent is not null
group by date
order by date;

-- Trend of cases and death day-to-day globally
select date, total_cases, total_deaths
from coviddeath
where continent is null and location like 'World'

-- average of additional cases and death per day
-- select date, new_cases, new_deaths
select total_cases, total_death, avg(new_cases), avg(new_deaths), avg()average_percentage_population_infected
from coviddeath
where continent is null
group by location
having location like 'World';


-- Growth additional cases per day vs vaccinated
select dea.continent, dea.location, dea.date, dea.population, dea.new_cases, dea.new_deaths, vac.new_vaccinations
from coviddeath dea join covidvaccine vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and dea.location like 'Indonesia'
order by 1,2,3;

-- Total People vaccinated (and percentage of population) for every day using CTE 
with popuvac(continent, location, date, population, additional_vaccinated, rolling_people_vaccine)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as PeopleVaccinated
from coviddeath dea join covidvaccine vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
)
select *, cast(rolling_people_vaccine as float(1))/(cast(population as float(1)))*100 as percentage_pop_vaccinated
from popuvac;

