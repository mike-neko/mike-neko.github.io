+++
categories = ["old"]
tags = ["metal", "gpgpu", "swift2"]
date = "2016-02-25T22:05:16+09:00"
draft = false
slug = "metal-sand"
title = "Metalによる砂のシミュレーションもどき"

+++

MetalのGPGPUによる大量のパーティクル処理能力を活かしたデモ。
パーティクルをそれぞれ砂の一粒に見立てており、上から落下してきた砂粒が山のように積みあがっていく様子をシュミレートしている。

なお、これも約26万パーティクルで60FPSを維持している。

## 動作イメージ
<!--more-->
<blockquote class="instagram-media" data-instgrm-version="6" style=" background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:658px; padding:0; width:99.375%; width:-webkit-calc(100% - 2px); width:calc(100% - 2px);"><div style="padding:8px;"> <div style=" background:#F8F8F8; line-height:0; margin-top:40px; padding:50.0% 0; text-align:center; width:100%;"> <div style=" background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAsCAMAAAApWqozAAAAGFBMVEUiIiI9PT0eHh4gIB4hIBkcHBwcHBwcHBydr+JQAAAACHRSTlMABA4YHyQsM5jtaMwAAADfSURBVDjL7ZVBEgMhCAQBAf//42xcNbpAqakcM0ftUmFAAIBE81IqBJdS3lS6zs3bIpB9WED3YYXFPmHRfT8sgyrCP1x8uEUxLMzNWElFOYCV6mHWWwMzdPEKHlhLw7NWJqkHc4uIZphavDzA2JPzUDsBZziNae2S6owH8xPmX8G7zzgKEOPUoYHvGz1TBCxMkd3kwNVbU0gKHkx+iZILf77IofhrY1nYFnB/lQPb79drWOyJVa/DAvg9B/rLB4cC+Nqgdz/TvBbBnr6GBReqn/nRmDgaQEej7WhonozjF+Y2I/fZou/qAAAAAElFTkSuQmCC); display:block; height:44px; margin:0 auto -44px; position:relative; top:-22px; width:44px;"></div></div><p style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; line-height:17px; margin-bottom:0; margin-top:8px; overflow:hidden; padding:8px 0 7px; text-align:center; text-overflow:ellipsis; white-space:nowrap;"><a href="https://www.instagram.com/p/BCX1ylEFQd_/" style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:normal; line-height:17px; text-decoration:none;" target="_blank">@m_ike__が投稿した動画</a> - <time style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;" datetime="2016-02-29T13:51:35+00:00">2016 2月 29 5:51午前 PST</time></p></div></blockquote> <script async defer src="//platform.instagram.com/en_US/embeds.js"></script>

（2色にして拡大してみたけど、動画だとイマイチになってしまった・・・）


## 小ネタ
### 砂の動き
タイトルに「もどき」とある通り、砂の動きは粒子法などのちゃんとした物理計算をしているわけではないが、GameGems本の中の地形生成の粒子堆積を参考にしている。

> #### フラクタル地形生成-粒子堆積
> {{< img "gems4-19-3.png" >}}
> 出典：Game Programming Gems

上図にあるように、

1. 粒子を地面（粒子）にぶつかるまで落下させる
2. ぶつかった地点の周囲で最も低い地点を探す  
見つからなければそこに粒子を固定（地面化）させて終了
3. 2で見つかった地点に粒子を移動させる
4. 1に戻って落下させ続ける

という動きをGPUで計算している。

### コンピュートシェーダのコード
{{< gist c6997165804cbaa25402 >}}

流れとしては、

1. CPU側で砂の初期位置とy軸への落下速度を設定
1. コンピュートシェーダで砂の動きを計算して描画用バッファへ書き出し
1. バーテックスシェーダとフラグメントシェーダはシンプルにパーティクルを描画

となる。

#### 地面との衝突判定

今回は地面との衝突の判定のみで、粒子間の衝突などは考慮しない。よって、512*512のバッファ`laminateBuffer`を地面に見立てて、各座標の高さを記録している。ここでテクスチャを使っていないのは、コンピュートシェーダではテクスチャの読み書きを同時に行うことができない為。

地面にぶつかったら、元の位置からそれぞれ30度+αずつずらした位置の地面の高さを見て、一番低いところを探す。なお、ここで手を抜いてsincosを使わなければ、四角い山ができてしまう・・・

一番低いところの判定を
```
min_id = mix((float)min_id, 1.f, not(step(h[1], h[min_id])));
```
としているが、これは
```
min_id = (h[1] <= h[min_id]) ? min_id : 1;
```
と同じである。(Metalの座標系のy軸は上が-になる)

現在位置が一番低い場所であれば、y軸の速度を0にして粒子を固定する。同時に地面の高さも更新し、次回参照時からはそこが地面の扱いとなる。

あとはこれをひたすら繰り返していくと山のように積み重なっていく。

## 感想
パラメータの調整とかバッファへの書き込みの精度を上げたりするなど、まだまだ改良の余地はありそう。。。

なんにしても単純な方法を力任せに処理してもちゃんと動くあたり、GPGPUは頼もしい。

あと、GameGemsの1以外も電子書籍で出ないかなぁ。内容的には古くても色々参考になるし、紙版は置く場所考えるとどうしても買いづらいので

# 開発環境
+ Xcode 7.2
+ iOS 9.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/MetalSand)(*iOS9 A7以降搭載機種のみ*)
