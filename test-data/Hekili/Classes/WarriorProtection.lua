-- WarriorProtection.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


if UnitClassBase( 'player' ) == 'WARRIOR' then
    local spec = Hekili:NewSpecialization( 73 )

    spec:RegisterResource( Enum.PowerType.Rage )

    -- Talents
    spec:RegisterTalents( {
        into_the_fray = 15760, -- 202603
        punish = 15759, -- 275334
        impending_victory = 15774, -- 202168

        crackling_thunder = 22373, -- 203201
        bounding_stride = 22629, -- 202163
        safeguard = 22409, -- 223657

        best_served_cold = 22378, -- 202560
        unstoppable_force = 22626, -- 275336
        dragon_roar = 23260, -- 118000

        indomitable = 23096, -- 202095
        never_surrender = 23261, -- 202561
        bolster = 22488, -- 280001

        menace = 22384, -- 275338
        rumbling_earth = 22631, -- 275339
        storm_bolt = 22800, -- 107570

        booming_voice = 22395, -- 202743
        vengeance = 22544, -- 202572
        devastator = 22401, -- 236279

        anger_management = 21204, -- 152278
        heavy_repercussions = 22406, -- 203177
        ravager = 23099, -- 228920
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3595, -- 208683
        relentless = 3594, -- 196029
        adaptation = 3593, -- 214027

        oppressor = 845, -- 205800
        disarm = 24, -- 236077
        sword_and_board = 167, -- 199127
        bodyguard = 168, -- 213871
        leave_no_man_behind = 169, -- 199037
        morale_killer = 171, -- 199023
        shield_bash = 173, -- 198912
        thunderstruck = 175, -- 199045
        ready_for_battle = 3063, -- 253900
        warpath = 178, -- 199086
        dragon_charge = 831, -- 206572
        mass_spell_reflection = 833, -- 213915
    } )

    -- Auras
    spec:RegisterAuras( {
        avatar = {
            id = 107574,
            duration = 20,
            max_stack = 1,
        },
        battle_shout = {
            id = 6673,
            duration = 3600,
            max_stack = 1,
            shared = "player", -- check for anyone's buff on the player.
        },
        berserker_rage = {
            id = 18499,
            duration = 6,
            type = "",
            max_stack = 1,
        },
        charge = {
            id = 105771,
            duration = 1,
            max_stack = 1,
        },
        deep_wounds = {
            id = 115768,
            duration = 19.5,
            max_stack = 1,
        },
        demoralizing_shout = {
            id = 1160,
            duration = 8,
            max_stack = 1,
        },
        devastator = {
            id = 236279,
        },
        dragon_roar = {
            id = 118000,
            duration = 6,
            max_stack = 1,
        },
        ignore_pain = {
            id = 190456,
            duration = 12,
            max_stack = 1,
        },
        intimidating_shout = {
            id = 5246,
            duration = 12,
            max_stack = 1,
        },
        into_the_fray = {
            id = 202602,
            duration = 3600,
            max_stack = 2,
        },
        kakushans_stormscale_gauntlets = {
            id = 207844,
            duration = 3600,
            max_stack = 1,
        },
        last_stand = {
            id = 12975,
            duration = 15,
            max_stack = 1,
        },
        punish = {
            id = 275335,
            duration = 9,
            max_stack = 1,
        },
        rallying_cry = {
            id = 97463,
            duration = 10,
            max_stack = 1,
        },
        ravager = {
            id = 228920,
            duration = 12,
            max_stack = 1,
        },
        revenge = {
            id = 5302,
            duration = 6,
            max_stack = 1,
        },
        shield_block = {
            id = 132404,
            duration = 7,
            max_stack = 1,
        },
        shield_wall = {
            id = 871,
            duration = 8,
            max_stack = 1,
        },
        shockwave = {
            id = 132168,
            duration = 2,
            max_stack = 1,
        },
        spell_reflection = {
            id = 23920,
            duration = 5,
            max_stack = 1,
        },
        storm_bolt = {
            id = 132169,
            duration = 2,
            max_stack = 1,
        },
        taunt = {
            id = 355,
            duration = 3,
            max_stack = 1,
        },
        thunder_clap = {
            id = 6343,
            duration = 10,
            max_stack = 1,
        },
        vanguard = {
            id = 71,
        },
        vengeance_ignore_pain = {
            id = 202574,
            duration = 15,
            max_stack = 1,
        },
        vengeance_revenge = {
            id = 202573,
            duration = 15,
            max_stack = 1,
        },


        -- Azerite Powers
        bastion_of_might = {
            id = 287379,
            duration = 20,
            max_stack = 1,
        },

        intimidating_presence = {
            id = 288644,
            duration = 12,
            max_stack = 1,
        },


    } )


    -- model rage expenditure reducing CDs...
    spec:RegisterHook( "spend", function( amt, resource )
        if resource == "rage" then
            if talent.anger_management.enabled and amt >= 10 then
                local secs = floor( amt / 10 )

                cooldown.avatar.expires = cooldown.avatar.expires - secs
                cooldown.last_stand.expires = cooldown.last_stand.expires - secs
                cooldown.shield_wall.expires = cooldown.shield_wall.expires - secs
                cooldown.demoralizing_shout.expires = cooldown.demoralizing_shout.expires - secs
            end

            if level < 116 and equipped.mannoroths_bloodletting_manacles and amt >= 10 then
                local heal = 0.01 * floor( amt / 10 )
                gain( heal * health.max, "health" )
            end
        end
    end )


    spec:RegisterGear( 'tier20', 147187, 147188, 147189, 147190, 147191, 147192 )
    spec:RegisterGear( 'tier21', 152178, 152179, 152180, 152181, 152182, 152183 )

    spec:RegisterGear( "ararats_bloodmirror", 151822 )
    spec:RegisterGear( "archavons_heavy_hand", 137060 )
    spec:RegisterGear( "ayalas_stone_heart", 137052 )
        spec:RegisterAura( "stone_heart", { id = 225947,
            duration = 10
        } )
    spec:RegisterGear( "ceannar_charger", 137088 )
    spec:RegisterGear( "destiny_driver", 137018 )
    spec:RegisterGear( "kakushans_stormscale_gauntlets", 137108 )
    spec:RegisterGear( "kazzalax_fujiedas_fury", 137053 )
        spec:RegisterAura( "fujiedas_fury", {
            id = 207776,
            duration = 10,
            max_stack = 4 
        } )
    spec:RegisterGear( "mannoroths_bloodletting_manacles", 137107 )
    spec:RegisterGear( "najentuss_vertebrae", 137087 )
    spec:RegisterGear( "soul_of_the_battlelord", 151650 )
    spec:RegisterGear( "the_great_storms_eye", 151823 )
        spec:RegisterAura( "tornados_eye", {
            id = 248142, 
            duration = 6, 
            max_stack = 6
        } )
    spec:RegisterGear( "the_walls_fell", 137054 )
    spec:RegisterGear( "thundergods_vigor", 137089 )
    spec:RegisterGear( "timeless_stratagem", 143728 )
    spec:RegisterGear( "valarjar_berserkers", 151824 )
    spec:RegisterGear( "weight_of_the_earth", 137077 ) -- NYI.

    -- Abilities
    spec:RegisterAbilities( {
        avatar = {
            id = 107574,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 90 end,
            gcd = "spell",

            spend = -20,
            spendType = "rage",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 613534,

            handler = function ()
                applyBuff( "avatar" )
                if azerite.bastion_of_might.enabled then
                    applyBuff( "bastion_of_might" )
                    applyBuff( "ignore_pain" )
                end
            end,
        },


        battle_shout = {
            id = 6673,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            essential = true, -- new flag, will prioritize using this in precombat APL even in combat.

            startsCombat = false,
            texture = 132333,

            nobuff = "battle_shout",

            handler = function ()
                applyBuff( "battle_shout" )
            end,
        },


        berserker_rage = {
            id = 18499,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            defensive = true,

            startsCombat = false,
            texture = 136009,

            handler = function ()
                applyBuff( "berserker_rage" )
            end,
        },


        demoralizing_shout = {
            id = 1160,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = function () return talent.booming_voice.enabled and -40 or 0 end,
            spendType = "rage",

            startsCombat = true,
            texture = 132366,

            -- toggle = "defensives", -- should probably be a defensive...

            handler = function ()
                applyDebuff( "target", "demoralizing_shout" )
                active_dot.demoralizing_shout = max( active_dot.demoralizing_shout, active_enemies )
            end,
        },


        devastate = {
            id = 20243,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 135291,

            notalent = "devastator",

            handler = function ()
                applyDebuff( "target", "deep_wounds" )

                if level < 116 and equipped.kakushans_stormscale_gauntlets then
                    applyBuff( "kakushans_stormscale_gauntlets" )
                end
            end,
        },


        dragon_roar = {
            id = 118000,
            cast = 0,
            cooldown = 35,
            gcd = "spell",

            spend = -10,
            spendType = "rage",

            startsCombat = true,
            texture = 642418,

            talent = "dragon_roar",
            range = 12,

            handler = function ()
                applyDebuff( "target", "dragon_roar" )
                active_dot.dragon_roar = max( active_dot.dragon_roar, active_enemies )
            end,
        },


        heroic_leap = {
            id = 6544,
            cast = 0,
            charges = function () return ( level < 116 and equipped.timeless_stratagem ) and 3 or nil end,
            cooldown = function () return talent.bounding_stride.enabled and 30 or 45 end,
            recharge = function () return talent.bounding_stride.enabled and 30 or 45 end,
            gcd = "spell",

            startsCombat = true,
            texture = 236171,

            handler = function ()
                setDistance( 5 )
                setCooldown( "taunt", 0 )

                if talent.bounding_stride.enabled then applyBuff( "bounding_stride" ) end
            end,
        },


        heroic_throw = {
            id = 57755,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132453,

            handler = function ()
            end,
        },


        ignore_pain = {
            id = 190456,
            cast = 0,
            cooldown = 1,
            gcd = "off",

            spend = function () return ( buff.vengeance_ignore_pain.up and 0.67 or 1 ) * 40 end,
            spendType = "rage",

            startsCombat = false,
            texture = 1377132,

            toggle = "defensives",

            readyTime = function ()
                if buff.ignore_pain.up and buff.ignore_pain.v1 > 0.3 * stat.attack_power * 3.5 * ( 1 + stat.versatility_atk_mod / 100 ) then
                    return buff.ignore_pain.remains - gcd.max
                end
                return 0
            end,

            handler = function ()
                if talent.vengeance.enabled then applyBuff( "vengeance_revenge" ) end
                removeBuff( "vengeance_ignore_pain" )

                applyBuff( "ignore_pain" )
            end,
        },


        impending_victory = {
            id = 202168,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 10,
            spendType = "rage",

            startsCombat = true,
            texture = 589768,

            talent = "impending_victory",

            handler = function ()
                gain( health.max * 0.2, "health" )
            end,
        },


        intercept = {
            id = 198304,
            cast = 0,
            charges = 2,
            cooldown = 15,
            recharge = 15,
            gcd = "spell",

            spend = -15,
            spendType = "rage",

            startsCombat = true,
            texture = 132365,

            usable = function () return target.distance > 10 end,
            handler = function ()
                applyDebuff( "target", "charge" )
                setDistance( 5 )
            end,
        },


        intimidating_shout = {
            id = 5246,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 132154,

            handler = function ()
                applyDebuff( "target", "intimidating_shout" )
                active_dot.intimidating_shout = max( active_dot.intimidating_shout, active_enemies )
                if azerite.intimidating_presence.enabled then applyDebuff( "target", "intimidating_presence" ) end
            end,
        },


        last_stand = {
            id = 12975,
            cast = 0,
            cooldown = function () return talent.bolster.enabled and 120 or 180 end,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = true,
            texture = 135871,

            handler = function ()
                applyBuff( "last_stand" )
            end,
        },


        pummel = {
            id = 6552,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 132938,

            toggle = "interrupts",
            interrupt = true,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        rallying_cry = {
            id = 97462,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 132351,

            handler = function ()
                applyBuff( "rallying_cry" )
                gain( 0.15 * health.max, "health" )
                health.max = health.max * 1.15
            end,
        },


        ravager = {
            id = 228920,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 970854,

            talent = "ravager",

            handler = function ()
                applyBuff( "ravager" )
            end,
        },


        revenge = {
            id = 6572,
            cast = 0,
            cooldown = 3,
            hasteCD = true,
            gcd = "spell",

            spend = function ()
                if buff.revenge.up then return 0 end
                return buff.vengeance_revenge.up and 20 or 30
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132353,

            usable = function ()
                if action.revenge.cost == 0 then return true end
                if toggle.defensives and buff.ignore_pain.down then return false, "don't spend on revenge if ignore_pain is down" end
                if settings.free_revenge and action.revenge.cost ~= 0 then return false, "free_revenge is checked and revenge is not free" end

                return true
            end,

            handler = function ()
                if talent.vengeance.enabled then applyBuff( "vengeance_ignore_pain" ) end

                if buff.revenge.up then removeBuff( "revenge" )
                else removeBuff( "vengeance_revenge" ) end

                applyDebuff( "target", "deep_wounds" )
            end,
        },


        shield_block = {
            id = 2565,
            cast = 0,
            charges = function () return ( level < 116 and equipped.ararats_bloodmirror ) and 3 or 2 end,
            cooldown = 16,
            recharge = 16,
            hasteCD = true,
            gcd = "off",

            toggle = "defensives",
            defensive = true,

            spend = 30,
            spendType = "rage",

            startsCombat = false,
            texture = 132110,

            readyTime = function () return max( talent.bolster.enabled and buff.last_stand.remains or 0, buff.shield_block.remains ) end,
            handler = function ()
                applyBuff( "shield_block" )
            end,
        },


        shield_slam = {
            id = 23922,
            cast = 0,
            cooldown = 9,
            hasteCD = true,
            gcd = "spell",

            spend = function () 
                return ( buff.kakushans_stormscale_gauntlets.up and 1.2 or 1 ) * ( ( level < 116 and equipped.the_walls_fell ) and -17 or -15 )
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 134951,

            handler = function ()
                if talent.heavy_repercussions.enabled and buff.shield_block.up then
                    buff.shield_block.expires = buff.shield_block.expires + 1
                end

                if talent.punish.enabled then applyDebuff( "target", "punish" ) end

                if level < 116 and equipped.the_walls_fell then
                    setCooldown( "shield_wall", cooldown.shield_wall.remains - 4 )
                end

                removeBuff( "kakushans_stormscale_gauntlets" )
            end,
        },


        shield_wall = {
            id = 871,
            cast = 0,
            cooldown = 240,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 132362,

            handler = function ()
                applyBuff( "shield_wall" )
            end,
        },


        shockwave = {
            id = 46968,
            cast = 0,
            cooldown = function () return ( talent.rumbling_earth.enabled and active_enemies >= 3 ) and 25 or 40 end,
            gcd = "spell",

            startsCombat = true,
            texture = 236312,

            toggle = "interrupts",
            debuff = "casting",
            readyTime = state.timeToInterrupt,
            usable = function () return not target.is_boss end,

            handler = function ()
                applyDebuff( "target", "shockwave" )
                active_dot.shockwave = max( active_dot.shockwave, active_enemies )
                if not target.is_boss then interrupt() end
            end,
        },


        spell_reflection = {
            id = 23920,
            cast = 0,
            charges = function () return ( level < 116 and equipped.ararats_bloodmirror ) and 2 or nil end,
            cooldown = 25,
            recharge = 25,
            gcd = "off",

            defensive = true,

            startsCombat = false,
            texture = 132361,

            handler = function ()
                applyBuff( "spell_reflection" )
            end,
        },


        storm_bolt = {
            id = 107570,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 613535,

            talent = "storm_bolt",

            handler = function ()
                applyDebuff( "target", "storm_bolt" )
            end,
        },


        taunt = {
            id = 355,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            startsCombat = true,
            texture = 136080,

            handler = function ()
                applyDebuff( "target", "taunt" )
            end,
        },


        thunder_clap = {
            id = 6343,
            cast = 0,
            cooldown = function () return haste * ( ( buff.avatar.up and talent.unstoppable_force.enabled ) and 3 or 6 ) end,
            gcd = "spell",

            spend = function () return ( buff.kakushans_stormscale_gauntlets.up and 1.2 or 1 ) * -5 end,
            spendType = "rage",

            startsCombat = true,
            texture = 136105,

            handler = function ()
                applyDebuff( "target", "thunder_clap" )
                active_dot.thunder_clap = max( active_dot.thunder_clap, active_enemies )

                if level < 116 and equipped.thundergods_vigor then
                    setCooldown( "demoralizing_shout", cooldown.demoralizing_shout.remains - ( 3 * active_enemies ) )
                end

                removeBuff( "kakushans_stormscale_gauntlets" )
            end,
        },


        victory_rush = {
            id = 34428,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132342,

            buff = "victorious",

            handler = function ()
                removeBuff( "victorious" )
                gain( 0.2 * health.max, "health" )
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 8,

        potion = "potion_of_unbridled_fury",

        package = "Protection Warrior",
    } )


    spec:RegisterSetting( "free_revenge", true, {
        name = "Free |T132353:0|t Revenge",
        desc = "If checked, the Revenge ability will only be recommended when it costs 0 Rage to use.",
        type = "toggle",
        width = 1.5
    } )


    spec:RegisterPack( "Protection Warrior", 20200126, [[dKeYMaqivvPhbaBIsfFsvfLrbOCkavRcqIxPkmlIk3svvzxk5xukddvQJru1YikEgrPMMQQQRbG2MQkY3uvfnoIs6CasADQQOAEaI7PkTpujDqvvHfQk6HeLOjsPsYfPuP4JeLqNKsLyLOIzciLBsPsPDQuAOQQqlfqQEQqtvP4QuQu1xjkb7vXFLQbl4WqlgHhJYKLYLjTzG(mrgTs1PLSAkvs9AkvnBkUnI2TOFRYWvvooLkvwospNW0P66uY2rv(oanEvvW5vvP1JkX8rvTFqpYpBMydDD2kd3YWn3YiJSxCdu5w2Ypr)3pDIFiZEusNyIK6e)r65kZRlHbzbKsRJoXp8xZHTzZefNfLPtC39pXp3MnPY3TiwSJ0MOiTmOxxYOiOBtuKmBtKWQmUDjhIj2qxNTYWTmCZTmYi7f3avULn3aCIIpLnB)tzpX9Q10CiMytfSjcay4hPNRmVUegKfqkTokKdaGHD3)e)CB2KkF3IyXosBII0YGEDjJIGUnrrYGCaamWbtlK(lmiZpjhmid3YWnKdKdaGbz5oMsQaYbaWW)GH)O1Gb72Ylj0RlHbZjvmyWpyivaHHyrklHH)4hbAlihaad)dgSRud(lm40kTxDbmam9hy6NddYI0lL(zcGddGhfg(dEOJ0fKdaGH)bdaTsA31egI7LAAWWtZXShgWSbd2fP8Okm8JyLWqdjrjfgQ0r7vyGQ2Dwfvj10flihaad)dga6k5XtHb65OxxIgyWsGskmCGWaqdfomeDmBlihaad)dgS7fkma0vEAkPWaWaCxtyOCyGDcxadaDusbomCP5xyOaHHYHbaV8N5WqLUsbvQcdaw(omqwEjHED5AIF0dSm6ebam8J0ZvMxxcdYciLwhfYbaWWU7FIFUnBsLVBrSyhPnrrAzqVUKrrq3MOizqoaag4GPfs)fgK5NKdgKHBz4gYbYbaWGSChtjva5aay4FWWF0AWGDB5Le61LWG5Kkgm4hmKkGWqSiLLWWF8JaTfKdaGH)bd2vQb)fgCAL2RUagaM(dm9ZHbzr6Ls)mbWHbWJcd)bp0r6cYbaWW)GbGwjT7AcdX9snny4P5y2ddy2Gb7IuEufg(rSsyOHKOKcdv6O9kmqv7oRIQKA6IfKdaGH)bdaDL84PWa9C0RlrdmyjqjfgoqyaOHchgIoMTfKdaGH)bd29cfga6kpnLuyayaURjmuomWoHlGbGokPahgU08lmuGWq5WaGx(ZCyOsxPGkvHbalFhgilVKqVUCb5a5aayWU5huMLRnyGqbpQcdSJKaDyGqLQuSGH)GX0pxad5L)BhPKGwgyazEDPagU087cYbaWaY86sX6JQSJKa9xqdkShYbaWaY86sX6JQSJKa9hV2aVRb5aayazEDPy9rv2rsG(JxBOLePMo61LqoaagIj(j2phgOy1GbclqqTbdchDbmqOGhvHb2rsGomqOsvkGbmBWWhv)335ELsWqjGH2L6cYbzEDPy9rv2rsG(JxBeO7gTl2plhYbzEDPy9rv2rsG(JxBwcTxUskxIK6lYfXosrrh8sVFG9VdqLc5GmVUuS(Ok7ijq)XRnapQPXtRStvXLyYuihK51LI1hvzhjb6pETrQKh93(b2nwSQ1BufjfqoiZRlfRpQYosc0F8AtYcPTcZ(b2rUO0Z3HCqMxxkwFuLDKeO)412351LqoqoaagSB(bLz5AdguEk9xyWlsfg8DfgqMFuyOeWaYdldsy0fKdY86sXBLUsz6Nd5GmVUu8412NfjPAGCqMxxkE8AtSFm7be5PYvGVnLWceCXqHxP0Y6Zo)1rQK6Rs0joHaYbzEDP4XRnlH2lxjfYvGVS7mTdWCH8qhPlQsIvkaYReRXNpHfi4c5HosxwFqoiZRlfpETryUR1bTO)c5GmVUu841gHsfk1(kLGCqMxxkE8AdPmm1UFuQMoKdY86sXJxBMsA3fD7ARMePMoKdY86sXJxBGfvjm31GCqMxxkE8AdtMkCkA6m0yGCqMxxkE8AJaL6hy3PfZEbKdY86sXJxBFNxxkxb(sybcUqEOJ0L1hF(ErQD)6TsbImaeYbaWGLqHb7IuEufg(rSsyWpya5DvdgOOKcdm87RsjihK51LIhV2kP8OA)dRuUc8LIs6QPGfRCGidaFid3afhnA6lI7iRuQZ7kMU0ejmAdOWUZ0oaZvtjpkAkUuPuxSFw(IQy7xihK51LIhV2a8OMgpTYovfxIjtLRaFz3zAhG5c5HosxuLeRuaKxzGCqMxxkE8AJwFFgTxzx8HmfYbzEDP4XRnsL8O)2pWUXIvTEJQiPaYbzEDP4XRn2LmnDk6ARdAqsvUc8LWceCH8qhPR2byAN)2oFXUKPPtrxBDqdsQDclAUOkjwPGRCZNVkeAY0LVRDg1IvegTFGDqdsQlkM2dezd5aayazEDP4XRndk8UWXSjxb(YUZ0oaZfMfj2pWEtrFFrvsSsbqELbYbzEDP4XRnKh6ifYbzEDP4XRngAmDK51LDtjC5sKuFjlVKqVUuUc8Ts2rwPuVHKOK2bOGRCd5GmVUu841g1k7iZRl7Ms4YLiP(INkxb(k(uJP7ivsDXY3TYMs7md(X1xzd5GmVUu841gdnMoY86YUPeUCjsQVchYbYbzEDPyrwEjHED5BjLhv7FyLYvGVvYoYkL6nKeL0oafqoiZRlflYYlj0RlF8AtSxQP1jmhZE5kWxG9xhnA6lIZiCLU0ejmAJp))sybcUmOW7chZ2Y6d42bySDKkPIoifzEDjA4Q8lzLp)kzhzLs9gsIsAhGcGd5GmVUuSilVKqVU8XRTMsEu0uCPsPUy)SC5kWxG5ivs9fGLVxP8CZNpY8IN21ujlvWv5bUDagWQKDKvk1BijkPDak4k3l5biqzxrJVViXFGp)Dfn((6J5ar2CdC(8b2FD0OPViUJSsPoVRy6stKWOn(8POKUiXF4FuusbY)5g4ahYbzEDPyrwEjHED5JxBgu4DHJztUc8Ts2rwPuVHKOK2LTGR7kA8D7WUZ0oaZfMfj2pWEtrFFrvsSsbqELbYbzEDPyrwEjHED5JxBI9snToGOXixb(wj7iRuQ3qsus7auW1Dfn(oF(7kA891hZbImCd5a5GmVUuSWtF9DRSP0oZGFqoiZRlfl80hV2ivYJ(B)a7glw16nQIKc5kWxclqWfYdDKUAhGjKdY86sXcp9XRTMsEu0uCPsPUy)SC5kWxhnA6lI7iRuQZ7kMU0ejmAdYbzEDPyHN(41gMfj2pWEtrFxUc8LWceCzqH3foMTL1hKdY86sXcp9XRTgfLUStpKc5GmVUuSWtF8AJQ80usLRaFjSabxuLNMs6Y6Jp))6NKKrxnfutrXtf85tybcUkP8OA)dRCz9XNpWiSabxI9snToH5y2VOkjwPGpF2DM2byUe7LAADcZXSFX2rQKk6GuK51LObiCVKvGd5GmVUuSWtF8AZsO9Yvs5sKuFLOxkj6F0IenDkkPYvGVewGGlKh6iD1oat(8z3zAhG5Y3TYMs7md(TOkjwPGRV)hYbzEDPyHN(41gf5HskfYbaWaY86sXcp9XRnXEPMwNWCm7LRaFz3zAhG5sSxQP1fgKCrvS9RDiSabxI9snToH5y2VAhGjKdY86sXcp9XRnXEPMwxyqsihK51LIfE6JxB8kMF0F7ulXoKdY86sXcp9XRTI8tZwLsDEfZp6VqoiZRlfl80hV2Akpu4ORqoqoiZRlflH)67wztPDMb)KRaFfFQX0DKkPUy57wztPDMb)ELXooA00xwPWVVpKWODWJY0LMiHrB2HWceCH8qhPlRpihaadiZRlflH)41MyVutRtyoM9YvGVS7mTdWCj2l106cdsUOk2(1oewGGlXEPMwNWCm7xTdWeYbzEDPyj8hV2e7LAADHbjLRaFjSabxI9snToH5y2VS(GCqMxxkwc)XRnF3kBkTZm4NCf4lWC0OPVSsHFFFiHr7GhLPlnrcJ2SdHfi4c5HosxwFahYbzEDPyj8hV2Ak5rrtXLkL6I9ZYLRaFD0OPViUJSsPoVRy6stKWOnihK51LILWF8AdZIe7hyVPOVlxb(sybcUmOW7chZ2Y6dYbzEDPyj8hV2e7LAADHbjHCqMxxkwc)XRnlH2lxjLlrs9ff78WufDkYLJ2zhfnYvGVnLWceCrrUC0o7OOP3uclqWLWrM9VCd5GmVUuSe(JxBwcTxUskxIK6lk25HPk6uKlhTZokAKRaFBkHfi4IIC5OD2rrtVPewGGlHJm756FAhGXUZ0oaZfYdDKUOkjwPaiaKpFclqWfYdDKUS(aoKdY86sXs4pET1OO0LD6HuihK51LILWF8AZ3TYMs7md(b5GmVUuSe(JxBuLNMsQCf4lHfi4IQ80usxwF85)x)KKm6QPGAkkEQGpFclqWvjLhv7FyLlRp(8bgHfi4sSxQP1jmhZ(fvjXkf85ZUZ0oaZLyVutRtyoM9l2osLurhKImVUenaH7LScCihK51LILWF8AZsO9Yvs5sKuFLOxkj6F0IenDkkPYvGVewGGlKh6iD1oat(8z3zAhG5sSxQP1fgKCrvsSsbxF)pKdY86sXs4pETrrEOKsHCqMxxkwc)XRnEfZp6VDQLyhYbzEDPyj8hV2kYpnBvk15vm)O)c5GmVUuSe(JxBnLhkC01jYtPI6YzRmCld3ClVm)FIaI0SsjXeTlKFh11gmaqyazEDjmykHlwqot0ucxmBMytbrlJpBMTYpBMiY86YjwPRuM(5tutKWOT554ZwzMntezED5e)SijvZe1ejmABEo(Sv2ZMjQjsy028CImA5kTWj2uclqWfdfELslRpyWoWWFHbhPsQVkrN4eIjImVUCII9JzpGipD8z7)NntutKWOT55ez0YvAHtKDNPDaMlKh6iDrvsSsbmaKxyqI1Gb(8HbclqWfYdDKUS(MiY86YjAj0E5kPy8zlaNntezED5ejm316Gw0FNOMiHrBZZXNT)0SzIiZRlNiHsfk1(kLMOMiHrBZZXNT)5SzIiZRlNiszyQD)Oun9jQjsy028C8zRSoBMiY86YjAkPDx0TRTAsKA6tutKWOT554ZwG6SzIiZRlNiyrvcZDTjQjsy028C8zR8CpBMiY86YjIjtfofnDgAmtutKWOT554Zw5LF2mrK51LtKaL6hy3PfZEXe1ejmABEo(SvEzMntutKWOT55ez0YvAHtKWceCH8qhPlRpyGpFyWlsT7xVvkmaeyqgaorK51Lt8786YXNTYl7zZe1ejmABEorgTCLw4ePOKUAkyXkhgacmidaHHhWGmCddafyWrJM(I4oYkL68UIPlnrcJ2GbGcmWUZ0oaZvtjpkAkUuPuxSFw(IQy73jImVUCILuEuT)Hvo(Sv()pBMOMiHrBZZjYOLR0cNi7ot7amxip0r6IQKyLcyaiVWGmtezED5eb8OMgpTYovfxIjthF2kpaNntezED5eP13Nr7v2fFitNOMiHrBZZXNTY)tZMjImVUCIKk5r)TFGDJfRA9gvrsXe1ejmABEo(Sv()C2mrnrcJ2MNtKrlxPforclqWfYdDKUAhGjmyhy4VWq78f7sMMofDT1bniP2jSO5IQKyLcyGRWa3WaF(WGkeAY0LVRDg1IvegTFGDqdsQlkM2ddabgK9erMxxor2LmnDk6ARdAqsD8zR8Y6SzIiZRlNiYdDKornrcJ2MNJpBLhOoBMOMiHrBZZjYOLR0cNyLSJSsPEdjrjTdqbmWvyG7jImVUCIm0y6iZRl7Ms4t0ucVNiPorYYlj0RlhF2kd3ZMjQjsy028CImA5kTWjk(uJP7ivsDXY3TYMs7md(bdC9fgK9erMxxorQv2rMxx2nLWNOPeEprsDI4PJpBLr(zZe1ejmABEorK51LtKHgthzEDz3ucFIMs49ej1jk8XhFIFuLDKeOpBMTYpBMiY86YjsGUB0Uy)S8jQjsy028C8zRmZMjQjsy028CIjsQte5IyhPOOdEP3pW(3bOsNiY86YjICrSJuu0bV07hy)7auPJpBL9SzIiZRlNiGh104Pv2PQ4smz6e1ejmABEo(S9)ZMjImVUCIKk5r)TFGDJfRA9gvrsXe1ejmABEo(SfGZMjImVUCIswiTvy2pWoYfLE((e1ejmABEo(S9NMntezED5e)oVUCIAIegTnphF8jswEjHED5Sz2k)SzIAIegTnpNiJwUslCIvYoYkL6nKeL0oaftezED5elP8OA)dRC8zRmZMjQjsy028CImA5kTWjcmy4VWGJgn9fXzeUsxAIegTbd85dd)fgiSabxgu4DHJzBz9bdahgSdmamyGTJujv0bPiZRlrdmWvyq(LScd85ddvYoYkL6nKeL0oafWaWNiY86Yjk2l106eMJz)4ZwzpBMOMiHrBZZjYOLR0cNiWGbhPsQVaS89kLNByGpFyazEXt7AQKLkGbUcdYddahgSdmamyayWqLSJSsPEdjrjTdqbmWvyG7L8aegakWWUIgFFrI)amWNpmSROX3xFmhgacmiBUHbGdd85ddadg(lm4OrtFrChzLsDExX0LMiHrBWaF(WafL0fj(dWW)GbkkPWaqGH)ZnmaCya4tezED5eBk5rrtXLkL6I9ZYhF2()zZe1ejmABEorgTCLw4eRKDKvk1BijkPDzlGbUcd7kA8DyWoWa7ot7amxywKy)a7nf99fvjXkfWaqEHbzMiY86YjAqH3foMTXNTaC2mrnrcJ2MNtKrlxPfoXkzhzLs9gsIsAhGcyGRWWUIgFhg4Zhg2v047RpMddabgKH7jImVUCII9snToGOXm(4tu4ZMzR8ZMjQjsy028CImA5kTWjk(uJP7ivsDXY3TYMs7md(bdVWGmWGDGbhnA6lRu433hsy0o4rz6stKWOnyWoWaHfi4c5HosxwFtezED5e9DRSP0oZGFJpBLz2mrnrcJ2MNtKrlxPforclqWLyVutRtyoM9lRVjImVUCII9snTUWGKJpBL9SzIAIegTnpNiJwUslCIadgC0OPVSsHFFFiHr7GhLPlnrcJ2Gb7adewGGlKh6iDz9bdaFIiZRlNOVBLnL2zg8B8z7)NntutKWOT55ez0YvAHt0rJM(I4oYkL68UIPlnrcJ2MiY86Yj2uYJIMIlvk1f7NLp(SfGZMjQjsy028CImA5kTWjsybcUmOW7chZ2Y6BIiZRlNiMfj2pWEtrFF8z7pnBMiY86Yjk2l106cdsornrcJ2MNJpB)ZzZe1ejmABEorK51Ltef78WufDkYLJ2zhfntKrlxPfoXMsybcUOixoANDu00BkHfi4s4iZEy4fg4EIjsQtef78WufDkYLJ2zhfnJpBL1zZe1ejmABEorK51Ltef78WufDkYLJ2zhfntKrlxPfoXMsybcUOixoANDu00BkHfi4s4iZEyGRWWFcd2bgagmWUZ0oaZfYdDKUOkjwPagacmaqyGpFyGWceCH8qhPlRpya4tmrsDIOyNhMQOtrUC0o7OOz8zlqD2mrK51LtSrrPl70dPtutKWOT554Zw55E2mrK51Lt03TYMs7md(nrnrcJ2MNJpBLx(zZe1ejmABEorgTCLw4ejSabxuLNMs6Y6dg4Zhg(lm4NKKrxnfutrXtfWaF(WaHfi4QKYJQ9pSYL1hmWNpmamyGWceCj2l106eMJz)IQKyLcyGpFyGDNPDaMlXEPMwNWCm7xSDKkPIoifzEDjAGbGadCVKvya4tezED5ePkpnL0XNTYlZSzIAIegTnpNiY86YjkrVus0)OfjA6uusNiJwUslCIewGGlKh6iD1oatyGpFyGDNPDaMlXEPMwxyqYfvjXkfWaxFHH)pXej1jkrVus0)OfjA6uushF2kVSNntezED5ePipusPtutKWOT554Zw5))SzIiZRlNiVI5h93o1sSprnrcJ2MNJpBLhGZMjImVUCIf5NMTkL68kMF0FNOMiHrBZZXNTY)tZMjImVUCInLhkC01jQjsy028C8XNiE6Sz2k)SzIiZRlNOVBLnL2zg8BIAIegTnphF2kZSzIAIegTnpNiJwUslCIewGGlKh6iD1oaZjImVUCIKk5r)TFGDJfRA9gvrsX4ZwzpBMOMiHrBZZjYOLR0cNOJgn9fXDKvk15DftxAIegTnrK51LtSPKhfnfxQuQl2plF8z7)NntutKWOT55ez0YvAHtKWceCzqH3foMTL13erMxxormlsSFG9MI((4ZwaoBMiY86Yj2OO0LD6H0jQjsy028C8z7pnBMOMiHrBZZjYOLR0cNiHfi4IQ80usxwFWaF(WWFHb)KKm6QPGAkkEQag4ZhgiSabxLuEuT)HvUS(Gb(8HbGbdewGGlXEPMwNWCm7xuLeRuad85ddS7mTdWCj2l106eMJz)ITJujv0bPiZRlrdmaeyG7LScdaFIiZRlNiv5PPKo(S9pNntutKWOT55erMxxorj6LsI(hTirtNIs6ez0YvAHtKWceCH8qhPR2bycd85ddS7mTdWC57wztPDMb)wuLeRuadC9fg()etKuNOe9sjr)JwKOPtrjD8zRSoBMiY86YjsrEOKsNOMiHrBZZXNTa1zZerMxxorXEPMwxyqYjQjsy028C8zR8CpBMiY86YjYRy(r)TtTe7tutKWOT554Zw5LF2mrK51LtSi)0SvPuNxX8J(7e1ejmABEo(SvEzMntezED5eBkpu4ORtutKWOT554Jp(erlF)OtmwKwg0RlLLue0hF8za]] )


end
