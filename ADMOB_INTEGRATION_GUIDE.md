# 📱 AdMob SDK Integration Guide - Receipt Maker

## ✅ Integration Complete

AdMob SDK has been successfully integrated into the Receipt Maker app with the following configuration:

### 🔧 Configuration Details

**App ID:** `ca-app-pub-5706787649643234~8692577186`

**Ad Units:**
1. **Banner Ad**
   - Unit ID: `ca-app-pub-5706787649643234/5463886415`
   - Type: バナー (Standard Banner)
   - Size: 320x50 (AdSize.banner)
   - Location: Bottom of Home Screen

2. **Interstitial Ad**
   - Unit ID: `ca-app-pub-5706787649643234~8692577186`
   - Type: インタースティシャル (Full-Screen Interstitial)
   - Trigger: After creating a new receipt
   - Frequency: Once per receipt creation (for free users)

---

## 📁 Implementation Files

### 1. **android/app/src/main/AndroidManifest.xml**
```xml
<!-- AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-5706787649643234~8692577186"/>
```

### 2. **lib/services/ad_service.dart**
Centralized AdMob service with:
- Mobile Ads SDK initialization
- Banner ad creation and loading
- Interstitial ad loading and display
- Premium user check (ads disabled for premium users)
- Test/Production ad unit ID switching
- Error handling and lifecycle management

Key Features:
- **Environment-based Ad IDs**: Automatically switches between test and production ad units based on debug mode
- **Premium User Support**: Automatically hides ads for premium subscription users
- **Lifecycle Management**: Proper ad disposal and preloading
- **Error Handling**: Graceful failure handling with fallback behavior

### 3. **lib/widgets/banner_ad_widget.dart**
Reusable banner ad widget with:
- Automatic ad loading
- Premium user detection
- Lifecycle management (dispose on widget destruction)
- Responsive container with padding and borders

### 4. **lib/main.dart**
SDK initialization on app startup:
```dart
if (!kIsWeb) {
  await ConsentService.initialize();
  await AdService.initialize();
  await AdService.loadInterstitialAd();
}
```

### 5. **lib/screens/home_screen.dart**
Banner ad display at bottom of screen:
```dart
bottomNavigationBar: const BannerAdContainer(),
```

### 6. **lib/screens/receipt_form_screen.dart**
Interstitial ad display after receipt creation:
```dart
if (widget.receipt == null) {
  await AdService.showInterstitialAd();
  await AnalyticsService.logInterstitialAdShown();
}
```

---

## 🎯 Ad Placement Strategy

### Banner Ads
- **Location**: Bottom of Home Screen (above navigation bar)
- **Always Visible**: Displayed throughout the home screen browsing
- **Premium Users**: Hidden for premium subscription users
- **UX Consideration**: Non-intrusive, standard AdMob banner size

### Interstitial Ads
- **Trigger**: After successfully creating a new receipt
- **Frequency**: Once per creation (not shown when editing existing receipts)
- **Premium Users**: Not shown for premium subscription users
- **Preloading**: Next ad is preloaded immediately after display
- **UX Consideration**: Shown at natural transition points

---

## 🔒 Best Practices Implemented

### 1. **User Experience**
✅ Ads are non-intrusive and placed at natural breakpoints  
✅ Banner ads don't overlap with interactive elements  
✅ Interstitial ads shown only after user actions complete  
✅ Premium users have completely ad-free experience  

### 2. **Performance**
✅ Ads initialized asynchronously to avoid blocking UI  
✅ Interstitial ads preloaded for instant display  
✅ Proper ad disposal to prevent memory leaks  
✅ Error handling prevents app crashes from ad failures  

### 3. **AdMob Policy Compliance**
✅ App ID correctly configured in AndroidManifest.xml  
✅ Test ads used in debug mode, production ads in release mode  
✅ User consent managed through ConsentService  
✅ Analytics tracking for ad impressions  

### 4. **Code Quality**
✅ Centralized ad service for easy maintenance  
✅ Reusable banner ad widget  
✅ Clear separation of concerns  
✅ Comprehensive error handling  

---

## 🧪 Testing

### Debug Mode (Test Ads)
When running in debug mode, the app automatically uses Google's official test ad unit IDs:
- **Banner**: `ca-app-pub-3940256099942544/6300978111`
- **Interstitial**: `ca-app-pub-3940256099942544/1033173712`

```bash
# Run in debug mode with test ads
flutter run --debug
```

### Release Mode (Production Ads)
When building release APK/AAB, production ad unit IDs are used:
- **Banner**: `ca-app-pub-5706787649643234/5463886415`
- **Interstitial**: `ca-app-pub-5706787649643234~8692577186`

```bash
# Build release APK with production ads
flutter build apk --release

# Build release AAB for Google Play
flutter build appbundle --release
```

---

## 📊 Analytics Integration

Ad events are tracked through Firebase Analytics:
- `interstitial_ad_shown` - Logged when interstitial ad is displayed
- Error tracking for ad loading failures
- User engagement metrics

---

## 🚀 Deployment Checklist

Before releasing to production:

- [x] ✅ AdMob App ID configured in AndroidManifest.xml
- [x] ✅ Production ad unit IDs configured in AdService
- [x] ✅ Banner ads tested on home screen
- [x] ✅ Interstitial ads tested after receipt creation
- [x] ✅ Premium user ad-free experience verified
- [x] ✅ Test/Production ad switching verified
- [x] ✅ Error handling and fallback behavior tested
- [x] ✅ Analytics tracking for ad events verified
- [x] ✅ User consent flow integrated
- [x] ✅ Memory leak prevention (ad disposal) verified

---

## 🔧 Troubleshooting

### Issue: Ads not showing
**Solution:** 
1. Check internet connection
2. Verify AdMob App ID in AndroidManifest.xml
3. Ensure test mode is enabled for testing
4. Check if user has premium subscription

### Issue: App crashes on ad display
**Solution:**
1. Verify google_mobile_ads dependency version
2. Check error logs for detailed error messages
3. Ensure proper ad initialization in main.dart
4. Verify ad unit IDs are correct

### Issue: Test ads showing in production
**Solution:**
1. Verify app is built in release mode (`--release`)
2. Check `kDebugMode` flag in AdService
3. Ensure production ad unit IDs are configured

---

## 📝 Version History

### v1.3.0 (2024-02-19)
- ✨ AdMob SDK integration complete
- ✨ Banner ads on home screen
- ✨ Interstitial ads after receipt creation
- ✨ Premium user ad-free experience
- ✨ Test/Production ad unit switching
- ✨ Firebase Analytics integration for ad events

---

## 📞 Support

For AdMob-related issues:
- **AdMob Help Center**: https://support.google.com/admob
- **Flutter Google Mobile Ads**: https://pub.dev/packages/google_mobile_ads
- **Implementation Issues**: Check IMPLEMENTATION_GUIDE.md

---

**© 2024 Receipt Maker. All rights reserved.**
