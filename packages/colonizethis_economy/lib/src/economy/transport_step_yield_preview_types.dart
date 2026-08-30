/// Types and next-level mapping for transport-step extraction previews.
///
/// SPEC: SPEC/game/extraction-and-improvements.md § Transport Level.
library;

/// Why the next transport step does or does not raise what arrives.
enum TransportStepYieldKind {
  raise,
  roadPathLimit,
  townDevelopmentLimit,
  disconnected,
  bindsToCapital,
  portOnCoast,
}

/// Current vs hypothetical next effective yield after one transport work step.
class TransportStepYieldPreview {
  const TransportStepYieldPreview({
    this.commodityId,
    required this.currentEffective,
    required this.nextEffective,
    required this.kind,
  });

  final String? commodityId;
  final int currentEffective;
  final int nextEffective;
  final TransportStepYieldKind kind;
}

/// Work-target ids matching [colonizethis_orders] (passed as strings to avoid
/// an orders dependency in this package).
abstract final class TransportStepWorkTargets {
  static const buildRoad = 'build_road';
  static const buildPort = 'build_port';
  static const buildRail = 'build_rail';
}

/// Next stored transport after [workTarget] on [currentTransport], or null when
/// the step does not apply.
int? nextStoredTransportLevel({
  required String workTarget,
  required int currentTransport,
  required bool hasRoadConstructionTech,
}) {
  return switch (workTarget) {
    TransportStepWorkTargets.buildRoad => switch (currentTransport) {
      0 => 1,
      1 when hasRoadConstructionTech => 2,
      _ => null,
    },
    TransportStepWorkTargets.buildPort => currentTransport < 4 ? 4 : null,
    TransportStepWorkTargets.buildRail => switch (currentTransport) {
      1 || 2 => 4,
      _ => null,
    },
    _ => null,
  };
}
