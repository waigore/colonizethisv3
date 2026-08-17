# Commerce and the World Market

## Purpose

A **Great Power** is a playable nation. The **world market** is the one shared place where those nations buy and sell goods for treasury. A **bid** is a buy you stage this turn. An **offer** is a sale you stage this turn. **Minor Nations** and **Tribes** do not place bids; the game lists what they extract as sales. When your storehouses hold more timber than you can use, or you lack coal for industry, tap **Trade** and stage bids and offers. Mastery here smooths shortages, funds wars, and rewards a **Merchant** who has bought a foreign tile (Chapter 6). This chapter covers bids, offers, the three-bid limit, first right of refusal, and `GAME60001` **Trade screen**.

## How it is done

### What clears on the market

- There is one world market for every Great Power, Minor Nation, and Tribe. You do not draw trade routes on the map.
- Cargo for buys comes from leftover holds on your home fleet after overseas extraction has already shipped. Only bids use that leftover cargo; offers do not consume holds.
- Tradeable goods are food, raw materials, and manufactured goods. Gold, silver, gems, diamonds, and spices do not appear as trade rows; they turn into treasury after you confirm **Next turn** (riches, not market goods).
- You stage a bid or an offer: the good, how many, and (until a priority control ships) the default rank. Minor Nations and Tribes never bid. After you confirm **Next turn**, the game lists what they extracted as sales and then matches buys and sales.

### Caps and rules that protect the realm

- On one good in one turn you may bid or offer, not both.
- You may bid on **three** different goods each turn unless you have researched **Trade Fairs**, which raises that limit to **six**. An embassy does not change this limit. Offers have no such count limit.
- Bid amounts cannot exceed leftover trade cargo. Offer amounts cannot exceed what will remain after industry takes its reserved inputs.
- Total bid spend (quantity times the integer price shown) cannot exceed leftover treasury after other staged spending. On the Market tab, **Bid** and **+** refuse the extra unit when that budget is full; the header may show **Treasury bid limit reached**.
- The Market header shows **Bid goods: U of C**, **Cargo remaining: X**, and **Bid budget: R of B**. Tap **?** beside a limit for a short explanation.
- Unfilled bids and offers can stay open next turn if cargo or stock still covers them. Minor and Tribe auto-sales do not stay open; they are listed again from that turn’s extraction.

### First right of refusal and friends

If a Merchant finished **Purchase land** on a Minor Nation or Tribe tile, that land’s sales still list under the Minor or Tribe, but you keep three privileges:

1. **Bid priority** — your bid on that good is filled from that tile’s sale before ordinary rank and before **Favored Trading Partner**.
2. **Overseas profit** — when another Great Power buys those goods, you receive a treasury share that grows with how friendly that court is toward the seller (hidden relation). Other Great Powers that hold an **Embassy** with the seller may receive a smaller share (one tenth of their relation portion), even if they do not own the tile. Embassy holders can still receive that smaller share on Minor or Tribe sales when no tile was purchased.
3. **Riches** from a purchased gold, silver, gems, diamonds, or spices tile go into **your** treasury, not the Minor’s.

**Favored Trading Partner** is a diplomacy agreement that only breaks ties inside the same bid rank when a Great Power sells; it never beats first right of refusal.

When a Minor Nation or Tribe sells and several Great Powers bid at the same rank (after first-right fills), buyers who hold a **Consulate** or higher with that seller are served first, then by hidden relation. Great-Power sellers keep the ordinary order. This never beats first right of refusal either.

A **subsidy** you set toward a Minor Nation or Tribe (Chapter 10) does not pay them each turn. Deals between you and that court are cheaper when you sell to them and dearer when you buy from them, by the subsidy percent.

A **boycott** (Chapter 10) can leave bids and colony-Tribe sales between the boycotted Great Power and the issuer’s colony Tribes unfilled, in both directions.

### Where you act in the UI

1. On `GAME10001` **Game screen**, tap the **Trade** icon on the left of the map to open `GAME60001` **Trade screen**.
2. Stay on the **Market** tab. Goods are grouped under **Food**, **Raw Materials**, and **Manufactured**.
3. On a row, tap **None**, **Bid**, or **Offer**, then use **−** / **+** to set quantity. Bid and offer cannot both be on for the same good.
4. Watch **Bid goods: U of C**, **Cargo remaining: X**, and **Bid budget: R of B**. Tap **?** beside a limit for a short explanation.
5. Each row shows the integer price; when last market moved that price, **+£N** or **−£N** appears under it — rest on it (or press and hold) to read that this turn’s deals use the price shown.
6. The muted line **Last turn: bids N · offers M** is last turn’s market volume, not your staged orders.
7. A number in parentheses **(N)** beside the name is how many you can still offer after industry reservations and staged offers.
8. When you still hold first right on that good, **First right** appears beside the name — rest on it (or press and hold) for bid priority and overseas profit. Riches never appear as rows.
9. On **Deal Book**, read **Your bids** and **Your offers**. Filled lines sit under **Filled** as **Timber — 5 at £30 = £150** (display name, not a catalog id). Leftovers sit under **Still open** as **Timber — 5**. Filled lines may show **First right** or **Favored partner**. When rivals bought goods under your purchased-tile rights last turn, **Overseas profit** lists each credited good, quantity, and treasury amount. Totals are **Total spent** and **Total received**. Empty panels read **No bids placed last turn.** / **No offers placed last turn.**
10. On `GAME20001` **Production screen**, the **Available** amounts for tradeable goods already match the Market **(N)** figure — they are not a separate labelled readout.
11. After you confirm **Next turn**, the game matches deals. Confirm fills on Deal Book and on `OVL70001` **Player turn event feed**. Market lines look like **Market: bought £240 · sold £160**. Overseas-profit lines look like **Overseas profit credited: £… Tap to open Deal Book.** Tap either kind of line to open Deal Book. Do not look to turn news for market fills.

### Trade Counsel

1. On the Market tab, tap **Counsel** in the header (or a ★ on a highlighted good) to open `GAME90001` **Counsel screen** on the **Trade** tab.
2. The vizier lists the full ordinary market book it would stage for your court this turn — surplus offers, shortage bids, and (when treasury is rich enough) extra inventory bids — using your stores, production plan, treasury, cargo, and other staged costs. Extra wartime recovery shortcuts only rivals use are **not** included.
3. At most three lines are starred on both Counsel and Market; each line shows Bid or Offer, the good’s name, quantity, and a short reason.
4. **Apply recommended market book** replaces **all** your staged trade orders with that list.
5. **Agree** on one line stages only that good (and clears the opposite direction on the same good).
6. Empty counsel: “No pressing market advice this turn.” Apply and Agree are hidden while the game is carrying out the turn, same as Industry Counsel.

## Counsel

**Counsel.** Hark, my liege: a bid without cargo is a promise the fleet cannot keep — leave holds for extraction first, then for the market.

**Tip.** You may bid on up to **three** distinct commodities each turn by default; research **Trade Fairs** to raise the limit to six. The Market header shows **Bid goods: U of C** and a **?** beside each limit line for a short explanation.

**Tip.** **Bid budget: R of B** shows how much treasury you can still commit to bids this turn after other staged spending. When the treasury bid limit is reached, free gold or trim other orders before bidding more; tap the **?** beside the budget line for a short explanation.

**Tip.** A per-row priority control is not yet on the Market tab; staged orders use the default rank until that control ships.

**Tip.** Trade Counsel on `GAME90001` **Counsel screen** drafts the ordinary book a rival would stage in your place — apply it, then trim or override rows on Market before you tap **Next turn**.

**Warning.** Selling the last timber you still assigned to lumber on `GAME20001` **Production screen** invites a refused offer or a silent industry stall. Watch the **(N)** figure on Market and the matching **Available** number on Production.

## The other courts

When a rival court’s treasury runs low, it leans toward the market: sell surplus, buy shortages, and stay inside cargo and diplomatic limits. A boycott can stop some of those bids. A recent trade can make a court prefer a friend. Expect broke rivals to list many sales, and cash-rich ones to bid for the feedstock you also need.

## Consequences

- Ignoring the market while you overproduce raw goods leaves coin on the table and lets rivals buy the shortages you created.
- Purchasing land without bidding on that tile’s good cedes the fill — but you may still earn overseas profit when others buy.
- A boycott can leave bids and colony sales unfilled between the boycotted Great Power and the issuer’s colony Tribes.
- A subsidy toward a Minor or Tribe (Chapter 10) makes your deals with that court cheaper when you sell and dearer when you buy, by the subsidy percent — with no separate per-turn payment.
- After fills, the next-turn price moves by about half the gap between new bids and new offers, never more than 20% either way, and never below 30% of that good’s default price. Deals this turn clear at the **old** integer price; the new price applies next turn.

## Acceptance criteria for this chapter

- [x] Explains the one global market, tradeable goods vs riches, bid vs offer, and that fills appear after **Next turn**.
- [x] Documents one-direction-per-good, the 3/6 bid-count limit, cargo and treasury limits, and leftover orders.
- [x] Covers first right / overseas profit / Favored Trading Partner at player level (Market **First right**, Deal Book tags and overseas-profit list, feed deep-link).
- [x] Documents operable `GAME60001` **Trade screen** (left-side **Trade** icon, Market + Deal Book, printed cap lines) and notes the deferred priority control in Counsel.
- [x] Documents `GAME90001` **Counsel screen** Trade tab: Market entry, Apply full book, per-line Agree, empty state.
- [x] Notes Production **Available** numbers matching Market **(N)**.
- [x] Sources match the chapter coverage map, including the event-feed path.

## Sources

- `SPEC/game/world-market.md`
- `SPEC/game/world-market-first-right-of-refusal.md`
- `SPEC/game/commodity-catalog.md`
- `SPEC/game/diplomacy.md`
- `SPEC/program/orders.md`
- `SPEC/program/turn-resolution-phases.md`
- `SPEC/program/world-market-resolution.md`
- `SPEC/ui/trade-screen.md`
- `SPEC/ui/counsel-panel.md`
- `SPEC/program/trade-counsel-ranking.md`
- `SPEC/ui/production-panel.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ui/empire-buttons.md`
- `SPEC/ui/player-turn-event-feed.md`
- `SPEC/ai/treasury-planner.md`
- `SPEC/ai/economy-planner.md`
