// Widget golden coverage for the three in-game unit panels — UNIT10001
// (Civilian), UNIT20001 (Military), UNIT30001 (Naval) — closing the final
// golden acceptance criterion of issue #3514 (align unit-panel visual chrome
// with the HTML mockups). Each panel renders against `AppThemes.editorialMonocle`
// from the committed seed-42 serialized fixtures (`loadSeed42Game()` +
// `loadSeed42MapViewData().combinedTopology`) at the canonical test host
// viewport and is captured via a keyed `RepaintBoundary`, following the
// committed golden harness pattern
// (`province_build_improvement_shortcut_host_goldens_test.dart`,
// `new_game_leader_selection_dialog_golden_test.dart`). Each golden is paired
// with structural finder assertions so the baseline keeps mapping to its
// screen (and to the post-#3514 mockup chrome) rather than silently drifting.
//
// Refs #3656: the panels render unit/fleet lists and the combined topology
// only (no per-cell tile/resource data), all of which are cross-process stable,
// so loading the committed seed-42 fixtures keeps the baselines byte-identical
// while dropping the ~7-11s `getDebugInitGameResult()` map generation per file.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_card.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'game_fixture.dart';
import 'golden_capture_harness.dart';
import 'map_view_fixture.dart';

/// Canonical golden host viewport for the unit panels (wide enough for the
/// mockup row chrome without horizontal overflow at the panel constraint).
const Size _hostViewport = Size(440, 820);

/// Panel sizing applied inside the host for every golden so the three captures
/// share one set of constraints (issue #3514 owner decision #3 — aligned
/// sizing rules across all three panels).
const BoxConstraints _panelConstraints = BoxConstraints(
  maxWidth: 400,
  maxHeight: 760,
);

Widget _host({required Key boundaryKey, required Widget child}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    wrapInProviderScope: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: ConstrainedBox(constraints: _panelConstraints, child: child),
  );
}

/// Mobile golden viewport (`360 × 640` dp) for the narrow sizing contract
/// (Refs #3627 AC6 / AC7). The panel is bound by the production narrow
/// constraints from `unitsPanelSheetConstraints` (full width × `50%` height)
/// so the committed mobile baselines exercise the same host sizing the
/// bottom-sheet openers apply on a phone-sized viewport.
const Size _mobileViewport = Size(360, 640);

/// Narrow host constraints derived from the shared sizing helper so the
/// mobile golden matches the in-app `50%` height / full-width contract.
final BoxConstraints _mobilePanelConstraints = unitsPanelSheetConstraints(
  _mobileViewport,
);

Widget _mobileHost({required Key boundaryKey, required Widget child}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    alignment: Alignment.bottomCenter,
    wrapInProviderScope: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: ConstrainedBox(
      constraints: _mobilePanelConstraints,
      child: child,
    ),
  );
}

void main() {
  suppressLogsForTests();

  late final Game game;
  late final String humanPlayerId;
  late final MapTopology combinedTopology;

  setUpAll(() {
    game = loadSeed42Game();
    combinedTopology = loadSeed42MapViewData().combinedTopology;
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  Future<void> pumpHost(WidgetTester tester, Widget panel, Key key) async {
    await configureGoldenSurface(tester, size: _hostViewport);
    await tester.pumpWidget(_host(boundaryKey: key, child: panel));
    await pumpForGolden(tester);
  }

  Future<void> pumpMobileHost(
    WidgetTester tester,
    Widget panel,
    Key key,
  ) async {
    await configureGoldenSurface(tester, size: _mobileViewport);
    await tester.pumpWidget(_mobileHost(boundaryKey: key, child: panel));
    await pumpForGolden(tester);
  }

  testWidgets('golden: UNIT10001 Civilian Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_civilian_golden');
    await pumpHost(
      tester,
      CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_civilian_default.png'),
    );
  });

  testWidgets('golden: UNIT20001 Military Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_military_golden');
    await pumpHost(
      tester,
      MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
        draftOrders: const Orders(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_military_default.png'),
    );
  });

  testWidgets('golden: UNIT30001 Naval Units panel chrome (Refs #3514)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_naval_golden');
    await pumpHost(
      tester,
      NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
    // Naval fleet rows adopt the shared mockup `.fleet-row` card chrome
    // (issue #3514 AC-6); at least one card is present in the default fixture.
    expect(find.byType(UnitsEntityCard), findsWidgets);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_naval_default.png'),
    );
  });

  // Mobile (narrow) golden coverage — Refs #3627 AC6 / AC7. Each panel is
  // bound by the production narrow constraints (full width × 50% height) at a
  // 360 × 640 dp viewport so the committed baseline pins the fill-height
  // contract (AC3) and the narrow sizing rule together.
  testWidgets('golden: UNIT10001 Civilian Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_civilian_mobile_golden');
    await pumpMobileHost(
      tester,
      CivilianUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_civilian_mobile.png'),
    );
  });

  testWidgets('golden: UNIT20001 Military Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_military_mobile_golden');
    await pumpMobileHost(
      tester,
      MilitaryUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
        draftOrders: const Orders(),
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_military_mobile.png'),
    );
  });

  testWidgets('golden: UNIT30001 Naval Units panel mobile (Refs #3627)', (
    WidgetTester tester,
  ) async {
    const key = ValueKey('unit_panel_naval_mobile_golden');
    await pumpMobileHost(
      tester,
      NavalUnitsPanel(
        game: game,
        humanPlayerId: humanPlayerId,
        bus: AppEventBus.create(),
        topology: combinedTopology,
      ),
      key,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavalUnitsPanel), findsOneWidget);
    expect(find.byType(UnitsEntityCard), findsWidgets);
    expectEditorialMonocleDarkChrome(tester);

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/unit_panel_naval_mobile.png'),
    );
  });
}
