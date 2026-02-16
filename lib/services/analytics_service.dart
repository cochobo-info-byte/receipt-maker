import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;

/// Firebase Analytics統合サービス
/// ユーザー行動を追跡して、アプリ改善のための洞察を提供
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;
  static bool _isInitialized = false;

  /// Analytics初期化（モバイルのみ）
  static Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return; // Web版では無効化
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      _isInitialized = true;
      debugPrint('✅ Firebase Analytics initialized');
    } catch (e) {
      debugPrint('⚠️ Firebase Analytics initialization failed: $e');
    }
  }

  /// Analytics Observerを取得（NavigatorObserver用）
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// カスタムイベントをログ
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('📊 Analytics: $name ${parameters ?? ""}');
      }
    } catch (e) {
      debugPrint('⚠️ Analytics log error: $e');
    }
  }

  // ==================== アプリライフサイクル ====================

  /// アプリ起動
  static Future<void> logAppOpen() async {
    await logEvent(name: 'app_open');
  }

  // ==================== 画面遷移 ====================

  /// 画面表示（自動的にNavigatorObserverが記録）
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('⚠️ Screen view log error: $e');
    }
  }

  // ==================== 領収書関連 ====================

  /// 領収書作成開始
  static Future<void> logReceiptCreateStart() async {
    await logEvent(
      name: 'receipt_create_start',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// 領収書保存成功
  static Future<void> logReceiptSaved({
    required double amount,
    required String paymentMethod,
    bool hasTaxItems = false,
  }) async {
    await logEvent(
      name: 'receipt_saved',
      parameters: {
        'amount': amount,
        'payment_method': paymentMethod,
        'has_tax_items': hasTaxItems,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 領収書編集
  static Future<void> logReceiptEdited({
    required String receiptId,
  }) async {
    await logEvent(
      name: 'receipt_edited',
      parameters: {
        'receipt_id': receiptId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 領収書削除
  static Future<void> logReceiptDeleted({
    required String receiptId,
  }) async {
    await logEvent(
      name: 'receipt_deleted',
      parameters: {
        'receipt_id': receiptId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== PDF関連 ====================

  /// PDF生成
  static Future<void> logPdfGenerated({
    required String receiptNumber,
    required String format, // 'preview' or 'download'
  }) async {
    await logEvent(
      name: 'pdf_generated',
      parameters: {
        'receipt_number': receiptNumber,
        'format': format,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// PDFダウンロード
  static Future<void> logPdfDownloaded({
    required String receiptNumber,
  }) async {
    await logEvent(
      name: 'pdf_downloaded',
      parameters: {
        'receipt_number': receiptNumber,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== 共有・送信 ====================

  /// LINE送信
  static Future<void> logLineSent({
    String format = 'pdf', // 'pdf' or 'text'
    String? receiptNumber,
    int receiptCount = 1,
  }) async {
    await logEvent(
      name: 'line_sent',
      parameters: {
        'format': format,
        'receipt_number': receiptNumber ?? 'multiple',
        'receipt_count': receiptCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// PDF共有
  static Future<void> logPdfShared({
    required String receiptNumber,
  }) async {
    await logEvent(
      name: 'pdf_shared',
      parameters: {
        'receipt_number': receiptNumber,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== エクスポート ====================

  /// CSVエクスポート
  static Future<void> logCsvExported({
    required int receiptCount,
  }) async {
    await logEvent(
      name: 'csv_exported',
      parameters: {
        'receipt_count': receiptCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// JSONエクスポート
  static Future<void> logJsonExported({
    required int receiptCount,
  }) async {
    await logEvent(
      name: 'json_exported',
      parameters: {
        'receipt_count': receiptCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== テンプレート管理 ====================

  /// 宛名テンプレート作成
  static Future<void> logRecipientTemplateCreated() async {
    await logEvent(name: 'recipient_template_created');
  }

  /// 但書きテンプレート作成
  static Future<void> logDescriptionTemplateCreated() async {
    await logEvent(name: 'description_template_created');
  }

  /// 発行者プロファイル作成
  static Future<void> logIssuerProfileCreated() async {
    await logEvent(name: 'issuer_profile_created');
  }

  // ==================== サブスクリプション ====================

  /// プレミアム購入開始
  static Future<void> logPremiumPurchaseStart() async {
    await logEvent(name: 'premium_purchase_start');
  }

  /// プレミアム購入成功
  static Future<void> logPremiumPurchaseSuccess({
    required String productId,
    required double price,
  }) async {
    await logEvent(
      name: 'premium_purchase_success',
      parameters: {
        'product_id': productId,
        'price': price,
        'currency': 'JPY',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// プレミアム購入キャンセル
  static Future<void> logPremiumPurchaseCancelled() async {
    await logEvent(name: 'premium_purchase_cancelled');
  }

  // ==================== 広告 ====================

  /// バナー広告表示
  static Future<void> logBannerAdShown({
    required String screenName,
  }) async {
    await logEvent(
      name: 'banner_ad_shown',
      parameters: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// インタースティシャル広告表示
  static Future<void> logInterstitialAdShown() async {
    await logEvent(
      name: 'interstitial_ad_shown',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 広告クリック
  static Future<void> logAdClicked({
    required String adType, // 'banner' or 'interstitial'
  }) async {
    await logEvent(
      name: 'ad_clicked',
      parameters: {
        'ad_type': adType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== エラー追跡 ====================

  /// エラーログ
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ==================== ユーザープロパティ ====================

  /// ユーザープロパティ設定
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('⚠️ Set user property error: $e');
    }
  }

  /// プレミアムユーザー設定
  static Future<void> setUserPremiumStatus(bool isPremium) async {
    await setUserProperty(
      name: 'user_type',
      value: isPremium ? 'premium' : 'free',
    );
  }
}
