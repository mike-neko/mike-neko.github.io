+++
categories = ["server"]
tags = ["php", "db"]
date = "2016-10-15T21:53:49+09:00"
draft = false
slug = "redis sakura"
title = "さくらのレンタルサーバでredisを使う"

+++

さくらのレンタルサーバ（スタンダード）に[redis](http://redis.io/)をインストールする方法のメモ

<!--more-->
`Laravel`のキューを使うついでに、せっかくなので`redis`を使えるようにしてみる。
`Laravel`をさくらで使うあたりは[以前の記事](../laravel-sakura/)を参照

## インストール
### ソースを展開
SSHでログインして公式の手順通り以下の様にする
```
% wget http://download.redis.io/releases/redis-3.2.0.tar.gz
% tar xzf redis-3.2.0.tar.gz
% cd redis-3.2.0
```

最新版(Ver.3.2.4)では、権限絡みで`make`に失敗する為、少し古いバージョンを使っているのがポイント

### インストール先の変更
`src/Makefile`を開く
（`redis-3.2.0`直下にも`Makefile`があるので間違わないこと）

`PREFIX?=`という行を以下の様に書き換えて保存する

```
PREFIX?=/home/アカウント名
```

### make
```
% gmake
% gmake install
```
さくらのサーバはBSD系なので`gmake`を使ってインストールを実行。
これで、`~/bin`に`redis`関連がインストールされる

もし、`~/bin`にパスが通っていなければ通しておくと便利

### 実行
一旦、SSHをログアウトしてログインしなおしてから
```
% nohup redis-server < /dev/null >& /dev/null &
```
として、`redis`サーバをバックグラウンド起動する

確認のため、
```
% redis-cli
```
として、
```
127.0.0.1:6379>
```
というようになればOK。失敗している時は`not connected>`となる

*この時に表示されているサーバのIPとポート番号を覚えておくこと*

確認が終了すれば、`exit`で抜ける（`shatdown`にするとサーバまで止まるのでNG）

## Laravelで使う
### パッケージの準備
`Laravel`で`redis`を使うには`predis/predis`が必要なので、`Composer`でインストールしておく

### 設定
`config/database.php`の中の`redis`を設定する
```
'redis' => [

  'cluster' => false,

  'default' => [
    'host'     => '127.0.0.1',      // redis-cliで確認したIP
    'port'     => 6379,             // redis-cliで確認したポート
    'database' => 0,
  ],
],
```

**なお`.env`を使う場合、`database`の部分は`intval(env('REDIS_DATABASE', 0))`というように明示的にintにしないとエラーになるので注意**

以上で、`Laravel`からも`redis`が使える様になる

## 環境
- Laravel 5.1
- さくらのレンタルサーバ（スタンダード）
  - PHP 5.6
  - redis 3.2.0
