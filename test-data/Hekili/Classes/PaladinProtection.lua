-- PaladinProtection.lua
-- May 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State


local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'PALADIN' then
    local spec = Hekili:NewSpecialization( 66 )

    spec:RegisterResource( Enum.PowerType.HolyPower )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        holy_shield = 22428, -- 152261
        redoubt = 22558, -- 280373
        blessed_hammer = 22430, -- 204019

        first_avenger = 22431, -- 203776
        crusaders_judgment = 22604, -- 204023
        bastion_of_light = 22594, -- 204035

        fist_of_justice = 22179, -- 198054
        repentance = 22180, -- 20066
        blinding_light = 21811, -- 115750

        retribution_aura = 22433, -- 203797
        cavalier = 22434, -- 230332
        blessing_of_spellwarding = 22435, -- 204018

        unbreakable_spirit = 22705, -- 114154
        final_stand = 21795, -- 204077
        hand_of_the_protector = 17601, -- 213652

        judgment_of_light = 22189, -- 183778
        consecrated_ground = 22438, -- 204054
        aegis_of_light = 23087, -- 204150

        last_defender = 21201, -- 203791
        righteous_protector = 21202, -- 204074
        seraphim = 22645, -- 152262
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3469, -- 208683
        adaptation = 3470, -- 214027
        relentless = 3471, -- 196029
        shield_of_virtue = 861, -- 215652
        warrior_of_light = 860, -- 210341
        inquisition = 844, -- 207028
        cleansing_light = 3472, -- 236186
        holy_ritual = 3473, -- 199422
        luminescence = 3474, -- 199428
        unbound_freedom = 3475, -- 199325
        hallowed_ground = 90, -- 216868
        steed_of_glory = 91, -- 199542
        judgments_of_the_pure = 93, -- 216860
        guarded_by_the_light = 97, -- 216855
        guardian_of_the_forgotten_queen = 94, -- 228049
        sacred_duty = 92, -- 216853
    } )

    -- Auras
    spec:RegisterAuras( {
        aegis_of_light = {
            id = 204150,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        ardent_defender = {
            id = 31850,
            duration = 8,
            max_stack = 1,
        },
        avengers_shield = {
            id = 31935,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        avengers_valor = {
            id = 197561,
            duration = 15,
            max_stack = 1,
        },
        avenging_wrath = {
            id = 31884,
            duration = function () return azerite.lights_decree.enabled and 25 or 20 end,
            max_stack = 1,
        },
        blessed_hammer = {
            id = 204301,
            duration = 10,
            max_stack = 1,
        },
        blessing_of_freedom = {
            id = 1044,
            duration = function () return ( ( level < 116 and equipped.uthers_guard ) and 1.5 or 1 ) * 8 end,
            type = "Magic",
            max_stack = 1,
        },
        blessing_of_protection = {
            id = 1022,
            duration = function () return ( ( level < 116 and equipped.uthers_guard ) and 1.5 or 1 ) * 10 end,
            max_stack = 1,
            type = "Magic",
        },
        blessing_of_sacrifice = {
            id = 6940,
            duration = function () return ( ( level < 116 and equipped.uthers_guard ) and 1.5 or 1 ) * 12 end,
            max_stack = 1,
            type = "Magic",
        },
        blessing_of_spellwarding = {
            id = 204018,
            duration = function () return ( ( level < 116 and equipped.uthers_guard ) and 1.5 or 1 ) * 10 end,
            type = "Magic",
            max_stack = 1,
        },
        blinding_light = {
            id = 115750,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        consecration = {
            id = 188370,
            duration = 12,
            max_stack = 1,
            generate = function( c, type )
                if type == "buff" and FindUnitBuffByID( "player", 188370 ) then
                    local dropped, expires
                    
                    for i = 1, 5 do
                        local up, name, start, duration = GetTotemInfo( i )

                        if up and name == class.abilities.consecration.name then
                            dropped = start
                            expires = dropped + duration
                            break
                        end
                    end

                    if dropped and expires > query_time then
                        c.expires = expires
                        c.applied = dropped
                    c.count = 1
                    c.caster = "player"
                    return
                end
                end

                c.count = 0
                c.expires = 0
                c.applied = 0
                c.caster = "unknown"
            end
        },
        consecration_dot = {
            id = 204242,
            duration = 12,
            max_stack = 1,
        },
        contemplation = {
            id = 121183,
        },
        divine_shield = {
            id = 642,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        divine_steed = {
            id = 221883,
            duration = 3,
            max_stack = 1,
        },
        final_stand = {
            id = 204079,
            duration = 8,
            max_stack = 1,
        },
        forbearance = {
            id = 25771,
            duration = 30,
            max_stack = 1,
        },
        grand_crusader = {
            id = 85043,
        },
        guardian_of_ancient_kings = {
            id = 86659,
            duration = 8,
            max_stack = 1,
        },
        hammer_of_justice = {
            id = 853,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        hand_of_reckoning = {
            id = 62124,
            duration = 3,
            max_stack = 1,
        },
        heart_of_the_crusader = {
            id = 32223,
        },
        judgment_of_light = {
            id = 196941,
            duration = 30,
            max_stack = 25,
        },
        redoubt = {
            id = 280375,
            duration = 8,
            max_stack = 1,
        },
        repentance = {
            id = 20066,
            duration = 6,
            max_stack = 1,
        },
        retribution_aura = {
            id = 203797,
            duration = 3600,
            max_stack = 1,
        },
        seraphim = {
            id = 152262,
            duration = 16,
            max_stack = 1,
        },
        shield_of_the_righteous = {
            id = 132403,
            duration = 4.5,
            max_stack = 1,
        },
        shield_of_the_righteous_icd = {
            duration = 1,
            max_stack = 1,
            generate = function( t, type )
                if type ~= "buff" then return end

                local applied = action.shield_of_the_righteous.lastCast

                if applied > 0 then
                    t.applied = applied
                    t.expires = applied + 1
                    t.count = 1
                    t.caster = "player"
                end
            end,
        },


        -- Azerite Powers
        empyreal_ward = {
            id = 287731,
            duration = 60,
            max_stack = 1,
        },

    } )


    -- Gear Sets
    spec:RegisterGear( 'tier19', 138350, 138353, 138356, 138359, 138362, 138369 )
    spec:RegisterGear( 'tier20', 147160, 147162, 147158, 147157, 147159, 147161 )
        spec:RegisterAura( 'sacred_judgment', {
            id = 246973,
            duration = 8,
            max_stack = 1,
        } )        

    spec:RegisterGear( 'tier21', 152151, 152153, 152149, 152148, 152150, 152152 )
    spec:RegisterGear( 'class', 139690, 139691, 139692, 139693, 139694, 139695, 139696, 139697 )

    spec:RegisterGear( "breastplate_of_the_golden_valkyr", 137017 )
    spec:RegisterGear( "heathcliffs_immortality", 137047 )
    spec:RegisterGear( 'justice_gaze', 137065 )
    spec:RegisterGear( "saruans_resolve", 144275 )
    spec:RegisterGear( "tyelca_ferren_marcuss_stature", 137070 )
    spec:RegisterGear( "tyrs_hand_of_faith", 137059 )
    spec:RegisterGear( "uthers_guard", 137105 )

    spec:RegisterGear( "soul_of_the_highlord", 151644 )
    spec:RegisterGear( "pillars_of_inmost_light", 151812 )    


    spec:RegisterStateExpr( "last_consecration", function () return action.consecration.lastCast end )
    spec:RegisterStateExpr( "last_blessed_hammer", function () return action.blessed_hammer.lastCast end )
    spec:RegisterStateExpr( "last_shield", function () return action.shield_of_the_righteous.lastCast end )

    spec:RegisterStateExpr( "consecration", function () return buff.consecration end )

    spec:RegisterHook( "reset_precast", function ()
        last_consecration = nil
        last_blessed_hammer = nil
        last_shield = nil
    end )


    -- Abilities
    spec:RegisterAbilities( {
        aegis_of_light = {
            id = 204150,
            cast = 6,
            channeled = true,
            cooldown = 180,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,


            startsCombat = false,
            texture = 135909,

            start = function ()
                applyBuff( "aegis_of_light" )
            end,
        },


        ardent_defender = {
            id = 31850,
            cast = 0,
            cooldown = function ()
                return ( talent.unbreakable_spirit.enabled and 0.7 or 1 ) * ( ( level < 116 and equipped.pillars_of_inmost_light ) and 0.75 or 1 ) * 120 end,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 135870,

            handler = function ()
                applyBuff( "ardent_defender" )
            end,
        },


        avengers_shield = {
            id = 31935,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            interrupt = true,

            startsCombat = true,
            texture = 135874,

            handler = function ()
                applyBuff( "avengers_valor" )
                applyDebuff( "target", "avengers_shield" )
                interrupt()

                if level < 116 and equipped.breastplate_of_the_golden_valkyr then
                    cooldown.guardian_of_ancient_kings.expires = cooldown.guardian_of_ancient_kings.expires - ( 3 * min( 3 + ( talent.redoubt.enabled and 1 or 0 ) + ( equipped.tyelca_ferren_marcuss_stature and 2 or 0 ), active_enemies ) )
                end

                if talent.redoubt.enabled then
                    applyBuff( "redoubt" ) 
                end
            end,
        },


        avenging_wrath = {
            id = 31884,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 135875,

            handler = function ()
                applyBuff( "avenging_wrath" )
                applyBuff( "avenging_wrath_crit" )
            end,
        },


        bastion_of_light = {
            id = 204035,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 535594,

            talent = "bastion_of_light",

            handler = function ()
                gainCharges( "shield_of_the_righteous", 3 )
            end,
        },


        blessed_hammer = {
            id = 204019,
            cast = 0,
            charges = 3,
            cooldown = 4.5,
            recharge = 4.5,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 535595,

            talent = "blessed_hammer",

            handler = function ()
                applyDebuff( "target", "blessed_hammer" )
                last_blessed_hammer = query_time
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
                applyBuff( "blessing_of_freedom" )
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

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 135964,

            notalent = "blessing_of_spellwarding",

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                applyBuff( "blessing_of_protection" )
                applyDebuff( "player", "forbearance" )
            end,
        },


        blessing_of_sacrifice = {
            id = 6940,
            cast = 0,
            charges = 1,
            cooldown = 120,
            recharge = 120,
            gcd = "off",

            spend = 0.07,
            spendType = "mana",

            defensives = true,

            startsCombat = false,
            texture = 135966,

            handler = function ()
                applyBuff( "blessing_of_sacrifice" )
            end,
        },


        blessing_of_spellwarding = {
            id = 204018,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            spend = 0.15,
            spendType = "mana",

            -- toggle = "cooldowns",
            defensives = true,

            startsCombat = false,
            texture = 135880,

            talent = "blessing_of_spellwarding",

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                applyBuff( "blessing_of_spellwarding" )
                applyDebuff( "player", "forbearance" )
            end,
        },


        blinding_light = {
            id = 115750,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            interrupt = true,

            startsCombat = true,
            texture = 571553,

            toggle = "interrupts",

            talent = "blinding_light",
            usable = function () return target.casting end,
            readyTime = function () return debuff.casting.up and ( debuff.casting.remains - 0.5 ) or 3600 end,
            handler = function ()
                interrupt()
                applyDebuff( "target", "blinding_light" )
                active_dot.blinding_light = max( active_enemies, active_dot.blinding_light )
            end,
        },


        cleanse_toxins = {
            id = 213644,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 135953,

            handler = function ()
            end,
        },


        consecration = {
            id = 26573,
            cast = 0,
            cooldown = 4.5,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 135926,

            handler = function ()
                applyBuff( "consecration", 12 )
                applyDebuff( "target", "consecration_dot" )
                last_consecration = query_time
            end,
        },


        --[[ contemplation = {
            id = 121183,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            startsCombat = true,
            texture = 134916,

            handler = function ()
            end,
        }, ]]


        divine_shield = {
            id = 642,
            cast = 0,
            cooldown = function () return ( talent.unbreakable_spirit.enabled and 0.7 or 1 ) * 300 end,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 524354,

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                applyBuff( "divine_shield" )
                applyDebuff( "player", "forbearance" )

                if talent.last_defender.enabled then
                    applyDebuff( "target", "final_stand" )
                    active_dot.final_stand = min( active_dot.final_stand, active_enemies )
                end
            end,
        },


        divine_steed = {
            id = 190784,
            cast = 0,
            charges = function () return talent.cavalier.enabled and 2 or nil end,
            cooldown = 45,
            recharge = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 1360759,

            handler = function ()
                applyBuff( "divine_steed" )
            end,
        },


        flash_of_light = {
            id = 19750,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.22,
            spendType = "mana",

            startsCombat = false,
            texture = 135907,

            handler = function ()
                gain( 0.5 * health.max, "health" )
            end,
        },


        guardian_of_ancient_kings = {
            id = 86659,
            cast = 0,
            cooldown = 300,
            gcd = "off",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 135919,

            handler = function ()
                applyBuff( "guardian_of_ancient_kings" )
            end,
        },


        hammer_of_justice = {
            id = 853,
            cast = 0,
            cooldown = function () return ( level < 116 and equipped.justice_gaze ) and 15 or 60 end,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 135963,

            handler = function ()
                applyDebuff( "target", "hammer_of_justice" )
            end,
        },


        hammer_of_the_righteous = {
            id = 53595,
            cast = 0,
            charges = 2,
            cooldown = 4.5,
            recharge = 4.5,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 236253,

            notalent = "blessed_hammer",

            handler = function ()
            end,
        },


        hand_of_reckoning = {
            id = 62124,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "off",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 135984,

            handler = function ()
                applyDebuff( "target", "hand_of_reckoning" )
            end,
        },


        hand_of_the_protector = {
            id = 213652,
            cast = 0,
            charges = function () return ( level < 116 and equipped.saruans_resolve ) and 2 or nil end,
            cooldown = function () return ( ( level < 116 and equipped.saruans_resolve ) and 0.9 or 1 ) * 15 * haste end,
            recharge = function () return ( ( level < 116 and equipped.saruans_resolve ) and 0.9 or 1 ) * 15 * haste end,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 236248,

            talent = "hand_of_the_protector",

            handler = function ()
                if buff.avenging_wrath_crit.up then removeBuff( "avenging_wrath_crit" ) end
                gain( 0.1 * health.max, "health" )
            end,
        },


        judgment = {
            id = 275779,
            cast = 0,
            charges = function () return talent.crusaders_judgment.enabled and 2 or nil end,
            cooldown = 6,
            recharge = 6,
            hasteCD = true,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 135959,

            handler = function ()
                applyDebuff( "target", "judgment" )

                if talent.judgment_of_light.enabled then applyDebuff( "target", "judgment_of_light", 30, 25 ) end

                if talent.fist_of_justice.enabled then
                    cooldown.hammer_of_justice.expires = max( 0, cooldown.hammer_of_justice.expires - 6 ) 
                end
            end,
        },


        lay_on_hands = {
            id = 633,
            cast = 0,
            cooldown = function () return ( ( level < 116 and equipped.tyrs_hand_of_faith ) and 0.3 or 1 ) * ( talent.unbreakable_spirit.enabled and 0.7 or 1 ) * 600 end,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 135928,

            readyTime = function () return debuff.forbearance.remains end,

            handler = function ()
                gain( health.max, "health" )
                applyDebuff( "player", "forbearance" )
                if azerite.empyreal_ward.enabled then applyBuff( "empyrael_ward" ) end
            end,
        },


        light_of_the_protector = {
            id = 184092,
            cast = 0,
            charges = function () return ( level < 116 and equipped.saruans_resolve ) and 2 or nil end,
            cooldown = function () return ( ( level < 116 and equipped.saruans_resolve ) and 0.9 or 1 ) * 17 * haste end,
            recharge = function () return ( ( level < 116 and equipped.saruans_resolve ) and 0.9 or 1 ) * 17 * haste end,
            hasteCD = true,
            gcd = "spell",

            toggle = "defensives",
            defensives = true,

            startsCombat = false,
            texture = 1360763,

            notalent = "hand_of_the_protector",

            handler = function ()
                if buff.avenging_wrath_crit.up then removeBuff( "avenging_wrath_crit" ) end
                gain( 0.1 * health.max, "health" )
            end,
        },


        rebuke = {
            id = 96231,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 523893,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        --[[ redemption = {
            id = 7328,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 135955,

            handler = function ()
            end,
        }, ]]


        repentance = {
            id = 20066,
            cast = 1.7,
            cooldown = 15,
            gcd = "spell",

            interrupt = true,

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 135942,

            handler = function ()
                applyDebuff( "target", "repentance" )
            end,
        },


        seraphim = {
            id = 152262,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 1030103,

            usable = function () return cooldown.shield_of_the_righteous.charges > 0 end,
            handler = function ()
                local used = min( 2, cooldown.shield_of_the_righteous.charges )
                applyBuff( "seraphim", used * 8 )
                spendCharges( "shield_of_the_righteous", used )
            end,
        },


        shield_of_the_righteous = {
            id = 53600,
            cast = 0,
            charges = 3,
            cooldown = 18,
            recharge = 18,
            hasteCD = true,
            gcd = "off",

            defensives = true,

            startsCombat = true,
            texture = 236265,

            readyTime = function () return max( gcd.remains, buff.shield_of_the_righteous_icd.remains, ( not talent.bastion_of_light.enabled or cooldown.bastion_of_light.remains > 0 ) and ( recharge * ( 2 - charges_fractional ) ) or 0 ) end,
            handler = function ()
                removeBuff( "avengers_valor" )

                applyBuff( "shield_of_the_righteous", buff.shield_of_the_righteous.remains + 4.5 )
                applyBuff( "shield_of_the_righteous_icd" )

                if talent.righteous_protector.enabled then
                    cooldown.light_of_the_protector.expires = max( 0, cooldown.light_of_the_protector.expires - 3 )
                    cooldown.hand_of_the_protector.expires = max( 0, cooldown.hand_of_the_protector.expires - 3 )
                    cooldown.avenging_wrath.expires = max( 0, cooldown.avenging_wrath.expires - 3 )
                end

                last_shield = query_time
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

        package = "Protection Paladin",
    } )


    spec:RegisterPack( "Protection Paladin", 20200410, [[diKnVaqiuspcLqBss1OiPCkssRcLGxjjmljr3ssj1UG6xaQHjjDmsOLPc6zsk10aOUMkW2ijY3uHuJJKaoNKsSoscQ5jP4EKO9Hs0bLuswijvpKKGmrscuxKKOQtssGSsaStuQgkjrzPKevEkqtfLYEH8xsnyQ6WuwmOEmvMSexgzZc(miJwjNwQvdqETkuZwOBRs7wXVv1WrXYr1ZjA6IUUsTDsW3bKXRcX5vHK1tsO5RI2pHrkIydbwSKqSFy1dRwfWkwfxTwQDvfvebMhfdHazm3XgeHah7siqvg)tYL9pcVkZIwPheiJDuX3ki2qGYFZDecCLjJufgyGH6CTHXU)cSSV7OL9poUfsGL91bmceE3Xuf0GGrGflje7hw9WQvbSIvXvRLAxT6biqBNRNJab7RkecC1LcniyeyHKoeilk8Qm(NKl7FeEvMfTspcayrHFLjJufgyGH6CTHXU)cSSV7OL9poUfsGL91bSaawu4Rvm8ok8kwTsH)WQhwvaGaawu4vHw2arsbaSOWxRf(AvPqfHxLJG3htyeySLPeXgc82zdzz)dIne7kIydbsJbhPcsDeOJ3jXBdbYQWNwKMeljUXS6lMgdosfHVUWBUS)blxnfl6pOZfP5n0kPFlXULXHiPWZsH)qHVUWZQWRMWdVdbSrqTu)bDSHwjEZi81fE4DiGnEHMuxOanfIJ3mcFDHhEhcyOTXlTn6pOTX10K6J7bsI3mcFDHhEhc4sRqpKwUAkwWBgHVUWdVdbmZN9p4nJWRkc0Cz)dcuUAkw0FqNlsZBOvs)wIse7hIydbsJbhPcsDeOJ3jXBdbYQWNwKMeljUXS6lMgdosfHVUWNwKMedBYS)r)bDSHwjMgdosfHVUWBUS)blxnfl6pOZfP5n0kPFlXULXHiPWxJWRic0Cz)dce2Kz)J(d6ydTsuIyV2i2qG0yWrQGuhb64Ds82qGQj8lYI5cZ4sHVgHhWvfEvrGMl7FqGXgAL6pOZfPz4FsU85OeXoGrSHaPXGJubPoc0X7K4THavt4xKfZfMXLcFncpGRk8QIanx2)Gax2u0FqNlsZW)KC5ZrjI9dqSHaPXGJubPoc0X7K4THavt47X93EG0f7AqKwXQvRw9kf(Ae(fzXCHV2reEwq4veF4bcVQcFDHFrwmxygxk81i8hCGWxx4tlstI5n0kPFl1m8pjx(CmngCKkiqZL9piWydTs9h05I0m8pjx(CuIyxLqSHaPXGJubPoc0X7K4THavt47X93EG0f7AqKwXAxTA1Ru4Rr4xKfZf(Ahr4zbHxrSkj8Qk81f(fzXCHzCPWxJWFWbiqZL9piWydTs9h05I0m8pjx(CuIy)OrSHaPXGJubPoc0X7K4THavt47X93EG0f7AqKwLQwT6vk81i8lYI5cFTJi8SGWxfF0cVQcFDHFrwmxygxk81i8Q0bcFDHpTinjM3qRK(TuZW)KC5ZX0yWrQGanx2)Gax2u0FqNlsZW)KC5ZrjIDvaeBiqAm4ivqQJaD8ojEBiq1e(EC)ThiDXUgePRLQvRELcFnc)ISyUWx7icpli8kIpu4vv4Rl8lYI5cZ4sHVgH)GdqGMl7FqGlBk6pOZfPz4FsU85OeXETGydbsJbhPcsDeOJ3jXBdbYQWNwKMeljUXS6lMgdosfHVUW3J7V9aPl21Gi9HhuT6vk8Su4xKfZf(Ahr4zbHVkgWcFDHNvHxnHhEhcyJGAP(d6ydTs8Mr4ppfE4DiGnEHMuxOanfIJ3mc)5PWdVdbm024L2g9h024AAs9X9ajXBgH)8u4H3HaU0k0dPLRMIf8Mr4ppfE4DiGz(S)bVzeEvrGMl7FqGgb1s9h0XgALOeXUIvrSHaPXGJubPoc0X7K4THazv4tlstILe3yw9ftJbhPIWxx47X93EG0f7AqK(WdQw9kfEwk8lYI5cFTJi8SGWxfdyHVUWZQWRMWdVdbSrqTu)bDSHwjEZi8NNcp8oeWgVqtQluGMcXXBgH)8u4H3HagAB8sBJ(dABCnnP(4EGK4nJWFEk8W7qaxAf6H0YvtXcEZi8NNcp8oeWmF2)G3mcVQiqZL9piqOTXlTn6pOTX10K6J7bsIse7kQiIneingCKki1rGoENeVneiRcFArAsSK4gZQVyAm4ive(6cFArAsCOhlQLPnfmngCKkcFDHVh3F7bsxSRbr6dpOA1Ru4zPWVilMl81oIWZccFvmGf(6cpRcVAcp8oeWgb1s9h0XgAL4nJWFEk8W7qaB8cnPUqbAkehVze(ZtHhEhcyOTXlTn6pOTX10K6J7bsI3mc)5PWdVdbCPvOhslxnfl4nJWFEk8W7qaZ8z)dEZi8QIanx2)GalTc9qA5QPybLi2v8qeBiqAm4ivqQJaD8ojEBiqwf(0I0KyjXnMvFX0yWrQi81f(EC)ThiDXUgePp8GQvVsHNLc)ISyUWx7icpli8vXaw4Rl8Sk8Qj8W7qaBeul1FqhBOvI3mc)5PWdVdbSXl0K6cfOPqC8Mr4ppfE4DiGH2gV02O)G2gxttQpUhijEZi8NNcp8oeWLwHEiTC1uSG3mc)5PWdVdbmZN9p4nJWRkc0Cz)dc04fAsDHc0uiokrSRyTrSHaPXGJubPoc0X7K4THazv4tlstILe3yw9ftJbhPIWxx4xKfZfMXLcFncVIhGanx2)GaJ2rP)rVSPirjkrGU)JLhOrIydXUIi2qG0yWrQGuhb64Ds82qGW7qaBkqdupqAG4wUWBgeO5Y(heyO5eC8)ckrSFiIneingCKki1rGMl7FqGMkkxg3K6WpP(dAMhiIJaD8ojEBiq3)XYd0GLe3yw9fZPR1Ju4RrPWRyvH)8u4zv4tlstILe3yw9ftJbhPccCSlHanvuUmUj1HFs9h0mpqehLi2RnIneingCKki1rGMl7FqGMCPGnKuZnv85A3ZTic0X7K4THavt4le8oeWCtfFU29ClQle8oeWY0Chl8Su4pAHVUWdVdbSPanq9aPbIB5cVzeEvf(ZtHVqW7qaZnv85A3ZTOUqW7qaltZDSWRu4RIah7siqtUuWgsQ5Mk(CT75weLi2bmIneingCKki1rGoENeVneO7)y5bAWYvtXI(d6CrAEdTs63sSBzCisQdCZL9pwu4zPsH)qeO5Y(heOK4gZQVOeX(bi2qG0yWrQGuhb64Ds82qGW7qaljUXS6lEZi8NNcV7)y5bAWsIBmR(I5016rk81i8hk8NNcpRcFArAsSK4gZQVyAm4ivqGMl7FqGMc0a1dKgiULluIyxLqSHaPXGJubPoc0X7K4THaD)hlpqdwUAkw0FqNlsZBOvs)wIDlJdrsDGBUS)XIcFnkf(Q4dqGMl7FqGWMm7F0FqhBOvIse7hnIneingCKki1rGoENeVnei8oeWMc0a1dKgiULl8MbbAUS)bbY8z)dkrSRcGydbsJbhPcsDeOJ3jXBdbcVdbSK4gZQV4nJWFEk8Sk8PfPjXsIBmR(IPXGJubbAUS)bbULKUt6krjI9AbXgcKgdosfK6iqZL9piqi(pqsndVVwuZnicb64Ds82qGQj8Qj8U)JLhObdODb6stId7yuZj3Y4qKo7lj8Su4bSWFEk8Qj8Sk8PfPjXo(wAfIl1aAxGU0KyAm4ive(6cpdNuqd5kyfXaAxGU0KcVQcVQcFDH39FS8anytbAGiUulxnflyoDTEKcplfEal81fE4DiGLe3yw9fZPR1Ju4zPWdyHxvH)8u4vt4H3HawsCJz1xmNUwpsHVgHhWcVQiWXUeceI)dKuZW7Rf1CdIqjIDfRIydbsJbhPcsDeO5Y(he4L40X5YK6GnqiqhVtI3gcKvHhEhcytbAG6bsde3YfEZi81fE1eE4DiGLe3yw9fVze(ZtHNvHpTinjwsCJz1xmngCKkcVQiWXUec8sC64CzsDWgiuIyxrfrSHaPXGJubPocCSlHa5Mkw2ZXsnCdP5urdVZ8heO5Y(hei3uXYEowQHBinNkA4DM)GsuIaluW2XeXgIDfrSHanx2)Ga5e8(ycbsJbhPcsDuIy)qeBiqAm4ivqQJanx2)GaDwmQnx2)OJTmrGXwM6XUec09FS8ansuIyV2i2qG0yWrQGuhbAUS)bb6SyuBUS)rhBzIaJTm1JDje4TZgYY(huIyhWi2qG0yWrQGuhb64Ds82qGW7qah7abh)VGLP5ow4Rr4Rnc0Cz)dceONhlkq9O5K8hBCekrSFaIneingCKki1rGoENeVneOAcp8oeWMc0arCPwbl(C8Mr4Rl8U)JLhOblxnfl6pOZfP5n0kPFlXULXHiPoWnx2)yrHNLkf(dXhi8Qk81fE1eE3)XYd0GLe3yw9fZPR1Ju4zPWd5kc)5PWZQWNwKMeljUXS6lMgdosfHxveO5Y(heOC1uSO)GoxKM3qRK(TeLi2vjeBiqAm4ivqQJaD8ojEBiq1eE4DiGnfObQhinqClx4nJWxx4zv4tlstILe3yw9ftJbhPIWRQWFEk8W7qaljUXS6lEZi81fE4DiGnfObI4sTcw854ndc0Cz)dcuUAkw0FqNlsZBOvs)wIse7hnIneingCKki1rGoENeVneOAcp8oeWMc0a1dKgiULl8Mr4Rl8W7qaBkqdupqAG4wUWC6A9if(AeEal81fEwf(0I0KyjXnMvFX0yWrQi8Qk8NNcVAcp8oeWsIBmR(I5016rk81i8aw4Rl8W7qaljUXS6lEZi8QIanx2)GaLRMIf9h05I08gAL0VLOeXUkaIneingCKki1rGoENeVnei8oeWsIBmR(I3mcFDHhEhcyjXnMvFXC6A9if(Ae(AJanx2)GaJn0kLAaTlqxAsuIyVwqSHaPXGJubPoc0X7K4THazv4D)ijh3Y(h8MbbAUS)bb6(rsoUL9pOeXUIvrSHaPXGJubPoc0X7K4THavt4D)hlpqdgq7c0LMeZPR1Ju4Rr4HCfHVUW7(pwEGgmG2fOlnj2Tmoej1bU5Y(hlk8Su4vu4Rl8U)JLhOrZjZLcVQc)5PWZQWNwKMe74BPviUudODb6stIPXGJubbAUS)bbcODb6stIse7kQiIneingCKki1rGoENeVneO7)y5bA0CYCjc0Cz)dc0uGgiIl1YvtXckrSR4Hi2qG0yWrQGuhb64Ds82qGU)JLhOrZjZLc)5PWZQWNwKMe74BPviUudODb6stIPXGJubbAUS)bbcODb6stIse7kwBeBiqAm4ivqQJaD8ojEBiq1eEwf(0I0KyjXnMvFX0yWrQi8NNcp8oeWsIBmR(I3mcVQcFDHNvHV8j29JJMKBjv0HODjn8MpyoDTEKcplf(Qc)5PWtsjnocNls74Bxdhj9h0HODjm3MJf(Ae(AJanx2)GaD)4Oj5wsfDiAxcLi2veWi2qG0yWrQGuhb64Ds82qGSk8PfPjXsIBmR(IPXGJur4ppfE4DiGLe3yw9fVzqGMl7FqGXgALsnG2fOlnjkrSR4bi2qGMl7FqG20xt)bDHSCHaPXGJubPokrSROkHydbsJbhPcsDeO5Y(heiCKKsQOx29sCeOm59XKebwBuIyxXJgXgc0Cz)dcCz3lX1FqNlsZBOvs)wIaPXGJubPokrSROkaIneO5Y(heO7hj54w2)GaPXGJubPokrSRyTGydbsJbhPcsDeOJ3jXBdbYQWRMWtsjnocNls74Bxdhj9h0HODj81a0Zf(ZtHNKsACegONhlkq9O5K8hBCe(Aa65c)5PWtsjnocBtFn9h0XoqABk6cz5cFna9CH)8u4jPKghHV095hL(d6421fDHt2vIVgGEUWRkc0Cz)dcCrgp1KusJJqjkrGmCY9xylrSHyxreBiqAm4ivqQJse7hIydbsJbhPcsDuIyV2i2qG0yWrQGuhLi2bmIneingCKki1rjI9dqSHanx2)Gaz(S)bbsJbhPcsDuIyxLqSHanx2)GaJn0kLAaTlqxAseingCKki1rjkrjcubIl7FqSFyvfRLQ1YHhGabY4tpqseOkOlZZtQi8aw4nx2)i8XwMsSaaeOKHCi2vjvcbYW)qhjeilk8Qm(NKl7FeEvMfTspcayrHFLjJufgyGH6CTHXU)cSSV7OL9poUfsGL91bSaawu4Rvm8ok8kwTsH)WQhwvaGaawu4vHw2arsbaSOWxRf(AvPqfHxLJG3htybacayrHxL)iKBNur4HPWZjH39xylfEycQhjw4RvohXKsHF(PwVm(nSJcV5Y(hPW)t8OWcamx2)iXmCY9xylvgIM8ybaMl7FKygo5(lSLvOe4W)fbaMl7FKygo5(lSLvOeyBdDPjTS)raalk8GJXixFk8CRlcp8oeOIWltlLcpmfEoj8U)cBPWdtq9ifEBkcpdNQ1mFM9aj8Tu4l)qybaMl7FKygo5(lSLvOey5ymY1NAzAPuaG5Y(hjMHtU)cBzfkbM5Z(hbaMl7FKygo5(lSLvOe4ydTsPgq7c0LMuaGaawu4v5pc52jveEsbIFucF2xs4Zfj8MlFUW3sH3uW6ObhjSaaZL9psLCcEFmjaWCz)JScLa7SyuBUS)rhBzw5yxsP7)y5bAKcamx2)iRqjWolg1Ml7F0XwMvo2LuE7SHSS)raG5Y(hzfkbgONhlkq9O5K8hBCuLDqj8oeWXoqWX)lyzAUJRP2cayrHxf8(Y0dKWd(PkNW7wghIKcamx2)iRqjWYvtXI(d6CrAEdTs63Yk7Gs1G3Ha2uGgiIl1kyXNJ3m1D)hlpqdwUAkw0FqNlsZBOvs)wIDlJdrsDGBUS)XISu5H4duTUAU)JLhObljUXS6lMtxRhjlHCLZtwtlstILe3yw9ftJbhPIQcamx2)iRqjWYvtXI(d6CrAEdTs63Yk7Gs1G3Ha2uGgOEG0aXTCH3m1znTinjwsCJz1xmngCKkQEEcVdbSK4gZQV4ntD4DiGnfObI4sTcw854nJaaZL9pYkucSC1uSO)GoxKM3qRK(TSYoOun4DiGnfObQhinqClx4ntD4DiGnfObQhinqClxyoDTEK1a46SMwKMeljUXS6lMgdosfvppvdEhcyjXnMvFXC6A9iRbW1H3HawsCJz1x8MrvbaMl7FKvOe4ydTsPgq7c0LMSYoOeEhcyjXnMvFXBM6W7qaljUXS6lMtxRhzn1waG5Y(hzfkb29JKCCl7FQSdkz19JKCCl7FWBgbaMl7FKvOeyaTlqxAYk7Gs1C)hlpqdgq7c0LMeZPR1JSgixPU7)y5bAWaAxGU0Ky3Y4qKuh4Ml7FSilvSU7)y5bA0CYCPQNNSMwKMe74BPviUudODb6stIPXGJuraG5Y(hzfkb2uGgiIl1YvtXsLDqP7)y5bA0CYCPaaZL9pYkucmG2fOlnzLDqP7)y5bA0CYC55jRPfPjXo(wAfIl1aAxGU0KyAm4iveayUS)rwHsGD)4Oj5wsfDiAxQYoOunwtlstILe3yw9ftJbhPY5j8oeWsIBmR(I3mQwN1YNy3poAsULurhI2L0WB(G5016rYYQNNKusJJW5I0o(21Wrs)bDiAxcZT54AQTaaZL9pYkucCSHwPudODb6stwzhuYAArAsSK4gZQVyAm4ivopH3HawsCJz1x8MraG5Y(hzfkb2M(A6pOlKLlbaMl7FKvOey4ijLurVS7L4vktEFmjvwBbaMl7FKvOe4LDVex)bDUinVHwj9BPaaZL9pYkucS7hj54w2)iaWCz)JScLaViJNAskPXrv2bLSQgjL04iCUiTJVDnCK0FqhI2LWxdqp)8KKsACegONhlkq9O5K8hBCe(Aa65NNKusJJW20xt)bDSdK2MIUqwUWxdqp)8KKsACe(s3NFu6pOJBxx0fozxj(Aa65QkaqaG5Y(hj29FS8ansLHMtWX)lv2bLW7qaBkqdupqAG4wUWBgbaMl7FKy3)XYd0iRqjWBjP7KUvo2LuAQOCzCtQd)K6pOzEGiELDqP7)y5bAWsIBmR(I5016rwJsfREEYAArAsSK4gZQVyAm4iveayUS)rID)hlpqJScLaVLKUt6w5yxsPjxkydj1CtfFU29ClwzhuQwHG3HaMBQ4Z1UNBrDHG3HawMM7ywE01H3Ha2uGgOEG0aXTCH3mQEEwi4DiG5Mk(CT75wuxi4DiGLP5owzvbaMl7FKy3)XYd0iRqjWsIBmR(wzhu6(pwEGgSC1uSO)GoxKM3qRK(Te7wghIK6a3Cz)JfzPYdfayUS)rID)hlpqJScLaBkqdupqAG4wUQSdkH3HawsCJz1x8M5809FS8anyjXnMvFXC6A9iR5WZtwtlstILe3yw9ftJbhPIaaZL9psS7)y5bAKvOeyytM9p6pOJn0kRSdkD)hlpqdwUAkw0FqNlsZBOvs)wIDlJdrsDGBUS)XI1OSk(abaMl7FKy3)XYd0iRqjWmF2)uzhucVdbSPanq9aPbIB5cVzeayUS)rID)hlpqJScLaVLKUt6kRSdkH3HawsCJz1x8M58K10I0KyjXnMvFX0yWrQiaWCz)Je7(pwEGgzfkbEljDN0TYXUKsi(pqsndVVwuZniQYoOun1C)hlpqdgq7c0LMeh2XOMtULXHiD2xILa(8unwtlstID8T0kexQb0UaDPjX0yWrQuNHtkOHCfSIyaTlqxAsvvTU7)y5bAWMc0arCPwUAkwWC6A9izjGRdVdbSK4gZQVyoDTEKSeWQEEQg8oeWsIBmR(I5016rwdGvvaG5Y(hj29FS8anYkuc8ws6oPBLJDjLxIthNltQd2avzhuYk8oeWMc0a1dKgiULl8MPUAW7qaljUXS6lEZCEYAArAsSK4gZQVyAm4ivuvaG5Y(hj29FS8anYkuc8ws6oPBLJDjLCtfl75yPgUH0CQOH3z(JaabaMl7FK4BNnKL9pkLRMIf9h05I08gAL0VLv2bLSMwKMeljUXS6lMgdosL6Ml7FWYvtXI(d6CrAEdTs63sSBzCisYYdRZQAW7qaBeul1FqhBOvI3m1H3Ha24fAsDHc0uioEZuhEhcyOTXlTn6pOTX10K6J7bsI3m1H3HaU0k0dPLRMIf8MPo8oeWmF2)G3mQkaWCz)JeF7SHSS)PcLadBYS)r)bDSHwzLDqjRPfPjXsIBmR(IPXGJuPEArAsmSjZ(h9h0XgALyAm4ivQBUS)blxnfl6pOZfP5n0kPFlXULXHiznkkaWCz)JeF7SHSS)PcLahBOvQ)GoxKMH)j5YNxzhuQ2ISyUWmUSgaxvvbaMl7FK4BNnKL9pvOe4Lnf9h05I0m8pjx(8k7Gs1wKfZfMXL1a4QQkaWCz)JeF7SHSS)PcLahBOvQ)GoxKMH)j5YNxzhuQwpU)2dKUyxdI0kwTA1QxznlYI5cFTJWckIp8avRVilMlmJlR5GdQNwKMeZBOvs)wQz4FsU85yAm4iveayUS)rIVD2qw2)uHsGJn0k1FqNlsZW)KC5ZRSdkvRh3F7bsxSRbrAfRD1QvVYAwKfZf(AhHfueRsQwFrwmxygxwZbhiaWCz)JeF7SHSS)PcLaVSPO)GoxKMH)j5YNxzhuQwpU)2dKUyxdI0Qu1QvVYAwKfZf(AhHfQIpAvRVilMlmJlRrLoOEArAsmVHwj9BPMH)j5YNJPXGJuraG5Y(hj(2zdzz)tfkbEztr)bDUind)tYLpVYoOuTEC)ThiDXUgePRLQvREL1SilMl81oclOi(qvRVilMlmJlR5GdeayUS)rIVD2qw2)uHsGncQL6pOJn0kRSdkznTinjwsCJz1xmngCKk17X93EG0f7AqK(WdQw9kz5ISyUWx7iSqvmGRZQAW7qaBeul1FqhBOvI3mNNW7qaB8cnPUqbAkehVzopH3HagAB8sBJ(dABCnnP(4EGK4nZ5j8oeWLwHEiTC1uSG3mNNW7qaZ8z)dEZOQaaZL9ps8TZgYY(Nkucm024L2g9h024AAs9X9ajRSdkznTinjwsCJz1xmngCKk17X93EG0f7AqK(WdQw9kz5ISyUWx7iSqvmGRZQAW7qaBeul1FqhBOvI3mNNW7qaB8cnPUqbAkehVzopH3HagAB8sBJ(dABCnnP(4EGK4nZ5j8oeWLwHEiTC1uSG3mNNW7qaZ8z)dEZOQaaZL9ps8TZgYY(NkucCPvOhslxnflv2bLSMwKMeljUXS6lMgdosL6PfPjXHESOwM2uW0yWrQuVh3F7bsxSRbr6dpOA1RKLlYI5cFTJWcvXaUoRQbVdbSrqTu)bDSHwjEZCEcVdbSXl0K6cfOPqC8M58eEhcyOTXlTn6pOTX10K6J7bsI3mNNW7qaxAf6H0YvtXcEZCEcVdbmZN9p4nJQcamx2)iX3oBil7FQqjWgVqtQluGMcXRSdkznTinjwsCJz1xmngCKk17X93EG0f7AqK(WdQw9kz5ISyUWx7iSqvmGRZQAW7qaBeul1FqhBOvI3mNNW7qaB8cnPUqbAkehVzopH3HagAB8sBJ(dABCnnP(4EGK4nZ5j8oeWLwHEiTC1uSG3mNNW7qaZ8z)dEZOQaaZL9ps8TZgYY(NkucC0ok9p6LnfzLDqjRPfPjXsIBmR(IPXGJuP(ISyUWmUSgfpaLOeHa]] )


end
