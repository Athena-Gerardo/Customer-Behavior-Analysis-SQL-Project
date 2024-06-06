/*
Customer Behavior Analysis: Danny's Diner Portfolio Project

Skills used: Joins, CTE's, Aggregate Functions, Partition Function, Case Function, Date Functions.

*/


-- Create a database for the project:
CREATE DATABASE dannys_diner;

USE dannys_diner;


-- Create the data to use for the project:
CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
	);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
	);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
	);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');


-- View the data:
SELECT *
FROM dbo.members;

SELECT *
FROM dbo.menu;

SELECT *
FROM dbo.sales;


-- SQL Analysis:

--1. What is the total amount each customer spent at the restaurant?

SELECT S.customer_id, SUM(M.price) AS total_spent
FROM dbo.sales as S
JOIN dbo.menu as M
	ON S.product_id = M.product_id
GROUP BY S.customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visted
FROM dbo.sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
-- Create a CTE to run this analysis:

WITH customer_first_purchase AS (
	SELECT S.customer_id, MIN(S.order_date) as first_purchase_date
	FROM dbo.sales as S
	GROUP BY S.customer_id
	)
SELECT cfp.customer_id, cfp.first_purchase_date, M.product_name
FROM customer_first_purchase AS cfp
JOIN dbo.sales as S
	ON S.customer_id = cfp.customer_id
	AND cfp.first_purchase_date = S.order_date
JOIN dbo.menu AS M
	ON M.product_id = S.product_id;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT M.product_name, COUNT(M.product_name) as count_purchased
FROM dbo.sales as S
JOIN dbo.menu AS M	
	ON S.product_id = M.product_id
GROUP BY M.product_name
ORDER BY 2 DESC;


-- 5. Which item was the most popular for each customer?
-- Create a CTE to run this analysis:

WITH most_popular AS (
SELECT S.customer_id, M.product_name, COUNT(*) as purchase_count,
		ROW_NUMBER() OVER(PARTITION BY S.customer_id ORDER BY COUNT(*) DESC) AS rank
FROM dbo.sales as S
JOIN dbo.menu as M
	ON S.product_id = M.product_id
GROUP BY S.customer_id, M.product_name
)
SELECT mp.customer_id, mp.product_name, mp.purchase_count, mp.rank
FROM most_popular AS mp
WHERE mp.rank = 1;


-- 6. Which item was purchased first by the customer after they became a member?
-- Create a CTE to run this analysis:

WITH first_purchase_after_membership AS (
SELECT memb.customer_id, sales.order_date AS purchases_after_membership, menu.product_name,
		ROW_NUMBER() OVER(PARTITION BY memb.customer_id ORDER BY COUNT(*)) AS rank 
FROM dbo.sales AS sales 
JOIN dbo.menu AS menu
	ON sales.product_id = menu.product_id
JOIN dbo.members AS memb
	ON sales.customer_id = memb.customer_id
WHERE sales.order_date >= memb.join_date
GROUP BY memb.customer_id, sales.order_date, menu.product_name
)
SELECT fp.customer_id, fp.product_name, fp.purchases_after_membership, fp.rank
FROM first_purchase_after_membership AS fp
WHERE fp.rank = 1;

-- you can also code it like this:

WITH first_purchase_after_membership AS (
SELECT S.customer_id, MIN(S.order_date) as first_purchase_date
FROM dbo.sales AS S
JOIN dbo.members AS MB 
	ON S.customer_id = MB.customer_id
WHERE S.order_date >= MB.join_date
GROUP BY S.customer_id
)
SELECT FP.customer_id, FP.first_purchase_date, M.product_name
FROM first_purchase_after_membership AS FP
JOIN dbo.sales as S
	ON FP.customer_id = S.customer_id
AND FP.first_purchase_date = S.order_date
JOIN dbo.menu AS M
	ON S.product_id = M.product_id;


-- 7. Which item was purchased just before the customer became a member?
-- Create a CTE to run this analysis:

WITH first_purchase_before_membership AS (
SELECT S.customer_id, MAX(S.order_date) as purchase_date
FROM dbo.sales AS S
JOIN dbo.members AS MB 
	ON S.customer_id = MB.customer_id
WHERE S.order_date < MB.join_date
GROUP BY S.customer_id
)
SELECT FP.customer_id, M.product_name, FP.purchase_date
FROM first_purchase_before_membership AS FP
JOIN dbo.sales as S
	ON FP.customer_id = S.customer_id
AND FP.purchase_date = S.order_date
JOIN dbo.menu AS M
	ON S.product_id = M.product_id;


-- 8. What is the total items and amount spent for each member before they became a member?
-- Create a CTE to run this analysis:

WITH purchase_before_membership AS (
SELECT S.customer_id, S.order_date, MB.join_date, S.product_id
FROM dbo.sales AS S
JOIN dbo.members AS MB 
	ON S.customer_id = MB.customer_id
WHERE S.order_date < MB.join_date
)
SELECT pbm.customer_id, COUNT(pbm.product_id) as total_items, SUM(M.price) AS total_spent
FROM purchase_before_membership AS pbm
JOIN dbo.menu AS M
	ON pbm.product_id = M.product_id
GROUP BY pbm.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- This is a hypothetical scenario for if all 3 customers were members

SELECT S.customer_id, SUM(
	CASE
		WHEN M.product_name = 'sushi' THEN M.price*20
		ELSE M.price*10 END) AS total_points
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
GROUP BY S.customer_id;


/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT S.customer_id, SUM(
	CASE
		WHEN S.order_date BETWEEN MB.join_date AND DATEADD(DAY, 7, MB.join_date)
			THEN M.price*20
		WHEN M.product_name = 'sushi'
			THEN M.price*20
		ELSE M.price*10 END) AS total_points
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
LEFT JOIN dbo.members AS MB				-- Use LEFT JOIN to ensure that the calculations exclude any nulls when we write our conditions (since customer C is not a member a NULL would appear)
	ON S.customer_id = MB.customer_id
WHERE S.customer_id IN ('A', 'B') AND S.order_date <= '2021-01-31'	-- Add this condition to ensure we are only looking at members (ie not customer C)
GROUP BY S.customer_id;


--11. Recreate the table output using the available data

SELECT S.customer_id, S.order_date, M.product_name, M.price, 
	CASE
		WHEN S.order_date < MB.join_date THEN 'N'
		WHEN S.order_date >= MB.join_date THEN 'Y'
		ELSE 'N' END AS member
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
LEFT JOIN dbo.members AS MB				-- Use LEFT JOIN to include customer C to showcase their membership additionally
	ON S.customer_id = MB.customer_id
ORDER BY 1, 2;


--12. Rank all the things:

WITH table_rankings AS (
SELECT S.customer_id, S.order_date, M.product_name, M.price, 
	CASE
		WHEN S.order_date < MB.join_date THEN 'N'
		WHEN S.order_date >= MB.join_date THEN 'Y'
		ELSE 'N' 
		END AS member
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
LEFT JOIN dbo.members AS MB				-- Use LEFT JOIN to include customer C to showcase their membership additionally
	ON S.customer_id = MB.customer_id
)
SELECT *, 
	CASE	
		WHEN TR.member = 'N' THEN NULL
		ELSE RANK() OVER(PARTITION BY TR.customer_id, TR.member ORDER BY TR.order_date)
		END AS ranking
FROM table_rankings AS TR
ORDER BY TR.customer_id;