// Move army dialog. SPEC/ui/move-army-dialog.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import 'chrome/ct_nine_patch_button.dart';
import 'move_units_dialog_base.dart';

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
    final ok = await showDialog<bool>(
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
    if (ok == true && context.mounted) {
      _emitAndClose(entry);
    }
  }

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
  Widget build(BuildContext context) => buildMoveDialogScaffold(context);

  @override
  Widget buildMoveDialogDestinations(BuildContext context) {
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
