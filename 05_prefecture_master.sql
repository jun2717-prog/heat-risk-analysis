-- ============================================================
-- 05_prefecture_master.sql
-- 都道府県マスタの作成と正規化 / Prefecture master table & normalization
--
--   prefecture (1) ──< population (n)   pref_code
--   prefecture (1) ──< weather    (n)   pref_code
-- ============================================================

USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

-- ------------------------------------------------------------
-- STEP 1: マスタテーブル / Master table
-- ------------------------------------------------------------
DROP TABLE IF EXISTS prefecture;
CREATE TABLE prefecture (
  pref_code     CHAR(5)     NOT NULL PRIMARY KEY,
  pref_name     VARCHAR(10) NOT NULL,   -- 北海道, 東京都 ...
  pref_name_en  VARCHAR(20),            -- Hokkaido, Tokyo ...
  jma_pref_name VARCHAR(10),            -- 気象庁の名称：石狩, 東京 ...
  city          VARCHAR(20) UNIQUE      -- 観測地点：札幌, 東京 ...
) CHARACTER SET utf8mb4;

-- 人口と気象の名前の違いをそろえて結合（北海道=石狩、末尾の都府県を除く）
-- Match names: Hokkaido = "石狩"; drop the trailing 都/府/県
INSERT INTO prefecture (pref_code, pref_name, jma_pref_name, city)
SELECT DISTINCT p.pref_code, p.pref_name, w.pref_name, w.city
FROM population p
JOIN (SELECT DISTINCT pref_name, city FROM weather) w
  ON w.pref_name = CASE WHEN p.pref_name = '北海道' THEN '石狩'
                        ELSE LEFT(p.pref_name, CHAR_LENGTH(p.pref_name) - 1) END;

-- 確認：47行 / Check: 47 rows
SELECT COUNT(*) FROM prefecture;

-- ------------------------------------------------------------
-- STEP 2: 英語名 / English names
-- ------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE prefecture
SET pref_name_en = CASE pref_code
  WHEN '01000' THEN 'Hokkaido'   WHEN '02000' THEN 'Aomori'
  WHEN '03000' THEN 'Iwate'      WHEN '04000' THEN 'Miyagi'
  WHEN '05000' THEN 'Akita'      WHEN '06000' THEN 'Yamagata'
  WHEN '07000' THEN 'Fukushima'  WHEN '08000' THEN 'Ibaraki'
  WHEN '09000' THEN 'Tochigi'    WHEN '10000' THEN 'Gunma'
  WHEN '11000' THEN 'Saitama'    WHEN '12000' THEN 'Chiba'
  WHEN '13000' THEN 'Tokyo'      WHEN '14000' THEN 'Kanagawa'
  WHEN '15000' THEN 'Niigata'    WHEN '16000' THEN 'Toyama'
  WHEN '17000' THEN 'Ishikawa'   WHEN '18000' THEN 'Fukui'
  WHEN '19000' THEN 'Yamanashi'  WHEN '20000' THEN 'Nagano'
  WHEN '21000' THEN 'Gifu'       WHEN '22000' THEN 'Shizuoka'
  WHEN '23000' THEN 'Aichi'      WHEN '24000' THEN 'Mie'
  WHEN '25000' THEN 'Shiga'      WHEN '26000' THEN 'Kyoto'
  WHEN '27000' THEN 'Osaka'      WHEN '28000' THEN 'Hyogo'
  WHEN '29000' THEN 'Nara'       WHEN '30000' THEN 'Wakayama'
  WHEN '31000' THEN 'Tottori'    WHEN '32000' THEN 'Shimane'
  WHEN '33000' THEN 'Okayama'    WHEN '34000' THEN 'Hiroshima'
  WHEN '35000' THEN 'Yamaguchi'  WHEN '36000' THEN 'Tokushima'
  WHEN '37000' THEN 'Kagawa'     WHEN '38000' THEN 'Ehime'
  WHEN '39000' THEN 'Kochi'      WHEN '40000' THEN 'Fukuoka'
  WHEN '41000' THEN 'Saga'       WHEN '42000' THEN 'Nagasaki'
  WHEN '43000' THEN 'Kumamoto'   WHEN '44000' THEN 'Oita'
  WHEN '45000' THEN 'Miyazaki'   WHEN '46000' THEN 'Kagoshima'
  WHEN '47000' THEN 'Okinawa'
END;

-- ------------------------------------------------------------
-- STEP 3: weather に結合キー pref_code を追加
--   Add the join key pref_code to weather
-- ------------------------------------------------------------
ALTER TABLE weather ADD COLUMN pref_code CHAR(5);

UPDATE weather w
JOIN prefecture p ON p.city = w.city
SET w.pref_code = p.pref_code;

SET SQL_SAFE_UPDATES = 1;

-- 確認：0 ならOK / Check: should be 0
SELECT COUNT(*) AS missing FROM weather WHERE pref_code IS NULL;

ALTER TABLE weather MODIFY pref_code CHAR(5) NOT NULL;

-- ------------------------------------------------------------
-- STEP 4: 重複する名前の列を削除（正規化）
--   Drop duplicated name columns (normalization)
-- ------------------------------------------------------------
ALTER TABLE population DROP COLUMN pref_name;
ALTER TABLE weather    DROP COLUMN pref_name;

-- ------------------------------------------------------------
-- STEP 5: 外部キー / Foreign keys
-- ------------------------------------------------------------
ALTER TABLE population
  ADD CONSTRAINT fk_population_prefecture
  FOREIGN KEY (pref_code) REFERENCES prefecture(pref_code);

ALTER TABLE weather
  ADD CONSTRAINT fk_weather_prefecture
  FOREIGN KEY (pref_code) REFERENCES prefecture(pref_code);

SELECT * FROM prefecture ORDER BY pref_code;
