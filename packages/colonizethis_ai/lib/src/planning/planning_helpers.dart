/// Shared planning-layer helpers (Refs #3278 dedup; topic split Refs #3941).
///
/// Thin barrel re-exporting topic libraries. Call sites may keep importing
/// `planning_helpers.dart`; new code may import the topic file directly.
///
/// Topic modules:
///   - [planning_peace_collectors.dart] — GP/non-GP at-war collectors
///   - [planning_ow_tech_helpers.dart] — own-OW / tech-steal / mutual-exhausted
///   - [planning_weight_scale.dart] — weight clamp / colonial-pressure scale / list equals
///   - [planning_phase_predicates.dart] — phase gates / weight projections / resolveFromPhasePlan
///   - [planning_diplomatic_scans.dart] — diplomatic cooldown / peace-target scoring gates
///   - [planning_invadable_owners.dart] — invadable frontier ownership helpers
library;

export 'planning_diplomatic_scans.dart';
export 'planning_invadable_owners.dart';
export 'planning_ow_tech_helpers.dart';
export 'planning_peace_collectors.dart';
export 'planning_phase_predicates.dart';
export 'planning_weight_scale.dart';
