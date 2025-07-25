Shader "E2G2/EEGFeedBack"
{
    Properties
    {
        [Header(EEGFeedBack)][Space]
        _FrameRate ("Frame Rate", Float) = 30.0

        // BrainFlowsIntoVRChat Parameters
        [Header(BrainFlowsIntoVRChat Parameters)][Space]
        _BFI_PwrBands_Avg_Gamma ("BFI/PwrBands/Avg/Gamma", Float) = 0
        _BFI_PwrBands_Avg_Beta ("BFI/PwrBands/Avg/Beta", Float) = 0
        _BFI_PwrBands_Avg_Alpha ("BFI/PwrBands/Avg/Alpha", Float) = 0
        _BFI_PwrBands_Avg_Theta ("BFI/PwrBands/Avg/Theta", Float) = 0
        _BFI_PwrBands_Avg_Delta ("BFI/PwrBands/Avg/Delta", Float) = 0
        _BFI_NeuroFB_FocusAvg ("BFI/NeuroFB/FocusAvg", Float) = 0
        _BFI_NeuroFB_RelaxAvg ("BFI/NeuroFB/RelaxAvg", Float) = 0
        _DebugType ("Debug Type", Float) = 0.0

        // Initialization
        [Header(Initialization)][Space]
        _InitializeBuffer ("Initialize Buffer", Float) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
            "Queue"="Overlay"
            "DisableBatching"="True"
        }
        LOD 200
        ZWrite Off
        ZTest Always
        Cull Off

        // GrabPassを使用して前のフレームのデータを取得
        GrabPass { "_EEGFeedBackBuffer" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "../EEG_Buffer/EEGBuffer.hlsl"
            #include "../EEG_Debug/EEGDebug.hlsl"

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

            // GrabPassで取得した前のフレームのデータ
            sampler2D _EEGFeedBackBuffer;
            float4 _EEGFeedBackBuffer_ST;

            // BrainFlowsIntoVRChat Parameters
            float _BFI_PwrBands_Avg_Gamma;
            float _BFI_PwrBands_Avg_Beta;
            float _BFI_PwrBands_Avg_Alpha;
            float _BFI_PwrBands_Avg_Theta;
            float _BFI_PwrBands_Avg_Delta;
            float _BFI_NeuroFB_FocusAvg;
            float _BFI_NeuroFB_RelaxAvg;
            float _DebugType;

            float _InitializeBuffer;
            float _FrameRate;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _EEGFeedBackBuffer);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 初期化バッファの描画
                if (_InitializeBuffer > 0.5 && i.uv.y < 0.5)
                {
                    return float4(1, 0, 0, 1);
                }

                // 時間ベースでフレームインデックスを計算
                int currentFrameIndex = GetCurrentFrameIndex(_FrameRate, _InitializeBuffer);

                // 現在のパワーバンドデータを取得（バリデーション付き）
                PowerBands currentBands = GetCurrentBands(
                    _BFI_PwrBands_Avg_Gamma,
                    _BFI_PwrBands_Avg_Beta,
                    _BFI_PwrBands_Avg_Alpha,
                    _BFI_PwrBands_Avg_Theta,
                    _BFI_PwrBands_Avg_Delta,
                    _BFI_NeuroFB_FocusAvg,
                    _BFI_NeuroFB_RelaxAvg,
                    _DebugType
                );

                // データの整合性をチェック
                float totalValue = currentBands.gamma + currentBands.beta + currentBands.alpha + currentBands.theta + currentBands.delta;
                bool hasNegativeValues = any(float4(currentBands.gamma, currentBands.beta, currentBands.alpha, currentBands.theta) < -0.001) || currentBands.delta < -0.001;
                bool hasInvalidValues = any(float4(currentBands.gamma, currentBands.beta, currentBands.alpha, currentBands.theta) > 1.001) || currentBands.delta > 1.001;
                bool hasNaNValues = any(isnan(float4(currentBands.gamma, currentBands.beta, currentBands.alpha, currentBands.theta))) || isnan(currentBands.delta);
                bool hasInfValues = any(isinf(float4(currentBands.gamma, currentBands.beta, currentBands.alpha, currentBands.theta))) || isinf(currentBands.delta);

                // 基本的なバリデーション（NaN、Inf、負の値のみチェック）
                if (hasNaNValues || hasInfValues || hasNegativeValues)
                {
                    // 無効なデータの場合は前のフレームのデータを保持
                    return tex2Dlod(_EEGFeedBackBuffer, float4(i.uv, 0.0, 0.0));
                }

                // 同期した書き込み関数を使用（GrabPassバッファを使用）
                float4 compressedData;
                compressedData = WriteSynchronizedFrameData(currentBands, currentFrameIndex, _EEGFeedBackBuffer, i.uv);

                // 同期した座標計算を使用
                bool isUpperHalf = i.uv.y < 0.5;
                bool isWritePos = IsSynchronizedWritePosition(i.uv, currentFrameIndex, isUpperHalf);

                if (isWritePos)
                {
                    // 書き込み位置の場合は圧縮データを返す
                    return compressedData;
                }
                else
                {
                    // 非書き込み位置の場合は前のフレームのデータを保持
                    return tex2Dlod(_EEGFeedBackBuffer, float4(i.uv, 0.0, 0.0));
                }
            }
            ENDCG
        }
    }
} 