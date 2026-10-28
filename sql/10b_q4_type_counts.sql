-- Count banks by profile type (same rules as file 10)
USE upi_reliability;

WITH prof AS (
    SELECT bank_name,
           AVG(CASE WHEN td_pct > tier_median_td THEN 1.0 ELSE 0 END) * 100 AS persistence_pct,
           STDDEV_POP(td_pct) / AVG(td_pct) AS cv
    FROM v_bank_month
    GROUP BY bank_id, bank_name
),
typed AS (
    SELECT CASE WHEN persistence_pct >= 75 THEN 'Chronic'
                WHEN persistence_pct >  50 THEN 'Mixed'
                WHEN cv >= 1.15            THEN 'Episodic'
                ELSE 'Healthy' END AS profile_type
    FROM prof
)
SELECT profile_type, COUNT(*) AS banks
FROM typed
GROUP BY profile_type
ORDER BY banks DESC;