-- =========================================================
--                  PIZZA SALES ANALYSIS
-- =========================================================


-- 1. Retrieve the total number of orders placed.

SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
    
    
    
-- 2. Calculate the total revenue generated from pizza sales.

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM
    order_details od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id;
    
    
    
-- 3. Identify the highest-priced pizza.

-- Approach 1. MAX() in FROM clause

SELECT 
    pt.name, a.price
FROM
    (SELECT 
        MAX(price) AS price
    FROM
        pizzas) a
        JOIN
    pizzas p ON a.price = p.price
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id;    
    
-- Approach 2. ORDER BY + LIMIT

SELECT 
    pt.name, p.price
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- Approach 3. MAX() in WHERE clause

SELECT 
    pt.name, p.price
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
WHERE
    p.price = (SELECT 
            MAX(price)
        FROM
            pizzas);
            
            
            
-- 4. Identify the most common pizza size ordered.

-- Approach 1. With LIMIT
SELECT 
    p.size, SUM(od.quantity) AS times_ordered
FROM
    pizzas p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY times_ordered DESC
LIMIT 1;

-- Approach 2. With CTE

with cte as (select p.size, sum(od.quantity) as times_ordered from order_details od
			 join pizzas p on od.pizza_id = p.pizza_id
             group by p.size)
select *
from cte
where times_ordered = (select max(times_ordered) from cte);



-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name, SUM(od.quantity) AS quantity
FROM
    pizzas p
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY quantity DESC
LIMIT 5;



-- 6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pt.category, SUM(od.quantity) as quantity
FROM
    pizzas p
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category;



-- 7. Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(order_time) AS order_hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY order_hour
ORDER BY order_hour;



-- 8. Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    pt.category, SUM(od.quantity) AS quantity
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category;



-- 9. Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    ROUND(AVG(quantity),2) AS avg_pizzas_ordered_per_day
FROM
    (SELECT 
        o.order_date, SUM(od.quantity) AS quantity
    FROM
        orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_date) pizzas_per_day;
    
    
    
-- 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM(od.quantity * p.price) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;



-- 11. Calculate the percentage contribution of each pizza type to total revenue.

WITH cte_total_revenue AS (SELECT SUM(od.quantity * p.price) as total_revenue
						   FROM order_details od
                           JOIN pizzas p on od.pizza_id = p.pizza_id)
SELECT 
    pt.name, ROUND(SUM(od.quantity * p.price)/c.total_revenue * 100,2) AS revenue_percentage
FROM
    pizza_types pt
        JOIN
    pizzas p ON p.pizza_type_id = pt.pizza_type_id
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
    JOIN cte_total_revenue c
GROUP BY pt.name, c.total_revenue
ORDER by revenue_percentage DESC;



-- 12. Analyze the cumulative revenue generated over time.

SELECT order_date,
revenue,
ROUND(SUM(revenue) OVER(ORDER by order_date),2) as cumulative_revenue FROM 
(SELECT o.order_date,
ROUND(SUM(od.quantity * p.price),2) as revenue
FROM orders o
JOIN order_details od on o.order_id = od.order_id
JOIN pizzas p on od.pizza_id = p.pizza_id
GROUP BY o.order_date) revenue_per_day;



-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH cte1 as 
(SELECT 
    pt.category, pt.name, ROUND(SUM(od.quantity * p.price),2) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.category , pt.name),

cte2 as (SELECT category, name, revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS ranking
FROM cte1)

SELECT * from cte2
WHERE ranking < 4;