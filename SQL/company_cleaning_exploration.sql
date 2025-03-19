----- DATA CLEANING -----


--adding continent column to table companies so we can analyze regionality
ALTER TABLE companies
ADD continent NVARCHAR(50);

UPDATE companies
SET companies.continent = column1 FROM companies JOIN continents ON country = column2;


-- deleting duplicate rows
WITH CTE AS
(SELECT c.rank, ROW_NUMBER() OVER(PARTITION BY c.rank, c.organizationName, c.revenue ORDER BY c.rank) AS duplicate
FROM companies c)

DELETE FROM CTE WHERE duplicate > 1;


-- creating a row id, setting it as PK, so that we can do easier joins
ALTER TABLE companies
ADD ID INT IDENTITY(1,1)

ALTER TABLE companies
ADD CONSTRAINT PK_companies PRIMARY KEY(ID)


-- deleting 'M' and 'B' from the money values, so that we can convert them to numeric types
UPDATE companies
SET revenue = new_revenue,
	profits = new_profits,
	assets = new_assets,
	marketValue = new_market_value
FROM 
(SELECT	  ID, 
		  CASE	
			WHEN revenue LIKE '%B' THEN CAST(REPLACE(revenue, 'B', '') AS DECIMAL(18,2)) * 1000000000
			WHEN revenue LIKE '%M' THEN CAST(REPLACE(revenue, 'M', '') AS DECIMAL(18,2)) * 1000000
		  END AS new_revenue,
		  CASE	
			WHEN profits LIKE '%B' THEN CAST(REPLACE(profits, 'B', '') AS DECIMAL(18,2)) * 1000000000
			WHEN profits LIKE '%M' THEN CAST(REPLACE(profits, 'M', '') AS DECIMAL(18,2)) * 1000000
		  END AS new_profits,
		  CASE	
			WHEN assets LIKE '%B' THEN CAST(REPLACE(REPLACE(assets, ',', ''), 'B', '') AS DECIMAL(18,2)) * 1000000000
			WHEN assets LIKE '%M' THEN CAST(REPLACE(REPLACE(assets, ',', ''), 'M', '') AS DECIMAL(18,2)) * 1000000
		  END AS new_assets,
		  CASE	
			WHEN marketValue LIKE '%B' THEN CAST(REPLACE(REPLACE(marketValue, ',', ''), 'B', '') AS DECIMAL(18,2)) * 1000000000
			WHEN marketValue LIKE '%M' THEN CAST(REPLACE(REPLACE(marketValue, ',', ''), 'M', '') AS DECIMAL(18,2)) * 1000000
		  END AS new_market_value
		FROM companies) new_money JOIN companies c ON c.ID = new_money.ID;


-- changing column types
ALTER TABLE companies
ALTER COLUMN revenue DECIMAL(18,2)
ALTER TABLE companies
ALTER COLUMN profits DECIMAL(18,2)
ALTER TABLE companies
ALTER COLUMN assets DECIMAL(18,2)
ALTER TABLE companies
ALTER COLUMN marketValue DECIMAL(18,2)


-- changing string values in rank to integer values and changing the column type to integer
UPDATE companies 
SET rank = new_rank
FROM
(SELECT ID, 
	   CAST(REPLACE(rank, ',', '') AS INTEGER) AS new_rank
FROM companies) CTE JOIN companies c ON c.ID = CTE.ID;

ALTER TABLE companies
ALTER COLUMN rank INTEGER

-- now we can order by rank
SELECT organizationName, rank FROM companies ORDER BY rank;


----- FEATURE ENGINEERING -----------

ALTER TABLE companies
ADD profitMargin DECIMAL(18,2);

UPDATE companies
SET companies.profitMargin = (profits / revenue) * 100;

-- Adding return on assets column
ALTER TABLE companies
ADD returnOnAssets DECIMAL(18,2);

UPDATE companies
SET companies.returnOnAssets = (profits / assets) * 100;


----- DATA EXPLORATION -----

-- percentages of top 2000 companies by origin continent
SELECT continent, CAST(100 * COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER ()  AS continent_percentage 
FROM companies 
GROUP BY continent
ORDER BY continent_percentage DESC;


-- percentages of top 2000 companies by origin country
SELECT country, CAST(100 * COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER ()  AS country_percentage 
FROM companies 
GROUP BY country
ORDER BY country_percentage DESC;

-- Top 10 organizations by profit margin
SELECT TOP(10) organizationName, profitMargin
FROM companies
ORDER BY profitMargin DESC;

-- top 3 companies of each top 10 country(ranked by number of companies in the country)
WITH ranked_companies AS 
(SELECT country, organizationName, ROW_NUMBER() OVER (PARTITION BY country ORDER BY rank ASC) AS country_rank
FROM companies), 
top_countries AS 
(SELECT TOP 10 country, COUNT(organizationName) AS num_of_companies
FROM companies
GROUP BY country
ORDER BY num_of_companies DESC)

SELECT rc.country, rc.organizationName, country_rank 
FROM ranked_companies rc JOIN top_countries tc ON rc.country = tc.country
WHERE country_rank < 4
ORDER BY num_of_companies DESC;