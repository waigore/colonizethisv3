// Shared multi-selection dispatch for the combine-capable unit panels
// (`MilitaryUnitsPanel`, `NavalUnitsPanel`). Refs #3546 target state #2 (AC4).
//
// Before this controller both panels duplicated an identical `Set<String>`
// selection store plus the same toggle / header-tristate / select-all logic
// (`military_units_panel.dart` `_selectedArmyIds`, `naval_units_panel.dart`
// `_selectedFleetIds`). The two `CivilianUnitsPanel` deliberately keeps its own
// single-id selection (`String? _selectedUnitId`) and does not use this
// controller — civilian rows are not combinable, so a multi-id store would add
// state it never reads (documented divergence for AC5).
//
// The controller is intentionally free of Flutter imports so the
// selection-dispatch contract can be unit-tested in isolation; panels still own
// their `setState` and wrap mutating calls so rebuilds stay in the widget layer.
library;

/// Mutable set-backed selection store shared by the combine-capable unit
/// panels.
///
/// Callers derive the canonical selection id for each row (e.g. the army id, or
/// the home-fleet id for the Home Fleet) and pass it in; this controller only
/// tracks membership and computes the header select-all tri-state.
class UnitsMultiSelectionController {
  final Set<String> _selectedIds = <String>{};

  /// Read-only view of the currently selected ids.
  Set<String> get selectedIds => Set<String>.unmodifiable(_selectedIds);

  /// Number of currently selected ids.
  int get length => _selectedIds.length;

  /// Whether nothing is currently selected.
  bool get isEmpty => _selectedIds.isEmpty;

  /// Whether [id] is currently selected.
  bool contains(String id) => _selectedIds.contains(id);

  /// Adds [id] when absent, removes it when present.
  void toggle(String id) {
    if (!_selectedIds.remove(id)) {
      _selectedIds.add(id);
    }
  }

  /// Clears the entire selection.
  void clear() => _selectedIds.clear();

  /// Replaces the selection with exactly [ids] (drops any stale entries).
  void replaceWith(Iterable<String> ids) {
    _selectedIds.clear();
    _selectedIds.addAll(ids);
  }

  /// Keeps only the ids that are still present in [validIds].
  ///
  /// Returns true when the selection changed (some stale ids were pruned), so
  /// callers can decide whether a rebuild is warranted.
  bool retainOnly(Iterable<String> validIds) {
    final valid = validIds.toSet();
    final before = _selectedIds.length;
    _selectedIds.retainAll(valid);
    return _selectedIds.length != before;
  }

  /// Header checkbox tri-state for the rows identified by [allIds]:
  /// `false` when nothing (or no rows) selected, `true` when every row is
  /// selected, and `null` (indeterminate) for a partial selection.
  bool? headerValue(Iterable<String> allIds) {
    final ids = allIds.toSet();
    if (ids.isEmpty) return false;
    var selected = 0;
    for (final id in ids) {
      if (_selectedIds.contains(id)) selected++;
    }
    if (selected == 0) return false;
    if (selected == ids.length) return true;
    return null;
  }

  /// Select-all header behavior: when every row in [allIds] is already
  /// selected, clear the selection; otherwise select exactly [allIds]
  /// (dropping any stale ids). Mirrors the prior per-panel handlers and does
  /// not depend on the `Checkbox` tri-state `next` value (indeterminate taps
  /// may report `false`).
  void selectAllOrClear(Iterable<String> allIds) {
    final ids = allIds.toSet();
    final allSelected =
        ids.isNotEmpty && ids.every(_selectedIds.contains);
    if (allSelected) {
      _selectedIds.clear();
      return;
    }
    replaceWith(ids);
  }
}
