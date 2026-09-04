# Diplomacy and Courtly Affairs

## Purpose

Diplomacy lets your **Great Power** — a playable nation — choose whether rivals become trading partners, treaty allies, subjects, or enemies. A **Minor Nation** is an Old World court that does not issue decrees of its own. A **Tribe** is a New World people. A **decree** is an action you choose on your turn. The **Old World** is the map where military victory is counted. An **Embassy** is a later step on the diplomatic ladder. A **colony** is a Tribe that has joined your empire but still owns its own land. An **overture** is a stepwise offer (Consulate → Embassy → Non-Aggression Pact → Join Empire).

A timely Embassy can open foreign opportunities; a formal alliance can deter aggression; a declaration of war can clear the way for conquest. These choices matter because military victory depends on Old World provinces, while colonies, trade, and dependable friends strengthen the realm that pursues it.

Each diplomacy row shows a **PEACE** or **WAR** chip, an optional **ALLIANCE** chip (only when a formal treaty exists — not merely a friendly standing), a ten-step bar, and one word such as **Wary** or **Friendly**. The ten words, from cold to warm, are **Hostile**, **Antagonistic**, **Distrustful**, **Unfriendly**, **Wary**, **Neutral**, **Cordial**, **Amicable**, **Friendly**, and **Devoted**. The hidden standing number is never shown. **Friendly** is not a treaty; only the **ALLIANCE** chip marks mutual defence.

## How it is done

### Open Diplomacy and Intelligence

1. On **Game screen**, tap the **Diplomacy** icon on the left of the map. That opens **Diplomacy screen**.
2. The list shows discovered Great Powers, Minor Nations, and contacted Tribes. Use the bottom bar to filter: **All**, **Great Powers only**, or **Minors only** (that last mode still shows Minor Nations and Tribes). When no Tribes are contacted yet, the Tribes section shows **No tribes contacted yet.**
3. Tap a row to open **Diplomacy detail screen**. You see three cards: **CURRENT RELATION** (Great Powers also show **Relative power:**, an **ALLIANCE** chip when a treaty exists, standing chips, and a **Formal allies** line), **DIPLOMATIC HISTORY** (newest first, with year and turn; undiscovered parties appear as **Unknown faction**), and **DOSSIER** (Great Powers only — suspicion and evidence, never a secret label). This screen does not issue decrees; actions stay on **Diplomacy screen**.
4. On **Diplomacy screen**, tap **Intelligence**. That opens **Intelligence Council**. **World briefing** lists last turn’s public wars, peace, formal alliances formed or broken, overture advances, captures, discoveries, and first fleet presence. When there is nothing to report, it shows **No major world events last turn.** **Spy reports** lists news from courts where one of your Spies still stood after the turn finished; each line starts **Our spy in {court} reports:**. When you have no Spies abroad, it shows **No spy reports. Station a Spy in a foreign province to hear that court's news.** Closing turn news does not erase this briefing; it stays until the next turn replaces it. Tap a court line to open **Diplomacy detail screen**. Tap a capture or discovery line to open that place on the map via **Province sea-zone overlay** (Political is the tab).

### Stage a decree on a court

5. On each **Diplomacy screen** row, tap an enabled action. Actions that need no amount still open a confirm that names **Cost**, **Effect**, and — for **Break Alliance** only — **When**. **Grant Aid** and **Set Subsidy** show **Cost** and **Effect** on **Grant or subsidy dialog**; **Submit** stages the action with no second confirm. Tap **More actions** for unavailable steps and the refusal reason under each.
6. On **Province sea-zone overlay**, Political shows standing with the owner when your records know them (**At war** or **At peace**, plus **ALLIANCE** when you hold a formal treaty). It can also show **No consulate with {owner}** plus **Establish Consulate** when Explore or Prospect is blocked for lack of a Consulate. The disabled Explore/Prospect hint is **Establish a consulate before exploring or prospecting**. When you are **At war** with that owner on a foreign land province, Political also offers **Offer Peace**. Consulate and Offer Peace use the same confirm, pending order, and **Cancel** behavior as the Diplomacy row.

### War, peace, and alliance

7. **Declare War** requires peace with the target. It takes effect before that turn’s movement and combat, so it may support an invasion ordered for the same turn. The confirm names other courts the war can pull in: formal allies of a Great Power target who may be called to defend, and Great Powers holding an Embassy or purchased land in a Minor or Tribe who may be asked to intervene. It does not predict who will join. **Diplomacy detail screen** lists a Great Power’s other formal allies as orientation.
8. **Offer Peace** requires war. Use the **Diplomacy screen** row, or **Offer Peace** on **Province sea-zone overlay** Political when that province’s owner is at war with you. Minor Nations and Tribes never refuse peace. Another Great Power must agree. Peace does not change borders.
9. **Alliance** targets another Great Power at peace when no formal alliance already exists. Order validation accepts that offer at peace with no formal treaty; the game-design standing table also names Alliance at standing 76 or higher. Those two SPECs disagree — this handbook does not invent a **Friendly** or **Devoted** button gate until they agree. A successful treaty creates formal mutual defence.
10. **Break Alliance** requires that treaty. On the human panel it ends immediately after confirmation rather than waiting for **Next turn**. A voluntary break harms standing with the former ally and with other courts the same way a refused call to arms does. The confirm on **Diplomacy screen** names the rest-of-turn lock (Alliance, overture, Favored Trading Partner, Grant Aid, and Set Subsidy blocked toward that court until next turn; Declare War and Offer Peace stay available) and does not print the −50 / −10 figures; those numbers appear on **Call to arms dialogue overlay** under **Refuse**.
11. After you voluntarily break an alliance on this turn, you cannot **Alliance**, **Establish Overture**, **Establish Favored partner**, **Grant Aid**, or **Set Subsidy** with that same court for the rest of the turn. War and peace stay available. Disabled **Alliance** copy reads **On cooldown after breaking alliance — available next turn**. The lock clears next turn.

### Overtures

12. Tap **Establish Overture**. The stage dialog opens first. The enabled next stage sits on the default row; later locked stages sit under **More actions** with the refusal reason. Then the confirm appears and names what that stage unlocks (for example, a Consulate toward a Minor or Tribe lets you Explore and Prospect on their land; an Embassy opens Grant Aid, subsidies, and land purchase; a Non-Aggression Pact does not by itself stop you from declaring war). **Confirm** stages the pending decree. Stages advance one at a time: Trade Consulate, Embassy, Non-Aggression Pact, then Join Empire. You may submit only one overture toward a faction per turn.
13. A Trade Consulate costs £500 by default; an Embassy costs £1000; a Non-Aggression Pact is free.
14. Toward Minor Nations and Tribes, order validation requires **Diplomatic Expertise** for Consulate, Embassy, and Non-Aggression Pact. The diplomacy tech table says Diplomatic Expertise “Enables: embassy overture to Minor Nations” only. Those SPECs disagree — follow the order rules for what you can stage until the SPECs are reconciled. That tech also unlocks the foreign civilian work tied to an embassy. Great Powers begin with mutual Embassies (no Consulate cost); later stages may still be pursued.
15. Minor Nations never refuse Consulate or Embassy. Join Empire toward a Minor or Tribe still needs Friendly/Allied standing and the treasury cost. Great Power targets decide for themselves; when you are the target, **Overture dialogue** asks you to answer.
16. War clears ordinary overtures and prevents new ones until peace returns. After peace, rebuild the chain from the start (Great Power auto-embassies are the documented exception).
17. **Join Empire** follows a Non-Aggression Pact and needs the required standing and treasury. Toward a Minor Nation or Tribe, the default cost is £5000 plus £2000 per province the target owns. A Minor Nation is absorbed: its provinces, units, and fleets transfer to you. A Tribe instead becomes your colony, remaining on the map under its own ownership. Against another Great Power, Join Empire requires Empire Building and a nearly defeated target: three or fewer total provinces and loss of its original capital — do not invent a Great Power per-province charge beyond that.

### Favored Trading Partner

18. **Establish Favored partner** targets another Great Power at peace when you hold an Embassy with them. The confirm on **Diplomacy screen** says there is no treasury charge. **Effect** says that if they accept you become Favored Trading Partners; that fills between you are preferred when you buy or sell the same good at the same rank; that prices do not change; and that this does not beat First right of refusal. It never prints a hidden standing number.

### Aid, subsidy, and boycott

19. **Grant Aid** requires an Embassy and enough gold. Open **Grant or subsidy dialog**, choose a positive amount in £1000 steps (minimum £1000), read **Cost** and **Effect**, and tap **Submit**. That stages the one-time transfer with no second confirm. **Cost** names the gold that leaves your treasury. **Effect** says standing with that court improves when the turn finishes, that a larger gift this turn does not improve standing further, and whether the standing word on **Diplomacy screen** the current word or **becomes** the next word. Give the smallest allowed gift unless you simply want to spend the gold. Tap **Cancel** on the **Diplomacy screen** row if you change your mind before **Next turn**.
20. **Set Subsidy** uses the same **Grant or subsidy dialog** dialog. It is available only toward a Minor Nation or Tribe with an Embassy (not toward another Great Power). Choose 5%, 10%, 15%, or 20%. **Cost** says there is no per-turn gold charge. **Effect** says that on deals that fill with that court you pay that percent more when buying from them and receive that percent less when selling to them. Hover or long-press the outgoing or pending subsidy line on **Diplomacy screen** for the same meaning. **Submit** stages the subsidy with no second confirm.
21. **Boycott** targets another Great Power. You need at least one colony, must be at peace, and cannot already boycott that target. The confirm on **Diplomacy screen** shows **Cost: No treasury charge.** **Effect** lines say world-market deals between that court and your colony Tribes will not fill either way; that court cannot **purchase land**, **Grant Aid**, or **Set Subsidy** toward those colonies; and subsidies they already pay those colonies are cancelled when this resolves. The same embargo applies to every Tribe that is your colony at resolution, not one tribe chosen on the button. **Revoke Boycott** confirm says the embargo ends so that court may again trade with, purchase land in, and grant aid or subsidies toward those colonies. War between the two Great Powers also ends the boycott.

### Limits this turn

22. After you lock **Declare War**, **Offer Peace**, **Alliance**, or **Establish Overture** toward a court, you cannot add another diplomacy decree toward that same court this turn (except **Boycott** / **Revoke Boycott**). **Grant Aid** and **Set Subsidy** may both appear toward the same court, but only once each. **Boycott** and **Revoke Boycott** each may appear once per target and do not block the other diplomacy families.

### Incoming offers after Next turn

23. After you confirm **Next turn**, the game may stop and ask you to answer.
24. On **Overture dialogue**, read the spoken intro, tap **Continue**, then set **Accept** or **Reject** on every row. Each row shows plain **Effect** lines under the choices. **Submit** stays off until every offer is chosen; then tap **Submit** so the turn can finish.
25. On **Call to arms dialogue overlay**, there is no intro. Each row names the formal treaty, then **Join** or **Refuse**, with plain **Effect** lines. **Submit** is gated the same way: pick every row, then **Submit**.
26. On **Pending intervention overlay**, read the spoken intro and the situation, then choose **Intervene**, **Do naught**, or **Diplomatic protest**. Each choice shows an **Effect** line (protest names −10). An aggressor reaction follows before the turn continues.
27. On **Favored Trading Partner dialogue overlay**, there is no spoken intro. Each row names the offering court, then **Accept** or **Reject**, with the same first-order **Effect** meaning as the Diplomacy confirm. **Submit** stays off until every offer is chosen; then tap **Submit** so the turn can finish.

## Counsel

**Counsel.** Hark, my liege: an Embassy is not merely a polite seal upon a letter. It opens aid, subsidy, foreign work, intervention, and the patient road toward influence.

**Warning.** A friendly standing is not an alliance. Only the visible **ALLIANCE** chip can summon a call to arms; refusing that call breaks the treaty and damages your standing with other courts.

**Tip.** Regard the **Relative power:** line as a warning bell. It compares provinces, army strength, and ships with your own realm and prints a percent plus a tier word such as **Superior** (tiers: **Vastly inferior**, **Inferior**, **Roughly equal**, **Superior**, **Vastly superior**). A stronger rival appears in red; an equal or weaker one appears in green. Do not hunt for a separate numeric power score on these screens — the printed comparison is **Relative power:**.

## The other courts

Rival Great Powers weigh war, peace, treaties, and boycotts by strength and standing. Strong standing discourages war; a weaker target, needed resources, and favourable invasion conditions can make war more attractive. Embassies held by other powers make attacks on Minor Nations and Tribes riskier because they may trigger intervention.

Do not expect a secret agenda label on any screen. The **DOSSIER** on **Diplomacy detail screen** shows suspicion and evidence only. Rivals show habits you can watch: after a war they start, they often wait several turns before starting another with the same court; after an overture is answered, they often wait a short time before another friendly offer.

Rival allies join a defensive call to arms when their standing with the defended ally is at least 50; otherwise they refuse.

## Consequences

- War permits hostile military movement and blockade against the target, but ends ordinary overtures between the pair. Peace restores peace, not the former diplomatic ladder.
- A formal alliance formed this turn does not protect its partner from a declaration made in the same turn. Refusing a later defensive call — or voluntarily breaking the treaty — harms standing with the former ally and with other Great Powers.
- A successful Minor Nation Join Empire directly expands your realm. For how Old World province counts feed victory, see Chapter 15. A Tribal Join Empire creates a colony instead: strategically valuable, but not direct province ownership.
- Grants, subsidies, embassies, and trade can cultivate a relationship; neglect lets peaceful relations drift toward neutral over time.
- Boycotts protect a colonial trade sphere but can narrow your own commercial options. They vanish when war makes normal trade impossible anyway.
- The diplomacy screens compare rivals with **Relative power:** (provinces, army strength, and ships). That comparison informs diplomatic judgment; it does not replace the province-based victory requirement.
