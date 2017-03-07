+++
categories = ["server"]
tags = ["php", "apns", "http2"]
date = "2016-10-29T22:40:57+09:00"
draft = false
slug = "guzzle-apns"
title = "Guzzle(PHP)でAPNsの同時配信を行う"

+++

`Guzzle`でiOSのAPNs(Push通知)をお手軽に同時配信する方法

<!--more-->

APNs自体については[APNs Provider API(http2)を利用する(Node.js)](../http2apns/)を参照

## 事前準備
`Guzzle`自体は[以前の記事](../guzzle/)を参照

### curlの更新
APNsを使うには`http2`が必要かつ非同期で実行したいので、`curl`をインストールし直す

`homebrew`を使っている場合は以下の感じ
```
brew install curl --with-nghttp2 --with-openssl
brew link curl --force
brew reinstall php56 --with-homebrew-curl
```

なお、自分で試した時は上記だけでは`http2`が有効にならなかったので、
アンイストールした方が確実かもしれない

更新後に
```
curl -V
```
として`http2`が出ていればOK

## Guzzleの使い方
### http2で通信する
オプションで指定するだけでOK
```
$client = new Client(['version' => 2.0]);
```

### POST送信
`body`はリクエスト時のオプションとして以下の感じで指定する
```
$client = new Client();
$response = $client->request('POST', $url, ['body' => $body]);
```

`body`の中身を`JSON`にしたい時は、
```
['body' => json_encode($json])]
```
という形にして渡す

### クライアント証明書をつける
これもオプションで指定するだけでOK

例えば同じ階層内に`apns_dev.pem`という証明書（パスフレーズ`0000`）に置いた場合は、
```
$client = new Client(['cert' => ['apns_dev.pem', '0000']]);
```

あえていうなら、`pem`形式の証明書を作るのがちょっと面倒

## APNsの同時配信
APNsは通知内容をJSONで指定することと、前回の並列リクエストを併せると、以下のコードで同時配信が実現できる

{{< gist dcc15bedbc4d42e4e8b1c31119f3c63a >}}

（※配信環境はSandBox向け）



# 開発環境
- PHP 5.6
- Guzzle 6.2.2
