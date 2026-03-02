// Production Screen: manage resource extraction, stockpile, and production. SPEC/tui/screens/production.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Production recipe definition for display.
class ProductionRecipe {
  final String id;
  final String name;
  final Map<String, int> inputs;
  final Map<String, int> outputs;
  final int labourRequired;

  const ProductionRecipe({
    required this.id,
    required this.name,
    required this.inputs,
    required this.outputs,
    required this.labourRequired,
  });
}

/// Extraction tile info for display.
class ExtractionTileInfo {
  final String tileKey;
  final String provinceId;
  final String? regionId;
  final String resource;
  final int improvementLevel;
  final int roadLevel;
  final int yieldPerTurn;

  const ExtractionTileInfo({
    required this.tileKey,
    required this.provinceId,
    this.regionId,
    required this.resource,
    required this.improvementLevel,
    required this.roadLevel,
    required this.yieldPerTurn,
  });
}

/// MVP production recipes (program-level constants per spec).
const _productionRecipes = [
  ProductionRecipe(
    id: 'timber_to_lumber',
    name: 'Timber to Lumber',
    inputs: {'timber': 2},
    outputs: {'lumber': 1},
    labourRequired: 2,
  ),
  ProductionRecipe(
    id: 'iron_to_cast_iron',
    name: 'Iron + Coal to Cast Iron',
    inputs: {'iron': 2, 'coal': 1},
    outputs: {'castIron': 1},
    labourRequired: 3,
  ),
  ProductionRecipe(
    id: 'wool_to_fabric',
    name: 'Wool to Fabric',
    inputs: {'wool': 2},
    outputs: {'fabric': 1},
    labourRequired: 2,
  ),
  ProductionRecipe(
    id: 'cotton_to_fabric',
    name: 'Cotton to Fabric',
    inputs: {'cotton': 2},
    outputs: {'fabric': 1},
    labourRequired: 2,
  ),
  ProductionRecipe(
    id: 'sugar_cane_to_refined_sugar',
    name: 'Sugar Cane to Refined Sugar',
    inputs: {'sugarCane': 2},
    outputs: {'refinedSugar': 1},
    labourRequired: 2,
  ),
  ProductionRecipe(
    id: 'tobacco_to_cigars',
    name: 'Tobacco to Cigars',
    inputs: {'tobacco': 2},
    outputs: {'cigars': 1},
    labourRequired: 3,
  ),
  ProductionRecipe(
    id: 'furs_to_fur_hats',
    name: 'Furs to Fur Hats',
    inputs: {'furs': 2},
    outputs: {'furHats': 1},
    labourRequired: 3,
  ),
  ProductionRecipe(
    id: 'iron_coal_to_steel',
    name: 'Iron + Coal to Steel',
    inputs: {'iron': 2, 'coal': 2},
    outputs: {'steel': 1},
    labourRequired: 4,
  ),
  ProductionRecipe(
    id: 'copper_tin_to_bronze',
    name: 'Copper + Tin to Bronze',
    inputs: {'copper': 1, 'tin': 1},
    outputs: {'bronze': 1},
    labourRequired: 2,
  ),
];

/// Default commodity list from SPEC/game/commodity-catalog.md.
const _defaultCommodities = [
  // Food
  'grain', 'meat',
  // Raw materials
  'timber', 'iron', 'wool', 'cotton', 'coal', 'copper', 'tin',
  'sugarCane', 'tobacco', 'furs', 'horses',
  // Manufactured
  'lumber', 'castIron', 'fabric', 'refinedSugar', 'cigars',
  'furHats', 'steel', 'paper', 'bronze',
  // Riches
  'gold', 'silver', 'gems', 'diamonds',
  // Advanced
  'spices',
];

/// Production screen for managing resource extraction, stockpile, and production.
class ProductionScreen extends StatefulComponent {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.onNavigate,
  });

  /// Current game state (required for stockpile and province data).
  final Game game;
  final void Function(CttermRoute) onNavigate;

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  /// Currently selected panel: 'extraction', 'stockpile', 'production'.
  String _selectedPanel = 'stockpile';
  
  /// Selected index within the current panel.
  int _selectedIndex = 0;
  
  /// Currently active production recipes (by recipe id).
  final Set<String> _activeRecipes = {};
  
  /// Feedback message to display.
  String _feedbackMessage = '';
  
  /// Color for feedback message.
  Color _feedbackColor = const Color(0xFFFFFFFF);

  /// Get the human player's ID (non-AI controlled).
  String? _getHumanPlayerId() {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    // Fallback: first player
    return component.game.players.isNotEmpty ? component.game.players.first.id : null;
  }

  /// Get the human player's data.
  Player? _getHumanPlayer() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return null;
    return component.game.players.where((p) => p.id == playerId).firstOrNull;
  }

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

  /// Get extraction tiles for the player's provinces.
  List<ExtractionTileInfo> _getExtractionTiles() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];

    final tiles = <ExtractionTileInfo>[];
    final worldState = component.game.worldState;
    final tileState = worldState.tileState;

    // Get all provinces the player owns in both worlds
    for (final world in [worldState.oldWorld, worldState.newWorld]) {
      for (final province in world.provinces) {
        if (province.ownerId != playerId) continue;
        if (province.townTileKey == null) continue;

        // Get tile key and coordinates
        final tileKey = province.townTileKey!;
        final parts = tileKey.split('|');
        final regionId = parts.isNotEmpty ? parts[0] : null;
        
        // Get tile improvement and road level from tile state
        final improvement = tileState.improvementLevel(tileKey);
        final roadLevel = tileState.roadLevel(tileKey);
        
        // Calculate yield per turn (simplified: min of improvement, town dev, 1)
        // Per spec: min(improvement, tech cap, transport, town development)
        final townDev = province.townDevelopmentLevel;
        final transportCap = roadLevel > 0 ? roadLevel : 1;
        final yieldAmount = [improvement, townDev, transportCap].reduce((a, b) => a < b ? a : b);
        
        // Determine resource type from tile key (simplified - would need ruleset)
        // For MVP, derive from tile position
        final coords = parts.length >= 4 ? parts.sublist(1) : <String>['', '', ''];
        
        tiles.add(ExtractionTileInfo(
          tileKey: tileKey,
          provinceId: province.id,
          regionId: regionId,
          resource: _deriveResourceType(tileKey, coords),
          improvementLevel: improvement,
          roadLevel: roadLevel,
          yieldPerTurn: yieldAmount > 0 ? yieldAmount : 1,
        ));
      }
    }

    return tiles;
  }

  /// Derive resource type from tile key (simplified for MVP).
  String _deriveResourceType(String tileKey, List<String> coords) {
    // Simplified: use hash of tile key to pick a resource
    final hash = tileKey.hashCode.abs();
    final resources = <String>['timber', 'iron', 'coal', 'wool', 'cotton', 'grain', 'furs', 'horses'];
    return resources[hash % resources.length];
  }

  /// Get total extraction by commodity.
  Map<String, int> _getExtractionTotals() {
    final tiles = _getExtractionTiles();
    final totals = <String, int>{};
    for (final tile in tiles) {
      totals[tile.resource] = (totals[tile.resource] ?? 0) + tile.yieldPerTurn;
    }
    return totals;
  }

  /// Check if a recipe can be activated (has enough inputs and labour).
  (bool canActivate, String reason) _canActivateRecipe(ProductionRecipe recipe) {
    final player = _getHumanPlayer();
    if (player == null) return (false, 'No player');

    // Check input commodities
    for (final entry in recipe.inputs.entries) {
      final available = player.stockpile.quantityOf(entry.key);
      if (available < entry.value) {
        return (false, 'Need ${entry.value} ${entry.key}, have $available');
      }
    }

    // Check labour availability
    final availableLabour = player.workerPool.totalWorkers;
    if (availableLabour < recipe.labourRequired) {
      return (false, 'Need ${recipe.labourRequired} labour, have $availableLabour');
    }

    return (true, 'Ready to produce');
  }

  /// Activate a production recipe.
  void _activateRecipe(ProductionRecipe recipe) {
    final (canActivate, reason) = _canActivateRecipe(recipe);
    if (!canActivate) {
      setState(() {
        _feedbackMessage = 'Cannot activate: $reason';
        _feedbackColor = const Color(0xFFFF6666);
      });
      return;
    }

    setState(() {
      _activeRecipes.add(recipe.id);
      _feedbackMessage = '${recipe.name} activated';
      _feedbackColor = const Color(0xFF66FF66);
    });
  }

  /// Deactivate a production recipe.
  void _deactivateRecipe(ProductionRecipe recipe) {
    setState(() {
      _activeRecipes.remove(recipe.id);
      _feedbackMessage = '${recipe.name} deactivated';
      _feedbackColor = const Color(0xFFFFFF66);
    });
  }

  /// Handle keyboard input.
  // Type is inferred from Nocterm's Focusable.onKeyEvent callback
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();

    // Escape: back to shell
    if (key == LogicalKey.escape) {
      _log.d('tui:nav: Production -> shell');
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    // Arrow keys / j/k: navigate within panel
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() {
        int maxIndex;
        if (_selectedPanel == 'extraction') {
          maxIndex = _getExtractionTiles().length - 1;
        } else if (_selectedPanel == 'stockpile') {
          maxIndex = _defaultCommodities.length - 1;
        } else {
          maxIndex = _productionRecipes.length - 1;
        }
        _selectedIndex = (_selectedIndex + 1).clamp(0, maxIndex);
      });
      return true;
    }
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, 999);
      });
      return true;
    }

    // Tab: switch panels
    if (key == LogicalKey.tab && !event.isShiftPressed) {
      setState(() {
        if (_selectedPanel == 'extraction') {
          _selectedPanel = 'stockpile';
        } else if (_selectedPanel == 'stockpile') {
          _selectedPanel = 'production';
        } else {
          _selectedPanel = 'extraction';
        }
        _selectedIndex = 0;
      });
      return true;
    }
    if (key == LogicalKey.tab && event.isShiftPressed) {
      setState(() {
        if (_selectedPanel == 'extraction') {
          _selectedPanel = 'production';
        } else if (_selectedPanel == 'stockpile') {
          _selectedPanel = 'extraction';
        } else {
          _selectedPanel = 'stockpile';
        }
        _selectedIndex = 0;
      });
      return true;
    }

    // Enter/Space: select recipe (in production panel)
    if (_selectedPanel == 'production' && 
        (key == LogicalKey.enter || key == LogicalKey.space)) {
      final recipes = _productionRecipes;
      if (_selectedIndex < recipes.length) {
        final recipe = recipes[_selectedIndex];
        if (_activeRecipes.contains(recipe.id)) {
          _deactivateRecipe(recipe);
        } else {
          _activateRecipe(recipe);
        }
      }
      return true;
    }

    // a: activate selected recipe
    if (_selectedPanel == 'production' && c == 'a') {
      final recipes = _productionRecipes;
      if (_selectedIndex < recipes.length) {
        final recipe = recipes[_selectedIndex];
        if (!_activeRecipes.contains(recipe.id)) {
          _activateRecipe(recipe);
        }
      }
      return true;
    }

    // d: deactivate selected recipe
    if (_selectedPanel == 'production' && c == 'd') {
      final recipes = _productionRecipes;
      if (_selectedIndex < recipes.length) {
        final recipe = recipes[_selectedIndex];
        if (_activeRecipes.contains(recipe.id)) {
          _deactivateRecipe(recipe);
        }
      }
      return true;
    }
    
    return false;
  }

  @override
  Component build(BuildContext context) {
    final player = _getHumanPlayer();
    final extractionTiles = _getExtractionTiles();
    final extractionTotals = _getExtractionTotals();

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with panel tabs
          Container(
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  ' Production ',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' | ', style: TextStyle(color: Color(0xFF888888))),
                _buildPanelTab('extraction', 'Extraction'),
                const Text(' | ', style: TextStyle(color: Color(0xFF888888))),
                _buildPanelTab('stockpile', 'Stockpile'),
                const Text(' | ', style: TextStyle(color: Color(0xFF888888))),
                _buildPanelTab('production', 'Production'),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _selectedPanel == 'extraction'
                ? _buildExtractionPanel(extractionTiles)
                : _selectedPanel == 'stockpile'
                    ? _buildStockpilePanel(player)
                    : _buildProductionPanel(player),
          ),
          // Feedback message
          if (_feedbackMessage.isNotEmpty)
            Container(
              color: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                ' ${_feedbackMessage}',
                style: TextStyle(color: _feedbackColor),
              ),
            ),
          // Worker pool summary
          _buildWorkerPoolSummary(player),
          // Extraction summary
          _buildExtractionSummary(extractionTiles, extractionTotals),
          // Help line
          Container(
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: const Text(
              ' Up/Down/j/k: navigate | Tab: switch panel | a: activate | d: deactivate | Esc: back ',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildPanelTab(String panel, String label) {
    final isSelected = _selectedPanel == panel;
    return Text(
      isSelected ? '[${label[0]}]${label.substring(1)}' : ' ${label} ',
      style: TextStyle(
        color: isSelected ? const Color(0xFF00FFFF) : const Color(0xFF888888),
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Component _buildExtractionPanel(List<ExtractionTileInfo> tiles) {
    if (tiles.isEmpty) {
      return const Center(
        child: Text(
          'No extraction tiles (no owned provinces with towns)',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            color: const Color(0xFF1a1a2e),
            child: const Text(
              ' CONNECTED EXTRACTION TILES ',
              style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                final isSelected = _selectedPanel == 'extraction' && _selectedIndex == index;
                final bg = isSelected ? const Color(0xFF2a2a4e) : null;
                final fg = isSelected ? const Color(0xFFFFFFFF) : const Color(0xFFAAAAAA);
                
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Text(
                    '  ${_provinceLabel(tile.provinceId)}: ${tile.resource} (imp:${tile.improvementLevel}, road:${tile.roadLevel}) -> +${tile.yieldPerTurn}/turn',
                    style: TextStyle(color: fg),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Component _buildStockpilePanel(Player? player) {
    if (player == null) {
      return const Center(
        child: Text(
          'No player data',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }

    final stockpile = player.stockpile;
    return Container(
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            color: const Color(0xFF1a1a2e),
            child: const Text(
              ' STOCKPILE ',
              style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _defaultCommodities.length,
              itemBuilder: (context, index) {
                final commodity = _defaultCommodities[index];
                final quantity = stockpile.quantityOf(commodity);
                final isSelected = _selectedPanel == 'stockpile' && _selectedIndex == index;
                final isZero = quantity == 0;
                final bg = isSelected ? const Color(0xFF2a2a4e) : null;
                final fg = isSelected 
                    ? const Color(0xFFFFFFFF) 
                    : (isZero ? const Color(0xFFFF6666) : const Color(0xFFAAAAAA));
                
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Text(
                    '  $commodity: $quantity',
                    style: TextStyle(color: fg),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Component _buildProductionPanel(Player? player) {
    if (player == null) {
      return const Center(
        child: Text(
          'No player data',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            color: const Color(0xFF1a1a2e),
            child: const Text(
              ' PRODUCTION RECIPES ',
              style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _productionRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _productionRecipes[index];
                final isActive = _activeRecipes.contains(recipe.id);
                final isSelected = _selectedPanel == 'production' && _selectedIndex == index;
                final (canActivate, _) = _canActivateRecipe(recipe);
                
                final inputStr = recipe.inputs.entries
                    .map((e) => '${e.value} ${e.key}')
                    .join(', ');
                final outputStr = recipe.outputs.entries
                    .map((e) => '${e.value} ${e.key}')
                    .join(', ');

                final bg = isSelected ? const Color(0xFF2a2a4e) : null;
                final fg = isSelected 
                    ? const Color(0xFFFFFFFF) 
                    : (isActive 
                        ? const Color(0xFF66FF66) 
                        : (canActivate ? const Color(0xFFAAAAAA) : const Color(0xFFFF6666)));
                
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Text(
                    '  ${isActive ? "[*] " : "[ ] "}${recipe.name}: $inputStr -> $outputStr (labour: ${recipe.labourRequired})${!canActivate ? " (N/A)" : ""}',
                    style: TextStyle(color: fg),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Component _buildWorkerPoolSummary(Player? player) {
    if (player == null) {
      return const Text('Worker Pool: N/A');
    }

    final wp = player.workerPool;
    final total = wp.totalWorkers;
    // For MVP, assume all workers are idle (extraction assignment is a stub)
    const extractionWorkers = 0;
    final productionWorkers = _activeRecipes.length * 2; // Approximate
    final idleWorkers = total - extractionWorkers - productionWorkers;

    return Container(
      color: const Color(0xFF0d0d1a),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Text(
        ' Workers: $total total, $extractionWorkers extraction, $productionWorkers production, $idleWorkers idle',
        style: const TextStyle(color: Color(0xFFAAAAAA)),
      ),
    );
  }

  Component _buildExtractionSummary(List<ExtractionTileInfo> tiles, Map<String, int> totals) {
    final tileCount = tiles.length;
    final landTotal = totals.entries.fold(0, (sum, e) => sum + e.value);
    // Simplified: no overseas extraction in MVP
    const overseasTotal = 0;

    return Container(
      color: const Color(0xFF0d0d1a),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Text(
        ' Extraction: $tileCount tiles, $landTotal land, $overseasTotal overseas',
        style: const TextStyle(color: Color(0xFFAAAAAA)),
      ),
    );
  }
}
