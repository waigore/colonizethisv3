# Seed-42 World-Market lock-recovery diagnostic — initial findings

Captured against `dev` for issue #2924. Refresh with:

```bash
(cd packages/colonizethis_ai && dart test \
    test/seed42_observer_world_market_diagnostic_test.dart \
    --run-skipped)
```

Copy the `WM2924_DIAGNOSTIC_JSON_BEGIN/END` block into a fresh comment on #2924
if the failing link shifts after a Path F tuning slice lands.

## Initial findings (2026-06-01 against `dev` @ `d75d4f42d`)

First run with the world-market phase active produced these per-GP 100-turn rollup
numbers (treasury units; commodity quantities in stockpile units):

| GP  | offers | offerQty | bids | dealsSell | credSell | dealsBuy | zeroBidCap | turnsUnder |
|-----|--------|----------|------|-----------|----------|----------|------------|------------|
| gp1 |    100 |    6 256 |    0 |         0 |        0 |        0 |        100 |         98 |
| gp2 |    179 |    7 856 |    0 |         0 |        0 |        0 |        100 |         98 |
| gp3 |    100 |   15 762 |    0 |         0 |        0 |        0 |        100 |         98 |
| gp4 |    100 |   11 106 |    0 |         0 |        0 |        0 |        100 |         98 |
| gp5 |    100 |   16 104 |    0 |         0 |        0 |        0 |        100 |         98 |
| gp6 |    100 |   39 750 |    0 |         0 |        0 |        0 |        100 |         98 |

Decomposition by chain link:

* **Goal bias F6** — fires correctly. `firstTurnTreasuryCrossesCheapest=1` for every GP
  reflects the seeded starting treasury; from turn 2 onward treasury collapses below
  `cheapestRegimentBuildTreasuryCost` (2000) and stays there for 98 / 100 turns per GP.
  `turnsZeroTradeCargo=0` across the board, so the suggester precondition for offers is met.
* **TreasuryPlanner F1–F5 + F8 — offer emission works.** Every GP emits at least one
  urgent offer every turn (gp2 emits 179 because its starting stockpile holds two surplus
  commodities at once for parts of the run). The top offer commodity for every failing GP is
  `grain` (gp3 15 762, gp4 11 106, gp5 16 104, gp6 39 750).
* **TreasuryPlanner bid emission does not fire.** `cumulativeBidsEmitted=0` for every GP
  because `worldMarketBidTypeCap == 0` on every turn (`turnsZeroBidTypeCap=100` per GP). Per
  `SPEC/ai/treasury-planner.md` § Priority and cargo and per the `worldMarketBidTypeCap`
  implementation, the bid-side cap depends on the GP having at least one embassy overture;
  the seed-42 campaign under the current AI never establishes a GP↔GP embassy across the
  100-turn EXPAND-phase horizon.
* **Deal matching collapses to zero.** With every GP submitting only offers and nobody
  submitting bids, `cumulativeDealsAsSeller=0` and `cumulativeDealsAsBuyer=0` for every GP.
  The carry-forward queue fills with unfilled offers but never clears.
* **Treasury credited from world market sales = 0.** Path F never puts a single treasury
  unit into any GP's account on seed 42 — the chain breaks before treasury can recover. This
  is the same bottom-line outcome as the Step-0 baseline, now decomposed to the exact failing
  link.

**Headline:** Path F is liquidity-starved on seed 42, not surplus-starved or cargo-starved.
The failing link is not the TreasuryPlanner offer-side surplus / cargo logic; it is the
**bid-side embassy gate** (`worldMarketBidTypeCap`) which is zero for every GP for the full
100-turn EXPAND-phase horizon, so no demand exists for the offers the planner aggressively
emits. The next tuning slice should target the bid-side market liquidity gap (for example: AI
diplomacy that opens embassies earlier under the lock predicate, a no-embassy fallback path
for emergency lock-recovery bidding, or extending the world market to include minor / tribe
auto-bids per #2991) rather than further tuning the urgent-offer threshold or the F8
fill-rate discount. Affordability is **not** bypassed anywhere in this finding.

## Refreshed findings (2026-06-03 against `dev` @ `3199fcd09`)

Re-run after the bid-side liquidity tuning the 2026-06-01 finding called for landed:
phase-13 minor / tribe auto-bids + seller-priority matching (F15, #3157), the F16
urgent-offer tier-alignment fix (#3183), and the faithful Full-AI handoff pin (#3174). The
failing link has shifted — the lock-recovery chain now credits treasury on seed 42:

| GP  | offers | offerQty | bids | dealsSell | credSell | dealsBuy | zeroBidCap | turnsUnder |
|-----|--------|----------|------|-----------|----------|----------|------------|------------|
| gp1 |     96 |      115 |    7 |        91 |    1 381 |        2 |          0 |         93 |
| gp2 |    137 |      152 |    2 |        96 |    1 456 |        0 |          0 |         98 |
| gp3 |     82 |      462 |   36 |        58 |    3 757 |       32 |          0 |         56 |
| gp4 |     96 |      323 |   11 |       104 |    4 076 |        3 |          0 |         87 |
| gp5 |     82 |      588 |   32 |        72 |    5 812 |       86 |          0 |         63 |
| gp6 |     84 |      842 |   32 |        72 |    9 538 |       26 |          0 |         67 |

Decomposition by chain link (contrast with the 2026-06-01 table above):

* **Bid-side liquidity gate is now open.** `turnsZeroBidTypeCap` is `0` for every GP (was
  `100`). The phase-13 minor / tribe auto-bids (F15, #3157) supply the buy-side demand that
  the prior embassy-gated run lacked, so the suggester's bid precondition is met every turn.
* **Deals clear.** `cumulativeDealsAsSeller` is now `58`–`104` per GP (was `0`), and
  `cumulativeBidsEmitted` is positive for every GP (gp3 `36`, gp5 `32`, gp6 `32`).
* **Treasury is credited from market sales.** `cumulativeTreasuryCreditedAsSeller` rose from
  `0` to `1 381`–`9 538` per GP; the four failing GPs gp3–gp6 each earn `3 757`–`9 538`
  treasury legitimately through the market over the 100-turn horizon.
* **Below-threshold pressure relaxed.** `turnsTreasuryUnderCheapestRegiment` fell from `98`
  for every GP to `56` (gp3), `87` (gp4), `63` (gp5), `67` (gp6) — gp3 now spends 44 / 100
  turns at or above the `2 000` regiment-build threshold. gp4 remains the weakest of the four.
* **Smaller per-turn offer quantities** (e.g. gp6 `842` vs the prior `39 750`) reflect a
  *working* market: offers now clear into deals each turn instead of piling up unmatched in
  the carry-forward queue.

**Headline:** Path F is no longer the failing link on seed 42. The lock-recovery chain
(`StrategicGoal.trade` floor F6 -> `runTreasuryPlanner` surplus / offers F1-F5/F8 ->
phase-13 minor auto-bids / F15 -> credited treasury) now redistributes treasury to the
failing GPs without any affordability bypass. The residual gap — gp4 still below the
regiment threshold for 87 / 100 turns — is bounded by the § "Conservation bound on Path F"
insight: market trade redistributes but cannot grow the aggregate Great-Power treasury pool,
so full closure of #2924's all-four gate now depends on a net treasury source outside the
market (Path E NW riches conversion) and/or downstream build / conquest conversion (#2925),
rather than further Path F offer / bid tuning. Affordability is **not** bypassed anywhere in
this finding.
