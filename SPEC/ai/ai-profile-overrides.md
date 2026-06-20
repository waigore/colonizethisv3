# AI Profile Overrides (decision-path wiring)

**SPEC/ai** — Authorizes wiring `AiProfile` parameter overrides into the live Full-AI decision path so external tools (Observer `--profiles`, GA runner) can replace hardcoded AI-behavior constants per Great Power. Derives from [ai-parameter-registry.md](ai-parameter-registry.md) (profile/registry contract) and [ai-personalities.md](ai-personalities.md). Tracked by GitHub **#3437** (consumed by GA runner **#3439**).

---

## Purpose

`AiProfile` (#3436) defines the registry-keyed parameter set but does not change AI behavior. This spec defines how a resolved profile, supplied per `playerId`, overrides the parameters the Full-AI planner would otherwise read from `ai_personality_config.dart` and `ai_victory_config.dart`.

Overrides are injected as an **optional parameter** into the AI entrypoints (`observer → AI`), never via global state, preserving determinism and the `colonizethis-logic-ai-decoupling` one-way boundary (no `logic → AI` edge is introduced).

---

## Override carrier

`AIConfig` gains two optional fields, both defaulting to `null`:

- `parameterOverrides` — the active profile's full `parameters` map (registry-keyed `name → num`), or `null` when no profile is active.
- `profileId` — the active profile's `profile_id`, or `null`.

When `parameterOverrides` is `null`, AI behavior is **byte-for-byte identical** to the no-profile path.

## Override-resolution rule

For each registry-declared parameter `name`, the **effective value** is:

- the profile value `parameterOverrides[name]` **when** that value differs from `AiParameterRegistry.defaults[name]` (i.e. the profile sets a non-default value);
- otherwise the leader's hardcoded value (the existing `getXForLeader` / constant lookup).

This honors the issue rule "override applies to registry-declared parameters with non-default values": a parameter left at (or explicitly set to) the registry default keeps the leader's hardcoded value, so a seed profile that mirrors a leader reproduces that leader's behavior.

## Scope of this slice (#3437)

In scope now: the **personality categories** (`personality_domain`, `personality_goal`, `personality_threshold`). These resolve through `resolveDomainWeights`, `resolveGoalWeights`, and `resolveThresholds` in `colonizethis_data`, replacing the bare `getDomainWeightsForLeader` / `getGoalWeightsForLeader` / `getThresholdsForLeader` lookups at every `AIConfig`-consuming call site (goal selection, planner-context base weights, economy/build/research/diplomacy scoring, and the AI trace builder).

Deferred (separate follow-up): `victory_config` category overrides (the `k*` constants are referenced as bare top-level `const`s across the AI package and require a dedicated config-threading design to preserve the turn-resolution budget and determinism); and the colonial-acquisition war-vs-alliance bias, which threads a bare `personalityId` through phase-planner dispatch rather than `AIConfig`. Until then those read leader defaults even when a profile is active.

## Trace

The active `profileId` is recorded under the existing `TurnTraceAiSection.state.decisionContext.profileId`, so no logic-level trace schema change is required. When no profile is active for a Great Power, the key is `null`.

---

## Acceptance criteria

- Given an `AIConfig` with `parameterOverrides == null`, when `resolveDomainWeights`/`resolveGoalWeights`/`resolveThresholds` run for that config's `personalityId`, then each returned value equals the corresponding `getXForLeader(personalityId)` value.
- Given a profile whose `personalityDomainWeights.military` differs from the registry default and whose other keys equal the registry default, when `resolveDomainWeights` runs for a leader, then only `military` takes the profile value and `economy`/`diplomacy`/`research` keep the leader's hardcoded values.
- Given a profile key whose value equals the registry default, when the matching `resolveX` runs, then the leader's hardcoded value is kept (the default-valued key does not override).
- Given a Great Power planned with an active profile, when its `TurnTraceAiSection` is built, then `state.decisionContext.profileId` equals the profile's `profile_id`; given no active profile, then `state.decisionContext.profileId` is `null`.
- Given `generateOrdersForGameFullAI` called with `profiles == null`, when orders are generated, then the emitted orders and trace are identical to a call that omits `profiles`.
