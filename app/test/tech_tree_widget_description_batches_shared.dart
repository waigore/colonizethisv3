// Shared types for TechTreeWidget description batch tables (Refs #4305).

typedef TechTreeDescriptionBatch = ({
  String name,
  Map<String, String> expectedByTech,
  List<String> forbiddenFragments,
});

const _fbGather = 'Improves gathering capabilities';
const _fbLabourEcon = 'Improves labour and economy output';
const _fbNewWorld = 'Improves new-world capabilities';
const _fbTransport = 'Improves transport capabilities';
const _fbLabour = 'Improves labour capabilities';
const _fbDiplomacy = 'Improves diplomacy capabilities';
const _fbCivilian = 'Improves civilian capabilities';
const _fbNaval = 'Improves naval capabilities';
const _fbMilitary = 'Improves military capabilities';
const _fbMilitaryCap = 'Improves Military capabilities';

// Exported for batch modules.
const techTreeDescriptionFbGather = _fbGather;
const techTreeDescriptionFbLabourEcon = _fbLabourEcon;
const techTreeDescriptionFbNewWorld = _fbNewWorld;
const techTreeDescriptionFbTransport = _fbTransport;
const techTreeDescriptionFbLabour = _fbLabour;
const techTreeDescriptionFbDiplomacy = _fbDiplomacy;
const techTreeDescriptionFbCivilian = _fbCivilian;
const techTreeDescriptionFbNaval = _fbNaval;
const techTreeDescriptionFbMilitary = _fbMilitary;
const techTreeDescriptionFbMilitaryCap = _fbMilitaryCap;
