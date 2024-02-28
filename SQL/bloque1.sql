-- We firstly calculate the ranked products by number of sales taking into account products that didn't have any order.
-- We then get all the results from the products ranking that have the at least the same amount of sells than the product
-- ranked number 10. We do this because the 7 first products have no sales but there are 4 products that have the same amount
-- of sales (1 sale) and we shouldn't leave any of those outside of the ranking. We cannot cut just on 10 least product sold
-- because, how can we chose what product is number 10? Ordering? Is it fair? That is why we should answer this way

WITH ranked_products AS (
  SELECT
    products.product_id,
    COALESCE(SUM(orderlines.product_qty), 0) AS total_sells,
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(orderlines.product_qty), 0), products.product_id) AS rank_n
  FROM
    products
  LEFT JOIN
    orderlines ON orderlines.product_id = products.product_id
  GROUP BY
    products.product_id
)
SELECT
  product_id,
  total_sells
FROM
  ranked_products
WHERE
  total_sells <= (SELECT total_sells FROM ranked_products WHERE rank_n = 10)
ORDER BY
  total_sells, product_id;

-- On this question we also make use of a CTE to firstly calculate what is the value of the mean basket value per gender
-- We the query to get the customers whose mean basket value is less than the mean basket value given their gender
WITH mean_basket AS (
  SELECT
    customers.gender,
    AVG(orderlines.product_price * orderlines.product_qty) AS avg_basket_value
  FROM
    orderlines
  JOIN
    customers ON orderlines.customer_id = customers.customer_id
  GROUP BY
    customers.gender
)
SELECT
  customers.customer_id,
  customers.gender,
  AVG(orderlines.product_price * orderlines.product_qty) AS avg_customer_basket
FROM
  orderlines
JOIN
  customers ON orderlines.customer_id = customers.customer_id
GROUP BY
  customers.customer_id, customers.gender
HAVING
  AVG(orderlines.product_price * orderlines.product_qty) < 
    (SELECT avg_basket_value FROM mean_basket WHERE mean_basket.gender = customers.gender);

-- We get the difference between current timestamp (current date) and the last order made by a certain customer
-- calculated with max(order_ts)
SELECT
	customer_id,
  MAX(order_ts),
	DATE_PART('day', CURRENT_TIMESTAMP - MAX(order_ts)) as days_recency
FROM
  orderlines
GROUP BY customer_id
ORDER BY days_recency

-- The function NTILE(3) automatically assigns a tier to each of the rows depending on the values calculated on total
-- earnings for each of the products. The ordering of the OVER function assigns the highest tier to the highest earnings
-- We then order it for presentation purposes
SELECT
  product_id,
  NTILE(3) OVER (ORDER BY SUM(product_price * product_qty)) AS tier,
  SUM(product_price * product_qty) AS total_earnings
FROM
  orderlines
GROUP BY
	product_id
ORDER BY
	tier DESC, product_id