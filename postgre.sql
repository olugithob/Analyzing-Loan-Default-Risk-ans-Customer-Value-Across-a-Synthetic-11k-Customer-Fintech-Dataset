SELECT 
    c.customer_id,
    l.loan_id
FROM customers c
LEFT JOIN loans l
    ON c.customer_id = l.customer_id;

SELECT 
	c.customer_id,
	ticket_id
FROM customers c
LEFT JOIN support_tickets t
	ON c.customer_id = t.ticket_id;

SELECT c.customer_id,
		t.transaction_id
FROM customers c
LEFT JOIN transactions t
ON c.customer_id = t.transaction_id


SELECT
		SUM(l.principal_amount)
FROM customers c
LEFT JOIN loans l
ON c.customer_id = l.customer_id
WHERE l.loan_id is NOT NULL
------------------------------------------------
---What actually predicts a loan default here?
SELECT 
    COUNT(c.customer_id) AS customers,
    COUNT(CASE WHEN c.has_defaulted_loan THEN c.customer_id END) AS has_defaulted_loan,
    COUNT(CASE WHEN l.status = 'Default' THEN l.customer_id END) AS default
FROM loans l
JOIN customers c
    ON c.customer_id = l.customer_id;
--customers that have defaulted = 552 | Total defaults: 451
---80% of customers with a history of defaulting, are currently defaulters. Flag this as a default predictor.
--
SELECT *
FROM loans l
	WHERE status is NOT NULL
--Total loan offered/sent out: 5007
---------------
SELECT 
		c.customer_id,
		l.loan_id,
		c.has_defaulted_loan,
		c.income_band,
		l.status,
		l.days_past_due
FROM customers c
LEFT JOIN loans l
ON c.customer_id = l.customer_id
WHERE has_defaulted_loan = 'true' AND days_past_due > 90
---------------
----------------------------------
SELECT 
		c.customer_id,
		l.loan_id,
		c.has_defaulted_loan,
		c.income_band,
		l.status,
		l.days_past_due
FROM customers c
LEFT JOIN loans l
ON c.customer_id = l.customer_id
WHERE income_band = '<25k' OR income_band = '25k-50k'
GROUP BY c.customer_id,
		l.loan_id,
		c.has_defaulted_loan,
		c.income_band,
		l.status,
		l.days_past_due
HAVING status = 'Default'

-------Out of the 451 customers defaulting, a large number(305) come from the low income earners(<25k, <50k). 
----This predicts defaults and it is important that the company addresses this moving forward.
----------------------OR---------------------

SELECT 
    SUM(CASE WHEN c.income_band IN ('<25k', '25k-50k') THEN 1 ELSE 0 END) AS income_or_less,
    COUNT(*) AS total_defaults,
    ROUND(
        SUM(CASE WHEN c.income_band IN ('<25k', '25k-50k') THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 
        2
    ) AS pct_50k_or_less
FROM customers c
JOIN loans l 
    ON c.customer_id = l.customer_id
WHERE l.status = 'Default';
--over 67% of these defaulting customers have an income band of <= 50k: small income earners are likely to defalut
--


--





						-------EXPLORATORY ANALYSIS--------
						-----------------------------------
----percentage that has defaulted_loan in the past amongst loan records
SELECT 
    c.has_defaulted_loan,
    COUNT(l.loan_id) AS count,
    ROUND(COUNT(l.loan_id) * 100.0 / SUM(COUNT(l.loan_id)) OVER (), 2) AS percentage
FROM customers c
LEFT JOIN loans l
    ON l.customer_id = c.customer_id
GROUP BY c.has_defaulted_loan;

-------11% of the total customers on a loan has defaulted in the past
-----------------------

----percentage distribution of churned customers
SELECT 	
	COUNT(customer_id) as customers,
   COUNT(CASE WHEN churned THEN customer_id END) AS churned,
   COUNT(CASE WHEN churned THEN customer_id END) * 100/COUNT(customer_id) as pct_churned
FROM customers
WHERE support_ticket_count > 1 
----612/8928 that used the support ticket, churned.
----444/612 that churned used the support services 2 or more times.
----216/612 used the support services atleast thrice. 
--This indicates that customers who filed more tickets  are likely to churn due to various complaints or categories.



---Percentage distribution of customers according to their loan status.
SELECT
	status,
	COUNT(status),
	 ROUND(COUNT(loan_id) * 100.0 / SUM(COUNT(loan_id)) OVER (), 2) AS percentage
FROM loans l
JOIN customers c
ON l.customer_id = c.customer_id
WHERE churned = TRUE
GROUP BY status

----------
-------complaint category with the highest churn rate
SELECT 
    s.category,
    COUNT(CASE WHEN churned THEN c.customer_id END) AS churned,
    ROUND(
        COUNT(CASE WHEN churned THEN c.customer_id END) * 100.0 / SUM(COUNT(CASE WHEN churned THEN c.customer_id END)) OVER (), 
        2
    ) AS percentage
FROM customers c
JOIN support_tickets s
    ON c.customer_id = s.customer_id
WHERE c.churned = TRUE
GROUP BY s.category
ORDER BY churned DESC;
-------customers who use the support services complaining about Billing, login access have the highest combine churn rate of 33.46%
-------

---Are churn_rate and default_rate correlated, or are they different problems?
SELECT 
    EXTRACT(YEAR FROM c.signup_date) AS year,
    COUNT(DISTINCT c.customer_id) AS Default_rate,
    COUNT(DISTINCT CASE WHEN c.churned THEN c.customer_id END) AS churned_rate
FROM customers c
JOIN loans l
    ON l.customer_id = c.customer_id
WHERE l.status = 'Default' 
    
GROUP BY 
    EXTRACT(YEAR FROM c.signup_date) 
ORDER BY 
   EXTRACT(YEAR FROM c.signup_date) 
---------The correlation between the two is strong by 61.7%. A strong indication that there are chances that customers who defaults are likely to churn.
----------------------------------------------

------Add a year column
ALTER TABLE loans ADD COLUMN total_interest_revenue NUMERIC(15, 2);

UPDATE loans
SET total_interest_revenue = ROUND(principal_amount * (interest_rate_pct / 100) * (term_months / 12.0), 2);
-------
----

--------------------------------------------------------------------------------------------------
--Which customer segments (income band, credit score tier, product mix, tenure) are driving risk vs. driving value?

-------what category of employment status among customers is driving value and minimizing risk?
SELECT 
		c.employment_status,
		COUNT(c.customer_id) as customers,
		SUM(l.total_interest_revenue) as interest_revenue,
		ROUND(AVG(CASE WHEN l.status = 'Default' THEN 1.0 ELSE 0 END), 2) * 100 AS default_rate_pct,
    ROUND(AVG(CASE WHEN c.churned THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
	FROM customers c
	JOIN loans l
	ON c.customer_id = l.customer_id
	GROUP BY 
		c.employment_status
	ORDER BY 2 desc	
----risk of default is spread equally across all employment categories(average of 9%). however, full time employees that borrow loan drive the highest value. a large number of them borrow loans(3109), and they produce the most interest revenue (13,938,262)
--------

-----What category of customer's monthly income is driving value and minimizing risk?
SELECT 
		c.income_band,
		SUM(l.total_interest_revenue) as interest_revenue,
		ROUND(AVG(CASE WHEN l.status = 'Default' THEN 1.0 ELSE 0 END), 2) * 100 AS default_rate_pct,
    ROUND(AVG(CASE WHEN c.churned THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
	FROM customers c
	JOIN loans l
	ON c.customer_id = l.customer_id
	GROUP BY 
		c.income_band
	ORDER BY 2 desc	
-----low income earners of <50k have the greatest risk with a combined default rate of 41%. average income earners between 75k-100k  drive value and minimize risk(at 3% risk of default)
-----high income earners(100k-150k) pose little or no risk of default. 
---

---What loan type category is driving value?
SELECT 
		l.loan_type,
		SUM(l.total_interest_revenue) as interest_revenue,
		ROUND(AVG(CASE WHEN l.status = 'Default' THEN 1.0 ELSE 0 END), 2) * 100 AS default_rate_pct,
    ROUND(AVG(CASE WHEN c.churned THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
	FROM customers c
	JOIN loans l
	ON c.customer_id = l.customer_id
	GROUP BY 
		l.loan_type
	ORDER BY 2 desc	
--------Personal loans are the ones with the greatest value with a total interest revenue of 12,412,447.90 so far
-----------

---Which credit tier category is costing the company?
SELECT
    CASE
        WHEN c.credit_score < 500 THEN '<50'
        WHEN c.credit_score <= 600 THEN '50-60'
        WHEN c.credit_score <= 700 THEN '61-70'
        WHEN c.credit_score <= 800 THEN '71-80'
        ELSE '81+'
    END AS credit_tier,
	SUM(l.total_interest_revenue) as interest_revenue,
		ROUND(AVG(CASE WHEN l.status = 'Default' THEN 1.0 ELSE 0 END), 2) * 100 AS default_rate_pct,
    ROUND(AVG(CASE WHEN c.churned THEN 1.0 ELSE 0 END) * 100, 2) AS churn_rate_pct
	FROM customers c
	JOIN loans l
	ON c.customer_id = l.customer_id
	GROUP BY 1
	ORDER BY 3 asc
----customers with a less than average(<50) credit score and average credit score(50-60) are costing the company a great deal. They have a ridiculously high default rate - 61% and 23% respectively.
---

---Does the company run a risk of default increase as the loan term increases?
SELECT l.term_months,
		ROUND(AVG(CASE WHEN l.status = 'Default' THEN 1.0 ELSE 0 END), 2) * 100 AS default_rate_pct
	FROM customers c
	JOIN loans l
	ON c.customer_id = l.customer_id
	GROUP BY 1
	ORDER BY 1 asc
---No, there is no sign of the default rate increasing as the loan term extends further
------------

----Total interest revenue so far 
		SELECT ROUND(SUM(total_interest_revenue), 2) AS total_interest_revenue
FROM loans;
------"total_interest_revenue"
		22,499,613.26
---

-----Total amount loaned out
SELECT SUM(principal_amount) as total_loan_amount
FROM loans 
----------"total_loan_amount"
			73,599,194.68
---

-----churned customers
SELECT  COUNT(DISTINCT customer_id) as status_count, 
		churned
FROM customers
WHERE churned = TRUE
GROUP BY churned
