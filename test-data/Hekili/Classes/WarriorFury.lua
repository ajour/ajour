-- WarriorFury.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


if UnitClassBase( 'player' ) == 'WARRIOR' then
    local spec = Hekili:NewSpecialization( 72 )

    local base_rage_gen, fury_rage_mult = 1.75, 1.00
    local offhand_mod = 0.50

    spec:RegisterResource( Enum.PowerType.Rage, {
        mainhand_fury = {
            -- setting = "forecast_fury",

            last = function ()
                local swing = state.swings.mainhand
                local t = state.query_time

                return swing + ( floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed )
            end,

            interval = "mainhand_speed",

            stop = function () return state.time == 0 or state.swings.mainhand == 0 end,
            value = function ()
                return ( state.talent.war_machine.enabled and 1.1 or 1 ) * ( base_rage_gen * fury_rage_mult * state.swings.mainhand_speed / state.haste )
            end
        },

        offhand_fury = {
            -- setting = 'forecast_fury',

            last = function ()
                local swing = state.swings.offhand
                local t = state.query_time

                return swing + ( floor( ( t - swing ) / state.swings.offhand_speed ) * state.swings.offhand_speed )
            end,

            interval = 'offhand_speed',

            stop = function () return state.time == 0 or state.swings.offhand == 0 end,
            value = function ()
                return ( state.talent.war_machine.enabled and 1.1 or 1 ) * base_rage_gen * fury_rage_mult * state.swings.mainhand_speed * offhand_mod / state.haste
            end,
        },

        bladestorm = {
            aura = "bladestorm",

            last = function ()
                local app = state.buff.bladestorm.applied
                local t = state.query_time

                return app + ( floor( ( t - app ) / ( 1 * state.haste ) ) * ( 1 * state.haste ) )
            end,

            interval = function () return 1 * state.haste end,

            value = 5,
        },

        battle_trance = {
            aura = "battle_trance",

            last = function ()
                local app = state.buff.battle_trance.applied
                local t = state.query_time

                return app + ( floor( ( t - app ) / state.haste ) * state.haste )
            end,

            interval = 3,

            value = 5,
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        war_machine = 22632, -- 262231
        endless_rage = 22633, -- 202296
        fresh_meat = 22491, -- 215568

        double_time = 19676, -- 103827
        impending_victory = 22625, -- 202168
        storm_bolt = 23093, -- 107570

        inner_rage = 22379, -- 215573
        sudden_death = 22381, -- 280721
        furious_slash = 23372, -- 100130

        furious_charge = 23097, -- 202224
        bounding_stride = 22627, -- 202163
        warpaint = 22382, -- 208154

        carnage = 22383, -- 202922
        massacre = 22393, -- 206315
        frothing_berserker = 19140, -- 215571

        meat_cleaver = 22396, -- 280392
        dragon_roar = 22398, -- 118000
        bladestorm = 22400, -- 46924

        reckless_abandon = 22405, -- 202751
        anger_management = 22402, -- 152278
        siegebreaker = 16037, -- 280772
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3592, -- 208683
        relentless = 3591, -- 196029
        adaptation = 3590, -- 214027

        death_wish = 179, -- 199261
        enduring_rage = 177, -- 198877
        thirst_for_battle = 172, -- 199202
        battle_trance = 170, -- 213857
        barbarian = 166, -- 280745
        slaughterhouse = 3735, -- 280747
        spell_reflection = 1929, -- 216890
        death_sentence = 25, -- 198500
        disarm = 3533, -- 236077
        master_and_commander = 3528, -- 235941
    } )


    -- Auras
    spec:RegisterAuras( {
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
        bladestorm = {
            id = 46924,
            duration = function () return 4 * haste end,
            max_stack = 1,
        },
        bounding_stride = {
            id = 202164,
            duration = 3,
            max_stack = 1,
        },
        charge = {
            id = 105771,
            duration = 1,
            max_stack = 1,
        },
        dragon_roar = {
            id = 118000,
            duration = 6,
            max_stack = 1,
        },
        enrage = {
            id = 184362,
            duration = 4,
            max_stack = 1,
        },
        enraged_regeneration = {
            id = 184364,
            duration = 8,
            max_stack = 1,
        },
        frothing_berserker = {
            id = 215572,
            duration = 6,
            max_stack = 1,
        },
        furious_charge = {
            id = 202225,
            duration = 5,
            max_stack = 1,
        },
        furious_slash = {
            id = 202539,
            duration = 15,
            max_stack = 3,
        },
        intimidating_shout = {
            id = 5246,
            duration = 8,
            max_stack = 1,
        },
        piercing_howl = {
            id = 12323,
            duration = 15,
            max_stack = 1,
        },
        rallying_cry = {
            id = 97463,
            duration = 10,
            max_stack = 1,
        },
        recklessness = {
            id = 1719,
            duration = function () return talent.reckless_abandon.enabled and 14 or 10 end,
            max_stack = 1,
        },
        siegebreaker = {
            id = 280773,
            duration = 10,
            max_stack = 1,
        },
        sign_of_the_skirmisher = {
            id = 186401,
            duration = 3600,
            max_stack = 1,
        },
        storm_bolt = {
            id = 132169,
            duration = 4,
            max_stack = 1,
        },
        sudden_death = {
            id = 280776,
            duration = 10,
            max_stack = 1,
        },
        taunt = {
            id = 355,
            duration = 3,
            max_stack = 1,
        },
        victorious = {
            id = 32216,
            duration = 20,
        },
        whirlwind = {
            id = 85739,
            duration = 20,
            max_stack = 2,
            copy = "meat_cleaver"
        },


        -- Azerite Powers
        gathering_storm = {
            id = 273415,
            duration = 6,
            max_stack = 5,
        },

        -- Cold Steel, Hot Blood
        gushing_wound = {
            id = 288091,
            duration = 6,
            max_stack = 1,
        },

        intimidating_presence = {
            id = 288644,
            duration = 12,
            max_stack = 1,
        },


        -- PvP Talents
        battle_trance = {
            id = 213858,
            duration = 18,
            max_stack = 1
        }
    } )


    spec:RegisterGear( 'tier20', 147187, 147188, 147189, 147190, 147191, 147192 )
        spec:RegisterAura( "raging_thirst", {
            id = 242300, 
            duration = 8
         } ) -- fury 2pc.
        spec:RegisterAura( "bloody_rage", {
            id = 242952,
            duration = 10,
            max_stack = 10
         } ) -- fury 4pc.

    spec:RegisterGear( 'tier21', 152178, 152179, 152180, 152181, 152182, 152183 )
        spec:RegisterAura( "slaughter", {
            id = 253384,
            duration = 4
        } ) -- fury 2pc dot.
        spec:RegisterAura( "outrage", {
            id = 253385,
            duration = 8
         } ) -- fury 4pc.

    spec:RegisterGear( "ceannar_charger", 137088 )
    spec:RegisterGear( "timeless_stratagem", 143728 )
    spec:RegisterGear( "kazzalax_fujiedas_fury", 137053 )
        spec:RegisterAura( "fujiedas_fury", {
            id = 207776,
            duration = 10,
            max_stack = 4 
        } )
    spec:RegisterGear( "mannoroths_bloodletting_manacles", 137107 ) -- NYI.
    spec:RegisterGear( "najentuss_vertebrae", 137087 )
    spec:RegisterGear( "valarjar_berserkers", 151824 )
    spec:RegisterGear( "ayalas_stone_heart", 137052 )
        spec:RegisterAura( "stone_heart", { id = 225947,
            duration = 10
        } )
    spec:RegisterGear( "the_great_storms_eye", 151823 )
        spec:RegisterAura( "tornados_eye", {
            id = 248142, 
            duration = 6, 
            max_stack = 6
        } )
    spec:RegisterGear( "archavons_heavy_hand", 137060 )
    spec:RegisterGear( "weight_of_the_earth", 137077 ) -- NYI.

    spec:RegisterGear( "soul_of_the_battlelord", 151650 )


    local function IsActiveSpell( id )
        local slot = FindSpellBookSlotBySpellID( id )
        if not slot then return false end

        local _, _, spellID = GetSpellBookItemName( slot, "spell" )
        return id == spellID 
    end

    state.IsActiveSpell = IsActiveSpell

    local whirlwind_consumers = {
        bloodthirst = 1,
        execute = 1,
        furious_slash = 1,
        impending_victory = 1,
        raging_blow = 1,
        rampage = 1,
        siegebreaker = 1,
        storm_bolt = 1,
        victory_rush = 1
    }

    local whirlwind_gained = 0
    local whirlwind_stacks = 0

    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function( event )
        local _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID and subtype == "SPELL_CAST_SUCCESS" then
            local ability = class.abilities[ spellID ]

            if not ability then return end

            if ability.key == "whirlwind" then
                whirlwind_gained = GetTime()
                whirlwind_stacks = 2
            
            elseif whirlwind_consumers[ ability.key ] and whirlwind_stacks > 0 then
                whirlwind_stacks = whirlwind_stacks - 1

            end
        end
    end )


    local rageSpent = 0

    spec:RegisterHook( "spend", function( amt, resource )
        if talent.recklessness.enabled and resource == "rage" then
            rageSpent = rageSpent + amt
            cooldown.recklessness.expires = cooldown.recklessness.expires - floor( rageSpent / 20 )
            rageSpent = rageSpent % 20
        end
    end )


    spec:RegisterHook( "reset_precast", function ()
        rageSpent = 0
        
        if buff.bladestorm.up then
            setCooldown( "global_cooldown", max( cooldown.global_cooldown.remains, buff.bladestorm.remains ) )
            if buff.gathering_storm.up then
                applyBuff( "gathering_storm", buff.bladestorm.remains + 6, 5 )
            end
        end

        if buff.whirlwind.up then
            if whirlwind_stacks == 0 then removeBuff( "whirlwind" )
            elseif whirlwind_stacks < buff.whirlwind.stack then
                applyBuff( "whirlwind", buff.whirlwind.remains, whirlwind_stacks )
            end
        end
    end )    


    -- Abilities
    spec:RegisterAbilities( {
        battle_shout = {
            id = 6673,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = false,
            texture = 132333,

            essential = true,
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

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136009,

            handler = function ()
                applyBuff( "berserker_rage" )
                if level < 116 and equipped.ceannar_charger then gain( 8, "rage" ) end
            end,
        },


        bladestorm = {
            id = 46924,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 236303,

            range = 8,

            handler = function ()
                applyBuff( "bladestorm" )
                gain( 5, "rage" )
                setCooldown( "global_cooldown", 4 * haste )

                if level < 116 and equipped.the_great_storms_eye then addStack( "tornados_eye", 6, 1 ) end

                if azerite.gathering_storm.enabled then
                    applyBuff( "gathering_storm", 6 + ( 4 * haste ), 5 )
                end
            end,
        },


        bloodthirst = {
            id = 23881,
            cast = 0,
            cooldown = 4.5,
            hasteCD = true,
            gcd = "spell",

            spend = -8,
            spendType = "rage",

            startsCombat = true,
            texture = 136012,

            handler = function ()
                gain( health.max * ( buff.enraged_regeneration.up and 0.25 or 0.05 ) * ( talent.fresh_meat.enabled and 1.2 or 1 ), "health" )
                if level < 116 and equipped.kazzalax_fujiedas_fury then addStack( "fujiedas_fury", 10, 1 ) end
                removeBuff( "bloody_rage" )
                removeStack( "whirlwind" )
                if azerite.cold_steel_hot_blood.enabled and stat.crit >= 100 then
                    applyDebuff( "target", "gushing_wound" )
                    gain( 4, "rage" )
                end
            end,
        },


        charge = {
            id = 100,
            cast = 0,
            charges = function () return talent.double_time.enabled and 2 or nil end,
            cooldown = function () return talent.double_time.enabled and 17 or 20 end,
            recharge = function () return talent.double_time.enabled and 17 or 20 end,
            gcd = "spell",

            startsCombat = true,
            texture = 132337,

            usable = function () return target.distance > 10 and ( query_time - max( action.charge.lastCast, action.heroic_leap.lastCast ) > gcd.execute ) end,
            handler = function ()
                applyDebuff( "target", "charge" )
                if talent.furious_charge.enabled then applyBuff( "furious_charge" ) end
                setDistance( 5 )
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
            end,
        },


        enraged_regeneration = {
            id = 184364,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 132345,

            handler = function ()
                applyBuff( "enraged_regeneration" )
            end,
        },


        execute = {
            id = function () return IsActiveSpell( 280735 ) and 280735 or 5308 end,
            known = 5308,
            cast = 0,
            cooldown = 6,
            hasteCD = true,
            gcd = "spell",

            spend = -20,
            spendType = "rage",

            startsCombat = true,
            texture = 135358,

            usable = function () return buff.sudden_death.up or buff.stone_heart.up or target.health.pct < ( IsActiveSpell( 280735 ) and 35 or 20 ) end,
            handler = function ()
                if buff.stone_heart.up then removeBuff( "stone_heart" )
                elseif buff.sudden_death.up then removeBuff( "sudden_death" ) end
                removeStack( "whirlwind" )
            end,

            copy = { 280735, 5308 }
        },


        furious_slash = {
            id = 100130,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -4,
            spendType = "rage",

            startsCombat = true,
            texture = 132367,

            talent = "furious_slash",

            recheck = function () return buff.furious_slash.remains - 9, buff.furious_slash.remains - 3, buff.furious_slash.remains, cooldown.recklessness.remains < 3, cooldown.recklessness.remains end,
            handler = function ()
                if buff.furious_slash.stack < 3 then stat.haste = stat.haste + 0.02 end
                addStack( "furious_slash", 15, 1 )
                removeStack( "whirlwind" )
            end,
        },


        heroic_leap = {
            id = 6544,
            cast = 0,
            charges = function () return ( level < 116 and equipped.timeless_stratagem ) and 3 or nil end,
            cooldown = function () return talent.bounding_stride.enabled and 30 or 45 end,
            recharge = function () return talent.bounding_stride.enabled and 30 or 45 end,
            gcd = "spell",

            startsCombat = false,
            texture = 236171,

            usable = function () return target.distance > 10 and ( query_time - max( action.charge.lastCast, action.heroic_leap.lastCast ) > gcd.execute ) end,
            handler = function ()
                setDistance( 5 )
                if talent.bounding_stride.enabled then applyBuff( "bounding_stride" ) end
            end,
        },


        heroic_throw = {
            id = 57755,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = true,
            texture = 132453,

            handler = function ()
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
                removeStack( "whirlwind" )
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
                if azerite.intimidating_presence.enabled then applyDebuff( "target", "intimidating_presence" ) end
            end,
        },


        piercing_howl = {
            id = 12323,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 10,
            spendType = "rage",

            startsCombat = true,
            texture = 136147,

            handler = function ()
                applyDebuff( "target", "piercing_howl" )
            end,
        },


        pummel = {
            id = 6552,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 132938,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        raging_blow = {
            id = 85288,
            cast = 0,
            charges = 2,
            cooldown = function () return ( talent.inner_rage.enabled and 7 or 8 ) * haste end,
            recharge = function () return ( talent.inner_rage.enabled and 7 or 8 ) * haste end,
            gcd = "spell",

            spend = -12,
            spendType = "rage",

            startsCombat = true,
            texture = 589119,

            handler = function ()
                removeBuff( "raging_thirst" )
                if level < 116 and set_bonus.tier_21_4pc == 1 then addStack( "bloody_rage", 10, 1 ) end
                removeStack( "whirlwind" )
            end,
        },


        rallying_cry = {
            id = 97462,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 132351,

            handler = function ()
                applyBuff( "rallying_cry" )
            end,
        },


        rampage = {
            id = 184367,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if talent.carnage.enabled then return 75 end
                if talent.frothing_berserker.enabled then return 95 end
                return 85
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132352,

            handler = function ()
                if not buff.enrage.up then
                    stat.haste = stat.haste + 0.25
                end

                applyBuff( "enrage" )
                if talent.endless_rage.enabled then gain( 6, "rage" ) end

                if level < 116 and set_bonus.tier21_2pc == 1 then applyDebuff( "target", "slaughter" ) end

                if talent.frothing_berserker.enabled then
                    if buff.frothing_berserker.down then stat.haste = stat.haste + 0.05 end
                    applyBuff( "frothing_berserker" )
                end
                removeStack( "whirlwind" )  
            end,
        },


        recklessness = {
            id = 1719,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 458972,

            handler = function ()
                applyBuff( "recklessness" )
                if talent.reckless_abandon.enabled then gain( 100, "rage" ) end
            end,
        },


        siegebreaker = {
            id = 280772,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = -10,
            spendType = "rage",

            startsCombat = true,
            texture = 294382,

            talent = "siegebreaker",

            handler = function ()
                applyDebuff( "target", "siegebreaker" )
                removeStack( "whirlwind" )
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
                removeStack( "whirlwind" )
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


        victory_rush = {
            id = 34428,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132342,

            notalent = "impending_victory",
            buff = "victorious",

            handler = function ()
                removeBuff( "victorious" )
                removeStack( "whirlwind" )
            end,
        },


        whirlwind = {
            id = 190411,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132369,

            range = 7,
            
            usable = function ()
                if settings.check_ww_range and target.outside7 then return false, "target is outside of whirlwind range" end
                return true
            end,

            handler = function ()
                applyBuff( "whirlwind", 20, 2 )

                if talent.meat_cleaver.enabled then
                    gain( 3 + min( 5, active_enemies ) + min( 3, active_enemies ), "rage" )
                else
                    gain( 3 + min( 5, active_enemies ), "rage" )
                end
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

        package = "Fury",
    } )


    spec:RegisterSetting( "check_ww_range", false, {
        name = "Check |T132369:0|t Whirlwind Range",
        desc = "If checked, when your target is outside of |T132369:0|t Whirlwind's range, it will not be recommended.",
        type = "toggle",
        width = 1.5
    } ) 


    spec:RegisterPack( "Fury", 20200210, [[dKukNaqiuvEekInHkzuQu5uQu1RqrnlsPULiHDrXVePggQQogPKLru6zQuyAevY1uPuBtLI6BOiX4uPiNtLswhrLY8iQ4EOI9js0brLkluL0drLQyIIKQUOijyJOsvnsIkvoPiPYkjfZuKK6MevQANOGHksswQij6PszQQexvKeAROsv6RIKs7vv)vfdMKdlSyP6XeMmvDzOntPptKrJQCAGvJIuVMu1SPYTrPDR43igUioUiPy5k9CqtxY1f12rH(orX4rrsNNOQ1JkL5tQSFK(16V8nFu4ZGS8ll)8lRS3WW)T4NFzVX3k5tWVLec9He(TjyXVX9ZR8FljK3rc)F5BqsEf434vvcuULoTeO4L7gbHnneWMDrbiJydBLgcyfP)wpdCvQB((38rHpdYYVS8ZVSYEdd)3IF(16M(wKlEK9Bnal3dvLMQ4UvWdWwGLa)gpG3JZ3)MhHIVXeQI7Nx5PQuBSlGSunmHQ4vvcuULoTeO4L7gbHnneWMDrbiJydBLgcyfunmHQ4(yFZXkpvPf)AtvYYVS8t1q1WeQI7HxmsiuUr1WeQkfuf359ONQsvzww0zOAycvLcQk1dGr3HEQILWiYItrvPPk5oCjabvLQXiHQeHZrv3nKIQge9ONQSKLQatkKcwKQeKPqMADVHQHjuvkOk5EcJONQU6cpclYYsvX4PQu)gsKHQsLKyPQOtyePQRocXx8alSOQIqva2KLWisv2ftnzCeYtvelvTOGWYIJpkazGu1DqalKQwswINtEQctn5WDVHQHjuvkOkUZ7rpvDnQYHuvJhjxuvrOQKffe2Euuf3LQs1gQgMqvPGQ4oVh9uf3lquKvEQkvMH8OQOtyePkiyKCykQyLWIQsT8aRtgW4nunmHQsbvXDEp6PQurisvPUczHMV5aWc(x(gemso8uXkH1F5zqR)Y3crbiZ3Gauc7lg6X9B4eDh6)RF9mi7F5B4eDh6)RFtSGcxq8T7OQE2Anlk07qiCqi0KtOkD6OQE2AnSilzL)qShxwa8h)Ibl0KtOQ7PkD6OQ7OQkC4ug7skEGr60XfIRECn4eDh6PkD6OQkC4ugrStiHgCIUd9ufxu1DuvpBTgC2qcnlYgGbsvYHQKeEQsNoQAdjKQsjvDl(PQ7PkD6OQkC4ug2acdXIgCIUd9ufxu1DuvpBTgC2qcnlYgGbsvYHQKeEQsNoQAdjKQsjvDl(PQ7PQ7)wikaz(2gSjHe(1ZWn(lFlefGmFdzQOix43Wj6o0)x)6zqU(lFdNO7q)F9BIfu4cIVXhv1ZwRP7ieVldltoHQ4IQ6zR1yZlGKHhOlG8mlYgGbsvYHQUX3crbiZ3S5fqYWd0fqEF9mC7)Y3Wj6o0)x)MybfUG4BjlY4rs4nAz2GnjKWVfIcqMV1DHhHfzz)6z4M)lFdNO7q)F9BIfu4cIV1ZwRbNnKqto5BHOaK5B(nKiZzjX(1Zat5V8nCIUd9)1VjwqHli(wpBTgC2qcnEImdvPthvfCdxqHgbX5pWcr3HhPoDhH4nBm6PQusvA9TquaY8TUJq8fpWcRVEgUP)Y3Wj6o0)x)MybfUG4BcEXkHqQIdvj73crbiZ32qcmsNUJiZxpd36V8TquaY8TUJq8fpWcRVHt0DO)V(1ZGw8)x(gor3H()63elOWfeFRchoLre7esObNO7qpvPthvDhvvHdNYWgqyiw0Gt0DONQ4IQ2qcPk5qv3e)u19uLoDu1DuvfoCkJDjfpWiD64cXvpUgCIUd9ufxu1gsivjhQ6w8tv3)TquaY8TnKaJ0P7iY81ZGwA9x(gor3H()63elOWfeFRchoLXMxajdpqxa5zWj6o0)TquaY8nBEbKm8aDbK3xpdAj7F5BHOaK5BmcefzL)SziVVHt0DO)V(1ZGw34V8TquaY8naBcoEWiDyeikYk)3Wj6o0)x)6zql56V8TquaY8nz4bwNmGX)nCIUd9)1V(6BSegrwCQ)YZGw)LVfIcqMVXdxcqCCyK8nCIUd9)1V(6BE0gzx9xEg06V8TquaY8nbVyLWVHt0DO)V(1ZGS)LVfIcqMVLKzzr33Wj6o0)x)6z4g)LVHt0DO)V(nXckCbX3UJQ2a4piJ4ugwcJiloLXdGvmcKQsjvj7TPkUOQna(dYioLHLWiYItzadvLsQsUUnvD)3crbiZ34Hlbiooms(6zqU(lFdNO7q)F9BIfu4cIV1ZwRrkhRheZHypb3WLu8m5eQsNoQ6oQIpQcHqCeOrqgpoq0FCalAjRanSbttwQIlQQIvcltbyXtroEasvYHdvDZ8tv3)TquaY8TesbiZxpd3(V8nCIUd9)1VjwqHli(MGqCEImJzrHEhcHdcHMfzdWaPk5qv34BHOaK5BBWMes4xpd38F5B4eDh6)RFtSGcxq8TE2Anlk07qiCqi0Kt(wikaz(w3ri(dXEkE4bhKv(VEgyk)LVHt0DO)V(nXckCbX34JQ6zR1SOqVdHWbHqtoHQ4IQ4JQ6zR1abOe2xm0JRjN8TquaY8TK8cSYdgPt3fW6RNHB6V8nCIUd9)1VjwqHli(gFuvpBTMff6DieoieAYjufxufFuvpBTgiaLW(IHECn5KVfIcqMVTGKehEaZbMec8RNHB9x(gor3H()63elOWfeFJpQQNTwZIc9oechecn5eQIlQIpQQNTwdeGsyFXqpUMCY3crbiZ3KHSopJiyolcjtmc8RNbT4)V8nCIUd9)1VjwqHli(gFuvpBTMff6DieoieAYjufxufFuvpBTgiaLW(IHECn5KVfIcqMVzjIme9NGB4ck80XG9RNbT06V8nCIUd9)1VjwqHli(gFuvpBTMff6DieoieAYjufxufFuvpBTgiaLW(IHECn5KVfIcqMVTyKagPJ1fSi8RNbTK9V8nCIUd9)1VjwqHli(gFuvpBTMff6DieoieAYjufxufFuvpBTgiaLW(IHECn5eQIlQYtkJGmcCQnk0FSUGfp98oMfzdWaPkouf)FlefGmFtqgbo1gf6pwxWIF9mO1n(lFdNO7q)F9BIfu4cIV1ZwRzrHEhcHhlzfOjN8TquaY8TIhEYtNKh)Xswb(1ZGwY1F5B4eDh6)RFtSGcxq8n(OQE2Anlk07qiCqi0KtOkUOQ7OQcWINIC8aKQsjvP1TUnvPthvvXkHLHhgUINjruuLCOkz5NQU)BHOaK5Bs5y9Gyoe7j4gUKI3xpdAD7)Y3Wj6o0)x)MybfUG4B8rv9S1AwuO3Hq4GqOjN8TquaY8nwKLSYFi2Jlla(JFXGf(1ZGw38F5B4eDh6)RFtSGcxq8n(OkecXrGgbz84ar)XbSOLSc0WgmnzPkUOk(OkecXrGMUJq8hI9u8WdoiR8g2GPjlvPthvjieNNiZyKYX6bXCi2tWnCjfpZISbyGuvkPkTOkD6OQE2Ans5y9Gyoe7j4gUKINjNqv60rvccX5jYmMUJq8hI9u8WdoiR8MfzdWaPk5qvsc)3crbiZ3wuO3Hq4Gq4xpdAXu(lFdNO7q)F9BIfu4cIVbtqN7uXkHf0idpW6KbmEQkLuLwufxufFuvpBTgwmQJWHbJ4AYjFlefGmFtgEG1jdy8F9mO1n9x(gor3H()63crbiZ3cipgJbHNn4gzpcYgUVjwqHli(wbyXtroEasvYHQKLFQsNoQIpQYJ9S1A2GBK9iiB4oESNTwtoHQ0PJQUJQQyLWYuaw8uKtIOo3GFQsou1TPkUOkp2ZwRrqgFwuagXdy0F8ypBTMCcvDpvPthvDhvXhv5XE2AncY4ZIcWiEaJ(Jh7zR1KtOkUOQE2AnSilzL)qShxwa8h)Ibl0KtOkD6OQKfz8ij8gzns5y9Gyoe7j4gUKIhvPthvLSiJhjH3iRzrHEhcHdcHufxu1DufFufcH4iqdlYsw5pe7XLfa)XVyWcnSbttwQIlQIpQcHqCeOrqgpoq0FCalAjRanSbttwQ6EQ6(Vnbl(TaYJXyq4zdUr2JGSH7RNbTU1F5B4eDh6)RFBcw8BBWMagPtWM4av2JhjGuWiXvhCKad(TquaY8TnytaJ0jytCGk7XJeqkyK4QdosGb)6zqw()lFlefGmFldXdOqw43Wj6o0)x)6zqwT(lFdNO7q)F9BIfu4cIV1ZwRzrHEhcHdcHMCY3crbiZ36ocXFS5v(VEgKv2)Y3Wj6o0)x)MybfUG4B9S1AwuO3Hq4GqOjN8TquaY8ToUqC1dgPVEgK9g)LVHt0DO)V(nXckCbX36zR1SOqVdHWbHqJNiZqvCrvESNTwdeGsyFXqpUgprM5BHOaK5BoGeVcEy6SxIfN6RNbzLR)Y3Wj6o0)x)MybfUG4B9S1AwuO3Hq4GqOjN8TquaY8nlyXUJq8F9mi7T)lFdNO7q)F9BIfu4cIV1ZwRzrHEhcHdcHMCY3crbiZ3IrGWAd3reo3xpdYEZ)LVHt0DO)V(nXckCbX36zR1SOqVdHWbHqJNiZqvCrvESNTwdeGsyFXqpUgprMHQ4IQ6zR1GZgsOjN8TquaY8TEiDi2tTaHE4xpdYYu(lFdNO7q)F9BHOaK5BBEoHOaK54aW6BoaSotWIFdcgjhEQyLW6RV(wYIccBpQ)YZGw)LVHt0DO)V(1ZGS)LVHt0DO)V(1ZWn(lFdNO7q)F9RNb56V8TquaY8TEuLdpqEKC9nCIUd9)1VEgU9F5B4eDh6)RFBcw8Bb3G8InGhlzQdXEsiYG73crbiZ3cUb5fBapwYuhI9KqKb3VEgU5)Y3crbiZ3KHSopJiyolcjtmc8B4eDh6)RF9mWu(lFlefGmFJfzjR8hI94YcG)4xmyHFdNO7q)F9RNHB6V8TquaY8nPCSEqmhI9eCdxsX7B4eDh6)RF9mCR)Y3crbiZ3wuO3Hq4Gq43Wj6o0)x)6zql()lFlefGmFlHuaY8nCIUd9)1V(6RVXiUqazEgKLFz5NFTKvU(MmXoGrc(TuhBczl0tvYfvfIcqgQYbGf0q18TKLybo8BmHQ4(5vEQk1g7cilvdtOkEvLaLBPtlbkE5UrqytdbSzxuaYi2WwPHawbvdtOkUp23CSYtvAXV2uLS8ll)ununmHQ4E4fJecLBunmHQsbvXDEp6PQuvMLfDgQgMqvPGQs9ay0DONQyjmIS4uuvAQsUdxcqqvPAmsOkr4Cu1DdPOQbrp6PklzPkWKcPGfPkbzkKPw3BOAycvLcQsUNWi6PQRUWJWISSuvmEQk1VHezOQujjwQk6egrQ6QJq8fpWclQQiufGnzjmIuLDXutghH8ufXsvlkiSS44JcqgivDheWcPQLKL45KNQWutoC3BOAycvLcQI78E0tvxJQCiv14rYfvveQkzrbHThfvXDPQuTHQHjuvkOkUZ7rpvX9cefzLNQsLzipQk6egrQccgjhMIkwjSOQulpW6KbmEdvdtOQuqvCN3JEQkveIuvQRqwOHQHQHjuvQatff5c9uvhTKfPkbHThfv1rjWanuf3jeysbPQHmPGxSS2SJQcrbidKQiJtEdvtikazGMKffe2EuCSUaQNQjefGmqtYIccBpkM5K2siEQMquaYanjlkiS9OyMt6ilXItffGmunmHQAtKa5rkQAdGNQ6zRf9ufSIcsvD0swKQee2EuuvhLadKQIXtvjlMIesvGrIQaqQYtg0q1eIcqgOjzrbHThfZCs3JQC4bYJKlQMquaYanjlkiS9OyMt6mepGcz1EcwKtWniVyd4XsM6qSNeIm4s1eIcqgOjzrbHThfZCsldzDEgrWCwesMyeivtikazGMKffe2EumZjnlYsw5pe7XLfa)XVyWcPAcrbid0KSOGW2JIzoPLYX6bXCi2tWnCjfpQMquaYanjlkiS9OyMt6ff6Dieoies1eIcqgOjzrbHThfZCsNqkazOAOAycvLkWurrUqpvHmIR8uvbyrQQ4HuvikYsvaivfmgax0DOHQjefGmqocEXkHunHOaKbYmN0jzww0r1WeQ6cpaKQaqQILalN8uvrOQKfzeNIQeeIZtKzGuLDjSuvhbJevfcbWJtfoN8uvgIEQYNxWirvSegrwCkdvdtOQquaYazMt6npNquaYCCayP9eSihwcJiloL2alhwcJiloLXdGvmcmL3MQjefGmqM5KMhUeG44WirBGLZDBa8hKrCkdlHrKfNY4bWkgbMszVnxBa8hKrCkdlHrKfNYaMukx3(EQMquaYazMt6esbiJ2alNE2Ans5y9Gyoe7j4gUKINjNOt3D8Hqioc0iiJhhi6poGfTKvGg2GPjlxvSsyzkalEkYXdq5W5M5)EQMquaYazMt6nytcjuBGLJGqCEImJzrHEhcHdcHMfzdWaLZnOAcrbidKzoP7ocXFi2tXdp4GSYRnWYPNTwZIc9oechecn5eQMquaYazMt6K8cSYdgPt3fWsBGLdF9S1AwuO3Hq4GqOjNWfF9S1AGauc7lg6X1KtOAcrbidKzoPxqsIdpG5atcbQnWYHVE2Anlk07qiCqi0Kt4IVE2AnqakH9fd94AYjunHOaKbYmN0YqwNNremNfHKjgbQnWYHVE2Anlk07qiCqi0Kt4IVE2AnqakH9fd94AYjunHOaKbYmN0wIidr)j4gUGcpDmy1gy5WxpBTMff6DieoieAYjCXxpBTgiaLW(IHECn5eQMquaYazMt6fJeWiDSUGfHAdSC4RNTwZIc9oechecn5eU4RNTwdeGsyFXqpUMCcvtikazGmZjTGmcCQnk0FSUGf1gy5WxpBTMff6DieoieAYjCXxpBTgiaLW(IHECn5eU8KYiiJaNAJc9hRlyXtpVJzr2amqo8t1eIcqgiZCsx8WtE6K84pwYkqTbwo9S1AwuO3Hq4XswbAYjunHOaKbYmN0s5y9Gyoe7j4gUKIN2alh(6zR1SOqVdHWbHqtoHR7kalEkYXdWuQ1TUToDvSsyz4HHR4zseLCKL)7PAcrbidKzoPzrwYk)HypUSa4p(fdwO2alh(6zR1SOqVdHWbHqtoHQjefGmqM5KErHEhcHdcHAdSC4dHqCeOrqgpoq0FCalAjRanSbttwU4dHqCeOP7ie)Hypfp8GdYkVHnyAYQtNGqCEImJrkhRheZHypb3WLu8mlYgGbMsT0PRNTwJuowpiMdXEcUHlP4zYj60jieNNiZy6ocXFi2tXdp4GSYBwKnaduoscpvtikazGmZjTm8aRtgW41gy5atqN7uXkHf0idpW6Kbm(uQfx81ZwRHfJ6iCyWiUMCcvtikazGmZjDgIhqHSApblYjG8ymgeE2GBK9iiB40gy5uaw8uKJhGYrw(1PJpp2ZwRzdUr2JGSH74XE2An5eD6URIvcltbyXtrojI6Cd(LZT5YJ9S1AeKXNffGr8ag9hp2ZwRjNCVoD3XNh7zR1iiJplkaJ4bm6pESNTwtoHRE2AnSilzL)qShxwa8h)Ibl0Kt0PlzrgpscVrwJuowpiMdXEcUHlP4PtxYImEKeEJSMff6DieoieY1D8Hqioc0WISKv(dXECzbWF8lgSqdBW0KLl(qiehbAeKXJde9hhWIwYkqdBW0K9(7PAcrbidKzoPZq8akKv7jyroBWMagPtWM4av2JhjGuWiXvhCKads1eIcqgiZCsNH4builKQjefGmqM5KU7ie)XMx51gy50ZwRzrHEhcHdcHMCcvtikazGmZjDhxiU6bJK2alNE2Anlk07qiCqi0KtOAcrbidKzoPDajEf8W0zVeloL2alNE2Anlk07qiCqi04jYmC5XE2AnqakH9fd94A8ezgQMquaYazMtAlyXUJq8AdSC6zR1SOqVdHWbHqtoHQjefGmqM5KogbcRnChr4CAdSC6zR1SOqVdHWbHqtoHQjefGmqM5KUhshI9ulqOhQnWYPNTwZIc9oechecnEImdxESNTwdeGsyFXqpUgprMHRE2An4SHeAYjunHOaKbYmN0BEoHOaK54aWs7jyroqWi5WtfRewununHOaKbAyjmIS4uC4HlbioomsOAOAcrbid0abJKdpvSsyXbcqjSVyOhxQMquaYanqWi5WtfRewmZj9gSjHeQnWY5UE2Anlk07qiCqi0Kt0PRNTwdlYsw5pe7XLfa)XVyWcn5K71P7UkC4ug7skEGr60XfIRECn4eDh61PRchoLre7esObNO7qpx31ZwRbNnKqZISbyGYrs41PBdjmL3I)71PRchoLHnGWqSObNO7qpx31ZwRbNnKqZISbyGYrs41PBdjmL3I)7VNQjefGmqdemso8uXkHfZCsJmvuKlKQjefGmqdemso8uXkHfZCsBZlGKHhOlG80gy5WxpBTMUJq8UmSm5eU6zR1yZlGKHhOlG8mlYgGbkNBq1eIcqgObcgjhEQyLWIzoP7UWJWISSAdSCswKXJKWB0YSbBsiHunHOaKbAGGrYHNkwjSyMtA)gsK5SKy1gy50ZwRbNnKqtoHQjefGmqdemso8uXkHfZCs3DeIV4bwyPnWYPNTwdoBiHgprMrNUGB4ck0iio)bwi6o8i1P7ieVzJrFk1IQjefGmqdemso8uXkHfZCsVHeyKoDhrgTbwocEXkHqoYs1eIcqgObcgjhEQyLWIzoP7ocXx8alSOAcrbid0abJKdpvSsyXmN0BibgPt3rKrBGLtfoCkJi2jKqdor3HED6URchoLHnGWqSObNO7qpxBiHY5M4)ED6URchoLXUKIhyKoDCH4Qhxdor3HEU2qcLZT4)EQMquaYanqWi5WtfRewmZjTnVasgEGUaYtBGLtfoCkJnVasgEGUaYZGt0DONQjefGmqdemso8uXkHfZCsZiquKv(ZMH8OAcrbid0abJKdpvSsyXmN0a2eC8Gr6WiquKvEQMquaYanqWi5WtfRewmZjTm8aRtgW4)gmbfpdmfz)6R)b]] )
end
