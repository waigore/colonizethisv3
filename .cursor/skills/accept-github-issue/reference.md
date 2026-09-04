# Reference: accept-github-issue

Tool cookbook and checklists for the three acceptance procedures. Read `SKILL.md` first.

## Baseline

```bash
git fetch origin && git checkout dev && git pull
cd app && flutter test          # app tests — not `dart test` from repo root
melos run test_app              # same, via melos
```

---

## §A Gameplay/UI — in-app AC execution

### A.1 Turn ACs into test cases

One executable case per AC (`## Suggested acceptance criteria` / Given-When-Then blocks): **Given** → setup path (menu flow, new-game config), **When** → driver actions, **Then** → widget-tree state (text, keys, visibility) and/or screenshot content. Gameplay-logic ACs with no visual component use the headless path (A.4).

### A.2 Launch and drive the app (Flutter MCP/DTD — preferred)

Works on macOS and Linux hosts; the app ships desktop runners (`app/macos/`, `app/linux/`).

1. `dart_list_devices` → pick the desktop device (`macos` on macOS hosts, `linux` on Linux).
2. `dart_launch_app(root: "<repo>/app", device: "<id>")` → `{ pid, dtdUri }`. First build can take minutes; poll `dart_get_app_logs(pid)`.
3. `dart_connect_dart_tooling_daemon(uri: dtdUri)`.
4. `dart_get_widget_tree(summaryOnly: true)` → discover real keys/text. **Never guess locators** — prefer the stable `k*Key` constants used by `app/integration_test/` and `packages/colonizethis_app_e2e_support/lib/` (e.g. `kHomeToCapitalButtonKey`).
5. Drive with `dart_flutter_driver`: `waitFor`/`waitForTappable` before every `tap` (visibility-first per `colonizethis-e2e-ui-stability.mdc`); `enter_text`, `scrollIntoView`, `get_text`, `get_offset` for assertions; `screenshot` at every visual **Then** step → save under `tmp/accept-issue-<n>/`.
6. New-game flow: Main Menu → New Game → configure per AC → start → map. Mirror the key sequences documented in `app/integration_test/new_game_*_e2e_test.dart`.
7. Next-turn ACs: sustained resolution over the turn-resolution budget is a defect (`colonizethis-turn-resolution-budget.mdc`). Touched game-app surfaces: standing 1 s open + unmount per `SKILL.md`.
8. `dart_get_runtime_errors` before finishing; `dart_stop_app(pid)` when done.

If MCP tools are absent: fall back to A.3/A.4 and note it in the comment.

### A.3 Fallback — existing e2e suites as executed evidence

```bash
cd app && flutter test integration_test/<file>.dart -d macos   # or: -d linux
```

5-minute wall-clock cap per scenario path; a timeout is a FAIL, not a skip. Do **not** author new e2e tests during acceptance — drive the app manually (A.2) or record a gap.

### A.4 Headless gameplay assertions

```bash
dart run init_game          # game creation pipeline (map gen, capitals, towns)
dart run run_observer_game  # full-AI turns with traces/snapshots
```

Assert AC conditions against generated state (JSON/snapshots) and targeted package tests (`packages/<name>/test/`); record commands + assertions in the comment.

### A.5 Screenshot proof

```bash
ISSUE=<n>
PROOF_DIR="tmp/accept-issue-${ISSUE}"
GIST_URL=$(gh gist create --public "$PROOF_DIR"/*.png -d "Accept #${ISSUE}" 2>&1 | tail -1)
GIST_ID="${GIST_URL##*/}"
OWNER=$(gh api "gists/${GIST_ID}" --jq .owner.login)
# Embed: https://gist.githubusercontent.com/${OWNER}/${GIST_ID}/raw/<file>.png
```

Verify each raw URL with `curl -sfI`; delete `$PROOF_DIR` after posting.

---

## §B Refactor — verification-based acceptance

Refactor issues contract to **byte-identical runtime behavior, no UX change**. That proof already happened at **verification** (`verify-github-issue`): AC↔code↔SPEC↔test closure on merged `dev`, with suites run. Acceptance therefore does **no re-testing and no diff audit** — it confirms the issue is verified and that `dev` still matches what was verified, then accepts as-is.

### B.1 Confirm passing verification

```bash
gh issue view <n> --json comments --jq '.comments[] | {author: .author.login, body: .body}'
```

- Locate the latest **Verification** comment with outcome **Complete**. None, or a **Gaps remain** outcome → **REJECT**; gap: run `verify-github-issue` first.
- Confirm it covers the issue's ACs and names the merged PR(s).

### B.2 Confirm merged state matches

```bash
git fetch origin && git checkout dev && git pull
git log --oneline <verified-sha>..HEAD -- <paths the issue touched>   # scope drift check
```

- Work not merged on `origin/dev` → **REJECT**.
- Material drift in the issue's scope since the verified sha → **REJECT**; gap: re-run verification.

### B.3 Verdict

Verification **Complete** + merged state matches → **ACCEPT**, citing the verification comment (and its recorded test runs) as the per-AC evidence. Do not re-run `melos`/package tests or audit hunks at acceptance.

---

## §C Art generation — vision acceptance

### C.1 Contract checks

- Files exist at contracted paths (e.g. `app/assets/images/terrain/tilesets/<name>.png` + `.json` sidecar); dimensions/layout match the contract (e.g. 256×256 for a 4×4 × 64 px atlas).
- Run the issue's contracted tests (`cd app && flutter test test/<file>.dart`).

### C.2 Vision checklist (built-in vision)

**Read every generated/updated PNG** (the Read tool renders images). Score each:

1. **Not a placeholder** — real generated detail (compare against any `*_backup.png` / prior revision).
2. **Contract geometry** — canvas size, tile grid, mask count, alpha channel.
3. **Edge/mask continuity** — connection atlases (roads, rails, coasts): tiles sharing an edge connect with no systematic seam gaps at typical zoom; mentally tile mask pairs (N+S, E+W).
4. **Style coherence** — read 2–3 **peer shipped assets** in the same directory/theme (e.g. `tileset_sea_plains_v2_64.png`, variants under `app/assets/themes/<theme>/…`); compare palette, outline weight, shading density, perspective. Off-palette or hyper-detailed outliers fail.
5. **No generation artifacts** — garbled geometry, smeared edges, banding, stray text.
6. **Theme parity** — themed variants each pass 1–5.

Record per-file verdicts in the comment; embed the atlas (and seam-join crops) via gist (A.5).

### C.3 In-situ check (when the asset renders in-game)

Launch the app (A.2), reach a map state rendering the asset, screenshot, confirm aesthetic fit and seams in situ.
