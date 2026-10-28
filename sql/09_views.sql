-- VIEWS used by analyses 4 to 7 (a view = a saved query you can treat like a table)
USE upi_reliability;

-- v_bank_tier: one row per ELIGIBLE bank (ranked, 12+ months) with its size tier.
-- Tier rule (our choice): average monthly volume >= 500 Mn = Large, 100 to 500 = Mid, below 100 = Small.
DROP VIEW IF EXISTS v_bank_month;
DROP VIEW IF EXISTS v_bank_tier;
CREATE VIEW v_bank_tier AS
SELECT d.bank_id, d.bank_name,
       COUNT(*)         AS months,
       AVG(f.volume_mn) AS avg_volume_mn,
       CASE WHEN AVG(f.volume_mn) >= 500 THEN 'Large'
            WHEN AVG(f.volume_mn) >= 100 THEN 'Mid'
            ELSE 'Small' END AS tier
FROM fact_upi_remitter f JOIN dim_bank d USING (bank_id)
WHERE d.is_ranked = 1
GROUP BY d.bank_id, d.bank_name
HAVING COUNT(*) >= 12;

-- v_bank_month: one row per eligible bank per month, plus that month's peer median TD rate.
-- Peer = banks in the same size tier, same month.
-- MySQL has no MEDIAN, so: sort banks by td_pct, number them (rn), count them (cnt);
-- the middle row(s) are where 2*rn is cnt, cnt+1 or cnt+2. Average those = median.
CREATE VIEW v_bank_month AS
WITH x AS (
    SELECT f.month_date, t.bank_id, t.bank_name, t.tier,
           f.volume_mn, f.bd_pct, f.td_pct,
           f.volume_mn * f.td_pct / 100 AS failed,
           ROW_NUMBER() OVER (PARTITION BY f.month_date, t.tier ORDER BY f.td_pct) AS rn,
           COUNT(*)     OVER (PARTITION BY f.month_date, t.tier)                   AS cnt
    FROM fact_upi_remitter f JOIN v_bank_tier t USING (bank_id)
),
m AS (
    SELECT month_date, tier, AVG(td_pct) AS tier_median_td
    FROM x
    WHERE 2 * rn IN (cnt, cnt + 1, cnt + 2)
    GROUP BY month_date, tier
)
SELECT x.month_date, x.bank_id, x.bank_name, x.tier, x.volume_mn, x.bd_pct, x.td_pct,
       x.failed, m.tier_median_td
FROM x JOIN m USING (month_date, tier);