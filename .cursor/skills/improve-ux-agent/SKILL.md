---
name: improve-ux-agent
description: Autonomously runs suggest-player-ux-improvements then files one GitHub issue via create-github-issue with no user clarifications. Use when asked to improve UX, scout and file a UX issue, or run improve-ux-agent.
---

# Improve UX Agent (ColonizeThis)

## When this applies

Use when the user wants an autonomous UX improvement pass that ends with a filed GitHub issue—no clarification Q&A.

## Required dependencies

Read and apply strictly — do not invent a lighter substitute:

- `.cursor/skills/suggest-player-ux-improvements/SKILL.md` — domain lock, lenses, data availability, single improvement, chat brief template.
- `.cursor/skills/create-github-issue/SKILL.md` — investigation notes, proposed fix, title/body structure, `gh` create / paste-ready fallback.

Also follow `AGENTS.md` and repository rules.

## Operating principles

1. **No user clarifications.** Never pause for numbered requirement questions, domain choice, or confirmation. Resolve ambiguity with the referenced skills’ heuristics and locked defaults.
2. **Suggest first, file second.** Complete one full `suggest-player-ux-improvements` run, then file from that brief.
3. **One improvement, one primary issue.** Prefer a single issue. If the suggest brief’s decomposition requires 2–3 dependent issues, file the primary (Issue A) and document dependents in the body; do not expand into a grab-bag backlog.
4. **Read-only until filing.** Same as the referenced skills: no code/SPEC/manual edits in this pass.

## Workflow

### 1) Run suggest-player-ux-improvements

Apply `.cursor/skills/suggest-player-ux-improvements/SKILL.md` end-to-end.

**Overrides relative to that skill:**

| Topic | This agent |
|-------|------------|
| Clarifications | Never ask; use heuristics / defaults |
| Domain lock | If user named a domain or lens, use it; otherwise pick autonomously |
| Delivery | Produce the mandatory brief in chat, then continue to filing (do not stop at “Next step for the user”) |

### 2) File via create-github-issue

Treat the suggest brief as the resolved report/requirements. Apply `.cursor/skills/create-github-issue/SKILL.md` for issue structure and `gh` filing.

**Overrides relative to that skill:**

| Topic | This agent |
|-------|------------|
| Mandatory clarification list | **Skip.** Do not present numbered clarifications or wait for confirmation |
| Source material | Map Player problem / outcome / path / proposed experience → Summary, Expected, Actual; Engineer direction → Proposed fix, ACs, SPEC/manual/`document-app-ui` follow-ups |
| Scope | Do not edit the repo beyond creating the GitHub issue |

Use `gh issue create`. If `gh` fails, output paste-ready title and body (same fallback as `create-github-issue`).

### 3) Chat output

After completion, report:

- Domain locked and improvement title
- Issue number / URL (or paste-ready draft if filing failed)
- One-line note that suggest + create-github-issue were applied with no-clarification overrides

## Guardrails

- Do not implement the improvement in this skill.
- Do not re-propose `rejected` entries from `SPEC/ui/ux-design-decisions.md` (enforced by suggest skill).
- Do not ask the user to pick among runner-ups; file the single selected improvement only.
- OpenCode shim: `.opencode/skills/improve-ux-agent/SKILL.md`
- Grok shim: `.grok/skills/improve-ux-agent/SKILL.md`
