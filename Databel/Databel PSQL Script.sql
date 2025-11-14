-- Data Import
COPY fact_databel FROM 'C:\Users\Adity\Desktop\Aditya\DataCamp Power BI\Churn Rate\Datasets\Databel - Data.csv' DELIMITER ',' CSV HEADER;

-- Data Cleaning/Modeling
UPDATE fact_databel
SET "Intl Plan" = INITCAP("Intl Plan");

ALTER TABLE fact_databel
ALTER COLUMN "Total Charges" TYPE smallint
USING "Total Charges"::smallint;
ALTER TABLE fact_databel
ALTER COLUMN "Monthly Charge" TYPE smallint
USING "Monthly Charge"::smallint;


SELECT *
FROM fact_databel
WHERE "Intl Calls" <> FLOOR("Intl Calls");
SELECT *
FROM fact_databel
WHERE "Extra International Charges" <> FLOOR("Extra International Charges");

UPDATE fact_databel
SET "Intl Calls" = FLOOR("Intl Calls");
UPDATE fact_databel
SET "Extra International Charges" = FLOOR("Extra International Charges");

SELECT * FROM fact_databel;

-- Begining
-- Page : Overview
-- Churn Rate, Total Customers, Churn customers
WITH churn AS (
SELECT
	COUNT(*) AS churn_customers
FROM fact_databel
WHERE "Churn Label" = 'Yes'
),
total_customers AS(
SELECT COUNT(*) AS total_customers
FROM fact_databel
)
SELECT
	ROUND((churn_customers :: NUMERIC /total_customers :: NUMERIC) *100, 2) AS churn_rate
FROM churn, total_customers
-- SELECT * FROM total_customers
-- SELECT * FROM churn
;

-- Total Customer Churn % by Churn Category
SELECT
	"Churn Category",
	ROUND((c_count/ total_count) * 100, 2) AS percentage
FROM (
SELECT
	"Churn Category",
	COUNT(*) AS c_count,
	SUM(COUNT(*)) OVER() AS total_count
FROM fact_databel
WHERE "Churn Label" = 'Yes'
GROUP BY "Churn Category") AS subquery
ORDER BY percentage DESC;
-- Number of Customers by Contract Types
SELECT 
	"Contract Type",
	c_customers,
	ROUND((c_customers/total_customers) * 100, 2) AS percentage
FROM(
SELECT
	"Contract Type",
	COUNT(*) AS c_customers,
	SUM(COUNT(*)) OVER() AS total_customers 
FROM fact_databel
GROUP BY 1
ORDER BY 2 DESC) AS subquery;
-- Top 10 Churn Reasons by Share of Total Churn
SELECT
	"Churn Reason",
	c_count,
	ROUND((c_count :: NUMERIC/ total_count :: NUMERIC) * 100, 2) AS percentage
FROM
(
	SELECT *,
		SUM(c_count) OVER() AS total_count
	FROM
	(
		SELECT
			"Churn Reason",
			COUNT(*) AS c_count
		FROM fact_databel
		WHERE "Churn Reason" IS NOT NULL
		GROUP BY "Churn Reason"
		ORDER BY c_count DESC
		LIMIT 10) AS subquery1
	)AS subquery2
ORDER BY percentage DESC;
-- Churn Rate by State

WITH with_churn AS(
SELECT
	"State",
	count(*) AS w_churn
FROM fact_databel
WHERE "Churn Label" = 'Yes'
GROUP BY 1),
without_churn AS (
SELECT
	"State",
	count(*) AS wo_churn
FROM fact_databel
GROUP BY 1)
SELECT 
	w."State",
	w_churn AS churn_customers,
	wo_churn AS total_customers,
	ROUND(w_churn :: NUMERIC /wo_churn :: NUMERIC * 100, 2) AS churn_rate
FROM with_churn w
LEFT JOIN without_churn wo
	ON w."State" = wo."State"
ORDER BY churn_rate DESC;

-- Page:: Churn Demographics
-- Share of Total Churn Customers by Reason
SELECT
	"Churn Reason",
	c_count,
	ROUND((c_count :: NUMERIC/ total_count :: NUMERIC) * 100, 2) AS percentage
FROM
(
	SELECT *,
		SUM(c_count) OVER() AS total_count
	FROM
	(
		SELECT
			"Churn Reason",
			COUNT(*) AS c_count
		FROM fact_databel
		WHERE "Churn Label" = 'Yes'
		GROUP BY "Churn Reason"
		ORDER BY c_count DESC) AS subquery1
	)AS subquery2
ORDER BY percentage DESC;

-- Number of Customer & Churn Rate by Age(Bins)

SELECT
    CASE 
        WHEN "Age" >= 100 THEN '100+'
        ELSE CONCAT(FLOOR("Age" / 5) * 5, '–', FLOOR("Age" / 5) * 5 + 4)
    END AS age_group,
    COUNT(*) AS total_customers,
    ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY age_group
ORDER BY MIN("Age");
-- Age Group & Churn Rate
SELECT
	CASE 
		WHEN "Senior" = 'Yes' THEN 'Senior'
		WHEN "Under 30" = 'Yes' THEN 'Under 30'
		ELSE 'Between 30-60'
	END AS category,
	COUNT(*),
	    ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1;

-- Page: Groups and Categories
-- Yearly/Monthly Contract Type Churn Rate
SELECT 
	CASE 
		WHEN "Contract Type" = 'One Year' THEN 'Yearly'
		WHEN "Contract Type" = 'Two Year' THEN 'Yearly'
		ELSE 'Monthly'
	END AS contract_group,
	"Gender",
	ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1,2
ORDER BY 1,2
;
-- Customer by Contract Type
SELECT
	"Contract Type",
	ROUND(COUNT(*) :: NUMERIC / SUM(COUNT(*)) OVER() ::NUMERIC * 100, 2) AS customer_distribution
FROM fact_databel
GROUP BY 1;
-- Avg Monthly Charge and Churn Rate by Number of Customers in Group
SELECT
	"Number of Customers in a Group",
	ROUND(AVG("Monthly Charge"), 2),
	ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1
ORDER BY 1;

-- Page: Unlimited Plan
-- Churn Rate by Grouped Consumption by Data Plan
SELECT
	CASE 
		WHEN "Contract Type" = 'One Year' THEN 'Yearly'
		WHEN "Contract Type" = 'Two Year' THEN 'Yearly'
		ELSE 'Monthly'
	END AS contract_group,	
	CASE 
		WHEN "Avg Monthly Gb Download" < 5 THEN 'Less than 5Gb'
		WHEN "Avg Monthly Gb Download" > 10 THEN 'Greater than 10Gb'
		ELSE 'Between 5 and 10 Gb'
	END AS grouped_consumption,
	"Unlimited Data Plan",
	ROUND(100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END)/ COUNT(*),2) AS churn_rate
FROM fact_databel
GROUP BY 1,2,3
ORDER BY 1, 2, 3;
-- Churn Rate, Number of Customers in Unlimited Data Plan
SELECT
	CASE 
		WHEN "Contract Type" = 'One Year' THEN 'Yearly'
		WHEN "Contract Type" = 'Two Year' THEN 'Yearly'
		ELSE 'Monthly'
	END AS contract_group,
	"Unlimited Data Plan",
	COUNT(*),
	ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1, 2
ORDER BY 1,2;

-- Page: International Calls
SELECT
	"Intl Plan",
	"Intl Active",
		ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1,2
ORDER BY 1,2;

-- Page: Contract Type
-- Churn Rate by Account Length and Contract Type
SELECT
	"Account Length (in months)",
	"Contract Type",
		ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1,2
ORDER BY 1,2;
-- No.of Customers and Churn Rate by Payment Method
SELECT
	"Payment Method",
	COUNT(*) AS total_customers,
		ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1
ORDER BY 3 DESC;

-- Page: Age Groups

-- Page: Payment and Contracts
SELECT
	CASE
		WHEN "Contract Type" = 'One Year' THEN 'Yearly'
		WHEN "Contract Type" = 'Two Year' THEN 'Yearly'
		ELSE 'Monthly'
	END AS contract_group,
	"Payment Method",
	ROUND(AVG("Customer Service Calls"), 2) AS avg_customer_service_calls,
	SUM("Customer Service Calls") AS total_cs_calls
FROM fact_databel
GROUP BY 1,2
ORDER BY 1, 2;

-- Extra Charges
-- Avg Extra Data Charges and Avg Extra International Charges
SELECT
	CASE 
		WHEN "Avg Monthly Gb Download" < 5 THEN 'Less than 5Gb'
		WHEN "Avg Monthly Gb Download" > 10 THEN 'Greater than 10Gb'
		ELSE 'Between 5 and 10 Gb'
	END AS grouped_consumption,
	"Unlimited Data Plan",
	ROUND(AVG("Extra Data Charges"), 2) AS avg_extra_data_charges,
	ROUND(AVG("Extra International Charges"), 2) AS avg_extra_international_charges,
	ROUND(
        100.0 * SUM(CASE WHEN "Churn Label" = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM fact_databel
GROUP BY 1, 2
ORDER BY 1, 2;

-- Page: Insights
-- Avg Service Calls by State and Churn Label
SELECT
	"State",
	"Churn Label",
	ROUND(AVG("Customer Service Calls"), 2) AS avg_service_calls
FROM fact_databel
GROUP BY 1, 2
ORDER BY 1, 2;
-- Churn Rate by State and Total Service Calls
SELECT
	"State",
	count(*) AS w_churn,
	SUM("Customer Service Calls")
FROM fact_databel
WHERE "Churn Label" = 'Yes'
GROUP BY 1
ORDER BY 3 DESC;