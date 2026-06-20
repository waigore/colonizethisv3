import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_radius.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'debug_console_controller.dart';

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

class _DebugConsoleOverlayPanelState extends State<DebugConsoleOverlayPanel> {
  late final DebugConsoleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DebugConsoleController(
      bus: widget.bus,
      humanPlayerId: widget.humanPlayerId,
      readOnlyContextProvider: widget.readOnlyContextProvider,
      onClose: widget.onClose,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _controller.submit();
    });
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final handled = _controller.handleKeyEvent(event);
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Material(
      color: EditorialMonoclePalette.bgDeep.withValues(
        alpha: DebugConsoleOverlayPanel.panelBackgroundAlpha,
      ),
      borderRadius: BorderRadius.circular(CtRadius.large),
      child: SizedBox(
        width: 420,
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(l10n),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(CtSpacing.s),
                  color: EditorialMonoclePalette.dialogScrim,
                  child: _buildLogList(),
                ),
              ),
              const SizedBox(height: CtSpacing.s),
              _buildInput(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.debugConsole_title,
            style: TextStyle(
              color: EditorialMonoclePalette.fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CtIconAction(
          key: DebugConsoleOverlayPanel.closeButtonKey,
          tooltip: 'Close debug console',
          icon: Icons.close,
          iconColor: EditorialMonoclePalette.fg,
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _buildLogList() {
    return ListView(
      children: _controller.lines
          .map(
            (line) => Text(
              line,
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildInput(AppLocalizations l10n) {
    return Focus(
      onKeyEvent: _handleKey,
      child: TextField(
        key: const ValueKey<String>('debug-console-input'),
        focusNode: _controller.focusNode,
        controller: _controller.textController,
        onSubmitted: (_) => _submit(),
        style: TextStyle(color: EditorialMonoclePalette.fg),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.debugConsole_hintSpawnCivilian,
          hintStyle: TextStyle(
            color: EditorialMonoclePalette.muted.withValues(
              alpha: DebugConsoleOverlayPanel.hintTextAlpha,
            ),
          ),
          filled: true,
          fillColor: EditorialMonoclePalette.dialogScrim,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CtRadius.medium),
          ),
        ),
      ),
    );
  }
}
