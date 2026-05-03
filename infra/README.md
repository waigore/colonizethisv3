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

On GitHub Actions, **`pytest infra/test`** runs in the **`quality`** workflow **only when `infra/**` changes** (same path filter as the Docker AC1 job).

Optional **`RUN_INFRA_FLUTTER_DOCTOR=1`**: slow integration that runs `flutter doctor -v` in Docker (see `test_ac6_…`).

## Optional operator workflow

To push a **local** image instead of declarative `Image.from_dockerfile`, see Daytona [Using local images](https://www.daytona.io/docs/snapshots.md#using-local-images) (`daytona snapshot push`). The repo’s primary path is the Python SDK (`build-daytona-snapshot` step 2).

## Troubleshooting: `dart pub get` / pub.dev socket errors in a sandbox

1. **`run-sandbox-agent`** sets **`network_block_all=False`** (open egress for DNS and pub). When CIDRs resolve, it also sends **`network_allow_list`** (up to **10** **IPv4 /32**s): **DNS** literals (**`1.1.1.1`**, **`1.0.0.1`**, **`8.8.8.8`**, **`8.8.4.4`**), optional **`DAYTONA_EXTRA_EGRESS_RESOLVER_IPV4`**, then **round-robin** A records across Flutter/pub/GitHub hostnames (see **`infra/colonizethis_infra/network_allowlist.py`**). If **`dig`** is missing, resolution uses **`getaddrinfo`** only. If **no** host IPs resolve, **`network_allow_list`** is omitted.
2. **Extra DNS:** if the sandbox **``/etc/resolv.conf``** lists nameservers outside the built-in four (e.g. **``213.x``**), set **`DAYTONA_EXTRA_EGRESS_RESOLVER_IPV4`** to those comma-separated IPv4 addresses (no ``/32`` suffix).
3. **Override:** set **`DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS`** to a comma-separated CIDR list your org approves (pub/CDN edges change; widen if **`dart pub get`** still fails).
4. If **`curl -I https://github.com`** works but **`curl -I https://pub.dev`** resets, the problem may be **upstream** to pub’s CDN, not the allowlist—coordinate with Daytona / org networking.
