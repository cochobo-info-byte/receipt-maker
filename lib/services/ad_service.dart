import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

class AdService {
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _isInitialized = false;

  // Production Ad Unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-5706787649643234/5463886415'; // Production Banner ID
  static const String _interstitialAdUnitId = 'ca-app-pub-5706787649643234/9842115124'; // Production Interstitial ID

  // Initialize Mobile Ads SDK
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
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
