SELECT m.Ord_id, c.Customer_Name , round(Sales) as SalesRounded, 
RANK() OVER(order by Sales desc)
FROM market_fact_full as m 
INNER JOIN cust_dimen as c 
on m.Cust_id = c.Cust_id 
where Customer_Name='RICk WILSON';

-- Top 10 sales order from customer 
with sales_info as (
SELECT m.Ord_id, c.Customer_Name , 
round(Sales) as SalesRounded, 
RANK() OVER(order by Sales desc) as sales_rank
FROM market_fact_full as m 
INNER JOIN cust_dimen as c 
on m.Cust_id = c.Cust_id 
where Customer_Name='RICk WILSON') 
select * 
from sales_info 
where sales_rank<=10;

-- Top 10 sales order from customer by rank , deep rank, percent rank
-- Step 1: Create the table
CREATE TABLE sales (
    id INT PRIMARY KEY,
    employee VARCHAR(50),
    amount DECIMAL(10, 2)
);

-- Step 2: Insert the data
INSERT INTO sales (id, employee, amount) VALUES
(1, 'Alice', 500),
(2, 'Bob', 600),
(3, 'Carol', 600),
(4, 'David', 400),
(5, 'Eve', 300);

select employee, amount, 
RANK() OVER (order by amount desc) as normalrank,
DENSE_RANK() OVER (order by amount desc) as denserank,
PERCENT_RANK() OVER (order by amount desc) as percentrank
from sales;

-- 

SELECT  c.Customer_Name , count(distinct m.Ord_id) as OrderCount, 
RANK() OVER(order by count(distinct m.Ord_id) desc) as ORDERRANK,
DENSE_RANK() OVER(order by count(distinct m.Ord_id) desc) as DENSE_ORDERRANK,
ROW_NUMBER() OVER(order by count(distinct m.Ord_id) desc) as ORDER_NUMBER 
FROM market_fact_full as m 
INNER JOIN cust_dimen as c 
on m.Cust_id = c.Cust_id 
group by c.Customer_Name ;

-- Named Window functions

SELECT ord_id,
discount,
customer_name,
RANK() OVER w AS disc_rank,
DENSE_RANK() OVER w AS disc_dense_rank,
ROW_NUMBER() OVER w AS disc_row_num
FROM market_fact_full as m
INNER JOIN cust_dimen as c
ON m.cust_id=c.cust_id
WINDOW w AS (PARTITION BY customer_name ORDER BY discount DESC) ;

-- Rewrite the following query using the named window function 

    SELECT *,
    RANK() OVER (
      PARTITION BY ship_mode
      ORDER BY COUNT(*)) 'Rank',
    DENSE_RANK() OVER (
      PARTITION BY ship_mode
      ORDER BY COUNT(*)) 'Dense Rank',
    PERCENT_RANK() OVER (
      PARTITION BY ship_mode
      ORDER BY COUNT(*)) 'Percent Rank'
    FROM shipping_dimen;

    SELECT  ship_mode,
    COUNT(*) AS ship_mode_count,
    RANK() OVER w AS 'Rank',
    DENSE_RANK() OVER w AS 'Dense Rank',
    PERCENT_RANK() OVER w AS 'Percent Rank'
    FROM shipping_dimen
    GROUP BY ship_mode
    WINDOW w AS (PARTITION BY ship_mode ORDER BY COUNT(*));
    
    
-- Frames example

WITH daily_shipping_summary AS (
SELECT s.Ship_Date, SUM(m.shipping_cost) as daily_total
FROM shipping_dimen as s 
INNER JOIN market_fact_full as m
ON s.Ship_id=m.Ship_id
group by s.Ship_Date
order by s.Ship_Date
)
SELECT *,
SUM(daily_total) OVER w1 AS running_total,
AVG(daily_total) OVER w1 AS moving_average
From daily_shipping_summary
WINDOW w1 as (order by ship_date ROWS UNBOUNDED PRECEDING),
w2 as (order by ship_date ROWS 6 PRECEDING)
;



-- lead Lag

 With order_info as (
	Select c.Customer_Name,
	 m.Ord_id, 
	 o.order_date
	From
		market_fact_full as m
		LEFT JOIN orders_dimen as o on m.Ord_id=o.Ord_id 
		LEFT JOIN cust_dimen as c on m.Cust_id = c.Cust_id 
	WHERE 
		c.Customer_Name = 'RICK WILSON'
	Group By 
		c.Customer_Name,
		m.Ord_id, 
		o.order_date
        )
 Select 
	*,
	lead(order_date,1,0) OVER (order by order_date, Ord_id) As NextOrder_Date,
	DATEDIFF(lead(order_date,1,0) OVER (order by order_date, Ord_id),order_date) as days_diff
 From 
	order_info;
; 

-- alternate sql 

WITH order_info AS (
    SELECT 
        c.Customer_Name,  
        m.Ord_id,   
        o.order_date  
    FROM  
        market_fact_full AS m  
        LEFT JOIN orders_dimen AS o ON m.Ord_id = o.Ord_id   
        LEFT JOIN cust_dimen AS c ON m.Cust_id = c.Cust_id  
    WHERE 
        c.Customer_Name = 'RICK WILSON'
),
order_with_lead AS (
    SELECT 
        *,  
        LEAD(order_date, 1) OVER (ORDER BY order_date, Ord_id) AS NextOrder_Date
    FROM 
        order_info
)
SELECT 
    *,  
    DATEDIFF(NextOrder_Date, order_date) AS days_diff
FROM 
    order_with_lead;
 
-- case 

SELECT 
market_fact_id,
profit
	CASE
		WHEN profit <-500 THEN 'Huge Loss'
		WHEN profit BETWEEN -500 AND 0 THEN 'Bearable Loss'
		WHEN profit BETWEEN 0 AND 500 THEN 'Decent Profit'
		ELSE 'Great Profit'
	END AS Profit_type
FROM
	market_fact_full;

-- Example 2    
-- Classify customers on the following criteria
-- Top 10 % of customers as Gold
-- Next 40% of customers as Silver
-- Rest 50% of customers as Bronze    

WITH sales_info AS
(select c.customer_name, 
		round(SUM(m.Sales)) as TotalSales,
        percent_rank() over (order by round(SUM(m.Sales)) desc) as per_rank
from
market_fact_full as m
left join
cust_dimen as c
ON m.Cust_id = c.Cust_id
group by 
c.Customer_Name
)
select *,
case
	when per_rank <= 0.1 THEN 'Gold'
    when per_rank > 0.1 AND per_rank <= 0.4 THEN 'Silver'
    else 'Bronze'
end as customer_category
from sales_info;




CREATE TABLE Salaries (Name VARCHAR(50),salary DECIMAL(4,1));

INSERT INTO Salaries (Name, salary) VALUES
('Sundar Pichai', 6.8),
('Jeff Bezos', 8.7),
('Bill Gates', 9),
('Mukesh Ambani', 14),
('Rahul Dravid', 1.2),
('Vishwanathan Anand', 3),
('Sunil Chhetri', 7),
('Leander Paes', 2.5),
('Saina Nehwal', 5),
('Sania Mirza', 10);

select *,
    round(case
        when salary <= 2.5 THEN 0
        WHEN salary  > 2.5 AND salary <= 5 THEN (((salary - 2.5)*0.05)*100000)
        WHEN salary > 5 AND salary <=10 THEN (((salary - 5)*0.2)*100000)+12500
        when salary > 10 then (((salary - 10)*0.3)*100000)+112500
    END) AS 'Tax Amounts'
FROM salaries;


-- User Defined Function

DELIMITER $$

CREATE FUNCTION profittype(profit int)
returns varchar(40) deterministic

BEGIN

declare message varchar(40);
if profit <-500 THEN 
    SET message = 'Huge Loss';
elseif profit BETWEEN -500 AND 0 THEN
    SET message = 'Bearable Loss';
elseif profit BETWEEN 0 AND 500 THEN 
    SET message ='Decent Profit';
ELSE
    SET message = 'Great Profit';
END IF;
    
RETURN message;

END;
DELIMITER $$

SELECT 
    	market_fact_id,
        profit,
    	profittype(profit)
FROM
    	market_fact_full;
        
-- Stored Procedure 

CREATE PROCEDURE get_sales_customer(sales_input int)

BEGIN

	SELECT ROUND(Sales), Cust_id
	FROM market_star_schema.market_fact_full
	WHERE round(Sales) > sales_input
	ORDER BY round(Sales);

END$$
DELIMITER $$;

call get_sales_customer(300);


-- Profits per product category
SELECT 
    p.Product_Category, SUM(m.Profit)
FROM
    market_fact_full AS m
        INNER JOIN
    prod_dimen AS p ON m.Prod_id = p.Prod_id
        INNER JOIN
    orders_dimen AS o ON m.Ord_id = o.Ord_id
GROUP BY p.Product_Category
ORDER BY SUM(m.Profit)
;
-- Profits per product subcategory
SELECT 
    p.Product_Category, p.Product_Sub_Category, SUM(m.Profit)
FROM
    market_fact_full AS m
        INNER JOIN
    prod_dimen AS p ON m.Prod_id = p.Prod_id
        INNER JOIN
    orders_dimen AS o ON m.Ord_id = o.Ord_id
GROUP BY p.Product_Category , p.Product_Sub_Category
ORDER BY SUM(m.Profit)
;
 -- Average profit per order
SELECT 
    p.Product_Category,
    SUM(m.Profit) AS profits,
    COUNT(DISTINCT o.Order_number) AS ordercount,
    ROUND(SUM(m.Profit) / COUNT(DISTINCT o.Order_number),
            2) AS Average_Profit_PerOreder
FROM
    market_fact_full AS m
        INNER JOIN
    prod_dimen AS p ON m.Prod_id = p.Prod_id
        INNER JOIN
    orders_dimen AS o ON m.Ord_id = o.Ord_id
GROUP BY p.Product_Category
ORDER BY p.Product_Category , SUM(m.Profit)
;
 -- Average profit per order
 SELECT 
    p.Product_Category,
    SUM(m.Profit) AS profits,
    COUNT(DISTINCT o.Order_number) AS ordercount,
    ROUND(SUM(m.Profit) / COUNT(DISTINCT o.Order_number),2) AS Average_Profit_PerOreder,
    ROUND(SUM(m.Sales) / COUNT(DISTINCT o.Order_number),2) AS Average_Sales_PerOreder,
    ROUND(SUM(m.profit)/SUM(m.sales),4)*100 AS Profit_Percentage 
FROM
    market_fact_full AS m
        INNER JOIN
    prod_dimen AS p ON m.Prod_id = p.Prod_id
        INNER JOIN
    orders_dimen AS o ON m.Ord_id = o.Ord_id
GROUP BY p.Product_Category
ORDER BY p.Product_Category , SUM(m.Profit)

-- Select top 10 profitable customer

WITH customer_summary as(
SELECT m.Cust_id,
rank() OVER(order by SUM(m.Profit) desc) as customer_rank,
c.Customer_Name,
SUM(m.Profit),
c.City as customer_city,
c.State as customer_state,
ROUND(SUM(m.Sales),2) as sales
FROM
market_fact_full as m
INNER JOIN
cust_dimen as c
on m.Cust_id = c.Cust_id
group by
m.Cust_id
order by SUM(m.Profit) desc
)
Select * from customer_summary
WHERE customer_rank <= 10;

-- customers who dicnt place any order

SELECT m.Cust_id,
c.Customer_Name,
c.City,
c.State,
m.Ord_id
FROM
cust_dimen as c
LEFT JOIN
market_fact_full as m
on  c.Cust_id = m.Cust_id
WHERE m.Ord_id IS null
;

-- verify result
select COUNT(Cust_id) from cust_dimen;
-- 1832
select COUNT(DISTINCT Cust_id) from market_fact_full;

-- 1832
   