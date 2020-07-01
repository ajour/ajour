-- State.lua
-- June 2014

local addon, ns = ...
local Hekili = _G[ addon ]

local auras = ns.auras

local formatKey = ns.formatKey
local getSpecializationID = ns.getSpecializationID
local ResourceRegenerates = ns.ResourceRegenerates

local Error = ns.Error

local orderedPairs = ns.orderedPairs
local round, roundUp, roundDown = ns.round, ns.roundUp, ns.roundDown
local safeMin, safeMax = ns.safeMin, ns.safeMax

local tcopy = ns.tableCopy

-- Clean up table_x later.
local insert, remove, sort, unpack, wipe = table.insert, table.remove, table.sort, table.unpack, table.wipe
local RC = LibStub( "LibRangeCheck-2.0" )


local class = Hekili.Class
local scripts = Hekili.Scripts


-- This will be our environment table for local functions.
local state = Hekili.State


state.iteration = 0

local PTR = ns.PTR
state.PTR = PTR
state.ptr = PTR and 1 or 0

state.now = 0
state.offset = 0

state.encounterID = 0
state.encounterName = "None"
state.encounterDifficulty = 0

state.delay = 0
state.delayMin = 0
state.delayMax = 60

state.false_start = 0
state.latency = 0

state.filter = "none"
state.cycle_aura = 'no_aura'
state.cast_target = 'nobody'

state.arena = false
state.bg = false

state.mainhand_speed = 0
state.offhand_speed = 0

state.min_targets = 0
state.max_targets = 0

state.action = {}
state.active_dot = {}
state.args = {}
state.azerite = {}
state.essence = {}
state.aura = {}
state.buff = {}
state.auras = auras
state.consumable = {}
state.cooldown = {}
state.corruptions = {}
--[[ state.health = {
    resource = "health",
    actual = 10000,
    max = 10000,
    regen = 0
} ]]
state.debuff = {}
state.dot = {}
state.equipped = {}
state.gcd = {}

state.history = {
    casts = {},
    units = {}
}

state.holds = {}

state.items = {}
state.pet = {
    fake_pet = {
        name = "Mary-Kate Olsen",
        expires = 0,
        permanent = false,
    }
}
state.player = {
    lastcast = 'none',
    lastgcd = 'none',
    lastoffgcd = 'none',
    casttime = 0,
    updated = true,
    channeling = false,
    channel_start = 0,
    channel_end = 0,
    channel_spell = nil
}
state.prev = {
    meta = 'castsAll',
    history = { 'no_action', 'no_action', 'no_action', 'no_action', 'no_action' }
}
state.prev_gcd = {
    meta = 'castsOn',
    history = { 'no_action', 'no_action', 'no_action', 'no_action', 'no_action' }
}
state.prev_off_gcd = {
    meta = 'castsOff',
    history = { 'no_action', 'no_action', 'no_action', 'no_action', 'no_action' }
}
state.predictions = {}
state.predictionsOff = {}
state.predictionsOn = {}
state.purge = {}
state.pvptalent = {}
state.race = {}
state.script = {}
state.set_bonus = {}
state.settings = {}
state.sim = {}
state.spec = {}
state.stance = {}
state.stat = {}
state.swings = {
    mh_actual = 0,
    mh_speed = UnitAttackSpeed( 'player' ) > 0 and UnitAttackSpeed( 'player' ) or 2.6,
    mh_projected = 2.6,
    oh_actual = 0,
    oh_speed = select( 2, UnitAttackSpeed( 'player' ) ) or 2.6,
    oh_projected = 3.9
}
state.system = {}
state.table = table
state.talent = {}
state.target = {
    debuff = state.debuff,
    dot = state.dot,
    health = {},
    updated = true
}
state.movement = state.target -- lazy!
state.sim.target = state.target
state.toggle = {}
state.totem = {}


state.trinket = {
    t1 = {
        slot = 't1',

        cooldown = {
            slot = 't1'
        },
        --[[ has_cooldown = {
            slot = 't1'
        }, ]]

        stacking_stat = {
            slot = 't1'
        },
        has_stacking_stat = {
            slot = 't1'
        },

        stat = {
            slot = 't1'
        },
        has_stat = {
            slot = 't1'
        }
    },

    t2 = {
        slot = 't2',

        cooldown = {
            slot = 't2',
        },
        
        --[[ has_cooldown = {
            slot = 't2',
        }, ]]

        stacking_stat = {
            slot = 't2'
        },
        has_stacking_stat = {
            slot = 't2'
        },

        stat = {
            slot = 't2'
        },
        has_stat = {
            slot = 't2',
        },
    },

    any = {},

    cooldown = {
    },
    has_cooldown = {
    },

    stacking_stat = {
    },
    has_stacking_stat = {
    },

    stacking_proc = {
    },
    has_stacking_proc = {
    },

    stat = {
    },
    has_stat = {
    }
}
state.trinket.proc = state.trinket.stat
state.trinket[1] = state.trinket.t1
state.trinket[2] = state.trinket.t2

state.using_apl = setmetatable( {}, {
    __index = function( t, k )
        return false
    end
} )


state.role = setmetatable( {}, {
    __index = function( t, k )
        return false
    end
} )

local mt_no_trinket_cooldown = {
}

local mt_no_trinket_stacking_stat = {
}

local mt_no_trinket_stat = {
}


local mt_no_trinket = {
    __index = function( t, k )
        if k:sub(1,4) == 'has_' then
            return false
        elseif k == 'down' then
            return true
        end

        return false
    end
}

local no_trinket = setmetatable( {
    slot = 'none',
    cooldown = setmetatable( {}, mt_no_trinket_cooldown ),
    stacking_stat = setmetatable( {}, mt_no_trinket_stacking_stat ),
    stat = setmetatable( {}, mt_no_trinket_stat )
}, mt_no_trinket )


state.trinket.stat.any = state.trinket.any


local mt_trinket_any = {
    __index = function( t, k )
        return state.trinket.t1[ k ] or state.trinket.t2[ k ]
    end
}

setmetatable( state.trinket.any, mt_trinket_any )

local mt_trinket_any_stacking_stat = {
    __index = function( t, k )
        if state.trinket.t1.has_stacking_stat[k] then return state.trinket.t1
            elseif state.trinket.t2.has_stacking_stat[k] then return state.trinket.t2 end
        return no_trinket
    end
}

setmetatable( state.trinket.stacking_stat, mt_trinket_any_stacking_stat )
setmetatable( state.trinket.stacking_proc, mt_trinket_any_stacking_stat )

local mt_trinket_any_stat = {
    __index = function( t, k )
        --[[ if k == 'any' then
        return ( state.trinket.has_stat[ 
    end ]]

        if state.trinket.t1.has_stat[k] then return state.trinket.t1
            elseif state.trinket.t2.has_stat[k] then return state.trinket.t2 end
        return no_trinket
    end
}

setmetatable( state.trinket.stat, mt_trinket_any_stat )


local mt_trinket = {
    __index = function( t, k )
        if k == 'up' or k == 'ticking' or k == 'active' then
            return class.trinkets[ t.id ].buff and state.buff[ class.trinkets[ t.id ].buff ].up or false
        elseif k == 'react' or k == 'stack' or k == 'stacks' then
            return class.trinkets[ t.id ].buff and state.buff[ class.trinkets[ t.id ].buff ][k] or 0
        elseif k == 'remains' then
            return class.trinkets[ t.id ].buff and state.buff[ class.trinkets[ t.id ].buff ].remains or 0
        elseif k == 'has_cooldown' then
            return GetItemSpell( t.id ) ~= nil
        end
        return false
    end
}

setmetatable( state.trinket.t1, mt_trinket )
setmetatable( state.trinket.t2, mt_trinket )


local mt_trinket_cooldown = {
    __index = function(t, k)
        if k == 'duration' or k == 'expires' then
            -- Refresh the ID in case we changed specs and ability is spec dependent.
            local start, duration = GetItemCooldown( state.trinket[ t.slot ].id )

            t.duration = duration or 0
            t.expires = start and ( start + duration ) or 0

            return t[k]

        elseif k == 'remains' then
            return max( 0, t.expires - ( state.query_time ) )

        elseif k == 'up' then
            return t.remains == 0

        elseif k == 'down' then
            return t.remains > 0

        end

        -- return Error( "UNK: " .. k )

    end
}

setmetatable( state.trinket.t1.cooldown, mt_trinket_cooldown )
setmetatable( state.trinket.t2.cooldown, mt_trinket_cooldown )


local mt_trinket_has_stacking_stat = {
    __index = function( t, k )
        local trinket = state.trinket[ t.slot ].id

        if trinket == 0 then return false end

        if k == 'any' then return class.trinkets[ trinket ].stacking_stat ~= nil end

        if k == 'ms' then k = 'multistrike' end

        return class.trinkets[ trinket ].stacking_stat == k
    end
}

setmetatable( state.trinket.t1.has_stacking_stat, mt_trinket_has_stacking_stat )
setmetatable( state.trinket.t2.has_stacking_stat, mt_trinket_has_stacking_stat )


local mt_trinket_has_stat = {
    __index = function( t, k )
        local trinket = state.trinket[ t.slot ].id

        if trinket == 0 then return false end

        if k == 'any' then return class.trinkets[ trinket ].stat ~= nil end

        if k == 'ms' then k = 'multistrike' end

        return class.trinkets[ trinket ].stat == k
    end
}

setmetatable( state.trinket.t1.has_stat, mt_trinket_has_stat )
setmetatable( state.trinket.t2.has_stat, mt_trinket_has_stat )


local mt_trinkets_has_stat = {
    __index = function( t, k )
        if k == 'ms' then k = 'multistrike' end

        if k == 'any' then
            return class.trinkets[ state.trinket.t1.id ].stat ~= nil or class.trinkets[ state.trinket.t2.id ].stat ~= nil
        end

        return class.trinkets[ state.trinket.t1.id ].stat == k or class.trinkets[ state.trinket.t2.id ].stat == k
    end
}

setmetatable( state.trinket.has_stat, mt_trinkets_has_stat )


local mt_trinkets_has_stacking_stat = {
    __index = function( t, k )
        if k == 'ms' then k = 'multistrike' end

        if k == 'any' then
            return class.trinkets[ state.trinket.t1.id ].stacking_stat ~= nil or class.trinkets[ state.trinket.t2.id ].stacking_stat ~= nil
        end

        return class.trinkets[ state.trinket.t1.id ].stacking_stat == k or class.trinkets[ state.trinket.t2.id ].stacking_stat == k
    end
}

setmetatable( state.trinket.has_stacking_stat, mt_trinkets_has_stacking_stat )


state.max = safeMax
state.min = safeMin
state.print = print

state.Enum = Enum
state.FindUnitBuffByID = ns.FindUnitBuffByID
state.FindUnitDebuffByID = ns.FindUnitDebuffByID
state.GetItemCooldown = GetItemCooldown
state.GetItemCount = GetItemCount
state.GetItemGem = GetItemGem
state.GetShapeshiftForm = GetShapeshiftForm
state.GetShapeshiftFormInfo = GetShapeshiftFormInfo
state.GetSpellCount = GetSpellCount
state.GetSpellInfo = GetSpellInfo
state.GetSpellTexture = GetSpellTexture
state.GetStablePetInfo = GetStablePetInfo
state.GetTime = GetTime
state.GetTotemInfo = GetTotemInfo
state.IsActiveSpell = ns.IsActiveSpell
state.IsPlayerSpell = IsPlayerSpell
state.IsSpellKnown = IsSpellKnown
state.IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown
state.IsUsableItem = IsUsableItem
state.IsUsableSpell = IsUsableSpell
state.UnitBuff = UnitBuff
state.UnitCanAttack = UnitCanAttack
state.UnitCastingInfo = UnitCastingInfo
state.UnitChannelInfo = UnitChannelInfo
state.UnitClassification = UnitClassification
state.UnitDebuff = UnitDebuff
state.UnitExists = UnitExists
state.UnitHealth = UnitHealth
state.UnitHealthMax = UnitHealthMax
state.UnitName = UnitName
state.UnitIsFriend = UnitIsFriend
state.UnitIsUnit = UnitIsUnit
state.UnitIsPlayer = UnitIsPlayer
state.UnitLevel = UnitLevel
state.UnitPower = UnitPower
state.UnitPowerMax = UnitPowerMax
state.abs = math.abs
state.ceil = math.ceil
state.floor = math.floor
state.format = string.format
state.ipairs = ipairs
state.pairs = pairs
state.rawget = rawget
state.rawset = rawset
state.select = select
state.tinsert = table.insert
state.insert = table.insert
state.remove = table.remove
state.tonumber = tonumber
state.tostring = tostring
state.type = type

state.safenum = function( val )
    if type( val ) == "number" then return val end
    return val == true and 1 or 0
end

state.safebool = function( val )
    if type( val ) == "boolean" then return val end
    return val ~= 0 and true or false
end

state.combat = 0
state.faction = UnitFactionGroup( 'player' )
state.race[ formatKey( UnitRace('player') ) ] = true

state.class = Hekili.Class
state.targets = ns.targets

state._G = 0


-- Place an ability on cooldown in the simulated game state.
local function setCooldown( action, duration )
    local cd = state.cooldown[ action ] or {}
    cd.duration = duration
    cd.expires = state.query_time + duration

    cd.charge = 0
    cd.recharge_began = state.query_time
    cd.next_charge = cd.expires
    cd.recharge = duration

    state.cooldown[ action ] = cd
end
state.setCooldown = setCooldown


local function spendCharges( action, charges )
    local ability = class.abilities[ action ]

    if not ability.charges or ability.charges == 1 then
        setCooldown( action, ability.cooldown )
        return
    end

    if not state.cooldown[ action ] then state.cooldown[ action ] = {} end
    local cd = state.cooldown[ action ]

    if cd.next_charge <= state.query_time then
        cd.recharge_began = state.query_time
        cd.next_charge = state.query_time + ( ability.recharge or ability.cooldown )
        cd.recharge = ability.recharge
    end

    cd.charge = max( 0, cd.charge - charges )

    if cd.charge == 0 then
        cd.duration = ability.recharge or ability.cooldown
        cd.expires = cd.next_charge
    else
        cd.duration = 0
        cd.expires = 0
    end
end
state.spendCharges = spendCharges


local function gainCharges( action, charges )

    if class.abilities[ action ].charges then
        state.cooldown[ action ].charge = min( class.abilities[ action ].charges, state.cooldown[ action ].charge + charges )

        -- resolve cooldown state.
        if state.cooldown[ action ].charge > 0 then
            state.cooldown[ action ].duration = 0
            state.cooldown[ action ].expires = 0
        end

        if state.cooldown[ action ].charge == class.abilities[ action ].charges then
            state.cooldown[ action ].next_charge = 0
            state.cooldown[ action ].recharge = 0
            state.cooldown[ action ].recharge_began = 0
        end

    else
        -- Error-proof gaining charges for abilities without charges.
        if charges >= 1 then
            setCooldown( action, 0 )
        end
    end

end
state.gainCharges = gainCharges


function state.gainChargeTime( action, time, debug )    
    local ability = class.abilities[ action ]    
    if not ability then return end

    local cooldown = state.cooldown[ action ]

    if not ability.charges then
        -- Error-proof gaining charge time on chargeless abilities.
        cooldown.expires = cooldown.expires - time
        return
    end

    if cooldown.charge == ability.charges then return end

    cooldown.next_charge = cooldown.next_charge - time
    cooldown.expires = cooldown.expires - time

    if cooldown.next_charge <= state.query_time then
        cooldown.charge = min( ability.charges, cooldown.charge + 1 )

        -- We have a charge, reset cooldown.
        -- cooldown.duration = 0
        cooldown.expires = 0

        if cooldown.charge == ability.charges then
            cooldown.next_charge = 0
            cooldown.recharge = 0
            cooldown.recharge_began = 0
        else
            cooldown.recharge_began = cooldown.next_charge
            cooldown.next_charge = cooldown.next_charge + ability.recharge
            cooldown.recharge = cooldown.next_charge - ( state.query_time + time )
        end    
    end
end


function state.reduceCooldown( action, time )
    local ability = class.abilities[ action ]
    if not ability then return end

    if ability.charges then
        state.gainChargeTime( action, time )
        return
    end

    cooldown[ action ].expires = cooldown[ action ].expires - time
end


-- Cycling System...
do
    local cycle = {}
    local debug = function( ... ) if Hekili.ActiveDebug then Hekili:Debug( ... ) end end

    function state.SetupCycle( ability )
        wipe( cycle )

        if not ability then
            debug( " - no ability provided to SetupCycle." )
            return
        end

        local aura = ability.cycle
        
        if not aura then
            -- Fallback check, is there an aura with the same name as the ability?
            aura = class.auras[ ability.key ] and ability.key
        end

        if not aura then
            debug( " - no aura identified for target-cycling and no aura matching " .. ability.key .. " found in ability / spec module; target cycling disabled." )
            return
        end

        local cDebuff = rawget( state.debuff, aura )

        if not cDebuff then
            debug( " - the debuff '%s' was not found in our database.", aura )
            return
        end

        cycle.expires = cDebuff.expires
        cycle.minTTD  = max( state.settings.cycle_min, ability.min_ttd or 0 )
        cycle.maxTTD  = ability.max_ttd

        cycle.aura = aura
        debug( " - we will use the ability on a different target, if available, until %s expires at %.2f [+%.2f].", cycle.aura, cycle.expires, cycle.expires - state.query_time )
    end

    function state.IsCycling( aura )
        if not cycle.aura then return false end
        if aura and cycle.aura ~= aura then return false end
        if state.active_enemies == 1 then return false end
        if cycle.expires < state.query_time then return false end        

        local targets = state.active_enemies

        if cycle.minTTD then targets = min( targets, Hekili:GetNumTTDsAfter( cycle.minTTD + state.delay + state.offset ) ) end
        if cycle.maxTTD then targets = min( targets, Hekili:GetNumTTDsBefore( cycle.maxTTD + state.delay + state.offset ) ) end

        return state.active_dot[ cycle.aura ] < targets
    end

    function state.ClearCycle()
        if cycle.aura then wipe( cycle ) end
    end

    state.cycleInfo = cycle
end


-- Apply a buff to the current game state.
local function applyBuff( aura, duration, stacks, value )
    if not aura then
        Error( "Attempted to apply/remove a nameless aura '%s'.", aura or "nil" )
        return
    end

    local auraInfo = class.auras[ aura ]

    if not auraInfo then
        local spec = class.specs[ state.spec.id ]
        if spec then
            spec:RegisterAura( aura, { duration = duration } )
            class.auras[ aura ] = spec.auras[ aura ]
            -- Hekili:SpecializationChanged()
        end
        
        auraInfo = class.auras[ aura ]
        if not auraInfo then return end
    end

    if auraInfo.alias then
        aura = auraInfo.alias[1]
    end

    if state.cycle then
        if duration == 0 then state.active_dot[ aura ] = state.active_dot[ aura ] - 1
        else state.active_dot[ aura ] = state.active_dot[ aura ] + 1 end
        return
    end

    local b = state.buff[ aura ]
    if not b then return end
    if not duration then duration = class.auras[ aura ].duration or 15 end

    if duration == 0 then
        b.last_expiry = b.expires or 0
        b.expires = 0

        b.lastCount = b.count
        b.count = 0

        b.lastApplied = b.applied
        b.last_application = b.applied or 0

        b.v1 = 0
        b.applied = 0
        b.caster = 'unknown'

        state.active_dot[ aura ] = max( 0, state.active_dot[ aura ] - 1 )

    else
        if not b.up then state.active_dot[ aura ] = state.active_dot[ aura ] + 1 end

        b.lastCount = b.count
        b.lastApplied = b.applied

        -- state.buff[ aura ] = state.buff[ aura ] or {}
        b.expires = state.query_time + duration
        b.last_expiry = b.expires

        b.applied = state.query_time
        b.last_application = b.applied or 0

        b.count = min( class.auras[ aura ].max_stack or 1, stacks or 1 )
        b.v1 = value or 0
        b.caster = 'player'
    end

    if aura == 'heroism' or aura == 'time_warp' or aura == 'ancient_hysteria' then
        applyBuff( 'bloodlust', duration, stacks, value )
    elseif aura ~= 'potion' and class.auras.potion and class.auras[ aura ].id == class.auras.potion.id then
        applyBuff( 'potion', duration, stacks, value )
    end
end
state.applyBuff = applyBuff


local function removeBuff( aura )
    applyBuff( aura, 0 )

    local auraInfo = class.auras[ aura ]
    if auraInfo and auraInfo.alias then
        for _, child in ipairs( auraInfo.alias ) do
            applyBuff( child, 0 )
        end
    end    
end
state.removeBuff = removeBuff


-- Apply stacks of a buff to the current game state.
-- Wraps around Buff() to check for an existing buff.
local function addStack( aura, duration, stacks, value )

    local a = class.auras[ aura ]

    duration = duration or ( a and a.duration or 15 )
    stacks = stacks or 1

    local max_stack = a and a.max_stack or 1

    local b = state.buff[ aura ]

    if b.remains > 0 then
        applyBuff( aura, duration, min( max_stack, b.count + stacks ), value )
    else
        applyBuff( aura, duration, min( max_stack, stacks ), value )
    end

end
state.addStack = addStack


local function removeStack( aura, stacks )
    stacks = stacks or 1

    local b = state.buff[ aura ]

    if b.count > stacks then
        b.lastCount = b.count
        b.count = max( 1, b.count - stacks )
    else
        removeBuff( aura )
    end
end
state.removeStack = removeStack


-- Add a debuff to the simulated game state.
-- Needs to actually use 'unit' !
local function applyDebuff( unit, aura, duration, stacks, value )
    if not aura then aura = unit; unit = "target" end

    if not class.auras[ aura ] then
        Error( "Attempted to apply unknown aura '%s'.", aura ) 
        local spec = class.specs[ state.spec.id ]
        if spec then
            spec:RegisterAura( aura, { duration = duration } )
            class.auras[ aura ] = spec.auras[ aura ]
            -- Hekili:SpecializationChanged()
        end

        if not class.auras[ aura ] then return end
    end

    if state.cycle then
        if duration == 0 then state.active_dot[ aura ] = state.active_dot[ aura ] - 1
    else state.active_dot[ aura ] = state.active_dot[ aura ] + 1 end
        return
    end

    local d = state.debuff[ aura ]
    duration = duration or class.auras[ aura ].duration or 15

    if duration == 0 then
        d.expires = 0

        d.lastCount = d.count
        d.lastApplied = d.lastApplied

        d.count = 0
        d.value = 0
        d.applied = 0
        d.unit = unit

        state.active_dot[ aura ] = max( 0, state.active_dot[ aura ] - 1 )
    else
        if d.down then state.active_dot[ aura ] = state.active_dot[ aura ] + 1 end

        -- state.debuff[ aura ] = state.debuff[ aura ] or {}
        d.expires = state.query_time + duration

        d.lastCount = d.count or 0
        d.lastApplied = d.applied or 0

        d.count = min( class.auras[ aura ].max_stack or 1, stacks or 1 )
        d.value = value or 0
        d.applied = state.now
        d.unit = unit or 'target'
    end

end
state.applyDebuff = applyDebuff


local function removeDebuff( unit, aura )    
    applyDebuff( unit, aura, 0 )        
end
state.removeDebuff = removeDebuff


local function setStance( stance )
    for k in pairs( state.stance ) do
        state.stance[ k ] = false
    end
    state.stance[ stance ] = true
end
state.setStance = setStance


local function interrupt()
    removeDebuff( 'target', 'casting' )
end
state.interrupt = interrupt


-- Use this for readyTime in an interrupt action; will interrupt casts at end of cast and channels ASAP.
local function timeToInterrupt()
    if debuff.casting.down or debuff.casting.v2 then return 3600 end
    if debuff.casting.v3 then return 0 end
    return debuff.casting.remains - 0.25
end
state.timeToInterrupt = timeToInterrupt


-- Pet stuff.
local function summonPet( name, duration, spec )
    state.pet[ name ] = rawget( state.pet, name ) or {}
    state.pet[ name ].name = name
    state.pet[ name ].expires = state.query_time + ( duration or 3600 )

    if class.pets[ name ] then
        state.pet[ name ].id = id
    end

    if spec then
        state.pet[ name ].spec = spec

        for k, v in pairs( state.pet ) do
            if type(v) == 'boolean' then state.pet[k] = false end
        end

        state.pet[ spec ] = state.pet[ name ]
    end
end
state.summonPet = summonPet


local function dismissPet( name )

    state.pet[ name ] = rawget( state.pet, name ) or {}
    state.pet[ name ].name = name
    state.pet[ name ].expires = 0


end
state.dismissPet = dismissPet


local function summonTotem( name, elem, duration )

    if elem then
        state.totem[ elem ] = rawget( state.totem, elem ) or {}
        state.totem[ elem ].name = name
        state.totem[ elem ].expires = state.query_time + duration
    end

    summonPet( name, duration )
    summonPet( elem, duration )    
end
state.summonTotem = summonTotem


-- Useful for things like leap/charge/etc.
local function setDistance( minimum, maximum )
    state.target.minR = minimum or 5
    state.target.maxR = maximum or minimum or 5
    state.target.distance = ( state.target.minR + state.target.maxR ) / 2
end
state.setDistance = setDistance


-- For tracking if we are currently channeling.
function state.channelSpell( name, start, duration, id )
    if name then
        local ability = class.abilities[ name ]

        start = start or state.query_time

        if ability then
            duration = duration or ability.cast
        end

        if not duration then return end

        state.player.channelSpell = name
        state.player.channelStart = start
        state.player.channelEnd = start + duration

        applyBuff( "casting", duration, nil, id or ( ability and ability.id ) or 0 )
        state.buff.casting.applied = start
        state.buff.casting.expires = start + duration
        -- state.buff.casting.v3 = true
    end
end

function state.stopChanneling( reset )

    if not reset then
        local spell = state.player.channelSpell
        local ability = spell and class.abilities[ spell ]

        if ability and ability.breakchannel then ability.breakchannel() end
    end

    state.player.channelSpell = nil
    state.player.channelStart = 0
    state.player.channelEnd   = 0
    removeBuff( "casting" )
end

-- See mt_state for 'isChanneling'.



-- Spell Targets, so I don't have to convert it in APLs any more.
-- This will also factor in target caps and TTD restrictions.
state.spell_targets = setmetatable( {}, {
    __index = function( t, k )
        local ability = class.abilities[ k ]

        if not ability or state.active_enemies == 1 then return state.active_enemies end
        
        local n = state.active_enemies

        if ability.max_targets then n = min( n, ability.max_targets ) end
        if ability.max_ttd then n = min( n, Hekili:GetNumTTDsBefore( ability.max_ttd + state.offset + state.delay ) ) end
        if ability.min_ttd then n = min( n, Hekili:GetNumTTDsAfter( ability.min_ttd + state.offset + state.delay ) ) end

        return n
    end 
} )


local raid_event_filter = {
    ["in"] = 3600,
    amount = 0,
    duration = 0,
    remains = 0,
    cooldown = 0,
    exists = false,
    distance = 0,
    max_distance = 0,
    min_distance = 0,
    to_pct = 0,
    up = false,
    down = true
}

state.raid_event = setmetatable( {}, {
    __index = function( t, k )
        return raid_event_filter[ k ] or raid_event_filter
    end
} )


-- We'll pretend we're in an active raid_event.adds when there are multiple targets.
state.raid_event.adds = setmetatable( {
    ["in"] = 3600, -- raid_event.adds.in appears to return time to the next add event, so we can just always say it's waaaay in the future.
}, {
    __index = function( t, k )
        if k == "up" or k == "exists" then
            return state.active_enemies > 1
        elseif k == "down" then
            return state.active_enemies <= 1
        elseif k == "in" then
            return state.active_enemies > 1 and 0 or 3600
        elseif k == "duration" or k == "remains" then
            return state.active_enemies > 1 and state.target.time_to_die or 0
        elseif raid_event_filter[k] ~= nil then return raid_event_filter[k] end

        return 0
    end
} )


-- Resource Modeling!
local events = {}
local remains = {}

local function resourceModelSort( a, b )
    return b == nil or ( a.next < b.next )
end


local FORECAST_DURATION = 10.01

local function forecastResources( resource )
    if not resource then return end

    wipe( events )
    wipe( remains )

    local now = state.now + state.offset -- roundDown( state.now + state.offset, 2 )

    local timeout = FORECAST_DURATION * state.haste -- roundDown( FORECAST_DURATION * state.haste, 2 )
    if state.class.file == "DEATHKNIGHT" and state.runes then
        timeout = max( timeout, 0.01 + 2 * state.runes.cooldown )
    end       

    local r = state[ resource ]

    -- We account for haste here so that we don't compute lots of extraneous future resource gains in Bloodlust/high haste situations.
    remains[ resource ] = timeout

    wipe( r.times )
    wipe( r.values )
    r.forecast[1] = r.forecast[1] or {}
    r.forecast[1].t = now
    r.forecast[1].v = r.actual
    r.forecast[1].e = "actual"
    r.fcount = 1

    local models = r.regenModel

    if models then
        for k, v in pairs( models ) do
            if  ( not v.resource  or v.resource == resource ) and
                ( not v.spec      or state.spec[ v.spec ] ) and
                ( not v.equip     or state.equipped[ v.equip ] ) and 
                ( not v.talent    or state.talent[ v.talent ].enabled ) and
                ( not v.pvptalent or state.pvptalent[ v.pvptalent ].enabled ) and
                ( not v.aura      or state[ v.debuff and 'debuff' or 'buff' ][ v.aura ].remains > 0 ) and
                ( not v.set_bonus or state.set_bonus[ v.set_bonus ] > 0 ) and
                ( not v.setting   or state.settings[ v.setting ] ) then

                local r = state[ v.resource ]

                local l = v.last()
                local i = type( v.interval ) == 'number' and v.interval or ( type( v.interval ) == 'function' and v.interval( now, r.actual ) or ( type( v.interval ) == 'string' and state[ v.interval ] or 0 ) )
                -- local i = roundDown( type( v.interval ) == 'number' and v.interval or ( type( v.interval ) == 'function' and v.interval( now, r.actual ) or ( type( v.interval ) == 'string' and state[ v.interval ] or 0 ) ), 2 )

                v.next = l + i
                v.name = k

                if i > 0 and v.next >= 0 then
                    table.insert( events, v )
                end
            end
        end
    end

    sort( events, resourceModelSort )

    local finish = now + timeout

    local prev = now
    local iter = 0

    while( #events > 0 and now <= finish and iter < 20 ) do
        local e = events[1]
        local r = state[ e.resource ]
        iter = iter + 1

        if e.next > finish or not r or not r.actual then
            table.remove( events, 1 )

        else
            now = e.next

            local bonus = r.regen * ( now - prev )

            if ( e.stop and e.stop( r.forecast[ r.fcount ].v ) ) or ( e.aura and state[ e.debuff and 'debuff' or 'buff' ][ e.aura ].expires < now ) then
                table.remove( events, 1 )

                local v = max( 0, min( r.max, r.forecast[ r.fcount ].v + bonus ) )
                local idx

                if r.forecast[ r.fcount ].t == now then
                    -- Reuse the last one.
                    idx = r.fcount
                else
                    idx = r.fcount + 1
                end

                r.forecast[ idx ] = r.forecast[ idx ] or {}
                r.forecast[ idx ].t = now
                r.forecast[ idx ].v = v
                r.forecast[ idx ].e = e.name or 'none'
                r.fcount = idx
            else
                prev = now

                local val = r.fcount > 0 and r.forecast[ r.fcount ].v or r.actual

                local v = max( 0, min( r.max, val + bonus ) )
                v = max( 0, min( r.max, v + ( type( e.value ) == 'number' and e.value or e.value( now ) ) ) )

                local idx

                if r.forecast[ r.fcount ].t == now then
                    -- Reuse the last one.
                    idx = r.fcount
                else
                    idx = r.fcount + 1
                end

                r.forecast[ idx ] = r.forecast[ idx ] or {}
                r.forecast[ idx ].t = now
                r.forecast[ idx ].v = v
                r.forecast[ idx ].e = e.name or 'none'
                r.fcount = idx

                -- interval() takes the last tick and the current value to remember the next step.
                local step = roundUp( type( e.interval ) == 'number' and e.interval or ( type( e.interval ) == 'function' and e.interval( now, v ) or ( type( e.interval ) == 'string' and state[ e.interval ] or 0 ) ), 2 )

                remains[ e.resource ] = finish - e.next
                e.next = e.next + step

                if e.next > finish or step < 0 then
                    table.remove( events, 1 )
                end
            end
        end

        if #events > 1 then sort( events, resourceModelSort ) end
    end

    if r.regen > 0 and r.forecast[ r.fcount ].v < r.max then
        for k, v in pairs( remains ) do
            local r = state[ k ]
            local val = r.fcount > 0 and r.forecast[ r.fcount ].v or r.actual
            local idx = r.fcount + 1

            r.forecast[ idx ] = r.forecast[ idx ] or {}
            r.forecast[ idx ].t = finish
            r.forecast[ idx ].v = min( r.max, val + ( v * r.regen ) )
            r.fcount = idx
        end
    end
end
ns.forecastResources = forecastResources
state.forecastResources = forecastResources

Hekili:ProfileCPU( "forecastResources", forecastResources )


local resourceChange = function( amount, resource, overcap )
    if amount == 0 then return false end

    local r = state[ resource ]
    local pre = r.current

    if amount < 0 and r.spend then r.spend( -amount, resource, overcap )
    elseif amount > 0 and r.gain then r.gain( amount, resource, overcap )
    else
        r.actual = max( 0, r.current + amount )
        if not overcap then r.actual = min( r.max, r.actual ) end
    end

    return true
end


-- Noteworthy hooks for gain/spend:
-- pregain - the hook is expected to return modified values for the resource (i.e., special cost reduction or refunds).
-- gain    - the hook can do whatever it wants, but if it changes the same resource again it will cause another forecast.

local gain = function( amount, resource, overcap )
    amount, resource, overcap = ns.callHook( "pregain", amount, resource, overcap )
    resourceChange( amount, resource, overcap )
    if resource ~= "health" then forecastResources( resource ) end
    ns.callHook( "gain", amount, resource, overcap )
end

local rawGain = function( amount, resource, overcap )
    resourceChange( amount, resource, overcap )
    forecastResources( resource )
end


local spend = function( amount, resource, clean )
    amount, resource = ns.callHook( "prespend", amount, resource )
    resourceChange( -amount, resource, overcap )
    if resource ~= "health" then forecastResources( resource ) end
    ns.callHook( "spend", amount, resource, overcap, true )
end

local rawSpend = function( amount, resource )
    resourceChange( -amount, resource, overcap )
    forecastResources( resource )
end


state.gain = gain
state.rawGain = rawGain

state.spend = spend
state.rawSpend = rawSpend


do
    -- Rechecking System
    -- Setup on a per-ability basis, this gives the prediction engine a head's up that the ability may become ready in a short time.

    state.recheckTimes = {}

    local function recheckHelper( t, ... )
        local n = select( "#", ... )

        for i = 1, n do
            local x = select( i, ... )
            if type( x ) == "number" and x > state.delayMin and x < state.delayMax then
                table.insert( t, roundUp( x, 2 ) )
            end
        end
    end


    local function channelInfo( ability )
        if state.system.packName and scripts.Channels[ state.system.packName ] then
            return scripts.Channels[ state.system.packName ][ state.player.channelSpell ], class.auras[ state.player.channelSpell ]
        end
    end


    function state.recheck( ability, script, stack )
        local times = state.recheckTimes
        wipe( times )

        local debug = Hekili.ActiveDebug

        if script then
            if script.Recheck then
                recheckHelper( times, script.Recheck() )
            end

            if script.Variables then
                for i, var in ipairs( script.Variables ) do
                    local varIDs = state:GetVariableIDs( var )

                    if varIDs then
                        for _, entry in ipairs( varIDs ) do
                            local vr = scripts.DB[ entry.id ].VarRecheck
                            if vr then recheckHelper( times, vr() ) end
                        end
                    end
                end
            end
        end

        local data = class.abilities[ ability ]
        if data and data.aura then
            local a = state.buff[ data.aura ]
            if a and a.up then
                recheckHelper( times, a.remains )
            end

            a = state.debuff[ data.aura ]
            if a and a.up then
                recheckHelper( times, a.remains )
            end
        end

        if stack and #stack > 0 then
            for i, caller in ipairs( stack ) do
                local callScript = caller.script
                callScript = callScript and scripts:GetScript( callScript )

                if callScript and callScript.Recheck then
                    recheckHelper( times, callScript.Recheck() )
                end
            end
        end

        if state.channeling then
            local aura = class.auras[ state.channel ]
            local remains = state.channel_remains

            if aura and aura.tick_time then
                -- Put tick times into recheck.
                local i = 1
                while ( true ) do
                    if remains - ( i * aura.tick_time ) > 0 then table.insert( times, roundUp( remains - ( i * aura.tick_time ), 2 ) )
                    else break end
                    i = i + 1
                end

                for i = #times, 1, -1 do
                    local time = times[ i ]

                    if ( ( remains - time ) / aura.tick_time ) % 1 <= 0.5 then
                        table.remove( times, i )
                    end
                end
            end

            table.insert( times, remains )
        end

        sort( times )
    end
end



--------------------------------------
-- UGLY METATABLES BELOW THIS POINT --
--------------------------------------
ns.metatables = {}
local metafunctions = {
    action = {},
    active_dot = {},
    buff = {},
    cooldown = {},
    debuff = {},
    default_action = {},
    default_aura = {},
    default_cooldown = {},
    default_debuff = {},
    default_pet = {},
    default_totem = {},
    perk = {},
    pet = {},
    resource = {},
    set_bonus = {},
    settings = {},
    spec = {},
    stance = {},
    stat = {},
    state = {},
    talent = {},
    target = {},
    target_health = {},
    toggle = {},
    totem = {},
}

ns.addMetaFunction = function( t, k, func )

    if metafunctions[ t ] then
        metafunctions[ t ][ k ] = setfenv( func, state )
        return
    end

    Error( "addMetaFunction() - no such table '" .. t .. "' for key '" .. k .. "'." )

end


-- Returns false instead of nil when a key is not found.
local mt_false = {
    __index = function(t, k)
        return false
    end
}
ns.metatables.mt_false = mt_false


do
    local a = class.knownAuraAttributes

    -- Populate table of known aura attributes so we know if we should bother looking in buffs/debuffs for this information.

    a.applied = true
    a.caster = true
    a.cooldown_remains = true
    a.count = true
    a.down = true
    a.duration = true
    a.expires = true
    a.i_up = true
    a.id = true
    a.key = true
    a.lastApplied = true
    a.lastCount = true
    a.last_application = true
    a.last_expiry = true
    a.max_stack = true
    a.max_stacks = true
    a.mine = true
    a.name = true
    a.rank = true
    a.react = true
    a.refreshable = true
    a.remains = true
    a.stack = true
    a.stack_pct = true
    a.stacks = true
    a.tick_time_remains = true
    a.ticking = true
    a.ticks = true
    a.ticks_remain = true
    a.time_to_refresh = true
    a.timeMod = true
    a.unit = true
    a.up = true
    a.v1 = true
    a.v2 = true
    a.v3 = true
end    


-- Gives calculated values for some state options in order to emulate SimC syntax.
local mt_state = {
    __index = function( t, k )

        if metafunctions.state[ k ] then
            return metafunctions.state[ k ]()

        elseif class.stateExprs[ k ] then
            return class.stateExprs[ k ]()

        elseif k == "display" then
            return "Primary"

        elseif k == "scriptID" then
            return "NilScriptID"
        
        elseif k == "resetting" then
            return false

        -- First, any values that don't reference an ability or aura.
        elseif k == 'this_action' then
            return 'wait'
        
        elseif k == 'current_action' then
            return 'this_action'

        elseif k == 'cast_target' then
            return 'nobody'

        elseif k == 'delay' then
            return 0

        elseif k == 'whitelist' then
            return nil
        
        elseif k == 'selection' then
            return t.selectionTime < 60

        elseif k == 'selectionTime' then
            return 60

        elseif k == 'desired_targets' then
            return 1

        elseif k == 'inEncounter' or k == 'encounter' then
            return t.encounterID > 0
        
        elseif k == 'mounted' or k == 'is_mounted' then
            return IsMounted()

        elseif k == 'boss' then
            return ( t.encounterID > 0 or ( UnitCanAttack( "player", "target" ) and ( UnitClassification( "target" ) == "worldboss" or UnitLevel( "target" ) == -1 ) ) ) == true

        elseif k == 'cycle' then
            return false

        elseif k == 'hardcast' then
            return false -- will set to true if/when a spell is hardcast.

        elseif k == 'channeling' then
            return t.player.channelSpell ~= nil and t.player.channelEnd >= t.query_time

        elseif k == 'channel' then
            return t.channeling and t.player.channelSpell or nil

        elseif k == 'channel_remains' then
            return t.channeling and ( t.player.channelEnd - t.query_time ) or 0

        elseif k == 'ranged' then
            return false

        elseif k == 'wait_for_gcd' then 
            -- For specs that have to weave a lot of off GCD stuff.
            -- i.e., Frost DK.
            return false

        elseif k == 'query_time' then
            return t.now + t.offset + t.delay

        elseif k == 'time_to_die' then
            if not t.boss then return 3600 end
            return max( 1, Hekili:GetGreatestTTD() - ( t.offset + t.delay ) )
        
        elseif k:sub(1, 12) == "time_to_pct_" then
            local percent = tonumber( k:sub( 13 ) ) or 0
            return Hekili:GetGreatestTimeToPct( percent ) - ( t.offset + t.delay )

        elseif k == "expected_combat_length" then
            if not t.boss then return 3600 end
            return Hekili:GetGreatestTTD() + t.time -- + t.offset + t.delay

        elseif k == 'moving' then
            return ( GetUnitSpeed('player') > 0 )

        elseif k == 'group' then
            return GetNumGroupMembers() > 1

        elseif k == 'group_members' then
            return max( 1, GetNumGroupMembers() )

        elseif k == 'raid' then
            return IsInRaid() and t.group_members > 5

        elseif k == 'level' then
            return ( UnitLevel('player') or MAX_PLAYER_LEVEL )

        elseif k == 'active' then
            return false

        elseif k == 'active_enemies' then
            t[k] = ns.getNumberTargets()

            if t.min_targets > 0 then t[k] = max( t.min_targets, t[k] ) end
            if t.max_targets > 0 then t[k] = min( t.max_targets, t[k] ) end

            t[k] = max( 1, t[k] )

            return t[k]

        elseif k == 'my_enemies' then
            -- The above is not needed as the nameplate target system will add missing enemies.
            t[k] = ns.numTargets()

            if t.min_targets > 0 then t[k] = max( t.min_targets, t[k] ) end
            if t.max_targets > 0 then t[k] = min( t.max_targets, t[k] ) end

            t[k] = max( 1, t[k] )

            return t[k]

        elseif k == 'true_active_enemies' then
            t[k] = max( 1, ns.getNumberTargets() )
            return t[k]

        elseif k == 'true_my_enemies' then
            t[k] = max( 1, ns.numTargets() )
            return t[k]

        elseif k == 'haste' or k == 'spell_haste' then
            return ( 1 / ( 1 + t.stat.spell_haste ) )

        elseif k == 'melee_haste' then
            return ( 1 / ( 1 + t.stat.melee_haste ) )

        elseif k == 'mastery_value' then
            return ( GetMasteryEffect() / 100 )

        elseif k == 'miss_react' then
            return false

        elseif k == 'cooldown_react' or k == 'cooldown_up' then
            return t.cooldown[ t.this_action ].remains == 0

        elseif k == 'cast_delay' then return 0

        elseif k == 'in_flight' then
            local data = t.action[ t.this_action ]
            if data and data.flightTime then
                return data.lastCast + data.flightTime - query_time > 0
            end

            return state:IsInFlight( t.this_action )

        elseif k == 'in_flight_remains' then
            local data = t.action[ t.this_action ]
            if data and data.flightTime then
                return max( 0, data.lastCast + data.flightTime - query_time )
            end

            return state:InFlightRemains( t.this_action )

        elseif k == 'executing' then
            return state:IsCasting( t.this_action ) or ( state.prev[1][ t.this_action ] and state.gcd.remains > 0 )

        elseif k == 'execute_remains' then
            return ( state:IsCasting( t.this_action ) and max( state:QueuedCastRemains( t.this_action ), state.gcd.remains ) ) or ( state.prev[1][ t.this_action ] and state.gcd.remains ) or 0

        elseif k == 'prowling' then
            return t.buff.prowl.up or ( t.buff.cat_form.up and t.buff.shadowform.up )        

        elseif type(k) == 'string' and k:sub(1, 16) == 'incoming_damage_' then
            local remains = k:sub(17)
            local time = remains:match("^(%d+)[m]?s")

            if not time then
                return 0
                -- Error("ERR: " .. remains )
            end

            time = tonumber( time )

            if time > 100 then
                t[k] = ns.damageInLast( time / 1000 )
            else
                t[k] = ns.damageInLast( min( 15, time ) )
            end

            table.insert( t.purge, k )
            return t[ k ]

        elseif type(k) == 'string' and k:sub(1, 18) == 'incoming_physical_' then
            local remains = k:sub(19)
            local time = remains:match("^(%d+)[m]?s")

            if not time then
                return 0
                -- Error("ERR: " .. remains )
            end

            time = tonumber( time )

            if time > 100 then
                t[k] = ns.damageInLast( time / 1000, true )
            else
                t[k] = ns.damageInLast( min( 15, time ), true )
            end

            table.insert( t.purge, k )
            return t[ k ]

        elseif type(k) == 'string' and k:sub(1, 15) == 'incoming_magic_' then
            local remains = k:sub(16)
            local time = remains:match("^(%d+)[m]?s")

            if not time then
                return 0
                -- Error("ERR: " .. remains )
            end

            time = tonumber( time )

            if time > 100 then
                t[k] = ns.damageInLast( time / 1000, false )
            else
                t[k] = ns.damageInLast( min( 15, time ), false )
            end

            table.insert( t.purge, k )
            return t[ k ]

        elseif type(k) == 'string' and k:sub(1, 14) == 'incoming_heal_' then
            local remains = k:sub(15)
            local time = remains:match("^(%d+)[m]?s")

            if not time then
                return 0
                -- Error("ERR: " .. remains) 
            end

            time = tonumber( time )

            if time > 100 then
                t[ k ] = ns.healingInLast( time / 1000 )
            else
                t[ k ] = ns.healingInLast( min( 15, time ) )
            end

            table.insert( t.purge, k )
            return t[ k ]

        end

        -- The next block are values that reference an ability.
        local action = t.this_action
        local ability = class.abilities[ action ]

        if k == 'time' then
            -- Calculate time in combat.
            if t.combat == 0 and t.false_start == 0 then return 0 end

            local start = t.combat > 0 and t.combat or ( t.false_start > 0 and t.false_start or t.query_time )
            return t.query_time - start

        elseif k == 'cast_time' then
            return ability and ability.cast or 0

        elseif k == 'execute_time' then
            return max( state.gcd.execute, ability and ability.cast or 0 )

        elseif k == 'travel_time' then 
            local v = ability.velocity or 0
            if v > 0 then
                return t.target.maxR / v
            end
            return 0
        
        elseif k == 'action_cooldown' then
            return ability and ability.cooldown or 0

        elseif k == 'charges' then
            return t.cooldown[ action ].charges

        elseif k == 'charges_fractional' then
            return t.cooldown[ action ].charges_fractional

        elseif k == 'time_to_max_charges' or k == 'full_recharge_time' then
            return t.cooldown[ action ].full_recharge_time

        elseif k == 'max_charges' or k == 'charges_max' then
            return ability and ability.charges or 1

        elseif k == 'recharge' then
            -- TODO: Recheck what value SimC would use for recharge if an ability doesn't have charges.
            return t.cooldown[ action ].recharge

        elseif k == 'recharge_time' then
            -- TODO: Recheck what value SimC would use for recharge if an ability doesn't have charges.
            return t.cooldown[ action ].recharge_time

        elseif k == 'cost' then
            return ability and ability.spend or 0

        elseif k == 'cast_regen' then
            return ( max( state.gcd.execute, ability.cast or 0 ) * state[ ability.spendType or class.primaryResource ].regen ) -- - ( ability and ability.spend or 0 )

        elseif k == 'crit_pct_current' or k == 'crit_percent_current' then
            -- This is the crit % of the current ability.
            -- Pulse from the ability's 'critical' value or uses current character sheet crit.
            return ability and ability.critical or t.stat.crit

        end


        if class.knownAuraAttributes[ k ] then
            -- Buffs, debuffs...
            local aura_name = ability and ability.aura or t.this_action
            local aura = class.auras[ aura_name ]

            local app = aura and ( t.buff[ aura_name ].up and t.buff[ aura_name ] ) or ( t.debuff[ aura_name ].up and t.debuff[ aura_name ] ) or nil

            -- This uses the default aura duration (if available) to keep pandemic windows accurate.
            local duration = aura and aura.duration or 15
            
            -- This allows for overridden tick times on a particular application of an aura (i.e., Exsanguinate).
            local tick_time = app and app.tick_time or ( aura and aura.tick_time ) or ( 3 * t.haste )

            if k == 'duration' then            
                return duration

            elseif k == 'refreshable' then
                -- When cycling targets, we want to consider that there may be a valid other target.
                -- if t.isCyclingTargets( action, aura_name ) then return true end
                if app then return app.remains < 0.3 * duration end
                return true

            elseif k == 'time_to_refresh' then
                -- if t.isCyclingTargets( action, aura_name ) then return 0 end
                if app then return max( 0, app.remains - ( 0.3 * app.duration ) ) end
                return 0

            elseif k == 'ticking' or k == "up" then
                if app then return app.up end
                return false

            elseif k == "down" then
                if app then return app.down end
                return true

            elseif k == 'ticks' then
                if app then return 1 + floor( duration / tick_time ) - t.ticks_remain end
                return 0

            elseif k == 'ticks_remain' then
                if app then return 1 + floor( app.remains / tick_time ) end
                return 0

            elseif k == 'tick_time_remains' then
                if app then return ( app.remains % tick_time ) end
                return 0

            elseif k == 'remains' then
                if app then return app.remains end
                return 0

            elseif k == 'tick_time' then
                if app then return tick_time end
                return 0

            else
                if app and app[ k ] ~= nil then return app[ k ] end

            end
        end


        -- Check if this is a resource table pre-init.
        for i, key in pairs( class.resources ) do
            if k == key then
                return nil
            end
        end


        if state:GetVariableIDs( k ) then return t.variable[ k ] end

        if t.settings[ k ] ~= nil then return t.settings[ k ] end
        if t.toggle[ k ]   ~= nil then return t.toggle[ k ]   end

        Hekili:Error( "Returned unknown string '" .. k .. "' in state metatable [" .. state.scriptID .. "]." )
        return nil
    end,
    __newindex = function(t, k, v)
        rawset(t, k, v)
    end
}
ns.metatables.mt_state = mt_state


local mt_spec = {
    __index = function(t, k)
        return false
    end
}
ns.metatables.mt_spec = mt_spec


local mt_stat = {
    __index = function(t, k)
        if k == 'strength' then
            return UnitStat('player', 1)

        elseif k == 'agility' then
            return UnitStat('player', 2)

        elseif k == 'stamina' then
            return UnitStat('player', 3)

        elseif k == 'intellect' then
            return UnitStat('player', 4)

        elseif k == 'spirit' then
            return UnitStat('player', 5)

        elseif k == 'health' then
            return UnitHealth('player')

        elseif k == 'maximum_health' then
            return UnitHealthMax('player')

        elseif k == 'health_pct' then
            return UnitHealth( 'player' ) / UnitHealthMax( 'player' )

        elseif k == 'mana' then
            return Hekili.State.mana and Hekili.State.mana.current or 0

        elseif k == 'maximum_mana' then
            return Hekili.State.mana and Hekili.State.mana.max or 0

        elseif k == 'rage' then
            return Hekili.State.rage and Hekili.State.rage.current or 0

        elseif k == 'maximum_rage' then
            return Hekili.State.rage and Hekili.State.rage.max or 0

        elseif k == 'energy' then
            return Hekili.State.energy and Hekili.State.energy.current or 0

        elseif k == 'maximum_energy' then
            return Hekili.State.energy and Hekili.State.energy.max or 0

        elseif k == 'focus' then
            return Hekili.State.focus and Hekili.State.focus.current or 0

        elseif k == 'maximum_focus' then
            return Hekili.State.focus and Hekili.State.focus.max or 0

        elseif k == 'runic' or k == 'runic_power' then
            return Hekili.State.runic_power and Hekili.State.runic_power.current or 0

        elseif k == 'maximum_runic' or k == 'maximum_runic_power' then
            return Hekili.State.runic_power and Hekili.State.runic_power.max or 0

        elseif k == 'spell_power' then
            return GetSpellBonusDamage(7)

        elseif k == 'mp5' then
            return t.mana and Hekili.State.mana.regen or 0

        elseif k == 'attack_power' then
            return UnitAttackPower('player')

        elseif k == 'crit_rating' then
            return GetCombatRating(CR_CRIT_MELEE)

        elseif k == 'haste_rating' then
            return GetCombatRating(CR_HASTE_MELEE)

        elseif k == 'weapon_dps' then
            return -- Error("NYI")

        elseif k == 'weapon_speed' then
            return -- Error("NYI")

        elseif k == 'weapon_offhand_dps' then
            return -- Error("NYI")
            -- return OffhandHasWeapon()

        elseif k == 'weapon_offhand_speed' then
            return -- Error("NYI")

        elseif k == 'armor' then
            return -- Error("NYI")

        elseif k == 'bonus_armor' then
            return UnitArmor('player')

        elseif k == 'resilience_rating' then
            return GetCombatRating(CR_CRIT_TAKEN_SPELL)

        elseif k == 'mastery_rating' then
            return GetCombatRating(CR_MASTERY)

        elseif k == 'mastery_value' then
            return GetMasteryEffect()

        elseif k == 'versatility_atk_rating' then
            return GetCombatRating(CR_VERSATILITY_DAMAGE_DONE)

        elseif k == 'versatility_atk_mod' then
            return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)

        elseif k == 'versatility_def_rating' then
            return GetCombatRating(CR_VERSATILITY_DAMAGE_TAKEN)

        elseif k == 'versatility_def_mod' then
            return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)

        elseif k == 'mod_haste_pct' then
            return 0

        elseif k == 'spell_haste' then
            return ( UnitSpellHaste( 'player' ) + ( t.mod_haste_pct or 0 ) ) / 100

        elseif k == 'melee_haste' then
            return ( GetMeleeHaste('player') + ( t.mod_haste_pct or 0 ) ) / 100

        elseif k == 'haste' then
            return t.spell_haste or t.melee_haste

        elseif k == 'mod_crit_pct' then
            return 0

        elseif k == 'crit' then
            return ( max( GetCritChance( 'player' ), GetSpellCritChance( 'player' ), GetRangedCritChance( 'player' ) ) + ( t.mod_crit_pct or 0 ) )

        end

        -- Hekili:Error( "Unknown state.stat key: '" .. k .. "'." )
        return
    end
}
ns.metatables.mt_stat = mt_stat


-- Table of default handlers for specific pets/totems.
local mt_default_pet = {
    __index = function(t, k)
        --[[ if rawget( t, "permanent" ) then
            if k == 'up' or k == 'exists' then
                return UnitExists( 'pet' ) and ( not UnitIsDead( 'pet' ) )

            elseif k == 'alive' then
                return not UnitIsDead( 'pet' )

            elseif k == 'dead' then
                return UnitIsDead( 'pet' )

            elseif k == 'remains' then
                return 3600

            elseif k == 'down' then
                return not UnitExists( 'pet' ) or UnitIsDead( 'pet' )

            end
        end ]]

        if k == 'expires' then            
            local present, name, start, duration

            for i = 1, 5 do
                present, name, start, duration = GetTotemInfo( i )
                if duration == 0 then duration = 3600 end

                if present and class.abilities[ t.key ] and name == class.abilities[ t.key ].name then
                    t.expires = start + duration
                    return t.expires
                end
            end

            t.expires = 0            
            return t[ k ]

        elseif k == 'remains' then
            return max( 0, t.expires - ( state.query_time ) )

        elseif k == 'up' or k == 'active' or k == 'alive' or k == 'exists' then
            return ( t.expires >= ( state.query_time ) )

        elseif k == 'down' then
            return ( t.expires < ( state.query_time ) )

        elseif k == 'id' then
            return t.exists and UnitGUID( "pet" ) and tonumber( UnitGUID( "pet" ):match("(%d+)-%x-$" ) ) or nil

        elseif k == 'spec' then
            return t.exists and GetSpecialization( false, true )

        end

        return -- Error("UNK: " .. k)
    end,
}
ns.metatables.mt_default_pet = mt_default_pet


-- Table of pet data.
local mt_pets = {
    __index = function(t, k)
        -- Should probably add all totems, but holding off for now.
        for id, pet in pairs( t ) do
            if type( pet ) == 'table' and pet.up and pet[ k ] ~= nil then
                return pet[ k ]
            end
        end

        if k == 'up' or k == 'exists' or k == 'active' then
            for k, v in pairs( t ) do
                if type(v) == 'table' then
                    if v.expires > state.query_time then return true end
                end
            end
            return UnitExists( 'pet' ) and ( not UnitIsDead( 'pet' ) )

        elseif k == 'alive' then
            return UnitExists( 'pet' ) and not UnitIsDead( 'pet' )

        elseif k == 'dead' then
            return UnitExists( 'pet' ) and UnitIsDead( 'pet' )

        elseif k == 'health_pct' or k == 'health_percent' then
            if t.alive then return 100 * UnitHealth( 'pet' ) / UnitHealthMax( 'pet' ) end
            return 100

        end

        local model = class.pets[ k ]

        if model then
            t[ k ] = {
                id = model.id,
                name = k,
                duration = model.duration,
                expires = nil,
                spec = model.spec,
            }

            if model.spec then
                t[ model.spec ] = t[ k ]
            end

            return t[ k ]
        end

        return t.fake_pet
    end,

    __newindex = function(t, k, v)
        if type(v) == 'table' then
            if not v.key then v.key = k end
            rawset( t, k, setmetatable( v, mt_default_pet ) )
        else
            rawset( t, k, v )
        end
    end

}
ns.metatables.mt_pets = mt_pets


local mt_stances = {
    __index = function( t, k )
        if not class.stances[ k ] or not GetShapeshiftForm() then return false
        elseif GetShapeshiftForm() < 1 then return false
            elseif not select( 5, GetShapeshiftFormInfo( GetShapeshiftForm() ) ) == class.stances[k] then return false end
        rawset(t, k, select( 5, GetShapeshiftFormInfo( GetShapeshiftForm() ) ) == class.stances[k] )
        return t[k]
    end
}
ns.metatables.mt_stances = mt_stances

-- Table of supported toggles (via keybinding).
-- Need to add a commandline interface for these, but for some reason, I keep neglecting that.
local mt_toggle = {
    __index = function(t, k)
        if not k then return end

        if metafunctions.toggle[ k ] then
            return metafunctions.toggle[ k ]()
        end

        local db = Hekili.DB
        if not db then return end

        local toggle = db.profile.toggles[ k ]

        if k == "cooldowns" and toggle.override and state.buff.bloodlust.up then return true end
        if k == "essences" and toggle.override and state.toggle.cooldowns then return true end

        if toggle then return toggle.value end
    end
}
ns.metatables.mt_toggle = mt_toggle


local mt_settings = {
    __index = function( t, k )
        if metafunctions.settings[ k ] then
            return metafunctions.settings[ k ]()
        end

        local ability = state.this_action and class.abilities[ state.this_action ]        

        if rawget( t, "spec" ) then
            if t.spec.settings[ k ] ~= nil then return t.spec.settings[ k ] end
            if t.spec[ k ] ~= nil then return t.spec[ k ] end

            if ability then
                if ability.item and t.spec.items[ state.this_action ] ~= nil then return t.spec.items[ state.this_action ][ k ]
                elseif not ability.item and t.spec.abilities[ state.this_action ] ~= nil then return t.spec.abilities[ state.this_action ][ k ] end
            end
        end

        return
    end
}
ns.metatables.mt_settings = mt_settings


-- Table of target attributes. Needs to be expanded.
-- Needs review.
local mt_target = {
    __index = function(t, k)
        if k == 'level' then
            return UnitLevel('target') or UnitLevel('player')

        elseif k == 'unit' then
            if state.args.cycle_target == 1 then return UnitGUID( 'target' ) .. 'c' or 'cycle'
            elseif state.args.target then return UnitGUID( 'target' ) .. '+' .. state.args.target or 'unknown' end
            return UnitGUID( 'target' ) or 'unknown'

        elseif k == 'time_to_die' then
            local ttd = Hekili:GetTTD( 'target' )
            if ttd == 3600 then return ttd end
            return max( 1, Hekili:GetTTD( 'target' ) - ( state.offset + state.delay ) )

        elseif k:sub(1, 12) == 'time_to_pct_' then
            local percent = tonumber( k:sub( 13 ) ) or 0
            return Hekili:GetTimeToPct( "target", percent ) - ( state.offset + state.delay )

        elseif k == 'health_current' then
            return ( UnitHealth('target') > 0 and UnitHealth('target') or 50000 )

        elseif k == 'health_max' then
            return ( UnitHealthMax('target') > 0 and UnitHealthMax('target') or 50000 )

        elseif k == 'health_pct' or k == 'health_percent' then
            -- TBD: should health_pct use our time offset and TTD calculation to predict health?
            -- Currently deciding not to, as predicting that you can use something that you can't is
            -- probably worse than saying you can't use something that you can. Right?
            return t.health_max ~= 0 and ( 100 * ( t.health_current / t.health_max ) ) or 0

        elseif k == 'adds' then
            -- Need to return # of active targets minus 1.
            return max(0, ns.numTargets() - 1)

        elseif k == 'distance' then
            -- Need to identify a couple of spells to roughly get the distance to an enemy.
            -- We'd probably use IsSpellInRange() on an individual action instead, so maybe not.
            t.distance = UnitCanAttack( 'player', 'target'  ) and ( ( t.minR + t.maxR ) / 2 ) or 7.5
            return t.distance

        elseif k == 'moving' then
            return GetUnitSpeed( 'target' ) > 0

        elseif k == 'exists' then
            return UnitExists( 'target' )

        elseif k == 'casting' then
            return state.debuff.casting.up and not state.debuff.casting.v2

        elseif k == 'in_range' then
            return t.distance <= 8

            --[[ local ability = state.this_action and class.abilities[ state.this_action ]

            if ability then
                return ( not state.target.exists or ( LibStub( "SpellRange-1.0" ).IsSpellInRange( ability.id, 'target' ) == true ) )
            end

            return true ]]

        elseif k == 'is_demon' then
            return UnitCreatureType( 'target' ) == PET_TYPE_DEMON

        elseif k == 'is_undead' then
            return UnitCreatureType( 'target' ) == BATTLE_PET_NAME_4

        elseif k == 'is_player' then
            return UnitIsPlayer( 'target' )

        elseif k == 'is_boss' then
            if UnitExists( "boss1" ) and UnitIsUnit( "target", "boss1" ) or
                UnitExists( "boss2" ) and UnitIsUnit( "target", "boss2" ) or
                UnitExists( "boss3" ) and UnitIsUnit( "target", "boss3" ) or
                UnitExists( "boss4" ) and UnitIsUnit( "target", "boss4" ) or
                UnitExists( "boss5" ) and UnitIsUnit( "target", "boss5" ) then return true
            end
            return ( UnitCanAttack( "player", "target" ) and ( UnitClassification( "target" ) == "worldboss" or UnitLevel( "target" ) == -1 ) )

        elseif k:sub(1, 6) == 'within' then
            local maxR = k:match( "^within(%d+)$" )

            if not maxR then
                -- Error("UNK: " .. k)
                return false
            end

            return ( t.maxR <= tonumber( maxR ) )

        elseif k:sub(1, 7) == 'outside' then
            local minR = k:match( "^outside(%d+)$" )

            if not minR then
                -- Error("UNK: " .. k)
                return false
            end

            return ( t.minR > tonumber( minR ) )

        elseif k:sub(1, 5) == 'range' then
            local minR, maxR = k:match( "^range(%d+)to(%d+)$" )

            if not minR or not maxR then
                return false
                -- Error("UNK: " .. k)
            end 

            return ( t.minR >= tonumber( minR ) and t.maxR <= tonumber( maxR ) )

        elseif k == 'minR' then
            local minR = LibStub( "LibRangeCheck-2.0" ):GetRange( 'target' )
            if minR then
                t.minR = minR
                return t.minR
            end
            return 5

        elseif k == 'maxR' then
            local maxR = select( 2, LibStub( "LibRangeCheck-2.0" ):GetRange( 'target' ) )
            if maxR then
                t.maxR = maxR
                return t.maxR
            end
            return 10

        end

        return

    end
}
ns.metatables.mt_target = mt_target


local mt_target_health = {
    __index = function(t, k)
        if k == 'current' or k == 'actual' then
            return UnitCanAttack('player', 'target') and not UnitIsDead( 'target' ) and UnitHealth('target') or 10000

        elseif k == 'max' then
            return UnitCanAttack('player', 'target') and not UnitIsDead( 'target' ) and UnitHealthMax('target') or 10000

        elseif k == 'pct' or k == 'percent' then
            return t.max ~= 0 and ( 100 * t.current / t.max ) or 100
        end
    end
}
ns.metatables.mt_target_health = mt_target_health



local mt_consumable = {
    __index = function( t, k )
        return class.potion == k
    end
}
setmetatable( state.consumable, mt_consumable )



local cd_meta_functions = {}

function ns.addCooldownMetaFunction( ability, key, func )
    if not state.cooldown[ ability ] then state.cooldown[ ability ] = { key = ability } end
    if not rawget( state.cooldown[ ability ], 'meta' ) then state.cooldown[ ability ].meta = {} end
    state.cooldown[ ability ].meta[ key ] = setfenv( func, state )
end


-- Table of default handlers for specific ability cooldowns.
local mt_default_cooldown = {
    __index = function( t, k )
        local ability = t.key and class.abilities[ t.key ]

        if rawget( ability, 'meta' ) and ability.meta[ k ] then
            return ability.meta[ k ]( t )
        end

        local GetCooldown = _G.GetSpellCooldown
        local profile = Hekili.DB.profile
        local id = ability.id

        if ability and ability.item then
            GetCooldown = _G.GetItemCooldown
            id = ability.itemCd or ability.item
        end

        local raw = false

        if k:sub(1, 5) == "true_" then
            k = k:sub(6)
            raw = true
        end

        if k == 'duration' or k == 'expires' or k == 'next_charge' or k == 'charge' or k == 'recharge_began' then
            -- Refresh the ID in case we changed specs and ability is spec dependent.
            t.id = ability.id

            local start, duration = 0, 0

            if id > 0 then start, duration = GetCooldown( id ) end

            if t.key ~= 'global_cooldown' then
            local gcdStart, gcdDuration = GetSpellCooldown( 61304 )
            if gcdStart == start and gcdDuration == duration then start, duration = 0, 0 end
            end

            local true_duration = duration

            if t.key == 'ascendance' and state.buff.ascendance.up then
                start = state.buff.ascendance.expires - class.auras.ascendance.duration
                duration = class.abilities[ 'ascendance' ].cooldown

            elseif t.key == 'potion' then
                local itemName = state.args.ModName or state.args.name or class.potion
                local potion = class.potions[ itemName ]

                if state.toggle.potions and potion and GetItemCount( potion.item ) > 0 then
                    start, duration = GetItemCooldown( potion.item )

                else
                    start = state.now
                    duration = 0

                end

            elseif not state:IsKnown( t.id ) then
                start = state.now
                duration = 0

            end

            t.duration = max( duration or 0, ability.cooldown or 0, ability.recharge or 0 ) or 0
            t.expires = start and ( start + duration ) or 0
            t.true_duration = true_duration
            t.true_expires = start and ( start + true_duration ) or 0

            if ability.charges and ability.charges > 1 then
                local charges, maxCharges, start, duration = GetSpellCharges( t.id )

                --[[ if class.abilities[ t.key ].toggle and not state.toggle[ class.abilities[ t.key ].toggle ] then
                    charges = 1
                    maxCharges = 1
                    start = state.now
                    duration = 0
                end ]]

                t.charge = charges or 1
                t.recharge = duration or ability.recharge

                if charges and charges < maxCharges then
                    t.next_charge = start + duration
                else
                    t.next_charge = 0
                end
                t.recharge_began = start or t.expires - t.duration

            else
                t.charge = t.expires < state.query_time and 1 or 0
                t.next_charge = t.expires > state.query_time and t.expires or 0
                t.recharge_began = t.expires - t.duration
            end

            return t[k]

        elseif k == 'charges' then
            if not raw and ( state:IsDisabled( t.key ) or ability.disabled ) then
                return 0
            end

            return floor( t.charges_fractional )

        elseif k == 'charges_max' or k == 'max_charges' then
            return ability.charges or 1

        elseif k == 'recharge' then
            return ability.recharge or ability.cooldown or 0

        elseif k == 'time_to_max_charges' or k == 'full_recharge_time' then
            return ( ( ability.charges or 1 ) - t.charges_fractional ) * ( ability.recharge or ability.cooldown )

        elseif k == 'remains' then            
            if t.key == 'global_cooldown' then
                return max( 0, t.expires - state.query_time )
            end

            -- If the ability is toggled off in the profile, we may want to fake its CD.
            -- Revisit this if I add base_cooldown to the ability tables.
            if not raw and ( state:IsDisabled( t.key ) or ability.disabled ) then
                return ability.cooldown
            end

            local bonus_cdr = 0
            bonus_cdr = ns.callHook( "cooldown_recovery", bonus_cdr ) or bonus_cdr

            return max( 0, t.expires - state.query_time - bonus_cdr )

        elseif k == 'charges_fractional' then
            if not state:IsKnown( t.key ) then return 1 end
            if not raw and ( state:IsDisabled( t.key ) or ability.disabled ) then return 0 end

            if ability.charges then 
                if t.charge < ability.charges then
                    return min( ability.charges, t.charge + ( max( 0, state.query_time - t.recharge_began ) / t.recharge ) )
                    -- return t.charges + ( 1 - ( class.abilities[ t.key ].recharge - t.recharge_time ) / class.abilities[ t.key ].recharge )
                end
                return t.charge
            end

            return t.remains > 0 and 0 or 1

        --
        elseif k == 'recharge_time' then
            if not ability.charges then return t.duration or 0 end
            return t.recharge

        elseif k == 'up' or k == 'ready' then
            return ( t.remains == 0 )

        -- Hunters
        elseif k == 'remains_guess' then
            if t.remains == t.duration then return t.remains end
            
            local lastCast = state.action[ t.key ].lastCast or 0
            if lastCast == 0 then return t.remains end

            local reduction = ( state.query_time - lastCast ) / ( t.duration - t.remains )
            return t.remains * reduction

        elseif k == 'duration_guess' then
            if t.remains == t.duration then return t.duration end

            -- not actually the same as simc here, which tracks when CDs charge.            
            local lastCast = state.action[ t.key ].lastCast or 0
            if lastCast == 0 then return t.duration end

            local reduction = ( state.query_time - lastCast ) / ( t.duration - t.remains )
            return t.duration * reduction

        end

        Error( "UNK: cooldown." .. t.key .. "." .. k )
        return

    end
}
ns.metatables.mt_default_cooldown = mt_default_cooldown


-- Table for gathering cooldown information. Some abilities with odd behavior are getting embedded here.
-- Probably need a better system that I can keep in the class modules.
-- Needs review.
local mt_cooldowns = {
    -- The action doesn't exist in our table so check the real game state, -- and copy it so we don't have to use the API next time.
    __index = function(t, k)
        local entry = class.abilities[ k ]

        if not entry then
            Error( "UNK: cooldown." .. k )
            return
        end

        if k ~= entry.key then
            t[ k ] = t[ entry.key ]
            return t[ k ]
        end

        local ability = entry.id

        t[ k ] = { key = k }
        return t[ k ]

    end, 
    __newindex = function(t, k, v)
        rawset( t, k, setmetatable( v, mt_default_cooldown ) )
    end
}
ns.metatables.mt_cooldowns = mt_cooldowns


local mt_dot = {
    __index = function(t, k)
        local a = class.auras[ k ]

        if a and a.dot == "buff" then
            return state.buff[ k ]
        end

        return state.debuff[ k ]
    end,
}
ns.metatables.mt_dot = mt_dot


local mt_gcd = {
    __index = function( t, k )
        if k == "execute" then
            local ability = state.this_action and class.abilities[ state.this_action ]

            -- We can specify this for any ability, if we want.
            if ability and ability.gcdTime then return ability.gcdTime end

            local gcd = ability and ability.gcd or "spell"

            if gcd == "off" then return 0 end
            if gcd == "totem" then return 1 end

            if UnitPowerType( 'player' ) == Enum.PowerType.Energy then
                return state.buff.adrenaline_rush.up and 0.8 or 1
            end

            return max( 1.5 * state.haste, state.buff.voidform.up and 0.67 or 0.75 )

        elseif k == "remains" then
            return state.cooldown.global_cooldown.remains

        elseif k == "max" or k == "duration" then
            if UnitPowerType( 'player' ) == Enum.PowerType.Energy then
                return state.buff.adrenaline_rush.up and 0.8 or 1
            end

            return max( 1.5 * state.haste, state.buff.voidform.up and 0.67 or 0.75 )
        
        elseif k == "lastStart" then
            return 0
        
        end

        return
    end        
}
ns.metatables.mt_gcd = mt_gcd
setmetatable( state.gcd, mt_gcd )


local mt_prev_lookup = {
    __index = function( t, k )
        if state.time == 0 then return false end

        local idx = t.index
        local preds, prev
        local action
        
        if t.meta == 'castsAll' then preds, prev = state.predictions, state.prev
        elseif t.meta == 'castsOn' then preds, prev = state.predictionsOn, state.prev_gcd
        elseif t.meta == 'castsOff' then preds, prev = state.predictionsOff, state.prev_off_gcd end

        if k == 'spell' then
            -- Return the actual spell for the slot, for lookups.
            if preds[ idx ] then return preds[ idx ] end

            if state.player.queued_ability then
                if idx == #preds + 1 then return state.player.queued_ability end
                return prev.history[ idx - #preds + 1 ]
            end
    
            if idx == 1 and prev.override then
                return prev.override
            end
    
            return prev.history[ idx - #preds ]
        end

        if preds[ idx ] then return preds[ idx ] == k end

        if state.player.queued_ability then
            if idx == #preds + 1 then return state.player.queued_ability == k end
            return prev.history[ idx - #preds + 1 ] == k
        end

        if idx == 1 and prev.override then
            return prev.override == k
        end

        return prev.history[ idx - #preds ] == k
    end,
}

local prev_lookup = setmetatable( {
    index = 1,
    meta = 'castsAll'
}, mt_prev_lookup )


local mt_prev = {
    __index = function( t, k )
        if type( k ) == 'number' then
            -- This is a SimulationCraft 7.1.5 or later indexed lookup, we support up to #5.
            if k < 1 or k > 5 then return false end
            prev_lookup.meta = t.meta -- Which data to use? castsAll, castsOn (GCD), castsOff (offGCD)?
            prev_lookup.index = k
            return prev_lookup
        end

        if k == t.last then
            return true
        end

        return false
    end
}
ns.metatables.mt_prev = mt_prev


local resource_meta_functions = {}

function state:AddResourceMetaFunction( name, f )
    resource_meta_functions[ name ] = f
end


function state:TimeToResource( t, amount )
    if not amount or amount > t.max then return 3600
    elseif t.current >= amount then return 0 end

    local pad, lastTick = 0
    if t.resource == "energy" or t.resource == "focus" then
        -- Round any result requiring ticks to the next tick.
        lastTick = t.last_tick
    end

    if t.forecast and t.fcount > 0 then
        local q = state.query_time
        local index, slice

        if t.times[ amount ] then return t.times[ amount ] - q end

        if t.regen == 0 then
            for i = 1, t.fcount do
                local v = t.forecast[ i ]
                if v.v >= amount then
                    t.times[ amount ] = v.t
                    return max( 0, t.times[ amount ] - q )
                end
            end
            t.times[ amount ] = q + 3600
            return max( 0, t.times[ amount ] - q )
        end

        for i = 1, t.fcount do
            local slice = t.forecast[ i ]
            local after = t.forecast[ i + 1 ]

            if slice.v >= amount then
                t.times[ amount ] = slice.t

                if lastTick then
                    pad = ( slice.t - lastTick ) % 0.1
                    pad = 0.1 - pad
                end

                return max( 0, pad + t.times[ amount ] - q )

            elseif after and after.v >= amount then
                -- Our next slice will have enough resources.  Check to see if we'd regen enough in-between.
                local time_diff = after.t - slice.t
                local deficit = amount - slice.v
                local regen_time = deficit / t.regen

                if lastTick then
                    pad = ( slice.t - lastTick ) % 0.1
                    pad = 0.1 - pad
                end

                if regen_time < time_diff then
                    t.times[ amount ] = ( pad + slice.t + regen_time )
                else
                    t.times[ amount ] = after.t
                end
                return max( 0, t.times[ amount ] - q )
            end
        end

        t.times[ amount ] = q + 3600
        return max( 0, t.times[ amount ] - q )
    end

    -- This wasn't a modeled resource,, just look at regen time.
    if lastTick then
        pad = ( slice.t - lastTick ) % 0.1
        pad = 0.1 - pad
    end

    if t.regen <= 0 then return 3600 end
    return max( 0, pad + ( ( amount - t.current ) / t.regen ) )
end



local mt_resource = {
    __index = function(t, k)

        if resource_meta_functions[ k ] then
            local result = resource_meta_functions[ k ]( t )

            if result then
                return result
            end
        end

        if k == 'pct' or k == 'percent' then
            return 100 * ( t.current / t.max )

        elseif k == 'deficit_pct' or k == 'deficit_percent' then
            return 100 - t.pct

        elseif k == 'current' then
            -- If this is a modeled resource, use our lookup system.
            if t.forecast and t.fcount > 0 then
                local q = state.query_time
                local index, slice

                if t.values[ q ] then return t.values[ q ] end

                for i = 1, t.fcount do
                    local v = t.forecast[ i ]
                    if v.t <= q then
                        index = i
                        slice = v
                    else
                        break
                    end
                end

                -- We have a slice.
                if index and slice then
                    t.values[ q ] = max( 0, min( t.max, slice.v + ( ( state.query_time - slice.t ) * t.regen ) ) )
                    return t.values[ q ]
                end
            end

            -- No forecast.
            if t.regen ~= 0 then
                return max( 0, min( t.max, t.actual + ( t.regen * state.delay ) ) )
            end

            return t.actual

        elseif k == 'deficit' then
            return t.max - t.current

        elseif k == 'max_nonproc' then
            return t.max -- need to accommodate buffs that increase mana, etc.

        elseif k == 'time_to_max' then
            return state:TimeToResource( t, t.max )

        elseif k:sub(1, 8) == 'time_to_' then
            local amount = k:sub(9)
            amount = tonumber(amount)

            if not amount then return 3600 end

            return state:TimeToResource( t, amount )

        elseif k == 'regen' then
            return ( state.time > 0 and t.active_regen or t.inactive_regen ) or 0

        elseif k == 'model' then
            return

        elseif k == 'onAdvance' then
            return

        end

    end
}
ns.metatables.mt_resource = mt_resource


local default_buff_values = {
    name = "no_name",
    count = 0,
    lastCount = 0,
    lastApplied = 0,
    expires = 0,
    applied = 0,
    duration = 15,
    caster = 'nobody',
    timeMod = 1,
    v1 = 0,
    v2 = 0,
    v3 = 0,

    last_application = 0,
    last_expiry = 0,

    unit = 'player'
}


function state:AddBuffMetaFunction( aura, key, func )
    local a = class.auras[ aura ]
    if not a then return end

    if not a.meta then a.meta = {} end
    a.meta[ key ] = setfenv( func, self )
end


-- Aliases let a single buff name refer to any of multiple buffs.
-- Developed mainly for RtB; it will also report 'stack' or 'count' as the sum of stacks of multiple buffs.
local mt_alias_buff = {
    __index = function( t, k )
        local aura = class.auras[ t.key ]
        local type = aura.aliasType or "buff"

        if k == 'count' or k == 'stack' or k == 'stacks' then
            local n = 0

            for i, child in ipairs( aura.alias ) do
                if state[ type ][ child ].up then n = n + max( 1, state[ type ][ child ].stack ) end
            end

            return n

        end

        local alias
        local mode = aura.aliasMode or "first"

        for i, v in ipairs( aura.alias ) do
            local child = state[ type ][ v ]
            if not alias and mode == "first" and child.up then return child[ k ] end

            if child.up then
                if mode == "shortest" and ( not alias or child.remains < alias.remains ) then alias = child
                elseif mode == "longest" and ( not alias or child.remains > alias.remains ) then alias = child end
            end
        end

        if alias then return alias[ k ]
        else return state[ type ][ aura.alias[1] ][ k ] end
    end 
}


local requiresLookup = {
    name = true,
    count = true,
    lastCount = true,
    lastApplied = true,
    expires = true,
    applied = true,
    caster = true,
    id = true,
    timeMod = true,
    v1 = true,
    v2 = true,
    v3 = true,

    last_application = true,
    last_expiry = true,

    unit = true
}


-- Table of default handlers for auras (buffs, debuffs).
local mt_default_buff = {
    mtID = "default_buff",

    __index = function( t, k )
        local aura = class.auras[ t.key ]

        if aura and rawget( aura, "meta" ) and aura.meta[ k ] then
            return aura.meta[ k ]( t, "buff" )

        elseif requiresLookup[ k ] then
            if aura and aura.generate then
                for attr, a_val in pairs( default_buff_values ) do
                    t[ attr ] = rawget( t, attr ) or rawget( aura, attr ) or a_val
                end

                aura.generate( t, "buff" )
                t.id = aura and aura.id or t.key

                return rawget( t, k )
            end

            local real = auras.player.buff[ t.key ] or auras.target.buff[ t.key ]

            if real then
                t.name = real.name
                t.count = real.count
                t.lastCount = real.lastCount or 0
                t.lastApplied = real.lastApplied or 0                
                t.duration = real.duration
                t.expires = real.expires
                t.applied = max( 0, real.expires - real.duration )
                t.caster = real.caster
                t.id = real.id or class.auras[ t.key ].id
                t.timeMod = real.timeMod
                t.v1 = real.v1
                t.v2 = real.v2
                t.v3 = real.v3

                t.last_application = real.last_application or 0
                t.last_expiry = real.last_expiry or 0

                t.unit = real.unit
            else
                for attr, a_val in pairs( default_buff_values ) do
                    t[ attr ] = aura and aura[ attr ] or a_val
                end

                t.id = rawget( t, id ) or ( aura and aura.id ) or t.key
            end

            return rawget( t, k )

        elseif k == 'up' or k == 'ticking' then
            return t.remains > 0            

        elseif k == 'react' then
            -- React returns stacks assuming you've had time to react to them.
            -- if state.query_time > t.applied + state.latency then
                if t.expires > state.query_time then
                    return t.count
                end
                return 0
            -- end

            -- return state.query_time > t.lastApplied and t.lastCount or 0

        elseif k == 'down' then
            return t.remains == 0

        elseif k == 'remains' then
            if aura and aura.strictTiming then
                return max( 0, t.expires - state.query_time )
            end
            return max( 0, t.expires - state.query_time )

        elseif k == 'refreshable' then
            return t.remains < 0.3 * ( aura.duration or 30 )

        elseif k == 'time_to_refresh' then
            return t.up and max( 0, t.remains - ( 0.3 * ( aura.duration or 30 ) ) ) or 0

        elseif k == 'cooldown_remains' then
            return state.cooldown[ t.key ] and state.cooldown[ t.key ].remains or 0

        elseif k == 'max_stack' or k == 'max_stacks' then
            return class.auras[ t.key ].max_stack or 1

        elseif k == 'mine' then
            return t.caster == 'player'

        elseif k == 'stack' or k == 'stacks' then
            if t.up then return ( t.count ) else return 0 end

        elseif k == 'stack_pct' then
            if t.up then return ( 100 * t.stack / t.max_stack ) else return 0 end

        elseif k == 'ticks' then
            if t.up then return 1 + ( ( class.auras[ t.key ].duration or ( 30 * state.haste ) ) / ( class.auras[ t.key ].tick_time or ( 3 * t.haste ) ) ) - t.ticks_remain end
            return 0
        
        elseif k == 'tick_time' then
            return aura and aura.tick_time or 3 -- Default tick time will be 3 because why not?

        elseif k == 'ticks_remain' then
            if t.up then return math.floor( t.remains / t.tick_time ) end
            return 0
        
        elseif k == 'last_trigger' then
            if state.combat > 0 then return max( 0, t.last_application - state.combat ) end
            return 0
        
        elseif k == 'last_expire' then
            if state.combat > 0 then return max( 0, t.last_expiry - state.combat ) end
            return 0

        else
            if class.auras[ t.key ] and class.auras[ t.key ][ k ] ~= nil then
                return class.auras[ t.key ][ k ]
            end
        end

        Error( "UNK: buff." .. t.key .. "." .. k )

    end,

    newindex = function( t, k, v )
        -- Prevent a fixed value from being entered if it is calculated by a meta function.
        if t.meta and t.meta[ k ] then
            return
        end
        class.knownAuraAttributes[ k ] = true
        t[ k ] = v
    end
}
ns.metatables.mt_default_buff = mt_default_buff


local unknown_buff = setmetatable( {
    key = 'unknown_buff',
    count = 0,
    duration = 0,
    expires = 0,
    applied = 0,
    caster = 'nobody',
    timeMod = 1,
    v1 = 0,
    v2 = 0,
    v3 = 0
}, mt_default_buff )


-- This will currently accept any key and make an honest effort to find the buff on the player.
-- Unfortunately, that means a buff.dog_farts.up check will actually get a return value.

-- Fullscan definitely needs revamping, but it works for now.
local mt_buffs = {
    -- The aura doesn't exist in our table so check the real game state, -- and copy it so we don't have to use the API next time.
    __index = function( t, k )        
        if k == '__scanned' then
            return false
        end

        local aura = class.auras[ k ]

        if not aura then
            return unknown_buff
        end

        if k ~= aura.key then
            t[ aura.key ] = rawget( t, aura.key ) or {
                key = aura.key,
                name = aura.name
            }
            t[ k ] = t[ aura.key ]
        else
            t[k] = {
                key = aura.key,
                name = aura.name
            }
        end

        if aura.generate then
            for attr, a_val in pairs( default_buff_values ) do
                t[ k ][ attr ] = rawget( t[ k ], attr ) or a_val
            end
            aura.generate( t[ k ], "buff" )
            return t[ k ]
        end

        local real = auras.player.buff[ k ] or auras.target.buff[ k ]

        local buff = t[k]

        if real then
            buff.name = real.name
            buff.count = real.count
            buff.lastCount = real.lastCount or 0
            buff.lastApplied = real.lastApplied or 0
            buff.duration = real.duration
            buff.expires = real.expires
            buff.applied = max( 0, real.expires - real.duration )
            buff.caster = real.caster
            buff.id = real.id
            buff.timeMod = real.timeMod
            buff.v1 = real.v1
            buff.v2 = real.v2
            buff.v3 = real.v3

            buff.unit = real.unit

        else
            buff.name = aura.name or "No Name"
            buff.count = 0
            buff.lastCount = 0
            buff.lastApplied = 0
            buff.duration = aura.duration or 30
            buff.expires = 0
            buff.applied = 0
            buff.caster = 'nobody'
            -- buff.id = nil
            buff.timeMod = 1
            buff.v1 = 0
            buff.v2 = 0
            buff.v3 = 0

            buff.unit = aura.unit or 'player'
        end

        return t[ k ]

    end,

    __newindex = function( t, k, v )
        local aura = class.auras[ k ]

        if aura and aura.alias then
            rawset( t, k, setmetatable( v, mt_alias_buff ) )
            return
        end

        rawset( t, k, setmetatable( v, mt_default_buff ) )
    end
}
ns.metatables.mt_buffs = mt_buffs


local mt_default_talent = {
    __index = function( t, k )
        if k == 'i_enabled' or k == 'rank' then return t.enabled and 1 or 0 end
        return k
    end,
}
ns.metatables.mt_default_talent = mt_default_talent


local null_talent = setmetatable( {
    enabled = false,
}, mt_default_talent )
ns.metatables.null_talent = null_talent


local mt_talents = {
    __index = function( t, k )
        return ( null_talent )
    end,

    __newindex = function( t, k, v )
        if type( v ) == 'table' then
            rawset( t, k, setmetatable( v, mt_default_talent ) )
            return
        end
        rawset( t, k, v )
    end,
}
ns.metatables.mt_talents = mt_talents


local function IslandPvP()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "scenario" and difficulty == 45
end

local mt_default_pvptalent = {
    __index = function( t, k )
        local enlisted = state.bg or state.arena or state.buff.enlisted.up or IslandPvP()

        if k == 'enabled' then return enlisted and t._enabled or false
        elseif k == "_enabled" then return false
        elseif k == 'i_enabled' or k == 'rank' then return ( enlisted and t._enabled ) and 1 or 0 end

        return k
    end,
}


local null_pvptalent = setmetatable( {
    _enabled = false
}, mt_default_pvptalent )


local mt_pvptalents = {
    __index = function( t, k )
        return null_pvptalent
    end,

    __newindex = function( t, k, v )
        rawset( t, k, setmetatable( v, mt_default_pvptalent ) )
    end,
}


local mt_default_trait = {
    __index = function( t, k )
        if k == 'enabled' or k == 'minor' then
            return t.rank and t.rank > 0
        elseif k == 'disabled' then
            return not t.rank or t.rank == 0
        end
    end
}


local mt_artifact_traits = {
    __index = function( t, k )
        return t.no_trait
    end,

    __newindex = function( t, k, v )
        rawset( t, k, setmetatable( v, mt_default_trait ) )
        return t.k
    end
}

setmetatable( state.azerite, mt_artifact_traits )
state.azerite.no_trait = { rank = 0 }
state.artifact = state.azerite

setmetatable( state.corruptions, mt_artifact_traits )
state.corruptions.no_trait = { rank = 0 }

-- Essences
setmetatable( state.essence, mt_artifact_traits )
state.essence.no_trait = { rank = 0, major = false, minor = false }


do
    local db = scripts.DB

    -- Args table, make it nicer.
    setmetatable( state.args, {
        __index = function( t, k )
            -- No script selected.
            if not state.scriptID then return end

            local script = db[ state.scriptID ]

            -- No script by that name.
            if not script then return end

            -- Script has no modifiers.
            if not script.Modifiers then return end

            local mod = script.Modifiers[ k ]

            if mod then
                local s, val = pcall( mod )
                if s then return val end
            end
        end,
    } )
end


-- Table for counting active dots.
local mt_active_dot = {
    __index = function(t, k)
        local aura = class.auras[ k ]

        if aura then
            if rawget( t, aura.key ) then return t[ aura.key ] end
            t[ k ] = ns.numDebuffs( aura.id )
            return t[ k ]

        else
            return 0

        end
    end
}
ns.metatables.mt_active_dot = mt_active_dot


-- Table of default handlers for a totem. Under-implemented at the moment.
-- Needs review.
local mt_default_totem = {
    __index = function(t, k)
        if k == 'expires' then
            local _, name, start, duration = GetTotemInfo( t.totem )

            t.name = name
            t.expires = ( start or 0 ) + ( duration or 0 )

            return t[ k ]

        elseif k == 'up' or k == 'active' then
            return ( t.expires > ( state.query_time ) )

        elseif k == 'remains' then
            if t.expires > ( state.query_time ) then
                return ( t.expires - ( state.query_time ) )
            else
                return 0
            end

        end

        Error( "UNK: totem." .. name or "no_name" .. "." .. k )
    end
}
Hekili.mt_default_totem = mt_default_totem


-- Table of totems. Currently Shaman-centric.
-- Needs review.
local mt_totem = {
    __index = function(t, k)
        if k == 'fire' then
            local _, name, start, duration = GetTotemInfo(1)

            t[k] = {
            key = k, totem = 1, name = name, expires = (start + duration) or 0, }
            return t[k]

        elseif k == 'earth' then
            local _, name, start, duration = GetTotemInfo(2)

            t[k] = {
            key = k, totem = 2, name = name, expires = (start + duration) or 0, }
            return t[k]

        elseif k == 'water' then
            local _, name, start, duration = GetTotemInfo(3)

            t[k] = {
            key = k, totem = 3, name = name, expires = (start + duration) or 0, }
            return t[k]

        elseif k == 'air' then
            local _, name, start, duration = GetTotemInfo(4)

            t[k] = {
            key = k, totem = 4, name = name, expires = (start + duration) or 0, }
            return t[k]
        end

        Error( "UNK: totem." .. k )

        end, __newindex = function(t, k, v)
        rawset( t, k, setmetatable( v, mt_default_totem ) )
    end
}
ns.metatables.mt_totem = mt_totem


do
    local db = {}
    local cache = {}
    local pathState = {}

    state.varDB = db
    -- state.varCache = cache
    state.varPaths = pathState


    local entryPool = {}

    function state:RegisterVariable( key, scriptID, preconditions, preclusions )
        db[ key ] = db[ key ] or {}
        local data = db[ key ]
        
        cache[ key ] = cache[ key ] or {}

        local fullPath = scriptID

        local entry = remove( entryPool ) or {
            mustPass = {},
            mustFail = {}
        }

        entry.id = scriptID

        if preconditions then
            for i, prereq in ipairs( preconditions ) do
                local script = prereq.script
                if script ~= 0 then
                    insert( entry.mustPass, script )
                    fullPath = fullPath .. "+" .. script
                end
            end
        end

        if preclusions then
            for i, block in ipairs( preclusions ) do
                local script = block.script
                if script ~= 0 then                
                    insert( entry.mustFail, script )
                    fullPath = fullPath .. "-" .. script
                end
            end
        end

        entry.fullPath = fullPath
        insert( data, entry )
    end

    
    function state:ResetVariables()
        for k, v in pairs( db ) do
            for i = #v, 1, -1 do
                local x = remove( v, i )
                wipe( x.mustPass )
                wipe( x.mustFail )
                insert( entryPool, x )
            end
            wipe( cache[ k ] )
            wipe( self.variable )
        end

        wipe( pathState )
    end


    function state:GetVariableIDs( key )
        return db[ key ]
    end

    
    state.variable = setmetatable( {}, {
        __index = function( t, var )
            local debug = Hekili.ActiveDebug

            local now = state.query_time

            if class.variables[ var ] then
                -- We have a hardcoded shortcut.
                return class.variables[ var ]()
            end

            if Hekili.LoadingScripts then
                return 0
            end

            state.variable[ var ] = 0

            if not db[ var ] then
                return 0
            end

            local data = db[ var ]
            local parent = state.scriptID

            -- If we're checking variable with no script loaded, don't bother.
            if not parent or parent == "NilScriptID" then return 0 end

            local default = 0
            local value = 0

            local which_mod = "value"

            for i, entry in ipairs( data ) do
                local scriptID = entry.id
                local currPath = entry.fullPath .. ":" .. now

                -- Check the requirements/exclusions in the APL stack.
                if pathState[ currPath ] == nil then
                    pathState[ currPath ] = true

                    for r, prereq in ipairs( entry.mustPass ) do
                        state.scriptID = prereq
                        if not scripts:CheckScript( prereq ) then
                            pathState[ currPath ] = false
                            break
                        end
                    end

                    if pathState[ currPath ] then
                        for e, excl in ipairs( entry.mustFail ) do
                            state.scriptID = excl
                            if scripts:CheckScript( excl ) then
                                pathState[ currPath ] = false
                                break
                            end
                        end
                    end
                end

                if pathState[ currPath ] then                    
                    local pathKey = currPath .. "-" .. i

                    if cache[ var ][ pathKey ] ~= nil then
                        value = cache[ var ][ pathKey ]

                    else
                        state.scriptID = scriptID
                        local op = state.args.op or "set"

                        local passed = scripts:CheckScript( scriptID )

                        --[[    add = "Add Value",
                                ceil
                                x default = "Set Default Value",
                                div = "Divide Value",
                                floor
                                max = "Maximum Value",
                                min = "Minimum Value",
                                mod = "Modulo Value",
                                mul = "Multiply Value",
                                pow = "Raise Value to X Power",
                                x reset = "Reset to Default",
                                x set = "Set Value",
                                x setif = "Set Value If...",
                                sub = "Subtract Value" ]]

                        if op == "set" or op == "setif" then
                            if passed then
                                local v1 = state.args.value
                                if v1 ~= nil then value = v1
                                else value = state.args.default end
                            else
                                local v2 = state.args.value_else
                                if v2 ~= nil then
                                    value = v2
                                    which_mod = "value_else"
                                end
                            end

                        elseif op == "reset" then
                            if passed then
                                local v = state.args.value
                                if v == nil then v = state.args.default end
                                if v == nil then v = 0 end
                                value = v
                            end

                        elseif passed then
                            -- Math Ops.
                            local currType = type( value )

                            if currType == 'number' then
                                -- Operations on existing value.
                                if op == "floor" then
                                    value = floor( value )
                                elseif op == "ceil" then
                                    value = ceil( value )
                                else
                                    -- Operations with two values.
                                    local newVal = state.args.value
                                    local valType = type( newVal )
                                    
                                    if valType == 'number' then
                                        if op == "add" then
                                            value = value + newVal
                                        elseif op == "div" then
                                            if newVal == 0 then value = 0
                                            else value = value / newVal end
                                        elseif op == "max" then
                                            value = max( value, newVal )
                                        elseif op == "min" then
                                            value = min( value, newVal )
                                        elseif op == "mod" then
                                            if newVal == 0 then value = 0
                                            else value = value % newVal end
                                        elseif op == "mul" then
                                            value = value * newVal
                                        elseif op == "pow" then
                                            value = value ^ newVal
                                        elseif op == "sub" then
                                            value = value - newVal
                                        end
                                    end
                                end
                            end
                        end

                        -- Cache the value in case it is an intermediate value (i.e., multiple calculation steps).                        
                        state.variable[ var ] = value
                        cache[ var ][ pathKey ] = value
                    end
                end
            end

            -- Clear cache and clear the flag that we are checking this variable already.
            state.variable[ var ] = nil

            --[[ if debug then
                Hekili:Debug( "Spent %.2fms calculating value of %s -- %s [%s].", debugprofilestop() - varStart, var, tostring( value ), parent )
            end ]]

            state.scriptID = parent

            return value
        end
    } )
end



-- Table of set bonuses. Some string manipulation to honor the SimC syntax.
-- Currently returns 1 for true, 0 for false to be consistent with SimC conditionals.
-- Won't catch fake set names. Should revise.
local mt_set_bonuses = {
    __index = function(t, k)
        if type(k) == 'number' then return 0 end

        -- if ( not class.artifacts[ k ] ) and ( state.bg or state.arena ) then return 0 end

        local set, pieces, class = k:match("^(.-)_"), tonumber( k:match("_(%d+)pc") ), k:match("pc(.-)$")

        if not pieces or not set then
            -- This wasn't a tier set bonus.
            return 0

        else
            if class then set = set .. class end

            if not t[set] then
                return 0
            end

            return t[set] >= pieces and 1 or 0
        end

        return 0

    end
}
ns.metatables.mt_set_bonuses = mt_set_bonuses


local mt_equipped = {
    __index = function(t, k)
        -- if not class.artifacts[ k ] and ( state.bg or state.arena ) then return false end
        return state.set_bonus[k] > 0 or state.corruptions[k].rank > 0
    end
}
ns.metatables.mt_equipped = mt_equipped


-- Aliases let a single buff name refer to any of multiple buffs.
-- Developed mainly for RtB; it will also report 'stack' or 'count' as the sum of stacks of multiple buffs.
local mt_alias_debuff = {
    __index = function( t, k )
        local aura = class.auras[ t.key ]
        local type = aura.aliasType or "debuff"

        if k == 'count' or k == 'stack' or k == 'stacks' then
            local n = 0

            for i, child in ipairs( aura.alias ) do
                if state[ type ][ child ].up then n = n + max( 1, state[ type ][ child ].stack ) end
            end

            return n
        end

        local alias
        local mode = aura.aliasMode or "first"

        for i, v in ipairs( aura.alias ) do
            local child = state[ type ][ v ]
            if not alias and mode == "first" and child.up then return child[ k ] end

            if child.up then
                if mode == "shortest" and ( not alias or child.remains < alias.remains ) then alias = child
                elseif mode == "longest" and ( not alias or child.remains > alias.remains ) then alias = child end
            end
        end

        if alias then return alias[ k ]
        else return state[ type ][ aura.alias[1] ][ k ] end
    end 
}


local default_debuff_values = {
    name = "no_name",
    count = 0,
    lastCount = 0,
    lastApplied = 0,
    expires = 0,
    applied = 0,    
    duration = 15,
    caster = 'nobody',
    timeMod = 1,
    v1 = 0,
    v2 = 0,
    v3 = 0,
    unit = 'target'
}

local cycle_debuff = {
    name = "cycle",
    count = 0,
    lastCount = 0,
    lastApplied = 0,
    expires = 0,
    applied = 0,
    duration = 0,
    caster = 'nobody',
    timeMod = 1,
    v1 = 0,
    v2 = 0,
    v3 = 0,
    unit = 'target',

    down = true,
    i_up = 0,
    rank = 0,
    react = 0,
    refreshable = true,
    remains = 0,
    stack = 0,
    stack_pct = 0,
    tick_time_remains = 0,
    ticking = false,
    ticks = 0,
    ticks_remain = 0,
    time_to_refresh = 0,
    up = false,
}


-- Table of default handlers for debuffs.
-- Needs review.
local mt_default_debuff = {
    mtID = "default_debuff",

    __index = function( t, k )
        local aura = class.auras[ t.key ]

        -- The aura is flagged to get info from a different target.
        if state.IsCycling( t.key ) and cycle_debuff[ k ] ~= nil then
            return cycle_debuff[ k ]
        end

        if aura and rawget( aura, "meta" ) and aura.meta[ k ] then
            return aura.meta[ k ]( t, "debuff" )

        elseif requiresLookup[ k ] then
            if aura and aura.generate then
                for attr, a_val in pairs( default_debuff_values ) do
                    t[ attr ] = rawget( t, attr ) or rawget( aura, attr ) or  a_val
                end

                aura.generate( t, "debuff" )
                t.id = aura and aura.id or t.key

                return rawget( t, k )
            end

            local real = auras.target.debuff[ t.key ] or auras.player.debuff[ t.key ]

            if real then
                t.name = real.name or t.key
                t.count = real.count
                t.lastCount = real.lastCount or 0
                t.lastApplied = real.lastApplied or 0
                t.duration = real.duration
                t.expires = real.expires or 0
                t.applied = max( 0, real.expires - real.duration )
                t.caster = real.caster
                t.id = real.id
                t.timeMod = real.timeMod
                t.v1 = real.v1
                t.v2 = real.v2
                t.v3 = real.v3

                t.unit = real.unit
            else
                for attr, a_val in pairs( default_debuff_values ) do
                    t[ attr ] = aura and aura[ attr ] or a_val
                end

                t.id = aura and aura.id or t.id
            end

            return rawget( t, k )

        elseif k == 'up' or k == 'ticking' then
            return t.remains > 0

        elseif k == 'i_up' or k == 'rank' then
            return t.up and 1 or 0

        elseif k == 'down' then
            return not t.up

        elseif k == 'remains' then
            if aura and aura.strictTiming then
                return max( 0, t.expires - state.query_time )
            end
            return max( 0, t.expires - state.query_time )

        elseif k == 'refreshable' then
            -- if state.isCyclingTargets( nil, t.key ) then return true end
            return t.remains < 0.3 * ( aura and aura.duration or t.duration or 30 )

        elseif k == 'time_to_refresh' then
            -- if state.isCyclingTargets( nil, t.key ) then return 0 end
            return t.up and ( max( 0, state.query_time - ( 0.3 * ( aura and aura.duration or t.duration or 30 ) ) ) ) or 0

        elseif k == 'stack' then
            -- if state.isCyclingTargets( nil, t.key ) then return 0 end
            if t.up then return ( t.count ) else return 0 end

        elseif k == 'react' then
            -- React returns stacks assuming you've had time to react to them.
            if state.query_time > t.applied + state.latency then
                if t.expires > state.query_time then
                    return t.count
                end
                return 0
            end

            return state.query_time > t.lastApplied and t.lastCount or 0

        elseif k == 'max_stack' or k == 'max_stacks' then
            return aura and aura.max_stack or 1

        elseif k == 'stack_pct' then
            if t.up then
                if aura then aura.max_stack = max( aura.max_stack or 1, t.count ) end
                return ( 100 * t.count / aura and aura.max_stack or t.count )
            end 

            return 0

        elseif k == 'pmultiplier' then
            -- Persistent modifier, used by Druids.
            return ns.getModifier( aura.id, state.target.unit )

        elseif k == 'ticks' then
            if t.up then return floor( 1 + ( ( aura.duration or ( 30 * state.haste ) ) / ( aura.tick_time or ( 3 * t.haste ) ) ) - t.ticks_remain ) end
            return 0

        elseif k == 'ticks_remain' then
            if not aura.tick_time then return t.remains end
            return floor( t.remains / aura.tick_time )       

        elseif k == 'tick_time_remains' then
            if not aura.tick_time then return t.remains end
            return t.remains % aura.tick_time

        else
            if aura and aura[ k ] ~= nil then
                return aura[ k ]
            end
        end

        Error ( "UNK: debuff." .. t.key .. "." .. k )
    end
}
ns.metatables.mt_default_debuff = mt_default_debuff


local unknown_debuff = setmetatable( {
    count = 0,
    expires = 0,
    timeMod = 1,
    v1 = 0,
    v2 = 0,
    v3 = 0
}, mt_default_debuff )


-- Table of debuffs applied to the target by the player.
-- Needs review.
local mt_debuffs = {
    -- The debuff/ doesn't exist in our table so check the real game state, -- and copy it so we don't have to use the API next time.
    __index = function( t, k )        
        local aura = class.auras[ k ]

        if aura then       
            if k ~= aura.key then
                t[ aura.key ] = rawget( t, aura.key ) or {
                    key = aura.key,
                    name = aura.name
                }
                t[ k ] = t[ aura.key ]
            else
                t[ k ] = {
                    key = aura.key,
                    name = aura.name
                }
            end

            if aura.generate then
                for attr, a_val in pairs( default_debuff_values ) do
                    t[ k ][ attr ] = rawget( t[ k ], attr ) or a_val
                end
                aura.generate( t[ k ], "debuff" )
                return t[ k ]
            end

        else
            t[ k ] = {
                key = k,
                name = k,
                id = k
            }

        end

        local real = auras.player.debuff[ k ] or auras.target.debuff[ k ]        
        local debuff = t[k]

        if real then
            debuff.name = real.name
            debuff.count = real.count
            debuff.lastCount = real.lastCount or 0
            debuff.lastApplied = real.lastApplied or 0
            debuff.duration = real.duration
            debuff.expires = real.expires
            debuff.applied = max( 0, real.expires - real.duration )
            debuff.caster = real.caster
            debuff.id = real.id
            debuff.timeMod = real.timeMod
            debuff.v1 = real.v1
            debuff.v2 = real.v2
            debuff.v3 = real.v3

            debuff.unit = real.unit

        else
            debuff.name = aura and aura.name or "No Name"
            debuff.count = 0
            debuff.lastCount = 0
            debuff.lastApplied = 0
            debuff.duration = aura and aura.duration or 30
            debuff.expires = 0
            debuff.applied = 0
            debuff.caster = 'nobody'
            -- debuff.id = nil
            debuff.timeMod = 1
            debuff.v1 = 0
            debuff.v2 = 0
            debuff.v3 = 0

            debuff.unit = aura and aura.unit or 'player'
        end

        t[k] = debuff
        return t[ k ]
    end, 

    __newindex = function( t, k, v )
        local aura = class.auras[ k ]

        if aura and aura.alias then
            rawset( t, k, setmetatable( v, mt_alias_debuff ) )
            return
        end

        rawset( t, k, setmetatable( v, mt_default_debuff ) )
    end
}
ns.metatables.mt_debuffs = mt_debuffs


-- Table of default handlers for actions.
-- Needs review.
local mt_default_action = {
    __index = function( t, k )
        local ability = t.action and class.abilities[ t.action ]
        local aura = ability and ability.aura or t.action

        if k == 'enabled' or k == 'known' then
            return state:IsKnown( t.action )

        elseif k == 'gcd' then
            local queued_action = state.this_action
            state.this_action = t.action

            local value = state.gcd.execute
            state.this_action = queued_action

            return value

        elseif k == 'execute_time' then
            local queued_action = state.this_action
            state.this_action = t.action

            local value = state.gcd.execute
            state.this_action = queued_action

            return max( value, t.cast_time )

        elseif k == 'charges' then
            return ability.charges and state.cooldown[ t.action ].charges or 0

        elseif k == 'charges_fractional' then
            return state.cooldown[ t.action ].charges_fractional

        elseif k == 'recharge_time' then
            return state.cooldown[ t.action ].recharge_time

        elseif k == 'max_charges' then
            return ability.charges or 0

        elseif k == 'time_to_max_charges' or k == 'full_recharge_time' then
            return ( ability.charges - state.cooldown[ t.action ].charges_fractional ) * ability.recharge

        elseif k == 'ready_time' then
            return state:IsUsable( t.action ) and state:TimeToReady( t.action ) or 999

        elseif k == 'ready' then
            return state:IsUsable( t.action ) and state:IsReady( t.action )

        elseif k == 'cast_time' then
            return ability.cast

        elseif k == 'cooldown' then
            return ability.cooldown

        elseif k == 'crit_pct_current' then
            return ability.critical or state.stat.crit

        elseif k == 'ticking' then
            return ( state.dot[ aura ].ticking )

        elseif k == 'ticks' then
            return 1 + ( state.dot[ aura ].duration or ( 30 * state.haste ) / class.auras[ aura ].tick_time or ( 3 * state.haste ) ) - t.ticks_remain

        elseif k == 'ticks_remain' then
            return state.dot[ aura ].remains / ( class.auras[ aura ].tick_time or ( 3 * state.haste ) )

        elseif k == 'remains' then
            return ( state.dot[ aura ].remains )

        elseif k == 'tick_time' then
            return class.auras[ aura ].tick_time or ( 3 * state.haste )

        elseif k == 'travel_time' then
            -- NYI: maybe capture the last travel time for the spell and use that?
            local v = ability.velocity

            if v and v > 0 then return state.target.maxR / v end
            return 0

        elseif k == 'miss_react' then
            return false

        elseif k == 'cooldown_react' then
            return false

        elseif k == 'cast_delay' then
            return 0

        elseif k == 'cast_regen' then
            return floor( max( state.gcd.execute, t.cast_time ) * state[ class.primaryResource ].regen ) -- - ( ability and t.cost or 0 )

        elseif k == 'cost' then
            local a = ability.spend
            if not a then return 0 end
            if type( a ) == 'function' then a = a() end
            if a > 0 and a < 1 then a = a * state[ ability.spendType or class.primaryResource ].modmax end
            return a

        elseif k == 'in_flight' then
            if ability and ability.flightTime then
                return ability.lastCast + ability.flightTime > state.query_time
            end

            return state:IsInFlight( t.action )

        elseif k == "in_flight_remains" then
            if ability and ability.flightTime then
                return max( 0, ability.lastCast + ability.flightTime - state.query_time )
            end

            return state:InFlightRemains( t.action )

        elseif k == "executing" then
            return state:IsCasting( t.action ) or ( state.prev[ 1 ][ t.action ] and state.gcd.remains > 0 )

        elseif k == 'execute_remains' then
            return ( state:IsCasting( t.action ) and max( state:QueuedCastRemains( t.action ), state.gcd.remains ) ) or ( state.prev[1][ t.action ] and state.gcd.remains ) or 0

        else
            local val = ability[ k ]

            if val ~= nil then
                if type( val ) == 'function' then return val() end
                return val
            end
        end

        return 0
    end
}
ns.metatables.mt_default_action = mt_default_action


-- mt_actions: provides action information for display/priority queue/action criteria.
-- NYI.
local mt_actions = {
    __index = function(t, k)
        local action = class.abilities[ k ]

        -- Need a null_action table.
        if not action then return nil end

        t[k] = {
            action = k,
            name = action.name,
            gcdType = action.gcd
        }

        local h = state.haste
        state.haste = 0
        t[k].base_cast = action.cast
        state.haste = h

        return ( t[k] )
        end, __newindex = function(t, k, v)
        rawset( t, k, setmetatable( v, mt_default_action ) )
    end
}
ns.metatables.mt_actions = mt_actions



-- mt_swings: used for projecting weapon swing-based resource gains.
local mt_swings = {
    __index = function( t, k )
        if k == 'mainhand' then
            return t.mh_pseudo and t.mh_pseudo or t.mh_actual

        elseif k == 'offhand' then
            return t.oh_pseudo and t.oh_pseudo or t.oh_actual

        elseif k == 'mainhand_speed' then
            return t.mh_pseudo_speed and t.mh_pseudo_speed or t.mh_speed

        elseif k == 'offhand_speed' then
            return t.oh_pseudo_speed and t.oh_pseudo_speed or t.oh_speed

        end
    end
}


local mt_aura = {
    __index = function( t, k )
        return rawget( state.buff, k ) or rawget( state.debuff, k )
    end
}


setmetatable( state, mt_state )
setmetatable( state.action, mt_actions )
setmetatable( state.active_dot, mt_active_dot )
-- setmetatable( state.azerite, mt_artifact_traits ) -- already set above.
setmetatable( state.aura, mt_aura )
setmetatable( state.buff, mt_buffs )
setmetatable( state.cooldown, mt_cooldowns )
setmetatable( state.debuff, mt_debuffs )
setmetatable( state.dot, mt_dot )
setmetatable( state.equipped, mt_equipped )
-- setmetatable( state.health, mt_resource )
setmetatable( state.pet, mt_pets )
setmetatable( state.pet.fake_pet, mt_default_pet )
setmetatable( state.prev, mt_prev )
setmetatable( state.prev_gcd, mt_prev )
setmetatable( state.prev_off_gcd, mt_prev )
setmetatable( state.pvptalent, mt_pvptalents )
setmetatable( state.race, mt_false )
setmetatable( state.set_bonus, mt_set_bonuses )
setmetatable( state.settings, mt_settings )
setmetatable( state.spec, mt_spec )
setmetatable( state.stance, mt_stances )
setmetatable( state.stat, mt_stat )
setmetatable( state.swings, mt_swings )
setmetatable( state.talent, mt_talents )
setmetatable( state.target, mt_target )
setmetatable( state.target.health, mt_target_health )
setmetatable( state.toggle, mt_toggle )
setmetatable( state.totem, mt_totem )



local all = class.specs[ 0 ]

-- 04072017: Let's go ahead and cache aura information to reduce overhead.
local autoAuraKey = setmetatable( {}, {
    __index = function( t, k )
        local aura_name = GetSpellInfo( k )

        if not aura_name then return end

        local name

        if class.auras[ aura_name ] then
            local i = 1

            while( true ) do
                local new = aura_name .. ' ' .. i

                if not class.auras[ new ] then
                    name = new
                    break
                end

                i = i + 1
            end
        end
        name = name or aura_name

        local key = formatKey( aura_name )

        if class.auras[ key ] then
            local i = 1

            while ( true ) do 
                local new = key .. '_' .. i

                if not class.auras[ new ] then
                    key = new
                    break
                end

                i = i + 1
            end
        end

        -- Store the aura and save the key if we can.
        if not all then all = class.specs[ 0 ] end
        if all then
            all:RegisterAura( key, {
                id = k,
                name = name
            } )
        end
        t[k] = key

        return t[k]
    end
} )



do
    local scraped = {}

    function state.ScrapeUnitAuras( unit, newTarget )
        local db = ns.auras[ unit ]

        if scraped[ unit ] then
            for k,v in pairs( db.buff ) do
                v.name = nil
                v.lastCount = newTarget and 0 or v.count
                v.lastApplied = newTarget and 0 or v.applied

                v.last_application = max( 0, v.applied, v.last_application )
                v.last_expiry  = max( 0, v.expires, v.last_expiry )

                v.count = 0
                v.expires = 0
                v.applied = 0
                v.duration = class.auras[ k ] and class.auras[ k ].duration or v.duration
                v.caster = 'nobody'
                v.timeMod = 1
                v.v1 = 0
                v.v2 = 0
                v.v3 = 0
                v.unit = unit
            end

            for k,v in pairs( db.debuff ) do
                v.name = nil
                v.lastCount = newTarget and 0 or v.count
                v.lastApplied = newTarget and 0 or v.applied
                v.count = 0
                v.expires = 0
                v.applied = 0
                v.duration = class.auras[ k ] and class.auras[ k ].duration or v.duration
                v.caster = 'nobody'
                v.timeMod = 1
                v.v1 = 0
                v.v2 = 0
                v.v3 = 0
                v.unit = unit
            end

            scraped[ unit ] = false
        end

        if not UnitExists( unit ) then return end

        scraped[ unit ] = true

        local i = 1
        while ( true ) do
            local name, _, count, _, duration, expires, caster, _, _, spellID, _, _, _, _, timeMod, v1, v2, v3 = UnitBuff( unit, i, "PLAYER" )
            if not name then break end

            local key = class.auras[ spellID ] and class.auras[ spellID ].key
            -- if not key then key = class.auras[ name ] and class.auras[ name ].key end
            if not key then key = autoAuraKey[ spellID ] end

            if key then 
                db.buff[ key ] = db.buff[ key ] or {}
                local buff = db.buff[ key ]

                if expires == 0 then
                    expires = GetTime() + 3600
                    duration = 7200
                end

                buff.key = key
                buff.id = spellID
                buff.name = name
                buff.count = count > 0 and count or 1
                buff.expires = expires
                buff.duration = duration
                buff.applied = expires - duration
                buff.caster = caster
                buff.timeMod = timeMod
                buff.v1 = v1
                buff.v2 = v2
                buff.v3 = v3
                
                buff.last_application = buff.last_application or 0
                buff.last_expiry      = buff.last_expiry or 0

                buff.unit = unit
            end

            i = i + 1
        end

        i = 1
        while ( true ) do
            local name, _, count, _, duration, expires, caster, _, _, spellID, _, _, _, _, timeMod, v1, v2, v3 = UnitDebuff( unit, i, unit ~= "player" and "PLAYER" or nil )
            if not name then break end

            local key = class.auras[ spellID ] and class.auras[ spellID ].key
            -- if not key then key = class.auras[ name ] and class.auras[ name ].key end
            if not key then key = autoAuraKey[ spellID ] end

            if key then 
                db.debuff[ key ] = db.debuff[ key ] or {}
                local debuff = db.debuff[ key ]

                if expires == 0 then
                    expires = GetTime() + 3600
                    duration = 7200
                end

                debuff.key = key
                debuff.id = spellID
                debuff.name = name
                debuff.count = count > 0 and count or 1
                debuff.expires = expires
                debuff.duration = duration
                debuff.applied = expires - duration
                debuff.caster = caster
                debuff.timeMod = timeMod
                debuff.v1 = v1
                debuff.v2 = v2
                debuff.v3 = v3

                debuff.unit = unit
            end

            i = i + 1
        end
    end

    Hekili.ScrapeUnitAuras = state.ScrapeUnitAuras
    Hekili:ProfileCPU( "ScrapeUnitAuras", state.ScrapeUnitAuras )

    Hekili.AuraDB = ns.auras
end
local ScrapeUnitAuras = state.ScrapeUnitAuras


-- Helper functions to query the real aura data that has been scraped.
-- Used for snapshotting projectile data to be handled when a spell impacts.
function state.PlayerBuffUp( buff )
    local aura = state.auras.player.buff[ buff ]
    return aura and aura.expires > GetTime()
end

function state.PlayerDebuffUp( debuff )
    local aura = state.auras.player.debuff[ debuff ]
    return aura and aura.expires > GetTime()
end

function state.TargetBuffUp( buff )
    local aura = state.auras.target.buff[ buff ]
    return aura and aura.expires > GetTime()
end

function state.TargetDebuffUp( debuff )
    local aura = state.auras.target.debuff[ debuff ]
    return aura and aura.expires > GetTime()
end


function state.putTrinketsOnCD( val )
    val = val or 10

    for i, item in ipairs( state.items ) do
        if not class.abilities[ item ].essence then setCooldown( item, val ) end
    end
end


do
    -- Simpler Queue System
    local realQueue = {}
    state.realQueue = realQueue

    local virtualQueue = {}
    state.queue = virtualQueue

    local byTime = function( a, b )
        return a.time < b.time
    end


    local eventPool = {}

    local function NewEvent()
        if #eventPool > 0 then
            return remove( eventPool, 1 )
        end

        return {}
    end

    local function RecycleEvent( queue, i )
        local e = queue[ i ]

        if e then
            e.action = nil
            e.start  = nil
            e.time   = nil
            e.type   = nil
            e.target = nil

            insert( eventPool, e )
            remove( queue, i )
        end
    end

    function state:QueueEvent( action, start, time, type, target, real )
        local queue = real and realQueue or virtualQueue
        local e = NewEvent()

        if not time then
            local ability = class.abilities[ action ]

            if ability then
                if type == "PROJECTILE_IMPACT" then
                    if ability.flightTime then time = start + ability.flightTime
                    else time = start + ( state.target.distance / ability.velocity ) end
                
                elseif type == "CHANNEL_START" then
                    time = start
                
                elseif type == "CHANNEL_FINISH" or type == "CAST_FINISH" then
                    time = start + ability.cast

                end
            end
        end

        if action and start and time and type then
            if time < start then time = start + time end

            e.action = action
            e.start  = start
            e.time   = time
            e.type   = type
            e.target = target

            insert( queue, e )
            sort( queue, byTime )

            if Hekili.ActiveDebug and not real then Hekili:Debug( "Queued %s from %.2f to %.2f (%s).", action, start, time, type ) end
        end
    end

    function state:RemoveEvent( e, real )
        local queue = real and realQueue or virtualQueue

        Hekili:Debug( "Trying to remove %s %s from queue.", e.action, e.type )

        for i = #queue, 1, -1 do
            if queue[ i ] == e then
                Hekili:Debug( "Removing %d from queue.", i )
                RecycleEvent( queue, i )
                break
            end
        end
    end

    function state:GetEventInfo( action, start, time, type, target, real )
        local queue = real and realQueue or virtualQueue
        
        -- Find the first event that matches the provided criteria and return all the data.
        for i, event in ipairs( queue ) do
            if ( not action or event.action == action ) and
               ( not start  or event.start  == start  ) and
               ( not time   or event.time   == time   ) and
               ( not type   or event.type   == type   ) and
               ( not target or event.target == target ) then
            
               return event.action, event.start, event.time, event.type, event.target
            end
        end
    end

    function state:RemoveSpellEvents( action, real, eType )
        local queue = real and realQueue or virtualQueue

        local success = false

        for i = #queue, 1, -1 do
            local e = queue[ i ]

            if e.action == action and ( eType == nil or e.type == eType ) then
                RecycleEvent( queue, i )
                success = true
            end
        end

        return success
    end

    function state:ResetQueues()
        for i = #virtualQueue, 1, -1 do
            RecycleEvent( virtualQueue, i )
        end

        local now = GetTime()

        for i = #realQueue, 1, -1 do
            local e = realQueue[ i ]

            if e.time < now then
                RecycleEvent( realQueue, i )
            end
        end

        for i, r in ipairs( realQueue ) do
            local e = NewEvent()

            e.action = r.action
            e.start  = r.start
            e.time   = r.time
            e.type   = r.type
            e.target = r.target

            virtualQueue[ i ] = e
        end
    end


    local times = {}

    function state:GetQueueTimes( queue )
        wipe( times )

        for i, v in ipairs( queue ) do
            times[ i ] = v.time
        end

        return unpack( times )
    end


    function state:GetQueue( real )
        if real then return realQueue end
        return virtualQueue
    end


    function state:HandleEvent( e )
        if not e then return end

        local action = e.action
        local ability = class.abilities[ e.action ]
        
        if not ability then
            state:RemoveEvent( e )
            return
        end

        local curr_action = self.this_action
        self.this_action = action

        if Hekili.ActiveDebug then Hekili:Debug( "\nHandling %s at %.2f (%s).", action, e.time, e.type ) end

        if e.type == "CAST_FINISH" then
            self.hardcast = true
            local cooldown = ability.cooldown

            -- Put the action on cooldown. (It's slightly premature, but addresses CD resets like Echo of the Elements.)
            -- if ability.charges and ability.charges > 1 and ability.recharge > 0 then
            if ability.charges and ability.recharge > 0 then
                self.spendCharges( action, 1 )

            elseif action ~= 'global_cooldown' then
                self.setCooldown( action, cooldown )
            end

            -- Spend resources.
            ns.spendResources( action )

            -- Perform the action.            
            self:RunHandler( action )
            self.hardcast = nil

            if ability.item and not ability.essence then
                self.putTrinketsOnCD( cooldown / 6 )
            end

        elseif e.type == "CHANNEL_TICK" then
            if ability.tick then ability.tick() end

        elseif e.type == "CHANNEL_FINISH" then
            if ability.finish then ability.finish() end
            self.stopChanneling()

        elseif e.type == "PROJECTILE_IMPACT" then
            if ability.impact then ability.impact() end
            self:StartCombat()
        
        end

        scripts:ResetCache()

        state.this_action = curr_action
        state:RemoveEvent( e )
    end


    function state:IsQueued( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if entry.action == action then return true end
        end

        return false
    end


    function state:IsInFlight( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if entry.action == action and entry.type == "PROJECTILE_IMPACT" and entry.start <= self.query_time then return true end
        end

        return false
    end


    function state:InFlightRemains( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if entry.action == action and entry.type == "PROJECTILE_IMPACT" and entry.start <= self.query_time then return max( 0, entry.time - self.query_time ) end
        end

        return 0
    end


    local cast_events = {
        CAST_FINISH = true,
        CHANNEL_FINISH = true
    }

    function state:IsCasting( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if entry.type == "CAST_FINISH" and ( action == nil or entry.action == action ) and entry.start <= self.query_time then return true end
        end

        return false
    end


    function state:QueuedCastRemains( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if cast_events[ entry.type ] and ( action == nil or entry.action == action ) and entry.start <= self.query_time then return max( 0, entry.time - self.query_time ) end
        end

        return 0
    end


    function state:IsChanneling( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if entry.type == "CHANNEL_FINISH" and ( action == nil or entry.action == action ) and entry.start <= self.query_time then return true end
        end

        return false
    end


    function state:ApplyCastingAuraFromQueue( action, real )
        local queue = real and realQueue or virtualQueue

        for i, entry in ipairs( queue ) do
            if cast_events[ entry.type ] and ( action == nil or entry.action == action ) and entry.start <= self.query_time then
                self.applyBuff( "casting", entry.time - self.query_time )
                break
            end
        end
    end
end



function state:RunHandler( key, noStart )
    local ability = class.abilities[ key ]

    if not ability then
        -- ns.Error( "runHandler() attempting to run handler for non-existant ability '" .. key .. "'." )
        return
    end

    if state.channeling then state.stopChanneling() end

    if ability.channeled and ability.start then ability.start()
    elseif ability.handler then ability.handler() end

    self.prev.last = key
    self[ ability.gcd == 'off' and 'prev_off_gcd' or 'prev_gcd' ].last = key

    table.insert( self.predictions, 1, key )
    table.insert( self[ ability.gcd == 'off' and 'predictionsOff' or 'predictionsOn' ], 1, key )

    self.history.casts[ key ] = self.query_time

    self.predictions[6] = nil
    self.predictionsOn[6] = nil
    self.predictionsOff[6] = nil

    self.prev.override = nil
    self.prev_gcd.override = nil
    self.prev_off_gcd.override = nil

    if self.time == 0 and ability.startsCombat and not noStart then
        self.false_start = self.query_time - 0.01

        -- Assume MH swing at combat start and OH swing half a swing later?
        if self.target.distance < 8 then
            if self.swings.mainhand_speed > 0 and self.nextMH == 0 then self.swings.mh_pseudo = self.false_start end
            if self.swings.offhand_speed > 0 and self.nextOH == 0 then self.swings.oh_pseudo = self.false_start + ( self.offhand_speed / 2 ) end
        end
    end

    -- state.cast_start = 0
    ns.callHook( 'runHandler', key )    
end

function state.runHandler( key, noStart )
    state:RunHandler( key, noStart )
end


function state.reset( dispName )
    state.now = GetTime()
    state.index = 0
    state.scriptID = nil
    state.offset = 0
    state.delay = 0
    state.false_start = 0

    state.resetting = true

    state.ClearCycle()
    state:ResetVariables()    
    scripts:ResetCache()

    state.selectionTime = 60
    state.selectedAction = nil

    local _, zone = GetInstanceInfo()

    state.bg = zone == 'pvp'
    state.arena = zone == 'arena'

    state.min_targets = 0
    state.max_targets = 0

    state.active_enemies = nil
    state.my_enemies = nil
    state.true_active_enemies = nil
    state.true_my_enemies = nil

    state.cycle = nil

    state.latency = select( 4, GetNetStats() ) / 1000

    -- Projectiles
    state:ResetQueues()

    local p = Hekili.DB.profile

    local display = dispName and p.displays[ dispName ]
    local spec = state.spec.id and p.specs[ state.spec.id ]
    local mode = p.toggles.mode.value

    state.display = dispName
    state.filter = 'none'
    state.rangefilter = false

    if display then
        if dispName == 'Primary' then
            if mode == "single" or mode == "dual" or mode == "reactive" then state.max_targets = 1
            elseif mode == "aoe" then state.min_targets = spec and spec.aoe or 3 end
        elseif dispName == 'AOE' then state.min_targets = spec and spec.aoe or 3
        elseif dispName == 'Interrupts' then state.filter = 'interrupts'
        elseif dispName == 'Defensives' then state.filter = 'defensives'
        end

        state.rangefilter = display.range.enabled and display.range.type == 'xclude'
    end

    for i = #state.purge, 1, -1 do
        state[ state.purge[ i ] ] = nil
        table.remove( state.purge, i )
    end

    for k in pairs( state.active_dot ) do
        state.active_dot[ k ] = nil
    end

    for k in pairs( state.stat ) do
        state.stat[ k ] = nil
    end

    state.haste = nil

    if state.target.updated then
        ScrapeUnitAuras( 'target' )
        state.target.updated = false
    end

    if state.player.updated then
        ScrapeUnitAuras( 'player' )
        state.player.updated = false
    end


    for k, v in pairs( state.buff ) do
        for attr in pairs( default_buff_values ) do
            v[ attr ] = nil
        end
        v.lastCount = nil
        v.lastApplied = nil
    end

    for k, v in pairs( state.cooldown ) do
        v.duration = nil
        v.expires = nil
        v.charge = nil
        v.next_charge = nil
        v.recharge_began = nil
        v.recharge_duration = nil
        v.true_expires = nil
        v.true_remains = nil
    end

    state.trinket.t1.cooldown.duration = nil
    state.trinket.t1.cooldown.expires = nil
    state.trinket.t2.cooldown.duration = nil
    state.trinket.t2.cooldown.expires = nil

    for k, v in pairs( state.debuff ) do
        for attr in pairs( default_debuff_values ) do
            v[ attr ] = nil            
        end
        v.lastCount = nil
        v.lastApplied = nil
    end

    state.pet.exists = nil
    for k, v in pairs( state.pet ) do
        if type(v) == 'table' and k ~= 'fake_pet' then
            v.expires = nil
        end
    end
    -- rawset( state.pet, 'exists', UnitExists( 'pet' ) )

    for k in pairs( state.stance ) do
        state.stance[ k ] = nil
    end

    for k in pairs( class.stateTables ) do
        if rawget( state[ k ], "onReset" ) then state[ k ].onReset( state[ k ] ) end
    end

    for k in pairs( state.totem ) do
        state.totem[ k ].expires = nil
    end

    for k, v in pairs( state.pet ) do
        if type(v) == 'table' then
            v.expires = 0
            
            if not rawget( v, "key" ) then
                v.key = k
            end
        end
    end

    local petID = UnitGUID( "pet" )
    if petID then
        petID = tonumber( petID:match( "%-(%d+)%-[0-9A-F]+$" ) )

        for k, v in pairs( class.pets ) do
            local id = v.id and ( type( v.id ) == 'function' and v.id() ) or v.id

            if id == petID then
                local lastCast = v.spell and class.abilities[ v.spell ] and class.abilities[ v.spell ].lastCast or 0
                local duration = v.duration and ( ( type( v.duration ) == 'function' and v.duration() ) or v.duration ) or 3600

                if lastCast > 0 and duration < 3600 then
                    summonPet( k, lastCast + duration - state.now )
                else
                    summonPet( k )
                end
            end
        end
    end

    for i = 1, 5 do
        local _, _, start, duration, icon = GetTotemInfo(i)

        if icon and class.totems[ icon ] then
            summonPet( class.totems[ icon ], start + duration - state.now )
        end
    end

    for k, v in pairs( state.pet ) do
        if type(v) == 'table' and k ~= 'fake_pet' and v.summonTime and v.summonTime > 0 and v.duration then
            local remains = ( v.summonTime + v.duration ) - state.now
            if remains > 0 then
                summonPet( k, remains )
            else
                v.summonTime = 0
            end
        end
    end    

    state.target.health.actual = nil
    state.target.health.current = nil
    state.target.health.max = nil

    state.tanking = state.role.tank and ( UnitThreatSituation( 'player' ) or 0 ) > 1

    -- range checks
    state.target.minR = nil
    state.target.maxR = nil
    state.target.distance = nil

    state.prev.last = state.player.lastcast
    state.prev.override = nil

    state.prev_gcd.last = state.player.lastgcd
    state.prev_gcd.override = nil

    state.prev_off_gcd.last = state.player.lastoffgcd
    state.prev_off_gcd.override = nil

    for i = 1, 5 do
        state.predictions[i] = nil
        state.predictionsOn[i] = nil
        state.predictionsOff[i] = nil
    end

    wipe( state.history.casts )
    wipe( state.history.units )

    local last_act = state.player.lastcast and class.abilities[ state.player.lastcast ]
    if last_act and last_act.startsCombat and state.combat == 0 and state.now - last_act.lastCast < 1 then
        state.false_start = last_act.lastCast - 0.01
    end

    -- interrupts
    state.target.casting = nil

    for k, power in pairs( class.resources ) do
        local res = rawget( state, k )

        if res then
            res.actual = UnitPower( 'player', power.type )
            res.max = UnitPowerMax( 'player', power.type )

            res.modmax = res.max
            if k == "mana" and state.spec.arcane then
                res.modmax = res.modmax / ( 1 + state.mastery_value )
            end

            res.last_tick = rawget( res, 'last_tick' ) or 0
            res.tick_rate = rawget( res, 'tick_rate' ) or 0.1

            if power.type == Enum.PowerType.Mana then 
                local inactive, active = GetManaRegen()

                res.active_regen = active or 0
                res.inactive_regen = inactive or 0

            else
                if ResourceRegenerates( k ) then
                    local inactive, active = GetPowerRegenForPowerType( power.type )
                    res.active_regen = active or 0
                    res.inactive_regen = inactive or 0
                    res.regen = nil
                else
                    res.regen = 0
                end
            end

            if res.reset then res.reset() end
            forecastResources( k )            
        end
    end

    state.health = rawget( state, "health" ) or setmetatable( { resource = "health" }, mt_resource )
    state.health.current = nil
    state.health.actual = UnitHealth( 'player' ) or 10000
    state.health.max = UnitHealthMax( 'player' ) or 10000
    state.health.regen = 0

    state.swings.mh_speed, state.swings.oh_speed = UnitAttackSpeed( 'player' )
    state.swings.mh_speed = state.swings.mh_speed or 0
    state.swings.oh_speed = state.swings.oh_speed or 0

    state.mainhand_speed = state.swings.mh_speed
    state.offhand_speed = state.swings.oh_speed

    state.nextMH = ( state.combat > 0 and state.swings.mh_actual > state.combat and state.swings.mh_actual + state.mainhand_speed ) or 0
    state.nextOH = ( state.combat > 0 and state.swings.oh_actual > state.combat and state.swings.oh_actual + state.offhand_speed ) or 0

    state.swings.mh_pseudo = nil    
    state.swings.oh_pseudo = nil

    -- Special case spells that suck.
    if class.abilities[ 'ascendance' ] and state.buff.ascendance.up then
        setCooldown( 'ascendance', state.buff.ascendance.remains + 165 )
    end

    local cast_time, casting, ability = 0, nil, nil

    if state.buff.casting.up then
        cast_time = state.buff.casting.remains

        local castID = state.buff.casting.v1
        ability = class.abilities[ castID ]

        casting = ability and ability.key or formatKey( state.buff.casting.name )

        if castID == class.abilities.cyclotronic_blast.id then
            -- Set up Pocket-Sized Computation Device.
            if state.buff.casting.v3 then
                -- We are in the channeled part of the cast.
                setCooldown( "pocketsized_computation_device", state.buff.casting.applied + 120 - state.now )
                setCooldown( "global_cooldown", cast_time )
            else
                -- This is the casting portion.
                casting = class.abilities.pocketsized_computation_device.key
                state.buff.casting.v1 = class.abilities.pocketsized_computation_device.id
            end
        end
    end

    ns.callHook( "reset_precast" )

    -- Okay, two paths here.
    -- 1.  We can cast while casting (i.e., Fire Blast for Fire Mage), so we want to hand off the current cast to the event system, and then let the recommendation engine sort it out.
    -- 2.  We cannot cast anything while casting (typical), so we want to advance the clock, complete the cast, and then generate recommendations.

    if casting and cast_time > 0 then
        if not state:IsCasting( casting ) then
            state:QueueEvent( casting, state.buff.casting.applied, state.buff.casting.expires, ability and ability.channeled and "CHANNEL_FINISH" or "CAST_FINISH", state.target.GUID )
        end

        if not state.spec.canCastWhileCasting then
            if ( not ability or not ability.breakable ) then
                -- Revisit auto-advance, we may be overcompensating for it now that we use the queue.
                state.setCooldown( "global_cooldown", max( cast_time, state.cooldown.global_cooldown.remains ) )

                if ability and dispName ~= "Interrupts" and dispName ~= "Defensives" then
                    if not ability.channeled then
                        state.advance( max( cast_time, state:QueuedCastRemains( casting, true ) ) )

                    elseif ability.postchannel then
                        ability.postchannel()

                    end
                end
            end
        end
    end    

    -- Delay to end of GCD.
    if dispName == "Primary" or dispName == "AOE" then
        local delay = 0

        if state.settings.spec and state.settings.spec.gcdSync then
            delay = state.cooldown.global_cooldown and state.cooldown.global_cooldown.remains or 0
        end

        if not state.spec.canCastWhileCasting and state.buff.casting.up and not state.buff.casting.v3 then -- v3 means it's channeled.
            delay = max( delay, state.buff.casting.remains )
        end

        delay = ns.callHook( "reset_postcast", delay )

        if delay > 0 then
            if Hekili.ActiveDebug then Hekili:Debug( "Advancing by %.2f per GCD or cast or channel or reset_postcast value.", delay ) end
            state.advance( delay )
        end
    end

    state.resetting = false
end


Hekili:ProfileCPU( "state.reset", state.reset )


function state:SetConstraint( min, max )
    state.delayMin = min or 0
    state.delayMax = max or 3600
end


function state:SetWhitelist( t )
    state.whitelist = t
end


function state:StartCombat()
    self.false_start = self.query_time - 0.01
    if self.swings.mainhand_speed > 0 and self.nextMH == 0 then self.swings.mh_pseudo = self.false_start end
    if self.swings.offhand_speed > 0 and self.nextOH == 0 then self.swings.oh_pseudo = self.false_start + ( self.offhand_speed / 2 ) end
end


function state.advance( time )

    if time <= 0 then
        return
    end

    if Hekili.ActiveDebug then Hekili:Debug( "Advancing clock by %.2f...", time ) end

    time = ns.callHook( 'advance', time ) or time
    if not state.resetting then time = roundUp( time, 2 ) end

    state.delay = 0

    local realOffset = state.offset

    if state.player.queued_ability then
        local lands = max( state.now + 0.01, state.player.queued_lands )

        if lands > state.query_time and lands <= state.query_time + time then
            state.offset = lands - state.query_time
            if Hekili.ActiveDebug then Hekili:Debug( "Using queued ability '" .. state.player.queued_ability .. "' at " .. state.query_time .. "." ) end
            state:RunHandler( state.player.queued_ability, true )

            state.offset = realOffset
        end
    end

    local events = state:GetQueue()
    local event = events[ 1 ]

    local eCount = 0

    while( event ) do
        if event.time > state.query_time and event.time <= state.query_time + time then
            state.offset = event.time - state.now

            if Hekili.ActiveDebug then Hekili:Debug( "While advancing by %.2f to %.2f, %s %s occurred at %.2f.", time, realOffset + time, event.action, event.type, state.offset ) end

            state:HandleEvent( event )

            event = events[ 1 ]
            state.offset = realOffset
        else
            break
        end
        
        eCount = eCount + 1
        if eCount == 10 then break end
    end

    for k in pairs( class.resources ) do
        local resource = state[ k ]

        if not resource.regenModel then
            local override = ns.callHook( 'advance_resource_regen', false, k, time )

            if not override and resource.regen and resource.regen ~= 0 then
                resource.actual = min( resource.max, max( 0, resource.actual + ( resource.regen * time ) ) )
            end
        else
            -- revisit this, may want to forecastResources( k ) instead.
            state.delay = time
            resource.actual = resource.current
            state.delay = 0
        end
    end

    state.offset = state.offset + time

    local bonus_cdr = 0 -- ns.callHook( 'advance_bonus_cdr', 0 )

    for k, cd in pairs( state.cooldown ) do
        if state:IsKnown( k ) then
            if bonus_cdr > 0 then
                if cd.next_charge > 0 then
                    cd.next_charge = cd.next_charge - bonus_cdr
                end
                cd.expires = max( 0, cd.expires - bonus_cdr )
                cd.true_expires = max( 0, cd.expires - bonus_cdr )
            end

            local ability = class.abilities[ k ]

            while ability.charges and ability.charges > 1 and cd.next_charge > 0 and cd.next_charge < state.now + state.offset do
                -- if class.abilities[ k ].charges and cd.next_charge > 0 and cd.next_charge < state.now + state.offset then
                cd.charge = cd.charge + 1
                if cd.charge < class.abilities[ k ].charges then
                    cd.recharge_began = cd.next_charge
                    cd.next_charge = cd.next_charge + class.abilities[ k ].recharge
                else 
                    cd.recharge_began = 0
                    cd.next_charge = 0
                end
            end
        end
    end

    ns.callHook( 'advance_end', time )

    return time
end


function state.GetResourceType( ability )
    local action = class.abilities[ ability ]

    if not action then return end

    if action.spend ~= nil then
        if type( action.spend ) == 'number' then
            return action.spendType or class.primaryResource

        elseif type( action.spend ) == 'function' then
            return select( 2, action.spend() ) or action.spendType or class.primaryResource

        end
    end

    return nil
end


local hysteria_resources = {
    mana            = true,
    rage            = true,
    focus           = true,
    energy          = true,
    runic_power     = true,
    astral_power    = true,
    maelstrom       = true,
    insanity        = true,
    fury            = true,
    pain            = true
}

ns.spendResources = function( ability )
    local action = class.abilities[ ability ]

    if not action then return end

    -- First, spend resources.
    if action.spend ~= nil then
        local cost, resource

        if type( action.spend ) == 'number' then
            cost = action.spend
            resource = action.spendType or class.primaryResource
        elseif type( action.spend ) == 'function' then
            cost, resource = action.spend()
            resource = resource or action.spendType or class.primaryResource
        else
            cost = cost or 0
            resource = resource or 'health'
        end

        if cost > 0 and cost < 1 then
            cost = ( cost * state[ resource ].modmax )
        end

        if state.debuff.hysteria.up and hysteria_resources[ resource ] then
            cost = cost + ( .03 * state.debuff.hysteria.stack * cost )
        end            

        if cost ~= 0 then
            state.spend( cost, resource )            
        end
    end
end
state.SpendResources = ns.spendResources


do
    local HOLD_PERMANENT = 1
    local HOLD_COMBAT    = 2
    
    function Hekili:PlaceHold( action, combat, verbose )
        if not action then return end

        action = action:trim()    
        local ability = class.abilities[ action ]

        if not ability then
            action = action:lower()
            -- Try to auto-complete.
            for k, v in orderedPairs( class.abilities ) do
                if type(k) == 'string' and k:sub( 1, action:len() ):lower() == action then
                    action = v.key
                    ability = class.abilities[ action ]
                    break
                end
            end
        end

        if ability then
            state.holds[ ability.key ] = combat and HOLD_COMBAT or HOLD_PERMANENT
            if verbose then Hekili:Print( class.abilities[ ability.key ].name .. " placed on hold" .. ( combat and " until end of combat." or "." ) ) end
            Hekili:ForceUpdate( "HEKILI_HOLD_APPLIED" )
        end
    end

    function Hekili:RemoveHold( action, verbose )
        if not action then return end

        action = action:trim()
        local ability = class.abilities[ action ]

        if not ability then
            action = action:lower()
            -- Try to auto-complete.
            for k, v in orderedPairs( class.abilities ) do
                if type(k) == 'string' and k:sub( 1, action:len() ):lower() == action then
                    action = v.key
                    ability = class.abilities[ action ]
                    break
                end
            end
        end

        if ability and state.holds[ ability.key ] then
            state.holds[ ability.key ] = nil
            if verbose then Hekili:Print( class.abilities[ ability.key ].name .. " hold removed." ) end
            Hekili:ForceUpdate( "HEKILI_HOLD_REMOVED" )
        end
    end

    function Hekili:ToggleHold( action, combat, verbose )
        if self:IsHeld( action ) then
            self:RemoveHold( action, verbose )
            return
        end

        self:PlaceHold( action, combat, verbose )
    end

    function Hekili:IsHeld( action )
        action = action and action:trim()
        local ability = class.abilities[ action ]

        if not ability then
            action = action:lower()
            -- Try to auto-complete.
            for k, v in orderedPairs( class.abilities ) do
                if type(k) == 'string' and k:sub( 1, action:len() ):lower() == action then
                    action = v.key
                    ability = class.abilities[ action ]
                    break
                end
            end
        end

        if ability and state.holds[ ability.key ] then
            return true, state.holds[ ability.key ]
        end

        return false
    end

    function Hekili:ReleaseHolds( combat )
        local holdRemoved = false

        for k, v in pairs( state.holds ) do
            if not combat or v == HOLD_COMBAT then
                state.holds[ k ] = nil
                holdRemoved = true
            end
        end

        if holdRemoved then Hekili:ForceUpdate( "HEKILI_COMBAT_HOLD_REMOVED" ) end
    end
end


function state:IsKnown( sID, notoggle )

    if type(sID) ~= 'number' then sID = class.abilities[ sID ] and class.abilities[ sID ].id or nil end

    if not sID then
        return false, "could not find valid ID" -- no ability

    elseif sID < 0 then
        return true

    end

    local ability = class.abilities[ sID ]

    if not ability then
        Error( "IsKnown() - " .. sID .. " not found in abilities table." )
        return false
    end

    local profile = Hekili.DB.profile

    if ability.spec and not state.spec[ ability.spec ] then
        return false, "wrong specialization"
    end

    if ability.nospec and state.spec[ ability.nospec ] then
        return false, "spec [ " .. ability.nospec .. " ] disallowed"
    end

    if ability.talent and not state.talent[ ability.talent ].enabled then
        return false, "talent [ " .. ability.talent .. " ] missing"
    end

    if ability.notalent and state.talent[ ability.notalent ].enabled then
        return false, "talent [ " .. ability.notalent .. " ] disallowed"
    end

    if ability.pvptalent and not state.pvptalent[ ability.pvptalent ].enabled then
        return false, "PvP talent [ " .. ability.pvptalent .. " ] missing"
    end

    if ability.nopvptalent and state.pvptalent[ ability.nopvptalent ].enabled then
        return false, "PvP talent [ " ..ability.nopvptalent .. " ] disallowed"
    end

    if ability.trait and not state.artifact[ ability.trait ].enabled then
        return false, "trait [ " .. ability.trait .. " ] missing"
    end

    if ability.equipped and not state.equipped[ ability.equipped ] then
        return false, "equipment [ " .. ability.equipped .. " ] missing"
    end

    if ability.item and not state.equipped[ ability.item ] then
        return false, "item [ " .. ability.item .. " ] missing"
    end

    if ability.known ~= nil then
        if type( ability.known ) == 'number' then
            return IsPlayerSpell( ability.known ), "IsPlayerSpell"
        end
        return ability.known
    end

    return ( ability.item and true ) or IsPlayerSpell( sID ) or IsSpellKnown( sID ) or IsSpellKnown( sID, true )

end



do
    local LSR = LibStub( "SpellRange-1.0" )

    local toggleSpells = {
        potion = true,
        cancel_buff = true
    }

    -- If an ability has been manually disabled, don't consider it.    
    function state:IsDisabled( spell, strict )
        spell = spell or self.this_action

        local ability = class.abilities[ spell ]
        if not ability then return false end

        spell = ability.key

        if self.holds[ spell ] then return true end

        local profile = Hekili.DB.profile
        local spec = profile.specs[ state.spec.id ]

        local option = ability.item and spec.items[ spell ] or spec.abilities[ spell ]

        if option.disabled then return true end
        if option.boss and not state.boss then return true end

        if not strict then
            local toggle = option.toggle
            if not toggle or toggle == 'default' then toggle = ability.toggle end

            if ability.id < -100 or ability.id > 0 or toggleSpells[ spell ] then
                if state.filter ~= 'none' and state.filter ~= toggle and not ability[ state.filter ] then return true
                elseif ability.item and not state.equipped[ ability.item ] then return false
                elseif toggle and toggle ~= 'none' then
                    if not self.toggle[ toggle ] or ( profile.toggles[ toggle ].separate and state.filter ~= toggle ) then return true end
                end
            end
        end

        return false
    end


    local LRC = LibStub( "LibRangeCheck-2.0" )

    -- Filter out non-resource driven issues with abilities.
    -- Unusable abilities are treated as on CD unless overridden.
    function state:IsUsable( spell )        
        spell = spell or self.this_action

        local ability = class.abilities[ spell ]    
        if not ability then return true end

        local profile = Hekili.DB.profile

        if self.rangefilter and UnitExists( 'target' ) then
            if LSR.IsSpellInRange( ability.id, 'target' ) == 0 then
                return false, "filtered out of range"
            end

            if ability.range then
                local _, dist = LRC:GetRange( "target", true )

                if dist and dist > ability.range then
                    return false, "not within ability-specified range (" .. ability.range .. ")"
                end
            end
        end

        if ability.item then
            if not self.equipped[ ability.item ] then
                return false, "item not equipped"
            end
        else
            local cfg = self.settings.spec and self.settings.spec.abilities[ spell ]

            if cfg then
                if cfg.targetMin > 0 and self.active_enemies < cfg.targetMin then
                    return false, "active_enemies[" .. self.active_enemies .. "] is less than ability's minimum targets [" .. cfg.targetMin .. "]"
                elseif cfg.targetMax > 0 and self.active_enemies > cfg.targetMax then
                    return false, "active_enemies[" .. self.active_enemies .. "] is more than ability's maximum targets [" .. cfg.targetMax .. "]"
                end
            end
        end

        if ability.disabled then
            return false, "ability.disabled returned true"
        end

        if ability.nomounted and IsMounted() then
            return false, "not recommended while mounted"
        end

        if ability.form and not state.buff[ ability.form ].up then
            return false, "required form (" .. ability.form .. ") not active"
        end

        if ability.noform and state.buff[ ability.noform ].up then
            return false, "not usable in current form (" .. ability.noform .. ")"
        end

        if ability.buff and not state.buff[ ability.buff ].up then
            return false, "required buff (" .. ability.buff .. ") not active"
        end

        if ability.debuff and not state.debuff[ ability.debuff ].up then
            return false, "required debuff (" ..ability.debuff .. ") not active"
        end

        if self.args.moving == 1 and state.buff.movement.down then
            return false, "entry requires movement and player is not moving"
        end

        if self.args.moving == 0 and state.buff.movement.up then
            return false, "entry requires no movement and player is moving"
        end

        -- Moved this into TimeToReady; we can see when the buff falls off.
        --[[ if ability.nobuff and state.buff[ ability.nobuff ].up then
            return false
        end ]] 

        local hook, reason = ns.callHook( "IsUsable", spell )
        if hook == false then return false, reason end

        if ability.usable ~= nil then
            if type( ability.usable ) == 'number' then
                if IsUsableSpell( ability.usable ) then
                    return true
                end
                return false, "IsSpellUsable(" .. ability.usable .. ") was false"
            elseif type( rawget( ability, "usable" ) ) == 'boolean' then
                return ability.usable
            end
            local usable, reason = ability.funcs.usable()
            if usable then return true end
            return false, reason or "ability 'usable' function returned false without explanation"
        end

        return true        
    end

end

ns.hasRequiredResources = function( ability )
    local action = class.abilities[ ability ]

    if not action then return end

    -- First, spend resources.
    if action.spend and action.spend ~= 0 then
        local spend, resource

        if type( action.spend ) == 'number' then
            spend = action.spend
            resource = action.spendType or class.primaryResource
        elseif type( action.spend ) == 'function' then
            spend, resource = action.spend()
        end

        if resource == 'focus' or resource == 'energy' then
            -- Thought: We'll already delay CD based on time to get energy/focus.
            -- So let's leave it alone.
            return true            
        end

        if spend > 0 and spend < 1 then
            spend = ( spend * state[ resource ].modmax )
        end

        if spend > 0 then
            return ( state[ resource ].current >= spend )
        end
    end

    return true
end
function state:HasRequiredResources( action )
    return ns.hasRequiredResources( action )
end


local power_tick_rate = 0.115

local debug_actions = {
    -- rune_of_power = true,
    -- fire_blast = true,
    -- skull_bash = true,
    -- festering_strike = true,
    -- scourge_strike = true
}


-- Needs to be expanded to handle energy regen before Rogue, Monk, Druid will work.
function state:TimeToReady( action, pool )
    local now = self.now + self.offset
    local action = action or self.this_action

    -- Need to ignore the wait for this part.
    local wait = self.cooldown[ action ].remains
    local ability = class.abilities[ action ]

    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 1, wait ) end

    if ability.id < -99 or ability.id > 0 then
        if not ability.castableWhileCasting and self.args.use_off_gcd ~= 1 and ( ability.gcd ~= 'off' or ( ability.item and not ability.essence ) or not ability.interrupt ) then
            wait = max( wait, self.cooldown.global_cooldown.remains )
            if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f (%d %s %s)", 2, wait, self.args.use_off_gcd or 0, self.settings.gcdSync and "sync" or "nosync", ability.gcd ) end
        end

        if not ability.castableWhileCasting and self.args.use_while_casting ~= 1 and self.buff.casting.remains > 0 then
            wait = max( wait, self.buff.casting.remains )
            if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 3, wait ) end
        end
    end

    local line_cd = state.args.line_cd
    if ( line_cd and type( line_cd ) == 'number' ) and ability.lastCast > self.combat then
        if Hekili.Debug then Hekili:Debug( "Line CD is " .. line_cd .. ", last cast was " .. ability.lastCast .. ", remaining CD: " .. max( 0, ability.lastCast + line_cd - self.query_time ) ) end
        wait = max( wait, ability.lastCast + self.args.line_cd - self.query_time )
    end
    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 4, wait ) end

    local synced = state.args.sync and class.abilities[ state.args.sync ]
    if synced then wait = max( wait, state.cooldown[ state.args.sync ].remains ) end
    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 5, wait ) end

    wait = ns.callHook( "TimeToReady", wait, action )
    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 6, wait ) end

    local spend, resource

    if ability.spend then
        if type( ability.spend ) == 'number' then
            spend = ability.spend
            resource = ability.spendType or class.primaryResource
        elseif type( ability.spend ) == 'function' then
            spend, resource = ability.spend()
            resource = resource or ability.spendType or class.primaryResource
        end

        spend = ns.callHook( 'TimeToReady_spend', spend )
        spend = spend or 0

        if state.debuff.hysteria.up and resource and hysteria_resources[ resource ] then
            spend = spend * ( 1 + 0.03 * state.debuff.hysteria.stack )
        end
    end

    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 7, wait ) end

    -- For special cases where we want to pool more of a resource than is required for usage.
    if not pool and ability.readySpend then
        spend = ability.readySpend
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 8, wait ) end
    end

    if spend and resource and spend > 0 and spend < 1 then
        spend = spend * self[ resource ].modmax
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 9, wait ) end
    end

    -- Okay, so we don't have enough of the resource.
    if spend and resource and spend > self[ resource ].current then
        wait = max( wait, self[ resource ][ 'time_to_' .. spend ] or 0 )        
        wait = ceil( wait * 100 ) / 100 -- round to the hundredth.
        if debug_actions[ action ] then Hekili:Debug( "%d wait ( %s.current = %.2f, time_to ( %.2f ) = %.2f ) %.2f", 10, resource, self[ resource ].current, spend, self[ resource ][ 'time_to_' .. spend ] or 0, wait ) end
    end

    if debug_actions[ action ] then Hekili:Debug( "%d %s prewait %.2f", 11, ability.nobuff or "n/a", wait ) end
    if ability.nobuff and self.buff[ ability.nobuff ].up then
        wait = max( wait, self.buff[ ability.nobuff ].remains )
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 11, wait ) end
    end

    -- Need to house this in an encounter module, really.
    if self.debuff.repeat_performance.up and self.prev[1][ action ] then
        wait = max( wait, self.debuff.repeat_performance.remains )
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 12, wait ) end
    end

    if ability.icd and self.query_time - ability.lastCast < ability.icd then
        wait = max( wait, ability.lastCast + ability.icd - self.query_time )
    end

    -- If ready is a function, it returns time.
    -- Ignore this if we are just checking pool_resources.
    if not pool and ability.readyTime then
        wait = max( wait, ability.readyTime )
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 13, wait ) end
    end

    if state.spec.fire and state.buff.casting.up and ( ability.id > 0 or ability.id < -99 ) and ability.gcd ~= "off" and not ability.castableWhileCasting then
        wait = max( wait, state.buff.casting.remains )
        if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 14, wait ) end
    end

    wait = max( wait, self.delayMin )
    if debug_actions[ action ] then Hekili:Debug( "%d wait %.2f", 15, wait ) end
    return max( wait, self.delayMin )
end


function state:IsReady( action )
    action = action or self.this_action
    local ability = action and class.abilities[ action ]

    if not ability then
        Hekili:Error( "Failed state:IsReady( " .. ( action or "BLANK" ) .. " )." )
        return false
    end

    if ability.spend then
        local spend, resource

        if type( ability.spend ) == 'number' then
            spend = ability.spend
            resource = ability.spendType or class.primaryResource
        elseif type( ability.spend ) == 'function' then
            spend, resource = ability.spend()
        end

        if resource == 'focus' or resource == 'energy' or state.script.entry then
            local ttr = self:TimeToReady( action )

            if ttr <= self.delayMin or ttr >= self.delayMax then return false, "not ready within our time contraint"
            elseif ttr >= state.delay then return false, "not ready before selected action" end

            return true
        end

    end

    return self:HasRequiredResources( action ) and self.cooldown[ action ].remains <= self.delay
end


function state:IsReadyNow( action )
    action = action or self.this_action    
    local a = class.abilities[ action ]

    if not a then return false end

    action = a.key
    local profile = Hekili.DB.profile
    local spec = profile.specs[ state.spec.id ]
    local option = spec.abilities[ action ]    
    local clash = option.clash or 0

    if self.cooldown[ action ].remains - clash > 0 then return false end
    local wait = ns.callHook( "TimeToReady", 0, action )
    if wait and wait > 0 then return false end

    if a.ready and type( a.ready ) == 'function' and a.ready() > 0 then return false end

    if a.spend and a.spend ~= 0 then
        local spend, resource

        if type( a.spend ) == 'number' then
            spend = a.spend
            resource = a.spendType or class.primaryResource

        elseif type( a.spend ) == 'function' then
            spend, resource = a.spend()

        end

        if a.ready and type( a.ready ) == 'number' then
            spend = a.ready
        end

        if spend > 0 and spend < 1 then
            spend = ( spend * state[ resource ].modmax )
        end

        if spend > 0 then
            return state[ resource ].current >= spend 
        end
    end

    return true
end



function state:ClashOffset( action )
    local a = class.abilities[ action ]
    if not a then return 0 end
    action = a.key

    local profile = Hekili.DB.profile
    local spec = profile.specs[ state.spec.id ]
    local option = spec.abilities[ action ]

    return ns.callHook( "clash", option.clash, action )
end


for k, v in pairs( state ) do
    ns.commitKey( k )
end

ns.attr = { "serenity", "active", "active_enemies", "my_enemies", "active_flame_shock", "adds", "agility", "air", "armor", "attack_power", "bonus_armor", "cast_delay", "cast_time", "casting", "cooldown_react", "cooldown_remains", "cooldown_up", "crit_rating", "deficit", "distance", "down", "duration", "earth", "enabled", "energy", "execute_time", "fire", "five", "focus", "four", "gcd", "hardcasts", "haste", "haste_rating", "health", "health_max", "health_pct", "intellect", "level", "mana", "mastery_rating", "mastery_value", "max_nonproc", "max_stack", "maximum_energy", "maximum_focus", "maximum_health", "maximum_mana", "maximum_rage", "maximum_runic", "melee_haste", "miss_react", "moving", "mp5", "multistrike_pct", "multistrike_rating", "one", "pct", "rage", "react", "regen", "remains", "resilience_rating", "runic", "seal", "spell_haste", "spell_power", "spirit", "stack", "stack_pct", "stacks", "stamina", "strength", "this_action", "three", "tick_damage", "tick_dmg", "tick_time", "ticking", "ticks", "ticks_remain", "time", "time_to_die", "time_to_max", "travel_time", "two", "up", "water", "weapon_dps", "weapon_offhand_dps", "weapon_offhand_speed", "weapon_speed", "single", "aoe", "cleave", "percent", "last_judgment_target", "unit", "ready", "refreshable", "pvptalent" }