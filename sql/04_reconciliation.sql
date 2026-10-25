USE upi_reliability;

-- Check 1a. Expect 1198 and 1198
SELECT 'stg_mapped' AS stage, COUNT(*) AS row_count FROM stg_mapped
UNION ALL
SELECT 'fact_upi_remitter', COUNT(*) FROM fact_upi_remitter;

-- Check 1b. Expect 2 rows: 2026-03-01 and 2026-06-01, both with 49
SELECT month_date, COUNT(*) AS banks
FROM fact_upi_remitter
GROUP BY month_date
HAVING COUNT(*) <> 50;

-- Check 2. Expect 0
SELECT COUNT(*) AS mismatched_rows
FROM stg_mapped s
JOIN dim_bank b ON b.bank_name = s.bank_name
LEFT JOIN fact_upi_remitter f
       ON f.month_date = s.month AND f.bank_id = b.bank_id
WHERE f.bank_id IS NULL
   OR f.volume_mn    <> s.volume_mn
   OR f.approved_pct <> s.approved_pct
   OR f.bd_pct       <> s.bd_pct
   OR f.td_pct       <> s.td_pct;
   
   
   -- Check 3a. Expect 0 in every row
SELECT 'sum rule broken (gap over 0.1)' AS test, COUNT(*) AS bad_rows
FROM fact_upi_remitter
WHERE ABS(approved_pct + bd_pct + td_pct - 100) > 0.1
UNION ALL
SELECT 'volume zero or negative', COUNT(*)
FROM fact_upi_remitter WHERE volume_mn <= 0
UNION ALL
SELECT 'a rate outside 0 to 100', COUNT(*)
FROM fact_upi_remitter
WHERE approved_pct NOT BETWEEN 0 AND 100
   OR bd_pct       NOT BETWEEN 0 AND 100
   OR td_pct       NOT BETWEEN 0 AND 100
UNION ALL
SELECT 'bank listed twice in a month', COUNT(*)
FROM (SELECT 1 FROM fact_upi_remitter
      GROUP BY month_date, bank_id HAVING COUNT(*) > 1) d;

-- Check 3b. Expect 0.01 or smaller (rounding in NPCI's published rates)
SELECT MAX(ABS(approved_pct + bd_pct + td_pct - 100)) AS max_sum_gap
FROM fact_upi_remitter;


(SELECT f.month_date, b.bank_name, f.volume_mn, f.approved_pct, f.bd_pct, f.td_pct
 FROM fact_upi_remitter f JOIN dim_bank b ON b.bank_id = f.bank_id
 WHERE f.month_date BETWEEN '2024-08-01' AND '2024-12-01'
   AND b.bank_name <> 'Slice Small Finance Bank Limited'
 ORDER BY RAND(42) LIMIT 3)
UNION ALL
(SELECT f.month_date, b.bank_name, f.volume_mn, f.approved_pct, f.bd_pct, f.td_pct
 FROM fact_upi_remitter f JOIN dim_bank b ON b.bank_id = f.bank_id
 WHERE f.month_date BETWEEN '2025-01-01' AND '2025-06-01'
   AND b.bank_name <> 'Slice Small Finance Bank Limited'
 ORDER BY RAND(42) LIMIT 3)
UNION ALL
(SELECT f.month_date, b.bank_name, f.volume_mn, f.approved_pct, f.bd_pct, f.td_pct
 FROM fact_upi_remitter f JOIN dim_bank b ON b.bank_id = f.bank_id
 WHERE f.month_date BETWEEN '2025-07-01' AND '2026-07-01'
   AND b.bank_name <> 'Slice Small Finance Bank Limited'
 ORDER BY RAND(42) LIMIT 4);
 
 -- Check 5. Top 50 approved volume per month (Mn)
SELECT month_date,
       ROUND(SUM(volume_mn * approved_pct / 100), 1) AS top50_approved_mn
FROM fact_upi_remitter
GROUP BY month_date
ORDER BY month_date;