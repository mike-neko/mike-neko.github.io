+++
categories = ["ios"]
tags = ["swift3"]
date = "2016-10-23T22:28:33+09:00"
draft = false
slug = "scrollview"
title = "UIScrollViewのAutoLayoutをStoryboardのみで設定"

+++

Storyboard上だけでUIScrollViewのAutoLayoutを完結させる方法。
中のUIを動的に追加や削除しないのであればコードを書く必要もないし、
`UILabel`のようにコンテンツに応じて動的に高さが変わるようなものにも対応可能

<!--more-->

ポイントは`ContainerView`を利用してScrollViewを別のViewControllerに持っていくこと

## 手順
サンプルとしてViewControllerの全画面に縦スクロールするScrollViewを配置する例を考える

#### 1. ViewControllerのScrollViewを置きたい場所に`ContainerView`を置き制約を設定する  
  
（サンプル）全画面にしたいのでViewに対して`0`で設定
{{< img "step1.png" >}}
*`Layout Guide`に対して制約を設定するとステータスバーなどに合わせて位置が変わる*

#### 2. 1で追加した子ViewControllerをアウトライン上で選択し、ViewControllerのサイズを`Freeform`へ変更する  
  
変更すると`Height`の部分が変更できるようになるので、
{{< img "step2.png" >}}
ScrollViewの`ContentSize`の高さがあらかじめ決まっているのであれば同じに、
そうでないなら余裕を持った数字に変えておく

*サイズを変更しなくても組めるが変更した方がスクロールせずに作業が行えるので楽*

#### 3. 1で追加した子ViewControllerのViewにScrollViewを追加し任意の制約を設定する  
  
（サンプル）全画面にしたいのでViewに対して今回も`0`で設定
{{< img "step1.png" >}}
*もしスクロールしないヘッダとつけたりしたいなら、この子ViewControllerのViewに対して追加しておくと便利*

#### 4. 3で追加したScrollViewにViewを追加し制約を設定する

（サンプル）縦スクロールにしたいので制約は以下の通り
{{< img "step4.png" >}}

- 縦と横はそれぞれ親(Scrollview)に対して`0`
- 横幅は親(Scrollview)と同じ

*ここで追加したViewがいわば`ContentView`となる*

#### 5. 4のviewに各パーツを配置していく
この工程は普段通りのAutoLayoutの設定でOK。
`UILabel`の高さをコンテンツに応じて変えたいなら高さを設定せずにマージンだけを設定する

*Scrollviewの中身の高さが固定でないなら`height`は設定しないこと*

### 参考：Viewの階層
子ViewControllerのアウトライン
{{< img "view.png" >}}

## 感想
`AutoLayout`って使い方のコツを見つけるまでが大変だけど、このサンプルみたいにやり方を見つけてしまうと楽すぎ〜〜


# 開発環境
+ OS X 10.12.0
+ Xcode 8.0 / Swift3
+ iOS 10.0.2