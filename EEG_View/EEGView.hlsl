#ifndef EEG_VIEW_INCLUDED
#define EEG_VIEW_INCLUDED

// EEGグラフ描画ライブラリ
// 128フレーム分の履歴からグラフを描画（上半分・下半分方式対応）

// Buffer.hlslをインクルードしてHISTORY_FRAMESとPowerBands構造体を取得
#include "../EEG_Buffer/EEGBuffer.hlsl"
#include "../EEG_Debug/EEGDebug.hlsl"

// Define colors and settings for the graph
// グラフの色と設定を定義
#define GAMMA_COLOR float4(1.0, 0.2, 0.2, 1.0) // Red
#define BETA_COLOR  float4(0.2, 1.0, 0.2, 1.0) // Green
#define ALPHA_COLOR float4(0.2, 0.5, 1.0, 1.0) // Blue
#define THETA_COLOR float4(1.0, 1.0, 0.2, 1.0) // Yellow
#define DELTA_COLOR float4(1.0, 0.2, 1.0, 1.0) // Magenta
#define FOCUS_COLOR float4(1.0, 0.5, 0.0, 1.0) // Orange
#define RELAX_COLOR float4(0.0, 1.0, 1.0, 1.0) // Cyan
#define DEBUG_COLOR float4(0.5, 0.5, 0.5, 1.0) // Gray
#define GRAPH_BACKGROUND_COLOR float4(0.0, 0.0, 0.0, 0.0)
#define GRID_COLOR float4(0.0, 0.0, 0.0, 0.5)
#define GRID_LINE_THICKNESS 0.05
#define NUM_GRID_LINES 20.0

// 最適化された線グラフ描画関数
inline float4 DrawBandLine(float4 inputColor, float uv_y, int band_index, float currentValue, float previousValue, float4 bandColor)
{
    const float bandHeight = 0.25; // 4 bands in total
    const float lineThickness = 0.015; // 線の太さ

    float band_start_y = 1.0 - (band_index + 1) * bandHeight;

    if (uv_y >= band_start_y && uv_y < band_start_y + bandHeight)
    {
        float band_uv_y = (uv_y - band_start_y) / bandHeight;

        // 前の値と現在の値の間の線分を描画
        float value1 = clamp(previousValue, 0.0, 1.0);
        float value2 = clamp(currentValue, 0.0, 1.0);

        // 線分の距離を計算（最適化版）
        float valueDiff = value2 - value1;
        float t = (abs(valueDiff) > 0.001) ? clamp((band_uv_y - value1) / valueDiff, 0.0, 1.0) : 0.0;
        float closestPoint = lerp(value1, value2, t);
        float distance = abs(band_uv_y - closestPoint);

        if (distance < lineThickness)
        {
            return bandColor;
        }
    }
    return inputColor;
}

// 統合されたグラフ描画関数（上半分・下半分方式対応）
float4 DrawIntegratedGraph(float2 uv, sampler2D historyTex, int currentFrameIndex, float _FrameRate)
{
    float4 finalColor = GRAPH_BACKGROUND_COLOR;

    // グラフの横方向の位置を計算（0-1の範囲）
    float graphX = uv.x;

    // 最新フレームを左端に配置するため、フレーム順序を逆転
    for (int i = 0; i < HISTORY_FRAMES; i++)
    {
        // バッファが埋まるまで右端はDebugType=0.5のグラフ
        float filledFrames = _Time.y * _FrameRate;
        if (i > filledFrames)
        {
            // ここでDebugType=0.5のグラフ（例：グレー）を返す
            finalColor = float4(0.5, 0.5, 0.5, 1.0); // 例：グレー
            break;
        }

        // 最新フレーム（i=0）を左端に配置するため、フレーム順序を逆転
        int historyFrameIndex = (currentFrameIndex - i + HISTORY_FRAMES) % HISTORY_FRAMES;

        // 履歴データを読み取り（同期版を使用）
        PowerBands historyBands = ReadSynchronizedFrameData(historyTex, historyFrameIndex);

        // このフレームのグラフ位置を計算（最新フレームが左端）
        float frameX = (float)i / (float)(HISTORY_FRAMES - 1);

        // 現在のピクセルがこのフレームの範囲内かチェック
        float frameWidth = 1.0 / (float)(HISTORY_FRAMES - 1);
        if (graphX >= frameX - frameWidth * 0.5 && graphX <= frameX + frameWidth * 0.5)
        {
            // 前のフレームのデータを取得（線分描画用）
            PowerBands previousBands;
            if (i == 0)
            {
                // 最新のフレームの場合は現在のデータを使用
                previousBands = historyBands;
            }
            else
            {
                // 前のフレームのデータを取得（同期版を使用）
                int previousFrameIndex = (currentFrameIndex - i + 1 + HISTORY_FRAMES) % HISTORY_FRAMES;
                previousBands = ReadSynchronizedFrameData(historyTex, previousFrameIndex);
            }

            // パワーバンドを描画（band_index=3で統一）
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.gamma, previousBands.gamma, GAMMA_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.beta, previousBands.beta, BETA_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.alpha, previousBands.alpha, ALPHA_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.theta, previousBands.theta, THETA_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.delta, previousBands.delta, DELTA_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.focus, previousBands.focus, FOCUS_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.relax, previousBands.relax, RELAX_COLOR);
            finalColor = DrawBandLine(finalColor, uv.y, 3, historyBands.debug, previousBands.debug, DEBUG_COLOR);

            break;
        }
    }

    // 横方向のグリッド線を描画
    if (fmod(uv.y * NUM_GRID_LINES, 1.0) < GRID_LINE_THICKNESS) {
        finalColor = max(finalColor, GRID_COLOR);
    }

    return finalColor;
}

#endif // EEG_VIEW_INCLUDED