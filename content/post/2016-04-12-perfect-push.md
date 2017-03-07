+++
categories = ["old"]
tags = ["swift2", "apns"]
date = "2016-04-11T19:45:28+09:00"
draft = false
slug = "perfect-push"
title = "Perfect APNs編"

+++

サーバーサイドSwiftフレームワークの[Perfect](https://perfect.org/)の使い方のメモその3

今回はiOSのプッシュ通知を送信する方法について

Perfectは最新のAPNsの通信形式に対応していて、細かなエラーレスポンスを取れるのがメリット。
なので、開発用としては大変使いやすい

<!--more-->
## 手順
Push通知はサーバ側で微妙に必要とされる証明書が変わったりするのがややこしいところ。
PerfectでPush通知を送るのに必要なものは以下の通り

- サーバ
  - APNs用証明書と秘密鍵
  - CAルート証明書
- クライアント
  - プロビジョニングプロファイル

### 登録〜プロビジョニングプロファイルと証明書の作成
証明書の取得には`AppID`の登録やら結構手順があって大変だが、まずは以下のリンク先の通りに作業をすればOK

> Qiita:[プッシュ通知に必要な証明書の作り方2016](http://qiita.com/natsumo/items/d5cc1d0be427ca3af1cb)

なお、最後の手順の`APNs用証明書(.p12)`を書き出す時のファイル名は`apns.p12`とする

### サーバ用の証明書の準備
#### APNs用証明書(.pem)
ターミナルで以下を実行して`apns_dev_cert.pem`を作成する
```
cd [apns.p12を書き出した場所]
openssl pkcs12 -clcerts -nokeys -out apns_dev_cert.pem -in apns.p12
```

#### 秘密鍵(.pem)
ターミナルで以下を実行して`apns_dev_key.pem`を作成する
```
cd [apns.p12を書き出した場所]
openssl pkcs12 -nocerts -out apns_dev_key.pem -in apns.p12
```
`Enter PEM pass phrase:`と秘密鍵のパスフレーズを聞かれるので、適当なものを入れる。
後でサーバに設定するので忘れないように・・・

#### CAルート証明書
APNsとサーバで接続する為に`Entrust`の証明書が必要なので、以下からダウンロードする

Entrust.net Certificate Authority (2048)：
[entrust_2048_ca.cer](https://www.entrust.com/root-certificates/entrust_2048_ca.cer)  
（[Entrustの証明書DLページ](https://www.entrust.com/get-support/ssl-certificate-support/root-certificate-downloads/
) - Entrust.net Certificate Authority (2048) - Download）


### iOSアプリの作成
とりあえず、必要最低限でPush通知を受信できる状態にする。
デバイストークンの更新等には未対応なので注意

#### プロジェクトの設定
- ダウンロードしたプロビジョニングプロファイルをダブルクリックしてインストール
- `Bundle Identifier`を`AppID`取得時のものと一緒にする
- `Provisioning Profile`をインストールしたプロビジョニングプロファイルにする

#### アプリの実装
`AppDelegate`に以下の実装をする

- `didFinishLaunchingWithOptions`でPush通知の登録
- `didRegisterForRemoteNotificationsWithDeviceToken`でデバイストークンを受信

コードにすると以下の通り
{{< gist 8000f2d8dc5b37773323065e867e2e4d >}}

これを実機上で実行すると、端末のデバイストークンがログ出力される

***デバッグ実行を停止させると、Push通知が届かない場合があるので、デバッグ実行したままにするか
再度実機上からアクティブにしてバックグラウンドに落としておく。***

***また、マルチタスクから終了させても届かない場合があるので、注意***

### サーバへ証明書の設置
基礎編の[ビルドでファイルを配置する](../perfect-2/)の方法で証明書を配置する

- 対象のファイル
  - apns_dev_cert.pem
  - apns_dev_key.pem
  - entrust_2048_ca.cer
- `Copy Files`の設定
  - `Destination`:Products Directory
  - `Subpath`:空白

（`webroot`へのドキュメントの配置とは別に`Copy Files`を設定する）

### サーバの実装
サーバ側での実装は主に2つ。
ひとつは証明書を`NotificationPusher`に初期設定するのと、
もう一つは実際にPush通知を送る実装

初期設定は一度だけ行えばOKなので、（実環境では送信毎にチェックした方が良いけど）
今回は`PerfectServerModuleInit`で行う

Push通知の送信は、`IOSNotificationItem`の配列
（ここのenumの使い方は参考になる）で送信内容を作成し、
`NotificationPusher().pushIOS`で送信を行う

{{< gist 821b3dced86e0eb741563e23c43fed0f >}}

この実装でサーバにアクセスする度に、Push通知が端末へ送られる。
送信時の結果は、ブラウザに表示される（エラーであればエラー内容）

## 感想
今回の一番大変だったのはEntrustの証明書の置き場が変わっていたこと。。。
逆に言えばそれ以外はとても簡単にPush通知を送れる環境を作れた感じ

巷にはたくさんAPNsに対応したフレームワークやサービスがあるけど、
開発用としては、このPerfectが一番手軽で確実だと思う。
なにせ環境構築は不要で、Xcodeでプロジェクトを作って
少し実装すれば良いだけという素晴らしさ！

もちろん、商用はAWSとかがオススメだけど。。。


# 参考リンク
- [プッシュ通知に必要な証明書の作り方2016](http://qiita.com/natsumo/items/d5cc1d0be427ca3af1cb)
- Perfect 導入編[その1](../perfect-1/)
- Perfect 基礎編[その2](../perfect-2/)

# 開発環境
+ OS X 10.11.4
+ Xcode 7.3
+ iOS 9.3.2
+ iPhone 6+

