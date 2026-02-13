# 📸 Receipt Maker - スクリーンショット作成ガイド

Play Storeリスティング用のスクリーンショット作成手順

---

## 必要なスクリーンショット

### 必須（Phone）
- **サイズ**: 1080 x 1920 px (縦向き)
- **枚数**: 最低2枚、推奨4-8枚
- **フォーマット**: PNG または JPG

### 推奨内容

1. **ホーム画面** - 領収書一覧
2. **作成画面** - 新規領収書作成フォーム
3. **PDFプレビュー** - 生成されたPDF
4. **統計画面** - ダッシュボード
5. **設定画面** - 発行者プロファイル管理

---

## 方法1: Chrome DevToolsで作成（推奨）

### 手順

1. **Chrome で Webアプリを開く**
   ```
   https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai
   ```

2. **DevTools を開く**
   - Windows/Linux: `F12` または `Ctrl+Shift+I`
   - Mac: `Cmd+Option+I`

3. **デバイスツールバーを有効化**
   - Windows/Linux: `Ctrl+Shift+M`
   - Mac: `Cmd+Shift+M`

4. **デバイス設定**
   - デバイス選択: `Pixel 5` (1080 x 2340)
   - または `Custom` で `1080 x 1920` に設定

5. **スクリーンショット撮影**
   - `Ctrl+Shift+P` (Cmd+Shift+P on Mac)
   - 検索: `Capture screenshot`
   - または `Capture full size screenshot`

6. **各画面を撮影**
   - Home → +ボタン → Receipt Form
   - Preview → PDF画面
   - Settings → Statistics
   - Settings → Issuer Profiles

---

## 方法2: Androidエミュレーターで作成

### Android Studioエミュレーター使用

1. **エミュレーター起動**
   ```bash
   # Android Studioから起動
   # または
   emulator -avd Pixel_5_API_31
   ```

2. **APKインストール**
   ```bash
   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

3. **スクリーンショット撮影**
   ```bash
   # 方法A: adbコマンド
   adb shell screencap -p /sdcard/screenshot1.png
   adb pull /sdcard/screenshot1.png ./screenshots/screenshot1.png
   
   # 方法B: エミュレーターのツールバー
   # カメラアイコンをクリック
   ```

---

## 方法3: 実機で作成

### USBデバッグ接続

1. **開発者向けオプション有効化**
   - 設定 → デバイス情報 → ビルド番号を7回タップ

2. **USBデバッグ有効化**
   - 設定 → 開発者向けオプション → USBデバッグ

3. **接続確認**
   ```bash
   adb devices
   ```

4. **スクリーンショット撮影**
   ```bash
   adb shell screencap -p /sdcard/screenshot.png
   adb pull /sdcard/screenshot.png
   ```

---

## スクリーンショット編集のヒント

### 推奨ツール

1. **GIMP** (無料)
   - リサイズ: Image → Scale Image
   - 目標: 1080 x 1920 px

2. **Photoshop** (有料)
   - Image → Image Size

3. **オンラインツール**
   - https://www.resizepixel.com/
   - https://www.iloveimg.com/resize-image

### テキストオーバーレイ追加（オプション）

**効果的なスクリーンショットにするため、説明テキストを追加**:

```
Screenshot 1: ホーム画面
テキストオーバーレイ: "領収書を簡単に管理"

Screenshot 2: 作成画面
テキストオーバーレイ: "数秒で領収書作成"

Screenshot 3: PDFプレビュー
テキストオーバーレイ: "プロフェッショナルなPDF"

Screenshot 4: 統計画面
テキストオーバーレイ: "売上を見える化"
```

### Figmaテンプレート（推奨）

1. **Figma無料アカウント作成**
   - https://www.figma.com/

2. **フレーム作成**
   - サイズ: 1080 x 1920 px

3. **スクリーンショット配置**
   - ドラッグ&ドロップ

4. **テキスト追加**
   - タイトル: 32-48 px
   - 説明文: 24-32 px

5. **エクスポート**
   - Format: PNG
   - Scale: 1x

---

## 機能グラフィック作成

### 仕様

- **サイズ**: 1024 x 500 px
- **フォーマット**: PNG または JPG
- **用途**: Play Storeのヘッダー画像

### 内容例

```
背景: グラデーション（白 → 薄いグレー）
アプリアイコン: 中央左
テキスト: 
  "Receipt Maker"（大）
  "シンプル領収書管理"（小）
```

### Canvaテンプレート使用（推奨）

1. **Canva無料アカウント**
   - https://www.canva.com/

2. **カスタムサイズ作成**
   - 1024 x 500 px

3. **デザイン作成**
   - アプリアイコン配置
   - タイトル追加
   - 簡潔な説明文

4. **ダウンロード**
   - PNG形式

---

## チェックリスト

### Phone スクリーンショット

- [ ] Screenshot 1: ホーム画面（領収書一覧）
- [ ] Screenshot 2: 作成画面（フォーム入力）
- [ ] Screenshot 3: PDFプレビュー
- [ ] Screenshot 4: 統計ダッシュボード
- [ ] Screenshot 5: 設定画面（オプション）

### 仕様確認

- [ ] すべて1080 x 1920 px
- [ ] PNG または JPG形式
- [ ] ファイルサイズ < 8MB
- [ ] 最低2枚、最大8枚

### 機能グラフィック

- [ ] 1024 x 500 px
- [ ] アプリアイコン含む
- [ ] タイトルと説明文

---

## サンプルファイル名

```
screenshots/
├── phone/
│   ├── 01_home_screen.png
│   ├── 02_create_receipt.png
│   ├── 03_pdf_preview.png
│   ├── 04_statistics.png
│   └── 05_settings.png
└── feature_graphic.png
```

---

## 自動化スクリプト（オプション）

### スクリーンショット一括撮影

```bash
#!/bin/bash
# screenshots.sh

# Androidエミュレーター接続確認
adb devices

# 各画面のスクリーンショット撮影
echo "Taking screenshots..."

# 1. ホーム画面
adb shell input tap 540 1600  # Homeタブ
sleep 1
adb shell screencap -p /sdcard/01_home.png

# 2. 作成画面
adb shell input tap 900 1800  # +ボタン
sleep 1
adb shell screencap -p /sdcard/02_create.png

# 3. 設定画面
adb shell input tap 900 1600  # Settingsタブ
sleep 1
adb shell screencap -p /sdcard/03_settings.png

# スクリーンショットをPCに転送
echo "Pulling screenshots..."
mkdir -p screenshots
adb pull /sdcard/01_home.png screenshots/
adb pull /sdcard/02_create.png screenshots/
adb pull /sdcard/03_settings.png screenshots/

# クリーンアップ
adb shell rm /sdcard/*.png

echo "Screenshots saved to ./screenshots/"
```

使用方法:
```bash
chmod +x screenshots.sh
./screenshots.sh
```

---

## 完成例

### 理想的なスクリーンショット構成

1. **ホーム画面**
   - 複数の領収書が表示されている
   - 検索バーが見える
   - ボトムナビゲーション表示

2. **作成画面**
   - フォームに入力済み
   - すべてのフィールドが見える
   - Previewボタンが強調

3. **PDFプレビュー**
   - 生成されたPDFが表示
   - プロフェッショナルな見た目

4. **統計画面**
   - 数字が入っている
   - グラフ/チャートがある

5. **設定画面**
   - 発行者プロファイル一覧
   - 機能がわかりやすい

---

**🎨 魅力的なスクリーンショットで、より多くのユーザーを獲得しましょう！**
