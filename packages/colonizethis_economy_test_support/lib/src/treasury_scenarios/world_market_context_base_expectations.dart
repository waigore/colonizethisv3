// Compact WorldMarketContextBase assertions (Refs #3939 phase 3 slice 19).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [WorldMarketContextBase] scenario rows.
// dart format off
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
// dart format on
