# Details Of database
SELECT * FROM startup_dataset.startup_data;


-- How many startups are profitable vs non-profitable?
select Profitable, count(*) as "Total Startups" 
FROM startup_dataset.startup_data
group by Profitable;

-- Which startups are the most overvalued by valuation-to-revenue ratio?
select `Startup Name`,
round(`Valuation (M USD)`/ nullif(`Revenue (M USD)`,0),2) as `valuation-to-revenue`
FROM startup_dataset.startup_data
ORDER BY `valuation-to-revenue` DESC
LIMIT 5;


-- Which startups have the best funding efficiency? (Valuation / Funding)
select `Startup Name`,
round(`Valuation (M USD)`/ nullif(`Funding Amount (M USD)`,0),2) as `valuation-to-funding`
FROM startup_dataset.startup_data
ORDER BY `valuation-to-funding` DESC
LIMIT 5;

 
-- Are startups founded after 2010 more likely to be profitable?
SELECT CASE WHEN `Year Founded` > 2010 THEN 'After 2010' ELSE 'Before 2010' END AS era,
       SUM(CASE WHEN Profitable = 'Yes' THEN 1 ELSE 0 END) AS profitable_count,
       COUNT(*) AS total_count,
       ROUND(SUM(CASE WHEN Profitable = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS profit_percentage
FROM startup_dataset.startup_data
GROUP BY era;


-- Grouped revenue by funding brackets
SELECT 
  CASE 
    WHEN `Funding Amount (M USD)` < 5 THEN 'Under $5M'
    WHEN `Funding Amount (M USD)` BETWEEN 5 AND 20 THEN '$5M - $20M'
    WHEN `Funding Amount (M USD)` BETWEEN 20 AND 50 THEN '$20M - $50M'
    ELSE 'Above $50M' 
  END AS funding_range,
  COUNT(*) AS startup_count,
  round(AVG(`Revenue (M USD)`),2) AS avg_revenue
FROM startup_dataset.startup_data
GROUP BY funding_range;



-- Top startups by market share within their industry
SELECT *
FROM (
  SELECT *, 
         RANK() OVER (PARTITION BY Industry ORDER BY `Market Share (%)` DESC) AS rnk
  FROM startup_dataset.startup_data
) AS ranked
WHERE rnk = 1;




-- Rank startups by custom health score
SELECT `Startup Name`,
       (CASE WHEN Profitable = 'Yes' THEN 1 ELSE 0 END) * 0.4 +
       (`Revenue (M USD)` / NULLIF(MAX(`Revenue (M USD)`) OVER(), 0)) * 0.3 +
       (`Market Share (%)` / NULLIF(MAX(`Market Share (%)`) OVER(), 0)) * 0.2 +
       ((MAX(Employees) OVER() - Employees) / NULLIF(MAX(Employees) OVER(), 0)) * 0.1 AS health_score
FROM startup_dataset.startup_data
ORDER BY health_score DESC
LIMIT 10;


-- What percentage of startups in each region are profitable?
alter table startup_dataset.startup_data
modify column Profitable varchar(25);

Update startup_dataset.startup_data
set Profitable="Yes"
where Profitable=1;


Update startup_dataset.startup_data
set Profitable="No"
where Profitable='0';

select Region,
Sum(case when Profitable="Yes" then 1 end)*100.0/count(*) as Percentage
FROM startup_dataset.startup_data
group by Region;

-- Which industries have the highest average employee-to-revenue ratio?
select Industry,
round(Avg(Nullif(Employees,0)/`Revenue (M USD)`),3) as `employee-to-revenue ratio`
FROM startup_dataset.startup_data
group by Industry
order by `employee-to-revenue ratio` desc;


-- Identify startups with above-average funding but below-average revenue.
select *
FROM startup_dataset.startup_data
where `Funding Amount (M USD)`> (select Avg(`Funding Amount (M USD)`) FROM startup_dataset.startup_data)
and `Revenue (M USD)`< (select Avg(`Revenue (M USD)`) FROM startup_dataset.startup_data);

--  Which region has the highest average number of funding rounds per startup?
select Region, round(Avg(`Funding Rounds`),0) as "Average Funding Rounds"
FROM startup_dataset.startup_data
group by Region;


-- Which startups have been funded the most relative to their number of employees?
select `Startup Name`,
round(`Funding Amount (M USD)`/nullif(Employees,0),3) as funding_per_employee
FROM startup_dataset.startup_data
order by funding_per_employee desc
limit 10;

-- Identify startups with negative or zero revenue but high valuation
select *
FROM startup_dataset.startup_data
WHERE `Revenue (M USD)` <= 0 AND `Valuation (M USD)` >= 100;

-- Find the top 3 industries with the highest total funding in the last decade (startups founded after 2013).
SELECT Industry,
       round(SUM(`Funding Amount (M USD)`),2)  AS total_funding
FROM startup_dataset.startup_data
WHERE `Year Founded` > 2013
GROUP BY Industry
ORDER BY total_funding DESC
LIMIT 3;




