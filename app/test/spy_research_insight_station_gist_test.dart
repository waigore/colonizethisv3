// Spy research-insight station / already-grants gist (Refs #4679 / #4720 Slice F).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md, SPEC/ui/civilian-units-panel.md

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/spy_research_insight_gist_line.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'civilian_units_panel_test_support.dart';
import 'panel_fixtures/core.dart';

const _human = 'h1';
const _rival = 'gp2';
const _rivalTile = 'oldWorld|p2|0|0';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('MAP20001 Station spy gist (Refs #4679)', () {
    testWidgets('enabled control shows rival GP research gist', (tester) async {
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        buildAppShell(
          viewport: const Size(800, 640),
          child: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              stationSpy: (
                showControl: true,
                enabled: true,
                tooltip: l10n.provinceOverlay_stationSpyAction,
                gist: l10n.spyResearchInsight_maySpeedResearchGist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.spyResearchInsight_maySpeedResearchGist),
        findsOneWidget,
      );
    });

    testWidgets('enabled control shows already-grants-insight gist', (
      tester,
    ) async {
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        buildAppShell(
          viewport: const Size(800, 640),
          child: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              stationSpy: (
                showControl: true,
                enabled: true,
                tooltip: l10n.provinceOverlay_stationSpyAction,
                gist: l10n.spyResearchInsight_alreadyGrantsInsightGist,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.spyResearchInsight_alreadyGrantsInsightGist),
        findsOneWidget,
      );
    });

    testWidgets('enabled control omits gist on Minor Nation land', (
      tester,
    ) async {
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        buildAppShell(
          viewport: const Size(800, 640),
          child: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              stationSpy: (
                showControl: true,
                enabled: true,
                tooltip: l10n.provinceOverlay_stationSpyAction,
                gist: '',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kSpyResearchInsightGistKey), findsNothing);
    });
  });

  group('UNIT10001 Relocate already-grants gist (Refs #4679)', () {
    testWidgets(
      'rival GP shortcut shows already-grants gist when court posted',
      (tester) async {
        final game = buildPanelTestGame(
          id: 'g_spy_already_insight',
          players: [
            Player(id: _human, displayName: 'Human', isHuman: true),
            Player(id: _rival, displayName: 'Rival', isHuman: false),
          ],
          oldWorldProvinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              displayName: 'Home',
              ownerId: _human,
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              displayName: 'Rival Land',
              ownerId: _rival,
            ),
          ],
          oldWorldUnits: [
            Unit(
              id: 'spy1',
              type: kUnitTypeSpy,
              ownerId: _human,
              locationProvinceId: 'oldWorld|p1',
              tileKey: 'oldWorld|p1|0|0',
            ),
            Unit(
              id: 'spy2',
              type: kUnitTypeSpy,
              ownerId: _human,
              locationProvinceId: 'oldWorld|p2',
              tileKey: _rivalTile,
            ),
          ],
        );
        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: _human,
            spyOnly: true,
            relocateShortcutTargetTileKey: _rivalTile,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.spyResearchInsight_alreadyGrantsInsightGist),
          findsAtLeastNWidgets(1),
        );
      },
    );
  });
}
