# Tech Tree — Diplomacy and Civilian

**SPEC/game** — Diplomatic options and civilian unit unlocks. Reference: Imperialism II 08-technology (Diplomacy and Civilian). Overview: [tech-tree.md](tech-tree.md). Diplomacy: [diplomacy.md](diplomacy.md). Civilian units: [civilian-units.md](civilian-units.md).

---

## Tech Table

| id | name | era | prerequisites | effects |
|----|------|-----|---------------|--------|
| diplomatic_expertise | Diplomatic Expertise | 1 | — | Offer embassies to Minor Nations; Merchants, Engineers, Builders may work there |
| merchant_companies | Merchant Companies | 1 | — | Construct Merchant units; buy land in Minor Nations |
| national_bureaucracy | National Bureaucracy | 2 | printing_press, money_lending, diplomatic_expertise | Builders may upgrade provincial towns |
| propaganda | Propaganda | 3 | national_bureaucracy, university | Decreases diplomatic penalties for declaring war |
| nationalism | Nationalism | 3 | propaganda, master_artisans, modern_forts | Deployment limit 12 regiments (vs 10); general adds more |
| empire_building | Empire Building | 4 | nationalism, banking | Ask Great Powers to join your empire peacefully |

---

## Effect Semantics

- **Diplomatic Expertise:** Unlocks embassy overture and allows civilian units to work in Minor Nations with embassy.
- **Merchant Companies:** Unlocks building Merchant civilian unit. **Purchasing land** (Merchant `purchase_land` work order) in a Minor Nation or Tribe requires Merchant Companies **and** an **embassy** with that Minor/Tribe (see [diplomacy.md](diplomacy.md), [civilian-units.md](civilian-units.md)).
- **Empire Building:** Unlocks Join Empire (GP can ask another GP to join when nearly defeated). See [diplomacy.md](diplomacy.md).
