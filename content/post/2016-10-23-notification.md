+++
categories = ["ios"]
tags = ["swift3"]
date = "2016-10-23T18:30:34+09:00"
draft = false
slug = "notification"
title = "NotificationCenterの使い方"

+++

旧`NSNotification`がSwift3でちょっと変更が入ったので使い方と＋αのエクステンションのまとめ

<!--more-->

## 使い方
### 通知の送信
"Change"という名前の通知を送信するときは以下の2パターン
```
NotificationCenter.default.post(
    Notification(name: Notification.Name("Change")))

NotificationCenter.default.post(name: Notification.Name("Change"),
                                object: nil)
```

### 通知の受信

上述の通知を受信したい場合は、

#### 受信先の登録

```
NotificationCenter.default.addObserver(self,
    selector: #selector(recieveHoge),
    name: Notification.Name("Change"),
    object: nil)
```

なお、登録した場合は解除も忘れずにすること！

*参考: UIKeyboardWillShowNotificationとかは*
```
NotificationCenter.default.addObserver(self,
    selector: #selector(keyboardWillShow),
    name: .UIKeyboardWillShow,
    object: nil)
```
という感じに名前が定義されているので省略形で良い

#### 受信するメソッド
```
func recieveHoge(notification: NSNotification) {
    // ここで処理
}
```
アクセス制限は`internal`以上が必要（`private`/`fileprivate`は不可）

`post`時に送った`object`を利用したい場合は、
```
guard let hoge = notification.object as? Hoge else { return }
```
というように変換して使う

また、特に指定をしないとメイン以外のスレッドで呼び出されることがあるので、
UI絡みの部分は`DispatchQueue.main.async`を使った方が良い

#### 受信の解除
特定の通知のみ解除する場合は、
```
NotificationCenter.default.removeObserver(self,
                                          name: Notification.Name("Change"),
                                          object: nil)
```

自身が登録している受信を全て解除する場合は、
```
NotificationCenter.default.removeObserver(self)
```

## エクステンション
今回のSwift3から`Notification.Name`の部分で、以前と比べて手間がかかるようになってしまった
（元からOSで用意されているものは逆に楽）

それとは別に、名前がアプリの他とかぶらないようになるべく一元管理をしたいので、以下のようなエクステンションと`enum`を利用する  

{{< gist 5c92a36705ebcc3c49022a534d4df157 >}}

*※`enum`はガイドライン的には小文字が良いが文字定数を強調したいので大文字になっている*

特にエクステンションといっても特別なことはしていなくて単に専用の`enum`を使えるようにしただけ。  
でも、これを実際に使うと、
```
// 通知の送信
NotificationCenter.default.post(key: .ChangeStatus)

// 通知の受信先の登録
NotificationCenter.default.addObserver(self,
    selector: #selector(recieveHoge),
    key: .ChangeStatus)
```
って感じですっきりする

本来は、`Notification.Name`をエクステンションして使うのが想定されているようだが、
`enum`により一意になることが保証されるのと、リテラルが出てこないので、個人的にはこっちがお気に入り

# 開発環境
+ OS X 10.12.0
+ Xcode 8.0 / Swift3
+ iOS 10.0.2