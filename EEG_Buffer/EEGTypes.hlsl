#ifndef EEG_TYPES_INCLUDED
#define EEG_TYPES_INCLUDED

// EEGデータ型定義
// パワーバンドデータの構造体定義

// --- PowerBands構造体定義 ---
struct PowerBands {
    float gamma;
    float beta;
    float alpha;
    float theta;
    float delta;
    float focus;
    float relax;
    float debug;
};

#endif // EEG_TYPES_INCLUDED