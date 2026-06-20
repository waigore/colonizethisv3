/// Connectivity hot-path counters, threaded as a parameter through the
/// connectivity resolution call chain (Refs #3544 AC3).
///
/// Standalone library (extracted from the former `connectivity_resolver.dart`
/// `part` chain, Refs #3544 Step 3). This library holds **no module-level
/// mutable state**: callers that want to measure hot-path work construct a
/// [ConnectivityHotPathMetrics] and pass it via the `metrics` parameter of
/// `resolveConnectivity` / `resolveNonGreatPowerConnectivity`. The propagation
/// core increments the supplied instance through its `record*` methods. A null
/// metrics argument disables recording, so the production hot path pays nothing
/// (no allocation, no per-dequeue dispatch beyond a null-aware tear-off).
library;

/// Counters for connectivity hot paths (Refs #2268 AC-10).
///
/// Construct an instance and pass it via the `metrics` parameter of
/// `resolveConnectivity` / `resolveNonGreatPowerConnectivity` to record
/// dequeue counts from tests. The instance is mutated in place by the
/// connectivity propagation core via the `record*` methods below.
class ConnectivityHotPathMetrics {
  int townRuleWorklistDequeues = 0;
  int connectivityBottleneckDequeues = 0;
  int seaZoneBreadthFirstDequeues = 0;

  /// Sum of tile bottleneck propagation dequeues and sea-zone plain BFS dequeues.
  int get connectivityBfsTotalDequeues =>
      connectivityBottleneckDequeues + seaZoneBreadthFirstDequeues;

  /// Increments the town-rule worklist dequeue counter.
  void recordTownRuleWorklistDequeue() => townRuleWorklistDequeues++;

  /// Increments the bottleneck-propagation dequeue counter.
  void recordConnectivityBottleneckDequeue() => connectivityBottleneckDequeues++;

  /// Increments the sea-zone BFS dequeue counter.
  void recordSeaZoneBfsDequeue() => seaZoneBreadthFirstDequeues++;
}
