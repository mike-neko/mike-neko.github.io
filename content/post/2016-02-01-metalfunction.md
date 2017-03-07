+++
categories = ["old"]
tags = ["metal", "gpgpu"]
date = "2016-01-28T22:32:26+09:00"
draft = false
slug = "metal-function"
title = "Metal組み込み関数"

+++
## Metalのシェーダで利用できる関数のまとめ

#### HLSL/GLSLは各言語との対比
- (空白) : 同じ
- ー : 該当なし
- △ : 同等の関数があるが詳細が異なる
- (関数名) : 挙動は同じだが、名前が別の関数がある

<!--more-->

## 共通関数
- T は浮動小数点数のスカラーかベクター

Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
T clamp(T x, T min, T max) | x を [min, max] の範囲にクランプする<br>fmin(fmax(x, min), max) を返す<br>min > maxは**不定**
T mix(T x, T y, T a) | [x, y] の間の a で線形補間<br>x + (y – x) * a を返す<br>a は 0.0 から 1.0。それ以外は**不定** | lerp
T saturate(T x) | x を [0.0, 1.0] の範囲にクランプして返す | | ー |
T sign(T x) | x > 0 で 1.0, x < 0 で -1.0,<br>x = -0.0 で -0.0, x = +0.0 で +0.0,<br>x = NaN で 0.0 を返す | △ | △ |
T smoothstep(T e0, T e1, T x) | x <= e0 で 0.0, x >= e1 で 1.0<BR>それ以外は [0.0, 1.0] の範囲でエルミート補間した値を返す<br>スムーズなトランジションに便利<br>t = clamp((x – e0)/(e1 – e0), 0, 1);<br>return t * t * (3 – 2 * t);と等価<br>e0 >= e1 または<br> x, e0, e1 のいずれかが NaN は**不定**
T step(T edge, T x) | x < edge で 0.0<br>それ以外は 1.0 を返す


## 整数関数
- T は整数のスカラーかベクター
- Tu は符号なし整数のスカラーかベクター

Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
T abs(T x)<br>T fabs(T x) | x の絶対値を返す
Tu absdiff(T x, T y) | オーバーフローなしで x - y の絶対値を返す | ー | ー
T clz(T x) | x の先頭ビットから連続する 0 の個数<br>x = 0 で x の型のビットのサイズを返す | ー | ー
T ctz(T x) | x の末尾ビットから連続する 0 の個数<br>x = 0 で x の型のビットのサイズを返す | ー | ー
T hadd(T x, T y) | (x + y) >> 1 を返す<br>中間合計はオーバーフローしない | ー | ー
T madhi(T a, T b, T c) | mulhi(a, b) + c を返す | ー | ー
T madsat(T a, T b, T c) | saturate(a * b + c) を返す | ー | ー
T max(T x, T y) | x と y の最大値を返す
T min(T x, T x) | x と y の最小値を返す
T mulhi(T x, T y) | x * y の結果の上位半分のビットを返す | ー | ー
T popcount(T x) | x の 0 ではないビットの数を返す | ー | ー
T rhadd(T x, T y) | (x + y + 1) >> 1 を返す<br>中間合計はオーバーフローしない | ー | ー
T rotate(T v, T i) | v の各要素に対し対応する i の要素の値のビット数分左へシフトした値を返す<br>あふれたビットは右端から挿入される | ー | ー
T subsat(T x, T y) | saturate(x - y) を返す | ー | ー

## 関係関数
- T は浮動小数点数のスカラーかベクター
- Ti は整数かブーリアン型のスカラーかベクター
- Tb はブーリアン型のスカラーかベクター

Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
bool all(Tb x) | x の全ての要素が true の時に true を返す | △ | 
bool any(Tb x) | x のいずれかの要素が true の時に true を返す | △ | 
Tb isfinite(T x) | x が有限の場合は true を返す |  | ー
Tb isinf(T x) | x が無限大(+/-)であれば true を返す |  | 
Tb isnan(T x) | x がNanであれば true を返す |  | 
Tb isnormal(T x) | x が正規化数であれば true を返す | ー | ー
Tb isordered(T x, T y) | x と y の引数が順序付けられているか<br>(x == x) && (y == y) を返す | ー | ー
Tb isunordered(T x, T y) | x と y の引数が順序付けられていないか<br>x か y が NaN であれば true を返す | ー | ー
T select(T a, T b, Tb c) | result[i] = c[i] ? b[i] : a[i] を返す | ー | ー
Ti select(Ti a, Ti b, Tb c) | result = c ? b : a　を返す | ー | ー
Tb signbit(T x) | 符号ビットをテストする<br>x に浮動小数点数がセットされている場合は true | ー | ー


## 数学関数
- T は浮動小数点数のスカラーかベクター
- Ti は整数のスカラーかベクター

 Metal |     | HLSL | GLSL |
 ----- | --- |:----:|:----:|
T acos(T x) | x のアークコサインを返す
T acosh(T x) | x のハイパボリックアークコサインを返す
T asin(T x) | x のアークサインを返す
T asinh(T x) | x のハイパボリックアークサインを返す
T atan(T x) | x のアークタンジェントを返す
T atan2(T y, T x) | y と x のアークタンジェントを返す
T atanh(T x) | x のハイパボリックアークタンジェントを返す
T ceil(T x) | x を正の無限大に近いほうの整数に丸めた値を返す
T copysign(T x, T y) | y の符号に変えた x を返す | ー | ー
T cos(T x) | x のコサインを返す
T cosh(T x) | x のハイパボリックコサインを返す
T cospi(T x) | pi * x のコサインを返す | ー | ー
T exp(T x) | e ^ x を返す
T exp2(T x) | 2 ^ x を返す
T exp10(T x) | 10 ^ x を返す | ー | ー
T fdim(T x, T y) | x > y で x - y,<br>x <= y で +0 を返す | ー | ー
T floor(T x) | x を負の無限大に近いほうの整数に丸めた値を返す
T fma(T a, T b, T c) | a * b + c を返す<br>融合積和演算(IEEE 754-2008準拠) | ー 
T fmod(T x, T y) | x - y * trunc(x / y) を返す |  | ー
T fract(T x) | x の小数部を返す | frac |
T frexp(T x, Ti &exp) | x = [返り値] * 2 ^ exp となる<br>返り値は[1/2, 1]の範囲か 0 となる
Ti ilogb(T x) | x の指数を整数で返す | ー | ー
T ldexp(T x, Ti k) | x * 2 ^ k を返す
T log(T x) | x の自然対数を返す
T log2(T x) | x の 2 を底とする対数を返す
T log10(T x) | x の 10 を底とする対数を返す
T fmax(T x, T y) | x と y の最大値を返す<br>片方の引数が NaN なら NaN では無い方の値を返す<br>両方が NaN なら NaN を返す | ー | ー
T fmin(T x, T y) | x と y の最小値を返す<br>片方の引数が NaN なら NaN では無い方の値を返す<br>両方が NaN なら NaN を返す | ー | ー
T modf(T x, T &intval) | x を同じ符号を持つ整数部と少数部に分ける<br>少数部を返り値で、整数部を intval で返す
T pow(T x, T y) | x ^ y を返す
T powr(T x, T y) | x >= 0 の x ^ y を返す | ー | ー
T rint(T x) | x を最近接偶数へ丸めた整数値を返す | ー | ー
T round(T x) | x を直近の整数値に丸めて返す<br>半分の場合は 0 に近い方となる | △ | △
T rsqrt(T x) | x の平方根の逆数を返す |  | ー
T sin(T x) | x のサインを返す
T sincos(T x, T &cosval) | x のサインとコサインを計算する<br>サインを返り値で、コサインを cosval で返す |  | ー
T sinh(T x) | x のハイパボリックサインを返す
T sinpi(T x) | pi * x のサインを返す | ー | ー
T sqrt(T x) | x の平方根を返す
T tan(T x) | x のタンジェントを返す
T tanh(T x) | x のハイパボリックタンジェントを返す
T tanpi(T x) | pi * x のタンジェントを返す | ー | ー
T trunc(T x) | x を 0 に近い方向へ丸めた値を返す | ー | 

## 行列関数
Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
float determinant(floatnxn)<br>half determinant(halfnxn) | 行列式を返す<br>行列は正方行列でなければならない
floatmxn transpose(floatnxm)<br>halfmxn transpose(halfnxm) | 転置行列を返す

## 幾何関数
- T は浮動小数点数(floatn / halfn)のベクター
- Ts はベクターに対応するスカラー

Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
T cross(T x, T y) | x と y の外積を返す<br>T は3次元ベクトルでなければならない
Ts distance(T x, T y) | x と y の距離を求める<br>length(x - y) を返す
Ts distance_squared(T x, T y) | x と y の距離の平方を返す | ー | ー
Ts dot(T x, T y) | x と y の内積を返す
T faceforward(T N, T I, T Nref) | dot(Nref, I) < 0.0 で N<br>それ以外は -N を返す
Ts length(T x) | x のベクトルの長さを返す
Ts length_squared(T x) | x のベクトルの長さの平方を返す | ー | ー
T normalize(T x) | x の正規化した値を返す
T reflect(T I, T N) | 入射ベクトル I と面の法線ベクトル N から、反射ベクトル I – 2 * dot(N, I) * N を返す<br>N は正規されていなければならない
T refract(T I, T N, Ts eta) | 入射ベクトル I と面の法線ベクトル N と屈折率 eta から、屈折ベクトルを返す<br>I と N  は正規されていなければならない

## グラフィック関数
### フラグメントシェーダ
- T はfloat, float2, float3, float4, half, half2, half3, half4

Metal |     | HLSL | GLSL |
----- | --- |:----:|:----:|
T dfdx(T p) | スクリーン空間の指定された x 座標に対する高精度の偏微分を返す | ddx | dFdxFine
T dfdy(T p) | スクリーン空間の指定された y 座標に対する高精度の偏微分を返す | ddy | dFdyFine
T fwidth(T p) | fabs(dfdx(p)) + fabs(dfdy(p)) を返す | 


## 感想
さすが後発なだけあって、全部入り。GLSLをベースにHLSLやらOpenCLからありったけ詰め込んだような感じ。

# 参考リンク
- 公式：[Metal Standard Library](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalShadingLanguageGuide/std-lib/std-lib.html)
- OpenGL4.5：[API Reference Card](https://www.opengl.org/sdk/docs/reference_card/opengl45-reference-card.pdf)
- DirectX：[組み込み関数 (DirectX HLSL)](https://msdn.microsoft.com/ja-jp/library/bb509611.aspx)

