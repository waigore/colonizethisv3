/// Work-target assignment bottom sheet for civilian unit rows.
/// SPEC/ui/civilian-units-panel.md — local-by-design dialog carve-out.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show kWorkTargetCounterSpy;
import 'package:flutter/material.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'civilian_units_panel_support_resolution.dart';

void showCivilianUnitsPanelOrderMenu(
  BuildContext context, {
  required AppEventBus bus,
  required Unit unit,
  required List<String> availableWorkTargetIds,
}) {
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
            final label = civilianUnitsPanelWorkTargetLabels[target] ?? target;
            final isCounterSpy = target == kWorkTargetCounterSpy;
            final gist = isCounterSpy
                ? appL10n(context).provinceOverlay_counterEspionageGist
                : null;
            final tooltip = isCounterSpy
                ? appL10n(context).provinceOverlay_counterEspionageOneSpyTooltip
                : null;
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
              child: Tooltip(
                message: tooltip ?? label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CtSpacing.l,
                    vertical: CtSpacing.ml,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isAvailable
                              ? null
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      if (gist != null)
                        Text(
                          gist,
                          style: TextStyle(
                            color: EditorialMonoclePalette.muted,
                            fontSize: 11,
                          ),
                        ),
                    ],
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
