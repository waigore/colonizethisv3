// Fixtures for upgrade_town Minor/Tribe scenario family (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const utmtGpId = 'gp1';
const utmtOw = 'oldWorld';

Game utmtMinorTownEmbassyPeaceGame() {
  const minorId = 'minor1';
  const minorTown = '$utmtOw|p2|0|0';
  return TestFixtures.minimalGame(
    id: 'g-minor-town-upgrade',
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$utmtOw|p1',
          regionId: utmtOw,
          ownerId: utmtGpId,
          townTileKey: '$utmtOw|p1|0|0',
        ),
        Province(
          id: '$utmtOw|p2',
          regionId: utmtOw,
          ownerId: minorId,
          townTileKey: minorTown,
          townDevelopmentLevel: 1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {
      utmtOw: {
        '$utmtOw|p1': ['$utmtOw|p1|0|0'],
        '$utmtOw|p2': [minorTown],
      },
    },
    players: const [
      Player(id: utmtGpId, displayName: 'GP', isHuman: true),
    ],
    minorNations: const [
      MinorNation(id: minorId, displayName: 'Minor'),
    ],
    overtureStates: const [
      OvertureState(
        gpId: utmtGpId,
        targetId: minorId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Game utmtWarTribeUpgradeGame() {
  const tribeId = 'tribe1';
  const townKey = '$utmtOw|p2|0|0';
  return TestFixtures.minimalGame(
    id: 'g-war-town-upgrade',
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$utmtOw|p2',
          regionId: utmtOw,
          ownerId: tribeId,
          townTileKey: townKey,
        ),
      ],
    ),
    players: [
      Player(
        id: utmtGpId,
        displayName: 'GP',
        isHuman: true,
        techUnlocked: {kTechIdNationalBureaucracy: true},
      ),
    ],
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
    overtureStates: const [
      OvertureState(
        gpId: utmtGpId,
        targetId: tribeId,
        stage: OvertureStage.embassy,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: utmtGpId,
        factionId2: tribeId,
        state: RelationState.atWar,
      ),
    ],
  );
}
