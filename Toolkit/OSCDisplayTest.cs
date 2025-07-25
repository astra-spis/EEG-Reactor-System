using UnityEngine;
using System.Collections;

public class OSCDisplayTest : MonoBehaviour
{
    [Header("OSC Sender Reference")]
    [SerializeField] private VRChatOSCSender oscSender;

    [Header("Test Settings")]
    [SerializeField] private bool autoTest = false;
    [SerializeField] private float testInterval = 0.1f; // より高速な更新間隔

    [Header("Real-time Data Settings")]
    [SerializeField] private bool enableRealTimeVariation = true;
    [SerializeField] private float variationSpeed = 1.0f;
    [SerializeField] private float variationAmplitude = 0.5f;

    [Header("Simulation Settings")]
    [SerializeField] private float baseFocusValue = 0.0f;
    [SerializeField] private float baseRelaxValue = 0.0f;
    [SerializeField] private float baseAlphaValue = 0.25f;
    [SerializeField] private float baseBetaValue = 0.20f;
    [SerializeField] private float baseThetaValue = 0.15f;
    [SerializeField] private float baseDeltaValue = 0.10f;
    [SerializeField] private float baseGammaValue = 0.05f;

    // リアルタイム変動用の時間変数
    private float timeOffset = 0f;
    private float lastUpdateTime = 0f;

    private void Start()
    {
        // If no OSC sender is assigned, try to find one in the scene
        if (oscSender == null)
        {
            oscSender = FindObjectOfType<VRChatOSCSender>();
        }

        if (oscSender == null)
        {
            Debug.LogError("No VRChatOSCSender found in the scene!");
            return;
        }

        if (autoTest)
        {
            StartCoroutine(AutoTestRoutine());
        }
    }

    private IEnumerator AutoTestRoutine()
    {
        while (true)
        {
            yield return new WaitForSeconds(testInterval);

            // Send real-time BFI parameters
            SendIndividualBFIParameters();
        }
    }

    [ContextMenu("Send Individual BFI Parameters")]
    public void SendIndividualBFIParameters()
    {
        if (oscSender == null) return;

        // リアルタイム変動を有効にする場合、時間に基づいて値を変動させる
        if (enableRealTimeVariation)
        {
            UpdateRealTimeValues();
        }

        // Info parameters
        oscSender.SendFloatParameter("BFI/Info/VersionMajor", 1.0f);
        oscSender.SendFloatParameter("BFI/Info/VersionMinor", 0.0f);
        oscSender.SendFloatParameter("BFI/Info/DeviceConnected", 1.0f);
        oscSender.SendFloatParameter("BFI/Info/BatterySupported", 1.0f);
        oscSender.SendFloatParameter("BFI/Info/BatteryLevel", 0.85f);
        oscSender.SendFloatParameter("BFI/Info/SecondsSinceLastUpdate", 0.1f);

        // NeuroFB parameters (Focus and Relax with real-time variation)
        float focusLeft = baseFocusValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed) * variationAmplitude : 0f);
        float focusRight = baseFocusValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 1.1f) * variationAmplitude : 0f);
        float focusAvg = (focusLeft + focusRight) / 2f;

        float relaxLeft = baseRelaxValue + (enableRealTimeVariation ? Mathf.Cos(Time.time * variationSpeed * 0.8f) * variationAmplitude : 0f);
        float relaxRight = baseRelaxValue + (enableRealTimeVariation ? Mathf.Cos(Time.time * variationSpeed * 0.9f) * variationAmplitude : 0f);
        float relaxAvg = (relaxLeft + relaxRight) / 2f;

        // Focus parameters
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusLeft", Mathf.Clamp(focusLeft, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusLeftPos", Mathf.Clamp01((focusLeft + 1f) / 2f));
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusRight", Mathf.Clamp(focusRight, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusRightPos", Mathf.Clamp01((focusRight + 1f) / 2f));
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusAvg", Mathf.Clamp(focusAvg, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/FocusAvgPos", Mathf.Clamp01((focusAvg + 1f) / 2f));

        // Relax parameters
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxLeft", Mathf.Clamp(relaxLeft, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxLeftPos", Mathf.Clamp01((relaxLeft + 1f) / 2f));
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxRight", Mathf.Clamp(relaxRight, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxRightPos", Mathf.Clamp01((relaxRight + 1f) / 2f));
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxAvg", Mathf.Clamp(relaxAvg, -1f, 1f));
        oscSender.SendFloatParameter("BFI/NeuroFB/RelaxAvgPos", Mathf.Clamp01((relaxAvg + 1f) / 2f));

        // Power Bands parameters with real-time variation
        float leftAlpha = baseAlphaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.7f) * variationAmplitude * 0.3f : 0f);
        float rightAlpha = baseAlphaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.75f) * variationAmplitude * 0.3f : 0f);
        float avgAlpha = (leftAlpha + rightAlpha) / 2f;

        float leftBeta = baseBetaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.6f) * variationAmplitude * 0.3f : 0f);
        float rightBeta = baseBetaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.65f) * variationAmplitude * 0.3f : 0f);
        float avgBeta = (leftBeta + rightBeta) / 2f;

        float leftTheta = baseThetaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.5f) * variationAmplitude * 0.3f : 0f);
        float rightTheta = baseThetaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.55f) * variationAmplitude * 0.3f : 0f);
        float avgTheta = (leftTheta + rightTheta) / 2f;

        float leftDelta = baseDeltaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.4f) * variationAmplitude * 0.3f : 0f);
        float rightDelta = baseDeltaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.45f) * variationAmplitude * 0.3f : 0f);
        float avgDelta = (leftDelta + rightDelta) / 2f;

        float leftGamma = baseGammaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.3f) * variationAmplitude * 0.3f : 0f);
        float rightGamma = baseGammaValue + (enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.35f) * variationAmplitude * 0.3f : 0f);
        float avgGamma = (leftGamma + rightGamma) / 2f;

        // Left Power Bands
        oscSender.SendFloatParameter("BFI/PwrBands/Left/Alpha", Mathf.Clamp01(leftAlpha));
        oscSender.SendFloatParameter("BFI/PwrBands/Left/Beta", Mathf.Clamp01(leftBeta));
        oscSender.SendFloatParameter("BFI/PwrBands/Left/Theta", Mathf.Clamp01(leftTheta));
        oscSender.SendFloatParameter("BFI/PwrBands/Left/Delta", Mathf.Clamp01(leftDelta));
        oscSender.SendFloatParameter("BFI/PwrBands/Left/Gamma", Mathf.Clamp01(leftGamma));

        // Right Power Bands
        oscSender.SendFloatParameter("BFI/PwrBands/Right/Alpha", Mathf.Clamp01(rightAlpha));
        oscSender.SendFloatParameter("BFI/PwrBands/Right/Beta", Mathf.Clamp01(rightBeta));
        oscSender.SendFloatParameter("BFI/PwrBands/Right/Theta", Mathf.Clamp01(rightTheta));
        oscSender.SendFloatParameter("BFI/PwrBands/Right/Delta", Mathf.Clamp01(rightDelta));
        oscSender.SendFloatParameter("BFI/PwrBands/Right/Gamma", Mathf.Clamp01(rightGamma));

        // Average Power Bands
        oscSender.SendFloatParameter("BFI/PwrBands/Avg/Alpha", Mathf.Clamp01(avgAlpha));
        oscSender.SendFloatParameter("BFI/PwrBands/Avg/Beta", Mathf.Clamp01(avgBeta));
        oscSender.SendFloatParameter("BFI/PwrBands/Avg/Theta", Mathf.Clamp01(avgTheta));
        oscSender.SendFloatParameter("BFI/PwrBands/Avg/Delta", Mathf.Clamp01(avgDelta));
        oscSender.SendFloatParameter("BFI/PwrBands/Avg/Gamma", Mathf.Clamp01(avgGamma));

        // Addons parameters
        float hueShift = (focusAvg + relaxAvg + 2f) / 4f; // Convert to 0-1 range
        oscSender.SendFloatParameter("BFI/Addons/HueShift", Mathf.Clamp01(hueShift));

        // Biometrics parameters with real-time variation
        float heartRateVariation = enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.2f) * 5f : 0f;
        float oxygenVariation = enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.15f) * 0.02f : 0f;
        float breathRateVariation = enableRealTimeVariation ? Mathf.Sin(Time.time * variationSpeed * 0.25f) * 2f : 0f;

        oscSender.SendFloatParameter("BFI/Biometrics/Supported", 1.0f);
        oscSender.SendFloatParameter("BFI/Biometrics/HeartBeatsPerSecond", 1.2f + heartRateVariation * 0.1f);
        oscSender.SendIntParameter("BFI/Biometrics/HeartBeatsPerMinute", Mathf.Clamp(Mathf.RoundToInt(72 + heartRateVariation), 60, 100));
        oscSender.SendFloatParameter("BFI/Biometrics/OxygenPercent", Mathf.Clamp01(0.98f + oxygenVariation));
        oscSender.SendFloatParameter("BFI/Biometrics/BreathsPerSecond", 0.25f + breathRateVariation * 0.05f);
        oscSender.SendIntParameter("BFI/Biometrics/BreathsPerMinute", Mathf.Clamp(Mathf.RoundToInt(15 + breathRateVariation), 10, 25));

        if (enableRealTimeVariation)
        {
            Debug.Log($"Sent real-time BFI parameters - Focus: {focusAvg:F2}, Relax: {relaxAvg:F2}, Alpha: {avgAlpha:F2}");
        }
        else
        {
            Debug.Log("Sent static BFI parameters");
        }
    }

    private void UpdateRealTimeValues()
    {
        // 時間に基づいてベース値を少し変動させる
        float time = Time.time;
        
        // ベース値に小さな変動を追加
        baseFocusValue = Mathf.Sin(time * 0.1f) * 0.1f;
        baseRelaxValue = Mathf.Cos(time * 0.08f) * 0.1f;
        
        // パワーバンドのベース値も変動させる
        baseAlphaValue = 0.25f + Mathf.Sin(time * 0.05f) * 0.05f;
        baseBetaValue = 0.20f + Mathf.Cos(time * 0.06f) * 0.05f;
        baseThetaValue = 0.15f + Mathf.Sin(time * 0.07f) * 0.05f;
        baseDeltaValue = 0.10f + Mathf.Cos(time * 0.04f) * 0.05f;
        baseGammaValue = 0.05f + Mathf.Sin(time * 0.03f) * 0.05f;
    }

    [ContextMenu("Send Static BFI Parameters")]
    public void SendStaticBFIParameters()
    {
        bool originalVariation = enableRealTimeVariation;
        enableRealTimeVariation = false;
        SendIndividualBFIParameters();
        enableRealTimeVariation = originalVariation;
    }

    [ContextMenu("Send BrainFlow Simulation")]
    public void SendBrainFlowSimulation()
    {
        if (oscSender == null) return;

        // Simulate BrainFlow data with realistic values
        float[] eegData = new float[8];
        float[] bandPowers = new float[5];

        // Generate realistic EEG data
        for (int i = 0; i < eegData.Length; i++)
        {
            eegData[i] = Random.Range(-50f, 50f);
        }

        // Generate realistic band powers (Delta, Theta, Alpha, Beta, Gamma)
        bandPowers[0] = Random.Range(10f, 30f); // Delta
        bandPowers[1] = Random.Range(5f, 15f);  // Theta
        bandPowers[2] = Random.Range(20f, 40f); // Alpha
        bandPowers[3] = Random.Range(15f, 35f); // Beta
        bandPowers[4] = Random.Range(5f, 20f);  // Gamma

        // Generate realistic attention and meditation values
        float attention = Random.Range(30f, 90f);
        float meditation = Random.Range(20f, 80f);

        oscSender.SendBrainFlowData(eegData, bandPowers, attention, meditation);
        Debug.Log($"Sent simulated BrainFlow data - Attention: {attention:F1}, Meditation: {meditation:F1}");
    }

    // UI Button methods
    public void OnRealTimeBFIButton()
    {
        SendIndividualBFIParameters();
    }

    public void OnStaticBFIButton()
    {
        SendStaticBFIParameters();
    }

    public void OnBrainFlowButton()
    {
        SendBrainFlowSimulation();
    }

    public void OnToggleAutoTest()
    {
        if (autoTest)
        {
            StopAllCoroutines();
            autoTest = false;
            Debug.Log("Auto test stopped");
        }
        else
        {
            StartCoroutine(AutoTestRoutine());
            autoTest = true;
            Debug.Log("Auto test started");
        }
    }

    public void OnToggleRealTimeVariation()
    {
        enableRealTimeVariation = !enableRealTimeVariation;
        Debug.Log($"Real-time variation: {(enableRealTimeVariation ? "Enabled" : "Disabled")}");
    }

    // Update method for keyboard shortcuts
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            SendIndividualBFIParameters();
        }

        if (Input.GetKeyDown(KeyCode.S))
        {
            SendStaticBFIParameters();
        }

        if (Input.GetKeyDown(KeyCode.B))
        {
            SendBrainFlowSimulation();
        }

        if (Input.GetKeyDown(KeyCode.Space))
        {
            OnToggleAutoTest();
        }

        if (Input.GetKeyDown(KeyCode.V))
        {
            OnToggleRealTimeVariation();
        }
    }

    private void OnGUI()
    {
        if (oscSender == null) return;

        GUILayout.BeginArea(new Rect(10, 10, 400, 600));
        GUILayout.Label("OSC Display Test - BFI Parameters", GUI.skin.box);

        GUILayout.Space(10);

        // Auto Test Toggle
        if (GUILayout.Button(autoTest ? "Stop Auto Test (Space)" : "Start Auto Test (Space)"))
        {
            OnToggleAutoTest();
        }

        // Real-time Variation Toggle
        if (GUILayout.Button(enableRealTimeVariation ? "Disable Real-time Variation (V)" : "Enable Real-time Variation (V)"))
        {
            OnToggleRealTimeVariation();
        }

        GUILayout.Space(10);

        // Manual Test Buttons
        if (GUILayout.Button("Send Real-time BFI Parameters (R)"))
        {
            SendIndividualBFIParameters();
        }

        if (GUILayout.Button("Send Static BFI Parameters (S)"))
        {
            SendStaticBFIParameters();
        }

        if (GUILayout.Button("Send BrainFlow Simulation (B)"))
        {
            SendBrainFlowSimulation();
        }

        GUILayout.Space(10);

        // Settings
        GUILayout.Label("Settings:", GUI.skin.box);
        testInterval = GUILayout.HorizontalSlider(testInterval, 0.05f, 2.0f);
        GUILayout.Label($"Test Interval: {testInterval:F2}s");

        variationSpeed = GUILayout.HorizontalSlider(variationSpeed, 0.1f, 5.0f);
        GUILayout.Label($"Variation Speed: {variationSpeed:F1}");

        variationAmplitude = GUILayout.HorizontalSlider(variationAmplitude, 0.1f, 1.0f);
        GUILayout.Label($"Variation Amplitude: {variationAmplitude:F1}");

        GUILayout.Space(10);

        // Current Values Display
        GUILayout.Label("Current Values:", GUI.skin.box);
        GUILayout.Label($"Focus Avg: {baseFocusValue:F2}");
        GUILayout.Label($"Relax Avg: {baseRelaxValue:F2}");
        GUILayout.Label($"Alpha: {baseAlphaValue:F2}");
        GUILayout.Label($"Beta: {baseBetaValue:F2}");
        GUILayout.Label($"Theta: {baseThetaValue:F2}");

        GUILayout.Space(10);

        GUILayout.Label("Keyboard Shortcuts:");
        GUILayout.Label("R - Real-time BFI Parameters");
        GUILayout.Label("S - Static BFI Parameters");
        GUILayout.Label("B - BrainFlow Simulation");
        GUILayout.Label("Space - Toggle Auto Test");
        GUILayout.Label("V - Toggle Real-time Variation");

        GUILayout.EndArea();
    }
}