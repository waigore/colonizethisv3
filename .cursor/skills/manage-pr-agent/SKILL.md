---
name: manage-pr-agent
description: Keeps open pull requests moving through CI and GitHub workflows in an orderly manner. Enforces one open PR per GitHub issue (via consolidate-prs) and maintains a running-CI quota of 2 PRs (both floor and ceiling) by pausing excess via `[skip ci]` empty commits, resuming paused PRs, and unblocking stalled PRs via fix-pr (older PRs first) whenever the quota has headroom. Performs actions once and then ends the run without waiting for merges, CI, or unblock confirmation. Use when the user asks to tidy, throttle, unblock, or generally manage in-flight PRs.
---

# Manage PR Agent (ColonizeThis)

## When this applies

Use when the user asks to:

- Triage and move open PRs along through CI / review workflows.
- Enforce one-PR-per-issue across the repo.
- Throttle GitHub Actions usage so a constant 2 PRs are running CI at a
  time (both floor and ceiling).
- Unblock stalled PRs to keep PRs flowing toward merge.

This skill performs one orderly pass and **ends**. It never sits waiting
for merges, unblocks, or workflow completion.

## Required dependencies

Read and apply these strictly — do not invent lighter substitutes:

- `.cursor/skills/consolidate-prs/SKILL.md` — used end-to-end whenever any
  open issue has two or more referencing open PRs. Apply that skill's
  workflow per affected issue; do not collapse PRs by hand.
- `.cursor/skills/fix-pr/SKILL.md` — used end-to-end on stalled PRs picked
  during the maintain-CI-throughput phase (see phase 3). Apply only while
  the running-CI count is under the quota of 2, generally **oldest PR
  first**. Discover the PR via `gh`, then pass its number/URL into that
  skill.

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

### 3. Maintain CI throughput target of 2

The quota is **2 PRs with CI running** — both floor and ceiling. Fewer
than 2 wastes throughput; more than 2 wastes runner minutes. **Skip this
phase entirely when total open PRs < 2** (the quota cannot be filled).

#### Compute counts

From the (refreshed) phase 1 data, let:

- `R` = open PRs with **Has running workflows == true** (phase 1).
- `P` = open **non-fork** PRs whose head-commit subject contains a
  recognised skip directive — `[skip ci]`, `[ci skip]`, `[no ci]`,
  `[skip actions]`, or `[actions skip]`. These are the resumable PRs.
- `S` = stalled open PRs (phase 1 definition), **excluding** any already
  in `P`, ordered by `updatedAt` ascending (oldest first).

#### Cases

- `R > 2` → **Pause** `R - 2` PRs.
- `R < 2` → **Fill** toward `R == 2`.
- `R == 2` → no-op; record "quota met" in the report.

Pause / resume / fix-pr calls are fire-and-forget; the agent does not
wait for CI to start or stop. Each successful push to a head branch
logically increments the projected `R` by 1 for the duration of this
phase only.

#### Pause (R > 2)

Keep the two highest-priority running PRs and pause the rest. Priority
order (highest first):

1. PRs this agent just operated on in phase 2 of this run (their CI
   needs to validate the fresh push).
2. PRs marked `mergeable == MERGEABLE` whose only remaining wait is CI
   (closest to landing).
3. Non-draft PRs over drafts.
4. Newer `updatedAt` over older (older has had more chances; pausing it
   once is cheap).

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
   `pull_request_target` and whose `headSha` matches the PR's current
   head commit. Do **not** cancel `push`, `schedule`, `workflow_dispatch`,
   or `merge_group` runs based on this rule alone.

2. Append an empty `[skip ci]` commit to the head branch so the next
   push does not retrigger CI. Use an empty commit (no history rewrite,
   works on PRs the agent did not author):

   ```bash
   git fetch origin <headRefName>
   git checkout -B _pause/<headRefName> origin/<headRefName>
   git commit --allow-empty -m "[skip ci] manage-pr-agent: pause CI to honour 2-PR quota"
   git push origin HEAD:<headRefName>
   ```

   Fork-owned PRs (`headRepositoryOwner.login` differs from upstream)
   cannot be paused via push — **skip** them and pick the
   next-lowest-priority owned PR instead. Record the skipped fork PR in
   the report.

3. Do **not** convert the PR to draft, mark it as "do not merge", change
   labels, or add review-blocking comments. The pause is purely a CI
   budget tool.

#### Fill (R < 2)

Push toward projected `R == 2`. Stop as soon as projected `R == 2` or
both `P` and `S` are exhausted for this run. The goal is **PRs moving
toward merge**; the agent has discretion over which lever to pull next
and may interleave them.

- **Resume a paused PR** (from `P`) by appending a non-skip empty commit
  to its head branch — cheap; retriggers CI without altering content:

  ```bash
  git fetch origin <headRefName>
  git checkout -B _resume/<headRefName> origin/<headRefName>
  git commit --allow-empty -m "chore: resume CI (manage-pr-agent)"
  git push origin HEAD:<headRefName>
  ```

- **Unblock a stalled PR** (from `S`) by applying
  `.cursor/skills/fix-pr/SKILL.md` strictly end-to-end against that PR's
  number/URL. Generally prefer the **oldest `updatedAt` first**; the
  agent may pick a clearly-closer-to-merge PR instead (e.g., one whose
  only failure is a flaky check) and must record the deviation in the
  report.

Fork-owned PRs cannot be resumed via push — skip them for resume too and
record in the report. Fork-owned PRs still count toward `R` when their
CI is running.

### 4. End the run

Do not poll workflow runs, mergeability, or label state after acting. Emit
the report (next section) and stop.

## Output in chat

Produce one consolidated report with these sections (omit empty ones):

**Consolidation (phase 2)**
- Per issue handled: issue number/URL, canonical PR, redundant PRs closed,
  outcomes — or delegate to the `consolidate-prs` skill's own report.

**CI throughput (phase 3)**
- Total open PRs; `R` before; projected `R` after; quota target = 2.
- Branch taken: pause (`R > 2`), fill (`R < 2`), or quota met (`R == 2`).
- **Paused PRs** (when pausing): number/URL, cancelled `databaseId`s,
  push SHA of the `[skip ci]` empty commit, and the priority rule that
  saved each kept-running PR.
- **Resumed PRs** (when filling): number/URL, push SHA of the resume
  commit.
- **Unblocked PRs** (when filling): number/URL, `fix-pr` outcome (one
  line), push SHA if any. Note any deviation from oldest-first ordering
  with a one-line reason.
- **Skipped**: fork-owned PRs (cannot pause/resume), candidates left
  untouched because the quota was already met, etc.

**No-op phases**
- One line per phase that had no candidates (including "open PRs < 2,
  quota phase skipped" when applicable).

## Guardrails

- Never wait for CI, merges, reviews, or unblock confirmation.
- Never bundle multiple issues into one PR.
- Never close issues. Closing redundant PRs only via `consolidate-prs`.
- Never delete remote branches.
- Never bypass required checks; pausing is for budget only and is undone
  by the next normal commit.
- Never merge PRs. The agent only keeps PRs *in a mergeable state*;
  merging is performed by the normal review/merge workflow.
- Never `gh run cancel` a workflow run whose event is not
  `pull_request`/`pull_request_target` based on this skill's throttle rule
  alone.
- Resume CI only via plain non-skip empty commits (e.g.,
  `chore: resume CI`); never force-push, never rewrite history.
- If `gh` is unavailable, emit the exact prepared commands and commit
  bodies for manual follow-up instead of guessing.
- If a PR's head is on a fork and pause/resume requires a push, skip the
  PR for both directions and surface it in the report rather than
  attempting force-push or branch creation in the upstream repo.
