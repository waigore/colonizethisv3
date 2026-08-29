// Case bodies for `develop_phase_planner_nw_suppression_test.dart` (Refs #2509 S4).

import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_planner_nw_suppression_test_support.dart';
import 'develop_phase_planner_nw_suppression_support.dart';

void registerDevelopPhasePlannerNwSuppressionCases() {
  group('DEVELOP planner set NW suppression (AC pin)', () {
    test('planner set output contains no declareWar, no NW acquisition, '
        'and no NW-invasion orders', () {
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();

      final peace = planDevelopPeace(game: game, snapshot: snapshot);
      for (final factionId in peace) {
        expect(
          isNonGpFaction(game, factionId),
          isFalse,
          reason:
              'planDevelopPeace must return only Great Power '
              'factionIds (DEVELOP is GP-vs-GP peace only). Tribe / '
              'minor ids in the output set indicate a structural '
              'leakage that would route the orchestrator into an '
              'unsupported NW peace path. Offending factionId: '
              '$factionId.',
        );
      }
      expect(peace, containsAll(<String>[kNwSuppressionGp2, kNwSuppressionGp3]));

      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      for (final order in civilian) {
        expect(
          order.target,
          kWorkTargetBuildImprovement,
          reason:
              'planDevelopCivilian must emit only '
              'kWorkTargetBuildImprovement orders. Any other target '
              '(purchase_land, etc.) is a structural NW-acquisition '
              'leakage. Offending order: $order.',
        );
        final tileOwner = ownerOfProvinceContainingTile(
          game,
          order.targetTileKey,
        );
        expect(
          tileOwner,
          kNwSuppressionGp1,
          reason:
              'planDevelopCivilian emitted a build_improvement '
              'order against tile ${order.targetTileKey} whose '
              'province is owned by $tileOwner (not the active '
              'player). DEVELOP must improve owned territory only; '
              'tile-keys in foreign or unowned provinces are a '
              'structural NW-acquisition leakage.',
        );
      }
      expect(civilian.map((o) => o.targetTileKey), <String>[
        kDevelopNwSuppressionOwnedNwTileKey,
        kDevelopNwSuppressionOwnedOwTileKey,
      ]);

      final emittedTileKeys = civilian.map((o) => o.targetTileKey).toSet();
      expect(
        emittedTileKeys.contains(kDevelopNwSuppressionTribeNwTileKey),
        isFalse,
        reason:
            'planDevelopCivilian must not emit improvements toward '
            'tribe-held NW tiles. The tribe-NW tile resource entry '
            'is present in the fixture; rejection must come from '
            'the ownership gate (province.ownerId != playerId).',
      );
      expect(
        emittedTileKeys.contains(kDevelopNwSuppressionUnownedNwTileKey),
        isFalse,
        reason:
            'planDevelopCivilian must not emit improvements toward '
            'unowned NW tiles. The unowned-NW tile resource entry '
            'is present in the fixture; rejection must come from '
            'the ownership gate (province.ownerId is null and not '
            'the active player).',
      );
    });

    test('tribe-only at-war set (NW-acquisition tempting) -> peace empty, '
        'civilian unchanged (no NW leakage when only tribes are at war)', () {
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot(
        atWarWith: const [kNwSuppressionTribe1, kNwSuppressionMinor1],
      );

      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'planDevelopPeace must return empty when atWarWith '
            'contains only non-GP factions. A tribe / minor id in '
            'the output set would route the orchestrator into an '
            'unsupported NW peace path.',
      );

      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      for (final order in civilian) {
        expect(order.target, kWorkTargetBuildImprovement);
        expect(
          isNwProvinceId(order.targetTileKey) &&
              ownerOfProvinceContainingTile(game, order.targetTileKey) !=
                  kNwSuppressionGp1,
          isFalse,
          reason:
              'planDevelopCivilian must never emit a NW order '
              'against a tile in a province the active player does '
              'not own, regardless of `atWarWith` shape. Offending '
              'order: $order.',
        );
      }
    });

    test('colonial summary populated but DEVELOP still routes only to '
        'owned-tile improvements (positive structural NW pin)', () {
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();
      expect(snapshot.colonial.invadableNewWorldProvinceIdsSorted, isNotEmpty);

      final civilian = planDevelopCivilian(game: game, snapshot: snapshot);
      final nwOrders = civilian
          .where((o) => isNwProvinceId(o.targetTileKey))
          .toList();
      expect(
        nwOrders.length,
        1,
        reason:
            'Exactly one NW order should appear (the active '
            'player owns one NW province with one resource tile). '
            'A larger NW count would indicate leakage from the '
            'colonial summary into civilian planning.',
      );
      expect(nwOrders.single.targetTileKey, kDevelopNwSuppressionOwnedNwTileKey);
    });

    test('determinism across the planner set (Must-have #7): same '
        'NW-rich fixture -> identical plan outputs across two runs', () {
      final game = buildDevelopPhaseNwSuppressionGame();
      final snapshot = buildDevelopPhaseNwSuppressionSnapshot();

      final peace1 = planDevelopPeace(game: game, snapshot: snapshot);
      final civilian1 = planDevelopCivilian(game: game, snapshot: snapshot);

      final peace2 = planDevelopPeace(game: game, snapshot: snapshot);
      final civilian2 = planDevelopCivilian(game: game, snapshot: snapshot);

      expect(peace2, peace1);
      expect(
        civilian2.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        civilian1.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
      );
    });
  });
}
