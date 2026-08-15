import 'naming_default_great_powers.dart';
import 'naming_default_minors.dart';
import 'naming_default_tribes.dart';
import 'naming_rules.dart';

/// Default historically inspired naming config (program-level; current product).
///
/// This is a program-level stand-in for a future JSON-driven ruleset; it is
/// deterministic and aligned with the Great Power identities from GDD 09.
/// Faction-family pools live in sibling libraries (Refs #4412).
const ResolvedNamingConfig defaultNamingConfig = ResolvedNamingConfig(
  greatPowers: defaultNamingGreatPowers,
  minorNations: defaultNamingMinors,
  tribes: defaultNamingTribes,
);
