-- RogueOutlaw.lua
-- June 2018
-- Contributed by Alkena.

local addon, ns = ...
local Hekili = _G[ addon ] 

local class = Hekili.Class
local state =  Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'ROGUE' then
    local spec = Hekili:NewSpecialization( 260 )

    spec:RegisterResource( Enum.PowerType.ComboPoints )
    spec:RegisterResource( Enum.PowerType.Energy, {
        blade_rush = {
            aura = 'blade_rush',

            last = function ()
                local app = state.buff.blade_rush.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 5,
        }, 
    } )

    -- Talents
    spec:RegisterTalents( {
        weaponmaster = 22118, -- 200733
        quick_draw = 22119, -- 196938
        ghostly_strike = 22120, -- 196937

        acrobatic_strikes = 19236, -- 196924
        retractable_hook = 19237, -- 256188
        hit_and_run = 19238, -- 196922

        vigor = 19239, -- 14983
        deeper_stratagem = 19240, -- 193531
        marked_for_death = 19241, -- 137619

        iron_stomach = 22121, -- 193546
        cheat_death = 22122, -- 31230
        elusiveness = 22123, -- 79008

        dirty_tricks = 23077, -- 108216
        blinding_powder = 22114, -- 256165
        prey_on_the_weak = 22115, -- 131511

        loaded_dice = 21990, -- 256170
        alacrity = 23128, -- 193539
        slice_and_dice = 19250, -- 5171

        dancing_steel = 22125, -- 272026
        blade_rush = 23075, -- 271877
        killing_spree = 23175, -- 51690
    } )



    local rtb_buff_list = {
        "broadside", "buried_treasure", "grand_melee", "ruthless_precision", "skull_and_crossbones", "true_bearing", "rtb_buff_1", "rtb_buff_2"
    }


    -- Auras
    spec:RegisterAuras( {
        adrenaline_rush = {
            id = 13750,
            duration = 20,
            max_stack = 1,
        },
        alacrity = {
            id = 193538,
            duration = 20,
            max_stack = 5,
        },
        between_the_eyes = {
            id = 199804,
            duration = 5,
            max_stack = 1
        },
        blade_flurry = {
            id = 13877,
            duration = 15,
            max_stack = 1,
        },
        blade_rush = {
            id = 271896,
            duration = 5,
            max_stack = 1,
        },
        blind = {
            id = 2094,
            duration = 60,
            max_stack = 1,
        },
        cheap_shot = {
            id = 1833,
            duration = 4,
            max_stack = 1,
        },
        cloak_of_shadows = {
            id = 31224,
            duration = 5,
            max_stack = 1,
        },
        combat_potency = {
            id = 61329,
        },
        crimson_vial = {
            id = 185311,
            duration = 6,
            max_stack = 1,
        },
        detection = {
            id = 56814,
            duration = 30,
            max_stack = 1,
        },
        feint = {
            id = 1966,
            duration = 5,
            max_stack = 1,
        },
        fleet_footed = {
            id = 31209,
        },
        ghostly_strike = {
            id = 196937,
            duration = 10,
            max_stack = 1,
        },
        gouge = {
            id = 1776,
            duration = 4,
            max_stack = 1,
        },
        killing_spree = {
            id = 51690,
            duration = 2,
            max_stack = 1,
        },
        loaded_dice = {
            id = 256171,
            duration = 45,
            max_stack = 1,
        },
        marked_for_death = {
            id = 137619,
            duration = 60,
            max_stack = 1,
        },
        opportunity = {
            id = 195627,
            duration = 10,
            max_stack = 1,
        },
        pistol_shot = {
            id = 185763,
            duration = 6,
            max_stack = 1,
        },
        restless_blades = {
            id = 79096,
        },
        riposte = {
            id = 199754,
            duration = 10,
            max_stack = 1,
        },
        -- Replaced this with 'alias' for any of the other applied buffs.
        -- roll_the_bones = { id = 193316, },
        ruthlessness = {
            id = 14161,
        },
        sharpened_sabers = {
            id = 252285,
            duration = 15,
            max_stack = 2,
        },
        shroud_of_concealment = {
            id = 114018,
            duration = 15,
            max_stack = 1,
        },
        slice_and_dice = {
            id = 5171,
            duration = 18,
            max_stack = 1,
        },
        sprint = {
            id = 2983,
            duration = 8,
            max_stack = 1,
        },
        stealth = {
            id = 1784,
            duration = 3600,
        },
        vanish = {
            id = 11327,
            duration = 3,
            max_stack = 1,
        },

        -- Real RtB buffs.
        broadside = {
            id = 193356,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },
        buried_treasure = {
            id = 199600,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },
        grand_melee = {
            id = 193358,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },
        skull_and_crossbones = {
            id = 199603,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },        
        true_bearing = {
            id = 193359,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },
        ruthless_precision = {
            id = 193357,
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },


        -- Fake buffs for forecasting.
        rtb_buff_1 = {
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },

        rtb_buff_2 = {
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },

        roll_the_bones = {
            alias = rtb_buff_list,
            aliasMode = "first", -- use duration info from the first buff that's up, as they should all be equal.
            aliasType = "buff",
            duration = function () return 36 + ( talent.deeper_strategem.enabled and 6 or 0 ) end,
        },


        -- Azerite Powers
        brigands_blitz = {
            id = 277725,
            duration = 20,
            max_stack = 10,
        },
        deadshot = {
            id = 272940,
            duration = 3600,
            max_stack = 1,
        },
        keep_your_wits_about_you = {
            id = 288988,
            duration = 15,
            max_stack = 30,
        },
        paradise_lost = {
            id = 278962,
            duration = 3600,
            max_stack = 1,
        },
        snake_eyes = {
            id = 275863,
            duration = 12,
            max_stack = 5,
        },
        storm_of_steel = {
            id = 273455,
            duration = 3600,
            max_stack = 1,
        },
    } )


    spec:RegisterStateExpr( "rtb_buffs", function ()
        return buff.roll_the_bones.count
    end )


    spec:RegisterStateExpr( "cp_max_spend", function ()
        return combo_points.max
    end )


    local stealth = {
        rogue   = { "stealth", "vanish", "shadow_dance", "subterfuge" },
        mantle  = { "stealth", "vanish" },
        all     = { "stealth", "vanish", "shadow_dance", "subterfuge", "shadowmeld" }
    }

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


    -- Legendary from Legion, shows up in APL still.
    spec:RegisterGear( "mantle_of_the_master_assassin", 144236 )
    spec:RegisterAura( "master_assassins_initiative", {
        id = 235027,
        duration = 3600
    } )

    spec:RegisterStateExpr( "mantle_duration", function ()
        if level > 115 then return 0 end

        if stealthed.mantle then return cooldown.global_cooldown.remains + 5
        elseif buff.master_assassins_initiative.up then return buff.master_assassins_initiative.remains end
        return 0
    end )


    -- We need to break stealth when we start combat from an ability.
    spec:RegisterHook( "runHandler", function( ability )
        local a = class.abilities[ ability ]

        if stealthed.mantle and ( not a or a.startsCombat ) then
            if level < 116 and equipped.mantle_of_the_master_assassin then
                applyBuff( "master_assassins_initiative", 5 )
            end

            if talent.subterfuge.enabled then
                applyBuff( "subterfuge" )
            end

            if buff.stealth.up then
                setCooldown( "stealth", 2 )
            end

            removeBuff( "stealth" )
            removeBuff( "shadowmeld" )
            removeBuff( "vanish" )
        end
    end )


    spec:RegisterHook( "spend", function( amt, resource )
        if resource == "combo_points" then
            if amt >= 5 then gain( 1, "combo_points" ) end

            local cdr = amt * ( buff.true_bearing.up and 2 or 1 )

            reduceCooldown( "adrenaline_rush", cdr )
            reduceCooldown( "between_the_eyes", cdr )
            reduceCooldown( "sprint", cdr )
            reduceCooldown( "grappling_hook", cdr )
            reduceCooldown( "vanish", cdr )

            reduceCooldown( "blade_rush", cdr )
            reduceCooldown( "killing_spree", cdr )
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        adrenaline_rush = {
            id = 13750,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
            gcd = "off",

            startsCombat = false,
            texture = 136206,

            toggle = 'cooldowns',

            nobuff = "stealth",

            handler = function ()
                applyBuff( 'adrenaline_rush', 20 )

                energy.regen = energy.regen * 1.6
                energy.max = energy.max + 50
                forecastResources( 'energy' )

                if talent.loaded_dice.enabled then
                    applyBuff( 'loaded_dice', 45 )
                    return
                end

                if azerite.brigands_blitz.enabled then
                    applyBuff( "brigands_blitz" )
                end
            end,
        },


        ambush = {
            id = 8676,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 50,
            spendType = "energy",

            startsCombat = true,
            texture = 132282,

            usable = function () return stealthed.all end,            
            handler = function ()
                gain( buff.broadside.up and 3 or 2, 'combo_points' )
            end,
        },


        between_the_eyes = {
            id = 199804,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 25,
            spendType = "energy",

            startsCombat = true,
            texture = 135610,

            usable = function() return combo_points.current > 0 end,

            handler = function ()
                if talent.prey_on_the_weak.enabled then
                    applyDebuff( 'target', 'prey_on_the_weak', 6 )
                end

                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end

                applyDebuff( 'target', 'between_the_eyes', combo_points.current ) 

                if azerite.deadshot.enabled then
                    applyBuff( "deadshot" )
                end

                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" ) 
            end,
        },


        blade_flurry = {
            id = 13877,
            cast = 0,
            charges = 2,
            cooldown = 25,
            recharge = 25,

            gcd = "spell",

            spend = 15,
            spendType = "energy",

            startsCombat = false,
            texture = 132350,

            usable = function () return buff.blade_flurry.remains < gcd.execute end,
            handler = function ()
                if talent.dancing_steel.enabled then 
                    applyBuff ( 'blade_flurry', 15 )
                    return
                end
                applyBuff( 'blade_flurry', 12 )
            end,
        },


        blade_rush = {
            id = 271877,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 1016243,

            handler = function ()
                applyBuff( 'blade_rush', 5 )
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

            spend = function () return 40 - ( talent.dirty_tricks.enabled and 40 or 0 ) end,
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
                applyDebuff( 'target', 'cheap_shot', 4)
                if talent.prey_on_the_weak.enabled then
                    applyDebuff( 'target', 'prey_on_the_weak', 6)
                    return
                end
            end,
        },


        cloak_of_shadows = {
            id = 31224,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

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

            spend = 30,
            spendType = "energy",

            startsCombat = false,
            texture = 1373904,

            handler = function ()
                applyBuff( 'crimson_vial', 6 )
            end,
        },


        detection = {
            id = 56814,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            startsCombat = false,
            texture = 132319,
            
            handler = function ()
                applyBuff( "detection" )
            end,
        },


        dispatch = {
            id = 2098,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = true,
            texture = 236286,

            usable = function() return combo_points.current > 0 end,
            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end

                removeBuff( "storm_of_steel" )

                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" )
            end,
        },


        distract = {
            id = 1725,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 30,
            spendType = "energy",

            startsCombat = false,
            texture = 132289,

            handler = function ()
            end,
        },


        feint = {
            id = 1966,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = false,
            texture = 132294,

            handler = function ()
                applyBuff( 'feint', 5 )
            end,
        },


        ghostly_strike = {
            id = 196937,
            cast = 0,
            cooldown = 35,
            gcd = "spell",

            spend = 30,
            spendType = "energy",

            talent = 'ghostly_strike',

            startsCombat = true,
            texture = 132094,

            handler = function ()
                applyDebuff( 'target', 'ghostly_strike', 10 )
                gain( buff.broadside.up and 2 or 1, "combo_points" )
            end,
        },


        gouge = {
            id = 1776,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = function () return talent.dirty_tricks.enabled and 0 or 0 end,
            spendType = "energy",

            startsCombat = true,
            texture = 132155,

            -- Disable Gouge because we can't tell if we're in front of the target to use it.
            usable = function () return false end,
            handler = function ()
                gain( buff.broadside.up and 2 or 1, "combo_points" )
                applyDebuff( 'target', 'gouge', 4 )
            end,
        },


        grappling_hook = {
            id = 195457,
            cast = 0,
            cooldown = function () return 60 - ( talent.retractable_hook.enabled and 30 or 0 ) end,
            gcd = "spell",

            startsCombat = false,
            texture = 1373906,

            handler = function ()
            end,
        },


        kick = {
            id = 1766,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

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


        killing_spree = {
            id = 51690,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            talent = 'killing_spree',

            startsCombat = true,
            texture = 236277,

            toggle = 'cooldowns',

            handler = function ()
                applyBuff( 'killing_spree', 2 )
            end,
        },


        marked_for_death = {
            id = 137619,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            talent = 'marked_for_death', 

            startsCombat = false,
            texture = 236364,

            usable = function ()
                return settings.mfd_waste or combo_points.current == 0, "combo_point (" .. combo_points.current .. ") waste not allowed"
            end,

            handler = function ()
                gain( 5, 'combo_points')
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


        pistol_shot = {
            id = 185763,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 40 - ( buff.opportunity.up and 20 or 0 ) end,
            spendType = "energy",

            startsCombat = true,
            texture = 1373908,

            handler = function ()
                gain( buff.broadside.up and 2 or 1, 'combo_points' )

                if talent.quick_draw.enabled and buff.opportunity.up then
                    gain( 1, 'combo_points' )
                end

                removeBuff( "deadshot" )
                removeBuff( 'opportunity' )
            end,
        },


        riposte = {
            id = 199754,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 132269,

            handler = function ()
                applyBuff( 'riposte', 10 )
            end,
        },


        roll_the_bones = {
            id = 193316,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            notalent = 'slice_and_dice',

            spend = 25,
            spendType = "energy",

            startsCombat = false,
            texture = 1373910,

            usable = function ()
                if combo_points.current == 0 then return false, "no combo points" end

                -- Don't RtB if we've already done a simulated RtB.
                if buff.rtb_buff_1.up then return false, "we already rerolled and can't know which buffs we'll have" end

                --[[ This was based on 8.2 logic; tweaking APL instead to avoid hardcoding.  2020-03-09
                
                if buff.roll_the_bones.down then return true end

                -- Handle reroll checks for pre-combat.
                if time == 0 then
                    if combo_points.current < 5 then return false end

                    local reroll = rtb_buffs < 2 and ( buff.loaded_dice.up or not buff.grand_melee.up and not buff.ruthless_precision.up )

                    if azerite.deadshot.enabled or azerite.ace_up_your_sleeve.enabled then
                        reroll = rtb_buffs < 2 and ( buff.loaded_dice.up or buff.ruthless_precision.remains <= cooldown.between_the_eyes.remains )
                    end

                    if azerite.snake_eyes.enabled then
                        reroll = rtb_buffs < 2 or ( azerite.snake_eyes.rank == 3 and rtb_buffs < 5 )
                    end

                    if azerite.snake_eyes.rank >= 2 and buff.snake_eyes.stack >= ( buff.broadside.up and 1 or 2 ) then return false end

                    return reroll
                end ]]

                return true
            end,            

            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end

                for _, name in pairs( rtb_buff_list ) do
                    removeBuff( name )
                end

                if azerite.snake_eyes.enabled then
                    applyBuff( "snake_eyes", 12, 5 )
                end

                applyBuff( "rtb_buff_1", 12 + 6 * ( combo_points.current - 1 ) )
                if buff.loaded_dice.up then
                    applyBuff( "rtb_buff_2", 12 + 6 * ( combo_points.current - 1 ) )
                    removeBuff( "loaded_dice" )
                end

                spend( min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current ), "combo_points" )
            end,
        },


        sap = {
            id = 6770,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 35 - ( talent.dirty_tricks.enabled and 35 or 0 ) end,
            spendType = "energy",

            startsCombat = false,
            texture = 132310,

            handler = function ()
                applyDebuff( 'target', 'sap', 60 )
            end,
        },


        shroud_of_concealment = {
            id = 114018,
            cast = 0,
            cooldown = 360,
            gcd = "spell",

            startsCombat = false,
            texture = 635350,

            handler = function ()
                applyBuff( 'shroud_of_concealment', 15 )
            end,
        },


        sinister_strike = {
            id = 193315,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 45,
            spendType = "energy",

            startsCombat = true,
            texture = 136189,

            handler = function ()
                removeStack( "snake_eyes" )
                gain( buff.broadside.up and 2 or 1, 'combo_points')
            end,
        },


        slice_and_dice = {
            id = 5171,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 25,
            spendType = "energy",

            startsCombat = false,
            texture = 132306,

            talent = "slice_and_dice",

            usable = function()
                if combo_points.current == 0 or buff.slice_and_dice.remains > 6 + ( 6 * combo_points.current ) then return false end
                return true
            end,

            handler = function ()
                if talent.alacrity.enabled and combo_points.current > 4 then
                    addStack( "alacrity", 20, 1 )
                end

                local combo = min( talent.deeper_stratagem.enabled and 6 or 5, combo_points.current )
                applyBuff( "slice_and_dice", 6 + 6 * ( combo - 1 ) )
                spend( combo, "combo_points" )
            end,
        },


        sprint = {
            id = 2983,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 132307,

            handler = function ()
                applyBuff( 'sprint', 8 )
            end,
        },


        stealth = {
            id = 1784,
            cast = 0,
            cooldown = 2,
            gcd = "off",

            startsCombat = false,
            texture = 132320,

            usable = function ()
                if time > 0 then return false, "cannot stealth in combat"
                elseif buff.stealth.up then return false, "already in stealth"
                elseif buff.vanish.up then return false, "already vanished" end
                return true
            end,

            handler = function ()
                applyBuff( 'stealth' )
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
                applyBuff( "tricks_of_the_trade" )
            end,
        },


        vanish = {
            id = 1856,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 132331,

            disabled = function ()
                return not ( boss and group )
            end,

            handler = function ()
                applyBuff( 'vanish', 3 )
                applyBuff( "stealth" )
            end,
        },
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


    spec:RegisterPack( "Outlaw", 20200410, [[devKsbqivbpsvkBcL0NefWOuL4uQcTkvjPxHs1SqjULOk2Li)Is0Wev1Xicldf1ZiIQPPkvDnvPY2uLu9nvjLghrjDorb16iIsZtuP7Hc7tuXbffYcjkEirPQjsukxuvs0gjkHpsuIWijkrYjjkvSsvrVKOuPzsuIu3KikANII(jrjQHQkjCuIseTurH6PQQPsjCvrbzRQskYxjIcJvvsrDwvjfSxc)LKbRYHfwScpMIjtQlJSzf9zkPrlLoTsRwvsHEnkYSr1TLIDd53GgoL64Ic0YbEoutNQRlvBxu67OugVOkDEI06jImFIQ9lzHecleFD4KitMZN58Z)9sKFk)m87ENesU47sTjX3ommfwjXhfnK4ll3DEWM4Bhs5WqlSq8XWoWqIFR72yjRLwAD92(izGnwI3Mop8fImGy6wI3gJLI)OVCx2bjgIVoCsKjZ5ZC(5)EjYpLFg(DVlFjx8X2KrKjZVE(IF7Q1esmeFnHnI)B1jl3DEWwDzm0ANQNVvxR72yjRLwAD92(izGnwI3Mop8fImGy6wI3gJL1Z3QlJSblVojYNL6yoFMZVEwpFRozFBGSsyjB98T6YtDzKwt66KDxdt15W600m6CVUW4levhFXEQE(wD5PUmsRjDD2aYaBgHxNm8qt1jl4DaqADVOHegLb86gakyQUVtb3BFmvpFRU8uNSbrzaVUoMQZblIjYX1TO6WofCVnvpFRU8uNSbrzaVUoMQRzrs2xZ1nHG6KmdatKUUjeuNSrH3w3lRNbW1HGED4UTne4K(Xu98T6YtDzuw4QRdqaiNViR1LXUm1P7GfzToz4HMQtwW7aG06EPJ4egxhBuDqexADTrwQojQZdGvYFmvpFRU8uxgt8iV1j7UC(ISw33gquQE(wD5PUmeMQZ3gs5qLEP6MqqDeYa7iNa1ri9ISwhi8wcuN3gO68ayL8KVnKYHk9sP65B1LN6YqyQUm2LPoabGCEDCO11uxG019rYwDaAciCBDCO11u3IQZBP6SbKb2mcVUW4levhFXEs8TbW5YjX)T6KL7opyRUmgATt1Z3QR1DBSK1slTUEBFKmWglXBtNh(crgqmDlXBJXY65B1Lr2GLxNe5ZsDmNpZ5xpRNVvNSVnqwjSKTE(wD5PUmsRjDDYURHP6CyDAAgDUxxy8fIQJVypvpFRU8uxgP1KUoBazGnJWRtgEOP6Kf8oaiTUx0qcJYaEDdafmv33PG7TpMQNVvxEQt2GOmGxxht15GfXe546wuDyNcU3MQNVvxEQt2GOmGxxht11Sij7R56MqqDsMbGjsx3ecQt2OWBR7L1Za46qqVoC32gcCs)yQE(wD5PUmklC11biaKZxK16YyxM60DWISwNm8qt1jl4DaqADV0rCcJRJnQoiIlTU2ilvNe15bWk5pMQNVvxEQlJjEK36KDxoFrwR7BdikvpFRU8uxgct15BdPCOsVuDtiOoczGDKtG6iKErwRdeElbQZBduDEaSsEY3gs5qLEPu98T6YtDzimvxg7YuhGaqoVoo06AQlq66(izRoanbeUToo06AQBr15TuD2aYaBgHxxy8fIQJVypvpRNVv3RmVKP7KUUbnHaQodSzeEDdY6IWP6YiJHSDCDiikpTbOz251fgFHiCDqexAQE(wDHXxicNSbKb2mcNXKhyMQNVvxy8fIWjBazGnJWzNHLr3AdH8WxiQE(wDHXxicNSbKb2mcNDgwoHqD98T6(OWg3c96aXQRB0Ntsxh2dhx3GMqavNb2mcVUbzDr46cKUoBaLhBO7lYADlUonerP65B1fgFHiCYgqgyZiC2zyjgf24wORWE446zy8fIWjBazGnJWzNHLnbGjsRMqGstH3YInGmWMr4kmzGinMX7yzNmaXQvuwc5PqRXPfLZ7ZVEggFHiCYgqgyZiC2zyj2PG7TSStgV8aLb7RTnPt2qdtKJxjrALb2y39WxisPPSRHKl)bdeY1q2qjJudh6aiAnQbpWEs3bHVqKC5Gy1kklH80IY25icedoLO8Uyh)y98T6Yyca586MqqDmZEDqqDYsacKUojtItuDqqDzC3B5egx3RaqMfVquQEggFHim7mSmBa2yWjwqrdXa4dfGaqoNLSbVtma(qn6ZjoxMz9HrFotwbbsRAiorPUnRpm6Zzc09woHXkBazw8crPUD98T6Yyca586MqqDmZEDJ(CIRdcQtgam04vt1X26T1jBuOXTqpvpdJVqeMDgwMnaBm4elOOHya8HcqaiNZc0MbMCw2jJqseyDkPPqJBHEIqXGtAwYg8oXa4d1OpN4CzM1xg95mXHHM0k9AOu3wU8hg95mnaWqJxnL62pwpFRUmMaqoVUjeuhZSx3OpN46GG6Y4U3YjmUUxbGmlEHO6yB926Yidvx3UoPWoOUpNOSel11rCcJRZBjavxaO6AGaQozJcnUf61bcet4u9mm(cry2zyz2aSXGtSGIgIbWhkabGColqBgyYzzNmcjrG1Puyiv3wjf2bkmNOSuIqXGtAwdjrG1Puyiv3wjf2bkmNOSuceiMYHrijcSoL0uOXTqpbcetSKn4DIbWhQrFoX5YmRVm6ZzIddnPv61qPUTC5J(CMaDVLtySYgqMfVqucqnXIW5YWaHCnKnuAqoBeHuElPiPeobOMyr4hRNVvhZSx3hfmr19kLsyjBDzeNTqkUoabGCEDtiOoMzVUrFoXP6zy8fIWSZWYSbyJbNybfnedGpuaca5CwG2mWKZYozesIaRtjmkyIuKucNabIPCyWmlzdENya8HA0NtCUmxpFRoMzVUpkyIQ7vkLWs26KnyDiOxhGaqoVo2wVToMzVoShgMW1bN15TuDFuWev3RukHRB0NZ6Erc2Rd7HHP6yB926KbadnE1uDD7ht1ZW4leHzNHLzdWgdoXckAigaFOaeaY5SaTzaim5SStgHKiW6ucJcMifjLWjqGykhgmZ6OpNjmkyIuKucNWEyykhgmNNrFotdam04vtPUD98T6KmwVToz4HMQtwW7aG0662Su3AfbbuDGoNW1fdywQUaPRZdMO6OSeqQ3UiR15THx3IRJz2R7fe0RZa7iFrwR7hY(hRdcQdViRCQoz(SuNSesMSuxg)kQNHXxicZodlZgGngCIfu0qma(qbiaKZzbAZatol7KXOpNPbp0KAY7aG0u3MLSbVtma(qn6ZjopJ(CMWm15CvG0kdaIXdiIWPUDUmZ6lJ(CM4WqtALEnuQBlx(dJ(CMSccKw1qCIsDBwFy0NZeO7TCcJv2aYS4fIsDBwFy0NZ0aadnE1uQB)y98T6KmwVTozPHHM01jBRHQRBZsDaca586cK06WlYkNQB0NtwQlqsRJ56g95So2wVToz6GL01zbGcChqSuheu3IQZoqAQznP6zy8fIWSZWYSbyJbNybfnedGpuaca5CwG2mWKZYozm6ZzIddnPv61qPUnlzdENy8cWhQrFoX5z0NZ0OdwsRCaf4oGsD7hZLz5Yh95mbGCUYBj1aIiCcqnXIW5kr(jzL9xKijRVQhCc5jnr2eqHDq4HvQjrOyWj9J1ZW4leHt2aYaBgHZodlbqox5TKAareMfBazGnJWvyYarAmdMzzNmg95mbGCUYBj1aIiCcqnXIW5YqYLlpBa2yWPeWhkabGCE9mm(cr4KnGmWMr4SZWsmFnKkqALEnel2aYaBgHRWKbI0ygmZYozm6ZzcZxdPcKwPxdLautSiCU(2qkhQ0lX6OpNjmFnKkqALEnucqnXIW5(IeSBGndOYgUih)4RkrswRNHXxicNSbKb2mcNDgwgAaHc(IifOJBzXgqgyZiCfMmqKgZqcw2jJxEGYG912M0jBOHjYXRKiTYaBS7E4leP0u21qYL)Gbc5AiBOKrQHdDaeTg1GhypP7GWxisUCqSAfLLqEArz7CebIbNsuExSJFSEggFHiCYgqgyZiC2zyzhtQ1PgwqrdXiKeUnabwnHixbNkBiBeOEggFHiCYgqgyZiC2zyzhtQ1PgwO5KmUcfnedJudh6aiAnQbpWol7KXdGy1kklH80IY25icedoLO8UyhxpdJVqeozdidSzeo7mS0g6levpRNVv3RmVKP7KUoklbKwNVnuDElvxyCiOUfxxKnwEm4uQE(wDzmHDk4EBD7SoBigVdov3liyDz7CebIbNQJquZs46wuDgyZi8hRNHXxicZGP1Wel7KXdyNcU3s6eaATt1ZW4leHzGDk4EB9mm(cry2zyz2aSXGtSGIgIr0m64wLbI0RVqelzdENyyGndOYgUihN00CnRNddMzN5x9fp4eYtwBHyNlvHDWYeLium4KMvdeY1q2qjRTqSZLQWoyzIsaQjweoxjEK9rFotdam04vtPUnReIawLMZRNpRpm6ZzcZuNZvbsRmaigpGicN62S(WOpNjMiYwjf2bk2whRIbS7kPWEQBxpdJVqeMDgwMnaBm4elOOHymCszGi96leXs2G3jgJ(CMaDVLtySYgqMfVquQBlx(lHKiW6ustHg3c9eHIbN0YLhsIaRtPWqQUTskSduyorzPeHIbN0pY6OpNjaKZvElPgqeHtD765B1jzSEBDnDUV2CQopawjhZsDE7IRlBa2yWP6wCDMwYWePRZH1PjZQP6yRL8wcuhg2q1j7LnCD4wyNRRBq1HLImKUo2wVToz4HMQtwW7aG06zy8fIWSZWYSbyJbNybfneJbp0KAY7aGufwkYWs2G3jgyBIZvEaSsoon4HMutEhaKMlZScIvROSeYtHwJtlkhMZxU8rFotdEOj1K3baPPUD9mm(cry2zyPj4Cvy8fIu8f7SGIgIb2PG7TSStgyNcU3s6uW51ZW4leHzNHLMGZvHXxisXxSZckAiggnUE(wDYIfT426cVUMiVBtVPoz)Riv3VpWoimEDqev3ecQJctBDYaGHgVAQUaPRtw22gc8oADP1XwlHQtwY(AyQozdeSv3IRdtCY4KUUaPRtYCkB1T46qqVoafAP1ftNa15TuDikVEDyYar6uDzeNTqkUUMiV1jJ)kRJT1BRJz2RlJmuQEggFHim7mSe0rQW4leP4l2zbfneJ5IwCll7KHb2mGkB4ICComm2QMiVkSnH055LrFotdam04vtPUn7J(CMG22qG3rRln1TF8vFXdoH8ugSVgMuAqWwIqXGtAwF5bp4eYtnbGjsRMqGstH3Mium4KwUCdeY1q2qPMaWePvtiqPPWBtaQjweohjE8Xx9LqseyDkfgs1TvsHDGcZjklLabIPCzwU8hmqixdzdLgKZgriL3skskHtDB5YFy0NZeaY5kVLudiIWPU9J1ZW4leHzNHLMGZvHXxisXxSZckAigJ(Y11ZW4leHzNHLbWeis5qaGqol7KbHiGvPjnnxZ65WqI3XoHiGvPjazLq1ZW4leHzNHLbWeisz35yQEggFHim7mSKVwBDS61yxBTHqE9mm(cry2zy5iSQGtLdwdt46z98T6KPVCnbW1Z3QldHP6Efl2H86(TqVUDw361XgeLb86mHDDgyZawNnCroUUaPRZBP6KLTTHaVJwxADJ(Cw3IRRBNQlJYcxDDD8ISwhBTeQozxISR71aSdQtYyDCDypmmHRlauDTR126GG6yRLq11XlYADsguydrnb2jal11rCcJRZBP6Knk04wOx3OpN1T4662P6zy8fIWPrF5Ag2l2HCfUf6SStgV4bNqEkd2xdtkniylrOyWjTC5HKiW6uIjISvsHDGIT1XQya7UskSNabIPCz(rwh95mbTTHaVJwxAQBZ6lJ(CMyIiBLuyhOyBDSkgWURKc7jShgMYvI3lxoHiGvP5((39y9mm(cr40OVCn7mS0EXoKRWTqNLDYy0NZe02gc8oADPPUnRJ(CM0uOXTqp1TRNHXxicNg9LRzNHL4fTyNakSdwMO6z98T6K9qixdzdHRNHXxicNmAmdtW5QW4leP4l2zbfnedcJjKHWSStgpGDk4ElPtbNxpdJVqeoz0y2zyzObek4lIuGoULLDY4HrFotHgqOGVisb642u3M1xEGYG912M0Pqs42aey1eICfCQSHSra5YnqixdzdL4HtixfatGIeGAIfHZH58FSE(wDYoZ6cTgxxaO662SuhgT2uDElvher1X26T1XHSryVolSq2s1LHWuDS1sO60sxK16Mb2jqDEBGQt2)kQttZ1SEDqqDSTElS71fiP1j7FfP6zy8fIWjJgZodlBcatKwnHaLMcVLfJudNuEaSsoMHeSStgGy1kklH8uO14u3M1x8ayL8KVnKYHk9s5AGndOYgUihN00CnRlx(dyNcU3s6eaATtSAGndOYgUihN00CnRNddJTQjYRcBtiDEK4X65B1j7mRdbRl0ACDSTCED6LQJT1BxuDElvhIYRxNKNpML66yQojZPSvhev3aIX1X26TWUxxGKwNS)vKQNHXxicNmAm7mSSjamrA1ecuAk8ww2jdqSAfLLqEk0ACAr5i55NhqSAfLLqEk0ACs3bHVqeRpGDk4ElPtaO1oXQb2mGkB4ICCstZ1SEomm2QMiVkSnH05rI65B1jdp0uDYcEhaKwhevhZSxhHOMLWP6KmwVTUqRXs26YqyQUDwN3ssRd7H06MqqDYk71HjdePX1bb1TZ6Kc7G6quE96mTbWkvhBlNx3GQdqHwADlQoFBO6MqqDElvhIYRxhBrwkvpdJVqeoz0y2zy5GhAsn5Daqkl7Kb2M4CLhaRKJZHbZS(WOpNPbp0KAY7aG0u3M1xEaeRwrzjKNcTgNO8UyhlxoiwTIYsipfAnobOMyr4CKv5YbXQvuwc5PqRXPfLZlmNhdeY1q2qPbp0KAY7aG0KPnawjSAccJVquWF8vz(DpwpdJVqeoz0y2zyP1wi25svyhSmrSStggyZaQSHlYXjnnxZ65Wqc2h95mnaWqJxnL621ZW4leHtgnMDgwY0Y5lYQcBdiILDYiBa2yWP0GhAsn5DaqQclfzyfBtCUYdGvYXPbp0KAY7aG0CKGvcraRst(2qkhQAI8MdZ1ZW4leHtgnMDgwo4HMuGoULLDYiBa2yWP0GhAsn5DaqQclfzyLqeWQ0KVnKYHQMiV5WC98T6Yq4fzTUxtbAXTwMrnJoUTUfxheXLwxuxwciToFrsRBrgafyIL6WW6wuDak4RlLL6Kc7zaavxmWqE3jU06MlIQZH11XuDRxxGRlQR7lFDP1HTjopvpdJVqeoz0y2zyz2aT4ww2jJhWofCVL0PGZznBa2yWPu0m64wLbI0RVqu9mm(cr4KrJzNHL42qdzRH4Aw2jJhWofCVL0PGZznBa2yWPu0m64wLbI0RVqu9mm(cr4KrJzNHL2qFHiw2jJrFotdoeQ5DSNauyC5Yh95mfAaHc(IifOJBtD765B1jlcoFrwRBegMQZH1PPz05EDRtn11XHvQEggFHiCYOXSZWYoMuRtnSGIgIr2aSXGtQf5ecVUuL11AKfYDfeBwop8fzvbOW4qal7KXOpNPbhc18o2takmUC5(2qkhQ0lLldMZxUCdSzav2Wf54KMMRz9CzWC9mm(cr4KrJzNHLDmPwNAWSStgJ(CMgCiuZ7ypbOW4YL7BdPCOsVuUmyoF5YnWMbuzdxKJtAAUM1ZLbZ1ZW4leHtgnMDgwo4qOwn7aP1ZW4leHtgnMDgwoiaMamTiR1ZW4leHtgnMDgwoxan4qOUEggFHiCYOXSZWYaziSdcUYeCE9mm(cr4KrJzNHLDmPwNAyHMtY4ku0qmmsnCOdGO1Og8a7SStgpGDk4ElPtbNZ6OpNPqdiuWxePaDCBsdzdX6OpNPgQbcKQGtfVBwTsdOObN0q2qSsicyvAY3gs5qvtK3CEpRaFOg95eN77QNHXxicNmAm7mSSJj16udlOOHyesc3gGaRMqKRGtLnKncWYoz8WOpNPqdiuWxePaDCBQBZ6dJ(CMg8qtQjVdastDBwnqixdzdLcnGqbFrKc0XTja1elcNReVRE(wDVMiG06aWU1wU06aDovhCwN32Bg7CjDDnH3IRBqCiBs26YqyQUjeuNSdIjBOUodyDwQd6TeGTft1X26T1LrzCDHxhZ5ZEDypmmHRdcQtI8zVo2wVTUGJH1jdhc111Tt1ZW4leHtgnMDgw2XKADQHfu0qmcCB2aryfiKeeOmqqWzzNm00OpNjqijiqzGGGR00OpNjnKnKC5AA0NZKbI0DJVzj1IysPPrFotDBw9ayL8ulfCVnzB8CLCMz1dGvYtTuW92KTXZHHKNVC5pOPrFotgis3n(MLulIjLMg95m1Tz9fnn6Zzcesccugii4knn6Zzc7HHPCyWC(5rI8Fvnn6ZzAWHqTcovElPie1in1TLl3dGvYt(2qkhQ0lL7RN)JSo6Zzk0acf8frkqh3MautSiCosiR1Z3Qt2Oz05EDZGZhHHP6MqqDDCm4uDRtn4u9mm(cr4KrJzNHLDmPwNAWSStgJ(CMgCiuZ7ypbOW4YL7BdPCOsVuUmyoF5YnWMbuzdxKJtAAUM1ZLbZ1Z65B19kXycziC9mm(cr4eHXeYqyggiYqiheoPvtE0qSStgeIawLM8THuou1e5nhjy9HrFotdEOj1K3baPPUnRV8Gg6jdeziKdcN0QjpAi1OdqjFnmTiRS(qy8fIsgiYqiheoPvtE0qPfPM81ARlx(SZ5kazAdGvs5BdLRvJo1e59X6zy8fIWjcJjKHWSZWYbhc1k4u5TKIquJuw2jJSbyJbNsdEOj1K3baPkSuKHvdeY1q2qPb5Sres5TKIKs4u3M1SbyJbNsdNugisV(crS(c2M4CLhaRKJtdEOj1K3baP5WGz5YbXQvuwc5PqRXPfLZ7F3J1ZW4leHtegtidHzNHLw7bqVbsbNQqsea6T1ZW4leHtegtidHzNHLtOPJjTkKebwNudkAyzNmW2eNR8ayLCCAWdnPM8oainhgmlxoiwTIYsipfAnoTOCE98z9HrFotHgqOGVisb642u3UEggFHiCIWyczim7mS0Ud2P0fzvn4b2zzNmW2eNR8ayLCCAWdnPM8oainhgmlxoiwTIYsipfAnoTOCE98RNHXxicNimMqgcZodl9ws1rdyhPvtiWqSStgJ(CMaKHjoHXQjeyOu3wU8rFotaYWeNWy1ecmKYa7iNajShgMYvI8RNHXxicNimMqgcZodlbRTnNulsHTddvpdJVqeorymHmeMDgwYgeW1zPfPaegIcKHQNHXxicNimMqgcZodlBOgiqQcov8Uz1knGIgml7KbHiGvP5((3vpFRozPGCDDzmf2lYADYcE0q46MqqDuEjt3P6abYkvheuhtlNx3OpNywQBN1zdX4DWPuDzeNTqkUohiTohwNvYRZBP64q2iSxNbc5AiBO6gbM01br1fzJLhdovhHOMLWP6zy8fIWjcJjKHWSZWsaf2lYQAYJgcZIrQHtkpawjhZqcw2jdpawjp5BdPCOsVuUsKENC5V8IhaRKNAPG7TjBJNJSMVC5EaSsEQLcU3MSnEUmyo)hz9LW4BwsriQzjmdjKl3dGvYt(2qkhQ0lLdZz4hFuU8x8ayL8KVnKYHkBJRyo)CK88z9LW4BwsriQzjmdjKl3dGvYt(2qkhQ0lLZ7F)JpwpRNVvNSyrlULa465B1jJ)kRdMLa1LXUm1biaKZX1X26T1jBuOXTq3YmYq15GyDCDqqDzC3B5egx3RaqMfVquQEggFHiCAUOf3YyqoBeHuElPiPeMLDYiBa2yWP0WjLbI0RVqu9mm(cr40CrlULDgwI5RHubsR0RHyzNmg95mH5RHubsR0RHsaQjweoxFBiLdv6LyD0NZeMVgsfiTsVgkbOMyr4CFrc2nWMbuzdxKJF8vLijR1ZW4leHtZfT4w2zyjaY5kVLudiIWSStgJ(CMaqox5TKAareobOMyr4Czi5YLNnaBm4uc4dfGaqoVE(wDY4VY6yB9268wQUmYq1LHSR71aSdQ7ZjklvheuNSrHg3c96CqSoovpdJVqeonx0IBzNHLdYzJiKYBjfjLWSStgHKiW6ukmKQBRKc7afMtuwkrOyWjTC5HKiW6ustHg3c9eHIbN01ZW4leHtZfT4w2zyPEX2HBARN1Z3Q77uW926zy8fIWjStb3BzyAPWwHBHolgPgoP8ayLCmdjyzNm8GtipzdiPkis5TKInkykrOyWjnRp4bWk5PfRgqmUEggFHiCc7uW9w2zyz0m64wXplbWlejYK58zo)8FF(si(Sfa0ISIfFzNgBiWjDDV26cJVquD8f74u9u85l2XcleFcJjKHWclezkHWcXNqXGtAHmIVbSob2q8jebSkn5BdPCOQjYBD5uNe1XADpu3OpNPbp0KAY7aG0u3UowR7L6EOon0tgiYqiheoPvtE0qQrhGs(AyArwRJ16EOUW4leLmqKHqoiCsRM8OHslsn5R1wVo5YRB25CfGmTbWkP8THQl36SA0PMiV19O4hgFHiX3argc5GWjTAYJgs4ImzwyH4tOyWjTqgX3awNaBi(zdWgdoLg8qtQjVdasvyPitDSwNbc5AiBO0GC2icP8wsrsjCQBxhR1LnaBm4uA4KYar61xiQowR7L6W2eNR8ayLCCAWdnPM8oaiTUCyuhZ1jxEDGy1kklH8uO140IQlN6E)7Q7rXpm(crI)GdHAfCQ8wsriQrQWfzk5cle)W4lej(w7bqVbsbNQqsea6TIpHIbN0czeUiZ3lSq8jum4KwiJ4BaRtGneFSnX5kpawjhNg8qtQjVdasRlhg1XCDYLxhiwTIYsipfAnoTO6YPUxp)6yTUhQB0NZuObek4lIuGoUn1Tf)W4lej(tOPJjTkKebwNudkAeUiZ3jSq8jum4KwiJ4BaRtGneFSnX5kpawjhNg8qtQjVdasRlhg1XCDYLxhiwTIYsipfAnoTO6YPUxpFXpm(crIVDhStPlYQAWdSlCrMVUWcXNqXGtAHmIVbSob2q8h95mbidtCcJvtiWqPUDDYLx3OpNjazyItySAcbgszGDKtGe2ddt1LBDsKV4hgFHiX3BjvhnGDKwnHadjCrMVwHfIFy8fIeFWABZj1Iuy7WqIpHIbN0czeUitzvyH4hgFHiXNniGRZslsbimefidj(ekgCslKr4ImZWcleFcfdoPfYi(gW6eydXNqeWQ06YTU3)oXpm(crIFd1absvWPI3nRwPbu0GfUitjYxyH4tOyWjTqgXpm(crIpGc7fzvn5rdHfFdyDcSH47bWk5jFBiLdv6LQl36Ki9U6KlVUxQ7L68ayL8ulfCVnzB86YPozn)6KlVopawjp1sb3Bt2gVUCzuhZ5x3J1XADVuxy8nlPie1SeUog1jrDYLxNhaRKN8THuouPxQUCQJ5mCDpw3J1jxEDVuNhaRKN8THuouzBCfZ5xxo1j55xhR19sDHX3SKIquZs46yuNe1jxEDEaSsEY3gs5qLEP6YPU3)(6ESUhfFJudNuEaSsowKPecx4IVMMrN7clezkHWcXNqXGtAHmIp0w8XKl(HXxis8ZgGngCs8Zg8oj(aFOg95exxU1XCDSw3d1n6ZzYkiqAvdXjk1TRJ16EOUrFotGU3YjmwzdiZIxik1Tf)SbqHIgs8b(qbiaKZfUitMfwi(ekgCslKr8H2IpMCXpm(crIF2aSXGtIF2G3jXh4d1OpN46YToMRJ16EPUrFotCyOjTsVgk1TRtU86EOUrFotdam04vtPUDDpk(gW6eydXpKebwNsAk04wONium4Kw8ZgafkAiXh4dfGaqox4ImLCHfIpHIbN0czeFOT4Jjx8dJVqK4NnaBm4K4Nn4Ds8b(qn6ZjUUCRJ56yTUxQB0NZehgAsR0RHsD76KlVUrFotGU3YjmwzdiZIxikbOMyr46YLrDgiKRHSHsdYzJiKYBjfjLWja1elcx3JIVbSob2q8djrG1Puyiv3wjf2bkmNOSuIqXGt66yTUqseyDkfgs1TvsHDGcZjklLabIP6YHrDHKiW6ustHg3c9eiqmj(zdGcfnK4d8HcqaiNlCrMVxyH4tOyWjTqgXhAl(yYf)W4lej(zdWgdoj(zdENeFGpuJ(CIRl36yw8nG1jWgIFijcSoLWOGjsrsjCceiMQlhg1XS4Nnaku0qIpWhkabGCUWfz(oHfIpHIbN0czeFOT4dim5IFy8fIe)SbyJbNe)SbqHIgs8b(qbiaKZfFdyDcSH4hsIaRtjmkyIuKucNabIP6YHrDmxhR1n6ZzcJcMifjLWjShgMQlhg1XCD5PUrFotdam04vtPUTWfz(6cleFcfdoPfYi(qBXhtU4hgFHiXpBa2yWjXpBW7K4d8HA0NtCD5PUrFotyM6CUkqALbaX4ber4u3UUCRJ56yTUxQB0NZehgAsR0RHsD76KlVUhQB0NZKvqG0QgItuQBxhR19qDJ(CMaDVLtySYgqMfVquQBxhR19qDJ(CMgayOXRMsD76Eu8nG1jWgI)OpNPbp0KAY7aG0u3w8ZgafkAiXh4dfGaqox4ImFTcleFcfdoPfYi(qBXhtU4hgFHiXpBa2yWjXpBW7K4)sDaFOg95exxEQB0NZ0OdwsRCaf4oGsD76ESUCRJ56KlVUrFotaiNR8wsnGicNautSiCD5wNe5NK16yVUxQtIKSw3RwNhCc5jnr2eqHDq4HvQjrOyWjDDpk(gW6eydXF0NZehgAsR0RHsDBXpBauOOHeFGpuaca5CHlYuwfwi(ekgCslKr8nG1jWgI)d1HDk4ElPtaO1oj(HXxis8zAnmjCrMzyHfIFy8fIeFStb3BfFcfdoPfYiCrMsKVWcXNqXGtAHmIp0w8XKl(HXxis8ZgGngCs8Zg8oj(gyZaQSHlYXjnnxZ61LdJ6yUo2RJ56E16EPop4eYtwBHyNlvHDWYeLium4KUowRZaHCnKnuYAle7CPkSdwMOeGAIfHRl36KOUhRJ96g95mnaWqJxnL621XADeIawLwxo1965xhR19qDJ(CMWm15CvG0kdaIXdiIWPUDDSw3d1n6ZzIjISvsHDGIT1XQya7UskSN62IF2aOqrdj(rZOJBvgisV(crcxKPesiSq8jum4KwiJ4dTfFm5IFy8fIe)SbyJbNe)SbVtI)OpNjq3B5egRSbKzXleL621jxEDVuxijcSoL0uOXTqprOyWjDDYLxxijcSoLcdP62kPWoqH5eLLsekgCsx3J1XADJ(CMaqox5TKAareo1Tf)SbqHIgs8hoPmqKE9fIeUitjywyH4tOyWjTqgXhAl(yYf)W4lej(zdWgdoj(zdENeFSnX5kpawjhNg8qtQjVdasRl36yUowRdeRwrzjKNcTgNwuD5uhZ5xNC51n6ZzAWdnPM8oain1Tf)SbqHIgs8h8qtQjVdasvyPiJWfzkHKlSq8jum4KwiJ4BaRtGneFStb3BjDk4CXpm(crIVj4Cvy8fIu8f7IpFXUcfnK4JDk4ERWfzkX7fwi(ekgCslKr8dJVqK4BcoxfgFHifFXU4ZxSRqrdj(gnw4ImL4DcleFcfdoPfYi(gW6eydX3aBgqLnCroUUCyuNXw1e5vHTjKUU8u3l1n6ZzAaGHgVAk1TRJ96g95mbTTHaVJwxAQBx3J19Q19sDEWjKNYG91WKsdc2sekgCsxhR19sDpuNhCc5PMaWePvtiqPPWBtekgCsxNC51zGqUgYgk1eaMiTAcbknfEBcqnXIW1LtDsu3J19yDVADVuxijcSoLcdP62kPWoqH5eLLsGaXuD5whZ1jxEDpuNbc5AiBO0GC2icP8wsrsjCQBxNC519qDJ(CMaqox5TKAareo1TR7rXpm(crIpOJuHXxisXxSl(8f7ku0qI)CrlUv4ImL41fwi(ekgCslKr8dJVqK4BcoxfgFHifFXU4ZxSRqrdj(J(Y1cxKPeVwHfIpHIbN0czeFdyDcSH4ticyvAstZ1SED5WOojExDSxhHiGvPjazLqIFy8fIe)aycePCiaqix4ImLqwfwi(HXxis8dGjqKYUZXK4tOyWjTqgHlYuImSWcXpm(crIpFT26y1RXU2AdHCXNqXGtAHmcxKjZ5lSq8dJVqK4pcRk4u5G1Wew8jum4KwiJWfU4BdidSzeUWcrMsiSq8jum4KwiJ4hgFHiXVjamrA1ecuAk8wX3awNaBi(Gy1kklH8uO140IQlN6EF(IVnGmWMr4kmzGinw8FNWfzYSWcXNqXGtAHmIVbSob2q8FPUhQJYG912M0jBOHjYXRKiTYaBS7E4leP0u21q1jxEDpuNbc5AiBOKrQHdDaeTg1GhypP7GWxiQo5YRdeRwrzjKNwu2ohrGyWPeL3f746Eu8dJVqK4JDk4ERWfzk5cleFcfdoPfYi(HXxis8bqox5TKAarew8nG1jWgI)OpNjaKZvElPgqeHtaQjweUUCzuNKxNC51LnaBm4uc4dfGaqox8TbKb2mcxHjdePXIpZcxK57fwi(ekgCslKr8dJVqK4J5RHubsR0RHeFdyDcSH4p6ZzcZxdPcKwPxdLautSiCD5wNVnKYHk9s1XADJ(CMW81qQaPv61qja1elcxxU19sDsuh71zGndOYgUihx3J19Q1jrswfFBazGnJWvyYarAS4ZSWfz(oHfIpHIbN0cze)W4lej(HgqOGVisb64wX3awNaBi(Vu3d1rzW(ABt6Kn0We54vsKwzGn2Dp8fIuAk7AO6KlVUhQZaHCnKnuYi1WHoaIwJAWdSN0Dq4levNC51bIvROSeYtlkBNJiqm4uIY7IDCDpk(2aYaBgHRWKbI0yXxcHlY81fwi(ekgCslKr8rrdj(HKWTbiWQje5k4uzdzJaIFy8fIe)qs42aey1eICfCQSHSraHlY81kSq8jum4KwiJ4hgFHiX3i1WHoaIwJAWdSl(gW6eydX)H6aXQvuwc5PfLTZreigCkr5DXow8P5KmUcfnK4BKA4qharRrn4b2fUitzvyH4hgFHiX3g6lej(ekgCslKr4cx8h9LRfwiYucHfIpHIbN0czeFdyDcSH4)sDEWjKNYG91WKsdc2sekgCsxNC51fsIaRtjMiYwjf2bk2whRIbS7kPWEceiMQl36yUUhRJ16g95mbTTHaVJwxAQBxhR19sDJ(CMyIiBLuyhOyBDSkgWURKc7jShgMQl36K491jxEDeIawLwxU19(3v3JIFy8fIeF7f7qUc3cDHlYKzHfIpHIbN0czeFdyDcSH4p6ZzcABdbEhTU0u3UowRB0NZKMcnUf6PUT4hgFHiX3EXoKRWTqx4ImLCHfIFy8fIeF8IwStaf2bltK4tOyWjTqgHlCXh7uW9wHfImLqyH4tOyWjTqgXpm(crIVPLcBfUf6IVbSob2q89GtipzdiPkis5TKInkykrOyWjDDSw3d15bWk5PfRgqmw8nsnCs5bWk5yrMsiCrMmlSq8dJVqK4hnJoUv8jum4KwiJWfU4B0yHfImLqyH4tOyWjTqgX3awNaBi(puh2PG7TKofCU4hgFHiX3eCUkm(crk(IDXNVyxHIgs8jmMqgclCrMmlSq8jum4KwiJ4BaRtGne)hQB0NZuObek4lIuGoUn1TRJ16EPUhQJYG912M0Pqs42aey1eICfCQSHSrG6KlVodeY1q2qjE4eYvbWeOibOMyr46YPoMZVUhf)W4lej(HgqOGVisb64wHlYuYfwi(ekgCslKr8dJVqK43eaMiTAcbknfER4BaRtGneFqSAfLLqEk0ACQBxhR19sDEaSsEY3gs5qLEP6YTodSzav2Wf54KMMRz96KlVUhQd7uW9wsNaqRDQowRZaBgqLnCrooPP5AwVUCyuNXw1e5vHTjKUU8uNe19O4BKA4KYdGvYXImLq4ImFVWcXNqXGtAHmIVbSob2q8bXQvuwc5PqRXPfvxo1j55xxEQdeRwrzjKNcTgN0Dq4levhR19qDyNcU3s6eaATt1XADgyZaQSHlYXjnnxZ61LdJ6m2QMiVkSnH01LN6Kq8dJVqK43eaMiTAcbknfERWfz(oHfIpHIbN0czeFdyDcSH4JTjox5bWk546YHrDmxhR19qDJ(CMg8qtQjVdastD76yTUxQ7H6aXQvuwc5PqRXjkVl2X1jxEDGy1kklH8uO14eGAIfHRlN6K16KlVoqSAfLLqEk0ACAr1LtDVuhZ1LN6mqixdzdLg8qtQjVdastM2ayLWQjim(crbVUhR7vRJ53v3JIFy8fIe)bp0KAY7aGuHlY81fwi(ekgCslKr8nG1jWgIVb2mGkB4ICCstZ1SED5WOojQJ96g95mnaWqJxnL62IFy8fIeFRTqSZLQWoyzIeUiZxRWcXNqXGtAHmIVbSob2q8ZgGngCkn4HMutEhaKQWsrM6yToSnX5kpawjhNg8qtQjVdasRlN6KOowRJqeWQ0KVnKYHQMiV1LtDml(HXxis8zA58fzvHTbejCrMYQWcXNqXGtAHmIVbSob2q8ZgGngCkn4HMutEhaKQWsrM6yTocraRst(2qkhQAI8wxo1XS4hgFHiXFWdnPaDCRWfzMHfwi(ekgCslKr8nG1jWgI)d1HDk4ElPtbNxhR1LnaBm4ukAgDCRYar61xis8dJVqK4NnqlUv4ImLiFHfIpHIbN0czeFdyDcSH4)qDyNcU3s6uW51XADzdWgdoLIMrh3QmqKE9fIe)W4lej(42qdzRH4AHlYucjewi(ekgCslKr8nG1jWgI)OpNPbhc18o2takmEDYLx3OpNPqdiuWxePaDCBQBl(HXxis8TH(crcxKPemlSq8jum4KwiJ4hgFHiXpBa2yWj1ICcHxxQY6AnYc5UcInlNh(ISQauyCiq8nG1jWgI)OpNPbhc18o2takmEDYLxNVnKYHk9s1LlJ6yo)6KlVodSzav2Wf54KMMRz96YLrDml(OOHe)SbyJbNulYjeEDPkRR1ilK7ki2SCE4lYQcqHXHaHlYucjxyH4tOyWjTqgX3awNaBi(J(CMgCiuZ7ypbOW41jxED(2qkhQ0lvxUmQJ58RtU86mWMbuzdxKJtAAUM1Rlxg1XS4hgFHiXVJj16udw4ImL49cle)W4lej(doeQvZoqQ4tOyWjTqgHlYuI3jSq8dJVqK4piaMamTiRIpHIbN0czeUitjEDHfIFy8fIe)5cObhc1IpHIbN0czeUitjETcle)W4lej(bYqyheCLj4CXNqXGtAHmcxKPeYQWcXNqXGtAHmIFy8fIeFJudh6aiAnQbpWU4BaRtGne)hQd7uW9wsNcoVowRB0NZuObek4lIuGoUnPHSHQJ16g95m1qnqGufCQ4DZQvAafn4KgYgQowRJqeWQ0KVnKYHQMiV1LtDVVowRd4d1OpN46YTU3j(0CsgxHIgs8nsnCOdGO1Og8a7cxKPezyHfIpHIbN0cze)W4lej(HKWTbiWQje5k4uzdzJaIVbSob2q8FOUrFotHgqOGVisb642u3UowR7H6g95mn4HMutEhaKM621XADgiKRHSHsHgqOGVisb642eGAIfHRl36K4DIpkAiXpKeUnabwnHixbNkBiBeq4ImzoFHfIpHIbN0cze)W4lej(bUnBGiScesccugii4IVbSob2q810OpNjqijiqzGGGR00OpNjnKnuDYLxNMg95mzGiD34BwsTiMuAA0NZu3UowRZdGvYtTuW92KTXRl36KCMRJ168ayL8ulfCVnzB86YHrDsE(1jxEDpuNMg95mzGiD34BwsTiMuAA0NZu3UowR7L600OpNjqijiqzGGGR00OpNjShgMQlhg1XC(1LN6Ki)6E1600OpNPbhc1k4u5TKIquJ0u3Uo5YRZdGvYt(2qkhQ0lvxU1965x3J1XADJ(CMcnGqbFrKc0XTja1elcxxo1jHSk(OOHe)a3MnqewbcjbbkdeeCHlYKzjewi(ekgCslKr8nG1jWgI)OpNPbhc18o2takmEDYLxNVnKYHk9s1LlJ6yo)6KlVodSzav2Wf54KMMRz96YLrDml(HXxis87ysTo1GfUWf)5IwCRWcrMsiSq8jum4KwiJ4BaRtGne)SbyJbNsdNugisV(crIFy8fIe)b5Sres5TKIKsyHlYKzHfIpHIbN0czeFdyDcSH4p6ZzcZxdPcKwPxdLautSiCD5wNVnKYHk9s1XADJ(CMW81qQaPv61qja1elcxxU19sDsuh71zGndOYgUihx3J19Q1jrswf)W4lej(y(AivG0k9AiHlYuYfwi(ekgCslKr8nG1jWgI)OpNjaKZvElPgqeHtaQjweUUCzuNKxNC51LnaBm4uc4dfGaqox8dJVqK4dGCUYBj1aIiSWfz(EHfIpHIbN0czeFdyDcSH4hsIaRtPWqQUTskSduyorzPeHIbN01jxEDHKiW6ustHg3c9eHIbN0IFy8fIe)b5Sres5TKIKsyHlY8Dcle)W4lej(6fBhUPv8jum4KwiJWfUWf)O7TqG4)3gzVWfUqa]] )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "potion_of_unbridled_fury",

        package = "Outlaw",
    } )

    spec:RegisterSetting( "mfd_waste", true, {
        name = "Allow |T236364:0|t Marked for Death Combo Waste",
        desc = "If unchecked, the addon will not recommend |T236364:0|t Marked for Death if it will waste combo points.",
        type = "toggle",
        width = "full"
    } )  
end