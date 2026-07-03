// Table-driven boycottedColonySellableCommodityIds scenarios (Refs #3856).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'boycott_blocked_commodities_test_support.dart';
import 'trade_order_factory.dart';

/// One row in [boycottBlockedCommoditiesScenarios].
typedef BoycottBlockedCommoditiesScenario = ({
  String label,
  Game Function() buildGame,
  String buyerPlayerId,
  bool useDefaultTileMaps,
  bool useDefaultTopology,
  Map<String, ConnectivityResult>? connectivityByFactionId,
  Map<String, List<TradeOrder>>? autoOffersByFactionId,
  void Function(Set<CommodityId> blocked) verify,
  String? refs,
});

/// Canonical scenarios for [boycottedColonySellableCommodityIds].
List<BoycottBlockedCommoditiesScenario> boycottBlockedCommoditiesScenarios() => [
  (
    label: 'returns the colony Tribe sellable commodities for the boycotted buyer',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: true,
    useDefaultTopology: true,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, equals(<CommodityId>{'furs'})),
    refs: '#3758',
  ),
  (
    label: 'honors precomputed auto-offers without recomputing connectivity',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: true,
    useDefaultTopology: true,
    connectivityByFactionId: const {},
    autoOffersByFactionId: {
      't1': [testOffer('furs', 1)],
    },
    verify: (blocked) => expect(blocked, equals(<CommodityId>{'furs'})),
    refs: '#3758',
  ),
  (
    label: 'empty for a buyer that is not the boycott target',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpA',
    useDefaultTileMaps: true,
    useDefaultTopology: true,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, isEmpty),
    refs: '#3758',
  ),
  (
    label: 'empty when no boycott is active',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: true,
    useDefaultTopology: true,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, isEmpty),
    refs: '#3758',
  ),
  (
    label: 'empty when the boycotting GP holds no colony',
    buildGame: () => gameWithColonyTribeBoycottTest(
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: true,
    useDefaultTopology: true,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, isEmpty),
    refs: '#3758',
  ),
  (
    label: 'empty when tile maps are omitted (unit-test path unaffected)',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: false,
    useDefaultTopology: true,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, isEmpty),
    refs: '#3758',
  ),
  (
    label: 'empty when topology is absent',
    buildGame: () => gameWithColonyTribeBoycottTest(
      colonyStates: const [
        ColonyState(tribeId: 't1', colonyOfGpId: 'gpA', sinceTurn: 1),
      ],
      boycottStates: const [
        BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
      ],
    ),
    buyerPlayerId: 'gpC',
    useDefaultTileMaps: true,
    useDefaultTopology: false,
    connectivityByFactionId: null,
    autoOffersByFactionId: null,
    verify: (blocked) => expect(blocked, isEmpty),
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
