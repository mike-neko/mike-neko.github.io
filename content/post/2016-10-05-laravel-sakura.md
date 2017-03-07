+++
categories = ["server"]
tags = ["php", "db"]
date = "2016-10-06T00:27:56+09:00"
draft = false
slug = "laravel-sakura"
title = "Laravelをさくらのレンタルサーバへデプロイ"

+++

ローカルで開発した`Laravel5`のプロジェクトをさくらのレンタルサーバ（スタンダード）で公開する時のメモ

<!--more-->
## 環境
- macOS 10.12.0
- Laravel 5.1
- さくらのレンタルサーバ（スタンダード）
  - PHP 5.6
  - MySQL 5.5

ちなみにローカルでは`PhpStorm`で開発している

## 手順
`www.アカウント名.sakura.ne.jp/hoge`とアクセスすると表示させる前提の手順  
（アカウント名は○○○○.sakura.ne.jpの○○○○部分）

流れとしては、

1. Gitの`export`でアップするファイルを準備
1. FTPで1をアップロード
1. `composer`をインストール
1. プロジェクトの設定
1. 公開


今回はGitのリモートサーバは外部に公開していない為、1〜2の手順が必要。
GitHubとかで管理しているならcloneしてくればOK


### ファイルの準備
#### （任意）除外ファイルの設定
*※普段はGit管理しているがサーバへアップしたくないファイルがある場合のみ*

今回は`PhpStorm`のプロジェクトファイルをアップロード対象外としたい
=エクスポートさせたくないので、`.gitattributes`に設定を追加する


1. プロジェクトのルートフォルダの`.gitattributes`を開く  
  （無い場合は作成）
1. 除外対象を`.idea/ export-ignore`として追記する  
  （.ideaフォルダ以下をエクスポート時に除外する設定）  

#### エクスポート
ターミナルでエクスポートする。エクスポート先はプロジェクトのフォルダと同じ階層にしている

```
cd （プロジェクトのルート）
mkdir ../export
git archive master --worktree-attributes | tar -x -C ../export
```
（回線によってはここで圧縮しておき、サーバ上で展開した方が良いかも）

### サーバへアップロード
FTPソフトで一つ前の手順でエクスポートしたフォルダの中身を丸ごとアップロードする  
アップロード先は`/home/アカウント名/laravel`とする  
*`www`以下にはアップロードしないこと！*

### composerをインストール
- SSHでログインする  
  ターミナルで  
  ```
  ssh アカウント名@アカウント名.sakura.ne.jp
  ``` 
  鍵認証をしていなければ、パスワードを聞かれるので入力する

- `bin`ディレクトリを作成し、そこへ`composer`をインストールする  
  ```
  % mkdir bin
  % curl -sS https://getcomposer.org/installer | php -- --install-dir=bin --filename=composer
  % chmod 755 bin/composer
  ``` 
- 一旦ログアウトしてログインする  
  ```
  % exit
  ssh アカウント名@アカウント名.sakura.ne.jp
  ```
- `Laravel`プロジェクトにパッケージをインストールする  
  ```
  % cd laravel
  % composer install
  ```

### プロジェクトの設定
#### DBの準備
- サーバのコントロールパネルへログイン
- `データベースの設定`を開き、DBサーバとユーザ名を確認
- `データベースの新規作成`からプロジェクト用のデータベースを作成

#### Laravelへ設定
- `.env`ファイルを設定する  
  `DB_〜`の各項目はコントロールパネルで確認・設定したものを記述しておく

{{< gist 7ae29213feac486174f86ebe8e8c534c >}}

- `.env`ファイルの`APP_KEY`を生成  
  （ターミナルの状態は前回の続き）
  ```
  % php artisan key:generate  
  ```

- DBのマイグレーションを実施
  ```
  % php artisan migrate  
  ```

### 公開
#### 公開用フォルダの設定
さくらのレンタルサーバは`DocumentRoot`を変更できないので、
```
% ln -s ~/laravel/public ~/www/hoge
```
として`Laravel`の`public`へのシンボリックリンクを`www`の中へ置く

これで`www.アカウント名.sakura.ne.jp/hoge`へのアクセスで、
プロジェクトの公開用フォルダ`public`へアクセスできるようになる  
（ただしまだこの段階ではエラー）

#### .htaccessの編集
さくらのレンタルサーバは`.htaccess`で`Options`を使えないので、
`laravel/public`の中の`.htaccess`を開き、
```
<IfModule mod_negotiation.c>
  Options -MultiViews
</IfModule>
```
の部分を削除する

これで無事公開が完了！

## 参考
サーバ上のファイル構成は以下の感じ
```
/home/アカウント名
  ├─ laravel
  |    ├─ .env
  |    ├─ public
  |    |  ├─ .htaccess
  |    |  └─ ...
  |    └─ ...
  ├─ www
  |    ├─ hoge          # シンボリックリンク
  |    └─ ...
  └─ ...
```

# 参考リンク
- [Laravel5をさくらのレンタルサーバで動かす](http://c-rtx.com/2015/09/22/laravel-on-sakura-rental-server/)