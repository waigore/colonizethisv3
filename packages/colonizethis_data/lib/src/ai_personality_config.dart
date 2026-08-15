// Personality and domain weights for full AI. SPEC/ai/ai-personalities.md.
//
// Thin facade: types, tables, lookup helpers, and dossier cap live in sibling
// libraries. Public symbols stay importable from this library and from
// `package:colonizethis_data/colonizethis_data.dart` (Refs #4412).

export 'ai_dossier_config.dart';
export 'ai_personality_lookup.dart';
export 'ai_personality_tables.dart';
export 'ai_personality_types.dart';
