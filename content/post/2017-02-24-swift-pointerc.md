+++
categories = ["ios", "mac"]
date = "2017-02-24T23:44:10+09:00"
draft = false
slug = "swift-pointerc"
tags = ["swift3"]
title = "Swift3のポインタの実践編"

+++

主にSwiftのポインタとCのポインタとの対比やポインタの変換方法についてのまとめ
<!--more-->

Swiftでのポインタの基礎については[基礎編](../swift-pointer)を参照

## Cのポインタとの対比
`Hoge`という型のポインタを表す場合

| Swift | C |
|:---|:---| 
UnsafePointer\<Hoge> | const Hoge*
UnsafeMutablePointer\<Hoge> | Hoge*

`void*`(汎用ポインタ)には専用の型が用意されている

| Swift | C |
|:---|:---| 
UnsafeRawPointer | const void*
UnsafeMutableRawPointer | void*

なお、ポインタ経由で値を変更したい場合は`Mutable`がついている方を、参照のみであればついていない方を使う

## ポインタへの変換方法

### 早見表

| 変換元 | Hoge | UnsafePointer | UnsafeRawPointer |
|---:|:---:|:---:|:---:|
| **Hoge**             | - | 1.withUnsafePointer | 1 -> 3 |
| **UnsafePointer**    | 2.pointee or [] | - | 3.UnsafeRawPointer() |
| **UnsafeRawPointer** | 4 -> 2 | 4.assumingMemoryBound | - |

`Mutable`の場合も変換方法は同じであるが、それぞれ`Mutable`に対応したものを使う

`Hoge`から`UnsafeRawPointer`のように直接変換できる方法がない場合は、
`UnsafePointer`に変換してから目的の型へ2段階で変換する

異なる型同士での変換については[基礎編](../swift-pointer)を参照のこと

### コード例

前提として、`Hoge`は以下の型とする
```
struct Hoge {
    var x: Float, y: Float, z: Float
}
```
（今回は構造体だが、実体がプリミティブでもクラスでも方法は同じ）

#### 1.2. Hoge => Unsafe(Mutable)Pointer => Hoge
`Hoge`をポインタへ変換、変換したポインタ経由で元の`Hoge`にアクセスする場合

Cの書き方
```
Hoge pos;
pos.x = pox.y = pos.z = 1;

Hoge* p = &pos;
p->x = 100;             // pos.x = 100 となる
(*p).y = 200;           // pos.y = 200 となる
```

Swiftの書き方
```
var pos = Hoge(x: 1, y: 1, z: 1)
withUnsafeMutablePointer(to: &pos) { 
    let p: UnsafeMutablePointer<Hoge> = $0
    p.pointee.x = 100   // pos.x = 100 となる
    p.pointee.y = 200   // pos.y = 200 となる
}
// または以下でも同じ
withUnsafeMutablePointer(to: &pos) { p in
    // p が UnsafeMutablePointer<Hoge> となる
}
```

`withUnsafe(Mutable)Pointer`のクロージャは値を返せるからといって
```
let p = withUnsafeMutablePointer(to: &pos) { $0 }   // 絶対ダメ
p.pointee.x = 100
```
というようにポインタを返す書き方は禁止。
渡されるポインタが有効なのはクロージャ内だけなので、上記書き方の動作は未定義である

よって、クロージャ内で処理を完結させるか、Swiftの変数に代入（値コピー）してそれを返すこと

#### 3. Unsafe(Mutable)Pointer => Unsafe(Mutable)RawPointer
Cの書き方
```
// pHoge が Hoge* の場合
void* pRaw = (void*)pHoge;
```

Swiftの書き方
```
// pHoge が UnsafePointer<Hoge> の場合
let pRaw = UnsafeRawPointer(pHoge)
```

#### 4. Unsafe(Mutable)RawPointer => Unsafe(Mutable)Pointer
Cの書き方
```
// pRaw が void* の場合
Hoge* pHoge = (Hoge*)pRaw;
```

Swiftの書き方
```
// pRaw が UnsafeRawPointer の場合
let pHoge = pRaw.assumingMemoryBound(to: Hoge.self)
```
 *ただし、pRawが既にバインド済であることが前提*  
 未バインドの場合は、`bindMemory`を使う


# 参考リンク
- [Interacting with C APIs](https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID23)
- [UnsafeRawPointer Migration](https://swift.org/migration-guide/se-0107-migrate.html)

