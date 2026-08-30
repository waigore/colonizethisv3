import 'package:colonizethis_logic/ai_api.dart';

import 'summary_models.dart';

EconomySummary buildEconomySummary(PlayerView view) {
  final p = view.player;
  final workerCount = p.workerPool.totalWorkers;
  final treasury = p.treasury;
  var ownCount = 0;
  for (final prov in view.provincesById.values) {
    if (prov.ownerId == view.playerId) ownCount++;
  }
  return EconomySummary(
    workerCount: workerCount,
    treasury: treasury,
    ownProvinceCount: ownCount,
  );
}
