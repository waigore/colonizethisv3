# Daytona sandbox tooling

Python-first scripts for building a **tools-only** linux/amd64 image and running **Cursor** or **OpenCode** inside a **Daytona** sandbox. See **`SPEC/program/daytona-sandbox.md`** for contracts (`SANDBOX_AGENT`, clone resolution, env vars).

## Setup

From the repository root:

```bash
python3 -m venv .venv-infra
. .venv-infra/bin/activate
pip install -r infra/requirements.txt
```

Operator entrypoints (executable after `chmod +x` or via `bash`):

- **`infra/build-daytona-snapshot`** — Docker build + `daytona.snapshot.create`
- **`infra/run-sandbox-agent`** — sandbox from snapshot → HTTPS clone → agent CLI

## Quick examples

```bash
export DAYTONA_API_KEY=...
./infra/build-daytona-snapshot
```

```bash
export DAYTONA_API_KEY=...
export GITHUB_TOKEN=...
export GITHUB_REPOSITORY=owner/colonizethisv3
export SANDBOX_AGENT=cursor
export CURSOR_API_KEY=...
./infra/run-sandbox-agent "Summarize the repo"
```

## Tests

```bash
cd infra
python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements.txt
pytest test/ -q
```

Optional **`RUN_INFRA_FLUTTER_DOCTOR=1`**: slow integration that runs `flutter doctor -v` in Docker (see `test_ac6_…`).

## Optional operator workflow

To push a **local** image instead of declarative `Image.from_dockerfile`, see Daytona [Using local images](https://www.daytona.io/docs/snapshots.md#using-local-images) (`daytona snapshot push`). The repo’s primary path is the Python SDK (`build-daytona-snapshot` step 2).
