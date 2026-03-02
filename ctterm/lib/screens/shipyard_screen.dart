// Shipyard Screen: construct naval units. SPEC/tui/screens/shipyard.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = log_pkg.Logger();

/// Display info for a ship type in the Shipyard.
class ShipDisplayInfo {
  final String id;
  final String name;
  final String category;
  final int cost;
  final Map<String, int> inputs;
  final int firepower;
  final int range;
  final int armour;
  final int hull;
  final int movement;
  final int cargoHold;
  final bool isAvailable;

  const ShipDisplayInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.inputs,
    required this.firepower,
    required this.range,
    required this.armour,
    required this.hull,
    required this.movement,
    required this.cargoHold,
    required this.isAvailable,
  });
}

/// Build order display info.
class BuildOrderInfo {
  final String shipTypeId;
  final String shipName;
  final String provinceId;
  final int turnsRemaining;

  const BuildOrderInfo({
    required this.shipTypeId,
    required this.shipName,
    required this.provinceId,
    required this.turnsRemaining,
  });
}

/// Shipyard screen for constructing naval units.
class ShipyardScreen extends StatefulComponent {
  const ShipyardScreen({
    super.key,
    required this.game,
    required this.orders,
    required this.onNavigate,
    required this.onOrdersChanged,
  });

  final Game game;
  final Orders orders;
  final void Function(CttermRoute) onNavigate;
  final void Function(Orders) onOrdersChanged;

  @override
  State<ShipyardScreen> createState() => _ShipyardScreenState();
}

class _ShipyardScreenState extends State<ShipyardScreen> {
  int _selectedIndex = 0;
  String _inputMode = 'none';
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.white;
  String _provinceInput = '';
  bool _showHomeFleet = false;

  String? _getHumanPlayerId() {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    return null;
  }

  Player? _getHumanPlayer() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return null;
    try {
      return component.game.players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  List<ShipDisplayInfo> _getShipList() {
    return const [
      ShipDisplayInfo(id: 'carrack', name: 'Carrack', category: 'Merchant', cost: 80, inputs: {'lumber': 2, 'fabric': 1}, firepower: 2, range: 1, armour: 1, hull: 2, movement: 2, cargoHold: 3, isAvailable: true),
      ShipDisplayInfo(id: 'fluyte', name: 'Fluyte', category: 'Merchant', cost: 60, inputs: {'lumber': 1, 'fabric': 1}, firepower: 1, range: 1, armour: 1, hull: 1, movement: 2, cargoHold: 4, isAvailable: true),
      ShipDisplayInfo(id: 'sloop', name: 'Sloop', category: 'Warship', cost: 50, inputs: {'lumber': 1}, firepower: 1, range: 1, armour: 1, hull: 1, movement: 2, cargoHold: 0, isAvailable: true),
      ShipDisplayInfo(id: 'frigate', name: 'Frigate', category: 'Warship', cost: 100, inputs: {'lumber': 2, 'iron': 1}, firepower: 2, range: 2, armour: 1, hull: 2, movement: 3, cargoHold: 0, isAvailable: true),
    ];
  }

  List<BuildOrderInfo> _getBuildOrders() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    final buildOrders = component.orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final shipNames = {for (final s in _getShipList()) s.id: s.name};
    return buildOrders.where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).map((o) => BuildOrderInfo(shipTypeId: o.unitType, shipName: shipNames[o.unitType] ?? o.unitType, provinceId: o.spawnProvinceId, turnsRemaining: 2)).toList();
  }

  List<Unit> _getHomeFleet() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    return component.game.worldState.oldWorld.units.where((u) => u.ownerId == playerId && ShipEconomyCatalog.byId.containsKey(u.type)).toList();
  }

  List<Province> _getPortProvinces() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    return component.game.worldState.oldWorld.provinces.where((p) => p.ownerId == playerId && p.townDevelopmentLevel >= 1).toList();
  }

  int _getPlayerGold() => _getHumanPlayer()?.treasury ?? 0;

  String _provinceLabel(String fullProvinceId) {
    final world = component.game.worldState;
    for (final p in world.oldWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    for (final p in world.newWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    return fullProvinceId;
  }

  void _issueBuildOrder(String provinceId, ShipDisplayInfo ship) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) { setState(() { _feedbackMessage = 'Error: No human player'; _feedbackColor = Colors.red; }); return; }
    if (!ship.isAvailable) { setState(() { _feedbackMessage = 'Ship not available'; _feedbackColor = Colors.red; }); return; }
    final gold = _getPlayerGold();
    if (gold < ship.cost) { setState(() { _feedbackMessage = 'Insufficient gold: need ${ship.cost}, have $gold'; _feedbackColor = Colors.red; }); return; }
    final hasPort = _getPortProvinces().any((p) => p.id == provinceId);
    if (!hasPort) { setState(() { _feedbackMessage = 'Province has no port'; _feedbackColor = Colors.red; }); return; }
    final newOrder = BuildUnitOrder(unitType: ship.id, isMilitary: false, spawnProvinceId: provinceId);
    final existing = component.orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {...component.orders.buildUnitOrdersByPlayerId, playerId: [...existing, newOrder]},
      workOrdersByPlayerId: component.orders.workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );
    component.onOrdersChanged(newOrders);
    _log.i('tui:shipyard: build order for ${ship.name} in $provinceId');
    setState(() { _inputMode = 'none'; _provinceInput = ''; _feedbackMessage = 'Build order issued'; _feedbackColor = Colors.green; });
  }

  void _cancelBuildOrder(int index) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;
    final existing = component.orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final shipOrders = existing.where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).toList();
    if (index >= shipOrders.length) return;
    final toCancel = shipOrders[index];
    final updated = existing.where((o) => o != toCancel).toList();
    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {...component.orders.buildUnitOrdersByPlayerId, playerId: updated},
      workOrdersByPlayerId: component.orders.workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );
    component.onOrdersChanged(newOrders);
    setState(() { _inputMode = 'none'; _feedbackMessage = 'Order cancelled'; _feedbackColor = Colors.green; });
  }

  bool _handleKeyEvent(dynamic event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    if (key == LogicalKey.escape) {
      if (_inputMode != 'none') { setState(() { _inputMode = 'none'; _provinceInput = ''; _feedbackMessage = ''; }); return true; }
      component.onNavigate(CttermRoute.inGameShell); return true;
    }
    final ships = _getShipList();
    if (ships.isEmpty) return false;
    if (_inputMode == 'province') {
      if (key == LogicalKey.enter) { _issueBuildOrder(_provinceInput, ships[_selectedIndex]); return true; }
      else if (key == LogicalKey.backspace) { setState(() { _provinceInput = _provinceInput.isNotEmpty ? _provinceInput.substring(0, _provinceInput.length - 1) : ''; }); return true; }
      else if (c != null && (c == '|' || (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57))) { setState(() { _provinceInput += c; }); return true; }
      return false;
    }
    if (key == LogicalKey.arrowUp || c == 'k') { setState(() { _selectedIndex = (_selectedIndex - 1).clamp(0, ships.length - 1); _feedbackMessage = ''; }); return true; }
    if (key == LogicalKey.arrowDown || c == 'j') { setState(() { _selectedIndex = (_selectedIndex + 1).clamp(0, ships.length - 1); _feedbackMessage = ''; }); return true; }
    if (c == 'b') { setState(() { _inputMode = 'province'; _provinceInput = ''; _feedbackMessage = 'Enter province ID:'; _feedbackColor = Colors.cyan; }); return true; }
    if (c == 'c') { final orders = _getBuildOrders(); if (orders.isNotEmpty && _selectedIndex < orders.length) _cancelBuildOrder(_selectedIndex); return true; }
    if (c == 'h') { setState(() { _showHomeFleet = !_showHomeFleet; }); return true; }
    return false;
  }

  @override
  Component build(BuildContext context) {
    final ships = _getShipList();
    final buildOrders = _getBuildOrders();
    final homeFleet = _getHomeFleet();
    final ports = _getPortProvinces();
    final selected = ships.isNotEmpty && _selectedIndex < ships.length ? ships[_selectedIndex] : null;
    return KeyboardListener(
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: Colors.black,
        child: Column(children: [
          Container(padding: const EdgeInsets.all(1), color: Colors.blue, child: Row(children: [
            const Text(' Shipyard ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('[b]uild [c]ancel [h]ome [Esc]back', style: TextStyle(color: Colors.grey)),
          ])),
          Expanded(child: Row(children: [
            Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(1), child: Column(children: [
              const Text('Available Ships:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              Expanded(child: ListView(children: [for (var i = 0; i < ships.length; i++) _shipRow(ships[i], i == _selectedIndex)])),
            ]))),
            Container(width: 40, padding: const EdgeInsets.all(1), child: Column(children: [
              const Text('Details:', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              if (selected != null) ...[
                Text(selected.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Category: ${selected.category}', style: const TextStyle(color: Colors.grey)),
                Text('Cost: ${selected.cost}g', style: const TextStyle(color: Colors.white)),
                const Text('Stats:', style: TextStyle(color: Colors.cyan)),
                Text('  FRP:${selected.firepower} RNG:${selected.range}', style: const TextStyle(color: Colors.white)),
                Text('  ARM:${selected.armour} HULL:${selected.hull}', style: const TextStyle(color: Colors.white)),
                Text('  MV:${selected.movement}', style: const TextStyle(color: Colors.white)),
                Text(selected.isAvailable ? '[b]uild' : 'Locked', style: TextStyle(color: selected.isAvailable ? Colors.green : Colors.red)),
              ] else const Text('No selection', style: TextStyle(color: Colors.grey)),
            ])),
            Container(width: 40, padding: const EdgeInsets.all(1), child: Column(children: [
              Text(_showHomeFleet ? 'Home Fleet:' : 'Build Queue:', style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              if (_showHomeFleet) ...[
                if (homeFleet.isEmpty) const Text('No ships', style: TextStyle(color: Colors.grey))
                else ...homeFleet.map((u) => Text(_fmtShip(u.type), style: const TextStyle(color: Colors.white))),
                Text('Ports: ${ports.length}', style: const TextStyle(color: Colors.grey)),
              ] else ...[
              if (buildOrders.isEmpty) const Text('No orders', style: TextStyle(color: Colors.grey))
              else ...buildOrders.asMap().entries.map((e) => Text(
                    '${e.key + 1}.${e.value.shipName}>${_provinceLabel(e.value.provinceId)}',
                    style: TextStyle(
                        color: e.key == _selectedIndex ? Colors.green : Colors.white),
                  )),
              ],
            ])),
          ])),
          Container(padding: const EdgeInsets.all(1), color: Colors.grey, child: Row(children: [
            if (_inputMode == 'province') ...[
              Text(_provinceInput.isEmpty ? 'Province: ' : _provinceInput, style: TextStyle(color: _feedbackColor)),
              const Text('_', style: TextStyle(color: Colors.cyan)),
            ] else Text(_feedbackMessage.isEmpty ? 'arrows/jk b c h' : _feedbackMessage, style: TextStyle(color: _feedbackColor)),
          ])),
        ]),
      ),
    );
  }

  String _fmtShip(String id) => id.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  Component _shipRow(ShipDisplayInfo ship, bool sel) {
    return Container(color: sel ? Colors.blue : Colors.black, padding: const EdgeInsets.all(1), child: Row(children: [
      Text(sel ? '> ' : '  ', style: const TextStyle(color: Colors.cyan)),
      Expanded(child: Text('${ship.name.padRight(10)} ${ship.category.padRight(10)} ${ship.isAvailable?"Avail":"Lock"}', style: TextStyle(color: sel ? Colors.white : (ship.isAvailable ? Colors.green : Colors.red)))),
      Text('${ship.cost}g', style: const TextStyle(color: Colors.yellow)),
    ]));
  }
}
