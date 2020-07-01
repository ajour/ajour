-- Constants.lua
-- June 2014

local addon, ns = ...
local Hekili = _G[ addon ]


-- Class Localization
ns.getLocalClass = function ( class )

  if not ns.player.sex then ns.player.sex = UnitSex( 'player' ) end

  return ns.player.sex == 1 and LOCALIZED_CLASS_NAMES_MALE[ class ] or LOCALIZED_CLASS_NAMES_FEMALE[ class ]

end


local InverseDirection = {
  LEFT = 'RIGHT',
  RIGHT = 'LEFT',
  TOP = 'BOTTOM',
  BOTTOM = 'TOP'
}

ns.getInverseDirection = function ( dir )

  return InverseDirection[ dir ] or dir

end


local ClassIDs = {}

for i = 1, GetNumClasses() do
  local classDisplayName, classTag = GetClassInfo( i )

  ClassIDs[ classTag ] = i
end

ns.getClassID = function( class )

  return ClassIDs[ class ] or -1

end


local ResourceInfo = {
    -- health          = Enum.PowerType.HealthCost,
    none            = Enum.PowerType.None,
    mana            = Enum.PowerType.Mana,
    rage            = Enum.PowerType.Rage,
    focus           = Enum.PowerType.Focus,
    energy          = Enum.PowerType.Energy,
    combo_points    = Enum.PowerType.ComboPoints,
    runes           = Enum.PowerType.Runes,
    runic_power     = Enum.PowerType.RunicPower,
    soul_shards     = Enum.PowerType.SoulShards,
    astral_power    = Enum.PowerType.LunarPower,
    holy_power      = Enum.PowerType.HolyPower,
    alternate       = Enum.PowerType.Alternate,
    maelstrom       = Enum.PowerType.Maelstrom,
    chi             = Enum.PowerType.Chi,
    insanity        = Enum.PowerType.Insanity,
    obsolete        = Enum.PowerType.Obsolete,
    obsolete2       = Enum.PowerType.Obsolete2,
    arcane_charges  = Enum.PowerType.ArcaneCharges,
    fury            = Enum.PowerType.Fury,
    pain            = Enum.PowerType.Pain
}

local ResourceByID = {}

for k, powerType in pairs( ResourceInfo ) do
    ResourceByID[ powerType ] = k
end


function ns.GetResourceInfo()
    return ResourceInfo
end


function ns.GetResourceID( key )
    return ResourceInfo[ key ]
end


function ns.GetResourceKey( id )
    return ResourceByID[ id ]
end


local passive_regen = {
    mana = 1,
    focus = 1,
    energy = 1
}

function ns.ResourceRegenerates( key )
    -- Does this resource have a passive gain from waiting?
    if passive_regen[ key ] then return true end
    return false
end


local Specializations = {
  death_knight_blood = 250,
  death_knight_frost = 251,
  death_knight_unholy = 252,

  druid_balance = 102,
  druid_feral = 103,
  druid_guardian = 104,
  druid_restoration = 105,

  hunter_beast_mastery = 253,
  hunter_marksmanship = 254,
  hunter_survival = 255,

  mage_arcane = 62,
  mage_fire = 63,
  mage_frost = 64,

  monk_brewmaster = 268,
  monk_windwalker = 269,
  monk_mistweaver = 270,

  paladin_holy = 65,
  paladin_protection = 66,
  paladin_retribution = 70,

  priest_discipline = 256,
  priest_holy = 257,
  priest_shadow = 258,

  rogue_assassination = 259,
  rogue_outlaw = 260,
  rogue_subtlety = 261,

  shaman_elemental = 262,
  shaman_enhancement = 263,
  shaman_restoration = 264,

  warlock_affliction = 265,
  warlock_demonology = 266,
  warlock_destruction = 267,

  warrior_arms = 71,
  warrior_fury = 72,
  warrior_protection = 73,

  demonhunter_havoc = 577,
  demonhunter_vengeance = 581
}

ns.getSpecializationID = function ( key )
  return Specializations[ key ] or -1
end


local SpecializationKeys = {
  [250] = 'blood',
  [251] = 'frost',
  [252] = 'unholy',

  [102] = 'balance',
  [103] = 'feral',
  [104] = 'guardian',
  [105] = 'restoration',

  [253] = 'beast_mastery',
  [254] = 'marksmanship',
  [255] = 'survival',

  [62] = 'arcane',
  [63] = 'fire',
  [64] = 'frost',

  [268] = 'brewmaster',
  [269] = 'windwalker',
  [270] = 'mistweaver',

  [65] = 'holy',
  [66] = 'protection',
  [70] = 'retribution',

  [256] = 'discipline',
  [257] = 'holy',
  [258] = 'shadow',

  [259] = 'assassination',
  [260] = 'outlaw',
  [261] = 'subtlety',

  [262] = 'elemental',
  [263] = 'enhancement',
  [264] = 'restoration',

  [265] = 'affliction',
  [266] = 'demonology',
  [267] = 'destruction',

  [71] = 'arms',
  [72] = 'fury',
  [73] = 'protection',

  [577] = 'havoc',
  [581] = 'vengeance'
}

ns.getSpecializationKey = function ( id )
  return SpecializationKeys[ id ] or 'none'
end


ns.getSpecializationID = function ( index )
  return GetSpecializationInfo( index or GetSpecialization() or 0 )
end



ns.FrameStratas = {
  "BACKGROUND",
  "LOW",
  "MEDIUM",
  "HIGH",
  "DIALOG",
  "FULLSCREEN",
  "FULLSCREEN_DIALOG",
  "TOOLTIP",

  BACKGROUND = 1,
  LOW = 2,
  MEDIUM = 3,
  HIGH = 4,
  DIALOG = 5,
  FULLSCREEN = 6,
  FULLSCREEN_DIALOG = 7,
  TOOLTIP = 8
}