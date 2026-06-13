/// GA fitness function: scores AI profile performance from a single observer
/// game's final snapshot and run-summary. Pure computation, deterministic.
/// SPEC/program/ga-fitness.md. Refs #3438.
library;

import '../package_logger.dart';
import 'fitness_score.dart';

final _log = packageLogger('fitness');

/// Category weights for the base fitness sum.
const double kEconomicWeight = 0.4;
const double kMilitaryWeight = 0.4;
const double kDiplomaticWeight = 0.2;

/// Multiplier applied to the declared winner's base score before penalties.
const double kWinMultiplier = 2.0;

/// Additive shaping penalties (negative), applied after the win multiplier.
const double kBankruptcyPenalty = -50.0;
const double kCapitalLossPenalty = -100.0;
const double kZeroRegimentsPenalty = -80.0;
const double kMilitaryHeavyBrokePenalty = -30.0;

/// Regiment-to-(regiment+worker) ratio above which "military-heavy" applies.
const double kMilitaryHeavyRatioThreshold = 0.9;

const List<String> _kWorkerTiers = <String>[
  'peasants',
  'apprentices',
  'journeymen',
  'masters',
];

/// Scores every player in [snapshot] against game-relative normalization.
///
/// [snapshot] is a decoded `ObserverSnapshot` (schema v4); [runSummary] is a
/// decoded `run-summary.json`; [capitalProvinceByPlayerId] maps each playerId to
/// its capital province id (supplied by the caller, not present in the snapshot).
/// Returns one [FitnessScore] per playerId. See SPEC/program/ga-fitness.md.
Map<String, FitnessScore> computeFitness(
  Map<String, dynamic> snapshot,
  Map<String, dynamic> runSummary, {
  required Map<String, String> capitalProvinceByPlayerId,
}) {
  final players = _parsePlayers(snapshot);
  if (players.isEmpty) return const <String, FitnessScore>{};

  final provinceCountByOwner = _countByOwner(
    snapshot['provinceOwnershipSorted'],
  );
  final ownerByProvince = _ownerByProvince(snapshot['provinceOwnershipSorted']);
  final regimentCountByOwner = _regimentCountByOwner(
    snapshot['militaryArmySummariesSorted'],
  );
  final relations = _parseRelations(
    snapshot['diplomacyRelationSummariesSorted'],
  );
  final winnerId = runSummary['declared_winner_player_id'];

  for (final p in players) {
    p.provinceCount = provinceCountByOwner[p.playerId] ?? 0;
    p.regimentCount = regimentCountByOwner[p.playerId] ?? 0;
    p.allianceCount = relations
        .where((r) => r.involves(p.playerId) && r.level == 'allied')
        .length;
    p.nonWarRelations = relations
        .where((r) => r.involves(p.playerId) && !r.atWar)
        .length;
  }

  final economic = _category(<List<double>>[
    [for (final p in players) p.treasury],
    [for (final p in players) p.workerTotal.toDouble()],
    [for (final p in players) p.provinceCount.toDouble()],
  ]);
  final military = _category(<List<double>>[
    [for (final p in players) p.regimentCount.toDouble()],
    [for (final p in players) p.provinceCount.toDouble()],
    [for (final p in players) p.strengthProxy],
  ]);
  final diplomatic = _category(<List<double>>[
    [for (final p in players) p.allianceCount.toDouble()],
    [for (final p in players) p.nonWarRelations.toDouble()],
  ]);

  final result = <String, FitnessScore>{};
  for (var i = 0; i < players.length; i++) {
    final p = players[i];
    final base =
        kEconomicWeight * economic[i] +
        kMilitaryWeight * military[i] +
        kDiplomaticWeight * diplomatic[i];
    final winMultiplier = p.playerId == winnerId ? kWinMultiplier : 1.0;
    final penalties = _shapingPenalties(
      p,
      capitalId: capitalProvinceByPlayerId[p.playerId],
      ownerByProvince: ownerByProvince,
    );
    result[p.playerId] = FitnessScore(
      economic: economic[i],
      military: military[i],
      diplomatic: diplomatic[i],
      total: base * winMultiplier + penalties,
    );
  }
  return result;
}

double _shapingPenalties(
  _PlayerRaw p, {
  required String? capitalId,
  required Map<String, String?> ownerByProvince,
}) {
  var sum = 0.0;
  if (p.treasury <= 0) sum += kBankruptcyPenalty;
  if (capitalId != null && ownerByProvince[capitalId] != p.playerId) {
    sum += kCapitalLossPenalty;
  }
  if (p.regimentCount == 0) sum += kZeroRegimentsPenalty;
  final denom = p.regimentCount + p.workerTotal;
  final ratio = denom > 0 ? p.regimentCount / denom : 0.0;
  if (ratio > kMilitaryHeavyRatioThreshold && p.treasury <= 0) {
    sum += kMilitaryHeavyBrokePenalty;
  }
  return sum;
}

/// Equal-weight mean of per-component normalized values for each player.
List<double> _category(List<List<double>> rawColumns) {
  final normalized = rawColumns.map(_normalizeColumn).toList();
  final playerCount = normalized.first.length;
  final componentCount = normalized.length;
  return List<double>.generate(playerCount, (i) {
    var sum = 0.0;
    for (final column in normalized) {
      sum += column[i];
    }
    return sum / componentCount;
  });
}

/// Floors raw values at 0, then divides by the column max (0 when max <= 0).
List<double> _normalizeColumn(List<double> raws) {
  final floored = raws.map((r) => r < 0 ? 0.0 : r).toList();
  final maxValue = floored.fold<double>(0, (m, v) => v > m ? v : m);
  if (maxValue <= 0) return List<double>.filled(floored.length, 0.0);
  return floored.map((v) => v / maxValue).toList();
}

List<_PlayerRaw> _parsePlayers(Map<String, dynamic> snapshot) {
  final raw = snapshot['players'];
  if (raw is! List<Object?>) return const <_PlayerRaw>[];
  final players = <_PlayerRaw>[];
  for (final entry in raw) {
    if (entry is! Map<Object?, Object?>) continue;
    final playerId = entry['playerId'];
    if (playerId is! String) continue;
    players.add(
      _PlayerRaw(
        playerId: playerId,
        treasury: _numOf(entry, 'treasuryPounds').toDouble(),
        workerTotal: _workerTotal(entry['workerPool']),
        strengthProxy: _strengthProxy(entry),
      ),
    );
  }
  return players;
}

int _workerTotal(Object? pool) {
  if (pool is! Map<Object?, Object?>) return 0;
  var sum = 0;
  for (final tier in _kWorkerTiers) {
    final value = pool[tier];
    if (value is num) sum += value.round();
  }
  return sum;
}

double _strengthProxy(Map<dynamic, dynamic> player) {
  final hint = player['regimentLikeUnitCountHint'];
  if (hint is num) return hint.toDouble();
  final score = player['greatPowerPowerScore'];
  if (score is num) return score.toDouble();
  return 0.0;
}

num _numOf(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  return value is num ? value : 0;
}

Map<String, int> _countByOwner(Object? rows) {
  final result = <String, int>{};
  if (rows is! List<Object?>) return result;
  for (final row in rows) {
    if (row is! Map<Object?, Object?>) continue;
    final owner = row['ownerId'];
    if (owner is String) {
      result[owner] = (result[owner] ?? 0) + 1;
    }
  }
  return result;
}

Map<String, String?> _ownerByProvince(Object? rows) {
  final result = <String, String?>{};
  if (rows is! List<Object?>) return result;
  for (final row in rows) {
    if (row is! Map<Object?, Object?>) continue;
    final id = row['id'];
    if (id is String) {
      final owner = row['ownerId'];
      result[id] = owner is String ? owner : null;
    }
  }
  return result;
}

Map<String, int> _regimentCountByOwner(Object? lines) {
  final result = <String, int>{};
  if (lines is! List<Object?>) return result;
  for (final line in lines) {
    if (line is! String) continue;
    final owner = _token(line, 'owner=');
    final regiments = int.tryParse(_token(line, 'regiments=') ?? '');
    if (owner == null || regiments == null) {
      _log.warning('ignoring unparseable army summary "$line"');
      continue;
    }
    result[owner] = (result[owner] ?? 0) + regiments;
  }
  return result;
}

List<_Relation> _parseRelations(Object? lines) {
  final result = <_Relation>[];
  if (lines is! List<Object?>) return result;
  for (final line in lines) {
    if (line is! String) continue;
    final relation = _Relation.tryParse(line);
    if (relation == null) {
      _log.warning('ignoring unparseable diplomacy summary "$line"');
      continue;
    }
    result.add(relation);
  }
  return result;
}

String? _token(String line, String prefix) {
  for (final part in line.split(RegExp(r'\s+'))) {
    if (part.startsWith(prefix)) return part.substring(prefix.length);
  }
  return null;
}

class _PlayerRaw {
  _PlayerRaw({
    required this.playerId,
    required this.treasury,
    required this.workerTotal,
    required this.strengthProxy,
  });

  final String playerId;
  final double treasury;
  final int workerTotal;
  final double strengthProxy;

  int provinceCount = 0;
  int regimentCount = 0;
  int allianceCount = 0;
  int nonWarRelations = 0;
}

class _Relation {
  _Relation(this.a, this.b, this.level, this.atWar);

  final String a;
  final String b;
  final String level;
  final bool atWar;

  bool involves(String playerId) => a == playerId || b == playerId;

  static _Relation? tryParse(String line) {
    final colon = line.indexOf(': ');
    if (colon < 0) return null;
    final ids = line.substring(0, colon).split('<->');
    if (ids.length != 2) return null;
    final right = line.substring(colon + 2);
    final level = _token(right, 'lvl=');
    if (level == null) return null;
    final tokens = right.split(RegExp(r'\s+'));
    final atWar = tokens.isNotEmpty && tokens.last == 'war';
    return _Relation(ids[0].trim(), ids[1].trim(), level, atWar);
  }
}
