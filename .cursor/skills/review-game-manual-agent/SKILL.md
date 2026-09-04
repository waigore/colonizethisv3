---
name: review-game-manual-agent
description: Reviews one ColonizeThis player game-manual chapter for STYLE_GUIDE conformance and SPEC-accurate instructions/UI references, then files one GitHub issue listing every required alignment change. Picks a chapter if none is named. Use when asked to review the game manual or a handbook chapter, or to run review-game-manual-agent.
---

# Review game-manual agent (ColonizeThis)

Read-only review of **one** `docs/manual/[0-9][0-9]-*.md`. Files one issue. Does not edit the handbook. No user clarifications. Conventions: [shared.md](../shared.md). Filing: [create-github-issue](../create-github-issue/SKILL.md) (skip clarifications). Later implementation: [update-game-manual](../update-game-manual/SKILL.md), then [export-player-manual](../export-player-manual/SKILL.md).

| Check | Source of truth |
|-------|-----------------|
| Style | `docs/manual/STYLE_GUIDE.md` |
| Accuracy | The chapter’s `## Sources` plus `SPEC/ui/screen-registry.md` |

Do not use app code, playthrough, or memory as accuracy authority.

## Run

1. **Lock** — user-named chapter, else lowest-numbered chapter with no open issue citing that filename or title `Align handbook chapter N`. `gh issue list --state open --search "<filename>"`. If an alignment issue already exists, report its URL and stop. Lock in chat in one line.

2. **Style** — whole chapter vs STYLE_GUIDE. Each miss: locate, name the rule, state the rewrite. Do not copy the guide into the issue.

3. **Accuracy** — every Sources path + screen-registry. How-to vs SPEC; IDs exist; draft vs active; names match; rules/numbers vs cited SPEC; unsourced claims. SPEC wins. Two SPECs conflict → record, do not invent a resolution.

4. **File** if any findings. Title: `Align handbook chapter N: <title>`. Body: summary, expected/actual counts, required-changes checklists (style + accuracy), implementation via `update-game-manual` then `export-player-manual`, ACs that every item is applied and the reading-level gate passes. No findings → say it aligns; do not file.
