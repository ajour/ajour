-- DeathKnightUnholy.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local roundUp = ns.roundUp

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DEATHKNIGHT' then
    local spec = Hekili:NewSpecialization( 252 )

    spec:RegisterResource( Enum.PowerType.Runes, {
        rune_regen = {
            last = function ()
                return state.query_time
            end,

            interval = function( time, val )
                local r = state.runes

                if val == 6 then return -1 end
                return r.expiry[ val + 1 ] - time
            end,

            stop = function( x )
                return x == 6
            end,

            value = 1,    
        }
    }, setmetatable( {
        expiry = { 0, 0, 0, 0, 0, 0 },
        cooldown = 10,
        regen = 0,
        max = 6,
        forecast = {},
        fcount = 0,
        times = {},
        values = {},
        resource = "runes",

        reset = function()
            local t = state.runes

            for i = 1, 6 do
                local start, duration, ready = GetRuneCooldown( i )

                start = start or 0
                duration = duration or ( 10 * state.haste )
                
                start = roundUp( start, 2 )

                t.expiry[ i ] = ready and 0 or start + duration
                t.cooldown = duration
            end

            table.sort( t.expiry )

            t.actual = nil
        end,

        gain = function( amount )
            local t = state.runes

            for i = 1, amount do
                t.expiry[ 7 - i ] = 0
            end
            table.sort( t.expiry )

            t.actual = nil
        end,

        spend = function( amount )
            local t = state.runes

            for i = 1, amount do
                if t.expiry[ 4 ] > state.query_time then
                    t.expiry[ 1 ] = t.expiry[ 4 ] + t.cooldown
                else
                    t.expiry[ 1 ] = state.query_time + t.cooldown
                end
                table.sort( t.expiry )
            end

            if amount > 0 then
                state.gain( amount * 10, "runic_power" )

                if state.set_bonus.tier20_4pc == 1 then
                    state.cooldown.army_of_the_dead.expires = max( 0, state.cooldown.army_of_the_dead.expires - 1 )
                end
            end

            t.actual = nil
        end,

        timeTo = function( x )
            return state:TimeToResource( state.runes, x )
        end,
    }, {
        __index = function( t, k, v )
            if k == 'actual' then
                local amount = 0

                for i = 1, 6 do
                    if t.expiry[ i ] <= state.query_time then
                        amount = amount + 1
                    end
                end

                return amount

            elseif k == 'current' then
                -- If this is a modeled resource, use our lookup system.
                if t.forecast and t.fcount > 0 then
                    local q = state.query_time
                    local index, slice

                    if t.values[ q ] then return t.values[ q ] end

                    for i = 1, t.fcount do
                        local v = t.forecast[ i ]
                        if v.t <= q then
                            index = i
                            slice = v
                        else
                            break
                        end
                    end

                    -- We have a slice.
                    if index and slice then
                        t.values[ q ] = max( 0, min( t.max, slice.v ) )
                        return t.values[ q ]
                    end
                end

                return t.actual

            elseif k == 'time_to_next' then
                return t[ 'time_to_' .. t.current + 1 ]

            elseif k == 'time_to_max' then
                return t.current == 6 and 0 or max( 0, t.expiry[6] - state.query_time )


            elseif k == 'add' then
                return t.gain

            else
                local amount = k:match( "time_to_(%d+)" )
                amount = amount and tonumber( amount )

                if amount then return state:TimeToResource( t, amount ) end
            end
        end
    } ) )

    spec:RegisterResource( Enum.PowerType.RunicPower )


    spec:RegisterStateFunction( "apply_festermight", function( n )
        if azerite.festermight.enabled then
            if buff.festermight.up then
                addStack( "festermight", buff.festermight.remains, n )
            else
                applyBuff( "festermight", nil, n )
            end
        end
    end )


    -- Talents
    spec:RegisterTalents( {
        infected_claws = 22024, -- 207272
        all_will_serve = 22025, -- 194916
        clawing_shadows = 22026, -- 207311

        bursting_sores = 22027, -- 207264
        ebon_fever = 22028, -- 207269
        unholy_blight = 22029, -- 115989

        grip_of_the_dead = 22516, -- 273952
        deaths_reach = 22518, -- 276079
        asphyxiate = 22520, -- 108194

        pestilent_pustules = 22522, -- 194917
        harbinger_of_doom = 22524, -- 276023
        soul_reaper = 22526, -- 130736

        spell_eater = 22528, -- 207321
        wraith_walk = 22529, -- 212552
        death_pact = 23373, -- 48743

        pestilence = 22532, -- 277234
        defile = 22534, -- 152280
        epidemic = 22536, -- 207317

        army_of_the_damned = 22030, -- 276837
        unholy_frenzy = 22110, -- 207289
        summon_gargoyle = 22538, -- 49206
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3537, -- 214027
        relentless = 3536, -- 196029
        gladiators_medallion = 3535, -- 208683

        antimagic_zone = 42, -- 51052
        cadaverous_pallor = 163, -- 201995
        dark_simulacrum = 41, -- 77606
        lichborne = 3754, -- 287081 -- ADDED 8.1
        life_and_death = 40, -- 288855 -- ADDED 8.1
        necrotic_aura = 3437, -- 199642
        necrotic_strike = 149, -- 223829
        raise_abomination = 3747, -- 288853
        reanimation = 152, -- 210128
        transfusion = 3748, -- 288977 -- ADDED 8.1
    } )


    -- Auras
    spec:RegisterAuras( {
        antimagic_shell = {
            id = 48707,
            duration = function () return 5 + ( talent.spell_eater.enabled and 5 or 0 ) + ( ( level < 116 and equipped.acherus_drapes ) and 5 or 0 ) end,
            max_stack = 1,
        },
        army_of_the_dead = {
            id = 42650,
            duration = 4,
            max_stack = 1,
        },
        asphyxiate = {
            id = 108194,
            duration = 4,
            max_stack = 1,
        },
        dark_succor = {
            id = 101568,
            duration = 20,
        },
        dark_transformation = {
            id = 63560, 
            duration = 20,
            generate = function ()
                local cast = class.abilities.dark_transformation.lastCast or 0
                local up = pet.ghoul.up and cast + 20 > state.query_time

                local dt = buff.dark_transformation
                dt.name = class.abilities.dark_transformation.name
                dt.count = up and 1 or 0
                dt.expires = up and cast + 20 or 0
                dt.applied = up and cast or 0
                dt.caster = "player"
            end,
        },
        death_and_decay_debuff = {
            id = 43265,
            duration = 10,
            max_stack = 1,
        },
        death_and_decay = {
            id = 188290,
            duration = 10
        },
        death_pact = {
            id = 48743,
            duration = 15,
            max_stack = 1,
        },
        deaths_advance = {
            id = 48265,
            duration = 8,
            max_stack = 1,
        },
        defile = {
            id = 156004,
            duration = 10,
        },
        festering_wound = {
            id = 194310,
            duration = 30,
            max_stack = 6,
            meta = {
                stack = function ()
                    -- Designed to work with Unholy Frenzy, time until 4th Festering Wound would be applied.
                    local actual = debuff.festering_wound.up and debuff.festering_wound.count or 0
                    if buff.unholy_frenzy.down or debuff.festering_wound.down then 
                        return actual
                    end

                    local slot_time = query_time
                    local swing, speed = state.swings.mainhand, state.swings.mainhand_speed

                    local last = swing + ( speed * floor( slot_time - swing ) / swing )
                    local window = min( buff.unholy_frenzy.expires, query_time ) - last

                    local bonus = floor( window / speed )

                    return min( 6, actual + bonus )
                end
            }
        },
        grip_of_the_dead = {
            id = 273977,
            duration = 3600,
            max_stack = 1,
        },
        icebound_fortitude = {
            id = 48792,
            duration = 8,
            max_stack = 1,
        },
        on_a_pale_horse = {
            id = 51986,
        },
        outbreak = {
            id = 196782,
            duration = 6,
            type = "Disease",
            max_stack = 1,
            tick_time = 1,
        },
        path_of_frost = {
            id = 3714,
            duration = 600,
            max_stack = 1,
        },
        runic_corruption = {
            id = 51460,
            duration = 3,
            max_stack = 1,
        },
        sign_of_the_skirmisher = {
            id = 186401,
            duration = 3600,
            max_stack = 1,
        },
        soul_reaper = {
            id = 130736,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        sudden_doom = {
            id = 81340,
            duration = 10,
            max_stack = 2,
        },
        unholy_blight = {
            id = 115989,
            duration = 6,
            max_stack = 1,
        },
        unholy_blight_dot = {
            id = 115994,
            duration = 14,
            tick_time = function () return 2 * haste end,
        },
        unholy_frenzy = {
            id = 207289,
            duration = 12,
            max_stack = 1,
        },
        unholy_strength = {
            id = 53365,
            duration = 15,
            max_stack = 1,
        },
        virulent_plague = {
            id = 191587,
            duration = function () return 21 * ( talent.ebon_fever.enabled and 0.5 or 1 ) end,
            tick_time = function () return 3 * ( talent.ebon_fever.enabled and 0.5 or 1 ) end,
            type = "Disease",
            max_stack = 1,
        },
        wraith_walk = {
            id = 212552,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },


        -- PvP Talents
        crypt_fever = {
            id = 288849,
            duration = 4,
            max_stack = 1,
        },

        necrotic_wound = {
            id = 223929,
            duration = 18,
            max_stack = 1,
        },


        -- Azerite Powers
        cold_hearted = {
            id = 288426,
            duration = 8,
            max_stack = 1
        },

        festermight = {
            id = 274373,
            duration = 20,
            max_stack = 99,
        },

        helchains = {
            id = 286979,
            duration = 15,
            max_stack = 1
        }
    } )


    spec:RegisterStateTable( 'death_and_decay', 
        setmetatable( { onReset = function( self ) end },
        { __index = function( t, k )
            if k == 'ticking' then
                return buff.death_and_decay.up

            elseif k == 'remains' then
                return buff.death_and_decay.remains

            end

            return false
        end } ) )

    spec:RegisterStateTable( 'defile', 
        setmetatable( { onReset = function( self ) end },
        { __index = function( t, k )
            if k == 'ticking' then
                return buff.death_and_decay.up

            elseif k == 'remains' then
                return buff.death_and_decay.remains

            end

            return false
        end } ) )

    spec:RegisterStateExpr( "dnd_ticking", function ()
        return death_and_decay.ticking
    end )

    spec:RegisterStateExpr( "dnd_remains", function ()
        return death_and_decay.remains
    end )


    spec:RegisterStateExpr( "spreading_wounds", function ()
        if talent.infected_claws.enabled and buff.dark_transformation.up then return false end -- Ghoul is dumping wounds for us, don't bother.
        return azerite.festermight.enabled and settings.cycle and settings.festermight_cycle and cooldown.death_and_decay.remains < 9 and active_dot.festering_wound < spell_targets.festering_strike
    end )


    spec:RegisterStateFunction( "time_to_wounds", function( x )
        if debuff.festering_wound.stack >= x then return 0 end
        if buff.unholy_frenzy.down then return 3600 end

        local deficit = x - debuff.festering_wound.stack
        local swing, speed = state.swings.mainhand, state.swings.mainhand_speed

        local last = swing + ( speed * floor( query_time - swing ) / swing )
        local fw = last + ( speed * deficit ) - query_time

        if fw > buff.unholy_frenzy.remains then return 3600 end
        return fw
    end )


    spec:RegisterGear( "tier19", 138355, 138361, 138364, 138349, 138352, 138358 )
    spec:RegisterGear( "tier20", 147124, 147126, 147122, 147121, 147123, 147125 )
        spec:RegisterAura( "master_of_ghouls", {
            id = 246995,
            duration = 3,
            max_stack = 1
        } )        

    spec:RegisterGear( "tier21", 152115, 152117, 152113, 152112, 152114, 152116 )
        spec:RegisterAura( "coils_of_devastation", {
            id = 253367,
            duration = 4,
            max_stack = 1
        } )

    spec:RegisterGear( "acherus_drapes", 132376 )
    spec:RegisterGear( "cold_heart", 151796 ) -- chilled_heart stacks NYI
        spec:RegisterAura( "cold_heart_item", {
            id = 235599,
            duration = 3600,
            max_stack = 20 
        } )

    spec:RegisterGear( "consorts_cold_core", 144293 )
    spec:RegisterGear( "death_march", 144280 )
    -- spec:RegisterGear( "death_screamers", 151797 )
    spec:RegisterGear( "draugr_girdle_of_the_everlasting_king", 132441 )
    spec:RegisterGear( "koltiras_newfound_will", 132366 )
    spec:RegisterGear( "lanathels_lament", 133974 )
    spec:RegisterGear( "perseverance_of_the_ebon_martyr", 132459 )
    spec:RegisterGear( "rethus_incessant_courage", 146667 )
    spec:RegisterGear( "seal_of_necrofantasia", 137223 )
    spec:RegisterGear( "shackles_of_bryndaor", 132365 ) -- NYI
    spec:RegisterGear( "soul_of_the_deathlord", 151740 )
    spec:RegisterGear( "soulflayers_corruption", 151795 )
    spec:RegisterGear( "the_instructors_fourth_lesson", 132448 )
    spec:RegisterGear( "toravons_whiteout_bindings", 132458 )
    spec:RegisterGear( "uvanimor_the_unbeautiful", 137037 )


    spec:RegisterPet( "ghoul", 26125, "raise_dead", 3600 )
    spec:RegisterTotem( "gargoyle", 458967 )
    spec:RegisterTotem( "abomination", 298667 )
    spec:RegisterPet( "apoc_ghoul", 24207, "apocalypse", 15 )


    spec:RegisterHook( "reset_precast", function ()
        local expires = action.summon_gargoyle.lastCast + 35
        if expires > now then
            summonPet( "gargoyle", expires - now )
        end

        local control_expires = action.control_undead.lastCast + 300
        if control_expires > now and pet.up and not pet.ghoul.up then
            summonPet( "controlled_undead", control_expires - now )
        end

        local apoc_expires = action.apocalypse.lastCast + 15
        if apoc_expires > now then
            summonPet( "apoc_ghoul", apoc_expires - now )
        end

        if talent.all_will_serve.enabled and pet.ghoul.up then
            summonPet( "skeleton" )
        end

        rawset( cooldown, "army_of_the_dead", nil )
        rawset( cooldown, "raise_abomination", nil )

        if pvptalent.raise_abomination.enabled then
            cooldown.army_of_the_dead = cooldown.raise_abomination
        else
            cooldown.raise_abomination = cooldown.army_of_the_dead
        end

        if debuff.outbreak.up and debuff.virulent_plague.down then
            applyDebuff( "target", "virulent_plague" )
        end
    end )


    -- Not actively supporting this since we just respond to the player precasting AOTD as they see fit.
    spec:RegisterStateTable( "death_knight", setmetatable( {
        disable_aotd = false,
        delay = 6,
    }, {
        __index = function( t, k )
            if k == "fwounded_targets" then return state.active_dot.festering_wound end
            return 0
        end,
    } ) )


    -- Abilities
    spec:RegisterAbilities( {
        antimagic_shell = {
            id = 48707,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            startsCombat = false,
            texture = 136120,

            handler = function ()
                applyBuff( "antimagic_shell" )
            end,
        },


        apocalypse = {
            id = 275699,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( pvptalent.necromancers_bargain.enabled and 45 or 90 ) end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1392565,

            handler = function ()
                summonPet( "apoc_ghoul", 15 )

                if debuff.festering_wound.stack > 4 then
                    applyDebuff( "target", "festering_wound", debuff.festering_wound.remains, debuff.festering_wound.remains - 4 )
                    apply_festermight( 4 )
                    gain( 12, "runic_power" )
                else                    
                    gain( 3 * debuff.festering_wound.stack, "runic_power" )
                    apply_festermight( debuff.festering_wound.stack )
                    removeDebuff( "target", "festering_wound" )
                end

                if pvptalent.necromancers_bargain.enabled then applyDebuff( "target", "crypt_fever" ) end
                -- summon pets?                
            end,
        },


        army_of_the_dead = {
            id = function () return pvptalent.raise_abomination.enabled and 288853 or 42650 end,
            cast = 0,
            cooldown = 480,
            gcd = "spell",

            spend = function () return pvptalent.raise_abomination.enabled and 0 or 3 end,
            spendType = "runes",

            toggle = "cooldowns",
            -- nopvptalent = "raise_abomination",

            startsCombat = false,
            texture = function () return pvptalent.raise_abomination.enabled and 298667 or 237511 end,

            handler = function ()
                if pvptalent.raise_abomination.enabled then
                    summonPet( "abomination" )
                else
                    applyBuff( "army_of_the_dead", 4 )
                    if set_bonus.tier20_2pc == 1 then applyBuff( "master_of_ghouls" ) end
                end
            end,

            copy = { 288853, 42650, "army_of_the_dead", "raise_abomination" }
        },


        --[[ raise_abomination = {
            id = 288853,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            toggle = "cooldowns",
            pvptalent = "raise_abomination",

            startsCombat = false,
            texture = 298667,

            handler = function ()                
            end,
        }, ]]


        asphyxiate = {
            id = 108194,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 538558,

            toggle = "interrupts",

            talent = "asphyxiate",

            debuff = "casting",
            readyTime = state.timeToInterrupt,            

            handler = function ()
                applyDebuff( "target", "asphyxiate" )
            end,
        },


        chains_of_ice = {
            id = 45524,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 135834,

            recheck = function ()
                return buff.unholy_strength.remains - gcd, buff.unholy_strength.remains
            end,
            handler = function ()
                applyDebuff( "target", "chains_of_ice" )
                removeBuff( "cold_heart_item" )
            end,
        },


        clawing_shadows = {
            id = 207311,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 615099,

            talent = "clawing_shadows",

            handler = function ()
                if debuff.festering_wound.stack > 1 then
                    applyDebuff( "target", "festering_wound", debuff.festering_wound.remains, debuff.festering_wound.stack - 1 )
                else removeDebuff( "target", "festering_wound" ) end
                apply_festermight( 1 )
                gain( 3, "runic_power" )
            end,
        },


        control_undead = {
            id = 111673,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 237273,

            usable = function () return target.is_undead and target.level <= level + 1 end,
            handler = function ()
                dismissPet( "ghoul" )
                summonPet( "controlled_undead", 300 )
            end,
        },


        dark_command = {
            id = 56222,
            cast = 0,
            cooldown = 8,
            gcd = "off",

            startsCombat = true,
            texture = 136088,

            handler = function ()
                applyDebuff( "target", "dark_command" )
            end,
        },


        dark_simulacrum = {
            id = 77606,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = 0,
            spendType = "runic_power",

            startsCombat = true,
            texture = 135888,

            pvptalent = "dark_simulacrum",

            usable = function ()
                if not target.is_player then return false, "target is not a player" end
                return true
            end,
            handler = function ()
                applyDebuff( "target", "dark_simulacrum" )
            end,
        },


        dark_transformation = {
            id = 63560,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            texture = 342913,

            usable = function () return pet.ghoul.alive end,
            handler = function ()
                applyBuff( "dark_transformation" )
                if azerite.helchains.enabled then applyBuff( "helchains" ) end
            end,
        },


        death_and_decay = {
            id = 43265,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 136144,

            notalent = "defile",

            handler = function ()
                applyBuff( "death_and_decay", 10 )
                if talent.grip_of_the_dead.enabled then applyDebuff( "target", "grip_of_the_dead" ) end
            end,
        },


        death_coil = {
            id = 47541,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.sudden_doom.up and 0 or 40 end,
            spendType = "runic_power",

            startsCombat = true,
            texture = 136145,

            handler = function ()
                removeStack( "sudden_doom" )
                if set_bonus.tier21_2pc == 1 then applyDebuff( "target", "coils_of_devastation" ) end
                if cooldown.dark_transformation.remains > 0 then setCooldown( 'dark_transformation', cooldown.dark_transformation.remains - 1 ) end
            end,
        },


        --[[ death_gate = {
            id = 50977,
            cast = 4,
            cooldown = 60,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = false,
            texture = 135766,

            handler = function ()
            end,
        }, ]]


        death_grip = {
            id = 49576,
            cast = 0,
            charges = 1,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            startsCombat = true,
            texture = 237532,

            handler = function ()
                applyDebuff( "target", "death_grip" )
                setDistance( 5 )
            end,
        },


        death_pact = {
            id = 48743,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 136146,

            talent = "death_pact",

            handler = function ()
                gain( health.max * 0.5, "health" )
                applyBuff( "death_pact" )
            end,
        },


        death_strike = {
            id = 49998,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.dark_succor.up and 0 or ( ( buff.transfusion.up and 0.5 or 1 ) * 35 ) end,
            spendType = "runic_power",

            startsCombat = true,
            texture = 237517,

            handler = function ()
                removeBuff( "dark_succor" )
                if level < 116 and equipped.death_march then
                    local cd = cooldown[ talent.defile.enabled and "defile" or "death_and_decay" ]
                    cd.expires = max( 0, cd.expires - 2 )
                end
            end,
        },


        deaths_advance = {
            id = 48265,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 237561,

            handler = function ()
                applyBuff( "deaths_advance" )
            end,
        },


        defile = {
            id = 152280,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            talent = "defile",

            startsCombat = true,
            texture = 1029008,

            handler = function ()
                applyBuff( "death_and_decay" )
                applyDebuff( "target", "defile", 1 )
            end,
        },


        epidemic = {
            id = 207317,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "runic_power",

            startsCombat = true,
            texture = 136066,

            talent = "epidemic",

            targets = {
                count = function () return active_dot.virulent_plague end,
            },

            usable = function () return active_dot.virulent_plague > 0 end,
            handler = function ()
            end,
        },


        festering_strike = {
            id = 85948,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 2,
            spendType = "runes",

            startsCombat = true,
            texture = 879926,

            cycle = function ()
                if settings.cycle and azerite.festermight.enabled and settings.festermight_cycle and dot.festering_wound.stack >= 2 and active_dot.festering_wound < spell_targets.festering_strike then return "festering_wound" end
            end,
            min_ttd = function () return min( cooldown.death_and_decay.remains + 4, 8 ) end, -- don't try to cycle onto targets that will die too fast to get consumed.

            handler = function ()
                applyDebuff( "target", "festering_wound", 24, debuff.festering_wound.stack + 2 )
            end,
        },


        icebound_fortitude = {
            id = 48792,
            cast = 0,
            cooldown = function ()
                if azerite.cold_hearted.enabled then return 165 end
                return 180
            end,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 237525,

            handler = function ()
                applyBuff( "icebound_fortitude" )
                if azerite.cold_hearted.enabled then applyBuff( "cold_hearted" ) end
            end,
        },


        lichborne = {
            id = 287081,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            pvptalent = "lichborne",

            startsCombat = false,
            texture = 136187,

            handler = function ()
                applyBuff( "lichborne" )
            end,
        },


        mind_freeze = {
            id = 47528,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = 0,
            spendType = "runic_power",

            startsCombat = true,
            texture = 237527,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        necrotic_strike = {
            id = 223829,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 132481,

            pvptalent = function ()
                if essence.conflict_and_strife.major then return end
                return "necrotic_strike"
            end,
            debuff = "festering_wound",

            handler = function ()
                if debuff.festering_wound.up then
                    if debuff.festering_wound.stack == 1 then removeDebuff( "target", "festering_wound" )
                    else applyDebuff( "target", "festering_wound", debuff.festering_wound.remains, debuff.festering_wound.stack - 1 ) end

                    applyDebuff( "target", "necrotic_wound" )
                end
            end,
        },


        outbreak = {
            id = 77575,
            cast = 0,
            cooldown = 0,
            icd = 3,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 348565,

            cycle = 'virulent_plague',

            nodebuff = "outbreak",
            usable = function () return target.exists or active_dot.outbreak == 0, "requires real target or no other outbreaks up" end,

            handler = function ()
                applyDebuff( "target", "outbreak" )
                applyDebuff( "target", "virulent_plague" )
                active_dot.virulent_plague = active_enemies
            end,
        },


        path_of_frost = {
            id = 3714,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = false,
            texture = 237528,

            handler = function ()
                applyBuff( "path_of_frost" )
            end,
        },


        --[[ raise_ally = {
            id = 61999,
            cast = 0,
            cooldown = 600,
            gcd = "spell",

            spend = 30,
            spendType = "runic_power",

            startsCombat = false,
            texture = 136143,

            handler = function ()
            end,
        }, ]]


        raise_dead = {
            id = 46584,
            cast = 0,
            cooldown = 30,
            gcd = "spell",            

            startsCombat = false,
            texture = 1100170,

            essential = true, -- new flag, will allow recasting even in precombat APL.
            nomounted = true,

            usable = function () return not pet.alive end,
            handler = function ()
                summonPet( "ghoul", 3600 )
                if talent.all_will_serve.enabled then summonPet( "skeleton", 3600 ) end
            end,
        },


        --[[ runeforging = {
            id = 53428,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 237523,

            usable = false,
            handler = function ()
            end,
        }, ]]


        scourge_strike = {
            id = 55090,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 237530,

            notalent = "clawing_shadows",

            handler = function ()
                gain( 3, "runic_power" )
                if debuff.festering_wound.stack > 1 then
                    applyDebuff( "target", "festering_wound", debuff.festering_wound.remains, debuff.festering_wound.stack - 1 )
                else removeDebuff( "target", "festering_wound" ) end
                apply_festermight( 1 )
            end,
        },


        soul_reaper = {
            id = 130736,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 636333,

            talent = "soul_reaper",

            handler = function ()
                applyDebuff( "target", "soul_reaper" )
            end,
        },


        summon_gargoyle = {
            id = 49206,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 458967,

            talent = "summon_gargoyle",

            handler = function ()
                summonPet( "gargoyle", 30 )
            end,
        },


        transfusion = {
            id = 288977,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = -20,
            spendType = "runic_power",

            startsCombat = false,
            texture = 237515,

            pvptalent = "transfusion",

            handler = function ()
                applyBuff( "transfusion" )
            end,
        },


        unholy_blight = {
            id = 115989,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 136132,

            talent = "unholy_blight",

            handler = function ()
                applyBuff( "unholy_blight" )
                applyDebuff( "unholy_blight_dot" )
            end,
        },


        unholy_frenzy = {
            id = 207289,
            cast = 0,
            cooldown = 75,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 136224,

            talent = "unholy_frenzy",

            handler = function ()
                applyBuff( "unholy_frenzy" )
                stat.haste = state.haste + 0.20
            end,
        },


        wraith_walk = {
            id = 212552,
            cast = 0,
            channeled = 4,
            cooldown = 60,
            gcd = "spell",

            startsCombat = false,
            texture = 1100041,

            talent = "wraith_walk",

            handler = function ()
                applyBuff( "wraith_walk" )
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

        cycle = true,

        potion = "potion_of_unbridled_fury",

        package = "Unholy",
    } )


    spec:RegisterSetting( "festermight_cycle", false, {
        name = "Festermight: Spread |T237530:0|t Wounds",
        desc = function ()
            return  "If checked, the addon will encourage you to spread Festering Wounds to multiple targets before |T136144:0|t Death and Decay.\n\n" ..
                    "Requires |cFF" .. ( state.azerite.festermight.enabled and "00FF00" or "FF0000" ) .. "Festermight|r (Azerite)\n" .. 
                    "Requires |cFF" .. ( state.settings.cycle and "00FF00" or "FF0000" ) .. "Recommend Target Swaps|r in |cFFFFD100Targeting|r section."
        end,
        type = "toggle",
        width = "full"
    } )  


    spec:RegisterPack( "Unholy", 20200525, [[dCuADbqib0JeaTjH0Oirofj0ReknlHWTKsjTlc)siAyOqoMufltQkptkfMgkuxtQQ2Muk6Bcq14KsP6CcaADsPenpPuDpu0(irDqbaSqPk9qbizIcaKlkarTrPukDsbiYkrbVukLq3ukLIDkLyOcqOLkabpfQMQqXvLsjyRcau7LI)IyWu6WuTyP4XqMmQUSQnd4Zqz0a50kwTaqVMemBsDBuA3I(TKHlOJlaLLd65enDLUojTDHQVlqJxasDEPY6LsA(a1(rAtpMym4CFVPL(yuFmIr93x)IE6Ppg3FaObF7cVbp0rk4y3GNo7n4TfsqLUZGh6D6Y5Mym4YsfIUbh0UHY2YiJeBwqQncuXgPCyv1(ovIGoWgPCyrrAWBuh9gqknngCUV30sFmQpgXO(7RFrp90hJ7pGBWLHhzAPV(7ZGdA48NMgdo)sKbpaP22cjOs3rTbaDFbrTTfZbd0sziaPwq7gkBlJmsSzbP2iqfBKYHvv77ujc6aBKYHffjLHaKABB8oQTV(JGA7Jr9XikdugcqQnGcKNyx2wsziaP22k1gaGZpNABBMKtTTTW)wVGYqasTTvQnGQY4hUNtTRdX(sgaQfvjF2Psj1Uf1cpMQ2HulQs(StLsbLHaKABRuBabhnUwgzBBLl1wauBaXk4Hu7g8UcsHbxpYvAIXGFP8j6stmMw6XeJb)P3Op30RbhbN9WXn4q18IDypzlspuRYulgItTrPwOAoisyf8qQTDQLXmYG7ODQ0GZE2c2rkaIwfnCchENvAwtl9zIXG)0B0NB61GJGZE44gC(9feXtoHFK3j2bPWKyulyWuB4xHhwicgOsvlC0oXp1gLAD0oXp55zNlPwMuBpgChTtLg8gDvCsbqwqN88SDM10sByIXG)0B0NB61GJGZE44gCLOwuvAEfmfEyHCDxO8c4z9jLuB7uBBsTrPwuvAEfmfoKTJuaKf0j87Cb8S(KsQvzQfvLMxbtbQs(t55e9aCGcIUaEwFsj1Qi1cgm1IQsZRGPWHSDKcGSGoHFNlGN1NusTTtT9rTGbtTOccvd3PsPyYda4n6twO6cs80B0NBWD0ovAWXuDiF8KuaeV1dRfKznTWytmg8NEJ(CtVgCeC2dh3G3OcaiGhPG(sjbOGOludPwWGP2gvaab8if0xkjafeDcQuZ9qHCDKcuB7uBp9yWD0ovAWxqNOMnLAYjafeDZAAPFtmg8NEJ(CtVgCeC2dh3Ghi1YVVGiEYj8J8oXoifMeZG7ODQ0Gduiv55eV1dN9KM7SM10sBAIXG)0B0NB61GJGZE44gCETcuLONl03ZjaAN9KgvykGN1NusTmPwgzWD0ovAWrvIEUqFpNaOD2BwtlbCtmg8NEJ(CtVgCeC2dh3Ghi1YVVGiEYj8J8oXoifMeZG7ODQ0GhQchGUjXinAxUM10sB3eJb)P3Op30RbhbN9WXn4RRFUchY2rkaYc6eUZMNlE6n6ZP2Ou7LYNOlIpYPssbqcpe4ODQuWozbP2OuBJkaGqnbv6oICHpXwqc1qQfmyQ9s5t0fXh5ujPaiHhcC0ovkyNSGuBuQn8RWdlebduPQfoAN4NAbdMAxx)CfoKTJuaKf0jCNnpx80B0NtTrP2WVcpSqemqLQw4ODIFQnk1IQsZRGPWHSDKcGSGoHFNlGN1NusTktTTjJOwWGP211pxHdz7ifazbDc3zZZfp9g95uBuQn8RWHSDemqLQw4ODIFdUJ2PsdEWcQ5X)Ke4Lv6j6M10saOjgd(tVrFUPxdoco7HJBWdKA53xqep5e(rENyhKctIrTrP2gvaaHAcQ0De5cFITGeQHuBuQnqQ9s5t0fXh5ujPaiHhcC0ovkyNSGuBuQnqQDD9Zv4q2osbqwqNWD28CXtVrFo1cgm1Uoe7Ryh2t2IWNtTTtTOQ08kyk8Wc56Uq5fWZ6tkn4oANkn4blOMh)tsGxwPNOBwtl9Witmg8NEJ(CtVgCeC2dh3Ghi1YVVGiEYj8J8oXoifMeZG7ODQ0GdNWq9jtsKHo6M10sp9yIXG7ODQ0GdVhojgbq7SxAWF6n6Zn9AwZAW5hWv1Rjgtl9yIXG7ODQ0GZojNaa)B9g8NEJ(CtVM10sFMym4p9g95MEn4vObx(1G7ODQ0Gh3HJ3OVbpURvVbhvLMxbtHuLLTscMdXQo9fWZ6tkP22P2(P2Ou766NRqQYYwjbZHyvN(INEJ(CdEChssN9g8WQ0tIrakibZHyvN(M10sByIXG)0B0NB61GJGZE44gCOAoisyf8qb)adAwQvzQTn7NAJsTkrTHFfyoeR60x4ODIFQfmyQnqQDD9ZvivzzRKG5qSQtFXtVrFo1Qi1gLAHQ5f8dmOzPwLzsT9BWD0ovAWDiYZt2ccFUM10cJnXyWF6n6Zn9AWrWzpCCdE4xbMdXQo9foAN4NAbdMAdKAxx)Cfsvw2kjyoeR60x80B0NBWD0ovAWB0vXjaQWoZAAPFtmg8NEJ(CtVgCeC2dh3G3OcaiutqLUJaaF2ANqnKAbdMAd)kWCiw1PVWr7e)ulyWuRsu766NRWHSDKcGSGoH7S55INEJ(CQnk1g(v4HfIGbQu1chTt8tTkAWD0ovAWBouEOctIzwtlTPjgd(tVrFUPxdoco7HJBWvIABubaeQjOs3rKl8j2csOgsTrP2gvaabWL7HSdgOvapRpPKABNj12p1Qi1cgm16ODIFYZZoxsTkZKA7JAJsTkrTnQaac1euP7iYf(eBbjudPwWGP2gvaabWL7HSdgOvapRpPKABNj12p1QOb3r7uPbxpyGwjjaQYXyFUM10sa3eJb)P3Op30RbhbN9WXn4krTHFfyoeR60x4ODIFQnk1UU(5kKQSSvsWCiw1PV4P3OpNAvKAbdMAd)k8WcrWavQAHJ2j(n4oANkn4EIUCHUMGCT2SMwA7Mym4p9g95MEn4i4ShoUb3r7e)KNNDUKAvMj12h1cgm1Qe1cvZl4hyqZsTkZKA7NAJsTq1CqKWk4Hc(bg0SuRYmP22KruRIgChTtLgChI88KqvT8M10saOjgd(tVrFUPxdoco7HJBWvIAd)kWCiw1PVWr7e)uBuQDD9ZvivzzRKG5qSQtFXtVrFo1Qi1cgm1g(v4HfIGbQu1chTt8BWD0ovAWbg4B0vXnRPLEyKjgd(tVrFUPxdoco7HJBWBubaeQjOs3rKl8j2csOgsTrPwhTt8tEE25sQLj12d1cgm12OcaiaUCpKDWaTc4z9jLuB7ulgItTrPwhTt8tEE25sQLj12Jb3r7uPbVXXifazHdsbPznT0tpMym4p9g95MEn4i4ShoUbFh2tTktT9XiQfmyQnqQ9bm1jm8Cb0zdNeJ4SH6zv5NGnyE8sVKNytEQfmyQnqQ9bm1jm8Cr8rovskac)SJ8gChTtLgCv5jZEwPznT0tFMym4p9g95MEn4oANkn4ERsqo0LeGkxsbqcRGhAWrWzpCCdUsu7LYNOlIpYPssbqcpe4ODQu80B0NtTrP2aP211pxHAcQ0Dea4Zw7ep9g95uRIulyWuRsuBGu7LYNOlqvYFkpNOhGduq0fSEaSGuBuQnqQ9s5t0fXh5ujPaiHhcC0ovkE6n6ZPwfn4PZEdU3QeKdDjbOYLuaKWk4HM10spTHjgd(tVrFUPxdUJ2PsdU3QeKdDjbOYLuaKWk4HgCeC2dh3GJQsZRGPWdlKR7cLxapRpPKABNA7HXuBuQvjQ9s5t0fOk5pLNt0dWbki6cwpawqQfmyQ9s5t0fXh5ujPaiHhcC0ovkE6n6ZP2Ou766NRqnbv6oca8zRDINEJ(CQvrdE6S3G7Tkb5qxsaQCjfajScEOznT0dJnXyWF6n6Zn9AWD0ovAW9wLGCOljavUKcGewbp0GJGZE44g8DypzlcFo12o1IQsZRGPWdlKR7cLxapRpPKAJLABdgBWtN9gCVvjih6scqLlPaiHvWdnRPLE63eJb)P3Op30Rb3r7uPb3LGI75LeO3AbjOc6Adoco7HJBW5Vrfaqa9wlibvqxt4VrfaqixhPa12o12JbpD2BWDjO4EEjb6TwqcQGU2SMw6PnnXyWF6n6Zn9AWD0ovAWDjO4EEjb6TwqcQGU2GJGZE44g8WVcmvhYhpjfaXB9WAbjC0oXp1gLAd)k8WcrWavQAHJ2j(n4PZEdUlbf3ZljqV1csqf01M10spbCtmg8NEJ(CtVgChTtLgCxckUNxsGERfKGkORn4i4ShoUbhvLMxbtHhwix3fkVaEN3rTrPwLO2lLprxGQK)uEorpahOGOly9aybP2Ou7oSNSfHpNABNArvP5vWuGQK)uEorpahOGOlGN1NusTXsT9XiQfmyQnqQ9s5t0fOk5pLNt0dWbki6cwpawqQvrdE6S3G7sqX98sc0BTGeubDTznT0tB3eJb)P3Op30Rb3r7uPb3LGI75LeO3AbjOc6Adoco7HJBW3H9KTi85uB7ulQknVcMcpSqUUluEb8S(KsQnwQTpgzWtN9gCxckUNxsGERfKGkORnRPLEcanXyWF6n6Zn9AWD0ovAWJpYPssbq4NDK3GJGZE44gCLOwuvAEfmfEyHCDxO8c4DEh1gLA5VrfaqaC5E4KyKGLAYfY1rkqTkZKAzm1gLAVu(eDr8rovskas4HahTtLINEJ(CQvrQfmyQTrfaqOMGkDhba(S1oHAi1cgm1g(vG5qSQtFHJ2j(n4PZEdE8rovskac)SJ8M10sFmYeJb)P3Op30Rb3r7uPbh6SHtIrC2q9SQ8tWgmpEPxYtSjVbhbN9WXn4OQ08kyk8Wc56Uq5fWZ6tkP22P2(OwWGP211pxHdz7ifazbDc3zZZfp9g95ulyWul0ho5XFUcNZLIjP22P2(n4PZEdo0zdNeJ4SH6zv5NGnyE8sVKNytEZAAPVEmXyWF6n6Zn9AWD0ovAWB6WQ8KMFIRz90rgCeC2dh3GJQsZRGPqQYYwjbZHyvN(c4z9jLuRYuBBYiQfmyQnqQDD9ZvivzzRKG5qSQtFXtVrFo1gLA3H9uRYuBFmIAbdMAdKAFatDcdpxaD2WjXioBOEwv(jydMhV0l5j2K3GNo7n4nDyvEsZpX1SE6iZAAPV(mXyWF6n6Zn9AWD0ovAWdGxsavb1hAWrWzpCCdE4xbMdXQo9foAN4NAbdMAdKAxx)Cfsvw2kjyoeR60x80B0NtTrP2Dyp1Qm12hJOwWGP2aP2hWuNWWZfqNnCsmIZgQNvLFc2G5Xl9sEIn5n4PZEdEa8scOkO(qZAAPV2WeJb)P3Op30Rb3r7uPbhZ1h5A9HssZDfm4i4ShoUbp8RaZHyvN(chTt8tTGbtTbsTRRFUcPklBLemhIvD6lE6n6ZP2Ou7oSNAvMA7JrulyWuBGu7dyQty45cOZgojgXzd1ZQYpbBW84LEjpXM8g80zVbhZ1h5A9HssZDfmRPL(ySjgd(tVrFUPxdUJ2PsdogSsmjjeoSUMaDSBWrWzpCCdounp12otQTnO2OuRsu7oSNAvMA7JrulyWuBGu7dyQty45cOZgojgXzd1ZQYpbBW84LEjpXM8uRIg80zVbhdwjMKechwxtGo2nRPL(63eJb)P3Op30RbhbN9WXn4OQ08kykCiBhPailOt435c4DEh1cgm1g(vG5qSQtFHJ2j(PwWGP2gvaaHAcQ0Dea4Zw7eQHgChTtLg8WANknRPL(Attmg8NEJ(CtVgCeC2dh3GZRveFGQ6Nlju7yQxapRpPKABNj1IH4gChTtLg8sDBG3vWSMw6lGBIXG)0B0NB61G7ODQ0GJCTM4ODQKOh5AW1JCjPZEd(LYNOlnRPL(A7Mym4p9g95MEn4oANkn4ixRjoANkj6rUgC9ixs6S3GJQsZRGP0SMw6la0eJb)P3Op30RbhbN9WXn4oAN4N88SZLuRYmP2(m4oANkn4ixRjoANkj6rUgC9ixs6S3G71nRPL2GrMym4p9g95MEn4oANkn4ixRjoANkj6rUgC9ixs6S3GJ98WbzwZAWdHhvSn(AIX0spMym4oANkn4H1ovAWF6n6Zn9Awtl9zIXG7ODQ0Gd9rEc)o3G)0B0NB61SMwAdtmg8NEJ(CtVg80zVb3BvcYHUKau5skasyf8qdUJ2PsdU3QeKdDjbOYLuaKWk4HM10cJnXyWF6n6Zn9AW5x7Dg8(m4oANkn4oKTJuaKf0j87CZAwdoQknVcMstmMw6XeJb3r7uPb3HSDKcGSGoHFNBWF6n6Zn9Awtl9zIXG)0B0NB61GJGZE44gC(BubaeaxUhojgjyPMCHCDKcuRYmPwgtTrPwLOwhTt8tEE25sQvzMuBFulyWuBGu7LYNOlIpYPssbqcpe4ODQu80B0NtTGbtTbsTERho7fSoMQKuaKf0j87CXtVrFo1cgm1EP8j6I4JCQKuaKWdboANkfp9g95uBuQvjQDD9ZvOMGkDhba(S1oXtVrFo1gLArvP5vWuOMGkDhba(S1ob8S(KsQTDMuBBqTGbtTbsTRRFUc1euP7iaWNT2jE6n6ZPwfPwfn4oANkn4EyHCDxO8M10sByIXG)0B0NB61GJGZE44g8aPwOpCYJ)CfoNlfpGEKRKAbdMAH(Wjp(Zv4CUumj1Qm12t)gChTtLgCUdvGSqpLafK13PsZAAHXMym4p9g95MEn4i4ShoUbhQMdIewbpuWpWGMLABNA7HXgChTtLgCPklBLemhIvD6Bwtl9BIXG)0B0NB61GJGZE44g8lLprxeFKtLKcGeEiWr7uP4P3OpNAJsTHFfEyHiyGkvTWr7e)ulyWul)nQaacGl3dNeJeSutUqUosbQTDQLXuBuQnqQ9s5t0fXh5ujPaiHhcC0ovkE6n6ZP2OuRsuBGuR36HZEbRJPkjfazbDc)ox80B0NtTGbtTERho7fSoMQKuaKf0j87CXtVrFo1gLAd)k8WcrWavQAHJ2j(Pwfn4oANkn4QjOs3raGpBTZSMwAttmg8NEJ(CtVgCeC2dh3G7ODIFYZZoxsTkZKA7JAJsTkrTkrTOQ08kyk43xqep5e(rENaEwFsj12otQfdXP2OuBGu766NRGFGrFXtVrFo1Qi1cgm1Qe1IQsZRGPGFGrFb8S(KsQTDMulgItTrP211pxb)aJ(INEJ(CQvrQvrdUJ2PsdUAcQ0Dea4Zw7mRPLaUjgd(tVrFUPxdUJ2PsdUSu1e49Wdn4i4ShoUbFDi2xXoSNSfHpNABNAB7uBuQDDi2xXoSNSfHpNAvMAzSbh1H0NSoe7R00spM10sB3eJb)P3Op30RbhbN9WXn4krTbsTqF4Kh)5kCoxkEa9ixj1cgm1c9HtE8NRW5CPysQvzQTpgrTksTrPwOAEQTDMuRsuBpuBBLABubaeQjOs3raGpBTtOgsTkAWD0ovAWLLQMaVhEOznTeaAIXG7ODQ0GRMGkDhPrpyGwd(tVrFUPxZAwdUx3eJPLEmXyWF6n6Zn9AWrWzpCCdoQknVcMcpSqUUluEb8S(KsdUJ2Psdo)(cI4jNWpY7mRPL(mXyWF6n6Zn9AWrWzpCCdoQknVcMcpSqUUluEb8S(KsdUJ2Psdo)aJ(M10sByIXG)0B0NB61GJGZE44gC(9feXtoHFK3j2bPWKyuBuQfQMdIewbpuWpWGMLABNA7HXuBuQnqQDD9Zv0OcL7KyezbVu80B0NtTrP2aP24oC8g9fHvPNeJauqcMdXQo9n4oANkn4pC4NDqM10cJnXyWF6n6Zn9AWrWzpCCdo)(cI4jNWpY7e7GuysmQnk1Qe1gi1YVVGikKdgOvaeSut(5K1HyFLuBuQDD9Zv0OcL7KyezbVu80B0NtTksTrP2aP24oC8g9fHvPNeJauqcMdXQo9n4oANkn4pC4NDqM10s)Mym4p9g95MEn4i4ShoUbNFFbr8Kt4h5DIDqkmjg1gLArvP5vWu4HfY1DHYlGN1NuAWD0ovAWLOsfIDICHJc3SMwAttmg8NEJ(CtVgCeC2dh3GZVVGiEYj8J8oXoifMeJAJsTOQ08kyk8Wc56Uq5fWZ6tkn4oANkn4iThCsmIeKZRGsZAAjGBIXG)0B0NB61GJGZE44g8aP24oC8g9fHvPNeJauqcMdXQo9n4oANkn4pC4NDqM10sB3eJb)P3Op30Rb3r7uPbh4Y9WjXiYfokCdoco7HJBW5VrfaqaC5E4KyKGLAYfY1rkqTTZKA7JAJsTOQ08kyk43xqep5e(rENaEwFsj1gLArvP5vWu4HfY1DHYlGN1NusTktT9tTrPwLOwuvAEfmfoKTJuaKf0j87Cb8S(KsQvzQTFQfmyQLFFbruihmqRGpsVrFIxlNAv0GJ6q6twhI9vAAPhZAAja0eJb)P3Op30RbhbN9WXn4nQaacPkN)KWRIvaVJwQnk1cvZl2H9KTimMAvMAXqCdUJ2Psdo)(cIGQrBwtl9Witmg8NEJ(CtVgCeC2dh3G3OcaiKQC(tcVkwb8oAP2OuBGuBChoEJ(IWQ0tIrakibZHyvN(ulyWuB4xbMdXQo9foAN43G7ODQ0GZVVGiOA0M10sp9yIXG)0B0NB61GJGZE44gCOAoisyf8qb)adAwQTDQThgtTrPwLOwuvAEfmfEyHCDxO8c4z9jLuRYuB)ulyWul)nQaacGl3dNeJeSutUqUosbQvzQLXuRIuBuQnqQnUdhVrFryv6jXiafKG5qSQtFdUJ2Psdo)(cIGQrBwtl90Njgd(tVrFUPxdUJ2PsdUevQqStKlCu4gCeC2dh3GRe1Qe1IQsZRGPWHSDKcGSGoHFNlGN1NusTktT9tTGbtT87liIc5GbAf8r6n6t8A5uRIuBuQvjQfvLMxbtHhwix3fkVaEwFsj1Qm12p1gLA5VrfaqaC5E4KyKGLAYfY1rkqTktTmIAbdMA5VrfaqaC5E4KyKGLAYfY1rkqTktTmMAvKAJsTkrT7WEYwe(CQTDQfvLMxbtb)(cI4jNWpY7eWZ6tkP2yP2Eye1cgm1Ud7jBr4ZPwLPwuvAEfmfEyHCDxO8c4z9jLuRIuRIgCuhsFY6qSVstl9ywtl90gMym4p9g95MEn4oANkn4iThCsmIeKZRGsdoco7HJBWvIAvIArvP5vWu4q2osbqwqNWVZfWZ6tkPwLP2(PwWGPw(9ferHCWaTc(i9g9jETCQvrQnk1Qe1IQsZRGPWdlKR7cLxapRpPKAvMA7NAJsT83OcaiaUCpCsmsWsn5c56ifOwLPwgrTGbtT83OcaiaUCpCsmsWsn5c56ifOwLPwgtTksTrPwLO2DypzlcFo12o1IQsZRGPGFFbr8Kt4h5Dc4z9jLuBSuBpmIAbdMA3H9KTi85uRYulQknVcMcpSqUUluEb8S(KsQvrQvrdoQdPpzDi2xPPLEmRPLEySjgd(tVrFUPxdoco7HJBWHQ5GiHvWdf8dmOzP22P2(ye1gLAdKAJ7WXB0xewLEsmcqbjyoeR603G7ODQ0GZVVGiOA0M10sp9BIXG)0B0NB61GJGZE44gCLOwLOwLOwLOw(BubaeaxUhojgjyPMCHCDKcuB7ulJP2OuBGuBJkaGqnbv6oca8zRDc1qQvrQfmyQL)gvaabWL7HtIrcwQjxixhPa12o12guRIuBuQfvLMxbtHhwix3fkVaEwFsj12o12guRIulyWul)nQaacGl3dNeJeSutUqUosbQTDQThQvrQnk1Qe1IQsZRGPWHSDKcGSGoHFNlGN1NusTktT9tTGbtT87liIc5GbAf8r6n6t8A5uRIgChTtLgCGl3dNeJix4OWnRPLEAttmg8NEJ(CtVgCeC2dh3GZVVGiEYj8J8oXoifMeZG7ODQ0GlrLke7e5chfUznT0ta3eJb)P3Op30RbhbN9WXn4bsTXD44n6lcRspjgbOGemhIvD6BWD0ovAW53xqeunAZAwdo2ZdhKjgtl9yIXG)0B0NB61GJGZE44g8gvaaHuLZFs4vXkG3rl1gLAHQ5f7WEYwegtTktTyio1gLAdKAJ7WXB0xewLEsmcqbjyoeR60NAbdMAd)kWCiw1PVWr7e)gChTtLgC(9febvJ2SMw6ZeJb)P3Op30RbhbN9WXn4q1CqKWk4Hc(bg0SuB7uBpmMAJsTq18IDypzlcJPwLPwmeNAJsTbsTXD44n6lcRspjgbOGemhIvD6BWD0ovAW53xqeunAZAAPnmXyWF6n6Zn9AWrWzpCCdUsuRsul)nQaacGl3dNeJeSutUqnKAJsTkrTOQ08kyk8Wc56Uq5fWZ6tkPwLP2(P2OuRsuBGu7LYNOlIpYPssbqcpe4ODQu80B0NtTGbtTbsTRRFUc1euP7iaWNT2jE6n6ZPwfPwWGP2lLprxeFKtLKcGeEiWr7uP4P3OpNAJsTRRFUc1euP7iaWNT2jE6n6ZP2OulQknVcMc1euP7iaWNT2jGN1NusTktTTj1Qi1Qi1cgm1YFJkaGa4Y9WjXibl1KlKRJuGAvMAzm1Qi1gLAvIArvP5vWu4q2osbqwqNWVZfWZ6tkPwLP2(PwWGPw(9ferHCWaTc(i9g9jETCQvrdUJ2PsdUevQqStKlCu4M10cJnXyWF6n6Zn9AWrWzpCCdUsuRsul)nQaacGl3dNeJeSutUqnKAJsTkrTOQ08kyk8Wc56Uq5fWZ6tkPwLP2(P2OuRsuBGu7LYNOlIpYPssbqcpe4ODQu80B0NtTGbtTbsTRRFUc1euP7iaWNT2jE6n6ZPwfPwWGP2lLprxeFKtLKcGeEiWr7uP4P3OpNAJsTRRFUc1euP7iaWNT2jE6n6ZP2OulQknVcMc1euP7iaWNT2jGN1NusTktTTj1Qi1Qi1cgm1YFJkaGa4Y9WjXibl1KlKRJuGAvMAzm1Qi1gLAvIArvP5vWu4q2osbqwqNWVZfWZ6tkPwLP2(PwWGPw(9ferHCWaTc(i9g9jETCQvrdUJ2Psdos7bNeJib58kO0SMw63eJb)P3Op30RbhbN9WXn4q1CqKWk4Hc(bg0SuB7uBFmIAJsTbsTXD44n6lcRspjgbOGemhIvD6BWD0ovAW53xqeunAZAAPnnXyWF6n6Zn9AWrWzpCCdo)nQaacGl3dNeJeSutUqUosbQTDQLXuBuQvjQfvLMxbtHhwix3fkVaEwFsj12o12guBuQvjQnqQ9s5t0fXh5ujPaiHhcC0ovkE6n6ZPwWGP2aP211pxHAcQ0Dea4Zw7ep9g95ulyWu7LYNOlIpYPssbqcpe4ODQu80B0NtTrP211pxHAcQ0Dea4Zw7ep9g95uBuQfvLMxbtHAcQ0Dea4Zw7eWZ6tkP22P2ao1Qi1Qi1cgm1YFJkaGa4Y9WjXibl1KlKRJuGABNA7HAJsTkrTOQ08kykCiBhPailOt435c4z9jLuRYuB)ulyWul)(cIOqoyGwbFKEJ(eVwo1QOb3r7uPbh4Y9WjXiYfokCZAAjGBIXG)0B0NB61GJGZE44g8aP24oC8g9fHvPNeJauqcMdXQo9n4oANkn487licQgTznRzn4XpuovAAPpg1hJyu)mQnm4bDyojM0GhqInSG75uBBsToANkPw9ixPGYGbpewaJ(g8aKABlKGkDh1ga09fe12wmhmqlLHaKAbTBOSTmYiXMfKAJavSrkhwvTVtLiOdSrkhwuKugcqQTTX7O2(6pcQTpg1hJOmqziaP2akqEIDzBjLHaKABRuBaao)CQTTzso122c)B9ckdbi12wP2aQkJF4Eo1Uoe7lzaOwuL8zNkLu7wul8yQAhsTOk5ZovkfugcqQTTsTbeC04AzKTTvUuBbqTbeRGhsTBW7kifugOmeGuBa5a6Ju3ZP2MduWtTOITXxQT5ytkfuBaae6HRKAZkBRGCilGQMAD0ovkP2k1Dckdbi16ODQukcHhvSn(Yeq7sfOmeGuRJ2PsPieEuX24BSmJeOkoLHaKAD0ovkfHWJk2gFJLzKUkg7Z13Pskdbi1INEOeuTul0ho12OcaCo1kxFLuBZbk4PwuX24l12CSjLuRNCQne(2AyT7Kyu7iPwELxqziaPwhTtLsri8OITX3yzgPm9qjOAjY1xjLbhTtLsri8OITX3yzgzyTtLugC0ovkfHWJk2gFJLzKqFKNWVZPm4ODQukcHhvSn(glZivLNm7zJiD2Z0BvcYHUKau5skasyf8qkdoANkLIq4rfBJVXYmshY2rkaYc6e(DEe8R9oM9rzGYqasTbKdOpsDpNAF8d7O2Dyp1UGo16OTGu7iPwpUpAVrFbLbhTtLsMStYjaW)wpLbhTtLYyzgzChoEJ(rKo7zgwLEsmcqbjyoeR60pI4Uw9mrvP5vWuivzzRKG5qSQtFb8S(KY27p666NRqQYYwjbZHyvN(INEJ(Ckdbi1gqWrJRLrqTbK2ZkJGA9KtT1c6qQTWqCjLbhTtLYyzgPdrEEYwq4ZnIbGjunhejScEOGFGbnRYTz)rvk8RaZHyvN(chTt8dgCGRRFUcPklBLemhIvD6lE6n6ZvmkunVGFGbnRYm7NYGJ2PszSmJSrxfNaOc7Iyayg(vG5qSQtFHJ2j(bdoW11pxHuLLTscMdXQo9fp9g95ugC0ovkJLzKnhkpuHjXIyay2OcaiutqLUJaaF2ANqnem4WVcmhIvD6lC0oXpyWkTU(5kCiBhPailOt4oBEU4P3OppA4xHhwicgOsvlC0oXVIugC0ovkJLzK6bd0kjbqvog7ZnIbGPsnQaac1euP7iYf(eBbjudJ2OcaiaUCpKDWaTc4z9jLTZSFfbd2r7e)KNNDUuzM9fvPgvaaHAcQ0De5cFITGeQHGb3OcaiaUCpKDWaTc4z9jLTZSFfPm4ODQuglZi9eD5cDnb5ADedatLc)kWCiw1PVWr7e)rxx)Cfsvw2kjyoeR60x80B0NRiyWHFfEyHiyGkvTWr7e)ugC0ovkJLzKoe55jHQA5Jyay6ODIFYZZoxQmZ(adwjOAEb)adAwLz2FuOAoisyf8qb)adAwLz2MmsrkdoANkLXYmsGb(gDv8igaMkf(vG5qSQtFHJ2j(JUU(5kKQSSvsWCiw1PV4P3OpxrWGd)k8WcrWavQAHJ2j(Pm4ODQuglZiBCmsbqw4GuqgXaWSrfaqOMGkDhrUWNyliHAyuhTt8tEE25sM9agCJkaGa4Y9q2bd0kGN1Nu2ogIh1r7e)KNNDUKzpugOmeGuBaLQClwQDHtQWxj1QkDStzWr7uPmwMrQkpz2ZkJyayUd7vUpgbgCGpGPoHHNlGoB4KyeNnupRk)eSbZJx6L8eBYdgCGpGPoHHNlIpYPssbq4NDKNYGJ2PszSmJuvEYSNnI0zptVvjih6scqLlPaiHvWdJyayQ0LYNOlIpYPssbqcpe4ODQu80B0NhnW11pxHAcQ0Dea4Zw7ep9g95kcgSsbEP8j6cuL8NYZj6b4afeDbRhaly0aVu(eDr8rovskas4HahTtLINEJ(CfPm4ODQuglZivLNm7zJiD2Z0BvcYHUKau5skasyf8WigaMOQ08kyk8Wc56Uq5fWZ6tkBVhghvPlLprxGQK)uEorpahOGOly9aybbd(s5t0fXh5ujPaiHhcC0ovkE6n6ZJUU(5kutqLUJaaF2AN4P3OpxrkdoANkLXYmsv5jZE2isN9m9wLGCOljavUKcGewbpmIbG5oSNSfHpVDuvAEfmfEyHCDxO8c4z9jLX2gmMYGJ2PszSmJuvEYSNnI0zptxckUNxsGERfKGkORJyayYFJkaGa6TwqcQGUMWFJkaGqUosH27HYGJ2PszSmJuvEYSNnI0zptxckUNxsGERfKGkORJyayg(vGP6q(4jPaiERhwliHJ2j(Jg(v4HfIGbQu1chTt8tzWr7uPmwMrQkpz2Zgr6SNPlbf3ZljqV1csqf01rmamrvP5vWu4HfY1DHYlG35Drv6s5t0fOk5pLNt0dWbki6cwpawWO7WEYwe(82rvP5vWuGQK)uEorpahOGOlGN1NugBFmcm4aVu(eDbQs(t55e9aCGcIUG1dGfurkdoANkLXYmsv5jZE2isN9mDjO4EEjb6TwqcQGUoIbG5oSNSfHpVDuvAEfmfEyHCDxO8c4z9jLX2hJOm4ODQuglZivLNm7zJiD2Zm(iNkjfaHF2r(igaMkHQsZRGPWdlKR7cLxaVZ7IYFJkaGa4Y9WjXibl1KlKRJuqzMmo6LYNOlIpYPssbqcpe4ODQu80B0NRiyWnQaac1euP7iaWNT2judbdo8RaZHyvN(chTt8tzWr7uPmwMrQkpz2Zgr6SNj0zdNeJ4SH6zv5NGnyE8sVKNyt(igaMOQ08kyk8Wc56Uq5fWZ6tkBVpWGxx)CfoKTJuaKf0jCNnpx80B0Ndgm0ho5XFUcNZLIjBVFkdoANkLXYmsv5jZE2isN9mB6WQ8KMFIRz90rrmamrvP5vWuivzzRKG5qSQtFb8S(KsLBtgbgCGRRFUcPklBLemhIvD6lE6n6ZJUd7vUpgbgCGpGPoHHNlGoB4KyeNnupRk)eSbZJx6L8eBYtzWr7uPmwMrQkpz2Zgr6SNza8scOkO(WigaMHFfyoeR60x4ODIFWGdCD9ZvivzzRKG5qSQtFXtVrFE0DyVY9XiWGd8bm1jm8Cb0zdNeJ4SH6zv5NGnyE8sVKNytEkdoANkLXYmsv5jZE2isN9mXC9rUwFOK0CxHigaMHFfyoeR60x4ODIFWGdCD9ZvivzzRKG5qSQtFXtVrFE0DyVY9XiWGd8bm1jm8Cb0zdNeJ4SH6zv5NGnyE8sVKNytEkdoANkLXYmsv5jZE2isN9mXGvIjjHWH11eOJ9igaMq18TZSnIQ0oSx5(yeyWb(aM6egEUa6SHtIrC2q9SQ8tWgmpEPxYtSjVIugC0ovkJLzKH1ovgXaWevLMxbtHdz7ifazbDc)oxaVZ7ado8RaZHyvN(chTt8dgCJkaGqnbv6oca8zRDc1qkdbi1224tU(KtIrTbapqv9ZLAdiQDm1tTJKADQneofC2okdoANkLXYmYsDBG3viIbGjVwr8bQQFUKqTJPEb8S(KY2zIH4ugC0ovkJLzKixRjoANkj6rUrKo7zEP8j6skdoANkLXYmsKR1ehTtLe9i3isN9mrvP5vWuszWr7uPmwMrICTM4ODQKOh5gr6SNPxpIbGPJ2j(jpp7CPYm7JYGJ2PszSmJe5AnXr7ujrpYnI0zptSNhoikdugcqQnaqfqMAH167ujLbhTtLsHxNj)(cI4jNWpY7IyayIQsZRGPWdlKR7cLxapRpPKYGJ2PsPWRhlZi5hy0pIbGjQknVcMcpSqUUluEb8S(KskdoANkLcVESmJ8Hd)SdkIbGj)(cI4jNWpY7e7GuysSOq1CqKWk4Hc(bg0ST3dJJg466NROrfk3jXiYcEP4P3OppAGXD44n6lcRspjgbOGemhIvD6tzWr7uPu41JLzKpC4NDqrmam53xqep5e(rENyhKctIfvPa53xqefYbd0kacwQj)CY6qSVYORRFUIgvOCNeJil4LINEJ(CfJgyChoEJ(IWQ0tIrakibZHyvN(ugC0ovkfE9yzgPevQqStKlCu4rmam53xqep5e(rENyhKctIffvLMxbtHhwix3fkVaEwFsjLbhTtLsHxpwMrI0EWjXisqoVckJyayYVVGiEYj8J8oXoifMelkQknVcMcpSqUUluEb8S(KskdoANkLcVESmJ8Hd)SdkIbGzGXD44n6lcRspjgbOGemhIvD6tzWr7uPu41JLzKaxUhojgrUWrHhbQdPpzDi2xjZEIyayYFJkaGa4Y9WjXibl1KlKRJuODM9ffvLMxbtb)(cI4jNWpY7eWZ6tkJIQsZRGPWdlKR7cLxapRpPu5(JQeQknVcMchY2rkaYc6e(DUaEwFsPY9dgm)(cIOqoyGwbFKEJ(eVwUIugC0ovkfE9yzgj)(cIGQrhXaWSrfaqiv58NeEvSc4D0gfQMxSd7jBrySYyioLbhTtLsHxpwMrYVVGiOA0rmamBubaesvo)jHxfRaEhTrdmUdhVrFryv6jXiafKG5qSQtFWGd)kWCiw1PVWr7e)ugC0ovkfE9yzgj)(cIGQrhXaWeQMdIewbpuWpWGMT9EyCuLqvP5vWu4HfY1DHYlGN1NuQC)GbZFJkaGa4Y9WjXibl1KlKRJuqzgRy0aJ7WXB0xewLEsmcqbjyoeR60NYGJ2PsPWRhlZiLOsfIDICHJcpcuhsFY6qSVsM9eXaWujLqvP5vWu4q2osbqwqNWVZfWZ6tkvUFWG53xqefYbd0k4J0B0N41YvmQsOQ08kyk8Wc56Uq5fWZ6tkvU)O83OcaiaUCpCsmsWsn5c56ifuMrGbZFJkaGa4Y9WjXibl1KlKRJuqzgRyuL2H9KTi85TJQsZRGPGFFbr8Kt4h5Dc4z9jLX2dJadEh2t2IWNRmQknVcMcpSqUUluEb8S(KsfvKYGJ2PsPWRhlZirAp4KyejiNxbLrG6q6twhI9vYSNigaMkPeQknVcMchY2rkaYc6e(DUaEwFsPY9dgm)(cIOqoyGwbFKEJ(eVwUIrvcvLMxbtHhwix3fkVaEwFsPY9hL)gvaabWL7HtIrcwQjxixhPGYmcmy(BubaeaxUhojgjyPMCHCDKckZyfJQ0oSNSfHpVDuvAEfmf87liINCc)iVtapRpPm2EyeyW7WEYwe(CLrvP5vWu4HfY1DHYlGN1NuQOIugC0ovkfE9yzgj)(cIGQrhXaWeQMdIewbpuWpWGMT9(yu0aJ7WXB0xewLEsmcqbjyoeR60NYGJ2PsPWRhlZibUCpCsmICHJcpIbGPskPKs83OcaiaUCpCsmsWsn5c56ifANXrdSrfaqOMGkDhba(S1oHAOIGbZFJkaGa4Y9WjXibl1KlKRJuO92qXOOQ08kyk8Wc56Uq5fWZ6tkBVnuemy(BubaeaxUhojgjyPMCHCDKcT3JIrvcvLMxbtHdz7ifazbDc)oxapRpPu5(bdMFFbruihmqRGpsVrFIxlxrkdoANkLcVESmJuIkvi2jYfok8igaM87liINCc)iVtSdsHjXOm4ODQuk86XYms(9febvJoIbGzGXD44n6lcRspjgbOGemhIvD6tzGYGJ2PsPavLMxbtjthY2rkaYc6e(DoLbhTtLsbQknVcMYyzgPhwix3fkFedat(BubaeaxUhojgjyPMCHCDKckZKXrvYr7e)KNNDUuzM9bgCGxkFIUi(iNkjfaj8qGJ2PsXtVrFoyWb6TE4SxW6yQssbqwqNWVZfp9g95GbFP8j6I4JCQKuaKWdboANkfp9g95rvAD9ZvOMGkDhba(S1oXtVrFEuuvAEfmfQjOs3raGpBTtapRpPSDMTbyWbUU(5kutqLUJaaF2AN4P3OpxrfPm4ODQukqvP5vWuglZi5oubYc9ucuqwFNkJyaygi0ho5XFUcNZLIhqpYvcgm0ho5XFUcNZLIjvUN(Pm4ODQukqvP5vWuglZiLQSSvsWCiw1PFedatOAoisyf8qb)adA227HXugC0ovkfOQ08kykJLzKQjOs3raGpBTlIbG5LYNOlIpYPssbqcpe4ODQu80B0Nhn8RWdlebduPQfoAN4hmy(BubaeaxUhojgjyPMCHCDKcTZ4ObEP8j6I4JCQKuaKWdboANkfp9g95rvkqV1dN9cwhtvskaYc6e(DU4P3OphmyV1dN9cwhtvskaYc6e(DU4P3OppA4xHhwicgOsvlC0oXVIugC0ovkfOQ08kykJLzKQjOs3raGpBTlIbGPJ2j(jpp7CPYm7lQskHQsZRGPGFFbr8Kt4h5Dc4z9jLTZedXJg466NRGFGrFXtVrFUIGbReQknVcMc(bg9fWZ6tkBNjgIhDD9ZvWpWOV4P3OpxrfPm4ODQukqvP5vWuglZiLLQMaVhEyeOoK(K1HyFLm7jIbG56qSVIDypzlcFE7T9ORdX(k2H9KTi85kZykdoANkLcuvAEfmLXYmszPQjW7HhgXaWuPaH(Wjp(Zv4CUu8a6rUsWGH(Wjp(Zv4CUumPY9XifJcvZ3otL6PT2OcaiutqLUJaaF2ANqnurkdoANkLcuvAEfmLXYms1euP7in6bd0szGYGJ2PsP4s5t0LmzpBb7ifarRIgoHdVZkJyaycvZl2H9KTi9OmgIhfQMdIewbpSDgZikdoANkLIlLprxglZiB0vXjfazbDYZZ2fXaWKFFbr8Kt4h5DIDqkmjgyWHFfEyHiyGkvTWr7e)rD0oXp55zNlz2dLbhTtLsXLYNOlJLzKyQoKpEskaI36H1ckIbGPsOQ08kyk8Wc56Uq5fWZ6tkBVnJIQsZRGPWHSDKcGSGoHFNlGN1NuQmQknVcMcuL8NYZj6b4afeDb8S(KsfbdgvLMxbtHdz7ifazbDc)oxapRpPS9(adgvqOA4ovkftEaaVrFYcvxqINEJ(CkdoANkLIlLprxglZixqNOMnLAYjafe9igaMnQaac4rkOVusaki6c1qWGBubaeWJuqFPKauq0jOsn3dfY1rk0Ep9qzWr7uPuCP8j6YyzgjqHuLNt8wpC2tAUZgXaWmq(9feXtoHFK3j2bPWKyugC0ovkfxkFIUmwMrIQe9CH(Eobq7SpIbGjVwbQs0Zf675eaTZEsJkmfWZ6tkzYikdoANkLIlLprxglZidvHdq3KyKgTl3igaMbYVVGiEYj8J8oXoifMeJYGJ2PsP4s5t0LXYmYGfuZJ)jjWlR0t0JyayUU(5kCiBhPailOt4oBEU4P3Opp6LYNOlIpYPssbqcpe4ODQuWozbJ2OcaiutqLUJix4tSfKqnem4lLprxeFKtLKcGeEiWr7uPGDYcgn8RWdlebduPQfoAN4hm411pxHdz7ifazbDc3zZZfp9g95rd)k8WcrWavQAHJ2j(JIQsZRGPWHSDKcGSGoHFNlGN1NuQCBYiWGxx)CfoKTJuaKf0jCNnpx80B0Nhn8RWHSDemqLQw4ODIFkdoANkLIlLprxglZidwqnp(NKaVSsprpIbGzG87liINCc)iVtSdsHjXI2OcaiutqLUJix4tSfKqnmAGxkFIUi(iNkjfaj8qGJ2Psb7KfmAGRRFUchY2rkaYc6eUZMNlE6n6ZbdEDi2xXoSNSfHpVDuvAEfmfEyHCDxO8c4z9jLugC0ovkfxkFIUmwMrcNWq9jtsKHo6rmamdKFFbr8Kt4h5DIDqkmjgLbhTtLsXLYNOlJLzKW7HtIra0o7LugOm4ODQukWEE4GyYVVGiOA0rmamBubaesvo)jHxfRaEhTrHQ5f7WEYwegRmgIhnW4oC8g9fHvPNeJauqcMdXQo9bdo8RaZHyvN(chTt8tzWr7uPuG98WbflZi53xqeun6igaMq1CqKWk4Hc(bg0ST3dJJcvZl2H9KTimwzmepAGXD44n6lcRspjgbOGemhIvD6tzWr7uPuG98WbflZiLOsfIDICHJcpIbGPskXFJkaGa4Y9WjXibl1KludJQeQknVcMcpSqUUluEb8S(KsL7pQsbEP8j6I4JCQKuaKWdboANkfp9g95Gbh466NRqnbv6oca8zRDINEJ(Cfbd(s5t0fXh5ujPaiHhcC0ovkE6n6ZJUU(5kutqLUJaaF2AN4P3OppkQknVcMc1euP7iaWNT2jGN1NuQCBQOIGbZFJkaGa4Y9WjXibl1KlKRJuqzgRyuLqvP5vWu4q2osbqwqNWVZfWZ6tkvUFWG53xqefYbd0k4J0B0N41YvKYGJ2PsPa75HdkwMrI0EWjXisqoVckJyayQKs83OcaiaUCpCsmsWsn5c1WOkHQsZRGPWdlKR7cLxapRpPu5(JQuGxkFIUi(iNkjfaj8qGJ2PsXtVrFoyWbUU(5kutqLUJaaF2AN4P3OpxrWGVu(eDr8rovskas4HahTtLINEJ(8ORRFUc1euP7iaWNT2jE6n6ZJIQsZRGPqnbv6oca8zRDc4z9jLk3MkQiyW83OcaiaUCpCsmsWsn5c56ifuMXkgvjuvAEfmfoKTJuaKf0j87Cb8S(KsL7hmy(9ferHCWaTc(i9g9jETCfPm4ODQukWEE4GILzK87licQgDedatOAoisyf8qb)adA227JrrdmUdhVrFryv6jXiafKG5qSQtFkdoANkLcSNhoOyzgjWL7HtIrKlCu4rmam5VrfaqaC5E4KyKGLAYfY1rk0oJJQeQknVcMcpSqUUluEb8S(KY2BJOkf4LYNOlIpYPssbqcpe4ODQu80B0NdgCGRRFUc1euP7iaWNT2jE6n6Zbd(s5t0fXh5ujPaiHhcC0ovkE6n6ZJUU(5kutqLUJaaF2AN4P3OppkQknVcMc1euP7iaWNT2jGN1Nu2EaxrfbdM)gvaabWL7HtIrcwQjxixhPq79evjuvAEfmfoKTJuaKf0j87Cb8S(KsL7hmy(9ferHCWaTc(i9g9jETCfPm4ODQukWEE4GILzK87licQgDedaZaJ7WXB0xewLEsmcqbjyoeR603G7QlOcAWXhwvTVtLbuqhynRznga]] )

end
