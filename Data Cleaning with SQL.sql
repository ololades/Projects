

-----------Cleaning data in MSSQL
--Read Data
SELECT * FROM Retail.[dbo].[Order details]
SELECT * FROM Retail.[dbo].[List of Orders]


-- Get the number of rows 
SELECT COUNT (*) FROM Retail.[dbo].[Order details]
SELECT COUNT (*) FROM Retail.[dbo].[List of Orders]

-- Get the distinct total number of order id
SELECT DISTINCT (Order_ID) FROM Retail.[dbo].[Order details] -- We have 500 Order ID (no missing values)


-- Extract year, Month, day from Order date using DATEPART() function
SELECT 
    DATEPART(month, order_date) AS Month,
    DATEPART(day, order_date) AS Day,
    DATEPART(year, order_date) AS Year,
    DATENAME(month,order_date) AS Month_name --to convert month number to month name
FROM Retail.[dbo].[List of Orders]


-- create a new table with the extracted columns using SELECT INTO statement 
SELECT 
    DATEPART(month, order_date) AS Month,
    DATEPART(day, order_date) AS Day,
    DATEPART(year, order_date) AS Year,
    DATENAME(month,order_date) AS Month_name,
*
INTO Retail.[dbo].[Date]
FROM Retail.[dbo].[List of Orders]


--Remove duplicates using CTE, ROW_NUMBER, PARTITION BY 
WITH CTE AS
(
    SELECT ROW_NUMBER() OVER (PARTITION BY 
	Amount, Profit, quantity ORDER BY Order_ID) as RowNum, *
    FROM Retail.[dbo].[Order details] 
)
DELETE FROM CTE WHERE RowNum < 1;


-- Correcting error in Price column
UPDATE Retail.[dbo].[Order details] 
SET price = (SELECT AVG(price) FROM Retail.[dbo].[Order details]  WHERE product_name = 'product_name')
WHERE product_name = 'product_name' AND 
	price < (SELECT AVG(price) FROM Retail.[dbo].[Order details]  WHERE product_name = 'product_name');


-- Join two tables 
--Join the Tables (dr; share_death) using LEFT join 
SELECT * FROM Retail.[dbo].[Order details] AS orders 
 LEFT JOIN Retail.[dbo].[List of Orders] AS list
	ON orders.Order_ID = list.Order_ID
	AND list.Order_ID = orders.Order_ID
	--COUNT
	SELECT COUNT (*) FROM Retail.[dbo].[Order details] AS orders 
	LEFT JOIN Retail.[dbo].[List of Orders] AS list
		ON orders.Order_ID = list.Order_ID
		AND list.Order_ID = orders.Order_ID
	

-- Check for missing values on the joined table for amount, profit and Quantity
SELECT COUNT (*) FROM Retail.[dbo].[Order details] AS orders 
LEFT JOIN Retail.[dbo].[List of Orders] AS list
	ON orders.Order_ID = list.Order_ID
	AND list.Order_ID = orders.Order_ID
	WHERE Amount IS NULL AND Profit IS NULL AND Quantity IS NULL   --No missing values 

-- Check outliers on Amount column using interquartile range (IQR) method
WITH CTE AS
(
    SELECT amount,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) OVER() AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) OVER() AS Q3
    FROM Retail.[dbo].[Order details] AS orders 
	LEFT JOIN Retail.[dbo].[List of Orders] AS list
	ON orders.Order_ID = list.Order_ID
	AND list.Order_ID = orders.Order_ID
)
SELECT amount
FROM CTE
WHERE amount < Q1 - 1.5 * (Q3 - Q1) OR amount > Q3 + 1.5 * (Q3 - Q1);

-- Check outliers on Amount column using standard deviation
WITH CTE AS
(
    SELECT amount,
        AVG(amount) OVER() AS Mean,
        STDEV(amount) OVER() AS StdDev
    FROM Retail.[dbo].[Order details] AS orders 
	LEFT JOIN Retail.[dbo].[List of Orders] AS list
	ON orders.Order_ID = list.Order_ID
	AND list.Order_ID = orders.Order_ID
)
SELECT amount
FROM CTE
WHERE amount > Mean + 3 * StdDev OR amount < Mean - 3 * StdDev;


-- Count the distinct number of state
SELECT COUNT (*) FROM Retail.[dbo].[List of Orders]
WHERE state IS NULL AND City IS NULL


-- Replace value i.e  null to  unknown using CASE STATEMENT
SELECT DISTINCT (State), COUNT (State) State_Count
FROM Retail.[dbo].[List of Orders]
GROUP BY (State) 
ORDER BY 1

BEGIN TRANSACTION

SELECT State,
CASE WHEN State IS NULL THEN 'Unknown'
	ELSE State END
FROM Retail.[dbo].[List of Orders]

SELECT city,
CASE WHEN city IS NULL THEN 'Unknown'
	ELSE City END
FROM Retail.[dbo].[List of Orders]

UPDATE [List of Orders]
SET State  =
CASE WHEN State IS NULL THEN 'Unknown'
	ELSE State END
FROM Retail.[dbo].[List of Orders]

UPDATE [List of Orders]
SET City  =
CASE WHEN City IS NULL THEN 'Unknown'
	ELSE City END
FROM Retail.[dbo].[List of Orders]


-- Create condtional column for loss&gain from Profit column
ALTER TABLE Retail.[dbo].[Order details]
ADD Loss_Gain AS (CASE 
                WHEN profit < 0 THEN 'Loss' 
                WHEN profit >= 1 THEN 'Gain' 
                ELSE 'Invalid' 
                END);


--Delete unused columns using DROP function
ALTER TABLE Retail.[dbo].[Order details]
DROP COLUMN column1;

ALTER TABLE Retail.[dbo].[List of Orders]
DROP COLUMN column1, column2;

