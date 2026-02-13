import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/database.dart';
import 'screens/home_screen.dart';
import 'screens/cloud_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/consent_service.dart';

void main() async {
  // DEBUG VERSION: Completely disable AdMob/UMP to isolate crash
  print('🔷 DEBUG: Starting Receipt Maker v1.0.2 (Debug)');
  
  try {
    print('🔷 DEBUG: Initializing Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ DEBUG: Flutter bindings initialized');
    
    // Initialize SharedPreferences early (especially for Web)
    try {
      print('🔷 DEBUG: Initializing SharedPreferences...');
      await SharedPreferences.getInstance();
      print('✅ DEBUG: SharedPreferences initialized successfully');
    } catch (e) {
      print('⚠️ DEBUG: SharedPreferences warning: $e');
    }
    
    // DISABLED: AdMob initialization completely removed for debugging
    print('🔷 DEBUG: AdMob initialization DISABLED for testing');
    
    print('🔷 DEBUG: Launching app...');
    runApp(
      Provider<AppDatabase>(
        create: (context) {
          print('🔷 DEBUG: Creating AppDatabase...');
          return AppDatabase();
        },
        dispose: (context, db) {
          print('🔷 DEBUG: Disposing AppDatabase...');
          db.close();
        },
        child: const MyApp(),
      ),
    );
    print('✅ DEBUG: App launched successfully');
  } catch (e, stackTrace) {
    print('❌ DEBUG: FATAL ERROR in main(): $e');
    print('❌ DEBUG: Stack trace: $stackTrace');
    
    // Show detailed error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(Icons.bug_report, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'デバッグモード',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'アプリの起動中にエラーが発生しました',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'エラー詳細:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      e.toString(),
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'スタックトレース:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      stackTrace.toString(),
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'このスクリーンショットを開発者に送信してください',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Maker',
      debugShowCheckedModeBanner: false,
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
