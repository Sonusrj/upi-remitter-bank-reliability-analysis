-- QUESTION 3a: How concentrated are technical failures?
-- Do a few banks account for most of them (Pareto)?
USE upi_reliability;

-- Step A: total estimated failures per ranked bank, over all 24 months.
WITH b AS (
    SELECT d.bank_name,
           SUM(f.volume_mn * f.td_pct / 100) AS failed
    FROM fact_upi_remitter f JOIN dim_bank d USING (bank_id)
    WHERE d.is_ranked = 1
    GROUP BY d.bank_name
),
-- Step B: rank banks, then compute each bank's share and the running total.
r AS (
    SELECT bank_name, failed,
           RANK() OVER (ORDER BY failed DESC) AS rnk,                    -- 1 = most failures
           failed / SUM(failed) OVER () * 100 AS share_pct,              -- own share of all failures
           SUM(failed) OVER (ORDER BY failed DESC) / SUM(failed) OVER () * 100 AS cum_pct  -- running total
    FROM b
)
SELECT rnk, bank_name, ROUND(failed, 1) AS est_failed_mn,
       ROUND(share_pct, 1) AS share_pct, ROUND(cum_pct, 1) AS cum_share_pct
FROM r ORDER BY rnk LIMIT 15;