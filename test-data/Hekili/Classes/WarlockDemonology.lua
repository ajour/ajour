-- WarlockDemonology.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'WARLOCK' then
    local spec = Hekili:NewSpecialization( 266, true )

    spec:RegisterResource( Enum.PowerType.SoulShards )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        dreadlash = 19290, -- 264078
        demonic_strength = 22048, -- 267171
        bilescourge_bombers = 23138, -- 267211

        demonic_calling = 22045, -- 205145
        power_siphon = 21694, -- 264130
        doom = 23158, -- 265412

        demon_skin = 19280, -- 219272
        burning_rush = 19285, -- 111400
        dark_pact = 19286, -- 108416

        from_the_shadows = 22477, -- 267170
        soul_strike = 22042, -- 264057
        summon_vilefiend = 23160, -- 264119

        darkfury = 22047, -- 264874
        mortal_coil = 19291, -- 6789
        demonic_circle = 19288, -- 268358

        soul_conduit = 23147, -- 215941
        inner_demons = 23146, -- 267216
        grimoire_felguard = 21717, -- 111898

        sacrificed_souls = 23161, -- 267214
        demonic_consumption = 22479, -- 267215
        nether_portal = 23091, -- 267217
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3501, -- 196029
        adaptation = 3500, -- 214027
        gladiators_medallion = 3499, -- 208683

        master_summoner = 1213, -- 212628
        singe_magic = 154, -- 212623
        call_felhunter = 156, -- 212619
        curse_of_weakness = 3507, -- 199892
        curse_of_tongues = 3506, -- 199890
        casting_circle = 3626, -- 221703
        curse_of_fragility = 3505, -- 199954
        pleasure_through_pain = 158, -- 212618
        essence_drain = 3625, -- 221711
        call_fel_lord = 162, -- 212459
        nether_ward = 3624, -- 212295
        call_observer = 165, -- 201996
    } )


    -- Demon Handling
    local dreadstalkers = {}
    local dreadstalkers_v = {}

    local vilefiend = {}
    local vilefiend_v = {}

    local wild_imps = {}
    local wild_imps_v = {}

    local demonic_tyrant = {}
    local demonic_tyrant_v = {}

    local other_demon = {}
    local other_demon_v = {}

    local imps = {}
    local guldan = {}
    local guldan_v = {}

    local shards_for_guldan = 0

    local last_summon = {}


    local FindUnitBuffByID = ns.FindUnitBuffByID


    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function()
        local _, subtype, _, source, _, _, _, destGUID, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        local now = GetTime()

        if source == state.GUID then
            if subtype == "SPELL_SUMMON" then
                -- Dreadstalkers: 104316, 12 seconds uptime.
                if spellID == 193332 or spellID == 193331 then table.insert( dreadstalkers, now + 12 )

                -- Vilefiend: 264119, 15 seconds uptime.
                elseif spellID == 264119 then table.insert( vilefiend, now + 15 )

                -- Wild Imp: 104317 and 279910, 20 seconds uptime.
                elseif spellID == 104317 or spellID == 279910 then
                    table.insert( wild_imps, now + 20 )

                    imps[ destGUID ] = {
                        t = now,
                        casts = 0,
                        expires = math.ceil( now + 20 ),
                        max = math.ceil( now + 20 )
                    }

                    if guldan[ 1 ] then
                        -- If this imp is impacting within 0.1s of the expected queued imp, remove that imp from the queue.
                        if abs( now - guldan[ 1 ] ) < 0.1 then
                            table.remove( guldan, 1 )
                        end
                    end

                    -- Expire missed/lost Gul'dan predictions.
                    while( guldan[ 1 ] ) do
                        if guldan[ 1 ] < now then
                            table.remove( guldan, 1 )
                        else
                            break
                        end
                    end

                -- Demonic Tyrant: 265187, 15 seconds uptime.
                elseif spellID == 265187 then table.insert( demonic_tyrant, now + 15 )

                -- Other Demons, 15 seconds uptime.
                -- 267986 - Prince Malchezaar
                -- 267987 - Illidari Satyr
                -- 267988 - Vicious Hellhound
                -- 267989 - Eyes of Gul'dan
                -- 267991 - Void Terror
                -- 267992 - Bilescourge
                -- 267994 - Shivarra
                -- 267995 - Wrathguard
                -- 267996 - Darkhound
                elseif spellID >= 267986 and spellID <= 267996 then table.insert( other_demon, now + 15 ) end

            elseif subtype == "SPELL_CAST_START" and spellID == 105174 then
                shards_for_guldan = UnitPower( "player", Enum.PowerType.SoulShards )

            elseif subtype == "SPELL_CAST_SUCCESS" then
                if spellID == 196277 then
                    table.wipe( wild_imps )
                    table.wipe( imps )

                elseif spellID == 264130 then
                    if wild_imps[1] then table.remove( wild_imps, 1 ) end
                    if wild_imps[1] then table.remove( wild_imps, 1 ) end
                    
                    for i = 1, 2 do
                        local lowest

                        for id, imp in pairs( imps ) do
                            if not lowest then lowest = id
                            elseif imp.expires < imps[ lowest ].expires then
                                lowest = id
                            end
                        end

                        if lowest then
                            imps[ lowest ] = nil
                        end
                    end

                elseif spellID == 105174 then
                    -- Hand of Guldan; queue imps.
                    if shards_for_guldan >= 1 then table.insert( guldan, now + 1.11 ) end
                    if shards_for_guldan >= 2 then table.insert( guldan, now + 1.51 ) end
                    if shards_for_guldan >= 3 then table.insert( guldan, now + 1.91 ) end

                elseif spellID == 265187 and state.talent.demonic_consumption.enabled then
                    table.wipe( guldan ) -- wipe incoming imps, too.
                    table.wipe( wild_imps )
                    table.wipe( imps )

                end

            end

        elseif imps[ source ] and subtype == "SPELL_CAST_START" then
            local demonic_power = FindUnitBuffByID( "player", 265273 )

            if not demonic_power then
                local imp = imps[ source ]

                imp.start = now
                imp.casts = imp.casts + 1

                imp.expires = min( imp.max, now + ( ( 6 - imp.casts ) * 2 * state.haste ) )
            end
        end
    end )


    local wipe = table.wipe

    spec:RegisterHook( "reset_precast", function()
        local i = 1
        while dreadstalkers[ i ] do
            if dreadstalkers[ i ] < now then
                table.remove( dreadstalkers, i )
            else
                i = i + 1
            end
        end

        wipe( dreadstalkers_v )
        for n, t in ipairs( dreadstalkers ) do dreadstalkers_v[ n ] = t end


        i = 1
        while( vilefiend[ i ] ) do
            if vilefiend[ i ] < now then
                table.remove( vilefiend, i )
            else
                i = i + 1
            end
        end

        wipe( vilefiend_v )
        for n, t in ipairs( vilefiend ) do vilefiend_v[ n ] = t end

        
        for id, imp in pairs( imps ) do
            if imp.expires < now then
                imps[ id ] = nil
            end
        end

        i = 1
        while( wild_imps[ i ] ) do
            if wild_imps[ i ] < now then
                table.remove( wild_imps, i )
            else
                i = i + 1
            end
        end

        wipe( wild_imps_v )
        for n, t in pairs( imps ) do table.insert( wild_imps_v, t.expires ) end
        table.sort( wild_imps_v )

        local difference = #wild_imps_v - GetSpellCount( 196277 )

        while difference > 0 do
            table.remove( wild_imps_v, 1 )
            difference = difference - 1
        end

        
        wipe( guldan_v )
        for n, t in ipairs( guldan ) do guldan_v[ n ] = t end


        i = 1
        while( demonic_tyrant[ i ] ) do
            if demonic_tyrant[ i ] < now then
                table.remove( demonic_tyrant, i )
            else
                i = i + 1
            end
        end

        wipe( demonic_tyrant_v )
        for n, t in ipairs( demonic_tyrant ) do demonic_tyrant_v[ n ] = t end


        i = 1
        while( other_demon[ i ] ) do
            if other_demon[ i ] < now then
                table.remove( other_demon, i )
            else
                i = i + 1
            end
        end

        wipe( other_demon_v )
        for n, t in ipairs( other_demon ) do other_demon_v[ n ] = t end

        last_summon.name = nil
        last_summon.at = nil
        last_summon.count = nil

        if demonic_tyrant_v[ 1 ] and demonic_tyrant_v[ 1 ] > query_time then
            summonPet( "demonic_tyrant", demonic_tyrant_v[ 1 ] - query_time )
        end
    end )


    spec:RegisterHook( "advance_end", function ()
        for i = #guldan_v, 1, -1 do
            local imp = guldan_v[i]

            if imp <= query_time then
                if ( imp + 20 ) > query_time then
                    insert( wild_imps_v, imp + 20 )
                end
                remove( guldan_v, i )
            end
        end
    end )


    -- Provide a way to confirm if all Hand of Gul'dan imps have landed.
    spec:RegisterStateExpr( "spawn_remains", function ()
        if #guldan_v > 0 then
            return max( 0, guldan_v[ #guldan_v ] - query_time )
        end
        return 0
    end )


    spec:RegisterHook( "spend", function( amt, resource )
        if resource == "soul_shards" and buff.nether_portal.up then
            summon_demon( "other", 15, amt )
        end
    end )


    spec:RegisterStateFunction( "summon_demon", function( name, duration, count )
        local db = other_demon_v

        if name == 'dreadstalkers' then db = dreadstalkers_v
        elseif name == 'vilefiend' then db = vilefiend_v
        elseif name == 'wild_imps' then db = wild_imps_v
        elseif name == 'demonic_tyrant' then db = demonic_tyrant_v end

        count = count or 1
        local expires = query_time + duration

        last_summon.name = name
        last_summon.at = query_time
        last_summon.count = count

        for i = 1, count do
            table.insert( db, expires )
        end
    end )


    spec:RegisterStateFunction( "extend_demons", function( duration )
        duration = duration or 15 

        for k, v in pairs( dreadstalkers_v ) do dreadstalkers_v[ k ] = v + duration end
        for k, v in pairs( vilefiend_v     ) do vilefiend_v    [ k ] = v + duration end
        for k, v in pairs( wild_imps_v     ) do wild_imps_v    [ k ] = v + duration end
        for k, v in pairs( other_demon_v   ) do other_demon_v  [ k ] = v + duration end
    end )

    spec:RegisterStateFunction( "consume_demons", function( name, count )
        local db = other_demon_v

        if name == 'dreadstalkers' then db = dreadstalkers_v
        elseif name == 'vilefiend' then db = vilefiend_v
        elseif name == 'wild_imps' then db = wild_imps_v
        elseif name == 'demonic_tyrant' then db = demonic_tyrant_v end

        if type( count ) == 'string' and count == 'all' then
            table.wipe( db )

            -- Wipe queued Guldan imps that should have landed by now.
            if name == "wild_imps" then
                while( guldan_v[ 1 ] ) do
                    if guldan_v[ 1 ] < now then table.remove( guldan_v, 1 )
                    else break end
                end
            end
            return
        end

        count = count or 0

        if count >= #db then
            count = count - #db
            table.wipe( db )
        end

        while( count > 0 ) do
            if not db[1] then break end
            table.remove( db, 1 )
            count = count - 1
        end

        if name == "wild_imps" and count > 0 then
            while( count > 0 ) do
                if not guldan_v[1] or guldan_v[1] > now then break end
                table.remove( guldan_v, 1 )
                count = count - 1 
            end
        end
    end )


    spec:RegisterStateExpr( "soul_shard", function () return soul_shards.current end )


    -- New imp forecasting expressions for Demo.
    spec:RegisterStateExpr( "incoming_imps", function ()
        local n = 0

        for i, time in ipairs( guldan_v ) do
            if time < query_time then break end
            n = n + 1
        end

        return n
    end )


    local time_to_n = 0

    spec:RegisterStateTable( "query_imp_spawn", setmetatable( {}, {
        __index = function( t, k )
            if k ~= 'remains' then return 0 end

            local queued = #guldan_v

            if queued == 0 then return 0 end

            if time_to_n == 0 or time_to_n >= queued then
                return max( 0, guldan_v[ queued ] - query_time )
            end

            local count = 0
            local remains = 0

            for i, time in ipairs( guldan_v ) do
                if time > query_time then
                    count = count + 1
                    remains = time - query_time

                    if count >= time_to_n then break end
                end
            end

            return remains
        end,
    } ) )

    spec:RegisterStateTable( "time_to_imps", setmetatable( {}, {
        __index = function( t, k )
            if type( k ) == "number" then
                time_to_n = min( #guldan_v, k )
            elseif k == "all" then
                time_to_n = #guldan_v
            else
                time_to_n = 0
            end

            return query_imp_spawn
        end
    } ) )


    spec:RegisterStateTable( "imps_spawned_during", setmetatable( {}, {
        __index = function( t, k, v )
            local cap = query_time
            
            if type(k) == 'number' then cap = cap + ( k / 1000 )
            else
                if not class.abilities[ k ] then k = "summon_demonic_tyrant" end
                cap = cap + action[ k ].cast
            end

            -- In SimC, k would be a numeric value to be interpreted but I don't see the point.
            -- We're only using it for SDT now, and I don't know what else we'd really use it for.
            
            -- So imps_spawned_during.summon_demonic_tyrant would be the syntax I'll use here.

            local n = 0

            for i, spawn in ipairs( guldan_v ) do
                if spawn > cap then break end
                if spawn > query_time then n = n + 1 end
            end
            
            return n
        end,
    } ) )


    -- Auras
    spec:RegisterAuras( {
        axe_toss = {
            id = 89766,
            duration = 4,
            max_stack = 1,
        },

        bile_spit = {
            id = 267997,
            duration = 10,
            max_stack = 1,
        },

        burning_rush = {
            id = 111400,
            duration = 3600,
            max_stack = 1,
        },

        dark_pact = {
            id = 108416,
            duration = 20,
            max_stack = 1,
        },

        demonic_calling = {
            id = 205146,
            duration = 20,
            type = "Magic",
            max_stack = 1,
        },

        demonic_circle = {
            id = 48018,
        },

        demonic_circle_teleport = {
            id = 48020,
        },

        demonic_core = {
            id = 264173,
            duration = 20,
            max_stack = 4,
        },

        demonic_power = {
            id = 265273,
            duration = 15,
            max_stack = 1,
        },

        demonic_strength = {
            id = 267171,
            duration = 20,
        },

        doom = {
            id = 265412,
            duration = function () return 30 * haste end,
            tick_time = function () return 30 * haste end,
            max_stack = 1,
        },

        drain_life = {
            id = 234153,
            duration = 5,
            max_stack = 1,
        },

        eye_of_guldan = {
            id = 272131,
            duration = 15,
            max_stack = 1,
        },

        eye_of_kilrogg = {
            id = 126,
        },

        fear = {
            id = 118699,
            duration = 20,
            type = "Magic",
            max_stack = 1,
        },

        felstorm = {
            id = 89751,
            duration = function () return 5 * haste end,
            tick_time = function () return 1 * haste end,
            max_stack = 1,

            generate = function () 
                local fs = buff.felstorm

                local name, _, count, _, duration, expires, caster = FindUnitBuffByID( "pet", 89751 )

                if name then
                    fs.count = 1
                    fs.applied = expires - duration
                    fs.expires = expires
                    fs.caster = "pet"
                    return
                end

                fs.count = 0
                fs.applied = 0
                fs.expires = 0
                fs.caster = "nobody"
            end,
        },

        from_the_shadows = {
            id = 270569,
            duration = 12,
            max_stack = 1,
        },

        grimoire_felguard = {
            -- fake buff when grimoire_felguard is up.
            duration = 15,
            generate = function ()
                local cast = rawget( class.abilities.grimoire_felguard, "lastCast" ) or 0
                local up = cast + 15 > query_time

                local gf = buff.grimoire_felguard
                gf.name = class.abilities.grimoire_felguard.name

                if up then
                    gf.count = 1
                    gf.expires = cast + 15
                    gf.applied = cast
                    gf.caster = "player"
                    return
                end
                gf.count = 0
                gf.expires = 0
                gf.applied = 0
                gf.caster = "nobody"                
            end,
        },

        legion_strike = {
            id = 30213,
            duration = 6,
            max_stack = 1,
        },

        mortal_coil = {
            id = 6789,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },

        nether_portal = {
            duration = 15,
            max_stack = 1,

            generate = function ()
                local applied = class.abilities.nether_portal.lastCast or 0
                local up = applied + 15 > query_time

                local np = buff.nether_portal
                np.name = "Nether Portal"

                if up then
                    np.count = 1
                    np.expires = applied + 15
                    np.applied = applied
                    np.caster = "player"
                    return
                end

                np.count = 0
                np.expires = 0
                np.applied = 0
                np.caster = "nobody"
            end,    
        },

        ritual_of_summoning = {
            id = 698,
        },

        shadowfury = {
            id = 30283,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },

        soul_leech = {
            id = 108366,
            duration = 15,
            max_stack = 1,
        },

        soul_link = {
            id = 108415,
        },

        soul_shard = {
            id = 246985,
        },

        unending_breath = {
            id = 5697,
            duration = 600,
            max_stack = 1,
        },

        unending_resolve = {
            id = 104773,
            duration = 8,
            max_stack = 1,
        },

        dreadstalkers = {
            duration = 12,

            meta = {
                up = function () local exp = dreadstalkers_v[ #dreadstalkers_v ]; return exp and exp >= query_time or false end,
                down = function () local exp = dreadstalkers_v[ #dreadstalkers_v ]; return exp and exp < query_time or true end,
                applied = function () local exp = dreadstalkers_v[ 1 ]; return exp and ( exp - 12 ) or 0 end,
                remains = function () local exp = dreadstalkers_v[ #dreadstalkers_v ]; return exp and max( 0, exp - query_time ) or 0 end,
                count = function () 
                    local c = 0
                    for i, exp in ipairs( dreadstalkers_v ) do
                        if exp > query_time then c = c + 1 end
                    end
                    return c
                end,
            }
        },

        wild_imps = {
            duration = 25,

            meta = {
                up = function () local exp = wild_imps_v[ #wild_imps_v ]; return exp and exp >= query_time or false end,
                down = function () local exp = wild_imps_v[ #wild_imps_v ]; return exp and exp < query_time or true end,
                applied = function () local exp = wild_imps_v[ 1 ]; return exp and ( exp - 20 ) or 0 end,
                remains = function () local exp = wild_imps_v[ #wild_imps_v ]; return exp and max( 0, exp - query_time ) or 0 end,
                count = function () 
                    local c = 0
                    for i, exp in ipairs( wild_imps_v ) do
                        if exp > query_time then c = c + 1 end
                    end

                    -- Count queued HoG imps.
                    for i, spawn in ipairs( guldan_v ) do
                        if spawn <= query_time and ( spawn + 20 ) >= query_time then c = c + 1 end
                    end
                    return c
                end,
            }
        },

        vilefiend = {
            duration = 12,

            meta = {
                up = function () local exp = vilefiend_v[ #vilefiend_v ]; return exp and exp >= query_time or false end,
                down = function () local exp = vilefiend_v[ #vilefiend_v ]; return exp and exp < query_time or true end,
                applied = function () local exp = vilefiend_v[ 1 ]; return exp and ( exp - 15 ) or 0 end,
                remains = function () local exp = vilefiend_v[ #vilefiend_v ]; return exp and max( 0, exp - query_time ) or 0 end,
                count = function () 
                    local c = 0
                    for i, exp in ipairs( vilefiend_v ) do
                        if exp > query_time then c = c + 1 end
                    end
                    return c
                end,
            }
        },

        other_demon = {
            duration = 20,

            meta = {
                up = function () local exp = other_demon_v[ 1 ]; return exp and exp >= query_time or false end,
                down = function () local exp = other_demon_v[ 1 ]; return exp and exp < query_time or true end,
                applied = function () local exp = other_demon_v[ 1 ]; return exp and ( exp - 15 ) or 0 end,
                remains = function () local exp = other_demon_v[ 1 ]; return exp and max( 0, exp - query_time ) or 0 end,
                count = function () 
                    local c = 0
                    for i, exp in ipairs( other_demon_v ) do
                        if exp > query_time then c = c + 1 end
                    end
                    return c
                end,
            }
        },


        -- Azerite Powers
        forbidden_knowledge = {
            id = 279666,
            duration = 15,
            max_stack = 1,
        },
    } )


    local Glyphed = IsSpellKnownOrOverridesKnown

    -- Fel Imp          58959
    spec:RegisterPet( "imp",
        function() return Glyphed( 112866 ) and 58959 or 416 end,
        "summon_imp",
        3600 )

    -- Voidlord         58960
    spec:RegisterPet( "voidwalker",
        function() return Glyphed( 112867 ) and 58960 or 1860 end,
        "summon_voidwalker",
        3600 )

    -- Observer         58964
    spec:RegisterPet( "felhunter",
        function() return Glyphed( 112869 ) and 58964 or 417 end,
        "summon_felhunter",
        3600 )

    -- Fel Succubus     120526
    -- Shadow Succubus  120527
    -- Shivarra         58963
    spec:RegisterPet( "succubus", 
        function()
            if Glyphed( 240263 ) then return 120526
            elseif Glyphed( 240266 ) then return 120527
            elseif Glyphed( 112868 ) then return 58963 end
            return 1863
        end,
        3600 )

    -- Wrathguard       58965
    spec:RegisterPet( "felguard",
        function() return Glyphed( 112870 ) and 58965 or 17252 end,
        "summon_felguard",
        3600 )


    -- Abilities
    spec:RegisterAbilities( {
        axe_toss = {
            id = 89766,
            known = function () return IsSpellKnownOrOverridesKnown( 119914 ) end,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,

            usable = function () return pet.exists end,
            handler = function ()
                applyDebuff( 'target', 'axe_toss', 4 )
            end,
        },


        banish = {
            id = 710,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( 'target', 'banish', 30 )
            end,
        },


        bilescourge_bombers = {
            id = 267211,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 2,
            spendType = "soul_shards",

            talent = 'bilescourge_bombers',

            startsCombat = true,

            handler = function ()
            end,
        },


        burning_rush = {
            id = 111400,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            talent = 'burning_rush',

            handler = function ()
                if buff.burning_rush.up then removeBuff( 'burning_rush' )
                else applyBuff( 'burning_rush', 3600 ) end
            end,
        },


        -- PvP:master_summoner.
        call_dreadstalkers = {
            id = 104316,
            cast = function () if pvptalent.master_summoner.enabled then return 0 end
                return buff.demonic_calling.up and 0 or ( 2 * haste )
            end,
            cooldown = 20,
            gcd = "spell",

            spend = function () return 2 - ( buff.demonic_calling.up and 1 or 0 ) end,
            spendType = "soul_shards",

            startsCombat = true,

            handler = function ()
                summon_demon( "dreadstalkers", 12, 2 )
                removeStack( 'demonic_calling' )

                if talent.from_the_shadows.enabled then applyDebuff( 'target', 'from_the_shadows' ) end
            end,
        },


        --[[ command_demon = {
            id = 119898,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
                if pet.felguard.up then runHandler( 'axe_toss' )
                elseif pet.felhunter.up then runHandler( 'spell_lock' )
                elseif pet.voidwalker.up then runHandler( 'shadow_bulwark' )
                elseif pet.succubus.up then runHandler( 'seduction' )
                elseif pet.imp.up then runHandler( 'singe_magic' ) end
            end,
        }, ]]


        create_healthstone = {
            id = 6201,
            cast = function () return 3 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        create_soulwell = {
            id = 29893,
            cast = function () return 3 * haste end,
            cooldown = 120,
            gcd = "spell",

            spend = 0.05,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        dark_pact = {
            id = 108416,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,

            talent = 'dark_pact',

            handler = function ()
                applyBuff( 'dark_pact', 20 )
            end,
        },


        demonbolt = {
            id = 264178,
            cast = function () return buff.demonic_core.up and 0 or ( 4.5 * haste ) end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                if buff.forbidden_knowledge.up and buff.demonic_core.down then
                    removeBuff( "forbidden_knowledge" )
                end

                removeStack( 'demonic_core' )
                gain( 2, "soul_shards" )
            end,
        },


        demonic_circle = {
            id = 48018,
            cast = 0.5,
            cooldown = 10,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            talent = 'demonic_circle',

            handler = function ()
            end,
        },


        demonic_circle_teleport = {
            id = 48020,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,

            talent = 'demonic_circle',

            handler = function ()
            end,
        },


        demonic_gateway = {
            id = 111771,
            cast = function () return 2 * haste end,
            cooldown = 10,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        demonic_strength = {
            id = 267171,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            nobuff = "felstorm",

            handler = function ()
                applyBuff( 'demonic_strength' )
            end,
        },


        doom = {
            id = 265412,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,

            talent = 'doom',
            
            cycle = "doom",
            min_ttd = function () return 3 + debuff.doom.duration end,

            -- readyTime = function () return IsCycling() and 0 or debuff.doom.remains end,
            -- usable = function () return IsCycling() or ( target.time_to_die < 3600 and target.time_to_die > debuff.doom.duration ) end,
            handler = function ()
                applyDebuff( 'target', 'doom' )
            end,
        },


        drain_life = {
            id = 234153,
            cast = function () return 5 * haste end,
            cooldown = 0,
            channeled = true,
            gcd = "spell",

            spend = 0,
            spendType = "mana",

            startsCombat = true,

            start = function ()
                applyDebuff( 'drain_life' )
            end,
        },


        enslave_demon = {
            id = 1098,
            cast = function () return 3 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        eye_of_kilrogg = {
            id = 126,
            cast = function () return 2 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        fear = {
            id = 5782,
            cast = function () return 1.7 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.05,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( 'target', 'fear' )
            end,
        },


        grimoire_felguard = {
            id = 111898,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            toggle = 'cooldowns',

            startsCombat = true,

            handler = function ()
                summon_demon( "grimoire_felguard", 15 )
                applyBuff( "grimoire_felguard" )
            end,
        },


        hand_of_guldan = {
            id = 105174,
            cast = function () return 1.5 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            startsCombat = true,
            flightTime = 0.7,

            -- usable = function () return soul_shards.current >= 3 end,
            handler = function ()
                local extra_shards = min( 2, soul_shards.current )
                spend( extra_shards, "soul_shards" )

                insert( guldan_v, query_time + 1.05 )
                if extra_shards > 0 then insert( guldan_v, query_time + 1.50 ) end
                if extra_shards > 1 then insert( guldan_v, query_time + 1.90 ) end

                -- Don't immediately summon; queue them up.
                -- summon_demon( "wild_imps", 25, 1 + extra_shards, 1.5 )
            end,
        },


        health_funnel = {
            id = 755,
            cast = function () return 5 * haste end,
            cooldown = 0,
            gcd = "spell",

            channeled = true,            
            startsCombat = false,

            start = function ()
                applyBuff( 'health_funnel' )
            end,
        },


        implosion = {
            id = 196277,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            velocity = 30,

            usable = function ()
                if buff.wild_imps.stack < 3 and azerite.explosive_potential.enabled then return false, "too few imps for explosive_potential"
                elseif buff.wild_imps.stack < 1 then return false, "no imps available" end
                return true
            end,

            handler = function ()
                if azerite.explosive_potential.enabled and buff.wild_imps.stack >= 3 then applyBuff( "explosive_potential" ) end
                consume_demons( "wild_imps", "all" )
            end,
        },


        mortal_coil = {
            id = 6789,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( 'target', 'mortal_coil' )
            end,
        },


        nether_portal = {
            id = 267217,
            cast = function () return 2.5 * haste end,
            cooldown = 180,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            toggle = "cooldowns", 

            startsCombat = false,

            handler = function ()
                applyBuff( "nether_portal" )
            end,
        },


        power_siphon = {
            id = 264130,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,

            talent = "power_siphon",

            readyTime = function ()
                if buff.wild_imps.stack >= 2 then return 0 end

                local imp_deficit = 2 - buff.wild_imps.stack

                for i, imp in ipairs( guldan_v ) do
                    if imp > query_time then
                        imp_deficit = imp_deficit - 1
                        if imp_deficit == 0 then return imp - query_time end
                    end
                end

                return 3600
            end,

            handler = function ()
                local num = min( 2, buff.wild_imps.count ) 
                consume_demons( "wild_imps", num )

                addStack( "demonic_core", 20, num )
            end,
        },


        ritual_of_summoning = {
            id = 698,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 0,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        shadow_bolt = {
            id = 686,
            cast = function () return 2 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                gain( 1, "soul_shards" )
            end,
        },


        shadowfury = {
            id = 30283,
            cast = function () return 1.5 * haste end,
            cooldown = function () return talent.darkfury.enabled and 45 or 60 end,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
            end,
        },


        soul_strike = {
            id = 264057,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            startsCombat = true,
            -- nobuff = "felstorm", -- Does not appear to prevent Soul Strike any longer.

            usable = function () return pet.felguard.up and pet.alive end,
            handler = function ()
                gain( 1, "soul_shards" )
            end,
        },


        soulstone = {
            id = 20707,
            cast = 3,
            cooldown = 600,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
            end,
        },


        summon_demonic_tyrant = {
            id = 265187,
            cast = function () return 2 * haste end,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 90 end,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            texture = 2065628,
            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
                summonPet( "demonic_tyrant", 15 )
                summon_demon( "demonic_tyrant", 15 )
                applyBuff( "demonic_power", 15 )
                if talent.demonic_consumption.enabled then
                    consume_demons( "wild_imps", "all" )
                end
                if azerite.baleful_invocation.enabled then gain( 5, "soul_shards" ) end
                extend_demons()
            end,
        },


        summon_felguard = {
            id = 30146,
            cast = function () return 2.5 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            startsCombat = false,
            essential = true,

            bind = "summon_pet",
            nomounted = true,

            usable = function () return not pet.exists end,
            handler = function ()
                summonPet( 'felguard', 3600 )
            end,

            copy = { "summon_pet", 112870 }
        },


        summon_vilefiend = {
            id = 264119,
            cast = function () return 2 * haste end,
            cooldown = 45,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
                summon_demon( "vilefiend", 15 )
            end,
        },


        unending_breath = {
            id = 5697,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        },


        unending_resolve = {
            id = 104773,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            toggle = "defensives",

            startsCombat = true,

            handler = function ()
            end,
        },


        --[[ wartime_ability = {
            id = 264739,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]
    } )

    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = false,
        nameplateRange = 8,

        cycle = true,

        damage = true,
        damageExpiration = 6,

        potion = "unbridled_fury",

        package = "Demonology",
    } )

    spec:RegisterPack( "Demonology", 20200124, [[dKej8bqiLswKqc1JukkxsiHWMus9jLIizukroLsuRsPi5vkbZsjPBjKKDjYVefnmvGJHiwgIQNjkmnvqDnLeBtfeFtPi14esGZPuuTovqQMNkX9uQ2hI0bvkIuluPupufKYevbjxuibPtkKGYkruMPqcQ2PsHFkKq0qvkI4PemvHuxviH0xfsqSxb)vvdgLdRyXc1JHmzOUmPntOpleJwL60sTALIWRvcnBuDBI2nv)MYWfvhxPiQLd65inDjxhHTRs67IsJxiPoVk06fs08vr7h4ajHOdc4P0WgKFa5hCajKF40bB(kB(kB6GqDmxdc5dAXjIge8rQbHdLkn34wKJbH85i3gCi6Ga1iGiniCxvo9qpZmJ01nrCczYmPTKGpvBocoIvM0wIYmiet08kkmpeheWtPHni)aYp4asi)WPd28v28vwjiqZvuydYpKdjiC3yS6H4GawPOGWMbyhkvAUXTihbSOqgi3qlciBZaS7QYPh6zMzKUUjItitMjTLe8PAZrWrSYK2suMaY2maJSXjg4raJ8dVkGr(bKFaGmazBgGDODpEeLEOdiBZaSOcWeYvohWIc3qlMaKTzawubyrrPkGftikMCTUv4NBWA4jICaRDAPdgWmradQYP92JayhAhkaRAPcyIgeW2qRBfcyBsmynCaBqvFvbS87HQjazBgGfvawuKo)iGbvKjLQJbSdLknp24fGLd1OczY4PaSweW6cWAkG1oTgVaSLmiGDpqmAOfGjAqal2OuLUCcq2MbyrfGTjXYQqatOZVnhWgo3YQyalhQrfYKXtbyLby5qdbyTtRXla7qPsZJnELaKTzawubyrrPkGffxTu)YECRrXa2sAuNROsXaM6iJWlfcyQJxgWGtDRqaRUhhWIIRbgrRu1s9l7XTgfdylPrDUIkfdyiciu9cWQbgrRnPOagwN6EzaRmaBUAngW0OgPuAFvbSycO3EeaZebm4G6HdyhAhkAkiKdnXMRbHndWouQ0CJBrocyrHmqUHweq2Mby3vLtp0ZmZiDDteNqMmtAlj4t1MJGJyLjTLOmbKTzagzJtmWJag5hEvaJ8di)aazaY2ma7q7E8ik9qhq2MbyrfGjKRCoGffUHwmbiBZaSOcWIIsvalMqum5ADRWp3G1Wte5aw70shmGzIaguLt7ThbWo0ouaw1sfWeniGTHw3keW2KyWA4a2GQ(Qcy53dvtaY2malQaSOiD(radQitkvhdyhkvAESXlalhQrfYKXtbyTiG1fG1uaRDAnEbylzqa7EGy0qlat0GawSrPkD5eGSndWIkaBtILvHaMqNFBoGnCULvXawouJkKjJNcWkdWYHgcWANwJxa2HsLMhB8kbiBZaSOcWIIsvalkUAP(L94wJIbSL0OoxrLIbm1rgHxkeWuhVmGbN6wHawDpoGffxdmIwPQL6x2JBnkgWwsJ6CfvkgWqeqO6fGvdmIwBsrbmSo19Yawza2C1AmGPrnsP0(QcyXeqV9iaMjcyWb1dhWo0ou0eGmazBgGffAuRiIsXawSkAqfWqMmEkalwJ0onbyBsJqAErbm38O6EGsrcoGnOQnNcyMZpMaKTza2GQ2CAkhQitgp1UiFOlciBZaSbvT50uourMmEQf2Zu0mmGSndWgu1Mtt5qfzY4PwypZHiIu9AQ2CazdQAZPPCOImz8ulSNjLqkn)Z1cq2MbydQAZPPCOImz8ulSNz7UcFSknNUAlUxdx9k1URWhRsZPj1NyUIbKTza2GQ2CAkhQitgp1c7zs9jNEB1tRPOaYgu1Mtt5qfzY4PwypZClRcFANFB(QT4EmHOykBZXFlZPjAnOfjLK1XeIIjSknVrpYGAIwdAXl7KdiBqvBonLdvKjJNAH9mZTQnhq2GQ2CAkhQitgp1c7zIvP5XgVwTf3Jnk98CqvBEcRsZJnELqdT2paq2GQ2CAkhQitgp1c7zsVhSL9JnEbidq2MbyrHg1kIOumGPxv4raRAPcy1TcydQmiG1uaBUonFI5Acq2GQ2C6onx58NBOfbKnOQnNUWEM5w1MVAlUNRvcRsZB0xhHJxPbv9vD9sBPuQ6inDTPT5Vj(5kuurvBEsoBcdEEUvnC1RewLM3OhzoLqMxT5j1NyUIpprMXXwwprjKsZFSknVrFDeoELGQCANs6oYmo2Y6jkHuA(JvP5n6RJWXReMaovBEuTYYRxARA4QxjxRBf(5gSgEs9jMR4ZZycrXKR1Tc)CdwdprKV85z1s9l7XTEjJdaKnOQnNUWEMeu97sLR6Ju3NOKEpWH(IMxVj(5wwfUAlUJmJJTSEIsiLM)yvAEJ(6iC8kbv50o9Yo5hSERA4QxjxRBf(5gSgEs9jMRyazdQAZPlSNjbv)UujD1wCpxRewLM3OVochVsdQ6R66L2sPu1rA6AtBZFt8ZvOOIQ28KC2eg88CRA4QxjSknVrpYCkHmVAZtQpXCfFEImJJTSEIsiLM)yvAEJ(6iC8kbv50oL0DKzCSL1tucP08hRsZB0xhHJxjmbCQ28OALLppRwQFzpU1l7KScGSbvT50f2ZmwHufUy7rwTf3Z1kHvP5n6RJWXR0GQ(QUEPTukvDKMU20283e)CfkQOQnpjNnHbpp3QgU6vcRsZB0JmNsiZR28K6tmxXNNiZ4ylRNOesP5pwLM3OVochVsqvoTtjDhzghBz9eLqkn)XQ08g91r44vctaNQnpQwz5ZZQL6x2JB9YojRaiBqvBoDH9mJ5MHFrc4XvBX9CTsyvAEJ(6iC8knOQVQRxAlLsvhPPRnTn)nXpxHIkQAZtYztyWZZTQHRELWQ08g9iZPeY8QnpP(eZv85jYmo2Y6jkHuA(JvP5n6RJWXReuLt7us3rMXXwwprjKsZFSknVrFDeoELWeWPAZJQvw(8SAP(L94wVStYkaYgu1MtxyptXgQXCZWR2I75ALWQ08g91r44vAqvFvxV0wkLQostxBAB(BIFUcfvu1MNKZMWGNNBvdx9kHvP5n6rMtjK5vBEs9jMR4ZtKzCSL1tucP08hRsZB0xhHJxjOkN2PKUJmJJTSEIsiLM)yvAEJ(6iC8kHjGt1MhvRS85z1s9l7XTEzNKvaKnOQnNUWEMXCZWVj(1T(QRYJR2I75ALWQ08g91r44vAqvFvxNRvcRsZB0xhHJxjOkN2Px2jzLOkccVPYy9sBPuQ6inDTPT5Vj(5kuurvBEsoBcdEEUvnC1RewLM3OhzoLqMxT5j1NyUIpprMXXwwprjKsZFSknVrFDeoELGQCANs6oYmo2Y6jkHuA(JvP5n6RJWXReMaovBEuTYYaYgu1MtxypZSgKJVQT)qLA(4iD1wCpMqumXBrnMBgorRbT4LmwVuUwjSknVrFDeoELgu1x11lTLsPQJ001M2M)M4NRqrfvT5j5Sjm455w1WvVsyvAEJEK5uczE1MNuFI5k(8ezghBz9eLqkn)XQ08g91r44vcQYPDkP7iZ4ylRNOesP5pwLM3OVochVsyc4uT5r1klFEwTu)YECRx2jzLLbKnOQnNUWEMWopNRF7pnFq6QT4EUwjSknVrFDeoELgu1x11lTLsPQJ001M2M)M4NRqrfvT5j5Sjm455w1WvVsyvAEJEK5uczE1MNuFI5k(8ezghBz9eLqkn)XQ08g91r44vcQYPDkP7iZ4ylRNOesP5pwLM3OVochVsyc4uT5r1klFEwTu)YECRx2jzfazdQAZPlSNjbv)Uu5Q(i19CdTOw0okv8JmzornvB(J1RnsxTf3rMXXwwprjKsZFSknVrFDeoELGQCANs6o5hSgzghBz9eLqkn)XQ08g91r44vcQYPD6LDKzCSL1tucP08hRsZB0xhHJxjmbCQ28OIKvopRwQFzpU1l7zCaGSbvT50f2ZKGQFxQCvFK6o0keKGwk(VAg2ShBC(QT4(siZ4ylRNOesP5pwLM3OVochVsqvoTtjDN8vopRwQFzpU1l7zCWYaYgu1MtxyptcQ(DPYv9rQ707(Qc)RQBYhQ8gTAlUVeYmo2Y6jkHuA(JvP5n6RJWXReuLt7us3jFLZZQL6x2JB9YEghSmGSbvT50f2ZKGQFxQCvFK6(Sjt05wPE9(qunNGUAlUVeYmo2Y6jkHuA(JvP5n6RJWXReuLt7us3jFLZZQL6x2JB9YEghSmGSbvT50f2ZKGQFxQCvFK6E1yLwgu(idRr9QT4(siZ4ylRNOesP5pwLM3OVochVsqvoTtjDN8vopRwQFzpU1l7zCWYaYgu1MtxyptcQ(DPYv9rQ7x7H)M4tldkPR2I7lHmJJTSEIsiLM)yvAEJ(6iC8kbv50oL0DYx58SAP(L94wVSNXbldiBqvBoDH9mrdN)dQAZFEtRv9rQ7wU6kC1wCFRA4QxjxRBf(5gSgEs9jMR41vl1lzCW6TqMXXwwprjKsZFSknVrFDeoELGQCANciBqvBoDH9mjO63Lkx1hPUprj9EGd9fnVEt8ZTSkC1wCFPQLkPzCW55w1WvVsUw3k8Znyn8K6tmxXlVUgU6vkcSLwd1xu5rigioP(eZv86LQwQFzpUvsjH8dopRwQFzpU1liZ4ylRNOesP5pwLM3OVochVsqvoTtxGKvw(8SAP(L94wVSNXkaYgu1MtxypZ7XXVj(ri44XxTf3NOuHDPjnQZ5gTVQFUvQx9WtWXxCD1s9YkRPgb)P3detk5RJjeftAuNZnAFv)CRuV6HNWwwFDmHOykBZXFlZPjAnOfVKX6TYH61pccNijDpo(nXpcbhp(6TYH61pccNipDpo(nXpcbhpoGSbvT50f2ZeRsZJnETAlUtnc(tVhi(YEgRJjeftyvAEJEKb1er(6ycrXewLM3OhzqnrRbT4(HbKnOQnNUWEMTmNB028vBX9jkvyxAsJ6CUr7R6NBL6vp8eC8fxhtikMY2C83YCAIwdArsjFDmHOysJ6CUr7R6NBL6vp8euLt70ldQAZt07bBz)yJxjnQverPF1sD9sBvdx9kHvP5n6rMtjK5vBEs9jMR4ZtKzCSL1tucP08hRsZB0xhHJxjOkN2PKsc5ldiBqvBoDH9mXMjxTf33QA0IThzD1s9l7XTsAghSMMRC(xdmIw0ulZ5gTn)c5R3kMqum5ADRWp3G1WtqvoTtbKnOQnNUWEMXnxPiJagr)ytgRq6QT4(eLkSlnPrDo3O9v9ZTs9QhEco(IKEW6QL6fsoynnx58VgyeTOPwMZnAB(fYxhtikMWqDW0A4lQqAcQYPD66A4QxjxRBf(5gSgEs9jMRyazdQAZPlSNjwLM3ONwq1Ju3R2I7lftikMY2C83YCAIwdAXlhY5zmHOycRsZB0NBzvyIiF5ZtAUY5FnWiArtTmNB028lKdiBqvBoDH9mrdN)dQAZFEtRv9rQ7Uw3k8Znyn8vBX9A4QxjxRBf(5gSgEs9jMR410CLZ)AGr0IMAzo3OT5x2jhq2GQ2C6c7zIgo)hu1M)8MwR6Ju3Bzo3OT5R2I70CLZ)AGr0IMAzo3OT5KscGSbvT50f2ZmcXaX94Vj(tuQqRUxTf3rMXXwwprjKsZFSknVrFDeoELGQCANEzNKvopRwQFzpU1l7zCaGSbvT50f2ZmcSLwd1xu5rigiE1wCFPQL6x2JBLusi)GZZQL6x2JB9cYmo2Y6jkHuA(JvP5n6RJWXReuLt70fizLZtKzCSL1tucP08hRsZB0xhHJxjOkN2PxijJLbKnOQnNUWEMucP08)AZvXwD8QT4oYmo2Y6jkHuA(JvP5n6RJWXReuLt7usp8bNNiZ4ylRNOesP5pwLM3OVochVsqvoTtVqc5aYgu1Mtxypt0W5pgQdMwdFrfsxTf3xczghBz9eLqkn)XQ08g91r44vcQYPD6LnFDmHOycRsZB0JgoV9ijOkN2PlFEUeYmo2Y6jkHuA(JvP5n6RJWXReuLt70lKqY6TIjeftyvAEJE0W5Thjbv50oD5ZtKzCSL1tucP08hRsZB0xhHJxjOkN2PKsYHbKnOQnNUWEM1T(eESr44x0GiD1wCpMqumbv0ICLsFrdI0euhubiBqvBoDH9mJBUsrgbmI(XMmwHuazdQAZPlSN59443e)ieC84R2I7lnrPc7stXdxfj4F7xn0uT5j1NyUIppRHRELWQ08g9iZPeY8QnpP(eZv8YRZH61pccNijDpo(nXpcbhp(AKzCSL1tucP08hRsZB0xhHJxjOkN2Pxihq2MbyKFWbhefbnx58)EOLcynfWO3gSUhhdyIgeWQBfWqdTaSQLkGzIa2HsLM3ial6JWXReGf9TcyTxQxawtbSYamZ5hbSyns7agAOv7raSweWgadPWAAhWCczScbmteWAzofWY2CoGfRaMruaw8raRUvatDmGzIawDRagAOvcq2GQ2C6c7zsjKsZFSknVrFDeoETAlUtnc(tVhi(sgRxARA4QxjSknVrpYCkHmVAZtQpXCfFEgtikMY2C83YCAIwdAXfAzo9P5twxXpMa2EKeLqkn)XQ08g91r44fP7hY6QL6x23YCAA48euLt70lOHwF1sD5ZZQL6x2JB9c5haiBqvBoDH9mZTSk8PD(T5R2I7XeIIPSnh)TmNMO1GwK0DYxhtikMWQ08g9idQjAnOfVSt(6ycrXewLM3Op3YQWe2Y6RP5kN)1aJOfn1YCUrBZVqoGSbvT50f2ZeBMC1wCVgU6vcBMmP(eZv8AOkcv69eZ11vl1VSh3kPlHTkHntMGQCANUqghSmGSbvT50f2Z8EC8BIFecoE8vBXDQrWF69aXKUVY55suJG)07bIjDpJ1iZ4ylRNqdN)yOoyAn8fvinbv50oL0dVEjKzCSL1tucP08hRsZB0xhHJxjOkN2PKs(bNNlHmJJTSEIsiLM)yvAEJ(6iC8kbv50o9seeEtr(6A4QxjSknVrpYCkHmVAZtQpXCfFEImJJTSEIsiLM)yvAEJ(6iC8kbv50o9seeEtD41Bvdx9kHvP5n6rMtjK5vBEs9jMR4LxE9sBvdx9krjKsZ)RnxfB1Xj1NyUIpprMXXwwprjKsZ)RnxfB1XjOkN2PKMXYldiBqvBoDH9mPgb)PfSxuxTf3Pgb)P3deFzL1XeIIjSknVrpYGAIwdAXl7KdiBqvBoDH9mXQ08yJxR2I7uJG)07bIVSNX6ycrXewLM3OhzqnrKVEPLqMXXwwprjKsZFSknVrFDeoELGQCANE5qoprMXXwwprjKsZFSknVrFDeoELGQCANsk5KVERjkvyxAIEpyll9J7stQpXCfV85zmHOycRsZB0JmOMO1GwK09mopJjeftyvAEJEKb1euLt70lRCEwTu)YECRxiFLZZycrXe9EWww6h3LMGQCANUmGSbvT50f2Zu0qeuf)tuQWU0pwh5QT4(w5ALWQ08g91r44vAqvFvbKnOQnNUWEM5eWw8y7r(y(qlazdQAZPlSNzm3m8BIFDRV6Q8iGSbvT50f2Zezos9coLIFr(i1vBX9TWwLqMJuVGtP4xKps9JjGEcQYPD66Tgu1MNqMJuVGtP4xKpsn1(lY7i316TY1kHvP5n6RJWXR0GQ(QciBqvBoDH9mH6K3EKxKpsLUAlUVvUwjSknVrFDeoELgu1xvazdQAZPlSNjA48FqvB(ZBATQpsDpMO54FE69aXaYaKnOQnNMIjAo(NNEpq8UuLg84BIpNa14hd1rsxTf3Pgb)P3deFHCazdQAZPPyIMJ)5P3deVWEMuJG)0c2lQR2I7Bvdx9kHvP5n6rMtjK5vBEs9jMR4ZZQLkPKSY5zouV(rq4ejP7XXVj(ri44XxVvmHOykMBgMtqReuLt7uazdQAZPPyIMJ)5P3deVWEM07bBz)yJxaYaKnOQnNMAzo3OT57TmNB028vBX9LIjeftzBo(BzonrRbTiP7hY6LOgb)P3deFjJZZCOE9JGWjssOHZFmuhmTg(IkKEEgtikMY2C83YCAIwdArs338ZZCOE9JGWjssXnxPiJagr)ytgRq655sBLd1RFeeors6EC8BIFecoE81BLd1RFeeorE6EC8BIFecoE8LxE9w5q96hbHtKKUhh)M4hHGJhF9w5q96hbHtKNUhh)M4hHGJhFDmHOycRsZB0NBzvycBz9LppxQAP(L94wVKX6ycrXu2MJ)wMtt0Aqls6blFEUuouV(rq4e5j0W5pgQdMwdFrfsxhtikMY2C83YCAIwdArsjF9w1WvVsyvAEJE0W5ThjP(eZv8YaYgu1MttTmNB028f2ZmcSLwd1xu5rigiE1wChzghBz9eLqkn)XQ08g91r44vcQYPD6fsY48ClDtMOZZvCIKmipJdzZbKnOQnNMAzo3OT5lSNjA48hd1btRHVOcPR2I7lHmJJTSEIsiLM)yvAEJ(6iC8kbv50o9YMVoMqumHvP5n6rdN3EKeuLt70LppxczghBz9eLqkn)XQ08g91r44vcQYPD6fsiz9wXeIIjSknVrpA482JKGQCANU85jYmo2Y6jkHuA(JvP5n6RJWXReuLt7usj5WaYgu1MttTmNB028f2ZKsiLM)yvAEJ(6iC8cq2GQ2CAQL5CJ2MVWEM3JJFt8JqWXJVAlUtnc(tVhiM09vaKnOQnNMAzo3OT5lSN59443e)ieC84R2I7uJG)07bIjDpJ1lT0s5q96hbHtKNUhh)M4hHGJh)8mMqumLT54VL50eTg0IKUNXYRJjeftzBo(BzonrRbT4LnF5ZtKzCSL1tucP08hRsZB0xhHJxjOkN2Px2JGWBkYppJjeftyvAEJ(ClRctqvoTtjnccVPiFzazdQAZPPwMZnAB(c7zIvP5XgVwTf3ZH61pccNijDpo(nXpcbhp(AQrWF69aXKUtY6LIjeftzBo(BzonrRbT4L9mopZH61pccNYiDpo(nXpcbhp(YRPgb)P3deF5WRJjeftyvAEJEKb1eroGSbvT50ulZ5gTnFH9mPesP5)1MRIT64vBX9LqMXXwwprjKsZFSknVrFDeoELGQCANs6Hpynnx58VgyeTOPwMZnAB(LDYx(8ezghBz9eLqkn)XQ08g91r44vcQYPD6fsihq2GQ2CAQL5CJ2MVWEMXnxPiJagr)ytgRq6QT4oYmo2Y6jkHuA(JvP5n6RJWXReuLt7us3CazdQAZPPwMZnAB(c7zkAicQI)jkvyx6hRJeq2GQ2CAQL5CJ2MVWEM5eWw8y7r(y(qlazdQAZPPwMZnAB(c7zgZnd)M4x36RUkpciBqvBon1YCUrBZxyptK5i1l4uk(f5JuxTf33cBvczos9coLIFr(i1pMa6jOkN2PR3AqvBEczos9coLIFr(i1u7ViVJCxRP5kN)1aJOfn1YCUrBZVScGSbvT50ulZ5gTnFH9mPgb)PfSxuxTf3Pgb)P3deFzL1XeIIjSknVrpYGAIwdAXl7KdiBqvBon1YCUrBZxyptSknp241QT4o1i4p9EG4l7zSoMqumHvP5n6rgute5RxkMqumHvP5n6rgut0Aqls6EgNNXeIIjSknVrpYGAcQYPD6L9ii8MAL0MEzazdQAZPPwMZnAB(c7zIntUk6iIRFnWiAr3jzv5e1p6iIRFnWiAr330R2I7qveQ07jMRaYgu1MttTmNB028f2ZenC(pOQn)5nTw1hPUht0C8pp9EGyazaYgu1MttUw3k8Znyn8D0W5)GQ28N30AvFK6UR1Tc)Cdwd)JjAoU9iR2I7iZ4ylRNCTUv4NBWA4jOkN2Pxi)aazdQAZPjxRBf(5gSg(c7zIgo)hu1M)8MwR6Ju3DTUv4NBWA4)GQ(QUAlUhtikMCTUv4NBWA4jICazaYgu1MttUw3k8Znyn8FqvFv3JBUsrgbmI(XMmwHuazdQAZPjxRBf(5gSg(pOQVQlSNzeylTgQVOYJqmq8QT4oYmo2Y6jkHuA(JvP5n6RJWXReuLt70lKKX55w6MmrNNR4ejzqEghYMdiBqvBon5ADRWp3G1W)bv9vDH9mPesP5)1MRIT64vBXDKzCSL1tucP08hRsZB0xhHJxjOkN2PKE4doprMXXwwprjKsZFSknVrFDeoELGQCANEHeYbKnOQnNMCTUv4NBWA4)GQ(QUWEMOHZFmuhmTg(IkKUAlUVeYmo2Y6jkHuA(JvP5n6RJWXReuLt70lB(6ycrXewLM3OhnCE7rsqvoTtx(8CjKzCSL1tucP08hRsZB0xhHJxjOkN2PxiHK1BftikMWQ08g9OHZBpscQYPD6YNNiZ4ylRNOesP5pwLM3OVochVsqvoTtjLKddiBqvBon5ADRWp3G1W)bv9vDH9mrdN)dQAZFEtRv9rQ7Xenh)ZtVhiE1wCNAe8NEpq8ojRxczghBz9eA48hd1btRHVOcPjOkN2Pxgu1MNO3d2Y(XgVsOHwF1s98CPA4QxP4MRuKraJOFSjJvinP(eZv8AKzCSL1tXnxPiJagr)ytgRqAcQYPD6LbvT5j69GTSFSXReAO1xTuxEzazdQAZPjxRBf(5gSg(pOQVQlSN59443e)ieC84R2I7lTeYmo2Y6j0W5pgQdMwdFrfstqvoTtjDqvBEcRsZJnELqdT(QL6YRxczghBz9eA48hd1btRHVOcPjOkN2PKoOQnprVhSL9JnELqdT(QL6YlVgzghBz9KR1Tc)Cdwdpbv50oL0Li5qwzHbvT5P7XXVj(ri44XtOHwF1sDzazdQAZPjxRBf(5gSg(pOQVQlSNjLqkn)XQ08g91r441QT4EmHOyY16wHFUbRHNGQCANEzL1uJG)07bI3paq2GQ2CAY16wHFUbRH)dQ6R6c7zsjKsZFSknVrFDeoETAlUhtikMCTUv4NBWA4jOkN2Pxgu1MNOesP5pwLM3OVochVsOHwF1sDHdsRaiBqvBon5ADRWp3G1W)bv9vDH9mXQ08yJxR2I7XeIIjSknVrpYGAIiFn1i4p9EG4l7zaiBqvBon5ADRWp3G1W)bv9vDH9mrdN)dQAZFEtRv9rQ7Xenh)ZtVhigqgGSbvT50KR1Tc)Cdwd)JjAoU9i7eu97sLR6Ju3NOKEpWH(IMxVj(5wwfUAlUJmJJTSEY16wHFUbRHNGQCANEzFLnfnx58)EOLciBqvBon5ADRWp3G1W)yIMJBpYc7zgHyG4E83e)jkvOv3R2I7BHmJJTSEY16wHFUbRHNGQCANUMAe8NEpqmP7RaiBqvBon5ADRWp3G1W)yIMJBpYc7z6ADRWp3G1WxTf3Pgb)P3det6(kaYgu1MttUw3k8Znyn8pMO542JSWEMOHZFmuhmTg(IkKUAlUxTujDpJdaKnOQnNMCTUv4NBWA4FmrZXThzH9mVhh)M4hHGJhF1wCVAPs6EghSgzghBz9eA48hd1btRHVOcPjOkN2PKssuWAQrWF69aXKUNbGSbvT50KR1Tc)Cdwd)JjAoU9ilSNzULvHpTZVnF1wCVAPs6EghSoMqumLT54VL50eTg0IKUt(6ycrXewLM3OhzqnrRbT4LDYxhtikMWQ08g95wwfMWwwFn1i4p9EGys3Zaq2GQ2CAY16wHFUbRH)Xenh3EKf2Z8EC8BIFecoE8vBX9QLkP7zCWAQrWF69aXKUVcGSbvT50KR1Tc)Cdwd)JjAoU9ilSNjA48FqvB(ZBATQpsDpMO54FE69aXaYaKnOQnNMSC1v4(9443e)ieC84RYBxFeEpJdwTf3NOuHDPjnQZ5gTVQFUvQx9WtQpXCfdiBqvBonz5QRWf2ZSL5CJ2MVAlUprPc7stAuNZnAFv)CRuV6HNuFI5kEDmHOykBZXFlZPjAnOfjL81XeIIjnQZ5gTVQFUvQx9WtylRdiBqvBonz5QRWf2ZeBMCvE76JW7zCaGSbvT50KLRUcxypZiede3J)M4prPcT6gq2GQ2CAYYvxHlSN59443e)ieC84R2I75q96hbHtKKUhh)M4hHGJhFn1i4p9EGyspyDouV(rq4e5jQrWFAb7fvazdQAZPjlxDfUWEMyvAEJEAbvpsDVAlUNd1RFeeors6EC8BIFecoE81BLd1RFeeorE6EC8BIFecoE81lftikMY2C83YCAIwdArsjz9GQ2809443e)ieC84P2FrEh5Uwgq2GQ2CAYYvxHlSNzCZvkYiGr0p2KXkKciBqvBonz5QRWf2ZKAe8NwWErDvE76JW7zCWQT4(wXeIIPyUzyobTsqvoTtppRwQKUY6COE9JGWjss3JJFt8JqWXJdiBqvBonz5QRWf2ZKsiLM)xBUk2QJxTf3Pgb)P3deVVcGSbvT50KLRUcxypZiWwAnuFrLhHyG4vBXDQrWF69aX7RaiBqvBonz5QRWf2ZenC(JH6GP1WxuH0vBXDQrWF69aX7RaiBqvBonz5QRWf2Z8EC8BIFecoE8vBXDQrWF69aX7RaiBqvBonz5QRWf2Z8EC8BIFecoE8vBXDQrWF69aXKUNX6COE9JGWjYt3JJFt8JqWXJVUAPs6kRxkhQx)iiCIKe1i4pTG9I655w1WvVsuJG)0c2lQj1NyUIxNd1RFeeorsIEpyl7hB8AzazBgGr(bhCque0CLZ)7HwkG1uaJEBW6ECmGjAqaRUvadn0cWQwQaMjcyhkvAEJaSOpchVsaw03kG1EPEbynfWkdWmNFeWI1iTdyOHwThbWAraBamKcRPDaZjKXkeWmraRL5ualBZ5awScygrbyXhbS6wbm1XaMjcy1TcyOHwjazdQAZPjlxDfUWEMucP08hRsZB0xhHJxR2I75q96hbHtKKWQ08g90cQEK6(8mhQx)iiCIK09443e)ieC84RZH61pccNipDpo(nXpcbhp(55w1WvVsyvAEJEAbvpsDNuFI5kEDmHOykBZXFlZPjAnOfxOL50NMpzDf)ycy7rsucP08hRsZB0xhHJxKUFiaYgu1MttwU6kCH9mXQ08yJxR2I7uJG)07bIVSNX6ycrXewLM3Ohzqnbv50ofq2GQ2CAYYvxHlSNjA48FqvB(ZBATQpsDpMO54FE69aXbHRkK2Mh2G8dizZpik4GmcczhO3EeAqikmzUblfdyrba2GQ2CaJ30IMaKfe4nTOHOdcwU6kmeDydscrheuFI5koSDqyqvBEq4EC8BIFecoE8Gac2Lc7jimrPc7stAuNZnAFv)CRuV6HNuFI5koiWBxFeoiKXbHkSb5HOdcQpXCfh2oiGGDPWEcctuQWU0Kg15CJ2x1p3k1RE4j1NyUIbS1awmHOykBZXFlZPjAnOfbmsbmYbS1awmHOysJ6CUr7R6NBL6vp8e2Y6bHbvT5bHwMZnABEOcBKri6GG6tmxXHTdcdQAZdcyZKbbE76JWbHmoiuHnoCi6GWGQ28GqeIbI7XFt8NOuHwDheuFI5koSDOcBSsi6GG6tmxXHTdciyxkSNGqouV(rq4ejP7XXVj(ri44XbS1ag1i4p9EGyaJua7aaBnGLd1RFeeorEIAe8NwWErnimOQnpiCpo(nXpcbhpEOcBCiHOdcQpXCfh2oiGGDPWEcc5q96hbHtKKUhh)M4hHGJhhWwdyBby5q96hbHtKNUhh)M4hHGJhhWwdylbyXeIIPSnh)TmNMO1GweWifWibWwdydQAZt3JJFt8JqWXJNA)f5DK7cWwoimOQnpiGvP5n6Pfu9i1DOcBSPdrhegu1MheIBUsrgbmI(XMmwH0GG6tmxXHTdvyJOGq0bb1NyUIdBhegu1MheOgb)PfSxudciyxkSNGWwawmHOykMBgMtqReuLt7ua78eWQwQagPa2ka2AalhQx)iiCIK09443e)ieC84bbE76JWbHmoiuHn28q0bb1NyUIdBheqWUuypbbQrWF69aXa2oGTsqyqvBEqGsiLM)xBUk2QJdvydsoieDqq9jMR4W2bbeSlf2tqGAe8NEpqmGTdyReegu1MheIaBP1q9fvEeIbIdvydsijeDqq9jMR4W2bbeSlf2tqGAe8NEpqmGTdyReegu1MheqdN)yOoyAn8fvinuHniH8q0bb1NyUIdBheqWUuypbbQrWF69aXa2oGTsqyqvBEq4EC8BIFecoE8qf2GKmcrheuFI5koSDqab7sH9eeOgb)P3dedyKUdyzayRbSCOE9JGWjYt3JJFt8JqWXJdyRbSQLkGrkGTcGTgWwcWYH61pccNijrnc(tlyVOcyNNa2wawnC1Re1i4pTG9IAs9jMRyaBnGLd1RFeeorsIEpyl7hB8cWwoimOQnpiCpo(nXpcbhpEOcBqYHdrheuFI5koSDqab7sH9eeYH61pccNijHvP5n6Pfu9i1nGDEcy5q96hbHtKKUhh)M4hHGJhhWwdy5q96hbHtKNUhh)M4hHGJhhWopbSTaSA4QxjSknVrpTGQhPUtQpXCfdyRbSycrXu2MJ)wMtt0AqlcylayTmN(08jRR4htaBpsIsiLM)yvAEJ(6iC8cWiDhWoKGWGQ28GaLqkn)XQ08g91r44vOcBqYkHOdcQpXCfh2oiGGDPWEccuJG)07bIbSl7awga2AalMqumHvP5n6rgutqvoTtdcdQAZdcyvAESXRqf2GKdjeDqq9jMR4W2bHbvT5bb0W5)GQ28N30kiWBA9(i1GqmrZX)807bIdvOccUw3k8Znyn8FqvFvdrh2GKq0bHbvT5bH4MRuKraJOFSjJviniO(eZvCy7qf2G8q0bb1NyUIdBheqWUuypbbKzCSL1tucP08hRsZB0xhHJxjOkN2Pa2faJKmaSZtaBlat3Kj68CfNY2CrOIPpTJ083eFkrUcBd(ucP082Jeegu1MheIaBP1q9fvEeIbIdvyJmcrheuFI5koSDqab7sH9eeqMXXwwprjKsZFSknVrFDeoELGQCANcyKcyh(aa78eWqMXXwwprjKsZFSknVrFDeoELGQCANcyxamsipimOQnpiqjKsZ)RnxfB1XHkSXHdrheuFI5koSDqab7sH9eewcWqMXXwwprjKsZFSknVrFDeoELGQCANcyxaSnhWwdyXeIIjSknVrpA482JKGQCANcyldyNNa2sagYmo2Y6jkHuA(JvP5n6RJWXReuLt7ua7cGrcja2AaBlalMqumHvP5n6rdN3EKeuLt7uaBza78eWqMXXwwprjKsZFSknVrFDeoELGQCANcyKcyKC4GWGQ28GaA48hd1btRHVOcPHkSXkHOdcQpXCfh2oiGGDPWEccuJG)07bIbSDaJeaBnGTeGHmJJTSEcnC(JH6GP1WxuH0euLt7ua7cGnOQnprVhSL9JnELqdT(QLkGDEcylby1WvVsXnxPiJagr)ytgRqAs9jMRyaBnGHmJJTSEkU5kfzeWi6hBYyfstqvoTtbSla2GQ28e9EWw2p24vcn06RwQa2Ya2YbHbvT5bb0W5)GQ28N30kiWBA9(i1GqmrZX)807bIdvyJdjeDqq9jMR4W2bbeSlf2tqyjaBjadzghBz9eA48hd1btRHVOcPjOkN2PagPa2GQ28ewLMhB8kHgA9vlvaBzaBnGTeGHmJJTSEcnC(JH6GP1WxuH0euLt7uaJuaBqvBEIEpyl7hB8kHgA9vlvaBzaBzaBnGHmJJTSEY16wHFUbRHNGQCANcyKcylbyKCiRaylaydQAZt3JJFt8JqWXJNqdT(QLkGTCqyqvBEq4EC8BIFecoE8qf2ythIoiO(eZvCy7Gac2Lc7jietikMCTUv4NBWA4jOkN2Pa2faBfaBnGrnc(tVhigW2bSdccdQAZdcucP08hRsZB0xhHJxHkSruqi6GG6tmxXHTdciyxkSNGqmHOyY16wHFUbRHNGQCANcyxaSbvT5jkHuA(JvP5n6RJWXReAO1xTubSfaSdsReegu1MheOesP5pwLM3OVochVcvyJnpeDqq9jMR4W2bbeSlf2tqiMqumHvP5n6rgute5a2AaJAe8NEpqmGDzhWYiimOQnpiGvP5XgVcvydsoieDqq9jMR4W2bHbvT5bb0W5)GQ28N30kiWBA9(i1GqmrZX)807bIdvOccyvCi4vi6WgKeIoimOQnpiqZvo)5gAXGG6tmxXHTdvydYdrheuFI5koSDqab7sH9eeY1kHvP5n6RJWXR0GQ(QcyRbSLaSTamLsvhPPRnTn)nXpxHIkQAZtYztyqa78eW2cWQHRELWQ08g9iZPeY8QnpP(eZvmGDEcyiZ4ylRNOesP5pwLM3OVochVsqvoTtbms3bmKzCSL1tucP08hRsZB0xhHJxjmbCQ2CalQaSvaSLbS1a2sa2wawnC1RKR1Tc)CdwdpP(eZvmGDEcyXeIIjxRBf(5gSgEIihWwgWopbSQL6x2JBfWUayzCqqyqvBEqi3Q28qf2iJq0bb1NyUIdBhegu1MheMOKEpWH(IMxVj(5wwfgeqWUuypbbKzCSL1tucP08hRsZB0xhHJxjOkN2Pa2LDaJ8daS1a2wawnC1RKR1Tc)CdwdpP(eZvCqWhPgeMOKEpWH(IMxVj(5wwfgQWghoeDqq9jMR4W2bbeSlf2tqixRewLM3OVochVsdQ6RkGTgWwcW2cWukvDKMU20283e)CfkQOQnpjNnHbbSZtaBlaRgU6vcRsZB0JmNsiZR28K6tmxXa25jGHmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWiDhWqMXXwwprjKsZFSknVrFDeoELWeWPAZbSOcWwbWwgWopbSQL6x2JBfWUSdyKSsqyqvBEqGGQFxQKgQWgReIoiO(eZvCy7Gac2Lc7jiKRvcRsZB0xhHJxPbv9vfWwdylbyBbykLQostxBAB(BIFUcfvu1MNKZMWGa25jGTfGvdx9kHvP5n6rMtjK5vBEs9jMRya78eWqMXXwwprjKsZFSknVrFDeoELGQCANcyKUdyiZ4ylRNOesP5pwLM3OVochVsyc4uT5awubyRayldyNNaw1s9l7XTcyx2bmswjimOQnpieRqQcxS9iHkSXHeIoiO(eZvCy7Gac2Lc7jiKRvcRsZB0xhHJxPbv9vfWwdylbyBbykLQostxBAB(BIFUcfvu1MNKZMWGa25jGTfGvdx9kHvP5n6rMtjK5vBEs9jMRya78eWqMXXwwprjKsZFSknVrFDeoELGQCANcyKUdyiZ4ylRNOesP5pwLM3OVochVsyc4uT5awubyRayldyNNaw1s9l7XTcyx2bmswjimOQnpieZnd)IeWJHkSXMoeDqq9jMR4W2bbeSlf2tqixRewLM3OVochVsdQ6RkGTgWwcW2cWukvDKMU20283e)CfkQOQnpjNnHbbSZtaBlaRgU6vcRsZB0JmNsiZR28K6tmxXa25jGHmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWiDhWqMXXwwprjKsZFSknVrFDeoELWeWPAZbSOcWwbWwgWopbSQL6x2JBfWUSdyKSsqyqvBEqqSHAm3mCOcBefeIoiO(eZvCy7Gac2Lc7jiKRvcRsZB0xhHJxPbv9vfWwdy5ALWQ08g91r44vcQYPDkGDzhWizfalQaSiimGTPaSmaS1a2sa2waMsPQJ001M2M)M4NRqrfvT5j5SjmiGDEcyBby1WvVsyvAEJEK5uczE1MNuFI5kgWopbmKzCSL1tucP08hRsZB0xhHJxjOkN2PagP7agYmo2Y6jkHuA(JvP5n6RJWXReMaovBoGfva2ka2YbHbvT5bHyUz43e)6wF1v5Xqf2yZdrheuFI5koSDqab7sH9eeIjeft8wuJ5MHt0AqlcyxaSmaS1a2sawUwjSknVrFDeoELgu1xvaBnGTeGTfGPuQ6inDTPT5Vj(5kuurvBEsoBcdcyNNa2wawnC1RewLM3OhzoLqMxT5j1NyUIbSZtadzghBz9eLqkn)XQ08g91r44vcQYPDkGr6oGHmJJTSEIsiLM)yvAEJ(6iC8kHjGt1MdyrfGTcGTmGDEcyvl1VSh3kGDzhWizfaB5GWGQ28GqwdYXx12FOsnFCKgQWgKCqi6GG6tmxXHTdciyxkSNGqUwjSknVrFDeoELgu1xvaBnGTeGTfGPuQ6inDTPT5Vj(5kuurvBEsoBcdcyNNa2wawnC1RewLM3OhzoLqMxT5j1NyUIbSZtadzghBz9eLqkn)XQ08g91r44vcQYPDkGr6oGHmJJTSEIsiLM)yvAEJ(6iC8kHjGt1MdyrfGTcGTmGDEcyvl1VSh3kGDzhWizLGWGQ28GaSZZ563(tZhKgQWgKqsi6GG6tmxXHTdcdQAZdc5gArTODuQ4hzYCIAQ28hRxBKgeqWUuypbbKzCSL1tucP08hRsZB0xhHJxjOkN2PagP7ag5hayRbmKzCSL1tucP08hRsZB0xhHJxjOkN2Pa2LDadzghBz9eLqkn)XQ08g91r44vctaNQnhWIkaJKvaSZtaRAP(L94wbSl7awghee8rQbHCdTOw0okv8JmzornvB(J1RnsdvydsipeDqq9jMR4W2bHbvT5bbOviibTu8F1mSzp248Gac2Lc7jiSeGHmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWiDhWiFfa78eWQwQFzpUva7YoGLXba2YbbFKAqaAfcsqlf)xndB2JnopuHnijJq0bb1NyUIdBhegu1MheO39vf(xv3Kpu5nkiGGDPWEcclbyiZ4ylRNOesP5pwLM3OVochVsqvoTtbms3bmYxbWopbSQL6x2JBfWUSdyzCaGTCqWhPgeO39vf(xv3Kpu5nkuHni5WHOdcQpXCfh2oimOQnpimBYeDUvQxVpevZjObbeSlf2tqyjadzghBz9eLqkn)XQ08g91r44vcQYPDkGr6oGr(ka25jGvTu)YECRa2LDalJdaSLdc(i1GWSjt05wPE9(qunNGgQWgKSsi6GG6tmxXHTdcdQAZdcvJvAzq5JmSg1bbeSlf2tqyjadzghBz9eLqkn)XQ08g91r44vcQYPDkGr6oGr(ka25jGvTu)YECRa2LDalJdaSLdc(i1Gq1yLwgu(idRrDOcBqYHeIoiO(eZvCy7GWGQ28GW1E4Vj(0YGsAqab7sH9eewcWqMXXwwprjKsZFSknVrFDeoELGQCANcyKUdyKVcGDEcyvl1VSh3kGDzhWY4aaB5GGpsniCTh(BIpTmOKgQWgKSPdrheuFI5koSDqab7sH9ee2cWQHRELCTUv4NBWA4j1NyUIbS1aw1sfWUayzCaGTgW2cWqMXXwwprjKsZFSknVrFDeoELGQCANgegu1MheqdN)dQAZFEtRGaVP17JudcwU6kmuHnijkieDqq9jMR4W2bHbvT5bHjkP3dCOVO51BIFULvHbbeSlf2tqyjaRAPcyKcyzCaGDEcyBby1WvVsUw3k8Znyn8K6tmxXa2Ya2AaRgU6vkcSLwd1xu5rigioP(eZvmGTgWwcWQwQFzpUvaJuaJeYpaWopbSQL6x2JBfWUayiZ4ylRNOesP5pwLM3OVochVsqvoTtbSfamswbWwgWopbSQL6x2JBfWUSdyzSsqWhPgeMOKEpWH(IMxVj(5wwfgQWgKS5HOdcQpXCfh2oiGGDPWEcctuQWU0Kg15CJ2x1p3k1RE4j44lcyRbSQLkGDbWwbWwdyuJG)07bIbmsbmYbS1awmHOysJ6CUr7R6NBL6vp8e2Y6a2AalMqumLT54VL50eTg0Ia2faldaBnGTfGLd1RFeeors6EC8BIFecoECaBnGTfGLd1RFeeorE6EC8BIFecoE8GWGQ28GW9443e)ieC84HkSb5heIoiO(eZvCy7Gac2Lc7jiqnc(tVhigWUSdyzayRbSycrXewLM3OhzqnrKdyRbSycrXewLM3OhzqnrRbTiGTdyhoimOQnpiGvP5XgVcvydYjjeDqq9jMR4W2bbeSlf2tqyIsf2LM0OoNB0(Q(5wPE1dpbhFraBnGftikMY2C83YCAIwdAraJuaJCaBnGftikM0OoNB0(Q(5wPE1dpbv50ofWUaydQAZt07bBz)yJxjnQverPF1sfWwdylbyBby1WvVsyvAEJEK5uczE1MNuFI5kgWopbmKzCSL1tucP08hRsZB0xhHJxjOkN2PagPagjKdylhegu1MheAzo3OT5HkSb5KhIoiO(eZvCy7Gac2Lc7jiSfGvnAX2JayRbSQL6x2JBfWifWY4aaBnGrZvo)RbgrlAQL5CJ2MdyxamYbS1a2wawmHOyY16wHFUbRHNGQCANgegu1MheWMjdvydYZieDqq9jMR4W2bbeSlf2tqyIsf2LM0OoNB0(Q(5wPE1dpbhFraJua7aaBnGvTubSlagjhayRbmAUY5FnWiArtTmNB02Ca7cGroGTgWIjeftyOoyAn8fvinbv50ofWwdy1WvVsUw3k8Znyn8K6tmxXbHbvT5bH4MRuKraJOFSjJvinuHni)WHOdcQpXCfh2oiGGDPWEcclbyXeIIPSnh)TmNMO1GweWUayhcGDEcyXeIIjSknVrFULvHjICaBza78eWO5kN)1aJOfn1YCUrBZbSlag5bHbvT5bbSknVrpTGQhPUdvydYxjeDqq9jMR4W2bbeSlf2tqOgU6vY16wHFUbRHNuFI5kgWwdy0CLZ)AGr0IMAzo3OT5a2LDaJ8GWGQ28GaA48FqvB(ZBAfe4nTEFKAqW16wHFUbRHhQWgKFiHOdcQpXCfh2oiGGDPWEcc0CLZ)AGr0IMAzo3OT5agPagjbHbvT5bb0W5)GQ28N30kiWBA9(i1GqlZ5gTnpuHniFthIoiO(eZvCy7Gac2Lc7jiGmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWUSdyKScGDEcyvl1VSh3kGDzhWY4GGWGQ28GqeIbI7XFt8NOuHwDhQWgKhfeIoiO(eZvCy7Gac2Lc7jiSeGvTu)YECRagPagjKFaGDEcyvl1VSh3kGDbWqMXXwwprjKsZFSknVrFDeoELGQCANcylayKScGDEcyiZ4ylRNOesP5pwLM3OVochVsqvoTtbSlagjzaylhegu1MheIaBP1q9fvEeIbIdvydY38q0bb1NyUIdBheqWUuypbbKzCSL1tucP08hRsZB0xhHJxjOkN2PagPa2HpaWopbmKzCSL1tucP08hRsZB0xhHJxjOkN2Pa2faJeYdcdQAZdcucP08)AZvXwDCOcBKXbHOdcQpXCfh2oiGGDPWEcclbyiZ4ylRNOesP5pwLM3OVochVsqvoTtbSla2MdyRbSycrXewLM3OhnCE7rsqvoTtbSLbSZtaBjadzghBz9eLqkn)XQ08g91r44vcQYPDkGDbWiHeaBnGTfGftikMWQ08g9OHZBpscQYPDkGTmGDEcyiZ4ylRNOesP5pwLM3OVochVsqvoTtbmsbmsoCqyqvBEqanC(JH6GP1WxuH0qf2idscrheuFI5koSDqab7sH9eeIjeftqfTixP0x0Ginb1bvbHbvT5bH6wFcp2iC8lAqKgQWgzqEi6GWGQ28GqCZvkYiGr0p2KXkKgeuFI5koSDOcBKrgHOdcQpXCfh2oiGGDPWEcclbytuQWU0u8Wvrc(3(vdnvBEs9jMRya78eWQHRELWQ08g9iZPeY8QnpP(eZvmGTmGTgWYH61pccNijDpo(nXpcbhpoGTgWqMXXwwprjKsZFSknVrFDeoELGQCANcyxamYdcdQAZdc3JJFt8JqWXJhQWgzC4q0bb1NyUIdBheqWUuypbbQrWF69aXa2faldaBnGTeGTfGvdx9kHvP5n6rMtjK5vBEs9jMRya78eWIjeftzBo(BzonrRbTiGTaG1YC6tZNSUIFmbS9ijkHuA(JvP5n6RJWXlaJ0Da7qaS1aw1s9l7BzonnCEcQYPDkGDbWqdT(QLkGTmGDEcyvl1VSh3kGDbWi)GGWGQ28GaLqkn)XQ08g91r44vOcBKXkHOdcQpXCfh2oiGGDPWEccXeIIPSnh)TmNMO1GweWiDhWihWwdyXeIIjSknVrpYGAIwdAra7YoGroGTgWIjeftyvAEJ(ClRctylRdyRbmAUY5FnWiArtTmNB02Ca7cGrEqyqvBEqi3YQWN253MhQWgzCiHOdcQpXCfh2oiGGDPWEcc1WvVsyZKj1NyUIbS1agufHk9EI5kGTgWQwQFzpUvaJuaBjadBvcBMmbv50ofWwaWY4aaB5GWGQ28Ga2mzOcBKXMoeDqq9jMR4W2bbeSlf2tqGAe8NEpqmGr6oGTcGDEcylbyuJG)07bIbms3bSmaS1agYmo2Y6j0W5pgQdMwdFrfstqvoTtbmsbSddyRbSLamKzCSL1tucP08hRsZB0xhHJxjOkN2PagPag5hayNNa2sagYmo2Y6jkHuA(JvP5n6RJWXReuLt7ua7cGfbHbSnfGroGTgWQHRELWQ08g9iZPeY8QnpP(eZvmGDEcyiZ4ylRNOesP5pwLM3OVochVsqvoTtbSlaweegW2ua2HbS1a2wawnC1RewLM3OhzoLqMxT5j1NyUIbSLbSLbS1a2sa2wawnC1ReLqkn)V2CvSvhNuFI5kgWopbmKzCSL1tucP08)AZvXwDCcQYPDkGrkGLbGTmGTCqyqvBEq4EC8BIFecoE8qf2iJOGq0bb1NyUIdBheqWUuypbbQrWF69aXa2faBfaBnGftikMWQ08g9idQjAnOfbSl7ag5bHbvT5bbQrWFAb7f1qf2iJnpeDqq9jMR4W2bbeSlf2tqGAe8NEpqmGDzhWYaWwdyXeIIjSknVrpYGAIihWwdylbylbyiZ4ylRNOesP5pwLM3OVochVsqvoTtbSla2HayNNagYmo2Y6jkHuA(JvP5n6RJWXReuLt7uaJuaJCYbS1a2wa2eLkSlnrVhSLL(XDPj1NyUIbSLbSZtalMqumHvP5n6rgut0AqlcyKUdyzayNNawmHOycRsZB0JmOMGQCANcyxaSvaSZtaRAP(L94wbSlag5RayNNawmHOyIEpyll9J7stqvoTtbSLdcdQAZdcyvAESXRqf24WheIoiO(eZvCy7Gac2Lc7jiSfGLRvcRsZB0xhHJxPbv9vnimOQnpiiAicQI)jkvyx6hRJmuHnomjHOdcdQAZdc5eWw8y7r(y(qRGG6tmxXHTdvyJdtEi6GWGQ28Gqm3m8BIFDRV6Q8yqq9jMR4W2HkSXHZieDqq9jMR4W2bbeSlf2tqyladBvczos9coLIFr(i1pMa6jOkN2Pa2AaBlaBqvBEczos9coLIFr(i1u7ViVJCxa2AaBlalxRewLM3OVochVsdQ6RAqyqvBEqazos9coLIFr(i1qf24WhoeDqq9jMR4W2bbeSlf2tqylalxRewLM3OVochVsdQ6RAqyqvBEqaQtE7rEr(ivAOcBC4vcrheuFI5koSDqyqvBEqanC(pOQn)5nTcc8MwVpsniet0C8pp9EG4qfQGqourMmEQq0HnijeDqyqvBEqGsiLM)IkpcXaXbb1NyUIdBhQWgKhIoiO(eZvCy7Gac2Lc7jietikMY2C83YCAIwdAraJuaJeaBnGftikMWQ08g9idQjAnOfbSl7ag5bHbvT5bHClRcFANFBEOcBKri6GWGQ28GqUvT5bb1NyUIdBhQWghoeDqq9jMR4W2bbeSlf2tqi2Oua78eWgu1MNWQ08yJxj0qlaBhWoiimOQnpiGvP5XgVcvyJvcrhegu1MheO3d2Y(XgVccQpXCfh2ouHki0YCUrBZdrh2GKq0bb1NyUIdBheqWUuypbHLaSycrXu2MJ)wMtt0AqlcyKUdyhcGTgWwcWOgb)P3dedyxaSmaSZtalhQx)iiCIKeA48hd1btRHVOcPa25jGftikMY2C83YCAIwdAraJ0DaBZbSZtalhQx)iiCIKuCZvkYiGr0p2KXkKcyNNa2sa2wawouV(rq4ejP7XXVj(ri44XbS1a2wawouV(rq4e5P7XXVj(ri44XbSLbSLbS1a2wawouV(rq4ejP7XXVj(ri44XbS1a2wawouV(rq4e5P7XXVj(ri44XbS1awmHOycRsZB0NBzvycBzDaBza78eWwcWQwQFzpUva7cGLbGTgWIjeftzBo(BzonrRbTiGrkGDaGTmGDEcylby5q96hbHtKNqdN)yOoyAn8fvifWwdyXeIIPSnh)TmNMO1GweWifWihWwdyBby1WvVsyvAEJE0W5ThjP(eZvmGTCqyqvBEqOL5CJ2MhQWgKhIoiO(eZvCy7Gac2Lc7jiGmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWUayKKbGDEcyBby6MmrNNR4u2Mlcvm9PDKM)M4tjYvyBWNsiLM3EKGWGQ28GqeylTgQVOYJqmqCOcBKri6GG6tmxXHTdciyxkSNGWsagYmo2Y6jkHuA(JvP5n6RJWXReuLt7ua7cGT5a2AalMqumHvP5n6rdN3EKeuLt7uaBza78eWwcWqMXXwwprjKsZFSknVrFDeoELGQCANcyxamsibWwdyBbyXeIIjSknVrpA482JKGQCANcyldyNNagYmo2Y6jkHuA(JvP5n6RJWXReuLt7uaJuaJKdhegu1MheqdN)yOoyAn8fvinuHnoCi6GWGQ28GaLqkn)XQ08g91r44vqq9jMR4W2HkSXkHOdcQpXCfh2oiGGDPWEccuJG)07bIbms3bSvccdQAZdc3JJFt8JqWXJhQWghsi6GG6tmxXHTdciyxkSNGa1i4p9EGyaJ0DaldaBnGTeGTeGTeGLd1RFeeorE6EC8BIFecoECa78eWIjeftzBo(BzonrRbTiGr6oGLbGTmGTgWIjeftzBo(BzonrRbTiGDbW2CaBza78eWqMXXwwprjKsZFSknVrFDeoELGQCANcyx2bSiimGTPamYbSZtalMqumHvP5n6ZTSkmbv50ofWifWIGWa2McWihWwoimOQnpiCpo(nXpcbhpEOcBSPdrheuFI5koSDqab7sH9eeYH61pccNijDpo(nXpcbhpoGTgWOgb)P3dedyKUdyKayRbSLaSycrXu2MJ)wMtt0Aqlcyx2bSmaSZtalhQx)iiCkJ09443e)ieC84a2Ya2AaJAe8NEpqmGDbWomGTgWIjeftyvAEJEKb1erEqyqvBEqaRsZJnEfQWgrbHOdcQpXCfh2oiGGDPWEcclbyiZ4ylRNOesP5pwLM3OVochVsqvoTtbmsbSdFaGTgWO5kN)1aJOfn1YCUrBZbSl7ag5a2Ya25jGHmJJTSEIsiLM)yvAEJ(6iC8kbv50ofWUayKqEqyqvBEqGsiLM)xBUk2QJdvyJnpeDqq9jMR4W2bbeSlf2tqazghBz9eLqkn)XQ08g91r44vcQYPDkGrkGT5bHbvT5bH4MRuKraJOFSjJvinuHni5Gq0bHbvT5bbrdrqv8prPc7s)yDKbb1NyUIdBhQWgKqsi6GWGQ28GqobSfp2EKpMp0kiO(eZvCy7qf2GeYdrhegu1MheI5MHFt8RB9vxLhdcQpXCfh2ouHnijJq0bb1NyUIdBheqWUuypbHTamSvjK5i1l4uk(f5Ju)ycONGQCANcyRbSTaSbvT5jK5i1l4uk(f5JutT)I8oYDbyRbmAUY5FnWiArtTmNB02Ca7cGTsqyqvBEqazos9coLIFr(i1qf2GKdhIoiO(eZvCy7Gac2Lc7jiqnc(tVhigWUayRayRbSycrXewLM3OhzqnrRbTiGDzhWipimOQnpiqnc(tlyVOgQWgKSsi6GG6tmxXHTdciyxkSNGa1i4p9EGya7YoGLbGTgWIjeftyvAEJEKb1eroGTgWwcWIjeftyvAEJEKb1eTg0IagP7awga25jGftikMWQ08g9idQjOkN2Pa2LDalccdyBkaBL0MgWwoimOQnpiGvP5XgVcvydsoKq0bb1NyUIdBhegu1MheWMjdcOJiU(1aJOfnSbjbb5e1p6iIRFnWiArdcB6Gac2Lc7jiavrOsVNyUgQWgKSPdrheuFI5koSDqyqvBEqanC(pOQn)5nTcc8MwVpsniet0C8pp9EG4qfQGGR1Tc)Cdwd)JjAoU9iHOdBqsi6GG6tmxXHTdcdQAZdctusVh4qFrZR3e)ClRcdciyxkSNGaYmo2Y6jxRBf(5gSgEcQYPDkGDzhWwbW2uagnx58)EOLge8rQbHjkP3dCOVO51BIFULvHHkSb5HOdcQpXCfh2oiGGDPWEccBbyiZ4ylRNCTUv4NBWA4jOkN2Pa2AaJAe8NEpqmGr6oGTsqyqvBEqicXaX94Vj(tuQqRUdvyJmcrheuFI5koSDqab7sH9eeOgb)P3dedyKUdyReegu1MheCTUv4NBWA4HkSXHdrheuFI5koSDqab7sH9eeQwQagP7awgheegu1MheqdN)yOoyAn8fvinuHnwjeDqq9jMR4W2bbeSlf2tqOAPcyKUdyzCaGTgWqMXXwwpHgo)XqDW0A4lQqAcQYPDkGrkGrsuaGTgWOgb)P3dedyKUdyzeegu1MheUhh)M4hHGJhpuHnoKq0bb1NyUIdBheqWUuypbHQLkGr6oGLXba2AalMqumLT54VL50eTg0IagP7ag5a2AalMqumHvP5n6rgut0Aqlcyx2bmYbS1awmHOycRsZB0NBzvycBzDaBnGrnc(tVhigWiDhWYiimOQnpiKBzv4t78BZdvyJnDi6GG6tmxXHTdciyxkSNGq1sfWiDhWY4aaBnGrnc(tVhigWiDhWwjimOQnpiCpo(nXpcbhpEOcBefeIoiO(eZvCy7GWGQ28GaA48FqvB(ZBAfe4nTEFKAqiMO54FE69aXHkubHyIMJ)5P3dehIoSbjHOdcQpXCfh2oiGGDPWEccuJG)07bIbSlag5bHbvT5bbPkn4X3eFobQXpgQJKgQWgKhIoiO(eZvCy7Gac2Lc7jiSfGvdx9kHvP5n6rMtjK5vBEs9jMRya78eWQwQagPagjRayNNawouV(rq4ejP7XXVj(ri44XbS1a2wawmHOykMBgMtqReuLt70GWGQ28Ga1i4pTG9IAOcBKri6GWGQ28Ga9EWw2p24vqq9jMR4W2HkubbxRBf(5gSgEi6WgKeIoiO(eZvCy7Gac2Lc7jiGmJJTSEY16wHFUbRHNGQCANcyxamYpiimOQnpiGgo)hu1M)8MwbbEtR3hPgeCTUv4NBWA4FmrZXThjuHnipeDqq9jMR4W2bbeSlf2tqiMqum5ADRWp3G1Wte5bHbvT5bb0W5)GQ28N30kiWBA9(i1GGR1Tc)Cdwd)hu1x1qfQqfegI62GbbHwEOfQqfca]] )


end
