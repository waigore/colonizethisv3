/// Distance / personality COLONIAL acquisition Game builders (Refs #3972 / #4602).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../planning/ai_planner_fixtures.dart';
import 'colonial_acquisition_test_support.dart';

/// Near/far tribe ids for adjacency-distance iteration pins.
const String kColonialAcquisitionNearTribe = 'tribeNear';
const String kColonialAcquisitionFarTribe = 'tribeFar';

/// Near province (second in lex order, first by distance).
const String kColonialAcquisitionNearProvince = 'newWorld|near_a';

/// Far province (first in lex order, second by distance).
const String kColonialAcquisitionFarProvince = 'newWorld|far_b';

/// Distance-iteration Game: both tribes Join-Empire-eligible; lex vs
/// distance order diverge on which tribe wins.
Game buildColonialAcquisitionDistanceGame({
  int activePlayerTreasury = 100000,
  List<Province>? newWorldProvinces,
}) {
  return buildColonialAcquisitionGame(
    gameId: 'g-2509-colonial-acquisition-distance',
    activePlayerTreasury: activePlayerTreasury,
    newWorldProvinces:
        newWorldProvinces ??
        const [
          Province(
            id: kColonialAcquisitionNearProvince,
            regionId: 'newWorld',
            ownerId: kColonialAcquisitionNearTribe,
          ),
          Province(
            id: kColonialAcquisitionFarProvince,
            regionId: 'newWorld',
            ownerId: kColonialAcquisitionFarTribe,
          ),
        ],
    tribes: const [
      Tribe(id: kColonialAcquisitionNearTribe, displayName: 'Near'),
      Tribe(id: kColonialAcquisitionFarTribe, displayName: 'Far'),
    ],
    overtureStates: [
      colonialAcquisitionNap(kColonialPhaseGp1, kColonialAcquisitionNearTribe),
      colonialAcquisitionNap(kColonialPhaseGp1, kColonialAcquisitionFarTribe),
    ],
    diplomacyRelations: [
      colonialAcquisitionFriendly(
        kColonialPhaseGp1,
        kColonialAcquisitionNearTribe,
      ),
      colonialAcquisitionFriendly(
        kColonialPhaseGp1,
        kColonialAcquisitionFarTribe,
      ),
    ],
  );
}

/// Personality-bias fixture: Join Empire and declareWar both valid for tribe1.
Game buildColonialAcquisitionBothValidGame({
  int activePlayerTreasury = 100000,
  List<Army>? armies,
  List<DiplomacyRelation>? diplomacyRelations,
  List<OvertureState>? overtureStates,
  List<Province>? newWorldProvinces,
}) {
  return buildColonialAcquisitionGame(
    gameId: 'g-2509-colonial-acquisition-personality',
    activePlayerTreasury: activePlayerTreasury,
    newWorldProvinces:
        newWorldProvinces ??
        const [
          Province(
            id: kColonialAcquisitionNwProv1,
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
    armies: armies ?? [homeArmyWithRegimentsAtCapital(kColonialPhaseGp1, 1)],
    tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
    overtureStates:
        overtureStates ??
        [colonialAcquisitionNap(kColonialPhaseGp1, kColonialPhaseTribe1)],
    diplomacyRelations:
        diplomacyRelations ??
        [colonialAcquisitionFriendly(kColonialPhaseGp1, kColonialPhaseTribe1)],
  );
}
