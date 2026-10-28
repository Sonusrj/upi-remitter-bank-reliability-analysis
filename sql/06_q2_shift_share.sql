-- QUESTION 2: Did the overall TD rate change because banks themselves
-- got better or worse (rate effect), or because traffic moved between
-- banks (mix effect)?
-- Method: compare Aug 2024 vs Jul 2026 on banks present in ALL 24 months.
USE upi_reliability;

-- Step A: the balanced panel = ranked banks with all 24 months.
WITH panel AS (
    SELECT f.bank_id FROM fact_upi_remitter f
    JOIN dim_bank d USING (bank_id)
    WHERE d.is_ranked = 1
    GROUP BY f.bank_id HAVING COUNT(*) = 24
),
-- Step B: keep only panel banks, and add each bank's failures.
p AS (
    SELECT f.month_date, f.bank_id, f.volume_mn,
           f.volume_mn * f.td_pct / 100 AS failed
    FROM fact_upi_remitter f JOIN panel USING (bank_id)
),
-- Step C: monthly panel total, to turn volume into a share.
tot AS (SELECT month_date, SUM(volume_mn) AS v FROM p GROUP BY month_date),
-- Step D: per bank per month: share of traffic and own failure rate.
s AS (
    SELECT p.month_date, p.bank_id,
           p.volume_mn / t.v AS share,
           p.failed / p.volume_mn AS rate
    FROM p JOIN tot t USING (month_date)
),
-- Step E: two snapshots, start and end.
a AS (SELECT * FROM s WHERE month_date = '2024-08-01'),
z AS (SELECT * FROM s WHERE month_date = '2026-07-01')
-- Step F: overall rate = sum of (share x rate).
-- rate_effect: banks' own rate change, weighted by average share.
-- mix_effect: share change, weighted by average rate.
-- The two add up to end minus start (using averages makes it order-independent).
SELECT ROUND(SUM(a.share * a.rate) * 100, 3)                          AS start_td_pct,
       ROUND(SUM(z.share * z.rate) * 100, 3)                          AS end_td_pct,
       ROUND(SUM((a.share + z.share) / 2 * (z.rate - a.rate)) * 100, 3) AS rate_effect_pp,
       ROUND(SUM((z.share - a.share) * (a.rate + z.rate) / 2) * 100, 3) AS mix_effect_pp,
       COUNT(*) AS banks_in_panel
FROM a JOIN z USING (bank_id);