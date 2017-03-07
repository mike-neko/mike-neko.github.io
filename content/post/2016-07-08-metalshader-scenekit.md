+++
categories = ["old"]
tags = ["metal", "swift2"]
date = "2016-07-10T18:28:58+09:00"
draft = false
slug = "metalshader-scenekit"
title = "SceneKitでMetalのシェーダを利用する(SCNProgram)"

+++

`Metal`を使いたい場合にネックとなるのが、シーンの構築とかモデル・テクスチャの管理。
なので、その面倒な部分を`SceneKit`に任せたいという時の話。

今回は描画周りに`Metal`のシェーダを使うパターン。

<!--more-->

主に`SceneKit`でカスタムシェーダを使いたい場合は、

- `SCNProgram`
- `SCNShadable`
- `SCNTechnique`

といった辺りがあるみたい。

`SCNTechnique`はマルチパスのレンダリングに使うのがメインっぽい。
~~（これも試したけどシェーダへカスタム変数を渡す辺りでつまずいて放置）~~

`SCNShadable`は`Metal`での使えそうなサンプルがなかったので断念。

という訳で、WWDCのセッションの資料にあった`SCNProgram`を使って実装。


## 下準備
プロジェクトはXcodeのデフォルトのテンプレートの`Game`を流用している。
作成時の`Game Technology`では`SceneKit`を選択する。

### SceneKitの設定

- `Main.storeyboard`を開き、`Game View Controller`の`SceneKit View`の
`Rendering API`を`Metal`にする

- `GameViewController`の`viewDidLoad`の中のライト周りのコードを削除  
（今回のシェーダはライトを使わないもので不必要なので消す）

### SCNProgramの作成
以下のようにして`SCNProgram`を生成してシェーダの関数名を設定する
```
let program = SCNProgram()
program.vertexFunctionName = "textureVertex"
program.fragmentFunctionName = "textureFragment"
```

生成した`SCNProgram`を適用させたいマテリアルに設定する
```
let material = ship.childNodes.first?.geometry?.firstMaterial!
material.program = program
```

### シェーダの準備
通常どおり`Metal`のファイルを追加した後に、
```
#include <SceneKit/scn_metal>
```
とする。
これは後述の`SceneKit`とデータのやりとりに必要。


## データの渡し方
`SceneKit`から描画に必要なデータ（座標や変換行列、テクスチャなど）を
シェーダへ渡す方法

### VertexShader側

#### 頂点属性（位置とか法線とかuv座標とか）

まずは、
```
struct VertexInput {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float2 texcoord [[ attribute(SCNVertexSemanticTexcoord0) ]];
};
```
という感じで、頂点属性の中で必要なものを構造体で定義する。
すると、変数名の後ろの`Attribute Qualifier`("[[]]"で囲まれた部分)で指定したものが
`[[stage_in]]`にバインドされて自動で渡されてくる。

> 指定できるものはドキュメントの`Table 1 
SceneKit Vertex Attribute Qualifiers for Metal Shaders`を参照


#### フレーム定数（ビューの変換行列など）

あらかじめ`SCNSceneBuffer`という構造体が用意されており、これらはその中に入っている。
このデータは`[[buffer(0)]]`にバインドされて渡されてくる。

> 構造体の定義はドキュメントの`Frame-Constant Data`の項目を参照


#### ノード毎のデータ（モデルの変換行列など）

これは、あらかじめ用意された構造体がなく、代わりに必要なものをピックアップして
以下のように自分で構造体を定義する。

```
struct NodeBuffer {
    float4x4 modelViewProjectionTransform;
};
```

すると、そのデータが`[[buffer(1)]]`にバインドされてシェーダに渡される。

> ピックアップできるものはドキュメントの`Listing 1 
Available Fields for Per-Node Shader Data`を参照


#### カスタム変数
上記以外の変数は構造体として定義が必要。定義自体は通常通りに行う。
ただし、バインドされるバッファは2以降になる。

#### 実装
まとめると、`VertexShader`の宣言部分は以下の通り
```
vertex output myVertex(input in [[ stage_in ]],
                       constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                       constant NodeBuffer& scn_node [[ buffer(1) ]],
                       constant CustomBuffer& custom [[ buffer(2) ]]) {
```
ここでの重要なポイントは**引数名**。
- `scn_frame`と`scn_node`は固定  
（違う名前にすると正しくバインドされない）
- カスタム変数の引数名`custom`は`SceneKit`からデータを渡す時に使う

中での処理は必要な計算をして、それを`FragmentShader`に渡すという、
通常の`Metal`のシェーダと同じ実装を行う。

### FragmentShader側

#### テクスチャ
テクスチャを利用したい場合は、特に事前の定義などは不要で通常通り宣言する
```
fragment half4 textureFragment(VertexOut in [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]]) {
```
ただしここでも重要なポイントは**引数名**（詳細は後述）。

### SceneKit側
カスタム変数とテクスチャ以外は自動でバインドされる  
（＝SceneKit側の処理は特にない）

#### カスタム変数
シェーダ側と同じ構造体のデータを準備する辺りは通常通り。

そのデータをシェーダ側にバインドするのは以下のように`setValue`を利用する
```
var custom = CustomBuffer(color: float4(0, 0, 0, 1))
material.setValue(NSData(bytes: &custom, length:sizeof(CustomBuffer)),
                  forKey: "custom")
```
`setValue`は`SCNProgram`をセットしたのと同じ対象（今回は`material`）に行う。  
また、`value`は`NSData`としてバイナリで渡し、`key`はシェーダでの宣言と同じ名前にする。

#### テクスチャ
今回のモデルではマテリアルの`diffuse`にテクスチャが設定されているので、まずそれを取得する。
その後、`SCNMaterialProperty`の形式にしてから変数と同様に`setValue`する
```
guard let contents = material.diffuse.contents else { return }
material.setValue(SCNMaterialProperty(contents: contents),
                  forKey: "texture")
```

ポイントは、`SCNMaterialProperty`を生成しなおしてからセットすること。  
直接`diffuse`の中のデータを`setValue`すると正しくデータが渡されない。


#### 命名の注意点
シェーダの引数名と`SceneKit`側で`setValue`の`key`は一致させる必要がある。

さらに大事な点として、`setValue`は`KVO`を利用しているので、
命名時にはオブジェクトのプロパティとかぶる様な名前をつけてはいけない。  
（例えば`color`などは実行時にエラーログが出て連携ができない）



## 感想
今回はサンプルもなくとても苦戦した。。。特にシェーダとSceneKit間のデータのやりとり辺りは、
ドキュメントにも細かく書いてなくて苦労した。  
妙に親切に頂点属性などをバインドしてくれると思ったら、
引数名固定だったり、テクスチャの再生成が必要だったりと落とし穴もいっぱい・・・

あと、引数名がスネークケースなのもいただけない。
他がキャメルケースなのでここは統一して欲しかった。

ただ、Metalのバインドの辺りの仕組みはどうなっているのか興味深いので、
もっといろいろ触ってみたい。

# 参考リンク
- Apple公式ドキュメント([SCNProgram](https://developer.apple.com/reference/scenekit/scnprogram))

# 開発環境
+ OS X 10.11.5
+ Xcode 7.3.1
+ iOS 9.3.2
+ iPhone 6+

# ソース
[こちら](https://github.com/mike-neko/MetalShaderSceneKit)