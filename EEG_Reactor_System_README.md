# EEG Reactor System

Unity用のEEG（脳波）データ可視化・フィードバックシステム

## 概要

EEG Reactor Systemは、BrainFlowなどのEEGデバイスから取得した脳波データをUnity内でリアルタイムに可視化し、VRChatアバターとの連携を可能にするシステムです。

このシステムは[BOOTHで販売されている「Sio Avatar v1」](https://spis.booth.pm/items/7056584)の中核システムとして組み込まれており、[BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)のパラメータ仕様を完全に踏襲しています。

### BrainFlowsIntoVRChatとの関係

- **仕様の完全踏襲**: [BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)で定義された全てのBFI（BrainFlowsIntoVRChat）パラメータに対応
- **システム的疎結合**: BrainFlowsIntoVRChatはPythonベースでVRChatへのOSC送信までを担当し、本システムはUnity側での可視化・フィードバックを担当するため、Forkではなく独立したシステムとして開発
- **相互補完**: BrainFlowsIntoVRChatのデータ出力を本システムで受信し、Unity内での高度な可視化とVRChatアバター連携を実現

## 機能

- **リアルタイムEEGデータ表示**: 脳波の各周波数帯（Alpha、Beta、Gamma、Theta、Delta）をリアルタイムでグラフ表示
- **神経フィードバック**: 集中度（Focus）とリラックス度（Relax）の可視化
- **生体情報表示**: 心拍数、呼吸数、血中酸素濃度などの生体情報表示
- **VRChat連携**: OSCプロトコルを使用したVRChatアバターとのリアルタイム連携
- **テキスト表示**: カスタムフォントを使用した数値・テキスト表示
- **デバッグ機能**: グラフモニターパネルによる詳細なデバッグ情報表示

## システム構成

### 📁 EEG_Animations/
Unity Animator Controllerとアニメーションクリップ群
- `OSC_Animator.controller`: メインのアニメーターコントローラー
- 各種BFI（BrainFlowsIntoVRChat）パラメータ用アニメーションクリップ
- パワーバンド、神経フィードバック、生体情報用のアニメーション

### 📁 EEG_Buffer/
HLSLシェーダー用のデータ型定義とバッファ処理
- `EEGTypes.hlsl`: EEGデータの構造体定義（PowerBands構造体）
- `EEGBuffer.hlsl`: データバッファ処理
- `EEGCompression_HalfTexture.hlsl`: テクスチャ圧縮処理

### 📁 EEG_Text/
テキスト表示システム
- `EEGText.shader`: テキスト表示用シェーダー
- `EEGTextEncoder.hlsl`: テキストエンコーダー
- `EEGTextRenderer.hlsl`: テキストレンダラー
- `123font.png`: カスタムフォントテクスチャ

### 📁 EEG_View/
メイン表示システム
- `EEGView.shader`: メイン表示シェーダー
- `EEGView.hlsl`: 表示処理ロジック
- グラフ表示、テキスト表示、背景設定

### 📁 EEG_FeedBack/
フィードバック表示システム
- `EEGFeedBack.shader`: フィードバック表示シェーダー
- `EEGModel.shader`: モデル表示シェーダー
- `EEG_RenderTexture.renderTexture`: レンダーテクスチャ

### 📁 EEG_Debug/
デバッグ・モニタリング機能
- `EEGDebug.hlsl`: デバッグ処理
- `GraphMonitorPanel.mat`: グラフモニターパネルマテリアル
- `GraphRenderPanel.fbx`: グラフ表示パネルモデル

### 📁 Toolkit/
開発・テスト用ツール
- `VRChatOSCSender.cs`: VRChat用OSC送信スクリプト
- `OSCDisplayTest.cs`: OSC表示テストスクリプト
- `AnimatorOSCSetupEditor.cs`: アニメーターOSC設定エディター
- `OSCSender.prefab`: OSC送信用プレハブ
- `TestController.prefab`: テスト用コントローラープレハブ

## 対応データ形式

### BrainFlowsIntoVRChat (BFI) パラメータ

本システムは[BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)で定義された全てのパラメータに対応しています。

#### 情報パラメータ
- `BFI_Info_VersionMajor/Minor`: バージョン情報
- `BFI_Info_SecondsSinceLastUpdate`: 最終更新からの経過時間
- `BFI_Info_DeviceConnected`: デバイス接続状態
- `BFI_Info_BatterySupported/Level`: バッテリー情報

#### 神経フィードバック
- `BFI_NeuroFB_FocusLeft/Right/Avg`: 集中度（左/右/平均）
- `BFI_NeuroFB_RelaxLeft/Right/Avg`: リラックス度（左/右/平均）
- `BFI_NeuroFB_FocusLeftPos/RightPos/AvgPos`: 集中度位置情報
- `BFI_NeuroFB_RelaxLeftPos/RightPos/AvgPos`: リラックス度位置情報

#### パワーバンド
- `BFI_PwrBands_Left/Right/Avg_Gamma`: ガンマ波
- `BFI_PwrBands_Left/Right/Avg_Beta`: ベータ波
- `BFI_PwrBands_Left/Right/Avg_Alpha`: アルファ波
- `BFI_PwrBands_Left/Right/Avg_Theta`: シータ波
- `BFI_PwrBands_Left/Right/Avg_Delta`: デルタ波

#### 生体情報
- `BFI_Biometrics_HeartBeatsPerSecond/Minute`: 心拍数
- `BFI_Biometrics_OxygenPercent`: 血中酸素濃度
- `BFI_Biometrics_BreathsPerSecond/Minute`: 呼吸数
- `BFI_Biometrics_Supported`: 生体情報サポート状態

#### アドオン
- `BFI_Addons_HueShift`: 色相シフト（集中度/リラックス度）

## 使用方法

### 前提条件

1. [BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)のセットアップと実行
2. Unity 2021.3 LTS以上
3. VRChat SDK3

### 1. 基本セットアップ

1. UnityプロジェクトにEEG_Reactor_Systemフォルダをインポート
2. `EEG_Reactor_System/EEG_Animations/OSC_Animator.controller`をアニメーターに設定
3. 表示用オブジェクトに`EEG_Reactor_System/EEG_View/EEGView.shader`を適用

### 2. VRChat連携

1. `EEG_Reactor_System/Toolkit/OSCSender.prefab`をシーンに配置
2. VRChatOSCSenderコンポーネントの設定を調整
   - VRChat IP: `127.0.0.1`
   - VRChat Port: `9000`
3. BrainFlowsIntoVRChatから送信されるOSCデータを自動受信

**注意**: 本システムはBrainFlowsIntoVRChatのデータ出力を受信するため、別途BrainFlowsIntoVRChatの実行が必要です。

### 3. カスタマイズ

#### シェーダーパラメータ調整
- `_FrameRate`: 表示フレームレート
- `_GraphEnabled`: グラフ表示の有効/無効
- `_TextEnabled`: テキスト表示の有効/無効
- `_TextColor`: テキスト色
- `_BackgroundColor`: 背景色

#### フォントカスタマイズ
- `123font.png`を60x60ピクセルの12x4グリッド形式で作成
- 文字コードに応じて配置

## 技術仕様

### 対応Unityバージョン
- Unity 2021.3 LTS以上推奨
- URP/HDRP対応

### シェーダー要件
- HLSL 3.0以上
- テクスチャサポート
- レンダーテクスチャ対応

### OSC通信仕様
- プロトコル: UDP
- デフォルトポート: 9000
- エンコーディング: UTF-8

## 関連プロジェクト

### BrainFlowsIntoVRChat
- **リポジトリ**: [ChilloutCharles/BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)
- **役割**: PythonベースのEEGデータ処理とVRChatへのOSC送信
- **ライセンス**: MIT License
- **関係**: 本システムのデータ仕様の基盤となっているプロジェクト

## ライセンス

MIT License

```
MIT License

Copyright (c) 2024 E2G2

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 貢献

プルリクエストやイシューの報告を歓迎します。

## サポート

技術的な質問やサポートが必要な場合は、GitHubのIssuesページをご利用ください。

## 謝辞

- [ChilloutCharles](https://github.com/ChilloutCharles)氏による[BrainFlowsIntoVRChat](https://github.com/ChilloutCharles/BrainFlowsIntoVRChat)プロジェクトのパラメータ仕様定義
- BrainFlowsIntoVRChatコミュニティによる継続的な開発と改善

---

**注意**: このシステムは医療機器ではありません。VRChatでの学術・技術向けの使用を想定しています。 
