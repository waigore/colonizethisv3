import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'blockade_capital_link_ui_support.dart';
import 'naval_mission_goldens_test_support.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('navalMissionEffectLine (Refs #4516)', () {
    test('Blockade names capital-link cut and interception', () {
      final line = navalMissionEffectLine(l10n, FleetMission.blockade);
      expect(line.toLowerCase(), contains('capital'));
      expect(line.toLowerCase(), contains('warehouse'));
      expect(line.toLowerCase(), contains('intercept'));
    });

    test('target caption names warehouse cut', () {
      final caption = navalMissionTargetCaption(l10n, FleetMission.blockade);
      expect(caption, isNotNull);
      expect(caption!.toLowerCase(), contains('warehouse'));
    });
  });

  group('resolveHumanOwnedBlockadeStatus (Refs #4516)', () {
    test('human-owned blockaded port resolves portBlockaded', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionHumanOwnedBlockadedPortGame();
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.portBlockaded);
    });

    test('human-owned blockaded capital resolves capitalBlockaded', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionHumanOwnedBlockadedPortGame(
        capitalPort: true,
      );
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.capitalBlockaded);
    });

    test('foreign-owned province resolves none', () {
      const target = 'oldWorld|enemy1';
      final game = buildNavalMissionWarTargetsGame();
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.none);
    });
  });

  group('buildNavalSection blockade status (Refs #4516)', () {
    testWidgets('shows under blockade line for human-owned blockaded port', (
      tester,
    ) async {
      await pumpBlockadeNavalSection(
        tester,
        blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
      );
      expect(find.text(l10n.provinceOverlay_underBlockade), findsOneWidget);
    });

    testWidgets(
      'shows capital under-blockade line for human-owned capital port',
      (tester) async {
        await pumpBlockadeNavalSection(
          tester,
          blockadeStatus: ProvinceBlockadeStatus.capitalBlockaded,
        );
        expect(
          find.text(l10n.provinceOverlay_underBlockadeCapital),
          findsOneWidget,
        );
      },
    );

    testWidgets('omits status line when not blockaded', (tester) async {
      await pumpBlockadeNavalSection(tester);
      expect(find.text(l10n.provinceOverlay_underBlockade), findsNothing);
      expect(
        find.text(l10n.provinceOverlay_underBlockadeCapital),
        findsNothing,
      );
    });
  });

  testWidgets(
    'Blockade target dialog adds capital extra when capital selected',
    (tester) async {
      const enemyCap = 'oldWorld|enemy1';
      final game = buildNavalMissionCapitalPortTargetGame();
      await pumpBlockadeTargetDialog(
        tester,
        game: game,
        enemyCap: enemyCap,
      );

      expect(
        find.text(l10n.naval_mission_blockade_capitalExtra),
        findsOneWidget,
      );
    },
  );

  group('tile details blockade cause (Refs #4516)', () {
    test(
      'names blockade when the owned tile is disconnected by a port blockade',
      () {
        final game = blockadeTileDetailsGame(
          id: 'tile-blockade-cause',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|enemy1',
              regionId: 'oldWorld',
              ownerId: navalMissionGoldenHumanId,
              displayName: 'My Port',
            ),
          ],
        );
        final lines = blockadeTileDetailsLines(
          l10n: l10n,
          game: game,
          provinceId: 'oldWorld|enemy1',
          tileConnectivity: disconnectedTileConnectivity,
          blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
        );
        expect(
          lines,
          contains(l10n.provinceOverlay_tileCapitalLinkNotConnected),
        );
        expect(
          lines,
          contains(l10n.provinceOverlay_tileCapitalLinkCutByBlockade),
        );
      },
    );

    test(
      'omits the cause when the tile is disconnected for a non-blockade reason',
      () {
        final game = blockadeTileDetailsGame(
          id: 'tile-blockade-cause-none',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|enemy1',
              regionId: 'oldWorld',
              ownerId: navalMissionGoldenHumanId,
              displayName: 'Inland',
            ),
          ],
        );
        final lines = blockadeTileDetailsLines(
          l10n: l10n,
          game: game,
          provinceId: 'oldWorld|enemy1',
          tileConnectivity: disconnectedTileConnectivity,
        );
        expect(
          lines,
          contains(l10n.provinceOverlay_tileCapitalLinkNotConnected),
        );
        expect(
          lines,
          isNot(contains(l10n.provinceOverlay_tileCapitalLinkCutByBlockade)),
        );
      },
    );

    test('omits the cause when the owned tile stays capital-connected', () {
      final game = blockadeTileDetailsGame(
        id: 'tile-blockade-cause-connected',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|cap1',
            regionId: 'oldWorld',
            ownerId: navalMissionGoldenHumanId,
            displayName: 'Capital',
          ),
        ],
      );
      final lines = blockadeTileDetailsLines(
        l10n: l10n,
        game: game,
        provinceId: 'oldWorld|cap1',
        tileConnectivity: connectedTileConnectivity,
        blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
        roadLevel: 4,
      );
      expect(
        lines,
        isNot(contains(l10n.provinceOverlay_tileCapitalLinkCutByBlockade)),
      );
    });
  });
}
