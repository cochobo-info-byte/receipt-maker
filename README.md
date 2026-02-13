# 📱 Receipt Maker

ミニマリストデザインの領収書作成・管理アプリ

## ✨ 主要機能

### 📄 領収書管理
- 領収書の作成・編集・削除
- PDF生成・プレビュー・共有
- リアルタイム検索・フィルター
- CSV/JSONエクスポート

### ☁️ クラウド連携
- Google Drive自動同期
- OneDrive自動同期
- オフライン対応

### 💰 ビジネス向け機能
- 発行者プロファイル管理
- 統計ダッシュボード
- 月次レポート
- 複数支払方法対応

### 💎 プレミアム機能（月額¥150）
- 広告非表示
- 無制限クラウド同期
- プレミアムテーマ

## 🌐 プレビュー

**Webアプリ**: https://5060-islxh7hjv70qrbal7wo9c-18e660f9.sandbox.novita.ai

## 📱 Android APKダウンロード

| ファイル | サイズ | 対象 |
|---------|-------|------|
| app-arm64-v8a-release.apk | 27.6MB | 最新端末（推奨） |
| app-armeabi-v7a-release.apk | 25.3MB | 古い端末 |

**APKパス**: `/home/user/flutter_app/build/app/outputs/flutter-apk/`

## 🚀 クイックスタート

### 1. 発行者プロファイル作成
Settings → Issuer Profiles → + → 会社情報入力 → Save → Set Default

### 2. 領収書作成
Home → + → 情報入力 → Preview → Save

### 3. クラウド同期（オプション）
Cloud → Google Drive / OneDrive に接続 → Sync

## 🛠️ 技術スタック

- **Flutter** 3.35.4
- **Dart** 3.9.2
- **Material Design 3**
- **SharedPreferences** - ローカルストレージ
- **PDF & Printing** - PDF生成
- **Google APIs** - Drive連携
- **AAD OAuth** - OneDrive連携
- **AdMob** - 広告統合

## 📊 プロジェクト構成

```
lib/
├── main.dart                  # エントリーポイント
├── screens/                   # UI画面
│   ├── home_screen.dart
│   ├── receipt_form_screen.dart
│   ├── cloud_screen.dart
│   └── settings_screen.dart
├── services/                  # ビジネスロジック
│   ├── pdf_service.dart
│   ├── cloud_service.dart
│   ├── ad_service.dart
│   └── subscription_service.dart
└── database/                  # データモデル
    └── database.dart
```

## 🔧 開発コマンド

```bash
# 依存関係インストール
flutter pub get

# Webビルド
flutter build web --release

# Android APKビルド
flutter build apk --split-per-abi --release

# コード解析
flutter analyze
```

## 📝 本番環境設定

詳細は [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) を参照

### Google Drive連携
1. Google Cloud Console でプロジェクト作成
2. OAuth 2.0 クライアントID設定
3. `google-services.json` を `android/app/` に配置

### OneDrive連携
1. Azure Portal でアプリ登録
2. クライアントID取得
3. `lib/services/onedrive_service.dart` を更新

### AdMob広告
1. AdMob Console でアプリ登録
2. 広告ユニットID取得
3. `AndroidManifest.xml` と `ad_service.dart` を更新

## 🎯 完成度

| 機能 | 状態 |
|------|------|
| コア機能 | ✅ 100% |
| クラウド連携 | ✅ 100% |
| 広告統合 | ✅ 100% |
| サブスクリプション | ✅ 100% |
| プライバシー対応 | ⚠️ 簡易版 |
| Web対応 | ✅ 100% |
| Android対応 | ✅ 100% |

## 📄 ライセンス

© 2026 Receipt Maker

---

**バージョン**: 1.0.0  
**ビルド番号**: 1  
**パッケージ名**: com.receiptmaker.receipt
