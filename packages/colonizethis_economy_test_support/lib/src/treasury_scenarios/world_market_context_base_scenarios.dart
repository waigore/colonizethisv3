// dart format off
// Table-driven WorldMarketContextBase scenarios (Refs #3856, #3939 slice 19).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [WorldMarketContextBase] scenario rows.
class WorldMarketContextBaseExpectation {
  const WorldMarketContextBaseExpectation({this.playerId, this.bidTypeCap, this.tradeCargoCapacity, this.availableStockpileByCommodityId, this.stockpileEmpty = false});
  final String? playerId;
  final int? bidTypeCap;
  final int? tradeCargoCapacity;
  final Map<CommodityId, int>? availableStockpileByCommodityId;
  final bool stockpileEmpty;
}
void assertWorldMarketContextBaseExpectation(WorldMarketContextBase ctx, WorldMarketContextBaseExpectation expectation) {
  if (expectation.playerId != null) {
    expect(ctx.playerId, expectation.playerId);
  }
  if (expectation.bidTypeCap != null) {
    expect(ctx.bidTypeCap, expectation.bidTypeCap);
  }
  if (expectation.tradeCargoCapacity != null) {
    expect(ctx.tradeCargoCapacity, expectation.tradeCargoCapacity);
  }
  if (expectation.availableStockpileByCommodityId != null) {
    expect(ctx.availableStockpileByCommodityId, expectation.availableStockpileByCommodityId);
  }
  if (expectation.stockpileEmpty) {
    expect(ctx.availableStockpileByCommodityId, isEmpty);
  }
}
/// Minimal concrete subclass exercising the abstract base constructor.
class TestWorldMarketContextBase extends WorldMarketContextBase {
  const TestWorldMarketContextBase({required super.playerId, required super.bidTypeCap, required super.tradeCargoCapacity, super.availableStockpileByCommodityId});
}
/// One row in [worldMarketContextBaseScenarios].
typedef WorldMarketContextBaseScenario = ({String label, String playerId, int bidTypeCap, int tradeCargoCapacity, Map<CommodityId, int>? availableStockpileByCommodityId, WorldMarketContextBaseExpectation expect, String? refs});
/// Canonical scenarios for [WorldMarketContextBase] field carrying.
List<WorldMarketContextBaseScenario> worldMarketContextBaseScenarios() => [
  (label: 'carries the four shared fields through the constructor', playerId: 'gp1', bidTypeCap: 6, tradeCargoCapacity: 12, availableStockpileByCommodityId: const {'grain': 5, 'silver': 2}, expect: const WorldMarketContextBaseExpectation(playerId: 'gp1', bidTypeCap: 6, tradeCargoCapacity: 12, availableStockpileByCommodityId: {'grain': 5, 'silver': 2}), refs: '#3396'),
  (label: 'availableStockpileByCommodityId defaults to empty when omitted', playerId: 'gp2', bidTypeCap: 0, tradeCargoCapacity: 0, availableStockpileByCommodityId: null, expect: const WorldMarketContextBaseExpectation(stockpileEmpty: true), refs: '#3396'),
];
/// Builds the context for a scenario row.
TestWorldMarketContextBase buildWorldMarketContextBaseScenario(WorldMarketContextBaseScenario scenario) {
  if (scenario.availableStockpileByCommodityId != null) {
    return TestWorldMarketContextBase(playerId: scenario.playerId, bidTypeCap: scenario.bidTypeCap, tradeCargoCapacity: scenario.tradeCargoCapacity, availableStockpileByCommodityId: scenario.availableStockpileByCommodityId!);
  }
  return TestWorldMarketContextBase(playerId: scenario.playerId, bidTypeCap: scenario.bidTypeCap, tradeCargoCapacity: scenario.tradeCargoCapacity);
}
// dart format on
