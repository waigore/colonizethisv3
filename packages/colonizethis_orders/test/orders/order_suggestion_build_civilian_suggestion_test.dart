// Tests for civilian build candidate enumeration in `suggestBuildOrders`
// (Refs #3793, SPEC/ai/civilian-build-planner.md). Civilian candidates are
// opt-in via `includeCivilianBuilds`; the default keeps the list identical to
// the military+naval-only enumeration so the Full-AI build path is unaffected.
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_build_civilian_test_support.dart';

List<String> _civilianUnitTypes(List<BuildUnitOrder> orders) => orders
    .where((o) => CivilianEconomyCatalog.byId.containsKey(o.unitType))
    .map((o) => o.unitType)
    .toList();

void main() {
  group('suggestBuildOrders civilian enumeration (Refs #3793)', () {
    test(
      'AC1: includes affordable civilian candidates when includeCivilianBuilds '
      'is true',
      () {
        final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
        final view = buildPlayerView(game, buildCivilianTopology, 'p1');

        final suggestions = suggestBuildOrders(
          view,
          game,
          buildCivilianTopology,
          const Orders(),
          includeCivilianBuilds: true,
        );

        final civilians = _civilianUnitTypes(suggestions);
        expect(
          civilians,
          containsAll(<String>[
            kUnitTypeBuilder,
            kUnitTypeEngineer,
            kUnitTypeExplorer,
          ]),
          reason:
              'Builder/Engineer/Explorer cost 1000 cash + 2 paper and are '
              'affordable with treasury 2000 + paper 2',
        );
      },
    );

    test('AC1: emitted civilian candidates are deterministically sorted by '
        'unitType', () {
      final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      final unitTypes = suggestions.map((o) => o.unitType).toList();
      final sorted = [...unitTypes]..sort();
      expect(unitTypes, sorted);
    });

    test('AC1b: default (flag omitted) emits no civilian candidates and equals '
        'the explicit false call', () {
      final game = buildCivilianValidationGame(treasury: 2000, paper: 2);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final defaulted = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
      );
      final explicitFalse = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: false,
      );

      expect(_civilianUnitTypes(defaulted), isEmpty);
      expect(
        defaulted.map((o) => o.unitType).toList(),
        explicitFalse.map((o) => o.unitType).toList(),
      );
    });

    test('AC5: Merchant excluded when merchant_companies is not unlocked', () {
      final game = buildCivilianValidationGame(treasury: 3000, paper: 4);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      expect(_civilianUnitTypes(suggestions), isNot(contains(kUnitTypeMerchant)));
    });

    test('AC5: Merchant included when merchant_companies is unlocked and '
        'affordable', () {
      final game = buildCivilianValidationGame(
        treasury: 3000,
        paper: 4,
        techUnlocked: const {kTechIdMerchantCompanies: true},
      );
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      expect(_civilianUnitTypes(suggestions), contains(kUnitTypeMerchant));
    });

    test('AC9: identical inputs produce identical civilian enumeration', () {
      final game = buildCivilianValidationGame(treasury: 3000, paper: 4);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final first = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );
      final second = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      expect(
        first.map((o) => o.unitType).toList(),
        second.map((o) => o.unitType).toList(),
      );
    });

    test('AC12: no civilian candidates when treasury is zero', () {
      final game = buildCivilianValidationGame(treasury: 0, paper: 4);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      expect(_civilianUnitTypes(suggestions), isEmpty);
    });

    test('AC12: no civilian candidates when paper is below the minimum cost', () {
      final game = buildCivilianValidationGame(treasury: 5000, paper: 1);
      final view = buildPlayerView(game, buildCivilianTopology, 'p1');

      final suggestions = suggestBuildOrders(
        view,
        game,
        buildCivilianTopology,
        const Orders(),
        includeCivilianBuilds: true,
      );

      expect(_civilianUnitTypes(suggestions), isEmpty);
    });
  });
}
