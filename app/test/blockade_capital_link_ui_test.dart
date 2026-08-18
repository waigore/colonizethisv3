// Blockade capital-link player copy (Refs #4516).

import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'panel_test_fixtures.dart';

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
      final game = buildPanelTestGame(
        id: 'blockade-status-owned',
        players: const [
          Player(
            id: navalMissionGoldenHumanId,
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap1',
          ),
          Player(
            id: navalMissionGoldenEnemyId,
            displayName: 'Spain',
            isHuman: false,
          ),
        ],
        oldWorldProvinces: const [
          Province(
            id: target,
            regionId: 'oldWorld',
            ownerId: navalMissionGoldenHumanId,
            displayName: 'My Port',
          ),
        ],
        fleets: [
          Fleet(
            id: 'blockader',
            ownerId: navalMissionGoldenEnemyId,
            regionId: 'oldWorld',
            seaZoneId: navalMissionGoldenSeaZone,
            mission: FleetMission.blockade,
            targetProvinceId: target,
            ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: navalMissionGoldenHumanId,
            factionId2: navalMissionGoldenEnemyId,
            state: RelationState.atWar,
          ),
        ],
        portsByProvinceSeaboard: const {
          'oldWorld|enemy1|$navalMissionGoldenSeaZone': 'oldWorld|enemy1|0|0',
        },
      );
      final status = resolveHumanOwnedBlockadeStatus(
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: target,
        topology: navalMissionWarTopology(),
        isSeaZone: false,
      );
      expect(status, ProvinceBlockadeStatus.portBlockaded);
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
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              return buildNavalSection(
                l10n: appL10n(context),
                game: buildNavalMissionMenuPeacetimeGame(),
                fleets: const [],
                humanPlayerId: navalMissionGoldenHumanId,
                draftOrders: const Orders(),
                blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n.provinceOverlay_underBlockade), findsOneWidget);
    });

    testWidgets('omits status line when not blockaded', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              return buildNavalSection(
                l10n: appL10n(context),
                game: buildNavalMissionMenuPeacetimeGame(),
                fleets: const [],
                humanPlayerId: navalMissionGoldenHumanId,
                draftOrders: const Orders(),
              );
            },
          ),
        ),
      );
      await tester.pump();
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
      final game = buildPanelTestGame(
        id: 'blockade-capital-extra',
        players: const [
          Player(
            id: navalMissionGoldenHumanId,
            displayName: 'England',
            isHuman: true,
          ),
          Player(
            id: navalMissionGoldenEnemyId,
            displayName: 'Spain',
            isHuman: false,
            capitalProvinceId: enemyCap,
          ),
        ],
        oldWorldProvinces: const [
          Province(
            id: enemyCap,
            regionId: 'oldWorld',
            ownerId: navalMissionGoldenEnemyId,
            displayName: 'Enemy Capital Port',
          ),
        ],
        fleets: [
          Fleet(
            id: 'fleet_at_sea',
            ownerId: navalMissionGoldenHumanId,
            regionId: 'oldWorld',
            seaZoneId: navalMissionGoldenSeaZone,
            ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: navalMissionGoldenHumanId,
            factionId2: navalMissionGoldenEnemyId,
            state: RelationState.atWar,
          ),
        ],
      );
      final fleet = game.worldState.fleets.single;

      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: NavalMissionTargetDialog(
            game: game,
            mission: FleetMission.blockade,
            fleet: fleet,
            targetProvinceIds: const [enemyCap],
            humanPlayerId: navalMissionGoldenHumanId,
            initialTargetProvinceId: enemyCap,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.naval_mission_blockade_capitalExtra),
        findsOneWidget,
      );
    },
  );

  group('tile details blockade cause (Refs #4516)', () {
    const disconnected = ProvinceTileConnectivityDisplay(
      capitalConnected: false,
      extractionEffective: 0,
      extractionFull: 3,
    );
    const connected = ProvinceTileConnectivityDisplay(
      capitalConnected: true,
      extractionEffective: 1,
      extractionFull: 1,
    );

    test(
      'names blockade when the owned tile is disconnected by a port blockade',
      () {
        final game = buildPanelTestGame(
          id: 'tile-blockade-cause',
          players: const [
            Player(
              id: navalMissionGoldenHumanId,
              displayName: 'England',
              isHuman: true,
              capitalProvinceId: 'oldWorld|cap1',
            ),
          ],
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|enemy1',
              regionId: 'oldWorld',
              ownerId: navalMissionGoldenHumanId,
              displayName: 'My Port',
            ),
          ],
        );
        final lines = provinceTileDetailsLines(
          l10n: l10n,
          game: game,
          humanPlayerId: navalMissionGoldenHumanId,
          provinceId: 'oldWorld|enemy1',
          roadLevel: 0,
          tileConnectivity: disconnected,
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
        final game = buildPanelTestGame(
          id: 'tile-blockade-cause-none',
          players: const [
            Player(
              id: navalMissionGoldenHumanId,
              displayName: 'England',
              isHuman: true,
              capitalProvinceId: 'oldWorld|cap1',
            ),
          ],
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|enemy1',
              regionId: 'oldWorld',
              ownerId: navalMissionGoldenHumanId,
              displayName: 'Inland',
            ),
          ],
        );
        final lines = provinceTileDetailsLines(
          l10n: l10n,
          game: game,
          humanPlayerId: navalMissionGoldenHumanId,
          provinceId: 'oldWorld|enemy1',
          roadLevel: 0,
          tileConnectivity: disconnected,
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
      final game = buildPanelTestGame(
        id: 'tile-blockade-cause-connected',
        players: const [
          Player(
            id: navalMissionGoldenHumanId,
            displayName: 'England',
            isHuman: true,
            capitalProvinceId: 'oldWorld|cap1',
          ),
        ],
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|cap1',
            regionId: 'oldWorld',
            ownerId: navalMissionGoldenHumanId,
            displayName: 'Capital',
          ),
        ],
      );
      final lines = provinceTileDetailsLines(
        l10n: l10n,
        game: game,
        humanPlayerId: navalMissionGoldenHumanId,
        provinceId: 'oldWorld|cap1',
        roadLevel: 4,
        tileConnectivity: connected,
        blockadeStatus: ProvinceBlockadeStatus.portBlockaded,
      );
      expect(
        lines,
        isNot(contains(l10n.provinceOverlay_tileCapitalLinkCutByBlockade)),
      );
    });
  });
}
