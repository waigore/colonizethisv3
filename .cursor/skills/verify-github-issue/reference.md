# Reference: verify-github-issue

## Baseline

- PRs → **`dev`**. Coverage 90% (logic/ai/map) / 80% (elsewhere).
- App tests: **`cd app && flutter test`** — not `dart test` from repo root.
- UI proof: widget goldens in `app/test/`, PNGs in `app/test/goldens/`.

## Verify on dev

```bash
git fetch origin && git checkout dev && git pull
```

## Golden discovery and run

```bash
rg 'matchesGoldenFile' app/test --glob '*_test.dart' -l
cd app && flutter test test/<file>.dart   # never --update-goldens
```

## Gist upload + comment

```bash
ISSUE=42
PROOF_DIR="tmp/verify-issue-${ISSUE}"
mkdir -p "$PROOF_DIR"
cp app/test/goldens/<file>.png "$PROOF_DIR/"

GIST_URL=$(gh gist create --public "$PROOF_DIR"/*.png -d "Verify #${ISSUE}" 2>&1 | tail -1)
GIST_ID="${GIST_URL##*/}"
OWNER=$(gh api "gists/${GIST_ID}" --jq .owner.login)
# Embed: https://gist.githubusercontent.com/${OWNER}/${GIST_ID}/raw/<file>.png

gh issue comment "$ISSUE" --body-file verification.md
rm -rf "$PROOF_DIR"
```

## gh

```bash
gh issue view 42 --json title,body,state,labels,url
gh issue comment 42 --body-file verification.md
gh pr list --state merged --search "Refs #42" --json number,url,mergeCommit
```
