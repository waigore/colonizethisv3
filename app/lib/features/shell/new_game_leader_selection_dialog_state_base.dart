part of 'new_game_leader_selection_dialog.dart';

/// Shared mutable state for [NewGameLeaderSelectionDialog] part mixins (Refs #3878).
mixin _NewGameLeaderSelectionDialogStateBase
    on State<NewGameLeaderSelectionDialog> {
  late List<String> _orderedGpIdsBySlot;
  late Map<String, String> _leaderByGpId;
  late final TextEditingController _seedController;
  bool _infiniteMode = false;
  AdvancedStartType _advancedStart = AdvancedStartType.none;
  double _terrainVariation =
      NewGameLeaderSelectionDialog.defaultTerrainVariation;
  final Map<int, String?> _profileBySlot = <int, String?>{};

  List<String> get _allGpIds =>
      widget.naming.greatPowers.map((g) => g.id).toList();

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(
      text: widget.baseConfig.seed.toString(),
    );
    final initial = widget.baseConfig.selectedGreatPowerIds;
    _orderedGpIdsBySlot = initial.length == _kNumSlots
        ? List<String>.from(initial)
        : List<String>.from(
            GameSetupConfig.defaultConfig.selectedGreatPowerIds,
          );
    _leaderByGpId = Map<String, String>.from(widget.initialLeaderByGpId);
    for (final id in _orderedGpIdsBySlot) {
      final gp = widget.naming.gpById(id);
      if (gp != null &&
          gp.leaderVariants.isNotEmpty &&
          !_leaderByGpId.containsKey(id)) {
        _leaderByGpId[id] = gp.defaultLeaderVariantId;
      }
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  Set<int> _duplicateSlotIndices() {
    final counts = <String, int>{};
    for (final id in _orderedGpIdsBySlot) {
      if (id.isEmpty) {
        continue;
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final duplicates = <int>{};
    for (var i = 0; i < _kNumSlots; i++) {
      final id = _orderedGpIdsBySlot[i];
      if (id.isEmpty) {
        continue;
      }
      if ((counts[id] ?? 0) > 1) {
        duplicates.add(i);
      }
    }
    return duplicates;
  }

  List<String> _availableGpIdsForSlot(int slotIndex) {
    final current = _orderedGpIdsBySlot[slotIndex];
    final takenElsewhere = <String>{};
    for (var j = 0; j < _kNumSlots; j++) {
      if (j != slotIndex) {
        final id = _orderedGpIdsBySlot[j];
        if (id.isNotEmpty) {
          takenElsewhere.add(id);
        }
      }
    }
    final out = <String>[];
    for (final id in _allGpIds) {
      if (!takenElsewhere.contains(id) || id == current) {
        out.add(id);
      }
    }
    return out;
  }

  bool get _startEnabled {
    final seen = <String>{};
    for (var i = 0; i < _kNumSlots; i++) {
      final id = _orderedGpIdsBySlot[i];
      if (id.isEmpty) {
        return false;
      }
      if (seen.contains(id)) {
        return false;
      }
      seen.add(id);
      final gp = widget.naming.gpById(id);
      if (gp == null || gp.leaderVariants.isEmpty) {
        return false;
      }
      final vid = _leaderByGpId[id] ?? gp.defaultLeaderVariantId;
      if (!gp.leaderVariants.any((v) => v.id == vid)) {
        return false;
      }
    }
    return true;
  }
}
