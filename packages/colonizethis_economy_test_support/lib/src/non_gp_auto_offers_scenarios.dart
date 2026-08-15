// dart format off
// Table-driven non-GP auto-offer scenarios (Refs #3856, #3939 slice 47 / 58 / 62).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'extraction_fixture_support.dart';
import 'non_gp_auto_offers_test_support.dart';
/// One row for `computeNonGreatPowerAutoOffers` scenario tables
/// (Refs #3939 slice 63).
typedef NonGpAutoOffersScenario = ({String label, Game game, Map<String, TileMapResult> tileMapByRegion, Map<String, ConnectivityResult> connectivityByFactionId, void Function(Map<String, List<TradeOrder>> result) verify, String? refs});
NonGpAutoOffersScenario nonGpAutoOfferRow({required String label, required Game game, required Map<String, TileMapResult> tileMapByRegion, required Map<String, ConnectivityResult> connectivityByFactionId, required NonGpAutoOffersExpectation expect, String? refs}) => (label: label, game: game, tileMapByRegion: tileMapByRegion, connectivityByFactionId: connectivityByFactionId, verify: (result) => assertNonGpAutoOffersExpectation(result, expect, game: game), refs: refs);
NonGpAutoOffersScenario nonGpEmptyAutoOfferRow({required String label, Game? game, Map<String, TileMapResult> tileMapByRegion = const {}, Map<String, ConnectivityResult> connectivityByFactionId = const {}, String? refs = '#2991 C4'}) => nonGpAutoOfferRow(label: label, game: game ?? nonGpEmptyGame(), tileMapByRegion: tileMapByRegion, connectivityByFactionId: connectivityByFactionId, expect: const NonGpAutoOffersExpectation(empty: true), refs: refs);
void runNonGpAutoOffersScenario(NonGpAutoOffersScenario scenario) {
  final result = computeNonGreatPowerAutoOffers(game: scenario.game, tileMapByRegion: scenario.tileMapByRegion, connectivityByFactionId: scenario.connectivityByFactionId);
  scenario.verify(result);
}
/// Compact minor/OW auto-offer row (Refs #3939 slice 47 / 57 / 58).
NonGpAutoOffersScenario nonGpAutoOfferMinorRow({required String label, required NonGpAutoOffersExpectation expect, required List<List<Resource?>> resources, required Set<String> connected, List<TileImprovementSpec>? tileSpecs, bool emptyConnectivity = false, String? refs = '#2991 C4'}) => nonGpAutoOfferRow(
  label: label,
  game: nonGpMinorM1Game(tileSpecs: tileSpecs ?? const []),
  tileMapByRegion: {'oldWorld': nonGpProvMap('oldWorld|m1', resources)},
  connectivityByFactionId: emptyConnectivity ? const {} : connectivityByFaction({'m1': connected}),
  expect: expect,
  refs: refs,
);
/// Compact purchased-tile C6 auto-offer row (Refs #3939 slice 47).
NonGpAutoOffersScenario nonGpAutoOfferPurchasedRow({required String label, required NonGpAutoOffersExpectation expect, required Resource resource, String tileKey = 'oldWorld|m1|0|0', String? refs = '#2991 C6'}) => nonGpAutoOfferRow(
  label: label,
  game: minorTileAutoOfferGame(tileKey: tileKey, improvementLevel: 1, roadLevel: 1, purchasedTilesByTileKey: {tileKey: 'gpA'}),
  tileMapByRegion: {'oldWorld': singleTileMap(resource, province: 'm1')},
  connectivityByFactionId: connectivityByFaction({
    'm1': {tileKey},
  }),
  expect: expect,
  refs: refs,
);
/// Canonical scenarios from `non_gp_auto_offers_test.dart` (Issue #2991 C4).
List<NonGpAutoOffersScenario> nonGpAutoOffersScenarios() {
  final dual = nonGpMinorTribeTimberFursFixture();
  return [
  nonGpEmptyAutoOfferRow(label: 'empty when no minors and no tribes are configured'),
  nonGpEmptyAutoOfferRow(
    label: 'empty when tileMapByRegion is empty',
    game: nonGpMinorM1Game(),
    connectivityByFactionId: connectivityByFaction({
      'm1': {'oldWorld|m1|0|0'},
    }),
  ),
  nonGpAutoOfferMinorRow(
    label: 'factions with no connectivity entry do not appear in the auto-offer map',
    tileSpecs: tileImps(const ['oldWorld|m1|0|0'], 1, 0),
    resources: const [
      [Resource.timber],
    ],
    connected: const {},
    emptyConnectivity: true,
    expect: const NonGpAutoOffersExpectation(empty: true),
  ),
    nonGpAutoOfferMinorRow(
      label: 'emits one priority-1 offer per non-riches tile with originTileKey set',
      tileSpecs: tileImps(const ['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
      resources: const [
        [Resource.timber, Resource.grain],
      ],
      connected: const {'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      expect: nonGpM1OffersExpect(length: 2, standardPriorityOneOffers: true, commodityIds: ['timber', 'grain'], originTileKeys: ['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
    ),
    nonGpAutoOfferRow(
      label: 'aggregates minor and tribe offers in the same result map',
      game: dual.game,
      tileMapByRegion: dual.tileMapByRegion,
      connectivityByFactionId: dual.connectivityByFactionId,
      expect: nonGpDualFactionOffersExpect(
        m1: const FactionAutoOffersExpectation(length: 1, singleCommodityId: 'timber'),
        t1: const FactionAutoOffersExpectation(length: 1, singleCommodityId: 'furs'),
      ),
      refs: '#2991 C4',
    ),
    nonGpAutoOfferMinorRow(
      label:
          'excludes riches commodities (spices) per Requirement 11 — '
          'riches do not trade on the world market',
      tileSpecs: tileImps(const ['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
      resources: const [
        [Resource.spices, Resource.grain],
      ],
      connected: const {'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      expect: nonGpM1OffersExpect(length: 1, singleCommodityId: 'grain', singleOriginTileKey: 'oldWorld|m1|1|0', excludeCommodity: 'spices'),
    ),
    nonGpAutoOfferMinorRow(
      label:
          'minerals stay excluded (covered by computeNonGreatPowerExtraction '
          'mineral filter) — no offer emitted for an iron tile even if developed',
      tileSpecs: tileImps(const ['oldWorld|m1|0|0', 'oldWorld|m1|1|0']),
      resources: const [
        [Resource.iron, Resource.grain],
      ],
      connected: const {'oldWorld|m1|0|0', 'oldWorld|m1|1|0'},
      expect: nonGpM1OffersExpect(length: 1, singleCommodityId: 'grain', factionKeys: null),
    ),
    ...nonGpAutoOffersPurchasedTileScenarios(),
  ];
}
/// Purchased-tile parity scenarios (Refs #2991 C6, #3939).
List<NonGpAutoOffersScenario> nonGpAutoOffersPurchasedTileScenarios() {
  const purchasedTileKey = 'oldWorld|m1|0|0';
  const unpurchasedTileKey = 'oldWorld|m1|1|0';
  return [
    nonGpAutoOfferPurchasedRow(
      label:
          'purchased non-riches tile (timber) emits a priority-1 auto-offer '
          'keyed under the minor with originTileKey equal to the purchased '
          'tile key',
      resource: Resource.timber,
      expect: nonGpM1OffersExpect(length: 1, standardPriorityOneOffers: true, singleCommodityId: 'timber', singleOriginTileKey: purchasedTileKey),
    ),
    nonGpAutoOfferRow(
      label:
          'purchased non-riches tile parity with unpurchased tile — both tiles '
          'emit auto-offers with identical quantity and priority; only '
          'originTileKey differs',
      game: twoMinorTimberTilesAutoOfferGame(purchasedTileKey: purchasedTileKey, unpurchasedTileKey: unpurchasedTileKey),
      tileMapByRegion: {'oldWorld': twoTileSameResourceMap(Resource.timber)},
      connectivityByFactionId: connectivityByFaction({
        'm1': {purchasedTileKey, unpurchasedTileKey},
      }),
      expect: nonGpM1OffersExpect(length: 2, standardPriorityOneOffers: true, commodityIds: ['timber', 'timber'], originTileKeys: [purchasedTileKey, unpurchasedTileKey], factionKeys: null),
      refs: '#2991 C6',
    ),
    nonGpAutoOfferPurchasedRow(
      label:
          'PurchasedTileIndex.fromGame is built independently of auto-offer '
          "emission — the minor's auto-offer for a purchased timber tile "
          'carries the originTileKey that the index can map back to the '
          'owning GP for FRR routing',
      resource: Resource.timber,
      expect: const NonGpAutoOffersExpectation(
        purchasedTileFrrAttribution: PurchasedTileFrrAttributionExpectation(factionId: 'm1', owningGpId: 'gpA', sourceFactionId: 'm1'),
      ),
    ),
    nonGpAutoOfferPurchasedRow(
      label:
          'purchased gold tile (mineral riches) emits no auto-offer — riches '
          'handoff (C5) routes the yield to the owning GP treasury in '
          'phase 3 instead',
      resource: Resource.gold,
      expect: const NonGpAutoOffersExpectation(empty: true),
    ),
    nonGpAutoOfferPurchasedRow(
      label:
          'purchased spices tile (non-mineral riches) emits no auto-offer — '
          'spices route through the riches handoff (C5) instead of the '
          'world market',
      resource: Resource.spices,
      expect: const NonGpAutoOffersExpectation(empty: true),
    ),
  ];
}
// dart format on
