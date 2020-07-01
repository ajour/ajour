-- MageFire.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'MAGE' then
    local spec = Hekili:NewSpecialization( 63, true )

    -- spec:RegisterResource( Enum.PowerType.ArcaneCharges )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        firestarter = 22456, -- 205026
        pyromaniac = 22459, -- 205020
        searing_touch = 22462, -- 269644

        blazing_soul = 23071, -- 235365
        shimmer = 22443, -- 212653
        blast_wave = 23074, -- 157981

        incanters_flow = 22444, -- 1463
        mirror_image = 22445, -- 55342
        rune_of_power = 22447, -- 116011

        flame_on = 22450, -- 205029
        alexstraszas_fury = 22465, -- 235870
        phoenix_flames = 22468, -- 257541

        frenetic_speed = 22904, -- 236058
        ice_ward = 22448, -- 205036
        ring_of_frost = 22471, -- 113724

        flame_patch = 22451, -- 205037
        conflagration = 23362, -- 205023
        living_bomb = 22472, -- 44457

        kindling = 21631, -- 155148
        pyroclasm = 22220, -- 269650
        meteor = 21633, -- 153561
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3583, -- 208683
        relentless = 3582, -- 196029
        adaptation = 3581, -- 214027

        prismatic_cloak = 828, -- 198064
        dampened_magic = 3524, -- 236788
        greater_pyroblast = 648, -- 203286
        flamecannon = 647, -- 203284
        kleptomania = 3530, -- 198100
        temporal_shield = 56, -- 198111
        netherwind_armor = 53, -- 198062
        tinder = 643, -- 203275
        world_in_flames = 644, -- 203280
        firestarter = 646, -- 203283
        controlled_burn = 645, -- 280450
    } )

    -- Auras
    spec:RegisterAuras( {
        arcane_intellect = {
            id = 1459,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
            shared = "player", -- use anyone's buff on the player, not just player's.
        },
        blast_wave = {
            id = 157981,
            duration = 4,
            max_stack = 1,
        },
        blazing_barrier = {
            id = 235313,
            duration = 60,
            type = "Magic",
            max_stack = 1,
        },
        blink = {
            id = 1953,
        },
        cauterize = {
            id = 86949,
        },
        combustion = {
            id = 190319,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        conflagration = {
            id = 226757,
            duration = 8.413,
            type = "Magic",
            max_stack = 1,
        },
        critical_mass = {
            id = 117216,
        },
        dragons_breath = {
            id = 31661,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        enhanced_pyrotechnics = {
            id = 157642,
            duration = 15,
            type = "Magic",
            max_stack = 10,
        },
        fire_blasting = {
            duration = 0.5,
            max_stack = 1,
            generate = function ()
                local last = action.fire_blast.lastCast
                local fb = buff.fire_blasting

                if query_time - last < 0.5 then
                    fb.count = 1
                    fb.applied = last
                    fb.expires = last + 0.5
                    fb.caster = "player"
                    return
                end

                fb.count = 0
                fb.applied = 0
                fb.expires = 0
                fb.caster = "nobody"
            end,
        },
        flamestrike = {
            id = 2120,
            duration = 8,
            max_stack = 1,
        },
        frenetic_speed = {
            id = 236060,
            duration = 3,
            max_stack = 1,
        },
        frost_nova = {
            id = 122,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        heating_up = {
            id = 48107,
            duration = 10,
            max_stack = 1,
        },
        hot_streak = {
            id = 48108,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        hypothermia = {
            id = 41425,
            duration = 30,
            max_stack = 1,
        },
        ice_block = {
            id = 45438,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        ignite = {
            id = 12654,
            duration = 9,
            type = "Magic",
            max_stack = 1,
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
        living_bomb = {
            id = 217694,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        living_bomb_spread = {
            id = 244813,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        meteor_burn = {
            id = 155158,
            duration = 3600,
            max_stack = 1,
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
        pyroclasm = {
            id = 269651,
            duration = 15,
            max_stack = 2,
        },
        rune_of_power = {
            id = 116014,
            duration = 10,
            max_stack = 1,
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

        -- Azerite Powers
        blaster_master = {
            id = 274598,
            duration = 3,
            max_stack = 3,
        },

        wildfire = {
            id = 288800,
            duration = 10,
            max_stack = 1,
        },
    } )


    spec:RegisterStateTable( "firestarter", setmetatable( {}, {
        __index = setfenv( function( t, k )
            if k == "active" then return talent.firestarter.enabled and target.health.pct > 90
            elseif k == "remains" then
                if not talent.firestarter.enabled or target.health.pct <= 90 then return 0 end
                return target.time_to_pct_90
            end
        end, state )
    } ) )


    spec:RegisterTotem( "rune_of_power", 609815 )


    spec:RegisterHook( "reset_precast", function ()
        if pet.rune_of_power.up then applyBuff( "rune_of_power", pet.rune_of_power.remains )
        else removeBuff( "rune_of_power" ) end

        incanters_flow.reset()
    end )

    spec:RegisterHook( "advance", function ( time )
        if Hekili.ActiveDebug then Hekili:Debug( "\n*** Hot Streak (Advance) ***\n    Heating Up:  %.2f\n    Hot Streak:  %.2f\n", state.buff.heating_up.remains, state.buff.hot_streak.remains ) end
    end )

    spec:RegisterStateFunction( "hot_streak", function( willCrit )
        willCrit = willCrit or buff.combustion.up or stat.crit >= 100

        if Hekili.ActiveDebug then Hekili:Debug( "*** HOT STREAK (Cast/Impact) ***\n    Heating Up: %s, %.2f\n    Hot Streak: %s, %.2f\n    Crit: %s, %.2f", buff.heating_up.up and "Yes" or "No", buff.heating_up.remains, buff.hot_streak.up and "Yes" or "No", buff.hot_streak.remains, willCrit and "Yes" or "No", stat.crit ) end

        if willCrit then
            if buff.heating_up.up then removeBuff( "heating_up" ); applyBuff( "hot_streak" )
            elseif buff.hot_streak.down then applyBuff( "heating_up" ) end
            
            if Hekili.ActiveDebug then Hekili:Debug( "*** HOT STREAK END ***\nHeating Up: %s, %.2f\nHot Streak: %s, %.2f", buff.heating_up.up and "Yes" or "No", buff.heating_up.remains, buff.hot_streak.up and "Yes" or "No", buff.hot_streak.remains ) end
            return true
        end
        
        -- Apparently it's safe to not crit within 0.2 seconds.
        if buff.heating_up.up then
            if query_time - buff.heating_up.applied > 0.2 then
                if Hekili.ActiveDebug then Hekili:Debug( "May not crit; Heating Up was applied %.2f ago, so removing Heating Up..", query_time - buff.heating_up.applied ) end
                removeBuff( "heating_up" )
            else
                if Hekili.ActiveDebug then Hekili:Debug( "May not crit; Heating Up was applied %.2f ago, so ignoring the non-crit impact.", query_time - buff.heating_up.applied ) end
            end
        end

        if Hekili.ActiveDebug then Hekili:Debug( "*** HOT STREAK END ***\nHeating Up: %s, %.2f\nHot Streak: %s, %.2f\n***", buff.heating_up.up and "Yes" or "No", buff.heating_up.remains, buff.hot_streak.up and "Yes" or "No", buff.hot_streak.remains ) end
    end )


    --[[
    spec:RegisterVariable( "combustion_on_use", function ()
        return equipped.manifesto_of_madness or equipped.gladiators_badge or equipped.gladiators_medallion or equipped.ignition_mages_fuse or equipped.tzanes_barkspines or equipped.azurethos_singed_plumage or equipped.ancient_knot_of_wisdom or equipped.shockbiters_fang or equipped.neural_synapse_enhancer or equipped.balefire_branch
    end )

    spec:RegisterVariable( "font_double_on_use", function ()
        return equipped.azsharas_font_of_power and variable.combustion_on_use
    end )

    -- Items that are used outside of Combustion are not used after this time if they would put a trinket used with Combustion on a sharded cooldown.
    spec:RegisterVariable( "on_use_cutoff", function ()
        return 20 * ( ( variable.combustion_on_use and not variable.font_double_on_use ) and 1 or 0 ) + 40 * ( variable.font_double_on_use and 1 or 0 ) + 25 * ( ( equipped.azsharas_font_of_power and not variable.font_double_on_use ) and 1 or 0 ) + 8 * ( ( equipped.manifesto_of_madness and not variable.font_double_on_use ) and 1 or 0 )
    end )

    -- Combustion is only used without Worldvein Resonance or Memory of Lucid Dreams if it will be available at least this many seconds before the essence's cooldown is ready.
    spec:RegisterVariable( "hold_combustion_threshold", function ()
        return 20
    end )

    -- This variable specifies the number of targets at which Hot Streak Flamestrikes outside of Combustion should be used.
    spec:RegisterVariable( "hot_streak_flamestrike", function ()
        if talent.flame_patch.enabled then return 2 end
        return 99
    end )

    -- This variable specifies the number of targets at which Hard Cast Flamestrikes outside of Combustion should be used as filler.
    spec:RegisterVariable( "hard_cast_flamestrike", function ()
        if talent.flame_patch.enabled then return 3 end
        return 99
    end )

    -- Using Flamestrike after Combustion is over can cause a significant amount of damage to be lost due to the overwriting of Ignite that occurs when the Ignite from your primary Combustion target spreads. This variable is used to specify the amount of time in seconds that must pass after Combustion expires before Flamestrikes will be used normally.
    spec:RegisterVariable( "delay_flamestrike", function ()
        return 25
    end )

    -- With Kindling, Combustion's cooldown will be reduced by a random amount, but the number of crits starts very high after activating Combustion and slows down towards the end of Combustion's cooldown. When making decisions in the APL, Combustion's remaining cooldown is reduced by this fraction to account for Kindling.
    spec:RegisterVariable( "kindling_reduction", function ()
        return 0.2
    end )

    spec:RegisterVariable( "time_to_combustion", function ()
        local out = ( talent.firestarter.enabled and 1 or 0 ) * firestarter.remains + ( cooldown.combustion.remains * ( 1 - variable.kindling_reduction * ( talent.kindling.enabled and 1 or 0 ) ) - action.rune_of_power.execute_time * ( talent.rune_of_power.enabled and 1 or 0 ) ) * ( not cooldown.combustion.ready and 1 or 0 ) * ( buff.combustion.down and 1 or 0 )

        if essence.memory_of_lucid_dreams.major and buff.memory_of_lucid_dreams.down and cooldown.memory_of_lucid_dreams.remains - out <= variable.hold_combustion_threshold then
            out = max( out, cooldown.memory_of_lucid_dreams.remains )
        end

        if essence.worldvein_resonance.major and buff.worldvein_resonance.down and cooldown.worldvein_resonance.remains - out <= variable.hold_combustion_threshold then
            out = max( out, cooldown.worldvein_resonance.remains )
        end

        return out
    end )

    spec:RegisterVariable( "fire_blast_pooling", function ()
        return talent.rune_of_power.enabled and cooldown.rune_of_power.remains < cooldown.fire_blast.full_recharge_time and ( variable.time_to_combustion > action.rune_of_power.full_recharge_time ) and ( cooldown.rune_of_power.remains < time_to_die or action.rune_of_power.charges > 0 ) or variable.time_to_combustion < action.fire_blast.full_recharge_time and variable.time_to_combustion < time_to_die
    end )

    spec:RegisterVariable( "phoenix_pooling", function ()
        return talent.rune_of_power.enabled and cooldown.rune_of_power.remains < cooldown.phoenix_flames.full_recharge_time and ( variable.time_to_combustion > action.rune_of_power.full_recharge_time ) and ( cooldown.rune_of_power.remains < time_to_die or action.rune_of_power.charges > 0 ) or variable.time_to_combustion < action.phoenix_flames.full_recharge_time and variable.time_to_combustion < time_to_die
    end ) 
    --]]


    
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


        blast_wave = {
            id = 157981,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 135903,

            talent = "blast_wave",

            usable = function () return target.distance < 8 end,
            handler = function ()
                applyDebuff( "target", "blast_wave" )
            end,
        },


        blazing_barrier = {
            id = 235313,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            defensive = true,

            spend = 0.03,
            spendType = "mana",

            startsCombat = false,
            texture = 132221,

            handler = function ()
                applyBuff( "blazing_barrier" )
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
                if talent.blazing_soul.enabled then applyBuff( "blazing_barrier" ) end
            end,

            copy = { 212653, 1953, "shimmer" }
        },


        combustion = {
            id = 190319,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "off",
            castableWhileCasting = true,

            spend = 0.1,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135824,

            handler = function ()
                applyBuff( "combustion" )
                stat.crit = stat.crit + 100

                if azerite.wildfire.enabled then applyBuff( 'wildfire' ) end
            end,
        },


        --[[ conjure_refreshment = {
            id = 190336,
            cast = 3,
            cooldown = 15,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
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


        dragons_breath = {
            id = 31661,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 134153,

            usable = function () return target.within12 end,
            
            handler = function ()
                hot_streak( talent.alexstraszas_fury.enabled )
                applyDebuff( "target", "dragons_breath" )
            end,

            impact = function ()
                hot_streak( talent.alexstraszas_fury.enabled )
            end,
        },


        fire_blast = {
            id = 108853,
            cast = 0,
            charges = function () return ( talent.flame_on.enabled and 3 or 2 ) end,
            cooldown = function () return ( talent.flame_on.enabled and 10 or 12 ) * ( buff.memory_of_lucid_dreams.up and 0.5 or 1 ) * haste end,
            recharge = function () return ( talent.flame_on.enabled and 10 or 12 ) * ( buff.memory_of_lucid_dreams.up and 0.5 or 1 ) * haste end,
            gcd = "off",
            castableWhileCasting = true,

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135807,

            nobuff = "fire_blasting", -- horrible.

            --[[ readyTime = function ()
                if settings.no_scorch_blast and action.scorch.executing and ( ( talent.searing_touch.enabled and target.health_pct < 30 ) or ( buff.combustion.up and buff.combustion.remains >= buff.casting.remains ) ) then
                    return buff.casting.remains
                end
            end, ]]

            usable = function ()
                if time == 0 then return false, "no fire_blast out of combat" end
            end,

            handler = function ()
                hot_streak( true )

                if talent.kindling.enabled then setCooldown( "combustion", max( 0, cooldown.combustion.remains - 1 ) ) end
                if azerite.blaster_master.enabled then addStack( "blaster_master", nil, 1 ) end

                applyBuff( "fire_blasting" ) -- Causes 1 second ICD on Fire Blast; addon only.
            end,
        },


        fireball = {
            id = 133,
            cast = 2.25,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135812,

            velocity = 45,
            usable = function ()
                if moving and settings.prevent_hardcasts then return false, "prevent_hardcasts is checked and player is moving" end
                return true
            end,

            handler = function ()
                if talent.kindling.enabled and firestarter.active or stat.crit + buff.enhanced_pyrotechnics.stack * 10 >= 100 then
                    setCooldown( "combustion", max( 0, cooldown.combustion.remains - 1 ) )
                end
            end,

            impact = function ()
                if hot_streak( firestarter.active or stat.crit + buff.enhanced_pyrotechnics.stack * 10 >= 100 ) then
                    removeBuff( "enhanced_pyrotechnics" )
                else
                    addStack( "enhanced_pyrotechnics", nil, 1 )
                end

                applyDebuff( "target", "ignite" )
                if talent.conflagration.enabled then applyDebuff( "target", "conflagration" ) end
            end,
        },


        flamestrike = {
            id = 2120,
            cast = function () return buff.hot_streak.up and 0 or 4 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135826,

            handler = function ()
                if not hardcast then removeBuff( "hot_streak" ) end
                applyDebuff( "target", "ignite" )
                applyDebuff( "target", "flamestrike" )
            end,
        },


        frost_nova = {
            id = 122,
            cast = 0,
            charges = function () return talent.ice_ward.enabled and 2 or nil end,
            cooldown = 30,
            recharge = 30,
            gcd = "spell",

            defensive = true,

            spend = 0.02,
            spendType = "mana",

            startsCombat = false,
            texture = 135848,

            handler = function ()
                applyDebuff( "target", "frost_nova" )
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


        living_bomb = {
            id = 44457,
            cast = 0,
            cooldown = 12,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 236220,

            handler = function ()
                applyDebuff( "target", "living_bomb" )
            end,
        },


        meteor = {
            id = 153561,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 1033911,

            flightTime = 1,

            --[[ handler = function ()
                applyDebuff( "target", "meteor_burn" )
            end, ]]

            impact = function ()
                applyDebuff( "target", "meteor_burn" )
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


        phoenix_flames = {
            id = 257541,
            cast = 0,
            charges = 3,
            cooldown = 30,
            recharge = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 1392549,

            talent = "phoenix_flames",

            velocity = 50,

            handler = function ()
                if talent.kindling.enabled then setCooldown( "combustion", max( 0, cooldown.combustion.remains - 1 ) ) end
            end,

            impact = function ()
                hot_streak( true )
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


        pyroblast = {
            id = 11366,
            cast = function () return buff.hot_streak.up and 0 or 4.5 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 135808,

            usable = function ()
                if action.pyroblast.cast > 0 then
                    if moving and settings.prevent_hardcasts then return false, "prevent_hardcasts is checked and player is moving" end
                    if combat == 0 and not boss and not settings.pyroblast_pull then return false, "opener pyroblast disabled and/or target is not a boss" end
                end
                return true
            end,

            handler = function ()
                if hardcast then removeStack( "pyroclasm" )
                else removeBuff( "hot_streak" ) end
            end,

            velocity = 35,

            impact = function ()
                if hot_streak( firestarter.active ) then
                    if talent.kindling.enabled then setCooldown( "combustion", max( 0, cooldown.combustion.remains - 1 ) ) end
                end
                applyDebuff( "target", "ignite" )
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

            usable = function ()
                if settings.save_2_runes then
                    local combustime = max( variable.time_to_combustion, cooldown.combustion.remains )
                    if combustime > 0 and ( charges <= 1 or cooldown.combustion.true_remains < action.rune_of_power.recharge ) then return false, "saving rune_of_power charges for combustion" end
                end
                return true
            end,

            handler = function ()
                applyBuff( "rune_of_power" )
            end,
        },


        scorch = {
            id = 2948,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135827,

            handler = function ()
                if talent.frenetic_speed.enabled then applyBuff( "frenetic_speed" ) end
                hot_streak( talent.searing_touch.enabled and target.health_pct < 30 )
                applyDebuff( "target", "ignite" )
            end,
        },


        slow_fall = {
            id = 130,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
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
        gcdSync = false,
        -- canCastWhileCasting = true,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "superior_battle_potion_of_intellect",

        package = "Fire",
    } )


    spec:RegisterSetting( "pyroblast_pull", false, {
        name = "Allow |T135808:0|t Pyroblast Hardcast Pre-Pull",
        desc = "If checked, the addon will recommend an opener |T135808:0|t Pyroblast against bosses, if included in the current priority.",
        type = "toggle",
        width = 3,
    } )
    
    spec:RegisterSetting( "prevent_hardcasts", false, {
        name = "Prevent |T135808:0|t Pyroblast and |T135812:0|t Fireball Hardcasts While Moving",
        desc = "If checked, the addon will not recommend |T135808:0|t Pyroblast or |T135812:0|t Fireball if they have a cast time and you are moving.\n\n" ..
            "Instant |T135808:0|t Pyroblasts will not be affected.",
        type = "toggle",
        width = 3
    } )

    --[[ spec:RegisterSetting( "no_scorch_blast", true, {
        name = "Prevent |T135807:0|t Fire Blast During Critical |T135827:0|t Scorch Casts",
        desc = "If checked, the addon will not recommend |T135827:0|t Fire Blast during any of your |T135827:0|t Scorch casts that are expected to critically strike.\n\n" ..
            "This will override the priority's logic that allows for some interwoven Blaster Master refreshes that tend to confuse users.",
        type = "toggle",
        width = 3
    } ) ]]

    spec:RegisterSetting( "save_2_runes", true, {
        name = "Reserve |T609815:0|t Rune of Power Charges for Combustion",
        desc = "While |T609815:0|t Rune of Power is not considered a Cooldown by default, saving 2 charges to line up with |T135824:0|t Combustion is generally a good idea.\n\n" ..
            "The addon will reserve this many charges to line up with |T135824:0|t Combustion, regardless of whether Cooldowns are toggled on/off.",
        type = "toggle",
        width = 3
    } )



    spec:RegisterPack( "Fire", 20200525, [[d8uXPcqiiIhrvqxsPOeBse(KivKrjI6uIeRcIeVsPuZcs6wqIAxe9lLkgMsLoMiPLPuKNrvitJQq5AIu12GijFtPOOXbrsDoQcvRtPOQEhvbQmpLQ6EqQ9PuLdsvaAHkfEiePmrLIQCrLIsAJqKQpsvaOrQuu5KkffwjvrVKQavntrQOUPivyNIu(jvbqdvPOulLQaGNIQMQsjxLQa6RufOSxr9xugmuhMYIv4XeMmQCzKnlLpdHrtvDAHvtvG8ArKztLBRODRYVLmCPYXfPslh45GMoPRRKTtv67svnEiHZdrTEirMVuL9RQZPM3kZZzkLtBt7UPD3n9Bk9YutDtECpw6Z8kYDuMVZejziOm)ztkZJ0daL57mKDLXL3kZdRfqqzEFv7GB(7SdIq9xdPOM7aJ5YzAuNaynDhymf7K5hRWPBgxEK55mLYPTPD30U7M(nLEzQPUjpUhBtzEBP(fiZZhtKwM3p44OlpY8CeuK59WhJ0da940HHGEp9Wh7RAhCZFNDqeQ)Aif1ChymxotJ6eaRP7aJPyN3tp8XPdd5hVP0J6J30UBA33Z3tp8XinF7qqWn)3tp8XO8J9aH0J1ysmTyCb9yGP(e4XQVDpwnacsLAmjMwmUGECRap2zqfLHKOoUhBJWfkYpEbneeu(E6HpgLFShyhNP0JDfIq8yaT5)405Li4E8MhGSju(E6HpgLFC6Cvq6ESWG6Jbu6UcanPtHpUvGhJ0Q5yb1OUhNCijjQpMRU0j9X(LJ7XH(4wbES94gGG(poDqkvGhlmOMI890dFmk)4nVaAdh9y7EmDka5hR(M(4(1YX9yabxo9XX9y7X(gGtyq9XB2idQHZG6JJdLryts(E6HpgLF8M1Zgo6Xqfec9XcFsKuCiECDp2ECJ6)4wbsc(44ES6tp2d4MD68J16XaIBjOh3Vaj5kJtM5DbuH5TY8HstiZv9zDGOaHICERCAPM3kZtNnCexEJmVj0OUmVgCeulWKjkocfzEbiucewM3RbcB4iPgtIPftuZXcQrDpEVh71aHnCKSo2csmXsRwlZF2KY8AWrqTatMO4iuK1CABkVvMNoB4iU8gzEtOrDzEbYcxPG6cbB4mOM5fGqjqyzEVgiSHJKAmjMwmrnhlOg1949ESxde2WrY6yliXelTATmp1AKqzNnPmVazHRuqDHGnCguZAwZ8IAowqnQJ15BqkVvoTuZBL5PZgoIlVrMxacLaHL5hRwtkQ5yb1Oojx1)Y8MqJ6Y8UaHVczEqloet60SMtBt5TY80zdhXL3iZlaHsGWY8JvRjf1CSGAuNKR6FzEtOrDz(HHGvnMccrsWSMtZJYBL5PZgoIlVrMxacLaHL5nHgEjgD0mi4J37XP(4epESAnPOMJfuJ6KCv)lZBcnQlZ7cVXHGnQ5iR508y5TY8MqJ6Y8dxvCSQXuFIrhnroZtNnCexEJSMtl95TY8MqJ6Y8tAwaKzvJ5wIGJXbiBcZ80zdhXL3iR50qQYBL5nHg1L57xahNxkogGG1zNGY80zdhXL3iR502mZBL5PZgoIlVrMFbjwF)WrmHb14qKtl1mVaekbclZl8nacc(49q)4uFCIhN8Jt(XMqJ6KTaqSHZGQu4BaeeK1aMqJ6m3J3(Xj)4XQ1KIAowqnQtcOPfh8XO8JhRwtoCgujaBAqLasUfW0OUhNYJ3S8yrvoUQ)jBbGydNbvj3cyAu3Jr5hN8JhRwtkQ5yb1OojGMwCWhNYJ3S84KF8y1AYHZGkbytdQeqYTaMg19yu(X7kt)Jt5XP849q)4DFCVEpgjp2qjcekjhodQeGnnOsajD2WrCpUxVhJKhRMJov2C2Ky1jPZgoI7X9694XQ1KIAowqnQtcOPfh8X7J(XJvRjhodQeGnnOsaj3cyAu3J717XJvRjhodQeGnnOsajGMwCWhV)J3vM(h3R3JP0DfDDeN0h5ocO(aY4y9bbu7dSo4Jt8yrvoUQ)j9rUJaQpGmowFqa1(aRdY8OD3nvp2MKaAAXbF8(po9poLhN4XJvRjf1CSGAuNC194epo5hJKhBcnQtcffq4ljuqILghIhN4Xi5XMqJ6KDidQHZGQmowZfi81hN4XJvRj9jtJdbB1jxDpUxVhBcnQtcffq4ljuqILghIhN4XJvRj9lLbvazjj5Q(3Jt84KF8y1AsFY04qWwDsUQ)94E9ESHseiusoCgujaBAqLas6SHJ4ECkpUxVhBOebcLKdNbvcWMgujGKoB4iUhN4XQ5OtLnNnjwDs6SHJ4ECIhBcnQt2HmOgodQY4ynxGWxFCIhpwTM0NmnoeSvNKR6FpoXJhRwt6xkdQaYssYv9VhNsMFbjw1AmecUCAPM5nHg1L5BbGydNb1SMtdPoVvMNoB4iU8gzEbiucewMFSAnjyDeRASUQpbKCv)7XjE8y1AsrnhlOg1j5Q(xM3eAuxMhSoIvnwx1NaznNMhpVvMNoB4iU8gz(fKy99dhXeguJdroTuZ8MqJ6Y8TaqSHZGAMxacLaHL5nuIaHsYHZGkbytdQeqsNnCe3Jt84KFmbH0ji5KMfazw1yULi4yCaYMq508GkWJ717Xi5XeesNGKtAwaKzvJ5wIGJXbiBcLZ4kWJt5XjESAo6u5KuQas6SHJ4ECIhRMJov2C2Ky1jPZgoI7XjE8y1AYHZGkbytdQeqYv9VhN4Xj)y1C0PsW6iw1yDvFciPZgoI7XjESj0OojyDeRASUQpbKekiXsJdXJt8ytOrDsW6iw1yDvFcijuqILsmanT4GpE)hVReP6X9694KFSxde2WrsnMetlMOMJfuJ6E8(OF8UpUxVhpwTMuuZXcQrDYv3Jt5XjEmsESAo6ujyDeRASUQpbK0zdhX94epgjp2eAuNSdzqnCguLXXAUaHV(4epgjp2eAuNSfaAyoNmowZfi81hNswZPL6U5TY80zdhXL3iZBcnQlZlmNJzcnQJ5cOM5DbuzNnPmVj0WlXuZrNcZAoTutnVvMNoB4iU8gz(fKy99dhXeguJdroTuZ8cqOeiSmFYpo5hBcnQtojLkGmowZfi81hN4XMqJ6KtsPciJJ1CbcFLbOPfh8X7J(X7kt)Jt5X969ytOrDYjPubKXXAUaHV(4E9EmbH0ji5KMfazw1yULi4yCaYMq508GkWJ717XJvRj9lLbvazjjbKj0h3R3JnHg1jHIci8LekiXsJdXJt8ytOrDsOOacFjHcsSuIbOPfh8X7)4DLP)X969ytOrDYoKb1WzqvsOGelnoepoXJnHg1j7qgudNbvjHcsSuIbOPfh8X7)4DLP)XP84epo5hpwTMeSoIvnwx1NaYv3J717Xi5XQ5OtLG1rSQX6Q(eqsNnCe3JtjZVGeRAngcbxoTuZ8MqJ6Y8IAowqnQlR50sDt5TY8MqJ6Y8DLg1L5PZgoIlVrwZPLQhL3kZBcnQlZpCvXXAlaYzE6SHJ4YBK1CAP6XYBL5nHg1L5heasGKIdrMNoB4iU8gznNwQPpVvM3eAuxMVfaA4QIlZtNnCexEJSMtlvKQ8wzEtOrDzE7eeubMJjmNlZtNnCexEJSMtl1nZ8wzE6SHJ4YBK5fGqjqyz(KFCYpwnhDQS5SjX6mv4lPZgoI7XjESj0WlXOJMbbF8EpEtpoLh3R3JnHgEjgD0mi4J37XivpoLhN4XJvRj9lLbvazjjbKj0hN4Xi5XgkrGqj5WzqLaSPbvciPZgoIlZBcnQlZ3C2KGkisIYAoTurQZBL5PZgoIlVrMxacLaHL5hRwt2HmOeodoLaYe6Jt84XQ1KIAowqnQtcOPfh8X79yHbvMgtkZBcnQlZ3HmOgodQznNwQE88wzE6SHJ4YBK5fGqjqyz(XQ1K(LYGkGSKKaYeAM3eAuxMVdzqnCguZAoTnTBERmVj0OUmFNFrxGcwZztcM5PZgoIlVrwZPTPuZBL5PZgoIlVrMxacLaHL5hRwtkQ5yb1OojGMwCWhV3JfguzAmPhN4XJvRjf1CSGAuNC194E9E8y1AsrnhlOg1j5Q(3Jt8yrvoUQ)jf1CSGAuNeqtlo4J3)XcdQmnMuM3eAuxMhkkGWpR5020MYBL5PZgoIlVrMxacLaHL5hRwtkQ5yb1OojGMwCWhV)Jri4KtdfpoXJnHgEjgD0mi4J37XPM5nHg1L5DH34qWg1CK1CABYJYBL5PZgoIlVrMxacLaHL5hRwtkQ5yb1OojGMwCWhV)Jri4KtdfpoXJhRwtkQ5yb1Oo5QlZBcnQlZZbme1bzdazQFwZPTjpwERmpD2WrC5nY8cqOeiSmVAaeKk9jZP(YoH(49r)ypA3hN4XQ5OtLqYaXHGP1s4lPZgoIlZBcnQlZdffq4N1SM5nHgEjMAo6uyERCAPM3kZtNnCexEJmVaekbclZBcn8sm6OzqWhV3Jt9XjE8y1AsrnhlOg1j5Q(3Jt84KFSxde2WrsnMetlMOMJfuJ6E8EpwuLJR6Fsx4noeSrnhsUfW0OUh3R3J9AGWgosQXKyAXe1CSGAu3J3h9J39XPK5nHg1L5DH34qWg1CK1CABkVvMNoB4iU8gzEbiucewM3RbcB4iPgtIPftuZXcQrDpEF0pE3h3R3Jt(XJvRjbRJyvJ1v9jGC194E9ESOkhx1)KG1rSQX6Q(eqcOPfh8X79ynMetlgxqpoXJnHg1jbRJyvJ1v9jGu4Baee8X7)4uFCVEpgjpwnhDQeSoIvnwx1Nas6SHJ4ECkpoXJt(XIQCCv)tojLkGKBbmnQ7X7)yVgiSHJKAmjMwmrnhlOg194E9ESgtIPfJlOhV)J9AGWgosQXKyAXe1CSGAu3JtjZBcnQlZpjLkqwZP5r5TY80zdhXL3iZlaHsGWY8Q5OtLMJqbubgeLmiRTailPZgoI7XjECYpESAnPOMJfuJ6KCv)7XjEmsE8y1As)szqfqwssazc9X9694XQ1KIAowqnQtU6ECIhBcnQt2caXgodQsHVbqqWhV)JnHg1jBbGydNbv50qbt4Baee8XjEmsE8y1As)szqfqwssazc9XPK5nHg1L55agI6GSbGm1pRznZhknHm)aHpRdefiuKZBLtl18wzE6SHJ4YBK5fGqjqyzEVgiSHJKAmjMwmrnhlOg1949r)4DZ8MqJ6Y8cZ5yMqJ6yUaQzExav2ztkZhknHmrnhlOg1L1CABkVvM3eAuxMFbjwO0eM5PZgoIlVrwZP5r5TY80zdhXL3iZBcnQlZpTlAeulw1ytJ7iimZlaHsGWY8i5Xu6UIUoItAOe03agK1QtzvJ1v9jWJt8yVgiSHJKAmjMwmrnhlOg1949FmsDM)SjL5N2fncQfRASPXDeeM1CAES8wzE6SHJ4YBK5nHg1L5nuc6BadYA1PSQX6Q(eiZlaHsGWY8Enqydhj1ysmTyIAowqnQ7X7J(XP)XB)4ut)Jrkp2RbcB4izRoLXvRHJy1XwqkZF2KY8gkb9nGbzT6uw1yDvFcK1CAPpVvMNoB4iU8gzEtOrDzEqPcWcQehZBvCvX4kNlZlaHsGWY8Enqydhj1ysmTyIAowqnQ7X79yVgiSHJK1XwqIjwA1Az(ZMuMhuQaSGkXX8wfxvmUY5YAonKQ8wzE6SHJ4YBK5nHg1L5T0DfDLsNYoBPHBbZ8cqOeiSmVxde2WrsnMetlMOMJfuJ6E8Ep2RbcB4izDSfKyILwTwM)SjL5T0DfDLsNYoBPHBbZAoTnZ8wzE6SHJ4YBK5nHg1L5H(HxcW8sxnzaYfImVaekbclZ71aHnCKuJjX0IjQ5yb1OUhV3J9AGWgoswhBbjMyPvRL5pBszEOF4LamV0vtgGCHiR50qQZBL5PZgoIlVrM3eAuxMVvGrWXrhRgWGlSJjCw)mVaekbclZ71aHnCKuJjX0IjQ5yb1OUhV3J9AGWgoswhBbjMyPvRL5pBsz(wbgbhhDSAadUWoMWz9ZAonpEERmpD2WrC5nY8MqJ6Y8(gywxiyC00uceMlqjcK5PwJek7SjL59nWSUqW4OPPeimxGseiR50sD38wzE6SHJ4YBK5nHg1L5NMRvGjXX8jG54GmhHOpW6GzEbiucewM3RbcB4iPgtIPftuZXcQrDpEp0po9P)XjE8y1AsrnhlOg1j5Q(3Jt8yVgiSHJKAmjMwmrnhlOg1949ESxde2WrY6yliXelTATm)ztkZpnxRatIJ5taZXbzocrFG1bZAoTutnVvMNoB4iU8gzEtOrDzE7ebDklPRuw1y9dixnZ8cqOeiSmVxde2WrsnMetlMOMJfuJ6E8EOFC6t)Jt84XQ1KIAowqnQtYv9VhN4XEnqydhj1ysmTyIAowqnQ7X79yVgiSHJK1XwqIjwA1Az(ZMuM3orqNYs6kLvnw)aYvZSMtl1nL3kZtNnCexEJmVj0OUm)rlG5yqKpRdsm68TtqGmVaekbclZ71aHnCKuJjX0IjQ5yb1OUhVh6h7Xs)Jt84XQ1KIAowqnQtYv9VhN4XEnqydhj1ysmTyIAowqnQ7X79yVgiSHJK1XwqIjwA1Az(ZMuM)OfWCmiYN1bjgD(2jiqwZAMNJA2YP5TYPLAERmVj0OUmVOwNsayh5CzE6SHJ4YBK1CABkVvMNoB4iU8gz(QlZdjnZBcnQlZ71aHnCuM3R5wuMxnhDQSfacQgqjGKoB4iUhJuEClaeunGsajGMwCWhV9Jt(XIQCCv)tkQ5yb1OojGMwCWhJuECYpo1hJYp2RbcB4izsXX5IdbdqClHg19yKYJvZrNktkooxCiK0zdhX94uEmk)ytOrDsW6iw1yDvFcijuqILsmnM0JrkpwnhDQeSoIvnwx1Nas6SHJ4ECkpgP8yK8yrvoUQ)jf1CSGAuNeqghYpgP84XQ1KIAowqnQtYv9VmVxdWoBszEnMetlMOMJfuJ6YAonpkVvMNoB4iU8gz(QlZpnuK5nHg1L59AGWgokZ71ClkZlQYXv9p5KMfazw1yULi4yCaYMqjGMwCWmVaekbclZtqiDcsoPzbqMvnMBjcoghGSjuonpOc84epESAn5KMfazw1yULi4yCaYMqjx1)ECIhlQYXv9p5KMfazw1yULi4yCaYMqjGMwCWhJYp2RbcB4iPgtIPftuZXcQrDpEF0p2RbcB4iPF54yIAowqnQJP(ac6xoUmVxdWoBszEnMetlMOMJfuJ6YAonpwERmpD2WrC5nY8vxMFAOiZBcnQlZ71aHnCuM3R5wuMxuLJR6FY(fWX5LIJbiyD2jijGMwCWmVaekbclZtqiDcs2VaooVuCmabRZobjNMhubECIhpwTMSFbCCEP4yacwNDcsYv9VhN4XIQCCv)t2VaooVuCmabRZobjb00Id(yu(XEnqydhj1ysmTyIAowqnQ7X7J(XEnqydhj9lhhtuZXcQrDm1hqq)YXL59Aa2ztkZRXKyAXe1CSGAuxwZPL(8wzE6SHJ4YBK5nHg1L5fMZXmHg1XCbuZ8UaQSZMuMpuAcz(bcFwhikqOiN1CAiv5TY80zdhXL3iZlaHsGWY8JvRjf1CSGAuNKR6FzEtOrDz(zaafGftdbL1CABM5TY80zdhXL3iZlaHsGWY8j)yVgiSHJKAmjMwmrnhlOg1949FCQ7(4E9ESgtIPfJlOhV)J9AGWgosQXKyAXe1CSGAu3JtjZBcnQlZJyzaUWow1ygkrGs9ZAonK68wzEtOrDzErDc6uGPehR5SjL5PZgoIlVrwZP5XZBL5nHg1L5bK1fhcwZztcM5PZgoIlVrwZPL6U5TY8MqJ6Y8TsSGehZqjcekXgKnZ80zdhXL3iR50sn18wzEtOrDz(UfiAihhc2WzqnZtNnCexEJSMtl1nL3kZBcnQlZdIUohXIJb7mbL5PZgoIlVrwZPLQhL3kZBcnQlZR(eBDJADCSwbeuMNoB4iU8gznNwQES8wzE6SHJ4YBK5fGqjqyz(XQ1KG1rSQX6Q(eqYv9VhN4XJvRjf1CSGAuNKR6FpoXJt(XEnqydhj1ysmTyIAowqnQ7X7942Y5yas4BaeetJj94E9ESxde2WrsnMetlMOMJfuJ6E8EpwnacsLAmjMwmUGECkzEtOrDzEW6iw1yDvFcK1CAPM(8wzE6SHJ4YBK5fGqjqyzEVgiSHJKAmjMwmrnhlOg1949r)4DZ8MqJ6Y8cZ5yMqJ6yUaQzExav2ztkZlQ5yb1OowNVbPSMtlvKQ8wzE6SHJ4YBK5xqI13pCetyqnoe50snZlaHsGWY8j)yccPtqYjnlaYSQXClrWX4aKnHYP5bvGh3R3JjiKobjN0SaiZQgZTebhJdq2ekNXvGhN4XgkrGqj5WzqLaSPbvciPZgoI7XP84epw4Baee8XOF80qbt4Baee8XjEmsE8y1As)szqfqwssazc9XjEmsECYpESAnPpzACiyRojGmH(4epo5hpwTMuuZXcQrDYv3Jt84KFSj0Oozla0WCozCSMlq4RpUxVhBcnQt2HmOgodQY4ynxGWxFCVEp2eAuNekkGWxsOGelnoepoLh3R3JvdGGuPpzo1x2j0hVp6h7r7(4ep2eAuNekkGWxsOGelnoepoLhNYJt8yK84KFmsE8y1AsFY04qWwDsazc9XjEmsE8y1As)szqfqwssazc9XjE8y1AsrnhlOg1j5Q(3Jt84KFSj0Oozla0WCozCSMlq4RpUxVhBcnQt2HmOgodQY4ynxGWxFCkpoLm)csSQ1yieC50snZBcnQlZ3caXgodQznNwQBM5TY80zdhXL3iZxDzEiPzEtOrDzEVgiSHJY8En3IY8Q5OtLG1rSQX6Q(eqsNnCe3Jt8yrvoUQ)jbRJyvJ1v9jGeqtlo4J3)XIQCCv)t2caXgodQY2Y5yas4BaeetJj94epo5h71aHnCKuJjX0IjQ5yb1OUhV3JnHg1jbRJyvJ1v9jGSTCogGe(gabX0yspoLhN4Xj)yrvoUQ)jbRJyvJ1v9jGeqtlo4J3)XAmjMwmUGECVEp2eAuNeSoIvnwx1NasHVbqqWhV3J39XP84E9ESxde2WrsnMetlMOMJfuJ6E8(p2eAuNSfaInCguLTLZXaKW3aiiMgt6XjESxde2WrsnMetlMOMJfuJ6E8(pwJjX0IXfuM3RbyNnPmFlaeB4mOY6QYfhISMtlvK68wzE6SHJ4YBK5fGqjqyz(XQ1KG1rSQX6Q(eqU6ECIhN8J9AGWgosQXKyAXe1CSGAu3J37X7(4uY8qfecnNwQzEtOrDzEH5CmtOrDmxa1mVlGk7SjL5bvhRZ3GuwZPLQhpVvMNoB4iU8gz(QlZdjnZBcnQlZ71aHnCuM3R5wuMxnhDQeSoIvnwx1Nas6SHJ4ECIhlQYXv9pjyDeRASUQpbKaAAXbF8(pwuLJR6FYo)IUafSMZMeu2wohdqcFdGGyAmPhN4Xj)yVgiSHJKAmjMwmrnhlOg1949ESj0OojyDeRASUQpbKTLZXaKW3aiiMgt6XP84epo5hlQYXv9pjyDeRASUQpbKaAAXbF8(pwJjX0IXf0J717XMqJ6KG1rSQX6Q(eqk8nacc(49E8UpoLh3R3J9AGWgosQXKyAXe1CSGAu3J3)XMqJ6KD(fDbkynNnjOSTCogGe(gabX0yspoXJ9AGWgosQXKyAXe1CSGAu3J3)XAmjMwmUGY8Ena7SjL578l6cuW6QYfhISMtBt7M3kZtNnCexEJm)csS((HJycdQXHiNwQzEbiucewMp5hJKh71aHnCKSfaInCguzDv5IdXJ717XJvRjbRJyvJ1v9jGC194uECIhN8J9AGWgosQXKyAXe1CSGAu3J37X7(4uECIhN8JnHgEjgD0mi4J3d9J9AGWgos6BaoMWGkR5SjbvqKe94epo5hRXKEmk)4XQ1KIAowqnQt6mOYiu0fa6X79yVgiSHJKCKZqM1C2KGkisIECkpoLhN4Xi5XTaqq1akbKMqdV0Jt84XQ1K(LYGkGSKKCv)7XjECYpgjp2qjcekjhodQeGnnOsajD2WrCpUxVhpwTMC4mOsa20GkbKaAAXbF8(pExz6FCkz(fKyvRXqi4YPLAM3eAuxMVfaInCguZAoTnLAERmpD2WrC5nY8liX67hoIjmOghICAPM5fGqjqyz(waiOAaLastOHx6XjESW3aii4J3d9Jt9XjECYpgjp2RbcB4izlaeB4mOY6QYfhIh3R3JhRwtcwhXQgRR6ta5Q7XP84epo5hJKhBOebcLKdNbvcWMgujGKoB4iUh3R3JhRwtoCgujaBAqLasanT4GpE)hVRm9poLhN4Xj)yK8ytOrDYwaOH5CscfKyPXH4XjEmsESj0OozhYGA4mOkJJ1CbcF9XjE8y1AsFY04qWwDYv3J717XMqJ6KTaqdZ5KekiXsJdXJt84XQ1K(LYGkGSKKCv)7X969ytOrDYoKb1WzqvghR5ce(6Jt84XQ1K(KPXHGT6KCv)7XjE8y1As)szqfqwssUQ)94uY8liXQwJHqWLtl1mVj0OUmFlaeB4mOM1CABAt5TY80zdhXL3iZlaHsGWY8Enqydhj1ysmTyIAowqnQ7X794DZ8qfecnNwQzEtOrDzEH5CmtOrDmxa1mVlGk7SjL5HQDCgGJbk10OUSM1mFO0eYe1CSGAuxERCAPM3kZtNnCexEJm)ztkZhiUqJ6ytdbbzTfKY8MqJ6Y8bIl0Oo20qqqwBbPSMtBt5TY80zdhXL3iZBcnQlZ7JChbuFazCS(GaQ9bwhmZlaHsGWY8JvRjf1CSGAuNC194ep2eAuNSfaInCguLcFdGGGpg9J39XjESj0OozlaeB4mOkbKW3aiiMgt6X79yeco50qrM)SjL59rUJaQpGmowFqa1(aRdM1CAEuERmpD2WrC5nY8NnPm)0UOrqTyvJnnUJGWmVj0OUm)0UOrqTyvJnnUJGWSMtZJL3kZpwTg7SjL5N2fncQfRASPXDeeYe(wNsawDuMxacLaHL5hRwtkQ5yb1Oo5Q7X969ytOrDYjPubKXXAUaHV(4ep2eAuNCskvazCSMlq4RmanT4GpEF0pExz6Z8liXQwJHqWLtl1mVj0OUmVWob5yJvRL5PZgoIlVrwZPL(8wzE6SHJ4YBK5pBszEdLwas9lidghcIJ15wtdbL5xqIvTgdHGlNwQzEtOrDzEdLwas9lidghcIJ15wtdbL5fGqjqyz(XQ1KIAowqnQtU6ECVEp2eAuNCskvazCSMlq4RpoXJnHg1jNKsfqghR5ce(kdqtlo4J3h9J3vM(SMtdPkVvMNoB4iU8gzEtOrDzEeoJlmTaq2W4qqz(fKyvRXqi4YPLAMxacLaHL5hRwtkQ5yb1Oo5Q7X969ytOrDYjPubKXXAUaHV(4ep2eAuNCskvazCSMlq4RmanT4GpEF0pExz6Z8uRrcLD2KY8iCgxyAbGSHXHGYAoTnZ8wzE6SHJ4YBK5nHg1L5r4mUW0caztIZCUOUm)csSQ1yieC50snZlaHsGWY8JvRjf1CSGAuNC194E9ESj0Oo5KuQaY4ynxGWxFCIhBcnQtojLkGmowZfi8vgGMwCWhVp6hVRm9zEQ1iHYoBszEeoJlmTaq2K4mNlQlR50qQZBL5PZgoIlVrM)SjL5hMJAbGydGDc)m)csSQ1yieC50snZBcnQlZpmh1caXga7e(zEbiucewMFSAnPOMJfuJ6KRUh3R3JnHg1jNKsfqghR5ce(6Jt8ytOrDYjPubKXXAUaHVYa00Id(49r)4DLPpR50845TY80zdhXL3iZF2KY8q)sK0iucazn7qK5xqIvTgdHGlNwQzEtOrDzEOFjsAekbGSMDiY8cqOeiSm)y1AsrnhlOg1jxDpUxVhBcnQtojLkGmowZfi81hN4XMqJ6KtsPciJJ1CbcFLbOPfh8X7J(X7ktFwZPL6U5TY80zdhXL3iZF2KY8kkzhbzddKeSlocM5xqIvTgdHGlNwQzEtOrDzEfLSJGSHbsc2fhbZ8cqOeiSm)y1AsrnhlOg1jxDpUxVhBcnQtojLkGmowZfi81hN4XMqJ6KtsPciJJ1CbcFLbOPfh8X7J(X7ktFwZPLAQ5TY80zdhXL3iZF2KY82jc6uwsxPSQX6hqUAM5xqIvTgdHGlNwQzEtOrDzE7ebDklPRuw1y9dixnZ8cqOeiSm)y1AsrnhlOg1jxDpUxVhBcnQtojLkGmowZfi81hN4XMqJ6KtsPciJJ1CbcFLbOPfh8X7J(X7ktFwZPL6MYBL5PZgoIlVrM)SjL5pAbmhdI8zDqIrNVDccK5xqIvTgdHGlNwQzEtOrDz(JwaZXGiFwhKy05BNGazEbiucewMFSAnPOMJfuJ6KRUh3R3JnHg1jNKsfqghR5ce(6Jt8ytOrDYjPubKXXAUaHVYa00Id(49r)4DLPpR50s1JYBL5PZgoIlVrM)SjL5NMRvGjXX8jG54GmhHOpW6Gz(fKyvRXqi4YPLAM3eAuxMFAUwbMehZNaMJdYCeI(aRdM5fGqjqyz(XQ1KIAowqnQtU6ECVEp2eAuNCskvazCSMlq4RpoXJnHg1jNKsfqghR5ce(kdqtlo4J3h9J3vM(SM1mFhGe1CyAERCAPM3kZBcnQlZBaHDeloLCosOzE6SHJ4YBK1CABkVvMNoB4iU8gz(QlZdjnZBcnQlZ71aHnCuM3R5wuMNs3v01rCYPDrJGAXQgBAChbHpUxVhtP7k66iojcNXfMwaiByCiOh3R3JP0DfDDeNeHZ4ctlaKnjoZ5I6ECVEpMs3v01rCYaXfAuhBAiiiRTG0J717Xu6UIUoItQOKDeKnmqsWU4i4J717Xu6UIUoItAO0cqQFbzW4qqCSo3AAiOh3R3JP0DfDDeN0orqNYs6kLvnw)aYvZh3R3JP0DfDDeNe6xIKgHsaiRzhIh3R3JP0DfDDeN8OfWCmiYN1bjgD(2jiWJ717Xu6UIUoItomh1caXga7e(zEVgGD2KY8IAowqnQJvhBbPSMtZJYBL5PZgoIlVrMV6Y8qsZ8MqJ6Y8EnqydhL59AUfL5P0DfDDeN0qjOVbmiRvNYQgRR6tGhN4XEnqydhjf1CSGAuhRo2cszEVgGD2KY8T6ugxTgoIvhBbPSMtZJL3kZtNnCexEJmF1L5HKM5nHg1L59AGWgokZ71ClkZVPDFms5Xj)yVgiSHJKIAowqnQJvhBbPhN4Xi5XEnqydhjB1PmUAnCeRo2cspoLhV9J9y7(yKYJt(XEnqydhjB1PmUAnCeRo2cspoLhV9J3u6Fms5Xj)ykDxrxhXjnuc6BadYA1PSQX6Q(e4XjEmsESxde2WrYwDkJRwdhXQJTG0Jt5XB)yK6hJuECYpMs3v01rCYPDrJGAXQgBAChbHpoXJrYJ9AGWgos2QtzC1A4iwDSfKECkzEVgGD2KY81XwqIjwA1AznNw6ZBL5PZgoIlVrMV6Y8acsAM3eAuxM3RbcB4OmVxdWoBszE)YXXe1CSGAuht9be0VCCzEoQzlNM530UznNgsvERmpD2WrC5nY8vxMhsAM3eAuxM3RbcB4OmVxZTOm)MEms5XQ5OtLnNnjwNPcFjD2WrCpE7h7X94pgP8yK8y1C0PYMZMeRZuHVKoB4iUmVaekbclZ71aHnCK0VugubKLeR5SjbvqKe9y0pE3mVxdWoBszE)szqfqwsSMZMeubrsuwZPTzM3kZtNnCexEJmF1L5HKM5nHg1L59AGWgokZ71ClkZ7rpgP8y1C0PYMZMeRZuHVKoB4iUhV9J94E8hJuEmsESAo6uzZztI1zQWxsNnCexMxacLaHL59AGWgos6BaoMWGkR5SjbvqKe9y0pE3mVxdWoBszEFdWXeguznNnjOcIKOSMtdPoVvMNoB4iU8gz(QlZdiiPzEtOrDzEVgiSHJY8Ena7SjL55iNHmR5SjbvqKeL55OMTCAMFtPpR50845TY80zdhXL3iZxDzEabjnZBcnQlZ71aHnCuM3RbyNnPmFsXX5IdbdqClHg1L55OMTCAMFx5MYAoTu3nVvMNoB4iU8gz(ZMuM3qjOVbmiRvNYQgRR6tGmVj0OUmVHsqFdyqwRoLvnwx1NaznNwQPM3kZBcnQlZpdaOaSyAiOmpD2WrC5nYAoTu3uERmVj0OUmFxPrDzE6SHJ4YBK1CAP6r5TY8MqJ6Y8DidQHZGAMNoB4iU8gznRzEOAhNb4yGsnnQlVvoTuZBL5PZgoIlVrMxacLaHL5t(XMqdVeJoAge8X7H(XEnqydhj9lLbvazjXAoBsqfejrpoXJt(XAmPhJYpESAnPOMJfuJ6KodQmcfDbGE8Ep2RbcB4ijh5mKznNnjOcIKOhNYJt5XjE8y1As)szqfqwssazcnZBcnQlZ3C2KGkisIYAoTnL3kZtNnCexEJmVaekbclZpwTM0VugubKLKeqMqFCIhpwTM0VugubKLKeqtlo4J3)XMqJ6KTaqdZ5KekiXsjMgtkZBcnQlZ3HmOgodQznNMhL3kZtNnCexEJmVaekbclZpwTM0VugubKLKeqMqFCIhN8J7aKxgcbNmvzla0WCUh3R3JBbGGQbucinHgEPh3R3JnHg1j7qgudNbvzCSMlq4RpUxVhplVXH4XPK5nHg1L57qgudNb1SMtZJL3kZtNnCexEJmVaekbclZl8nacc(49q)yp6XjESj0WlXOJMbbF8EpEtpoXJrYJ9AGWgos25x0fOG1vLloezEtOrDz(o)IUafSMZMemR50sFERmpD2WrC5nY8cqOeiSm)y1As)szqfqwssazc9XjESAaeKk9jZP(YoH(49r)ypA3hN4XQ5OtLqYaXHGP1s4lPZgoIlZBcnQlZ3HmOgodQznNgsvERmpD2WrC5nY8cqOeiSm)y1AYoKbLWzWPeqMqFCIhlmOY0yspE)hpwTMSdzqjCgCkb00IdM5nHg1L57qgudNb1SMtBZmVvMNoB4iU8gz(fKy99dhXeguJdroTuZ8cqOeiSmFYpESAnjyDeRASUQpbKCv)7XjEmsEClaeunGsaPj0Wl94uECIhJKh71aHnCKSfaInCguzDv5IdXJt84KFCYpo5hBcnQt2canmNtsOGelnoepUxVhBcnQt2HmOgodQscfKyPXH4XP84epESAnPpzACiyRojGmH(4uECVEpo5hRMJovcjdehcMwlHVKoB4iUhN4XQbqqQ0NmN6l7e6J3h9J9ODFCIhN8JhRwt6tMghc2QtcitOpoXJrYJnHg1jHIci8LekiXsJdXJ717Xi5XJvRj9lLbvazjjbKj0hN4Xi5XJvRj9jtJdbB1jbKj0hN4XMqJ6Kqrbe(scfKyPXH4XjEmsESj0OozhYGA4mOkJJ1CbcF9XjEmsESj0Oozla0WCozCSMlq4RpoLhNYJtjZVGeRAngcbxoTuZ8MqJ6Y8TaqSHZGAwZPHuN3kZtNnCexEJmVaekbclZN8JhRwt6tMghc2QtcitOpUxVhN8JrYJhRwt6xkdQaYsscitOpoXJt(XMqJ6KTaqSHZGQu4Baee8X794DFCVEpwnhDQesgioemTwcFjD2WrCpoXJvdGGuPpzo1x2j0hVp6h7r7(4uECkpoLhN4Xi5XEnqydhj78l6cuW6QYfhImVj0OUmFNFrxGcwZztcM1CAE88wzE6SHJ4YBK5nHg1L5fMZXmHg1XCbuZ8UaQSZMuM3eA4LyQ5OtHznNwQ7M3kZtNnCexEJmVaekbclZBcn8sm6OzqWhV3JtnZBcnQlZZbme1bzdazQFwZPLAQ5TY80zdhXL3iZBcnQlZlmNJzcnQJ5cOM5DbuzNnPmFO0eYCvFwhikqOiN1CAPUP8wzE6SHJ4YBK5fGqjqyzE1aiiv6tMt9LDc9X7J(XE0UpoXJvZrNkHKbIdbtRLWxsNnCexM3eAuxMhkkGWpR50s1JYBL5PZgoIlVrMxacLaHL5nHgEjgD0mi4J3d9J9AGWgos6BaoMWGkR5SjbvqKe94epo5hRXKEmk)4XQ1KIAowqnQt6mOYiu0fa6X79yVgiSHJKCKZqM1C2KGkisIECkzEtOrDz(MZMeubrsuwZPLQhlVvM3eAuxMVfaAyoxMNoB4iU8gznNwQPpVvM3eAuxMhkkGWpZtNnCexEJSM1mpO6yD(gKYBLtl18wzE6SHJ4YBK5fGqjqyz(KFSj0WlXOJMbbF8EOFSxde2Wrs)szqfqwsSMZMeubrs0Jt84KFSgt6XO8JhRwtkQ5yb1OoPZGkJqrxaOhV3J9AGWgosYrodzwZztcQGij6XP84uECIhpwTM0VugubKLKeqMqZ8MqJ6Y8nNnjOcIKOSMtBt5TY80zdhXL3iZlaHsGWY8JvRj9lLbvazjjbKj0mVj0OUmFhYGA4mOM1CAEuERmpD2WrC5nY8liX67hoIjmOghICAPM5fGqjqyzEK84KFSj0WlXOJMbbF8EOFSxde2WrsFdWXeguznNnjOcIKOhN4Xj)ynM0Jr5hpwTMuuZXcQrDsNbvgHIUaqpEVh71aHnCKKJCgYSMZMeubrs0Jt5XP84epgjpUfacQgqjG0eA4LECIhN8JrYJhRwt6tMghc2QtcitOpoXJrYJhRwt6xkdQaYsscitOpoXJrYJ7aKxw1AmecozlaeB4mO(4epo5hBcnQt2caXgodQsHVbqqWhVh6hVPh3R3Jt(XMqJ6KD(fDbkynNnjOu4Baee8X7H(XP(4epwnhDQSZVOlqbR5SjbL0zdhX94uECVEpo5hRMJovAocfqfyquYGS2cGSKoB4iUhN4XIQCCv)tYbme1bzdazQVeqghYpoLh3R3Jt(XQ5OtLqYaXHGP1s4lPZgoI7XjESAaeKk9jZP(YoH(49r)ypA3hNYJt5XPK5xqIvTgdHGlNwQzEtOrDz(wai2WzqnR508y5TY80zdhXL3iZBcnQlZlmNJzcnQJ5cOM5DbuzNnPmVj0WlXuZrNcZAoT0N3kZtNnCexEJmVaekbclZpwTMSdzqjCgCkbKj0hN4XcdQmnM0J3)XJvRj7qgucNbNsanT4GpoXJhRwtcwhXQgRR6tajGMwCWhV3JfguzAmPmVj0OUmFhYGA4mOM1CAiv5TY80zdhXL3iZVGeRVF4iMWGACiYPLAMxacLaHL5rYJt(XMqdVeJoAge8X7H(XEnqydhj9nahtyqL1C2KGkisIECIhN8J1yspgLF8y1AsrnhlOg1jDguzek6ca949ESxde2WrsoYziZAoBsqfejrpoLhNYJt8yK84waiOAaLastOHx6XjECYpESAnPpzACiyRojGmH(4epo5hRgabPsFYCQVStOpEp0p2J29X969yK8y1C0PsizG4qW0Aj8L0zdhX94uECkz(fKyvRXqi4YPLAM3eAuxMVfaInCguZAoTnZ8wzE6SHJ4YBK5xqI13pCetyqnoe50snZlaHsGWY8i5Xj)ytOHxIrhndc(49q)yVgiSHJK(gGJjmOYAoBsqfejrpoXJt(XAmPhJYpESAnPOMJfuJ6KodQmcfDbGE8Ep2RbcB4ijh5mKznNnjOcIKOhNYJt5XjEmsEClaeunGsaPj0Wl94epwnhDQesgioemTwcFjD2WrCpoXJvdGGuPpzo1x2j0hVp6h7r7(4epo5hpwTM0NmnoeSvNeqMqFCIhJKhBcnQtcffq4ljuqILghIh3R3JrYJhRwt6tMghc2QtcitOpoXJrYJhRwt6xkdQaYsscitOpoLm)csSQ1yieC50snZBcnQlZ3caXgodQznNgsDERmpD2WrC5nY8cqOeiSmpsEChG8Yqi4KPk78l6cuWAoBsWhN4XJvRj9jtJdbB1jbKj0mVj0OUmFNFrxGcwZztcM1CAE88wzE6SHJ4YBK5fGqjqyzE1aiiv6tMt9LDc9X7J(XE0UpoXJvZrNkHKbIdbtRLWxsNnCexM3eAuxMhkkGWpR50sD38wzE6SHJ4YBK5fGqjqyzEtOHxIrhndc(49E8MY8MqJ6Y8CadrDq2aqM6N1CAPMAERmpD2WrC5nY8cqOeiSmFYp2eA4Ly0rZGGpEp0p2RbcB4iPVb4ycdQSMZMeubrs0Jt84KFSgt6XO8JhRwtkQ5yb1OoPZGkJqrxaOhV3J9AGWgosYrodzwZztcQGij6XP84uY8MqJ6Y8nNnjOcIKOSMtl1nL3kZBcnQlZ3canmNlZtNnCexEJSM1SM59sayuxoTnT7M2Dxp2M2uMVVbU4qaZ8BgZUcOe3J94p2eAu3JDbuHY3ZmpSJe50qQ8OmFhOAHJY8E4Jr6bGEC6WqqVNE4J9vTdU5VZoic1FnKIAUdmMlNPrDcG10DGXuSZ7Ph(40HH8J3u6r9XBA3nT7757Ph(yKMVDii4M)7Ph(yu(XEGq6XAmjMwmUGEmWuFc8y13UhRgabPsnMetlgxqpUvGh7mOIYqsuh3JTr4cf5hVGgcckFp9WhJYp2dSJZu6XUcriEmG28FC68seCpEZdq2ekFp9WhJYpoDUkiDpwyq9XakDxbGM0PWh3kWJrA1CSGAu3JtoKKe1hZvx6K(y)YX94qFCRap2ECdqq)hNoiLkWJfgutr(E6HpgLF8MxaTHJESDpMofG8JvFtFC)A54EmGGlN(44ES9yFdWjmO(4nBKb1Wzq9XXHYiSjjFp9WhJYpEZ6zdh9yOccH(yHpjskoepUUhBpUr9FCRajbFCCpw9Ph7bCZoD(XA9yaXTe0J7xGKCLXjFpFp9WhVzffKyPe3JhuRa0Jf1Cy6JheI4GYh7buiOof(4Rou23aZ2Y9ytOrDWhxNdz57Ph(ytOrDqzhGe1Cyk6MZGj9E6Hp2eAuhu2birnhMUn6DAvX9E6Hp2eAuhu2birnhMUn6DSfIjDQPrDVNMqJ6GYoajQ5W0TrVJbe2rS4uY5iH(EAcnQdk7aKOMdt3g9oEnqydhH6ztcTOMJfuJ6y1Xwqc1QdnKuu9AUfHMs3v01rCYPDrJGAXQgBAChbH96rP7k66iojcNXfMwaiByCiOE9O0DfDDeNeHZ4ctlaKnjoZ5I661Js3v01rCYaXfAuhBAiiiRTGuVEu6UIUoItQOKDeKnmqsWU4iyVEu6UIUoItAO0cqQFbzW4qqCSo3AAiOE9O0DfDDeN0orqNYs6kLvnw)aYvZE9O0DfDDeNe6xIKgHsaiRzhIE9O0DfDDeN8OfWCmiYN1bjgD(2jiqVEu6UIUoItomh1caXga7e(VNMqJ6GYoajQ5W0TrVJxde2WrOE2Kq3QtzC1A4iwDSfKqT6qdjfvVMBrOP0DfDDeN0qjOVbmiRvNYQgRR6tGeEnqydhjf1CSGAuhRo2csVNE4J3muAcFS6B6Jna94fK4ECTuyWrpUApgPvZXcQrDp2a0JVsF8csCp2AkbES6hWhRXKEC0ES6ti)4(1YX94UL(y7XkiUKi9XliX94(H6)yKwnhlOg1946ES9yOVb4iUhlQYXv9p57Pj0OoOSdqIAomDB0741aHnCeQNnj01XwqIjwA1AOwDOHKIQxZTi0BAxKsYEnqydhjf1CSGAuhRo2csjqIxde2WrYwDkJRwdhXQJTGukB7X2fPKSxde2WrYwDkJRwdhXQJTGukBVP0JusMs3v01rCsdLG(gWGSwDkRASUQpbsGeVgiSHJKT6ugxTgoIvhBbPu2gPgPKmLURORJ4Kt7Igb1Ivn204occtGeVgiSHJKT6ugxTgoIvhBbPuEp9WhJ0Q5yb1OUhhWhxNd5hVGe3J7hQFT0h7bRaooVuCp2daeSo7e0JlWJth0Sai)4Q9405Li4E8MhGSj8Xr7XH(4(HZ94b9yZRfoB4OhB6JDKb1hR(b8Xt7q(Xqsuhh8XdQva6XQp9yccPtqPtWhlQYXv9VhhWhdiJdz57Pj0OoOSdqIAomDB0741aHnCeQNnj0(LJJjQ5yb1OoM6diOF54qT6qdiiPOYrnB5u0BA33tp8XB5hWh71aHnC0JHDKiAbbFS6tp(wZbbEC1ESAaeKcFSPpUVFi8F8MR0hZRaYs6XiDNnjOcIKi4JRLcdo6Xv7XiTAowqnQ7Xq)A54E8GE8csCY3ttOrDqzhGe1Cy62O3XRbcB4iupBsO9lLbvazjXAoBsqfejrOwDOHKIA0q71aHnCK0VugubKLeR5SjbvqKeHExu9AUfHEtif1C0PYMZMeRZuHVKoB4iUT94ECKcsuZrNkBoBsSotf(s6SHJ4Ep9WhVLFaFSxde2Wrpg2rIOfe8XQp94Bnhe4Xv7XQbqqk8XM(4((HW)XBodW9yKMb1hJ0D2KGkisIGpUwkm4OhxThJ0Q5yb1OUhd9RLJ7Xd6XliX9yd(4w4Ceq(EAcnQdk7aKOMdt3g9oEnqydhH6ztcTVb4ycdQSMZMeubrseQvhAiPOgn0Enqydhj9nahtyqL1C2KGkisIqVlQEn3Iq7rif1C0PYMZMeRZuHVKoB4iUT94ECKcsuZrNkBoBsSotf(s6SHJ4Ep9Wh7bcJdXJr6oBsqfejrp2AkbEmsRMJfuJ6ECaFC5Lapwy3Jf2csp2EmmqCrle2Pp2M160hxThZztdb9yTE8GESRG6J5w0J16XQp94Ylb6dcnoepUApEZaXfk9y130hxcXcaFCFF6ES6tpEZaXfk94gOMpg5AbEChiMga5hJ0Q5yb1OUhRgabPpg2biJdkF8w(b8XEnqydh94a(4fK4ESwpg2rIOH8JvF6X2SwN(4Q9ynM0JJ7Xqsuhh8XQVPpEUG6J7mi8XwtjWJrA1CSGAu3Jju0fac(4b1ka9yKUZMeubrse8X9dN7Xd6XliX94RatZ5qw(EAcnQdk7aKOMdt3g9oEnqydhH6ztcnh5mKznNnjOcIKiu5OMTCk6nLEuRo0acs67Ph(ypyH6)yp4JJZfhcuFmsRMJfuJ6sNGpwuLJR6FpUF4CpEqpgqClbX94bYp2EmWoUA(yBwRtr9XJL(y1NE8TMdc84Q9ybiu4JHQbu4J9saKFSFGW)XwtjWJnHgEnnoepgPvZXcQrDp2oUhdDvF4J5Q(3J1QVb4Gpw9Phth3JR2JrA1CSGAux6e8XIQCCv)t(ypy(094PLuCiEmhjcyuh8XX9y1NEShWn70zuFmsRMJfuJ6sNGpgqtlU4q8yrvoUQ)94a(yaXTee3Jhi)y1pGpUbmHg19yTESje160h3kWJ9GpooxCiKVNMqJ6GYoajQ5W0TrVJxde2WrOE2KqNuCCU4qWae3sOrDOYrnB5u07k3eQvhAabj990dFSj0OoOSdqIAomDB07apRd6xkdQMcFpnHg1bLDasuZHPBJENfKyHstupBsOnuc6BadYA1PSQX6Q(e490eAuhu2birnhMUn6DMbauawmne07Pj0OoOSdqIAomDB070vAu37Pj0OoOSdqIAomDB070HmOgodQVNVNE4J3SIcsSuI7XKxcG8J1yspw9PhBcTapoGp28AHZgos(EAcnQdIwuRtjaSJCU3ttOrDWTrVJxde2WrOE2KqRXKyAXe1CSGAuhQvhAiPO61ClcTAo6uzlaeunGsajD2WrCiLwaiOAaLasanT4GBNSOkhx1)KIAowqnQtcOPfhePKCQOSxde2WrYKIJZfhcgG4wcnQdPOMJovMuCCU4qiPZgoIlfu2eAuNeSoIvnwx1NascfKyPetJjHuuZrNkbRJyvJ1v9jGKoB4iUuqkiruLJR6FsrnhlOg1jbKXHmszSAnPOMJfuJ6KCv)790eAuhCB0741aHnCeQNnj0AmjMwmrnhlOg1HA1HEAOavVMBrOfv54Q(NCsZcGmRAm3seCmoaztOeqtloiQrdnbH0ji5KMfazw1yULi4yCaYMq508GkqIXQ1KtAwaKzvJ5wIGJXbiBcLCv)lHOkhx1)KtAwaKzvJ5wIGJXbiBcLaAAXbrzVgiSHJKAmjMwmrnhlOg1TpAVgiSHJK(LJJjQ5yb1OoM6diOF54EpnHg1b3g9oEnqydhH6ztcTgtIPftuZXcQrDOwDONgkq1R5weArvoUQ)j7xahNxkogGG1zNGKaAAXbrnAOjiKobj7xahNxkogGG1zNGKtZdQajgRwt2VaooVuCmabRZobj5Q(xcrvoUQ)j7xahNxkogGG1zNGKaAAXbrzVgiSHJKAmjMwmrnhlOg1TpAVgiSHJK(LJJjQ5yb1OoM6diOF54EpnHg1b3g9ocZ5yMqJ6yUaQOE2KqhknHm)aHpRdefiuKFpnHg1b3g9oZaakalMgcc1OHESAnPOMJfuJ6KCv)790eAuhCB07GyzaUWow1ygkrGs9rnAOt2RbcB4iPgtIPftuZXcQrD7N6U96PXKyAX4cAFVgiSHJKAmjMwmrnhlOg1LY7Pj0Oo42O3ruNGofykXXAoBsVNMqJ6GBJEhazDXHG1C2KGVNMqJ6GBJENwjwqIJzOebcLydYMVNMqJ6GBJENUfiAihhc2Wzq990eAuhCB07aIUohXIJb7mb9EAcnQdUn6DuFITUrToowRac690eAuhCB07awhXQgRR6tauJg6XQ1KG1rSQX6Q(eqYv9VeJvRjf1CSGAuNKR6Fjs2RbcB4iPgtIPftuZXcQrD71wohdqcFdGGyAmPE98AGWgosQXKyAXe1CSGAu3EQbqqQuJjX0IXfukVNMqJ6GBJEhH5CmtOrDmxavupBsOf1CSGAuhRZ3GeQrdTxde2WrsnMetlMOMJfuJ62h9UVNMqJ6GBJENwai2Wzqf1fKyvRXqi4qNkQliX67hoIjmOghc0PIA0qNmbH0ji5KMfazw1yULi4yCaYMq508GkqVEeesNGKtAwaKzvJ5wIGJXbiBcLZ4kqcdLiqOKC4mOsa20GkbK0zdhXLscHVbqqq0tdfmHVbqqWeizSAnPFPmOciljjGmHMajjpwTM0NmnoeSvNeqMqtK8y1AsrnhlOg1jxDjs2eAuNSfaAyoNmowZfi81E9mHg1j7qgudNbvzCSMlq4R96zcnQtcffq4ljuqILghIu61tnacsL(K5uFzNq3hThTBctOrDsOOacFjHcsS04qKskjqsYizSAnPpzACiyRojGmHMajJvRj9lLbvazjjbKj0eJvRjf1CSGAuNKR6Fjs2eAuNSfaAyoNmowZfi81E9mHg1j7qgudNbvzCSMlq4RPKY7Pj0Oo42O3XRbcB4iupBsOBbGydNbvwxvU4qGQxZTi0Q5OtLG1rSQX6Q(eqsNnCexcrvoUQ)jbRJyvJ1v9jGeqtlo4(IQCCv)t2caXgodQY2Y5yas4BaeetJjLizVgiSHJKAmjMwmrnhlOg1TNj0OojyDeRASUQpbKTLZXaKW3aiiMgtkLejlQYXv9pjyDeRASUQpbKaAAXb3xJjX0IXfuVEMqJ6KG1rSQX6Q(eqk8naccU3UP0RNxde2WrsnMetlMOMJfuJ623eAuNSfaInCguLTLZXaKW3aiiMgtkHxde2WrsnMetlMOMJfuJ62xJjX0IXf07Pj0Oo42O3ryohZeAuhZfqf1ZMeAq1X68niHkubHqrNkQrd9y1AsW6iw1yDvFcixDjs2RbcB4iPgtIPftuZXcQrD7TBkVNMqJ6GBJEhVgiSHJq9SjHUZVOlqbRRkxCiq1R5weA1C0PsW6iw1yDvFciPZgoIlHOkhx1)KG1rSQX6Q(eqcOPfhCFrvoUQ)j78l6cuWAoBsqzB5Cmaj8nacIPXKsKSxde2WrsnMetlMOMJfuJ62ZeAuNeSoIvnwx1NaY2Y5yas4BaeetJjLsIKfv54Q(NeSoIvnwx1NasanT4G7RXKyAX4cQxptOrDsW6iw1yDvFcif(gabb3B3u61ZRbcB4iPgtIPftuZXcQrD7BcnQt25x0fOG1C2KGY2Y5yas4BaeetJjLWRbcB4iPgtIPftuZXcQrD7RXKyAX4c690dFShmF6E8MZaCcdQXH4XiDNnPhZRGijc1hJ0da94nCguHpg6xlh3Jh0JxqI7XA9ye0ratPhV5k9X8kGSKGp2oUhR1JjuO0X94nCgujWJthgujG890eAuhCB070caXgodQOUGeRAngcbh6urDbjwF)WrmHb14qGovuJg6KrIxde2WrYwai2WzqL1vLloe96nwTMeSoIvnwx1NaYvxkjs2RbcB4iPgtIPftuZXcQrD7TBkjs2eA4Ly0rZGG7H2RbcB4iPVb4ycdQSMZMeubrsuIK1ysO8y1AsrnhlOg1jDguzek6caTNxde2WrsoYziZAoBsqfejrPKscK0cabvdOeqAcn8sjgRwt6xkdQaYssYv9VejJedLiqOKC4mOsa20GkbK0zdhX1R3y1AYHZGkbytdQeqcOPfhC)DLPpL3tp8XBElqCiEmspaeunGsauFmspa0J3Wzqf(ydqpEbjUhdJz4mGd5hR1J5wG4q8yKwnhlOg1jFShaPJaMZHmQpw9jKFSbOhVGe3J16XiOJaMspEZv6J5vazjbFCFF6ESaek8X9dN7XxPpEqpUVbvI7X2X94(H6)4nCgujWJthgujaQpw9jKFm0VwoUhpOhd7aKX94APpwRhpT4ulUhR(0J3WzqLapoDyqLapESAn57Pj0Oo42O3PfaInCgurDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0Taqq1akbKMqdVucHVbqqW9qNAIKrIxde2WrYwai2WzqL1vLloe96nwTMeSoIvnwx1NaYvxkjsgjgkrGqj5WzqLaSPbvciPZgoIRxVXQ1KdNbvcWMgujGeqtlo4(7ktFkjsgjMqJ6KTaqdZ5KekiXsJdrcKycnQt2HmOgodQY4ynxGWxtmwTM0NmnoeSvNC11RNj0Oozla0WCojHcsS04qKySAnPFPmOciljjx1)61ZeAuNSdzqnCguLXXAUaHVMySAnPpzACiyRojx1)smwTM0VugubKLKKR6FP8EAcnQdUn6DeMZXmHg1XCbur9SjHgQ2XzaogOutJ6qfQGqOOtf1OH2RbcB4iPgtIPftuZXcQrD7T7757Pj0OoO0eA4LyQ5OtHODH34qWg1CGA0qBcn8sm6OzqW9snXy1AsrnhlOg1j5Q(xIK9AGWgosQXKyAXe1CSGAu3EIQCCv)t6cVXHGnQ5qYTaMg11RNxde2WrsnMetlMOMJfuJ62h9UP8EAcnQdknHgEjMAo6u42O3zskvauJgAVgiSHJKAmjMwmrnhlOg1Tp6D71l5XQ1KG1rSQX6Q(eqU661tuLJR6FsW6iw1yDvFcib00IdUNgtIPfJlOeMqJ6KG1rSQX6Q(eqk8naccUFQ96He1C0PsW6iw1yDvFciPZgoIlLejlQYXv9p5KuQasUfW0OU99AGWgosQXKyAXe1CSGAuxVEAmjMwmUG23RbcB4iPgtIPftuZXcQrDP8EAcnQdknHgEjMAo6u42O3HdyiQdYgaYuFuJgA1C0PsZrOaQadIsgK1waKL0zdhXLi5XQ1KIAowqnQtYv9VeizSAnPFPmOciljjGmH2R3y1AsrnhlOg1jxDjmHg1jBbGydNbvPW3aii4(MqJ6KTaqSHZGQCAOGj8naccMajJvRj9lLbvazjjbKj0uEpFp9WhJ0Q5yb1OUh35Bq6XDaQZae8X2iCHge8X9d1)X2J5iNHmQpw9P7XoBDcFc(4406XQp9yKwnhlOg19yiLUl6e07Pj0OoOuuZXcQrDSoFdsODbcFfY8GwCiM0POgn0JvRjf1CSGAuNKR6FVNMqJ6GsrnhlOg1X68niTn6Dggcw1ykiejbrnAOhRwtkQ5yb1Oojx1)EpnHg1bLIAowqnQJ15BqAB074cVXHGnQ5a1OH2eA4Ly0rZGG7LAIXQ1KIAowqnQtYv9V3ttOrDqPOMJfuJ6yD(gK2g9odxvCSQXuFIrhnr(90eAuhukQ5yb1OowNVbPTrVZKMfazw1yULi4yCaYMW3ttOrDqPOMJfuJ6yD(gK2g9o9lGJZlfhdqW6StqVNE4J38wG4q8yKwnhlOg1H6Jr6bGE8godQWhBa6XliX9yTEmc6iGP0J3CL(yEfqwsWhBh3JNXfZaLOhR(0JTzTo9Xv7XAmPhd7OtFmHcsS04q84s9jWJHDKZbLpgPxGhdv74ma3Jr6bGq9Xi9aqpEdNbv4Jna946Ci)4fK4ECFF6E8MJmnoep2dS7Xb8XMqdV0JlWJ77t3JThZlkGW)XcdQpoGpoUh3bkeaccFSDCpEZrMghIh7b29y74E8MR0hZRaYs6XgGE8v6JnHgEj5J9GfQ)J3WzqLapoDyqLap2oUhJ0D2KEShGhQpgPha6XB4mOcFSWUhBCCHg1zohYpEqpEbjUh33pC0J3CL(yEfqwsp2oUhV5itJdXJ9a7ESbOhFL(ytOHx6X2X9y7XB2idQHZG6Jd4JJ7XQp9ylap2oUhBoy94((HJESWGACiEmVOac)htEP7Xr7XBoY04q8ypWUhhWhBoazCi)ytOHxs(4T8Ph7mvjWJnNR6dFS2VE8MR0hZRaYs6XB2idQHZGk8XA94b9yHb1hh3JHlHGGWOUhBnLapw9PhZlkGWx(ypGCCHg1zohYpUFO(pEdNbvc840Hbvc8y74Ems3zt6XEaEO(yKEaOhVHZGk8Xq)A54E8v6Jh0JxqI7XRZrq4J3WzqLapoDyqLapoGp2g1sFSwpMqrxaOhxGhR(eGESbOhpla9y13UhtxTq4)yKEaOhVHZGk8XA9ycfkDCpEdNbvc840Hbvc8yTES6tpMoUhxThJ0Q5yb1Oo57Pj0OoOuuZXcQrDSoFdsBJENwai2Wzqf1fKyvRXqi4qNkQliX67hoIjmOghc0PIA0ql8naccUh6utKCYMqJ6KTaqSHZGQu4BaeeK1aMqJ6m32jpwTMuuZXcQrDsanT4GO8y1AYHZGkbytdQeqYTaMg1LYMfrvoUQ)jBbGydNbvj3cyAuhkN8y1AsrnhlOg1jb00IdMYMLKhRwtoCgujaBAqLasUfW0OouExz6tjL9qVBVEiXqjcekjhodQeGnnOsajD2WrC96He1C0PYMZMeRojD2WrC96nwTMuuZXcQrDsanT4G7JESAn5WzqLaSPbvci5watJ661BSAn5WzqLaSPbvcib00IdU)UY03RhLURORJ4K(i3ra1hqghRpiGAFG1btiQYXv9pPpYDeq9bKXX6dcO2hyDqMhT7UP6X2Keqtlo4(PpLeJvRjf1CSGAuNC1LizKycnQtcffq4ljuqILghIeiXeAuNSdzqnCguLXXAUaHVMySAnPpzACiyRo5QRxptOrDsOOacFjHcsS04qKySAnPFPmOciljjx1)sK8y1AsFY04qWwDsUQ)1RNHseiusoCgujaBAqLas6SHJ4sPxpdLiqOKC4mOsa20GkbK0zdhXLqnhDQS5SjXQtsNnCexctOrDYoKb1WzqvghR5ce(AIXQ1K(KPXHGT6KCv)lXy1As)szqfqwssUQ)LY7Pj0OoOuuZXcQrDSoFdsBJEhW6iw1yDvFcGA0qpwTMeSoIvnwx1NasUQ)LySAnPOMJfuJ6KCv)790dFShWhJ0da94nCguFm0VwoUhpOhVGe3J16XwxNd5hVHZGkbEC6WGkbECF)Wrpwyqnoep2daRJEC1E8MD1NapUVpDpEbJdXJ3WzqLapoDyqLaO(yKUZM0J9a8q9X2X940bPubKpEZO946Ci)40bnlaYpUApoDEjcUhV5biBcFC6iUc84a(ykDxrxhXH6Jv)a(yxC0Jd4JdexbiUhpiHTG0Jd9X9dN7XWAsAmj4JbeC50hh3JruXH4XXP1JrA1CSGAu3J7hQ)JBu)hJ0da94nCguFSW3aiiO890eAuhukQ5yb1OowNVbPTrVtlaeB4mOI6csS((HJycdQXHaDQOgn0gkrGqj5WzqLaSPbvciPZgoIlrYeesNGKtAwaKzvJ5wIGJXbiBcLtZdQa96HeccPtqYjnlaYSQXClrWX4aKnHYzCfiLeQ5OtLtsPciPZgoIlHAo6uzZztIvNKoB4iUeJvRjhodQeGnnOsajx1)sKSAo6ujyDeRASUQpbK0zdhXLWeAuNeSoIvnwx1NascfKyPXHiHj0OojyDeRASUQpbKekiXsjgGMwCW93vIu1RxYEnqydhj1ysmTyIAowqnQBF072R3y1AsrnhlOg1jxDPKajQ5OtLG1rSQX6Q(eqsNnCexcKycnQt2HmOgodQY4ynxGWxtGetOrDYwaOH5CY4ynxGWxt590eAuhukQ5yb1OowNVbPTrVJWCoMj0OoMlGkQNnj0MqdVetnhDk890eAuhukQ5yb1OowNVbPTrVJOMJfuJ6qDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0jNSj0Oo5KuQaY4ynxGWxtycnQtojLkGmowZfi8vgGMwCW9rVRm9P0RNj0Oo5KuQaY4ynxGWx71JGq6eKCsZcGmRAm3seCmoaztOCAEqfOxVXQ1K(LYGkGSKKaYeAVEMqJ6Kqrbe(scfKyPXHiHj0OojuuaHVKqbjwkXa00IdU)UY03RNj0OozhYGA4mOkjuqILghIeMqJ6KDidQHZGQKqbjwkXa00IdU)UY0NsIKhRwtcwhXQgRR6ta5QRxpKOMJovcwhXQgRR6tajD2WrCP8EAcnQdkf1CSGAuhRZ3G02O3PR0OU3ttOrDqPOMJfuJ6yD(gK2g9odxvCS2cG87Pj0OoOuuZXcQrDSoFdsBJENbbGeiP4q8EAcnQdkf1CSGAuhRZ3G02O3PfaA4QI790eAuhukQ5yb1OowNVbPTrVJDccQaZXeMZ9EAcnQdkf1CSGAuhRZ3G02O3P5SjbvqKeHA0qNCYQ5OtLnNnjwNPcFjD2WrCjmHgEjgD0mi4EBkLE9mHgEjgD0mi4EivPKySAnPFPmOciljjGmHMajgkrGqj5WzqLaSPbvciPZgoI790eAuhukQ5yb1OowNVbPTrVthYGA4mOIA0qpwTMSdzqjCgCkbKj0eJvRjf1CSGAuNeqtlo4EcdQmnM07Pj0OoOuuZXcQrDSoFdsBJENoKb1Wzqf1OHESAnPFPmOciljjGmH(E6HpgPvZjDACiES6hWhtNcq(X1s9G7XHMobFmGCihhIhx3JThditOrDpwJj9yoYzi)4((09yKR1Jt6Q(pg5AbEmVOac)h3pCUhlaH(y74EmY16X(g3J3CKPXH4XEGDpUVpDpg5A9yHb1hZlkGWx(E6HpEZ4qze2Kq9XQFaFCaFSVDCoI7XZcqp(mDbmNdz57Ph(ytOrDqPOMJfuJ6yD(gK2g9oDidQHZGkQrdDhG8Yqi4KPkHIci8tmwTM0NmnoeSvNC19EAcnQdkf1CSGAuhRZ3G02O3PZVOlqbR5SjbFpnHg1bLIAowqnQJ15BqAB07affq4JA0qpwTMuuZXcQrDsanT4G7jmOY0ysjgRwtkQ5yb1Oo5QRxVXQ1KIAowqnQtYv9VeIQCCv)tkQ5yb1OojGMwCW9fguzAmP3ttOrDqPOMJfuJ6yD(gK2g9oUWBCiyJAoqnAOhRwtkQ5yb1OojGMwCW9ri4KtdfjmHgEjgD0mi4EP(EAcnQdkf1CSGAuhRZ3G02O3HdyiQdYgaYuFuJg6XQ1KIAowqnQtcOPfhCFeco50qrIXQ1KIAowqnQtU6EpnHg1bLIAowqnQJ15BqAB07affq4JA0qRgabPsFYCQVStO7J2J2nHAo6ujKmqCiyATe(s6SHJ4EpFpnHg1bLHstituZXcQrDOxqIfknr9SjHoqCHg1XMgccYAli9EAcnQdkdLMqMOMJfuJ62g9oliXcLMOE2Kq7JChbuFazCS(GaQ9bwhe1OHESAnPOMJfuJ6KRUeMqJ6KTaqSHZGQu4Baeee9UjmHg1jBbGydNbvjGe(gabX0ys7HqWjNgkEpnHg1bLHstituZXcQrDBJENfKyHstupBsON2fncQfRASPXDee(EAcnQdkdLMqMOMJfuJ62g9oc7eKJnwTgQliXQwJHqWHovupBsON2fncQfRASPXDeeYe(wNsawDeQrd9y1AsrnhlOg1jxD96zcnQtojLkGmowZfi81eMqJ6KtsPciJJ1CbcFLbOPfhCF07kt)7Pj0OoOmuAczIAowqnQBB07SGeluAI6csSQ1yieCOtf1ZMeAdLwas9lidghcIJ15wtdbHA0qpwTMuuZXcQrDYvxVEMqJ6KtsPciJJ1CbcFnHj0Oo5KuQaY4ynxGWxzaAAXb3h9UY0)EAcnQdkdLMqMOMJfuJ62g9oliXcLMOUGeRAngcbh6urLAnsOSZMeAeoJlmTaq2W4qqOgn0JvRjf1CSGAuNC11RNj0Oo5KuQaY4ynxGWxtycnQtojLkGmowZfi8vgGMwCW9rVRm9VNMqJ6GYqPjKjQ5yb1OUTrVZcsSqPjQliXQwJHqWHovuPwJek7SjHgHZ4ctlaKnjoZ5I6qnAOhRwtkQ5yb1Oo5QRxptOrDYjPubKXXAUaHVMWeAuNCskvazCSMlq4RmanT4G7JExz6FpnHg1bLHstituZXcQrDBJENfKyHstuxqIvTgdHGdDQOE2Kqpmh1caXga7e(Ogn0JvRjf1CSGAuNC11RNj0Oo5KuQaY4ynxGWxtycnQtojLkGmowZfi8vgGMwCW9rVRm9VNMqJ6GYqPjKjQ5yb1OUTrVZcsSqPjQliXQwJHqWHovupBsOH(LiPrOeaYA2Ha1OHESAnPOMJfuJ6KRUE9mHg1jNKsfqghR5ce(ActOrDYjPubKXXAUaHVYa00IdUp6DLP)90eAuhugknHmrnhlOg1Tn6DwqIfknrDbjw1Ameco0PI6ztcTIs2rq2Wajb7IJGOgn0JvRjf1CSGAuNC11RNj0Oo5KuQaY4ynxGWxtycnQtojLkGmowZfi8vgGMwCW9rVRm9VNMqJ6GYqPjKjQ5yb1OUTrVZcsSqPjQliXQwJHqWHovupBsOTte0PSKUszvJ1pGC1e1OHESAnPOMJfuJ6KRUE9mHg1jNKsfqghR5ce(ActOrDYjPubKXXAUaHVYa00IdUp6DLP)90eAuhugknHmrnhlOg1Tn6DwqIfknrDbjw1Ameco0PI6ztc9rlG5yqKpRdsm68TtqauJg6XQ1KIAowqnQtU661ZeAuNCskvazCSMlq4RjmHg1jNKsfqghR5ce(kdqtlo4(O3vM(3ttOrDqzO0eYe1CSGAu32O3zbjwO0e1fKyvRXqi4qNkQNnj0tZ1kWK4y(eWCCqMJq0hyDquJg6XQ1KIAowqnQtU661ZeAuNCskvazCSMlq4RjmHg1jNKsfqghR5ce(kdqtlo4(O3vM(3Z3ttOrDqzO0eY8de(SoquGqrgTWCoMj0OoMlGkQNnj0HstituZXcQrDOgn0Enqydhj1ysmTyIAowqnQBF07(EAcnQdkdLMqMFGWN1bIcekYBJENfKyHst47Pj0OoOmuAcz(bcFwhikqOiVn6DwqIfknr9SjHEAx0iOwSQXMg3rqiQrdnsO0DfDDeN0qjOVbmiRvNYQgRR6tGeEnqydhj1ysmTyIAowqnQBFK63ttOrDqzO0eY8de(SoquGqrEB07SGeluAI6ztcTHsqFdyqwRoLvnwx1NaOgn0Enqydhj1ysmTyIAowqnQBF0PF7utpsXRbcB4izRoLXvRHJy1Xwq690eAuhugknHm)aHpRdefiuK3g9oliXcLMOE2KqdkvawqL4yERIRkgx5COgn0Enqydhj1ysmTyIAowqnQBpVgiSHJK1XwqIjwA1AVNMqJ6GYqPjK5hi8zDGOaHI82O3zbjwO0e1ZMeAlDxrxP0PSZwA4wquJgAVgiSHJKAmjMwmrnhlOg1TNxde2WrY6yliXelTAT3ttOrDqzO0eY8de(SoquGqrEB07SGeluAI6ztcn0p8saMx6QjdqUqGA0q71aHnCKuJjX0IjQ5yb1OU98AGWgoswhBbjMyPvR9EAcnQdkdLMqMFGWN1bIcekYBJENfKyHstupBsOBfyeCC0XQbm4c7ycN1h1OH2RbcB4iPgtIPftuZXcQrD751aHnCKSo2csmXsRw790eAuhugknHm)aHpRdefiuK3g9oliXcLMOsTgju2ztcTVbM1fcghnnLaH5cuIaVNMqJ6GYqPjK5hi8zDGOaHI82O3zbjwO0e1ZMe6P5AfysCmFcyooiZri6dSoiQrdTxde2WrsnMetlMOMJfuJ62dD6tFIXQ1KIAowqnQtYv9VeEnqydhj1ysmTyIAowqnQBpVgiSHJK1XwqIjwA1AVNMqJ6GYqPjK5hi8zDGOaHI82O3zbjwO0e1ZMeA7ebDklPRuw1y9dixnrnAO9AGWgosQXKyAXe1CSGAu3EOtF6tmwTMuuZXcQrDsUQ)LWRbcB4iPgtIPftuZXcQrD751aHnCKSo2csmXsRw790eAuhugknHm)aHpRdefiuK3g9oliXcLMOE2KqF0cyoge5Z6GeJoF7eea1OH2RbcB4iPgtIPftuZXcQrD7H2JL(eJvRjf1CSGAuNKR6Fj8AGWgosQXKyAXe1CSGAu3EEnqydhjRJTGetS0Q1EpFpnHg1bLHstiZv9zDGOaHIm6fKyHstupBsO1GJGAbMmrXrOa1OH2RbcB4iPgtIPftuZXcQrD751aHnCKSo2csmXsRw790eAuhugknHmx1N1bIcekYBJENfKyHstuPwJek7SjHwGSWvkOUqWgodQOgn0Enqydhj1ysmTyIAowqnQBpVgiSHJK1XwqIjwA1AVNVNMqJ6Gsq1X68niHU5SjbvqKeHA0qNSj0WlXOJMbb3dTxde2Wrs)szqfqwsSMZMeubrsuIK1ysO8y1AsrnhlOg1jDguzek6caTNxde2WrsoYziZAoBsqfejrPKsIXQ1K(LYGkGSKKaYe67Pj0OoOeuDSoFdsBJENoKb1Wzqf1OHESAnPFPmOciljjGmH(EAcnQdkbvhRZ3G02O3PfaInCgurDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0ijztOHxIrhndcUhAVgiSHJK(gGJjmOYAoBsqfejrjswJjHYJvRjf1CSGAuN0zqLrOOla0EEnqydhj5iNHmR5SjbvqKeLskjqslaeunGsaPj0WlLizKmwTM0NmnoeSvNeqMqtGKXQ1K(LYGkGSKKaYeAcK0biVSQ1yieCYwai2WzqnrYMqJ6KTaqSHZGQu4BaeeCp0BQxVKnHg1j78l6cuWAoBsqPW3aii4EOtnHAo6uzNFrxGcwZztckPZgoIlLE9swnhDQ0CekGkWGOKbzTfazjD2WrCjev54Q(NKdyiQdYgaYuFjGmoKtPxVKvZrNkHKbIdbtRLWxsNnCexc1aiiv6tMt9LDcDF0E0UPKskVNMqJ6Gsq1X68niTn6DeMZXmHg1XCbur9SjH2eA4LyQ5OtHVNMqJ6Gsq1X68niTn6D6qgudNbvuJg6XQ1KDidkHZGtjGmHMqyqLPXK2FSAnzhYGs4m4ucOPfhmXy1AsW6iw1yDvFcib00IdUNWGktJj9EAcnQdkbvhRZ3G02O3PfaInCgurDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0ijztOHxIrhndcUhAVgiSHJK(gGJjmOYAoBsqfejrjswJjHYJvRjf1CSGAuN0zqLrOOla0EEnqydhj5iNHmR5SjbvqKeLskjqslaeunGsaPj0WlLi5XQ1K(KPXHGT6KaYeAIKvdGGuPpzo1x2j09q7r72RhsuZrNkHKbIdbtRLWxsNnCexkP8EAcnQdkbvhRZ3G02O3PfaInCgurDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0ijztOHxIrhndcUhAVgiSHJK(gGJjmOYAoBsqfejrjswJjHYJvRjf1CSGAuN0zqLrOOla0EEnqydhj5iNHmR5SjbvqKeLskjqslaeunGsaPj0WlLqnhDQesgioemTwcFjD2WrCjudGGuPpzo1x2j09r7r7Mi5XQ1K(KPXHGT6KaYeAcKycnQtcffq4ljuqILghIE9qYy1AsFY04qWwDsazcnbsgRwt6xkdQaYsscitOP8E6HpgPvZjDACiES6hWhtNcq(X1s9G7XHMobFmGCihhIhx3JThditOrDpwJj9yoYzi)4((09yKR1Jt6Q(pg5AbEmVOac)h3pCUhlaH(y74EmY16X(g3J3CKPXH4XEGDpUVpDpg5A9yHb1hZlkGWx(E6HpEZ4qze2Kq9XQFaFCaFSVDCoI7XZcqp(mDbmNdz57Ph(ytOrDqjO6yD(gK2g9oDidQHZGkQrdDhG8Yqi4KPkHIci8tmwTM0NmnoeSvNC1LqnhDQesgioemTwcFjD2WrCjudGGuPpzo1x2j09r7r7MajjBcn8sm6OzqW9q71aHnCK0VugubKLeR5SjbvqKeLiznMekpwTMuuZXcQrDsNbvgHIUaq751aHnCKKJCgYSMZMeubrsukP8EAcnQdkbvhRZ3G02O3PZVOlqbR5SjbrnAOrshG8Yqi4KPk78l6cuWAoBsWeJvRj9jtJdbB1jbKj03ttOrDqjO6yD(gK2g9oqrbe(Ogn0QbqqQ0NmN6l7e6(O9ODtOMJovcjdehcMwlHVKoB4iU3ttOrDqjO6yD(gK2g9oCadrDq2aqM6JA0qBcn8sm6OzqW9207Pj0OoOeuDSoFdsBJENMZMeubrseQrdDYMqdVeJoAgeCp0Enqydhj9nahtyqL1C2KGkisIsKSgtcLhRwtkQ5yb1OoPZGkJqrxaO98AGWgosYrodzwZztcQGijkLuEpnHg1bLGQJ15BqAB070canmN79890eAuhucv74mahduQPrDOBoBsqfejrOgn0jBcn8sm6OzqW9q71aHnCK0VugubKLeR5SjbvqKeLiznMekpwTMuuZXcQrDsNbvgHIUaq751aHnCKKJCgYSMZMeubrsukPKySAnPFPmOciljjGmH(EAcnQdkHQDCgGJbk10OUTrVthYGA4mOIA0qpwTM0VugubKLKeqMqtmwTM0VugubKLKeqtlo4(MqJ6KTaqdZ5KekiXsjMgt690eAuhucv74mahduQPrDBJENoKb1Wzqf1OHESAnPFPmOciljjGmHMi5oa5LHqWjtv2canmNRxVwaiOAaLastOHxQxptOrDYoKb1WzqvghR5ce(AVEZYBCis590eAuhucv74mahduQPrDBJENo)IUafSMZMee1OHw4BaeeCp0EuctOHxIrhndcU3MsGeVgiSHJKD(fDbkyDv5IdX7Pj0OoOeQ2XzaogOutJ62g9oDidQHZGkQrd9y1As)szqfqwssazcnHAaeKk9jZP(YoHUpApA3eQ5OtLqYaXHGP1s4lPZgoI790eAuhucv74mahduQPrDBJENoKb1Wzqf1OHESAnzhYGs4m4ucitOjeguzAmP9hRwt2HmOeodoLaAAXbFpnHg1bLq1oodWXaLAAu32O3PfaInCgurDbjw1Ameco0PI6csS((HJycdQXHaDQOgn0jpwTMeSoIvnwx1NasUQ)LajTaqq1akbKMqdVukjqIxde2WrYwai2WzqL1vLloejso5KnHg1jBbGgMZjjuqILghIE9mHg1j7qgudNbvjHcsS04qKsIXQ1K(KPXHGT6KaYeAk96LSAo6ujKmqCiyATe(s6SHJ4sOgabPsFYCQVStO7J2J2nrYJvRj9jtJdbB1jbKj0eiXeAuNekkGWxsOGelnoe96HKXQ1K(LYGkGSKKaYeAcKmwTM0NmnoeSvNeqMqtycnQtcffq4ljuqILghIeiXeAuNSdzqnCguLXXAUaHVMajMqJ6KTaqdZ5KXXAUaHVMskP8E6HpgPvZjDACiES6hWhtNcq(X1s9G7XHMobFmGCihhIhx3JThditOrDpwJj9yoYzi)4((09yKR1Jt6Q(pg5AbEmVOac)h3pCUhlaH(y74EmY16X(g3J3CKPXH4XEGDpUVpDpg5A9yHb1hZlkGWx(E6HpEZ4qze2Kq9XQFaFCaFSVDCoI7XZcqp(mDbmNdz57Ph(ytOrDqjuTJZaCmqPMg1Tn6D6qgudNbvuJg6oa5LHqWjtvcffq4NySAnPpzACiyRo5QlHAo6ujKmqCiyATe(s6SHJ4sOgabPsFYCQVStO7J2J2nbss2eA4Ly0rZGG7H2RbcB4iPFPmOciljwZztcQGijkrYAmjuESAnPOMJfuJ6KodQmcfDbG2ZRbcB4ijh5mKznNnjOcIKOus590eAuhucv74mahduQPrDBJENo)IUafSMZMee1OHo5XQ1K(KPXHGT6KaYeAVEjJKXQ1K(LYGkGSKKaYeAIKnHg1jBbGydNbvPW3aii4E72RNAo6ujKmqCiyATe(s6SHJ4sOgabPsFYCQVStO7J2J2nLusjbs8AGWgos25x0fOG1vLloeVNMqJ6GsOAhNb4yGsnnQBB07imNJzcnQJ5cOI6ztcTj0WlXuZrNcFpnHg1bLq1oodWXaLAAu32O3HdyiQdYgaYuFuJgAtOHxIrhndcUxQVNMqJ6GsOAhNb4yGsnnQBB07imNJzcnQJ5cOI6ztcDO0eYCvFwhikqOi)EAcnQdkHQDCgGJbk10OUTrVduuaHpQrdTAaeKk9jZP(YoHUpApA3eQ5OtLqYaXHGP1s4lPZgoI790dFShSq9FmD1cH)JvdGGuiQpo0hhWhBpgHf3J16XcdQpgP7SjbvqKe9yd(4w4Ce4XXbvY4EC1Emspa0WCo57Pj0OoOeQ2XzaogOutJ62g9onNnjOcIKiuJgAtOHxIrhndcUhAVgiSHJK(gGJjmOYAoBsqfejrjswJjHYJvRjf1CSGAuN0zqLrOOla0EEnqydhj5iNHmR5SjbvqKeLY7Pj0OoOeQ2XzaogOutJ62g9oTaqdZ5EpnHg1bLq1oodWXaLAAu32O3bkkGWpRznNb]] )


end
