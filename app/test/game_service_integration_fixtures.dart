// Shared GameSetupConfig for GameService integration tests (#4734 Slice J).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

GameSetupConfig gameServiceIntegrationConfig({
  int seed = 0,
  AdvancedStartType advancedStart = AdvancedStartType.none,
  List<String> selectedGreatPowerIds = const ['england'],
  int numProvincesOldWorld = 3,
  int numProvincesNewWorld = 2,
}) {
  return GameSetupConfig(
    seed: seed,
    selectedGreatPowerIds: selectedGreatPowerIds,
    continentCount: 1,
    minorNationCount: 0,
    tribeCount: 1,
    numProvincesOldWorld: numProvincesOldWorld,
    numProvincesNewWorld: numProvincesNewWorld,
    advancedStart: advancedStart,
  );
}
