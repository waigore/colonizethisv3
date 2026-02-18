# Tech Tree Catalog

**SPEC/game** — Full technology catalog derived from Imperialism II 08-technology. Overview: [tech-tree.md](tech-tree.md). Each tech has: **id** (slug), **display name**, **era** (1–4), **category**, **prerequisite ids**, **effects** (extraction/transport/regiment/civilian/diplomatic/labour as applicable).

---

## Structure

Effects are structured per tech type:

- **Gathering:** Max improvement level for a resource (e.g. timber 2, grain 3). Builders/Engineers apply improvements; effective yield is capped by tech and transport.
- **Transport:** Allows building road level 2 (Road Construction) or railroad (Early Steam Engine, Later Steam Engine, Dynamite). Player action required; ports and railroads both give transport level 4.
- **Regiment:** Unlocks buildable regiment id(s). No era gate; buildable iff unlocking tech researched.
- **Civilian:** Unlocks unit type (e.g. Merchant, Rail Builder).
- **Diplomatic:** Unlocks option (embassies, Join Empire, etc.).
- **Labour:** Worker tier, trade slots, fourth research slot (University).

Implementation: colonizethis_data holds the canonical catalog (ids, names, eras, categories, prerequisites, costs, effect payloads). Program code and show_tech tool read from that source.

---

## Category Sub-Docs

Full tables per category (≤500 words each):

| Category | Doc | Contents |
|----------|-----|----------|
| Gathering and Production | [tech-tree-gathering.md](tech-tree-gathering.md) | Old World extraction techs: grain, timber, ore, coal, livestock, precious metals/gems. |
| Transport and Infrastructure | [tech-tree-transport.md](tech-tree-transport.md) | Road Construction, Early/Later Steam Engine, Dynamite; transport level 2/4. |
| Labour and Economy | [tech-tree-labour-economy.md](tech-tree-labour-economy.md) | Apprentice/Journeyman/Master, Money Lending, Banking, Trade Fairs, University. |
| Diplomacy and Civilian | [tech-tree-diplomacy-civilian.md](tech-tree-diplomacy-civilian.md) | Diplomatic Expertise, Merchant Companies, National Bureaucracy, Propaganda, Nationalism, Empire Building. |
| Naval (Merchant and Warships) | [tech-tree-naval.md](tech-tree-naval.md) | Ship types: Fluytes, Trader, Galleons, Sloops, Frigates, Ships-of-the-Line, Ironclads, etc. |
| Military (Infantry, Cavalry, Artillery) | [tech-tree-military.md](tech-tree-military.md) | Regiment unlocks per [military-units.md](military-units.md); artillery and fort levels. |
| New World Resources | [tech-tree-new-world.md](tech-tree-new-world.md) | Discovery + improvement techs for sugar, tobacco, cotton, furs, spices, precious metals/gems. |

---

## Prerequisite and Unlock Rules

- A tech is **researchable** only when all of its prerequisite tech ids are in the player’s techUnlocked set.
- Regiment **buildability**: player can build a regiment iff the tech that unlocks that regiment (see [tech-tree-military.md](tech-tree-military.md)) is in techUnlocked. Military level for minor parity is derived from the set of buildable regiment types (highest era among them).
- Extraction cap per resource/improvement type is the maximum level granted by any researched tech in the catalog (see [tech-and-extraction-cap.md](tech-and-extraction-cap.md)).
