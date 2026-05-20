/// Direct unit tests for `validateJoinEmpireOverture`, the free-function
/// replacement for the legacy `JoinEmpireOvertureValidator` class (Refs #2560
/// § Diplomatic sub-validators). Each per-stage establishOverture dispatcher
/// still exercises it via `establishOvertureSubValidator`, but these tests
/// pin the direct contract (rejected/accepted result, preserved-on-reject
/// treasury) for the lifted entry point.
/// SPEC/program/orders.md § Diplomatic orders / overtures.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/diplomatic/join_empire_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

void main() {
  group('validateJoinEmpireOverture (free function)', () {
    test(
      'rejects when current stage is not NAP and preserves treasury (negative)',
      () {
        final ctx = diplomaticSubValidatorContext(
          gpMinorGame(overtureStage: OvertureStage.embassy),
          'gp1',
        );
        final r = validateJoinEmpireOverture(
          ctx: ctx,
          targetId: 'minor1',
          rel: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
            score: relationScoreMinFriendly,
          ),
          currentStage: OvertureStage.embassy,
          treasury: 99999,
        );
        expect(r.result.status, OrderValidationStatus.rejected);
        expect(r.result.reason, contains('Non-Aggression Pact'));
        expect(r.treasury, 99999, reason: 'reject must not debit treasury');
      },
    );

    test(
      'rejects when score below friendly threshold and preserves treasury (negative)',
      () {
        final ctx = diplomaticSubValidatorContext(
          gpMinorGame(
            overtureStage: OvertureStage.nap,
            relationScore: relationScoreNeutral,
          ),
          'gp1',
        );
        final r = validateJoinEmpireOverture(
          ctx: ctx,
          targetId: 'minor1',
          rel: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
            score: relationScoreNeutral,
          ),
          currentStage: OvertureStage.nap,
          treasury: 99999,
        );
        expect(r.result.status, OrderValidationStatus.rejected);
        expect(r.result.reason, contains('Friendly relations'));
        expect(r.treasury, 99999);
      },
    );

    test(
      'accepts minor target with funds at or above scaled cost and preserves treasury (positive)',
      () {
        final ctx = diplomaticSubValidatorContext(
          gpMinorGame(
            overtureStage: OvertureStage.nap,
            relationScore: relationScoreMinFriendly,
          ),
          'gp1',
        );
        // gpMinorGame's minor1 has no provinces, so scaled cost stays at
        // the minor/tribe floor; pick a treasury comfortably above it.
        final r = validateJoinEmpireOverture(
          ctx: ctx,
          targetId: 'minor1',
          rel: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
            score: relationScoreMinFriendly,
          ),
          currentStage: OvertureStage.nap,
          treasury: 1000000,
        );
        expect(r.result.status, OrderValidationStatus.accepted);
        expect(
          r.treasury,
          1000000,
          reason: 'joinEmpire toward minor does not debit on accept',
        );
      },
    );

    test(
      'rejects join empire toward GP without Empire Building tech (negative)',
      () {
        final ctx = diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atPeace),
          'gp1',
        );
        final r = validateJoinEmpireOverture(
          ctx: ctx,
          targetId: 'gp2',
          rel: const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            score: relationScoreMinFriendly,
          ),
          currentStage: OvertureStage.nap,
          treasury: 99999,
        );
        expect(r.result.status, OrderValidationStatus.rejected);
        expect(r.result.reason, contains('Empire Building'));
        expect(r.treasury, 99999);
      },
    );
  });
}
