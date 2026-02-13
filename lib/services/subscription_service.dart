import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _premiumKey = 'is_premium_user';
  static const String _subscriptionDateKey = 'subscription_date';
  
  // Monthly subscription price
  static const int subscriptionPriceYen = 150;

  // Check if user is premium
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  // Set premium status
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

  // Get subscription date
  static Future<DateTime?> getSubscriptionDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_subscriptionDateKey);
    
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // Simulate subscription purchase (for demo)
  // In production, this should integrate with Play Billing/StoreKit
  static Future<bool> purchaseSubscription() async {
    try {
      // TODO: Integrate with Play Billing (Android) or StoreKit (iOS)
      // For now, just set premium status
      await setPremiumUser(true);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancel subscription
  static Future<void> cancelSubscription() async {
    await setPremiumUser(false);
  }

  // Premium features
  static const Map<String, dynamic> premiumFeatures = {
    'noAds': true,
    'unlimitedCloudSync': true,
    'prioritySupport': true,
    'advancedExport': true,
    'customTemplates': true,
  };

  // Check if feature is available
  static Future<bool> hasFeature(String featureName) async {
    final isPremium = await isPremiumUser();
    
    if (isPremium) {
      return true;
    }
    
    // Free features
    const freeFeatures = [
      'basicReceipts',
      'pdfGeneration',
      'localStorage',
      'basicExport',
    ];
    
    return freeFeatures.contains(featureName);
  }

  // Get subscription info for display
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
}
