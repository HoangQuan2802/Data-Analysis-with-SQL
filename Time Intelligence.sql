USE AdventureWorksDW2019; 

  

WITH CTE AS  -- Đổi tên thành tên có ý nghĩa hơn.  Sales_Sumarize 

( 

SELECT 

CAST(Sales.OrderDate as date) AS OrderDate 

,YEAR(Sales.OrderDate) AS OrderYear 

,MONTH(Sales.OrderDate) AS OrderMonth 

,Territories.[SalesTerritoryRegion] AS Territory 

,SUM(Sales.[SalesAmount]) AS InternetSales 

FROM [dbo].[FactInternetSales] AS Sales 

    JOIN [dbo].[DimDate] AS Calendar ON Sales.[OrderDateKey]=Calendar.[DateKey] 

    JOIN [dbo].[DimSalesTerritory] AS Territories ON Sales.[SalesTerritoryKey]=Territories.SalesTerritoryKey 

GROUP BY YEAR(Sales.OrderDate) 

    ,    MONTH(Sales.OrderDate) 

    ,    CAST(Sales.OrderDate as date)  -- Đảm bảo không nhầm lẫn khi tính toán có thời gian. 

    ,    Territories.[SalesTerritoryRegion] 

) 

  

  

--CREATE TABLE WITH WINDOWED FUNCTION-- 

SELECT 

CY.OrderYear AS OrderYear 

,CY.OrderMonth AS OrderMonth 

,CY.Territory AS Territory 

,SUM(CY.InternetSales) OVER (PARTITION BY CY.OrderYear, CY.Territory ORDER BY CY.OrderMonth) AS Sales_CurrentMonth 

,SUM(CY.InternetSales) OVER (PARTITION BY CY.OrderYear, CY.OrderMonth, CY.Territory ORDER BY CY.OrderDate) AS Sales_YTD 

,SUM(SMLY.InternetSales) OVER (PARTITION BY SMLY.OrderYear, SMLY.Territory ORDER BY SMLY.OrderMonth) AS Sales_SameMonthLastYear 

,( 

SUM(CY.InternetSales) OVER (PARTITION BY CY.OrderYear, CY.Territory ORDER BY CY.OrderMonth)-SUM(SMLY.InternetSales)  

OVER (PARTITION BY SMLY.OrderYear, SMLY.Territory ORDER BY SMLY.OrderMonth)) 

/SUM(CY.InternetSales) OVER (PARTITION BY CY.OrderYear, CY.Territory ORDER BY CY.OrderMonth) AS GrowthRate 

,AVG(CY.InternetSales) OVER (PARTITION BY CY.Territory ORDER BY CY.OrderDate ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS Sales_30DaysAverage 

FROM CTE AS CY 

LEFT JOIN CTE AS SMLY 

ON  DAY(CY.OrderDate) = DAY(SMLY.OrderDate) 

AND CY.OrderMonth = SMLY.OrderMonth 

AND CY.OrderYear = SMLY.OrderYear+1 

AND CY.Territory = SMLY.Territory 

ORDER BY CY.OrderYear DESC 

        , CY.OrderMonth DESC 

        , CY.OrderDate DESC 

        , CY.Territory ASC 

  

 

 

 