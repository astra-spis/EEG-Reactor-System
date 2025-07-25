Shader "E2G2/EEGText"
{
    Properties
    {
        _FontTex ("Font Texture (60x60, 12x4 grid)", 2D) = "white" {}
        _FontTexWidth ("Font Texture Width (px)", Float) = 60
        _FontTexHeight ("Font Texture Height (px)", Float) = 60
        _TextColor ("Text Color", Color) = (1,1,1,1)
        _TextScale ("Text Scale", Float) = 1.0
        _BackgroundColor ("Background Color", Color) = (0,0,0,0)
        _TextEnabled ("Text Enabled", Float) = 1.0

        // Display configuration
        _DisplayWidth ("Display Width (Characters)", Int) = 32
        _DisplayHeight ("Display Height (Characters)", Int) = 8
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "DisableBatching"="True"
        }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest Always
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "EEGTextEncoder.hlsl"
            #include "EEGTextRenderer.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _FontTex;
            float4 _FontTex_ST;

            float _TextEnabled;
            float4 _TextColor;
            float _TextScale;
            float4 _BackgroundColor;
            float _FontTexWidth;
            float _FontTexHeight;
            int _DisplayWidth;
            int _DisplayHeight;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _FontTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                if (_TextEnabled > 0.5)
                {
                    // テキスト描画用のパラメータを設定
                    TextRenderParams params;
                    params.textColor = _TextColor;
                    params.backgroundColor = _BackgroundColor;
                    params.textScale = _TextScale;
                    params.fontTexWidth = _FontTexWidth;
                    params.fontTexHeight = _FontTexHeight;
                    params.displayWidth = _DisplayWidth;
                    params.displayHeight = _DisplayHeight;
                    params.fontTex = _FontTex;

                    // ダミーのBFIData（テキスト専用シェーダーなので実際のデータは使用しない）
                    BFIData dummyData = GetBFIData(
                        0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0,
                        0,
                        0, 0, 0, 0,
                        0, 0
                    );

                    // テキスト描画処理
                    return RenderText(i.uv, dummyData, params);
                }
                else
                {
                    // テキストが無効な場合は透明を返す
                    return float4(0, 0, 0, 0);
                }
            }
            ENDCG
        }
    }
}