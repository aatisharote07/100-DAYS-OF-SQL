-- Q-5: Sales man name who has most no of unique customer.
SELECT 
    t1.SalesPersonID,
    t2.FirstName,
    t2.LastName,
    COUNT(DISTINCT t1.CustomerID) AS unique_customers
FROM sales1 t1
JOIN employees t2 
    ON t1.SalesPersonID = t2.EmployeeID
GROUP BY 
    t1.SalesPersonID,
    t2.FirstName,
    t2.LastName
ORDER BY unique_customers DESC
LIMIT 5;


-- Q-6: Sales man who has generated most revenue. Show top 5.
SELECT 
    t1.SalesPersonID,
    t3.FirstName,
    t3.LastName,
    ROUND(SUM(t1.Quantity * t2.Price)) AS total_revenue
FROM sales1 t1
JOIN products t2 
    ON t1.productID = t2.productID
JOIN employees t3 
    ON t1.SalesPersonID = t3.EmployeeID
GROUP BY 
    t1.SalesPersonID,
    t3.FirstName,
    t3.LastName
ORDER BY total_revenue DESC 
LIMIT 5;

-- 6. Sales man who has generated most revenue. Show top 5.
SELECT t1.SalesPersonID,t3.FirstName,t3.LastName,
ROUND(SUM(t1.Quantity * t2.Price)) AS 'total_revenue'
FROM sales t1
JOIN product t2
ON t1.ProductID = t2.ProductID
JOIN employee t3
ON t1.SalesPersonID = t3.EmployeeID
GROUP BY t1.SalesPersonID
ORDER BY total_revenue DESC LIMIT 5;
-- 7. List all customers who have made more than 10 purchases.
SELECT t1.CustomerID,t2.FirstName,t2.LastName,COUNT(*) FROM sales t1
JOIN customer t2
ON t1.CustomerID = t2.CustomerID
GROUP BY t1.CustomerID
HAVING COUNT(*) > 10;

-- 8. List all salespeople who have made sales to more than 5 customers.
SELECT t1.SalesPersonID,FirstName,LastName,COUNT(DISTINCT CustomerID) AS 'unique_customers' FROM sales t1
JOIN employee t2
ON t1.SalesPersonID = t2.EmployeeID
GROUP BY t1.SalesPersonID
HAVING unique_customers > 5;

-- 9. List all pairs of customers who have made purchases with 
--    the same salesperson.
SELECT *
FROM (SELECT DISTINCT t1.CustomerID AS 'first_customer',
t2.CustomerID AS 'second_customer',
t1.SalesPersonID
FROM sales t1
JOIN sales t2
ON t1.SalesPersonID = t2.SalesPersonID 
AND t1.CustomerID != t2.CustomerID) A
JOIN customer B
ON A.first_customer = B.customerID
