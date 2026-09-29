-- ============================================================
-- 06_pref_year_summary.sql
-- 都道府県×年の分析用テーブル / Prefecture-year analysis table
--   → pref_year_summary.csv として書き出し（推移分析用）
--   → Export as pref_year_summary.csv
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

DROP TABLE IF EXISTS pref_year_summary;

CREATE TABLE pref_year_summary AS
WITH weather_year AS (
  -- 月別 -> 年別 / Monthly -> yearly
  SELECT pref_code, year,
         SUM(hot_days)           AS hot_days,   -- 年間猛暑日数 / hot days per year
         ROUND(AVG(avg_temp), 1) AS avg_temp    -- 年平均気温 / annual mean temp
  FROM weather
  GROUP BY pref_code, year
)
SELECT pr.pref_code, pr.pref_name, pr.pref_name_en, pr.city, p.year,
       p.total_pop, p.pop_65plus,
       ROUND(p.pop_65plus / p.total_pop * 100, 1) AS aging_rate,
       w.hot_days, w.avg_temp
FROM population p
JOIN prefecture   pr ON pr.pref_code = p.pref_code
JOIN weather_year w  ON w.pref_code  = p.pref_code AND w.year = p.year;

-- 確認：470行 / Check: 470 rows
SELECT COUNT(*) FROM pref_year_summary;

SELECT * FROM pref_year_summary ORDER BY pref_code, year;
