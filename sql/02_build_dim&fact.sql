-- Builds dim_bank (each bank once) and fact_upi_remitter (one row per bank per month)
USE upi_reliability;

DROP TABLE IF EXISTS fact_upi_remitter;
DROP TABLE IF EXISTS dim_bank;

CREATE TABLE dim_bank (
    bank_id           INT AUTO_INCREMENT PRIMARY KEY,
    bank_name         VARCHAR(100) NOT NULL UNIQUE,
    is_ranked         TINYINT NOT NULL,
    possible_same_as  VARCHAR(100) NULL
);

INSERT INTO dim_bank (bank_name, is_ranked, possible_same_as)
SELECT standard_name,
       MIN(is_ranked),
       NULLIF(MAX(possible_same_as), '')
FROM stg_mapping
GROUP BY standard_name;

CREATE TABLE fact_upi_remitter (
    month_date    DATE NOT NULL,
    bank_id       INT NOT NULL,
    volume_mn     DECIMAL(14,6) NOT NULL,
    approved_pct  DECIMAL(8,4) NOT NULL,
    bd_pct        DECIMAL(8,4) NOT NULL,
    td_pct        DECIMAL(8,4) NOT NULL,
    PRIMARY KEY (month_date, bank_id),
    FOREIGN KEY (bank_id) REFERENCES dim_bank (bank_id)
);

INSERT INTO fact_upi_remitter (month_date, bank_id, volume_mn, approved_pct, bd_pct, td_pct)
SELECT s.month, b.bank_id, s.volume_mn, s.approved_pct, s.bd_pct, s.td_pct
FROM stg_mapped s
JOIN dim_bank b ON b.bank_name = s.bank_name;

--
SELECT * FROM fact_upi_remitter;
SELECT * FROM dim_bank;