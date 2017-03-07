+++
categories = ["ios"]
tags = ["swift3"]
date = "2016-11-29T18:40:09+09:00"
draft = false
slug = "multipeer"
title = "MultipeerConnectivityでP2P通信"

+++

iOS同士限定になるが、`Multipeer Connectivity Framework`でお手軽にP2P通信をさせる方法

<!--more-->

今回は特に`MCBrowserViewController`を使わずに実装してみた

## 使い方
おおまかな流れは

1. `MCSession`で接続を開く  
  同時に`MCNearbyServiceAdvertiser`で他の端末からの接続を待機
1. `MCNearbyServiceBrowser`で待機している端末を探す  
  見つかれば、招待して接続を確立する
1. 招待された側が招待を受け入れれば接続が確立されるので、データをやりとりできる

となる

*なお、各種デリゲートはメインスレッドで呼び出されるとは限らないので、
UIを操作する場合は注意すること*

### 接続の開始
各端末は`Peer`（ピア）と呼ばれ、相手に表示させる表示名を設定できる。
自端末をあらわす`Peer`を生成したら、それを使って接続を開始する

```
let peerID = MCPeerID(displayName: "表示名")
session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
session.delegate = self
```

さらに他の端末から見える状態にする為に`MCNearbyServiceAdvertiser`を設定する。
サービス名は相手を検索するのに使用するIDの様なものなので、かぶらないものを指定する

```
advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "サービス名")
advertiser.delegate = self
advertiser.startAdvertisingPeer()
```

ここまでの手順でいわば接続の待ち受け状態となる

### 相手の検索と接続の確立
相手を検索するには、`MCNearbyServiceBrowser`を利用する。
サービス名には`Advertiser`で設定したのと同じものを指定する

```
browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "サービス名")
browser.delegate = self
browser.startBrowsingForPeers()
```

指定したサービス名と同じPeerが見つかると`MCNearbyServiceBrowserDelegate`の`foundPeer`が呼び出される

```
func browser(_ browser: MCNearbyServiceBrowser,
      foundPeer peerID: MCPeerID,
withDiscoveryInfo info: [String : String]?) {
    print("found: \(peerID)")
    browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
}
```

見つかった相手に、`invitePeer`で接続を招待することができる。
招待された側には、`MCNearbyServiceAdvertiserDelegate`の`didReceiveInvitationFromPeer`が呼び出される

```
func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
  didReceiveInvitationFromPeer peerID: MCPeerID,
                  withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    print("InvitationFrom: \(peerID)")
    invitationHandler(true, session)
}
```

`invitationHandler`の第一引数で`true`を渡すと招待を受け入れたことになり接続が確立される。

### データの送受信
接続が確立されればデータのやりとりが出来る様になる。
データのやりとりには

- `Data / NSData`
- `URL / NSURL`でのリソース
- `Stream / NSStream`でのストリーム

のどれかを使う

一番シンプルな`Data`の場合、

```
session.send(data, toPeers: session.connectedPeers, with: .reliable)
```

とすると、接続を確立しているPeer全てにデータを送信できる。
`.reliable`にするとデータの送信順が保証され、
`.unreliable`にすると送信順が保証されない代わりに即時にデータが送られる

送信されたデータは、`MCSessionDelegate`の各メソッドで受け取ることができる。
`Data`の場合だと、

```
func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
}
```

で受け取れる

# ソース
上記を元に2台の端末同士でP2Pで単純なテキストを送受信するクラスのソースは以下のとおり

{{< gist 00e0e04fd7bdf4c3e9378fc6d8e0a11a >}}

使い方は、

#### 接続の開始
```
P2PConnectivity.manager.start(
    serviceType: "MIKE-SIMPLE-P2P",
    displayName: UIDevice.current.name,
    stateChangeHandler: { state in
        // 接続状況の変化した時の処理
    }, recieveHandler: { data in
        // データを受信した時の処理
    }
)
```

#### データの送信
```
// 送信
P2PConnectivity.manager.send(message: "送信するテキスト")
```

#### 終了
```
P2PConnectivity.manager.stop()
```

という感じ

# 開発環境
- Xcode 8.1
- iOS 9.3.2 / 10.1.1
- iPhone 6+ / 7+
