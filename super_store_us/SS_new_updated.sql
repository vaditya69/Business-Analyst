CREATE DATABASE superstore_us_new;

USE superstore_us_new;

CREATE TABLE orders(
		row_id int primary key,
        order_priority char(20),
        customer_id int not null,
        customer_name char(30),
        ship_mode char(30),
        customer_segment char(30),
        product_category char(30),
        product_sub_category varchar(70),
        product_container varchar(100),
		product_name varchar(200),
        product_base_margin decimal(7,2),
        country char(30),
        region char(15),
        state_province char(30),
        city char(30),
        order_date date,
        ship_date date,
		discount decimal(7,2),
        unit_price decimal(7,2),
        shipping_cost decimal(7,2),
        profit decimal(7,2),
        quantity_ordered_new int,
        sales decimal(7,2),
        order_id int not null
	);
    
SELECT COUNT(row_id) FROM orders;
    
    CREATE TABLE o_return( 
	order_id int primary key, 
    Order_status char(20)
);
    
    CREATE TABLE users( 
	region char(15) unique,
    manager char(30)
);

-- to check what is the most used shipmode and how many times it has been used 
 WITH CTE AS(
 SELECT 
	state_province,
	ship_mode, 
	COUNT(ship_mode) AS no_of_times,
    RANK() OVER(PARTITION BY state_province ORDER BY COUNT(ship_mode) DESC) AS ranking 
 FROM orders 
 GROUP BY state_province, ship_mode
 ORDER BY state_province, no_of_times DESC)

SELECT * FROM CTE 
WHERE ranking = 1;
#Better analysis
 /*
 SELECT 
	ship_mode, 
    COUNT(*) AS occurance, 
    SUM(no_of_times) AS total_times
FROM CTE
WHERE ranking = 1
GROUP BY 1; 
 */
 -- to check the most used customer segment orders comming from
 select customer_segment, count(customer_segment) from orders group by customer_segment order by count(customer_segment) asc;
 
 -- most to least sold product/sub product category order by region
 select product_category as product, count(product_category) as total_sold, product_sub_category as sub_category, region 
 from orders 
 group by product, region, sub_category  
 order by product, region desc; 
 
 -- most and least sales done in a month/ STATE/ REGION/ PRODUCTS/ SUB-PRODUCT WISE.
 # MONTH WISE DIVISION
 SELECT 
	MONTH(order_date) AS MONTHLY, 
    SUM(sales) AS TOTAL 
FROM ORDERS 
GROUP BY MONTHLY 
ORDER BY MONTHLY, TOTAL DESC;
# STATE WISE
SELECT 
	MONTH(order_date) AS months, 
    state_province, 
    SUM(sales) AS t_sales
FROM orders
GROUP BY months, state_province
ORDER BY months, t_sales DESC;
# SUB_PRODUCTS WITH ROLLUP
SELECT 
	MONTH(order_date) AS months, 
    product_sub_category, 
    SUM(sales) AS t_sales
FROM orders
GROUP BY months, product_sub_category
WITH ROLLUP
ORDER BY months, t_sales DESC;

-- most to least ordering customer with quantity and sales figure with profit
SELECT 
	CUSTOMER_ID, 
    CUSTOMER_NAME, 
    SUM(QUANTITY_ORDERED_NEW) AS QUANTITY, 
    SUM(SALES) AS T_SALES, 
    SUM(PROFIT) AS T_PROFIT
FROM ORDERS 
GROUP BY CUSTOMER_NAME, CUSTOMER_ID 
ORDER BY SUM(SALES) DESC;

-- period where the most orders where returned region wise
SELECT 
	ORDERS.ORDER_ID, 
    O_RETURN.ORDER_ID, 
    ORDERS.REGION, 
    ORDERS.ORDER_DATE 
FROM ORDERS 
NATURAL JOIN O_RETURN 
ORDER BY REGION, ORDER_DATE;

-- Replacing the Not Specified in order_priority with Completed
SELECT *, 
	REPLACE(order_priority, 'Not Specified', 'Completed') AS refined
FROM orders;

-- Region wise total_sales contribution
SELECT 
	region, 
    SUM(sales)/ SUM(SUM(sales)) OVER() * 100 AS perc_contribution
FROM orders
GROUP BY region;

-- Analyzing month wise region sales/profit perccentage weightage with total sales/profit 
WITH CTE AS (
SELECT 
	MONTH(order_date) AS months,
    region,
    SUM(sales)/ SUM(SUM(sales)) OVER() * 100 AS perc_t_sales,
    SUM(profit)/ SUM(SUM(profit)) OVER() * 100 AS perc_t_profit
FROM orders
GROUP BY 1, 2
ORDER BY 1,2)

SELECT * FROM CTE;
-- finding out the details of the customers who returned their order
SELECT * 
FROM orders
WHERE order_id IN( 
	SELECT 
	DISTINCT order_id
	FROM ORDERS
	INNER JOIN o_return
	USING(order_id)
);
#Cross Checking 
SELECT * FROM orders WHERE row_id = 5059;
SELECT * FROM o_return WHERE order_id = 5059;

-- finding out the product category with char_len > 15
SELECT
	product_sub_category, 
	LENGTH(product_sub_category) AS char_len
FROM orders 
WHERE LENGTH(product_sub_category) > 15
GROUP BY product_sub_category
ORDER BY char_len DESC;
-- Lets declare some changes
/*
#Replacing and with &
UPDATE orders
SET product_sub_category = REPLACE(product_sub_category, 'and', ' & ') 
WHERE product_sub_category LIKE '%and%';
#Replacing "Binders and Binder Accessories" with "Binders and Accessories"
UPDATE orders
SET product_sub_category = REPLACE(product_sub_category, 'Binders and Binder Accessories', 'Binders and Accessories') 
WHERE product_sub_category = 'Binders and Binder Accessories';
*/

-- month wise region's sales and profit 
SELECT 
    MONTHNAME(order_date) AS months,
    region,
    SUM(sales) AS t_sales,
    SUM(profit) AS t_profit
FROM orders
GROUP BY 1, 2
ORDER BY FIELD(months, 
    'January', 'February', 'March', 'April', 'May', 'June', 
    'July', 'August', 'September', 'October', 'November', 'December'
), t_sales DESC;

SELECT * FROM orders;

-- Checking of order priority and product container with region, state, city with conditional searching
SELECT  
    ROW_NUMBER() OVER(ORDER BY REGION) AS R_INDEX,  
    REGION,  
    ORDER_PRIORITY,  
    PRODUCT_CONTAINER AS CONTAINER,
    COUNT(*) AS NO_OF_ITEMS,
    SUM(SALES) AS T_SALES,  
    SUM(PROFIT) AS T_PROFIT  
FROM ORDERS   
GROUP BY REGION, ORDER_PRIORITY, PRODUCT_CONTAINER  
ORDER BY R_INDEX, REGION, T_SALES, T_PROFIT;

-- Issuing of commision for sales over 50,000 for each month with cumulative sum.
-- Analysing all the regions
WITH analysing AS (SELECT 
	REGION, 
	SUM(sales) AS t_sales,
	COUNT(state_province) AS states_per_region 
FROM orders 
GROUP BY region),
-- Reason for using Chris as particular because central area covers most states
answer AS (SELECT  
    DATE_FORMAT(ORDER_DATE, '%Y-%m') AS MONTH_DATA,  
    MANAGER,  
    SUM(SALES) AS T_SALES,  
    SUM(PROFIT) AS T_PROFIT,  
    CASE  
        WHEN MANAGER = 'Chris' AND SUM(SALES) > 60000 THEN (SUM(SALES) - 60000) * 0.15  
        WHEN SUM(SALES) > 50000 THEN (SUM(SALES) - 50000) * 0.15  
    END AS BONUS  
FROM ORDERS  
JOIN USERS  
ON ORDERS.REGION = USERS.REGION  
GROUP BY MONTH_DATA, MANAGER
ORDER BY MONTH_DATA, T_SALES),
-- Lets analyse how much the managers are making in bonuses
bonuses AS (SELECT 
	month_data,
    manager,
    SUM(bonus) AS t_bonus
FROM answer
GROUP BY 1,2
WITH ROLLUP
ORDER BY month_data, t_bonus DESC)

-- Total Bonus Payouts
SELECT * FROM bonuses;  

-- Checking which city and region have the most active client
SELECT  
    REGION,  
    COUNT(REGION)  
FROM (  
    SELECT  
        STATE_PROVINCE AS STATE,  
        CITY,  
        REGION,  
        SUM(SALES) AS T_SALES,  
        SUM(PROFIT) AS T_PROFIT  
    FROM ORDERS  
    GROUP BY STATE, CITY, REGION  
    ORDER BY REGION, T_SALES DESC  
) AS REGION_ANALYSIS  
GROUP BY REGION;  

SELECT  
    CITY,  
    COUNT(CITY)  
FROM (  
    SELECT  
        STATE_PROVINCE AS STATE,  
        CITY,  
        REGION,  
        SUM(SALES) AS T_SALES,  
        SUM(PROFIT) AS T_PROFIT  
    FROM ORDERS  
    GROUP BY STATE, CITY, REGION  
    ORDER BY STATE, T_SALES DESC  
) AS REGION_ANALYSIS  
GROUP BY CITY  
ORDER BY COUNT(CITY) DESC;  
#Cross Checking 
SELECT 
	DISTINCT(customer_name) 
FROM orders 
WHERE city = 'Columbus';

-- Finding out which CITY is repeated in the same REGION but belongs to different STATES  
SELECT  
    REGION,  
    CITY,  
    COUNT(CITY) AS TIMES  
FROM (  
    SELECT  
        STATE_PROVINCE AS STATE,  
        CITY,  
        REGION,  
        SUM(SALES) AS T_SALES,  
        SUM(PROFIT) AS T_PROFIT  
    FROM ORDERS  
    GROUP BY STATE, CITY, REGION  
    ORDER BY REGION, T_SALES DESC  
) AS REGION_ANALYSIS  
GROUP BY REGION, CITY  
HAVING TIMES > 1;  
-- CROSS-CHECKING  
SELECT *  
FROM (  
    SELECT  
        STATE_PROVINCE AS STATE,  
        CITY,  
        REGION,  
        SUM(SALES) AS T_SALES,  
        SUM(PROFIT) AS T_PROFIT  
    FROM ORDERS  
    GROUP BY STATE, CITY, REGION  
    ORDER BY REGION, T_SALES DESC  
) AS REGION_ANALYSIS  
WHERE CITY = 'Watertown';  


-- Finding those CITIES and STATE where the name of the city is same but in different state.
SELECT 
    region_analysis.region, 
    region_analysis.city, 
    COUNT(region_analysis.city) AS times, 
    GROUP_CONCAT(DISTINCT region_analysis.state ORDER BY region_analysis.state) AS states
FROM (
    SELECT 
        state_province AS state, 
        city, 
        region, 
        SUM(sales) AS t_sales, 
        SUM(profit) AS t_profit
    FROM orders
    GROUP BY state_province, city, region
) AS region_analysis
GROUP BY region_analysis.region, region_analysis.city
HAVING times > 1
ORDER BY region_analysis.region, times DESC;

--  Analyzing p_category, p_sub_category month wise sales.
SELECT  
    DATE_FORMAT(ORDER_DATE, '%Y-%m') AS MONTHLY,  
    PRODUCT_CATEGORY,  
    PRODUCT_SUB_CATEGORY,  
    SUM(SALES) AS SALES  
FROM ORDERS  
GROUP BY 1, 2, 3  
ORDER BY 1, 2, 4 DESC;  
-- Analyzing product category sales month-wise  
SELECT  
    DATE_FORMAT(ORDER_DATE, '%Y-%m') AS MONTHLY,  
    PRODUCT_CATEGORY,  
    SUM(SALES) AS SALES  
FROM ORDERS  
GROUP BY 1, 2  
ORDER BY 1, 2, 3 DESC;  

-- For checking how many cities are being covered
SELECT 
COUNT(*) 
FROM(
	SELECT 
    state_province, 
    city 
    FROM orders
	GROUP BY 1, 2) AS subqury;

-- Finding the no. of time a ship mode is used in each State
SELECT  
STATE,  
SHIPPING,  
COUNT(SHIPPING) AS MODE_COUNT  
FROM (  
    SELECT  
	STATE_PROVINCE AS STATE,  
	CITY,  
	SHIP_MODE AS SHIPPING  
    FROM ORDERS  
    GROUP BY STATE, CITY, SHIP_MODE  
    ORDER BY 1  
) AS NEW_TABLE  
GROUP BY STATE, SHIPPING  
ORDER BY 1, 3 DESC;

-- Getting the most used Delivary Mode Used by Each State
SELECT * FROM (
	SELECT state, 
    shipping, 
    COUNT(shipping) AS mode_count 
    FROM (
		SELECT 
        state_province AS state, 
        city, 
        ship_mode AS shipping
		FROM orders 
        GROUP BY state, city, ship_mode
		ORDER BY 1) AS new_table
	GROUP BY state, shipping) AS result
WHERE mode_count = (
    SELECT MAX(mode_count)
    FROM (
        SELECT state, COUNT(shipping) AS mode_count
        FROM (
            SELECT state_province AS state, city, ship_mode AS shipping
            FROM orders
            GROUP BY state_province, city, ship_mode
        ) AS new_table
        WHERE new_table.state = result.state
        GROUP BY state, shipping
    ) AS max_table
);

-- Finding out the customers who placed orders >= 3 in a month.
SELECT  
    CUSTOMER_ID,  
    CUSTOMER_NAME,  
    DATE_FORMAT(ORDER_DATE, '%Y-%m') AS MONTHLY,  
    COUNT(CUSTOMER_NAME) AS ORDER_NO  
FROM ORDERS  
GROUP BY CUSTOMER_ID, CUSTOMER_NAME, MONTHLY  
HAVING COUNT(CUSTOMER_NAME) >= 3;

#Cross Checking
SELECT * FROM orders
WHERE customer_name = 'Louis Parrish'
AND MONTH(order_date) =  6 ;

-- Finding out customer who placed orderd >= 3 times on different days in a month
SELECT 
    DISTINCT DATE(o.order_date) AS order_date,
    o.customer_id, 
    o.customer_name,
    count(customer_id) over(partition by customer_name) as order_frequency
FROM orders o
WHERE o.customer_id IN (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id, MONTH(order_date)
    HAVING COUNT(DISTINCT DATE(order_date)) >= 3
)
GROUP BY 1,2,3
ORDER BY o.customer_id, DATE(o.order_date);

-- FINDING THE TOP 2 SELLING Products of each category
SELECT * FROM (SELECT 
	product_category, 
    product_name, 
    SUM(sales) AS total_sales, 
    DENSE_RANK() OVER(PARTITION BY product_category ORDER BY SUM(sales) DESC) AS ranking
	FROM orders
	GROUP BY product_category, product_name) AS conditional
WHERE ranking < 3
ORDER BY product_category, total_sales;

SELECT product_name, SUM(sales) 
FROM orders
GROUP BY 1;

-- Finding out the products who's ODV is lower than of the average order value
# USING TEMPORARY TABLES FOR THIS 
CREATE TEMPORARY TABLE sample 
SELECT product_name, ROUND(AVG(sales), 2) AS sales FROM orders GROUP BY 1;
#CROSS CHECKING
SELECT * FROM sample WHERE product_name LIKE 'Motorola%';
# ANSWER
SELECT 
sample.*, 
orders.sales
FROM orders
JOIN sample
ON orders.product_name = sample.product_name
WHERE orders.sales < sample.sales;

-- Finding out the products who's ODV is lower than of the average order value per customer
SELECT 
orders.order_date, 
orders.customer_name, 
sum(orders.sales) AS sales2, 
sample.*
FROM orders 
JOIN sample
ON orders.product_name = sample.product_name
GROUP BY 1,2, sample.sales, sample.product_name
HAVING sales2 < sales;

-- FINDING WHICH REGION HAS THE MOST ACTIVE CLIENTS 
SELECT region, 
COUNT(DISTINCT customer_id), 
SUM(sales) 
FROM orders
GROUP BY region;
-- FURTHER ANALYZING THIS AND CHECKING MONTH WISE NEW CUSTOMER ACQUISATION
SELECT 
MONTH(order_date) AS month_wise, 
region, 
COUNT(DISTINCT customer_id) AS engagement, 
SUM(sales) AS sales
FROM orders
GROUP BY month_wise, region;

-- FINDING CUSTOMERS WHO HAS PURCHASED FROM ALL THE CATEGORIES
SELECT 
customer_id, 
categorizing 
FROM (SELECT 
	customer_id, 
	product_category,
	row_number() OVER(PARTITION BY customer_id) AS categorizing
	FROM orders 
	GROUP BY customer_id, product_category) AS subquery
WHERE categorizing = 3;

-- Number of Customers Per Order Value Bracket
WITH CTE AS (
	SELECT 
		customer_id,
        SUM(sales) AS t_sales
	FROM orders
    GROUP BY customer_id)
SELECT 
	ROUND(t_sales, -2) AS sales_bracket,
    COUNT(DISTINCT customer_id) AS no_of_customers
FROM CTE
GROUP BY sales_bracket
ORDER BY sales_bracket;

use superstore_us_new;

SELECT * FROM orders;

#FINDING PRODUCTS WHICH ARE BEING SOLD ON ALL THE REGIONS 
SELECT * FROM 
	(SELECT 
		product_name, 
		region, 
		RANK() OVER(PARTITION BY product_name ORDER BY product_name, region) AS listing
	FROM orders 
	GROUP BY 1, 2) as happy
WHERE listing = 4;
-- CROSSCHECKING 
SELECT 
	product_name, 
	region 
    FROM orders
WHERE product_name = 'Accessory34'
GROUP BY 1,2;

#FINDING THE NUMBER OF PRODUCT_SUB_CATEGORY SOLD BY EACH REGION
-- Finding out how many types of product_sub_category is there 
SELECT COUNT(DISTINCT product_sub_category) FROM orders;
-- Answer
SELECT 
	region, 
    MAX(category) AS maximum 
FROM (SELECT 
		region, 
        product_sub_category, 
        RANK() OVER(PARTITION BY region ORDER BY region, product_sub_category) AS category
	FROM orders
	GROUP BY 1, 2) AS happy 
GROUP BY region;

-- CUMULATIVE PERCENTAGE OF EACH product_sub_category OF TOTAL SALES
# A different approach
SELECT *, 
	SUM(rev_pct) OVER (ORDER BY rev_pct) AS cumulative_sum_perc FROM (
		SELECT *, 
			ROUND(((revenue / total_sales) * 100), 2) AS rev_pct 
		FROM(
			SELECT 
				product_sub_category, 
                SUM(sales) AS revenue, 
					(SELECT ROUND(SUM(sales), 0) FROM orders) as total_sales
			FROM orders
		GROUP BY 1) as happy
) as happy2;

-- SELECTING THE MOST ORDERD product_sub_category FOR EVERY REGION.
SELECT 
	region, 
    product_sub_category, 
    MAX(occurance) AS max_occurance
FROM (
    SELECT 
		product_sub_category, 
        region, 
        COUNT(product_sub_category) AS occurance 
    FROM orders
    GROUP BY product_sub_category, region
) AS happy
GROUP BY region, product_sub_category
HAVING max_occurance = (
    SELECT MAX(occurance)
    FROM (
        SELECT COUNT(product_sub_category) AS occurance
        FROM orders
        WHERE region = happy.region
        GROUP BY product_sub_category
    ) AS region_occurances
);
-- ALTERNATIVE AND EASY APPROACH
SELECT * FROM (
	SELECT *, 
		DENSE_RANK() OVER(PARTITION BY region ORDER BY occurance DESC) as top_most
	FROM (
		SELECT 
			product_sub_category, 
			region, 
			COUNT(product_sub_category) AS occurance 
		FROM orders
		GROUP BY product_sub_category, region) AS happy
	) as happy2 
HAVING top_most = 1;

-- Finding Customers's First Order Date
WITH first_order AS (SELECT 
	MIN(order_date) as first_order,
	customer_id, 
	customer_name
FROM orders
GROUP BY customer_id, customer_name
ORDER BY first_order),
#LAST ORDER WITH DATE DIFFERENCE
last_order AS (SELECT 
	MIN(order_date) as first_order,
	customer_id, 
	customer_name,
    MAX(order_date) AS last_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS inactive_days
FROM orders
GROUP BY customer_id, customer_name
ORDER BY first_order),
#ANALYZING USING BINS OF 10 DAYS
with_bins AS (SELECT 
	ROUND(inactive_days, -1) AS day_bracket,
    COUNT(customer_id) AS no_of_customers
FROM last_order
GROUP BY day_bracket
ORDER BY day_bracket)

SELECT * FROM last_order;
#crosschecking
SELECT * FROM ORDERS WHERE customer_name = 'Gary Koch';

# Providing customers with coupon if the last order date is more than 118 days
SELECT *,
CASE 
	WHEN last_order >= 118 THEN 'Coupon Eligible'
END AS promotional  
FROM (SELECT * , 
		DATEDIFF(today, last_date) AS last_order 
	FROM (Select customer_id, 
			customer_name,
			MAX(order_date) AS last_date, 
			'2015-06-28' as today 
		FROM orders
		GROUP BY 1,2) as happy
	) as conditional;

# Finding which product_name is the most ordered in which state/province
SELECT * 
FROM (SELECT 
		state_province, 
		product_name, 
		COUNT(product_name) AS occurance,
		DENSE_RANK() OVER(PARTITION BY state_province ORDER BY COUNT(product_name) DESC) AS ranking
	FROM orders
	GROUP BY state_province, product_name
	ORDER BY 1, 3 DESC) as happy
WHERE ranking = 1;

#Finding orders which are more than the average_monthly_sales
WITH CTE AS (
	SELECT month(order_date) as monthly, 
		ROUND(AVG(sales), 0) AS avg_sales
	FROM orders
	GROUP BY monthly),
CTE2 AS (SELECT customer_id,
			MONTH(order_date) AS month_wise, 
			product_name, 
			sales, 
			profit 
        FROM orders)

SELECT * 
FROM CTE2 
LEFT JOIN CTE 
ON CTE2.month_wise = CTE.monthly
WHERE sales > avg_sales;

#Finding orders which have the order_value more than the avg(monthly_region_category_sale) value
WITH CTE AS (
	SELECT month(order_date) as monthly,
		region, 
        product_sub_category, 
        ROUND(AVG(sales), 0) AS avg_sales
	FROM orders
	GROUP BY monthly, region, product_sub_category),
CTE2 AS (
	SELECT customer_id,
		MONTH(order_date) AS month_wise, 
        region, 
        product_sub_category, 
        product_name, 
        sales, 
        profit 
    FROM orders)

SELECT CTE2.customer_id, 
	CTE2.month_wise, 
    CTE2.region, 
    CTE2.product_sub_category, 
    CTE2.product_name, 
    CTE2.sales, 
    CTE2.profit, 
    avg_sales 
FROM CTE2 
LEFT JOIN CTE 
ON CTE2.month_wise = CTE.monthly 
	AND CTE2.product_sub_category = CTE.product_sub_category
	AND CTE2.region = CTE.region
WHERE sales > avg_sales
ORDER BY month_wise, region;

-- TO CHECK THE MOST USED CUSTOMER SEGMENT ORDERS COMING FROM  
SELECT  
    CUSTOMER_SEGMENT,  
    COUNT(CUSTOMER_SEGMENT)  
FROM ORDERS  
GROUP BY CUSTOMER_SEGMENT  
ORDER BY COUNT(CUSTOMER_SEGMENT) ASC;  

-- MOST TO LEAST SOLD PRODUCT/SUB-PRODUCT CATEGORY ORDERED BY REGION  
SELECT  
    PRODUCT_CATEGORY AS PRODUCT,  
    COUNT(PRODUCT_CATEGORY) AS TOTAL_SOLD,  
    PRODUCT_SUB_CATEGORY AS SUB_CATEGORY,  
    REGION  
FROM ORDERS  
GROUP BY PRODUCT, REGION, SUB_CATEGORY  
ORDER BY REGION, TOTAL_SOLD DESC;

-- MOST AND LEAST SALES DONE BASED ON MONTH, STATE, REGION, PRODUCTS, AND SUB-PRODUCT  
WITH MAX_SALES AS (SELECT 
	REGION,
    STATE_PROVINCE,
	PRODUCT_CATEGORY,
    PRODUCT_SUB_CATEGORY,
    SUM(SALES) AS T_SALES,
    RANK() OVER(PARTITION BY PRODUCT_CATEGORY ORDER BY SUM(SALES) DESC) AS MAXIMUM
FROM ORDERS
GROUP BY 1,2,3,4 ),

LEAST_SALES AS (SELECT 
	REGION,
    STATE_PROVINCE,
	PRODUCT_CATEGORY,
    PRODUCT_SUB_CATEGORY,
    SUM(SALES) AS T_SALES,
    RANK() OVER(PARTITION BY PRODUCT_CATEGORY ORDER BY SUM(SALES)) AS MINIMUM
FROM ORDERS
GROUP BY 1,2,3,4)

SELECT * 
FROM MAX_SALES AS M
WHERE MAXIMUM = 1
UNION ALL
SELECT *
FROM 
LEAST_SALES AS L
WHERE MINIMUM = 1;



-- MONTH-WISE SALES DISTRIBUTION  
SELECT  
    MONTH(SALES) AS MONTHLY,  
    SUM(SALES) AS TOTAL  
FROM ORDERS  
GROUP BY MONTHLY  
ORDER BY MONTHLY;  

-- MOST AND LEAST ORDERING CUSTOMERS WITH QUANTITY, SALES, AND PROFIT  
SELECT  
    CUSTOMER_ID,  
    CUSTOMER_NAME,  
    SUM(QUANTITY_ORDERED_NEW) AS QUANTITY,  
    SUM(SALES) AS T_SALES,  
    SUM(PROFIT) AS T_PROFIT  
FROM ORDERS  
GROUP BY CUSTOMER_NAME, CUSTOMER_ID  
ORDER BY SUM(SALES) DESC;  

-- PERIOD WITH THE MOST RETURNED ORDERS REGION-WISE  
SELECT  
    ORDERS.ORDER_ID,  
    O_RETURN.ORDER_ID,  
    ORDERS.REGION,  
    MONTH(ORDERS.ORDER_DATE) AS MONTHLY  
FROM ORDERS  
NATURAL JOIN O_RETURN  
ORDER BY REGION, MONTHLY ASC;

-- ORDER PRIORITY BASED ON REGION AND STATE  
SELECT  
    REGION,  
    STATE_PROVINCE AS STATE, 
    ORDER_PRIORITY,
    COUNT(*) AS counts 
FROM ORDERS   
GROUP BY STATE_PROVINCE, REGION, ORDER_PRIORITY
ORDER BY REGION, STATE, COUNTS DESC;

-- DISTINCT ORDER PRIORITIES  
SELECT ORDER_PRIORITY, COUNT(*) 
FROM ORDERS
GROUP BY ORDER_PRIORITY;  