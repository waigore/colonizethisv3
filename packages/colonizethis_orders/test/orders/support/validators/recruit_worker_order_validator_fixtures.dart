// Shared RecruitWorkerOrderValidator fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Player recruitWorkerValidatorPlayer({
  Stockpile? stockpile,
  WorkerPool? workerPool,
  int treasury = 0,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: 'p1',
    displayName: 'P',
    isHuman: true,
    stockpile: stockpile ?? const Stockpile(),
    workerPool: workerPool ?? const WorkerPool(),
    treasury: treasury,
    techUnlocked: techUnlocked ?? const {},
  );
}

const recruitWorkerApprenticeTech = {
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};

const recruitWorkerJourneymanTech = {
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
};

const recruitWorkerMasterTech = {
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};
