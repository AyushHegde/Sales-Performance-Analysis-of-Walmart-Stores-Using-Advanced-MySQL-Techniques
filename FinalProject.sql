USE walmart;
CREATE TABLE WalmartSalesData2 (
    InvoiceID VARCHAR(50),
    Date DATE,
    Branch VARCHAR(50),
    City VARCHAR(50),
    CustomerType VARCHAR(20),
    Gender VARCHAR(10),
    ProductLine VARCHAR(50),
    UnitPrice DECIMAL(10, 2),
    Quantity INT,
    Tax DECIMAL(10, 2),
    TotalAmount DECIMAL(10),
    TIME TIME,
    PaymentMethod VARCHAR(20),
    COGS DECIMAL(10),
    GrossMargin DECIMAL(10),
    GrossIncome DECIMAL(10),
    Rating DECIMAL(4)
);
Select * FROM WalmartSalesData2;

#Task 1: Identifying the Top Branch by Sales Growth Rate
SELECT 
    Branch, 
    DATE_FORMAT(Date, '%Y-%m') AS Month, 
    SUM(TotalAmount) AS Total_Sales
FROM 
    WalmartSalesData2
GROUP BY 
    Branch, 
    Month
ORDER BY 
    Branch, 
    Month;
    
WITH MonthlySales AS (
    SELECT 
        Branch, 
        DATE_FORMAT(Date, '%Y-%m') AS Month, 
        SUM(TotalAmount) AS Total_Sales
    FROM 
        WalmartSalesData2
    GROUP BY 
        Branch, 
        Month
)
SELECT 
    Branch, 
    Month, 
    Total_Sales,
    (Total_Sales - LAG(Total_Sales) OVER (PARTITION BY Branch ORDER BY Month)) / LAG(Total_Sales) OVER (PARTITION BY Branch ORDER BY Month) AS Growth_Rate
FROM 
    MonthlySales
ORDER BY 
    Branch, 
    Month;
#Branch with highest growth rate
WITH MonthlySales AS (
    SELECT 
        Branch, 
        DATE_FORMAT(Date, '%Y-%m') AS Month, 
        SUM(TotalAmount) AS Total_Sales
    FROM 
        WalmartSalesData2
    GROUP BY 
        Branch, 
        Month
),
GrowthRates AS (
    SELECT 
        Branch, 
        Month, 
        (Total_Sales - LAG(Total_Sales) OVER (PARTITION BY Branch ORDER BY Month)) / LAG(Total_Sales) OVER (PARTITION BY Branch ORDER BY Month) AS Growth_Rate
    FROM 
        MonthlySales
)
SELECT 
    Branch, 
    AVG(Growth_Rate) AS Avg_Growth_Rate
FROM 
    GrowthRates
GROUP BY 
    Branch
ORDER BY 
    Avg_Growth_Rate DESC
LIMIT 1;
    

#Task 2: Finding the Most Profitable Product Line for Each Branch
WITH RankedProfits AS (
    SELECT 
        Branch, 
        ProductLine, 
        SUM(GrossIncome) AS Total_Profit,
        ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY SUM(GrossIncome) DESC) AS rn
    FROM 
        WalmartSalesData2
    GROUP BY 
        Branch, 
        ProductLine
)
SELECT 
    Branch, 
    ProductLine, 
    Total_Profit
FROM 
    RankedProfits
WHERE 
    rn = 1;


#Task 3: Analyzing Customer Segmentation Based on Spending
CREATE TEMPORARY TABLE CustomerSpending AS
SELECT 
    InvoiceID, 
    SUM(TotalAmount) AS Total_Spending
FROM 
    WalmartSalesData2
GROUP BY 
    InvoiceID;
-- Rank customers by their total spending
CREATE TEMPORARY TABLE RankedSpending AS
SELECT 
    InvoiceID, 
    Total_Spending,
    NTILE(100) OVER (ORDER BY Total_Spending) AS Spending_Rank
FROM 
    CustomerSpending;
SELECT 
    InvoiceID,
    CASE
        WHEN Spending_Rank > 67 THEN 'High'
        WHEN Spending_Rank BETWEEN 34 AND 67 THEN 'Medium'
        ELSE 'Low'
    END AS Spending_Segment
FROM 
    RankedSpending;
    
    
#Task 4: Detecting Anomalies in Sales Transactions
-- Calculate average sales per product line
WITH AvgSales AS (
    SELECT 
        ProductLine, 
        AVG(TotalAmount) AS Avg_Sales
    FROM 
        WalmartSalesData2
    GROUP BY 
        ProductLine
)
SELECT 
    ws.InvoiceID, 
    ws.Branch, 
    ws.City, 
    ws.ProductLine, 
    ws.TotalAmount,
    avg.Avg_Sales,
    (ws.TotalAmount - avg.Avg_Sales) / avg.Avg_Sales AS Deviation
FROM 
    WalmartSalesData2 AS ws
JOIN 
    AvgSales AS avg ON ws.ProductLine = avg.ProductLine
WHERE 
    ABS((ws.TotalAmount - avg.Avg_Sales) / avg.Avg_Sales) > 0.5 -- Customize this threshold as needed
ORDER BY 
    Deviation DESC;

    
#Task 5: Most Popular Payment Method by City
WITH RankedPayments AS (
    SELECT 
        City, 
        PaymentMethod, 
        COUNT(*) AS Payment_Count,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS rn
    FROM 
        WalmartSalesData2
    GROUP BY 
        City, 
        PaymentMethod
)
SELECT 
    City, 
    PaymentMethod, 
    Payment_Count
FROM 
    RankedPayments
WHERE 
    rn = 1;

    
#Task 6: Monthly Sales Distribution by Gender
SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS Month, 
    Gender, 
    SUM(TotalAmount) AS Total_Sales
FROM 
    WalmartSalesData2
GROUP BY 
    Month, 
    Gender
ORDER BY 
    Month, 
    Gender;
    
    

#Task 7: Best Product Line by Customer Type
WITH BestProductLine AS(
SELECT 
    CustomerType, 
    ProductLine, 
    SUM(TotalAmount) AS Total_Sales,
    ROW_NUMBER() OVER (PARTITION BY CustomerType ORDER BY SUM(TotalAmount) DESC) AS rn
FROM 
    WalmartSalesData2
GROUP BY 
    CustomerType, 
    ProductLine
)
SELECT 
	CustomerType,
    ProductLine,
    Total_Sales
FROM
	BestProductLine
WHERE
		rn=1;


#Task 8: Identifying Repeat Customers
WITH PurchaseDates AS (
    SELECT 
        InvoiceID, 
        Date,
        LAG(Date) OVER (PARTITION BY InvoiceID ORDER BY Date) AS Previous_Purchase
    FROM 
        WalmartSalesData2
)
SELECT 
    InvoiceID, 
    COUNT(*) AS Repeat_Purchases
FROM 
    PurchaseDates
WHERE 
    DATEDIFF(Date, Previous_Purchase) <= 30
GROUP BY 
    InvoiceID
HAVING 
    Repeat_Purchases > 1;


#Task 9: Finding Top 5 Customers by Sales Volume
SELECT 
    InvoiceID, 
    SUM(TotalAmount) AS Total_Sales
FROM 
    WalmartSalesData2
GROUP BY 
    InvoiceID
ORDER BY 
    Total_Sales DESC
LIMIT 5;


#Task 10: Analyzing Sales Trends by Day of the Week
SELECT 
    DAYNAME(Date) AS Day_of_Week, 
    SUM(TotalAmount) AS Total_Sales
FROM 
    WalmartSalesData2
GROUP BY 
    Day_of_Week
ORDER BY 
    FIELD(Day_of_Week, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
