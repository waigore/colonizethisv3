// coverage:ignore-file
// E2E expected-line helpers for province overlay road/rail transport labels.

const String kRoadRailPrimitiveVersusRailGloss =
    'Basic land link for connectivity and yield caps. Railroads are transport level 4.';

String roadRailDefaultCaptionLine(int roadLevel) {
  return 'Road / railroad: ${roadRailSupplementaryLabel(roadLevel)}';
}

String roadRailSupplementaryLabel(int roadLevel) {
  return switch (roadLevel) {
    0 => 'none',
    1 => 'primitive road',
    2 => 'improved road',
    4 => 'port or railroad',
    _ => 'non-standard transport level',
  };
}

String roadRailTransportLevelPrimaryLine(int transportLevel) {
  return 'Road / railroad: transport level $transportLevel';
}
