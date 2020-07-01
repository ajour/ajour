-- WarlockAffliction.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


if UnitClassBase( 'player' ) == 'WARLOCK' then
    local spec = Hekili:NewSpecialization( 265, true )

    spec:RegisterResource( Enum.PowerType.SoulShards, {
        -- regen effects.
    }, setmetatable( {
        actual = nil,
        max = 5,
        active_regen = 0,
        inactive_regen = 0,
        forecast = {},
        times = {},
        values = {},
        fcount = 0,
        regen = 0,
        regenerates = false,
    }, {
        __index = function( t, k )
            if k == 'count' or k == 'current' then return t.actual

            elseif k == 'actual' then
                t.actual = UnitPower( "player", Enum.PowerType.SoulShards )
                return t.actual

            end
        end
    } ) )

    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        nightfall = 22039, -- 108558
        drain_soul = 23140, -- 198590
        deathbolt = 23141, -- 264106

        writhe_in_agony = 22044, -- 196102
        absolute_corruption = 21180, -- 196103
        siphon_life = 22089, -- 63106

        demon_skin = 19280, -- 219272
        burning_rush = 19285, -- 111400
        dark_pact = 19286, -- 108416

        sow_the_seeds = 19279, -- 196226
        phantom_singularity = 19292, -- 205179
        vile_taint = 22046, -- 278350

        darkfury = 22047, -- 264874
        mortal_coil = 19291, -- 6789
        demonic_circle = 19288, -- 268358

        shadow_embrace = 23139, -- 32388
        haunt = 23159, -- 48181
        grimoire_of_sacrifice = 19295, -- 108503

        soul_conduit = 19284, -- 215941
        creeping_death = 19281, -- 264000
        dark_soul_misery = 19293, -- 113860
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3498, -- 196029
        adaptation = 3497, -- 214027
        gladiators_medallion = 3496, -- 208683

        soulshatter = 13, -- 212356
        gateway_mastery = 15, -- 248855
        rot_and_decay = 16, -- 212371
        curse_of_shadows = 17, -- 234877
        nether_ward = 18, -- 212295
        essence_drain = 19, -- 221711
        endless_affliction = 12, -- 213400
        curse_of_fragility = 11, -- 199954
        curse_of_weakness = 10, -- 199892
        curse_of_tongues = 9, -- 199890
        casting_circle = 20, -- 221703
    } )

    -- Auras
    spec:RegisterAuras( {
        agony = {
            id = 980,
            duration = function () return 18 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) * haste end,
            type = "Curse",
            max_stack = function () return ( talent.writhe_in_agony.enabled and 15 or 10 ) end,
            meta = {
                stack = function( t )
                    if t.down then return 0 end
                    if t.count >= 10 then return t.count end

                    local app = t.applied
                    local tick = t.tick_time

                    local last_real_tick = now + ( floor( ( now - app ) / tick ) * tick )
                    local ticks_since = floor( ( query_time - last_real_tick ) / tick )

                    return min( 10, t.count + ticks_since )
                end,
            }
        },
        burning_rush = {
            id = 111400,
            duration = 3600,
            max_stack = 1,
        },
        corruption = {
            id = 146739,
            duration = function () return ( talent.absolute_corruption.enabled and ( target.is_player and 24 or 3600 ) or 14 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) * haste end,
            type = "Magic",
            max_stack = 1,
        },
        dark_pact = {
            id = 108416,
            duration = 20,
            max_stack = 1,
        },
        dark_soul_misery = {
            id = 113860,
            duration = 20,
            max_stack = 1,
        },
        demonic_circle = {
            id = 48018,
            duration = 900,
            max_stack = 1,
        },
        demonic_circle_teleport = {
            id = 48020,
        },
        drain_life = {
            id = 234153,
            duration = function () return 5 * haste end,
            max_stack = 1,
            tick_time = function () return haste end,
        },
        drain_soul = {
            id = 198590,
            duration = function () return 5 * haste end,
            max_stack = 1,
            tick_time = function () return haste end,
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
        grimoire_of_sacrifice = {
            id = 196099,
            duration = 3600,
            max_stack = 1,
        },
        haunt = {
            id = 48181,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        mortal_coil = {
            id = 6789,
            duration = 3.001,
            type = "Magic",
            max_stack = 1,
        },
        nightfall = {
            id = 264571,
            duration = 12,
            max_stack = 1,
        },
        phantom_singularity = {
            id = 205179,
            duration = 16,
            max_stack = 1,
        },
        ritual_of_summoning = {
            id = 698,
        },
        seed_of_corruption = {
            id = 27243,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },
        shadow_embrace = {
            id = 32390,
            duration = 10,
            type = "Magic",
            max_stack = 3,
        },
        shadowfury = {
            id = 30283,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        siphon_life = {
            id = 63106,
            duration = function () return 15 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 3 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
        },
        soul_leech = {
            id = 108366,
            duration = 15,
            max_stack = 1,
        },
        soul_shards = {
            id = 246985,
        },
        summon_darkglare = {
            id = 205180,
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
        unstable_affliction = {
            id = 233490,
            duration = function () return ( pvptalent.endless_affliction.enabled and 14 or 8 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
            copy = "unstable_affliction_1"
        },
        unstable_affliction_2 = {
            id = 233496,
            duration = function () return ( pvptalent.endless_affliction.enabled and 14 or 8 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
        },
        unstable_affliction_3 = {
            id = 233497,
            duration = function () return ( pvptalent.endless_affliction.enabled and 14 or 8 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
        },
        unstable_affliction_4 = {
            id = 233498,
            duration = function () return ( pvptalent.endless_affliction.enabled and 14 or 8 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
        },
        unstable_affliction_5 = {
            id = 233499,
            duration = function () return ( pvptalent.endless_affliction.enabled and 14 or 8 ) * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            tick_time = function () return 2 * ( talent.creeping_death.enabled and 0.85 or 1 ) end,
            type = "Magic",
            max_stack = 1,
        },
        active_uas = {
            alias = { "unstable_affliction_1", "unstable_affliction_2", "unstable_affliction_3", "unstable_affliction_4", "unstable_affliction_5" },
            aliasMode = 'longest',
            aliasType = 'debuff',
            duration = 8
        },
        vile_taint = {
            id = 278350,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },


        -- PvP Talents
        casting_circle = {
            id = 221705,
            duration = 3600,
            max_stack = 1,
        },
        curse_of_fragility = {
            id = 199954,
            duration = 10,
            max_stack = 1,
        },
        curse_of_shadows = {
            id = 234877,
            duration = 10,
            type = "Curse",
            max_stack = 1,
        },
        curse_of_tongues = {
            id = 199890,
            duration = 10,
            type = "Curse",
            max_stack = 1,
        },
        curse_of_weakness = {
            id = 199892,
            duration = 10,
            type = "Curse",
            max_stack = 1,
        },
        demon_armor = {
            id = 285933,
            duration = 3600,
            max_stack = 1,
        },
        essence_drain = {
            id = 221715,
            duration = 6,
            type = "Magic",
            max_stack = 5,
        },
        nether_ward = {
            id = 212295,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        soulshatter = {
            id = 236471,
            duration = 8,
            max_stack = 5,
        },


        -- Azerite Powers
        inevitable_demise = {
            id = 273525,
            duration = 20,
            max_stack = 50,
        },
    } )


    spec:RegisterHook( "TimeToReady", function( wait, action )
        local ability = action and class.abilities[ action ]

        if ability and ability.spend and ability.spendType == "soul_shards" and ability.spend > soul_shard then
            wait = 3600
        end

        return wait
    end )

    spec:RegisterStateExpr( "soul_shard", function () return soul_shards.current end )


    state.sqrt = math.sqrt

    spec:RegisterStateExpr( "time_to_shard", function ()
        local num_agony = active_dot.agony
        if num_agony == 0 then return 3600 end

        return 1 / ( 0.16 / sqrt( num_agony ) * ( num_agony == 1 and 1.15 or 1 ) * num_agony / debuff.agony.tick_time )
    end )


    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount, interrupt, a, b, c, d, offhand, multistrike, ... )
        if sourceGUID == GUID and spellName == "Seed of Corruption" then
            if subtype == "SPELL_CAST_SUCCESS" then
                action.seed_of_corruption.flying = GetTime()
            elseif subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_REFRESH" then
                action.seed_of_corruption.flying = 0
            end
        end
    end )


    spec:RegisterGear( 'tier21', 152174, 152177, 152172, 152176, 152173, 152175 )
    spec:RegisterGear( 'tier20', 147183, 147186, 147181, 147185, 147182, 147184 )
    spec:RegisterGear( 'tier19', 138314, 138323, 138373, 138320, 138311, 138317 )
    spec:RegisterGear( 'class', 139765, 139768, 139767, 139770, 139764, 139769, 139766, 139763 )

    spec:RegisterGear( 'amanthuls_vision', 154172 )
    spec:RegisterGear( 'hood_of_eternal_disdain', 132394 )
    spec:RegisterGear( 'norgannons_foresight', 132455 )
    spec:RegisterGear( 'pillars_of_the_dark_portal', 132357 )
    spec:RegisterGear( 'power_cord_of_lethtendris', 132457 )
    spec:RegisterGear( 'reap_and_sow', 144364 )
    spec:RegisterGear( 'sacrolashs_dark_strike', 132378 )
    spec:RegisterGear( 'sindorei_spite', 132379 )
    spec:RegisterGear( 'soul_of_the_netherlord', 151649 )
    spec:RegisterGear( 'stretens_sleepless_shackles', 132381 )
    spec:RegisterGear( 'the_master_harvester', 151821 )


    spec:RegisterStateFunction( "applyUnstableAffliction", function( duration )
        for i = 1, 5 do
            local aura = "unstable_affliction_" .. i

            if debuff[ aura ].down then
                applyDebuff( 'target', aura, duration or 8 )
                break
            end
        end
    end )


    local summons = {
        [18540] = true,
        [157757] = true,
        [1122] = true,
        [157898] = true
    }

    local last_sindorei_spite = 0

    spec:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED", function( _, unit, spell, _, spellID )
        if not UnitIsUnit( unit, "player" ) then return end

        local now = GetTime()

        if summons[ spellID ] then
            if now - last_sindorei_spite > 25 then
                last_sindorei_spite = now
            end
        end
    end )

    spec:RegisterHook( "reset_precast", function ()
        soul_shards.actual = nil

        local icd = 25

        if now - last_sindorei_spite < icd then
            cooldown.sindorei_spite_icd.applied = last_sindorei_spite
            cooldown.sindorei_spite_icd.expires = last_sindorei_spite + icd
            cooldown.sindorei_spite_icd.duration = icd
        end

        if debuff.drain_soul.up then            
            local ticks = debuff.drain_soul.ticks_remain
            if pvptalent.rot_and_decay.enabled then
                for i = 1, 5 do
                    if debuff[ "unstable_affliction_" .. i ].up then debuff[ "unstable_affliction_" .. i ].expires = debuff[ "unstable_affliction_" .. i ].expires + ticks end
                end
                if debuff.corruption.up then debuff.corruption.expires = debuff.corruption.expires + 1 end
                if debuff.agony.up then debuff.agony.expires = debuff.agony.expires + 1 end
            end
            if pvptalent.essence_drain.enabled and health.pct < 100 then
                addStack( "essence_drain", debuff.drain_soul.remains, debuff.essence_drain.stack + ticks )
            end
        end

        if buff.casting.up and buff.casting.v1 == 234153 then
            removeBuff( "inevitable_demise" )
        end

        if buff.casting_circle.up then
            applyBuff( "casting_circle", action.casting_circle.lastCast + 8 - query_time )
        end
    end )


    spec:RegisterStateExpr( "target_uas", function ()
        return buff.active_uas.stack
    end )

    spec:RegisterStateExpr( "contagion", function ()
        return max( debuff.unstable_affliction.remains, debuff.unstable_affliction_2.remains, debuff.unstable_affliction_3.remains, debuff.unstable_affliction_4.remains, debuff.unstable_affliction_5.remains )
    end )


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
        sindorei_spite_icd = {
            name = "Sindorei Spite ICD",
            cast = 0,
            cooldown = 25,
            gcd = "off",

            hidden = true,
            usable = function () return false end,
        },

        agony = {
            id = 980,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "agony", nil, max( azerite.sudden_onset.enabled and 4 or 1, debuff.agony.stack ) )
            end,
        },


        --[[ banish = {
            id = 710,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        burning_rush = {
            id = 111400,
            cast = 0,
            cooldown = 0,
            gcd = function () return buff.burning_rush.up and "off" or "spell" end,

            startsCombat = true,

            talent = "burning_rush",

            handler = function ()
                if buff.burning_rush.down then applyBuff( "burning_rush" )
                else removeBuff( "burning_rush" ) end
            end,
        },


        casting_circle = {
            id = 221703,
            cast = 0.5,
            cooldown = 60,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            pvptalent = "casting_circle",

            startsCombat = false,
            texture = 1392953,

            handler = function ()
                applyBuff( "casting_circle", 8 )
            end,
        },


        --[[ command_demon = {
            id = 119898,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        corruption = {
            id = 172,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "corruption" )
            end,
        },


        --[[ create_healthstone = {
            id = 6201,
            cast = 3,
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
            cast = 3,
            cooldown = 120,
            gcd = "spell",

            spend = 0.05,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        curse_of_fragility = {
            id = 199954,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            pvptalent = "curse_of_fragility",            

            startsCombat = true,
            texture = 132097,

            usable = function () return target.is_player end,
            handler = function ()
                applyDebuff( "target", "curse_of_fragility" )
                setCooldown( "curse_of_tongues", max( 6, cooldown.curse_of_tongues.remains ) )
                setCooldown( "curse_of_weakness", max( 6, cooldown.curse_of_weakness.remains ) )
            end,
        },


        curse_of_tongues = {
            id = 199890,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            pvptalent = "curse_of_tongues",

            startsCombat = true,
            texture = 136140,

            handler = function ()
                applyDebuff( "target", "curse_of_tongues" )
                setCooldown( "curse_of_fragility", max( 6, cooldown.curse_of_fragility.remains ) )
                setCooldown( "curse_of_weakness", max( 6, cooldown.curse_of_weakness.remains ) )
            end,
        },


        curse_of_weakness = {
            id = 199892,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            pvptalent = "curse_of_weakness",

            startsCombat = true,
            texture = 615101,

            handler = function ()
                applyDebuff( "target", "curse_of_weakness" )
                setCooldown( "curse_of_fragility", max( 6, cooldown.curse_of_fragility.remains ) )
                setCooldown( "curse_of_tongues", max( 6, cooldown.curse_of_tongues.remains ) )
            end,
        },


        dark_pact = {
            id = 108416,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,

            talent = "dark_pact",

            handler = function ()
                spend( 0.2 * health.current, "health" )
                applyBuff( "dark_pact" )
            end,
        },


        dark_soul = {
            id = 113860,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,

            talent = "dark_soul_misery",

            handler = function ()
                applyBuff( "dark_soul_misery" )
                stat.haste = stat.haste + 0.3
            end,

            copy = "dark_soul_misery"
        },


        deathbolt = {
            id = 264106,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            talent = "deathbolt",

            handler = function ()
                -- applies shadow_embrace (32390)
            end,
        },


        demon_armor = {
            id = 285933,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            pvptalent = "demon_armor",

            startsCombat = false,
            texture = 136185,

            handler = function ()
                applyBuff( "demon_armor" )
            end,
        },


        --[[ demonic_circle = {
            id = 48018,
            cast = 0.5,
            cooldown = 10,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

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

            handler = function ()
            end,
        },


        demonic_gateway = {
            id = 111771,
            cast = 2,
            cooldown = 10,
            gcd = "spell",

            spend = 0.2,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        devour_magic = {
            id = 19505,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            spend = 0,
            spendType = "mana",

            startsCombat = true,
            toggle = "interrupts",

            usable = function ()
                if buff.dispellable_magic.down then return false, "no dispellable magic aura" end
                return true
            end,

            handler = function()
                removeBuff( "dispellable_magic" )
            end,
        },


        drain_life = {
            id = 234153,
            cast = 5,
            channeled = true,
            breakable = true,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "mana",

            startsCombat = true,

            start = function ()
                removeBuff( "inevitable_demise" )
            end,
        },


        drain_soul = {
            id = 198590,
            cast = 5,
            cooldown = 0,
            gcd = "spell",

            channeled = true,
            prechannel = true,
            breakable = true,
            breakchannel = function () removeDebuff( "target", "drain_soul" ) end,

            spend = 0,
            spendType = "mana",

            startsCombat = true,

            talent = "drain_soul",

            start = function ()
                applyDebuff( "target", "drain_soul" )
                applyBuff( "casting", 5 * haste )
                channelSpell( "drain_soul" )
            end,
        },


        --[[ enslave_demon = {
            id = 1098,
            cast = 3,
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
            cast = 2,
            cooldown = 0,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        fear = {
            id = 5782,
            cast = 1.7,
            cooldown = 0,
            gcd = "spell",

            spend = 0.15,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "fear" )
            end,
        },


        grimoire_of_sacrifice = {
            id = 108503,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,

            usable = function () return pet.exists and buff.grimoire_of_sacrifice.down end,
            handler = function ()
                applyBuff( "grimoire_of_sacrifice" )
            end,
        },


        haunt = {
            id = 48181,
            cast = 1.5,
            cooldown = 15,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            talent = "haunt",

            handler = function ()
                applyDebuff( "target", "haunt" )
            end,
        },


        health_funnel = {
            id = 755,
            cast = 5,
            channeled = true,
            breakable = true,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,

            start = function ()
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

            talent = "mortal_coil",

            handler = function ()
                applyDebuff( "target", "mortal_coil" )
                gain( 0.2 * health.max, "health" )
            end,
        },


        nether_ward = {
            id = 212295,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = "nether_ward",

            startsCombat = false,
            texture = 135796,

            handler = function ()
                applyBuff( "nether_ward" )
            end,
        },


        phantom_singularity = {
            id = 205179,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,

            talent = "phantom_singularity",

            handler = function ()
                applyDebuff( "target", "phantom_singularity" )
            end,
        },


        --[[ ritual_of_summoning = {
            id = 698,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 0,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


        seed_of_corruption = {
            id = 27243,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            startsCombat = true,
            velocity = 30,

            usable = function () return dot.seed_of_corruption.down end,
            handler = function ()
                applyDebuff( "target", "seed_of_corruption" )
            end,
        },


        shadow_bolt = {
            id = 232670,
            cast = 2,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            velocity = 20,

            notalent = "drain_soul",
            cycle = function () return talent.shadow_embrace.enabled and "shadow_embrace" or nil end,

            handler = function ()
                if talent.shadow_embrace.enabled then
                    addStack( "shadow_embrace", 10, 1 )
                end
            end,
        },


        shadowfury = {
            id = 30283,
            cast = 1.5,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "shadowfury" )
            end,
        },


        siphon_life = {
            id = 63106,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            talent = "siphon_life",

            handler = function ()
                applyDebuff( "target", "siphon_life" )
            end,
        },


        soulshatter = {
            id = 212356,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",
            pvptalent = "soulshatter",

            startsCombat = true,
            texture = 135728,

            usable = function () return buff.active_uas.stack > 0 or active_dot.agony > 0 or active_dot.corruption > 0 or active_dot.siphon_life > 0 end,
            handler = function ()
                local targets = min( 5, max( buff.active_uas.stack, active_dot.agony, active_dot.corruption, active_dot.siphon_life ) )

                applyBuff( "soulshatter", nil, targets )
                stat.haste = stat.haste + ( 0.1 * targets )

                gain( targets, "soul_shards" )

                active_dot.agony = max( 0, active_dot.agony - targets )
                if active_dot.agony == 0 then removeDebuff( "target", "agony" ) end

                active_dot.corruption = max( 0, active_dot.corruption - targets )
                if active_dot.corruption == 0 then removeDebuff( "target", "corruption" ) end

                active_dot.siphon_life = max( 0, active_dot.siphon_life - targets )
                if active_dot.siphon_life == 0 then removeDebuff( "target", "siphon_life" ) end
            end,
        },


        soulstone = {
            id = 20707,
            cast = 3,
            cooldown = 600,
            gcd = "spell",

            startsCombat = false,

            handler = function ()
                applyBuff( "soulstone" )
            end,
        },


        spell_lock = {
            id = 19647,
            known = function () return IsSpellKnownOrOverridesKnown( 119910 ) or IsSpellKnownOrOverridesKnown( 132409 ) end,
            cast = 0,
            cooldown = 24,
            gcd = "off",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        summon_darkglare = {
            id = 205180,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
                summonPet( "darkglare", 20 )
            end,
        },


        summon_imp = {
            id = 688,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            usable = function () return not pet.alive end,
            handler = function () summonPet( "imp" ) end,
        },


        summon_voidwalker = {
            id = 697,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            usable = function () return not pet.alive end,
            handler = function () summonPet( "voidwalker" ) end,
        },


        summon_felhunter = {
            id = 691,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            essential = true,
            nomounted = true,

            bind = "summon_pet",

            usable = function ()
                if pet.alive then return false, "pet is alive"
                elseif buff.grimoire_of_sacrifice.up then return false, "grimoire_of_sacrifice is up" end
                return true
            end,
            handler = function () summonPet( "felhunter" ) end,

            copy = { "summon_pet", 112869 }
        },


        summon_succubus = {
            id = 712,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            usable = function () return not pet.alive end,
            handler = function () summonPet( "succubus" ) end,
        },


        unending_breath = {
            id = 5697,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = false,

            handler = function ()
                applyBuff( "unending_breath" )
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
                applyBuff( "unending_resolve" )
            end,
        },


        unstable_affliction = {
            id = 30108,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            startsCombat = true,

            handler = function ()
                applyUnstableAffliction()
                if azerite.dreadful_calling.enabled then
                    gainChargeTime( "summon_darkglare", 1 )
                end
            end,
        },


        vile_taint = {
            id = 278350,
            cast = 1.5,
            cooldown = 20,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "vile_taint" )
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

        potion = "unbridled_fury",

        package = "Affliction",
    } )


    spec:RegisterPack( "Affliction", 20200419, [[dCeemcqibYJuQIUekrSjI4tkvH0OqPCkusRcLWRqPAwevDlbGDr4xkvAycOJPewMsv9mvjMMauxtjQTjaY3eGyCOeLZjaP1HsuL5rK6EQI9ru5GcGQfQkPhQufQjkakxeLOsDsuIkzLcuZeLOQ6MkvHWovISuuIkEkLmvLkUQsvi6ROevL9kv)LIbJ4WKwmL6XcnzuDzOnlfFwknALYPv8AIKzdCBv1UL8BrdxqhxPky5Q8CKMovxhfBxj13vsgpkr68QsTELQ08jk7h09f9D6wC1X(s7h4(bgyaViGkcCX(lcC)UL)oe7wHAukTf7wL(XUvaEtdyI(Kv3kuFdsL33PBrtMlIDRn3dPS82D32X3ySfX8VlD(ma1NSIN247sNFC3ULnZaCwUQUD3IRo2xA)a3pWad4fburGlcmG8clRBrdXyFP9dql3T2gohRUD3IJ0y3ApHKa8MgWe9jliHLp9azukyW7jKS5EiLL3U72o(gJTiM)DPZNbO(Kv80gFx68J7cdEpHKG1IrV3qY(lKhs2pW9degmm49es2J30QfPS8GbVNqsaajb4CoYHeRqeaGew(ZOucyW7jKeaqsaoNJCijadxNmhKShH2orbm49escaiHLd(Z1ihsC9Ar3mncHag8EcjbaKWYb3dmZHqsawUdfsycHKSGexVw0HKM8GKamu9n7e4qcB0PIiKCyZH0nibKTtesgkKWNMg8WYHKPbs2JdWOqIEiKWhQAdqoRcyW7jKeaqclhmeOresO4A8uaK461IUWNpA80WhesIkfPqYQX3GeF(OXtdFqiHnS4qs2ajyftMYXJvr3k8YMbGDR9escWBAat0NSGew(0dKrPGbVNqYM7HuwE7UB74Bm2Iy(3LoFgG6twXtB8DPZpUlm49escWdVbajlcOYdj7h4(bcdgg8Ecj7XBA1IuwEWG3tijaGKaCoh5qIvicaqcl)zukbm49escaijaNZroKeGHRtMds2JqBNOag8EcjbaKWYb)5AKdjUETOBMgHqadEpHKaasy5G7bM5qijal3HcjmHqswqIRxl6qstEqsagQ(MDcCiHn6uresoS5q6gKaY2jcjdfs4ttdEy5qY0aj7Xbyuirpes4dvTbiNvbm49escaiHLdgc0icjuCnEkasC9Arx4ZhnEA4dcjrLIuiz14BqIpF04PHpiKWgwCijBGeSIjt54XQagmm49esy5MLIrgh5qIn2KhcjX8BRoKyJTtrfqsaEmIHofsQScGn9(nmairJ(KffsYc8wadEpHen6twur4HX8BR(tdqPsbdEpHen6twur4HX8BRo7p72Kjhg8EcjA0NSOIWdJ53wD2F2vzA)y5QpzbdwJ(KfveEym)2QZ(ZUuM)plti6WG1OpzrfHhgZVT6S)SB7n)Co0KngQgVPzIO8tZJRaSCr7n)Co0KngQgVPzIOal1gGCyW7jKOrFYIkcpmMFB1z)zxAPH0T0nuxDkmyn6twur4HX8BRo7p7gM(Kfmyn6twur4HX8BRo7p7YqrZ44x(s)4JUx6MEk10KLBYgtyUcpyWA0NSOIWdJ53wD2F2LIi3KnMyEhtOpzj)08qdraW461IovqrKBYgtmVJj0NSmAIY98IKGW9aZegICXIaua9Lfbmmyn6twur4HX8BRo7p7UPmLddwJ(KfveEym)2QZ(ZU0nLNRm2jWLFAEcYvawUytzkxGLAdqUeAicagxVw0PckICt2yI5DmH(KLrtu6xKeeUhyMWqKlweGcOVSiGHbddEpHewUzPyKXroKGRX7nK4ZhHeFdHen65bjdfs016auBakGbRrFYI(qdraWaYOuWG1Opzrz)zxoUozoZxBNimyn6twu2F2DTEJAdq5l9Jpmu0qrKl)AfWGpUcWYf0CLX3qdfrovGLAdqUeAicagxVw0PckICt2yI5DmH(KLrtuUNxy)0HBW1y5IPwZak8uBakycLjZvawUGoHBzzatdkWsTbixcnebaJRxl6ubfrUjBmX8oMqFYsUNLz)0HBW1y5IPwZak8uBakycLjJgIaGX1RfDQGIi3KnMyEhtOpzj3dlJ9thUbxJLlMAndOWtTbOGjegSg9jlk7p7UwVrTbO8L(XNqLZNQv(m8HIU8Rvad(OrFYsq3uEUYyNaxGSumY4OXNpYcDV4nokIknQ8PAnrfO)XFlWsTbihgSg9jlk7p7UwVrTbO8L(XNqLZNQv(m85qk6YVwbm4tBKl)08O7fVXrruPrLpvRjQa9p(BbwQna5syZvawUGF6ugAYaeyP2aKltMRaSCbhvFZobUal1gGCjXmb8Cvj4O6B2jWfh(1POs)0g5ScdwJ(KfL9NDxR3O2au(s)4ZxNY1Pmuu(1kGbFOHiayC9ArNkOiYnzJjM3Xe6twgnrPFwWURaSCXQB8n0mLrBZ6Tal1gGC2DfGLluBAcyC0eZ7yc9jlbwQna5SyF2zZvawUy1n(gAMYOTz9wGLAdqUexby5cAUY4BOHIiNkWsTbixcnebaJRxl6ubfrUjBmX8oMqFYYOjk3(SYoBUcWYf0jClldyAqbwQna5scYvawUiEigovRHJQVjWsTbixsqUcWYf8tNYqtgGal1gGCwz)0HBW1y5IPwZak8uBakycHbRrFYIY(ZUR1BuBakFPF8HNo1Wek)AfWGpSfKRaSCbDc3YYaMguGLAdqUmz80f0jClldyAqbtiRs4Pl02SElOUgLsUNfbkjiE6cTnR3IdBoKUP2aucpDrmVJj0NSemHWG1Opzrz)z3Ocagn6twgWqD5l9JpXmb8CvrHbRrFYIY(ZU8tNYqtgG8t54DmHUPfK2k4zH8XnDQNfYhFhbOX1RfD6Zc5NMhF(OXtdFqPFAJCj0KbyOB6XLEzyWA0NSOS)S7MYuU8tZdnebaJRxl6ubfrUjBmX8oMqFYYOjk9Z(SF6Wn4ASCXuRzafEQnafmHWG1Opzrz)zxkZ)NLHRNuTa9q5NMhE6cTnR3cFIsnvReE6IyEhtOpzj8jk1uTsyZMPPrOrFwJggLkOUgL6zzzYOjdWq30J)eOmz80fHBA553qNQLbO34Vfh(1POs4Plc30YZVHovldqVXFlo8RtrL(PnYzvcBb5kalxeUPLNFdDQwgGEJ)wGLAdqUmz80fHBA553qNQLbO34Vfh(1POSkHTGCfGLl4O6B2jWfyP2aKltwmtapxvcoQ(MDcCXHFDkQ0pTrUmzbfZeWZvLGJQVzNaxC4xNIktgnzag6ME8NaLqdraW461IovqrKBYgtmVJj0NSmAIYTG9thUbxJLlMAndOWtTbOGjKvyWA0NSOS)SlhvFZobU8tZtmtapxvckZ)NLHRNuTa9qXHFDkQK16nQnaf80PgMqj0qeamUETOtfue5MSXeZ7yc9jlJM4Zc2pD4gCnwUyQ1mGcp1gGcMqjSfesPyfrX6HozzYgtiEny0NSe)PYtsq6EXBCuWpu5nmatubGPAfNwsjtwmtapxvckZ)NLHRNuTa9qXHFDkQCVeiRWG1Opzrz)zxFdnmLDYuCttEru(P5XMPPrCyukasPMM8IO4WVoffgSg9jlk7p7QTz9w(47ianUETOtFwi)08C4xNIk9tBKZUg9jlbDt55kJDcCbYsXiJJgF(OeF(OXtdFq5yzWG1Opzrz)z3p(Z7TjBmaM4Wn8d1pv(P5XNpk9lbcdEpHKDWFyE69gsAgwkK4jK8vPqiHYCiKO7LUPNUhLcjnz5qcprATh1He7dvPGeUEs1c0dHegQ2IcyWA0NSOS)SR2M1B5btHMi)5LaLFAE85JY9sGsIzc45Qsqz()SmC9KQfOhko8RtrL(zXYsW9aZegICXIaua9Lfbmmyn6twu2F2nM3Xe6twYdMcnr(Zlbk)084ZhL7LaLeZeWZvLGY8)zz46jvlqpuC4xNIk9ZILLG7bMjme5IfbOa6llcyjb5kalxO20eW4OjM3Xe6twcSuBaYLWMRaSCbDc3YYaMguGLAdqUmz0qeamUETOtfue5MSXeZ7yc9jlJMOClKqdraW461IovqrKBYgtmVJj0NSmAIs)8cRWG1Opzrz)zx6eULLbmnO8GPqtK)8sGYpnp(8r5EjqjXmb8CvjOm)FwgUEs1c0dfh(1POs)Syzj4EGzcdrUyrakG(YIaggSg9jlk7p7YuuxTbOrBAat0NSKp(ocqJRxl60NfYpnpbfZY12jlj(8rJNg(Gs)WYGbRrFYIY(ZU8tNYqtgG8X3raAC9ArN(Sq(OwreyMMhFIsrnh(1PKEz5NMhxby5c6MYZvg8BFAefyP2aKlzTEJAdqXxNY1PmuuchTzAAe0nLNRm43(0iko8RtrLWrBMMgbDt55kd(TpnIId)6uuPFAJCwSpmyn6twu2F2LUP8CLXobU8X3raAC9ArN(Sq(P5XvawUGUP8CLb)2NgrbwQna5swR3O2au81PCDkdfLWrBMMgbDt55kd(TpnIId)6uujC0MPPrq3uEUYGF7tJO4WVofv6hKLIrghn(8rwSp7(PRrGXNpkjin6twc6MYZvg7e4IPmnGPDZHbRrFYIY(ZUHBA553qNQLbO34VLp(ocqJRxl60NfYpnp(8r5EzzjUETOl85Jgpn8bLBraIf0qeamBk1rjSfesPyfrX6HozzYgtiEny0NSe)PYtsq6EXBCuWpu5nmatubGPAfNwsjtwmtapxvckZ)NLHRNuTa9qXHFDkQCb8YSttgGHUPhNf6EXBCuWpu5nmatubGPAfNwsjtwmtapxvckZ)NLHRNuTa9qXHFDkQ0lwMf0qeamBk1r2PjdWq30JZcDV4nok4hQ8ggGjQaWuTItlPyfgSg9jlk7p7YuuxTbOrBAat0NSKp(ocqJRxl60NfYpnpbTwVrTbOGHIgkICj0KbyOB6XFwggSg9jlk7p7srKBYgtmVJj0NSKFAEwR3O2auWqrdfrUeAYam0n94plddwJ(KfL9NDJkay0Opzzad1LV0p(WtNcdwJ(KfL9NDxpa046uU8X3raAC9ArN(Sq(P5XNpk3ILL4ZhnEA4dk3ZIaLWwmtapxvckZ)NLHRNuTa9qXHFDkQCVeOmzXmb8CvjOm)FwgUEs1c0dfh(1POsViqj80fABwVfh(1POY9Siqj80fX8oMqFYsC4xNIk3ZIaLWgpDbDc3YYaMguC4xNIk3ZIaLjlixby5c6eULLbmnOal1gGCwzfgSg9jlk7p7YqrZ44x(s)4JUx6MEk10KLBYgtyUcp5NMhF(O0pVadwJ(KfL9NDd30YZVHovldqVXFl)084ZhL(5LLHbRrFYIY(ZURhaACDkx(P5XNpk9ILHbRrFYIY(ZUTm6XhTmzJr3lEPVj)08WwmtapxvckZ)NLHRNuTa9qXHFDkQ0lwMDAYam0n94Sq3lEJJc(HkVHbyIkamvRal1gGCzYyt3lEJJc(HkVHbyIkamvR40skzYqkfRikwp0jlt2ycXRbJ(KL40skwL4ZhL7LaL4ZhnEA4dk3Z(lcKvjSXtxeUPLNFdDQwgGEJ)wC4xNIktgpDX6bGgxNYfh(1POYKfKRaSCr4MwE(n0PAza6n(BbwQna5scYvawUy9aqJRt5cSuBaYzvMmF(OXtdFqPFjq2BJCyWA0NSOS)SlxpPm0Kbi)08eZeWZvLGY8)zz46jvlqpuC4xNIk9ILzNMmadDtpol09I34OGFOYByaMOcat1kWsTbixcB80fHBA553qNQLbO34Vfh(1POYKXtxSEaOX1PCXHFDkkRWG1Opzrz)zxB8O4j1uTWG1Opzrz)z3Ocagn6twgWqD5l9Jp0qS44rHbRrFYIY(ZUrfamA0NSmGH6Yx6hFAgaapkmyyWA0NSOIyMaEUQOpRYdWxJtzoKMLwregSg9jlQiMjGNRkk7p7YqrZ44x(s)4JUx6MEk10KLBYgtyUcp5NMh2cYvawUiCtlp)g6uTma9g)Tal1gGCzYIzc45QseUPLNFdDQwgGEJ)wC4xNIkDaZcAicaMnL6OmzbfZeWZvLiCtlp)g6uTma9g)T4WVofLvjXmb8CvjOm)FwgUEs1c0dfh(1POsViGYcAicaMnL6i70KbyOB6XzHUx8ghf8dvEddWevayQwXPLus4Pl02SElo8RtrLWtxeZ7yc9jlXHFDkQe24PlOt4wwgW0GId)6uuzYcYvawUGoHBzzatdkWsTbiNvyWA0NSOIyMaEUQOS)SBy6twYpnpS5kalxW1tkdnzaM)qX7Tal1gGCjXmb8CvjOm)FwgUEs1c0dfmHsIzc45QsW1tkdnzacMqwLjlMjGNRkbL5)ZYW1tQwGEOGjuMmF(OXtdFqPFjqyWA0NSOIyMaEUQOS)SldfnJJFQ8tZtmtapxvckZ)NLHRNuTa9qXHFDkQCbKaLjZNpA80Whu69duMm2yZMPPrOrFwJggLkOUgL6zzzYOjdWq30J)eiRsylixby5IWnT88BOt1Ya0B83cSuBaYLjlMjGNRkr4MwE(n0PAza6n(BXHFDkkRsylixby5coQ(MDcCbwQna5YKfZeWZvLGJQVzNaxC4xNIk9tBKltwqXmb8Cvj4O6B2jWfh(1POSkjOyMaEUQeuM)pldxpPAb6HId)6uuwHbRrFYIkIzc45QIY(ZUnZH2Gm5YpnpbfZeWZvLGY8)zz46jvlqpuWecdwJ(KfveZeWZvfL9NDTbzYnnm3B5NMNGIzc45Qsqz()SmC9KQfOhkycHbRrFYIkIzc45QIY(ZUF8N3Bt2yamXHB4hQFQ8tZJpFuUxcegSg9jlQiMjGNRkk7p7Y1tkdnzaYpnp(8rJNg(GsVFGS3g5YK5kalxqZvgFdnue5ubwQna5sIzc45Qsqz()SmC9KQfOhko8RtrL7jMjGNRkbL5)ZYW1tQwGEOGZCQpzfalcegSg9jlQiMjGNRkk7p7AdYKBYgJVHgSW)B5NMNq0fC9KQfOhko8RtrLjJTGIzc45QsWr13StGlo8RtrLjlixby5coQ(MDcCbwQna5SkjMjGNRkbL5)ZYW1tQwGEO4WVofvUhwwGsqkfRikSbzYnzJX3qdw4)T40sk5wadEpHK9iPiKW1V2ovlKKvaWqriXVPKcDkK8ZdHK8GeasPqswqsmtapxvYdj0esaz1cjkfs8nesy5Apoads8n8nKmvK5GKvzTh1HeSPbJoKO1Bij9n8Ge)Msk0PqcdvBriHZCt1cjXmb8CvrfWG1OpzrfXmb8Cvrz)zxgkAgh)Yx6hFcZOuOtN9ICtm)HmU6twgoUEIO8tZdBXmb8CvjOm)FwgUEs1c0dfh(1POY9S)YYK5ZhnEA4dk9ZlbYQe2Izc45QsWr13StGlo8RtrLjlixby5coQ(MDcCbwQna5ScdwJ(KfveZeWZvfL9NDzOOzC8lFPF85spEmuh5M1zYZ0Wtaq(P5HTyMaEUQeuM)pldxpPAb6HId)6uu5E2FzzY85Jgpn8bL(5LazvcBXmb8Cvj4O6B2jWfh(1POYKfKRaSCbhvFZobUal1gGCwHbRrFYIkIzc45QIY(ZUmu0mo(LV0p(q3M14zwJv(nhcMO8tZdBXmb8CvjOm)FwgUEs1c0dfh(1POY9S)YYK5ZhnEA4dk9ZlbYQe2Izc45QsWr13StGlo8RtrLjlixby5coQ(MDcCbwQna5ScdwJ(KfveZeWZvfL9NDzOOzC8lFPF8r3dmty6y5Msz8bWqLFAEylMjGNRkbL5)ZYW1tQwGEO4WVofvUN9xwMmF(OXtdFqPFEjqwLWwmtapxvcoQ(MDcCXHFDkQmzb5kalxWr13StGlWsTbiNvyWA0NSOIyMaEUQOS)SldfnJJF5l9Jp(WrQN33etoYsLFAEylMjGNRkbL5)ZYW1tQwGEO4WVofvUN9xwMmF(OXtdFqPFEjqwLWwmtapxvcoQ(MDcCXHFDkQmzb5kalxWr13StGlWsTbiNvyWA0NSOIyMaEUQOS)SldfnJJF5l9JpRhfyYgd1Z7tLFAEylMjGNRkbL5)ZYW1tQwGEO4WVofvUN9xwMmF(OXtdFqPFEjqwLWwmtapxvcoQ(MDcCXHFDkQmzb5kalxWr13StGlWsTbiNvyWA0NSOIyMaEUQOS)S7nHHa0mLHgQregmmyn6twub32CyZH0Th6eULLbmnO8GPqtK)Syz5NMh24PlOt4wwgW0GId)6uuwcpDbDc3YYaMguWzo1NSyv6h24Pl02SElo8Rtrzj80fABwVfCMt9jlwLWgpDbDc3YYaMguC4xNIYs4PlOt4wwgW0GcoZP(KfRs)WgpDrmVJj0NSeh(1POSeE6IyEhtOpzj4mN6twSkHNUGoHBzzatdko8RtrLMNUGoHBzzatdk4mN6twSyH4fyWA0NSOcUT5WMdPBS)SR2M1B5btHMi)zXYYpnpSXtxOTz9wC4xNIYs4Pl02SEl4mN6twSk9dB80fX8oMqFYsC4xNIYs4PlI5DmH(KLGZCQpzXQe24Pl02SElo8Rtrzj80fABwVfCMt9jlwL(HnE6c6eULLbmnO4WVofLLWtxqNWTSmGPbfCMt9jlwLWtxOTz9wC4xNIknpDH2M1BbN5uFYIfleVadwJ(KfvWTnh2CiDJ9NDJ5DmH(KL8GPqtK)Syz5NMh24PlI5DmH(KL4WVofLLWtxeZ7yc9jlbN5uFYIvPFyJNUqBZ6T4WVofLLWtxOTz9wWzo1NSyvcB80fX8oMqFYsC4xNIYs4PlI5DmH(KLGZCQpzXQ0pSXtxqNWTSmGPbfh(1POSeE6c6eULLbmnOGZCQpzXQeE6IyEhtOpzjo8RtrLMNUiM3Xe6twcoZP(KflwiEbgmmyn6twubpD6dfrUjBmX8oMqFYs(P5HNUiM3Xe6twId)6uuPF0OpzjOiYnzJjM3Xe6twIOsDJpFKDF(OXtdDtpo7bSyFwW2IaWvawUiEigovRHJQVjWsTbiNfbkwSmRsOHiayC9ArNkOiYnzJjM3Xe6twgnr5EEH9thUbxJLlMAndOWtTbOGjKDxby5Iv34BOzkJ2M1BbwQna5scINUGIi3KnMyEhtOpzjo8RtrLeKg9jlbfrUjBmX8oMqFYsmLPbmTBomyn6twubpDk7p7QTz9w(47ianUETOtFwi)084kalxepedNQ1Wr13eyP2aKlrJ(Sgn80fABwVLoajXNpA80WhuUfbkHTd)6uuPFAJCzYIzc45Qsqz()SmC9KQfOhko8RtrLBrGsy7WVofv6LLjliDV4nokc1IJ)jAMADgvFYsCAjLKdBoKUP2aKvwHbRrFYIk4Ptz)zxTnR3YhFhbOX1RfD6Zc5NMNGCfGLlIhIHt1A4O6BcSuBaYLOrFwJgE6cTnR3sZYK4ZhnEA4dk3IaLW2HFDkQ0pTrUmzXmb8CvjOm)FwgUEs1c0dfh(1POYTiqjSD4xNIk9YYKfKUx8ghfHAXX)entToJQpzjoTKsYHnhs3uBaYkRWG1Opzrf80PS)SlDc3YYaMgu(47ianUETOtFwi)08WMg9znA4PlOt4wwgW0GsZYcaxby5I4Hy4uTgoQ(Mal1gG8aGgIaGX1RfDQGMRm(gAOiYPgnrwL4ZhnEA4dk3IaLCyZH0n1gGsylOd)6uuj0qeamUETOtfue5MSXeZ7yc9jlJM4ZczYIzc45Qsqz()SmC9KQfOhko8RtrLJMmadDtpol0OpzjykQR2a0OnnGj6twcKLIrghn(8rwHbRrFYIk4Ptz)z3yEhtOpzjF8DeGgxVw0PplKFAEOHiayC9ArNkOiYnzJjM3Xe6twgnrPFH9thUbxJLlMAndOWtTbOGjKDxby5Iv34BOzkJ2M1BbwQna5sy7WVofv6N2ixMSyMaEUQeuM)pldxpPAb6HId)6uu5weOKdBoKUP2aKvjUETOl85Jgpn8bLBrGWGHbRrFYIkAgaap6dtrD1gGgTPbmrFYsEWuOjYFwSS8tZtmtapxvcoQ(MDcCXHFDkQ0pTrol2xcnebaJRxl6ubfrUjBmX8oMqFYYOj(SG9thUbxJLlMAndOWtTbOGjusmtapxvckZ)NLHRNuTa9qXHFDkQC7himyn6twurZaa4rz)z3Ocagn6twgWqD5l9JpCBZHnhs3KFAECfGLl4O6B2jWfyP2aKlHgIaGX1RfDQGIi3KnMyEhtOpzz0eFwW(Pd3GRXYftTMbu4P2auWekHnE6cTnR3Id)6uuP5Pl02SEl4mN6twSiqrazzzY4PlI5DmH(KL4WVofvAE6IyEhtOpzj4mN6twSiqrazzzY4PlOt4wwgW0GId)6uuP5PlOt4wwgW0GcoZP(KflcueqwMvjXmb8Cvj4O6B2jWfh(1POs)OrFYsOTz9w0g5SiGLeZeWZvLGY8)zz46jvlqpuC4xNIk3(bcdwJ(Kfv0maaEu2F2nQaGrJ(KLbmux(s)4d32CyZH0n5NMhxby5coQ(MDcCbwQna5sOHiayC9ArNkOiYnzJjM3Xe6twgnXNfSF6Wn4ASCXuRzafEQnafmHsIzc45Qsqz()SmC9KQfOhko8RtrL(HMmadDtpol0Opzj02SElAJC21Opzj02SElAJCw8Ie24Pl02SElo8RtrLMNUqBZ6TGZCQpzXIfYKXtxeZ7yc9jlXHFDkQ080fX8oMqFYsWzo1NSyXczY4PlOt4wwgW0GId)6uuP5PlOt4wwgW0GcoZP(KflwWkmyn6twurZaa4rz)zxoQ(MDcC5NMN16nQnaf80PgMqjSfZeWZvLGY8)zz46jvlqpuC4xNIk3ZlbYEBKltwmtapxvckZ)NLHRNuTa9qXHFDkQClc4azfgSg9jlQOzaa8OS)SlDt55kJDcC5NMhBMMgXpxJFSCbtOeBMMgrnTBEJcaId)6uuyWA0NSOIMbaWJY(ZUABwVLFAESzAAe)Cn(XYfmHscInxby5c6eULLbmnOal1gGCjSfE4AtBKlwi02SElj8W1M2ixSVqBZ6TKWdxBAJCXlcTnR3Sktw4HRnTrUyHqBZ6nRWG1OpzrfndaGhL9NDPt4wwgW0GYpnp2mnnIFUg)y5cMqjbXw4HRnTrUyHGoHBzzatdkj8W1M2ixSVGoHBzzatdkj8W1M2ix8IGoHBzzatdYkmyn6twurZaa4rz)z3yEhtOpzj)08yZ00i(5A8JLlycLeu4HRnTrUyHiM3Xe6twscYvawUqTPjGXrtmVJj0NSeyP2aKddwJ(Kfv0maaEu2F2LF6ugW0GYpnp2mnnIPW1JR2a0WX)qrb11OuYTiqj(8rJNg(Gs)SiqyWA0NSOIMbaWJY(ZU8tNYaMgu(P5XvawUGoHBzzatdkWsTbixInttJykC94QnanC8puuqDnkLCplhyaSFGSGnAicagxVw0PckICt2yI5DmH(KLrtmaoD4gCnwUyQ1mGcp1gGcMq5E2Nvj80fABwVfh(1POYTmlOHiay2uQJs4PlI5DmH(KL4WVofvU2ixcB80f0jClldyAqXHFDkQCTrUmzb5kalxqNWTSmGPbfyP2aKZQe24OnttJytzkxC4xNIk3YSGgIaGztPoktwqUcWYfBkt5cSuBaYzvsmlxBNSKBzwqdraWSPuhHbRrFYIkAgaapk7p7YpDkdyAq5NMhxby5Iv34BOzkJ2M1BbwQna5sSzAAetHRhxTbOHJ)HIcQRrPK7z5adG9dKfSrdraW461IovqrKBYgtmVJj0NSmAIbWPd3GRXYftTMbu4P2auWek3ZlSgalZc2OHiayC9ArNkOiYnzJjM3Xe6twgnXa40HBW1y5IPwZak8uBakycF2Nvj80fABwVfh(1POYTmlOHiay2uQJs4PlI5DmH(KL4WVofvU2ixcBC0MPPrSPmLlo8RtrLBzwqdraWSPuhLjlixby5InLPCbwQna5SkjMLRTtwYTmlOHiay2uQJWG1OpzrfndaGhL9ND5NoLbmnO8tZJRaSCHAttaJJMyEhtOpzjWsTbixInttJykC94QnanC8puuqDnkLCplhyaSFGSGnAicagxVw0PckICt2yI5DmH(KLrtmaoD4gCnwUyQ1mGcp1gGcMq5EcywLWtxOTz9wC4xNIk3YSGgIaGztPokHnoAZ00i2uMYfh(1POYTmlOHiay2uQJYKfKRaSCXMYuUal1gGCwLeZY12jl5wMf0qeamBk1ryWA0NSOIMbaWJY(ZUBkt5WG1OpzrfndaGhL9NDBYidf5gDV4noASr9ddwJ(Kfv0maaEu2F2nK5MM3t1ASbk1HbRrFYIkAgaapk7p7gZkILFQJCtdq)O8tZtq80fXSIy5N6i30a0pASzUsC4xNIkjin6twIywrS8tDKBAa6hftzAat7MddwJ(Kfv0maaEu2F2LF6ugAYaKFkhVJj0nTG0wbplKpUPt9Sq(PC8oMq)zH8X3raAC9ArN(Sq(P5XNpA80Whu6N2ihgSg9jlQOzaa8OS)Sl)0Pm0KbiF8DeGgxVw0PplKpUPt9Sq(PC8oMq3mnp(eLIAo8Rtj9YYpLJ3Xe6MwqARGNfYpnpUcWYf0nLNRm43(0ikWsTbixYA9g1gGIVoLRtzOOKG4OnttJGUP8CLb)2NgrXHFDkkmyn6twurZaa4rz)zx(PtzOjdq(47ianUETOtFwiFCtN6zH8t54DmHUzAE8jkf1C4xNs6LLFkhVJj0nTG0wbplKFAECfGLlOBkpxzWV9PruGLAdqUK16nQnafFDkxNYqryWA0NSOIMbaWJY(ZU8tNYqtgG8t54DmHUPfK2k4zH8XnDQNfYpLJ3Xe6plGbRrFYIkAgaapk7p7s3uEUYyNax(47ianUETOtFwi)084kalxq3uEUYGF7tJOal1gGCjR1BuBak(6uUoLHIscIJ2mnnc6MYZvg8BFAefh(1POscsJ(KLGUP8CLXobUyktdyA3CyWA0NSOIMbaWJY(ZU0nLNRm2jWLp(ocqJRxl60NfYpnpUcWYf0nLNRm43(0ikWsTbixYA9g1gGIVoLRtzOimyn6twurZaa4rz)zx6MYZvg7e4WGHbRrFYIkOHyXXJ(WuuxTbOrBAat0NSKFAEIzc45Qsqz()SmC9KQfOhko8RtrL(HMmadDtpolydzPyKXrJpFKDDV4nok4hQ8ggGjQaWuTItlPyvcBb5kalxWr13StGlWsTbixMSyMaEUQeCu9n7e4Id)6uuPFOjdWq30JZcKLIrghn(8rwLWMRaSCbnxz8n0qrKtfyP2aKltgpDr4MwE(n0PAza6n(BXHFDkQmz80fRhaACDkxC4xNIYkmyn6twubneloEu2F2nQaGrJ(KLbmux(s)4tZaa4rLFAEylMjGNRkbL5)ZYW1tQwGEO4WVofvAF(OXtdDtpolyB5aGMmadDtpoRYKfZeWZvLGY8)zz46jvlqpuWeYQeF(OXtdFq5Izc45Qsqz()SmC9KQfOhko8RtrHbRrFYIkOHyXXJY(ZUue5MSXeZ7yc9jl5NMN16nQnafmu0qrKddwJ(KfvqdXIJhL9NDzkQR2a0OnnGj6twYpnpbTwVrTbOGHIgkICjbfE4AtBKlwiOm)FwgUEs1c0dLWMRaSCbhvFZobUal1gGCjXmb8Cvj4O6B2jWfh(1POs)GSumY4OXNpkjiDV4nokIknQ8PAnrfO)XFlWsTbixMm2OjdWq30Jl3ZYsOHiayC9ArNkOiYnzJjM3Xe6twgnrP3xMmAYam0n94Y9SVeAicagxVw0PckICt2yI5DmH(KLrtuUN9zvIRxl6cF(OXtdFq5cy2rwkgzC04ZhLqdraW461IovqrKBYgtmVJj0NSmAIplKjZNpA80Whu6hwg7ilfJmoA85JSGMmadDtpoRWG1Opzrf0qS44rz)zxMI6QnanAtdyI(KL8tZtqR1BuBakyOOHIixsmlxBNSK(jQu34ZhzFTEJAdqrOY5t1cdwJ(KfvqdXIJhL9NDzkQR2a0OnnGj6twYhFhbOX1RfD6Zc5NMNGwR3O2auWqrdfrUe2cYvawUGJQVzNaxGLAdqUmzXmb8Cvj4O6B2jWfh(1POY5ZhnEAOB6XLjJMmadDtpUClyvcBb5kalxSEaOX1PCbwQna5YKrtgGHUPhxUfSkjMLRTtws)evQB85JSVwVrTbOiu58PALWwq6EXBCuevAu5t1AIkq)J)wGLAdqUmz2mnnIOsJkFQwtub6F83Id)6uu585Jgpn0n94S2TwJhDYQV0(bUFGbUy)aUBTsVAQwA3ILRFyEoYHKacKOrFYcsad1PcyWDlWqDAFNUf32CyZH0T(o9Lw03PBHLAdqE)1ULg9jRUfDc3YYaMgSBfVXXB0UfBqcpDbDc3YYaMguC4xNIcjSeiHNUGoHBzzatdk4mN6twqcRqI0pqcBqcpDH2M1BXHFDkkKWsGeE6cTnR3coZP(KfKWkKibsyds4PlOt4wwgW0GId)6uuiHLaj80f0jClldyAqbN5uFYcsyfsK(bsyds4PlI5DmH(KL4WVoffsyjqcpDrmVJj0NSeCMt9jliHvircKWtxqNWTSmGPbfh(1POqI0qcpDbDc3YYaMguWzo1NSGewajleV0TatHMiVBTy5U3xA)(oDlSuBaY7V2T0Opz1T02SE3TI344nA3IniHNUqBZ6T4WVoffsyjqcpDH2M1BbN5uFYcsyfsK(bsyds4PlI5DmH(KL4WVoffsyjqcpDrmVJj0NSeCMt9jliHvircKWgKWtxOTz9wC4xNIcjSeiHNUqBZ6TGZCQpzbjScjs)ajSbj80f0jClldyAqXHFDkkKWsGeE6c6eULLbmnOGZCQpzbjScjsGeE6cTnR3Id)6uuirAiHNUqBZ6TGZCQpzbjSaswiEPBbMcnrE3AXYDVV0l9D6wyP2aK3FTBPrFYQBfZ7yc9jRUv8ghVr7wSbj80fX8oMqFYsC4xNIcjSeiHNUiM3Xe6twcoZP(KfKWkKi9dKWgKWtxOTz9wC4xNIcjSeiHNUqBZ6TGZCQpzbjScjsGe2GeE6IyEhtOpzjo8RtrHewcKWtxeZ7yc9jlbN5uFYcsyfsK(bsyds4PlOt4wwgW0GId)6uuiHLaj80f0jClldyAqbN5uFYcsyfsKaj80fX8oMqFYsC4xNIcjsdj80fX8oMqFYsWzo1NSGewajleV0TatHMiVBTy5U39UfhBugG33PV0I(oDln6twDlAicagqgLQBHLAdqE)1U3xA)(oDln6twDloUozoZxBNy3cl1gG8(RDVV0l9D6wyP2aK3FTBLHDlk6Dln6twDR16nQna7wRvad2TCfGLlO5kJVHgkICQal1gGCircKqdraW461IovqrKBYgtmVJj0NSmAIqICpqYlqc7qYPd3GRXYftTMbu4P2auWecjYKbjUcWYf0jClldyAqbwQna5qIeiHgIaGX1RfDQGIi3KnMyEhtOpzbjY9ajldjSdjNoCdUglxm1AgqHNAdqbtiKitgKqdraW461IovqrKBYgtmVJj0NSGe5EGewgKWoKC6Wn4ASCXuRzafEQnafmHDR16zk9JDlgkAOiY7EFPaUVt3cl1gG8(RDRmSBrrVBPrFYQBTwVrTby3ATcyWULg9jlbDt55kJDcCbYsXiJJgF(iKWcir3lEJJIOsJkFQwtub6F83cSuBaY7wR1Zu6h7wHkNpvB37lTCFNUfwQna59x7wzy36qk6Dln6twDR16nQna7wRvad2TAJ8Uv8ghVr7w6EXBCuevAu5t1AIkq)J)wGLAdqoKibsydsCfGLl4NoLHMmabwQna5qImzqIRaSCbhvFZobUal1gGCircKeZeWZvLGJQVzNaxC4xNIcjs)ajTroKWA3ATEMs)y3ku58PA7EFPauFNUfwQna59x7wzy3IIE3sJ(Kv3ATEJAdWU1AfWGDlAicagxVw0PckICt2yI5DmH(KLrtesK(bswajSdjUcWYfRUX3qZugTnR3cSuBaYHe2Hexby5c1MMaghnX8oMqFYsGLAdqoKWcizFiHDiHniXvawUy1n(gAMYOTz9wGLAdqoKibsCfGLlO5kJVHgkICQal1gGCircKqdraW461IovqrKBYgtmVJj0NSmAIqICqY(qcRqc7qcBqIRaSCbDc3YYaMguGLAdqoKibsccsCfGLlIhIHt1A4O6BcSuBaYHejqsqqIRaSCb)0Pm0KbiWsTbihsyfsyhsoD4gCnwUyQ1mGcp1gGcMWU1A9mL(XU1xNY1PmuS79Lci9D6wyP2aK3FTBLHDlk6Dln6twDR16nQna7wRvad2TydsccsCfGLlOt4wwgW0GcSuBaYHezYGeE6c6eULLbmnOGjesyfsKaj80fABwVfuxJsbjY9ajlcesKajbbj80fABwVfh2CiDtTbiKibs4PlI5DmH(KLGjSBTwptPFSBXtNAyc7EFjwwFNUfwQna59x7wA0NS6wrfamA0NSmGH6DlWqDtPFSBfZeWZvfT79LcO9D6wyP2aK3FTBPrFYQBXpDkdnzaDR47ianUETOt7lTOBfVXXB0ULpF04PHpiKi9dK0g5qIeiHMmadDtpoKinKSC3kUPt1Tw0TMYX7ycDtliTvq3Ar37lTiW(oDlSuBaY7V2TI344nA3IgIaGX1RfDQGIi3KnMyEhtOpzz0eHePFGK9He2HKthUbxJLlMAndOWtTbOGjSBPrFYQBTPmL39(slw03PBHLAdqE)1Uv8ghVr7w80fABwVf(eLAQwircKWtxeZ7yc9jlHprPMQfsKajSbj2mnncn6ZA0WOub11OuqYdKSmKitgKqtgGHUPhhsEGKaHezYGeE6IWnT88BOt1Ya0B83Id)6uuircKWtxeUPLNFdDQwgGEJ)wC4xNIcjs)ajTroKWkKibsydsccsCfGLlc30YZVHovldqVXFlWsTbihsKjds4Plc30YZVHovldqVXFlo8RtrHewHejqcBqsqqIRaSCbhvFZobUal1gGCirMmijMjGNRkbhvFZobU4WVoffsK(bsAJCirMmijiijMjGNRkbhvFZobU4WVoffsKjdsOjdWq30JdjpqsGqIeiHgIaGX1RfDQGIi3KnMyEhtOpzz0eHe5GKfqc7qYPd3GRXYftTMbu4P2auWecjS2T0Opz1TOm)FwgUEs1c0d7EFPf733PBHLAdqE)1Uv8ghVr7wXmb8CvjOm)FwgUEs1c0dfh(1POqIeizTEJAdqbpDQHjesKaj0qeamUETOtfue5MSXeZ7yc9jlJMiK8ajlGe2HKthUbxJLlMAndOWtTbOGjesKajSbjbbjiLIvefRh6KLjBmH41GrFYs8NkpircKeeKO7fVXrb)qL3WamrfaMQvCAjfKitgKeZeWZvLGY8)zz46jvlqpuC4xNIcjYbjVeiKWA3sJ(Kv3IJQVzNaV79Lw8sFNUfwQna59x7wXBC8gTBzZ00iomkfaPuttEruC4xNI2T0Opz1T8n0Wu2jtXnn5fXU3xAra33PBHLAdqE)1ULg9jRUL2M17Uv8ghVr7wh(1POqI0pqsBKdjSdjA0NSe0nLNRm2jWfilfJmoA85JqIeiXNpA80WhesKdsyzDR47ianUETOt7lTO79LwSCFNUfwQna59x7wXBC8gTB5ZhHePHKxcSBPrFYQB9XFEVnzJbWehUHFO(PDVV0IauFNUfwQna59x7wA0NS6wABwV7wXBC8gTB5ZhHe5GKxcesKajXmb8CvjOm)FwgUEs1c0dfh(1POqI0pqYILHejqcUhyMWqKl09s30tPMMSCt2ycZv41TatHMiVB9sGDVV0IasFNUfwQna59x7wA0NS6wX8oMqFYQBfVXXB0ULpFesKdsEjqircKeZeWZvLGY8)zz46jvlqpuC4xNIcjs)ajlwgsKaj4EGzcdrUq3lDtpLAAYYnzJjmxHhKibsccsCfGLluBAcyC0eZ7yc9jlbwQna5qIeiHniXvawUGoHBzzatdkWsTbihsKjdsOHiayC9ArNkOiYnzJjM3Xe6twgnriroizbKibsOHiayC9ArNkOiYnzJjM3Xe6twgnrir6hi5fiH1Ufyk0e5DRxcS79LwWY670TWsTbiV)A3sJ(Kv3IoHBzzatd2TI344nA3YNpcjYbjVeiKibsIzc45Qsqz()SmC9KQfOhko8RtrHePFGKfldjsGeCpWmHHixO7LUPNsnnz5MSXeMRWRBbMcnrE36La7EFPfb0(oDlSuBaY7V2T0Opz1TykQR2a0OnnGj6twDR4noEJ2TccsIz5A7KfKibs85Jgpn8bHePFGeww3k(ocqJRxl60(sl6EFP9dSVt3cl1gG8(RDln6twDl(PtzOjdOBfFhbOX1RfDAFPfDROwreyMMULprPOMd)6usVC3kEJJ3ODlxby5c6MYZvg8BFAefyP2aKdjsGK16nQnafFDkxNYqrircKWrBMMgbDt55kd(TpnIId)6uuircKWrBMMgbDt55kd(TpnIId)6uuir6hiPnYHewaj739(s7VOVt3cl1gG8(RDln6twDl6MYZvg7e4DR4noEJ2TCfGLlOBkpxzWV9PruGLAdqoKibswR3O2au81PCDkdfHejqchTzAAe0nLNRm43(0iko8RtrHejqchTzAAe0nLNRm43(0iko8RtrHePFGeKLIrghn(8riHfqY(qc7qIF6Aey85JqIeijiirJ(KLGUP8CLXobUyktdyA38Uv8DeGgxVw0P9Lw09(s7VFFNUfwQna59x7wA0NS6wHBA553qNQLbO34V7wXBC8gTB5ZhHe5GKxwgsKajUETOl85Jgpn8bHe5GKfbiiHfqcnebaZMsDesKajSbjbbjiLIvefRh6KLjBmH41GrFYs8NkpircKeeKO7fVXrb)qL3WamrfaMQvCAjfKitgKeZeWZvLGY8)zz46jvlqpuC4xNIcjYbjb8Yqc7qcnzag6MECiHfqIUx8ghf8dvEddWevayQwXPLuqImzqsmtapxvckZ)NLHRNuTa9qXHFDkkKinKSyziHfqcnebaZMsDesyhsOjdWq30JdjSas09I34OGFOYByaMOcat1koTKcsyTBfFhbOX1RfDAFPfDVV0(V03PBHLAdqE)1ULg9jRUftrD1gGgTPbmrFYQBfVXXB0UvqqYA9g1gGcgkAOiYHejqcnzag6MECi5bswUBfFhbOX1RfDAFPfDVV0(bCFNUfwQna59x7wXBC8gTBTwVrTbOGHIgkICircKqtgGHUPhhsEGKL7wA0NS6wue5MSXeZ7yc9jRU3xA)L770TWsTbiV)A3sJ(Kv3kQaGrJ(KLbmuVBbgQBk9JDlE60U3xA)auFNUfwQna59x7wA0NS6wRhaACDkVBfVXXB0ULpFesKdswSmKibs85Jgpn8bHe5EGKfbcjsGe2GKyMaEUQeuM)pldxpPAb6HId)6uuiroi5LaHezYGKyMaEUQeuM)pldxpPAb6HId)6uuirAizrGqIeiHNUqBZ6T4WVoffsK7bsweiKibs4PlI5DmH(KL4WVoffsK7bsweiKibsyds4PlOt4wwgW0GId)6uuirUhizrGqImzqsqqIRaSCbDc3YYaMguGLAdqoKWkKWA3k(ocqJRxl60(sl6EFP9di9D6wyP2aK3FTBPrFYQBP7LUPNsnnz5MSXeMRWRBfVXXB0ULpFesK(bsEPBv6h7w6EPB6PuttwUjBmH5k86EFP9zz9D6wyP2aK3FTBfVXXB0ULpFesK(bsEz5ULg9jRUv4MwE(n0PAza6n(7U3xA)aAFNUfwQna59x7wXBC8gTB5ZhHePHKfl3T0Opz1Twpa046uE37l9sG9D6wyP2aK3FTBfVXXB0UfBqsmtapxvckZ)NLHRNuTa9qXHFDkkKinKSyziHDiHMmadDtpoKWcir3lEJJc(HkVHbyIkamvRal1gGCirMmiHnir3lEJJc(HkVHbyIkamvR40skirMmibPuSIOy9qNSmzJjeVgm6twItlPGewHejqIpFesKdsEjqircK4ZhnEA4dcjY9aj7ViqiHvircKWgKWtxeUPLNFdDQwgGEJ)wC4xNIcjYKbj80fRhaACDkxC4xNIcjYKbjbbjUcWYfHBA553qNQLbO34VfyP2aKdjsGKGGexby5I1danUoLlWsTbihsyfsKjds85Jgpn8bHePHKxcesyhsAJ8ULg9jRUvlJE8rlt2y09Ix6BDVV0ll670TWsTbiV)A3kEJJ3ODRyMaEUQeuM)pldxpPAb6HId)6uuirAizXYqc7qcnzag6MECiHfqIUx8ghf8dvEddWevayQwbwQna5qIeiHniHNUiCtlp)g6uTma9g)T4WVoffsKjds4Plwpa046uU4WVoffsyTBPrFYQBX1tkdnzaDVV0l733PBPrFYQBzJhfpPMQTBHLAdqE)1U3x6Lx670TWsTbiV)A3sJ(Kv3kQaGrJ(KLbmuVBbgQBk9JDlAiwC8ODVV0lbCFNUfwQna59x7wA0NS6wrfamA0NSmGH6DlWqDtPFSB1maaE0U39Uv4HX8BREFN(sl670T0Opz1TOm)FwMgeSXuoEDlSuBaY7V29(s733PBHLAdqE)1Uv8ghVr7wUcWYfT38Z5qt2yOA8MMjIcSuBaY7wA0NS6wT38Z5qt2yOA8MMjIDVV0l9D6wA0NS6wHPpz1TWsTbiV)A37lfW9D6wyP2aK3FTBv6h7w6EPB6PuttwUjBmH5k86wA0NS6w6EPB6PuttwUjBmH5k86EFPL770TWsTbiV)A3kEJJ3ODlAicagxVw0PckICt2yI5DmH(KLrtesK7bsEbsKajbbj4EGzcdrUq3lDtpLAAYYnzJjmxHx3sJ(Kv3IIi3KnMyEhtOpz19(sbO(oDln6twDRnLP8UfwQna59x7EFPasFNUfwQna59x7wXBC8gTBfeK4kalxSPmLlWsTbihsKaj0qeamUETOtfue5MSXeZ7yc9jlJMiKinK8cKibsccsW9aZegICHUx6MEk10KLBYgtyUcVULg9jRUfDt55kJDc8U39Uvmtapxv0(o9Lw03PBPrFYQBTkpaFnoL5qAwAfXUfwQna59x7EFP9770TWsTbiV)A3sJ(Kv3s3lDtpLAAYYnzJjmxHx3kEJJ3ODl2GKGGexby5IWnT88BOt1Ya0B83cSuBaYHezYGKyMaEUQeHBA553qNQLbO34Vfh(1POqI0qsadjSasOHiay2uQJqImzqsqqsmtapxvIWnT88BOt1Ya0B83Id)6uuiHvircKeZeWZvLGY8)zz46jvlqpuC4xNIcjsdjlcOqclGeAicaMnL6iKWoKqtgGHUPhhsybKO7fVXrb)qL3WamrfaMQvCAjfKibs4Pl02SElo8RtrHejqcpDrmVJj0NSeh(1POqIeiHniHNUGoHBzzatdko8RtrHezYGKGGexby5c6eULLbmnOal1gGCiH1UvPFSBP7LUPNsnnz5MSXeMRWR79LEPVt3cl1gG8(RDR4noEJ2TydsCfGLl46jLHMmaZFO49wGLAdqoKibsIzc45Qsqz()SmC9KQfOhkycHejqsmtapxvcUEszOjdqWecjScjYKbjXmb8CvjOm)FwgUEs1c0dfmHqImzqIpF04PHpiKinK8sGDln6twDRW0NS6EFPaUVt3cl1gG8(RDR4noEJ2TIzc45Qsqz()SmC9KQfOhko8RtrHe5GKasGqImzqIpF04PHpiKinKSFGqImzqcBqcBqInttJqJ(SgnmkvqDnkfK8ajldjYKbj0KbyOB6XHKhijqiHvircKWgKeeK4kalxeUPLNFdDQwgGEJ)wGLAdqoKitgKeZeWZvLiCtlp)g6uTma9g)T4WVoffsyfsKajSbjbbjUcWYfCu9n7e4cSuBaYHezYGKyMaEUQeCu9n7e4Id)6uuir6hiPnYHezYGKGGKyMaEUQeCu9n7e4Id)6uuiHvircKeeKeZeWZvLGY8)zz46jvlqpuC4xNIcjS2T0Opz1TyOOzC8t7EFPL770TWsTbiV)A3kEJJ3ODRGGKyMaEUQeuM)pldxpPAb6HcMWULg9jRUvZCOnitE37lfG670TWsTbiV)A3kEJJ3ODRGGKyMaEUQeuM)pldxpPAb6HcMWULg9jRULnitUPH5E39(sbK(oDlSuBaY7V2TI344nA3YNpcjYbjVey3sJ(Kv36J)8EBYgdGjoCd)q9t7EFjwwFNUfwQna59x7wXBC8gTB5ZhnEA4dcjsdj7hiKWoK0g5qImzqIRaSCbnxz8n0qrKtfyP2aKdjsGKyMaEUQeuM)pldxpPAb6HId)6uuirUhijMjGNRkbL5)ZYW1tQwGEOGZCQpzbjbaKSiWULg9jRUfxpPm0Kb09(sb0(oDlSuBaY7V2TI344nA3keDbxpPAb6HId)6uuirMmiHnijiijMjGNRkbhvFZobU4WVoffsKjdsccsCfGLl4O6B2jWfyP2aKdjScjsGKyMaEUQeuM)pldxpPAb6HId)6uuirUhiHLfiKibsqkfRikSbzYnzJX3qdw4)T40skiroizr3sJ(Kv3YgKj3KngFdnyH)3DVV0Ia770TWsTbiV)A3sJ(Kv3kmJsHoD2lYnX8hY4Qpzz446jIDR4noEJ2TydsIzc45Qsqz()SmC9KQfOhko8RtrHe5EGK9xgsKjds85Jgpn8bHePFGKxcesyfsKajSbjXmb8Cvj4O6B2jWfh(1POqImzqsqqIRaSCbhvFZobUal1gGCiH1UvPFSBfMrPqNo7f5My(dzC1NSmCC9eXU3xAXI(oDlSuBaY7V2T0Opz1TU0Jhd1rUzDM8mn8ea6wXBC8gTBXgKeZeWZvLGY8)zz46jvlqpuC4xNIcjY9aj7VmKitgK4ZhnEA4dcjs)ajVeiKWkKibsydsIzc45QsWr13StGlo8RtrHezYGKGGexby5coQ(MDcCbwQna5qcRDRs)y36spEmuh5M1zYZ0WtaO79LwSFFNUfwQna59x7wA0NS6w0TznEM1yLFZHGj2TI344nA3InijMjGNRkbL5)ZYW1tQwGEO4WVoffsK7bs2FzirMmiXNpA80WhesK(bsEjqiHvircKWgKeZeWZvLGJQVzNaxC4xNIcjYKbjbbjUcWYfCu9n7e4cSuBaYHew7wL(XUfDBwJNznw53CiyIDVV0Ix670TWsTbiV)A3sJ(Kv3s3dmty6y5Msz8bWq7wXBC8gTBXgKeZeWZvLGY8)zz46jvlqpuC4xNIcjY9aj7VmKitgK4ZhnEA4dcjs)ajVeiKWkKibsydsIzc45QsWr13StGlo8RtrHezYGKGGexby5coQ(MDcCbwQna5qcRDRs)y3s3dmty6y5Msz8bWq7EFPfbCFNUfwQna59x7wA0NS6w(WrQN33etoYs7wXBC8gTBXgKeZeWZvLGY8)zz46jvlqpuC4xNIcjY9aj7VmKitgK4ZhnEA4dcjs)ajVeiKWkKibsydsIzc45QsWr13StGlo8RtrHezYGKGGexby5coQ(MDcCbwQna5qcRDRs)y3Yhos98(MyYrwA37lTy5(oDlSuBaY7V2T0Opz1TwpkWKngQN3N2TI344nA3InijMjGNRkbL5)ZYW1tQwGEO4WVoffsK7bs2FzirMmiXNpA80WhesK(bsEjqiHvircKWgKeZeWZvLGJQVzNaxC4xNIcjYKbjbbjUcWYfCu9n7e4cSuBaYHew7wL(XU16rbMSXq98(0U3xAraQVt3sJ(Kv36MWqaAMYqd1i2TWsTbiV)A37E3IgIfhpAFN(sl670TWsTbiV)A3kEJJ3ODRyMaEUQeuM)pldxpPAb6HId)6uuir6hiHMmadDtpoKWciHnibzPyKXrJpFesyhs09I34OGFOYByaMOcat1koTKcsyfsKajSbjbbjUcWYfCu9n7e4cSuBaYHezYGKyMaEUQeCu9n7e4Id)6uuir6hiHMmadDtpoKWcibzPyKXrJpFesyfsKajSbjUcWYf0CLX3qdfrovGLAdqoKitgKWtxeUPLNFdDQwgGEJ)wC4xNIcjYKbj80fRhaACDkxC4xNIcjS2T0Opz1TykQR2a0OnnGj6twDVV0(9D6wyP2aK3FTBfVXXB0UfBqsmtapxvckZ)NLHRNuTa9qXHFDkkKinK4ZhnEAOB6XHewajSbjldjbaKqtgGHUPhhsyfsKjdsIzc45Qsqz()SmC9KQfOhkycHewHejqIpF04PHpiKihKeZeWZvLGY8)zz46jvlqpuC4xNI2T0Opz1TIkay0Opzzad17wGH6Ms)y3Qzaa8ODVV0l9D6wyP2aK3FTBfVXXB0U1A9g1gGcgkAOiY7wA0NS6wue5MSXeZ7yc9jRU3xkG770TWsTbiV)A3kEJJ3ODRGGK16nQnafmu0qrKdjsGKGGKWdxBAJCXcbL5)ZYW1tQwGEiKibsydsCfGLl4O6B2jWfyP2aKdjsGKyMaEUQeCu9n7e4Id)6uuir6hibzPyKXrJpFesKajbbj6EXBCuevAu5t1AIkq)J)wGLAdqoKitgKWgKqtgGHUPhhsK7bswgsKaj0qeamUETOtfue5MSXeZ7yc9jlJMiKinKSpKitgKqtgGHUPhhsK7bs2hsKaj0qeamUETOtfue5MSXeZ7yc9jlJMiKi3dKSpKWkKibsC9Arx4ZhnEA4dcjYbjbmKWoKGSumY4OXNpcjsGeAicagxVw0PckICt2yI5DmH(KLrtesEGKfqImzqIpF04PHpiKi9dKWYGe2HeKLIrghn(8riHfqcnzag6MECiH1ULg9jRUftrD1gGgTPbmrFYQ79LwUVt3cl1gG8(RDR4noEJ2TccswR3O2auWqrdfroKibsIz5A7KfKi9dKevQB85Jqc7qYA9g1gGIqLZNQTBPrFYQBXuuxTbOrBAat0NS6EFPauFNUfwQna59x7wA0NS6wmf1vBaA0MgWe9jRUv8ghVr7wbbjR1BuBakyOOHIihsKajSbjbbjUcWYfCu9n7e4cSuBaYHezYGKyMaEUQeCu9n7e4Id)6uuiroiXNpA80q30JdjYKbj0KbyOB6XHe5GKfqcRqIeiHnijiiXvawUy9aqJRt5cSuBaYHezYGeAYam0n94qICqYciHvircKeZY12jlir6hijQu34ZhHe2HK16nQnafHkNpvlKibsydsccs09I34OiQ0OYNQ1evG(h)Tal1gGCirMmiXMPPrevAu5t1AIkq)J)wC4xNIcjYbj(8rJNg6MECiH1Uv8DeGgxVw0P9Lw09U3TAgaapAFN(sl670TWsTbiV)A3sJ(Kv3IPOUAdqJ20aMOpz1TI344nA3kMjGNRkbhvFZobU4WVoffsK(bsAJCiHfqY(qIeiHgIaGX1RfDQGIi3KnMyEhtOpzz0eHKhizbKWoKC6Wn4ASCXuRzafEQnafmHqIeijMjGNRkbL5)ZYW1tQwGEO4WVoffsKds2pWUfyk0e5DRfl39(s733PBHLAdqE)1Uv8ghVr7wUcWYfCu9n7e4cSuBaYHejqcnebaJRxl6ubfrUjBmX8oMqFYYOjcjpqYciHDi50HBW1y5IPwZak8uBakycHejqcBqcpDH2M1BXHFDkkKinKWtxOTz9wWzo1NSGewajbkcildjYKbj80fX8oMqFYsC4xNIcjsdj80fX8oMqFYsWzo1NSGewajbkcildjYKbj80f0jClldyAqXHFDkkKinKWtxqNWTSmGPbfCMt9jliHfqsGIaYYqcRqIeijMjGNRkbhvFZobU4WVoffsK(bs0Opzj02SElAJCiHfqsadjsGKyMaEUQeuM)pldxpPAb6HId)6uuiroiz)a7wA0NS6wrfamA0NSmGH6DlWqDtPFSBXTnh2CiDR79LEPVt3cl1gG8(RDR4noEJ2TCfGLl4O6B2jWfyP2aKdjsGeAicagxVw0PckICt2yI5DmH(KLrtesEGKfqc7qYPd3GRXYftTMbu4P2auWecjsGKyMaEUQeuM)pldxpPAb6HId)6uuir6hiHMmadDtpoKWcirJ(KLqBZ6TOnYHe2Hen6twcTnR3I2ihsybK8cKibsyds4Pl02SElo8RtrHePHeE6cTnR3coZP(KfKWcizbKitgKWtxeZ7yc9jlXHFDkkKinKWtxeZ7yc9jlbN5uFYcsybKSasKjds4PlOt4wwgW0GId)6uuirAiHNUGoHBzzatdk4mN6twqclGKfqcRDln6twDROcagn6twgWq9UfyOUP0p2T42MdBoKU19(sbCFNUfwQna59x7wXBC8gTBTwVrTbOGNo1WecjsGe2GKyMaEUQeuM)pldxpPAb6HId)6uuirUhi5LaHe2HK2ihsKjdsIzc45Qsqz()SmC9KQfOhko8RtrHe5GKfbCGqcRDln6twDloQ(MDc8U3xA5(oDlSuBaY7V2TI344nA3YMPPr8Z14hlxWecjsGeBMMgrnTBEJcaId)6u0ULg9jRUfDt55kJDc8U3xka13PBHLAdqE)1Uv8ghVr7w2mnnIFUg)y5cMqircKeeKWgK4kalxqNWTSmGPbfyP2aKdjsGe2GKWdxBAJCXcH2M1BircKeE4AtBKl2xOTz9gsKajHhU20g5IxeABwVHewHezYGKWdxBAJCXcH2M1BiH1ULg9jRUL2M17U3xkG03PBHLAdqE)1Uv8ghVr7w2mnnIFUg)y5cMqircKeeKWgKeE4AtBKlwiOt4wwgW0GqIeij8W1M2ixSVGoHBzzatdcjsGKWdxBAJCXlc6eULLbmniKWA3sJ(Kv3IoHBzzatd29(sSS(oDlSuBaY7V2TI344nA3YMPPr8Z14hlxWecjsGKGGKWdxBAJCXcrmVJj0NSGejqsqqIRaSCHAttaJJMyEhtOpzjWsTbiVBPrFYQBfZ7yc9jRU3xkG23PBHLAdqE)1Uv8ghVr7w2mnnIPW1JR2a0WX)qrb11OuqICqYIaHejqIpF04PHpiKi9dKSiWULg9jRUf)0PmGPb7EFPfb23PBHLAdqE)1Uv8ghVr7wUcWYf0jClldyAqbwQna5qIeiXMPPrmfUEC1gGgo(hkkOUgLcsK7bswoqijaGK9desybKWgKqdraW461IovqrKBYgtmVJj0NSmAIqsaajNoCdUglxm1AgqHNAdqbtiKi3dKSpKWkKibs4Pl02SElo8RtrHe5GKLHewaj0qeamBk1rircKWtxeZ7yc9jlXHFDkkKihK0g5qIeiHniHNUGoHBzzatdko8RtrHe5GK2ihsKjdsccsCfGLlOt4wwgW0GcSuBaYHewHejqcBqchTzAAeBkt5Id)6uuiroizziHfqcnebaZMsDesKjdsccsCfGLl2uMYfyP2aKdjScjsGKywU2ozbjYbjldjSasOHiay2uQJDln6twDl(Ptzatd29(slw03PBHLAdqE)1Uv8ghVr7wUcWYfRUX3qZugTnR3cSuBaYHejqInttJykC94QnanC8puuqDnkfKi3dKSCGqsaaj7hiKWciHniHgIaGX1RfDQGIi3KnMyEhtOpzz0eHKaasoD4gCnwUyQ1mGcp1gGcMqirUhi5fiHvijaGKLHewajSbj0qeamUETOtfue5MSXeZ7yc9jlJMiKeaqYPd3GRXYftTMbu4P2auWecjpqY(qcRqIeiHNUqBZ6T4WVoffsKdswgsybKqdraWSPuhHejqcpDrmVJj0NSeh(1POqICqsBKdjsGe2GeoAZ00i2uMYfh(1POqICqYYqclGeAicaMnL6iKitgKeeK4kalxSPmLlWsTbihsyfsKajXSCTDYcsKdswgsybKqdraWSPuh7wA0NS6w8tNYaMgS79LwSFFNUfwQna59x7wXBC8gTB5kalxO20eW4OjM3Xe6twcSuBaYHejqInttJykC94QnanC8puuqDnkfKi3dKSCGqsaaj7hiKWciHniHgIaGX1RfDQGIi3KnMyEhtOpzz0eHKaasoD4gCnwUyQ1mGcp1gGcMqirUhijGHewHejqcpDH2M1BXHFDkkKihKSmKWciHgIaGztPocjsGe2GeoAZ00i2uMYfh(1POqICqYYqclGeAicaMnL6iKitgKeeK4kalxSPmLlWsTbihsyfsKajXSCTDYcsKdswgsybKqdraWSPuh7wA0NS6w8tNYaMgS79Lw8sFNULg9jRU1MYuE3cl1gG8(RDVV0IaUVt3sJ(Kv3QjJmuKB09I34OXg1F3cl1gG8(RDVV0IL770T0Opz1TczUP59uTgBGs9UfwQna59x7EFPfbO(oDlSuBaY7V2TI344nA3kiiHNUiMvel)uh5MgG(rJnZvId)6uuircKeeKOrFYseZkILFQJCtdq)OyktdyA38ULg9jRUvmRiw(PoYnna9JDVV0IasFNUfwQna59x7wA0NS6w8tNYqtgq3k(ocqJRxl60(sl6wt54DmHE3Ar3kEJJ3ODlF(OXtdFqir6hiPnY7wXnDQU1IU1uoEhtOBAbPTc6wl6EFPfSS(oDlSuBaY7V2T0Opz1T4NoLHMmGUv8DeGgxVw0P9Lw0TMYX7ycDZ00T8jkf1C4xNs6L7wXBC8gTB5kalxq3uEUYGF7tJOal1gGCircKSwVrTbO4Rt56ugkcjsGKGGeoAZ00iOBkpxzWV9PruC4xNI2TIB6uDRfDRPC8oMq30csBf0Tw09(slcO9D6wyP2aK3FTBPrFYQBXpDkdnzaDR47ianUETOt7lTOBnLJ3Xe6MPPB5tukQ5WVoL0l3TI344nA3YvawUGUP8CLb)2NgrbwQna5qIeizTEJAdqXxNY1PmuSBf30P6wl6wt54DmHUPfK2kOBTO79L2pW(oDlSuBaY7V2T0Opz1T4NoLHMmGU1uoEhtO3Tw0TIB6uDRfDRPC8oMq30csBf0Tw09(s7VOVt3cl1gG8(RDln6twDl6MYZvg7e4DR4noEJ2TCfGLlOBkpxzWV9PruGLAdqoKibswR3O2au81PCDkdfHejqsqqchTzAAe0nLNRm43(0iko8RtrHejqsqqIg9jlbDt55kJDcCXuMgW0U5DR47ianUETOt7lTO79L2F)(oDlSuBaY7V2T0Opz1TOBkpxzStG3TI344nA3YvawUGUP8CLb)2NgrbwQna5qIeizTEJAdqXxNY1PmuSBfFhbOX1RfDAFPfDVV0(V03PBPrFYQBr3uEUYyNaVBHLAdqE)1U39UfpDAFN(sl670TWsTbiV)A3kEJJ3ODlE6IyEhtOpzjo8RtrHePFGen6twckICt2yI5DmH(KLiQu34ZhHe2HeF(OXtdDtpoKWoKeWI9HewajSbjlGKaasCfGLlIhIHt1A4O6BcSuBaYHewajbkwSmKWkKibsOHiayC9ArNkOiYnzJjM3Xe6twgnrirUhi5fiHDi50HBW1y5IPwZak8uBakycHe2Hexby5Iv34BOzkJ2M1BbwQna5qIeijiiHNUGIi3KnMyEhtOpzjo8RtrHejqsqqIg9jlbfrUjBmX8oMqFYsmLPbmTBE3sJ(Kv3IIi3KnMyEhtOpz19(s733PBHLAdqE)1ULg9jRUL2M17Uv8ghVr7wUcWYfXdXWPAnCu9nbwQna5qIeirJ(Sgn80fABwVHePHKaeKibs85Jgpn8bHe5GKfbcjsGe2GKd)6uuir6hiPnYHezYGKyMaEUQeuM)pldxpPAb6HId)6uuiroizrGqIeiHni5WVoffsKgswgsKjdsccs09I34Oiulo(NOzQ1zu9jlXPLuqIei5WMdPBQnaHewHew7wX3raAC9ArN2xAr37l9sFNUfwQna59x7wA0NS6wABwV7wXBC8gTBfeK4kalxepedNQ1Wr13eyP2aKdjsGen6ZA0WtxOTz9gsKgsyzqIeiXNpA80WhesKdsweiKibsydso8RtrHePFGK2ihsKjdsIzc45Qsqz()SmC9KQfOhko8RtrHe5GKfbcjsGe2GKd)6uuirAizzirMmijiir3lEJJIqT44FIMPwNr1NSeNwsbjsGKdBoKUP2aesyfsyTBfFhbOX1RfDAFPfDVVua33PBHLAdqE)1ULg9jRUfDc3YYaMgSBfVXXB0UfBqIg9znA4PlOt4wwgW0GqI0qcldscaiXvawUiEigovRHJQVjWsTbihscaiHgIaGX1RfDQGMRm(gAOiYPgnriHvircK4ZhnEA4dcjYbjlcesKajh2CiDtTbiKibsydsccso8RtrHejqcnebaJRxl6ubfrUjBmX8oMqFYYOjcjpqYcirMmijMjGNRkbL5)ZYW1tQwGEO4WVoffsKdsOjdWq30JdjSas0OpzjykQR2a0OnnGj6twcKLIrghn(8riH1Uv8DeGgxVw0P9Lw09(sl33PBHLAdqE)1ULg9jRUvmVJj0NS6wXBC8gTBrdraW461IovqrKBYgtmVJj0NSmAIqI0qYlqc7qYPd3GRXYftTMbu4P2auWecjSdjUcWYfRUX3qZugTnR3cSuBaYHejqcBqYHFDkkKi9dK0g5qImzqsmtapxvckZ)NLHRNuTa9qXHFDkkKihKSiqircKCyZH0n1gGqcRqIeiX1RfDHpF04PHpiKihKSiWUv8DeGgxVw0P9Lw09U39ULY4B51TSM)EC37EVda]] )


end