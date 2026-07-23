import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import '../../panels/tree_builders/naval_tree_builder.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel_build.dart';
import 'naval_units_panel_scope_tracking.dart';
import 'naval_units_panel_support_combine.dart';
import 'naval_units_panel_support_dialogs.dart';
import 'naval_units_panel_widget.dart';

class NavalUnitsPanelState extends BaseUnitsPanelState<NavalUnitsPanel>
    with
        NavalUnitsPanelScopeTracking,
        NavalUnitsPanelCombineSupport,
        NavalUnitsPanelDialogs,
        NavalUnitsPanelList,
        NavalUnitsPanelBuild {
  @override
  void initState() {
    super.initState();
    final id = widget.initialSelectedFleetId;
    if (id != null && id.isNotEmpty) {
      // initState runs before the first build, so mutate the store directly
      // rather than via the `setState`-wrapped dispatch.
      selection.toggle(id);
    }
    moveRequestedSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((
      event,
    ) {
      if (widget.locationScopeKey == null) return;
      if (visibleScopedFleetIds.contains(event.moveOrder.fleetId)) {
        pendingScopedAutoCloseAfterMove = true;
      }
    });
  }

  @override
  void dispose() {
    moveRequestedSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NavalUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameOrDraftChanged =
        oldWidget.game != widget.game ||
        oldWidget.draftOrders != widget.draftOrders;
    if (gameOrDraftChanged) {
      final oldFlat = flattenNavalTree(
        buildNavalTree(
          oldWidget.game,
          oldWidget.humanPlayerId,
          oldWidget.topology,
          oldWidget.draftOrders,
          appL10n(context),
          tileMapByRegion: oldWidget.tileMapByRegion,
          topologyByRegion: oldWidget.topologyByRegion,
          locationScopeKeyFilter: oldWidget.locationScopeKey,
        ),
      );
      final flat = flattenNavalTree(
        buildNavalTree(
          widget.game,
          widget.humanPlayerId,
          widget.topology,
          widget.draftOrders,
          appL10n(context),
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: widget.topologyByRegion,
          locationScopeKeyFilter: widget.locationScopeKey,
        ),
      );
      final valid = flat.map(selectionFleetId).toSet();
      final prunedAny = !selection.selectedIds.every(valid.contains);
      if (prunedAny) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => selection.retainOnly(valid));
        });
      }
      if (pendingScopedAutoCloseAfterMove &&
          widget.locationScopeKey != null &&
          oldFlat.isNotEmpty &&
          flat.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.bus.emit(const ClosePanelEvent());
        });
      }
      if (pendingScopedAutoCloseAfterMove) {
        pendingScopedAutoCloseAfterMove = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => buildNavalUnitsPanel(context);
}
