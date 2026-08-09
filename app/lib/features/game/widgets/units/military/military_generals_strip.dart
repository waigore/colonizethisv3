// Generals roster strip on Military Units land section (#4233).
// SPEC/ui/military-units-panel.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show GamePlayerLookup;
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'general_command_capacity.dart';

/// Compact generals summary for the human player on `UNIT20001`.
class MilitaryGeneralsStrip extends StatefulWidget {
  const MilitaryGeneralsStrip({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  final Game game;
  final String humanPlayerId;

  @override
  State<MilitaryGeneralsStrip> createState() => _MilitaryGeneralsStripState();
}

class _MilitaryGeneralsStripState extends State<MilitaryGeneralsStrip> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final player = widget.game.playerById(widget.humanPlayerId);
    if (player == null) return const SizedBox.shrink();

    final cap = effectiveGeneralCapForPlayer(player);
    final roster = generalsForPlayer(widget.game, widget.humanPlayerId);
    final displayCount = humanGeneralCountForDisplay(
      widget.game,
      widget.humanPlayerId,
    );
    final bodyStyle = (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.fg.withValues(alpha: 0.9),
    );
    final mutedStyle = bodyStyle.copyWith(
      color: EditorialMonoclePalette.muted,
    );

    final medalGenerals = roster.isNotEmpty
        ? roster
        : List<General>.generate(
            displayCount,
            (i) => General(
              id: '${widget.humanPlayerId}_display_$i',
              ownerId: widget.humanPlayerId,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.ml),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: EditorialMonoclePalette.border),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              EditorialMonoclePalette.bgDeep,
              EditorialMonoclePalette.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.military_units_generalsCount(displayCount, cap),
                          style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: CtSpacing.xs),
                        for (var i = 0; i < medalGenerals.length; i++)
                          Text(
                            l10n.military_units_generalMedals(
                              i + 1,
                              medalGenerals[i].medals,
                            ),
                            style: mutedStyle,
                          ),
                        const SizedBox(height: CtSpacing.s),
                        Text(
                          l10n.military_units_generalsPlainSummary,
                          style: mutedStyle,
                        ),
                      ],
                    ),
                  ),
                  CtActionTextButton(
                    onPressed: () =>
                        setState(() => _showDetails = !_showDetails),
                    label: _showDetails
                        ? l10n.military_units_generalsHideDetails
                        : l10n.military_units_generalsDetails,
                  ),
                ],
              ),
              if (_showDetails) ...[
                const SizedBox(height: CtSpacing.s),
                Text(
                  l10n.military_units_generalsMedalGloss,
                  style: mutedStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
