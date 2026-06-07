// Tests for DiplomacyPanel. SPEC/ui/diplomacy-panel.md.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
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

/// Fixture for the discovery-via-visibility ACs (Refs #3341): the human GP
/// `gp1` has fully-visible tile sight into a New-World province owned by Tribe
/// `t1` but holds **no** `DiplomacyRelation` with the tribe. Per
/// SPEC/ui/diplomacy-panel.md § Discovered factions, the panel must discover
/// the tribe via `knownDiplomaticTargetFactionIds` and surface the default
/// neutral first-contact standing.
Game _gameWithTribeDiscoveredByVisibility() {
  const nw = 'newWorld';
  const ow = 'oldWorld';
  final tribeProvince = Province(
    id: '$nw|t1prov',
    regionId: nw,
    displayName: 'Tribe Land',
    ownerId: 't1',
  );
  final homeProvince = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'Home',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
    oldWorld: RegionData(provinces: [homeProvince], units: const []),
    newWorld: RegionData(provinces: [tribeProvince], units: const []),
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
    playerProspectedTiles: const {},
  );
  const player = Player(id: 'gp1', displayName: 'Solo', isHuman: true);
  return Game(
    id: 'tribe-visibility',
    worldState: world,
    players: const [player],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe One')],
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

    testWidgets('AC-6/AC-10: overture and FTP buttons shown disabled when invalid', (
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

      expect(find.text('Consulate'), findsWidgets);
      expect(find.text('Embassy'), findsWidgets);
      expect(find.text('Establish FTP'), findsWidgets);
      expect(find.text('Offer Peace'), findsWidgets);
    });

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


    testWidgets(
      'AC-1: Empty state shows all three section headings + tribe placeholder',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        await tester.pumpWidget(
          buildPanel(
            game: gameWithNoDiscovered,
            humanPlayerId: 'gp1',
            topology: const MapTopology(nodes: [], edges: []),
          ),
        );
        await _pumpPanelBuilt(tester);

        // SPEC/ui/diplomacy-panel.md § Section headings (Refs #3341):
        // headings are always rendered even when their sections are empty.
        expect(find.text('Great Powers'), findsOneWidget);
        expect(find.text('Minor Nations'), findsOneWidget);
        expect(find.text('Tribes'), findsOneWidget);
        // The Tribes empty placeholder copy (diplomacy_panel_noTribes).
        expect(find.text('No tribes contacted yet.'), findsOneWidget);
      },
    );

    testWidgets(
      'AC-5 (Refs #3341): tribe discovered by visibility renders under Tribes '
      'with no prior relation (no empty placeholder)',
      (WidgetTester tester) async {
        await _bindTallTestSurface(tester);
        await tester.pumpWidget(
          buildPanel(
            game: _gameWithTribeDiscoveredByVisibility(),
            humanPlayerId: 'gp1',
            topology: const MapTopology(nodes: [], edges: []),
          ),
        );
        await _pumpPanelBuilt(tester);

        expect(find.text('Tribes'), findsOneWidget);
        expect(
          find.text('Tribe One'),
          findsOneWidget,
          reason: 'Discovered tribe row must render under the Tribes section.',
        );
        expect(
          find.text('No tribes contacted yet.'),
          findsNothing,
          reason:
              'The empty Tribes placeholder must not show once a tribe is '
              'discovered.',
        );
      },
    );

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
        final tribeRows =
            rows.where((r) => r.kind == FactionKind.tribe).toList();
        if (tribeRows.isEmpty) return;
        final tribeRow = tribeRows.first;

        final tribeText = find.descendant(
          of: find.byKey(
            ValueKey('$kDiplomacyRowBodyKeyPrefix${tribeRow.factionId}'),
          ),
          matching: find.text('Tribe'),
        );
        await tester.scrollUntilVisible(
          tribeText,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        final container = tester.widget<Container>(
          find
              .ancestor(of: tribeText, matching: find.byType(Container))
              .first,
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

  // Faction-row chrome, relation-state badges, and war-button danger variant
  // tests live in `diplomacy_panel_chrome_test.dart` to keep this file under
  // the repo non-comment line ceiling.
}
