#ifndef OSC_TEXT_ENCODER_INCLUDED
#define OSC_TEXT_ENCODER_INCLUDED

// OSCTextEncoder.cginc
// シェーダーで使用するVRChat互換のテキストエンコード関数

// Character mapping for 48-character font (12x4 grid), reference image : 123font.png
// Row 0: 0-9, ., -
// Row 1: A-L
// Row 2: M-X
// Row 3: Y, Z, Γ, Δ, Θ, /, コロン, バッテリー記号, デバイス記号, ブレス記号, 心拍数記号, [space]
// 0-9: 数字（0-9）
// 10: ピリオド（.）
// 11: ハイフン（-）
// 12-37: アルファベット（A-Z）
// 38-40: ギリシャ文字（Γ、Δ、Θ）
// 41: スラッシュ（/）
// 42: コロン（:）
// 43: バッテリー記号
// 44: デバイス記号
// 45: ブレス記号
// 46: 心拍数記号
// 47: スペース

// --- 構造体定義 ---
struct BFIInfo {
    int versionMajor;
    int versionMinor;
    float secondsSinceLastUpdate;
    float deviceConnected;
    float batterySupported;
    float batteryLevel;
};

struct BFINeuroFeedback {
    float focusLeft;
    float focusLeftPos;
    float focusRight;
    float focusRightPos;
    float focusAvg;
    float focusAvgPos;
    float relaxLeft;
    float relaxLeftPos;
    float relaxRight;
    float relaxRightPos;
    float relaxAvg;
    float relaxAvgPos;
};

struct BFIPowerBands {
    float leftGamma, leftBeta, leftAlpha, leftTheta, leftDelta;
    float rightGamma, rightBeta, rightAlpha, rightTheta, rightDelta;
    float avgGamma, avgBeta, avgAlpha, avgTheta, avgDelta;
};

struct BFIAddons {
    float hueShift;
};

struct BFIBiometrics {
    float supported;
    float heartBeatsPerSecond;
    float heartBeatsPerMinute;
    float oxygenPercent;
    int breathsPerSecond;
    int breathsPerMinute;
};

struct BFIData {
    BFIInfo info;
    BFINeuroFeedback neuroFB;
    BFIPowerBands powerBands;
    BFIAddons addons;
    BFIBiometrics biometrics;
};

// --- 初期化関数 ---
BFIData GetBFIData(
    int versionMajor, int versionMinor, float secondsSinceLastUpdate, float deviceConnected, float batterySupported, float batteryLevel,
    float focusLeft, float focusLeftPos, float focusRight, float focusRightPos, float focusAvg, float focusAvgPos,
    float relaxLeft, float relaxLeftPos, float relaxRight, float relaxRightPos, float relaxAvg, float relaxAvgPos,
    float leftGamma, float leftBeta, float leftAlpha, float leftTheta, float leftDelta,
    float rightGamma, float rightBeta, float rightAlpha, float rightTheta, float rightDelta,
    float avgGamma, float avgBeta, float avgAlpha, float avgTheta, float avgDelta,
    float hueShift,
    float biometricsSupported, float heartBeatsPerSecond, float heartBeatsPerMinute, float oxygenPercent,
    int breathsPerSecond, int breathsPerMinute)
{
    BFIData data;
    data.info.versionMajor = versionMajor;
    data.info.versionMinor = versionMinor;
    data.info.secondsSinceLastUpdate = secondsSinceLastUpdate;
    data.info.deviceConnected = deviceConnected;
    data.info.batterySupported = batterySupported;
    data.info.batteryLevel = batteryLevel;

    data.neuroFB.focusLeft = focusLeft;
    data.neuroFB.focusLeftPos = focusLeftPos;
    data.neuroFB.focusRight = focusRight;
    data.neuroFB.focusRightPos = focusRightPos;
    data.neuroFB.focusAvg = focusAvg;
    data.neuroFB.focusAvgPos = focusAvgPos;
    data.neuroFB.relaxLeft = relaxLeft;
    data.neuroFB.relaxLeftPos = relaxLeftPos;
    data.neuroFB.relaxRight = relaxRight;
    data.neuroFB.relaxRightPos = relaxRightPos;
    data.neuroFB.relaxAvg = relaxAvg;
    data.neuroFB.relaxAvgPos = relaxAvgPos;

    data.powerBands.leftGamma = leftGamma;
    data.powerBands.leftBeta = leftBeta;
    data.powerBands.leftAlpha = leftAlpha;
    data.powerBands.leftTheta = leftTheta;
    data.powerBands.leftDelta = leftDelta;
    data.powerBands.rightGamma = rightGamma;
    data.powerBands.rightBeta = rightBeta;
    data.powerBands.rightAlpha = rightAlpha;
    data.powerBands.rightTheta = rightTheta;
    data.powerBands.rightDelta = rightDelta;
    data.powerBands.avgGamma = avgGamma;
    data.powerBands.avgBeta = avgBeta;
    data.powerBands.avgAlpha = avgAlpha;
    data.powerBands.avgTheta = avgTheta;
    data.powerBands.avgDelta = avgDelta;

    data.addons.hueShift = hueShift;

    data.biometrics.supported = biometricsSupported;
    data.biometrics.heartBeatsPerSecond = heartBeatsPerSecond;
    data.biometrics.heartBeatsPerMinute = heartBeatsPerMinute;
    data.biometrics.oxygenPercent = oxygenPercent;
    data.biometrics.breathsPerSecond = breathsPerSecond;
    data.biometrics.breathsPerMinute = breathsPerMinute;
    return data;
}

// Get character for display position using BrainFlowsIntoVRChat parameters
// This function processes the parameters and generates formatted text
int GetDisplayCharacter(int x, int y, int displayWidth, BFIData data)
{
    // Default return value to ensure variable is always initialized
    int result = 47; // Space character as default

    // --- 追加: 値の四捨五入処理 ---
    // -1.0~1.0, 小数第二位以降四捨五入
    float focusLeftR = round(data.neuroFB.focusLeft * 100.0) / 100.0;
    float focusRightR = round(data.neuroFB.focusRight * 100.0) / 100.0;
    float focusAvgR = round(data.neuroFB.focusAvg * 100.0) / 100.0;
    float relaxLeftR = round(data.neuroFB.relaxLeft * 100.0) / 100.0;
    float relaxRightR = round(data.neuroFB.relaxRight * 100.0) / 100.0;
    float relaxAvgR = round(data.neuroFB.relaxAvg * 100.0) / 100.0;
    // 0~1.0, 小数第一位以降四捨五入
    float leftGammaR = round(data.powerBands.leftGamma * 100.0) / 100.0;
    float leftBetaR = round(data.powerBands.leftBeta * 100.0) / 100.0;
    float leftAlphaR = round(data.powerBands.leftAlpha * 100.0) / 100.0;
    float leftThetaR = round(data.powerBands.leftTheta * 100.0) / 100.0;
    float leftDeltaR = round(data.powerBands.leftDelta * 100.0) / 100.0;
    float rightGammaR = round(data.powerBands.rightGamma * 100.0) / 100.0;
    float rightBetaR = round(data.powerBands.rightBeta * 100.0) / 100.0;
    float rightAlphaR = round(data.powerBands.rightAlpha * 100.0) / 100.0;
    float rightThetaR = round(data.powerBands.rightTheta * 100.0) / 100.0;
    float rightDeltaR = round(data.powerBands.rightDelta * 100.0) / 100.0;
    float avgGammaR = round(data.powerBands.avgGamma * 100.0) / 100.0;
    float avgBetaR = round(data.powerBands.avgBeta * 100.0) / 100.0;
    float avgAlphaR = round(data.powerBands.avgAlpha * 100.0) / 100.0;
    float avgThetaR = round(data.powerBands.avgTheta * 100.0) / 100.0;
    float avgDeltaR = round(data.powerBands.avgDelta * 100.0) / 100.0;

    // Line 7: Version and Info
    if (y == 7)
    {
        if (x == 0) result = 33; // V
        else if (x == 1) result = 16;  // E
        else if (x == 2) result = 29; // R
        else if (x == 3) result = 42; // : (コロン)
        else if (x == 4) result = (data.info.versionMajor >= 0 && data.info.versionMajor <= 9) ? data.info.versionMajor : 47;
        else if (x == 5) result = 10; // .
        else if (x == 6) result = (data.info.versionMinor >= 0 && data.info.versionMinor <= 9) ? data.info.versionMinor : 47;
        else if (x == 7) result = 47; // space
        else if (x == 8) result = 23; // L
        else if (x == 9) result = 12;  // A
        else if (x == 10) result = 30; // S
        else if (x == 11) result = 31; // T
        else if (x == 12) result = 42; // : (コロン)
        else if (x == 13) result = (data.info.secondsSinceLastUpdate >= 0 && data.info.secondsSinceLastUpdate <= 99) ? (uint)data.info.secondsSinceLastUpdate / 10u : 0;
        else if (x == 14) result = (data.info.secondsSinceLastUpdate >= 0 && data.info.secondsSinceLastUpdate <= 99) ? (uint)data.info.secondsSinceLastUpdate % 10u : 0;
        else if (x == 15) result = 30; // S
        else if (x == 16) result = 47; // space
        else if (x == 17) result = 15; // D if connected
        else if (x == 18) result = 16; // E if connected
        else if (x == 19) result = 33; // V if connected
        else if (x == 20) result = 42; // : (コロン) if connected
        else if (x == 21) result = (data.info.deviceConnected > 0.5) ? 44 : 11; // デバイス記号 if connected
        else if (x == 22) result = 47; // space
        else if (x == 23) result = 13; // B if supported
        else if (x == 24) result = 12; // A
        else if (x == 25) result = 31; // T
        else if (x == 26) result = 42; // :
        else if (x == 27) result = (data.info.batterySupported > 0.5) ? 43 : 11; // Battery symbol if supported
        else if (x == 28) result = (data.info.batterySupported > 0.5 && data.info.batteryLevel >= 0 && data.info.batteryLevel <= 99) ? (uint)(data.info.batteryLevel * 100) / 10u : 0;
        else if (x == 29) result = (data.info.batterySupported > 0.5 && data.info.batteryLevel >= 0 && data.info.batteryLevel <= 99) ? (uint)(data.info.batteryLevel * 100) % 10u : 0;
        else if (x == 30) result = (data.info.batterySupported > 0.5) ? 27 : 47; // P if supported
        else if (x == 31) result = (data.info.batterySupported > 0.5) ? 14 : 47; // C if supported
    }

    // Line 6: Focus
    if (y == 6)
    {
        if (x == 0) result = 17;  // F
        if (x == 1) result = 26; // O
        if (x == 2) result = 14;  // C
        if (x == 3) result = 32; // U
        if (x == 4) result = 30; // S
        if (x == 5) result = 41; // /
        if (x == 6) result = 47; // space
        if (x == 7) result = 23; // L
        if (x == 8) result = 42; // :
        if (x == 9) result = (focusLeftR < 0) ? 11 : 47; // - if negative
        if (x == 10) result = (abs(focusLeftR) >= 1.0) ? (uint)abs(focusLeftR) / 1u : 0;
        if (x == 11) result = 10; // .
        if (x == 12) result = (1.0 > abs(focusLeftR) && abs(focusLeftR) > 0.1) ? (uint)abs(focusLeftR * 10.0) % 10u : 0;
        if (x == 13) result = (uint)(abs(focusLeftR * 100.0)) % 10u;
        if (x == 14) result = 47; // space
        if (x == 15) result = 29; // R
        if (x == 16) result = 42; // :
        if (x == 17) result = (focusRightR < 0) ? 11 : 47; // - if negative
        if (x == 18) result = (abs(focusRightR) >= 1.0) ? (uint)abs(focusRightR) / 1u : 0;
        if (x == 19) result = 10; // .
        if (x == 20) result = (1.0 > abs(focusRightR) && abs(focusRightR) > 0.1) ? (uint)abs(focusRightR * 10.0) % 10u : 0;
        if (x == 21) result = (uint)(abs(focusRightR * 100.0)) % 10u;
        if (x == 22) result = 47; // space
        if (x == 23) result = 12;  // A
        if (x == 24) result = 33; // V
        if (x == 25) result = 18;  // G
        if (x == 26) result = 42; // :
        if (x == 27) result = (focusAvgR < 0) ? 11 : 47; // - if negative
        if (x == 28) result = (abs(focusAvgR) >= 1.0) ? (uint)abs(focusAvgR) / 1u : 0;
        if (x == 29) result = 10; // .
        if (x == 30) result = (1.0 > abs(focusAvgR) && abs(focusAvgR) > 0.1) ? (uint)abs(focusAvgR * 10.0) % 10u : 0;
        if (x == 31) result = (uint)(abs(focusAvgR * 100.0)) % 10u;
    }

    // Line 5: Relax
    if (y == 5)
    {
        if (x == 0) result = 29; // R
        if (x == 1) result = 16;  // E
        if (x == 2) result = 23; // L
        if (x == 3) result = 12;  // A
        if (x == 4) result = 35; // X
        if (x == 5) result = 41; // /
        if (x == 6) result = 47; // space
        if (x == 7) result = 23; // L
        if (x == 8) result = 42; // :
        if (x == 9) result = (relaxLeftR < 0) ? 11 : 47; // - if negative
        if (x == 10) result = (abs(relaxLeftR) >= 1.0) ? (uint)abs(relaxLeftR) / 1u : 0;
        if (x == 11) result = 10; // .
        if (x == 12) result = (1.0 > abs(relaxLeftR) && abs(relaxLeftR) > 0.1) ? (uint)abs(relaxLeftR * 10.0) % 10u : 0;
        if (x == 13) result = (uint)(abs(relaxLeftR * 100.0)) % 10u;
        if (x == 14) result = 47; // space
        if (x == 15) result = 29; // R
        if (x == 16) result = 42; // :
        if (x == 17) result = (relaxRightR < 0) ? 11 : 47; // - if negative
        if (x == 18) result = (abs(relaxRightR) >= 1.0) ? (uint)abs(relaxRightR) / 1u : 0;
        if (x == 19) result = 10; // .
        if (x == 20) result = (1.0 > abs(relaxRightR) && abs(relaxRightR) > 0.1) ? (uint)abs(relaxRightR * 10.0) % 10u : 0;
        if (x == 21) result = (uint)(abs(relaxRightR * 100.0)) % 10u;
        if (x == 22) result = 47; // space
        if (x == 23) result = 12;  // A
        if (x == 24) result = 33; // V
        if (x == 25) result = 18;  // G
        if (x == 26) result = 42; // :
        if (x == 27) result = (relaxAvgR < 0) ? 11 : 47; // - if negative
        if (x == 28) result = (abs(relaxAvgR) >= 1.0) ? (uint)abs(relaxAvgR) / 1u : 0;
        if (x == 29) result = 10; // .
        if (x == 30) result = (1.0 > abs(relaxAvgR) && abs(relaxAvgR) > 0.1) ? (uint)abs(relaxAvgR * 10.0) % 10u : 0;
        if (x == 31) result = (uint)(abs(relaxAvgR * 100.0)) % 10u;
    }

    // Line 4: Left Power Bands
    if (y == 4)
    {
        if (x == 0) result = 23; // L
        if (x == 1) result = 41; // /
        if (x == 2) result = 47; // space
        if (x == 3) result = 12; // A
        if (x == 4) result = 42; // :
        if (x == 5) result = (leftAlphaR >= 1.0) ? 1 : 10; // .
        if (x == 6) result = (leftAlphaR >= 1.0) ? 10 : ((leftAlphaR >= 0.1) ? (uint)(leftAlphaR * 10.0) : 0);
        if (x == 7) result = (leftAlphaR >= 1.0) ? 0 : (uint)(leftAlphaR * 100.0) % 10u;
        if (x == 8) result = 47; // space
        if (x == 9) result = 13;  // B
        if (x == 10) result = 42; // :
        if (x == 11) result = (leftBetaR >= 1.0) ? 1 : 10; // .
        if (x == 12) result = (leftBetaR >= 1.0) ? 10 : ((leftBetaR >= 0.1) ? (uint)(leftBetaR * 10.0) : 0);
        if (x == 13) result = (leftBetaR >= 1.0) ? 0 : (uint)(leftBetaR * 100.0) % 10u;
        if (x == 14) result = 47; // space
        if (x == 15) result = 40;  // Θ
        if (x == 16) result = 42; // :
        if (x == 17) result = (leftThetaR >= 1.0) ? 1 : 10; // .
        if (x == 18) result = (leftThetaR >= 1.0) ? 10 : ((leftThetaR >= 0.1) ? (uint)(leftThetaR * 10.0) : 0);
        if (x == 19) result = (leftThetaR >= 1.0) ? 0 : (uint)(leftThetaR * 100.0) % 10u;
        if (x == 20) result = 47; // space
        if (x == 21) result = 39; // Δ
        if (x == 22) result = 42; // :
        if (x == 23) result = (leftDeltaR >= 1.0) ? 1 : 10; // .
        if (x == 24) result = (leftDeltaR >= 1.0) ? 10 : ((leftDeltaR >= 0.1) ? (uint)(leftDeltaR * 10.0) : 0);
        if (x == 25) result = (leftDeltaR >= 1.0) ? 0 : (uint)(leftDeltaR * 100.0) % 10u;
        if (x == 26) result = 47; // space
        if (x == 27) result = 38; // Γ
        if (x == 28) result = 42; // :
        if (x == 29) result = (leftGammaR >= 1.0) ? 1 : 10; // .
        if (x == 30) result = (leftGammaR >= 1.0) ? 10 : ((leftGammaR >= 0.1) ? (uint)(leftGammaR * 10.0) : 0);
        if (x == 31) result = (leftGammaR >= 1.0) ? 0 : (uint)(leftGammaR * 100.0) % 10u;
    }

    // Line 3: Right Power Bands
    if (y == 3)
    {
        if (x == 0) result = 29; // R
        if (x == 1) result = 41; // /
        if (x == 2) result = 47; // space
        if (x == 3) result = 12;  // A
        if (x == 4) result = 42; // :
        if (x == 5) result = (rightAlphaR >= 1.0) ? 1 : 10; // .
        if (x == 6) result = (rightAlphaR >= 1.0) ? 10 : ((rightAlphaR >= 0.1) ? (uint)(rightAlphaR * 10.0) : 0);
        if (x == 7) result = (rightAlphaR >= 1.0) ? 0 : (uint)(rightAlphaR * 100.0) % 10u;
        if (x == 8) result = 47; // space
        if (x == 9) result = 13;  // B
        if (x == 10) result = 42; // :
        if (x == 11) result = (rightBetaR >= 1.0) ? 1 : 10; // .
        if (x == 12) result = (rightBetaR >= 1.0) ? 10 : ((rightBetaR >= 0.1) ? (uint)(rightBetaR * 10.0) : 0);
        if (x == 13) result = (rightBetaR >= 1.0) ? 0 : (uint)(rightBetaR * 100.0) % 10u;
        if (x == 14) result = 47; // space
        if (x == 15) result = 40; // Θ
        if (x == 16) result = 42; // :
        if (x == 17) result = (rightThetaR >= 1.0) ? 1 : 10; // .
        if (x == 18) result = (rightThetaR >= 1.0) ? 10 : ((rightThetaR >= 0.1) ? (uint)(rightThetaR * 10.0) : 0);
        if (x == 19) result = (rightThetaR >= 1.0) ? 0 : (uint)(rightThetaR * 100.0) % 10u;
        if (x == 20) result = 47; // space
        if (x == 21) result = 39; // Δ
        if (x == 22) result = 42; // :
        if (x == 23) result = (rightDeltaR >= 1.0) ? 1 : 10; // .
        if (x == 24) result = (rightDeltaR >= 1.0) ? 10 : ((rightDeltaR >= 0.1) ? (uint)(rightDeltaR * 10.0) : 0);
        if (x == 25) result = (rightDeltaR >= 1.0) ? 0 : (uint)(rightDeltaR * 100.0) % 10u;
        if (x == 26) result = 47; // space
        if (x == 27) result = 38; // Γ
        if (x == 28) result = 42; // :
        if (x == 29) result = (rightGammaR >= 1.0) ? 1 : 10; // .
        if (x == 30) result = (rightGammaR >= 1.0) ? 10 : ((rightGammaR >= 0.1) ? (uint)(rightGammaR * 10.0) : 0);
        if (x == 31) result = (rightGammaR >= 1.0) ? 0 : (uint)(rightGammaR * 100.0) % 10u;
    }

    // Line 2: Average Power Bands
    if (y == 2)
    {
        if (x == 0) result = 12;  // A
        if (x == 1) result = 41; // /
        if (x == 2) result = 47; // space
        if (x == 3) result = 12;  // A
        if (x == 4) result = 42; // :
        if (x == 5) result = (avgAlphaR >= 1.0) ? 1 : 10; // .
        if (x == 6) result = (avgAlphaR >= 1.0) ? 10 : ((avgAlphaR >= 0.1) ? (uint)(avgAlphaR * 10.0) : 0);
        if (x == 7) result = (avgAlphaR >= 1.0) ? 0 : (uint)(avgAlphaR * 100.0) % 10u;
        if (x == 8) result = 47; // space
        if (x == 9) result = 13;  // B
        if (x == 10) result = 42; // :
        if (x == 11) result = (avgBetaR >= 1.0) ? 1 : 10; // .
        if (x == 12) result = (avgBetaR >= 1.0) ? 10 : ((avgBetaR >= 0.1) ? (uint)(avgBetaR * 10.0) : 0);
        if (x == 13) result = (avgBetaR >= 1.0) ? 0 : (uint)(avgBetaR * 100.0) % 10u;
        if (x == 14) result = 47; // space
        if (x == 15) result = 40; // Θ
        if (x == 16) result = 42; // :
        if (x == 17) result = (avgThetaR >= 1.0) ? 1 : 10; // .
        if (x == 18) result = (avgThetaR >= 1.0) ? 10 : ((avgThetaR >= 0.1) ? (uint)(avgThetaR * 10.0) : 0);
        if (x == 19) result = (avgThetaR >= 1.0) ? 0 : (uint)(avgThetaR * 100.0) % 10u;
        if (x == 20) result = 47; // space
        if (x == 21) result = 39; // Δ
        if (x == 22) result = 42; // :
        if (x == 23) result = (avgDeltaR >= 1.0) ? 1 : 10; // .
        if (x == 24) result = (avgDeltaR >= 1.0) ? 10 : ((avgDeltaR >= 0.1) ? (uint)(avgDeltaR * 10.0) : 0);
        if (x == 25) result = (avgDeltaR >= 1.0) ? 0 : (uint)(avgDeltaR * 100.0) % 10u;
        if (x == 26) result = 47; // space
        if (x == 27) result = 38; // Γ
        if (x == 28) result = 42; // :
        if (x == 29) result = (avgGammaR >= 1.0) ? 1 : 10; // .
        if (x == 30) result = (avgGammaR >= 1.0) ? 10 : ((avgGammaR >= 0.1) ? (uint)(avgGammaR * 10.0) : 0);
        if (x == 31) result = (avgGammaR >= 1.0) ? 0 : (uint)(avgGammaR * 100.0) % 10u;
    }

    // Line 1: Biometrics
    if (y == 1)
    {
        if (x == 0) result = 13;  // B
        if (x == 1) result = 20;  // I
        if (x == 2) result = 26; // O
        if (x == 3) result = 41; // /
        if (x == 4) result = 47; // space
        if (x == 5) result = (data.biometrics.supported > 0.5) ? 19 : 47; // H or space
        if (x == 6) result = (data.biometrics.supported > 0.5) ? 29 : 25; // R or N
        if (x == 7) result = (data.biometrics.supported > 0.5) ? 42 : 26; // : or O
        if (x == 8) result = (data.biometrics.supported > 0.5) ? 46 : 31; // 心拍数記号 if supported, T if not
        if (x == 9) result = (data.biometrics.supported > 0.5 && data.biometrics.heartBeatsPerMinute >= 100) ? (uint)data.biometrics.heartBeatsPerMinute / 100u : 0;
        if (x == 10) result = (data.biometrics.supported > 0.5 && data.biometrics.heartBeatsPerMinute >= 10) ? (uint)data.biometrics.heartBeatsPerMinute / 10u : 0;
        if (x == 11) result = (data.biometrics.supported > 0.5) ? (uint)data.biometrics.heartBeatsPerMinute % 10u : 30; // B or S
        if (x == 12) result = (data.biometrics.supported > 0.5) ? 41 : 16; // / or E
        if (x == 13) result = (data.biometrics.supported > 0.5) ? 24 : 31; // M or T
        if (x == 14) result = 47; // space
        if (x == 15) result = (data.biometrics.supported > 0.5) ? 26 : 47; // X or space
        if (x == 16) result = (data.biometrics.supported > 0.5) ? 35 : 47; // X or space
        if (x == 17) result = (data.biometrics.supported > 0.5) ? 42 : 47; // : or space
        if (x == 18) result = (data.biometrics.supported > 0.5) ? (uint)(data.biometrics.oxygenPercent * 100) / 10u : 0;
        if (x == 19) result = (data.biometrics.supported > 0.5) ? (uint)(data.biometrics.oxygenPercent * 100) % 10u : 0;
        if (x == 20) result = (data.biometrics.supported > 0.5) ? 27 : 47; // P or space
        if (x == 21) result = (data.biometrics.supported > 0.5) ? 14 : 47; // C or space
        if (x == 22) result = (data.biometrics.supported > 0.5) ? 47 : 47; // space or R
        if (x == 23) result = (data.biometrics.supported > 0.5) ? 13 : 47; // B or space
        if (x == 24) result = (data.biometrics.supported > 0.5) ? 29 : 47; // R or space
        if (x == 25) result = (data.biometrics.supported > 0.5) ? 42 : 47; // : or space
        if (x == 26) result = (data.biometrics.supported > 0.5) ? 45 : 47; // ブレス記号 if supported, space if not
        if (x == 27) result = (data.biometrics.supported > 0.5 && data.biometrics.breathsPerMinute >= 100) ? (uint)data.biometrics.breathsPerMinute / 100u : 0;
        if (x == 28) result = (data.biometrics.supported > 0.5 && data.biometrics.breathsPerMinute >= 10) ? ((uint)data.biometrics.breathsPerMinute / 10u) % 10u : 0;
        if (x == 29) result = (data.biometrics.supported > 0.5) ? (uint)data.biometrics.breathsPerMinute % 10u : 0;
        if (x == 30) result = (data.biometrics.supported > 0.5) ? 41 : 47; // / if supported
        if (x == 31) result = (data.biometrics.supported > 0.5) ? 24 : 47; // M or space
    }

    // Line 0: Addons
    if (y == 0)
    {
        if (x == 0) result = 12;  // A
        if (x == 1) result = 15;  // D
        if (x == 2) result = 15;  // D
        if (x == 3) result = 26; // O
        if (x == 4) result = 25; // N
        if (x == 5) result = 30; // S
        if (x == 6) result = 41; // /
        if (x == 7) result = 47; // space
        if (x == 8) result = 19;  // H
        if (x == 9) result = 32; // U
        if (x == 10) result = 16;  // E
        if (x == 11) result = 42; // :
        if (x == 12) result = (data.addons.hueShift >= 0.1) ? (uint)(data.addons.hueShift * 10) : 0;
        if (x == 13) result = 10; // .
        if (x == 14) result = (uint)(data.addons.hueShift * 100) % 10u;
        if (x == 15) result = (uint)(data.addons.hueShift * 1000) % 10u;
    }

    return result;
}

#endif // OSC_TEXT_ENCODER_INCLUDED