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
