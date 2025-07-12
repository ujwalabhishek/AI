DELIMITER $$
CREATE PROCEDURE get_sales_customer(sales_input int)
BEGIN
	SELECT ROUND(Sales), Cust_id
	FROM market_star_schema.market_fact_full
	WHERE round(Sales) > sales_input
	ORDER BY round(Sales);
END$$
DELIMITER $$;

call get_sales_customer(300);

--
Use sakila DB 
SELECT 
    MONTH(PAYMENT_DATE) AS Payment_month,
    COUNT(payment_id) AS No_of_payments
FROM
    PAYMENT
GROUP BY MONTH(PAYMENT_DATE)
ORDER BY COUNT(payment_id) DESC
LIMIT 1;
