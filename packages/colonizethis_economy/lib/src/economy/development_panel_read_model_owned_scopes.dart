/// Owned-province scope rows for the Development panel read model.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show Game, PlayerView;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_model.dart';
import 'development_panel_read_model_scopes.dart';
import 'province_improvable_resource_counts.dart';

/// Builds owned-province scope rows for one region.
List<DevelopmentPanelScopeRow> buildDevelopmentPanelOwnedScopes({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, String> provinceDisplayNamesById,
  required ProvinceOwnerCache ownerCache,
  PlayerView? playerView,
}) {
  final ownedProvinces =
      ownerCache.provincesOwnedByInRegion(playerId, regionId);
  final ownedScopes = <DevelopmentPanelScopeRow>[];
  for (final province in ownedProvinces) {
    final improvable = developmentImprovableRowsFromCounts(
      provinceImprovableResourceTileCounts(
        game: game,
        provinceId: province.id,
        ownerId: playerId,
        tileMapByRegion: tileMapByRegion,
      ),
      playerView: playerView,
    );
    ownedScopes.add(
      DevelopmentPanelScopeRow(
        scopeKey: province.id,
        provinceId: province.id,
        displayName:
            provinceDisplayNamesById[province.id] ?? province.id,
        improvableCommodities: improvable,
      ),
    );
  }
  return ownedScopes;
}
