import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Banner Ad Widget with automatic lifecycle management
/// 
/// Usage:
/// ```dart
/// BannerAdWidget()
/// ```
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _shouldShowAds = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    // Check if ads should be shown (premium users don't see ads)
    _shouldShowAds = await AdService.shouldShowAds();
    
    if (!_shouldShowAds) {
      return;
    }

    // Create and load banner ad
    final ad = await AdService.createBannerAd();
    
    if (mounted) {
      setState(() {
        _bannerAd = ad;
        _isAdLoaded = ad != null;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if ads should not be displayed
    if (!_shouldShowAds) {
      return const SizedBox.shrink();
    }

    // Don't show anything if ad is not loaded
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Show the banner ad
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Banner Ad Container with padding and border
/// 
/// Usage:
/// ```dart
/// BannerAdContainer()
/// ```
class BannerAdContainer extends StatelessWidget {
  const BannerAdContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: const BannerAdWidget(),
    );
  }
}
