-- Targets.lua
-- June 2014

local addon, ns = ...
local Hekili = _G[addon]

local class = Hekili.Class
local state = Hekili.State

local targetCount = 0
local targets = {}

local myTargetCount = 0
local myTargets = {}

local addMissingTargets = true
local counted = {}

local formatKey = ns.formatKey
local orderedPairs = ns.orderedPairs
local FeignEvent = ns.FeignEvent

local insert, remove, wipe = table.insert, table.remove, table.wipe

local unitIDs = { "target", "targettarget", "focus", "focustarget", "boss1", "boss2", "boss3", "boss4", "boss5" }

local npGUIDs = {}
local npUnits = {}

Hekili.unitIDs = unitIDs
Hekili.npGUIDs = npGUIDs
Hekili.npUnits = npUnits


function Hekili:GetNameplateUnitForGUID( id )
    return npUnits[ id ]
end

function Hekili:GetGUIDForNameplateUnit( unit )
    return npGUIDs[ unit ]
end

function Hekili:GetUnitByGUID( id )
    for _, unit in ipairs( unitIDs ) do
        if UnitGUID( unit ) == id then return unit end
    end
end


local enemyExclusions = {
    ["120651"] = true, -- Explosives
    ["23775"] = true,  -- Head of the Horseman,
    ["156227"] = true, -- Neferset Denizen,
    ["160966"] = true, -- Thing from Beyond?
    ["161895"] = true, -- Thing from Beyond?
}

local f = CreateFrame("Frame")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

f:SetScript( "OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local id = UnitGUID( unit )
        npGUIDs[unit] = id
        npUnits[id]   = unit
    
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local id = npGUIDs[ unit ]
        npGUIDs[unit] = nil
        npUnits[id]   = nil

    end
end )

Hekili:ProfileFrame( "NamePlateWatcherFrame", f )





local RC = LibStub("LibRangeCheck-2.0")

local lastCount = 1
local lastCycle = 0

local guidRanges = {}


do
    function ns.iterateTargets()
        return next, counted, nil
    end

    -- New Nameplate Proximity System
    function ns.getNumberTargets()
        local now = GetTime()

        if now - lastCycle < 0.2 then return lastCount end
        lastCycle = now

        if now - Hekili.lastAudit > 1 then
            -- Kick start the damage-based target detection filter.
            Hekili.AuditorStalled = true
            ns.Audit()
        end

        local showNPs = GetCVar( "nameplateShowEnemies" ) == "1"

        wipe(counted)

        local count = 0

        Hekili.TargetDebug = ""

        local spec = state.spec.id
        spec = spec and rawget( Hekili.DB.profile.specs, spec ) or nil

        if spec and spec.nameplates and showNPs then
            for unit, guid in pairs(npGUIDs) do
                if UnitExists(unit) and not UnitIsDead(unit) and UnitCanAttack("player", unit) and UnitHealth(unit) > 1 and UnitInPhase(unit) and (UnitIsPVP("player") or not UnitIsPlayer(unit)) then
                    local npcid = guid:match("(%d+)-%x-$")

                    if not enemyExclusions[npcid] then
                        local _, range = RC:GetRange(unit)

                        guidRanges[ guid ] = range

                        local rate, n = Hekili:GetTTD(unit)
                        Hekili.TargetDebug = format( "%s%12s - %2d - %s - %.2f - %d\n", Hekili.TargetDebug, unit, range or 0, guid, rate or 0, n or 0 )

                        if range and range <= spec.nameplateRange then
                            count = count + 1
                            counted[ guid ] = true
                        end
                    end
                end

                counted[ guid ] = counted[ guid ] or false
            end

            for _, unit in ipairs(unitIDs) do
                local guid = UnitGUID(unit)
    
                if guid and counted[ guid ] == nil then
                    if UnitExists(unit) and not UnitIsDead(unit) and UnitCanAttack("player", unit) and UnitHealth(unit) > 1 and UnitInPhase(unit) and (UnitIsPVP("player") or not UnitIsPlayer(unit)) then
                        local npcid = guid:match("(%d+)-%x-$")
    
                        if not enemyExclusions[npcid] then
                            local _, range = RC:GetRange(unit)
    
                            guidRanges[ guid ] = range
    
                            local rate, n = Hekili:GetTTD(unit)
                            Hekili.TargetDebug = format( "%s%12s - %2d - %s - %.2f - %d\n", Hekili.TargetDebug, unit, range or 0, guid, rate or 0, n or 0 )
    
                            if range and range <= spec.nameplateRange then
                                count = count + 1
                                counted[ guid ] = true
                            end
                        end
    
                        counted[ guid ] = counted[ guid ] or false
                    end
                end
            end            
        end

        if not spec or spec.damage or not spec.nameplates or not showNPs then
            local db = spec and (spec.myTargetsOnly and myTargets or targets) or targets

            for guid, seen in pairs(db) do
                local npcid = guid:match("(%d+)-%x-$")

                if counted[ guid ] == nil then
                    if not enemyExclusions[npcid] and ( spec.damageRange == 0 or ( not guidRanges[ guid ] or guidRanges[ guid ] <= spec.damageRange ) ) then
                        Hekili.TargetDebug = format("%s%12s - %2d - %s\n", Hekili.TargetDebug, "dmg", guidRanges[ guid ] or 0, guid)
                        count = count + 1                    
                        counted[ guid ] = true
                    else
                        counted[ guid ] = false
                    end
                end
            end
        end

        local targetGUID = UnitGUID( "target" )
        if targetGUID then
            if counted[ targetGUID ] == nil and UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target") and UnitInPhase("target") and (UnitIsPVP("player") or not UnitIsPlayer("target")) then
                Hekili.TargetDebug = format("%s%12s - %2d - %s\n", Hekili.TargetDebug, "target", 0, targetGUID)
                count = count + 1
                counted[ targetGUID ] = true
            else
                counted[ targetGUID ] = false
            end
        end

        count = max( 1, count )

        if count ~= lastCount then
            lastCount = count
            Hekili:ForceUpdate( "TARGET_COUNT_CHANGED" )
        end

        return count
    end
end

function Hekili:GetNumTargets()
    return ns.getNumberTargets()
end


function ns.dumpNameplateInfo()
    return counted
end


function ns.updateTarget(id, time, mine)
    if id == state.GUID then
        return
    end

    if time then
        if not targets[id] then
            targetCount = targetCount + 1
            targets[id] = time
            ns.updatedTargetCount = true
        else
            targets[id] = time
        end

        if mine then
            if not myTargets[id] then
                myTargetCount = myTargetCount + 1
                myTargets[id] = time
                ns.updatedTargetCount = true
            else
                myTargets[id] = time
            end
        end
    else
        if targets[id] then
            targetCount = max(0, targetCount - 1)
            targets[id] = nil
        end

        if myTargets[id] then
            myTargetCount = max(0, myTargetCount - 1)
            myTargets[id] = nil
        end

        ns.updatedTargetCount = true
    end
end

ns.reportTargets = function()
    for k, v in pairs(targets) do
        Hekili:Print("Saw " .. k .. " exactly " .. GetTime() - v .. " seconds ago.")
    end
end

ns.numTargets = function()
    return targetCount > 0 and targetCount or 1
end
ns.numMyTargets = function()
    return myTargetCount > 0 and myTargetCount or 1
end
ns.isTarget = function(id)
    return targets[id] ~= nil
end
ns.isMyTarget = function(id)
    return myTargets[id] ~= nil
end

-- MINIONS
local minions = {}

ns.updateMinion = function(id, time)
    minions[id] = time
end

ns.isMinion = function(id)
    return minions[id] ~= nil or UnitGUID("pet") == id
end

function Hekili:HasMinionID(id)
    for k, v in pairs(minions) do
        local npcID = tonumber(k:match("%-(%d+)%-[0-9A-F]+$"))

        if npcID == id and v > state.now then
            return true, v
        end
    end
end

function Hekili:DumpMinions()
    local o = ""

    for k, v in orderedPairs(minions) do
        o = o .. k .. " " .. tostring(v) .. "\n"
    end

    return o
end

local debuffs = {}
local debuffCount = {}
local debuffMods = {}

function ns.saveDebuffModifier(id, val)
    debuffMods[id] = val
end

ns.wipeDebuffs = function()
    for k, _ in pairs(debuffs) do
        table.wipe(debuffs[k])
        debuffCount[k] = 0
    end
end

ns.actorHasDebuff = function( target, spell )
    return ( debuffs[ spell ] and debuffs[ spell ][ target ] ~= nil ) or false
end

ns.trackDebuff = function(spell, target, time, application)
    debuffs[spell] = debuffs[spell] or {}
    debuffCount[spell] = debuffCount[spell] or 0

    if not time then
        if debuffs[spell][target] then
            -- Remove it.
            debuffs[spell][target] = nil
            debuffCount[spell] = max(0, debuffCount[spell] - 1)
        end
    else
        if not debuffs[spell][target] then
            debuffs[spell][target] = {}
            debuffCount[spell] = debuffCount[spell] + 1
        end

        local debuff = debuffs[spell][target]

        debuff.last_seen = time
        debuff.applied = debuff.applied or time

        if application then
            debuff.pmod = debuffMods[spell]
        else
            debuff.pmod = debuff.pmod or 1
        end
    end
end


ns.GetDebuffApplicationTime = function( spell, target )
    if not debuffCount[ spell ] or debuffCount[ spell ] == 0 then return 0 end
    return debuffs[ spell ] and debuffs[ spell ][ target ] and ( debuffs[ spell ][ target ].applied or debuffs[ spell ][ target ].last_seen ) or 0
end


function ns.getModifier(id, target)
    local debuff = debuffs[id]
    if not debuff then
        return 1
    end

    local app = debuff[target]
    if not app then
        return 1
    end

    return app.pmod or 1
end

ns.numDebuffs = function(spell)
    return debuffCount[spell] or 0
end

ns.compositeDebuffCount = function( ... )
    local n = 0

    for i = 1, select("#", ...) do  
        local debuff = select( i, ... )
        debuff = class.auras[ debuff ] and class.auras[ debuff ].id
        debuff = debuff and debuffs[ debuff ]

        if debuff then
            for unit in pairs(debuff) do
                n = n + 1
            end
        end
    end

    return n
end

ns.conditionalDebuffCount = function(req1, req2, ...)
    local n = 0

    req1 = class.auras[req1] and class.auras[req1].id
    req2 = class.auras[req2] and class.auras[req2].id

    for i = 1, select("#", ...) do
        local debuff = select(i, ...)
        debuff = class.auras[debuff] and class.auras[debuff].id
        debuff = debuff and debuffs[debuff]

        if debuff then
            for unit in pairs(debuff) do
                local reqExp =
                    (req1 and debuffs[req1] and debuffs[req1][unit]) or (req2 and debuffs[req2] and debuffs[req2][unit])
                if reqExp then
                    n = n + 1
                end
            end
        end
    end

    return n
end

do
    local counted = {}

    -- Useful for "count number of enemies with at least one of these debuffs applied".
    -- i.e., poisoned_enemies for Assassination Rogue.
    
    ns.countUnitsWithDebuffs = function( ... )
        wipe( counted )
        
        local n = 0

        for i = 1, select("#", ...) do
            local debuff = select( i, ... )
            debuff = class.auras[ debuff ] and class.auras[ debuff ].id
            debuff = debuff and debuffs[ debuff ]

            if debuff then
                for unit in pairs( debuff ) do
                    if not counted[ unit ] then
                        n = n + 1
                        counted[ unit ] = true
                    end
                end
            end
        end

        return n
    end
end

ns.isWatchedDebuff = function(spell)
    return debuffs[spell] ~= nil
end

ns.eliminateUnit = function(id, force)
    ns.updateMinion(id)
    ns.updateTarget(id)

    lastCycle = 0

    guidRanges[id] = nil

    if force then
        for k, v in pairs(debuffs) do
            ns.trackDebuff(k, id)
        end
    end

    ns.callHook( "UNIT_ELIMINATED", id )
end

local incomingDamage = {}
local incomingHealing = {}

ns.storeDamage = function(time, damage, physical)
    if damage and damage > 0 then
        table.insert(incomingDamage, {t = time, damage = damage, physical = physical})
    end
end
ns.storeHealing = function(time, healing)
    table.insert(incomingHealing, {t = time, healing = healing})
end

ns.damageInLast = function(t, physical)
    local dmg = 0
    local start = GetTime() - min(t, 15)

    for k, v in pairs(incomingDamage) do
        if v.t > start and (physical == nil or v.physical == physical) then
            dmg = dmg + v.damage
        end
    end

    return dmg
end

function ns.healingInLast(t)
    local heal = 0
    local start = GetTime() - min(t, 15)

    for k, v in pairs(incomingHealing) do
        if v.t > start then
            heal = heal + v.healing
        end
    end

    return heal
end

-- Auditor should clean things up for us.
Hekili.lastAudit = GetTime()
Hekili.auditInterval = 0

ns.Audit = function()
    local now = GetTime()
    local spec = state.spec.id and Hekili.DB.profile.specs[ state.spec.id ]
    local grace = spec and spec.damageExpiration or 6

    Hekili.auditInterval = now - Hekili.lastAudit
    Hekili.lastAudit = now

    for aura, targets in pairs(debuffs) do
        local a = class.auras[aura]
        local window = a and a.duration or grace
        local expires = a and a.no_ticks or false

        for unit, entry in pairs(targets) do
            -- NYI: Check for dot vs. debuff, since debuffs won't 'tick'
            if expires and now - entry.last_seen > window then
                ns.trackDebuff(aura, unit)
            end
        end
    end

    for whom, when in pairs(targets) do
        if now - when > grace then
            ns.eliminateUnit(whom)
        end
    end

    for i = #incomingDamage, 1, -1 do
        local instance = incomingDamage[i]

        if instance.t < (now - 15) then
            table.remove(incomingDamage, i)
        end
    end

    for i = #incomingHealing, 1, -1 do
        local instance = incomingHealing[i]

        if instance.t < (now - 15) then
            table.remove(incomingHealing, i)
        end
    end

    Hekili:ExpireTTDs()

    if Hekili.DB.profile.enabled then
        C_Timer.After(1, ns.Audit)
    end
end

do
    -- New TTD, hopefully more aggressive and accurate than old TTD.
    Hekili.TTD = Hekili.TTD or {}
    local db = Hekili.TTD

    local recycle = {}

    local function EliminateEnemy(guid)
        local enemy = db[guid]
        if not enemy then
            return
        end

        db[guid] = nil
        wipe(enemy)
        insert(recycle, enemy)

        for k, _ in pairs(debuffs) do
            ns.trackDebuff(k, guid)
        end
    end

    local function UpdateEnemy(guid, healthPct, unit, time)
        local enemy = db[guid]
        time = time or GetTime()

        if not enemy then
            -- This is the first time we've seen the enemy.
            enemy = remove(recycle, 1) or {}
            db[guid] = enemy

            enemy.firstSeen = time
            enemy.firstHealth = healthPct
            enemy.lastSeen = time
            enemy.lastHealth = healthPct

            enemy.unit = unit

            enemy.rate = 0
            enemy.n = 0

            return
        end

        local difference = enemy.lastHealth - healthPct

        -- We don't recalculate the rate when enemies heal.
        if difference > 0 then
            local elapsed = time - enemy.lastSeen

            -- If this is our first health difference, just store it.
            if enemy.n == 0 then
                enemy.rate = difference / elapsed
                enemy.n = 1
            else
                local samples = min(enemy.n, 9)
                local newRate = enemy.rate * samples + (difference / elapsed)
                enemy.n = samples + 1
                enemy.rate = newRate / enemy.n
            end
        end

        enemy.unit = unit
        enemy.lastHealth = healthPct
        enemy.lastSeen = time
    end

    local DEFAULT_TTD = 15
    local FOREVER = 3600
    local TRIVIAL = 5


    function Hekili:GetDeathClockByGUID( guid )
        local time, validUnit = 0, false

        local enemy = db[ guid ]

        if enemy and enemy.n > 3 then
            time = max( time, ceil( enemy.lastHealth / enemy.rate ) )
            validUnit = true
        end

        if not validUnit then return FOREVER end

        return time
    end

    function Hekili:GetTTD( unit, isGUID )
        local default = UnitIsTrivial(unit) and TRIVIAL or FOREVER

        local guid = UnitExists(unit) and UnitCanAttack("player", unit) and UnitGUID(unit)
        if not guid then
            return default
        end

        local enemy = db[guid]
        if not enemy then
            return default
        end

        -- Don't have enough data to predict yet.
        if enemy.n < 3 or enemy.rate == 0 then
            return default, enemy.n
        end

        local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
        health = health + UnitGetTotalAbsorbs(unit)
        local healthPct = health / healthMax

        if healthPct == 0 then
            return 1, enemy.n
        end

        return ceil(healthPct / enemy.rate), enemy.n
    end

    function Hekili:GetTimeToPct( unit, percent )
        local default = 0.7 * ( UnitIsTrivial( unit ) and TRIVIAL or FOREVER )
        local guid = UnitExists( unit ) and UnitCanAttack( "player", unit ) and UnitGUID( unit )

        if percent >= 1 then
            percent = percent / 100
        end

        if not guid then return default end

        local enemy = db[ guid ]
        if not enemy then return default end

        if enemy.n < 3 or enemy.rate == 0 then
            return default, enemy.n
        end

        local health, healthMax = UnitHealth( unit ), UnitHealthMax( unit )
        health = health + UnitGetTotalAbsorbs( unit )

        local healthPct = health / healthMax

        if healthPct <= percent then return FOREVER, enemy.n end

        return ceil( ( healthPct - percent ) / enemy.rate ), enemy.n
    end

    function Hekili:GetTimeToPctByGUID( guid, percent )
        if percent >= 1 then
            percent = percent / 100
        end

        local default = percent * FOREVER

        if not guid then return default end

        local enemy = db[ guid ]
        if not enemy then return default end

        if enemy.n < 3 or enemy.rate == 0 then
            return default, enemy.n
        end

        local healthPct = enemy.lastHealth
        if healthPct <= percent then return FOREVER, enemy.n end

        return ceil( ( healthPct - percent ) / enemy.rate ), enemy.n
    end

    function Hekili:GetGreatestTTD()
        local time, validUnit = 0, false

        for k, v in pairs( db ) do
            if v.n > 3 then
                time = max( time, ceil( v.lastHealth / v.rate ) )
                validUnit = true
            end
        end

        if not validUnit then return state.boss and FOREVER or DEFAULT_TTD end

        return time
    end

    function Hekili:GetGreatestTimeToPct( percent )
        local time, validUnit = 0, false

        if percent >= 1 then
            percent = percent / 100
        end        

        for k, v in pairs(db) do
            if v.n > 3 and v.lastHealth > percent then
                time = max( time, ( v.lastHealth - percent ) / v.rate )
                validUnit = true
            end
        end

        if not validUnit then return FOREVER end

        return time
    end

    function Hekili:GetLowestTTD()
        local time, validUnit = 3600, false

        for k, v in pairs(db) do
            if v.n > 3 then
                time = min(time, ceil(v.lastHealth / v.rate))
                validUnit = true
            end
        end

        if not validUnit then
            return FOREVER
        end

        return time
    end

    function Hekili:GetNumTTDsWithin(x)
        if x <= 3 then
            return 1
        end

        local count = 0

        for k, v in pairs(db) do
            if v.n > 3 then
                if ceil(v.lastHealth / v.rate) <= x then
                    count = count + 1
                end
            end
        end

        return count
    end
    Hekili.GetNumTTDsBefore = Hekili.GetNumTTDsWithin

    function Hekili:GetNumTTDsAfter(x)
        local count = 0

        for k, v in pairs(db) do
            if v.n > 3 then
                if ceil(v.lastHealth / v.rate) > x then
                    count = count + 1
                end
            end
        end

        return count
    end

    local bosses = {}

    function Hekili:GetAddWaveTTD()
        if not UnitExists("boss1") then
            return self:GetGreatestTTD()
        end

        wipe(bosses)

        for i = 1, 5 do
            local unit = "boss" .. i
            local guid = UnitExists(unit) and UnitGUID(unit)
            if guid then
                bosses[guid] = true
            end
        end

        local time = 0

        for k, v in pairs(db) do
            if not bosses[k] and v.n > 0 then
                time = max(time, ceil(v.lastHealth / v.rate))
            end
        end

        return time
    end

    function Hekili:ExpireTTDs(all)
        local now = GetTime()

        for k, v in pairs(db) do
            if all or now - v.lastSeen > 10 then
                EliminateEnemy(k)
            end
        end
    end

    local trackedUnits = {"target", "boss1", "boss2", "boss3", "boss4", "boss5", "focus"}
    local seen = {}

    local UpdateTTDs

    UpdateTTDs = function()
        wipe(seen)

        local now = GetTime()

        for i, unit in ipairs(trackedUnits) do
            local guid = UnitGUID(unit)

            if guid and not seen[guid] then
                if db[guid] and (not UnitExists(unit) or UnitIsDead(unit) or not UnitCanAttack("player", unit) or UnitHealth(unit) <= 1) then
                    EliminateEnemy(guid)
                else
                    local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
                    health = health + UnitGetTotalAbsorbs(unit)
                    UpdateEnemy(guid, health / healthMax, unit, now)
                end
                seen[guid] = true
            end
        end

        for unit, guid in pairs(npGUIDs) do
            if db[guid] and (not UnitExists(unit) or UnitIsDead(unit) or not UnitCanAttack("player", unit)) then
                EliminateEnemy(guid)
            elseif not seen[guid] then
                local health, healthMax = UnitHealth(unit), UnitHealthMax(unit)
                UpdateEnemy(guid, health / healthMax, unit, now)
            end
            seen[guid] = true
        end

        C_Timer.After( 0.5, UpdateTTDs )
    end

    C_Timer.After( 0.5, UpdateTTDs )
end
