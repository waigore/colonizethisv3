// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'dart:async';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show GamePlayerLookup, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../../../../../config/ui_screen_ids.dart';
import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart'
    show trainNavalDialogId;
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import '../../panels/fleet_expansion_tile.dart';
import '../../panels/game_panel_contract.dart';
import '../../panels/tree_builders/naval_tree_builder.dart';
import '../../unit_orders/move_fleet_dialog.dart';
import '../../unit_orders/split_fleet_dialog.dart';
import '../../unit_orders/transfer_to_home_fleet_dialog.dart';
import '../shared/base_units_panel.dart';
import '../shared/location_section_header.dart';
import '../shared/region_section_header.dart';
import '../shared/region_labels.dart';

part 'naval_units_panel_list.dart';
part 'naval_units_panel_build.dart';
part 'naval_units_panel_support_combine.dart';
part 'naval_units_panel_support_home_transfer.dart';
part 'naval_units_panel_support_dialogs.dart';

class NavalUnitsPanel extends StatefulWidget with GamePanelMixin {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    this.draftOrders = const Orders(),
    this.tileMapByRegion,
    this.topologyByRegion,
    this.locationScopeKey,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
    this.readOnly = false,
  });

  /// SPEC/ui/naval-units-panel.md — [UiScreenIds.navalUnitsPanel].
  static const screenId = UiScreenIds.navalUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  @override
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, MapTopology>? topologyByRegion;
  final String? locationScopeKey;
  final String? initialSelectedFleetId;
  final String? tileScopeTileKey;
  @override
  final bool readOnly;

  @override
  State<NavalUnitsPanel> createState() => _NavalUnitsPanelState();
}

class _NavalUnitsPanelState extends BaseUnitsPanelState<NavalUnitsPanel> {
  final Set<String> _visibleScopedFleetIds = <String>{};
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveRequestedSub;
  bool _pendingScopedAutoCloseAfterMove = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initialSelectedFleetId;
    if (id != null && id.isNotEmpty) {
      // initState runs before the first build, so mutate the store directly
      // rather than via the `setState`-wrapped dispatch.
      selection.toggle(id);
    }
    _moveRequestedSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((
      event,
    ) {
      if (widget.locationScopeKey == null) return;
      if (_visibleScopedFleetIds.contains(event.moveOrder.fleetId)) {
        _pendingScopedAutoCloseAfterMove = true;
      }
    });
  }

  @override
  void dispose() {
    _moveRequestedSub?.cancel();
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
      final valid = flat.map(_selectionFleetId).toSet();
      final prunedAny = !selection.selectedIds.every(valid.contains);
      if (prunedAny) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => selection.retainOnly(valid));
        });
      }
      if (_pendingScopedAutoCloseAfterMove &&
          widget.locationScopeKey != null &&
          oldFlat.isNotEmpty &&
          flat.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.bus.emit(const ClosePanelEvent());
        });
      }
      if (_pendingScopedAutoCloseAfterMove) {
        _pendingScopedAutoCloseAfterMove = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => buildNavalUnitsPanel(context);
}
