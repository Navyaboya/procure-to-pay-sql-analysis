create database p2p_project;
use p2p_project;

create table sellers (
seller_id varchar(50) primary key,
seller_zip_code_prefix int,
seller_city varchar(100),
seller_state varchar(5)
);

CREATE TABLE orders (
  order_id VARCHAR(50) PRIMARY KEY,
  customer_id VARCHAR(50),
  order_status VARCHAR(20),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date DATETIME,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2)
);

CREATE TABLE order_payments (
  order_id VARCHAR(50),
  payment_sequential INT,
  payment_type VARCHAR(30),
  payment_installments INT,
  payment_value DECIMAL(10,2)
);

CREATE USER 'loader'@'localhost' IDENTIFIED BY 'Load1234';
GRANT ALL PRIVILEGES ON p2p_project.* TO 'loader'@'localhost';