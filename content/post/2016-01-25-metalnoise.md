+++
categories = ["old"]
tags = ["metal", "gpgpu", "swift2"]
date = "2016-01-25T19:41:59+09:00"
draft = false
slug = "metal-noise"
title = "MetalのGPGPUによるPerlinノイズ"

+++

GPGPUでリアルタイムにパーリンノイズを生成しテクスチャに書き込んで表示するデモ。

パーリンノイズはGPU Gems2の改良パーリンノイズで、それを元にした数種類を選択可能。
デモでは3次元ノイズを生成し、z値だけを時間で加算していきノイズを変化させている。

## 動作イメージ
<!--more-->
<blockquote class="instagram-media" data-instgrm-captioned data-instgrm-version="6" style=" background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:658px; padding:0; width:99.375%; width:-webkit-calc(100% - 2px); width:calc(100% - 2px);"><div style="padding:8px;"> <div style=" background:#F8F8F8; line-height:0; margin-top:40px; padding:50.0% 0; text-align:center; width:100%;"> <div style=" background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAsCAMAAAApWqozAAAAGFBMVEUiIiI9PT0eHh4gIB4hIBkcHBwcHBwcHBydr+JQAAAACHRSTlMABA4YHyQsM5jtaMwAAADfSURBVDjL7ZVBEgMhCAQBAf//42xcNbpAqakcM0ftUmFAAIBE81IqBJdS3lS6zs3bIpB9WED3YYXFPmHRfT8sgyrCP1x8uEUxLMzNWElFOYCV6mHWWwMzdPEKHlhLw7NWJqkHc4uIZphavDzA2JPzUDsBZziNae2S6owH8xPmX8G7zzgKEOPUoYHvGz1TBCxMkd3kwNVbU0gKHkx+iZILf77IofhrY1nYFnB/lQPb79drWOyJVa/DAvg9B/rLB4cC+Nqgdz/TvBbBnr6GBReqn/nRmDgaQEej7WhonozjF+Y2I/fZou/qAAAAAElFTkSuQmCC); display:block; height:44px; margin:0 auto -44px; position:relative; top:-22px; width:44px;"></div></div> <p style=" margin:8px 0 0 0; padding:0 4px;"> <a href="https://www.instagram.com/p/BBATaXDFQW1/" style=" color:#000; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:normal; line-height:17px; text-decoration:none; word-wrap:break-word;" target="_blank">ノイズ生成デモ</a></p> <p style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; line-height:17px; margin-bottom:0; margin-top:8px; overflow:hidden; padding:8px 0 7px; text-align:center; text-overflow:ellipsis; white-space:nowrap;">@m_ike__が投稿した動画 - <time style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;" datetime="2016-01-26T13:57:16+00:00">2016 1月 26 5:57午前 PST</time></p></div></blockquote> <script async defer src="//platform.instagram.com/en_US/embeds.js"></script>

  
	
## 小ネタ
ソース自体はGPUGemsのサンプルをほぼほぼ書き換えただけなので、ノイズ生成のアルゴリズムなどは参考リンクの方で。。。

### ノイズ生成の流れ
1. 初期化時に順列テーブル`permBuffer`を生成  
初回のみなのでCPU側で生成  
実行時毎にノイズの模様が変化する様にランダムに並び替えを行う

2. 毎フレームごと、ComputeShaderでノイズを生成  
シェーダは各種パラメータ`NoiseParameter`や順列テーブルなどを受け取って、生成した結果をテクスチャに書き込んで返却する

3. 2のテクスチャを板ポリに貼って描画する

### ComputeShader用の設定

#### MTKViewの設定
ComputeShaderを利用する場合は、`MTKView`の`framebufferOnly`を`false`にしておくこと。  
ただし、パフォーマンスに影響を与えるので、利用しない時は触らないこと。

#### waitUntilCompleted()
各種コマンドの実行の終了するまで待機するメソッド。  
以下のように`commandBuffer.commit()`より後に置く。  
描画時のような毎フレームごとの呼び出しの時は、別途 `dispatch_semaphore_wait`で処理を待機するので不要だが、
初期化時の1回のみ実行するような場合は、これを使って待機させる。

>
```
/* ~~ （ここでGPGPUのコマンド処理） ~~ */
commandBuffer.commit()
commandBuffer.waitUntilCompleted()
```

### スレッド
GPGPUは大量のスレッドを並列動作させて圧倒的な処理を行うのが特徴だが、モバイルのGPUのため、スレッドグループ毎の最大のスレッド数は512までになっている([公式](https://developer.apple.com/library/ios/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/MetalFeatureSetTables/MetalFeatureSetTables.html))。

なお、スレッド数は32の倍数にするのが良い。nVIDIAの資料(URL忘れた…)によると64−192ぐらいが一番パフォーマンス的に良いらしいがA系チップに当てはまるかは不明。

今回は以下のように、スレッドグループは1つのみだが、グループのサイズをテクスチャのサイズと同じにしている。

>
```
// スレッドグループの事前設定
threadgroupSize = MTLSize(width: TexSize, height: TexSize, depth: 1)
threadgroupCount = MTLSize(width: 1, height: 1, depth: 1)

// コマンドバッファへスレッドグループの設定
computeEncoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadgroupCount)
```

ここでの注意ポイントは、スレッドの***次元***に合わせてシェーダ側の引数も変更が必要なこと。
今回はサイズが2次元(width * height * 1)なので、シェーダ側は`uint2 id [[ thread_position_in_grid ]]`と、
`uint2`で受け取ることになる(間違えるとシェーダのコンパイルが通らない親切?仕様)。1次元なら`uint`で受け取れば良い。

また、グループが複数だったり1次元のバッファで2次元のグループサイズを指定している様な場合は、`threads_per_grid`や`thread_position_in_threadgroup`を追加で受け取る必要がある。詳細は公式の[Attribute Qualifiers for Kernel Function Input](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalShadingLanguageGuide/func-var-qual/func-var-qual.html)の項目を参照。

同じスレッドグループ内であれば、メモリの共有ができたりするのだが、そのあたりも公式のサンプル[Metal N-Body](https://developer.apple.com/library/ios/samplecode/Metal_NBody_Simulation/Introduction/Intro.html)が参考になる。

### デバッグ
Xcodeの`Capture GPU Frame`がとても便利。

これを使うと、実行中の各バッファやテクスチャのイメージの様子をキャプチャしてくれる。
バッファのバイナリも見れるので、例えば構造体のアライメントが崩れたりしているのを簡単に見つけることができる。

また、プロファイル機能も充実していてどこがボトルネックがわかりやすい。


## 感想
Metalの発表を聞いて一番ワクワクして触りたかったのが、このGPGPUだった。これまでMacでは統合開発環境でGPGPUが組めなかった（普通のシェーダだけならUnityがあった）ので、使い慣れたXcodeで触れるのは楽しみだった。

元々ソース自体はGemsのものや参考リンクのものがあったので、移植しただけ。実際にはパラメータやノイズの加工を工夫すれば、雲になったり地形になったりしていくが、パラメータの調整はどうも苦手というか時間がものすごくかかるので、とりあえず今回はここまでで。

並列化によってどれくらい高速化するのかとか、モバイルのGPGPUでどのくらいパフォーマンスが上がるのか（もちろんバッファの転送が無いだけでも効果は大きいだろうけど）とかが気になったのだけど、それもまた別の機会に・・・

にしても、シェーダ関係は環境毎に用語が微妙に変わるのは何とかしてほしい。。。  

# 参考リンク
- 日本語の解説：[パーリンノイズを理解する(POSTD)](http://postd.cc/understanding-perlin-noise/)
- 本家：[Ken Perlin's homepage](http://mrl.nyu.edu/~perlin/)
- GPUGems Chapter5：[Implementing Improved Perlin Noise](http://http.developer.nvidia.com/GPUGems/gpugems_ch05.html)
- GPUGems2 Chapter26：[Implementing Improved Perlin Noise](http://http.developer.nvidia.com/GPUGems2/gpugems2_chapter26.html)
- FragmentShaderで実装や応用例：[Perlin Noise on GPU](http://www.sci.utah.edu/~leenak/IndStudy_reportfall/Perlin%20Noise%20on%20GPU.html)

# 開発環境
+ Xcode 7.2
+ iOS 9.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/MetalCompute) (*iOS9 A7以降搭載機種のみ*)

