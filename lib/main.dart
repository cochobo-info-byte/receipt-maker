import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'database/database.dart';
import 'screens/home_screen.dart';
import 'screens/cloud_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/consent_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences early (especially for Web)
  try {
    await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences initialized successfully');
  } catch (e) {
    debugPrint('⚠️ SharedPreferences initialization warning: $e');
  }
  
  // Initialize Firebase (モバイルのみ)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');
      
      // Initialize Firebase Analytics
      await AnalyticsService.initialize();
      
      // Log app open
      await AnalyticsService.logAppOpen();
    } catch (e) {
      debugPrint('⚠️ Firebase initialization warning: $e');
    }
  }
  
  // Initialize AdMob (モバイルのみ)
  if (!kIsWeb) {
    try {
      await ConsentService.initialize();
      await AdService.initialize();
      await AdService.loadInterstitialAd();
      debugPrint('✅ AdMob initialized successfully');
    } catch (e) {
      debugPrint('⚠️ AdMob initialization warning: $e');
    }
  } else {
    debugPrint('ℹ️ Firebase & AdMob disabled on Web platform');
  }
  
  runApp(
    Provider<AppDatabase>(
      create: (context) => AppDatabase(),
      dispose: (context, db) => db.close(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Maker',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        if (AnalyticsService.observer != null) AnalyticsService.observer!,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    CloudScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_outlined),
              activeIcon: Icon(Icons.cloud),
              label: 'クラウド',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
