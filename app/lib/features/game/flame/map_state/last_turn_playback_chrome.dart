// Caption + Skip chrome for last-turn map playback (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_nine_patch_button.dart';

/// Insets that keep caption/Skip off the tab row, news toggle, and sheet close.
EdgeInsets lastTurnPlaybackChromeInsets({required bool isNarrow}) {
  return EdgeInsets.only(
    left: isNarrow ? 56 : 72,
    right: isNarrow ? 8 : 120,
    bottom: isNarrow ? 88 : 64,
  );
}

/// Overlay placement for [LastTurnPlaybackChrome] on `MAP10001`.
Widget lastTurnPlaybackChromeOverlay({
  required bool isNarrow,
  required String caption,
  required String skipLabel,
  required VoidCallback onSkip,
}) {
  final insets = lastTurnPlaybackChromeInsets(isNarrow: isNarrow);
  return Positioned(
    left: insets.left,
    right: insets.right,
    bottom: insets.bottom,
    child: LastTurnPlaybackChrome(
      caption: caption,
      skipLabel: skipLabel,
      onSkip: onSkip,
    ),
  );
}

class LastTurnPlaybackChrome extends StatelessWidget {
  const LastTurnPlaybackChrome({
    required this.caption,
    required this.skipLabel,
    required this.onSkip,
    super.key,
  });

  final String caption;
  final String skipLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EditorialMonoclePalette.bgDeep.withValues(alpha: 0.9),
                border: Border.all(color: EditorialMonoclePalette.accent),
              ),
              child: Text(
                caption,
                style: TextStyle(
                  color: EditorialMonoclePalette.fg,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CtNinePatchButton(
            key: const Key('last_turn_playback_skip'),
            minHeight: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: onSkip,
            child: Text(skipLabel),
          ),
        ],
      ),
    );
  }
}
