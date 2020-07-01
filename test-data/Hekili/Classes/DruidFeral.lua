-- DruidFeral.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


local FindUnitBuffByID = ns.FindUnitBuffByID


if UnitClassBase( 'player' ) == 'DRUID' then
    local spec = Hekili:NewSpecialization( 103 )

    spec:RegisterResource( Enum.PowerType.Energy )
    spec:RegisterResource( Enum.PowerType.ComboPoints )

    spec:RegisterResource( Enum.PowerType.Rage )
    spec:RegisterResource( Enum.PowerType.LunarPower )
    spec:RegisterResource( Enum.PowerType.Mana )


    -- Talents
    spec:RegisterTalents( {
        predator = 22363, -- 202021
        sabertooth = 22364, -- 202031
        lunar_inspiration = 22365, -- 155580

        tiger_dash = 19283, -- 252216
        renewal = 18570, -- 108238
        wild_charge = 18571, -- 102401

        balance_affinity = 22163, -- 197488
        guardian_affinity = 22158, -- 217615
        restoration_affinity = 22159, -- 197492

        mighty_bash = 21778, -- 5211
        mass_entanglement = 18576, -- 102359
        typhoon = 18577, -- 132469

        soul_of_the_forest = 21708, -- 158476
        savage_roar = 18579, -- 52610
        incarnation = 21704, -- 102543

        scent_of_blood = 21714, -- 285564
        brutal_slash = 21711, -- 202028
        primal_wrath = 22370, -- 285381

        moment_of_clarity = 21646, -- 236068
        bloodtalons = 21649, -- 155672
        feral_frenzy = 21653, -- 274837
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3432, -- 214027
        relentless = 3433, -- 196029
        gladiators_medallion = 3431, -- 208683

        earthen_grasp = 202, -- 236023
        enraged_maim = 604, -- 236026
        ferocious_wound = 611, -- 236020
        freedom_of_the_herd = 203, -- 213200
        fresh_wound = 612, -- 203224
        heart_of_the_wild = 3053, -- 236019
        king_of_the_jungle = 602, -- 203052
        leader_of_the_pack = 3751, -- 202626
        malornes_swiftness = 601, -- 236012
        protector_of_the_grove = 847, -- 209730
        rip_and_tear = 620, -- 203242
        savage_momentum = 820, -- 205673
        thorns = 201, -- 236696
    } )


    -- Auras
    spec:RegisterAuras( {
        aquatic_form = {
            id = 276012,
        },
        astral_influence = {
            id = 197524,
        },
        berserk = {
            id = 106951,
            duration = 20,
            max_stack = 1,
            copy = 279526,
        },
        bear_form = {
            id = 5487,
            duration = 3600,
            max_stack = 1,
        },
        bloodtalons = {
            id = 145152, 
            max_stack = 2,
            duration = 30,
        },
        cat_form = {
            id = 768,
            duration = 3600,
            max_stack = 1,
        },
        clearcasting = {
            id = 135700,
            duration = 15,
            max_stack = function()
                local x = 1 -- Base Stacks
                return talent.moment_of_clarity.enabled and 2 or x
            end,
        },
        dash = {
            id = 1850,
            duration = 10,
        },
        entangling_roots = {
            id = 339,
            duration = 30,
            type = "Magic",
        },
        feline_swiftness = {
            id = 131768,
        },
        feral_frenzy = {
            id = 274837,
            duration = 6,
        },
        feral_instinct = {
            id = 16949,
        },
        flight_form = {
            id = 276029,
        },
        frenzied_regeneration = {
            id = 22842,
        },
        hibernate = {
            id = 2637,
            duration = 40,
        },
        incarnation = {
            id = 102543,
            duration = 30,
        },
        infected_wounds = {
            id = 48484,
        },
        ironfur = {
            id = 192081,
            duration = 6,
        },
        jungle_stalker = {
            id = 252071, 
            duration = 30,
        },
        lunar_empowerment = {
            id = 164547,
            duration = 45,
            type = "Magic",
            max_stack = 3,
        },
        maim = {
            id = 22570,
            duration = 5,
            max_stack = 1,
        },
        moonfire = {
            id = 164812,
            duration = 16,
            tick_time = function () return 2 * haste end,
            type = "Magic",
            max_stack = 1,
        },
        moonfire_cat = {
            id = 155625, 
            duration = 16,
            tick_time = function() return 2 * haste end,
        },
        moonkin_form = {
            id = 197625,
        },
        omen_of_clarity = {
            id = 16864,
            duration = 16,
            max_stack = function () return talent.moment_of_clarity.enabled and 2 or 1 end,
        },
        predatory_swiftness = {
            id = 69369,
            duration = 12,
            max_stack = 1,
        },
        primal_fury = {
            id = 159286,
        },
        prowl_base = {
            id = 5215,
            duration = 3600,
        },
        prowl_incarnation = {
            id = 102547,
            duration = 3600,
        },
        prowl = {
            alias = { "prowl_base", "prowl_incarnation" },
            aliasMode = "first",
            aliasType = "buff",
            duration = 3600,
        },
        rake = {
            id = 155722, 
            duration = 15,
            tick_time = function() return 3 * haste end,
        },
        regrowth = { 
            id = 8936, 
            duration = 12,
        },
        rip = {
            id = 1079,
            duration = 24,
            tick_time = function() return 2 * haste end,
        },
        savage_roar = {
            id = 52610,
            duration = 36,
        },
        scent_of_blood = {
            id = 285646,
            duration = 6,
            max_stack = 1,
        },
        shadowmeld = {
            id = 58984,
            duration = 3600,
        },
        solar_empowerment = {
            id = 164545,
            duration = 45,
            type = "Magic",
            max_stack = 3,
        },
        survival_instincts = {
            id = 61336,
            duration = 6,
            max_stack = 1,
        },
        thrash_bear = {
            id = 192090,
            duration = 15,
            max_stack = 3,
        },
        thrash_cat ={
            id = 106830, 
            duration = 15,
            tick_time = function() return 3 * haste end,
        },
        --[[ thrash = {
            id = function ()
                if buff.cat_form.up then return 106830 end
                return 192090
            end,
            duration = function()
                local x = 15 -- Base duration
                return talent.jagged_wounds.enabled and x * 0.80 or x
            end,
            tick_time = function()
                local x = 3 -- Base tick time
                return talent.jagged_wounds.enabled and x * 0.80 or x
            end,
        }, ]]
        thick_hide = {
            id = 16931,
        },
        tiger_dash = {
            id = 252216,
            duration = 5,
        },
        tigers_fury = {
            id = 5217,
            duration = function()
                local x = 10 -- Base Duration
                if talent.predator.enabled then return x + 5 end
                return x
            end,
        },
        travel_form = {
            id = 783,
        },
        wild_charge = {
            id = 102401,
        },
        yseras_gift = {
            id = 145108,
        },


        -- PvP Talents
        cyclone = {
            id = 209753,
            duration = 6,
            max_stack = 1,
        },

        ferocious_wound = {
            id = 236021,
            duration = 30,
            max_stack = 2,
        },

        king_of_the_jungle = {
            id = 203059,
            duration = 24,
            max_stack = 3,
        },

        leader_of_the_pack = {
            id = 202636,
            duration = 3600,
            max_stack = 1,
        },

        thorns = {
            id = 236696,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },


        -- Azerite Powers
        iron_jaws = {
            id = 276026,
            duration = 30,
            max_stack = 1,
        },

        jungle_fury = {
            id = 274426,
            duration = function () return talent.predator.enabled and 17 or 12 end,
            max_stack = 1,
        },
    } )


    -- Snapshotting
    local tf_spells = { rake = true, rip = true, thrash_cat = true, moonfire_cat = true, primal_wrath = true }
    local bt_spells = { rake = true, rip = true, thrash_cat = true, primal_wrath = true }
    local mc_spells = { thrash_cat = true }
    local pr_spells = { rake = true }

    local snapshot_value = {
        tigers_fury = 1.15,
        bloodtalons = 1.25,
        clearcasting = 1.15, -- TODO: Only if talented MoC, not used by 8.1 script
        prowling = 2
    }


    --[[ local modifiers = {
        [1822]   = 155722,
        [1079]   = 1079,
        [106830] = 106830,
        [8921]   = 155625
    } ]] -- ??


    local stealth_dropped = 0

    local function calculate_multiplier( spellID )

        local tigers_fury = FindUnitBuffByID( "player", class.auras.tigers_fury.id, "PLAYER" ) and snapshot_value.tigers_fury or 1
        local bloodtalons = FindUnitBuffByID( "player", class.auras.bloodtalons.id, "PLAYER" ) and snapshot_value.bloodtalons or 1
        local clearcasting = FindUnitBuffByID( "player", class.auras.clearcasting.id, "PLAYER" ) and state.talent.moment_of_clarity.enabled and snapshot_value.clearcasting or 1
        local prowling = ( GetTime() - stealth_dropped < 0.2 or FindUnitBuffByID( "player", class.auras.incarnation.id, "PLAYER" ) ) and snapshot_value.prowling or 1     

        if spellID == 155722 then
            return 1 * bloodtalons * tigers_fury * prowling

        elseif spellID == 1079 or spellID == 285381 then
            return 1 * bloodtalons * tigers_fury

        elseif spellID == 106830 then
            return 1 * bloodtalons * tigers_fury * clearcasting

        elseif spellID == 155625 then
            return 1 * tigers_fury

        end

        return 1
    end

    spec:RegisterStateExpr( 'persistent_multiplier', function ()
        local mult = 1

        if not this_action then return mult end

        if tf_spells[ this_action ] and buff.tigers_fury.up then mult = mult * snapshot_value.tigers_fury end
        if bt_spells[ this_action ] and buff.bloodtalons.up then mult = mult * snapshot_value.bloodtalons end
        if mc_spells[ this_action ] and buff.clearcasting.up then mult = mult * snapshot_value.clearcasting end
        if pr_spells[ this_action ] and ( buff.incarnation.up or buff.prowl.up or buff.shadowmeld.up or state.query_time - stealth_dropped < 0.2 ) then mult = mult * snapshot_value.prowling end

        return mult
    end )


    local snapshots = {
        [155722] = true,
        [1079]   = true,
        [106830] = true,
        [155625] = true
    }


    -- Tweaking for new Feral APL.
    local rip_applied = false

    spec:RegisterEvent( "PLAYER_REGEN_ENABLED", function ()
        rip_applied = false
    end )    

    spec:RegisterStateExpr( "opener_done", function ()
        return rip_applied
    end )


    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount, interrupt, a, b, c, d, offhand, multistrike, ... )
        local _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID then
            if subtype == "SPELL_AURA_REMOVED" then
                -- Track Prowl and Shadowmeld dropping, give a 0.2s window for the Rake snapshot.
                if spellID == 58984 or spellID == 5215 or spellID == 1102547 then
                    stealth_dropped = GetTime()
                end
            elseif snapshots[ spellID ] and ( subtype == 'SPELL_AURA_APPLIED'  or subtype == 'SPELL_AURA_REFRESH' or subtype == 'SPELL_AURA_APPLIED_DOSE' ) then
                ns.saveDebuffModifier( spellID, calculate_multiplier( spellID ) )
                ns.trackDebuff( spellID, destGUID, GetTime(), true )
            elseif subtype == "SPELL_CAST_SUCCESS" and ( spellID == class.abilities.rip.id or spellID == class.abilities.primal_wrath.id or spellID == class.abilities.ferocious_bite.id or spellID == class.abilities.maim.id or spellID == class.abilities.savage_roar.id ) then
                rip_applied = true
            end
        end
    end )  


    spec:RegisterStateFunction( "break_stealth", function ()
        removeBuff( "shadowmeld" )
        if buff.prowl.up then
            setCooldown( "prowl", 6 )
            removeBuff( "prowl" )
        end
    end )


    -- Function to remove any form currently active.
    spec:RegisterStateFunction( "unshift", function()
        removeBuff( "cat_form" )
        removeBuff( "bear_form" )
        removeBuff( "travel_form" )
        removeBuff( "moonkin_form" )
    end )


    -- Function to apply form that is passed into it via string.
    spec:RegisterStateFunction( "shift", function( form )
        removeBuff( "cat_form" )
        removeBuff( "bear_form" )
        removeBuff( "travel_form" )
        removeBuff( "moonkin_form" )
        applyBuff( form )
    end )


    spec:RegisterHook( "runHandler", function( ability )
        local a = class.abilities[ ability ]

        if not a or a.startsCombat then
            break_stealth()
        end 
    end )

    spec:RegisterHook( "reset_precast", function ()
        if buff.cat_form.down then
            energy.regen = 10 + ( stat.haste * 10 )
        end
        debuff.rip.pmultiplier = nil
        debuff.rake.pmultiplier = nil
        debuff.thrash.pmultiplier = nil

        opener_done = nil
    end )

    spec:RegisterHook( "gain", function( amt, resource )
        if azerite.untamed_ferocity.enabled and amt > 0 and resource == "combo_points" then
            if talent.incarnation.enabled then gainChargeTime( "incarnation", 0.2 )
            else gainChargeTime( "berserk", 0.3 ) end
        end
    end )


    local function comboSpender( a, r )
        if r == "combo_points" and a > 0 and talent.soul_of_the_forest.enabled then
            gain( a * 5, "energy" )
        end
    end

    spec:RegisterHook( "spend", comboSpender )
    -- spec:RegisterHook( "spendResources", comboSpender )


    -- Legendaries.  Ugh.
    spec:RegisterGear( 'ailuro_pouncers', 137024 )
    spec:RegisterGear( 'behemoth_headdress', 151801 )
    spec:RegisterGear( 'chatoyant_signet', 137040 )        
    spec:RegisterGear( 'ekowraith_creator_of_worlds', 137015 )
    spec:RegisterGear( 'fiery_red_maimers', 144354 )
    spec:RegisterGear( 'luffa_wrappings', 137056 )
    spec:RegisterGear( 'soul_of_the_archdruid', 151636 )
    spec:RegisterGear( 'the_wildshapers_clutch', 137094 )

    -- Legion Sets (for now).
    spec:RegisterGear( 'tier21', 152127, 152129, 152125, 152124, 152126, 152128 )
        spec:RegisterAura( 'apex_predator', {
            id = 252752,
            duration = 25
         } ) -- T21 Feral 4pc Bonus.

    spec:RegisterGear( 'tier20', 147136, 147138, 147134, 147133, 147135, 147137 )
    spec:RegisterGear( 'tier19', 138330, 138336, 138366, 138324, 138327, 138333 )
    spec:RegisterGear( 'class', 139726, 139728, 139723, 139730, 139725, 139729, 139727, 139724 )


    -- Abilities
    spec:RegisterAbilities( {
        bear_form = {
            id = 5487,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -25,
            spendType = "rage",

            startsCombat = false,
            texture = 132276,

            noform = "bear_form",
            handler = function () shift( "bear_form" ) end,
        },


        berserk = {
            id = 106951,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 180 end,
            gcd = "spell",

            startsCombat = false,
            texture = 236149,

            notalent = "incarnation",

            toggle = "cooldowns",
            nobuff = "berserk", -- VoP

            handler = function ()
                if buff.cat_form.down then shift( "cat_form" ) end
                applyBuff( "berserk" )
                energy.max = energy.max + 50
            end,
        },


        brutal_slash = {
            id = 202028,
            cast = 0,
            charges = 3,

            cooldown = 8,
            recharge = 8,
            hasteCD = true,

            gcd = "spell",

            spend = function ()
                if buff.clearcasting.up then return 0 end

                local x = 25
                if buff.scent_of_blood.up then x = x + buff.scent_of_blood.v1 end
                return x * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 )
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 132141,

            form = "cat_form",
            talent = "brutal_slash",

            handler = function ()
                gain( 1, "combo_points" )
                removeStack( "bloodtalons" )
            end,
        },


        cat_form = {
            id = 768,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132115,

            essential = true,

            noform = "cat_form",
            handler = function ()
                shift( "cat_form" ) 
            end,
        },


        cyclone = {
            id = 209753,
            cast = 1.7,
            cooldown = 0,
            gcd = "spell",

            pvptalent = "cyclone",

            spend = 0.15,
            spendType = "mana",

            startsCombat = true,
            texture = 136022,

            handler = function ()
                applyDebuff( "target", "cyclone" )
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
                shift( "cat_form" )
                applyBuff( "dash" )
            end,
        },


        enraged_maul = {
            id = 236716,
            cast = 0,
            cooldown = 3,
            gcd = "spell",

            pvptalent = "heart_of_the_wild",
            form = "bear_form",

            spend = 40,
            spendType = "rage",

            startsCombat = true,
            texture = 132136,

            handler = function ()                
            end,
        },


        entangling_roots = {
            id = 339,
            cast = function ()
                if buff.predatory_swiftness.up then return 0 end
                return 1.7 * haste
            end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            startsCombat = true,
            texture = 136100,

            handler = function ()
                applyDebuff( "target", "entangling_roots" )
                removeBuff( "predatory_swiftness" )
                if talent.bloodtalons.enabled then applyBuff( "bloodtalons", 30, 2 ) end
            end,
        },


        feral_frenzy = {
            id = 274837,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 25,
            spendType = "energy",

            startsCombat = true,
            texture = 132140,

            handler = function ()
                gain( 5, "combo_points" )
                applyDebuff( "target", "feral_frenzy" )
                removeStack( "bloodtalons" )
            end,

            copy = "ashamanes_frenzy"
        },


        ferocious_bite = {
            id = 22568,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.apex_predator.up then return 0 end
                -- going to require 50 energy and then refund it back...
                if talent.sabertooth.enabled and debuff.rip.up then
                    -- Let's make FB available sooner if we need to keep a Rip from falling off.
                    local nrg = 50 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 )
                    
                    if energy[ "time_to_" .. nrg ] - debuff.rip.remains > 0 then
                        return max( 25, energy.current + ( (debuff.rip.remains - 1 ) * energy.regen ) )
                    end
                end
                return 50 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 )
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 132127,

            form = "cat_form",
            indicator = function ()
                if settings.cycle and talent.sabertooth.enabled and dot.rip.down and active_dot.rip > 0 then return "cycle" end
            end,

            usable = function () return buff.apex_predator.up or combo_points.current > 0 end,
            handler = function ()
                if talent.sabertooth.enabled and debuff.rip.up then
                    debuff.rip.expires = debuff.rip.expires + ( 4 * combo_points.current )
                end

                if pvptalent.ferocious_wound.enabled and combo_points.current >= 5 then
                    applyDebuff( "target", "ferocious_wound", nil, min( 2, debuff.ferocious_wound.stack + 1 ) )
                end

                if buff.apex_predator.up then
                    applyBuff( "predatory_swiftness" )
                    removeBuff( "apex_predator" )
                else
                    -- gain( 25, "energy" )
                    if combo_points.current == 5 then applyBuff( "predatory_swiftness" ) end
                    spend( min( 5, combo_points.current ), "combo_points" )
                end

                opener_done = true

                removeStack( "bloodtalons" )
            end,
        },


        frenzied_regeneration = {
            id = 22842,
            cast = 0,
            charges = 1,
            cooldown = 36,
            recharge = 36,
            hasteCD = true,
            gcd = "spell",

            spend = 10,
            spendType = "rage",

            startsCombat = false,
            texture = 132091,

            talent = "guardian_affinity",
            form = "bear_form",

            handler = function ()
                applyBuff( "frenzied_regeneration" )
                gain( health.max * 0.05, "health" )
            end,
        },


        growl = {
            id = 6795,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            startsCombat = true,
            texture = 132270,

            form = "bear_form",
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


        incarnation = {
            id = 102543,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 180 end,
            gcd = "spell",

            startsCombat = false,
            texture = 571586,

            toggle = "cooldowns",
            nobuff = "incarnation", -- VoP

            handler = function ()
                if buff.cat_form.down then shift( "cat_form" ) end
                applyBuff( "incarnation" )
                applyBuff( "jungle_stalker" )
                energy.max = energy.max + 50 
            end,

            copy = { "incarnation_king_of_the_jungle", "Incarnation" }
        },


        ironfur = {
            id = 192081,
            cast = 0,
            cooldown = 0.5,
            gcd = "spell",

            spend = 45,
            spendType = "rage",

            startsCombat = false,
            texture = 1378702,

            form = "bear_form",
            talent = "guardian_affinity",

            handler = function ()
                applyBuff( "ironfur", 6 + buff.ironfur.remains )
            end,
        },


        lunar_strike = {
            id = 197628,
            cast = function() return 2.5 * haste * ( buff.lunar_empowerment.up and 0.85 or 1 ) end,
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


        maim = {
            id = 22570,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = function () return 35 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 132134,

            form = "cat_form",
            usable = function () return combo_points.current > 0 end,

            handler = function ()
                applyDebuff( "target", "maim", combo_points.current )
                if combo_points.current == 5 then applyBuff( "predatory_swiftness" ) end
                spend( combo_points.current, "combo_points" )
                removeStack( "bloodtalons" )
                removeBuff( "iron_jaws" )

                opener_done = true
            end,
        },


        mangle = {
            id = 33917,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            spend = -10,
            spendType = "rage",

            startsCombat = true,
            texture = 132135,

            form = "bear_form",

            handler = function ()
                removeStack( "bloodtalons" )
            end,
        },


        mass_entanglement = {
            id = 102359,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 538515,

            talent = "mass_entanglement",

            handler = function ()
                applyDebuff( "target", "mass_entanglement" )
                active_dot.mass_entanglement = max( active_dot.mass_entanglement, true_active_enemies )
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

            startsCombat = true,
            texture = 136096,

            cycle = "moonfire",

            form = "moonkin_form",

            handler = function ()
                if not buff.moonkin_form.up then unshift() end
                applyDebuff( "target", "moonfire" )
            end,
        },


        moonfire_cat = {            
            id = 155625,
            known = 8921,
            suffix = "(Cat)",
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 30 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 136096,

            talent = "lunar_inspiration",
            form = "cat_form",

            cycle = "moonfire_cat",
            aura = "moonfire_cat",

            handler = function ()
                applyDebuff( "target", "moonfire_cat" )
                debuff.moonfire_cat.pmultiplier = persistent_multiplier
                gain( 1, "combo_points" )
            end,

            copy = { 8921, 155625, "moonfire_cat" }
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


        primal_wrath = {
            id = 285381,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            talent = "primal_wrath",
            aura = "rip",

            spend = 20,
            spendType = "energy",

            startsCombat = true,
            texture = 1392547,

            usable = function () return combo_points.current > 0, "no combo points" end,
            handler = function ()
                applyDebuff( "target", "rip", 4 * combo_points.current )
                active_dot.rip = active_enemies

                opener_done = true

                spend( combo_points.current, "combo_points" )
            end,
        },


        prowl = {
            id = function () return buff.incarnation.up and 102547 or 5215 end,
            cast = 0,
            cooldown = function ()
                if buff.prowl.up then return 0 end
                return 6
            end,
            gcd = "off",

            startsCombat = false,
            texture = 514640,

            nobuff = "prowl",

            usable = function () return time == 0 or ( boss and buff.jungle_stalker.up ) end,

            handler = function ()
                shift( "cat_form" )
                applyBuff( buff.incarnation.up and "prowl_incarnation" or "prowl_base" )
            end,

            copy = { 5215, 102547 }
        },


        rake = {
            id = 1822,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                return 35 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ), "energy"
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 132122,

            cycle = "rake",
            min_ttd = 6,

            damage = function ()
                return stat.attack_power * 0.18225
            end,

            tick_damage = function ()
                return stat.attack_power * 0.15561
            end,

            tick_dmg = function ()
                return stat.attack_power * 0.15561
            end,

            form = "cat_form",

            handler = function ()
                applyDebuff( "target", "rake" )
                debuff.rake.pmultiplier = persistent_multiplier

                gain( 1, "combo_points" )
                removeStack( "bloodtalons" )
            end,

            copy = "rake_bleed"
        },


        rebirth = {
            id = 20484,
            cast = 2,
            cooldown = 600,
            gcd = "spell",

            spend = 0,
            spendType = "rage",

            startsCombat = false,
            texture = 136080,

            handler = function ()
            end,
        },


        regrowth = {
            id = 8936,
            cast = function ()
                if buff.predatory_swiftness.up then return 0 end
                return 1.5 * haste
            end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.14,
            spendType = "mana",

            startsCombat = false,
            texture = 136085,

            usable = function ()
                if buff.bloodtalons.up then return false end
                -- Try without out-of-combat time == 0 check.
                if buff.prowl.up then return false, "prowling" end
                if buff.cat_form.up and time > 0 and buff.predatory_swiftness.down then return false, "predatory_swiftness is down" end
                return true
            end,

            handler = function ()
                if buff.predatory_swiftness.down then
                    unshift() 
                end
                removeBuff( "predatory_swiftness" )

                if talent.bloodtalons.enabled then applyBuff( "bloodtalons", 30, 2 ) end
                applyBuff( "regrowth", 12 )
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

            handler = function ()
                unshift()
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

            handler = function ()
            end,
        },


        renewal = {
            id = 108238,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            startsCombat = false,
            texture = 136059,

            talent = "renewal",

            handler = function ()
                health.actual = min( health.max, health.actual + ( 0.3 * health.max ) )
            end,
        },


        revive = {
            id = 50769,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = false,
            texture = 132132,

            handler = function ()
            end,
        },


        rip = {
            id = 1079,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 30 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 132152,

            aura = "rip",
            cycle = "rip",
            min_ttd = 9.6,

            form = "cat_form",

            usable = function ()
                if combo_points.current == 0 then return false, "no combo points" end
                --[[ if settings.hold_bleed_pct > 0 then
                    local limit = settings.hold_bleed_pct * debuff.rip.duration
                    if target.time_to_die < limit then return false, "target will die in " .. target.time_to_die .. " seconds (<" .. limit .. ")" end
                end ]]
                return true
            end,            

            handler = function ()
                if combo_points.current == 5 then applyBuff( "predatory_swiftness" ) end
                spend( combo_points.current, "combo_points" )

                applyDebuff( "target", "rip", min( 1.3 * class.auras.rip.duration, debuff.rip.remains + class.auras.rip.duration ) )
                debuff.rip.pmultiplier = persistent_multiplier
                removeStack( "bloodtalons" )

                opener_done = true
            end,
        },


        rip_and_tear = {
            id = 203242,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 60,
            spendType = "energy",

            talent = "rip_and_tear",

            startsCombat = true,
            texture = 1029738,

            handler = function ()
                applyDebuff( "target", "rip" )
                applyDebuff( "target", "rake" )
            end,
        },


        savage_roar = {
            id = 52610,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 25 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 236167,

            talent = "savage_roar",

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                if combo_points.current == 5 then applyBuff( "predatory_swiftness" ) end

                local cost = min( 5, combo_points.current )
                spend( cost, "combo_points" )
                if buff.savage_roar.down then energy.regen = energy.regen * 1.1 end
                applyBuff( "savage_roar", 6 + ( 6 * cost ) )

                opener_done = true
            end,
        },


        shred = {
            id = 5221,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.clearcasting.up then return 0 end
                return 40 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) 
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 136231,

            form = "cat_form",

            handler = function ()
                gain( 1, "combo_points" )
                removeStack( "bloodtalons" )
                removeStack( "clearcasting" )
            end,
        },


        skull_bash = {
            id = 106839,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 236946,

            toggle = "interrupts",
            interrupt = true,

            form = function () return buff.bear_form.up and "bear_form" or "cat_form" end,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()

                if pvptalent.savage_momentum.enabled then
                    gainChargeTime( "tigers_fury", 10 )
                    gainChargeTime( "survival_instincts", 10 )
                    gainChargeTime( "stampeding_roar", 10 )
                end
            end,
        },


        solar_wrath = {
            id = 197629,
            cast = function () return 1.5 * haste * ( buff.solar_empowerment.up and 0.85 or 1 ) end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 535045,

            form = "moonkin_form",
            talent = "balance_affinity",

            handler = function ()
                removeStack( "solar_empowerment" )
            end,
        },


        soothe = {
            id = 2908,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            toggle = "interrupts",

            startsCombat = false,
            texture = 132163,

            usable = function () return buff.dispellable_enrage.up end,
            handler = function ()
                removeBuff( "dispellable_enrage" )
            end,
        },


        stampeding_roar = {
            id = 106898,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 464343,

            handler = function ()
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

            form = "moonkin_form",
            talent = "balance_affinity",

            handler = function ()
                addStack( "solar_empowerment", nil, 1 )
                addStack( "lunar_empowerment", nil, 1 )
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

            form = "moonkin_form",
            talent = "balance_affinity",

            handler = function ()
                applyDebuff( "target", "sunfire" )
                active_dot.sunfire = active_enemies
            end,
        },


        survival_instincts = {
            id = 61336,
            cast = 0,
            charges = 2,
            cooldown = 120,
            recharge = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 236169,

            handler = function ()
                applyBuff( "survival_instincts" )
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

            handler = function ()
                unshift()
            end,
        },


        swipe_cat = {
            id = 106785,
            known = 213764,
            suffix = "(Cat)",
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.clearcasting.up then return 0 end
                return max( 0, ( 35 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 ) ) + buff.scent_of_blood.v1 )
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 134296,

            notalent = "brutal_slash",
            form = "cat_form",

            damage = function () return stat.attack_power * 0.28750 * ( active_dot.thrash_cat > 0 and 1.2 or 1 ) end,

            handler = function ()
                gain( 1, "combo_points" )
                removeStack( "bloodtalons" )
                removeStack( "clearcasting" )
            end,

            copy = { 213764, "swipe" },
        },

        teleport_moonglade = {
            id = 18960,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 4,
            spendType = "mana",

            startsCombat = false,
            texture = 135758,

            handler = function ()
            end,
        },


        thorns = {
            id = 305497,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = function ()
                if essence.conflict_and_strife.enabled then return end
                return "thorns"
            end,

            spend = 0.12,
            spendType = "mana",

            startsCombat = false,
            texture = 136104,

            handler = function ()
                applyBuff( "thorns" )
            end,
        },


        thrash_cat = {
            id = 106830,
            known = 106832,
            suffix = "(Cat)",
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.clearcasting.up then return 0 end
                return 40 * ( ( buff.berserk.up or buff.incarnation.up ) and 0.6 or 1 )
            end,
            spendType = "energy",

            startsCombat = true,
            texture = 451161,

            aura = "thrash_cat",
            cycle = "thrash_cat",

            form = "cat_form",
            handler = function ()
                applyDebuff( "target", "thrash_cat" )
                active_dot.thrash_cat = max( active_dot.thrash, true_active_enemies )
                debuff.thrash_cat.pmultiplier = persistent_multiplier

                if talent.scent_of_blood.enabled then
                    applyBuff( "scent_of_blood" )
                    buff.scent_of_blood.v1 = -3 * active_enemies
                end

                removeStack( "bloodtalons" )
                removeStack( "clearcasting" )
                if target.within8 then gain( 1, "combo_points" ) end
            end,
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
                shift( "cat_form" )
                applyBuff( "tiger_dash" )
            end,
        },


        tigers_fury = {
            id = 5217,
            cast = 0,
            cooldown = 30,
            gcd = "off",

            spend = -50,
            spendType = "energy",

            startsCombat = false,
            texture = 132242,

            usable = function () return buff.tigers_fury.down or energy.deficit > 50 + energy.regen end,
            handler = function ()
                shift( "cat_form" )
                applyBuff( "tigers_fury", talent.predator.enabled and 15 or 10 )
                if azerite.jungle_fury.enabled then applyBuff( "jungle_fury" ) end
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


        wild_charge = {
            id = 102401,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = false,
            texture = 538771,

            handler = function ()
                setDistance( 5 )
                -- applyDebuff( "target", "dazed", 3 )
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

            talent = "restoration_affinity",

            handler = function ()
                unshift()
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
        damageDots = false,
        damageExpiration = 3,

        potion = "focused_resolve",

        package = "Feral"
    } )

    spec:RegisterSetting( "brutal_charges", 2, {
        name = "Reserve |T132141:0|t Brutal Slash Charges",
        desc = "If set above zero, the addon will hold these Brutal Slash charges for when 3+ enemies have been detected.",
        icon = 132141,
        iconCoords = { 0.1, 0.9, 0.1, 0.9 },
        type = "range",
        min = 0,
        max = 4,
        step = 0.1,
        width = 1.5
    } )    

    spec:RegisterPack( "Feral", 20200222, [[dS0aCbqibWIiqqEKaPlrGe2KO4tei1OeuoLa1Qiq5veWSuQ6wcq2ff)ck1WuQ0XukTmLOEMsKMMsfUMGQ2gbI(MseACkr05iqL1Peb9oceW8eiUhG2hb1bjqOfsqEibQYevIaxKab1gfGQtsGQALkfZuakzNqHFsGanubOuwQau8uv1uHs(kbs0EH8xrgmQomvlgOht0KvLlJSzH(SOA0aCAPwnbs61qrZMs3wjTBv(TIHtOJlaLQLl55OmDsxhQ2Ua67cY4fu58IsRxPIMVsy)GgTfHf6)CLqyS8UlV7UlV8YMLxEhcUDeE0xZksOVOlX0Zj0)8vc9d4u5w0x0ZAh)HWc9zdEjj0hGQISLqSXoVva4Gg5SInRxXTU2ZjlpQyZ6vj2OpiEBvb)dbI(pxjeglV7Y7U7YlVSz5L3XU7yz0NjssegB3DPOpG(9OdbI(pIjr)Gc5bCQClKVeu49dUjOqoavfzlHyJDERaWbnYzfBwVIBDTNtwEuXM1RsSHBckKhWjWc3RSq(YlVhYxE3L3fUbUjOqUGha)Yj2siCtqH8acYfeFp6b5FmXTwixiNbWa3euipGG8agY6HJEqowDovcAgKhWXRSqoDuLNfYLaijMqUoqUlkAZc5ZzZc5HaqhKJvNtLGMb5bC8klK3mi3Tf5VSqoUObUjOqEab5JiDuLEZrqEZGCa(9S0dY7tP6CRnlKdMfYvaeK7V3Ccca5fTobspixbqmcYd0R2bTeZa5qUGGNnlKdokaQG8(GCWHXG8yNdqzg4MGc5beKl4nxGuPqU6voPPoc5Y5ET2ZXGCDGCzwPLsQx5KYmWnbfYdiipGHwNajixqdG8steJrNKe0qEoDu1si3LApNbUjOqEab5cIVhKlKB9tsqUGym2xRzHCXQNQ1Sg4MGc5beKhWq9jNsCkxjiNnReKpri)dyDMLa8hjOzqo9ALzqFXAITLq)Gc5bCQClKVeu49dUjOqoavfzlHyJDERaWbnYzfBwVIBDTNtwEuXM1RsSHBckKhWjWc3RSq(YlVhYxE3L3fUbUjOqUGha)Yj2siCtqH8acYfeFp6b5FmXTwixiNbWa3euipGG8agY6HJEqowDovcAgKhWXRSqoDuLNfYLaijMqUoqUlkAZc5ZzZc5HaqhKJvNtLGMb5bC8klK3mi3Tf5VSqoUObUjOqEab5JiDuLEZrqEZGCa(9S0dY7tP6CRnlKdMfYvaeK7V3Ccca5fTobspixbqmcYd0R2bTeZa5qUGGNnlKdokaQG8(GCWHXG8yNdqzg4MGc5beKl4nxGuPqU6voPPoc5Y5ET2ZXGCDGCzwPLsQx5KYmWnbfYdiipGHwNajixqdG8steJrNKe0qEoDu1si3LApNbUjOqEab5cIVhKlKB9tsqUGym2xRzHCXQNQ1Sg4MGc5beKhWq9jNsCkxjiNnReKpri)dyDMLa8hjOzqo9ALzGBckKhqq(sWCcAfYXzeKluHRUfY)wNbaYdHnKlOSTpipGBjgGIUxF5qEhHCSauodaK3StqRqoUObUbUjOqUGWHJK4k9GCqkofb5Yzf0vihKY7JzGCbrPKevgKFZfqa8AnIBHCxQ9CmiFoBwdCtqHCxQ9CmJyrYzf0vGrRZWeUjOqUl1EoMrSi5Sc6QaaXooZdUjOqUl1EoMrSi5Sc6QaaX2XZxPtDTNdUjOqUGVc5ndYdnLcaYBfYJtb5UDDykKtbsv25iixhiF17t9(GCfq5maWnUu75ygXIKZkORcae7a9QDqlT)8vcioJskGYza2hOBXjG7c34sTNJzelsoRGUkaqSd0R2bT0(ZxjG4mkPakNbyFGUfNaU8(oc03jvTsMqT9LIwIbOO71xUHoh0sp4gxQ9CmJyrYzf0vbaIDGE1oOL2F(kbSAXK2smz7d0T4eWLeUXLAphZiwKCwbDvaGyxuEnHua77iqq8y0SoZHzFP4uRM3e6YOULo1aAN5PUDoMHoh0sp4gxQ9CmJyrYzf0vbaInoJsTsR7pFLa67KbWlNLIZPPjMeNqub34sTNJzelsoRGUkaqSfRjKDFhbcIhJM1zom7lfNA18MqhCtqH8)5ImaJc5L3pihepgPhKZuxzqoifNIGC5Sc6kKds59XGC)EqUyrbK4OAF5qEZG83CKbUjOqUl1EoMrSi5Sc6QaaXMDUidWOjM6kdUXLAphZiwKCwbDvaGyloAphCJl1EoMrSi5Sc6QaaXgKkgvyUVJabXJrZ6mhM9LItTAEtOdUXLAphZiwKCwbDvaGyRDovSueVYUVJabXJrZ6mhM9LItTAEtOldiEmA0oNkwkIxznVj0b34sTNJzelsoRGUkaqSLUMItTUVJabXJrZ6mhM9LItTAEtOdUbUjOqUGWHJK4k9GCkqQYc5AVsqUcGGCxQtb5ndY9a926GwYa34sTNJbKHjU1MaDgG9DeyaaXJrJynHSgCXmbaepgnma(BcTs2NbxeUXLAphtaGyx4xYLApxY2mD)5Reqq36NK23rGQBPtnGU1pjL8ySVwZAOZbT0ldiEmAwN5WSVuCQvdUiCJl1EoMaaXw6wBYLApxY2mD)5ReWrKoQ23rGbyePJQ0BokJ6w6udZbPsNrbyOZbT0ltyG4XObKkgvyAWfxSaepgn9j96CTNZGlgmCJl1EoMaaXw6Ako16(ocmaG4XOr6Ako1QbxeUXLAphtaGyxoM0(oceepgnI1eYAWfxSaepgnma(BcTs2NbxeUXLAphtaGylDRn5sTNlzBMU)8vcOCg7BcDm4gxQ9CmbaIDKQr2dolb2kTxMvAPK6voPmGB33rGVrnvlA0wIzF5zEJAQw0u0Q3hlilnJ6voPgTxPKoPxtcVD3mHPULo1WCqQ0zuag6Cql9cgUXLAphtaGyhPAK9GZsGTs7LzLwkPELtkd429DeO6w6udZbPsNrbyOZbT0lJCwbNK40NYeMjswBs9kNuMrbuodqs6AM3OMQfnAlXSV8mVrnvlAkA17JfKLMr9kNuJ2RusN0RjHFJAQw0u0Q3htGa9QDqlzQwmPTetMG5sTNZuTOrBjMjTxj4MGc5Uu75ycae7IYRjKcyFhbkNvWjjo9PmGHpdiEmAel656uztSqDupIXm4Izu3sNAaTZ8u3ohZqNdAPxgq8y0aAN5PUDoM5nHo4gxQ9CmbaIDHFjxQ9CjBZ09NVsaJ91mauX23rGYzfCsItFkt4Da34sTNJjaqSLU1MCP2ZLSnt3F(kbmNoQCDkwYhAFhbYejRnPELtkZOakNbijDv4TWnUu75ycae7c)sUu75s2MP7pFLaMthvUofdUbUXLAphZiNX(MqhdiivmQWCFhbshv5zfg4s3ntyYzSVj0z0oNkwkIxznfT69Xeo8lwaIhJgTZPILI4vwdUyWWnUu75yg5m23e6ycaeBTZPILI4v29DeiDuLN18OylBvyGcYDxSaepgnANtflfXRSM3e6GBCP2ZXmYzSVj0Xeai2GuXOcZ(YHBCP2ZXmYzSVj0Xeai2kGPo2(oc0LAhiLOJwBIj8JyDrVK6voPSflkVFjkq6uJ)EmtFcVJWd34sTNJzKZyFtOJjaqSvauc)ah87LItjP9DeiiEmAksIPLySuCkjzWfxSaepgnANtflfXRSgCr4gxQ9CmJCg7BcDmbaI9kTov20etwCz)sVI8v2(oceepgnANtflfXRSgCXmG4XObKkgvyAEtOdUXLAphZiNX(MqhtaGydAN5LMysbqj6O1S77iqq8y0ODovSueVYAWfHBCP2ZXmYzSVj0Xeai2rQCBkw0TZS77iq5ScojXPpLbCx4gxQ9CmJCg7BcDmbaIDCK4m6L8DsvRucK819DeOl1oqkrhT2et4hX6IEj1RCszlwew59lrbsNA83Jz6tyb3UzOJQ8SMhfBzRcdm87gmCJl1EoMroJ9nHoMaaXweV6y2(YtGwNP77iqxQDGuIoATjMWpI1f9sQx5KYwSO8(LOaPtn(7Xm9jSGCx4gxQ9CmJCg7BcDmbaIDoUxV2V0et(oPAua77iqq8y0ODovSueVYAWfHBCP2ZXmYzSVj0Xeai2Y5K0PLR0lfT(kTVJabXJrJ25uXsr8kRbxeUXLAphZiNX(MqhtaGyxTOOLs9LyIUK23rGG4XOr7CQyPiEL1Glc34sTNJzKZyFtOJjaqSdnL9fi1xQi2C(jP9DeiiEmA0oNkwkIxzn4IWnUu75yg5m23e6ycae7ICX(YtrRVsS9DeO6voPgTxPKoPxtbzRj8lwewyQx5KAaqUvbyeLQWl5UlwOELtQba5wfGruQbb4Y7gCg1RCsnAVsjDsVMeEzbxWlweM6voPgTxPKojrPMwExHx6UzuVYj1O9kL0j9As4DSJGHBCP2ZXmYzSVj0Xeai29j96CTNBFhbshv5zfg4s3ntyYzSVj0z0oNkwkIxznfT69XeEB4xSaepgnANtflfXRSgCXGHBCP2ZXmYzSVj0Xeai2IJ2ZTVJavVYj1O9kL0j9AkicYWVyryAVsjDsVMcY2LC3mHbIhJgqQyuHPbxCXcq8y00N0RZ1EodUyWbd34sTNJzKZyFtOJjaqSza83eALSV9DeOCwbNK40NYcs4Zqhv5zfgOl1Eot5ysg5W0mVrnLJjzexXTAlABQcYYMTzaXJrJ25uXsr8kRbxmtyG4XOb0oZtD7CmdU4IfbqDlDQb0oZtD7CmdDoOLEbNjSaOULo10N0RZ1EodDoOLElwiNX(MqNPpPxNR9CMIw9(ycVDjdotaaXJrtFsVox75m4IWnUu75yg5m23e6ycaeBCgLALw3F(kb0zac0pILkFNtLKt529De4JaXJrt57CQKCk3MEeiEmAEtOBXIhbIhJg5CpCP2bsP(Wm9iq8y0GlMr9kNuJ2RusNKOutlD3GS1e(flcWJaXJrJCUhUu7aPuFyMEeiEmAWfZe2JaXJrt57CQKCk3MEeiEmAyQlXuyGlh(aA7Uc2JaXJrdODMxAIjfaLOJwZAWfxSq7vkPt61uq2XUbNbepgnANtflfXRSMIw9(ycVDx4gxQ9CmJCg7BcDmbaInoJsTsR7PyKKA68vcOmR0oAnxltGwNP77iWWOJQ8SMhfBzRcdKoQYZAkkNobBPbNbepgnANtflfXRSM3e6YeaFNu1kzeuXVClLI4vwdDoOLEWnUu75yg5m23e6ycaeBCgLALw3tXij105ReqzwPD0AUwMaTot33rGG4XOr7CQyPiEL1GlMX3jvTsgbv8l3sPiEL1qNdAPhCJl1EoMroJ9nHoMaaXgNrPwP19umssnD(kb03jdGxolfNtttmjoHOAFhbshv5znpk2Ywfgy43fUXLAphZiNX(MqhtaGyJZOuR0kBFhbcIhJgTZPILI4vwdU4IfAVsjDsVMcYY7c3a34sTNJzI91mauXawuEnHua77iqq8y0iw0Z1PYMyH6OEeJzWfZOULo1aAN5PUDoMHoh0sVmG4XOb0oZtD7CmdtDjMbzz4gxQ9CmtSVMbGkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZe7RzaOIjaqSzEGEoLQXR9DeiiEmAyEGEoLQXlZBcDWnUu75yMyFndavmbaIT4m2urSbVK0(4uPJcNcClCJl1EoMj2xZaqftaGylw9QBtHkxbSxMvAPK6voPmGB33rGmrYAtQx5KYmIvV62uOYvacVnZBut1IMIw9(ybzhWnUu75yMyFndavmbaIT4m2urSbVK0(4uPJcNcClCJl1EoMj2xZaqftaGylw9QBtHkxbSxMvAPK6voPmGB33rGmrYAtQx5KYmIvV62uOYvacdCz4gxQ9CmtSVMbGkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZe7RzaOIjaqSRwCVmR0sj1RCsza3UVJadG6w6udZbPsNrbyOZbT0ltrXIyaCqlLr9kNuJ2RusN0RjHFJAQw0u0Q3htGa9QDqlzQwmPTetMG5sTNZuTOrBjMjTxj4gxQ9CmtSVMbGkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZe7RzaOIjaqSRwCVmR0sj1RCsza3UVJav3sNAyoiv6mkadDoOLEzclaAlXSV8flkA17JfeGp8Y1EobBxZsZisfRzkDAAf3QTOTPs43OMQfnIR4wTfTnvbNr9kNuJ2RusN0RjHFJAQw0u0Q3htGa9QDqlzQwmPTetMGf2wbEJAQw0OTeZ(YfSLgSG5sTNZuTOrBjMjTxj4gxQ9CmtSVMbGkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZe7RzaOIjaqSzEGEoLQXR9DeiiEmAyEGEoLQXltrREFSGSDz4gxQ9CmtSVMbGkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZe7RzaOIjaqSx9EDFhbcIhJMUMljO6HygCr4gxQ9CmtSVMbGkMaaXos1i7bNLaBL2V6Hlrhv5zbUDVmR0sj1RCsza3c3a34sTNJzYPJkxNIbSO8AcPa23rGQBPtnG2zEQBNJzOZbT0ldiEmAel656uztSqDupIXm4IzaXJrdODMN625yM3e6YiNvWjjo9PmG7iZBut5ysMIw9(ybzhWnUu75yMC6OY1Pycae7IYRjKcyFhbQULo1aAN5PUDoMHoh0sVmG4XOb0oZtD7CmZBcDzaXJrJyrpxNkBIfQJ6rmMbxmJ6w6uJf)8k1htSlx75m05Gw6L5nQPCmjtrREFSGSfUXLAphZKthvUoftaGydw4QBtmRZaSVJazIK1MuVYjLzalC1TjM1zae(rSUOxs9kNuwMWcGVtQALmHA7lfTedqr3RVCdDoOLElw8g1OakNbijD1OTeZ(YdgUXLAphZKthvUoftaGyloJnveBWljTpov6OWPa3c34sTNJzYPJkxNIjaqSvaLZaKKUUVJadROyrmaoOLYWejRnPELtkZOakNbijDv4LdgUXLAphZKthvUoftaGyloJnveBWljTpov6OWPa3c34sTNJzYPJkxNIjaqSvaLZaKKUUVJadtDlDQHjPtttmbAN5zOZbT0ldiEmAys600etG2zEM3e6codtKS2K6voPmJcOCgGK0vHxkCJl1EoMjNoQCDkMaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZKthvUoftaGyZc1Ius66(oceepgnmjDAAIjq7mpdU4IfH5sTNZWc1Ius6Q55REojymrYAtQx5KYmSqTiLKUkCyUu75mLJjzE(QNtceMl1Eot5ysjqlrpJ2smtpF1Zjbl8bhCWWnUu75yMC6OY1PycaeBXzSPIydEjP9XPshfof4w4gxQ9CmtoDu56umbaID5ys7LzLwkPELtkd429Deya0wIzF5lwewau3sNAaTZ8u3ohZqNdAPxMIw9(yb5HxU2Zjy7AwAWzuVYj1O9kL0j9As4Da34sTNJzYPJkxNIjaqSfNXMkIn4LK2hNkDu4uGBHBCP2ZXm50rLRtXeai2LJjTxMvAPK6voPmGB33rGQBPtnG2zEQBNJzOZbT0ldiEmAaTZ8u3ohZGlMjSWkA17JfeGlXGZisfRzkDAAf3QTOTPs43OMYXKmIR4wTfTnvc2UMLm8bNr9kNuJ2RusN0RjH3bCtqHCbLTcaYdyj4d5zGCHWApKhIGCPFqooJG81zUyxeKRdKZ8ajixiSGCjaVYj2Ei3T2juF5qoodY1bYbjvPcYlkwedaKxoMeCJl1EoMjNoQCDkMaaXEDMl2fLKUUVJabXJrdODMN625ygCXmG4XOrSONRtLnXc1r9igZ8Mqxg5ScojXPpLfKWd34sTNJzYPJkxNIjaqSxN5IDrjPR7LzLwkPELtkd429DeyrXIyaCqlb34sTNJzYPJkxNIjaqSblC1TjM1za23rGHfaFNu1kzc12xkAjgGIUxF5g6Cql9wS4nQrbuodqs6QrBjM9LhCgq8y0ODovSueVYAWfZew59lrbsNA83Jz6t4W2kWQhUKeGx5elGKa8kNyPy5sTNZTblyfjb4voL0ELcgUXLAphZKthvUoftaGyloJnveBWljTpov6OWPa3c34sTNJzYPJkxNIjaqSvaLZaKKUUVJalkwedGdAPmHfwGE1oOLm4mkPakNba4YzclaG4XOPpPxNR9CgCXfl8DsvRKjuBFPOLyak6E9LBOZbT0l4GxSGjswBs9kNuMrbuodqs6QWBdgUjOqUl1EoMjNoQCDkMaaXwbuodqs66(ocSOyrmaoOLYeOxTdAjdoJskGYzaaUndiEmAKwYlPZ0(Ynf5sntybaepgn9j96CTNZGlUyHVtQALmHA7lfTedqr3RVCdDoOLEbd34sTNJzYPJkxNIjaqSfNXMkIn4LK2hNkDu4uGBHBCP2ZXm50rLRtXeai2SqTiLKUUVJazIK1MuVYjLzyHArkjDv4TWnUu75yMC6OY1PycaeBgGIE77iW3OMYXKmfT69XeomxQ9CggGIEg5WubCP2ZzkhtYihMgq0rvE2Gfuqhv5znfLt3IfG4XOrAjVKot7l3uKlv4g4gxQ9CmtoDu56uSKpeqXzSPIydEjP9XPshfof4w4gxQ9CmtoDu56uSKpKaaXwbuodqs66(ocmSIIfXa4GwAXcxQDGu6nQrbuodqs6AqCP2bsj6O1Myckwo4mmrYAtQx5KYmkGYzassxfE5flu3sNAys600etG2zEg6Cql9YaIhJgMKonnXeODMN5nHUmmrYAtQx5KYmkGYzassxfEPlweaTLy2xEgFNu1kzc12xkAjgGIUxF5g6Cql9GBCP2ZXm50rLRtXs(qcaeBXzSPIydEjP9XPshfof4w4gxQ9CmtoDu56uSKpKaaXgSWv3MywNbyFhbYejRnPELtkZaw4QBtmRZai8JyDrVK6voPm4gxQ9CmtoDu56uSKpKaaXwCgBQi2GxsAFCQ0rHtbUfUXLAphZKthvUofl5djaqSzHArkjDDFhbcIhJgMKonnXeODMNbxeUbUjOqowaiiFePJkipNoQCRnlKhhRDcb5kacYTtElH8jc5kacYlIPq(eHCfab5UODpKdIRqEZGCgj6LR0dYhCfYbqfb5XPGC7K3s3c5sRxTMfUjOqUGscYd1wlKpI0b5HAfaKJvaFpKNDWHCPFqoZJKnlKlDMc5kGMb5XAwHCMsUvba5HAfWGRqoyroM9Ld5TAGBCP2ZXmJiDubu7CQyPiELfUjOqUGOnKNLb5JiDqEOwba5LJjThYLZXWx7lhYzk5wfaK73dYNJGCHWcYLa8kNG8W6iKRULoLEbd34sTNJzgr6OsaGyxoM0(ocmaAlXSV8flaXJrJynHSgCr4MGc5bSiLb5RoMeKZWlcYdrqoDpixbqq(ishvqUGqmkGDC6KKGqqEia0b5dEb5XUykKxTiK3mixBjM9Ld3eui3LAphZmI0rLaaXoqVAh0s7pFLaoI0rv6nhTpq3ItaFJAQw0OTeZ(YHBckKluroMq(GRq(eHCfab5Uu75GCBZu4MGc5Uu75yMrKoQeai2H8w3ZijWDn7U729De4But1IgTLy2xoCtqHCb)iKhIGCaEGeKhWsWFpK73dYb4bsNGwHCxu020dYBfYZskKJZiiFDMl2fzGBCP2ZXmJiDujaqSxN5IDrjPR77iWaOTeZ(YHBckKFdKFe9GCDG8qERqECkip8qUGxaBmi3VSRtr7HCbvCMc5vlc5(9G8qeK7fb54IqUFpiVWVRVC4gxQ9CmZishvcaeBXQxDBku5kG9DeOl1oqkrhT2et4TzcdepgnANtflfXRSgCXmHbIhJgq7mp1TZXm4Ilwea1T0Pgq7mp1TZXm05Gw6fCMWcG6w6uJf)8k1htSlx75m05Gw6TyXBuZ6mxSlkjD1OTeZ(Ydota0wIzF5bd34sTNJzgr6OsaGyxT4(oc0LAhiLOJwBIbCBMWaXJrJ25uXsr8kRbxmtyG4XOb0oZtD7CmdU4IfbqDlDQb0oZtD7CmdDoOLEbN5nQPCmjJ2sm7lptybqDlDQXIFEL6Jj2LR9Cg6Cql9wS4nQzDMl2fLKUA0wIzF5bNjaAlXSV8GHBGBCP2ZXmGU1pjbKHFXUO9DeyrXIyaCqlTyryUu7aPeD0AtmH3MjS3Ogg(f7ImfflIbWbT0IfUu7aP0Budd)IDrbXLAhiLOJwBIfCWWnUu75ygq36NKeai2w8ZRetRgtAFhb6sTdKs0rRnXeEhlweMl1oqkrhT2et4TzaXJrJf)8krRItiQwPtn4Ibd34sTNJzaDRFssaGyZgRxPqLRa23rGUu7aPeD0AtmHxodiEmAyJ1ReTkoHOALo1Glc34sTNJzaDRFssaGyZuVy4vob34sTNJzaDRFssaGyZgRxPqLRa23rGG4XOHnwVs0Q4eIQv6udUiCJl1EoMb0T(jjbaITf)8kX0QXK23rGG4XOXIFELOvXjevR0PgCr4gxQ9CmdOB9tscaeB2y9kfQCfa6hivSEoeglV7wb3Ul5UH3S8sxo8OFiVU(YzOVG)Q4uk9G8LeYDP2Zb52MPmdCd674kGPq)FVk4H(2MPmewO)ishviSqySfHf67sTNd91oNkwkIxzrF6Cql9qcHueglJWc9PZbT0dje6lRwPQD0paqU2sm7lhYxSaYbXJrJynHSgCr03LAph6xoMesrySuewOpDoOLEiHqFz1kvTJ(baY1wIzF5OVl1Eo0FDMl2fLKUIueg7aHf6tNdAPhsi0xwTsv7OVl1oqkrhT2edYfgY3c5zG8WGCq8y0ODovSueVYAWfH8mqEyqoiEmAaTZ8u3ohZGlc5lwa5baYv3sNAaTZ8u3ohZqNdAPhKhmKNbYddYdaKRULo1yXpVs9Xe7Y1EodDoOLEq(Ifq(BuZ6mxSlkjD1OTeZ(YH8GH8mqEaGCTLy2xoKhm67sTNd9fRE1TPqLRaqkcJWJWc9PZbT0dje6lRwPQD03LAhiLOJwBIb5aH8TqEgipmihepgnANtflfXRSgCripdKhgKdIhJgq7mp1TZXm4Iq(IfqEaGC1T0Pgq7mp1TZXm05Gw6b5bd5zG83OMYXKmAlXSVCipdKhgKhaixDlDQXIFEL6Jj2LR9Cg6Cql9G8flG83OM1zUyxus6QrBjM9Ld5bd5zG8aa5AlXSVCipy03LAph6xTisrk6NthvUofl5dHWcHXwewOpDoOLEiHq)4uPJcNIWyl67sTNd9fNXMkIn4LKqkcJLryH(05Gw6Hec9LvRu1o6hgKxuSigah0sq(IfqUl1oqk9g1OakNbijDfYdcK7sTdKs0rRnXGCbfq(YqEWqEgiNjswBs9kNuMrbuodqs6kKlmKVmKVybKRULo1WK0PPjMaTZ8m05Gw6b5zGCq8y0WK0PPjMaTZ8mVj0b5zGCMizTj1RCszgfq5majPRqUWq(sH8flG8aa5AlXSVCipdK77KQwjtO2(srlXau096l3qNdAPh67sTNd9vaLZaKKUIueglfHf6tNdAPhsi0pov6OWPim2I(Uu75qFXzSPIydEjjKIWyhiSqF6Cql9qcH(YQvQAh9zIK1MuVYjLzalC1TjM1zaGCHH8hX6IEj1RCszOVl1Eo0hSWv3MywNbaPimcpcl0Noh0spKqOFCQ0rHtrySf9DP2ZH(IZytfXg8ssifHHGeHf6tNdAPhsi0xwTsv7OpiEmAys600etG2zEgCr03LAph6Zc1Ius6ksrk6)OOJBvewim2IWc9PZbT0dje6lRwPQD0paqoiEmAeRjK1Glc5zG8aa5G4XOHbWFtOvY(m4IOVl1Eo0NHjU1MaDgaKIWyzewOpDoOLEiHqFz1kvTJ(QBPtnGU1pjL8ySVwZAOZbT0dYZa5G4XOzDMdZ(sXPwn4IOVl1Eo0VWVKl1EUKTzk6BBMMoFLqFq36NKqkcJLIWc9PZbT0dje6lRwPQD0paq(ishvP3CeKNbYv3sNAyoiv6mkadDoOLEqEgipmihepgnGuXOctdUiKVybKdIhJM(KEDU2ZzWfH8GrFxQ9COV0T2Kl1EUKTzk6BBMMoFLq)rKoQqkcJDGWc9PZbT0dje6lRwPQD0paqoiEmAKUMItTAWfrFxQ9COV01uCQvKIWi8iSqF6Cql9qcH(YQvQAh9bXJrJynHSgCriFXcihepgnma(BcTs2Nbxe9DP2ZH(LJjHuegcsewOpDoOLEiHqFxQ9COV0T2Kl1EUKTzk6BBMMoFLqF5m23e6yifHXseHf6tNdAPhsi03LAph6hPAK9GZsGTsOVSALQ2r)3OMQfnAlXSVCipdK)g1uTOPOvVpgKheiFPqEgix9kNuJ2RusN0RjixyiF7UqEgipmixDlDQH5GuPZOam05Gw6b5bJ(YSslLuVYjLHWylsrySKiSqF6Cql9qcH(Uu75q)ivJShCwcSvc9LvRu1o6RULo1WCqQ0zuag6Cql9G8mqUCwbNK40NYGCHHCMizTj1RCszgfq5majPRqEgi)nQPArJ2sm7lhYZa5VrnvlAkA17Jb5bbYxkKNbYvVYj1O9kL0j9AcYfgYFJAQw0u0Q3hdYfaYd0R2bTKPAXK2smzqUGb5Uu75mvlA0wIzs7vc9LzLwkPELtkdHXwKIWqWHWc9PZbT0dje6lRwPQD0xoRGtsC6tzqUWq(oqFxQ9COFHFjxQ9CjBZu032mnD(kH(X(AgaQyifHX2DryH(05Gw6Hec9LvRu1o6ZejRnPELtkZOakNbijDfYfgY3I(Uu75qFPBTjxQ9CjBZu032mnD(kH(50rLRtXs(qifHX2TiSqF6Cql9qcH(Uu75q)c)sUu75s2MPOVTzA68vc9ZPJkxNIHuKI(IfjNvqxryHWylcl0Noh0spKqO)iI(msrFxQ9COFGE1oOLq)aDloH(7I(b6v68vc9XzusbuodasrySmcl0Noh0spKqO)iI(msrFxQ9COFGE1oOLq)aDloH(lJ(YQvQAh99DsvRKjuBFPOLyak6E9LBOZbT0d9d0R05Re6JZOKcOCgaKIWyPiSqF6Cql9qcH(Ji6Zif9DP2ZH(b6v7Gwc9d0T4e6VKOFGELoFLq)QftAlXKHueg7aHf6tNdAPhsi0xwTsv7OpiEmAwN5WSVuCQvZBcDqEgixDlDQb0oZtD7CmdDoOLEOVl1Eo0VO8AcPaqkcJWJWc9PZbT0dje6F(kH((oza8YzP4CAAIjXjevOVl1Eo033jdGxolfNtttmjoHOcPimeKiSqF6Cql9qcH(YQvQAh9bXJrZ6mhM9LItTAEtOd9DP2ZH(I1eYIueglrewOVl1Eo0xC0Eo0Noh0spKqifHXsIWc9PZbT0dje6lRwPQD0hepgnRZCy2xko1Q5nHo03LAph6dsfJkmrkcdbhcl0Noh0spKqOVSALQ2rFq8y0SoZHzFP4uRM3e6G8mqoiEmA0oNkwkIxznVj0H(Uu75qFTZPILI4vwKIWy7UiSqF6Cql9qcH(YQvQAh9bXJrZ6mhM9LItTAEtOd9DP2ZH(sxtXPwrksr)C6OY1PyiSqySfHf6tNdAPhsi0xwTsv7OV6w6udODMN625yg6Cql9G8mqoiEmAel656uztSqDupIXm4IqEgihepgnG2zEQBNJzEtOdYZa5YzfCsItFkdYbc57aYZa5VrnLJjzkA17Jb5bbY3b67sTNd9lkVMqkaKIWyzewOpDoOLEiHqFz1kvTJ(QBPtnG2zEQBNJzOZbT0dYZa5G4XOb0oZtD7CmZBcDqEgihepgnIf9CDQSjwOoQhXygCripdKRULo1yXpVs9Xe7Y1EodDoOLEqEgi)nQPCmjtrREFmipiq(w03LAph6xuEnHuaifHXsryH(05Gw6Hec9LvRu1o6ZejRnPELtkZaw4QBtmRZaa5cd5pI1f9sQx5KYG8mqEyqEaGCFNu1kzc12xkAjgGIUxF5g6Cql9G8flG83Ogfq5majPRgTLy2xoKhm67sTNd9blC1TjM1zaqkcJDGWc9PZbT0dje6hNkDu4uegBrFxQ9COV4m2urSbVKesryeEewOpDoOLEiHqFz1kvTJ(Hb5fflIbWbTeKNbYzIK1MuVYjLzuaLZaKKUc5cd5ld5bJ(Uu75qFfq5majPRifHHGeHf6tNdAPhsi0pov6OWPim2I(Uu75qFXzSPIydEjjKIWyjIWc9PZbT0dje6lRwPQD0pmixDlDQHjPtttmbAN5zOZbT0dYZa5G4XOHjPtttmbAN5zEtOdYdgYZa5mrYAtQx5KYmkGYzassxHCHH8LI(Uu75qFfq5majPRifHXsIWc9PZbT0dje6hNkDu4uegBrFxQ9COV4m2urSbVKesryi4qyH(05Gw6Hec9LvRu1o6dIhJgMKonnXeODMNbxeYxSaYddYDP2ZzyHArkjD188vpNGCbdYzIK1MuVYjLzyHArkjDfYfgYddYDP2ZzkhtY88vpNGCbG8WGCxQ9CMYXKsGwIEgTLyME(QNtqUGb5HhYdgYdgYdg9DP2ZH(SqTiLKUIuegB3fHf6tNdAPhsi0pov6OWPim2I(Uu75qFXzSPIydEjjKIWy7wewOpDoOLEiHqFxQ9COF5ysOVSALQ2r)aa5AlXSVCiFXcipmipaqU6w6udODMN625yg6Cql9G8mqErREFmipiq(dVCTNdYfmiFxZsH8GH8mqU6voPgTxPKoPxtqUWq(oqFzwPLsQx5KYqySfPim2Umcl0Noh0spKqOFCQ0rHtrySf9DP2ZH(IZytfXg8ssifHX2LIWc9PZbT0dje67sTNd9lhtc9LvRu1o6RULo1aAN5PUDoMHoh0spipdKdIhJgq7mp1TZXm4IqEgipmipmiVOvVpgKheGq(seYdgYZa5IuXAMsNMwXTAlABQGCHH83OMYXKmIR4wTfTnvqUGb57AwYWd5bd5zGC1RCsnAVsjDsVMGCHH8DG(YSslLuVYjLHWylsrySDhiSqF6Cql9qcH(YQvQAh9bXJrdODMN625ygCripdKdIhJgXIEUov2eluh1JymZBcDqEgixoRGtsC6tzqEqG8WJ(Uu75q)1zUyxus6ksrySn8iSqF6Cql9qcH(Uu75q)1zUyxus6k6lRwPQD0VOyrmaoOLqFzwPLsQx5KYqySfPim2kiryH(05Gw6Hec9LvRu1o6hgKhai33jvTsMqT9LIwIbOO71xUHoh0spiFXci)nQrbuodqs6QrBjM9Ld5bd5zGCq8y0ODovSueVYAWfH8mqEyqE59lrbsNA83Jz6dYfgYddY3c5ca5RE4ssaELtmipGGCjaVYjwkwUu75ClKhmKlyqErsaELtjTxjipy03LAph6dw4QBtmRZaGuegBxIiSqF6Cql9qcH(XPshfofHXw03LAph6loJnveBWljHuegBxsewOpDoOLEiHqFz1kvTJ(fflIbWbTeKNbYddYddYd0R2bTKbNrjfq5maqoqiFzipdKhgKhaihepgn9j96CTNZGlc5lwa5(oPQvYeQTVu0smafDV(Yn05Gw6b5bd5bd5lwa5mrYAtQx5KYmkGYzassxHCHH8TqEWOVl1Eo0xbuodqs6ksrySvWHWc9PZbT0dje6hNkDu4uegBrFxQ9COV4m2urSbVKesryS8UiSqF6Cql9qcH(YQvQAh9zIK1MuVYjLzyHArkjDfYfgY3I(Uu75qFwOwKssxrkcJL3IWc9PZbT0dje6lRwPQD0)nQPCmjtrREFmixyipmi3LApNHbOONromfYfaYDP2ZzkhtYihMc5beKthv5zH8GHCbfqoDuLN1uuoDq(IfqoiEmAKwYlPZ0(Ynf5sf9DP2ZH(maf9qksr)yFndavmewim2IWc9PZbT0dje6lRwPQD0hepgnIf9CDQSjwOoQhXygCripdKRULo1aAN5PUDoMHoh0spipdKdIhJgq7mp1TZXmm1Lyc5bbYxg9DP2ZH(fLxtifasrySmcl0Noh0spKqOFCQ0rHtrySf9DP2ZH(IZytfXg8ssifHXsryH(05Gw6Hec9LvRu1o6dIhJgMhONtPA8Y8Mqh67sTNd9zEGEoLQXlKIWyhiSqF6Cql9qcH(XPshfofHXw03LAph6loJnveBWljHuegHhHf6tNdAPhsi03LAph6lw9QBtHkxbG(YQvQAh9zIK1MuVYjLzeRE1TPqLRaGCHH8TqEgi)nQPArtrREFmipiq(oqFzwPLsQx5KYqySfPimeKiSqF6Cql9qcH(XPshfofHXw03LAph6loJnveBWljHueglrewOpDoOLEiHqFxQ9COVy1RUnfQCfa6lRwPQD0NjswBs9kNuMrS6v3McvUcaYfgiKVm6lZkTus9kNugcJTifHXsIWc9PZbT0dje6hNkDu4uegBrFxQ9COV4m2urSbVKesryi4qyH(05Gw6Hec9DP2ZH(vlI(YQvQAh9daKRULo1WCqQ0zuag6Cql9G8mqErXIyaCqlb5zGC1RCsnAVsjDsVMGCHH83OMQfnfT69XGCbG8a9QDqlzQwmPTetgKlyqUl1Eot1IgTLyM0ELqFzwPLsQx5KYqySfPim2Ulcl0Noh0spKqOFCQ0rHtrySf9DP2ZH(IZytfXg8ssifHX2TiSqF6Cql9qcH(Uu75q)QfrFz1kvTJ(QBPtnmhKkDgfGHoh0spipdKhgKhaixBjM9Ld5lwa5fT69XG8GaeYF4LR9CqUGb57AwkKNbYfPI1mLonTIB1w02ub5cd5VrnvlAexXTAlABQG8GH8mqU6voPgTxPKoPxtqUWq(But1IMIw9(yqUaqEGE1oOLmvlM0wIjdYfmipmiFlKlaK)g1uTOrBjM9Ld5cgKVuipyixWGCxQ9CMQfnAlXmP9kH(YSslLuVYjLHWylsrySDzewOpDoOLEiHq)4uPJcNIWyl67sTNd9fNXMkIn4LKqkcJTlfHf6tNdAPhsi0xwTsv7OpiEmAyEGEoLQXltrREFmipiq(2LrFxQ9COpZd0ZPunEHuegB3bcl0Noh0spKqOFCQ0rHtrySf9DP2ZH(IZytfXg8ssifHX2WJWc9PZbT0dje6lRwPQD0hepgnDnxsq1dXm4IOVl1Eo0F17vKIWyRGeHf6tNdAPhsi0F1dxIoQYZI(BrFxQ9COFKQr2dolb2kH(YSslLuVYjLHWylsrk6lNX(MqhdHfcJTiSqF6Cql9qcH(YQvQAh9PJQ8SqUWaH8LUlKNbYddYLZyFtOZODovSueVYAkA17Jb5cd5HhYxSaYbXJrJ25uXsr8kRbxeYdg9DP2ZH(GuXOctKIWyzewOpDoOLEiHqFz1kvTJ(0rvEwZJITSvixyGqUGCxiFXcihepgnANtflfXRSM3e6qFxQ9COV25uXsr8klsrySuewOVl1Eo0hKkgvy2xo6tNdAPhsiKIWyhiSqF6Cql9qcH(YQvQAh9DP2bsj6O1MyqUWq(JyDrVK6voPmiFXciV8(LOaPtn(7Xm9b5cd57i8OVl1Eo0xbm1XqkcJWJWc9PZbT0dje6lRwPQD0hepgnfjX0smwkoLKm4Iq(IfqoiEmA0oNkwkIxzn4IOVl1Eo0xbqj8dCWVxkoLKqkcdbjcl0Noh0spKqOVSALQ2rFq8y0ODovSueVYAWfH8mqoiEmAaPIrfMM3e6qFxQ9CO)kTov20etwCz)sVI8vgsrySeryH(05Gw6Hec9LvRu1o6dIhJgTZPILI4vwdUi67sTNd9bTZ8stmPaOeD0AwKIWyjryH(05Gw6Hec9LvRu1o6lNvWjjo9PmihiKVl67sTNd9Ju52uSOBNzrkcdbhcl0Noh0spKqOVSALQ2rFxQDGuIoATjgKlmK)iwx0lPELtkdYxSaYddYlVFjkq6uJ)EmtFqUWqUGBxipdKthv5znpk2YwHCHbc5HFxipy03LAph6hhjoJEjFNu1kLajFfPim2Ulcl0Noh0spKqOVSALQ2rFxQDGuIoATjgKlmK)iwx0lPELtkdYxSaYlVFjkq6uJ)EmtFqUWqUGCx03LAph6lIxDmBF5jqRZuKIWy7wewOpDoOLEiHqFz1kvTJ(G4XOr7CQyPiEL1GlI(Uu75q)CCVETFPjM8Ds1OaqkcJTlJWc9PZbT0dje6lRwPQD0hepgnANtflfXRSgCr03LAph6lNtsNwUsVu06ResrySDPiSqF6Cql9qcH(YQvQAh9bXJrJ25uXsr8kRbxe9DP2ZH(vlkAPuFjMOljKIWy7oqyH(05Gw6Hec9LvRu1o6dIhJgTZPILI4vwdUi67sTNd9dnL9fi1xQi2C(jjKIWyB4ryH(05Gw6Hec9LvRu1o6RELtQr7vkPt61eKheiFRj8q(IfqEyqEyqU6voPgaKBvagrPc5cd5l5Uq(IfqU6voPgaKBvagrPc5bbiKV8UqEWqEgix9kNuJ2RusN0RjixyiFzbhKhmKVybKhgKRELtQr7vkPtsuQPL3fYfgYx6UqEgix9kNuJ2RusN0RjixyiFh7aYdg9DP2ZH(f5I9LNIwFLyifHXwbjcl0Noh0spKqOVSALQ2rF6OkplKlmqiFP7c5zG8WGC5m23e6mANtflfXRSMIw9(yqUWq(2Wd5lwa5G4XOr7CQyPiEL1Glc5bJ(Uu75q)(KEDU2ZHuegBxIiSqF6Cql9qcH(YQvQAh9vVYj1O9kL0j9AcYdcKlidpKVybKhgKR9kL0j9AcYdcKVDj3fYZa5Hb5G4XObKkgvyAWfH8flGCq8y00N0RZ1EodUiKhmKhm67sTNd9fhTNdPim2UKiSqF6Cql9qcH(YQvQAh9LZk4KeN(ugKheip8qEgiNoQYZc5cdeYDP2ZzkhtYihMc5zG83OMYXKmIR4wTfTnvqEqG8LnBH8mqoiEmA0oNkwkIxzn4IqEgipmihepgnG2zEQBNJzWfH8flG8aa5QBPtnG2zEQBNJzOZbT0dYdgYZa5Hb5baYv3sNA6t615ApNHoh0spiFXcixoJ9nHotFsVox75mfT69XGCHH8TljKhmKNbYdaKdIhJM(KEDU2ZzWfrFxQ9COpdG)MqRK9HuegBfCiSqF6Cql9qcH(Uu75qFNbiq)iwQ8DovsoLBrFz1kvTJ(pcepgnLVZPsYPCB6rG4XO5nHoiFXci)rG4XOro3dxQDGuQpmtpcepgn4IqEgix9kNuJ2RusNKOutlDxipiq(wt4H8flG8aa5pcepgnY5E4sTdKs9Hz6rG4XObxeYZa5Hb5pcepgnLVZPsYPCB6rG4XOHPUetixyGq(YHhYdiiF7UqUGb5pcepgnG2zEPjMuauIoAnRbxeYxSaY1ELs6KEnb5bbY3XUqEWqEgihepgnANtflfXRSMIw9(yqUWq(2Dr)Zxj03zac0pILkFNtLKt5wKIWy5DryH(05Gw6Hec9DP2ZH(YSs7O1CTmbADMI(YQvQAh9ddYPJQ8SMhfBzRqUWaHC6OkpRPOC6GCbdYxkKhmKNbYbXJrJ25uXsr8kR5nHoipdKhai33jvTsgbv8l3sPiEL1qNdAPh6tXij105Re6lZkTJwZ1YeO1zksryS8wewOpDoOLEiHqFxQ9COVmR0oAnxltGwNPOVSALQ2rFq8y0ODovSueVYAWfH8mqUVtQALmcQ4xULsr8kRHoh0sp0NIrsQPZxj0xMvAhTMRLjqRZuKIWy5LryH(05Gw6Hec9DP2ZH((oza8YzP4CAAIjXjevOVSALQ2rF6OkpR5rXw2kKlmqip87I(umssnD(kH((oza8YzP4CAAIjXjevifHXYlfHf6tNdAPhsi0xwTsv7OpiEmA0oNkwkIxzn4Iq(IfqU2RusN0Rjipiq(Y7I(Uu75qFCgLALwzifPOpOB9tsiSqySfHf6tNdAPhsi0xwTsv7OFrXIyaCqlb5lwa5Hb5Uu7aPeD0AtmixyiFlKNbYddYFJAy4xSlYuuSigah0sq(IfqUl1oqk9g1WWVyxeKhei3LAhiLOJwBIb5bd5bJ(Uu75qFg(f7IqkcJLryH(05Gw6Hec9LvRu1o67sTdKs0rRnXGCHH8Da5lwa5Hb5Uu7aPeD0AtmixyiFlKNbYbXJrJf)8krRItiQwPtn4IqEWOVl1Eo03IFELyA1ysifHXsryH(05Gw6Hec9LvRu1o67sTdKs0rRnXGCHH8LH8mqoiEmAyJ1ReTkoHOALo1GlI(Uu75qF2y9kfQCfasrySdewOVl1Eo0NPEXWRCc9PZbT0djesryeEewOpDoOLEiHqFz1kvTJ(G4XOHnwVs0Q4eIQv6udUi67sTNd9zJ1RuOYvaifHHGeHf6tNdAPhsi0xwTsv7OpiEmAS4NxjAvCcr1kDQbxe9DP2ZH(w8ZRetRgtcPimwIiSqFxQ9COpBSELcvUca9PZbT0djesrksrksria]] )


end
