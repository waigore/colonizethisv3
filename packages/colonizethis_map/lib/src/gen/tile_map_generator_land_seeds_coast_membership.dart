/// Ordered coastline cells with O(1) membership (Refs #4654).
///
/// List iteration order is preserved for scoring/RNG. [contains] is a [Set]
/// lookup so neighbor de-dup is not `List.contains`.
library;

/// Coastal-cell list plus membership set used by [LandSeedCoast] growth.
class LandSeedCoastalCells {
  LandSeedCoastalCells();

  final List<(int x, int y)> list = <(int x, int y)>[];
  final Set<(int x, int y)> _members = <(int x, int y)>{};

  bool get isEmpty => list.isEmpty;

  /// Whether [cell] is already on this coastline (O(1)).
  bool contains((int x, int y) cell) => _members.contains(cell);

  /// Appends [cell] even if it is already present (Pass-2 register order).
  void addAllowingDuplicate((int x, int y) cell) {
    list.add(cell);
    _members.add(cell);
  }

  /// Appends [cell] only when it is not already a member.
  void addIfAbsent((int x, int y) cell) {
    if (_members.contains(cell)) return;
    _members.add(cell);
    list.add(cell);
  }

  /// Removes every occurrence of [cell] from the list and membership set.
  void removeCell((int x, int y) cell) {
    list.removeWhere((p) => p.$1 == cell.$1 && p.$2 == cell.$2);
    _members.remove(cell);
  }
}
