+++
categories = ["ios"]
tags = ["swift3", "webrtc"]
date = "2016-11-29T23:24:55+09:00"
draft = false
slug = "webrtc-build"
title = "WebRTCをiOSネイティブで使う(準備編)"

+++

iOSのブラウザでは`WebRTC`がサポートされていないので、利用したい場合は
ネイティブのフレームワークを使う必要がある。

今回の準備編では公式のフレームワークを使うにあたってフレームワークの生成と組み込みまでの手順について

<!--more-->

ただ、これが結構面倒で、ソースをダウンロードして一からビルドしないといけないし、
その方法が公式に明記されていないというおまけ付き

普段、GitHubやCarthageに頼りきっている身には大変だった・・・

## フレームワークの生成
まずは、作業用の適当なフォルダを作っておく
```
mkdir 作業用のフォルダ
cd 作業用のフォルダ
```

ビルド用のツールをインストールする
```
brew update
brew install git
brew install python
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
```

ソースをダウンロードする

***以下、ものすごく時間と容量をくうので注意！***

```
export PATH=`pwd`/depot_tools:"$PATH"
fetch --nohooks webrtc_ios
gclient sync
```

ビルドする
```
cd src
webrtc/build/ios/build_ios_libs.sh
```

成功すれば、`src/out_ios_libs/`の中に`WebRTC.framework`ができている

## 組み込み
組み込み自体は他のサードパーティのフレームワークと一緒だが、ポイントは

- `Embedded Binaries`で追加
- `Build Settings`で`Bitcode`を無効にする

というあたり

また、`Video`を使う場合はシミュレータが使えないので注意


# 参考リンク
- [WebRTC公式](https://webrtc.org/native-code/)


# 開発環境
- macOS 10.12
- Xcode 8.1
- iOS 9.3.2 / 10.1.1
- iPhone 6+ / 7+
