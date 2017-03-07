+++
categories = ["ios", "mac"]
date = "2017-03-05T22:36:43+09:00"
draft = false
slug = "modelio-mesh"
tags = ["metal", "swift3"]
title = "Model I/Oで立体図形のメッシュを生成"

+++

## 概要
Metalで描画のテストなどでさくっとモデルを表示したい時に、Model I/Oを使って3Dのモデルを生成する方法

法線やUV座標も作ってくれるので地味に便利である

<!--more-->

## 生成されるモデル
生成できる図形の種類は、

- ボックス
- 球体
- シリンダ
- 円錐
- 平面
- 正20面体

生成時には大きさや分割数も指定できる

各頂点データの中身は、シェーダで書くと以下の感じ
```
struct Vertex {
    float3 position    [[ attribute(0) ]];
    float3 normal      [[ attribute(1) ]];
    float2 texcoord    [[ attribute(2) ]];
};
```

## 生成の方法
流れとしては、

1. `MDLMesh`のクラスメソッドで指定した図形のメッシュを生成
1. Metalで扱えるように`MTKMesh`へ変換
1. 頂点データに合わせて`MTLRenderPipelineState`を生成
1. メッシュを描画

という感じになる

### メッシュを生成
例えば、ボックスを生成したい場合は以下のとおり
```
let device = MTLCreateSystemDefaultDevice()!
let allocator = MTKMeshBufferAllocator(device: device)
let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(1),
                             segments: vector_uint3(2),
                             geometryType: .triangles,
                             inwardNormals: false,
                             allocator: allocator)
```
`MDLMesh.newBox`がボックスのメッシュを生成するクラスメソッドで、
引数の`dimensions`でサイズ、`segments`で分割数を指定している。
図形の種類によって引数のパラメータは異なる（円筒なら半径も指定など）

`inwardNormals`は法線の向きの指定。
通常は`false`で良いが、スカイボックスや部屋の中のように立体の内側に視点がある場合は`true`にする

### メッシュを変換
`MDLMesh`を`MTKMesh`（Metalで描画する時に必要な情報全部がまとまったクラス）へ変換する
```
let mesh = try! MTKMesh(mesh: mdlMesh, device: device)
```

### MTLRenderPipelineStateを生成
`MTLRenderPipelineState`を生成する際にメッシュの頂点情報を与えて生成する
```
let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
let renderDescriptor = MTLRenderPipelineDescriptor()
renderDescriptor.vertexDescriptor = vertexDescriptor
// ここで通常どおりシェーダなどの設定をする
let renderState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
```
ただし、生成されるメッシュの頂点形式は固定のようなので手動で設定するのもありかもしれない

### メッシュを描画
```
renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer,
                              offset: 0, at: 0)
renderEncoder.drawIndexedPrimitives(
    type: mesh.submeshes[0].primitiveType,
    indexCount: mesh.submeshes[0].indexCount,
    indexType: mesh.submeshes[0].indexType,
    indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
    indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)
```
メッシュのデータはインデックスバッファ形式で格納されているので、`drawIndexedPrimitives`を使う。
また、`VertexBuffer`は一つのみ、サブメッシュも一つのみ生成されるようなので固定にしている


## ソース
必要最低限（ライト固定、テクスチャなし）のコードは以下の感じ  
mac用だがiOSへもViewController周り以外はそのまま使える

{{< gist 6ed7ba3fe83bcf0418a6f5e682e6138a >}}

`Matrix`周りは[こちら](https://github.com/mike-neko/MetalTessellation/blob/master/MetalTessellation/Matrix.swift)を参照

# 開発環境
- Xcode 8.2
- iOS 10 
- macOS 10.12
