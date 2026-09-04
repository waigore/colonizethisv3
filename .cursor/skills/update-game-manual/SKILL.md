---
name: update-game-manual
description: Updates the ColonizeThis player game manual under docs/manual/ when player UX or gameplay changes—maps affected chapters via Sources footers, preserves vizier tone and grade-12 reading level (UI-engineering and genre jargon banned), player-angle framing, chapter template, and draft-marking. Use when SPEC/game, SPEC/ui, allowlisted SPEC/program files, orders, screens, or manual chapters change; when create-github-issue/plan-feature issues include manual ACs; or when the user asks to refresh the game manual.
---

# Update the player game manual (ColonizeThis)

Style + template: `docs/manual/STYLE_GUIDE.md`. ToC: `docs/manual/index.md`. Rule: `.cursor/rules/colonizethis-game-manual.mdc`. SPEC remains source of truth.

Use when `SPEC/game/**`, `SPEC/ui/**`, or allowlisted `SPEC/program/` (`orders.md`, `turn-resolution-phases.md`, `turn-resolution-phase-details.md`, `order-engine.md`) change, or player-facing orders/screens/outcomes change. Skip other `SPEC/program/**` unless the player can do, see, or be told something different.

1. Collect changed SPEC paths.
2. Map each path to chapters whose `## Sources` backtick equals that path. Update every match. If ToC says it belongs in a pending chapter, note the gap.
3. Update prose: player angle; seven required sections; operable UI only under **How it is done**; archaic register only in Counsel (still must pass reading-level); rival courts from `SPEC/ai/*` as what they **do**; quote only player-critical numbers; draft IDs marked or omitted.
4. **Reading-level gate (hard fail)** — every added/changed sentence vs STYLE_GUIDE banned classes. Rewrite until the touched section passes. Do not export failing prose. Do not rewrite untouched chapters unless asked.
5. `## Sources` last `##` section; one backtick path per bullet.
6. After passing the gate, run [export-player-manual](../export-player-manual/SKILL.md).

Report SPEC paths, chapters (or justified non-update), gate result, pending gaps.
