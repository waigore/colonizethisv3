import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/constants.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'technology_panel_constants.dart';

class TechnologyPanelSlotHeaderRow extends StatelessWidget {
  const TechnologyPanelSlotHeaderRow({
    super.key,
    required this.slotIndex,
    required this.canEdit,
    required this.hasTech,
    required this.onCancel,
    required this.onChooseTech,
  });

  final int slotIndex;
  final bool canEdit;
  final bool hasTech;
  final VoidCallback? onCancel;
  final VoidCallback? onChooseTech;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    // SPEC/ui/technology-panel.md § Slot behaviour: below the narrow
    // breakpoint the compact slot action controls expand to a 44 dp minimum
    // tap target (mobile-adaptation § 1); at or above it they keep the
    // compact mockup size (`.slot-actions button`). Refs #3510.
    final bool enforceMobileTouchTarget = MediaQuery.sizeOf(context).width <
        kTechnologySlotActionTouchTargetBreakpoint;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.technologyPanel_slot(slotIndex + 1),
            style: TextStyle(
              color: EditorialMonoclePalette.fg,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.04,
            ),
          ),
        ),
        if (canEdit) ...[
          if (hasTech && onCancel != null) ...[
            _wrapSlotActionTouchTarget(
              enforce: enforceMobileTouchTarget,
              child: CtDangerTextButton(
                onPressed: onCancel,
                label: l10n.common_cancel,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (onChooseTech != null)
            _wrapSlotActionTouchTarget(
              enforce: enforceMobileTouchTarget,
              child: CtActionTextButton(
                onPressed: onChooseTech,
                label: l10n.technologyPanel_chooseTech,
              ),
            ),
        ],
      ],
    );
  }

  /// Guarantees a [kMinTouchTargetSize] (44 dp) minimum tap target around a
  /// compact slot action control when [enforce] is `true` (narrow / mobile
  /// viewports). The min constraints propagate through the button's
  /// `InkWell`, so the whole 44 dp region becomes tappable while the visible
  /// chrome stays the compact mockup control on wider viewports.
  /// SPEC/ui/technology-panel.md § Slot behaviour. Refs #3510.
  static Widget _wrapSlotActionTouchTarget({
    required bool enforce,
    required Widget child,
  }) {
    if (!enforce) {
      return child;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTargetSize,
        minHeight: kMinTouchTargetSize,
      ),
      child: child,
    );
  }
}
