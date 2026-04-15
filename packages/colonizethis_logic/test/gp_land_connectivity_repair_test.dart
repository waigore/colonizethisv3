import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('gpProvincesAreLandConnected', () {
    test('single province is connected', () {
      final owners = {'p1': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1'},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), true);
    });

    test('two adjacent provinces are connected', () {
      final owners = {'p1': 'gp1', 'p2': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), true);
    });

    test('two non-adjacent provinces are not connected', () {
      final owners = {'p1': 'gp1', 'p3': 'gp1'};
      final n = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2'},
      };
      expect(gpProvincesAreLandConnected('gp1', owners, n), false);
    });
  });

  group('repairGpLandOwnershipMutating', () {
    test('1:1 swap with minor connects GP exclave (line graph)', () {
      final owners = <String, String>{'p1': 'gp1', 'p2': 'minor1', 'p3': 'gp1'};
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2'},
      };
      final landmass = <String, int>{'p1': 0, 'p2': 0, 'p3': 0};
      final ok = repairGpLandOwnershipMutating(
        owners: owners,
        gpIdsSorted: ['gp1'],
        neighbours: neighbours,
        landmassIds: landmass,
        seaBoundLocalIds: {'p1'},
        allProvinceIdsSorted: ['p1', 'p2', 'p3'],
      );
      expect(ok, true);
      expect(owners['p1'], 'gp1');
      expect(owners['p2'], 'gp1');
      expect(owners['p3'], 'minor1');
      expect(gpProvincesAreLandConnected('gp1', owners, neighbours), true);
    });

    test('swap with other GP preserves both GPs sea-bound and landmass', () {
      // p1—p2—p3—p4; gp1 should have p1,p4 (bad), gp2 p2,p3 (bad). Swap p4↔p2 fixes both.
      final owners = <String, String>{
        'p1': 'gp1',
        'p2': 'gp2',
        'p3': 'gp2',
        'p4': 'gp1',
      };
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2', 'p4'},
        'p4': {'p3'},
      };
      final landmass = <String, int>{'p1': 0, 'p2': 0, 'p3': 0, 'p4': 0};
      final ok = repairGpLandOwnershipMutating(
        owners: owners,
        gpIdsSorted: ['gp1', 'gp2'],
        neighbours: neighbours,
        landmassIds: landmass,
        seaBoundLocalIds: {'p1', 'p4'},
        allProvinceIdsSorted: ['p1', 'p2', 'p3', 'p4'],
      );
      expect(ok, true);
      expect(gpProvincesAreLandConnected('gp1', owners, neighbours), true);
      expect(gpProvincesAreLandConnected('gp2', owners, neighbours), true);
    });

    test('returns true immediately when already valid', () {
      final owners = <String, String>{'p1': 'gp1', 'p2': 'gp1'};
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1'},
      };
      final landmass = <String, int>{'p1': 0, 'p2': 0};
      final ok = repairGpLandOwnershipMutating(
        owners: owners,
        gpIdsSorted: ['gp1'],
        neighbours: neighbours,
        landmassIds: landmass,
        seaBoundLocalIds: {'p1'},
        allProvinceIdsSorted: ['p1', 'p2'],
      );
      expect(ok, true);
      expect(owners['p1'], 'gp1');
      expect(owners['p2'], 'gp1');
    });

    test(
      'maxRounds zero skips repair and reports failure when disconnected',
      () {
        final owners = <String, String>{
          'p1': 'gp1',
          'p2': 'minor1',
          'p3': 'gp1',
        };
        final neighbours = <String, Set<String>>{
          'p1': {'p2'},
          'p2': {'p1', 'p3'},
          'p3': {'p2'},
        };
        final landmass = <String, int>{'p1': 0, 'p2': 0, 'p3': 0};
        final ok = repairGpLandOwnershipMutating(
          owners: owners,
          gpIdsSorted: ['gp1'],
          neighbours: neighbours,
          landmassIds: landmass,
          seaBoundLocalIds: {'p1'},
          allProvinceIdsSorted: ['p1', 'p2', 'p3'],
          maxRounds: 0,
        );
        expect(ok, false);
        expect(gpProvincesAreLandConnected('gp1', owners, neighbours), false);
      },
    );
  });

  group('repairFactionLandOwnershipMutating', () {
    test('can repair disconnected minor while preserving GP hard rules', () {
      final owners = <String, String>{
        'p1': 'gp1',
        'p2': 'minor1',
        'p3': 'minor1',
        'p4': 'gp1',
      };
      final neighbours = <String, Set<String>>{
        'p1': {'p2'},
        'p2': {'p1', 'p3'},
        'p3': {'p2', 'p4'},
        'p4': {'p3'},
      };
      final landmass = <String, int>{'p1': 0, 'p2': 0, 'p3': 0, 'p4': 0};
      final ok = repairFactionLandOwnershipMutating(
        owners: owners,
        requiredConnectedFactionIdsSorted: ['gp1', 'minor1'],
        gpIdsSorted: ['gp1'],
        neighbours: neighbours,
        landmassIds: landmass,
        seaBoundLocalIds: {'p1'},
        allProvinceIdsSorted: ['p1', 'p2', 'p3', 'p4'],
      );
      expect(ok, true);
      expect(factionProvincesAreLandConnected('gp1', owners, neighbours), true);
      expect(
        factionProvincesAreLandConnected('minor1', owners, neighbours),
        true,
      );
    });
  });

  group('GameSetupConnectivityFailure', () {
    test('exposes reason code', () {
      final e = GameSetupConnectivityFailure('msg');
      expect(e.reasonCode, 'fair_assignment_connectivity_exhausted');
      expect(e.toString(), contains('fair_assignment_connectivity_exhausted'));
    });
  });
}
