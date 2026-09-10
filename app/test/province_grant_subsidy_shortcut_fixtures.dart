// Shared fixtures for MAP20001 Grant Aid / Set Subsidy pins (Refs #4761).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'province_establish_embassy_shortcut_fixtures.dart';

const String kGrantSubsidyHumanPlayerId = kEstablishEmbassyHumanPlayerId;
const String kGrantSubsidyMinorId = kEstablishEmbassyMinorId;
const String kGrantSubsidyGpOwnerId = kEstablishEmbassyGpOwnerId;
const String kGrantSubsidyProvinceId = kEstablishEmbassyProvinceId;
const String kGrantSubsidyTileKey = kEstablishEmbassyTileKey;
final kGrantSubsidyTopology = kEstablishEmbassyTopology;

Game buildGrantSubsidyShortcutGame({
  required String? ownerId,
  int treasury = 5000,
  bool asMinor = true,
  OvertureStage? overtureStage = OvertureStage.embassy,
  bool atWar = false,
}) => buildEstablishEmbassyShortcutGame(
  ownerId: ownerId,
  treasury: treasury,
  asMinor: asMinor,
  overtureStage: overtureStage,
  atWar: atWar,
);
