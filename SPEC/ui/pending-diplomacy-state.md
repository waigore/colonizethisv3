# Pending diplomacy state (Flutter Riverpod)

**SPEC/ui** — Single source of truth for **one** blocking diplomacy gate from turn resolution. Program dialogue contract: [dialogue-system.md](../program/dialogue-system.md).

---

## Responsibility

Expose a **discriminated** pending state so `GameScreen` shows exactly one of: overture dialogue, intervention dialogue, call-to-arms dialogue, or Favored Trading Partner dialogue. Turn resolution may return only **one** pending kind at a time; resuming may chain to another kind — the provider is **replaced** wholesale on each result.

---

## Model

Sealed variants (conceptual):

- **Overtures** — `List<OvertureOffer>`.
- **Intervention** — `List<InterventionPrompt>` (logic types).
- **Call to arms** — `List<CallToArmsPending>`.
- **Favored Trading Partner** — `List<FtpOffer>`.

`null` means no pending diplomacy gate.

---

## API

Notifier methods: `setOvertures`, `setIntervention`, `setCallToArms`, `setFtp`, `clear`. Setting any variant **clears** the others implicitly (single state field).

---

## Acceptance criteria

- Given the notifier is cleared, when any consumer reads the provider, then the value is null.
- Given the notifier holds an intervention state, when `setOvertures` is called, then the provider exposes only overture state (previous intervention is discarded).
- Given `GameScreen` applies `TurnResolutionComplete`, when the notifier is cleared, then no diplomacy overlay is visible.
