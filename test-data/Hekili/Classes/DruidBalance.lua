-- DruidBalance.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DRUID' then
    local spec = Hekili:NewSpecialization( 102, true )

    spec:RegisterResource( Enum.PowerType.LunarPower, {
        fury_of_elune = {            
            aura = "fury_of_elune_ap",

            last = function ()
                local app = state.buff.fury_of_elune_ap.applied
                local t = state.query_time

                return app + floor( ( t - app ) / 0.5 ) * 0.5
            end,

            interval = 0.5,
            value = 2.5
        },

        natures_balance = {
            talent = "natures_balance",

            last = function ()
                local app = state.combat
                local t = state.query_time

                return app + floor( ( t - app ) / 1.5 ) * 1.5
            end,

            interval = 1.5, -- actually 0.5 AP every 0.75s, but...
            value = 1,
        }
    } )


    spec:RegisterResource( Enum.PowerType.Mana )
    spec:RegisterResource( Enum.PowerType.Energy )
    spec:RegisterResource( Enum.PowerType.ComboPoints )
    spec:RegisterResource( Enum.PowerType.Rage )


    -- Talents
    spec:RegisterTalents( {
        natures_balance = 22385, -- 202430
        warrior_of_elune = 22386, -- 202425
        force_of_nature = 22387, -- 205636

        tiger_dash = 19283, -- 252216
        renewal = 18570, -- 108238
        wild_charge = 18571, -- 102401

        feral_affinity = 22155, -- 202157
        guardian_affinity = 22157, -- 197491
        restoration_affinity = 22159, -- 197492

        mighty_bash = 21778, -- 5211
        mass_entanglement = 18576, -- 102359
        typhoon = 18577, -- 132469

        soul_of_the_forest = 18580, -- 114107
        starlord = 21706, -- 202345
        incarnation = 21702, -- 102560

        stellar_drift = 22389, -- 202354
        twin_moons = 21712, -- 279620
        stellar_flare = 22165, -- 202347

        shooting_stars = 21648, -- 202342
        fury_of_elune = 21193, -- 202770
        new_moon = 21655, -- 274281
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3543, -- 214027
        relentless = 3542, -- 196029
        gladiators_medallion = 3541, -- 208683

        celestial_downpour = 183, -- 200726
        celestial_guardian = 180, -- 233754
        crescent_burn = 182, -- 200567
        cyclone = 857, -- 209753
        deep_roots = 834, -- 233755
        dying_stars = 822, -- 232546
        faerie_swarm = 836, -- 209749
        ironfeather_armor = 1216, -- 233752
        moon_and_stars = 184, -- 233750
        moonkin_aura = 185, -- 209740
        prickling_thorns = 3058, -- 200549
        protector_of_the_grove = 3728, -- 209730
        thorns = 3731, -- 236696
    } )


    spec:RegisterPower( "lively_spirit", 279642, {
        id = 279648,
        duration = 20,
        max_stack = 1,
    } )


    -- Auras
    spec:RegisterAuras( {
        aquatic_form = {
            id = 276012,
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
        blessing_of_cenarius = {
            id = 238026,
            duration = 60,
            max_stack = 1,
        },
        blessing_of_the_ancients = {
            id = 206498,
            duration = 3600,
            max_stack = 1,
        },
        cat_form = {
            id = 768,
            duration = 3600,
            max_stack = 1,
        },
        celestial_alignment = {
            id = 194223,
            duration = 20,
            max_stack = 1,
        },
        dash = {
            id = 1850,
            duration = 10,
            max_stack = 1,
        },
        eclipse = {
            id = 279619,
        },
        empowerments = {
            id = 279708,
        },
        entangling_roots = {
            id = 339,
            duration = 30,
            type = "Magic",
            max_stack = 1,
        },
        feline_swiftness = {
            id = 131768,
        },
        flask_of_the_seventh_demon = {
            id = 188033,
            duration = 3600.006,
            max_stack = 1,
        },
        flight_form = {
            id = 276029,
        },
        force_of_nature = {
            id = 205644,
            duration = 15,
            max_stack = 1,
        },
        frenzied_regeneration = {
            id = 22842,
            duration = 3,
            max_stack = 1,
        },
        fury_of_elune_ap = {
            id = 202770,
            duration = 8,
            max_stack = 1,

            generate = function ()
                local foe = buff.fury_of_elune_ap
                local applied = action.fury_of_elune.lastCast

                if applied and now - applied < 8 then
                    foe.count = 1
                    foe.expires = applied + 8
                    foe.applied = applied
                    foe.caster = "player"
                    return
                end

                foe.count = 0
                foe.expires = 0
                foe.applied = 0
                foe.caster = "nobody"
            end,
        },
        growl = {
            id = 6795,
            duration = 3,
            max_stack = 1,
        },
        incarnation = {
            id = 102560,
            duration = 30,
            max_stack = 1,
            copy = "incarnation_chosen_of_elune"
        },
        ironfur = {
            id = 192081,
            duration = 7,
            max_stack = 1,
        },
        legionfall_commander = {
            id = 233641,
            duration = 3600,
            max_stack = 1,
        },
        lunar_empowerment = {
            id = 164547,
            duration = 45,
            type = "Magic",
            max_stack = 3,
        },
        mana_divining_stone = {
            id = 227723,
            duration = 3600,
            max_stack = 1,
        },
        mass_entanglement = {
            id = 102359,
            duration = 30,
            type = "Magic",
            max_stack = 1,
        },
        mighty_bash = {
            id = 5211,
            duration = 5,
            max_stack = 1,
        },
        moonfire = {
            id = 164812,
            duration = 22,
            tick_time = function () return 2 * haste end,
            type = "Magic",
            max_stack = 1,
        },
        moonkin_form = {
            id = 24858,
            duration = 3600,
            max_stack = 1,
        },
        prowl = {
            id = 5215,
            duration = 3600,
            max_stack = 1,
        },
        regrowth = {
            id = 8936,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },
        shadowmeld = {
            id = 58984,
            duration = 3600,
            max_stack = 1,
        },
        sign_of_the_critter = {
            id = 186406,
            duration = 3600,
            max_stack = 1,
        },
        solar_beam = {
            id = 81261,
            duration = 3600,
            max_stack = 1,
        },
        solar_empowerment = {
            id = 164545,
            duration = 45,
            type = "Magic",
            max_stack = 3,
        },
        stag_form = {
            id = 210053,
            duration = 3600,
            max_stack = 1,
            generate = function ()
                local form = GetShapeshiftForm()
                local stag = form and form > 0 and select( 4, GetShapeshiftFormInfo( form ) )

                local sf = buff.stag_form

                if stag == 210053 then
                    sf.count = 1
                    sf.applied = now
                    sf.expires = now + 3600
                    sf.caster = "player"
                    return
                end

                sf.count = 0
                sf.applied = 0
                sf.expires = 0
                sf.caster = "nobody"
            end,
        },
        starfall = {
            id = 191034,
            duration = function () return pvptalent.celestial_downpour.enabled and 16 or 8 end,
            max_stack = 1,

            generate = function ()
                local sf = buff.starfall

                if now - action.starfall.lastCast < 8 then
                    sf.count = 1
                    sf.applied = action.starfall.lastCast
                    sf.expires = sf.applied + 8
                    sf.caster = "player"
                    return
                end

                sf.count = 0
                sf.applied = 0
                sf.expires = 0
                sf.caster = "nobody"
            end
        },
        starlord = {
            id = 279709,
            duration = 20,
            max_stack = 3,
        },
        stellar_drift = {
            id = 202461,
            duration = 3600,
            max_stack = 1,
        },
        stellar_flare = {
            id = 202347,
            duration = 24,
            tick_time = function () return 2 * haste end,
            type = "Magic",
            max_stack = 1,
        },
        sunfire = {
            id = 164815,
            duration = 18,
            tick_time = function () return 2 * haste end,
            type = "Magic",
            max_stack = 1,
        },
        thick_hide = {
            id = 16931,
        },
        thorny_entanglement = {
            id = 241750,
            duration = 15,
            max_stack = 1,
        },
        thrash_bear = {
            id = 192090,
            duration = 15,
            max_stack = 3,
        },
        thrash_cat ={
            id = 106830, 
            duration = function()
                local x = 15 -- Base duration
                return talent.jagged_wounds.enabled and x * 0.80 or x
            end,
            tick_time = function()
                local x = 3 -- Base tick time
                return talent.jagged_wounds.enabled and x * 0.80 or x
            end,
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
        treant_form = {
            id = 114282,
            duration = 3600,
            max_stack = 1,
        },
        typhoon = {
            id = 61391,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        warrior_of_elune = {
            id = 202425,
            duration = 3600,
            type = "Magic",
            max_stack = 3,
        },
        wild_charge = {
            id = 102401,
        },
        yseras_gift = {
            id = 145108,
        },
        -- Alias for Celestial Alignment vs. Incarnation
        ca_inc = {
            alias = { "celestial_alignment", "incarnation" },
            aliasMode = "first", -- use duration info from the first buff that's up, as they should all be equal.
            aliasType = "buff",
            duration = function () return talent.incarnation.enabled and 30 or 20 end,
        },


        -- PvP Talents
        celestial_guardian = {
            id = 234081,
            duration = 3600,
            max_stack = 1,
        },

        cyclone = {
            id = 209753,
            duration = 6,
            max_stack = 1,
        },

        faerie_swarm = {
            id = 209749,
            duration = 5,
            type = "Magic",
            max_stack = 1,
        },

        moon_and_stars = {
            id = 234084,
            duration = 10,
            max_stack = 1,
        },

        moonkin_aura = {
            id = 209746,
            duration = 18,
            type = "Magic",
            max_stack = 3,
        },

        thorns = {
            id = 236696,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },


        -- Azerite Powers
        arcanic_pulsar = {
            id = 287790,
            duration = 3600,
            max_stack = 9,
        },

        dawning_sun = {
            id = 276153,
            duration = 8,
            max_stack = 1,
        },

        sunblaze = {
            id = 274399,
            duration = 20,
            max_stack = 1
        },
    } )


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
        removeBuff( "travel_form" )
        removeBuff( "aquatic_form" )
        removeBuff( "stag_form" )
        removeBuff( "celestial_guardian" )
    end )


    -- Function to apply form that is passed into it via string.
    spec:RegisterStateFunction( "shift", function( form )
        removeBuff( "cat_form" )
        removeBuff( "bear_form" )
        removeBuff( "travel_form" )
        removeBuff( "moonkin_form" )
        removeBuff( "travel_form" )
        removeBuff( "aquatic_form" )
        removeBuff( "stag_form" )
        applyBuff( form )

        if form == "bear_form" and pvptalent.celestial_guardian.enabled then
            applyBuff( "celestial_guardian" )
        end
    end )


    spec:RegisterHook( "runHandler", function( ability )
        local a = class.abilities[ ability ]

        if not a or a.startsCombat then
            break_stealth()
        end 
    end )

    spec:RegisterHook( "pregain", function( amt, resource, overcap, clean )
        if buff.memory_of_lucid_dreams.up then
            if amt > 0 and resource == "astral_power" then
                return amt * 2, resource, overcap, true
            end
        end
    end )

    spec:RegisterHook( "prespend", function( amt, resource, clean )
        if buff.memory_of_lucid_dreams.up then
            if amt < 0 and resource == "astral_power" then
                return amt * 2, resource, overcap, true
            end
        end
    end )


    local check_for_ap_overcap = setfenv( function( ability )
        local a = ability or this_action
        if not a then return true end

        a = action[ a ]
        if not a then return true end

        local cost = 0
        if a.spendType == "astral_power" then cost = a.cost end

        return astral_power.current - cost + ( talent.shooting_stars.enabled and 4 or 0 ) + ( talent.natures_balance.enabled and ceil( execute_time / 1.5 ) or 0 ) < astral_power.max
    end, state )

    spec:RegisterStateExpr( "ap_check", function() return check_for_ap_overcap() end )
    
    -- Simplify lookups for AP abilities consistent with SimC.
    local ap_checks = { 
        "force_of_nature", "full_moon", "half_moon", "incarnation", "lunar_strike", "moonfire", "new_moon", "solar_wrath", "starfall", "starsurge", "sunfire"
    }

    for i, lookup in ipairs( ap_checks ) do
        spec:RegisterStateExpr( lookup, function ()
            return action[ lookup ]
        end )
    end
    

    spec:RegisterStateExpr( "active_moon", function ()
        return "new_moon"
    end )

    local function IsActiveSpell( id )
        local slot = FindSpellBookSlotBySpellID( id )
        if not slot then return false end

        local _, _, spellID = GetSpellBookItemName( slot, "spell" )
        return id == spellID 
    end

    state.IsActiveSpell = IsActiveSpell

    spec:RegisterHook( "reset_precast", function ()
        if IsActiveSpell( class.abilities.new_moon.id ) then active_moon = "new_moon"
        elseif IsActiveSpell( class.abilities.half_moon.id ) then active_moon = "half_moon"
        elseif IsActiveSpell( class.abilities.full_moon.id ) then active_moon = "full_moon"
        else active_moon = nil end

        -- UGLY
        if talent.incarnation.enabled then
            rawset( cooldown, "ca_inc", cooldown.incarnation )
        else
            rawset( cooldown, "ca_inc", cooldown.celestial_alignment )
        end

        if buff.warrior_of_elune.up then
            setCooldown( "warrior_of_elune", 3600 ) 
        end
    end )


    spec:RegisterHook( "spend", function( amt, resource )
        if level < 116 and equipped.impeccable_fel_essence and resource == "astral_power" and cooldown.celestial_alignment.remains > 0 then
            setCooldown( "celestial_alignment", max( 0, cooldown.celestial_alignment.remains - ( amt / 12 ) ) )
        end 
    end )


    -- Legion Sets (for now).
    spec:RegisterGear( 'tier21', 152127, 152129, 152125, 152124, 152126, 152128 )
        spec:RegisterAura( 'solar_solstice', {
            id = 252767,
            duration = 6,
            max_stack = 1,
         } ) 

    spec:RegisterGear( 'tier20', 147136, 147138, 147134, 147133, 147135, 147137 )
    spec:RegisterGear( 'tier19', 138330, 138336, 138366, 138324, 138327, 138333 )
    spec:RegisterGear( 'class', 139726, 139728, 139723, 139730, 139725, 139729, 139727, 139724 )

    spec:RegisterGear( "impeccable_fel_essence", 137039 )    
    spec:RegisterGear( "oneths_intuition", 137092 )
        spec:RegisterAuras( {
            oneths_intuition = {
                id = 209406,
                duration = 3600,
                max_stacks = 1,
            },    
            oneths_overconfidence = {
                id = 209407,
                duration = 3600,
                max_stacks = 1,
            },
        } )

    spec:RegisterGear( "radiant_moonlight", 151800 )
    spec:RegisterGear( "the_emerald_dreamcatcher", 137062 )
        spec:RegisterAura( "the_emerald_dreamcatcher", {
            id = 224706,
            duration = 5,
            max_stack = 2,
        } )



    -- Abilities
    spec:RegisterAbilities( {
        barkskin = {
            id = 22812,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 136097,

            handler = function ()
                applyBuff( "barkskin" )
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

            noform = "bear_form",

            handler = function ()
                shift( "bear_form" )
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
            end,
        },


        celestial_alignment = {
            id = 194223,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 180 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 136060,

            notalent = "incarnation",

            handler = function ()
                applyBuff( "celestial_alignment" )
                gain( 40, "astral_power" )
                if pvptalent.moon_and_stars.enabled then applyBuff( "moon_and_stars" ) end
            end,

            copy = "ca_inc"
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
            gcd = "off",

            startsCombat = false,
            texture = 132120,

            notalent = "tiger_dash",

            handler = function ()
                if not buff.cat_form.up then
                    shift( "cat_form" )
                end
                applyBuff( "dash" )
            end,
        },


        --[[ dreamwalk = {
            id = 193753,
            cast = 10,
            cooldown = 60,
            gcd = "spell",

            spend = 4,
            spendType = "mana",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135763,

            handler = function ()
            end,
        }, ]]


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


        faerie_swarm = {
            id = 209749,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            pvptalent = "faerie_swarm",

            startsCombat = true,
            texture = 538516,

            handler = function ()
                applyDebuff( "target", "faerie_swarm" )
            end,
        },


        ferocious_bite = {
            id = 22568,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 50,
            spendType = "energy",

            startsCombat = true,
            texture = 132127,

            form = "cat_form",
            talent = "feral_affinity",

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                --[[ if target.health.pct < 25 and debuff.rip.up then
                    applyDebuff( "target", "rip", min( debuff.rip.duration * 1.3, debuff.rip.remains + debuff.rip.duration ) )
                end ]]
                spend( combo_points.current, "combo_points" )
            end,
        },


        --[[ flap = {
            id = 164862,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132925,

            handler = function ()
            end,
        }, ]]


        force_of_nature = {
            id = 205636,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = -20,
            spendType = "astral_power",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 132129,

            talent = "force_of_nature",

            ap_check = function() return check_for_ap_overcap( "force_of_nature" ) end,

            handler = function ()
                summonPet( "treants", 10 )
            end,
        },


        frenzied_regeneration = {
            id = 22842,
            cast = 0,
            charges = 1,
            cooldown = 36,
            recharge = 36,
            gcd = "spell",

            spend = 10,
            spendType = "rage",

            startsCombat = false,
            texture = 132091,

            form = "bear_form",
            talent = "guardian_affinity",

            handler = function ()
                applyBuff( "frenzied_regeneration" )
                gain( 0.08 * health.max, "health" )
            end,
        },


        full_moon = {
            id = 274283,
            known = 274281,
            cast = 3,
            charges = 3,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = -40,
            spendType = "astral_power",

            texture = 1392542,
            startsCombat = true,

            talent = "new_moon",
            bind = "half_moon",

            ap_check = function() return check_for_ap_overcap( "full_moon" ) end,

            usable = function () return active_moon == "full_moon" end,
            handler = function ()
                spendCharges( "new_moon", 1 )
                spendCharges( "half_moon", 1 )

                -- Radiant Moonlight, NYI.
                active_moon = "new_moon"
            end,
        },


        fury_of_elune = {
            id = 202770,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            -- toggle = "cooldowns",

            startsCombat = true,
            texture = 132123,

            handler = function ()
                if not buff.moonkin_form.up then unshift() end
                applyDebuff( "target", "fury_of_elune_ap" )
            end,
        },


        growl = {
            id = 6795,
            cast = 0,
            cooldown = 8,
            gcd = "off",

            startsCombat = true,
            texture = 132270,

            form = "bear_form",

            handler = function ()
                applyDebuff( "target", "growl" )
            end,
        },


        half_moon = {
            id = 274282, 
            known = 274281,
            cast = 2,
            charges = 3,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = -20,
            spendType = "astral_power",

            texture = 1392543,
            startsCombat = true,

            talent = "new_moon",
            bind = "new_moon",

            ap_check = function() return check_for_ap_overcap( "half_moon" ) end,

            usable = function () return active_moon == 'half_moon' end,
            handler = function ()
                spendCharges( "new_moon", 1 )
                spendCharges( "full_moon", 1 )

                active_moon = "full_moon"
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
            id = 102560,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 180 end,
            gcd = "spell",

            spend = -40,
            spendType = "astral_power",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 571586,

            talent = "incarnation",

            handler = function ()
                shift( "moonkin_form" )
                
                applyBuff( "incarnation" )

                if pvptalent.moon_and_stars.enabled then applyBuff( "moon_and_stars" ) end
            end,

            copy = { "incarnation_chosen_of_elune", "Incarnation" },
        },


        innervate = {
            id = 29166,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136048,

            usable = function () return group end,
            handler = function ()
                active_dot.innervate = 1
            end,
        },


        ironfur = {
            id = 192081,
            cast = 0,
            cooldown = 0.5,
            gcd = "spell",

            spend = 45,
            spendType = "rage",

            startsCombat = true,
            texture = 1378702,

            handler = function ()
                applyBuff( "ironfur" )
            end,
        },


        lunar_strike = {
            id = 194153,
            cast = function () 
                if buff.warrior_of_elune.up then return 0 end
                return haste * ( buff.lunar_empowerment.up and 0.85 or 1 ) * 2.25 
            end,
            cooldown = 0,
            gcd = "spell",

            spend = function () return ( buff.warrior_of_elune.up and 1.4 or 1 ) * -12 end,
            spendType = "astral_power",

            startsCombat = true,
            texture = 135753,            

            ap_check = function() return check_for_ap_overcap( "lunar_strike" ) end,

            handler = function ()
                if not buff.moonkin_form.up then unshift() end
                removeStack( "lunar_empowerment" )

                if buff.warrior_of_elune.up then
                    removeStack( "warrior_of_elune" )
                    if buff.warrior_of_elune.down then
                        setCooldown( "warrior_of_elune", 45 ) 
                    end
                end

                if azerite.dawning_sun.enabled then applyBuff( "dawning_sun" ) end
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

            talent = "guardian_affinity",
            form = "bear_form",

            handler = function ()
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
                active_dot.mass_entanglement = max( active_dot.mass_entanglement, active_enemies )
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

            spend = -3,
            spendType = "astral_power",

            startsCombat = true,
            texture = 136096,

            cycle = "moonfire",

            ap_check = function() return check_for_ap_overcap( "moonfire" ) end,

            handler = function ()
                if not buff.moonkin_form.up and not buff.bear_form.up then unshift() end
                applyDebuff( "target", "moonfire" )

                if talent.twin_moons.enabled and active_enemies > 1 then
                    active_dot.moonfire = min( active_enemies, active_dot.moonfire + 1 )
                end
            end,
        },


        moonkin_form = {
            id = 24858,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 136036,

            noform = "moonkin_form",
            essential = true,

            handler = function ()
                shift( "moonkin_form" )
            end,
        },


        new_moon = {
            id = 274281, 
            cast = 1,
            charges = 3,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = -10,
            spendType = "astral_power",

            texture = 1392545,
            startsCombat = true,

            talent = "new_moon",
            bind = "full_moon",

            ap_check = function() return check_for_ap_overcap( "new_moon" ) end,

            usable = function () return active_moon == "new_moon" end,
            handler = function ()
                spendCharges( "half_moon", 1 )
                spendCharges( "full_moon", 1 )

                active_moon = "half_moon"
            end,
        },


        prowl = {
            id = 5215,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = false,
            texture = 514640,

            usable = function () return time == 0 end,
            handler = function ()
                shift( "cat_form" )
                applyBuff( "prowl" )
                removeBuff( "shadowmeld" )
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
            end,
        },


        --[[ rebirth = {
            id = 20484,
            cast = 2,
            cooldown = 600,
            gcd = "spell",

            spend = 0,
            spendType = "rage",

            -- toggle = "cooldowns",

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

            handler = function ()
                if buff.moonkin_form.down then unshift() end
                applyBuff( "regrowth" )
            end,
        },


        rejuvenation = {
            id = 774,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.11,
            spendType = "mana",

            startsCombat = false,
            texture = 136081,

            talent = "restoration_affinity",

            handler = function ()
                if buff.moonkin_form.down then unshift() end
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

            startsCombat = true,
            texture = 135952,

            handler = function ()
            end,
        },


        renewal = {
            id = 108238,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            startsCombat = true,
            texture = 136059,

            talent = "renewal",

            handler = function ()
                -- unshift?
                gain( 0.3 * health.max, "health" )
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

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                spend( combo_points.current, "combo_points" )
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

            talent = "feral_affinity",
            form = "cat_form",

            handler = function ()
                gain( 1, "combo_points" )
            end,
        },


        solar_beam = {
            id = 78675,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            spend = 0.17,
            spendType = "mana",

            toggle = "interrupts",

            startsCombat = true,
            texture = 252188,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                if buff.moonkin_form.down then unshift() end
                interrupt()
            end,
        },


        solar_wrath = {
            id = 190984,
            cast = function () return haste * ( buff.solar_empowerment.up and 0.85 or 1 ) * 1.5 end,
            cooldown = 0,
            gcd = "spell",

            spend = -8,
            spendType = "astral_power",

            startsCombat = true,
            texture = 535045,

            ap_check = function() return check_for_ap_overcap( "solar_wrath" ) end,

            handler = function ()
                if not buff.moonkin_form.up then unshift() end
                removeStack( "solar_empowerment" )
                removeBuff( "dawning_sun" )
                if azerite.sunblaze.enabled then applyBuff( "sunblaze" ) end
            end,
        },


        soothe = {
            id = 2908,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = true,
            texture = 132163,

            usable = function () return buff.dispellable_enrage.up end,
            handler = function ()
                if buff.moonkin_form.down then unshift() end
                removeBuff( "dispellable_enrage" )
            end,
        },


        stag_form = {
            id = 210053,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 1394966,

            noform = "travel_form",
            handler = function ()
                shift( "stag_form" )
            end,
        },


        starfall = {
            id = 191034,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.oneths_overconfidence.up then return 0 end
                return talent.soul_of_the_forest.enabled and 40 or 50
            end,
            spendType = "astral_power",

            startsCombat = true,
            texture = 236168,

            ap_check = function() return check_for_ap_overcap( "starfall" ) end,

            handler = function ()
                addStack( "starlord", buff.starlord.remains > 0 and buff.starlord.remains or nil, 1 )
                removeBuff( "oneths_overconfidence" )
                if level < 116 and set_bonus.tier21_4pc == 1 then
                    applyBuff( "solar_solstice" )
                end
            end,
        },


        starsurge = {
            id = 78674,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.oneths_intuition.up then return 0 end
                return 40 - ( buff.the_emerald_dreamcatcher.stack * 5 )
            end,
            spendType = "astral_power",

            startsCombat = true,
            texture = 135730,

            ap_check = function() return check_for_ap_overcap( "starsurge" ) end,   

            handler = function ()
                addStack( "lunar_empowerment", nil, 1 )
                addStack( "solar_empowerment", nil, 1 )
                addStack( "starlord", buff.starlord.remains > 0 and buff.starlord.remains or nil, 1 )
                removeBuff( "oneths_intuition" )
                removeBuff( "sunblaze" )

                if pvptalent.moonkin_aura.enabled then
                    addStack( "moonkin_aura", nil, 1 )
                end

                if level < 116 and set_bonus.tier21_4pc == 1 then
                    applyBuff( "solar_solstice" )
                end

                if azerite.arcanic_pulsar.enabled then
                    addStack( "arcanic_pulsar" )
                    if buff.arcanic_pulsar.stack == 9 then
                        removeBuff( "arcanic_pulsar" )
                        applyBuff( talent.incarnation.enabled and "incarnation" or "celestial_alignment" )
                    end
                end

                if ( level < 116 and equipped.the_emerald_dreamcatcher ) then addStack( "the_emerald_dreamcatcher", 5, 1 ) end
            end,
        },


        stellar_flare = {
            id = 202347,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = -8,
            spendType = "astral_power",

            startsCombat = true,
            texture = 1052602,
            cycle = "stellar_flare",

            talent = "stellar_flare",

            ap_check = function() return check_for_ap_overcap( "stellar_flare" ) end,

            handler = function ()
                applyDebuff( "target", "stellar_flare" )
            end,
        },


        sunfire = {
            id = 93402,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -3,
            spendType = "astral_power",

            startsCombat = true,
            texture = 236216,

            cycle = "sunfire",

            ap_check = function()
                return astral_power.current - action.sunfire.cost + ( talent.shooting_stars.enabled and 4 or 0 ) + ( talent.natures_balance.enabled and ceil( execute_time / 1.5 ) or 0 ) < astral_power.max
            end,            

            readyTime = function()
                return mana[ "time_to_" .. ( 0.12 * mana.max ) ]
            end,

            handler = function ()
                spend( 0.12 * mana.max, "mana" ) -- I want to see AP in mouseovers.
                applyDebuff( "target", "sunfire" )
                active_dot.sunfire = active_enemies
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
                if buff.moonkin_form.down then unshift() end
                gain( health.max * 0.1, "health" )
            end,
        },

        -- May want to revisit this and split out swipe_cat from swipe_bear.
        swipe = {
            known = 213764,
            cast = 0,
            cooldown = function () return haste * ( buff.cat_form.up and 0 or 6 ) end,
            gcd = "spell",

            spend = function () return buff.cat_form.up and 40 or nil end,
            spendType = function () return buff.cat_form.up and "energy" or nil end,

            startsCombat = true,
            texture = 134296,

            talent = "feral_affinity",

            usable = function () return buff.cat_form.up or buff.bear_form.up end,
            handler = function ()
                if buff.cat_form.up then
                    gain( 1, "combo_points" )
                end
            end,

            copy = { 106785, 213771 }
        },


        thrash = {
            id = 106832,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -5,
            spendType = "rage",

            cycle = "thrash_bear",
            startsCombat = true,
            texture = 451161,

            talent = "guardian_affinity",
            form = "bear_form",

            handler = function ()
                applyDebuff( "target", "thrash_bear", nil, debuff.thrash.stack + 1 )
            end,
        },


        tiger_dash = {
            id = 252216,
            cast = 0,
            cooldown = 45,
            gcd = "off",

            startsCombat = false,
            texture = 1817485,

            talent = "tiger_dash",

            handler = function ()
                shift( "cat_form" )
                applyBuff( "tiger_dash" )
            end,
        },


        thorns = {
            id = 236696,
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


        travel_form = {
            id = 783,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132144,

            noform = "travel_form",
            handler = function ()
                shift( "travel_form" )
            end,
        },


        treant_form = {
            id = 114282,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 132145,

            handler = function ()
                shift( "treant_form" )
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
                applyDebuff( "target", "typhoon" )
                if target.distance < 15 then setDistance( target.distance + 5 ) end
            end,
        },


        warrior_of_elune = {
            id = 202425,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 135900,

            talent = "warrior_of_elune",

            usable = function () return buff.warrior_of_elune.down end,
            handler = function ()
                applyBuff( "warrior_of_elune", nil, 3 )
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
            id = function () return buff.moonkin_form.up and 102383 or 102401 end,
            known = 102401,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = false,
            texture = 538771,

            talent = "wild_charge",

            handler = function ()
                if buff.moonkin_form.up then setDistance( target.distance + 10 ) end
            end,

            copy = { 102401, 102383 }
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

            talent = "wild_growth",

            handler = function ()
                unshift()
                applyBuff( "wild_growth" )
            end,
        },
    } )

    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageDots = false,
        damageExpiration = 6,

        potion = "unbridled_fury",

        package = "Balance",        
    } )

    
    spec:RegisterSetting( "starlord_cancel", false, {
        name = "Cancel |T462651:0|t Starlord",
        desc = "If checked, the addon will recommend canceling your Starlord buff before starting to build stacks with Starsurge again.\n\n" ..
            "You will likely want a |cFFFFD100/cancelaura Starlord|r macro to manage this during combat.",
        icon = 462651,
        iconCoords = { 0.1, 0.9, 0.1, 0.9 },
        type = "toggle",
        width = 1.5
    } )

    -- Starlord Cancel Override
    class.specs[0].abilities.cancel_buff.funcs.usable = setfenv( function ()
        if not settings.starlord_cancel and args.buff_name == "starlord" then return false, "starlord cancel option disabled" end
        return args.buff_name ~= nil, "no buff name detected"
    end, state )    


    spec:RegisterPack( "Balance", 20190920, [[dCKO3aqiPIhrj4scKAtOIpjqsJsk6usjRccYROKAwusULuPQDHYVOenmGOJjGwMa8miW0KkLUgqOTbe03KkvACsLIZjq06Kkv8oiOO5rj09qL2NG4GceAHcQEOabtuGeUieuQnkqI8rbsuNecQSsPuZeckStbPLcbL8ueMQGYEPYFfAWQ6WKwmQ6XinzeDzIntvFgOgTu40kTAiOQxdrZMIBdPDRYVbnCk1YL8COMUORdy7aPVdHgpqGZlqTEPsMVu1(vSlqxyocsnfxObaYadsqgKbasgidsqeegacCezW2IJWwPivWIJ4uuXreUA0JkocBnydujDH5iWqGIkoIgzAJ7owAj4nBaWZOqulXlkGrZfE0s9PL4fLAPJGhynjc354DeKAkUqdaKbgKGmidaKmqgKGiimWG0rOazdy5iiw0GGJOXsskNJ3rqkyQJWcZhUA0JkZhuual502cZ3itBC3XslbVzdaEgfIAjErbmAUWJwQpTeVOulN2wyEcXofuEPMpaqA18baYadYP902cZheAOhyb3DM2wy(UF(GijPqopb0O18HlkkBABH57(5dcn0dSqoFQfyjJRFEQIf88jCEAWuJetTaljMnTTW8D)8elQTz9bpFqSlP2uMplDZ5nqisaB88njHxqnNhalZdCNqfmwRGNhuTwL3iZJd(sfe0InTTW8D)8iSeuiOc58imwqftWZtyV1MZtHh5Ml8M3dR5dcIrW5QM5dIMf8HkxIWC(GHabvJz(gkOY8BopSMpyiW8icVGAopEpQmpc3DsbQMY8lE(gl4gsnVDTWAZGzocZItSlmhbP4vat6cZfAGUWCeknx45iWqJwrErrDeYP8gH0fUlDHgGlmhHCkVriDH7iO1MsTQJGhW7zunUhLby7iuAUWZrWlfwkK7b2LUqrGlmhHCkVriDH7iuAUWZrODHBOLIJE4LrOpAdrukhbT2uQvDeDMNhW7zunUhLbyppN5jHjdfcp)wclxkY9appN5jHjddC(TewUuK7bEEoZ3C(oZNQrUKHtXy0k6nAjm5uEJqoFF)8KWKHtXy0k6nAjSCPi3d88TCeNIkocTlCdTuC0dVmc9rBiIs5sxODRlmhHCkVriDH7iO1MsTQJO58DMpvJCjdNAzGfjtoL3iKZ33pppG3ZWPwgyrYaSNV18CMVZ88aEpJQX9Oma755mpjmzOq453sy5srUh455mpjmzyGZVLWYLICpWZZz(MZ3z(unYLmCkgJwrVrlHjNYBeY577NNeMmCkgJwrVrlHLlf5EGNVLJqP5cphbyaTix9IqFu7sky2WLUqbrxyoc5uEJq6c3rO0CHNJGgm1aZcElnYBuC6iO1MsTQJOZ88aEpJQX9Oma755mpjmzOq453sy5srUh455mpjmzyGZVLWYLICpWZZz(MZ3z(unYLmCkgJwrVrlHjNYBeY577NNeMmCkgJwrVrlHLlf5EGNVLJq8EHMXtrfhbnyQbMf8wAK3O40LUqbHUWCeYP8gH0fUJqP5cphbUXcQurqLdIglXSuhXPOIJa3ybvQiOYbrJLywQJGwBk1QoIoZZd49mQg3JYaSNNZ8DMNhW7z8giK0aGtgGTJi1cSKX17iiHjd3ybvQiOYbrz4uPiNpeUZdIU0fA31fMJqoL3iKUWDe0AtPw1rqHqdjeXJr14EuwjO6E45dzEeashHsZfEocEdesgH(y2qIYjOb7sxODJlmhHCkVriDH7iO1MsTQJOZ88aEpJQX9Oma755mFZ5vCwQjAdruQ5T48baIZ33ppfcnKqepgvJ7rzLGQ7HNpK5raiNV18CMNeMmmW53syLGQ7HNpK5deKZZzEsyYqHWZVLWkbv3dpFiZhiiNNZ8nNVZ8PAKlz4umgTIEJwctoL3iKZ33ppjmz4umgTIEJwcReuDp88HmFGGC(wocLMl8CeOckScoc9rdaDjJKLOOyx6cniDH5iuAUWZryduRp49ah5nkoDeYP8gH0fUlDHgiiDH5iuAUWZruRTTrI7fX2kvCeYP8gH0fUlDHgyGUWCeknx45iOWJkxwAkKrVrrfhHCkVriDH7sxObgGlmhHCkVriDH7iO1MsTQJGhW7zLqrAemo6Hfvya2ZZzEsyYqHWZVLWYLICpWZZzEsyYWaNFlHLlf5EGNNZ8nNVZ8PAKlz4umgTIEJwctoL3iKZ33ppjmz4umgTIEJwclxkY9apFlhHsZfEoISHeboEiWrg9WIkU0fAGiWfMJqP5cphbIWYqcQSxSem80Jkoc5uEJq6c3LUqdSBDH5iKt5ncPlChbT2uQvDenNVZ8GQ1Q8gHPDfX4577NVZ88aEpJQX9Oma75BnpN5jHjdfcp)wclxkY9appN5jHjddC(TewUuK7bEEoZ3C(oZNQrUKHtXy0k6nAjm5uEJqoFF)8KWKHtXy0k6nAjSCPi3d88TCeknx45i8qkawiJAxsTPe5ff1LUqdeeDH5iuAUWZrKnG1HDeYP8gH0fUlDHgii0fMJqP5cphbawIBkOyhHCkVriDH7sxOb2DDH5iuAUWZrGOw1cRi0hfdWjoc5uEJq6c3LUqdSBCH5iKt5ncPlChbT2uQvDeDMNhW7zunUhLbyppN5BoppG3ZqfuyfCe6Jga6sgjlrrXma7577NV58nNNcHgsiIhdvqHvWrOpAaOlzKSeffZkbv3dpFiZhaiNVVF(oZlySCuHHkOWk4i0hna0LmswIIIzOkcpSMV18CMxTJ0gcf58TMV18CMV588aEpdvqHvWrOpAaOlzKSeffZaSNVVFE1osBiuKZ3AEoZtctgg48BjSsq19WZhY8DZ8CMNeMmui88BjSsq19WZhY8bgW8CMV58KWKHtXy0k6nAjSsq19WZhY8GW577NVZ8PAKlz4umgTIEJwctoL3iKZ3YrO0CHNJypQwNMl8CPl0adsxyoc5uEJq6c3rqRnLAvhrN55b8EgvJ7rza2ZZz(MZZd49mubfwbhH(ObGUKrYsuumdWE(((5BoFZ5PqOHeI4XqfuyfCe6Jga6sgjlrrXSsq19WZhY8baY577NVZ8cglhvyOckScoc9rdaDjJKLOOygQIWdR5BnpN5v7iTHqroFR5BnpN5BopjmzyGZVLWkbv3dpFiZhW8CMNeMmui88BjSCPi3d88CMV58KWKHtXy0k6nAjSCPi3d8899Z3z(unYLmCkgJwrVrlHjNYBeY5BnFlhHsZfEocQyeCUQjQMf8Hkx6sxObasxyoc5uEJq6c3rqRnLAvhrZ55b8EgvJ7rza2Z33ppfcnKqepgvJ7rzLGQ7HNpK5raiNV18CMhdnAfrS0SbtTJ0gcfPJqP5cphHhOcoc9rXaCIlDHgqGUWCeYP8gH0fUJGwBk1QoIMZZd49mQg3JYaSNVVFEkeAiHiEmQg3JYkbv3dpFiZJaqoFR55mVAhPnekshHsZfEocpSOse6JNMaL4sxObeGlmhHCkVriDH7iO1MsTQJGhW7z4uldSizLGQ7HN3IZJG55mFN5XqJwrelnBWu7iTHqr6iuAUWZrq1JkMipG37i4b8(4POIJaNAzGfPlDHgacCH5iKt5ncPlChbT2uQvDenNNhW7z4uldSiz4uPiN3IZJG577NNhW7z4uldSizLGQ7HNpeUZ3nZ3AEoZJTfJjMAbws88HWDEq1AvEJWW(yQfyjXZZz(MZNAbwswUOsmHrYvM365dC(wZJqZJTfJjMAbws88HmpfIZ5d65dGbIocLMl8Ce4ulVAmU0fAaDRlmhHCkVriDH7iO1MsTQJO58PAKlz4uldSizYP8gHCEoZ3CEEaVNHtTmWIKHtLICElopcMVVFEEaVNHtTmWIKvcQUhE(q4opiopN55b8EMwu9wA0gWG1IHtLICEloF3mFR577NVZ8PAKlz4uldSizYP8gHCEoZ3CEEaVNPfvVLgTbmyTy4uPiN3IZ3nZ33pppG3ZOACpkdWE(wZ3AEoZJTfJjMAbwsmdNA5vJzElopOATkVryyFm1cSK455mppG3ZmaNwrb1gIOuOYLmCQuKZB988aEpddnAffuBiIsHkxYWPsroVfNVBNNZ88aEpddnAffuBiIsHkxYWPsroVfNhbZZzEEaVNzaoTIcQnerPqLlz4uPiN3IZJG55mFZ57mV2LuBkmCwIICpWrCQfMv6HC(((57mppG3ZOACpkdWE(((57mVDjGYWPwyGcSmFR577Np1cSKSCrLycJKRmVf5oVacekqkXCrL5rO5vCwQjAdruQ5d657wqoFF)8DMhdnAfrS0SbtTJ0gcfPJqP5cphbo1cduGfx6cnaq0fMJqoL3iKUWDe0AtPw1rWd49mQg3JYaSNNZ88aEpJQX9OSsq19WZBX5btjzOkiyEoZRDj1McdNLOi3dCeNAHzLEiNNZ8KWKHcHNFlHvcQUhE(qMVeuDpSJqP5cphbg48BjU0fAaGqxyoc5uEJq6c3rqRnLAvhbpG3ZOACpkdWEEoZZd49mQg3JYkbv3dpVfNhmLKHQGG55mV2LuBkmCwIICpWrCQfMv6H0rO0CHNJafcp)wIlDHgq31fMJqoL3iKUWDeknx45iWaNFlXrqRnLAvhrj(sWnuEJmpN5v7iTHqropN59giSMV58PwGLKLlQetyKCL5d65BoFaZJqZJTfJj2qXPmFR5Bnpcnp2wmMyQfyjXZhc35PYAMV58EdewZ3C(aMpONhBlgtm1cSK45BnpcnFGmqC(wZB98bmpcnp2wmMyQfyjXZZz(MZJTfJjMAbws88HmFGZB98PAKlzjI7frHWdZKt5nc5899ZtctgkeE(TewUuK7bE(wZZz(MZ3zETlP2uy4Sef5EGJ4ulmR0d5899Z3zEEaVNr14EugG9899Z3zE7saLHbo)wY8TMNZ8nNNhW7zunUhLvcQUhE(qMVeuDp8899Z3zEEaVNr14EugG98TCe0GPgjMAbwsSl0aDPl0a6gxyoc5uEJq6c3rO0CHNJafcp)wIJGwBk1QoIs8LGBO8gzEoZR2rAdHICEoZ7nqynFZ5tTaljlxujMWi5kZh0Z3C(aMhHMhBlgtSHItz(wZ3AEeAESTymXulWsINpeUZdcNNZ8nNVZ8AxsTPWWzjkY9ahXPwywPhY577NVZ88aEpJQX9Oma7577NVZ82Lakdfcp)wY8TMNZ8nNNhW7zunUhLvcQUhE(qMVeuDp8899Z3zEEaVNr14EugG98TCe0GPgjMAbwsSl0aDPl0acsxyoc5uEJq6c3rO0CHNJaNIXOv0B0sCe0AtPw1ruIVeCdL3iZZzE1osBiuKZZzEVbcR5BoFQfyjz5IkXegjxz(GE(MZhW8i08yBXyInuCkZ3A(wZhc35bX55mFZ57mV2LuBkmCwIICpWrCQfMv6HC(((57mppG3ZOACpkdWE(((57mVDjGYWPymAf9gTK5B5iObtnsm1cSKyxOb6sxOiaKUWCeYP8gH0fUJGwBk1Qoc1osBiuKocLMl8CeNGyefcpx6cfbb6cZriNYBesx4ocATPuR6iu7iTHqr6iuAUWZr0qn(ikeEU0fkccWfMJqoL3iKUWDe0AtPw1rO2rAdHI0rO0CHNJWdymrui8CPlueGaxyoc5uEJq6c3rqRnLAvhbpG3ZWqJwrb1gIOuOYLmCQuKZBX5rW8CMV58QDK2qOiNVVFEEaVNzaoTIcQnerPqLlz4uPiNN78iy(wZZz(MZ3CEEaVNHOw1cRi0hfdWjma7577NNhW7zgGtROGAdruku5sgG9899ZJTfJjMAbws88HWD(aMNZ8DMNhW7zyOrROGAdruku5sgG98TMNZ8nNVZ8AxsTPWWzjkY9ahXPwywPhY577NVZ88aEpJQX9Oma75BnFF)8AxsTPWWzjkY9ahXPwywPhY55mppG3ZOACpkdWEEoZBxcOmm0OveXsZgZ3YrO0CHNJWaCAfXzTifx6cfbDRlmhHCkVriDH7iO1MsTQJq7sQnfgolrrUh4io1cZk9qoVfNhbZ33pFN55b8EgvJ7rza2Z33pFN5TlbuggA0kIyPzdhHsZfEocm0OveXsZgU0fkcarxyocLMl8CeyGZVL4iKt5ncPlCx6shHDjuikVMUWCHgOlmhHCkVriDH7iG2ocSKocLMl8CeGQ1Q8gXraQAaehr36iavR4POIJa7JPwGLe7sxOb4cZriNYBesx4ocOTJqjjDeknx45iavRv5nIJau1aioIaDe0AtPw1rODj1MctlQElnAdyWAXKt5ncPJauTINIkocSpMAbwsSlDHIaxyoc5uEJq6c3raTDekjPJqP5cphbOATkVrCeGQgaXreOJGwBk1QoIunYLmCQLbwKm5uEJq6iavR4POIJa7JPwGLe7sxODRlmhHCkVriDH7iG2ocLK0rO0CHNJauTwL3iocqvdG4ic0rqRnLAvhH2LuBkmCwIICpWrCQfMv6HC(qMpG55mV2LuBkmTO6T0OnGbRftoL3iKocq1kEkQ4iW(yQfyjXU0fki6cZriNYBesx4ocOTJadW7iuAUWZraQwRYBehbOQbqCeb6iO1MsTQJOZ8PAKlzjI7frHWdZKt5ncPJauTINIkocSpMAbwsSlDHccDH5iuAUWZrGcHhY9IEyH6iKt5ncPlCx6cT76cZriNYBesx4oItrfhH2fUHwko6HxgH(OnerPCeknx45i0UWn0sXrp8Yi0hTHikLlDH2nUWCeYP8gH0fUJqP5cphHnmx45iid(u0LgTlXgMoIaDPl0G0fMJqP5cphbgA0kIyPzdhHCkVriDH7sxObcsxyocLMl8Ce4ulmqbwCeYP8gH0fUlDPlDeGkfEHNl0aazGbji7UbeilaeGahbIAD7bg7iq4qTHvkKZhW8knx4nVzXjMnTDe2f0VgXryH5dxn6rL5dkkGLCABH5BKPnU7yPLG3SbapJcrTeVOagnx4rl1NwIxuQLtBlmpHyNckVuZhaiTA(aazGb50EABH5dcn0dSG7otBlmF3pFqKKuiNNaA0A(WffLnTTW8D)8bHg6bwiNp1cSKX1ppvXcE(eopnyQrIPwGLeZM2wy(UFEIf12S(GNpi2LuBkZNLU58giejGnE(MKWlOMZdGL5bUtOcgRvWZdQwRYBK5XbFPccAXM2wy(UFEewckeuHCEeglOIj45jS3AZ5PWJCZfEZ7H18bbXi4CvZ8brZc(qLlryoFWqGGQXmFdfuz(nNhwZhmeyEeHxqnNhVhvMhH7oPavtz(fpFJfCdPM3UwyTzWSP902cZJWgeiuGuiNNx8WsMNcr51CEEb8Ey28brkvSt88h86(gAH6bmZR0CHhEE4zcMnTTW8knx4Hz2LqHO8AY1BumYPTfMxP5cpmZUekeLxtR5APhcjN2wyELMl8Wm7sOquEnTMRLkayu5snx4nTN2wy(GyxsTPmpOATkVrWtBlmVsZfEyMDjuikVMwZ1sq1AvEJy1POcxTRigBfOQbq4QDj1McdNLOi3dCeNAHzLEiN2wyELMl8Wm7sOquEnTMRLGQ1Q8gXQtrfUAxr12kqvdGWv7sQnfMwu9wA0gWG1Iv6HCApTTW8ePwE1yMh05jsTWafyz(ulWsopfiHE)0wP5cpmZUekeLxtUGQ1Q8gXQtrfUyFm1cSKyRavnac3UDAR0CHhMzxcfIYRP1CTeuTwL3iwDkQWf7JPwGLeBf0MRssAfOQbq4gOvRNR2LuBkmTO6T0OnGbRftoL3iKtBLMl8Wm7sOquEnTMRLGQ1Q8gXQtrfUyFm1cSKyRG2CvssRavnac3aTA9Ct1ixYWPwgyrYKt5nc50wP5cpmZUekeLxtR5AjOATkVrS6uuHl2htTalj2kOnxLK0kqvdGWnqRwpxTlP2uy4Sef5EGJ4ulmR0dzibWr7sQnfMwu9wA0gWG1IjNYBeYPTsZfEyMDjuikVMwZ1sq1AvEJy1POcxSpMAbwsSvqBUyaERavnac3aTA9C7KQrUKLiUxefcpmtoL3iKtBLMl8Wm7sOquEnTMRLOq4HCVOhwOt7PTfMN4uBCdyoFPl588aEVqopo1eppV4HLmpfIYR588c49WZRh582L092Wm3d88lEEs4jSPTfMxP5cpmZUekeLxtR5Aj(uBCdygXPM4PTsZfEyMDjuikVMwZ1saSe3uqT6uuHR2fUHwko6HxgH(OnerPM2knx4Hz2LqHO8AAnxlTH5cpRid(u0LgTlXgMCdCAR0CHhMzxcfIYRP1CTednAfrS0SX0wP5cpmZUekeLxtR5Ajo1cduGLP902cZJWgeiuGuiNxavQGNpxuz(SHmVstyn)INxbvxJYBe20wP5cpmxm0OvKxu0PTfMpieuGN2knx4HTMRL8sHLc5EGTA9C5b8EgvJ7rza2tBLMl8WwZ1saSe3uqT6uuHR2fUHwko6HxgH(OnerPSA9C7Wd49mQg3JYaS5qctgkeE(TewUuK7bMdjmzyGZVLWYLICpWCA2jvJCjdNIXOv0B0syYP8gHSVNeMmCkgJwrVrlHLlf5EGBnTvAUWdBnxlbdOf5Qxe6JAxsbZgwTEUn7KQrUKHtTmWIKjNYBeY(EEaVNHtTmWIKby3IthEaVNr14EugGnhsyYqHWZVLWYLICpWCiHjddC(TewUuK7bMtZoPAKlz4umgTIEJwctoL3iK99KWKHtXy0k6nAjSCPi3dCRPTsZfEyR5AjawIBkOwjEVqZ4POcxAWudml4T0iVrXPvRNBhEaVNr14EugGnhsyYqHWZVLWYLICpWCiHjddC(TewUuK7bMtZoPAKlz4umgTIEJwctoL3iK99KWKHtXy0k6nAjSCPi3dCRPTsZfEyR5AjawIBkOwDkQWf3ybvQiOYbrJLywQvRNBhEaVNr14EugGnNo8aEpJ3aHKgaCYaSTk1cSKX1ZLeMmCJfuPIGkheLHtLImeUG40wP5cpS1CTK3aHKrOpMnKOCcAWwTEUui0qcr8yunUhLvcQUhoeeaYPTsZfEyR5AjQGcRGJqF0aqxYizjkk2Q1ZTdpG3ZOACpkdWMttfNLAI2qeLYIbaI99ui0qcr8yunUhLvcQUhoeeaYwCiHjddC(TewjO6E4qceKCiHjdfcp)wcReuDpCibcson7KQrUKHtXy0k6nAjm5uEJq23tctgofJrRO3OLWkbv3dhsGGS10wP5cpS1CT0gOwFW7boYBuCoTvAUWdBnxlR122iX9IyBLktBLMl8WwZ1sk8OYLLMcz0BuuzAR0CHh2AUwMnKiWXdboYOhwuXQ1ZLhW7zLqrAemo6Hfvya2CiHjdfcp)wclxkY9aZHeMmmW53sy5srUhyon7KQrUKHtXy0k6nAjm5uEJq23tctgofJrRO3OLWYLICpWTM2knx4HTMRLicldjOYEXsWWtpQmTvAUWdBnxl9qkawiJAxsTPe5ff1Q1ZTzhq1AvEJW0UIyCFFhEaVNr14EugGDloKWKHcHNFlHLlf5EG5qctgg48BjSCPi3dmNMDs1ixYWPymAf9gTeMCkVri77jHjdNIXOv0B0sy5srUh4wtBLMl8WwZ1YSbSo80wP5cpS1CTealXnfu80wP5cpS1CTerTQfwrOpkgGtM2wyELMl8WwZ1Y9oPavtXQ1Zv7sQnfMzbvmbhX2BTjtoL3iKCAsHqdjeXJThvRtZfESsq19WwmG(EkeAiHiEmQyeCUQjQMf8HkxYkbv3dBXadO10wP5cpS1CTCpQwNMl8SA9C7Wd49mQg3JYaS50KhW7zOckScoc9rdaDjJKLOOygGDFFZMui0qcr8yOckScoc9rdaDjJKLOOywjO6E4qcaK99DemwoQWqfuyfCe6Jga6sgjlrrXmufHhwT4O2rAdHISvlon5b8EgQGcRGJqF0aqxYizjkkMby33R2rAdHISfhsyYWaNFlHvcQUhoKUHdjmzOq453syLGQ7HdjWa40KeMmCkgJwrVrlHvcQUhoeqyFFNunYLmCkgJwrVrlHjNYBeYwtBLMl8WwZ1sQyeCUQjQMf8HkxA1652HhW7zunUhLbyZPjpG3ZqfuyfCe6Jga6sgjlrrXma7((MnPqOHeI4XqfuyfCe6Jga6sgjlrrXSsq19WHeai777iySCuHHkOWk4i0hna0LmswIIIzOkcpSAXrTJ0gcfzRwCAsctgg48BjSsq19WHeahsyYqHWZVLWYLICpWCAsctgofJrRO3OLWYLICpW99Ds1ixYWPymAf9gTeMCkVriB1AAR0CHh2AUw6bQGJqFumaNy1652KhW7zunUhLby33tHqdjeXJr14EuwjO6E4qqaiBXbdnAfrS0SbtTJ0gcf50wP5cpS1CT0dlQeH(4PjqjwTEUn5b8EgvJ7rza299ui0qcr8yunUhLvcQUhoeeaYwCu7iTHqroTN2wyEcB5iLcpTvAUWdBnxlP6rftKhW7T6uuHlo1YalsRwpxEaVNHtTmWIKvcQUh2IiGthm0OveXsZgm1osBiuKtBLMl8WwZ1sCQLxngRwp3M8aEpdNAzGfjdNkfPfrqFppG3ZWPwgyrYkbv3dhc3UPfhSTymXulWsIdHlOATkVryyFm1cSKyontTaljlxujMWi5kwhylecBlgtm1cSK4qOqCg0bWaXPTsZfEyR5Ajo1cduGfRwp3MPAKlz4uldSizYP8gHKttEaVNHtTmWIKHtLI0IiOVNhW7z4uldSizLGQ7HdHliYHhW7zAr1BPrBadwlgovksl2nT677KQrUKHtTmWIKjNYBeson5b8EMwu9wA0gWG1IHtLI0IDtFppG3ZOACpkdWUvloyBXyIPwGLeZWPwE1ySiOATkVryyFm1cSKyo8aEpZaCAffuBiIsHkxYWPsrAnpG3ZWqJwrb1gIOuOYLmCQuKwSB5Wd49mm0OvuqTHikfQCjdNkfPfrahEaVNzaoTIcQnerPqLlz4uPiTic40SJ2LuBkmCwIICpWrCQfMv6HSVVdpG3ZOACpkdWUVVJDjGYWPwyGcS0QVp1cSKSCrLycJKRyrUciqOaPeZfvqifNLAI2qeLkO7wq233bdnAfrS0SbtTJ0gcf50wP5cpS1CTedC(TeRwpxEaVNr14EugGnhEaVNr14EuwjO6EylcMsYqvqahTlP2uy4Sef5EGJ4ulmR0djhsyYqHWZVLWkbv3dhsjO6E4PTsZfEyR5AjkeE(TeRwpxEaVNr14EugGnhEaVNr14EuwjO6EylcMsYqvqahTlP2uy4Sef5EGJ4ulmR0d50EABH5dkGHHN2knx4HTMRLyGZVLyfnyQrIPwGLeZnqRwp3s8LGBO8gHJAhPneksoEdewntTaljlxujMWi5kbDZaqiSTymXgkoLwTqiSTymXulWsIdHlvwttVbcRMbe0yBXyIPwGLe3cHcKbITSoaecBlgtm1cSKyonX2IXetTaljoKaTovJCjlrCVikeEyMCkVri77jHjdfcp)wclxkY9a3ItZoAxsTPWWzjkY9ahXPwywPhY((o8aEpJQX9Oma7((o2LakddC(TKwCAYd49mQg3JYkbv3dhsjO6E4((o8aEpJQX9Oma7wtBLMl8WwZ1sui88BjwrdMAKyQfyjXCd0Q1ZTeFj4gkVr4O2rAdHIKJ3aHvZulWsYYfvIjmsUsq3maecBlgtSHItPvlecBlgtm1cSK4q4cc50SJ2LuBkmCwIICpWrCQfMv6HSVVdpG3ZOACpkdWUVVJDjGYqHWZVL0IttEaVNr14EuwjO6E4qkbv3d333HhW7zunUhLby3AAR0CHh2AUwItXy0k6nAjwrdMAKyQfyjXCd0Q1ZTeFj4gkVr4O2rAdHIKJ3aHvZulWsYYfvIjmsUsq3maecBlgtSHItPvRq4cICA2r7sQnfgolrrUh4io1cZk9q233HhW7zunUhLby333XUeqz4umgTIEJwsRP902cZhuwoP0ew4PTsZfEyR5A5jigrHWZQ1ZvTJ0gcf50wP5cpS1CTSHA8rui8SA9Cv7iTHqroTvAUWdBnxl9agtefcpRwpx1osBiuKtBLMl8WwZ1sdWPveN1IuSA9C5b8EggA0kkO2qeLcvUKHtLI0IiGtt1osBiuK998aEpZaCAffuBiIsHkxYWPsrYfbT40SjpG3ZquRAHve6JIb4egGDFppG3ZmaNwrb1gIOuOYLma7(ESTymXulWsIdHBaC6Wd49mm0OvuqTHikfQCjdWUfNMD0UKAtHHZsuK7boItTWSspK99D4b8EgvJ7rza2T671UKAtHHZsuK7boItTWSspKC4b8EgvJ7rza2CSlbuggA0kIyPzJwtBLMl8WwZ1sm0OveXsZgwTEUAxsTPWWzjkY9ahXPwywPhslIG((o8aEpJQX9Oma7((o2LakddnAfrS0SX0EABH5dkPgt2OaM3dR5rHGkOYLtBLMl8WwZ1smW53sCeyBH6cnqqgGlDPZba]] )


end