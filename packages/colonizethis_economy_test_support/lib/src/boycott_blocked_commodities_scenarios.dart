// Table-driven boycottedColonySellableCommodityIds scenarios (Refs #3856, #3939 slice 15).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'boycott_blocked_commodities_expectations.dart';
import 'boycott_blocked_commodities_test_support.dart';
import 'trade_order_factory.dart';

const _boycottColonyStates = [
  ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
];
const _boycottActiveStates = [
  BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
];

BoycottBlockedCommoditiesScenario _boycottColonyRow({
  required String label,
  required BoycottBlockedCommoditiesExpectation expect,
  List<ColonyState> colonyStates = _boycottColonyStates,
  List<BoycottState> boycottStates = _boycottActiveStates,
  String buyerPlayerId = 'gpC',
  bool useDefaultTileMaps = true,
  bool useDefaultTopology = true,
  Map<String, ConnectivityResult>? connectivityByFactionId,
  Map<String, List<TradeOrder>>? autoOffersByFactionId,
  String? refs,
}) =>
    BoycottBlockedCommoditiesScenario.expect(
      label: label,
      buildGame: () => gameWithColonyTribeBoycottTest(
        colonyStates: colonyStates,
        boycottStates: boycottStates,
      ),
      buyerPlayerId: buyerPlayerId,
      expect: expect,
      useDefaultTileMaps: useDefaultTileMaps,
      useDefaultTopology: useDefaultTopology,
      connectivityByFactionId: connectivityByFactionId,
      autoOffersByFactionId: autoOffersByFactionId,
      refs: refs,
    );

/// One row in [boycottBlockedCommoditiesScenarios].
class BoycottBlockedCommoditiesScenario {
  const BoycottBlockedCommoditiesScenario({
    required this.label,
    required this.buildGame,
    required this.buyerPlayerId,
    required this.verify,
    this.useDefaultTileMaps = true,
    this.useDefaultTopology = true,
    this.connectivityByFactionId,
    this.autoOffersByFactionId,
    this.refs,
  });

  BoycottBlockedCommoditiesScenario.expect({
    required String label,
    required Game Function() buildGame,
    required String buyerPlayerId,
    required BoycottBlockedCommoditiesExpectation expect,
    bool useDefaultTileMaps = true,
    bool useDefaultTopology = true,
    Map<String, ConnectivityResult>? connectivityByFactionId,
    Map<String, List<TradeOrder>>? autoOffersByFactionId,
    String? refs,
  }) : this(
          label: label,
          buildGame: buildGame,
          buyerPlayerId: buyerPlayerId,
          useDefaultTileMaps: useDefaultTileMaps,
          useDefaultTopology: useDefaultTopology,
          connectivityByFactionId: connectivityByFactionId,
          autoOffersByFactionId: autoOffersByFactionId,
          verify: (blocked) =>
              assertBoycottBlockedCommoditiesExpectation(blocked, expect),
          refs: refs,
        );

  final String label;
  final Game Function() buildGame;
  final String buyerPlayerId;
  final bool useDefaultTileMaps;
  final bool useDefaultTopology;
  final Map<String, ConnectivityResult>? connectivityByFactionId;
  final Map<String, List<TradeOrder>>? autoOffersByFactionId;
  final void Function(Set<CommodityId> blocked) verify;
  final String? refs;
}

/// Canonical scenarios for [boycottedColonySellableCommodityIds].
List<BoycottBlockedCommoditiesScenario> boycottBlockedCommoditiesScenarios() =>
    [
      _boycottColonyRow(
        label:
            'returns the colony Tribe sellable commodities for the boycotted buyer',
        expect: const BoycottBlockedCommoditiesExpectation(
          blockedCommodityIds: {'furs'},
        ),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'honors precomputed auto-offers without recomputing connectivity',
        connectivityByFactionId: const {},
        autoOffersByFactionId: {
          't1': [testOffer('furs', 1)],
        },
        expect: const BoycottBlockedCommoditiesExpectation(
          blockedCommodityIds: {'furs'},
        ),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'empty for a buyer that is not the boycott target',
        buyerPlayerId: 'gpA',
        expect: const BoycottBlockedCommoditiesExpectation(isEmpty: true),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'empty when no boycott is active',
        boycottStates: const [],
        expect: const BoycottBlockedCommoditiesExpectation(isEmpty: true),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'empty when the boycotting GP holds no colony',
        colonyStates: const [],
        expect: const BoycottBlockedCommoditiesExpectation(isEmpty: true),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'empty when tile maps are omitted (unit-test path unaffected)',
        useDefaultTileMaps: false,
        expect: const BoycottBlockedCommoditiesExpectation(isEmpty: true),
        refs: '#3758',
      ),
      _boycottColonyRow(
        label: 'empty when topology is absent',
        useDefaultTopology: false,
        expect: const BoycottBlockedCommoditiesExpectation(isEmpty: true),
        refs: '#3758',
      ),
    ];

/// Runs a boycott-blocked-commodities scenario row.
void runBoycottBlockedCommoditiesScenario({
  required BoycottBlockedCommoditiesScenario scenario,
  required Map<String, TileMapResult> defaultTileMaps,
  required MapTopology defaultTopology,
}) {
  final blocked = boycottedColonySellableCommodityIds(
    game: scenario.buildGame(),
    buyerPlayerId: scenario.buyerPlayerId,
    tileMapByRegion: scenario.useDefaultTileMaps ? defaultTileMaps : const {},
    topology: scenario.useDefaultTopology ? defaultTopology : null,
    connectivityByFactionId: scenario.connectivityByFactionId,
    autoOffersByFactionId: scenario.autoOffersByFactionId,
  );
  scenario.verify(blocked);
}
