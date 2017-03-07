+++
categories = ["server"]
tags = ["php", "db", "centos"]
date = "2016-11-03T19:24:51+09:00"
draft = false
slug = "mssql-cent"
title = "CentOSからSQLServerへ接続"

+++

CentOSのPHP5.6から`PDO_ODBC`でSQLServer(MSSQL)へ接続する方法
<!--more-->
Macの場合は[こちら](../mssql-mac/)

なおCentOSからであれば`PDO_DBLIB`+`FreeTDS`も可能だが、公式ドライバがあるこちらを試してみた

## 手順
### SQLServerのドライバのインストール
1. 以下でインストール  
```
su
yum -y update
yum -y install yum-utils
yum-config-manager --add-repo https://apt-mo.trafficmanager.net/yumrepos/mssql-rhel6-release/
yum-config-manager --enable mssql-rhel6-release
wget "http://aka.ms/msodbcrhelpublickey/dpgswdist.v1.asc"
rpm --import dpgswdist.v1.asc
yum -y remove unixODBC
yum -y install msodbcsql # 途中にライセンスの承諾確認あり
yum -y install unixODBC-utf16-devel
```

1. ODBCドライバの確認
```
vi /etc/odbcinst.ini
```
として、以下のような文言があればOK
```
[ODBC Driver 13 for SQL Server]
Description=Microsoft ODBC Driver 13 for SQL Server
Driver=/opt/microsoft/msodbcsql/lib64/libmsodbcsql-13.0.so.1.0
UsageCount=1
```

### ODBCドライバの設定
```
sudo vi /etc/odbcinst.ini
```
として、次のような設定を追記する
```
[(ドライバ名として判り易い名称)]
Driver = （odbcinst.iniの[]で囲まれたドライバ名）
Description = (適当な説明)
Trace = Yes
Server = (サーバのIP)
Port = (サーバのポート)
Database = (データベース名)
```
上記の例の場合だと、
```
[SQLServer]
Driver = ODBC Driver 13 for SQL Server
Description = For Develop
Trace = Yes
Server = 192.168.0.10
Port = 1433
Database = sample
```
といった感じになる

### PDO_ODBCのインストール
1. 以下でインストール
```
yum -y install --enablerepo=remi --enablerepo=remi-php56 php-pdo php-odbc
```

1. 設定の確認
```
php -i | grep odbc
```
を実行して、`PDO drivers`に`odbc`が表示されていればOK

## PHPからの接続
PDOのDSNの指定は以下の通り
```
$driver = 'SQLServer';      // odbc.iniで設定したドライバ名
$user = 'test';             // ユーザ名
$pass = '1234';             // パスワード

$pdo = new PDO('odbc:' . $driver, $user, $pass); 
```

# 参考リンク
- PHP公式 [PDO_ODBC](http://php.net/manual/ja/ref.pdo-odbc.php)
- Microsoft公式 [ODBC Driver 13.0 for SQL Server](https://blogs.technet.microsoft.com/dataplatforminsider/2016/10/25/odbc-driver-13-0-for-sql-server-linux-is-now-released/)

# 開発環境
- CentOS6.8
- PHP 5.6.27 + PDO_ODBC
- ODBC Driver 13.0 for SQL Server
- DBサーバ SQLServer Express 2016(Win)
