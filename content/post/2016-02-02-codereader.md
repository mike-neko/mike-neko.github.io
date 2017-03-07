+++
categories = ["old"]
tags = ["swift2"]
date = "2016-06-15T22:52:40+09:00"
draft = false
slug = "code-reader"
title = "QRコードの読み取りサンプル(Swift) その1"

+++

iOS端末のカメラでQRコードを読み取り、認識されたコードを枠線で強調表示するサンプル。

<!--more-->

なお、QRコードに限らず、他のバーコードや顔認識にも対応。対応形式は[公式](https://developer.apple.com/library/prerelease/ios/documentation/AVFoundation/Reference/AVMetadataMachineReadableCodeObject_Class/index.html#//apple_ref/doc/constant_group/Machine_Readable_Object_Types)を参照。地味にiOS8から対応形式が増えている。

あと、2次元なら同時認識できたりするが、その辺りの詳細は参考リンクの公式FAQが詳しい。

コード認識自体はもっと詳しい説明がいろんなとこにあるので、ここは他で説明していなそうなところだけ。

## 小ネタ
### シリアルキューの利用
カメラの起動や画像認識は処理が重いので、それぞれ専用のシリアルキューを作成して利用している。

カメラの設定周りはフリーズ状態になるのを防ぐためだが、最近の端末は起動が早いらしく、キューを使わなくても特に問題無い感じ。

### AVMetadataMachineReadableCodeObject
認識されたコードは`AVMetadataMachineReadableCodeObject`のオブジェクトの配列で渡される。

- `type`：認識されたコードのフォーマットが逆DNS形式で返ってくる  
(QRの場合は`org.iso.QRCode`)
- `stringValue`：コードに含まれるデータ

### プレビュー画面上に認識したコードの枠を表示する
`AVMetadataMachineReadableCodeObject`の中の`corners`にコードの座標位置が含まれているが、これはプレビューのViewの座標系とは異なるので、そのままでは使えない。

`AVCaptureVideoPreviewLayer`の`transformedMetadataObjectForMetadataObject`で変換後の座標が入った`AVMetadataObject`が取得できるので、その中の`bounds`を使って枠線を描画している。

（以前は手動でちゃんとプレビュー画面上の座標に変換していたが、今回、この簡単に変換できるメソッドを発見！`AVCaptureVideoPreviewLayer`の方もちゃんと調べていれば・・・）

## 感想
昔iOS7で使えるようになった時に試したものを、Swiftで書き直し＋αしたコード。やはりSwiftはわかりやすく、かつエラー処理もしっかり書いても、Objective-Cよりコードが少ないので良い。

以前は結構カメラの起動もコードの読み取りも時間がかかっていたのだが、今回はかなりスピードアップした感じがした。iPhoneのカメラの進化もすごいということか。ただ、バッテリーには優しくないので常に使うのは厳しそう・・・

~~あと、カメラをわざわざ起動しなくても画像を直接認識してくれるようになって欲しい。~~
(6/17追記：方法が判ったので[その2](../qr-reader/)を作成した)

# 参考リンク
- 公式：[AV Foundation iOS Machine Readable Code Detection FAQ](https://developer.apple.com/library/prerelease/ios/technotes/tn2325/_index.html)


# 開発環境
+ Xcode 7.3
+ iOS 9.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/CodeReader/)

カメラ不要なバージョンは[こちら](../qr-reader/)
