+++
categories = ["ios", "mac"]
date = "2017-03-02T23:36:28+09:00"
draft = false
slug = "metal-coordinate"
tags = ["metal"]
title = "Metalの座標周りのメモ"

+++
わりと間違いやすいので、Metalの座標周りのまとめ

<!--more-->
実はAppleの公式のサンプルも間違っていたりする・・・・

## 座標系
Metalは *左手系* である

**元々のiOS / macはOpenGLの為、そのまま既存サンプルを移し替えようとすると、座標系でハマるので注意！**
OpenGLからの移植は行列の中身（列ベクトル or 行ベクトル）が違う場合もあるので注意！

||座標系|
---|---|
Metal | 左手系
OpenGL / WebGL | 右手系
DirectX | 左手系

なお、左手系と右手系の違いはZ軸の向きだけである

| Metal, DirectX | OpenGL, WebGL |
:---: | :---: |
{{< img "left.png" >}} | {{< img "right.png" >}}
z軸の奥が+ | z軸の手前が+


## UV座標
Metalは *左上* が原点(0, 0)、右下が(1, 1)となる

||UV座標|
---|---|
Metal | 左上
OpenGL / WebGL | 右上
DirectX | 左上

| Metal, DirectX | OpenGL, WebGL |
:---: | :---: |
{{< img "lefttop.png" >}} | {{< img "rightbottom.png" >}}
