# Reference: verify-github-issue

```bash
git fetch origin && git checkout dev && git pull

rg 'matchesGoldenFile' app/test --glob '*_test.dart' -l
cd app && flutter test test/<file>.dart   # never --update-goldens

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

gh issue view 42 --json title,body,state,labels,url
gh pr list --state merged --search "Refs #42" --json number,url,mergeCommit
```
