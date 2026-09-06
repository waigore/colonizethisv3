// Panel-family diplomacy fixtures (Refs #3847 / #4734 Slice F).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game with one discovered GP row for orders/chrome suites.
Game buildDiplomacyPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const rival = 'gp2';
  return buildPanelTestGame(
    id: 'diplomacy-panel-widget-test',
    players: const [
      Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      Player(id: rival, displayName: 'Rival Power', isHuman: false),
    ],
  ).copyWith(
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: human,
        factionId2: rival,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}

/// Rich panel fixture: three GPs, one minor, one tribe (Refs #3656).
Game buildDiplomacyRichPanelTestGame() {
  const human = kPanelTestHumanPlayerId;
  const gp2 = 'gp2';
  const gp3 = 'gp3';
  const minorId = 'm1';
  const tribeId = 't1';
  const type = kPanelTestRegimentType;
  const dummyProvince = 'oldWorld|p1';
  return buildPanelTestGame(
    id: 'diplomacy-rich-panel-widget-test',
    players: [
      const Player(
        id: human,
        displayName: 'Test Human',
        isHuman: true,
        treasury: 5000,
      ),
      const Player(id: gp2, displayName: 'Rival Power', isHuman: false),
      const Player(id: gp3, displayName: 'Third Power', isHuman: false),
    ],
    minorNations: const [MinorNation(id: minorId, displayName: 'Free City')],
    tribes: const [Tribe(id: tribeId, displayName: 'Tribe One')],
    oldWorldUnits: [
      Unit(
        id: 'reg_gp1',
        type: type,
        ownerId: human,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp2_a',
        type: type,
        ownerId: gp2,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp2_b',
        type: type,
        ownerId: gp2,
        locationProvinceId: dummyProvince,
      ),
      Unit(
        id: 'reg_gp3',
        type: type,
        ownerId: gp3,
        locationProvinceId: dummyProvince,
      ),
    ],
  ).copyWith(
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: human,
        factionId2: gp2,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: gp3,
        state: RelationState.atWar,
        score: 20,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: minorId,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
      DiplomacyRelation(
        factionId1: human,
        factionId2: tribeId,
        state: RelationState.atPeace,
        score: 50,
        sinceTurn: 0,
        lastInteractionTurn: 0,
      ),
    ],
  );
}
