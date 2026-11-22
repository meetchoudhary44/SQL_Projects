---- Creating the customer table schema for importing the raw dataset ----

CREATE TABLE customers (
    customer_id varchar(20),
    age INTEGER,
    gender VARCHAR(20),
    marital_status VARCHAR(30),
    education_level VARCHAR(50),
    employment_status VARCHAR(50),
    income NUMERIC,
    city VARCHAR(100),
    credit_score INTEGER,
    account_age_months INTEGER,
    card_type VARCHAR(50),
    credit_limit NUMERIC,
    annual_fees NUMERIC,
    interest_rate NUMERIC,
    num_products INTEGER,
    has_loan INTEGER,
    has_savings_account INTEGER,
    monthly_spendings NUMERIC,
    average_transaction_amount NUMERIC,
    monthly_transactions INTEGER,
    online_transactions INTEGER,
    international_transactions INTEGER,
    cash_withdrawals INTEGER,
    utilization_ratio NUMERIC,
    payment_delay_count INTEGER,
    late_payment_amount NUMERIC,
    app_login_monthly INTEGER,
    website_visit_monthly INTEGER,
    customer_service_calls INTEGER,
    complaint_count INTEGER,
    support_satisfaction NUMERIC,
    reward_points INTEGER,
    offer_received INTEGER,
    offer_redeemed INTEGER,
    financial_stress_score NUMERIC,
    engagement_score NUMERIC,
    customer_value_score NUMERIC,
    churn_risk_score NUMERIC,
    churn_probability NUMERIC,
    is_churned INTEGER
);

---- Sanity check: verify the number of records and preview the imported data ----

Select count(*) from customers; 
Select * from customers 
limit 5;




---- Purpose: Establish the overall customer base and portfolio churn baseline for Meridian Bank ----

Select count(distinct(customer_id)) from customers; 

Select count(distinct(customer_id)) from customers   
where is_churned = 1;

Select round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as customer_churn_percentage
from customers  
where is_churned = 1;

---- Finding: 100,000 total customers, of which 19,458 are churned, resulting in an overall churn rate of 19.46%. ----

----**** Churn bucketing logic: High churn >= 1.5x baseline (29.19%); Low churn <= 0.6x baseline (11.68%). ****----




---- purpose: compare churn rates across card types against the 19.46% portfolio baseline. ----

Select
	card_type, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from customers  
group by card_type
order by customer_churn_percentage desc;


-- Finding: 
-- 1. Churn rates are broadly consistent across card types(18.92%–19.64%) and remain close to the 19.46% portfolio baseline,
-- suggesting card type is not a strong differentiator of customer churn.

-- Business implication:
-- 1. Standard card customers represent ~45% of the customer base,
-- so even with a baseline-level churn rate, this segment represents a large share of the overall churn population.




---- Purpose: compare customer churn rates across employment status segments to identify whether employment status is a meaningful churn differentiator. ----

Select
	employment_status, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from customers  
group by employment_status
order by customer_churn_percentage desc;

-- Finding: 
-- 1. Students have the highest churn rate at 20.27%, followed by unemployed customers at 19.65%.
-- 2. However, the difference across employment groups is relatively small, with all segments remaining close to the 19.46% baseline.
-- 3. Therefore, employment status does not appear to be a strong churn differentiator.
-- 4. Employed customers represent the largest share of the customer base at 62.08%, followed by self-employed customers at 15.04%.
-- 5. Students account for only 5.00% of the total customer base.

-- Business Implication:
-- 1. Although students have the highest churn rate, their small 5.00% share of the customer base limits their overall contribution to portfolio churn.
-- 2. Employed customers should receive greater attention from a volume perspective, as they represent 62.08% of the customer base despite having a near-baseline churn rate of 19.49%.




---- Purpose: analyze customer churn across account tenure segments to determine whether account age is a meaningful churn differentiator. ----

-- Tenure groups:
-- New: 0-60 months
-- Early Tenure: 61-120 months
-- Established: 121-180 months
-- Long Tenure: 181-240 months
-- Very Long Tenure: 241-400 months
-- Extremely Long Tenure: 401+ months

With Tenure_bucket as (
	select 
		customer_id, 
		account_age_months, 
		is_churned,
		case
			when account_age_months <= 60 then 'New'
			when account_age_months <= 120 then 'Early Tenure'
			when account_age_months <= 180 then 'Established'
			when account_age_months <= 240 then 'Long Tenure'
			when account_age_months <= 400 then 'Very Long Tenure'
			else 'Extremely Long Tenure'
		End  as Tunure_groups

	from customers
)

Select
	Tunure_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
	
from Tenure_bucket  
group by Tunure_groups
order by Customer_Distribution_percentage desc;

-- Findings:
-- 1. New customers represent 76.18% of the total customer base and have a churn rate of 19.81%, slightly above the overall churn baseline of 19.46%.
-- 2. Early Tenure customers represent 18.04% of the customer base and have a churn rate of 18.52%, below the overall baseline.
-- 3. Established, Long Tenure, and Very Long Tenure groups also have churn rates below the overall baseline.
-- 4. Extremely Long Tenure has the highest churn rate at 33.33%, but represents only 0.01% of the customer base, making the segment too small for a meaningful conclusion.
-- 5. Overall, tenure does not appear to be a strong differentiator of churn, with most groups showing churn rates relatively close to the 19.46% baseline.

-- Business Implications:
-- 1. New customers should receive attention because they represent the largest share of the customer base, even though their churn rate is only slightly above the baseline.
-- 2. Tenure alone does not identify a high-risk customer segment, so retention strategies should not be based on tenure alone.




---- Purpose: What is the churn rate by payment delay group? ----

-- Payment Delay groups:
-- No Delays: O Delays
-- Low Delays: 1-3 Delays
-- Moderate Delays: 4-6 Delays
-- High Delays: 6+ Delays

With Delay_payment_bucket as (
	select 
		customer_id, 
		payment_delay_count, 
		is_churned,
		case
			when payment_delay_count = 0 then 'No Delays'
			when payment_delay_count <= 3 then 'Low Delays'
			when payment_delay_count <= 6 then 'Moderate Delays'
			else 'High Delays'
		End  as Delay_payment_groups

	from customers
)

Select
	Delay_payment_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Delay_payment_bucket  
group by Delay_payment_groups
order by customer_churn_percentage desc;

-- Findings: Churn rises sharply with payment delays, from 12.46% for customers with no delays to 100% for high-delay customers, making payment delays a strong churn driver.

-- Business Implication: Prioritize payment delays for churn segmentation and retention, especially customers showing repeated or moderate-to-high payment delays.




---- Purpose: Compare churn rates across age groups against the 19.46% portfolio baseline to determine whether age is a meaningful differentiator of customer churn. ----

-- Age groups:
-- Young Adults: 1-25 Years
-- Early Adults: 26-35 Years
-- Mid Adults: 36-45 Years
-- Mature Adults: 45-55 Years
-- Older Adults: 55+ Years

With Customer_Age_bucket as (
	select 
		customer_id, 
		age, 
		is_churned,
		case
			when age <=25  then 'Young Adults'
			when age <= 35 then 'Early Adults'
			when age <= 45 then 'Mid Adults'
			when age <= 55 then 'Mature Adults'
			else 'Older Adults'
		End  as Customer_Age_groups
	from customers
)

Select
	Customer_Age_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Age_bucket  
group by Customer_Age_groups
order by customer_churn_percentage desc;

-- Findings:
-- 1. Churn rates are very consistent across age groups, ranging from 19.27% to 19.75%, with all groups remaining very close to the 19.46% portfolio baseline.
-- 2. Older Adults have the highest churn rate at 19.75%, only 0.29 percentage points above the portfolio baseline.
-- 3. Early Adults have the lowest churn rate at 19.27%, only 0.19 percentage point below the portfolio baseline.
-- 4. The difference between the highest and lowest age-group churn rates is only 0.48 percentage points, indicating very weak age-based differentiation.
-- 5. Churn share is broadly proportional to customer distribution across all age groups, further indicating that no age group contributes disproportionately to total churn.

-- Business Implications:
-- 1. Age does not appear to be a strong standalone driver of customer churn, as churn rates remain closely aligned with the 19.46% portfolio baseline.
-- 2. Older Adults show slightly higher churn, but the difference is too small to justify age-based retention strategies on its own.
-- 3. Age should not be prioritized as a primary churn segmentation variable, but can be retained as a supporting variable in multi-attribute analysis.




---- Purpose: Compare churn rates across income groups against the 19.46% portfolio baseline. ----

-- Income groups:
-- Low Income: <=50000
-- Lower-Middle Income: 50001-100000
-- Moderate Income: 100001-150000
-- High Income: 150001-250000
-- Very High Income: 250000+

With Customer_Income_bucket as (
	select 
		customer_id, 
		income, 
		is_churned,
		case
			when income <= 50000  then 'Low Income'
			when income <= 100000 then 'Lower-Middle Income'
			when income <= 150000 then 'Moderate Income'
			when income <= 250000 then 'High Income'
			else 'Very High Income'
		End  as Customer_Income_groups
	from customers
)
Select
	Customer_Income_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Income_bucket  
group by Customer_Income_groups
order by customer_churn_percentage desc;

-- Findings: Churn rates range from 18.89% to 19.58%, remaining close to the 19.46% baseline, so income is not a strong churn driver.

-- Business Implication: Don't prioritize income for segmentation on its own; keeping it as a supporting variable for combined analysis.



---- Purpose: Compare churn rates across credit limit groups against the 19.46% portfolio baseline. ----

-- Credit_Limit groups:
-- Very Low Credit_Limit: 1-10000
-- Low Credit_Limit: 10001-25000
-- Moderate Credit_Limit: 25001-50000
-- High Credit_Limit: 50000+

With Customer_Credit_Limit_bucket as (
	select 
		customer_id, 
		credit_limit, 
		is_churned,
		case
			when credit_limit <= 10000  then 'Very Low Credit_Limit'
			when credit_limit <= 25000 then 'Low Credit_Limit'
			when credit_limit <= 50000 then 'Moderate Credit_Limit'
			else 'High Credit_Limit'
		End  as Customer_Credit_Limit_groups
	from customers
)
Select
	Customer_Credit_Limit_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Credit_Limit_bucket  
group by Customer_Credit_Limit_groups
order by customer_churn_percentage desc;


-- Findings:
-- 1. Churn rates range from 19.18% to 20.32%, showing a modest difference across credit limit groups.
-- 2. High Credit Limit has the highest churn at 20.32%, while Low Credit Limit has the lowest at 19.18%.

-- Business Implication:
-- 1. Credit limit is a relatively weak churn differentiator and should not be prioritized on its own.
-- 2. Keeping it as a supporting variable for combined segment analysis.



---- Purpose: Compare churn rates across customer contact groups against the 19.46% portfolio baseline. ----

-- Contacts groups:
-- No Contact: 0 Contacts
-- Low Contact: 1-3 Contacts
-- Moderate Contact: 4-7 Contacts
-- High Contact: 8-12 Contacts
-- Very High Contact: 12+ Contacts

With Customer_Contacts_bucket as (
	select 
		customer_id, 
		customer_service_calls, 
		is_churned,
		case
			when customer_service_calls = 0  then 'No Contact'
			when customer_service_calls <= 3 then 'Low Contact'
			when customer_service_calls <= 7 then 'Moderate Contact'
			when customer_service_calls <= 12 then 'High Contact'
			else 'Very High Contact'
		End  as Customer_Contact_groups
	from customers
)
Select
	Customer_Contact_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Contacts_bucket  
group by Customer_Contact_groups
order by customer_churn_percentage desc;

-- Findings:
-- 1. Moderate Contact represents 11.38% of customers and has 33.47% churn, exceeding the 29.19% high-churn threshold (1.5× the 19.46% baseline).
-- 2. High and Very High Contact show much higher churn, but they are excluded because their segment sizes are below the 5% minimum requirement

-- Business Implication:
-- 1. Customer contacts are a strong churn differentiator and should be prioritized in segmentation.
-- 2. Focus retention efforts on customers with repeated service contacts, while monitoring the very high contact group separately due to its small size.




---- Purpose: Compare churn rates across complaint groups against the 19.46% portfolio baseline. ----

-- Complaints groups:
-- No Complaints: 0 Complaints
-- Low Complaints: 1-3 Complaints
-- Moderate Complaints: 4-6 Complaints
-- High Complaints: 7-10 Complaints
-- Very High Complaints: 10+

With Customer_Complaints_bucket as (
	select 
		customer_id, 
		complaint_count, 
		is_churned,
		case
			when complaint_count = 0  then 'No Complaints'
			when complaint_count <= 3 then 'Low Complaints'
			when complaint_count <= 6 then 'Moderate Complaints'
			when complaint_count <= 10 then 'High Complaints'
			else 'Very High Complaints'
		End  as Customer_Complaints_groups
	from customers
)
Select
	Customer_Complaints_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_complaints_bucket  
group by Customer_Complaints_groups
order by customer_churn_percentage desc;



-- Findings:
-- 1. Low Complaints has 26.94% churn, but it does not meet the 29.19% high-churn threshold.
-- 2. Moderate, High, and Very High Complaints show higher churn, but each represents <5% of customers and is excluded from the analysis.

-- Business Implication:
-- 1. Complaints show a potential relationship with churn, but no valid segment meets the project's high-churn criteria.
-- 2. Keep complaints as a supporting variable for combined segment analysis.




---- Purpose: Compare churn rates across monthly app login groups against the 19.46% portfolio baseline. ----

-- App Usage groups:
-- Low App Usage: 1-3 Monthly login  
-- Moderate App Usage: 4-7 Monthly login 
-- High App Usage: 8-15 Monthly login 
-- Very High App Usage: 15+ Monthly login 

With Customer_Monthly_login_bucket as (
	select 
		customer_id, 
		app_login_monthly, 
		is_churned,
		case
			when app_login_monthly <= 3 then 'Low App Usage'
			when app_login_monthly <= 7 then 'Moderate App Usage'
			when app_login_monthly <= 15 then 'High App Usage'
			else 'Very High App Usage'
		End  as Customer_Monthly_login_groups
	from customers
)
Select
	Customer_Monthly_login_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Monthly_login_bucket  
group by Customer_Monthly_login_groups
order by customer_churn_percentage desc;


-- Findings:
-- 1. No valid segment meets the high- or low-churn thresholds while also satisfying the 5% minimum segment size requirement.
-- 2. Low App Usage has 29.71% churn but represents only 0.24% of customers, so it is excluded from the analysis.
 
-- Business Implication:
-- 1. App login frequency does not provide a valid high- or low-churn segment under the project criteria.
-- 2. App usage can be retained as a supporting variable for combined analysis.




---- Purpose: Compare churn rates across engagement score groups against the 19.46% portfolio baseline. ----

-- Engagement groups:
-- Low Engagement: 1-30
-- Moderate Engagement: 31-50
-- High Engagement: 51-70
-- Very High Engagement: 70+

With Customer_engagement_score_bucket as (
	select 
		customer_id, 
		engagement_score, 
		is_churned,
		case
			when engagement_score <= 30 then 'Low Engagement'
			when engagement_score <= 50 then 'Moderate Engagement'
			when engagement_score <= 70 then 'High Engagement'
			else 'Very High Engagement'
		End  as Customer_engagement_score_groups
	from customers
)
Select
	Customer_engagement_score_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_engagement_score_bucket  
group by Customer_engagement_score_groups
order by customer_churn_percentage desc;


-- Findings:
-- 1. Moderate Engagement represents 16.35% of customers and has 32.48% churn, exceeding the 29.19% high-churn threshold.
-- 2. Very High Engagement represents 36.97% of customers and has 11.08% churn, below the 11.68% low-churn threshold.

-- Business Implication:
-- 1. Moderate-engagement customers should be prioritized for proactive retention efforts.
-- 2. Very high engagement is associated with lower churn and can be used as a positive customer-retention indicator.




---- Purpose: Compare churn rates across reward points groups against the 19.46% portfolio baseline. ----

-- reward groups:
-- Low reward: 1-5000 Points
-- Moderate reward: 5001-15000 Points
-- High reward: 15001-30000 Points
-- Very High reward: 30001-50000 Points
-- Extremely High Rewards: 50000+ Points

With Customer_Reward_Points_bucket as (
	select 
		customer_id, 
		reward_points, 
		is_churned,
		case
			when reward_points <= 5000 then 'Low reward'
			when reward_points <= 15000 then 'Moderate reward'
			when reward_points <= 30000 then 'High reward'
			when reward_points <= 50000 then 'Very High Rewards'
			else 'Extremely High Rewards'
		End  as Customer_Reward_Points_groups
	from customers
)
Select
	Customer_Reward_Points_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Reward_Points_bucket  
group by Customer_Reward_Points_groups
order by customer_churn_percentage desc;

-- Findings:
-- 1. None of the segments meeting the 5% minimum customer-size requirement falls into the high- or low-churn category.
-- 2. Extremely High Rewards has 29.29% churn, but represents only 0.28% of customers, so it is excluded despite exceeding the high-churn threshold.

-- Business Implications:
-- 1. Reward points do not provide a valid standalone high- or low-churn segment under the project criteria.
-- 2. Reward points can be retained as a supporting variable for combined analys is.




---- Purpose: Assess whether Financial Stress Score is associated with customer churn. ----

-- financial Stress groups:
-- No/Negligible stress: 0-1
-- Low stress: 1-20   
-- Moderate stress: 20-40   
-- High stress: 40-60  
-- Very stress: 60-80 
-- Extremely High stress: 80+

With financial_Stress_Score_bucket as (
	select 
		customer_id, 
		financial_stress_score, 
		is_churned,
		case
			when financial_stress_score <= 1 then 'No/Negligible stress'
			when financial_stress_score <= 20 then 'Low stress'
			when financial_stress_score <= 40 then 'Moderate stress'
			when financial_stress_score <= 60 then 'High stress'
			when financial_stress_score <= 80 then 'Very High stress'
			else 'Extremely High stress'
		End  as financial_stress_score_groups
	from customers
)
Select
	financial_stress_score_groups, round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from financial_Stress_Score_bucket  
group by financial_stress_score_groups
order by customer_churn_percentage desc;

-- Findings:
-- 1. High Stress customers have a 36.72% churn rate and represent 14.96% of the customer base,
--    making them a valid high-churn segment.
-- 2. Low Stress customers have an 8.95% churn rate and represent 30.96% of the customer base,
--    making them a valid low-churn segment.
-- 3. Moderate Stress customers have a 17.13% churn rate and represent 49.39% of the customer base,
--    serving as the baseline segment.
-- 4. Churn increases substantially with financial stress, indicating a strong positive relationship
--    between financial stress and customer churn.

-- Business Implications:
-- 1. Financial stress can be used as an important churn-risk indicator.
-- 2. Customers experiencing High Stress should be prioritized for targeted retention interventions.
-- 3. Reducing financial pressure may help improve customer retention, particularly among high-stress customers.





--**** Level 1 single-attribute analysis is complete. ****--

----******** Level 2 analysis now combines meaningful attributes to identify actionable customer segments and deeper churn patterns. ********----



---- Level 2 Analysis 1: Payment Delay Count × Support Satisfaction ----

With Support_satisfaction_and_Payment_delay_bucket as (
	select 
		customer_id,
		payment_delay_count,
		support_satisfaction, 
		is_churned,
		customer_service_calls,
		complaint_count,
			case
				when payment_delay_count = 0 then 'No Delays'
				when payment_delay_count <= 3 then 'Low Delays'
				when payment_delay_count <= 6 then 'Moderate Delays'
				else 'High Delays'
			End  as Delay_payment_groups,
			case 
				when Support_satisfaction <= 2.5 then 'Low Satisfaction'
				when Support_satisfaction <= 4 then 'Moderate Satisfaction'
				else 'High Satisfaction'
			End as Support_satisfaction_groups

	from customers
)

Select
	Delay_payment_groups,
	Support_satisfaction_groups, 
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	coalesce(round((Sum(complaint_count)*100.0/nullif((Sum(customer_service_calls)),0)),2),0) as Complaint_rate_percentage,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Support_satisfaction_and_Payment_delay_bucket  
group by Delay_payment_groups, Support_satisfaction_groups 
having count(*) >= 5000
order by Delay_payment_groups,Support_satisfaction_groups;

-- Findings:
-- 1. Low Delays with Low Satisfaction has the highest valid churn at 56.02%,
--    representing 6.25% of customers and exceeding the 29.19% high-churn threshold.
-- 2. Among customers with No Delays, churn rises from 6.96% with High Satisfaction
--    to 31.23% with Low Satisfaction, a 4.5× increase, showing a strong association
--    between lower support satisfaction and higher churn.

-- Business Implications:
-- 1. Prioritize customers with low support satisfaction for retention, especially when they also experience payment delays.
-- 2. Improving support satisfaction may be particularly important even for customers without payment delays, given the large difference in observed churn.




---- Level 2 Analysis 2: Engagement Score × App Login Frequency ----

With Customer_engagement_score_and_App_Login_bucket as (
	select 
		customer_id, 
		engagement_score,
		app_login_monthly,
		is_churned,
		case
			when engagement_score <= 30 then 'Low Engagement'
			when engagement_score <= 50 then 'Moderate Engagement'
			when engagement_score <= 70 then 'High Engagement'
			else 'Very High Engagement'
		End  as Customer_engagement_score_groups,
		case
			when app_login_monthly <= 3 then 'Low App Usage'
			when app_login_monthly <= 7 then 'Moderate App Usage'
			when app_login_monthly <= 15 then 'High App Usage'
			else 'Very High App Usage'
		End  as Customer_Monthly_login_groups
	from customers
)
Select
	Customer_engagement_score_groups,
	Customer_Monthly_login_groups,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_engagement_score_and_App_Login_bucket  
group by Customer_engagement_score_groups,Customer_Monthly_login_groups
having count(*) >= 5000
order by customer_churn_percentage desc;

-- Findings:
-- 1. Moderate Engagement with High App Usage has 32.50% churn and represents
--    12.07% of customers, exceeding the 29.19% high-churn threshold.
-- 2. Very High Engagement customers have low churn even with High App Usage
--    (11.11%) or Very High App Usage (10.95%), indicating that high app usage
--    alone does not necessarily translate into lower churn.

-- Business Implications:
-- 1. Investigate customers with High App Usage but only Moderate Engagement,
--    focusing on whether the overall app experience is sufficiently engaging
--    and whether potential UI/UX friction may be contributing to churn.
-- 2. Focus retention efforts on improving customer engagement quality rather
--    than increasing app usage alone, as highly engaged customers show lower churn.

-- Note: UI/UX issues are a possible explanation for the observed pattern but
-- are not directly measured in this analysis.

-- Verdict: Customer engagement appears to be more important than app usage frequency alone in reducing churn.




---- Level 2 Analysis 3: Financial Stress Score × Income ----

With Customer_Income_and_Stress_bucket as (
	select 
		customer_id, 
		income,
		financial_stress_score,
		is_churned,
		case
			when income <= 50000  then 'Low Income'
			when income <= 100000 then 'Lower-Middle Income'
			when income <= 150000 then 'Moderate Income'
			when income <= 250000 then 'High Income'
			else 'Very High Income'
		End  as Customer_Income_groups,
		case
			when financial_stress_score < 1 then 'No/Negligible stress'
			when financial_stress_score <= 20 then 'Low stress'
			when financial_stress_score <= 40 then 'Moderate stress'
			when financial_stress_score <= 60 then 'High stress'
			when financial_stress_score <= 80 then 'Very High stress'
			else 'Extremely High stress'
		End  as financial_stress_score_groups
	from customers
)
Select
	Customer_Income_groups,
	financial_stress_score_groups,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage
from Customer_Income_and_Stress_bucket  
group by Customer_Income_groups,financial_stress_score_groups
having count(*) >= 5000
order by customer_churn_percentage desc;

-- Findings:
-- 1. Lower-Middle Income customers with High Financial Stress have the highest
--    meaningful churn rate at 36.53%, across 6.53% of the customer base,
--    making this a valid high-churn segment.
-- 2. Moderate Financial Stress remains around the portfolio baseline across
--    the meaningful income segments, with churn rates of 16.73%–17.91%.
-- 3. Low Financial Stress is associated with lower churn across meaningful
--    income segments, ranging from 8.32% to 9.21%, all below the low-churn threshold of 11.68%.

-- Business Implications:
-- 1. Financial stress becomes a stronger churn risk when concentrated among Lower-Middle Income customers.
-- 2. Retention efforts should prioritize Lower-Middle Income customers experiencing High Financial Stress.
-- 3. Lower Financial Stress customers show relatively stable and low churn,
--    suggesting that financial stress can be used as a useful segmentation variable for churn-risk prioritization.





-- High Churn vs Low Churn Customer Profile Comparison
--
-- Objective:
-- Compare the key characteristics of the highest-churn and lowest-churn
-- customer segments identified through Level 2 analysis.
--
-- High-Churn Profile:
-- Low Payment Delays + Low Support Satisfaction
-- Churn Rate: 56.02%
--
-- Low-Churn Profile:
-- No Payment Delays + High Support Satisfaction
-- Churn Rate: 6.96%
--
-- Comparison Attributes:
-- Age
-- Account Tenure
-- Income
-- Credit Score
-- Credit Limit
-- Utilization Ratio
-- Monthly Spending
-- Average Transaction Amount
-- Monthly Transactions
-- Online Transactions
-- International Transactions
-- Cash Withdrawals
-- Payment Delay Count
-- Late Payment Amount
-- App Login Monthly
-- Website Visit Monthly
-- Customer Service Calls
-- Complaint Count
-- Financial Stress Score
-- Engagement Score
-- Customer Value Score
-- Reward Points

With Churn_Profile_Compare as (
	select *,
			case
				when payment_delay_count = 0 then 'No Delays'
				when payment_delay_count <= 3 then 'Low Delays'
				when payment_delay_count <= 6 then 'Moderate Delays'
				else 'High Delays'
			End  as Delay_payment_groups,
			case 
				when Support_satisfaction <= 2.5 then 'Low Satisfaction'
				when Support_satisfaction <= 4 then 'Moderate Satisfaction'
				else 'High Satisfaction'
			End as Support_satisfaction_groups

	from customers
)

Select
	Delay_payment_groups,
	Support_satisfaction_groups, 
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(count(distinct(customer_id))),2) as customer_churn_percentage,
	round((count(distinct(case when is_churned = 1 then customer_id end ))*100.0)/(Select count(distinct(case when is_churned = 1 then customer_id end)) from customers),2)as Churn_Share,
	round((count(distinct(customer_id))*100.0)/(Select count(distinct(customer_id)) from customers),2) as Customer_Distribution_percentage,
	round(Avg(age),2) as Avg_Age ,
	round(Avg(account_age_months),2) as Avg_Account_Tenure,
	round(Avg(income),2) as Avg_Income,
	round(Avg(credit_score),2) as Avg_Credit_score,
	round(Avg(credit_limit),2) as Avg_Credit_limit,
	round(Avg(utilization_ratio),2) as Avg_utilization_ratio, 
	round(Avg(monthly_spendings),2) as Avg_monthly_spending,
	round(Avg(average_transaction_amount),2) as Avg_transaction_amount,
	round(Avg(monthly_transactions),2) as Avg_monthly_transactions,
	round(Avg(online_transactions),2) as Avg_Online_transactions,
	round(Avg(international_transactions),2) as Avg_international_transactions,
	round(Avg(cash_withdrawals),2) as Avg_cash_withdrawals,
	round(Avg(app_login_monthly),2) as Avg_app_login_monthly,
	round(Avg(Website_visit_monthly),2) as Avg_Website_visit,
	round(Avg(customer_service_calls),2) as Avg_Contacts,
	round(Avg(complaint_count),2) as Avg_complaint_registered,
	round(Avg(financial_stress_score),2) as Avg_financial_stress,
	round(Avg(engagement_score),2) as Avg_engagement,
	round(Avg(customer_value_score),2) as Avg_Customer_value_Score,
	round(Avg(reward_points),2) as Avg_reward_points
from Churn_Profile_Compare  
Where (Delay_payment_groups = 'Low Delays' and Support_satisfaction_groups = 'Low Satisfaction') or (Delay_payment_groups = 'No Delays' and Support_satisfaction_groups = 'High Satisfaction')
group by Delay_payment_groups, Support_satisfaction_groups 
order by customer_churn_percentage

-- Findings:
-- 1. The Low Delays + Low Satisfaction segment has a significantly higher churn rate
--    of 56.02%, compared with only 6.96% for the No Delays + High Satisfaction segment.
--
-- 2. Customer service interaction is a major differentiator. High-churn customers
--    have an average of 3.35 customer contacts, compared with only 0.68 for
--    low-churn customers.
--
-- 3. Complaint levels are substantially higher among high-churn customers, with
--    an average of 1.79 complaints compared with only 0.08 for low-churn customers.
--
-- 4. Financial stress is substantially higher among high-churn customers, with
--    an average financial stress score of 44.83 compared with 21.82 for low-churn
--    customers.
--
-- 5. Most other customer characteristics, including age, account tenure, income,
--    credit score, credit limit, utilization ratio, spending, transaction activity,
--    engagement score, and customer value score, show relatively small differences
--    between the two profiles.
--
-- Business Implications:
-- 1. Customer service experience appears to be a key differentiator between
--    high-churn and low-churn customers.
--
-- 2. Customers with frequent customer-service interactions and higher complaint
--    levels should be prioritized for proactive retention efforts.
--
-- 3. Higher financial stress is strongly associated with the high-churn profile,
--    suggesting that financially stressed customers may require targeted retention
--    support.
--
-- 4. Since most other customer attributes show limited differences, retention
--    efforts should focus more on customer experience, complaints, and financial
--    stress rather than broad demographic or spending characteristics.