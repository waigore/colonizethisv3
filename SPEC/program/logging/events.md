# Logging — domain events

**SPEC/program/logging** — Annex to [logging.md](logging.md). Applies whenever **logic** (or another package) emits **game/domain events** consumed by UI, ctdev, or tests — e.g. `GameEvent`, `OrderRejectedEvent`, combat result events, diplomacy events.

---

## Info (every emission)

- **Requirement:** For **each** event **delivered** to callers (callback, bus, or stream), emit **one info** log line that includes:
  - **`event=`** stable type name (class or enum name as emitted).
  - **Identifiers:** `turn` when present; **province** / **faction** / **player** ids as applicable, using **prefixed** province ids per [world-model.md](../../game/world-model.md).
  - **Payload summary:** **Compact** string: prefer `key=value` segments, `toString()` on the event if stable, or a **small** JSON/map subset. **No secrets.**

**Implementation preference:** Centralize via a **single choke point** (e.g. wrapper on `GameEventBus` / `onGameEvent`) so new event types automatically gain logging. If a code path bypasses the choke point, that path must still log per this annex.

---

## Debug

- **Optional debug** for **construction** of complex events (e.g. before/after mutation) where it aids replay debugging. Not required for every event type if **info** summary is sufficient.

---

## Truncation and PII

- Cap line length for **info** (implementation-defined constant, documented in code). Truncate with `…` and `truncated=true` when needed.
- Do not log **full** nested maps or lists at info; summarize counts and **representative** entries.

---

## Acceptance criteria

- **Given** turn resolution emits a sequence of `GameEvent` instances to `onGameEvent`, **when** each event is emitted, **then** at least one **info** log line exists for that emission containing `event=<TypeName>` and a payload summary sufficient to distinguish duplicate emissions in the same turn.
- **Given** a new event type is added and raised from the logic package, **when** the PR is reviewed against [CONTRIBUTING.md](../../../CONTRIBUTING.md), **then** logging for that emission is verified against this annex.
