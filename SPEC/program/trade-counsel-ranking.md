# Trade Counsel ranking

**SPEC/program** — Shared human Trade Counsel emission and ranking API (Refs #4282).

## Package ownership

| Surface | Package | Path |
|---------|---------|------|
| Need analysis, bid emission, DTOs | `colonizethis_economy` | `lib/src/economy/trade_counsel/` |
| `emitTradeCounselBook`, `rankTradeCounselRecommendations` | `colonizethis_orders` | `lib/src/orders/trade_counsel_*.dart` |
| App contract export | `colonizethis_logic` | `lib/trade_counsel_api.dart` |

## Rules

- Human counsel uses the **neutral treasury emission path**: F1–F5 surplus/need maps, F10 speculative bids when `treasury >= treasuryAffluenceThreshold()`, standard cargo · bid-type · treasury clamps, boycott-aware bid suppression.
- **Exclude** lock-recovery seller/buyer scripts, regiment bootstrap carve-outs, supplier offer-tier alignment, and trade-deal relation-boost preference (AI-only snapshot).
- Full book: offers then bids, validator-clean via `TradeOrderSuggester`.
- Highlights: global top ≤3 by `rankScore`, then stable id (`bid:<commodityId>` / `offer:<commodityId>`).
- **Apply:** replaces entire `tradeOrdersByPlayerId[human]`.
- **Agree:** stages one line via `applyTradeOrderForPlayer` (mutual exclusion on commodity).

## AI alignment

`colonizethis_ai` `treasury_planner_emit_input.dart` may delegate shared need-analysis helpers to `colonizethis_economy` trade counsel modules when refactored; human counsel must match AI emission for the same inputs when no lock-recovery state is active.

`tool/check_logic_ai_decoupling.sh` rejects `colonizethis_ai` in `colonizethis_logic`, `colonizethis_economy`, and `colonizethis_orders` pubspecs.
