CREATE SCHEMA dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');


CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM dbo.members;

SELECT *
FROM dbo.menu;

SELECT *
FROM dbo.sales;
--3. What was the first item from the menu purchased by each customer?
WITH FIRSTITEM_CTE AS(
SELECT S.customer_id,
M.PRODUCT_NAME,
DENSE_RANK() OVER(PARTITION BY S.customer_id ORDER BY S.ORDER_DATE) AS FIRST_ITEM
FROM DBO.SALES S
JOIN DBO.menu M
ON S.product_id=M.product_id
)
SELECT * FROM FIRSTITEM_CTE
WHERE FIRST_ITEM=1

--DIFFERENCE BETWEEN DENSERANK AND ROWNUMBER
--SELECT dbo.sales.customer_id, dbo.sales.product_id,dbo.sales.order_date,
--ROW_NUMBER() OVER(PARTITION BY dbo.sales.customer_id ORDER BY dbo.sales.ORDER_DATE) ex_rownumber,
--dense_rank() OVER(PARTITION BY dbo.sales.customer_id ORDER BY dbo.sales.ORDER_DATE) ex_denserank
--FROM DBO.SALES

--2. How many days has each customer visited the restaurant?
--Use of DISTINCT is not allowed with the OVER clause.
SELECT DBO.sales.customer_id,
COUNT(DISTINCT (DBO.sales.order_date)) AS VISITED_DAYS
FROM DBO.SALES
GROUP BY dbo.sales.customer_id 

--6. Which item was purchased first by the customer after they became a member?
--VERY POWERFUL APPLICATION OF JOIN AND WHERE TOGETHER
WITH FIRSTORDER_CTE AS(
SELECT
S.customer_id,M.join_date,S.order_date,S.product_id,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE)AS ranking
FROM DBO.sales S
JOIN DBO.members M
ON M.customer_id=S.customer_id
WHERE S.order_date>=M.join_date)
SELECT FO.CUSTOMER_ID,M2.product_name
FROM FIRSTORDER_CTE AS FO
JOIN DBO.menu AS M2
ON FO.PRODUCT_ID=M2.product_id
WHERE RANKING=1

--7. Which item was purchased just before the customer became a member?
WITH FIRSTORDER_CTE AS(
SELECT
S.customer_id,M.join_date,S.order_date,S.product_id,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE)AS ranking
FROM DBO.sales S
JOIN DBO.members M
ON M.customer_id=S.customer_id
WHERE S.order_date<M.join_date)
SELECT FO.CUSTOMER_ID,M2.product_name
FROM FIRSTORDER_CTE AS FO
JOIN DBO.menu AS M2
ON FO.PRODUCT_ID=M2.product_id
WHERE RANKING=1

--8. What is the total items and amount spent for each member before they became a member?
SELECT
S.customer_id, COUNT(DISTINCT S.product_id) AS ORDERNUMBER, SUM(MN.price) AS PRICE
FROM DBO.sales AS S
JOIN DBO.members AS M
ON S.customer_id=M.customer_id
JOIN DBO.menu AS MN
ON S.product_id=MN.product_id
WHERE S.order_date<M.join_date
GROUP BY S.customer_id

--1. What is the total amount each customer spent at the restaurant?-groupby OR PARTITIONBY
SELECT
S.customer_id, SUM(M.PRICE) AS AMOUNT_SPENT
FROM DBO.sales AS S
JOIN DBO.menu AS M
ON S.product_id=M.product_id
GROUP BY S.customer_id

--2.How many days has each customer visited the restaurant?
SELECT
CUSTOMER_ID, COUNT (DISTINCT ORDER_DATE)AS DAYS_VISITED FROM DBO.sales
GROUP BY CUSTOMER_ID

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
--TOP ALWAYS COMES WITH SELECT STATEMENT THEN ANY OTHER COLUMN STARTS. THIS IS SYNTAX.HERE ORDER BY IS IMPORTANT.
--Only the GROUP BY columns can be included in the SELECT clause. 
--To use other columns in the SELECT clause, use the aggregate functions with them.
SELECT TOP 1 (COUNT(S.product_id)) AS MOST_PURCHASED,M.product_name
FROM DBO.SALES AS S
JOIN DBO.menu AS M
ON S.product_id=M.product_id
GROUP BY M.product_name
ORDER BY MOST_PURCHASED DESC
-- HERE SINCE PRODUCT NAME ISIN SYNC WITH PRODUCT ID SO ANY ONE CAN BE USED WITH GROUP BY OR BOTH CAN BE USED 
--BUT REMEMBER TO USE THE COLUMN WHICH IS USED IN SELECT STATEMENT. LIKE HERE PRODUCT NAME

--5.Which item was the most popular for each customer?
--DIFFERENCE BETWEEN TOP AND RANK CAN BE UNDERSTOOD HERE- TOP CAN BE USED WHEN LEVEL OF GROUPING IS ONEBUT RANK CAN BE USED 
--WHEN THERE ARE MULTIPLE SUBGROUPING
WITH fav_item_cte AS
(
	SELECT 
    s.customer_id, 
    m.product_name, 
    COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM dbo.menu AS m
JOIN dbo.sales AS s
	ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT 
  customer_id, 
  product_name, 
  order_count
FROM fav_item_cte 
WHERE rank = 1;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH price_points_cte AS
(
	SELECT *, 
		CASE WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10 END AS points
	FROM menu
)

SELECT 
  s.customer_id, 
  SUM(p.points) AS total_points
FROM price_points_cte AS p
JOIN sales AS s
	ON p.product_id = s.product_id
GROUP BY s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--not just sushi - how many points do customer A and B have at the end of January?
