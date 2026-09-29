-- ============================================================
-- 04_eda.sql
-- 探索的データ分析 / Exploratory Data Analysis
-- ※ 05 で pref_name 列を削除する前に実行 / Run before 05 (uses pref_name)
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

-- 2024年の高齢化率トップ10
-- Top 10 prefectures by aging rate (2024)
SELECT pref_name, total_pop, pop_65plus,
       ROUND(pop_65plus / total_pop * 100, 1) AS aging_rate
FROM population
WHERE year = 2024
ORDER BY aging_rate DESC
LIMIT 10;

-- 2024年の猛暑日数トップ10（12か月の合計）
-- Top 10 cities by extremely hot days (35°C+) in 2024
SELECT city, pref_name, SUM(hot_days) AS hot_days_2024
FROM weather
WHERE year = 2024
GROUP BY city, pref_name
ORDER BY hot_days_2024 DESC
LIMIT 10;
