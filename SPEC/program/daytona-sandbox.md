# Daytona agent sandbox (infra)

Authoritative operator contract for **`infra/build-daytona-snapshot`** and **`infra/run-sandbox-agent`**. GitHub issue **#2065** tracks delivery; this document is the SPEC mirror for naming, env vars, and clone resolution.

## Goals

- **linux/amd64** Ubuntu-based **tools-only** image: Flutter (`stable` resolved at **image build time**), Dart within root **`pubspec.yaml`** `environment.sdk`, Android SDK, Linux desktop build deps, **xvfb**, **git**, **gh**, **Cursor CLI** (`agent`), **OpenCode CLI** (`opencode` via npm global). **No** repository clone in the image.
- **Clone after start** over **HTTPS** using **`GITHUB_TOKEN`** (and Daytona sandbox APIs).
- **Manual** snapshot lifecycle: operators run **`infra/build-daytona-snapshot`** to rebuild when toolchains should advance.

## Scripts (repo root relative)

| Entry | Role |
|-------|------|
| **`infra/build-daytona-snapshot`** | Thin shim → **`python3 -m colonizethis_infra.build_daytona_snapshot`**. (1) `docker build --platform linux/amd64`. (2) Register a Daytona Snapshot via Python **`daytona.snapshot.create`** with **`on_logs`**. |
| **`infra/run-sandbox-agent`** | Thin shim → **`python3 -m colonizethis_infra.run_sandbox_agent`**. Create sandbox from snapshot → clone → run **Cursor** or **OpenCode** with the given prompt. |

Install Python deps once per machine/CI: **`pip install -r infra/requirements.txt`** (see **`infra/README.md`**).

## `SANDBOX_AGENT` (canonical)

| Rule | Value |
|------|--------|
| Name | **`SANDBOX_AGENT`** only (no `AGENT`, `CT_AGENT`, or other aliases for backend selection). |
| Legal values | **`cursor`**, **`opencode`** (lowercase). Invalid → exit **non-zero**; message **quotes** the value and lists legal values. |
| CLI override | **`--agent cursor`** \| **`--agent opencode`** overrides **`SANDBOX_AGENT`** when both are set. |
| Required | At least one of **`--agent`** or a **non-empty** **`SANDBOX_AGENT`** (after trim) must select the backend; else **usage** error naming **`SANDBOX_AGENT`** and **`--agent`** with examples `SANDBOX_AGENT=cursor`, `SANDBOX_AGENT=opencode`. |
| Empty / whitespace | **`SANDBOX_AGENT=`** or whitespace-only → **unset**; fall back to **`--agent`**. |

If **`AGENT`** or **`CT_AGENT`** is set (non-empty), **`run-sandbox-agent`** exits **non-zero** with a hint to use **`SANDBOX_AGENT`**.

## Other environment variables

| Variable | Role |
|----------|------|
| **`DAYTONA_API_KEY`** | Required for Daytona API (build snapshot registration + run sandbox). |
| **`DAYTONA_API_URL`**, **`DAYTONA_TARGET`** | Optional Daytona SDK overrides ([Configuration](https://www.daytona.io/docs/en/configuration.md)). |
| **`DAYTONA_SNAPSHOT_NAME`** | Optional; default sticky name **`colonizethis-daytona-flutter-tools`** (constant in `infra/colonizethis_infra/constants.py`). |
| **`GITHUB_TOKEN`** | HTTPS clone + `gh`. |
| **`CURSOR_API_KEY`** | Required when backend is **cursor** (before invoking Cursor). |
| **`OPENCODE_API_KEY`** | Required when backend is **opencode**. |
| **`OPENCODE_MODEL`** | Optional; default **`opencode-go/qwen3.6-plus`** (matches `.github/workflows/opencode.yml`). |
| **`GITHUB_REPOSITORY`** | Optional `owner/repo` for clone target. |
| **`GIT_REF`** | Optional branch, tag, or SHA for clone checkout semantics. |

## Clone target resolution (first hit wins)

1. **`--repo owner/repo`** and **`--ref`** (CLI) when passed.
2. **`GITHUB_REPOSITORY`** / **`GIT_REF`**.
3. **Local inference** (optional): from **`git remote get-url origin`** in the current working directory **only** when **`GITHUB_ACTIONS`** is **unset** (fail-closed in CI).
4. Otherwise **non-zero** exit listing required inputs.

## Default snapshot image tag (local Docker)

**`colonizethis-daytona-flutter-tools:local`** — used by **`build-daytona-snapshot`** step 1; step 2 passes **`Image.from_dockerfile`** for the same **`infra/Dockerfile`** to Daytona’s declarative builder (see Daytona [Snapshots](https://www.daytona.io/docs/snapshots.md)).

## Acceptance criteria ↔ tests

| AC | Test location / gate |
|----|----------------------|
| **AC1** | **Strong:** `.github/workflows/quality.yml` job **“Infra Daytona docker build (linux/amd64)”** (`infra_daytona_docker_build`) runs **`docker build --platform linux/amd64 -f infra/Dockerfile infra`** when **`infra/**`** changes. **Supplementary:** `infra/test/test_ac1_dockerfile_pubspec_sdk.py` parses root **`pubspec.yaml`** `environment.sdk` vs Dockerfile **`CT_PUBSPEC_SDK_LOWER_BOUND`** marker. |
| **AC2** | `infra/test/test_ac2_snapshot_register.py` mocks **`daytona.snapshot.create`**. |
| **AC3** | `infra/test/test_ac3_clone_resolution.py` URL + **`git clone`** contract / resolution order. |
| **AC4** | `infra/test/test_ac4_cursor_api_key.py`. |
| **AC5** | `infra/test/test_ac5_opencode_model.py`. |
| **AC6** | `infra/test/test_ac6_flutter_doctor_integration.py` — **skipped** unless **`RUN_INFRA_FLUTTER_DOCTOR=1`** (optional slow / Docker). |

**CI:** In **`.github/workflows/quality.yml`**, the **`quality`** job runs **`pytest infra/test`** only when the **`infra_daytona`** path filter is true (**`infra/**`** changed); Dart/app gates continue to use the existing **`tests`** filter.

## OpenCode / Cursor invocation (v1)

- **OpenCode:** `opencode run -m <resolved-model> <prompt>` (single shell command; prompt shell-quoted).
- **Cursor:** `agent -p <prompt>` with **`CURSOR_API_KEY`** in the process environment (headless pattern per Cursor CLI docs).
