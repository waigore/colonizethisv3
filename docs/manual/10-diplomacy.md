# Diplomacy and Courtly Affairs

## Purpose

Diplomacy lets your Great Power choose whether rivals become trading partners, treaty allies, subjects, or enemies. A timely embassy can open foreign opportunities; a formal alliance can deter aggression; a declaration of war can clear the way for conquest. These choices matter because military victory depends on Old World provinces, while colonies, trade, and dependable friends strengthen the realm that pursues it.

Relations are shown as Peace or War and a descriptive relation meter rather than a raw number. A formal alliance is separate from friendly relations: only a treaty creates mutual-defence obligations.

## How it is done

1. From `GAME10001` **Game screen**, use the diplomacy button to open `GAME30001` **Diplomacy screen**. It lists discovered Great Powers, Minor Nations, and contacted Tribes. Select a row for `GAME30002` **Diplomacy detail screen**, where you may review the relationship and its diplomatic history. The **Intelligence** button on `GAME30001` opens `GAME30003` **Intelligence**. **World briefing** lists last turn’s public wars, peace, alliances, captures, and discoveries. **Spy reports** lists news from courts where one of your Spies still stood after the turn finished, each line starting **Our spy in {court} reports:**. Closing turn news does not erase this briefing; it stays until the next turn replaces it. If you have no Spies abroad, Spy reports says so and tells you to station a Spy.
2. Choose an enabled action on each faction row (`GAME30001`). Parameter-less decrees still use a confirmation that states first-order **cost** (when relevant), **effect**, and **when** (Break Alliance only — immediate) before you commit. **Grant Aid** and **Set Subsidy** are different: `DIPL20001` itself shows that cost and effect, and **Submit** stages the pending order — there is no second confirmation. When a Minor or Tribe province blocks Explore or Prospect for lack of a Consulate, `MAP20001` Political offers the same first-stage **Establish Consulate** decree in context. When you open a foreign-owned land province at war, Political also shows **At war** and **Offer Peace** with the same confirmation, pending order, and **Cancel** behavior as the Diplomacy row. Both Consulate and Offer Peace entry points use the same confirmation, validation, pending order, and **Cancel** behavior as the panel. Each diplomacy row shows current actions; tap **More actions** for unavailable steps and reasons.
3. **Declare War** requires peace with the target. It takes effect before that turn’s movement and combat, so it may support an invasion ordered for the same turn. The confirmation names other courts the war can pull in: formal allies of a Great Power target who may be called to defend, and Great Powers holding an Embassy or purchased land in a Minor or Tribe who may be asked to intervene. It does not predict who will join. `GAME30002` lists a Great Power’s other formal allies as orientation. **Offer Peace** requires war; peace needs the other side’s agreement and does not change borders.
4. **Alliance** targets another Great Power at peace when no formal alliance already exists. A successful treaty creates formal mutual defence. **Break Alliance** requires that treaty; on the human panel it applies immediately after confirmation rather than waiting for turn resolution.
5. After voluntarily breaking an alliance, the two Great Powers cannot form an alliance, establish an overture, grant aid, or set a subsidy with one another for the rest of that turn. War and peace remain available; the bilateral cooldown ends next turn.
6. **Establish Overture** advances one stage at a time: Trade Consulate, Embassy, Non-Aggression Pact, then Join Empire. You may submit only one overture toward a faction per turn. The target must accept; costs are paid and the stage advances only on acceptance.
   - A Trade Consulate costs £500 by default; an Embassy costs £1000; a Non-Aggression Pact is free.
   - Toward Minor Nations and Tribes, **Diplomatic Expertise** is required for Consulate, Embassy, and Non-Aggression Pact stages, and it unlocks the foreign civilian work associated with an embassy. Great Powers begin with mutual Embassies (no Consulate cost), even though later stages may still be pursued.
   - War clears ordinary overtures and prevents new ones until peace returns. After peace, rebuild the chain from the start (Great Power auto-embassies are the documented exception).
   - **Join Empire** follows a Non-Aggression Pact and needs the required relation and treasury. Its default cost is £5000 plus £2000 per target province. A Minor Nation is absorbed: its provinces, units, and fleets transfer to you. A Tribe instead becomes your colony, remaining on the map under its own ownership.
   - Against another Great Power, Join Empire requires Empire Building and a nearly defeated target: three or fewer total provinces and loss of its original capital.
7. **Grant Aid** requires an Embassy and sufficient treasury. Open `DIPL20001` **Grant or subsidy dialog**, choose a positive amount in £1000 steps (minimum £1000), read the **Cost** and **Effect** lines in that dialog, and tap **Submit**. That stages the pending one-time transfer; there is no second confirmation. It improves relations when resolved. Cancel the pending line on the `GAME30001` row if you change your mind before the turn ends.
8. **Set Subsidy** uses the same `DIPL20001` dialog. It is available only toward a Minor Nation or Tribe with an Embassy (not toward another Great Power). Choose 5%, 10%, 15%, or 20%; the dialog shows that there is no per-turn gold charge and that market terms are affected. **Submit** stages the pending subsidy with no second confirmation.
9. **Boycott** targets another Great Power. You need at least one colony, must be at peace, and cannot already boycott that target. It blocks trade between that Great Power and all Tribes that are your colonies. **Revoke Boycott** ends an active boycott. War automatically ends a boycott between the warring Great Powers.
10. For one target in one turn, a non-economic diplomatic order—Declare War, Offer Peace, Alliance, Break Alliance, or Establish Overture—blocks further diplomatic orders toward that target. Grant Aid and Set Subsidy may coexist, but only once each per target. Boycott and Revoke Boycott are separate actions, each limited to once per target per turn, and do not block the other diplomatic families.

When a human-controlled Great Power must answer an overture, `OVL30001` **Overture dialogue overlay** pauses resolution until every offer is accepted or rejected. Before you submit, each offer row states muted **Effect** lines under Accept and Reject: Accept names the stage that would be established and that you pay nothing (Join Empire instead states that your realm is absorbed and your provinces transfer to the offerer); Reject states that the offer lapses and the stage does not advance, with no standing penalty. A formal ally called to defend against a declaration of war likewise pauses resolution at `OVL40001` **Call to arms dialogue overlay** until you choose Join or Refuse. Before you submit, each call row states the formal alliance with the defended ally and plain **Effect** lines under Join and Refuse: Join enters war with the aggressor this turn while the treaty stays; Refuse ends the treaty, sharply worsens relations with that ally (−50), and harms standing with other Great Powers (−10).

If another Great Power declares war on a Minor Nation or Tribe in which you hold an Embassy or purchased land, `OVL50001` **Pending intervention overlay** asks you to Intervene, Do naught, or make a Diplomatic protest. Before you choose, the overlay states who declared war on whom, why you were prompted (Embassy and/or purchased land), and plain **Effect** lines under each option summarizing war, overture loss, and relation penalties. Intervening puts you at war with the aggressor; doing nothing abandons your overtures with the attacked faction while purchased land remains; protest keeps peace but harms relations with the aggressor.

## Counsel

**Counsel.** Hark, my liege: an Embassy is not merely a polite seal upon a letter. It opens aid, subsidy, foreign work, intervention, and the patient road toward influence.

**Warning.** A friendly relation is not an alliance. Only the visible formal treaty can summon a call to arms; refusing that call breaks the treaty and damages your standing with other courts.

**Tip.** Regard the Great Power relative-power line as a warning bell. It compares provinces, army strength, and ships with your own realm; a stronger rival appears in red, while an equal or weaker one appears in green.

## The other courts

AI Great Powers weigh war, peace, alliances, overtures, boycotts, and treaty-breaking against relative power, relations, personality, and hidden agenda. Strong relations discourage war; a weaker target, needed resources, and favourable invasion conditions can make it more attractive. Embassies held by other powers make attacks on Minor Nations and Tribes riskier because they may trigger intervention.

Hidden agendas shape conduct without revealing themselves directly. A warmonger may seek weaker neighbours, an isolationist may avoid or end alliances, a backstabber may exploit weakness, and a peacemaker prefers de-escalation. The Great Power dossier offers only accumulated evidence and suspicion, never an opponent’s secret agenda itself.

AI allies join a defensive call to arms when their relation with the defended ally is at least 50; otherwise they refuse. An AI that initiates war waits four turns before reconsidering that target, while rejected or accepted overture outcomes impose a two-turn improve-relations cooldown for that pair.

## Consequences

- War permits hostile military movement and blockade against the target, but ends ordinary overtures between the pair. Peace restores peace, not the former diplomatic ladder.
- A formal alliance formed this turn does not protect its partner from a declaration made in the same turn. Refusing a later defensive call breaks the alliance, sharply damages the former ally’s relation, and harms relations with other Great Powers.
- A successful Minor Nation Join Empire directly expands your realm and can advance the Old World victory count. A Tribal Join Empire creates a colony instead: strategically valuable, but not direct province ownership.
- Grants, subsidies, embassies, and trade can cultivate a relationship; neglect lets peaceful relations drift toward neutral over time.
- Boycotts protect a colonial trade sphere but can narrow your own commercial options. They vanish when war makes normal trade impossible anyway.
- Great Power power score combines province count, regiment strength, and ship count. It informs diplomatic comparison and AI strategic judgment, but does not replace the province-based victory requirement.

## Acceptance criteria for this chapter

- [ ] Documents declareWar, offerPeace, alliance, breakAlliance, establishOverture, grantAid, setSubsidy, boycott, and revokeBoycott.
- [ ] Explains peace/war, treaty, Embassy, colony, treasury, and target-type preconditions.
- [ ] States Grant Aid’s £1000 minimum-step rule and Set Subsidy’s 5–20% range in 5-point steps.
- [ ] Distinguishes Grant Aid / Set Subsidy (`DIPL20001` **Submit**, Cost / Effect in that dialog, no second confirmation) from other diplomacy confirms.
- [ ] Covers per-target-per-turn order limits and the same-turn post-break bilateral cooldown.
- [ ] Explains the overture chain, Diplomatic Expertise, Empire Building, and the distinct Minor/Tribe/Great Power Join Empire outcomes.
- [ ] Cites `GAME30001`, `GAME30002`, `GAME30003`, `DIPL20001`, `OVL30001`, `OVL40001`, and `OVL50001` with their player-facing flows.
- [ ] Distinguishes public **World briefing** from Spy-only court reports on `GAME30003`.
- [ ] Explains pending overtures, calls to arms, and interventions without exposing hidden agenda values.
- [ ] Explains Great Power relative power and its province, military, and naval components.

## Sources

- `SPEC/game/diplomacy.md`
- `SPEC/game/tech-tree-diplomacy-civilian.md`
- `SPEC/program/orders.md`
- `SPEC/ui/diplomacy-panel.md`
- `SPEC/ui/intelligence-council.md`
- `SPEC/program/intelligence-digest.md`
- `SPEC/ui/province-sea-zone-detail-overlay.md`
- `SPEC/ui/diplomacy-detail-screen.md`
- `SPEC/ui/grant-or-subsidy-dialog.md`
- `SPEC/ui/overture-dialogue-overlay.md`
- `SPEC/ui/call-to-arms-dialogue-overlay.md`
- `SPEC/ui/pending-diplomacy-state.md`
- `SPEC/ui/screens/pending-intervention-overlay.md`
- `SPEC/ui/screen-registry.md`
- `SPEC/ai/diplomacy-planner.md`
- `SPEC/ai/dialogue-and-mood.md`
- `SPEC/ai/hidden-agendas.md`
