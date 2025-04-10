create database Apple;

use Apple;
create table stores(
store_id int primary key,
store_name varchar(100),
city varchar(50),
country varchar(50)
);

create table category (
category_id int primary key,
category_name varchar(50)
);

create table product (
product_id int primary key,
product_name varchar(50),
category_id int,
launch_date Date,
price int,
foreign key (category_id) references category(category_id)
);



CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    store_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);

create table warrenty(
claim_id int primary key,
claim_date Date,
sale_id int,
repair_status varchar(80),
foreign key (sale_id) references sales(sale_id)
);

select * from sales;
select * from warrenty;
select * from category;
select * from product;
select * from stores;

UPDATE sales
SET sale_date = DATE_SUB(sale_date, INTERVAL FLOOR(RAND() * 3) YEAR);

-- Find the number of stores in each country.

SELECT 
    country, COUNT(*)
FROM
    stores
GROUP BY country;


-- Calculate the total number of units sold by each store.
  

SELECT 
    s.store_name, SUM(sa.quantity)as total_quantity_sold
FROM
    stores s
        JOIN
    sales sa ON s.store_id = sa.store_id
GROUP BY s.store_name;


-- Identify how many sales occurred in December 2023.

SELECT 
    YEAR(sale_date) AS Y, MONTH(sale_date) AS M, COUNT(quantity)
FROM
    sales
WHERE
    YEAR(sale_date) = '2023'
        AND MONTH(sale_date) = '12'
GROUP BY Y , M;


-- Determine how many stores have never had a warranty claim filed.


SELECT 
    COUNT(DISTINCT a.stores_id) as total_store_without_claimed_warrenty
FROM
    (SELECT 
        st.store_id AS stores_id,
            sa.sale_id AS real1,
            wa.sale_id AS warrenty_not_claimed
    FROM
        stores st
    JOIN sales sa ON st.store_id = sa.store_id
    LEFT JOIN warrenty wa ON sa.sale_id = wa.sale_id
    WHERE
        wa.sale_id IS NULL) a;


-- Calculate the percentage of warranty claims marked as "Warranty Void".

WITH total_warranty_count AS (
    SELECT COUNT(*) AS total_count FROM warrenty
),
count_warranty_void AS (
    SELECT COUNT(*) AS void_count FROM warrenty WHERE repair_status = 'Warranty Void'
)
SELECT 
    (wv.void_count * 100.0) / wc.total_count AS percentage_warranty_void
FROM total_warranty_count wc, count_warranty_void wv;


-- Identify which store had the highest total units sold in the last year.
select * from stores;
select * from sales;

SELECT 
    st.store_name,
    YEAR(sa.sale_date),
    SUM(sa.quantity) AS total_unit_sold
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id
    where YEAR(sa.sale_date)=2022
GROUP BY st.store_name , YEAR(sa.sale_date)
ORDER BY total_unit_sold DESC
limit 1;


-- like if you want to find previous year data then you use curdate in my case my curdate is 
-- 2025 that why i did not get any ou put beacause i have not any data of 2024
SELECT 
    st.store_name,
    SUM(sa.quantity) AS total_unit_sold
FROM stores st
JOIN sales sa ON st.store_id = sa.store_id
WHERE YEAR(sa.sale_date) = YEAR(CURDATE()) - 1  -- Get last year (2022 if current year is 2023)
GROUP BY st.store_name
ORDER BY total_unit_sold DESC
LIMIT 1;

-- Count the number of unique products sold in the last year.
select * from sales;
select * from product;

SELECT DISTINCT
    (p.product_name) AS name,
    YEAR(sa.sale_date) AS yr,
    COUNT(*) AS unique_pro_sold
FROM
    product p
        JOIN
    sales sa ON p.product_id = sa.product_id
WHERE
    YEAR(sa.sale_date) = 2022
GROUP BY name , yr
ORDER BY unique_pro_sold DESC;



-- Find the average price of products in each category.
select * from product;
select * from category;

SELECT 
    c.category_name AS ct_name,
    ROUND(AVG(p.price), 1) AS avg_price
FROM
    category c
        JOIN
    product p ON c.category_id = p.category_id
GROUP BY c.category_name;

-- How many warranty claims were filed in 2024?
select * from sales;
select * from warrenty;

SELECT 
    YEAR(claim_date)as year_claim, COUNT(*) as total_claim_filed
FROM
    warrenty
WHERE
    YEAR(claim_date) = 2024
GROUP BY YEAR(claim_date);

-- Find the top 3 stores that had the highest number of warranty claims in 2023. 
-- Also, display the total revenue lost due to these claims (assuming each claim results in a refund).

select * from sales;
select * from stores;
select * from warrenty;
select * from product;

SELECT 
    st.store_name AS st_name,
    YEAR(wt.claim_date) AS claim_yr,
    COUNT(wt.claim_id) AS claim_warrenty,
    SUM(p.price) AS total_price_loss
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id
        JOIN
    warrenty wt ON sa.sale_id = wt.sale_id
        JOIN
    product p ON sa.product_id = p.product_id
WHERE
    YEAR(wt.claim_date) = 2023
GROUP BY st.store_name , claim_yr
ORDER BY claim_warrenty DESC
LIMIT 3;

-- Question:
-- For each product category, calculate:
-- Total units sold in 2023.
-- Total warranty claims filed in 2023.
-- Claim percentage ((claims/total sales) * 100).Sort the results by the highest claim percentage.

select * from category;

SELECT 
    a.ct_name,
    a.sa_yr,
    a.total_unit_sold,
    a.warrenty_filled,
    ROUND((a.warrenty_filled / NULLIF(a.total_unit_sold, 0)) * 100,
            2) AS prct_claim
FROM
    (SELECT 
        ct.category_name AS ct_name,
            YEAR(sa.sale_date) AS sa_yr,
            SUM(sa.quantity) AS total_unit_sold,
            COUNT(wt.claim_id) AS warrenty_filled
    FROM
        category ct
    JOIN product p ON ct.category_id = p.category_id
    JOIN sales sa ON p.product_id = sa.product_id
    LEFT JOIN warrenty wt ON sa.sale_id = wt.sale_id
    WHERE
        YEAR(sa.sale_date) = 2023
    GROUP BY ct_name , sa_yr
    ORDER BY total_unit_sold DESC) a
ORDER BY prct_claim DESC
;


-- For each store, identify the best-selling day based on highest quantity sold.

with storesales as(
select st.store_name as st_name,
day(sa.sale_date) as bussiest_day, 
sum(sa.quantity) as item_sold,
rank() over(partition by st.store_name order by sum(sa.quantity) desc) as rnk
from stores st join sales sa on st.store_id=sa.store_id
group by st_name,bussiest_day
)
select st_name,bussiest_day,item_sold from storesales where rnk = 1;

-- 👉 Find the best-selling product for each store on its busiest sales day.

with storesales as
(select 
st.store_name as st_name,
date(sa.sale_date) as bussiest_day,
sum(sa.quantity) as item_sold,
rank() over(partition by st.store_name order by sum(sa.quantity) desc) as rnk
from stores st join sales sa on
st.store_id=sa.store_id group by st_name,bussiest_day
),
product_sales as (
select st.store_name as st_name,
p.product_name as p_name,
date(sa.sale_date) as bussiest_day,
sum(sa.quantity) as product_sold,
rank() over(partition by st.store_name,date(sa.sale_date) order by sum(sa.quantity) desc) as rnk
from stores st join sales sa on
st.store_id=sa.store_id join product p on
sa.product_id=p.product_id GROUP BY st.store_name, p.product_name, Date(sa.sale_date)
)
SELECT pb.st_name, pb.p_name, sb.bussiest_day, pb.product_sold
FROM storesales sb
JOIN product_sales pb 
ON sb.st_name = pb.st_name AND sb.bussiest_day = pb.bussiest_day
WHERE sb.rnk = 1 AND pb.rnk = 1
ORDER BY sb.st_name;


-- 👉 Compare sales performance across different days of the week for each store.


WITH DailySales AS (
    SELECT 
        st.store_name AS st_name, 
        DAYNAME(sa.sale_date) AS sale_day, 
        SUM(sa.quantity) AS total_sold,
        ROUND(AVG(sa.quantity), 2) AS avg_daily_sales
    FROM stores st
    JOIN sales sa ON st.store_id = sa.store_id
    GROUP BY st.store_name, sale_day
)
SELECT 
    ds.*, 
    (ds.total_sold - LAG(ds.total_sold) OVER (PARTITION BY ds.st_name ORDER BY FIELD(ds.sale_day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'))) 
    AS sales_change
FROM DailySales ds
ORDER BY ds.st_name, FIELD(ds.sale_day, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');


-- Identify the least selling product in each country for each year based on total units sold.

with Productsale as
(select
st.country as country,
p.product_name as p_name,
sum(sl.quantity) as total_sold,
year(sl.sale_date) as date_sale,
rank() over(partition by st.country,year(sl.sale_date) order by sum(sl.quantity) asc) as rnk
from stores st join sales sl
on st.store_id=sl.store_id join
product p on sl.product_id=p.product_id group by country,p_name,date_sale)
select country,p_name,total_sold,date_sale from Productsale where rnk=1
order by country, date_sale asc;

-- 👉 Identify products that were the least selling in a country for at least 2 consecutive years.
with 2021_sale as (
select
st.country as country,
p.product_name as p_name,
sum(sl.quantity) as total_sold,
year(sl.sale_date) as date_sale,
rank() over(partition by st.country,year(sl.sale_date) order by sum(sl.quantity) asc) as rnk
from stores st join sales sl
on st.store_id=sl.store_id join
product p on sl.product_id=p.product_id
where year(sl.sale_date) = 2021 group by country,p_name,date_sale),
2022_sale as(
select
st.country as country,
p.product_name as p_name,
sum(sl.quantity) as total_sold,
year(sl.sale_date) as date_sale,
rank() over(partition by st.country,year(sl.sale_date) order by sum(sl.quantity) asc) as rnk
from stores st join sales sl
on st.store_id=sl.store_id join
product p on sl.product_id=p.product_id
where year(sl.sale_date) = 2022 group by country,p_name,date_sale),
2023_sale as (
select
st.country as country,
p.product_name as p_name,
sum(sl.quantity) as total_sold,
year(sl.sale_date) as date_sale,
rank() over(partition by st.country,year(sl.sale_date) order by sum(sl.quantity) asc) as rnk
from stores st join sales sl
on st.store_id=sl.store_id join
product p on sl.product_id=p.product_id
where year(sl.sale_date) = 2023 group by country,p_name,date_sale)
select
s1.country, s2.p_name,s1.total_sold
from 2021_sale s1 join
2022_sale s2 on s1.country=s2.country and
s1.p_name=s2.p_name where s1.rnk=1 and s2.rnk=1
union
SELECT s2.country, s2.p_name,s2.total_sold
FROM 2022_sale s2
JOIN 2023_sale s3 ON s2.country = s3.country AND s2.p_name = s3.p_name
WHERE s2.rnk = 1 AND s3.rnk = 1;


-- Calculate how many warranty claims were filed within 180 days of a product sale.
select * from sales;
select * from warrenty;
select * from product;

SELECT 
    a.sale_date,
    a.claim_date,
    DATEDIFF(a.claim_date, a.sale_date) AS days_diff
FROM
    (SELECT 
        sa.sale_date, wa.claim_date
    FROM
        sales sa
    JOIN warrenty wa ON sa.sale_id = wa.sale_id) a
WHERE
    DATEDIFF(a.claim_date, a.sale_date) < 180;


SELECT 
    COUNT(*) AS total_warenty_clain_within_180
FROM
    (SELECT 
        sa.sale_date, wa.claim_date
    FROM
        sales sa
    JOIN warrenty wa ON sa.sale_id = wa.sale_id) a
WHERE
    DATEDIFF(a.claim_date, a.sale_date) < 180;
    
    
    
-- Find the top 5 products with the highest percentage of warranty claims within 90 days of the sale.
-- Return product_id, product_name, total_sales, total_claims, claim_percentage sorted by claim percentage in descending order.


WITH total_claim AS (
    SELECT 
        p.product_name, 
        SUM(sa.quantity) AS total_item_sold,
        COUNT(wa.claim_id) AS total_claim
    FROM product p 
    JOIN sales sa ON p.product_id = sa.product_id 
    LEFT JOIN warrenty wa ON sa.sale_id = wa.sale_id
    GROUP BY p.product_name
),
90_days AS (
    SELECT 
        p.product_name AS p_name,
        COUNT(wa.claim_id) AS claim_within_90days
    FROM product p 
    JOIN sales sa ON p.product_id = sa.product_id 
    LEFT JOIN warrenty wa ON sa.sale_id = wa.sale_id
    WHERE DATEDIFF(wa.claim_date, sa.sale_date) <= 90  
    GROUP BY p.product_name
)
SELECT 
    tc.product_name, 
    tc.total_item_sold,
    tc.total_claim,
    COALESCE(d.claim_within_90days, 0) AS claim_within_90days,
    ROUND((COALESCE(d.claim_within_90days, 0) / NULLIF(tc.total_claim, 0)) * 100, 2) AS percentage_claim_within_90days
FROM total_claim tc
LEFT JOIN 90_days d ON tc.product_name = d.p_name
order by percentage_claim_within_90days desc limit 5;

-- Analyze how the number of warranty claims has changed over 
-- the last 12 months, showing the monthly trend in the number of claims.

select * from warrenty;
select * from sales;

SELECT 
    YEAR(claim_date) AS year_claimed,
    MONTHNAME(claim_date) AS month_name,
    MONTH(claim_date) AS month_claimed,
    COUNT(*)
FROM
    warrenty
WHERE
    repair_status IS NOT NULL
    AND repair_status != ''
    AND repair_status != 'Warrenty Void'
        AND YEAR(claim_date) = 2023
GROUP BY YEAR(claim_date) , MONTH(claim_date),month_name
ORDER BY month_claimed ASC;

-- List the months in the last three years where sales exceeded in the USA.

SELECT 
    st.country AS country,
    YEAR(sa.sale_date) AS sales_year,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity) AS total_sold
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id
WHERE
    country = 'USA'
GROUP BY country , sales_year , month_name , sales_month
ORDER BY sales_year , sales_month;

-- see how each month's sales changed across years (2021 → 2021 → 2023)

select * from product;
select * from sales;

with 2021_yr as (
SELECT 
    YEAR(sa.sale_date) AS sales_year_21,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity*p.price) AS total_sold_21
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2021
GROUP BY sales_year_21 , month_name , sales_month
ORDER BY sales_year_21 , sales_month ),
2022_yr as(
SELECT 
    YEAR(sa.sale_date) AS sales_year_22,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity*p.price) AS total_sold_22
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2022
GROUP BY sales_year_22, month_name , sales_month
ORDER BY sales_year_22 , sales_month ),
2023_yr as (
SELECT 
    YEAR(sa.sale_date) AS sales_year_23,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity*p.price) AS total_sold_23
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2023
GROUP BY sales_year_23 , month_name , sales_month
ORDER BY sales_year_23 , sales_month)
select
2023_yr.month_name,
2021_yr.total_sold_21,
2022_yr.total_sold_22,
2023_yr.total_sold_23,
cASE 
        WHEN 2021_yr.total_sold_21 < 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 < 2023_yr.total_sold_23 THEN 'Increasing'
        WHEN 2021_yr.total_sold_21 > 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 > 2023_yr.total_sold_23 THEN 'Decreasing'
        WHEN 2021_yr.total_sold_21 = 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 = 2023_yr.total_sold_23 THEN 'Stable'
        ELSE 'Fluctuating'
    END AS trend
from
2021_yr join 2022_yr on
2021_yr.month_name=2022_yr.month_name join
2023_yr on 2022_yr.month_name=2023_yr.month_name;

-- Which month saw the highest % increase in sales compared to the same month in the previous year?

with 2022_yr as(
SELECT 
    YEAR(sa.sale_date) AS sales_year_22,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity*p.price) AS total_sold_22
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2022
GROUP BY sales_year_22, month_name , sales_month
ORDER BY sales_year_22 , sales_month ),
2023_yr as (
SELECT 
    YEAR(sa.sale_date) AS sales_year_23,
    MONTHNAME(sa.sale_date) AS month_name,
    MONTH(sa.sale_date) AS sales_month,
    SUM(sa.quantity*p.price) AS total_sold_23
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2023
GROUP BY sales_year_23 , month_name , sales_month
ORDER BY sales_year_23 , sales_month)
select
2023_yr.month_name,
2022_yr.total_sold_22,
2023_yr.total_sold_23,
cASE 
        WHEN 2022_yr.total_sold_22 < 2023_yr.total_sold_23 THEN 'Increasing'
        WHEN 2022_yr.total_sold_22 > 2023_yr.total_sold_23 THEN 'Decreasing'
        WHEN 2022_yr.total_sold_22 = 2023_yr.total_sold_23 THEN 'Stable'
        ELSE 'Fluctuating'
    END AS trend,
ROUND(((2023_yr.total_sold_23 - 2022_yr.total_sold_22) / NULLIF(2023_yr.total_sold_23 + 2022_yr.total_sold_22, 0)) * 100, 2) AS pct_change_22_23   
from
2022_yr join 2023_yr on
2022_yr.month_name=2023_yr.month_name
order by pct_change_22_23 desc;


-- Analyze the year-by-year growth ratio for each store.
select * from stores;

with 2021_yr as (
SELECT
    st.store_name as st_name,
    YEAR(sa.sale_date) AS sales_year_21,
    SUM(sa.quantity*p.price) AS total_sold_21
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2021
GROUP BY sales_year_21 ,st_name
ORDER BY sales_year_21),
2022_yr as(
SELECT
    st.store_name as st_name,
    YEAR(sa.sale_date) AS sales_year_22,
    SUM(sa.quantity*p.price) AS total_sold_22
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2022
GROUP BY sales_year_22, st_name
ORDER BY sales_year_22),
2023_yr as (
SELECT
    st.store_name as st_name, 
    YEAR(sa.sale_date) AS sales_year_23,
    SUM(sa.quantity*p.price) AS total_sold_23
FROM
    stores st
        JOIN
    sales sa ON st.store_id = sa.store_id join
    product p on sa.product_id=p.product_id
WHERE
    year(sa.sale_date) = 2023
GROUP BY sales_year_23 , st_name
ORDER BY sales_year_23)
select
2023_yr.st_name,
2021_yr.total_sold_21,
2022_yr.total_sold_22,
2023_yr.total_sold_23,
	ROUND(((2022_yr.total_sold_22 - 2021_yr.total_sold_21) / NULLIF(2022_yr.total_sold_22 + 2021_yr.total_sold_21, 0)) * 100, 2) AS pct_change_21_22,
    ROUND(((2023_yr.total_sold_23 - 2022_yr.total_sold_22) / NULLIF(2023_yr.total_sold_23 + 2022_yr.total_sold_22, 0)) * 100, 2) AS pct_change_22_23,
CASE 
        WHEN 2021_yr.total_sold_21 < 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 < 2023_yr.total_sold_23 THEN 'Increasing'
        WHEN 2021_yr.total_sold_21 > 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 > 2023_yr.total_sold_23 THEN 'Decreasing'
        WHEN 2021_yr.total_sold_21 = 2022_yr.total_sold_22 AND 2022_yr.total_sold_22 = 2023_yr.total_sold_23 THEN 'Stable'
        ELSE 'Fluctuating'
    END AS trend
from
2021_yr join 2022_yr on
2021_yr.st_name=2022_yr.st_name join
2023_yr on 2022_yr.st_name=2023_yr.st_name;

-- Calculate the correlation between product price and warranty claims for products sold in the one years, segmented by price range.

select * from sales;
select * from product;
select * from warrenty;


SELECT 
    CASE
        WHEN p.price < 500 THEN 'Below 500'
        WHEN p.price BETWEEN 500 AND 999 THEN '500-999'
        WHEN p.price BETWEEN 1000 AND 1499 THEN '1000-1499'
        ELSE '1500+'
    END AS Price_segment,
    COUNT(w.claim_id) AS total_warrenty_claim,
    COUNT(DISTINCT s.sale_id) AS total_sales,
    ROUND(COUNT(w.claim_id) / COUNT(DISTINCT s.sale_id), 4) AS claim_rate
FROM sales s
JOIN product p ON s.product_id = p.product_id
LEFT JOIN warrenty w ON s.sale_id = w.sale_id
GROUP BY Price_segment
ORDER BY 
    CASE 
        WHEN Price_segment = 'Below 500' THEN 1
        WHEN Price_segment = '500-999' THEN 2
        WHEN Price_segment = '1000-1499' THEN 3
        WHEN Price_segment = '1500+' THEN 4
    END;

-- Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed.


with Paid_rep_claim as (
select
st.store_name as st_name,
count(w.claim_id) as Paid_Repaired_claim
from sales sa join stores st on sa.store_id=st.store_id left join
warrenty w on sa.sale_id=w.sale_id 
where w.repair_status = 'Paid Repaired'
group by st_name
),
total_claim as(
select
st.store_name as st_name,
count(w.claim_id) as total_claim
from sales sa join stores st on sa.store_id=st.store_id left join
warrenty w on sa.sale_id=w.sale_id 
group by st_name
)
select 
pr.st_name,
pr.Paid_Repaired_claim,
tc.total_claim,
ROUND(pr.Paid_Repaired_claim * 100.0 / NULLIF(tc.total_claim, 0), 2) AS prct_pr_claim
from Paid_rep_claim pr join
total_claim tc on
pr.st_name=tc.st_name;

-- Write a query to calculate the monthly running total of sales for each store over the past three years and compare trends during this period.

WITH 2021_yr AS (
    SELECT
        st.store_name AS st_name,
        YEAR(sa.sale_date) AS sales_year_21,
        MONTH(sa.sale_date) AS month_num,
        MONTHNAME(sa.sale_date) AS month_name,
        SUM(sa.quantity * p.price) AS total_sold_21,
        SUM(SUM(sa.quantity * p.price)) OVER (
            PARTITION BY st.store_name, YEAR(sa.sale_date)
            ORDER BY MONTH(sa.sale_date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_21
    FROM
        stores st
        JOIN sales sa ON st.store_id = sa.store_id
        JOIN product p ON sa.product_id = p.product_id
    WHERE
        YEAR(sa.sale_date) = 2021
    GROUP BY st.store_name, sales_year_21, month_num, month_name
),
2022_yr AS (
    SELECT
        st.store_name AS st_name,
        YEAR(sa.sale_date) AS sales_year_22,
        MONTH(sa.sale_date) AS month_num,
        MONTHNAME(sa.sale_date) AS month_name,
        SUM(sa.quantity * p.price) AS total_sold_22,
        SUM(SUM(sa.quantity * p.price)) OVER (
            PARTITION BY st.store_name, YEAR(sa.sale_date)
            ORDER BY MONTH(sa.sale_date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_22
    FROM
        stores st
        JOIN sales sa ON st.store_id = sa.store_id
        JOIN product p ON sa.product_id = p.product_id
    WHERE
        YEAR(sa.sale_date) = 2022
    GROUP BY st.store_name, sales_year_22, month_num, month_name
),
2023_yr AS (
    SELECT
        st.store_name AS st_name,
        YEAR(sa.sale_date) AS sales_year_23,
        MONTH(sa.sale_date) AS month_num,
        MONTHNAME(sa.sale_date) AS month_name,
        SUM(sa.quantity * p.price) AS total_sold_23,
        SUM(SUM(sa.quantity * p.price)) OVER (
            PARTITION BY st.store_name, YEAR(sa.sale_date)
            ORDER BY MONTH(sa.sale_date)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_23
    FROM
        stores st
        JOIN sales sa ON st.store_id = sa.store_id
        JOIN product p ON sa.product_id = p.product_id
    WHERE
        YEAR(sa.sale_date) = 2023
    GROUP BY st.store_name, sales_year_23, month_num, month_name
)
SELECT
    y21.st_name,
    y21.month_name,
    y21.total_sold_21,
    y21.running_total_21,
    y22.total_sold_22,
    y22.running_total_22,
    y23.total_sold_23,
    y23.running_total_23
FROM
    2021_yr y21
    JOIN 2022_yr y22 ON y21.st_name = y22.st_name AND y21.month_name = y22.month_name
    JOIN 2023_yr y23 ON y22.st_name = y23.st_name AND y22.month_name = y23.month_name
ORDER BY
    y21.st_name,
    FIELD(y21.month_name, 
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December');