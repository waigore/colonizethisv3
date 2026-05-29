// Widget tests for the diplomacy faction-row responsive layout pinning
// SPEC/ui/diplomacy-panel.md § Responsive layout (Refs #2870 S5).
//
// Pins the wide (> 500 dp) Row layout and the narrow (≤ 500 dp) Column
// layout selected via [kDiplomacyRowNarrowMaxWidth] and surfaced through
// the public `kDiplomacyRowBodyKeyPrefix`-tagged body key.

import 'dart:ui' as ui;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

Future<void> _preWarmFlameImageCache() async {
  try {
    final bytes = await rootBundle.load(
      'assets/images/ui_button_nine_patch.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    Flame.images.add('ui_button_nine_patch.png', frame.image);
  } catch (_) {
    // Best-effort: existing diplomacy tests tolerate a missing nine-patch
    // bundle. Layout assertions here do not require pixel-perfect chrome.
  }
}

Future<void> _pumpPanelBuilt(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Widget _wrapPanel({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required Size viewportSize,
}) {
  final bus = AppEventBus.create();
  // Explicit MediaQuery inside the MaterialApp pins the viewport size that
  // `MediaQuery.sizeOf(context).width` reads in `_DiplomacyRow.build`,
  // mirroring the pattern in `screen_spec_acceptance_test.dart` and
  // `game_screen_narrow_test.dart` for narrow-viewport widget tests.
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: viewportSize),
      child: Scaffold(
        body: DiplomacyPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: const Orders(),
          bus: bus,
        ),
      ),
    ),
  );
}

/// Wide test surface so unrelated wide-only chrome (e.g. the mode-bar Row)
/// always fits without overflowing the render flex; the narrow-vs-wide
/// behaviour we pin is driven by the `MediaQuery(size: viewportSize)`
/// override injected by [_wrapPanel], not by the surface itself.
Future<void> _bindStandardSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(900, 1600));
}

void main() {
  suppressLogsForTests();

  late Game game;
  late MapTopology topology;
  late String humanPlayerId;
  late String firstNonHumanFactionId;

  setUp(() => AppEventBus.reset());

  setUpAll(() async {
    await _preWarmFlameImageCache();
    final result = getDebugInitGameResult();
    game = result.game;
    topology = result.combinedTopology;
    humanPlayerId = game.players.isNotEmpty ? game.players.first.id : 'gp1';

    // Pick the first GP/minor/tribe id that the human player has discovered
    // through the diplomacy view — this is the row whose key/layout we pin.
    final rows = buildDiplomacyRows(
      game,
      topology,
      humanPlayerId,
      const Orders(),
    );
    expect(
      rows,
      isNotEmpty,
      reason: 'Debug init game must seed at least one discovered faction.',
    );
    firstNonHumanFactionId = rows.first.factionId;
  });

  group('DiplomacyPanel responsive layout (Refs #2870 S5)', () {
    testWidgets(
      'narrow boundary 500 dp: faction row body uses Column (info above '
      'actions, leading-aligned)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
            viewportSize: Size(kDiplomacyRowNarrowMaxWidth, 1200),
          ),
        );
        await _pumpPanelBuilt(tester);

        final Key bodyKey = ValueKey(
          '$kDiplomacyRowBodyKeyPrefix$firstNonHumanFactionId',
        );
        expect(
          find.byKey(bodyKey),
          findsOneWidget,
          reason: 'Body key must be attached to the variant-selected widget.',
        );
        final Widget body = tester.widget(find.byKey(bodyKey));
        expect(
          body,
          isA<Column>(),
          reason:
              'At viewport width ≤ kDiplomacyRowNarrowMaxWidth (= 500 dp), '
              'SPEC/ui/diplomacy-panel.md § Responsive layout selects the '
              'narrow Column body so action buttons drop below the info '
              'column.',
        );

        // Leading-aligned: the Column's crossAxisAlignment must be start so
        // info text and the trailing actions Align widget both sit at the
        // left edge.
        final Column column = body as Column;
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);

        // Narrow body wraps the action cluster in Align(centerLeft, ...) per
        // SPEC/ui/diplomacy-panel.md § Responsive layout. Verify at least
        // one Align with leading alignment is rendered within the body.
        final Finder leadingAligns = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Align && w.alignment == Alignment.centerLeft,
            description: 'leading-aligned Align widget',
          ),
        );
        expect(leadingAligns, findsWidgets);
      },
    );

    testWidgets(
      'narrow 480 dp: row body does NOT use the wide Row(Expanded info, '
      'actions) arrangement',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
            viewportSize: const Size(480, 1200),
          ),
        );
        await _pumpPanelBuilt(tester);

        final Key bodyKey = ValueKey(
          '$kDiplomacyRowBodyKeyPrefix$firstNonHumanFactionId',
        );
        final Widget body = tester.widget(find.byKey(bodyKey));
        expect(
          body,
          isNot(isA<Row>()),
          reason:
              'At viewport width 480 dp (≤ kDiplomacyRowNarrowMaxWidth), '
              'SPEC/ui/diplomacy-panel.md § Faction row narrow does not '
              'right-align actions: the wide Row pattern must not be used.',
        );

        // Defensive: no Expanded should sit directly under the narrow body
        // either (the narrow body has no need to flex info; it stacks).
        final Finder expandedUnderBody = find.descendant(
          of: find.byKey(bodyKey),
          matching: find.byType(Expanded),
        );
        expect(expandedUnderBody, findsNothing);
      },
    );

    testWidgets(
      'wide 800 dp: faction row body uses Row(Expanded info, action cluster)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
            viewportSize: const Size(800, 1200),
          ),
        );
        await _pumpPanelBuilt(tester);

        final Key bodyKey = ValueKey(
          '$kDiplomacyRowBodyKeyPrefix$firstNonHumanFactionId',
        );
        final Widget body = tester.widget(find.byKey(bodyKey));
        expect(
          body,
          isA<Row>(),
          reason:
              'At viewport width 800 dp (> kDiplomacyRowNarrowMaxWidth), '
              'SPEC/ui/diplomacy-panel.md § Faction row wide layout selects '
              'the Row body (Expanded info + trailing action cluster).',
        );

        // The wide body's first child is an Expanded carrying the info
        // column, then a sibling action cluster — pin both contracts.
        final Row row = body as Row;
        expect(row.crossAxisAlignment, CrossAxisAlignment.start);
        expect(row.children, isNotEmpty);
        expect(row.children.first, isA<Expanded>());
      },
    );

    testWidgets(
      'wide 600 dp: at least one Expanded sits directly inside the row body '
      '(wide info-column flex contract)',
      (WidgetTester tester) async {
        await _bindStandardSurface(tester);
        await tester.pumpWidget(
          _wrapPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
            viewportSize: const Size(600, 1200),
          ),
        );
        await _pumpPanelBuilt(tester);

        final Key bodyKey = ValueKey(
          '$kDiplomacyRowBodyKeyPrefix$firstNonHumanFactionId',
        );
        expect(
          find.descendant(
            of: find.byKey(bodyKey),
            matching: find.byType(Expanded),
          ),
          findsWidgets,
          reason:
              'Wide variant must keep the info column inside Expanded so the '
              'action cluster can sit on the trailing edge.',
        );
      },
    );
  });

  group('kDiplomacyRowNarrowMaxWidth', () {
    test('constant value pins the SPEC ≤ 500 dp diplomacy breakpoint', () {
      // SPEC/ui/diplomacy-panel.md § Responsive layout and
      // SPEC/ui/mobile-adaptation.md § 4 both cite 500 dp; the constant is
      // the single source the implementation reads from.
      expect(kDiplomacyRowNarrowMaxWidth, 500.0);
    });
  });
}
