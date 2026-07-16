/// Capital reassignment and Great Power / faction terminal fall.
///
/// Split into standalone libraries (Refs #3968); this cascade re-exports the
/// sibling entry points for deep importers. The package barrel publishes only a
/// `show`-restricted subset (combat/debug apply + eligibility) so cascade
/// siblings and setup's `capital_reassignment.dart` stay not fully published
/// (Refs #4038 / `SPEC/program/logic-package-barrel-contracts.md`).
library;

export 'capital_and_gp_fall_eligibility.dart';
export 'capital_and_gp_fall_reassignment.dart';
export 'capital_and_gp_fall_terminal.dart';
