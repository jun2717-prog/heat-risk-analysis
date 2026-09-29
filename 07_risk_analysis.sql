-- ============================================================
-- 07_risk_analysis.sql
-- 熱中症リスクの4分類 / Classify prefectures into 4 heat-risk groups
--   高齢化率：2024年（最新の人口構成）/ Aging rate: 2024 (latest)
--   猛暑日数：2015–2024年の年平均（年ごとの変動をならす）
--   Hot days: 2015–2024 annual average (smooths year-to-year swings)
--   基準：47都道府県の平均 / Threshold: mean of 47 prefectures
--   → pref_risk.csv として書き出し（Tableau用）/ Export as pref_risk.csv
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

WITH aging_2024 AS (
  SELECT pref_code, pref_name, pref_name_en, aging_rate
  FROM pref_year_summary
  WHERE year = 2024
),
hot_avg AS (
  SELECT pref_code, ROUND(AVG(hot_days), 1) AS hot_days_avg
  FROM pref_year_summary
  GROUP BY pref_code
),
combined AS (
  SELECT a.pref_code, a.pref_name, a.pref_name_en, a.aging_rate, h.hot_days_avg
  FROM aging_2024 a
  JOIN hot_avg h ON h.pref_code = a.pref_code
),
national AS (
  SELECT AVG(aging_rate) AS avg_aging, AVG(hot_days_avg) AS avg_hot
  FROM combined
)
SELECT c.pref_name, c.pref_name_en, c.aging_rate, c.hot_days_avg,
  CASE
    WHEN c.aging_rate >= n.avg_aging AND c.hot_days_avg >= n.avg_hot THEN '1_高リスク'
    WHEN c.hot_days_avg >= n.avg_hot THEN '2_猛暑型'
    WHEN c.aging_rate >= n.avg_aging THEN '3_高齢化型'
    ELSE '4_低リスク'
  END AS risk_group
FROM combined c
CROSS JOIN national n
ORDER BY risk_group, c.hot_days_avg DESC;
