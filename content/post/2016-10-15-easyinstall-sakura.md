+++
categories = ["server"]
tags = []
date = "2016-10-15T02:03:14+09:00"
draft = false
slug = "easyinstall-sakura"
title = "さくらのレンタルサーバでeasy_installを使う"

+++

さくらのレンタルサーバ（スタンダード）でいつのまにか
[easy_install](http://setuptools.readthedocs.io/en/latest/easy_install.html)
が使えるようになっていたので使い方のメモ

<!--more-->
レンタルサーバなので、当然そのまま実行すると`[Errno 13] Permission denied`で怒られるのでその対策

## 準備
### インストール先の変更
1. (無ければ)`~/.pydistutils.cfg`を作成
1. ファイルの中に以下を追記  

```
[install]
user=1
```

### パスの追加
ついでにパスを通しておく。
`csh`の場合は、`~/.cshrc`の中の`set path`の行に` $HOME/.local/bin`を追加する

## 使い方
インストール時はそのまま実行すればOK

例えば、
```
% easy_install pip
```
とすれば、`~/.local/bin`に`pip`がインストールされる

実行したい時は、パスが通っているので`pip`とだけで実行できる

なお、インストールしたのに、`Command not found.`と出る場合は、
SSHにログインしなおすと良い