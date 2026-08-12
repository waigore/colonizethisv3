// Confirm-dialog preview fixtures for diplomacy panel tests (Refs #4181, #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_panel_orders_pump_support.dart';
import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';

Game diplomacyConfirmPreviewMinorConsulateGame() {
  const ow = 'oldWorld';
  return buildPanelTestGame(
    id: 'diplomacy-consulate-confirm-test',
    players: const [
      Player(
        id: diplomacyOrdersHumanId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
        techUnlocked: {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [
      MinorNation(id: diplomacyOrdersMinorId, displayName: 'Free City'),
    ],
    oldWorldProvinces: [
      Province(id: '$ow|p1', regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(
        id: '$ow|m1',
        regionId: ow,
        ownerId: diplomacyOrdersMinorId,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewMinorJoinEmpireGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: 50,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersMinorId,
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewGpJoinEmpireGame() {
  const ow = 'oldWorld';
  const rivalCapital = '$ow|cap2';
  const rivalProv1 = '$ow|p2a';
  return buildPanelTestGame(
    id: 'diplomacy-gp-join-empire-confirm-test',
    players: const [
      Player(
        id: diplomacyOrdersHumanId,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
        techUnlocked: {kTechIdEmpireBuilding: true},
      ),
      Player(
        id: diplomacyOrdersGp2,
        displayName: 'Rival Power',
        isHuman: false,
        capitalProvinceId: rivalCapital,
      ),
    ],
    oldWorldProvinces: [
      Province(id: '$ow|p1', regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(id: rivalCapital, regionId: ow, ownerId: diplomacyOrdersHumanId),
      Province(id: rivalProv1, regionId: ow, ownerId: diplomacyOrdersGp2),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersGp2,
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
  ).copyWith(
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersGp2,
        stage: OvertureStage.nap,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewMinorEmbassyOvertureGame() {
  return diplomacyConfirmPreviewMinorConsulateGame().copyWith(
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersMinorId,
        stage: OvertureStage.tradeConsulate,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewMinorNapOvertureGame() {
  return diplomacyConfirmPreviewMinorConsulateGame().copyWith(
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersMinorId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewFtpGame() {
  return buildDiplomacyPanelTestGame().copyWith(
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersGp2,
        state: RelationState.atPeace,
        score: relationScoreMinFtp,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: diplomacyOrdersGp2,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

Game diplomacyConfirmPreviewColonyBoycottGame({
  List<BoycottState> boycotts = const [],
}) {
  return buildDiplomacyPanelTestGame().copyWith(
    colonyStates: const [
      ColonyState(
        tribeId: 't1',
        colonyOfGpId: diplomacyOrdersHumanId,
        sinceTurn: 1,
      ),
    ],
    tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
    boycottStates: boycotts,
  );
}

Game diplomacyConfirmPreviewTribeJoinEmpireGame() {
  return buildDiplomacyRichPanelTestGame().copyWith(
    diplomacyRelations: [
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp2',
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 'gp3',
        state: RelationState.atWar,
        score: 20,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: diplomacyOrdersMinorId,
        state: RelationState.atPeace,
        score: 50,
      ),
      const DiplomacyRelation(
        factionId1: diplomacyOrdersHumanId,
        factionId2: 't1',
        state: RelationState.atPeace,
        score: relationScoreMinFriendly,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: diplomacyOrdersHumanId,
        targetId: 't1',
        stage: OvertureStage.nap,
      ),
    ],
  );
}
