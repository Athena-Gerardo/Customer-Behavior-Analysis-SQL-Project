# Customer Behavior Analysis SQL Project: Danny's Diner
The project and the data used was part of a case study from the "8 Week SQL Challenge", which can be found [at this link](https://8weeksqlchallenge.com/case-study-1/). The project aims to analyze customer spending patterns, trends, and influencing factors to understand their preferences, buying behaviors, and identify new insights for enhacning business operations. 

## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
* **Challenges:** Danny has data but doesn't know how to use it to benefit the company. 
* **Questions:** Danny wants to know more about his customers, including visiting patterns, spending habits, and food preferences.
* **Importance:** Having this deeper connection with his customers will help him deliver a better and more personalized experience for his loyal customers.
* **Goals:** He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## Overview of the Data
Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:
* members:

![image](https://github.com/Athena-Gerardo/Customer-Behavior-Analysis-SQL-Project/assets/155771968/9b63ff62-0c8f-4cce-b856-b054d18edde9)

* menu:

![image](https://github.com/Athena-Gerardo/Customer-Behavior-Analysis-SQL-Project/assets/155771968/24280120-6d75-4927-ac52-c87d63674a73)

* sales:

![image](https://github.com/Athena-Gerardo/Customer-Behavior-Analysis-SQL-Project/assets/155771968/bec056bc-fbc5-4ba1-8c28-2c0f5a69dee6)

## Entity Relationship Diagram:

![image](https://github.com/Athena-Gerardo/Customer-Behavior-Analysis-SQL-Project/assets/155771968/e2e96f2d-e1c0-4cd2-a998-256ed82b5193)

## Skills Used:
* Joins
* CTE's
* Aggregate Functions
* Partition Function
* Case Function
* Date Functions
* Automated Reports

## Case Study Questions:
1. What is the total amount each customer spent at the restaurant?
```sql
SELECT S.customer_id, SUM(M.price) AS total_spent
FROM dbo.sales as S
JOIN dbo.menu as M
	ON S.product_id = M.product_id
GROUP BY S.customer_id;
```
2. How many days has each customer visited the restaurant?
```sql
SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visted
FROM dbo.sales
GROUP BY customer_id;
```
3. What was the first item from the menu purchased by each customer?
```sql
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
```
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
SELECT M.product_name, COUNT(M.product_name) as count_purchased
FROM dbo.sales as S
JOIN dbo.menu AS M	
	ON S.product_id = M.product_id
GROUP BY M.product_name
ORDER BY 2 DESC;
```
5. Which item was the most popular for each customer?
```sql
WITH most_popular AS (
SELECT S.customer_id, M.product_name, COUNT(*) as purchase_count,
		DENSE_RANK() OVER(PARTITION BY S.customer_id ORDER BY COUNT(*) DESC) AS rank
FROM dbo.sales as S
JOIN dbo.menu as M
	ON S.product_id = M.product_id
GROUP BY S.customer_id, M.product_name
)
SELECT mp.customer_id, mp.product_name, mp.purchase_count, mp.rank
FROM most_popular AS mp
WHERE mp.rank = 1;
```
6. Which item was purchased first by the customer after they became a member?
```sql
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
```
The following can also be queried as such:
```sql
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
```
7. Which item was purchased just before the customer became a member?
```sql
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
```
8. What is the total items and amount spent for each member before they became a member?
```sql
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
```
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
SELECT S.customer_id, SUM(
	CASE
		WHEN M.product_name = 'sushi' THEN M.price*20
		ELSE M.price*10 END) AS total_points
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
GROUP BY S.customer_id;
```
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
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
LEFT JOIN dbo.members AS MB
	ON S.customer_id = MB.customer_id
WHERE S.customer_id IN ('A', 'B') AND S.order_date <= '2021-01-31'
GROUP BY S.customer_id;
```
11. Bonus Q: Recreate the table output using the available data.
```sql
SELECT S.customer_id, S.order_date, M.product_name, M.price, 
	CASE
		WHEN S.order_date < MB.join_date THEN 'N'
		WHEN S.order_date >= MB.join_date THEN 'Y'
		ELSE 'N' END AS member
FROM dbo.sales AS S
JOIN dbo.menu AS M
	ON S.product_id = M.product_id
LEFT JOIN dbo.members AS MB
	ON S.customer_id = MB.customer_id
ORDER BY 1, 2;
```
12. Bonus Q: Rank all the things.
```sql
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
LEFT JOIN dbo.members AS MB
	ON S.customer_id = MB.customer_id
)
SELECT *, 
	CASE	
		WHEN TR.member = 'N' THEN NULL
		ELSE RANK() OVER(PARTITION BY TR.customer_id, TR.member ORDER BY TR.order_date)
		END AS ranking
FROM table_rankings AS TR
ORDER BY TR.customer_id;
```

## Insights
**Visiting Patterns:** 
* Customer B has visted the restaurant the most out of any other customer, with 6 total visits.
* Customer C has visted the restaurant the least amount of times, with 2 total visits. Customer C is not currently a member with the restaurant.

**Spending Habits:**
* Customer A has spent the most money at the restaurant, totaling $76. They are also the member with the most points, 1370.
* Customer C has spent the least amount of money. If they were a member with the restaurant, they could have 360 points.
* Customer A bought 2 items before becoming a member, while Customer B bought 3 items before becoming a member. Customer B has 940 points at the restaurant currently.
* The last items purchased by Customer A and B before becoming members were the curry and sushi, respectively.
  
**Food Preferences:**
* Ramen was the most popular item on the menu, purchased 8 times in total. Curry was the next most popular, purchased 4 times, and sushi was the least popular, purchased only 3 times.
* Both Customers A and C prefer ramen, while Customer B prefers sushi, ramen, and curry equally.
