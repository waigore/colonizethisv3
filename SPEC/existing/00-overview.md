# Imperialism II: Age of Exploration — Game Design Document

## Document Map

This design document extracts and synthesizes the full game design from the Imperialism II manual. It is organized into the following sections:

| Section | Description |
|---------|-------------|
| [01. Game Fundamentals](01-game-fundamentals.md) | Political structure, Old vs New World, provinces, turn resolution order, Orders screens, terrain map, cursors |
| [02. Economy](02-economy.md) | Transport levels, production, warehouse, trade screen, commodities, money supply |
| [03. Civilian Units](03-units-civilian.md) | Explorer, Builder, Engineer, Spy, Merchant, Rail Builder; cursors; terrain development table |
| [04. Naval Units](04-units-naval.md) | Fleet orders, missions (patrol, blockade, landings), ship types, convoying |
| [05. Military Forces](05-units-military.md) | Regiment categories, Army Book, movement, experience, unit stats table |
| [06. Combat](06-combat.md) | Strategic vs tactical resolution, deployment, forts, sieges, attacking and defending |
| [07. Diplomacy](07-diplomacy.md) | Civilians abroad, embassies, overtures, treaties, peaceful joining, colonies |
| [08. Technology](08-technology.md) | Research screen, slots, goals, spy flags; full technology tree with benefits and prerequisites |
| [09. Strategy](09-strategy.md) | Grand schemes, New World approach, internal development |
| [10. Appendix](10-appendix.md) | Hot keys, quick reference tables |

---

## Game Purpose

In Imperialism II: Age of Exploration you rule one of the colonial powers of Europe in the period 1500–1850. Your goal is **military or diplomatic domination of the Old World**.

The colonial and mercantile periods did not witness the rapid industrial changes of the nineteenth century. Players must focus on establishing colonies, conquering or befriending native populations, and developing their nations using the riches and commodities found only in the New World. Once these benefits are brought home, your Great Power can attempt to dominate the greater and lesser states of the Old World.

Since the New World does not directly help a Great Power win, good players tend to invest in New World development only so far as it leads to greater power in the Old World. **This is the model for victory appropriate to the era.**

---

## Win Conditions and Loss Conditions

### Victory

Victory in Imperialism II is obtained by **control of the Old World**. The number of provinces each player owns measures this control. When one player controls **one more than half** of all the Old World provinces in the game, that empire is victorious and the game ends.

- Control can be gained by **conquest** or by **economic and diplomatic successes**
- In most games the required total is slightly more than 30 Old World provinces (the Old World usually contains around 60 provinces)
- The exact number required varies depending on the map; you can find it using the Diplomacy screen (see [07. Diplomacy](07-diplomacy.md))

### Loss

**If you lose your capital, the game ends.** There is no recovery. The most dire advisor warnings involve the safety of the capital and cannot be disabled.

---

## The Two-Region Model

### Old World

- Made up of Great Powers and Minor Nations whose provinces **count toward victory**
- Great Powers: the six player-controlled empires (human or computer)
- Minor Nations: regions for exploitation and battle; cannot become Great Powers or win
- All worlds contain **six Great Powers** and **six Minor Nations**

### New World

- **Hidden from view** at the beginning of the game
- Provinces of the New World **do not count toward victory**
- Contains **ten Tribes**; Tribes are exploited (economically or militarily) because they contain resources not found in the Old World
- Riches found in the New World lead successful rulers to control of the Old World
- Tribes never develop into Great Powers and cannot win the game

See [01. Game Fundamentals — Political Organisation](01-game-fundamentals.md#political-organisation-in-imperialism-ii) for full details.

---

## Core Game Loop

1. **Exploration** — Uncover the New World to conduct trade, diplomacy, or war. See [03. Civilian Units — Explorer](03-units-civilian.md) and [04. Naval Units](04-units-naval.md).
2. **Development** — Use Builders, Engineers, and Merchants to develop terrain at home and abroad. See [02. Economy](02-economy.md) and [07. Diplomacy — Peaceful Control](07-diplomacy.md).
3. **Economy** — Transport commodities, produce materials, trade for cash and scarce resources. Riches (spices, silver, gold, gems, diamonds) convert to cash when brought to the capital. See [02. Economy](02-economy.md).
4. **Military and Diplomacy** — Conquer provinces or persuade nations to join your empire peacefully. See [06. Combat](06-combat.md) and [07. Diplomacy](07-diplomacy.md).
5. **Technology** — Invest in research to unlock new units, improvements, and capabilities. See [08. Technology](08-technology.md).

---

## Key Constraints

- **Food** — Everyone (army, navy, laborers) must eat 1 unit of meat or grain every turn. Agriculture limits the size of your force. See [02. Economy — Feeding Workers](02-economy.md).
- **Cash** — No taxation. Money comes from trade, riches, and overseas profits. Offensive attacks cost significant cash. See [02. Economy — Money Supply](02-economy.md).
- **Sea Transport** — Anything moving across water uses ship cargo holds. Ships are shared among transport, trade, and naval missions; they can be intercepted. See [02. Economy — Transport](02-economy.md) and [04. Naval Units](04-units-naval.md).
- **New World Resources** — Sugar, tobacco, and furs are required for trained workers. Labor force training is limited by New World resource acquisition. See [02. Economy](02-economy.md) and [08. Technology](08-technology.md).

---

## Time Progression

- **Period:** 1500–1850
- **1500–1700:** Each turn represents two years
- **1700 onwards:** Each turn represents one year
- Each new turn begins with a Turn Summary of events from the last turn

---

## See Also

- [01. Game Fundamentals — Turn Resolution Order](01-game-fundamentals.md#turn-resolution-order) for the exact sequence of events when a turn is processed
- [01. Game Fundamentals — Orders Screens](01-game-fundamentals.md#orders-screens) for the Transport, Industry, Trade, Diplomacy, and Technology screens
- [09. Strategy](09-strategy.md) for grand scheme ideas and strategic approaches
