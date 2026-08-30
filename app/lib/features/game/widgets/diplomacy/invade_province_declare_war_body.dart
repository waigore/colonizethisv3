/// Shared Declare War confirm body for invasion sub-dialogs (Refs #4409).
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pair invasion copy plus the same third-party Effect lines as GAME30001.
String invadeProvinceDeclareWarBody({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String targetFactionId,
  required String ownerLabel,
}) {
  final pair = l10n.moveArmy_invadeProvinceBody(ownerLabel);
  final extra = declareWarThirdPartyPreviewLines(
    game: game,
    humanPlayerId: humanPlayerId,
    targetFactionId: targetFactionId,
  );
  if (extra.isEmpty) return pair;
  return '$pair\n${extra.join('\n')}';
}
