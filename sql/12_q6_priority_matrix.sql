-- QUESTION 6: Which banks should a UPI app team or bank ops team look at FIRST?
-- Two axes:  IMPACT   = the bank's share of all estimated technical failures
--            SEVERITY = how much worse its rate is than its own size tier (ratio, 1.0 = same as tier)
-- Cut-offs (our choices):  high impact = share above an "equal share" (100% / 49 banks = 2.04%)
--                          high severity = rate at least 1.25 x the tier rate
USE upi_reliability;

WITH b AS (
    SELECT bank_name, tier, SUM(failed) AS failed, SUM(volume_mn) AS vol
    FROM v_bank_month GROUP BY bank_id, bank_name, tier
),
t AS (SELECT tier, SUM(failed) / SUM(vol) AS tier_rate FROM b GROUP BY tier),
x AS (
    SELECT b.bank_name, b.tier, b.failed,
           b.failed / SUM(b.failed) OVER () * 100 AS impact_pct,
           (b.failed / b.vol) / t.tier_rate         AS severity_x
    FROM b JOIN t USING (tier)
)
SELECT bank_name, tier,
       ROUND(failed, 1)      AS est_failed_mn,
       ROUND(impact_pct, 2)  AS impact_pct,
       ROUND(severity_x, 2)  AS severity_x_tier,
       CASE WHEN impact_pct >= 100.0 / 49 AND severity_x >= 1.25 THEN '1 Fix first'
            WHEN impact_pct >= 100.0 / 49                        THEN '2 Big but in line'
            WHEN severity_x >= 1.25                               THEN '3 Small but weak'
            ELSE '4 Healthy' END AS quadrant
FROM x
ORDER BY quadrant, impact_pct DESC;