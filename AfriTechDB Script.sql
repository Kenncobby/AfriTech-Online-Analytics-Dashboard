-- Create the Database
CREATE DATABASE Afritechdb;
                                            -- 1. Create the tables --
-- Create a staging data table 
CREATE TABLE StagingData (
    CustomerID INT,
    CustomerName TEXT,
    Region TEXT,
    Age INT,
    Income NUMERIC(10,2),
    CustomerType TEXT,
    TransactionYear INT,
    TransactionDate DATE,
    ProductPurchased TEXT, 
    PurchaseAmount NUMERIC(10,2),
    ProductRecalled BOOLEAN,
    Competitor TEXT,
    InteractionDate DATE,
    Platform TEXT,
    PostType TEXT,
    EngagementLikes INT, 
    EngagementShares INT,
    EngagementComments INT, 
    UserFollowers INT,
    InfluencerScore NUMERIC(10,2),
    BrandMention BOOLEAN,
    CompetitorMention BOOLEAN,
    Sentiment TEXT,
    CrisisEventTime DATE, 
    FirstResponseTime DATE,
    ResolutionStatus BOOLEAN, 
    NPSResponse INT
);

CREATE TABLE Customer_data (
Customer_id int PRIMARY KEY,
customer_name Varchar (225),
Region Varchar (225),
Income Numeric (10,2),
customer_type Varchar (50),
age int
);

CREATE TABLE Transactions (
Transaction_id SERIAL PRIMARY KEY,
customer_id int,
transaction_year Varchar (4),
transaction_date Date,
product_purchased Varchar (225),
purchased_amount numeric(10,2),
product_recalled boolean,
competitor Varchar (225),
FOREIGN KEY (customer_id) References Customer_data (customer_id)
);

CREATE TABLE social_media (
post_id Serial Primary key,
customer_id int,
interaction_date date,
platform Varchar(50),
post_type Varchar(50),
engagement_likes int,
engagement_shares int,
engagement_comments int,
user_followers int,
influence_score int,
brand_mention boolean,
competitor_mention boolean,
competitor Varchar(225),
sentiment text,
crisis_event_time date,
first_response_time date,
resolution_status boolean,
NPS_response int,
FOREIGN KEY (customer_id) REFERENCES customer_data (customer_id)
);

                                     -- 2. Begin insertion of Data --

-- 2.1 Insert Customer Data
INSERT INTO customer_data ( Customer_id, customer_name, Region, Income, customer_type, age)
Select distinct Customerid, customername, Region, Income, customertype, age
from stagingdata;

-- 2.2 Insert into Transaction data
INSERT INTO Transactions ( customer_id, transaction_year, transaction_date, product_purchased, purchased_amount, product_recalled, competitor)
Select CustomerID, TransactionYear, TransactionDate, ProductPurchased, PurchaseAmount, ProductRecalled, Competitor
from stagingdata
where TransactionDate is not null;

-- 2.3 Insert into Social Media
INSERT INTO social_media ( customer_id, interaction_date, platform, post_type, engagement_likes, engagement_shares, engagement_comments, user_followers, influence_score, brand_mention, competitor_mention, competitor, sentiment, crisis_event_time, first_response_time, resolution_status, NPS_response)
Select customerID, interactionDate, platform, postType, engagementLikes, engagementShares, engagementComments, userFollowers, influencerScore, brandMention,competitormention, competitor, sentiment, crisisEventTime, firstresponsetime, resolutionStatus, NPSResponse
From stagingdata
where interactiondate is not null;

-- 2.4 Dropping the stagingdata after insertions
Drop Table Stagingdata;

                             -- 3. Data validation for the columns, rows and tables in the database --
							  
-- 3.1 Number of rows in each table
Select count(*) from customer_data;

select count(*) from social_media;

select count(*) from Transactions;

-- 3.2 View first 5 rows of each table
Select * from customer_data
limit 5;

select * from social_media
limit 5;

select * from Transactions
limit 5;
                                                               
-- 3.3 Identifying missing values
select count(*)  
from customer_data 
where customer_id is null

select count(*)  
from social_media 
where nps_response is null;

select count(*)  
from transactions 
where competitor is null;


                                               -- 4. Exploratory Data Analysis --
-- 4.1 CUSTOMER EDA

-- 4.1.1 Customer Demographics (How many customers live in what region)
Select region, count(*) as Customer_Count
from customer_data
group by region
order by Customer_Count desc;

Select count(distinct customer_id) as Unique_Customers
from customer_data;

-- 4.1.2 counting the number of Null values in the 'customer_name' and 'region' columns 
Select 'customer_name' as ColumnName,	count(*) as NullCount
from customer_data
where customer_name is null
UNION
Select 'region' as ColumnName, count(*) as NullCount
from customer_data
where region is null;

-- 4.2 TRANSACTIONS EDA

-- 4.2.1 Basic Summary Statistics Transactions/Sales
Select
	To_char(avg(purchased_amount),'$999,999,999.99') as Avg_Purchase_Amt,
	To_char(min(purchased_amount),'$999,999,999.99') as Min_Purchase_Amt,
	To_char(max(purchased_amount),'$999,999,999.99') as Max_Purchase_Amt,
	To_char(sum(purchased_amount),'$999,999,999.99') as Total_Sales
From transactions;

-- 4.2.2 Summary of Product Sales for the total number of sales and total revenue for each product.
Select
	Product_purchased,
	To_char(count(*),'999,999,999') as Number_of_sales,
	To_char(Sum(purchased_amount),'$999,999,999.99') as Revenue
From transactions
Group by Product_purchased;

-- 4.2.3 Total number of recalled products and the potential lost revenue
Select
	Product_recalled,
	To_char(count(*),'999,999,999') as No_of_recalled_pdt,
	To_char(Sum(purchased_amount),'$999,999,999.99') as Potential_Lost_Revenue
From transactions
where Product_recalled = 'TRUE'
Group by Product_recalled;

-- 4.3 SOCIAL MEDIA EDA

-- 4.3.1 Social media likes
Select
	platform,
	To_char(avg(engagement_likes),'999,999,999.99')  as Average_likes,
	To_char(sum(engagement_likes),'999,999,999') as Total_likes
From social_media
Group by platform;

-- 4.3.2 Social media sentiment
Select
	platform,
	sentiment,
	To_char(count(*),'999,999,999') as Sentiment_count
From social_media
where sentiment is not null
Group by platform, sentiment
order by platform;

-- 4.3.3 General percentage Sentiment score
Select
	sentiment,
	round(count(*)*100.0/(select count(*) from social_media),2)|| '%' as Sentiment_percent
from social_media
group by sentiment;

-- 4.3.4 Percentage sentiment score breakdown per platform.
SELECT
    platform,
	sentiment,
    TO_CHAR(COUNT(*), '999,999,999') AS sentiment_count,
    TO_CHAR(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY platform),'990.00') || '%' AS sentiment_percentage
FROM social_media
WHERE sentiment IS NOT NULL
GROUP BY platform, sentiment
ORDER BY platform;

-- 4.3.5 social media brand and competitor mentions by platform
select
	platform,
	sum(case when brand_mention = 'True' then 1 else 0 end) as Brand_mentions,
	sum(case when competitor_mention = 'True' then 1 else 0 end) as competitor_mentions
from social_media
group by platform

-- 4.3.6 Total social media brand and competitor mentions
select
	sum(case when brand_mention = 'True' then 1 else 0 end) as Brand_mentions,
	sum(case when competitor_mention = 'True' then 1 else 0 end) as competitor_mentions
from social_media;

-- 4.3.7 Engagement rate
Select
	avg((engagement_likes + engagement_shares + engagement_comments)/
	nullif (user_followers,0)) as Engagement_Rate
from social_media;

-- 4.3.8 influence score per platform
select
	platform,
	round(avg(influence_score),2) as influence_score
from social_media
group by platform;

-- 4.3.9 Total Influence score
select
	round(avg(influence_score),2) as influence_score
from social_media;

--Monthly(time) Mentions Trend Analysis by platform
Select
	platform,
	to_char(date_trunc('month', interaction_date),'YYYY-MM') as month,
	count(*) as Mentions
from social_media
where Brand_mention = 'True'
Group by platform,month
order by month asc, mentions;

-- Average Crisis response time in days
Select -- we divide with 86400 beacuse that's how many seconds that make a day.
	avg(date_part('epoch', (cast(first_response_time AS timestamp) 
	- cast(crisis_event_time as timestamp))))/86400 as Avg_crisis_response_time_in_days 
From Social_media
where crisis_event_time is not null and first_response_time is not null;

-- Percentage_Crisis Resolution rate
Select
	to_char(count(*) * 100.0/(Select count(*) from social_media where crisis_event_time is not null),
	'990.00') || '%' as Percentage_crisis_resolution_rate
from Social_media
where resolution_status = True;

-- Top ten Influencers
Select
	Customer_id,
	to_char(avg(Influence_score),'990.00') || '%' as Influence_score
From Social_media
Group by customer_id
order by influence_score desc
Limit 10;

-- Overall average content effectiveness
Select
	post_type,
	TO_CHAR(AVG(engagement_likes + engagement_shares + engagement_comments), '999,999.99') AS average_engagement
FROM social_media
GROUP BY post_type
;

-- Average Content Effectiveness (Engagement) by platform
SELECT
	Platform,
    post_type,
    TO_CHAR(AVG(engagement_likes + engagement_shares + engagement_comments), '999,999.99') AS average_engagement,
    RANK() OVER (PARTITION BY platform ORDER BY AVG(engagement_likes + engagement_shares + engagement_comments) DESC) AS rank
FROM social_media
GROUP BY platform, post_type
ORDER BY platform, rank;

-- Total Revenue by Platform
Select
	sm.platform,
	to_char(sum(t.purchased_amount), '$999,999,999,999.99') as Platform_total_revenue
from social_media as sm
left join transactions as t
	on sm.customer_id=t.customer_id
where t.purchased_amount is not null
Group by sm.Platform
order by Platform_total_revenue desc
;

-- Top buying customers and their region
Select
	c.customer_id,
	c.customer_name,
	c.region,
	to_char(coalesce(sum(t.Purchased_amount),0), '$999,999,999.99') as total_purchase_amount
from transactions as t
left Join customer_data as c
	on t.customer_id=c.customer_id
group by c.region, c.customer_id
order by total_purchase_amount desc
limit 10;

-- -- Average social media Engagement by product
SELECT
	t.product_Purchased,
	TO_CHAR(avg(s.engagement_likes), '999,999.99') as avg_likes,
	TO_CHAR(avg(s.engagement_shares), '999,999.99') as avg_shares,
	TO_CHAR(avg(s.engagement_comments), '999,999.99') as avg_comments,
    TO_CHAR(AVG(s.engagement_likes + s.engagement_shares + s.engagement_comments), '999,999.99') AS average_engagement
FROM transactions as t
Left join social_media as s
	on t.customer_id=s.customer_id
GROUP BY t.product_Purchased
ORDER BY average_engagement desc;

-- Products with negative customer buzz and product recals
with Negative_buzz_and_recall as (
	Select
		t.product_purchased,
		count(distinct case when s.sentiment = 'Negative' then s.customer_id end) as Negative_buzz_count,
		count(distinct case when t.product_recalled ='True' then s.customer_id end) as Recall_count
	from Transactions as t
	Left Join social_media as s
		on t.customer_id=s.customer_id
	Group by t.product_purchased
)
Select *
from Negative_buzz_and_recall 
;

-- Creating a view for brand mentions
CREATE OR REPLACE VIEW BrandMentions as
Select
	interaction_date,
	count (*) as Brand_Mentions
From Social_media
WHERE Brand_Mention
Group by interaction_date
Order by interaction_date;

Select * from BrandMentions;

-- Stored procedure for crisis response time

CREATE OR REPLACE FUNCTION Calc_avg_crisis_response_time()
RETURNS TABLE(platform varchar(50), avg_crisis_response_time_in_days NUMERIC) 
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        s.platform,
        AVG(extract(EPOCH FROM(CAST(s.first_response_time AS TIMESTAMP) - CAST(s.crisis_event_time AS TIMESTAMP)))) / 86400 
        AS avg_crisis_response_time_in_days
    FROM social_media as s
    WHERE crisis_event_time IS NOT NULL 
    AND first_response_time IS NOT NULL
    GROUP BY s.platform;
END;
$$ LANGUAGE plpgsql;


Select * from Calc_avg_crisis_response_time();
