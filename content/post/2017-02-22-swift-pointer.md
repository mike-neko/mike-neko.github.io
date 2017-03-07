+++
categories = ["ios", "mac"]
date = "2017-02-22T23:55:36+09:00"
draft = false
slug = "swift-pointer"
tags = ["swift3"]
title = "Swift3のポインタの基礎知識"

+++
基本的にSwiftからポインタをそのまま扱う機会はほとんどないが、CのAPIやMetal等でポインタを扱う場合用のメモ

なお、画像などのバイナリデータを単に扱いたいだけの場合は`Data`が`UInt8`の配列と同等に扱えるようになったのでそっちを使った方が良い

<!--more-->

実際の使い方は[実践編](../swift-pointerc)も参照

## 概要
ポインタはメモリ上のデータにアクセスする時に使うものである。
Swiftの場合、紐付けられている**型**によって、以下の種類がある

- UnsafePointer / UnsafeMutablePointer  
    特定の型にバインドされている。タイプセーフである
- UnsafeRawPointer / UnsafeMutableRawPointer  
    特定の型にバインドされていない。型保証がない
- UnsafeBufferPointer / UnsafeMutableBufferPointer  
    Unsafe(Mutable)Pointerの配列版
- UnsafeRawBufferPointer / UnsafeMutableRawBufferPointer  
    Unsafe(Mutable)RawPointerの配列版

`〜BufferPointer`は、メモリ上に要素（データ）が連続しているバッファの場合に利用出来るポインタで、実体はメモリへのビューである。
リリースモードでは境界チェックがされずにアクセスされる（デバッグモードではチェックされる）

### 注意事項
ポインタを使う場合、自動メモリ管理やアライメントの保証はされない。よってライフサイクルを自分で管理しメモリリークや未定義扱いとなる動作を自分で避けなければならない

`〜RawPointer`の場合は、タイプセーフではない
（Rawがついていないものはコンパイラによる型チェックが行われるが、異なるデータ型を強制的に割り当てたような場合は当然未定義の動作となる）

### ポインタの状態
ポインタはポインタの指すメモリの状態によって以下のような状態となる

- 未バインド（未初期化）  
    - メモリとバインドされていない状態
    - 例：ポインタの宣言直後のような場合
- バインド済・未初期化  
    - メモリとバインドされているが、メモリ上のデータは未初期化
    - 例：メモリ確保済だが未初期化のメモリへのポインタ
- バインド済・初期化済
    - 例：値の設定されているメモリへのポインタ

### `trivial type`
型の中に参照を含まないデータ型。単純なバイトのコピーだけで複製できる型のこと

## UnsafePointer / UnsafeMutablePointer
### 読み取り
- バインド済・未初期化：初期化が必要
- バインド済・初期化済：次のどちらかで読み取る  

    ```
    let ptr: UnsafePointer<Int> = ...   // 中身は10  
    let i = ptr.pointee                 // Intの10  
    let j = ptr[0]                      // Intの10  
    ```

### 書き込み
- 未バインド（未初期化）：`allocate(capacity:)`でメモリを確保してバインドできる（メモリは未初期化のまま）
- バインド済・未初期化：`initialize(to:count:)`,`initialize(from:)`,`moveInitializeMemory(from:count)`を使って初期化
- バインド済・初期化済：次のどちらかで設定できる

    ```
    var ptr: UnsafeMutablePointer<Int> = ...
    ptr.pointee = 10
    ptr[0] = 10
    ```

## UnsafeRawPointer / UnsafeMutableRawPointer
読み書きの際にはアライメントに注意すること
### 読み取り
- 未バインド（未初期化）：`bindMemory(to:count:)`で型にバインドする（rawではないポインタが返される）
- バインド済・未初期化：バインドした型の値で初期化が必要  
    （=rawでは初期化はできない）
- バインド済・初期化済：`load(fromByteOffset:as:)`で型を指定して読み取り
（アライメントに注意）

### 書き込み
- 未バインド（未初期化）：`initializeMemory(as:from:)`,`moveInitializeMemory(as:from:count)`を使って初期化できる
- バインド済：`storeBytes(of:toByteOffset:as:)`で書き込み可能。ただし`trivial type`のみ

## ポインタ演算
`+`と`-`と`[]`(subscript)が利用可能。
それぞれ指定した数だけオフセット（※）されてアクセスされる

※UnsafePointer / UnsafeMutablePointerの場合は、その型のバイト数分だけ。UnsafeRawPointer / UnsafeMutableRawPointerの場合は、バイト単位でオフセットされる

```
// intPointerがIntの[0, 1, 2, 3, 4]のメモリを指している場合
intPointer + 2      // 2
intPointer[2]       // 2
```

## 型変換
### 互換性のある別の型に一時的にバインド  
`withMemoryRebound(to:capacity:)`を使う
```
// 例：Int8 => UInt8
uint8Pointer.withMemoryRebound(to: Int8.self, capacity: 8) {
    // $0
}
```

### 別の型に永続的にバインド
1. `RawPointer`にしてから指定の型へバインドしなおす

    ```
    // 例：UInt8 => UInt64
    let uint64Pointer = UnsafeRawPointer(uint8Pointer)
                            .bindMemory(to: UInt64.self, capacity: 1)
    ```
    なお、再バインドされるのでこの場合、元のuint8Pointerは**未定義**になる

1. trivial types同士の場合  
    `RawPointer`にしてから`load`を使う

    ```
    let rawPointer = UnsafeRawPointer(uint64Pointer)
    fullInteger = rawPointer.load(as: UInt64.self)   // OK
    firstByte = rawPointer.load(as: UInt8.self)      // OK
    ```
    Mutableの場合は`storeBytes(of:toByteOffset:as:)`で設定もできる

### 暗黙の変換とブリッジ
関数の引数に渡す時限定で暗黙的なキャストとブリッジをしてくれる

例えば、
```
func printInt(atAddress p: UnsafePointer<Int>)
```
というメソッドがある場合、

```
var value: Int = 23
printInt(atAddress: &value)         // &をつける

let numbers = [5, 10, 15, 20]       // 配列はlet
printInt(atAddress: numbers)        // 配列は&不要
```
とすれば、自動で`UnsafePointer`へ変換して処理される

もし、`printInt`の引数が`UnsafeMutablePointer`の場合であれば、
```
var value: Int = 23
printInt(atAddress: &value)         // &をつける

var numbers = [5, 10, 15, 20]       // mutableなのでvar
printInt(atAddress: &numbers)       // inoutなので&
```
とする

***注意事項***

この暗黙の変換によるポインタの有効範囲は該当の関数のスコープ内のみ。
よって関数からポインタを返してそれを利用するのは禁止（動作は**未定義**である）

特に以下のように初期化に使うのは禁止
```
var number = 5
let numberPointer = UnsafePointer<Int>(&number)
// numberPointerの動作は未定義
```
