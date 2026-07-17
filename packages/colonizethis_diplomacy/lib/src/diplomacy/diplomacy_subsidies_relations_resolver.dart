/// Barrel re-export for subsidies + relation-modifier resolvers (Refs #4028).
///
/// Call sites and the public package barrel keep importing this path so the
/// split into focused modules does not break external imports.
library;

export 'diplomacy_relation_modifiers_resolver.dart';
export 'diplomacy_subsidies_resolver.dart';
