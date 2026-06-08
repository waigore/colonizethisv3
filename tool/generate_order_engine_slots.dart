import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Emits [order_engine.g.dart] from [order_engine_manifest.yaml].
///
/// SPEC: SPEC/program/order-engine.md — Code generation (OrderEngine slots)
void main() {
  final repoRoot = Directory.current.path;
  final manifestFile = File(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_orders',
      'lib',
      'src',
      'orders',
      'order_engine_manifest.yaml',
    ),
  );
  final ordersModelFile = File(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_models',
      'lib',
      'src',
      'orders.dart',
    ),
  );
  final outFile = File(
    p.join(
      repoRoot,
      'packages',
      'colonizethis_orders',
      'lib',
      'src',
      'orders',
      'order_engine.g.dart',
    ),
  );

  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing manifest: ${manifestFile.path}');
    exitCode = 1;
    return;
  }
  if (!ordersModelFile.existsSync()) {
    stderr.writeln('Missing Orders model: ${ordersModelFile.path}');
    exitCode = 1;
    return;
  }

  final doc = loadYamlDocument(manifestFile.readAsStringSync());
  final root = doc.contents;
  if (root is! YamlMap) {
    stderr.writeln('Manifest root must be a map');
    exitCode = 1;
    return;
  }

  final engineRaw = root['engine_slots'];
  if (engineRaw is! YamlList) {
    stderr.writeln('engine_slots must be a list');
    exitCode = 1;
    return;
  }

  final storageRaw = root['storage_only'];
  if (storageRaw is! YamlList) {
    stderr.writeln('storage_only must be a list');
    exitCode = 1;
    return;
  }

  final slots = <_EngineSlot>[];
  for (final item in engineRaw) {
    if (item is! YamlMap) continue;
    slots.add(_EngineSlot.fromYaml(item));
  }

  final storageOnly = <_StorageField>[];
  for (final item in storageRaw) {
    if (item is! YamlMap) continue;
    storageOnly.add(_StorageField.fromYaml(item));
  }

  final ordersFieldNames = _ordersMapFields(ordersModelFile.readAsStringSync());
  final manifestFields = <String>{
    ...slots.map((s) => s.ordersField),
    ...storageOnly.map((s) => s.ordersField),
  };
  if (manifestFields.length != slots.length + storageOnly.length) {
    stderr.writeln('Duplicate orders_field in manifest');
    exitCode = 1;
    return;
  }
  if (manifestFields.length != ordersFieldNames.length ||
      !manifestFields.containsAll(ordersFieldNames) ||
      !ordersFieldNames.containsAll(manifestFields)) {
    stderr.writeln(
      'Manifest fields do not match Orders map fields.\n'
      '  orders.dart: ${ordersFieldNames.toList()..sort()}\n'
      '  manifest:    ${manifestFields.toList()..sort()}',
    );
    exitCode = 1;
    return;
  }

  final sink = StringBuffer();
  sink.writeln('// GENERATED FILE — do not edit by hand.');
  sink.writeln('// Run: dart run tool/generate_order_engine_slots.dart');
  sink.writeln('// Source: order_engine_manifest.yaml');
  sink.writeln();
  sink.writeln("part of 'order_engine.dart';");
  sink.writeln();

  for (final s in slots) {
    final getter = '_orderEngineGet${s.orderType}';
    final updater = '_orderEngineWith${s.orderType}';
    sink.writeln(
      'Map<String, List<${s.orderType}>> $getter(Orders o) => '
      'o.${s.ordersField};',
    );
    sink.writeln();
    sink.writeln(
      'Orders $updater(Orders o, Map<String, List<${s.orderType}>> m) => '
      'o.copyWith(${s.copyWithParam}: m);',
    );
    sink.writeln();
    final slotConst = '_orderSlot${s.orderType}';
    sink.writeln(
      'const $slotConst = _OrderSlot<${s.orderType}>(\n'
      '  getter: $getter,\n'
      '  updater: $updater,\n'
      "  label: '${_escapeString(s.logLabel)}',\n"
      ');',
    );
    sink.writeln();
  }

  sink.writeln('Orders copyInitialOrdersForEngine(Orders initialOrders) =>');
  sink.writeln('    Orders(');
  for (final s in slots) {
    sink.writeln(
      '      ${s.ordersField}: _copyMapOfOrderLists('
      'initialOrders.${s.ordersField}),',
    );
  }
  for (final s in storageOnly) {
    sink.writeln(
      '      ${s.ordersField}: _copyMapOfOrderLists('
      'initialOrders.${s.ordersField}),',
    );
  }
  sink.writeln('    );');
  sink.writeln();

  sink.writeln('Orders copyOrdersSnapshotForEngine(Orders o) =>');
  sink.writeln('    Orders(');
  for (final s in slots) {
    sink.writeln(
      '      ${s.ordersField}: _copyMapOfOrderLists(o.${s.ordersField}),',
    );
  }
  for (final s in storageOnly) {
    sink.writeln(
      '      ${s.ordersField}: _copyMapOfOrderLists(o.${s.ordersField}),',
    );
  }
  sink.writeln('    );');
  sink.writeln();

  // No `on OrderEngine` — that would be circular with `class OrderEngine with ...`.
  sink.writeln('mixin _OrderEngineGeneratedOrderMethods {');
  for (final s in slots) {
    final slotConst = '_orderSlot${s.orderType}';
    sink.writeln(
      '  OrderValidationResult ${s.addMethod}(String playerId, '
      '${s.orderType} order) =>\n'
      '      (this as OrderEngine).addOrderForSlot(playerId, order, $slotConst);',
    );
    sink.writeln();
    sink.writeln(
      '  OrderValidationResult ${s.addWithContextMethod}(\n'
      '    Game game,\n'
      '    MapTopology topology,\n'
      '    String playerId,\n'
      '    ${s.orderType} order, {\n'
      '    Map<String, TileMapResult>? tileMapByRegion,\n'
      '  }) => (this as OrderEngine).addOrderForSlotWithContext(\n'
      '    game,\n'
      '    topology,\n'
      '    playerId,\n'
      '    order,\n'
      '    $slotConst,\n'
      '    tileMapByRegion: tileMapByRegion,\n'
      '  );',
    );
    sink.writeln();
    sink.writeln(
      '  void ${s.removeMethod}(String playerId, int index) =>\n'
      '      (this as OrderEngine).removeOrderForSlot(playerId, index, $slotConst);',
    );
    sink.writeln();
  }
  sink.writeln('}');

  final formatted = _trimTrailingBlankLines(sink.toString());
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('$formatted\n');
}

String _escapeString(String s) =>
    s.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

String _trimTrailingBlankLines(String s) {
  var t = s;
  while (t.endsWith('\n\n')) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}

final _ordersMapFieldRe = RegExp(
  r'final Map<String, List<[^>]+>> (\w+);',
  multiLine: true,
);

Set<String> _ordersMapFields(String ordersDartSource) {
  final names = <String>{};
  for (final m in _ordersMapFieldRe.allMatches(ordersDartSource)) {
    names.add(m.group(1)!);
  }
  return names;
}

class _EngineSlot {
  _EngineSlot({
    required this.orderType,
    required this.ordersField,
    required this.copyWithParam,
    required this.logLabel,
    required this.addMethod,
    required this.addWithContextMethod,
    required this.removeMethod,
  });

  factory _EngineSlot.fromYaml(YamlMap m) {
    String req(String k) {
      final v = m[k];
      if (v is! String || v.isEmpty) {
        throw FormatException('Missing or invalid string: $k');
      }
      return v;
    }

    return _EngineSlot(
      orderType: req('order_type'),
      ordersField: req('orders_field'),
      copyWithParam: req('copy_with_param'),
      logLabel: req('log_label'),
      addMethod: req('add_method'),
      addWithContextMethod: req('add_with_context_method'),
      removeMethod: req('remove_method'),
    );
  }

  final String orderType;
  final String ordersField;
  final String copyWithParam;
  final String logLabel;
  final String addMethod;
  final String addWithContextMethod;
  final String removeMethod;
}

class _StorageField {
  _StorageField({required this.ordersField, required this.copyWithParam});

  factory _StorageField.fromYaml(YamlMap m) {
    String req(String k) {
      final v = m[k];
      if (v is! String || v.isEmpty) {
        throw FormatException('Missing or invalid string: $k');
      }
      return v;
    }

    return _StorageField(
      ordersField: req('orders_field'),
      copyWithParam: req('copy_with_param'),
    );
  }

  final String ordersField;
  final String copyWithParam;
}
