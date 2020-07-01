-- PaladinRetribution.lua
-- May 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'PALADIN' then
    local spec = Hekili:NewSpecialization( 70 )

    spec:RegisterResource( Enum.PowerType.HolyPower )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        zeal = 22590, -- 269569
        righteous_verdict = 22557, -- 267610
        execution_sentence = 22175, -- 267798

        fires_of_justice = 22319, -- 203316
        blade_of_wrath = 22592, -- 231832
        hammer_of_wrath = 22593, -- 24275

        fist_of_justice = 22896, -- 234299
        repentance = 22180, -- 20066
        blinding_light = 21811, -- 115750

        divine_judgment = 22375, -- 271580
        consecration = 22182, -- 205228
        wake_of_ashes = 22183, -- 255937

        cavalier = 22595, -- 230332
        unbreakable_spirit = 22185, -- 114154
        eye_for_an_eye = 22186, -- 205191

        selfless_healer = 23167, -- 85804
        justicars_vengeance = 22483, -- 215661
        word_of_glory = 23086, -- 210191

        divine_purpose = 22591, -- 223817
        crusade = 22215, -- 231895
        inquisition = 22634, -- 84963
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3446, -- 196029
        adaptation = 3445, -- 214027
        gladiators_medallion = 3444, -- 208683
        
        blessing_of_sanctuary = 752, -- 210256
        cleansing_light = 3055, -- 236186
        divine_punisher = 755, -- 204914
        hammer_of_reckoning = 756, -- 247675
        jurisdiction = 757, -- 204979
        law_and_order = 858, -- 204934
        lawbringer = 754, -- 246806
        luminescence = 81, -- 199428
        ultimate_retribution = 753, -- 287947
        unbound_freedom = 641, -- 305394
        vengeance_aura = 751, -- 210323
    } )

    -- Auras
    spec:RegisterAuras( {
        avenging_wrath = {
            id = 31884,
            duration = function () return azerite.lights_decree.enabled and 25 or 20 end,
            max_stack = 1,
        },

        avenging_wrath_autocrit = {
            id = 294027,
            duration = 20,
            max_stack = 1,
            copy = "avenging_wrath_crit"
        },

        blade_of_wrath = {
            id = 281178,
            duration = 10,
            max_stack = 1,
        },

        blessing_of_freedom = {
            id = 1044,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },

        blessing_of_protection = {
            id = 1022,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },

        crusade = {
            id = 231895,
            duration = 25,
            type = "Magic",
            max_stack = 10,
        },

        divine_purpose = {
            id = 223819,
            duration = 12,
            max_stack = 1,
        },

        divine_shield = {
            id = 642,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },

        divine_steed = {
            id = 221886,
            duration = 3,
            max_stack = 1,
        },

        execution_sentence = {
            id = 267799,
            duration = 12,
            max_stack = 1,
        },

        fires_of_justice = {
            id = 209785,
            duration = 15,
            max_stack = 1,
            copy = "the_fires_of_justice" -- backward compatibility
        },

        greater_blessing_of_kings = {
            id = 203538,
            duration = 3600,
            max_stack = 1,
            tick_time = 6,
            shared = "player", -- check for anyone's buff on the player.
        },

        greater_blessing_of_wisdom = {
            id = 203539,
            duration = 3600,
            max_stack = 1,
            tick_time = 10,
            shared = "player", -- check for anyone's buff on the player.
        },

        hammer_of_justice = {
            id = 853,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },

        hand_of_hindrance = {
            id = 183218,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },

        hand_of_reckoning = {
            id = 62124,
            duration = 3,
            max_stack = 1,
        },

        inquisition = {
            id = 84963,
            duration = 45,
            max_stack = 1,
        },

        judgment = {
            id = 197277,
            duration = 15,
            max_stack = 1,
        },

        righteous_verdict = {
            id = 267611,
            duration = 6,
            max_stack = 1,
        },

        selfless_healer = {
            id = 114250,
            duration = 15,
            max_stack = 4,
        },

        shield_of_vengeance = {
            id = 184662,
            duration = 15,
            max_stack = 1,
        },

        wake_of_ashes = {
            id = 255937,
            duration = 5,
            max_stack = 1,
        },

        zeal = {
            id = 217020,
            duration = 12,
            max_stack = 3
        },


        -- Azerite Powers
        empyreal_ward = {
            id = 287731,
            duration = 60,
            max_stack = 1,
        },

        empyrean_power = {
            id = 286393,
            duration = 15,
            max_stack = 1
        },

        -- PvP
        reckoning = {
            id = 247677,
            max_stack = 30,
            duration = 30
        },
    } )

    spec:RegisterGear( 'tier19', 138350, 138353, 138356, 138359, 138362, 138369 )
    spec:RegisterGear( 'tier20', 147160, 147162, 147158, 147157, 147159, 147161 )
        spec:RegisterAura( 'sacred_judgment', {
            id = 246973,
            duration = 8
        } )

    spec:RegisterGear( 'tier21', 152151, 152153, 152149, 152148, 152150, 152152 )
        spec:RegisterAura( 'hidden_retribution_t21_4p', {
            id = 253806, 
            duration = 15 
        } )

    spec:RegisterGear( 'class', 139690, 139691, 139692, 139693, 139694, 139695, 139696, 139697 )
    spec:RegisterGear( 'truthguard', 128866 )
    spec:RegisterGear( 'whisper_of_the_nathrezim', 137020 )
        spec:RegisterAura( 'whisper_of_the_nathrezim', {
            id = 207633,
            duration = 3600
        } )

    spec:RegisterGear( 'justice_gaze', 137065 )
    spec:RegisterGear( 'ashes_to_dust', 51745 )
        spec:RegisterAura( 'ashes_to_dust', {
            id = 236106, 
            duration = 6
        } )

    spec:RegisterGear( 'aegisjalmur_the_armguards_of_awe', 140846 )
    spec:RegisterGear( 'chain_of_thrayn', 137086 )
        spec:RegisterAura( 'chain_of_thrayn', {
            id = 236328,
            duration = 3600
        } )

    spec:RegisterGear( 'liadrins_fury_unleashed', 137048 )
        spec:RegisterAura( 'liadrins_fury_unleashed', {
            id = 208410,
            duration = 3600,
        } )

    spec:RegisterGear( "soul_of_the_highlord", 151644 )
    spec:RegisterGear( "pillars_of_inmost_light", 151812 )
    spec:RegisterGear( "scarlet_inquisitors_expurgation", 151813 )
        spec:RegisterAura( "scarlet_inquisitors_expurgation", {
            id = 248289, 
            duration = 3600,
            max_stack = 3
        } )
    
    spec:RegisterHook( 'spend', function( amt, resource )
        if amt > 0 and resource == "holy_power" and talent.crusade.enabled and buff.crusade.up then
            addStack( "crusade", buff.crusade.remains, amt )
        end
    end )



    -- Abilities
    spec:RegisterAbilities( {
        avenging_wrath = {
            id = 31884,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = 'cooldowns',
            notalent = 'crusade',

            startsCombat = true,
            texture = 135875,

            nobuff = 'avenging_wrath',

            handler = function ()
                applyBuff( 'avenging_wrath' )
                applyBuff( "avenging_wrath_crit" )
                if level < 115 then
                    if equipped.liadrins_fury_unleashed then gain( 1, 'holy_power' ) end
                end
            end,
        },


        blade_of_justice = {
            id = 184575,
            cast = 0,
            cooldown = function () return 10.5 * haste end,
            gcd = "spell",

            spend = -2,
            spendType = 'holy_power',

            notalent = 'divine_hammer',
            bind = 'divine_hammer',

            startsCombat = true,
            texture = 1360757,

            handler = function ()
                removeBuff( "blade_of_wrath" )
                removeBuff( 'sacred_judgment' )
                if talent.divine_judgment.enabled then addStack( 'divine_judgment', 15, 1 ) end
            end,
        },


        blessing_of_freedom = {
            id = 1044,
            cast = 0,
            charges = 1,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = 0.07,
            spendType = "mana",

            startsCombat = false,
            texture = 135968,

            handler = function ()
                applyBuff( 'blessing_of_freedom' )
            end,
        },


        blessing_of_protection = {
            id = 1022,
            cast = 0,
            charges = 1,
            cooldown = 300,
            recharge = 300,
            gcd = "spell",

            spend = 0.15,
            spendType = "mana",

            startsCombat = false,
            texture = 135964,

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                applyBuff( 'blessing_of_protection' )
                applyDebuff( 'player', 'forbearance' )
            end,
        },


        blinding_light = {
            id = 115750,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            talent = 'blinding_light',

            startsCombat = true,
            texture = 571553,

            handler = function ()
                applyDebuff( 'target', 'blinding_light', 6 )
                active_dot.blinding_light = active_enemies
            end,
        },


        cleanse_toxins = {
            id = 213644,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 135953,

            handler = function ()
            end,
        },


        consecration = {
            id = 205228,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            talent = 'consecration',

            startsCombat = true,
            texture = 135926,

            handler = function ()
            end,
        },


        crusade = {
            id = 231895,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            talent = 'crusade',
            toggle = 'cooldowns',

            startsCombat = false,
            texture = 236262,

            nobuff = 'crusade',

            usable = function () return not buff.crusade.up end,
            handler = function ()
                applyBuff( 'crusade' )
            end,
        },


        crusader_strike = {
            id = 35395,
            cast = 0,
            charges = 2,
            cooldown = function () return 6 * ( talent.fires_of_justice.enabled and 0.85 or 1 ) * haste end,
            recharge = function () return 6 * ( talent.fires_of_justice.enabled and 0.85 or 1 ) * haste end,
            gcd = "spell",

            spend = -1,
            spendType = 'holy_power',

            startsCombat = true,
            texture = 135891,

            handler = function ()
            end,
        },


        divine_shield = {
            id = 642,
            cast = 0,
            cooldown = function () return 300 * ( talent.unbreakable_spirit.enabled and 0.7 or 1 ) end,
            gcd = "spell",

            startsCombat = false,
            texture = 524354,

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                applyBuff( 'divine_shield' )
                applyDebuff( 'player', 'forbearance' )
            end,
        },


        divine_steed = {
            id = 190784,
            cast = 0,
            charges = function () return talent.cavalier.enabled and 2 or nil end,
            cooldown = 60,
            recharge = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 1360759,

            handler = function ()
                applyBuff( 'divine_steed' )
            end,
        },


        divine_storm = {
            id = 53385,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.divine_purpose.up then return 0 end
                if buff.empyrean_power.up then return 0 end
                return 3 - ( buff.fires_of_justice.up and 1 or 0 ) - ( buff.hidden_retribution_t21_4p.up and 1 or 0 )
            end,
            spendType = "holy_power",

            startsCombat = true,
            texture = 236250,

            handler = function ()
                if buff.empyrean_power.up then removeBuff( 'empyrean_power' )
                elseif buff.divine_purpose.up then removeBuff( 'divine_purpose' )
                else
                    removeBuff( 'fires_of_justice' )
                    removeBuff( 'hidden_retribution_t21_4p' )
                end

                if buff.avenging_wrath_crit.up then removeBuff( "avenging_wrath_crit" ) end

                if level < 116 then
                    if equipped.whisper_of_the_nathrezim then applyBuff( 'whisper_of_the_nathrezim', 4 ) end
                    if talent.divine_judgment.enabled then addStack( 'divine_judgment', 15, active_enemies ) end
                end
            end,
        },


        execution_sentence = {
            id = 267798,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = function ()
                if buff.divine_purpose.up then return 0 end
                return 3 - ( buff.fires_of_justice.up and 1 or 0 ) - ( buff.hidden_retribution_t21_4p.up and 1 or 0 )
            end,
            spendType = "holy_power",

            talent = 'execution_sentence', 

            startsCombat = true,
            texture = 613954,

            handler = function ()
                if buff.divine_purpose.up then removeBuff( 'divine_purpose' )
                else
                    removeBuff( 'fires_of_justice' )
                    removeBuff( 'hidden_retribution_t21_4p' )
                end
                applyDebuff( 'target', 'execution_sentence', 12 )
            end,
        },

        eye_for_an_eye = {
            id = 205191,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            talent = 'eye_for_an_eye',

            startsCombat = false,
            texture = 135986,

            handler = function ()
                applyBuff( 'eye_for_an_eye' )
            end,
        },


        flash_of_light = {
            id = 19750,
            cast = function () return ( 1.5 - ( buff.selfless_healer.stack * 0.5 ) ) * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.2,
            spendType = "mana",

            startsCombat = true,
            texture = 135907,

            handler = function ()
                removeBuff( 'selfless_healer' )
            end,
        },


        -- TODO:  Detect GBoK on allies.
        greater_blessing_of_kings = {
            id = 203538,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 135993,

            usable = function () return active_dot.greater_blessing_of_kings == 0 end,
            handler = function ()
                applyBuff( 'greater_blessing_of_kings' )
            end,
        },


        -- TODO:  Detect GBoW on allies.
        greater_blessing_of_wisdom = {
            id = 203539,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 135912,

            usable = function () return active_dot.greater_blessing_of_wisdom == 0 end,
            handler = function ()
                applyBuff( 'greater_blessing_of_wisdom' )
            end,
        },


        hammer_of_justice = {
            id = 853,
            cast = 0,
            cooldown = function ()
                if equipped.justice_gaze and target.health.percent > 75 then
                    return 15
                end
                return 60
            end,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 135963,

            handler = function ()
                applyDebuff( 'target', 'hammer_of_justice' )
                if equipped.justice_gaze and target.health.percent > 75 then
                    gain( 1, 'holy_power' )
                end
            end,
        },


        hammer_of_reckoning = {
            id = 247675,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            -- texture = ???,

            pvptalent = "hammer_of_reckoning",

            usable = function () return buff.reckoning.stack >= 50 end,
            handler = function ()
                removeStack( "reckoning", 50 )
                if talent.crusade.enabled then
                    applyBuff( "crusade", 12 )
                else
                    applyBuff( "avenging_wrath", 6 )
                end
            end,
        },


        hammer_of_wrath = {
            id = 24275,
            cast = 0,
            cooldown = function () return 7.5 * haste end,
            gcd = "spell",

            spend = -1,
            spendType = 'holy_power',

            startsCombat = true,
            texture = 613533,

            usable = function () return target.health_pct < 20 or buff.avenging_wrath.up or buff.crusade.up end,
            handler = function ()                
            end,
        },


        hand_of_hindrance = {
            id = 183218,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            startsCombat = true,
            texture = 1360760,

            handler = function ()
                applyDebuff( 'target', 'hand_of_hindrance' )
            end,
        },


        hand_of_reckoning = {
            id = 62124,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 135984,

            handler = function ()
                applyDebuff( 'target', 'hand_of_reckoning' )
            end,
        },


        inquisition = {
            id = 84963,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "holy_power",

            talent = 'inquisition',

            startsCombat = true,
            texture = 461858,

            usable = function () return buff.fires_of_justice.up or holy_power.current > 0 end,
            handler = function ()
                if buff.fires_of_justice.up then
                    local hopo = min( 2, holy_power.current )
                    spend( hopo, 'holy_power' )                    
                    applyBuff( 'inquisition', 15 * ( hopo + 1 ) )
                    return
                end
                local hopo = min( 3, holy_power.current )
                spend( hopo, 'holy_power' )                    
                applyBuff( 'inquisition', 15 * hopo )
            end,
        },


        judgment = {
            id = 20271,
            cast = 0,
            charges = 1,
            cooldown = function () return 12 * haste end,
            gcd = "spell",

            spend = -1,
            spendType = "holy_power",

            startsCombat = true,
            texture = 135959,

            handler = function ()
                applyDebuff( 'target', 'judgment' )
                if talent.zeal.enabled then applyBuff( 'zeal', 20, 3 ) end
                if set_bonus.tier20_2pc > 0 then applyBuff( 'sacred_judgment' ) end
                if set_bonus.tier21_4pc > 0 then applyBuff( 'hidden_retribution_t21_4p', 15 ) end
                if talent.sacred_judgment.enabled then applyBuff( 'sacred_judgment' ) end                
            end,
        },


        justicars_vengeance = {
            id = 215661,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.divine_purpose.up then return 0 end
                return 5 - ( buff.fires_of_justice.up and 1 or 0 ) - ( buff.hidden_retribution_t21_4p.up and 1 or 0 )
            end,
            spendType = "holy_power",

            startsCombat = true,
            texture = 135957,

            handler = function ()
                if buff.divine_purpose.up then removeBuff( 'divine_purpose' )
                else
                    removeBuff( 'fires_of_justice' )
                    removeBuff( 'hidden_retribution_t21_4p' )
                end
                if talent.divine_judgment.enabled then addStack( 'divine_judgment', 15, 1 ) end
            end,
        },


        lay_on_hands = {
            id = 633,
            cast = 0,
            cooldown = function () return 600 * ( talent.unbreakable_spirit.enabled and 0.7 or 1 ) end,
            gcd = "off",

            startsCombat = false,
            texture = 135928,

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                gain( health.max, "health" )
                applyDebuff( 'player', 'forbearance', 30 )
                if azerite.empyreal_ward.enabled then applyBuff( "empyreal_ward" ) end
            end,
        },


        rebuke = {
            id = 96231,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            toggle = 'interrupts',

            startsCombat = true,
            texture = 523893,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        redemption = {
            id = 7328,
            cast = function () return 10 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 135955,

            handler = function ()
            end,
        },


        repentance = {
            id = 20066,
            cast = function () return 1.7 * haste end,
            cooldown = 15,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 135942,

            handler = function ()
                interrupt()
                applyDebuff( 'target', 'repentance', 60 )
            end,
        },


        shield_of_vengeance = {
            id = 184662,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = true,
            texture = 236264,

            usable = function () return incoming_damage_3s > 0.2 * health.max, "incoming damage over 3s is less than 20% of max health" end,
            handler = function ()
                applyBuff( 'shield_of_vengeance' )
            end,
        },


        templars_verdict = {
            id = 85256,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.divine_purpose.up then return 0 end
                return 3 - ( buff.fires_of_justice.up and 1 or 0 ) - ( buff.hidden_retribution_t21_4p.up and 1 or 0 )
            end,
            spendType = "holy_power",

            startsCombat = true,
            texture = 461860,

            handler = function ()
                if buff.divine_purpose.up then removeBuff( 'divine_purpose' )                
                else
                    removeBuff( 'fires_of_justice' )
                    removeBuff( 'hidden_retribution_t21_4p' )
                end
                if buff.avenging_wrath_crit.up then removeBuff( "avenging_wrath_crit" ) end
                if talent.righteous_verdict.enabled then applyBuff( 'righteous_verdict' ) end
                if level < 115 and equipped.whisper_of_the_nathrezim then applyBuff( 'whisper_of_the_nathrezim', 4 ) end
                if talent.divine_judgment.enabled then addStack( 'divine_judgment', 15, 1 ) end
            end,
        },


        wake_of_ashes = {
            id = 255937,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = -5,
            spendType = 'holy_power',

            startsCombat = true,
            texture = 1112939,

            usable = function ()
                if settings.check_wake_range and not ( target.exists and target.within12 ) then return false, "target is outside of 12 yards" end
                return true
            end,

            handler = function ()
                if target.is_undead or target.is_demon then applyDebuff( 'target', 'wake_of_ashes' ) end
                if level < 115 and equipped.ashes_to_dust then
                    applyDebuff( 'target', 'ashes_to_dust' )
                    active_dot.ashes_to_dust = active_enemies
                end
                if talent.divine_judgment.enabled then addStack( 'divine_judgment', 15, 1 ) end
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


        word_of_glory = {
            id = 210191,
            cast = 0,
            charges = 2,
            cooldown = 60,
            recharge = 60,
            gcd = "spell",

            spend = function ()
                if buff.divine_purpose.up then return 0 end
                return 3 - ( buff.fires_of_justice.up and 1 or 0 ) - ( buff.hidden_retribution_t21_4p.up and 1 or 0 )
            end,
            spendType = "holy_power",

            startsCombat = true,
            texture = 133192,

            handler = function ()
                if buff.divine_purpose.up then removeBuff( 'divine_purpose' )
                else
                    removeBuff( 'fires_of_justice' )
                    removeBuff( 'hidden_retribution_t21_4p' )
                end
                gain( 1.33 * stat.spell_power * 8, 'health' )
            end,
        },
    } )


    spec:RegisterPack( "Retribution", 20200409, [[dCeUCbqiKKEevfAtuHrjf1Puiwfvf9kfLMfvLULcL0UG6xuv1Wqchtr1YOs5zsrMgvcxdjX2OQG(gvfyCkuQZHejRtHcAEujDpfSpPWbvOiwOIIhQqrnrfksUisKQ2isKkJejs5KkucRKkv7uHQHQqjAPkuGNsIPQq6QkuK6RkuO9k0FL0GrCyklgPEmrtMuxg1ML4ZeA0kYPvz1uj61iPMTuDBsA3I(TsdxkDCKOA5Q65qMoORly7urFNQmEKOCEQQSEKiMpb7h4484OrfTb544UrHBuqHlOGsHN30CFafJDub6xlhvAnj1MihvstLJkJbm8p6a82mQ0A(1xthhnQG2Wl5OYee2Igd93FXdofOXYv1F0Pg6g82u(wb6p6uL(hvOdxhowKr6OI2GCCC3OWnkOWfuqPWZBIIXUP5rfullJJ7dOiQmDAnNr6OIMrYOIpciJbm8p6a82eqglTUPVe4UpcitqylAm0F)fp4uGglxv)rNAOBWBt5BfO)Otv6pWDFeqgtA)RdiukFbe3OWnkaUdC3hbKX8KLImAme4UpciJvazmDR2GSgqk7diJnUjmWDFeqgRacLUJYaePHG(lNSm5oGmMhtHae5elPgbiL9bKXKXO)J5pGmnJbU7JaYyfqO0DugJaKY(acL2owUas7U9lfbep)xazSiP8WHo4TjGyPgqgJ731o5lbKXagTPLsgq88FbKX8hqMMXrL2FlxNJk(iGmgWW)OdWBtazS06M(sG7(iGmbHTOXq)9x8GtbASCv9hDQHUbVnLVvG(JovP)a39razmP9VoGqP8fqCJc3Oa4oWDFeqgZtwkYOXqG7(iGmwbKX0TAdYAaPSpGm24MWa39razSciu6okdqKgc6VCYYK7aYyEmfcqKtSKAeGu2hqgtgJ(pM)aY0mg4UpciJvaHs3rzmcqk7diuA7y5ciT72Vueq88FbKXIKYdh6G3MaILAazmUFx7KVeqgdy0MwkzaXZ)fqgZFazAgdCh4Upciu6PmwgGSgqO5Y(mGixvAdci0S4LimGmMiLClebi5MJ1j7vlHoGys4Tjcq2S7hg4UpciMeEBIWTplxvAdou6gIAG7(iGys4Tjc3(SCvPn4Sd(x2vdC3hbetcVnr42NLRkTbNDWFliQYj0G3Ma39rarjTw00cbK3onGqhkfwdiiObracnx2Nbe5QsBqaHMfVebiwQbK2NhRTleEPiGCiarVjJbU7JaIjH3MiC7ZYvL2GZo4pkTw00cRiObra3nj82eHBFwUQ0gC2b)Bx4TjWDtcVnr42NLRkTbNDW)aIRhKv9nnvEWOe0K9gQw2ew3sTD94h4UjH3MiC7ZYvL2GZo4V9sl5kC)NtOVxzGQqRZje7zuZ1Tun0eJWCA0DwdCh4Upciu6PmwgGSgqyN87hGapvgqGtmGys4(aYHaeZPDDJUZyG7MeEBIgEMoqndC3KWBt0Sd(lTEVAs4TzTFiOVPPYdYD761lra3nj82en7G)sR3RMeEBw7hc6BAQ8GiN8BW9ra3bUBs4Tjcd)lPMHOzh8pG46bzvFttLhEJs0HKAuL(eRpRR0biCtG7MeEBIWW)sQziA2b)diUEqw130u5bdn50sgvFJs2Vk336(ELbnthkf8BuY(v5(wVQz6qPG1Rxki0mDOuWMtofVuS69gCc)SQDjQXGBuiiqhkfS8ditZye0KupmNch0Hsbl)aY0m(zv7suJ5uzehnl3TRxVelgSxFww3s1Oe(x4e(zv7sudkffccWtLRWTQp21MOqqGQmcXPKXYn1CIyDTFfUSVKXQMl3FeG7MeEBIWW)sQziA2b)diUEqw130u5bxYO6061533RmqhkfS5KtXlfREVbNWHwbb6qPGLFazAghADqhkfS8ditZye0KupmNcG7MeEBIWW)sQziA2b)diUEqw130u5bNN1RBPA5PAqwxP77Q99kdnthkfS5KtXlfREVbNWHwbb6qPGLFazAghADqhkfS8ditZ4NvTlrUoFShrqOz5UD96LyZjNIxkw9EdoHFw1Ue1OjkeeK721RxILFazAg)SQDjQrtumcWDtcVnry4Fj1men7G)bexpiR6BAQ8GExvuTeE)89kd0HsbBo5u8sXQ3BWjCOvqGouky5hqMMXHwh0Hsbl)aY0m(zv7sKRZhBG7MeEBIWW)sQziA2b)diUEqw130u5brRZsR35hvPzJAFVYaDOuWMtofVuS69gCchAfeOdLcw(bKPzCO1bDOuWYpGmnJFw1Ue56CQaC3KWBteg(xsndrZo4FaX1dYQ(MMkpq7N4MCLM5Q1vT0K(ELb6qPGnNCkEPy17n4eo0kiqhkfS8ditZ4qlWDtcVnry4Fj1men7G)bexpiR6BAQ8Gk)m1Wjdvlwk67vgAMQVD6k7Kti20AeMPSdbrccVD6k7Kti20Ae(YgZPYiccOwU3Rq7fzicRpNxYveCF1gdUbC3KWBteg(xsndrZo4FaX1dYQ(MMkp02dPMFA2EnQw6gIAFVYaDOuWMtofVuS69gCchAfeOdLcw(bKPzCO1bDOuWYpGmnJrqtsDJH5uiii3TRxVeBo5u8sXQ3BWj8ZQ2LOgUGkccuLouky5hqMMXHwhYD761lXYpGmnJFw1Ue1Wfub4UjH3Mim8VKAgIMDW)aIRhKv9nnvEGMFe)uZpQ6YGld(ELb6qPGnNCkEPy17n4eo0kiqhkfS8ditZ4qRd6qPGLFazAgJGMK6gdZPqqqUBxVEj2CYP4LIvV3Gt4NvTlrnCbveeOkDOuWYpGmnJdToK721RxILFazAg)SQDjQHlOcWDtcVnry4Fj1men7G)bexpiR6BAQ8aN6oJqv4Lsy456wQL3KWBtRxBxp(99kd0HsbBo5u8sXQ3BWjCOvqGouky5hqMMXHwh0Hsbl)aY0mgbnj1ngMtHGGC3UE9sS5KtXlfREVbNWpRAxIA4cQiii3TRxVel)aY0m(zv7sudxqfG7MeEBIWW)sQziA2b)diUEqw130u5Hw2(EvFo5hvLRARHq(ELb6qPGnNCkEPy17n4eo0kiqhkfS8ditZ4qRd6qPGLFazAgJGMK6gdZPa4UjH3Mim8VKAgIMDW)aIRhKv9nnvEOCpcwvniJQOw)e7gc57vgOdLc2CYP4LIvV3Gt4qRGaDOuWYpGmnJdToOdLcw(bKPz8ZQ2LixhMtfG7MeEBIWW)sQziA2b)diUEqw130u5bVP77ExkIQT9GQjY(ELb6qPGnNCkEPy17n4eo0kiqhkfS8ditZ4qRd6qPGLFazAg)SQDjY1b3Oa4UjH3Mim8VKAgIMDW)aIRhKv9nnvEq)SPRIDtFgCFuL20ISVxzGoukyZjNIxkw9EdoHdTcc0Hsbl)aY0mo06Gouky5hqMMXpRAxICDWnkaUBs4Tjcd)lPMHOzh8pG46bzvFttLh0pB6QHAV3siQQYAR3Vn99kd0HsbBo5u8sXQ3BWjCOvqGouky5hqMMXHwh0Hsbl)aY0m(zv7sKRdUrbWDtcVnry4Fj1men7G)bexpiR6BAQ8G4VPiQ2(NQ1RVjY(ELbQshkfS5KtXlfREVbNWHwhuLouky5hqMMXHwG7MeEBIWW)sQziA2b)diUEqw130u5b0LhcYFvSB6ZG7JQ0MwK99kd0HsbBo5u8sXQ3BWjCOvqGouky5hqMMXHwh0Hsbl)aY0m(zv7sKRdZPcWDtcVnry4Fj1men7G)bexpiR6BAQ8a6Ydb5Vk2n9zW9rvvwB9(TPVxzGoukyZjNIxkw9EdoHdTcc0Hsbl)aY0mo06Gouky5hqMMXpRAxICDWnkaUBs4Tjcd)lPMHOzh8pG46bzvFttLhmkbnzVHQLnH1TuBxp(99kdufADoHy5hqMMXCA0Dw7qUBxVEj2CYP4LIvV3Gt4NvTlrUsfbbO15eILFazAgZPr3zTd5UD96Ly5hqMMXpRAxICLkoGNk3yofcctB3VA76XFJHMCapv215u4aADoHypJAUULQHMyeMtJUZAG7MeEBIWW)sQziA2b)diUEqw130u5bNh62SULQMvpe77vgOdLc2CYP4LIvV3Gt4qRGaDOuWYpGmnJdToOdLcw(bKPzmcAsQhMtHGGC3UE9sS5KtXlfREVbNWpRAxIAm0efccYD761lXYpGmnJFw1Ue1yOjkaUBs4Tjcd)lPMHOzh8pG46bzvFttLhm0Ktlzu9nkz)QCFR77vg0mDOuWVrj7xL7B9QMPdLcwVEPGqZ0HsbBo5u8sXQ3BWj8ZQ2LOgdUrHGaDOuWYpGmnJrqts9WCkCqhkfS8ditZ4NvTlrnMtLrC0SC3UE9sSyWE9zzDlvJs4FHt4NvTlrnOuuiiapvUc3Q(yxBIcbbQYieNsgl3uZjI11(v4Y(sgRAUC)raUBs4Tjcd)lPMHOzh8pG46bzvFttLhOoxyDlvlLhNWAj8(57vgOdLc2CYP4LIvV3Gt4qRGaDOuWYpGmnJdToOdLcw(bKPzmcAsQBmmNcbb5UD96LyZjNIxkw9EdoHFw1Ue1OjkeeOkDOuWYpGmnJdToK721RxILFazAg)SQDjQrtuaC3KWBteg(xsndrZo4FaX1dYQiFVYaDOuWMtofVuS69gCchAfeOdLcw(bKPzCO1bDOuWYpGmnJrqts9WCkaUdC3KWBtewUBxVEjAODH3M(ELHML721RxIfd2RplRBPAuc)lCc)SQDjQbLIcbbQYieNsgl3uZjI11(v4Y(sgRAUC)rC0mDOuW09D19acIF2Kqbb6qPGnNCkEPy17n4eo06GoukyZjNIxkw9EdoHFw1Ue1y(yliqhkfS8ditZ4qRd6qPGLFazAg)SQDjYv3OYia3nj82eHL721RxIMDW)(jobrvxg0IQCc99kdOwU3Rq7fzic3pXjiQ6YGwuLtyJb3eeAMQVD6k7Kti20AeMPSdbrccVD6k7Kti20Ae(Yg(aQmcWDtcVnry5UD96LOzh8VCpt33v77vgOdLc2CYP4LIvV3Gt4qRGaDOuWYpGmnJdToOdLcw(bKPzmcAsQhMtbWDtcVnry5UD96LOzh8hnDCxx3s1jNISLs23RmqhkfmIz40LI13ezSE9sh0HsbRYQ77xDl1EqE6Q(ztfH1RxcC3KWBtewUBxVEjA2b)LwVxnj82S2pe030u5b4Fj1mebC3KWBtewUBxVEjA2b)HtCnK0Bi11Y(s23Rmapv21b3eeOdLc(zj1DgHQL9Lmo0cC3KWBtewUBxVEjA2b)P77QRBPcN4kNSQF(ELb6qPGnNCkEPy17n4eo0kiqhkfS8ditZ4qRd6qPGLFazAgJGMK6H5uaC3KWBtewUBxVEjA2b)fd2RplRBPAuc)lCY3RmqvO15eILFazAgZPr3zTJML721RxInNCkEPy17n4e(zv7sKRuXX029R2UE83yOjhnthkf8LuE4qh82ehAfeOk06CcXxs5HdDWBtmNgDN1Jiii3TRxVeBo5u8sXQ3BWj8ZQ2LOgdUGkJii0m06CcXYpGmnJ50O7S2HC3UE9sS8ditZ4NvTlrUkk1oM2UF121J)gdUqqyA7(vBxp(Bm0Kd4PYUoNchqRZje7zuZ1Tun0eJWCA0Dwlii3TRxVel)aY0m(zv7suJbxqLraUBs4Tjcl3TRxVen7G)E731o5lRpJ20sj77vgK721RxInNCkEPy17n4e(zv7sKRIsTJPT7xTD94VXqtccqRZjel)aY0mMtJUZAhYD761lXYpGmnJFw1Ue5QOu7yA7(vBxp(Bm4cbb5UD96LyZjNIxkw9EdoHFw1Ue1yWfurqqUBxVEjw(bKPz8ZQ2LOgdUGka3nj82eHL721RxIMDW)YkdiwxnkH)dYvA2u99kdnt13oDLDYjeBAncZu2HGibH3oDLDYjeBAncFzJMOqqa1Y9EfAVidry958sUIG7R2yWTrCq1MPdLc2CYP4LIvV3Gt4qRGaDOuWYpGmnJdTJ4Oz5UD96Ly6UP56wQUmGGNKXpRAxIAik1(SjhYD761lXUmOfv5eIFw1Ue1quQ9ztJaC3KWBtewUBxVEjA2b)vz199RULApipDv)SPI89kdnthkfS5KtXlfREVbNWHwbb6qPGLFazAghADqhkfS8ditZye0KupmNIrCmTD)QTRh)Uo0eWDtcVnry5UD96LOzh8Vn8xXVlfR0Ddb99kdnt13oDLDYjeBAncZu2HGibH3oDLDYjeBAncFzJMOqqa1Y9EfAVidry958sUIG7R2yWTraUBs4Tjcl3TRxVen7G)bexpiR6lxkSewttLhK(j7l838Kv6UHG(ELbQ2mDOuWMtofVuS69gCchAfeOdLcw(bKPzCODehnl3TRxVet3nnx3s1Lbe8Km(zv7sudrP2Nn5qUBxVEj2LbTOkNq8ZQ2LOgIsTpBAeG7MeEBIWYD761lrZo4V5KtXlfREVbN89kdntvO15eIVKYdh6G3Myon6oRfeOdLc(skpCOdEBIdTJ4yA7(vBxp(Bm0eWDtcVnry5UD96LOzh8x(bKPzFVYW029R2UE83yWfcctB3VA76XFJHMCapv215u4aADoHypJAUULQHMyeMtJUZAG7a3nj82eHlxEOj(rdoT)m6o7BAQ8G3LIOA7UDFDA9apqvMYdxBlRXZ9HuQMM7chntvO15eILFazAgZPr3zTd5UD96LyZjNIxkw9EdoHFw1Ue1quQ9ztccYD761lXYpGmnJFw1Ue1quQ9ztJiiWuE4ABznEUpKs10Cx4OzQcToNqS8ditZyon6oRDi3TRxVeBo5u8sXQ3BWj8ZQ2LOgIsTp9HccYD761lXYpGmnJFw1Ue1quQ9PpCeG7MeEBIWLlp0e)Ozh83P9Nr3zFttLh0OQ0qqJUZ(606bEa1Y9EfAVidry958sUIG7R2yWnhufADoH4)eNG8gqvN8RpjeZPr3zTGaQL79k0ErgIW6Z5LCfb3xTXqtoGwNti(pXjiVbu1j)6tcXCA0DwliqhkfmR263ZwwBxp(XHwhAMoukyxg0IQCcX61lDqhkfS(CEjxBdF7IySE9sh0HsbBo5u8sXQ3BWPQfGR8piwVEjWDtcVnr4YLhAIF0Sd(FjLho0bVn99kd0HsbBo5u8sXQ3BWjSE9shnthkf8LuE4qh82eRxVuqGouk4lP8WHo4Tj(zv7sKRJTJPT7xTD94VXqtccqRZjeZugldWBZkItiNsgZPr3zTd5UD96LyMYyzaEBwrCc5uY4NvTlrUoNch0HsbFjLho0bVnXpRAxICDoveeK721RxInNCkEPy17n4e(zv7sKRZPId6qPGVKYdh6G3M4NvTlrU6gfoM2UF121J)gdnncWDtcVnr4YLhAIF0Sd(ZugldWBZkItiNs23RmGA5EVcTxKHiS(CEjxrW9vDDWnhntvO15eILFazAgZPr3zTd5UD96LyZjNIxkw9EdoHFw1Ue1yofccqRZjel)aY0mMtJUZAh0Hsbl)aY0mwVEPd5UD96Ly5hqMMXpRAxIAmNcbb6qPGLFazAgJGMK6gd(GraUBs4TjcxU8qt8JMDWF958sUIG7R67vgCA)z0DgRrvPHGgDND40(ZO7m27sruTD3UJMBMQqRZjeZugldWBZkItiNsgZPr3zTGqZOwU3Rq7fzicRpNxYveCF1gdUjii3TRxVeZugldWBZkItiNsg)SQDjQHOu7t3gzebHML721RxInNCkEPy17n4e(zv7sudrP2Nn5qUBxVEj2CYP4LIvV3Gt4NvTlrUoNcbb5UD96Ly5hqMMXpRAxIAik1(SjhYD761lXYpGmnJFw1Ue56CkeeOdLcw(bKPzCO1bDOuWYpGmnJrqtsTRZPyKraUBs4TjcxU8qt8JMDWFiR22ThvDYV(KqFVYGt7pJUZyVlfr12D7oAMQqRZjeZugldWBZkItiNsgZPr3zTGGC3UE9smtzSmaVnRioHCkz8ZQ2LOgIsTpDtqqUBxVEj2CYP4LIvV3Gt4NvTlrneLAF2Kd5UD96LyZjNIxkw9EdoHFw1Ue56CkeeK721RxILFazAg)SQDjQHOu7ZMCi3TRxVel)aY0m(zv7sKRZPqqGouky5hqMMXHwh0Hsbl)aY0mgbnj1UoNIraUdC3KWBtewKt(n4(ObN2FgDN9nnvEGsBhJ(606bEOzQcToNq8KPQYFDlvV3Gtyon6oRfeG2lYq8eBD4eUvcBm4gfoOAZ0HsbBo5u8sXQ3BWjCOvqGouky5hqMMXH2rgb4UjH3MiSiN8BW9rZo4V069QjH3M1(HG(MMkpuU8qt8J89kdtB3VA76XFJbQiiqhkfSkRUVF1Tu7b5PR6Nnveo0kiqhkfmIz40LI13ezCOvqaADoH4lP8WHo4TjMtJUZAh0HsbFjLho0bVnX61lDmTD)QTRh)ngAc4UjH3MiSiN8BW9rZo4VNrnx3s1qtmY3Rm0mvF70v2jNqSP1imtzhcIeeE70v2jNqSP1i8LnMtfbbul37vO9ImeH9mQ56wQgAIrngCBehnpTD)QTRh)UoqHGW029R2UE8pm3HC3UE9smD30CDlvxgqWtY4NvTlrneL6rC0SC3UE9sS5KtXlfREVbNWpRAxIAmNcbbO15eILFazAgZPr3zTd5UD96Ly5hqMMXpRAxIAmNIraUBs4TjclYj)gCF0Sd(t3nnx3s1Lbe8KSVxzyA7(vBxp(DDWnbHMN2UF121J)HMC0SC3UE9s8KPQYFDlvV3Gt4NvTlrneLAF6MGGt7pJUZykTDmoYia3nj82eHf5KFdUpA2b)DzqlQYj03RmmTD)QTRh)Uo4MGqZtB3VA76XVRdUWrZYD761lX0DtZ1TuDzabpjJFw1Ue1quQ9PBccoT)m6oJP02X4iJaC3KWBtewKt(n4(Ozh8FYuv5VULQ3BWjFVYW029R2UE876GlaUBs4TjclYj)gCF0Sd(l3eXY3G3M(ELHPT7xTD9431b3eeM2UF121JFxhAYHC3UE9smD30CDlvxgqWtY4NvTlrneLAF6MGW029R2UE8p4chYD761lX0DtZ1TuDzabpjJFw1Ue1quQ9PBoK721RxIDzqlQYje)SQDjQHOu7t3aUBs4TjclYj)gCF0Sd(lTEVAs4TzTFiOVPPYdLlp0e)iFVYa06CcXtMQk)1Tu9EdoH50O7S2b0ErgINyRdNWTsORdUrHGaDOuWMtofVuS69gCchAfeOdLcw(bKPzCOf4UjH3MiSiN8BW9rZo4V8ditZFfb)JA23Rmi3TRxVel)aY08xrW)OMXYj7fzuT8MeEBA9gdZX(aQ4O5PT7xTD9431b3eeM2UF121JFxhAYHC3UE9smD30CDlvxgqWtY4NvTlrneLAF6MGW029R2UE8p4chYD761lX0DtZ1TuDzabpjJFw1Ue1quQ9PBoK721RxIDzqlQYje)SQDjQHOu7t3Ci3TRxVel3eXY3G3M4NvTlrneLAF62ia3nj82eHf5KFdUpA2b)LwVxnj82S2pe030u5HYLhAIFeWDtcVnryro53G7JMDWF5MsoHVbzDT0nvg4UjH3MiSiN8BW9rZo4)Zw7LI1s3uzeWDtcVnryro53G7JMDWF5hqMM)kc(h1SVxzyA7(vBxp(DDWfa3nj82eHf5KFdUpA2b)TxAjxH7)Cc99kdtB3VA76XVRdUiQ4KF0TzCC3OWnkOOP5(GOIN95LIOOYyHA7(qwdi(qaXKWBtaPFiicdCpQ0peefhnQO5If6W4OXXNhhnQys4Tzu5z6a1CuHtJUZ64mryCC3IJgv40O7SootuXKWBZOI069QjH3M1(HGrL(HG10u5OIC3UE9sueghVP4Orfon6oRJZevmj82mQiTEVAs4TzTFiyuPFiynnvoQiYj)gCFuegHrL2NLRkTbJJghFEC0OIjH3MrL2fEBgv40O7Sootegh3T4Orfon6oRJZevstLJkgLGMS3q1YMW6wQTRh)rftcVnJkgLGMS3q1YMW6wQTRh)ryC8MIJgv40O7Sootur(hK)ZIkufqGwNti2ZOMRBPAOjgH50O7SoQys4TzuXEPLCfU)ZjmcJWOIC3UE9suC044ZJJgv40O7Sootur(hK)ZIkndiYD761lXIb71NL1TunkH)foHFw1UebinaekffaIGaGqvaHrioLmwUPMteRR9RWL9Lmw1C5(aYiaIdaPzaHouky6(U6EabXpBsiGiiai0HsbBo5u8sXQ3BWjCOfqCai0HsbBo5u8sXQ3BWj8ZQ2LiaPbGmFSbebbaHouky5hqMMXHwaXbGqhkfS8ditZ4NvTlraIRaIBubqgjQys4TzuPDH3MryCC3IJgv40O7Sootur(hK)ZIkOwU3Rq7fzic3pXjiQ6YGwuLtiG0yaqCdqeeaKMbeQciVD6k7Kti20AeMPSdbraIGaG82PRStoHytRr4lbKgaIpGkaYirftcVnJk9tCcIQUmOfv5egHXXBkoAuHtJUZ64mrf5Fq(plQqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqCai0Hsbl)aY0mgbnj1aYaGmNIOIjH3MrLY9mDFxDegh3fXrJkCA0DwhNjQi)dY)zrf6qPGrmdNUuS(MiJ1Rxcioae6qPGvz199RULApipDv)SPIW61lJkMeEBgvqth311TuDYPiBPKJW44ujoAuHtJUZ64mrftcVnJksR3RMeEBw7hcgv6hcwttLJkW)sQzikcJJ7dJJgv40O7Sootur(hK)ZIkWtLbexhae3aebbaHouk4NLu3zeQw2xY4qBuXKWBZOcCIRHKEdPUw2xYryCCFqC0OcNgDN1XzIkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPzmcAsQbKbazofrftcVnJk09D11TuHtCLtw1Vimo(yhhnQWPr3zDCMOI8pi)NfvOkGaToNqS8ditZyon6oRbehasZaIC3UE9sS5KtXlfREVbNWpRAxIaexbeQaioaKPT7xTD94hqAmainbioaKMbe6qPGVKYdh6G3M4qlGiiaiufqGwNti(skpCOdEBI50O7Sgqgbqeeae5UD96LyZjNIxkw9EdoHFw1UebingaexqfazearqaqAgqGwNtiw(bKPzmNgDN1aIdarUBxVEjw(bKPz8ZQ2LiaXvaruQbehaY029R2UE8dingaexaiccaY029R2UE8dingaKMaehac8uzaXvazofaIdabADoHypJAUULQHMyeMtJUZAarqaqK721RxILFazAg)SQDjcqAmaiUGkaYirftcVnJkIb71NL1TunkH)fofHXXPuXrJkCA0DwhNjQi)dY)zrf5UD96LyZjNIxkw9EdoHFw1UebiUciIsnG4aqM2UF121JFaPXaG0eGiiaiqRZjel)aY0mMtJUZAaXbGi3TRxVel)aY0m(zv7seG4kGik1aIdazA7(vBxp(bKgdaIlaebbarUBxVEj2CYP4LIvV3Gt4NvTlrasJbaXfubqeeae5UD96Ly5hqMMXpRAxIaKgdaIlOsuXKWBZOI3(DTt(Y6ZOnTuYryC85uehnQWPr3zDCMOI8pi)NfvAgqOkG82PRStoHytRryMYoeebiccaYBNUYo5eInTgHVeqAainrbGiiaiOwU3Rq7fzicRpNxYveCFvaPXaG4gGmcG4aqOkG0mGqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqgbqCaindiYD761lX0DtZ1TuDzabpjJFw1UebinaerPgq8jG0eG4aqK721RxIDzqlQYje)SQDjcqAaiIsnG4taPjazKOIjH3MrLYkdiwxnkH)dYvA2uJW44ZNhhnQWPr3zDCMOI8pi)NfvAgqOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAgJGMKAazaqMtbGmcG4aqM2UF121JFaX1baPPOIjH3MrfvwDF)QBP2dYtx1pBQOimo(C3IJgv40O7Sootur(hK)ZIkndiufqE70v2jNqSP1imtzhcIaebba5TtxzNCcXMwJWxcinaKMOaqeeaeul37vO9ImeH1NZl5kcUVkG0yaqCdqgjQys4TzuPn8xXVlfR0DdbJW44ZBkoAuHtJUZ64mrftcVnJks)K9f(BEYkD3qWOI8pi)NfvOkG0mGqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqgbqCaindiYD761lX0DtZ1TuDzabpjJFw1UebinaerPgq8jG0eG4aqK721RxIDzqlQYje)SQDjcqAaiIsnG4taPjazKOcxkSewttLJks)K9f(BEYkD3qWimo(CxehnQWPr3zDCMOI8pi)NfvAgqOkGaToNq8LuE4qh82eZPr3znGiiai0HsbFjLho0bVnXHwazeaXbGmTD)QTRh)asJbaPPOIjH3MrfZjNIxkw9EdofHXXNtL4Orfon6oRJZevK)b5)SOY029R2UE8dingaexaiccaY029R2UE8dingaKMaehac8uzaXvazofaIdabADoHypJAUULQHMyeMtJUZ6OIjH3Mrf5hqMMJWimQa)lPMHO4OXXNhhnQWPr3zDCMOsAQCu5nkrhsQrv6tS(SUshGWnJkMeEBgvEJs0HKAuL(eRpRR0biCZimoUBXrJkCA0DwhNjQys4TzuXqtoTKr13OK9RY9TEur(hK)ZIkAMouk43OK9RY9TEvZ0HsbRxVeqeeaKMbe6qPGnNCkEPy17n4e(zv7seG0yaqCJcarqaqOdLcw(bKPzmcAsQbKbazofaIdaHouky5hqMMXpRAxIaKgaYCQaiJaioaKMbe5UD96LyXG96ZY6wQgLW)cNWpRAxIaKgacLIcarqaqGNkxHBvFmG4kG0efaIGaGqvaHrioLmwUPMteRR9RWL9Lmw1C5(aYirL0u5OIHMCAjJQVrj7xL7B9imoEtXrJkCA0DwhNjQys4TzuXLmQoTED(JkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPzmcAsQbKbazofrL0u5OIlzuDA968hHXXDrC0OcNgDN1XzIkMeEBgvCEwVULQLNQbzDLUVRoQi)dY)zrLMbe6qPGnNCkEPy17n4eo0ciccacDOuWYpGmnJdTaIdaHouky5hqMMXpRAxIaexbK5JnGmcGiiaindiYD761lXMtofVuS69gCc)SQDjcqAainrbGiiaiYD761lXYpGmnJFw1UebinaKMOaqgjQKMkhvCEwVULQLNQbzDLUVRocJJtL4Orfon6oRJZevmj82mQO3vfvlH3VOI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAg)SQDjcqCfqMp2rL0u5OIExvuTeE)IW44(W4Orfon6oRJZevmj82mQiADwA9o)OknBuhvK)b5)SOcDOuWMtofVuS69gCchAbebbaHouky5hqMMXHwaXbGqhkfS8ditZ4NvTlraIRaYCQevstLJkIwNLwVZpQsZg1ryCCFqC0OcNgDN1XzIkMeEBgvO9tCtUsZC16QwAYOI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0gvstLJk0(jUjxPzUADvlnzeghFSJJgv40O7SootuXKWBZOIk)m1WjdvlwkgvK)b5)SOsZacvbK3oDLDYjeBAncZu2HGiarqaqE70v2jNqSP1i8LasdazovaKraebbab1Y9EfAVidry958sUIG7Rcingae3IkPPYrfv(zQHtgQwSumcJJtPIJgv40O7SootuXKWBZOsBpKA(Pz71OAPBiQJkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPzmcAsQbKgdaYCkaebbarUBxVEj2CYP4LIvV3Gt4NvTlrasdaXfubqeeaeQci0Hsbl)aY0mo0cioae5UD96Ly5hqMMXpRAxIaKgaIlOsujnvoQ02dPMFA2EnQw6gI6imo(CkIJgv40O7SootuXKWBZOcn)i(PMFu1LbxgIkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPzmcAsQbKgdaYCkaebbarUBxVEj2CYP4LIvV3Gt4NvTlrasdaXfubqeeaeQci0Hsbl)aY0mo0cioae5UD96Ly5hqMMXpRAxIaKgaIlOsujnvoQqZpIFQ5hvDzWLHimo(85XrJkCA0DwhNjQys4TzuHtDNrOk8sjm8CDl1YBs4TP1RTRh)rf5Fq(plQqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqCai0Hsbl)aY0mgbnj1asJbazofaIGaGi3TRxVeBo5u8sXQ3BWj8ZQ2LiaPbG4cQaiccaIC3UE9sS8ditZ4NvTlrasdaXfujQKMkhv4u3zeQcVucdpx3sT8MeEBA9A76XFeghFUBXrJkCA0DwhNjQys4TzuPLTVx1Nt(rv5Q2Aiuur(hK)ZIk0HsbBo5u8sXQ3BWjCOfqeeae6qPGLFazAghAbehacDOuWYpGmnJrqtsnG0yaqMtrujnvoQ0Y23R6Zj)OQCvBnekcJJpVP4Orfon6oRJZevmj82mQuUhbRQgKrvuRFIDdHIkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPz8ZQ2LiaX1bazovIkPPYrLY9iyv1GmQIA9tSBiueghFUlIJgv40O7SootuXKWBZOI309DVlfr12Eq1e5OI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAg)SQDjcqCDaqCJIOsAQCuXB6(U3LIOABpOAICeghFovIJgv40O7SootuXKWBZOI(ztxf7M(m4(OkTPf5OI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAg)SQDjcqCDaqCJIOsAQCur)SPRIDtFgCFuL20ICeghFUpmoAuHtJUZ64mrftcVnJk6NnD1qT3BjevvzT173Mrf5Fq(plQqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqCai0Hsbl)aY0m(zv7seG46aG4gfrL0u5OI(ztxnu79wcrvvwB9(TzeghFUpioAuHtJUZ64mrftcVnJkI)MIOA7FQwV(MihvK)b5)SOcvbe6qPGnNCkEPy17n4eo0cioaeQci0Hsbl)aY0mo0gvstLJkI)MIOA7FQwV(MihHXXNp2XrJkCA0DwhNjQys4TzubD5HG8xf7M(m4(OkTPf5OI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAg)SQDjcqCDaqMtLOsAQCubD5HG8xf7M(m4(OkTPf5imo(CkvC0OcNgDN1XzIkMeEBgvqxEii)vXUPpdUpQQYAR3VnJkY)G8FwuHoukyZjNIxkw9EdoHdTaIGaGqhkfS8ditZ4qlG4aqOdLcw(bKPz8ZQ2LiaX1baXnkIkPPYrf0LhcYFvSB6ZG7JQQS269BZimoUBuehnQWPr3zDCMOIjH3MrfJsqt2BOAztyDl121J)OI8pi)NfvOkGaToNqS8ditZyon6oRbehaIC3UE9sS5KtXlfREVbNWpRAxIaexbeQaiccac06CcXYpGmnJ50O7SgqCaiYD761lXYpGmnJFw1UebiUciubqCaiWtLbKgaYCkaebbazA7(vBxp(bKgdastaIdabEQmG4kGmNcaXbGaToNqSNrnx3s1qtmcZPr3zDujnvoQyucAYEdvlBcRBP2UE8hHXXDBEC0OcNgDN1XzIkMeEBgvCEOBZ6wQAw9qCur(hK)ZIk0HsbBo5u8sXQ3BWjCOfqeeae6qPGLFazAghAbehacDOuWYpGmnJrqtsnGmaiZPaqeeae5UD96LyZjNIxkw9EdoHFw1UebingaKMOaqeeae5UD96Ly5hqMMXpRAxIaKgdastuevstLJkop0TzDlvnREiocJJ7MBXrJkCA0DwhNjQys4TzuXqtoTKr13OK9RY9TEur(hK)ZIkAMouk43OK9RY9TEvZ0HsbRxVeqeeaKMbe6qPGnNCkEPy17n4e(zv7seG0yaqCJcarqaqOdLcw(bKPzmcAsQbKbazofaIdaHouky5hqMMXpRAxIaKgaYCQaiJaioaKMbe5UD96LyXG96ZY6wQgLW)cNWpRAxIaKgacLIcarqaqGNkxHBvFmG4kG0efaIGaGqvaHrioLmwUPMteRR9RWL9Lmw1C5(aYirL0u5OIHMCAjJQVrj7xL7B9imoUBnfhnQWPr3zDCMOIjH3MrfQZfw3s1s5XjSwcVFrf5Fq(plQqhkfS5KtXlfREVbNWHwarqaqOdLcw(bKPzCOfqCai0Hsbl)aY0mgbnj1asJbazofaIGaGi3TRxVeBo5u8sXQ3BWj8ZQ2LiaPbG0efaIGaGqvaHouky5hqMMXHwaXbGi3TRxVel)aY0m(zv7seG0aqAIIOsAQCuH6CH1TuTuECcRLW7xegh3nxehnQWPr3zDCMOI8pi)NfvOdLc2CYP4LIvV3Gt4qlGiiai0Hsbl)aY0mo0cioae6qPGLFazAgJGMKAazaqMtruXKWBZOsaX1dYQOimcJkLlp0e)O4OXXNhhnQWPr3zDCMOY2gvqmmQys4TzuXP9Nr35OItRh4OcvbeMYdxBlRXgLGMS3q1YMW6wQTRh)aIdaPzaHQac06CcXYpGmnJ50O7SgqCaiYD761lXMtofVuS69gCc)SQDjcqAaiIsnG4taPjarqaqK721RxILFazAg)SQDjcqAaiIsnG4taPjazearqaqykpCTTSgBucAYEdvlBcRBP2UE8dioaKMbeQciqRZjel)aY0mMtJUZAaXbGi3TRxVeBo5u8sXQ3BWj8ZQ2LiaPbGik1aIpbeFiGiiaiYD761lXYpGmnJFw1UebinaerPgq8jG4dbKrIkoTVMMkhv8UuevB3ThHXXDloAuHtJUZ64mrLTnQGyyuXKWBZOIt7pJUZrfNwpWrful37vO9ImeH1NZl5kcUVkG0yaqCdqCaiufqGwNti(pXjiVbu1j)6tcXCA0DwdiccacQL79k0ErgIW6Z5LCfb3xfqAmainbioaeO15eI)tCcYBavDYV(KqmNgDN1aIGaGqhkfmR263ZwwBxp(XHwaXbGOz6qPGDzqlQYjeRxVeqCai0HsbRpNxY12W3UigRxVeqCai0HsbBo5u8sXQ3BWPQfGR8piwVEzuXP910u5OIgvLgcA0DocJJ3uC0OcNgDN1XzIkY)G8FwuHoukyZjNIxkw9EdoH1RxcioaKMbe6qPGVKYdh6G3My96LaIGaGqhkf8LuE4qh82e)SQDjcqCfqgBaXbGmTD)QTRh)asJbaPjarqaqGwNtiMPmwgG3MveNqoLmMtJUZAaXbGi3TRxVeZugldWBZkItiNsg)SQDjcqCfqMtbG4aqOdLc(skpCOdEBIFw1UebiUciZPcGiiaiYD761lXMtofVuS69gCc)SQDjcqCfqMtfaXbGqhkf8LuE4qh82e)SQDjcqCfqCJcaXbGmTD)QTRh)asJbaPjazKOIjH3MrLlP8WHo4Tzegh3fXrJkCA0DwhNjQi)dY)zrful37vO9ImeH1NZl5kcUVkG46aG4gG4aqAgqOkGaToNqS8ditZyon6oRbehaIC3UE9sS5KtXlfREVbNWpRAxIaKgaYCkaebbabADoHy5hqMMXCA0Dwdioae6qPGLFazAgRxVeqCaiYD761lXYpGmnJFw1UebinaK5uaiccacDOuWYpGmnJrqtsnG0yaq8baYirftcVnJkmLXYa82SI4eYPKJW44ujoAuHtJUZ64mrf5Fq(plQ40(ZO7mwJQsdbn6odioaeN2FgDNXExkIQT72behasZasZacvbeO15eIzkJLb4TzfXjKtjJ50O7SgqeeaKMbeul37vO9ImeH1NZl5kcUVkG0yaqCdqeeae5UD96LyMYyzaEBwrCc5uY4NvTlrasdaruQbeFciUbiJaiJaiccasZaIC3UE9sS5KtXlfREVbNWpRAxIaKgaIOudi(eqAcqCaiYD761lXMtofVuS69gCc)SQDjcqCfqMtbGiiaiYD761lXYpGmnJFw1UebinaerPgq8jG0eG4aqK721RxILFazAg)SQDjcqCfqMtbGiiai0Hsbl)aY0mo0cioae6qPGLFazAgJGMKAaXvazofaYiaYirftcVnJk6Z5LCfb3xncJJ7dJJgv40O7Sootur(hK)ZIkoT)m6oJ9UuevB3TdioaKMbeQciqRZjeZugldWBZkItiNsgZPr3znGiiaiYD761lXmLXYa82SI4eYPKXpRAxIaKgaIOudi(eqCdqeeae5UD96LyZjNIxkw9EdoHFw1UebinaerPgq8jG0eG4aqK721RxInNCkEPy17n4e(zv7seG4kGmNcarqaqK721RxILFazAg)SQDjcqAaiIsnG4taPjaXbGi3TRxVel)aY0m(zv7seG4kGmNcarqaqOdLcw(bKPzCOfqCai0Hsbl)aY0mgbnj1aIRaYCkaKrIkMeEBgvGSAB3Eu1j)6tcJWimQiYj)gCFuC044ZJJgv40O7SootuzBJkiggvmj82mQ40(ZO7CuXP1dCuPzaHQac06CcXtMQk)1Tu9EdoH50O7SgqeeaeO9ImepXwhoHBLqaPXaG4gfaIdaHQasZacDOuWMtofVuS69gCchAbebbaHouky5hqMMXHwazeazKOIt7RPPYrfkTDmgHXXDloAuHtJUZ64mrf5Fq(plQmTD)QTRh)asJbaHkaIGaGqhkfSkRUVF1Tu7b5PR6Nnveo0ciccacDOuWiMHtxkwFtKXHwarqaqGwNti(skpCOdEBI50O7SgqCai0HsbFjLho0bVnX61lbehaY029R2UE8dingaKMIkMeEBgvKwVxnj82S2pemQ0peSMMkhvkxEOj(rryC8MIJgv40O7Sootur(hK)ZIkndiufqE70v2jNqSP1imtzhcIaebba5TtxzNCcXMwJWxcinaK5ubqeeaeul37vO9ImeH9mQ56wQgAIrasJbaXnazeaXbG0mGmTD)QTRh)aIRdacfaIGaGmTD)QTRh)aYaGmhqCaiYD761lX0DtZ1TuDzabpjJFw1UebinaerPgqgbqCaindiYD761lXMtofVuS69gCc)SQDjcqAaiZPaqeeaeO15eILFazAgZPr3znG4aqK721RxILFazAg)SQDjcqAaiZPaqgjQys4TzuXZOMRBPAOjgfHXXDrC0OcNgDN1XzIkY)G8FwuzA7(vBxp(bexhae3aebbaPzazA7(vBxp(bKbaPjaXbG0mGi3TRxVepzQQ8x3s17n4e(zv7seG0aqeLAaXNaIBaIGaG40(ZO7mMsBhJaYiaYirftcVnJk0DtZ1TuDzabpjhHXXPsC0OcNgDN1XzIkY)G8FwuzA7(vBxp(bexhae3aebbaPzazA7(vBxp(bexhaexaioaKMbe5UD96Ly6UP56wQUmGGNKXpRAxIaKgaIOudi(eqCdqeeaeN2FgDNXuA7yeqgbqgjQys4TzuXLbTOkNWimoUpmoAuHtJUZ64mrf5Fq(plQmTD)QTRh)aIRdaIlIkMeEBgvMmvv(RBP69gCkcJJ7dIJgv40O7Sootur(hK)ZIktB3VA76XpG46aG4gGiiaitB3VA76XpG46aG0eG4aqK721RxIP7MMRBP6YacEsg)SQDjcqAaiIsnG4taXnarqaqM2UF121JFazaqCbG4aqK721RxIP7MMRBP6YacEsg)SQDjcqAaiIsnG4taXnaXbGi3TRxVe7YGwuLti(zv7seG0aqeLAaXNaIBrftcVnJkYnrS8n4TzeghFSJJgv40O7Sootur(hK)ZIkqRZjepzQQ8x3s17n4eMtJUZAaXbGaTxKH4j26WjCReciUoaiUrbGiiai0HsbBo5u8sXQ3BWjCOfqeeae6qPGLFazAghAJkMeEBgvKwVxnj82S2pemQ0peSMMkhvkxEOj(rryCCkvC0OcNgDN1XzIkY)G8FwurUBxVEjw(bKP5VIG)rnJLt2lYOA5nj8206asJbazo2hqfaXbG0mGmTD)QTRh)aIRdaIBaIGaGmTD)QTRh)aIRdastaIdarUBxVEjMUBAUULQldi4jz8ZQ2LiaPbGik1aIpbe3aebbazA7(vBxp(bKbaXfaIdarUBxVEjMUBAUULQldi4jz8ZQ2LiaPbGik1aIpbe3aehaIC3UE9sSldArvoH4NvTlrasdaruQbeFciUbioae5UD96Ly5Miw(g82e)SQDjcqAaiIsnG4taXnazKOIjH3Mrf5hqMM)kc(h1CeghFofXrJkCA0DwhNjQys4TzurA9E1KWBZA)qWOs)qWAAQCuPC5HM4hfHXXNppoAuXKWBZOICtjNW3GSUw6Mkhv40O7SooteghFUBXrJkMeEBgvE2AVuSw6MkJIkCA0DwhNjcJJpVP4Orfon6oRJZevK)b5)SOY029R2UE8diUoaiUiQys4Tzur(bKP5VIG)rnhHXXN7I4Orfon6oRJZevK)b5)SOY029R2UE8diUoaiUiQys4TzuXEPLCfU)ZjmcJWimQyb40(rfLtDmhHrymc]] )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 8,

        potion = "potion_of_focused_resolve",

        package = "Retribution",
    } )


    spec:RegisterSetting( "check_wake_range", false, {
        name = "Check |T1112939:0|t Wake of Ashes Range",
        desc = "If checked, when your target is outside of |T1112939:0|t Wake of Ashes' range, it will not be recommended.",
        type = "toggle",
        width = 1.5
    } ) 


end
