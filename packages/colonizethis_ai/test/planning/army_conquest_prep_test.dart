// Thin contract for prepareConquestFieldArmy pin suite (Refs #4079 Slice C).
// SPEC: SPEC/ai/ai-architecture.md § Field army prep and
// `packages/colonizethis_ai/lib/src/planning/army_conquest_prep.dart`.
//
// Case bodies live in sibling `*_cases.dart` modules:
//   - basic: single-split + existing-field-army no-op
//   - stalled: multi-split loop, cap guard, sole-regiment peel (#2925)

import 'army_conquest_prep_basic_cases.dart';
import 'army_conquest_prep_stalled_noop_cases.dart';
import 'army_conquest_prep_stalled_split_cases.dart';

void main() {
  registerArmyConquestPrepBasicCases();
  registerArmyConquestPrepStalledSplitCases();
  registerArmyConquestPrepStalledNoopCases();
}
