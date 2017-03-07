+++
categories = ["old"]
tags = ["swift2"]
date = "2016-06-23T00:13:25+09:00"
draft = false
slug = "webview-pdf"
title = "WKWebViewの内容をPDFで保存する(Swift)"

+++

昔に`UIWebView`でやっていたものを最新の`WKWebView`+`Swift`で書き換えた時のメモ。

内容は大したことないのだけれど、検索で引っかかるWebの資料がiOS9の実機で動かなかったので残しておく。

<!--more-->

## 小ネタ
### 内容全体の取得
今回は`WebView`の中身全体をPDF化したいので、PDF化する時に表示中のコンテンツがビュー内に収まるように、
コンテンツの表示位置（`scrollView.contentOffset`）を初期位置に戻し、
ビュー自体のサイズも表示ページのサイズ（`scrollView.contentSize`）に拡大している。

また、以下のようにPDFのページのサイズもコンテンツと同じサイズに設定している。
```
// frameの中身はコンテンツのサイズ
UIGraphicsBeginPDFPageWithInfo(frame, nil)
```

（つまり、書き出し時には一瞬画面がちらついてしまうので、気になる場合は
`ViewController`の`view`にマスクとなるビューを`addSubView`して隠すこと）

**ただし、あまりにコンテンツが長い場合は、うまく描画されないので注意！**  
（例えば、Google検索結果とかだと半分ぐらいから下は空白状態になったり、全く空白になったりする）

なお、端末によっても状況が異なるようで、対処方法は未調査。。。

### PDFへの書き出し
今回は、
```
webView.scrollView.drawViewHierarchyInRect(frame, afterScreenUpdates: true)
```
としてWebView内のコンテンツをPDFに書き出ししている。

ちまたにある資料では、この部分が、
```
webView.scrollView.layer.renderInContext(context)
```
のようになっているのが多いが、iOS9の実機では、
`CGImageCreateWithImageProvider: invalid image provider: NULL`
のエラーが出て書き出しが出来なくなっている。（他のOSは未検証）

なお、`drawViewHierarchyInRect`の方が速いらしいが、個人的には、
わざわざコンテキストの取得がいらなくなったのがありがたい。
（よく書く場所を間違えて取得に失敗する凡ミスをしていたので）

### PDFのファイル保存
PDFをファイルとして保存したい場合は、`UIGraphicsBeginPDFContextToFile`を利用するが、
このメソッドは既存のファイルを問答無用で上書きするので注意すること。

もし、サーバへ送信などでデータが欲しい場合は、`UIGraphicsBeginPDFContextToData`を利用すれば、
`NSData`で取得できる。

# 開発環境
+ OS X 10.11.5
+ Xcode 7.3.1
+ iOS 9.3.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/WebView2PDF)
