// Tests for DiplomacyScreen widget. SPEC/ui/diplomacy-panel.md.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy_screen.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game gameWithFactions;
  late String humanPlayerId;

  setUpAll(() async {
    await _mockNinePatchAssetForTests();
    await _preWarmPanelNinePatchForTests();
    final result = getDebugInitGameResult();
    gameWithFactions = result.game;
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  Widget buildScreen({required Game game, required String humanPlayerId}) {
    return ProviderScope(
      child: MaterialApp(
        home: Navigator(
          pages: [
            MaterialPage(
              child: DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
            ),
          ],
          onPopPage: (_, __) => false,
        ),
      ),
    );
  }

  group('DiplomacyScreen', () {
    testWidgets('uses CtScreenShell with showBackButton true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtScreenShell), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows title Diplomacy', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diplomacy'), findsOneWidget);
    });

    testWidgets('contains DiplomacyPanel content', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildScreen(game: gameWithFactions, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('back button is tappable', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const Text('Home'),
          ),
        ),
      );

      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DiplomacyScreen(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diplomacy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Diplomacy'), findsNothing);
    });
  });
}

Future<void> _preWarmPanelNinePatchForTests() async {
  try {
    final bytes =
        await rootBundle.load('assets/images/ui_button_nine_patch.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
    Flame.images
        .add('assets/images/ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Resilient when decode fails on some hosts.
  }
}

Future<void> _mockNinePatchAssetForTests() async {
  final fallbackBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  );
  var ninePatchBytes = fallbackBytes;
  for (final candidate in <String>[
    'app/assets/images/ui_button_nine_patch.png',
    'assets/images/ui_button_nine_patch.png',
  ]) {
    final file = File(candidate);
    if (await file.exists()) {
      ninePatchBytes = await file.readAsBytes();
      break;
    }
  }
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final key = const StringCodec().decodeMessage(message);
        if (key == 'assets/images/ui_button_nine_patch.png') {
          return ByteData.view(Uint8List.fromList(ninePatchBytes).buffer);
        }
        return null;
      });
}
