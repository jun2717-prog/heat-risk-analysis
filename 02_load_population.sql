-- ============================================================
-- 02_load_population.sql
-- 人口データの取り込み / Load population data
--
-- 出典 / Source: e-Stat 社会・人口統計体系 都道府県データ
--   A1101 総人口 / A1303 65歳以上人口, 2015–2024
-- 前処理 / Preprocessing:
--   先頭のタイトル行を削除し、1行目を英語の列名に置き換え
--   Removed title rows; replaced header with English column names:
--   year_code,year_label,area_code,area_name,item,total_pop,pop_65plus
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

DROP TABLE IF EXISTS population;

CREATE TABLE population (
  pref_code  CHAR(5)     NOT NULL,   -- 01000 = 北海道
  pref_name  VARCHAR(10) NOT NULL,   -- 05 でマスタへ移したあと削除 / dropped in 05
  year       INT         NOT NULL,
  total_pop  INT,
  pop_65plus INT,
  PRIMARY KEY (pref_code, year)
) CHARACTER SET utf8mb4;

-- ★パスは自分の環境に合わせる / Adjust the path
LOAD DATA LOCAL INFILE '/Users/jun/Desktop/SQL portfolio source/FEI_PREF_260928140730.csv'
INTO TABLE population
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@year_code, @year_label, @area_code, @area_name, @item, @total, @pop65)
SET
  pref_code  = LPAD(@area_code, 5, '0'),            -- 1000 -> 01000
  pref_name  = @area_name,
  year       = LEFT(@year_code, 4),                 -- 2024100000 -> 2024
  total_pop  = NULLIF(TRIM(@total), ''),
  pop_65plus = NULLIF(TRIM(TRAILING '\r' FROM @pop65), '');

-- 全国の行は不要 / Remove the national total row
DELETE FROM population WHERE pref_code = '00000';

-- 確認：47都道府県 × 10年 = 470行 / Check: 470 rows
SELECT COUNT(*) AS row_count FROM population;

SELECT year, COUNT(*) AS prefs
FROM population
GROUP BY year
ORDER BY year;
