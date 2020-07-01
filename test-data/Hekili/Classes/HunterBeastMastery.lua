-- PaladinRetribution.lua
-- May 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


-- needed for Frenzy.
local FindUnitBuffByID = ns.FindUnitBuffByID


if UnitClassBase( 'player' ) == 'HUNTER' then
    local spec = Hekili:NewSpecialization( 253, true )

    spec:RegisterResource( Enum.PowerType.Focus, {
        aspect_of_the_wild = {
            resource = 'focus',
            aura = 'aspect_of_the_wild',

            last = function ()
                local app = state.buff.aspect_oF_the_wild.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 5,
        },

        barbed_shot = {
            resource = 'focus',
            aura = 'barbed_shot',

            last = function ()
                local app = state.buff.barbed_shot.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },

        barbed_shot_2 = {
            resource = 'focus',
            aura = 'barbed_shot_2',

            last = function ()
                local app = state.buff.barbed_shot_2.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },

        barbed_shot_3 = {
            resource = 'focus',
            aura = 'barbed_shot_3',

            last = function ()
                local app = state.buff.barbed_shot_3.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },

        barbed_shot_4 = {
            resource = 'focus',
            aura = 'barbed_shot_4',

            last = function ()
                local app = state.buff.barbed_shot_4.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },

        barbed_shot_5 = {
            resource = 'focus',
            aura = 'barbed_shot_5',

            last = function ()
                local app = state.buff.barbed_shot_5.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },

        barbed_shot_6 = {
            resource = 'focus',
            aura = 'barbed_shot_6',

            last = function ()
                local app = state.buff.barbed_shot_6.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },
        
        barbed_shot_7 = {
            resource = 'focus',
            aura = 'barbed_shot_7',

            last = function ()
                local app = state.buff.barbed_shot_7.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },
        
        barbed_shot_8 = {
            resource = 'focus',
            aura = 'barbed_shot_8',

            last = function ()
                local app = state.buff.barbed_shot_8.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 2,
            value = function () return state.talent.scent_of_blood.enabled and 7 or 5 end,
        },
    } )

    -- Talents
    spec:RegisterTalents( {
        killer_instinct = 22291, -- 273887
        animal_companion = 22280, -- 267116
        dire_beast = 22282, -- 120679

        scent_of_blood = 22500, -- 193532
        one_with_the_pack = 22266, -- 199528
        chimaera_shot = 22290, -- 53209

        trailblazer = 19347, -- 199921
        natural_mending = 19348, -- 270581
        camouflage = 23100, -- 199483

        venomous_bite = 22441, -- 257891
        thrill_of_the_hunt = 22347, -- 257944
        a_murder_of_crows = 22269, -- 131894

        born_to_be_wild = 22268, -- 266921
        posthaste = 22276, -- 109215
        binding_shot = 22499, -- 109248

        stomp = 19357, -- 199530
        barrage = 22002, -- 120360
        stampede = 23044, -- 201430

        aspect_of_the_beast = 22273, -- 191384
        killer_cobra = 21986, -- 199532
        spitting_cobra = 22295, -- 194407
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3562, -- 208683
        relentless = 3561, -- 196029
        adaptation = 3560, -- 214027

        survival_tactics = 3599, -- 202746
        dragonscale_armor = 3600, -- 202589
        viper_sting = 3602, -- 202797
        spider_sting = 3603, -- 202914
        scorpid_sting = 3604, -- 202900
        hiexplosive_trap = 3605, -- 236776
        the_beast_within = 693, -- 212668
        interlope = 1214, -- 248518
        hunting_pack = 3730, -- 203235
        wild_protector = 821, -- 204190
        dire_beast_hawk = 824, -- 208652
        dire_beast_basilisk = 825, -- 205691
        roar_of_sacrifice = 3612, -- 53480
    } )

    -- Auras
    spec:RegisterAuras( {
        a_murder_of_crows = {
            id = 131894,
            duration = 15,
            max_stack = 1,
        },

        aspect_of_the_cheetah = {
            id = 186257,
            duration = 9,
            max_stack = 1,
        },

        aspect_of_the_turtle = {
            id = 186265,
            duration = 8,
            max_stack = 1,
        },

        aspect_of_the_wild = {
            id = 193530,
            duration = 20,
            max_stack = 1,
        },

        barbed_shot = {
            id = 246152,
            duration = 8,
            max_stack = 1,
        },

        barbed_shot_2 = {
            id = 246851,
            duration = 8,
            max_stack = 1,
        },

        barbed_shot_3 = {
            id = 246852,
            duration = 8,
            max_stack = 1,
        },

        barbed_shot_4 = {
            id = 246853,
            duration = 8,
            max_stack = 1,
        },

        barbed_shot_5 = {
            id = 246854,
            duration = 8,
            max_stack = 1,
        },
        
        barbed_shot_6 = {
            id = 284255,
            duration = 8,
            max_stack = 1,
        },
        
        barbed_shot_7 = {
            id = 284257,
            duration = 8,
            max_stack = 1,
        },
        
        barbed_shot_8 = {
            id = 284258,
            duration = 8,
            max_stack = 1,
        },
        
        barbed_shot_dot = {
            id = 217200,
            duration = 8,
            max_stack = 1,
        },

        barrage = {
            id = 120360,
        },

        beast_cleave = {
            id = 118455,
            duration = 4,
            max_stack = 1,
            generate = function ()
                local bc = buff.beast_cleave
                local name, _, count, _, duration, expires, caster = FindUnitBuffByID( "pet", 118455 )

                if name then
                    bc.name = name
                    bc.count = 1
                    bc.expires = expires
                    bc.applied = expires - duration
                    bc.caster = caster
                    return
                end

                bc.count = 0
                bc.expires = 0
                bc.applied = 0
                bc.caster = "nobody"
            end,
        },

        bestial_wrath = {
            id = 19574,
            duration = 15,
            max_stack = 1,
        },

        binding_shot = {
            id = 117405,
            duration = 3600,
            max_stack = 1,
        },

        camouflage = {
            id = 199483,
            duration = 60,
            max_stack = 1,
        },

        concussive_shot = {
            id = 5116,
            duration = 6,
            max_stack = 1,
        },

        dire_beast_basilisk = {
            id = 209967,
            duration = 30,
            max_stack = 1,
        },

        dire_beast_hawk = {
            id = 208684,
            duration = 3600,
            max_stack = 1,
        },

        eagle_eye = {
            id = 6197,
            duration = 60,
        },

        exotic_beasts = {
            id = 53270,
        },

        feign_death = {
            id = 5384,
            duration = 360,
            max_stack = 1,
        },

        freezing_trap = {
            id = 3355,
            duration = 60,
            type = "Magic",
            max_stack = 1,
        },

        frenzy = {
            id = 272790,
            duration = function () return azerite.feeding_frenzy.enabled and 9 or 8 end,
            max_stack = 3,
            generate = function ()
                local fr = buff.frenzy
                local name, _, count, _, duration, expires, caster = FindUnitBuffByID( "pet", 272790 )

                if name then
                    fr.name = name
                    fr.count = count
                    fr.expires = expires
                    fr.applied = expires - duration
                    fr.caster = caster
                    return
                end

                fr.count = 0
                fr.expires = 0
                fr.applied = 0
                fr.caster = "nobody"
            end,
        },

        growl = {
            id = 2649,
            duration = 3,
            max_stack = 1,
        },

        intimidation = {
            id = 24394,
            duration = 5,
            max_stack = 1,
        },

        kindred_spirits = {
            id = 56315,
        },

        masters_call = {
            id = 54216,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },

        misdirection = {
            id = 35079,
            duration = 8,
            max_stack = 1,
        },

        parsels_tongue = {
            id = 248085,
            duration = 8,
            max_stack = 4,
        },

        posthaste = {
            id = 118922,
            duration = 4,
            max_stack = 1,
        },

        spitting_cobra = {
            id = 194407,
            duration = 20,
            max_stack = 1,
        },

        stampede = {
            id = 201430,
        },

        tar_trap = {
            id = 135299,
            duration = 3600,
            max_stack = 1,
        },

        thrill_of_the_hunt = {
            id = 257946,
            duration = 8,
            max_stack = 2,
        },

        trailblazer = {
            id = 231390,
            duration = 3600,
            max_stack = 1,
        },

        wild_call = {
            id = 185789,
        },


        -- PvP Talents
        hiexplosive_trap = {
            id = 236777,
            duration = 0.1,
            max_stack = 1,
        },

        interlope = {
            id = 248518,
            duration = 45,
            max_stack = 1,
        },

        roar_of_sacrifice = {
            id = 53480,
            duration = 12,
            max_stack = 1,
        },

        scorpid_sting = {
            id = 202900,
            duration = 8,
            type = "Poison",
            max_stack = 1,
        },

        spider_sting = {
            id = 202914,
            duration = 4,
            type = "Poison",
            max_stack = 1,
        },

        the_beast_within = {
            id = 212704,
            duration = 15,
            max_stack = 1,
        },

        viper_sting = {
            id = 202797,
            duration = 6,
            type = "Poison",
            max_stack = 1,
        },

        wild_protector = {
            id = 204205,
            duration = 3600,
            max_stack = 1,
        },


        -- Azerite Powers
        dance_of_death = {
            id = 274443,
            duration = 8,
            max_stack = 1
        },
        
        primal_instincts = {
            id = 279810,
            duration = 20,
            max_stack = 1
        },


        -- Utility
        mend_pet = {
            id = 136,
            duration = 10,
            max_stack = 1
        }
    } )

    spec:RegisterStateExpr( "barbed_shot_grace_period", function ()
        return ( settings.barbed_shot_grace_period or 0 ) * gcd.max
    end )

    -- Abilities
    spec:RegisterAbilities( {
        a_murder_of_crows = {
            id = 131894,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            talent = 'a_murder_of_crows',   

            startsCombat = true,
            texture = 645217,

            handler = function ()
                applyDebuff( 'target', 'a_murder_of_crows' )
            end,
        },


        aspect_of_the_cheetah = {
            id = 186257,
            cast = 0,
            cooldown = function () return pvptalent.hunting_pack.enabled and 90 or 180 end,
            gcd = "spell",

            startsCombat = false,
            texture = 132242,

            handler = function ()
                applyBuff( 'aspect_of_the_cheetah' )
            end,
        },


        aspect_of_the_turtle = {
            id = 186265,
            cast = 8,
            cooldown = 180,
            gcd = "spell",
            channeled = true,

            startsCombat = false,
            texture = 132199,

            start = function ()
                applyBuff( 'aspect_of_the_turtle' )
            end,
        },


        aspect_of_the_wild = {
            id = 193530,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = 'cooldowns',

            startsCombat = false,
            texture = 136074,

            nobuff = function ()
                if settings.aspect_vop_overlap then return end
                return "aspect_of_the_wild"
            end,

            handler = function ()
                applyBuff( 'aspect_of_the_wild' )

                if azerite.primal_instincts.enabled then gainCharges( "barbed_shot", 1 ) end
            end,
        },


        barbed_shot = {
            id = 217200,
            cast = 0,
            charges = 2,
            cooldown = function () return 12 * haste end,
            recharge = function () return 12 * haste end,
            gcd = "spell",

            velocity = 50,

            startsCombat = true,
            texture = 2058007,

            cycle = 'barbed_shot',

            handler = function ()
                if buff.barbed_shot.down then applyBuff( 'barbed_shot' )
                else
                    for i = 2, 8 do
                        if buff[ 'barbed_shot_' .. i ].down then applyBuff( 'barbed_shot_' .. i ); break end
                    end
                end

                addStack( 'frenzy', 8, 1 )

                setCooldown( 'bestial_wrath', cooldown.bestial_wrath.remains - 12 )
                applyDebuff( 'target', 'barbed_shot_dot' )
            end,
        },


        barrage = {
            id = 120360,
            cast = function () return 3 * haste end,
            cooldown = 20,
            gcd = "spell",
            channeled = true,

            spend = 60,
            spendType = "focus",

            startsCombat = true,
            texture = 236201,

            start = function ()
            end,
        },


        bestial_wrath = {
            id = 19574,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            startsCombat = true,
            texture = 132127,

            recheck = function () return buff.bestial_wrath.remains end,
            handler = function ()
                applyBuff( 'bestial_wrath' )
                if pvptalent.the_beast_within.enabled then applyBuff( "the_beast_within" ) end
            end,
        },


        binding_shot = {
            id = 109248,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            talent = 'binding_shot',

            startsCombat = true,
            texture = 462650,

            handler = function ()
                applyDebuff( 'target', 'binding_shot' )
            end,
        },


        camouflage = {
            id = 199483,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            texture = 461113,

            handler = function ()
                applyBuff( 'camouflage' )
            end,
        },


        chimaera_shot = {
            id = 53209,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            velocity = 50,

            talent = 'chimaera_shot',

            startsCombat = true,
            texture = 236176,

            handler = function ()
                gain( 10 * min( 2, active_enemies ), 'focus' )                
            end,
        },


        cobra_shot = {
            id = 193455,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            velocity = 45,

            spend = 35,
            spendType = "focus",

            startsCombat = true,
            texture = 461114,

            handler = function ()                
                if talent.venomous_bite.enabled then setCooldown( 'bestial_wrath', cooldown.bestial_wrath.remains - 1 ) end
                if talent.killer_cobra.enabled and buff.bestial_wrath.up then setCooldown( 'kill_command', 0 )
                else setCooldown( 'kill_command', cooldown.kill_command.remains - 1 ) end
            end,
        },


        concussive_shot = {
            id = 5116,
            cast = 0,
            cooldown = 5,
            gcd = "spell",

            velocity = 50,

            startsCombat = true,
            texture = 135860,

            handler = function ()
                applyDebuff( 'target', 'concussive_shot' )
            end,
        },


        counter_shot = {
            id = 147362,
            cast = 0,
            cooldown = 24,
            gcd = "off",

            toggle = 'interrupts',

            startsCombat = true,
            texture = 249170,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        dire_beast = {
            id = 120679,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = 25,
            spendType = "focus",

            startsCombat = true,
            texture = 236186,

            handler = function ()
                summonPet( 'dire_beast', 8 )
            end,
        },


        dire_beast_basilisk = {
            id = 205691,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 60,
            spendType = "focus",

            toggle = "cooldowns",
            pvptalent = "dire_beast_basilisk",

            startsCombat = true,
            texture = 1412204,

            handler = function ()
                applyDebuff( "target", "dire_beast_basilisk" )
            end,
        },


        dire_beast_hawk = {
            id = 208652,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            pvptalent = "dire_beast_hawk",

            startsCombat = true,
            texture = 612363,

            handler = function ()
                applyDebuff( "target", "dire_beast_hawk" )
            end,
        },


        disengage = {
            id = 781,
            cast = 0,
            charges = 1,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",

            startsCombat = false,
            texture = 132294,

            handler = function ()
            end,
        },


        eagle_eye = {
            id = 6197,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132172,

            handler = function ()
                applyBuff( 'eagle_eye', 60 )
            end,
        },


        exhilaration = {
            id = 109304,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 461117,

            handler = function ()
                gain( 0.3 * health.max, "health" )
            end,
        },


        feign_death = {
            id = 5384,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 132293,

            handler = function ()
                applyBuff( 'feign_death' )
            end,
        },


        flare = {
            id = 1543,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 135815,

            handler = function ()
            end,
        },


        freezing_trap = {
            id = 187650,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 135834,

            handler = function ()
                applyDebuff( 'target', 'freezing_trap' )
            end,
        },


        hiexplosive_trap = {
            id = 236776,
            cast = 0,
            cooldown = 40,
            gcd = "spell",

            pvptalent = "hiexplosive_trap",

            startsCombat = false,
            texture = 135826,

            handler = function ()
            end,
        },


        interlope = {
            id = 248518,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = "interlope",

            startsCombat = false,
            texture = 132180,

            handler = function ()
            end,
        },


        intimidation = {
            id = 19577,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 132111,

            handler = function ()
                applyDebuff( 'target', 'intimidation' )
            end,
        },


        kill_command = {
            id = 34026,
            cast = 0,
            cooldown = function () return 7.5 * haste end,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 132176,

            recheck = function () return buff.barbed_shot.remains end,
            handler = function ()
            end,
        },


        masters_call = {
            id = 272682,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 236189,

            handler = function ()
            end,
        },


        misdirection = {
            id = 34477,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            nopvptalent = "interlope",

            startsCombat = true,
            texture = 132180,

            handler = function ()                
            end,
        },


        multishot = {
            id = 2643,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 40,
            spendType = "focus",

            startsCombat = true,
            texture = 132330,

            velocity = 40,

            recheck = function () return buff.beast_cleave.remains - gcd, buff.beast_cleave.remains end,
            handler = function ()
                applyBuff( 'beast_cleave' )
            end,
        },


        roar_of_sacrifice = {
            id = 53480,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            pvptalent = "roar_of_sacrifice",

            startsCombat = false,
            texture = 464604,

            handler = function ()
                applyBuff( "roar_of_sacrifice" )
            end,
        },


        scorpid_sting = {
            id = 202900,
            cast = 0,
            cooldown = 24,
            gcd = "spell",

            pvptalent = "scorpid_sting",

            startsCombat = true,
            texture = 132169,

            handler = function ()
                applyDebuff( "target", "scorpid_sting" )
                setCooldown( "spider_sting", max( 8, cooldown.spider_sting.remains ) )
                setCooldown( "viper_sting", max( 8, cooldown.viper_sting.remains ) )
            end,
        },


        spider_sting = {
            id = 202914,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = "spider_sting",

            startsCombat = true,
            texture = 1412206,

            handler = function ()
                applyDebuff( "target", "spider_sting" )
                setCooldown( "scorpid_sting", max( 8, cooldown.scorpid_sting.remains ) )
                setCooldown( "viper_sting", max( 8, cooldown.viper_sting.remains ) )
            end,
        },


        spitting_cobra = {
            id = 194407,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            talent = 'spitting_cobra',
            toggle = 'cooldowns',

            startsCombat = true,
            texture = 236177,

            handler = function ()
                summonPet( 'spitting_cobra', 20 )
                applyBuff( 'spitting_cobra', 20 )
            end,
        },


        stampede = {
            id = 201430,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = 'cooldowns',
            talent = 'stampede',

            startsCombat = true,
            texture = 461112,

            recheck = function () return cooldown.bestial_wrath.remains - gcd, target.time_to_die - 15 end,
            handler = function ()
            end,
        },


        summon_pet = {
            id = 883,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "focus",

            startsCombat = false,
            texture = 'Interface\\ICONS\\Ability_Hunter_BeastCall',

            essential = true,
            nomounted = true,

            usable = function () return not pet.exists end,
            handler = function ()
                summonPet( 'made_up_pet', 3600, 'ferocity' )
            end,
        },


        tar_trap = {
            id = 187698,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 576309,

            handler = function ()
            end,
        },


        viper_sting = {
            id = 202797,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            pvptalent = "viper_sting",

            startsCombat = true,
            texture = 236200,

            handler = function ()
                applyDebuff( "target", "spider_sting" )
                setCooldown( "scorpid_sting", max( 8, cooldown.scorpid_sting.remains ) )
                setCooldown( "viper_sting", max( 8, cooldown.viper_sting.remains ) )
            end,
        },


        --[[ wartime_ability = {
            id = 264739,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 1518639,

            handler = function ()
            end,
        }, ]]


        -- Pet Abilities
        -- Moths
        serenity_dust = {
            id = 264055,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Sporebats
        spore_cloud = {
            id = 264056,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Water Striders
        soothing_water = {
            id = 264262,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Bats
        sonic_blast = {
            id = 264263,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Nether Rays
        nether_shock = {
            id = 264264,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Cranes
        chijis_tranquility = {
            id = 264028,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Spirit Beasts
        spirit_shock = {
            id = 264265,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,

            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Stags
        natures_grace = {
            id = 264266,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            toggle = "interrupts",

            startsCombat = true,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return buff.dispellable_enrage.up or buff.dispellable_magic.up, "requires enrage or magic debuff"
            end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
                removeBuff( "dispellable_magic" )
            end,
        },


        -- Utility
        mend_pet = {
            id = 136,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            startsCombat = false,

            usable = function ()
                if not pet.alive then return false, "requires a living pet" end
                return true
            end,
        }


    } )


    spec:RegisterPack( "Beast Mastery", 20200425, [[dWKFnbqiOQ8iLsztuj(euvnkLKoLsIvPuQYRuQmlPe3ckj7Iu)ck1WKs1XusTmLIEgvQmnQKY1GsSnQKQVrLenoQK05ukjRJkv18Gc3tOSpLchuPewijvpKkvzIkLk1fLsc5JkLkgPsPsoPsjQvkuntPKOBQuQk7ekAOsjHAPsjbpfstfQYvvkvvFvPezSujHZQusTxu9xqdMWHfTyiEmWKfCzKnlvFMKmAP40swTus61sPmBQ62Ky3Q8BfdxihhkPwokpNOPt56uX2jP8DOY4LsQZRu16Psz(kX(v181C84OH0ioMB2(MT3URTjw0T7QUMR6AUsoQTpI4OrjOTufXrVuH4OQtP0EX2xknITNJgL79tg44XrLJddqC0gZIKUp2yRQSghenyuWwwko(0Q5aSSByllfa2CueNYBB5JJWrdPrCm3S9nBVD31(AoA6yndJJIwkUhhTPcb64iC0ajbC0T9c1PuAVy7lLgX2)ITlNZi2hFBVOXSiP7Jn2QkRXbrdgfSLLIJpTAoal7g2YsbG9hFBVylIyL)fBILwEXMTVz7F8p(2EH71KNks6(F8T9cS6fBriqHx4EJZze7fOnJ9cBErG6PJ3ErcSAUx4lPP)4B7fy1l2(L0lSsHG2adf9IvvtQFHLmvKPTsHG2adfTYlS5f5zfOIsJEbDHxm9xqhyCoJy6p(2Ebw9ITieErOKrKxIDKdtfjFHAv(chR8LT)fjWQ5EHVKM(JVTxGvVWy11gzAxHUjLqWm(WG7ErjFHZjDIIgMrb9hFBVaREH71qG2ErFyVaWkdgbmiWHXOZ0CuFjnjhpoAG6PJ344XXCnhpoMR54XnokDjINcC15OjWQ54Ok0fGrKXrbSYiwLC0iY0nu6TgyeWEbgVWDTZnoMBYXJJsxI4PaxDoAcSAooki9EycSAoOVKghfWkJyvYrdeItVRbP0QtL2j6fllVaXP31HsgrEFI4jOsQQaANOxSS8ceNExhkze59jING0XsvK2jIJ6lPbVuH4Oow5lBp34y6ooECu6sepf4QZrbSYiwLC0igPgufiOxRtzebm40HwdbXv(WlwwEHvke0gyOOxGXl2SDoAcSAooQJKGLrksUXX0144XrPlr8uGRohfWkJyvYrbZ4ddUtNYicyWPdTgcIR8bnJuY6KqvoKu(cmEXAS8cxEHvke0gyOOxSXlw3oh9sfIJMUjBswkH95m40HrdoIXrtGvZXrt3KnjlLW(CgC6WObhX4ghtSWXJJsxI4PaxDokGvgXQKJgieNExZs3ggemS0ddeItVRDIEHlVy1xGVxqyTtffrbD6MSjzPe2NZGthgn4i2lwwEbygFyWD60nztYsjSpNbNomAWrmnJuY6KVyJx4QU(lwwEbjL0binIFMaC6qRHG0rk71kzRoSxSYlC5fR(IigPgufiOxRtzebm40HwdbXv(WlwwEb(EbH1ovuef0G9a)yS5kaeXNs7fU8ceNExNYicyWPdTgcIR8bnJuY6KVyJxSvVyLx4Ylw9f47fKushG0G5c0jPa0xDQpmaPvYwDyVyz5fio9UwLtYcvEWPdt3i2ynANOxSYlC5fR(clzQit3qP3A0ra7fy8c3HLxSS8c89cskPdqAWCb6Kua6Ro1hgG0kzRoSxSS8c89cl90z62kVNyW6KwDattxI4PWlw5fllVy1xeieNExZs3ggemS0ddeItVRddU7fllVWkfcAdmu0lW4fB66VyLx4YlSsHG2adf9InEXQVytx7fBVxS6laZ4ddUtd2d8JXMRaqeFknnJuY6KVy3lCTxGXlSsHG2adf9IvEXkC0lvioAkBulpsczPBddcgw65OjWQ54OPSrT8ijKLUnmiyyPNBCmDDoECu6sepf4QZrbSYiwLCueNExJqsRspehlTgDyWDVyz5fwPqqBGHIEbgValC0ey1CCuWEGFm2CfaI4tPXrPENag8sfIJc2d8JXMRaqeFknUXX0vYXJJsxI4PaxDoAcSAooki9EycSAoOVKgh1xsdEPcXrbbj34y6QC84O0LiEkWvNJMaRMJJcsVhMaRMd6lPXrbSYiwLC0eyLAeKosPi5lW4fBYr9L0GxQqCuPXnoMBfhpokDjINcC15OjWQ54OG07HjWQ5G(sACuaRmIvjhnbwPgbPJuks(InEXAoQVKg8sfIJc8uQgXnUXrJyeyuqsJJhhZ1C84OjWQ54OshfL5GrKXrPlr8uGRo34yUjhpokDjINcC15OxQqC00nztYsjSpNbNomAWrmoAcSAooA6MSjzPe2NZGthgn4ig34y6ooEC0ey1CCuCdZhuJQdYi5C5biokDjINcC15ghtxJJhhnbwnhhvLtYcvEWPdt3i2ynCu6sepf4QZnoMyHJhhnbwnhhvHug2E40HEhqfGbgLksokDjINcC15ghtxNJhhLUeXtbU6CuaRmIvjhfFVGLvasQrNPRtnh)rSeXtAQ1L0KVWLxS6liS2PIIOGwTKvjING1z0jlBpuvPkvB8gCKGY7tRovqgLaByVyfoAcSAookypWpgBUcar8P04OuVtadEPcXrb7b(XyZvaiIpLg34y6k54XrPlr8uGRohfWkJyvYrX3lyzfGKA0z66uZXFelr8KMADjn5lC5fR(cJvxBKPxRBsjemJpm4UxS7fgRU2itVPUjLqWm(WG7EbgVyZxSS8ccRDQOikOvlzvI4jyDgDYY2dvvQs1gVbhjO8(0QtfKrjWg2lwHJMaRMJJc2d8JXMRaqeFknok17eWGxQqCuWEGFm2CfaI4tPXnoMUkhpokDjINcC15OawzeRsok(EblRaKuJotxNAo(JyjIN0uRlPj5OjWQ54O9b4iPamDJyLrqekv4ghZTIJhhLUeXtbU6C0igbsPbTsH4OR1R5OjWQ54OPmIagC6qRHG4kFGJcyLrSk5O47fPBeRmshXkL0dRtA1bmPMUeXtHx4YlW3liPKoaPjPKoabNo0AiyFaoY6ublwj1kzRoSx4Ylw9few7urruqNUjBswkH95m40HrdoI9ILLxGVxqyTtffrbnypWpgBUcar8P0EXkCJJ56254XrPlr8uGRohnIrGuAqRuio6Anw4OjWQ54OiK0Q0dXXsRHJcyLrSk5OPBeRmshXkL0dRtA1bmPMUeXtHx4YlW3liPKoaPjPKoabNo0AiyFaoY6ublwj1kzRoSx4Ylw9few7urruqNUjBswkH95m40HrdoI9ILLxGVxqyTtffrbnypWpgBUcar8P0EXkCJJ561C84OjWQ54OrJvZXrPlr8uGRo34ghf4PunIJhhZ1C84O0LiEkWvNJcyLrSk5Oio9UUZOZT9ANOx4YlqC6DDNrNB71msjRt(cmI9cvGGwjB9l29cKKHqbOSzmOkwciyeXQjWrtGvZXrrsgcfGYMX4OG9apbTKPImjhZ1CJJ5MC84O0LiEkWvNJcyLrSk5OQabTs26xGvVaXP31iukniWtPAKMrkzDYxSXlAxVjw4OjWQ54OkoERKnJXnoMUJJhhLUeXtbU6CuaRmIvjhT749qgbAsMkcALc9cmEHkqqRKT(fU8cWm(WG70iK0Q0dXXsRrZiLSojhnbwnhhfjziuakBgJJc2d8e0sMkYKCmxZnoMUghpoAcSAooAkJiGbNo0AiiUYh4O0LiEkWvNBCmXchpokDjINcC15OawzeRsokItVRtzebm40HwdbXv(G2j6fU8ceNExJqsRspehlTgTt0lwwEHvke0gyOOxGXlwJfoAcSAooQ0sLikqCJJPRZXJJsxI4PaxDokGvgXQKJcMXhgCNoLreWGthAneex5dAgPK1jHQCiP8fB8InB)fllVWspDMEocIRSgO1qWOe0MMUeXtHxSS8cRuiOnWqrVaJxSglC0ey1CCuesAv6H4yP1WnoMUsoEC0ey1CCuqtPKelHYMX4O0LiEkWvNBCmDvoEC0ey1CC0eQ4WcedoDiGn4KCu6sepf4QZnoMBfhpoAcSAooksYyPkIJsxI4PaxDUXXCD7C84O0LiEkWvNJcyLrSk5OjWk1iiDKsrYxGXlCTxSS8c89I0nIvgPzzufGmYpzqtxI4PahnbwnhhTTY7HGrrjVa34yUEnhpoAcSAooAOyeeHsPXrPlr8uGRo34yUEtoECu6sepf4QZrbSYiwLCueNEx3z052EDyWDVWLxS6lanjtfjHDwcSAU0)InEXATR(ILLxG407AesAv6H4yP1ODIEXkVyz5fGz8Hb3Ptzebm40HwdbXv(GMrkzDYxGXlqC6DDNrNB71bhwA1CVaREHkq4fU8I0nIvgPJyLs6H1jT6aMutxI4PWlwwEbOjzQijSZsGvZL(xSXlwRDTxSS8cRuiOnWqrVaJxSvC0ey1CCuKKHqbOSzmokypWtqlzQitYXCn34yU2DC84OjWQ54O9b4iPamDJyLrqekv4O0LiEkWvNBCmx7AC84OjWQ54OroSQVVovqeFknokDjINcC15ghZ1yHJhhnbwnhhfmhGoJLgfGDFQqCu6sepf4QZnoMRDDoEC0ey1CCue)mb40HwdbPJu2ZrPlr8uGRo34yU2vYXJJsxI4PaxDokGvgXQKJI407AgbAZtsjSpmaPDIEXYYlqC6DnJaT5jPe2hgGGGX5mIPLwcA7fy8I1TZrtGvZXrTgc6CiJZfG9HbiUXXCTRYXJJsxI4PaxDokGvgXQKJMUrSYinlJQaKr(jdA6sepfEHlVibwPgbPJuks(InEXMC0ey1CCufhVvYMX4ghZ1BfhpokDjINcC15OawzeRsokygFyWD62kVhcgfL8cAgPK1jFXgVOpahP2kfcAdujB9lC5fR(IeyLAeKosPi5lW4fU7fllVaFViDJyLrAwgvbiJ8tg00LiEk8Iv4OjWQ54OGbHLqzZyCJJ5MTZXJJMaRMJJkJkZQtfemiSKJsxI4PaxDUXnokii54XXCnhpokDjINcC15OawzeRsokygFyWDAesAv6H4yP1OzKswN8fB8c31ohnbwnhhnpajnw6HG075ghZn54XrPlr8uGRohfWkJyvYrbZ4ddUtJqsRspehlTgnJuY6KVyJx4U25OjWQ54O9Iri(zcCJJP744XrPlr8uGRohfWkJyvYrrC6DDkJiGbNo0AiiUYh0orVWLxS6lSsHG2adf9InEbygFyWDAeIjjwB1PshCyPvZ9IDVi4WsRM7fllVy1xyjtfz6gk9wJocyVaJx4oS8ILLxGVxyPNot3w59edwN0QdyA6sepfEXkVyLxSS8cRuiOnWqrVaJxS2DC0ey1CCueIjjwB1PIBCmDnoECu6sepf4QZrbSYiwLCueNExNYicyWPdTgcIR8bTt0lC5fR(cRuiOnWqrVyJxaMXhgCNgXpta2Dy71bhwA1CVy3lcoS0Q5EXYYlw9fwYurMUHsV1OJa2lW4fUdlVyz5f47fw6PZ0TvEpXG1jT6aMMUeXtHxSYlw5fllVWkfcAdmu0lW4fRDDoAcSAookIFMaS7W2ZnoMyHJhhLUeXtbU6CuaRmIvjhfXP31DgDUTx7e9cxEbItVR7m6CBVMrkzDYxSXlubcALS1Vyz5f47fio9UUZOZT9ANioAcSAooQVu1ysyR6euPqNXnoMUohpokDjINcC15OawzeRsokItVRriPvPhIJLwJ2j6fU8ceNExNYicyWPdTgcIR8bTt0lC5fwYurMUHsV1OJa2lW4fUdlVyz5fR(IvFbyoPJsI4jD0y1CWPdDoewf8ua2Dy7FXYYlaZjDusepPDoewf8ua2Dy7FXkVWLxyLcbTbgk6fy8cxF9lwwEHvke0gyOOxGXl201FXkC0ey1CC0OXQ54ghtxjhpokDjINcC15OawzeRso6QViIrQbvbc616ugradoDO1qqCLp8ILLxaMXhgCNoLreWGthAneex5dAgPK1jFbgVqfi8ILLxyjtfzARuiOnWqrVaJxSz7VyLxSS8c89cskPdqA1kznhC6WiI1jGvZPvQByC0ey1CCuCdZhuJQdYi5C5biUXX0v54XrPlr8uGRohfWkJyvYrbZ4ddUtNYicyWPdTgcIR8bnJuY6KVaJxSU9xSS8cRuiOnWqrVyJxKaRMtRYjzHkp40HPBeBSgnygFyWDVy3lCx7Vyz5fwPqqBGHIEbgVWDTZrtGvZXrv5KSqLhC6W0nInwd34yUvC84OjWQ54OSkkYtW6GYOeqCu6sepf4QZnoMRBNJhhnbwnhhvHug2E40HEhqfGbgLksokDjINcC15ghZ1R54XrPlr8uGRohfWkJyvYrTKPImDdLERrhbSxSXlC12FXYYlSKPImDdLERrhbSxGrSxSz7Vyz5fwYurM2kfcAdmcyWnB)fB8c31ohnbwnhhLrzuDQGDFQqsUXnoQ044XXCnhpokDjINcC15OawzeRsokItVR7m6CBV2j6fU8ceNEx3z052EnJuY6KVaJxOceEXUxGKmekaLnJbvXsabJiwnHxSS8cWm(WG70iK0Q0dXXsRrZiLSo5lC5fR(IUJ3dzeOjzQiOvk0lW4fQaHxSS8I0nIvgPJyLs6H1jT6aMutxI4PWlC5fGz8Hb3Ptzebm40HwdbXv(GMrkzDYxGXlubcVyfoAcSAooksYqOau2mg34yUjhpokDjINcC15OawzeRsoAFaoYxS7f9b4i1msfDVy79cvGWlW4f9b4i1kzRFHlVaXP31iK0Q0dXXsRrhgC3lC5fR(c89IWyAWCa6mwAua29PcbrCyNMrkzDYx4YlW3lsGvZPbZbOZyPrby3NkKUoy3xQASxSYlwwEr3X7Hmc0Kmve0kf6fy8cvGWlwwEHvke0gyOOxGXlWchnbwnhhfmhGoJLgfGDFQqCJJP744XrPlr8uGRohfWkJyvYrrC6DDkJiGbNo0AiiUYh0Hb39cxEXQVamJpm4onsYqOau2mMg0KmvK8fy8I1Vyz5f47fPBeRmshXkL0dRtA1bmPMUeXtHxSchnbwnhhnLreWGthAneex5dCJJPRXXJJsxI4PaxDokGvgXQKJI4076ugradoDO1qqCLpODIEHlVaXP31iK0Q0dXXsRr7e9ILLxyLcbTbgk6fy8I1yHJMaRMJJkTujIce34yIfoEC0ey1CC0eQ4WcedoDiGn4KCu6sepf4QZnoMUohpokDjINcC15OawzeRsokItVRriPvPhIJLwJom4UxSS8cRuiOnWqrVaJxGfoAcSAooAFaoskat3iwzeeHsfUXX0vYXJJsxI4PaxDokGvgXQKJI407AgbAZtsjSpmaPDIEXYYlqC6DnJaT5jPe2hgGGGX5mIPLwcA7fy8I1T)ILLxyLcbTbgk6fy8cSWrtGvZXrTgc6CiJZfG9HbiUXX0v54XrPlr8uGRohfWkJyvYrX3lqC6DncjTk9qCS0A0orVWLxaMXhgCNoLreWGthAneex5dAgPK1jFXgVynwEXYYlSsHG2adf9cmEXAS8IDVqfiWrtGvZXrriPvPhIJLwd34yUvC84O0LiEkWvNJcyLrSk5OPBeRmshYdqWPdduAnAwET9InEX6x4YlqC6DDipabNomqP1OzKswN8fy8cvGahnbwnhhfjziuakBgJBCmx3ohpokDjINcC15OawzeRsokItVRtzebm40HwdbXv(GMrkzDYxSXlw3(l29cvGWlwwEHvke0gyOOxGXlw3(l29cvGahnbwnhhfXptaoDO1qq6iL9CJJ561C84OjWQ54OTvEpemkk5f4O0LiEkWvNBCmxVjhpokDjINcC15OawzeRsokItVRriPvPhIJLwJom4UxSS8clzQitBLcbTbgk6fy8cSWrtGvZXrrsvWPdnwbAtYnoMRDhhpoAcSAookOPusILqzZyCu6sepf4QZnoMRDnoEC0ey1CC0qXiicLsJJsxI4PaxDUXXCnw44XrPlr8uGRohfWkJyvYrT0tNPNJG4kRbAnemkbTPPlr8u4fU8cqtYursyNLaRMl9VyJxSwJLxSS8cqtYursyNLaRMl9VyJxSw7QVyz5fGz8Hb3Ptzebm40HwdbXv(GMrkzDYxGXlqC6DDNrNB71bhwA1CVaREHkq4fU8I0nIvgPJyLs6H1jT6aMutxI4PWlwwEHvke0gyOOxGXl2koAcSAooksYqOau2mg34yU2154XrPlr8uGRohfWkJyvYrrC6DncjTk9qCS0A0Hb39ILLxyLcbTbgk6fy8cxLJMaRMJJg5WQ((6ubr8P04ghZ1UsoEC0ey1CCue)mb40HwdbPJu2ZrPlr8uGRo34yU2v54XrtGvZXrrsglvrCu6sepf4QZnoMR3koECu6sepf4QZrbSYiwLC0vFrFaoYxGvVams7f7ErFaosnJur3l2EVy1xaMXhgCNUTY7HGrrjVGMrkzDYxGvVy9lw5fB8Iey1C62kVhcgfL8cAWiTxSS8cWm(WG70TvEpemkk5f0msjRt(InEX6xS7fQaHx4YlaZ4ddUtJqsRspehlTgnJuY6KqvoKu(InErFaosTvke0gOs26xSS8ceNExRqkdBpC6qVdOcWaJsfP2j6fR8cxEbygFyWD62kVhcgfL8cAgPK1jFXgVy9lwwEHvke0gyOOxGXlChhnbwnhhfmiSekBgJBCm3SDoEC0ey1CCuzuzwDQGGbHLCu6sepf4QZnoMBUMJhhLUeXtbU6CuaRmIvjhfXP31DgDUTxhCyPvZ9cS6fQaHxSXl6oEpKrGMKPIGwPqC0ey1CCuKKHqbOSzmUXnoQJv(Y2ZXJJ5AoEC0ey1CCuW4CgXGYMX4O0LiEkWvNBCm3KJhhnbwnhhvsm6kBpm4inokDjINcC15ght3XXJJMaRMJJkJggbb(XjWrPlr8uGRo34y6AC84OjWQ54OYzSM6ubXLgX4O0LiEkWvNBCmXchpoAcSAooQCUcar8P04O0LiEkWvNBCmDDoEC0ey1CC0JSgIbLndOnokDjINcC15ghtxjhpoAcSAookOPA1scnwEyTt5lBphLUeXtbU6CJJPRYXJJMaRMJJkJkwzqzZaAJJsxI4PaxDUXXCR44XrtGvZXrV0CyKeQILaIJsxI4PaxDUXnUXrvJyYAooMB2(MT3U7AFnhfxYU6uj5OBPTOvaZTmMBh3)fVaVg6fLs0WSx0h2lWFG6PJ3W)lyew7umk8c5OqViDSrjnk8cqtEQiP(J3kRJEHR5(VW9MtnIzu4f43y11gzAxHgmJpm4o8)cBEb(bZ4ddUt7kW)lwDDRxr)X)4BPTOvaZTmMBh3)fVaVg6fLs0WSx0h2lWpWtPAe(FbJWANIrHxihf6fPJnkPrHxaAYtfj1F8wzD0lw7(VW9MtnIzu4f4pImTRqV1ATg)VWMxG)TwR14)fRUzRxr)XBL1rVyt3)fU3CQrmJcVa)rKPDf6TwR14)f28c8V1ATg)Vy11TEf9hVvwh9I1B6(VW9MtnIzu4f4pImTRqV1ATg)VWMxG)TwR14)fRUzRxr)X)4BPTOvaZTmMBh3)fVaVg6fLs0WSx0h2lWpiiX)lyew7umk8c5OqViDSrjnk8cqtEQiP(J3kRJEbwC)x4EZPgXmk8c8hrM2vO3ATwJ)xyZlW)wR1A8)IvDxRxr)X)4BPTOvaZTmMBh3)fVaVg6fLs0WSx0h2lWV0W)lyew7umk8c5OqViDSrjnk8cqtEQiP(J3kRJEXA3)fU3CQrmJcVa)rKPDf6TwR14)f28c8V1ATg)Vy1nB9k6pERSo6fRXI7)c3Bo1iMrHxG)iY0Uc9wR1A8)cBEb(3ATwJ)xS66wVI(J3kRJEXMRD)x4EZPgXmk8c8hrM2vO3ATwJ)xyZlW)wR1A8)Ivx36v0F8p(wwjAygfEHR)Iey1CVWxstQ)4Cuzeb4yUjwChhnIn9YtC0T9c1PuAVy7lLgX2)ITlNZi2hFBVOXSiP7Jn2QkRXbrdgfSLLIJpTAoal7g2YsbG9hFBVylIyL)fBILwEXMTVz7F8p(2EH71KNks6(F8T9cS6fBriqHx4EJZze7fOnJ9cBErG6PJ3ErcSAUx4lPP)4B7fy1l2(L0lSsHG2adf9IvvtQFHLmvKPTsHG2adfTYlS5f5zfOIsJEbDHxm9xqhyCoJy6p(2Ebw9ITieErOKrKxIDKdtfjFHAv(chR8LT)fjWQ5EHVKM(JVTxGvVWy11gzAxHUjLqWm(WG7ErjFHZjDIIgMrb9hFBVaREH71qG2ErFyVaWkdgbmiWHXOZ0F8p(2ErROwtahJcVaH6dJEbyuqs7fiKQ6K6xSfaafzYxCZHvnjtP74FrcSAo5lMZVx)X32lsGvZj1rmcmkiPfR7tzBF8T9Iey1CsDeJaJcsA7IHD6OsHolTAUp(2ErcSAoPoIrGrbjTDXWUpt4JNaRMtQJyeyuqsBxmSLokkZbJi7JVTxGEzKSzSxWYk8ceNENcVqAPjFbc1hg9cWOGK2lqiv1jFrEHxeXiSkAmRovVOKVimhP)4B7fjWQ5K6igbgfK02fdB5LrYMXGsln5hpbwnNuhXiWOGK2Uyy7ijyzKslxQqXs3KnjlLW(CgC6WObhX(4jWQ5K6igbgfK02fdBCdZhuJQdYi5C5bOpEcSAoPoIrGrbjTDXWwLtYcvEWPdt3i2ynF8ey1CsDeJaJcsA7IHTcPmS9WPd9oGkadmkvKF8ey1CsDeJaJcsA7IHTJKGLrkTq9obm4LkumWEGFm2CfaI4tP1s1JHpwwbiPgDMUo1C8hXsepPPwxst6YQew7urruqRwYQeXtW6m6KLThQQuLQnEdosq59PvNkiJsGnSv(4jWQ5K6igbgfK02fdBhjblJuAH6DcyWlvOyG9a)yS5kaeXNsRLQhdFSScqsn6mDDQ54pILiEstTUKM0LvnwDTrMETUjLqWm(WG72zS6AJm9M6MucbZ4ddUdJnxwiS2PIIOGwTKvjING1z0jlBpuvPkvB8gCKGY7tRovqgLaByR8XtGvZj1rmcmkiPTlg29b4iPamDJyLrqekvAP6XWhlRaKuJotxNAo(JyjIN0uRlPj)4B7fBrOvDKM8fwd9IGdlTAUxKx4fGz8Hb39IP)ITqgra7ft)fwd9ITu5dViVWlAfZkL0)IT8jT6aM8fi7FH1qVi4WsRM7ft)f59cNRjLgfEX2X92UFbUg6EH1q7XpJEHJKcViIrGrbjn9luNaPJKEXwiJiG9IP)cRHEXwQ8HxWOGdGKVy74EB3Vaz)l2S92vKT8cRPKVOKVyT2DVqsG5cs9l(4jWQ5K6igbgfK02fd7ugradoDO1qqCLp0seJaP0GwPqXwRDxlvpg(s3iwzKoIvkPhwN0QdysnDjINcUGpskPdqAskPdqWPdTgc2hGJSovWIvsTs2QdZLvjS2PIIOGoDt2KSuc7ZzWPdJgCeBzbFew7urruqd2d8JXMRaqeFkTv(4B7fBrOvDKM8fwd9IGdlTAUxKx4fGz8Hb39IP)c1jPvP)fBjwAnViVWl2Us3Oxm9x0kKQOxGS)fwd9IGdlTAUxm9xK3lCUMuAu4fBh3B7(f4AO7fwdTh)m6fosk8IigbgfK00F8ey1CsDeJaJcsA7IHncjTk9qCS0AAjIrGuAqRuOyR1yPLQhlDJyLr6iwPKEyDsRoGj10LiEk4c(iPKoaPjPKoabNo0AiyFaoY6ublwj1kzRomxwLWANkkIc60nztYsjSpNbNomAWrSLf8ryTtffrbnypWpgBUcar8P0w5JNaRMtQJyeyuqsBxmSJgRM7J)XtGvZj1ow5lBFmW4CgXGYMX(4jWQ5KAhR8LTFxmSLeJUY2ddos7JNaRMtQDSYx2(DXWwgnmcc8Jt4JNaRMtQDSYx2(DXWwoJ1uNkiU0i2hpbwnNu7yLVS97IHTCUcar8P0(4jWQ5KAhR8LTFxmSpYAigu2mG2(4jWQ5KAhR8LTFxmSbnvRwsOXYdRDkFz7)4jWQ5KAhR8LTFxmSLrfRmOSzaT9XtGvZj1ow5lB)UyyFP5Wijuflb0h)JVTx0kQ1eWXOWli1i2(xyLc9cRHErcSH9Is(IuTS8jIN0F8ey1CYyG07HjWQ5G(sATCPcfZXkFz7BP6XceItVRbP0QtL2jAzbXP31HsgrEFI4jOsQQaANOLfeNExhkze59jING0XsvK2j6JNaRMtUlg2oscwgPiBP6XIyKAqvGGEToLreWGthAneex5dllwPqqBGHIWyZ2)4jWQ5K7IHTJKGLrkTCPcflDt2KSuc7ZzWPdJgCeRLQhdmJpm4oDkJiGbNo0AiiUYh0msjRtcv5qsjgRXIlwPqqBGHI2yD7F8ey1CYDXW2rsWYiLwUuHILYg1YJKqw62WGGHL(wQESaH407Aw62WGGHLEyGqC6DTtKlRIpcRDQOikOt3KnjlLW(CgC6WObhXwwmwDTrMoDt2KSuc7ZzWPdJgCetdMXhgCNMrkzDYnCvxFzHKs6aKgXptaoDO1qq6iL9ALSvh2kUSAeJudQce0R1PmIagC6qRHG4kFyzbFew7urruqd2d8JXMRaqeFknxqC6DDkJiGbNo0AiiUYh0msjRtUXwTIlRIpskPdqAWCb6Kua6Ro1hgG0kzRoSLfeNExRYjzHkp40HPBeBSgTt0kUSQLmvKPBO0Bn6iGHH7WYYc(iPKoaPbZfOtsbOV6uFyasRKT6WwwWNLE6mDBL3tmyDsRoGPPlr8uyLLLvdeItVRzPBddcgw6HbcXP31Hb3TSyLcbTbgkcJnD9vCXkfcAdmu0gRUPRT9wfmJpm4onypWpgBUcar8P00msjRtUZ1WWkfcAdmu0kR8XtGvZj3fdBhjblJuAH6DcyWlvOyG9a)yS5kaeXNsRLQhdXP31iK0Q0dXXsRrhgC3YIvke0gyOimWYhpbwnNCxmSbP3dtGvZb9L0A5sfkgii)4jWQ5K7IHni9EycSAoOVKwlxQqXKwlvpwcSsncshPuKeJn)4jWQ5K7IHni9EycSAoOVKwlxQqXaEkvJAP6XsGvQrq6iLIKBS(J)XtGvZj1GGmwEasAS0dbP33s1JbMXhgCNgHKwLEiowAnAgPK1j3WDT)XtGvZj1GGCxmS7fJq8ZeAP6XaZ4ddUtJqsRspehlTgnJuY6KB4U2)4jWQ5KAqqUlg2ietsS2QtvlvpgItVRtzebm40HwdbXv(G2jYLvTsHG2adfTbygFyWDAeIjjwB1PshCyPvZTl4WsRMBzzvlzQit3qP3A0radd3HLLf8zPNot3w59edwN0QdyA6sepfwzLLfRuiOnWqryS2DF8ey1Csnii3fdBe)mby3HTVLQhdXP31PmIagC6qRHG4kFq7e5YQwPqqBGHI2amJpm4onIFMaS7W2RdoS0Q52fCyPvZTSSQLmvKPBO0Bn6iGHH7WYYc(S0tNPBR8EIbRtA1bmnDjINcRSYYIvke0gyOimw76F8ey1Csnii3fdBFPQXKWw1jOsHoRLQhlImninnItVR7m6CBV2jYLiY0G00io9UUZOZT9AgPK1j3qfiOvYwVSGViY0G00io9UUZOZT9ANOpEcSAoPgeK7IHD0y1CTu9yio9UgHKwLEiowAnANixqC6DDkJiGbNo0AiiUYh0orUyjtfz6gk9wJocyy4oSSSS6QG5KokjIN0rJvZbNo05qyvWtby3HTFzbmN0rjr8K25qyvWtby3HTFfxSsHG2adfHHRVEzXkfcAdmuegB66R8XtGvZj1GGCxmSXnmFqnQoiJKZLhGAP6XwnIrQbvbc616ugradoDO1qqCLpSSaMXhgCNoLreWGthAneex5dAgPK1jXqfiSSyjtfzARuiOnWqrySz7RSSGpskPdqA1kznhC6WiI1jGvZPvQByF8ey1Csnii3fdBvojlu5bNomDJyJ10s1JbMXhgCNoLreWGthAneex5dAgPK1jXyD7llwPqqBGHI2ibwnNwLtYcvEWPdt3i2ynAWm(WG725U2xwSsHG2adfHH7A)JNaRMtQbb5UyyZQOipbRdkJsa9XtGvZj1GGCxmSviLHThoDO3bubyGrPI8JVTxKaRMtQbb5UyyJKQGthASc0M8JNaRMtQbb5UyyZOmQovWUpvizlvpMLmvKPBO0Bn6iGTHR2(YILmvKPBO0Bn6iGHrSnBFzXsMkY0wPqqBGradUz7B4U2)4F8ey1CsnWtPAumKKHqbOSzSwa7bEcAjtfzYyRBP6XIitdstJ4076oJo32RDICjImninnItVR7m6CBVMrkzDsmIPce0kzR3HKmekaLnJbvXsabJiwnHpEcSAoPg4PunAxmSvC8wjBgRLQhtfiOvYwJvrKPbPPrC6DncLsdc8uQgPzKswNCJ21BILpEcSAoPg4PunAxmSrsgcfGYMXAbSh4jOLmvKjJTULQhR749qgbAsMkcALcHHkqqRKT2fWm(WG70iK0Q0dXXsRrZiLSo5hpbwnNud8uQgTlg2PmIagC6qRHG4kF4JNaRMtQbEkvJ2fdBPLkruGAP6XqC6DDkJiGbNo0AiiUYh0orUG407AesAv6H4yP1ODIwwSsHG2adfHXAS8XtGvZj1apLQr7IHncjTk9qCS0AAP6XaZ4ddUtNYicyWPdTgcIR8bnJuY6KqvoKuUXMTVSyPNotphbXvwd0AiyucAttxI4PWYIvke0gyOimwJLpEcSAoPg4PunAxmSbnLssSekBg7JNaRMtQbEkvJ2fd7eQ4WcedoDiGn4KF8ey1CsnWtPA0UyyJKmwQI(4jWQ5KAGNs1ODXWUTY7HGrrjVqlvpwcSsncshPuKedxBzbFPBeRmsZYOkazKFYGMUeXtHpEcSAoPg4PunAxmSdfJGiukTpEcSAoPg4PunAxmSrsgcfGYMXAbSh4jOLmvKjJTULQhlImninnItVR7m6CBVom4oxwf0KmvKe2zjWQ5s)gR1U6YcItVRriPvPhIJLwJ2jALLfWm(WG70PmIagC6qRHG4kFqZiLSojgrKPbPPrC6DDNrNB71bhwA1CyLkqWL0nIvgPJyLs6H1jT6aMutxI4PWYcOjzQijSZsGvZL(nwRDTLfRuiOnWqrySvF8ey1CsnWtPA0Uyy3hGJKcW0nIvgbrOu5JNaRMtQbEkvJ2fd7ihw13xNkiIpL2hpbwnNud8uQgTlg2G5a0zS0OaS7tf6JNaRMtQbEkvJ2fdBe)mb40HwdbPJu2)XtGvZj1apLQr7IHT1qqNdzCUaSpma1s1JH407AgbAZtsjSpmaPDIwwqC6DnJaT5jPe2hgGGGX5mIPLwcAdJ1T)XtGvZj1apLQr7IHTIJ3kzZyTu9yPBeRmsZYOkazKFYGMUeXtbxsGvQrq6iLIKBS5hpbwnNud8uQgTlg2GbHLqzZyTu9yGz8Hb3PBR8EiyuuYlOzKswNCJ(aCKARuiOnqLS1USAcSsncshPuKed3TSGV0nIvgPzzufGmYpzqtxI4PWkF8ey1CsnWtPA0UyylJkZQtfemiS8J)XtGvZj1slgsYqOau2mwlvpwezAqAAeNEx3z052ETtKlrKPbPPrC6DDNrNB71msjRtIHkqyhsYqOau2mguflbemIy1ewwaZ4ddUtJqsRspehlTgnJuY6KUSA3X7Hmc0Kmve0kfcdvGWYs6gXkJ0rSsj9W6KwDatQPlr8uWfWm(WG70PmIagC6qRHG4kFqZiLSojgQaHv(4jWQ5KAPTlg2G5a0zS0OaS7tfQLQhRpah5U(aCKAgPIUTNkqaJ(aCKALS1UG407AesAv6H4yP1OddUZLvXxymnyoaDglnka7(uHGioStZiLSoPl4lbwnNgmhGoJLgfGDFQq66GDFPQXwzzP749qgbAsMkcALcHHkqyzXkfcAdmuegy5JNaRMtQL2UyyNYicyWPdTgcIR8HwQEmeNExNYicyWPdTgcIR8bDyWDUSkygFyWDAKKHqbOSzmnOjzQijgRxwWx6gXkJ0rSsj9W6KwDatQPlr8uyLpEcSAoPwA7IHT0sLikqTu9yio9UoLreWGthAneex5dANixqC6DncjTk9qCS0A0orllwPqqBGHIWynw(4jWQ5KAPTlg2juXHfigC6qaBWj)4jWQ5KAPTlg29b4iPamDJyLrqekvAP6XqC6DncjTk9qCS0A0Hb3TSyLcbTbgkcdS8XtGvZj1sBxmSTgc6CiJZfG9HbOwQEmeNExZiqBEskH9HbiTt0YcItVRzeOnpjLW(WaeemoNrmT0sqBySU9LfRuiOnWqryGLpEcSAoPwA7IHncjTk9qCS0AAP6XS0tNPNJG4kRbAnemkbTPPlr8uWfeNExJqsRspehlTgnJuY6KyOcewwqC6DncjTk9qCS0A0Hb35cygFyWD6ugradoDO1qqCLpOzKswNCJ1yzzXkfcAdmuegRXYovGWhpbwnNulTDXWgjziuakBgRLQhlDJyLr6qEacoDyGsRrZYRTnw7cItVRd5bi40HbkTgnJuY6KyOce(4jWQ5KAPTlg2i(zcWPdTgcshPSVLQhdXP31PmIagC6qRHG4kFqZiLSo5gRBFNkqyzXkfcAdmuegRBFNkq4JNaRMtQL2Uyy3w59qWOOKx4JNaRMtQL2UyyJKQGthASc0MSLQhdXP31iK0Q0dXXsRrhgC3YILmvKPTsHG2adfHbw(4jWQ5KAPTlg2GMsjjwcLnJ9XtGvZj1sBxmSdfJGiukTpEcSAoPwA7IHnsYqOau2mwlvpMLE6m9CeexznqRHGrjOnnDjINcUaAsMksc7Sey1CPFJ1ASSSaAsMksc7Sey1CPFJ1AxDzbmJpm4oDkJiGbNo0AiiUYh0msjRtIrezAqAAeNEx3z052EDWHLwnhwPceCjDJyLr6iwPKEyDsRoGj10LiEkSSyLcbTbgkcJT6JNaRMtQL2Uyyh5WQ((6ubr8P0AP6XqC6DncjTk9qCS0A0Hb3TSyLcbTbgkcdx9JNaRMtQL2UyyJ4NjaNo0AiiDKY(pEcSAoPwA7IHnsYyPk6JNaRMtQL2UyydgewcLnJ1s1JTAFaosScmsBxFaosnJur32BvWm(WG70TvEpemkk5f0msjRtIvRxzJey1C62kVhcgfL8cAWiTLfWm(WG70TvEpemkk5f0msjRtUX6DQabxaZ4ddUtJqsRspehlTgnJuY6KqvoKuUrFaosTvke0gOs26LfeNExRqkdBpC6qVdOcWaJsfP2jAfxaZ4ddUt3w59qWOOKxqZiLSo5gRxwSsHG2adfHH7(4jWQ5KAPTlg2YOYS6ubbdcl)4jWQ5KAPTlg2ijdHcqzZyTu9yrKPbPPrC6DDNrNB71bhwA1CyLkqyJUJ3dzeOjzQiOvke34gNd]] )


    spec:RegisterOptions( {
        enabled = true,

        potion = "unbridled_fury",

        buffPadding = 0,

        nameplates = false,
        nameplateRange = 8,

        aoe = 3,

        damage = true,
        damageExpiration = 3,

        package = "Beast Mastery",
    } )


    spec:RegisterSetting( "aspect_vop_overlap", false, {
        name = "|T136074:0|t Aspect of the Wild Overlap (Vision of Perfection)",
        desc = "If checked, the addon will recommend |T136074:0|t Aspect of the Wild even if the buff is already applied due to a Vision of Perfection proc.\n" ..
            "This may be preferred when delaying Aspect of the Wild would cost you one or more uses of Aspect of the Wild in a given fight.",
        type = "toggle",
        width = "full"
    } )    

    spec:RegisterSetting( "barbed_shot_grace_period", 0.5, {
        name = "|T2058007:0|t Barbed Shot Grace Period",
        desc = "If set above zero, the addon (using the default priority or |cFFFFD100barbed_shot_grace_period|r expression) will recommend |T2058007:0|t Barbed Shot up to 1 global cooldown earlier.",
        icon = 2058007,
        iconCoords = { 0.1, 0.9, 0.1, 0.9 },
        type = "range",
        min = 0,
        max = 1,
        step = 0.01,
        width = 1.5
    } )    


end
