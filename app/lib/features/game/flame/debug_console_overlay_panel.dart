import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug_console_controller.dart';

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
      color: Colors.black.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 420,
        height: 220,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(l10n),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  color: EditorialMonoclePalette.dialogScrim,
                  child: _buildLogList(),
                ),
              ),
              const SizedBox(height: 6),
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Close debug console',
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: Colors.white),
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
              style: const TextStyle(
                color: Colors.white,
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
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.debugConsole_hintSpawnCivilian,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          filled: true,
          fillColor: EditorialMonoclePalette.dialogScrim,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
