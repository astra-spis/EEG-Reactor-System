#ifndef EEG_COMPRESSION_HALF_TEXTURE_INCLUDED
#define EEG_COMPRESSION_HALF_TEXTURE_INCLUDED

// 上半分・下半分圧縮アルゴリズム（8変数対応、相対距離保持）
// 上半分: gamma, beta, alpha, theta
// 下半分: delta, focus, relax, debug
// focus, relaxは-1.0～1.0を0.0～1.0に正規化

#include "EEGTypes.hlsl"

// 上半分圧縮関数（gamma, beta, alpha, theta）
// 相対距離を保持するため、各ピクセルは独立した値を持つ
float4 CompressPowerBandsUpperHalf(PowerBands bands)
{
    // 各値を0-1の範囲に正規化
    float gamma_norm = clamp(bands.gamma, 0.0, 1.0);
    float beta_norm = clamp(bands.beta, 0.0, 1.0);
    float alpha_norm = clamp(bands.alpha, 0.0, 1.0);
    float theta_norm = clamp(bands.theta, 0.0, 1.0);

    // 上半分: gamma, beta, alpha, theta
    // 各チャンネルは独立した値を保持
    return float4(gamma_norm, beta_norm, alpha_norm, theta_norm);
}

// 下半分圧縮関数（delta, focus, relax, debug）
// 相対距離を保持するため、各ピクセルは独立した値を持つ
float4 CompressPowerBandsLowerHalf(PowerBands bands)
{
    // deltaを0-1の範囲に正規化
    float delta_norm = clamp(bands.delta, 0.0, 1.0);

    // focus, relaxを-1.0～1.0から0.0～1.0に正規化
    float focus_norm = clamp((bands.focus + 1.0) * 0.5, 0.0, 1.0);
    float relax_norm = clamp((bands.relax + 1.0) * 0.5, 0.0, 1.0);

    // debugを0-1の範囲に正規化
    float debug_norm = clamp(bands.debug, 0.0, 1.0);

    // 下半分: delta, focus, relax, debug
    // 各チャンネルは独立した値を保持
    return float4(delta_norm, focus_norm, relax_norm, debug_norm);
}

// 完全な上半分・下半分復元関数（相対距離保持対応）
PowerBands DecompressPowerBandsHalfTexture(float4 upperHalf, float4 lowerHalf)
{
    PowerBands bands;

    // 上半分から復元（各チャンネルは独立）
    bands.gamma = upperHalf.r;
    bands.beta = upperHalf.g;
    bands.alpha = upperHalf.b;
    bands.theta = upperHalf.a;

    // 下半分から復元（各チャンネルは独立）
    bands.delta = lowerHalf.r;

    // focus, relaxを0.0～1.0のまま出力（グラフ描画用）
    bands.focus = lowerHalf.g;  // 0.0～1.0のまま
    bands.relax = lowerHalf.b;  // 0.0～1.0のまま

    bands.debug = lowerHalf.a;

    return bands;
}

#endif // EEG_COMPRESSION_HALF_TEXTURE_INCLUDED