-- MageFrost.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR
local FindUnitBuffByID = ns.FindUnitBuffByID


if UnitClassBase( 'player' ) == 'MAGE' then
    local spec = Hekili:NewSpecialization( 64, true )

    -- spec:RegisterResource( Enum.PowerType.ArcaneCharges )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        bone_chilling = 22457, -- 205027
        lonely_winter = 22460, -- 205024
        ice_nova = 22463, -- 157997

        glacial_insulation = 22442, -- 235297
        shimmer = 22443, -- 212653
        ice_floes = 23073, -- 108839

        incanters_flow = 22444, -- 1463
        mirror_image = 22445, -- 55342
        rune_of_power = 22447, -- 116011

        frozen_touch = 22452, -- 205030
        chain_reaction = 22466, -- 278309
        ebonbolt = 22469, -- 257537

        frigid_winds = 22446, -- 235224
        ice_ward = 22448, -- 205036
        ring_of_frost = 22471, -- 113724

        freezing_rain = 22454, -- 270233
        splitting_ice = 23176, -- 56377
        comet_storm = 22473, -- 153595

        thermal_void = 21632, -- 155149
        ray_of_frost = 22309, -- 205021
        glacial_spike = 21634, -- 199786
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3584, -- 214027
        relentless = 3585, -- 196029
        gladiators_medallion = 3586, -- 208683

        deep_shatter = 68, -- 198123
        frostbite = 67, -- 198120
        chilled_to_the_bone = 66, -- 198126
        kleptomania = 58, -- 198100
        dampened_magic = 57, -- 236788
        prismatic_cloak = 3532, -- 198064
        temporal_shield = 3516, -- 198111
        ice_form = 634, -- 198144
        burst_of_cold = 633, -- 206431
        netherwind_armor = 3443, -- 198062
        concentrated_coolness = 632, -- 198148
    } )

    -- Auras
    spec:RegisterAuras( {
        active_blizzard = {
            duration = function () return 8 * haste end,
            max_stack = 1,
            generate = function( t )
                if query_time - action.blizzard.lastCast < 8 * haste then
                    t.count = 1
                    t.applied = action.blizzard.lastCast
                    t.expires = t.applied + ( 8 * haste )
                    t.caster = "player"
                    return
                end

                t.count = 0
                t.applied = 0
                t.expires = 0
                t.caster = "nobody"
            end,
        },
        arcane_intellect = {
            id = 1459,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
            shared = "player", -- use anyone's buff on the player, not just player's.
        },
        blink = {
            id = 1953,
        },
        blizzard = {
            id = 12486,
            duration = 3,
            max_stack = 1,
        },
        bone_chilling = {
            id = 205766,
            duration = 8,
            max_stack = 10,
        },
        brain_freeze = {
            id = 190446,
            duration = 15,
            max_stack = 1,
        },
        chain_reaction = {
            id = 278310,
            duration = 10,
            max_stack = 1,
        },
        chilled = {
            id = 205708,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        cone_of_cold = {
            id = 212792,
            duration = 5,
            type = "Magic",
            max_stack = 1,
        },
        fingers_of_frost = {
            id = 44544,
            duration = 15,
            max_stack = 2,
        },
        flurry = {
            id = 228354,
            duration = 1,
            type = "Magic",
            max_stack = 1,
        },
        freezing_rain = {
            id = 270232,
            duration = 12,
            max_stack = 1,
        },
        frost_nova = {
            id = 122,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        frostbolt = {
            id = 59638,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        frozen_orb = {
            duration = 10,
            max_stack = 1,
            generate = function ()
                local fo = buff.frozen_orb

                if query_time - action.frozen_orb.lastCast < 10 then
                    fo.count = 1
                    fo.applied = action.frozen_orb.lastCast
                    fo.expires = fo.applied + 10
                    fo.caster = "player"
                    return
                end

                fo.count = 0
                fo.applied = 0
                fo.expires = 0
                fo.caster = "nobody"
            end,
        },
        frozen_orb_snare = {
            id = 289308,
            duration = 3,
            max_stack = 1,
        },
        glacial_spike = {
            id = 228600,
            duration = 4,
            max_stack = 1,
        },
        hypothermia = {
            id = 41425,
            duration = 30,
            max_stack = 1,
        },
        ice_barrier = {
            id = 11426,
            duration = 60,
            type = "Magic",
            max_stack = 1,
        },
        ice_block = {
            id = 45438,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        ice_floes = {
            id = 108839,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        ice_nova = {
            id = 157997,
            duration = 2,
            type = "Magic",
            max_stack = 1,
        },
        icicles = {
            id = 205473,
            duration = 61,
            max_stack = 5,
        },
        icy_veins = {
            id = 12472,
            duration = function () return talent.thermal_void.enabled and 30 or 20 end,
            type = "Magic",
            max_stack = 1,
        },
        incanters_flow = {
            id = 116267,
            duration = 3600,
            max_stack = 5,
            meta = {
                stack = function() return state.incanters_flow_stacks end,
                stacks = function() return state.incanters_flow_stacks end,
            }
        },
        preinvisibility = {
            id = 66,
            duration = 3,
            max_stack = 1,
        },
        invisibility = {
            id = 32612,
            duration = 20,
            max_stack = 1
        },
        mirror_image = {
            id = 55342,
            duration = 40,
            max_stack = 3,
            generate = function ()
                local mi = buff.mirror_image

                if action.mirror_image.lastCast > 0 and query_time < action.mirror_image.lastCast + 40 then
                    mi.count = 1
                    mi.applied = action.mirror_image.lastCast
                    mi.expires = mi.applied + 40
                    mi.caster = "player"
                    return
                end

                mi.count = 0
                mi.applied = 0
                mi.expires = 0
                mi.caster = "nobody"
            end,
        },
        polymorph = {
            id = 118,
            duration = 60,
            max_stack = 1
        },
        ray_of_frost = {
            id = 205021,
            duration = 5,
            max_stack = 1,
        },
        rune_of_power = {
            id = 116014,
            duration = 3600,
            max_stack = 1,
        },
        shatter = {
            id = 12982,
        },
        shimmer = {
            id = 212653,
        },
        slow_fall = {
            id = 130,
            duration = 30,
            max_stack = 1,
        },
        temporal_displacement = {
            id = 80354,
            duration = 600,
            max_stack = 1,
        },
        time_warp = {
            id = 80353,
            duration = 40,
            type = "Magic",
            max_stack = 1,
        },
        winters_chill = {
            id = 228358,
            duration = 1,
            type = "Magic",
            max_stack = 1,
        },


        -- Azerite Powers (overrides)
        frigid_grasp = {
            id = 279684,
            duration = 20,
            max_stack = 1,
        },
        overwhelming_power = {
            id = 266180,
            duration = 25,
            max_stack = 25,
        },
        tunnel_of_ice = {
            id = 277904,
            duration = 300,
            max_stack = 3
        },
    } )


    spec:RegisterStateExpr( "fingers_of_frost_active", function ()
        return false
    end )

    spec:RegisterStateFunction( "fingers_of_frost", function( active )
        fingers_of_frost_active = active
    end )


    spec:RegisterStateTable( "ground_aoe", {
        frozen_orb = setmetatable( {}, {
            __index = setfenv( function( t, k )
                if k == "remains" then
                    return buff.frozen_orb.remains
                end
            end, state )
        } ),

        blizzard = setmetatable( {}, {
            __index = setfenv( function( t, k )
                if k == "remains" then return buff.active_blizzard.remains end
            end, state )
        } )
    } )

    spec:RegisterStateTable( "frost_info", {
        last_target_actual = "nobody",
        last_target_virtual = "nobody",
        watching = true,

        real_brain_freeze = false,
        virtual_brain_freeze = false
    } )

    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceGUID == GUID and subtype == "SPELL_CAST_SUCCESS" then
            if spellID == 116 then
                frost_info.last_target_actual = destGUID
            end

            if spellID == 44614 then
                frost_info.real_brain_freeze = FindUnitBuffByID( "player", 190446 ) ~= nil
            end
        end
    end )

    spec:RegisterStateExpr( "brain_freeze_active", function ()
        return frost_info.virtual_brain_freeze
    end )


    spec:RegisterStateTable( "rotation", setmetatable( {},
    {
        __index = function( t, k )
            if k == "standard" and state.settings.rotation == "standard" then return true
            elseif k == "no_ice_lance" and state.settings.rotation == "no_ice_lance" then return true
            elseif k == "frozen_orb" and state.settings.rotation == "frozen_orb" then return true end
        
            return false
        end,
    } ) )


    spec:RegisterStateTable( "incanters_flow", {
        changed = 0,
        count = 0,
        direction = 0,
        
        startCount = 0,
        startTime = 0,
        startIndex = 0,

        values = {
            [0] = { 0, 1 },
            { 1, 1 },
            { 2, 1 },
            { 3, 1 },
            { 4, 1 },
            { 5, 0 },
            { 5, -1 },
            { 4, -1 },
            { 3, -1 },
            { 2, -1 },
            { 1, 0 }
        },

        f = CreateFrame("Frame"),
        fRegistered = false,

        reset = setfenv( function ()
            if talent.incanters_flow.enabled then
                if not incanters_flow.fRegistered then
                    -- One-time setup.
                    incanters_flow.f:RegisterUnitEvent( "UNIT_AURA", "player" )
                    incanters_flow.f:SetScript( "OnEvent", function ()
                        -- Check to see if IF changed.
                        if state.talent.incanters_flow.enabled then
                            local flow = state.incanters_flow
                            local name, _, count = FindUnitBuffByID( "player", 116267, "PLAYER" )
                            local now = GetTime()
                
                            if name then
                                if count ~= flow.count then
                                    if count == 1 then flow.direction = 0
                                    elseif count == 5 then flow.direction = 0
                                    else flow.direction = ( count > flow.count ) and 1 or -1 end

                                    flow.changed = GetTime()
                                    flow.count = count
                                end
                            else
                                flow.count = 0
                                flow.changed = GetTime()
                                flow.direction = 0
                            end
                        end
                    end )

                    incanters_flow.fRegistered = true
                end

                if now - incanters_flow.changed >= 1 then
                    if incanters_flow.count == 1 and incanters_flow.direction == 0 then
                        incanters_flow.direction = 1
                        incanters_flow.changed = incanters_flow.changed + 1
                    elseif incanters_flow.count == 5 and incanters_flow.direction == 0 then
                        incanters_flow.direction = -1
                        incanters_flow.changed = incanters_flow.changed + 1
                    end
                end
    
                if incanters_flow.count == 0 then
                    incanters_flow.startCount = 0
                    incanters_flow.startTime = incanters_flow.changed + floor( now - incanters_flow.changed )
                    incanters_flow.startIndex = 0
                else
                    incanters_flow.startCount = incanters_flow.count
                    incanters_flow.startTime = incanters_flow.changed + floor( now - incanters_flow.changed )
                    incanters_flow.startIndex = 0
                    
                    for i, val in ipairs( incanters_flow.values ) do
                        if val[1] == incanters_flow.count and val[2] == incanters_flow.direction then incanters_flow.startIndex = i; break end
                    end
                end
            else
                incanters_flow.count = 0
                incanters_flow.changed = 0
                incanters_flow.direction = 0
            end
        end, state ),
    } )



    spec:RegisterStateExpr( "incanters_flow_stacks", function ()
        if not talent.incanters_flow.enabled then return 0 end

        local index = incanters_flow.startIndex + floor( query_time - incanters_flow.startTime )
        if index > 10 then index = index % 10 end
        
        return incanters_flow.values[ index ][ 1 ]
    end )

    spec:RegisterStateExpr( "incanters_flow_dir", function()
        if not talent.incanters_flow.enabled then return 0 end

        local index = incanters_flow.startIndex + floor( query_time - incanters_flow.startTime )
        if index > 10 then index = index % 10 end

        return incanters_flow.values[ index ][ 2 ]
    end )

    -- Seemingly, a very silly way to track Incanter's Flow...
    local incanters_flow_time_obj = setmetatable( { __stack = 0 }, {
        __index = function( t, k )
            if not state.talent.incanters_flow.enabled then return 0 end

            local stack = t.__stack
            local ticks = #state.incanters_flow.values

            local start = state.incanters_flow.startIndex + floor( state.offset + state.delay )

            local low_pos, high_pos

            if k == "up" then low_pos = 5
            elseif k == "down" then high_pos = 6 end

            local time_since = ( state.query_time - state.incanters_flow.changed ) % 1

            for i = 0, 10 do
                local index = ( start + i )
                if index > 10 then index = index % 10 end

                local values = state.incanters_flow.values[ index ]

                if values[ 1 ] == stack and ( not low_pos or index <= low_pos ) and ( not high_pos or index >= high_pos ) then
                    return max( 0, i - time_since )
                end
            end

            return 0
        end
    } )

    spec:RegisterStateTable( "incanters_flow_time_to", setmetatable( {}, {
        __index = function( t, k )
            incanters_flow_time_obj.__stack = tonumber( k ) or 0
            return incanters_flow_time_obj
        end
    } ) )

    spec:RegisterHook( "reset_precast", function ()
        if pet.rune_of_power.up then applyBuff( "rune_of_power", pet.rune_of_power.remains )
        else removeBuff( "rune_of_power" ) end

        frost_info.last_target_virtual = frost_info.last_target_actual
        frost_info.virtual_brain_freeze = frost_info.real_brain_freeze

        incanters_flow.reset()
    end )


    spec:RegisterTotem( "rune_of_power", 609815 )

    -- Abilities
    spec:RegisterAbilities( {
        arcane_intellect = {
            id = 1459,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            nobuff = "arcane_intellect",
            essential = true,

            startsCombat = false,
            texture = 135932,

            handler = function ()
                applyBuff( "arcane_intellect" )
            end,
        },


        blink = {
            id = function () return talent.shimmer.enabled and 212653 or 1953 end,
            cast = 0,
            charges = function () return talent.shimmer.enabled and 2 or 1 end,
            cooldown = function () return talent.shimmer.enabled and 20 or 15 end,
            recharge = function () return talent.shimmer.enabled and 20 or 15 end,
            gcd = "off",

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = false,
            texture = function () return talent.shimmer.enabled and 135739 or 135736 end,

            handler = function ()
                if talent.displacement.enabled then applyBuff( "displacement_beacon" ) end
            end,

            copy = { 212653, 1953, "shimmer" }
        },


        blizzard = {
            id = 190356,
            cast = function () return buff.freezing_rain.up and 0 or 2 * haste end,
            cooldown = 8,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135857,

            velocity = 20,

            handler = function ()
                applyDebuff( "target", "blizzard" )
                applyBuff( "active_blizzard" )
            end,
        },


        cold_snap = {
            id = 235219,
            cast = 0,
            cooldown = 300,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 135865,

            handler = function ()
                setCooldown( "ice_barrier", 0 )
                setCooldown( "frost_nova", 0 )
                setCooldown( "cone_of_cold", 0 )
                setCooldown( "ice_block", 0 )
            end,
        },


        comet_storm = {
            id = 153595,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 2126034,

            talent = "comet_storm",

            handler = function ()
            end,
        },


        cone_of_cold = {
            id = 120,
            cast = 0,
            cooldown = 12,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 135852,

            usable = function ()
                return target.distance <= 12
            end,
            handler = function ()
                applyDebuff( "target", "cone_of_cold" )
                active_dot.cone_of_cold = max( active_enemies, active_dot.cone_of_cold )
            end,
        },


        --[[ conjure_refreshment = {
            id = 190336,
            cast = 3,
            cooldown = 15,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = false,
            texture = 134029,

            handler = function ()
            end,
        }, ]]


        counterspell = {
            id = 2139,
            cast = 0,
            cooldown = 24,
            gcd = "off",

            interrupt = true,
            toggle = "interrupts",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135856,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        ebonbolt = {
            id = 257537,
            cast = 2.5,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 1392551,

            velocity = 30,

            handler = function ()
                applyBuff( "brain_freeze" )
            end,
        },


        flurry = {
            id = 44614,
            cast = function ()
                if buff.brain_freeze.up then return 0 end
                return 3 * haste
            end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 1506795,

            handler = function ()
                if buff.brain_freeze.up then
                    applyDebuff( "target", "winters_chill" )
                    removeBuff( "brain_freeze" )
                    frost_info.virtual_brain_freeze = true
                else
                    frost_info.virtual_brain_freeze = false
                end

                applyDebuff( "target", "flurry" )
                addStack( "icicles", nil, 1 )

                if talent.bone_chilling.enabled then addStack( "bone_chilling", nil, 1 ) end
                removeBuff( "ice_floes" )
            end,
        },


        frost_nova = {
            id = 122,
            cast = 0,
            charges = function () return talent.ice_ward.enabled and 2 or nil end,
            cooldown = 30,
            recharge = 30,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135848,

            handler = function ()
                applyDebuff( "target", "frost_nova" )
            end,
        },


        frostbolt = {
            id = 116,
            cast = 2,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135846,

            handler = function ()
                addStack( "icicles", nil, 1 )

                applyDebuff( "target", "chilled" )
                if talent.bone_chilling.enabled then addStack( "bone_chilling", nil, 1 ) end

                removeBuff( "ice_floes" )

                if azerite.tunnel_of_ice.enabled then
                    if frost_info.last_target_virtual == target.unit then
                        addStack( "tunnel_of_ice", nil, 1 )
                    else
                        removeBuff( "tunnel_of_ice" )
                    end
                    frost_info.last_target_virtual = target.unit
                end
            end,
        },


        frozen_orb = {
            id = 84714,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            -- toggle = "cooldowns",

            startsCombat = true,
            texture = 629077,

            handler = function ()
                addStack( "fingers_of_frost", nil, 1 )
                if talent.freezing_rain.enabled then applyBuff( "freezing_rain" ) end
                applyBuff( "frozen_orb" )
                applyDebuff( "target", "frozen_orb_snare" )
            end,
        },


        glacial_spike = {
            id = 199786,
            cast = 3,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 1698699,

            talent = "glacial_spike",

            velocity = 40,

            usable = function () return buff.icicles.stack >= 5 end,
            handler = function ()
                removeBuff( "icicles" )
                applyDebuff( "target", "glacial_spike" )
            end,
        },


        ice_barrier = {
            id = 11426,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            defensive = true,

            spend = 0.03,
            spendType = "mana",

            startsCombat = false,
            texture = 135988,

            handler = function ()
                applyBuff( "ice_barrier" )
            end,
        },


        ice_block = {
            id = 45438,
            cast = 0,
            cooldown = 240,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 135841,

            handler = function ()
                applyBuff( "ice_block" )
                applyDebuff( "player", "hypothermia" )
            end,
        },


        ice_floes = {
            id = 108839,
            cast = 0,
            charges = 3,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",

            startsCombat = false,
            texture = 610877,

            talent = "ice_floes",

            handler = function ()
                applyBuff( "ice_floes" )
            end,
        },


        ice_lance = {
            id = 30455,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135844,

            velocity = 47,

            handler = function ()
                if not talent.glacial_spike.enabled then removeStack( "icicles" ) end
                removeStack( "fingers_of_frost" )

                if talent.chain_reaction.enabled then
                    addStack( "chain_reaction", nil, 1 )
                end

                applyDebuff( "target", "chilled" )
                if talent.bone_chilling.enabled then addStack( "bone_chilling", nil, 1 ) end

                if azerite.whiteout.enabled then
                    cooldown.frozen_orb.expires = max( 0, cooldown.frozen_orb.expires - 0.5 )
                end 
            end,
        },


        ice_nova = {
            id = 157997,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 1033909,

            talent = "ice_nova",

            handler = function ()
                applyDebuff( "target", "ice_nova" )
            end,
        },


        icy_veins = {
            id = 12472,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135838,

            handler = function ()
                applyBuff( "icy_veins" )
                stat.haste = stat.haste + 0.30

                if azerite.frigid_grasp.enabled then
                    applyBuff( "frigid_grasp", 10 )
                    addStack( "fingers_of_frost", nil, 1 )
                end
            end,
        },


        invisibility = {
            id = 66,
            cast = 0,
            cooldown = 300,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 132220,

            handler = function ()
                applyBuff( "preinvisibility" )
                applyBuff( "invisibility", 23 )
            end,
        },


        mirror_image = {
            id = 55342,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 135994,

            talent = "mirror_image",

            handler = function ()
                applyBuff( "mirror_image" )
            end,
        },


        polymorph = {
            id = 118,
            cast = 1.7,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = false,
            texture = 136071,

            handler = function ()
                applyDebuff( "target", "polymorph" )
            end,
        },


        ray_of_frost = {
            id = 205021,
            cast = 5,
            cooldown = 75,
            gcd = "spell",

            channeled = true,

            spend = 0.02,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1698700,

            talent = "ray_of_frost",

            start = function ()
                applyDebuff( "target", "ray_of_frost" )
            end,
        },


        remove_curse = {
            id = 475,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 136082,

            handler = function ()
            end,
        },


        ring_of_frost = {
            id = 113724,
            cast = 2,
            cooldown = 45,
            gcd = "spell",

            spend = 0.08,
            spendType = "mana",

            startsCombat = true,
            texture = 464484,

            talent = "ring_of_frost",

            handler = function ()                
            end,
        },


        rune_of_power = {
            id = 116011,
            cast = 1.5,
            charges = 2,
            cooldown = 40,
            recharge = 40,
            gcd = "spell",

            startsCombat = false,
            texture = 609815,

            nobuff = "rune_of_power",
            talent = "rune_of_power",

            handler = function ()
                applyBuff( "rune_of_power" )
            end,
        },


        slow_fall = {
            id = 130,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = false,
            texture = 135992,

            handler = function ()
                applyBuff( "slow_fall" )
            end,
        },


        spellsteal = {
            id = 30449,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.21,
            spendType = "mana",

            startsCombat = true,
            texture = 135729,

            handler = function ()
            end,
        },


        water_elemental = {
            id = 31687,
            cast = 1.5,
            cooldown = 30,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = false,
            texture = 135862,

            notalent = "lonely_winter",
            nomounted = true,

            usable = function () return not pet.alive end,
            handler = function ()
                summonPet( "water_elemental" )
            end,

            copy = "summon_water_elemental"
        },


        time_warp = {
            id = 80353,
            cast = 0,
            cooldown = 300,
            gcd = "off",

            spend = 0.04,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 458224,

            handler = function ()
                applyBuff( "time_warp" )
                applyDebuff( "player", "temporal_displacement" )
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "potion_of_focused_resolve",

        package = "Frost Mage",
    } )


    spec:RegisterSetting( "rotation", "standard", {
        name = "Preferred Priority",
        desc = "This sets the |cFFFFD100rotation.X|r value, selecting between one of three integrated SimC builds.",
        type = "select",
        width = 1.5,
        values = {
            standard = "Standard",
            no_ice_lance = "No Ice Lance",
            frozen_orb = "Frozen Orb"
        }
    } )

    
    spec:RegisterPack( "Frost Mage", 20200525, [[dWe2KbqiuqEKsvAtaQprQKgLsvCkLKSkuGqVIqzwOi3IGQSlH(fbzykj6yOuwgHQEMssnncQCnsLABOa13uQkACkvfoNsczDkvvAEOaUhHSpckhefuAHOOEikOyIOarxefuTrcv(ibv1irbc6KkvLwPsQzsQe5MKkrTtuQ(PsvfdffiTuLe8uGMkGCvLeQ(kPsyVi9xsgSkhMQfRkpgXKvvxgAZc(Ssz0KQoTKvRKq51KkMnr3wj2TOFl1WrjhhfiWYb9CunDkxNu2oa9DcmELQQopk06bW8vQSFftzJcef87gszx8Ru8RCL6w86oYgBIFFO7vef0yKfsbz5eD8nKcM(csbfhS52C6Y(gsbz5mkB)tbIcYBnibPG6nJfF)kKqBLPx7fj9Iq8Art6w1jb6btiETqeIc(0kPTVj9rb)UHu2f)kf)kxPUfVUJSXM43h6MbtbDntFdPGG1cddfuF9)ysFuWpYjuW9oN4Gn3Mtx23Wz9ENtVzS47xHeARm9AViPxeIxlAs3QojqpycXRfIqZ69oNUSZ4CIx3mnN4xP4x5SEwV35yy075gY3VZ69oNWBUvCooNUA1cQSw9luxNRsUH(FUomNUAoCdTOvlOYA1VqDDUqdNt6CBoos68phdddY504(ggN17DoH3CRa(75ybRgwgJZfAOo85cnCoyBUvDg5MNFh(fkaBaWu1WNqzRkcQKEsWifuwCJtbIcYRCtIQSvspjifik7SrbIcIP)K4NYmfKaldHLtbnxIPfXxNVwArm9Ne)Zb8CSGiGQnYpYweFD(APnhWZ90cH4d6vQcqebaJq0jgf0jw1jfmi1GqgPgLDXtbIcIP)K4NYmfKaldHLtbzbravBKFKT4M0jLlvCwLo4Cap3tleIpOxPkareamcrNyuqNyvNuWGudczKAu2xnfikiM(tIFkZuqNyvNuqIlLkNyvNkzXnkOS4Mk9fKcICoMeKtnk7chfikOtSQtkya2aGPQHpkiM(tIFkZuJYUUParbX0Fs8tzMcsGLHWYPGoXkarfM4sH85e2CIFUD7MZjwbiQWexkKpNWMJT5aEogAoZLyArolzzwLBQIGrm9Ne)uqNyvNuWNSaaah(PgLDgmfikOtSQtkiPxqtXTgUqbX0Fs8tzMAu23NuGOGy6pj(PmtbjWYqy5uWNwielsrKipYnNOZCIMt3Zb8Cm0CpTqi(GELQaeraWieDIrbDIvDsbXxNVwAuJY((Gcefet)jXpLzkibwgclNc(0cH4d6vQcqebaJq0j2Cap3EM7PfcXqLBiKR6GkaBUfHOtS52TBowqeq1g5hzlgKAqiJZTQ5aEU9m3tleIfPisKhx89xXnNOZCcV5EAHqSifrI8i3CIoZTQ5yqCoNyvNXaS52RLwe3FKOzOYQfCoXMZjw1zCt6KYLkoRshmsCUPSAbNtS5CIvDg3KoPCPIZQ0bJg0beLkRwW5yG5QK4PHqUkiBbkRwqL1rDh9KX5aEUNwiexWLgYOQdkPgP(Qpe9fE83cskOtSQtkyrqL0tcsnk7Rikquqm9Ne)uMPGeyziSCk4tleIpOxPkareamcrNyZTB3CSGiGQnYpYweFD(APn3UDZzUetlwjXtdHCvq2cIy6pj(Nd45io3uwTGZj2Cg0beLkRwW5e2Cvs80qixfKTaLvlOY6OUJASMd45io3uwTGZj2Cg0beLkRwW5yG5QK4PHqUkiBbkRwqL1rHl(Bbjf0jw1jfCt6KYLkoRshKAuJcICoMeKtbIYoBuGOGy6pj(PmtbjWYqy5uqyBUvDgdWgamvn8rb5gSigLD2OGoXQoPGexkvoXQovYIBuqzXnv6life5Cmjix1Wh1OSlEkquqm9Ne)uMPGeyziSCkidnhSn3QoJbydaMQg(OGCdweJYoBuqNyvNuqIlLkNyvNkzXnkOS4Mk9fKcICoMeKR(yW1Kg1OgfKx5MevCZZVd)uGOSZgfikiM(tIFkZuqcSmewof0CjMweFD(APfX0Fs8phWZXcIaQ2i)iBr815RL2Cap3EMJHMZCjMwCt6KYLkoRshmIP)K4FUD7M7PfcXIuejYJCZj6mhdmNWn3UDZ90cH4d6vQcqebaJq0j2CRIc6eR6KcgKAqiJuJYU4ParbX0Fs8tzMcsGLHWYPGMlX0IBsNuUuXzv6Grm9Ne)Zb8CSGiGQnYpYwCt6KYLkoRshCoGN7PfcXh0RufGicagHOtmkOtSQtkyqQbHmsnk7RMcefet)jXpLzkibwgclNcYcIaQ2i)iBXaS52RL2Cap3tleIpOxPkareamcrNyZb8C7zogAoZLyAXnPtkxQ4SkDWiM(tI)52TBUNwielsrKipYnNOZCmWCc3CRIc6eR6KcgKAqiJuJYUWrbIcIP)K4NYmf0jw1jfK4sPYjw1PswCJcklUPsFbPGiNJjb5uJYUUParbDIvDsbdWgamvn8rbX0Fs8tzMAu2zWuGOGy6pj(PmtbjWYqy5uqNyfGOctCPq(CcBoXp3UDZ5eRaevyIlfYNtyZX2CaphX5MYQfCorZTY5aEUNwiedvUHqUQdQaS5weIoXMJbMt8uqNyvNuWNSaaah(PgL99jfikiM(tIFkZuqcSmewof8PfcXqLBiKR6GkaBUfHOtmkOtSQtkyrqL0tcsnk77dkquqNyvNuqsVGMIBnCHcIP)K4NYm1OSVIOarbDIvDsbXxNVwAuqm9Ne)uMPgLD2wjfikiM(tIFkZuqcSmewofKHMZjw1zmaBaWu1WxSsvqwB6T5aEUnyRLFL3ymaBaWu1WxeIlEL85en3kPGoXQoPGqNrvhubyZnQrzNn2OarbX0Fs8tzMcsGLHWYPGeNBkRwW5en3kNB3U5CIvaIkmXLc5ZjS5yJc6eR6Kc(Kfaa4Wp1OSZM4ParbX0Fs8tzMcsGLHWYPGpTqi(GELQaeraWieDIn3UDZXcIaQ2i)iBr815RL2C72nNtScquHjUuiFoHnhBZb8CMlX0ICwYYSk3ufbJy6pj(PGoXQoPGBsNuUuXzv6GuJAuqZLyAkyZIceLD2OarbX0Fs8tzMcsGLHWYPGpTqic1su1bfRwacJ)wqohWZzUetlUjDs5sfNvPdgX0Fs8phWZ90cHyrkIe5rU5eDMt0C6EoGNBpZ90cH4d6vQcqebaJq0j2C72nN5smTi(681slIP)K4FoGNJ0T83cYi(681slcXfVs(CmWCeNBkRwW5wff0jw1jfeQLOQdkwTaesnk7INcefet)jXpLzkibwgclNc(0cHiulrvhuSAbim(Bb5CaphdnN5smT4M0jLlvCwLoyet)jX)Cap3EMZCjMweFD(APfX0Fs8phWZr6w(BbzeFD(APfH4IxjFogyoIZnLvl4C72nN5smTiPxqtXTgUeX0Fs8phWZr6w(BbzK0lOP4wdxIqCXRKphdmhX5MYQfCUD7MZCjMwe6mQ6GkaBUfX0Fs8phWZr6w(Bbze6mQ6GkaBUfH4IxjFogyoIZnLvl4C72nhrVd3qUkaDIvD6Y5e2CSfxrZTkkOtSQtkiulrvhuSAbiKAuJcYRCtIQg(OarzNnkquqm9Ne)uMPGoXQoPGexkvoXQovYIBuqzXnv6life5CmjiNAu2fpfikOtSQtkya2aGPQHpkiM(tIFkZuJY(QParbX0Fs8tzMcsGLHWYPGSGiGQnYpYweFD(APnhWZ90cH4d6vQcqebaJq0jgf0jw1jfmi1GqgPgLDHJcefet)jXpLzkibwgclNc6eRaevyIlfYNtyZj(52TBoNyfGOctCPq(CcBo2Md45io3uwTGZjAUvsbDIvDsbFYcaaC4NAu21nfikiM(tIFkZuqcSmewof8PfcXqLBiKR6GkaBUfHOtS5aEos3YFliJbydaMQg(IqCXRKpNWMt3ZTB3CpTqigQCdHCvhubyZTieDInNO5epf0jw1jfSiOs6jbPgLDgmfikiM(tIFkZuqcSmewofK4Ctz1coNO5wjf0jw1jf8jlaaWHFQrzFFsbIcIP)K4NYmfKaldHLtbzbravBKFKTi(681sJc6eR6KcgKAqiJuJY((Gcefet)jXpLzkibwgclNc(0cH4d6vQcqebaJq0j2Cap3EMJfebuTr(r2IbyZTxlT52TBUp(0cHilNOd(vfbJqCXRKpNWMd3FKOzOYQfCoXMZjw1zSiOs6jbJg0beLkRwW5wff0jw1jfmi1GqgPgL9vefikOtSQtkiPxqtXTgUqbX0Fs8tzMAu2zBLuGOGoXQoPG4RZxlnkiM(tIFkZuJYoBSrbIcIP)K4NYmf0jw1jfe6mQ6GkaBUrbR0qiuJLPQaf8PfcXqLBiKR6GkaBUfHOtmrINcwPHqOgltvll4VCdPGSrbjWYqy5uWp(0cHilNOd(vfbJASOgLD2epfikOtSQtk4twaaGd)uqm9Ne)uMPg1OGiNJjb5Qg(OarzNnkquqm9Ne)uMPGeyziSCk4tleIqTevDqXQfGW4VfKZb8CF8Pfcrworh8Rkcg)TGCUD7MZjwbiQWexkKpNWMB1uqNyvNuWqt044x5aGWYq1d9fQrzx8uGOGy6pj(PmtbjWYqy5uqNyfGOctCPq(CmWC6EoGN7JpTqiYYj6GFvrW4VfKZb8CKUL)wqgdWgamvn8fH4IxjFoHnNUNd45yO5CIvDgdWgamvn8fRufK1MEBoGNBd2A5x5ngdWgamvn8fH4IxjForZTskOtSQtk4cU0qgvDqj1i1x9HOVWPgL9vtbIcIP)K4NYmfKaldHLtbzbravBKFKTya2aGPQHV52TBUnyRLFL3ymaBaWu1WxeIlEL85e2C6Mc6eR6Kc(KD)vDqz6rfM4cJuJYUWrbIcIP)K4NYmfKaldHLtbFAHqeQLOQdkwTaeg)TGCoGN7JpTqiYYj6GFvrW4VfKZTB3CoXkarfM4sH85e2CRMc6eR6KcYsdwbgRCt9Ko3OgLDDtbIcIP)K4NYmfKaldHLtbFAHqeQLOQdkwTaeg)TGCoGN7JpTqiYYj6GFvrW4VfKZTB3CoXkarfM4sH85e2CRMc6eR6KcclwSKOQsfNLtqQrzNbtbIcIP)K4NYmf0jw1jfK0jbtd6g(vbPVGuqcSmewof8PfcrOwIQoOy1cqy83cY5aEUp(0cHilNOd(vfbJ)wqsbLvIkYNcYGPgL99jfikiM(tIFkZuqcSmewof8PfcrOwIQoOy1cqy83cY5aEUp(0cHilNOd(vfbJ)wqsbDIvDsbHOZQYnvq6liNAu23huGOGy6pj(PmtbjWYqy5uWNwieHirhjY5QqdjyuJff0jw1jf00JkT81A5xfAibPgL9vefikiM(tIFkZuqcSmewof8PfcrOwIQoOy1cqy83cY5aEUp(0cHilNOd(vfbJ)wqohWZr6w(BbzmaBaWu1WxeIlEL85yG5eU52TBoNyfGOctCPq(CcBUvtbDIvDsbf0q5hqSsfe5D6jbPg1OGiNJjb5QpgCnPrbIYoBuGOGy6pj(PmtbjWYqy5uWNwieHAjQ6GIvlaHXFliNB3U5CIvaIkmXLc5ZjS5wnf0jw1jfm0eno(voaiSmu9qFHAu2fpfikiM(tIFkZuqcSmewof0jwbiQWexkKphdmNUNd452ZCpTqiwKIirEKBorN5yarZX2C72nhdnN5smT4M0jLlvCwLoyet)jX)CRAoGNJ0T83cYya2aGPQHViex8k5ZjS5yBLZb8C7zogAoyBUvDg5MNFh(NB3U5yO5CIvDgdWgamvn8fRufK1MEBoGNBd2A5x5ngdWgamvn8fH4IxjForZTY5wff0jw1jfCbxAiJQoOKAK6R(q0x4uJY(QParbX0Fs8tzMcsGLHWYPG7zoZLyAXnPtkxQ4SkDWiM(tI)5aEUNwielsrKipYnNOZCIMt3Zb8C7zUNwieFqVsvaIiayeIoXMB3U5ybravBKFKTi(681sBUvn3QMB3U52ZC7zoNyfGOctCPq(CcBUvp3UDZXqZzUetlUjDs5sfNvPdgX0Fs8p3QMd452ZCSGiGQnYpYwmaBaWu1W3C72n3gS1YVYBmgGnayQA4lcXfVs(CcBoDp3QMBvuqNyvNuWNS7VQdktpQWexyKAu2fokquqm9Ne)uMPGeyziSCk4tleIqTevDqXQfGW4VfKZTB3CoXkarfM4sH85e2CRMc6eR6KcYsdwbgRCt9Ko3OgLDDtbIcIP)K4NYmfKaldHLtbFAHqeQLOQdkwTaeg)TGCUD7MZjwbiQWexkKpNWMB1uqNyvNuqyXILevvQ4SCcsnk7mykquqm9Ne)uMPGoXQoPGKojyAq3WVki9fKcsGLHWYPGpTqic1su1bfRwacJ)wqsbLvIkYNcYGPgL99jfikiM(tIFkZuqcSmewof8PfcrOwIQoOy1cqy83cskOtSQtkieDwvUPcsFb5uJY((Gcefet)jXpLzkibwgclNc(0cHiej6iroxfAibJASOGoXQoPGMEuPLVwl)Qqdji1OSVIOarbX0Fs8tzMcsGLHWYPGpTqic1su1bfRwacJ)wqo3UDZ5eRaevyIlfYNtyZTAkOtSQtkOGgk)aIvQGiVtpji1OgfCPbexW0OarzNnkquqm9Ne)uMPGeyziSCk4sdiUGPf)f38KGZjS5yBLuqNyvNuWNSsDuEYi1OSlEkquqm9Ne)uMPGeyziSCk4tleIfbvbzJ84VfKuqNyvNuWIGQGSro1OgfKfej9YZnkqu2zJcef0jw1jf0HeprvLgkLiXOGy6pj(Pmtnk7INcef0jw1jfuGBiuHsCbtZLuqm9Ne)uMPgL9vtbIcIP)K4NYmfm9fKc6aW17qNRcDAQoOy1cqif0jw1jf0bGR3Hoxf60uDqXQfGqQrzx4OarbDIvDsbxkiSHQAX3qkiM(tIFkZuJYUUParbDIvDsbz1w1jfet)jXpLzQrzNbtbIc6eR6KcgGn3ET0OGy6pj(PmtnQrbjDl)TGKtbIYoBuGOGoXQoPGBAo8xEQ6GYbaHTPNcIP)K4NYm1OSlEkquqNyvNuWIWOcqSsofet)jXpLzQrzF1uGOGoXQoPGlfe2qvT4Bifet)jXpLzQrzx4OarbX0Fs8tzMcsGLHWYPGpTqic1su1bfRwacJ)wqohWZTN5ybravBKFKTya2aGPQHV52TBoRwqL1QFHZjS5yBLZj2CeNBkRwW5aEoRwqL1QFHZXaZj(vo3QOGoXQoPGqTevDqXQfGqQrzx3uGOGy6pj(PmtbjWYqy5uqZLyArOwIQoOy1cqyet)jX)CapNtScquHjUuiForZX2CaphPB5VfKrOwIQoOy1cqymOjLkis07Wnuz1cohdmhPB5VfKXaSbatvdFriU4vYPGoXQoPGexkvoXQovYIBuqzXnv6lif0CjMMc2SOgLDgmfikiM(tIFkZuqcSmewofKfebuTr(r2IfHrfGyL852TBoRwqL1QFHZXaZT6vsbDIvDsbz1w1j1OSVpParbX0Fs8tzMc6eR6Kc(CjgkiQEqpj6PGeyziSCkidnN5smT4M0jLlvCwLoyet)jX)C72n3tleIpOxPkareamcrNyZb8CSGiGQnYpYwCt6KYLkoRshKcM(csbFUedfevpONe9uJY((Gcef0jw1jfuJJQYWfofet)jXpLzQrzFfrbIc6eR6Kc(KD)vbniJuqm9Ne)uMPgLD2wjfikOtSQtk4dHCeQtLBuqm9Ne)uMPgLD2yJcef0jw1jfuwB6nUAft7VTGPrbX0Fs8tzMAu2zt8uGOGoXQoPGHcIpz3FkiM(tIFkZuJYoBRMcef0jw1jf0tcYnOlvexkPGy6pj(Pmtnk7SjCuGOGoXQoPGpFt1bLblIoCkiM(tIFkZuJAuqVrkqu2zJcef0jw1jfmaBaWu1Whfet)jXpLzQrzx8uGOGoXQoPGpzbaao8tbX0Fs8tzMAu2xnfikiM(tIFkZuqNyvNuqIlLkNyvNkzXnkOS4Mk9fKcICoMeKtnk7chfikOtSQtkiPxqtXTgUqbX0Fs8tzMAu21nfikOtSQtkyrqv2a6uqm9Ne)uMPgLDgmfikiM(tIFkZuqcSmewofKfebuTr(r2I4RZxlT52TBUNwieFqVsvaIiayeIoXMd452ZCSGiGQnYpYwmaBU9APnhWZTN5EAHqSifrI8i3CIoZXaZjCZTB3Cm0CMlX0IBsNuUuXzv6Grm9Ne)ZTQ52TBowqeq1g5hzlUjDs5sfNvPdo3QOGoXQoPGbPgeYi1OSVpParbX0Fs8tzMcsGLHWYPGpTqigQCdHCvhubyZTieDIrbDIvDsblcQKEsqQrzFFqbIc6eR6KccDgvDqfGn3OGy6pj(Pmtnk7RikquqNyvNuq815RLgfet)jXpLzQrzNTvsbIc6eR6KcUjDs5sfNvPdsbX0Fs8tzMAu2zJnkquqNyvNuqsNOQdksl)uqm9Ne)uMPgLD2epfikiM(tIFkZuqNyvNuqR(i3A4II0FC)PGeyziSCk4tleIfHrfGyL84VfKZb8CpTqic1su1bfRwacJ)wqsbtFbPGw9rU1WffP)4(tnk7STAkquqm9Ne)uMPGoXQoPGegjY2GDwe1t6CJcsGLHWYPGpTqiwegvaIvYJ)wqohWZ90cHiulrvhuSAbim(BbjfedbKyQ0xqkiHrISnyNfr9Ko3OgLD2eokquqNyvNuWaS52RLgfet)jXpLzQrzNnDtbIcIP)K4NYmf0jw1jfK4sPYjw1PswCJcklUPsFbPGlnG4cMg1OSZgdMcef0jw1jfSiOs6jbPGy6pj(PmtnQrb5vUjrkqu2zJcefet)jXpLzkibwgclNcs6w(BbzSiOkBa9ie9pJZb8CF8PfcrbvAiKRi6lPmQXIc6eR6KcweuLnGo1OSlEkquqm9Ne)uMPGeyziSCkiSn3QoJCZZVd)uqUblIrzNnkOtSQtkiXLsLtSQtLS4gfuwCtL(csb5vUjrf3887Wp1OSVAkquqm9Ne)uMPGeyziSCkiSn3QoJzRkcQKEsqki3GfXOSZgf0jw1jfK4sPYjw1PswCJcklUPsFbPG8k3KOkBL0tcsnk7chfikiM(tIFkZuqcSmewofe2MBvNXaSbatvdFuqUblIrzNnkOtSQtkiXLsLtSQtLS4gfuwCtL(csb5vUjrvdFuJYUUParbDIvDsblcQYgqNcIP)K4NYm1OSZGParbX0Fs8tzMc6eR6KcA1h5wdxuK(J7pfKaldHLtbFAHqSimQaeRKh)TGCoGN7PfcrOwIQoOy1cqy83csky6lif0QpYTgUOi9h3FQrzFFsbIcIP)K4NYmf0jw1jfKWir2gSZIOEsNBuqcSmewof8PfcXIWOcqSsE83cY5aEUNwieHAjQ6GIvlaHXFliPGyiGetL(csbjmsKTb7SiQN05g1OSVpOarbDIvDsbdWMBVwAuqm9Ne)uMPgL9vefikiM(tIFkZuqNyvNuqIlLkNyvNkzXnkOS4Mk9fKcU0aIlyAuJYoBRKcef0jw1jfSiOs6jbPGy6pj(PmtnQrb)yW1Kgfik7SrbIc6eR6KcsAT0qiNfkLuqm9Ne)uMPgLDXtbIcIP)K4NYmfKaldHLtbzO5GT5w1zmBvrqL0tcohWZXcIaQ2i)iBXGudczCoGNJHM7PfcXqLBiKR6GkaBUfHOtmkOtSQtkyrqL0tcsnk7RMcefet)jXpLzkOtSQtkiXLsLtSQtLS4gfuwCtL(csbjDl)TGKtnk7chfikiM(tIFkZuqcSmewof0jwbiQWexkKpNWMB1Zb8CMlX0IbiIau5Mc6vgX0Fs8p3UDZ5eRaevyIlfYNtyZjCuqNyvNuqIlLkNyvNkzXnkOS4Mk9fKc6nsnk76Mcefet)jXpLzkOtSQtkiXLsLtSQtLS4gfuwCtL(csb5vUjrQrnQrbbeH8Qtk7IFLIFLRC1Ru3uqbomRCJtb1fmSRa77l7c)97CZbKECUAHvdT5cnCoDDPbexW0015Gidc0ki(NJ3l4CUM1lUH)5i69Cd5XzTUuL4CSTFNBfp5ASy1qd)Z5eR6CoD9jRuhLNmQRXz9SEFxy1qd)ZX2QNZjw15CYIB84SMcYc2HsIuW9oN4Gn3Mtx23Wz9ENtVzS47xHeARm9AViPxeIxlAs3QojqpycXRfIqZ69oNUSZ4CIx3mnN4xP4x5SEwV35yy075gY3VZ69oNWBUvCooNUA1cQSw9luxNRsUH(FUomNUAoCdTOvlOYA1VqDDUqdNt6CBoos68phdddY504(ggN17DoH3CRa(75ybRgwgJZfAOo85cnCoyBUvDg5MNFh(fkaBaWu1WNqzRkcQKEsW4SEwV35y47ps0m8p3ddneNJ0lp3M7HBvYJZXWsiilJpx2PWtVdxcAY5CIvDYNRtjJXz9ENZjw1jpYcIKE55MOG056mR37CoXQo5rwqK0lp3etKqHU)Z69oNtSQtEKfej9YZnXejKRTTGP5w15S2jw1jpYcIKE55MyIeYHeprvLgkLiXM1oXQo5rwqK0lp3etKqCTLLovcCdHkuIlyAUCwV35CIvDYJSGiPxEUjMiH4PZIRVnf3CJpRDIvDYJSGiPxEUjMiH04OQmCHP0xqroaC9o05QqNMQdkwTaeoRDIvDYJSGiPxEUjMiHwkiSHQAX3WzTtSQtEKfej9YZnXejeR2QoN1oXQo5rwqK0lp3etKqbyZTxlTz9SEVZXW3FKOz4FoeqeY4CwTGZz6X5CI1W5k(CoGEj9NeJZANyvNCrKwlneYzHs5SEVZTVH5m94Cl(goNENpN4AXnNhmeohX5wLBZvj380MtCsniKrMMtaohXZ5(O0zCotpo3(sW50L8KGZ55FonooxB6r4C6Rn9ZXcwnSmgNZjw1jtZvH5Ca9s6pjgN1oXQo5IjsOIGkPNeKPkiIHGT5w1zmBvrqL0tccmlicOAJ8JSfdsniKrGzONwiedvUHqUQdQaS5weIoXM1oXQo5IjsiIlLkNyvNkzXnMsFbfr6w(BbjFwV35aspoN5Wn0MZ0drU(w(NR4PUAZH7VtS4CmJMaeZ5wTWt3ZzoCdnotZz6X5(viGqmjiFUhAcqmNZ0JZbc0CE(NJHTz4Z5eR6CozXn(CoeNd6MEeohFXLY4CmiSfGaIqMMtCqebOYT5wbVY5ybXac5ZPXRCBog2MHpNtSQZ5Kf3MJ3DIW5C(CLn3dtmugFUni6MKX5cWEzotpoN(At)CSGvdlJX5ywwaaGd)Z5eR6moRDIvDYftKqexkvoXQovYIBmL(ckYBKPkiYjwbiQWexkKlSvdS5smTyaIiavUPGELrm9Ne)725eRaevyIlfYfMWnRDIvDYftKqexkvoXQovYIBmL(ckIx5MeN1Z69oNUOm9ZjoiIau52CRGxjtZvMUYN7HMHW5SEowWQHLvaGZPXRCBoXbBaWCU9d8nNa9yo3Rn9ZjU9ZCE(NJzzbaao8pNdX56qyos3YFliJZPlktFRzZjoiIau52CRGxjtZz6X5iDcic54CfFodQHZ5stFRTPFotpo3VcbeIjbNR4ZTuzXjAsCoT0k5CaIqgNtFTPFoZHBOnhP1sJhN1oXQo5rVrrbydaMQg(M1oXQo5rVrXej0twaaGd)ZANyvN8O3OyIeI4sPYjw1PswCJP0xqriNJjb5ZANyvN8O3OyIeI0lOP4wdxM1oXQo5rVrXejurqv2a6Z69ohyTWswHc)ZjoPgeY4CKo)LvDYNla7L5m94CGanNtSQZ5Kf3IZbwjbNZ0JZT4B4CfFUnmrOBvUnxWHZjroFoMHELZjoiIaGZr07WnKZ0CMECoC)DInhPZFzvNZPhH4Cfp1vBoxkNZ072C1cRgAEAXzTtSQtE0BumrcfKAqiJmvbrSGiGQnYpYweFD(APTB3tleIpOxPkareamcrNyaVhwqeq1g5hzlgGn3ET0aEppTqiwKIirEKBorhgq42TJHmxIPf3KoPCPIZQ0bJy6pj(x1UDSGiGQnYpYwCt6KYLkoRshCvZANyvN8O3OyIeQiOs6jbzQcIEAHqmu5gc5QoOcWMBri6eBwV35aspo3IVHZjOKY52WeHUuY4CpCUnmrOBvUnNpNST56WCIRf3Ce9oCd5ZjqpMZPXRCBotpohdBZWNZjw15CYIBX5acYyLBZz9CFu6mo3k4moxhMtCWMBZPLwjNZ0JqCohIZL9CIRf3Ce9oCd5Z55FUSNZjwbioN4Gnayo3(b(4ZjO1K)5KO)NZ65kBUST5EyLBZPXX)CUnNlLXzTtSQtE0BumrcbDgvDqfGn3M1oXQo5rVrXeje(681sBw7eR6Kh9gftKqBsNuUuXzv6GZ69o3koVYT5yy6eNRdZXW0Y)CfFULMBsgNJbjdk4CjQzqxoNGY0pNPhNJHTz4ZzoCdT5m9qKRVLFECU91MRtjJZ9qsVG85(ibtBUnVY5euM(5GT2MEjJZTpNRHZT0qCoZHBOXJZANyvN8O3OyIeI0jQ6GI0Y)S2jw1jp6nkMiH04OQmCHP0xqrw9rU1WffP)4(Zufe90cHyryubiwjp(BbjWpTqic1su1bfRwacJ)wqoRDIvDYJEJIjsinoQkdxycdbKyQ0xqregjY2GDwe1t6CJPki6PfcXIWOcqSsE83csGFAHqeQLOQdkwTaeg)TGCw7eR6Kh9gftKqbyZTxlTzTtSQtE0BumrcrCPu5eR6ujlUXu6lOOLgqCbtBw7eR6Kh9gftKqfbvspj4SEw7eR6KhjDl)TGKlAtZH)YtvhuoaiSn9ZANyvN8iPB5VfKCXejuryubiwjFw7eR6KhjDl)TGKlMiHwkiSHQAX3Wz9ENBf0sCUomhdAlaHZv85CPaNr(CAC8pNGY0pN4Gnayo3(b(IZXWMmoNedwdicNJO3HBiFo3MZ0JZH5FUomNPhNluB6T546Bn5FUhoNgh)mnx9rxkzCUkmNPhN71C(C)g5PUAZ9lCUkNZ0JZTu)VeNRdZz6X5wbTeN7PfcXzTtSQtEK0T83csUyIecQLOQdkwTaeYufe90cHiulrvhuSAbim(BbjW7HfebuTr(r2IbydaMQg(2TZQfuzT6xOWyBLIrCUPSAbb2QfuzT6xidi(vUQz9ENB)KZXRCtIZzoCdT5c1MEJZ0CMECos3YFliNRdZTcAjoxhMJbTfGW5k(CYwacNZ075CMECos3YFliNRdZjoydaMZTFGpMMZ0x852kar(C4(BqFUvqlX56WCmOTaeohrVd3q(CME3MJRV1K)5E4CAC8pNGY0pNtScqCoZLyACMMRcZXQ586jX4S2jw1jps6w(BbjxmrcrCPu5eR6ujlUXu6lOiZLyAkyZIPkiYCjMweQLOQdkwTaegX0Fs8dStScquHjUuixeBat6w(BbzeQLOQdkwTaegdAsPcIe9oCdvwTGmaPB5VfKXaSbatvdFriU4vYN1oXQo5rs3YFli5IjsiwTvDYufeXcIaQ2i)iBXIWOcqSs(UDwTGkRv)czGvVYzTtSQtEK0T83csUyIesJJQYWfMsFbf9CjgkiQEqpj6zQcIyiZLyAXnPtkxQ4SkDWiM(tI)D7EAHq8b9kvbiIaGri6edywqeq1g5hzlUjDs5sfNvPdoRDIvDYJKUL)wqYftKqACuvgUWN1oXQo5rs3YFli5IjsONS7VkObzCw7eR6KhjDl)TGKlMiHEiKJqDQCBw7eR6KhjDl)TGKlMiHK1MEJRwX0(BlyAZANyvN8iPB5VfKCXejuOG4t29Fw7eR6KhjDl)TGKlMiH8KGCd6sfXLYzTtSQtEK0T83csUyIe65BQoOmyr0HpRN17DogoNJjb5735anp)o8pNN)5yVNBFj4C6sEsWzTtSQtEe5Cmjix9XGRjnrHMOXXVYbaHLHQh6lmvbrpTqic1su1bfRwacJ)wqUBNtScquHjUuixyREw7eR6KhrohtcYvFm4AstmrcTGlnKrvhusns9vFi6lCMQGiNyfGOctCPqodOBG3ZtleIfPisKh5Mt0HbeX2UDmK5smT4M0jLlvCwLoyet)jX)QaM0T83cYya2aGPQHViex8k5cJTvc8EyiyBUvDg5MNFh(3TJHCIvDgdWgamvn8fRufK1MEd4nyRLFL3ymaBaWu1WxeIlELCrRCvZANyvN8iY5ysqU6JbxtAIjsONS7VQdktpQWexyKPkiApMlX0IBsNuUuXzv6Grm9Ne)a)0cHyrkIe5rU5eDePBG3ZtleIpOxPkareamcrNy72XcIaQ2i)iBr815RL2Qw1UD7zpoXkarfM4sHCHT6D7yiZLyAXnPtkxQ4SkDWiM(tI)vb8EybravBKFKTya2aGPQHVD72GTw(vEJXaSbatvdFriU4vYfMUx1QM1oXQo5rKZXKGC1hdUM0etKqS0GvGXk3upPZnMQGONwieHAjQ6GIvlaHXFli3TZjwbiQWexkKlSvpRDIvDYJiNJjb5QpgCnPjMiHGflwsuvPIZYjitvq0tleIqTevDqXQfGW4VfK725eRaevyIlfYf2QN1oXQo5rKZXKGC1hdUM0etKqKojyAq3WVki9fKjzLOI8fXGzQcIEAHqeQLOQdkwTaeg)TGCw7eR6KhrohtcYvFm4AstmrcbrNvLBQG0xqotvq0tleIqTevDqXQfGW4VfKZANyvN8iY5ysqU6JbxtAIjsitpQ0YxRLFvOHeKPki6Pfcris0rICUk0qcg1ynRDIvDYJiNJjb5QpgCnPjMiHe0q5hqSsfe5D6jbzQcIEAHqeQLOQdkwTaeg)TGC3oNyfGOctCPqUWw9SEwV35y4CoMeKVFNtCWgamNB)aFZANyvN8iY5ysqUQHpXejuOjAC8RCaqyzO6H(ctvq0tleIqTevDqXQfGW4VfKa)XNwiez5eDWVQiy83cYD7CIvaIkmXLc5cB1ZANyvN8iY5ysqUQHpXej0cU0qgvDqj1i1x9HOVWzQcICIvaIkmXLc5mGUb(JpTqiYYj6GFvrW4VfKat6w(BbzmaBaWu1WxeIlELCHPBGziNyvNXaSbatvdFXkvbzTP3aEd2A5x5ngdWgamvn8fH4Ixjx0kN1oXQo5rKZXKGCvdFIjsONS7VQdktpQWexyKPkiIfebuTr(r2IbydaMQg(2TBd2A5x5ngdWgamvn8fH4Ixjxy6Ew7eR6KhrohtcYvn8jMiHyPbRaJvUPEsNBmvbrpTqic1su1bfRwacJ)wqc8hFAHqKLt0b)QIGXFli3TZjwbiQWexkKlSvpRDIvDYJiNJjb5Qg(etKqWIfljQQuXz5eKPki6PfcrOwIQoOy1cqy83csG)4tleISCIo4xvem(Bb5UDoXkarfM4sHCHT6zTtSQtEe5Cmjix1WNyIeI0jbtd6g(vbPVGmjRevKVigmtvq0tleIqTevDqXQfGW4VfKa)XNwiez5eDWVQiy83cYzTtSQtEe5Cmjix1WNyIecIoRk3ubPVGCMQGONwieHAjQ6GIvlaHXFlib(JpTqiYYj6GFvrW4VfKZANyvN8iY5ysqUQHpXejKPhvA5R1YVk0qcYufe90cHiej6iroxfAibJASM1oXQo5rKZXKGCvdFIjsibnu(beRubrENEsqMQGONwieHAjQ6GIvlaHXFlib(JpTqiYYj6GFvrW4VfKat6w(BbzmaBaWu1WxeIlELCgq42TZjwbiQWexkKlSvpRN1oXQo5rKZXKGCrexkvoXQovYIBmXnyrmrSXu6lOiKZXKGCvdFmvbrW2CR6mgGnayQA4Bw7eR6KhrohtcYftKqexkvoXQovYIBmXnyrmrSXu6lOiKZXKGC1hdUM0yQcIyiyBUvDgdWgamvn8nRN1oXQo5XLgqCbtt0twPokpzKPkiAPbexW0I)IBEsqHX2kN1oXQo5XLgqCbttmrcveufKnYzQcIEAHqSiOkiBKh)TGCwpR37CGvUjX5aYHBOnR37C6IY03A2CcFqMMJH)681sBUIpNlf4mYNJR3ndH4poNUOm9Zj8bzAog(RZxlT5k(CC9Uzie)ZvH5kBobTM8pNaNB4Cmd9kNtCqebaNJO3HB4C7PIyCob6XCotpo3IVHZXnhA85io3QCBog(RZxlT5euM(5yg6voN4GicaoNtScqCvZ1W5eOhZ5EOSfmNWn3(skIe5ZTNkmhd)15RL2CfFoIZT5eOhZ5m94Cl(goNENpNWj809C7lPisKZ0CLPR85EOziCoRNtJJZz6X5yg6voN4Gicaoxa2lZv2CDoNWx6KYLZbYQ0bxvCw7eR6Kh5vUjrf3887WVOGudczKPkiYCjMweFD(APfX0Fs8dmlicOAJ8JSfXxNVwAaVhgYCjMwCt6KYLkoRshmIP)K4F3UNwielsrKipYnNOddiC7290cH4d6vQcqebaJq0j2QM17DoHV0jLlNdKvPdoxXNZLcCg5ZX17MHq8hN1oXQo5rELBsuXnp)o8lMiHcsniKrMQGiZLyAXnPtkxQ4SkDWiM(tIFGzbravBKFKT4M0jLlvCwLoiWpTqi(GELQaeraWieDInR37C6IY03A2CcFqMMZ0JZT4B4CRyACBodwiFoRNJR3ndHZ585w8KX5ehS52RLgFoNphRMZRNeJZPlkt)CcFqMMZ0JZT4B4CDkzCoUE3meYNtCWMBVwAZz6DBobTM8phlnBotpUmNBZXMWB1ZTVKIiX54Mt0HhNJbzfcietco3dnbiMZX17MHWk3MtCWMBVwAZjOm9ZXMWB1ZTVKIir(CE(NJnHNWn3(skIe5Zv854lUuY0CpnBo2eEREodZpFoRN7HZ9qZq4Cvo3sdX54LP5w1jFU9y6X50xB6r4CcFW5((IVHZvCMMZ0JZT0qCUYMtIEYNZAbo8ZNJnH3QxvCoX1qsLBZX17MHW56CoXbBU9APnxXNJBLuoNphFXLY528kzAoEpxXNlBBoIdRCBo)1A2CIRfxCU9LGZPl5jbNR4ZzDpNa01zoRNtGdHEAZ9rPZyLBZXm0RCoXbreaCoXj1GqgJZANyvN8iVYnjQ4MNFh(ftKqbPgeYitvqelicOAJ8JSfdWMBVwAa)0cH4d6vQcqebaJq0jgW7HHmxIPf3KoPCPIZQ0bJy6pj(3T7PfcXIuejYJCZj6Wac3QM1oXQo5rELBsuXnp)o8lMiHiUuQCIvDQKf3yk9fueY5ysq(S2jw1jpYRCtIkU553HFXejua2aGPQHVz9ENtxuM(5eheraQCBUvWRCop)Z52Cs052CIFoZHBOXzAoMLfaa4W)CjIF(Cwp3dNtJJ)5euM(50xB6r4CSGvdlJX5SEUfxhCoUgeNJXwBoINZfkBUxB6NRsU5PnhZYcaaC4NpxLwpNphVYnjoN4GicqLBZTcELX5anhAvUnNGY0pNPhI4CMd3qJZ0CmllaaWH)5KOdiYNZ0JZjBbZXcwnSmgNlusjcNd2sCop)Zv85044FUoNJ0T83cY52JN)5wX042ClUovUnhxdIZLTnN1ZjW5gohZqVY5eheraW5i6D4gYx1Cckt)CnCobLPV1S5eheraQCBUvWRmoRDIvDYJ8k3KOIBE(D4xmrc9Kfaa4WptvqKtScquHjUuixyIF3oNyfGOctCPqUWydyIZnLvlOOvc8tleIHk3qix1bva2ClcrNymG4N17DoGGmw52CwphRULZr07WnKpxhMtCT4Ml0W58KrtFLBZv8uxT5e0qt)CLfNBfNJZz6XL5C(CMEKX5i9cgN1oXQo5rELBsuXnp)o8lMiHkcQKEsqMQGONwiedvUHqUQdQaS5weIoXM1oXQo5rELBsuXnp)o8lMiHi9cAkU1WLzTtSQtEKx5MevCZZVd)Ijsi815RL2SEVZTcoJZ1H5ehS52CfFono(NZdgcNZLY5exLBiKpxhMtCWMBZr07WnKpNEhqCUhI5CAC8pNN)5m9ieNR4PUAZ5eRaeNtCWgamNB)aFZz6DBosRj)ZTHjcDdNBPHyCoG0x85k(CDkzCoFo(IlLZT5voNV5vYT5w0KwXsIZzoCdnotZ585wbNX56WCId2CBUIN6QnN19C1clNybnzCw7eR6Kh5vUjrf3887WVyIec6mQ6GkaBUXufeXqoXQoJbydaMQg(IvQcYAtVb8gS1YVYBmgGnayQA4lcXfVsUOvoR37CmllaaWH)5k(CAC8pNZNt2cMJfSAyzmoxOKseoNV5vYT5e)CMd3qJhNtxOhZ504vUnN4GicqLBZTcELmnxz6kFoFUf8xAlZT5voN1ZPXX5m94CvYnpT5ywwaaGd)ZHaI5C(Mxj3MZNJx5MeNZC4gAmnhYzHKYLsgNtqz6Nt2cMBX5gczmoRDIvDYJ8k3KOIBE(D4xmrc9Kfaa4WptvqeX5MYQfu0k3TZjwbiQWexkKlm2M17DoHV0jLlNdKvPdoxXNtJJ)5eOhZ5m9ie1v(C(Cmd9kNtCqebaNJfSjZ5eRaeNBpveJZ1PKX5eOhZ5kBoINZ9W546DZqi(xvCoG0x85k(C(C8fxkNZ65wWFPTm3Mx5Cvo3sZT54LP5w1jpoNUulyUfNBiKX5KON85SwGd)8504vUnxzZjqpMZ5a6L0FsmoNUqpMZPXRCBoqwYYSk3MBFj4CE(NtVdyLBZ5zB6r4CMd3qBUeD4JrMMRmDLphxwB6njJZ9qZq4CwpNghNt4doNa9yoNdOxs)jrMMZ5Zz6X54iPZ)CMd3qBUFJ8uxT5EyIHYMla7L546DZqyLBZz6X5w8kNZC4gAXzTtSQtEKx5MevCZZVd)IjsOnPtkxQ4SkDqMQGONwieFqVsvaIiayeIoX2TJfebuTr(r2I4RZxlTD7CIvaIkmXLc5cJnGnxIPf5SKLzvUPkcgX0Fs8pRN1oXQo5rELBsuLTs6jbffKAqiJmvbrMlX0I4RZxlTiM(tIFGzbravBKFKTi(681sd4NwieFqVsvaIiayeIoXM1oXQo5rELBsuLTs6jbftKqbPgeYitvqelicOAJ8JSf3KoPCPIZQ0bb(PfcXh0RufGicagHOtSzTtSQtEKx5MevzRKEsqXejeXLsLtSQtLS4gtPVGIqohtcYN1oXQo5rELBsuLTs6jbftKqbydaMQg(M1oXQo5rELBsuLTs6jbftKqpzbaao8Zufe5eRaevyIlfYfM43TZjwbiQWexkKlm2aMHmxIPf5SKLzvUPkcgX0Fs8pRDIvDYJ8k3KOkBL0tckMiHi9cAkU1WLzTtSQtEKx5MevzRKEsqXeje(681sJPki6PfcXIuejYJCZj6is3aZqpTqi(GELQaeraWieDInRDIvDYJ8k3KOkBL0tckMiHkcQKEsqMQGONwieFqVsvaIiayeIoXaEppTqigQCdHCvhubyZTieDITBhlicOAJ8JSfdsniKXvb8EEAHqSifrI84IV)kU5eDeEpTqiwKIirEKBorNvXGOtSQZya2C71slI7ps0muz1ckMtSQZ4M0jLlvCwLoyK4Ctz1ckMtSQZ4M0jLlvCwLoy0GoGOuz1cYavs80qixfKTaLvlOY6OUJEYiWpTqiUGlnKrvhusns9vFi6l84VfKZANyvN8iVYnjQYwj9KGIjsOnPtkxQ4SkDqMQGONwieFqVsvaIiayeIoX2TJfebuTr(r2I4RZxlTD7mxIPfRK4PHqUkiBbrm9Ne)atCUPSAbfZGoGOuz1ckSkjEAiKRcYwGYQfuzDu3rnwatCUPSAbfZGoGOuz1cYavs80qixfKTaLvlOY6OWf)TGCwpRDIvDYJ8k3KOQHprexkvoXQovYIBmL(ckc5CmjiFw7eR6Kh5vUjrvdFIjsOaSbatvdFZANyvN8iVYnjQA4tmrcfKAqiJmvbrSGiGQnYpYweFD(APb8tleIpOxPkareamcrNyZANyvN8iVYnjQA4tmrc9Kfaa4WptvqKtScquHjUuixyIF3oNyfGOctCPqUWydyIZnLvlOOvoRDIvDYJ8k3KOQHpXejurqL0tcYufe90cHyOYneYvDqfGn3Iq0jgWKUL)wqgdWgamvn8fH4Ixjxy6E3UNwiedvUHqUQdQaS5weIoXej(zTtSQtEKx5Mevn8jMiHEYcaaC4NPkiI4Ctz1ckALZANyvN8iVYnjQA4tmrcfKAqiJmvbrSGiGQnYpYweFD(APnRDIvDYJ8k3KOQHpXejuqQbHmYufe90cH4d6vQcqebaJq0jgW7HfebuTr(r2IbyZTxlTD7(4tleISCIo4xvemcXfVsUWW9hjAgQSAbfZjw1zSiOs6jbJg0beLkRwWvnRDIvDYJ8k3KOQHpXejePxqtXTgUmRDIvDYJ8k3KOQHpXeje(681sBw7eR6Kh5vUjrvdFIjsiOZOQdQaS5gtvq0hFAHqKLt0b)QIGrnwmvPHqOgltvbrpTqigQCdHCvhubyZTieDIjs8mvPHqOgltvll4VCdfX2S2jw1jpYRCtIQg(etKqpzbaao8pRN17DU9nNJ3l4C8Y0CR6KZ0Cm2AZr8CoUE3meo3(sW5yVb0NdbeZ58GHW5Cje9pJZrCUv52CItQbHmoNN)52xcoNUKNemo3(X0JqbfhNZ0x85CIvDoxXNtJJ)5eOhZ5m94Cl(goNENpN4AXnNhmeohX5wLBZjoPgeYitZXrCo)1aIXzTtSQtEKx5MefveuLnGotvqePB5VfKXIGQSb0Jq0)mc8hFAHquqLgc5kI(skJASM1oXQo5rELBsumrcrCPu5eR6ujlUXe3GfXeXgtPVGI4vUjrf3887WptvqeSn3QoJCZZVd)ZANyvN8iVYnjkMiHiUuQCIvDQKf3yIBWIyIyJP0xqr8k3KOkBL0tcYufebBZTQZy2QIGkPNeCw7eR6Kh5vUjrXejeXLsLtSQtLS4gtCdweteBmL(ckIx5Mevn8XufebBZTQZya2aGPQHVzTtSQtEKx5MeftKqfbvzdOpRDIvDYJ8k3KOyIesJJQYWfMsFbfz1h5wdxuK(J7ptvq0tleIfHrfGyL84VfKa)0cHiulrvhuSAbim(Bb5S2jw1jpYRCtIIjsinoQkdxycdbKyQ0xqregjY2GDwe1t6CJPki6PfcXIWOcqSsE83csGFAHqeQLOQdkwTaeg)TGCw7eR6Kh5vUjrXejua2C71sBw7eR6Kh5vUjrXejeXLsLtSQtLS4gtPVGIwAaXfmTzTtSQtEKx5MeftKqfbvspj4SEwV350fLPFoHV0jLlNdKvPdY0CRGwIZ1H5yqBbiCoU(wt(N7HZPXX)CWAtVn3ddneNZ0JZj8LoPC5CGSkDW5i9YRNBpveJZjOm9ZP752xsrKiFop)Z5ZXm0RCoXbreaCvX50f6XCog(RZxlT5k(CDimhPB5VfKmn3kOL4CDyog0wacNJ45CUK3Z9W5044FUvmnUnNGY0pNUNBFjfrI84S2jw1jpAUettbBwIGAjQ6GIvlaHmvbrpTqic1su1bfRwacJ)wqcS5smT4M0jLlvCwLoyet)jXpWpTqiwKIirEKBorhr6g4980cH4d6vQcqebaJq0j2UDMlX0I4RZxlTiM(tIFGjDl)TGmIVoFT0IqCXRKZaeNBkRwWvnR37C6IY03A2CcFPtkxohiRshKP5wbTeNRdZXG2cq4CC9TM8p3dNtJJ)5EyOH4CEY4CVABdHZr6w(Bb5C7HH)681sJP5yy6f0Md0A4ctZTcoJZ1H5ehS52QMRHZjqpMZTcAjoxhMJbTfGW5k(C(R1S5SEoi6e9Zj(5i6D4gYJZANyvN8O5smnfSzjMiHGAjQ6GIvlaHmvbrpTqic1su1bfRwacJ)wqcmdzUetlUjDs5sfNvPdgX0Fs8d8EmxIPfXxNVwArm9Ne)at6w(BbzeFD(APfH4IxjNbio3uwTG72zUetls6f0uCRHlrm9Ne)at6w(BbzK0lOP4wdxIqCXRKZaeNBkRwWD7mxIPfHoJQoOcWMBrm9Ne)at6w(Bbze6mQ6GkaBUfH4IxjNbio3uwTG72r07WnKRcqNyvNUuySfxrRIcYzHek7myHJAuJsb]] )


end
