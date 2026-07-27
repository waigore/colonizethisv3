import 'package:colonizethis_data/colonizethis_data.dart'
    show kMilitaryVictoryOldWorldProvinceThreshold;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Weighted power-score components for one Great Power row expansion.
class VictoryPowerScoreBreakdown {
  const VictoryPowerScoreBreakdown({
    required this.totalProvinces,
    required this.regimentStrength,
    required this.shipCount,
    required this.provincePoints,
    required this.regimentPoints,
    required this.shipPoints,
    required this.totalScore,
  });

  final int totalProvinces;
  final int regimentStrength;
  final int shipCount;
  final int provincePoints;
  final int regimentPoints;
  final int shipPoints;
  final int totalScore;
}

/// One Great Power row in the Victory standings list.
class VictoryStandingRow {
  const VictoryStandingRow({
    required this.playerId,
    required this.displayName,
    required this.owProvinceCount,
    required this.powerBreakdown,
  });

  final String playerId;
  final String displayName;
  final int owProvinceCount;
  final VictoryPowerScoreBreakdown powerBreakdown;
}

/// Military victory threshold surfaced in the Victory panel conditions block.
int get victoryPanelMilitaryOwThreshold =>
    kMilitaryVictoryOldWorldProvinceThreshold;

VictoryPowerScoreBreakdown buildVictoryPowerScoreBreakdown(
  Game game,
  String playerId,
) {
  final totalProvinces = provinceCountOwnedBy(game, playerId);
  final regimentStrength =
      aggregateMilitaryStrengthForPlayer(game, playerId).round();
  final shipCount = shipCountForFaction(game, playerId);
  final provincePoints = totalProvinces * powerScoreProvinceWeight;
  final regimentPoints = regimentStrength * powerScoreRegimentWeight;
  final shipPoints = shipCount * powerScoreShipWeight;
  return VictoryPowerScoreBreakdown(
    totalProvinces: totalProvinces,
    regimentStrength: regimentStrength,
    shipCount: shipCount,
    provincePoints: provincePoints,
    regimentPoints: regimentPoints,
    shipPoints: shipPoints,
    totalScore: provincePoints + regimentPoints + shipPoints,
  );
}

/// Sorts Great Powers by Old World province count descending, then display
/// name ascending for stable ties. SPEC/ui/victory-panel.md § Standings.
List<VictoryStandingRow> buildVictoryStandings(Game game) {
  final players = List<Player>.from(game.players);
  players.sort((a, b) {
    final owCmp = oldWorldProvinceCountOwnedBy(
      game,
      b.id,
    ).compareTo(oldWorldProvinceCountOwnedBy(game, a.id));
    if (owCmp != 0) return owCmp;
    return a.displayName.compareTo(b.displayName);
  });
  return [
    for (final player in players)
      VictoryStandingRow(
        playerId: player.id,
        displayName: player.displayName,
        owProvinceCount: oldWorldProvinceCountOwnedBy(game, player.id),
        powerBreakdown: buildVictoryPowerScoreBreakdown(game, player.id),
      ),
  ];
}

String displayNameForVictoryFaction(Game game, String id) {
  final player = game.playerById(id);
  if (player != null) return player.displayName;
  return id;
}
