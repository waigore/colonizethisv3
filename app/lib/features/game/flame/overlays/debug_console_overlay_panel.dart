import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_radius.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'debug_console_controller.dart';

part 'debug_console_overlay_panel_state.dart';

/// `SYS20001` Debug console overlay panel.
///
/// Visual chrome resolves through [EditorialMonoclePalette] tokens — no
/// hard-coded Material color literals — and the close affordance is the
/// [CtIconAction] catalog primitive (no banned Material [IconButton]).
/// Implements `Refs #2914` S3 (Material color cleanup) and S8 (Material
/// widget ban) for the dev-tooling debug console surface
/// (`SPEC/ui/debug-console-panel.md` § Visual chrome).
class DebugConsoleOverlayPanel extends StatefulWidget {
  const DebugConsoleOverlayPanel({
    required this.bus,
    required this.humanPlayerId,
    required this.readOnlyContextProvider,
    required this.onClose,
    super.key,
  });

  final AppEventBus bus;
  final String humanPlayerId;
  final DebugConsoleReadOnlyContext? Function() readOnlyContextProvider;
  final VoidCallback onClose;

  /// Stable key for the panel close affordance ([CtIconAction]). Exposed
  /// for widget tests that pin the editorial-monocle chrome contract
  /// (Refs #2914 S8 — no banned Material [IconButton]).
  static const ValueKey<String> closeButtonKey = ValueKey<String>(
    'debug-console-close',
  );

  /// Alpha applied to [EditorialMonoclePalette.bgDeep] for the outer
  /// panel surface. Kept at the prior `0.85` value the panel used
  /// against the now-removed `Colors.black` literal so the visual
  /// density on top of the in-map overlay stack does not regress.
  static const double panelBackgroundAlpha = 0.85;

  /// Alpha applied to [EditorialMonoclePalette.muted] for the
  /// `TextField` hint text. Kept at the prior `0.6` value the panel
  /// used against the now-removed `Colors.white.withValues(alpha: 0.6)`
  /// literal for hint legibility parity.
  static const double hintTextAlpha = 0.6;

  @override
  State<DebugConsoleOverlayPanel> createState() =>
      _DebugConsoleOverlayPanelState();
}
