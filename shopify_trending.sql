select * from shopify
-- Product Performance
-- Which products generate the highest total revenue?
select product_name, estimated_revenue_in_2025_usd as total_revenue
from shopify
order by total_revenue desc
limit 10
-- Which products sell the highest number of units?
select product_id, product_name, estimated_total_units_sold_in_2025
from shopify
order by estimated_total_units_sold_in_2025 desc
limit 10
-- Are top-revenue products high-priced items or high-volume items?
WITH avg_analysis AS (
    SELECT
        product_name,
        estimated_revenue_in_2025_usd,
        avg_price_usd,
        estimated_total_units_sold_in_2025,

        AVG(avg_price_usd) OVER () AS avg_price,
        AVG(estimated_total_units_sold_in_2025) OVER () AS avg_units

    FROM shopify
)

SELECT
    product_name,
    estimated_revenue_in_2025_usd AS total_revenue,
    avg_price_usd,
    estimated_total_units_sold_in_2025,

    CASE
        WHEN avg_price_usd > avg_price THEN 'High-Priced'
        ELSE 'Low-Priced'
    END AS price_category,

    CASE
        WHEN estimated_total_units_sold_in_2025 > avg_units THEN 'High-Volume'
        ELSE 'Low-Volume'
    END AS volume_category

FROM avg_analysis
ORDER BY total_revenue DESC
-- Category Performance

-- Which product categories generate the most revenue?
select category, sum(estimated_revenue_in_2025_usd) as revenue
from shopify
group by category
order by revenue desc
-- Which categories have the highest units sold?
select category, 
-- Are there categories with high trend scores but low sales?
with category_trend as (
select category, avg(trend_score) as avg_trend,
avg(estimated_revenue_in_2025_usd) as avg_sales
from 
shopify
group by category
)
select 
category,
round(avg_trend::numeric, 2) as avg_trend,
round(avg_sales::numeric, 2) as avg_sales,
case
	when avg_trend > (select avg(avg_trend) from category_trend) then 'High Trend' else 'Low Trend'
end as trend_structure,
case 
	when avg_sales < (select avg(avg_sales) from category_trend) then 'Low Sales' else 'High Sales'
end as sales_structure
from
category_trend
order by avg_sales desc
-- Platform Comparison (Shopify vs TikTok Shop)
select trend_source, sum(estimated_revenue_in_2025_usd) as revenue
from 
shopify
group by trend_source
order by revenue
limit 2
-- Which platform contributes more revenue?
select trend_source, sum(estimated_revenue_in_2025_usd) as revenue
from shopify
group by trend_source
order by revenue desc
-- Which platform has higher unit sales?
select trend_source, 
sum(estimated_total_units_sold_in_2025) as total_units
from
shopify
group by trend_source 
order by total_units desc
-- Are certain categories performing better on TikTok Shop vs Shopify?
SELECT
    trend_source,
    category,
    SUM(estimated_revenue_in_2025_usd) AS total_revenue,
    SUM(estimated_total_units_sold_in_2025) AS total_units_sold
FROM shopify
WHERE trend_source IN ('Shopify Trending List', 'TikTok Shop Viral')
GROUP BY trend_source, category

-- Trend Score Analysis

-- Do products with higher trend scores sell more?
WITH trend_analysis AS (
    SELECT
        product_name,
        trend_score,
        estimated_total_units_sold_in_2025,
        estimated_revenue_in_2025_usd,
        AVG(trend_score) OVER () AS avg_trend_score
    FROM shopify
)
SELECT
    product_name,
    trend_score,
    estimated_total_units_sold_in_2025,
    estimated_revenue_in_2025_usd
FROM trend_analysis
WHERE trend_score > avg_trend_score;


-- High Trend & Low Revenue
WITH avg_values AS (
    SELECT
        product_name,
        trend_score,
        estimated_revenue_in_2025_usd,

        AVG(trend_score) OVER () AS avg_trend_score,
        AVG(estimated_revenue_in_2025_usd) OVER () AS avg_revenue
    FROM shopify
)

SELECT
    product_name,
    trend_score,
    estimated_revenue_in_2025_usd,

    CASE
        WHEN trend_score > avg_trend_score THEN 'High Trend'
        ELSE 'Low Trend'
    END AS trend_status,

    CASE
        WHEN estimated_revenue_in_2025_usd < avg_revenue THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS revenue_status

FROM avg_values
WHERE trend_score > avg_trend_score
  AND estimated_revenue_in_2025_usd < avg_revenue
ORDER BY trend_score DESC;