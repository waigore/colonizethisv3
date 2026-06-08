// Refs #3290 C2 prerequisite — orders-domain logging decoupling.
//
// Pins the contract that the `orders/` source tree uses a dedicated `ordersLog`
// (`CtLogger('orders')`) instead of the thin-core `logicLog`, so the tree can
// move into a future `colonizethis_orders` package without a dependency on the
// `colonizethis_logic` core. Mirrors `setup/setup_logging_test.dart` and
// `package_logger_shared_test.dart`.

import 'dart:io';

import 'package:colonizethis_logic/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_logic/src/orders/orders_application_context.dart';
import 'package:colonizethis_logic/src/orders/orders_logging.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;

void main() {
  group('ordersLog (Refs #3290 C2)', () {
    test('ordersLog is a CtLogger with the distinct `orders` prefix', () {
      expect(ordersLog, isA<CtLogger>());
      expect(ordersLog.prefix, equals('orders'));
    });

    test('ordersLog is the single shared instance for the orders domain', () {
      expect(identical(ordersLog, ordersLog), isTrue);
    });

    test('ordersApplicationLog is an alias of the shared ordersLog', () {
      expect(identical(ordersApplicationLog, ordersLog), isTrue);
    });

    test('orderSuggestionLog is rooted under the `orders` domain prefix', () {
      expect(orderSuggestionLog, isA<CtLogger>());
      expect(orderSuggestionLog.prefix, equals('orders.order_suggestion'));
    });

    test('ordersLog emits messages with the `orders:` prefix', () {
      final captured = <LogEvent>[];
      void listener(LogEvent e) => captured.add(e);
      Logger.addLogListener(listener);
      final priorLevel = Logger.level;
      Logger.level = Level.debug;
      try {
        ordersLog.i('orders_logger_smoke');
      } finally {
        Logger.removeLogListener(listener);
        Logger.level = priorLevel;
      }
      final messages = captured
          .map((e) => e.message?.toString() ?? '')
          .toList();
      expect(
        messages.any((m) => m.contains('orders: orders_logger_smoke')),
        isTrue,
        reason: 'expected at least one log entry prefixed with "orders: "',
      );
    });

    test('no lib/src/orders source consumes the core logicLog', () {
      final ordersDir = Directory('lib/src/orders');
      expect(
        ordersDir.existsSync(),
        isTrue,
        reason: 'expected orders source directory at lib/src/orders',
      );
      final offenders = <String>[];
      for (final entity in ordersDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('orders_logging.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains('colonizethis_logic/src/logging.dart') ||
            content.contains('logicLog')) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'orders/ must use ordersLog (orders_logging.dart), not the core '
            'logicLog: $offenders',
      );
    });
  });
}
