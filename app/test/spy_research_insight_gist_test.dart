// Spy research-insight gist on MAP20001 / UNIT10001 (Refs #4679).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md, SPEC/ui/civilian-units-panel.md

import 'package:colonizethis_app/features/game/widgets/units/civilian/spy_research_insight_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';
import 'panel_fixtures/core.dart';

const _human = 'h1';
const _rival = 'gp2';
const _rivalTile = 'oldWorld|p2|0|0';
const _minorTile = 'oldWorld|p3|0|0';

Game _stationSpyTargetGame({required bool minorNation}) {
  return buildPanelTestGame(
    id: minorNation ? 'g_spy_minor' : 'g_spy_rival',
    players: [
      Player(id: _human, displayName: 'Human', isHuman: true),
      if (!minorNation)
        Player(id: _rival, displayName: 'Rival', isHuman: false),
    ],
    minorNations: minorNation
        ? const [MinorNation(id: 'minor1', displayName: 'Minor')]
        : const [],
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
        ownerId: minorNation ? 'minor1' : _rival,
      ),
      if (minorNation)
        Province(
          id: 'oldWorld|p3',
          regionId: 'oldWorld',
          displayName: 'Minor Land',
          ownerId: 'minor1',
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
    ],
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('UNIT10001 Spy status (Refs #4679)', () {
    testWidgets('rival GP foreign post includes may-speed-research clause', (
      tester,
    ) async {
      final game = buildCivilianSpyFixtureGame(
        id: 'g_spy_status_rival',
        foreignStation: true,
      );
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: _human),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Holding intel:'), findsOneWidget);
      expect(find.textContaining('may speed research'), findsOneWidget);
    });

    testWidgets('minor nation foreign post omits research clause', (
      tester,
    ) async {
      final game = buildPanelTestGame(
        id: 'g_spy_status_minor',
        players: [Player(id: _human, displayName: 'Human', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
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
            displayName: 'Minor Land',
            ownerId: 'minor1',
          ),
        ],
        oldWorldUnits: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: _human,
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|0|0',
          ),
        ],
      );
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: _human),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Holding intel:'), findsOneWidget);
      expect(find.textContaining('may speed research'), findsNothing);
    });
  });

  group('UNIT10001 Relocate shortcut gist (Refs #4679)', () {
    testWidgets('rival GP shortcut shows research gist', (tester) async {
      final game = _stationSpyTargetGame(minorNation: false);
      await tester.pumpWidget(
        buildCivilianPanel(
          game: game,
          humanPlayerId: _human,
          spyOnly: true,
          relocateShortcutTargetTileKey: _rivalTile,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kSpyResearchInsightGistKey), findsOneWidget);
      expect(
        find.text(l10n.spyResearchInsight_maySpeedResearchGist),
        findsOneWidget,
      );
    });

    testWidgets('minor nation shortcut omits research gist', (tester) async {
      final game = _stationSpyTargetGame(minorNation: true);
      await tester.pumpWidget(
        buildCivilianPanel(
          game: game,
          humanPlayerId: _human,
          spyOnly: true,
          relocateShortcutTargetTileKey: _minorTile,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kSpyResearchInsightGistKey), findsNothing);
    });
  });
}
