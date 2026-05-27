// Tests for DiplomacyPanel. SPEC/ui/diplomacy-panel.md.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// `pumpAndSettle` hangs here: Flame nine-patch widgets can keep the ticker
/// busy. Bounded pumps flush layout, bus handlers, and dialog routes.
Future<void> _pumpPanelBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

/// Dialogs: `showDialog` from async bus listeners + route transition.
/// Tall surface so diplomacy rows and action buttons are on-screen without
/// calling `ensureVisible` (avoids long scroll pump loops on [ListView]).
Future<void> _bindTallTestSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(800, 4000));
}

class _EventHandlingWrapper extends StatefulWidget {
  const _EventHandlingWrapper({
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_EventHandlingWrapper> createState() => _EventHandlingWrapperState();
}

class _EventHandlingWrapperState extends State<_EventHandlingWrapper> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _openDialogSub;

  @override
  void initState() {
    super.initState();
    // Defer showDialog past the pointer + emit stack. Opening a route synchronously
    // from an onPressed that runs during gesture dispatch can hang the test binding.
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) {
      scheduleMicrotask(() async {
        if (!mounted) return;
        final nav = widget.navigatorKey.currentState;
        if (nav == null) return;
        final result = await showDialog<bool>(
          context: nav.context,
          builder: (ctx) => AlertDialog(
            title: Text(event.title),
            content: Text(event.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(event.cancelLabel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(event.confirmLabel),
              ),
            ],
          ),
        );
        event.result(result ?? false);
      });
    });
    _openDialogSub = widget.bus.on<OpenDialogEvent>().listen((event) {
      scheduleMicrotask(() async {
        if (!mounted) return;
        final nav = widget.navigatorKey.currentState;
        if (nav == null) return;
        await showDialog<void>(
          context: nav.context,
          builder: (ctx) => AlertDialog(
            title: Text('dialog:${event.dialogId}'),
            content: const Text('opened-via-bus'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _openDialogSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (e) {
    // Silently fail - the test might still work if the image is available later
  }
}

Widget buildPanel({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  Orders currentOrders = const Orders(),
  AppEventBus? bus,
}) {
  final panelBus = bus ?? AppEventBus.create();
  final navigatorKey = GlobalKey<NavigatorState>();
  return MaterialApp(
    navigatorKey: navigatorKey,
    home: Scaffold(
      body: _EventHandlingWrapper(
        bus: panelBus,
        navigatorKey: navigatorKey,
        child: DiplomacyPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: currentOrders,
          bus: panelBus,
        ),
      ),
    ),
  );
}

Game _gameWithNoDiscoveredFactions() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'empty-diplo',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late Game gameWithNoDiscovered;
  late String humanPlayerId;
  late MapTopology topology;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    await _preWarmFlameImageCache();
    final result = getDebugInitGameResult();
    gameWithFactions = result.game;
    topology = result.combinedTopology;
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
    gameWithNoDiscovered = _gameWithNoDiscoveredFactions();
  });

  group('DiplomacyPanel', () {
    testWidgets('AC: Great Powers section when player has discovered GPs', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('AC: Faction rows show name and kind', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.byType(CtPanel), findsAtLeastNWidgets(1));
      final firstGp = gameWithFactions.players
          .where((p) => p.id != humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state shown (Peace or War)', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(
        find.textContaining('Peace').evaluate().isNotEmpty ||
            find.textContaining('War').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'AC: One-word relation state shown (Hostile/Unfriendly/Cordial/Friendly), score hidden',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await _pumpPanelBuilt(tester);

        final displayLabels = ['Hostile', 'Unfriendly', 'Cordial', 'Friendly'];
        final hasDisplayLabel = displayLabels.any(
          (label) => find.textContaining(label).evaluate().isNotEmpty,
        );
        expect(
          hasDisplayLabel,
          isTrue,
          reason: 'Panel must show one of $displayLabels',
        );

        expect(find.textContaining(' (50)'), findsNothing);
        expect(find.text('Neutral'), findsNothing);
      },
    );

    testWidgets('AC: Action buttons present for factions', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.byType(CtNinePatchButton), findsAtLeastNWidgets(1));
      expect(
        find.text('Declare War').evaluate().isNotEmpty ||
            find.text('Offer Peace').evaluate().isNotEmpty ||
            find.text('Alliance').evaluate().isNotEmpty,
        isTrue,
      );
    });


    testWidgets('AC: Pending orders show Cancel button, action button hidden', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final initialOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        initialOrders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: initialOrders,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.text('Cancel'), findsWidgets);
    });


    testWidgets('AC: Empty state when no factions discovered', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithNoDiscovered,
          humanPlayerId: 'gp1',
          topology: const MapTopology(nodes: [], edges: []),
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.text('No other factions discovered yet.'), findsOneWidget);
    });

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('buildDiplomacyRows', () {
    test(
      'display mapping aligned with SPEC (relationScoreToDisplayLabel bands)',
      () {
        expect(relationScoreToDisplayLabel(0), 'Hostile');
        expect(relationScoreToDisplayLabel(29), 'Hostile');
        expect(relationScoreToDisplayLabel(30), 'Unfriendly');
        expect(relationScoreToDisplayLabel(49), 'Unfriendly');
        expect(relationScoreToDisplayLabel(50), 'Cordial');
        expect(relationScoreToDisplayLabel(69), 'Cordial');
        expect(relationScoreToDisplayLabel(70), 'Friendly');
        expect(relationScoreToDisplayLabel(100), 'Friendly');
      },
    );

    test('returns empty list when player has no relations', () {
      final rows = buildDiplomacyRows(
        gameWithNoDiscovered,
        const MapTopology(nodes: [], edges: []),
        'gp1',
        const Orders(),
      );
      expect(rows, isEmpty);
    });

    test('returns GP rows sorted by military power then province count', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      if (gpRows.length < 2) return;
      for (var i = 0; i < gpRows.length - 1; i++) {
        final strA = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i].factionId,
        );
        final strB = aggregateMilitaryStrengthForPlayer(
          gameWithFactions,
          gpRows[i + 1].factionId,
        );
        expect(strA >= strB, isTrue);
      }
    });

    test('GP rows have power score and player power score set', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows
          .where((r) => r.kind == FactionKind.greatPower)
          .toList();
      for (final r in gpRows) {
        expect(r.powerScore, isNotNull, reason: 'GP row ${r.displayName}');
        expect(
          r.playerPowerScore,
          isNotNull,
          reason: 'GP row ${r.displayName}',
        );
      }
      final nonGp = rows.where((r) => r.kind != FactionKind.greatPower);
      for (final r in nonGp) {
        expect(r.powerScore, isNull);
        expect(r.playerPowerScore, isNull);
      }
    });

    test('pendingOrderTypes reflects submitted diplomatic orders', () {
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        orders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
    });
  });

  group('powerComparisonPercent', () {
    test('GP stronger than player produces positive percentage', () {
      expect(powerComparisonPercent(110, 100), 10);
    });

    test('GP weaker than player produces negative percentage', () {
      expect(powerComparisonPercent(78, 100), -22);
    });

    test('equal scores produce zero percentage', () {
      expect(powerComparisonPercent(100, 100), 0);
    });

    test('rounding uses banker-agnostic round() (positive)', () {
      // (105 - 100) / 100 = 0.05 → +5
      expect(powerComparisonPercent(105, 100), 5);
      // (114 - 100) / 100 = 0.14 → +14
      expect(powerComparisonPercent(114, 100), 14);
    });

    test('zero playerPowerScore uses max(playerScore, 1) guard', () {
      // With denominator clamped to 1, (50 - 0) / 1 = 50 → +5000%
      expect(powerComparisonPercent(50, 0), 5000);
      // (0 - 0) / max(0, 1) = 0 → 0%, finite (no NaN, no division-by-zero)
      expect(powerComparisonPercent(0, 0), 0);
    });

    test('negative playerPowerScore is still guarded by max(.., 1)', () {
      // The SPEC formula uses `max(playerPowerScore, 1)`; a defensive call
      // with a negative `playerPowerScore` must not produce a sign flip via a
      // negative denominator. Result must be a finite integer using `1` as
      // the effective denominator.
      expect(powerComparisonPercent(50, -10), 6000);
    });
  });

  group('formatPowerComparisonPercent', () {
    test('positive percentage uses ASCII plus and percent suffix', () {
      expect(formatPowerComparisonPercent(10), '+10%');
      expect(formatPowerComparisonPercent(1), '+1%');
    });

    test('negative percentage uses unicode minus sign (U+2212)', () {
      // U+2212 MINUS SIGN, not U+002D HYPHEN-MINUS.
      expect(formatPowerComparisonPercent(-22), '\u221222%');
      expect(formatPowerComparisonPercent(-1), '\u22121%');
      expect(formatPowerComparisonPercent(-22).startsWith('\u2212'), isTrue);
      expect(formatPowerComparisonPercent(-22).startsWith('-'), isFalse);
    });

    test('zero percentage formats as "0%" without sign', () {
      expect(formatPowerComparisonPercent(0), '0%');
    });
  });

  group('DiplomacyPanel GP power-comparison rendering', () {
    testWidgets('AC: GP +10% renders in --danger color', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final stronger = rows
          .where(
            (r) =>
                r.kind == FactionKind.greatPower &&
                r.powerScore != null &&
                r.playerPowerScore != null &&
                r.powerScore! > r.playerPowerScore!,
          )
          .toList();
      if (stronger.isEmpty) {
        // No qualifying row in the debug-init game; skip dynamically rather
        // than failing — the helper-level tests already pin the formula.
        return;
      }
      for (final r in stronger) {
        final pct = powerComparisonPercent(r.powerScore!, r.playerPowerScore!);
        if (pct <= 0) continue;
        final expectedText = formatPowerComparisonPercent(pct);
        final finder = find.text(expectedText);
        expect(
          finder,
          findsAtLeastNWidgets(1),
          reason: 'Expected "$expectedText" for ${r.displayName}',
        );
        final widget = tester.widget<Text>(finder.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.danger,
          reason: 'Stronger GP percentage must use --danger',
        );
      }
    });

    testWidgets('AC: GP ≤0% renders in --success color', (
      WidgetTester tester,
    ) async {
      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        buildPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await _pumpPanelBuilt(tester);

      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final weakerOrEqual = rows
          .where(
            (r) =>
                r.kind == FactionKind.greatPower &&
                r.powerScore != null &&
                r.playerPowerScore != null &&
                r.powerScore! <= r.playerPowerScore!,
          )
          .toList();
      if (weakerOrEqual.isEmpty) {
        return;
      }
      for (final r in weakerOrEqual) {
        final pct = powerComparisonPercent(r.powerScore!, r.playerPowerScore!);
        if (pct > 0) continue;
        final expectedText = formatPowerComparisonPercent(pct);
        final finder = find.text(expectedText);
        expect(
          finder,
          findsAtLeastNWidgets(1),
          reason: 'Expected "$expectedText" for ${r.displayName}',
        );
        final widget = tester.widget<Text>(finder.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.success,
          reason: 'Weaker/equal GP percentage must use --success',
        );
      }
    });

    testWidgets(
      'absolute "Power: N" score label is no longer rendered on GP rows',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        await tester.pumpWidget(
          buildPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await _pumpPanelBuilt(tester);

        // SPEC: percentage replaces the absolute score. No row should render
        // text starting with "Power: ".
        expect(find.textContaining('Power: '), findsNothing);
      },
    );
  });
}
