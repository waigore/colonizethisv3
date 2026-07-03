import 'package:colonizethis_ai/src/planning/research_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

/// Research-planner civilian-gating tech prioritization (Refs #3793 AC6).
/// SPEC/ai/civilian-build-planner.md § Tech prioritization. When the civilian
/// build planner is enabled, the research planner front-loads slot selection
/// toward not-yet-unlocked civilian-gating techs (`merchant_companies`,
/// `early_steam_engine`) within the unchanged per-turn slot target. Uses a fake
/// suggestion API so candidate ordering and selection are deterministic.
void main() {
  const playerId = 'gp1';
  const topology = MapTopology(nodes: [], edges: []);

  Game gameWith({
    required int treasury,
    Map<String, bool>? techUnlocked,
    int researchSlots = 3,
  }) => Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        leaderKey: 'victoria',
        treasury: treasury,
        researchSlots: researchSlots,
        techUnlocked: techUnlocked,
      ),
    ],
  );

  FakeOrderSuggestionAPIForDomainPlannerTests apiWith(
    List<ResearchOrder> research,
  ) => FakeOrderSuggestionAPIForDomainPlannerTests(
    work: const [],
    build: const [],
    move: const [],
    research: research,
    navalMove: const [],
    navalMission: const [],
  );

  ResearchOrder ro(int slot, String tech) => ResearchOrder(
    slotIndex: slot,
    techId: tech,
    funding: ResearchFundingLevel.medium,
  );

  List<ResearchOrder> runFor({
    required Game game,
    required FakeOrderSuggestionAPIForDomainPlannerTests api,
    required bool civilianBuildPlannerEnabled,
  }) {
    final ctx = buildTestPlannerContext(
      game: game,
      topology: topology,
      suggestionAPI: api,
      civilianBuildPlannerEnabled: civilianBuildPlannerEnabled,
    );
    final orders = runResearchPlanner(ctx: ctx);
    return orders.researchOrdersByPlayerId[playerId] ?? const <ResearchOrder>[];
  }

  group('research planner civilian-gating tech bias (AC6)', () {
    test('the gating-tech set derives from unlockingTechByCivilianId', () {
      expect(kCivilianGatingTechIds, contains(kTechIdMerchantCompanies));
      expect(kCivilianGatingTechIds, contains(kTechIdEarlySteamEngine));
      expect(isCivilianGatingTech(kTechIdMerchantCompanies), isTrue);
      expect(isCivilianGatingTech(kTechIdEarlySteamEngine), isTrue);
      expect(isCivilianGatingTech('tech_a'), isFalse);
    });

    test('AC6: enabled + not unlocked selects the gating tech over a '
        'lower-slot non-gating tech when only one slot funds', () {
      // treasury 50 funds exactly one Low slot (proven by the multi-slot
      // packing tests): the bias front-loads merchant_companies (slot 1) ahead
      // of tech_a (slot 0), so the single funded slot targets the gating tech.
      final game = gameWith(treasury: 50);
      final api = apiWith([ro(0, 'tech_a'), ro(1, kTechIdMerchantCompanies)]);

      final result = runFor(
        game: game,
        api: api,
        civilianBuildPlannerEnabled: true,
      );

      expect(result.length, 1, reason: 'only one slot is affordable');
      expect(
        result.single.techId,
        kTechIdMerchantCompanies,
        reason: 'civilian-gating tech is prioritized into the funded slot',
      );
    });

    test('AC6b (negative): disabled keeps the original slot order (lower-slot '
        'non-gating tech funded)', () {
      final game = gameWith(treasury: 50);
      final api = apiWith([ro(0, 'tech_a'), ro(1, kTechIdMerchantCompanies)]);

      final result = runFor(
        game: game,
        api: api,
        civilianBuildPlannerEnabled: false,
      );

      expect(result.length, 1);
      expect(
        result.single.techId,
        'tech_a',
        reason: 'with the bias off the lower slot index wins (no reordering)',
      );
    });

    test('AC6b (negative): enabled but the gating tech already unlocked keeps '
        'the original slot order', () {
      final game = gameWith(
        treasury: 50,
        techUnlocked: const {
          kTechIdMerchantCompanies: true,
          kTechIdEarlySteamEngine: true,
        },
      );
      final api = apiWith([ro(0, 'tech_a'), ro(1, kTechIdMerchantCompanies)]);

      final result = runFor(
        game: game,
        api: api,
        civilianBuildPlannerEnabled: true,
      );

      expect(result.length, 1);
      expect(
        result.single.techId,
        'tech_a',
        reason: 'an already-unlocked gating tech is not front-loaded',
      );
    });

    test('AC6: the bias funds no extra slot — count is identical enabled vs '
        'disabled when treasury funds every candidate', () {
      final api = apiWith([
        ro(0, 'tech_a'),
        ro(1, kTechIdMerchantCompanies),
        ro(2, kTechIdEarlySteamEngine),
      ]);

      final enabled = runFor(
        game: gameWith(treasury: 1000),
        api: api,
        civilianBuildPlannerEnabled: true,
      );
      final disabled = runFor(
        game: gameWith(treasury: 1000),
        api: api,
        civilianBuildPlannerEnabled: false,
      );

      expect(enabled.length, disabled.length);
      expect(
        enabled.map((o) => o.techId).toSet(),
        disabled.map((o) => o.techId).toSet(),
        reason:
            'reordering within the slot target changes no funded slot when '
            'all candidates are affordable',
      );
    });

    test('AC6: gating tech is front-loaded but the funded slot still carries '
        'its original slotIndex (deterministic)', () {
      final game = gameWith(treasury: 50);
      final api = apiWith([ro(0, 'tech_a'), ro(1, kTechIdMerchantCompanies)]);

      final result = runFor(
        game: game,
        api: api,
        civilianBuildPlannerEnabled: true,
      );

      expect(result.single.slotIndex, 1);
    });
  });
}
