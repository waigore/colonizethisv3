// In-game shell top bar. SPEC/ui/in-game-shell-narrow.md § Top bar.
//
// De-parted wave-9 cluster (Refs #4117): explicit-import libraries replace the
// former 3-part library. Public surface: [GameTopBar].

import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_gradients.dart';

import 'game_top_bar_layout.dart';

/// In-game shell top bar: 36 px dark editorial-monocle chrome with a
/// 3-line hamburger, centered turn display, optional observe banner,
/// bordered pause affordance, and the wood-panel `Next turn` button.
///
/// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Top bar, `SPEC/ui/empire-overview.md`
/// (in-game shell), `SPEC/ui/mobile-adaptation.md` § 4 In-game shell
/// (`< kNarrowBreakpoint`: hamburger + turn-counter / Next-turn button only),
/// and the canonical [CtTopBar] chrome contract in
/// `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette
/// (gradient + 1 px `--accent-dim` bottom border). Issue #2861 S1; narrow
/// top-bar chrome #2870 S10.
///
/// Renders a fixed-height [SizedBox] wrapped in a [DecoratedBox] that
/// paints [CtGradients.topBarGradient] and a 1 px
/// [EditorialMonoclePalette.accentDim] bottom border, matching the
/// existing `CtTopBar` chrome family. The bar is intentionally a
/// dedicated widget (rather than a thin wrap around `CtTopBar`) because
/// the in-game shell needs:
///
/// - a 28 x 28 hamburger leading slot (no `CtBackButton` chevron),
/// - an optional muted observe banner between the hamburger and the
///   Next-turn button,
/// - a primary [CtNinePatchButton] trailing slot rather than the
///   text-only trailing widget that `CtTopBar` carries.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue
/// #2858); no hard-coded hex literals.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.onToggleSideMenu,
    required this.onPausePressed,
    required this.onNextTurn,
    required this.nextTurnEnabled,
    required this.turnDisplayText,
    required this.nextTurnText,
    required this.menuTooltip,
    required this.pauseTooltip,
    this.observeBannerLabel,
  });

  /// Tap callback for the leading hamburger. Opens the in-game side menu
  /// (Debug log + Game Parameters) per `SPEC/ui/game-side-menu.md`.
  final VoidCallback onToggleSideMenu;

  /// Tap callback for the bordered pause affordance. The host emits
  /// `OpenPauseMenuPanelEvent` on the app bus per
  /// `SPEC/ui/in-game-shell-narrow.md` § Top bar. Null while turn resolution
  /// blocks ([save-load-session-clear.md]).
  final VoidCallback? onPausePressed;

  /// Tap callback for the trailing wood-panel `Next turn` button. The
  /// host handles the confirmation + processing dialog flow per
  /// `SPEC/ui/next-turn-confirmation.md`.
  final Future<void> Function() onNextTurn;

  /// When `false`, the Next-turn button passes both `enabled: false` and
  /// `onPressed: null` to [CtNinePatchButton], plus
  /// `disabledOpacityOverride: kNextTurnDisabledOpacity` (`0.35`), so the
  /// button reads as non-interactive AND dims to the SPEC-mandated 0.35
  /// opacity during turn resolution. SPEC alignment: issue #2861 R1 /
  /// AC#9 (`SPEC/ui/game-screen.md` § Acceptance Criteria; mockup
  /// `.next-turn.disabled { opacity: 0.35 }` in
  /// `SPEC/ui/mockups/GAME10001-game-screen.html`). The override is
  /// scoped to this Next-turn button; other [CtNinePatchButton] call
  /// sites continue to use the catalog default
  /// [CtNinePatchButton.disabledOpacity] (`0.4`).
  final bool nextTurnEnabled;

  /// Centered turn/year label (e.g. `Turn 42 / Year 1650`). The host
  /// owns i18n formatting via `game_turnDisplay`.
  final String turnDisplayText;

  /// Pre-formatted button label (e.g. `Next turn (42 / 1650)` or the
  /// observe-mode `Observe — Turn 42 (1650)` fallback). The host owns
  /// the i18n + turn/year formatting.
  final String nextTurnText;

  /// Accessibility tooltip for the hamburger affordance. The caller
  /// resolves the localised string (`appL10n(context).gameMap_menuTooltip`).
  final String menuTooltip;

  /// Accessibility tooltip for the pause affordance (`game_pauseMenu_tooltip`).
  final String pauseTooltip;

  /// Optional muted banner rendered between the hamburger and the Next
  /// turn button. Shown when the shell is in observe mode; `null` in the
  /// default player path.
  final String? observeBannerLabel;

  /// Fixed bar height (issue #2861 R1: `36 px top bar`).
  static const double height = 36;

  /// Bottom-border width — matches [CtBackButton.size] / `CtTopBar`
  /// chrome family.
  static const double borderWidth = 1;

  /// Hamburger affordance tap-target side length (issue #2861 R1).
  static const double hamburgerSize = 28;

  /// Hamburger glyph side length inside the 28 dp tap target.
  static const double hamburgerGlyphSize = 18;

  /// Inner [CtNinePatchButton] minimum height so the wood-panel chrome
  /// fits inside the 36 dp bar with a 2 dp top/bottom inset. The bar is
  /// already constrained by its outer SPEC height; the host page chrome
  /// remains the dominant tap target.
  static const double nextTurnMinHeight = 32;

  /// Inset between the hamburger and the optional observe banner /
  /// Next-turn button.
  static const double leadingGap = 8;

  /// Inset before the Next-turn button (after the observe banner or a
  /// flexible spacer).
  static const double trailingGap = 8;

  /// Outer horizontal padding inside the bar (matches `CtTopBar`).
  static const double horizontalPadding = 8;

  /// Stable widget key for the hamburger affordance — surfaced for
  /// integration / widget tests.
  static const Key hamburgerKey = Key('game_top_bar_hamburger');

  /// Stable widget key for the centered turn display label.
  static const Key turnDisplayKey = Key('game_top_bar_turn_display');

  /// Stable widget key for the pause affordance.
  static const Key pauseButtonKey = Key('game_top_bar_pause');

  /// Stable widget key for the optional observe banner text.
  static const Key observeBannerKey = Key('game_top_bar_observe_banner');

  /// Stable widget key for the outer bar surface (DecoratedBox).
  static const Key surfaceKey = Key('game_top_bar_surface');

  @override
  Widget build(BuildContext context) {
    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final bool isNarrow = viewportWidth < kNarrowBreakpoint;
    final bool isMinViewport = viewportWidth <= kMinViewportWidth;

    return SizedBox(
      key: surfaceKey,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: CtGradients.topBarGradient,
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isNarrow
                ? buildNarrowRowChildren(isMinViewport: isMinViewport)
                : buildWideRowChildren(context),
          ),
        ),
      ),
    );
  }
}
