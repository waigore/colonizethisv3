/// Full tech catalog (113 techs). SPEC/game/tech-tree.md and category sub-docs.
/// Imported by tech_extraction.dart. Do not export; use colonizethis_data public API.

import 'tech_definition.dart';

int _cost(int era) => 80 + era * 40; // 120, 160, 200, 240 for era 1-4

/// Full catalog: 113 techs with displayName, prerequisiteIds, discoveryResourceIds (7 discovery techs), regimentUnlockIds, shipUnlockIds.
Map<String, TechDefinition> buildTechCatalog() {
  final m = <String, TechDefinition>{};

  // --- Gathering (26) ---
  m['crop_rotation'] = TechDefinition(id: 'crop_rotation', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Crop Rotation');
  m['saw_mill'] = TechDefinition(id: 'saw_mill', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Saw Mill');
  m['land_enclosure'] = TechDefinition(id: 'land_enclosure', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Land Enclosure');
  m['mine_engineering'] = TechDefinition(id: 'mine_engineering', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Mine Engineering');
  m['iron_mining'] = TechDefinition(id: 'iron_mining', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Iron Mining', prerequisiteIds: ['mine_engineering']);
  m['copper_and_tin_mining'] = TechDefinition(id: 'copper_and_tin_mining', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Copper and Tin Mining', prerequisiteIds: ['mine_engineering']);
  m['coal_mining'] = TechDefinition(id: 'coal_mining', era: 1, category: 'gathering', cost: _cost(1), displayName: 'Coal Mining', prerequisiteIds: ['mine_engineering']);
  m['wind_saw_mill'] = TechDefinition(id: 'wind_saw_mill', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Wind Saw Mill', prerequisiteIds: ['saw_mill']);
  m['seed_drill'] = TechDefinition(id: 'seed_drill', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Seed Drill', prerequisiteIds: ['land_enclosure']);
  m['sheep_ranching'] = TechDefinition(id: 'sheep_ranching', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Sheep Ranching', prerequisiteIds: ['crop_rotation']);
  m['animal_husbandry'] = TechDefinition(id: 'animal_husbandry', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Animal Husbandry', prerequisiteIds: ['crop_rotation']);
  m['square_set_timbering'] = TechDefinition(id: 'square_set_timbering', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Square-set Timbering', prerequisiteIds: ['coal_mining']);
  m['steam_in_mining'] = TechDefinition(id: 'steam_in_mining', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Steam in Mining', prerequisiteIds: ['iron_mining']);
  m['large_coal_mines'] = TechDefinition(id: 'large_coal_mines', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Large Coal Mines', prerequisiteIds: ['square_set_timbering', 'steam_in_mining']);
  m['large_copper_and_tin_mines'] = TechDefinition(id: 'large_copper_and_tin_mines', era: 2, category: 'gathering', cost: _cost(2), displayName: 'Large Copper and Tin Mines', prerequisiteIds: ['copper_and_tin_mining']);
  m['circular_saw'] = TechDefinition(id: 'circular_saw', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Circular Saw', prerequisiteIds: ['wind_saw_mill', 'university']);
  m['scientific_sheep_breeding'] = TechDefinition(id: 'scientific_sheep_breeding', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Scientific Sheep Breeding', prerequisiteIds: ['sheep_ranching', 'university']);
  m['scientific_cattle_breeding'] = TechDefinition(id: 'scientific_cattle_breeding', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Scientific Cattle Breeding', prerequisiteIds: ['animal_husbandry', 'university']);
  m['moldboard_plow'] = TechDefinition(id: 'moldboard_plow', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Moldboard Plow', prerequisiteIds: ['seed_drill']);
  m['safety_lamp'] = TechDefinition(id: 'safety_lamp', era: 4, category: 'gathering', cost: _cost(4), displayName: 'Safety Lamp', prerequisiteIds: ['large_coal_mines', 'dynamite']);
  m['large_precious_stone_mines'] = TechDefinition(id: 'large_precious_stone_mines', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Large Precious Stone Mines', prerequisiteIds: ['precious_stone_mining', 'university']);
  m['extraction_of_precious_metals'] = TechDefinition(id: 'extraction_of_precious_metals', era: 3, category: 'gathering', cost: _cost(3), displayName: 'Extraction of Precious Metals', prerequisiteIds: ['precious_metals_mining', 'university']);
  m['geological_prospecting'] = TechDefinition(id: 'geological_prospecting', era: 4, category: 'gathering', cost: _cost(4), displayName: 'Geological Prospecting', prerequisiteIds: ['large_precious_stone_mines', 'dynamite']);
  m['amalgamation_process'] = TechDefinition(id: 'amalgamation_process', era: 4, category: 'gathering', cost: _cost(4), displayName: 'Amalgamation Process', prerequisiteIds: ['dynamite', 'extraction_of_precious_metals']);
  m['industrial_iron_mining'] = TechDefinition(id: 'industrial_iron_mining', era: 4, category: 'gathering', cost: _cost(4), displayName: 'Industrial Iron Mining', prerequisiteIds: ['industrial_funding_of_research', 'steam_in_mining']);
  m['efficient_extraction_of_copper_and_tin'] = TechDefinition(id: 'efficient_extraction_of_copper_and_tin', era: 4, category: 'gathering', cost: _cost(4), displayName: 'Efficient Extraction of Copper & Tin', prerequisiteIds: ['large_coal_mines', 'large_copper_and_tin_mines']);

  // --- New World (28) ---
  m['discovery_of_sugar'] = TechDefinition(id: 'discovery_of_sugar', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Sugar', discoveryResourceIds: ['sugarCane']);
  m['sugar_planting'] = TechDefinition(id: 'sugar_planting', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Sugar Planting', prerequisiteIds: ['discovery_of_sugar']);
  m['sugar_refining'] = TechDefinition(id: 'sugar_refining', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Sugar Refining', prerequisiteIds: ['discovery_of_sugar']);
  m['large_sugar_plantations'] = TechDefinition(id: 'large_sugar_plantations', era: 2, category: 'new-world', cost: _cost(2), displayName: 'Large Sugar Plantations', prerequisiteIds: ['sugar_planting']);
  m['sugar_industry'] = TechDefinition(id: 'sugar_industry', era: 3, category: 'new-world', cost: _cost(3), displayName: 'Sugar Industry', prerequisiteIds: ['large_sugar_plantations']);
  m['discovery_of_tobacco'] = TechDefinition(id: 'discovery_of_tobacco', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Tobacco', discoveryResourceIds: ['tobacco']);
  m['tobacco_planting'] = TechDefinition(id: 'tobacco_planting', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Tobacco Planting', prerequisiteIds: ['discovery_of_tobacco']);
  m['cigar_production'] = TechDefinition(id: 'cigar_production', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Cigar Production', prerequisiteIds: ['discovery_of_tobacco']);
  m['large_tobacco_plantations'] = TechDefinition(id: 'large_tobacco_plantations', era: 2, category: 'new-world', cost: _cost(2), displayName: 'Large Tobacco Plantations', prerequisiteIds: ['tobacco_planting', 'seed_drill']);
  m['tobacco_industry'] = TechDefinition(id: 'tobacco_industry', era: 3, category: 'new-world', cost: _cost(3), displayName: 'Tobacco Industry', prerequisiteIds: ['early_steam_engine', 'large_tobacco_plantations']);
  m['discovery_of_cotton'] = TechDefinition(id: 'discovery_of_cotton', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Cotton', discoveryResourceIds: ['cotton']);
  m['cotton_planting'] = TechDefinition(id: 'cotton_planting', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Cotton Planting', prerequisiteIds: ['discovery_of_cotton']);
  m['cotton_weaving'] = TechDefinition(id: 'cotton_weaving', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Cotton Weaving', prerequisiteIds: ['discovery_of_cotton']);
  m['large_cotton_plantations'] = TechDefinition(id: 'large_cotton_plantations', era: 2, category: 'new-world', cost: _cost(2), displayName: 'Large Cotton Plantations', prerequisiteIds: ['cotton_planting']);
  m['cotton_gin'] = TechDefinition(id: 'cotton_gin', era: 3, category: 'new-world', cost: _cost(3), displayName: 'Cotton Gin', prerequisiteIds: ['large_cotton_plantations', 'trained_journeymen']);
  m['discovery_of_furs'] = TechDefinition(id: 'discovery_of_furs', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Furs', discoveryResourceIds: ['furs']);
  m['improved_trapping_techniques'] = TechDefinition(id: 'improved_trapping_techniques', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Improved Trapping Techniques', prerequisiteIds: ['discovery_of_furs']);
  m['hat_production'] = TechDefinition(id: 'hat_production', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Hat Production', prerequisiteIds: ['discovery_of_furs']);
  m['riverboats'] = TechDefinition(id: 'riverboats', era: 3, category: 'new-world', cost: _cost(3), displayName: 'Riverboats', prerequisiteIds: ['improved_trapping_techniques', 'early_steam_engine']);
  m['excessive_fur_harvesting'] = TechDefinition(id: 'excessive_fur_harvesting', era: 4, category: 'new-world', cost: _cost(4), displayName: 'Excessive Fur Harvesting', prerequisiteIds: ['later_steam_engine', 'riverboats']);
  m['discovery_of_spices'] = TechDefinition(id: 'discovery_of_spices', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Spices', discoveryResourceIds: ['spices']);
  m['improved_sea_routes'] = TechDefinition(id: 'improved_sea_routes', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Improved Sea Routes', prerequisiteIds: ['discovery_of_spices']);
  m['large_spice_plantations'] = TechDefinition(id: 'large_spice_plantations', era: 2, category: 'new-world', cost: _cost(2), displayName: 'Large Spice Plantations', prerequisiteIds: ['seed_drill', 'improved_sea_routes']);
  m['improved_food_preservation'] = TechDefinition(id: 'improved_food_preservation', era: 3, category: 'new-world', cost: _cost(3), displayName: 'Improved Food Preservation', prerequisiteIds: ['large_spice_plantations']);
  m['discovery_of_gold_or_silver'] = TechDefinition(id: 'discovery_of_gold_or_silver', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Gold or Silver', discoveryResourceIds: ['gold', 'silver']);
  m['precious_metals_mining'] = TechDefinition(id: 'precious_metals_mining', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Precious Metals Mining', prerequisiteIds: ['discovery_of_gold_or_silver', 'mine_engineering']);
  m['discovery_of_gems_or_diamonds'] = TechDefinition(id: 'discovery_of_gems_or_diamonds', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Discovery of Gems or Diamonds', discoveryResourceIds: ['gems', 'diamonds']);
  m['precious_stone_mining'] = TechDefinition(id: 'precious_stone_mining', era: 1, category: 'new-world', cost: _cost(1), displayName: 'Precious Stone Mining', prerequisiteIds: ['discovery_of_gems_or_diamonds']);

  // --- Transport (4) ---
  m['road_construction'] = TechDefinition(id: 'road_construction', era: 1, category: 'transport', cost: _cost(1), displayName: 'Road Construction', prerequisiteIds: ['saw_mill', 'land_enclosure', 'iron_mining']);
  m['early_steam_engine'] = TechDefinition(id: 'early_steam_engine', era: 2, category: 'transport', cost: _cost(2), displayName: 'Early Steam Engine', prerequisiteIds: ['road_construction', 'square_set_timbering', 'steam_in_mining']);
  m['later_steam_engine'] = TechDefinition(id: 'later_steam_engine', era: 3, category: 'transport', cost: _cost(3), displayName: 'Later Steam Engine', prerequisiteIds: ['early_steam_engine', 'crucible_process']);
  m['dynamite'] = TechDefinition(id: 'dynamite', era: 4, category: 'transport', cost: _cost(4), displayName: 'Dynamite', prerequisiteIds: ['later_steam_engine', 'banking', 'explosives']);

  // --- Labour (8) ---
  m['printing_press'] = TechDefinition(id: 'printing_press', era: 1, category: 'labour', cost: _cost(1), displayName: 'Printing Press', prerequisiteIds: ['saw_mill']);
  m['apprentice_workers'] = TechDefinition(id: 'apprentice_workers', era: 2, category: 'labour', cost: _cost(2), displayName: 'Apprentice Workers', prerequisiteIds: ['land_enclosure', 'sugar_refining']);
  m['trained_journeymen'] = TechDefinition(id: 'trained_journeymen', era: 2, category: 'labour', cost: _cost(2), displayName: 'Trained Journeymen', prerequisiteIds: ['cigar_production', 'printing_press']);
  m['master_artisans'] = TechDefinition(id: 'master_artisans', era: 3, category: 'labour', cost: _cost(3), displayName: 'Master Artisans', prerequisiteIds: ['apprentice_workers', 'university', 'hat_production']);
  m['money_lending'] = TechDefinition(id: 'money_lending', era: 1, category: 'labour', cost: _cost(1), displayName: 'Money Lending', prerequisiteIds: ['land_enclosure']);
  m['banking'] = TechDefinition(id: 'banking', era: 3, category: 'labour', cost: _cost(3), displayName: 'Banking', prerequisiteIds: ['master_artisans', 'trade_fairs']);
  m['trade_fairs'] = TechDefinition(id: 'trade_fairs', era: 2, category: 'labour', cost: _cost(2), displayName: 'Trade Fairs', prerequisiteIds: ['merchant_companies', 'sugar_refining']);
  m['university'] = TechDefinition(id: 'university', era: 3, category: 'labour', cost: _cost(3), displayName: 'University', prerequisiteIds: ['money_lending', 'apprentice_workers', 'printing_press']);

  // --- Diplomacy / Civilian (6) ---
  m['diplomatic_expertise'] = TechDefinition(id: 'diplomatic_expertise', era: 1, category: 'diplomacy', cost: _cost(1), displayName: 'Diplomatic Expertise');
  m['merchant_companies'] = TechDefinition(id: 'merchant_companies', era: 1, category: 'civilian', cost: _cost(1), displayName: 'Merchant Companies');
  m['national_bureaucracy'] = TechDefinition(id: 'national_bureaucracy', era: 2, category: 'civilian', cost: _cost(2), displayName: 'National Bureaucracy', prerequisiteIds: ['printing_press', 'money_lending', 'diplomatic_expertise']);
  m['propaganda'] = TechDefinition(id: 'propaganda', era: 3, category: 'diplomacy', cost: _cost(3), displayName: 'Propaganda', prerequisiteIds: ['national_bureaucracy', 'university']);
  m['nationalism'] = TechDefinition(id: 'nationalism', era: 3, category: 'diplomacy', cost: _cost(3), displayName: 'Nationalism', prerequisiteIds: ['propaganda', 'master_artisans', 'modern_forts']);
  m['empire_building'] = TechDefinition(id: 'empire_building', era: 4, category: 'diplomacy', cost: _cost(4), displayName: 'Empire Building', prerequisiteIds: ['nationalism', 'banking']);

  // --- Naval merchant (8) ---
  m['superior_hull_design'] = TechDefinition(id: 'superior_hull_design', era: 1, category: 'naval', cost: _cost(1), displayName: 'Superior Hull Design', shipUnlockIds: ['fluyte']);
  m['improved_sail_design'] = TechDefinition(id: 'improved_sail_design', era: 2, category: 'naval', cost: _cost(2), displayName: 'Improved Sail Design', prerequisiteIds: ['wind_saw_mill', 'superior_hull_design'], shipUnlockIds: ['trader']);
  m['convoying'] = TechDefinition(id: 'convoying', era: 2, category: 'naval', cost: _cost(2), displayName: 'Convoying', prerequisiteIds: ['merchant_companies'], shipUnlockIds: ['galleon']);
  m['navigation'] = TechDefinition(id: 'navigation', era: 1, category: 'naval', cost: _cost(1), displayName: 'Navigation', prerequisiteIds: ['superior_hull_design'], shipUnlockIds: ['sloop']);
  m['large_hulls'] = TechDefinition(id: 'large_hulls', era: 2, category: 'naval', cost: _cost(2), displayName: 'Large Hulls', prerequisiteIds: ['wind_saw_mill', 'navigation', 'convoying'], shipUnlockIds: ['indiaman']);
  m['clipper_ships'] = TechDefinition(id: 'clipper_ships', era: 4, category: 'naval', cost: _cost(4), displayName: 'Clipper Ships', prerequisiteIds: ['circular_saw', 'advanced_hull_design'], shipUnlockIds: ['clipper']);
  m['paddlewheels'] = TechDefinition(id: 'paddlewheels', era: 3, category: 'naval', cost: _cost(3), displayName: 'Paddlewheels', prerequisiteIds: ['advanced_hull_design', 'early_steam_engine'], shipUnlockIds: ['raider']);
  m['merchant_steamships'] = TechDefinition(id: 'merchant_steamships', era: 4, category: 'naval', cost: _cost(4), displayName: 'Merchant Steamships', prerequisiteIds: ['paddlewheels', 'riverboats'], shipUnlockIds: ['merchant_steamship']);

  // --- Naval warships (4) ---
  m['advanced_hull_design'] = TechDefinition(id: 'advanced_hull_design', era: 3, category: 'naval', cost: _cost(3), displayName: 'Advanced Hull Design', prerequisiteIds: ['university', 'improved_sail_design', 'privateering_companies'], shipUnlockIds: ['frigate']);
  m['ship_of_the_line'] = TechDefinition(id: 'ship_of_the_line', era: 3, category: 'naval', cost: _cost(3), displayName: 'Ship of the Line', prerequisiteIds: ['large_hulls', 'large_copper_and_tin_mines'], shipUnlockIds: ['ship_of_the_line']);
  m['privateering_companies'] = TechDefinition(id: 'privateering_companies', era: 2, category: 'naval', cost: _cost(2), displayName: 'Privateering Companies', prerequisiteIds: ['navigation', 'diplomatic_expertise']);
  m['advanced_iron_working'] = TechDefinition(id: 'advanced_iron_working', era: 4, category: 'naval', cost: _cost(4), displayName: 'Advanced Iron Working', prerequisiteIds: ['ship_of_the_line', 'industrial_funding_of_research', 'paddlewheels'], shipUnlockIds: ['ironclad']);

  // --- Military infantry (12) ---
  m['organised_regiments'] = TechDefinition(id: 'organised_regiments', era: 1, category: 'military', cost: _cost(1), displayName: 'Organised Regiments', prerequisiteIds: ['land_enclosure'], regimentUnlockIds: ['lancers']);
  m['improved_iron_weapons'] = TechDefinition(id: 'improved_iron_weapons', era: 1, category: 'military', cost: _cost(1), displayName: 'Improved Iron Weapons', prerequisiteIds: ['organised_regiments', 'iron_mining'], regimentUnlockIds: ['halberdiers']);
  m['improved_infantry_tactics'] = TechDefinition(id: 'improved_infantry_tactics', era: 2, category: 'military', cost: _cost(2), displayName: 'Improved Infantry Tactics', prerequisiteIds: ['organised_regiments', 'printing_press'], regimentUnlockIds: ['calivermen']);
  m['crucible_process'] = TechDefinition(id: 'crucible_process', era: 2, category: 'military', cost: _cost(2), displayName: 'Crucible Process', prerequisiteIds: ['square_set_timbering', 'steam_in_mining']);
  m['bayonet'] = TechDefinition(id: 'bayonet', era: 2, category: 'military', cost: _cost(2), displayName: 'Bayonet', prerequisiteIds: ['improved_iron_weapons', 'crucible_process'], regimentUnlockIds: ['regulars']);
  m['weapon_craftsmanship'] = TechDefinition(id: 'weapon_craftsmanship', era: 2, category: 'military', cost: _cost(2), displayName: 'Weapon Craftsmanship', prerequisiteIds: ['organised_regiments', 'copper_and_tin_mining'], regimentUnlockIds: ['musketeers']);
  m['industrial_machinery'] = TechDefinition(id: 'industrial_machinery', era: 3, category: 'military', cost: _cost(3), displayName: 'Industrial Machinery', prerequisiteIds: ['trained_journeymen', 'steam_in_mining', 'university']);
  m['explosives'] = TechDefinition(id: 'explosives', era: 3, category: 'military', cost: _cost(3), displayName: 'Explosives', prerequisiteIds: ['weapon_craftsmanship', 'industrial_machinery'], regimentUnlockIds: ['grenadiers']);
  m['early_rifles'] = TechDefinition(id: 'early_rifles', era: 3, category: 'military', cost: _cost(3), displayName: 'Early Rifles', prerequisiteIds: ['improved_infantry_tactics', 'crucible_process'], regimentUnlockIds: ['skirmishers']);
  m['long_range_rifles'] = TechDefinition(id: 'long_range_rifles', era: 3, category: 'military', cost: _cost(3), displayName: 'Long Range Rifles', prerequisiteIds: ['early_rifles', 'crucible_process'], regimentUnlockIds: ['sharpshooters']);
  m['needle_guns'] = TechDefinition(id: 'needle_guns', era: 4, category: 'military', cost: _cost(4), displayName: 'Needle Guns', prerequisiteIds: ['industrial_funding_of_research', 'bayonet', 'early_rifles'], regimentUnlockIds: ['rifle_infantry']);
  m['elite_military_training'] = TechDefinition(id: 'elite_military_training', era: 4, category: 'military', cost: _cost(4), displayName: 'Elite Military Training', prerequisiteIds: ['modern_military_funding', 'needle_guns', 'explosives'], regimentUnlockIds: ['guards']);

  // --- Military cavalry (6) ---
  m['recruit_steppe_horsemen'] = TechDefinition(id: 'recruit_steppe_horsemen', era: 1, category: 'military', cost: _cost(1), displayName: 'Recruit Steppe Horsemen', prerequisiteIds: ['crop_rotation'], regimentUnlockIds: ['cossacks']);
  m['improved_cavalry_tactics'] = TechDefinition(id: 'improved_cavalry_tactics', era: 2, category: 'military', cost: _cost(2), displayName: 'Improved Cavalry Tactics', prerequisiteIds: ['printing_press', 'animal_husbandry'], regimentUnlockIds: ['harquebusiers']);
  m['hussars'] = TechDefinition(id: 'hussars', era: 2, category: 'military', cost: _cost(2), displayName: 'Hussars', prerequisiteIds: ['improved_cavalry_tactics', 'recruit_steppe_horsemen'], regimentUnlockIds: ['hussars']);
  m['improved_cavalry_weapons'] = TechDefinition(id: 'improved_cavalry_weapons', era: 3, category: 'military', cost: _cost(3), displayName: 'Improved Cavalry Weapons', prerequisiteIds: ['industrial_machinery', 'crucible_process', 'improved_cavalry_tactics'], regimentUnlockIds: ['cuirassiers']);
  m['scouting'] = TechDefinition(id: 'scouting', era: 3, category: 'military', cost: _cost(3), displayName: 'Scouting', prerequisiteIds: ['hussars', 'early_rifles'], regimentUnlockIds: ['scouts']);
  m['repeating_cavalry_carbine'] = TechDefinition(id: 'repeating_cavalry_carbine', era: 4, category: 'military', cost: _cost(4), displayName: 'Repeating Cavalry Carbine', prerequisiteIds: ['industrial_funding_of_research', 'improved_cavalry_weapons'], regimentUnlockIds: ['carbine_cavalry']);

  // --- Military artillery (11) ---
  m['horse_artillery'] = TechDefinition(id: 'horse_artillery', era: 1, category: 'military', cost: _cost(1), displayName: 'Horse Artillery', prerequisiteIds: ['animal_husbandry', 'copper_and_tin_mining'], regimentUnlockIds: ['horse_artillery']);
  m['siege_engineering'] = TechDefinition(id: 'siege_engineering', era: 2, category: 'military', cost: _cost(2), displayName: 'Siege Engineering', prerequisiteIds: ['printing_press', 'copper_and_tin_mining'], regimentUnlockIds: ['royal_artillery']);
  m['light_artillery_tactics'] = TechDefinition(id: 'light_artillery_tactics', era: 3, category: 'military', cost: _cost(3), displayName: 'Light Artillery Tactics', prerequisiteIds: ['crucible_process', 'university'], regimentUnlockIds: ['light_artillery']);
  m['modern_forts'] = TechDefinition(id: 'modern_forts', era: 3, category: 'military', cost: _cost(3), displayName: 'Modern Forts', prerequisiteIds: ['siege_engineering', 'university']);
  m['heavy_artillery'] = TechDefinition(id: 'heavy_artillery', era: 3, category: 'military', cost: _cost(3), displayName: 'Heavy Artillery', prerequisiteIds: ['modern_forts', 'crucible_process'], regimentUnlockIds: ['heavy_artillery']);
  m['heavy_emplaced_artillery'] = TechDefinition(id: 'heavy_emplaced_artillery', era: 3, category: 'military', cost: _cost(3), displayName: 'Heavy Emplaced Artillery', prerequisiteIds: ['road_construction', 'national_bureaucracy', 'siege_engineering']);
  m['field_artillery_tactics'] = TechDefinition(id: 'field_artillery_tactics', era: 4, category: 'military', cost: _cost(4), displayName: 'Field Artillery Tactics', prerequisiteIds: ['light_artillery_tactics', 'modern_military_funding'], regimentUnlockIds: ['field_artillery']);
  m['high_grade_steel'] = TechDefinition(id: 'high_grade_steel', era: 4, category: 'military', cost: _cost(4), displayName: 'High Grade Steel', prerequisiteIds: ['heavy_artillery', 'industrial_funding_of_research', 'modern_military_funding'], regimentUnlockIds: ['siege_guns']);
  m['emplaced_siege_guns'] = TechDefinition(id: 'emplaced_siege_guns', era: 4, category: 'military', cost: _cost(4), displayName: 'Emplaced Siege Guns', prerequisiteIds: ['heavy_artillery', 'heavy_emplaced_artillery']);
  m['modern_military_funding'] = TechDefinition(id: 'modern_military_funding', era: 3, category: 'military', cost: _cost(3), displayName: 'Modern Military Funding', prerequisiteIds: ['banking', 'large_precious_stone_mines', 'modern_forts']);
  m['industrial_funding_of_research'] = TechDefinition(id: 'industrial_funding_of_research', era: 3, category: 'military', cost: _cost(3), displayName: 'Industrial Funding of Research', prerequisiteIds: ['industrial_machinery', 'crucible_process']);

  return m;
}
