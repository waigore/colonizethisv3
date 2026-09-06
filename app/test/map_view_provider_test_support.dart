import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'province_shortcut_host_golden_game_service.dart';

class MapViewProviderFakeGameService extends GameService {
  MapViewProviderFakeGameService(super.box, super.adapter);

  @override
  getMapData(String gameId) {
    return null;
  }
}

GameService mapViewProviderShortcutHostMapService(Box<dynamic> gamesBox) {
  return ProvinceShortcutHostGoldenGameService(
    gamesBox,
    GameSaveAdapter(),
    gameId: 'g_map',
    includeNewWorld: true,
    useCoastalTileMap: true,
  );
}
