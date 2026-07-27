// Shared fixtures for economy_stockpile_preview_recruit_worker_test (Refs #4168 slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Player economyPreviewRecruitWorkerPlayer({
  String id = 'p1',
  Stockpile stockpile = const Stockpile(),
  WorkerPool workerPool = const WorkerPool(),
  int treasury = 0,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: id,
    displayName: 'A',
    isHuman: true,
    stockpile: stockpile,
    workerPool: workerPool,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

const economyPreviewRecruitApprenticeTechUnlocked = {
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};
