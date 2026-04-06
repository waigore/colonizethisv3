import 'dart:async';

/// Tracks stream subscriptions for predictable batch cleanup.
class SubscriptionTracker {
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  T track<T extends StreamSubscription<dynamic>>(T subscription) {
    _subscriptions.add(subscription);
    return subscription;
  }

  void cancelAll() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
