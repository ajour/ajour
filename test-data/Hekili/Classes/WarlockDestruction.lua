-- WarlockDestruction.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


if UnitClassBase( 'player' ) == 'WARLOCK' then
    local spec = Hekili:NewSpecialization( 267, true )

    spec:RegisterResource( Enum.PowerType.SoulShards, {
        infernal = {
            aura = "infernal",

            last = function ()
                local app = state.buff.infernal.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 0.1
        },

        chaos_shards = {
            aura = "chaos_shards",

            last = function ()
                local app = state.buff.chaos_shards.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 0.5,
            value = 0.2,
        }
    }, setmetatable( {
        actual = nil,
        max = nil,
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
                t.actual = UnitPower( "player", Enum.PowerType.SoulShards, true ) / 10
                return t.actual

            elseif k == 'max' then
                t.max = UnitPowerMax( "player", Enum.PowerType.SoulShards, true ) / 10
                return t.max

            end
        end
    } ) )

    spec:RegisterResource( Enum.PowerType.Mana )


    spec:RegisterHook( "spend", function( amt, resource )
        if resource == "soul_shards" and amt > 0 then
            if talent.soul_fire.enabled and cooldown.soul_fire.remains > 0 then
                setCooldown( "soul_fire", max( 0, cooldown.soul_fire.remains - ( 2 * amt ) ) )
            end

            if talent.grimoire_of_supremacy.enabled and pet.infernal.up then
                addStack( "grimoire_of_supremacy", nil, amt )
            end
        end
    end )


    -- Talents
    spec:RegisterTalents( {
        flashover = 22038, -- 267115
        eradication = 22090, -- 196412
        soul_fire = 22040, -- 6353

        reverse_entropy = 23148, -- 205148
        internal_combustion = 21695, -- 266134
        shadowburn = 23157, -- 17877

        demon_skin = 19280, -- 219272
        burning_rush = 19285, -- 111400
        dark_pact = 19286, -- 108416

        inferno = 22480, -- 270545
        fire_and_brimstone = 22043, -- 196408
        cataclysm = 23143, -- 152108

        darkfury = 22047, -- 264874
        mortal_coil = 19291, -- 6789
        demonic_circle = 19288, -- 268358

        roaring_blaze = 23155, -- 205184
        grimoire_of_supremacy = 23156, -- 266086
        grimoire_of_sacrifice = 19295, -- 108503

        soul_conduit = 19284, -- 215941
        channel_demonfire = 23144, -- 196447
        dark_soul_instability = 23092, -- 113858
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3493, -- 196029
        adaptation = 3494, -- 214027
        gladiators_medallion = 3495, -- 208683

        bane_of_havoc = 164, -- 200546
        entrenched_in_flame = 161, -- 233581
        cremation = 159, -- 212282
        fel_fissure = 157, -- 200586
        focused_chaos = 155, -- 233577
        casting_circle = 3510, -- 221703
        essence_drain = 3509, -- 221711
        nether_ward = 3508, -- 212295
        curse_of_weakness = 3504, -- 199892
        curse_of_tongues = 3503, -- 199890
        curse_of_fragility = 3502, -- 199954
    } )


    -- Auras
    spec:RegisterAuras( {
        active_havoc = {
            duration = 10,
            max_stack = 1,

            generate = function( ah )
                if active_enemies > 1 then
                    if pvptalent.bane_of_havoc.enabled and debuff.bane_of_havoc.up and query_time - last_havoc < 10 then
                        ah.count = 1
                        ah.applied = last_havoc
                        ah.expires = last_havoc + 10
                        ah.caster = "player"
                        return
                    elseif not pvptalent.bane_of_havoc.enabled and active_dot.havoc > 0 and query_time - last_havoc < 10 then
                        ah.count = 1
                        ah.applied = last_havoc
                        ah.expires = last_havoc + 10
                        ah.caster = "player"
                        return
                    end
                end

                ah.count = 0
                ah.applied = 0
                ah.expires = 0
                ah.caster = "nobody"
            end
        },
        backdraft = {
            id = 117828,
            duration = 10,
            type = "Magic",
            max_stack = function () return talent.flashover.enabled and 4 or 2 end,
        },

        -- Going to need to keep an eye on this.  active_dot.bane_of_havoc won't work due to no SPELL_AURA_APPLIED event.
        bane_of_havoc = {
            id = 200548,
            duration = 10,
            max_stack = 1,
            generate = function( boh )
                boh.applied = action.bane_of_havoc.lastCast
                boh.expires = boh.applied > 0 and ( boh.applied + 10 ) or 0
            end,
        },
        blood_pact = {
            id = 6307,
            duration = 3600,
            max_stack = 1,
        },
        burning_rush = {
            id = 111400,
            duration = 3600,
            max_stack = 1,
        },
        channel_demonfire = {
            id = 196447,
        },
        conflagrate = {
            id = 265931,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        dark_pact = {
            id = 108416,
            duration = 20,
            max_stack = 1,
        },
        dark_soul_instability = {
            id = 113858,
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
            duration = 4.95,
            max_stack = 1,
        },
        eradication = {
            id = 196414,
            duration = 7,
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
        grimoire_of_sacrifice = {
            id = 196099,
            duration = 3600,
            max_stack = 1,
        },
        grimoire_of_supremacy = {
            id = 266091,
            duration = 3600,
            max_stack = 8,
        },
        havoc = {
            id = 80240,
            duration = 10,
            type = "Curse",
            max_stack = 1,

            generate = function ( t, type )
                if type == "buff" then
                    t.count = 0
                    t.applied = 0
                    t.expires = 0
                    t.caster = "nobody"
                    return
                end

                local h = debuff.havoc
                --[[ local name, _, count, _, duration, expires, caster = FindUnitDebuffByID( "target", 80240, "PLAYER" )

                if active_enemies > 1 and name then
                    h.count = 1
                    h.applied = expires - duration
                    h.expires = expires
                    h.caster = "player"
                    return
                end ]]

                h.count = 0
                h.applied = 0
                h.expires = 0
                h.caster = "nobody"
            end
        },
        immolate = {
            id = 157736,
            duration = 18,
            tick_time = function () return 3 * haste end,
            type = "Magic",
            max_stack = 1,
        },
        infernal = {
            duration = 30,
            generate = function ()
                local inf = buff.infernal

                if pet.infernal.alive then
                    inf.count = 1
                    inf.applied = pet.infernal.expires - 30
                    inf.expires = pet.infernal.expires
                    inf.caster = "player"
                    return
                end

                inf.count = 0
                inf.applied = 0
                inf.expires = 0
                inf.caster = "nobody"
            end,
        },
        infernal_awakening = {
            id = 22703,
            duration = 2,
            max_stack = 1,
        },
        mana_divining_stone = {
            id = 227723,
            duration = 3600,
            max_stack = 1,
        },
        mortal_coil = {
            id = 6789,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        rain_of_fire = {
            id = 5740,
        },
        reverse_entropy = {
            id = 266030,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        ritual_of_summoning = {
            id = 698,
        },
        shadowburn = {
            id = 17877,
            duration = 5,
            max_stack = 1,
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
        soul_shards = {
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


        -- Azerite Powers
        chaos_shards = {
            id = 287660,
            duration = 2,
            max_stack = 1
        },
    } )


    spec:RegisterStateExpr( "last_havoc", function ()
        return pvptalent.bane_of_havoc.enabled and action.bane_of_havoc.lastCast or action.havoc.lastCast
    end )

    spec:RegisterStateExpr( "havoc_remains", function ()
        return buff.active_havoc.remains
    end )

    spec:RegisterStateExpr( "havoc_active", function ()
        return buff.active_havoc.up
    end )

    spec:RegisterHook( "TimeToReady", function( wait, action )
        local ability = action and class.abilities[ action ]

        if ability and ability.spend and ability.spendType == "soul_shards" and ability.spend > soul_shard then
            wait = 3600
        end

        return wait
    end )

    spec:RegisterStateExpr( "soul_shard", function () return soul_shards.current end )


    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceGUID == GUID and subtype == "SPELL_CAST_SUCCESS" and destGUID ~= nil and destGUID ~= "" then
            lastTarget = destGUID
        end
    end )


    spec:RegisterHook( "reset_precast", function ()
        last_havoc = nil
        soul_shards.actual = nil

        for i = 1, 5 do
            local up, _, start, duration, id = GetTotemInfo( i )

            if up and id == 136219 then
                summonPet( "infernal", start + duration - now )
                break
            end
        end

        if pvptalent.bane_of_havoc.enabled then
            class.abilities.havoc = class.abilities.bane_of_havoc
        else
            class.abilities.havoc = class.abilities.real_havoc
        end
    end )


    spec:RegisterCycle( function ()
        if active_enemies == 1 then return end

        -- For Havoc, we want to cast it on a different target.
        if this_action == "havoc" and class.abilities.havoc.key == "havoc" then return "cycle" end

        if debuff.havoc.up or FindUnitDebuffByID( "target", 80240, "PLAYER" ) then
            return "cycle"
        end
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
        banish = {
            id = 710,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = false,

            handler = function ()
                if debuff.banish.up then removeDebuff( "target", "banish" )
                else applyDebuff( "target", "banish") end
            end,
        },


        burning_rush = {
            id = 111400,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
                if buff.burning_rush.up then removeBuff( "burning_rush" )
                else applyBuff( "burning_rush" ) end
            end,
        },


        cataclysm = {
            id = 152108,
            cast = 2,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,

            talent = "cataclysm",

            handler = function ()
                applyDebuff( "target", "immolate" )
                active_dot.immolate = max( active_dot.immolate, true_active_enemies )
            end,
        },


        channel_demonfire = {
            id = 196447,
            cast = 3,
            channeled = true,
            cooldown = 25,
            hasteCD = true,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            talent = "channel_demonfire",

            usable = function () return active_dot.immolate > 0 end,
            start = function ()
                -- applies channel_demonfire (196447)
            end,
        },


        chaos_bolt = {
            id = 116858,
            cast = function () return ( buff.backdraft.up and 0.7 or 1 ) * 3 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 2,
            spendType = "soul_shards",

            startsCombat = true,

            cycle = function () return talent.eradication.enabled and "eradication" or nil end,

            velocity = 16,

            handler = function ()
                if talent.eradication.enabled then
                    applyDebuff( "target", "eradication" )
                    active_dot.eradication = max( active_dot.eradication, active_dot.bane_of_havoc )
                end
                if talent.internal_combustion.enabled and debuff.immolate.up then
                    if debuff.immolate.remains <= 5 then removeDebuff( "target", "immolate" )
                    else debuff.immolate.expires = debuff.immolate.expires - 5 end
                end
                removeStack( "backdraft" )
                removeStack( "crashing_chaos" )
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


        conflagrate = {
            id = 17962,
            cast = 0,
            charges = 2,
            cooldown = 13,
            recharge = 13,
            hasteCD = true,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,

            cycle = function () return talent.roaring_blaze.enabled and "conflagrate" or nil end,

            handler = function ()
                gain( 0.5, "soul_shards" )
                addStack( "backdraft", nil, talent.flashover.enabled and 4 or 2 )
                if talent.roaring_blaze.enabled then
                    applyDebuff( "target", "conflagrate" )
                    active_dot.conflagrate = max( active_dot.conflagrate, active_dot.bane_of_havoc )
                end
            end,
        },


        --[[ create_healthstone = {
            id = 6201,
            cast = 2.97,
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
            cast = 2.97,
            cooldown = 120,
            gcd = "spell",

            spend = 0.05,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()                
            end,
        }, ]]


        dark_pact = {
            id = 108416,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            defensive = true,

            startsCombat = true,

            talent = "dark_pact",

            usable = function () return health.pct > 20 end,
            handler = function ()
                applyBuff( "dark_pact" )
                spend( 0.2 * health.max, "health" )
            end,
        },


        dark_soul_instability = {
            id = 113858,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,

            talent = "dark_soul_instability",

            handler = function ()
                applyBuff( "dark_soul_instability" )
            end,
        },


        --[[ demonic_circle = {
            id = 48018,
            cast = 0.49995,
            cooldown = 10,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
                -- applies demonic_circle (48018)
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
                -- applies demonic_circle_teleport (48020)
            end,
        },


        demonic_gateway = {
            id = 111771,
            cast = 1.98,
            cooldown = 10,
            gcd = "spell",

            spend = 0.2,
            spendType = "mana",

            startsCombat = true,

            handler = function ()
            end,
        }, ]]


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
                applyDebuff( "target", "drain_life" )
            end,
        },


        --[[ enslave_demon = {
            id = 1098,
            cast = 2.97,
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
            cast = 1.98,
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
            cast = 1.69983,
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

            talent = "grimoire_of_sacrifice",
            nobuff = "grimoire_of_sacrifice",

            essential = true,

            usable = function () return pet.active end,
            handler = function ()
                if pet.felhunter.alive then dismissPet( "felhunter" )
                elseif pet.imp.alive then dismissPet( "imp" )
                elseif pet.succubus.alive then dismissPet( "succubus" )
                elseif pet.voidawalker.alive then dismissPet( "voidwalker" ) end

                applyBuff( "grimoire_of_sacrifice" )
            end,
        },


        havoc = {
            id = 80240,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            indicator = function () return ( lastTarget == "lastTarget" or target.unit == lastTarget ) and "cycle" or nil end,
            cycle = "havoc",

            bind = "bane_of_havoc",

            usable = function () return not pvptalent.bane_of_havoc.enabled and active_enemies > 1 end,
            handler = function ()
                if class.abilities.havoc.indicator == "cycle" then
                    active_dot.havoc = active_dot.havoc + 1
                else
                    applyDebuff( "target", "havoc" )
                end
                applyBuff( "active_havoc" )
            end,

            copy = "real_havoc"
        },


        bane_of_havoc = {
            id = 200546,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            startsCombat = true,
            texture = 1380866,
            cycle = "DoNotCycle",

            bind = "havoc",

            pvptalent = "bane_of_havoc",
            usable = function () return active_enemies > 1 end,
            
            handler = function ()
                applyDebuff( "target", "bane_of_havoc" )
                active_dot.bane_of_havoc = active_enemies
                applyBuff( "active_havoc" )
            end,
        },        


        health_funnel = {
            id = 755,
            cast = 5,
            channeled = true,
            breakable = true,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,

            usable = function () return pet.active end,
            start = function ()
                applyBuff( "health_funnel" )
            end,
        },


        immolate = {
            id = 348,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            cycle = function () return not debuff.immolate.refreshable and "immolate" or nil end,

            handler = function ()
                applyDebuff( "target", "immolate" )
                active_dot.immolate = max( active_dot.immolate, active_dot.bane_of_havoc )
            end,
        },


        incinerate = {
            id = 29722,
            cast = function ()
                if buff.chaotic_inferno.up then return 0 end
                return ( buff.backdraft.up and 0.7 or 1 ) * 2 * haste
            end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            velocity = 25,

            handler = function ()
                removeBuff( "chaotic_inferno" )
                removeStack( "backdraft" )
                -- Using true_active_enemies for resource predictions' sake.
                gain( 0.2 + ( talent.fire_and_brimstone.enabled and ( ( true_active_enemies - 1 ) * 0.1 ) or 0 ), "soul_shards" )
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
                active_dot.mortal_coil = max( active_dot.mortal_coil, active_dot.bane_of_havoc )
                gain( 0.2 * health.max, "health" )
            end,
        },


        rain_of_fire = {
            id = 5740,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 3,
            spendType = "soul_shards",

            startsCombat = true,

            handler = function ()
                -- establish that RoF is ticking?
                -- need a CLEU handler?
            end,
        },


        shadowburn = {
            id = 17877,
            cast = 0,
            charges = 2,
            cooldown = 12,
            recharge = 12,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,

            talent = "shadowburn",

            handler = function ()
                gain( 0.3, "soul_shards" )
                applyDebuff( "target", "shadowburn" )
                active_dot.shadowburn = max( active_dot.shadowburn, active_dot.bane_of_havoc )
            end,
        },


        shadowfury = {
            id = 30283,
            cast = 1.5,
            cooldown = function () return talent.darkfury.enabled and 45 or 60 end,
            gcd = "spell",

            startsCombat = true,

            handler = function ()
                applyDebuff( "target", "shadowfury" )
            end,
        },


        singe_magic = {
            id = 132411,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,

            usable = function ()
                return pet.exists or buff.grimoire_of_sacrifice.up
            end,
            handler = function ()
                -- generic dispel effect?
            end,
        },


        soul_fire = {
            id = 6353,
            cast = 1.5,
            cooldown = 20,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,

            talent = "soul_fire",

            handler = function ()
                gain( 0.4, "soul_shards" )
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

            startsCombat = true,
            -- texture = ?

            toggle = "interrupts",
            interrupt = true,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        summon_felhunter = {
            id = 691,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            essential = true,

            usable = function ()
                if pet.alive then return false, "pet is alive"
                elseif buff.grimoire_of_sacrifice.up then return false, "grimoire_of_sacrifice is up" end
                return true
            end,
            handler = function () summonPet( "felhunter" ) end,

            copy = { 112869 }
        },


        summon_imp = {
            id = 688,
            cast = 2.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "soul_shards",

            essential = true,
            bind = "summon_pet",
            nomounted = true,

            usable = function ()
                if pet.alive then return false, "pet is alive"
                elseif buff.grimoire_of_sacrifice.up then return false, "grimoire_of_sacrifice is up" end
                return true
            end,
            handler = function () summonPet( "imp" ) end,

            copy = "summon_pet"
        },


        summon_infernal = {
            id = 1122,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 - ( azerite.crashing_chaos.enabled and 15 or 0 ) end,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,

            handler = function ()
                summonPet( "infernal", 30 )
                if azerite.crashing_chaos.enabled then applyBuff( "crashing_chaos", 3600, 8 ) end
            end,
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

            defensive = true,            
            toggle = "defensives",

            startsCombat = false,

            handler = function ()
                applyBuff( "unending_resolve" )
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,
        cycle = true,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageDots = false,
        damageExpiration = 6,

        potion = "unbridled_fury",

        package = "Destruction",
    } )


    spec:RegisterPack( "Destruction", 20200124, [[dW0RQbqivipIsP2KkYNurjnkqKtbIAvusvEffvZcvXTOKk2LO(fQQgMkWXGQAzQGEgivtdKIRPIQTrPeFtfLyCGuQZrjv16OKkL5rr5EGY(OuCqvuelevPhQIctKsj5IQOO2iiL0hbPenskPsojLuSsqYmvrPe3ufLsANus(jLuPQHsjvQSuvukEkuMkQkxvfLs9vvuK2lr)vKbRQdtAXu4XeMSuDzKnRsFMImAq1PPA1ukPETkuZgLBlLDl53kgou54Guclh45qMUW1rLTdcFhQY4vrP68uQwpLuA(uI9R0s8L8jX6AqsRo8Gdp4a8peAY4FWbhEa0LyHDCKedNkownrsSsBKeZwrOaWjcFkjgo1oB0UKpjgA4acsIbpcCiRB8ZVjpGZzKftJFK34yA4tja6n4h5nb)smdoNfwtjnKyDniPvhEWHhCa(hcnz8p4Gdp4qjMYfWhGedZBNHedU37ujnKyDcjKy2EFBfHcaNi8P2)mvbSrC8cLT3hEe4qw34NFtEaNZilMg)iVXX0WNsa0BWpYBc(xOS9(qPfNcSV)H4ZZ(hEWHhiXyokqs(KyMgehUKxxcuktYN0k8L8jXOsnyuxYReta8GaUkXqdhlHGRG((W2)89pT)r7BWDVzdvCChO3iZHB)t7BWDV5g1gG90CtmoH3tDaPnuMd3(N23G7EZMaEBCaLMBcXHdqnvypJcvC8(MbBF8pqIPIWNsIbuVsZnDDajdPvhk5tIrLAWOUKxjMa4bbCvIzWDVzdvCChO3iZHtIPIWNsIjGRdkzmSqgsRGUKpjgvQbJ6sELycGheWvjgA4yjeCf033gy7dn5d336SVb39MBuBa2tZnX4eEp1bK2qzoCsmve(usmbCDqjJHfYqAf0i5tIrLAWOUKxjMa4bbCvID0(Izy9bVklM6YutanOmhojMkcFkjMaUoOKXWcziT6CjFsmQudg1L8kXeapiGRsmHIIu4nAFZ2hhfzVUeOuwgqn1l0(N2hhfzVUeOuwgqn1l0(MTVqrrk8gTV57Bs0LyQi8PKyc46GsgdlKH0kBrYNeJk1GrDjVsmbWdc4QeZG7EZgQ44oqVrUp4v7FAFdU7n3O2aSNMBIXj8EQdiTHYC42)0(OHJLqWvqFFBGTp(zOlXur4tjXetDzQjGgKmKwDwK8jXOsnyuxYReta8GaUkXm4U3SHkoUd0BK7dE1(N2)O9n4U3CJAdWEAUjgNW7PoG0gkZHB)t7dP9rdhlHGRG((2aB)dZq79TyzFbCfyIqPlqfHpLY23M9XpB93)0(OHJLqWvqFFBGTp(zOVpKLyQi8PKyIPUm1eqdsgsRG2s(KyuPgmQl5vIjaEqaxLy4Oi71LaLYYaQPEH23S9pxIPIWNsIjM6YutaniziTY6l5tIrLAWOUKxjMa4bbCvIjGRateAFB2hFjMkcFkjMyQltnb0GKH0k8pqYNetfHpLednCS01bKeJk1GrDjVYqAf(4l5tIPIWNsIHGR9bpdoqjXOsnyuxYRmKwH)Hs(KyQi8PKyEj8IaAqsmQudg1L8kdziXGRqmcjFsRWxYNeJk1GrDjVsmbWdc4QeZG7EZgQ44oqVrUp4v7FAF0WXsi4kOVVnW2h)9pTpA4yjeCf033my7dnsmve(usmXuxMAcObjdPvhk5tIrLAWOUKxjMa4bbCvIfkJQi7vqGszjX0m4qHpvMk1Gr99pTpGAQxO9nB)ohqdFQ9TE7Fq(89Tyz)J2pugvr2RGaLYsIPzWHcFQmvQbJ67FAFaDbecUAWijMkcFkjM3AdtdsgsRGUKpjgvQbJ6sELycGheWvjMqrrk8gTVz7dxHyeja1uVqsmve(usmbCDqjJHfYqAf0i5tIPIWNsIHgow66asIrLAWOUKxziT6CjFsmQudg1L8kXeapiGRsmveoeuIkQ5eAFZ2h67BXY(hTFOmQI81busREYa4numfLPsnyuxIPIWNsIHGR9bpdoqjdPv2IKpjgvQbJ6sELycGheWvjMqrrk8gTVz7dxHyeja1uVqsmve(usmVeEranizidjgoajMMHgs(KwHVKpjMkcFkjgIR1Mk5nCsmQudg1L8kdPvhk5tIrLAWOUKxjMa4bbCvIfkJQiBc4TXbuAUjKka(1fuMk1GrDjMkcFkjMjG3ghqP5MqQa4xxqYqAf0L8jXur4tjXWnHpLeJk1GrDjVYqAf0i5tIPIWNsIHgow66asIrLAWOUKxziT6CjFsmQudg1L8kXeapiGRsSJ2pugvrgnCS01buMk1GrDjMkcFkjMxcViGgKmKHethsYN0k8L8jXOsnyuxYReta8GaUkXWrr2RlbkLLvr4qq7FAFiTVb39Mfafb3ltjbCDq5(GxTVfl7F0(HYOkYMaEBCaLMBcXHdqnvyptLAWO((qE)t7dP9pAFXmS(GxLHRqmImG0U99TyzFveoeuIkQ5eAFB2h67dzjMkcFkjgq9kn301bKmKwDOKpjgvQbJ6sELycGheWvjwFIS3AdtdkdOM6fAFB2xOOifEJKyQi8PKyc4Avel1P2uxhqYqAf0L8jXOsnyuxYRetfHpLeZBTHPbjXeapiGRsma1uVq7B2(NV)P9H0(hTFOmQISqdvWSJAzQudg133IL9fZW6dEvwOHky2rTmGAQxO9TzFa1uVq7dzjMWUGrPqbMOajTcFziTcAK8jXOsnyuxYRetfHpLetOmwsfHpvI5OqIXCuKkTrsmrhjdPvNl5tIrLAWOUKxjMkcFkjgCfIriXeapiGRsmveoeuIkQ5eAFZ2hAKyc7cgLcfyIcK0k8LH0kBrYNeJk1GrDjVsmbWdc4Qelugvr2eWBJdO0CtioCaQPc7zQudg13)0(4Oi71LaLYYQiCiO9pTpK2hUcXisQiCiO9Tyz)qzufzHgQGzh1YuPgmQVVfl7hkJQi71La1KPsnyuF)t7RIWHGsurnNq7B2(qZ(qwIPIWNsIjGRdkzmSqgsRols(KyQi8PKya1R0CtxhqsmQudg1L8kdPvqBjFsmve(usS7i4qupPwlb8GsgK2KyuPgmQl5vgsRS(s(KyQi8PKy44a(1UxMsgmffsmQudg1L8kdPv4FGKpjgvQbJ6sELyQi8PKyWvigHeta8GaUkXG0(hTFOmQISjG3ghqP5MqC4autf2ZuPgmQVVfl7F0(HYOkYEDjqnzQudg133IL9dLrvKnb824akn3eIdhGAQWEMk1Gr99pTpokYEDjqPSmGAQxO9nd2(4FW(qwIjSlyukuGjkqsRWxgsRWhFjFsmQudg1L8kXeapiGRsSqzuf5RdOKw9KbWBOykktLAWO((N23G7EZgQ44oqVrMd3(N2hnCSecUc67B2(NVV1z)dYhUV1BFveoeuIkQ5esIPIWNsI5LWlcObjdPv4FOKpjMkcFkjgA4yPRdijgvQbJ6sELH0k8HUKpjgvQbJ6sELycGheWvjMb39MnuXXDGEJCFWRKyQi8PKyIPUm1eqdsgsRWhAK8jXOsnyuxYReta8GaUkXoA)qzuf5RdOKw9KbWBOykktLAWOUetfHpLedbx7dEgCGsgsRW)CjFsmQudg1L8kXeapiGRsSJ2VprwmLGQaOb1txM2OKbhOYaQPEH2)0(hTVkcFQSykbvbqdQNUmTrzVsxMBcES)P9vr4qqjQOMtO9nB)ZLyQi8PKyIPeufanOE6Y0gjdPv4Bls(KyQi8PKyEj8IaAqsmQudg1L8kdziXeDKKpPv4l5tIrLAWOUKxjMa4bbCvIfkJQiBc4TXbuAUjehoa1uH9mvQbJ67FAFa1uVq7B2(q79pTVygwFWRYiUwBQKxxcukldOM6fAFZ2hAYNlXur4tjX8wByAqYqA1Hs(KyuPgmQl5vIjaEqaxLyHYOkYMaEBCaLMBcXHdqnvyptLAWO((N2xmdRp4vzexRnvYRlbkLLbut9cTVz7dn5Z3)0(hTVb39MnuXXDGEJmhU9pTpA4yjeCf033S9HMm0LyQi8PKyIPUm1eqdsgsRGUKpjgvQbJ6sELyQi8PKyQ1IGRafLUtfP5MWn4rajMa4bbCvIjMH1h8QmIR1Mk51LaLYYC423IL9fZW6dEvgX1AtL86sGszza1uVq7BgS9HgjwPnsIPwlcUcuu6ovKMBc3GhbKH0kOrYNetfHpLedX1AtL86sGszsmQudg1L8kdPvNl5tIrLAWOUKxjMa4bbCvIHJISxxcuklRIWHGKyQi8PKyM4uq31kn3KATeyc4YqALTi5tIrLAWOUKxjMa4bbCvIHJISxxcuklRIWHG2)0(qAFCuK96sGszza1uVq7B2(hEq(89TyzFCuK96sGszza1uVq7B2(hE4(N2hnCSecUc67BdS9HE2w23IL9pA)qzufztaVnoGsZnH4WbOMkSNPsnyuFFilXur4tjX6k44eA4yjVqHA4mpSldPvNfjFsmQudg1L8kXeapiGRsmCuK96sGszzveoe0(N2hs7JJISxxcukldOM6fAFZ2h)ZZNVVfl7Jgowcbxb99nBFONpF)t7dP9n4U3CxbhNqdhl5fkudN5H9mhU9Tyz)J2pugvr2eWBJdO0CtioCaQPc7zQudg13)0(9jYERnmnOmGAQxO9TzF8pCFiVpKLyQi8PKynQna7P5MyCcVN6asBiziTcAl5tIrLAWOUKxjMa4bbCvIfEJsXK6oTVn7lMH1h8QmIR1Mk51LaLYYDoGg(u7B((q)ajMkcFkjgIR1Mk51LaLYKH0kRVKpjgvQbJ6sELycGheWvjw4nAFB2h6hS)P9dVrPysDN23M9fZW6dEv2eNc6UwP5MuRLatap35aA4tTV57d9dKyQi8PKyM4uq31kn3KATeyc4YqAf(hi5tIrLAWOUKxjMa4bbCvIfkJQi3vWXj0WXsEHc1WzEyptLAWO((N2xmdRp4v5UcooHgowYluOgoZd7za1uVq7BZ(Hcmrro8gLIj1DsIPIWNsIH4ATPsEDjqPmziTcF8L8jXOsnyuxYReta8GaUkXeZW6dEvgX1AtL86sGszza1uVq7BZ(H3OumPUtsmve(usmtCkO7ALMBsTwcmbCziTc)dL8jXOsnyuxYReta8GaUkXeZW6dEvgX1AtL86sGszza1uVq7BZ(H3OumPUt7FAFCuK96sGszza1uVq7B2(hEq(CjMkcFkjwxbhNqdhl5fkudN5HDziTcFOl5tIrLAWOUKxjMa4bbCvIjMH1h8QmIR1Mk51LaLYYaQPEH23M9dVrPysDN2)0(4Oi71LaLYYaQPEH23S9XhANpxIPIWNsIH3ayDiiVsacnLwcsgsRWhAK8jXOsnyuxYReta8GaUkXeZW6dEvgX1AtL86sGszza1uVq7BZ(H3OumPUt7FAFiTpokYEDjqPSmGAQxO9nBF8ppF((wSSVb39M7k44eA4yjVqHA4mpSN5WT)P9rdhlHGRG((MTp03hYsmve(usSg1gG90CtmoH3tDaPnKmKwH)5s(KyuPgmQl5vIjaEqaxLyH3OumPUt7B2(q)ajMkcFkjgIR1Mk51LaLYKH0k8TfjFsmQudg1L8kXeapiGRsSWBukMu3P9nBFOFGetfHpLeZeNc6UwP5MuRLataxgsRW)Si5tIrLAWOUKxjMa4bbCvIfEJsXK6oTVz7Fi(7FA)WBukMu3P9TzFOrIPIWNsI1vWXj0WXsEHc1WzEyxgsRWhAl5tIrLAWOUKxjMa4bbCvIfEJsXK6oTVz7JVTS)P9dVrPysDN23M9TfjMkcFkjwJAdWEAUjgNW7PoG0gsgsRW36l5tIrLAWOUKxjMa4bbCvIfEJsXK6oTVz7JV1F)t7hEJsXK6oTVn7dnsmve(usm8gaRdb5vcqOP0sqYqA1Hhi5tIrLAWOUKxjMa4bbCvIfEJsXK6oTVz7JVTS)P9dVrPysDN23M9TfjMkcFkjwJAdWEAUjgNW7PoG0gsgsRoeFjFsmve(usmd2m90CtbCkrf1SlXOsnyuxYRmKwD4Hs(KyuPgmQl5vIjaEqaxLyIzy9bVkJ4ATPsEDjqPSmGAQxO9Tb2(2Yb7BD2h)d3)0(hTpokYEDjqPSSkchcsIPIWNsIH3ayDiiVsacnLwcsgsRoe6s(KyQi8PKyahhogL8kHWPcsIrLAWOUKxziT6qOrYNeJk1GrDjVsmbWdc4QedhfzVUeOuwwfHdbTVfl7hEJsXK6oTVz7d9dKyQi8PKy4MWNsgsRo8CjFsmQudg1L8kXeapiGRsmCuK96sGszzveoe0(N2hs7F0(HYOkYMaEBCaLMBcXHdqnvyptLAWO((wSSpK2)O9jeIkbLBuBa2tZnX4eEp1bK2q5MARhW(wSSVb39MBuBa2tZnX4eEp1bK2qza1uVq7d59pTpK2)O9dLrvK7k44eA4yjVqHA4mpSNPsnyuFFlw23G7EZDfCCcnCSKxOqnCMh2ZaQPEH2hY7d59Tyz)WBukMu3P9nd2(4FUetfHpLeZGaicCSxMKH0QdTfjFsmQudg1L8kXeapiGRsmCuK96sGszzveoe0(N2hs7F0(HYOkYMaEBCaLMBcXHdqnvyptLAWO((wSSpK2)O9jeIkbLBuBa2tZnX4eEp1bK2q5MARhW(wSSVb39MBuBa2tZnX4eEp1bK2qza1uVq7d59pTpK2)O9dLrvK7k44eA4yjVqHA4mpSNPsnyuFFlw23G7EZDfCCcnCSKxOqnCMh2ZaQPEH2hY7d59Tyz)WBukMu3P9nd2(4FUetfHpLeZGntpD5a2LH0Qdpls(KyuPgmQl5vIjaEqaxLy4Oi71LaLYYQiCiO9pTpK2)O9dLrvKnb824akn3eIdhGAQWEMk1Gr99TyzFiT)r7tievck3O2aSNMBIXj8EQdiTHYn1wpG9TyzFdU7n3O2aSNMBIXj8EQdiTHYaQPEH2hY7FAFiT)r7hkJQi3vWXj0WXsEHc1WzEyptLAWO((wSSVb39M7k44eA4yjVqHA4mpSNbut9cTpK3hY7BXY(H3OumPUt7BgS9X)CjMkcFkj21bKbBMUmKwDi0wYNeJk1GrDjVsmbWdc4QedhfzVUeOuwwfHdbT)P9H0(hTFOmQISjG3ghqP5MqC4autf2ZuPgmQVVfl7JJISxxcukldOM6fAFZGT)HhSpK33IL9dVrPysDN23my7F4bsmve(usmoeL8GAiziT6qRVKpjgvQbJ6sELyQi8PKy4gXXuGCRL6jX0WXfA4tL6eeUGKycGheWvjwFIS3AdtdkdOM6fAFBGT)57FAFiTVygwFWRYiUwBQKxxcukldOM6fAFBGT)HhSVfl7hEJsXK6oTVz7d9d2hYsSsBKed3ioMcKBTupjMgoUqdFQuNGWfKmKwb9dK8jXOsnyuxYRetfHpLedmHaWHcQNGyM(mP(WysmbWdc4QeRpr2BTHPbLbut9cTVnW2)89pTpK2xmdRp4vzexRnvYRlbkLLbut9cTVnW2)Wd23IL9dVrPysDN23S9H(b7dzjwPnsIbMqa4qb1tqmtFMuFymziTc64l5tIrLAWOUKxjMkcFkjgcUdbbsqq10saI5cjMa4bbCvI1Ni7T2W0GYaQPEH23gy7F((N2hs7lMH1h8QmIR1Mk51LaLYYaQPEH23gy7F4b7BXY(H3OumPUt7B2(q)G9HSeR0gjXqWDiiqccQMwcqmxidPvq)qjFsmQudg1L8kXur4tjXuOfCoUjOksLYfoJdjXeapiGRsS(ezV1gMgugqn1l0(2aB)Z3)0(qAFXmS(GxLrCT2ujVUeOuwgqn1l0(2aB)dpyFlw2p8gLIj1DAFZ2h6hSpKLyL2ijMcTGZXnbvrQuUWzCiziTc6qxYNeJk1GrDjVsmve(usSW7ekgqljMoD2LycGheWvjwFIS3AdtdkdOM6fAFBGT)57FAFiTVygwFWRYiUwBQKxxcukldOM6fAFBGT)HhSVfl7hEJsXK6oTVz7d9d2hYsSsBKel8oHIb0sIPtNDziTc6qJKpjgvQbJ6sELyQi8PKyq4kln3ekgqdjXeapiGRsS(ezV1gMgugqn1l0(2aB)Z3)0(qAFXmS(GxLrCT2ujVUeOuwgqn1l0(2aB)dpyFlw2p8gLIj1DAFZ2h6hSpKLyL2ijgeUYsZnHIb0qYqgsSoDvowi5tAf(s(KyQi8PKyiCeJLyJ4yjgvQbJ6sELH0QdL8jXur4tjXqEzIsn1KlKyuPgmQl5vgsRGUKpjgvQbJ6sELycGheWvjgCfIrKur4qq7FAFveoeuIkQ5eAFZ2)89To7hkJQi71La1KPsnyuFFZ3hs7hkJQi71La1KPsnyuF)t7hkJQi7vqGszjX0m4qHpvMk1Gr99HSetfHpLetOmwsfHpvI5OqIXCuKkTrsm4keJqgsRGgjFsmQudg1L8kXeapiGRsSJ2hs7JJISxxcuklRIWHG2)0(9jYERnmnOmGAQxO9nFF833M9Xrr2RlbkLLbut9cTpK33IL9r4iglfkWefOSqdvWSJA7BZ(4VVfl7F0(HYOkYMaEBCaLMBcXHdqnvyptLAWOUetfHpLetOHky2rnziT6CjFsmQudg1L8kXeapiGRsmveoeuIkQ5eAFB2)qjMkcFkjMqzSKkcFQeZrHeJ5OivAJKy6qYqALTi5tIrLAWOUKxjMkcFkjM3AdtdsIjaEqaxLya6cieC1Gr7FAFiT)r7hkJQil0qfm7OwMk1Gr99TyzFXmS(GxLfAOcMDuldOM6fAFB2hqn1l0(qwIjSlyukuGjkqsRWxgsRols(KyuPgmQl5vIjaEqaxLyHYOkYEfeOuwsmndou4tLPsnyuF)t7RIWNklGRdkzmSi7v6YCtWJ9pTpGAQxO9nB)ohqdFQ9TE7Fq(CjMkcFkjM3AdtdsgsRG2s(KyuPgmQl5vIPIWNsIjuglPIWNkXCuiXyoksL2ijMOJKH0kRVKpjgvQbJ6sELycGheWvj2r7JJISxxcuklRIWHG23IL9pA)qzufztaVnoGsZnH4WbOMkSNPsnyuxIPIWNsIDhbhI6j1AjGhuYG0MmKwH)bs(KyuPgmQl5vIjaEqaxLygC3BgqIJzecLUdqqzaPIqIPIWNsIfWPexzmCvpDhGGKH0k8XxYNetfHpLedhhWV29YuYGPOqIrLAWOUKxziTc)dL8jXOsnyuxYReta8GaUkXoA)(ezXucQcGgupDzAJsgCGkdOM6fA)t7F0(Qi8PYIPeufanOE6Y0gL9kDzUj4HetfHpLetmLGQaOb1txM2iziTcFOl5tIPIWNsIbifNxMsxM2iKeJk1GrDjVYqAf(qJKpjMkcFkjMaUwfXsDQn11bKeJk1GrDjVYqAf(Nl5tIrLAWOUKxjMkcFkjgCfIriXeapiGRsmiTFFIS3AdtdkdOM6fAFB2Vpr2BTHPbL7Can8P236T)b5Z33IL9pA)qzufzVccukljMMbhk8PYuPgmQVpK3)0(qA)J2xmdRp4vzexRnvYRlbkLLbK2TVVfl7F0(HYOkYMaEBCaLMBcXHdqnvyptLAWO((wSSFOmQISjG3ghqP5MqC4autf2ZuPgmQV)P9Xrr2RlbkLLbut9cTVzW2h)d2hYsmHDbJsHcmrbsAf(YqAf(2IKpjgvQbJ6sELycGheWvjwOmQISjG3ghqP5MqC4autf2ZuPgmQV)P9Xrr2RlbkLLvr4qqsmve(usmHYyjve(ujMJcjgZrrQ0gjXmnioCjVUeOuMmKwH)zrYNetfHpLednCS01bKeJk1GrDjVYqAf(qBjFsmQudg1L8kXgCsmefsmve(usmiuGRgmsIbHY4ijMkchckrf1CcTVn7J)(N2xmdRp4vz4keJidOM6fAFZGTp(hSVfl7lMH1h8QmIR1Mk51LaLYYaQPEH23my7J)57FAFiTFOmQISjG3ghqP5MqC4autf2ZuPgmQVVfl7hkJQi3vWXj0WXsEHc1WzEyptLAWO((N2xmdRp4v5UcooHgowYluOgoZd7za1uVq7BgS9X)89H8(wSSFOmQICxbhNqdhl5fkudN5H9mvQbJ67FAFXmS(GxL7k44eA4yjVqHA4mpSNbut9cTVzW2h)Z3)0(qAFXmS(GxLrCT2ujVUeOuwgqn1l0(2SF4nkftQ70(wSSVygwFWRYiUwBQKxxcukldOM6fAFZ3xmdRp4vzexRnvYRlbkLL7Can8P23M9dVrPysDN2hYsmiuqQ0gjXWndlHgowcbxbDKmKwHV1xYNeJk1GrDjVsmbWdc4QeZG7EZgQ44oqVrUp4v7FAF0WXsi4kOVVnW2h)857BD2)Gm0336TFOmQI8LPi4deeitLAWO((N2)O9HqbUAWOmUzyj0WXsi4kOJKyQi8PKyIPUm1eqdsgsRo8ajFsmQudg1L8kXeapiGRsm0WXsi4kOVVz7F4(N2hs7F0(qOaxnyug3mSeA4yjeCf0r7BXY(c4kWeH23M9XFFilXur4tjXqW1(GNbhOKH0QdXxYNeJk1GrDjVsmbWdc4Qeds7hkJQiBc4TXbuAUjehoa1uH9mvQbJ67BXY(Q1sapOSaOi4EzkjGRdktLAWO((qE)t7JJISxxcuklRIWHG23IL9n4U3CxbhNqdhl5fkudN5H9mhU9TyzFdU7ndiXXmcHs3biOmGurS)P9n4U3mGehZiekDhGGYaQPEH23M9fkksH3ijMkcFkjMaUoOKXWcziT6WdL8jXOsnyuxYReta8GaUkXm4U3SHkoUd0BK5WT)P9pAFiuGRgmkJBgwcnCSecUc6O9pT)r7hkJQitaT7cn8PYuPgmQlXur4tjXeW1bLmgwidPvhcDjFsmQudg1L8kXeapiGRsSJ2hcf4QbJY4MHLqdhlHGRGoA)t7hkJQitaT7cn8PYuPgmQV)P9H0(DYG7EZeq7UqdFQmGAQxO9nBFHIIu4nAFlw23G7EZgQ44oqVrMd3(qwIPIWNsIjGRdkzmSqgsRoeAK8jXOsnyuxYReta8GaUkXG0(OHJLqWvqFFBGTp0KpFFRZ(hKpCFR3(QiCiOevuZj0(qE)t7dP9pA)qzufztaVnoGsZnH4WbOMkSNPsnyuFFlw2xmdRp4vzexRnvYRlbkLLbut9cTVn7Fw2hYsmve(usmbCDqjJHfYqA1HNl5tIrLAWOUKxjMa4bbCvIjGRateAFB2hFjMkcFkjMyQltnb0GKH0QdTfjFsmve(usmVeEranijgvQbJ6sELHmKHedccG8PKwD4b4B9paAJ)bsm8uq5LjKeZAA4gqq99TL9vr4tTpZrbkVqjXq4iH0QdTLZIedhyUoJKy2EFBfHcaNi8P2)mvbSrC8cLT3hEe4qw34NFtEaNZilMg)iVXX0WNsa0BWpYBc(xOS9(qPfNcSV)H4ZZ(hEWHhSqTqz79pZNDsWfuFFd6oaAFX0m0yFdYKxO8(NjcbHlq7xtzDGRG2LJTVkcFk0(tXSNxOS9(Qi8PqzCasmndnGDzk64fkBVVkcFkughGetZqdZHX)DM(cLT3xfHpfkJdqIPzOH5W4x5m1Ok0WNAHsfHpfkJdqIPzOH5W4hX1AtLWrXcLkcFkughGetZqdZHXVjG3ghqP5MqQa4xxq84xyHYOkYMaEBCaLMBcPcGFDbLPsnyuFHY27RIWNcLXbiX0m0WCy8Jkfhc(ejuObAHsfHpfkJdqIPzOH5W4h3e(uluQi8PqzCasmndnmhg)OHJLUoGwOur4tHY4aKyAgAyom(9s4fb0G4XVWokugvrgnCS01buMk1Gr9fQfkBV)z(StcUG67tqqa77hEJ2pGt7RIya77O9viuNPgmkVqPIWNcbdHJySeBehVqPIWNczom(rEzIsn1KlwOwOS9(wxkeJyFoeH2x3hHJeUY2hhWhGh23N5Oy)P2VnOy)ghl8qbMOyFKGkf4dIN9n4I9d40(HcmrX(bCaHGpS((cT2hcfyF)oHJQUxM2FQ9dLrvGwOur4tHGjuglPIWNkXCuWtPncgCfIrWJFHbxHyejveoe0jveoeuIkQ5eYSZToHYOkYEDjqnzQudg1nhsHYOkYEDjqnzQudg1pfkJQi7vqGszjX0m4qHpvMk1GrDiVqPIWNczom(fAOcMDuJh)c7iiHJISxxcuklRIWHGo1Ni7T2W0GYaQPEHmhFBWrr2RlbkLLbut9cbzlwq4iglfkWefOSqdvWSJA2GVflhfkJQiBc4TXbuAUjehoa1uH9mvQbJ6lu2EF(WB2puGjk2hjOsb(G2xb0(W1QZO((m)yAFKxMy0(HcmrX(45b89TUuigX(4rkeuFFVY7Jfki8Y0(45b89d4aI2puGjkq8SVUpchjCL5wl13)mzoZ7Jd4dWd777O9be0cohq9fkve(uiZHXVqzSKkcFQeZrbpL2iy6q84xyQiCiOevuZjKnhUqz79TMwByAq7JGpCS((fbbb2)Qm2(Z9UFaN2hhWBkW((HcmrrEFR5U)zOHky2rT9XZzS9b0fqi47BnT2W0G23GUdG23J9PZoohqiE2pGta6SI2VM9bKIMA)y2hpff0(H3O9fkk8Y0(ESqPIWNczom(9wByAq8iSlyukuGjkqWWNh)cdqxaHGRgm6eKokugvrwOHky2rTmvQbJ6wSiMH1h8QSqdvWSJAza1uVq2aOM6fcYlu2EFBFM6b89TMkiqPS9pJPzWHcFQ9dLrvqDE23JZkAFCdc5gmAFRP1gMg0(45m2(fr99JzFdAFaDbeco13hntrG9d4ATFaN2hqn1lVmTFNdOHp1(i1oIN997(bCcqNv0(kdqA3((6(NbCDq7Z7WI9NA)aoTpEQ99Jz)aoTFOatuKxOur4tHmhg)ERnmniE8lSqzufzVccukljMMbhk8PYuPgmQFsfHpvwaxhuYyyr2R0L5MGhNaut9czwNdOHpL17G85lu2EF(Gt7BIkcOS9bCmA)5UFaNRzS)Da7hkJQaTVJ2pM9B6z3BU1s7hWP9lUMbb2FU7ZHi0(ZDFsfWxOur4tHmhg)cLXsQi8Psmhf8uAJGj6Ofkve(uiZHX)DeCiQNuRLaEqjdsB84xyhHJISxxcuklRIWHGSy5OqzufztaVnoGsZnH4WbOMkSNPsnyuFHsfHpfYCy8hWPexzmCvpDhGG4XVWm4U3mGehZiekDhGGYasfXcLkcFkK5W4hhhWV29YuYGPOyHsfHpfYCy8lMsqva0G6PltBep(f2r9jYIPeufanOE6Y0gLm4avgqn1l0PJur4tLftjOkaAq90LPnk7v6YCtWJfkve(uiZHXpGuCEzkDzAJqluQi8PqMdJFbCTkIL6uBQRdOfkBVpFWP997(IP6E4tTpCcq7Rm8u7O9vC4yoH236sHye7hZ(OPrbCVmT)eWjW(bCT2pGt7Jd4nfyF)qbMOyHsfHpfYCy8dxHye8iSlyukuGjkqWWNh)cds9jYERnmnOmGAQxiB6tK9wByAq5ohqdFkR3b5ZTy5OqzufzVccukljMMbhk8PYuPgmQd5tq6iXmS(GxLrCT2ujVUeOuwgqA3UflhfkJQiBc4TXbuAUjehoa1uH9mvQbJ6wSekJQiBc4TXbuAUjehoa1uH9mvQbJ6NWrr2RlbkLLbut9czgm8paYluQi8PqMdJFHYyjve(ujMJcEkTrWmnioCjVUeOugp(fwOmQISjG3ghqP5MqC4autf2ZuPgmQFchfzVUeOuwwfHdbTqz79Xgo2(qRoG2hbF4y99nO95quF)P2xmdRp4v8SVh73hcTFnX(koCKc2hVbeW3hPq4LP9VdyFturan8Y0(ydhBFm4kOJ2VZb8Y0(Izy9bVcTqPIWNczom(rdhlDDaTqz79TM4SI2hVbeW3hfJ4yVmTphU9NAFSHJTpgCf0r7Bq3bq7R73uB9a2xmdRp4v7ZHut0cLkcFkK5W4hcf4QbJ4P0gbd3mSeA4yjeCf0r8aHY4iyQiCiOevuZjKn4FsmdRp4vz4keJidOM6fYmy4FGflIzy9bVkJ4ATPsEDjqPSmGAQxiZGH)5NGuOmQISjG3ghqP5MqC4autf2ZuPgmQBXsOmQICxbhNqdhl5fkudN5H9mvQbJ6NeZW6dEvURGJtOHJL8cfQHZ8WEgqn1lKzWW)CiBXsOmQICxbhNqdhl5fkudN5H9mvQbJ6NeZW6dEvURGJtOHJL8cfQHZ8WEgqn1lKzWW)8tqsmdRp4vzexRnvYRlbkLLbut9czt4nkftQ7KflIzy9bVkJ4ATPsEDjqPSmGAQxiZfZW6dEvgX1AtL86sGsz5ohqdFkBcVrPysDNG8cLT3)mM6YutanO9rWhowF)Py233G2Ndr99JzFef7ZHB)ZaUoO95DybkVp0ktrWhiiW(mkq7FgtDzQjGg0(g0(CiQVpPaMtG9JzFef7ZHBFT23AkHxeqdAFd6oaA)ZG38(wZDFD)MARhW(Izy9bVAFhTVyAEzAFoC8SpsHG2xaxbMi0(3bSVhluQi8PqMdJFXuxMAcObXJFHzWDVzdvCChO3i3h8QtOHJLqWvq3gy4Np36Cqg6wVqzuf5ltrWhiiqMk1Gr9thbHcC1GrzCZWsOHJLqWvqhTqz79XGR9bpdoqTVJ2Ndr99v0(6(DhjgUk2)mM6YutanO9JzFturanO9rWvqhTVF33(WTFFQZASpCfcAFQgotW3)oG919pd46G2N3Hf595doTpsB0(aogH2xngUyFKcHxM23J9Vdy)MARhW(Izy9bVcTVIdhZj0cLkcFkK5W4hbx7dEgCGIh)cdnCSecUc6MD4jiDeekWvdgLXndlHgowcbxbDKflc4kWeHSbFiVqz79pd46G2N3Hf7dxr7JiiiGY2h3GqUbJ2Ndr7lMQ7HpfkV)zaueCVmT)zaxhep7dTe4TXb0(ZDFmoCaQPc78SVw99Tvk449XgoM1T9TMcfQHZ8W((kJT)vHya7luu4LP9v0(nTSV)zWlAFfTpUbHCdgTpEWPAFTSV)C3pGtT9vaTVkchcAHsfHpfYCy8lGRdkzmSGh)cdsHYOkYMaEBCaLMBcXHdqnvyptLAWOUflQ1sapOSaOi4EzkjGRdktLAWOoKpHJISxxcuklRIWHGSyXG7EZDfCCcnCSKxOqnCMh2ZC4SyXG7EZasCmJqO0DackdiveNm4U3mGehZiekDhGGYaQPEHSrOOifEJwOS9(wZDFSHJTpgCf0r7RaA)AI9niVmTpUzyuFFT67FMbA3fA4tTVJ2VMy)qzufuNN9T1COyFeoQ67Fg8I2xr7hWj77BqIPr7RqOotny0cLkcFkK5W4xaxhuYyybp(fMb39MnuXXDGEJmhUthbHcC1GrzCZWsOHJLqWvqhD6OqzufzcODxOHpvMk1Gr9fkBV)zQhW3)md0Ul0WNIN994SI23Gk66cxz7hZ(n9S7n3AP9d40(C4cVr7p1(bCA)ozWDV59TUg8iiiap77XzfTpkCgBFdkccSFm7ZHO9pd46G2N3Hf77Tg1DniM9997(8QIJ7a9g77O95WTqPIWNczom(fW1bLmgwWJFHDeekWvdgLXndlHgowcbxbD0PqzufzcODxOHpvMk1Gr9tqQtgC3BMaA3fA4tLbut9czMqrrk8gzXIb39MnuXXDGEJmhoiVqz79pZqq1(4bNQ9rkeEzIN97Z(1e7pqqaHIB)P2hB4y7JbxbD0cLkcFkK5W4xaxhuYyybp(fgKqdhlHGRGUnWGM85wNdYhA9ur4qqjQOMtiiFcshfkJQiBc4TXbuAUjehoa1uH9mvQbJ6wSiMH1h8QmIR1Mk51LaLYYaQPEHS5Sa5fkBVVTAQZAS)abbekU9NAFbCfyIq7p39pJPUm1eqdAHsfHpfYCy8lM6YutaniE8lmbCfyIq2G)cLkcFkK5W43lHxeqdAHAHY27F2OET)C3hA1b0(oA)WooxOmM99d40(WDtWjuSpoGpapSVVkcFkE23Gl2xqGq9AFKhCA4tH2)QqmG95qEzA)ZaUoO95DyX(EHcs7luQi8PqzDiya1R0Ctxhq84xy4Oi71LaLYYQiCiOtqYG7EZcGIG7LPKaUoOCFWRSy5OqzufztaVnoGsZnH4WbOMkSNPsnyuhYNG0rIzy9bVkdxHyezaPD7wSOIWHGsurnNq2aDiVqz79pd4AveBFBf1M66aA)Py23ViQJ2FkAFRP1gMg0(QiCiO97CaVmTVhO9fkk2)oG9ptMZCEFR7aEtb23puGjk23r7ZHO((WjaT)Da7J8goMl8W(cLkcFkuwhYCy8lGRvrSuNAtDDaXJFH1Ni7T2W0GYaQPEHSrOOifEJwOS9(yEZzky)y2h5LjgTFOatuWZ(bCcq77O9Rz)IO((XSpGUacbFFRP1gMgeAF)U)zOHky2rT9fATFF23J99cfK2xOur4tHY6qMdJFV1gMgepc7cgLcfyIcem85XVWaut9cz25NG0rHYOkYcnubZoQLPsnyu3IfXmS(GxLfAOcMDuldOM6fYga1uVqqEHY27F2WXi0(3bSVygwFWRq73N9Rj2xaxlt0(3bS)zYCM5zF0SVqzS9d40(iTr7ZCuSVI2FQ9rEzIr7hkWefluQi8PqzDiZHXVqzSKkcFQeZrbpL2iyIoAHY27ZhCar7hkWefO9D0(ATVxwhdkWJOAFHIO9d4ASVjhccTVUpI5MGh7BqfD9y)y2hUBcob2hhWhGh2336sHyeluQi8PqzDiZHXpCfIrWJWUGrPqbMOabdFE8lmveoeuIkQ5eYmOzHY27F2OET)C3hA1b0(45m2(OqbX(XSFFAEPbT)u7dNuiSV)zYCM5zFdUyF00O9rUPYVUqRy)ZaUoO95DyX(gC3lAF8CgBFu4m2(MCiO9H7MGtG97Atnr7pCboUy)P2Fecf5tTqPIWNcL1Hmhg)c46Gsgdl4XVWcLrvKnb824akn3eIdhGAQWEMk1Gr9t4Oi71LaLYYQiCiOtqcUcXisQiCiilwcLrvKfAOcMDultLAWOUflHYOkYEDjqnzQudg1pPIWHGsurnNqMbnqEHY27ZRcaEzAFTSVpD2feUWNcXZ(NnQx7p39HwDaTpEoJTVbTphI67RO9BCc47RO9XniKBWiE2h5LG2VXXchhJ2xm4CcT)C33J9fATpkuXXluQi8PqzDiZHXpq9kn301b0cLkcFkuwhYCy8FhbhI6j1AjGhuYG02cLkcFkuwhYCy8JJd4x7EzkzWuuSqz79pZqq1((D)aoTV1LcXi2hhWhGh23N5OyF8M6Sg7Bq7ZHOop7BDPqmI9D0(4aue23VXjGV)fq0(DTPMO91QVpGqdhqqO91QVpc(WX67Bq7ZHO((kRnOy)P2xmdRp4vluQi8PqzDiZHXpCfIrWJWUGrPqbMOabdFE8lmiDuOmQISjG3ghqP5MqC4autf2ZuPgmQBXYrHYOkYEDjqnzQudg1Tyjugvr2eWBJdO0CtioCaQPc7zQudg1pHJISxxcukldOM6fYmy4FaKxOS9(NTr0(qRoG2xR((8c8gkMI23V7ZRkoUd0BSVJ2xfHdbXZ(kAF2uM2xr77X(45m2(1e7pqqaHIB)P2hB4y7JbxbD0cLkcFkuwhYCy87LWlcObXJFHfkJQiFDaL0QNmaEdftrzQudg1pzWDVzdvCChO3iZH7eA4yjeCf0n7CRZb5dTEQiCiOevuZj0cLT336(aob2hB4y7Jbxb99nrfb0Wlt7RgoZdNq7RaAFtZ03)6mgb23V7xtSphYlt7dT6aAFT67ZlWBOykAHsfHpfkRdzom(rdhlDDaTqPIWNcL1Hmhg)IPUm1eqdIh)cZG7EZgQ44oqVrUp4vluQi8PqzDiZHXpcU2h8m4afp(f2rHYOkYxhqjT6jdG3qXuuMk1Gr9fkve(uOSoK5W4xmLGQaOb1txM2iE8lSJ6tKftjOkaAq90LPnkzWbQmGAQxOthPIWNklMsqva0G6PltBu2R0L5MGhNur4qqjQOMtiZoFHY27FM6b89HwDaTVw995f4numfXZ(wtj8IaAq7JNZy7Bq7R7JcWuM2)6mgbY7BnXzfTpoMkO((WjaT)Da7Rm2(HYOkq7hZ(4aeeuf7RcH3PkugZ((CiVmTFaN2h5LjgTFOatuSpycn8P2N5OyHsfHpfkRdzom(9s4fb0GwOwOS9(Nn0fqi477T2W0G23GUdG2NQGaEzAFDFOLdghU9TM6sGsz7hZ(dUWBU1s7Bs0r5fkve(uOSOJG5T2W0G4XVWcLrvKnb824akn3eIdhGAQWEMk1Gr9taQPEHmdAFsmdRp4vzexRnvYRlbkLLbut9czg0KpFHY27F2gr7lM6YutanO9T1COyFd6oaAFOLdghU9TM6sGsz7hZ(dUWBU1s7Bs0r5fkve(uOSOJmhg)IPUm1eqdIh)clugvr2eWBJdO0CtioCaQPc7zQudg1pjMH1h8QmIR1Mk51LaLYYaQPEHmdAYNF6idU7nBOIJ7a9gzoCNqdhlHGRGUzqtg6luQi8Pqzrhzom(5quYdQXtPncMATi4kqrP7urAUjCdEeGh)ctmdRp4vzexRnvYRlbkLL5WzXIygwFWRYiUwBQKxxcukldOM6fYmyqZcLkcFkuw0rMdJFexRnvYRlbkLTqPIWNcLfDK5W43eNc6UwP5MuRLataNh)cdhfzVUeOuwwfHdbTqPIWNcLfDK5W4VRGJtOHJL8cfQHZ8Wop(fgokYEDjqPSSkchc6eKWrr2RlbkLLbut9cz2HhKp3IfCuK96sGszza1uVqMD4HNqdhlHGRGUnWGE2wSy5OqzufztaVnoGsZnH4WbOMkSNPsnyuhYluQi8Pqzrhzom(BuBa2tZnX4eEp1bK2q84xy4Oi71LaLYYQiCiOtqchfzVUeOuwgqn1lKz4FE(ClwqdhlHGRGUzqpF(jizWDV5UcooHgowYluOgoZd7zoCwSCuOmQISjG3ghqP5MqC4autf2ZuPgmQFQpr2BTHPbLbut9czd(hcziVqz79TM7(2kmRzFhTFnX(as7233Gl23(WTVqR9nrX(Tbq7hW1A)PO996sGsz771(g0Da0(bCAFQ67p39d40(x3e8GN9rCT2u7hWP9TM6sGsz7xdEluQi8Pqzrhzom(rCT2ujVUeOugp(fw4nkftQ7KnIzy9bVkJ4ATPsEDjqPSCNdOHpL5q)Gfkve(uOSOJmhg)M4uq31kn3KATeyc484xyH3iBG(bNcVrPysDNSrmdRp4vztCkO7ALMBsTwcmb8CNdOHpL5q)GfkBVV1C3pGt7FDtWJ9XZzS9PQVVbDhaTVTcZA23r7BOIJ3Ndhp7J4ATP2pGt7Bn1LaLYwOur4tHYIoYCy8J4ATPsEDjqPmE8lSqzuf5UcooHgowYluOgoZd7zQudg1pjMH1h8QCxbhNqdhl5fkudN5H9mGAQxiBcfyIIC4nkftQ70cLkcFkuw0rMdJFtCkO7ALMBsTwcmbCE8lmXmS(GxLrCT2ujVUeOuwgqn1lKnH3OumPUtlu2EFR5UFaN2)6MGh7JNZy7tvFFd6oaAFVUeOu2(oAFdvC8(C44zFoeTVTcZAwOur4tHYIoYCy83vWXj0WXsEHc1WzEyNh)ctmdRp4vzexRnvYRlbkLLbut9czt4nkftQ70jCuK96sGszza1uVqMD4b5ZxOur4tHYIoYCy8J3ayDiiVsacnLwcIh)ctmdRp4vzexRnvYRlbkLLbut9czt4nkftQ70jCuK96sGszza1uVqMHp0oF(cLkcFkuw0rMdJ)g1gG90CtmoH3tDaPnep(fMygwFWRYiUwBQKxxcukldOM6fYMWBukMu3PtqchfzVUeOuwgqn1lKz4FE(Clwm4U3CxbhNqdhl5fkudN5H9mhUtOHJLqWvq3mOd5fkBVV1C3pGt7FDtWJ9D0(QXWf7hZ(u15zFoeT)zyRq7J4eW3pGRX(bCY((MOyFfTFJtaF)WB0(C42xr7JBqi3GrluQi8Pqzrhzom(rCT2ujVUeOugp(fw4nkftQ7Kzq)Gfkve(uOSOJmhg)M4uq31kn3KATeyc484xyH3OumPUtMb9dwOur4tHYIoYCy83vWXj0WXsEHc1WzEyNh)cl8gLIj1DYSdX)u4nkftQ7KnqZcLkcFkuw0rMdJ)g1gG90CtmoH3tDaPnep(fw4nkftQ7Kz4BlNcVrPysDNSXwwOur4tHYIoYCy8J3ayDiiVsacnLwcIh)cl8gLIj1DYm8T(NcVrPysDNSbAwOur4tHYIoYCy83O2aSNMBIXj8EQdiTH4XVWcVrPysDNmdFB5u4nkftQ7Kn2YcLkcFkuw0rMdJFd2m90CtbCkrf1SVqPIWNcLfDK5W4hVbW6qqELaeAkTeep(fMygwFWRYiUwBQKxxcukldOM6fYgy2Ybwh8p80r4Oi71LaLYYQiCiOfkve(uOSOJmhg)ahhogL8kHWPcAHsfHpfkl6iZHXpUj8P4XVWWrr2RlbkLLvr4qqwSeEJsXK6ozg0pyHsfHpfkl6iZHXVbbqe4yVmXJFHHJISxxcuklRIWHGobPJcLrvKnb824akn3eIdhGAQWEMk1GrDlwG0recrLGYnQna7P5MyCcVN6asBOCtT1dWIfdU7n3O2aSNMBIXj8EQdiTHYaQPEHG8jiDuOmQICxbhNqdhl5fkudN5H9mvQbJ6wSyWDV5UcooHgowYluOgoZd7za1uVqqgYwSeEJsXK6ozgm8pFHsfHpfkl6iZHXVbBME6YbSZJFHHJISxxcuklRIWHGobPJcLrvKnb824akn3eIdhGAQWEMk1GrDlwG0recrLGYnQna7P5MyCcVN6asBOCtT1dWIfdU7n3O2aSNMBIXj8EQdiTHYaQPEHG8jiDuOmQICxbhNqdhl5fkudN5H9mvQbJ6wSyWDV5UcooHgowYluOgoZd7za1uVqqgYwSeEJsXK6ozgm8pFHsfHpfkl6iZHX)1bKbBMop(fgokYEDjqPSSkchc6eKokugvr2eWBJdO0CtioCaQPc7zQudg1Tybshrievck3O2aSNMBIXj8EQdiTHYn1wpalwm4U3CJAdWEAUjgNW7PoG0gkdOM6fcYNG0rHYOkYDfCCcnCSKxOqnCMh2ZuPgmQBXIb39M7k44eA4yjVqHA4mpSNbut9cbziBXs4nkftQ7KzWW)8fkve(uOSOJmhg)Cik5b1q84xy4Oi71LaLYYQiCiOtq6OqzufztaVnoGsZnH4WbOMkSNPsnyu3IfCuK96sGszza1uVqMb7WdGSflH3OumPUtMb7WdwOur4tHYIoYCy8ZHOKhuJNsBemCJ4ykqU1s9KyA44cn8PsDccxq84xy9jYERnmnOmGAQxiBGD(jijMH1h8QmIR1Mk51LaLYYaQPEHSb2HhyXs4nkftQ7Kzq)aiVqPIWNcLfDK5W4NdrjpOgpL2iyGjeaouq9eeZ0Nj1hgJh)cRpr2BTHPbLbut9czdSZpbjXmS(GxLrCT2ujVUeOuwgqn1lKnWo8alwcVrPysDNmd6ha5fkve(uOSOJmhg)Cik5b14P0gbdb3HGajiOAAjaXCbp(fwFIS3AdtdkdOM6fYgyNFcsIzy9bVkJ4ATPsEDjqPSmGAQxiBGD4bwSeEJsXK6ozg0paYluQi8Pqzrhzom(5quYdQXtPncMcTGZXnbvrQuUWzCiE8lS(ezV1gMgugqn1lKnWo)eKeZW6dEvgX1AtL86sGszza1uVq2a7WdSyj8gLIj1DYmOFaKxOur4tHYIoYCy8ZHOKhuJNsBeSW7ekgqljMoD25XVW6tK9wByAqza1uVq2a78tqsmdRp4vzexRnvYRlbkLLbut9czdSdpWILWBukMu3jZG(bqEHsfHpfkl6iZHXphIsEqnEkTrWGWvwAUjumGgIh)cRpr2BTHPbLbut9czdSZpbjXmS(GxLrCT2ujVUeOuwgqn1lKnWo8alwcVrPysDNmd6ha5fQfkBVpgNHIJTFNqUPI67hZ(dUWBU1s7hWP95qQjA)5UVHkoUd0BSFNd4LP9HwoyC423AQlbkLH4zFT67JdqqqvSVqXHZlt7JNhW3)S15SfBvEHsfHpfkBAqC4sEDjqPmya1R0Ctxhq84xyOHJLqWvqh25NoYG7EZgQ44oqVrMd3jdU7n3O2aSNMBIXj8EQdiTHYC4ozWDVztaVnoGsZnH4WbOMkSNrHko2my4FWcLkcFku20G4WL86sGszMdJFbCDqjJHf84xygC3B2qfh3b6nYC4wOur4tHYMgehUKxxcukZCy8lGRdkzmSGh)cdnCSecUc62adAYhADm4U3CJAdWEAUjgNW7PoG0gkZHBHsfHpfkBAqC4sEDjqPmZHXVaUoOKXWcE8lSJeZW6dEvwm1LPMaAqzoCluQi8PqztdIdxYRlbkLzom(fW1bLmgwWJFHjuuKcVrMHJISxxcukldOM6f6eokYEDjqPSmGAQxiZekksH3iZnj6luQi8PqztdIdxYRlbkLzom(ftDzQjGgep(fMb39MnuXXDGEJCFWRozWDV5g1gG90CtmoH3tDaPnuMd3j0WXsi4kOBdm8ZqFHsfHpfkBAqC4sEDjqPmZHXVyQltnb0G4XVWm4U3SHkoUd0BK7dE1PJm4U3CJAdWEAUjgNW7PoG0gkZH7eKqdhlHGRGUnWomdTTyraxbMiu6cur4tPmBWpB9pHgowcbxbDBGHFg6qEHsfHpfkBAqC4sEDjqPmZHXVyQltnb0G4XVWWrr2RlbkLLbut9cz25luQi8PqztdIdxYRlbkLzom(ftDzQjGgep(fMaUcmriBWFHsfHpfkBAqC4sEDjqPmZHXpA4yPRdOfkve(uOSPbXHl51LaLYmhg)i4AFWZGduluQi8PqztdIdxYRlbkLzom(9s4fb0GwOwOur4tHYWvigbmXuxMAcObXJFHzWDVzdvCChO3i3h8QtOHJLqWvq3gy4FcnCSecUc6MbdAwOur4tHYWvigH5W43BTHPbXJFHfkJQi7vqGszjX0m4qHpvMk1Gr9taQPEHmRZb0WNY6Dq(Clwokugvr2RGaLYsIPzWHcFQmvQbJ6Na0fqi4QbJwOur4tHYWvigH5W4xaxhuYyybp(fMqrrk8gzgCfIrKaut9cTqPIWNcLHRqmcZHXpA4yPRdOfkve(uOmCfIryom(rW1(GNbhO4XVWur4qqjQOMtiZGUflhfkJQiFDaL0QNmaEdftrzQudg1xOur4tHYWvigH5W43lHxeqdIh)ctOOifEJmdUcXisaQPEHKHmKs]] )


end
