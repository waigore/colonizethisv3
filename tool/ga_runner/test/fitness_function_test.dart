import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

/// Fitness function tests mapped to SPEC/program/ga-fitness.md ACs. Refs #3438.

Map<String, dynamic> _player(
  String id, {
  num treasury = 0,
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  num? strengthHint,
  num? powerScore,
}) => <String, dynamic>{
  'playerId': id,
  'treasuryPounds': treasury,
  'workerPool': <String, dynamic>{
    'peasants': peasants,
    'apprentices': apprentices,
    'journeymen': journeymen,
    'masters': masters,
  },
  if (strengthHint != null) 'regimentLikeUnitCountHint': strengthHint,
  if (powerScore != null) 'greatPowerPowerScore': powerScore,
};

Map<String, String?> _prov(String id, String? ownerId) => <String, String?>{
  'id': id,
  'ownerId': ownerId,
};

Map<String, dynamic> _snapshot({
  required List<Map<String, dynamic>> players,
  List<Map<String, String?>> provinces = const [],
  List<String> armies = const [],
  List<String> relations = const [],
}) => <String, dynamic>{
  'players': players,
  'provinceOwnershipSorted': provinces,
  'militaryArmySummariesSorted': armies,
  'diplomacyRelationSummariesSorted': relations,
};

Map<String, dynamic> _summary(String? winner) => <String, dynamic>{
  'declared_winner_player_id': winner,
};

void main() {
  group('computeFitness output shape', () {
    test('returns one FitnessScore per player keyed by playerId', () {
      final scores = computeFitness(
        _snapshot(players: [_player('A'), _player('B')]),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      expect(scores.keys.toSet(), {'A', 'B'});
      final a = scores['A']!;
      expect(a.economic, isA<double>());
      expect(a.military, isA<double>());
      expect(a.diplomatic, isA<double>());
      expect(a.total, isA<double>());
    });

    test('empty players → empty result', () {
      final scores = computeFitness(
        _snapshot(players: const []),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      expect(scores, isEmpty);
    });
  });

  group('category normalization', () {
    test('strictly stronger player gets economic 1.0 and beats weaker', () {
      final scores = computeFitness(
        _snapshot(
          players: [
            _player('A', treasury: 100, peasants: 10),
            _player('B', treasury: 10, peasants: 2),
          ],
          provinces: [_prov('p1', 'A'), _prov('p2', 'A'), _prov('p3', 'B')],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      expect(scores['A']!.economic, closeTo(1.0, 1e-9));
      expect(scores['A']!.economic, greaterThan(scores['B']!.economic));
    });

    test('component with game-max 0 yields 0 (no division by zero)', () {
      final scores = computeFitness(
        _snapshot(players: [_player('A'), _player('B')]),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      expect(scores['A']!.economic, 0.0);
      expect(scores['A']!.military, 0.0);
      expect(scores['A']!.diplomatic, 0.0);
      expect(scores['B']!.economic, 0.0);
    });

    test('negative treasury is floored at 0 before normalization', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A', treasury: -100), _player('B', treasury: 50)],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      // Only treasury varies; floored A treasury is 0, B is max → A economic 0.
      expect(scores['A']!.economic, 0.0);
      expect(scores['B']!.economic, closeTo(1.0 / 3.0, 1e-9));
    });

    test('diplomatic counts allied-only alliances and non-war relations', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A'), _player('B'), _player('C')],
          relations: const [
            'A<->B: score=9 lvl=allied peace',
            'A<->C: score=2 lvl=neutral peace',
            'B<->C: score=-5 lvl=hostile war',
          ],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {},
      );
      expect(scores['A']!.diplomatic, closeTo(1.0, 1e-9));
      expect(scores['B']!.diplomatic, closeTo(0.75, 1e-9));
      expect(scores['C']!.diplomatic, closeTo(0.25, 1e-9));
    });
  });

  group('win multiplier', () {
    Map<String, dynamic> dominantSnapshot() => _snapshot(
      players: [
        _player('A', treasury: 100, peasants: 10, strengthHint: 5),
        _player('B', treasury: 10, peasants: 1, strengthHint: 0),
      ],
      provinces: [_prov('pA1', 'A'), _prov('pA2', 'A')],
      armies: const ['army:a1 owner=A region=r1 regiments=5'],
      relations: const ['A<->B: score=9 lvl=allied peace'],
    );

    test('winner base is multiplied by 2.0 (penalty-free dominator → 2.0)', () {
      final scores = computeFitness(
        dominantSnapshot(),
        _summary('A'),
        capitalProvinceByPlayerId: const {'A': 'pA1'},
      );
      expect(scores['A']!.total, closeTo(2.0, 1e-9));
    });

    test('non-winner uses multiplier 1.0 (same dominator → base 1.0)', () {
      final scores = computeFitness(
        dominantSnapshot(),
        _summary(null),
        capitalProvinceByPlayerId: const {'A': 'pA1'},
      );
      expect(scores['A']!.total, closeTo(1.0, 1e-9));
    });
  });

  group('shaping penalties', () {
    test('bankruptcy applies -50 (treasury <= 0)', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A', treasury: 0, peasants: 10, strengthHint: 3)],
          provinces: [_prov('p1', 'A')],
          armies: const ['army:a1 owner=A region=r1 regiments=3'],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'A': 'p1'},
      );
      // base = 0.4*(0+1+1)/3 + 0.4*1 = 0.6666667; penalty -50.
      expect(scores['A']!.total, closeTo(0.6666667 - 50.0, 1e-6));
    });

    test('zero regiments applies -80', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A', treasury: 100, peasants: 10, strengthHint: 5)],
          provinces: [_prov('p1', 'A')],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'A': 'p1'},
      );
      // base = 0.4*1 + 0.4*(0+1+1)/3 = 0.6666667; penalty -80.
      expect(scores['A']!.total, closeTo(0.6666667 - 80.0, 1e-6));
    });

    test('capital loss applies -100; absent capital id skips penalty', () {
      final scores = computeFitness(
        _snapshot(
          players: [
            _player('A', treasury: 100, peasants: 10, strengthHint: 5),
            _player('B', treasury: 100, peasants: 10, strengthHint: 5),
          ],
          provinces: [_prov('p1', 'B'), _prov('p2', 'A')],
          armies: const [
            'army:a1 owner=A region=r1 regiments=5',
            'army:b1 owner=B region=r1 regiments=5',
          ],
        ),
        _summary(null),
        // A's capital p1 is owned by B → loss; B has no capital provided → skip.
        capitalProvinceByPlayerId: const {'A': 'p1'},
      );
      expect(scores['A']!.total, closeTo(0.8 - 100.0, 1e-6));
      expect(scores['B']!.total, closeTo(0.8, 1e-6));
    });

    test('military-heavy + broke adds -30 on top of bankruptcy', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A', treasury: 0, peasants: 0, strengthHint: 10)],
          provinces: [_prov('p1', 'A')],
          armies: const ['army:a1 owner=A region=r1 regiments=10'],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'A': 'p1'},
      );
      // base = 0.4*(0+0+1)/3 + 0.4*1 = 0.5333333; ratio 10/10=1.0 > 0.9 and
      // treasury 0 → -30, plus bankruptcy -50 → -80 total penalties.
      expect(scores['A']!.total, closeTo(0.5333333 - 80.0, 1e-6));
    });
  });

  group('determinism and monotonicity', () {
    test('identical inputs produce identical scores', () {
      Map<String, dynamic> snap() => _snapshot(
        players: [
          _player('A', treasury: 100, peasants: 10, strengthHint: 5),
          _player('B', treasury: 50, peasants: 5, strengthHint: 2),
        ],
        provinces: [_prov('p1', 'A'), _prov('p2', 'B')],
        armies: const [
          'army:a1 owner=A region=r1 regiments=5',
          'army:b1 owner=B region=r1 regiments=2',
        ],
        relations: const ['A<->B: score=9 lvl=allied peace'],
      );
      final first = computeFitness(
        snap(),
        _summary('A'),
        capitalProvinceByPlayerId: const {'A': 'p1', 'B': 'p2'},
      );
      final second = computeFitness(
        snap(),
        _summary('A'),
        capitalProvinceByPlayerId: const {'A': 'p1', 'B': 'p2'},
      );
      for (final id in first.keys) {
        expect(second[id]!.total, first[id]!.total);
        expect(second[id]!.economic, first[id]!.economic);
        expect(second[id]!.military, first[id]!.military);
        expect(second[id]!.diplomatic, first[id]!.diplomatic);
      }
    });

    test('player that grows provinces/regiments/treasury scores higher', () {
      final weak = computeFitness(
        _snapshot(
          players: [
            _player('P', treasury: 10, peasants: 1, strengthHint: 1),
            _player('Q', treasury: 100, peasants: 10, strengthHint: 10),
          ],
          provinces: [_prov('pP', 'P'), _prov('qP', 'Q'), _prov('q2', 'Q')],
          armies: const [
            'army:p1 owner=P region=r1 regiments=1',
            'army:q1 owner=Q region=r1 regiments=10',
          ],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'P': 'pP', 'Q': 'qP'},
      );
      final strong = computeFitness(
        _snapshot(
          players: [
            _player('P', treasury: 100, peasants: 10, strengthHint: 10),
            _player('Q', treasury: 10, peasants: 1, strengthHint: 1),
          ],
          provinces: [_prov('pP', 'P'), _prov('p2', 'P'), _prov('qP', 'Q')],
          armies: const [
            'army:p1 owner=P region=r1 regiments=10',
            'army:q1 owner=Q region=r1 regiments=1',
          ],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'P': 'pP', 'Q': 'qP'},
      );
      expect(strong['P']!.total, greaterThan(weak['P']!.total));
    });
  });

  group('robustness', () {
    test('unparseable army summary is ignored (treated as 0 regiments)', () {
      final scores = computeFitness(
        _snapshot(
          players: [_player('A', treasury: 100, peasants: 10, strengthHint: 5)],
          provinces: [_prov('p1', 'A')],
          armies: const ['totally malformed line without fields'],
        ),
        _summary(null),
        capitalProvinceByPlayerId: const {'A': 'p1'},
      );
      // No parseable regiments → zero-regiment penalty -80.
      expect(scores['A']!.total, closeTo(0.6666667 - 80.0, 1e-6));
    });
  });
}
