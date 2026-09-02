// Shared fixtures for diplomacy confirm preview golden tests.

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const diplomacyConfirmPreviewHumanId = 'gp1';
const diplomacyConfirmPreviewTargetGp = 'gp2';

Game diplomacyConfirmPreviewGame() => diplomacyGame(
  players: const [
    Player(
      id: diplomacyConfirmPreviewHumanId,
      displayName: 'England',
      isHuman: true,
      treasury: 50_000,
    ),
    Player(
      id: diplomacyConfirmPreviewTargetGp,
      displayName: 'Spain',
      isHuman: false,
    ),
  ],
);

String diplomacyConfirmPreviewMessage(DiplomaticOrder order) =>
    buildDiplomacyConfirmPreviewMessage(
      order: order,
      game: diplomacyConfirmPreviewGame(),
      humanPlayerId: diplomacyConfirmPreviewHumanId,
      targetDisplayName: 'Spain',
    );

Game diplomacyConfirmTwoColonyPreviewGame() => diplomacyGame(
  players: const [
    Player(
      id: diplomacyConfirmPreviewHumanId,
      displayName: 'England',
      isHuman: true,
      treasury: 50_000,
    ),
    Player(
      id: diplomacyConfirmPreviewTargetGp,
      displayName: 'Spain',
      isHuman: false,
    ),
  ],
  tribes: const [
    Tribe(id: 'tribe_aztec', displayName: 'Aztec'),
    Tribe(id: 'tribe_inca', displayName: 'Inca'),
  ],
  colonyStates: const [
    ColonyState(
      tribeId: 'tribe_aztec',
      colonyOfGpId: diplomacyConfirmPreviewHumanId,
      sinceTurn: 1,
    ),
    ColonyState(
      tribeId: 'tribe_inca',
      colonyOfGpId: diplomacyConfirmPreviewHumanId,
      sinceTurn: 1,
    ),
  ],
);

Game diplomacyConfirmMinorOvertureGame() => diplomacyGame(
  players: const [
    Player(
      id: diplomacyConfirmPreviewHumanId,
      displayName: 'England',
      isHuman: true,
    ),
  ],
  minorNations: const [
    MinorNation(id: 'minor1', displayName: 'Bavaria'),
  ],
);
