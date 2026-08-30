---
name: review-game-manual-agent
description: Reviews one ColonizeThis player game-manual chapter for STYLE_GUIDE conformance and SPEC-accurate instructions/UI references, then files one GitHub issue listing every required alignment change. Picks a chapter if none is named. Use when asked to review the game manual or a handbook chapter, or to run review-game-manual-agent.
---

# Review game-manual agent (ColonizeThis)

Read-only review of **one** authoring chapter under `docs/manual/[0-9][0-9]-*.md`. Files a GitHub issue with the full change list. Does not edit the handbook.

## Authority

| Check | Source of truth | Do not substitute |
|-------|-----------------|-------------------|
| Style | [`docs/manual/STYLE_GUIDE.md`](../../../docs/manual/STYLE_GUIDE.md) | Invented tone/reading-level rules |
| Accuracy | SPECs in that chapter’s `## Sources`, plus [`SPEC/ui/screen-registry.md`](../../../SPEC/ui/screen-registry.md) for IDs and titles | App code, playthrough, or memory |

Dependent skills (apply; do not fork):

- [`.cursor/skills/create-github-issue/SKILL.md`](../create-github-issue/SKILL.md) — issue structure and `gh` create / paste-ready fallback. **Skip** that skill’s mandatory user-clarification step.
- Later implementation (not this run): [`.cursor/skills/update-game-manual/SKILL.md`](../update-game-manual/SKILL.md), then [`.cursor/skills/export-player-manual/SKILL.md`](../export-player-manual/SKILL.md). Screen IDs: [`.cursor/skills/document-app-ui/SKILL.md`](../document-app-ui/SKILL.md).

## Workflow

```
Task progress:
- [ ] 1. Lock one chapter
- [ ] 2. Review style against STYLE_GUIDE
- [ ] 3. Review instructions and UI refs against cited SPECs
- [ ] 4. File one issue if any findings; otherwise stop
```

### 1. Lock one chapter

Numbered files only: `docs/manual/[0-9][0-9]-*.md` (not `index.md`, `STYLE_GUIDE.md`, or `player-export/`).

- If the user named a chapter (number, title, or filename), use that one.
- Else pick the **lowest-numbered** chapter that has **no** open GitHub issue citing that filename (e.g. `01-primer.md`) or title `Align handbook chapter N`.

```bash
gh issue list --state open --search "<filename>" --limit 20 --json number,title,url
```

If the chosen chapter already has an open alignment issue, report that URL and **stop** (do not file a second). If every chapter has one, report that and stop. Lock the choice in chat in one line and continue — do not ask which chapter to review.

### 2. Style review

Read `STYLE_GUIDE.md`, then the whole chapter. Check every section against that guide (tone, reading-level / banned-language classes, player-angle, required template sections, Counsel register, draft marking, Sources footer). Record each miss as a required change: quote or locate the sentence, name the STYLE_GUIDE rule, and state the rewrite.

Do not copy the style guide into the issue.

### 3. Accuracy review

Read every path in the chapter’s `## Sources` and `SPEC/ui/screen-registry.md`. Check:

- How-to steps vs the cited UI/game SPECs (order of actions, what the player taps, when results appear).
- Screen IDs exist; `active` vs `draft` matches STYLE_GUIDE draft marking; display names match the registry.
- Rules, numbers, and rival-court claims vs the cited `SPEC/game`, `SPEC/program`, and `SPEC/ai` files.
- Chapter claims that have no Sources path (missing citation or unsourced invention).

On conflict, the SPEC is right and the manual must change. If two SPECs conflict, record that as a finding and do not invent a resolution.

Do not open `app/` or play the game for this skill.

### 4. File the issue

If there are **no** findings, say the chapter already aligns and **do not** file.

Otherwise apply `create-github-issue` filing (`gh issue create --body-file`, fallback to paste-ready draft). Skip clarifications. Do not edit the repo.

**Title:** `Align handbook chapter N: <chapter title>` (N = the `NN` prefix).

**Body:**

```markdown
## Summary
Chapter N (`docs/manual/NN-….md`) needs alignment with STYLE_GUIDE and cited SPECs.

## Expected behavior
The chapter conforms to `docs/manual/STYLE_GUIDE.md`. Every instruction and UI reference matches the SPECs in its `## Sources` and `SPEC/ui/screen-registry.md`.

## Actual behavior
- Style: <count> findings
- Accuracy: <count> findings

## Required changes
### Style (STYLE_GUIDE)
- [ ] <location>: <what is wrong> → <what to write instead>

### Accuracy (SPEC)
- [ ] <location>: <manual claim> vs `<SPEC/path>` <what SPEC says> → <correction>

## Implementation
Use `update-game-manual`, then `export-player-manual`. Do not invent gameplay. Do not assign new screen IDs (`document-app-ui` if a registry gap is in the findings).

## Suggested acceptance criteria
- [ ] Every Required-changes item above is applied in `docs/manual/NN-….md`.
- [ ] Touched sections pass the STYLE_GUIDE reading-level gate.
- [ ] Cited screen IDs and how-to steps match `SPEC/ui/screen-registry.md` and the chapter Sources SPECs.
- [ ] `export-player-manual` run after the authoring edit.
```

List **every** required change. One issue, one chapter.

## Chat output

- Chapter locked (file + why)
- Finding counts (style / accuracy), or “already aligns”
- Issue URL, or existing open issue, or paste-ready draft if `gh` failed

## Guardrails

- One chapter per run. No handbook edits. No SPEC edits.
- No user clarifications. No second issue for a chapter that already has an open alignment issue.
- OpenCode: `.opencode/skills/review-game-manual-agent/SKILL.md`
- Grok: `.grok/skills/review-game-manual-agent/SKILL.md`
