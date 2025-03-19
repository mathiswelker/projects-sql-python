
----- DATA CLEANING to allow further analysis -----

-- removing table rows filled with column names
DELETE
FROM saxony_auction_data   -- dbo name in SSMS
WHERE info = 'info' AND status = 'status';


-- assigning better column names
EXEC SP_RENAME 'saxony_auction_data.nr', 'auction_id', 'COLUMN';
EXEC SP_RENAME 'saxony_auction_data.sold_at', 'selling_price', 'COLUMN';
EXEC SP_RENAME 'saxony_auction_data.limit_price', 'starting_bid', 'COLUMN';


-- deleting useless column 'column1'
ALTER TABLE saxony_auction_data
DROP COLUMN column1;


-- removing the last three letters, which were the .cent values, which are 0 anyway
UPDATE saxony_auction_data 
SET
	selling_price = LEFT(selling_price, LEN(selling_price) -3),
	starting_bid = LEFT(starting_bid, LEN(starting_bid) -3)


-- removing the '.' and ',' from sold_at and limit_price, so changing the type to numeric is possible
UPDATE saxony_auction_data 
SET
	saxony_auction_data.selling_price = SQ.selling_price,
	saxony_auction_data.starting_bid = SQ.starting_bid
FROM (SELECT	auction_id,
		REPLACE(REPLACE(selling_price, '.', ''), ',', '') selling_price,
		REPLACE(REPLACE(starting_bid, '.', ''), ',', '') starting_bid
	  FROM saxony_auction_data) SQ
JOIN saxony_auction_data	
ON saxony_auction_data.auction_id = SQ.auction_id;


-- assigning more fitting types than nvarchars to the columns
ALTER TABLE saxony_auction_data
ALTER COLUMN selling_price NUMERIC(19,2);
ALTER TABLE saxony_auction_data
ALTER COLUMN starting_bid NUMERIC(19,2);


-- defining auction_id as primary key, because it uniquely identifies row
ALTER TABLE saxony_auction_data
ADD CONSTRAINT auctionPK PRIMARY KEY (auction_id);


-- extracting the city name from 'info' column and adding it as new column
ALTER TABLE saxony_auction_data
ADD city nvarchar(100);

UPDATE saxony_auction_data
SET city = REVERSE(SUBSTRING(REVERSE(info), 1, PATINDEX('%[0-9]%', REVERSE(info)) - 2));


-- delete city name from info column
UPDATE saxony_auction_data
SET info = SUBSTRING(info, 1, (LEN(info) - LEN(city) - 1));

SELECT * from saxony_auction_data;



----- DATA EXPLORATION -----

-- Top 5 highest selling_price/starting_bid ratios
SELECT TOP(5) auction_id, info, city, starting_bid, selling_price, status, CAST(ROUND((selling_price/starting_bid), 2) AS DECIMAL(8,2)) AS price_ratio
FROM saxony_auction_data 
ORDER BY price_ratio DESC


-- Top 5 lowest selling_price/starting_bid ratios
SELECT TOP(5) auction_id, info, city, starting_bid, selling_price, status, CAST(ROUND((selling_price/starting_bid), 2) AS DECIMAL(8,2)) AS price_ratio
FROM saxony_auction_data 
ORDER BY price_ratio ASC;


-- Average starting bid and selling price per city
SELECT auction_id, city, status, starting_bid, selling_price,
		AVG(starting_bid) OVER (PARTITION BY city) AS avg_starting_bid_per_city,
		AVG(selling_price) OVER (PARTITION BY city) AS avg_selling_price_per_city
FROM saxony_auction_data
ORDER BY city;
