-- RogueSubtlety.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ] 

local class = Hekili.Class
local state =  Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'ROGUE' then
    local spec = Hekili:NewSpecialization( 261 )

    spec:RegisterResource( Enum.PowerType.Energy, {
        shadow_techniques = {
            last = function () return state.query_time end,
            interval = function () return state.time_to_sht[5] end,
            value = 8,
            stop = function () return state.time_to_sht[5] == 0 or state.time_to_sht[5] == 3600 end,
        }, 
    } )
    spec:RegisterResource( Enum.PowerType.ComboPoints, {
        shadow_techniques = {
            last = function () return state.query_time end,
            interval = function () return state.time_to_sht[5] end,
            value = 1,
            stop = function () return state.time_to_sht[5] == 0 or state.time_to_sht[5] == 3600 end,
        },

        shuriken_tornado = {
            aura = "shuriken_tornado",
            last = function ()
                local app = state.buff.shuriken_tornado.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            stop = function( x ) return state.buff.shuriken_tornado.remains == 0 end,

            interval = 0.95,
            value = function () return state.active_enemies + ( state.buff.shadow_blades.up and 1 or 0 ) end,
        },
    } )

    -- Talents
    spec:RegisterTalents( {
        weaponmaster = 19233, -- 193537
        find_weakness = 19234, -- 91023
        gloomblade = 19235, -- 200758

        nightstalker = 22331, -- 14062
        subterfuge = 22332, -- 108208
        shadow_focus = 22333, -- 108209

        vigor = 19239, -- 14983
        deeper_stratagem = 19240, -- 193531
        marked_for_death = 19241, -- 137619

        soothing_darkness = 22128, -- 200759
        cheat_death = 22122, -- 31230
        elusiveness = 22123, -- 79008

        shot_in_the_dark = 23078, -- 257505
        night_terrors = 23036, -- 277953
        prey_on_the_weak = 22115, -- 131511

        dark_shadow = 22335, -- 245687
        alacrity = 19249, -- 193539
        enveloping_shadows = 22336, -- 238104

        master_of_shadows = 22132, -- 196976
        secret_technique = 23183, -- 280719
        shuriken_tornado = 21188, -- 277925
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3460, -- 196029
        gladiators_medallion = 3457, -- 208683
        adaptation = 3454, -- 214027

        smoke_bomb = 1209, -- 212182
        shadowy_duel = 153, -- 207736
        silhouette = 856, -- 197899
        maneuverability = 3447, -- 197000
        veil_of_midnight = 136, -- 198952
        dagger_in_the_dark = 846, -- 198675
        thiefs_bargain = 146, -- 212081
        phantom_assassin = 143, -- 216883
        shiv = 3450, -- 248744
        cold_blood = 140, -- 213981
        death_from_above = 3462, -- 269513
        honor_among_thieves = 3452, -- 198032
    } )

    -- Auras
    spec:RegisterAuras( {
    	alacrity = {
            id = 193538,
            duration = 20,
            max_stack = 5,
        },
        cheap_shot = {
            id = 1833,
            duration = 1,
            max_stack = 1,
        },
        cloak_of_shadows = {
            id = 31224,
            duration = 5,
            max_stack = 1,
        },
        death_from_above = {
            id = 152150,
            duration = 1,
        },
        crimson_vial = {
            id = 185311,
        },
        deepening_shadows = {
            id = 185314,
        },
        evasion = {
            id = 5277,
        },
        feeding_frenzy = {
            id = 242705,
            duration = 30,
            max_stack = 3,
        },
        feint = {
            id = 1966,
            duration = 5,
            max_stack = 1,
        },
        find_weakness = {
            id = 91021,
            duration = 10,
            max_stack = 1,
        },
        fleet_footed = {
            id = 31209,
        },
        marked_for_death = {
            id = 137619,
            duration = 60,
            max_stack = 1,
        },
        master_of_shadows = {
            id = 196980,
            duration = 3,
            max_stack = 1,
        },
        nightblade = {
            id = 195452,
            duration = function () return talent.deeper_stratagem.enabled and 18 or 16 end,
            tick_time = function () return 2 * haste end,
            max_stack = 1,
        },
        prey_on_the_weak = {
            id = 255909,
            duration = 6,
            max_stack = 1,
        },
        relentless_strikes = {
            id = 58423,
        },
        shadow_blades = {
            id = 121471,
            duration = 20,
            max_stack = 1,
        },
        shadow_dance = {
            id = 185422,
            duration = function () return talent.subterfuge.enabled and 6 or 5 end,
            max_stack = 1,
        },
        shadow_gestures = {
            id = 257945,
            duration = 15
        },
        shadows_grasp = {
            id = 206760,
            duration = 8.001,
            type = "Magic",
            max_stack = 1,
        },
        shadow_techniques = {
            id = 196912,
        },
        shadowstep = {
            id = 36554,
            duration = 2,
            max_stack = 1,
        },
        shroud_of_concealment = {
            id = 114018,
            duration = 15,
            max_stack = 1,
        },
        shuriken_tornado = {
            id = 277925,
            duration = 4,
            max_stack = 1,
        },
        stealth = {
            id = function () return talent.subterfuge.enabled and 115191 or 1784 end,
            duration = 3600,
            max_stack = 1,
            copy = { 115191, 1784 }
        },
        subterfuge = {
            id = 115192,
            duration = 3,
            max_stack = 1,
        },
        symbols_of_death = {
            id = 212283,
            duration = 10,
            max_stack = 1,
        },
        vanish = {
            id = 11327,
            duration = 3,
            max_stack = 1,
        },

        -- Azerite Powers
        blade_in_the_shadows = {
            id = 279754,
            duration = 60,
            max_stack = 10,
        },

        nights_vengeance = {
            id = 273424,
            duration = 8,
            max_stack = 1,
        },

        perforate = {
            id = 277720,
            duration = 12,
            max_stack = 1
        },

        replicating_shadows = {
            id = 286131,
            duration = 1,
            max_stack = 50
        },

        the_first_dance = {
            id = 278981,
            duration = function () return buff.shadow_dance.duration end,
            max_stack = 1,
        },

    } )


    local true_stealth_change = 0
    local emu_stealth_change = 0

    spec:RegisterEvent( "UPDATE_STEALTH", function ()
        true_stealth_change = GetTime()
    end )

    spec:RegisterStateTable( "stealthed", setmetatable( {}, {
        __index = function( t, k )
            if k == "rogue" then
                return buff.stealth.up or buff.vanish.up or buff.shadow_dance.up or buff.subterfuge.up
            elseif k == "mantle" then
                return buff.stealth.up or buff.vanish.up
            elseif k == "all" then
                return buff.stealth.up or buff.vanish.up or buff.shadow_dance.up or buff.subterfuge.up or buff.shadowmeld.up
            end

            return false
        end
    } ) )


    local last_mh = 0
    local last_oh = 0
    local last_shadow_techniques = 0
    local swings_since_sht = 0

    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function()
        local event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount, interrupt, a, b, c, d, offhand, multistrike = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID then
            if subtype == "SPELL_ENERGIZE" and spellID == 196911 then
                last_shadow_techniques = GetTime()
                swings_since_sht = 0
            end

            if subtype:sub( 1, 5 ) == 'SWING' and not multistrike then
                if subtype == 'SWING_MISSED' then
                    offhand = spellName
                end

                local now = GetTime()

                if now > last_shadow_techniques + 3 then
                    swings_since_sht = swings_since_sht + 1
                end

                if offhand then last_mh = GetTime()
                else last_mh = GetTime() end
            end
        end
    end )


    local sht = {}

    spec:RegisterStateTable( "time_to_sht", setmetatable( {}, {
        __index = function( t, k )
            local n = tonumber( k )
            n = n - ( n % 1 )

            if not n or n > 5 then return 3600 end

            if n <= swings_since_sht then return 0 end

            local mh_speed = swings.mainhand_speed
            local mh_next = ( swings.mainhand > now - 3 ) and ( swings.mainhand + mh_speed ) or now + ( mh_speed * 0.5 )

            local oh_speed = swings.offhand_speed               
            local oh_next = ( swings.offhand > now - 3 ) and ( swings.offhand + oh_speed ) or now

            table.wipe( sht )

            sht[1] = mh_next + ( 1 * mh_speed )
            sht[2] = mh_next + ( 2 * mh_speed )
            sht[3] = mh_next + ( 3 * mh_speed )
            sht[4] = mh_next + ( 4 * mh_speed )
            sht[5] = oh_next + ( 1 * oh_speed )
            sht[6] = oh_next + ( 2 * oh_speed )
            sht[7] = oh_next + ( 3 * oh_speed )
            sht[8] = oh_next + ( 4 * oh_speed )


            local i = 1

            while( sht[i] ) do
                if sht[i] < last_shadow_techniques + 3 then
                    table.remove( sht, i )
                else
                    i = i + 1
                end
            end

            if #sht > 0 and n - swings_since_sht < #sht then
                table.sort( sht )
                return max( 0, sht[ n - swings_since_sht ] - query_time )
            else
                return 3600
            end
        end
    } ) )


    spec:RegisterStateExpr( "bleeds", function ()
        return ( debuff.garrote.up and 1 or 0 ) + ( debuff.rupture.up and 1 or 0 )
    end )


    spec:RegisterStateExpr( "cp_max_spend", function ()
        return combo_points.max
    end )

    -- Legendary from Legion, shows up in APL still.
    spec:RegisterGear( "cinidaria_the_symbiote", 133976 )
    spec:RegisterGear( "denial_of_the_halfgiants", 137100 )

    local function comboSpender( amt, resource )
        if resource == 'combo_points' then
            if amt > 0 then
                gain( 6 * amt, "energy" )
            end

            if level < 116 and amt > 0 and equipped.denial_of_the_halfgiants then
                if buff.shadow_blades.up then
                    buff.shadow_blades.expires = buff.shadow_blades.expires + 0.2 * amt
                end
            end

            if talent.alacrity.enabled and amt >= 5 then
                addStack( "alacrity", 20, 1 )
            end

            if talent.secret_technique.enabled then
                cooldown.secret_technique.expires = max( 0, cooldown.secret_technique.expires - amt )
            end

            cooldown.shadow_blades.expires = max( 0, cooldown.shadow_blades.expires - ( amt * 1.5 ) )

            if level < 116 and amt > 0 and set_bonus.tier21_2pc > 0 then
                if cooldown.symbols_of_death.remains > 0 then
                    cooldown.symbols_of_death.expires = cooldown.symbols_of_death.expires - ( 0.2 * amt )
                end
            end
        end
    end

    spec:RegisterHook( 'spend', comboSpender )
    -- spec:RegisterHook( 'spendResources', comboSpender )


    spec:RegisterStateExpr( "mantle_duration", function ()
        if level > 115 then return 0 end

        if stealthed.mantle then return cooldown.global_cooldown.remains + 5
        elseif buff.master_assassins_initiative.up then return buff.master_assassins_initiative.remains end
        return 0
    end )


    spec:RegisterStateExpr( "priority_rotation", function ()
        return false
    end )


    -- We need to break stealth when we start combat from an ability.
    spec:RegisterHook( "runHandler", function( ability )
        local a = class.abilities[ ability ]

        if stealthed.mantle and ( not a or a.startsCombat ) then
            if level < 116 and stealthed.mantle and equipped.mantle_of_the_master_assassin then
                applyBuff( "master_assassins_initiative", 5 )
                -- revisit for subterfuge?
            end

            if talent.subterfuge.enabled and stealthed.mantle then
                applyBuff( "subterfuge" )
            end

            if buff.stealth.up then 
                setCooldown( "stealth", 2 )
            end
            removeBuff( "stealth" )
            removeBuff( "vanish" )
            removeBuff( "shadowmeld" )
        end
    end )


    spec:RegisterGear( "insignia_of_ravenholdt", 137049 )
    spec:RegisterGear( "mantle_of_the_master_assassin", 144236 )
        spec:RegisterAura( "master_assassins_initiative", {
            id = 235027,
            duration = 5
        } )

        spec:RegisterStateExpr( "mantle_duration", function()
            if stealthed.mantle then return cooldown.global_cooldown.remains + buff.master_assassins_initiative.duration
            elseif buff.master_assassins_initiative.up then return buff.master_assassins_initiative.remains end
            return 0
        end )


    spec:RegisterGear( "shadow_satyrs_walk", 137032 )
        spec:RegisterStateExpr( "ssw_refund_offset", function()
            return target.distance
        end )

    spec:RegisterGear( "soul_of_the_shadowblade", 150936 )
    spec:RegisterGear( "the_dreadlords_deceit", 137021 )
        spec:RegisterAura( "the_dreadlords_deceit", {
            id = 228224, 
            duration = 3600,
            max_stack = 20,
            copy = 208693
        } )

    spec:RegisterGear( "the_first_of_the_dead", 151818 )
        spec:RegisterAura( "the_first_of_the_dead", {
            id = 248210, 
            duration = 2 
        } )

    spec:RegisterGear( "will_of_valeera", 137069 )
        spec:RegisterAura( "will_of_valeera", {
            id = 208403, 
            duration = 5 
        } )

    -- Tier Sets
    spec:RegisterGear( "tier21", 152163, 152165, 152161, 152160, 152162, 152164 )
    spec:RegisterGear( "tier20", 147172, 147174, 147170, 147169, 147171, 147173 )
    spec:RegisterGear( "tier19", 138332, 138338, 138371, 138326, 138329, 138335 )


    -- Abilities
    spec:RegisterAbilities( {
        backstab = {
            id = 53,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 132090,

            notalent = "gloomblade",

            handler = function ()
                applyDebuff( 'target', "shadows_grasp", 8 )
                if azerite.perforate.enabled and buff.perforate.up then
                    -- We'll assume we're attacking from behind if we've already put up Perforate once.
                    addStack( "perforate", nil, 1 )
                    gainChargeTime( "shadow_blades", 0.5 )
                end
            	gain( buff.shadow_blades.up and 2 or 1, 'combo_points')
            end,
        },


        blind = {
            id = 2094,
            cast = 0,
            cooldown = function () return 120 - ( talent.blinding_powder.enabled and 30 or 0 ) end,
            gcd = "spell",

            startsCombat = true,
            texture = 136175,

            handler = function ()
              applyDebuff( 'target', 'blind', 60)
            end,
        },


        cheap_shot = {
            id = 1833,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () 
                if buff.shot_in_the_dark.up then return 0 end
                return 40 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 132092,

            cycle = function ()
                if talent.prey_on_the_weak.enabled then return "prey_on_the_weak" end
            end,

            usable = function ()
                if boss then return false, "cheap_shot assumed unusable in boss fights" end
                return stealthed.all or buff.subterfuge.up, "not stealthed"
            end,

            handler = function ()
            	if talent.find_weakness.enabled then
            		applyDebuff( 'target', 'find_weakness' )
            	end
            	if talent.prey_on_the_weak.enabled then
                    applyDebuff( 'target', 'prey_on_the_weak' )
                end
                if talent.subterfuge.enabled then
                	applyBuff( 'subterfuge' )
                end

                applyDebuff( 'target', 'cheap_shot' )
                removeBuff( "shot_in_the_dark" )

                gain( 2 + ( buff.shadow_blades.up and 1 or 0 ), "combo_points" )
            end,
        },


        cloak_of_shadows = {
            id = 31224,
            cast = 0,
            cooldown = 120,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136177,

            handler = function ()
                applyBuff( 'cloak_of_shadows', 5 )
            end,
        },


        crimson_vial = {
            id = 185311,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            toggle = "cooldowns",

            spend = function () return 30 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 1373904,

            handler = function ()
                applyBuff( 'crimson_vial', 6 )
            end,
        },


        distract = {
            id = 1725,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = function () return 30 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 132289,

            handler = function ()
            end,
        },


        evasion = {
            id = 5277,
            cast = 0,
            cooldown = 120,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136205,

            handler = function ()
            	applyBuff( 'evasion', 10 )
            end,
        },


        eviscerate = {
            id = 196819,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 132292,

            usable = function () return combo_points.current > 0 end,
            handler = function ()
            	if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end
                removeBuff( "nights_vengeance" )
                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" )
            end,
        },


        feint = {
            id = 1966,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 132294,

            handler = function ()
                applyBuff( 'feint', 5 )
            end,
        },


        gloomblade = {
            id = 200758,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            talent = 'gloomblade',

            startsCombat = true,
            texture = 1035040,

            handler = function ()
            applyDebuff( 'target', "shadows_grasp", 8 )
            	if buff.stealth.up then
            		removeBuff( "stealth" )
            	end
            	gain( buff.shadow_blades.up and 2 or 1, 'combo_points' )
            end,
        },


        kick = {
            id = 1766,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            toggle = 'interrupts', 
            interrupt = true,

            startsCombat = true,
            texture = 132219,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        kidney_shot = {
            id = 408,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = function () return 25 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 132298,

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end
                local combo = min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current )
                applyBuff( "kidney_shot", 2 + 1 * ( combo - 1 ) )

                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" )
            end,
        },


        marked_for_death = {
            id = 137619,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            talent = 'marked_for_death', 

            toggle = "cooldowns",

            startsCombat = false,
            texture = 236364,

            usable = function ()
                return settings.mfd_waste or combo_points.current == 0, "combo_point (" .. combo_points.current .. ") waste not allowed"
            end,

            handler = function ()
                gain( 5, 'combo_points')
                applyDebuff( 'target', 'marked_for_death', 60 )
            end,
        },


        nightblade = {
            id = 195452,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 25 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            cycle = "nightblade",

            startsCombat = true,
            texture = 1373907,

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end
                local combo = min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current )

                if azerite.nights_vengeance.enabled then applyBuff( "nights_vengeance" ) end

                applyDebuff( "target", "nightblade", 8 + 2 * ( combo - 1 ) )
                spend( combo, "combo_points" )
            end,
        },


        pick_lock = {
            id = 1804,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 136058,

            handler = function ()
            end,
        },


        pick_pocket = {
            id = 921,
            cast = 0,
            cooldown = 0.5,
            gcd = "spell",

            startsCombat = false,
            texture = 133644,

            handler = function ()
            end,
        },


        sap = {
            id = 6770,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 132310,

            handler = function ()
                applyDebuff( 'target', 'sap', 60 )
            end,
        },


        secret_technique = {
            id = 280719,
            cast = 0,
            cooldown = function () return 45 - min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ) end,
            gcd = "spell",

            spend = function () return 30 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 132305,

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then addStack( "alacrity", 20, 1 ) end                
                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" )
            end,
        },


        shadow_blades = {
            id = 121471,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 376022,

            handler = function ()
            	applyBuff( 'shadow_blades', 20 )
            end,
        },


        shadow_dance = {
            id = 185313,
            cast = 0,
            charges = 2,
            cooldown = 60,
            recharge = 60,
            gcd = "off",

            startsCombat = false,
            texture = 236279,

            nobuff = "shadow_dance",

            ready = function () return max( energy.time_to_max, buff.shadow_dance.remains ) end,

            usable = function () return not stealthed.all end,
            handler = function ()
                applyBuff( "shadow_dance" )
                if talent.shot_in_the_dark.enabled then applyBuff( "shot_in_the_dark" ) end
                if talent.master_of_shadows.enabled then applyBuff( "master_of_shadows", 3 ) end
                if azerite.the_first_dance.enabled then
                    gain( 2, "combo_points" )
                    applyBuff( "the_first_dance" )
                end
            end,
        },


        shadowstep = {
            id = 36554,
            cast = 0,
            charges = 2,
            cooldown = 30,
            recharge = 30,
            gcd = "off",

            startsCombat = false,
            texture = 132303,

            handler = function ()
            	applyBuff( "shadowstep", 2 )
            end,
        },


        shadowstrike = {
            id = 185438,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return ( azerite.blade_in_the_shadows.enabled and 38 or 40 ) * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            cycle = function () return talent.find_weakness.enabled and "find_weakness" or nil end,

            startsCombat = true,
            texture = 1373912,

            usable = function () return stealthed.all end,
            handler = function ()
                gain( buff.shadow_blades.up and 3 or 2, 'combo_points' )
                if azerite.blade_in_the_shadows.enabled then addStack( "blade_in_the_shadows", nil, 1 ) end

                if talent.find_weakness.enabled then
                    applyDebuff( "target", "find_weakness" )
                end
            end,
        },


        shroud_of_concealment = {
            id = 114018,
            cast = 0,
            cooldown = 360,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 635350,

            handler = function ()
                applyBuff( 'shroud_of_concealment', 15 )
            end,
        },


        shuriken_storm = {
            id = 197835,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 1375677,

            handler = function ()
            	gain( active_enemies + ( buff.shadow_blades.up and 1 or 0 ), 'combo_points')
            end,
        },


        shuriken_tornado = {
            id = 277925,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = function () return 60 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            toggle = "cooldowns",

            talent = 'shuriken_tornado',

            startsCombat = true,
            texture = 236282,

            handler = function ()
             	applyBuff( 'shuriken_tornado', 4 )
            end,
        },


        shuriken_toss = {
            id = 114014,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 40 * ( ( talent.shadow_focus.enabled and ( buff.shadow_dance.up or buff.stealth.up ) ) and 0.8 or 1 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 135431,

            handler = function ()
                gain( active_enemies + ( buff.shadow_blades.up and 1 or 0 ), "combo_points" )
            end,
        },


        sprint = {
            id = 2983,
            cast = 0,
            cooldown = 120,
            gcd = "off",

            startsCombat = false,
            texture = 132307,

            handler = function ()
                applyBuff( 'sprint', 8 )
            end,
        },


        stealth = {
            id = function () return talent.subterfuge.enabled and 115191 or 1784 end,
            known = 1784,
            cast = 0,
            cooldown = 2,
            gcd = "off",

            startsCombat = false,
            texture = 132320,

            usable = function () return time == 0 and not buff.stealth.up and not buff.vanish.up end,            
            readyTime = function () return buff.shadow_dance.remains end,
            handler = function ()
                applyBuff( 'stealth' )
                if talent.shot_in_the_dark.enabled then applyBuff( "shot_in_the_dark" ) end

                emu_stealth_change = query_time
            end,

            copy = { 1784, 115191 }
        },


        symbols_of_death = {
            id = 212283,
            cast = 0,
            charges = 1,
            cooldown = 30,
            recharge = 30,
            gcd = "off",

            startsCombat = false,
            texture = 252272,

            handler = function ()
                gain ( 40, 'energy')
                applyBuff( "symbols_of_death" )
            end,
        },


        tricks_of_the_trade = {
            id = 57934,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 236283,

            handler = function ()
                applyBuff( 'tricks_of_the_trade' )
            end,
        },


        vanish = {
            id = 1856,
            cast = 0,
            cooldown = 120,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 132331,

            disabled = function ()
                return not ( boss and group )
            end,

            handler = function ()
                applyBuff( 'vanish', 3 )
                applyBuff( "stealth" )
                emu_stealth_change = query_time
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
    } )


    -- Override this for rechecking.
    spec:RegisterAbility( "shadowmeld", {
        id = 58984,
        cast = 0,
        cooldown = 120,
        gcd = "off",

        usable = function () return boss and group end,
        handler = function ()
            applyBuff( "shadowmeld" )
        end,
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "potion_of_unbridled_fury",

        package = "Subtlety",
    } )


    spec:RegisterSetting( "mfd_waste", true, {
        name = "Allow |T236364:0|t Marked for Death Combo Waste",
        desc = "If unchecked, the addon will not recommend |T236364:0|t Marked for Death if it will waste combo points.",
        type = "toggle",
        width = "full"
    } )  


    spec:RegisterPack( "Subtlety", 20200525, [[daLHRbqiqspcKQnjk9jqIWOus1PusAvGe6vOkMfQk3cvPSlj(LOsddKYXGsTmrHNHQktturxdvvTnLe5BkjOXjQGohir16usunpLq3dk2hfL)bsePdQKalujLhIQunrLaxuuHQnIQK8rrfkgjiruNeKiTsLsVuuHsZevjvDtqIYoPO6NOkPYqbjyPIkWtHQPkk6QIkKTQKq9vLeLZcseXEf5VuAWsDyHfdPhlPjt4YiBgIpdIrdQtRy1OkP8ALOzt0TPWUb(TkdxP64kjKLJYZv10jDDuz7qjFNImEuL48IQwVsqZxPy)uDc7uMjCrOuY8mGwgqdA8pd(xWg7mYiNyNW187ucFpQldiucheguchNdvLKMpHVh5LxiszMW)JJvPeoSQ7)kp3CHmkmhAPEg5(JbNm05avwGO5(Jrn3eok3ivOuqcnHlcLsMNb0YaAqJ)zW)c2yNrg8BfMWdof(yjC8XG3t4WJqqGeAcxqFnHdDVX5qvjP59ohCq4iFl09gw19FLNBUqgfMdTupJC)XGtg6CGklq0C)XOMRVf6EdLf59od(ZN3zaTmGMV13cDV5D4aaH(vUVf6EZBEVcecs4Do2PU0B98wqibNu9oQ6CaVLZRfFl09M38ohqghwKWBnyqi1oiExpGy05aEFaVHYc2ss4nYX8EbuOWfFl09M38EfieKW7C0tEdLQKXxs4Y51pLzc)vkKkmjszMmh7uMjCceOssKwlHxzJsSjs4R7TgscOfKbiSMOyjG(VqGavscV3SX7FNKsRgmiK(LhMJnljG91Jz49IEZpVx17SEVU3OCiiLxPqQWfUDV3SXBuoeKcwbyE4c3U3RMWJQohiH)WH4m9kBwsjnzEgPmt4eiqLKiTwcVYgLytKWr5qqkpmhBwsaREmqiUc3U3z9UEgOND)gG(fbHm1r9ErmENrcpQ6CGeEnKsBu15aw58AcxoVAbHbLWrgW8Wjnzo)szMWjqGkjrATeELnkXMiH)7KuA1GbH0V8WCSzjbSVEmdVX4Do9oR31Za9S73a03BZW4Dot4rvNdKWRHuAJQohWkNxt4Y5vlimOeoYaMhoPjZZzkZeobcujjsRLWRSrj2ej86zGE29Ba6xeeYuh17fX4n2EZBEVU3AijGweeTtm7RSqdiKrHabQKeEN1719gLdbPGvaMhUWT79MnEhlKyJsffMSid7vRiavQqGavscVZ69VtsPvdges)YdZXMLeW(6Xm8ErV5N3z9gLdbPagiW6BXIaqOauPc3U3R69Qj8OQZbs41qkTrvNdyLZRjC58QfeguchzaZdN0K58pLzcNabQKeP1s4v2OeBIeESqInkv2jgYXcLkSaS0BZW4DgEN17FNKsRgmiK(LhMJnljG91Jz49Iy8oJeEu15ajCiY7mqLHGsAY8vkLzcNabQKeP1s4rvNdKWF4qCMELnlPeELnkXMiHRHKaA5PkJuRsvyWSI4Ocbcujj8oR3AijGwqgGWAIILa6)cbcujj8oR3ccLdbPGmaH1eflb0)fgzed49ErVX27SE)7KuA1GbH0V8WCSzjbSVEmdVX4DgEN1BDmiREwXqEZBEZiJyaV3M59kLWR5RsYQbdcPFYCStAY8vykZeobcujjsRLWRSrj2ejCO6TgscOfbr7eZ(kl0aczuiqGkjH3z9owiXgLkOYqq2byvyY(WH4m9fwaw6ngV5N3z9(3jP0QbdcPF5H5yZscyF9ygEJXB(LWJQohiH)WH4m9kBwsjnzEomLzcNabQKeP1s4v2OeBIeowbBcujv4EYUZMJnAEl70qNd4DwVx3BnKeqlidqynrXsa9FHabQKeEN1BbHYHGuqgGWAIILa6)cJmIb8EVO3y79MnERHKaAXef7hWiELyfceOss4DwV)DskTAWGq6xEyo2SKa2xpMH3lIX7C69MnEhlKyJsLbqynAGoYrZxiqGkjH3z9gLdbP85nqp5BpeRGcfUWT7DwV)DskTAWGq6xEyo2SKa2xpMH3lIXB(5npEhlKyJsfuzii7aSkmzF4qCM(cbcujj8E1eEu15aj8hoeNPxzZskPjZHYtzMWjqGkjrATeELnkXMiH)7KuA1GbH03BZW4n)s4rvNdKWFyo2SKa2xpMrstMJn0szMWJQohiH)WH4m9kBwsjCceOssKwlPjnHt)tGk9PmtMJDkZeobcujjsRLWRSrj2ejCcqmi5l6yqw9SgbV4TzEJT3z9gQEJYHGu(8gON8ThIvqHcx429oR3R7nu9wCAPEGkbuwOKWIiddYIYXafDQlhaeVZ6nu9oQ6CGs9avcOSqjHfrgguzawe5abw9EZgVr4KslJQWbdcz1XG8ErVHuffJGx8E1eEu15aj86bQeqzHsclImmOKMmpJuMjCceOssKwlHxzJsSjs4q176DsXzcuE4qCMSOYqqFHB37SExVtkotGYN3a9KV9qScku4c3U3B24TogKvpRyiVxeJ3ydTeEu15ajCu5Dc7HyvyYsaYiFstMZVuMj8OQZbs4q4cMycG9qSXcj2PWjCceOssKwlPjZZzkZeobcujjsRLWRSrj2ej819(3jP0QbdcPF5H5yZscyF9ygEBggVZW7nB8MfJWsyraTecXxgG3M59kbnVx17SEdvVR3jfNjq5ZBGEY3EiwbfkCHB37SEdvVr5qqkFEd0t(2dXkOqHlC7EN1Bcqmi5lcczQJ6Tzy8MFqlHhvDoqch5QCpjSXcj2OKfLcJKMmN)Pmt4eiqLKiTwcVYgLytKW)DskTAWGq6xEyo2SKa2xpMH3MHX7m8EZgVzXiSeweqlHq8Lb4TzEVsqlHhvDoqcFNJni5haelQmEnPjZxPuMjCceOssKwlHxzJsSjs4OCiifgvxkP)TihRsfUDV3SXBuoeKcJQlL0)wKJvjB94akXkVg1LEVO3ydTeEu15ajCfMSCa0JdiSihRsjnz(kmLzcpQ6CGeoB23LKDa2FpQucNabQKeP1sAY8CykZeobcujjsRLWRSrj2ej86DsXzcu(8gON8ThIvqHcxyKrmG37f9M)EVzJ36yqw9SIH8ErVXohMWJQohiHB6ysbw0aSm6pqaQustMdLNYmHtGavsI0Aj8kBuInrcNaedsEVx07CcnVZ6nkhcs5ZBGEY3EiwbfkCHBpHhvDoqc3GmowE7HyLC1ryfmkm(KMmhBOLYmHtGavsI0Aj8OQZbs4mk2haelImmOpHxzJsSjs4AWGqArhdYQNvmK3l6n2f(79MnEVU3R7TgmiKwGPqQWL9Q6TzENdHM3B24TgmiKwGPqQWL9Q69Iy8odO59QEN1719oQ6Gfzjazm07ngVX27nB8wdgesl6yqw9SIH82mVZak37v9EvV3SX719wdgesl6yqw9S7v1Mb082mV5h08oR3R7Du1blYsaYyO3BmEJT3B24TgmiKw0XGS6zfd5TzENZC69QEVAcVMVkjRgmiK(jZXoPjnHliKGtQPmtMJDkZeobcujjsRLWRSrj2ejCO69RuivysuyheokHhvDoqcF5uxM0K5zKYmHhvDoqc)vkKkCcNabQKeP1sAYC(LYmHtGavsI0Aj8OQZbs41qkTrvNdyLZRjC58QfegucVk(KMmpNPmt4eiqLKiTwcVYgLytKWFLcPctIsiLj8OQZbs4moGnQ6CaRCEnHlNxTGWGs4VsHuHjrstMZ)uMjCceOssKwlHxzJsSjs46yqw9SIH82mVxjVZ6nJmIb8EVO3qQIIrWlEN176zGE29Ba67Tzy8oNEZBEVU36yqEVO3ydnVx1BOO3zKWJQohiHdgiWkQmeustMVsPmt4eiqLKiTwc)2t4pPj8OQZbs4yfSjqLuchRqYrj8D2CSrZBzNg6CaVZ69VtsPvdges)YdZXMLeW(6Xm82mmENrchRGzbHbLW5EYUZMJnAEl70qNdK0K5RWuMjCceOssKwlHxzJsSjs4yfSjqLuH7j7oBo2O5TStdDoqcpQ6CGeEnKsBu15aw58AcxoVAbHbLWFLcPcBRIpPjZZHPmt4eiqLKiTwc)2t4pPj8OQZbs4yfSjqLuchRqYrj8m4V384TgscOfSgihRqGavscVHIEZp(7npERHKaAXiELy2dX(WH4m9fceOss4nu07m4V384TgscOLhoeNjlYv5(cbcujj8gk6DgqZBE8wdjb0siJkB08fceOss4nu0BSHM384n283BOO3R79VtsPvdges)YdZXMLeW(6Xm82mmEZpVxnHJvWSGWGs4VsHuHTkmJE4tksAYCO8uMjCceOssKwlHxzJsSjs4eGyqYxeeYuh17fX4nwbBcujvELcPcBvyg9WNuKWJQohiHxdP0gvDoGvoVMWLZRwqyqj8xPqQW2Q4tAYCSHwkZeobcujjsRLWRSrj2ej8yHeBuQagiW6BXIaqOauPcbcujj8oR3q1BuoeKcyGaRVflcaHcqLkC7EN176zGE29Ba6xeeYuh1BZ8gBVZ696E)7KuA1GbH0V8WCSzjbSVEmdVx07m8EZgVXkytGkPc3t2D2CSrZBzNg6CaVx17SEVU317KIZeO85nqp5BpeRGcfUWiJyaV3lIXB(59MnEVU3Xcj2OubmqG13IfbGqbOsfwaw6Tzy8odVZ6nkhcs5ZBGEY3EiwbfkCHrgXaEVnZB(5DwVHQ3VsHuHjrjKsVZ6D9oP4mbkpCiotwraQuPchmi0BryrvNdesVndJ3qRaL79QEVAcpQ6CGeoyGaROYqqjnzo2yNYmHtGavsI0Aj8kBuInrcVEgOND)gG(fbHm1r9ErmEJT3B24TogKvpRyiVxeJ3y7DwVRNb6z3VbOV3MHXB(LWJQohiHxdP0gvDoGvoVMWLZRwqyqjCKbmpCstMJDgPmt4eiqLKiTwcVYgLytKW)DskTAWGq6xEyo2SKa2xpMH3y8oNEN176zGE29Ba67Tzy8oNj8OQZbs41qkTrvNdyLZRjC58QfeguchzaZdN0K5yZVuMjCceOssKwlHxzJsSjs4eGyqYxeeYuh17fX4nwbBcujvELcPcBvyg9WNuKWJQohiHxdP0gvDoGvoVMWLZRwqyqjCuUrksAYCSZzkZeobcujjsRLWRSrj2ejCcqmi5lcczQJ6Tzy8gB(7npEtaIbjFHrqiqcpQ6CGeEWQbGS6XyeqtAYCS5FkZeEu15aj8Gvdaz35KpLWjqGkjrATKMmh7vkLzcpQ6CGeUCGaRVLxJtaXGaAcNabQKeP1sAYCSxHPmt4rvNdKWrdi2dXQSPU8t4eiqLKiTwstAcFNr1Zan0uMjZXoLzcpQ6CGe(Ruiv4eobcujjsRL0K5zKYmHtGavsI0Aj8OQZbs4gbBjjSihZkOqHt47mQEgOHAFQEaXNWXM)jnzo)szMWjqGkjrATeoimOeESWhoyXBroGApe7(zIyj8OQZbs4XcF4GfVf5aQ9qS7NjIL0K55mLzcpQ6CGe((PZbs4eiqLKiTwstAchLBKIuMjZXoLzcNabQKeP1s4v2OeBIe(VtsPvdgesFVndJ3z4npEVU3AijGwGiVZavgcQqGavscVZ6DSqInkv2jgYXcLkSaS0BZW4DgEVAcpQ6CGe(dZXMLeW(6XmsAY8mszMWJQohiHdrENbQmeucNabQKeP1sAYC(LYmHhvDoqchnQlFnqt4eiqLKiTwstAcVk(uMjZXoLzcNabQKeP1s4v2OeBIeou9gLdbP8WH4mzfbOsfUDVZ6nkhcs5H5yZscy1JbcXv429oR3OCiiLhMJnljGvpgiexHrgXaEVxeJ38RW)eEu15aj8hoeNjRiavkHZ9K9qqSqQIK5yN0K5zKYmHtGavsI0Aj8kBuInrchLdbP8WCSzjbS6XaH4kC7EN1BuoeKYdZXMLeWQhdeIRWiJyaV3lIXB(v4FcpQ6CGe(N3a9KV9qScku4eo3t2dbXcPksMJDstMZVuMjCceOssKwlHxzJsSjs4q17xPqQWKOesP3z9wCAbmqGvuziOIo1LdaI3B24n9pbQubLrHcBpeRctwr(baPye8AhZ7SERJb5Tzy8oJeEu15aj8AiL2OQZbSY51eUCE1ccdkHt)tGk9jnzEotzMWjqGkjrATeEu15aj897Kwg9hhRsj8kBuInrchQERHKaA5HdXzYICvUVqGavsIeoYXSaIx0K5yN0K58pLzcNabQKeP1s4v2OeBIeobigK8EBggVxjO5DwVfNwadeyfvgcQOtD5aG4DwVR3jfNjq5ZBGEY3EiwbfkCHB37SExVtkotGYdhIZKveGkvQWbdc9EBggVXoHhvDoqc)H5yZscy1JbcXL0K5RukZeobcujjsRLWRSrj2ejCXPfWabwrLHGk6uxoaiEN1BO6D9oP4mbkpCiotwuziOVWT7DwVx3BO6TgscOLhMJnljGvpgiexHabQKeEVzJ3AijGwE4qCMSixL7leiqLKW7nB8UENuCMaLhMJnljGvpgiexHrgXaEVnZ7m8EvVZ696EdvVP)jqLkOY7e2dXQWKLaKr(IrWRDmV3SX76DsXzcuqL3jShIvHjlbiJ8fgzed492mVZW7v9oR3R7DSqInkvadey9TyraiuaQuHfGLEVO3z49MnEJYHGuadey9TyraiuaQuHB37vt4rvNdKW)8gON8ThIvqHcN0K5RWuMjCceOssKwlHhvDoqc3iyljHf5ywbfkCcVYgLytKWzXiSeweqlHq8fUDVZ696ERbdcPfDmiREwXqEVO31Za9S73a0ViiKPoQ3B24nu9(vkKkmjkHu6DwVRNb6z3VbOFrqitDuVndJ31DRrWl2FNacVxnHxZxLKvdges)K5yN0K55WuMjCceOssKwlHxzJsSjs4SyewclcOLqi(Ya82mV5h08M38MfJWsyraTecXxeCSqNd4DwVHQ3VsHuHjrjKsVZ6D9mqp7(na9lcczQJ6Tzy8UUBncEX(7eqKWJQohiHBeSLKWICmRGcfoPjZHYtzMWjqGkjrATeELnkXMiHdvVFLcPctIsiLEN1BXPfWabwrLHGk6uxoaiEN176zGE29Ba6xeeYuh1BZW4Dgj8OQZbs4pCiotwuziOpPjZXgAPmt4eiqLKiTwcVYgLytKW1qsaT8WH4mzrUk3xiqGkjH3z9wCAbmqGvuziOIo1LdaI3z9gLdbP85nqp5BpeRGcfUWTNWJQohiH)WCSzjbS6XaH4sAYCSXoLzcNabQKeP1s4v2OeBIeou9gLdbP8WH4mzfbOsfUDVZ6TogKvpRyiVxeJ383BE8wdjb0YZHQedHdcviqGkjH3z9gQEZIryjSiGwcH4lC7j8OQZbs4pCiotwraQustMJDgPmt4eiqLKiTwcVYgLytKWr5qqkOY7esUxlmkQQ3B24nkhcs5ZBGEY3EiwbfkCHB37SEVU3OCiiLhoeNjlQme0x429EZgVR3jfNjq5HdXzYIkdb9fgzed49ErmEJn08E1eEu15aj89tNdK0K5yZVuMjCceOssKwlHxzJsSjs4OCiiLpVb6jF7HyfuOWfU9eEu15ajCu5DclchlFstMJDotzMWjqGkjrATeELnkXMiHJYHGu(8gON8ThIvqHcx42t4rvNdKWrj2tSLdasstMJn)tzMWjqGkjrATeELnkXMiHJYHGu(8gON8ThIvqHcx42t4rvNdKWrggHkVtK0K5yVsPmt4eiqLKiTwcVYgLytKWr5qqkFEd0t(2dXkOqHlC7j8OQZbs4bOsVYcPTgszstMJ9kmLzcNabQKeP1s4rvNdKWR5RYtzhyQwuz8AcVYgLytKWHQ3VsHuHjrjKsVZ6T40cyGaROYqqfDQlhaeVZ6nu9gLdbP85nqp5BpeRGcfUWT7DwVjaXGKViiKPoQ3MHXB(bTeoHGqv1ccdkHxZxLNYoWuTOY41KMmh7CykZeobcujjsRLWJQohiHhl8Hdw8wKdO2dXUFMiwcVYgLytKWHQ3OCiiLhoeNjRiavQWT7DwVR3jfNjq5ZBGEY3EiwbfkCHrgXaEVx0BSHwchegucpw4dhS4TihqThID)mrSKMmhBO8uMjCceOssKwlHhvDoqcpEySca9wwSWJzRhlKj8kBuInrcxqOCiifwSWJzRhlKwbHYHGueNjG3B24TGq5qqk1di4Q6GfzhWsRGq5qqkC7EN1BnyqiTOJbz1ZUxvl)GM3l6n)9EZgVHQ3ccLdbPupGGRQdwKDalTccLdbPWT7DwVx3BbHYHGuyXcpMTESqAfekhcs51OU0BZW4Dg83BEZBSHM3qrVfekhcsbvENWEiwfMSeGmYx429EZgV1XGS6zfd59IENtO59QEN1BuoeKYN3a9KV9qScku4cJmIb8EBM35WeoimOeE8Wyfa6TSyHhZwpwitAY8mGwkZeobcujjsRLWbHbLWnYlI3QHCEJaKWJQohiHBKxeVvd58gbiPjZZa7uMjCceOssKwlHxzJsSjs4OCiiLpVb6jF7HyfuOWfUDV3SXBDmiREwXqEVO3zaTeEu15ajCUNSJsgFstAc)vkKkSTk(uMjZXoLzcNabQKeP1s43Ec)jnHhvDoqchRGnbQKs4yfsokHxVtkotGYdhIZKveGkvQWbdc9wewu15aH0BZW4n2Lvi)t4yfmlimOe(dlSkmJE4tksAY8mszMWjqGkjrATeELnkXMiHdvVXkytGkPYdlSkmJE4tk8oR31Za9S73a0ViiKPoQ3M5n2EN1BbHYHGuqgGWAIILa6)cJmIb8EVO3y7DwVR3jfNjq5ZBGEY3EiwbfkCHrgXaEVndJ38lHhvDoqchRampCstMZVuMjCceOssKwlHhvDoqcF)oPLr)XXQucN4fLf2W44aAcpNqlHJCmlG4fnzo2jnzEotzMWjqGkjrATeELnkXMiHtaIbjV3MHX7CcnVZ6nbigK8fbHm1r92mmEJn08oR3q1BSc2eOsQ8WcRcZOh(KcVZ6D9mqp7(na9lcczQJ6TzEJT3z9wqOCiifKbiSMOyjG(VWiJyaV3l6n2j8OQZbs4pCiotgKuK0K58pLzcNabQKeP1s43Ec)jnHhvDoqchRGnbQKs4yfsokHxpd0ZUFdq)IGqM6OEBggVZP38M3R7TgscOfbr7eZ(kl0aczuiqGkjH3z9EDVJfsSrPIctwKH9QveGkviqGkjH3z9gQERHKaAreSL2hoeNPcbcujj8oR3q1BnKeqlphQsmeoiuHabQKeEN17FNKsRgmiK(LhMJnljG91Jz49IEZpVx17vt4yfmlimOe(dlS1Za9S73a0pPjZxPuMjCceOssKwlHF7j8N0eEu15ajCSc2eOskHJvi5OeE9mqp7(na9lcczQJ69Iy8gBV5X7m8gk6DSqInkvuyYImSxTIauPcbcujjs4v2OeBIeowbBcujv4EYUZMJnAEl70qNd4DwVx3BnKeqlGbcS(AixsScbcujj8EZgV1qsaTic2s7dhIZuHabQKeEVAchRGzbHbLWFyHTEgOND)gG(jnz(kmLzcNabQKeP1s4v2OeBIeowbBcujvEyHTEgOND)gG(EN1719gQERHKaAreSL2hoeNPcbcujj8EZgVfNwadeyfvgcQWiJyaV3MHXB(7npERHKaA55qvIHWbHkeiqLKW7v9oR3R7nwbBcujvEyHvHz0dFsH3B24nkhcs5ZBGEY3EiwbfkCHrgXaEVndJ3yxYW7nB8(3jP0QbdcPF5H5yZscyF9ygEBggVZP3z9UENuCMaLpVb6jF7HyfuOWfgzed492mVXgAEVQ3z9EDVJfsSrPcyGaRVflcaHcqLkSaS07f9odV3SXBuoeKcyGaRVflcaHcqLkC7EVAcpQ6CGe(dhIZKveGkL0K55WuMjCceOssKwlHxzJsSjs4yfSjqLu5Hf26zGE29Ba67DwV1XGS6zfd59IExVtkotGYN3a9KV9qScku4cJmIb8EN1BO6nlgHLWIaAjeIVWTNWJQohiH)WH4mzfbOsjnPjCKbmpCkZK5yNYmHtGavsI0AjCKJzbeVOjZXoHhvDoqcF)oPLr)XXQustMNrkZeobcujjsRLWRSrj2ejCuoeKcyGaRVflcaHcqLkC7EN1719(3jP0QbdcPF5H5yZscyF9ygEVO3z49MnEJvWMavsfUNS7S5yJM3Yon05aEVzJ3q1BnKeqlpvzKAvQcdMvehviqGkjH3B24nu9UENuCMaLNQmsTkvHbZkIJkC7EVAcpQ6CGeoH18vIfkL0K58lLzcNabQKeP1s4v2OeBIe(6EdvV1qsaTic2s7dhIZuHabQKeEVzJ3q1BuoeKYdhIZKveGkv429EvVZ6TogKvpRyiV5nVzKrmG3BZ8EL8oR3mYigW79IERtDPvhdYBOO3zKWJQohiHdgiWkQmeustMNZuMjCceOssKwlHhvDoqchmqGvuziOeELnkXMiHdvVXkytGkPc3t2D2CSrZBzNg6CaVZ69VtsPvdges)YdZXMLeW(6Xm82mmENH3z9EDVJfsSrPcyGaRVflcaHcqLkeiqLKW7nB8gQEhlKyJsfgTlNAOdaI9HdXz6leiqLKW7nB8(3jP0QbdcPF5H5yZscyF9ygEZBEhvDWISItlGbcSIkdb5Tzy8odVx17SEdvVr5qqkpCiotwraQuHB37SERJbz1ZkgYBZW496EZFV5X719odVHIExpd0ZUFdqFVx17v9oR3mcHrpCGkPeEnFvswnyqi9tMJDstMZ)uMjCceOssKwlHxzJsSjs4mYigW79IExVtkotGYN3a9KV9qScku4cJmIb8EZJ3ydnVZ6D9oP4mbkFEd0t(2dXkOqHlmYigW79Iy8M)EN1BDmiREwXqEZBEZiJyaV3M5D9oP4mbkFEd0t(2dXkOqHlmYigW7npEZ)eEu15ajCWabwrLHGsAY8vkLzcpQ6CGe(tvgPwLQWGzfXrjCceOssKwlPjZxHPmt4rvNdKWjSMVsSqPeobcujjsRL0KM0eowe7NdKmpdOLb0Gg)XoNjCtbdmaiFchk1y)ykj8oh6Du15aElNx)IVnHVZoKrsjCO7nohQkjnV35Gdch5BHU3WQU)R8CZfYOWCOL6zK7pgCYqNduzbIM7pg1C9Tq3BOSiV3zWF(8odOLb08T(wO7nVdhai0VY9Tq3BEZ7vGqqcVZXo1LERN3ccj4KQ3rvNd4TCET4BHU38M35aY4WIeERbdcP2bX76beJohW7d4nuwWwscVroM3lGcfU4BHU38M3RaHGeENJEYBOuLm(IV13cDVZX5fQYPKWBuc5yK31ZanuVrjid4lEVcQvAxFVbhG3GdMbcN07OQZbEVpGmFX3cDVJQoh4l7mQEgOHIbrg)sFl09oQ6CGVSZO6zGgkpyYn4Gyqan05a(wO7Du15aFzNr1ZanuEWKlYDcFl09ghe7p8PEZIr4nkhccj8(1qFVrjKJrExpd0q9gLGmG37ai8ENr82(P6aG498Eloav8Tq37OQZb(YoJQNbAO8Gj3he7p8P2xd99TrvNd8LDgvpd0q5btUVsHuH9TrvNd8LDgvpd0q5btUgbBjjSihZkOqH5BNr1Zanu7t1diEmyZFFBu15aFzNr1ZanuEWKl3t2rjd(aHbHjw4dhS4TihqThID)mrmFBu15aFzNr1ZanuEWK7(PZb8T(wO7DooVqvoLeEtyrS8ERJb5TctEhv9yEpV3bwXidujv8Tq37Ca9kfsf27bX797)bvsEVo48glojGybQK8MaKXqV3dW76zGg6Q(2OQZbEmlN6s(gemq9vkKkmjkSdch5BJQoh45btUVsHuH9Tq3BEhMQl9M3xW7DOEJmSx9TrvNd88Gj3AiL2OQZbSY5v(aHbHPkEFl09ohWb8gHtkZ79BA0km9ERN3km5nUsHuHjH35GtdDoG3RJM3BXnaiE)hFEpQ3ihRsV373jhaeVheVbNcpaiEpV3bwXidujTAX3gvDoWZdMCzCaBu15aw58kFGWGW8kfsfMe8niyELcPctIsiL(wO79kyFxM3BZhiWkQmeK3H6Dg84nVdf8wWXgaeVvyYBKH9Q3ydnVFQEaXZN3bIsmVv4q9oN84nVdf8Eq8EuVjEzFy07TPrHhG3km5nG4f17Cm8(c8(yEpV3Gt9MB33gvDoWZdMCbdeyfvgcIVbbJogKvpRyiZwPSmYigWViKQOye8s26zGE29Ba6BgMCYBRRJbTi2qBvOyg(wO7nVoGmV3v4aaH8MDAOZb8Eq82e5nCGf59oBo2O5TStdDoG3pPEhaH3gCsD2LK3AWGq67n3EX3gvDoWZdMCXkytGkj(aHbHH7j7oBo2O5TStdDoaFyfsocZoBo2O5TStdDoq2FNKsRgmiK(LhMJnljG91JzygMm8Tq3BOaBo2O59ohCAOZbGsQ386jfkX7nKblY7W7kl29oqpo1Bcqmi59g5yERWK3VsHuH9M3xW796OCJuqmVFDKsVz0Vtv17rxT4nus425Z7r9UgaVrjVv4q9(hJDjv8TrvNd88Gj3AiL2OQZbSY5v(aHbH5vkKkSTkE(gemyfSjqLuH7j7oBo2O5TStdDoGVf6ENJEs4TEEliKbqEBcMaERN3Cp59RuivyV59f8EFmVr5gPGyVVnQ6CGNhm5IvWMavs8bcdcZRuivyRcZOh(Kc(WkKCeMm4ppAijGwWAGCScbcujjGI8J)8OHKaAXiELy2dX(WH4m9fceOssafZG)8OHKaA5HdXzYICvUVqGavscOygqJhnKeqlHmQSrZxiqGkjbueBOXd28hkU(VtsPvdges)YdZXMLeW(6Xmmdd)w13cDV59d8JGyEZ9daI3H34kfsf2BEFbEBcMaEZOOcpaiERWK3eGyqY7TcZOh(KcFBu15appyYTgsPnQ6CaRCELpqyqyELcPcBRINVbbdbigK8fbHm1rxedwbBcujvELcPcBvyg9WNu4BHU3MpqGvOeV3RycaHcqLw5EB(abwrLHG8gLqog5nEEd0t(EhQ3YZK38ouWB98UEgOdG8McMmV3mcHrpS3Mgf2BiKQdaI3km5nkhcI3C7fVxbY)8wEM8M3HcEl4ydaI345nqp57nkPMic49ccqLEVnnkS3zWJ3MVIl(2OQZbEEWKlyGaROYqq8niyIfsSrPcyGaRVflcaHcqLkeiqLKilur5qqkGbcS(wSiaekavQWTNTEgOND)gG(fbHm1rnd7SR)7KuA1GbH0V8WCSzjbSVEmJfZyZgSc2eOsQW9KDNnhB08w2PHohy1SRxVtkotGYN3a9KV9qScku4cJmIb8lIHFB2SESqInkvadey9TyraiuaQuHfGLMHjJSOCiiLpVb6jF7HyfuOWfgzed4nJFzH6RuivysucPmB9oP4mbkpCiotwraQuPchmi0BryrvNdesZWaTcu(QR6BHU38QbmpS3H6Do5XBtJcFCQ3laNpV5ppEBAuyVxaU3RFC6pcY7xPqQWR6BJQoh45btU1qkTrvNdyLZR8bcdcdYaMhMVbbt9mqp7(na9lcczQJUigS3SrhdYQNvm0IyWoB9mqp7(na9ndd)8Tq37v2OWEVaCVd5FEJmG5H9ouVZjpEhqIb8Q3eVevvM37C6TgmiK(EV(XP)iiVFLcPcVQVnQ6CGNhm5wdP0gvDoGvoVYhimimidyEy(gem)ojLwnyqi9lpmhBwsa7RhZatoZwpd0ZUFdqFZWKtFl09oh9K3H3OCJuqmVnbtaVzuuHhaeVvyYBcqmi59wHz0dFsHVnQ6CGNhm5wdP0gvDoGvoVYhimimOCJuW3GGHaeds(IGqM6OlIbRGnbQKkVsHuHTkmJE4tk8Tq3BE9Nj6vV3zZXgnV3dW7qk9(q8wHjVxbqbE9EJs1G7jVh17AW907D4DogEFb(2OQZbEEWKBWQbGS6Xyeq5BqWqaIbjFrqitDuZWGn)5Haeds(cJGqaFBu15appyYny1aq2Do5t(2OQZbEEWKRCGaRVLxJtaXGaQVnQ6CGNhm5IgqShIvztD57B9Tq3714gPGyVVnQ6CGVGYnsbMhMJnljG91JzW3GG53jP0QbdcPVzyYGN11qsaTarENbQmeuHabQKezJfsSrPYoXqowOuHfGLMHjJv9TrvNd8fuUrk4btUqK3zGkdb5BJQoh4lOCJuWdMCrJ6YxduFRVf6EZ73jfNjW7BHU35ON8EbbOsEFii8gKQWBuc5yK3km5nYWE1BCyo2SKaEJRhZWBe2z4DMhdeIZ76zqV3dO4BJQoh4lvXJ5HdXzYkcqL4J7j7HGyHufyWMVbbdur5qqkpCiotwraQuHBplkhcs5H5yZscy1JbcXv42ZIYHGuEyo2SKaw9yGqCfgzed4xed)k833cDVxphbK0)EhsgfI8EZT7nkvdUN82e5TE3sVXHdXzYBE1v5(v9M7jVXZBGEY37dbH3GufEJsihJ8wHjVrg2REJdZXMLeWBC9ygEJWodVZ8yGqCExpd69EafFBu15aFPkEEWK7N3a9KV9qSckuy(4EYEiiwivbgS5BqWGYHGuEyo2SKaw9yGqCfU9SOCiiLhMJnljGvpgiexHrgXa(fXWVc)9TrvNd8LQ45btU1qkTrvNdyLZR8bcdcd9pbQ0Z3GGbQVsHuHjrjKYSItlGbcSIkdbv0PUCaq2SH(NavQGYOqHThIvHjRi)aGumcETJLvhdYmmz4BHU3qH7KEJCmVZ8yGqCEVZiEd)wG3Mgf2BC4f4nJcrEVnbtaVbN6nJdagaeVX5vfFBu15aFPkEEWK7(DslJ(JJvj(qoMfq8IIbB(gemqvdjb0YdhIZKf5QCFHabQKe(wO7Do6jVZ8yGqCEVZiVXVf4Tjyc4TjYB4alYBfM8MaedsEVnbtkmX8gHDgEVFNCaq820OWhN6noVY7J5nVg3REdHaelKY8fFBu15aFPkEEWK7dZXMLeWQhdeIJVbbdbigK8MHzLGwwXPfWabwrLHGk6uxoaizR3jfNjq5ZBGEY3EiwbfkCHBpB9oP4mbkpCiotwraQuPchmi0BggS9Tq37C0tEJN3a9KV3hW76DsXzc496bIsmVrg2REB(abwrLHGw1BoGK(3BtK3bJ8gYnaiERN373U3zEmqioVdGWBX5n4uVHdSiVXHdXzYBE1v5(IVnQ6CGVufppyY9ZBGEY3EiwbfkmFdcgXPfWabwrLHGk6uxoaizHA9oP4mbkpCiotwuziOVWTNDDOQHKaA5H5yZscy1JbcXviqGkjXMnAijGwE4qCMSixL7leiqLKyZM6DsXzcuEyo2SKaw9yGqCfgzed4nlJvZUouP)jqLkOY7e2dXQWKLaKr(IrWRDSnBQ3jfNjqbvENWEiwfMSeGmYxyKrmG3Smwn76Xcj2OubmqG13IfbGqbOsfwawUygB2GYHGuadey9TyraiuaQuHBFvFl09gkfX7qiEVdg5n3oFE)GzN8wHjVpa5TPrH9wEMOx9oZmxqX7C0tEBcMaElYpaiEJeVsmVv4a4nVdf8wqitDuVpM3Gt9(vkKkmj820OWhN6DaY7nVdfk(2OQZb(sv88GjxJGTKewKJzfuOW8vZxLKvdgesFmyZ3GGHfJWsyraTecXx42ZUUgmiKw0XGS6zfdTy9mqp7(na9lcczQJUzduFLcPctIsiLzRNb6z3VbOFrqitDuZWu3TgbVy)Dciw13cDVHsr8gCEhcX7TPrk9wmK3MgfEaERWK3aIxuV5h0E(8M7jVHYqwG3hWB07FVnnk8XPEhG8EZ7qbVdGWBW59Ruiv4IVnQ6CGVufppyY1iyljHf5ywbfkmFdcgwmclHfb0sieFzaMXpOXBSyewclcOLqi(IGJf6CGSq9vkKkmjkHuMTEgOND)gG(fbHm1rndtD3Ae8I93jGW3gvDoWxQINhm5(WH4mzrLHGE(gemq9vkKkmjkHuMvCAbmqGvuziOIo1Ldas26zGE29Ba6xeeYuh1mmz4BHU3RSrH9gNxXN3dI3Gt9oKmke59wCaIpV5EY7mpgieN3Mgf2B8BbEZTx8TrvNd8LQ45btUpmhBwsaREmqio(gemAijGwE4qCMSixL7leiqLKiR40cyGaROYqqfDQlhaKSOCiiLpVb6jF7HyfuOWfUDFBu15aFPkEEWK7dhIZKveGkX3GGbQOCiiLhoeNjRiavQWTNvhdYQNvm0Iy4ppAijGwEouLyiCqOcbcujjYcvwmclHfb0sieFHB33gvDoWxQINhm5UF6Ca(gemOCiifu5Dcj3RfgfvDZguoeKYN3a9KV9qScku4c3E21r5qqkpCiotwuziOVWTVzt9oP4mbkpCiotwuziOVWiJya)IyWgAR6BJQoh4lvXZdMCrL3jSiCS88niyq5qqkFEd0t(2dXkOqHlC7(2OQZb(sv88GjxuI9eB5aGW3GGbLdbP85nqp5BpeRGcfUWT7BJQoh4lvXZdMCrggHkVtW3GGbLdbP85nqp5BpeRGcfUWT7BJQoh4lvXZdMCdqLELfsBnKs(gemOCiiLpVb6jF7HyfuOWfUDFBu15aFPkEEWKl3t2rjd(ieeQQwqyqyQ5RYtzhyQwuz8kFdcgO(kfsfMeLqkZkoTagiWkQmeurN6Ybajlur5qqkFEd0t(2dXkOqHlC7zjaXGKViiKPoQzy4h08TrvNd8LQ45btUCpzhLm4degeMyHpCWI3ICa1Ei29ZeX4BqWavuoeKYdhIZKveGkv42ZwVtkotGYN3a9KV9qScku4cJmIb8lIn08Tq37vmXY7n74GalZ7nJtsEFiERWCgOdYqcVncf(9gLKNPvU35ON8g5yEdLcwUFcVRSr5Z7tHjMP5jVnnkS343c8ouVZG)849RrD579X8gB(ZJ3Mgf27q(N3RjVt4n3EX3gvDoWxQINhm5Y9KDuYGpqyqyIhgRaqVLfl8y26XcjFdcgbHYHGuyXcpMTESqAfekhcsrCMaB2iiuoeKs9acUQoyr2bS0kiuoeKc3EwnyqiTOJbz1ZUxvl)G2I8FZgOkiuoeKs9acUQoyr2bS0kiuoeKc3E21fekhcsHfl8y26XcPvqOCiiLxJ6sZWKb)5nSHguuqOCiifu5Dc7HyvyYsaYiFHBFZgDmiREwXqlMtOTAwuoeKYN3a9KV9qScku4cJmIb8MLd9TrvNd8LQ45btUCpzhLm4degegJ8I4TAiN3ia(wO79ciKGtQEJesjAux6nYX8M7duj59OKXVY9oh9K3Mgf2B88gON89(q8EbuOWfFBu15aFPkEEWKl3t2rjJNVbbdkhcs5ZBGEY3EiwbfkCHBFZgDmiREwXqlMb08T(wO7Do()eOsVVnQ6CGVq)tGk9yQhOsaLfkjSiYWG4BqWqaIbjFrhdYQN1i4fZWolur5qqkFEd0t(2dXkOqHlC7zxhQItl1dujGYcLewezyqwuogOOtD5aGKfQrvNduQhOsaLfkjSiYWGkdWIihiW6MniCsPLrv4GbHS6yqlcPkkgbVSQVnQ6CGVq)tGk98Gjxu5Dc7HyvyYsaYipFdcgOwVtkotGYdhIZKfvgc6lC7zR3jfNjq5ZBGEY3EiwbfkCHBFZgDmiREwXqlIbBO5BJQoh4l0)eOsppyYfcxWetaShInwiXof23gvDoWxO)jqLEEWKlYv5EsyJfsSrjlkfg8niyw)3jP0QbdcPF5H5yZscyF9ygMHjJnByXiSeweqlHq8Lby2kbTvZc16DsXzcu(8gON8ThIvqHcx42ZcvuoeKYN3a9KV9qScku4c3Ewcqmi5lcczQJAgg(bnFBu15aFH(Nav65btU7CSbj)aGyrLXR8niy(DskTAWGq6xEyo2SKa2xpMHzyYyZgwmclHfb0sieFzaMTsqZ3gvDoWxO)jqLEEWKRctwoa6XbewKJvj(gemOCiifgvxkP)TihRsfU9nBq5qqkmQUus)BrowLS1JdOeR8AuxUi2qZ3gvDoWxO)jqLEEWKlB23LKDa2FpQKVnQ6CGVq)tGk98GjxthtkWIgGLr)bcqL4BqWuVtkotGYN3a9KV9qScku4cJmIb8lY)nB0XGS6zfdTi25qFBu15aFH(Nav65btUgKXXYBpeRKRocRGrHXZ3GGHaeds(fZj0YIYHGu(8gON8ThIvqHcx429Tq3BOKpPW7Caf7daI38kzyqV3ihZBIxOkNsEZcaeY7J59Yrk9gLdb55Z7bX797)bvsfVxbstr(3BLL3B98gcPERWK3YZe9Q317KIZeWB04jH3hW7aRyKbQK8MaKXqFX3gvDoWxO)jqLEEWKlJI9baXIidd65RMVkjRgmiK(yWMVbbJgmiKw0XGS6zfdTi2f(VzZ6RRbdcPfykKkCzVQMLdH2MnAWGqAbMcPcx2R6IyYaARMD9OQdwKLaKXqpgS3Srdgesl6yqw9SIHmldO8vxDZM11GbH0IogKvp7EvTzanZ4h0YUEu1blYsaYyOhd2B2ObdcPfDmiREwXqMLZCU6Q(wFl09MxnG5Hj27BJQoh4lidyEym73jTm6powL4d5ywaXlkgS9Tq37CCSMVsSqjVHJ3B4bcm9Q37S5yJM3BtJc7T5deyfkX79kMaqOaujV52lE7DooVuPDDoG3Z79k4YX9wegbeYBtWeWBCQMjv9EEVzuiYx8TrvNd8fKbmpmpyYLWA(kXcL4BqWGYHGuadey9TyraiuaQuHBp76)ojLwnyqi9lpmhBwsa7RhZyXm2SbRGnbQKkCpz3zZXgnVLDAOZb2SbQAijGwEQYi1QufgmRioQqGavsInBGA9oP4mbkpvzKAvQcdMvehv42x13cDVZXs0U3C7EB(abwrLHG8Eq8EuVN37a94uV1ZBghW7JtlEVGZBWPEZ9K3MVM3co2aG49ccqL4Z7bXBnKeqjH3dqpVxqWw6noCiotfFBu15aFbzaZdZdMCbdeyfvgcIVbbZ6qvdjb0IiylTpCiotfceOssSzdur5qqkpCiotwraQuHBF1S6yqw9SIH4ngzed4nBLYYiJya)I6uxA1XGGIz4BHU3qzCsDeNQdaI3hN(JG8EbbOsEFaV1GbH03BfouVnnsP3YblYBKJ5TctEl4yHohW7dXBZhiWkQmeeFEZieg9WEl4ydaI37bqqgtT4nugNuhXPEhV3YdaX749odE8wdgesFVfN3Gt9goWI828bcSIkdb5n3U3Mgf27CaTlNAOdaI34WH4m9EVohqs)7D(JZB4alYBZhiWkuI37vmbGqbOsER3TAX3gvDoWxqgW8W8GjxWabwrLHG4RMVkjRgmiK(yWMVbbduXkytGkPc3t2D2CSrZBzNg6CGS)ojLwnyqi9lpmhBwsa7RhZWmmzKD9yHeBuQagiW6BXIaqOauPcbcujj2SbQXcj2OuHr7YPg6aGyF4qCM(cbcujj2S53jP0QbdcPF5H5yZscyF9yg8wu1blYkoTagiWkQmeKzyYy1SqfLdbP8WH4mzfbOsfU9S6yqw9SIHmdZ68NN1Zakwpd0ZUFdq)vxnlJqy0dhOsY3cDVZbecJEyVnFGaROYqqEtbtM37bX7r920iLEt8Y(WiVfCSbaXB88gON8lEVGZBfouVzecJEyVheVXVf4nesFVzuiY79a8wHjVbeVOEZ)V4BJQoh4lidyEyEWKlyGaROYqq8niyyKrmGFX6DsXzcu(8gON8ThIvqHcxyKrmGNhSHw26DsXzcu(8gON8ThIvqHcxyKrmGFrm8pRogKvpRyiEJrgXaEZQ3jfNjq5ZBGEY3EiwbfkCHrgXaEE4VVnQ6CGVGmG5H5btUpvzKAvQcdMveh5BJQoh4lidyEyEWKlH18vIfk5B9Tq3BCLcPc7nVFNuCMaVVf6EdLmj3jM3R4GnbQK8TrvNd8LxPqQW2Q4XGvWMavs8bcdcZdlSkmJE4tk4dRqYryQ3jfNjq5HdXzYkcqLkv4GbHElclQ6CGqAggSlRq(7BHU3R4ampS3Caj9V3MiVdg5DGECQ365Dn29(aEVGaujVRWbdc9fV51bK592emb8MxnaH3RmkwcO)9EEVd0Jt9wpVzCaVpoT4BJQoh4lVsHuHTvXZdMCXkaZdZ3GGbQyfSjqLu5HfwfMrp8jfzRNb6z3VbOFrqitDuZWoRGq5qqkidqynrXsa9FHrgXa(fXoB9oP4mbkFEd0t(2dXkOqHlmYigWBgg(5BHU3qH7KEJCmVXHdXzYGKcV5XBC4qCMELnljV5as6FVnrEhmY7a94uV1Z7AS79b8EbbOsExHdge6lEZRdiZ7Tjyc4nVAacVxzuSeq)798EhOhN6TEEZ4aEFCAX3gvDoWxELcPcBRINhm5UFN0YO)4yvIpKJzbeVOyWMpIxuwydJJdOyYj08TrvNd8LxPqQW2Q45btUpCiotgKuW3GGHaedsEZWKtOLLaeds(IGqM6OMHbBOLfQyfSjqLu5HfwfMrp8jfzRNb6z3VbOFrqitDuZWoRGq5qqkidqynrXsa9FHrgXa(fX23cDV5DOG3mAfXnmYGa6k37feGk5DOElptEZ7qbVrZ7TGqcoPw8EDCouLfvDoG3Z7D4D92Z7nc7m8wHjVFLcjmj8gzaZdtmVRHu6nYX8otE1c8goac5aGuw13gvDoWxELcPcBRINhm5IvWMavs8bcdcZdlS1Za9S73a0NpScjhHPEgOND)gG(fbHm1rndto5T11qsaTiiANy2xzHgqiJcbcujjYUESqInkvuyYImSxTIauPcbcujjYcvnKeqlIGT0(WH4mviqGkjrwOQHKaA55qvIHWbHkeiqLKi7VtsPvdges)YdZXMLeW(6XmwKFRUQVf6EZ7qbVz0kIByKbb0vU3liavY7diZ7nkHCmYBKbmpmXEVheVnrEdhyrEhg7ERHKa67DaeEVZMJnAEVzNg6CGIVnQ6CGV8kfsf2wfppyYfRGnbQK4degeMhwyRNb6z3VbOpFyfsoct9mqp7(na9lcczQJUigS5jdOySqInkvuyYImSxTIauPcbcujj4BqWGvWMavsfUNS7S5yJM3Yon05azxxdjb0cyGaRVgYLeRqGavsInB0qsaTic2s7dhIZuHabQKeR6BHU3RSrH9EbbBP34WH4m59bK59EbbOsEBcMaEB(abwrLHG820iLE)AK3BU9I35ON8wWXgaeVXZBGEY37J5DGEyrERWm6HpPO49klg1BKJ5T5RyVr5qq820OWENbpMVIl(2OQZb(YRuivyBv88Gj3hoeNjRiavIVbbdwbBcujvEyHTEgOND)gG(zxhQAijGwebBP9HdXzQqGavsInBeNwadeyfvgcQWiJyaVzy4ppAijGwEouLyiCqOcbcujjwn76yfSjqLu5HfwfMrp8jfB2GYHGu(8gON8ThIvqHcxyKrmG3mmyxYyZMFNKsRgmiK(LhMJnljG91JzygMCMTENuCMaLpVb6jF7HyfuOWfgzed4ndBOTA21JfsSrPcyGaRVflcaHcqLkSaSCXm2SbLdbPagiW6BXIaqOauPc3(Q(wO79ACmG3mYigWaG49ccqLEVrjKJrERWK3AWGqQ3IHEVheVXVf4TPdaLq9gL8MrHiV3dWBDmOIVnQ6CGV8kfsf2wfppyY9HdXzYkcqL4BqWGvWMavsLhwyRNb6z3VbOFwDmiREwXqlwVtkotGYN3a9KV9qScku4cJmIb8zHklgHLWIaAjeIVWT7B9Tq3BCLcPctcVZbNg6CaFl09gkfXBCLcPcNlwbyEyVdg5n3oFEZ9K34WH4m9kBwsERN3OeGqg1Be2z4TctEVh)pyrEJEaU37ai8MxnaH3RmkwcO)5ZBclc49G4TjY7GrEhQ3gbV4nVdf8EDe2z4TctEVZO6zGgQ3qzily1IVnQ6CGV8kfsfMeyE4qCMELnlj(gemRRHKaAbzacRjkwcO)leiqLKyZMFNKsRgmiK(LhMJnljG91JzSi)wn76OCiiLxPqQWfU9nBq5qqkyfG5HlC7R6BHU38QbmpS3H6n)4XBEhk4TPrHpo17fG7DUENtE820OWEVaCVnnkS34WCSzjb8oZJbcX5nkhcI3C7ERN3bw3i8(pdYBEhk4TP4vY7FuUqNd8fFBu15aF5vkKkmj4btU1qkTrvNdyLZR8bcdcdYaMhMVbbdkhcs5H5yZscy1JbcXv42Zwpd0ZUFdq)IGqM6OlIjdFl09Efi)Z7pqiV1ZBKbmpS3H6Do5XBEhk4TPrH9M4LOQY8ENtV1GbH0V4964Hb5D8EFC6pcY7xPqQWLv9TrvNd8LxPqQWKGhm5wdP0gvDoGvoVYhimimidyEy(gem)ojLwnyqi9lpmhBwsa7RhZatoZwpd0ZUFdqFZWKtFl09MxnG5H9ouVZjpEZ7qbVnnk8XPEVaC(8M)84TPrH9Eb485DaeEVsEBAuyVxaU3bIsmVxXbyEyVpM3zctEZRg2REVGaujV5XBZhiW679kMGqbOs(2OQZb(YRuivysWdMCRHuAJQohWkNx5degegKbmpmFdcM6zGE29Ba6xeeYuhDrmyZBRRHKaArq0oXSVYcnGqgfceOssKDDuoeKcwbyE4c3(MnXcj2OurHjlYWE1kcqLkeiqLKi7VtsPvdges)YdZXMLeW(6XmwKFzr5qqkGbcS(wSiaekavQWTV6Q(wO7Do6jVZXiVZavgcY7dlI5noCiotVYMLK3bq4nUEmdVnnkS3zWJ3qbIHCSqjVd17m8(yElP)9wdges)IVnQ6CGV8kfsfMe8GjxiY7mqLHG4BqWelKyJsLDIHCSqPclalndtgz)DskTAWGq6xEyo2SKa2xpMXIyYW3cDVxbQ3z4TgmiK(EBAuyVXPkJuVZKQWGzfXrEVKODV529MxnaH3RmkwcO)9gnV318v5aG4noCiotVYMLuX3gvDoWxELcPctcEWK7dhIZ0RSzjXxnFvswnyqi9XGnFdcgnKeqlpvzKAvQcdMvehviqGkjrwnKeqlidqynrXsa9FHabQKezfekhcsbzacRjkwcO)lmYigWVi2z)DskTAWGq6xEyo2SKa2xpMbMmYQJbz1ZkgI3yKrmG3SvY3cDVxzJcFCQ3lGODI5nUYcnGqgEhaH38Z7Cqaw(EFiEVMmeK3dWBfM8ghoeNP37r9EEVnDmf2BUFaq8ghoeNPxzZsY7d4n)8wdges)IVnQ6CGV8kfsfMe8Gj3hoeNPxzZsIVbbdu1qsaTiiANy2xzHgqiJcbcujjYglKyJsfuzii7aSkmzF4qCM(clalXWVS)ojLwnyqi9lpmhBwsa7RhZad)8Tq3BE1X8ENnhB08EZon05a85n3tEJdhIZ0RSzj59HfX8gxpMH3yVQ3Mgf27vguM3bKyaV6n3U365Do9wdgesF(8oJv9Eq8MxTY8EEVzCaWaG49HG496hW7aK37W44aQ3hI3AWGq6VkFEFmV53QERN3gbVmgZcjVXVf4nXlkb(5aEBAuyVHsbewJgOJC08EFaV5N3AWGq679650BtJc79AJIVAX3gvDoWxELcPctcEWK7dhIZ0RSzjX3GGbRGnbQKkCpz3zZXgnVLDAOZbYUUgscOfKbiSMOyjG(VqGavsISccLdbPGmaH1eflb0)fgzed4xe7nB0qsaTyII9dyeVsScbcujjY(7KuA1GbH0V8WCSzjbSVEmJfXKZnBIfsSrPYaiSgnqh5O5leiqLKilkhcs5ZBGEY3EiwbfkCHBp7VtsPvdges)YdZXMLeW(6Xmwed)4jwiXgLkOYqq2byvyY(WH4m9fceOssSQVnQ6CGV8kfsfMe8Gj3hMJnljG91JzW3GG53jP0QbdcPVzy4NVnQ6CGV8kfsfMe8Gj3hoeNPxzZskH)7unzEgRe2jnPPe]] )


end
