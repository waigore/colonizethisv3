---
name: report-codebase-size
description: Reports ColonizeThis codebase size using pytool/project_stats.py with reproducible totals and category breakdowns. Use when the user asks for repository size, LOC counts, file counts, language/category distribution, or package-level code/test sizing.
---

# Report codebase size (ColonizeThis)

Single source: `pytool/project_stats.py`. Do not estimate. Prefer JSON.

```bash
python3 pytool/project_stats.py --root . --json
```

Report `total.files` / `total.lines` and category totals (`code`, `spec`, `asset`). Package/language breakdowns only if asked. Omit `__no_package__` unless asked. State that counts are from the script at execution time.

```markdown
Codebase size from `pytool/project_stats.py`:

- Total: <files> files, <lines> lines
- Code / Spec / Assets: …
```
