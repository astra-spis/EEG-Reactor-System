#ifndef EEG_BUFFER_INCLUDED
#define EEG_BUFFER_INCLUDED

// EEGデータのバッファ処理ライブラリ
// パワーバンドデータの圧縮・展開とFIFO処理を提供

// FIFO設定
#define HISTORY_FRAMES 128  // 総フレーム数: 128フレーム
#define FRAMES_PER_ROW 16  // 横分割数 : 16
#define FRAMES_PER_COLUMN 8  // 縦分割数 : 8

// データ型定義をインクルード
#include "EEGTypes.hlsl"
#include "EEGCompression_HalfTexture.hlsl"

// --- 時間ベースのフレームインデックス計算 ---
// アバターギミック対応のため、時間からフレームインデックスを計算

// 時間からフレームインデックスを計算する関数（安定化版）
int GetFrameIndexFromTime(float time, float frameRate, float initializeBuffer)
{
    // 初期化バッファの描画
    if (initializeBuffer > 0.5)
        return 0;

    // フレームレートに基づいてフレームインデックスを計算
    // 初期フレームでの安定性を向上させるため、最小値を設定
    float minTime = 0.1; // 最小時間を設定
    float adjustedTime = max(time, minTime);

    // フレームインデックスを計算（安定化版）
    int frameIndex = (int)(adjustedTime * frameRate) % HISTORY_FRAMES;

    // 初期フレームでの予測可能な動作を確保
    // 時間が短い場合は0から開始するように調整
    if (time < 0.5)
    {
        // 初期フレームでは0から開始
        frameIndex = 0;
    }

    return frameIndex;
}

// Unity時間からフレームインデックスを取得（安定化版）
int GetCurrentFrameIndex(float frameRate, float initializeBuffer)
{
    // _Time.yはUnityの時間（秒）
    if (initializeBuffer > 0.5)
        return 0;
    return GetFrameIndexFromTime(_Time.y, frameRate, initializeBuffer);
}

// 上半分・下半分同期書き込み位置判定
bool IsSynchronizedWritePosition(float2 uv, int frameIndex, bool isUpperHalf)
{
    // 16×8のグリッドでフレーム位置を計算
    int frameX = frameIndex % FRAMES_PER_ROW;
    int frameY = frameIndex / FRAMES_PER_ROW;

    // Y座標の調整（上半分: 0-7, 下半分: 8-15）
    if (isUpperHalf)
    {
        frameY = frameY % FRAMES_PER_COLUMN;
    }
    else
    {
        frameY = (frameY % FRAMES_PER_COLUMN) + FRAMES_PER_COLUMN;
    }

    // フレームの中心座標を計算
    float2 framePos = float2(
        (float)frameX / (float)FRAMES_PER_ROW + 0.5 / (float)FRAMES_PER_ROW,
        (float)frameY / 16.0 + 0.5 / 16.0  // 16×16テクスチャのY座標
    );

    // フレームの範囲を計算
    float frameSizeX = 1.0 / (float)FRAMES_PER_ROW;
    float frameSizeY = 1.0 / 16.0;
    float2 frameStart = framePos - float2(frameSizeX, frameSizeY) * 0.5;
    float2 frameEnd = framePos + float2(frameSizeX, frameSizeY) * 0.5;

    // UV座標がフレーム範囲内かチェック
    return (uv.x >= frameStart.x && uv.x <= frameEnd.x &&
            uv.y >= frameStart.y && uv.y <= frameEnd.y);
}

// 上半分・下半分同期書き込み関数
float4 WriteSynchronizedFrameData(PowerBands bands, int frameIndex, sampler2D bufferTex, float2 uv)
{
    // 上半分と下半分で同じフレームインデックスを使用
    bool isUpperHalf = uv.y < 0.5;

    // 同期した書き込み位置判定
    if (IsSynchronizedWritePosition(uv, frameIndex, isUpperHalf))
    {
        if (isUpperHalf)
        {
            // 上半分: gamma, beta, alpha, theta
            return CompressPowerBandsUpperHalf(bands);
        }
        else
        {
            // 下半分: delta, focus, relax, debug
            return CompressPowerBandsLowerHalf(bands);
        }
    }
    else
    {
        // 書き込み位置以外は既存のデータを保持
        return tex2Dlod(bufferTex, float4(uv, 0.0, 0.0));
    }
}

// 現在のパワーバンドデータを取得する関数（8変数対応、バリデーション付き）
PowerBands GetCurrentBands(float gamma, float beta, float alpha, float theta, float delta, float focus, float relax, float debug)
{
    PowerBands bands;

    // 入力値のバリデーション
    bands.gamma = clamp(gamma, 0.0, 1.0);
    bands.beta = clamp(beta, 0.0, 1.0);
    bands.alpha = clamp(alpha, 0.0, 1.0);
    bands.theta = clamp(theta, 0.0, 1.0);
    bands.delta = clamp(delta, 0.0, 1.0);

    // focus, relaxは-1.0～1.0の範囲を保持
    bands.focus = clamp(focus, -1.0, 1.0);
    bands.relax = clamp(relax, -1.0, 1.0);
    bands.debug = clamp(debug, 0.0, 1.0);

    return bands;
}

// 同期したデータ読み取り関数
PowerBands ReadSynchronizedFrameData(sampler2D historyTex, int frameIndex)
{
    // 16×8のグリッドでフレーム位置を計算
    int frameX = frameIndex % FRAMES_PER_ROW;
    int frameY = frameIndex / FRAMES_PER_ROW;

    // 上半分と下半分の座標を計算
    float2 upperPos = float2(
        (float)frameX / (float)FRAMES_PER_ROW + 0.5 / (float)FRAMES_PER_ROW,
        (float)(frameY % FRAMES_PER_COLUMN) / 16.0 + 0.5 / 16.0
    );

    float2 lowerPos = float2(
        (float)frameX / (float)FRAMES_PER_ROW + 0.5 / (float)FRAMES_PER_ROW,
        (float)((frameY % FRAMES_PER_COLUMN) + FRAMES_PER_COLUMN) / 16.0 + 0.5 / 16.0
    );

    // 上半分と下半分からデータを読み取り
    float4 upperData = tex2Dlod(historyTex, float4(upperPos, 0.0, 0.0));
    float4 lowerData = tex2Dlod(historyTex, float4(lowerPos, 0.0, 0.0));

    return DecompressPowerBandsHalfTexture(upperData, lowerData);
}

#endif // EEG_BUFFER_INCLUDED