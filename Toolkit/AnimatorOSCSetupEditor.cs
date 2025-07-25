#if UNITY_EDITOR
using UnityEngine;
using UnityEditor;
using UnityEditor.Animations;
using System.Collections.Generic;
using System.Linq;
using System.IO;
#if VRC_SDK_VRCSDK3
using VRC.SDK3.Avatars.ScriptableObjects;
#endif

public class AnimatorOSCSetupEditor : EditorWindow
{
    // アニメーターコントローラー
    public AnimatorController animatorController;
#if VRC_SDK_VRCSDK3
    // VRC用エクスプレッションパラメータ
    public VRCExpressionParameters expressionParameters;
#endif
    // アニメーション対象のオブジェクト
    public GameObject targetObject;

    // パラメータ定義クラス
    [System.Serializable]
    public class ParamDef
    {
        public string name = "OSCParam";
        public AnimatorControllerParameterType type = AnimatorControllerParameterType.Float;
        public string shaderPropertyName = "_MainTex"; // シェーダープロパティ名
        public string oscParamName = "OSCParam"; // ←追加
    }

    public static string ShaderPropToOSCParam(string shaderProp)
    {
        if (string.IsNullOrEmpty(shaderProp)) return shaderProp;
        if (shaderProp.StartsWith("_")) shaderProp = shaderProp.Substring(1);
        var parts = shaderProp.Split('_');
        if (parts.Length < 2) return shaderProp;
        string oscParam = parts[0];
        for (int i = 1; i < parts.Length; i++)
            oscParam += "/" + parts[i];
        return oscParam;
    }

    // パラメータ定義リスト
    public List<ParamDef> paramDefs = new List<ParamDef>();

    // UI用変数
    private int addCount = 1;
    private string addNamePrefix = "OSCParam";
    private AnimatorControllerParameterType addType = AnimatorControllerParameterType.Float;
    private string addShaderProperty = "_MainTex";
    private bool writeDefaults = true;
    private bool showShaderProperties = false;
    private Vector2 scrollPosition;

    // 定数
    private const string AnimationsFolderName = "OSC_Animations";

    /// <summary>
    /// ウィンドウを表示するメニュー項目を追加
    /// </summary>
    [MenuItem("Tools/E2G2/Setup OSC Parameters for Animator & VRCExpressionParameters")]
    public static void ShowWindow()
    {
        GetWindow<AnimatorOSCSetupEditor>("OSC Animator Setup");
    }

    /// <summary>
    /// メインのGUI描画処理
    /// </summary>
    void OnGUI()
    {
        scrollPosition = EditorGUILayout.BeginScrollView(scrollPosition);

        GUILayout.Label("OSCパラメータ自動セットアップ", EditorStyles.boldLabel);
        animatorController = (AnimatorController)EditorGUILayout.ObjectField("Animator Controller", animatorController, typeof(AnimatorController), false);
#if VRC_SDK_VRCSDK3
        expressionParameters = (VRCExpressionParameters)EditorGUILayout.ObjectField("VRCExpressionParameters", expressionParameters, typeof(VRCExpressionParameters), false);
#endif
        targetObject = (GameObject)EditorGUILayout.ObjectField("Target Object", targetObject, typeof(GameObject), true);

        DrawShaderPropertiesSection();
        writeDefaults = EditorGUILayout.Toggle("Write Defaults", writeDefaults);
        DrawParamDefsSection();
        DrawAddParamSection();
        DrawActionButtons();

        EditorGUILayout.EndScrollView();
    }

    /// <summary>
    /// シェーダープロパティ表示セクションの描画
    /// </summary>
    void DrawShaderPropertiesSection()
    {
        if (targetObject == null) return;
        var renderer = targetObject.GetComponent<Renderer>();
        if (renderer == null) return;
        var materials = renderer.sharedMaterials;
        if (materials == null || materials.Length == 0) return;

        string foldoutTitle = materials.Length == 1
            ? $"利用可能なシェーダープロパティ: '{materials[0].name}'"
            : $"利用可能なシェーダープロパティ（{materials.Length}マテリアル）";
        showShaderProperties = EditorGUILayout.Foldout(showShaderProperties, foldoutTitle, true);
        if (!showShaderProperties) return;

        EditorGUI.indentLevel++;
        for (int matIndex = 0; matIndex < materials.Length; matIndex++)
        {
            var material = materials[matIndex];
            if (material == null || material.shader == null) continue;
            var shader = material.shader;
            if (materials.Length > 1)
            {
                GUILayout.Label($"Material {matIndex}: {material.name}", EditorStyles.boldLabel);
                EditorGUI.indentLevel++;
            }
            int propertyCount = ShaderUtil.GetPropertyCount(shader);
            for (int i = 0; i < propertyCount; i++)
            {
                string propertyName = ShaderUtil.GetPropertyName(shader, i);
                ShaderUtil.ShaderPropertyType propertyType = ShaderUtil.GetPropertyType(shader, i);
                GUILayout.BeginHorizontal();
                if (GUILayout.Button("+", EditorStyles.miniButton, GUILayout.Width(22), GUILayout.Height(15)))
                {
                    paramDefs.Add(new ParamDef {
                        name = ShaderPropToOSCParam(propertyName), // Animator等のパラメータ名
                        type = AnimatorControllerParameterType.Float,
                        shaderPropertyName = propertyName,         // AnimationClip用
                        oscParamName = ShaderPropToOSCParam(propertyName)
                    });
                }
                if (GUILayout.Button("Copy", EditorStyles.miniButton, GUILayout.Width(45), GUILayout.Height(15)))
                {
                    GUIUtility.systemCopyBuffer = propertyName;
                    Debug.Log($"シェーダープロパティ '{propertyName}' をクリップボードにコピーしました");
                }
                GUILayout.Label($"  {propertyName} ({propertyType})", EditorStyles.miniLabel);
                GUILayout.EndHorizontal();
                // 右クリックメニュー
                var labelRect = GUILayoutUtility.GetLastRect();
                if (Event.current.type == EventType.MouseDown && Event.current.button == 1 && labelRect.Contains(Event.current.mousePosition))
                {
                    ShowShaderPropertyContextMenu(propertyName, propertyType, matIndex, materials.Length);
                    Event.current.Use();
                }
            }
            if (materials.Length > 1)
            {
                EditorGUI.indentLevel--;
                GUILayout.Space(4);
            }
        }
        EditorGUI.indentLevel--;
    }

    /// <summary>
    /// シェーダープロパティ右クリックメニュー
    /// </summary>
    /// <param name="propertyName">シェーダープロパティ名</param>
    /// <param name="propertyType">シェーダープロパティ型</param>
    /// <param name="matIndex">マテリアルインデックス</param>
    /// <param name="matCount">マテリアル数</param>
    void ShowShaderPropertyContextMenu(string propertyName, ShaderUtil.ShaderPropertyType propertyType, int matIndex, int matCount)
    {
        var menu = new GenericMenu();
        menu.AddItem(new GUIContent("プロパティ名をコピー"), false, () => {
            GUIUtility.systemCopyBuffer = propertyName;
            Debug.Log($"シェーダープロパティ '{propertyName}' をクリップボードにコピーしました");
        });
        menu.AddItem(new GUIContent("プロパティ情報をコピー"), false, () => {
            string fullInfo = $"{propertyName} ({propertyType})";
            GUIUtility.systemCopyBuffer = fullInfo;
            Debug.Log($"シェーダープロパティ情報 '{fullInfo}' をクリップボードにコピーしました");
        });
        if (matCount > 1)
        {
            menu.AddItem(new GUIContent($"マテリアルインデックス[{matIndex}]付きでコピー"), false, () => {
                string fullInfo = $"{propertyName} ({propertyType}) - Material[{matIndex}]";
                GUIUtility.systemCopyBuffer = fullInfo;
                Debug.Log($"シェーダープロパティ情報 '{fullInfo}' をクリップボードにコピーしました");
            });
        }
        menu.ShowAsContext();
    }

    /// <summary>
    /// パラメータリスト表示セクションの描画
    /// </summary>
    void DrawParamDefsSection()
    {
        GUILayout.Label("追加/削除するパラメータ:");
        for (int i = 0; i < paramDefs.Count; i++)
        {
            GUILayout.BeginVertical("box");
            GUILayout.BeginHorizontal();
            paramDefs[i].name = EditorGUILayout.TextField("Name", paramDefs[i].name);
            paramDefs[i].type = (AnimatorControllerParameterType)EditorGUILayout.EnumPopup("Type", paramDefs[i].type, GUILayout.Width(80));
            if (GUILayout.Button("−", GUILayout.Width(20)))
            {
                paramDefs.RemoveAt(i);
                i = Mathf.Max(-1, i - 1); // インデックスずれ防止
                GUILayout.EndHorizontal();
                GUILayout.EndVertical();
                continue;
            }
            GUILayout.EndHorizontal();
            // シェーダープロパティ名フィールド
            GUILayout.BeginHorizontal();
            paramDefs[i].shaderPropertyName = EditorGUILayout.TextField("Shader Property", paramDefs[i].shaderPropertyName);
            if (GUILayout.Button("📋", GUILayout.Width(20)))
            {
                paramDefs[i].shaderPropertyName = GUIUtility.systemCopyBuffer;
            }
            GUILayout.EndHorizontal();
            // 右クリックメニュー
            var shaderPropertyRect = GUILayoutUtility.GetLastRect();
            if (Event.current.type == EventType.MouseDown && Event.current.button == 1 && shaderPropertyRect.Contains(Event.current.mousePosition))
            {
                ShowShaderPropertyFieldContextMenu(i);
                Event.current.Use();
            }
            GUILayout.EndVertical();
        }
    }

    /// <summary>
    /// シェーダープロパティフィールド右クリックメニュー
    /// </summary>
    /// <param name="index">パラメータリストのインデックス</param>
    void ShowShaderPropertyFieldContextMenu(int index)
    {
        var menu = new GenericMenu();
        menu.AddItem(new GUIContent("クリップボードから貼り付け"), false, () => {
            paramDefs[index].shaderPropertyName = GUIUtility.systemCopyBuffer;
        });
        menu.AddItem(new GUIContent("クリア"), false, () => {
            paramDefs[index].shaderPropertyName = "";
        });
        menu.ShowAsContext();
    }

    /// <summary>
    /// パラメータ追加UIセクションの描画
    /// </summary>
    void DrawAddParamSection()
    {
        GUILayout.Space(8);
        GUILayout.BeginHorizontal();
        GUILayout.Label("個数:", GUILayout.Width(50));
        addCount = EditorGUILayout.IntField(addCount, GUILayout.Width(60));
        addCount = Mathf.Max(1, addCount);
        GUILayout.Label("接頭辞:", GUILayout.Width(50));
        addNamePrefix = EditorGUILayout.TextField(addNamePrefix, GUILayout.Width(100));
        GUILayout.Label("型:", GUILayout.Width(40));
        addType = (AnimatorControllerParameterType)EditorGUILayout.EnumPopup(addType, GUILayout.Width(80));
        GUILayout.EndHorizontal();
        GUILayout.BeginHorizontal();
        GUILayout.Label("Shader Property:", GUILayout.Width(100));
        addShaderProperty = EditorGUILayout.TextField(addShaderProperty, GUILayout.Width(150));
        if (GUILayout.Button("📋", GUILayout.Width(20)))
        {
            addShaderProperty = GUIUtility.systemCopyBuffer;
        }
        if (GUILayout.Button("Add"))
        {
            int startIdx = paramDefs.Count + 1;
            for (int j = 0; j < addCount; j++)
            {
                var def = new ParamDef();
                def.name = addNamePrefix + (startIdx + j);
                def.type = addType;
                def.shaderPropertyName = addShaderProperty;
                paramDefs.Add(def);
            }
        }
        GUILayout.EndHorizontal();
        // 右クリックメニュー
        var addShaderPropertyRect = GUILayoutUtility.GetLastRect();
        if (Event.current.type == EventType.MouseDown && Event.current.button == 1 && addShaderPropertyRect.Contains(Event.current.mousePosition))
        {
            var menu = new GenericMenu();
            menu.AddItem(new GUIContent("クリップボードから貼り付け"), false, () => {
                addShaderProperty = GUIUtility.systemCopyBuffer;
            });
            menu.AddItem(new GUIContent("クリア"), false, () => {
                addShaderProperty = "";
            });
            menu.ShowAsContext();
            Event.current.Use();
        }
    }

    /// <summary>
    /// アクションボタン（追加・削除）の描画
    /// </summary>
    void DrawActionButtons()
    {
        GUILayout.Space(8);
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("パラメータを追加"))
        {
            AddParamsToAnimator();
#if VRC_SDK_VRCSDK3
            AddParamsToVRCExpressionParameters();
#endif
            CreateLayersAndStates();
        }
        if (GUILayout.Button("パラメータを削除"))
        {
            RemoveParamsFromAnimator();
#if VRC_SDK_VRCSDK3
            RemoveParamsFromVRCExpressionParameters();
#endif
            RemoveLayersAndStates();
        }
        GUILayout.EndHorizontal();
    }

    /// <summary>
    /// AnimatorControllerにパラメータを追加
    /// </summary>
    void AddParamsToAnimator()
    {
        if (animatorController == null) { Debug.LogWarning("Animator Controllerが未設定です。"); return; }
        foreach (var def in paramDefs)
        {
            if (!animatorController.parameters.Any(p => p.name == def.oscParamName))
            {
                animatorController.AddParameter(def.oscParamName, def.type);
                Debug.Log($"Animatorパラメータ追加: {def.oscParamName} ({def.type})");
            }
        }
        EditorUtility.SetDirty(animatorController);
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    /// AnimatorControllerからパラメータを削除
    /// </summary>
    void RemoveParamsFromAnimator()
    {
        if (animatorController == null) { Debug.LogWarning("Animator Controllerが未設定です。"); return; }
        int removedCount = 0;
        foreach (var def in paramDefs)
        {
            var param = animatorController.parameters.FirstOrDefault(p => p.name == def.oscParamName);
            if (param != null)
            {
                animatorController.RemoveParameter(param);
                Debug.Log($"Animatorパラメータ削除: {def.oscParamName}");
                removedCount++;
            }
        }
        if (removedCount == 0)
        {
            Debug.LogWarning("paramDefsに該当するAnimatorパラメータが見つかりませんでした。");
        }
        else
        {
            EditorUtility.SetDirty(animatorController);
            AssetDatabase.SaveAssets();
        }
    }

    /// <summary>
    /// レイヤー・ステート・アニメーションを作成
    /// </summary>
    void CreateLayersAndStates()
    {
        if (animatorController == null) { Debug.LogWarning("Animator Controllerが未設定です。"); return; }
        string controllerPath = AssetDatabase.GetAssetPath(animatorController);
        string animationsFolderPath = Path.GetDirectoryName(controllerPath) + "/" + AnimationsFolderName;
        if (!AssetDatabase.IsValidFolder(animationsFolderPath))
        {
            AssetDatabase.CreateFolder(Path.GetDirectoryName(controllerPath), AnimationsFolderName);
        }
        foreach (var def in paramDefs)
        {
            AnimatorControllerLayer layer = GetOrCreateLayer(def.oscParamName);
            layer.defaultWeight = 1.0f;
            AnimatorState state = GetOrCreateState(layer, def.oscParamName);
            state.writeDefaultValues = writeDefaults;
            AnimationClip animClip = CreateAnimationClip(def.shaderPropertyName, animationsFolderPath, def.type);
            state.motion = animClip;
            if (def.type == AnimatorControllerParameterType.Float)
            {
                state.timeParameterActive = true;
                state.timeParameter = def.name;
            }
            Debug.Log($"レイヤー・ステート・アニメーション作成: {def.oscParamName}");
        }
        EditorUtility.SetDirty(animatorController);
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    /// レイヤー・ステート・アニメーションを削除
    /// </summary>
    void RemoveLayersAndStates()
    {
        if (animatorController == null)
        {
            Debug.LogWarning("Animator Controllerが未設定です。");
            return;
        }
        if (paramDefs == null || paramDefs.Count == 0)
        {
            Debug.LogWarning("削除対象パラメータがありません。");
            return;
        }
        string animatorPath = AssetDatabase.GetAssetPath(animatorController);
        if (string.IsNullOrEmpty(animatorPath))
        {
            Debug.LogError("Animator Controllerがディスクに保存されていません。先に保存してください。");
            return;
        }
        string animationsFolderPath = Path.GetDirectoryName(animatorPath) + "/" + AnimationsFolderName;

        // 削除対象レイヤーのインデックスをリストアップ（後ろから削除）
        List<int> removeIndices = new List<int>();
        for (int i = 0; i < animatorController.layers.Length; i++)
        {
            var layer = animatorController.layers[i];
            if (layer != null && paramDefs.Any(def => def.name == layer.name))
            {
                removeIndices.Add(i);
            }
        }
        removeIndices.Sort();
        removeIndices.Reverse(); // 後ろから削除

        foreach (int idx in removeIndices)
        {
            string layerName = animatorController.layers[idx].name;
            animatorController.RemoveLayer(idx);
            Debug.Log($"レイヤー削除: {layerName}");
        }

        int layersRemoved = 0;
        int animationsRemoved = 0;
        int errors = 0;
        foreach (var def in paramDefs)
        {
            if (def == null || string.IsNullOrEmpty(def.name))
            {
                Debug.LogWarning("nullまたは空のパラメータ定義をスキップします。");
                continue;
            }
            try
            {
                var layer = animatorController.layers.FirstOrDefault(l => l != null && l.name == def.name);
                if (layer != null)
                {
                    int layerIndex = System.Array.IndexOf(animatorController.layers, layer);
                    if (layerIndex >= 0 && layerIndex < animatorController.layers.Length)
                    {
                        animatorController.RemoveLayer(layerIndex);
                        Debug.Log($"レイヤー削除: {def.name}");
                        layersRemoved++;
                    }
                    else
                    {
                        Debug.LogWarning($"レイヤーインデックス不正: {def.name}: {layerIndex}");
                        errors++;
                    }
                }
                else
                {
                    Debug.Log($"レイヤーが見つかりません: {def.name}");
                }
                string animPath = animationsFolderPath + "/" + def.shaderPropertyName + ".anim";
                if (!string.IsNullOrEmpty(animPath))
                {
                    var animClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(animPath);
                    if (animClip != null)
                    {
                        try
                        {
                            AssetDatabase.DeleteAsset(animPath);
                            Debug.Log($"アニメーション削除: {def.shaderPropertyName}.anim");
                            animationsRemoved++;
                        }
                        catch (System.Exception ex)
                        {
                            Debug.LogError($"アニメーションファイル削除失敗 {animPath}: {ex.Message}");
                            errors++;
                        }
                    }
                    else
                    {
                        Debug.Log($"アニメーションファイルが見つかりません: {animPath}");
                    }
                }
                else
                {
                    Debug.LogWarning($"アニメーションパス不正: {def.name}");
                    errors++;
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"パラメータ処理中にエラー: {def.name}: {ex.Message}");
                errors++;
            }
        }
        if (layersRemoved > 0 || animationsRemoved > 0)
        {
            try
            {
                EditorUtility.SetDirty(animatorController);
                AssetDatabase.SaveAssets();
                Debug.Log($"削除完了: {layersRemoved}レイヤー, {animationsRemoved}アニメーション削除");
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"変更保存失敗: {ex.Message}");
                errors++;
            }
        }
        else
        {
            Debug.Log("削除対象のレイヤー・アニメーションがありませんでした。");
        }
        if (errors > 0)
        {
            Debug.LogWarning($"削除処理で{errors}件のエラーが発生しました。詳細はコンソールを確認してください。");
        }
        // 空のOSC_Animationsフォルダを削除
        try
        {
            if (AssetDatabase.IsValidFolder(animationsFolderPath))
            {
                string[] assetsInFolder = AssetDatabase.FindAssets("", new string[] { animationsFolderPath });
                if (assetsInFolder.Length == 0)
                {
                    AssetDatabase.DeleteAsset(animationsFolderPath);
                    Debug.Log("空のOSC_Animationsフォルダを削除しました。");
                }
            }
        }
        catch (System.Exception ex)
        {
            Debug.LogWarning($"空フォルダのクリーンアップ失敗: {ex.Message}");
        }
    }

    /// <summary>
    /// レイヤーを取得または新規作成
    /// </summary>
    /// <param name="layerName">レイヤー名</param>
    /// <returns>AnimatorControllerLayer</returns>
    AnimatorControllerLayer GetOrCreateLayer(string layerName)
    {
        var existingLayer = animatorController.layers.FirstOrDefault(l => l.name == layerName);
        if (existingLayer != null)
        {
            return existingLayer;
        }
        var newLayer = new AnimatorControllerLayer();
        newLayer.name = layerName;
        newLayer.defaultWeight = 1.0f;
        newLayer.stateMachine = new AnimatorStateMachine();
        newLayer.stateMachine.name = layerName;
        newLayer.stateMachine.hideFlags = HideFlags.HideInHierarchy;
        if (AssetDatabase.GetAssetPath(animatorController) != "")
        {
            AssetDatabase.AddObjectToAsset(newLayer.stateMachine, animatorController);
        }
        animatorController.AddLayer(newLayer);
        return animatorController.layers.Last();
    }

    /// <summary>
    /// ステートを取得または新規作成
    /// </summary>
    /// <param name="layer">レイヤー</param>
    /// <param name="stateName">ステート名</param>
    /// <returns>AnimatorState</returns>
    AnimatorState GetOrCreateState(AnimatorControllerLayer layer, string stateName)
    {
        var existingState = layer.stateMachine.states.FirstOrDefault(s => s.state.name == stateName);
        if (existingState.state != null)
        {
            return existingState.state;
        }
        var newState = layer.stateMachine.AddState(stateName);
        newState.writeDefaultValues = writeDefaults;
        return newState;
    }

    /// <summary>
    /// アニメーションクリップを作成
    /// </summary>
    /// <param name="clipName">クリップ名</param>
    /// <param name="folderPath">保存先フォルダパス</param>
    /// <param name="paramType">パラメータ型</param>
    /// <returns>AnimationClip</returns>
    AnimationClip CreateAnimationClip(string clipName, string folderPath, AnimatorControllerParameterType paramType)
    {
        string clipPath = folderPath + "/" + clipName + ".anim";
        var existingClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(clipPath);
        if (existingClip != null)
        {
            return existingClip;
        }
        var newClip = new AnimationClip();
        newClip.name = clipName;
        if (targetObject != null)
        {
            var renderer = targetObject.GetComponent<Renderer>();
            if (renderer != null)
            {
                var materials = renderer.sharedMaterials;
                if (materials != null && materials.Length > 0)
                {
                    var paramDef = paramDefs.FirstOrDefault(p => p.name == clipName);
                    string propertyName = paramDef?.shaderPropertyName ?? "_MainTex";
                    bool propertyFound = false;
                    for (int matIndex = 0; matIndex < materials.Length; matIndex++)
                    {
                        var material = materials[matIndex];
                        if (material != null && material.shader != null)
                        {
                            var shader = material.shader;
                            if (shader.FindPropertyIndex(propertyName) >= 0)
                            {
                                var curve = new AnimationCurve();
                                if (paramType == AnimatorControllerParameterType.Bool || paramType == AnimatorControllerParameterType.Trigger)
                                {
                                    curve.AddKey(0f, 0f);
                                    curve.AddKey(1f, 1f);
                                    string materialPath = matIndex == 0 ? "" : $"materials[{matIndex}]";
                                    newClip.SetCurve(materialPath, typeof(Material), propertyName, curve);
                                }
                                else if (paramType == AnimatorControllerParameterType.Int)
                                {
                                    curve.AddKey(0f, 0f);
                                    curve.AddKey(1f, 1f);
                                    string materialPath = matIndex == 0 ? "" : $"materials[{matIndex}]";
                                    newClip.SetCurve(materialPath, typeof(Material), propertyName, curve);
                                }
                                else // Float
                                {
                                    curve.AddKey(0f, 0f);
                                    curve.AddKey(1f, 1f);
                                    for (int i = 0; i < curve.keys.Length; i++)
                                    {
                                        AnimationUtility.SetKeyLeftTangentMode(curve, i, AnimationUtility.TangentMode.Linear);
                                        AnimationUtility.SetKeyRightTangentMode(curve, i, AnimationUtility.TangentMode.Linear);
                                    }
                                    string materialPath = matIndex == 0 ? "" : $"materials[{matIndex}]";
                                    newClip.SetCurve(materialPath, typeof(Material), propertyName, curve);
                                }
                                propertyFound = true;
                                Debug.Log($"シェーダープロパティのアニメーション作成: {propertyName} (material[{matIndex}] '{material.name}')");
                            }
                            else
                            {
                                Debug.LogWarning($"シェーダープロパティ '{propertyName}' が material[{matIndex}] '{material.name}' に見つかりません");
                            }
                        }
                    }
                    if (!propertyFound)
                    {
                        Debug.LogWarning($"シェーダープロパティ '{propertyName}' がどのマテリアルにも見つかりません。ダミーアニメーションを使用します。");
                        CreateDummyAnimation(newClip);
                    }
                }
                else
                {
                    Debug.LogWarning($"ターゲットオブジェクト '{targetObject.name}' にマテリアルがありません。ダミーアニメーションを使用します。");
                    CreateDummyAnimation(newClip);
                }
            }
            else
            {
                Debug.LogWarning($"ターゲットオブジェクト '{targetObject.name}' にRendererがありません。ダミーアニメーションを使用します。");
                CreateDummyAnimation(newClip);
            }
        }
        else
        {
            Debug.LogWarning("ターゲットオブジェクトが未設定です。ダミーアニメーションを使用します。");
            CreateDummyAnimation(newClip);
        }
        AssetDatabase.CreateAsset(newClip, clipPath);
        AssetDatabase.SaveAssets();
        return newClip;
    }

    /// <summary>
    /// ダミーアニメーションを作成（アニメーションが空にならないように）
    /// </summary>
    /// <param name="clip">AnimationClip</param>
    void CreateDummyAnimation(AnimationClip clip)
    {
        var dummyCurve = new AnimationCurve();
        dummyCurve.AddKey(0f, 1f);
        dummyCurve.AddKey(1f, 1f);
        clip.SetCurve("", typeof(GameObject), "m_IsActive", dummyCurve);
    }

#if VRC_SDK_VRCSDK3
    /// <summary>
    /// VRCExpressionParametersにパラメータを追加
    /// </summary>
    void AddParamsToVRCExpressionParameters()
    {
        if (expressionParameters == null) { Debug.LogWarning("VRCExpressionParametersが未設定です。"); return; }
        var paramList = expressionParameters.parameters != null ? expressionParameters.parameters.ToList() : new List<VRCExpressionParameters.Parameter>();
        foreach (var def in paramDefs)
        {
            if (!paramList.Exists(p => p.name == def.oscParamName))
            {
                var vrcType = VRCExpressionParameters.ValueType.Float;
                if (def.type == AnimatorControllerParameterType.Int) vrcType = VRCExpressionParameters.ValueType.Int;
                if (def.type == AnimatorControllerParameterType.Bool) vrcType = VRCExpressionParameters.ValueType.Bool;
                if (def.type == AnimatorControllerParameterType.Trigger) vrcType = VRCExpressionParameters.ValueType.Bool;
                paramList.Add(new VRCExpressionParameters.Parameter
                {
                    name = def.oscParamName,
                    valueType = vrcType,
                    saved = false
                });
                Debug.Log($"VRCExpressionParameter追加: {def.oscParamName} ({vrcType})");
            }
        }
        expressionParameters.parameters = paramList.ToArray();
        EditorUtility.SetDirty(expressionParameters);
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    /// VRCExpressionParametersからパラメータを削除
    /// </summary>
    void RemoveParamsFromVRCExpressionParameters()
    {
        if (expressionParameters == null) { Debug.LogWarning("VRCExpressionParametersが未設定です。"); return; }
        var paramList = expressionParameters.parameters != null ? expressionParameters.parameters.ToList() : new List<VRCExpressionParameters.Parameter>();
        int removedCount = 0;
        foreach (var def in paramDefs)
        {
            var param = paramList.FirstOrDefault(p => p.name == def.oscParamName);
            if (param != null)
            {
                paramList.Remove(param);
                Debug.Log($"VRCExpressionParameter削除: {def.oscParamName}");
                removedCount++;
            }
        }
        if (removedCount == 0)
        {
            Debug.LogWarning("paramDefsに該当するVRCExpressionParametersが見つかりませんでした。");
        }
        else
        {
            expressionParameters.parameters = paramList.ToArray();
            EditorUtility.SetDirty(expressionParameters);
            AssetDatabase.SaveAssets();
        }
    }
#endif
}
#endif