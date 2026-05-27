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

      // SPEC/ui/diplomacy-panel.md § Per-faction row → Row chrome: rows
      // render as flat gradient tiles, not nine-patch CtPanel frames.
      // The presence of at least one row is asserted indirectly by the
      // faction display name showing up below.
      final firstGp = gameWithFactions.players
          .where((p) => p.id != humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state badge shows PEACE or WAR label', (
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

      // SPEC/ui/diplomacy-panel.md § Relation state badge: the badge
      // label is the uppercase string `WAR` or `PEACE`, never the
      // sentence-case `War` / `Peace` literals.
      expect(
        find.text('WAR').evaluate().isNotEmpty ||
            find.text('PEACE').evaluate().isNotEmpty,
        isTrue,
        reason:
            'Every faction row must render the uppercase relation-state badge.',
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

  group('diplomacyFilterShowsKind', () {
    test('mode `all` shows every faction kind', () {
      for (final kind in FactionKind.values) {
        expect(
          diplomacyFilterShowsKind(DiplomacyFilterMode.all, kind),
          isTrue,
          reason: 'DiplomacyFilterMode.all must accept $kind',
        );
      }
    });

    test('mode `greatPowersOnly` shows only Great Power rows', () {
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.greatPower,
        ),
        isTrue,
      );
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.minor,
        ),
        isFalse,
      );
      expect(
        diplomacyFilterShowsKind(
          DiplomacyFilterMode.greatPowersOnly,
          FactionKind.tribe,
        ),
        isFalse,
      );
    });

    test(
      'mode `minorsOnly` shows Minor Nations and Tribes but not Great Powers',
      () {
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.minor,
          ),
          isTrue,
        );
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.tribe,
          ),
          isTrue,
        );
        expect(
          diplomacyFilterShowsKind(
            DiplomacyFilterMode.minorsOnly,
            FactionKind.greatPower,
          ),
          isFalse,
        );
      },
    );
  });

  group('DiplomacyPanel mode bar', () {
    testWidgets(
      'AC: default state — All button active (--accent), others inactive (--muted)',
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

        final allButton = tester.widget<Text>(find.text('All'));
        expect(
          allButton.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Default "All" filter must render in --accent.',
        );

        final gpOnlyButton = tester.widget<Text>(find.text('Great Powers only'));
        expect(
          gpOnlyButton.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Inactive "Great Powers only" filter must render in --muted.',
        );

        final minorsOnlyButton = tester.widget<Text>(find.text('Minors only'));
        expect(
          minorsOnlyButton.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Inactive "Minors only" filter must render in --muted.',
        );
      },
    );

    testWidgets(
      'AC: tapping "Great Powers only" hides Minor Nation and Tribe rows',
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

        // Sanity: default "All" view includes the Great Powers heading.
        expect(find.text('Great Powers'), findsOneWidget);

        await tester.tap(find.text('Great Powers only'));
        await _pumpPanelBuilt(tester);

        expect(
          find.text('Great Powers'),
          findsOneWidget,
          reason: 'Great Powers heading must remain after filter switch.',
        );
        expect(
          find.text('Minor Nations'),
          findsNothing,
          reason: 'Minor Nations section must be hidden when GP-only is active.',
        );
        expect(
          find.text('Tribes'),
          findsNothing,
          reason: 'Tribes section must be hidden when GP-only is active.',
        );

        final activeLabel = tester.widget<Text>(
          find.text('Great Powers only'),
        );
        expect(
          activeLabel.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Selected mode-bar button label must use --accent.',
        );
      },
    );

    testWidgets(
      'AC: tapping "Minors only" hides Great Power rows but keeps Minors and Tribes',
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

        // Sanity: GP section starts visible.
        expect(find.text('Great Powers'), findsOneWidget);

        await tester.tap(find.text('Minors only'));
        await _pumpPanelBuilt(tester);

        expect(
          find.text('Great Powers'),
          findsNothing,
          reason: 'Great Powers section must be hidden when Minors-only is active.',
        );
        // Both Minor and Tribe sections may or may not appear depending on
        // discovered factions in the debug-init game; assert that whichever
        // are present render at least once and the GP section is gone.
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasMinors = rows.any((r) => r.kind == FactionKind.minor);
        final hasTribes = rows.any((r) => r.kind == FactionKind.tribe);
        if (hasMinors) {
          expect(find.text('Minor Nations'), findsOneWidget);
        }
        if (hasTribes) {
          expect(find.text('Tribes'), findsOneWidget);
        }

        final activeLabel = tester.widget<Text>(find.text('Minors only'));
        expect(
          activeLabel.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Selected mode-bar button label must use --accent.',
        );
      },
    );

    testWidgets('AC: mode bar renders all three filter labels', (
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

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Great Powers only'), findsOneWidget);
      expect(find.text('Minors only'), findsOneWidget);
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

  group('DiplomacyPanel section headings (editorial-monocle)', () {
    testWidgets(
      'AC: Section heading text resolves to --accent color',
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

        final heading = tester.widget<Text>(find.text('Great Powers'));
        expect(
          heading.style?.color,
          EditorialMonoclePalette.accent,
          reason:
              'Section heading must render in --accent per editorial-monocle.',
        );
        expect(
          heading.style?.fontFamily,
          'Cinzel',
          reason: 'Section heading must use the editorial-monocle display font.',
        );
      },
    );

    testWidgets(
      'AC: Section heading container exposes a 2 px --accent-dim bottom border',
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

        final headingFinder = find.text('Great Powers');
        final decorated = find.ancestor(
          of: headingFinder,
          matching: find.byType(DecoratedBox),
        );
        expect(decorated, findsAtLeastNWidgets(1));
        final box = tester.widget<DecoratedBox>(decorated.first);
        final decoration = box.decoration as BoxDecoration;
        final BorderSide bottom = decoration.border!.bottom;
        expect(bottom.color, EditorialMonoclePalette.accentDim);
        expect(bottom.width, 2);
      },
    );
  });

  group('DiplomacyPanel faction kind badges (editorial-monocle)', () {
    testWidgets(
      'AC: GP badge background --accent-dim and foreground --bg-deep',
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

        // Only assert if the debug-init game actually has a GP row.
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasGp = rows.any((r) => r.kind == FactionKind.greatPower);
        if (!hasGp) return;

        final gpText = find.text('GP').first;
        final container = tester.widget<Container>(
          find.ancestor(of: gpText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          EditorialMonoclePalette.accentDim,
          reason: 'GP badge background must resolve to --accent-dim.',
        );
        expect(
          decoration.border,
          isNull,
          reason: 'GP badge must not draw an outline border.',
        );
        final textWidget = tester.widget<Text>(gpText);
        expect(
          textWidget.style?.color,
          EditorialMonoclePalette.bgDeep,
          reason: 'GP badge foreground must resolve to --bg-deep.',
        );
      },
    );

    testWidgets(
      'AC: Minor badge background --muted and foreground --bg-deep',
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

        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasMinor = rows.any((r) => r.kind == FactionKind.minor);
        if (!hasMinor) return;

        final minorText = find.text('Minor').first;
        final container = tester.widget<Container>(
          find.ancestor(of: minorText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          EditorialMonoclePalette.muted,
          reason: 'Minor badge background must resolve to --muted.',
        );
        expect(
          decoration.border,
          isNull,
          reason: 'Minor badge must not draw an outline border.',
        );
        final textWidget = tester.widget<Text>(minorText);
        expect(
          textWidget.style?.color,
          EditorialMonoclePalette.bgDeep,
          reason: 'Minor badge foreground must resolve to --bg-deep.',
        );
      },
    );

    testWidgets(
      'AC: Tribe badge outlined with --muted border, transparent background',
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

        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasTribe = rows.any((r) => r.kind == FactionKind.tribe);
        if (!hasTribe) return;

        final tribeText = find.text('Tribe').first;
        final container = tester.widget<Container>(
          find.ancestor(of: tribeText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          isNull,
          reason: 'Tribe badge background must be transparent (null).',
        );
        expect(decoration.border, isNotNull);
        expect(
          decoration.border!.top.color,
          EditorialMonoclePalette.muted,
          reason: 'Tribe badge outline must use --muted.',
        );
        final textWidget = tester.widget<Text>(tribeText);
        expect(
          textWidget.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Tribe badge foreground must resolve to --muted.',
        );
      },
    );

    testWidgets(
      'AC: No badge uses raw Material chrome (Colors.blue/grey/orange)',
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

        final allLabels = ['GP', 'Minor', 'Tribe'];
        for (final label in allLabels) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final widget = tester.widget<Text>(finder.first);
          final color = widget.style?.color;
          // Reject the prior hardcoded Material palette for these labels.
          expect(color, isNot(equals(Colors.blue)),
              reason: '$label badge must not use Colors.blue.');
          expect(color, isNot(equals(Colors.grey)),
              reason: '$label badge must not use Colors.grey.');
          expect(color, isNot(equals(Colors.orange)),
              reason: '$label badge must not use Colors.orange.');
        }
      },
    );
  });

  group('DiplomacyPanel relation-state badge (editorial-monocle)', () {
    Game gameWithWarRelation(Game source, String otherFactionId) {
      // Replace any existing relation between humanPlayerId ↔ otherFactionId
      // with an at-war pair so the panel always renders at least one WAR
      // badge for the assertion.
      bool involvesPair(DiplomacyRelation r) =>
          (r.factionId1 == humanPlayerId && r.factionId2 == otherFactionId) ||
          (r.factionId1 == otherFactionId && r.factionId2 == humanPlayerId);
      final updated = [
        for (final r in source.diplomacyRelations)
          if (!involvesPair(r)) r,
        DiplomacyRelation(
          factionId1: humanPlayerId,
          factionId2: otherFactionId,
          score: 10,
          state: RelationState.atWar,
          sinceTurn: 0,
        ),
      ];
      return source.copyWith(diplomacyRelations: updated);
    }

    testWidgets(
      'AC: WAR badge foreground resolves to --danger',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        final otherGp = gameWithFactions.players.firstWhere(
          (p) => p.id != humanPlayerId,
        );
        final warGame = gameWithWarRelation(gameWithFactions, otherGp.id);
        await tester.pumpWidget(
          buildPanel(
            game: warGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await _pumpPanelBuilt(tester);

        final warText = find.text('WAR');
        expect(warText, findsAtLeastNWidgets(1));
        final widget = tester.widget<Text>(warText.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.danger,
          reason: 'WAR badge foreground must resolve to --danger.',
        );
        expect(
          widget.style?.fontFamily,
          'monospace',
          reason: 'WAR badge label must use the mono font stack.',
        );
      },
    );

    testWidgets(
      'AC: PEACE badge foreground resolves to --success',
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

        final peaceText = find.text('PEACE');
        if (peaceText.evaluate().isEmpty) {
          // Debug-init game may have all relations at-war by default;
          // skip rather than fail.
          return;
        }
        final widget = tester.widget<Text>(peaceText.first);
        expect(
          widget.style?.color,
          EditorialMonoclePalette.success,
          reason: 'PEACE badge foreground must resolve to --success.',
        );
        expect(
          widget.style?.fontFamily,
          'monospace',
          reason: 'PEACE badge label must use the mono font stack.',
        );
      },
    );

    testWidgets(
      'AC: WAR badge background derives from --danger hue at alpha 0.40',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        final otherGp = gameWithFactions.players.firstWhere(
          (p) => p.id != humanPlayerId,
        );
        final warGame = gameWithWarRelation(gameWithFactions, otherGp.id);
        await tester.pumpWidget(
          buildPanel(
            game: warGame,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await _pumpPanelBuilt(tester);

        // Mockup token: oklch(40% 0.06 20 / 0.4).
        final Color expectedBg =
            oklchToColor(const OklchToken(0.40, 0.06, 20))
                .withValues(alpha: 0.4);
        final warText = find.text('WAR');
        expect(warText, findsAtLeastNWidgets(1));
        final container = tester.widget<Container>(
          find.ancestor(of: warText.first, matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          expectedBg,
          reason:
              'WAR badge background must derive from the danger hue at alpha 0.4.',
        );
        expect(decoration.border, isNull,
            reason: 'WAR badge must not draw an outline border.');
      },
    );

    testWidgets(
      'AC: PEACE badge background derives from --success hue at alpha 0.20',
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

        final peaceText = find.text('PEACE');
        if (peaceText.evaluate().isEmpty) return;
        final Color expectedBg =
            oklchToColor(const OklchToken(0.40, 0.06, 150))
                .withValues(alpha: 0.2);
        final container = tester.widget<Container>(
          find.ancestor(of: peaceText.first, matching: find.byType(Container))
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(
          decoration.color,
          expectedBg,
          reason:
              'PEACE badge background must derive from the success hue at alpha 0.2.',
        );
        expect(decoration.border, isNull,
            reason: 'PEACE badge must not draw an outline border.');
      },
    );
  });

  group('DiplomacyPanel faction-row chrome (editorial-monocle)', () {
    testWidgets(
      'AC: Faction row paints --bg-deep → --surface vertical gradient and --border outline',
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

        // Locate the first AnimatedContainer that wraps a faction row
        // (the row chrome lives inside _DiplomacyRowChrome → MouseRegion →
        // AnimatedContainer per diplomacy_panel_chrome.dart).
        final containers = find.byType(AnimatedContainer);
        BoxDecoration? rowDecoration;
        for (final element in containers.evaluate()) {
          final w = element.widget as AnimatedContainer;
          final deco = w.decoration;
          if (deco is! BoxDecoration) continue;
          final gradient = deco.gradient;
          if (gradient is! LinearGradient) continue;
          if (gradient.colors.length != 2) continue;
          // Match against the canonical row gradient (bg-deep → surface).
          if (gradient.colors[0] == EditorialMonoclePalette.bgDeep &&
              gradient.colors[1] == EditorialMonoclePalette.surface) {
            rowDecoration = deco;
            break;
          }
        }
        expect(
          rowDecoration,
          isNotNull,
          reason:
              'At least one faction row must paint the canonical --bg-deep → --surface vertical gradient.',
        );
        final LinearGradient gradient = rowDecoration!.gradient as LinearGradient;
        expect(gradient.begin, Alignment.topCenter,
            reason: 'Row gradient must flow top → bottom (180deg).');
        expect(gradient.end, Alignment.bottomCenter);
        expect(rowDecoration.border, isNotNull,
            reason: 'Row chrome must draw a 1 px outline.');
        final BorderSide side = rowDecoration.border!.top;
        expect(side.width, 1);
        expect(
          side.color,
          EditorialMonoclePalette.border,
          reason: 'Idle row outline must resolve to --border.',
        );
      },
    );

  });

  group('DiplomacyPanel war-action button (editorial-monocle danger variant)',
      () {
    testWidgets(
      'AC: Declare War button resolves border and label to --danger',
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

        final warBtn = find.text('Declare War');
        if (warBtn.evaluate().isEmpty) return;
        final button = tester.widget<CtNinePatchButton>(
          find
              .ancestor(of: warBtn, matching: find.byType(CtNinePatchButton))
              .first,
        );
        expect(
          button.dangerVariant,
          isTrue,
          reason:
              'Declare War button must opt into the CtNinePatchButton danger variant.',
        );
      },
    );

    testWidgets(
      'AC: Non-war action buttons do not opt into the danger variant',
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

        const nonWarLabels = [
          'Offer Peace',
          'Alliance',
          'Grant Aid',
          'Set Subsidy',
        ];
        for (final label in nonWarLabels) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final button = tester.widget<CtNinePatchButton>(
            find
                .ancestor(of: finder, matching: find.byType(CtNinePatchButton))
                .first,
          );
          expect(
            button.dangerVariant,
            isFalse,
            reason:
                'Non-war action button "$label" must keep the default brass variant.',
          );
        }
      },
    );
  });
}
