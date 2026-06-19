/// Connectivity hot-path counters and the test-only recording hook.
///
/// Standalone library (extracted from the former `connectivity_resolver.dart`
/// `part` chain, Refs #3544 Step 3). The mutable counter container
/// [ConnectivityHotPathMetrics] is encapsulated here; the only module-level
/// mutable state ([_connectivityHotPathMetricsForTests]) is private to this
/// library and reachable solely through the public `record*`/`set*` functions
/// below, so the standalone `connectivity_propagation.dart` core records via
/// these functions rather than reaching into another library's privates.
library;

/// Counters for connectivity hot paths (Refs #2268 AC-10); used with
/// [setConnectivityHotPathMetricsForTests] from tests only.
class ConnectivityHotPathMetrics {
  int townRuleWorklistDequeues = 0;
  int connectivityBottleneckDequeues = 0;
  int seaZoneBreadthFirstDequeues = 0;

  /// Sum of tile bottleneck propagation dequeues and sea-zone plain BFS dequeues.
  int get connectivityBfsTotalDequeues =>
      connectivityBottleneckDequeues + seaZoneBreadthFirstDequeues;
}

ConnectivityHotPathMetrics? _connectivityHotPathMetricsForTests;

/// When non-null, connectivity resolution increments [metrics] (test hook).
void setConnectivityHotPathMetricsForTests(
  ConnectivityHotPathMetrics? metrics,
) {
  _connectivityHotPathMetricsForTests = metrics;
}

/// Increments the town-rule worklist dequeue counter when a test hook is active.
void recordTownRuleWorklistDequeue() {
  _connectivityHotPathMetricsForTests?.townRuleWorklistDequeues++;
}

/// Increments the bottleneck-propagation dequeue counter when a test hook is active.
void recordConnectivityBottleneckDequeue() {
  _connectivityHotPathMetricsForTests?.connectivityBottleneckDequeues++;
}

/// Increments the sea-zone BFS dequeue counter when a test hook is active.
void recordSeaZoneBfsDequeue() {
  _connectivityHotPathMetricsForTests?.seaZoneBreadthFirstDequeues++;
}
