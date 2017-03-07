+++
categories = ["ios"]
tags = ["swift3", "php"]
date = "2016-12-06T22:04:28+09:00"
draft = false
slug = "multipart"
title = "multipart/form-dataによるファイルのアップロード"

+++

（`Alamofire`とかのライブラリを使った方が幸せになれると思うが）
HTMLのフォームからの送信と同じ様な`multipart`によるアップロードをiOSからする方法

<!--more-->

## 要件
- タイトル（文字列）とファイルを一緒にサーバへアップロード
- アップロード先は同じホストの`upload.php`
- サーバからはjsonで結果が返ってくる

## HTMLの場合
上記要件でかつアップロードと同じ画面内で結果を表示させたい場合、
`jQuery`などを全く使わずに素のHTMLで書くと

{{< gist 9c53de2d62a4be94dd26131479b52c6f >}}

もし、ajaxではなく送信結果は次の画面で表示させる様な場合だと`<form>`タグは
`<form name="upload" enctype="multipart/form-data" action="upload.php" method="post">`
とする必要がある

## iOSの場合
もし単一のファイルのアップロードだけなら、`URLSession`の`uploadTask(with:〜`でOKだが、
他のデータやファイルも付加したい場合は自分で`multipart`のリクエストを生成する必要がある

とりあえずHTMLと同じものをベタ書き(+エラー省略)すると、

{{< gist 3825cf1ea22cb4f1a1469a33c44097ff >}}

### boundary文字列
`multipart`の場合、データの区切りを表すためにデータ内に含まれない様なバウンダリ文字列が必要となる
```
let boundary = String(format: "----iOSURLSessionBoundary.%08x%08x", arc4random(), arc4random())
```
今回は`Alamofire`を参考に送信元のプログラムとランダムな数字を組合せた文字列を生成している

### bodyの生成
フォームのデータの場合の構造は
```
--(バウンダリ文字列)[CRLF]
Content-Disposition: form-data; name="フォームの名前"[CRLF]
[CRLF]
(フォームのデータ)
```
となる

ファイルの場合の構造は
```
--(バウンダリ文字列)[CRLF]
Content-Disposition: form-data; name="フォームの名前"; filename="ファイル名"[CRLF]
Content-Type: "ファイルのタイプ"[CRLF]
[CRLF]
(ファイルのデータ)
```
となる

各構造をバイナリ(`Data`型)にしたものを必要な分だけ組合せて、最後に
```
--(バウンダリ文字列)--[CRLF]
```
をつけたものがbody部分のデータとなる

今回の例だとフォームデータが一つとファイルデータが一つなので、
それぞれ一つずつを追加し最後にフッタを付けたものをbodyに入れている  

### headerの生成
フィールドにセットすべきなのは以下の2つ

1. "Content-Type"
1. "Content-Length"

`Content-Type`にはタイプとバウンダリ文字列を以下のように指定する
```
multipart/form-data; boundary=（バウンダリ文字列）
```

`Content-Length`は普通にbodyのサイズを入れればOK

### 送信
送信は`uploadTask`だと`multipart`指定ができないので`dataTask`で行う。
それ以外は通常の`dataTask`のやり方でOK

## 参考：サーバの処理(PHP)
今回サーバ側で検証用に使ったのは以下のソース  
（送信されてきたファイルはそのまま専用のディレクトリに格納し結果をJSONで返すだけ）
```
// "upload"のディレクトリに書き込み権限が必要
$dir = __DIR__ . '/upload/';
$path = $dir . basename($_FILES['filename']['name']);

$data['result'] = 'アップロード失敗';
if (move_uploaded_file($_FILES['filename']['tmp_name'], $path)) {
    chmod($path, 0666);
    $data['result'] = date("H:i:s") . ' ' . $_POST['title'] . ' アップロード成功';
}

header('Content-Type: application/json');
echo json_encode($data);
```

# 参考リンク
- PHP公式：[POST メソッドによるアップロード](http://php.net/manual/ja/features.file-upload.post-method.php)
- MDN公式：[FormData オブジェクトの利用](https://developer.mozilla.org/ja/docs/Web/Guide/Using_FormData_Objects)

# 開発環境
- Xcode 8.1
- iOS 9.3.2 / 10.1.1
- iPhone 6+ / 7+
- PHP 7
- Chrome
