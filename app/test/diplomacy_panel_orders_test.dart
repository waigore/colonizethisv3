// DiplomacyPanel order UI + bus command emission coverage.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  final ninePatchFallbackPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+X2ioAAAAASUVORK5CYII=',
  );
  Uint8List ninePatchBytes = ninePatchFallbackPng;

  setUpAll(() async {
    final assetCandidates = <String>[
      'app/assets/images/ui_button_nine_patch.png',
      'assets/images/ui_button_nine_patch.png',
    ];
    for (final candidate in assetCandidates) {
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
            return ByteData.view(ninePatchBytes.buffer);
          }
          return null;
        });

    try {
      final bytes = await rootBundle.load(
        'assets/images/ui_button_nine_patch.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      Flame.images.add('ui_button_nine_patch.png', frame.image);
      Flame.images.add('assets/images/ui_button_nine_patch.png', frame.image);
    } catch (_) {
      // Keep test resilient if this host cannot decode during prewarm.
    }
  });

  setUp(() {
    AppEventBus.reset();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets(
    'DiplomacyPanel shows always-visible section headings + tribe placeholder '
    'when no factions discovered',
    (WidgetTester tester) async {
      const humanId = 'solo';
      final game = Game(
        id: 'solo_game',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: humanId, displayName: 'Only', isHuman: true, treasury: 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: MapTopology(),
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SPEC/ui/diplomacy-panel.md § Section headings (Refs #3341).
      expect(find.text('Great Powers'), findsOneWidget);
      expect(find.text('Minor Nations'), findsOneWidget);
      expect(find.text('Tribes'), findsOneWidget);
      expect(find.text('No tribes contacted yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyPanel confirm action emits AppendDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final confirmSub = bus.on<ConfirmDialogEvent>().listen((event) {
        event.result(true);
      });
      addTearDown(confirmSub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: const Orders(),
              bus: bus,
            ),
          ),
        ),
      );
      await tester.pump();

      const actionLabels = <String>['Declare War', 'Offer Peace', 'Alliance'];
      Finder? actionFinder;
      for (final label in actionLabels) {
        final candidate = find.text(label);
        if (candidate.evaluate().isNotEmpty) {
          actionFinder = candidate.first;
          break;
        }
      }
      expect(
        actionFinder,
        isNotNull,
        reason: 'Expected at least one non-parameter diplomacy action button',
      );

      await tester.ensureVisible(actionFinder!);
      await tester.tap(actionFinder);
      await tester.pump();

      final event = await appendFuture;
      expect(event.playerId, humanId);
    },
  );

  testWidgets(
    'DiplomacyPanel pending cancel emits RemoveDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final target = game.players.firstWhere((p) => p.id != humanId).id;
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final currentOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: target,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: currentOrders,
              bus: bus,
            ),
          ),
        ),
      );
      await tester.pump();

      final cancelButton = find.text('Cancel').first;
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.declareWar);
      expect(event.targetFactionId, target);
    },
  );
}
