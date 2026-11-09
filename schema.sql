--E-Commerce RFM Analysis - Database Schema Setup

DROP TABLE IF EXISTS raw_transactions;

CREATE TABLE raw_transactions (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INT,
    invoice_date VARCHAR(50), 
    unit_price DECIMAL(10, 2),
    customer_id INT,
    country VARCHAR(50)
);