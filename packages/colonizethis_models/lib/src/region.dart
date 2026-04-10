import 'model_validation_exception.dart';

/// Region identifier. SPEC/game/world-model: Old World + New World.
enum Region { oldWorld, newWorld }

extension RegionJson on Region {
  static Region fromJson(String value) {
    switch (value) {
      case 'oldWorld':
        return Region.oldWorld;
      case 'newWorld':
        return Region.newWorld;
      default:
        throw ModelValidationException.value(value, 'value', 'Unknown Region');
    }
  }

  String toJson() => name;
}
