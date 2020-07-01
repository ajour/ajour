-- DeathKnightFrost.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DEATHKNIGHT' then
    local spec = Hekili:NewSpecialization( 251 )

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

            value = 1
        },

        empower_rune = {
            aura        = 'empower_rune_weapon',

            last = function ()
                return state.buff.empower_rune_weapon.applied + floor( state.query_time - state.buff.empower_rune_weapon.applied )
            end,

            stop = function ( x )
                return x == 6
            end,

            interval = 5,
            value = 1
        },
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
                t.expiry[ 1 ] = ( t.expiry[ 4 ] > 0 and t.expiry[ 4 ] or state.query_time ) + t.cooldown
                table.sort( t.expiry )
            end

            state.gain( amount * 10, "runic_power" )

            if state.talent.gathering_storm.enabled and state.buff.remorseless_winter.up then
                state.buff.remorseless_winter.expires = state.buff.remorseless_winter.expires + ( 0.5 * amount )
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

    spec:RegisterResource( Enum.PowerType.RunicPower, {
        breath = {
            talent      = 'breath_of_sindragosa',
            aura        = 'breath_of_sindragosa',

            last = function ()
                return state.buff.breath_of_sindragosa.applied + floor( state.query_time - state.buff.breath_of_sindragosa.applied )
            end,

            stop = function ( x ) return x < 16 end,

            interval = 1,
            value = -16
        },

        empower_rp = {
            aura        = 'empower_rune_weapon',

            last = function ()
                return state.buff.empower_rune_weapon.applied + floor( state.query_time - state.buff.empower_rune_weapon.applied )
            end,

            interval = 5,
            value = 5
        },
    } )


    local virtual_rp_spent_since_pof = 0

    local spendHook = function( amt, resource, noHook )
        if amt > 0 and resource == "runic_power" and buff.breath_of_sindragosa.up and runic_power.current < 16 then
            removeBuff( "breath_of_sindragosa" )
            gain( 2, "runes" )
        end
    end

    spec:RegisterHook( "spend", spendHook )


    -- Talents
    spec:RegisterTalents( {
        inexorable_assault = 22016, -- 253593
        icy_talons = 22017, -- 194878
        cold_heart = 22018, -- 281208

        runic_attenuation = 22019, -- 207104
        murderous_efficiency = 22020, -- 207061
        horn_of_winter = 22021, -- 57330

        deaths_reach = 22515, -- 276079
        asphyxiate = 22517, -- 108194
        blinding_sleet = 22519, -- 207167

        avalanche = 22521, -- 207142
        frozen_pulse = 22523, -- 194909
        frostscythe = 22525, -- 207230

        permafrost = 22527, -- 207200
        wraith_walk = 22530, -- 212552
        death_pact = 23373, -- 48743

        gathering_storm = 22531, -- 194912
        glacial_advance = 22533, -- 194913
        frostwyrms_fury = 22535, -- 279302

        icecap = 22023, -- 207126
        obliteration = 22109, -- 281238
        breath_of_sindragosa = 22537, -- 152279
    } )


    spec:RegisterPvpTalents( { 
        adaptation = 3540, -- 214027
        relentless = 3539, -- 196029
        gladiators_medallion = 3538, -- 208683

        antimagic_zone = 3435, -- 51052
        cadaverous_pallor = 3515, -- 201995
        chill_streak = 706, -- 305392
        dark_simulacrum = 3512, -- 77606
        dead_of_winter = 3743, -- 287250
        deathchill = 701, -- 204080
        delirium = 702, -- 233396
        heartstop_aura = 3439, -- 199719
        lichborne = 3742, -- 136187
        necrotic_aura = 43, -- 199642
        transfusion = 3749, -- 237515
    } )


    -- Auras
    spec:RegisterAuras( {
        antimagic_shell = {
            id = 48707,
            duration = function () return 5 + ( ( level < 116 and equipped.acherus_drapes ) and 5 or 0 ) end,
            max_stack = 1,
        },
        asphyxiate = {
            id = 108194,
            duration = 4,
            max_stack = 1,
        },
        blinding_sleet = {
            id = 207167,
            duration = 5,
            max_stack = 1,
        },
        breath_of_sindragosa = {
            id = 152279,
            duration = 3600,
            max_stack = 1,
            dot = "buff"
        },
        chains_of_ice = {
            id = 45524,
            duration = 8,
            max_stack = 1,
        },
        cold_heart_item = {
            id = 235599,
            duration = 3600,
            max_stack = 20
        },
        cold_heart_talent = {
            id = 281209,
            duration = 3600,
            max_stack = 20,
        },
        cold_heart = {
            alias = { "cold_heart_item", "cold_heart_talent" },
            aliasMode = "first",
            aliasType = "buff",
            duration = 3600,
            max_stack = 20,
        },
        dark_command = {
            id = 56222,
            duration = 3,
            max_stack = 1,
        },
        dark_succor = {
            id = 101568,
            duration = 20,
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
        empower_rune_weapon = {
            id = 47568,
            duration = 20,
            max_stack = 1,
        },
        frost_breath = {
            id = 279303,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },
        frost_fever = {
            id = 55095,
            duration = 30,
            type = "Disease",
            max_stack = 1,
        },
        frozen_pulse = {
            -- pseudo aura for talent.
            name = "Frozen Pulse",
            meta = {
                up = function () return runes.current < 3 end,
                down = function () return runes.current >= 3 end,
                stack = function () return runes.current < 3 and 1 or 0 end,
                duration = 15,
                remains = function () return runes.time_to_3 end,
                applied = function () return runes.current < 3 and query_time or 0 end,
                expires = function () return runes.current < 3 and ( runes.time_to_3 + query_time ) or 0 end,
            }
        },
        gathering_storm = {
            id = 211805,
            duration = 3600,
            max_stack = 9,
        },
        icebound_fortitude = {
            id = 48792,
            duration = 8,
            max_stack = 1,
        },
        icy_talons = {
            id = 194879,
            duration = 6,
            max_stack = 3,
        },
        inexorable_assault = {
            id = 253595,
            duration = 3600,
            max_stack = 5,
        },
        killing_machine = {
            id = 51124,
            duration = 10,
            max_stack = 1,
        },
        obliteration = {
            id = 281238,
        },
        on_a_pale_horse = {
            id = 51986,
        },
        path_of_frost = {
            id = 3714,
            duration = 600,
            max_stack = 1,
        },
        pillar_of_frost = {
            id = 51271,
            duration = 15,
            max_stack = 1,
        },
        razorice = {
            id = 51714,
            duration = 26,
            max_stack = 5,
        },
        remorseless_winter = {
            id = 196770,
            duration = 8,
            max_stack = 1,
        },
        rime = {
            id = 59052,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        runic_empowerment = {
            id = 81229,
        },
        unholy_strength = {
            id = 53365,
            duration = 15,
            max_stack = 1,
        },


        -- PvP Talents
        -- Chill Streak
        chilled = {
            id = 204206,
            duration = 4,
            max_stack = 1
        },

        dead_of_winter = {
            id = 289959,
            duration = 4,
            max_stack = 5,
        },

        deathchill = {
            id = 204085,
            duration = 4,
            max_stack = 1
        },

        delirium = {
            id = 233396,
            duration = 15,
            max_stack = 1,
        },

        heartstop_aura = {
            id = 199719,
            duration = 3600,
            max_stack = 1,
        },

        lichborne = {
            id = 287081,
            duration = 10,
            max_stack = 1,
        },

        transfusion = {
            id = 288977,
            duration = 7,
            max_stack = 1,
        },


        -- Azerite Powers
        cold_hearted = {
            id = 288426,
            duration = 8,
            max_stack = 1
        },

        frostwhelps_indignation = {
            id = 287338,
            duration = 6,
            max_stack = 1,
        },
    } )


    spec:RegisterGear( "acherus_drapes", 132376 )
    spec:RegisterGear( "aggramars_stride", 132443 )
    spec:RegisterGear( "cold_heart", 151796 ) -- chilled_heart stacks NYI
        spec:RegisterAura( "cold_heart_item", {
            id = 235599, 
            duration = 3600,
            max_stack = 20
        } )
    spec:RegisterGear( "consorts_cold_core", 144293 )
    spec:RegisterGear( "kiljaedens_burning_wish", 144259 )
    spec:RegisterGear( "koltiras_newfound_will", 132366 )
    spec:RegisterGear( "perseverance_of_the_ebon_martyr", 132459 )
    spec:RegisterGear( "rethus_incessant_courage", 146667 )
    spec:RegisterGear( "seal_of_necrofantasia", 137223 )
    spec:RegisterGear( "shackles_of_bryndaor", 132365 ) -- NYI
    spec:RegisterGear( "soul_of_the_deathlord", 151640 )
    spec:RegisterGear( "toravons_whiteout_bindings", 132458 )


    spec:RegisterHook( "reset_precast", function ()
        local control_expires = action.control_undead.lastCast + 300

        if control_expires > now and pet.up then
            summonPet( "controlled_undead", control_expires - now )
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        antimagic_shell = {
            id = 48707,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 136120,

            handler = function ()
                applyBuff( "antimagic_shell" )
            end,
        },


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


        blinding_sleet = {
            id = 207167,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 135836,

            talent = "blinding_sleet",

            handler = function ()
                applyDebuff( "target", "blinding_sleet" )
                active_dot.blinding_sleet = max( active_dot.blinding_sleet, active_enemies )
            end,
        },


        breath_of_sindragosa = {
            id = 152279,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            spend = 16,
            readySpend = function () return settings.bos_rp end,
            spendType = "runic_power",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1029007,

            handler = function ()
                gain( 2, "runes" )
                applyBuff( "breath_of_sindragosa" )
                if talent.icy_talons.enabled then addStack( "icy_talons", 6, 1 ) end
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

            handler = function ()
                applyDebuff( "target", "chains_of_ice" )
                removeBuff( "cold_heart_item" )
                removeBuff( "cold_heart_talent" )

                --[[ if pvptalent.deathchill.enabled and debuff.chains_of_ice.up then
                    applyDebuff( "target", "deathchill" )
                end ]]
            end,
        },


        chill_streak = {
            id = 305392,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = function ()
                if essence.conflict_and_strife.major then return end
                return "chill_streak"
            end,

            handler = function ()
                applyDebuff( "target", "chilled" )
            end,
        },


        control_undead = {
            id = 111673,
            cast = 1.5,
            hasteCD = true,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 237273,

            usable = function () return target.is_undead and target.level <= level + 1, "requires undead target up to 1 level above player" end,
            handler = function ()
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


        --[[ death_gate = {
            id = 50977,
            cast = 4,
            hasteCD = true,
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

            toggle = "cooldowns",

            startsCombat = false,
            texture = 136146,

            talent = "death_pact",

            handler = function ()
                gain( health.max * 0.5, "health" )
                applyDebuff( "player", "death_pact" )
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
                gain( health.max * 0.10, "health" )
                if talent.icy_talons.enabled then addStack( "icy_talons", 6, 1 ) end
            end,
        },


        deaths_advance = {
            id = 48265,
            cast = 0,
            cooldown = 45,
            gcd = "off",

            startsCombat = false,
            texture = 237561,

            handler = function ()
                applyBuff( "deaths_advance" )
            end,
        },


        empower_rune_weapon = {
            id = 47568,
            cast = 0,
            charges = function () return ( level < 116 and equipped.seal_of_necrofantasia ) and 2 or nil end,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 / ( ( level < 116 and equipped.seal_of_necrofantasia ) and 1.10 or 1 ) end,
            recharge = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 / ( ( level < 116 and equipped.seal_of_necrofantasia ) and 1.10 or 1 ) end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 135372,

            nobuff = "empower_rune_weapon",

            handler = function ()
                stat.haste = state.haste + 0.15
                gain( 1, "runes" )
                gain( 5, "runic_power" )
                applyBuff( "empower_rune_weapon" )
            end,

            copy = "empowered_rune_weapon" -- typo often in SimC APL.
        },


        frost_strike = {
            id = 49143,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 25,
            spendType = "runic_power",

            startsCombat = true,
            texture = 237520,

            handler = function ()
                applyDebuff( "target", "razorice", 20, 2 )                
                if talent.icy_talons.enabled then addStack( "icy_talons", 6, 1 ) end
                if talent.obliteration.enabled and buff.pillar_of_frost.up then applyBuff( "killing_machine" ) end
                -- if pvptalent.delirium.enabled then applyDebuff( "target", "delirium" ) end
            end,
        },


        frostscythe = {
            id = 207230,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 1060569,

            talent = "frostscythe",

            range = 7,

            handler = function ()
                removeBuff( "killing_machine" )
            end,
        },


        frostwyrms_fury = {
            id = 279302,
            cast = 0,
            cooldown = function () return 180 - ( ( level < 116 and equipped.consorts_cold_core ) and 90 or 0 ) end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 341980,

            talent = "frostwyrms_fury",

            recheck = function () return buff.pillar_of_frost.remains - gcd.remains end,
            handler = function ()
                applyDebuff( "target", "frost_breath" )
            end,
        },


        glacial_advance = {
            id = 194913,
            cast = 0,
            cooldown = 6,
            hasteCD = true,
            gcd = "spell",

            spend = 30,
            spendType = "runic_power",

            startsCombat = true,
            texture = 537514,

            handler = function ()
                applyDebuff( "target", "razorice", nil, 1 )
                if talent.icy_talons.enabled then addStack( "icy_talons", 6, 1 ) end
            end,
        },


        horn_of_winter = {
            id = 57330,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 134228,

            talent = "horn_of_winter",

            recheck = function () return runic_power[ "time_to_" .. ( runic_power.max - 30 ) ] end,
            handler = function ()
                gain( 2, "runes" )
                gain( 25, "runic_power" )
            end,
        },


        howling_blast = {
            id = 49184,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.rime.up and 0 or 1 end,
            spendType = "runes",

            startsCombat = true,
            texture = 135833,

            recheck = function () return dot.frost_fever.remains end,
            handler = function ()
                applyDebuff( "target", "frost_fever" )
                active_dot.frost_fever = max( active_dot.frost_fever, active_enemies )

                if talent.obliteration.enabled and buff.pillar_of_frost.up then applyBuff( "killing_machine" ) end
                -- if pvptalent.delirium.enabled then applyDebuff( "target", "delirium" ) end

                removeBuff( "rime" )
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

            startsCombat = true,
            texture = 237527,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        obliterate = {
            id = 49020,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 2,
            spendType = "runes",

            startsCombat = true,
            texture = 135771,

            handler = function ()
                removeStack( "inexorable_assault" )
                applyDebuff( "target", "razorice", nil, debuff.razorice.stack + 1 )
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


        pillar_of_frost = {
            id = 51271,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 458718,

            handler = function ()
                applyBuff( "pillar_of_frost" )
                if azerite.frostwhelps_indignation.enabled then applyBuff( "frostwhelps_indignation" ) end
                virtual_rp_spent_since_pof = 0
            end,
        },


        --[[ raise_ally = {
            id = 61999,
            cast = 0,
            cooldown = 600,
            gcd = "spell",

            spend = 30,
            spendType = "runic_power",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 136143,

            handler = function ()
            end,
        }, ]]


        remorseless_winter = {
            id = 196770,
            cast = 0,
            cooldown = function () return pvptalent.dead_of_winter.enabled and 45 or 20 end,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = false,
            texture = 538770,

            range = 7,

            handler = function ()
                applyBuff( "remorseless_winter" )
                -- if pvptalent.deathchill.enabled then applyDebuff( "target", "deathchill" ) end
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
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,

        nameplates = true,
        nameplateRange = 8,

        damage = true,
        damageDots = false,
        damageExpiration = 8,

        potion = "potion_of_unbridled_fury",

        package = "Frost DK",
    } )


    spec:RegisterSetting( "bos_rp", 50, {
        name = "Runic Power for |T1029007:0|t Breath of Sindragosa",
        desc = "The addon will not recommend |T1029007:0|t Breath of Sindragosa only if you have this much Runic Power (or more).",
        icon = 1029007,
        iconCoords = { 0.1, 0.9, 0.1, 0.9 },
        type = "range",
        min = 16,
        max = 100,
        step = 1,
        width = 1.5
    } )

    
    spec:RegisterPack( "Frost DK", 20200531, [[dKeYqcqirvEeqk2ePYOebNseAvIkPxjIAwIe3ciLAxi(LivdtuvhtvQLjk5zIiMMisUMOuBdiv(MOsLXbKQoNOsX6asjnpG4EaAFIIoOisLwOOWdfrQAIIkLQlkIu0gfvQAKIkLItkIuYkrj9sGuc3uePu7uK0pfvkLgQisflvePGNIIPks5RaPeTxk(lrdMshMQfRQEmstwjxgAZK8zagnqDAjRwuPKxJsmBuDBvXUv53kgoPCCrLy5s9Cctx46k12bs(oPQXlIuOZRkz9IkMpk1(bT5TjndZYd0KAw5Nv(5NDsEtENv(zNvUZWeV0qdJMtzXbGgMZFqdtUVhraT52bTWWO5V4JVmPzyeZUPOHbCeAcqRPNoGkaV)e68KUOE2CpQ5OTRI0f1dnDdZFx8iP1z(gMLhOj1SYpR8Zp7K8M8oR8ZoldJVdWtByyQNKEdd4ATWZ8nmluqnmGgOn33JiG2C7OhGHwqlUca4aYkObAbhHMa0A6PdOcW7pHopPlQNn3JAoA7QiDr9qthYkObAtA7VG2K8ofOnR8ZkFiRqwbnqBspy)aGcqRqwbnqlOn0M06O89cH2K21TG2CFJyoibYkObAbTH2KURf0QCo)7uwGw10q7wuhaOnPzsdGwMc0M0zY9qBPGwnU)cBOTUkkpqb0MXWaTFunncTAZWRda0YhaffAlb0sNhnog4Iazf0aTG2qBspy)aGqB4namir9GYyKRcH2yG2OEqzmYvHqBmq7wGqlE0zFb2qlhpabyOT9am2qBa2pOvBc8IY5qB0Uam0UqpaliqwbnqlOn0M0p8f0MBd6DaT(TG22PLZH2qp6SiiggEjcHjnddD4ljy07WKMj13M0mm45FoUmzyyODfyxUH5VvkcD4ljy07GicNYc0Mj0Mn0QdAJ6bLXixfcTGaTaOldJtJAoddfSxNqokzrrtysnltAgg88phxMmmm0UcSl3WKa0(3kfrGyaUoaY2bGKgF86eqliqla6cAteA1bT)TsreigGRdGSDaizRzyCAuZzyOG96eYrjlkActQjXKMHbp)ZXLjdddTRa7YnmjaT)Tsr0ko3B5OKQEebPXhVob0ccqOfaDbT5k0Ma0(gAtgAPZWxJ(JO6re6F1pcPA3Vin6RxqBIqlB2q7FRueTIZ9wokPQhrqA8XRtaTGaT9(qsupOmgzsG2eHwDq7FRueTIZ9wokPQhrq2AqRoOnbO1Zb7kqsrFjPv4lKtA)ybAbbi0(gAzZgA)BLI8B0dWYrjf1TAhWiCYwdAteA1bT5bTHZXliffPUgbp)ZXLHXPrnNHHc2RtihLSOOjmPMuM0mm45FoUmzyyODfyxUH5VvkIwX5ElhLu1Jiin(41jGwqGwqp0QdA)BLISpWd)LuenEacWKgF86eqliqla6cAZvOnbO9n0Mm0sNHVg9hr1Ji0)QFes1UFrA0xVG2eHwDq7FRuK9bE4VKIOXdqaM04JxNaA1bT)Tsr0ko3B5OKQEebzRbT6G2eGwphSRajf9LKwHVqoP9JfOfeGq7BOLnBO9VvkYVrpalhLuu3QDaJWjBnOnrOvh0Mh0gohVGuuK6Ae88phxggNg1CggkyVoHCuYIIMWKA2M0mm45FoUmzyyODfyxUHjbO9VvksrFjPv4lKtA8XRtaTGaTjf0YMn0(3kfPOVK0k8fYjn(41jGwqG2EFijQhugJmjqBIqRoO9VvksrFjPv4lKt2AqRoO1Zb7kqsrFjPv4lKtA)ybAZei0Mf0QdAZdA)BLI8B0dWYrjf1TAhWiCYwdA1bT5bTHZXliffPUgbp)ZXLHXPrnNHHc2RtihLSOOjmPc6mPzyWZ)CCzYWWq7kWUCdZFRuKI(ssRWxiNS1GwDq7FRuK9bE4VKIOXdqaMS1GwDqRNd2vGKI(ssRWxiN0(Xc0MjqOnlOvh0Mh0(3kf53OhGLJskQB1oGr4KTg0QdAZdAdNJxqkksDncE(NJldJtJAoddfSxNqokzrrtysn3zsZWGN)54YKHHH2vGD5gM)wPiAfN7TCusvpIG04JxNaAbbAtkOvh0(3kfrR4CVLJsQ6reKTg0QdAdNJxqkksDncE(NJlOvh0(3kfHo8Lem6DqeHtzbAZei0(g0dT6GwphSRajf9LKwHVqoP9JfOfeGq7BdJtJAoddfSxNqokzrrtysf0BsZWGN)54YKHHH2vGD5gM)wPiAfN7TCusvpIGS1GwDqB4C8csrrQRrWZ)CCbT6GwphSRajf9LKwHVqoP9JfOntGqBwqRoOnbO9VvkcD4ljy07GicNYc0MjqO9DUbA1bT)Tsrk6ljTcFHCsJpEDcOfeOfaDbT6G2)wPif9LKwHVqozRbTSzdT)Tsr2h4H)skIgpabyYwdA1bT)TsrOdFjbJEher4uwG2mbcTVb9qBIggNg1CggkyVoHCuYIIMWegM5ZRaBpQ5mPzs9TjnddE(NJltgggAxb2LBycNJxqa4bySRdGuet)qWZ)CCzyCAuZzyA8zAbYrHqQVUaBtysnltAgg88phxMmmmonQ5mmZNxb2EGggAxb2LBysaAx4FRuK2Zz6IIer4uwGwqG2SHw2SH2f(3kfP9CMUOiPXhVob0cc0(oFOnrOvh0Mh0gohVGO6rec6RamsWZ)CCbT6G28G2)wPiD9GKTg0QdAfAiNldVbGHGaE0ZRdG8ZDraTzceAtIHH(IYrz4nameMuFBctQjXKMHbp)ZXLjdddTRa7Ynm5bTHZXliQEeHG(kaJe88phxqRoOnpO9VvksxpizRbT6GwHgY5YWBayiiGh986ai)CxeqBMaH2KyyCAuZzyMpVcS9anHj1KYKMHbp)ZXLjdddTRa7YnmjaT)TsryP486aiFCk46qsJonGw2SH2eG2)wPiSuCEDaKpofCDizRbT6G2eGwTgbLeaDrEtu9icPi6IfeAzZgA1Aeusa0f5nb8ONxha5N7IaAzZgA1Aeusa0f5nba3PLZL(cu(rrOnrOnrOnrOvh0k0qoxgEdadbr1Jie0xbyeAZei0MLHXPrnNHr1Jie0xby0eMuZ2KMHbp)ZXLjddJtJAodZ85vGThOHH2vGD5gMeG2f(3kfP9CMUOireoLfOfeOnBOLnBODH)TsrApNPlksA8XRtaTGaTVZhAteA1bT)TsryP486aiFCk46qsJonGw2SH2eG2)wPiSuCEDaKpofCDizRbT6G2eGwTgbLeaDrEtu9icPi6IfeAzZgA1Aeusa0f5nb8ONxha5N7IaAzZgA1Aeusa0f5nba3PLZL(cu(rrOnrOnrdd9fLJYWBayimP(2eMubDM0mm45FoUmzyyODfyxUH5VvkclfNxha5JtbxhsA0Pb0YMn0Ma0(3kfHLIZRdG8XPGRdjBnOvh0Ma0Q1iOKaOlYBIQhrifrxSGqlB2qRwJGscGUiVjGh986ai)CxeqlB2qRwJGscGUiVja4oTCU0xGYpkcTjcTjAyCAuZzyMpVcS9anHj1CNjnddE(NJltgggAxb2LBysaAZdA)BLI01ds2AqlB2qBVVIk1g9ytwOQOvaTGaTVZhAzZgA79HKOEqzmYSG2mHwa0f0Mi0QdAfAiNldVbGHGaG70Y5sFbk)Oi0MjqOnldJtJAoddaUtlNl9fO8JIMWKkO3KMHbp)ZXLjdddTRa7Ynm)Tsr66bjBnOvh0k0qoxgEdadbb8ONxha5N7IaAZei0MLHXPrnNHb8ONxha5N7IWeMuZnM0mm45FoUmzyyCAuZzyu9icPi6If0Wq7kWUCdtcq7c)BLI0EotxuKicNYc0cc0Mn0YMn0UW)wPiTNZ0ffjn(41jGwqG235dTjcT6G28G2)wPiD9GKTg0YMn027ROsTrp2KfQkAfqliq778Hw2SH2EFijQhugJmlOntOfaDbT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMuFNVjnddE(NJltgggAxb2LByYdA)BLI01ds2AqlB2qBVVIk1g9ytwOQOvaTGaTVZhAzZgA79HKOEqzmYSG2mHwa0LHXPrnNHr1JiKIOlwqtys99BtAgg88phxMmmm0UcSl3W83kfPRhKS1mmonQ5mmGh986ai)CxeMWK67SmPzyWZ)CCzYWW40OMZWmFEfy7bAyODfyxUHjbODH)TsrApNPlkseHtzbAbbAZgAzZgAx4FRuK2Zz6IIKgF86eqliq778H2eHwDqBEqB4C8cIQhriOVcWibp)ZXLHH(IYrz4nameMuFBctQVtIjndJtJAodZ85vGThOHbp)ZXLjdtycdZFeYOOSuhatAMuFBsZWGN)54YKHHH2vGD5gg6m81O)i4J2OhBzVpuQhDT5in(41jmmonQ5mmAfN7TCusvpIWeMuZYKMHXPrnNHbF0g9yl79Hs9ORnNHbp)ZXLjdtysnjM0mm45FoUmzyyCAuZzyMpVcS9anm0UcSl3WKa0UW)wPiTNZ0ffjIWPSaTGaTzdTSzdTl8Vvks75mDrrsJpEDcOfeO9D(qBIqRoOT3xrLAJESHwqacTjjlOvh0Mh0gohVGO6rec6RamsWZ)CCzyOVOCugEdadHj13MWKAszsZWGN)54YKHHH2vGD5gMEFfvQn6XgAbbi0MKSmmonQ5mmZNxb2EGMWKA2M0mm45FoUmzyyODfyxUHjCoEbbGhGXUoasrm9dbp)ZXLHXPrnNHPXNPfihfcP(6cSnHjvqNjnddE(NJltgggAxb2LBy(BLI01ds2AggNg1CggWJEEDaKFUlctysn3zsZWGN)54YKHHXPrnNHz(8kW2d0Wq7kWUCdtcq7c)BLI0EotxuKicNYc0cc0Mn0YMn0UW)wPiTNZ0ffjn(41jGwqG235dTjcT6G2EFijQhugJmBOfeOfaDbTSzdT9(kQuB0Jn0ccqOnPYgA1bT5bTHZXliQEeHG(kaJe88phxgg6lkhLH3aWqys9TjmPc6nPzyWZ)CCzYWWq7kWUCdtVpKe1dkJrMn0cc0cGUGw2SH2EFfvQn6XgAbbi0MuzByCAuZzyMpVcS9anHj1CJjnddE(NJltgggAxb2LBy(BLIWsX51bq(4uW1HKTg0QdAfAiNldVbGHGO6rec6RamcTzceAZYW40OMZWO6rec6RamActQVZ3KMHbp)ZXLjdddTRa7Ynm9(kQuB0JnzHQIwb0MjqOnjzbT6G2EFijQhugJmjqBMqla6YW40OMZWaE6tokP(6cSnHj13VnPzyCAuZzyA8zAbYrHqQVUaBddE(NJltgMWK67SmPzyWZ)CCzYWWq7kWUCdJqd5Cz4nameevpIqqFfGrOntGqBwggNg1CggvpIqqFfGrtys9DsmPzyWZ)CCzYWW40OMZWmFEfy7bAyODfyxUHjbODH)TsrApNPlkseHtzbAbbAZgAzZgAx4FRuK2Zz6IIKgF86eqliq778H2eHwDqBVVIk1g9ytwOQOvaTzcTzLn0YMn027dH2mH2KaT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMuFNuM0mm45FoUmzyyODfyxUHP3xrLAJESjluv0kG2mH2SYgAzZgA79HqBMqBsmmonQ5mmZNxb2EGMWK67SnPzyWZ)CCzYWWq7kWUCdtVVIk1g9ytwOQOvaTzcTzNVHXPrnNHXBQFOmMUXlmHjmm0z4Rr)jmPzs9TjnddE(NJltgggNg1CggphbyVDHunxihLuB0JTHH2vGD5gMeGw6m81O)i4J2OhBzVpuQhDT5in6RxqRoOnpOfuEx(NJKjaJTCo5wGsmx2LMgUG2eHw2SH2eGw6m81O)iAfN7TCusvpIG04JxNaAbbi0(oFOvh0ckVl)ZrYeGXwoNClqjMl7stdxqBIgMZFqdJNJaS3UqQMlKJsQn6X2eMuZYKMHbp)ZXLjddJtJAoddF3SGTqwNOw1SfsaLkmm0UcSl3WeohVG8B0dWYrjf1TAhWiCcE(NJlOvh0Ma0Ma0sNHVg9hrR4CVLJsQ6reKgF86eqliaH235dT6Gwq5D5FosMam2Y5KBbkXCzxAA4cAteAzZgAtaA)BLIOvCU3Yrjv9icYwdA1bT5bTGY7Y)CKmbySLZj3cuI5YU00Wf0Mi0Mi0YMn0Ma0(3kfrR4CVLJsQ6reKTg0QdAZdAdNJxq(n6by5OKI6wTdyeobp)ZXf0MOH58h0WW3nlylK1jQvnBHeqPctysnjM0mm45FoUmzyyCAuZzyOVO8j65kQ8ZDryyODfyxUHjpO9VvkIwX5ElhLu1JiiBndZ5pOHH(IYNONROYp3fHjmPMuM0mm45FoUmzyyODfyxUHjbOLodFn6pIwX5ElhLu1Jiin6RxqlB2qlDg(A0FeTIZ9wokPQhrqA8XRtaTzcTzLp0Mi0QdAtaAZdAdNJxq(n6by5OKI6wTdyeobp)ZXf0YMn0sNHVg9hbF0g9yl79Hs9ORnhPXhVob0Mj0MBYgAt0W40OMZWSfOSc8ryctQzBsZWGN)54YKHHXPrnNHXfGbLFOq2EotlPt7CddTRa7Ynml8Vvks75mTKoTZLl8VvkYA0FgMZFqdJladk)qHS9CMwsN25MWKkOZKMHbp)ZXLjddJtJAodJladk)qHS9CMwsN25ggAxb2LByOZWxJ(JGpAJESL9(qPE01MJ04JxNaAZeAZn5dT6G2f(3kfP9CMwsN25Yf(3kfzRbT6Gwq5D5FosMam2Y5KBbkXCzxAA4cAzZgA)BLI8B0dWYrjf1TAhWiCYwdA1bTl8Vvks75mTKoTZLl8VvkYwdA1bT5bTGY7Y)CKmbySLZj3cuI5YU00Wf0YMn0(3kfbF0g9yl79Hs9ORnhzRbT6G2f(3kfP9CMwsN25Yf(3kfzRbT6G28G2W54fKFJEawokPOUv7agHtWZ)CCbTSzdTr9GYyKRcHwqG2SEByo)bnmUamO8dfY2ZzAjDANBctQ5otAgg88phxMmmmonQ5mm5wOqcE0ZX2Wq7kWUCdtcqlMl7stdxe(UzbBHSorTQzlKakvaT6G2)wPiAfN7TCusvpIG04JxNaAteAzZgAtaAZdAXCzxAA4IW3nlylK1jQvnBHeqPcOvh0(3kfrR4CVLJsQ6reKgF86eqliq77SGwDq7FRueTIZ9wokPQhrq2AqBIgMZFqdtUfkKGh9CSnHjvqVjnddE(NJltgggNg1CggwUjKJs6hTWlKQD)YWq7kWUCddDg(A0Fe8rB0JTS3hk1JU2CKgF86eqBMqBsLVH58h0WWYnHCus)OfEHuT7xMWKAUXKMHbp)ZXLjddJtJAoddGEoacPwxpox2oa0Wq7kWUCdtVpeAbbi0MeOvh0Mh0(3kfrR4CVLJsQ6reKTg0QdAtaAZdA)BLI8B0dWYrjf1TAhWiCYwdAzZgAZdAdNJxq(n6by5OKI6wTdyeobp)ZXf0MOH58h0WaONdGqQ11JZLTdanHj135BsZWGN)54YKHH58h0W0EoR9XIq(laYgxY)oI5mmonQ5mmTNZAFSiK)cGSXL8VJyotys99BtAgg88phxMmmmonQ5mmpyJSeGDHu5haddTRa7Ynm5bT)Tsr(n6by5OKI6wTdyeozRbT6G28G2)wPiAfN7TCusvpIGS1mmN)GgMhSrwcWUqQ8dGjmP(oltAgg88phxMmmm0UcSl3W83kfrR4CVLJsQ6reKTg0QdA)BLIGpAJESL9(qPE01MJS1mmonQ5mmAtuZzctQVtIjnddE(NJltgggAxb2LBy(BLIOvCU3Yrjv9icYwdA1bT)TsrWhTrp2YEFOup6AZr2AggNg1CgMpFMLuT7xMWK67KYKMHbp)ZXLjdddTRa7Ynm)Tsr0ko3B5OKQEebzRzyCAuZzy(ylWML6ayctQVZ2KMHbp)ZXLjdddTRa7YnmjaT5bT)Tsr0ko3B5OKQEebzRbT6GwNgfOqjE4tHcOntGqBwqBIqlB2qBEq7FRueTIZ9wokPQhrq2AqRoOnbOT3hswOQOvaTzceAZgA1bT9(kQuB0JnzHQIwb0MjqOf0Lp0MOHXPrnNHXBQFOuBZfOjmP(g0zsZWGN)54YKHHH2vGD5gM)wPiAfN7TCusvpIGS1mmonQ5mm8ca4qiZT2lap4fMWK67CNjnddE(NJltgggAxb2LBy(BLIOvCU3Yrjv9icYwdA1bT)TsrWhTrp2YEFOup6AZr2AggNg1Cgg)OOiANlPoNBctQVb9M0mm45FoUmzyyODfyxUH5VvkIwX5ElhLu1Jiin(41jGwqacTGEOvh0(3kfbF0g9yl79Hs9ORnhzRzyCAuZzyuvJF(mltys9DUXKMHbp)ZXLjdddTRa7Ynm)Tsr0ko3B5OKQEebzRbT6G2eG2)wPiAfN7TCusvpIG04JxNaAbbAZgA1bTHZXli0HVKGrVdcE(NJlOLnBOnpOnCoEbHo8Lem6DqWZ)CCbT6G2)wPiAfN7TCusvpIG04JxNaAbbAtc0Mi0QdADAuGcL4HpfkGwGq7BOLnBO9VvkIaXaCDaKTdajBnOvh060OafkXdFkuaTaH23ggNg1CgMVdqokz0fLfHjmPMv(M0mm45FoUmzyyODfyxUHjbOLodFn6pc(On6Xw27dL6rxBosJpEDcOLnBOnCoEbPOi11i45FoUG2eHwDqBEq7FRueTIZ9wokPQhrq2AggNg1CggTIZ9wokPQhryctQz92KMHbp)ZXLjdddTRa7Ynm0z4Rr)rWhTrp2YEFOup6AZrA8XRtaT6Gw6m81O)iAfN7TCusvpIG04JxNWW40OMZW8B0dWYrjf1TAhWiCdZwGYrPKaOltQVnHj1SYYKMHbp)ZXLjdddTRa7Ynm0z4Rr)r0ko3B5OKQEebPrF9cA1bTHZXliZNxb2EuZrWZ)CCbT6G2EFijQhugJmBOntOfaDbT6G2EFfvQn6XMSqvrRaAZei0(oFOLnBOnQhugJCvi0cc0Mv(ggNg1Cgg8rB0JTS3hk1JU2CMWKAwjXKMHbp)ZXLjdddTRa7YnmjaT0z4Rr)r0ko3B5OKQEebPrF9cAzZgAJ6bLXixfcTGaTzLp0Mi0QdAdNJxq(n6by5OKI6wTdyeobp)ZXf0QdA79vuP2OhBOntOf0LVHXPrnNHbF0g9yl79Hs9ORnNjmPMvszsZWGN)54YKHHH2vGD5gMW54fKIIuxJGN)54cA1bT9(qOfeOnjggNg1Cgg8rB0JTS3hk1JU2CMWKAwzBsZWGN)54YKHHH2vGD5gMW54fe6WxsWO3bbp)ZXf0QdAtaAtaA)BLIqh(scg9oiIWPSaTzceAFNp0QdAx4FRuK2Zz6IIer4uwGwGqB2qBIqlB2qBupOmg5QqOfeGqla6cAt0W40OMZWqDox60OMtYlryy4LiKN)Ggg6WxsWO3HjmPMfOZKMHbp)ZXLjdddTRa7YnmjaT)Tsr0ko3B5OKQEebzRbT6GwphSRajf9LKwHVqoP9JfOfeGq7BOvh0Ma0(3kfrR4CVLJsQ6reKgF86eqliaHwa0f0YMn0(3kfzFGh(lPiA8aeGjn(41jGwqacTaOlOvh0(3kfzFGh(lPiA8aeGjBnOnrOnrdJtJAodJQhrO)v)iKQD)YeMuZk3zsZWGN)54YKHHH2vGD5gMeG2)wPif9LKwHVqozRbT6G28G2W54fKIIuxJGN)54cA1bTjaT)Tsr2h4H)skIgpabyYwdAzZgA)BLIu0xsAf(c5KgF86eqliaHwa0f0Mi0Mi0YMn0(3kfPOVK0k8fYjBnOvh0(3kfPOVK0k8fYjn(41jGwqacTaOlOvh0gohVGuuK6Ae88phxqRoO9VvkIwX5ElhLu1JiiBndJtJAodJQhrO)v)iKQD)YeMuZc0BsZWGN)54YKHHH2vGD5gMOEqzmYvHqliqla6cAzZgAtaAJ6bLXixfcTGaT0z4Rr)r0ko3B5OKQEebPXhVob0QdA)BLISpWd)LuenEacWKTg0MOHXPrnNHr1Ji0)QFes1UFzctyy(JqQndVoaM0mP(2KMHbp)ZXLjdddTRa7Ynm)Tsr66bjBndJtJAodd4rpVoaYp3fHjmPMLjnddE(NJltgggNg1CgM5ZRaBpqddTRa7YnmjaTl8Vvks75mDrrIiCklqliqB2qlB2q7c)BLI0EotxuK04JxNaAbbAFNp0Mi0QdA79vuP2OhBYcvfTcOntGqBwzdT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMutIjnddE(NJltgggAxb2LBy69vuP2OhBYcvfTcOntGqBwzByCAuZzyMpVcS9anHj1KYKMHbp)ZXLjdddTRa7Ynm9(kQuB0JnzHQIwb0cc0Mv(qRoOvOHCUm8gagccaUtlNl9fO8JIqBMaH2SGwDqlDg(A0FeTIZ9wokPQhrqA8XRtaTzcTzByCAuZzyaWDA5CPVaLFu0eMuZ2KMHbp)ZXLjddJtJAodJQhrifrxSGggAxb2LBysaAx4FRuK2Zz6IIer4uwGwqG2SHw2SH2f(3kfP9CMUOiPXhVob0cc0(oFOnrOvh027ROsTrp2KfQkAfqliqBw5dT6G28G2W54fevpIqqFfGrcE(NJlOvh0sNHVg9hrR4CVLJsQ6reKgF86eqBMqB2gg6lkhLH3aWqys9TjmPc6mPzyWZ)CCzYWWq7kWUCdtVVIk1g9ytwOQOvaTGaTzLp0QdAPZWxJ(JOvCU3Yrjv9icsJpEDcOntOnBdJtJAodJQhrifrxSGMWKAUZKMHbp)ZXLjdddTRa7Ynm)TsryP486aiFCk46qYwdA1bT9(kQuB0JnzHQIwb0Mj0Ma0(oBOnzOnCoEbP3xrLEe4T9OMJGN)54cAZvOnjqBIqRoOvOHCUm8gagcIQhriOVcWi0MjqOnldJtJAodJQhriOVcWOjmPc6nPzyWZ)CCzYWWq7kWUCdtVVIk1g9ytwOQOvaTzceAtaAts2qBYqB4C8csVVIk9iWB7rnhbp)ZXf0MRqBsG2eHwDqRqd5Cz4nameevpIqqFfGrOntGqBwggNg1CggvpIqqFfGrtysn3ysZWGN)54YKHHXPrnNHz(8kW2d0Wq7kWUCdtcq7c)BLI0EotxuKicNYc0cc0Mn0YMn0UW)wPiTNZ0ffjn(41jGwqG235dTjcT6G2EFfvQn6XMSqvrRaAZei0Ma0MKSH2KH2W54fKEFfv6rG32JAocE(NJlOnxH2KaTjcT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMuFNVjnddE(NJltgggAxb2LBy69vuP2OhBYcvfTcOntGqBcqBsYgAtgAdNJxq69vuPhbEBpQ5i45FoUG2CfAtc0MOHXPrnNHz(8kW2d0eMuF)2KMHbp)ZXLjdddTRa7Ynm0z4Rr)r0ko3B5OKQEebPXhVob0Mj027djr9GYyKjf0QdA79vuP2OhBYcvfTcOfeOnPYhA1bTcnKZLH3aWqqaWDA5CPVaLFueAZei0MLHXPrnNHba3PLZL(cu(rrtys9DwM0mm45FoUmzyyCAuZzyu9icPi6If0Wq7kWUCdtcq7c)BLI0EotxuKicNYc0cc0Mn0YMn0UW)wPiTNZ0ffjn(41jGwqG235dTjcT6Gw6m81O)iAfN7TCusvpIG04JxNaAZeA79HKOEqzmYKcA1bT9(kQuB0JnzHQIwb0cc0Mu5dT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMuFNetAgg88phxMmmm0UcSl3WqNHVg9hrR4CVLJsQ6reKgF86eqBMqBVpKe1dkJrMuqRoOT3xrLAJESjluv0kGwqG2KkFdJtJAodJQhrifrxSGMWeggTgPZZ3dtAMuFBsZW40OMZWOnrnNHbp)ZXLjdtysnltAgg88phxMmmmN)GggphbyVDHunxihLuB0JTHXPrnNHXZra2BxivZfYrj1g9yBctQjXKMHbp)ZXLjddZOzyeyyyCAuZzyaL3L)5OHbuoFJgMeGwmx2LMgUi3etxZwibW9v5X0c53xaqOLnBOfZLDPPHlcD6ERf4scG7RYJPfYVVaGqlB2qlMl7stdxe609wlWLea3xLhtlKp4Y58AoOLnBOfZLDPPHlcOkNlhL0V6XdCj)8zwqlB2qlMl7stdxev1Iq(4bkKcTxa4UqaTSzdTyUSlnnCrYTqHe8ONJn0YMn0I5YU00Wf5My6A2cjaUVkpMwiFWLZ51CqlB2qlMl7stdxexagu(Hcz75mTKoTZH2enmGYB55pOHzcWylNtUfOeZLDPPHltycdJpOjntQVnPzyWZ)CCzYWWq7kWUCdt4C8ccapaJDDaKIy6hcE(NJlOLnBOnbO1Zb7kqIQNCWtg4Jgkcs7hlqRoOvOHCUm8gagcsJptlqokes91fydTzceAtc0QdAZdA)BLI01ds2AqBIggNg1CgMgFMwGCuiK6RlW2eMuZYKMHbp)ZXLjdddTRa7YnmHZXliQEeHG(kaJe88phxggNg1CggaCNwox6lq5hfnHj1KysZWGN)54YKHHXPrnNHr1JiKIOlwqddTRa7YnmjaTl8Vvks75mDrrIiCklqliqB2qlB2q7c)BLI0EotxuK04JxNaAbbAFNp0Mi0QdAPZWxJ(J04Z0cKJcHuFDb2KgF86eqliaH2SG2CfAbqxqRoOnCoEbbGhGXUoasrm9dbp)ZXf0QdAZdAdNJxqu9icb9vagj45FoUmm0xuokdVbGHWK6BtysnPmPzyWZ)CCzYWWq7kWUCddDg(A0FKgFMwGCuiK6RlWM04JxNaAbbi0Mf0MRqla6cA1bTHZXlia8am21bqkIPFi45FoUmmonQ5mmQEeHueDXcActQzBsZWGN)54YKHHH2vGD5gM)wPiD9GKTMHXPrnNHb8ONxha5N7IWeMubDM0mm45FoUmzyyODfyxUH5VvkclfNxha5Jtbxhs2AggNg1CggvpIqqFfGrtysn3zsZWGN)54YKHHH2vGD5gMEFfvQn6XMSqvrRaAbbAtaAFNn0Mm0gohVG07ROspc82EuZrWZ)CCbT5k0MeOnrdJtJAoddaUtlNl9fO8JIMWKkO3KMHbp)ZXLjddJtJAodJQhrifrxSGggAxb2LBysaAx4FRuK2Zz6IIer4uwGwqG2SHw2SH2f(3kfP9CMUOiPXhVob0cc0(oFOnrOvh027ROsTrp2KfQkAfqliqBcq77SH2KH2W54fKEFfv6rG32JAocE(NJlOnxH2KaTjcT6G28G2W54fevpIqqFfGrcE(NJldd9fLJYWBayimP(2eMuZnM0mm45FoUmzyyODfyxUHP3xrLAJESjluv0kGwqG2eG23zdTjdTHZXli9(kQ0JaVTh1Ce88phxqBUcTjbAteA1bT5bTHZXliQEeHG(kaJe88phxggNg1CggvpIqkIUybnHj135BsZW40OMZW04Z0cKJcHuFDb2gg88phxMmmHj13VnPzyCAuZzyu9icb9vagnm45FoUmzyctQVZYKMHbp)ZXLjddJtJAodZ85vGThOHH2vGD5gMeG2f(3kfP9CMUOireoLfOfeOnBOLnBODH)TsrApNPlksA8XRtaTGaTVZhAteA1bT9(kQuB0JnzHQIwb0Mj0Ma0Mv2qBYqB4C8csVVIk9iWB7rnhbp)ZXf0MRqBsG2eHwDqBEqB4C8cIQhriOVcWibp)ZXLHH(IYrz4nameMuFBctQVtIjnddE(NJltgggAxb2LBy69vuP2OhBYcvfTcOntOnbOnRSH2KH2W54fKEFfv6rG32JAocE(NJlOnxH2KaTjAyCAuZzyMpVcS9anHj13jLjndJtJAoddaUtlNl9fO8JIgg88phxMmmHj13zBsZWGN)54YKHHXPrnNHr1JiKIOlwqddTRa7YnmjaTl8Vvks75mDrrIiCklqliqB2qlB2q7c)BLI0EotxuK04JxNaAbbAFNp0Mi0QdAZdAdNJxqu9icb9vagj45FoUmm0xuokdVbGHWK6Btys9nOZKMHXPrnNHr1JiKIOlwqddE(NJltgMWK67CNjndJtJAodd4Pp5OK6RlW2WGN)54YKHjmP(g0BsZW40OMZW4n1pugt34fgg88phxMmmHjmmlu5BEysZK6BtAggNg1CgMN6wsvJyoOHbp)ZXLjdtysnltAgg88phxMmmm0UcSl3WKh0UMGO6resfckSjrrzPoaqRoOnbOnpOnCoEb53OhGLJskQB1oGr4e88phxqlB2qlDg(A0FKFJEawokPOUv7agHtA8XRtaTzcTVZgAt0W40OMZWaE0ZRdG8ZDryctQjXKMHbp)ZXLjdddTRa7Ynm)Tsrk6lz485eKgF86eqliaHwa0f0QdA)BLIu0xYW5ZjiBnOvh0k0qoxgEdadbba3PLZL(cu(rrOntGqBwqRoOnbOnpOnCoEb53OhGLJskQB1oGr4e88phxqlB2qlDg(A0FKFJEawokPOUv7agHtA8XRtaTzcTVZgAt0W40OMZWaG70Y5sFbk)OOjmPMuM0mm45FoUmzyyODfyxUH5VvksrFjdNpNG04JxNaAbbi0cGUGwDq7FRuKI(sgoFobzRbT6G2eG28G2W54fKFJEawokPOUv7agHtWZ)CCbTSzdT0z4Rr)r(n6by5OKI6wTdyeoPXhVob0Mj0(oBOnrdJtJAodJQhrifrxSGMWKA2M0mm45FoUmzyyCAuZzyOoNlDAuZj5Limm8seYZFqddke4rrHjmPc6mPzyWZ)CCzYWW40OMZWqDox60OMtYlryy4LiKN)Ggg6m81O)eMWKAUZKMHbp)ZXLjdddTRa7Ynm)Tsr(n6by5OKI6wTdyeozRzyCAuZzy69jDAuZj5Limm8seYZFqdZFeYOOSuhatysf0BsZWGN)54YKHHH2vGD5gMW54fKFJEawokPOUv7agHtWZ)CCbT6G2eG2eGw6m81O)i)g9aSCusrDR2bmcN04JxNaAbcT5dT6Gw6m81O)iAfN7TCusvpIG04JxNaAbbAFNp0Mi0YMn0Ma0sNHVg9h53OhGLJskQB1oGr4KgF86eqliqBw5dT6G2OEqzmYvHqliqBsYgAteAt0W40OMZW07t60OMtYlryy4LiKN)GgM)iKAZWRdGjmPMBmPzyWZ)CCzYWWq7kWUCdZFRueTIZ9wokPQhrq2AqRoOnCoEbz(8kW2JAocE(NJldJtJAodtVpPtJAojVeHHHxIqE(dAyMpVcS9OMZeMuFNVjnddE(NJltgggAxb2LByCAuGcL4HpfkG2mbcTzzyCAuZzy69jDAuZj5Limm8seYZFqdJpOjmP((TjnddE(NJltgggNg1CggQZ5sNg1CsEjcddVeH88h0Wic)wEVmHjmmIWVL3ltAMuFBsZW40OMZW04Z0cKJcHuFDb2gg88phxMmmHj1SmPzyWZ)CCzYWWq7kWUCddDg(A0FKgFMwGCuiK6RlWM04JxNaAbbi0Mf0MRqla6cA1bTHZXlia8am21bqkIPFi45FoUmmonQ5mmQEeHueDXcActQjXKMHbp)ZXLjdddTRa7Ynm)Tsr66bjBndJtJAodd4rpVoaYp3fHjmPMuM0mm45FoUmzyyODfyxUHjCoEbPOi11i45FoUGwDq7FRueTIZ9wokPQhrq2AqRoO1Zb7kqsrFjPv4lKtA)ybAZei0MLHXPrnNHz(8kW2d0eMuZ2KMHbp)ZXLjdddTRa7Ynm5bT)Tsru9KdEsTnxGKTg0QdAdNJxqu9KdEsTnxGe88phxggNg1CgM5ZRaBpqtysf0zsZWGN)54YKHHH2vGD5gMEFfvQn6XMSqvrRaAbbAtaAFNn0Mm0gohVG07ROspc82EuZrWZ)CCbT5k0MeOnrdJtJAodJQhrifrxSGMWKAUZKMHbp)ZXLjdddTRa7Ynm)TsryP486aiFCk46qYwdA1bT9(qsupOmgzsbTzceAbqxggNg1CggvpIqqFfGrtysf0BsZWGN)54YKHHH2vGD5gMEFfvQn6XMSqvrRaAZeAtaAZkBOnzOnCoEbP3xrLEe4T9OMJGN)54cAZvOnjqBIggNg1CgM5ZRaBpqtysn3ysZW40OMZWO6resr0flOHbp)ZXLjdtys9D(M0mmonQ5mmGN(KJsQVUaBddE(NJltgMWK673M0mmonQ5mmEt9dLX0nEHHbp)ZXLjdtycddke4rrHjntQVnPzyWZ)CCzYWWq7kWUCdZFRueTIZ9wokPQhrq2AqRoOnbO9VvkIwX5ElhLu1Jiin(41jGwqG235dT6G2eG2)wPi)g9aSCusrDR2bmcNS1Gw2SH2W54fK5ZRaBpQ5i45FoUGw2SH2W54fKIIuxJGN)54cA1bT5bTEoyxbsk6ljTcFHCcE(NJlOnrOLnBO9VvksrFjPv4lKt2AqRoOnCoEbPOi11i45FoUG2enmonQ5mmF(ml5OKbyuIh(8YeMuZYKMHbp)ZXLjdddTRa7Ynm5bTHZXliffPUgbp)ZXf0YMn0gohVGuuK6Ae88phxqRoO1Zb7kqsrFjPv4lKtWZ)CCbT6G2)wPiAfN7TCusvpIG04JxNaAbbAbDqRoO9VvkIwX5ElhLu1JiiBnOLnBOnCoEbPOi11i45FoUGwDqBEqRNd2vGKI(ssRWxiNGN)54YW40OMZWay79Q8tokPNd2ta2eMutIjnddE(NJltgggAxb2LBy(BLIOvCU3Yrjv9icsJpEDcOfeOnBOvh0(3kfrR4CVLJsQ6reKTg0YMn0g1dkJrUkeAbbAZ2W40OMZWqbxCUuen6SyctQjLjnddE(NJltgggAxb2LBy(BLI0iLfokes10uKS1Gw2SH2)wPinszHJcHunnfL0zFb2er4uwGwqG23VnmonQ5mmbyuUV)SVLunnfnHj1SnPzyWZ)CCzYWWq7kWUCdtEq7FRueTIZ9wokPQhrq2AqRoOnpO9VvkYVrpalhLuu3QDaJWjBndJtJAodJAOBbUKEoyxbk)O)yctQGotAgg88phxMmmm0UcSl3WKh0(3kfrR4CVLJsQ6reKTg0QdAZdA)BLI8B0dWYrjf1TAhWiCYwdA1bTRji05O4fTh4sQ4(dk)7(in(41jGwGqB(ggNg1Cgg6Cu8I2dCjvC)bnHj1CNjnddE(NJltgggAxb2LBy(BLIOvCU3Yrjv9icYwdAzZgA)BLIGpAJESL9(qPE01MJS1Gw2SHw6m81O)i)g9aSCusrDR2bmcN04JxNaAZeAbD5dTjdTVZgAzZgAPt3BTOMtqQdvk)Zrz07ambp)ZXLHXPrnNHr)08fOW6KnkMZpkActQGEtAgg88phxMmmm0UcSl3WKh0(3kfrR4CVLJsQ6reKTg0QdAZdA)BLI8B0dWYrjf1TAhWiCYwZW40OMZW0LMghL1jfAofnHj1CJjnddE(NJltgggAxb2LBy(BLIGpAJESL9(qPE01MJ04JxNaAbbAZgA1bT)Tsr(n6by5OKI6wTdyeozRbTSzdTjaT9(qsupOmgzwqBMqla6cA1bT9(kQuB0Jn0cc0MD(qBIggNg1CgMh8z6xYrj5BATKRg9hHjmP(oFtAggNg1CgMgDT6aivC)bfgg88phxMmmHjmHHbuylQ5mPMv(zLF(jvwzBy079vhaHHjP1J20bUG235dTonQ5GwEjcbbYQHrRhvXrddObAZ99icOn3o6byOf0IRaaoGScAGwWrOjaTME6aQa8(tOZt6I6zZ9OMJ2Uksxup00HScAG2K2(lOnjVtbAZk)SYhYkKvqd0M0d2paOa0kKvqd0cAdTjTokFVqOnPDDlOn33iMdsGScAGwqBOnP7AbTkNZ)oLfOvnn0Uf1baAtAM0aOLPaTjDMCp0wkOvJ7VWgARRIYduaTzmmq7hvtJqR2m86aaT8bqrH2saT05rJJbUiqwbnqlOn0M0d2pai0gEdadsupOmg5QqOngOnQhugJCvi0gd0Ufi0IhD2xGn0YXdqagABpaJn0gG9dA1MaVOCo0gTladTl0dWccKvqd0cAdTj9dFbT52GEhqRFlOTDA5COn0JolccKviRGgOnPzsJiDh4cA)OAAeAPZZ3dO9JaQtqG2KUukQfcO9Md0gS3pQnhADAuZjG254ViqwDAuZjiAnsNNVhjdmDTjQ5GS60OMtq0AKopFpsgy6BbkRaFs58heONJaS3UqQMlKJsQn6XgYQtJAobrRr6889izGPdkVl)ZXuo)bbobySLZj3cuI5YU00WvkGY5BeycyUSlnnCrUjMUMTqcG7RYJPfYVVaGSzJ5YU00WfHoDV1cCjbW9v5X0c53xaq2SXCzxAA4IqNU3AbUKa4(Q8yAH8bxoNxZXMnMl7stdxeqvoxokPF1Jh4s(5ZSyZgZLDPPHlIQAriF8afsH2laCxiyZgZLDPPHlsUfkKGh9CSzZgZLDPPHlYnX01SfsaCFvEmTq(GlNZR5yZgZLDPPHlIladk)qHS9CMwsN25jczfYkObAtAM0is3bUGweuy)cAJ6bH2amcTonMgAlb06GYlU)5ibYQtJAobWN6wsvJyoiKvqd0M0vtJ)cAZ99icOn3JGcBO1Vf0(41fEDqBsl6lOnnNpNaYQtJAorYath8ONxha5N7IiLsbmV1eevpIqQqqHnjkkl1bqxc5fohVG8B0dWYrjf1TAhWiCcE(NJl2SPZWxJ(J8B0dWYrjf1TAhWiCsJpEDImFNDIqwDAuZjsgy6a4oTCU0xGYpkMsPa(3kfPOVKHZNtqA8XRtacqa0LU)wPif9LmC(CcYwtNqd5Cz4nameeaCNwox6lq5hfZeyw6siVW54fKFJEawokPOUv7agHtWZ)CCXMnDg(A0FKFJEawokPOUv7agHtA8XRtK57SteYQtJAorYatx1JiKIOlwWukfW)wPif9LmC(CcsJpEDcqacGU093kfPOVKHZNtq2A6siVW54fKFJEawokPOUv7agHtWZ)CCXMnDg(A0FKFJEawokPOUv7agHtA8XRtK57SteYQtJAorYatN6CU0PrnNKxIiLZFqGOqGhffqwDAuZjsgy6uNZLonQ5K8sePC(dcKodFn6pbKvNg1CIKbMEVpPtJAojVerkN)Ga)JqgfLL6aKsPa(3kf53OhGLJskQB1oGr4KTgKvNg1CIKbMEVpPtJAojVerkN)Ga)JqQndVoaPukGHZXli)g9aSCusrDR2bmcNGN)54sxcjqNHVg9h53OhGLJskQB1oGr4KgF86eaZxhDg(A0FeTIZ9wokPQhrqA8XRtaY78tKn7eOZWxJ(J8B0dWYrjf1TAhWiCsJpEDcqYkFDr9GYyKRcbjjzNyIqwDAuZjsgy69(KonQ5K8sePC(dcC(8kW2JAUukfW)wPiAfN7TCusvpIGS10fohVGmFEfy7rnhbp)ZXfKvNg1CIKbMEVpPtJAojVerkN)Ga9btPuaDAuGcL4HpfkYeywqwDAuZjsgy6uNZLonQ5K8sePC(dcue(T8EbzfYQtJAobXheyJptlqokes91fyNsPagohVGaWdWyxhaPiM(HGN)54In7e8CWUcKO6jh8Kb(OHIG0(XIoHgY5YWBayiin(mTa5Oqi1xxGDMatIU8(BLI01ds2Ajcz1PrnNG4dMmW0bWDA5CPVaLFumLsbmCoEbr1Jie0xbyKGN)54cYQtJAobXhmzGPR6resr0flyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e1rNHVg9hPXNPfihfcP(6cSjn(41jabyw5ka6sx4C8ccapaJDDaKIy6hcE(NJlD5fohVGO6rec6RamsWZ)CCbz1PrnNG4dMmW0v9icPi6IfmLsbKodFn6psJptlqokes91fytA8XRtacWSYva0LUW54feaEag76aifX0pe88phxqwDAuZji(GjdmDWJEEDaKFUlIukfW)wPiD9GKTgKvNg1CcIpyYatx1Jie0xbymLsb8VvkclfNxha5Jtbxhs2AqwDAuZji(GjdmDaCNwox6lq5hftPua79vuP2OhBYcvfTcqs4D2jhohVG07ROspc82EuZrWZ)CCLRjjriRonQ5eeFWKbMUQhrifrxSGPqFr5Om8gagcGVtPuatyH)TsrApNPlkseHtzbKSzZEH)TsrApNPlksA8XRtaY78tuxVVIk1g9ytwOQOvascVZo5W54fKEFfv6rG32JAocE(NJRCnjjQlVW54fevpIqqFfGrcE(NJliRonQ5eeFWKbMUQhrifrxSGPukG9(kQuB0JnzHQIwbij8o7KdNJxq69vuPhbEBpQ5i45FoUY1KKOU8cNJxqu9icb9vagj45FoUGS60OMtq8btgy6n(mTa5Oqi1xxGnKvNg1CcIpyYatx1Jie0xbyeYQtJAobXhmzGPpFEfy7bMc9fLJYWBayia(oLsbmHf(3kfP9CMUOireoLfqYMn7f(3kfP9CMUOiPXhVobiVZprD9(kQuB0JnzHQIwrMjKv2jhohVG07ROspc82EuZrWZ)CCLRjjrD5fohVGO6rec6RamsWZ)CCbz1PrnNG4dMmW0NpVcS9atPua79vuP2OhBYcvfTImtiRStoCoEbP3xrLEe4T9OMJGN)54kxtsIqwDAuZji(GjdmDaCNwox6lq5hfHS60OMtq8btgy6QEeHueDXcMc9fLJYWBayia(oLsbmHf(3kfP9CMUOireoLfqYMn7f(3kfP9CMUOiPXhVobiVZprD5fohVGO6rec6RamsWZ)CCbz1PrnNG4dMmW0v9icPi6IfeYQtJAobXhmzGPdE6tokP(6cSHS60OMtq8btgy6Et9dLX0nEbKviRGgOnJg9am0okOLPUv7agHdTAZWRda02t4rnh0cAfAfH3HaAZkFb0(r10i0M0P4CVH2rbT5(Eeb0Mm0MXWaTEJqRdkV4(NJqwDAuZji)ri1MHxhaGGh986ai)CxePukG)Tsr66bjBniRonQ5eK)iKAZWRdqYatF(8kW2dmf6lkhLH3aWqa8DkLcycl8Vvks75mDrrIiCklGKnB2l8Vvks75mDrrsJpEDcqENFI669vuP2OhBYcvfTImbMv26YlCoEbr1Jie0xbyKGN)54cYQtJAob5pcP2m86aKmW0NpVcS9atPua79vuP2OhBYcvfTImbMv2qwDAuZji)ri1MHxhGKbMoaUtlNl9fO8JIPukG9(kQuB0JnzHQIwbizLVoHgY5YWBayiia4oTCU0xGYpkMjWS0rNHVg9hrR4CVLJsQ6reKgF86ezMnKvNg1CcYFesTz41bizGPR6resr0flyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e117ROsTrp2KfQkAfGKv(6YlCoEbr1Jie0xbyKGN)54shDg(A0FeTIZ9wokPQhrqA8XRtKz2qwDAuZji)ri1MHxhGKbMUQhrifrxSGPukG9(kQuB0JnzHQIwbizLVo6m81O)iAfN7TCusvpIG04JxNiZSHS60OMtq(JqQndVoajdmDvpIqqFfGXukfW)wPiSuCEDaKpofCDizRPR3xrLAJESjluv0kYmH3zNC4C8csVVIk9iWB7rnhbp)ZXvUMKe1j0qoxgEdadbr1Jie0xbymtGzbz1PrnNG8hHuBgEDasgy6QEeHG(kaJPukG9(kQuB0JnzHQIwrMatijzNC4C8csVVIk9iWB7rnhbp)ZXvUMKe1j0qoxgEdadbr1Jie0xbymtGzbz1PrnNG8hHuBgEDasgy6ZNxb2EGPqFr5Om8gagcGVtPuatyH)TsrApNPlkseHtzbKSzZEH)TsrApNPlksA8XRtaY78tuxVVIk1g9ytwOQOvKjWess2jhohVG07ROspc82EuZrWZ)CCLRjjrD5fohVGO6rec6RamsWZ)CCbz1PrnNG8hHuBgEDasgy6ZNxb2EGPukG9(kQuB0JnzHQIwrMatijzNC4C8csVVIk9iWB7rnhbp)ZXvUMKeHS60OMtq(JqQndVoajdmDaCNwox6lq5hftPuaPZWxJ(JOvCU3Yrjv9icsJpEDIm79HKOEqzmYKsxVVIk1g9ytwOQOvassLVoHgY5YWBayiia4oTCU0xGYpkMjWSGS60OMtq(JqQndVoajdmDvpIqkIUybtH(IYrz4nameaFNsPaMWc)BLI0EotxuKicNYcizZM9c)BLI0EotxuK04JxNaK35NOo6m81O)iAfN7TCusvpIG04JxNiZEFijQhugJmP017ROsTrp2KfQkAfGKu5RlVW54fevpIqqFfGrcE(NJliRonQ5eK)iKAZWRdqYatx1JiKIOlwWukfq6m81O)iAfN7TCusvpIG04JxNiZEFijQhugJmP017ROsTrp2KfQkAfGKu5dzfYkObAZ9oN)DklqBmq7wGqBsNj3Nc0M0mPbqlHw9GXdA3cSbTRRIYduaTzmmqRwJpESBK)Iaz1PrnNG8hHmkkl1baOwX5ElhLu1JisPuaPZWxJ(JGpAJESL9(qPE01MJ04JxNaYQtJAob5pczuuwQdqYathF0g9yl79Hs9ORnhKvNg1CcYFeYOOSuhGKbM(85vGThyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e117ROsTrp2GamjzPlVW54fevpIqqFfGrcE(NJliRonQ5eK)iKrrzPoajdm95ZRaBpWukfWEFfvQn6XgeGjjliRonQ5eK)iKrrzPoajdm9gFMwGCuiK6RlWoLsbmCoEbbGhGXUoasrm9dbp)ZXfKvNg1CcYFeYOOSuhGKbMo4rpVoaYp3frkLc4FRuKUEqYwdYQtJAob5pczuuwQdqYatF(8kW2dmf6lkhLH3aWqa8DkLcycl8Vvks75mDrrIiCklGKnB2l8Vvks75mDrrsJpEDcqENFI669HKOEqzmYSbbaDXMDVVIk1g9ydcWKkBD5fohVGO6rec6RamsWZ)CCbz1PrnNG8hHmkkl1bizGPpFEfy7bMsPa27djr9GYyKzdca6In7EFfvQn6XgeGjv2qwDAuZji)riJIYsDasgy6QEeHG(kaJPukG)TsryP486aiFCk46qYwtNqd5Cz4nameevpIqqFfGXmbMfKvNg1CcYFeYOOSuhGKbMo4Pp5OK6RlWoLsbS3xrLAJESjluv0kYeysYsxVpKe1dkJrMKmbqxqwDAuZji)riJIYsDasgy6n(mTa5Oqi1xxGnKvNg1CcYFeYOOSuhGKbMUQhriOVcWykLcOqd5Cz4nameevpIqqFfGXmbMfKvNg1CcYFeYOOSuhGKbM(85vGThyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e117ROsTrp2KfQkAfzMv2Sz37dZmj6YlCoEbr1Jie0xbyKGN)54cYQtJAob5pczuuwQdqYatF(8kW2dmLsbS3xrLAJESjluv0kYmRSzZU3hMzsGS60OMtq(JqgfLL6aKmW09M6hkJPB8IukfWEFfvQn6XMSqvrRiZSZhYkKvqd0M0p8f0cg9oGw6CRkQ5eqwDAuZji0HVKGrVdGuWEDc5OKfftPua)BLIqh(scg9oiIWPSKz26I6bLXixfcca6cYQtJAobHo8Lem6DKmW0PG96eYrjlkMsPaMWFRuebIb46aiBhasA8XRtaca6krD)TsreigGRdGSDaizRbz1PrnNGqh(scg9osgy6uWEDc5OKfftPuat4VvkIwX5ElhLu1Jiin(41jabia6kxt4DY0z4Rr)ru9ic9V6hHuT7xKg91RezZ(VvkIwX5ElhLu1Jiin(41jaP3hsI6bLXitsI6(BLIOvCU3Yrjv9icYwtxcEoyxbsk6ljTcFHCs7hlGa8nB2)Tsr(n6by5OKI6wTdyeozRLOU8cNJxqkksDncE(NJliRonQ5ee6WxsWO3rYatNc2RtihLSOykLc4FRueTIZ9wokPQhrqA8XRtacOx3FRuK9bE4VKIOXdqaM04JxNaea0vUMW7KPZWxJ(JO6re6F1pcPA3Vin6RxjQ7VvkY(ap8xsr04biatA8XRtO7VvkIwX5ElhLu1JiiBnDj45GDfiPOVK0k8fYjTFSacW3Sz)3kf53OhGLJskQB1oGr4KTwI6YlCoEbPOi11i45FoUGS60OMtqOdFjbJEhjdmDkyVoHCuYIIPukGj83kfPOVK0k8fYjn(41jajPyZ(VvksrFjPv4lKtA8XRtasVpKe1dkJrMKe193kfPOVK0k8fYjBnDEoyxbsk6ljTcFHCs7hlzcmlD593kf53OhGLJskQB1oGr4KTMU8cNJxqkksDncE(NJliRonQ5ee6WxsWO3rYatNc2RtihLSOykLc4FRuKI(ssRWxiNS1093kfzFGh(lPiA8aeGjBnDEoyxbsk6ljTcFHCs7hlzcmlD593kf53OhGLJskQB1oGr4KTMU8cNJxqkksDncE(NJliRonQ5ee6WxsWO3rYatNc2RtihLSOykLc4FRueTIZ9wokPQhrqA8XRtassP7VvkIwX5ElhLu1JiiBnDHZXliffPUgbp)ZXLU)wPi0HVKGrVdIiCklzc8nOxNNd2vGKI(ssRWxiN0(XciaFdz1PrnNGqh(scg9osgy6uWEDc5OKfftPua)BLIOvCU3Yrjv9icYwtx4C8csrrQRrWZ)CCPZZb7kqsrFjPv4lKtA)yjtGzPlH)wPi0HVKGrVdIiCklzc8DUr3FRuKI(ssRWxiN04JxNaea0LU)wPif9LKwHVqozRXM9FRuK9bE4VKIOXdqaMS1093kfHo8Lem6DqeHtzjtGVb9jczfYQtJAobHodFn6pbWTaLvGpPC(dc0Zra2BxivZfYrj1g9yNsPaMaDg(A0Fe8rB0JTS3hk1JU2CKg91lD5bkVl)ZrYeGXwoNClqjMl7stdxjYMDc0z4Rr)r0ko3B5OKQEebPXhVobiaFNVoq5D5FosMam2Y5KBbkXCzxAA4kriRonQ5ee6m81O)ejdm9TaLvGpPC(dcKVBwWwiRtuRA2cjGsfPukGHZXli)g9aSCusrDR2bmcNGN)54sxcjqNHVg9hrR4CVLJsQ6reKgF86eGa8D(6aL3L)5izcWylNtUfOeZLDPPHRezZoH)wPiAfN7TCusvpIGS10LhO8U8phjtagB5CYTaLyUSlnnCLyISzNWFRueTIZ9wokPQhrq2A6YlCoEb53OhGLJskQB1oGr4e88phxjcz1PrnNGqNHVg9NizGPVfOSc8jLZFqG0xu(e9Cfv(5UisPuaZ7VvkIwX5ElhLu1JiiBniRonQ5ee6m81O)ejdm9TaLvGpIukfWeOZWxJ(JOvCU3Yrjv9icsJ(6fB20z4Rr)r0ko3B5OKQEebPXhVorMzLFI6siVW54fKFJEawokPOUv7agHtWZ)CCXMnDg(A0Fe8rB0JTS3hk1JU2CKgF86ezMBYoriRonQ5ee6m81O)ejdm9TaLvGpPC(dc0fGbLFOq2EotlPt78ukfWf(3kfP9CMwsN25Yf(3kfzn6piRonQ5ee6m81O)ejdm9TaLvGpPC(dc0fGbLFOq2EotlPt78ukfq6m81O)i4J2OhBzVpuQhDT5in(41jYm3KVUf(3kfP9CMwsN25Yf(3kfzRPduEx(NJKjaJTCo5wGsmx2LMgUyZ(VvkYVrpalhLuu3QDaJWjBnDl8Vvks75mTKoTZLl8VvkYwtxEGY7Y)CKmbySLZj3cuI5YU00WfB2)TsrWhTrp2YEFOup6AZr2A6w4FRuK2ZzAjDANlx4FRuKTMU8cNJxq(n6by5OKI6wTdyeobp)ZXfB2r9GYyKRcbjR3qwDAuZji0z4Rr)jsgy6BbkRaFs58heyUfkKGh9CStPuataZLDPPHlcF3SGTqwNOw1SfsaLk093kfrR4CVLJsQ6reKgF86ejYMDc5H5YU00WfHVBwWwiRtuRA2cjGsf6(BLIOvCU3Yrjv9icsJpEDcqENLU)wPiAfN7TCusvpIGS1seYQtJAobHodFn6prYatFlqzf4tkN)Gaz5MqokPF0cVqQ29Rukfq6m81O)i4J2OhBzVpuQhDT5in(41jYmPYhYQtJAobHodFn6prYatFlqzf4tkN)Gab0Zbqi166X5Y2bGPukG9(qqaMeD593kfrR4CVLJsQ6reKTMUeY7VvkYVrpalhLuu3QDaJWjBn2SZlCoEb53OhGLJskQB1oGr4e88phxjcz1PrnNGqNHVg9NizGPVfOSc8jLZFqGTNZAFSiK)cGSXL8VJyoiRonQ5ee6m81O)ejdm9TaLvGpPC(dc8bBKLaSlKk)aKsPaM3FRuKFJEawokPOUv7agHt2A6Y7VvkIwX5ElhLu1JiiBniRonQ5ee6m81O)ejdmDTjQ5sPua)BLIOvCU3Yrjv9icYwt3FRue8rB0JTS3hk1JU2CKTgKvNg1CccDg(A0FIKbM(NpZsQ29RukfW)wPiAfN7TCusvpIGS1093kfbF0g9yl79Hs9ORnhzRbz1PrnNGqNHVg9NizGP)XwGnl1biLsb8VvkIwX5ElhLu1JiiBniRonQ5ee6m81O)ejdmDVP(HsTnxGPukGjK3FRueTIZ9wokPQhrq2A6CAuGcL4HpfkYeywjYMDE)Tsr0ko3B5OKQEebzRPlHEFizHQIwrMaZwxVVIk1g9ytwOQOvKjqqx(jcz1PrnNGqNHVg9NizGPZlaGdHm3AVa8GxKsPa(3kfrR4CVLJsQ6reKTgKvNg1CccDg(A0FIKbMUFuueTZLuNZtPua)BLIOvCU3Yrjv9icYwt3FRue8rB0JTS3hk1JU2CKTgKvNg1CccDg(A0FIKbMUQA8ZNzLsPa(3kfrR4CVLJsQ6reKgF86eGae0R7Vvkc(On6Xw27dL6rxBoYwdYQtJAobHodFn6prYat)7aKJsgDrzrKsPa(3kfrR4CVLJsQ6reKTMUe(BLIOvCU3Yrjv9icsJpEDcqYwx4C8ccD4ljy07GGN)54In78cNJxqOdFjbJEhe88phx6(BLIOvCU3Yrjv9icsJpEDcqssI6CAuGcL4Hpfka(Mn7)wPicedW1bq2oaKS1050OafkXdFkua8nKviRGgOn33JiGw6m81O)eqwDAuZji0z4Rr)jsgy6AfN7TCusvpIiLsbmb6m81O)i4J2OhBzVpuQhDT5in(41jyZoCoEbPOi11i45FoUsuxE)Tsr0ko3B5OKQEebzRbz1PrnNGqNHVg9NizGP)B0dWYrjf1TAhWi8u2cuokLeaDb8DkLciDg(A0Fe8rB0JTS3hk1JU2CKgF86e6OZWxJ(JOvCU3Yrjv9icsJpEDciRonQ5ee6m81O)ejdmD8rB0JTS3hk1JU2CPukG0z4Rr)r0ko3B5OKQEebPrF9sx4C8cY85vGTh1Ce88phx669HKOEqzmYSZeaDPR3xrLAJESjluv0kYe478zZoQhugJCviizLpKvNg1CccDg(A0FIKbMo(On6Xw27dL6rxBUukfWeOZWxJ(JOvCU3Yrjv9icsJ(6fB2r9GYyKRcbjR8tux4C8cYVrpalhLuu3QDaJWj45FoU017ROsTrp2zc6YhYQtJAobHodFn6prYathF0g9yl79Hs9ORnxkLcy4C8csrrQRrWZ)CCPR3hcssGS60OMtqOZWxJ(tKmW0PoNlDAuZj5Lis58heiD4ljy07iLsbmCoEbHo8Lem6DqWZ)CCPlHe(BLIqh(scg9oiIWPSKjW35RBH)TsrApNPlkseHtzby2jYMDupOmg5QqqacGUseYQtJAobHodFn6prYatx1Ji0)QFes1UFLsPaMWFRueTIZ9wokPQhrq2A68CWUcKu0xsAf(c5K2pwab4BDj83kfrR4CVLJsQ6reKgF86eGaeaDXM9FRuK9bE4VKIOXdqaM04JxNaeGaOlD)Tsr2h4H)skIgpabyYwlXeHS60OMtqOZWxJ(tKmW0v9ic9V6hHuT7xPukGj83kfPOVK0k8fYjBnD5fohVGuuK6Ae88phx6s4VvkY(ap8xsr04biat2ASz)3kfPOVK0k8fYjn(41jabia6kXezZ(VvksrFjPv4lKt2A6(BLIu0xsAf(c5KgF86eGaeaDPlCoEbPOi11i45FoU093kfrR4CVLJsQ6reKTgKvNg1CccDg(A0FIKbMUQhrO)v)iKQD)kLsbmQhugJCviiaOl2StiQhugJCvii0z4Rr)r0ko3B5OKQEebPXhVoHU)wPi7d8WFjfrJhGamzRLiKviRonQ5eeuiWJIcGF(ml5OKbyuIh(8kLsb8VvkIwX5ElhLu1JiiBnDj83kfrR4CVLJsQ6reKgF86eG8oFDj83kf53OhGLJskQB1oGr4KTgB2HZXliZNxb2EuZrWZ)CCXMD4C8csrrQRrWZ)CCPlpphSRajf9LKwHVqobp)ZXvISz)3kfPOVK0k8fYjBnDHZXliffPUgbp)ZXvIqwDAuZjiOqGhffjdmDaBVxLFYrj9CWEcWPukG5fohVGuuK6Ae88phxSzhohVGuuK6Ae88phx68CWUcKu0xsAf(c5e88phx6(BLIOvCU3Yrjv9icsJpEDcqaD6(BLIOvCU3Yrjv9icYwJn7W54fKIIuxJGN)54sxEEoyxbsk6ljTcFHCcE(NJliRonQ5eeuiWJIIKbMofCX5sr0OZskLc4FRueTIZ9wokPQhrqA8XRtas26(BLIOvCU3Yrjv9icYwJn7OEqzmYvHGKnKvNg1Cccke4rrrYatpaJY99N9TKQPPykLc4FRuKgPSWrHqQMMIKTgB2)TsrAKYchfcPAAkkPZ(cSjIWPSaY73qwDAuZjiOqGhffjdmD1q3cCj9CWUcu(r)jLsbmV)wPiAfN7TCusvpIGS10L3FRuKFJEawokPOUv7agHt2AqwDAuZjiOqGhffjdmD6Cu8I2dCjvC)btPuaZ7VvkIwX5ElhLu1JiiBnD593kf53OhGLJskQB1oGr4KTMU1ee6Cu8I2dCjvC)bL)DFKgF86eaZhYQtJAobbfc8OOizGPRFA(cuyDYgfZ5hftPua)BLIOvCU3Yrjv9icYwJn7)wPi4J2OhBzVpuQhDT5iBn2SPZWxJ(J8B0dWYrjf1TAhWiCsJpEDImbD5N87SzZMoDV1IAobPouP8phLrVdWe88phxqwDAuZjiOqGhffjdm9U004OSoPqZPykLcyE)Tsr0ko3B5OKQEebzRPlV)wPi)g9aSCusrDR2bmcNS1GS60OMtqqHapkksgy6p4Z0VKJsY30Ajxn6pIukfW)wPi4J2OhBzVpuQhDT5in(41jajBD)Tsr(n6by5OKI6wTdyeozRXMDc9(qsupOmgzwzcGU017ROsTrp2GKD(jcz1PrnNGGcbEuuKmW0B01QdGuX9huazfYkObAZT9ZRaBpQ5G2EcpQ5GS60OMtqMpVcS9OMdyJptlqokes91fyNsPagohVGaWdWyxhaPiM(HGN)54cYQtJAobz(8kW2JAUKbM(85vGThyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e1Lx4C8cIQhriOVcWibp)ZXLU8(BLI01ds2A6eAiNldVbGHGaE0ZRdG8ZDrKjWKaz1PrnNGmFEfy7rnxYatF(8kW2dmLsbmVW54fevpIqqFfGrcE(NJlD593kfPRhKS10j0qoxgEdadbb8ONxha5N7IitGjbYQtJAobz(8kW2JAUKbMUQhriOVcWykLcyc)TsryP486aiFCk46qsJonyZoH)wPiSuCEDaKpofCDizRPlbTgbLeaDrEtu9icPi6IfKnBTgbLeaDrEtap651bq(5UiyZwRrqjbqxK3eaCNwox6lq5hftmXe1j0qoxgEdadbr1Jie0xbymtGzbz1PrnNGmFEfy7rnxYatF(8kW2dmf6lkhLH3aWqa8DkLcycl8Vvks75mDrrIiCklGKnB2l8Vvks75mDrrsJpEDcqENFI6(BLIWsX51bq(4uW1HKgDAWMDc)TsryP486aiFCk46qYwtxcAnckja6I8MO6resr0fliB2Anckja6I8MaE0ZRdG8ZDrWMTwJGscGUiVja4oTCU0xGYpkMyIqwDAuZjiZNxb2EuZLmW0NpVcS9atPua)BLIWsX51bq(4uW1HKgDAWMDc)TsryP486aiFCk46qYwtxcAnckja6I8MO6resr0fliB2Anckja6I8MaE0ZRdG8ZDrWMTwJGscGUiVja4oTCU0xGYpkMyIqwDAuZjiZNxb2EuZLmW0bWDA5CPVaLFumLsbmH8(BLI01ds2ASz37ROsTrp2KfQkAfG8oF2S79HKOEqzmYSYeaDLOoHgY5YWBayiia4oTCU0xGYpkMjWSGS60OMtqMpVcS9OMlzGPdE0ZRdG8ZDrKsPa(3kfPRhKS10j0qoxgEdadbb8ONxha5N7IitGzbz1PrnNGmFEfy7rnxYatx1JiKIOlwWuOVOCugEdadbW3PukGjSW)wPiTNZ0ffjIWPSas2SzVW)wPiTNZ0ffjn(41ja5D(jQlV)wPiD9GKTgB29(kQuB0JnzHQIwbiVZNn7EFijQhugJmRmbqx6YlCoEbr1Jie0xbyKGN)54cYQtJAobz(8kW2JAUKbMUQhrifrxSGPukG593kfPRhKS1yZU3xrLAJESjluv0ka5D(Sz37djr9GYyKzLja6cYQtJAobz(8kW2JAUKbMo4rpVoaYp3frkLc4FRuKUEqYwdYQtJAobz(8kW2JAUKbM(85vGThyk0xuokdVbGHa47ukfWew4FRuK2Zz6IIer4uwajB2Sx4FRuK2Zz6IIKgF86eG8o)e1Lx4C8cIQhriOVcWibp)ZXfKvNg1CcY85vGTh1Cjdm95ZRaBpqiRqwbnqlt43Y7f0kQdahbTdVbGb02t4rnhKvNg1CcIi8B59cyJptlqokes91fydz1PrnNGic)wEVsgy6QEeHueDXcMsPasNHVg9hPXNPfihfcP(6cSjn(41jabyw5ka6sx4C8ccapaJDDaKIy6hcE(NJliRonQ5eer43Y7vYath8ONxha5N7IiLsb8VvksxpizRbz1PrnNGic)wEVsgy6ZNxb2EGPukGHZXliffPUgbp)ZXLU)wPiAfN7TCusvpIGS1055GDfiPOVK0k8fYjTFSKjWSGS60OMtqeHFlVxjdm95ZRaBpWukfW8(BLIO6jh8KABUajBnDHZXliQEYbpP2MlqcE(NJliRonQ5eer43Y7vYatx1JiKIOlwWukfWEFfvQn6XMSqvrRaKeENDYHZXli9(kQ0JaVTh1Ce88phx5AsseYQtJAobre(T8ELmW0v9icb9vagtPua)BLIWsX51bq(4uW1HKTMUEFijQhugJmPYeia6cYQtJAobre(T8ELmW0NpVcS9atPua79vuP2OhBYcvfTImtiRStoCoEbP3xrLEe4T9OMJGN)54kxtsIqwDAuZjiIWVL3RKbMUQhrifrxSGqwDAuZjiIWVL3RKbMo4Pp5OK6RlWgYQtJAobre(T8ELmW09M6hkJPB8cdJqdPMuZk73MWegda]] )
    
end
