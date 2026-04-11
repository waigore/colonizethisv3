# Dialogue Content and Yarn Integration

**SPEC/ai** — Defines how dialogue content is keyed, where it lives (authored .yarn and/or data assets), and how options map to game outcomes. Presentation: [dialogue-presentation.md](../ui/dialogue-presentation.md). Management (when/where): [dialogue-management.md](dialogue-management.md). Province identity: [world-model-identity.md](../game/world-model-identity.md).

---

## Purpose

Dialogue **content** (lines and choices) is authored separately from logic. The app uses **Jenny** (Yarn Spinner–style) with **.yarn** script files; each dialogue point is presented by **jumping to a named node** keyed by dialogue kind and situation. Options in the node are wired to **game outcomes** (e.g. Accept/Reject for overture).

---

## Content keys and node names

- A **content key** uniquely identifies the dialogue to show. It is derived from:
  - **dialogue point kind** (e.g. `overture_target_response`, `intervention_choice`);
  - **situation** or **subtype** (e.g. overture stage: `trade_consulate`, `embassy`, `nap`, `join_empire`; intervention: `minor_embassy`, `tribe_investment`);
  - Optional **era** and **variables** (e.g. offerer name, province) for localization or branching.

- **intervention_choice (app):** Nodes in `assets/dialogue/intervention.yarn`: `DialoguePoint/intervention_intro`, `DialoguePoint/intervention_situation`, `DialoguePoint/intervention_reaction_intervene`, `DialoguePoint/intervention_reaction_do_nothing`, `DialoguePoint/intervention_reaction_protest`. Variables: `aggressorName`, `defenderName`, `interveningName` (strings). See [pending-intervention-overlay.md](../ui/screens/pending-intervention-overlay.md).

- **App (Jenny):** The content key maps to a **Yarn node name**. Convention: `DialoguePoint/<kind>/<situation>` (e.g. `DialoguePoint/overture_target_response/embassy`). The node contains:
  - **Lines:** Speaker (leader/offerer), text (possibly with inline expressions for variables).
  - **Options:** Each option has a **destination** (next node or stop) and an **outcome tag** or **command** that the runner interprets as the game outcome (e.g. `<<Accept>>`, `<<Reject>>` for overture; `<<Intervene>>`, `<<DoNothing>>`, `<<Protest>>` for intervention).


---

## Where content lives

- **Yarn scripts (app):** Under `assets/dialogue/` or as specified in TDD; `.yarn` files are loaded by Jenny’s DialogueRunner. Node names follow the convention above. Variables (e.g. `offererName`, `stage`, `province`) are set by the game layer before starting the node. The **game start intro** node is named `DialoguePoint/game_start_intro` (or `game_start_intro`); its text is in **archaic language**, stating that the age of imperialism is rapidly approaching and challenging the player to usher in glory for their nation. Single line (or short paragraph) plus one option to dismiss (e.g. "Begin" or "I shall").
- **Data assets (shared):** Supporting strings may live in the same ruleset/localization data that supplies DialogueEvent resolution (see [dialogue-and-mood.md](dialogue-and-mood.md)). Keys align with content keys so authored Yarn and data-driven copy stay consistent.

---

## Option → outcome mapping

Each **selectable option** in a dialogue point corresponds to exactly one **game outcome** for that dialogue point kind:

| Kind | Option labels (example) | Outcome / resume payload |
|------|------------------------|---------------------------|
| overture_target_response | Accept, Reject (per offer) | OvertureDecision(accepted: true/false) per offer |
| intervention_choice | Intervene, Do Nothing, Diplomatic Protest | InterventionChoice enum |
| alliance_offer_response | Accept, Refuse | AllianceDecision enum |
| dialogue_flavour | Dismiss / Continue | None |
| game_start_intro | Begin / I shall | None (dismiss only) |

Jenny custom commands or tags (e.g. `<<Accept>>`) are invoked when the player picks an option; the app’s dialogue layer maps that to the corresponding outcome object and passes it to the resume API.

---

## Variables and personalization

Dialogue may include **variables** (offerer name, faction, overture stage, province, era). These are set by the game layer when starting the dialogue point and passed into **Jenny** as Yarn variables so node text can use `{offererName}`, `{stage}`, etc., and into any supporting data-asset templates for string substitution where used.

Province ids in variables must be **prefixed** per [world-model-identity.md](../game/world-model-identity.md). No asset paths or image references in the dialogue model; only keys and variables.

---

## Acceptance criteria

- **Given** a blocking dialogue point of kind **overture_target_response** and situation **embassy**, **when** the app presents it, **then** the app loads the Yarn node named by the content key (e.g. `DialoguePoint/overture_target_response/embassy`) and displays lines and options; when the player selects Accept (or Reject), the app calls the resume API with an OvertureDecision with the corresponding accepted value.
- **Given** a dialogue point includes variables (e.g. offererName, stage), **when** content is resolved, **then** those variables are substituted in the presented dialogue; province id variables use prefixed form.
- **Content key stability:** The same (kind, situation, optional era) always maps to the same content key so that authored Yarn nodes and data assets can be maintained in one place.
