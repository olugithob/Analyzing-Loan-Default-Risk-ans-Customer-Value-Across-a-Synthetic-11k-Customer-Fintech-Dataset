# Analyzing-Loan-Default-Risk-and-Customer-Value-Across-a-Synthetic-11k-Customer-Fintech-Dataset

## Table of Content

- [Problem Statement](#problem-statement)
- [Tool and Methodology](#tools-and-methodology)
- [Analysis Findings](#analysis-findings)
- [Key Insights](Key_Insights)
- [Recommendations](#Recommendations)

## Problem Statement:
Our loan default rate has gone up over the last two quarters, and at the same time we're bleeding customers — churn is up too, and I can't tell if these are the same customers or two separate fires. Support is getting flooded with tickets, marketing keeps running campaigns that don't seem to move the needle, and nobody can give me a straight answer on which customer segments are actually profitable versus which ones are quietly costing us money.

I need a business analyst to dig into our data — customers, their transaction behavior, loan performance, and support interactions — and help me figure out:

1. What actually predicts a loan default here?
2. Are churn and default correlated, or are they different problems?
3. Which customer segments (income band, credit score tier, product mix, tenure) are driving risk vs. driving value?
4. Is there a support/experience angle — are customers who file more tickets more likely to churn or default?

## Tools and Methodoology:

### Tools:

MS Excel: Used Ms excel to clean the data and for Dashboard creation.

PostGre SQL: To analyze the data, uncover insights and solve the problems


### Method:

Data Cleaning: The process of data cleaning carried out in this project includes:
- checking for missing values and duplicates
- standardizing specific data fields.

Data Processing and Analysis: Pg admin 4 was used to write queries and experiment on the data, extracting key details that were used to solve business impact questions relevant to the company's needs. Here's an excerpt:

```SQL
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
```

Data Visualization: Built a one page dashboard to properly communicate in clear terms, and provide clarity and straight answers to the various areas of concern.

## Analysis Findings:

### Client Reporting
![Client Report](https://github.com/olugithob/Analyzing-Loan-Default-Risk-and-Customer-Value-Across-a-Synthetic-11k-Customer-Fintech-Dataset/blob/main/Client%20dashboard.png)


### Key Insights:


- 80% of customers with a history of defaulting, are currently defaulters. Flag this as a default predictor.

- Out of the 451 customers defaulting, a large number(305) come from the low income earners(<25k, <50k). This predicts defaults and it is important that the company addresses this moving forward.

- Correlation might indeed be present in certain customer categories like the income band categories, which is worth paying attention to. data shows a 61.7% strong relationship among churn and default rate, and that is because it is not uniform across all customer categories. It may be non existent in certain categories

- 11% of the total customers on a loan has defaulted in the past.

- 612/8928 that used the support ticket, churned. 444/612 that churned used the support services 2 or more times. 216/612 used the support services atleast thrice. This indicates that customers who filed more tickets  are likely to churn due to various complaints or categories.

- customers who use the support services complaining about Billing, login access have the highest combine churn rate of 33.46%

- Risk of default is spread equally across all employment categories(average of 9%). however, full time employees that borrow loan drive the highest value. a large number of them borrow loans(3109), and they produce the most interest revenue (13,938,262)

- Low income earners of <50k have the greatest risk with a combined default rate of 41%. average income earners between 75k-100k  drive value and minimize risk(at 3% risk of default)
high income earners(100k-150k) pose little or no risk of default. 

- Personal loans are the ones with the greatest value with a total interest revenue of 12,412,447.90 so far

- Customers with a less than average(<50) credit score and average credit score(50-60) are costing the company a great deal. They have a ridiculously high default rate - 61% and 23% respectively.

- The company does not run a risk of default increase as the loan term increase, as there is no sign of the default rate increasing as the loan term extends further.


### Recommendations:

* Repeat defaulters are your clearest red flag. 80% of customers who've defaulted before are defaulting again — treat past default as an automatic trigger for manual review, not an automated approval.
  
* Stop lending as freely to the <50k income band. They're driving a 41% default rate. Either shrink loan sizes for this group, ask for more documentation, or price the risk into the rate.
  
* Double down on the 75k-100k income group. Only 3% default risk, and they're pulling their weight on value. This is your safest, most profitable segment — prioritize them in marketing and offers.

* Fast-track approvals for 100k-150k earners. Almost no default risk here — lighter, quicker underwriting makes sense and will improve their experience.

* Protect the Personal loan product. It's earned $12.4M in interest — by far your biggest revenue driver. Don't let broader risk tightening accidentally choke this off.

* Credit scores under 60 are losing you money. A 61% default rate for scores under 50, and 23% for scores 50-60, means most of these loans don't pay off. Stop approving standard loans for this group, or offer a smaller, safer product instead (like a secured or small-dollar loan).

* Watch for customers who hit more than one red flag. Someone with a past default, low income and a low credit score is your highest-risk customer — these three things compound.

### Code Exploration:
![code screen](https://github.com/olugithob/Analyzing-Loan-Default-Risk-ans-Customer-Value-Across-a-Synthetic-11k-Customer-Fintech-Dataset/blob/main/postgre.sql)
