// Batches 7–12 for TechTreeWidget description pins (Refs #4305 / #4734 Slice F).

import 'tech_tree_widget_description_batches_shared.dart';

const List<TechTreeDescriptionBatch> techTreeDescriptionBatchesB =
    <TechTreeDescriptionBatch>[
  (
    name:
        'Batch-7 tech descriptions are concrete and avoid generic fallback text (Refs #1631)',
    expectedByTech: <String, String>{
      'Trained Journeymen':
          'Enables: Journeyman tier (6x labour; consumes cigars)',
      'Master Artisans': 'Enables: Master tier (8x labour; consumes fur hats)',
      'Money Lending': 'Enables: Research-phase treasury floor to -500',
      'Banking': 'Unlocks: Dynamite, Empire Building, Modern Military Funding',
      'Trade Fairs':
          'Enables: 6 commodity slots per embassy trade agreement (3 baseline without this tech)',
      'University': 'Enables: Fourth active research slot (3 -> 4)',
      'Diplomatic Expertise': 'Enables: Embassy overtures with Minor Nations',
      'Merchant Companies': 'Enables: Merchant civilian unit construction',
      'National Bureaucracy': 'Enables: Builder upgrade_town work order',
      'Propaganda':
          'Improves: Diplomatic protest war penalty against aggressor (-10 -> -5)',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbLabour,
      techTreeDescriptionFbDiplomacy,
      techTreeDescriptionFbCivilian,
    ],
  ),
  (
    name:
        'Batch-8 tech descriptions are concrete and avoid generic fallback text (Refs #1632)',
    expectedByTech: <String, String>{
      'Nationalism':
          'Improves: Battle deployment base limit to 12 regiments (vs 10)',
      'Empire Building':
          'Enables: Join Empire overture toward nearly-defeated Great Powers',
      'Superior Hull Design':
          'Unlocks: Improved Sail Design and Navigation hull paths',
      'Improved Sail Design':
          'Unlocks: Advanced Hull Design path (University + Privateering)',
      'Convoying': 'Unlocks: Large Hulls (with Wind Saw Mill + Navigation)',
      'Navigation': 'Unlocks: Large Hulls and Privateering Companies',
      'Large Hulls':
          'Unlocks: Ship of the Line (with Large Copper and Tin Mines)',
      'Clipper Ships': 'Improves: Late-era fast merchant Clipper cargo line',
      'Paddlewheels': 'Unlocks: Merchant Steamships (with Riverboats)',
      'Merchant Steamships':
          'Enables: Steam-powered merchant hull for seagoing trade',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbNaval,
      techTreeDescriptionFbDiplomacy,
    ],
  ),
  (
    name:
        'Batch-9 tech descriptions are concrete and avoid generic fallback text (Refs #1633)',
    expectedByTech: <String, String>{
      'Advanced Hull Design':
          'Improves: Frigate — high intercept, moderate flee (patrol/blockade)',
      'Ship of the Line':
          'Improves: Battle-line capital ship for decisive fleet engagements',
      'Privateering Companies':
          'Improves: Patrol/Blockade interception and trade-raid effectiveness',
      'Advanced Iron Working': 'Improves: Ironclad armored steam combat hull',
      'Organised Regiments': 'Improves: General cap floor to at least 2',
      'Improved Iron Weapons': 'Unlocks: Bayonet (with Crucible Process)',
      'Improved Infantry Tactics':
          'Improves: General cap floor to at least 3 (or National Bureaucracy)',
      'Crucible Process':
          'Prerequisite-only: Steel chain for Bayonet, rifles, steam, and cannons',
      'Bayonet':
          'Unlocks: Needle Guns (with Industrial Funding + Early Rifles)',
      'Weapon Craftsmanship':
          'Unlocks: Explosives and Grenadiers (with Industrial Machinery)',
    },
    forbiddenFragments: <String>[
      techTreeDescriptionFbNaval,
      techTreeDescriptionFbMilitary,
    ],
  ),
  (
    name:
        'Batch-10 tech descriptions are concrete and avoid generic fallback text (Refs #1634)',
    expectedByTech: <String, String>{
      'Industrial Machinery':
          'Unlocks: Explosives, Improved Cavalry Weapons, Industrial Funding of Research (as prerequisite)',
      'Explosives': 'Improves: Musketeers regiment upgrade path',
      'Early Rifles': 'Improves: Calivermen regiment upgrade path',
      'Long Range Rifles': 'Improves: Skirmishers regiment upgrade path',
      'Needle Guns': 'Improves: Regulars regiment upgrade path',
      'Elite Military Training': 'Improves: Grenadiers regiment upgrade path',
      'Recruit Steppe Horsemen': 'Improves: Squires regiment upgrade path',
      'Improved Cavalry Tactics':
          'Prerequisite for: Hussars and Improved Cavalry Weapons',
      'Hussars': 'Improves: Cossacks regiment upgrade path',
      'Improved Cavalry Weapons':
          'Improves: Harquebusiers regiment upgrade path',
    },
    forbiddenFragments: <String>[techTreeDescriptionFbMilitaryCap],
  ),
  (
    name:
        'Batch-11 tech descriptions are concrete and avoid generic fallback text (Refs #1635)',
    expectedByTech: <String, String>{
      'Scouting': 'Improves: Hussars regiment upgrade path',
      'Repeating Cavalry Carbine':
          'Improves: Cuirassiers regiment upgrade path',
      'Horse Artillery': 'Prerequisite for: Light Artillery Tactics',
      'Siege Engineering': 'Improves: Culverin regiment upgrade path',
      'Light Artillery Tactics':
          'Improves: Horse Artillery regiment upgrade path',
      'Modern Forts':
          'Enables: Builder fort upgrades to level 3 (Modern: 3 emplaced guns, strongest walls)',
      'Heavy Artillery': 'Improves: Royal Artillery regiment upgrade path',
      'Heavy Emplaced Artillery':
          'Improves: defender emplaced fort batteries to Heavy quality (Royal → Heavy line)',
      'Field Artillery Tactics':
          'Improves: Light Artillery regiment upgrade path',
      'High Grade Steel': 'Improves: Heavy Artillery regiment upgrade path',
    },
    forbiddenFragments: <String>[techTreeDescriptionFbMilitaryCap],
  ),
  (
    name:
        'Batch-12 tech descriptions are concrete and avoid generic fallback text (Refs #1636)',
    expectedByTech: <String, String>{
      'Emplaced Siege Guns':
          'Improves: defender emplaced fort batteries to Siege Gun quality (final emplaced tier)',
      'Modern Military Funding':
          'Unlocks: Field Artillery Tactics, High Grade Steel, Elite Military Training stack',
      'Industrial Funding of Research':
          'Unlocks: Needle Guns, Repeating Cavalry Carbine, High Grade Steel, Advanced Iron Working (as prerequisite)',
    },
    forbiddenFragments: <String>[techTreeDescriptionFbMilitaryCap],
  ),
];
