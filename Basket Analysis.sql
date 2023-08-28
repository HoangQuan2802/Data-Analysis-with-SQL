--CTE--
WITH CTE AS (
SELECT
CAST(A.[OrderDate] as date) AS OrderDateA
,CAST(B.[OrderDate] as date) AS OrderDateB
,A.[CustomerKey] AS CustomerA
,A.[SalesOrderNumber] AS SalesOrderA
,B.[SalesOrderNumber] AS SalesOrderB
,A.[ProductKey] AS ProductA
,B.[ProductKey] AS ProductB
FROM [AdventureWorksDW2019].[dbo].[FactInternetSales] AS A
JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] AS B
ON A.[CustomerKey] = B.[CustomerKey]
AND A.[ProductKey] <> B.[ProductKey]
),

--CTE2--
CTE2 AS (
SELECT
OrderDateA
,OrderDateB
,SalesOrderA
,SalesOrderB
,ProductA
,ProductB
,CASE  WHEN CAST(RIGHT(SalesOrderA,5) AS INT) = CAST(RIGHT(SalesOrderB,5) AS INT) THEN 'Shared Invoices'
       WHEN OrderDateA < OrderDateB AND DATEDIFF(DAY, OrderDateA, OrderDateB) > 30 THEN 'Buy A Then Buy B'
	   WHEN OrderDateA < OrderDateB AND DATEDIFF(DAY, OrderDateA, OrderDateB) <= 30 THEN 'Buy A Then Buy B Within 1 month'
	   WHEN CAST(RIGHT(SalesOrderA,5) AS INT) = CAST(RIGHT(SalesOrderB,5) AS INT) -2  THEN 'Buy A Then Buy B In Next 2 Orders'
	   ELSE NULL
	   END AS Scenario
,1 AS CountRows
FROM CTE
)

--Basket Analysis--
SELECT
ProductA AS ProductA
,ProductB AS ProductB
,[Buy A Then Buy B]
,[Shared Invoices]
,[Buy A Then Buy B Within 1 month]
,[Buy A Then Buy B In Next 2 Orders]
FROM (SELECT
Scenario
,ProductA
,ProductB
,SUM(CountRows) AS ProductCount
FROM CTE2
WHERE Scenario IS NOT NULL
GROUP BY Scenario, ProductA, ProductB
) AS SourceTable
PIVOT
(
SUM(ProductCount)
FOR Scenario IN ([Buy A Then Buy B], [Shared Invoices], [Buy A Then Buy B Within 1 month], [Buy A Then Buy B In Next 2 Orders])
) AS PivotTable