import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_game_fixtures_scenarios.dart';

/// Phase resolver base game with gp1 embassy to minor1 and a neutral relation.
Game gpMinorEmbassyNeutralPhaseGame({
  int gp1Treasury = 2000,
  List<SubsidyState> subsidyStates = const [],
}) {
  final base = diplomacyResolverPhaseTestBaseGame();
  return base.copyWith(
    players: [
      base.players.single.copyWith(treasury: gp1Treasury),
    ],
    overtureStates: const [gpMinorEmbassyOverture],
    diplomacyRelations: [gpMinorNeutralRelation()],
    subsidyStates: subsidyStates,
  );
}
