SELECT
    COUNT(*)                                                    AS total_orders,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)          AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)       AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)      AS null_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END)   AS null_purchase_date,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_actual_delivery,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM olist_orders_dataset;

SELECT
    order_id,
    order_status,
    CAST(order_purchase_timestamp AS DATETIME)        AS purchase_date,
    CAST(order_delivered_customer_date AS DATETIME)   AS actual_delivery,
    CAST(order_estimated_delivery_date AS DATETIME)   AS estimated_delivery,

    DATEDIFF(
        day,
        CAST(order_estimated_delivery_date AS DATETIME),
        CAST(order_delivered_customer_date AS DATETIME)
    ) AS days_late,

    CASE
        WHEN CAST(order_delivered_customer_date AS DATETIME)
             <= CAST(order_estimated_delivery_date AS DATETIME)
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status

FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

  SELECT
    o.order_id,
    o.order_status,
    CAST(o.order_purchase_timestamp AS DATETIME)        AS purchase_date,
    CAST(o.order_delivered_customer_date AS DATETIME)   AS actual_delivery,
    CAST(o.order_estimated_delivery_date AS DATETIME)   AS estimated_delivery,

    DATEDIFF(
        day,
        CAST(o.order_estimated_delivery_date AS DATETIME),
        CAST(o.order_delivered_customer_date AS DATETIME)
    ) AS days_late,

    CASE
        WHEN CAST(o.order_delivered_customer_date AS DATETIME)
             <= CAST(o.order_estimated_delivery_date AS DATETIME)
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    r.review_score,
    r.review_comment_title,
    r.review_comment_message

FROM olist_orders_dataset o
LEFT JOIN olist_order_reviews_dataset r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL;

  SELECT
    CASE
        WHEN CAST(o.order_delivered_customer_date AS DATETIME)
             <= CAST(o.order_estimated_delivery_date AS DATETIME)
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,

    COUNT(o.order_id)                       AS total_orders,
    AVG(CAST(r.review_score AS FLOAT))      AS avg_review_score,
    MIN(r.review_score)                     AS min_review_score,
    MAX(r.review_score)                     AS max_review_score

FROM olist_orders_dataset o
LEFT JOIN olist_order_reviews_dataset r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY
    CASE
        WHEN CAST(o.order_delivered_customer_date AS DATETIME)
             <= CAST(o.order_estimated_delivery_date AS DATETIME)
        THEN 'On Time'
        ELSE 'Late'
    END
ORDER BY avg_review_score DESC;