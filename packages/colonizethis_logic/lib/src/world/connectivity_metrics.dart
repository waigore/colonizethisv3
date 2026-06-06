part of 'connectivity_resolver.dart';

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

void _recordTownRuleWorklistDequeue() {
  _connectivityHotPathMetricsForTests?.townRuleWorklistDequeues++;
}

void _recordConnectivityBottleneckDequeue() {
  _connectivityHotPathMetricsForTests?.connectivityBottleneckDequeues++;
}

void _recordSeaZoneBfsDequeue() {
  _connectivityHotPathMetricsForTests?.seaZoneBreadthFirstDequeues++;
}
