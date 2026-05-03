"""Resolve Flutter / pub / GitHub hostnames to IPv4 CIDRs for Daytona ``network_allow_list``.

Daytona accepts comma-separated **CIDRs**, not DNS names. We resolve well-known
hosts used by ``dart pub``, Flutter artifact fetches, and ``git clone`` over
HTTPS, then emit ``<ip>/32`` entries (de-duplicated).

Daytona caps ``network_allow_list`` at **10** entries. After built-in DNS
``/32``s (and optional extras from env), we add **one A record per hostname per
wave** (round-robin) so **pub** and **GitHub** both appear before deeper waves
fill from the same hosts.

**``run-sandbox-agent``** passes this string with **`network_block_all=False`**
so resolvers and pub.dev work; the allowlist still documents preferred egress
CIDRs for org policy where Daytona honors it alongside open egress.

Resolution runs on the **operator machine** (where ``run-sandbox-agent`` runs).
IPs seen from your resolver may differ from those the sandbox hits; use
``DAYTONA_FLUTTER_EGRESS_ALLOWLIST_CIDRS`` to paste org-approved CIDRs when
needed.
"""

from __future__ import annotations

import os
import socket
import subprocess
from collections.abc import Iterable

# Daytona API: "Network allow list cannot contain more than 10 networks"
_MAX_ALLOWLIST_CIDRS = 10

# When ``network_block_all=True``, the sandbox still needs **DNS** reachability;
# literal resolver IPs avoid a chicken-and-egg with hostname-derived CIDRs.
# Order: match common Docker ``resolv.conf`` (Cloudflare first), then Google.
_DNS_RESOLVER_IPV4: tuple[str, ...] = (
    "1.1.1.1",
    "1.0.0.1",
    "8.8.8.8",
    "8.8.4.4",
)

# Hostnames commonly hit for clone + ``dart pub get`` + Flutter tooling.
# ``github.com`` / ``codeload`` early so the first round-robin wave covers clone.
FLUTTER_PUB_EGRESS_HOSTS: tuple[str, ...] = (
    "pub.dev",
    "api.pub.dev",
    "github.com",
    "api.github.com",
    "codeload.github.com",
    "objects.githubusercontent.com",
    "raw.githubusercontent.com",
    "storage.googleapis.com",
)


def _is_ipv4(addr: str) -> bool:
    parts = addr.split(".")
    if len(parts) != 4:
        return False
    try:
        return all(0 <= int(p) <= 255 for p in parts)
    except ValueError:
        return False


def _dig_a_records(host: str) -> set[str]:
    try:
        proc = subprocess.run(
            ["dig", "+short", host, "A"],
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return set()
    ips: set[str] = set()
    for line in proc.stdout.splitlines():
        line = line.strip()
        if line and _is_ipv4(line):
            ips.add(line)
    return ips


def _getaddrinfo_ipv4(host: str) -> set[str]:
    ips: set[str] = set()
    try:
        infos = socket.getaddrinfo(host, 443, socket.AF_INET, socket.SOCK_STREAM)
    except OSError:
        return ips
    for _fam, _typ, _proto, _canon, sockaddr in infos:
        if len(sockaddr) < 1:
            continue
        ip = str(sockaddr[0])
        if _is_ipv4(ip):
            ips.add(ip)
    return ips


def ipv4_addresses_for_host(host: str) -> set[str]:
    """Combine ``dig`` A records (when available) with ``getaddrinfo``."""
    return _dig_a_records(host) | _getaddrinfo_ipv4(host)


def ipv4_cidrs_for_hosts(hosts: Iterable[str]) -> str:
    """Return comma-separated ``<ipv4>/32`` list, sorted, de-duplicated."""
    found: set[str] = set()
    for host in hosts:
        found |= ipv4_addresses_for_host(host)
    return ",".join(f"{ip}/32" for ip in sorted(found))


def truncate_cidr_allowlist_csv(value: str, *, max_parts: int = _MAX_ALLOWLIST_CIDRS) -> str:
    """Daytona rejects more than ``max_parts`` comma-separated CIDR tokens."""
    parts = [p.strip() for p in value.split(",") if p.strip()]
    return ",".join(parts[: max(1, min(max_parts, _MAX_ALLOWLIST_CIDRS))])


def _extra_resolver_ips_from_env() -> tuple[str, ...]:
    """Optional ``DAYTONA_EXTRA_EGRESS_RESOLVER_IPV4`` (comma-separated), e.g. host ``resolv.conf`` nameservers."""
    raw = os.environ.get("DAYTONA_EXTRA_EGRESS_RESOLVER_IPV4", "").strip()
    if not raw:
        return ()
    return tuple(p.strip() for p in raw.split(",") if p.strip())


def prioritized_ipv4_egress_cidrs(
    hosts: tuple[str, ...] = FLUTTER_PUB_EGRESS_HOSTS,
    *,
    extra_resolver_ips: tuple[str, ...] | None = None,
    max_entries: int = _MAX_ALLOWLIST_CIDRS,
) -> str:
    """Up to ``max_entries`` ``/32`` CIDRs: DNS resolvers first, then round-robin host A records."""
    seen: set[str] = set()
    cidrs: list[str] = []
    cap = max(1, min(max_entries, _MAX_ALLOWLIST_CIDRS))
    extra = extra_resolver_ips if extra_resolver_ips is not None else _extra_resolver_ips_from_env()
    dns_chain = tuple(dict.fromkeys((*_DNS_RESOLVER_IPV4, *extra)))
    for ip in dns_chain:
        if not _is_ipv4(ip) or ip in seen:
            continue
        seen.add(ip)
        cidrs.append(f"{ip}/32")
        if len(cidrs) >= cap:
            return ",".join(cidrs)
    wave = 0
    while len(cidrs) < cap:
        progressed = False
        for host in hosts:
            if len(cidrs) >= cap:
                break
            ips_sorted = sorted(ipv4_addresses_for_host(host))
            if wave >= len(ips_sorted):
                continue
            ip = ips_sorted[wave]
            if ip in seen:
                continue
            seen.add(ip)
            cidrs.append(f"{ip}/32")
            progressed = True
        if not progressed:
            break
        wave += 1
    return ",".join(cidrs)


def flutter_pub_egress_allowlist_cidrs() -> str:
    """CIDR string for ``CreateSandboxFromSnapshotParams.network_allow_list``."""
    return prioritized_ipv4_egress_cidrs(FLUTTER_PUB_EGRESS_HOSTS)
