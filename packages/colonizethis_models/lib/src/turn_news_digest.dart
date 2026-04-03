// Turn-start news digest lines. SPEC/program/turn-news-digest.md; UI: SPEC/ui/turn-news-dialog.md.

import 'diplomacy.dart';

/// Digest for the turn that just finished (resolved turn number).
class TurnNewsDigest {
  const TurnNewsDigest({
    required this.resolvedTurnNumber,
    required this.lines,
  });

  final int resolvedTurnNumber;
  final List<TurnNewsLine> lines;
}

/// One display line in the news digest.
sealed class TurnNewsLine {
  const TurnNewsLine();
}

class TurnNewsProvinceCapturedLine extends TurnNewsLine {
  const TurnNewsProvinceCapturedLine({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
  });

  final String provinceId;
  final String previousOwnerId;
  final String newOwnerId;
}

enum TurnNewsDiplomacyKind { war, peace }

/// [factionIdA] and [factionIdB] are sorted lexicographically (stable neutral pair).
class TurnNewsDiplomacyLine extends TurnNewsLine {
  const TurnNewsDiplomacyLine({
    required this.factionIdA,
    required this.factionIdB,
    required this.kind,
  });

  final String factionIdA;
  final String factionIdB;
  final TurnNewsDiplomacyKind kind;
}

/// Overture stage advanced vs start of turn (acceptance path).
class TurnNewsOvertureAdvancedLine extends TurnNewsLine {
  const TurnNewsOvertureAdvancedLine({
    required this.offererGpId,
    required this.targetFactionId,
    required this.newStage,
  });

  final String offererGpId;
  final String targetFactionId;
  final OvertureStage newStage;
}

/// First global charting of a province (any GP gained non-unknown visibility).
class TurnNewsProvinceDiscoveredLine extends TurnNewsLine {
  const TurnNewsProvinceDiscoveredLine({required this.provinceId});

  final String provinceId;
}

/// First recorded fleet presence in this sea zone (global).
class TurnNewsSeaZoneFleetLine extends TurnNewsLine {
  const TurnNewsSeaZoneFleetLine({required this.seaZoneId});

  final String seaZoneId;
}
