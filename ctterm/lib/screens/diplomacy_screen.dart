// Diplomacy Screen: manage relations with other powers. SPEC/tui/screens/diplomacy.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = log_pkg.Logger();

/// Faction type for display.
enum FactionType { greatPower, minorNation, tribe }

/// Display info for a faction in the diplomacy list.
class FactionDisplayInfo {
  final String id;
  final String name;
  final FactionType type;
  final RelationState? relationState;
  final RelationLevel? relationLevel;
  final int? relationScore;
  final OvertureStage? overtureStage;
  final int? relationLastInteractionTurn;
  /// Great Power power score. Only set for GP rows. SPEC/game/diplomacy.md § Great Power power score.
  final int? powerScore;
  /// Human player's power score for red/green comparison. Only set for GP rows.
  final int? playerPowerScore;

  const FactionDisplayInfo({
    required this.id,
    required this.name,
    required this.type,
    this.relationState,
    this.relationLevel,
    this.relationScore,
    this.overtureStage,
    this.relationLastInteractionTurn,
    this.powerScore,
    this.playerPowerScore,
  });
}

/// Diplomacy screen for managing relations with Great Powers, Minor Nations, and Tribes.
class DiplomacyScreen extends StatefulComponent {
  const DiplomacyScreen({
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
  State<DiplomacyScreen> createState() => _DiplomacyScreenState();
}

class _DiplomacyScreenState extends State<DiplomacyScreen> {
  List<FactionDisplayInfo> _factions = [];
  int _selectedIndex = 0;
  FactionDisplayInfo? _selectedFaction;
  String? _statusMessage;
  bool _isStatusError = false;
  // Intervention choice state
  bool _showIntervention = false;
  final String _interventionMinorId = '';

  // Get the human player's ID
  String get _humanPlayerId {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (entry.value == false) return entry.key;
    }
    // Fallback to first GP
    return component.game.players.isNotEmpty ? component.game.players.first.id : '';
  }

  @override
  void initState() {
    super.initState();
    _loadFactions();
  }

  void _loadFactions() {
    final factions = <FactionDisplayInfo>[];
    final humanId = _humanPlayerId;
    final playerPower = greatPowerPowerScore(component.game, humanId);

    // Add Great Powers (exclude human player from list, show others)
    for (final player in component.game.players) {
      if (player.id == humanId) continue; // Skip self
      
      final relation = _getRelationForFaction(humanId, player.id);
      factions.add(FactionDisplayInfo(
        id: player.id,
        name: player.displayName,
        type: FactionType.greatPower,
        relationState: relation?.state,
        relationLevel: relation?.level,
        relationScore: relation?.score,
        relationLastInteractionTurn: relation?.lastInteractionTurn,
        powerScore: greatPowerPowerScore(component.game, player.id),
        playerPowerScore: playerPower,
      ));
    }

    // Add Minor Nations
    for (final minor in component.game.minorNations) {
      final overture = _getOvertureForMinor(humanId, minor.id);
      final relation = _getRelationForFaction(humanId, minor.id);
      factions.add(FactionDisplayInfo(
        id: minor.id,
        name: minor.displayName ?? minor.id,
        type: FactionType.minorNation,
        relationState: relation?.state,
        relationLevel: relation?.level,
        relationScore: relation?.score,
        overtureStage: overture?.stage,
        relationLastInteractionTurn: relation?.lastInteractionTurn,
      ));
    }

    // Add Tribes
    for (final tribe in component.game.tribes) {
      final overture = _getOvertureForTribe(humanId, tribe.id);
      final relation = _getRelationForFaction(humanId, tribe.id);
      factions.add(FactionDisplayInfo(
        id: tribe.id,
        name: tribe.displayName ?? tribe.id,
        type: FactionType.tribe,
        relationState: relation?.state,
        relationLevel: relation?.level,
        relationScore: relation?.score,
        overtureStage: overture?.stage,
        relationLastInteractionTurn: relation?.lastInteractionTurn,
      ));
    }

    _factions = factions;
    if (_factions.isNotEmpty) {
      _selectedFaction = _factions[_selectedIndex];
    }
  }

  DiplomacyRelation? _getRelationForFaction(String gpId, String targetId) {
    for (final rel in component.game.diplomacyRelations) {
      if ((rel.factionId1 == gpId && rel.factionId2 == targetId) ||
          (rel.factionId1 == targetId && rel.factionId2 == gpId)) {
        return rel;
      }
    }
    return null;
  }

  OvertureState? _getOvertureForMinor(String gpId, String minorId) {
    for (final overture in component.game.overtureStates) {
      if (overture.gpId == gpId && overture.targetId == minorId) {
        return overture;
      }
    }
    return null;
  }

  OvertureState? _getOvertureForTribe(String gpId, String tribeId) {
    for (final overture in component.game.overtureStates) {
      if (overture.gpId == gpId && overture.targetId == tribeId) {
        return overture;
      }
    }
    return null;
  }

  /// Get treasury for the human player.
  int _getTreasury() {
    final humanId = _humanPlayerId;
    for (final player in component.game.players) {
      if (player.id == humanId) {
        return player.treasury;
      }
    }
    return 0;
  }

  /// Handle keyboard input.
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();

    if (_showIntervention) {
      return _handleInterventionKey(key, c);
    }

    // Escape to go back
    if (key == LogicalKey.escape || c == 'b') {
      _log.d('tui:nav: diplomacy -> in-game shell');
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    if (_handleNavigationKey(key, c)) {
      return true;
    }

    return _handleActionKey(c);
  }

  bool _handleInterventionKey(LogicalKey key, String? c) {
    if (c == 'i') {
      _handleIntervention(InterventionChoice.intervene);
      return true;
    }
    if (c == 'o') {
      _handleIntervention(InterventionChoice.doNothing);
      return true;
    }
    if (c == 'r') {
      _handleIntervention(InterventionChoice.protest);
      return true;
    }
    if (key == LogicalKey.escape || c == 'b') {
      setState(() {
        _showIntervention = false;
      });
      return true;
    }
    return false;
  }

  bool _handleNavigationKey(LogicalKey key, String? c) {
    // Navigation keys
    if (key == LogicalKey.arrowUp || c == 'k' || c == 'w') {
      setState(() {
        if (_selectedIndex > 0) {
          _selectedIndex--;
          _selectedFaction = _factions[_selectedIndex];
          _clearStatus();
        }
      });
      return true;
    }

    // Navigation: Use arrow keys, k/w for up, but NOT j/s for down
    // because j=Join Empire (Minor/Tribe) and s=Subsidy (Minor/Tribe)
    // Check if selected faction is eligible for these actions before allowing navigation
    final isNavigationKeyDown = key == LogicalKey.arrowDown;
    final canNavigateWithJ = _selectedFaction != null &&
        (_selectedFaction!.type == FactionType.greatPower ||
            _selectedFaction!.overtureStage != OvertureStage.nap ||
            (_selectedFaction!.relationScore ?? 0) < 51);
    final canNavigateWithS = _selectedFaction != null &&
        _selectedFaction!.type == FactionType.greatPower;

    if (isNavigationKeyDown ||
        (c == 'j' && canNavigateWithJ) ||
        (c == 's' && canNavigateWithS)) {
      setState(() {
        if (_selectedIndex < _factions.length - 1) {
          _selectedIndex++;
          _selectedFaction = _factions[_selectedIndex];
          _clearStatus();
        }
      });
      return true;
    }

    return false;
  }

  bool _handleActionKey(String? c) {
    // Action keys
    if (_selectedFaction == null) return false;

    if (_selectedFaction!.type == FactionType.greatPower) {
      // GP actions: d=declare war, p=offer peace, l=alliance
      if (c == 'd') {
        _handleDeclareWar();
        return true;
      }
      if (c == 'p') {
        _handleOfferPeace();
        return true;
      }
      if (c == 'l') {
        _handleAlliance();
        return true;
      }
    } else {
      // Minor/Tribe actions: d=declare war, p=peace, c=consulate, e=embassy, n=nap,
      // j=join, g=grant aid, s=subsidy
      if (c == 'd') {
        _handleDeclareWar();
        return true;
      }
      if (c == 'p') {
        _handleOfferPeace();
        return true;
      }
      if (c == 'c') {
        _handleEstablishOverture(OvertureStage.tradeConsulate);
        return true;
      }
      if (c == 'e') {
        _handleEstablishOverture(OvertureStage.embassy);
        return true;
      }
      if (c == 'n') {
        _handleEstablishOverture(OvertureStage.nap);
        return true;
      }
      if (c == 'j') {
        _handleJoinEmpire();
        return true;
      }
      if (c == 'g') {
        _handleGrantAid();
        return true;
      }
      if (c == 's') {
        _handleSetSubsidy();
        return true;
      }
    }
    return false;
  }

  void _clearStatus() {
    setState(() {
      _statusMessage = null;
      _isStatusError = false;
    });
  }

  String _formatOvertureStage(OvertureStage? stage) {
    if (stage == null || stage == OvertureStage.none) return 'None';
    switch (stage) {
      case OvertureStage.tradeConsulate: return 'Trade Consulate';
      case OvertureStage.embassy: return 'Embassy';
      case OvertureStage.nap: return 'NAP';
      case OvertureStage.joinEmpire: return 'Join Empire';
      default: return stage.name; // Fallback for any new stages
    }
  }

  void _setStatus(String message, {bool isError = false}) {
    // Workaround for nocterm buffer corruption (issue #953):
    // Force string copy via substring to avoid buffer reuse issues
    final sanitizedMessage = _sanitizeDisplayString(message);
    setState(() {
      _statusMessage = sanitizedMessage;
      _isStatusError = isError;
    });
  }

  /// Sanitizes string for TUI display to work around nocterm buffer corruption.
  /// Creates a new string instance and removes any non-printable characters.
  String _sanitizeDisplayString(String input) {
    // Force a new string allocation via substring
    final freshString = input.substring(0);
    // Remove any characters that might be buffer residue (non-printable or unexpected)
    return freshString.replaceAll(RegExp(r'[^\x20-\x7E£]'), '');
  }

  void _updateSelectedFactionRelationState(RelationState newState) {
    if (_selectedFaction == null || _factions.isEmpty) {
      return;
    }
    setState(() {
      final index = _selectedIndex.clamp(0, _factions.length - 1);
      final current = _factions[index];
      // Update lastInteractionTurn to current turn when relation changes
      final currentTurn = component.game.worldState.turnState.turnNumber;
      final updated = FactionDisplayInfo(
        id: current.id,
        name: current.name,
        type: current.type,
        relationState: newState,
        relationLevel: current.relationLevel,
        relationScore: current.relationScore,
        overtureStage: current.overtureStage,
        relationLastInteractionTurn: currentTurn,
      );
      _factions[index] = updated;
      _selectedFaction = updated;
    });
  }

  void _updateSelectedFactionOvertureStage(OvertureStage newStage) {
    if (_selectedFaction == null || _factions.isEmpty) {
      return;
    }
    setState(() {
      final index = _selectedIndex.clamp(0, _factions.length - 1);
      final current = _factions[index];
      final updated = FactionDisplayInfo(
        id: current.id,
        name: current.name,
        type: current.type,
        relationState: current.relationState,
        relationLevel: current.relationLevel,
        relationScore: current.relationScore,
        overtureStage: newStage,
        relationLastInteractionTurn: current.relationLastInteractionTurn,
      );
      _factions[index] = updated;
      _selectedFaction = updated;
    });
  }

  // Get current orders for human player
  List<DiplomaticOrder> get _diplomaticOrders {
    return component.orders.diplomaticOrdersByPlayerId[_humanPlayerId] ?? [];
  }

  // Add diplomatic order
  void _addDiplomaticOrder(DiplomaticOrder order) {
    final currentOrders = List<DiplomaticOrder>.from(_diplomaticOrders);
    currentOrders.add(order);
    
    final newOrdersByPlayerId = Map<String, List<DiplomaticOrder>>.from(
      component.orders.diplomaticOrdersByPlayerId,
    );
    newOrdersByPlayerId[_humanPlayerId] = currentOrders;
    
    final newOrders = component.orders.copyWith(
      diplomaticOrdersByPlayerId: newOrdersByPlayerId,
    );
    component.onOrdersChanged(newOrders);
  }

  void _handleDeclareWar() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;

    // Validate: must be at peace (or unknown for Minor Nations/Tribes)
    // Great Powers: must be at peace
    // Minor Nations/Tribes: can declare war from any state (including unknown)
    final currentState = _selectedFaction!.relationState;
    if (_selectedFaction!.type == FactionType.greatPower &&
        currentState != RelationState.atPeace) {
      _setStatus('Cannot declare war: not at peace with ${_selectedFaction!.name}', isError: true);
      return;
    }
    // For Minor Nations/Tribes, war declaration is always allowed initially
    // (they start with unknown relation state)

    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: targetId,
    ));
    _updateSelectedFactionRelationState(RelationState.atWar);
    _setStatus('Declared war on ${_selectedFaction!.name}');
    _log.d('tui:diplomacy: declared war on $targetId');
  }

  void _handleOfferPeace() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    
    // Validate: must be at war
    if (_selectedFaction!.relationState != RelationState.atWar) {
      _setStatus('Cannot offer peace: not at war with ${_selectedFaction!.name}', isError: true);
      return;
    }
    
    // Validate: cannot offer peace in same turn as war declaration
    // SPEC: One overture per turn per counterparty faction
    final currentTurn = component.game.worldState.turnState.turnNumber;
    final lastInteractionTurn = _selectedFaction!.relationLastInteractionTurn ?? 0;
    if (lastInteractionTurn == currentTurn) {
      _setStatus('Cannot offer peace: war declared this turn. Wait until next turn.', isError: true);
      return;
    }
    
    // Validate: only one peace offer per turn per faction
    final existingOrders = _diplomaticOrders;
    final alreadyOffered = existingOrders.any((o) =>
        o.type == DiplomaticOrderType.offerPeace && o.targetFactionId == targetId);
    if (alreadyOffered) {
      _setStatus('Peace offer already sent to ${_selectedFaction!.name} this turn', isError: true);
      return;
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: targetId,
    ));
    // Do NOT update UI to AT_PEACE immediately - wait for turn resolution
    // For GP-GP, peace requires mutual agreement
    _setStatus('Peace offer sent to ${_selectedFaction!.name} (pending resolution)');
    _log.d('tui:diplomacy: peace offer sent to $targetId');
  }

  void _handleAlliance() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    final score = _selectedFaction!.relationScore ?? 0;
    
    // Validate: must be at peace and score >= 76
    if (_selectedFaction!.relationState != RelationState.atPeace) {
      _setStatus('Cannot ally: not at peace with ${_selectedFaction!.name}', isError: true);
      return;
    }
    if (score < 76) {
      _setStatus('Cannot ally: relation score $score (need 76+)', isError: true);
      return;
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: targetId,
    ));
    _setStatus('Proposed alliance with ${_selectedFaction!.name}');
    _log.d('tui:diplomacy: proposed alliance with $targetId');
  }

  void _handleEstablishOverture(OvertureStage stage) {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    final currentStage = _selectedFaction!.overtureStage ?? OvertureStage.none;

    // Validate prerequisites
    if (_selectedFaction!.relationState == RelationState.atWar) {
      _setStatus('Cannot establish overture: at war with ${_selectedFaction!.name}', isError: true);
      return;
    }

    // Check if overture stage already exists (prevent duplicates)
    if (currentStage == stage) {
      _setStatus('${_selectedFaction!.name} already has ${stage.name}', isError: true);
      return;
    }

    if (stage == OvertureStage.tradeConsulate && currentStage != OvertureStage.none) {
      _setStatus('${_selectedFaction!.name} already has a Consulate or higher overture', isError: true);
      return;
    }
    if (stage == OvertureStage.embassy && currentStage != OvertureStage.tradeConsulate) {
      _setStatus('Need Consulate first', isError: true);
      return;
    }
    if (stage == OvertureStage.nap && currentStage != OvertureStage.embassy) {
      _setStatus('Need Embassy first', isError: true);
      return;
    }
    
    // Check costs
    int cost = 0;
    if (stage == OvertureStage.tradeConsulate) cost = 500;
    if (stage == OvertureStage.embassy) cost = 1000;
    // NAP is free
    
    if (cost > 0) {
      final treasury = _getTreasury();
      if (treasury < cost) {
        _setStatus('Insufficient funds: need £$cost', isError: true);
        return;
      }
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: targetId,
      overtureStage: stage,
    ));
    // Capture name before update to ensure correct display in status message
    final factionName = _selectedFaction!.name;
    _updateSelectedFactionOvertureStage(stage);
    final stageName = _getOvertureStageDisplayName(stage);
    _setStatus('Established $stageName with $factionName');
    _log.d('tui:diplomacy: established $stage with $targetId');
  }

  String _getOvertureStageDisplayName(OvertureStage stage) {
    switch (stage) {
      case OvertureStage.tradeConsulate:
        return 'Trade Consulate';
      case OvertureStage.embassy:
        return 'Embassy';
      case OvertureStage.nap:
        return 'Non-Aggression Pact';
      case OvertureStage.joinEmpire:
        return 'Empire Join';
      case OvertureStage.none:
        return 'None';
    }
  }

  void _handleJoinEmpire() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    final currentStage = _selectedFaction!.overtureStage ?? OvertureStage.none;
    final score = _selectedFaction!.relationScore ?? 0;
    
    // Validate: need NAP, friendly+ relation
    if (currentStage != OvertureStage.nap) {
      _setStatus('Need NAP first', isError: true);
      return;
    }
    if (score < 51) {
      _setStatus('Need Friendly+ relation (score $score)', isError: true);
      return;
    }
    
    // Calculate cost: 5000 + 2000 per province
    // For MVP, assume 1 province
    const baseCost = 5000;
    const perProvinceCost = 2000;
    final provinceCount = _getProvinceCount(targetId);
    final totalCost = baseCost + (provinceCount * perProvinceCost);
    
    final treasury = _getTreasury();
    if (treasury < totalCost) {
      _setStatus('Insufficient funds: need £$totalCost', isError: true);
      return;
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: targetId,
      overtureStage: OvertureStage.joinEmpire,
    ));
    _setStatus('Joining empire: ${_selectedFaction!.name}');
    _log.d('tui:diplomacy: joining empire with $targetId');
  }

  int _getProvinceCount(String factionId) {
    // Count provinces owned by this faction in old world
    int count = 0;
    for (final province in component.game.worldState.oldWorld.provinces) {
      if (province.ownerId == factionId) count++;
    }
    return count > 0 ? count : 1; // Minimum 1 for cost calculation
  }

  int _getJoinEmpireCost(String factionId) {
    // Calculate cost: 5000 + 2000 per province
    const baseCost = 5000;
    const perProvinceCost = 2000;
    final provinceCount = _getProvinceCount(factionId);
    return baseCost + (provinceCount * perProvinceCost);
  }

  void _handleGrantAid() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    final currentStage = _selectedFaction!.overtureStage ?? OvertureStage.none;
    
    // Validate: need Embassy
    if (currentStage != OvertureStage.embassy && 
        currentStage != OvertureStage.nap &&
        currentStage != OvertureStage.joinEmpire) {
      _setStatus('Need Embassy first', isError: true);
      return;
    }
    
    final aidAmount = grantAidDefaultAmount;
    final treasury = _getTreasury();
    if (treasury < aidAmount) {
      _setStatus('Insufficient funds: need £$aidAmount', isError: true);
      return;
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: targetId,
      amount: aidAmount,
    ));
    _setStatus('Granted £$aidAmount to ${_selectedFaction!.name}');
    _log.d('tui:diplomacy: grant aid $aidAmount to $targetId');
  }

  void _handleSetSubsidy() {
    if (_selectedFaction == null) return;
    final targetId = _selectedFaction!.id;
    final currentStage = _selectedFaction!.overtureStage ?? OvertureStage.none;
    
    // Validate: need Consulate or Embassy
    if (currentStage == OvertureStage.none) {
      _setStatus('Need Consulate or Embassy first', isError: true);
      return;
    }
    
    final subsidyAmount = setSubsidyDefaultAmount;
    final treasury = _getTreasury();
    if (treasury < subsidyAmount) {
      _setStatus('Insufficient funds: need £$subsidyAmount', isError: true);
      return;
    }
    
    _addDiplomaticOrder(DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: targetId,
      amount: subsidyAmount,
    ));
    _setStatus('Set subsidy: £$subsidyAmount to ${_selectedFaction!.name}');
    _log.d('tui:diplomacy: set subsidy $subsidyAmount to $targetId');
  }

  void _handleIntervention(InterventionChoice choice) {
    _log.d('tui:diplomacy: intervention choice $choice for minor $_interventionMinorId');
    setState(() {
      _showIntervention = false;
      _setStatus('Intervention: $choice');
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text('=== DIPLOMACY ==='),
                const SizedBox(width: 2),
                Text('Turn ${component.game.worldState.turnState.turnNumber}', style: TextStyle(color: Colors.gray)),
              ],
            ),
          ),
          const SizedBox(height: 1),
          // Main content
          Expanded(
            child: _showIntervention ? _buildInterventionPanel() : _buildMainContent(),
          ),
          // Status message
          if (_statusMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: _isStatusError ? Colors.red : Colors.green),
              ),
            ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Component _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Faction list
        Expanded(flex: 2, child: _buildFactionList()),
        const SizedBox(width: 1),
        // Detail panel
        Expanded(flex: 3, child: _buildDetailPanel()),
      ],
    );
  }

  Component _buildFactionList() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Factions', style: TextStyle(color: Colors.gray, decoration: TextDecoration.underline)),
          const SizedBox(height: 1),
          Expanded(
            child: _factions.isEmpty
                ? const Text('No factions available')
                : Column(
                    children: _factions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final faction = entry.value;
                      final isSelected = index == _selectedIndex;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            _selectedFaction = faction;
                            _clearStatus();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                          color: isSelected ? Colors.blue.withOpacity(0.3) : null,
                          child: Row(
                            children: [
                              Text(isSelected ? '>' : ' ', style: TextStyle(color: Colors.cyan)),
                              const SizedBox(width: 1),
                              _buildFactionTypeIndicator(faction.type),
                              const SizedBox(width: 1),
                              Expanded(
                                child: Text(
                                  faction.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 1),
                              _buildRelationIndicator(faction),
                              if (faction.powerScore != null) ...[
                                const SizedBox(width: 1),
                                Text(
                                  'P:${faction.powerScore}',
                                  style: TextStyle(
                                    color: faction.playerPowerScore != null &&
                                            faction.powerScore! > faction.playerPowerScore!
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Component _buildFactionTypeIndicator(FactionType type) {
    String text;
    Color color;
    switch (type) {
      case FactionType.greatPower:
        text = 'GP';
        color = Colors.yellow;
        break;
      case FactionType.minorNation:
        text = 'MN';
        color = Colors.green;
        break;
      case FactionType.tribe:
        text = 'TR';
        color = Colors.magenta;
        break;
    }
    return Text(text, style: TextStyle(color: color));
  }

  Component _buildRelationIndicator(FactionDisplayInfo faction) {
    String stateStr = '';
    if (faction.relationState == RelationState.atWar) {
      stateStr = 'WAR';
    } else if (faction.relationState == RelationState.atPeace) {
      stateStr = 'PEACE';
    }
    
    if (faction.type != FactionType.greatPower && faction.overtureStage != null) {
      if (faction.overtureStage != OvertureStage.none) {
        stateStr = faction.overtureStage!.name.substring(0, 3).toUpperCase();
      }
    }
    
    // SPEC/game/diplomacy.md § Player-facing relation display: one-word state from score.
    final displayLabel = faction.relationScore != null
        ? relationScoreToDisplayLabel(faction.relationScore!)
        : null;
    
    Color color;
    if (faction.relationState == RelationState.atWar) {
      color = Colors.red;
    } else if (displayLabel == 'Friendly') {
      color = Colors.green;
    } else if (displayLabel == 'Hostile') {
      color = Colors.red;
    } else if (displayLabel == 'Cordial') {
      color = Colors.cyan;
    } else {
      color = Colors.gray;
    }
    
    return Text(stateStr, style: TextStyle(color: color));
  }

  Component _buildDetailPanel() {
    if (_selectedFaction == null) {
      return Container(
        padding: const EdgeInsets.all(1),
        child: const Text('Select a faction to view details'),
      );
    }

    final faction = _selectedFaction!;
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(faction.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Type: ${faction.type.name}', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          if (faction.type == FactionType.greatPower) ...[
            Text('Relation: ${faction.relationState?.name ?? "unknown"}'),
            Text('State: ${faction.relationScore != null ? relationScoreToDisplayLabel(faction.relationScore!) : "unknown"}'),
            Text(
              'Power: ${faction.powerScore ?? "—"}',
              style: TextStyle(
                color: faction.powerScore != null && faction.playerPowerScore != null &&
                        faction.powerScore! > faction.playerPowerScore!
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ] else ...[
            Text('Relation: ${faction.relationState?.name ?? "unknown"}'),
            Text('State: ${faction.relationScore != null ? relationScoreToDisplayLabel(faction.relationScore!) : "unknown"}'),
            Text('Overture: ${_formatOvertureStage(faction.overtureStage)}'),
          ],
          const SizedBox(height: 1),
          Text('Actions:', style: TextStyle(decoration: TextDecoration.underline)),
          const SizedBox(height: 1),
          if (faction.type == FactionType.greatPower) ...[
            _buildActionHint('d', 'Declare War', faction.relationState == RelationState.atPeace),
            _buildActionHint('p', 'Offer Peace', faction.relationState == RelationState.atWar),
            _buildActionHint('l', 'Alliance', faction.relationState == RelationState.atPeace && (faction.relationScore ?? 0) >= 76),
          ] else ...[
            _buildActionHint('d', 'Declare War', faction.relationState == RelationState.atPeace),
            _buildActionHint('p', 'Offer Peace', faction.relationState == RelationState.atWar),
            _buildActionHint('c', 'Consulate (£500)',
              faction.relationState == RelationState.atPeace && faction.overtureStage == OvertureStage.none),
            _buildActionHint('e', 'Embassy (£1000)',
              faction.relationState == RelationState.atPeace && faction.overtureStage == OvertureStage.tradeConsulate),
            _buildActionHint('n', 'NAP (free)',
              faction.relationState == RelationState.atPeace && faction.overtureStage == OvertureStage.embassy),
            _buildActionHint('j', 'Join Empire (£${_getJoinEmpireCost(faction.id)})',
              faction.relationState == RelationState.atPeace && faction.overtureStage == OvertureStage.nap && (faction.relationScore ?? 0) >= 51),
            _buildActionHint('g', 'Grant Aid (£$grantAidDefaultAmount)',
              faction.overtureStage == OvertureStage.embassy || faction.overtureStage == OvertureStage.nap),
            _buildActionHint('s', 'Set Subsidy (£$setSubsidyDefaultAmount)', 
              faction.overtureStage != null && faction.overtureStage != OvertureStage.none),
          ],
        ],
      ),
    );
  }

  Component _buildActionHint(String key, String action, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Text('[', style: TextStyle(color: enabled ? Colors.cyan : Colors.gray)),
          Text(key, style: TextStyle(color: enabled ? Colors.cyan : Colors.gray)),
          Text('] $action', style: TextStyle(color: enabled ? null : Colors.gray)),
        ],
      ),
    );
  }

  Component _buildInterventionPanel() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('=== INTERVENTION REQUIRED ===', style: TextStyle(color: Colors.yellow)),
          const SizedBox(height: 1),
          const Text('A Minor Nation is under attack!'),
          const SizedBox(height: 1),
          Text('Choose your response:', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          _buildActionHint('i', 'Intervene (enter war with attackers)', true),
          _buildActionHint('o', 'Do Nothing (lose Embassy)', true),
          _buildActionHint('r', 'Diplomatic Protest (penalty to attackers)', true),
          const SizedBox(height: 1),
          _buildActionHint('Esc', 'Cancel', true),
        ],
      ),
    );
  }

  Component _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Row(
        children: [
          Text('[', style: TextStyle(color: Colors.cyan)),
          Text('Esc/B', style: TextStyle(color: Colors.cyan)),
          Text('] Back  '),
          Text('[', style: TextStyle(color: Colors.cyan)),
          Text('j/k', style: TextStyle(color: Colors.cyan)),
          Text('] Navigate'),
        ],
      ),
    );
  }
}
