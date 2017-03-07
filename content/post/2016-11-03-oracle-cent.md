+++
categories = ["server"]
tags = ["php", "db", "centos"]
date = "2016-11-03T19:24:51+09:00"
draft = false
slug = "oracle-cent"
title = "CentOSからOracleへ接続"

+++

CentOSのPHP5.6から別サーバで動いているOracleのDBへ`oci8`で接続する方法
<!--more-->
Macの場合は[こちら](../oracle-mac/)

## 手順

### Oracleのドライバのインストール
1. サーバのアーキテクチャを確認
```
uname -a
```

1. [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/index.html)から
1で確認した環境の`basic`と`SDK`をダウンロードしサーバへ保存  
  (今回は`x86_64`だったので`Version 12.1.0.2 (x86_64)`の`rpm`を選択。以降このバージョンが前提) 

1. 以下でインストール
```
cd (保存した場所)
su
rpm -ivh oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
rpm -ivh oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm
```

1. パスを通す  
```
vi /etc/profile
# 以下の行を追加
export LD_LIBRARY_PATH=/usr/lib/oracle/12.1/client64/lib:$LD_LIBRARY_PATH
export PATH=/usr/lib/oracle/12.1/client64/bin:$PATH
```
追記したら保存して終了し
```
source /etc/profile
```
で強制反映させる

### peclのインストール
1. 以下でインストール
```
yum -y install --enablerepo=remi --enablerepo=remi-php56 php-pear
```

### oci8のインストール
1. `pecl`からインストールするので`DTrace`サポートを有効にする
```
yum -y install systemtap-sdt-devel
export PHP_DTRACE=yes
```
> ちなみにこれをしないと`error: oci8_dtrace_gen.h: No such file or director`というエラーになる。
> 詳細は[こちら](http://php.net/manual/ja/oci8.dtrace.php)

1. `oci8`をバージョン（Ver.2.0.12）を指定してインストール
```
pecl install oci8-2.0.12
```
> oci8の最新版だとPHP7以降の為、2.0系を指定する

1. インストール中にプロンプトが出れば、
```
instantclient,/usr/lib/oracle/12.1/client64/lib
```
と入力

1. PHPの設定
`php.ini`に以下を設定
```
extension=oci8.so
```
（場所が判らない時は`php -i | grep php.ini`）

1. 設定の確認
```
php --ri oci8
```
を実行して、
```
（略）
OCI8 Support => enabled
（略）
OCI8 Version => 2.0.12
（略）
Oracle Run-time Client Library Version => 12.1.0.2.0
Oracle Compile-time Instant Client Version => 12.1
```
と出ていればOK

## PHPからの接続
Macの場合の[PHPからの接続](../oracle-mac/)を参照

# 参考リンク
- PHP公式 [Oracle OCI8](http://php.net/manual/ja/book.oci8.php)
- Pecl公式 [oci8](https://pecl.php.net/package/oci8)
- [Orcale Instant Client](http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html)
(下の方にインストール方法)

# 開発環境
- CentOS6.8
- PHP 5.6.27 + OCI8 2.0.12
- Oracle Instant Client 12.1.0.2.0
- DBサーバ OracleDB(Win)
