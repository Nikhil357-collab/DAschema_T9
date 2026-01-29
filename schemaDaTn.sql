use superstore;
 CREATE TABLE dim_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) UNIQUE
);

CREATE TABLE dim_product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    UNIQUE(product_name, category, sub_category)
);

CREATE TABLE dim_region (
    region_id SERIAL PRIMARY KEY,
    region VARCHAR(100),
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    UNIQUE(region, country, state, city)
);

CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    order_date DATE UNIQUE,
    year INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT
);
-- Create Fact Table (Foreign Keys)

CREATE TABLE fact_sales (
    sales_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES dim_customer(customer_id),
    product_id INT REFERENCES dim_product(product_id),
    region_id INT REFERENCES dim_region(region_id),
    date_id INT REFERENCES dim_date(date_id),
    sales NUMERIC(10,2),
    quantity INT,
    discount NUMERIC(5,2),
    profit NUMERIC(10,2)
);
-- Insert Distinct Values into Dimensions
INSERT INTO dim_customer (customer_name)
SELECT DISTINCT customer_name
FROM global_superstore;
SELECT * FROM dim_customer;fact_sales
-- Product Dimension
INSERT INTO dim_product (product_name, category, sub_category)
SELECT DISTINCT product_name, category, sub_category
FROM global_superstore;
-- Region Dimension
INSERT INTO dim_region (region, country, state, city)
SELECT DISTINCT region, country, state, city
FROM global_superstore;
-- Date Dimension
INSERT INTO dim_date ( ship_date, year, month, month_name, quarter)
SELECT DISTINCT
    ship_date,
    EXTRACT(YEAR FROM ),
    EXTRACT(MONTH FROM ),
    TO_CHAR(order_date, 'Month'),
    EXTRACT(QUARTER FROM )
FROM global_superstore;

-- Insert Transactions into Fact Table (Key Mapping)
INSERT INTO fact_sales (
    customer_id,
    product_id,
    region_id,
    sales,
    quantity,
    discount,
    profit
)
SELECT
    c.customer_id,
    p.product_id,
    r.region_id,
    g.sales,
    g.quantity,
    g.discount,
    g.profit
FROM global_superstore g
JOIN dim_customer c ON g.customer_name = c.customer_name
JOIN dim_product p ON g.product_name = p.product_name
                  AND g.category = p.category
                  AND g.sub_category = p.sub_category
JOIN dim_region r ON g.region = r.region
                 AND g.country = r.country
                 AND g.state = r.state
                 AND g.city = r.city;

CREATE INDEX idx_fact_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_region ON fact_sales(region_id);
CREATE INDEX idx_fact_date ON fact_sales(date_id);


-- Analytics Queries (Star Schema Joins)
-- Total Sales by Region
SELECT r.region, SUM(f.sales) AS total_sales
FROM fact_sales f
JOIN dim_region r ON f.region_id = r.region_id
GROUP BY r.region;
-- Monthly Sales Trend
SELECT d.year, d.month, SUM(f.sales) AS monthly_sales
FROM fact_sales f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- Top 5 Products by Profit
SELECT p.product_name, SUM(f.profit) AS total_profit
FROM fact_sales f
JOIN dim_product p ON f.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Validation (Data Quality Checks)
SELECT
    (SELECT COUNT(*) FROM global_superstore) AS source_rows,
    (SELECT COUNT(*) FROM fact_sales) AS fact_rows;

-- Missing Key Validation
SELECT COUNT(*) AS orphan_records
FROM fact_sales
WHERE customer_id IS NULL
   OR product_id IS NULL
   OR region_id IS NULL
   OR date_id IS NULL;
-- 