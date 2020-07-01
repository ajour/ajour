-- MonkWindwalker.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'MONK' then
    local spec = Hekili:NewSpecialization( 269 )

    spec:RegisterResource( Enum.PowerType.Energy, {
        crackling_jade_lightning = {
            aura = 'crackling_jade_lightning',
            debuff = true,

            last = function ()
                local app = state.buff.crackling_jade_lightning.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            stop = function( x )
                return x < class.abilities.crackling_jade_lightning.spendPerSec
            end,

            interval = function () return state.haste end,
            value = function () return class.abilities.crackling_jade_lightning.spendPerSec end,
        },
    } )

    spec:RegisterResource( Enum.PowerType.Chi )

    spec:RegisterResource( Enum.PowerType.Mana )


    -- Talents
    spec:RegisterTalents( {
        eye_of_the_tiger = 23106, -- 196607
        chi_wave = 19820, -- 115098
        chi_burst = 20185, -- 123986

        celerity = 19304, -- 115173
        chi_torpedo = 19818, -- 115008
        tigers_lust = 19302, -- 116841

        ascension = 22098, -- 115396
        fist_of_the_white_tiger = 19771, -- 261947
        energizing_elixir = 22096, -- 115288

        tiger_tail_sweep = 19993, -- 264348
        good_karma = 23364, -- 280195
        ring_of_peace = 19995, -- 116844

        inner_strength = 23258, -- 261767
        diffuse_magic = 20173, -- 122783
        dampen_harm = 20175, -- 122278

        hit_combo = 22093, -- 196740
        rushing_jade_wind = 23122, -- 261715
        invoke_xuen = 22102, -- 123904

        spiritual_focus = 22107, -- 280197
        whirling_dragon_punch = 22105, -- 152175
        serenity = 21191, -- 152173
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3572, -- 214027
        relentless = 3573, -- 196029
        gladiators_medallion = 3574, -- 208683

        disabling_reach = 3050, -- 201769
        grapple_weapon = 3052, -- 233759
        tigereye_brew = 675, -- 247483
        turbo_fists = 3745, -- 287681
        pressure_points = 3744, -- 287599
        reverse_harm = 852, -- 287771
        wind_waker = 3737, -- 287506
        alpha_tiger = 3734, -- 287503
        ride_the_wind = 77, -- 201372
        fortifying_brew = 73, -- 201318
    } )

    -- Auras
    spec:RegisterAuras( {
        bok_proc = {
            id = 116768,
            duration = 15,
        },
        chi_torpedo = {
            id = 119085,
            duration = 10,
            max_stack = 2,
        },
        dampen_harm = {
            id = 122278,
            duration = 10
        },
        diffuse_magic = {
            id = 122783,
            duration = 6
        },
        disable = {
            id = 116095,
            duration = 15,
        },
        disable_root = {
            id = 116706,
            duration = 8,
        },
        exit_strategy = {
            id = 289324,
            duration = 2,
            max_stack = 1
        },
        eye_of_the_tiger = {
            id = 196608,
            duration = 8
        },        
        fists_of_fury = {
            id = 113656,
            duration = function () return 4 * haste end,
        },        
        flying_serpent_kick = {
            name = "Flying Serpent Kick",
            duration = 2,
            generate = function ()
                local cast = rawget( class.abilities.flying_serpent_kick, "lastCast" ) or 0
                local up = cast + 2 > query_time

                local fsk = buff.flying_serpent_kick
                fsk.name = "Flying Serpent Kick"

                if up then
                    fsk.count = 1
                    fsk.expires = cast + 2
                    fsk.applied = cast
                    fsk.caster = "player"
                    return
                end
                fsk.count = 0
                fsk.expires = 0
                fsk.applied = 0
                fsk.caster = "nobody"
            end,
        },        
        hit_combo = {
            id = 196741,
            duration = 10,
            max_stack = 6,
        },
        leg_sweep = {
            id = 119381,
            duration = 3,
        },
        mark_of_the_crane = {
            id = 228287,
            duration = 15,
        },
        mystic_touch = {
            id = 113746,
            duration = 60,
        },
        paralysis = {
            id = 115078,
            duration = 15,
        },
        power_strikes = {
            id = 129914,
            duration = 3600,
        },
        pressure_point = {
            id = 247255,
            duration = 5,
        },
        provoke = {
            id = 115546,
            duration = 8,
        },
        ring_of_peace = {
            id = 116844,
            duration = 5
        },
        rising_sun_kick = {
            id = 107428,
            duration = 10,
        },
        rushing_jade_wind = {
            id = 116847,
            duration = function () return 9 * haste end,
            max_stack = 1,
            dot = "buff",
        },
        serenity = {
            id = 152173,
            duration = 12,
        },
        spinning_crane_kick = {
            id = 101546,
            duration = function () return 1.5 * haste end,
        },
        storm_earth_and_fire = {
            id = 137639,
            duration = 15,
        },
        the_emperors_capacitor = {
            id = 235054,
            duration = 3600,
            max_stack = 20,
        },
        tigers_lust = {
            id = 116841,
            duration = 6,
        },
        touch_of_death = {
            id = 115080,
            duration = 8
        },
        touch_of_karma = {
            id = 125174,
            duration = 10,
        },
        touch_of_karma_debuff = {
            id = 122470,
            duration = 10,
        },
        transcendence = {
            id = 101643,
            duration = 900,
        },
        whirling_dragon_punch = {
            id = 152175,
            duration = 1,
        },
        windwalking = {
            id = 157411,
            duration = 3600,
            max_stack = 1,
        },

        -- PvP Talents
        alpha_tiger = {
            id = 287504,
            duration = 8,
            max_stack = 1,
        },

        fortifying_brew = {
            id = 201318,
            duration = 15,
            max_stack = 1,
        },

        grapple_weapon = {
            id = 233759,
            duration = 6,
            max_stack = 1,
        },

        heavyhanded_strikes = {
            id = 201787,
            duration = 2,
            max_stack = 1,
        },

        ride_the_wind = {
            id = 201447,
            duration = 3600,
            max_stack = 1,
        },

        tigereye_brew_stack = {
            id = 248646,
            duration = 120,
            max_stack = 20,
        },

        tigereye_brew = {
            id = 247483,
            duration = 20,
            max_stack = 1
        },

        wind_waker = {
            id = 290500,
            duration = 4,
            max_stack = 1,
        },


        -- Azerite Powers
        dance_of_chiji = {
            id = 286587,
            duration = 15,
            max_stack = 1
        },

        fury_of_xuen = {
            id = 287062,
            duration = 20,
            max_stack = 67,
        },

        fury_of_xuen_haste = {
            id = 287063,
            duration = 8,
            max_stack = 1,
        },

        recently_challenged = {
            id = 290512,
            duration = 30,
            max_stack = 1
        },

        sunrise_technique = {
            id = 273298,
            duration = 15,
            max_stack = 1
        },
    } )


    spec:RegisterGear( 'tier19', 138325, 138328, 138331, 138334, 138337, 138367 )
    spec:RegisterGear( 'tier20', 147154, 147156, 147152, 147151, 147153, 147155 )
    spec:RegisterGear( 'tier21', 152145, 152147, 152143, 152142, 152144, 152146 )
    spec:RegisterGear( 'class', 139731, 139732, 139733, 139734, 139735, 139736, 139737, 139738 )

    spec:RegisterGear( 'cenedril_reflector_of_hatred', 137019 )
    spec:RegisterGear( 'cinidaria_the_symbiote', 133976 )
    spec:RegisterGear( 'drinking_horn_cover', 137097 )
    spec:RegisterGear( 'firestone_walkers', 137027 )
    spec:RegisterGear( 'fundamental_observation', 137063 )
    spec:RegisterGear( 'gai_plins_soothing_sash', 137079 )
    spec:RegisterGear( 'hidden_masters_forbidden_touch', 137057 )
    spec:RegisterGear( 'jewel_of_the_lost_abbey', 137044 )
    spec:RegisterGear( 'katsuos_eclipse', 137029 )
    spec:RegisterGear( 'march_of_the_legion', 137220 )
    spec:RegisterGear( 'prydaz_xavarics_magnum_opus', 132444 )
    spec:RegisterGear( 'salsalabims_lost_tunic', 137016 )
    spec:RegisterGear( 'sephuzs_secret', 132452 )
    spec:RegisterGear( 'the_emperors_capacitor', 144239 )

    spec:RegisterGear( 'soul_of_the_grandmaster', 151643 )
    spec:RegisterGear( 'stormstouts_last_gasp', 151788 )
    spec:RegisterGear( 'the_wind_blows', 151811 )


    spec:RegisterStateTable( "combos", {
        blackout_kick = true,
        chi_burst = true,
        chi_wave = true,
        crackling_jade_lightning = true,
        fist_of_the_white_tiger = true,
        fists_of_fury = true,
        flying_serpent_kick = true,
        rising_sun_kick = true,
        spinning_crane_kick = true,
        tiger_palm = true,
        touch_of_death = true,
        whirling_dragon_punch = true
    } )

    local prev_combo, actual_combo, virtual_combo

    spec:RegisterStateExpr( "last_combo", function () return virtual_combo or actual_combo end )

    spec:RegisterStateExpr( "combo_break", function ()
        return this_action == virtual_combo and combos[ virtual_combo ]
    end )

    spec:RegisterStateExpr( "combo_strike", function ()
        return not combos[ this_action ] or this_action ~= virtual_combo 
    end )


    local tp_chi_pending = false

    -- If a Tiger Palm missed, pretend we never cast it.
    -- Use RegisterEvent since we're looking outside the state table.
    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function( event )
        local _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID then
            local ability = class.abilities[ spellID ] and class.abilities[ spellID ].key
            if not ability then return end

            if ability == "tiger_palm" and subtype == "SPELL_MISSED" and not state.talent.hit_combo.enabled then
                if ns.castsAll[1] == "tiger_palm" then ns.castsAll[1] = "none" end
                if ns.castsAll[2] == "tiger_palm" then ns.castsAll[2] = "none" end
                if ns.castsOn[1] == "tiger_palm" then ns.castsOn[1] = "none" end
                actual_combo = "none"

                Hekili:ForceUpdate( "WW_MISSED" )

            elseif subtype == "SPELL_CAST_SUCCESS" and state.combos[ ability ] then
                prev_combo = actual_combo
                actual_combo = ability

                --[[ if ability == "tiger_palm" then
                    tp_chi_pending = true
                end ]]

            elseif subtype == "SPELL_DAMAGE" and spellID == 148187 then
                -- track the last tick.
                state.buff.rushing_jade_wind.last_tick = GetTime()

            end
        end
    end )

    --[[ spec:RegisterEvent( "UNIT_POWER_UPDATE", function( event, unit, power )
        if unit == "player" and power == "CHI" then
            tp_chi_pending = false
        end
    end ) ]]


    spec:RegisterHook( "runHandler", function( key, noStart )
        if combos[ key ] then
            if last_combo == key then removeBuff( "hit_combo" )
            else
                if talent.hit_combo.enabled then addStack( "hit_combo", 10, 1 ) end
                if azerite.fury_of_xuen.enabled then addStack( "fury_of_xuen", nil, 1 ) end                
            end
            virtual_combo = key
        end
    end )


    local chiSpent = 0

    spec:RegisterHook( "spend", function( amt, resource )
        if talent.spiritual_focus.enabled then
            chiSpent = chiSpent + amt           
            cooldown.storm_earth_and_fire.expires = max( 0, cooldown.storm_earth_and_fire.expires - floor( chiSpent / 2 ) )
            chiSpent = chiSpent % 2
        end

        if level < 116 then
            if equipped.the_emperors_capacitor and resource == 'chi' then
                addStack( "the_emperors_capacitor", 30, 1 )
            end
        end
    end )

    local reverse_harm_target

    spec:RegisterHook( "reset_precast", function ()
        chiSpent = 0

        if actual_combo == "tiger_palm" and chi.current < 2 and now - action.tiger_palm.lastCast > 0.2 then
            actual_combo = "none"
        end

        --[[ if tp_chi_pending then
            if Hekili.ActiveDebug then Hekili:Debug( "Generating 2 additional Chi as Tiger Palm was cast but Chi did not appear to be gained yet." ) end
            gain( 2, "chi" )
        end ]]

        if buff.rushing_jade_wind.up then setCooldown( "rushing_jade_wind", 0 ) end

        spinning_crane_kick.count = nil

        virtual_combo = actual_combo or "no_action"
        reverse_harm_target = nil
    end )


    spec:RegisterHook( "IsUsable", function( spell )
        -- Allow repeats to happen if your chi has decayed to 0.
        if talent.hit_combo.enabled and buff.hit_combo.up and ( spell ~= "tiger_palm" or chi.current > 0 ) and last_combo == spell then
            return false, "would break hit_combo"
        end
    end )


    spec:RegisterStateTable( "spinning_crane_kick", setmetatable( { onReset = function( self ) self.count = nil end },
        { __index = function( t, k )
                if k == 'count' then
                    t[ k ] = max( GetSpellCount( action.spinning_crane_kick.id ), active_dot.mark_of_the_crane )
                    return t[ k ]
                end
        end } ) )

    spec:RegisterStateExpr( "alpha_tiger_ready", function ()
        if not pvptalent.alpha_tiger.enabled then
            return false
        elseif debuff.recently_challenged.down then
            return true
        elseif cycle then return
            active_dot.recently_challenged < active_enemies
        end
        return false
    end )

    spec:RegisterStateExpr( "alpha_tiger_ready_in", function ()
        if not pvptalent.alpha_tiger.enabled then return 3600 end
        if active_dot.recently_challenged < active_enemies then return 0 end
        return debuff.recently_challenged.remains
    end )


    -- Abilities
    spec:RegisterAbilities( {
        blackout_kick = {
            id = 100784,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                if buff.serenity.up or buff.bok_proc.up then return 0 end
                return 1
            end,
            spendType = "chi",

            startsCombat = true,
            texture = 574575,

            cycle = 'mark_of_the_crane',

            handler = function ()
                if buff.bok_proc.up and buff.serenity.down then
                    removeBuff( "bok_proc" )
                    if set_bonus.tier21_4pc > 0 then gain( 1, "chi" ) end
                end

                cooldown.rising_sun_kick.expires = max( 0, cooldown.rising_sun_kick.expires - 1 )
                cooldown.fists_of_fury.expires = max( 0, cooldown.fists_of_fury.expires - 1 )

                if talent.eye_of_the_tiger.enabled then applyDebuff( "target", "eye_of_the_tiger" ) end
                applyDebuff( "target", "mark_of_the_crane", 15 )
            end,
        },


        chi_burst = {
            id = 123986,
            cast = function () return 1 * haste end,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 135734,

            talent = "chi_burst",

            handler = function ()
                gain( min( 2, active_enemies ), "chi" )
            end,
        },


        chi_torpedo = {
            id = 115008,
            cast = 0,
            charges = 2,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",

            startsCombat = false,
            texture = 607849,

            talent = "chi_torpedo",            

            handler = function ()
                applyBuff( "chi_torpedo" )
            end,
        },


        chi_wave = {
            id = 115098,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 606541,

            talent = "chi_wave",

            handler = function ()
            end,
        },


        crackling_jade_lightning = {
            id = 117952,
            cast = 4,
            channeled = true,
            breakable = true,
            cooldown = 0,
            gcd = "spell",

            spend = 20,
            spendPerSec = 20,
            spendType = "energy",

            startsCombat = true,
            texture = 606542,

            start = function ()
                applyDebuff( "target", "crackling_jade_lightning" )
                removeBuff( "the_emperors_capacitor" )   
            end,
        },


        dampen_harm = {
            id = 122278,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 620827,

            talent = "dampen_harm",
            handler = function ()
                applyBuff( "dampen_harm" )
            end,
        },


        detox = {
            id = 218164,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "spell",

            spend = 20,
            spendType = "energy",

            startsCombat = false,
            texture = 460692,

            handler = function ()
            end,
        },


        diffuse_magic = {
            id = 122783,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 775460,

            handler = function ()
            end,
        },


        disable = {
            id = 116095,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "energy",

            startsCombat = true,
            texture = 132316,

            handler = function ()
                if not debuff.disable.up then applyDebuff( "target", "disable" )
                else applyDebuff( "target", "disable_root" ) end
            end,
        },


        energizing_elixir = {
            id = 115288,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            -- toggle = "cooldowns",

            startsCombat = true,
            texture = 608938,

            talent = "energizing_elixir",

            handler = function ()
                gain( energy.max, "energy" )
                gain( 2, "chi" )
            end,
        },


        fist_of_the_white_tiger = {
            id = 261947,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 40,
            spendType = "energy",

            startsCombat = true,
            texture = 2065583,

            talent = "fist_of_the_white_tiger",

            handler = function ()
                gain( 3, "chi" )
            end,
        },


        fists_of_fury = {
            id = 113656,
            cast = 4,
            channeled = true,
            cooldown = function ()
                local x = 24 * haste
                if buff.serenity.up then x = max( 0, x - ( buff.serenity.remains / 2 ) ) end
                return x
            end,
            gcd = "spell",

            spend = function ()
                if buff.serenity.up then return 0 end
                if level < 116 and equipped.katsuos_eclipse then return 2 end
                return 3
            end,
            spendType = "chi",

            startsCombat = true,
            texture = 627606,

            cycle = "mark_of_the_crane",
            aura = "mark_of_the_crane",

            start = function ()
                if level < 116 and set_bonus.tier20_4pc == 1 then applyBuff( "pressure_point", 5 + action.fists_of_fury.cast ) end
                if buff.fury_of_xuen.stack >= 50 then
                    applyBuff( "fury_of_xuen_haste" )
                    summonPet( "xuen", 8 )
                    removeBuff( "fury_of_xuen" )
                end
                if pvptalent.turbo_fists.enabled then
                    applyDebuff( "target", "heavyhanded_strikes", action.fists_of_fury.cast_time + 2 )
                end
            end,
        },


        fortifying_brew = {
            id = 201318,
            cast = 0,
            cooldown = 90,
            gcd = "off",

            toggle = "defensives",
            pvptalent = "fortifying_brew",

            startsCombat = false,
            texture = 1616072,

            handler = function ()
                applyBuff( "fortifying_brew" )
            end,
        },


        flying_serpent_kick = {
            id = 101545,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 606545,

            handler = function ()
                if buff.flying_serpent_kick.up then
                    removeBuff( "flying_serpent_kick" )
                else
                    applyBuff( "flying_serpent_kick" )
                    setCooldown( "global_cooldown", 2 )
                end
            end,
        },


        grapple_weapon = {
            id = 233759,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = "grapple_weapon",

            startsCombat = true,
            texture = 132343,

            handler = function ()
                applyDebuff( "target", "grapple_weapon" )
            end,
        },


        invoke_xuen = {
            id = 123904,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 620832,

            talent = "invoke_xuen",

            handler = function ()
                summonPet( "xuen", 45 )
            end,

            copy = "invoke_xuen_the_white_tiger"
        },


        leg_sweep = {
            id = 119381,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 642414,

            handler = function ()
                applyDebuff( "target", "leg_sweep" )
                active_dot.leg_sweep = active_enemies
            end,
        },


        paralysis = {
            id = 115078,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 0,
            spendType = "energy",

            startsCombat = false,
            texture = 629534,

            handler = function ()
                applyDebuff( "target", "paralysis", 60 )
            end,
        },


        provoke = {
            id = 115546,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            startsCombat = true,
            texture = 620830,

            handler = function ()
                applyDebuff( "target", "provoke", 8 )
            end,
        },


        resuscitate = {
            id = 115178,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 132132,

            handler = function ()
            end,
        },


        reverse_harm = {
            id = 287771,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            spend = 40,
            spendType = "energy",

            pvptalent = function ()
                if essence.conflict_and_strife.major then return end
                return "reverse_harm"
            end,

            startsCombat = true,
            texture = 627486,

            indicator = function ()
                local caption = class.abilities.reverse_harm.caption
                if caption and caption ~= UnitName( "player" ) then return "cycle" end
            end,

            caption = function ()
                if not group or not settings.optimize_reverse_harm then return end
                if reverse_harm_target then return reverse_harm_target end

                local targetName, dmg = UnitName( "player "), -1

                if raid then
                    for i = 1, 5 do                        
                        local unit = "raid" .. i

                        if UnitExists( unit ) and UnitIsFriend( "player", unit ) then
                            local h, m = UnitHealth( unit ), UnitHealthMax( unit )
                            local deficit = min( m - h, m * 0.08 )

                            if deficit > dmg then
                                targetName = i < 5 and UnitName( "target" ) or nil
                                dmg = deficit
                            end
                        end
                    end

                elseif group then
                    for i = 1, 5 do                        
                        local unit = i < 5 and ( "party" .. i ) or "player"

                        if UnitExists( unit ) and UnitIsFriend( "player", unit ) then
                            local h, m = UnitHealth( unit ), UnitHealthMax( unit )
                            local deficit = min( m - h, m * 0.08 )

                            if deficit > dmg then
                                targetName = not UnitIsUnit( "player", unit ) and UnitName( unit ) or nil
                                dmg = deficit
                            end
                        end
                    end

                end

                -- Consider using LibGetFrame to highlight a raid frame.

                reverse_harm_target = targetName
                return reverse_harm_target
            end,

            usable = function ()
                if not group and health.deficit / health.max < 0.02 then return false, "solo and health deficit is too low" end
                return true
            end,

            handler = function ()
                health.actual = min( health.max, health.current + 0.08 * health.max )
                gain( 2, "chi" )
            end,
        },


        ring_of_peace = {
            id = 116844,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 839107,

            talent = "ring_of_peace",

            handler = function ()
            end,
        },


        rising_sun_kick = {
            id = 107428,
            cast = 0,
            cooldown = function ()
                local x = 10 * haste
                if buff.serenity.up then x = max( 0, x - ( buff.serenity.remains / 2 ) ) end
                return x
            end,
            gcd = "spell",

            spend = function ()
                if buff.serenity.up then return 0 end
                return 2
            end,
            spendType = "chi",

            startsCombat = true,
            texture = 642415,

            cycle = "mark_of_the_crane",

            handler = function ()
                applyDebuff( 'target', 'mark_of_the_crane' )
                removeBuff( 'pressure_point' )

                if azerite.sunrise_technique.enabled then applyDebuff( "target", "sunrise_technique" ) end
            end,
        },


        roll = {
            id = 109132,
            cast = 0,
            charges = function () return talent.celerity.enabled and 2 or nil end,
            cooldown = function () return talent.celerity.enabled and 15 or 20 end,
            recharge = function () return talent.celerity.eanbled and 15 or 20 end,
            gcd = "spell",

            startsCombat = true,
            texture = 574574,

            notalent = "chi_torpedo",

            handler = function ()
                if azerite.exit_strategy.enabled then applyBuff( "exit_strategy" ) end
            end,
        },


        rushing_jade_wind = {
            id = 116847,
            cast = 0,
            cooldown = function ()
                local x = 6 * haste
                if buff.serenity.up then x = max( 0, x - ( buff.serenity.remains / 2 ) ) end
                return x
            end,
            hasteCD = true,
            gcd = "spell",

            spend = 1,
            spendType = "chi",

            talent = "rushing_jade_wind",

            startsCombat = false,
            texture = 606549,

            handler = function ()
                applyBuff( "rushing_jade_wind" )
            end,
        },


        serenity = {
            id = 152173,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 988197,

            talent = "serenity",

            handler = function ()
                applyBuff( "serenity" )
                setCooldown( "fist_of_the_white_tiger", cooldown.fist_of_the_white_tiger.remains - ( cooldown.fist_of_the_white_tiger.remains / 2 ) )
                setCooldown( "fists_of_fury", cooldown.fists_of_fury.remains - ( cooldown.fists_of_fury.remains / 2 ) )
                setCooldown( "rising_sun_kick", cooldown.rising_sun_kick.remains - ( cooldown.rising_sun_kick.remains / 2 ) )
                setCooldown( "rushing_jade_wind", cooldown.rushing_jade_wind.remains - ( cooldown.rushing_jade_wind.remains / 2 ) )
            end,
        },


        spear_hand_strike = {
            id = 116705,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 608940,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        spinning_crane_kick = {
            id = 101546,
            cast = 1.5,
            channeled = true,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.dance_of_chiji.up and 0 or 2 end,
            spendType = "chi",

            startsCombat = true,
            texture = 606543,

            start = function ()
                removeBuff( "dance_of_chiji" )
            end,
        },


        storm_earth_and_fire = {
            id = function () return buff.storm_earth_and_fire.up and 221771 or 137639 end,
            cast = 0,
            charges = 2,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 90 end,
            recharge = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136038,

            notalent = "serenity",
            nobuff = "storm_earth_and_fire",

            handler = function ()
                applyBuff( "storm_earth_and_fire" )
            end,

            copy = { 137639, 221771 }
        },


        tiger_palm = {
            id = 100780,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 50,
            spendType = "energy",

            startsCombat = true,
            texture = 606551,

            cycle = "mark_of_the_crane",

            buff = function () return prev_gcd[1].tiger_palm and buff.hit_combo.up and "hit_combo" or nil end,

            handler = function ()
                if talent.eye_of_the_tiger.enabled then
                    applyDebuff( "target", "eye_of_the_tiger" )
                    applyBuff( "eye_of_the_tiger" )
                end

                if pvptalent.alpha_tiger.enabled and debuff.recently_challenged.down then
                    if buff.alpha_tiger.down then stat.haste = stat.haste + 0.10 end
                    applyBuff( "alpha_tiger" )
                    applyDebuff( "target", "recently_challenged" )
                end

                applyDebuff( "target", "mark_of_the_crane" )

                gain( buff.power_strikes.up and 3 or 2, "chi" )
                removeBuff( "power_strikes" )
            end,
        },


        tigereye_brew = {
            id = 247483,
            cast = 0,
            cooldown = 1,
            gcd = "spell",

            startsCombat = false,
            texture = 613399,

            buff = "tigereye_brew_stack",
            pvptalent = "tigereye_brew",

            handler = function ()
                applyBuff( "tigereye_brew", 2 * min( 10, buff.tigereye_brew_stack.stack ) )
                removeStack( "tigereye_brew_stack", min( 10, buff.tigereye_brew_stack.stack ) )
            end,
        },


        tigers_lust = {
            id = 116841,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 651727,

            talent = "tigers_lust",

            handler = function ()
                applyBuff( "tigers_lust" )
            end,
        },


        touch_of_death = {
            id = 115080,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 606552,

            cycle = "touch_of_death",

            handler = function ()
                if level < 116 and equipped.hidden_masters_forbidden_touch and buff.hidden_masters_forbidden_touch.down then
                    applyBuff( "hidden_masters_forbidden_touch" )
                end
                applyDebuff( "target", "touch_of_death" )
            end,
        },


        touch_of_karma = {
            id = 122470,
            cast = 0,
            cooldown = 90,
            gcd = "off",

            startsCombat = true,
            texture = 651728,

            talent = "good_karma",

            usable = function ()                
                return incoming_damage_3s >= health.max * 0.2, "incoming damage not sufficient (20% / 3sec) to use"
            end,

            handler = function ()
                applyBuff( "touch_of_karma" )
                applyDebuff( "target", "touch_of_karma_debuff" )
            end,
        },


        transcendence = {
            id = 101643,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            startsCombat = false,
            texture = 627608,

            handler = function ()
            end,
        },


        transcendence_transfer = {
            id = 119996,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 237585,

            handler = function ()
            end,
        },


        vivify = {
            id = 116670,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "energy",

            startsCombat = false,
            texture = 1360980,

            handler = function ()
            end,
        },


        whirling_dragon_punch = {
            id = 152175,
            cast = 0,
            cooldown = 24,
            gcd = "spell",

            startsCombat = true,
            texture = 988194,

            talent = "whirling_dragon_punch",

            usable = function () return ( index > 1 or IsUsableSpell( 152175 ) ) and cooldown.fists_of_fury.remains > 0 and cooldown.rising_sun_kick.remains > 0 end,

            handler = function ()
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,
        cycle = true,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 8,

        potion = "unbridled_fury",

        package = "Windwalker",

        strict = false
    } )

    spec:RegisterSetting( "allow_fsk", true, {
        name = "Use |T606545:0|t Flying Serpent Kick",
        desc = "If unchecked, |T606545:0|t Flying Serpent Kick will not be recommended (this is the same as disabling the ability via Windwalker > Abilities > Flying Serpent Kick > Disable).",
        type = "toggle",
        width = 1.5,
        get = function () return not Hekili.DB.profile.specs[ 269 ].abilities.flying_serpent_kick.disabled end,
        set = function ( _, val )
            Hekili.DB.profile.specs[ 269 ].abilities.flying_serpent_kick.disabled = not val
        end,
    } ) 
    
    spec:RegisterSetting( "optimize_reverse_harm", false, {
        name = "Optimize |T627486:0|t Reverse Harm",
        desc = "If checked, |T627486:0|t Reverse Harm's caption will show the recommended target's name.",
        type = "toggle",
        width = 1.5
    } ) 
    
    spec:RegisterPack( "Windwalker", 20200409, [[d4KE(bqicjpsLuTjvIprifJss4uKu9kvsMfkLBbjyxs8ljjdJKYXuPSmcXZuPY0uPkxdLkBdLQ4BQKIgNKO6CsI06iKsZdOCpuY(GKoOkvLfkj1dvPQAIsIOlkjk1gvjL(ikvPAKQKcDsvsbRei9suQsMjkvPCtiHGDss6NqcHAOqcrlvseEkbtLK4QsIITcjeYxLeLmwiH0Ej1FHAWkoSslwGhJQjl0Lr2meFgGrtItt1QHeQxdeZwf3gf7wv)wQHtOooHuTCqpNOPt56cA7avFhsnEirNhqRhLQA(sQ9lA9nTkAH4AKwvrute1u7EQvPLBQjc7HDvQwWakM0cIxoilasl8ldPfQS8pIEpGqqTG4f4P3OwfTGSdHCslOyMyPOTQQa4MsyqH3mvjDMWZAE)C4IyvjDgEvAHGq)yxdVoqlexJ0QkIAIOMA3tTkTCtnrypS7oTGumX1Qkc7Ps1ckEmsVoqlejjxlC9CQS8pIEpGqWCqrOFqsqVEokMjwkARQkaUPegu4ntvsNj8SM3phUiwvsNHxvc61Z5(ed9tovkB5iIAIOwcAc61Z5(v2hajfTjOxphuiNkbX0Gt5iiMwyoxJ7hZrWGoiuo8(JM3VmNku2pEOyobaZzJX(vVKGE9CqHCUFL9bq5yleazyhjhRZHdKFiSTqaKjljOxphuiNkbX0Gt5qpbbamh(kohUcXbjhKgMZ16stMtJKZ1gcbMtfsNjNOJGqq65uoUmNNaCCaEWHylNGqlhXNfyorhbHG0ZPCCzoshW7ioFFt9sc61ZbfY5(IrkMtLrs5CnyeJmNkmO)GqMKTCiJxuVOfoU0KAv0c8iwsiAv0QEtRIwG(n4qrD1Abo0nc6RwiiebPiji9UbSeB0Fo115yodHTghDkhWYre2PfwU59Rf8h8gecJYq61Mwvr0QOfOFdouuxTwGdDJG(QfmNHWwJJoLdQ5CRYzxo115iQCaFH(gCOIsFIyRJ5CjhE3NyJ(lwhYvWncosRPuGeZ6VmhWyLZT7LtDDoMZqyRXrNYbSCUJDAHLBE)AbaHlm67JBe8Y(eSnfTPv9oTkAb63Gdf1vRf4q3iOVAbE3NyJ(lwhYvWncosRPuGeZ6VmhuZHDvEo115W7(eB0FX6qUcUrWrAnLcKyw)L5awoIKtDDoGVqFdourPprS1XCQRZXCgcBno6uoGLJiQPfwU59Rfq3WteCYFmKK9VpN0Mw17Pvrlq)gCOOUATah6gb9vlWv8cZIYCqHC4kEoOYkNB5Cjh6jiaGfZziS1yMfL5GkRCuRWoTWYnVFTWc57tyRHq6nTPvLDAv0c0VbhkQRwlWHUrqF1cIkhWxOVbhQO0Ni26yoxYPICevoKOh6IftXchi)0gSFNJdoR0YPUohE3NyJ(lCG8tBW(Doo4SsRajM1FzoGXkNB5OEoxYPIC4kEoOMZTCQRZHEccayoGLZ9ulh11cl38(1cwhYvWncosRPOnTQShTkAb63Gdf1vRf4q3iOVAbE3NyJ(lsRHmyAHMcE)igXHuHRSqaKmhw5iso115eBRyDixb3i4iTMsbsmR)YCQRZXCgcBno6uoGLJiQLtDDovKtqicsbDdprWj)Xqs2)(CQajM1FzoOMZn1YPUohE3NyJ(lOB4jco5pgsY(3NtfiXS(lZb1C4DFIn6ViTgYGPfAk49JyehsfKWZbdjUYcbqyZzOCQRZru5qsj9CQGUHNi4K)yij7FFovywuCdZr9CUKtf5W7(eB0FX6qUcUrWrAnLcKyw)L5GAo8UpXg9xKwdzW0cnf8(rmIdPcs45GHexzHaiS5muo115a(c9n4qfL(eXwhZ5soIkhs0dDXIPyjc9GGJ)aW(dI4oMJ65CjhE3NyJ(liU0K4gbJecbwGeZ6VmhWyLtLMZLC4kEoOYkN7Y5so8UpXg9xqR4WJ)aWr4cOFS4WNRuGeZ6VmhWyLZT70cl38(1csRHmyAHMcE)igXHK20QEn1QOfOFdouuxTwGdDJG(Qf4DFIn6VyDixb3i4iTMsbsmR)YCqnN7XUCQRZb8f6BWHkk9jIToMZLC4DFIn6VG4stIBemsieybsmR)YCalhrYPUohZziS14Ot5awo3ejN66CmNHWwJJoLdQ5Ctn1Y5soMZqyRXrNYbSCUDtTCUKtf5W7(eB0FbXLMe3iyKqiWcKyw)L5awo3LtDDo8UpXg9xqR4WJ)aWr4cOFS4WNRuGeZ6VmhWYHD5uxNdV7tSr)fOl9hawg(yqCoifiXS(lZbSCyxoQRfwU59RfcoDhXnc2uim9edqTPvTY1QOfOFdouuxTwGdDJG(QfevoX2k8(50BW1Oig5Smeoie(fiXS(lZ5sovKtf5W7(eB0FH3pNEdUgfXiNLHkqIz9xMdySYH39j2O)I1HCfCJGJ0AkfiXS(lZ5QCULtDDoGVqFdourPprS1XCupNl5uroIkhBp0Bf0ko84paCeUa6hlo85kf63GdfZPUohE3NyJ(lOvC4XFa4iCb0pwC4ZvkqIz9xMJ65CjhE3NyJ(lqx6paSm8XG4CqkqIz9xMZLC4DFIn6VG4stIBemsieybsmR)YCUKtqicsrAnKbtl0uW7hXioKkXg9NtDDoX2kwhYvWncosRPuGeZ6Vmh1ZPUohZziS14Ot5awovUwy5M3VwG3pNEdUgfXiNLH0Mw1kvRIwG(n4qrD1Abo0nc6RwG39j2O)I1HCfCJGJ0AkfiXS(lZb1CUtTCQRZb8f6BWHkk9jIToMtDDoMZqyRXrNYbSCernTWYnVFTqWP7igjecuBAvVPMwfTa9BWHI6Q1cCOBe0xTaV7tSr)fRd5k4gbhP1ukqIz9xMdQ5CNA5uxNd4l03Gdvu6teBDmN66CmNHWwJJoLdy5CJDAHLBE)AHackjii(dqBAvVDtRIwy5M3Vw44aumjgfhgbWqVPfOFdouuxT20QEteTkAb63Gdf1vRf4q3iOVAbE3NyJ(lwhYvWncosRPuGeZ6VmhuZ5o1YPUohWxOVbhQO0Ni26yo115yodHTghDkhWY5MAAHLBE)AbehsbNUJAtR6T70QOfOFdouuxTwGdDJG(Qf4DFIn6VyDixb3i4iTMsbsmR)YCqnN7ulN66CaFH(gCOIsFIyRJ5uxNJ5me2AC0PCalhrutlSCZ7xlSpNKgCpy(EoAtR6T7PvrlSCZ7xleSaWnc2GohePwG(n4qrD1AtR6n2Pvrlq)gCOOUATWYnVFTWkvaFFsIHl73qmVH7rlWHUrqF1cGVqFdouX6iUFCOKWg0FqilNl5uro8UpXg9xSoKRGBeCKwtPajM1FzoOMJi3YPUohWxOVbhQO0Ni26yoQNZLCQiNifeIGuGl73qmVH7bhPGqeKsSr)5uxNtqicsrAnKbtl0uW7hXioKkqIz9xMdQ5C7UCQRZXCgcBno6uoOqo8UpXg9xSoKRGBeCKwtPajM1FzoGLZ9ulNl5W7(eB0FX6qUcUrWrAnLcKyw)L5awoIWUCQRZXCgcBno6uoGLJiSlh11c)YqAHvQa((Kedx2VHyEd3J20QEJ9Ovrlq)gCOOUATWYnVFTWkvaFFsIHl73qmVH7rlWHUrqF1cIkhWxOVbhQyDe3pousyd6piKLZLCQiNifeIGuGl73qmVH7bhPGqeKsSr)5uxNtf5iQCirp0flMILi0dco(da7piI7yo115yleazfZziS1yXCdFNA5awovEoQNZLCQiNyBfRd5k4gbhP1ukqIz9xMtDDo8UpXg9xSoKRGBeCKwtPajM1FzoxLtLMdQ5yodHTghDkh1Z5sobHiifP1qgmTqtbVFeJ4qQekoN66CmNHWwJJoLdy5ic7YrDTWVmKwyLkGVpjXWL9BiM3W9OnTQ3UMAv0cl38(1cMcHd)Go8JyKgYjTa9BWHI6Q1Mw1BvUwfTWYnVFTG4qOJa0Fa4GZknTa9BWHI6Q1Mw1BvQwfTa9BWHI6Q1cl38(1cqAf7pamYzziPwGdDJG(QfSfcGSI5me2AC0PCalNBf2LtDDovKtf5yleazffApMsrm3Yb1CQC1YPUohBHaiROq7XukI5woGXkhrulh1Z5sovKZYnhCctpX4Kmhw5ClN66CSfcGSI5me2AC0PCqnhrQ0Cuph1ZPUoNkYXwiaYkMZqyRXI5gwe1Yb1CUtTCUKtf5SCZbNW0tmojZHvo3YPUohBHaiRyodHTghDkhuZ5E3lh1ZrDTahi)qyBHaitQv9M20QkIAAv0cl38(1cinpusr8Y(e0nchqlJwG(n4qrD1AtRQi30QOfOFdouuxTwGdDJG(QfONGaaMdy5Cp10cl38(1cmetdbIBe8jK7rCeslJuBAvfreTkAHLBE)AbOlw8HW(JLIxoPfOFdouuxT20QkYDAv0cl38(1cblaCJGnOZbrQfOFdouuxT20QkY90QOfOFdouuxTwGdDJG(QfQihs0dDXIPyHdKFAd2VZXbNvA5CjhE3NyJ(lCG8tBW(Doo4SsRajM1FzoGXkhrulh1ZPUohrLdj6HUyXuSWbYpTb7354GZknTWYnVFTqOKWUrmsTPnTqKq2WJPvrR6nTkAHLBE)AbPyAHyL9JyPbDqiTa9BWHI6Q1Mwvr0QOf83ii47rluPQPfeZnScThtrlOwHDAHLBE)AbRd5k4gbdYczwTa9BWHI6Q1Mw170QOfOFdouuxTwGdDJG(QfccrqkscsVBalHIZPUoNGqeKI0AidMwOPG3pIrCivcfNZLCITvSoKRGBeCKwtPajM1Fzo115yodHTghDkhWyLd7rnTWYnVFTG428(1Mw17Pvrlq)gCOOUATah6gb9vlWv8cZIYCqHC4kEoOYkhrY5sovKJTh6TIKG07gWc9BWHI5uxNJOYj2wX6qUcUrWrAnLcKyw)L5OEoxYjiebPiji9UbSeB0FoxYPICONGaawmNHWwJzwuMdy5ClN66CS9qVvKeKE3awOFdoumNl5W7(eB0Frsq6DdybsmR)YCalhrYPUohrLJTh6TIKG07gWc9BWHI5CjhE3NyJ(lwhYvWncosRPuGeZ6VmhWY5UCUKJOYb8f6BWHkk9jIToMtDDo0tqaalMZqyRXmlkZbSCUxoxYH39j2O)cIlnjUrWiHqGfiXS(lZbSCUvyxoQRfwU59RfGe4eusyLfYOnTQStRIwG(n4qrD1AHLBE)AbexA4gbBkegTIBe2CaeulWHUrqF1cCfVWSOmhuihUINdQSY5UCUKtqicsrsq6Ddyj2O)CUKtqicsrsKP4pamCbqLyJ(Z5sovKd9eeaWI5me2AmZIYCalNB5uxNJTh6TIKG07gWc9BWHI5CjhE3NyJ(lscsVBalqIz9xMdy5iso115iQCS9qVvKeKE3awOFdoumNl5W7(eB0FX6qUcUrWrAnLcKyw)L5awo3LZLCevoGVqFdourPprS1XCQRZHEccayXCgcBnMzrzoGLZ9Y5so8UpXg9xqCPjXncgjecSajM1FzoGLZTc7YrDTahi)qyBHaitQv9M20QYE0QOfOFdouuxTwy5M3VwWCaeelEpmAbo0nc6Rwqu5WBMGghaPfKCUKdxXlmlkZbfYHR45GkRCejNl5uro2EO3kscsVBal0VbhkMtDDoIkNyBfRd5k4gbhP1ukqIz9xMtDDol3CWjm9eJtYCqnhrYr9CUKtqicsrsKP4pamCbqLyJ(Z5sobHiifjbP3nGLyJ(Z5sovKd9eeaWI5me2AmZIYCalNB5uxNJTh6TIKG07gWc9BWHI5CjhE3NyJ(lscsVBalqIz9xMdy5iso115iQCS9qVvKeKE3awOFdoumNl5W7(eB0FX6qUcUrWrAnLcKyw)L5awo3LZLCevoGVqFdourPprS1XCQRZHEccayXCgcBnMzrzoGLZ9Y5so8UpXg9xqCPjXncgjecSajM1FzoGLZTc7YrDTahi)qyBHaitQv9M20QEn1QOfOFdouuxTwGdDJG(Qfevo2EO3kiU0Wnc2uimAf3iS5aiyH(n4qXCUKJyibogapwUvmhabXI3dtoxYXCgkhWyLZDAHLBE)AbUIJrVGtAtRALRvrlq)gCOOUATah6gb9vly7HERiji9UbSq)gCOOwy5M3VwGVNdE5M3p(4stlCCPH)LH0c8iwsq6DdO20QwPAv0c0VbhkQRwlWHUrqF1cIkhBp0BfjbP3nGf63Gdf1cl38(1c89CWl38(XhxAAHJln8VmKwGhXscrBAvVPMwfTa9BWHI6Q1cCOBe0xTqqicsrsq6DdyjuSwy5M3VwGVNdE5M3p(4stlCCPH)LH0cscsVBa1Mw1B30QOfOFdouuxTwGdDJG(QfwU5Gty6jgNK5awo3PfwU59Rf475GxU59JpU00chxA4FziTG00Mw1BIOvrlq)gCOOUATah6gb9vlSCZbNW0tmojZbvw5CNwy5M3VwGVNdE5M3p(4stlCCPH)LH0cBtAtBAbXqI3mbRPvrR6nTkAHLBE)AbXT59RfOFdouuxT20QkIwfTa9BWHI6Q1cTyTGKmTWYnVFTa4l03GdPfaFpHKwGe9qxSykw4a5N2G97CCWzLwo115qIEOlwmflNqPb7qjgqFI0JfFczwauo115qIEOlwmflaoB0xRHsCWgbq5uxNdj6HUyXuSa4SrFTgkXmuCphV)CQRZHe9qxSykwGetBegqOh3Nt4ibUZjTa4le)ldPfSoI7hhkjSb9heY0Mw170QOfOFdouuxTwOfRfKKPfwU59RfaFH(gCiTa47jK0c8UpXg9xSoKRGBeCKwtPajM1FzoxLtLMdQ5yleazfZziS14Ot5uxNJOYX2d9wrsq6DdyH(n4qXCUKJOYb8f6BWHkwhX9JdLe2G(dcz5Cjhs0dDXIPyjc9GGJ)aW(dI4oMZLCSfcGSI5me2ASyUHVtTCalNB3PwoxYXwiaYkMZqyRXI5g(o1Yb1CQ8CQRZXCgcBno6uoGLZT7ulNl5yodHTghDkhuZH39j2O)IKG07gWcKyw)L5CjhE3NyJ(lscsVBalqIz9xMdQ5iso115eeIGuKeKE3awcfNZLCSfcGSI5me2AC0PCqnNB30cGVq8VmKwqPprS1rTPv9EAv0c0VbhkQRwl0I1csY0cl38(1cGVqFdoKwa89esAHBvQwGdDJG(Qfevo2EO3kscsVBal0VbhkMZLCQihWxOVbhQyDe3pousyd6piKLtDDoKOh6IftXYkvaFFsIHl73qmVH7jh11cGVq8VmKwaPFd3iyXnAcIfdjEZeSgMRS)thTPvLDAv0c0VbhkQRwl8ldPfw2xQSWvIr63WncwCJMGAHLBE)AHL9LklCLyK(nCJGf3OjO20QYE0QOfOFdouuxTwGdDJG(Qfevo2EO3kscsVBal0VbhkMtDDoIkhBp0BfexA4gbBkegTIBe2CaeSq)gCOOwy5M3VwGR44GqO00Mw1RPwfTa9BWHI6Q1cCOBe0xTGTh6TcIlnCJGnfcJwXncBoacwOFdoumN66CiPKEov49JCCUH3pILg0rOcZIIBOwy5M3VwGR4y0l4K20Qw5Av0cl38(1c(dEdcHrzi9Ab63Gdf1vRnTQvQwfTWYnVFTaGWfg99XncEzFc2MIwG(n4qrD1AtBAHTjTkAvVPvrlSCZ7xlGwXHh)bGJWfq)yXHpxrlq)gCOOUATPvveTkAb63Gdf1vRf4q3iOVAbrLJyibogapwUvmhabXI3dtoxYHR45agRCULZLCONGaaMdy5Wo10cl38(1c0tqao77pamDCu6qTPv9oTkAb63Gdf1vRf4q3iOVAb6jiaGfZziS1yMfL5GAo30cl38(1ciU0K4gbJecbQnTQ3tRIwG(n4qrD1AHLBE)AbOl9hawg(yqCoiAbo0nc6RwOICS9qVvqR4WJ)aWr4cOFS4WNRuOFdoumNl5W7(eB0Fb6s)bGLHpgeNdsjgcxZ7phuZH39j2O)cAfhE8haocxa9Jfh(CLcKyw)L5Cvo3lh1Z5sovKdV7tSr)fexAsCJGrcHalqIz9xMdQ5Cxo115Wv8CqLvoSlh11cCG8dHTfcGmPw1BAtRk70QOfOFdouuxTwGdDJG(QfccrqkWqPI)aWO4nsy0(hlXg9RfwU59RfGHsf)bGrXBKWO9pQnTQShTkAb63Gdf1vRf4q3iOVAbEZe0yPbDqOCUKtf5urovKdxXZb1CUlN66C4DFIn6VG4stIBemsieybsmR)YCqnh2toQNZLCQihUINdQSYHD5uxNdV7tSr)fexAsCJGrcHalqIz9xMdQ5isoQNJ65uxNd9eeaWI5me2AmZIYCaJvo3LtDDobHiiL4(Cc3iyUIJI9cKwULJ6AHLBE)AbPy)F)bG5W9jmioheTPv9AQvrlq)gCOOUATah6gb9vlWv8cZIYCqHC4kEoOYkhr0cl38(1cqcCckjSYcz0Mw1kxRIwG(n4qrD1Abo0nc6RwGR4fMfL5Gc5Wv8CqLvo3PfwU59Rf4kooieknTPvTs1QOfOFdouuxTwy5M3VwaXLgUrWMcHrR4gHnhab1cCOBe0xTaxXlmlkZbfYHR45GkRCUtlyleazyhrlOnTQ3utRIwG(n4qrD1AHLBE)AbZbqqS49WOf4q3iOVAbUIxywuMdkKdxXZbvw5isoxYPICevo2EO3kkUH5ntqxOFdoumN66Cevo8MjOXbqAbjh11c2cbqg2r0cAtR6TBAv0c0VbhkQRwlWHUrqF1cIkhEZe04aiTGOfwU59Rf4kog9coPnTQ3erRIwG(n4qrD1AHLBE)AbKdq)bGLeum9ggeNdIwGdDJG(QfccrqkbniyXWMxIn6xl4VrqyOytlCtBAvVDNwfTa9BWHI6Q1cl38(1cbNLdshAyqCoiAbo0nc6RwG3mbnwAqhekNl5urobHiiLGgeSyyZlHIZPUoNkYX2d9wrXnmVzc6c9BWHI5CjhXqcCmaESCRyoacIfVhMCUKdxXZbSCUxoQNJ6Aboq(HW2cbqMuR6nTPnTapILeKE3aQvrR6nTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)5uxNJ5me2AC0PCalhryNwy5M3VwWFWBqimkdPxBAvfrRIwG(n4qrD1Abo0nc6RwiiebPiji9UbSeB0FoxYPICmNHWwJJoLdQ5CRYzxo115W7(eB0Frsq6DdybsmR)YCaJvoxZCupN66CmNHWwJJoLdy5Ch70cl38(1cacxy03h3i4L9jyBkAtR6DAv0c0VbhkQRwlWHUrqF1c8UpXg9xKeKE3awGeZ6VmhuZre1YPUohZziS14Ot5awoIOMwy5M3Vwi40DeJecbQnTQ3tRIwG(n4qrD1Abo0nc6RwG39j2O)IKG07gWcKyw)L5GAoIOwo115yodHTghDkhWY5g70cl38(1cbeusqq8hG20QYoTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)5CjhUIxywuMdkKdxXZbvw5ClNl5qpbbaSyodHTgZSOmhuzLJAf2PfwU59RfwiFFcBnesVPnTQShTkAHLBE)AHJdqXKyuCyead9MwG(n4qrD1AtR61uRIwG(n4qrD1Abo0nc6RwG39j2O)IKG07gWcKyw)L5GAoIOwo115yodHTghDkhWY5MAAHLBE)AbehsbNUJAtRALRvrlq)gCOOUATah6gb9vlW7(eB0Frsq6DdybsmR)YCqnhrulN66CmNHWwJJoLdy5iIAAHLBE)AH95K0G7bZ3ZrBAvRuTkAHLBE)AHGfaUrWg05Gi1c0VbhkQRwBAvVPMwfTa9BWHI6Q1cCOBe0xTGOYb8f6BWHkk9jIToQfwU59RfSoKRGBeCKwtrBAvVDtRIwG(n4qrD1Abo0nc6RwiiebPiji9UbSeB0FoxYPIC4DFIn6Viji9UbSajM1FzoOMJiQLtDDo8UpXg9xKeKE3awGeZ6VmhWYrKCupN66CmNHWwJJoLdy5CJDAHLBE)AHGt3rCJGnfctpXauBAvVjIwfTa9BWHI6Q1cl38(1cRub89jjgUSFdX8gUhTah6gb9vlePGqeKcCz)gI5nCp4ifeIGuIn6pN66CccrqkscsVBalqIz9xMdQ5uP5uxNJ5me2AC0PCalhryNw4xgslSsfW3NKy4Y(neZB4E0Mw1B3Pvrlq)gCOOUATah6gb9vleeIGuKeKE3awIn6pNl5uro8UpXg9xKeKE3awGeZ6VmhuZ5g7YPUohE3NyJ(lscsVBalqIz9xMdy5isoQNtDDoMZqyRXrNYbSCernTWYnVFTa6gEIGt(JHKS)95K20QE7EAv0c0VbhkQRwlWHUrqF1cbHiifjbP3nGLyJ(Z5sovKdV7tSr)fjbP3nGfiXS(lZPUohE3NyJ(l8(50BW1Oig5SmuHRSqaKmhw5isoQNZLCevoX2k8(50BW1Oig5Smeoie(fiXS(lZ5sovKdV7tSr)fOl9hawg(yqCoifiXS(lZ5so8UpXg9xqCPjXncgjecSajM1Fzo115yodHTghDkhWYPYZrDTWYnVFTaVFo9gCnkIroldPnTQ3yNwfTWYnVFTGKG07gqTa9BWHI6Q1Mw1BShTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)AHLBE)AbtHWHFqh(rmsd5K20QE7AQvrlq)gCOOUATah6gb9vleeIGuKeKE3awIn6xlSCZ7xlioe6ia9hao4SstBAvVv5Av0c0VbhkQRwlSCZ7xlaPvS)aWiNLHKAbo0nc6RwiiebPiji9UbSeB0FoxYPICSfcGSI5me2AC0PCalNBf2LtDDovKtf5yleazffApMsrm3Yb1CQC1YPUohBHaiROq7XukI5woGXkhrulh1Z5sovKZYnhCctpX4Kmhw5ClN66CSfcGSI5me2AC0PCqnhrQ0Cuph1ZPUoNkYXwiaYkMZqyRXI5gwe1Yb1CUtTCUKtf5SCZbNW0tmojZHvo3YPUohBHaiRyodHTghDkhuZ5E3lh1Zr9CuxlWbYpe2wiaYKAvVPnTQ3QuTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)AHLBE)AbKMhkPiEzFc6gHdOLrBAvfrnTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)5Cjh6jiaG5awo3tnTWYnVFTadX0qG4gbFc5EehH0Yi1MwvrUPvrlq)gCOOUATah6gb9vleeIGuKeKE3awIn6xlSCZ7xlaDXIpe2FSu8YjTPvver0QOfOFdouuxTwGdDJG(QfccrqkscsVBalXg9RfwU59Rfcwa4gbBqNdIuBAvf5oTkAb63Gdf1vRf4q3iOVAHGqeKIKG07gWsSr)5CjNkYPICirp0flMIfoq(Pny)ohhCwPLZLC4DFIn6VWbYpTb7354GZkTcKyw)L5agRCerTCupN66CevoKOh6IftXchi)0gSFNJdoR0YrDTWYnVFTqOKWUrmsTPnTG00QOv9MwfTWYnVFTaAfhE8haocxa9Jfh(CfTa9BWHI6Q1Mwvr0QOfOFdouuxTwGdDJG(QfS9qVvKeKE3awOFdoumN66C4DFIn6VyDixb3i4iTMsbsmR)YCqnh2to115a(c9n4qfL(eXwh1cl38(1ciU0K4gbJecbQnTQ3Pvrlq)gCOOUATWYnVFTa0L(daldFmioheTah6gb9vlW7(eB0FX6qUcUrWrAnLcKyw)L5GAoIKtDDoGVqFdourPprS1rTahi)qyBHaitQv9M20QEpTkAb63Gdf1vRf4q3iOVAHGqeKcmuQ4pamkEJegT)XsSr)5CjNLBo4eMEIXjzoOMZnTWYnVFTamuQ4pamkEJegT)rTPvLDAv0c0VbhkQRwlWHUrqF1cCfVWSOmhuihUINdQ5CtlSCZ7xlajWjOKWklKrBAvzpAv0c0VbhkQRwlSCZ7xlG4sd3iytHWOvCJWMdGGAbo0nc6RwGR45awo3Pf4a5hcBleazsTQ30Mw1RPwfTa9BWHI6Q1cCOBe0xTaxXZbmw5CxoxYHEccayoGLd7utlSCZ7xlqpbb4SV)aW0XrPd1Mw1kxRIwG(n4qrD1Abo0nc6RwGR4fMfL5Gc5Wv8Cqnh1Y5sol3CWjm9eJtYCyLZTCQRZHR4fMfL5Gc5Wv8CqnNBAHLBE)AbUIJdcHstBAvRuTkAb63Gdf1vRfwU59RfmhabXI3dJwGdDJG(Qf4ntqJLg0bHY5soCfVWSOmhuihUINdQ5CxoxYru5eBRyDixb3i4iTMsbsmR)YCUKtqicsrAnKbtl0uW7hXioKkXg9Rf4a5hcBleazsTQ30Mw1BQPvrlSCZ7xlWvCm6fCslq)gCOOUATPv92nTkAb63Gdf1vRf4q3iOVAbEZe0yPbDqOCUKtqicsjUpNWncMR4OyVaPLBAHLBE)AbPy)F)bG5W9jmioheTPv9MiAv0c0VbhkQRwlSCZ7xleCwoiDOHbX5GOf4q3iOVAbEZe0yPbDqOCUKtf5uro8UpXg9xSoKRGBeCKwtPajM1FzoOMJi5uxNd4l03Gdvu6teBDmh1Z5sovKdV7tSr)fOl9hawg(yqCoifiXS(lZb1CejNl5W7(eB0FbXLMe3iyKqiWcKyw)L5GAoIKtDDo8UpXg9xGU0Fayz4JbX5GuGeZ6VmhWY5UCUKdV7tSr)fexAsCJGrcHalqIz9xMdQ5CxoxYHR45GAoIKtDDo8UpXg9xGU0Fayz4JbX5GuGeZ6VmhuZ5UCUKdV7tSr)fexAsCJGrcHalqIz9xMdy5CxoxYHR45GAo3lN66C4kEoOMd7Yr9CQRZjiebPe0GGfdBEjuCoQRf4a5hcBleazsTQ30Mw1B3Pvrlq)gCOOUATWYnVFTG5aiiw8Ey0cCOBe0xTaVzcAS0GoiuoxYHR4fMfL5Gc5Wv8CqnNBAboq(HW2cbqMuR6nTPv9290QOf83iimuSPfUPfwU59Rfqoa9hawsqX0ByqCoiAb63Gdf1vRnTQ3yNwfTa9BWHI6Q1cl38(1cbNLdshAyqCoiAbo0nc6RwOIC4DFIn6VG4stIBemsieybsmR)YCalN7Y5soCfphw5iso115qpbbaSyodHTgZSOmhWY5woQNZLCQihXqcCmaESCRyoacIfVhMCQRZHR4fMfL5Gc5Wv8CalhrYrDTahi)qyBHaitQv9M20Mwqsq6DdOwfTQ30QOfOFdouuxTwGdDJG(QfccrqkscsVBalqIz9xMdy5ClN66CwU5Gty6jgNK5GAo30cl38(1ciU0K4gbJecbQnTQIOvrlq)gCOOUATah6gb9vlWBMGglnOdcLZLCQiNLBo4eMEIXjzoOMJi5uxNZYnhCctpX4KmhuZ5woxYru5W7(eB0Fb6s)bGLHpgeNdsjuCoQRfwU59RfKI9)9haMd3NWG4Cq0Mw170QOfOFdouuxTwy5M3Vwa6s)bGLHpgeNdIwGdDJG(Qf4ntqJLg0bH0cCG8dHTfcGmPw1BAtR690QOf83iimuSHDeTaaESajM1Fjl10cl38(1ciU0K4gbJecbQfOFdouuxT20QYoTkAb63Gdf1vRfwU59RfqCPHBeSPqy0kUryZbqqTah6gb9vlWv8CalN70cCG8dHTfcGmPw1BAtRk7rRIwG(n4qrD1Abo0nc6RwGR4fMfL5Gc5Wv8CqnNB5Cjh6jiaGfZziS1yMfL5awo30cl38(1cqcCckjSYcz0Mw1RPwfTa9BWHI6Q1cl38(1cbNLdshAyqCoiAbo0nc6RwG3mbnwAqhekN66Cevo2EO3kkUH5ntqxOFdouulWbYpe2wiaYKAvVPnTQvUwfTWYnVFTGuS)V)aWC4(egeNdIwG(n4qrD1AtBAtlaobLE)AvfrnrutT7PMiAb0l89hGuluzDFvcvVguL9UOnNCurHYXze3qlhKgMJOHhXscr0KdKe9qhsXCKndLZgAnZAumhUY(aizjbL9M)uo3ypI2CU)(bNGgfZr0yodHTglMByuuu0cKyw)LIMCSohrJ5me2ASyUHrrrrfn5uXnuQEjbnbTY6(QeQEnOk7DrBo5OIcLJZiUHwoinmhrJyiXBMG1en5ajrp0HumhzZq5SHwZSgfZHRSpaswsqzV5pLZDI2CU)(bNGgfZr0yodHTglMByuuu0cKyw)LIMCSohrJ5me2ASyUHrrrrfn5uHiOu9scAcAL19vju9Aqv27I2CYrffkhNrCdTCqAyoIMTjrtoqs0dDifZr2muoBO1mRrXC4k7dGKLeu2B(t5uPI2CQeetdofZHXFrlkAoCfIdsov8TLZc(6Nn4q54Foet4znVF1ZPIBOu9sck7n)PCUPMOnNkbX0GtXCy8x0IIMdxH4GKtfFB5SGV(zdouo(NdXeEwZ7x9CQ4gkvVKGMGEnWiUHgfZ5AMZYnV)CoU0KLeuTWgAknuli4m3VwqmSr8dPfUEovw(hrVhqiyoOi0pijOxphfZelfTvvfa3ucdk8MPkPZeEwZ7NdxeRkPZWRkb965CFIH(jNkLTCernrulbnb965C)k7dGKI2e0RNdkKtLGyAWPCeetlmNRX9J5iyqhekhE)rZ7xMtfk7hpumNaG5SXy)QxsqVEoOqo3VY(aOCSfcGmSJKJ15WbYpe2wiaYKLe0RNdkKtLGyAWPCONGaaMdFfNdxH4GKdsdZ5ADPjZPrY5AdHaZPcPZKt0rqii9CkhxMZtaooap4qSLtqOLJ4ZcmNOJGqq65uoUmhPd4DeNVVPEjb965Gc5CFXifZPYiPCUgmIrMtfg0FqitYwoKXlQxsqtqVEov2OK4HgfZjGqAiLdVzcwlNacG)Yso3hNtInzoF)OGYczqcp5SCZ7xMt)hGLe0RNZYnVFzrmK4ntWASqoReKe0RNZYnVFzrmK4ntWAxXQkKUJjOxpNLBE)YIyiXBMG1UIvvBiag6T18(tqVEoc)kwQ0woW1J5eeIGqXCK2AYCciKgs5WBMG1YjGa4VmN9J5igsOG42m)bKJlZj2pvsqVEol38(LfXqI3mbRDfRQK)kwQ0gwARjtqxU59llIHeVzcw7kwvjUnV)e0RNZ9RqCqK54i5aSdZrzbNYzZXG(dcz5qIEOlwmfZXuwlh07BYCSoNakNqjfZXAaKPqWCq7MsoQ0vYe0LBE)YIyiXBMG1UIvvGVqFdoeB)YqSSoI7hhkjSb9heYyRfZssgBGVNqIfj6HUyXuSWbYpTb7354GZkT6As0dDXIPy5eknyhkXa6tKES4tiZcGQRjrp0flMIfaNn6R1qjoyJaO6As0dDXIPybWzJ(AnuIzO4EoE)11KOh6IftXcKyAJWac94(CchjWDoLGE9Cqr0c9n4q5ykRLdA)CYXOZjhGDyoosoa7WCq7NtoprXCSoh0RB5yDo8vA5OsxjRk258TLd69TCSoh(kTCClN1YzpNC2hitdPe0LBE)YIyiXBMG1UIvvGVqFdoeB)YqSu6teBDKTwmljzSb(Ecjw8UpXg9xSoKRGBeCKwtPajM1F5vvkQ2cbqwXCgcBno6uDTOS9qVvKeKE3awOFdou8IOaFH(gCOI1rC)4qjHnO)Gq2fs0dDXIPyjc9GGJ)aW(dI4oEXwiaYkMZqyRXI5g(o1kqIz9xc2T7u7ITqaKvmNHWwJfZn8DQvGeZ6Ve1kVU2CgcBno6ey3UtTlMZqyRXrNqL39j2O)IKG07gWcKyw)Lx4DFIn6Viji9UbSajM1FjQIuxheIGuKeKE3awcfFXwiaYkMZqyRXrNq92Te0LBE)YIyiXBMG1UIvvGVqFdoeB)YqSq63WncwCJMGyXqI3mbRH5k7)0HTwmljzSb(Ecjw3Qu2CewIY2d9wrsq6DdyH(n4qXlva(c9n4qfRJ4(XHscBq)bHS6As0dDXIPyzLkGVpjXWL9BiM3W9OEc6YnVFzrmK4ntWAxXQQqjHDJyy7xgI1Y(sLfUsms)gUrWIB0embD5M3VSigs8MjyTRyvfxXXbHqPXMJWsu2EO3kscsVBal0VbhkwxlkBp0BfexA4gbBkegTIBe2CaeSq)gCOyc6YnVFzrmK4ntWAxXQkUIJrVGtS5iSS9qVvqCPHBeSPqy0kUryZbqWc9BWHI11KuspNk8(roo3W7hXsd6iuHzrXnmbD5M3VSigs8MjyTRyvL)G3Gqyugsp2uimAf3iS5aiyc6YnVFzrmK4ntWAxXQkaHlm67JBe8Y(eSnLe0e0RNtLnkjEOrXCiWjiWCmNHYXuOCwU1WCCzol4RF2GdvsqxU59lzjftleRSFelnOdcLGUCZ7xEfRQSoKRGBemilKzzZFJGGVhwvQASjMByfApMcl1kSlb965uzKuoIBZ7phhjhbcsVBaZXL5ekMTCAyobTPKJqL91MZ(XCuPRK5SqkNqXSLtdZXuOCSfcGSCq7NtorNYbTBk(Nd7rTCKeV)OmbD5M3V8kwvjUnVF2CewbHiifjbP3nGLqX11bHiifP1qgmTqtbVFeJ4qQek(sSTI1HCfCJGJ0AkfiXS(lRRnNHWwJJobgl2JAjOl38(LxXQkibobLewzHmS5iS4kEHzrjkWvCuzjYLkS9qVvKeKE3awOFdouSUwuX2kwhYvWncosRPuGeZ6Vu9lbHiifjbP3nGLyJ(Vub9eeaWI5me2AmZIsWUvxB7HERiji9UbSq)gCO4fE3NyJ(lscsVBalqIz9xcMi11IY2d9wrsq6DdyH(n4qXl8UpXg9xSoKRGBeCKwtPajM1Fjy3DruGVqFdourPprS1X6A6jiaGfZziS1yMfLGDVl8UpXg9xqCPjXncgjecSajM1Fjy3kSt9e0RNtLrs5CTTvzPsooso5aSdZzHuomUu6pGCwlNdTslN7YHR4SLZ99XCYrsq6DdiB5CFFmNCQUTk7CwiLZ3woHIzlN7t1kzoa7WCi3uiyolKYzd6qlhRZHVIZHEccaiB50WCKeKE3aMJlZzd6qlhRZH3muoHIzlNgMJkDLmhxMZg0HwowNdVzOCcfZwonmNRTV2CCzo8MXFa5ekoN9J5aSdZbTFo5WxX5qpbbamhz3Fc6YnVF5vSQcXLgUrWMcHrR4gHnhabzJdKFiSTqaKjzDJnhHfxXlmlkrbUIJkR7UeeIGuKeKE3awIn6)sqicsrsKP4pamCbqLyJ(Vub9eeaWI5me2AmZIsWUvxB7HERiji9UbSq)gCO4fE3NyJ(lscsVBalqIz9xcMi11IY2d9wrsq6DdyH(n4qXl8UpXg9xSoKRGBeCKwtPajM1Fjy3DruGVqFdourPprS1X6A6jiaGfZziS1yMfLGDVl8UpXg9xqCPjXncgjecSajM1Fjy3kSt9e0RNtLrs5OckYCCKCClh09B5eaPfKCywPrqGSLZ9PALmNfs5W4sP)aYzTCo0kTCejhUIZwo3NQvYCcCa5W7(eB0VmNfs58TLtOy2Y5(uTsMdWomhYnfcMZcPC2Go0YX6C4R4CONGaaYwonmhjbP3nG54YC2Go0YX6C4ndLtOy2YPH5OsxjZXL5WBg)bKtOy2YPH5CT91MJlZH3m(diNqX5SFmhGDyoO9Zjh(koh6jiaG5i7(tqxU59lVIvvMdGGyX7HHnoq(HW2cbqMK1n2CewII3mbnoaslix4kEHzrjkWvCuzjYLkS9qVvKeKE3awOFdouSUwuX2kwhYvWncosRPuGeZ6VSUE5MdoHPNyCsIQiQFjiebPijYu8hagUaOsSr)xccrqkscsVBalXg9FPc6jiaGfZziS1yMfLGDRU22d9wrsq6DdyH(n4qXl8UpXg9xKeKE3awGeZ6VemrQRfLTh6TIKG07gWc9BWHIx4DFIn6VyDixb3i4iTMsbsmR)sWU7IOaFH(gCOIsFIyRJ110tqaalMZqyRXmlkb7Ex4DFIn6VG4stIBemsieybsmR)sWUvyN6jOl38(LxXQkUIJrVGtS5iSeLTh6TcIlnCJGnfcJwXncBoacwOFdou8IyibogapwUvmhabXI3dZfZziWyDxc6YnVF5vSQIVNdE5M3p(4sJTFziw8iwsq6DdiBoclBp0BfjbP3nGf63GdftqxU59lVIvv89CWl38(XhxAS9ldXIhXscHnhHLOS9qVvKeKE3awOFdoumb965C)75KJPq5iqq6Ddyol38(Z54slhhjhbcsVBaZXL5WdHq6TdWCcfNGUCZ7xEfRQ475GxU59JpU0y7xgILKG07gq2CewbHiifjbP3nGLqXjOxpN7FpNCmfkhbvYz5M3FohxA54i5ykeKYzHuoIKtdZ5qszo0tmojtqxU59lVIvv89CWl38(XhxAS9ldXsAS5iSwU5Gty6jgNKGDxc61Z5(3ZjhtHY5(6k7CwU59NZXLwoosoMcbPCwiLZD50WCyAiLd9eJtYe0LBE)YRyvfFph8YnVF8XLgB)YqS2MyZryTCZbNW0tmojrL1DjOjOxpN7JBE)YY91v254YC83OpsXCqAyoHskh0UPKZ1iXnNJVVyeF)hAbNYz)yo8qiKE7amNNOOmhRZjGYPfBoJZ(umbD5M3VSSnXcTIdp(dahHlG(XIdFUsc6YnVFzzB6kwvrpbb4SV)aW0XrPdzZryjkXqcCmaESCRyoacIfVhMlCfhmw3Uqpbbaem2Pwc6YnVFzzB6kwvH4stIBemsieiBocl6jiaGfZziS1yMfLOElbD5M3VSSnDfRQGU0Fayz4JbX5GWghi)qyBHaitY6gBocRkS9qVvqR4WJ)aWr4cOFS4WNRuOFdou8cV7tSr)fOl9hawg(yqCoiLyiCnVFu5DFIn6VGwXHh)bGJWfq)yXHpxPajM1F5v3t9lvW7(eB0FbXLMe3iyKqiWcKyw)LOExDnxXrLf7upbD5M3VSSnDfRQGHsf)bGrXBKWO9pYMJWkiebPadLk(daJI3iHr7FSeB0Fc6YnVFzzB6kwvjf7)7pamhUpHbX5GWMJWI3mbnwAqhe6sfvubxXr9U6AE3NyJ(liU0K4gbJecbwGeZ6Vev2J6xQGR4OYID118UpXg9xqCPjXncgjecSajM1FjQIOU6110tqaalMZqyRXmlkbJ1D11bHiiL4(Cc3iyUIJI9cKwUPEc6YnVFzzB6kwvbjWjOKWklKHnhHfxXlmlkrbUIJklrsqxU59llBtxXQkUIJdcHsJnhHfxXlmlkrbUIJkR7sqxU59llBtxXQkexA4gbBkegTIBe2CaeKnBHaid7iSy8x0gPGqeKcZcbb3iytHWC4(ubsmR)s2CewCfVWSOef4koQSUlbD5M3VSSnDfRQmhabXI3ddB2cbqg2ryX4VOnsbHiifMfccUrWMcH5W9PcKyw)LS5iS4kEHzrjkWvCuzjYLkeLTh6TIIByEZe0f63GdfRRffVzcACaKwqupbD5M3VSSnDfRQ4kog9coXMJWsu8MjOXbqAbjbD5M3VSSnDfRQqoa9hawsqX0ByqCoiS5iSccrqkbniyXWMxIn6Nn)nccdfBSULGUCZ7xw2MUIvvbNLdshAyqCoiSXbYpe2wiaYKSUXMJWI3mbnwAqhe6sfbHiiLGgeSyyZlHIRRRW2d9wrXnmVzc6c9BWHIxedjWXa4XYTI5aiiw8EyUWvCWUN6QNGMGE9CU)UpXg9ltqxU59ll8iwsiS8h8gecJYq6XMcHrR4gHnhabzZryfeIGuKeKE3awIn6VU2CgcBno6eyIWUe0LBE)YcpILeYvSQcq4cJ((4gbVSpbBtHnhHL5me2AC0juVv5SRUwuGVqFdourPprS1Xl8UpXg9xSoKRGBeCKwtPajM1FjySUDV6AZziS14OtGDh7sqxU59ll8iwsixXQk0n8ebN8hdjz)7Zj2Cew8UpXg9xSoKRGBeCKwtPajM1FjQSRYRR5DFIn6VyDixb3i4iTMsbsmR)sWePUg8f6BWHkk9jITowxBodHTghDcmrulb965uzKuo3hKVpLJknesVLJJKdWomNfs5W4sP)aYzTCo0kTCULZ9R45SFmh09lASC4R4CONGaaMdA3u8ph1kSlhjX7pktqxU59ll8iwsixXQQfY3NWwdH0BS5iS4kEHzrjkWvCuzD7c9eeaWI5me2AmZIsuzPwHDjOl38(LfEeljKRyvL1HCfCJGJ0AkS5iSef4l03Gdvu6teBD8sfIIe9qxSykw4a5N2G97CCWzLwDnV7tSr)foq(Pny)ohhCwPvGeZ6Vemw3u)sfCfh1B110tqaab7EQPEc6YnVFzHhXsc5kwvjTgYGPfAk49JyehsS5iS4DFIn6ViTgYGPfAk49JyehsfUYcbqswIuxhBRyDixb3i4iTMsbsmR)Y6AZziS14OtGjIA11veeIGuq3WteCYFmKK9VpNkqIz9xI6n1QR5DFIn6VGUHNi4K)yij7FFovGeZ6VevE3NyJ(lsRHmyAHMcE)igXHubj8CWqIRSqae2CgQUwuKuspNkOB4jco5pgsY(3NtfMff3q1VubV7tSr)fRd5k4gbhP1ukqIz9xIkV7tSr)fP1qgmTqtbVFeJ4qQGeEoyiXvwiacBodvxd(c9n4qfL(eXwhViks0dDXIPyjc9GGJ)aW(dI4oQ(fE3NyJ(liU0K4gbJecbwGeZ6Vemwv6fUIJkR7UW7(eB0FbTIdp(dahHlG(XIdFUsbsmR)sWyD7Ue0LBE)YcpILeYvSQk40De3iytHW0tmazZryX7(eB0FX6qUcUrWrAnLcKyw)LOEp2vxd(c9n4qfL(eXwhVW7(eB0FbXLMe3iyKqiWcKyw)LGjsDT5me2AC0jWUjsDT5me2AC0juVPMAxmNHWwJJob2TBQDPcE3NyJ(liU0K4gbJecbwGeZ6VeS7QR5DFIn6VGwXHh)bGJWfq)yXHpxPajM1FjySRUM39j2O)c0L(daldFmiohKcKyw)LGXo1tqxU59ll8iwsixXQkE)C6n4AueJCwgInhHLOITv49ZP3GRrrmYzziCqi8lqIz9xEPIk4DFIn6VW7NtVbxJIyKZYqfiXS(lbJfV7tSr)fRd5k4gbhP1ukqIz9xE1T6AWxOVbhQO0Ni26O6xQqu2EO3kOvC4XFa4iCb0pwC4Zvk0VbhkwxZ7(eB0FbTIdp(dahHlG(XIdFUsbsmR)s1VW7(eB0Fb6s)bGLHpgeNdsbsmR)Yl8UpXg9xqCPjXncgjecSajM1F5LGqeKI0AidMwOPG3pIrCivIn6VUo2wX6qUcUrWrAnLcKyw)LQxxBodHTghDcSkpb965uzKuovF6oMZ1gcbMJJKJkDixjNgjNkjTMIOrMdV7tSr)54YCaaP1iyoMY(5CNA5uHP4YC8NFcJKmh0k(HYrLUsMJlZHhcH0BhG5SCZbNuNTCAyoncso8UpXg9NdAf6ZbyhMZcPCu6t0Fa50V15OsxjzlNgMdAf6ZXuOCSfcGSCCzoBqhA5yDorNsqxU59ll8iwsixXQQGt3rmsieiBoclE3NyJ(lwhYvWncosRPuGeZ6Ve17uRUg8f6BWHkk9jITowxBodHTghDcmrulbD5M3VSWJyjHCfRQciOKGG4pa2Cew8UpXg9xSoKRGBeCKwtPajM1FjQ3PwDn4l03Gdvu6teBDSU2CgcBno6ey3yxc6YnVFzHhXsc5kwvDCakMeJIdJayO3sqxU59ll8iwsixXQkehsbNUJS5iS4DFIn6VyDixb3i4iTMsbsmR)suVtT6AWxOVbhQO0Ni26yDT5me2AC0jWUPwc6YnVFzHhXsc5kwvTpNKgCpy(EoS5iS4DFIn6VyDixb3i4iTMsbsmR)suVtT6AWxOVbhQO0Ni26yDT5me2AC0jWerTe0LBE)YcpILeYvSQkybGBeSbDoiYe0LBE)YcpILeYvSQkusy3ig2(LHyTsfW3NKy4Y(neZB4EyZryb(c9n4qfRJ4(XHscBq)bHSlvW7(eB0FX6qUcUrWrAnLcKyw)LOkYT6AWxOVbhQO0Ni26O6xQisbHiif4Y(neZB4EWrkiebPeB0FDDqicsrAnKbtl0uW7hXioKkqIz9xI6T7QRnNHWwJJoHc8UpXg9xSoKRGBeCKwtPajM1Fjy3tTl8UpXg9xSoKRGBeCKwtPajM1FjyIWU6AZziS14OtGjc7upbD5M3VSWJyjHCfRQcLe2nIHTFziwRub89jjgUSFdX8gUh2CewIc8f6BWHkwhX9JdLe2G(dczxQisbHiif4Y(neZB4EWrkiebPeB0FDDfIIe9qxSykwIqpi44paS)GiUJ112cbqwXCgcBnwm3W3PwbsmR)sWQC1VurSTI1HCfCJGJ0AkfiXS(lRR5DFIn6VyDixb3i4iTMsbsmR)YRQuunNHWwJJoP(LGqeKI0AidMwOPG3pIrCivcfxxBodHTghDcmryN6jOl38(LfEeljKRyvLPq4WpOd)igPHCkbD5M3VSWJyjHCfRQehcDeG(dahCwPLGE9CUg7tmNkbTI9hqox7zzizoinmhcLep0OCG7dGYPH5aIFo5eeIGizlhhjhXTu6bhQKZ9DqVaL5yqG5yDoailhtHY50OjPLdV7tSr)5eSskMt)5SGV(zdouo0tmojljOl38(LfEeljKRyvfKwX(daJCwgsYghi)qyBHaitY6gBoclBHaiRyodHTghDcSBf2vxxrf2cbqwrH2JPueZnuRC1QRTfcGSIcThtPiMBGXse1u)sfl3CWjm9eJtsw3QRTfcGSI5me2AC0jufPsvx966kSfcGSI5me2ASyUHfrnuVtTlvSCZbNW0tmojzDRU2wiaYkMZqyRXrNq9E3tD1tqxU59ll8iwsixXQkKMhkPiEzFc6gHdOLjbD5M3VSWJyjHCfRQyiMgce3i4ti3J4iKwgjBocl6jiaGGDp1sqxU59ll8iwsixXQkOlw8HW(JLIxoLGUCZ7xw4rSKqUIvvblaCJGnOZbrMGUCZ7xw4rSKqUIvvHsc7gXizZryvbj6HUyXuSWbYpTb7354GZkTl8UpXg9x4a5N2G97CCWzLwbsmR)sWyjIAQxxlks0dDXIPyHdKFAd2VZXbNvAjOjOxpN7V7tSr)Ye0LBE)YcpILeKE3aYYFWBqimkdPhBkegTIBe2CaeKnhHvqicsrsq6Ddyj2O)6AZziS14OtGjc7sqxU59ll8iwsq6Dd4vSQcq4cJ((4gbVSpbBtHnhHvqicsrsq6Ddyj2O)lvyodHTghDc1Bvo7QR5DFIn6Viji9UbSajM1FjySUMQxxBodHTghDcS7yxc6YnVFzHhXscsVBaVIvvbNUJyKqiq2Cew8UpXg9xKeKE3awGeZ6VevruRU2CgcBno6eyIOwc6YnVFzHhXscsVBaVIvvbeusqq8haBoclE3NyJ(lscsVBalqIz9xIQiQvxBodHTghDcSBSlb965uzKuo3hKVpLJknesVLJJKJabP3nG54YC(2YjumB5SFmhGDyolKYHXLs)bKZA5COvA5ClN7xXzlN9J5GUFrJLdFfNd9eeaWCq7MI)5OwHD5ijE)rzc6YnVFzHhXscsVBaVIvvlKVpHTgcP3yZryfeIGuKeKE3awIn6)cxXlmlkrbUIJkRBxONGaawmNHWwJzwuIkl1kSlbD5M3VSWJyjbP3nGxXQQJdqXKyuCyead9wc6YnVFzHhXscsVBaVIvvioKcoDhzZryX7(eB0Frsq6DdybsmR)sufrT6AZziS14OtGDtTe0LBE)YcpILeKE3aEfRQ2NtsdUhmFph2Cew8UpXg9xKeKE3awGeZ6VevruRU2CgcBno6eyIOwc6YnVFzHhXscsVBaVIvvblaCJGnOZbrMGUCZ7xw4rSKG07gWRyvL1HCfCJGJ0AkS5iSef4l03Gdvu6teBDmbD5M3VSWJyjbP3nGxXQQGt3rCJGnfctpXaKnhHvqicsrsq6Ddyj2O)lvW7(eB0Frsq6DdybsmR)sufrT6AE3NyJ(lscsVBalqIz9xcMiQxxBodHTghDcSBSlbD5M3VSWJyjbP3nGxXQQqjHDJyy7xgI1kvaFFsIHl73qmVH7HnhHvKccrqkWL9BiM3W9GJuqicsj2O)66GqeKIKG07gWcKyw)LOwP11MZqyRXrNate2LGUCZ7xw4rSKG07gWRyvf6gEIGt(JHKS)95eBocRGqeKIKG07gWsSr)xQG39j2O)IKG07gWcKyw)LOEJD118UpXg9xKeKE3awGeZ6VemruVU2CgcBno6eyIOwc6YnVFzHhXscsVBaVIvv8(50BW1Oig5SmeBocRGqeKIKG07gWsSr)xQG39j2O)IKG07gWcKyw)L118UpXg9x49ZP3GRrrmYzzOcxzHaijlru)IOITv49ZP3GRrrmYzziCqi8lqIz9xEPcE3NyJ(lqx6paSm8XG4CqkqIz9xEH39j2O)cIlnjUrWiHqGfiXS(lRRnNHWwJJobwLREc6YnVFzHhXscsVBaVIvvscsVBatqxU59ll8iwsq6Dd4vSQYuiC4h0HFeJ0qoXMJWkiebPiji9UbSeB0Fc6YnVFzHhXscsVBaVIvvIdHocq)bGdoR0yZryfeIGuKeKE3awIn6pb965Cn2NyovcAf7pGCU2ZYqYCqAyoekjEOr5a3haLtdZbe)CYjiebrYwoosoIBP0doujN77GEbkZXGaZX6CaqwoMcLZPrtslhE3NyJ(ZjyLumN(ZzbF9ZgCOCONyCswsqxU59ll8iwsq6Dd4vSQcsRy)bGroldjzJdKFiSTqaKjzDJnhHvqicsrsq6Ddyj2O)lvyleazfZziS14OtGDRWU66kQWwiaYkk0EmLIyUHALRwDTTqaKvuO9ykfXCdmwIOM6xQy5MdoHPNyCsY6wDTTqaKvmNHWwJJoHQivQ6QxxxHTqaKvmNHWwJfZnSiQH6DQDPILBo4eMEIXjjRB112cbqwXCgcBno6eQ37EQRU6jOl38(LfEelji9Ub8kwvH08qjfXl7tq3iCaTmS5iSccrqkscsVBalXg9NGUCZ7xw4rSKG07gWRyvfdX0qG4gbFc5EehH0YizZryfeIGuKeKE3awIn6)c9eeaqWUNAjOl38(LfEelji9Ub8kwvbDXIpe2FSu8Yj2CewbHiifjbP3nGLyJ(tqxU59ll8iwsq6Dd4vSQkybGBeSbDois2CewbHiifjbP3nGLyJ(tqxU59ll8iwsq6Dd4vSQkusy3igjBocRGqeKIKG07gWsSr)xQOcs0dDXIPyHdKFAd2VZXbNvAx4DFIn6VWbYpTb7354GZkTcKyw)LGXse1uVUwuKOh6IftXchi)0gSFNJdoR0upbnb965GIe6n0nG5GwXpuoscsVBaZXL5ekobD5M3VSiji9UbKfIlnjUrWiHqGS5iSccrqkscsVBalqIz9xc2T66LBo4eMEIXjjQ3sqxU59llscsVBaVIvvsX()(daZH7tyqCoiS5iS4ntqJLg0bHUuXYnhCctpX4KevrQRxU5Gty6jgNKOE7IO4DFIn6VaDP)aWYWhdIZbPekw9e0LBE)YIKG07gWRyvf0L(daldFmiohe24a5hcBleazsw3yZryXBMGglnOdcLGE9CurXL5G2pNC4R0Y5A7RnN9J54VrqyOylhtHYHRS)tNCCKCmfkh273FLmhxMdK2iWC2pMJSzitXFa5O4auiyo9NJPq5ig6n0nG5CCPLtfvcb2l1ZXL5SGV(zdoujbD5M3VSiji9Ub8kwvH4stIBemsieiB(Beegk2Wocla8ybsmR)swQLGUCZ7xwKeKE3aEfRQqCPHBeSPqy0kUryZbqq24a5hcBleazsw3yZryXvCWUlbD5M3VSiji9Ub8kwvbjWjOKWklKHnhHfxXlmlkrbUIJ6Tl0tqaalMZqyRXmlkb7wc61ZPYiPCQUzVylh3YbTFo50)byobqAbjhMvAeeyoosoxJULZ93mbDoUmhvrrSk5y7HEJIjOl38(LfjbP3nGxXQQGZYbPdnmiohe24a5hcBleazsw3yZryXBMGglnOdcvxlkBp0Bff3W8MjOl0VbhkMGUCZ7xwKeKE3aEfRQKI9)9haMd3NWG4CqsqtqxU59llsJfAfhE8haocxa9Jfh(CLe0LBE)YI0UIvviU0K4gbJecbYMJWY2d9wrsq6DdyH(n4qX6AE3NyJ(lwhYvWncosRPuGeZ6Vev2tDn4l03Gdvu6teBDmb965uzKuovcb2RC6phBHaitMdA3u6qlhuewii50i5ykuo3pCFkNifeIGWwoosoIBP0doeB5SFmhhjhv6kzoUmN1Y5qR0YrKCKeV)OmNf9cmbD5M3VSiTRyvf0L(daldFmiohe24a5hcBleazsw3yZryX7(eB0FX6qUcUrWrAnLcKyw)LOksDn4l03Gdvu6teBDmbD5M3VSiTRyvfmuQ4pamkEJegT)r2CewbHiifyOuXFayu8gjmA)JLyJ(VSCZbNW0tmojr9wc6YnVFzrAxXQkibobLewzHmS5iS4kEHzrjkWvCuVLGUCZ7xwK2vSQcXLgUrWMcHrR4gHnhabzJdKFiSTqaKjzDJnhHfxXb7Ue0LBE)YI0UIvv0tqao77pamDCu6q2CewCfhmw3DHEccaiyStTe0RNtLrs5C)vNJJKdWomNfs5W0qkhtz)CulN7xXZzrVaZbb2m5WSOmN9J5OSGt5Clh6jgGSLtdZzHuomnKYXu2pNB5C)kEol6fyoiWMjhMfLjOl38(LfPDfRQ4kooiekn2CewCfVWSOef4koQQDz5MdoHPNyCsY6wDnxXlmlkrbUIJ6Te0RNtLrs5OckYCCKCa2H5SqkN7LtdZHPHuoCfpNf9cmheyZKdZIYC2pMJkDLmN9J5iuzFT5SqkNG2uY5BlNqXjOl38(LfPDfRQmhabXI3ddBCG8dHTfcGmjRBS5iS4ntqJLg0bHUWv8cZIsuGR4OE3frfBRyDixb3i4iTMsbsmR)YlbHiifP1qgmTqtbVFeJ4qQeB0Fc6YnVFzrAxXQkUIJrVGtjOl38(LfPDfRQKI9)9haMd3NWG4CqyZryXBMGglnOdcDjiebPe3Nt4gbZvCuSxG0YTe0RNtLrs5uDZELJJKtqBk5CT91MZ(XCQecSx5SqkNVTC4NwsSLtdZPsiWELJlZHFAjLZ(XCU2(AZXL58TLd)0skN9J5aSdZrzbNYHPHuoMY(5isoCfNTCAyoxBFT54YC4Nws5ujeyVYXL58TLd)0skN9J5aSdZrzbNYHPHuoMY(5CxoCfNTCAyoa7WCuwWPCyAiLJPSFoSlhUIZwonmhhjhGDyoailNnhXWMNGUCZ7xwK2vSQk4SCq6qddIZbHnoq(HW2cbqMK1n2Cew8MjOXsd6GqxQOcE3NyJ(lwhYvWncosRPuGeZ6VevrQRbFH(gCOIsFIyRJQFPcE3NyJ(lqx6paSm8XG4CqkqIz9xIQix4DFIn6VG4stIBemsieybsmR)sufPUM39j2O)c0L(daldFmiohKcKyw)LGD3fE3NyJ(liU0K4gbJecbwGeZ6Ve17UWvCufPUM39j2O)c0L(daldFmiohKcKyw)LOE3fE3NyJ(liU0K4gbJecbwGeZ6VeS7UWvCuVxDnxXrLDQxxheIGucAqWIHnVekw9e0LBE)YI0UIvvMdGGyX7HHnoq(HW2cbqMK1n2Cew8MjOXsd6Gqx4kEHzrjkWvCuVLGE9CQmskNRvG9kN9J54VrqyOylh3YrAW1bOy5SOxGjOl38(LfPDfRQqoa9hawsqX0ByqCoiS5VrqyOyJ1Te0RNtLrs5uDZELJJKZ12xBoUmh(PLuo7hZbyhMJYcoLJi5Wv8C2pMdWoeMZzLwoaoDWEYb9kZrfuKSLtdZXrYbyhMZcPC2Go0YX6C4R4CONGaaMZ(XCi3uiyoa7qyoNvA5aGhZb9kZrfuK50WCCKCa2H5SqkNdjL5yk7NJi5Wv8Cw0lWCqGnto8vSy)bKGUCZ7xwK2vSQk4SCq6qddIZbHnoq(HW2cbqMK1n2CewvW7(eB0FbXLMe3iyKqiWcKyw)LGD3fUIZsK6A6jiaGfZziS1yMfLGDt9lvigsGJbWJLBfZbqqS49WuxZv8cZIsuGR4GjI6AtBAn]] )

end