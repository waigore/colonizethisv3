import 'dart:async';

/// Typed narrowing for streams, matching [Iterable.whereType].
///
/// The Dart SDK does not define [Stream.whereType]; event buses use this
/// instead of chaining `.where((e) => e is T).map((e) => e as T)`.
extension CtStreamWhereType<S> on Stream<S> {
  Stream<T> whereType<T extends S>() {
    return transform(
      StreamTransformer<S, T>.fromHandlers(
        handleData: (data, sink) {
          if (data is T) {
            sink.add(data);
          }
        },
      ),
    );
  }
}
