+++
categories = ["ios"]
tags = ["swift3", "webrtc"]
date = "2016-11-30T01:38:22+09:00"
draft = false
slug = "webrtc-ios"
title = "WebRTCをiOSネイティブで使う(実装編)"

+++

iOSで`WebRTC`を使ったビデオチャットを作る方法

<!--more-->

## 事前準備
- [準備編](../webrtc-build)を参考にフレームワークを組み込む
- `Info.plist`に以下を書き込む（※）
  - `Privacy - Camera Usage Description`（カメラを使うのに必要）
  - `Privacy - Microphone Usage Description`（マイクを使うのに必要）

*※iOS10から必須。ないとアプリが強制終了する。
それぞれの値は使う理由の説明を入れておく*

## シグナリング
WebRTCはP2P通信なので何らかの方法で相手と端末(`Peer`)や
通信経路(`ICE Candidate`)の情報をやり取りする必要がある

つまり、何らかのWebRTCとは別の方法で端末間の通信を確立させておくことが必要となる

といってもテキストベースの情報をやり取りできれば良いので、
特にややこしい訳ではない（もちろん接続管理はそれなりに必要だが）ので、
node.jsのsocket.ioで自前のサーバを立てるのも良いし、
サービスとして提供されているサーバを介してやりとりしても良い

今回のサンプルでは完全にローカルなネットワークで、かつ、iOS同士限定なので
サーバが不要な`Multipeer Connectivity Framework`を使っている
（詳細は[こちら](../multipeer/)）

## 実装
ビデオチャットは1対1で動画と音声をやりとりするタイプとする

*生成したコネクション(`RTCPeerConnection`)とローカル / リモートストリーム(`RTCMediaStream`)はクラスのプロパティにして、
必ずstrongで保持されるようにしておくこと  
これを忘れると正常に接続ができていても画像が出ない原因となるので注意！*

### 接続の準備
最初に自分が相手に送る動画と音声のストリームを準備する。
なお、カメラへのアクセスやカメラのライブ映像の表示はほぼフレームワークがカバーしてくれる

#### ローカルストリームの生成
ビデオ（ライブ映像）ストリームを生成して端末のカメラと紐づける
```
let factory = RTCPeerConnectionFactory()
localStream = factory.mediaStream(withStreamId: "MIKE-VIDEOCHAT")
let video = factory.avFoundationVideoSource(with: nil)
let track = factory.videoTrack(with: video, trackId: "MIKE-VIDEOCHAT-V0")
localStream.addVideoTrack(track)
```

オーディオ（音声）ストリームを生成する
（こちらは特に指定しなくても端末のマイクと紐付けされるみたい）
```
localStream.addAudioTrack(factory.audioTrack(withTrackId: "MIKE-VIDEOCHAT-A0"))
```

#### 表示用のビューの生成
相手に送信している映像を確認できるよう、表示用のView
(`RTCEAGLVideoView`というOpenGLを利用して動画を表示する専用のView)
と端末のカメラを紐づける
```
// localView: ViewController内に置いた表示用ビューのコンテナ
let local = RTCEAGLVideoView(frame: localView.bounds)
localView.addSubview(local)
track.add(local)
```

これで端末のフロントカメラの映像が自動で表示されるようになる

#### 接続の生成
ビデオチャットなのでVideoとAudioを必須と指定して`RTCPeerConnection`を生成する。
またローカルストリームを接続と紐づけて相手に送信できるようにする
```
// peer: RTCPeerConnection
let constraints = RTCMediaConstraints(
  mandatoryConstraints: ["OfferToReceiveVideo": kRTCMediaConstraintsValueTrue,
                         "OfferToReceiveAudio": kRTCMediaConstraintsValueTrue],
   optionalConstraints: nil)
peer = factory.peerConnection(with: RTCConfiguration(),
                       constraints: constraints,
                          delegate: self)
peer.add(localStream)
```

### 接続の開始
接続の準備ができればシグナリングを行なって相手と接続を確立させる

流れとしては、

1. 端末Aがofferを送信
1. 端末Bが端末Aのofferを受信
1. 端末Bが端末Aへanswerを送信
1. 端末Aが端末Bのanswerを受信
1. ICEをやりとりしてP2Pで接続を確立

となる

#### [端末A] offerの送信
`peer.offer`で生成したローカルの情報を`peer.setLocalDescription`で設定すると、
offerとなる`SDP`（Peerの情報）が取得できるので、それを相手へ送信する

```
peer.offer(for: constraints) { (description, error) in
  guard let localDescription = description, error == nil else {
    print("Error: \(error?.localizedDescription ?? "")")
    return
  }
  self.peer.setLocalDescription(localDescription) { error in
    guard error == nil,
          let state = self.peer.signalingState,
          case .haveLocalOffer = state else {
      print("Error: \(error?.localizedDescription ?? "")")
      return
    }
    // localDescription.sdp(=offer)を相手へ送信する
  }
}
```

#### [端末B] offerの受信 / answerの送信
受信した`SDP`から`RTCSessionDescription`でリモートの情報を生成し`peer.setRemoteDescription`で設定する

offerを正常に設定できれば、`peer.answer`でローカルの情報を生成し`peer.setLocalDescription`で設定すると、
answerとなる`SDP`が取得できるので、それを相手へ返信する

```
// sdp: 受信した端末Aのoffer
let remoteDescription = RTCSessionDescription(type: .offer, sdp: sdp)
peer.setRemoteDescription(remoteDescription) { error in
  guard error == nil,
        let state = self.peer.signalingState, 
        case .haveRemoteOffer = state else {
    print("Error: \(error?.localizedDescription ?? "")")
    return
  }
  self.peer.answer(for: constraints) { (description, error) in
    guard let localDescription = description, error == nil else {
      print("Error: \(error?.localizedDescription ?? "")")
      return
    }
    self.peer.setLocalDescription(localDescription) { error in
      guard error == nil else {
        print("Error: \(error?.localizedDescription ?? "")")
        return
      }
      // localDescription.sdp(=answer)を相手へ送信する
    }
  }
}
```

#### [端末A] answerの受信
相手から返信された`SDP`から`RTCSessionDescription`でリモートの情報を生成し`peer.setRemoteDescription`で設定する
```
// sdp: 受信した端末Bのanswer
let remoteDescription = RTCSessionDescription(type: .answer, sdp: sdp)
peer.setRemoteDescription(remoteDescription) { error in
  guard error == nil else {
    print("Error: \(error?.localizedDescription ?? "")")
    return
  }
}
```

#### ICEの送受信
SDPのやり取りとは別に通信経路(`ICE Candidate`)もやり取りする必要がある

こちらは単純に相手に渡すべき`ICE Candidate`があると、`RTCPeerConnectionDelegate`の`didGenerate`が呼ばれるのでそれを相手へ送信する
```
func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
  // candidate.sdp(=ICE)を相手へ送信する
}
```

受信した側は、`SDP`から`RTCIceCandidate`を生成して`RTCPeerConnection`に追加する
```
let can = RTCIceCandidate(sdp: sdp, sdpMLineIndex: 0, sdpMid: nil)
peer.add(can)
```

これは何度か行われる

### リモートストリームの受信
`ICE`のやり取りで接続が確立されると、`RTCPeerConnectionDelegate`の`didAdd`が呼び出されて、
相手側からのリモートストリームが渡される

今回はVideoとAudioの両方のストリームがくるはずなので、それを表示用のViewと紐づける

```
func peerConnection(_ peerConnection: RTCPeerConnection, 
                       didAdd stream: RTCMediaStream) {
  // remoteView: ViewController内に置いた表示用ビューのコンテナ
  let remote = RTCEAGLVideoView(frame: remoteView.bounds)
  remoteView.addSubview(remote)
  stream.videoTracks.last?.add(remote)
  remoteStream = stream
}
```

これで相手の映像が表示されてチャットができるようになる

# 開発環境
- macOS 10.12
- Xcode 8.1
- iOS 9.3.2 / 10.1.1
- iPhone 6+ / 7+

# ソース
[こちら](https://github.com/mike-neko/WebRTCVideoChat)
