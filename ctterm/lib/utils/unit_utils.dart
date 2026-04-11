import 'package:colonizethis_models/colonizethis_models.dart';

/// True when [unit] is a civilian type (Builder, Engineer) by [Unit.type].
bool isCivilianUnit(Unit unit) {
  final type = unit.type.toLowerCase();
  return type.contains('builder') || type.contains('engineer');
}
