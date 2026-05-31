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
import 'chrome/ct_nine_patch_button.dart';

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

class _MoveArmyDialogState extends State<MoveArmyDialog> {
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
              const SizedBox(height: 8),
              Text(
                l10n.moveArmy_invadeProvinceBody(ownerLabel),
                style: bodyStyle,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
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
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final entries = _destinationEntries();
    final owned = entries.where((e) => e.isPlayerOwned).toList();
    final invasion = entries.where((e) => !e.isPlayerOwned).toList();

    final TextStyle titleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(
              color: EditorialMonoclePalette.accent,
              letterSpacing: 0.05 * 16,
              fontWeight: FontWeight.w600,
            );
    final TextStyle emptyStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.muted);

    Widget sectionRows(
      List<ArmyMovePickerDestination> sectionEntries, {
      required bool showDeclareWarTrigger,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sectionEntries
            .map(
              (entry) => _MoveArmyDestinationRow(
                entry: entry,
                selected: _selected == entry.fullProvinceId,
                declareWarTriggerLabel: showDeclareWarTrigger &&
                        entry.requiresDeclareWarOnConfirm
                    ? l10n.moveArmy_declareWarOnTrigger(
                        moveArmyFactionGroupHeaderLabel(
                          widget.game,
                          entry,
                          l10n,
                        ),
                      )
                    : null,
                onTap: () =>
                    setState(() => _selected = entry.fullProvinceId),
              ),
            )
            .toList(),
      );
    }

    final destinationColumns = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (owned.isNotEmpty) ...[
          CtSectionLabel(l10n.moveArmy_groupYourProvinces),
          const SizedBox(height: 6),
          sectionRows(owned, showDeclareWarTrigger: false),
        ],
        if (invasion.isNotEmpty) ...[
          if (owned.isNotEmpty) const SizedBox(height: 12),
          CtSectionLabel(l10n.moveArmy_groupInvasionTargets),
          const SizedBox(height: 6),
          sectionRows(invasion, showDeclareWarTrigger: true),
        ],
      ],
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.moveArmy_title(widget.army.id), style: titleStyle),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text(l10n.moveArmy_noValidDestinations, style: emptyStyle)
        else
          destinationColumns,
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_cancel),
            ),
            CtNinePatchButton(
              enabled: _selected != null,
              onPressed: _selected == null ? null : _onConfirmPressed,
              child: Text(l10n.common_confirm),
            ),
          ],
        ),
      ],
    );

    return CtDialogShell(child: body);
  }
}

/// Single destination row inside `MoveArmyDialog`.
///
/// SPEC: `SPEC/ui/move-army-dialog.md` § Layout — radio-row outline contract
/// (#2867 R7). Invasion rows may append a `declare war on …` trigger in
/// `--danger` italic body style (#2867 R8).
class _MoveArmyDestinationRow extends StatelessWidget {
  const _MoveArmyDestinationRow({
    required this.entry,
    required this.selected,
    required this.onTap,
    this.declareWarTriggerLabel,
  });

  final ArmyMovePickerDestination entry;
  final bool selected;
  final VoidCallback onTap;
  final String? declareWarTriggerLabel;

  static const double _selectedBorderWidth = 2;
  static const double _idleBorderWidth = 1;
  static const double _dotOuterDiameter = 14;
  static const double _dotInnerDiameter = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color outline = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    final double outlineWidth = selected
        ? _selectedBorderWidth
        : _idleBorderWidth;
    final TextStyle labelStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: selected
              ? EditorialMonoclePalette.fg
              : EditorialMonoclePalette.fg.withValues(alpha: 0.9),
        );
    final TextStyle? triggerStyle = declareWarTriggerLabel == null
        ? null
        : (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 11))
              .copyWith(
                color: EditorialMonoclePalette.danger,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: entry.provinceLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: outline, width: outlineWidth),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MoveArmyRadioDot(selected: selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.provinceLabel, style: labelStyle),
                      if (declareWarTriggerLabel != null && triggerStyle != null)
                        Text(declareWarTriggerLabel!, style: triggerStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveArmyRadioDot extends StatelessWidget {
  const _MoveArmyRadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MoveArmyDestinationRow._dotOuterDiameter,
      height: _MoveArmyDestinationRow._dotOuterDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? EditorialMonoclePalette.accent
                    : EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
          ),
          if (selected)
            Container(
              width: _MoveArmyDestinationRow._dotInnerDiameter,
              height: _MoveArmyDestinationRow._dotInnerDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EditorialMonoclePalette.accent,
              ),
            ),
        ],
      ),
    );
  }
}
