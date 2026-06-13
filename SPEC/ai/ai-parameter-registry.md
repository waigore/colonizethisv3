# AI Parameter Registry & Profile Format

**SPEC/ai** — Externalizes tunable AI-behavior parameters into a machine-readable registry and a JSON profile format, the foundational data layer for genetic-algorithm tuning. Source: [ai-personalities.md](ai-personalities.md), [ai-architecture.md](ai-architecture.md). Constants live in `packages/colonizethis_data` (`ai_personality_config.dart`, `ai_victory_config.dart`). Tracked by GitHub #3436 (required-by Observer `--profiles` #3437, GA runner #3439).

---

## Purpose

AI behavior is governed by numeric constants that are currently hardcoded. To tune them with a genetic algorithm they must be (1) declared in a registry with bounds and defaults, (2) serializable to/from JSON profiles, and (3) extensible so new constants flow into profiles automatically.

This spec authorizes the registry and profile **data layer only**. Wiring profile overrides into the live AI decision path is out of scope (tracked separately by #3437).

---

## Parameter registry

`AiParameterRegistry` declares one `AiParameter` per tunable constant. Each `AiParameter` has: `name` (canonical key), `category`, `isInteger`, `minValue`, `maxValue`, `defaultValue`, `description`.

Registry API: `allParams`, `defaults` (name→default), `byCategory(category)`, `byName(name)`.

**In scope:** every numeric (`int`/`double`) constant in `ai_personality_config.dart` and `ai_victory_config.dart` that affects AI behavior.
**Out of scope:** `String` constants (`kOldWorldRegionId`, `kNewWorldRegionId`), `bool`/utility functions, and infrastructure constants (`kMaxDossierEvidenceEntries`). Hidden agendas and starting-resources config stay separate.

### Categories

`personality_domain`, `personality_goal`, `personality_threshold`, `victory_config`. The `category` is metadata only and is **not** part of the key.

### Canonical key naming

- Personality params: `<sourceMapName>.<fieldName>` (e.g. `personalityDomainWeights.economy`, `personalityThresholds.warLikelihood`). A profile represents one leader, so the per-leader map key is omitted.
- Victory-config params: the flat Dart constant identifier (e.g. `kDeclareWarAdjacentOwnerBonus`), no synthetic prefix.

### Bounds

| Param type | Min | Max |
|---|---|---|
| Domain / goal / threshold | 0 | 100 |
| Victory-config `int` | 0 | max(2000, 4 × default) |
| Victory-config `double` | 0.0 | 4 × default |

All in-scope defaults are non-negative, so a `0`/`0.0` floor is correct. Bounds are stored per parameter (`minValue`); a future negative-default parameter MUST set an explicit `-N × |default|` lower bound rather than clamp to 0.

---

## JSON profile format

```json
{
  "schema_version": 1,
  "profile_id": "victoria_seed",
  "display_name": "Victoria (seed)",
  "parameters": { "personalityDomainWeights.economy": 70 }
}
```

`AiProfile` (`ai_profile.dart`) resolves one full per-leader parameter set:

- `fromJson` iterates `AiParameterRegistry.allParams`; for each param it takes the JSON value if present else the registry default, clamps to `[minValue, maxValue]`, and rounds to int when `isInteger`. The resulting `parameters` map therefore contains exactly the full registry key set.
- Keys in JSON not in the registry are ignored and logged once at `warning` (prefix `data:`) per unknown key.
- `toJson` emits `schema_version`, `profile_id`, `display_name`, and the complete `parameters` map.
- Typed accessors convert back to config objects: `toDomainWeights()`, `toGoalWeights()`, `toThresholds()`, `victoryConfigOverride(constName)`, plus `valueOf(name)`.

The only supported `schema_version` is `1`.

---

## Seed profiles

The 7 existing leader configs (`victoria`, `napoleon`, `isabella`, `henry`, `deruyter`, `frederick`, `gustavus`) are exported as JSON files under `packages/colonizethis_data/lib/src/profiles/<leaderId>.json`, co-located with the registry. Each seed sets its personality params from the leader's hardcoded config and its victory-config params from the registry defaults. Dart consumers read them via `seedAiProfiles` / `seedAiProfilesById`; downstream tools materialize them to disk from these accessors.

---

## Acceptance criteria

- Given the registry, when `allParams` is read, then it contains an `AiParameter` for every in-scope numeric constant in `ai_personality_config.dart` and `ai_victory_config.dart`, and contains no entry for `kMaxDossierEvidenceEntries`, `kOldWorldRegionId`, or `kNewWorldRegionId`.
- Given a registered parameter, when its metadata is read, then `name`, `category`, `isInteger`, `minValue`, `maxValue`, `defaultValue`, and `description` are all populated, with `minValue <= defaultValue <= maxValue`.
- Given a personality parameter, when its key is read, then the key equals `<sourceMapName>.<fieldName>`; given a victory-config parameter, then the key equals the flat Dart constant identifier.
- Given a profile JSON omitting a registered parameter, when `AiProfile.fromJson` runs, then the resulting `parameters[name]` equals that parameter's registry default.
- Given a profile JSON whose value exceeds `maxValue`, when `AiProfile.fromJson` runs, then the stored value is clamped to `maxValue`; given a value below `minValue`, then it is clamped to `minValue`.
- Given a profile JSON whose value for an `isInteger` parameter is `70.6`, when `AiProfile.fromJson` runs, then the stored value is the rounded int `71`.
- Given a profile JSON containing a key absent from the registry, when `AiProfile.fromJson` runs, then that key is ignored and a `warning` with prefix `data:` is logged for it.
- Given a profile JSON with `schema_version` other than `1`, when `AiProfile.fromJson` runs, then the system throws `FormatException` and does not return a profile.
- Given a profile, when `fromJson(toJson())` is evaluated, then the resulting profile's `parameters` map equals the original's.
- Given `seedAiProfilesById`, when read, then it contains exactly the 7 leader ids and each profile's personality params equal that leader's hardcoded `ai_personality_config.dart` values and its victory-config params equal the registry defaults.
- Given each committed `lib/src/profiles/<leaderId>.json`, when parsed via `AiProfile.fromJson`, then the resulting profile equals `seedAiProfilesById[leaderId]`.
