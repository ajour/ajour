-- DruidGuardian.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DRUID' then
    local spec = Hekili:NewSpecialization( 104 )

    spec:RegisterResource( Enum.PowerType.Rage, {
        oakhearts_puny_quods = {
            aura = "oakhearts_puny_quods",

            last = function ()
                local app = state.buff.oakhearts_puny_quods.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 10
        },

        raging_frenzy = {
            aura = "frenzied_regeneration",
            pvptalent = "raging_frenzy",

            last = function ()
                local app = state.buff.frenzied_regeneration.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 10 -- tooltip says 60, meaning this would be 20, but NOPE.
        },
    } )

    spec:RegisterResource( Enum.PowerType.LunarPower )
    spec:RegisterResource( Enum.PowerType.Mana )
    spec:RegisterResource( Enum.PowerType.ComboPoints )
    spec:RegisterResource( Enum.PowerType.Energy )


    -- Talents
    spec:RegisterTalents( {
        brambles = 22419, -- 203953
        blood_frenzy = 22418, -- 203962
        bristling_fur = 22420, -- 155835

        tiger_dash = 19283, -- 252216
        ursols_vortex = 22916, -- 102793
        wild_charge = 18571, -- 102401

        balance_affinity = 22163, -- 197488
        feral_affinity = 22156, -- 202155
        restoration_affinity = 22159, -- 197492

        mighty_bash = 21778, -- 5211
        mass_entanglement = 18576, -- 102359
        typhoon = 18577, -- 132469

        soul_of_the_forest = 21709, -- 158477
        galactic_guardian = 21707, -- 203964
        incarnation = 22388, -- 102558

        earthwarden = 22423, -- 203974
        survival_of_the_fittest = 21713, -- 203965
        guardian_of_elune = 22390, -- 155578

        rend_and_tear = 22426, -- 204053
        lunar_beam = 22427, -- 204066
        pulverize = 22425, -- 80313
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3465, -- 196029
        gladiators_medallion = 3464, -- 208683
        adaptation = 3463, -- 214027

        malornes_swiftness = 1237, -- 236147
        alpha_challenge = 842, -- 207017
        master_shapeshifter = 49, -- 236144
        toughness = 50, -- 201259
        den_mother = 51, -- 236180
        demoralizing_roar = 52, -- 201664
        roaring_speed = 3054, -- 236148
        protector_of_the_pack = 197, -- 202043
        overrun = 196, -- 202246
        entangling_claws = 195, -- 202226
        charging_bash = 194, -- 228431
        sharpened_claws = 193, -- 202110
        raging_frenzy = 192, -- 236153
        clan_defender = 191, -- 213951
    } )


    -- Auras
    spec:RegisterAuras( {
        aquatic_form = {
            id = 276012,
            duration = 3600,
            max_stack = 1,
        },
        astral_influence = {
            id = 197524,
        },
        barkskin = {
            id = 22812,
            duration = 12,
            max_stack = 1,
        },
        bear_form = {
            id = 5487,
            duration = 3600,
            max_stack = 1,
        },
        bristling_fur = {
            id = 155835,
            duration = 8,
            max_stack = 1,
        },
        cat_form = {
            id = 768,
            duration = 3600,
            max_stack = 1,
        },
        dash = {
            id = 1850,
            duration = 10,
            max_stack = 1,
        },
        earth_warden = {
            id = 203975,
            duration = 0, -- persistent / removed by taking auto attacks
            max_stack = 3,
        },
        --[[ enrage_effect = {
            I am not sure if this could / would be done here or its even viable for recommending soothe, but could be good as it's instant, doesn't take you out of bear form, but there are a million enrage buffs
        } ]]
        entangling_roots = {
            id = 339,
            duration = 30,
            max_stack = 1,
        },
        feline_swiftness = {
            id = 131768,
        },
        flight_form = {
            id = 276029,
            duration = 3600,
            max_stack = 1,
        },
        frenzied_regeneration = {
            id = 22842,
            duration = 3,
            max_stack = 1,
        },
        galactic_guardian = {
            id = 213708,
            duration = 15,
            max_stack = 1,
        },
        gore = {
            id = 93622,
            duration = 10,
            max_stack =1,
        },
        growl = {
            id = 6795,
            duration = 3,
            max_stack = 1,
        },
        guardian_of_elune = {
            id = 213680,
            duration = 15,
            max_stack = 1,
        },
        hibernate = {
            id = 2637,
            duration = 40,
            max_stack = 1,
        },
        immobilized = {
            id = 45334,
            duration = 4,
            max_stack = 1,
        },
        incapacitating_roar = {
            id = 99,
            duration = 3,
            max_stack = 1,
        },
        incarnation = {
            id = 102558,
            duration = 30,
            max_stack = 1,
            copy = "incarnation_guardian_of_ursoc"
        },
        intimidating_roar = {
            id = 236748,
            duration = 3,
            max_stack = 1,
        },
        ironfur = {
            id = 192081,
            duration = function () return buff.guardian_of_elune.up and 9 or 7 end,
            max_stack = 5,
        },
        lightning_reflexes = {
            id = 231065,
        },
        lunar_empowerment = {
            id = 164547,
            duration = 45,
            max_stack = 3,
        },
        mass_entanglement = {
            id = 102359,
            duration = 30,
            max_stack = 1,
            type = "Magic",
        },
        mighty_bash = {
            id = 5211,
            duration = 5,
            max_stack = 1,
        },
        moonfire = {
            id = 164812,
            duration = 16,
            max_stack = 1,
            type = "Magic",
        },
        moonkin_form = {
            id = 197625,
            duration = 3600,
            max_stack = 1,
        },
        natural_defenses = {
            id = 211160,
            duration = 15,
            max_stack = 2,
        },
        prowl = {
            id = 5215,
            duration = 3600,
            max_stack = 1,
        },
        pulverize = {
            id = 158792,
            duration = 20,
            max_stack = 1,
        },
        regrowth = {
            id = 8936,
            duration = 12,
            max_stack = 1,
        },
        rejuvenation = {
            id = 774,
            duration = 15,
            max_stack = 1,
        },
        stampeding_roar = {
            id = 77761,
            duration = 8,
            max_stack = 1,
        },
        solar_empowerment = {
            id = 164545,
            duration = 45,
            max_stack = 3,
        },
        sunfire = {
            id = 164815,
            duration = 12,
            max_stack = 1,
            type = "Magic",
        },
        survival_instincts = {
            id = 61336,
            duration = 6,
            max_stack = 1,
        },
        thick_hide = {
            id = 16931,
        },
        thrash_bear = {
            id = 192090,
            duration = 16,
            max_stack = function () return ( ( level < 116 and equipped.elizes_everlasting_encasement ) and 5 or 3 ) end,
        },
        thrash_cat = {
            id = 106830,
            duration = 15,
            max_stack = 1,            
        },
        tiger_dash = {
            id = 252216,
            duration = 5,
            max_stack = 1,
        },
        travel_form = {
            id = 783,
            duration = 3600,
            max_stack = 1,
        },
        typhoon = {
            id = 61391,
            duration = 6,
            max_stack = 1,
            type = "Magic",
        },
        ursols_vortex = {
            id = 127797,
            duration = 3600,
            max_stack = 1,
        },
        wild_charge = {
            id = 102401,
        },
        wild_growth = {
            id = 48438,
            duration = 7,
            max_stack = 1,
        },
        yseras_gift = {
            id = 145108,
        },        


        -- PvP Talents
        demoralizing_roar = {
            id = 201664,
            duration = 8,
            max_stack = 1,
        },

        den_mother = {
            id = 236181,
            duration = 3600,
            max_stack = 1,
        },

        focused_assault = {
            id = 206891,
            duration = 6,
            max_stack = 1,
        },

        master_shapeshifter_feral = {
            id = 236188,
            duration = 3600,
            max_stack = 1,
        },

        overrun = {
            id = 202244,
            duration = 3,
            max_stack = 1,
        },

        protector_of_the_pack = {
            id = 201940,
            duration = 3600,
            max_stack = 1,
        },

        sharpened_claws = {
            id = 279943,
            duration = 6,
            max_stack = 1,
        },

        -- Azerite
        masterful_instincts = {
            id = 273349,
            duration = 30,
            max_stack = 1,
        }
    } )


    -- Function to remove any form currently active.
    spec:RegisterStateFunction( "unshift", function()
        removeBuff( "cat_form" )
        removeBuff( "bear_form" )
        removeBuff( "travel_form" )
        removeBuff( "moonkin_form" )
    end )


    -- Function to apply form that is passed into it via string.
    spec:RegisterStateFunction( "shift", function( form )
        unshift()
        applyBuff( form )
    end )

    spec:RegisterStateExpr( "ironfur_damage_threshold", function ()
        return ( settings.ironfur_damage_threshold or 0 ) / 100 * ( health.max )
    end )


    -- Gear.
    spec:RegisterGear( 'class', 139726, 139728, 139723, 139730, 139725, 139729, 139727, 139724 )
    spec:RegisterGear( 'tier19', 138330, 138336, 138366, 138324, 138327, 138333 )
    spec:RegisterGear( 'tier20', 147136, 147138, 147134, 147133, 147135, 147137 ) -- Bonuses NYI
    spec:RegisterGear( 'tier21', 152127, 152129, 152125, 152124, 152126, 152128 )

    spec:RegisterGear( 'ailuro_pouncers', 137024 )
    spec:RegisterGear( 'behemoth_headdress', 151801 )
    spec:RegisterGear( 'chatoyant_signet', 137040 )        
    spec:RegisterGear( "dual_determination", 137041 )
    spec:RegisterGear( 'ekowraith_creator_of_worlds', 137015 )
    spec:RegisterGear( "elizes_everlasting_encasement", 137067 )
    spec:RegisterGear( 'fiery_red_maimers', 144354 )
    spec:RegisterGear( "lady_and_the_child", 144295 )
    spec:RegisterGear( 'luffa_wrappings', 137056 )
    spec:RegisterGear( "oakhearts_puny_quods", 144432 )
        spec:RegisterAura( "oakhearts_puny_quods", {
            id = 236479,
            duration = 3,
            max_stack = 1,
        } )
    spec:RegisterGear( "skysecs_hold", 137025 )
        spec:RegisterAura( "skysecs_hold", {
            id = 208218,
            duration = 3,
            max_stack = 1,
        } )

    spec:RegisterGear( 'the_wildshapers_clutch', 137094 )


    spec:RegisterGear( 'soul_of_the_archdruid', 151636 )


    spec:RegisterHook( "reset_precast", function ()
        if azerite.masterful_instincts.enabled and buff.survival_instincts.up and buff.masterful_instincts.down then
            applyBuff( "masterful_instincts", buff.survival_instincts.remains + 30 )
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        alpha_challenge = {
            id = 207017,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            pvptalent = "alpha_challenge",

            startsCombat = true,
            texture = 132270,

            handler = function ()
                applyDebuff( "target", "focused_assault" )
            end,
        },


        barkskin = {
            id = 22812,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            startsCombat = false,
            texture = 136097,

            toggle = "defensives",
            defensive = true,

            usable = function ()
                if not tanking then return false, "player is not tanking right now"
                elseif incoming_damage_3s == 0 then return false, "player has taken no damage in 3s" end
                return true
            end,
            handler = function ()
                applyBuff( "barkskin" )

                if ( level < 116 and equipped.oakhearts_puny_quods ) then
                    gain( 45, "rage" )
                    applyBuff( "oakhearts_puny_quods" )
                end
            end,
        },


        bear_form = {
            id = 5487,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -25,
            spendType = "rage",

            startsCombat = false,
            texture = 132276,

            essential = true,
            noform = "bear_form",

            handler = function ()
                shift( "bear_form" )                
            end,
        },


        bristling_fur = {
            id = 155835,
            cast = 0,
            cooldown = 40,
            gcd = "spell",

            startsCombat = false,
            texture = 1033476,

            talent = "bristling_fur",

            usable = function ()
                if incoming_damage_3s < health.max * 0.1 then return false, "player has not taken 10% health in dmg in 3s" end
                return true
            end,
            handler = function ()
                applyBuff( "bristling_fur" )
            end,
        },


        cat_form = {
            id = 768,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132115,

            noform = "cat_form",

            handler = function ()
                shift( "cat_form" )
                if pvptalent.master_shapeshifter.enabled and talent.feral_affinity.enabled then
                    applyBuff( "master_shapeshifter_feral" )
                end
            end,
        },


        dash = {
            id = 1850,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 132120,

            notalent = "tiger_dash",

            handler = function ()
                applyBuff( "dash" )
            end,
        },


        demoralizing_roar = {
            id = 201664,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            pvptalent = "demoralizing_roar",

            startsCombat = true,
            texture = 132117,

            handler = function ()
                applyDebuff( "demoralizing_roar" )
                active_dot.demoralizing_roar = active_enemies
            end,
        },


        entangling_roots = {
            id = 339,
            cast = 1.7,
            cooldown = 0,
            gcd = "spell",

            spend = 0.18,
            spendType = "mana",

            startsCombat = false,
            texture = 136100,

            handler = function ()
                applyDebuff( "target", "entangling_roots" )
            end,
        },


        ferocious_bite = {
            id = 22568,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return args.max_energy == 1 and 50 or 25 end,
            spendType = "energy",

            startsCombat = true,
            texture = 132127,

            form = "cat_form",
            
            usable = function ()
                if combo_points.current == 0 then return false, "player has no combo points" end
                return true
            end,

            handler = function ()
                if args.max_energy == 1 then gain( 25, "energy" ) end
                spend( min( 5, combo_points.current ), "combo_points" )
                if target.health_pct < 25 and debuff.rip.up then
                    debuff.rip.expires = query_time + min( debuff.rip.remains + debuff.rip.duration, debuff.rip.duration * 1.3 )
                end
            end,
        },


        frenzied_regeneration = {
            id = 22842,
            cast = 0,
            charges = 2,
            cooldown = 36,
            recharge = 36,
            gcd = "spell",

            spend = function () return 10 - ( 5 * buff.natural_defenses.stack ) end,
            spendType = "rage",

            startsCombat = false,
            texture = 132091,

            toggle = "defensives",
            defensive = true,

            form = "bear_form",

            readyTime = function () return buff.frenzied_regeneration.remains end,

            handler = function ()
                applyBuff( "frenzied_regeneration" )
                gain( health.max * 0.08, "health" )

                if level < 116 and equipped.skysecs_hold then applyBuff( "skysecs_hold" ) end
                removeStack( "natural_defenses" )
            end,
        },


        growl = {
            id = 6795,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            nopvptalent = "alpha_challenge",

            startsCombat = true,
            texture = 132270,

            handler = function ()
                applyDebuff( "target", "growl" )
            end,
        },


        hibernate = {
            id = 2637,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.15,
            spendType = "mana",

            startsCombat = false,
            texture = 136090,

            handler = function ()
                applyDebuff( "target", "hibernate" )
            end,
        },


        incapacitating_roar = {
            id = 99,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 132121,

            handler = function ()
                applyDebuff( "target", "incapacitating_roar" )
            end,
        },


        incarnation = {
            id = 102558,
            cast = 0,
            cooldown = 180,
            gcd = "off",

            startsCombat = false,
            texture = 571586,

            toggle = "cooldowns",

            handler = function ()
                applyBuff( "incarnation" )
            end,

            copy = { "incarnation_guardian_of_ursoc", "Incarnation" }
        },


        intimidating_roar = {
            id = 236748,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 132117,

            handler = function ()
                applyDebuff( "target", "intimidating_roar" )
            end,
        },


        ironfur = {
            id = 192081,
            cast = 0,
            cooldown = 0.5,
            gcd = "spell",

            spend = function () return 45 - ( 5 * buff.natural_defenses.stack ) end,
            spendType = "rage",

            startsCombat = false,
            texture = 1378702,

            toggle = "defensives",
            defensive = true,

            form = "bear_form",

            usable = function ()
                if not tanking then return false, "player is not tanking right now"
                elseif incoming_damage_3s == 0 then return false, "player has taken no damage in 3s" end
                return true
            end,

            handler = function ()
                applyBuff( "ironfur" )
                removeBuff( "guardian_of_elune" )
                removeStack( "natural_defenses" )
            end,
        },


        lunar_beam = {
            id = 204066,
            cast = 0,
            cooldown = 75,
            gcd = "spell",

            startsCombat = true,
            texture = 136057,

            talent = "lunar_beam",

            handler = function ()
                -- may need to construct fake aura...
            end,
        },


        lunar_strike = {
            id = 197628,
            cast = function () return haste * ( buff.lunar_empowerment.up and 1.8 or 2.5) end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 135753,

            form = "moonkin_form",
            talent = "balance_affinity",

            handler = function ()
                removeStack( "lunar_empowerment" )
            end,
        },


        mangle = {
            id = 33917,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            spend = function () return -10 + ( buff.gore.up and -4 or 0 ) end,
            spendType = "rage",

            startsCombat = true,
            texture = 132135,

            form = "bear_form",

            handler = function ()
                if talent.guardian_of_elune.enabled then applyBuff( "guardian_of_elune" ) end

                if set_bonus.tier21_2pc == 1 and buff.gore.up then
                    cooldown.barkskin.expires = cooldown.barkskin.expires - 1
                end

                if set_bonus.tier19_4pc == 1 then
                    addStack( "natural_defenses", 15, 1 )
                end

                removeBuff( "gore" )
            end,
        },


        mass_entanglement = {
            id = 102359,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 538515,

            talent = "mass_entanglement",

            handler = function ()
                applyDebuff( "target", "mass_entanglement" )
            end,
        },


        maul = {
            id = 6807,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 40,
            spendType = "rage",

            startsCombat = true,
            texture = 132136,

            form = "bear_form",

            usable = function ()
                if settings.maul_rage > 0 and rage.current - cost < settings.maul_rage then return false, "not enough additional rage" end
                return true
            end,

            handler = function ()
                if pvptalent.sharpened_claws.enabled or essence.conflict_and_strife.major then applyBuff( "sharpened_claws" ) end
            end,
        },


        mighty_bash = {
            id = 5211,
            cast = 0,
            cooldown = 50,
            gcd = "spell",

            startsCombat = true,
            texture = 132114,

            talent = "mighty_bash",

            handler = function ()
                applyDebuff( "target", "mighty_bash" )
            end,
        },


        moonfire = {
            id = 8921,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = true,
            texture = 136096,

            handler = function ()
                applyDebuff( "target", "moonfire" )
                if ( level < 116 and equipped.lady_and_the_child ) then
                    active_dot.moonfire = min( active_enemies, active_dot.moonfire + 1 )
                end

                if buff.galactic_guardian.up then
                    gain( 8, "rage" )
                    removeBuff( "galactic_guardian" )
                end
            end,
        },


        moonkin_form = {
            id = 197625,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 136036,

            noform = "moonkin_form",
            talent = "balance_affinity",

            handler = function ()
                shift( "moonkin_form" )
            end,
        },


        overrun = {
            id = 202246,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 1408833,

            handler = function ()
                applyDebuff( "target", "overrun" )
            end,
        },


        prowl = {
            id = 5215,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = false,
            texture = 514640,

            usable = function ()
                if time > 0 and not boss then return false, "cannot stealth in combat"
                elseif buff.prowl.up then return false, "player is already prowling" end
                return true
            end,

            handler = function ()
                shift( "cat_form" )
                applyBuff( "prowl" )
            end,
        },


        pulverize = {
            id = 80313,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 1033490,

            talent = "pulverize",
            form = "bear_form",

            usable = function ()
                if debuff.thrash_bear.stack < 2 then return false, "target has fewer than 2 thrash stacks" end
                return true
            end,

            handler = function ()
                if debuff.thrash_bear.count > 2 then debuff.thrash_bear.count = debuff.thrash_bear.count - 2
                else removeDebuff( "target", "thrash_bear" ) end
                applyBuff( "pulverize" )
            end,
        },


        rake = {
            id = 1822,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = true,
            texture = 132122,

            talent = "feral_affinity",
            form = "cat_form",

            handler = function ()
                applyDebuff( "target", "rake" )
                debuff.rake.pmultiplier = persistent_multiplier
                gain( 1, "combo_points" )
            end,
        },


        --[[ rebirth = {
            id = 20484,
            cast = 2,
            cooldown = 600,
            gcd = "spell",

            spend = 0,
            spendType = "rage",

            startsCombat = true,
            texture = 136080,

            handler = function ()
            end,
        }, ]]


        regrowth = {
            id = 8936,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.14,
            spendType = "mana",

            startsCombat = false,
            texture = 136085,

            talent = "restoration_affinity",
            usable = function ()
                if not ( buff.bear_form.down and buff.cat_form.down and buff.travel_form.down and buff.moonkin_form.down ) then return false, "player is in a form" end
                return true
            end,

            handler = function ()
                applyBuff( "regrowth" )
            end,
        },


        rejuvenation = {
            id = 774,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            startsCombat = false,
            texture = 136081,

            talent = "restoration_affinity",            

            usable = function ()
                if not ( buff.bear_form.down and buff.cat_form.down and buff.travel_form.down and buff.moonkin_form.down ) then return false, "player is in a form" end
                return true
            end,
            handler = function ()
                applyBuff( "rejuvenation" )
            end,
        },


        remove_corruption = {
            id = 2782,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 135952,

            usable = function ()
                if buff.dispellable_poison.down and buff.dispellable_curse.down then return false, "player has no dispellable auras" end
                return true
            end,
            handler = function ()
                removeBuff( "dispellable_poison" )
                removeBuff( "dispellable_curse" )
            end,
        },


        --[[ revive = {
            id = 50769,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = true,
            texture = 132132,

            handler = function ()
            end,
        }, ]]


        rip = {
            id = 1079,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "energy",

            startsCombat = true,
            texture = 132152,

            talent = "feral_affinity",
            form = "cat_form",

            usable = function ()
                if combo_points.current == 0 then return false, "player has no combo points" end
                return true
            end,

            handler = function ()
                applyDebuff( "target", "rip" )
            end,
        },


        shred = {
            id = 5221,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 40,
            spendType = "energy",

            startsCombat = true,
            texture = 136231,

            handler = function ()
            end,
        },


        skull_bash = {
            id = 106839,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 236946,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        solar_wrath = {
            id = 197629,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 535045,

            talent = "balance_affinity",
            form = "moonkin_form",

            handler = function ()
                removeStack( "solar_empowerment" )
            end,
        },


        stampeding_roar = {
            id = 106898,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            texture = 464343,

            handler = function ()
                applyBuff( "stampeding_roar" )
                if buff.bear_form.down and buff.cat_form.down then
                    shift( "bear_form" )
                end
            end,
        },


        starsurge = {
            id = 197626,
            cast = 2,
            cooldown = 10,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 135730,

            talent = "balance_affinity",
            form = "moonkin_form",

            handler = function ()
                addStack( "lunar_empowerment" )
                addStack( "solar_empowerment" )
            end,
        },


        sunfire = {
            id = 197630,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.12,
            spendType = "mana",

            startsCombat = true,
            texture = 236216,

            talent = "balance_affinity",
            form = "moonkin_form",

            handler = function ()
                applyDebuff( "target", "sunfire" )
                active_dot.sunfire = active_enemies
            end,
        },


        survival_instincts = {
            id = 61336,
            cast = 0,
            charges = function () return ( ( level < 116 and equipped.dual_determination ) and 3 or 2 ) end,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( ( level < 116 and equipped.dual_determination ) and 0.85 or 1 ) * 240 end,
            recharge = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( ( level < 116 and equipped.dual_determination ) and 0.85 or 1 ) * 240 end,
            gcd = "off",

            startsCombat = false,
            texture = 236169,

            toggle = "defensives",
            defensive = true,

            usable = function ()
                if not tanking then return false, "player is not tanking right now"
                elseif incoming_damage_3s == 0 then return false, "player has taken no damage in 3s" end
                return true
            end,

            handler = function ()
                applyBuff( "survival_instincts" )

                if azerite.masterful_instincts.enabled and buff.survival_instincts.up and buff.masterful_instincts.down then
                    applyBuff( "masterful_instincts", buff.survival_instincts.remains + 30 )
                end
            end,
        },


        swiftmend = {
            id = 18562,
            cast = 0,
            charges = 1,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = 0.14,
            spendType = "mana",

            startsCombat = false,
            texture = 134914,

            talent = "restoration_affinity",
            toggle = "defensives",
            defensive = true,


            handler = function ()
                unshift()
            end,
        },


        swipe_bear = {
            id = 213771,
            known = 213764,
            suffix = "(Bear)",
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 134296,

            form = "bear_form",

            handler = function ()
            end,

            copy = "swipe"
        },


        --[[ teleport_moonglade = {
            id = 18960,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 4,
            spendType = "mana",

            startsCombat = true,
            texture = 135758,

            handler = function ()
            end,
        }, ]]


        thrash_bear = {
            id = 77758,
            known = 106832,
            suffix = "(Bear)",
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            spend = -5,
            spendType = "rage",

            startsCombat = true,
            texture = 451161,

            form = "bear_form",

            handler = function ()
                applyDebuff( "target", "thrash_bear", 15, debuff.thrash_bear.count + 1 )
                active_dot.thrash_bear = active_enemies
            end,

            copy = "thrash"
        },


        tiger_dash = {
            id = 252216,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 1817485,

            talent = "tiger_dash",

            handler = function ()
                applyBuff( "tiger_dash" )
            end,
        },


        travel_form = {
            id = 783,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132144,

            handler = function ()
                shift( "travel_form" )
            end,
        },


        typhoon = {
            id = 132469,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 236170,

            talent = "typhoon",

            handler = function ()
                if target.distance < 15 then
                    applyDebuff( "target", "typhoon" )
                end
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


        ursols_vortex = {
            id = 102793,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            talent = "ursols_vortex",

            startsCombat = true,
            texture = 571588,

            handler = function ()
                applyDebuff( "target", "ursols_vortex" )
            end,
        },


        wild_charge = {
            id = 102401,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 538771,

            talent = "wild_charge",

            handler = function ()
                if buff.bear_form.up then target.distance = 5; applyDebuff( "target", "immobilized" )
                elseif buff.cat_form.up then target.distance = 5; applyDebuff( "target", "dazed" ) end
            end,
        },


        wild_growth = {
            id = 48438,
            cast = 1.5,
            cooldown = 10,
            gcd = "spell",

            spend = 0.3,
            spendType = "mana",

            startsCombat = false,
            texture = 236153,

            handler = function ()
                applyBuff( "wild_growth" )
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "focused_resolve",

        package = "Guardian",
    } )

    spec:RegisterSetting( "maul_rage", 20, {
        name = "Excess Rage for |T132136:0|t Maul",
        desc = "If set above zero, the addon will recommend |T132136:0|t Maul only if you have at least this much excess Rage.",
        type = "range",
        min = 0,
        max = 60,
        step = 0.1,
        width = 1.5
    } )

    spec:RegisterSetting( "ironfur_damage_threshold", 5, {
        name = "Required Damage % for |T1378702:0|t Ironfur",
        desc = "If set above zero, the addon will not recommend |T1378702:0|t Ironfur unless your incoming damage for the past 5 seconds is greater than this percentage of your maximum health.",
        type = "range",
        min = 0,
        max = 100,
        step = 0.1,
        width = 1.5
    } )    

    spec:RegisterPack( "Guardian", 20190818, [[dueLyaqiGs0JeOUeqjztQcJsrQoLQiwfKIELkQzjqULIu2Lk9lbmmvjhtKSmGQNbPutdO4AQIABqk4BiL04uK05qkX6qkL5js19aY(ePCqvrAHQipePuzIaLuxeOuSrGsOpIuQ6KaLsResUjKcTtfvdfOe8uHMQIyVs(RQAWO6WKwmsEmutwHltSzi(SkmArCAkRgOu9AKIzlQBdy3s9BLgos1Yr8CuMovxxqBxvQVROmEfjopKQwpKsMpKk7h0vQAsfhQl1CWFLIwEn1ut9McmVELc8k6ONUur6kMg9qQyRasfP9HkzyAxr6k6ZRoQjvKTHeSuXe3PZOTabompjK6IxGamdimRUTnMOiEaMbGdurQql7GTDrvXH6snh8xPOLxtn1uVPaZRxPQOg6jlPIrdG2vXeBmKUOQ4qy4kgmKt7dvYW0gYbRjH2aIkyipXD6mAlqGdZtcPU4fiaZacZQBBJjkIhGza4aqubd5pn8iK5qEQPgeKd(Ru0cKpnipfyOTxVGOGOcgYPDjAFimAdIkyiFAq(thdza5OrZTd1TTHCLYYMBc7crfmKpni)PJHmG8inH5mKFszjxiQGH8Pb5pDmKbKBKTrcj)HcOhY3ticlzZdiFP7223kMnMZQjveVBESZAwnPMNQMurf722vK(622vuALklJ6u51CWRjvuXUTDfPY7o(iHe0xrPvQSmQtLxZr7AsfvSBBxrkHWecnwFurPvQSmQtLxZbtnPIk2TTROsWAlFFjeP9kkTsLLrDQ8A(Z1KkQy32UIz7iXzFWE44aqAVIsRuzzuNkVMJgQjvuXUTDfrmIqL3DurPvQSmQtLxZP1AsfvSBBxrTXcZjA(J1CUIsRuzzuNkVMp1AsfLwPYYOovrmXCHyAfPcrqUuIs(ilb4gsVIk2TTRyoSvYNsuGYR50snPIsRuzzuNQiMyUqmTIuHiixkrjFKLaCdPxrf722vKIympB9XhjKuEnp1RAsfLwPYYOovrmXCHyAfNoKpw)cSBJye56gMgRpGC0HoixXU9w(slaMWG80G8uq(tG8hq(y9RNquwYNsuY1nmnwFurf722v0ASsA1TTlVMNkvnPIsRuzzuNQOIDB7kIrpoVozBd)PYkZROGGiy)3kGurm6X51jBB4pvwzE518uGxtQO0kvwg1PkIjMletROVhhz5I3np2zndYFa5thYDdq(((hMa5Pd5k2TT)4DZJDwd5Gvqo4qo6qhKRy3ElFPfatyqEAqEki)jvuXUTDf12a0)I8hI6jLxZtH21KkQy32UIacWsq)Fr(5qSn(dIOaSkkTsLLrDQ8AEkWutQOIDB7kgYKV5caRIsRuzzuNkV8kcyUDOUTDnPMNQMurPvQSmQtvetmxiMwrRXlG1h)HcOhY)zgKNgKBKTrcj)HcOhY3ticlzZdi)bKtfIGCnY2iHKlrauRzqE6q(bEa5OjKdEfvSBBxrJSnsiP8Ao41KkkTsLLrDQIyI5cX0kMiA2tU4qcrAhYthYFDP1NHC0eYten7jxaDkvuXUTDfrisJwMm(e5qAHOUTD51C0UMurPvQSmQtvetmxiMwrFpoYYDiisZS3cdYFa5jIM9KlDSd5Pd5t9vfvSBBxrTna9Vi)HOEs51CWutQO0kvwg1PkIjMletRyIOzp5sh7qE6qoT(mK)aYTgVawF8hkGEi)NzqEAq(Rl4pd5OjKNiA2tUa6uQOIDB7ksPeAy0yD518NRjvuALklJ6ufXeZfIPvKkeb5YcjVT3A(BnZTg7S7yN1q(diNkeb5sPeAy0y9DSZAi)bKNiA2tU0XoKNoKJgEb5pGCRXlG1h)HcOhY)zgKNgK)6c(ZqoAc5jIM9KlGoLkQy32UISqYB7TM)wZCRXoR8YR4qq0WSxtQ5PQjvuXUTDfz0eMZFkLLurPvQSmQtLxZbVMurPvQSmQtvuXUTDfXAo)vSBB)ZgZRy2y(VvaPIaMBhQBBxEnhTRjvuALklJ6ufvSBBxrSMZFf722)SX8kMnM)BfqQiE38yN1SYR5GPMurPvQSmQtvetmxiMwrIEi3HGyyZH80HCWFb5pGCf72B5lTaycdYthYbtfvSBBxranmxEn)5AsfLwPYYOovrmXCHyAfj6HChcIHnhYthYb)fK)aYfgtASCXBJKnS)1E8zoXqKlGc2xcK)aYblHCQqeKllrj0LwgFCwNXUH0ROIDB7kcOH5YR5OHAsfLwPYYOovrmXCHyAfXlZHCqq(lihDOdYNoKt0dbYtdYXlZH8hqUIwcXC5Mv0lez8b0wUsRuzza5pGCf72B5lTaycdYtdYbhYFsfvSBBxrJSnsiP8AoTwtQO0kvwg1PkIjMletR4y9RNquwYNsuYL5kMgiheKpw)6jeLL8PeLCb0P8zUIPHvrf722vKEy(Tqm0skVMp1AsfLwPYYOovrmXCHyAfhRFb2TrmICjccryjkvwG8hqUID7T8LwamHb5Pd5Gxrf722vey3gXis51CAPMurPvQSmQtvetmxiMwXPd5uHiixRXkPv32(o2znK)aYvSBVLV0cGjmipnipfK)eihDOdYNoKtfIGCTgRKwDB7BiDi)bKRy3ElFPfatyqEAqoyG8Nurf722v0tikl5tjkP8AEQx1KkkTsLLrDQIyI5cX0ksfIGCTgRKwDB77yN1q(dixXU9w(slaMWG80GCWurf722vKnZOlFkrjLxZtLQMurPvQSmQtvetmxiMwXX6xpHOSKpLOKRByAS(OIk2TTRiG2hzP8AEkWRjvuALklJ6ufXeZfIPvKkeb5EOzf7g(FeQKHP9nKoK)aYvSBVLV0cGjmipDih8kQy32UIa72igrkVMNcTRjvuXUTDf9eIYs(uIsQO0kvwg1PYR5PatnPIsRuzzuNQiMyUqmTIkAjeZLl9DMq(lY3tKpWU9LOnnqEAqEki)bKRy3ElFPfatyqoiipvfvSBBxrGDBeJiLxZt9CnPIk2TTRiBMrx(uIsQO0kvwg1PYlVI0jcEbOuVMuZtvtQOIDB7ksjk5JSeGkkTsLLrDQ8Ao41KkQy32UIacWsq)Fr(5qSn(dIOaSkkTsLLrDQ8AoAxtQOIDB7ksFDB7kkTsLLrDQ8YlVIVfcZ2UMd(Ru0YlAf8uxWrB0UIZusB9bRIGTa0xIldihmqUIDBBipBmNDHOQiJUGR5PEbMksNSiwwQyWqoTpujdtBihSMeAdiQGH8e3PZOTabompjK6IxGamdimRUTnMOiEaMbGdarfmK)0WJqMd5PMAqqo4Vsrlq(0G8uGH2E9cIcIkyiN2LO9HWOniQGH8Pb5pDmKbKJgn3ou32gYvklBUjSlevWq(0G8NogYaYJ0eMZq(jLLCHOcgYNgK)0XqgqUr2gjK8hkGEiFpHiSKnpG8LUBBFHOGOcgYbBMIGdDza5ucYseihVauQd5uYH1SlK)umwO7miV3EAjkbajmd5k2TTzq(2z0FHOcgYvSBBZU0jcEbOuheswz0arfmKRy32MDPte8cqP(zqbq2DarfmKRy32MDPte8cqP(zqb0WdaPD1TTHOuSBBZU0jcEbOu)mOauIs(ilbaIkyip2kDwY6qorTbKtfIGidiN5QZGCkbzjcKJxak1HCk5WAgKR9aYPtKPrFD36di3yq(yB5crfmKRy32MDPte8cqP(zqbyTsNLS(N5QZGOuSBBZU0jcEbOu)mOaacWsq)Fr(5qSn(dIOamikf722SlDIGxak1pdka91TTHOGOcgYbBMIGdDza5YBHGEi3nabY9ebYvSVei3yqU(wTSsLLleLIDBBgignH58Nszjquk2TTzNbfaR58xXUT9pBmpOwbeqaMBhQBBdrPy32MDguaSMZFf722)SX8GAfqaH3np2zndIsXUTn7mOaaAyoidberpK7qqmS5Pd(Rhk2T3YxAbWew6GbIsXUTn7mOaaAyoidberpK7qqmS5Pd(RhcJjnwU4TrYg2)Ap(mNyiYfqb7l5byjvicYLLOe6slJpoRZy3q6quk2TTzNbfWiBJescYqaHxMd6f6q30j6HKgEz(dfTeI5YnROxiY4dOTCLwPYY4HID7T8LwamHLg4pbIsXUTn7mOa0dZVfIHwsqUsoe)BiGgRF9eIYs(uIsUmxX0aAS(1tikl5tjk5cOt5ZCftddIsXUTn7mOaa72igrcYvYH4Fdb0y9lWUnIrKlrqiclrPYYdf72B5lTayclDWHOuSBBZodkGNquwsqgcOPtfIGCTgRKwDB77yN1puSBVLV0cGjS0s9e0HUPtfIGCTgRKwDB7Bi9hk2T3YxAbWewAG5jquk2TTzNbfGnZOlbziGOcrqUwJvsRUT9DSZ6hk2T3YxAbWewAGbIsXUTn7mOaaAFKLGmeqJ1VEcrzjFkrjx3W0y9beLIDBB2zqba2TrmIeKRKdX)gciQqeK7HMvSB4)rOsgM23q6puSBVLV0cGjS0bhIsXUTn7mOaEcrzjqubd5GfTCgYNzEcKJg3TrmIa5ZmpbYblSoACkGdrPy32MDguaGDBeJibziGu0siMlx67mH8xKVNiFGD7lrBAsl1df72B5lTaycdukikf722SZGcWMz0fikikf722SlG52H622GmY2iHKGmeqwJxaRp(dfqpK)ZS0mY2iHK)qb0d57jeHLS5XdQqeKRr2gjKCjcGAnl9d8anbhIsXUTn7cyUDOUT9zqbqisJwMm(e5qAHOUTDqgcOerZEYfhsis7P)6sRpJMjIM9KlGofikf722SlG52H622NbfqBdq)lYFiQNeKHaY3JJSChcI0m7TWEKiA2tU0XE6t9feLIDBB2fWC7qDB7ZGcqPeAy0yDqgcOerZEYLo2tNwF(H14fW6J)qb0d5)mlTxxWFgnten7jxaDkquk2TTzxaZTd1TTpdkalK82ER5V1m3ASZcYqarfIGCzHK32Bn)TM5wJD2DSZ6huHiixkLqdJgRVJDw)ir0SNCPJ90rdVEynEbS(4pua9q(pZs71f8NrZerZEYfqNcefeLIDBB2fVBESZAgi6RBBdrfmKRy32MDX7Mh7SMDguGerj(xymPXceLIDBB2fVBESZA2zqbOY7o(iHe0drPy32MDX7Mh7SMDguakHWecnwFarPy32MDX7Mh7SMDguaLG1w((sis7quk2TTzx8U5XoRzNbfiBhjo7d2dhhas7quk2TTzx8U5XoRzNbfaXicvE3beLIDBB2fVBESZA2zqb0glmNO5pwZzikf722SlE38yN1SZGcKdBL8PefiidbevicYLsuYhzja3q6quk2TTzx8U5XoRzNbfGIympB9XhjKeKHaIkeb5sjk5JSeGBiDikf722SlE38yN1SZGcynwjT622bziGM(y9lWUnIrKRByAS(aDOtXU9w(slaMWsl1tEmw)6jeLL8PeLCDdtJ1hquk2TTzx8U5XoRzNbfiKjFZfGGeeeb7)wbeqy0JZRt22WFQSYCikf722SlE38yN1SZGcOTbO)f5pe1tcYqa57XrwU4DZJDwZEmD3aKVV)HjPJ3np2znyf4OdDk2T3YxAbWewAPEceLIDBB2fVBESZA2zqbaeGLG()I8ZHyB8herbyquk2TTzx8U5XoRzNbfiKjFZfaw5Lxf]] )

end