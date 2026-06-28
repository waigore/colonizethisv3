// Market-tab commodity-section callback factory. SPEC/ui/trade-screen.md.
//
// Refs #3546 — app/ deduplication slice. The World Market Trade screen rendered
// three commodity sections (Food, Raw Materials, Manufactured) and inlined a
// verbatim `onDirectionChanged` / `onQuantityDelta` closure pair under each
// one. The only per-invocation difference was the lazily-read projected
// treasury delta; the binding to the shared per-build order context was
// identical across all three sections. This factory builds the pair once so the
// duplication collapses to a single call site.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Fired when a Market-tab commodity row toggles its trade direction.
typedef TradeDirectionChanged = void Function(
  CommodityId commodityId,
  TradeOrderType? next,
);

/// Fired when a Market-tab commodity row steps its staged quantity by [delta].
typedef TradeQuantityDelta = void Function(
  CommodityId commodityId,
  int delta,
);

/// The `(onDirectionChanged, onQuantityDelta)` pair every Market-tab commodity
/// section is rendered with.
typedef TradeSectionHandlers = ({
  TradeDirectionChanged onDirectionChanged,
  TradeQuantityDelta onQuantityDelta,
});

/// Builds the shared [TradeSectionHandlers] pair for the Market tab, replacing
/// the three verbatim closure pairs previously inlined per commodity section
/// (Refs #3546).
///
/// The projected treasury delta is read **lazily** through
/// [readProjectedTreasuryDelta] each time a row fires — not when the handlers
/// are built — so the value reflects the latest treasury projection at the
/// moment of interaction, preserving the original per-invocation read
/// semantics. [handleDirectionChanged] and [handleQuantityDelta] receive that
/// freshly-read delta alongside the row's own arguments.
TradeSectionHandlers buildTradeSectionHandlers({
  required int? Function() readProjectedTreasuryDelta,
  required void Function({
    required CommodityId commodityId,
    required TradeOrderType? next,
    required int? projectedTreasuryDelta,
  }) handleDirectionChanged,
  required void Function({
    required CommodityId commodityId,
    required int delta,
    required int? projectedTreasuryDelta,
  }) handleQuantityDelta,
}) {
  return (
    onDirectionChanged: (CommodityId commodityId, TradeOrderType? next) =>
        handleDirectionChanged(
          commodityId: commodityId,
          next: next,
          projectedTreasuryDelta: readProjectedTreasuryDelta(),
        ),
    onQuantityDelta: (CommodityId commodityId, int delta) =>
        handleQuantityDelta(
          commodityId: commodityId,
          delta: delta,
          projectedTreasuryDelta: readProjectedTreasuryDelta(),
        ),
  );
}
