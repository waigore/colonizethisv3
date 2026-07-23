/// Negotiation-mood emission helpers for DiplomacyPanel order actions.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/routes.dart';
import '../../../../config/themes.dart' show editorialMonocleDisplayFontFamily;
import '../../../../core/services/app_event_handler/app_event_handler_scope.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_radius.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/relation_meter.dart';
import 'diplomacy_order_helpers.dart';
import 'diplomacy_panel_rows.dart';
import 'fnv1a_hash_constants.dart';
import 'relative_power_line.dart';
import 'diplomacy_panel_widget.dart';
/// Negotiation-mood emission helpers for [DiplomacyPanel] order actions.
/// SPEC/ui/diplomacy-panel.md.


mixin DiplomacyOrderActionsMood on State<DiplomacyPanel> {
  Map<String, String> get moodByLeaderId;
  int pendingCountForTarget(String targetFactionId) {
    final list =
        widget.currentOrders.diplomaticOrdersByPlayerId[widget.humanPlayerId] ??
        const <DiplomaticOrder>[];
    return list.where((o) => o.targetFactionId == targetFactionId).length;
  }

  double offerQualityDeltaFor(DiplomaticOrderType type) {
    switch (type) {
      case DiplomaticOrderType.declareWar:
        return -0.8;
      case DiplomaticOrderType.offerPeace:
        return 0.6;
      case DiplomaticOrderType.alliance:
        return 0.4;
      case DiplomaticOrderType.breakAlliance:
        return -0.4;
      case DiplomaticOrderType.establishOverture:
        return 0.5;
      case DiplomaticOrderType.grantAid:
        return 0.7;
      case DiplomaticOrderType.setSubsidy:
        return 0.5;
      case DiplomaticOrderType.establishFtp:
        return 0.5;
      case DiplomaticOrderType.boycott:
        return -0.6;
      case DiplomaticOrderType.revokeBoycott:
        return 0.3;
    }
  }

  int stableSeed({
    required String leaderId,
    required String discriminator,
    required int stallCounter,
  }) {
    final turn = widget.game.worldState.turnState.turnNumber;
    final base = widget.game.globalGameSeed ?? 0;
    final text = '$leaderId|$discriminator|$stallCounter|$turn';
    var hash = kFnv1aOffsetBasis32;
    for (final code in text.codeUnits) {
      hash ^= code;
      hash = (hash * kFnv1aPrime32) & kDeterministicLcg31Mask;
    }
    return base ^ hash;
  }

  void emitNegotiationMood({
    required String leaderId,
    required double offerQualityDelta,
    required int stallCounter,
    required String discriminator,
  }) {
    final currentMood = moodByLeaderId[leaderId] ?? kDefaultMood;
    widget.bus.emit(
      NegotiationMoodUpdateEvent(
        leaderId: leaderId,
        currentMood: currentMood,
        offerQualityDelta: offerQualityDelta,
        stallCounter: stallCounter,
        seed: stableSeed(
          leaderId: leaderId,
          discriminator: discriminator,
          stallCounter: stallCounter,
        ),
      ),
    );
  }
}
