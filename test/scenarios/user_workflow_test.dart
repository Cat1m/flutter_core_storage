// test/scenarios/user_workflow_test.dart
import 'package:flutter_core_storage/flutter_core_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';
import '../utils/test_data_factory.dart';

void main() {
  group('User Workflow Scenarios', () {
    setUp(() {
      TestHelper.setUp();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      if (StorageService.isInitialized) {
        await StorageService.dispose();
      }
    });

    test('complete user onboarding flow', () async {
      // Initialize storage
      await StorageService.initialize(config: StorageConfig.development());

      // Step 1: User registration
      final newUser = TestDataFactory.createUser(
        name: 'Alice Smith',
        email: 'alice@example.com',
      );

      await StorageService.instance.setObject('current_user', newUser);
      await StorageService.instance.setBool('onboarding_completed', true);
      await StorageService.instance
          .setString('last_login', DateTime.now().toIso8601String());

      // Step 2: Initial settings
      final defaultSettings = TestDataFactory.createSettings(
        theme: 'light',
        notifications: true,
        language: 'en',
      );

      await StorageService.instance.setObject('user_settings', defaultSettings);

      // Step 3: Cache user data for quick access
      await StorageService.instance.cache(
        'user_${newUser['id']}',
        newUser,
        duration: const Duration(hours: 8),
      );

      // Step 4: Verification
      final storedUser = await StorageService.instance
          .getObject<Map<String, dynamic>>('current_user');
      final onboardingDone =
          await StorageService.instance.getBool('onboarding_completed');
      final cachedUser = await StorageService.instance
          .getCached<Map<String, dynamic>>('user_${newUser['id']}');
      final settings = await StorageService.instance
          .getObject<Map<String, dynamic>>('user_settings');

      // Assert complete workflow
      expect(storedUser!['name'], equals('Alice Smith'));
      expect(onboardingDone, isTrue);
      expect(cachedUser!['email'], equals('alice@example.com'));
      expect(settings!['theme'], equals('light'));
    });

    test('user session management workflow', () async {
      await StorageService.initialize();

      // Login flow
      const sessionToken = 'jwt_token_abc123';
      const refreshToken = 'refresh_token_xyz789';
      final loginTime = DateTime.now();

      // Store session securely
      await StorageService.instance.setSecure('session_token', sessionToken);
      await StorageService.instance.setSecure('refresh_token', refreshToken);
      await StorageService.instance
          .setString('login_time', loginTime.toIso8601String());
      await StorageService.instance.setBool('remember_me', true);

      // Store user preferences in cache for performance
      final userPrefs = TestDataFactory.createSettings();
      await StorageService.instance.cache(
        'user_preferences',
        userPrefs,
        duration: const Duration(hours: 4),
      );

      // Simulate app restart - check session validity
      final storedToken =
          await StorageService.instance.getSecure('session_token');
      final shouldRemember =
          await StorageService.instance.getBool('remember_me');
      final cachedPrefs = await StorageService.instance
          .getCached<Map<String, dynamic>>('user_preferences');

      expect(storedToken, equals(sessionToken));
      expect(shouldRemember, isTrue);
      expect(cachedPrefs, isNotNull);

      // Logout flow
      await StorageService.instance.removeSecure('session_token');
      await StorageService.instance.removeSecure('refresh_token');
      await StorageService.instance.removeCache('user_preferences');
      await StorageService.instance.setBool('remember_me', false);

      // Verify cleanup
      final tokenAfterLogout =
          await StorageService.instance.getSecure('session_token');
      final prefsAfterLogout = await StorageService.instance
          .getCached<Map<String, dynamic>>('user_preferences');

      expect(tokenAfterLogout, isNull);
      expect(prefsAfterLogout, isNull);
    });

    test('shopping cart workflow', () async {
      await StorageService.initialize();

      // Create shopping cart
      final cartItems = <Map<String, dynamic>>[];

      // Add items to cart
      for (int i = 0; i < 5; i++) {
        final product = TestDataFactory.createProduct(id: i);
        final cartItem = {
          'product': product,
          'quantity': (i % 3) + 1,
          'added_at': DateTime.now().toIso8601String(),
        };
        cartItems.add(cartItem);
      }

      // Store cart in different ways for resilience
      await StorageService.instance.setObject('shopping_cart', cartItems);
      await StorageService.instance
          .cache('cart_backup', cartItems, duration: const Duration(hours: 24));
      await StorageService.instance.setInt('cart_item_count', cartItems.length);

      // Simulate cart modifications
      cartItems.add({
        'product': TestDataFactory.createProduct(id: 99),
        'quantity': 2,
        'added_at': DateTime.now().toIso8601String(),
      });

      await StorageService.instance.setObject('shopping_cart', cartItems);
      await StorageService.instance.setInt('cart_item_count', cartItems.length);

      // Verify cart state
      final storedCart = await StorageService.instance
          .getObject<List<dynamic>>('shopping_cart');
      final itemCount = await StorageService.instance.getInt('cart_item_count');

      expect(storedCart!.length, equals(6));
      expect(itemCount, equals(6));

      // Checkout process - move to order history
      final order = {
        'id': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'items': cartItems,
        'total': cartItems.fold<double>(
            0,
            (sum, item) =>
                sum +
                (double.parse(item['product']['price']) * item['quantity'])),
        'created_at': DateTime.now().toIso8601String(),
      };

      await StorageService.instance
          .save('order_history', order, key: order['id']);
      await StorageService.instance.remove('shopping_cart');
      await StorageService.instance.setInt('cart_item_count', 0);

      // Verify checkout
      final clearedCart = await StorageService.instance
          .getObject<List<dynamic>>('shopping_cart');
      final finalCount =
          await StorageService.instance.getInt('cart_item_count');
      final savedOrder = await StorageService.instance
          .get<Map<String, dynamic>>('order_history', order['id']);

      expect(clearedCart, isNull);
      expect(finalCount, equals(0));
      expect(savedOrder!['items'].length, equals(6));
    });

    test('offline data synchronization workflow', () async {
      await StorageService.initialize();

      // Simulate offline actions queue
      final offlineActions = [
        {
          'type': 'create_post',
          'data': {'title': 'Offline Post 1'},
          'timestamp': DateTime.now().toIso8601String()
        },
        {
          'type': 'update_profile',
          'data': {'bio': 'Updated offline'},
          'timestamp': DateTime.now().toIso8601String()
        },
        {
          'type': 'like_post',
          'data': {'post_id': 123},
          'timestamp': DateTime.now().toIso8601String()
        },
      ];

      // Store offline actions
      for (int i = 0; i < offlineActions.length; i++) {
        await StorageService.instance
            .save('sync_queue', offlineActions[i], key: 'action_$i');
      }

      await StorageService.instance
          .setInt('pending_sync_count', offlineActions.length);
      await StorageService.instance
          .setString('last_sync_attempt', DateTime.now().toIso8601String());

      // Simulate sync process
      final queuedActions = await StorageService.instance
          .getAll<Map<String, dynamic>>('sync_queue');
      expect(queuedActions.length, equals(3));

      // Process each action (simulate API calls)
      final syncResults = <String, bool>{};
      for (final action in queuedActions) {
        // Simulate successful sync
        syncResults[action['type']] = true;
      }

      // Clear synced actions
      await StorageService.instance.clearBox('sync_queue');
      await StorageService.instance.setInt('pending_sync_count', 0);
      await StorageService.instance
          .setString('last_successful_sync', DateTime.now().toIso8601String());

      // Store sync results for analytics
      await StorageService.instance.setObject('last_sync_results', syncResults);

      // Verify sync completion
      final remainingActions = await StorageService.instance
          .getAll<Map<String, dynamic>>('sync_queue');
      final pendingCount =
          await StorageService.instance.getInt('pending_sync_count');
      final results = await StorageService.instance
          .getObject<Map<String, dynamic>>('last_sync_results');

      expect(remainingActions, isEmpty);
      expect(pendingCount, equals(0));
      expect(results!.values.every((success) => success), isTrue);
    });

    test('app settings and preferences workflow', () async {
      await StorageService.initialize();

      // Initial app setup
      final appConfig = {
        'app_version': '1.0.0',
        'environment': 'development',
        'api_base_url': 'https://dev-api.example.com',
        'feature_flags': {
          'new_ui': true,
          'analytics': false,
          'beta_features': true,
        }
      };

      await StorageService.instance.writeJson('app_config.json', appConfig);
      await StorageService.instance
          .cache('app_config', appConfig, duration: const Duration(days: 1));

      // User customizations
      final userSettings = TestDataFactory.createSettings(
        theme: 'dark',
        notifications: true,
        language: 'es',
      );

      await StorageService.instance.setObject('user_settings', userSettings);

      // Feature usage tracking
      await StorageService.instance.setInt('feature_new_ui_usage', 5);
      await StorageService.instance.setInt('notifications_sent', 12);
      await StorageService.instance
          .setStringList('recent_searches', ['query1', 'query2', 'query3']);

      // App update scenario
      const newVersion = '1.1.0';
      await StorageService.instance.setString('app_version', newVersion);

      // Migration logic would go here
      final currentSettings = await StorageService.instance
          .getObject<Map<String, dynamic>>('user_settings');
      if (currentSettings != null) {
        currentSettings['migrated_to'] = newVersion;
        currentSettings['migration_date'] = DateTime.now().toIso8601String();
        await StorageService.instance
            .setObject('user_settings', currentSettings);
      }

      // Verify settings persistence
      final config = await StorageService.instance
          .readJson<Map<String, dynamic>>('app_config.json');
      final cachedConfig = await StorageService.instance
          .getCached<Map<String, dynamic>>('app_config');
      final settings = await StorageService.instance
          .getObject<Map<String, dynamic>>('user_settings');
      final searches =
          await StorageService.instance.getStringList('recent_searches');

      expect(config!['app_version'], equals('1.0.0')); // File version
      expect(cachedConfig!['feature_flags']['new_ui'], isTrue);
      expect(settings!['theme'], equals('dark'));
      expect(settings['migrated_to'], equals(newVersion));
      expect(searches!.length, equals(3));
    });
  });
}
