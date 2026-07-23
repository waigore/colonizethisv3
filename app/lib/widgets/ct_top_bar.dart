import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_back_button.dart';
import 'ct_gradients.dart';
import 'ct_top_bar_layout.dart';

/// Pixel-art top bar for the dark editorial-monocle theme.
///
/// Implements `Refs #2859` R11 — a 36 px high horizontal bar painted with
/// [CtGradients.topBarGradient] and capped by a 1 px `--accent-dim`
/// bottom border. The bar lays out a leading [CtBackButton], an optional
/// `--muted` back-button label string, an optional pixel-art [icon], a
/// flexible [title] text, and an optional [trailing] slot.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue
/// #2858); no hard-coded hex literals. SPEC:
/// `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
/// (`CtTopBar` entry).
class CtTopBar extends StatelessWidget {
  const CtTopBar({
    super.key,
    required this.title,
    this.icon,
    this.backButtonLabel,
    this.onBackPressed,
    this.backButtonEnabled = true,
    this.backButtonSemanticLabel,
    this.trailing,
    this.showBackButton = true,
  });

  /// Required title text rendered using the dark-theme `titleMedium` slot
  /// (display font, `--accent` colour).
  final String title;

  /// Optional pixel-art icon (typically 18×18 px) painted between the
  /// back affordance and the title. The widget itself supplies no asset;
  /// callers compose the icon they want.
  final Widget? icon;

  /// Optional muted label rendered immediately after the chevron. Used
  /// to spell out the destination of the back action (e.g. `"Map"` on the
  /// production screen per #2862). When `null`, only the chevron is shown.
  final String? backButtonLabel;

  /// Forwarded to [CtBackButton.onPressed]. When `null` the back button
  /// falls back to `Navigator.maybePop()`.
  final VoidCallback? onBackPressed;

  /// Forwarded to [CtBackButton.enabled]. When `false` both the chevron
  /// **and** the [backButtonLabel] text dim to 0.4 opacity and the tap
  /// region is suppressed.
  final bool backButtonEnabled;

  /// Optional accessibility label for the back affordance. Forwarded to
  /// [CtBackButton.semanticLabel]; when `null`, the back button uses its
  /// own R11a default (`'Back'`).
  final String? backButtonSemanticLabel;

  /// Optional trailing slot rendered after the title (e.g. action button
  /// or right-aligned status icon).
  final Widget? trailing;

  /// When `false`, the leading [CtBackButton] (and the optional
  /// [backButtonLabel] text) is omitted entirely; the title plus optional
  /// icon and trailing slot still render. Used by container chrome that
  /// embeds [CtTopBar] but needs to control the back affordance separately
  /// (for example top-level shell routes that have no parent to pop to).
  final bool showBackButton;

  /// Fixed bar height (R11 / R4 — `36 px top bar`).
  static const double height = 36;

  /// Bottom-border width (matches `CtPanel` accent-line thickness).
  static const double borderWidth = 1;

  /// Outer horizontal padding inside the bar.
  static const double horizontalPadding = 8;

  /// Horizontal gap between the back affordance and the icon / title.
  static const double leadingGap = 4;

  /// Horizontal gap between the icon and the title text.
  static const double iconGap = 6;

  /// Horizontal gap before the optional trailing slot.
  static const double trailingGap = 8;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey<String>('ctTopBarSurface'),
      decoration: BoxDecoration(
        gradient: CtGradients.topBarGradient,
        border: Border(
          bottom: BorderSide(
            color: EditorialMonoclePalette.accentDim,
            width: borderWidth,
          ),
        ),
      ),
      child: SizedBox(
        key: const ValueKey<String>('ctTopBarHeightBox'),
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: buildCtTopBarRowChildren(this, context),
          ),
        ),
      ),
    );
  }
}
