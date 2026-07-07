/// Scrimmed shell chrome for [InterventionDialogueOverlay] phases.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
part of 'intervention_dialogue_overlay.dart';

/// Stable key for the "Pending Intervention" title `Text` widget so widget
/// tests can pin the dark editorial-monocle chrome contract without matching
/// localized strings.
const String kInterventionOverlayTitleKey = 'interventionOverlayTitle';

/// Stable key for the [CtBrassDivider] beneath the title.
const String kInterventionOverlayBrassDividerKey =
    'interventionOverlayBrassDivider';

/// Maximum content width inside `CtDialogShell` for the intervention overlay.
/// Shared with the prior layout (520 dp).
const double _kInterventionShellMaxWidth = 520;

/// Vertical gap between the title and the [CtBrassDivider] (#2867 SPEC table).
const double _kTitleToDividerGap = 8;

/// Vertical gap between the [CtBrassDivider] and the per-phase body.
const double _kDividerToBodyGap = 12;

/// Canonical 0.05em letter-spacing factor for the overlay title (#2867 R2).
const double _kOverlayTitleLetterSpacingEm = 0.05;

extension _InterventionDialogueOverlayShell on _InterventionDialogueOverlayState {
  /// Wrap the per-phase body in the dark editorial-monocle scrim +
  /// [CtFullScreenDialogueShell] with the canonical "Pending Intervention"
  /// title + [CtBrassDivider] header rendered on every phase (#2867 R1 / R2 /
  /// R26b; SPEC `SPEC/ui/screens/pending-intervention-overlay.md` § Dark
  /// editorial-monocle chrome). The scrim + framed shell scaffold lives in
  /// [CtFullScreenDialogueShell] (issue #2914 S2) so this method only owns
  /// the per-overlay title / divider composition.
  Widget buildInterventionScrimmedShell({
    required BuildContext context,
    required List<Widget> bodyChildren,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(CtSpacing.xl),
  }) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = _overlayTitleStyle(theme);
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      maxWidth: _kInterventionShellMaxWidth,
      padding: bodyPadding,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.game_intervention_overlayTitle,
            key: const ValueKey<String>(kInterventionOverlayTitleKey),
            style: titleStyle,
          ),
          const SizedBox(height: _kTitleToDividerGap),
          const CtBrassDivider(
            key: ValueKey<String>(kInterventionOverlayBrassDividerKey),
          ),
          const SizedBox(height: _kDividerToBodyGap),
          ...bodyChildren,
        ],
      ),
    );
  }

  /// Canonical title style per #2867 R2: `--accent` text with a 0.05em
  /// letter-spacing computed from the resolved title `fontSize` so the
  /// spacing scales with theme `titleMedium` overrides.
  TextStyle _overlayTitleStyle(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final double fontSize = base.fontSize ?? 16;
    return base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: fontSize * _kOverlayTitleLetterSpacingEm,
    );
  }
}
