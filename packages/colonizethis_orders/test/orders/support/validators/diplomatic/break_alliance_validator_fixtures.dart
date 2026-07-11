// Shared fixtures for breakAlliance validator scenarios (Refs #3949 wave 3,
// #3971 wave 4).
//
// Refs #3753 R11. SPEC/program/orders.md § Diplomatic orders / break alliance.

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../common/game_graphs.dart';

Game breakAllianceValidatorTwoGpAllianceGame({
  bool formalAlliance = true,
  RelationState state = RelationState.atPeace,
}) => ordersTwoGpEmptyGame(
  turnNumber: 0,
  state: state,
  level: RelationLevel.allied,
  formalAlliance: formalAlliance,
  score: 80,
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
);
