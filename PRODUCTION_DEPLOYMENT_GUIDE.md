# Receipt Maker - 本番環境デプロイ完全ガイド

## 📋 目次
1. [概要](#概要)
2. [プライバシーポリシー公開](#1-プライバシーポリシー公開)
3. [Google Cloud Console設定](#2-google-cloud-console設定)
4. [Azure Portal設定](#3-azure-portal設定)
5. [AdMob設定](#4-admob設定)
6. [Google Play Console準備](#5-google-play-console準備)
7. [最終APKビルド](#6-最終apkビルド)

---

## 概要

このガイドは、Receipt Makerアプリを本番環境にデプロイするための完全な手順書です。

**推奨作業時間**: 8-12時間（設定 + 審査待ち）

**必要なもの**:
- Google アカウント
- Microsoft アカウント（OneDrive連携用）
- Google Play Developerアカウント（$25、初回のみ）
- AdMobアカウント

---

## 1. プライバシーポリシー公開

### ✅ 完了済み
プライバシーポリシーは既に作成されています：  
`/home/user/flutter_app/PRIVACY_POLICY.md`

### 🔧 公開手順

#### オプション1: GitHub Pages（推奨）

1. **GitHubリポジトリ作成**
   ```bash
   # ローカルでGit初期化
   cd /home/user/flutter_app
   git init
   git add PRIVACY_POLICY.md
   git commit -m "Add privacy policy"
   
   # GitHubにプッシュ
   git remote add origin https://github.com/YOUR_USERNAME/receipt-maker.git
   git push -u origin main
   ```

2. **GitHub Pagesを有効化**
   - リポジトリの Settings → Pages
   - Source: Deploy from a branch
   - Branch: main / (root)
   - Save

3. **公開URL取得**
   - 数分後に `https://YOUR_USERNAME.github.io/receipt-maker/PRIVACY_POLICY` でアクセス可能

#### オプション2: Netlify/Vercel

1. **Netlifyにアクセス**: https://app.netlify.com/
2. **Sites → Add new site → Deploy manually**
3. **PRIVACY_POLICY.mdをドラッグ&ドロップ**
4. **公開URLをコピー**

#### オプション3: Google Sites

1. **Google Sitesにアクセス**: https://sites.google.com/
2. **新しいサイトを作成**
3. **PRIVACY_POLICY.mdの内容をコピペ**
4. **公開してURLを取得**

### 📝 取得したURLをメモ
```
プライバシーポリシーURL: _______________________________
```
このURLは次のステップで使用します。

---

## 2. Google Cloud Console設定

### 所要時間: 2-3時間

### Step 2.1: プロジェクト作成

1. **Google Cloud Consoleにアクセス**  
   https://console.cloud.google.com/

2. **新規プロジェクト作成**
   - 左上の「プロジェクトを選択」をクリック
   - 「新しいプロジェクト」をクリック
   - プロジェクト名: `receipt-maker-production`
   - 「作成」をクリック

3. **プロジェクトIDをメモ**
   ```
   プロジェクトID: _______________________________
   ```

### Step 2.2: Google Drive API有効化

1. **APIライブラリに移動**
   - サイドメニュー → API とサービス → ライブラリ

2. **Google Drive APIを検索**
   - 検索ボックスに「Google Drive API」と入力
   - 「Google Drive API」をクリック
   - 「有効にする」をクリック

### Step 2.3: OAuth同意画面の設定

1. **OAuth同意画面に移動**
   - サイドメニュー → API とサービス → OAuth 同意画面

2. **User Typeを選択**
   - 「外部」を選択
   - 「作成」をクリック

3. **アプリ情報を入力**
   ```
   アプリ名: Receipt Maker
   ユーザーサポートメール: あなたのメールアドレス
   アプリのロゴ: （オプション）
   アプリのドメイン:
     - アプリのホームページ: https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai
     - プライバシーポリシーのリンク: [Step 1で取得したURL]
     - 利用規約のリンク: （オプション）
   承認済みドメイン:
     - sandbox.novita.ai
   デベロッパーの連絡先情報: あなたのメールアドレス
   ```

4. **スコープを設定**
   - 「スコープを追加または削除」をクリック
   - 以下のスコープを追加:
     - `https://www.googleapis.com/auth/drive.file`
     - `https://www.googleapis.com/auth/drive.appdata`
   - 「更新」をクリック

5. **テストユーザーを追加（オプション）**
   - 「+ ADD USERS」をクリック
   - あなたのGmailアドレスを追加

6. **保存して続行**

### Step 2.4: OAuth 2.0 クライアントID作成（Android）

1. **認証情報ページに移動**
   - サイドメニュー → API とサービス → 認証情報

2. **認証情報を作成**
   - 「+ 認証情報を作成」をクリック
   - 「OAuth 2.0 クライアント ID」を選択

3. **アプリケーションの種類を選択**
   - アプリケーションの種類: **Android**

4. **Android設定**
   ```
   名前: Receipt Maker (Android)
   パッケージ名: com.receiptmaker.receipt
   ```

5. **SHA-1証明書フィンガープリントを取得**
   
   サンドボックスで以下のコマンドを実行:
   ```bash
   cd /home/user/flutter_app
   keytool -list -v -keystore android/release-key.jks -alias key
   ```
   
   パスワード入力: `12345678`
   
   出力例:
   ```
   証明書のフィンガープリント:
   SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
   ```

6. **SHA-1フィンガープリントを入力**
   - 上記の `SHA1:` の後の値をコピーして貼り付け
   - 「作成」をクリック

7. **クライアントIDをメモ**
   ```
   Android OAuth 2.0 クライアントID: _______________________________
   ```

### Step 2.5: OAuth 2.0 クライアントID作成（Web）

1. **認証情報を作成**
   - 「+ 認証情報を作成」をクリック
   - 「OAuth 2.0 クライアント ID」を選択

2. **アプリケーションの種類を選択**
   - アプリケーションの種類: **ウェブアプリケーション**

3. **Web設定**
   ```
   名前: Receipt Maker (Web)
   承認済みのJavaScript生成元:
     - https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai
   承認済みのリダイレクトURI:
     - https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai
     - https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai/callback
   ```

4. **作成してクライアントIDをメモ**
   ```
   Web OAuth 2.0 クライアントID: _______________________________
   Web OAuth 2.0 クライアントシークレット: _______________________________
   ```

### Step 2.6: google-services.json取得（Android用）

1. **Firebase Consoleにアクセス**  
   https://console.firebase.google.com/

2. **プロジェクトを追加**
   - 「プロジェクトを追加」をクリック
   - プロジェクト名: `receipt-maker-production`
   - 「続行」をクリック

3. **Google Analyticsを設定（オプション）**
   - 有効/無効を選択
   - 「プロジェクトを作成」をクリック

4. **Androidアプリを追加**
   - プロジェクト概要 → 「アプリを追加」
   - Androidアイコンをクリック
   - Androidパッケージ名: `com.receiptmaker.receipt`
   - アプリのニックネーム: `Receipt Maker`
   - 「アプリを登録」をクリック

5. **google-services.jsonをダウンロード**
   - 「google-services.jsonをダウンロード」をクリック
   - ファイルをダウンロード

6. **ファイルを配置**
   ```bash
   # ダウンロードしたgoogle-services.jsonを以下の場所に配置
   /home/user/flutter_app/android/app/google-services.json
   ```

### Step 2.7: firebase_options.dart生成

Firebase設定をFlutterアプリに統合するため、`firebase_options.dart`を生成します。

1. **FlutterFire CLIをインストール**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Firebase設定を生成**
   ```bash
   cd /home/user/flutter_app
   flutterfire configure --project=receipt-maker-production
   ```

3. **プラットフォームを選択**
   - Android と Web を選択
   - Enter キーで確認

4. **生成されたファイルを確認**
   ```bash
   ls -la lib/firebase_options.dart
   ```

### ✅ Google Cloud Console設定完了チェックリスト

- [ ] Google Drive API有効化
- [ ] OAuth同意画面設定
- [ ] Android OAuth 2.0 クライアントID作成
- [ ] Web OAuth 2.0 クライアントID作成
- [ ] google-services.json取得＆配置
- [ ] firebase_options.dart生成

---

## 3. Azure Portal設定（OneDrive連携）

### 所要時間: 2-3時間

### Step 3.1: Azure Portal アプリ登録

1. **Azure Portalにアクセス**  
   https://portal.azure.com/

2. **Azure Active Directoryに移動**
   - サイドメニュー → Azure Active Directory

3. **アプリの登録**
   - 左メニュー → アプリの登録
   - 「+ 新規登録」をクリック

4. **アプリ情報を入力**
   ```
   名前: Receipt Maker OneDrive
   サポートされているアカウントの種類:
     - 任意の組織ディレクトリ内のアカウント (任意の Azure AD ディレクトリ - マルチテナント) と
       個人の Microsoft アカウント (Skype、Xbox など)
   リダイレクト URI: （後で追加）
   ```

5. **登録をクリック**

6. **アプリケーション（クライアント）IDをメモ**
   ```
   Azure クライアントID: _______________________________
   ```

### Step 3.2: リダイレクトURI設定

1. **認証ページに移動**
   - 左メニュー → 認証

2. **プラットフォームを追加**
   - 「+ プラットフォームを追加」をクリック
   - 「モバイルアプリケーションとデスクトップアプリケーション」を選択

3. **カスタムリダイレクトURIを追加**
   ```
   msauth://com.receiptmaker.receipt/xxxxxx
   ```
   
   ※ `xxxxxx` 部分は後ほど生成します

4. **Webリダイレクトも追加**
   - 「+ プラットフォームを追加」をクリック
   - 「Web」を選択
   - リダイレクトURI:
     ```
     https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai/callback
     ```

5. **保存**

### Step 3.3: Microsoft Graph権限追加

1. **APIのアクセス許可ページに移動**
   - 左メニュー → APIのアクセス許可

2. **アクセス許可を追加**
   - 「+ アクセス許可の追加」をクリック
   - 「Microsoft Graph」を選択
   - 「委任されたアクセス許可」をクリック

3. **以下の権限を追加**
   - `Files.ReadWrite` - ユーザーファイルの読み取り/書き込み
   - `Files.ReadWrite.All` - すべてのファイルへのフルアクセス
   - `offline_access` - オフラインアクセス

4. **権限を追加をクリック**

5. **管理者の同意を付与（オプション）**
   - 「[テナント名] に管理者の同意を与えます」をクリック
   - 「はい」をクリック

### Step 3.4: onedrive_service.dart更新

サンドボックスで以下のコマンドを実行:

```bash
cd /home/user/flutter_app
nano lib/services/onedrive_service.dart
```

以下の行を更新:
```dart
// 旧
static const String _clientId = 'YOUR_AZURE_CLIENT_ID';

// 新（Step 3.1で取得したクライアントIDに置換）
static const String _clientId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
```

保存: `Ctrl + X` → `Y` → `Enter`

### ✅ Azure Portal設定完了チェックリスト

- [ ] Azure ADアプリ登録
- [ ] リダイレクトURI設定
- [ ] Microsoft Graph権限追加
- [ ] onedrive_service.dart更新

---

## 4. AdMob設定

### 所要時間: 1-2時間

### Step 4.1: AdMobアカウント作成

1. **AdMobにアクセス**  
   https://apps.admob.com/

2. **Googleアカウントでログイン**

3. **利用規約に同意**

### Step 4.2: アプリを追加

1. **アプリメニューに移動**
   - サイドメニュー → アプリ

2. **アプリを追加**
   - 「アプリを追加」ボタンをクリック

3. **アプリの詳細を入力**
   ```
   アプリはアプリストアに掲載されていますか?: いいえ
   アプリ名: Receipt Maker
   プラットフォーム: Android
   ```

4. **アプリを追加をクリック**

5. **App IDをメモ**
   ```
   AdMob App ID: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
   ```

### Step 4.3: 広告ユニット作成

#### バナー広告

1. **広告ユニットに移動**
   - アプリページ → 広告ユニット → 広告ユニットを追加

2. **広告フォーマットを選択**
   - 「バナー」をクリック

3. **広告ユニット設定**
   ```
   広告ユニット名: Receipt Maker Banner
   ```

4. **広告ユニットを作成**

5. **広告ユニットIDをメモ**
   ```
   バナー広告ユニットID: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
   ```

#### インタースティシャル広告

1. **広告ユニットを追加**
   - 広告ユニット → 広告ユニットを追加

2. **広告フォーマットを選択**
   - 「インタースティシャル」をクリック

3. **広告ユニット設定**
   ```
   広告ユニット名: Receipt Maker Interstitial
   ```

4. **広告ユニットを作成**

5. **広告ユニットIDをメモ**
   ```
   インタースティシャル広告ユニットID: ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW
   ```

### Step 4.4: コード更新

#### ad_service.dartを更新

```bash
cd /home/user/flutter_app
nano lib/services/ad_service.dart
```

以下の行を更新:
```dart
// テストIDを本番IDに置換
static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ'; // Step 4.3で取得したバナーID
static const String _interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/WWWWWWWWWW'; // Step 4.3で取得したインタースティシャルID
```

保存: `Ctrl + X` → `Y` → `Enter`

#### AndroidManifest.xmlを更新

```bash
nano android/app/src/main/AndroidManifest.xml
```

以下の行を更新:
```xml
<!-- 旧 -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- テストID -->

<!-- 新 -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/> <!-- Step 4.2で取得したApp ID -->
```

保存: `Ctrl + X` → `Y` → `Enter`

### ✅ AdMob設定完了チェックリスト

- [ ] AdMobアカウント作成
- [ ] アプリ登録
- [ ] バナー広告ユニット作成
- [ ] インタースティシャル広告ユニット作成
- [ ] ad_service.dart更新
- [ ] AndroidManifest.xml更新

---

## 5. Google Play Console準備

### 所要時間: 4-6時間

### Step 5.1: Google Play Developerアカウント登録

1. **Google Play Consoleにアクセス**  
   https://play.google.com/console/

2. **アカウント作成**
   - Googleアカウントでログイン
   - 利用規約に同意
   - **登録料 $25 USD を支払い**（初回のみ）

3. **デベロッパーアカウント情報入力**
   ```
   アカウントタイプ: 個人 or 組織
   デベロッパー名: あなたの名前 or 組織名
   メールアドレス: 連絡先メールアドレス
   ウェブサイト: （オプション）
   ```

### Step 5.2: アプリを作成

1. **すべてのアプリ → アプリを作成**

2. **アプリの詳細を入力**
   ```
   アプリ名: Receipt Maker
   デフォルトの言語: 日本語（日本）
   アプリまたはゲーム: アプリ
   無料または有料: 無料
   ```

3. **宣言**
   - [ ] Google Playのデベロッパープログラムポリシーを遵守します
   - [ ] 米国の輸出法に準拠していることを確認します

4. **アプリを作成**

### Step 5.3: ストアリスティング

1. **ストアリスティングに移動**
   - 左メニュー → ストアの設定 → メインのストア掲載情報

2. **アプリの詳細を入力**

#### アプリ名とアイコン
```
アプリ名: Receipt Maker
簡単な説明（80文字以内）:
  領収書を簡単作成・管理。PDF生成、クラウド同期対応。
```

#### 詳細な説明（4000文字以内）
```
Receipt Makerは、領収書の作成・管理を簡単にするモバイルアプリです。

【主な機能】
✅ 領収書の作成・編集・削除
✅ PDF生成とプレビュー
✅ クラウド同期（Google Drive / OneDrive）
✅ 検索・フィルター機能
✅ CSV/JSONエクスポート
✅ 統計ダッシュボード
✅ 発行者プロファイル管理

【こんな方におすすめ】
• フリーランス・個人事業主
• 小規模ビジネスオーナー
• 経理担当者
• 領収書管理を効率化したい方

【プレミアム機能】
月額150円で以下の機能が利用可能：
• 広告非表示
• 無制限クラウド同期
• プレミアムテーマ

【セキュリティ】
• データはローカルに保存され、プライバシーを保護
• クラウド同期は暗号化通信を使用

【サポート】
ご質問やフィードバックは、アプリ内の「ヘルプ」からお気軽にどうぞ。
```

#### アプリアイコン
- **512 x 512 px** (32-bit PNG, アルファチャンネル付き)
- アプリアイコンは既に生成済み: 
  - `/home/user/assets/icons/app_icon.png`

#### スクリーンショット（最低2枚、最大8枚）

**✅ 既に生成済み！**

以下のスクリーンショットをダウンロードしてアップロード:

1. **ホーム画面（領収書リスト）**
   - URL: https://www.genspark.ai/api/files/s/joUQJ0pQ?cache_control=3600
   - サイズ: 768x1365 (9:16)

2. **領収書作成画面**
   - URL: https://www.genspark.ai/api/files/s/USWrED0s?cache_control=3600
   - サイズ: 768x1365 (9:16)

3. **クラウド同期画面**
   - URL: https://www.genspark.ai/api/files/s/lwJ98rHt?cache_control=3600
   - サイズ: 768x1365 (9:16)

**スクリーンショット要件**:
- 形式: JPEG または 24-bit PNG（アルファチャンネルなし）
- 最小サイズ: 320px
- 最大サイズ: 3840px
- 推奨アスペクト比: 16:9 または 9:16

#### アプリカテゴリ
```
カテゴリ: ビジネス
タグ: 領収書, PDF, ビジネス, 会計
```

#### 連絡先情報
```
メールアドレス: あなたのメールアドレス
電話番号: （オプション）
ウェブサイト: （オプション）
```

#### プライバシーポリシー
```
プライバシーポリシーURL: [Step 1で取得したURL]
```

3. **保存**

### Step 5.4: コンテンツレーティング

1. **コンテンツレーティングに移動**
   - 左メニュー → ストアの設定 → アプリのコンテンツ

2. **アンケートを開始**
   - 「アンケートを開始」をクリック

3. **メールアドレスを入力**

4. **カテゴリを選択**
   - カテゴリ: ユーティリティ、生産性、コミュニケーション、その他

5. **質問に回答**
   - すべての質問に「いいえ」と回答（暴力、性的コンテンツなし）

6. **レーティングを取得**

### Step 5.5: 対象ユーザーとコンテンツ

1. **対象ユーザーに移動**
   - 左メニュー → ストアの設定 → 対象ユーザーとコンテンツ

2. **対象年齢層**
   - 18歳以上を選択

3. **広告の有無**
   - 「はい、このアプリには広告が含まれます」を選択（AdMob使用のため）

4. **保存**

### Step 5.6: データの安全性

1. **データの安全性に移動**
   - 左メニュー → ストアの設定 → データの安全性

2. **データ収集に関する質問に回答**
   ```
   ユーザーデータを収集または共有しますか?
   - 「はい」を選択
   
   収集するデータの種類:
   - 個人情報: メールアドレス（Cloud連携時のみ）
   - 財務情報: なし
   - 位置情報: なし
   - ファイルとドキュメント: 領収書データ（ローカル保存）
   
   データの使用目的:
   - アプリ機能
   - 分析
   
   データの保護:
   - 転送中のデータは暗号化されます
   - ユーザーはデータの削除をリクエストできます
   ```

3. **保存**

### ✅ Google Play Console準備完了チェックリスト

- [ ] Google Play Developerアカウント登録（$25支払い）
- [ ] アプリ作成
- [ ] ストアリスティング入力
- [ ] スクリーンショット3枚アップロード
- [ ] アプリアイコンアップロード
- [ ] コンテンツレーティング取得
- [ ] 対象ユーザー設定
- [ ] データの安全性設定

---

## 6. 最終APKビルド

### 所要時間: 1時間

すべての設定が完了したら、最終的なAPKをビルドします。

### Step 6.1: 設定確認

以下の設定が完了していることを確認:

```bash
cd /home/user/flutter_app

# 1. google-services.json配置確認
ls -la android/app/google-services.json

# 2. firebase_options.dart存在確認
ls -la lib/firebase_options.dart

# 3. ad_service.dart更新確認
grep "ca-app-pub-" lib/services/ad_service.dart

# 4. onedrive_service.dart更新確認
grep "_clientId" lib/services/onedrive_service.dart

# 5. AndroidManifest.xml更新確認
grep "APPLICATION_ID" android/app/src/main/AndroidManifest.xml
```

### Step 6.2: 依存関係の更新

```bash
cd /home/user/flutter_app
flutter pub get
```

### Step 6.3: コード分析

```bash
flutter analyze
```

エラーがないことを確認。

### Step 6.4: APKビルド実行

```bash
cd /home/user/flutter_app
flutter build apk --split-per-abi --release
```

**ビルド時間**: 約2分

### Step 6.5: ビルド成果物の確認

```bash
ls -lh build/app/outputs/flutter-apk/
```

**期待される出力**:
```
app-arm64-v8a-release.apk      (~27 MB) - 最新Android端末向け（推奨）
app-armeabi-v7a-release.apk    (~25 MB) - 旧Android端末向け
app-x86_64-release.apk         (~28 MB) - エミュレータ向け
```

### Step 6.6: APKテスト

#### エミュレータでテスト

```bash
# Android Studioのエミュレータを起動
# または
flutter run --release
```

#### 実機でテスト

1. **APKを実機に転送**
   ```bash
   adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
   ```

2. **アプリを起動してテスト**
   - 領収書作成
   - PDF生成
   - Cloud連携（Google Drive / OneDrive）
   - AdMob広告表示
   - サブスクリプション機能

### Step 6.7: Google Play Consoleにアップロード

1. **製品版に移動**
   - 左メニュー → リリース → 製品版

2. **新しいリリースを作成**
   - 「新しいリリースを作成」をクリック

3. **APKをアップロード**
   - 「Android App Bundle と APK」セクション
   - 「アップロード」をクリック
   - `app-arm64-v8a-release.apk` を選択（推奨）
   - または全3種類をアップロード

4. **リリースノートを入力**
   ```
   日本語:
   初回リリース
   
   - 領収書の作成・編集・削除
   - PDF生成とプレビュー
   - クラウド同期（Google Drive / OneDrive）
   - 検索・フィルター機能
   - 統計ダッシュボード
   - プレミアム機能（月額150円）
   ```

5. **審査用メモ（オプション）**
   ```
   テスト手順:
   1. アプリを起動
   2. Home画面で「+」ボタンをタップ
   3. 領収書情報を入力
   4. 「Preview」ボタンでPDFプレビュー
   5. 「Save」ボタンで保存
   
   プレミアム機能テスト:
   - Settings → Subscription → Upgrade to Premium
   
   Cloud連携テスト:
   - Cloud → Google Drive → Connect
   ```

6. **リリースを確認**

7. **公開範囲を選択**
   - **クローズドテスト**: 限定ユーザーでテスト（推奨）
   - **製品版**: 全ユーザーに公開

8. **審査に提出**

### ✅ 最終APKビルド完了チェックリスト

- [ ] 設定確認
- [ ] 依存関係更新
- [ ] コード分析
- [ ] APKビルド成功
- [ ] エミュレータ/実機テスト
- [ ] Google Play Consoleアップロード
- [ ] 審査提出

---

## 🎊 完了おめでとうございます！

すべての設定とデプロイが完了しました。

### 📱 次のステップ

1. **審査待ち**: 通常1-7日
2. **承認後**: Google Playストアで公開
3. **ユーザーフィードバック**: レビューと評価を収集
4. **継続的改善**: 新機能追加とバグ修正

---

## 📞 サポート

質問や問題がある場合は、以下を参照してください:

- **Flutter公式ドキュメント**: https://docs.flutter.dev/
- **Firebase公式ドキュメント**: https://firebase.google.com/docs
- **AdMobヘルプセンター**: https://support.google.com/admob
- **Google Play Consoleヘルプ**: https://support.google.com/googleplay/android-developer

---

**作成日**: 2026-02-12  
**バージョン**: 1.0.0  
**プロジェクト**: Receipt Maker
