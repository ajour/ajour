-- PriestDiscipline.lua
-- April 2019

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local FindUnitBuffByID = ns.FindUnitBuffByID


local PTR = ns.PTR


-- Load only for Priests.
if UnitClassBase( "player" ) == "PRIEST" then
    local spec = Hekili:NewSpecialization( 256 )

    -- spec:RegisterResource( Enum.PowerType.Insanity )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        castigation = 19752, -- 193134
        twist_of_fate = 22313, -- 265259
        schism = 22329, -- 214621

        body_and_soul = 22315, -- 64129
        masochism = 22316, -- 193063
        angelic_feather = 19758, -- 121536

        shield_discipline = 22440, -- 197045
        mindbender = 22094, -- 123040
        power_word_solace = 19755, -- 129250

        psychic_voice = 19759, -- 196704
        dominant_mind = 19769, -- 205367
        shining_force = 19761, -- 204263

        sins_of_the_many = 22330, -- 280391
        contrition = 19765, -- 197419
        shadow_covenant = 19766, -- 204065

        purge_the_wicked = 22161, -- 204197
        divine_star = 19760, -- 110744
        halo = 19763, -- 120517

        lenience = 21183, -- 238063
        luminous_barrier = 21184, -- 271466
        evangelism = 22976, -- 246287
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3554, -- 196029
        gladiators_medallion = 3555, -- 208683
        adaptation = 3556, -- 214027
        purification = 98, -- 196162
        purified_resolve = 100, -- 196439
        trinity = 109, -- 214205
        strength_of_soul = 111, -- 197535
        ultimate_radiance = 114, -- 236499
        dome_of_light = 117, -- 197590
        archangel = 123, -- 197862
        dark_archangel = 126, -- 197871
        premonition = 855, -- 209780
        searing_light = 1244, -- 215768
    } )

    -- Auras
    spec:RegisterAuras( {
        angelic_feather = {
            id = 121557,
            duration = 5,
            type = "Magic",
            max_stack = 1,
        },
        atonement = {
            id = 194384,
            duration = 21,
            max_stack = 1,
            friendly = true, -- To track count.
        },
        body_and_soul = {
            id = 65081,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        desperate_prayer = {
            id = 19236,
        },
        embrace_of_paku = {
            id = 292361,
            duration = 3600,
            max_stack = 1,
        },
        enlisted = {
            id = 269083,
            duration = 3600,
            max_stack = 1,
        },
        fade = {
            id = 586,
            duration = 10,
            max_stack = 1,
        },
        focused_will = {
            id = 45243,
        },
        levitate = {
            id = 111759,
            duration = 600,
            type = "Magic",
            max_stack = 1,
        },
        luminous_barrier = {
            id = 271466,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        mana_divining_stone = {
            id = 227723,
            duration = 3600,
            max_stack = 1,
        },
        masochism = {
            id = 193065,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        mind_vision = {
            id = 2096,
            duration = 60,
            max_stack = 1,
        },
        pain_suppression = {
            id = 33206,
            duration = 8,
            max_stack = 1,
        },
        power_of_the_dark_side = {
            id = 198068,
        },
        power_word_barrier = {
            id = 81782,
            duration = 3600,
            max_stack = 1,
        },
        power_word_fortitude = {
            id = 21562,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
        },
        power_word_shield = {
            id = 17,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        psychic_scream = {
            id = 8122,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        purge_the_wicked = {
            id = 204213,
            duration = 20,
            type = "Magic",
            max_stack = 1,
        },
        rapture = {
            id = 47536,
            duration = 10,
            max_stack = 1,
        },
        schism = {
            id = 214621,
            duration = 9,
            max_stack = 1,
        },
        shadow_mend = {
            id = 187464,
            duration = 10,
            max_stack = 1
        },
        shadow_word_pain = {
            id = 589,
            duration = 16,
            type = "Magic",
            max_stack = 1,
        },
        sins_of_the_many = {
            id = 280398,
            duration = 3600,
            max_stack = 1,
        },
        smite = {
            id = 208772,
            duration = 15,
            max_stack = 1,
        },
        soldier_of_the_horde = {
            id = 264408,
            duration = 3600,
            max_stack = 1,
        },
        weakened_soul = {
            id = 6788,
            duration = 7.186,
            max_stack = 1,
        },
    } )

    -- Abilities
    spec:RegisterAbilities( {
        angelic_feather = {
            id = 121536,
            cast = 0,
            charges = 3,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",
            
            startsCombat = true,
            texture = 642580,

            talent = "angelic_feather",
        },
        

        desperate_prayer = {
            id = 19236,
            cast = 0,
            cooldown = 90,
            gcd = "off",
            
            toggle = "defensives",

            startsCombat = true,
            texture = 237550,
            
            handler = function ()
                local gain = 1.25 * health.max
                health.max = health.max + gain
                health.current = health.current + gain
            end,
        },
        

        dispel_magic = {
            id = 528,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 136066,

            debuff = "dispellable_magic",
            
            handler = function ()
                removeDebuff( "target", "dispellable_magic" )
            end,
        },
        

        divine_star = {
            id = 110744,
            cast = 0,
            cooldown = 15,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 537026,

            talent = "divine_star",
        },
        

        evangelism = {
            id = 246287,
            cast = 0,
            cooldown = 90,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 135895,
            
            handler = function ()
                if buff.atonement.up then buff.atonement.expires = buff.atonement.expires + 6 end
            end,
        },
        

        fade = {
            id = 586,
            cast = 0,
            cooldown = 30,
            gcd = "off",
            
            startsCombat = false,
            texture = 135994,

            toggle = "defensives",
            
            handler = function ()
                applyBuff( "fade" )
            end,
        },
        

        halo = {
            id = 120517,
            cast = 1.5,
            cooldown = 40,
            gcd = "spell",
            
            spend = 0.03,
            spendType = "mana",
            
            startsCombat = true,
            texture = 632352,

            talent = "halo",
        },
        

        holy_nova = {
            id = 132157,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 135922,
        },
        

        leap_of_faith = {
            id = 73325,
            cast = 0,
            cooldown = 90,
            gcd = "spell",
            
            spend = 0.03,
            spendType = "mana",
            
            startsCombat = true,
            texture = 463835,
        },
        

        levitate = {
            id = 1706,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = false,
            texture = 135928,
            
            handler = function ()
                applyBuff( "levitate" )
            end,
        },
        

        luminous_barrier = {
            id = 271466,
            cast = 0,
            cooldown = function () return pvptalent.dome_of_light.enabled and 90 or 180 end,
            gcd = "spell",
            
            spend = 0.04,
            spendType = "mana",
            
            startsCombat = false,
            texture = 537078,
            
            handler = function ()
                applyBuff( "luminous_barrier" )
                active_dot.luminous_barrier = group_members
            end,
        },
        

        mass_dispel = {
            id = 32375,
            cast = 1.5,
            cooldown = 45,
            gcd = "spell",
            
            spend = 0.08,
            spendType = "mana",
            
            startsCombat = false,
            texture = 135739,
        },
        

        mass_resurrection = {
            id = 212036,
            cast = 10,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = false,
            texture = 413586,
        },
        

        mind_control = {
            id = 605,
            cast = 1.8,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 136206,
        },
        

        mind_vision = {
            id = 2096,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = false,
            texture = 135934,
        },
        

        mindbender = {
            id = 123040,
            cast = 0,
            cooldown = 60,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 136214,

            talent = "mindbender",
            
            handler = function ()
                summonPet( "mindbender" )
            end,
        },
        

        pain_suppression = {
            id = 33206,
            cast = 0,
            cooldown = 180,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            toggle = "defensives",

            startsCombat = false,
            texture = 135936,
            
            handler = function ()
                applyBuff( "pain_suppression" )
            end,
        },
        

        penance = {
            id = 47540,
            cast = 0,
            cooldown = 9,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 237545,
            
            handler = function ()                
            end,
        },
        

        power_word_barrier = {
            id = 62618,
            cast = 0,
            cooldown = 180,
            gcd = "spell",
            
            spend = 0.04,
            spendType = "mana",
            
            toggle = "defensives",
            notalent = "luminous_barrier",

            startsCombat = false,
            texture = 253400,
            
            handler = function ()
                applyBuff( "power_word_barrier" )
            end,
        },
        

        power_word_fortitude = {
            id = 21562,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.04,
            spendType = "mana",
            
            startsCombat = false,
            texture = 135987,
            
            handler = function ()
                applyBuff( "power_word_fortitude" )
            end,
        },
        

        power_word_radiance = {
            id = 194509,
            cast = 2,
            charges = 2,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",
            
            spend = 0.06,
            spendType = "mana",
            
            startsCombat = true,
            texture = 1386546,
            
            handler = function ()
                applyBuff( "atonement" )
                active_dot.atonement = max( active_dot.atonement, min( group_members, 5 ) )
            end,
        },
        

        power_word_shield = {
            id = 17,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.03,
            spendType = "mana",
            
            startsCombat = true,
            texture = 135940,

            usable = function()
                if buff.rapture.up then return true, "rapture is up"
                elseif debuff.weakened_soul.down then return true, "weakened_soul is down" end
                return false, "weakened_soul is up w/o rapture"
            end,
            
            handler = function ()
                applyBuff( "power_word_shield" )
                applyDebuff( "player", "weakened_soul" )

                local count = active_dot.atonement
                applyBuff( "atonement" )
                active_dot.atonement = active_dot.atonement + 1

                if talent.body_and_soul.enabled then applyBuff( "body_and_soul" ) end
            end,
        },
        

        power_word_solace = {
            id = 129250,
            cast = 0,
            cooldown = 12,
            gcd = "spell",
            
            startsCombat = true,
            texture = 612968,

            talent = "power_word_solace",
            
            handler = function ()
                gain( 0.01 * mana.max, "mana" )
            end,
        },
        

        psychic_scream = {
            id = 8122,
            cast = 0,
            cooldown = 60,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = true,
            texture = 136184,
            
            handler = function ()
                applyDebuff( "target", "psychic_scream" )
                active_dot.psychic_scream = active_enemies
            end,
        },
        

        purge_the_wicked = {
            id = 204197,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 236216,

            talent = "purge_the_wicked",
            
            handler = function ()
                applyDebuff( "target", "purge_the_wicked" )
            end,
        },
        

        --[[ purify = {
            id = 527,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = true,
            texture = 135894,
        }, -- doesn't really work, dispellable_magic is a hostile buff. ]]
        

        rapture = {
            id = 47536,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.9 or 1 ) * 90 end,
            gcd = "spell",
            
            startsCombat = false,
            texture = 237548,
            
            handler = function ()
                applyBuff( "rapture" )
            end,
        },
        

        resurrection = {
            id = 2006,
            cast = 10,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = false,
            texture = 135955,
        },
        

        schism = {
            id = 214621,
            cast = 1.5,
            cooldown = 24,
            gcd = "spell",
            
            spend = 298,
            spendType = "mana",
            
            startsCombat = true,
            texture = 463285,

            talent = "schism",
            
            handler = function ()
                applyDebuff( "target", "schism" )
            end,
        },
        

        shackle_undead = {
            id = 9484,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = false,
            texture = 136091,
        },
        

        shadow_covenant = {
            id = 204065,
            cast = 0,
            cooldown = 12,
            gcd = "spell",
            
            spend = 0.03,
            spendType = "mana",
            
            startsCombat = false,
            texture = 136221,

            talent = "shadow_covenant",
            
            handler = function ()
                applyDebuff( "player", "shadow_covenant" )
                active_dot.shadow_covenant = min( 5, group_members )
            end,
        },
        

        shadow_mend = {
            id = 186263,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.03,
            spendType = "mana",
            
            startsCombat = true,
            texture = 136202,
            
            handler = function ()
                applyDebuff( "player", "atonement" )
                if talent.masochism.enabled then applyBuff( "masochism" )
                elseif time > 0 then applyDebuff( "player", "shadow_mend" ) end
            end,
        },
        

        shadow_word_pain = {
            id = 589,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 136207,

            notalent = "purge_the_wicked",
            
            handler = function ()
                applyDebuff( "target", "shadow_word_pain" )
            end,
        },
        

        shadowfiend = {
            id = 34433,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.rank > 1 and 0.87 or 1 ) * 180 end,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 136199,

            notalent = "mindbender",
            
            handler = function ()
                summonPet( "mindbender" )
            end,
        },
        

        shining_force = {
            id = 204263,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 571554,

            talent = "shining_force",
            
            handler = function ()
                applyDebuff( "target", "shining_force" )
                active_dot.shining_force = active_enemies
            end,
        },
        

        smite = {
            id = 585,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.05,
            spendType = "mana",
            
            startsCombat = true,
            texture = 135924,
            
            handler = function ()
                applyDebuff( "target", "smite" )
            end,
        },        
    } )
end