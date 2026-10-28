-- QUESTION 3b: Is concentration changing over time?
-- CR5 = share of that month's failures coming from the 5 banks with the most failures.
USE upi_reliability;

-- Step A: rank banks WITHIN each month (PARTITION BY month = restart ranking every month).
WITH r AS (
    SELECT f.month_date, d.bank_name,
           f.volume_mn * f.td_pct / 100 AS failed,
           RANK() OVER (PARTITION BY f.month_date ORDER BY f.volume_mn * f.td_pct DESC) AS rnk
    FROM fact_upi_remitter f JOIN dim_bank d USING (bank_id)
    WHERE d.is_ranked = 1
)
-- Step B: top-5 failures / all failures, per month.
SELECT month_date,
       ROUND(SUM(CASE WHEN rnk <= 5 THEN failed END) / SUM(failed) * 100, 1) AS cr5_pct
FROM r GROUP BY month_date ORDER BY month_date;