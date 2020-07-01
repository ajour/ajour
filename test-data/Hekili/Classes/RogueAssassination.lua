-- RogueAssassination.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state =  Hekili.State

local PTR = ns.PTR

local FindUnitBuffByID = ns.FindUnitBuffByID
local IterateTargets, ActorHasDebuff = ns.iterateTargets, ns.actorHasDebuff


if UnitClassBase( 'player' ) == 'ROGUE' then
    local spec = Hekili:NewSpecialization( 259 )

    spec:RegisterResource( Enum.PowerType.ComboPoints )
    spec:RegisterResource( Enum.PowerType.Energy, {
        vendetta_regen = {
            aura = "vendetta_regen",

            last = function ()
                local app = state.buff.vendetta_regen.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = -3,
        },

        garrote_vim = {
            aura = "garrote",
            debuff = true,

            last = function ()
                local app = state.debuff.garrote.last_tick
                local exp = state.debuff.garrote.expires
                local tick = state.debuff.garrote.tick_time
                local t = state.query_time

                return min( exp, app + ( floor( ( t - app ) / tick ) * tick ) )
            end,

            stop = function ()
                return state.debuff.wound_poison_dot.down and state.debuff.deadly_poison_dot.down
            end,

            interval = function ()
                return state.debuff.garrote.tick_time
            end,

            value = 7
        },

        internal_bleeding_vim = {
            aura = "internal_bleeding",
            debuff = true,

            last = function ()
                local app = state.debuff.internal_bleeding.last_tick
                local exp = state.debuff.internal_bleeding.expires
                local tick = state.debuff.internal_bleeding.tick_time
                local t = state.query_time

                return min( exp, app + ( floor( ( t - app ) / tick ) * tick ) )
            end,

            stop = function ()
                return state.debuff.wound_poison_dot.down and state.debuff.deadly_poison_dot.down
            end,

            interval = function ()
                return state.debuff.internal_bleeding.tick_time
            end,

            value = 7
        },

        rupture_vim = {
            aura = "rupture",
            debuff = true,

            last = function ()
                local app = state.debuff.rupture.last_tick
                local exp = state.debuff.rupture.expires
                local tick = state.debuff.rupture.tick_time
                local t = state.query_time

                return min( exp, app + ( floor( ( t - app ) / tick ) * tick ) )
            end,

            stop = function ()
                return state.debuff.wound_poison_dot.down and state.debuff.deadly_poison_dot.down
            end,

            interval = function ()
                return state.debuff.rupture.tick_time
            end,

            value = 7
        },

        crimson_tempest_vim = {
            aura = "crimson_tempest",
            debuff = true,

            last = function ()
                local app = state.debuff.crimson_tempest.last_tick
                local exp = state.debuff.crimson_tempest.expires
                local tick = state.debuff.crimson_tempest.tick_time
                local t = state.query_time

                return min( exp, app + ( floor( ( t - app ) / tick ) * tick ) )
            end,

            stop = function ()
                return state.debuff.wound_poison_dot.down and state.debuff.deadly_poison_dot.down
            end,

            interval = function ()
                return state.debuff.crimson_tempest.tick_time
            end,

            value = 7
        },

        nothing_personal = {
            aura = "nothing_personal_regen",

            last = function ()
                local app = state.buff.nothing_personal_regen.applied
                local exp = state.buff.nothing_personal_regen.expires
                local tick = state.buff.nothing_personal_regen.tick_time
                local t = state.query_time

                return min( exp, app + ( floor( ( t - app ) / tick ) * tick ) )
            end,

            stop = function ()
                return state.buff.nothing_personal_regen.down
            end,

            interval = function ()
                return state.buff.nothing_personal_regen.tick_time
            end,

            value = 4
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        master_poisoner = 22337, -- 196864
        elaborate_planning = 22338, -- 193640
        blindside = 22339, -- 111240

        nightstalker = 22331, -- 14062
        subterfuge = 22332, -- 108208
        master_assassin = 23022, -- 255989

        vigor = 19239, -- 14983
        deeper_stratagem = 19240, -- 193531
        marked_for_death = 19241, -- 137619

        leeching_poison = 22340, -- 280716
        cheat_death = 22122, -- 31230
        elusiveness = 22123, -- 79008

        internal_bleeding = 19245, -- 154904
        iron_wire = 23037, -- 196861
        prey_on_the_weak = 22115, -- 131511

        venom_rush = 22343, -- 152152
        toxic_blade = 23015, -- 245388
        exsanguinate = 22344, -- 200806

        poison_bomb = 21186, -- 255544
        hidden_blades = 22133, -- 270061
        crimson_tempest = 23174, -- 121411
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3453, -- 214027
        gladiators_medallion = 3456, -- 208683
        relentless = 3461, -- 196029

        mindnumbing_poison = 137, -- 197050
        honor_among_thieves = 132, -- 198032
        maneuverability = 3448, -- 197000
        shiv = 131, -- 248744
        intent_to_kill = 130, -- 197007
        creeping_venom = 141, -- 198092
        flying_daggers = 144, -- 198128
        system_shock = 147, -- 198145
        death_from_above = 3479, -- 269513
        smoke_bomb = 3480, -- 212182
        neurotoxin = 830, -- 206328
    } )


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

    spec:RegisterStateExpr( "master_assassin_remains", function ()
        if not talent.master_assassin.enabled then return 0 end

        if stealthed.mantle then return cooldown.global_cooldown.remains + 3
        elseif buff.master_assassin.up then return buff.master_assassin.remains end
        return 0
    end )



    local stealth_dropped = 0


    local function isStealthed()
        return ( FindUnitBuffByID( "player", 1784 ) or FindUnitBuffByID( "player", 115191 ) or FindUnitBuffByID( "player", 115192 ) or FindUnitBuffByID( "player", 11327 ) or GetTime() - stealth_dropped < 0.2 )
    end


    local calculate_multiplier = setfenv( function( spellID )
        local mult = 1
        local stealth = isStealthed()

        if stealth then
            if talent.nightstalker.enabled then
                mult = mult * 1.5
            end

            -- Garrote.
            if talent.subterfuge.enabled and spellID == 703 then
                mult = mult * 1.8
            end
        end

        return mult
    end, state )


    -- index: unitGUID; value: isExsanguinated (t/f)
    local crimson_tempests = {}
    local ltCT = {}

    local garrotes = {}
    local ltG = {}
    local ssG = {}

    local internal_bleedings = {}
    local ltIB = {}

    local ruptures = {}
    local ltR = {}

    local snapshots = {
        [121411] = true,
        [703]    = true,
        [154953] = true,
        [1943]   = true
    }

    local death_events = {
        UNIT_DIED               = true,
        UNIT_DESTROYED          = true,
        UNIT_DISSIPATES        = true,
        PARTY_KILL              = true,
        SPELL_INSTAKILL         = true,
    }


    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function()
        local _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID then
            if subtype == 'SPELL_AURA_REMOVED' or subtype == 'SPELL_AURA_BROKEN' or subtype == 'SPELL_AURA_BROKEN_SPELL' then
                if spellID == 115191 or spellID == 1784 then
                    stealth_dropped = GetTime()
                
                elseif spellID == 703 then
                    ssG[ destGUID ] = nil

                end

            elseif snapshots[ spellID ] and ( subtype == 'SPELL_AURA_APPLIED'  or subtype == 'SPELL_AURA_REFRESH' or subtype == 'SPELL_AURA_APPLIED_DOSE' ) then
                    ns.saveDebuffModifier( spellID, calculate_multiplier( spellID ) )
                    ns.trackDebuff( spellID, destGUID, GetTime(), true )

                    if spellID == 121411 then
                        -- Crimson Tempest
                        crimson_tempests[ destGUID ] = false

                    elseif spellID == 703 then
                        -- Garrote
                        garrotes[ destGUID ] = false
                        ssG[ destGUID ] = state.azerite.shrouded_suffocation.enabled and isStealthed()

                    elseif spellID == 408 then
                        -- Internal Bleeding (from Kidney Shot)
                        internal_bleedings[ destGUID ] = false

                    elseif spellID == 1943 then
                        -- Rupture
                        ruptures[ destGUID ] = false
                    end
            
            elseif subtype == "SPELL_CAST_SUCCESS" and spellID == 200806 then
                -- Exsanguinate
                crimson_tempests[ destGUID ] = true
                garrotes[ destGUID ] = true
                internal_bleedings[ destGUID ] = true
                ruptures[ destGUID ] = true

            elseif subtype == "SPELL_PERIODIC_DAMAGE" then
                if spellID == 121411 then
                    ltCT[ destGUID ] = GetTime()

                elseif spellID == 703 then
                    ltG[ destGUID ] = GetTime()

                elseif spellID == 408 then
                    ltIB[ destGUID ] = GetTime()

                elseif spellID == 1943 then
                    ltR[ destGUID ] = GetTime()

                end
            end
        end

        if death_events[ subtype ] then
            ssG[ destGUID ] = nil
        end
    end )

    spec:RegisterHook( "UNIT_ELIMINATED", function( guid )
        ssG[ guid ] = nil
    end )

    spec:RegisterStateExpr( 'persistent_multiplier', function ()
        local mult = 1

        if not this_action then return mult end

        local stealth = buff.stealth.up or buff.subterfuge.up

        if stealth then
            if talent.nightstalker.enabled then
                mult = mult * 2
            end

            if talent.subterfuge.enabled and this_action == "garrote" then
                mult = mult * 1.8
            end
        end

        return mult
    end )

    spec:RegisterStateExpr( 'exsanguinated', function ()
        if not this_action then return false end
        local aura = this_action == "kidney_shot" and "internal_bleeding" or this_action

        return debuff[ aura ].exsanguinated == true
    end )

    -- Enemies with either Deadly Poison or Wound Poison applied.
    spec:RegisterStateExpr( 'poisoned_enemies', function ()
        return ns.countUnitsWithDebuffs( "deadly_poison_dot", "wound_poison_dot", "crippling_poison_dot" )
    end )

    spec:RegisterStateExpr( 'poison_remains', function ()
        return debuff.lethal_poison.remains
    end )

    -- Count of bleeds on targets.
    spec:RegisterStateExpr( 'bleeds', function ()
        local n = 0
        if debuff.garrote.up then n = n + 1 end
        if debuff.internal_bleeding.up then n = n + 1 end
        if debuff.rupture.up then n = n + 1 end
        if debuff.crimson_tempest.up then n = n + 1 end
        
        return n
    end )
    
    -- Count of bleeds on all poisoned (Deadly/Wound) targets.
    spec:RegisterStateExpr( 'poisoned_bleeds', function ()
        return ns.conditionalDebuffCount( "deadly_poison_dot", "wound_poison_dot", "garrote", "internal_bleeding", "rupture" )
    end )
    
    
    spec:RegisterStateExpr( "ss_buffed", function ()
        return debuff.garrote.ss_buffed or false
    end )

    spec:RegisterStateExpr( "non_ss_buffed_targets", function ()
        local count = ( debuff.garrote.down or not debuff.garrote.exsanguinated ) and 1 or 0

        for guid, counted in ns.iterateTargets() do
            if guid ~= target.unit and counted and ( not ns.actorHasDebuff( guid, 703 ) or not ssG[ guid ] ) then
                count = count + 1
            end
        end

        return count
    end )

    spec:RegisterStateExpr( "ss_buffed_targets_above_pandemic", function ()
        if not debuff.garrote.refreshable and debuff.garrote.ss_buffed then
            return 1
        end
        return 0 -- we aren't really tracking this right now...
    end )



    spec:RegisterStateExpr( "pmultiplier", function ()
        if not this_action then return 0 end

        local a = class.abilities[ this_action ]
        if not a then return 0 end

        local aura = a.aura or this_action
        if not aura then return 0 end

        if debuff[ aura ] and debuff[ aura ].up then
            return debuff[ aura ].pmultiplier or 1
        end

        return 0
    end )

    spec:RegisterStateExpr( "priority_rotation", function ()
        return settings.priority_rotation
    end )


    spec:RegisterHook( "reset_precast", function ()
        debuff.crimson_tempest.pmultiplier   = nil
        debuff.garrote.pmultiplier           = nil
        debuff.internal_bleeding.pmultiplier = nil
        debuff.rupture.pmultiplier           = nil

        debuff.crimson_tempest.exsanguinated   = nil -- debuff.crimson_tempest.up and crimson_tempests[ target.unit ]
        debuff.garrote.exsanguinated           = nil -- debuff.garrote.up and garrotes[ target.unit ]
        debuff.internal_bleeding.exsanguinated = nil -- debuff.internal_bleeding.up and internal_bleedings[ target.unit ]
        debuff.rupture.exsanguinated           = nil -- debuff.rupture.up and ruptures[ target.unit ]

        debuff.garrote.ss_buffed               = nil
    end )


    -- We need to break stealth when we start combat from an ability.
    spec:RegisterHook( "runHandler", function( ability )
        local a = class.abilities[ ability ]

        if stealthed.mantle and ( not a or a.startsCombat ) then
            if level < 116 and equipped.mantle_of_the_master_assassin then
                applyBuff( "master_assassins_initiative", 5 )
            end

            if talent.master_assassin.enabled then
                applyBuff( "master_assassin" )
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


    -- Auras
    spec:RegisterAuras( {
        blind = {
            id = 2094,
            duration = 60,
            max_stack = 1,
        },
        blindside = {
            id = 121153,
            duration = 10,
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
        crimson_tempest = {
            id = 121411,
            duration = 14,
            max_stack = 1,
            meta = {
                exsanguinated = function ( t ) return t.up and crimson_tempests[ target.unit ] end,                
                last_tick = function ( t ) return ltCT[ target.unit ] or t.applied end,
                tick_time = function( t ) return t.exsanguinated and haste or ( 2 * haste ) end,
            },                    
        },
        crimson_vial = {
            id = 185311,
            duration = 6,
            max_stack = 1,
        },
        crippling_poison = {
            id = 3408,
            duration = 3600,
            max_stack = 1,
        },
        crippling_poison_dot = {
            id = 3409,
            duration = 12,
            max_stack = 1,
        },
        deadly_poison = {
            id = 2823,
            duration = 3600,
            max_stack = 1,
        },
        deadly_poison_dot = {
            id = 2818,
            duration = function () return 12 * haste end,
            max_stack = 1,
        },  
        elaborate_planning = {
            id = 193641,
            duration = 4,
            max_stack = 1,
        },
        envenom = {
            id = 32645,
            duration = 4,
            type = "Poison",
            max_stack = 1,
        },
        evasion = {
            id = 5277,
            duration = 10,
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
        garrote = {
            id = 703,
            duration = 18,
            max_stack = 1,
            meta = {
                exsanguinated = function ( t ) return t.up and garrotes[ target.unit ] end,
                last_tick = function ( t ) return ltG[ target.unit ] or t.applied end,
                ss_buffed = function ( t ) return t.up and ssG[ target.unit ] end,
                tick_time = function ( t )
                    --if not talent.exsanguinate.enabled then return 2 * haste end
                    return t.exsanguinated and haste or ( 2 * haste ) end,
            },                    
        },
        garrote_silence = {
            id = 1330,
            duration = 3,
            max_stack = 1,
        },
        hidden_blades = {
            id = 270070,
            duration = 3600,
            max_stack = 20,
        },
        internal_bleeding = {
            id = 154953,
            duration = 6,
            max_stack = 1,
            meta = {
                exsanguinated = function ( t ) return t.up and internal_bleedings[ target.unit ] end,
                last_tick = function ( t ) return ltIB[ target.unit ] or t.applied end,
                tick_time = function ( t )
                    --if not talent.exsanguinate.enabled then return haste end
                    return t.exsanguinated and ( 0.5 * haste ) or haste end,
            },                    
        },
        kidney_shot = {
            id = 408,
            duration = 1,
            max_stack = 1,
        },
        lethal_poison = {
            alias = { "deadly_poison_dot", "wound_poison_dot" },
            aliasMode = "longest",
            aliasType = "debuff",
        },
        marked_for_death = {
            id = 137619,
            duration = 60,
            max_stack = 1,
        },
        master_assassin = {
            id = 256735,
            duration = 5,
            max_stack = 3,
        },
        master_assassins_initiative = {
            id = 235027,
            duration = 5,
            max_stack = 1,
        },
        prey_on_the_weak = {
            id = 255909,
            duration = 6,
            max_stack = 1,
        },
        rupture = {
            id = 1943,
            duration = function () return talent.deeper_stratagem.enabled and 28 or 24 end,
            max_stack = 1,
            meta = {
                exsanguinated = function ( t ) return t.up and ruptures[ target.unit ] end,
                last_tick = function ( t ) return ltR[ target.unit ] or t.applied end,
                tick_time = function ( t )
                    --if not talent.exsanguinate.enabled then return 2 * haste end
                    return t.exsanguinated and haste or ( 2 * haste ) end,
            },                    
        },
        seal_fate = {
            id = 14190,
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
        sign_of_battle = {
            id = 186403,
            duration = 3600,
            max_stack = 1,
        },
        sprint = {
            id = 2983,
            duration = 8,
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
        toxic_blade = {
            id = 245389,
            duration = 9,
            max_stack = 1,
        },
        tricks_of_the_trade = {
            id = 57934,
            duration = 30,
            max_stack = 1,
        },
        vanish = {
            id = 11327,
            duration = 3,
            max_stack = 1,
        },
        vendetta = {
            id = 79140,
            duration = 20,
            max_stack = 1,
        },
        vendetta_regen = {
            name = "Vendetta Regen",
            duration = 3,
            max_stack = 1,
            generate = function ()
                local cast = rawget( class.abilities.vendetta, "lastCast" ) or 0
                local up = cast + 3 > query_time

                local vr = buff.vendetta_regen

                if up then
                    vr.count = 1
                    vr.expires = cast + 15
                    vr.applied = cast
                    vr.caster = "player"
                    return
                end
                vr.count = 0
                vr.expires = 0
                vr.applied = 0
                vr.caster = "nobody"                
            end,
        },
        venomous_wounds = {
            id = 79134,
        },
        wound_poison = {
            id = 8679,
            duration = 3600,
            max_stack = 1,
        },
        wound_poison_dot = {
            id = 8680,
            duration = 12,
            max_stack = 1,
            no_ticks = true,
        },

        -- Azerite Powers
        nothing_personal = {
            id = 286581,
            duration = 20,
            tick_time = 2,
            max_stack = 1,
        },

        nothing_personal_regen = {
            id = 289467,
            duration = 20,
            tick_time = 2,
            max_stack = 1,
        },

        scent_of_blood = {
            id = 277731,
            duration = 24,            
        },

        sharpened_blades = {
            id = 272916,
            duration = 20,
            max_stack = 30
        },

        -- PvP Talents
        creeping_venom = {
            id = 198097,
            duration = 4,            
        },

        system_shock = {
            id = 198222,
            duration = 2,
        }
    } )

    -- Abilities
    spec:RegisterAbilities( {
        blind = {
            id = 2094,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = true,
            texture = 136175,

            handler = function ()
                applyDebuff( "target", "blind" )
                -- applies blind (2094)
            end,
        },


        blindside = {
            id = 111240,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.blindside.up and 0 or 30 end,
            spendType = "energy",

            startsCombat = true,
            texture = 236274,

            usable = function () return buff.blindside.up or target.health_pct < 30 end,
            handler = function ()
                gain( 1, "combo_points" )
                removeBuff( "blindside" )
            end,
        },


        cheap_shot = {
            id = 1833,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 40,
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
                applyDebuff( "target", "cheap_shot" )
                gain( 2, "combo_points" )

                if talent.prey_on_the_weak.enabled then applyDebuff( "target", "prey_on_the_weak" ) end
            end,
        },


        cloak_of_shadows = {
            id = 31224,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 136177,

            handler = function ()
                applyBuff( "cloak_of_shadows" )
            end,
        },


        crimson_tempest = {
            id = 121411,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = true,
            texture = 464079,

            talent = "crimson_tempest",
            aura = "crimson_tempest",
            cycle = "crimson_tempest",            

            usable = function () return combo_points.current > 0 end,

            handler = function ()
                applyDebuff( "target", "crimson_tempest", 2 + ( combo_points.current * 2 ) )
                debuff.crimson_tempest.pmultiplier = persistent_multiplier
                debuff.crimson_tempest.exsanguinated = false

                spend( combo_points.current, "combo_points" )

                if talent.elaborate_planning.enabled then applyBuff( "elaborate_planning" ) end
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
                applyBuff( "crimson_vial" )
            end,
        },


        crippling_poison = {
            id = 3408,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            essential = true,

            texture = 132274,
            nobuff = "crippling_poison",

            handler = function ()
                applyBuff( "crippling_poison" )
            end,
        },


        deadly_poison = {
            id = 2823,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            essential = true,
            texture = 132290,

            nobuff = "deadly_poison",

            handler = function ()
                applyBuff( "deadly_poison" )
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


        envenom = {
            id = 32645,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,

            spendType = "energy",

            startsCombat = true,
            texture = 132287,

            usable = function () return combo_points.current > 0 end,

            handler = function ()
                if pvptalent.system_shock.enabled then
                    if combo_points.current >= 5 and debuff.garrote.up and debuff.rupture.up and ( debuff.deadly_poison_dot.up or debuff.wound_poison_dot.up ) then
                        applyDebuff( "target", "system_shock", 2 )
                    end
                end

                if pvptalent.creeping_venom.enabled then
                    applyDebuff( "target", "creeping_venom" )
                end

                applyBuff( "envenom", 1 + combo_points.current )
                spend( combo_points.current, "combo_points" )

                if talent.elaborate_planning.enabled then applyBuff( "elaborate_planning" ) end

            end,
        },


        evasion = {
            id = 5277,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 136205,

            handler = function ()
                applyBuff( "evasion" )
            end,
        },


        exsanguinate = {
            id = 200806,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 25,
            spendType = "energy",

            startsCombat = true,
            texture = 538040,

            talent = "exsanguinate",

            handler = function ()
                if debuff.crimson_tempest.up then
                    debuff.crimson_tempest.expires = query_time + ( debuff.crimson_tempest.remains / 2 ) 
                    debuff.crimson_tempest.exsanguinated = true
                end

                if debuff.garrote.up then
                    debuff.garrote.expires = query_time + ( debuff.garrote.remains / 2 )
                    debuff.garrote.exsanguinated = true
                end

                if debuff.internal_bleeding.up then
                    debuff.internal_bleeding.expires = query_time + ( debuff.internal_bleeding.remains / 2 )
                    debuff.internal_bleeding.exsanguinated = true
                end

                if debuff.rupture.up then
                    debuff.rupture.expires = query_time + ( debuff.rupture.remains / 2 )
                    debuff.rupture.exsanguinated = true
                end
            end,
        },


        fan_of_knives = {
            id = 51723,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = true,
            texture = 236273,

            handler = function ()
                gain( 1, "combo_points" )
                removeBuff( "hidden_blades" )
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
                applyBuff( "feint" )
            end,
        },


        garrote = {
            id = 703,
            cast = 0,
            cooldown = function () return ( talent.subterfuge.enabled and ( buff.stealth.up or buff.subterfuge.up ) ) and 0 or 6 end,
            gcd = "spell",

            spend = 45,
            spendType = "energy",

            startsCombat = true,
            texture = 132297,

            aura = "garrote",
            cycle = "garrote",

            handler = function ()
                applyDebuff( "target", "garrote", min( debuff.garrote.remains + debuff.garrote.duration, 1.3 * debuff.garrote.duration ) )
                debuff.garrote.pmultiplier = persistent_multiplier
                debuff.garrote.exsanguinated = false

                gain( 1, "combo_points" )

                if stealthed.rogue then
                    applyDebuff( "target", "garrote_silence" ) 

                    if azerite.shrouded_suffocation.enabled then
                        gain( 2, "combo_points" )
                        debuff.garrote.ss_buffed = true
                    end
                end
            end,
        },


        kick = {
            id = 1766,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 132219,

            toggle = "interrupts",
            interrupt = true,

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

            spend = 25,
            spendType = "energy",

            startsCombat = true,
            texture = 132298,

            aura = "internal_bleeding",
            cycle = "internal_bleeding",

            usable = function () return combo_points.current > 0 end,
            handler = function ()
                if talent.internal_bleeding.enabled then
                    applyDebuff( "target", "internal_bleeding" )
                    debuff.internal_bleeding.pmultiplier = persistent_multiplier
                    debuff.internal_bleeding.exsanguinated = false
                end

                applyDebuff( "target", "kidney_shot", 1 + combo_points.current )
                spend( combo_points.current, "combo_points" )

                if talent.elaborate_planning.enabled then applyBuff( "elaborate_planning" ) end
            end,
        },


        marked_for_death = {
            id = 137619,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            -- toggle = "cooldowns",

            startsCombat = false,
            texture = 236364,

            usable = function ()
                return settings.mfd_waste or combo_points.current == 0, "combo_point (" .. combo_points.current .. ") waste not allowed"
            end,

            handler = function ()
                gain( 5, "combo_points" )
                applyDebuff( "target", "marked_for_death" )
            end,
        },


        mutilate = {
            id = 1329,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 50,
            spendType = "energy",

            startsCombat = true,
            texture = 132304,

            handler = function ()
                gain( 2, "combo_points" )

                if talent.venom_rush.enabled and ( debuff.deadly_poison_dot.up or debuff.wound_poison_dot.up or debuff.crippling_poison_dot.up ) then
                    gain( 5, "energy" )
                end
            end,
        },


        --[[ pick_lock = {
            id = 1804,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 136058,

            handler = function ()
            end,
        },


        pick_pocket = {
            id = 921,
            cast = 0,
            cooldown = 0.5,
            gcd = "spell",

            startsCombat = true,
            texture = 133644,

            handler = function ()
            end,
        }, ]]


        poisoned_knife = {
            id = 185565,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 40,
            spendType = "energy",

            startsCombat = true,
            texture = 1373909,

            handler = function ()
                removeBuff( "sharpened_blades" )
                gain( 1, "combo_points" )
            end,
        },


        rupture = {
            id = 1943,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 25,
            spendType = "energy",

            startsCombat = true,
            texture = 132302,

            aura = "rupture",
            cycle = "rupture",

            usable = function () return combo_points.current > 0 end,
            remains = function () return remains - ( duration * 0.3 ), remains - tick_time, remains - tick_time * 2, remains, cooldown.exsanguinate.remains - 1, 10 - time end,
            handler = function ()
                applyDebuff( "target", "rupture", min( dot.rupture.remains, class.auras.rupture.duration * 0.3 ) + 4 + ( 4 * combo_points.current ) )
                debuff.rupture.pmultiplier = persistent_multiplier
                debuff.rupture.exsanguinated = false

                if azerite.scent_of_blood.enabled then
                    applyBuff( "scent_of_blood", dot.rupture.remains )
                end

                spend( combo_points.current, "combo_points" )
            end,
        },


        sap = {
            id = 6770,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 35,
            spendType = "energy",

            startsCombat = true,
            texture = 132310,

            usable = function () return stealthed.all end,
            handler = function ()
                applyDebuff( "target", "sap" )
            end,
        },


        shadowstep = {
            id = 36554,
            cast = 0,
            charges = 1,
            cooldown = function ()
                if pvptalent.intent_to_kill.enabled and debuff.vendetta.up then return 10 end
                return 30
            end,
            recharge = function ()
                if pvptalent.intent_to_kill.enabled and debuff.vendetta.up then return 10 end
                return 30
            end,                
            gcd = "spell",

            startsCombat = false,
            texture = 132303,

            handler = function ()
                applyBuff( "shadowstep" )
                setDistance( 5 )
            end,
        },


        shroud_of_concealment = {
            id = 114018,
            cast = 0,
            cooldown = 360,
            gcd = "spell",

            startsCombat = false,
            texture = 635350,

            usable = function () return stealthed.all end,
            handler = function ()
                applyBuff( "shroud_of_concealment" )
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
                applyBuff( "sprint" )
            end,
        },


        stealth = {
            id = 1784,
            cast = 0,
            cooldown = 2,
            gcd = "spell",

            startsCombat = false,
            texture = 132320,

            usable = function () return time == 0 and not buff.stealth.up and not buff.vanish.up end,            
            handler = function ()
                applyBuff( "stealth" )
            end,
        },


        toxic_blade = {
            id = 245388,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            spend = 20,
            spendType = "energy",

            startsCombat = true,
            texture = 135697,

            talent = "toxic_blade",

            handler = function ()
                applyDebuff( "target", "toxic_blade" )
                gain( 1, "combo_points" )
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
                applyBuff( "vanish" )
                applyBuff( "stealth" )
            end,
        },


        vendetta = {
            id = 79140,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 458726,

            aura = "vendetta",

            handler = function ()
                applyDebuff( "target", "vendetta" )
                applyBuff( "vendetta_regen" )
                if azerite.nothing_personal.enabled then
                    applyDebuff( "target", "nothing_personal" )
                    applyBuff( "nothing_personal_regen" )
                end
            end,
        },

        wound_poison = {
            id = 8679,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            essential = true,

            texture = 134197,
            nobuff = "wound_poison",

            handler = function ()
                applyBuff( "wound_poison" )
            end,
        },


        apply_poison = {
            name = _G.MINIMAP_TRACKING_VENDOR_POISON,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            essential = true,

            texture = function ()
                if buff.deadly_poison.down and buff.wound_poison.down then return class.abilities.deadly_poison.texture end
                if buff.crippling_poison.down then return class.abilities.crippling_poison.texture end
            end,

            usable = function ()
                return ( buff.deadly_poison.down and buff.wound_poison.down and action.deadly_poison.known ) or
                    ( time == 0 and buff.crippling_poison.down and action.crippling_poison.known )
            end,

            handler = function ()
                if buff.deadly_poison.down and buff.wound_poison.down then applyBuff( "deadly_poison" )
                else applyBuff( "crippling_poison" ) end
            end,
        }


    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "potion_of_unbridled_fury",

        package = "Assassination",
    } )


    spec:RegisterSetting( "priority_rotation", false, {
        name = "Funnel AOE -> Target",
        desc = "If checked, the addon's default priority list will focus on funneling damage into your primary target when multiple enemies are present.",
        type = "toggle",
        width = 1.5
    } )

    spec:RegisterSetting( "envenom_pool_pct", 50, {
        name = "Energy % for |T132287:0|t Envenom",
        desc = "If set above 0, the addon will pool to this Energy threshold before recommending |T132287:0|t Envenom.",
        type = "range",
        min = 0,
        max = 100,
        step = 1,
        width = 1.5
    } )

    spec:RegisterStateExpr( "envenom_pool_deficit", function ()
        return energy.max * ( ( 100 - ( settings.envenom_pool_pct or 100 ) ) / 100 )
    end )

    spec:RegisterSetting( "mfd_waste", true, {
        name = "Allow |T236364:0|t Marked for Death Combo Waste",
        desc = "If unchecked, the addon will not recommend |T236364:0|t Marked for Death if it will waste combo points.",
        type = "toggle",
        width = "full"
    } )  


    spec:RegisterPack( "Assassination", 20200531, [[de1JbcqibXJiL0LuPaTjKQpPsbqJcfCkKsRcPiVcfAwKsDlvkAxu1VevmmvsDmvQwMkjpJuIPjO01evPTPsH(MOkQXjQcoNOkY6euO3PsbO5Ps4EiX(qs9pKcWbrkKfQs0drkktuLc6IifvBuqb5JifQgPkfqNuqrSsKKxkOintbfOBIuOStbvdvqrTuKc6POQPkiDvKcOTkQc9vvkamwbfu7vO)kYGL6Wuwmk9yvmzsUmyZQQplkJgv60kTAbfWRrfMnvUTa7wXVHmCs1XrkqlhXZHA6exxv2ok67IknEurNxuvRxLsZNuSFjhVhdnYRmbIHF11xD915vl393Vh2RUFpYl5RdrED7WHLbr(XcGipncJnmEhtw0e51T8DitfdnYJrpYbI8CfrhhgZjNSv4(y9huqo4n45mzrZHyFjh8gCYjYZ(wNeMmr2iVYeig(vxF11xNxTC3F)EyV668g5TNWfrI88BanlYZDvkyISrEfGprETwnncJnmEhtw0unneL9GIkTwnxr0XHXCYjBfUpw)bfKdEdEotw0Ci2xYbVbNCkQ0A10yw(vRL7Ax9vxF11fvfvATAAgxBYaCySOsRvFZQPrkfOQomDpCuTGQwbF75KQTJSOPA3IfFrLwR(MvtdHaetOAXizGK2VVOsRvFZQPrkfOQMgigQomrGaC1mGEcEvq1OF1ybmNWLwFrLwR(MvtZqdtGiGQAGtSnzVDmbu(WWvlOQviXhg2dCITj7TJjGYh5DlwWXqJ8ybmNWfuXqJHFpgAKhgJ1bQ4Lr(dzfGSwKxmhmIF2mUcwmhhaXdJX6av10R(GcyrjD0ocUAQPuDyRME1IrYaXlBaKeusTq13SAcey7GRM6QVXiVDKfnrEYtxEeikXWVkgAKhgJ1bQ4Lr(pIKgGtjg(9iVDKfnrEDeYLiag9ihikXW1sm0ipmgRduXlJ8hYkazTiVDlqwb8yUe0tbQe(9)OJjlA8WySoqvn9QzF)Vh)yfG8FzG)Pxn9QzF)Vh)yfG8FzGNab2o4QVO67ETun9QdPAmoX((Fqf5TJSOjYNzecsGOedpSXqJ8WySoqfVmY)rK0aCkXWVh5TJSOjYRJqUebWOh5arjgEEJHg5HXyDGkEzK3oYIMiFMriibI8hYkazTiVyoyep(Xka5)YapmgRduvtVAgQMab2o4QVO67xvTgnvRh8CYQ7wGu9fuQ(E10wn9QfJKbIx2aijOKAHQVz1eiW2bxn1vFvK)K)XbjXizGGJHFpkXWVXyOrEymwhOIxg5pKvaYArEXCWiE8JvaY)LbEymwhOQME12TazfWJ5sqpfOs43)JoMSOXdJX6av10RoKQviXtE6YJaEzpCStw10RMPrwJ1bE8ozoijgjdKiVDKfnrEYtxEeikXWZZXqJ8WySoqfVmY)rK0aCkXWVh5TJSOjYRJqUebWOh5arjgEEigAKhgJ1bQ4LrE7ilAI8zgHGeiYFiRaK1I8I5Gr84hRaK)ld8WySoqvn9QTBbYkGhZLGEkqLWV)hDmzrJhgJ1bQQPxndvBhzzcjyGGfWvtD13RwJMQdPAXCWiEGtSnzVDmb8WySoqvnTvtVAXizG4LnasckPwOAQRMab2o4QPxndvtGaBhC1xu998q1A0uDivJXj23)dQQPnYFY)4GKyKmqWXWVhLy45PyOrEymwhOIxg5)isAaoLy43J82rw0e51rixIay0JCGOed)(1XqJ8WySoqfVmYFiRaK1I8I5Gr84hRaK)ld8WySoqvn9QfZbJ4boX2K92XeWdJX6av10R2oYYesWablGRMs13RME1SV)3JFScq(VmWtGaBhC1xu9DVwI82rw0e5ZmcbjquIsKhWyyoaogAm87XqJ8WySoqfVmYFiRaK1I8WaKS89YgajbLcmoRM6QVxn9QdPAfW((FptyuGiM)Pxn9QzO6qQwHe)bnhyeIjGk9DwaKyFKXl7HJDYQME1HuTDKfn(dAoWietav67SaWVt672mUs1A0u9)5CjcC4AKmijBau9fvNDu(aJZQPnYBhzrtK)GMdmcXeqL(olaIsm8RIHg5HXyDGkEzK)qwbiRf5va77)9mHrbIy(NE10RMHQviXNzecsapWj2MS3oMaQQ1OPAfW((FVG4CpjwNPa)tVA6vFqbSOKoAhb7vWFpRu9fuQ(E1A0uTcyF)VNjmkqeZtGaBhC1xqP67xxnTvRrt1YgajbLulu9fuQ((1rE7ilAI8SoesLq)KWfsWab5hLy4AjgAKhgJ1bQ4Lr(dzfGSwK)Gqofk3XZegfiI5jqGTdU6lQwlvRrt1kG99)EMWOarm)tVAnAQwmsgiEzdGKGsQfQ(IQ1Y1rE7ilAI8zpJOwBsOFYUfiiHBuIHh2yOrEymwhOIxg5pKvaYAr(VdHivZq1muTyKmq8YgajbLulu9nRwlxxnTvFdwTDKfnPdc5uOCNQPTAQR(7qis1mundvlgjdeVSbqsqj1cvFZQ1Y1vFZQpiKtHYD8mHrbIyEcey7GRM2QVbR2oYIM0bHCkuUt10g5TJSOjYN9mIATjH(j7wGGeUrjgEEJHg5HXyDGkEzK)qwbiRf5X6GZLeJKbc2)TjH(joMLjGRMAkvFv1A0unXwvcycJ4nLc73PAQR(gVUA6vddqYYV6lQopFDK3oYIMi)hDEyqLSBbYkqIfSGOed)gJHg5HXyDGkEzK)qwbiRf5X6GZLeJKbc2)TjH(joMLjGRMAkvFv1A0unXwvcycJ4nLc73PAQR(gVoYBhzrtKx)r2F(7KLyDgwIsm88Cm0ipmgRduXlJ8hYkazTip77)9e4WHdW40hroG)PxTgnvZ((FpboC4amo9rKdKoO3iaXJf7Wr1xu99RJ82rw0e5fUq6nSO3OsFe5arjgEEigAK3oYIMipz11DqANew3oqKhgJ1bQ4LrjgEEkgAK3oYIMiFUiItXe2jramAS5arEymwhOIxgLy43VogAKhgJ1bQ4Lr(dzfGSwKhgGKLF1xuDEVUA6vhs1heYPq5oEMWOarm)tpYBhzrtKpacqK8tOFY9oRkPiGfGJsm873JHg5HXyDGkEzK3oYIMipbm9DYsFNfa4i)HScqwlYlgjdeVSbqsqj1cvFr1395TAnAQMHQzOAXizG45cMt461ps1uxDE46Q1OPAXizG45cMt461ps1xqP6RUUAARME1muTDKLjKGbcwaxnLQVxTgnvlgjdeVSbqsqj1cvtD1xLNQM2QPTAnAQMHQfJKbIx2aijOK(rsxDD1uxTwUUA6vZq12rwMqcgiybC1uQ(E1A0uTyKmq8YgajbLulun1vh2WwnTvtBK)K)XbjXizGGJHFpkrjYRGV9Csm0y43JHg5HXyDGkEzK)qwbiRf5dPASaMt4ckV5CrE7ilAI8CShoIsm8RIHg5TJSOjYJfWCc3ipmgRduXlJsmCTednYdJX6av8YipspYJbjYBhzrtKNPrwJ1brEMM7brEyasw(EcKbt1mwToAXObujwhakC10u155QVbRMHQVQAAQASo4CjUgwGQPnYZ0iPXcGipmajl)ebYGjDqbS7aQOedpSXqJ8WySoqfVmYJ0J8yqI82rw0e5zAK1yDqKNP5EqKhRdoxsmsgiy)3Me6N4ywMaU6lQ(QiptJKglaI84DYCqsmsgirjgEEJHg5HXyDGkEzK)qwbiRf5XcyoHlO8eu2dI82rw0e5pMZLSJSOj5wSe5DlwsJfarESaMt4cQOed)gJHg5HXyDGkEzK)qwbiRf5zO6qQwmhmIpWWcqsggBy8oEymwhOQwJMQviXNzecsaVSho2jRAAJ82rw0e5pMZLSJSOj5wSe5DlwsJfar(JchLy455yOrEymwhOIxg5TJSOjYFmNlzhzrtYTyjY7wSKglaI8kKeLy45HyOrEymwhOIxg5TJSOjYFmNlzhzrtYTyjY7wSKglaI8QLahjkXWZtXqJ8WySoqfVmYFiRaK1I8WaKS89k4VNvQMAkvFpVvZy1mnYASoWddqYYprGmyshua7oGkYBhzrtK3ihBGKGieyKOed)(1XqJ82rw0e5nYXgiP)CyiYdJX6av8YOed)(9yOrE7ilAI8UnJRGtHbEQSayKipmgRduXlJsm87xfdnYBhzrtKN1YsOFsi7HdCKhgJ1bQ4LrjkrEDcCqbSMedng(9yOrE7ilAI8MUUl)KoAXOjYdJX6av8YOed)QyOrEymwhOIxg5TJSOjYhyeoav6Jijfyc3i)HScqwlYtSvLaMWiEtPW(DQM6QVN3iVoboOawtsy4GgfoYN3OedxlXqJ82rw0e5XcyoHBKhgJ1bQ4LrjgEyJHg5HXyDGkEzKFSaiYB3I5AedN(OrsOFshLlqI82rw0e5TBXCnIHtF0ij0pPJYfirjgEEJHg5TJSOjYRJKfnrEymwhOIxgLOe5vlbosm0y43JHg5HXyDGkEzK)qwbiRf5pOawushTJGRMAkvh2QzSAXCWiEfa6ajHfIjwge4HXyDGQA6vZq1kG99)EMWOarm)tVAnAQwbSV)3lio3tI1zkW)0RwJMQHbiz57vWFpRu9fuQMHQHHjmOGKoc5sk4VNvQMAAavZq1xL3QzSAMgznwh4Hbiz5NiqgmPdkGDhqvnTvtB1A0uDivZ0iRX6apENmhKeJKbs10wn9QzO6qQwmhmIh4eBt2BhtapmgRduvRrt1heYPq5oEGtSnzVDmb8eiW2bxn1vFv10g5TJSOjYddtyqbrjg(vXqJ8WySoqfVmYJ0J8yqI82rw0e5zAK1yDqKNP5EqK)GcyrjD0oc2RG)EwPAQR(E1A0unmajlFVc(7zLQVGs1xL3QzSAMgznwh4Hbiz5NiqgmPdkGDhqvTgnvhs1mnYASoWJ3jZbjXizGe5zAK0ybqK)HH0FDoGeLy4AjgAKhgJ1bQ4Lr(dzfGSwKNPrwJ1b(hgs)15as10R2UfiRaE4WfTtwI1zka7HXyDGQA6vJ1bNljgjdeS)Btc9tCmltaxn1uQ(QQzSAgQwbSV)3ZegfiI5F6vttvZq13RMXQzOA7wGSc4Hdx0ozjwNPaSNydhvtP67vtB10wnTrE7ilAI8FBsOFIJzzc4OedpSXqJ8WySoqfVmYFiRaK1I8mnYASoW)Wq6VohqQME1mun77)9CxLcMeRZua2Jf7Wr1utP675PQ1OPAgQoKQ1jlISs(jcsmzrt10RgRdoxsmsgiy)3Me6N4ywMaUAQPuDyRMXQzOA7wGSc4vOhRdskeg8eB4OAQR(QQPTAgRglG5eUGYtqzpOAARM2iVDKfnr(Vnj0pXXSmbCuIHN3yOrEymwhOIxg5TJSOjY)TjH(joMLjGJ8hYkazTiptJSgRd8pmK(RZbKQPxnwhCUKyKmqW(Vnj0pXXSmbC1utPATe5p5FCqsmsgi4y43Jsm8BmgAKhgJ1bQ4Lr(dzfGSwKNPrwJ1b(hgs)15as10RMHQzF)VN1TJcVkW)0RwJMQdPAXCWiEMWGcsKhMRhgJ1bQQPxDivB3cKvaVc9yDqsHWGhgJ1bQQPnYBhzrtKN1TJcVkikXWZZXqJ8WySoqfVmYBhzrtKp4jRZeiYFiRaK1I8mnYASoW)Wq6VohqQME1yDW5sIrYab7)2Kq)ehZYeWvtP6RI8N8poijgjdeCm87rjgEEigAKhgJ1bQ4Lr(dzfGSwKNPrwJ1b(hgs)15asK3oYIMiFWtwNjquIsK)OWXqJHFpgAKhgJ1bQ4LrE7ilAI82TyUgXWPpAKe6N0r5cKi)HScqwlYhs1ybmNWfuEZ5QME1bgwasYWydJ3jrGaBhC1uQ(6QPxndvFqiNcL74zcJceX8eiW2bx9f0aQMHQpiKtHYD8cIZ9KyDMc8eiW2bxnnvnqd(wDDq5nmxM2a4eXUfrsheXCvtB10w9fvF)6QzS67xxnnvnqd(wDDq5nmxM2a4eXUfrsheXCvtV6qQwbSV)3ZegfiI5F6vtV6qQwbSV)3lio3tI1zkW)0J8JfarE7wmxJy40hnsc9t6OCbsuIHFvm0ipmgRduXlJ8hYkazTiFivJfWCcxq5nNRA6vRqIN80Lhb8YE4yNSQPxDGHfGKmm2W4DseiW2bxnLQVoYBhzrtK)yoxYoYIMKBXsK3Tyjnwae5bmgMdGJsmCTednYdJX6av8YiVDKfnr(aJWbOsFejPat4g5pKvaYArEITQeWegXBkf2)0RME1muTyKmq8YgajbLulu9fvFqbSOKoAhb7vWFpRunnv9DFERwJMQpOawushTJG9k4VNvQMAkvF0tbgNjSomQQPnYFY)4GKyKmqWXWVhLy4HngAKhgJ1bQ4Lr(dzfGSwKNyRkbmHr8MsH97un1vRLRR(MvtSvLaMWiEtPWE1JyYIMQPx9bfWIs6ODeSxb)9Ss1utP6JEkW4mH1Hrf5TJSOjYhyeoav6Jijfyc3OedpVXqJ8WySoqfVmYJ0J8yqI82rw0e5zAK1yDqKNP5EqKpKQfZbJ4Xpwbi)xg4HXyDGQAnAQoKQTBbYkGhZLGEkqLWV)hDmzrJhgJ1bQQ1OPAfs8zgHGeWRh8CYQ7wGun1vFVA6vZq1yDW5sIrYab7)2Kq)ehZYeWvFr13y1A0uDivFqiNcL74zAZI56F6vtBKNPrsJfarEMWOarSe(Xka5)YG0bnQvw0eLy43ym0ipmgRduXlJ8i9ipgKiVDKfnrEMgznwhe5zAUhe5dPAXCWi(zZ4kyXCCaepmgRduvRrt1HuTyoyepWj2MS3oMaEymwhOQwJMQpiKtHYD8aNyBYE7yc4jqGTdU6lQoVvFZQVQAAQAXCWiEfa6ajHfIjwge4HXyDGkYZ0iPXcGiptyuGiwA2mUcwmhhajDqJALfnrjgEEogAKhgJ1bQ4LrEKEKhdsK3oYIMiptJSgRdI8mn3dI8Hunqd(wDDq5TBXCnIHtF0ij0pPJYfivRrt12TazfWJ5sqpfOs43)JoMSOXdJX6av1A0uTcyF)VNy3IiPdIyUKcyF)VxHYDQwJMQpiKtHYD8gMltBaCIy3IiPdIyopbcSDWvFr13VUA6vZq1heYPq5oEbX5EsSotbEcey7GR(IQVxTgnvRa23)7feN7jX6mf4F6vtBKNPrsJfarEMWOarS0hns6Gg1klAIsm88qm0ipmgRduXlJ8hYkazTiFivJfWCcxq5jOShun9QviXtE6YJaEzpCStw10RoKQva77)9mHrbIy(NE10RMPrwJ1bEMWOarSe(Xka5)YG0bnQvw0un9QzAK1yDGNjmkqelnBgxblMJdGKoOrTYIMQPxntJSgRd8mHrbIyPpAK0bnQvw0e5TJSOjYZegfiIfLy45PyOrEymwhOIxg5pKvaYArEXCWiEGtSnzVDmb8WySoqvn9QfZbJ4NnJRGfZXbq8WySoqvn9QpOawushTJGRMAkvF0tbgNjSomQQPx9bHCkuUJh4eBt2BhtapbcSDWvFr13J82rw0e5zAZI5gLy43VogAKhgJ1bQ4Lr(dzfGSwKxmhmIF2mUcwmhhaXdJX6av10RoKQfZbJ4boX2K92XeWdJX6av10R(GcyrjD0ocUAQPu9rpfyCMW6WOQME1muTcyF)VNjmkqeZ)0RwJMQbmgMd4zU4fnj0pPdKpCKfnEymwhOQM2iVDKfnrEM2SyUrjg(97XqJ8WySoqfVmYJ0J8yqI82rw0e5zAK1yDqKNP5EqK3UfiRaEmxc6Pavc)(F0XKfnEymwhOQME1mu9GMegNyF)pOsIrYabxn1uQ(E1A0unwhCUKyKmqW(Vnj0pXXSmbC1uQwlvtB10RMHQX4e77)bvsmsgi4KXIycjDBuqWEQMs1xxTgnvJ1bNljgjdeS)Btc9tCmltaxn1uQ(gRM2iptJKglaI8yCIPnlMB6Gg1klAIsm87xfdnYdJX6av8YiVDKfnrEDeYLiag9ihiYdCkelzbO3ir(WM3i)hrsdWPed)EuIHFxlXqJ8WySoqfVmYFiRaK1I8I5Gr84hRaK)ld8WySoqvn9QdPASaMt4ckpbL9GQPx9bHCkuUJpZieKa(NE10RMHQzAK1yDGhJtmTzXCth0Owzrt1A0uDivB3cKvapMlb9uGkHF)p6yYIgpmgRduvtVAgQwHeFMriib8e4tamxJ1bvRrt1kG99)EMWOarm)tVA6vRqIpZieKaE9GNtwD3cKQVGs13RM2QPTA6vFqbSOKoAhb7vWFpRun1uQMHQzO67vZy1xvnnvTDlqwb8yUe0tbQe(9)OJjlA8WySoqvnTvttvJ1bNljgjdeS)Btc9tCmltaxnTvtnnGQdB10RMyRkbmHr8MsH97un1vF)QiVDKfnrEM2SyUrjg(9WgdnYdJX6av8Yi)HScqwlYlMdgXhyybijdJnmEhpmgRduvtV6qQglG5eUGYBox10RoWWcqsggBy8ojcey7GR(ckvFD10RoKQviXtE6YJaEc8jaMRX6GQPxTcj(mJqqc4jqGTdUAQRwlvtVAgQwbSV)3ZegfiI5F6vtVAgQoKQfZbJ4feN7jX6mf4HXyDGQAnAQwbSV)3lio3tI1zkW)0RM2QPxndvhs1agdZb8SoesLq)KWfsWab57dSWais1A0uTcyF)VN1HqQe6NeUqcgiiF)tVAARwJMQbmgMd4zU4fnj0pPdKpCKfnEymwhOQM2iVDKfnrEM2SyUrjg(98gdnYdJX6av8Yi)HScqwlYhs1ybmNWfuEZ5QME12TazfWJ5sqpfOs43)JoMSOXdJX6av10RwHeFMriib8e4tamxJ1bvtVAfs8zgHGeWRh8CYQ7wGu9fuQ(E10R(GcyrjD0oc2RG)EwPAQPu99iVDKfnrEmxtHYnaCQOed)(ngdnYdJX6av8Yi)HScqwlYhs1ybmNWfuEck7bvtVAgQoKQviXNzecsapb(eaZ1yDq10RwHep5Plpc4jqGTdUAQRoSvZy1HTAAQ6JEkW4mH1HrvTgnvRqIN80Lhb8eiW2bxnnv91(8wn1vlgjdeVSbqsqj1cvtB10RwmsgiEzdGKGsQfQM6QdBK3oYIMipWj2MS3oMarjg(98Cm0ipmgRduXlJ8hYkazTiVcjEYtxEeWl7HJDYQME1muDivd0GVvxhuE7wmxJy40hnsc9t6OCbs1A0u9bHCkuUJNjmkqeZtGaBhC1ux99RRM2iVDKfnrEbX5EsSotbrjg(98qm0ipmgRduXlJ8hYkazTip77)9Soes5EyXta7ivRrt1kG99)EMWOarm)tpYBhzrtKxhjlAIsm875PyOrEymwhOIxg5pKvaYArEfW((FptyuGiM)Ph5TJSOjYZ6qiv6)i5hLy4xDDm0ipmgRduXlJ8hYkazTiVcyF)VNjmkqeZ)0J82rw0e5zbcgiCStwuIHF19yOrEymwhOIxg5pKvaYArEfW((FptyuGiM)Ph5TJSOjY)xcW6qivuIHF1vXqJ8WySoqfVmYFiRaK1I8kG99)EMWOarm)tpYBhzrtK3MdGfI5shZ5Ism8R0sm0ipmgRduXlJ82rw0e5ZmhCmNdi4elcnr(dzfGSwKNHQva77)9mHrbIy(NE1A0undvhs1I5Gr8aNyBYE7yc4HXyDGQA6vFqiNcL74zcJceX8eiW2bxn1vh28wTgnvlMdgXdCITj7TJjGhgJ1bQQPxndvFqiNcL74boX2K92XeWtGaBhC1xu9nwTgnvFqiNcL74boX2K92XeWtGaBhC1ux9vxxn9Q)BgxjrGaBhC1ux9nM3QPTAARM2QPxDivRqIN80Lhb8aNyBYE7ycOI8Jfar(mZbhZ5acoXIqtuIHFvyJHg5HXyDGkEzK3oYIMiVH5Y0gaNi2Tis6GiMlYFiRaK1I8kG99)EIDlIKoiI5skG99)Efk3PAnAQw2aijOKAHQVO6RUoYpwae5nmxM2a4eXUfrsheXCrjg(v5ngAKhgJ1bQ4LrE7ilAI8gMltBaCIy3IiPdIyUi)HScqwlYZq1HuTyoyepWj2MS3oMaEymwhOQwJMQdPAXCWiE8JvaY)LbEymwhOQM2QPxTcyF)VNjmkqeZtGaBhC1ux99RR(Mvh2QPPQbAW3QRdkVDlMRrmC6JgjH(jDuUajYpwae5nmxM2a4eXUfrsheXCrjg(v3ym0ipmgRduXlJ82rw0e5nmxM2a4eXUfrsheXCr(dzfGSwKNHQfZbJ4boX2K92XeWdJX6av10RwmhmIh)yfG8FzGhgJ1bQQPTA6vRa23)7zcJceX8p9QPxndvRqIpZieKaEGtSnzVDmbuvRrt12TazfWJ5sqpfOs43)JoMSOXdJX6av10RwHeFMriib86bpNS6UfivtD13RM2i)ybqK3WCzAdGte7wejDqeZfLy4xLNJHg5HXyDGkEzK3oYIMi)j)Jdje0SNeRZWsK)qwbiRf5dmSaKKHXggVtIab2o4QPu91vtV6qQwbSV)3ZegfiI5F6vtV6qQwbSV)3lio3tI1zkW)0RME1SV)3habis(j0p5ENvLueWcWEfk3PA6vddqYYV6lQopCD10RwHep5Plpc4jqGTdUAQRoSrE4)HJKglaI8N8poKqqZEsSodlrjg(v5HyOrEymwhOIxg5TJSOjY7EeoacoTdEvl6Htz7xI8hYkazTiVcyF)VNjmkqeZ)0J8JfarE3JWbqWPDWRArpCkB)suIHFvEkgAKhgJ1bQ4LrE7ilAI8UhwiOhoLHCkys6UxGLbr(dzfGSwKxbSV)3ZegfiI5F6r(XcGiV7Hfc6HtziNcMKU7fyzquIHRLRJHg5HXyDGkEzK3oYIMiFMZuRjicofakZ5w0e5pKvaYArEfW((FptyuGiM)Ph5H)hosASaiYN5m1AcIGtbGYCUfnrjgUwUhdnYdJX6av8YiVDKfnr(mNPwtqeCI1uzqK)qwbiRf5va77)9mHrbIy(NEKh(F4iPXcGiFMZuRjicoXAQmikXW1YvXqJ82rw0e5FyiTceGJ8WySoqfVmkrjYRqsm0y43JHg5HXyDGkEzKhPh5XGe5TJSOjYZ0iRX6GiptZ9GiVozrKvYprqIjlAQME1yDW5sIrYab7)2Kq)ehZYeWvtD1APA6vZq1kK4ZmcbjGNab2o4QVO6dc5uOChFMriib8QhXKfnvRrt16OfJgqLyDaOWvtD15TAAJ8mnsASaiYJ5y1tN8poiLzecsGOed)QyOrEymwhOIxg5r6rEmirE7ilAI8mnYASoiYZ0CpiYRtwezL8teKyYIMQPxnwhCUKyKmqW(Vnj0pXXSmbC1uxTwQME1muTcyF)VxqCUNeRZuG)PxTgnvZq16OfJgqLyDaOWvtD15TA6vhs12TazfWJpWij0pX6qiLhgJ1bQQPTAAJ8mnsASaiYJ5y1tN8poirE6YJarjgUwIHg5HXyDGkEzKhPh5XGe5TJSOjYZ0iRX6GiptZ9GiVcyF)VNjmkqeZ)0RME1muTcyF)VxqCUNeRZuG)PxTgnvhyybijdJnmENebcSDWvtD1xxnTvtVAfs8KNU8iGNab2o4QPU6RI8mnsASaiYJ5y1tKNU8iquIHh2yOrEymwhOIxg5pKvaYArEXCWiEGtSnzVDmb8WySoqvn9QdPAGtSnzVDmbuvtVAfs8zgHGeWRh8CYQ7wGu9fuQ(E10R(Gqofk3XdCITj7TJjGNab2o4QVO6RQME1yDW5sIrYab7)2Kq)ehZYeWvtP67vtVAITQeWegXBkf2Vt1ux9nwn9QviXNzecsapbcSDWvttvFTpVvFr1IrYaXlBaKeusTqK3oYIMiFMriibIsm88gdnYdJX6av8Yi)HScqwlYlMdgXdCITj7TJjGhgJ1bQQPxndvFqbSOKoAhbxn1uQ(ONcmotyDyuvtV6dc5uOChpWj2MS3oMaEcey7GR(IQVxn9QviXtE6YJaEcey7GRMMQ(AFER(IQfJKbIx2aijOKAHQPnYBhzrtKN80LhbIsm8BmgAKhgJ1bQ4Lr(pIKgGtjg(9iVDKfnrEDeYLiag9ihikXWZZXqJ8WySoqfVmYFiRaK1I8e4tamxJ1bvtV6dkGfL0r7iyVc(7zLQPMs13RMXQ1s10u1muTDlqwb8yUe0tbQe(9)OJjlA8WySoqvn9QpiKtHYD8mTzXC9p9QPTA6vZq16bpNS6UfivFbLQVxTgnvtGaBhC1xqPAzpCKKnaQME1yDW5sIrYab7)2Kq)ehZYeWvtnLQ1s1mwTDlqwb8yUe0tbQe(9)OJjlA8WySoqvnTvtVAgQoKQboX2K92XeqvTgnvtGaBhC1xqPAzpCKKnaQMMQ(QQPxnwhCUKyKmqW(Vnj0pXXSmbC1utPATunJvB3cKvapMlb9uGkHF)p6yYIgpmgRduvtB10RoKQX4e77)bv10RMHQfJKbIx2aijOKAHQVz1eiW2bxnTvtD1HTA6vZq1bgwasYWydJ3jrGaBhC1uQ(6Q1OP6qQw2dh7Kvn9QTBbYkGhZLGEkqLWV)hDmzrJhgJ1bQQPnYBhzrtKpZieKarjgEEigAKhgJ1bQ4Lr(pIKgGtjg(9iVDKfnrEDeYLiag9ihikXWZtXqJ8WySoqfVmYBhzrtKpZieKar(dzfGSwKpKQzAK1yDGhZXQNo5FCqkZieKavtVAc8jaMRX6GQPx9bfWIs6ODeSxb)9Ss1utP67vZy1APAAQAgQ2UfiRaEmxc6Pavc)(F0XKfnEymwhOQME1heYPq5oEM2SyU(NE10wn9QzOA9GNtwD3cKQVGs13RwJMQjqGTdU6lOuTShosYgavtVASo4CjXizGG9FBsOFIJzzc4QPMs1APAgR2UfiRaEmxc6Pavc)(F0XKfnEymwhOQM2QPxndvhs1aNyBYE7ycOQwJMQjqGTdU6lOuTShosYgavttvFv10RgRdoxsmsgiy)3Me6N4ywMaUAQPuTwQMXQTBbYkGhZLGEkqLWV)hDmzrJhgJ1bQQPTA6vhs1yCI99)GQA6vZq1IrYaXlBaKeusTq13SAcey7GRM2QPU67xvn9QzO6adlajzySHX7KiqGTdUAkvFD1A0uDivl7HJDYQME12TazfWJ5sqpfOs43)JoMSOXdJX6av10g5p5FCqsmsgi4y43Jsm87xhdnYdJX6av8Yi)HScqwlYJ1bNljgjdeC1utP6RQME1eiW2bx9fvFv1mwndvJ1bNljgjdeC1utP68wnTvtV6dkGfL0r7i4QPMs1HnYBhzrtK)q2amAsceOdyjkXWVFpgAKhgJ1bQ4Lr(dzfGSwKpKQzAK1yDGhZXQNipD5rGQPxndvFqbSOKoAhbxn1uQoSvtVAc8jaMRX6GQ1OP6qQw2dh7Kvn9QzOAzdGQPU67xxTgnvFqbSOKoAhbxn1uQ(QQPTAARME1muTEWZjRUBbs1xqP67vRrt1eiW2bx9fuQw2dhjzdGQPxnwhCUKyKmqW(Vnj0pXXSmbC1utPATunJvB3cKvapMlb9uGkHF)p6yYIgpmgRduvtB10RMHQdPAGtSnzVDmbuvRrt1eiW2bx9fuQw2dhjzdGQPPQVQA6vJ1bNljgjdeS)Btc9tCmltaxn1uQwlvZy12TazfWJ5sqpfOs43)JoMSOXdJX6av10wn9QfJKbIx2aijOKAHQVz1eiW2bxn1vh2iVDKfnrEYtxEeikXWVFvm0ipmgRduXlJ82rw0e5jpD5rGi)HScqwlYhs1mnYASoWJ5y1tN8poirE6YJavtV6qQMPrwJ1bEmhREI80LhbQME1hualkPJ2rWvtnLQdB10RMaFcG5ASoOA6vZq16bpNS6UfivFbLQVxTgnvtGaBhC1xqPAzpCKKnaQME1yDW5sIrYab7)2Kq)ehZYeWvtnLQ1s1mwTDlqwb8yUe0tbQe(9)OJjlA8WySoqvnTvtVAgQoKQboX2K92XeqvTgnvtGaBhC1xqPAzpCKKnaQMMQ(QQPxnwhCUKyKmqW(Vnj0pXXSmbC1utPATunJvB3cKvapMlb9uGkHF)p6yYIgpmgRduvtB10RwmsgiEzdGKGsQfQ(MvtGaBhC1uxDyJ8N8poijgjdeCm87rjg(DTednYdJX6av8Yi)HScqwlYJ1bNljgjdeC1uQ(E10R(GcyrjD0ocUAQPundvF0tbgNjSomQQVz13RM2QPxnb(eaZ1yDq10RoKQboX2K92Xeqvn9QdPAfW((FVG4CpjwNPa)tVA6vhyybijdJnmENebcSDWvtP6RRME1HuTDlqwb8sUlwscxiXXSFWdJX6av10RwmsgiEzdGKGsQfQ(MvtGaBhC1uxDyJ82rw0e5pKnaJMKab6awIsuIsKNjqWlAIHF11xD91Arlxh5Z1iZoz4iFysGoIiGQ68C12rw0uTBXc2xuf51jO)6GiVwRMgHXggVJjlAQMgIYEqrLwRMRi64Wyo5KTc3hR)GcYbVbpNjlAoe7l5G3GtofvATAAml)Q1YDTR(QRV66IQIkTwnnJRnzaomwuP1QVz10iLcuvhMUhoQwqvRGV9Cs12rw0uTBXIVOsRvFZQPHqaIjuTyKmqs73xuP1QVz10iLcuvtdedvhMiqaUAgqpbVkOA0VASaMt4sRVOsRvFZQPzOHjqeqvnWj2MS3oMakFy4Qfu1kK4dd7boX2K92Xeq5lQkQ0A10CoHZtav1SWhrGQpOawtQMfY2b7RMgDoGUGREqZn5AKG)ZvTDKfn4QrJlFFrLwR2oYIgSxNahuaRju(odZrrLwR2oYIgSxNahuaRjmsjh7LfaJyYIMIkTwTDKfnyVoboOawtyKsoFesvuP1Q5hthZfjvtSvvn77)bv1yXeC1SWhrGQpOawtQMfY2bxTnQQ1jWn1rIStw1lUAfAaFrLwR2oYIgSxNahuaRjmsjh8y6yUijHftWfv2rw0G96e4GcynHrk5y66U8t6OfJMIk7ilAWEDcCqbSMWiLCcmchGk9rKKcmHR26e4GcynjHHdAuyk5v79tHyRkbmHr8MsH97q998wuzhzrd2RtGdkG1egPKdwaZjClQSJSOb71jWbfWAcJuY5HH0kqG2JfauSBXCnIHtF0ij0pPJYfifv2rw0G96e4GcynHrk5OJKfnfvfvATAAoNW5jGQAGjqYVAzdGQfUq12rqKQxC1gtBDgRd8fvATAAiGfWCc3Q3F16imEzDq1mmOQz(CdqmwhunmqWc4Q3P6dkG1eAlQSJSObtHJ9WH27NsiybmNWfuEZ5kQSJSObZiLCWcyoHBrLDKfnygPKdtJSgRd0ESaGcmajl)ebYGjDqbS7akTzAUhqbgGKLVNazWWOoAXObujwhakmnLNVbz4kAcRdoxIRHfG2Ik7ilAWmsjhMgznwhO9ybaf8ozoijgjdeTzAUhqbRdoxsmsgiy)3Me6N4ywMa(IRkQSJSObZiLCoMZLSJSOj5wSO9ybafSaMt4ckT3pfSaMt4ckpbL9GIk7ilAWmsjNJ5Cj7ilAsUflApwaq5OWAVFkmeIyoyeFGHfGKmm2W4D8WySoqPrJcj(mJqqc4L9WXoz0wuzhzrdMrk5CmNlzhzrtYTyr7XcakkKuuzhzrdMrk5CmNlzhzrtYTyr7XcakQLahPOYoYIgmJuYXihBGKGieyeT3pfyasw(Ef83Zkut5EEzKPrwJ1bEyasw(jcKbt6Gcy3bufv2rw0GzKsog5ydK0FomuuzhzrdMrk542mUcofg4PYcGrkQSJSObZiLCyTSe6NeYE4axuvuP1QPziKtHYDWfv2rw0G9hfMYddPvGaThlaOy3I5AedN(OrsOFshLlq0E)ucblG5eUGYBoh9adlajzySHX7KiqGTdMY10z4Gqofk3XZegfiI5jqGTd(cAamCqiNcL74feN7jX6mf4jqGTdMMaAW3QRdkVH5Y0gaNi2Tis6GiMJwAV4(1mE)AAcObFRUoO8gMltBaCIy3IiPdIyo6HOa23)7zcJceX8pD6HOa23)7feN7jX6mf4F6fv2rw0G9hfMrk5CmNlzhzrtYTyr7XcakagdZbWAVFkHGfWCcxq5nNJUcjEYtxEeWl7HJDYOhyybijdJnmENebcSDWuUUOsRvhM8R2ukC1gbQ(PRD14z1HQfUq1ObQo3v4wTdLlGLQdn0BOVAAGyO6C5ct1Q83jR6VHfGuTW1MQPzH5QvWFpRunIuDURWf9KQTj)QPzHzFrLDKfny)rHzKsobgHdqL(issbMWv7t(hhKeJKbcMYDT3pfITQeWegXBkf2)0PZGyKmq8YgajbLulCXbfWIs6ODeSxb)9ScnD3NxnAoOawushTJG9k4VNvOMYrpfyCMW6WOOTOsRvhM8REqvBkfU6CxNRA1cvN7kC3PAHlu9aCkvRLRXAx9ddvtJ9VHvJMQzryC15Ucx0tQ2M8RMMfM9fv2rw0G9hfMrk5eyeoav6JijfycxT3pfITQeWegXBkf2Vd1A56BsSvLaMWiEtPWE1JyYIg6hualkPJ2rWEf83Zkut5ONcmotyDyufvAT68imkqeRAhkBpMR6dAuRSOXC4QznmOQgnvFEecms1yD4uuzhzrd2FuygPKdtJSgRd0ESaGctyuGiwc)yfG8Fzq6Gg1klA0MP5EaLqeZbJ4Xpwbi)xg4HXyDGsJMqSBbYkGhZLGEkqLWV)hDmzrJhgJ1bknAuiXNzecsaVEWZjRUBbc13PZawhCUKyKmqW(Vnj0pXXSmb8f3OgnHCqiNcL74zAZI56F60wuzhzrd2FuygPKdtJSgRd0ESaGctyuGiwA2mUcwmhhajDqJALfnAZ0CpGsiI5Gr8ZMXvWI54aiEymwhO0OjeXCWiEGtSnzVDmb8WySoqPrZbHCkuUJh4eBt2BhtapbcSDWxK3BEfnjMdgXRaqhijSqmXYGapmgRdufv2rw0G9hfMrk5W0iRX6aThlaOW0iRX6aThlaOWegfiIL(Orsh0OwzrJ2mn3dOecqd(wDDq5TBXCnIHtF0ij0pPJYfiA0y3cKvapMlb9uGkHF)p6yYIgpmgRduA0Oa23)7j2Tis6GiMlPa23)7vOChnAoiKtHYD8gMltBaCIy3IiPdIyopbcSDWxC)A6mCqiNcL74feN7jX6mf4jqGTd(I7A0Oa23)7feN7jX6mf4F60wuzhzrd2FuygPKdtyuGiM27NsiybmNWfuEck7b0viXtE6YJaEzpCStg9qua77)9mHrbIy(NoDMgznwh4zcJceXs4hRaK)ldsh0OwzrdDMgznwh4zcJceXsZMXvWI54aiPdAuRSOHotJSgRd8mHrbIyPpAK0bnQvw0uuP1QZJ2SyUvN7kCRMMZjoRAgRo8nJRGfZXbqcJvtJzCUbVGQPzH5QTrvnnNtCw1eWu5x9hrQEaoLQPXPz3WIk7ilAW(JcZiLCyAZI5Q9(PiMdgXdCITj7TJjGhgJ1bk6I5Gr8ZMXvWI54aiEymwhOOFqbSOKoAhbtnLJEkW4mH1Hrr)Gqofk3XdCITj7TJjGNab2o4lUxuP1QZJ2SyUvN7kCRo8nJRGfZXbqQMXQdhvnnNtCwySAAmJZn4funnlmxTnQQZJWOarSQF6vZWBCagx9dVtw15ruyM2Ik7ilAW(JcZiLCyAZI5Q9(PiMdgXpBgxblMJdG4HXyDGIEiI5Gr8aNyBYE7yc4HXyDGI(bfWIs6ODem1uo6PaJZewhgfDgua77)9mHrbIy(NUgnagdZb8mx8IMe6N0bYhoYIgpmgRdu0wuP1Q5bO6)Z5Q(GccGrQgnvZveDCymNCYwH7J1Fqb5qdnMWWf5uYndLMLdneL9GCYD5yZHgHXggVJjlAUjnkmhg8M0qadg5W1xuzhzrd2FuygPKdtJSgRd0ESaGcgNyAZI5MoOrTYIgTzAUhqXUfiRaEmxc6Pavc)(F0XKfnEymwhOOZWGMegNyF)pOsIrYabtnL7A0G1bNljgjdeS)Btc9tCmltatrl0sNbmoX((FqLeJKbcozSiMqs3gfeShkxRrdwhCUKyKmqW(Vnj0pXXSmbm1uUrAlQSJSOb7pkmJuYrhHCjcGrpYb0(JiPb4uOCxBGtHyjla9gHsyZBrLDKfny)rHzKsomTzXC1E)ueZbJ4Xpwbi)xg4HXyDGIEiybmNWfuEck7b0piKtHYD8zgHGeW)0PZatJSgRd8yCIPnlMB6Gg1klA0Oje7wGSc4XCjONcuj87)rhtw04HXyDGIodkK4ZmcbjGNaFcG5ASoqJgfW((FptyuGiM)PtxHeFMriib86bpNS6Ufixq5oT0s)GcyrjD0oc2RG)EwHAkmWWDgVIMSBbYkGhZLGEkqLWV)hDmzrJhgJ1bkAPjSo4CjXizGG9FBsOFIJzzcyAPMgqyPtSvLaMWiEtPW(DO((vfvAT68OnlMB15Uc3QPXmSaKQPrySH3jmwD4OQXcyoHB12OQEqvBhzzcvtJrJQM99)Axnn8Plpcu9GKQ3PAc8jaMB1eBYaTRw9i7KvDEegfiIXyOxY4LiHMxndVXbyC1p8ozvNhrHzAlQSJSOb7pkmJuYHPnlMR27NIyoyeFGHfGKmm2W4D8WySoqrpeSaMt4ckV5C0dmSaKKHXggVtIab2o4lOCn9quiXtE6YJaEc8jaMRX6a6kK4ZmcbjGNab2oyQ1cDgua77)9mHrbIy(NoDgcrmhmIxqCUNeRZuGhgJ1bknAua77)9cIZ9KyDMc8pDAPZqiagdZb8SoesLq)KWfsWab57dSWaiIgnkG99)EwhcPsOFs4cjyGG89pDA1ObWyyoGN5Ix0Kq)Koq(Wrw04HXyDGI2IkTwnpxtHYnaCQQ)is18CjONcuvZ)(F0XKfnfv2rw0G9hfMrk5G5AkuUbGtP9(PecwaZjCbL3Co62TazfWJ5sqpfOs43)JoMSOXdJX6afDfs8zgHGeWtGpbWCnwhqxHeFMriib86bpNS6Ufixq5o9dkGfL0r7iyVc(7zfQPCVOsRvtZ5eBt2BhtGQZLlmvpiPASaMt4cQQTrvnls4wnn8PlpcuTnQQPXncbjq1gbQ(Px9hrQ2HMSQHb9Y46lQSJSOb7pkmJuYb4eBt2BhtaT3pLqWcyoHlO8eu2dOZqikK4ZmcbjGNaFcG5ASoGUcjEYtxEeWtGaBhm1HLXWsth9uGXzcRdJsJgfs8KNU8iGNab2oyA6AFEPwmsgiEzdGKGsQfOLUyKmq8YgajbLulqDylQSJSOb7pkmJuYrqCUNeRZuG27NIcjEYtxEeWl7HJDYOZqian4B11bL3UfZ1igo9rJKq)KokxGOrZbHCkuUJNjmkqeZtGaBhm13VM2Ik7ilAW(JcZiLC0rYIgT3pf23)7zDiKY9WINa2r0OrbSV)3ZegfiI5F6fv2rw0G9hfMrk5W6qiv6)i5R9(POa23)7zcJceX8p9Ik7ilAW(JcZiLCybcgiCStM27NIcyF)VNjmkqeZ)0lQSJSOb7pkmJuY5VeG1HqkT3pffW((FptyuGiM)Pxuzhzrd2FuygPKJnhaleZLoMZP9(POa23)7zcJceX8p9Ik7ilAW(JcZiLCEyiTceO9ybaLmZbhZ5acoXIqJ27NcdkG99)EMWOarm)txJggcrmhmIh4eBt2BhtapmgRdu0piKtHYD8mHrbIyEcey7GPoS5vJgXCWiEGtSnzVDmb8WySoqrNHdc5uOChpWj2MS3oMaEcey7GV4g1O5Gqofk3XdCITj7TJjGNab2oyQV6A6)nJRKiqGTdM6BmV0slT0drHep5Plpc4boX2K92Xeqvuzhzrd2FuygPKZddPvGaThlaOyyUmTbWjIDlIKoiI50E)uua77)9e7wejDqeZLua77)9kuUJgnYgajbLulCXvxxuzhzrd2FuygPKZddPvGaThlaOyyUmTbWjIDlIKoiI50E)uyieXCWiEGtSnzVDmb8WySoqPrtiI5Gr84hRaK)ld8WySoqrlDfW((FptyuGiMNab2oyQVF9ndlnb0GVvxhuE7wmxJy40hnsc9t6OCbsrLDKfny)rHzKsopmKwbc0ESaGIH5Y0gaNi2Tis6GiMt79tHbXCWiEGtSnzVDmb8WySoqrxmhmIh)yfG8FzGhgJ1bkAPRa23)7zcJceX8pD6mOqIpZieKaEGtSnzVDmbuA0y3cKvapMlb9uGkHF)p6yYIgpmgRdu0viXNzecsaVEWZjRUBbc13PTOYoYIgS)OWmsjNhgsRabAd)pCK0ybaLt(hhsiOzpjwNHfT3pLadlajzySHX7KiqGTdMY10drbSV)3ZegfiI5F60drbSV)3lio3tI1zkW)0PZ((FFaeGi5Nq)K7Dwvsrala7vOCh6WaKS8VipCnDfs8KNU8iGNab2oyQdBrLDKfny)rHzKsopmKwbc0ESaGI7r4ai40o4vTOhoLTFr79trbSV)3ZegfiI5F6fv2rw0G9hfMrk58WqAfiq7XcakUhwiOhoLHCkys6UxGLbAVFkkG99)EMWOarm)tVOYoYIgS)OWmsjNhgsRabAd)pCK0ybaLmNPwtqeCkauMZTOr79trbSV)3ZegfiI5F6fv2rw0G9hfMrk58WqAfiqB4)HJKglaOK5m1AcIGtSMkd0E)uua77)9mHrbIy(NErLwR(gcF75KQ)MZXAhoQ(Jiv)WgRdQEfiahgRMgigQgnvFqiNcL74lQSJSOb7pkmJuY5HH0kqaUOQOsRvFdxcCKQvwGLbvBSRBLfWfvATAA(Weguq1MuDyzSAgYlJvN7kCR(gYtB10SWSV6WKGaqTMaU8RgnvFfJvlgjdeS2vN7kCRopcJceX0UAeP6CxHB1HE5nGvJeUaj3fdvNRTs1FePAmkaQggGKLVVAAKdJQoxBLQ3F10CoXzvFqbSOQxC1huWozv)09fv2rw0G9QLahHcmmHbfO9(PCqbSOKoAhbtnLWYOyoyeVcaDGKWcXeldc8WySoqrNbfW((FptyuGiM)PRrJcyF)VxqCUNeRZuG)PRrdmajlFVc(7zLlOWammHbfK0rixsb)9Sc10ay4Q8YitJSgRd8WaKS8teidM0bfWUdOOLwnAcHPrwJ1bE8ozoijgjdeAPZqiI5Gr8aNyBYE7yc4HXyDGsJMdc5uOChpWj2MS3oMaEcey7GP(kAlQSJSOb7vlbocJuYHPrwJ1bApwaq5HH0FDoGOntZ9akhualkPJ2rWEf83ZkuFxJgyasw(Ef83Zkxq5Q8YitJSgRd8WaKS8teidM0bfWUdO0OjeMgznwh4X7K5GKyKmqkQ0A13ayfUvtZpCr7Kv9LotbyTRomKnvJ(vhMoltaxTjvFfJvlgjdeS2vJivRLBgwgRwmsgi4QZLlmvNhHrbIyvV4QF6fv2rw0G9QLahHrk58TjH(joMLjG1E)uyAK1yDG)HH0FDoGq3UfiRaE4WfTtwI1zka7HXyDGIowhCUKyKmqW(Vnj0pXXSmbm1uUIrgua77)9mHrbIy(NonXWDgzWUfiRaE4WfTtwI1zka7j2WbL70slTfvAT6Wq2un6xDy6SmbC1Mu998eJvJf7WbUA0V6BGRsbt1x6mfGRgrQ2YSDWs1HLXQziVmwDURWT6Bi6X6GQVHimqB1IrYab7lQSJSOb7vlbocJuY5Btc9tCmltaR9(PW0iRX6a)ddP)6CaHodSV)3ZDvkysSotbypwSdhut5EEsJggcrNSiYk5NiiXKfn0X6GZLeJKbc2)TjH(joMLjGPMsyzKb7wGSc4vOhRdskeg8eB4G6ROLrSaMt4ckpbL9aAPTOsRvhgYMQr)QdtNLjGRwqvB66U8R(gcMYLF1Hz0Irt17V6DSJSmHQrt12KF1IrYaPAtQwlvlgjdeSVOYoYIgSxTe4imsjNVnj0pXXSmbS2N8poijgjdemL7AVFkmnYASoW)Wq6VohqOJ1bNljgjdeS)Btc9tCmltatnfTuuzhzrd2RwcCegPKdRBhfEvG27NctJSgRd8pmK(RZbe6mW((FpRBhfEvG)PRrtiI5Gr8mHbfKipmxpmgRdu0dXUfiRaEf6X6GKcHbpmgRdu0wuP1Qd1yVjn2twNjq1cQAtx3LF13qWuU8RomJwmAQ2KQVQAXizGGlQSJSOb7vlbocJuYj4jRZeq7t(hhKeJKbcMYDT3pfMgznwh4Fyi9xNdi0X6GZLeJKbc2)TjH(joMLjGPCvrLDKfnyVAjWryKsobpzDMaAVFkmnYASoW)Wq6VohqkQkQ0A13qlWYGQrmbs1YgavBSRBLfWfvAT6WGBWkvtJBecsaC1OP6bn3uNSbeJKF1IrYabx9hrQw4cvRtwezL8RMGetw0u9(RoVmwnRdafUAJavBocyQ8R(Pxuzhzrd2RqcfMgznwhO9ybafmhRE6K)XbPmJqqcOntZ9ak6Kfrwj)ebjMSOHowhCUKyKmqW(Vnj0pXXSmbm1AHodkK4ZmcbjGNab2o4loiKtHYD8zgHGeWREetw0OrJoAXObujwhakm15L2IkTwDyWnyLQPHpD5raC1OP6bn3uNSbeJKF1IrYabx9hrQw4cvRtwezL8RMGetw0u9(RoVmwnRdafUAJavBocyQ8R(Pxuzhzrd2RqcJuYHPrwJ1bApwaqbZXQNo5FCqI80Lhb0MP5EafDYIiRKFIGetw0qhRdoxsmsgiy)3Me6N4ywMaMATqNbfW((FVG4CpjwNPa)txJgg0rlgnGkX6aqHPoV0dXUfiRaE8bgjH(jwhcP8WySoqrlTfvAT6WGBWkvtdF6YJa4Q3F15ryuGigJHI4CpvFPZuqo0ygwas10im2W4DQEXv)0R2gv15cvZ1ycvFfJvJHdAu4QDWxQgnvlCHQPHpD5rGQVHOqlQSJSOb7viHrk5W0iRX6aThlaOG5y1tKNU8iG2mn3dOOa23)7zcJceX8pD6mOa23)7feN7jX6mf4F6A0eyybijdJnmENebcSDWuFnT0viXtE6YJaEcey7GP(QIkTwnVoCwZvnnUriibQ2gv10WNU8iq1yqE6vRtwePAbvnnNtSnzVDmbQ(yyPOYoYIgSxHegPKtMriib0E)ueZbJ4boX2K92XeWdJX6af9qaoX2K92XeqrxHeFMriib86bpNS6Ufixq5o9dc5uOChpWj2MS3oMaEcey7GV4k6yDW5sIrYab7)2Kq)ehZYeWuUtNyRkbmHr8MsH97q9nsxHeFMriib8eiW2bttx7Z7fIrYaXlBaKeusTqrLDKfnyVcjmsjhYtxEeq79trmhmIh4eBt2BhtapmgRdu0z4GcyrjD0ocMAkh9uGXzcRdJI(bHCkuUJh4eBt2BhtapbcSDWxCNUcjEYtxEeWtGaBhmnDTpVxigjdeVSbqsqj1c0wuP1QPXncbjq1pDoaqx7QnhgvTqwaxTGQ(HHQxPAdxTvnwhoR5QodgGycIu9hrQw4cv7mSunnlmxnl8reOAR6)olMlqkQSJSOb7viHrk5OJqUebWOh5aA)rK0aCkuUxuzhzrd2RqcJuYjZieKaAVFke4tamxJ1b0pOawushTJG9k4VNvOMYDg1cnXGDlqwb8yUe0tbQe(9)OJjlA8WySoqr)Gqofk3XZ0MfZ1)0PLod6bpNS6Ufixq5UgneiW2bFbfzpCKKnaOJ1bNljgjdeS)Btc9tCmltatnfTWODlqwb8yUe0tbQe(9)OJjlA8WySoqrlDgcb4eBt2BhtaLgneiW2bFbfzpCKKnaOPROJ1bNljgjdeS)Btc9tCmltatnfTWODlqwb8yUe0tbQe(9)OJjlA8WySoqrl9qW4e77)bfDgeJKbIx2aijOKAHBsGaBhmTuhw6meyybijdJnmENebcSDWuUwJMqK9WXoz0TBbYkGhZLGEkqLWV)hDmzrJhgJ1bkAlQSJSOb7viHrk5OJqUebWOh5aA)rK0aCkuUxuzhzrd2RqcJuYjZieKaAFY)4GKyKmqWuUR9(PectJSgRd8yow90j)JdszgHGeGob(eaZ1yDa9dkGfL0r7iyVc(7zfQPCNrTqtmy3cKvapMlb9uGkHF)p6yYIgpmgRdu0piKtHYD8mTzXC9pDAPZGEWZjRUBbYfuURrdbcSDWxqr2dhjzda6yDW5sIrYab7)2Kq)ehZYeWutrlmA3cKvapMlb9uGkHF)p6yYIgpmgRdu0sNHqaoX2K92XeqPrdbcSDWxqr2dhjzdaA6k6yDW5sIrYab7)2Kq)ehZYeWutrlmA3cKvapMlb9uGkHF)p6yYIgpmgRdu0spemoX((FqrNbXizG4LnasckPw4MeiW2btl13VIodbgwasYWydJ3jrGaBhmLR1OjezpCStgD7wGSc4XCjONcuj87)rhtw04HXyDGI2IkTwnnJSby0uDOqGoGLQrt1bpNS6oOAXizGGR2KQdlJvtZcZvNlxyQM8MzNSQrpP6DQ(kC1m80Rwqvh2QfJKbcM2QrKQ1cUAgYlJvlgjdemTfv2rw0G9kKWiLCoKnaJMKab6aw0E)uW6GZLeJKbcMAkxrNab2o4lUIrgW6GZLeJKbcMAk5Lw6hualkPJ2rWutjSfvAT6Wua0R(Pxnn8PlpcuTjvhwgRgnvBox1IrYabxnd5YfMQDlZDYQ2HMSQHb9Y4wTnQQhKunEmDmxKqBrLDKfnyVcjmsjhYtxEeq79tjeMgznwh4XCS6jYtxEeGodhualkPJ2rWutjS0jWNayUgRd0OjezpCStgDgKnaO((1A0CqbSOKoAhbtnLROLw6mOh8CYQ7wGCbL7A0qGaBh8fuK9Wrs2aGowhCUKyKmqW(Vnj0pXXSmbm1u0cJ2TazfWJ5sqpfOs43)JoMSOXdJX6afT0zieGtSnzVDmbuA0qGaBh8fuK9Wrs2aGMUIowhCUKyKmqW(Vnj0pXXSmbm1u0cJ2TazfWJ5sqpfOs43)JoMSOXdJX6afT0fJKbIx2aijOKAHBsGaBhm1HTOYoYIgSxHegPKd5PlpcO9j)JdsIrYabt5U27NsimnYASoWJ5y1tN8poirE6YJa0dHPrwJ1bEmhREI80LhbOFqbSOKoAhbtnLWsNaFcG5ASoGod6bpNS6Ufixq5UgneiW2bFbfzpCKKnaOJ1bNljgjdeS)Btc9tCmltatnfTWODlqwb8yUe0tbQe(9)OJjlA8WySoqrlDgcb4eBt2BhtaLgneiW2bFbfzpCKKnaOPROJ1bNljgjdeS)Btc9tCmltatnfTWODlqwb8yUe0tbQe(9)OJjlA8WySoqrlDXizG4LnasckPw4MeiW2btDylQ0A10mYgGrt1Hcb6awQgnvZhA17V6DQw3gfeSNQTrv9kvN76CvRqv7amUALfyzq1cxBQMMpmHbfuT6bvlOQd9YCOXOr5eQeMwuzhzrd2RqcJuY5q2amAsceOdyr79tbRdoxsmsgiyk3PFqbSOKoAhbtnfgo6PaJZewhg1nVtlDc8jaMRX6a6HaCITj7TJjGIEikG99)EbX5EsSotb(No9adlajzySHX7KiqGTdMY10dXUfiRaEj3fljHlK4y2p4HXyDGIUyKmq8YgajbLulCtcey7GPoSfvfvATAAogdZbWfv2rw0G9agdZbWuoO5aJqmbuPVZcaT3pfyasw(EzdGKGsbgNuFNEikG99)EMWOarm)tNodHOqI)GMdmcXeqL(olasSpY4L9WXoz0dXoYIg)bnhyeIjGk9Dwa43j9DBgxrJM)Z5se4W1izqs2a4ISJYhyCsBrLwRMg5Y1Yhx9ddvFPdHuvN7kCRopcJceXQ(P7R(giYPQ(JivtZ5eBt2BhtaF10aXq15Uc3Qd9YQF6vZcFebQ2Q(VZI5cKQnC1o0KvTHRELQjVbx9hrQ((14QvpYozvNhHrbIy(Ik7ilAWEaJH5aygPKdRdHuj0pjCHemqq(AVFkkG99)EMWOarm)tNodkK4ZmcbjGh4eBt2BhtaLgnkG99)EbX5EsSotb(No9dkGfL0r7iyVc(7zLlOCxJgfW((FptyuGiMNab2o4lOC)AA1Or2aijOKAHlOC)6IkTwnnseiqxQwqvBUnBQMg)ze1At15Uc3QZJWOarSQnC1o0KvTHRELQZfn3auQMa4NtQENQDi8ozvBv)Fo3nzAUhu9XWs1iMaPAHlunbcSD2jRA1JyYIMQr)QfUq1)nJRuuzhzrd2dymmhaZiLCYEgrT2Kq)KDlqqcxT3pLdc5uOChptyuGiMNab2o4l0IgnkG99)EMWOarm)txJgXizG4LnasckPw4cTCDrLDKfnypGXWCamJuYj7ze1Atc9t2TabjC1E)u(oeIWadIrYaXlBaKeusTWn1Y10EdEqiNcL7ql1FhcryGbXizG4LnasckPw4MA56BEqiNcL74zcJceX8eiW2bt7n4bHCkuUdTfv2rw0G9agdZbWmsjNp68WGkz3cKvGelybAVFkyDW5sIrYab7)2Kq)ehZYeWut5knAi2QsatyeVPuy)ouFJxthgGKL)f55RlQSJSOb7bmgMdGzKso6pY(ZFNSeRZWI27NcwhCUKyKmqW(Vnj0pXXSmbm1uUsJgITQeWegXBkf2Vd1341fv2rw0G9agdZbWmsjhHlKEdl6nQ0hroG27Nc77)9e4WHdW40hroG)PRrd77)9e4WHdW40hroq6GEJaepwSdhxC)6Ik7ilAWEaJH5aygPKdz11DqANew3oqrLDKfnypGXWCamJuYjxeXPyc7Kiagn2CGIk7ilAWEaJH5aygPKtaeGi5Nq)K7DwvsralaR9(PadqYY)I8En9qoiKtHYD8mHrbIy(NErLwR(giYPQMgcM(ozvhgYzbaU6pIunWjCEcunXMmOAePAowNRA23)J1U69xTocJxwh4RMg5Y1YhxTqYVAbvDgivlCHQDOCbSu9bHCkuUt1SgguvJMQnM26mwhunmqWcyFrLDKfnypGXWCamJuYHaM(ozPVZcaS2N8poijgjdemL7AVFkIrYaXlBaKeusTWf395vJggyqmsgiEUG5eUE9JqDE4AnAeJKbINlyoHRx)ixq5QRPLod2rwMqcgiybmL7A0igjdeVSbqsqj1cuFvEIwA1OHbXizG4LnasckPFK0vxtTwUMod2rwMqcgiybmL7A0igjdeVSbqsqj1cuh2WslTfvfvATAEbmNWfuvtJoYIgCrLwRo8nJlwmhhaPA0u99qdJvZpMoMlsQMg(0LhbkQSJSOb7XcyoHlOOqE6YJaAVFkI5Gr8ZMXvWI54aiEymwhOOFqbSOKoAhbtnLWsxmsgiEzdGKGsQfUjbcSDWuFJfvATA(hRaK)ldQMXQ55sqpfOQM)9)OJjlAcJvtZh8JavNlu9ddvJgO6mhI1CvlOQnDDx(vtJBecsGQfu1cxO6aBNQfJKbs17V6vQEXvpiPA8y6yUiP68br7QXOQnNRAKWfivhy7uTyKmqQ2yx3klGRwNG(R4lQSJSOb7XcyoHlOyKso6iKlram6roG2FejnaNcL7fv2rw0G9ybmNWfumsjNmJqqcO9(Py3cKvapMlb9uGkHF)p6yYIgpmgRdu0zF)Vh)yfG8FzG)PtN99)E8JvaY)LbEcey7GV4Uxl0dbJtSV)hufvATA(hRaK)ldcJvtJ01D5xnIunne(eaZT6CxHB1SV)huvtJBecsaCrLDKfnypwaZjCbfJuYrhHCjcGrpYb0(JiPb4uOCVOYoYIgShlG5eUGIrk5KzecsaTp5FCqsmsgiyk31E)ueZbJ4Xpwbi)xg4HXyDGIodeiW2bFX9R0Orp45Kv3Ta5ck3PLUyKmq8YgajbLulCtcey7GP(QIkTwn)JvaY)LbvZy18CjONcuvZ)(F0XKfnvVt18HggRMgPR7YVAWiU8RMg(0LhbQw4As15Uox1Sq1e4tamxqv9hrQw3gfeSNIk7ilAWESaMt4ckgPKd5PlpcO9(PiMdgXJFScq(VmWdJX6afD7wGSc4XCjONcuj87)rhtw04HXyDGIEikK4jpD5raVSho2jJotJSgRd84DYCqsmsgifvATA(hRaK)ldQo3CQMNlb9uGQA(3)JoMSOjmwnnemDDx(v)rKQzrZdxnnlmxTnQCqKQbofyuGQA8y6yUiPA1JyYIgFrLDKfnypwaZjCbfJuYrhHCjcGrpYb0(JiPb4uOCVOYoYIgShlG5eUGIrk5KzecsaTp5FCqsmsgiyk31E)ueZbJ4Xpwbi)xg4HXyDGIUDlqwb8yUe0tbQe(9)OJjlA8WySoqrNb7iltibdeSaM67A0eIyoyepWj2MS3oMaEymwhOOLUyKmq8YgajbLulqnbcSDW0zGab2o4lUNh0OjemoX((FqrBrLwRM)Xka5)YGQzSAAoN4SQrt13dnmwnne(eaZTAACJqqcuTjvlCHQHrvn6xnwaZjCRwqvNbs1bgNvREetw0unl8reOAAoNyBYE7ycuuzhzrd2JfWCcxqXiLC0rixIay0JCaT)isAaofk3lQSJSOb7XcyoHlOyKsozgHGeq79trmhmIh)yfG8FzGhgJ1bk6I5Gr8aNyBYE7yc4HXyDGIUDKLjKGbcwat5oD23)7Xpwbi)xg4jqGTd(I7ETe5X6Wjg(v5npfLOeJ]] )

end