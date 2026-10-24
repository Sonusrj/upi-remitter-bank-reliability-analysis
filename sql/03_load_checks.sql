-- Load checks for staging, dim_bank and fact_upi_remitter
USE upi_reliability;

-- 1. Staging counts. Expect: 1198, 117, 1165, 33
SELECT 'stg_mapped rows' AS check_name, COUNT(*) AS result FROM stg_mapped
UNION ALL SELECT 'stg_mapping rows', COUNT(*) FROM stg_mapping
UNION ALL SELECT 'ranked bank-months', COUNT(*) FROM stg_mapped WHERE is_ranked = 1
UNION ALL SELECT 'unranked bank-months', COUNT(*) FROM stg_mapped WHERE is_ranked = 0;

-- 2. Final table counts. Expect: 61, 55, 1198
SELECT 'dim_bank rows' AS check_name, COUNT(*) AS result FROM dim_bank
UNION ALL SELECT 'ranked banks', COUNT(*) FROM dim_bank WHERE is_ranked = 1
UNION ALL SELECT 'fact rows', COUNT(*) FROM fact_upi_remitter;

-- 3. Bank names in staging that did not make it into dim_bank. Expect: 0 rows
SELECT DISTINCT s.bank_name
FROM stg_mapped s
LEFT JOIN dim_bank b ON b.bank_name = s.bank_name
WHERE b.bank_id IS NULL;

-- 4. Control months from the final tables. Expect:
--    2024-08-01  15498.84  54.888   0.354
--    2025-01-01  18004.92  90.542   0.503
--    2026-07-01  25897.80  103.225  0.399
SELECT month_date,
       ROUND(SUM(volume_mn), 2) AS volume_mn,
       ROUND(SUM(volume_mn * td_pct / 100), 3) AS est_failed_mn,
       ROUND(SUM(volume_mn * td_pct / 100) / SUM(volume_mn) * 100, 3) AS weighted_td_pct
FROM fact_upi_remitter
WHERE month_date IN ('2024-08-01', '2025-01-01', '2026-07-01')
GROUP BY month_date
ORDER BY month_date;