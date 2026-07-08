// Move army dialog. SPEC/ui/move-army-dialog.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../chrome/ct_nine_patch_button.dart';
import 'move_units_dialog_base.dart';

part 'move_army_dialog_declare_war.dart';
part 'move_army_dialog_destinations.dart';
part 'move_army_dialog_state.dart';

String moveArmyFactionGroupHeaderLabel(
  Game game,
  ArmyMovePickerDestination entry,
  AppLocalizations l10n,
) {
  if (entry.isPlayerOwned) return l10n.moveArmy_groupYourProvinces;
  if (entry.ownerFactionId == '__unowned__') return l10n.moveArmy_groupUnowned;
  final gp = game.playerById(entry.ownerFactionId);
  if (gp != null) return gp.displayName;
  for (final m in game.minorNations) {
    if (m.id == entry.ownerFactionId) {
      return m.displayName ?? m.id;
    }
  }
  for (final t in game.tribes) {
    if (t.id == entry.ownerFactionId) {
      return t.displayName ?? t.id;
    }
  }
  return entry.ownerFactionId;
}

class MoveArmyDialog extends StatefulWidget {
  const MoveArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
    this.playerView,
  });

  /// SPEC/ui/move-army-dialog.md — [UiScreenIds.moveArmyDialog].
  static const screenId = UiScreenIds.moveArmyDialog;

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

  /// When supplied, destination probing reuses this [PlayerView] and a single
  /// per-dialog [IncrementalCandidateValidator] instead of rebuilding them on
  /// every picker call (Refs #2394, SPEC/program/order-suggestions.md).
  final PlayerView? playerView;

  @override
  State<MoveArmyDialog> createState() => _MoveArmyDialogState();
}

class _MoveArmyDialogState extends MoveUnitsDialogState<MoveArmyDialog> {
  String? _selected;
  IncrementalCandidateValidator? _sharedCandidateValidator;
  List<ArmyMovePickerDestination>? _cachedDestinations;
  Orders? _cachedDestinationsOrders;
  String? _cachedDestinationsArmyId;

  @override
  void initState() {
    super.initState();
    _syncSharedValidatorAndDestinations();
    final entries = _destinationEntries();
    if (entries.isNotEmpty) {
      _selected = entries.first.fullProvinceId;
    }
  }

  @override
  void didUpdateWidget(MoveArmyDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftOrders != widget.draftOrders ||
        oldWidget.game != widget.game ||
        oldWidget.army != widget.army ||
        oldWidget.playerView != widget.playerView) {
      _syncSharedValidatorAndDestinations(
        rebuildValidator:
            oldWidget.game != widget.game ||
            oldWidget.playerView != widget.playerView,
      );
      final entries = _destinationEntries();
      if (_selected == null ||
          !entries.any((e) => e.fullProvinceId == _selected)) {
        _selected = entries.isEmpty ? null : entries.first.fullProvinceId;
      }
    }
  }

  @override
  String get moveDialogTitle => appL10n(context).moveArmy_title(widget.army.id);

  @override
  bool get moveDialogHasDestinations => _destinationEntries().isNotEmpty;

  @override
  String get moveDialogEmptyText =>
      appL10n(context).moveArmy_noValidDestinations;

  @override
  bool get moveDialogCanConfirm => _selected != null;

  @override
  void onMoveDialogConfirm() {
    _onConfirmPressed();
  }

  @override
  void onMoveDialogCancel() => Navigator.of(context).pop();

  @override
  Widget buildMoveDialogDestinations(BuildContext context) =>
      _buildMoveDialogDestinationsBody(context);

  @override
  Widget build(BuildContext context) => buildMoveDialogScaffold(context);
}
