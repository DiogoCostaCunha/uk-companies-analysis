-- after importing csv...

-- 55 columns in total
SELECT COUNT(column_name)
FROM information_schema.columns
WHERE table_name = 'company_data_sample';

--- Rename selected columns to facilitate understanding/manipulation
ALTER TABLE company_data_sample RENAME COLUMN companyname TO company_name;
ALTER TABLE company_data_sample RENAME COLUMN " CompanyNumber" TO company_number;
ALTER TABLE company_data_sample RENAME COLUMN "RegAddress.County"  TO county;
ALTER TABLE company_data_sample RENAME COLUMN "RegAddress.Country"  TO country;
ALTER TABLE company_data_sample RENAME COLUMN countryoforigin  TO origin_country;
ALTER TABLE company_data_sample RENAME COLUMN incorporationdate  TO incorporation_date;

ALTER TABLE company_data_sample RENAME COLUMN companycategory  TO legal_category;
ALTER TABLE company_data_sample RENAME COLUMN "SICCode.SicText_1"  TO SIC_1;
ALTER TABLE company_data_sample RENAME COLUMN "SICCode.SicText_2"  TO SIC_2;
ALTER TABLE company_data_sample RENAME COLUMN "SICCode.SicText_3"  TO SIC_3;
ALTER TABLE company_data_sample RENAME COLUMN "SICCode.SicText_4"  TO SIC_4;

ALTER TABLE company_data_sample RENAME COLUMN companystatus  TO legal_status; 
ALTER TABLE company_data_sample RENAME COLUMN "Mortgages.NumMortCharges"  TO total_mortgages;
ALTER TABLE company_data_sample RENAME COLUMN "Mortgages.NumMortOutstanding"  TO num_full_mortgages;
ALTER TABLE company_data_sample RENAME COLUMN "Mortgages.NumMortPartSatisfied"  TO num_partial_mortgages;
ALTER TABLE company_data_sample RENAME COLUMN "Mortgages.NumMortSatisfied" TO num_finished_mortgages;

CREATE TABLE company_data_sample_new AS
SELECT 
    company_name, 
    company_number, 
    county, 
    country, 
    origin_country, 
    incorporation_date, 
    legal_category, 
    SIC_1, 
    SIC_2, 
    SIC_3, 
    SIC_4, 
    legal_status, 
    total_mortgages, 
    num_full_mortgages, 
    num_partial_mortgages, 
    num_finished_mortgages
FROM company_data_sample;

DROP TABLE company_data_sample;

ALTER TABLE company_data_sample_new RENAME TO company_data_sample;

ALTER TABLE company_data_sample ALTER COLUMN incorporation_date TYPE DATE USING to_date(incorporation_date, 'DD-MM-YYYY');

-- Can use company number as primary key as it uniquely identifies each company on the dataset
select distinct(count(cds.company_number)) from company_data_sample cds;
ALTER TABLE company_data_sample ADD CONSTRAINT pk_company_number PRIMARY KEY (company_number);

-- Let's peak at data quality
SELECT 
    SUM(CASE WHEN company_name IS NULL OR company_name = '' THEN 1 ELSE 0 END) AS company_name_null_or_empty,
    SUM(CASE WHEN company_number IS NULL OR company_number = '' THEN 1 ELSE 0 END) AS company_number_null_or_empty,
    SUM(CASE WHEN county IS NULL OR county = '' THEN 1 ELSE 0 END) AS county_null_or_empty,
    SUM(CASE WHEN country IS NULL OR country = '' THEN 1 ELSE 0 END) AS country_null_or_empty,
    SUM(CASE WHEN origin_country IS NULL OR origin_country = '' THEN 1 ELSE 0 END) AS origin_country_null_or_empty,
    SUM(CASE WHEN incorporation_date IS NULL THEN 1 ELSE 0 END) AS incorporation_date_null_or_empty,
    SUM(CASE WHEN legal_category IS NULL OR legal_category = '' THEN 1 ELSE 0 END) AS legal_category_null_or_empty,
    SUM(CASE WHEN SIC_1 IS NULL OR SIC_1 = '' THEN 1 ELSE 0 END) AS SIC_1_null_or_empty,
    SUM(CASE WHEN SIC_2 IS NULL OR SIC_2 = '' THEN 1 ELSE 0 END) AS SIC_2_null_or_empty,
    SUM(CASE WHEN SIC_3 IS NULL OR SIC_3 = '' THEN 1 ELSE 0 END) AS SIC_3_null_or_empty,
    SUM(CASE WHEN SIC_4 IS NULL OR SIC_4 = '' THEN 1 ELSE 0 END) AS SIC_4_null_or_empty,
    SUM(CASE WHEN legal_status IS NULL OR legal_status = '' THEN 1 ELSE 0 END) AS legal_status_null_or_empty,
    SUM(CASE WHEN total_mortgages IS NULL THEN 1 ELSE 0 END) AS total_mortgages_null_or_empty,
    SUM(CASE WHEN num_full_mortgages IS NULL THEN 1 ELSE 0 END) AS num_full_mortgages_null_or_empty,
    SUM(CASE WHEN num_partial_mortgages IS null THEN 1 ELSE 0 END) AS num_partial_mortgages_null_or_empty,
    SUM(CASE WHEN num_finished_mortgages IS NULL THEN 1 ELSE 0 END) AS num_finished_mortgages_null_or_empty
FROM company_data_sample;

---- BASIC QUESTIONS

---- What are the oldest and most recent dates of incorporation for companies?
---- We have companies from 1856!
select 
	min(cds.incorporation_date), 
	max(cds.incorporation_date) 
from company_data_sample cds;

----
select
	company_name,
	sic_1
from company_data_sample cds
where extract(year from cds.incorporation_date) = '1856'

---- What is the trend for new companies appearing in the UK?

-- Obs: more and more companies appear over the years as expected...
SELECT 
    CASE
        WHEN EXTRACT(YEAR FROM incorporation_date) <= 1990 THEN 'Before 1980'
        ELSE TO_CHAR(EXTRACT(YEAR FROM incorporation_date), '9999')
    END AS year_group,
    COUNT(*) AS occurrences
FROM 
    company_data_sample cds
GROUP BY 
    year_group
ORDER BY 
    year_group ASC;
   
-- Obs: investigate possible seasonality for companies appearing
SELECT 
    EXTRACT(YEAR FROM incorporation_date) AS year,
    EXTRACT(MONTH FROM incorporation_date) AS month,
    COUNT(*) AS occurrences
FROM 
    company_data_sample cds
GROUP BY 
    year, month
ORDER BY 
    year DESC, month desc
    
--++ Let's explore the companies geographically
    
-- county
SELECT COUNT(*) as "num_county" FROM (SELECT DISTINCT cds.county FROM company_data_sample cds) AS temp;

select county, count(county)
from company_data_sample cds
group by county
order by count(county) desc;

-- country
SELECT COUNT(*) as "num_country" FROM (SELECT DISTINCT cds.country FROM company_data_sample cds) AS temp;

select country, count(country)
from company_data_sample cds
group by country
order by count(country) desc;

-- country of origin
SELECT COUNT(*) as "num_country_origin" FROM (SELECT DISTINCT cds.origin_country FROM company_data_sample cds) AS temp;

select origin_country, count(origin_country)
from company_data_sample cds
group by origin_country
order by count(origin_country) desc;


--++ let's explore company types
SELECT COUNT(*) as "num_legal_categories" FROM (SELECT DISTINCT cds.legal_category FROM company_data_sample cds) AS temp;

select legal_category, count(legal_category)
from company_data_sample cds
group by legal_category
order by count(legal_category) desc;

--++ sic reflects industry

-- What are the most common activities?
SELECT "SIC", COUNT(*)
FROM (
  SELECT cds.sic_1 AS "SIC" FROM company_data_sample cds
  UNION ALL
  SELECT cds.sic_2 AS "SIC" FROM company_data_sample cds
  UNION ALL
  SELECT cds.sic_3 AS "SIC" FROM company_data_sample cds
  UNION ALL
  SELECT cds.sic_4 AS "SIC" FROM company_data_sample cds
) AS combined_fields
where "SIC" <> ''
GROUP BY "SIC"
order by COUNT desc;

-- What is the distribution of companies in regards to having 1, 2, 3 or 4 activities specified?
SELECT
  COUNT(*) FILTER (WHERE cds.sic_2 = '') AS "1_sic",
  COUNT(*) FILTER (WHERE cds.sic_2 <> '') AS "2_sic",
  COUNT(*) FILTER (WHERE cds.sic_3 <> '') AS "3_sic",
  COUNT(*) FILTER (WHERE cds.sic_4 <> '') AS "4_sic"
FROM company_data_sample cds;

-- How is the distribution of general and limited partners among companies?

-- won't trust these data too much because it is too strange that it is 0
select num_general_partners, count(num_general_partners)
from company_data_sample cds
group by num_general_partners
order by count(num_general_partners) desc;

-- won't trust these data too much because it is too strange that it is 0
select num_limited_partners, count(num_limited_partners)
from company_data_sample cds
group by num_limited_partners
order by count(num_limited_partners) desc;

-- Let's explore company status / performance
SELECT COUNT(*) as "num_legal_status" FROM (SELECT DISTINCT cds.legal_status FROM company_data_sample cds) AS temp;

-- focus on the 3 most common types of legal status (~80%?)
select legal_status, count(legal_status)
from company_data_sample cds
group by legal_status
order by count(legal_status) desc;

-- company categories regarding financial status
SELECT COUNT(*) as "num_account_category" FROM (SELECT DISTINCT cds.account_category FROM company_data_sample cds) AS temp;

select account_category, count(account_category)
from company_data_sample cds
group by account_category
order by count(account_category) desc;

-- what about mortgages as a measure of financial success?
select
	count(case when total_mortgages >= 1 then 1 end) as "have_taken_mortgages",
	count(case when total_mortgages = 0 then 1 end) as "avoided_mortgages",
	count(case when total_mortgages = num_finished_mortgages and total_mortgages <> 0 then 1 end) as "paid_mortgages",
	count(case when total_mortgages > num_finished_mortgages and total_mortgages <> 0 then 1 end) as "still_paying_mortgages"
from company_data_sample cds;


---- GOING DEEPER:

-- deep-dive on mortgages for different sectors of activity
create view unified_sics as
with initial_filter as (
	select cds.company_number, cds.total_mortgages, cds.sic_1, cds.sic_2, cds.sic_3, cds.sic_4, cds.incorporation_date
	from company_data_sample cds
	where cds.incorporation_date >= '01-01-1980' -- check where we start getting more data
)
select cds.company_number, cds.total_mortgages, cds.sic_1 as "sic", cds.incorporation_date from initial_filter cds where cds.sic_1 <> ''
union all
select cds.company_number, cds.total_mortgages, cds.sic_2 as "sic", cds.incorporation_date from initial_filter cds where cds.sic_2 <> ''
union all
select cds.company_number, cds.total_mortgages, cds.sic_3 as "sic", cds.incorporation_date from initial_filter cds where cds.sic_3 <> ''
union all
select cds.company_number, cds.total_mortgages, cds.sic_4 as "sic", cds.incorporation_date from initial_filter cds where cds.sic_4 <> ''

with sic_counts as (
	SELECT sic, COUNT(DISTINCT company_number) AS company_count
	FROM unified_sics
	GROUP BY sic
),
sic_mortgages as (
	select sic, sum(total_mortgages) as total_mortgages
	from unified_sics
	group by sic
),
sic_companies_with_mortgages  as (
	SELECT sic, COUNT(DISTINCT company_number) AS companies_with_mortgages
	FROM unified_sics
	WHERE total_mortgages > 0
	GROUP BY sic
)
SELECT st.sic, st.total_mortgages, sc.company_count, 
       round((st.total_mortgages::float / sc.company_count)::numeric,2) AS avg_mortgages,
       round(((COALESCE(cm.companies_with_mortgages, 0)::float / sc.company_count) * 100)::numeric,2) AS percent_companies_with_mortgages
FROM sic_mortgages st
left JOIN sic_counts sc ON st.sic = sc.sic
left join sic_companies_with_mortgages cm on st.sic = cm.sic
where sc.company_count > 20
ORDER BY avg_mortgages desc, percent_companies_with_mortgages DESC;
-- TODO: explore sectors where mortgages are more extremed and sectors which are not that much

-- deep-dive on growth of sectors in terms of companies appearing
create view growth_sics_year as
SELECT
    EXTRACT(year FROM incorporation_date) AS "year",
    sic,
    COUNT(DISTINCT company_number) as "num_companies"
FROM unified_sics
GROUP BY sic, "year"

SELECT
    gs."year",
    gs.sic,
    gs.num_companies
FROM
    growth_sics_year gs
right JOIN (
    SELECT
        "year",
        MAX(num_companies) AS max_num_companies
    from growth_sics_year
    GROUP by "year"
) max_gs ON gs."year" = max_gs."year" AND gs.num_companies = max_gs.max_num_companies
order by year desc, num_companies desc;

-- Explore seasonality on existence of companies across the year by month from 2015 to 2023
create view growth_sics_month_2015_2023 as
select
	EXTRACT(month FROM incorporation_date) AS "month",
    EXTRACT(year FROM incorporation_date) AS "year",
    sic,
    COUNT(DISTINCT company_number) as "num_companies"
FROM unified_sics
where EXTRACT(year FROM incorporation_date) >= 2015 and EXTRACT(year FROM incorporation_date) <= 2023
GROUP BY sic, "year", "month"

-- explore seasonality with a chart and possibly some test here
select
	"year",
	"month",
	sum(num_companies) as "new_companies"
from growth_sics_month_2015_2023 
group by year, month
order by year asc, month asc;




