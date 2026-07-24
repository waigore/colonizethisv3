import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'player_turn_event_feed_toggle_glyph.dart';

/// Newspaper toggle for the human-player turn event feed; lives in the
/// trailing slot of [GameTabBar].
///
/// Implements `Refs #2861` M3 mockup-fidelity chrome (mockup `.news-toggle`
/// in `SPEC/ui/mockups/GAME10001-game-screen.html`): a bordered
/// `28 × 22` dp surface filled with [EditorialMonoclePalette.bgDeep] behind a
/// `1` dp [EditorialMonoclePalette.border] outline (lifting to
/// [EditorialMonoclePalette.accentDim] on hover/open). The glyph is a
/// `14 × 14` dp monochrome [NewspaperGlyph] vector (the mockup `.news-toggle
/// svg`, **not** a Material `Icons.newspaper` at 20 dp), tinted via
/// `currentColor` semantics: [EditorialMonoclePalette.accentDim] closed,
/// [EditorialMonoclePalette.accentBright] on hover, and
/// [EditorialMonoclePalette.accent] while the feed is open.
///
/// The unread-count badge resolves to the canonical
/// [EditorialMonoclePalette.danger] token (dark warm-red), positioned per the
/// mockup `.news-badge` (`top: -4`, `right: -6`), not the legacy Material
/// `Colors.redAccent`.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals. SPEC: `SPEC/ui/player-turn-event-feed.md`.
class PlayerTurnEventsFeedToggleButton extends StatefulWidget {
  const PlayerTurnEventsFeedToggleButton({
    super.key,
    required this.eventCount,
    required this.tooltip,
    required this.showFeed,
    required this.onPressed,
  });

  final int eventCount;
  final String tooltip;
  final bool showFeed;
  final VoidCallback onPressed;

  /// Width of the toggle surface (mockup `.news-toggle { width: 28px }`).
  static const double surfaceWidth = 28;

  /// Height of the toggle surface (mockup `.news-toggle { height: 22px }`).
  static const double surfaceHeight = 22;

  /// Side length of the newspaper glyph painted inside the toggle
  /// (mockup `.news-toggle svg { width: 14px; height: 14px }`).
  static const double glyphSize = 14;

  /// Border thickness around the toggle surface
  /// (mockup `.news-toggle { border: 1px solid var(--border) }`).
  static const double borderWidth = 1;

  /// Min height/width of the unread-count badge (sized for "99+").
  static const double badgeMinExtent = 16;

  /// Outer alpha of the badge background (so very dim chrome behind it
  /// still reads, but the badge sits brightly forward).
  static const double badgeBackgroundAlpha = 0.95;

  @override
  State<PlayerTurnEventsFeedToggleButton> createState() =>
      _PlayerTurnEventsFeedToggleButtonState();
}

class _PlayerTurnEventsFeedToggleButtonState
    extends State<PlayerTurnEventsFeedToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.showFeed;
    final Color glyphColor = active
        ? EditorialMonoclePalette.accent
        : (_hovering
              ? EditorialMonoclePalette.accentBright
              : EditorialMonoclePalette.accentDim);
    final Color borderColor = (active || _hovering)
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: kPlayerTurnFeedToggleButtonKey,
            onTap: widget.onPressed,
            child: Container(
              width: PlayerTurnEventsFeedToggleButton.surfaceWidth,
              height: PlayerTurnEventsFeedToggleButton.surfaceHeight,
              decoration: BoxDecoration(
                color: EditorialMonoclePalette.bgDeep,
                border: Border.all(
                  color: borderColor,
                  width: PlayerTurnEventsFeedToggleButton.borderWidth,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  NewspaperGlyph(
                    size: PlayerTurnEventsFeedToggleButton.glyphSize,
                    color: glyphColor,
                  ),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: PlayerTurnEventFeedUnreadBadge(
                      count: widget.eventCount,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
