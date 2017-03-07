+++
categories = ["server"]
tags = ["php", "db"]
date = "2016-10-10T02:03:14+09:00"
draft = false
slug = "phpstorm-sakura"
title = "PhpStormからさくらのレンタルサーバを使う"

+++

さくらのレンタルサーバ（スタンダード）をPhpStormから使うにあたっての便利な小ネタ

<!--more-->

## さくらのDBに接続する
### 設定情報
接続したいさくらのDBは、

- DBサーバ:mysql***.db.sakura.ne.jp
- データベース名:アカウント名_testdb
- ユーザ名:アカウント名
- パスワード:pass

とし、事前に作成済みとする

### PhpStormでの設定
1\. `PhpStorm`で適当なプロジェクトを作って起動  
2\. メニューの`View` - `Tool Windows` - `Database`を選択  
3\. ツールウィンドウの左上の`+` - `Data Source` - `MySQL`を選択  
4\. `SSH/SSL`のタブを選択  
5\. `Use SSH tunnel`にチェック  

項目 | 設定値 |
--- | ----- | 
Proxy host | アカウント名.sakura.ne.jp | 
Port | 22 | 
Proxy user | アカウント名 |  
Auth type | Password |  
Proxy password | サーバのパスワード  

6\. `Test Connection`を押して`Error`と出なければ接続OK  
7\. `General`のタブを選択  

項目 | 設定値 |   |
--- | ----- | --- |
Host | mysql***.db.sakura.ne.jp | 
Port | 3306 |  
Database | アカウント名_testdb |  
User | アカウント名 | 
Password | pass | DBのパスワード 

8\. `Test Connection`を押して`Successful`と出れば接続OK  
9\. `Options`タブを選択  
10\. `Resolve ...`の欄でDB名にチェックを入れる  
11\. `OK`で閉じるとツールウィンドウ内にDBが表示される  

## サーバの中を見る（FTP）
PhpStorm内蔵のFTPの設定方法。
ファイルのアップロードには制約があるが、代わりにローカルファイルとの差分を表示や同期ができるなど結構便利

1\. `PhpStorm`で適当なプロジェクトを作って起動  
2\. メニューの`View` - `Tool Windows` - `Remote Host`を選択  
3\. ツールウィンドウの`...`を選択  
4\. `Name`に適当な名前をつける  
5\. `Type`で`SFTP`を選択  

項目 | 設定値 |
--- | ----- |
SFTP host | アカウント名.sakura.ne.jp |  
Port | 22 |  
Root path | /home/アカウント名/ |  
User name | アカウント名 |  
Auth type | Password |  
Password | サーバのパスワード |  

6\. `Test SFTP connection`を押して`Successful`と出れば接続OK  

ここまで設定すればサーバ内のファイルの閲覧や削除などが行える。
さらに、アップロードやローカルファイルとの比較などがしたい場合は、ローカルとの紐付けが必要

7\. `Mappings`のタブを選択  
8\. `Loacal path`に既存プロジェクトのパスが入っていることを確認  
9\. `Deployment path on server 〜`に対応するサーバのパスを選択  

これでツールウィンドウの中にサーバ上のファイルが表示され、右クリックでいろいろできるようになる

# 開発環境
- PhpStorm 2016.2
- さくらのレンタルサーバ（スタンダード）
  - MySQL 5.5
