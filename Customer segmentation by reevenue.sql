WITH Customer_OrderDate_Sales AS (
SELECT
CAST(Sales.[OrderDate] as date) AS OrderDate
,Customer.[CustomerKey] AS Customer
,SUM(Sales.[SalesAmount]) AS Revenue
,RANK() OVER (PARTITION BY Customer.[CustomerKey] ORDER BY CAST(Sales.[OrderDate] as date) DESC) AS DateRank
FROM [dbo].[FactInternetSales] AS Sales
JOIN [dbo].[DimDate] AS Calendar
ON Sales.[OrderDateKey] = Calendar.[DateKey]
JOIN [dbo].[DimCustomer] AS Customer
ON Sales.[CustomerKey] = Customer.[CustomerKey]
GROUP BY Customer.[CustomerKey],CAST(Sales.[OrderDate] as date)
)

SELECT
Sales.Customer
,Sales.OrderDate
,YEAR(Sales.OrderDate) AS OrderYear
,DATENAME(MONTH,Sales.OrderDate) AS OrderMonth
,RANK() OVER (PARTITION BY Sales.Customer ORDER BY Sales.OrderDate DESC) AS DateRank 
,Sales.Revenue AS Revenue
,SUM(Sales.Revenue) OVER (PARTITION BY Sales.Customer ORDER BY Sales.OrderDate) AS CumulativeRevenue
,(
YEAR(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-YEAR(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-1) AS MonthsFromFirstPurchase
,AVG(Sales.Revenue) OVER (PARTITION BY Sales.Customer,YEAR(Sales.OrderDate) ORDER BY Month(Sales.OrderDate)) AS MonthlyAverageSales
,COUNT(Sales.OrderDate) OVER (PARTITION BY Sales.Customer, YEAR(Sales.OrderDate)) AS YearlyPurchaseFrequency
,CASE WHEN 
(
YEAR(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-YEAR(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-1) >= 12
AND CountTop30Revenue =1 
AND CountTop30Average =1 
THEN 'Gold'
WHEN 
CountTop30Revenue =1 
AND CountTop30Average =1 
THEN 'Silver'
WHEN 
(YEAR(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-YEAR(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-1) >= 12
AND CountTop30Revenue =1
THEN 'Silver'
WHEN 
(YEAR(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MAX(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-YEAR(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))*12 + MONTH(MIN(Sales.OrderDate) OVER (PARTITION BY Sales.Customer))
-1) >= 12
AND CountTop30Average =1
THEN 'Silver'
ELSE 'Potential'
END AS CustomerSegment
FROM Customer_OrderDate_Sales AS Sales
LEFT JOIN (
SELECT TOP 30 PERCENT 
Customer
,OrderDate
,SUM (Revenue) OVER (PARTITION BY Customer ORDER BY OrderDate) AS CumulativeRevenue
,1 AS CountTop30Revenue
FROM Customer_OrderDate_Sales) AS Top30CumulativeSales
ON Sales.Customer = Top30CumulativeSales.Customer
AND Sales.OrderDate = Top30CumulativeSales.OrderDate
LEFT JOIN (
SELECT TOP 30 PERCENT 
Customer
,OrderDate
,AVG(Revenue) OVER (PARTITION BY Customer,YEAR(OrderDate) ORDER BY Month(OrderDate)) AS MonthlyAverageSales
,1 AS CountTop30Average
FROM Customer_OrderDate_Sales) AS Top30AverageSales
ON Sales.Customer = Top30AverageSales.Customer
AND Sales.OrderDate = Top30AverageSales.OrderDate
ORDER BY Customer, OrderDate ASC
