SELECT * FROM gdb023.dim_customer;

-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select distinct market
FROM dim_customer
WHERE region="APAC" and customer="Atliq Exclusive"
ORDER BY market;

 -- What is the percentage of unique product increase in 2021 vs. 2020?
 
With unique_2020 AS (
SELECT count(distinct product_code) as unique_product_2020
FROM fact_sales_monthly WHERE fiscal_year=2020),
unique_2021 as (SELECT count(distinct product_code) as unique_product_2021
From fact_sales_monthly Where fiscal_year=2021)
select unique_2020.*, unique_2021.*,
round(((unique_2021.unique_product_2021 - unique_2020.unique_product_2020)
   /unique_2020.unique_product_2020)*100,2) as percentage_chg
   from unique_2020, unique_2021;
   
   -- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts

SELECT segment,
count(distinct(product_code)) as product_count
FROM gdb023.dim_product
group by segment
Order by product_count DESC;

  --  Which segment had the most increase in unique products in 2021 vs 2020?
  
  WITH P2020 AS
(SELECT P.segment,M.fiscal_year,Count(distinct P.product_code) AS
Product_count_2020 from
dim_product P 
JOIN fact_sales_monthly M 
ON P.product_code = M.product_code
WHERE fiscal_year =2020
Group by segment, M.fiscal_year),

P2021 AS
(SELECT P.segment,M.fiscal_year,Count(distinct P.product_code) AS
Product_count_2021 from
dim_product P 
JOIN fact_sales_monthly M 
ON P.product_code = M.product_code
WHERE fiscal_year =2021
Group by segment, M.fiscal_year)

SELECT P2020.segment,
P2020.product_count_2020,P2021.product_count_2021,
P2021.product_count_2021-P2020.product_count_2020 as Difference  
from P2020
JOIN P2021
ON P2020.segment =P2021.segment
ORDER BY Difference DESC;

  -- Get the products that have the highest and lowest manufacturing costs.
  
SELECT P.product_code,P.product,fmc.cost_year,fmc.manufacturing_cost
FROM fact_manufacturing_cost fmc
JOIN dim_product P 
ON fmc.product_code = P.product_code
WHERE fmc.manufacturing_cost 
IN 
(SELECT Max(manufacturing_cost) from fact_manufacturing_cost
union
SELECT Min(manufacturing_cost) from fact_manufacturing_cost)
ORDER BY fmc.manufacturing_cost desc ;

  -- Generate a report which contains the top 5 customers who received anaverage high pre_invoice_discount_pct for the fiscal year 2021 and in theI ndian market .
  
  SELECT C.customer_code,c.customer,Round(avg(PD.pre_invoice_discount_pct),4)as Avg_discount_pct 
  from dim_customer C
  JOIN fact_pre_invoice_deductions PD 
  ON c.customer_code = PD.customer_code
  WHERE C.market ="INDIA" AND PD.fiscal_year =2021
  GROUP BY C.customer,C.customer_code
  ORDER BY Avg_discount_pct desc limit 5;
  
    -- Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions . 
    
SELECT Concat(monthname(fm.date),'(', Year(fm.date),')') as Month_Date,fm.fiscal_year AS Fiscal_Year, 
concat(round(sum(fg.gross_price*fm.Sold_quantity)/1000000,2),'M') as Gross_Sales_Amount_mln 
from fact_gross_price fg Join fact_sales_monthly fm on  
fm.product_code = fg.product_code 
Join dim_customer C on fm.customer_code = C.customer_code 
Where C.customer = 'Atliq Exclusive' 
Group by Month_Date,Fiscal_Year 
Order by Fiscal_Year;

  -- In which quarter of 2020, got the maximum total_sold_quantity?
  
SELECT CASE
When Month(date) IN (9,10,11) Then 'Q1'
When Month(date) IN (12,01,02) Then 'Q2'
When Month(date) IN (3,4,5) Then 'Q3'
When Month(date) IN (6,7,8) Then 'Q4'
ELSE 'Q5'
End as Quarter,
sum(Sold_quantity) as Total_quantity_sold
From gdb023.fact_sales_monthly 
Where fiscal_year= '2020'
Group by Quarter
Order by Total_quantity_sold desc;


  -- Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
  
With Gross_sale AS (
SELECT C.channel,round(sum(fm.sold_quantity*fg.gross_price)/1000000,2)as
gross_sales_amount_mln
From fact_sales_monthly fm
Join fact_gross_price fg on
fg.product_code = fm.product_code
Join dim_customer C on
C.customer_code = fm.customer_code
Where fm.fiscal_year =2021
Group by C.channel
Order by Gross_sales_amount_mln Desc)
SELECT *,
round(gross_sales_amount_mln*100/sum(gross_sales_amount_mln) over(),2) as percentage
from Gross_sale
Order by percentage desc;

  -- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
 
With division_quantity as (
SELECT p.division,p.product_code,p.product,
sum(fm.sold_quantity) as Total_quantity
from dim_product p 
Join fact_sales_monthly fm on
p.product_code = fm.product_code
Where fm.fiscal_year= 2021
Group by p.product_code,p.product,p.division),
Ranked_products as
(SELECT *,dense_rank()over(partition by division Order by Total_quantity desc) as
Rnk from division_quantity)

SELECT *
FROM Ranked_products
Where Rnk <=3;









