// Shared scoring helpers for FTP competition overture case modules.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const ftpCompetitionOvertureConfig = AIConfig(
  leaderId: 'frederick',
  personalityId: 'frederick',
  hiddenAgendaId: 'merchant',
);
const ftpCompetitionOvertureTopology = MapTopology(nodes: [], edges: []);

int scoreFtpCompetitionOvertureCandidate({
  required Game game,
  required List<DiplomaticOrder> candidates,
  AIWorldSnapshot? snapshot,
}) {
  final resolvedSnapshot =
      snapshot ??
      AIWorldSnapshot.fromPlayerView(
        buildPlayerView(game, ftpCompetitionOvertureTopology, 'gp1'),
      );
  return computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: candidates,
      nationId: 'gp1',
      game: game,
      snapshot: resolvedSnapshot,
      config: ftpCompetitionOvertureConfig,
    ),
  ).single;
}

AIWorldSnapshot ftpCompetitionTribeOvertureSnapshot() => const AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: 20,
    provincesToVictory: 31,
  ),
  colonial: ColonialSummary(),
  economy: EconomySummary(),
  relations: {},
);
