#ifndef EEG_TEXT_RENDERER_INCLUDED
#define EEG_TEXT_RENDERER_INCLUDED

// テキスト描画ライブラリ
// EEGView.shaderとEEGText.shaderで共有するテキスト描画機能

// テキスト描画用の構造体
struct TextRenderParams {
    float4 textColor;
    float4 backgroundColor;
    float textScale;
    float fontTexWidth;
    float fontTexHeight;
    int displayWidth;
    int displayHeight;
    sampler2D fontTex;
};

// GetFontUVのラッパー関数
float2 GetFontUV_VarSize(int fontIndex, float2 charLocalUV, float fontTexWidth, float fontTexHeight)
{
    uint charX = (uint)fontIndex % 12u;
    uint charY = (uint)fontIndex / 12u;
    float charWidth = 5.0 / fontTexWidth;
    float charHeight = 14.0 / fontTexHeight;
    float2 fontUV = float2(
        (charX * charWidth) + (charLocalUV.x * charWidth),
        1.0 - ((charY + 1) * charHeight) + (charLocalUV.y * charHeight)
    );
    return fontUV;
}

// テキスト領域の描画を行う関数
fixed4 RenderText(float2 uv, BFIData data, TextRenderParams params)
{
    // 文字の位置を計算
    int charX = (int)(uv.x * params.displayWidth);
    int charY = (int)(uv.y * params.displayHeight);

    // ディスプレイの範囲外の場合、背景色を表示
    if (charX >= params.displayWidth || charY >= params.displayHeight)
        return params.backgroundColor;

    // ディスプレイ上の位置に対応する文字コードを取得
    int charCode = GetDisplayCharacter(charX, charY, params.displayWidth, data);

    // 文字のUV座標を計算
    float2 charUV = frac(float2(uv.x * params.displayWidth, uv.y * params.displayHeight));

    // フォントテクスチャのUV座標を計算
    float2 fontUV = GetFontUV_VarSize(charCode, charUV, params.fontTexWidth, params.fontTexHeight);

    // フォントテクスチャをサンプリング
    fixed4 fontSample = tex2D(params.fontTex, fontUV);

    // 赤チャンネルをアルファマスクとして使用
    float alpha = fontSample.r;

    // テキスト色と背景色を合成
    return lerp(params.backgroundColor, params.textColor, alpha);
}

#endif // EEG_TEXT_RENDERER_INCLUDED 