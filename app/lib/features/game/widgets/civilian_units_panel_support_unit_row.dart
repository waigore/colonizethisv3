/// Per-unit civilian row builder. SPEC/ui/civilian-units-panel.md.

part of 'civilian_units_panel.dart';

class _UnitRow extends ConsumerWidget {
  const _UnitRow({
    required this.game,
    required this.unit,
    required this.provinceNames,
    required this.currentOrders,
    required this.humanPlayerId,
    required this.bus,
    required this.isTileScope,
    required this.isSelectedInTileScope,
    required this.onSelectInTileScope,
    required this.projectedTileKey,
    required this.prospectShortcutTargetTileKey,
    required this.exploreShortcutTargetTileKey,
    required this.buildImprovementShortcutTargetTileKey,
    this.readOnly = false,
  });

  final Game game;
  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isTileScope;
  final bool isSelectedInTileScope;
  final VoidCallback onSelectInTileScope;
  final String? projectedTileKey;
  final String? prospectShortcutTargetTileKey;
  final String? exploreShortcutTargetTileKey;
  final String? buildImprovementShortcutTargetTileKey;
  final bool readOnly;

  List<WorkOrder> get _pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  WorkOrder? get _pendingWorkOrder {
    for (final o in _pendingForPlayer) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get _hasPending => _pendingWorkOrder != null;

  int? get _pendingIndex {
    final list = _pendingForPlayer;
    for (var i = 0; i < list.length; i++) {
      if (list[i].unitId == unit.id) return i;
    }
    return null;
  }

  bool get _isIdleNoPending =>
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !_hasPending;

  bool get _hasWork => unit.currentWork != null || _hasPending;

  String _locationLabel() {
    final regionId = Unit.regionIdFromTileKey(projectedTileKey);
    final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = regionDisplayLabel(regionId);
    return '$regionLabel — $name';
  }

  String _assignedToLabelNonPending(AppLocalizations l10n) {
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel = _workTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    var location = '';
    if (regionId != null && provinceId != null) {
      final name =
          provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = ' (${regionDisplayLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? l10n.civilian_units_turnProgress(
            cw.remainingTurns.toString(),
            cw.totalTurns.toString(),
          )
        : l10n.civilian_units_turns(
            cw.remainingTurns <= 0 ? 1 : cw.remainingTurns,
          );
    return '$workLabel$location — $progress';
  }

  Widget _buildAssignedToSubtitle(AppLocalizations l10n) {
    final pending = _pendingWorkOrder;
    if (pending != null) {
      final r = _resolvePendingAssignedResolution(
        game,
        unit,
        pending,
        provinceNames,
      );
      final turns = l10n.civilian_units_turns(r.totalTurns);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.civilian_units_assignedTo('${r.mainLine} — $turns')),
          if (r.materialCosts != null && r.materialCosts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in _sortedMaterialCostEntries(r.materialCosts!))
                    _AssignedCostChip(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon(commodityId: e.key, size: 14),
                          const SizedBox(width: 4),
                          Text(e.value.toString()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (r.treasuryAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _AssignedCostChip(
                child: Text(
                  l10n.trainUnits_treasury(r.treasuryAmount!.toString()),
                ),
              ),
            ),
        ],
      );
    }
    return Text(
      l10n.civilian_units_assignedTo(_assignedToLabelNonPending(l10n)),
    );
  }

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
            // Tappable work-target menu rows rendered without Material
            // `ListTile` chrome (Refs #2914 S8): an `InkWell` provides the
            // tap affordance, and the label muting reuses the theme
            // `disabledColor` for unavailable targets.
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
      // R30: locate is the rightmost action in the action cluster
      // (mockup `.u-actions .locate-btn`), rendered icon-only. Locate stays
      // visible on tile-scope rows that hide the Assign/Cancel cluster so
      // users can still recenter the map on any visible civilian.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableWorkTargetIds = ref.watch(
      availableWorkTargetIdsForUnitProvider(unit.id),
    );
    final l10n = appL10n(context);
    final statusLabel = switch (unit.status) {
      UnitStatus.idle => l10n.province_unitStatus_idle,
      UnitStatus.working => l10n.province_unitStatus_working,
    };
    final showActions = !isTileScope || isSelectedInTileScope;
    final inExplorerShortcutMode =
        (prospectShortcutTargetTileKey != null &&
            prospectShortcutTargetTileKey!.isNotEmpty) ||
        (exploreShortcutTargetTileKey != null &&
            exploreShortcutTargetTileKey!.isNotEmpty) ||
        (buildImprovementShortcutTargetTileKey != null &&
            buildImprovementShortcutTargetTileKey!.isNotEmpty);
    final tileKeyForLocate = projectedTileKey;
    final regionIdForLocate = Unit.regionIdFromTileKey(tileKeyForLocate);
    final rowActions = _buildRowActions(
      l10n,
      context,
      showActions: showActions,
      inExplorerShortcutMode: inExplorerShortcutMode,
      availableWorkTargetIds: availableWorkTargetIds,
      tileKeyForLocate: tileKeyForLocate,
      regionIdForLocate: regionIdForLocate,
    );
    final selected = isTileScope && isSelectedInTileScope;
    return CivilianUnitRowCard(
      key: ValueKey('civilian-unit-card-${unit.id}'),
      selected: selected,
      onTap: _handleRowTap,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unit.type, overflow: TextOverflow.ellipsis),
          Text(l10n.civilian_units_status(statusLabel)),
          Text(l10n.civilian_units_location(_locationLabel())),
          _buildAssignedToSubtitle(l10n),
        ],
      ),
      actions: rowActions,
    );
  }
}
