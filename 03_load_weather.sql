-- ============================================================
-- 03_load_weather.sql
-- 気象データの取り込みと縦長への変換（SQLのみ）
-- Load JMA weather data and unpivot wide -> long using SQL only
--
-- 出典 / Source: 気象庁 過去の気象データ・ダウンロード
--   47 県庁所在地, 月別値, 2015-01 to 2024-12
--   月平均気温 / 日最高気温35℃以上日数（猛暑日）
-- 元データの形 / Raw format:
--   47地点が横に並ぶ（1地点6列：気温・品質・均質番号・猛暑日・品質・均質番号）
--   47 stations side by side, 6 columns per station
-- 前処理 / Preprocessing:
--   「品質情報・均質番号」の見出し行を削除 → データは6行目から
--   Removed the sub-header row; data starts on line 6
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

-- ------------------------------------------------------------
-- STEP 1: CSVの1行を、列に分けずにまるごと取り込む
--   Load each line as a single text value.
--   ファイルにタブは含まれないので '\t' 区切りなら1行＝1値になる
--   The file has no tabs, so '\t' keeps each line whole.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS weather_raw;
CREATE TABLE weather_raw (
  line_no INT AUTO_INCREMENT PRIMARY KEY,
  line    TEXT
) CHARACTER SET utf8mb4;

-- ★パスは自分の環境に合わせる / Adjust the path
LOAD DATA LOCAL INFILE '/Users/jun/Desktop/SQL portfolio source/weather data.csv'
INTO TABLE weather_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
(line);

-- 確認：ヘッダ5行 + 120か月 = 125行 / Check: 125 rows
SELECT COUNT(*) FROM weather_raw;
SELECT line_no, LEFT(line, 60) AS preview FROM weather_raw WHERE line_no <= 8;

-- ------------------------------------------------------------
-- STEP 2: 地点番号 0〜46 の補助テーブル
--   Helper table with station index 0-46
-- ------------------------------------------------------------
DROP TABLE IF EXISTS k;
CREATE TABLE k AS
SELECT line_no - 1 AS n FROM weather_raw WHERE line_no <= 47;

-- ------------------------------------------------------------
-- STEP 3: 縦長テーブル / Long-format table
-- ------------------------------------------------------------
DROP TABLE IF EXISTS weather;
CREATE TABLE weather (
  city         VARCHAR(20) NOT NULL,  -- 観測地点（県庁所在地）/ station city
  pref_name    VARCHAR(10),           -- 気象庁の都府県名 / JMA name (dropped in 05)
  year         INT         NOT NULL,
  month        INT         NOT NULL,
  avg_temp     DECIMAL(4,1),          -- 月平均気温
  temp_quality INT,                   -- 品質情報 8=正常, 5=準正常
  hot_days     INT,                   -- 猛暑日数（35℃以上）
  hot_quality  INT,
  PRIMARY KEY (city, year, month)
) CHARACTER SET utf8mb4;

-- ------------------------------------------------------------
-- STEP 4: 横長 -> 縦長 / Unpivot
--   列の並び：1 年 / 2 月 / 以降1地点6列
--   Column layout: 1 year, 2 month, then 6 columns per station
--   地点n: 気温 = 3+6n番目, 品質 = 4+6n, 猛暑日 = 6+6n, 品質 = 7+6n
--   SUBSTRING_INDEX(SUBSTRING_INDEX(s, ',', i), ',', -1) = i番目の値 / i-th value
-- ------------------------------------------------------------
INSERT INTO weather
SELECT
  SUBSTRING_INDEX(SUBSTRING_INDEX(h4.line, ',', 3 + 6*k.n), ',', -1) AS city,
  SUBSTRING_INDEX(SUBSTRING_INDEX(h3.line, ',', 3 + 6*k.n), ',', -1) AS pref_name,
  SUBSTRING_INDEX(d.line, ',', 1)                                    AS year,
  SUBSTRING_INDEX(SUBSTRING_INDEX(d.line, ',', 2), ',', -1)          AS month,
  SUBSTRING_INDEX(SUBSTRING_INDEX(d.line, ',', 3 + 6*k.n), ',', -1)  AS avg_temp,
  SUBSTRING_INDEX(SUBSTRING_INDEX(d.line, ',', 4 + 6*k.n), ',', -1)  AS temp_quality,
  SUBSTRING_INDEX(SUBSTRING_INDEX(d.line, ',', 6 + 6*k.n), ',', -1)  AS hot_days,
  SUBSTRING_INDEX(SUBSTRING_INDEX(d.line, ',', 7 + 6*k.n), ',', -1)  AS hot_quality
FROM weather_raw d                          -- データ行 / data rows
JOIN weather_raw h3 ON h3.line_no = 3       -- 3行目：都府県名 / prefecture (JMA)
JOIN weather_raw h4 ON h4.line_no = 4       -- 4行目：地点名 / station city
CROSS JOIN k                                -- 47地点ぶん展開 / expand 47 stations
WHERE d.line_no >= 6;

-- 確認：47地点 × 120か月 = 5640行 / Check: 5640 rows
SELECT COUNT(*) FROM weather;

-- データ品質の確認 / Data quality check
SELECT temp_quality, hot_quality, COUNT(*) AS cnt
FROM weather
GROUP BY temp_quality, hot_quality;
