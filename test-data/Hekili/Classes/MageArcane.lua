-- MageArcane.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'MAGE' then
    local spec = Hekili:NewSpecialization( 62, true )

    spec:RegisterResource( Enum.PowerType.ArcaneCharges, {
        arcane_orb = {
            aura = "arcane_orb",

            last = function ()
                local app = state.buff.arcane_orb.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 0.5,
            value = function () return state.active_enemies end,
        },
    } )

    spec:RegisterResource( Enum.PowerType.Mana, {
        evocation = {
            aura = "evocation",

            last = function ()
                local app = state.buff.evocation.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 0.1,
            value = function () return state.mana.regen * 0.1 end,
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        amplification = 22458, -- 236628
        rule_of_threes = 22461, -- 264354
        arcane_familiar = 22464, -- 205022

        mana_shield = 23072, -- 235463
        shimmer = 22443, -- 212653
        slipstream = 16025, -- 236457

        incanters_flow = 22444, -- 1463
        mirror_image = 22445, -- 55342
        rune_of_power = 22447, -- 116011

        resonance = 22453, -- 205028
        charged_up = 22467, -- 205032
        supernova = 22470, -- 157980

        chrono_shift = 22907, -- 235711
        ice_ward = 22448, -- 205036
        ring_of_frost = 22471, -- 113724

        reverberate = 22455, -- 281482
        touch_of_the_magi = 22449, -- 210725
        nether_tempest = 22474, -- 114923

        overpowered = 21630, -- 155147
        time_anomaly = 21144, -- 210805
        arcane_orb = 21145, -- 153626
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3580, -- 208683
        relentless = 3579, -- 196029
        adaptation = 3578, -- 214027

        netherwind_armor = 3442, -- 198062
        torment_the_weak = 62, -- 198151
        arcane_empowerment = 61, -- 276741
        master_of_escape = 635, -- 210476
        temporal_shield = 3517, -- 198111
        dampened_magic = 3523, -- 236788
        rewind_time = 636, -- 213220
        kleptomania = 3529, -- 198100
        prismatic_cloak = 3531, -- 198064
        mass_invisibility = 637, -- 198158
    } )

    -- Auras
    spec:RegisterAuras( {
        arcane_charge = {
            duration = 3600,
            max_stack = 4,
            generate = function ()
                local ac = buff.arcane_charge

                if arcane_charges.current > 0 then
                    ac.count = arcane_charges.current
                    ac.applied = query_time
                    ac.expires = query_time + 3600
                    ac.caster = "player"
                    return
                end

                ac.count = 0
                ac.applied = 0
                ac.expires = 0
                ac.caster = "nobody"
            end,
            --[[ meta = {
                stack = function ()
                    return arcane_charges.current
                end,
            } ]]
        },
        arcane_familiar = {
            id = 210126,
            duration = 3600,
            max_stack = 1,
        },
        arcane_intellect = {
            id = 1459,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
            shared = "player", -- use anyone's buff on the player, not just player's.
        },
        arcane_orb = {
            duration = 2.5,
            max_stack = 1,
            --[[ generate = function ()
                local last = action.arcane_orb.lastCast
                local ao = buff.arcane_orb

                if query_time - last < 2.5 then
                    ao.count = 1
                    ao.applied = last
                    ao.expires = last + 2.5
                    ao.caster = "player"
                    return
                end

                ao.count = 0
                ao.applied = 0
                ao.expires = 0
                ao.caster = "nobody"
            end, ]]
        },
        arcane_power = {
            id = 12042,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        blink = {
            id = 1953,
        },
        charged_up = {
            id = 205032,
        },
        chrono_shift_buff = {
            id = 236298,
            duration = 5,
            max_stack = 1,
        },
        chrono_shift = {
            id = 236299,
            duration = 5,
            max_stack = 1,
        },
        clearcasting = {
            id = function () return pvptalent.arcane_empowerment.enabled and 276743 or 263725 end,
            duration = 15,
            type = "Magic",
            max_stack = function () return pvptalent.arcane_empowerment.enabled and 3 or 1 end,
            copy = { 263725, 276743 }
        },
        displacement = {
            id = 212801,
        },
        displacement_beacon = {
            id = 212799,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        evocation = {
            id = 12051,
            duration = 1,
            max_stack = 1,
        },
        frost_nova = {
            id = 122,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        greater_invisibility = {
            id = 113862,
            duration = 3,
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
        nether_tempest = {
            id = 114923,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },
        presence_of_mind = {
            id = 205025,
            duration = 3600,
            max_stack = 2,
        },
        prismatic_barrier = {
            id = 235450,
            duration = 60,
            type = "Magic",
            max_stack = 1,
        },
        ring_of_frost = {
            id = 82691,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        rule_of_threes = {
            id = 264774,
            duration = 15,
            max_stack = 1,
        },
        rune_of_power = {
            id = 116014,
            duration = 3600,
            max_stack = 1,
        },
        shimmer = {
            id = 212653,
        },
        slow = {
            id = 31589,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        slow_fall = {
            id = 130,
            duration = 30,
            max_stack = 1,
        },
        touch_of_the_magi = {
            id = 210824,
            duration = 8,
            max_stack = 1,
        },

        -- Azerite Powers
        brain_storm = {
            id = 273330,
            duration = 30,
            max_stack = 1,
        },

        equipoise = {
            id = 264352,
            duration = 3600,
            max_stack = 1,
        },
    } )


    spec:RegisterHook( "spend", function( amt, resource )
        if resource == "arcane_charges" then
            if arcane_charges.current == 0 then removeBuff( "arcane_charge" )
            else applyBuff( "arcane_charge", nil, arcane_charges.current ) end

        elseif resource == "mana" then
            if azerite.equipoise.enabled and mana.percent < 70 then
                removeBuff( "equipoise" )
            end
        end
    end )

    spec:RegisterHook( "gain", function( amt, resource )
        if resource == "arcane_charges" then
            if arcane_charges.current == 0 then removeBuff( "arcane_charge" )
            else
                if talent.rule_of_threes.enabled and arcane_charges.current >= 3 and arcane_charges.current - amt < 3 then
                    applyBuff( "rule_of_threes" )
                end
                applyBuff( "arcane_charge", nil, arcane_charges.current )
            end
        end
    end )


    spec:RegisterStateTable( "burn_info", setmetatable( {
        __start = 0,
        start = 0,
        __average = 20,
        average = 20,
        n = 1,
        __n = 1,
    }, {
        __index = function( t, k )
            if k == "active" then
                return t.start > 0
            end
        end,
    } ) )


    spec:RegisterTotem( "rune_of_power", 609815 )

    spec:RegisterHook( "reset_precast", function ()
        if pet.rune_of_power.up then applyBuff( "rune_of_power", pet.rune_of_power.remains )
        else removeBuff( "rune_of_power" ) end

        if burn_info.__start > 0 and ( ( state.time == 0 and now - player.casttime > ( gcd.execute * 4 ) ) or ( now - burn_info.__start >= 45 ) ) and ( ( cooldown.evocation.remains == 0 and cooldown.arcane_power.remains < action.evocation.cooldown - 45 ) or ( cooldown.evocation.remains > cooldown.arcane_power.remains + 45 ) ) then
            -- Hekili:Print( "Burn phase ended to avoid Evocation and Arcane Power desynchronization (%.2f seconds).", now - burn_info.__start )
            burn_info.__start = 0
        end

        burn_info.start = burn_info.__start
        burn_info.average = burn_info.__average
        burn_info.n = burn_info.__n

        if arcane_charges.current > 0 then applyBuff( "arcane_charge", nil, arcane_charges.current ) end

        incanters_flow.reset()
    end )


    spec:RegisterStateFunction( "start_burn_phase", function ()
        burn_info.start = query_time
    end )


    spec:RegisterStateFunction( "stop_burn_phase", function ()
        if burn_info.start > 0 then
            burn_info.average = burn_info.average * burn_info.n
            burn_info.average = burn_info.average + ( query_time - burn_info.start )
            burn_info.n = burn_info.n + 1

            burn_info.average = burn_info.average / burn_info.n
            burn_info.start = 0
        end
    end )


    spec:RegisterStateExpr( "burn_phase", function ()
        return burn_info.start > 0
    end )

    spec:RegisterStateExpr( "average_burn_length", function ()
        return burn_info.average or 15
    end )


    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceGUID == GUID and subtype == "SPELL_CAST_SUCCESS" then
            if spellID == 12042 then
                burn_info.__start = GetTime()
                Hekili:Print( "Burn phase started." )
            elseif spellID == 12051 and burn_info.__start > 0 then
                burn_info.__average = burn_info.__average * burn_info.__n
                burn_info.__average = burn_info.__average + ( query_time - burn_info.__start )
                burn_info.__n = burn_info.__n + 1

                burn_info.__average = burn_info.__average / burn_info.__n
                burn_info.__start = 0
                Hekili:Print( "Burn phase ended." )
            end
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        arcane_barrage = {
            id = 44425,
            cast = 0,
            cooldown = 3,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 236205,

            -- velocity = 24, -- ignore this, bc charges are consumed on cast.

            handler = function ()
                spend( arcane_charges.current, "arcane_charges" )
                if talent.chrono_shift.enabled then
                    applyBuff( "chrono_shift_buff" )
                    applyDebuff( "target", "chrono_shift" )
                end
            end,
        },


        arcane_blast = {
            id = 30451,
            cast = function () 
                if buff.presence_of_mind.up then return 0 end
                return 2.25 * ( 1 - ( 0.08 * arcane_charges.current ) ) * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = function () 
                if buff.rule_of_threes.up then return 0 end
                local mult = 0.0275 * ( 1 + arcane_charges.current ) * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 )
                if azerite.equipoise.enabled and mana.pct < 70 then return ( mana.modmax * mult ) - 190 end
                return mult
            end,
            spendType = "mana",

            startsCombat = true,
            texture = 135735,

            handler = function ()
                if buff.presence_of_mind.up then
                    removeStack( "presence_of_mind" )
                    if buff.presence_of_mind.down then setCooldown( "presence_of_mind", 60 ) end
                end
                removeBuff( "rule_of_threes" )
                if arcane_charges.current < arcane_charges.max then gain( 1, "arcane_charges" ) end
            end,
        },


        arcane_explosion = {
            id = 1449,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if not pvptalent.arcane_empowerment.enabled and buff.clearcasting.up then return 0 end
                return 0.1 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 )
            end,
            spendType = "mana",

            startsCombat = true,
            texture = 136116,

            usable = function () return target.distance < 10 end,
            handler = function ()
                removeStack( "clearcasting" )
                gain( 1, "arcane_charges" )
            end,
        },


        summon_arcane_familiar = {
            id = 205022,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            startsCombat = false,
            texture = 1041232,

            nobuff = "arcane_familiar",
            essential = true,

            handler = function ()
                if buff.arcane_familiar.down then mana.max = mana.max * 1.10 end
                applyBuff( "arcane_familiar" )
            end,

            copy = "arcane_familiar"
        },


        arcane_intellect = {
            id = 1459,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 0.04 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            nobuff = "arcane_intellect",
            essential = true,

            startsCombat = false,
            texture = 135932,

            handler = function ()
                applyBuff( "arcane_intellect" )
            end,
        },


        arcane_missiles = {
            id = 5143,
            cast = function () return ( buff.clearcasting.up and 0.8 or 1 ) * 2.5 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = function () 
                if buff.rule_of_threes.up then return 0 end
                return buff.clearcasting.up and 0 or 0.15 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 136096,

            handler = function ()
                removeBuff( "rule_of_threes" )
                removeStack( "clearcasting" )
            end,
        },


        arcane_orb = {
            id = 153626,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = function () return 0.01 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 1033906,

            talent = "arcane_orb",

            handler = function ()
                gain( 1, "arcane_charges" )
                applyBuff( "arcane_orb" )
            end,
        },


        arcane_power = {
            id = 12042,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",
            nobuff = "arcane_power", -- don't overwrite a free proc.

            startsCombat = true,
            texture = 136048,

            handler = function ()
                applyBuff( "arcane_power" )
                start_burn_phase()
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


        --[[ shimmer = {
            id = 212653,
            cast = 0,
            charges = 2,
            cooldown = 20,
            recharge = 20,
            gcd = "off",

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = false,
            texture = 135739,

            talent = "shimmer",

            handler = function ()
                -- applies shimmer (212653)
            end,
        }, ]]


        charged_up = {
            id = 205032,
            cast = 0,
            cooldown = 40,
            gcd = "spell",

            startsCombat = true,
            texture = 839979,

            handler = function ()
                gain( 4, "arcane_charges" )
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

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 135856,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        displacement = {
            id = 195676,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 132171,

            buff = "displacement_beacon",

            handler = function ()
                removeBuff( "displacement_beacon" )
            end,
        },


        evocation = {
            id = 12051,
            cast = 6,
            charges = 1,
            cooldown = 90,
            recharge = 90,
            gcd = "spell",

            channeled = true,
            fixedCast = true,

            -- toggle = "cooldowns",

            startsCombat = false,
            texture = 136075,

            start = function ()
                stop_burn_phase()
                applyBuff( "evocation" )
                if azerite.brain_storm.enabled then
                    gain( 2, "arcane_charges" )
                    applyBuff( "brain_storm" ) 
                end
            end,
        },


        frost_nova = {
            id = 122,
            cast = 0,
            charges = function () return talent.ice_ward.enabled and 2 or nil end,
            cooldown = 30,
            recharge = 30,
            gcd = "spell",

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 135848,

            handler = function ()
                applyDebuff( "target", "frost_nova" )
            end,
        },


        greater_invisibility = {
            id = 110959,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 575584,

            handler = function ()
                applyBuff( "greater_invisibility" )
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


        mirror_image = {
            id = 55342,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 135994,

            talent = "mirror_image",

            handler = function ()
                applyBuff( "mirror_image" )
            end,
        },


        nether_tempest = {
            id = 114923,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 0.02 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 610471,

            handler = function ()
                applyDebuff( "target", "nether_tempest" )
            end,
        },


        polymorph = {
            id = 118,
            cast = 1.7,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 0.04 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = false,
            texture = 136071,

            handler = function ()
                applyDebuff( "target", "polymorph" )
            end,
        },


        presence_of_mind = {
            id = 205025,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136031,

            nobuff = "presence_of_mind",

            handler = function ()
                applyBuff( "presence_of_mind", nil, 2 )
            end,
        },


        prismatic_barrier = {
            id = 235450,
            cast = 0,
            cooldown = function () return talent.mana_shield.enabled and 0 or 25 end    ,
            gcd = "spell",

            defensive = true,

            spend = function() return 0.03 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = false,
            texture = 135991,

            handler = function ()
                applyBuff( "prismatic_barrier" )
            end,
        },


        remove_curse = {
            id = 475,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = function () return 0.01 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 136082,

            debuff = "dispellable_curse",
            handler = function ()
                removeDebuff( "player", "dispellable_curse" )
            end,
        },


        ring_of_frost = {
            id = 113724,
            cast = 2,
            cooldown = 45,
            gcd = "spell",

            spend = function () return 0.08 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
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


        slow = {
            id = 31589,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 0.01 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 136091,

            handler = function ()
                applyDebuff( "target", "slow" )
            end,
        },


        slow_fall = {
            id = 130,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 0.01 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
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

            spend = function () return 0.21 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
            spendType = "mana",

            startsCombat = true,
            texture = 135729,

            debuff = "stealable_magic",
            handler = function ()
                removeDebuff( "target", "stealable_magic" )
            end,
        },


        supernova = {
            id = 157980,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 1033912,

            talent = "supernova",

            handler = function ()
            end,
        },


        time_warp = {
            id = 80353,
            cast = 0,
            cooldown = 300,
            gcd = "off",

            spend = function () return 0.04 * ( buff.arcane_power.up and ( talent.overpowered.enabled and 0.4 or 0.7 ) or 1 ) end,
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


    spec:RegisterSetting( "arcane_info", nil, {
        type = "description",
        name = "The Arcane Mage module treats combat as one of two phases.  The 'Burn' phase begins when you have used Arcane Power and begun aggressively burning mana.  The 'Conserve' phase starts when you've completed a burn phase and used Evocation to refill your mana bar.  This phase is less " ..
            "aggressive with mana expenditure, so that you will be ready when it is time to start another burn phase.",

        width = "full",
        order = 1,
    } )

    
    --[[ spec:RegisterSetting( "conserve_mana", 75, { -- NYI
            type = "range",
            name = "Minimum Mana (Conserve Phase)",
            desc = "Specify the amount of mana (%) that should be conserved when conserving mana before a burn phase.",

            min = 25,
            max = 100,
            step = 1,

            width = "full",
            order = 2,
        }
    } ) ]]


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "potion_of_focused_resolve",

        package = "Arcane",
    } )


    spec:RegisterPack( "Arcane", 20200525, [[d0KFqbqiesEKKGlHqvvTjjPprbkJIQkNIQQwffiEff0SikULkIAxu5xevnmeIJPI0Yik5zscnnQkQRruQ2gcv5BiuvgNkI05OQiToveH5jj6EsQ9rvHdQIWcPiEifOAIQiI4IiKsBeHuuFeHQQCsesvRuf1lrifzMQiI0nPaP2jvL(PkIOgkvfXsrifEkHMkfPRsbs(kcvv2lP(ljdgYHrTyL6XqnzeDzWML4Ziy0QWPrA1iKkVMOYSvPBtKDl8BPgobhhHklx0ZP00v11vY2PqFNQmEekNNcy9eLY8PO2VI1NQnvlsYpO9vwerweHiYUSKD3PNwrIurzxl(gqa0IcmwoMaOfdwc0INiXCaArb2a3Mj1MQfT9kXGw84Fb7jH8YtG(hRTd3sYBPsRl)0oWjxE5TujS8AX9IEFI(qV1IK8dAFLfrKfrisfjYPArRaG1(s8KLw8GsscHERfjblwlwHbDIeZbmidAMamNRWGo(xWEsiV8eO)XA7WTK8wQ06YpTdCYLxElvcl)CUcdYGMnWGKLSlZGKfrKfrMZZ5kmid(bhea7jXCUcd6KhK958v7vgkHd2cYmi73cQ9kdLWbBbzgehKdIncjtau7vgQlee(JbXjmOdoiVa5G2gyq)bmiMKSd3CUcd6Kh0Zjb4DpvcuFRiPWGozFmi)EQeO(wrsb)hKTh0FW)G8Gbr2Hb7heqmmyTuJW1adAVYyqDmOpz7XGOLb5bdISdd2pipo(b9TBoxHbDYdYGsGKFyqc9t7yq3Maf70IxQ9TAt1I4oSqAe0MQ99uTPArg)0o0Is0m7urLycGwecEFbsTj6x7RS0MQfHG3xGuBIweN0hskRf3RsXXjMdqHp4Ka4SpJLBq1dIiArg)0o0I4dojaKQLG(1(wrTPAri49fi1MOfXj9HKYAr)gucLeSh8(cdYS5brud6Py5ObHb5)GQoO9QuCCI5au4dojao7Zy5gu9G2RsXXjMdqHp4Ka4KyIPSpJLBqvh0EvkUCfGQlkH2dshz7fdQ6G2RsXXjMdqj0Eq6iBVqlY4N2HwmG)as1dscG91V2xFwBQwecEFbsTjArCsFiPSwCVkfhNyoaf(GtcGZ(mwUbvz9GK1GQoi)geU7lz7fooXCakH2dsxcsmnSdYhd6uImiZMheJFQrqbbirb7GQSEqYAq(Rfz8t7qlYjMdq15w)AFLDTPAri49fi1MOfXj9HKYAX9QuC56cQUO(JeaRBjmOQdAVkfhNyoaf(GtcGZ(mwUb5JbvrTiJFAhAroXCaQ9LTV(1(s80MQfHG3xGuBIweN0hskRf3RsXLRauDrj0Eq6iBVyqvhernO9QuCCI5aucThKUey8pOQdc39LS9chNyoaLq7bPlbjMg2b5JbjlIOfdwc0IpLeSFNskCtcetlY4N2Hw8PKG97usHBsGy6x7lXN2uTie8(cKAt0I4K(qszT4EvkUCfGQlkH2dshz7fdQ6GiQbTxLIJtmhGsO9G0LaJ)bvDq4UVKTx44eZbOeApiDjiX0WoiFmizreTiJFAhArSbW3(ZoOy1(Y2xlcLcGFvWsGweBa8T)SdkwTVS91V23tQ2uTie8(cKAt0I4K(qszT4EvkooXCak8bNeaN9zSCdQEq7vP44eZbOWhCsaCsmXu2NXYnOQdYVbvw3Rkb8bNea1tLGbvz9GaIb41dQNkbdYS5bvw3Rkb8bNea1tLGbvz9GWDFjBVWXjMdqj0Eq6sqIPHDqMnpONkbQVvKuyqvwpiC3xY2lCCI5aucThKUeKyAyhK)Arg)0o0I5kavxucThK6x7RpvBQwecEFbsTjAr8btdT4PArCsFiPSwuId2jG)bvz9G8PY(GQoO9QuC4lWjMTpni4sGX)GQoig)uJGccqIc2bv5GQOwKXpTdTiNyoaLe1APxWQFTVNseTPAri49fi1MOfXj9HKYAr)gKFdAVkfhNyoaf(GtcGZ(mwUbvpO9QuCCI5au4dojaojMyk7Zy5gK)dQ6G8Bq(nijoyNa(huL1dYiNuEFbhUdlKgbLeh8G8FqMnpi)g0ZxiExUcq1fLq7bPdcEFbYbvDq4UVKTx44eZbOeApiDjiX0WoiFmiC3xY2lC5kavxucThKUY6EvjGp4KaOEQemOQdsId2jG)bvz9GmYjL3xWH7WcPrqjXbpidhKSK9b5)G8FqMnpi)g0ZxiEhNyoavNBhe8(cKdQ6GWDFjBVWXjMdq152LGetd7GQSEqeWKdQ6GWDFjBVWXjMdqj0Eq6sqIPHDq(yqNsKb5)G8FqMnpijoyNa(huL1dYVbzKtkVVGd3HfsJGsIdEqN8GoLidYFTiJFAhAroXCaQnNjta0V23tpvBQwecEFbsTjArCsFiPSwuId2jG)bvz9G8PYUwKXpTdTODjaz0gz9R99uzPnvlcbVVaP2eTioPpKuwlY4NAeuqasuWoiFupOkoOQdYVbjXb7eW)G8r9GmYjL3xWH7WcPrqjXbpiZMh0EvkooXCak8bNeaN9zSCdQEqvCq(Rfz8t7qlYjMdqbet42wAh6x77PvuBQwKXpTdTiNyoa1(Y2xlcbVVaP2e9R99uFwBQwKXpTdTiNyoa1MZKjaAri49fi1MOF9RfjHcVUV2uTVNQnvlY4N2Hwe3R4H0ka3RwecEFbsTj6x7RS0MQfz8t7qlAfG71(aF1IqW7lqQnr)AFRO2uTiJFAhAXeKAJGcVslOfHG3xGuBI(1(6ZAt1IqW7lqQnrlY4N2HweZ3RIXpTd1LAFT4LAFvWsGweSwiWGv)AFLDTPAri49fi1MOfXj9HKYAX9QuC5kavxucThKoY2lgu1bTxLIJtmhGsO9G0r2EXGQoi)geU7lz7fooXCakH2dsxcsmnSdQY6b5ZdYWbDkrgKbzqg5KY7l4kD8kYETVGQd1YcdQ6GWDFjBVWbgBm)0oCjiX0WoOkRhKroP8(co2iKmbqTxzOUqq4pgKHdYNhKHd6uImidYGmYjL3xWv64vK9AFbvhQLfgKzZd6PsG6BfjfguLdc39LS9chNyoaLq7bPlbjMg2b5VwmyjqlYYM9Gt2QkD8QUOeApi1Im(PDOfzzZEWjBvLoEvxucThK6x7lXtBQwecEFbsTjArg)0o0Iy(Evm(PDOUu7RfXj9HKYAX9kdLWbBHbz28G8BqpvcuFRiPWGQCqSrizcGAVYqDHGWFmi)1IxQ9vblbAX9kd9R9L4tBQwecEFbsTjArg)0o0Iy(Evm(PDOUu7RfXj9HKYAr)geU7lz7fooXCakH2dsxcsmnSdQEqezqvheU7lz7foWyJ5N2HlbjMg2bvz9GyJqYea1ELH6cbH)yqvhKFdAVkfhNyoaf(GtcGZ(mwUbvpO9QuCCI5au4dojaojMyk7Zy5gKzZdYVb98fI3Hp4KaqQwcoi49fihu1bH7(s2EHdFWjbGuTeCjiX0WoO6brKbvDq7vP44eZbOWhCsaC2NXYnOkRh0PdY)b5)G8xlEP2xfSeOf3Rm0V23tQ2uTie8(cKAt0Im(PDOfX89Qy8t7qDP2xlIt6djL1Ie1G2RmuchSf0IxQ9vblbArChwinc6x7RpvBQwecEFbsTjArg)0o0Iy(Evm(PDOUu7RfVu7Rcwc0IsTrqcIx)6xlkKaUL28Rnv77PAt1Im(PDOf5eZbOOXd3lGFTie8(cKAt0V2xzPnvlY4N2Hw0UKK6qXjMdqvyj6LYPwecEFbsTj6x7Bf1MQfHG3xGuBIwSf0Iw41Im(PDOfnYjL3xqlAKVlqls8iYGmCqYIidYGmiw2GK(GdiUfvOPwWbbVVaPw0iNQGLaTiUdlKgbLehS(1(6ZAt1IqW7lqQnrl2cArl8Arg)0o0Ig5KY7lOfnY3fOfbIBrfeashlB2dozRQ0XR6IsO9GCqvhKFdciUfvqaiDsCqlG9Bvxusmzaw7GmBEqaXTOccaPJWLjP83PvTzscWGmBEqaXTOccaPJWLjP83PvjbK89s7yqMnpiG4wubbG0rje0N2HsIjawvzzHbz28GaIBrfeas3lBCaw1Mt5Sc0aSdYS5bbe3IkiaKow2wj8hTvzPbbGujCxsmbyqMnpiG4wubbG0XbMcXRKl6x1fLh1s2sdYS5bbe3IkiaKo7rJLBtFiTQchegKzZdciUfvqaiDbSs(QSgiyblOG4GdmKdYS5bbe3IkiaKUnFHcnb1o5aFmi)1Ig5ufSeOflD8kYETVGQd1Yc6x7RSRnvlcbVVaP2eTylOfTWRfz8t7qlAKtkVVGw0iFxGw8uzPfnYPkyjqlw64vDrj0EqQesa3sB(v4doc4QfXj9HKYArJCs59fCLoEfzV2xq1HAzHbvDqg5KY7l4kD8QUOeApivcjGBPn)k8bhbChu9GiI(1(s80MQfHG3xGuBIwmyjqlYYM9Gt2QkD8QUOeApi1Im(PDOfzzZEWjBvLoEvxucThK6x7lXN2uTiJFAhArjAMDQOsmbqlcbVVaP2e9R99KQnvlY4N2HwuOFAhAri49fi1MOFTV(uTPArg)0o0ICI5au7lBFTie8(cKAt0V(1I7vgAt1(EQ2uTie8(cKAt0I4K(qszT4EvkooXCak8bNeaN9zSCdQY6bDQwKXpTdTi(GtcaPAjOFTVYsBQwKXpTdTOenZovujMaOfHG3xGuBI(1(wrTPAri49fi1MOfXj9HKYAr)gucLeSh8(cdYS5brud6Py5ObHb5)GQoO9QuCCI5au4dojao7Zy5gu9G2RsXXjMdqHp4Ka4KyIPSpJLBqvh0EvkUCfGQlkH2dshz7fdQ6G2RsXXjMdqj0Eq6iBVqlY4N2HwmG)as1dscG91V2xFwBQwecEFbsTjArCsFiPSwCVkfxUUGQlQ)ibW6wcdQ6GE(cX7AJqk0EqcKoi49fihu1bX4NAeuqasuWoOkhuf1Im(PDOf5eZbO2x2(6x7RSRnvlcbVVaP2eTioPpKuwlUxLIJtmhGsO9G0r2EHwKXpTdT4Ls44TkIUfjbjiE9R9L4PnvlcbVVaP2eTioPpKuwlUxLIJtmhGsO9G0r2EHwKXpTdT4MjO6I6tkwoR(1(s8PnvlcbVVaP2eTioPpKuwlsudAVkfhNyoaLq7bPBjmOQdYVbjXb7eW)G8r9GKDImiZMheU7lz7fooXCakH2dsxcsmnSdQEqezq(pOQdYVbTxLIJtmhGcFWjbWzFgl3GQh0EvkooXCak8bNeaNetmL9zSCdYFTiJFAhAXCfGQlkH2ds9R99KQnvlY4N2HwCdPfs5ObbTie8(cKAt0V2xFQ2uTiJFAhAroXCakH2dsTie8(cKAt0V23tjI2uTie8(cKAt0I4K(qszT4EvkooXCakH2ds3syqMnpONkbQVvKuyqvoiC3xY2lCCI5aucThKUeKyAy1Im(PDOfxwqrFqYQFTVNEQ2uTiJFAhAX9TBsvzLgqlcbVVaP2e9R99uzPnvlY4N2HwSqtyF7MulcbVVaP2e9R990kQnvlY4N2HwKdmy)KVkmFVAri49fi1MOFTVN6ZAt1IqW7lqQnrlIt6djL1I(nONVq8UCfGQlkH2dshe8(cKdQ6G2RsXLRauDrj0Eq6sqIPHDqvwpO9QuCcjyHadQUOKObPtIjMY(mwUbzqgeJFAhooXCaQ9LTVdigGxpOEQemi)hKzZdAVkfhNyoaLq7bPlbjMg2bvz9G2RsXjKGfcmO6IsIgKojMyk7Zy5gKbzqm(PD44eZbO2x2(oGyaE9G6PsGwKXpTdTOqcwiWGQlkjAqQFTVNk7At1IqW7lqQnrlIt6djL1I7vP44eZbOeApiDlHbvDq(ni)gerniWAHadoChKqybs1LwGsNyWjXeDDoiZMheyTqGbhUdsiSaP6slqPtm4soKBqvoizni)hu1b53G2RsXTH0cPC0GGBjmiZMh0EvkU9TBsvzLgWTegKzZdIOgKFdkzm4(SV3bz28GsgdUoXdY)b5)GmBEq7vP4iS4KKYHQlkw2GS)d3syq(piZMh0tLa13kskmOkheU7lz7fooXCakH2dsxcsmnSArg)0o0Ic9t7q)AFpL4PnvlcbVVaP2eTioPpKuwlUxLIJtmhGcFWjbWzFgl3GQhergKzZdYVbX4NAeuqasuWoOkhufhKzZdYVbX4NAeuqasuWoOkhKSgu1b98fI3LGTdoWGdcEFbYb5)G8xlY4N2HwKtmhGQZT(1(EkXN2uTie8(cKAt0I4K(qszTiJFQrqbbirb7G8r9GQ4GQoi)g0EvkooXCak8bNeaN9zSCdQEq7vP44eZbOWhCsaCsmXu2NXYni)1Im(PDOf5eZbO2CMmbq)AFp9KQnvlcbVVaP2eTioPpKuwlY4NAeuqasuWoiFupOkQfz8t7qlYjMdqbet42wAh6x77P(uTPAri49fi1MOfXhmn0INQfXj9HKYAX9QuC4lWjMTpni4sGX)GQoig)uJGccqIc2bv5GQ4GQoi)g0ZxiEhljCPfkMFAhoi49fihKzZdYVbrud65leVRncPq7bjq6GG3xGCqvhelBqsFWXjMdqjSKKGlni4soKBq(OEqYAq(piZMh0EvkooXCakH2dshz7fdYFTiJFAhAroXCakjQ1sVGv)AFLfr0MQfHG3xGuBIweN0hskRfz8tnckiajkyhuLdQIArg)0o0ICI5au7lBF9R9vwNQnvlsJhYCj8kArlkXb7eWVpQpPYUwKgpK5s4vujjGKYpOfpvlY4N2Hwem2y(PDOfHG3xGuBI(1(klzPnvlY4N2HwKtmhGAZzYeaTie8(cKAt0V(1IG1cbgSAt1(EQ2uTie8(cKAt0I4K(qszT4ELHs4GTWGQoO9QuCCI5aucThKoY2lgu1bTxLIlxbO6IsO9G0r2EXGQoO9QuCCI5au4dojao7Zy5gu9G2RsXXjMdqHp4Ka4KyIPSpJLBqMnpONkbQVvKuyqvoiC3xY2lCCI5aucThKUeKyAy1Im(PDOf33UjvDr9hGccqYa6x7RS0MQfHG3xGuBIweN0hskRf3RsXLRauDrj0Eq6iBVyqvh0EvkooXCakH2dshz7fdQ6G8Bqe1G2RmuchSfgKzZd6PsG6BfjfguLdc39LS9chNyoaLq7bPlbjMg2b5)GQoijoy3tLa13kjMydYh1dcigGxpOEQeOfz8t7qlI7adXN8dKQYLLaT4LgGctQfjE6x7Bf1MQfHG3xGuBIweN0hskRf3RsXLRauDrj0Eq6iBVyqvh0EvkooXCakH2dshz7fdQ6G8Bqe1G2RmuchSfgKzZd6PsG6BfjfguLdc39LS9chNyoaLq7bPlbjMg2b5)GQoijoy3tLa13kjMydYh1dcigGxpOEQeOfz8t7qlMalqdcQYLLaR(1(6ZAt1IqW7lqQnrlIt6djL1I7vP4YvaQUOeApiDKTxmOQdAVkfhNyoaLq7bPJS9cTiJFAhAXsJxwGuXYgK0huBGL0V2xzxBQwecEFbsTjArCsFiPSwCVkfxUcq1fLq7bPJS9IbvDq7vP44eZbOeApiDKTxOfz8t7qlsyXjjLdvxuSSbz)h6x7lXtBQwecEFbsTjArCsFiPSwCVkfxUcq1fLq7bPJS9IbvDq7vP44eZbOeApiDKTxOfz8t7qlkSsAXa0GGAFz7RFTVeFAt1IqW7lqQnrlIt6djL1I7vP4YvaQUOeApiDKTxmOQdAVkfhNyoaLq7bPJS9cTiJFAhAXKkiCbfnuwbgd6x77jvBQwecEFbsTjArCsFiPSwCVkfxUcq1fLq7bPJS9IbvDq7vP44eZbOeApiDKTxOfz8t7ql(hGAf7EfKQsNyq)AF9PAt1IqW7lqQnrlIt6djL1Ie1G2RmuchSfgu1bTxLIJtmhGsO9G0r2EXGQoiC3xY2lCCI5aucThKUeKyAyhu1bTxLIJtmhGcFWjbWzFgl3GQh0EvkooXCak8bNeaNetmL9zSCdQ6G8Bqe1GE(cX7YvaQUOeApiDqW7lqoiZMheJFAhUCfGQlkH2dsh(GtcGDq(piZMh0tLa13kskmOkheU7lz7fooXCakH2dsxcsmnSArg)0o0IsGuNgq1f1DHPKkYeyjR(1(Ekr0MQfHG3xGuBIweN0hskRf3RmuchSfgu1bTxLIJtmhGsO9G0r2EXGQoO9QuC5kavxucThKoY2lgu1bTxLIJtmhGcFWjbWzFgl3GQh0EvkooXCak8bNeaNetmL9zSCdYS5b9ujq9TIKcdQYbH7(s2EHJtmhGsO9G0LGetdRwKXpTdTOxNxsJanujy7GdmOF9RfLAJGeeV2uTVNQnvlcbVVaP2eTioPpKuwlk1gbjiEhj1(CGHb5J6bDkr0Im(PDOf3xAiN(1(klTPAri49fi1MOfXj9HKYArP2iibX7iP2NdmmiFupOtjIwKXpTdT4(sd50V23kQnvlY4N2Hwuibleyq1fLeni1IqW7lqQnr)AF9zTPArg)0o0ICI5ausuRLEbRwecEFbsTj6x7RSRnvlY4N2HwKtmhGQZTwecEFbsTj6x7lXtBQwKXpTdTODjaz0gzTie8(cKAt0V(1Vw0iKwAhAFLfrKfrisfjYPArpodAqWQfj6Le68bYbr8geJFAhd6sTV1nN1I86p6ulksLwx(PDyWtU8ArHSl0lOfRWGorI5agKbntaMZvyqh)lypjKxEc0)yTD4wsElvAD5N2bo5YlVLkHLFoxHbzqZgyqYs2LzqYIiYIiZ55CfgKb)GdcG9KyoxHbDYdY(C(Q9kdLWbBbzgK9Bb1ELHs4GTGmdIdYbXgHKjaQ9kd1fcc)XG4eg0bhKxGCqBdmO)agets2HBoxHbDYd65Ka8UNkbQVvKuyqNSpgKFpvcuFRiPG)dY2d6p4FqEWGi7WG9dciggSwQr4AGbTxzmOog0NS9yq0YG8Gbr2Hb7hKhh)G(2nNRWGo5bzqjqYpmiH(PDmOBtGIDZ55CfgerlXa86bYbTHsNWGWT0M)bTbc0W6g0jWyq4Tdk64Kp4uQSUdIXpTd7G64Aa3CUcdIXpTdRtibClT5VUCzRCZ5kmig)0oSoHeWT0MFdRLV0n5CUcdIXpTdRtibClT53WA55fbjiE(PDmNz8t7W6esa3sB(nSwEoXCakA8W9c4FoZ4N2H1jKaUL28ByT8CI5aufwIEPCoNRWGWDyH0iOK4Ghe1oO)agKeh8GeGedXZeGb5bdYJJFqFpic9GiBVyqFpiYvsdcdc3HfsJGBqe9)GcaiTd67bDb2imii6fHJbLDlnOVhKxN2Fqy2cdYIHGtApiRalnOtyYG64AGbrUsAqyqNWN4MZm(PDyDcjGBPn)gwlVroP8(cYeSeuJ7WcPrqjXbltluBHxgJ8Db1epIyOSiIbHLniPp4aIBrfAQfCqW7lqoNz8t7W6esa3sB(nSwEJCs59fKjyjOU0XRi71(cQoullitluBHxgJ8Db1aXTOccaPJLn7bNSvv64vDrj0Eqw1pG4wubbG0jXbTa2VvDrjXKbyTMnde3IkiaKocxMKYFNw1MjjaMnde3IkiaKocxMKYFNwLeqY3lTdZMbIBrfeashLqqFAhkjMayvLLfmBgiUfvqaiDVSXbyvBoLZkqdWA2mqClQGaq6yzBLWF0wLLgeasLWDjXeaZMbIBrfeashhykeVsUOFvxuEulzlz2mqClQGaq6ShnwUn9H0QkCqWSzG4wubbG0fWk5RYAGGfSGcIdoWqA2mqClQGaq628fk0eu7Kd8H)Zzg)0oSoHeWT0MFdRL3iNuEFbzcwcQlD8QUOeApivcjGBPn)k8bhbCLPfQTWlJr(UG6tLLm0sTroP8(cUshVISx7lO6qTSqvJCs59fCLoEvxucThKkHeWT0MFf(GJaU1ezoZ4N2H1jKaUL28ByT8llOOpijtWsqnlB2dozRQ0XR6IsO9GCoZ4N2H1jKaUL28ByT8s0m7urLycWCMXpTdRtibClT53WA5f6N2XCMXpTdRtibClT53WA55eZbO2x2(Z55CfgerlXa86bYbbgH0ad6PsWG(dyqm(7Cqu7GyJm9Y7l4MZm(PDyRX9kEiTcW9oNz8t7WAyT8wb4ETpW35mJFAhwdRLpbP2iOWR0cZzg)0oSgwlpMVxfJFAhQl1(YeSeudwleyWoNz8t7WAyT8llOOpijtWsqnlB2dozRQ0XR6IsO9GugAPEVkfxUcq1fLq7bPJS9IQ7vP44eZbOeApiDKTxu1pC3xY2lCCI5aucThKUeKyAyRS2Nn8uIyqmYjL3xWv64vK9AFbvhQLfQI7(s2EHdm2y(PD4sqIPHTYAJCs59fCSrizcGAVYqDHGWFyOpB4PeXGyKtkVVGR0XRi71(cQoully28tLa13kskujU7lz7fooXCakH2dsxcsmnS(pNRWGi(Rh03dYKvgdYNCWwyqEhqmi(MatAGbTxzqdcYmOohK3bedA3w7G8O37GiPWGSDhU5mJFAhwdRLhZ3RIXpTd1LAFzcwcQ3RmKHwQ3RmuchSfmB2VNkbQVvKuOs2iKmbqTxzOUqq4p8FoxHbj(C(dYKvgdYNCWwyqEhqmOtKyoGb5tApihe1oOeysdmioiherRXgZpTJb5rV3bTHbLatAGb5xhdIncjta8FqBO0jmO)ag0ELXGeoylmiQDqTriDd6exBpijwoyq2vcdYdgeH(hKppOtKyoGbzWp4KayLzqDoimhdIa8dYNh0jsmhWGm4hCsaSdYJ(hdYGFWjbGCqgucU5mJFAhwdRLhZ3RIXpTd1LAFzcwcQ3RmKHwQ9d39LS9chNyoaLq7bPlbjMg2AIuf39LS9chySX8t7WLGetdBL1SrizcGAVYqDHGWFu1V9QuCCI5au4dojao7Zy5Q3RsXXjMdqHp4Ka4KyIPSpJLZSz)E(cX7WhCsaivlbhe8(cKvXDFjBVWHp4KaqQwcUeKyAyRjs19QuCCI5au4dojao7Zy5QS(u)93)5mJFAhwdRLhZ3RIXpTd1LAFzcwcQXDyH0iidTutu7vgkHd2cZzg)0oSgwlpMVxfJFAhQl1(YeSeul1gbji(58CUcdIOpWjibXpOELdAVYyqchSfgeUxXdPBqe)oGamc5G8GbbXd5G(dyqO9kd0Gy8t7Woip6F0RFqBGgegengepO9kJbjCWwqMbr)bjbCyh0FW)G8GbXjmiE3RFqFpi7Z5pOoa3CUcdIXpTdRBVYO2iNuEFbzcwcQ)(5RAVYWktluZKKYyKVlO(uzOLAIAVYqjCWwyoxHbX4N2H1TxzyyT82NZxTxzOeoylidTutu7vgkHd2cZ5kmiI2GCq)bmO9kJbjCWwyqEhqmipyqeDl7piWyJ5hiDZ5kmig)0oSU9kddRL3(TGAVYqjCWwqgAPEVYqjCWwOQqcgveWKUtDGXgZpTJQ(9ujq9TIKc(7dJCs59fCSrizcGAVYqDHGWFuDVYqjCWwqrUs(PD4dImNRWGojfS2b9hCmOthenSpWKdQldciUfFTd67brezg0gW8YcdQldsiHtgZ2FqNiXCadYKlB)5mJFAhw3ELHH1YJp4KaqQwcYql17vP44eZbOWhCsaC2NXYvz9PZzg)0oSU9kddRLxIMzNkQetaMZm(PDyD7vggwlFa)bKQhKea7ldTu7xcLeSh8(cMntupflhni4F19QuCCI5au4dojao7Zy5Q3RsXXjMdqHp4Ka4KyIPSpJLR6EvkUCfGQlkH2dshz7fv3RsXXjMdqj0Eq6iBVyoxHbr87aIbLRiObHbDs2iKcThKaPmdIdYb5bdIq)dIherJ1fguxgKPhja2bjKnEq(DcIMoXG8GbrO)b1RCq(8FmOtKyoGbzWp4KamiJuEqg8dojaKdYGsWFzg0YcdI(dAdLoHbTS0GWGiA0(edpHprMbTbmVSWG(dyqsCWdkbYf(PDmiQDq9FaPh1cd6Yjb4AGb5X2hihKLgyyq)bmOtyYG8y7GkjadIdd4XgWnNz8t7W62RmmSwEoXCaQ9LTVm0s9EvkUCDbvxu)rcG1TeQ(8fI31gHuO9GeiDqW7lqwLXp1iOGaKOGTYkoNz8t7W62RmmSw(lLWXBveDlscsq8Yql17vP44eZbOeApiDKTxmNz8t7W62RmmSw(ntq1f1NuSCwzOL69QuCCI5aucThKoY2lMZm(PDyD7vggwlFUcq1fLq7bPm0s9EvkUCfGQlkH2dshz7fvjQ9QuCCI5aucThKULqv)K4GDc43h1YormBg39LS9chNyoaLq7bPlbjMg2AI4Fv)2RsXXjMdqHp4Ka4SpJLREVkfhNyoaf(GtcGtIjMY(mwo)NZm(PDyD7vggwl)gslKYrdcZzg)0oSU9kddRLNtmhGsO9GCoZ4N2H1TxzyyT8llOOpizLHwQ3RsXXjMdqj0Eq6wcMn)ujq9TIKcvI7(s2EHJtmhGsO9G0LGetd7CMXpTdRBVYWWA533UjvLvAG5mJFAhw3ELHH1YxOjSVDtoNz8t7W62RmmSwEoWG9t(QW89oNz8t7W62RmmSwEHeSqGbvxus0GugAP2VNVq8UCfGQlkH2dshe8(cKv3RsXLRauDrj0Eq6sqIPHTY69QuCcjyHadQUOKObPtIjMY(mwodcJFAhooXCaQ9LTVdigGxpOEQe4VzZ7vP44eZbOeApiDjiX0Wwz9EvkoHeSqGbvxus0G0jXetzFglNbHXpTdhNyoa1(Y23bedWRhupvcMZm(PDyD7vggwlVq)0oKHwQ3RsXXjMdqj0Eq6wcv9ZpIcSwiWGd3bjewGuDPfO0jgCsmrxNMndwleyWH7GeclqQU0cu6edUKd5Quw(x1V9QuCBiTqkhni4wcMnVxLIBF7MuvwPbClbZMjk)sgdUp771S5KXGRtS)(B28EvkoclojPCO6IILni7)WTe83S5NkbQVvKuOsC3xY2lCCI5aucThKUeKyAyNZm(PDyD7vggwlpNyoavNBzOL69QuCCI5au4dojao7Zy5QjIzZ(X4NAeuqasuWwzfnB2pg)uJGccqIc2kLv1NVq8UeSDWbgCqW7lq6V)Zzg)0oSU9kddRLNtmhGAZzYeazOLAg)uJGccqIcwFuxXQ(TxLIJtmhGcFWjbWzFglx9EvkooXCak8bNeaNetmL9zSC(pNz8t7W62RmmSwEoXCakGyc32s7qgAPMXp1iOGaKOG1h1vCoxHbr0ti6eg0jsmhWGmOPwl9c2brUsAqyqNiXCadYN0EqkZGylLegujBPbzBjyqgH0adYkayAHIheqmmi80oSYmOlvoyqr)d6Gnsdcd6KSrifApibYb98fIhihu1bLRiObHbvrInOtKyoGb5twssWLgeCZzg)0oSU9kddRLNtmhGsIAT0lyLHwQ3RsXHVaNy2(0GGlbg)vz8tnckiajkyRSIv975leVJLeU0cfZpTdhe8(cKMn7hr98fI31gHuO9GeiDqW7lqwLLniPp44eZbOewssWLgeCjhY5JAz5VzZ7vP44eZbOeApiDKTx4Vm4dMg1NoNz8t7W62RmmSwEoXCaQ9LTVm0snJFQrqbbirbBLvCoxHb5B7nO)G)b5bgSegezhWG2RmObbzgKhmimhdAjqYpmO)ageBesMaO2Rmuxii8hdYJ(hd6pGbDHGWFmOUmO)GAh0ELHBoxHbX4N2H1TxzyyT8g5KY7litWsqnBesMaO2Rmuxii8hY0c1w4LXiFxqTFg5KY7l4yJqYea1ELH6cbH)WGyKtkVVG77NVQ9kd7jBKtkVVGJncjtau7vgQlee(dd9BVYqjCWwqrUs(PD4V)e)BKtkVVG77NVQ9kd7CMXpTdRBVYWWA5bJnMFAhYqJhYCj8kAPwId2jGFFuFsLDzOXdzUeEfvsciP8d1NoNRWGiAUZb9hWGsoHb1ymBPDmiVdiHb5bdIqpOULg0gkDcdcm2y(PDmiQDqBgl3GwcUb5NbLDX3Rbg0gW8YcdYdgeb4hKrinWG2m5GYGWGS9G(dyq7vgdIAheE9dYiKgyq2JoF)NZm(PDyD7vggwlpNyoa1MZKjaZ55mJFAhwhUdlKgHAjAMDQOsmbyoZ4N2H1H7WcPrWWA5XhCsaivlbzOL69QuCCI5au4dojao7Zy5QjYCMXpTdRd3HfsJGH1YhWFaP6bjbW(Yql1(Lqjb7bVVGzZe1tXYrdc(xDVkfhNyoaf(GtcGZ(mwU69QuCCI5au4dojaojMyk7Zy5QUxLIlxbO6IsO9G0r2Er19QuCCI5aucThKoY2lMZm(PDyD4oSqAemSwEoXCaQo3Yql17vP44eZbOWhCsaC2NXYvzTSQ6hU7lz7fooXCakH2dsxcsmnS(4uIy2mJFQrqbbirbBL1YY)5Cfg0jsmhWGm5Y2Fq2dA5TdAjmiAmiHK2j9nWG8oGyq5kcAqyq56cdQld6psaSU5mJFAhwhUdlKgbdRLNtmhGAFz7ldTuVxLIlxxq1f1FKayDlHQ7vP44eZbOWhCsaC2NXY5JkoNz8t7W6WDyH0iyyT8llOOpijtWsq9tjb73PKc3KaXKHwQ3RsXLRauDrj0Eq6iBVOkrTxLIJtmhGsO9G0LaJ)Q4UVKTx44eZbOeApiDjiX0W6dzrK5mJFAhwhUdlKgbdRLFzbf9bjzGsbWVkyjOgBa8T)SdkwTVS9LHwQ3RsXLRauDrj0Eq6iBVOkrTxLIJtmhGsO9G0LaJ)Q4UVKTx44eZbOeApiDjiX0W6dzrK5mJFAhwhUdlKgbdRLpxbO6IsO9GugAPEVkfxUcq1fLq7bPJS9IQ7vP44eZbOWhCsaC2NXYvVxLIJtmhGcFWjbWjXetzFglxv)kR7vLa(GtcG6PsqL1aXa86b1tLaZMlR7vLa(GtcG6PsqL14UVKTx44eZbOeApiDjiX0WA28Zjb4DpvcuFRiPqL14UVKTx44eZbOeApiDjiX0W6)CMXpTdRd3HfsJGH1YZjMdqjrTw6fSYql1sCWob8xzTpv2RUxLIdFboXS9Pbbxcm(RY4NAeuqasuWwzfLbFW0O(05Cfg0jjRKgegeUdlKgbzgKhmi7tV3br0TS)G844h03dc3XtJfmOO)brMTGanimi8bNea7Gy7GUDqyqSDqcT1s3xWj2dsoaegKbBVYGgemydITd62bHbX2bj0wlDFHb5hlhpiChwinckjo4b9hjypo6lP)dIdYb9hqmiRhlmOVhepiFMyd6eMCY(4eBoZbH7WcPryqz)8t7WniI(YG8Gbr2dk6FqhSryq(8GoHbxMb5bdcZXGiPcdYEPeo(Rbg0T9GCqFpicWpiEq(8FmOtyWDdI4hmi(A7bzx2NPXG4Fq8GoOeoGCqsCWdsasmeptagK3bedYdgKWLJb99Gwwyq8GiAScyqDzq(K2dYbrUsAqyq4oSqAegKWbBbzgKThKhmimhdAVYyqKRKgeg0FadIOXkGb1Lb5tApiDZzg)0oSoChwincgwlpNyoa1MZKjaYql1(53EvkooXCak8bNeaN9zSC17vP44eZbOWhCsaCsmXu2NXY5Fv)8tId2jG)kRnYjL3xWH7WcPrqjXb7VzZ(98fI3LRauDrj0Eq6GG3xGSkU7lz7fooXCakH2dsxcsmnS(a39LS9cxUcq1fLq7bPRSUxvc4dojaQNkbvL4GDc4VYAJCs59fC4oSqAeusCWgklz3F)nB2VNVq8ooXCaQo3oi49fiRI7(s2EHJtmhGQZTlbjMg2kRjGjRI7(s2EHJtmhGsO9G0LGetdRpoLi(7VzZsCWob8xzTFg5KY7l4WDyH0iOK4Gp5tjI)Z5kmiXLaKrBKhe1oOnNW1adYRZ)yqy2(0GGmdY7GIpge1oiVddmi6piQDq2Eqfohez7fYmOoUgyqeDl7piE3gHbDctCdAoZ4N2H1H7WcPrWWA5TlbiJ2ildTulXb7eWFL1(uzFoxHbr0eacdYGTxzqdcgSbrJbXnmil9x8t7WoOv807GWDyH0iOK4GhKa(Dd6eLhYb9h8pOoUgyqy2(d6eeTdYJ(hdQId6ejMdyq4dojawzgKLgyyq03GzheFLA7piG4w8DqsCWdc32FqFpiEqvCq2NXYnOtyYG4WaESbCd6e)G(d(hKqtJFqNOjAhu2p)0ogKh9Eh0gg0jmzqeRINSpobr7j7JtS5mNZm(PDyD4oSqAemSwEoXCakGyc32s7qgAPMXp1iOGaKOG1h1vSQFsCWob87JAJCs59fC4oSqAeusCWMnVxLIJtmhGcFWjbWzFglxDf9FoZ4N2H1H7WcPrWWA55eZbO2x2(Zzg)0oSoChwincgwlpNyoa1MZKjaZ55mJFAhwhyTqGbB9(2nPQlQ)auqasgqgAPEVYqjCWwO6EvkooXCakH2dshz7fv3RsXLRauDrj0Eq6iBVO6EvkooXCak8bNeaN9zSC17vP44eZbOWhCsaCsmXu2NXYz28tLa13kskujU7lz7fooXCakH2dsxcsmnSZzg)0oSoWAHadwdRLh3bgIp5hivLllbYCPbOWK1epzOL69QuC5kavxucThKoY2lQUxLIJtmhGsO9G0r2Erv)iQ9kdLWbBbZMFQeO(wrsHkXDFjBVWXjMdqj0Eq6sqIPH1)QsCWUNkbQVvsmX8rnqmaVEq9ujyoZ4N2H1bwleyWAyT8jWc0GGQCzjWkdTuVxLIlxbO6IsO9G0r2Er19QuCCI5aucThKoY2lQ6hrTxzOeoyly28tLa13kskujU7lz7fooXCakH2dsxcsmnS(xvId29ujq9TsIjMpQbIb41dQNkbZzg)0oSoWAHadwdRLV04LfivSSbj9b1gyjzOL69QuC5kavxucThKoY2lQUxLIJtmhGsO9G0r2EXCMXpTdRdSwiWG1WA5jS4KKYHQlkw2GS)dzOL69QuC5kavxucThKoY2lQUxLIJtmhGsO9G0r2EXCMXpTdRdSwiWG1WA5fwjTyaAqqTVS9LHwQ3RsXLRauDrj0Eq6iBVO6EvkooXCakH2dshz7fZzg)0oSoWAHadwdRLpPccxqrdLvGXGm0s9EvkUCfGQlkH2dshz7fv3RsXXjMdqj0Eq6iBVyoZ4N2H1bwleyWAyT8)bOwXUxbPQ0jgKHwQ3RsXLRauDrj0Eq6iBVO6EvkooXCakH2dshz7fZzg)0oSoWAHadwdRLxcK60aQUOUlmLurMalzLHwQjQ9kdLWbBHQ7vP44eZbOeApiDKTxuf39LS9chNyoaLq7bPlbjMg2Q7vP44eZbOWhCsaC2NXYvVxLIJtmhGcFWjbWjXetzFglxv)iQNVq8UCfGQlkH2dshe8(cKMnZ4N2HlxbO6IsO9G0Hp4Kay93S5NkbQVvKuOsC3xY2lCCI5aucThKUeKyAyNZm(PDyDG1cbgSgwlVxNxsJanujy7GdmidTuVxzOeoyluDVkfhNyoaLq7bPJS9IQ7vP4YvaQUOeApiDKTxuDVkfhNyoaf(GtcGZ(mwU69QuCCI5au4dojaojMyk7Zy5mB(PsG6BfjfQe39LS9chNyoaLq7bPlbjMg258CMXpTdRtQncsq812dQKeKYql1sTrqcI3rsTphyWh1NsK5mJFAhwNuBeKG4nSw(9LgYjdTul1gbjiEhj1(CGbFuFkrMZm(PDyDsTrqcI3WA5fsWcbguDrjrdY5mJFAhwNuBeKG4nSwEoXCakjQ1sVGDoZ4N2H1j1gbjiEdRLNtmhGQZ9CMXpTdRtQncsq8gwlVDjaz0gz9RFTg]] )


end
