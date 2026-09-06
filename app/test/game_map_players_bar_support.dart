import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kGameMapPlayerChipKeyPrefix, kGameMapPlayersBarKey;
import 'package:colonizethis_app/features/game/widgets/shell/game_map_players_bar.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show factionOwnershipColorMapForOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

ct_models.Game playersBarGameWithOwnership() {
  final base = buildPlayersBarTestGame();
  final greatPowers = GameMapPlayersBar.greatPowerRoster(base);
  expect(greatPowers.length, greaterThanOrEqualTo(2));
  final ow = base.worldState.oldWorld;
  final provinces = ow.provinces;
  expect(provinces.length, greaterThanOrEqualTo(6));

  ct_models.Province withoutOwner(ct_models.Province p) {
    return ct_models.Province(
      id: p.id,
      regionId: p.regionId,
      displayName: p.displayName,
      fortLevel: p.fortLevel,
      terrain: p.terrain,
      townTileKey: p.townTileKey,
      townDevelopmentLevel: p.townDevelopmentLevel,
    );
  }

  final mutated = <ct_models.Province>[];
  for (var i = 0; i < provinces.length; i++) {
    final cleared = withoutOwner(provinces[i]);
    if (i == 0) {
      mutated.add(cleared.copyWith(ownerId: greatPowers[0].id));
    } else if (i >= 1 && i <= 4) {
      mutated.add(cleared.copyWith(ownerId: greatPowers[1].id));
    } else {
      mutated.add(cleared);
    }
  }
  return base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: ct_models.RegionData(provinces: mutated, units: ow.units),
    ),
  );
}

Widget playersBarHostFor(ct_models.Game game, {String? highlightPlayerId}) {
  return buildAppShell(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: Scaffold(
      body: SizedBox(
        width: 600,
        height: 400,
        child: Stack(
          children: [
            GameMapPlayersBar(
              game: game,
              highlightPlayerId: highlightPlayerId,
            ),
          ],
        ),
      ),
    ),
  );
}
