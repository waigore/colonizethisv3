# Raising the Banners

## Purpose

A realm without fighting strength invites its neighbours to decide its borders. Military forces defend your provinces, support conquest, and give your diplomacy weight. A **regiment** is one land fighting unit. The **Home Army** is the capital force that receives new regiments and cannot leave home. A **field army** is a group of regiments you can send to another province. Train regiments into the Home Army, organize them into field armies, then move those field armies where the realm requires them.

## How it is done

### The regiment roster

A regiment is trainable only after its unlocking technology is researched. Being listed in an age band on the technology list does not unlock it by itself.

| Branch | Regiment progression | Unlocking technology |
|--------|---------------------|----------------------|
| Light infantry | Peasant Levies → Calivermen → Skirmishers → Sharpshooters | Peasant Levies available at start; Improved Infantry Tactics; Early Rifles; Long Range Rifles |
| Regular infantry | Pikemen → Halberdiers → Regulars → Rifle Infantry | Pikemen available at start; Improved Iron Weapons; Bayonet; Needle Guns |
| Heavy infantry | Arquebusiers → Musketeers → Grenadiers → Guards | Arquebusiers available at start; Weapon Craftsmanship; Explosives; Elite Military Training |
| Bowmen | Bowmen | Available at start; no upgrade path |
| Light cavalry | Squires → Cossacks → Hussars → Scouts | Squires available at start; Recruit Steppe Horsemen; Hussars; Scouting |
| Spear cavalry | Knights; Lancers | Knights available at start; Organised Regiments unlocks Lancers. Neither has a clear upgrade path in the current rules (see Counsel). |
| Heavy cavalry | Harquebusiers → Cuirassiers → Carbine Cavalry | Improved Cavalry Tactics; Improved Cavalry Weapons; Repeating Cavalry Carbine |
| Light artillery | Horse Artillery → Light Artillery → Field Artillery | Horse Artillery; Light Artillery Tactics; Field Artillery Tactics |
| Heavy artillery | Culverin → Royal Artillery → Heavy Artillery → Siege Guns | Culverin available at start; Siege Engineering; Heavy Artillery; High Grade Steel |

### Training regiments

1. Open **Military units panel** from the left-side **Military Units** icon (hover to read the name).
2. Select **Train** to open **Train military dialog** (header **Train Military**).
3. Choose unlocked regiments with the **−** and **+** buttons on each regiment row. Each row shows the regiment's **category and combat role** (e.g. melee line, ranged firepower, siege guns) plus **ongoing food upkeep per turn** so you can weigh battlefield role and ownership cost against treasury, goods, and peasant build costs before queuing.
4. When the unlocking technology is missing, the row shows **Requires:** and that technology’s name; you cannot change the count.
5. The dialog accounts for the combined treasury, peasants, and listed goods of all selected regiments — including a **Horses** chip for cavalry types that need horses. The **Peasants** chip shows how many remain free after peasants already promised to queued worker training or ship builds; when some are promised, a short line under the chips names that promise (for example **3 already promised to worker training**). Tap the **Peasants** chip for a short family breakdown. **+** will not raise a count past the free peasant total.
6. Tap outside the dialog (or use system back) to queue the training. There is no Close button. Each regiment consumes one peasant when training finishes, alongside its treasury and goods cost.
7. After you confirm **Next turn**, the game carries out training. New regiments appear in the **Home Army** at the capital when that finishes — not when you tap. They do not appear directly in a field army.

A lack of peasants, goods, treasury, or the required technology prevents training. Military training shares the peasant reserve with worker and naval training, so a full queue in one area can prevent another from being raised — and the Train Military chip shows that before you over-queue.

### Armies and generals

Every land regiment belongs to one army, and an army occupies one province. Armies may contain mixed regiment types.

In **Military units panel**:

1. Expand an army to inspect its composition.
2. Tap **Split Army** on a non-empty army to move some of its regiments into a new army in the same province.
3. To combine armies already in one province: check the army rows you want to merge (they must all share that province), then tap **Combine** in the header. If **Home Army** is among the checked armies, it is always the merge target — other checked armies empty into it. You can also open **Province sea-zone overlay** on that province and tap **Combine** in Military when two or more of your armies stand there. That path merges every army of yours in the province after you confirm. To merge only some of them, keep using the checkboxes on **Military units panel**. If any of those armies already has a march waiting this turn, **Combine** stays visible but you cannot use it until you cancel that march.

Your capital always has a **Home Army**, even when it has no regiments. It receives every newly trained regiment. To create a force that can campaign, use **Split Army** on the Home Army (or the map detach path below) so some regiments become a field army at the capital.

Generals are commanders rather than map units. Your realm begins with one general; military and national advances can raise the cap to two with Organised Regiments, three with National Bureaucracy or Improved Infantry Tactics, and four with Nationalism. Before combat, generals are assigned to armies fighting that turn. A victorious commanding general gains medals, up to four; medals improve the army’s combat contribution. After a win, **Player turn event feed** may report copy such as `Victory at {province}: a general earned a medal (now N).`

At the top of the land list on **Military units panel**, the **Generals** section shows how many generals you have versus your cap, each general’s medals, and a short note that each general can lead one invasion per turn. Tap **Details** for a plain-language summary of what medals do in battle. When you stage more invasions in one turn than you have generals, extra armies still march but fight with weaker command — **Move army dialog** shows a soft warning on invasion destinations without blocking Confirm.

### Moving a field army

**From the map stack marker**

1. On **Empire overview / map area**, tap your **army stack marker** in the bottom-right of a town tile.
2. When a field army there can march, **Move army dialog** opens. If several field armies share the tile, **Overlay army move picker** opens first (title **Select army**); each row shows that army’s regiment mix. The Home Army is never a Move choice from that tap.
3. If a **non-empty** Home Army is in that stack and no field army there has a legal destination, the tap opens Split Army with title **Detach a field army** and confirm **Detach and choose destination**, then **Move army dialog** for the new field army.
4. An **empty** Home-Army-only marker still opens **Military units panel**. This path does not open **Province sea-zone overlay**.

**From **Province sea-zone overlay****

5. Open **Province sea-zone overlay** on a province.
6. Tap **Move** when a field army is stationed there, or when a non-empty Home Army is ready to detach (same **Detach a field army** / **Detach and choose destination** path as above).
7. Tap **Invade** on a foreign province when the control is **visible and enabled** — a field army that can legally reach it this turn, or your capital Home Army sits next door and still has regiments. **Invade** can also appear **visible but disabled** when a field army is next door yet cannot reach the province this turn and that Home Army path does not apply — hover for the cannot-reach reason; tapping stages no order. Wilderness and unowned land do not show **Invade**.
8. If several armies qualify from **Province sea-zone overlay**, **Overlay army move picker** (title **Select army**) asks which army acts and shows each army’s regiment mix; then **Move army dialog** opens. **Invade** preselects that province so you need not hunt it again.

**From the roster**

9. In **Military units panel**, select **Move** on a non-Home army.

**Choosing a destination**

10. **Move army dialog** lists only destinations that are legal for that army and the current turn’s orders. Sections print **Your provinces** and **Invasion targets** when both kinds apply. The dialog body shows **Your army: N regiments** for the army you are moving.
11. When you select an invasion destination, it also shows **Invasions this turn: N · Generals: G**; staging more invasions than generals triggers a soft warning that extra armies fight with weaker command (Confirm stays enabled). If your armies are short on rations this turn, a separate soft line warns that they will fight weaker — again without blocking Confirm.
12. Invasion target rows show defender strength, unopposed capture, and fort/siege risk when military intel is complete (you own the land, every tile is fully visible, a Spy is there, or a Spy’s remaining reveal time still covers the province). Otherwise they show **Defenders unknown**. Select an invasion row to see regiment-type breakdown when intel allows.
13. **Your provinces** may be selected for relocation, including provinces in another region. **Invasion targets** are provinces owned by another faction — a rival **Great Power** (another playable nation), a Minor Nation, or a Tribe — that are land-adjacent to the army’s present province and lie in its current region. Unowned or wilderness land is not a legal army destination.
14. Confirm the selected destination. If the province is at peace and entering it would begin a war, confirm **Declare war?** with **Declare war and move** (the body includes the same third-party Effect lines as **Diplomacy screen** Declare War when a third-party court is named). Already at war: no second dialog.
15. After you confirm **Next turn**, the game carries out movement. Every regiment in that army moves with it when that finishes. Until then, the army row shows **Moving to:** and the destination name until you change or cancel that move.

The Home Army itself cannot leave the capital. Split a field army from it before any regiment can march. From the map or **Province sea-zone overlay**, a non-empty Home Army now starts that split for you (**Detach and choose destination**), then **Move army dialog** for the new army. On **Province sea-zone overlay**, Move stays disabled with the capital reminder only when the Home Army is empty.

### Military Counsel (**Counsel screen**)

1. On **Military units panel**, tap **Counsel** in the header to open **Counsel screen** on the **Military** tab (header **Counsel**).
2. Review up to three ranked recommendations: **raise** regiment or ship types (with count and cost summary) and **invade** targets (army, province, owner, defender intel when known).
3. Tap **Agree** on a train card to queue that many build orders when still affordable; otherwise a short on-screen message explains why nothing was staged.
4. Tap **Agree** on an invade card to stage the army move; when war must be declared first, confirm in the same invasion dialog used by **Move army dialog**.
5. Empty counsel: “No pressing military advice this turn.” Agree is hidden while the game is carrying out **Next turn** and you cannot change orders.

## Counsel

**Counsel.** Hark, my liege: a regiment raised in the Home Army is a shield, not yet a spear. Split a field army before promising a campaign beyond the capital.

**Warning.** Do not spend every peasant on banners. A regiment consumes one peasant at training, and the same reserve must also sustain your workers and naval ambitions.

**Counsel.** Hark, my liege: an invasion is no quiet march. Choose a hostile province only when you are prepared for the war declaration that accompanies it.

**Note.** The technology list for Organised Regiments mentions a Knights upgrade path, while the regiment roster rules say Knights and Lancers have no upgrade path. Until those rules agree, treat Lancers as the Organised Regiments unlock and do not count on upgrading Knights.

## The other courts

Rival **Great Powers** (the other playable nations) choose among **Old World** conquest (the home map), New World colonies, and building up at home. They still must follow the same legal army rules you do. Other courts also detach a field army from the capital before they campaign; they do not march the Home Army (sometimes leaving the Home Army with no regiments). A rival bent on expansion will raise regiments, split field armies, and look for neighbouring foreign provinces they can enter. A developing rival may instead favour peace and civilian growth.

## Consequences

- Research determines the regiments available to train; a richer arsenal gives the realm more military options but still requires peasants, treasury, and goods (including horses for listed cavalry).
- Leaving regiments in the Home Army protects the capital but cannot project force.
- Splitting creates a field army able to relocate or invade, while combining armies (same province: checkboxes plus **Combine** on **Military units panel**, or **Combine** on **Province sea-zone overlay** Military for every army of yours in that province) concentrates forces already in one province.
- Moving into an eligible foreign province can begin a war before movement finishes, making the diplomatic choice inseparable from the military one.
- Successful battles can improve generals, while too many simultaneous attacks may exceed the number of generals available to command them.
