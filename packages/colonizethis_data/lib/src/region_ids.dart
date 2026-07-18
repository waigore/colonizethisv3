/// Canonical region id string constants for Old World / New World.
///
/// Neutral home for ids previously declared only on the AI victory-config
/// surface so terrain/resource/setup/naming modules do not depend on
/// victory-config naming (Refs #4072). Values remain `'oldWorld'` /
/// `'newWorld'` for serialization compatibility.
library;

/// Region id for Old World provinces (prefixed `oldWorld|…`).
const String kOldWorldRegionId = 'oldWorld';

/// Region id for New World provinces (prefixed `newWorld|…`).
const String kNewWorldRegionId = 'newWorld';
