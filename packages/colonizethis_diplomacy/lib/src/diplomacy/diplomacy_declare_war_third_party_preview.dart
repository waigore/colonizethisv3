/// Third-party courts named on outgoing Declare War confirm (Refs #4409).
///
/// Eligibility matches the resolver: GP targets use the phase-start formal
/// alliance snapshot plus the already-at-war-with-aggressor skip; Minor/Tribe
/// targets use [gpHasEmbassyOrPurchasedLandInMinorTribe] with no war skip.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_pending_suspend.dart';
import 'diplomacy_resolver.dart';
import 'intervention_resolver_eligibility.dart';

/// Effect lines for other courts a declaration of war can pull in.
///
/// One line per qualifying court, sorted by display name. Empty when nobody
/// qualifies. Does not inspect draft `Alliance` orders.
List<String> declareWarThirdPartyPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetFactionId,
}) {
  if (isGreatPower(game, targetFactionId)) {
    return _callToArmsPreviewLines(
      game: game,
      humanPlayerId: humanPlayerId,
      targetGpId: targetFactionId,
    );
  }
  if (isMinorOrTribe(game, targetFactionId)) {
    return _interventionPreviewLines(
      game: game,
      humanPlayerId: humanPlayerId,
      targetId: targetFactionId,
    );
  }
  return const [];
}

/// Persisted formal-ally display names for a viewed Great Power (GAME30002).
///
/// Treaty roster only: no draft `Alliance`, no already-at-war-with-human
/// filter. Sorted by display name. Empty when none.
List<String> formalAllyDisplayNames({
  required Game game,
  required String viewedGpId,
  required String humanPlayerId,
}) {
  if (!isGreatPower(game, viewedGpId)) return const [];
  final allianceKeys = formalAlliancePairKeysAtPhaseStart(game);
  final names = <String>[];
  for (final p in game.players) {
    if (p.id == viewedGpId || p.id == humanPlayerId) continue;
    if (!isGreatPower(game, p.id)) continue;
    if (!allianceKeys.contains(pairKey(p.id, viewedGpId))) continue;
    names.add(_factionDisplayName(game, p.id));
  }
  names.sort();
  return names;
}

List<String> _callToArmsPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetGpId,
}) {
  final allianceKeys = formalAlliancePairKeysAtPhaseStart(game);
  final targetName = _factionDisplayName(game, targetGpId);
  final rows = <({String name, String line})>[];
  for (final p in game.players) {
    if (p.id == humanPlayerId || p.id == targetGpId) continue;
    if (!isGreatPower(game, p.id)) continue;
    if (factionsAtWar(game, p.id, humanPlayerId)) continue;
    final rel = getRelation(game, p.id, targetGpId);
    if (rel == null || !rel.atPeace) continue;
    if (!allianceKeys.contains(pairKey(p.id, targetGpId))) continue;
    final allyName = _factionDisplayName(game, p.id);
    rows.add((
      name: allyName,
      line:
          'Effect: $allyName holds a formal alliance with $targetName and '
          'may be called to defend. They may join the war against you or '
          'refuse.',
    ));
  }
  rows.sort((a, b) => a.name.compareTo(b.name));
  return [for (final r in rows) r.line];
}

List<String> _interventionPreviewLines({
  required Game game,
  required String humanPlayerId,
  required String targetId,
}) {
  final targetName = _factionDisplayName(game, targetId);
  final rows = <({String name, String line})>[];
  for (final p in game.players) {
    if (p.id == humanPlayerId) continue;
    if (!isGreatPower(game, p.id)) continue;
    if (!gpHasEmbassyOrPurchasedLandInMinorTribe(game, p.id, targetId)) {
      continue;
    }
    final gpName = _factionDisplayName(game, p.id);
    rows.add((
      name: gpName,
      line:
          'Effect: $gpName holds an Embassy or purchased land in $targetName '
          'and may be asked to intervene.',
    ));
  }
  rows.sort((a, b) => a.name.compareTo(b.name));
  return [for (final r in rows) r.line];
}

String _factionDisplayName(Game game, String id) {
  for (final p in game.players) {
    if (p.id == id) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == id) return m.displayName ?? id;
  }
  for (final t in game.tribes) {
    if (t.id == id) return t.displayName ?? id;
  }
  return id;
}
