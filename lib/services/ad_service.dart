import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'subscription_service.dart';

class AdService {
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isInitialized = false;

  // Production Ad Unit IDs（本番環境用）
  static const String _productionBannerAdUnitId = 'ca-app-pub-5706787649643234/5463886415';
  static const String _productionInterstitialAdUnitId = 'ca-app-pub-5706787649643234~8692577186';

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
    
    if (kDebugMode) {
      debugPrint('🧪 AdMob initialized with TEST ads');
    } else {
      debugPrint('✅ AdMob initialized with PRODUCTION ads');
    }
  }

  // Create and load banner ad
  static Future<BannerAd?> createBannerAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Don't show ads to premium users
    if (isPremium) {
      return null;
    }

    if (!_isInitialized) {
      await initialize();
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Ad loaded successfully
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    await _bannerAd!.load();
    return _bannerAd;
  }

  // Load interstitial ad
  static Future<void> loadInterstitialAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Don't load ads for premium users
    if (isPremium) {
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  // Show interstitial ad (e.g., after creating receipt)
  static Future<void> showInterstitialAd() async {
    final isPremium = await SubscriptionService.isPremiumUser();
    
    // Don't show ads to premium users
    if (isPremium) {
      return;
    }

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          // Preload next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
        },
      );

      await _interstitialAd!.show();
    } else {
      // Preload for next time
      await loadInterstitialAd();
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
