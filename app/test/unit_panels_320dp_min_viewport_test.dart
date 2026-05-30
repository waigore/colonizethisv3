// Pin the 320 dp minimum-viewport contract for the in-game unit panels
// (Civilian, Military) — extending the existing screen-, panel-, and
// dialog-level pins (`mobile_320dp_min_viewport_test.dart`,
// `panels_320dp_min_viewport_test.dart`,
// `dialogs_320dp_min_viewport_test.dart`) to two of the major Empire
// surfaces that mount the `UnitsPanelShell` chrome (`max-width: 400 dp`
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
// Naval units panel is **not** covered here: its row body depends on
// the bundled nine-patch image asset (see `naval_units_panel_test_part1`
// for the Flame image pre-warm dance) and a separate, sea-zone-shaped
// debug fixture; pinning it cleanly under the minimum viewport is a
// follow-up slice tracked on #2870 S10 alongside the existing naval
// regression tests.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// SPEC: `SPEC/ui/civilian-units-panel.md`, `SPEC/ui/military-units-panel.md`.
// Refs #2870 S10.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) mirrors the
/// existing screen-, panel-, and dialog-level pin files.
const Size _kMinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel — comfortably above every per-screen
/// breakpoint so the same panel renders its default layout. Mirrors
/// the contract used by `panels_320dp_min_viewport_test.dart` and
/// `dialogs_320dp_min_viewport_test.dart`.
const Size _kWideRegressionViewport = Size(1024, 768);

/// Pumps [child] at [size] under the running editorial-monocle theme.
///
/// Sets the surface size (so the binding's render flex math sees the
/// minimum viewport) and overrides MediaQuery so widget code that reads
/// `MediaQuery.sizeOf(context).width` resolves to the same value — the
/// pattern already used by the sibling 320 dp pin files.
///
/// Wraps [child] in a [ProviderScope] so Civilian-side `Consumer*`
/// widgets and provider reads inside the panel resolve to a deterministic
/// (empty) default; the contract under test is the panel chrome at the
/// narrow viewport, not the panel's full assign-work behaviour (which is
/// already covered by the dedicated `*_units_panel_test_part*` files).
Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    expect(
      game.players,
      isNotEmpty,
      reason: 'Debug init game must seed at least one player so the panels '
          'render a meaningful unit list at 320 dp.',
    );
    humanPlayerId = game.players.first.id;
  });

  setUp(() => AppEventBus.reset());

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — CivilianUnitsPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) CivilianUnitsPanel @ 320×640: no RenderFlex '
        'overflow exception, "Civilian Units" title renders',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildCivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
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
        },
      );

      testWidgets(
        'Negative control: CivilianUnitsPanel @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract — keeps the 320 dp positive pin meaningful)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildCivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Civilian Units'), findsOneWidget);
        },
      );
    },
  );

  group(
    'SPEC/ui/mobile-adaptation.md § 7 — MilitaryUnitsPanel @ 320 dp '
    '(Refs #2870 S10)',
    () {
      testWidgets(
        'AC (positive) MilitaryUnitsPanel @ 320×640: no RenderFlex '
        'overflow exception, "Military Units" title renders',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildMilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
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
        },
      );

      testWidgets(
        'Negative control: MilitaryUnitsPanel @ 1024×768 also pumps '
        'without exception (regression sentinel for the overflow '
        'contract)',
        (WidgetTester tester) async {
          await _pumpAtSize(
            tester,
            _buildMilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
            ),
            size: _kWideRegressionViewport,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Military Units'), findsOneWidget);
        },
      );
    },
  );
}
