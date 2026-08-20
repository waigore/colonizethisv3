/// Quick Battle round-engine helpers: group bookkeeping, command-point limits,
/// effective-strength and casualty-fraction math.
///
/// SPEC/program/quick-battle-resolution.md.
///
/// Extracted from the `quick_battle_resolver.dart` part-file group into a
/// regular library so these helpers can be imported (and unit-tested)
/// independently. Helpers consumed by the resolver are package-public; helpers
/// used only within this file remain private.
library;

export 'quick_battle_resolver_engine_emplaced.dart';
export 'quick_battle_resolver_engine_groups.dart';
export 'quick_battle_resolver_engine_strike.dart';
