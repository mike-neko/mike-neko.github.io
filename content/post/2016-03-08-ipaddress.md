+++
categories = ["old"]
tags = ["swift2", "swift3"]
date = "2016-03-07T23:59:45+09:00"
draft = false
slug = "ipaddress"
title = "IPアドレス取得のサンプル(Swift)"

+++

***以下はSwift2の情報で古い為、注意！***  
***Swift3版のソースは[こちら](https://github.com/mike-neko/NetworkInfo)***  
***(解説はそのうちに・・・・)***


iOS端末のIPアドレスを取得するサンプル。Cの関数呼び出し周りも含めてSwiftにて実装。

一応、Apple公式の方法でIPv6only環境でも動作確認済。

<!--more-->

### 実装概要
アドレス取得の実装は`NetworkInfo`にまとまっている。
実装の中身自体はよくあるIPアドレスの取得のコード。

サンプルでは、IPアドレスの一覧を取得して`TableView`に表示している。

細かい点は実際のソースを参照のこと。

## 小ネタ
### Cの関数呼び出し
端末内部のネットワーク情報を取得する為に、`getifaddrs`や`inet_ntop`などの関数を呼び出すが、
通常のCであればファイルの頭で
```
#include <ifaddrs.h>
#include <sys/socket.h>
#include <netinet/in.h>
```
とするが、Swiftなので`Bridging-Header.h`を用意して、そこに`include`を書く。

あと、ヘッダを追加した後にはビルド設定の`Objective-C Bridging Header`も忘れずに変更。

### デバイス
とりあえず今回は、IPアドレスを取りたいだけなので、WiFi(`en0`)とCellular(`pdp_ip0`)の
デバイスのみチェックしている。

### Swiftの言語的なこと
`defer`がとっても便利。これのおかげでリソースの解放のような後始末が必要なコードが、
とても簡単にかけるし処理漏れもなくなるので素晴らしい！  
(これが無いと今回のように処理の中でエラーで返すような場合はコードが面倒になる)

ポインタが見えなくなったり、型が厳格になってC系のソースの移植が面倒に思えるけど、

- 対応する型への変換（特に`UnsafePointer`）
- C++の`->`に相当するのが`memory`
- 同じく`[]`に相当するのが`advancedBy`(今回は出てこないけど)


と言ったあたりを押さえておけばOKな気がする。

確かに冗長な感じは否めないが、型は書かなくても済むことが多いし、
逆に一度正しく変換しておけば後はコンパイラで型チェックが行われるのは安心できる。

この辺りのバランス感覚がSwiftは絶妙だと思う。

# 参考リンク
- 公式：[IPv6only環境の確認方法](https://developer.apple.com/library/prerelease/ios/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/UnderstandingandPreparingfortheIPv6Transition/UnderstandingandPreparingfortheIPv6Transition.html)
- 公式：[CのAPIをSwiftで使う方法](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html)

# 開発環境
+ Xcode 7.2
+ iOS 9.2
+ iPhone 6+
+ Mac OS 10.11.3(NAT64ネットワーク)

# ソース
[こちら](https://github.com/mike-neko/NetworkInfo/releases/tag/swift2)
