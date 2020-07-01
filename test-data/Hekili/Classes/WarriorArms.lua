-- WarriorArms.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'WARRIOR' then
    local spec = Hekili:NewSpecialization( 71 )

    local base_rage_gen, arms_rage_mult = 1.75, 4.000

    spec:RegisterResource( Enum.PowerType.Rage, {
        mainhand = {
            last = function ()
                local swing = state.combat == 0 and state.now or state.swings.mainhand
                local t = state.query_time

                return swing + ( floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed )
            end,

            interval = 'mainhand_speed',

            stop = function () return state.time == 0 or state.swings.mainhand == 0 end,
            value = function ()
                return ( state.talent.war_machine.enabled and 1.1 or 1 ) * base_rage_gen * arms_rage_mult * state.swings.mainhand_speed / state.haste
            end,
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        war_machine = 22624, -- 262231
        sudden_death = 22360, -- 29725
        skullsplitter = 22371, -- 260643

        double_time = 19676, -- 103827
        impending_victory = 22372, -- 202168
        storm_bolt = 22789, -- 107570

        massacre = 22380, -- 281001
        fervor_of_battle = 22489, -- 202316
        rend = 19138, -- 772

        second_wind = 15757, -- 29838
        bounding_stride = 22627, -- 202163
        defensive_stance = 22628, -- 197690

        collateral_damage = 22392, -- 268243
        warbreaker = 22391, -- 262161
        cleave = 22362, -- 845

        in_for_the_kill = 22394, -- 248621
        avatar = 22397, -- 107574
        deadly_calm = 22399, -- 262228

        anger_management = 21204, -- 152278
        dreadnaught = 22407, -- 262150
        ravager = 21667, -- 152277
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3589, -- 208683
        relentless = 3588, -- 196029
        adaptation = 3587, -- 214027

        duel = 34, -- 236273
        disarm = 3534, -- 236077
        sharpen_blade = 33, -- 198817
        war_banner = 32, -- 236320
        spell_reflection = 3521, -- 216890
        death_sentence = 3522, -- 198500
        master_and_commander = 28, -- 235941
        shadow_of_the_colossus = 29, -- 198807
        storm_of_destruction = 31, -- 236308
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
        bladestorm = {
            id = 227847,
            duration = 6,
            max_stack = 1,
        },
        bounding_stride = {
            id = 202164,
            duration = 3,
            max_stack = 1,
        },
        colossus_smash = {
            id = 208086,
            duration = 10,
            max_stack = 1,
        },
        deadly_calm = {
            id = 262228,
            duration = 6,
            max_stack = 1,
        },
        deep_wounds = {
            id = 262115,
            duration = 6,
            max_stack = 1,
        },
        defensive_stance = {
            id = 197690,
            duration = 3600,
            max_stack = 1,
        },
        die_by_the_sword = {
            id = 118038,
            duration = 8,
            max_stack = 1,
        },
        hamstring = {
            id = 1715,
            duration = 15,
            max_stack = 1,
        },
        in_for_the_kill = {
            id = 248622,
            duration = 10,
            max_stack = 1,
        },
        intimidating_shout = {
            id = 5246,
            duration = 8,
            max_stack = 1,
        },
        mortal_wounds = {
            id = 115804,
            duration = 10,
            max_stack = 1,
        },
        overpower = {
            id = 7384,
            duration = 15,
            max_stack = 2,
        },
        rallying_cry = {
            id = 97463,
            duration = 10,
            max_stack = 1,
        },
        --[[ ravager = {
            id = 152277,
        }, ]]
        rend = {
            id = 772,
            duration = 12,
            tick_time = 3,
            max_stack = 1,
        },
        --[[ seasoned_soldier = {
            id = 279423,
        }, ]]
        sign_of_the_emissary = {
            id = 225788,
            duration = 3600,
            max_stack = 1,
        },
        stone_heart = {
            id = 225947,
            duration = 10,
        },
        sudden_death = {
            id = 52437,
            duration = 10,
            max_stack = 1,
        },
        sweeping_strikes = {
            id = 260708,
            duration = 12,
            max_stack = 1,
        },
        --[[ tactician = {
            id = 184783,
        }, ]]
        taunt = {
            id = 355,
            duration = 3,
            max_stack = 1,
        },
        victorious = {
            id = 32216,
            duration = 20,
            max_stack = 1,
        },

        -- Azerite Powers
        crushing_assault = {
            id = 278826,
            duration = 10,
            max_stack = 1
        },        

        gathering_storm = {
            id = 273415,
            duration = 6,
            max_stack = 5,
        },

        intimidating_presence = {
            id = 288644,
            duration = 12,
            max_stack = 1,
        },

        striking_the_anvil = {
            id = 288455,
            duration = 15,
            max_stack = 1,
        },

        test_of_might = {
            id = 275540,
            duration = 12,
            max_stack = 1
        }
    } )


    local rageSpent = 0

    spec:RegisterHook( "spend", function( amt, resource )
        if talent.anger_management.enabled and resource == "rage" then
            rageSpent = rageSpent + amt
            local reduction = floor( rageSpent / 20 )
            rageSpent = rageSpent % 20

            if reduction > 0 then
                cooldown.colossus_smash.expires = cooldown.colossus_smash.expires - reduction
                cooldown.bladestorm.expires = cooldown.bladestorm.expires - reduction
                cooldown.warbreaker.expires = cooldown.warbreaker.expires - reduction
            end
        end
    end )


    local last_cs_target = nil

    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function()
        local _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID and subtype == "SPELL_CAST_SUCCESS" and ( spellName == class.abilities.colossus_smash.name or spellName == class.abilities.warbreaker.name ) then
            last_cs_target = destGUID
        end
    end )


    local cs_actual

    spec:RegisterHook( "reset_precast", function ()
        rageSpent = 0
        if buff.bladestorm.up then
            setCooldown( "global_cooldown", max( cooldown.global_cooldown.remains, buff.bladestorm.remains ) )
            if buff.gathering_storm.up then applyBuff( "gathering_storm", buff.bladestorm.remains + 6, 4 ) end
        end

        if not cs_actual then cs_actual = cooldown.colossus_smash end

        if talent.warbreaker.enabled and cs_actual then
            cooldown.colossus_smash = cooldown.warbreaker
        else
            cooldown.colossus_smash = cs_actual
        end


        if prev_gcd[1].colossus_smash and time - action.colossus_smash.lastCast < 1 and last_cs_target == target.unit and debuff.colossus_smash.down then
            -- Apply Colossus Smash early because its application is delayed for some reason.
            applyDebuff( "target", "colossus_smash", 10 )
        elseif prev_gcd[1].warbreaker and time - action.warbreaker.lastCast < 1 and last_cs_target == target.unit and debuff.colossus_smash.down then
            applyDebuff( "target", "colossus_smash", 10 )
        end
    end )


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
        spec:RegisterAura( "war_veteran", {
            id = 253382,
            duration = 8
         } ) -- arms 2pc.
        spec:RegisterAura( "weighted_blade", { 
            id = 253383,  
            duration = 1,
            max_stack = 3
        } ) -- arms 4pc.

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



    -- Abilities
    spec:RegisterAbilities( {
        avatar = {
            id = 107574,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            spend = -20,
            spendType = "rage",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 613534,

            talent = "avatar",

            handler = function ()
                applyBuff( "avatar" )
            end,
        },


        battle_shout = {
            id = 6673,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = false,
            texture = 132333,

            nobuff = "battle_shout",
            essential = true,

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

            startsCombat = true,
            texture = 136009,

            handler = function ()
                applyBuff( "berserker_rage" )
                if level < 116 and equipped.ceannar_charger then gain( 8, "rage" ) end
            end,
        },


        bladestorm = {
            id = 227847,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 236303,

            notalent = "ravager",
            range = 8,

            handler = function ()
                applyBuff( "bladestorm" )
                setCooldown( "global_cooldown", 4 * haste )
                if level < 116 and equipped.the_great_storms_eye then addStack( "tornados_eye", 6, 1 ) end

                if azerite.gathering_storm.enabled then
                    applyBuff( "gathering_storm", 6 + ( 4 * haste ), 4 )
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
                setDistance( 5 )
            end,
        },


        cleave = {
            id = 845,
            cast = 0,
            cooldown = 9,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 20
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132338,

            talent = "cleave",

            handler = function ()
                if active_enemies >= 3 then applyDebuff( "target", "deep_wounds" ) end
                if talent.collateral_damage.enabled then gain( 4, "rage" ) end
            end,
        },


        colossus_smash = {
            id = 167105,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 464973,

            notalent = "warbreaker",

            handler = function ()
                applyDebuff( "target", "colossus_smash" )

                if level < 116 then
                    if set_bonus.tier21_2pc == 1 then applyBuff( "war_veteran" ) end
                    if set_bonus.tier20_2pc == 1 then
                        if talent.ravager.enabled then setCooldown( "ravager", max( 0, cooldown.ravager.remains - 2 ) )
                        else setCooldown( "bladestorm", max( 0, cooldown.bladestorm.remains - 3 ) ) end
                    end
                end

                if talent.in_for_the_kill.enabled then
                    applyBuff( "in_for_the_kill" )
                    stat.haste = state.haste + ( target.health.pct < 20 and 0.2 or 0.1 )
                end
            end,
        },


        deadly_calm = {
            id = 262228,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 298660,

            handler = function ()
                applyBuff( "deadly_calm" )
            end,
        },


        defensive_stance = {
            id = 212520,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = false,
            texture = 132349,

            talent = "defensive_stance",
            toggle = "defensives",

            handler = function ()
                if buff.defensive_stance.up then removeBuff( "defensive_stance" )
                else applyBuff( "defensive_stance" ) end
            end,
        },


        die_by_the_sword = {
            id = 118038,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            startsCombat = false,
            texture = 132336,

            toggle = "defensives",

            handler = function ()
                applyBuff( "die_by_the_sword" )
            end,
        },


        execute = {
            id = function () return talent.massacre.enabled and 281001 or 163201 end,
            known = 163201,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.sudden_death.up then return 0 end
                if buff.stone_heart.up then return 0 end
                if buff.deadly_calm.up then return 0 end
                return 20
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 135358,

            usable = function () return buff.sudden_death.up or buff.stone_heart.up or target.health.pct < ( talent.massacre.enabled and 35 or 20 ) end,
            handler = function ()
                if not buff.sudden_death.up and not buff.stone_heart.up then
                    local overflow = min( rage.current, 20 )
                    spend( overflow, "rage" )
                    gain( 0.2 * ( 20 + overflow ), "rage" )
                end
                if buff.stone_heart.up then removeBuff( "stone_heart" )
                else removeBuff( "sudden_death" ) end

                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 4, "rage" ) end
            end,

            copy = { 163201, 281001, 281000 }
        },


        hamstring = {
            id = 1715,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 10
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132316,

            handler = function ()
                applyDebuff( "target", "hamstring" )
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 2, "rage" ) end
            end,
        },


        heroic_leap = {
            id = 6544,
            cast = 0,
            charges = function () return ( level < 116 and equipped.timeless_strategem ) and 3 or nil end,
            cooldown = function () return talent.bounding_stride.enabled and 30 or 45 end,
            recharge = function () return talent.bounding_stride.enabled and 30 or 45 end,
            gcd = "spell",

            startsCombat = false,
            texture = 236171,

            usable = function () return ( equipped.weight_of_the_earth or target.distance > 10 ) and ( query_time - max( action.charge.lastCast, action.heroic_leap.lastCast ) > gcd.execute * 2 ) end,
            handler = function ()
                setDistance( 5 )
                if talent.bounding_stride.enabled then applyBuff( "bounding_stride" ) end
                if level < 116 and equipped.weight_of_the_earth then
                    applyDebuff( "target", "colossus_smash" )
                    active_dot.colossus_smash = max( 1, active_enemies )
                end
            end,
        },


        heroic_throw = {
            id = 57755,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = true,
            texture = 132453,

            usable = function () return target.distance > 10 end,
            handler = function ()
            end,
        },


        impending_victory = {
            id = 202168,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 10
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 589768,

            talent = "impending_victory",

            handler = function ()
                removeBuff( "victorious" )
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 2, "rage" ) end
            end,
        },


        intimidating_shout = {
            id = 5246,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            startsCombat = true,
            texture = 132154,

            handler = function ()
                applyBuff( "intimidating_shout" )
                if azerite.intimidating_presence.enabled then applyDebuff( "target", "intimidating_presence" ) end
            end,
        },


        mortal_strike = {
            id = 12294,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 30 - ( ( level < 116 and equipped.archavons_heavy_hand ) and 8 or 0 )
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132355,

            handler = function ()
                applyDebuff( "target", "mortal_wounds" )
                applyDebuff( "target", "deep_wounds" )
                removeBuff( "overpower" )
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 6, "rage" ) end
                if level < 116 and set_bonus.tier21_4pc == 1 then addStack( "weighted_blade", 12, 1 ) end
            end,
        },


        overpower = {
            id = 7384,
            cast = 0,
            charges = function () return talent.dreadnaught.enabled and 2 or nil end,
            cooldown = 12,
            recharge = 12,
            gcd = "spell",

            startsCombat = true,
            texture = 132223,

            handler = function ()
                if talent.dreadnaught.enabled then
                    addStack( "overpower", 15, 1 )
                else
                    applyBuff( "overpower" )
                end

                if buff.striking_the_anvil.up then
                    removeBuff( "striking_the_anvil" )
                    gainChargeTime( "mortal_strike", 1.5 )
                end
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

            startsCombat = false,
            texture = 132351,

            toggle = "defensives",

            handler = function ()
                applyBuff( "rallying_cry" )
            end,
        },


        ravager = {
            id = 152277,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 60 end,
            gcd = "spell",

            spend = -7,
            spendType = "rage",

            startsCombat = true,
            texture = 970854,

            talents = "ravager",
            toggle = "cooldowns",

            handler = function ()
                if ( level < 116 and equipped.the_great_storms_eye ) then addStack( "tornados_eye", 6, 1 ) end
                -- need to plan out rage gen.
            end,
        },


        rend = {
            id = 772,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 30
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132155,

            talent = "rend",

            handler = function ()
                applyDebuff( "target", "rend" )
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 6, "rage" ) end
            end,
        },


        skullsplitter = {
            id = 260643,
            cast = 0,
            cooldown = 21,
            hasteCD = true,
            gcd = "spell",

            spend = -20,
            spendType = "rage",

            startsCombat = true,
            texture = 2065621,

            talent = "skullsplitter",

            handler = function ()
            end,
        },


        slam = {
            id = 1464,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                if buff.crushing_assault.up then return 0 end
                return 20
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132340,

            handler = function ()
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 4, "rage" ) end
                removeBuff( "crushing_assault" )
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


        sweeping_strikes = {
            id = 260708,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 132306,

            handler = function ()
                applyBuff( "sweeping_strikes" )
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
            end,
        },


        warbreaker = {
            id = 262161,
            cast = 0,
            cooldown = 45,
            velocity = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 2065633,

            talent = "warbreaker",

            handler = function ()                
                if talent.in_for_the_kill.enabled then
                    if buff.in_for_the_kill.down then
                        stat.haste = stat.haste + ( target.health.pct < 0.2 and 0.2 or 0.1 )
                    end
                    applyBuff( "in_for_the_kill" )
                end

                if level < 116 then
                    if set_bonus.tier21_2pc == 1 then applyBuff( "war_veteran" ) end
                    if set_bonus.tier20_2pc == 1 then
                        if talent.ravager.enabled then setCooldown( "ravager", max( 0, cooldown.ravager.remains - 2 ) )
                        else setCooldown( "bladestorm", max( 0, cooldown.bladestorm.remains - 3 ) ) end
                    end
                end

                applyDebuff( "target", "colossus_smash" )
            end,
        },


        whirlwind = {
            id = 1680,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.deadly_calm.up then return 0 end
                return 30
            end,
            spendType = "rage",

            startsCombat = true,
            texture = 132369,

            handler = function ()
                if talent.collateral_damage.enabled and active_enemies > 1 then gain( 6, "rage" ) end
                if talent.fervor_of_battle.enabled and buff.crushing_assault.up then removeBuff( "crushing_assault" ) end
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageDots = false,
        damageExpiration = 8,

        potion = "potion_of_unbridled_fury",

        package = "Arms",
    } )


    spec:RegisterPack( "Arms", 20200601, [[dyuDzbqiqvpIQq2ei9jQQuvJcuCkq0QaHOELkWSab3cvIAxa)IQKHrv0XqLAzuv8mQQyAGq6AufSnQc13aHY4OQsohiewhvvQmpqL7jfTpujDqujYcLc9qQQuYfbHkDsqOQvckntQQuQDsvvdLQkflfeI0trvtLQuxLQkvzRGqfFfeIyVu6VKAWeoSWIvPhtLjt0LH2mfFwfnAP0Prz1QG61uvA2KCBrTBK(TIHlvwUQEUstxY1fz7sbFhvmEujCEvO1RcY8LQ2pITCB92YlJcT(7JN(4PNESNCd80V8KBpHiS81Xo0Y3foFJt0YtJmA55sFET8DXr1esR3w(DsVdT8Tv1T(DE51jRAtxGBYETSCsffBOUpmLxll78YYFtmvbXtTxlVmk06VpE6JNE6XEYnWt)YtU90dw(ivTZB55z5Kkk2q9B9HPS8TmPeP2RLxIRZY7rebx6Zlrars8pBEcSEer0wv3635LxNSQnDbUj71YYjvuSH6(WuETSSZlcSEeraBIIeb3qGi8XtF8KalbwpIi8B1g0tC97iW6rebxMi4ssjkjc)MuoJkabwpIi4YebxskrjraXH5Q5pseqKM2wVG4ZDivYONebehMRM)iGaRhreCzIGljLOKiAmQsHebF7KkIOgIO7r3KVrreCj)g)2acSEerWLjciUCb6sfBO473Fjc)MhDSLnuIGTeHevyHsabwpIi4Yebxskrjr43BrIaIVW8cS8k2wR1Bl)YONkuxXFIL1BR)CB92YJ04QqPTrlV7zf(SWY)XjseWreEWJjcOeXnzmajgs1rTluzGC4qjcOeXnzmGmMN)OEmAvYXKA5JrEbYHd1YhUInul)6BsP2ofRk8TL1FFSEB5rACvO02OL39ScFwy5HNiUjJbiXqQoQDHkdsDebuIagIWnJsoCOa3OMDtREZX2cEmhm6seWre(qe99ebmerfkKwaoXFFm8fFasJRcLebuIWnJsoCOaoXFFm8fFWJ5GrxIaoIWhIasIaslF4k2qT8F0qCIVTS(7hR3w(WvSHA5DJA2nT6nhBRLhPXvHsBJ2Y6pe16TLpCfBOwEoXFFm8fFlpsJRcL2gTL1Fpy92YhUInulVedP6O2fQSLhPXvHsBJ2Y6VhB92YJ04QqPTrlV7zf(SWYFtgdytsjs1smQwWJHRS8HRyd1YJCb6sfAlR)qmR3wEKgxfkTnA5DpRWNfwE3mk5WHcYZxHsV1Z8fbpMdgDjcOeHeVjJb4g1SBA1Bo2wGC4qjcOebmeb8erfkKwajgs1rTluzasJRcLerFprCtgdqIHuDu7cvgihouIasIakradradriXBYyaUrn7Mw9MJTfK6icOeb8erCi8zfckCl9y0z2zBbqACvOKiGKi67jIBYyafULEm6m7STaPoIasIakrCtgdiJ55pQhJwLCmPw(yKxGC4qjcOeXhNirahrar90YhUInul)vfsCR5Z2Y6VFz92YJ04QqPTrlV7zf(SWYddrapruHcPf4rQeG04QqjraLiKtbKi2P5mjQCbpMdgDjcOeXhNirahraX8KiGse3KXaYyE(J6XOvjhtQLpg5fihouIakriXBYyaUrn7Mw9MJTfihouIasIOVNiGHiQqH0c8ivcqACvOKiGseYPase70CMevUGhZbJUebuIqof4rQe8yoy0Li4krC6KebuI4JtKiGJiGyEseqjIBYyazmp)r9y0QKJj1YhJ8cKdhkraLiK4nzma3OMDtREZX2cKdhkraPLpCfBOw(Pb87go4BlR)qewVT8HRyd1YNNVcLERN5lA5rACvO02OTS(ZTNwVT8inUkuAB0Y7EwHplS8pMdgDjc4AseY0hfBOebezIWtGFS8HRyd1Y)ivAlR)CZT1BlpsJRcL2gT8UNv4Zcl)2HkLUI)eRfWPL9komQKi4kr4JLpCfBOwENcJgqBz9NBFSEB5rACvO02OL39ScFwy5HHiGHiGHiUjJbKX88h1JrRsoMulFmYli1reqse99ebmeHeVjJb4g1SBA1Bo2wqQJiGKi67jcyiIBYyasmKQJAxOYGuhrajrajraLiQqH0cyWVH51JrFJQuiaPXvHsIasIOVNiGHiUjJbKX88h1JrRsoMulFmYli1reqjcjEtgdWnQz30Q3CSTGuhraLiGNiQqH0cyWVH51JrFJQuiaPXvHsIaslF4k2qT8CAzVIdJkTL1FU9J1BlpsJRcL2gT8UNv4Zclp8erfkKwad(nmVEm6BuLcbinUkuseqjcyiIBYyazmp)r9y0QKJj1YhJ8csDerFpriXBYyaUrn7Mw9MJTfK6iciT8HRyd1YVQiBlR)CdrTEB5dxXgQLFAa)UHd(wEKgxfkTnAlR)C7bR3wEKgxfkTnA5DpRWNfw(kuiTag8ByE9y03OkfcqACvOKiGseWqe3KXakCl9y0z2zBbsDerFpriXBYyaUrn7Mw9MJTfihouIakrCtgdOWT0JrNzNTfqoCOebuI4JtKi4kr4XEseqA5dxXgQLNtl7vCyuPTS(ZThB92YJ04QqPTrlV7zf(SWYdpruHcPfWGFdZRhJ(gvPqasJRcLw(WvSHA5xvKTL1FUHywVT8HRyd1Y3aZvZFu)PT1YJ04QqPTrBz9NB)Y6TLpCfBOwEwUdPsg9u3aZvZF0YJ04QqPTrBzllVenrsvwVT(ZT1BlF4k2qT8U24prlpsJRcL2gTL1FFSEB5dxXgQLVlLZOYYJ04QqPTrBz93pwVT8inUkuAB0Y7EwHplS8Wqev8NybAXqvTGoxreWre(Wnr03tevOqAbYXUH7rasJRcLebuIOI)elqlgQQf05kIaoIWpEmrajraLiGHiUjJbKX88h1JrRsoMulFmYli1re99eXnzmGZu8swq1Jrhhc)PAbPoIasIOVNiGNiWDrQdbzmp)r9y0QKJj1YhJ8cYXHNNiGseWte4Ui1Ha3qLiDrPwXmOzEhcYXHNNiGseWqev8NybAXqvTGoxreWre(Wnr03tevOqAbYXUH7rasJRcLebuIOI)elqlgQQf05kIaoIWpEmrajraLiK4nzma3OMDtREZX2csDw(WvSHA57MInuBz9hIA92YJ04QqPTrlV7zf(SWYFtgdiJ55pQhJwLCmPw(yKxqQJiGse3KXakCl9y0z2zBbsDerFprCtgd4mfVKfu9y0XHWFQwqQJiGses8MmgGBuZUPvV5yBbPoIOVNiGHiGNiWDrQdbzmp)r9y0QKJj1YhJ8cYXHNNiGseWte4Ui1Ha3qLiDrPwXmOzEhcYXHNNiGses8MmgGBuZUPvV5yBbPoIaslF4k2qT8x1msTj9hTL1Fpy92YJ04QqPTrlV7zf(SWYFtgdiJ55pQhJwLCmPw(yKxqQJiGse3KXakCl9y0z2zBbsDerFprCtgd4mfVKfu9y0XHWFQwqQJiGses8MmgGBuZUPvV5yBbPoIOVNiUjJbSiwTm6P(JteK6iI(EIagIaEIa3fPoeKX88h1JrRsoMulFmYlihhEEIakraprG7IuhcCdvI0fLAfZGM5DiihhEEIakraprG7IuhcUQzK6XORwuJumFeKJdppraLiK4nzma3OMDtREZX2csDebKw(WvSHA5V4V47lJEAlR)ES1BlpsJRcL2gT8UNv4Zcl)nzmGmMN)OEmAvYXKA5JrEbYHdLiGseFCIebCeHh8KiGseWqeUzuYHdfKNVcLERN5lcEmhm6seCLioDsIOVNiGHiQ4pXc0IHQAbDUIiGJi8XtIOVNiQqH0cKJDd3JaKgxfkjcOerf)jwGwmuvlOZvebCeHF8arajraPLpCfBOw(4Dbf118pslBz9hIz92YJ04QqPTrlV7zf(SWYlXBYyaUrn7Mw9MJTfihoulF4k2qT8k2zBT6dNKNzKw2Y6VFz92YJ04QqPTrlV7zf(SWYFtgdiJ55pQhJwLCmPw(yKxqQJiGse3KXakCl9y0z2zBbsDerFprCtgd4mfVKfu9y0XHWFQwqQJiGses8MmgGBuZUPvV5yBbPoIOVNiGHiGNiWDrQdbzmp)r9y0QKJj1YhJ8cYXHNNiGseWte4Ui1Ha3qLiDrPwXmOzEhcYXHNNiGses8MmgGBuZUPvV5yBbPoIaslF4k2qT8g2Jx1msBz9hIW6TLhPXvHsBJwE3Zk8zHL)MmgqgZZFupgTk5ysT8XiVGuhraLiUjJbu4w6XOZSZ2cK6iI(EI4MmgWzkEjlO6XOJdH)uTGuhraLiK4nzma3OMDtREZX2csDerFpradraprG7IuhcYyE(J6XOvjhtQLpg5fKJdppraLiGNiWDrQdbUHkr6IsTIzqZ8oeKJdppraLiK4nzma3OMDtREZX2csDebKw(WvSHA5dQd36dL2fkLTS(ZTNwVT8inUkuAB0Y7EwHplS8s8MmgGBuZUPvV5yBbYHdLiGse3KXaYyE(J6XOvjhtQLpg5fihouIakr4MrjhouqE(ku6TEMVi4XCWORLpCfBOw(BCQhJUEMZ31ww)5MBR3wEKgxfkTnA5dxXgQLp22gckU6po08A38HYY7EwHplS8Wtes8MmgWhhAETB(qPL4nzmGuhr03teWqeWqev8NybAXqvTGoxreWre(4jGBIOVNiQqH0cKJDd3JaKgxfkjcOerf)jwGwmuvlOZvebCeHF8aGBIasIakradrCtgdiJ55pQhJwLCmPw(yKxqQJiGseUzuYHdfKX88h1JrRsoMulFmYl4XCWOlrahrWTNEmr03te3KXaotXlzbvpgDCi8NQfK6icOeHeVjJb4g1SBA1Bo2wqQJiGKiGKi67jcyiIk(tSaTyOQwqNRic4ic)4jGBIakriXBYyaUHktUI1aQzuF1s8MmgqQJiGseWte4Ui1HGmMN)OEmAvYXKA5JrEb54WZteqjc4jcCxK6qGBOsKUOuRyg0mVdb54WZteqse99ebmeb8eHeVjJb4gQm5kwdOMr9vlXBYyaPoIakraprG7IuhcYyE(J6XOvjhtQLpg5fKJdppraLiGNiWDrQdbUHkr6IsTIzqZ8oeKJdppraLiK4nzma3OMDtREZX2csDebKwEAKrlFSTneuC1FCO51U5dLTS(ZTpwVT8inUkuAB0YhUInulFCOTn(y1MHw6XO7go4B5DpRWNfw(ILrDnAjdjc4iciMNebuIagIWnJsoCOa3OMDtREZX2cEmhm6seWreC7dr03teWqevOqAb4e)9XWx8binUkuseqjc3mk5WHc4e)9XWx8bpMdgDjc4icU9HiGKiGKi67jc4jcjEtgdWnQz30Q3CSTGuhraLiGNiUjJbu4w6XOZSZ2cK6icOeb8eXnzmGmMN)OEmAvYXKA5JrEbPoIakruSmQRrlzirWvIGBp4PLNgz0YhhABJpwTzOLEm6UHd(2Y6p3(X6TLhPXvHsBJwE3Zk8zHL3nJsoCOa3OMDtREZX2cEmhm6seWre(fr03teWqevOqAb4e)9XWx8binUkuseqjc3mk5WHc4e)9XWx8bpMdgDjc4ic)IiG0YhUInulF0quXBlR)CdrTEB5rACvO02OL39ScFwy5DZOKdhkWnQz30Q3CSTGhZbJUebCeHFre99ebmerfkKwaoXFFm8fFasJRcLebuIWnJsoCOaoXFFm8fFWJ5GrxIaoIWViciT8HRyd1YNwuZkmV2Y6p3EW6TLhPXvHsBJwE3Zk8zHLF7qLsxXFI1c40YEfhgvseCLi4MiGseWqeUzuYHdfCvHe3A(m4XCWOlrWvIGBpjI(EIWnJsoCOa3OMDtREZX2cEmhm6seCLi8lIOVNiIdHpRqqHBPhJoZoBlasJRcLebKw(WvSHA5xoi2XON6TEMV4AlR)C7XwVT8inUkuAB0Y7EwHplS8Wqe3KXakCl9y0z2zBbsDerFpradriXBYyaUrn7Mw9MJTfK6icOeb8erCi8zfckCl9y0z2zBbqACvOKiGKiGKiGseWqeflJ6A0sgseCLiGi8Ki67jcyiIk(tSaTyOQwqNRic4icF8Ki67jIkuiTa5y3W9iaPXvHsIakruXFIfOfdv1c6Cfrahr4hpqeqseqA5dxXgQL)QMrQhJUArnsX8rBz9NBiM1BlpsJRcL2gT8UNv4Zclp8eHeVjJb4g1SBA1Bo2wqQJiGseWte3KXakCl9y0z2zBbsDw(WvSHA57spZCKrp1xvSLTS(ZTFz92YJ04QqPTrlV7zf(SWYdpriXBYyaUrn7Mw9MJTfK6icOeb8eXnzmGc3spgDMD2wGuNLpCfBOw(N11PqnJQ3UWH2Y6p3qewVT8inUkuAB0Y7EwHplS8Wtes8MmgGBuZUPvV5yBbPoIakraprCtgdOWT0JrNzNTfi1z5dxXgQLNZ8kzdiJQFChAqDOTS(7JNwVT8inUkuAB0Y7EwHplS8Wtes8MmgGBuZUPvV5yBbPoIakraprCtgdOWT0JrNzNTfi1z5dxXgQL3mU0IsDCi8zfQVyKTL1FF426TLhPXvHsBJwE3Zk8zHLhEIqI3KXaCJA2nT6nhBli1reqjc4jIBYyafULEm6m7STaPolF4k2qT8pgDm6P2OImU2Y6Vp(y92YJ04QqPTrlV7zf(SWYdpriXBYyaUrn7Mw9MJTfK6icOeb8eXnzmGc3spgDMD2wGuhraLiKtbCd1H06JcLAJkYO(MEk4XCWOlr0Ki80YhUInulVBOoKwFuOuBurgTL1FF8J1BlpsJRcL2gT8UNv4Zcl)nzmGhD(QWD1M5Dii1z5dxXgQLVArDIENevQnZ7qBz93hiQ1BlpsJRcL2gT8UNv4Zclp8erfkKwaoXFFm8fFasJRcLebuIWnJsoCOa3OMDtREZX2cEmhm6seWreEGiGseWqeflJ6A0sgseCLi8HBpjI(EIagIOI)elqlgQQf05kIaoIWhpjI(EIOcfslqo2nCpcqACvOKiGsev8NybAXqvTGoxreWre(XdebKerFpruSmQRrlzirahr4hUjciT8HRyd1YFMIxYcQEm64q4pvRTS(7JhSEB5rACvO02OL39ScFwy5RqH0cWj(7JHV4dqACvOKiGseUzuYHdfWj(7JHV4dEmhm6seWreEGiGseWqeflJ6A0sgseCLi8HBpjI(EIagIOI)elqlgQQf05kIaoIWhpjI(EIOcfslqo2nCpcqACvOKiGsev8NybAXqvTGoxreWre(XdebKerFpruSmQRrlzirahr4hUjciT8HRyd1YFMIxYcQEm64q4pvRTS(7JhB92YJ04QqPTrlV7zf(SWYdpruHcPfGt83hdFXhG04QqjraLiCZOKdhkWnQz30Q3CSTGhZbJUebCeb3ebuIagIOyzuxJwYqIGReb3EWtIOVNiGHiQ4pXc0IHQAbDUIiGJi8XtIOVNiQqH0cKJDd3JaKgxfkjcOerf)jwGwmuvlOZvebCeHF8arajraPLpCfBOw(mMN)OEmAvYXKA5JrETL1FFGywVT8inUkuAB0Y7EwHplS8vOqAb4e)9XWx8binUkuseqjc3mk5WHc4e)9XWx8bpMdgDjc4icUjcOebmerXYOUgTKHebxjcU9GNerFpradruXFIfOfdv1c6Cfrahr4JNerFpruHcPfih7gUhbinUkuseqjIk(tSaTyOQwqNRic4ic)4bIasIaslF4k2qT8zmp)r9y0QKJj1YhJ8AlR)(4xwVT8inUkuAB0Y7EwHplS8BhQu6k(tSwaNw2R4WOsIGRebe1YhUInul)NO6WvSHQvSTS8k2wAAKrlVH1aQR4pXYww)9bIW6TLhPXvHsBJwE3Zk8zHLhgIOcfslqo2nCpcqACvOKiGsev8NybAXqvTGoxreWre(XdebKerFpruXFIfOfdv1c6Cfrahr4JNw(WvSHA5)evhUInuTITLLxX2stJmA5rUaDPcTL1F)4P1BlpsJRcL2gT8HRyd1Y)jQoCfBOAfBllVITLMgz0YVm6Pc1v8NyzlBz57E0n5BuwVT(ZT1BlF4k2qT83OkfQ32jvwEKgxfkTnAlR)(y92YJ04QqPTrlpnYOLpo02gFSAZql9y0Ddh8T8HRyd1YhhABJpwTzOLEm6UHd(2Y6VFSEB5rACvO02OL39ScFwy5RqH0cyWVH51JrFJQuiaPXvHsIOVNiQqH0cKJDd3JaKgxfkjcOerXYOUgTKHebxjcU9GNerFpruHcPf4rQeG04QqjraLikwg11OLmKi4krWTpEA5dxXgQLpJ55pQhJwLCmPw(yKxBz9hIA92YJ04QqPTrlV7zf(SWYxHcPfWGFdZRhJ(gvPqasJRcLerFpruHcPfih7gUhbinUkuseqjIILrDnAjdjcUse(WTNerFpruHcPf4rQeG04QqjraLiGHikwg11OLmKi4kr4d3Ese99erXYOUgTKHebCeb3qupqeqA5dxXgQL)mfVKfu9y0XHWFQwBz93dwVT8HRyd1Y3nfBOwEKgxfkTnAlBz5rUaDPcTEB9NBR3wEKgxfkTnA5DpRWNfw(porIaoIWd(qeqjIBYyasmKQJAxOYa5WHseqjIBYyazmp)r9y0QKJj1YhJ8cKdhQLpCfBOw(13KsTDkwv4BlR)(y92YJ04QqPTrlV7zf(SWYdprCtgdqIHuDu7cvgK6icOebmeHBgLC4qbUrn7Mw9MJTf8yoy0LiGJi8Hi67jcyiIkuiTaCI)(y4l(aKgxfkjcOeHBgLC4qbCI)(y4l(GhZbJUebCeHpebKebKw(WvSHA5)OH4eFBz93pwVT8inUkuAB0Y7EwHplS8Wte4Ui1HGmMN)OEmAvYXKA5JrEb54WZte99ebmeXnzmGmMN)OEmAvYXKA5JrEbPoIOVNiCZOKdhkiJ55pQhJwLCmPw(yKxWJ5GrxIGReb3EseqA5dxXgQL3nQz30Q3CST2Y6pe16TLhPXvHsBJwE3Zk8zHLhEIa3fPoeKX88h1JrRsoMulFmYlihhEEIOVNiGHiUjJbKX88h1JrRsoMulFmYli1re99eHBgLC4qbzmp)r9y0QKJj1YhJ8cEmhm6seCLi42tIaslF4k2qT8CI)(y4l(2Y6VhSEB5dxXgQLxIHuDu7cv2YJ04QqPTrBz93JTEB5rACvO02OL39ScFwy5HNiUjJbKX88h1JrRsoMulFmYli1reqjIBYyafULEm6m7STaPoIakr8XjseWre(XtIakraprCtgdqIHuDu7cvgK6S8HRyd1YFvHe3A(STS(dXSEB5rACvO02OL39ScFwy53ouP0v8NyTaoTSxXHrLebxjcFS8HRyd1Y7uy0aAlR)(L1BlpsJRcL2gT8UNv4Zcl)nzma3N2wg9uh7gjvbsDebuI4MmgqgZZFupgTk5ysT8XiVa5WHA5dxXgQLFvr2ww)HiSEB5rACvO02OL39ScFwy5Fmhm6seW1KiKPpk2qjciYeHNa)qeqjIk(tSaflJ6A0sgseCLiGyw(WvSHA5FKkTL1FU906TLhPXvHsBJwE3Zk8zHL)MmgW0a(Ddh8bBfoFjIMeHpebuIOcfslG8XqsJ0zBbqACvO0YhUInulFE(ku6TEMVOTS(Zn3wVT8inUkuAB0Y7EwHplS83KXaYyE(J6XOvjhtQLpg5fK6iI(EI4MmgGedP6O2fQmi1re99eHeVjJb4g1SBA1Bo2wqQJi67jIBYyafULEm6m7STaPolF4k2qT8ixGUuH2Y6p3(y92YhUInul)0a(Ddh8T8inUkuAB0ww)52pwVT8HRyd1YJCb6sfA5rACvO02OTSLL3WAa1v8Nyz926p3wVT8inUkuAB0Y7EwHplS8FCIebCeHh7jraLiGHiGNiQqH0ciXqQoQDHkdqACvOKi67jIBYyasmKQJAxOYa5WHseqA5dxXgQLF9nPuBNIvf(2Y6VpwVT8inUkuAB0Y7EwHplS8WqeWtevOqAb4e)9XWx8binUkuse99eHBgLC4qbCI)(y4l(GhZbJUebCeHpebKw(WvSHA5)OH4eFBz93pwVT8inUkuAB0Y7EwHplS8s8MmgGBuZUPvV5yBbYHd1YhUInulVBuZUPvV5yBTL1FiQ1BlpsJRcL2gT8UNv4ZclVeVjJb4g1SBA1Bo2wGC4qT8HRyd1YZj(7JHV4BlR)EW6TLhPXvHsBJwE3Zk8zHL)MmgWYbXog9uV1Z8fxGC4qjcOebmeb8erfkKwajgs1rTluzasJRcLerFprCtgdqIHuDu7cvgihouIasIakradradriXBYyaUrn7Mw9MJTf8yoy0Li4krarbEGiGseWteXHWNviOWT0JrNzNTfaPXvHsIasIOVNiUjJbu4w6XOZSZ2cK6iciT8HRyd1YFvHe3A(STS(7XwVT8HRyd1YlXqQoQDHkB5rACvO02OTS(dXSEB5dxXgQL3PWOb0YJ04QqPTrBz93VSEB5rACvO02OL39ScFwy5HHiGNiQqH0c4uy0acqACvOKiGseYPase70CMevUGhZbJUebCeHpebKerFpradrCtgdytsjs1smQwWJHRiI(EI4MmgWwdf1Ty8f4XWvebKebuIagI4MmgWYbXog9uV1Z8fxqQJi67jc3mk5WHcwoi2XON6TEMV4cEmhm6seCLi8lIaslF4k2qT8ixGUuH2Y6peH1BlpsJRcL2gT8UNv4Zclpmeb8erfkKwaNcJgqasJRcLebuIqofqIyNMZKOYf8yoy0LiGJi8HiGKi67jIBYyalhe7y0t9wpZxCbPoIakrCtgdyAa)UHd(GTcNVertIWhIakruHcPfq(yiPr6STainUkuA5dxXgQLppFfk9wpZx0ww)52tR3wEKgxfkTnA5DpRWNfwEjEtgdWnQz30Q3CSTGuhr03teWqe3KXaCFABz0tDSBKufi1reqjIkuiTag8ByE9y03OkfcqACvOKiG0YhUInulpNw2R4WOsBz9NBUTEB5rACvO02OL39ScFwy5VjJbiXqQoQDHkdsDerFpr8XjseCLi8ypT8HRyd1YZPL9komQ0ww)52hR3w(WvSHA5NgWVB4GVLhPXvHsBJ2Y6p3(X6TLpCfBOwEoTSxXHrLwEKgxfkTnAlR)CdrTEB5dxXgQLVbMRM)O(tBRLhPXvHsBJ2Y6p3EW6TLpCfBOwEwUdPsg9u3aZvZF0YJ04QqPTrBzlBz5Ba)LnuR)(4PpE6Ph8d3wEoXtz0Z1YdXN7MVqjr4bIiCfBOeHIT1ciWA57(XWuOL3JicU0NxIaIK4F28ey9iIOTQU1VZlVozvB6cCt2RLLtQOyd19HP8AzzNxey9iIa2efjcUHar4JN(4jbwcSEer43QnON463rG1JicUmrWLKsuse(nPCgvacSEerWLjcUKuIsIaIdZvZFKiGinTTEbXN7qQKrpjciomxn)rabwpIi4Yebxskrjr0yuLcjc(2jverner3JUjFJIi4s(n(Tbey9iIGlteqC5c0Lk2qX3V)se(np6ylBOebBjcjQWcLacSEerWLjcUKuIsIWV3IebeFH5fqGLaRhreqC5c0Lkusex0mpseUjFJIiU4jJUaIGl5CyxTebDOC524ZMKIicxXg6sedvDeqG1JiIWvSHUGUhDt(gvtJkwFjW6rer4k2qxq3JUjFJ6GMEzMrsG1JiIWvSHUGUhDt(g1bn9ksNzKwrXgkbwpIi4Pr32ofr8btse3KXGsIyROwI4IM5rIWn5BueXfpz0LicQKi6EKl3nvXONebBjc5qrab2WvSHUGUhDt(g1bn96gvPq92oPIaB4k2qxq3JUjFJ6GMELwuZkmdbAKXMXH224JvBgAPhJUB4Gpb2WvSHUGUhDt(g1bn9kJ55pQhJwLCmPw(yKxiWmnRqH0cyWVH51JrFJQuiaPXvHY((kuiTa5y3W9iaPXvHsOflJ6A0sgYvU9GN99vOqAbEKkbinUkucTyzuxJwYqUYTpEsGnCfBOlO7r3KVrDqtVotXlzbvpgDCi8NQfcmtZkuiTag8ByE9y03OkfcqACvOSVVcfslqo2nCpcqACvOeAXYOUgTKHC1hU9SVVcfslWJujaPXvHsOWuSmQRrlzix9HBp77lwg11OLmeoUHOEascSHRydDbDp6M8nQdA6v3uSHsGLaRhreqC5c0Lkuseyd4FKikwgjIQfjIWvZteSLiIgcMkUkeqGnCfBOBtxB8Nib2WvSHUh00RUuoJkcSHRydDpOPxDtXgkeyMMWuXFIfOfdv1c6CfC(WDFFfkKwGCSB4EeG04Qqj0k(tSaTyOQwqNRGZpEmKqH5MmgqgZZFupgTk5ysT8XiVGuxF)nzmGZu8swq1Jrhhc)PAbPoi77Hh3fPoeKX88h1JrRsoMulFmYlihhEEOWJ7IuhcCdvI0fLAfZGM5DiihhEEOWuXFIfOfdv1c6CfC(WDFFfkKwGCSB4EeG04Qqj0k(tSaTyOQwqNRGZpEmKqL4nzma3OMDtREZX2csDeydxXg6EqtVUQzKAt6pcbMP5nzmGmMN)OEmAvYXKA5JrEbPoO3KXakCl9y0z2zBbsD993KXaotXlzbvpgDCi8NQfK6GkXBYyaUrn7Mw9MJTfK667HbECxK6qqgZZFupgTk5ysT8XiVGCC45HcpUlsDiWnujsxuQvmdAM3HGCC45HkXBYyaUrn7Mw9MJTfK6GKaB4k2q3dA61f)fFFz0tiWmnVjJbKX88h1JrRsoMulFmYli1b9MmgqHBPhJoZoBlqQRV)MmgWzkEjlO6XOJdH)uTGuhujEtgdWnQz30Q3CSTGuxF)nzmGfXQLrp1FCIGuxFpmWJ7IuhcYyE(J6XOvjhtQLpg5fKJdppu4XDrQdbUHkr6IsTIzqZ8oeKJdppu4XDrQdbx1ms9y0vlQrkMpcYXHNhQeVjJb4g1SBA1Bo2wqQdscSHRydDpOPxX7ckQR5FKwqGzAEtgdiJ55pQhJwLCmPw(yKxGC4qH(XjcNh8ekmUzuYHdfKNVcLERN5lcEmhm6Y1tNSVhMk(tSaTyOQwqNRGZhp77RqH0cKJDd3JaKgxfkHwXFIfOfdv1c6CfC(Xdqcjb2WvSHUh00lf7STw9HtYZmsliWmnL4nzma3OMDtREZX2cKdhkb2WvSHUh00ld7XRAgjeyMM3KXaYyE(J6XOvjhtQLpg5fK6GEtgdOWT0JrNzNTfi113Ftgd4mfVKfu9y0XHWFQwqQdQeVjJb4g1SBA1Bo2wqQRVhg4XDrQdbzmp)r9y0QKJj1YhJ8cYXHNhk84Ui1Ha3qLiDrPwXmOzEhcYXHNhQeVjJb4g1SBA1Bo2wqQdscSHRydDpOPxb1HB9Hs7cLccmtZBYyazmp)r9y0QKJj1YhJ8csDqVjJbu4w6XOZSZ2cK667VjJbCMIxYcQEm64q4pvli1bvI3KXaCJA2nT6nhBli113dd84Ui1HGmMN)OEmAvYXKA5JrEb54WZdfECxK6qGBOsKUOuRyg0mVdb54WZdvI3KXaCJA2nT6nhBli1bjb2WvSHUh00RBCQhJUEMZ3fcmttjEtgdWnQz30Q3CSTa5WHc9MmgqgZZFupgTk5ysT8XiVa5WHc1nJsoCOG88vO0B9mFrWJ5GrxcSHRydDpOPxPf1ScZqGgzSzSTneuC1FCO51U5dfeyMMWlXBYyaFCO51U5dLwI3KXasD99Watf)jwGwmuvlOZvW5JNaU77RqH0cKJDd3JaKgxfkHwXFIfOfdv1c6CfC(XdaUHekm3KXaYyE(J6XOvjhtQLpg5fK6G6MrjhouqgZZFupgTk5ysT8XiVGhZbJUWXTNECF)nzmGZu8swq1Jrhhc)PAbPoOs8MmgGBuZUPvV5yBbPoiHSVhMk(tSaTyOQwqNRGZpEc4gQeVjJb4gQm5kwdOMr9vlXBYyaPoOWJ7IuhcYyE(J6XOvjhtQLpg5fKJdppu4XDrQdbUHkr6IsTIzqZ8oeKJdppK99WaVeVjJb4gQm5kwdOMr9vlXBYyaPoOWJ7IuhcYyE(J6XOvjhtQLpg5fKJdppu4XDrQdbUHkr6IsTIzqZ8oeKJdppujEtgdWnQz30Q3CSTGuhKeydxXg6EqtVslQzfMHanYyZ4qBB8XQndT0Jr3nCWhcmtZILrDnAjdHdI5juyCZOKdhkWnQz30Q3CSTGhZbJUWXTp99WuHcPfGt83hdFXhG04Qqju3mk5WHc4e)9XWx8bpMdgDHJBFGeY(E4L4nzma3OMDtREZX2csDqH)MmgqHBPhJoZoBlqQdk83KXaYyE(J6XOvjhtQLpg5fK6GwSmQRrlzix52dEsGnCfBO7bn9kAiQ4HaZ00nJsoCOa3OMDtREZX2cEmhm6cNF13dtfkKwaoXFFm8fFasJRcLqDZOKdhkGt83hdFXh8yoy0fo)cscSHRydDpOPxPf1ScZleyMMUzuYHdf4g1SBA1Bo2wWJ5Grx48R(EyQqH0cWj(7JHV4dqACvOeQBgLC4qbCI)(y4l(GhZbJUW5xqsGnCfBO7bn9A5GyhJEQ36z(IleyMMBhQu6k(tSwaNw2R4WOsUYnuyCZOKdhk4QcjU18zWJ5GrxUYTN99UzuYHdf4g1SBA1Bo2wWJ5GrxU6x99XHWNviOWT0JrNzNTfaPXvHsijWgUIn09GMEDvZi1JrxTOgPy(ieyMMWCtgdOWT0JrNzNTfi113dJeVjJb4g1SBA1Bo2wqQdk8XHWNviOWT0JrNzNTfaPXvHsiHekmflJ6A0sgYvicp77HPI)elqlgQQf05k48XZ((kuiTa5y3W9iaPXvHsOv8NybAXqvTGoxbNF8aKqsGnCfBO7bn9Ql9mZrg9uFvXwqGzAcVeVjJb4g1SBA1Bo2wqQdk83KXakCl9y0z2zBbsDeydxXg6EqtVEwxNc1mQE7chcbMPj8s8MmgGBuZUPvV5yBbPoOWFtgdOWT0JrNzNTfi1rGnCfBO7bn9IZ8kzdiJQFChAqDieyMMWlXBYyaUrn7Mw9MJTfK6Gc)nzmGc3spgDMD2wGuhb2WvSHUh00lZ4slk1XHWNvO(Irgcmtt4L4nzma3OMDtREZX2csDqH)MmgqHBPhJoZoBlqQJaB4k2q3dA61JrhJEQnQiJleyMMWlXBYyaUrn7Mw9MJTfK6Gc)nzmGc3spgDMD2wGuhb2WvSHUh00l3qDiT(OqP2OImcbMPj8s8MmgGBuZUPvV5yBbPoOWFtgdOWT0JrNzNTfi1bvofWnuhsRpkuQnQiJ6B6PGhZbJUn9KaB4k2q3dA6v1I6e9ojQuBM3HqGzAEtgd4rNVkCxTzEhcsDeydxXg6EqtVotXlzbvpgDCi8NQfcmtt4RqH0cWj(7JHV4dqACvOeQBgLC4qbUrn7Mw9MJTf8yoy0fopafMILrDnAjd5QpC7zFpmv8NybAXqvTGoxbNpE23xHcPfih7gUhbinUkucTI)elqlgQQf05k48JhGSVVyzuxJwYq48d3qsGnCfBO7bn96mfVKfu9y0XHWFQwiWmnRqH0cWj(7JHV4dqACvOeQBgLC4qbCI)(y4l(GhZbJUW5bOWuSmQRrlzix9HBp77HPI)elqlgQQf05k48XZ((kuiTa5y3W9iaPXvHsOv8NybAXqvTGoxbNF8aK99flJ6A0sgcNF4gscSHRydDpOPxzmp)r9y0QKJj1YhJ8cbMPj8vOqAb4e)9XWx8binUkuc1nJsoCOa3OMDtREZX2cEmhm6ch3qHPyzuxJwYqUYTh8SVhMk(tSaTyOQwqNRGZhp77RqH0cKJDd3JaKgxfkHwXFIfOfdv1c6CfC(Xdqcjb2WvSHUh00RmMN)OEmAvYXKA5JrEHaZ0ScfslaN4Vpg(IpaPXvHsOUzuYHdfWj(7JHV4dEmhm6ch3qHPyzuxJwYqUYTh8SVhMk(tSaTyOQwqNRGZhp77RqH0cKJDd3JaKgxfkHwXFIfOfdv1c6CfC(Xdqcjb2WvSHUh00Rpr1HRydvRyBbbAKXMgwdOUI)eliWmn3ouP0v8NyTaoTSxXHrLCfIsGnCfBO7bn96tuD4k2q1k2wqGgzSjYfOlvieyMMWuHcPfih7gUhbinUkucTI)elqlgQQf05k48JhGSVVI)elqlgQQf05k48XtcSHRydDpOPxFIQdxXgQwX2cc0iJnxg9uH6k(tSiWsGnCfBOla5c0LkS56BsP2ofRk8HaZ08Jteop4d0BYyasmKQJAxOYa5WHc9MmgqgZZFupgTk5ysT8XiVa5WHsGnCfBOla5c0Lk8GME9rdXj(qGzAc)nzmajgs1rTluzqQdkmUzuYHdf4g1SBA1Bo2wWJ5Grx48PVhMkuiTaCI)(y4l(aKgxfkH6MrjhouaN4Vpg(Ip4XCWOlC(ajKeydxXg6cqUaDPcpOPxUrn7Mw9MJTfcmtt4XDrQdbzmp)r9y0QKJj1YhJ8cYXHNVVhMBYyazmp)r9y0QKJj1YhJ8csD99UzuYHdfKX88h1JrRsoMulFmYl4XCWOlx52tijWgUIn0fGCb6sfEqtV4e)9XWx8HaZ0eECxK6qqgZZFupgTk5ysT8XiVGCC4577H5MmgqgZZFupgTk5ysT8XiVGuxFVBgLC4qbzmp)r9y0QKJj1YhJ8cEmhm6YvU9escSHRydDbixGUuHh00ljgs1rTluzcSHRydDbixGUuHh00RRkK4wZNHaZ0e(BYyazmp)r9y0QKJj1YhJ8csDqVjJbu4w6XOZSZ2cK6G(XjcNF8ek83KXaKyivh1UqLbPocSHRydDbixGUuHh00lNcJgqiWmn3ouP0v8NyTaoTSxXHrLC1hcSHRydDbixGUuHh00RvfziWmnVjJb4(02YON6y3iPkqQd6nzmGmMN)OEmAvYXKA5JrEbYHdLaB4k2qxaYfOlv4bn96rQecmtZhZbJUW1uM(OydfISNa)aTI)elqXYOUgTKHCfIrGnCfBOla5c0Lk8GMELNVcLERN5lcbMP5nzmGPb87go4d2kC(20hOvOqAbKpgsAKoBlasJRcLeydxXg6cqUaDPcpOPxixGUuHqGzAEtgdiJ55pQhJwLCmPw(yKxqQRV)MmgGedP6O2fQmi113lXBYyaUrn7Mw9MJTfK667VjJbu4w6XOZSZ2cK6iWgUIn0fGCb6sfEqtVMgWVB4Gpb2WvSHUaKlqxQWdA6fYfOlvibwcSHRydDbgwdOUI)eRMRVjLA7uSQWhcmtZpor48ypHcd8vOqAbKyivh1UqLbinUku23FtgdqIHuDu7cvgihouijWgUIn0fyynG6k(tSoOPxF0qCIpeyMMWaFfkKwaoXFFm8fFasJRcL99UzuYHdfWj(7JHV4dEmhm6cNpqsGnCfBOlWWAa1v8NyDqtVCJA2nT6nhBleyMMs8MmgGBuZUPvV5yBbYHdLaB4k2qxGH1aQR4pX6GMEXj(7JHV4dbMPPeVjJb4g1SBA1Bo2wGC4qjWgUIn0fyynG6k(tSoOPxxviXTMpdbMP5nzmGLdIDm6PERN5lUa5WHcfg4RqH0ciXqQoQDHkdqACvOSV)MmgGedP6O2fQmqoCOqcfgyK4nzma3OMDtREZX2cEmhm6YvikWdqHpoe(ScbfULEm6m7STainUkuczF)nzmGc3spgDMD2wGuhKeydxXg6cmSgqDf)jwh00ljgs1rTluzcSHRydDbgwdOUI)eRdA6LtHrdib2WvSHUadRbuxXFI1bn9c5c0LkecmttyGVcfslGtHrdiaPXvHsOYPase70CMevUGhZbJUW5dK99WCtgdytsjs1smQwWJHR67VjJbS1qrDlgFbEmCfKqH5MmgWYbXog9uV1Z8fxqQRV3nJsoCOGLdIDm6PERN5lUGhZbJUC1VGKaB4k2qxGH1aQR4pX6GMELNVcLERN5lcbMPjmWxHcPfWPWObeG04Qqju5uajIDAotIkxWJ5Grx48bY((BYyalhe7y0t9wpZxCbPoO3KXaMgWVB4GpyRW5BtFGwHcPfq(yiPr6STainUkusGnCfBOlWWAa1v8NyDqtV40YEfhgvcbMPPeVjJb4g1SBA1Bo2wqQRVhMBYyaUpTTm6Po2nsQcK6GwHcPfWGFdZRhJ(gvPqasJRcLqsGnCfBOlWWAa1v8NyDqtV40YEfhgvcbMP5nzmajgs1rTluzqQRV)JtKRESNeydxXg6cmSgqDf)jwh00RPb87go4tGnCfBOlWWAa1v8NyDqtV40YEfhgvsGnCfBOlWWAa1v8NyDqtVAG5Q5pQ)02sGnCfBOlWWAa1v8NyDqtVy5oKkz0tDdmxn)rcSeydxXg6cwg9uH6k(tSAU(MuQTtXQcFiWmn)4eHZdEm0BYyasmKQJAxOYa5WHc9MmgqgZZFupgTk5ysT8XiVa5WHsGnCfBOlyz0tfQR4pX6GME9rdXj(qGzAc)nzmajgs1rTluzqQdkmUzuYHdf4g1SBA1Bo2wWJ5Grx48PVhMkuiTaCI)(y4l(aKgxfkH6MrjhouaN4Vpg(Ip4XCWOlC(ajKeydxXg6cwg9uH6k(tSoOPxUrn7Mw9MJTLaB4k2qxWYONkuxXFI1bn9It83hdFXNaB4k2qxWYONkuxXFI1bn9sIHuDu7cvMaB4k2qxWYONkuxXFI1bn9c5c0LkecmtZBYyaBskrQwIr1cEmCfb2WvSHUGLrpvOUI)eRdA61vfsCR5ZqGzA6MrjhouqE(ku6TEMVi4XCWOlujEtgdWnQz30Q3CSTa5WHcfg4RqH0ciXqQoQDHkdqACvOSV)MmgGedP6O2fQmqoCOqcfgyK4nzma3OMDtREZX2csDqHpoe(ScbfULEm6m7STainUkuczF)nzmGc3spgDMD2wGuhKqVjJbKX88h1JrRsoMulFmYlqoCOq)4eHdI6jb2WvSHUGLrpvOUI)eRdA610a(Ddh8HaZ0eg4RqH0c8ivcqACvOeQCkGeXonNjrLl4XCWOl0por4GyEc9MmgqgZZFupgTk5ysT8XiVa5WHcvI3KXaCJA2nT6nhBlqoCOq23dtfkKwGhPsasJRcLqLtbKi2P5mjQCbpMdgDHkNc8ivcEmhm6Y1tNe6hNiCqmpHEtgdiJ55pQhJwLCmPw(yKxGC4qHkXBYyaUrn7Mw9MJTfihouijWgUIn0fSm6Pc1v8NyDqtVYZxHsV1Z8fjWgUIn0fSm6Pc1v8NyDqtVEKkHaZ08XCWOlCnLPpk2qHi7jWpeydxXg6cwg9uH6k(tSoOPxofgnGqGzAUDOsPR4pXAbCAzVIdJk5QpeydxXg6cwg9uH6k(tSoOPxCAzVIdJkHaZ0egyG5MmgqgZZFupgTk5ysT8XiVGuhK99WiXBYyaUrn7Mw9MJTfK6GSVhMBYyasmKQJAxOYGuhKqcTcfslGb)gMxpg9nQsHaKgxfkHSVhMBYyazmp)r9y0QKJj1YhJ8csDqL4nzma3OMDtREZX2csDqHVcfslGb)gMxpg9nQsHaKgxfkHKaB4k2qxWYONkuxXFI1bn9Avrgcmtt4RqH0cyWVH51JrFJQuiaPXvHsOWCtgdiJ55pQhJwLCmPw(yKxqQRVxI3KXaCJA2nT6nhBli1bjb2WvSHUGLrpvOUI)eRdA610a(Ddh8jWgUIn0fSm6Pc1v8NyDqtV40YEfhgvcbMPzfkKwad(nmVEm6BuLcbinUkucfMBYyafULEm6m7STaPU(EjEtgdWnQz30Q3CSTa5WHc9MmgqHBPhJoZoBlGC4qH(XjYvp2tijWgUIn0fSm6Pc1v8NyDqtVwvKHaZ0e(kuiTag8ByE9y03OkfcqACvOKaB4k2qxWYONkuxXFI1bn9QbMRM)O(tBlb2WvSHUGLrpvOUI)eRdA6fl3HujJEQBG5Q5pA53o0z9hIXTTSL1c]] )


end
