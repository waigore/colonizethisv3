import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_chrome_relation_badges.dart'
    show DiplomacyAllianceBadge;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

List<Widget> buildOwnerStandingLine({
  required AppLocalizations l10n,
  required bool atWar,
  required bool showAllianceBadge,
  required TextStyle bodyStyle,
}) {
  final standing = atWar
      ? l10n.provinceOverlay_ownerStandingAtWar
      : l10n.provinceOverlay_ownerStandingAtPeace;
  return [
    Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(standing, style: bodyStyle),
          if (showAllianceBadge) const DiplomacyAllianceBadge(),
        ],
      ),
    ),
  ];
}

List<Widget> buildOfferPeaceControl({
  required AppLocalizations l10n,
  required bool enabled,
  required bool pending,
  required String? rejectionReason,
  required VoidCallback? onTap,
  required bool isNarrow,
  required TextStyle bodyStyle,
}) {
  final label = pending
      ? l10n.provinceOverlay_cancelOfferPeaceAction
      : l10n.provinceOverlay_offerPeaceAction;
  final tooltip = enabled || rejectionReason == null ? label : rejectionReason;
  return [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CtActionTextButton(
            label: label,
            tooltip: tooltip,
            semanticLabel: !enabled && rejectionReason != null
                ? l10n.provinceOverlay_offerPeaceDisabledSemantics(
                    rejectionReason,
                  )
                : label,
            enabled: enabled,
            onPressed: enabled ? onTap : null,
          ),
          if (isNarrow && !enabled && rejectionReason != null)
            Text(rejectionReason, style: bodyStyle),
        ],
      ),
    ),
  ];
}

List<Widget> buildEstablishConsulateControl({
  required AppLocalizations l10n,
  required String ownerName,
  required bool enabled,
  required bool pending,
  required String? rejectionReason,
  required VoidCallback? onTap,
  required bool isNarrow,
  required TextStyle bodyStyle,
}) {
  final label = pending
      ? l10n.provinceOverlay_cancelEstablishConsulateAction
      : l10n.provinceOverlay_establishConsulateAction;
  final tooltip = enabled || rejectionReason == null ? label : rejectionReason;
  return [
    Text(l10n.provinceOverlay_noConsulateWith(ownerName), style: bodyStyle),
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CtActionTextButton(
            label: label,
            tooltip: tooltip,
            semanticLabel: !enabled && rejectionReason != null
                ? l10n.provinceOverlay_establishConsulateDisabledSemantics(
                    rejectionReason,
                  )
                : label,
            enabled: enabled,
            onPressed: enabled ? onTap : null,
          ),
          if (isNarrow && !enabled && rejectionReason != null)
            Text(rejectionReason, style: bodyStyle),
        ],
      ),
    ),
  ];
}
