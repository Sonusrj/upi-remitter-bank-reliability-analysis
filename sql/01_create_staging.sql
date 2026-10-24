CREATE DATABASE IF NOT EXISTS upi_reliability;
USE upi_reliability;

-- Staging: exact copy of notebook 02 output, no rules yet
CREATE TABLE stg_mapped (
    month         DATE,
    bank_name     VARCHAR(100),
    volume_mn     DECIMAL(14,6),
    approved_pct  DECIMAL(8,4),
    bd_pct        DECIMAL(8,4),
    td_pct        DECIMAL(8,4),
    is_ranked     TINYINT
);

-- Staging: our decision logstg_mappedmonthmonth
CREATE TABLE stg_mapping (
    bank_raw          VARCHAR(150),
    standard_name     VARCHAR(100),
    `rule`            VARCHAR(30),
    is_ranked         TINYINT,
    possible_same_as  VARCHAR(100),
    note              VARCHAR(255)
);

SELECT COUNT(*) AS mapped_rows FROM stg_mapped;     -- expect 1198
SELECT COUNT(*) AS mapping_rows FROM stg_mapping;   -- expect 117

SELECT month,
       ROUND(SUM(volume_mn), 2) AS volume_mn,
       ROUND(SUM(volume_mn * td_pct / 100), 3) AS est_failed_mn,
       ROUND(SUM(volume_mn * td_pct / 100) / SUM(volume_mn) * 100, 3) AS weighted_td_pct
FROM stg_mapped
GROUP BY month
ORDER BY month;
