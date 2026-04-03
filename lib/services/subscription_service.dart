import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _premiumKey = 'is_premium_user';
  static const String _subscriptionDateKey = 'subscription_date';

  // Google Play の商品ID（Play Consoleで設定するIDと一致させる）
  static const String kPremiumMonthlyId = 'premium_monthly';

  // Monthly subscription price (表示用)
  static const int subscriptionPriceYen = 150;

  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ──────────────────────────────────────
  // 初期化: アプリ起動時に一度呼ぶ
  // ──────────────────────────────────────
  static Future<void> initialize() async {
    // Web では課金非対応のためスキップ
    if (kIsWeb) return;

    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) return;

    // 購入ストリームを監視
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('IAP stream error: $error');
      },
    );

    // 未完了の購入があれば復元
    await _restorePendingPurchases();
  }

  // ──────────────────────────────────────
  // 購入ストリームのコールバック
  // ──────────────────────────────────────
  static Future<void> _onPurchaseUpdate(
      List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == kPremiumMonthlyId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await setPremiumUser(true);
          debugPrint('✅ Premium activated: ${purchase.productID}');
        } else if (purchase.status == PurchaseStatus.error) {
          debugPrint('❌ Purchase error: ${purchase.error}');
        } else if (purchase.status == PurchaseStatus.canceled) {
          debugPrint('⚠️ Purchase canceled');
        }

        // 購入完了を Google Play に通知（必須）
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
  }

  // ──────────────────────────────────────
  // 未完了購入の復元
  // ──────────────────────────────────────
  static Future<void> _restorePendingPurchases() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  // ──────────────────────────────────────
  // サブスクリプション購入フロー
  // ──────────────────────────────────────
  static Future<bool> purchaseSubscription() async {
    // Web は非対応
    if (kIsWeb) {
      debugPrint('⚠️ IAP not supported on Web');
      return false;
    }

    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      debugPrint('❌ Store not available');
      return false;
    }

    // 商品情報を取得
    final ProductDetailsResponse response =
        await InAppPurchase.instance.queryProductDetails({kPremiumMonthlyId});

    if (response.error != null) {
      debugPrint('❌ Product query error: ${response.error}');
      return false;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('❌ Product not found: $kPremiumMonthlyId');
      debugPrint('  → Google Play Console でサブスクリプションを設定してください');
      return false;
    }

    // 購入リクエスト送信
    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    try {
      return await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      return false;
    }
  }

  // ──────────────────────────────────────
  // プレミアム状態の確認・保存
  // ──────────────────────────────────────
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<void> setPremiumUser(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);

    if (isPremium) {
      await prefs.setString(
        _subscriptionDateKey,
        DateTime.now().toIso8601String(),
      );
    } else {
      await prefs.remove(_subscriptionDateKey);
    }
  }

  // ──────────────────────────────────────
  // サブスクリプションのキャンセル
  // Google Play ではアプリ内でキャンセルできないため
  // Play Storeのサブスクリプション管理ページへ誘導する
  // ──────────────────────────────────────
  static Future<void> cancelSubscription() async {
    // ローカルのプレミアム状態はそのまま維持
    // 実際のキャンセルはユーザーがPlay Storeから行う
    debugPrint('ℹ️ ユーザーをPlay Storeのサブスクリプション管理へ誘導してください');
  }

  // ──────────────────────────────────────
  // 購入の復元（再インストール時など）
  // ──────────────────────────────────────
  static Future<void> restorePurchases() async {
    if (kIsWeb) return;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('Restore error: $e');
    }
  }

  // ──────────────────────────────────────
  // サブスクリプション日時の取得
  // ──────────────────────────────────────
  static Future<DateTime?> getSubscriptionDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_subscriptionDateKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // ──────────────────────────────────────
  // フィーチャーチェック
  // ──────────────────────────────────────
  static const Map<String, dynamic> premiumFeatures = {
    'noAds': true,
    'unlimitedCloudSync': true,
    'prioritySupport': true,
    'advancedExport': true,
    'customTemplates': true,
  };

  static Future<bool> hasFeature(String featureName) async {
    final isPremium = await isPremiumUser();
    if (isPremium) return true;

    const freeFeatures = [
      'basicReceipts',
      'pdfGeneration',
      'localStorage',
      'basicExport',
    ];
    return freeFeatures.contains(featureName);
  }

  static Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final isPremium = await isPremiumUser();
    final subscriptionDate = await getSubscriptionDate();

    return {
      'isPremium': isPremium,
      'subscriptionDate': subscriptionDate?.toIso8601String(),
      'price': subscriptionPriceYen,
      'features': premiumFeatures,
    };
  }

  // ──────────────────────────────────────
  // 破棄
  // ──────────────────────────────────────
  static void dispose() {
    _subscription?.cancel();
  }
}
