-- HunterMarksmanship.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'HUNTER' then
    local spec = Hekili:NewSpecialization( 254, true )

    spec:RegisterResource( Enum.PowerType.Focus )

    -- Talents
    spec:RegisterTalents( {
        master_marksman = 22279, -- 260309
        serpent_sting = 22501, -- 271788
        a_murder_of_crows = 22289, -- 131894

        careful_aim = 22495, -- 260228
        volley = 22497, -- 260243
        explosive_shot = 22498, -- 212431

        trailblazer = 19347, -- 199921
        natural_mending = 19348, -- 270581
        camouflage = 23100, -- 199483

        steady_focus = 22267, -- 193533
        streamline = 22286, -- 260367
        hunters_mark = 21998, -- 257284

        born_to_be_wild = 22268, -- 266921
        posthaste = 22276, -- 109215
        binding_shot = 22499, -- 109248

        lethal_shots = 23063, -- 260393
        barrage = 23104, -- 120360
        double_tap = 22287, -- 260402

        calling_the_shots = 22274, -- 260404
        lock_and_load = 22308, -- 194595
        piercing_shot = 22288, -- 198670
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3564, -- 196029
        adaptation = 3563, -- 214027
        gladiators_medallion = 3565, -- 208683

        trueshot_mastery = 658, -- 203129
        hiexplosive_trap = 657, -- 236776
        scatter_shot = 656, -- 213691
        spider_sting = 654, -- 202914
        scorpid_sting = 653, -- 202900
        viper_sting = 652, -- 202797
        survival_tactics = 651, -- 202746
        dragonscale_armor = 649, -- 202589
        roar_of_sacrifice = 3614, -- 53480
        rangers_finesse = 659, -- 248443
        sniper_shot = 660, -- 203155
        hunting_pack = 3729, -- 203235
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
        binding_shot = {
            id = 117405,
            duration = 3600,
            max_stack = 1,
        },
        bursting_shot = {
            id = 186387,
            duration = 6,
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
        double_tap = {
            id = 260402,
            duration = 15,
            max_stack = 1,
        },
        eagle_eye = {
            id = 6197,
        },
        explosive_shot = {
            id = 212431,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        feign_death = {
            id = 5384,
            duration = 360,
            max_stack = 1,
        },
        hunters_mark = {
            id = 257284,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
        },
        lethal_shots = {
            id = 260395,
            duration = 15,
            max_stack = 1,
        },
        lock_and_load = {
            id = 194594,
            duration = 15,
            max_stack = 1,
        },
        lone_wolf = {
            id = 155228,
            duration = 3600,
            max_stack = 1,
        },
        master_marksman = {
            id = 269576,
            duration = 12,
            max_stack = 1,
        },
        misdirection = {
            id = 35079,
            duration = 8,
            max_stack = 1,
        },
        pathfinding = {
            id = 264656,
            duration = 3600,
            max_stack = 1,
        },
        posthaste = {
            id = 118922,
            duration = 4,
            max_stack = 1,
        },
        precise_shots = {
            id = 260242,
            duration = 15,
            max_stack = 2,
        },
        rapid_fire = {
            id = 257044,
            duration = 2.97,
            max_stack = 1,
        },
        serpent_sting = {
            id = 271788,
            duration = 12,
            type = "Poison",
            max_stack = 1,
        },
        steady_focus = {
            id = 193534,
            duration = 12,
            max_stack = 1,
        },
        survival_of_the_fittest = {
            id = 281195,
            duration = 6,
            max_stack = 1,
        },
        trailblazer = {
            id = 231390,
            duration = 3600,
            max_stack = 1,
        },
        trick_shots = {
            id = 257622,
            duration = 20,
            max_stack = 1,
        },
        trueshot = {
            id = 288613,
            duration = 15,
            max_stack = 1,
        },


        -- Azerite Powers
        unerring_vision = {
            id = 274447,
            duration = function () return buff.trueshot.duration end,
            max_stack = 10,
            meta = {
                stack = function () return buff.unerring_vision.up and max( 1, ceil( query_time - buff.trueshot.applied ) ) end,
            }
        },
    } )


    spec:RegisterStateExpr( "ca_execute", function ()
        return talent.careful_aim.enabled and ( target.health.pct > 80 or target.health.pct < 20 )
    end )


    spec:RegisterHook( "reset_precast", function ()
        if now - action.serpent_sting.lastCast < gcd.execute * 2 and target.unit == action.serpent_sting.lastUnit then
            applyDebuff( "target", "serpent_sting" )
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        a_murder_of_crows = {
            id = 131894,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 20,
            spendType = "focus",

            startsCombat = true,
            texture = 645217,

            talent = "a_murder_of_crows",

            handler = function ()
                applyDebuff( "target", "a_murder_of_crows" )
            end,
        },


        aimed_shot = {
            id = 19434,
            cast = function () return buff.lock_and_load.up and 0 or ( 2.5 * haste ) end,
            charges = 2,
            cooldown = function () return haste * ( buff.trueshot.up and 4.8 or 12 ) end,
            recharge = function () return haste * ( buff.trueshot.up and 4.8 or 12 ) end,
            gcd = "spell",

            spend = function () return buff.lock_and_load.up and 0 or 30 end,
            spendType = "focus",

            startsCombat = true,
            texture = 135130,

            handler = function ()
                applyBuff( "precise_shots" )
                if talent.master_marksman.enabled then applyBuff( "master_marksman" ) end
                removeBuff( "lock_and_load" )
                removeBuff( "steady_focus" )
                removeBuff( "lethal_shots" )
                removeBuff( "double_tap" )
                removeBuff( "trick_shots" )
            end,
        },


        arcane_shot = {
            id = 185358,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.master_marksman.up and 0 or 15 end,
            spendType = "focus",

            startsCombat = true,
            texture = 132218,

            handler = function ()
                if talent.calling_the_shots.enabled then cooldown.trueshot.expires = max( 0, cooldown.trueshot.expires - 2.5 ) end
                removeBuff( "master_marksman" )
                removeStack( "precise_shots" )
                removeBuff( "steady_focus" )
            end,
        },


        aspect_of_the_cheetah = {
            id = 186257,
            cast = 0,
            cooldown = function () return 180 * ( talent.born_to_be_wild.enabled and 0.8 or 1 ) end,
            gcd = "off",

            startsCombat = false,
            texture = 132242,

            handler = function ()
                applyBuff( "aspect_of_the_cheetah" )
            end,
        },


        aspect_of_the_turtle = {
            id = 186265,
            cast = 0,
            cooldown = function () return 180 * ( talent.born_to_be_wild.enabled and 0.8 or 1 ) end,
            gcd = "off",

            toggle = "defensives",

            startsCombat = false,
            texture = 132199,

            handler = function ()
                applyBuff( "aspect_of_the_turtle" )
                setCooldown( "global_cooldown", 5 )
            end,
        },


        barrage = {
            id = 120360,
            cast = 3,
            channeled = true,
            cooldown = 20,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 236201,

            talent = "barrage",

            start = function ()
            end,
        },


        binding_shot = {
            id = 109248,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 462650,

            handler = function ()
                applyDebuff( "target", "binding_shot" )
            end,
        },


        bursting_shot = {
            id = 186387,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 10,
            spendType = "focus",

            startsCombat = true,
            texture = 1376038,

            handler = function ()
                applyDebuff( "target", "bursting_shot" )
                removeBuff( "steady_focus" )
            end,
        },


        camouflage = {
            id = 199483,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            texture = 461113,

            usable = function () return time == 0 end,
            handler = function ()
                applyBuff( "camouflage" )
            end,
        },


        concussive_shot = {
            id = 5116,
            cast = 0,
            cooldown = 5,
            gcd = "spell",

            startsCombat = true,
            texture = 135860,

            handler = function ()
                applyDebuff( "target", "concussive_shot" )
            end,
        },


        counter_shot = {
            id = 147362,
            cast = 0,
            cooldown = 24,
            gcd = "off",

            startsCombat = true,
            texture = 249170,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
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
                if talent.posthaste.enabled then applyBuff( "posthaste" ) end
            end,
        },


        double_tap = {
            id = 260402,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 537468,

            handler = function ()
                applyBuff( "double_tap" )
            end,
        },


        --[[ eagle_eye = {
            id = 6197,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132172,

            handler = function ()
            end,
        }, ]]


        exhilaration = {
            id = 109304,
            cast = 0,
            cooldown = function () return azerite.natures_salve.enabled and 105 or 120 end,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 461117,

            handler = function ()
            end,
        },


        explosive_shot = {
            id = 212431,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 20,
            spendType = "focus",

            startsCombat = false,
            texture = 236178,

            handler = function ()
                applyDebuff( "target", "explosive_shot" )
                removeBuff( "steady_focus" )
            end,
        },


        feign_death = {
            id = 5384,
            cast = 0,
            cooldown = 30,
            gcd = "off",

            startsCombat = false,
            texture = 132293,

            handler = function ()
                applyBuff( "feign_death" )
            end,
        },


        --[[ flare = {
            id = 1543,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 135815,

            handler = function ()
            end,
        }, ]]


        freezing_trap = {
            id = 187650,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 135834,

            handler = function ()
                applyDebuff( "target", "freezing_trap" )
            end,
        },


        hunters_mark = {
            id = 257284,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 236188,

            talent = "hunters_mark",

            usable = function () return debuff.hunters_mark.down end,
            handler = function ()
                applyDebuff( "target", "hunters_mark" )
            end,
        },


        masters_call = {
            id = 272682,
            cast = 0,
            cooldown = 45,
            gcd = "off",

            startsCombat = false,
            texture = 236189,

            handler = function ()
                applyBuff( "masters_call" )
            end,
        },


        misdirection = {
            id = 34477,
            cast = 0,
            cooldown = 30,
            gcd = "off",

            startsCombat = false,
            texture = 132180,

            handler = function ()
                applyBuff( "misdirection" )
            end,
        },


        multishot = {
            id = 257620,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.master_marksman.up and 0 or 15 end,
            spendType = "focus",

            startsCombat = true,
            texture = 132330,

            handler = function ()
                if talent.calling_the_shots.enabled then cooldown.trueshot.expires = max( 0, cooldown.trueshot.expires - 2.5 ) end
                if active_enemies > 2 then applyBuff( "trick_shots" ) end
                removeBuff( "master_marksman" )
                removeStack( "precise_shots" )
                removeBuff( "steady_focus" )
            end,
        },


        piercing_shot = {
            id = 198670,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 35,
            spendType = "focus",

            startsCombat = true,
            texture = 132092,

            handler = function ()
                removeBuff( "steady_focus" )
            end,
        },


        rapid_fire = {
            id = 257044,
            cast = function () return ( 3 * haste ) + ( talent.streamline.enabled and 0.6 or 0 ) end,
            channeled = true,
            cooldown = function () return buff.trueshot.up and ( haste * 8 ) or 20 end,
            gcd = "spell",

            startsCombat = true,
            texture = 461115,

            start = function ()
                applyBuff( "rapid_fire" )
                removeBuff( "lethal_shots" )
                removeBuff( "trick_shots" )
            end,

            finish = function () removeBuff( "double_tap" ) end,
        },


        serpent_sting = {
            id = 271788,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 10,
            spendType = "focus",

            startsCombat = true,
            texture = 1033905,

            velocity = 45,

            talent = "serpent_sting",

            recheck = function () return remains - ( duration * 0.3 ), remains end,
            handler = function ()
                applyDebuff( "target", "serpent_sting" )
                removeBuff( "steady_focus" )
            end,
        },


        steady_shot = {
            id = 56641,
            cast = 1.75,
            cooldown = 0,
            gcd = "spell",

            spend = -10,
            spendType = "focus",

            startsCombat = true,
            texture = 132213,

            handler = function ()
                if talent.steady_focus.enabled then applyBuff( "steady_focus", 12, min( 2, buff.steady_focus.stack + 1 ) ) end
                if debuff.concussive_shot.up then debuff.concussive_shot.expires = debuff.concussive_shot.expires + 4 end
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
            essential = true,

            texture = function () return GetStablePetInfo(1) or 'Interface\\ICONS\\Ability_Hunter_BeastCall' end,
            nomounted = true,

            usable = function () return false and not pet.exists end, -- turn this into a pref!
            handler = function ()
                summonPet( 'made_up_pet', 3600, 'ferocity' )
            end,
        },


        survival_of_the_fittest = {
            id = function () return pet.exists and 264735 or 281195 end,
            cast = 0,
            cooldown = 180,
            gcd = "off",
            known = function ()
                if not pet.exists then return 155228 end
            end,

            toggle = "defensives",

            startsCombat = false,

            usable = function ()
                return not pet.exists or pet.alive, "requires either no pet or a living pet"
            end,
            handler = function ()
                applyBuff( "survival_of_the_fittest" )
            end,

            copy = { 264735, 281195, 155228 }
        },        


        tar_trap = {
            id = 187698,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 576309,

            handler = function ()
                applyDebuff( "target", "tar_trap" )
            end,
        },


        trueshot = {
            id = 288613,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 132329,

            nobuff = function ()
                if settings.trueshot_vop_overlap then return end
                return "trueshot"
            end,

            handler = function ()
                applyBuff( "trueshot" )
                if azerite.unerring_vision.enabled then
                    applyBuff( "unerring_vision" )
                end
            end,

            meta = {
                duration_guess = function( t )
                    return talent.calling_the_shots.enabled and 90 or t.duration
                end,
            }
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

        package = "Marksmanship",
    } )


    spec:RegisterSetting( "trueshot_vop_overlap", false, {
        name = "|T132329:0|t Trueshot Overlap (Vision of Perfection)",
        desc = "If checked, the addon will recommend |T132329:0|t Trueshot even if the buff is already applied due to a Vision of Perfection proc.\n" ..
            "This may be preferred when delaying Trueshot would cost you one or more uses of Trueshot in a given fight.",
        type = "toggle",
        width = 1.5
    } )  


    spec:RegisterPack( "Marksmanship", 20200401, [[duKPbbqivIEKsrTjsjJsrQtPuyvuLuQxPuzwkc3sLqSlQ8lvsdJu0XuQAzkIEgvjMgkuDnuiBtLGVPuKgNkH6COqP1Hcfnpfv3JQyFKcoOkH0cjL6HkfrUivjLmsQsQ0jPkPIvQOmtQskCtuOWorrgQsrupvftffCvQskAVG(ljdMshwQftQEmQMSqxMyZk8zvQrtHtlz1kfHxJIA2k52O0Ub(TOHtvDCQsQA5Q65qMoY1fSDfjFxP04PkjNNQuRNuO5tr7hQH7HmapXMeittQ5KAQjJR5ENMmwnzKxUy4H82xGh)MZCFlWdOzf4HXOFMrSnazu(WJF79k7iKb4bLHNlWZMXwdI8rmMxVExKrq3Xt2ROInSAQsa)7bDfvS8RWJEOwKxhauhEInjqMMuZj1utgxZ9onzSAYiVCb4PdKr(WZPy3KGhJkgfauhEIcIdpBgBzm6NzeBdqgLp261nai5XZ2m2AqKpIX8617Imc6oEYEfvSHvtvc4FpOROILFfpBZylJr)CdS1lAob2oPMtQjEgE2MX2njJgCligt8SnJTxeS9IgJyBGQvrEJT(FLFrEJTuITx0nzVgo8SnJTxeS1RjsWwQyffLQyjy73KH8ylz0aSL6)wihvSIIsvSeSLsSTbuXl)MeSvarSnhylpz1BYbpRcriidWd9fNzKrsiidqM2dzaEAovjaE07)7BbEeqRVKiuBibzAsidWtZPkbWJ4v(RevtjkKrsWJaA9LeHAdjitEbYa8iGwFjrO2Wd)ls(QHh9Wy4OV4mRqgjHCbFSvlSL3kXReEGeSvlSvpmgUyg0xIIAFxWhEAovjaE6IvIkKrsqcYeJdzaEeqRVKiuB4H)fjF1WJEymC0xCMviJKqUGp2Qf2on22Au(Ie3i5bKevJ6fNaA9LeXwttST1O8fjUcOidr9gEtgSUVbmJTAaB3JTMMyBRr5lsCOWFxGBfYijKtaT(sIyRPj2s9saKdrV0SRciob06ljITBapnNQeapF7xr1OEbsqMyeKb4raT(sIqTHh(xK8vdp6HXWrFXzwHmsc5c(yRwy70yREymC(VWlKOqgjHCXClaBnnXwEMRyUf46IvIkKrsUryTuVWn6)wuuXky7CST5uLaxxSsuHmsYXBePOIvWwttSvpmgo6dcYijxWhB3aEAovjaE6IvIkKrsqcY0fGmapcO1xseQn8W)IKVA4rpmgo6loZkKrsixWhEAovjaE(2VIQr9cKGmTPqgGhb06ljc1gE4FrYxn8Ohgdh9fNzfYijKlMBbyRPj2QhgdN)l8cjkKrsixWhB1cBVeB1dJHJ(GGmsYf8XwttSDK8acB1a2UPAcpnNQeapSHfviJKGeKPlgYa80CQsa8msEajrvRr5lsu6sZcpcO1xseQnKGmXyHmapnNQeap(HVgExGBL(Qre8iGwFjrO2qcY0EnHmapnNQeap8eWfa9njr1y1Sc8iGwFjrO2qcY0(9qgGNMtvcGh9vMrvouKHOeGW6n8iGwFjrO2qcY0(jHmapcO1xseQn8W)IKVA4rpmgUx4mVeesnYNlUGp2AAIT6HXW9cN5LGqQr(CrXZaGK3HOMZm2ohB3Rj80CQsa8qgIka0ZaiQg5ZfibzAVxGmapnNQeap(L88cCRqgjbpcO1xseQnKGmTNXHmapnNQeapTIn8r5v5qX)ClcEeqRVKiuBibzApJGmapcO1xseQn8W)IKVA45LXliJwFjyRwy7LyBZPkboK8(cGuiQa3UcOgR62GGNMtvcGhK8(cGuiQa3qcY0(lazaEAovjaEqK0rVviJKGhb06ljc1gsqcEIYOdlcYaKP9qgGhb06ljc1gE4FrYxn8ef9Wy44nIkWTl4JTMMyREymCXc5lRvRVefBFxCxWhBnnXw9Wy4IfYxwRwFjkb89T4c(WtZPkbWdVxlvZPkbQvHi4zvisbAwbEcuTkYBibzAsidWJaA9LeHAdpnNQeapRWZS8ivbqvSYasDxdcE4FrYxn8WZCfZTah9bbzKK7f2Uai1DqqiSDo2UNryRPj2sfROOuflbBNJTErt4b0Sc8ScpZYJufavXkdi1DniibzYlqgGhb06ljc1gEAovjaEAnIm6VrQrcivou(5w5Hh(xK8vdptJTuXkkkvXsWwnGTnNQeO4zUI5wa2UdB9cJJTMMyl1)TqodPxKHZNty7CSDsnXwttSL6)wihvSIIsLpNutQj2ohB3ZiSDdSvlSLN5kMBbo6dcYij3lSDbqQ7GGqy7CSDpJWwttSLkwrrPkwc2ohB9cJGhqZkWtRrKr)nsnsaPYHYp3kpKGmX4qgGhb06ljc1gEAovjaEwbe9zaPUZvuak)vGTVf4H)fjF1WdpZvm3cC0heKrsUxy7cGu3bbHW25ylJWwttSLkwrrPkwc2ohBNut4b0Sc8Sci6ZasDNROau(RaBFlqcYeJGmapcO1xseQn80CQsa8C3lH3RL8iLEMa4H)fjF1WJ)ltPU5r3Eh9bbzKe2AAITxITuVea549AvGBfzikKrsiNaA9LeXwttSLkwrrPkwc2ohB3Rj8aAwbEU7LW71sEKsptaKGmDbidWJaA9LeHAdpnNQeapnYyQgii13AmFfp)Ebp8Vi5RgE8Fzk1np627OpiiJKWwTW2PXw9Wy4Ud9hRgOYHQ1O8jz4c(yRPj2Ej2kiKa4IJNGOaqsuTQHmYNlo2EtKp2Qf2YBL4vcpqc2Ub2AAITrrpmgUV1y(kE(9sff9Wy4I5wa2AAITuXkkkvXsW25y7KAcpGMvGNgzmvdeK6BnMVINFVGeKPnfYa8iGwFjrO2WtZPkbWJFYzwiuPrjQ4jRFGAQsGkktvCbE4FrYxn8Cj2Qhgdh9bbzKKl4JTAHTxITccjaU40xzgv5qrgIsacR3o2EtKp2AAITrrpmgo9vMrvouKHOeGW6Tl4JTMMylvSIIsvSeSDo2Yi4b0Sc84NCMfcvAuIkEY6hOMQeOIYufxGeKPlgYa8iGwFjrO2Wd)ls(QHh)xMsDZJU9o6dcYijS10eBVeBPEjaYX71Qa3kYquiJKqob06ljITMMylvSIIsvSeSDo2oPMWtZPkbWtajQIeweKGmXyHmapcO1xseQn80CQsa8W71s1CQsGAvicEwfIuGMvGhEebjit71eYa8iGwFjrO2Wd)ls(QHNMt1uIsacBjiSDo26f4P5uLa4H3RLQ5uLa1Qqe8SkePanRapicsqM2VhYa8iGwFjrO2Wd)ls(QHNMt1uIsacBjiSvdy7KWtZPkbWdVxlvZPkbQvHi4zvisbAwbEOV4mJmscbjibp(VWtw9MGmazApKb4P5uLa4Xiai5rk2(zgEeqRVKiuBibzAsidWJaA9LeHAdp(VWBePOIvGN9AcpnNQeapXmOVef1(qcYKxGmapcO1xseQn8aAwbEAnIm6VrQrcivou(5w5HNMtvcGNwJiJ(BKAKasLdLFUvEibzIXHmapnNQeapBZFfNskG6fucAaxGhb06ljc1gsqMyeKb4P5uLa45o0FSAGkhQwJYNKb8iGwFjrO2qcY0fGmapnNQeapScB(ERYHAf4vufFPzrWJaA9LeHAdjitBkKb4raT(sIqTHh)x4nIuuXkWZEhJGNMtvcGh6dcYij4H)fjF1WtZPAkrjaHTee2QbSDsibz6IHmapnNQeap(jvjaEeqRVKiuBibzIXczaEeqRVKiuB4H)fjF1WtZPAkrjaHTee2ohB9c80CQsa80fReviJKGeKGhEebzaY0EidWJaA9LeHAdp8Vi5RgEIIEymCgbajpsX2pZUyUfGTAHTxIT6HXWrFqqgj5c(WtZPkbWJraqYJuS9ZmKGmnjKb4raT(sIqTHh(xK8vdp8mxXClW9TFfvJ6f3lSDbqy7CS9MhXwttSLN5kMBbUV9ROAuV4EHTlacBNJT8mxXClW1fReviJKCVW2faHTMMylvSIIsvSeSDo2oPMWtZPkbWtmd6lrrTpKGm5fidWJaA9LeHAdp8Vi5RgE8Fzk1np627OpiiJKWwTW2PXwQ)BHCuXkkkvXsWwnGT8mxXClWPlpsEMlWTlg(MQeGT7W2y4BQsa2AAITtJTu)3c5mKErgoFoHTZX2j1eBnnX2lXwQxcGC8(LryP6I1jGwFjrSDdSDdS10eBPIvuuQILGTZX29EbEAovjaE0LhjpZf4gsqMyCidWJaA9LeHAdp8Vi5RgE8Fzk1np627OpiiJKWwTW2PXwQ)BHCuXkkkvXsWwnGT8mxXClWPVYmQgH3Bxm8nvjaB3HTXW3uLaS10eBNgBP(VfYzi9ImC(CcBNJTtQj2AAITxITuVea549lJWs1fRtaT(sIy7gy7gyRPj2sfROOuflbBNJT7Va80CQsa8OVYmQgH3BibzIrqgGhb06ljc1gE4FrYxn84)YuQBE0T3rFqqgjHTAHTtJTu)3c5OIvuuQILGTAaB5zUI5wGRbCbrFVu8ETCXW3uLaSDh2gdFtvcWwttSDASL6)wiNH0lYW5ZjSDo2oPMyRPj2Ej2s9saKJ3VmclvxSob06ljITBGTBGTMMylvSIIsvSeSDo2U)cWtZPkbWtd4cI(EP49AbjitxaYa8iGwFjrO2Wd)ls(QHh)xMsDZJU9o6dcYijSvlSDASL6)wihvSIIsvSeSvdylpZvm3cCJ6f9vMrxm8nvjaB3HTXW3uLaS10eBNgBP(VfYzi9ImC(CcBNJTtQj2AAITxITuVea549lJWs1fRtaT(sIy7gy7gyRPj2sfROOuflbBNJTmw4P5uLa4zuVOVYmcjitBkKb4raT(sIqTHh(xK8vdp6HXWrFqqgj5I5wa80CQsa8SQBdcP2eH4nRaiibz6IHmapcO1xseQn8W)IKVA4rpmgo6dcYijxm3cGNMtvcGh9(wLdf9fNzeKGmXyHmapcO1xseQn8W)IKVA4rpmgo6dcYijxm3cWwTW2PXwQ)BHCgsVidNpNWwnGTxSMyRPj2s9FlKZq6fz485e2o3d2oPMyRPj2s9FlKJkwrrPYNtQj1eB1a26fnX2nGNMtvcGNxA)cCRgRMvqqcY0EnHmapcO1xseQn8W)IKVA4zASLN5kMBbUwJiJ(BKAKasLdLFUvE3lSDbqyRgW2j1eBnnX2lXwXRpu((s01Aez0FJuJeqQCO8ZTYJTMMylvSIIsvSeSDo2YZCfZTaxRrKr)nsnsaPYHYp3kVlg(MQeGT7WwVW4yRwyl1)TqodPxKHZNtyRgW2j1eB3aB1cBNgB5zUI5wGJ(GGmsY9cBxaK6oiie2ohB9c2AAITtJTccjaU4MQqvcu5q5l)q4uLahBbYhB1cBPIvuuQILGTAaBBovjqXZCfZTaSDh2Qhgd328xXPKcOEbLGgWfxm8nvjaB3aB3aBnnXwQyffLQyjy7CSDsnHNMtvcGNT5VItjfq9ckbnGlqcY0(9qgGhb06ljc1gE4FrYxn8mn2YBL4vcpqc2AAITu)3c5OIvuuQILGTAaBBovjqXZCfZTaSDh26fnX2nWwTW2PXw9Wy4OpiiJKCbFS10eB5zUI5wGJ(GGmsY9cBxae2ohB3FbSDdS10eBPIvuuQILGTZXwVShEAovjaEUd9hRgOYHQ1O8jzajit7NeYa8iGwFjrO2Wd)ls(QHhEMRyUf4OpiiJKCVW2faHTZX2nfEAovjaE(Y3FjQcOq(nxGeKP9EbYa8iGwFjrO2Wd)ls(QHNlXw9Wy4OpiiJKCbF4P5uLa4HvyZ3BvouRaVIQ4lnlcsqM2Z4qgGhb06ljc1gE4FrYxn8Ohgdh9bbzKK7LMtyRwyREymC6RmJRaICV0CcBnnXw)xMsDZJU9o6dcYijSvlSL6)wiNH0lYW5ZjSDo2oPMyRPj2on2on2YtakW26lX5NuLavoubG(xXLevJW7n2AAIT8eGcST(sCbG(xXLevJW7n2Ub2Qf2s9FlKJkwrrPkwc2ohBVWES10eBPIvuuQILGTZX2jVa2Ub80CQsa84NuLaibzApJGmapcO1xseQn8W)IKVA4rpmgo6dcYijxm3cWwTWwEMRyUf4(2VIQr9I7f2UaiS10eBPIvuuQILGTZX29mcEAovjaEOpiiJKGeKGhebzaY0EidWtZPkbWJ4v(RevtjkKrsWJaA9LeHAdjittczaEeqRVKiuB4H)fjF1WtZPAkrjaHTee2QbSDp80CQsa8O3)33cKGm5fidWtZPkbWtRydFuEvou8p3IGhb06ljc1gsqMyCidWJaA9LeHAdp8Vi5RgEEz8cYO1xc2Qf2Ej22CQsGdjVVaifIkWTRaQXQUni4P5uLa4bjVVaifIkWnKGmXiidWJaA9LeHAdp8Vi5RgE0dJHJ(GGmsYfZTaS10eBhjpGW25yRxye2AAITJKhqy7CS9cAITAHTxITuVea5wcz0lfYijKtaT(sIyRPj2QhgdxbuKHOEdVjdw3lSDbqy7CSv8kHhirrfRapnNQeapF7xr1OEbsqMUaKb4raT(sIqTHh(xK8vdp6HXWrFqqgj5c(yRwy70yREymCbG8FbUvtvOkboe1CMXwnGTmo2AAITxITTgLViXfaY)f4wnvHQe4eqRVKi2Ub2AAITuXkkkvXsW25y7(9WtZPkbWJ(kZOkhkYqucqy9gsqM2uidWJaA9LeHAdp8Vi5RgEUeB1dJHJ(GGmsYf8XwttSLkwrrPkwc2ohBze80CQsa8msEajrvRr5lsu6sZcjitxmKb4raT(sIqTHh(xK8vdp6HXWrFqqgj5c(yRwyREymCSnIKxX2pZi2g4c(yRwy7LyREymCScB(ERYHAf4vufFPzrUGp80CQsa80pVbIczKeKGmXyHmapcO1xseQn8W)IKVA4rpmgo6dcYijxWhBnnX2PXw9Wy4IzqFjkQ9DXClaBnnXwEReVs4bsW2nWwTWw9Wy48FHxirHmsc5I5wa2AAITJWAPEHB0)TOOIvW25ylVrKIkwbB1cB5zUI5wGJ(GGmsY9cBxae80CQsa80fReviJKGeKP9AczaEeqRVKiuB4H)fjF1WJEymC0heKrsUGp2Qf2QhgdhBJi5vS9ZmITbUGp2Qf2QhgdhRWMV3QCOwbEfvXxAwKl4dpnNQeap9ZBGOqgjbjit73dzaEAovjaE8l55f4wHmscEeqRVKiuBibzA)KqgGhb06ljc1gE4FrYxn8Cj2Qhgdh9bbzKKl4JTMMylvSIIsvSeSDo2EXWtZPkbWJF4RH3f4wPVAebjit79cKb4raT(sIqTHh(xK8vdpJKhqy7oSDK8aY9YTaWwV2y7npITZX2rYdihB7vyRwyREymC0heKrsUyUfGTAHTtJTxITXKC8eWfa9njr1y1SIsp8a3lSDbqyRwy7LyBZPkboEc4cG(MKOASAwXva1yv3ge2Ub2AAITJWAPEHB0)TOOIvW25y7npITMMyl1)TqoQyffLQyjy7CSLrWtZPkbWdpbCbqFtsunwnRajit7zCidWJaA9LeHAdp8Vi5RgE0dJH7foZlbHuJ85Il4JTMMyREymCVWzEjiKAKpxu8mai5DiQ5mJTZX29AITMMylvSIIsvSeSDo2Yi4P5uLa4HmevaONbqunYNlqcY0EgbzaEeqRVKiuB4H)fjF1WJEymC0heKrsUyUfGTAHTtJT6HXW5)cVqIczKeYf8XwTW2PX2rYdiSvdylJye2AAIT6HXWX2isEfB)mJyBGl4JTBGTMMy7i5be2QbSDtze2AAITuXkkkvXsW25ylJW2nGNMtvcGN(5nquiJKGeKP9xaYa80CQsa8GiPJERqgjbpcO1xseQnKGe8eOAvK3qgGmThYa80CQsa8WZaGKxHmscEeqRVKiuBibzAsidWtZPkbWdsEbuK3QyarWJaA9LeHAdjitEbYa80CQsa8G8Zxu8vgIWJaA9LeHAdjitmoKb4P5uLa4bLjzuGB12MKhEeqRVKiuBibzIrqgGNMtvcGhuckUsF1icEeqRVKiuBibz6cqgGNMtvcGhGqgYRqgjNz4raT(sIqTHeKPnfYa80CQsa8WnQnrHu03aV(qTkYB4raT(sIqTHeKPlgYa80CQsa8G8RVifYi5mdpcO1xseQnKGmXyHmapnNQeapGMcVGu3FZf4raT(sIqTHeKGe8mL8OkbqMMuZj1uZj18cWZ2(bf4gbpEDy9ZNKi2EbST5uLaSDvic5WZGhKVWHmnjJyC4X)ZrTe4zZylJr)mJyBaYO8XwVUbajpE2MXwdI8rmMxVExKrq3Xt2ROInSAQsa)7bDfvS8R4zBgBzm6NBGTErZjW2j1CsnXZWZ2m2Ujz0GBbXyINTzS9IGTx0yeBduTkYBS1)R8lYBSLsS9IUj71WHNTzS9IGTEnrc2sfROOuflbB)MmKhBjJgGTu)3c5OIvuuQILGTuITnGkE53KGTciIT5aB5jREto8m8SnJTET8kHhijIT6YiFbB5jREtyRUCxaKdBVOCU4tiSfKGlIr)SJWcBBovjaHTjy5TdpBZyBZPkbiN)l8KvVjpJvJygpBZyBZPkbiN)l8KvVPDEU2HBwbqnvjapBZyBZPkbiN)l8KvVPDEUoYmINTzS9aAFKrsy73veB1dJHeXwe1ecB1Lr(c2Ytw9MWwD5UaiSTbrS1)LlIFsubUX2cHTXeio8SnJTnNQeGC(VWtw9M255kc0(iJKuiQjeEwZPkbiN)l8KvVPDEUAeaK8ifB)mJNTzSDt(fEJiSLmke22iSv6F5n22iS1prOsFjylLyRFscGQET8gBV7cGTnijd5XwEJiSng(cCJTKHGTJ62GC4znNQeGC(VWtw9M255Amd6lrrT)e(VWBePOIv8Sxt8SMtvcqo)x4jREt78CnGevrc7eGMv80Aez0FJuJeqQCO8ZTYJN1CQsaY5)cpz1BANNRBZFfNskG6fucAaxWZAovja58FHNS6nTZZ17q)XQbQCOAnkFsg4znNQeGC(VWtw9M255kRWMV3QCOwbEfvXxAweEwZPkbiN)l8KvVPDEUsFqqgjnH)l8grkQyfp7DmAIA4P5unLOeGWwcsdtIN1CQsaY5)cpz1BANNR(jvjapR5uLaKZ)fEYQ30opx7IvIkKrstudpnNQPeLae2sqZ9cEgEwZPkbixGQvrE7HNbajVczKeEwZPkbixGQvrEVZZvK8cOiVvXaIWZAovja5cuTkY7DEUI8Zxu8vgI4znNQeGCbQwf59opxrzsgf4wTTj5XZAovja5cuTkY7DEUIsqXv6Rgr4znNQeGCbQwf59opxbcziVczKCMXZAovja5cuTkY7DEUYnQnrHu03aV(qTkYB8SMtvcqUavRI8ENNRi)6lsHmsoZ4znNQeGCbQwf59opxbnfEbPU)Ml4z4zBgB9A5vcpqseBLPK3BSLkwbBjdbBBoLp2wiSTNQRvRVehEwZPkbip8ETunNQeOwfIMa0SINavRI8EIA4jk6HXWXBevGBxW30upmgUyH8L1Q1xIITVlUl4BAQhgdxSq(YA16lrjGVVfxWhpR5uLa0opxdirvKWobOzfpRWZS8ivbqvSYasDxdAIA4HN5kMBbo6dcYij3lSDbqQ7GGqZ3ZittQyffLQyjZ9IM4znNQeG255AajQIe2janR4P1iYO)gPgjGu5q5NBLFIA4zAQyffLQyjAGN5kMBb78cJBAs9FlKZq6fz48508j100K6)wihvSIIsLpNutQ589mAdT4zUI5wGJ(GGmsY9cBxaK6oii089mY0KkwrrPkwYCVWi8SMtvcq78CnGevrc7eGMv8Sci6ZasDNROau(RaBFltudp8mxXClWrFqqgj5EHTlasDheeAoJmnPIvuuQILmFsnXZAovjaTZZ1asufjStaAwXZDVeEVwYJu6zcMOgE8Fzk1np627OpiiJKmnVK6LaihVxRcCRidrHmsc5eqRVKOPjvSIIsvSK571epR5uLa0opxdirvKWobOzfpnYyQgii13AmFfp)Enrn84)YuQBE0T3rFqqgjP106HXWDh6pwnqLdvRr5tYWf8nnVuqibWfhpbrbGKOAvdzKpxCS9MiFT4Ts8kHhizdtZOOhgd33AmFfp)EPIIEymCXClW0KkwrrPkwY8j1epR5uLa0opxdirvKWobOzfp(jNzHqLgLOINS(bQPkbQOmvXLjQHNl1dJHJ(GGmsYf816sbHeaxC6RmJQCOidrjaH1BhBVjY30mk6HXWPVYmQYHImeLaewVDbFttQyffLQyjZzeE2MXwgEVXwkX2vbeSn4JTnNQPAsIyl9fGzHqy72ImWwg(GGmscpR5uLa0opxdirvKWIMOgE8Fzk1np627OpiiJKmnVK6LaihVxRcCRidrHmsc5eqRVKOPjvSIIsvSK5tQjEwZPkbODEUY71s1CQsGAviAcqZkE4reEwZPkbODEUY71s1CQsGAviAcqZkEq0e1WtZPAkrjaHTe0CVGN1CQsaANNR8ETunNQeOwfIMa0SIh6loZiJKqtudpnNQPeLae2sqAys8m8SMtvcqoEe5Xiai5rk2(zEIA4jk6HXWzeaK8ifB)m7I5wGwxQhgdh9bbzKKl4JN1CQsaYXJODEUgZG(suu7prn8WZCfZTa33(vunQxCVW2fan)Mhnn5zUI5wG7B)kQg1lUxy7cGMZZCfZTaxxSsuHmsY9cBxaKPjvSIIsvSK5tQjEwZPkbihpI255QU8i5zUa3tudp(VmL6MhD7D0heKrsAnn1)TqoQyffLQyjAGN5kMBboD5rYZCbUDXW3uLGDXW3uLatZPP(VfYzi9ImC(CA(KAAAEj1lbqoE)YiSuDX6eqRVK4gByAsfROOuflz(EVGN1CQsaYXJODEUQVYmQgH37jQHh)xMsDZJU9o6dcYijTMM6)wihvSIIsvSenWZCfZTaN(kZOAeEVDXW3uLGDXW3uLatZPP(VfYzi9ImC(CA(KAAAEj1lbqoE)YiSuDX6eqRVK4gByAsfROOuflz((lGN1CQsaYXJODEU2aUGOVxkEVwtudp(VmL6MhD7D0heKrsAnn1)TqoQyffLQyjAGN5kMBbUgWfe99sX71YfdFtvc2fdFtvcmnNM6)wiNH0lYW5ZP5tQPP5LuVea549lJWs1fRtaT(sIBSHPjvSIIsvSK57VaEwZPkbihpI2556OErFLzCIA4X)LPu38OBVJ(GGmssRPP(VfYrfROOuflrd8mxXClWnQx0xzgDXW3uLGDXW3uLatZPP(VfYzi9ImC(CA(KAAAEj1lbqoE)YiSuDX6eqRVK4gByAsfROOuflzoJfpR5uLaKJhr78CDv3gesTjcXBwbqtudp6HXWrFqqgj5I5waEwZPkbihpI255QEFRYHI(IZmAIA4rpmgo6dcYijxm3cWZAovja54r0opxFP9lWTASAwbnrn8Ohgdh9bbzKKlMBbAnn1)TqodPxKHZNtA4I100K6)wiNH0lYW5ZP5EMutttQ)BHCuXkkkv(CsnPMAWlAUbEwZPkbihpI255628xXPKcOEbLGgWLjQHNP5zUI5wGR1iYO)gPgjGu5q5NBL39cBxaKgMuttZlfV(q57lrxRrKr)nsnsaPYHYp3kVPjvSIIsvSK58mxXClW1Aez0FJuJeqQCO8ZTY7IHVPkb78cJRf1)TqodPxKHZNtAysn3qRP5zUI5wGJ(GGmsY9cBxaK6oii0CVyAoTGqcGlUPkuLavou(YpeovjWXwG81IkwrrPkwIg4zUI5wWo9Wy42M)koLua1lOe0aU4IHVPkbBSHPjvSIIsvSK5tQjEwZPkbihpI2556DO)y1avouTgLpjJjQHNP5Ts8kHhiX0K6)wihvSIIsvSenWZCfZTGDErZn0AA9Wy4OpiiJKCbFttEMRyUf4OpiiJKCVW2fanF)f2W0KkwrrPkwYCVShpR5uLaKJhr78C9lF)LOkGc53CzIA4HN5kMBbo6dcYij3lSDbqZ3u8SMtvcqoEeTZZvwHnFVv5qTc8kQIV0SOjQHNl1dJHJ(GGmsYf8XZAovja54r0opx9tQsWe1WJEymC0heKrsUxAoPLEymC6RmJRaICV0CY00)LPu38OBVJ(GGmsslQ)BHCgsVidNpNMpPMMMtpnpbOaBRVeNFsvcu5qfa6FfxsuncV3MM8eGcST(sCbG(xXLevJW79gAr9FlKJkwrrPkwY8lS30KkwrrPkwY8jVWg4znNQeGC8iANNR0heKrstudp6HXWrFqqgj5I5wGw8mxXClW9TFfvJ6f3lSDbqMMuXkkkvXsMVNr4z4znNQeGCiYJ4v(RevtjkKrs4znNQeGCiANNR69)9Tmrn80CQMsucqylbPH94znNQeGCiANNRTIn8r5v5qX)ClcpR5uLaKdr78CfjVVaifIkW9e1WZlJxqgT(s06YMtvcCi59faPqubUDfqnw1TbHN1CQsaYHODEU(TFfvJ6LjQHh9Wy4OpiiJKCXClW0CK8aAUxyKP5i5b08lOPwxs9saKBjKrVuiJKqob06ljAAQhgdxbuKHOEdVjdw3lSDbqZfVs4bsuuXk4zBgBRHh9Wy4OpiiJKCbFTMwpmgUaq(Va3QPkuLahIAoZAGXnnVS1O8fjUaq(Va3QPkuLaNaA9Le3W0K6)wihvSIIsvSK573JN1CQsaYHODEUQVYmQYHImeLaewVNOgE0dJHJ(GGmsYf81AA9Wy4ca5)cCRMQqvcCiQ5mRbg308YwJYxK4ca5)cCRMQqvcCcO1xsCdttQyffLQyjZ3VhpR5uLaKdr78CDK8asIQwJYxKO0LMDIA45s9Wy4OpiiJKCbFttQyffLQyjZzeEwZPkbihI255A)8gikKrstudp6HXWrFqqgj5c(APhgdhBJi5vS9ZmITbUGVwxQhgdhRWMV3QCOwbEfvXxAwKl4JN1CQsaYHODEU2fReviJKMOgE0dJHJ(GGmsYf8nnNwpmgUyg0xIIAFxm3cmn5Ts8kHhizdT0dJHZ)fEHefYijKlMBbMMJWAPEHB0)TOOIvMZBePOIv0IN5kMBbo6dcYij3lSDbq4znNQeGCiANNR9ZBGOqgjnrn8Ohgdh9bbzKKl4RLEymCSnIKxX2pZi2g4c(APhgdhRWMV3QCOwbEfvXxAwKl4JN1CQsaYHODEU6xYZlWTczKeEwZPkbihI255QF4RH3f4wPVAenrn8CPEymC0heKrsUGVPjvSIIsvSK5xmEwZPkbihI255kpbCbqFtsunwnRmrn8msEaTBK8aY9YTa8AFZJZhjpGCSTxPLEymC0heKrsUyUfO10xgtYXtaxa03KevJvZkk9WdCVW2faP1LnNQe44jGla6BsIQXQzfxbuJvDBqByAocRL6fUr)3IIkwz(npAAs9FlKJkwrrPkwYCgHN1CQsaYHODEUsgIka0ZaiQg5ZLjQHh9Wy4EHZ8sqi1iFU4c(MM6HXW9cN5LGqQr(CrXZaGK3HOMZ889AAAsfROOuflzoJWZAovja5q0opx7N3arHmsAIA4rpmgo6dcYijxm3c0AA9Wy48FHxirHmsc5c(An9i5bKgyeJmn1dJHJTrK8k2(zgX2axWFdtZrYdinSPmY0KkwrrPkwYCgTbEwZPkbihI255kIKo6TczKeEgEwZPkbih9fNzKrsip69)9TGN1CQsaYrFXzgzKeANNRIx5VsunLOqgjHN1CQsaYrFXzgzKeANNRDXkrfYiPjQHh9Wy4OV4mRqgjHCbFT4Ts8kHhirl9Wy4IzqFjkQ9DbF8SMtvcqo6loZiJKq78C9B)kQg1ltudp6HXWrFXzwHmsc5c(AnDRr5lsCJKhqsunQxCcO1xs00S1O8fjUcOidr9gEtgSUVbmRH9MMTgLViXHc)DbUviJKqob06ljAAs9saKdrV0SRciob06ljUbEwZPkbih9fNzKrsODEU2fReviJKMOgE0dJHJ(IZSczKeYf81AA9Wy48FHxirHmsc5I5wGPjpZvm3cCDXkrfYij3iSwQx4g9FlkQyL5nNQe46IvIkKrsoEJifvSIPPEymC0heKrsUG)g4znNQeGC0xCMrgjH25563(vunQxMOgE0dJHJ(IZSczKeYf8XZAovja5OV4mJmscTZZv2WIkKrstudp6HXWrFXzwHmsc5I5wGPPEymC(VWlKOqgjHCbFTUupmgo6dcYijxW30CK8asdBQM4znNQeGC0xCMrgjH2556i5bKevTgLVirPlnlEwZPkbih9fNzKrsODEU6h(A4DbUv6Rgr4znNQeGC0xCMrgjH255kpbCbqFtsunwnRGN1CQsaYrFXzgzKeANNR6RmJQCOidrjaH1B8SMtvcqo6loZiJKq78CLmevaONbqunYNltudp6HXW9cN5LGqQr(CXf8nn1dJH7foZlbHuJ85IINbajVdrnN5571epR5uLaKJ(IZmYij0opx9l55f4wHmscpR5uLaKJ(IZmYij0opxBfB4JYRYHI)5weEwZPkbih9fNzKrsODEUIK3xaKcrf4EIA45LXliJwFjADzZPkboK8(cGuiQa3UcOgR62GWZAovja5OV4mJmscTZZvejD0BfYijibjiea]] )


end