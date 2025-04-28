/* ASSIGNMENT 2 */
/*Selection 1 
Prompt 3
The store wants to keep customer addresses. Propose two architectures for the CUSTOMER_ADDRESS table, one that will retain changes, and another that will overwrite. Which is type 1, which is type 2?

HINT: search type 1 vs type 2 slowly changing dimensions.

Customer_addresses (type 2 - which retains history)
Address_ID
customer_id
country
province
city 
street
start_date
end_date
is_current

customer_addresses (type 1 - which over writes historical info)
address_id
customer_id
country
province
city 
street 
*/

/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM products

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

SELECT 
product_name || ', ' || 
coalesce(product_size, '')|| ' (' || 
coalesce(product_qty_type, 'unit')|| ')'
FROM product

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

select 
market_date
, customer_id
,row_number () OVER(PARTITION by customer_id order by market_date) as visit_number
from customer_purchases

-- dense rank 

select 
market_date
, customer_id
,dense_rank () OVER(PARTITION by customer_id order by market_date) as visit_number
from customer_purchases


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

--outer query
select 
market_date
, customer_id
, visit_number

FROM 
(	
	select 
	market_date
	, customer_id
	,row_number () OVER(PARTITION by customer_id order by market_date DESC) as visit_number
	from customer_purchases
) 

where visit_number = 1


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

-- include a value with each row of the customer purcases that indicates how many times that customer purchased that product_id 
-- so it would be like a row number function against  customer_id and market_date?

SELECT 
  product_id,
  customer_id,
  market_date,
  COUNT(*) OVER (PARTITION BY customer_id, product_id) AS purchase_count
FROM customer_purchases;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

-- trimming
SELECT
product_name
, trim (product_name) as product_name_trimmed
from product 

-- only capturing organic but the remaining is not null 
-- if it's just the column + number, it is the starting position and will give you what's remaining 
SELECT
product_name
, substr (product_name, 10) 
from product 

-- instr 
SELECT
product_name
, instr (product_name, '-') as hyphen_placement 
from product 


-- putting it together somehow 
-- + 1 gets rid of the hyphen 
-- instr will give you the position of the hyphen, if no hyphen then it's 0 which will be null at the END
-- substr product_name and 2 (for example) would have us at the start position of 2 and return everything remaining 
-- but substr + instr and (+1) it says, find the position of the hyphen plus 1 to not include the space afterward and return what's left i.e. organic, jar, bag
-- if no hyphen then null 

select 
product_name

,	case
		when instr (product_name, '-') > 0 then 
			trim (substr(product_name, instr(product_name, '-') + 1))
		else null 
	end as hyphen_check

from product

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

select product_size
from product
where product_size REGEXP '[0-9]'

-- putting it together? 
select 
product_name
, product_size
,	case
		when instr (product_name, '-') > 0 then 
			trim (substr(product_name, instr(product_name, '-') + 1))
		else null 
	end as hyphen_check

from product
where product_size REGEXP '[0-9]'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- union: combine the results of two or more queries vertically (removes the duplicates)
-- step 1: daily total sales by market date
-- step 2: rank total sales, highest and lowest
-- step 3: union 

drop table if exists temp.total_daily_sales;

create temp table temp.total_daily_sales as 
select 
	market_date
	, sum (cost_to_customer_per_qty * quantity) as total_sales_per_day
from customer_purchases
group by market_date;

Select 
market_date
, total_sales_per_day

FROM (
	select 
		market_date
		, total_sales_per_day
		, row_number () over (order by total_sales_per_day DESC) as daily_sales_rank
	from temp.total_daily_sales
) as ranked_sales 
where daily_sales_rank = 1

UNION 

Select 
market_date
, total_sales_per_day

FROM (
	select 
		market_date
		, total_sales_per_day
		, row_number () over (order by total_sales_per_day ASC) as daily_sales_rank
	from temp.total_daily_sales
) as ranked_sales 
where daily_sales_rank = 1


/* SECTION 3 */

-- FOR DD: NEED TO REVIEW
-- Cross Join 
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.


HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

-- "how much money would each vendor make per product?" isn't this just asking what the price of each product is x 5?
-- return will be 8 rows*
-- i want vendor_id, vendor_name, product_id, product_name, cost_to_customer_per_qty * 5, 

select DISTINCT 
vendor_id
from vendor_inventory
-- 3 distict vendors 

select DISTINCT 
product_id
from vendor_inventory
-- 8 distinct product ids 

select DISTINCT
customer_id
from customer_purchases
-- 26 total customer ids 

-- hmmmmmm
SELECT 
    vi.vendor_id
    , cp.product_id
    , cp.cost_to_customer_per_qty * 5 AS cost_times_5
FROM vendor_inventory vi
INNER JOIN customer_purchases cp 
    ON vi.product_id = cp.product_id

	
-- done with help but still really unsure 

tips 
-- cross join for inventory and vendor
-- and use above then cross join with customers 
-- create temp table and query from the temp table to avoid using subquery 

drop table if exists vendor_x_product 

create temp table vendor_x_product as 
select 
vi.vendor_id
, vi.product_id
, p.product_name
from vendor_inventory vi
INNER join product p
on vi.product_id = p.product_id 

drop table if exists vendor_name_x_product 

create temp table vendor_name_x_product as 
select 
vp.vendor_id
, vp.product_id
, vp.product_name
, v.vendor_name
from vendor_x_product vp
INNER join vendor v 
on vp.vendor_id = v.vendor_id 


drop table if exists vendor_x_product_x_customer

create temp table vendor_x_product_x_customer as
select 
vp.vendor_id
, vp.vendor_name
, vp.product_id
, vp.product_name
, cp.customer_id
, cp.cost_to_customer_per_qty
from vendor_name_x_product vp
cross join customer_purchases cp
on vp.product_id = cp.product_id 

select 
vendor_id
, vendor_name
, product_id
, product_name
, cost_to_customer_per_qty
, (cost_to_customer_per_qty * 5 * 26) as earnings_per_product 
from vendor_x_product_x_customer

group by vendor_id, vendor_name, product_id, product_name



	
-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
SELECT *,
	CURRENT_TIMESTAMP AS snapshot_timestamp
	FROM product
	WHERE 1 = 0;
INSERT INTO product_units
SELECT *,
	CURRENT_TIMESTAMP
	FROM product
	WHERE product_qty_type = 'unit'

	select *
	from product_units


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

insert into product_units
values (101, 'Passionfruit pie', 'big and juicy', 111, 'unit', CURRENT_TIMESTAMP) 


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM product_units
WHERE product_id = 101
AND snapshot_timestamp < (
    SELECT MAX(snapshot_timestamp)
    FROM product_units
    WHERE product_id = 101
)


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units
ADD current_quantity INT;

-- how to get the "last" quantity per product 

SELECT 
  product_id,
  MAX(quantity) AS last_quantity
FROM vendor_inventory
GROUP BY product_id;

-- update 
UPDATE product_units
SET current_quantity = COALESCE((
    SELECT MAX(vi.quantity)
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
), 0)


-- very lost on update..

