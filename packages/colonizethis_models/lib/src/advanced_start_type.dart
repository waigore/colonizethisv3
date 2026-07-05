/// Advanced-start preset selected at new-game setup. SPEC/game/advanced-starts.md.
enum AdvancedStartType {
  /// Standard turn-0 start (default).
  none,

  /// ~50 turns in (calendar year ~1598).
  turns50,

  /// ~100 turns in (calendar year ~1698).
  turns100,
}

extension AdvancedStartTypeJson on AdvancedStartType {
  String toJson() => name;

  static AdvancedStartType fromJson(String? value) {
    if (value == null || value.isEmpty) {
      return AdvancedStartType.none;
    }
    return AdvancedStartType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdvancedStartType.none,
    );
  }

  /// Turn index written to [WorldState.turnState] when this preset applies.
  int get startTurnNumber => switch (this) {
    AdvancedStartType.none => 0,
    AdvancedStartType.turns50 => 50,
    AdvancedStartType.turns100 => 100,
  };
}
