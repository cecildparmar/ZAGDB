-- Creating Calendar Dimension Table

CREATE TABLE calendar_dim (
calendarkey int,
Full_Date DATE, 
dayofweek varchar(20),
dayofmonth varchar(3),
month_1 varchar (5),
qty varchar (5),
year_1 varchar(5))

Insert into calendar_dim
SELECT row_number() over(order by dayofmonth asc) as calendarkey, *
from (select distinct tdate as "Full_Date", to_char(tdate, 'day') as dayofweek,
extract (day from tdate) dayofmonth, to_char(tdate, 'MON') as month_1,
'Q' || extract (QUARTER from tdate) Qty,
extract (year from tdate) year_1 from salestransaction) aa;
	  
select * from calendar_dim

-- Creating Product Dimension Table

CREATE TABLE product_dim AS
SELECT ROW_NUMBER() OVER(ORDER BY productid ASC) AS productkey, *
FROM (SELECT p.productid, p.productname, p.productprice, v.vendorname, c.categoryname FROM product p
	 JOIN vendor v ON v.vendorid = p.vendorid
	 JOIN category c ON p.categoryid = c.categoryid
GROUP BY p.productid, p.productname, v.vendorname, c.categoryname
ORDER BY p.productid, p.productname, v.vendorname, c.categoryname) aa;

SELECT * FROM product_dim;

-- Creating Intermediate Tables

CREATE TABLE layouttype (layoutid char(1) not null, layout varchar(25));
INSERT INTO layouttype values ('1', 'Traditional');
CREATE TABLE checkoutsystem (CSID char (2), Csystem varchar (20));
INSERT INTO checkoutsystem values ('MX', 'Mixed');
ALTER TABLE store ADD COLUMN csid char(2);
ALTER TABLE store ADD COLUMN ltid char (1);
ALTER TABLE store ADD COLUMN store_size integer;
SELECT * FROM store
UPDATE store SET CSID = 'MX', ltid = '1', store_size = 55000 WHERE storeid = 'S3';
UPDATE store SET CSID = 'SS', ltid = '2', store_size = 35000 WHERE storeid = 'S2';
UPDATE store SET CSID = 'CR', ltid = '3', store_size = 51000 WHERE storeid = 'S1';

SELECT * FROM store ORDER BY 1;
INSERT INTO layouttype values ('2', 'Traditional');
INSERT INTO layouttype values ('3', 'Modern');
INSERT INTO checkoutsystem values ('SS', 'Self Service');
INSERT INTO checkoutsystem values ('CR', 'Cashiers');
SELECT * FROM checkoutsystem
SELECT ROW_NUMBER() OVER (ORDER BY storeid asc) as storekey, * from (
SELECT s.storeid, s.storezip, s.store_size, r.regionname, c.csystem, l.layout from store s join region r on r.regionid = s.regionid
join layouttype l on l.layoutid = s.ltid
join checkoutsystem c on c.csid = s.csid) aa

-- Creating Store_Dim Table

CREATE TABLE store_dim as
SELECT ROW_NUMBER() OVER (ORDER BY storeid asc) as storekey, * from (
SELECT s.storeid, s.storezip, s.store_size, r.regionname, c.csystem, l.layout from store s join region r on r.regionid = s.regionid
join layouttype l on l.layoutid = s.ltid
join checkoutsystem c on c.csid = s.csid) aa

SELECT * FROM store_dim;

-- Creating Customer_Dim Table

SELECT * FROM customer
ALTER TABLE customer ADD COLUMN gender char(2);
ALTER TABLE customer ADD COLUMN marital_status char(10);
ALTER TABLE customer ADD COLUMN education_level char(10);
ALTER TABLE customer ADD COLUMN credit_score integer;

UPDATE customer set gender= 'F', marital_status= 'Single', education_level= 'College', credit_score = '700' WHERE customerid = '1-2-333'; 
UPDATE customer set gender= 'M', marital_status= 'Single', education_level= 'HSchool', credit_score = '650' WHERE customerid = '2-3-444';
UPDATE customer set gender= 'F', marital_status= 'Married', education_level= 'College', credit_score = '600' WHERE customerid = '3-4-555';

SELECT * FROM customer ORDER BY 1;

CREATE TABLE customer_dim AS
SELECT ROW_NUMBER() OVER (ORDER BY customerid asc) as CustomerKey, * from (
select * from customer where customerid!='0-1-222' order by 1)aa

SELECT * FROM customer_dim

-- Create Sales_Detailed_Fact table

CREATE TABLE SALES_DETAILED_FACT AS 
SELECT calendarkey, storekey, productkey, customerkey, ss.tid, to_char(tdate, 'HH:MM:SS') AS TIMEOFDAY,
productprice AS dollarssold, noofitems AS unitssold
FROM calendar_dim, store_dim, product_dim, customer_dim, salestransaction ss, soldvia WHERE 1=2;

SELECT * FROM SALES_DETAILED_FACT

-- Add primary keys to dimension table
-- Add foreign keys to sales_detailed_fact table

ALTER TABLE calendar_dim ADD PRIMARY KEY (calendarkey); 
ALTER TABLE store_dim ADD PRIMARY KEY (storekey); 
ALTER TABLE product_dim ADD PRIMARY KEY (productkey); 
ALTER TABLE customer_dim ADD PRIMARY KEY (customerkey);

ALTER TABLE SALES_DETAILED_FACT ADD CONSTRAINT FK_calendarkey FOREIGN KEY (calendarkey) REFERENCES calendar_dim(calendarkey);
ALTER TABLE SALES_DETAILED_FACT ADD CONSTRAINT FK_storekey FOREIGN KEY (storekey) REFERENCES store_dim(storekey);
ALTER TABLE SALES_DETAILED_FACT ADD CONSTRAINT FK_productkey FOREIGN KEY (productkey) REFERENCES product_dim(productkey);
ALTER TABLE SALES_DETAILED_FACT ADD CONSTRAINT FK_customerkey FOREIGN KEY (customerkey) REFERENCES customer_dim(customerkey);

INSERT INTO SALES_DETAILED_FACT SELECT cld.calendarkey, sd.storekey, pd.productkey, cd.customerkey, e.tid, to_char(st.tdate, 'HH:MM:SS'),
noofitems as dollars_sold, e.noofitems
FROM product_dim AS pd
LEFT JOIN soldvia e
ON pd.productid = e.productid
LEFT JOIN salestransaction st
on e.tid = st.tid
LEFT JOIN customer_dim cd
ON st.customerid = cd.customerid
LEFT JOIN store_dim sd
ON st.storeid = sd.storeid
LEFT JOIN product p
ON pd.productid = p.productid
LEFT JOIN calendar_dim cld ON
st.tdate = cld.full_date

select * from sales_detailed_fact

-- Create sales_dps_fact table and insert values

CREATE TABLE SALES_DPS_FACT AS
SELECT calendarkey, storekey, productkey, productprice as dollarssold, noofitems as unitssold
FROM calendar_dim, store_dim, product_dim, customer_dim, salestransaction ss, soldvia where 1=2;

ALTER TABLE SALES_DPS_FACT ADD CONSTRAINT FK_CALENDARKEY FOREIGN KEY (calendarkey) REFERENCES calendar_dim(calendarkey);
ALTER TABLE SALES_DPS_FACT ADD CONSTRAINT FK_STOREKEY FOREIGN KEY (storekey) REFERENCES store_dim(storekey);
ALTER TABLE SALES_DPS_FACT ADD CONSTRAINT FK_PRODUCTKEY FOREIGN KEY (productkey) REFERENCES product_dim(productkey);

INSERT INTO SALES_DPS_FACT SELECT cld.calendarkey, sd.storekey, pd.productkey, p.productprice,
e.noofitems as dollars_sold 
FROM product_dim AS pd
LEFT JOIN soldvia e
ON pd.productid = e.productid
LEFT JOIN salestransaction st
on e.tid = st.tid
LEFT JOIN customer_dim cd
ON st.customerid = cd.customerid
LEFT JOIN store_dim sd
ON st.storeid = sd.storeid
LEFT JOIN product p
ON pd.productid = p.productid
LEFT JOIN calendar_dim cld ON
st.tdate = cld.full_date

SELECT * FROM SALES_DPS_FACT;


