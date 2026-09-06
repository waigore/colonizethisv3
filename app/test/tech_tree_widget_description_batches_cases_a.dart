// Batches 1–6 for TechTreeWidget description pins (Refs #4305 / #4734 Slice F).

import 'tech_tree_widget_description_batches_shared.dart';

const List<TechTreeDescriptionBatch> techTreeDescriptionBatchesA =
    <TechTreeDescriptionBatch>[
  (
    name:
        'Batch-1 tech descriptions are concrete and avoid generic fallback text',
    expectedByTech: <String, String>{
      'Crop Rotation':
          'Unlocks: Sheep Ranching, Animal Husbandry, and Steppe Horsemen research paths',
      'Saw Mill': 'Improves: Timber extraction cap to 2 (forested provinces)',
      'Land Enclosure': 'Improves: Grain extraction cap to 2',
      'Mine Engineering': 'Enables: Builder upgrades to Fort Level 2',
      'Iron Mining': 'Improves: Iron extraction cap to 2',
      'Copper and Tin Mining': 'Improves: Copper/Tin extraction cap to 2',
      'Coal Mining': 'Enables: Coal extraction (cap 1)',
      'Wind Saw Mill': 'Improves: Timber extraction cap to 3',
      'Seed Drill': 'Improves: Grain extraction cap to 3',
      'Sheep Ranching': 'Improves: Wool extraction cap to 2',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbGather,
      techTreeDescriptionFbLabourEcon,
    ],
  ),
  (
    name:
        'Batch-2 tech descriptions are concrete and avoid generic fallback text (Refs #1626)',
    expectedByTech: <String, String>{
      'Animal Husbandry': 'Improves: Meat extraction cap to 3',
      'Square-set Timbering': 'Improves: Coal extraction cap to 2',
      'Steam in Mining': 'Improves: Iron extraction cap to 3',
      'Large Coal Mines': 'Improves: Coal extraction cap to 3',
      'Large Copper and Tin Mines': 'Improves: Copper/Tin extraction cap to 3',
      'Circular Saw': 'Improves: Timber extraction cap to 4',
      'Scientific Sheep Breeding': 'Improves: Wool extraction cap to 3',
      'Scientific Cattle Breeding': 'Improves: Meat extraction cap to 4',
      'Moldboard Plow': 'Improves: Grain extraction cap to 4',
      'Safety Lamp': 'Improves: Coal extraction cap to 4',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbGather,
      techTreeDescriptionFbLabourEcon,
    ],
  ),
  (
    name:
        'Batch-3 tech descriptions are concrete and avoid generic fallback text (Refs #1627)',
    expectedByTech: <String, String>{
      'Large Precious Stone Mines':
          'Improves: Gems/diamonds extraction cap to 3',
      'Extraction of Precious Metals':
          'Improves: Gold/silver extraction cap to 3',
      'Geological Prospecting': 'Improves: Gems/diamonds extraction cap to 4',
      'Amalgamation Process': 'Improves: Gold/silver extraction cap to 4',
      'Industrial Iron Mining': 'Improves: Iron extraction cap to 4',
      'Efficient Extraction of Copper & Tin':
          'Improves: Copper/Tin extraction cap to 4',
      'Discovery of Sugar':
          'Enables: Research when player has revealed sugar cane (discovery rule)',
      'Sugar Planting': 'Improves: Sugar cane extraction cap to 2',
      'Sugar Refining':
          'Enables: Refined sugar luxury for Apprentice-tier worker consumption',
      'Large Sugar Plantations': 'Improves: Sugar cane extraction cap to 3',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbGather,
      techTreeDescriptionFbLabourEcon,
      techTreeDescriptionFbNewWorld,
    ],
  ),
  (
    name:
        'Batch-4 tech descriptions are concrete and avoid generic fallback text (Refs #1628)',
    expectedByTech: <String, String>{
      'Sugar Industry': 'Improves: Sugar cane extraction cap to 4',
      'Discovery of Tobacco':
          'Enables: Research when player has revealed tobacco (discovery rule)',
      'Tobacco Planting': 'Improves: Tobacco extraction cap to 2',
      'Cigar Production':
          'Enables: Cigar luxury production for Journeyman-tier worker consumption',
      'Large Tobacco Plantations': 'Improves: Tobacco extraction cap to 3',
      'Tobacco Industry': 'Improves: Tobacco extraction cap to 4',
      'Discovery of Cotton':
          'Enables: Research when player has revealed cotton (discovery rule)',
      'Cotton Planting': 'Improves: Cotton extraction cap to 2',
      'Cotton Weaving': 'Enables: Cloth production from cotton',
      'Large Cotton Plantations': 'Improves: Cotton extraction cap to 3',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbGather,
      techTreeDescriptionFbLabourEcon,
      techTreeDescriptionFbNewWorld,
    ],
  ),
  (
    name:
        'Batch-5 tech descriptions are concrete and avoid generic fallback text (Refs #1629)',
    expectedByTech: <String, String>{
      'Cotton Gin': 'Improves: Cotton extraction cap to 4',
      'Discovery of Furs':
          'Enables: Research when player has revealed furs (discovery rule)',
      'Improved Trapping Techniques': 'Improves: Furs extraction cap to 2',
      'Hat Production':
          'Enables: Fur hats luxury production for Master-tier worker consumption',
      'Riverboats': 'Improves: Furs extraction cap to 3',
      'Excessive Fur Harvesting': 'Improves: Furs extraction cap to 4',
      'Discovery of Spices':
          'Enables: Research when player has revealed spices (discovery rule)',
      'Improved Sea Routes': 'Improves: Spices extraction cap to 2',
      'Large Spice Plantations': 'Improves: Spices extraction cap to 3',
      'Improved Food Preservation': 'Improves: Spices extraction cap to 4',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbGather,
      techTreeDescriptionFbLabourEcon,
      techTreeDescriptionFbNewWorld,
    ],
  ),
  (
    name:
        'Batch-6 tech descriptions are concrete and avoid generic fallback text (Refs #1630)',
    expectedByTech: <String, String>{
      'Discovery of Gold or Silver':
          'Enables: Research when player has revealed and prospected gold/silver',
      'Precious Metals Mining': 'Improves: Gold/silver extraction cap to 2',
      'Discovery of Gems or Diamonds':
          'Enables: Research when player has revealed and prospected gems/diamonds',
      'Precious Stone Mining': 'Improves: Gems/diamonds extraction cap to 2',
      'Road Construction':
          'Enables: Engineer road upgrades to transport level 2',
      'Early Steam Engine':
          'Enables: Rail Builder and railroads on flat terrain',
      'Later Steam Engine': 'Enables: Railroads on hills and swamps',
      'Dynamite': 'Enables: Railroads on mountains',
      'Printing Press':
          'Unlocks: Trained Journeymen, University, and military doctrine paths',
      'Apprentice Workers':
          'Enables: Apprentice tier (4x labour; consumes refined sugar)',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbNewWorld,
      techTreeDescriptionFbTransport,
      techTreeDescriptionFbLabour,
    ],
  ),
];
