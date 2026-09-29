-- ============================================================
-- 01_create_database.sql
-- データベースの作成 / Create the database
-- ============================================================

-- 一から作り直す場合のみ実行 / Run only when rebuilding from scratch
-- DROP DATABASE IF EXISTS heat_risk;

CREATE DATABASE IF NOT EXISTS heat_risk CHARACTER SET utf8mb4;
USE heat_risk;
SET NAMES utf8mb4;   -- 日本語の文字列を正しく扱う / handle Japanese text correctly

-- ローカルCSVの読み込みを許可（MySQL再起動後も保持）
-- Allow LOAD DATA LOCAL INFILE (persists after restart)
-- ※ Workbench の接続設定 Advanced > Others に OPT_LOCAL_INFILE=1 も必要
--   Also set OPT_LOCAL_INFILE=1 in the Workbench connection (Advanced > Others)
SET PERSIST local_infile = 1;
