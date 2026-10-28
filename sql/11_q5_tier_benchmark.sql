-- QUESTION 5: Is each bank's failure rate good or bad compared with banks of its own size?
-- (Part A) tier summary, (Part B) every bank vs its tier benchmark.
USE upi_reliability;

-- Part A: how big is each tier and how reliable is it overall?
SELECT tier,
       COUNT(DISTINCT bank_id)                                              AS banks,
       ROUND(SUM(volume_mn) / (SELECT SUM(volume_mn) FROM v_bank_month) * 100, 1) AS volume_share_pct,
       ROUND(SUM(failed)    / (SELECT SUM(failed)    FROM v_bank_month) * 100, 1) AS failure_share_pct,
       ROUND(SUM(failed) / SUM(volume_mn) * 100, 3)                         AS tier_weighted_td_pct
FROM v_bank_month
GROUP BY tier
ORDER BY FIELD(tier, 'Large', 'Mid', 'Small');

-- Part B: each bank vs its tier's weighted rate (gap in percentage points; + = worse than tier)
WITH b AS (
    SELECT bank_name, tier, SUM(failed) AS failed, SUM(volume_mn) AS vol
    FROM v_bank_month GROUP BY bank_id, bank_name, tier
),
t AS (
    SELECT tier, SUM(failed) / SUM(vol) * 100 AS tier_td FROM b GROUP BY tier
)
SELECT b.tier, b.bank_name,
       ROUND(b.failed / b.vol * 100, 3)                    AS bank_td_pct,
       ROUND(t.tier_td, 3)                                 AS tier_td_pct,
       ROUND(b.failed / b.vol * 100 - t.tier_td, 3)        AS gap_pp,
       RANK() OVER (PARTITION BY b.tier ORDER BY b.failed / b.vol DESC) AS worst_rank_in_tier
FROM b JOIN t USING (tier)
ORDER BY FIELD(b.tier, 'Large', 'Mid', 'Small'), worst_rank_in_tier;