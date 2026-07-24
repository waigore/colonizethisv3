import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'move_army_dialog.dart';
import 'move_units_dialog_base.dart';

mixin MoveArmyDialogStateLogic on MoveUnitsDialogState<MoveArmyDialog> {
  String? get armySelectedDestination;
  set armySelectedDestination(String? value);

  IncrementalCandidateValidator? get armySharedCandidateValidator;
  set armySharedCandidateValidator(IncrementalCandidateValidator? value);

  List<ArmyMovePickerDestination>? get armyCachedDestinations;
  set armyCachedDestinations(List<ArmyMovePickerDestination>? value);

  Orders? get armyCachedDestinationsOrders;
  set armyCachedDestinationsOrders(Orders? value);

  String? get armyCachedDestinationsArmyId;
  set armyCachedDestinationsArmyId(String? value);

  void syncSharedValidatorAndDestinations({bool rebuildValidator = false}) {
    final view = widget.playerView;
    if (view == null) {
      armySharedCandidateValidator = null;
      armyCachedDestinations = null;
      armyCachedDestinationsOrders = null;
      armyCachedDestinationsArmyId = null;
      return;
    }
    final orders = widget.draftOrders;
    if (rebuildValidator || armySharedCandidateValidator == null) {
      armySharedCandidateValidator = IncrementalCandidateValidator.forPlayer(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        basePrefix: orders,
        resolution: orderResolutionContextFromView(view, widget.game),
      );
    } else {
      armySharedCandidateValidator =
          armySharedCandidateValidator!.forBasePrefix(
        orders,
      );
    }
    final armyId = widget.army.id;
    if (armyCachedDestinationsOrders != orders ||
        armyCachedDestinationsArmyId != armyId) {
      armyCachedDestinations = armyMovePickerDestinations(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        army: widget.army,
        currentOrders: orders,
        sharedCandidateValidator: armySharedCandidateValidator,
      );
      armyCachedDestinationsOrders = orders;
      armyCachedDestinationsArmyId = armyId;
    }
  }

  List<ArmyMovePickerDestination> destinationEntries() {
    final view = widget.playerView;
    if (view != null) {
      syncSharedValidatorAndDestinations();
      return armyCachedDestinations!;
    }
    return armyMovePickerDestinations(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.humanPlayerId,
      army: widget.army,
      currentOrders: widget.draftOrders,
    );
  }

  ArmyMovePickerDestination? selectedEntry(
    List<ArmyMovePickerDestination> entries,
  ) {
    final id = armySelectedDestination;
    if (id == null) return null;
    for (final e in entries) {
      if (e.fullProvinceId == id) return e;
    }
    return null;
  }

  void emitAndClose(ArmyMovePickerDestination entry) {
    widget.bus.emit(
      ArmyMoveRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        moveOrder: ArmyMoveOrder(
          armyId: widget.army.id,
          destinationProvinceId: entry.fullProvinceId,
        ),
        declareWarTargetFactionId: entry.requiresDeclareWarOnConfirm
            ? entry.ownerFactionId
            : null,
      ),
    );
    Navigator.of(context).pop();
  }
}
