import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/faction_membership.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
void main() {
  final game = TestFixtures.minimalGame(
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
    minorNations: const [MinorNation(id: 'm1', displayName: 'Minor')],
    tribes: const [Tribe(id: 't1', displayName: 'Tribe')],
  );

  group('DiplomacyFactionMembership.from', () {
    final membership = DiplomacyFactionMembership.from(game);

    test('classifies great powers', () {
      expect(membership.isGreatPower('gp1'), isTrue);
      expect(membership.isMinorOrTribe('gp1'), isFalse);
    });

    test('classifies minors and tribes', () {
      expect(membership.isMinorOrTribe('m1'), isTrue);
      expect(membership.isMinorOrTribe('t1'), isTrue);
      expect(membership.isGreatPower('m1'), isFalse);
    });

    test('unknown ids are neither great power nor minor/tribe', () {
      expect(membership.isGreatPower('zzz'), isFalse);
      expect(membership.isMinorOrTribe('zzz'), isFalse);
    });
  });

  group('isMinorOrTribe (free function)', () {
    test('scans game collections when no snapshot is provided', () {
      expect(isMinorOrTribe(game, 'm1'), isTrue);
      expect(isMinorOrTribe(game, 't1'), isTrue);
      expect(isMinorOrTribe(game, 'gp1'), isFalse);
    });

    test('uses the snapshot when provided', () {
      final membership = DiplomacyFactionMembership.from(game);
      expect(
        isMinorOrTribe(game, 'm1', factionMembership: membership),
        isTrue,
      );
      expect(
        isMinorOrTribe(game, 'gp1', factionMembership: membership),
        isFalse,
      );
    });
  });

  group('isGreatPower (free function)', () {
    test('scans game players when no snapshot is provided', () {
      expect(isGreatPower(game, 'gp1'), isTrue);
      expect(isGreatPower(game, 'm1'), isFalse);
    });

    test('uses the snapshot when provided', () {
      final membership = DiplomacyFactionMembership.from(game);
      expect(
        isGreatPower(game, 'gp1', factionMembership: membership),
        isTrue,
      );
      expect(
        isGreatPower(game, 'm1', factionMembership: membership),
        isFalse,
      );
    });
  });
}
