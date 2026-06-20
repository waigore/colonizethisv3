import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../test_fixtures.dart';

/// Affordability regression guard + human-player guard (Refs #2924).
///
/// The #2924 owner direction is explicit: the AI must **earn** treasury
/// legitimately (World Market / NW riches) before it can build regiments;
/// "training regiments without treasury is cheating". The fix therefore never
/// adds an affordability bypass to the build pipeline. These tests pin that
/// contract through the normal [BuildOrderValidator] path that both human and
/// AI build orders flow through (SPEC/program/orders.md § Build orders;
/// SPEC/ai/treasury-planner.md § "No affordability bypass"):
///
///   * a regiment build is rejected whenever `treasury <
///     cheapestRegimentBuildTreasuryCost()`, even when every other input
///     (materials, worker, spawn province) is satisfied — the treasury gate is
///     the sole remaining blocker, so accepting at exactly the cost proves the
///     rejection below cost is purely the affordability check (no bypass), and
///   * the gate is player-agnostic: a human player at `treasury == 0` is
///     rejected identically to an AI player — there is no per-player waiver.
void main() {
  suppressLogsForTests();

  // Cheapest regiment in the catalog; the lock-recovery economic chain must
  // reach this treasury before any regiment build can succeed.
  final cheapest = RegimentEconomyCatalog.peasantLevies;
  const provinceId = 'oldWorld|p1';

  // Build a game whose sole player can afford a `peasant_levies` regiment in
  // every dimension except (possibly) treasury: owns its capital province, has
  // the single fabric input in stockpile and a peasant to consume.
  Game gameForRegimentBuild({required int treasury, required bool isHuman}) =>
      TestFixtures.minimalGame(
        players: [
          Player(
            id: 'gp1',
            displayName: 'P',
            isHuman: isHuman,
            capitalProvinceId: provinceId,
            treasury: treasury,
            stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 1}),
            workerPool: const WorkerPool(peasants: 1),
          ),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: provinceId, regionId: 'oldWorld', ownerId: 'gp1'),
          ],
        ),
      );

  final regimentOrder = BuildUnitOrder(
    unitType: cheapest.id,
    isMilitary: true,
    spawnProvinceId: provinceId,
  );

  OrderValidationResult validateRegiment(Game game) => BuildOrderValidator(
    game: game,
    player: game.players.first,
  ).validate(regimentOrder, previousRejected: false);

  group('Refs #2924 regiment build affordability no-bypass guard', () {
    test(
      'peasant_levies is the cheapest, tech-free regiment (fixture pin)',
      () {
        expect(cheapest.id, 'peasant_levies');
        expect(cheapest.buildTreasuryCost, cheapestRegimentBuildTreasuryCost());
        expect(
          unlockingTechByRegimentId[cheapest.id],
          isNull,
          reason:
              'peasant_levies must be buildable without tech so treasury is '
              'the sole gate exercised by these guards',
        );
      },
    );

    test(
      'AI player below cheapest regiment treasury is rejected (no bypass)',
      () {
        final game = gameForRegimentBuild(
          treasury: cheapest.buildTreasuryCost - 1,
          isHuman: false,
        );
        final result = validateRegiment(game);
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Insufficient treasury');
      },
    );

    test('AI player at exactly the cheapest treasury is accepted '
        '(treasury gate is the sole blocker)', () {
      final game = gameForRegimentBuild(
        treasury: cheapest.buildTreasuryCost,
        isHuman: false,
      );
      final result = validateRegiment(game);
      expect(
        result.status,
        OrderValidationStatus.accepted,
        reason:
            'with materials/worker/spawn satisfied, crossing the '
            'treasury threshold must restore the unchanged build pipeline',
      );
    });

    test('human player at zero treasury is rejected (no human waiver)', () {
      final game = gameForRegimentBuild(treasury: 0, isHuman: true);
      final result = validateRegiment(game);
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Insufficient treasury');
    });

    test('affordability gate is player-agnostic at zero treasury '
        '(human and AI both rejected)', () {
      final humanResult = validateRegiment(
        gameForRegimentBuild(treasury: 0, isHuman: true),
      );
      final aiResult = validateRegiment(
        gameForRegimentBuild(treasury: 0, isHuman: false),
      );
      expect(humanResult.status, OrderValidationStatus.rejected);
      expect(aiResult.status, OrderValidationStatus.rejected);
      expect(humanResult.reason, aiResult.reason);
    });
  });
}
