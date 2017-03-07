+++
categories = ["server"]
tags = ["docker"]
date = "2016-04-02T14:00:57+09:00"
draft = false
slug = "docker-cmd"
title = "Dockerのコマンド備忘録"

+++

## Dockerでよく使うコマンド
<!--more-->

### イメージ操作
#### イメージのリスト表示
```
docker images
```

#### 指定したイメージの削除
```
docker rmi [イメージの名前かID]
```
イメージの指定は`IMAGE ID`の先頭数文字での特定が便利

#### イメージの全削除
```
docker rmi $(docker images -a -q)
```

### コンテナ操作
#### コンテナのリスト表示
```
docker ps
```

#### 全部停止
```
docker stop $(docker ps -a -q)
```

#### 全部削除
```
docker rm $(docker ps -a -q) 
```

### DockerCompose
#### 起動
```
cd [docker-copose.ymlを置いてる場所]
docker-compose up -d
```
これだけで`build`と`pull`と`run`を一気にしてくれる

#### 停止
```
docker-compose stop
```

### nginx
*80ポートを使う場合はsudoが必要*
#### 起動
```
nginx
```
#### 停止
```
nginx -s stop
```
#### 再起動
```
nginx -s reload
```

## PHP
### オプション
#### docker-php-ext-installで指定できるもの
```
bcmath bz2 calendar ctype curl dba dom enchant exif fileinfo filter ftp gd gettext gmp hash iconv imap interbase intl json ldap mbstring mcrypt mssql mysql mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline recode reflection session shmop simplexml snmp soap sockets spl standard sybase_ct sysvmsg sysvsem sysvshm tidy tokenizer wddx xml xmlreader xmlrpc xmlwriter xsl zip
```
(デフォルトのPHPイメージは最低限の状態なのでDockerfileで指定して追加する)


