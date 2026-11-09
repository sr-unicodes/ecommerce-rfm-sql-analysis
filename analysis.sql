-- E-Commerce RFM Analysis - Data Cleaning & Scoring

-- PHASE 1: CONVERT TEXT DATES TO PROPER TIMESTAMPS

-- The original Kaggle dataset stores dates as text. We must convert these to true PostgreSQL timestamps so we can mathematically subtract them later to find customer Recency.

ALTER TABLE raw_transactions ADD COLUMN proper_date TIMESTAMP;

UPDATE raw_transactions SET proper_date = TO_TIMESTAMP(invoice_date, 'MM/DD/YY HH24:MI');

ALTER TABLE raw_transactions DROP COLUMN invoice_date;

ALTER TABLE raw_transactions RENAME COLUMN proper_date TO invoice_date;




-- PHASE 2: CREATE A CLEAN DATASET

-- Filtering out guest checkouts (NULL IDs) and canceled/returned orders (negative quantities). Including returns would artificially deflate our revenue calculations, and guest checkouts cannot be tracked for loyalty metrics.

DROP TABLE IF EXISTS clean_transactions;

CREATE TABLE clean_transactions AS
SELECT 
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date,
    unit_price,
    customer_id,
    country,
    (quantity * unit_price) AS total_amount
FROM raw_transactions
WHERE customer_id IS NOT NULL 
  AND quantity > 0 
  AND unit_price > 0;





-- PHASE 3: CALCULATE RFM SCORES
-- Aggregating 400,000+ transaction rows into a single summary profile per customer. This gives us the raw Recency, Frequency, and Monetary metrics needed to group them into marketing tiers.

DROP TABLE IF EXISTS rfm_scores;

CREATE TABLE rfm_scores AS 
SELECT
    customer_id,
    EXTRACT(DAY FROM (SELECT MAX(invoice_date) FROM clean_transactions) - MAX(invoice_date)) AS recency,
    COUNT(DISTINCT invoice_no) AS frequency,
    SUM(total_amount) AS monetary_value
FROM clean_transactions
GROUP BY customer_id;




--Phase 4: Customer Segmentation

-- Applying business logic to categorize customers into actionable marketing tiers 
-- based on their RFM scores. This enables targeted campaigns, like rewarding 
-- high-value shoppers (VIPs) or re-engaging inactive ones (Churn Risk).

DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments AS
SELECT 
    customer_id,
    recency,
    frequency,
    monetary_value,
    CASE
    WHEN monetary_value > 5000 and frequency > 10 then 'VIP'
    when recency > 180 THEN 'Churn Risk'
    ELSE 'Standard Customer'
    END as customer_segment
    from rfm_scores;

--PHASE 5: DATA VALIDATION

-- A quick sanity check to count the total number of customers in each segment 
-- to ensure our CASE WHEN logic distributed the users correctly.

SELECT customer_segment, COUNT(customer_id) 
FROM customer_segments 
GROUP BY customer_segment;
