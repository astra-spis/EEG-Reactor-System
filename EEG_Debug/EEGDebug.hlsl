#ifndef EEG_DEBUG_INCLUDED
#define EEG_DEBUG_INCLUDED

// EEGデバッグ機能ライブラリ
#include "../EEG_Buffer/EEGBuffer.hlsl"

// 共通: 履歴フレームのUV座標を計算
void GetDebugFrameUVs(int historyFrameIndex, out float2 upperUV, out float2 lowerUV) {
    int frameX = historyFrameIndex % 16;
    int frameY = historyFrameIndex / 16;
    upperUV = float2((float)frameX / 16.0 + 0.5 / 16.0, (float)(frameY % 8) / 16.0 + 0.5 / 16.0);
    lowerUV = float2((float)frameX / 16.0 + 0.5 / 16.0, (float)((frameY % 8) + 8) / 16.0 + 0.5 / 16.0);
}

// データ読み取り状況
float4 DrawDebugGraph(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    PowerBands historyBands = ReadSynchronizedFrameData(historyTex, historyFrameIndex);
    float totalValue = historyBands.gamma + historyBands.beta + historyBands.alpha + historyBands.theta + historyBands.delta;
    return (totalValue > 0.001) ? float4(historyBands.gamma, historyBands.beta, historyBands.alpha, 1.0) : float4(0,0,0,1);
}

// 書き込み座標デバッグ
float4 DrawCoordinateDebug(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    bool isUpperHalf = uv.y < 0.5;
    bool isWritePos = IsSynchronizedWritePosition(uv, currentFrameIndex, isUpperHalf);
    return isWritePos ? float4(1,0,0,1) : float4(0,0,1,1);
}

// 圧縮データの生値（上半分）
float4 DrawRawDataDebug(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    float2 upperUV, lowerUV; GetDebugFrameUVs(historyFrameIndex, upperUV, lowerUV);
    return tex2Dlod(historyTex, float4(upperUV, 0, 0));
}

// 圧縮データのRGB（上半分）
float4 DrawCompressionDebug(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    float2 upperUV, lowerUV; GetDebugFrameUVs(historyFrameIndex, upperUV, lowerUV);
    float4 upperData = tex2Dlod(historyTex, float4(upperUV, 0, 0));
    return float4(upperData.rgb, 1.0);
}

// 復元データのRGB
float4 DrawDecompressionDebug(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    PowerBands bands = ReadSynchronizedFrameData(historyTex, historyFrameIndex);
    return float4(bands.gamma, bands.beta, bands.alpha, 1.0);
}

// バリデーション結果
float4 DrawValidationDebug(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    PowerBands bands = ReadSynchronizedFrameData(historyTex, historyFrameIndex);
    float totalValue = bands.gamma + bands.beta + bands.alpha + bands.theta + bands.delta;
    bool hasNegative = any(float4(bands.gamma, bands.beta, bands.alpha, bands.theta) < -0.001) || bands.delta < -0.001;
    bool hasInvalid = any(float4(bands.gamma, bands.beta, bands.alpha, bands.theta) > 1.001) || bands.delta > 1.001;
    bool hasNaN = any(isnan(float4(bands.gamma, bands.beta, bands.alpha, bands.theta))) || isnan(bands.delta);
    bool hasInf = any(isinf(float4(bands.gamma, bands.beta, bands.alpha, bands.theta))) || isinf(bands.delta);
    bool hasInvalidFocus = bands.focus < -1.001 || bands.focus > 1.001;
    bool hasInvalidRelax = bands.relax < -1.001 || bands.relax > 1.001;
    bool hasInvalidDebug = bands.debug < -0.001 || bands.debug > 1.001;
    if (totalValue < -0.001) return float4(1,0,0,1);
    if (hasNegative) return float4(1,1,0,1);
    if (hasInvalid) return float4(1,0,1,1);
    if (hasNaN) return float4(0,1,1,1);
    if (hasInf) return float4(0.5,0.5,0.5,1);
    if (hasInvalidFocus || hasInvalidRelax || hasInvalidDebug) return float4(1,0.5,0,1);
    return float4(0,1,0,1);
}

// 圧縮データの詳細分析
float4 DrawCompressionAnalysis(float2 uv, sampler2D historyTex, int currentFrameIndex) {
    int frameIndex = clamp((int)(uv.x * (HISTORY_FRAMES - 1)), 0, HISTORY_FRAMES - 1);
    int historyFrameIndex = (currentFrameIndex - frameIndex + HISTORY_FRAMES) % HISTORY_FRAMES;
    float2 upperUV, lowerUV; GetDebugFrameUVs(historyFrameIndex, upperUV, lowerUV);
    float4 upperData = tex2Dlod(historyTex, float4(upperUV, 0, 0));
    float4 lowerData = tex2Dlod(historyTex, float4(lowerUV, 0, 0));
    bool hasUpper = (upperData.r > 0.0 || upperData.g > 0.0 || upperData.b > 0.0 || upperData.a > 0.0);
    bool hasLower = (lowerData.r > 0.0 || lowerData.g > 0.0 || lowerData.b > 0.0 || lowerData.a > 0.0);
    bool isUpperNorm = all(upperData >= 0.0 && upperData <= 1.0);
    bool isLowerNorm = all(lowerData >= 0.0 && lowerData <= 1.0);
    if (!hasUpper && !hasLower) return float4(0,0,0,1);
    if (!isUpperNorm || !isLowerNorm) return float4(1,1,0,1);
    return float4(0,1,0,1);
}

#endif // EEG_DEBUG_INCLUDED