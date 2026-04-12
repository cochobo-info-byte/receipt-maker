import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'subscription_service.dart';

class AdService {
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isInitialized = false;
  static bool _isLoadingInterstitial = false;

  // Production Ad Unit IDs（本番環境用）
  static const String _productionBannerAdUnitId = 'ca-app-pub-5706787649643234/5488351774';
  static const String _productionInterstitialAdUnitId = 'ca-app-pub-5706787649643234/3478829206';

  // Test Ad Unit IDs（テスト環境用 - Googleの公式テストID）
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // 環境に応じて広告IDを切り替え
  static String get _bannerAdUnitId =>
      kDebugMode ? _testBannerAdUnitId : _productionBannerAdUnitId;

  static String get _interstitialAdUnitId =>
      kDebugMode ? _testInterstitialAdUnitId : _productionInterstitialAdUnitId;

  // Initialize Mobile Ads SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    debugPrint(kDebugMode
        ? '🧪 AdMob initialized with TEST ads'
        : '✅ AdMob initialized with PRODUCTION ads');
  }

  // Create and load banner ad
  static Future<BannerAd?> createBannerAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    if (isPremium) return null;

    if (!_isInitialized) await initialize();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    await _bannerAd!.load();
    return _bannerAd;
  }

  // Load interstitial ad（重複ロード防止付き）
  static Future<void> loadInterstitialAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    if (isPremium) return;

    // すでにロード済みまたはロード中なら何もしない
    if (_interstitialAd != null) {
      debugPrint('ℹ️ Interstitial ad already loaded');
      return;
    }
    if (_isLoadingInterstitial) {
      debugPrint('ℹ️ Interstitial ad is loading...');
      return;
    }

    if (!_isInitialized) await initialize();

    _isLoadingInterstitial = true;
    debugPrint('🔄 Loading interstitial ad...');

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          debugPrint('✅ Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          debugPrint('❌ Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  // Show interstitial ad（ロード完了を最大3秒待つ）
  static Future<void> showInterstitialAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    if (isPremium) return;

    // 広告がロードされていない場合、最大3秒待つ
    if (_interstitialAd == null) {
      debugPrint('⏳ Interstitial not ready, loading now...');
      await loadInterstitialAd();

      // ロード完了を最大3秒待つ
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_interstitialAd != null) break;
      }
    }

    if (_interstitialAd != null) {
      debugPrint('▶️ Showing interstitial ad');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('✅ Interstitial ad showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('✅ Interstitial ad dismissed, preloading next...');
          ad.dispose();
          _interstitialAd = null;
          // 次の広告を事前ロード
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
    } else {
      debugPrint('⚠️ Interstitial ad not available, preloading for next time');
      loadInterstitialAd();
    }
  }

  // Dispose ads
  static void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }

  // Check if ads should be shown
  static Future<bool> shouldShowAds() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    return !isPremium;
  }
}
