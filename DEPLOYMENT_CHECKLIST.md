# 📋 Receipt Maker - デプロイメントチェックリスト

## ✅ 完了済み

### 開発フェーズ
- [x] Flutter プロジェクト作成
- [x] アプリアイコン生成
- [x] データベース設計
- [x] UI/UX実装（ミニマリストデザイン）
- [x] PDF生成機能
- [x] クラウド連携（Google Drive + OneDrive）
- [x] AdMob広告統合
- [x] サブスクリプション機能
- [x] プライバシー設定（UMP SDK簡易版）
- [x] Webビルド
- [x] Android APKビルド
- [x] ドキュメント作成

---

## 🔄 本番環境デプロイ準備

### Google Drive連携設定

#### 1. Google Cloud Console
- [ ] プロジェクト作成: https://console.cloud.google.com/
- [ ] OAuth同意画面設定
  - [ ] User Type: External
  - [ ] App name: Receipt Maker
  - [ ] Scopes: `https://www.googleapis.com/auth/drive.file`
- [ ] 認証情報作成
  - [ ] OAuth 2.0 クライアントID（Android）
  - [ ] SHA-1証明書フィンガープリント追加
  - [ ] OAuth 2.0 クライアントID（Web）
- [ ] `google-services.json` をダウンロード
- [ ] `android/app/google-services.json` に配置

#### 2. SHA-1フィンガープリント取得
```bash
# リリースキーストアから取得
keytool -list -v -keystore android/release-key.jks -alias release -storepass android
```

---

### OneDrive連携設定

#### 1. Azure Portal
- [ ] Azure Portal にアクセス: https://portal.azure.com/
- [ ] Azure Active Directory → App registrations
- [ ] 新しいアプリ登録
  - [ ] Name: Receipt Maker
  - [ ] Supported account types: Accounts in any organizational directory and personal Microsoft accounts
- [ ] API permissions → Add a permission
  - [ ] Microsoft Graph: `Files.ReadWrite`
  - [ ] `offline_access` も追加
- [ ] Authentication → Add platform → Mobile and desktop applications
  - [ ] Redirect URI: `msauth://com.receiptmaker.receipt/[SIGNATURE_HASH]`
- [ ] Client ID をコピー

#### 2. コード更新
```dart
// lib/services/onedrive_service.dart
static const String _clientId = 'YOUR_AZURE_CLIENT_ID';
static const String _redirectUri = 'msauth://com.receiptmaker.receipt/YOUR_SIGNATURE_HASH';
```

---

### AdMob設定

#### 1. AdMob Console
- [ ] AdMob アカウント作成: https://admob.google.com/
- [ ] アプリ追加
  - [ ] Platform: Android
  - [ ] Package name: com.receiptmaker.receipt
- [ ] 広告ユニット作成
  - [ ] バナー広告
  - [ ] インタースティシャル広告
- [ ] App ID と Ad Unit ID をコピー

#### 2. AndroidManifest.xml 更新
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_ADMOB_APP_ID"/>
```

#### 3. コード更新
```dart
// lib/services/ad_service.dart
static const String _bannerAdUnitId = 'ca-app-pub-YOUR_BANNER_AD_UNIT_ID';
static const String _interstitialAdUnitId = 'ca-app-pub-YOUR_INTERSTITIAL_AD_UNIT_ID';
```

---

### UMP SDK（プライバシー同意）完全実装

#### 1. AdMob プライバシー設定
- [ ] AdMob Console → Privacy & messaging
- [ ] GDPR メッセージ作成
  - [ ] EU User Consent
  - [ ] Message type: Consent
- [ ] CCPA メッセージ作成
  - [ ] California User Consent
  - [ ] Message type: Do Not Sell

#### 2. 依存関係更新（オプション）
```yaml
# pubspec.yaml（将来のアップグレード用）
dependencies:
  google_mobile_ads: ^6.0.0  # UMP SDK完全サポート
```

---

### Google Play Billing（サブスクリプション）

#### 1. Google Play Console
- [ ] アプリ作成: https://play.google.com/console/
- [ ] Monetize → Subscriptions
- [ ] サブスクリプション作成
  - [ ] Product ID: `premium_monthly`
  - [ ] Price: ¥150/月
  - [ ] Billing period: Monthly
- [ ] Base plan 設定

#### 2. テスト用ライセンステスター追加
- [ ] Settings → License Testing
- [ ] テストアカウント追加

---

### Play Store申請準備

#### 1. ストアリスティング
- [ ] アプリ名: Receipt Maker
- [ ] 簡単な説明（80文字以内）
- [ ] 詳細な説明（4000文字以内）
- [ ] スクリーンショット（最低2枚）
  - [ ] Phone: 1080 x 1920 px（縦向き）
  - [ ] Tablet（オプション）: 1536 x 2048 px
- [ ] 512x512 pxのアイコン
- [ ] 1024x500 pxの機能グラフィック

#### 2. コンテンツレーティング
- [ ] アンケート回答
- [ ] 年齢制限なし（予想）

#### 3. プライバシーポリシー
- [ ] プライバシーポリシーURL必須
- [ ] データ収集の開示
  - [ ] 広告データ（AdMob）
  - [ ] クラウドストレージデータ
  - [ ] 位置情報: なし
  - [ ] 連絡先: なし

#### 4. アプリカテゴリ
- [ ] Category: Business / Productivity
- [ ] Tags: 領収書、PDF、請求書、ビジネス

---

### APKアップロード

#### 1. リリースバンドル作成
```bash
cd /home/user/flutter_app

# App Bundle（推奨）
flutter build appbundle --release

# または Split APKs
flutter build apk --split-per-abi --release
```

#### 2. Play Console アップロード
- [ ] Production → Create new release
- [ ] APK/AAB をアップロード
- [ ] リリースノート作成
- [ ] Review → Start rollout to Production

---

## 🔍 最終チェック項目

### セキュリティ
- [ ] API キーがハードコードされていないか確認
- [ ] リリースキーストアを安全に保管
- [ ] ProGuard/R8有効化（デフォルトで有効）

### パフォーマンス
- [ ] アプリサイズ確認（28MB未満推奨）
- [ ] 起動時間テスト（3秒以内）
- [ ] メモリ使用量確認（100MB未満推奨）

### 機能テスト
- [ ] 領収書作成・編集・削除
- [ ] PDF生成・プレビュー
- [ ] 検索・フィルター
- [ ] クラウド同期（オフライン→オンライン）
- [ ] 広告表示（バナー・インタースティシャル）
- [ ] サブスクリプション購読・解除
- [ ] データエクスポート（CSV/JSON）

### デバイステスト
- [ ] Android 7.0（API 24）以降
- [ ] 様々な画面サイズ（4.5"〜6.5"）
- [ ] タブレット（オプション）
- [ ] 回転テスト（縦向き・横向き）

---

## 📱 配布方法

### オプション1: Google Play Store（推奨）
- **メリット**: 自動更新、信頼性、課金機能
- **デメリット**: 審査期間（1-7日）、手数料15%

### オプション2: 直接配布（APK）
- **メリット**: 即座に配布可能、手数料なし
- **デメリット**: 「提供元不明のアプリ」警告、手動更新

### オプション3: Firebase App Distribution
- **メリット**: ベータテスト向け、簡単配布
- **デメリット**: テスター限定、一般公開不可

---

## 🎯 今後のアップデート計画

### バージョン 1.1.0（3ヶ月以内）
- [ ] iOS対応
- [ ] 多言語対応（英語）
- [ ] テーマカスタマイズ

### バージョン 1.2.0（6ヶ月以内）
- [ ] OCR機能（領収書画像からデータ抽出）
- [ ] チーム共有機能
- [ ] 繰り返し領収書テンプレート

### バージョン 2.0.0（1年以内）
- [ ] AI予測機能
- [ ] 会計ソフト連携
- [ ] マルチデバイス同期強化

---

## 📞 サポート連絡先

- **開発者**: Receipt Maker Team
- **メール**: （設定してください）
- **プライバシーポリシー**: （URLを設定してください）
- **利用規約**: （URLを設定してください）

---

**最終更新**: 2026年2月12日  
**チェックリスト完成度**: 開発完了 → 本番設定待ち
