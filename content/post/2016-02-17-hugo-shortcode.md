+++
categories = ["web"]
tags = ["hugo", "github"]
date = "2016-02-16T23:07:23+09:00"
draft = false
slug = "hugo-shortcode"
title = "Hugoのshortcodeのメモ"

+++

Hugoの`shortcode`を使って、記事の中でHTMLのタグをべた書きしなくて良い様にする方法のメモ。あと、おまけで`shortcode`をMarkdownの中でエスケープして表示する方法。

<!--more-->
## 画像を貼り付けるshortcode
Hugoで画像を表示するには、`static`の中に置く必要がある。この中は全サイト共通になっているので、整理しやすいように以下のディレクトリ構成にした。
```
- static
    - media
        - 2016-02-16-sprite-shader
            - comp.png
            - beta.gif
        - 2016-02-18-hugo-shortcode
            - sample.jpg
        ...
```

`media`の中に、記事毎に`[作成日付]-[slug]`というディレクトリを作り、その中に画像などのコンテンツを置いている。

この状態で記事の中で画像を表示させるには、`{{</* figure src="/media/2016-02-18-hugo-shortcode/sample.jpg" */>}}`となる。

これを毎回書くのは面倒だが`shortcode`を使うと、`{{</* img "sample.jpg" */>}}`とだけ書けばよい。

### 作り方
1. `<site-name>/layouts/shortcodes/img.html`を作成
2. 1のファイルに
{{< gist 593de54e0ba8f5db4c6b >}}
を貼り付けて保存
3. あとは使いたい場所で`{{</* img "ファイル名" */>}}`とすればOK

## エスケープ方法
記事の中で、`shortcode`などを表示させたい場合に、そのまま書くと当然ながらそのコードが実行されてしまうので、エスケープが必要となる。

このエスケープ方法は幾つかある（他にもあるかも）

1. `\`をつける方法  
`\{\{< コード >}}`
2. `{`を`&lt;`と入力する方法  
`{{&lt; コード >}}`
3. `/**/`のコメントにする方法  
`{{/* コード */}}`

で、一番おすすめなのは3の方法。他の方法だと``で囲った時にうまく表示されないので。

# 参考リンク
- 公式：[Hugo - Shortcodes](https://gohugo.io/extras/shortcodes/)


