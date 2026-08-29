// Topic-split pins from `planning_diplomatic_scans_test.dart` (Refs #4669 Slice D).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/planning_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planning_diplomatic_scans_test_support.dart';

const String _gp2 = kPlanningDiplomaticScansGp2;
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';

AIWorldSnapshot _snapshotWithAtWar(List<String> atWarWith) {
  return AIWorldSnapshot(
    playerId: kPlanningDiplomaticScansGp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void registerPlanningDiplomaticScansAtWarGpCases() {
  group('atWarGreatPowerOrderTarget (Refs #3717)', () {
    const Player gp = Player(id: _gp2, displayName: 'GP2', isHuman: false);

    test('true when target is a Great Power we are at war with', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp2]),
          targetFactionId: _gp2,
        ),
        isTrue,
      );
    });

    test('false when the target is not a Great Power (targetGp null)', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar([_minor1]),
          targetFactionId: _minor1,
        ),
        isFalse,
      );
    });

    test('false when the Great Power target is not currently at war', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: gp,
          snapshot: _snapshotWithAtWar([_gp3]),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });

    test('false when both eligibility conditions fail', () {
      expect(
        atWarGreatPowerOrderTarget(
          targetGp: null,
          snapshot: _snapshotWithAtWar(const []),
          targetFactionId: _gp2,
        ),
        isFalse,
      );
    });
  });
}
