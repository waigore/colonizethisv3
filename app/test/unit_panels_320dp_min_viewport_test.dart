// Pin the 320 dp minimum-viewport contract for the in-game unit panels
// (Civilian, Military, Naval) — extending the existing screen-, panel-,
// and dialog-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`) to the three Empire surfaces
// that mount the `UnitsPanelShell` chrome (`max-width: 400 dp`
// container with `padding: 8`).
//
// At `kMinViewportWidth` (320 dp) the shell collapses to a 320 dp host;
// the panel body becomes the available `304 dp` content column inside
// the 8-dp shell padding. The shared per-unit `UnitsEntityActionRow`
// already honours an inner `iconOnlyBreakpoint = 280 dp` so action
// buttons stay readable when the row body itself drops below that, but
// the panel chrome (title bar, region/location headers, list shell) has
// no separate narrow contract — these pins assert that the existing
// shell layout still pumps cleanly against the minimum viewport.
//
// Each test asserts:
//
//  * `WidgetTester.takeException()` is `null` so no `RenderFlex` overflow
//    exception (which Flutter surfaces via `FlutterError.onError`) escapes
//    the framework — the contract the existing screen- and panel-level
//    pin files rely on.
//  * Each panel's title text still renders end-to-end so the responsive
//    layout actually exercises the panel body at 320 dp rather than
//    no-op'ing.
//  * A wide negative control at 1024 × 768 dp pumps without exception
//    against the same fixture so a regression in the overflow contract
//    upstream of the panel itself would be caught.
//
// `NavalUnitsPanel` further requires the bundled nine-patch image asset
// to be pre-warmed into the Flame image cache so the `FleetExpansionTile`
// chrome (which wraps `CtNinePatchButton` actions) lays out at its true
// declared height instead of falling back to a `SizedBox.shrink()`
// silhouette. This file mirrors the existing pre-warm pattern from
// `panels_320dp_min_viewport_test.dart` (DiplomacyPanel group) so the
// naval pin renders against the same asset surface as
// `naval_units_panel_test_part1`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/civilian-units-panel.md`, `SPEC/ui/military-units-panel.md`,
//        `SPEC/ui/naval-units-panel.md`.
// Refs #2870 S10.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';

import 'support/min_viewport_harness.dart';
import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same panel renders its default layout. Mirrors
/// the contract used by `panels_320dp_min_viewport_test.dart` and
/// `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [child] (hosted in a [Scaffold]) at [size] via the shared
/// min-viewport harness ([pumpAtMinViewport]).
///
/// The harness wraps the tree in a [ProviderScope] so Civilian-side
/// `Consumer*` widgets and provider reads inside the panel resolve to a
/// deterministic (empty) default; the contract under test is the panel
/// chrome at the narrow viewport, not the panel's full assign-work
/// behaviour (which is already covered by the dedicated
/// `*_units_panel_test_part*` files).
Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    child: Scaffold(body: child),
    settle: true,
  );
}

Widget _buildCivilianUnitsPanel({
  required Game game,
  required String humanPlayerId,
}) {
  return CivilianUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
  );
}

Widget _buildMilitaryUnitsPanel({
  required Game game,
  required String humanPlayerId,
}) {
  return MilitaryUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
    topology: const MapTopology(),
    draftOrders: const Orders(),
  );
}

Widget _buildNavalUnitsPanel({
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
}) {
  return NavalUnitsPanel(
    game: game,
    humanPlayerId: humanPlayerId,
    bus: AppEventBus.create(),
    topology: topology,
  );
}

void main() {
  suppressLogsForTests();

  late Game game;
  late MapTopology topology;
  late String humanPlayerId;

  setUpAll(() async {
    await preloadNinePatchImage();
    // Refs #3656: a shared lightweight fixture (civilians + army/regiments +
    // home/non-home fleets in both regions) replaces the ~11s
    // `getDebugInitGameResult()` map generation. These pins assert chrome only
    // (no overflow + title text), so an empty `MapTopology` is sufficient.
    game = buildUnitPanelsTestGame();
    topology = const MapTopology();
    expect(
      game.players,
      isNotEmpty,
      reason:
          'Fixture must seed at least one player so the panels '
          'render a meaningful unit list at 320 dp.',
    );
    humanPlayerId = game.players.first.id;
  });

  setUp(() => AppEventBus.reset());

  group('SPEC/ui/mobile-adaptation.md § 7 — CivilianUnitsPanel @ 320 dp '
      '(Refs #2870 S10)', () {
    testWidgets('AC (positive) CivilianUnitsPanel @ 320×640: no RenderFlex '
        'overflow exception, "Civilian Units" title renders', (
      WidgetTester tester,
    ) async {
      await _pumpNarrow(
        tester,
        _buildCivilianUnitsPanel(game: game, humanPlayerId: humanPlayerId),
        size: _kMinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: CivilianUnitsPanel must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The UnitsPanelShell chrome '
            '(CtTopBar + ListView) and per-unit UnitsEntityActionRow '
            'must fit within the 304 dp content column inside the '
            'shell padding without overflowing.',
      );
      expect(find.text('Civilian Units'), findsOneWidget);
    });

    testWidgets('Negative control: CivilianUnitsPanel @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)', (
      WidgetTester tester,
    ) async {
      await _pumpNarrow(
        tester,
        _buildCivilianUnitsPanel(game: game, humanPlayerId: humanPlayerId),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Civilian Units'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — MilitaryUnitsPanel @ 320 dp '
      '(Refs #2870 S10)', () {
    testWidgets('AC (positive) MilitaryUnitsPanel @ 320×640: no RenderFlex '
        'overflow exception, "Military Units" title renders', (
      WidgetTester tester,
    ) async {
      await _pumpNarrow(
        tester,
        _buildMilitaryUnitsPanel(game: game, humanPlayerId: humanPlayerId),
        size: _kMinViewport,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: MilitaryUnitsPanel must '
            'not emit a RenderFlex overflow exception at '
            'kMinViewportWidth (320 dp). The UnitsPanelShell chrome '
            '(CtTopBar + ListView), Army ExpansionTile rows, and per-'
            'army UnitsEntityActionRow must fit within the 304 dp '
            'content column inside the shell padding without '
            'overflowing.',
      );
      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets('Negative control: MilitaryUnitsPanel @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract)', (WidgetTester tester) async {
      await _pumpNarrow(
        tester,
        _buildMilitaryUnitsPanel(game: game, humanPlayerId: humanPlayerId),
        size: _kWideRegressionViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Military Units'), findsOneWidget);
    });
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — NavalUnitsPanel @ 320 dp '
      '(Refs #2870 S10)', () {
    testWidgets(
      'AC (positive) NavalUnitsPanel @ 320×640: no RenderFlex overflow '
      'exception, "Naval Units" title renders',
      (WidgetTester tester) async {
        await _pumpNarrow(
          tester,
          _buildNavalUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
          size: _kMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: NavalUnitsPanel must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The UnitsPanelShell chrome (CtTopBar with header '
              'Combine + select-all checkbox + ListView), Fleet '
              'ExpansionTile rows, and per-fleet UnitsEntityActionRow '
              'must fit within the 304 dp content column inside the '
              'shell padding without overflowing.',
        );
        expect(find.text('Naval Units'), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: NavalUnitsPanel @ 1024×768 also pumps without '
      'exception (regression sentinel for the overflow contract — keeps '
      'the 320 dp positive pin meaningful)',
      (WidgetTester tester) async {
        await _pumpNarrow(
          tester,
          _buildNavalUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
          size: _kWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Naval Units'), findsOneWidget);
      },
    );
  });
}
