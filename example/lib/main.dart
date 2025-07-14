import 'package:flutter/material.dart';
import 'package:flutter_core_storage/flutter_core_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service
  await StorageService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Service Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: StorageExampleScreen(),
    );
  }
}

class StorageExampleScreen extends StatefulWidget {
  const StorageExampleScreen({super.key});

  @override
  State<StorageExampleScreen> createState() => _StorageExampleScreenState();
}

class _StorageExampleScreenState extends State<StorageExampleScreen> {
  final _storageService = StorageService.instance;

  String _status = 'Ready to test storage operations';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Storage Service Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Preferences Storage Tests
            _buildSection('Preferences Storage', [
              ElevatedButton(
                onPressed: _testPreferences,
                child: Text('Test Preferences'),
              ),
            ]),

            // Secure Storage Tests
            _buildSection('Secure Storage', [
              ElevatedButton(
                onPressed: _testSecureStorage,
                child: Text('Test Secure Storage'),
              ),
            ]),

            // Cache Tests
            _buildSection('Cache Management', [
              ElevatedButton(onPressed: _testCache, child: Text('Test Cache')),
            ]),

            // File Storage Tests
            _buildSection('File Storage', [
              ElevatedButton(
                onPressed: _testFileStorage,
                child: Text('Test File Storage'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  Future<void> _testPreferences() async {
    try {
      _updateStatus('Testing preferences storage...');

      // Test string storage
      await _storageService.setString('test_key', 'test_value');
      final value = await _storageService.getString('test_key');

      _updateStatus('✅ Preferences test passed: $value');
    } catch (e) {
      _updateStatus('❌ Preferences test failed: $e');
    }
  }

  Future<void> _testSecureStorage() async {
    try {
      _updateStatus('Testing secure storage...');

      // Test secure storage (implementation needed)
      await _storageService.setSecure('secure_key', 'secure_value');
      final value = await _storageService.getSecure('secure_key');

      _updateStatus('✅ Secure storage test passed: $value');
    } catch (e) {
      _updateStatus('❌ Secure storage test failed: $e');
    }
  }

  Future<void> _testCache() async {
    try {
      _updateStatus('Testing cache management...');

      // Test cache with TTL
      await _storageService.cache('cache_key', {
        'data': 'cached_value',
      }, duration: Duration(seconds: 30));

      final cached = await _storageService.getCached('cache_key');

      _updateStatus('✅ Cache test passed: $cached');
    } catch (e) {
      _updateStatus('❌ Cache test failed: $e');
    }
  }

  Future<void> _testFileStorage() async {
    try {
      _updateStatus('Testing file storage...');

      // Test file operations
      const content = 'This is test file content';
      await _storageService.writeFile('test.txt', content);

      final readContent = await _storageService.readFile('test.txt');

      _updateStatus('✅ File storage test passed: $readContent');
    } catch (e) {
      _updateStatus('❌ File storage test failed: $e');
    }
  }
}
