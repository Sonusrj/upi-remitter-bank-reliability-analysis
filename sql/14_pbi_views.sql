-- VIEWS FOR POWER BI (phase 6A)
-- Power BI reads these so the dashboard shows exactly the numbers we verified in SQL.
-- They reuse v_bank_month from 09_views.sql, so run 09 first.
USE upi_reliability;

DROP VIEW IF EXISTS v_pbi_tier;
DROP VIEW IF EXISTS v_pbi_bank_summary;

-- One row per eligible bank (49 rows): size, volume, failures, profile and priority quadrant.
CREATE VIEW v_pbi_bank_summary AS
WITH prof AS (
    SELECT bank_id, bank_name, tier,
           COUNT(*)                                           AS months,
           AVG(volume_mn)                                     AS avg_volume_mn,
           SUM(volume_mn)                                     AS volume_mn,
           SUM(failed)                                        AS est_failed_mn,
           SUM(failed) / SUM(volume_mn) * 100                 AS weighted_td_pct,
           AVG(CASE WHEN td_pct > tier_median_td THEN 1.0 ELSE 0 END) * 100 AS persistence_pct,
           STDDEV_POP(td_pct) / AVG(td_pct)                   AS cv,
           SUM(failed) / SUM(volume_mn * (bd_pct + td_pct) / 100) * 100 AS tech_share_pct,
           AVG(td_pct)                                        AS mean_td_pct,
           SUM(CASE WHEN td_pct > tier_median_td
                    THEN volume_mn * (td_pct - tier_median_td) / 100 ELSE 0 END) AS avoidable_mn
    FROM v_bank_month
    GROUP BY bank_id, bank_name, tier
),
tier_rate AS (
    SELECT tier, SUM(est_failed_mn) / SUM(volume_mn) * 100 AS tier_td_pct
    FROM prof GROUP BY tier
),
x AS (
    SELECT p.*, t.tier_td_pct,
           p.est_failed_mn / SUM(p.est_failed_mn) OVER () * 100 AS impact_pct,
           p.weighted_td_pct / t.tier_td_pct                    AS severity_x,
           100.0 / COUNT(*) OVER ()                             AS equal_share_pct
    FROM prof p JOIN tier_rate t USING (tier)
)
SELECT bank_id, bank_name, tier,
       CASE tier WHEN 'Large' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END AS tier_order,
       months,
       ROUND(avg_volume_mn, 2)     AS avg_volume_mn,
       ROUND(volume_mn, 2)         AS volume_mn,
       ROUND(est_failed_mn, 3)     AS est_failed_mn,
       ROUND(weighted_td_pct, 4)   AS weighted_td_pct,
       ROUND(tier_td_pct, 4)       AS tier_td_pct,
       ROUND(persistence_pct, 1)   AS persistence_pct,
       ROUND(cv, 3)                AS cv,
       ROUND(tech_share_pct, 2)    AS tech_share_pct,
       ROUND(avoidable_mn, 3)      AS avoidable_mn,
       ROUND(impact_pct, 3)        AS impact_pct,
       ROUND(severity_x, 3)        AS severity_x,
       ROUND(equal_share_pct, 3)   AS equal_share_pct,
       CASE WHEN persistence_pct >= 75 THEN 'Chronic'
            WHEN persistence_pct >  50 THEN 'Mixed'
            WHEN cv >= 1.15            THEN 'Episodic'
            ELSE 'Healthy' END     AS profile_type,
       CASE WHEN impact_pct >= equal_share_pct AND severity_x >= 1.25 THEN 'Fix first'
            WHEN impact_pct >= equal_share_pct                         THEN 'Big but in line'
            WHEN severity_x >= 1.25                                    THEN 'Small but weak'
            ELSE 'Healthy' END     AS quadrant,
       CASE WHEN impact_pct >= equal_share_pct AND severity_x >= 1.25 THEN 1
            WHEN impact_pct >= equal_share_pct                         THEN 2
            WHEN severity_x >= 1.25                                    THEN 3
            ELSE 4 END             AS quadrant_order
FROM x;

-- One row per size tier (3 rows).
CREATE VIEW v_pbi_tier AS
SELECT tier,
       CASE tier WHEN 'Large' THEN 1 WHEN 'Mid' THEN 2 ELSE 3 END AS tier_order,
       COUNT(*)                                              AS banks,
       ROUND(SUM(volume_mn), 2)                              AS volume_mn,
       ROUND(SUM(est_failed_mn), 3)                          AS est_failed_mn,
       ROUND(SUM(est_failed_mn) / SUM(volume_mn) * 100, 4)   AS weighted_td_pct,
       ROUND(SUM(volume_mn) / (SELECT SUM(volume_mn) FROM v_pbi_bank_summary) * 100, 2)        AS volume_share_pct,
       ROUND(SUM(est_failed_mn) / (SELECT SUM(est_failed_mn) FROM v_pbi_bank_summary) * 100, 2) AS failure_share_pct
FROM v_pbi_bank_summary
GROUP BY tier;

SELECT quadrant, COUNT(*) AS banks FROM v_pbi_bank_summary GROUP BY quadrant ORDER BY MIN(quadrant_order);
SELECT ROUND(SUM(avoidable_mn), 1) AS avoidable_mn FROM v_pbi_bank_summary;