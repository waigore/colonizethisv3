import 'package:colonizethis_data/colonizethis_data.dart';

/// Expected tactical row per SPEC/game/military-units.md § Regiment Table.
typedef CombatConfigSpecRegimentRow = ({
  int fpn,
  int fpm,
  int rng,
  int def,
  int mvr,
  RegimentCategory category,
  int era,
});
