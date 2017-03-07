+++
categories = ["server"]
tags = ["centos"]
date = "2016-11-08T21:32:51+09:00"
draft = false
slug = "vagrant-cent"
title = "VagrantでCentOS6.8を使う"

+++

野良BOXはちょっと怖いので公式BOXを利用しようとしたら、いろいろと落とし穴があったのでメモ

<!--more-->

## 手順
1. `Vagrantfile`を作成
```
mkdir -p （適当なフォルダ）
cd （上で作ったフォルダ）
vagrant init bento/centos-6.8
```

1. `Vagrantfile`を編集(サーバとして使いたいので以下のように編集)  
```
# config.vm.network "forwarded_port", guest: 80, host: 8080
# ↓コメントを外す＋ポートは空いているものを指定
config.vm.network "forwarded_port", guest: 8010, host: 8010
```
```
# config.vm.network "private_network", ip: "192.168.33.10"
# ↓コメントを外す＋IPは空いているものを指定
config.vm.network "private_network", ip: "192.168.33.10"
```
```
# Centos6.8限定で以下も追記(※1 詳細は後述)
config.vm.provider "virtualbox" do |vb|
vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
end
```

1. 起動する  
```
vagrant up
vagrant ssh
```

## トラブルシューティング
### vagrant up で private key で先に進まずエラーになる
エラーは以下の感じでCentOS6.8で発生(6.7は問題無し)
```
Timed out while waiting for the machine to boot. This means that
Vagrant was unable to communicate with the guest machine within
the configured ("config.vm.boot_timeout" value) time period.

If you look above, you should be able to see the error(s) that
Vagrant had when attempting to connect to the machine. These errors
are usually good hints as to what may be wrong.

If you're using a custom box, make sure that networking is properly
working and you're able to connect to the machine. It is a common
problem that networking isn't setup properly in these boxes.
Verify that authentication configurations are also setup properly,
as well.

If the box appears to be booting properly, you may want to increase
the timeout ("config.vm.boot_timeout") value.
```

#### 対応策
ググると色々出てくるが、CentOS6.8で発生する場合は、前述の※1を`Vagrantfile`に追記しておけば大丈夫。  
（というか他の方法は効果なしだった・・・）

### ファイルの共有ができない
`vagrant up`で以下のエラーが出ている
```
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:
```

#### 対応策
1. まずはエラーを一旦無視してログインし、カーネルをアップデート
```
vagrant ssh
su                     # pass:"vagrant"
yum -y update kernel
```

1. アップデートが完了すれば`exit`を2回でログアウトする

1. `Guest Additions`をインストール
```
vagrant plugin install vagrant-vbguest
vagrant vbguest
```

1. リロードをかけてエラーが出なければOK
```
vagrant reload
```

# 環境
- Mac 10.11
- VirtualBox 5.0.28
- Vagrant 1.8.6
  - CentOS6.7
  - CentOS6.8
