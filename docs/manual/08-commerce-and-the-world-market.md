# Commerce and the World Market

## Purpose

When your warehouse overflows with timber or starves for coal, the **world market** lets Great Powers bid treasury for goods and offer surplus for coin. Minors and Tribes auto-sell what they extract. Mastery here smooths shortages, funds wars, and rewards Merchants who purchased foreign tiles. This chapter explains bids, offers, caps, first right of refusal, and how to stage trade at the dedicated Trade desk.

## How it is done

### What clears on the market

- One **global** market for every Great Power, Minor, and Tribe. No player-drawn trade routes; cargo still uses home-fleet holds after overseas extraction takes its share.
- **Tradeable** commodities: food, raw materials, and manufactured goods from the catalog — **not** riches (`gold`, `silver`, `gems`, `diamonds`, `spices`), which convert to treasury in Riches-to-treasury instead.
- Great Powers submit **`TradeOrder`** rows: `bid` or `offer`, commodity, quantity, priority (1 = highest tier). Minors/Tribes never bid; their extraction becomes system offers in **Phase 13 World Market**.

### Caps and rules that protect the realm

- **Mutual exclusion:** for a given commodity in one turn you may bid **or** offer, not both.
- **Bid-type cap:** by default **1** distinct commodity bid; **3** with at least one embassy; **6** with embassy and `trade_fairs`. Offers are uncapped by that rule.
- **Quantity:** bids limited by remaining **trade cargo**; offers limited by projected stockpile after industry reservations.
- **Treasury bid budget:** total bid spend (`quantity × current integer price`) cannot exceed treasury after other pending costs (builds, recruits, work, subsidies). Over-budget bids are rejected.
- Unfilled bids/offers may **carry forward** when stockpile/cargo still cover them; minor auto-offers do not carry.

### First right of refusal and friends

If a Merchant completed `purchase_land` on a Minor/Tribe tile, that tile’s auto-offers still list under the Minor/Tribe, but **you** enjoy:

- **Bid priority** on that commodity against the purchased-tile offer (above ordinary priority and Favored Trading Partner tie-breaks).
- **Overseas profit** when another GP buys those goods (relation-linear share for the tile owner; embassy holders may receive a smaller kickback — see Sources).
- **Riches handoff** on purchased riches tiles into **your** treasury (not the Minor’s).

**Favored Trading Partner** (diplomacy) only breaks ties inside the same priority tier; it never overrides first right of refusal.

### Where you act in the UI

1. From `GAME10001`, tap **Trade** on the left empire rail (or open route `/game/trade`) to reach `GAME60001` **Trade screen**.
2. **Market** tab: for each tradeable commodity, choose **None / Bid / Offer**, set quantity with the steppers, and watch **Bid goods: U of C** (distinct bid commodities vs your cap), **Cargo remaining**, and **Bid budget: R of B** (treasury headroom for bids after other pending costs). Bid and offer are mutually exclusive per commodity; staged bids respect bid-type, cargo, and treasury caps from the rules above. Riches never appear as trade rows.
3. **Deal Book** tab: review last-turn filled buys/sales and any carry-forward unfilled orders for your court.
4. Production (`GAME20001`) shows **sellable headroom** on tradeable stockpile lines so you do not offer what industry still needs.
5. Market clearance still resolves in **Phase 13**; after you end the turn, confirm fills in Deal Book, turn news, and market activity.

## Counsel

**Counsel.** Hark, my liege: a bid without cargo is a promise the fleet cannot keep — leave holds for extraction first, then for the market.

**Tip.** Embassy and `trade_fairs` multiply how many commodities you may chase in one turn. The Market header shows **Bid goods: U of C** so you see the limit before you end the turn — diplomacy is market infrastructure.

**Tip.** **Bid budget: R of B** shows how much treasury you can still commit to bids this turn after other staged spending. When the treasury bid limit is reached, free gold or trim other orders before bidding more; tap **Why this limit?** under the budget line for a short explanation.

**Tip.** A per-row priority dropdown is not yet on the Market tab; staged orders use the default priority until that control ships.

**Warning.** Selling the last timber you still assigned to lumber on `GAME20001` invites rejected offers or a silent industry stall. Watch sellable headroom.

## The other courts

AI Great Powers bias the **trade** strategic goal when treasury is low and use a **treasury planner** layered on the economy planner to buy deficits and sell surplus within cargo and diplomatic constraints (`SPEC/ai/treasury-planner.md`, `SPEC/ai/economy-planner.md`). Boycotts and relation boosts can suppress or prefer certain bids. Expect broke rivals to flood the market with offers and cash-rich ones to contest your feedstock.

## Consequences

- Ignoring Phase 13 while overproducing raw goods leaves coin on the table and lets rivals buy the shortages you created.
- Purchasing land without bidding on “your” commodity cedes the fill — but you may still earn overseas profit when others buy.
- Price discovery moves after fills (about half the bid–offer imbalance, capped ±20%, floor near 30% of default). Deals clear at the **old** integer price; the new price applies next turn.

## Acceptance criteria for this chapter

- [ ] Explains global market, tradeable vs riches, TradeOrder bid/offer, Phase 13 timing.
- [ ] Documents mutual exclusion, bid-type caps (1/3/6), cargo and treasury caps, carry-forward.
- [ ] Covers first right of refusal / overseas profit / FTP at player level.
- [ ] Documents operable `GAME60001` Trade (left-rail / route entry, Market + Deal Book, caps) without a draft-screen marker; notes any deferred control separately.
- [ ] Notes Production sellable headroom linkage.
- [ ] Sources match the chapter coverage map.

## Sources

- `SPEC/game/world-market.md`
- `SPEC/game/world-market-first-right-of-refusal.md`
- `SPEC/game/commodity-catalog.md`
- `SPEC/game/diplomacy.md`
- `SPEC/program/orders.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/world-market-resolution.md`
- `SPEC/ui/trade-screen.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/treasury-planner.md`
- `SPEC/ai/economy-planner.md`
