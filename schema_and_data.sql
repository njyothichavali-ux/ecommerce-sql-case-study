-- ============================================================
-- E-COMMERCE BUSINESS INTELLIGENCE CASE STUDY
-- Dataset: Simulated UK Online Retail (based on UCI Online Retail II)
-- Author: Naga Jyothi Chavali
-- ============================================================

-- ── TABLE DEFINITIONS ────────────────────────────────────────

CREATE TABLE customers (
    customer_id     VARCHAR(20) PRIMARY KEY,
    country         VARCHAR(50),
    signup_date     DATE,
    customer_segment VARCHAR(20)   -- 'New', 'Returning', 'VIP'
);

CREATE TABLE products (
    product_id      VARCHAR(20) PRIMARY KEY,
    description     VARCHAR(200),
    category        VARCHAR(50),
    unit_price      DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id        VARCHAR(20),
    customer_id     VARCHAR(20) REFERENCES customers(customer_id),
    order_date      DATE,
    status          VARCHAR(20),   -- 'Completed', 'Cancelled', 'Returned'
    PRIMARY KEY (order_id)
);

CREATE TABLE order_items (
    order_item_id   SERIAL PRIMARY KEY,
    order_id        VARCHAR(20) REFERENCES orders(order_id),
    product_id      VARCHAR(20) REFERENCES products(product_id),
    quantity        INT,
    unit_price      DECIMAL(10,2),  -- price at time of purchase
    discount_pct    DECIMAL(5,2) DEFAULT 0
);

-- ── SAMPLE DATA ──────────────────────────────────────────────

INSERT INTO customers VALUES
('CUST001','United Kingdom','2022-01-15','VIP'),
('CUST002','United Kingdom','2022-03-10','Returning'),
('CUST003','Germany','2022-06-01','New'),
('CUST004','France','2022-07-22','New'),
('CUST005','United Kingdom','2021-11-05','VIP'),
('CUST006','United Kingdom','2023-01-10','New'),
('CUST007','Ireland','2022-09-14','Returning'),
('CUST008','United Kingdom','2021-08-30','VIP'),
('CUST009','Netherlands','2023-02-18','New'),
('CUST010','United Kingdom','2022-12-01','Returning');

INSERT INTO products VALUES
('PROD001','Ceramic Mug Set','Kitchenware',12.99),
('PROD002','Scented Candle Pack','Home Decor',18.50),
('PROD003','Linen Cushion Cover','Home Decor',14.99),
('PROD004','Bamboo Chopping Board','Kitchenware',24.99),
('PROD005','Woollen Throw Blanket','Textiles',49.99),
('PROD006','Glass Water Bottle','Kitchenware',16.99),
('PROD007','Essential Oil Diffuser','Wellness',34.99),
('PROD008','Leather Notebook','Stationery',22.50),
('PROD009','Beeswax Wraps Pack','Kitchen',9.99),
('PROD010','Herb Garden Starter Kit','Garden',29.99);

INSERT INTO orders VALUES
('ORD001','CUST001','2023-01-05','Completed'),
('ORD002','CUST002','2023-01-12','Completed'),
('ORD003','CUST001','2023-02-03','Completed'),
('ORD004','CUST003','2023-02-14','Cancelled'),
('ORD005','CUST005','2023-03-01','Completed'),
('ORD006','CUST004','2023-03-15','Returned'),
('ORD007','CUST006','2023-04-02','Completed'),
('ORD008','CUST001','2023-04-18','Completed'),
('ORD009','CUST007','2023-05-05','Completed'),
('ORD010','CUST008','2023-05-20','Completed'),
('ORD011','CUST002','2023-06-08','Completed'),
('ORD012','CUST009','2023-06-22','Cancelled'),
('ORD013','CUST005','2023-07-10','Completed'),
('ORD014','CUST010','2023-07-28','Completed'),
('ORD015','CUST008','2023-08-14','Completed'),
('ORD016','CUST001','2023-09-01','Completed'),
('ORD017','CUST003','2023-09-18','Completed'),
('ORD018','CUST006','2023-10-05','Returned'),
('ORD019','CUST005','2023-10-22','Completed'),
('ORD020','CUST010','2023-11-09','Completed'),
('ORD021','CUST008','2023-11-25','Completed'),
('ORD022','CUST001','2023-12-10','Completed'),
('ORD023','CUST002','2023-12-20','Completed');

INSERT INTO order_items VALUES
(DEFAULT,'ORD001','PROD001',2,12.99,0),
(DEFAULT,'ORD001','PROD002',1,18.50,0),
(DEFAULT,'ORD002','PROD003',3,14.99,5),
(DEFAULT,'ORD003','PROD005',1,49.99,10),
(DEFAULT,'ORD003','PROD006',2,16.99,0),
(DEFAULT,'ORD004','PROD007',1,34.99,0),
(DEFAULT,'ORD005','PROD001',4,12.99,0),
(DEFAULT,'ORD005','PROD008',1,22.50,0),
(DEFAULT,'ORD006','PROD003',2,14.99,15),
(DEFAULT,'ORD007','PROD009',5,9.99,0),
(DEFAULT,'ORD007','PROD010',1,29.99,0),
(DEFAULT,'ORD008','PROD002',2,18.50,5),
(DEFAULT,'ORD008','PROD004',1,24.99,0),
(DEFAULT,'ORD009','PROD006',1,16.99,0),
(DEFAULT,'ORD009','PROD007',1,34.99,0),
(DEFAULT,'ORD010','PROD005',2,49.99,10),
(DEFAULT,'ORD010','PROD008',2,22.50,0),
(DEFAULT,'ORD011','PROD001',3,12.99,0),
(DEFAULT,'ORD011','PROD009',2,9.99,0),
(DEFAULT,'ORD012','PROD010',1,29.99,0),
(DEFAULT,'ORD013','PROD002',3,18.50,0),
(DEFAULT,'ORD013','PROD005',1,49.99,15),
(DEFAULT,'ORD014','PROD003',4,14.99,0),
(DEFAULT,'ORD014','PROD004',2,24.99,5),
(DEFAULT,'ORD015','PROD007',1,34.99,0),
(DEFAULT,'ORD015','PROD001',5,12.99,10),
(DEFAULT,'ORD016','PROD006',3,16.99,0),
(DEFAULT,'ORD016','PROD010',2,29.99,0),
(DEFAULT,'ORD017','PROD008',1,22.50,0),
(DEFAULT,'ORD017','PROD002',2,18.50,5),
(DEFAULT,'ORD018','PROD009',3,9.99,0),
(DEFAULT,'ORD019','PROD005',2,49.99,0),
(DEFAULT,'ORD019','PROD007',1,34.99,10),
(DEFAULT,'ORD020','PROD001',2,12.99,0),
(DEFAULT,'ORD020','PROD004',1,24.99,0),
(DEFAULT,'ORD021','PROD003',3,14.99,5),
(DEFAULT,'ORD021','PROD010',1,29.99,0),
(DEFAULT,'ORD022','PROD002',4,18.50,0),
(DEFAULT,'ORD022','PROD005',1,49.99,10),
(DEFAULT,'ORD023','PROD006',2,16.99,0),
(DEFAULT,'ORD023','PROD008',1,22.50,0);
