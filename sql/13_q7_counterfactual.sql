-- QUESTION 7: How many technical failures could have been avoided if every bank-month that was
-- WORSE than its tier median had matched that median? (the "size of the prize")
-- avoided in a bank-month = volume * (bank TD rate - tier median TD rate) / 100, only if positive.
-- This is a what-if, not a forecast. Medians are a benchmark choice, not a promise anyone can hit.
USE upi_reliability;

-- Part A: total prize
SELECT ROUND(SUM(failed), 1) AS est_failed_mn,
       ROUND(SUM(CASE WHEN td_pct > tier_median_td
                      THEN volume_mn * (td_pct - tier_median_td) / 100 ELSE 0 END), 1) AS avoidable_mn,
       ROUND(SUM(CASE WHEN td_pct > tier_median_td
                      THEN volume_mn * (td_pct - tier_median_td) / 100 ELSE 0 END)
             / SUM(failed) * 100, 1) AS avoidable_pct_of_failures
FROM v_bank_month;

-- Part B: where is the prize? Top 10 banks
SELECT bank_name, tier,
       ROUND(SUM(failed), 1) AS est_failed_mn,
       ROUND(SUM(CASE WHEN td_pct > tier_median_td
                      THEN volume_mn * (td_pct - tier_median_td) / 100 ELSE 0 END), 1) AS avoidable_mn,
       ROUND(SUM(CASE WHEN td_pct > tier_median_td
                      THEN volume_mn * (td_pct - tier_median_td) / 100 ELSE 0 END)
             / SUM(failed) * 100, 0) AS avoidable_pct_of_bank
FROM v_bank_month
GROUP BY bank_id, bank_name, tier
ORDER BY avoidable_mn DESC
LIMIT 10;