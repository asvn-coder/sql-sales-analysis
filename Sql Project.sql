select * from city;

select * from customers;

select * from sales;

select * from products;


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

Select 
	city_name,
	Round((population * 0.25)/1000000,2) As Coffee_consumer,
	city_rank
From city
Order By 2 Desc;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

Select *
From sales
Where 
	Extract(Year From sale_date) = 2023
	And Extract(QUARTER From sale_date) = 4


Select 
	ci.city_name,
	Sum(s.total) As total_revenue	
From sales As s 
Join customers As c 
On s.customer_id = c.customer_id
Join city As ci
On ci.city_id = c.city_id
Where 
	Extract(Year From s.sale_date) = 2023
	And 
	Extract(QUARTER From s.sale_date) = 4
Group By 1 
Order By 2 Desc
	

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?


Select 
	p.product_name,
	Count(s.sale_id) as Total_orders
From products as p 
Left Join 
sales as s 
On s.product_id = p.product_id
Group By 1
Order by 2 Desc


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

Select 
	ci.city_name,
	Sum(s.total) As total_revenue,
	Count(Distinct s.customer_id) As total_cx,
	Round(Sum(s.total)/Count(Distinct s.customer_id),2) As avg_sale_pr_cx
From sales As s 
Join customers As c 
On s.customer_id = c.customer_id
Join city As ci
On ci.city_id = c.city_id
Group By 1 
Order By 2 Desc

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

With city_table As 

(Select 
	city_name,
	Round((population *0.25) / 1000000 , 2) As coffee_consumers
From city),


customers_table
As
(Select 
	ci.city_name,
	Count(Distinct c.customer_id) As unique_cx
From sales As s 
Join customers As c 
On c.customer_id = s.customer_id
Join city As ci
On ci.city_id = c.city_id
Group By 1)

Select 
	customers_table.city_name,
	city_table.coffee_consumers As coffee_consumers_in_millions,
	customers_table.unique_cx
From city_table
Join customers_table
On city_table.city_name = customers_table.city_name


-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

Select 
	ci.city_name,
	p.product_name,
	Count(s.sale_id) As total_orders,
	Dense_Rank() Over(Partition By ci.city_name Order By Count(s.sale_id) Desc) As Rank
From sales as s 
Join products as p 
On s.product_id = p.product_id
Join customers as c 
On c.customer_id = s.customer_id
Join city as ci
On ci.city_id = c.city_id
Group By 1, 2



-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?


Select 
	ci.city_name,
	Count(Distinct c.customer_id) As unique_cx
From city As ci 
Left Join 
customers As c
On c.city_id = ci.city_id
Join sales As s 
On s.customer_id = c.customer_id
Where 
	s.product_id In (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
Group By 1 



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

With city_table
As 

(Select 
	ci.city_name,
	Count(Distinct s.customer_id) As total_cx,
	Round(Sum(s.total)/Count(Distinct s.customer_id),2) As avg_sale_pr_cx
From sales As s 
Join customers As c 
On s.customer_id = c.customer_id
Join city As ci
On ci.city_id = c.city_id
Group By 1 
Order By 2 Desc),


city_rent
As 
(Select 
	city_name,
	estimated_rent
From city)

Select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	Round(cr.estimated_rent/ct.total_cx, 2) As avg_rent_pr_cx
From city_rent As cr
Join city_table As ct 
On cr.city_name = ct.city_name
Order By 5 Desc




-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city


With monthly_sales
As
(
	Select 
		ci.city_name,
		Extract(Month From sale_date) As month,
		Extract(Year From sale_date) As year,
		sum(s.total) As total_sale
	From sales As s 
	Join customers As c
	On c.customer_id = s.customer_id
	Join city As ci
	On ci.city_id = c.city_id
	Group By 1, 2, 3
	Order By 4 Desc
),
growth_ratio
As
(
	Select 
		city_name,
		month,
		year,
		total_sale As cr_month_sale,
		Lag(total_sale, 1) Over(Partition By city_name Order By year, month) As last_month_sale
	From monthly_sales
)

Select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	Round((cr_month_sale-last_month_sale)/last_month_sale * 100 ,2) As growth_ratio
From growth_ratio
Where
	last_month_sale Is Not Null

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

With city_table
As 

(Select 
	ci.city_name,
	Sum(s.total) As total_revenue,
	Count(Distinct s.customer_id) As total_cx,
	Round(Sum(s.total)/Count(Distinct s.customer_id),2) As avg_sale_pr_cx
From sales As s 
Join customers As c 
On s.customer_id = c.customer_id
Join city As ci
On ci.city_id = c.city_id
Group By 1 
Order By 2 Desc),


city_rent
As 
(Select 
	city_name,
	estimated_rent,
	Round(population * 0.25/1000000, 2) As estimated_coffee_consumer
From city)

Select 
	cr.city_name,
	total_revenue,
	cr.estimated_rent As total_rent,
	ct.total_cx,
	estimated_coffee_consumer,
	ct.avg_sale_pr_cx,
	Round(cr.estimated_rent/ct.total_cx, 2) As avg_rent_pr_cx
From city_rent As cr
Join city_table As ct 
On cr.city_name = ct.city_name
Order By 4 Desc


