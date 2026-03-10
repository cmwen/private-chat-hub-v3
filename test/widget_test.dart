import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:private_chat_hub/main.dart';
import 'package:private_chat_hub/providers/conversation_provider.dart';
import 'package:private_chat_hub/providers/settings_provider.dart';
import 'package:private_chat_hub/services/database_service.dart';

Future<List<Override>> _buildOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // Use sqflite_ffi in-memory DB so tests don't touch the file system.
  final db = DatabaseService(
    databaseFactoryOverride: databaseFactoryFfi,
    databasePathOverride: inMemoryDatabasePath,
  );
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseServiceProvider.overrideWithValue(db),
  ];
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('App smoke tests', () {
    testWidgets('app launches and shows chat screen', (tester) async {
      final overrides = await _buildOverrides();
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const PrivateChatHubApp()),
      );
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('settings screen is accessible', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      final overrides = await _buildOverrides();
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const PrivateChatHubApp()),
      );
      await tester.pumpAndSettle();

      final ScaffoldState scaffold = tester.firstState(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
    });
  });
}
