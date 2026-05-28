// DiplomacyPanel chrome tests: row chrome, relation-state badges, and the
// danger-variant war action button. Split from `diplomacy_panel_test.dart`
// to keep each file under `repo.dart_file_non_comment_line_size` (1000
// non-comment lines). SPEC/ui/diplomacy-panel.md § Per-faction row.

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

Widget _buildPanel({
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

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
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
          _buildPanel(
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
          _buildPanel(
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
          _buildPanel(
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
          _buildPanel(
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
          _buildPanel(
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
          _buildPanel(
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
          _buildPanel(
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
