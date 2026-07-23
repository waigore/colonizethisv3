// Move army dialog state. SPEC/ui/move-army-dialog.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'move_army_dialog.dart' show MoveArmyDialog;
import 'move_army_dialog_labels.dart';
import 'move_units_dialog_base.dart';

class MoveArmyDialogState extends MoveUnitsDialogState<MoveArmyDialog> {
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

  void _syncSharedValidatorAndDestinations({bool rebuildValidator = false}) {
    final view = widget.playerView;
    if (view == null) {
      _sharedCandidateValidator = null;
      _cachedDestinations = null;
      _cachedDestinationsOrders = null;
      _cachedDestinationsArmyId = null;
      return;
    }
    final orders = widget.draftOrders;
    if (rebuildValidator || _sharedCandidateValidator == null) {
      _sharedCandidateValidator = IncrementalCandidateValidator.forPlayer(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        basePrefix: orders,
        resolution: orderResolutionContextFromView(view, widget.game),
      );
    } else {
      _sharedCandidateValidator = _sharedCandidateValidator!.forBasePrefix(
        orders,
      );
    }
    final armyId = widget.army.id;
    if (_cachedDestinationsOrders != orders ||
        _cachedDestinationsArmyId != armyId) {
      _cachedDestinations = armyMovePickerDestinations(
        game: widget.game,
        topology: widget.topology,
        playerId: widget.humanPlayerId,
        army: widget.army,
        currentOrders: orders,
        sharedCandidateValidator: _sharedCandidateValidator,
      );
      _cachedDestinationsOrders = orders;
      _cachedDestinationsArmyId = armyId;
    }
  }

  List<ArmyMovePickerDestination> _destinationEntries() {
    final view = widget.playerView;
    if (view != null) {
      _syncSharedValidatorAndDestinations();
      return _cachedDestinations!;
    }
    return armyMovePickerDestinations(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.humanPlayerId,
      army: widget.army,
      currentOrders: widget.draftOrders,
    );
  }

  ArmyMovePickerDestination? _selectedEntry(
    List<ArmyMovePickerDestination> entries,
  ) {
    final id = _selected;
    if (id == null) return null;
    for (final e in entries) {
      if (e.fullProvinceId == id) return e;
    }
    return null;
  }

  void _emitAndClose(ArmyMovePickerDestination entry) {
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

  Future<void> _onConfirmPressed() async {
    final entries = _destinationEntries();
    final entry = _selectedEntry(entries);
    if (entry == null) return;
    final l10n = appL10n(context);

    if (!entry.requiresDeclareWarOnConfirm) {
      _emitAndClose(entry);
      return;
    }

    final ownerLabel = moveArmyFactionGroupHeaderLabel(
      widget.game,
      entry,
      l10n,
    );
    final ok = await _showDeclareWarConfirmDialog(ownerLabel, l10n);
    if (ok == true && context.mounted) {
      _emitAndClose(entry);
    }
  }

  Future<bool?> _showDeclareWarConfirmDialog(
    String ownerLabel,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.danger);
        final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.fg);
        return CtDialogShell(
          borderColor: EditorialMonoclePalette.danger,
          borderWidth: CtDialogShell.dangerBorderWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moveArmy_invadeProvinceTitle, style: titleStyle),
              const SizedBox(height: CtSpacing.m),
              Text(
                l10n.moveArmy_invadeProvinceBody(ownerLabel),
                style: bodyStyle,
              ),
              const SizedBox(height: CtSpacing.l),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: CtSpacing.m,
                runSpacing: CtSpacing.m,
                children: [
                  CtNinePatchButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.common_cancel),
                  ),
                  CtNinePatchButton(
                    dangerVariant: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.moveArmy_declareWarAndMove),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoveDialogDestinationsBody(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final entries = _destinationEntries();
    final owned = entries.where((e) => e.isPlayerOwned).toList();
    final invasion = entries.where((e) => !e.isPlayerOwned).toList();

    Widget sectionRows(
      List<ArmyMovePickerDestination> sectionEntries, {
      required bool showDeclareWarTrigger,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sectionEntries
            .map(
              (entry) => _buildDestinationRow(
                theme,
                l10n,
                entry,
                showDeclareWarTrigger: showDeclareWarTrigger,
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (owned.isNotEmpty) ...[
          CtSectionLabel(l10n.moveArmy_groupYourProvinces),
          const SizedBox(height: CtSpacing.s),
          sectionRows(owned, showDeclareWarTrigger: false),
        ],
        if (invasion.isNotEmpty) ...[
          if (owned.isNotEmpty) const SizedBox(height: CtSpacing.ml),
          CtSectionLabel(l10n.moveArmy_groupInvasionTargets),
          const SizedBox(height: CtSpacing.s),
          sectionRows(invasion, showDeclareWarTrigger: true),
        ],
      ],
    );
  }

  /// Builds a single army destination row over the shared
  /// [MoveDialogDestinationRow] chrome. Invasion rows append a
  /// `declare war on …` trigger in `--danger` italic body style (#2867 R8).
  Widget _buildDestinationRow(
    ThemeData theme,
    AppLocalizations l10n,
    ArmyMovePickerDestination entry, {
    required bool showDeclareWarTrigger,
  }) {
    final bool selected = _selected == entry.fullProvinceId;
    final TextStyle labelStyle = moveDialogRowLabelStyle(
      theme,
      selected: selected,
    );
    final String? triggerLabel =
        showDeclareWarTrigger && entry.requiresDeclareWarOnConfirm
        ? l10n.moveArmy_declareWarOnTrigger(
            moveArmyFactionGroupHeaderLabel(widget.game, entry, l10n),
          )
        : null;
    final TextStyle? triggerStyle = triggerLabel == null
        ? null
        : (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.danger,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          );

    return MoveDialogDestinationRow(
      selected: selected,
      semanticsLabel: entry.provinceLabel,
      onTap: () => setState(() => _selected = entry.fullProvinceId),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.provinceLabel, style: labelStyle),
          if (triggerLabel != null && triggerStyle != null)
            Text(triggerLabel, style: triggerStyle),
        ],
      ),
    );
  }
}
