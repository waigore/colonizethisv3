---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs), throttles concurrent CI to at most two PRs with running workflows at a time (pausing excess via `[skip ci]` empty commits plus cancelling in-flight runs), and unblocks PRs that have been blocked for more than one hour (via fix-pr). Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

# Manage PR Agent (ColonizeThis)

## When this applies

Use when the user asks to:

- Triage and move open PRs along through CI / review workflows.
- Enforce one-PR-per-issue across the repo.
- Throttle GitHub Actions usage when too many PRs are burning runner
  minutes at once.
- Unblock PRs that have been stuck for a while.

This skill performs one orderly pass and **ends**. It never sits waiting
for merges, unblocks, or workflow completion.

## Required dependencies

Read and apply these strictly — do not invent lighter substitutes:

- `.cursor/skills/consolidate-prs/SKILL.md` — used end-to-end whenever any
  open issue has two or more referencing open PRs. Apply that skill's
  workflow per affected issue; do not collapse PRs by hand.
- `.cursor/skills/fix-pr/SKILL.md` — used end-to-end for every PR identified
  as blocked for **more than one hour** (see "Stalled detection" below).
  Discover the PR via `gh`, then pass its number/URL into that skill.

Also follow `AGENTS.md`, `CONTRIBUTING.md`, and `.cursor/rules/`.

## Non-negotiables (repo policy)

- **One issue per PR** — never bundle multiple issues; consolidate via the
  dedicated skill.
- **Never wait** for CI, reviews, merges, or unblock outcomes. After each
  action (push, PR close, run cancel, label edit), move on.
- **Never close issues** here. Closing redundant PRs is allowed only via
  the `consolidate-prs` workflow.
- **Never force-push** to branches the agent did not create unless the PR
  is owned by this agent's prior work. Prefer empty commits and normal
  pushes.
- **Never delete remote branches.** Local branch hygiene belongs to
  `clean-local-branches`.
- **No quality-gate bypass.** Throttling pauses CI for budget reasons only;
  it must never be used to circumvent required checks at merge time.
- **Read base ref from PR metadata** (`gh pr view --json baseRefName`). Do
  not assume `dev`.

## Workflow

Run the phases below in order. Skip phases with no candidates and continue.

### 1. Discover state

1. List open PRs with the metadata needed for every later decision:

   ```bash
   gh pr list --state open --limit 200 --json \
     number,title,url,headRefName,baseRefName,isDraft,mergeable,mergeStateStatus,updatedAt,body,headRepository,headRepositoryOwner,statusCheckRollup
   ```

2. For each PR, extract referenced issue numbers from `title` and `body`
   (`Refs #<n>`, `Fixes #<n>`, `Closes #<n>`, `Resolves #<n>`, `gh-<n>`,
   full `…/issues/<n>` URLs — case-insensitive).
3. Group PRs by referenced issue. Note groups with >1 PR for phase 2.
4. For each open PR, compute two booleans from `statusCheckRollup` and
   `mergeStateStatus`:
   - **Has running workflows** — any check with `status` in
     `IN_PROGRESS`, `QUEUED`, `PENDING`, or `WAITING`.
   - **Is stalled** — any of:
     - `mergeable == CONFLICTING`, or
     - any required check `conclusion` in `FAILURE`, `CANCELLED`,
       `TIMED_OUT`, `ACTION_REQUIRED`, or
     - PR is open with no checks running and none completed for this head
       SHA (CI never triggered or stuck).

### 2. Enforce one PR per issue (consolidate)

For each issue with two or more referencing open PRs, apply
`.cursor/skills/consolidate-prs/SKILL.md` strictly and end-to-end. Do not
re-implement its logic here; that skill already handles canonical-PR
selection, folding, redundant-PR closure with pointer comments, and
orphan-run cancellation.

After consolidation, **re-fetch** the open-PR set (step 1's command); the
PR list will have changed and downstream phases must use the updated set.

### 3. Unblock PRs blocked > 1 hour (fix-pr)

#### Stalled detection (per PR)

A PR qualifies for `fix-pr` in this run when **all** hold:

1. It is **stalled** (per phase 1's definition), AND
2. It has been stalled for **more than 60 minutes**. Estimate "stalled
   for" as the most recent of:
   - `updatedAt` of the PR, or
   - `completedAt` of its most recent failed/cancelled required check
     (from `statusCheckRollup`), or
   - the head-commit author/commit timestamp
     (`gh api repos/{owner}/{repo}/commits/<sha> --jq '.commit.committer.date'`).

   Use the latest available signal; if it is `> 60m` ago relative to "now",
   the PR qualifies.

The 1-hour floor exists so this agent does not stomp on another agent's
in-flight work. **Skip** any PR whose stalled signal is younger than 60
minutes — leave it alone this run.

#### Action

For each qualifying PR (oldest stalled timestamp first):

- Apply `.cursor/skills/fix-pr/SKILL.md` strictly end-to-end against that
  PR's number/URL.
- After pushing the fix (or determining no fix is possible without
  out-of-scope changes), **do not wait** for remote CI. Move on.

### 4. Throttle CI to at most 2 PRs with running workflows

#### Count

Refresh open PRs and count those with **Has running workflows == true**
(phase 1 definition). Let this be `R`.

If `R <= 2`, skip this phase entirely.

#### Choose which PRs to pause

When `R > 2`, **keep** the two highest-priority running PRs and **pause**
the rest. Priority order (highest first):

1. PRs this agent just operated on in phase 2 or 3 of this run (their CI
   needs to validate the fresh push).
2. PRs marked `mergeable == MERGEABLE` whose only remaining wait is CI
   (these are closest to landing).
3. Non-draft PRs over drafts.
4. Newer `updatedAt` over older (older has had more chances; pausing it
   once is cheap).

Apply tie-breakers in order; record the chosen "keep" set and the "pause"
set explicitly in the final report.

#### Pause a PR

For each PR in the pause set:

1. Cancel its currently in-flight workflow runs so they stop consuming
   runner minutes immediately:

   ```bash
   gh run list --branch <headRefName> --limit 50 --json \
     databaseId,status,event,headSha,workflowName \
     --jq '.[] | select(.status=="in_progress" or .status=="queued")'
   # then for each databaseId:
   gh run cancel <databaseId>
   ```

   Only cancel runs whose `event` is `pull_request` or
   `pull_request_target` and whose `headSha` matches the PR's current head
   commit. Do **not** cancel `push`, `schedule`, `workflow_dispatch`, or
   `merge_group` runs based on this rule alone.

2. Prevent the next push from re-triggering CI by ensuring the latest
   commit message on the PR's head branch contains a recognised skip
   directive. GitHub Actions honours any of `[skip ci]`, `[ci skip]`,
   `[no ci]`, `[skip actions]`, `[actions skip]` in the **subject** of the
   head commit. Use `[skip ci]`.

   Prefer an **empty commit** appended to the head branch — this avoids
   rewriting history and works on PRs the agent did not author:

   ```bash
   git fetch origin <headRefName>
   git checkout -B _pause/<headRefName> origin/<headRefName>
   git commit --allow-empty -m "[skip ci] manage-pr-agent: pause CI to honour 2-concurrent-PR budget"
   git push origin HEAD:<headRefName>
   ```

   If the PR head lives on a fork (`headRepositoryOwner.login` differs
   from the upstream owner), the agent typically lacks push rights. In
   that case **do not pause** — record the PR in the report as
   "fork-owned, cannot pause" and pick the next-lowest-priority owned PR
   instead.

3. Do **not** convert the PR to draft, mark it as "do not merge", change
   labels, or add review-blocking comments. The pause is purely a CI
   budget tool.

#### Un-pausing is out of scope

This agent only pauses. Resuming CI on a paused PR happens automatically
the next time a normal (non-skip) commit lands on the head branch, or the
next time `fix-pr` runs on it. The agent does **not** loop back to verify
the pause took effect.

### 5. End the run

Do not poll workflow runs, mergeability, or label state after acting. Emit
the report (next section) and stop.

## Output in chat

Produce one consolidated report with these sections (omit empty ones):

**Consolidation (phase 2)**
- Per issue handled: issue number/URL, canonical PR, redundant PRs closed,
  outcomes — or delegate to the `consolidate-prs` skill's own report.

**Unblocks (phase 3)**
- Per PR: number/URL, stalled-for duration, `fix-pr` outcome (one line),
  push SHA if any.
- PRs skipped because stalled < 60 min: list with the stalled timestamp.

**CI throttle (phase 4)**
- Total running PRs before/after.
- Kept-running PRs (with rationale: priority rule that won).
- Paused PRs: number/URL, cancelled `databaseId`s, push SHA of the
  `[skip ci]` empty commit.
- PRs that should have been paused but were skipped (fork-owned, etc.).

**No-op phases**
- One line per phase that had no candidates.

## Guardrails

- Never wait for CI, merges, reviews, or unblock confirmation.
- Never bundle multiple issues into one PR.
- Never close issues. Closing redundant PRs only via `consolidate-prs`.
- Never delete remote branches.
- Never bypass required checks; pausing is for budget only and is undone
  by the next normal commit.
- Never `gh run cancel` a workflow run whose event is not
  `pull_request`/`pull_request_target` based on this skill's throttle rule
  alone.
- If `gh` is unavailable, emit the exact prepared commands and commit
  bodies for manual follow-up instead of guessing.
- If a PR's head is on a fork and pausing requires a push, skip pausing
  that PR and surface it in the report rather than attempting force-push
  or branch creation in the upstream repo.
