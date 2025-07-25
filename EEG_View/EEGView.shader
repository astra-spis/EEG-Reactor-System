Shader "E2G2/EEGView"
{
    Properties
    {
        [Header(EEGView)][Space]
        _Buffer ("Buffer", 2D) = "white" {}
        _FrameRate ("Frame Rate", Float) = 30.0
        _GraphEnabled ("Graph Enabled", Float) = 1.0
        _TextEnabled ("Text Enabled", Float) = 1.0
        _TextColor ("Text Color", Color) = (1,1,1,1)
        _TextScale ("Text Scale", Float) = 1.0
        _BackgroundColor ("Background Color", Color) = (0,0,0,0)
        _FontTex ("Font Texture (60x60, 12x4 grid)", 2D) = "white" {}
        _FontTexWidth ("Font Texture Width (px)", Float) = 60
        _FontTexHeight ("Font Texture Height (px)", Float) = 60
        _TextAreaWidth ("Text Area Width", Range(0.0, 1.0)) = 0.5

        // BrainFlowsIntoVRChat Parameters
        [Header(BrainFlowsIntoVRChat Parameters)][Space]
        _BFI_Info_VersionMajor ("BFI/Info/VersionMajor", Int) = 0
        _BFI_Info_VersionMinor ("BFI/Info/VersionMinor", Int) = 0
        _BFI_Info_SecondsSinceLastUpdate ("BFI/Info/SecondsSinceLastUpdate", Float) = 0
        _BFI_Info_DeviceConnected ("BFI/Info/DeviceConnected", Float) = 0
        _BFI_Info_BatterySupported ("BFI/Info/BatterySupported", Float) = 0
        _BFI_Info_BatteryLevel ("BFI/Info/BatteryLevel", Float) = 0

        _BFI_NeuroFB_FocusLeft ("BFI/NeuroFB/FocusLeft", Float) = 0
        _BFI_NeuroFB_FocusLeftPos ("BFI/NeuroFB/FocusLeftPos", Float) = 0
        _BFI_NeuroFB_FocusRight ("BFI/NeuroFB/FocusRight", Float) = 0
        _BFI_NeuroFB_FocusRightPos ("BFI/NeuroFB/FocusRightPos", Float) = 0
        _BFI_NeuroFB_FocusAvg ("BFI/NeuroFB/FocusAvg", Float) = 0
        _BFI_NeuroFB_FocusAvgPos ("BFI/NeuroFB/FocusAvgPos", Float) = 0
        _BFI_NeuroFB_RelaxLeft ("BFI/NeuroFB/RelaxLeft", Float) = 0
        _BFI_NeuroFB_RelaxLeftPos ("BFI/NeuroFB/RelaxLeftPos", Float) = 0
        _BFI_NeuroFB_RelaxRight ("BFI/NeuroFB/RelaxRight", Float) = 0
        _BFI_NeuroFB_RelaxRightPos ("BFI/NeuroFB/RelaxRightPos", Float) = 0
        _BFI_NeuroFB_RelaxAvg ("BFI/NeuroFB/RelaxAvg", Float) = 0
        _BFI_NeuroFB_RelaxAvgPos ("BFI/NeuroFB/RelaxAvgPos", Float) = 0

        _BFI_PwrBands_Left_Gamma ("BFI/PwrBands/Left/Gamma", Float) = 0
        _BFI_PwrBands_Left_Beta ("BFI/PwrBands/Left/Beta", Float) = 0
        _BFI_PwrBands_Left_Alpha ("BFI/PwrBands/Left/Alpha", Float) = 0
        _BFI_PwrBands_Left_Theta ("BFI/PwrBands/Left/Theta", Float) = 0
        _BFI_PwrBands_Left_Delta ("BFI/PwrBands/Left/Delta", Float) = 0

        _BFI_PwrBands_Right_Gamma ("BFI/PwrBands/Right/Gamma", Float) = 0
        _BFI_PwrBands_Right_Beta ("BFI/PwrBands/Right/Beta", Float) = 0
        _BFI_PwrBands_Right_Alpha ("BFI/PwrBands/Right/Alpha", Float) = 0
        _BFI_PwrBands_Right_Theta ("BFI/PwrBands/Right/Theta", Float) = 0
        _BFI_PwrBands_Right_Delta ("BFI/PwrBands/Right/Delta", Float) = 0

        _BFI_PwrBands_Avg_Gamma ("BFI/PwrBands/Avg/Gamma", Float) = 0
        _BFI_PwrBands_Avg_Beta ("BFI/PwrBands/Avg/Beta", Float) = 0
        _BFI_PwrBands_Avg_Alpha ("BFI/PwrBands/Avg/Alpha", Float) = 0
        _BFI_PwrBands_Avg_Theta ("BFI/PwrBands/Avg/Theta", Float) = 0
        _BFI_PwrBands_Avg_Delta ("BFI/PwrBands/Avg/Delta", Float) = 0

        _BFI_Addons_HueShift ("BFI/Addons/HueShift", Float) = 0

        _BFI_Biometrics_Supported ("BFI/Biometrics/Supported", Float) = 0
        _BFI_Biometrics_HeartBeatsPerSecond ("BFI/Biometrics/HeartBeatsPerSecond", Float) = 0
        _BFI_Biometrics_HeartBeatsPerMinute ("BFI/Biometrics/HeartBeatsPerMinute", Int) = 0
        _BFI_Biometrics_OxygenPercent ("BFI/Biometrics/OxygenPercent", Float) = 0
        _BFI_Biometrics_BreathsPerSecond ("BFI/Biometrics/BreathsPerSecond", Float) = 0
        _BFI_Biometrics_BreathsPerMinute ("BFI/Biometrics/BreathsPerMinute", Int) = 0

        // Display configuration
        [Header(Display Configuration)][Space]
        _DisplayWidth ("Display Width (Characters)", Int) = 32
        _DisplayHeight ("Display Height (Characters)", Int) = 8

        // Debug
        [Header(Debug)][Space]
        _DebugMode ("Debug Mode", Float) = 0.0

        // Initialization
        [Header(Initialization)][Space]
        _InitializeBuffer ("Initialize Buffer", Float) = 0.0
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
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "EEGView.hlsl"
            #include "../EEG_Buffer/EEGBuffer.hlsl"
            #include "../EEG_Text/EEGTextEncoder.hlsl"
            #include "../EEG_Text/EEGTextRenderer.hlsl"
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

            sampler2D _Buffer;
            sampler2D _FontTex;
            float4 _Buffer_ST;
            float4 _FontTex_ST;

            float _FrameRate;
            float _GraphEnabled;
            float _TextEnabled;
            float4 _TextColor;
            float _TextScale;
            float4 _BackgroundColor;
            float _FontTexWidth;
            float _FontTexHeight;
            float _TextAreaWidth;
            float _DebugMode;

            // BrainFlowsIntoVRChat Parameters
            int _BFI_Info_VersionMajor, _BFI_Info_VersionMinor;
            float _BFI_Info_SecondsSinceLastUpdate, _BFI_Info_DeviceConnected, _BFI_Info_BatterySupported, _BFI_Info_BatteryLevel;

            float _BFI_NeuroFB_FocusLeft, _BFI_NeuroFB_FocusLeftPos, _BFI_NeuroFB_FocusRight, _BFI_NeuroFB_FocusRightPos, _BFI_NeuroFB_FocusAvg, _BFI_NeuroFB_FocusAvgPos;
            float _BFI_NeuroFB_RelaxLeft, _BFI_NeuroFB_RelaxLeftPos, _BFI_NeuroFB_RelaxRight, _BFI_NeuroFB_RelaxRightPos, _BFI_NeuroFB_RelaxAvg, _BFI_NeuroFB_RelaxAvgPos;

            float _BFI_PwrBands_Left_Gamma, _BFI_PwrBands_Left_Beta, _BFI_PwrBands_Left_Alpha, _BFI_PwrBands_Left_Theta, _BFI_PwrBands_Left_Delta;
            float _BFI_PwrBands_Right_Gamma, _BFI_PwrBands_Right_Beta, _BFI_PwrBands_Right_Alpha, _BFI_PwrBands_Right_Theta, _BFI_PwrBands_Right_Delta;
            float _BFI_PwrBands_Avg_Gamma, _BFI_PwrBands_Avg_Beta, _BFI_PwrBands_Avg_Alpha, _BFI_PwrBands_Avg_Theta, _BFI_PwrBands_Avg_Delta;
            float _BFI_Addons_HueShift;
            float _BFI_Biometrics_Supported, _BFI_Biometrics_HeartBeatsPerSecond, _BFI_Biometrics_HeartBeatsPerMinute, _BFI_Biometrics_OxygenPercent;
            int _BFI_Biometrics_BreathsPerSecond, _BFI_Biometrics_BreathsPerMinute;

            int _DisplayWidth;
            int _DisplayHeight;

            float _InitializeBuffer;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Buffer);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // テキスト描画用のパラメータを設定
                TextRenderParams textParams;
                textParams.textColor = _TextColor;
                textParams.backgroundColor = _BackgroundColor;
                textParams.textScale = _TextScale;
                textParams.fontTexWidth = _FontTexWidth;
                textParams.fontTexHeight = _FontTexHeight;
                textParams.displayWidth = _DisplayWidth;
                textParams.displayHeight = _DisplayHeight;
                textParams.fontTex = _FontTex;

                // 脳波データを構造体に格納
                BFIData bfiData = GetBFIData(
                    _BFI_Info_VersionMajor, _BFI_Info_VersionMinor, _BFI_Info_SecondsSinceLastUpdate, _BFI_Info_DeviceConnected, _BFI_Info_BatterySupported, _BFI_Info_BatteryLevel,
                    _BFI_NeuroFB_FocusLeft, _BFI_NeuroFB_FocusLeftPos, _BFI_NeuroFB_FocusRight, _BFI_NeuroFB_FocusRightPos, _BFI_NeuroFB_FocusAvg, _BFI_NeuroFB_FocusAvgPos,
                    _BFI_NeuroFB_RelaxLeft, _BFI_NeuroFB_RelaxLeftPos, _BFI_NeuroFB_RelaxRight, _BFI_NeuroFB_RelaxRightPos, _BFI_NeuroFB_RelaxAvg, _BFI_NeuroFB_RelaxAvgPos,
                    _BFI_PwrBands_Left_Gamma, _BFI_PwrBands_Left_Beta, _BFI_PwrBands_Left_Alpha, _BFI_PwrBands_Left_Theta, _BFI_PwrBands_Left_Delta,
                    _BFI_PwrBands_Right_Gamma, _BFI_PwrBands_Right_Beta, _BFI_PwrBands_Right_Alpha, _BFI_PwrBands_Right_Theta, _BFI_PwrBands_Right_Delta,
                    _BFI_PwrBands_Avg_Gamma, _BFI_PwrBands_Avg_Beta, _BFI_PwrBands_Avg_Alpha, _BFI_PwrBands_Avg_Theta, _BFI_PwrBands_Avg_Delta,
                    _BFI_Addons_HueShift,
                    _BFI_Biometrics_Supported, _BFI_Biometrics_HeartBeatsPerSecond, _BFI_Biometrics_HeartBeatsPerMinute, _BFI_Biometrics_OxygenPercent,
                    _BFI_Biometrics_BreathsPerSecond, _BFI_Biometrics_BreathsPerMinute
                );

                // テキスト領域とグラフ領域の配置を決定
                // グラフが右側にある場合は左側に配置する
                if (i.uv.x < _TextAreaWidth && _TextEnabled > 0.5)
                {
                    // テキスト領域の処理（左側）
                    float2 textUV = float2(i.uv.x / _TextAreaWidth, i.uv.y);
                    return RenderText(textUV, bfiData, textParams);
                }
                else if (_GraphEnabled > 0.5)
                {
                    // グラフ領域の処理（右側）
                    float2 graphUV = float2((i.uv.x - _TextAreaWidth) / (1.0 - _TextAreaWidth), i.uv.y);

                    // 時間ベースでフレームインデックスを計算
                    int currentFrameIndex = GetCurrentFrameIndex(_FrameRate, _InitializeBuffer);

                    // デバッグモードの処理
                    if (_DebugMode > 0.1)
                    {
                        // デバッグタイプに応じて異なるデバッグ機能を実行
                        if (_DebugMode < 0.2)
                        {
                            // データ読み取り状況を確認
                            return DrawDebugGraph(graphUV, _Buffer, currentFrameIndex);
                        }
                        else if (_DebugMode < 0.3)
                        {
                            // 座標計算の整合性を確認
                            return DrawCoordinateDebug(graphUV, _Buffer, currentFrameIndex);
                        }
                        else if (_DebugMode < 0.4)
                        {
                            // 圧縮データの生の値を確認
                            return DrawRawDataDebug(graphUV, _Buffer, currentFrameIndex);
                        }
                        else if (_DebugMode < 0.5)
                        {
                            // 圧縮・復元アルゴリズムの詳細確認
                            return DrawCompressionDebug(graphUV, _Buffer, currentFrameIndex);
                        }
                        else if (_DebugMode < 0.6)
                        {
                            // 復元アルゴリズムの詳細確認
                            return DrawDecompressionDebug(graphUV, _Buffer, currentFrameIndex);
                        }
                        else if (_DebugMode < 0.7)
                        {
                            // バリデーション結果の確認
                            return DrawValidationDebug(graphUV, _Buffer, currentFrameIndex);
                        }
                        else
                        {
                            // 圧縮データの詳細分析
                            return DrawCompressionAnalysis(graphUV, _Buffer, currentFrameIndex);
                        }
                    }
                    else
                    {
                        // グラフ描画
                        return DrawIntegratedGraph(graphUV, _Buffer, currentFrameIndex, _FrameRate);
                    }
                }
                else
                {
                    // グラフが無効な場合は透明を返す
                    return float4(0, 0, 0, 0);
                }
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}