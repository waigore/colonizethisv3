---
name: report-codebase-size
description: Reports ColonizeThis codebase size using pytool/project_stats.py with reproducible totals and category breakdowns. Use when the user asks for repository size, LOC counts, file counts, language/category distribution, or package-level code/test sizing.
---

# Report codebase size (ColonizeThis)

## When this applies

Use this skill whenever the user asks for codebase size, lines of code, file counts, package totals, or language/category size breakdowns for this repository.

## Canonical data source

- Always use `pytool/project_stats.py` from this repo as the single source of truth.
- Do not estimate counts manually and do not infer totals from partial folder scans.
- Prefer JSON mode for precise parsing; use human-readable mode only when explicitly requested.

## Required command

Run from repo root:

```bash
python3 pytool/project_stats.py --root . --json
```

Fallback if `python3` is unavailable:

```bash
python pytool/project_stats.py --root . --json
```

## Reporting rules

1. Parse and report `total.files` and `total.lines`.
2. Include top-level category totals from `totals` (`code`, `spec`, `asset` when present).
3. If the user asks for package detail, use `by_package` and `by_package_role`.
4. If the user asks for language detail, use `by_language` or `by_package_language`.
5. Exclude synthetic package `__no_package__` unless the user explicitly asks for uncategorized files.
6. State that counts come from `pytool/project_stats.py` and reflect the current workspace state at execution time.

## Default response template

Use this structure unless the user requests a different format:

```markdown
Codebase size from `pytool/project_stats.py`:

- Total: <files> files, <lines> lines
- Code: <files> files, <lines> lines
- Spec: <files> files, <lines> lines
- Assets: <files> files, <lines> lines

Optional details (only when requested):
- By package: ...
- Code main vs test by package: ...
- By language: ...
```

Only include categories that exist in the JSON output.

## Validation checklist

- Command executed successfully (exit code 0).
- JSON parsed successfully.
- Reported numbers exactly match emitted JSON values.
- Any omitted section is intentionally omitted because the user did not ask for it.
