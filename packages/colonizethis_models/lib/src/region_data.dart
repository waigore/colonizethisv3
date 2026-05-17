import 'province.dart';
import 'unit.dart';

/// Provinces and units for one region. SPEC/game/world-model.
class RegionData {
  const RegionData({this.provinces = const [], this.units = const []});

  final List<Province> provinces;
  final List<Unit> units;

  Map<String, dynamic> toJson() => {
    'provinces': provinces.map((e) => e.toJson()).toList(),
    'units': units.map((e) => e.toJson()).toList(),
  };

  static RegionData fromJson(Map<String, dynamic> json) {
    final provincesList = json['provinces'] as List<dynamic>? ?? [];
    final unitsList = json['units'] as List<dynamic>? ?? [];
    return RegionData(
      provinces: provincesList
          .map(
            (e) => Province.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
      units: unitsList
          .map(
            (e) => Unit.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionData &&
          runtimeType == other.runtimeType &&
          _listEquals(provinces, other.provinces) &&
          _listEquals(units, other.units);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(provinces), Object.hashAll(units));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
