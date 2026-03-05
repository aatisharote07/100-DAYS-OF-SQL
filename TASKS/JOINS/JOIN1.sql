-- Freedom Ranking for Different Countries
-- Some feature details of the dataset:
-- Feature	Description
-- A	Electoral Process
-- B	Political Pluralism and Participation
-- C	Functioning of Government
-- D	Freedom of Expression and Belief
-- E	Associational and Organizational Rights
-- F	Rule of Law
-- G	Personal Autonomy and Individual Rights
-- CL	Civil Liberties Scores
-- Status	F=Free, PF=Partly Free, NF=Not Free
-- Q-1 Find out top 10 countries' which have maximum A and D values
SELECT A.country,A,D FROM (SELECT Country,A FROM country_ab
ORDER BY A DESC LIMIT 10) A
LEFT JOIN
(SELECT Country,D FROM country_cd
ORDER BY D DESC LIMIT 10) B
ON A.country = B.country
UNION
SELECT B.country,A,D  FROM (SELECT Country,A FROM country_ab
ORDER BY A DESC LIMIT 10) A
RIGHT JOIN
(SELECT Country,D FROM country_cd
ORDER BY D DESC LIMIT 10) B
ON A.country = B.country
ORDER BY Country;

-- Q-2 Find out highest CL value for 2020 for every region. Also sort the result in descending order. Also display the CL values in descending order.
SELECT MAX(CL),Region FROM country_cl t1
JOIN country_ab t2
ON t1.country = t2.country
WHERE t1.edition = 2020
GROUP BY Region
ORDER BY MAX(CL) DESC; 

-- Customer
-- Employee
-- Sales
-- Products
-- Q-3 Find top-5 most sold products.
SELECT Name, SUM(Quantity) AS "total_Quantity" FROM sales1 t1
JOIN products t2	
ON t1.ProductID = t2.ProductID
GROUP BY t1.ProductID
ORDER BY total_Quantity DESC LIMIT 5;	

-- Q-4: Find sales man who sold most no of products.
SELECT t1.SalesPersonID,FirstName,LastName,SUM(Quantity) AS "num_sold" FROM sales1 t1
JOIN emplyoees t2 
ON t1.SalesPersonID = t2.EmployeeID
GROUP BY t1.SalesPersonID  
ORDER BY num_sold
 

 
