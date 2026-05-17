---
name: backlog-implement-agent
description: Optimizes code throughput across open issues labeled backlog:implementation. Each run does substantial work and never waits for CI, reviews, or merges. Unblocks stalled PRs via strict fix-pr (then moves on) and applies strict implement-github-issue for new work. Each PR targets exactly one issue. Relabels to backlog:verification only when an issue is fully done.
---

# Backlog Implement Agent (OpenCode)

## Source of truth

`.cursor/skills/backlog-implement-agent/SKILL.md` is authoritative for operating principles, dependencies, label policy, scope decisions, and output requirements.

## OpenCode adaptation

- Use `gh issue list --state open --label "backlog:implementation"` to enumerate candidates.
- Use `gh pr list --search "<refs to issue>"` to find open PRs referencing those issues.
- Read and follow `.cursor/skills/fix-pr/SKILL.md` strictly when any in-scope PR is stalled, and `.cursor/skills/implement-github-issue/SKILL.md` strictly for new implementation work.
- Multiple issues per run are allowed; each PR must target exactly one issue.
- Never wait for CI, reviews, or merges. After an unblock or push, move on to the next useful unit of work.

## Required references

- `.cursor/skills/backlog-implement-agent/SKILL.md`
- `.cursor/skills/implement-github-issue/SKILL.md`
- `.cursor/skills/fix-pr/SKILL.md` (when any in-scope PR is stalled)
