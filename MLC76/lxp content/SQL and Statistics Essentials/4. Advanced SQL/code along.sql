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