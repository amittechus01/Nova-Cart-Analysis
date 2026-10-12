---Project: NovaCart E-commerce Returns & Delivery Performance Analysis


/* ============================================================
   BUSINESS PROBLEM
   ============================================================
   The company is experiencing delivery delays and a high volume
   of product returns, which are increasing operational costs
   and negatively affecting profitability.

   Management does not have clear visibility into how delivery
   performance is contributing to product returns and financial
   losses.

   The business needs to identify which warehouses, couriers,
   shipping methods, products, categories and return reasons
   are creating the highest operational and financial impact.

   The company also needs to quantify refund, replacement,
   return shipping, processing and restocking costs to understand
   the overall financial impact of product returns.
*/


/* ============================================================
   TABLES USED
   ============================================================
   Customers
   Products
   Warehouses
   Orders
   Delivery
   Returns
   Missing_Items
   Refunds
   Return_Costs
*/


--Total Orders, Customers aur Order Value
SELECT COUNT(*) AS Total_Orders,COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    CAST(SUM(Order_Value) AS DECIMAL(18,2)) AS Total_Order_Value
FROM Orders;

--Order Status Analysis
SELECT Order_Status, COUNT(*) AS Total_Orders,
    CAST(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Order_Percentage
FROM Orders
GROUP BY Order_Status
ORDER BY Total_Orders DESC;

-- Total Returns and Return Rate
SELECT COUNT(DISTINCT o.Order_ID) AS Total_Orders, COUNT(DISTINCT r.Order_ID) AS Total_Returns,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID;


	--Return Reason Analysis
	SELECT Return_Reason,COUNT(*) AS Return_Count,
    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Return_Percentage
FROM Returns
GROUP BY Return_Reason
ORDER BY Return_Count DESC;

--Return Type Analysis

SELECT Return_Type,COUNT(*) AS Total_Returns
FROM Returns
GROUP BY Return_Type
ORDER BY Total_Returns DESC;

--Return Condition Analysis
SELECT
    Return_Condition,
    COUNT(*) AS Return_Count
FROM Returns
GROUP BY Return_Condition
ORDER BY Return_Count DESC;


---Courier-wise Delivery Performance

SELECT Courier,COUNT(*) AS Total_Deliveries,
    SUM(CASE
        WHEN Delivery_Status = 'Delayed' THEN 1
        ELSE 0
    END) AS Delayed_Deliveries,
    CAST(
        SUM(CASE
            WHEN Delivery_Status = 'Delayed' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Delay_Rate FROM Delivery GROUP BY Courier
ORDER BY Delay_Rate DESC;


--Shipping Method Performance

SELECT Shipping_Method,COUNT(*) AS Total_Deliveries,
    SUM(CASE
        WHEN Delivery_Status = 'Delayed' THEN 1
        ELSE 0
    END) AS Delayed_Deliveries,
    CAST(
        SUM(CASE
            WHEN Delivery_Status = 'Delayed' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS Delay_Rate
FROM Delivery
GROUP BY Shipping_Method
ORDER BY Delay_Rate DESC;


--Delivery Delay vs Returns

SELECT d.Delivery_Status,COUNT(DISTINCT d.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT d.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Delivery d
LEFT JOIN Returns r
    ON d.Order_ID = r.Order_ID
GROUP BY d.Delivery_Status
ORDER BY Return_Rate DESC;

--Warehouse return Performance
SELECT
    w.Warehouse_ID,w.Warehouse_Name,  w.Zone, COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
JOIN Warehouses w
    ON o.Warehouse_ID = w.Warehouse_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY
    w.Warehouse_ID,
    w.Warehouse_Name,
    w.Zone
ORDER BY Return_Rate DESC;

--Warehouse + Delivery Delay

SELECT
    w.Warehouse_Name,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(CASE
        WHEN d.Delivery_Status = 'Delayed' THEN 1
        ELSE 0
    END) AS Delayed_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
JOIN Warehouses w
    ON o.Warehouse_ID = w.Warehouse_ID
LEFT JOIN Delivery d
    ON o.Order_ID = d.Order_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY w.Warehouse_Name
ORDER BY Return_Rate DESC;

--Category-wise Return Rate
SELECT
    p.Category,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
JOIN Products p
    ON o.Product_ID = p.Product_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY p.Category
ORDER BY Return_Rate DESC;

---Top 20 Products with Highest Return Rate

SELECT TOP 20
    p.Product_ID, p.Product_Name, p.Category,COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID), 0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
JOIN Products p
    ON o.Product_ID = p.Product_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY
    p.Product_ID,p.Product_Name,  p.Category
HAVING COUNT(DISTINCT o.Order_ID) >= 50
ORDER BY Return_Rate DESC;

---Return Cost Analysis
SELECT
    CAST(SUM(rc.Return_Shipping_Cost) AS DECIMAL(18,2))
        AS Total_Return_Shipping_Cost,
    CAST(SUM(rc.Replacement_Cost) AS DECIMAL(18,2))
        AS Total_Replacement_Cost,
    CAST(SUM(rc.Processing_Cost) AS DECIMAL(18,2))
        AS Total_Processing_Cost,
    CAST(SUM(rc.Restocking_Cost) AS DECIMAL(18,2))
        AS Total_Restocking_Cost,
    CAST(SUM(rc.Return_Shipping_Cost
           + rc.Replacement_Cost
           + rc.Processing_Cost
           + rc.Restocking_Cost) AS DECIMAL(18,2))
        AS Total_Return_Cost
FROM Return_Costs rc;


--Refund Analysis
SELECT Refund_Status,COUNT(*) AS Total_Refunds,
    CAST(SUM(Refund_Amount) AS DECIMAL(18,2)) AS Total_Refund_Amount
FROM Refunds
GROUP BY Refund_Status
ORDER BY Total_Refund_Amount DESC;

---Replacement vs Refund

SELECT r.Return_Type, COUNT(*) AS Total_Returns,
    CAST(SUM(
        CASE
            WHEN r.Return_Type = 'Replacement'
            THEN rc.Replacement_Cost
            ELSE 0
        END
    ) AS DECIMAL(18,2)) AS Replacement_Cost
FROM Returns r
LEFT JOIN Return_Costs rc
    ON r.Order_ID = rc.Order_ID
GROUP BY r.Return_Type;
--High Financial Impact Categories

SELECT
    p.Category,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        SUM(
            ISNULL(rc.Return_Shipping_Cost,0)
            + ISNULL(rc.Replacement_Cost,0)
            + ISNULL(rc.Processing_Cost,0)
            + ISNULL(rc.Restocking_Cost,0)
        ) AS DECIMAL(18,2)
    ) AS Total_Return_Cost
FROM Orders o
JOIN Products p
    ON o.Product_ID = p.Product_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
LEFT JOIN Return_Costs rc
    ON o.Order_ID = rc.Order_ID
GROUP BY p.Category
ORDER BY Total_Return_Cost DESC;

-- Net Order Value After Return Costs


SELECT
    CAST(SUM(o.Order_Value) AS DECIMAL(18,2)) AS Total_Order_Value,

    CAST(
        SUM(
            ISNULL(rc.Return_Shipping_Cost,0)
            + ISNULL(rc.Replacement_Cost,0)
            + ISNULL(rc.Processing_Cost,0)
            + ISNULL(rc.Restocking_Cost,0)
        )
        AS DECIMAL(18,2)
    ) AS Total_Return_Cost,

    CAST(
        SUM(o.Order_Value)
        -
        SUM(
            ISNULL(rc.Return_Shipping_Cost,0)
            + ISNULL(rc.Replacement_Cost,0)
            + ISNULL(rc.Processing_Cost,0)
            + ISNULL(rc.Restocking_Cost,0)
        )
        AS DECIMAL(18,2)
    ) AS Value_After_Return_Cost
FROM Orders o
LEFT JOIN Return_Costs rc
    ON o.Order_ID = rc.Order_ID;


	--Delivery Delay Impact

	SELECT
    d.Delivery_Status,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
JOIN Delivery d
    ON o.Order_ID = d.Order_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY d.Delivery_Status
ORDER BY Return_Rate DESC;

--Delay Severity Analysis
SELECT
    d.Courier,
    AVG(
        CASE
            WHEN d.Actual_Date > d.Expected_Date
            THEN DATEDIFF(DAY, d.Expected_Date, d.Actual_Date)
        END
    ) AS Avg_Delay_Days
FROM Delivery d
GROUP BY d.Courier
ORDER BY Avg_Delay_Days DESC;

----Delivery Delay Duration vs Return Rate
SELECT
    CASE
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) <= 0 THEN 'On Time'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) = 1 THEN '1 Day Late'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) BETWEEN 2 AND 3 THEN '2-3 Days Late'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) BETWEEN 4 AND 7 THEN '4-7 Days Late'
        ELSE 'More Than 7 Days'
    END AS Delay_Bucket,
    COUNT(DISTINCT d.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT d.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Delivery d
LEFT JOIN Returns r
    ON d.Order_ID = r.Order_ID
GROUP BY
    CASE
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) <= 0 THEN 'On Time'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) = 1 THEN '1 Day Late'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) BETWEEN 2 AND 3 THEN '2-3 Days Late'
        WHEN DATEDIFF(DAY, Expected_Date, Actual_Date) BETWEEN 4 AND 7 THEN '4-7 Days Late'
        ELSE 'More Than 7 Days'
    END
ORDER BY Return_Rate DESC;


---Customer Segment vs Return Rate

SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Customers c
JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY c.Customer_Segment
ORDER BY Return_Rate DESC;

----Zone-wise Return Performance
SELECT
    c.Zone,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Customers c
JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY c.Zone
ORDER BY Return_Rate DESC;

--Area-wise High Return Locations
SELECT
    c.Area,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Customers c
JOIN Orders o
    ON c.Customer_ID = o.Customer_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY c.Area
HAVING COUNT(DISTINCT o.Order_ID) >= 100
ORDER BY Return_Rate DESC;

--Product Rating vs Return Rate
SELECT
    CASE
        WHEN p.Product_Rating < 2.5 THEN 'Low Rating'
        WHEN p.Product_Rating < 3.5 THEN 'Average Rating'
        WHEN p.Product_Rating < 4.5 THEN 'Good Rating'
        ELSE 'High Rating'
    END AS Rating_Group,

    COUNT(DISTINCT o.Order_ID) AS Total_Orders,

    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,

    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate

FROM Orders o

JOIN Products p
    ON o.Product_ID = p.Product_ID

LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID

GROUP BY
    CASE
        WHEN p.Product_Rating < 2.5 THEN 'Low Rating'
        WHEN p.Product_Rating < 3.5 THEN 'Average Rating'
        WHEN p.Product_Rating < 4.5 THEN 'Good Rating'
        ELSE 'High Rating'
    END

ORDER BY Return_Rate DESC;


--Refund Amount vs Order Value

SELECT
    CAST(SUM(o.Order_Value) AS DECIMAL(18,2)) AS Total_Order_Value,

    CAST(SUM(ISNULL(f.Refund_Amount,0)) AS DECIMAL(18,2))
        AS Total_Refund_Amount,

    CAST(
        SUM(ISNULL(f.Refund_Amount,0)) * 100.0 /
        NULLIF(SUM(o.Order_Value),0)
        AS DECIMAL(10,2)
    ) AS Refund_Value_Percentage

FROM Orders o

LEFT JOIN Refunds f
    ON o.Order_ID = f.Order_ID;

	---Missing Items vs Returns


	SELECT
    m.Missing_Item_Flag,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    CAST(
        COUNT(DISTINCT r.Order_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT o.Order_ID),0)
        AS DECIMAL(10,2)
    ) AS Return_Rate
FROM Orders o
LEFT JOIN Missing_Items m
    ON o.Order_ID = m.Order_ID
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY m.Missing_Item_Flag
ORDER BY Return_Rate DESC;


--Return Inspection Failure Analysis
SELECT
    Return_Inspection_Status,

    COUNT(*) AS Total_Returns,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Percentage

FROM Returns

GROUP BY Return_Inspection_Status

ORDER BY Total_Returns DESC;


--Non-Recoverable Return Cost


SELECT
    CAST(
        SUM(
            Return_Shipping_Cost
            + Replacement_Cost
            + Processing_Cost
            + Restocking_Cost
        )
        AS DECIMAL(18,2)
    ) AS Total_Return_Cost,
    CAST(
        SUM(Recoverable_Amount)
        AS DECIMAL(18,2)
    ) AS Recoverable_Amount,

    CAST(
        SUM(
            Return_Shipping_Cost
            + Replacement_Cost
            + Processing_Cost
            + Restocking_Cost
        )
        - SUM(Recoverable_Amount)
        AS DECIMAL(18,2)
    ) AS Net_Return_Loss
FROM Return_Costs;