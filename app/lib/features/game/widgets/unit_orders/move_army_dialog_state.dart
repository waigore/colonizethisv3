import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show ArmyMovePickerDestination, IncrementalCandidateValidator;
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'move_army_dialog.dart';
import 'move_army_dialog_declare_war.dart';
import 'move_army_dialog_destinations.dart';
import 'move_army_dialog_state_logic.dart';
import 'move_units_dialog_base.dart';

/// Stateful implementation for [MoveArmyDialog] (Refs #4117 de-part).
class MoveArmyDialogState extends MoveUnitsDialogState<MoveArmyDialog>
    with
        MoveArmyDialogStateLogic,
        MoveArmyDialogDestinations,
        MoveArmyDialogDeclareWar {
  @override
  String? armySelectedDestination;

  @override
  IncrementalCandidateValidator? armySharedCandidateValidator;

  @override
  List<ArmyMovePickerDestination>? armyCachedDestinations;

  @override
  Orders? armyCachedDestinationsOrders;

  @override
  String? armyCachedDestinationsArmyId;

  @override
  void initState() {
    super.initState();
    syncSharedValidatorAndDestinations();
    armySelectedDestination = _initialDestinationId(destinationEntries());
  }

  @override
  void didUpdateWidget(MoveArmyDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftOrders != widget.draftOrders ||
        oldWidget.game != widget.game ||
        oldWidget.army != widget.army ||
        oldWidget.playerView != widget.playerView ||
        oldWidget.initialDestinationProvinceId !=
            widget.initialDestinationProvinceId) {
      syncSharedValidatorAndDestinations(
        rebuildValidator:
            oldWidget.game != widget.game ||
            oldWidget.playerView != widget.playerView,
      );
      final entries = destinationEntries();
      if (armySelectedDestination == null ||
          !entries.any((e) => e.fullProvinceId == armySelectedDestination)) {
        armySelectedDestination = _initialDestinationId(entries);
      }
    }
  }

  String? _initialDestinationId(List<ArmyMovePickerDestination> entries) {
    if (entries.isEmpty) return null;
    final preferred = widget.initialDestinationProvinceId;
    if (preferred != null &&
        entries.any((e) => e.fullProvinceId == preferred)) {
      return preferred;
    }
    return entries.first.fullProvinceId;
  }

  @override
  String get moveDialogTitle => appL10n(context).moveArmy_title(widget.army.id);

  @override
  bool get moveDialogHasDestinations => destinationEntries().isNotEmpty;

  @override
  String get moveDialogEmptyText =>
      appL10n(context).moveArmy_noValidDestinations;

  @override
  bool get moveDialogCanConfirm => armySelectedDestination != null;

  @override
  void onMoveDialogConfirm() {
    onConfirmPressed();
  }

  @override
  void onMoveDialogCancel() => Navigator.of(context).pop();

  @override
  Widget buildMoveDialogDestinations(BuildContext context) =>
      buildMoveDialogDestinationsBody(context);

  @override
  Widget build(BuildContext context) => buildMoveDialogScaffold(context);
}
