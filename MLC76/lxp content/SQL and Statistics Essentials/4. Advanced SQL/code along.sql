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

