---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs), throttles concurrent CI to at most two PRs with running workflows at a time (pausing excess via `[skip ci]` empty commits plus cancelling in-flight runs), and unblocks PRs that have been blocked for more than one hour (via fix-pr). Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

# Manage PR Agent (ColonizeThis) — OpenCode

This OpenCode skill **defers** to the canonical Cursor skill to avoid drift.

## Read and follow

`.cursor/skills/manage-pr-agent/SKILL.md` (same repository).

That file is normative. It defines:

- Discovery of open PRs with mergeability, check rollup, and head/base
  metadata (single snapshot reused by every later phase).
- One-PR-per-issue enforcement by deferring strictly to
  `.cursor/skills/consolidate-prs/SKILL.md`.
- The > 60 minute "stalled-for" detection rule and strict use of
  `.cursor/skills/fix-pr/SKILL.md` to unblock qualifying PRs.
- CI throttling to at most two PRs with running workflows: priority order
  for which to keep running, and the pause mechanism (cancel in-flight
  `pull_request` / `pull_request_target` runs, then push an empty
  `[skip ci]` commit on the PR's head branch).
- Fork-owned head handling, never-wait policy, and guardrails (no issue
  closure, no remote branch deletion, no required-check bypass, no
  force-push).
- Output format with consolidation / unblocks / CI-throttle / no-op
  sections.

If `.cursor/skills/manage-pr-agent/SKILL.md` is unavailable, stop and ask
the user how to proceed — do not improvise a PR-management workflow.
