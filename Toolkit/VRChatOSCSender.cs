// OSCSender.cs
// This runs INSIDE Unity as a MonoBehaviour component
// Sends data to VRChat via OSC

using System;
using System.Text;
using System.Net;
using System.Net.Sockets;
using UnityEngine;

public class VRChatOSCSender : MonoBehaviour
{
    [Header("OSC Settings")]
    [SerializeField] private string vrchatIP = "127.0.0.1";
    [SerializeField] private int vrchatPort = 9000;

    [Header("Debug")]
    [SerializeField] private bool enableDebugLogging = true;

    private UdpClient udpClient;
    private IPEndPoint vrchatEndpoint;
    private bool isInitialized = false;

    // 独自記号用PUA Unicode定義
    private const char BatterySymbol = '\uE001';
    private const char FocusSymbol = '\uE002';
    private const char RelaxSymbol = '\uE003';
    private const char DeviceSymbol = '\uE004';
    private const char HeartSymbol = '\uE005';
    private const char BreathSymbol = '\uE006'; // 必要なら

    void Start()
    {
        InitializeOSC();
    }

    void OnDestroy()
    {
        Dispose();
    }

    void OnApplicationQuit()
    {
        Dispose();
    }

    private void InitializeOSC()
    {
        try
        {
            udpClient = new UdpClient();
            vrchatEndpoint = new IPEndPoint(IPAddress.Parse(vrchatIP), vrchatPort);
            isInitialized = true;

            if (enableDebugLogging)
                Debug.Log($"OSC Sender initialized - Target: {vrchatIP}:{vrchatPort}");
        }
        catch (Exception e)
        {
            Debug.LogError($"Failed to initialize OSC sender: {e.Message}");
            isInitialized = false;
        }
    }

    // Encode string data for VRChat shader consumption
    public void SendTextToVRChat(string text, string avatarId = "")
    {
        if (!isInitialized)
        {
            Debug.LogWarning("OSC Sender not initialized. Cannot send text.");
            return;
        }

        // Preprocess text (apply abbreviations and replacements)
        string processedText = PreprocessText(text);

        // Use linear encoding instead of row-based
        // Each parameter can store up to 10 characters
        int charsPerParam = 10;
        int totalChars = processedText.Length;
        int numParams = Mathf.CeilToInt((float)totalChars / charsPerParam);

        for (int i = 0; i < numParams && i < 8; i++)
        {
            int startIndex = i * charsPerParam;
            int length = Math.Min(charsPerParam, totalChars - startIndex);
            string paramText = processedText.Substring(startIndex, length).PadRight(charsPerParam, ' ');

            float encodedParam = EncodeTextToFloat(paramText);
            string paramName = $"/avatar/parameters/OSCParam{i + 1}";
            SendOSCFloat(paramName, encodedParam);
        }

        if (enableDebugLogging)
            Debug.Log($"Sent processed text to VRChat: {processedText.Substring(0, Math.Min(processedText.Length, 50))}...");
    }

    // Preprocess text by applying abbreviations and replacements
    private string PreprocessText(string text)
    {
        string processed = text;

        // Remove specified phrases
        processed = processed.Replace("BFI/Info/", "");
        processed = processed.Replace("BFI/NeuroFB/", "");
        processed = processed.Replace("BFI/PwrBands/", "");
        processed = processed.Replace("BFI/Addons/", "");
        processed = processed.Replace("BFI/Biometrics/", "");

        // Replace specified words with abbreviations or symbols
        processed = processed.Replace("Version", "VER");
        processed = processed.Replace("Major", "MJR");
        processed = processed.Replace("SecondsSinceLastUpdate", "LAST");
        processed = processed.Replace("Minor", "MNR");
        processed = processed.Replace("Level", "LV");
        processed = processed.Replace("Left", "L");
        processed = processed.Replace("Right", "R");
        processed = processed.Replace("Avg", "AVG");
        processed = processed.Replace("Focus", FocusSymbol.ToString());
        processed = processed.Replace("Relax", RelaxSymbol.ToString());
        processed = processed.Replace("Battery", BatterySymbol.ToString());
        processed = processed.Replace("DeviceConnected", DeviceSymbol.ToString());
        processed = processed.Replace("Alpha", "A");
        processed = processed.Replace("Beta", "B");
        processed = processed.Replace("Theta", "Θ");
        processed = processed.Replace("Delta", "Δ");
        processed = processed.Replace("Gamma", "Γ");
        processed = processed.Replace("HueShift", "HUE");
        processed = processed.Replace("Supported", "SP");
        processed = processed.Replace("HeartBeats", HeartSymbol.ToString());
        processed = processed.Replace("Breaths", BreathSymbol.ToString()); // 上下逆さ心拍数記号（必要なら）
        processed = processed.Replace("PerSecond", "/S");
        processed = processed.Replace("PerMinute", "/M");
        processed = processed.Replace("OxygenPercent", "OX");

        // 大文字・小文字を区別しない（大文字化）
        processed = processed.ToUpperInvariant();

        return processed;
    }

    // Split text into fixed-width rows
    private string[] SplitTextIntoRows(string text, int rowWidth, int maxRows)
    {
        string[] rows = new string[maxRows];

        for (int i = 0; i < maxRows; i++)
        {
            int startIndex = i * rowWidth;
            if (startIndex >= text.Length)
            {
                rows[i] = new string(' ', rowWidth); // Fill with spaces
            }
            else
            {
                int length = Math.Min(rowWidth, text.Length - startIndex);
                rows[i] = text.Substring(startIndex, length).PadRight(rowWidth);
            }
        }

        return rows;
    }

    // Encode text to float using base-256 encoding
    private float EncodeTextToFloat(string text)
    {
        // Base-256 encoding: pack character codes into a large number
        long encoded = 0;
        long multiplier = 1;

        for (int i = 0; i < text.Length && i < 10; i++) // Limit to prevent overflow
        {
            int charCode = CharToCharCode(text[i]);
            encoded += charCode * multiplier;
            multiplier *= 256; // Base-256 since we use 8-bit characters
        }

        // Normalize to 0-1 range for VRChat
        return (float)(encoded % 1000000) / 1000000f;
    }

    // Convert character to 8-bit character code
    private int CharToCharCode(char c)
    {
        // ASCII characters (0-127) - direct mapping
        if (c >= 0 && c <= 127)
            return (int)c;

        // Special extended characters (128-175) for symbols
        switch (c)
        {
            case 'B': return 128; // Battery symbol
            case 'F': return 129; // Focus symbol
            case 'R': return 130; // Relax symbol
            case 'D': return 131; // Device connected symbol
            case 'H': return 132; // Heart/breath symbol
            case '/': return 133; // Slash
            default: return 32;   // Space for unknown characters
        }
    }

    // Encode a single row of text into a float value (legacy function)
    private float EncodeRowToFloat(string row)
    {
        // Simple encoding: pack character indices into a large number
        long encoded = 0;
        long multiplier = 1;

        for (int i = 0; i < row.Length && i < 10; i++) // Limit to prevent overflow
        {
            int charIndex = CharToFontIndex(row[i]);
            encoded += charIndex * multiplier;
            multiplier *= 48; // Base-48 since we have 48 characters
        }

        // Normalize to 0-1 range for VRChat
        return (float)(encoded % 1000000) / 1000000f;
    }

    // Convert character to font index (same mapping as shader)
    private int CharToFontIndex(char c)
    {
        // Digits 0-9
        if (c >= '0' && c <= '9') return c - '0';
        // Period and hyphen
        if (c == '.') return 10;
        if (c == '-') return 11;
        // Letters A-Z (case insensitive)
        if (c >= 'A' && c <= 'Z') return c - 'A' + 12;
        // Greek letters
        if (c == 'Γ') return 38; // Gamma
        if (c == 'Δ') return 39; // Delta
        if (c == 'Θ') return 40; // Theta
        // Special symbols (41-47)
        if (c == '/') return 41;  // Slash
        if (c == ':') return 42;
        if (c == BatterySymbol) return 43;
        if (c == DeviceSymbol) return 44;
        if (c == BreathSymbol) return 45;
        if (c == HeartSymbol) return 46;
        // Default to space
        return 47;
    }

    // Send OSC float parameter to VRChat
    private void SendOSCFloat(string address, float value)
    {
        if (!isInitialized) return;

        try
        {
            byte[] oscMessage = CreateOSCMessage(address, value);
            udpClient.Send(oscMessage, oscMessage.Length, vrchatEndpoint);
        }
        catch (Exception e)
        {
            Debug.LogError($"Failed to send OSC message: {e.Message}");
        }
    }

    // Create OSC message bytes
    private byte[] CreateOSCMessage(string address, float value)
    {
        // Simple OSC message format
        // This is a minimal implementation - use a proper OSC library for production

        byte[] addressBytes = Encoding.UTF8.GetBytes(address);
        byte[] padding1 = new byte[4 - (addressBytes.Length % 4)];

        byte[] typeTag = Encoding.UTF8.GetBytes(",f"); // Float type
        byte[] padding2 = new byte[4 - (typeTag.Length % 4)];

        byte[] valueBytes = BitConverter.GetBytes(value);
        if (BitConverter.IsLittleEndian)
            Array.Reverse(valueBytes); // OSC uses big-endian

        // Combine all parts
        byte[] message = new byte[addressBytes.Length + padding1.Length +
                                typeTag.Length + padding2.Length + valueBytes.Length];

        int offset = 0;
        Array.Copy(addressBytes, 0, message, offset, addressBytes.Length);
        offset += addressBytes.Length + padding1.Length;

        Array.Copy(typeTag, 0, message, offset, typeTag.Length);
        offset += typeTag.Length + padding2.Length;

        Array.Copy(valueBytes, 0, message, offset, valueBytes.Length);

        return message;
    }

    // Example usage for BrainFlow data
    public void SendBrainFlowData(float[] eegData, float[] bandPowers,
                                 float attention, float meditation)
    {
        if (!isInitialized)
        {
            Debug.LogWarning("OSC Sender not initialized. Cannot send BrainFlow data.");
            return;
        }

        // Send BrainFlowsIntoVRChat parameters directly
        // Info parameters
        SendFloatParameter("BFI/Info/VersionMajor", 1.0f);
        SendFloatParameter("BFI/Info/VersionMinor", 0.0f);
        SendFloatParameter("BFI/Info/SecondsSinceLastUpdate", 0.1f);
        SendFloatParameter("BFI/Info/DeviceConnected", 1.0f);
        SendFloatParameter("BFI/Info/BatterySupported", 1.0f);
        SendFloatParameter("BFI/Info/BatteryLevel", 0.8f);

        // NeuroFB parameters (convert attention/meditation to focus/relax)
        float focusLeft = (attention - 50f) / 50f; // Convert 0-100 to -1 to 1
        float focusRight = focusLeft;
        float focusAvg = focusLeft;
        float relaxLeft = (meditation - 50f) / 50f; // Convert 0-100 to -1 to 1
        float relaxRight = relaxLeft;
        float relaxAvg = relaxLeft;

        SendFloatParameter("BFI/NeuroFB/FocusLeft", focusLeft);
        SendFloatParameter("BFI/NeuroFB/FocusLeftPos", (focusLeft + 1f) / 2f);
        SendFloatParameter("BFI/NeuroFB/FocusRight", focusRight);
        SendFloatParameter("BFI/NeuroFB/FocusRightPos", (focusRight + 1f) / 2f);
        SendFloatParameter("BFI/NeuroFB/FocusAvg", focusAvg);
        SendFloatParameter("BFI/NeuroFB/FocusAvgPos", (focusAvg + 1f) / 2f);
        SendFloatParameter("BFI/NeuroFB/RelaxLeft", relaxLeft);
        SendFloatParameter("BFI/NeuroFB/RelaxLeftPos", (relaxLeft + 1f) / 2f);
        SendFloatParameter("BFI/NeuroFB/RelaxRight", relaxRight);
        SendFloatParameter("BFI/NeuroFB/RelaxRightPos", (relaxRight + 1f) / 2f);
        SendFloatParameter("BFI/NeuroFB/RelaxAvg", relaxAvg);
        SendFloatParameter("BFI/NeuroFB/RelaxAvgPos", (relaxAvg + 1f) / 2f);

        // Power Bands parameters (normalize to 0-1 range)
        if (bandPowers != null && bandPowers.Length >= 5)
        {
            // Left side (use bandPowers directly)
            SendFloatParameter("BFI/PwrBands/Left/Delta", Mathf.Clamp01(bandPowers[0] / 100f));
            SendFloatParameter("BFI/PwrBands/Left/Theta", Mathf.Clamp01(bandPowers[1] / 100f));
            SendFloatParameter("BFI/PwrBands/Left/Alpha", Mathf.Clamp01(bandPowers[2] / 100f));
            SendFloatParameter("BFI/PwrBands/Left/Beta", Mathf.Clamp01(bandPowers[3] / 100f));
            SendFloatParameter("BFI/PwrBands/Left/Gamma", Mathf.Clamp01(bandPowers[4] / 100f));

            // Right side (use bandPowers with slight variation)
            SendFloatParameter("BFI/PwrBands/Right/Delta", Mathf.Clamp01(bandPowers[0] / 100f * 0.9f));
            SendFloatParameter("BFI/PwrBands/Right/Theta", Mathf.Clamp01(bandPowers[1] / 100f * 1.1f));
            SendFloatParameter("BFI/PwrBands/Right/Alpha", Mathf.Clamp01(bandPowers[2] / 100f * 0.95f));
            SendFloatParameter("BFI/PwrBands/Right/Beta", Mathf.Clamp01(bandPowers[3] / 100f * 1.05f));
            SendFloatParameter("BFI/PwrBands/Right/Gamma", Mathf.Clamp01(bandPowers[4] / 100f * 0.98f));

            // Average (use bandPowers directly)
            SendFloatParameter("BFI/PwrBands/Avg/Delta", Mathf.Clamp01(bandPowers[0] / 100f));
            SendFloatParameter("BFI/PwrBands/Avg/Theta", Mathf.Clamp01(bandPowers[1] / 100f));
            SendFloatParameter("BFI/PwrBands/Avg/Alpha", Mathf.Clamp01(bandPowers[2] / 100f));
            SendFloatParameter("BFI/PwrBands/Avg/Beta", Mathf.Clamp01(bandPowers[3] / 100f));
            SendFloatParameter("BFI/PwrBands/Avg/Gamma", Mathf.Clamp01(bandPowers[4] / 100f));
        }

        // Addons parameters
        float hueShift = (focusAvg + relaxAvg + 2f) / 4f; // Convert to 0-1 range
        SendFloatParameter("BFI/Addons/HueShift", hueShift);

        // Biometrics parameters (simulated)
        SendFloatParameter("BFI/Biometrics/Supported", 1.0f);
        SendFloatParameter("BFI/Biometrics/HeartBeatsPerSecond", 1.2f);
        SendIntParameter("BFI/Biometrics/HeartBeatsPerMinute", 72);
        SendFloatParameter("BFI/Biometrics/OxygenPercent", 0.98f);
        SendFloatParameter("BFI/Biometrics/BreathsPerSecond", 0.25f);
        SendIntParameter("BFI/Biometrics/BreathsPerMinute", 15);

        if (enableDebugLogging)
            Debug.Log("Sent BrainFlowsIntoVRChat parameters");
    }

    // Send BrainFlow data with custom formatting
    public void SendBrainFlowDataCustom(string parameterName, float value, string unit = "")
    {
        if (!isInitialized)
        {
            Debug.LogWarning("OSC Sender not initialized. Cannot send BrainFlow data.");
            return;
        }
        // 小数点第2位までで丸める
        string displayText = $"{parameterName}: {value:F2}{unit}\n";
        SendTextToVRChat(displayText);
    }

    // Public method to send custom float parameters
    public void SendFloatParameter(string parameterName, float value)
    {
        if (!isInitialized) return;

        string address = $"/avatar/parameters/{parameterName}";
        SendOSCFloat(address, value);
    }

    // Public method to send custom int parameters
    public void SendIntParameter(string parameterName, int value)
    {
        if (!isInitialized) return;

        string address = $"/avatar/parameters/{parameterName}";
        SendOSCInt(address, value);
    }

    // Send OSC int parameter to VRChat
    private void SendOSCInt(string address, int value)
    {
        if (!isInitialized) return;

        try
        {
            byte[] oscMessage = CreateOSCIntMessage(address, value);
            udpClient.Send(oscMessage, oscMessage.Length, vrchatEndpoint);
        }
        catch (Exception e)
        {
            Debug.LogError($"Failed to send OSC int message: {e.Message}");
        }
    }

    // Create OSC int message bytes
    private byte[] CreateOSCIntMessage(string address, int value)
    {
        byte[] addressBytes = Encoding.UTF8.GetBytes(address);
        byte[] padding1 = new byte[4 - (addressBytes.Length % 4)];

        byte[] typeTag = Encoding.UTF8.GetBytes(",i"); // Int type
        byte[] padding2 = new byte[4 - (typeTag.Length % 4)];

        byte[] valueBytes = BitConverter.GetBytes(value);
        if (BitConverter.IsLittleEndian)
            Array.Reverse(valueBytes); // OSC uses big-endian

        // Combine all parts
        byte[] message = new byte[addressBytes.Length + padding1.Length +
                                typeTag.Length + padding2.Length + valueBytes.Length];

        int offset = 0;
        Array.Copy(addressBytes, 0, message, offset, addressBytes.Length);
        offset += addressBytes.Length + padding1.Length;

        Array.Copy(typeTag, 0, message, offset, typeTag.Length);
        offset += typeTag.Length + padding2.Length;

        Array.Copy(valueBytes, 0, message, offset, valueBytes.Length);

        return message;
    }

    public void Dispose()
    {
        if (udpClient != null)
        {
            udpClient.Close();
            udpClient.Dispose();
            udpClient = null;
        }
        isInitialized = false;

        if (enableDebugLogging)
            Debug.Log("OSC Sender disposed");
    }
}