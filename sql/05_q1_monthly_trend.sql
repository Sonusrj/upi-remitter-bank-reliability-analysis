-- QUESTION 1: Is overall technical reliability improving over time?
-- Output: one row per month with volume, estimated failures, the
-- weighted TD rate, and how much the rate moved vs the previous month.
USE upi_reliability;

-- Step A: collapse the bank rows into one row per month.
WITH monthly AS (
    SELECT month_date,
           SUM(volume_mn) AS volume_mn,                          -- total transactions
           SUM(volume_mn * td_pct / 100) AS est_failed_mn        -- estimated technical failures
    FROM fact_upi_remitter
    GROUP BY month_date
),
-- Step B: weighted TD rate = total failed / total volume.
-- (Not an average of bank rates, so big banks count more.)
rates AS (
    SELECT month_date, volume_mn, est_failed_mn,
           est_failed_mn / volume_mn * 100 AS td_rate
    FROM monthly
)
-- Step C: show the table and add the change vs last month.
SELECT month_date,
       ROUND(volume_mn, 0)     AS volume_mn,
       ROUND(est_failed_mn, 2) AS est_failed_mn,
       ROUND(td_rate, 3)       AS weighted_td_pct,
       -- LAG looks one row up (previous month). Rate minus previous rate = MoM change in pp.
       ROUND(td_rate - LAG(td_rate) OVER (ORDER BY month_date), 3) AS mom_change_pp
FROM rates
ORDER BY month_date;