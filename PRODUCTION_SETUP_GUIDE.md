# 🚀 Receipt Maker - 本番環境設定ガイド

このガイドでは、Receipt Makerを本番環境にデプロイするための詳細な手順を説明します。

---

## 📋 事前準備チェックリスト

以下のアカウントが必要です：

- [ ] Google アカウント（Google Cloud Console用）
- [ ] Microsoft アカウント（Azure Portal用）
- [ ] Google AdMob アカウント
- [ ] Google Play Developer アカウント（$25 登録料）

---

## 1️⃣ Google Drive連携設定（必須）

### ステップ1: Google Cloud Consoleでプロジェクト作成

**URL**: https://console.cloud.google.com/

1. **新しいプロジェクト作成**
   - プロジェクト名: `Receipt Maker`
   - 組織: なし（個人開発の場合）

2. **APIとサービスを有効化**
   - 左メニュー → **APIとサービス** → **ライブラリ**
   - 検索: `Google Drive API`
   - **有効にする** をクリック

### ステップ2: OAuth同意画面の設定

1. **APIとサービス** → **OAuth同意画面**

2. **User Type選択**
   - **外部** を選択（一般ユーザー向け）
   - **作成** をクリック

3. **アプリ情報入力**
   ```
   アプリ名: Receipt Maker
   ユーザーサポートメール: あなたのメールアドレス
   デベロッパーの連絡先情報: あなたのメールアドレス
   ```

4. **スコープの追加**
   - **スコープを追加または削除** をクリック
   - フィルタで検索: `drive.file`
   - **Google Drive API** → `.../auth/drive.file` を選択
   - **更新** をクリック

5. **テストユーザー追加（オプション）**
   - 開発中は自分のメールアドレスを追加
   - 本番公開時は不要

6. **概要確認** → **ダッシュボードに戻る**

### ステップ3: Android用 OAuth 2.0 クライアントID作成

1. **APIとサービス** → **認証情報**

2. **認証情報を作成** → **OAuth クライアント ID**

3. **アプリケーションの種類**: `Android`

4. **必要情報入力**:

   **パッケージ名**:
   ```
   com.receiptmaker.receipt
   ```

   **SHA-1証明書フィンガープリント**:
   ```bash
   # リリースキーストアから取得
   cd /home/user/flutter_app/android
   keytool -list -v -keystore release-key.jks -alias release -storepass android -keypass android
   
   # 出力例:
   # SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
   ```
   
   ⚠️ **重要**: SHA1の値をコピーして貼り付けてください

5. **作成** をクリック

### ステップ4: Web用 OAuth 2.0 クライアントID作成

1. **認証情報を作成** → **OAuth クライアント ID**

2. **アプリケーションの種類**: `ウェブ アプリケーション`

3. **名前**: `Receipt Maker Web`

4. **承認済みのリダイレクト URI**:
   ```
   https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai
   http://localhost:5060
   ```
   
   ⚠️ **本番環境**: 実際のWebサイトURLに置き換えてください

5. **作成** をクリック

### ステップ5: google-services.jsonのダウンロード

⚠️ **重要**: Firebase Consoleから取得する必要があります

1. **Firebase Console**: https://console.firebase.google.com/

2. **プロジェクトを追加** → 既存のGoogle Cloudプロジェクトを選択

3. **Android アプリを追加**
   - パッケージ名: `com.receiptmaker.receipt`
   - アプリのニックネーム: `Receipt Maker`
   - デバッグ用の署名証明書: 上記のSHA-1を入力

4. **google-services.json をダウンロード**

5. **配置**:
   ```bash
   # ダウンロードしたファイルを配置
   cp ~/Downloads/google-services.json /home/user/flutter_app/android/app/google-services.json
   ```

6. **パッケージ名の確認**:
   ```bash
   grep "package_name" /home/user/flutter_app/android/app/google-services.json
   # 出力: "package_name": "com.receiptmaker.receipt"
   ```

---

## 2️⃣ OneDrive連携設定（オプション）

### ステップ1: Azure Portalでアプリ登録

**URL**: https://portal.azure.com/

1. **Azure Active Directory** → **アプリの登録**

2. **新規登録**
   ```
   名前: Receipt Maker
   サポートされているアカウントの種類: 
     任意の組織ディレクトリ内のアカウントと個人の Microsoft アカウント
   リダイレクト URI: (後で設定)
   ```

3. **登録** をクリック

### ステップ2: API アクセス許可の設定

1. **API のアクセス許可** → **アクセス許可の追加**

2. **Microsoft Graph** を選択

3. **委任されたアクセス許可** を選択

4. 以下のアクセス許可を追加:
   - `Files.ReadWrite` - ファイルの読み取りと書き込み
   - `offline_access` - リフレッシュトークン取得

5. **アクセス許可の追加** → **管理者の同意を付与** をクリック

### ステップ3: クライアントID取得

1. **概要** ページ
   - **アプリケーション (クライアント) ID** をコピー
   - 例: `12345678-1234-1234-1234-123456789abc`

### ステップ4: リダイレクトURI設定

1. **認証** → **プラットフォームの追加** → **モバイルとデスクトップ アプリケーション**

2. **カスタム リダイレクト URI**:
   ```
   msauth://com.receiptmaker.receipt/SIGNATURE_HASH
   ```
   
   ⚠️ **SIGNATURE_HASH**: SHA-1を特定の形式に変換したもの
   
   ```bash
   # 変換方法（例）
   # SHA1: AA:BB:CC:DD... → aabbccdd...（小文字、コロン削除）
   ```

3. **構成** をクリック

### ステップ5: コードの更新

`lib/services/onedrive_service.dart` を編集:

```dart
static const String _clientId = '12345678-1234-1234-1234-123456789abc'; // ← あなたのクライアントID
static const String _redirectUri = 'msauth://com.receiptmaker.receipt/SIGNATURE_HASH'; // ← あなたの署名ハッシュ
```

---

## 3️⃣ AdMob設定（必須）

### ステップ1: AdMob アカウント作成

**URL**: https://admob.google.com/

1. **AdMob アカウントを作成**
   - Google アカウントでサインイン
   - 利用規約に同意

### ステップ2: アプリを追加

1. **アプリ** → **アプリを追加**

2. **アプリの詳細**:
   ```
   プラットフォーム: Android
   アプリ名: Receipt Maker
   パッケージ名: com.receiptmaker.receipt
   ```

3. **アプリを追加** をクリック

4. **App ID** をコピー
   - 例: `ca-app-pub-1234567890123456~1234567890`

### ステップ3: 広告ユニット作成

#### バナー広告ユニット

1. **広告ユニット** → **広告ユニットを追加**

2. **フォーマット**: `バナー`

3. **広告ユニット名**: `Receipt Maker Banner`

4. **作成** → **広告ユニットID** をコピー
   - 例: `ca-app-pub-1234567890123456/9876543210`

#### インタースティシャル広告ユニット

1. **広告ユニットを追加**

2. **フォーマット**: `インタースティシャル`

3. **広告ユニット名**: `Receipt Maker Interstitial`

4. **作成** → **広告ユニットID** をコピー

### ステップ4: AndroidManifest.xml 更新

`android/app/src/main/AndroidManifest.xml` を編集:

```xml
<application>
    <!-- AdMob App ID -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-1234567890123456~1234567890"/>
    
    <!-- 既存の内容... -->
</application>
```

### ステップ5: ad_service.dart 更新

`lib/services/ad_service.dart` を編集:

```dart
// テスト用ID（現在）
static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

// ↓ 本番用IDに変更
static const String _bannerAdUnitId = 'ca-app-pub-1234567890123456/9876543210'; // ← あなたのバナーID
static const String _interstitialAdUnitId = 'ca-app-pub-1234567890123456/1234567890'; // ← あなたのインタースティシャルID
```

---

## 4️⃣ プライバシーポリシー作成（必須）

### 必須項目

Google Play Storeに申請するには、プライバシーポリシーが必須です。

#### 含めるべき内容

```markdown
# Receipt Maker プライバシーポリシー

最終更新日: 2026年2月12日

## 1. 収集する情報

Receipt Makerは以下の情報を収集します：

- **領収書データ**: 領収書番号、発行日、受取人名、金額、説明
- **発行者情報**: 会社名、住所、連絡先
- **デバイス情報**: 広告配信のための匿名識別子

## 2. 情報の使用目的

- 領収書の作成・管理機能の提供
- クラウド同期サービスの提供
- 広告の表示（無料ユーザー）
- アプリの改善

## 3. 第三者サービス

Receipt Makerは以下の第三者サービスを使用します：

- **Google Drive API**: 領収書PDFの保存
- **Microsoft OneDrive API**: 領収書PDFの保存
- **Google AdMob**: 広告の表示

各サービスのプライバシーポリシー：
- Google: https://policies.google.com/privacy
- Microsoft: https://privacy.microsoft.com/

## 4. データの保存

- **ローカルデータ**: デバイスのローカルストレージに保存
- **クラウドデータ**: ユーザーの同意のもと、選択したクラウドサービスに保存

## 5. データの削除

アプリをアンインストールすると、ローカルデータは削除されます。
クラウドデータは各クラウドサービスで管理できます。

## 6. お問い合わせ

プライバシーに関するご質問:
メール: your-email@example.com
```

### 公開方法

1. **オプション1**: GitHubにMarkdownで公開
   - リポジトリ作成 → `PRIVACY_POLICY.md` アップロード
   - GitHub Pagesで公開

2. **オプション2**: 無料ホスティングサービス
   - Google Sites
   - Notion（公開ページ）
   - Medium

3. **オプション3**: 自分のウェブサイト
   - `/privacy-policy.html`

⚠️ **重要**: URLをメモしておく（Play Console申請時に必要）

---

## 5️⃣ スクリーンショット作成

### 必要な仕様

**Phone（必須）**:
- サイズ: 1080 x 1920 px（縦向き）
- 枚数: 最低2枚、最大8枚
- フォーマット: PNG または JPG

### 推奨スクリーンショット

1. **ホーム画面** - 領収書一覧
2. **作成画面** - 新規領収書作成
3. **PDFプレビュー** - 生成されたPDF
4. **統計画面** - ダッシュボード
5. **設定画面** - 発行者プロファイル

### 作成方法

#### オプション1: ブラウザのデベロッパーツール

1. Chrome DevTools (F12)
2. デバイスツールバー (Ctrl+Shift+M)
3. デバイス選択: Pixel 5（1080 x 2340）
4. スクリーンショット: Ctrl+Shift+P → "Capture screenshot"

#### オプション2: Android実機/エミュレーター

```bash
# スクリーンショット撮影
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png ./screenshot.png
```

#### オプション3: デザインツール

- Figma（無料）
- Canva（無料）
- Photoshop

---

## 6️⃣ 最終ビルド＆テスト

### パッケージ名の最終確認

```bash
cd /home/user/flutter_app

# 1. pubspec.yaml
grep "name:" pubspec.yaml

# 2. AndroidManifest.xml
grep "package=" android/app/src/main/AndroidManifest.xml

# 3. build.gradle.kts
grep "applicationId" android/app/build.gradle.kts

# すべて "com.receiptmaker.receipt" であることを確認
```

### クリーンビルド

```bash
# キャッシュクリア
flutter clean

# 依存関係再取得
flutter pub get

# Android APKビルド
flutter build apk --split-per-abi --release
```

### ビルド成果物の確認

```bash
ls -lh build/app/outputs/flutter-apk/

# 出力例:
# app-arm64-v8a-release.apk    (27.6MB)  ← 最新端末用
# app-armeabi-v7a-release.apk  (25.3MB)  ← 古い端末用
# app-x86_64-release.apk       (28.8MB)  ← エミュレーター用
```

### テスト実機でのインストール

```bash
# USBデバッグ接続
adb devices

# インストール
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### 動作確認チェックリスト

- [ ] アプリ起動
- [ ] 領収書作成
- [ ] PDF生成・ダウンロード
- [ ] データ保存・読み込み
- [ ] 検索・フィルター
- [ ] Google Drive連携（設定済みの場合）
- [ ] AdMob広告表示
- [ ] サブスクリプション画面表示

---

## 7️⃣ Google Play Console 申請

### ステップ1: Play Console アカウント登録

**URL**: https://play.google.com/console/

- 登録料: $25（1回のみ）
- デベロッパーアカウント作成

### ステップ2: アプリ作成

1. **すべてのアプリ** → **アプリを作成**

2. **アプリの詳細**:
   ```
   アプリ名: Receipt Maker
   デフォルトの言語: 日本語
   アプリまたはゲーム: アプリ
   無料または有料: 無料
   ```

### ステップ3: ストアの設定

#### アプリのアクセス権

- **すべての機能がすべてのユーザーに制限なく利用可能**: はい

#### 広告

- **このアプリには広告が含まれますか？**: はい

#### コンテンツレーティング

- アンケート回答 → おそらく「全年齢対象」

#### ターゲット層とコンテンツ

- 主なターゲット年齢層: 18歳以上

#### データ セーフティ

- 収集するデータ: 個人情報なし、デバイス情報のみ
- 第三者と共有: AdMob（広告目的）

### ステップ4: メインのストア掲載情報

```
アプリ名: Receipt Maker

簡単な説明（80文字）:
シンプルな領収書作成アプリ。PDF生成、クラウド同期対応。

詳細な説明（4000文字）:
Receipt Makerは、ビジネス向けのシンプルで使いやすい領収書作成アプリです。

【主な機能】
✓ 領収書の作成・編集・管理
✓ プロフェッショナルなPDF生成
✓ Google Drive / OneDrive 同期
✓ 検索・フィルター機能
✓ CSV/JSON エクスポート
✓ 統計ダッシュボード

【こんな方におすすめ】
- フリーランス・個人事業主
- 小規模ビジネスオーナー
- 経理担当者

【プレミアム機能】
月額150円で広告非表示、無制限クラウド同期。

プライバシーポリシー: [あなたのURL]
```

#### グラフィック アセット

- **アプリアイコン**: 512 x 512 px（既に作成済み）
- **機能グラフィック**: 1024 x 500 px

### ステップ5: リリース作成

1. **本番** → **新しいリリースを作成**

2. **App Bundle** をアップロード
   ```bash
   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

3. **リリース名**: `1.0.0 (1)`

4. **リリースノート**:
   ```
   Receipt Maker初回リリース
   
   - 領収書作成・管理機能
   - PDF生成・共有
   - クラウド同期（Google Drive / OneDrive）
   - 統計ダッシュボード
   ```

5. **リリースの確認** → **本番環境にリリース**

---

## 🎯 次のステップ

申請後の流れ：

1. **審査**: 通常1-7日
2. **承認**: メール通知
3. **公開**: Play Storeで検索可能に
4. **モニタリング**: ダウンロード数・評価の確認

---

## 📞 トラブルシューティング

### よくある問題

**Q1: SHA-1が取得できない**
```bash
# Javaのインストール確認
java -version

# keytoolのパス確認
which keytool
```

**Q2: google-services.jsonのパッケージ名が違う**
- Firebase Consoleで新しいアプリを追加
- 正しいパッケージ名で再作成

**Q3: AdMob広告が表示されない**
- テストIDから本番IDへの変更を確認
- AdMob審査完了まで待つ（数時間〜数日）

**Q4: APKビルドが失敗する**
```bash
# 完全なクリーンビルド
flutter clean
rm -rf android/build android/app/build android/.gradle
flutter pub get
flutter build apk --release
```

---

## ✅ チェックリスト

申請前の最終確認：

- [ ] Google Drive OAuth設定完了
- [ ] OneDrive OAuth設定完了
- [ ] AdMob広告ユニット作成・ID更新完了
- [ ] google-services.json配置完了
- [ ] プライバシーポリシーURL取得完了
- [ ] スクリーンショット2枚以上作成完了
- [ ] APKビルド＆実機テスト完了
- [ ] Play Console登録料($25)支払い完了

---

**🎊 すべて完了したら、Play Storeリリース準備完了です！**

**頑張ってください！ 🚀**
