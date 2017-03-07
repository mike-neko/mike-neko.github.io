+++
categories = ["ios"]
tags = ["swift3", "objc"]
date = "2016-02-20T08:10:44+09:00"
draft = false
slug = "objC-exception"
title = "SwiftでNSExceptionを処理する"

+++

ObjectiveCで書かれた`NSException`を発生させるソースをSwiftから利用したい時の処理方法。

`NSException`は、ObjectiveCの`@try ~ @catch ~ @finally`でしか例外処理を行えない。例外処理を書いていない時は、実行時エラーとして処理される。つまり、Swiftから`NSException`を発生させるコードを呼び出して例外が起きると、問答無用でアプリが落ちてしまう・・・

<!--more-->
対応策としては、

1. 元のコードもSwiftで書き換えてしまう
2. そもそも例外は起きるはずがないので~~落ちていい~~無視する
3. 該当のメソッドを呼び出す部分をブリッジするラッパを作る
4. なんとかしてSwiftで`NSException`の例外を処理する

といった感じになると思うが、サードパーティのライブラリとかだと1や2の方法が取れない場合がある。
3も該当のメソッドが多ければ作業量が多くなるし、ソースの見通しも悪くなる。

なので、今回は4の方法で例外を処理する方法についてメモしておく。

## 小ネタ
基本的な考えた方は3と同じで、ObjectiveCでしか処理できない部分だけラップしてしまえ〜となる。
まずは以下の様なブリッジ用のObjectiveCのクラスを作る。（`Bridging-Header`への追加も忘れずに）

{{< gist 5add082e4f51059161ce >}}

中は見ての通り、例外処理のそれぞれの中身をクロージャ（ブロック）でブリッジ用のクラスに渡している。

`nonnull`や`nullable`をつけているのは、Swift側から呼び出す時に`Optional`になるかどうかを制御する為。`finally`は不要なことも多々あるので`nil`を渡せる様に`nullable`にしている。

（意図して処理がないことを明示させる為に空ブロックではなく`nil`を渡せる様にしている）

### 使い方
Swiftから呼び出す時は以下の感じ。

```
ObjC_Exception.objC_try({ _ in
  // NSExceptionが起きるかもしれない処理
},

objC_catch: { (NSException) in
  // 例外発生時の処理
},

objC_finally: { _ in
  // 後処理とか...
})
```

`finally`が不要であれば、

```
ObjC_Exception.objC_try({ _ in
  // NSExceptionが起きるかもしれない処理
},

objC_catch: { (NSException) in
  // 例外発生時の処理
},

objC_finally: nil)
```

もし複数の`catch`が使いたい場合は、これを元に拡張すればOK。

### nonnullやnullableのアノテーションについて
ObjectiveC側でアノテーションを指定すると、Swiftとの連携時のメソッドの型にも反映される。

 ObjC | Swift | 変換前(ObjC) | 変換後(Swift) |
:--: | :--: | :---: | :----: |
 未指定 | (型)! | Hoge* | Hoge!
 nonull<br>_Nonnull | (型) | Hoge* _Nonnull | Hoge
 nullable<br>_Nullable | (型)? | Hoge* _Nullable | Hoge?

例えば、今回のメソッドをSwiftから呼び出す時は
```
ObjC_Exception.objC_try(objC_try: () -> Void, objC_catch: (NSException) -> Void, objC_finally: (() -> Void)?)
```
という形式になっていて、`objC_finally`を`nullable`にしたので、ちゃんと`?`のついた`Optional`になっているし、それ以外は`nonnull`なので型がそのまま使われている。


# 開発環境
+ Xcode 7.2
+ iOS 9.2

# ソース
[こちら](https://github.com/mike-neko/ObjC_Exception)
