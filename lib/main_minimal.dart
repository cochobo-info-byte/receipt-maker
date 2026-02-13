import 'package:flutter/material.dart';

// MINIMAL VERSION: Absolute minimum Flutter app
void main() {
  print('🔷 MINIMAL: Starting app...');
  
  runApp(const MinimalApp());
  
  print('✅ MINIMAL: App started');
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Receipt Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MinimalHomePage(),
    );
  }
}

class MinimalHomePage extends StatefulWidget {
  const MinimalHomePage({super.key});

  @override
  State<MinimalHomePage> createState() => _MinimalHomePageState();
}

class _MinimalHomePageState extends State<MinimalHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Receipt Maker - テスト版'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              '✅ アプリが起動しました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'これは超ミニマル版です',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'タップカウンター:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            const Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '動作確認事項:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Flutter エンジン'),
                    Text('✅ Material Design 3'),
                    Text('✅ State Management'),
                    Text('✅ タップ操作'),
                    Text('✅ 画面表示'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'このアプリが起動したら、\n開発者に報告してください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
