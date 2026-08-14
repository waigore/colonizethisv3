# Raising the Banners

## Purpose

A realm without regiments invites its neighbours to decide its borders. Military forces defend your provinces, support conquest, and give your diplomacy weight. Train regiments into the capital’s Home Army, organize them into field armies, then move those field armies where the realm requires them.

## How it is done

### The regiment roster

A regiment is buildable only after its unlocking technology is researched; era alone does not unlock it.

| Branch | Regiment progression | Unlocking technology |
|--------|---------------------|----------------------|
| Light infantry | Peasant Levies → Calivermen → Skirmishers → Sharpshooters | Peasant Levies available at start; Improved Infantry Tactics; Early Rifles; Long Range Rifles |
| Regular infantry | Pikemen → Halberdiers → Regulars → Rifle Infantry | Pikemen available at start; Improved Iron Weapons; Bayonet; Needle Guns |
| Heavy infantry | Arquebusiers → Musketeers → Grenadiers → Guards | Arquebusiers available at start; Weapon Craftsmanship; Explosives; Elite Military Training |
| Bowmen | Bowmen | Available at start; no upgrade path |
| Light cavalry | Squires → Cossacks → Hussars → Scouts | Squires available at start; Recruit Steppe Horsemen; Hussars; Scouting |
| Spear cavalry | Knights; Lancers | Knights available at start; Organised Regiments unlocks Lancers. Neither has an upgrade path. |
| Heavy cavalry | Harquebusiers → Cuirassiers → Carbine Cavalry | Improved Cavalry Tactics; Improved Cavalry Weapons; Repeating Cavalry Carbine |
| Light artillery | Horse Artillery → Light Artillery → Field Artillery | Horse Artillery; Light Artillery Tactics; Field Artillery Tactics |
| Heavy artillery | Culverin → Royal Artillery → Heavy Artillery → Siege Guns | Culverin available at start; Siege Engineering; Heavy Artillery; High Grade Steel |

### Training regiments

1. Open **Military units panel** from the Military Units toolbar button.
2. Select **Train** to open **Train military dialog**.
3. Choose unlocked regiments with the row steppers. Each row shows the regiment's **category and combat role** (e.g. melee line, ranged firepower, siege guns) plus **ongoing food upkeep per turn** so you can weigh battlefield role and ownership cost against treasury, materials, and peasant build costs before queuing. The dialog accounts for the combined treasury, materials, and peasant cost of all selected regiments.
4. Close the dialog to queue the training orders. Each regiment consumes one peasant when training resolves, alongside its treasury and material cost.
5. After turn resolution, the new regiments enter the **Home Army** at the capital. They do not appear directly in a field army.

A lack of peasants, materials, treasury, or the required technology prevents training. Military training shares the peasant reserve with worker and naval training, so a full queue in one area can prevent another from being raised.

### Armies and generals

Every land regiment belongs to one army, and an army occupies one province. Armies may contain mixed regiment types. In **Military units panel**, expand an army to inspect its composition, split a non-empty group of regiments into a new army in the same province, or combine armies already stationed together.

Your capital always has a **Home Army**, even when it has no regiments. It receives every newly trained regiment. To create a force that can campaign, split regiments from the Home Army into a field army at the capital.

Generals are commanders rather than map units. Your realm begins with one general; military and national advances can raise the cap to two with Organised Regiments, three with National Bureaucracy or Improved Infantry Tactics, and four with Nationalism. Before combat, generals are assigned to armies fighting that turn. A victorious commanding general gains medals, up to four; medals improve the army’s combat contribution. After a win, the turn news feed may report that a general earned a medal and show the new count.

On **Military units panel**, the **Generals** strip at the top of the land list shows how many generals you have versus your cap, each general’s medals, and a short note that each general can lead one invasion per turn. Tap **Details** for a plain-language summary of what medals do in battle. When you stage more invasions in one turn than you have generals, extra armies still march but fight with weaker command — **Move army dialog** shows a soft warning on invasion destinations without blocking Confirm.

### Moving a field army

1. **From the map:** On **Empire overview / map area**, tap your **army stack marker** in the bottom-right of a town tile. When a field army is there, **Move army dialog** opens (or **Overlay army move picker** first if several field armies share the tile). The Home Army is never a Move choice from that tap. If only the Home Army is present, the tap opens **Military units panel** instead. This does not open **Province sea-zone overlay**. You can still open **Province sea-zone overlay** on a province and tap **Move** when a non-Home field army is stationed there, or **Invade** on a foreign province when a field army can conceivably reach it. If several armies qualify from the overlay, **Overlay army move picker** asks which army acts; then **Move army dialog** opens. **Invade** preselects that province so you need not hunt it again.
2. **From the roster:** In **Military units panel**, select **Move** on a non-Home army.
3. **Move army dialog** lists only destinations that are legal for that army and the current turn’s orders. The dialog body shows **Your army: N regiments** for the army you are moving. When you select an invasion destination, it also shows how many invasions you have staged this turn versus how many generals you have; staging more invasions than generals triggers a soft warning that extra armies fight with weaker command (Confirm stays enabled). If your armies are short on rations this turn, a separate soft line warns that they will fight weaker — again without blocking Confirm. Invasion target rows show defender strength, unopposed capture, and fort/siege risk when your military intel is complete (Spy, full tile visibility, or Spy fog-decay timer); otherwise they show **Defenders unknown**. Select an invasion row to see regiment-type breakdown when intel allows.
4. Your owned provinces may be selected for relocation, including provinces in another region. Enemy, neutral, Minor Nation, or Tribe provinces must be adjacent to the army’s present province and lie in its current region.
5. Confirm the selected destination. If entering another faction’s province would begin a war, confirm the invasion warning; the declaration of war and army move are submitted together.
6. When the turn resolves, every regiment in that army moves with it. The panel shows its pending destination while the order remains in the draft.

The Home Army has no enabled Move control and cannot leave the capital. Split it first if you need a marching force. On **Province sea-zone overlay**, Move may still appear disabled with that plain reminder when only the Home Army is present.

### Military Counsel (**Counsel screen** Military tab)

1. On **Military units panel**, tap **Counsel** in the header to open **Counsel screen** on the **Military** tab.
2. Review up to three ranked recommendations: **raise** regiment or ship types (with count and cost summary) and **invade** targets (army, province, owner, defender intel when known).
3. Tap **Agree** on a train card to queue that many build orders when still affordable; otherwise a plain snackbar explains why nothing was staged.
4. Tap **Agree** on an invade card to stage the army move; when war must be declared first, confirm in the same invasion dialog used by **Move army dialog**.
5. Empty counsel: “No pressing military advice this turn.” Agree is hidden while turn resolution blocks edits.

## Counsel

**Counsel.** Hark, my liege: a regiment raised in the Home Army is a shield, not yet a spear. Split a field army before promising a campaign beyond the capital.

**Warning.** Do not spend every peasant on banners. A regiment consumes one peasant at training, and the same reserve must also sustain your workers and naval ambitions.

**Counsel.** Hark, my liege: an invasion is no quiet march. Choose a hostile province only when you are prepared for the war declaration that accompanies it.

## The other courts

Other Great Powers use deterministic planners to weigh expansion, military rebuilding, diplomacy, and colonial opportunities each turn. Their priorities shift between Old World conquest, colonial acquisition, and development, but they still require legal orders and viable armies. Expect a rival pursuing expansion to raise regiments, form field armies, and seek invadable frontiers; a developing rival may instead favour peace and civilian growth.

## Consequences

- Research determines the regiments available to train; a richer arsenal gives the realm more military options but still requires peasants, treasury, and materials.
- Leaving regiments in the Home Army protects the capital but cannot project force.
- Splitting creates a field army able to relocate or invade, while combining armies concentrates forces already in one province.
- Moving into an eligible foreign province can begin a war before movement resolves, making the diplomatic choice inseparable from the military one.
- Successful battles can improve generals, while too many simultaneous attacks may exceed the number of generals available to command them.
