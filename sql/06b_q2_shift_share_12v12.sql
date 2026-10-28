-- QUESTION 2 (robust version): Compare the first 12 months with the last 12 months,
-- instead of two single months. Single months are noisy.
USE upi_reliability;

WITH panel AS (                               -- Step A: ranked banks present in all 24 months
    SELECT f.bank_id FROM fact_upi_remitter f
    JOIN dim_bank d USING (bank_id)
    WHERE d.is_ranked = 1
    GROUP BY f.bank_id HAVING COUNT(*) = 24
),
per AS (                                      -- Step B: per bank, per period (P1 = first 12, P2 = last 12)
    SELECT f.bank_id,
           CASE WHEN f.month_date <= '2025-07-01' THEN 'P1' ELSE 'P2' END AS period,
           SUM(f.volume_mn) AS v,
           SUM(f.volume_mn * f.td_pct / 100) AS failed
    FROM fact_upi_remitter f JOIN panel USING (bank_id)
    GROUP BY f.bank_id, period
),
tot AS (SELECT period, SUM(v) AS tv FROM per GROUP BY period),   -- Step C: panel total per period
s AS (                                        -- Step D: each bank's traffic share and own failure rate
    SELECT per.bank_id, per.period,
           per.v / tot.tv AS share,
           per.failed / per.v AS rate
    FROM per JOIN tot USING (period)
),
a AS (SELECT * FROM s WHERE period = 'P1'),
z AS (SELECT * FROM s WHERE period = 'P2')
-- Step E: same split as before: rate effect + mix effect = total change
SELECT ROUND(SUM(a.share * a.rate) * 100, 3)                          AS start_td_pct,
       ROUND(SUM(z.share * z.rate) * 100, 3)                          AS end_td_pct,
       ROUND(SUM((a.share + z.share) / 2 * (z.rate - a.rate)) * 100, 3) AS rate_effect_pp,
       ROUND(SUM((z.share - a.share) * (a.rate + z.rate) / 2) * 100, 3) AS mix_effect_pp,
       COUNT(*) AS banks_in_panel
FROM a JOIN z USING (bank_id);