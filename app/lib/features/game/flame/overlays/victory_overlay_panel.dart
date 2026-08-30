import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show pickUniqueGreatPowerLeaderByPowerScore;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_spacing.dart';
import 'victory_overlay_panel_actions.dart';
import 'victory_overlay_panel_corners.dart';
import 'victory_overlay_panel_layout.dart';

export 'victory_overlay_panel_layout.dart';

/// Brass-bordered ceremonial panel for `OVL20001` (military or calendar halt).
///
/// Visual contract: SPEC/ui/victory-overlay.md and the OVL20001 mockup.
/// Renders the laurel decoration row, the localized title, a [CtBrassDivider],
/// the body sentence, and two action buttons inside a
/// `surface-lite → bg-deep` gradient surface with a 2px `--accent` border
/// and asymmetric corner brackets.
class VictoryPanel extends StatelessWidget {
  const VictoryPanel({
    required this.game,
    required this.bus,
    this.victory,
    this.onViewFinalState,
    super.key,
  });

  final ct_models.Game game;

  /// When non-null, military victory copy. When null, calendar-complete copy.
  final ct_models.VictoryState? victory;
  final ct_models.AppEventBus bus;
  final VoidCallback? onViewFinalState;

  /// Outer max width for the ceremonial panel.
  @visibleForTesting
  static const double maxWidth = VictoryPanelLayout.maxWidth;

  /// Border thickness for the surrounding `--accent` frame.
  static const double borderWidth = VictoryPanelLayout.borderWidth;

  /// Corner-bracket dimensions for the top-left / bottom-right ornaments.
  static const double cornerBracketWidth =
      VictoryPanelLayout.cornerBracketWidth;
  static const double cornerBracketHeight =
      VictoryPanelLayout.cornerBracketHeight;
  static const double cornerBracketInset =
      VictoryPanelLayout.cornerBracketInset;
  static const double cornerBracketStroke =
      VictoryPanelLayout.cornerBracketStroke;
  static const double cornerBracketAlpha =
      VictoryPanelLayout.cornerBracketAlpha;

  /// Laurel font size at default and narrow viewport widths.
  static const double laurelFontSizeWide = VictoryPanelLayout.laurelFontSizeWide;
  static const double laurelFontSizeNarrow =
      VictoryPanelLayout.laurelFontSizeNarrow;

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.xxl),
        child: Stack(
          children: <Widget>[
            _buildPanelSurface(context, narrow: narrow),
            Positioned(
              top: cornerBracketInset,
              left: cornerBracketInset,
              child: victoryPanelTopLeftCornerBracket(),
            ),
            Positioned(
              bottom: cornerBracketInset,
              right: cornerBracketInset,
              child: victoryPanelBottomRightCornerBracket(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSurface(BuildContext context, {required bool narrow}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.victoryPanelGradient,
        border: Border.all(
          color: EditorialMonoclePalette.accent,
          width: borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: _buildPanelColumn(context, narrow: narrow),
      ),
    );
  }

  Widget _buildPanelColumn(BuildContext context, {required bool narrow}) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleBase =
        narrow ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall;
    final TextStyle? titleStyle = titleBase?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyBase =
        narrow ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge;
    final TextStyle? bodyStyle = bodyBase?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        VictoryLaurelRow(narrow: narrow),
        const SizedBox(height: 10),
        Text(
          _titleLabel(l10n).toUpperCase(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const CtBrassDivider(),
        const SizedBox(height: 14),
        Text(
          _bodyLabel(l10n),
          style: bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        buildVictoryPanelActionRow(
          context,
          l10n,
          bus: bus,
          onViewFinalState: onViewFinalState,
          narrow: narrow,
        ),
      ],
    );
  }

  String _titleLabel(AppLocalizations l10n) {
    final state = victory;
    if (state == null) return l10n.victory_campaignComplete;
    return switch (state.type) {
      ct_models.VictoryType.military => l10n.victory_military,
    };
  }

  String _bodyLabel(AppLocalizations l10n) {
    final state = victory;
    if (state != null) {
      final ct_models.Player winner =
          game.playerById(state.winnerPlayerId) ?? game.players.first;
      return l10n.victory_winnerOnTurn(winner.displayName, state.turnNumber);
    }
    final declaredId = pickUniqueGreatPowerLeaderByPowerScore(game);
    if (declaredId == null) return l10n.victory_endCalendarNoWinner;
    final name =
        game.playerById(declaredId)?.displayName ?? declaredId;
    return l10n.victory_endCalendarDeclaredWinner(name);
  }
}
