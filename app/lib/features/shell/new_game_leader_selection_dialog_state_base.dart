// Shared mutable state for [NewGameLeaderSelectionDialog] mixins (Refs #3878).
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'new_game_leader_selection_dialog_constants.dart';
import 'new_game_leader_selection_dialog_widget.dart';

mixin NewGameLeaderSelectionDialogStateBase
    on State<NewGameLeaderSelectionDialog> {
  late List<String> orderedGpIdsBySlot;
  late Map<String, String> leaderByGpId;
  late final TextEditingController seedController;
  bool infiniteMode = false;
  AdvancedStartType advancedStart = AdvancedStartType.none;
  double terrainVariation =
      NewGameLeaderSelectionDialog.defaultTerrainVariation;
  final Map<int, String?> profileBySlot = <int, String?>{};

  List<String> get allGpIds =>
      widget.naming.greatPowers.map((g) => g.id).toList();

  @override
  void initState() {
    super.initState();
    seedController = TextEditingController(
      text: widget.baseConfig.seed.toString(),
    );
    final initial = widget.baseConfig.selectedGreatPowerIds;
    orderedGpIdsBySlot = initial.length == kNewGameLeaderSelectionDialogNumSlots
        ? List<String>.from(initial)
        : List<String>.from(
            GameSetupConfig.defaultConfig.selectedGreatPowerIds,
          );
    leaderByGpId = Map<String, String>.from(widget.initialLeaderByGpId);
    for (final id in orderedGpIdsBySlot) {
      final gp = widget.naming.gpById(id);
      if (gp != null &&
          gp.leaderVariants.isNotEmpty &&
          !leaderByGpId.containsKey(id)) {
        leaderByGpId[id] = gp.defaultLeaderVariantId;
      }
    }
  }

  @override
  void dispose() {
    seedController.dispose();
    super.dispose();
  }

  Set<int> duplicateSlotIndices() {
    final counts = <String, int>{};
    for (final id in orderedGpIdsBySlot) {
      if (id.isEmpty) {
        continue;
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final duplicates = <int>{};
    for (var i = 0; i < kNewGameLeaderSelectionDialogNumSlots; i++) {
      final id = orderedGpIdsBySlot[i];
      if (id.isEmpty) {
        continue;
      }
      if ((counts[id] ?? 0) > 1) {
        duplicates.add(i);
      }
    }
    return duplicates;
  }

  List<String> availableGpIdsForSlot(int slotIndex) {
    final current = orderedGpIdsBySlot[slotIndex];
    final takenElsewhere = <String>{};
    for (var j = 0; j < kNewGameLeaderSelectionDialogNumSlots; j++) {
      if (j != slotIndex) {
        final id = orderedGpIdsBySlot[j];
        if (id.isNotEmpty) {
          takenElsewhere.add(id);
        }
      }
    }
    final out = <String>[];
    for (final id in allGpIds) {
      if (!takenElsewhere.contains(id) || id == current) {
        out.add(id);
      }
    }
    return out;
  }

  bool get startEnabled {
    final seen = <String>{};
    for (var i = 0; i < kNewGameLeaderSelectionDialogNumSlots; i++) {
      final id = orderedGpIdsBySlot[i];
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
      final vid = leaderByGpId[id] ?? gp.defaultLeaderVariantId;
      if (!gp.leaderVariants.any((v) => v.id == vid)) {
        return false;
      }
    }
    return true;
  }
}
