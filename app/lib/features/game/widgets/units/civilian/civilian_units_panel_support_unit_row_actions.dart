/// Civilian unit row assign/cancel/locate actions. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'civilian_units_panel.dart';

extension _UnitRowActions on _UnitRow {
  void _showOrderMenu(
    BuildContext context,
    List<String> availableWorkTargetIds,
  ) {
    final allowed = workOrderTargetsByUnitType[unit.type];
    if (allowed == null || allowed.isEmpty) {
      return;
    }
    final available = availableWorkTargetIds;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(CtSpacing.ml),
              child: Text(
                appL10n(context).civilian_assignWorkTitle(unit.type),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...allowed.map((target) {
              final isAvailable = available.contains(target);
              return InkWell(
                onTap: isAvailable
                    ? () {
                        Navigator.of(ctx).pop();
                        bus.closePanelThenEmit(
                          StartCivilianWorkTargetSelectionEvent(
                            unitId: unit.id,
                            workTarget: target,
                          ),
                        );
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CtSpacing.l,
                    vertical: CtSpacing.ml,
                  ),
                  child: Text(
                    _workTargetLabels[target] ?? target,
                    style: TextStyle(
                      color: isAvailable
                          ? null
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _startShortcutAssign(List<String> availableWorkTargetIds) {
    final hasExploreShortcut =
        exploreShortcutTargetTileKey != null &&
        exploreShortcutTargetTileKey!.isNotEmpty;
    final hasProspectShortcut =
        prospectShortcutTargetTileKey != null &&
        prospectShortcutTargetTileKey!.isNotEmpty;
    final hasBuildImprovementShortcut =
        buildImprovementShortcutTargetTileKey != null &&
        buildImprovementShortcutTargetTileKey!.isNotEmpty;
    final targetTileKey = hasBuildImprovementShortcut
        ? buildImprovementShortcutTargetTileKey
        : hasExploreShortcut
        ? exploreShortcutTargetTileKey
        : hasProspectShortcut
        ? prospectShortcutTargetTileKey
        : null;
    if (targetTileKey == null || targetTileKey.isEmpty) return;
    final workTarget = hasBuildImprovementShortcut
        ? kWorkTargetBuildImprovement
        : hasExploreShortcut
        ? kWorkTargetExplore
        : kWorkTargetProspect;
    if (!_isIdleNoPending || !availableWorkTargetIds.contains(workTarget)) {
      return;
    }
    bus.closePanelThenEmit(
      UpsertPendingCivilianWorkOrderRequestedEvent(
        playerId: humanPlayerId,
        workOrder: WorkOrder(
          unitId: unit.id,
          target: workTarget,
          targetTileKey: targetTileKey,
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final completer = Completer<bool>();
    bus.emit(
      ConfirmDialogEvent(
        title: 'Cancel work order?',
        message:
            'This will cancel the current or pending work for this unit. Materials are not refunded.',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        onResult: completer.complete,
      ),
    );
    final confirmed = await completer.future;
    if (!confirmed || !context.mounted) return;
    final idx = _pendingIndex;
    if (idx != null) {
      bus.emit(
        RemovePendingWorkOrderRequestedEvent(
          playerId: humanPlayerId,
          index: idx,
        ),
      );
    } else if (unit.currentWork != null) {
      bus.emit(CancelInProgressCivilianWorkRequestedEvent(unitId: unit.id));
    }
  }

  List<UnitsEntityAction> _buildRowActions(
    AppLocalizations l10n,
    BuildContext context, {
    required bool showActions,
    required bool inExplorerShortcutMode,
    required List<String> availableWorkTargetIds,
    required String? tileKeyForLocate,
    required String? regionIdForLocate,
  }) {
    if (readOnly) {
      return const <UnitsEntityAction>[];
    }
    final canLocate =
        tileKeyForLocate != null &&
        tileKeyForLocate.isNotEmpty &&
        regionIdForLocate != null;
    return [
      if (showActions && _isIdleNoPending)
        UnitsEntityAction(
          tooltip: l10n.civilian_units_assign,
          icon: Icons.playlist_add,
          label: l10n.civilian_units_assign,
          onPressed: inExplorerShortcutMode
              ? () => _startShortcutAssign(availableWorkTargetIds)
              : () => _showOrderMenu(context, availableWorkTargetIds),
        ),
      if (showActions && _hasWork)
        UnitsEntityAction(
          tooltip: l10n.common_cancel,
          icon: Icons.cancel_outlined,
          label: l10n.common_cancel,
          variant: UnitsEntityActionVariant.danger,
          onPressed: () => _confirmCancel(context),
        ),
      UnitsEntityAction(
        tooltip: l10n.common_locate,
        icon: Icons.my_location,
        label: l10n.common_locate,
        iconOnly: true,
        onPressed: canLocate
            ? () {
                bus.emit(
                  LocateMapTileEvent(
                    tileKey: tileKeyForLocate,
                    regionId: regionIdForLocate,
                  ),
                );
              }
            : null,
      ),
    ];
  }

  void _handleRowTap() {
    if (isTileScope) {
      onSelectInTileScope();
      return;
    }
    final tileKey = projectedTileKey;
    if (tileKey == null) return;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
