/// Standing-chip derivation for diplomacy panel rows.

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_panel_rows.dart';

/// Display names of Great Powers the human GP boycotts through a colony Tribe
/// it holds (Refs #3753 R12). Extracted so the standing-chip builder stays
/// under the repo control-flow nesting-depth gate.
List<String> _boycottVsNames(Game game, String humanPlayerId) {
  final names = <String>[];
  for (final b in game.boycottStates) {
    if (b.gpId == humanPlayerId) {
      names.add(game.playerById(b.targetGpId)?.displayName ?? b.targetGpId);
    }
  }
  return names;
}

/// Display names of Great Powers boycotting the human GP from trading with a
/// colony Tribe held by [colonyOfGpId] (Refs #3753 R12). Extracted so the
/// standing-chip builder stays under the repo control-flow nesting-depth gate.
List<String> _boycottedByNames(
  Game game,
  String humanPlayerId,
  String colonyOfGpId,
) {
  final names = <String>[];
  for (final b in game.boycottStates) {
    if (b.gpId == colonyOfGpId && b.targetGpId == humanPlayerId) {
      names.add(game.playerById(colonyOfGpId)?.displayName ?? colonyOfGpId);
    }
  }
  return names;
}

/// Derives the [DiplomaticStandingChips] for a faction row from current
/// [game] state. SPEC/ui/diplomacy-panel.md § Diplomatic standing chip
/// cluster (Refs #3753 R12). [purchasedTiles] is built once per render pass
/// by the caller (e.g. [buildDiplomacyRows]) so the per-tile attribution scan
/// is not repeated per row.
DiplomaticStandingChips diplomaticStandingChips({
  required Game game,
  required String humanPlayerId,
  required String factionId,
  required FactionKind kind,
  required DiplomacyRelation? relation,
  required OvertureState? overture,
  required PurchasedTileIndex purchasedTiles,
}) {
  final OvertureStage stage = overture?.stage ?? OvertureStage.none;
  final treaty = <String>[];
  if (stage.index >= OvertureStage.tradeConsulate.index) {
    treaty.add(kDiplomacyChipConsulate);
  }
  if (stage.index >= OvertureStage.embassy.index) {
    treaty.add(kDiplomacyChipEmbassy);
  }
  if (stage.index >= OvertureStage.nap.index) {
    treaty.add(kDiplomacyChipNap);
  }

  String? colonyOfGpId;
  if (kind == FactionKind.tribe) {
    for (final c in game.colonyStates) {
      if (c.tribeId == factionId) {
        colonyOfGpId = c.colonyOfGpId;
        break;
      }
    }
  }
  final bool isColonyOfHuman = colonyOfGpId == humanPlayerId;
  if (isColonyOfHuman) {
    treaty.add(kDiplomacyChipColony);
  } else if (kind == FactionKind.minor && stage == OvertureStage.joinEmpire) {
    treaty.add(kDiplomacyChipJoinEmpire);
  }

  List<String> boycottVs = const <String>[];
  List<String> boycottedBy = const <String>[];
  if (colonyOfGpId != null && isColonyOfHuman) {
    boycottVs = _boycottVsNames(game, humanPlayerId);
  } else if (colonyOfGpId != null) {
    boycottedBy = _boycottedByNames(game, humanPlayerId, colonyOfGpId);
  }

  int overseasCount = 0;
  if (kind != FactionKind.greatPower) {
    for (final a in purchasedTiles.attributions) {
      if (a.owningGpId == humanPlayerId && a.sourceFactionId == factionId) {
        overseasCount++;
      }
    }
  }
  final int overseasShare = relation == null ? 0 : relation.score.round();

  return DiplomaticStandingChips(
    treatyLabels: treaty,
    boycottVsNames: boycottVs,
    boycottedByNames: boycottedBy,
    overseasTileCount: overseasCount,
    overseasSharePercent: overseasShare,
  );
}
