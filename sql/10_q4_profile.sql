-- QUESTION 4: Which banks have a CHRONIC reliability problem, which have one-off (EPISODIC) bad
-- months, and which are healthy? Eligible banks only (ranked, 12+ months), from v_bank_month.
USE upi_reliability;

WITH prof AS (
    SELECT bank_name, tier,
           COUNT(*)                                       AS months,
           SUM(failed)                                    AS est_failed_mn,
           SUM(failed) / SUM(volume_mn) * 100             AS weighted_td_pct,   -- total failed / total volume
           -- persistence: % of months the bank was WORSE than its tier's median that month
           AVG(CASE WHEN td_pct > tier_median_td THEN 1.0 ELSE 0 END) * 100 AS persistence_pct,
           -- volatility: coefficient of variation = std dev / mean of the monthly TD rate
           STDDEV_POP(td_pct) / AVG(td_pct)               AS cv,
           -- technical share of declines: of all declines, how many were the bank's fault (TD)?
           SUM(failed) / SUM(volume_mn * (bd_pct + td_pct) / 100) * 100 AS tech_share_pct
    FROM v_bank_month
    GROUP BY bank_id, bank_name, tier
)
SELECT bank_name, tier, months,
       ROUND(est_failed_mn, 1)    AS est_failed_mn,
       ROUND(weighted_td_pct, 3)  AS weighted_td_pct,
       ROUND(persistence_pct, 0)  AS persistence_pct,
       ROUND(cv, 2)               AS cv,
       ROUND(tech_share_pct, 1)   AS tech_share_pct,
       -- Our rules (choices, not laws):
       -- Chronic  = worse than peer median in 75%+ of months
       -- Mixed    = worse than peers in 50 to 75% of months
       -- Episodic = better than peers most months, but spiky (cv >= 1.15)
       -- Healthy  = better than peers most months and stable
       CASE WHEN persistence_pct >= 75 THEN 'Chronic'
            WHEN persistence_pct >  50 THEN 'Mixed'
            WHEN cv >= 1.15            THEN 'Episodic'
            ELSE 'Healthy' END    AS profile_type
FROM prof
ORDER BY est_failed_mn DESC;