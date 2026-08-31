import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_spacing.dart';
import 'technology_panel_body.dart';
import 'technology_panel_open_path.dart';

export 'technology_panel_constants.dart';
export 'technology_panel_widgets.dart';

/// Technology panel (UXD 03k / GAME40001). Shows researched techs and
/// research slots for a player under the dark editorial-monocle theme.
class TechnologyPanel extends StatelessWidget {
  const TechnologyPanel({
    super.key,
    required this.game,
    required this.player,
    this.currentOrders = const Orders(),
    this.onOrdersChanged,
    this.slotsOpenPath,
  });

  /// SPEC/ui/technology-panel.md — [UiScreenIds.technologyScreen]. Hosted by
  /// `TechnologyScreen`; shares its stable surface ID.
  static const screenId = UiScreenIds.technologyScreen;

  final Game game;
  final Player player;
  final Orders currentOrders;
  final void Function(Orders orders)? onOrdersChanged;

  /// Session-cached Slots-tab projections when hosted by [TechnologyScreen].
  final TechnologyPanelSlotsOpenPathSnapshot? slotsOpenPath;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);

    return Padding(
      padding: const EdgeInsets.all(CtSpacing.l),
      child: buildTechnologyPanelSlotsBody(
        context: context,
        l10n: l10n,
        game: game,
        player: player,
        currentOrders: currentOrders,
        onOrdersChanged: onOrdersChanged,
        slotsOpenPath: slotsOpenPath,
      ),
    );
  }
}
