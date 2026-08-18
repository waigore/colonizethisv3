import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import '../production/force_feeding_readiness_labels.dart';
import '../production/labour_readiness_labels.dart';

/// Stable key for widget tests that open the labour/feeding details popover.
const Key kLabourFeedingDetailsPanelKey = Key('labour_feeding_details_panel');

/// Resolves the numeric `effective/full` colour tier for the tab-bar labour
/// indicator per `SPEC/ui/empire-overview.md` § Labour and feeding indicator.
Color labourFeedingNumericColor({
  required LabourReadinessSnapshot labourReadiness,
  required ForceFeedingSnapshot forcesFeeding,
  required bool notDefined,
}) {
  if (notDefined) {
    return EditorialMonoclePalette.muted;
  }
  if (forcesFeeding.hasAnyForces && !forcesFeeding.isFullyFed) {
    return EditorialMonoclePalette.danger;
  }
  if (labourReadiness.effectiveLabour == 0 &&
      labourReadiness.fullCapacity > 0) {
    return EditorialMonoclePalette.danger;
  }
  if (!labourReadiness.isFullCapacity) {
    return EditorialMonoclePalette.accent;
  }
  return EditorialMonoclePalette.muted;
}

/// Opens a dismissible floating panel anchored below the labour indicator.
Future<void> showLabourFeedingDetailsPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required AppLocalizations l10n,
  required LabourReadinessSnapshot labourReadiness,
  required ForceFeedingSnapshot forcesFeeding,
}) {
  final RenderBox? renderBox =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) {
    return Future<void>.value();
  }

  final OverlayState overlay = Overlay.of(context);
  final Offset anchorTopLeft = renderBox.localToGlobal(Offset.zero);
  final Size anchorSize = renderBox.size;
  final Completer<void> closed = Completer<void>();

  late OverlayEntry entry;
  void dismiss() {
    if (!closed.isCompleted) {
      closed.complete();
    }
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (BuildContext overlayContext) {
      final double viewportWidth = MediaQuery.sizeOf(overlayContext).width;
      const double panelMaxWidth = 280;
      final double panelWidth = panelMaxWidth.clamp(0, viewportWidth - 16);
      final double anchorRight = anchorTopLeft.dx + anchorSize.width;
      double panelLeft = anchorRight - panelWidth;
      panelLeft = panelLeft.clamp(8, viewportWidth - panelWidth - 8);
      final double panelTop =
          anchorTopLeft.dy + anchorSize.height + 4 - chromeBottomY;

      return Positioned(
        top: chromeBottomY,
        left: 0,
        right: 0,
        bottom: 0,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  dismiss();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: dismiss,
                      behavior: HitTestBehavior.opaque,
                      child: ColoredBox(
                        color: EditorialMonoclePalette.dialogScrim.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: panelTop,
                    left: panelLeft,
                    width: panelWidth,
                    child: Material(
                      color: Colors.transparent,
                      child: LabourFeedingDetailsPanel(
                        l10n: l10n,
                        labourReadiness: labourReadiness,
                        forcesFeeding: forcesFeeding,
                        onClose: dismiss,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  return closed.future;
}

/// Plain-language labour and feeding breakdown surfaced on player tap.
class LabourFeedingDetailsPanel extends StatelessWidget {
  const LabourFeedingDetailsPanel({
    super.key,
    required this.l10n,
    required this.labourReadiness,
    required this.forcesFeeding,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
  final VoidCallback onClose;

  static const Key closeButtonKey = Key('labour_feeding_details_close');

  @override
  Widget build(BuildContext context) {
    final TextStyle rowStyle = _labourFeedingDetailsRowStyle(context);
    final TextStyle counselStyle = rowStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );

    return DecoratedBox(
      key: kLabourFeedingDetailsPanelKey,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _LabourFeedingDetailsRows(
                    l10n: l10n,
                    labourReadiness: labourReadiness,
                    forcesFeeding: forcesFeeding,
                    rowStyle: rowStyle,
                  ),
                ),
                CtIconAction(
                  key: closeButtonKey,
                  icon: Icons.close,
                  tooltip: l10n.common_close,
                  semanticLabel: l10n.common_close,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: CtSpacing.s),
            Text(
              l10n.production_forcesFoodDetailsPriority,
              style: counselStyle,
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _labourFeedingDetailsRowStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
    color: EditorialMonoclePalette.fg,
    fontSize: 11,
    height: 1.3,
  );
}

class _LabourFeedingDetailsRows extends StatelessWidget {
  const _LabourFeedingDetailsRows({
    required this.l10n,
    required this.labourReadiness,
    required this.forcesFeeding,
    required this.rowStyle,
  });

  final AppLocalizations l10n;
  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
  final TextStyle rowStyle;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      Text(
        l10n.mapControls_labourFeeding_details_labour(
          '${labourReadiness.effectiveLabour}',
          '${labourReadiness.fullCapacity}',
        ),
        style: rowStyle,
      ),
    ];

    if (labourReadiness.fullCapacity == 0) {
      rows
        ..add(const SizedBox(height: 4))
        ..add(
          Text(
            l10n.mapControls_labourFeeding_details_emptyPool,
            style: rowStyle,
          ),
        );
    } else if (!labourReadiness.isFullCapacity &&
        labourReadiness.primaryCauseKind != null) {
      rows
        ..add(const SizedBox(height: 4))
        ..add(
          Text(
            labourReadinessPrimaryReasonText(l10n, labourReadiness),
            style: rowStyle,
          ),
        );
    }

    if (forcesFeeding.hasLandForces) {
      rows
        ..add(const SizedBox(height: 4))
        ..add(
          Text(
            landForceFeedingDefaultLine(l10n, forcesFeeding),
            style: rowStyle,
          ),
        );
    }
    if (forcesFeeding.hasNavalForces) {
      rows
        ..add(const SizedBox(height: 4))
        ..add(
          Text(
            navalForceFeedingDefaultLine(l10n, forcesFeeding),
            style: rowStyle,
          ),
        );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
