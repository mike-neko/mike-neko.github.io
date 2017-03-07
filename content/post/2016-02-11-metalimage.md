+++
categories = ["old"]
tags = ["metal", "gpgpu", "swift2"]
date = "2016-02-11T09:20:27+09:00"
draft = false
slug = "metal-image"
title = "MetalのGPGPUによるパーティクルデモ"

+++

読み込んだテクスチャをパーティクルに分解して動かすデモ。動きは滝のように画像がパーティクルに分解して落下していくのをイメージ。

画像サイズが512*512、1ピクセル=1パーティクルに分解するので、約26万個のパーティクルを動かしているが、60FPSを維持している。約100万まで増やすとiPhone6+で30FPSぐらいとなる。

そんなに複雑な計算をさせていないとはいえ、さすがGPGPUといったところ。なお、処理時間のほとんどはGPGPUの部分でCPUは余力がある様子。

## 動作イメージ
<!--more-->
<blockquote class="instagram-media" data-instgrm-version="6" style=" background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:658px; padding:0; width:99.375%; width:-webkit-calc(100% - 2px); width:calc(100% - 2px);"><div style="padding:8px;"> <div style=" background:#F8F8F8; line-height:0; margin-top:40px; padding:62.3366013072% 0; text-align:center; width:100%;"> <div style=" background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAsCAMAAAApWqozAAAAGFBMVEUiIiI9PT0eHh4gIB4hIBkcHBwcHBwcHBydr+JQAAAACHRSTlMABA4YHyQsM5jtaMwAAADfSURBVDjL7ZVBEgMhCAQBAf//42xcNbpAqakcM0ftUmFAAIBE81IqBJdS3lS6zs3bIpB9WED3YYXFPmHRfT8sgyrCP1x8uEUxLMzNWElFOYCV6mHWWwMzdPEKHlhLw7NWJqkHc4uIZphavDzA2JPzUDsBZziNae2S6owH8xPmX8G7zzgKEOPUoYHvGz1TBCxMkd3kwNVbU0gKHkx+iZILf77IofhrY1nYFnB/lQPb79drWOyJVa/DAvg9B/rLB4cC+Nqgdz/TvBbBnr6GBReqn/nRmDgaQEej7WhonozjF+Y2I/fZou/qAAAAAElFTkSuQmCC); display:block; height:44px; margin:0 auto -44px; position:relative; top:-22px; width:44px;"></div></div><p style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; line-height:17px; margin-bottom:0; margin-top:8px; overflow:hidden; padding:8px 0 7px; text-align:center; text-overflow:ellipsis; white-space:nowrap;"><a href="https://www.instagram.com/p/BBn2nSclQZi/" style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:normal; line-height:17px; text-decoration:none;" target="_blank">@m_ike__が投稿した動画</a> - <time style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;" datetime="2016-02-10T22:35:15+00:00">2016  2月 10 2:35午後 PST</time></p></div></blockquote>
<script async defer src="//platform.instagram.com/en_US/embeds.js"></script>

ちなみに実機で見るともっとキレイ

## 小ネタ
処理はおおまかにわけて、

- 事前処理として、テクスチャを読み込んで、ピクセル数分のバッファを確保
- テクスチャからパーティクルを生成
- 生成したパーティクルを動かす

となる。事前処理はCPU側で行い、以降はそれぞれ専用のシェーダを準備して、

1. 生成用シェーダ`fallImageSetup`をセットしてパーティクルを生成
2. 実行用シェーダ`fallImageCompute`へ切り替えてパーティクルを動かす
3. 動き終われば1へ戻る

といった流れでループする。

注意点として、画像の座標とMetalでの座標軸は違うので、x軸とy軸に−1のスケールをかけて補正している。テクスチャ読み込み時に何かできるかは未調査だが、そもそもこういうテクスチャの使い方は普通しないと思うのでそのまま。

### テクスチャからパーティクルを生成
#### パーティクルの位置の計算
```
// ImagePiece* particles [[ buffer(0) ]]
// uint2 id [[ thread_position_in_grid ]]
// uint2 size [[ threads_per_grid ]]
// uint index = id.x + id.y * size.x;
particles[index].position = float4(id.x / (float)size.x, id.y / (float)size.y, 0, 1);
```
イメージとしては1*1の板ポリの中にすべてのパーティクルを配置する感じで、各パーティクルのローカル座標が(0, 0)から(1, 1)の中に収まるようにする。

#### 画像の対応するピクセルの色を取得
```
// texture2d<float, access::read> image [[ texture(0) ]]
particles[index].color = image.read(id);
```
今回は1ピクセル=1パーティクル、スレッドも同じように分割しているので、テクスチャの対応するピクセルの座標は、そのままグリッド内のスレッド位置と同じになる。

#### 動きのパラメータの初期設定
```
// param.time.w : y方向のdelay
// rnd : 乱数
float rnd_d = param.time.w * (1 - (float)rnd / UINT_MAX * 0.1);  // 1

// param.delta : 各軸の1フレーム毎の移動量
particles[index].acc = float4(param.delta.x, param.delta.y, param.delta.z, rnd_d * id.y);  // 2
```
下の方から順にパーティクルが落ちるように、画像の上の方ほど遅れて落ち始めるようにで遅延を設定する(2の`rnd_d * id.y`部分)。また落ち方がそれっぽく見えるように、遅延時間は元の指定の100%〜90%の間でばらつくように乱数を使う(1の部分)。

### パーティクルに動きをつける
#### 位置の更新
```
// particles[index].acc.w : delay
// param.time.x : スタートからの経過時間
// param.time.y : 前フレームからの経過時間
float t = fmax(0.f, param.time.x - particles[index].acc.w) * param.time.y * rnd_d;
particles[index].position += t * particles[index].acc;
```
パーティクルの位置は、スムーズに見えるように`前回からの経過時間*時間あたりの移動量`で計算する。ただし、各パーティクルには遅延時間があるので、それを経過するまでは経過時間は0として動かないようにする(`fmax(0.f, param.time.x - particles[index].acc.w)`の部分)。さらに、こちらも乱数で落ち方にばらつきを与える。

#### 消滅処理
```
float4 f = step(param.delta.w, particles[index].position + t * particles[index].acc);
particles[index].color.a -= (1 - f.x * f.y * f.z) * 0.1 * rnd_d * 3;
```
一定距離落ちれば徐々に消滅したように見せる為に、まず`step()`で指定した距離を超えていないかチェックする。超えていれば、該当の要素が0になるのでαが減算されて消えたように見せかける（パーティクル自体は生きている）。ここも乱数で消え方にばらつきを与える。

ここでハマったのが、アルファブレンドをONにするのを忘れていて全然消えてくれなかったこと・・・  
デフォルトではフラグメントシェーダでどれだけαを変更しても無視されるので、`pipelineDescriptor.alphaToCoverageEnabled = true`でαの指定を有効にする。

ポイントとなるのは、フラグメントシェーダ内の`if (in.color.a < 0.1) discard_fragment();`という見えなくなったピクセルの破棄処理。なくてもパーティクルは消えてくれるが、この処理を行うことで若干フレームレートが改善するので入れた（~~単に使ってみたかっただけ~~）。

### 乱数の生成
Metalではシェーダ上で使える乱数の関数は準備されていない為、使いたい場合はシェーダ上で自前で実装するかCPU側で生成したものを渡して使うかになる。今回はCPU側でほとんど処理しないので、シェーダ上で実装する方を選択した。

乱数のアルゴリズムは幾つかあるし、このデモでの利用方法なら前回作ったようなノイズ関数を用いても良いが、ちょうど少し前に面白い記事(参考リンク参照)を見つけたので、`xorshift`を採用することにした。32bitにしたのは、もしCPU側とやりとりする場合（シードの初期値など）に、64bit以上の型は直接渡せない為。

{{< gist b1c006b69ccb57261f7d >}}

今回はシードの初期値に`2463534242`の値を直で指定している。もし本当にランダムにしたいならCPU側から現在のミリ秒あたりを渡して設定すればよい。

ポイントは、生成された乱数が次回のシードになるので、アドレス空間に`threadgroup`を指定していること。これにより同じスレッドグループ内のスレッドでこのシードが共有されるようになる。（指定しないと毎回初期値が設定されてしまう。）

しかし、GPGPUでは同時にスレッドが並列で幾つも実行される為、単にシードを共有するだけでは同じシードを複数のスレッドを使うことになり、結果が偏ったものになってしまう。そこで、シードを渡す時に`rotate(rnd, id.x)`として値をばらつかせている（フローの起きないrotateが標準で使えるのは、ほんと助かる）。

得られる結果は`uint`なので、実際のコード内では使いやすいよう`(float)rnd / UINT_MAX`として正規化してから使っている。


# 参考リンク
- 乱数のアルゴリズムの解説記事  
[Google Chromeが採用した、擬似乱数生成アルゴリズム「xorshift」の数理](https://blog.visvirial.com/articles/575)

# 開発環境
+ Xcode 7.2
+ iOS 9.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/MetalImage)(*iOS9 A7以降搭載機種のみ*)

