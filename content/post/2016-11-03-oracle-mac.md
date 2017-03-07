+++
categories = ["mac", "server"]
tags = ["php", "db"]
date = "2016-11-03T19:24:51+09:00"
draft = false
slug = "oracle-mac"
title = "MacからOracleへ接続"

+++

MacのPHP5.6から別サーバで動いているOracleのDBへ`oci8`で接続する方法  
<!--more-->
CentOSの場合は[こちら](../oracle-cent/)

## 手順

### Oracleのドライバのインストール
今回は`Version 12.1.0.2 (64-bit)`は選択。手順などはこのバージョンが前提

1. [Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/index.html)から`basic`と`SDK`をダウンロード  
  *公式の[要件](http://php.net/manual/ja/oci8.requirements.php)にあるように`OracleDB`と`PHP`のバージョンに合ったものを選択*

1. 1を全て同じフォルダへ解凍する
```
cd （ダウンロード先）
unzip instantclient-basic-macos.x64-12.1.0.2.0.zip
unzip instantclient-sdk-macos.x64-12.1.0.2.0.zip
```
  (Ver.12であれば`instantclient_12_1`というフォルダ内に全ファイルが解凍された状態になればOK)  
  **フォルダ名がバージョンになっているので解凍したフォルダ名をそのまま使うこと！**

1. 2をフォルダごと適当な場所に移動  
（今回は`/Library/Oracle/`へ移動）

1. ライブラリのシンボリックリンクを作成  
```
cd /Library/Oracle/instantclient_12_1/
ln -s libclntsh.dylib.12.1 libclntsh.dylib
```

1. パスを通す  
`.bash_profile`に以下を追記
```
export DYLD_LIBRARY_PATH=/Library/Oracle/instantclient_12_1
export PATH=$PATH:$DYLD_LIBRARY_PATH
```
追記したら保存し、
```
source ~/.bash_profile
```
で強制反映させる

### OCI8をインストール
*以下はすでにPHPをインストール済かつ`PECL`が使えない場合なので、
通常はPHPインストールと同時にしてしまうか`PECL`で追加が恐らく楽*  
（手持ちの環境では`PECL`がなぜか使えなかったので以下の手順）

1. OCI8（Ver.2.0.12）を`PECL`の[該当ページ](https://pecl.php.net/package/oci8)からダウンロード

1. 解凍する
```
cd （ダウンロード先）
tar -zxf oci8-2.0.12.tgz
```

1. makeする
```
cd oci8-2.0.12
phpize
./configure -with-oci8=shared,instantclient,/Library/Oracle/instantclient_12_1
make install
```
`modules`の中に`oci8.so`ができていればOK

1. ライブラリを移動
```
sudo mv modules/oci8.so /Library/Oracle 
```
（とりあえず今回はここで）

1. PHPの設定
`php.ini`に以下の2つの項目を設定
```
extension_dir = "/Library/Oracle" # oci8.soを置いた場所
extension=oci8.so
```
（ファイルの場所が判らない時は`php -i | grep php.ini`）

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
フレームワークなどを使わずにそのまま接続する場合は、
```
$user = 'test';             // ユーザ名
$pass = '1234';             // パスワード
$host = '192.168.0.10';     // ホスト
$port = '1521';             // ポート番号
$db = 'sample';             // データベース名（サービス名）

$conn = oci_connect(
  $user,
  $pass,
  '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)'
  . '(HOST=' . $host . ')(PORT=' . $port . ')))' 
  . '(CONNECT_DATA=(SERVICE_NAME=' . $db . ')))']
);
```
といった感じで接続できる

## PHPStormの設定
`PHPStorm`から接続したい場合は、`Oracle Instant Client`はVer.12以上が必要

設定は以下の感じ

{{< img "phpstorm.png" >}}

# トラブルシューティング
`php --ri oci8`で表示されるのに`Apache`上でうまく動かない場合

`Apache`上で`phpinfo()`を表示させて`oci8`が同じ様に表示されるかを確認

表示されていないければ`Apache Environment`を確認して5で設定した環境変数が入っているか確認

詳細は未検証だが、主にmacのデフォルトの`Apache`を使っている場合に起こる場合があるので、
その場合は、[ここ](https://gist.github.com/srayhunter/5208619)を参照して設定してみる  
（デフォルトの`Apache`のユーザとシェルのユーザが違うので`bash_profile`などでは`Apache`の環境変数を変更できないっぽい）


# 参考リンク
- PHP公式 [Oracle OCI8](http://php.net/manual/ja/book.oci8.php)
- [Orcale Instant Client](http://www.oracle.com/technetwork/topics/intel-macsoft-096467.html)
(下の方にインストール方法)

# 開発環境
- Mac 10.11
- PHP 5.6.27 + OCI8 2.0.12
- Oracle Instant Client 12.1.0.2.0
- DBサーバ OracleDB(Win)
