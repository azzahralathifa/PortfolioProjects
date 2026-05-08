--query 1 : percentage of late deliveries by seller
--business question : which seller are most responsible for late deliveries

SELECT
    i.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT o.order_id)                                      AS total_orders,
    SUM(
        CASE
            WHEN CAST (o.order_delivered_customer_date as DATE)
               > CAST (o.order_estimated_delivery_date as DATE) THEN 1
            ELSE 0
        END
    )                                                               AS late_orders,
  CAST(
    ROUND(
        1.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date THEN 1
                ELSE 0
            END
        ) / COUNT(DISTINCT o.order_id), 4
    )
AS DECIMAL(10,2)) AS late_delivery_pct
FROM olist_orders_dataset o
JOIN olist_order_items_dataset  i ON o.order_id   = i.order_id
JOIN olist_sellers_dataset      s ON i.seller_id  = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_status = 'delivered'
GROUP BY i.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 10 
ORDER BY late_delivery_pct DESC;

--query 2 : average review score by product category
-- business question : do certain product categoies concistently generate lower customer satisfaction scores

SELECT
    p.product_category_name                     AS category,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS avg_review_score,
    MIN(CAST(r.review_score AS FLOAT))			AS min_score,
	MAX(CAST(r.review_score AS FLOAT))			AS max_score                         
FROM olist_orders_dataset           o
JOIN olist_order_reviews_dataset    r ON o.order_id    = r.order_id
JOIN olist_order_items_dataset      i ON o.order_id    = i.order_id
JOIN olist_products_dataset         p ON i.product_id  = p.product_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 30   
ORDER BY avg_review_score ASC;   


-- Query 3: Average review score segmented by delivery delay Business Question
SELECT
    CASE
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) <= 0
            THEN '1 — On Time'
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) BETWEEN 1 AND 3
            THEN '2 — 1 to 3 Days Late'
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) BETWEEN 4 AND 7
            THEN '3 — 4 to 7 Days Late'
        ELSE '4 — More than 7 Days Late'
    END                                     AS delay_segment,
    COUNT(*)                                AS total_orders,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS avg_review_score,
    
	ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1
    )                                       AS pct_of_total_orders
FROM olist_orders_dataset           o
JOIN olist_order_reviews_dataset    r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_status = 'delivered'
GROUP BY
    CASE
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) <= 0
            THEN '1 — On Time'
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) BETWEEN 1 AND 3
            THEN '2 — 1 to 3 Days Late'
        WHEN DATEDIFF(day, o.order_estimated_delivery_date, 
                           o.order_delivered_customer_date) BETWEEN 4 AND 7
            THEN '3 — 4 to 7 Days Late'
        ELSE '4 — More than 7 Days Late'
    END
ORDER BY delay_segment;

-- Query 4: Average review score by seller state
-- Business Question: Is poor delivery performance geographically concentrated among specific seller regions?

SELECT
    s.seller_state,
    COUNT(DISTINCT o.order_id)					AS total_orders,
    ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS avg_review_score,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date
               > o.order_estimated_delivery_date THEN 1
            ELSE 0
        END
    )                                       AS late_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date
                   > o.order_estimated_delivery_date THEN 1
                ELSE 0
            END
        ) / COUNT(DISTINCT o.order_id), 4
    )                                       AS late_delivery_pct
FROM olist_orders_dataset           o
JOIN olist_order_reviews_dataset    r ON o.order_id   = r.order_id
JOIN olist_order_items_dataset      i ON o.order_id   = i.order_id
JOIN olist_sellers_dataset          s ON i.seller_id  = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_status = 'delivered'
GROUP BY s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY avg_review_score ASC;


-- Query 5: Executive KPI summary
-- Business Question: What is the overall delivery and satisfaction health of the platform, and how much
-- does lateness specifically damage review scores?

WITH kpi AS (
    SELECT
        COUNT(DISTINCT o.order_id) AS total_orders,

        SUM(CASE
            WHEN o.order_delivered_customer_date
               <= o.order_estimated_delivery_date THEN 1 ELSE 0
        END) AS on_time_orders,

        SUM(CASE
            WHEN o.order_delivered_customer_date
               > o.order_estimated_delivery_date THEN 1 ELSE 0
        END) AS late_orders,

        AVG(CAST(r.review_score AS FLOAT)) AS avg_score_overall,

        AVG(CASE
            WHEN o.order_delivered_customer_date
               <= o.order_estimated_delivery_date
            THEN CAST(r.review_score AS FLOAT)
        END) AS avg_score_on_time,

        AVG(CASE
            WHEN o.order_delivered_customer_date
               > o.order_estimated_delivery_date
            THEN CAST(r.review_score AS FLOAT)
        END) AS avg_score_late

    FROM olist_orders_dataset        o
    JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND o.order_status = 'delivered'
)

SELECT
    total_orders,
    ROUND(100.0 * on_time_orders / total_orders, 2) AS pct_on_time,
    ROUND(100.0 * late_orders    / total_orders, 2) AS pct_late,
    ROUND(avg_score_overall,  2)                    AS avg_review_score_overall,
    ROUND(avg_score_on_time,  2)                    AS avg_review_on_time,
    ROUND(avg_score_late,     2)                    AS avg_review_late,
    ROUND(avg_score_on_time - avg_score_late, 2)    AS review_score_impact_of_lateness
FROM kpi;