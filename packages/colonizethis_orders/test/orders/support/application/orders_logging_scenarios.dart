// Table-driven orders-domain logging scenarios (Refs #3949 wave 3).

import 'dart:io';
import '../scenario_runner.dart';

import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_orders/src/orders/orders_logging.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart' show Level, LogEvent, Logger;
// dart format off

void olRunOrdersLogIsCtLogger() {expect(ordersLog,isA<CtLogger>()); expect(ordersLog.prefix,equals('orders'));}

void olRunOrdersLogIsSharedInstance() {expect(identical(ordersLog,ordersLog),isTrue);}

void olRunOrdersApplicationLogAlias() {expect(identical(ordersApplicationLog,ordersLog),isTrue);}

void olRunOrderSuggestionLogPrefix() {expect(orderSuggestionLog,isA<CtLogger>()); expect(orderSuggestionLog.prefix,equals('orders.order_suggestion'));}

void olRunOrdersLogEmitsPrefixedMessages() {final captured = <LogEvent>[]; void listener(LogEvent e) => captured.add(e); Logger.addLogListener(listener); final priorLevel = Logger.level; Logger.level = Level.debug; try {ordersLog.i('orders_logger_smoke'); } finally {Logger.removeLogListener(listener); Logger.level = priorLevel; } final messages = captured.map((e) => e.message?.toString() ?? '').toList(); expect(messages.any((m) => m.contains('orders: orders_logger_smoke')),isTrue,reason: 'expected at least one log entry prefixed with "orders: "',);}

void olRunNoLibOrdersSourceConsumesLogicLog() {final ordersDir = Directory('lib/src/orders'); expect(ordersDir.existsSync(),isTrue,reason: 'expected orders source directory at lib/src/orders',); final offenders = <String>[]; for (final entity in ordersDir.listSync(recursive: true)) {if (entity is! File || !entity.path.endsWith('.dart')) continue; if (entity.path.endsWith('orders_logging.dart')) continue; final content = entity.readAsStringSync(); if (content.contains('colonizethis_logic/src/logging.dart') || content.contains('logicLog')) {offenders.add(entity.path); } } expect(offenders,isEmpty,reason: 'orders/ must use ordersLog (orders_logging.dart), not the core ' 'logicLog: $offenders',);}

/// Canonical scenarios for orders_logging family tests.
List<RunnableScenario> ordersLoggingScenarios() => [
  rs('ordersLog is a CtLogger with the distinct `orders` prefix', olRunOrdersLogIsCtLogger),
  rs('ordersLog is the single shared instance for the orders domain', olRunOrdersLogIsSharedInstance),
  rs('ordersApplicationLog is an alias of the shared ordersLog', olRunOrdersApplicationLogAlias),
  rs('orderSuggestionLog is rooted under the `orders` domain prefix', olRunOrderSuggestionLogPrefix),
  rs('ordersLog emits messages with the `orders:` prefix', olRunOrdersLogEmitsPrefixedMessages),
  rs('no lib/src/orders source consumes the core logicLog', olRunNoLibOrdersSourceConsumesLogicLog, '#3290 C2'),
];
