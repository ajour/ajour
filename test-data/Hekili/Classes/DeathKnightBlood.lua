-- DeathKnightBlood.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DEATHKNIGHT' then
    local spec = Hekili:NewSpecialization( 250 )

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

            if state.talent.rune_strike.enabled then state.gainChargeTime( "rune_strike", amount ) end

            if state.azerite.eternal_rune_weapon.enabled and state.buff.dancing_rune_weapon.up then
                if state.buff.dancing_rune_weapon.expires - state.buff.dancing_rune_weapon.applied < state.buff.dancing_rune_weapon.duration + 5 then
                    state.buff.dancing_rune_weapon.expires = min( state.buff.dancing_rune_weapon.applied + state.buff.dancing_rune_weapon.duration + 5, state.buff.dancing_rune_weapon.expires + ( 0.5 * amount ) )
                    state.buff.eternal_rune_weapon.expires = min( state.buff.dancing_rune_weapon.applied + state.buff.dancing_rune_weapon.duration + 5, state.buff.dancing_rune_weapon.expires + ( 0.5 * amount ) )
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

    local spendHook = function( amt, resource )
        if amt > 0 and resource == "runic_power" and talent.red_thirst.enabled then
            cooldown.vampiric_blood.expires = max( 0, cooldown.vampiric_blood.expires - amt / 10 )
        end
    end

    spec:RegisterHook( "spend", spendHook )


    -- Talents
    spec:RegisterTalents( {
        heartbreaker = 19165, -- 221536
        blooddrinker = 19166, -- 206931
        rune_strike = 19217, -- 210764

        rapid_decomposition = 19218, -- 194662
        hemostasis = 19219, -- 273946
        consumption = 19220, -- 274156

        foul_bulwark = 19221, -- 206974
        ossuary = 22134, -- 219786
        tombstone = 22135, -- 219809

        will_of_the_necropolis = 22013, -- 206967
        antimagic_barrier = 22014, -- 205727
        rune_tap = 22015, -- 194679

        grip_of_the_dead = 19227, -- 273952
        tightening_grasp = 19226, -- 206970
        wraith_walk = 19228, -- 212552

        voracious = 19230, -- 273953
        bloodworms = 19231, -- 195679
        mark_of_blood = 19232, -- 206940

        purgatory = 21207, -- 114556
        red_thirst = 21208, -- 205723
        bonestorm = 21209, -- 194844
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3468, -- 214027
        gladiators_medallion = 3467, -- 208683
        relentless = 3466, -- 196029

        antimagic_zone = 3434, -- 51052
        blood_for_blood = 607, -- 233411
        dark_simulacrum = 3511, -- 77606
        death_chain = 609, -- 203173
        decomposing_aura = 3441, -- 199720
        heartstop_aura = 3438, -- 199719
        last_dance = 608, -- 233412
        murderous_intent = 841, -- 207018
        necrotic_aura = 3436, -- 199642
        strangulate = 206, -- 47476
        unholy_command = 204, -- 202727
        walking_dead = 205, -- 202731
    } )


    -- Auras
    spec:RegisterAuras( {
        antimagic_shell = {
            id = 48707,
            duration = function () return ( azerite.runic_barrier.enabled and 1 or 0 ) + ( talent.antimagic_barrier.enabled and 6.5 or 5 ) * ( ( level < 116 and equipped.acherus_drapes ) and 2 or 1 ) end,
            max_stack = 1,
        },
        asphyxiate = {
            id = 108194,
            duration = 4,
            max_stack = 1,
        },
        blooddrinker = {
            id = 206931,
            duration = 3,
            max_stack = 1,
        },        
        blood_plague = {
            id = 55078,
            duration = 24, -- duration is capable of going to 32s if its reapplied before the first wears off
            type = "Disease",
            max_stack = 1,
        },
        blood_shield = {
            id = 77535,
            duration = 10,
            max_stack = 1,
        },
        bone_shield = {
            id = 195181,
            duration = 30,
            max_stack = 10,
        },
        bonestorm = {
            id = 194844,
        },
        crimson_scourge = {
            id = 81141,
            duration = 15,
            max_stack = 1,
        },
        dark_command = {
            id = 56222,
            duration = 3,
            max_stack = 1,
        },
        dancing_rune_weapon = {
            id = 81256,
            duration = 8,
            max_stack = 1,
        },
        death_and_decay = {
            id = 43265,
            duration = 10,
        },
        death_grip = {
            id = 51399,
            duration = 3,
        },
        deaths_advance = {
            id = 48265,
            duration = 8,
            max_stack = 1,
        },
        grip_of_the_dead = {
            id = 273984,
            duration = 10,
            max_stack = 10,
        },
        heart_strike = {
            id = 206930, -- slow debuff heart strike applies
            duration = 8,
            max_stack = 1,
        },
        hemostasis = {
            id = 273947,
            duration = 15,
            max_stack = 5,
            copy = "haemostasis"
        },
        icebound_fortitude = {
            id = 48792,
            duration = 8,
            max_stack = 1,
        },
        mark_of_blood = {
            id = 206940,
            duration = 15,
            max_stack = 1,
        },
        on_a_pale_horse = {
            id = 51986,
        },
        ossuary = {
            id = 219788,
            duration = 0, -- duration is persistent when boneshield stacks => 5
            max_stack = 1,
        },
        path_of_frost = {
            id = 3714,
            duration = 600,
            max_stack = 1,
        },
        perdition = { -- debuff from purgatory getting procced
            id = 123981,
            duration = 240,
            max_stack = 1,
        },
        rune_tap = {
            id = 194679,
            duration = 4,
            max_stack = 1,
        },
        shroud_of_purgatory = {
            id = 116888,
            duration = 3,
            max_stack = 1,
        },
        tombstone = {
            id = 219809,
            duration = 8,
            max_stack = 1,
        },
        unholy_strength = {
            id = 53365,
            duration = 15,
            max_stack = 1,
        },
        wraith_walk = {
            id = 212552,
            duration = 4,
            max_stack = 1,
        },
        vampiric_blood = {
            id = 55233,
            duration = 10,
            max_stack = 1,
        },
        veteran_of_the_third_war = {
            id = 48263,
        },
        voracious = {
            id = 274009,
            duration = 6,
            max_stack = 1,
        },

        -- Azerite Powers
        bloody_runeblade = {
            id = 289349,
            duration = 5,
            max_stack = 1
        },

        bones_of_the_damned = {
            id = 279503,
            duration = 30,
            max_stack = 1,
        },

        cold_hearted = {
            id = 288426,
            duration = 8,
            max_stack = 1
        },

        deep_cuts = {
            id = 272685,
            duration = 15,
            max_stack = 1,
        },

        eternal_rune_weapon = {
            id = 278543,
            duration = 5,
            max_stack = 1,
        },

        march_of_the_damned = {
            id = 280149,
            duration = 15,
            max_stack = 1,
        },


        -- PvP Talents
        antimagic_zone = {
            id = 145629,
            duration = 10,
            max_stack = 1,
        },

        blood_for_blood = {
            id = 233411,
            duration = 12,
            max_stack = 1,
        },

        dark_simulacrum = {
            id = 77606,
            duration = 12,
            max_stack = 1,
        },

        death_chain = {
            id = 203173,
            duration = 10,
            max_stack = 1
        },

        decomposing_aura = {
            id = 228581,
            duration = 3600,
            max_stack = 1,
        },

        focused_assault = {
            id = 206891,
            duration = 6,
            max_stack = 1,
        },

        heartstop_aura = {
            id = 228579,
            duration = 3600,
            max_stack = 1,
        },

        necrotic_aura = {
            id = 214968,
            duration = 3600,
            max_stack = 1,
        },

        strangulate = {
            id = 47476,
            duration = 5,
            max_stack = 1,                
        }, 
    } )


    spec:RegisterGear( "tier19", 138355, 138361, 138364, 138349, 138352, 138358 )
    spec:RegisterGear( "tier20", 147124, 147126, 147122, 147121, 147123, 147125 )
        spec:RegisterAura( "gravewarden", {
            id = 242010,
            duration = 10,
            max_stack = 0
        } )

    spec:RegisterGear( "tier21", 152115, 152117, 152113, 152112, 152114, 152116 )

    spec:RegisterGear( "acherus_drapes", 132376 )
    spec:RegisterGear( "cold_heart", 151796 ) -- chilled_heart stacks NYI
    spec:RegisterGear( "consorts_cold_core", 144293 )
    spec:RegisterGear( "death_march", 144280 )
    -- spec:RegisterGear( "death_screamers", 151797 )
    spec:RegisterGear( "draugr_girdle_of_the_everlasting_king", 132441 )
    spec:RegisterGear( "koltiras_newfound_will", 132366 )
    spec:RegisterGear( "lanathels_lament", 133974 )
    spec:RegisterGear( "perseverance_of_the_ebon_martyr", 132459 )
    spec:RegisterGear( "rethus_incessant_courage", 146667 )
    spec:RegisterGear( "seal_of_necrofantasia", 137223 )
    spec:RegisterGear( "service_of_gorefiend", 132367 )
    spec:RegisterGear( "shackles_of_bryndaor", 132365 ) -- NYI (Death Strike heals refund RP...)
    spec:RegisterGear( "skullflowers_haemostasis", 144281 )
        spec:RegisterAura( "haemostasis", {
            id = 235559,
            duration = 3600,
            max_stack = 5
        } )

    spec:RegisterGear( "soul_of_the_deathlord", 151740 )
    spec:RegisterGear( "soulflayers_corruption", 151795 )
    spec:RegisterGear( "the_instructors_fourth_lesson", 132448 )
    spec:RegisterGear( "toravons_whiteout_bindings", 132458 )
    spec:RegisterGear( "uvanimor_the_unbeautiful", 137037 )


    spec:RegisterHook( "reset_precast", function ()
        local control_expires = action.control_undead.lastCast + 300
        if control_expires > now and pet.up then
            summonPet( "controlled_undead", control_expires - now )
        end
    end )

    spec:RegisterStateExpr( "save_blood_shield", function ()
        return settings.save_blood_shield
    end )


    -- Abilities
    spec:RegisterAbilities( {
        antimagic_shell = {
            id = 48707,
            cast = 0,
            cooldown = function () return talent.antimagic_barrier.enabled and 45 or 60 end,
            gcd = "off",

            toggle = "defensives",

            startsCombat = false,
            texture = 136120,

            handler = function ()
                applyBuff( "antimagic_shell" )
            end,
        },


        antimagic_zone = {
            id = 51052,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 237510,

            pvptalent = "antimagic_zone",

            handler = function ()
                applyBuff( "antimagic_zone" )
            end,
        },


        asphyxiate = {
            id = 221562,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 538558,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,            

            handler = function ()
                interrupt()
                applyDebuff( "target", "asphyxiate" )
            end,
        },


        blood_boil = {
            id = 50842,
            cast = 0,
            charges = 2,
            cooldown = 7.5,
            recharge = 7.5,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 237513,

            handler = function ()
                applyDebuff( "target", "blood_plague" )
                active_dot.blood_plague = active_enemies

                if talent.hemostasis.enabled then
                    applyBuff( "hemostasis", 15, min( 5, active_enemies) )
                end

                if level < 116 and equipped.skullflowers_haemostasis then
                    applyBuff( "haemostasis" )
                end

                if level < 116 and set_bonus.tier20_2pc == 1 then
                    applyBuff( "gravewarden" )
                end
            end,
        },


        blood_for_blood = {
            id = 233411,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.15,
            spendType = "health",

            startsCombat = false,
            texture = 1035037,

            pvptalent = "blood_for_blood",

            handler = function ()
                applyBuff( "blood_for_blood" )
            end,
        },


        blooddrinker = {
            id = 206931,
            cast = 3,
            cooldown = 30,
            channeled = true,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 838812,

            talent = "blooddrinker",

            start = function ()
                applyDebuff( "target", "blooddrinker" )
            end,
        },


        bonestorm = {
            id = 194844,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0,
            spendType = "runic_power",

            -- toggle = "cooldowns",

            startsCombat = true,
            texture = 342917,

            talent = "bonestorm",

            handler = function ()
                local cost = min( runic_power.current, 100 )
                spend( cost, "runic_power" )
                applyBuff( "bonestorm", cost / 10 )
            end,
        },


        consumption = {
            id = 274156,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 1121487,

            talent = "consumption",

            handler = function ()                
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

            handler = function ()
            end,
        },


        dancing_rune_weapon = {
            id = 49028,
            cast = 0,
            cooldown = function () return pvptalent.last_dance.enabled and 60 or 120 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135277,

            handler = function ()
                applyBuff( "dancing_rune_weapon" )
                if azerite.eternal_rune_weapon.enabled then applyBuff( "dancing_rune_weapon" ) end
            end,
        },


        dark_command = {
            id = 56222,
            cast = 0,
            cooldown = 8,
            gcd = "off",

            startsCombat = true,
            texture = 136088,

            nopvptalent = "murderous_intent",

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


        death_and_decay = {
            id = 43265,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = function () return buff.crimson_scourge.up and 0 or 1 end,
            spendType = "runes",

            startsCombat = true,
            texture = 136144,

            handler = function ()
                applyBuff( "death_and_decay" )
                removeBuff( "crimson_scourge" )
            end,
        },


        --[[ death_gate = {
            id = 50977,
            cast = 4,
            cooldown = 60,
            gcd = "spell",

            spend = -10,
            spendType = "runic_power",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135766,

            handler = function ()
            end,
        }, ]]


        death_chain = {
            id = 203173,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 1390941,

            pvptalent = "death_chain",

            handler = function ()
                applyDebuff( "target", "death_chain" )
                active_dot.death_chain = min( 3, active_enemies )
            end,
        },


        death_grip = {
            id = 49576,
            cast = 0,
            charges = function () return pvptalent.unholy_command.enabled and 2 or 1 end,
            cooldown = 15,
            recharge = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 237532,

            handler = function ()
                applyDebuff( "target", "death_grip" )
                setDistance( 5 )
            end,
        },


        death_strike = {
            id = 49998,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return ( talent.ossuary.enabled and buff.bone_shield.stack >= 5 ) and 40 or 45 end,
            spendType = "runic_power",

            startsCombat = true,
            texture = 237517,

            handler = function ()
                applyBuff( "blood_shield" ) -- gain absorb shield
                gain( 0.075 * health.max * ( 1.2 * buff.haemostasis.stack ) * ( 1.08 * buff.hemostasis.stack ), "health" )
                removeBuff( "haemostasis" )
                removeBuff( "hemostasis" )

                if talent.voracious.enabled then applyBuff( "voracious" ) end
            end,
        },


        deaths_advance = {
            id = 48265,
            cast = 0,
            cooldown = function () return azerite.march_of_the_damned.enabled and 40 or 45 end,
            gcd = "spell",

            startsCombat = false,
            texture = 237561,

            handler = function ()
                applyBuff( "deaths_advance" )
            end,
        },


        deaths_caress = {
            id = 195292,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 1376743,

            handler = function ()
                applyDebuff( "target", "blood_plague" )
            end,
        },


        gorefiends_grasp = {
            id = 108199,
            cast = 0,
            cooldown = function () return talent.tightening_grasp.enabled and 90 or 120 end,
            gcd = "spell",

            -- toggle = "cooldowns",

            startsCombat = false,
            texture = 538767,

            handler = function ()
            end,
        },


        heart_strike = {
            id = 206930,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 135675,

            handler = function ()                
                applyDebuff( "target", "heart_strike" )
                local targets = min( active_enemies, buff.death_and_decay.up and 5 or 2 )

                removeBuff( "blood_for_blood" )

                if azerite.deep_cuts.enabled then applyDebuff( "target", "deep_cuts" ) end

                if level < 116 and equipped.service_of_gorefiend then cooldown.vampiric_blood.expires = max( 0, cooldown.vampiric_blood.expires - 2 ) end
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


        mark_of_blood = {
            id = 206940,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            spend = 30,
            spendType = "runic_power",

            startsCombat = true,
            texture = 132205,

            talent = "mark_of_blood",

            handler = function ()
                applyDebuff( "target", "mark_of_blood" )
            end,
        },


        marrowrend = {
            id = 195182,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 2,
            spendType = "runes",

            startsCombat = true,
            texture = 1376745,

            handler = function ()
                applyBuff( "bone_shield", 30, buff.bone_shield.stack + ( buff.dancing_rune_weapon.up and 6 or 3 ) )
                if azerite.bones_of_the_damned.enabled then applyBuff( "bones_of_the_damned" ) end
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


        murderous_intent = {
            id = 207018,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 136088,

            pvptalent = "murderous_intent",

            handler = function ()
                applyDebuff( "target", "focused_assault" )
            end,
        },


        path_of_frost = {
            id = 3714,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
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

            toggle = "cooldowns",

            startsCombat = true,
            texture = 136143,

            handler = function ()
            end,
        }, ]]


        rune_strike = {
            id = 210764,
            cast = 0,
            charges = 2,
            cooldown = 60,
            recharge = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 237518,

            talent = "rune_strike",

            handler = function ()
                gain( 1, "runes" )
            end,
        },


        rune_tap = {
            id = 194679,
            cast = 0,
            charges = 2,
            cooldown = 25,
            recharge = 25,
            gcd = "spell",

            spend = 1,
            spendType = "runes",

            startsCombat = true,
            texture = 237529,

            talent = "rune_tap",

            handler = function ()
                applyBuff( "rune_tap" )
            end,
        },


        --[[ runeforging = {
            id = 53428,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 237523,

            handler = function ()
            end,
        }, ]]


        strangulate = {
            id = 47476,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0,
            spendType = "runes",

            toggle = "interrupts",
            pvptalent = "strangulate",
            interrupt = true,

            startsCombat = true,
            texture = 136214,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
                applyDebuff( "target", "strangulate" )
            end,
        },


        tombstone = {
            id = 219809,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 132151,

            talent = "tombstone",
            buff = "bone_shield",

            handler = function ()
                local bs = min( 5, buff.bone_shield.stack )

                removeStack( "bone_shield", bs )                
                gain( 6 * bs, "runic_power" )

                if set_bonus.tier21_2pc == 1 then
                    cooldown.dancing_rune_weapon.expires = max( 0, cooldown.dancing_rune_weapon.expires - ( 3 * bs ) )
                end

                applyBuff( "tombstone" )
            end,
        },


        vampiric_blood = {
            id = 55233,
            cast = 0,
            cooldown = function () return 90 * ( essence.vision_of_perfection.enabled and 0.87 or 1 ) end,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 136168,

            handler = function ()
                applyBuff( "vampiric_blood" )
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


        wraith_walk = {
            id = 212552,
            cast = 4,
            fixedCast = true,
            channeled = true,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 1100041,

            start = function ()
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

        potion = "potion_of_unbridled_fury",

        package = "Blood",        
    } )


    spec:RegisterSetting( "save_blood_shield", true, {
        name = "Save |T237517:0|t Blood Shield",
        desc = "If checked, the default priority (or any priority checking |cFFFFD100save_blood_shield|r) will try to avoid letting your |T237517:0|t Blood Shield fall off during lulls in damage.",
        type = "toggle",
        width = 1.5
    } )   


    spec:RegisterPack( "Blood", 20200514, [[dCKcSaqivjEKqjxsHsXMqk(KqPyuqOofeYQuO4viHzHK6wirzxI8liQHHKCmiyzcspdPKPjiCnKkBdjsFdjIgNqP6CiLsRdjcnpHI7Pk2hsvhuHswia9qKiyIiLQCrfkvBePuWirkf6KiLIwPq1lrkv1nrkv2je5PkAQQsTxv(lrdMKdtzXQQhtyYiUmQndPpRGrdOtlz1kuk9AamBrDBHSBQ(TsdxGJlukTCqpNutxQRd02vL03fuJhjQoVcvRxq08vi7hQpeU33KynFifkvHsfv0Hqisuf70cbQcXn7Xd4BgycaSb(MUfX3eW8UKBgyJNxJCVVPEbHc(MZkcmBDToLa0q7B(bRCtB63)MeR5dPqPkuQOIoecrIQyNwurhL8M6awCifkDuDtGfHW(9VjH1IBglScW8UeSI2JTgiwr771aWghpwyfWUd0uIiJ8q1ab)jXgHSUIaZwxRlGgAJSUIe44XcROD24yfcHGASkuQcLkCCC8yHvucanFG1uI44XcROmSASieMGv0UYjyfTbiZHKt44XcROmSASieMGv0UQRbRR1XQCP7eoESWkkdRglcHjyvSzAVYyfG5Djy1eyXzcwnwF9c)XgSAd6A9eoESWkkdRg7VYowfTqgRSHbiR11RCECSAGDgAnJvaUoJvtGfNjyLUnba60nZLU137BYAn7cwFVpKq4EFt2TFMjhG3uaRMHLDtY2jX6c2BO1mrIMTiw(bHEcYrw5ASkgSkuSIgS6fS6dIIMiMlkFqcbDwgMTG1tGb30eDT(nfRlyVHwZejA2I4RpKc9EFt2TFMjhG3uaRMHLDZpikA6vlkOGLq(Z7ssGbyfnyfIXkOvej)k7DYieDIP8s3ASA0iScAfrYVYENmcrNkhROhRqGoScr30eDT(nnVIm5IkjS1aV(qIw37BYU9Zm5a8Mcy1mSSBcbDo1vel7vIawrpwniiyfnyfe0lHmydZqSkgSkeuDtt0163mIJw44YfvMbffrsGSfPV(qke37BAIUw)MHxyM8kxUeY61nxW3KD7NzYb41hs0DVVj72pZKdWBkGvZWYU5ly1hefnrmxu(Gec6SmmBbRNadUPj6A9BcRGGmllxQdmbF913KWOgyUV3hsiCVVPj6A9BgvorIczoK8nz3(zMCaE9HuO37BYU9Zm5a8Mcy1mSSBk2nt2WEIyUO8bje0zzy2cwpbzJmowrdwHyS6fSsSBMSH90pVlHalhagMGSrghRgncREbRAlZEN(5Djey5aWWe72pZeScr30eDT(n)5Djsuq44xFirR79nnrxRFZpd1meGYhUj72pZKdWRpKcX9(MSB)mtoaVPawndl7MMORxzj7CuXASI(hSkuSA0iScc6mwfdwHawrdwbb9sid2Wmmry0sunwrpwrPuDtt01630GcZzzaywZxFir39(MSB)mtoaVPawndl7MFqu0eOdCZJl1nK9Hgycm4MMOR1VzUga2A5yliziI9(6djk9EFtt01630CbRBOLLclNVj72pZKdWRpKOK37BAIUw)MOfK)5Dj3KD7NzYb41hsX(9(MMOR1V53gKlQSHLaa9nz3(zMCaE9HeT9EFt2TFMjhG3uaRMHLDtXUzYg2teZfLpiHGoldZwW6jihzLRXk6XkAlv30eDT(nb1SSAosF9HecuDVVj72pZKdWB6weFtOfscOdGw(RbjKjYpy3RFtt0163eAHKa6aOL)AqczI8d296xFiHac37BYU9Zm5a8MMOR1VPyCrEB46Lq(ZMUVPawndl7MIDZKnSNiMlkFqcbDwgMTG1tqoYkxJv0GvVGvFqu0eXCr5dsiOZYWSfSEcmaRObRGGoN6kIL9kdbwrpwjmDl7kIVPBr8nfJlYBdxVeYF2091hsie69(MSB)mtoaVPj6A9BAHud0GMwIUElxuzWgMH3uaRMHLDteJvIDZKnSNiMlkFqcbDwgMTG1tqoYkxJvXGv0Hv0GvTbh4o1vel7vskgROhRqGoScry1OryfIXQUIyzVssXyvmyfTcbwHOB6weFtlKAGg00s01B5Ikd2Wm86djeO19(MSB)mtoaVPj6A9BgXqgGgOPLOMpCtbSAgw2nrmwj2nt2WEIyUO8bje0zzy2cwpb5iRCnwrdw9cw9brrteZfLpiHGoldZwW6jWaSIgScc6CQRiw2Rmeyf9yfTWkeDt3I4BgXqgGgOPLOMpC9HecH4EFt2TFMjhG30eDT(nnnWxnN1sOfYfkfl0Y3uaRMHLDtc)brrtqlKlukwOLLe(dIIMiBy)MUfX300aF1CwlHwixOuSqlF9Hec0DVVj72pZKdWBAIUw)MMg4RMZAj0c5cLIfA5BkGvZWYUzBWbUtazl3atbIgRIbROfcyfnyfhBbRGaMKiW6)ZLpilhGGLCt3I4BAAGVAoRLqlKlukwOLV(qcbk9EFt2TFMjhG30eDT(nnnWxnN1sOfYfkfl0Y3uaRMHLDZpikAIyUO8bje0zzy2cwpbgGv0Gve(dIIMGwixOuSqllj8hefnbgGv0GvVGvCSfSccysIaR)px(GSCacwYnDlIVPPb(Q5SwcTqUqPyHw(6djeOK37BYU9Zm5a8Mcy1mSSB(brrteZfLpiHGoldZwW6jWGBAIUw)MbBxRF9HecX(9(MSB)mtoaVPawndl7MVGvTLzVt)8UecSCayyID7NzcwnAew9cwj2nt2WE6N3LqGLdadtq2iJFtt0163KyUO8bje0zzy2cw)6djeOT37BYU9Zm5a8Mcy1mSSB(brrt)1zPgyXzss3MaaSI(hSIsEtt0163S3OVUxNV(qkuQU33KD7NzYb4nfWQzyz3SCXgv(GKyr2alPtJv0JvuDtt0163uy5S0eDTUmx6(M5s3s3I4BgvDnyDT(1hsHIW9(MSB)mtoaVPj6A9BkSCwAIUwxMlDFZCPBPBr8nzTMDbRV(qk0qV33KD7NzYb4nnrxRFtHLZst016YCP7BMlDlDlIVPUnNyqY1xFZail2OV137djeU33KD7NzYb41hsHEVVj72pZKdWRpKO19(MSB)mtoaV(qke37BYU9Zm5a86dj6U330eDT(nd2Uw)MSB)mtoaV(6BgvDnyDT(9(qcH79nz3(zMCaEtbSAgw2nbYwUbMcenwfdwrhvy1OryfIXQxWQb4cgGv0Gvazl3atbIgRIbROukfRq0nnrxRFZxTOGcwc5pVl56dPqV33KD7NzYb4nfWQzyz3SCXgv(GKyr2alPtJv0)GvuLOdRgdwbKTCdmfzuownAewHyS6fSAaUGbyfnyv5InQ8bjXISbwsNgRO)bROkfkDy1yWkGSLBGPiJYXkeDtt0163KWwduQBybaF9HeTU33KD7NzYb4nfWQzyz3uBVYYFExIudS4mbRObRkxSrLpijwKnWs60yf9yfvyfny1hefn9Z7sKAGfNjjWaSIgS6dIIM(5DjsnWIZKeKJSY1yvmyfcj6WQXGvdcYnnrxRFtcBnqPUHfa81hsH4EFt2TFMjhG3uaRMHLDtGSLBGParJvXGv0rfwrzyfIXQqPcRgdw9brrt)8UePgyXzscmaRq0nnrxRFZsW)f0js0f2vds4RV(M62CIbj37djeU33KD7NzYb4nfWQzyz3ec6LqgSHzyIWOLOASkMhScbQWkAWkeJvVGvTLzVt)1zDVWOe72pZeSA0iS6fSsSBMSH90FDw3lmkbzJmownAew9brrteZfLpiHGoldZwW6jWaScr30eDT(njS1aL6gwaWxFif69(MSB)mtoaVPawndl7MVGvFqu0eXCr5dsiOZYWSfSEcm4MMOR1V5pVlHalhagE9HeTU33KD7NzYb4nfWQzyz38dIIM(RZsnWIZKeKJSY1yvmyfcj6WQXGvdcsIPCwa2mwnAewHyS6dIIM(RZsnWIZKeKJSY1yvmpyfe05uxrSSxjTWQrJWQpikA6Vol1alotsqoYkxJvX8GvigRgeeSIcSsSBMSH90pVlHalhagMGSrghRgdw1wM9o9Z7siWYbGHj2TFMjy1yWQqXkeHvJgHvFqu00FDwQbwCMK0TjaaRIbROfwHiSIgScc6LqgSHzyIWOLOASI(hSkuQUPj6A9Bgzq4ggYo56dPqCVVj72pZKdWBkGvZWYU5ly1hefnrmxu(Gec6SmmBbRNadUPj6A9BcKnylzTMDbF9HeD37BYU9Zm5a8Mcy1mSSBkaAWbwlrHMOR1Tmwr)dwHqk2XkAWkeJvFqu0eqoA1TPlDs3MaaSkMhScXyfDyfLHv6aoNLTbh4wN(5DjY)wzScry1OryLoGZzzBWbU1PFExI8VvgROhRcfRq0nnrxRFZFExI8Vv(6djk9EFt2TFMjhG3uaRMHLDZpikA6Vol1alots62eaGvX8Gvukwrdw1wM9oTAnObhpXU9ZmbRObRGGEjKbBygMimAjQgRO)bRqGUBAIUw)MrgeUHHStU(qIsEVVj72pZKdWBkGvZWYUje0lHmydZqSI(hScbQOcRObREbR(GOOjI5IYhKqqNLHzly9eyWnnrxRFZ)6SUxy01hsX(9(MSB)mtoaVPawndl7MqqVeYGnmdtegTevJvX8GvigRqGoSIcS6dIIMiMlkFqcbDwgMTG1tGby1yWk6WkkWkDaNZY2GdCRtazd2sDdlaySAmyvBz27eq2G9hYgammXU9ZmbRgdwfkwHiSA0iSQRiw2RKumwfdwHav30eDT(njS1aL6gwaWxFirBV33KD7NzYb4nfWQzyz3uhW5SSn4a36eHTgO0CIKWcBCSI(hSIw30eDT(njS1aLMtKewyJF9HecuDVVj72pZKdWBkGvZWYUjIXkbqdoWAjk0eDTULXk6FWkesXownAew9brrteZfLpiHGoldZwW6jWaScryfnyfe05uxrSSxjTWk6FWQbb5MMOR1Vje0zPUHfa81hsiGW9(MSB)mtoaVPawndl7MFqu0eXCr5dsiOZYWSfSEcmaRgncRGGoN6kIL9kdbwfdwnii30eDT(nbYgSL6gwaWxFiHqO37BYU9Zm5a8Mcy1mSSB(brrteZfLpiHGoldZwW6jWGBAIUw)M)8Ue5FR81hsiqR79nz3(zMCaEtbSAgw2n)GOOjbSI0Rl1IfeoWjWaSA0iSQTm7DcAbfrsyXgfS6QR1tSB)mtWQrJWkDaNZY2GdCRte2AGsZjsclSXXk6FWQqVPj6A9BsyRbknNijSWg)6djecX9(MMOR1VPyDnyuqxRFt2TFMjhGxFiHaD37BAIUw)M)8Ue5FR8nz3(zMCaE9Hecu69(MSB)mtoaVPawndl7MqqNtDfXYEL0cRIbRgeeSA0iS6dIIM(RZsnWIZKKUnbayf9yfLEtt0163eiBWwQBybaF9HecuY79nz3(zMCaEt3I4BoaxFqldGvKLLqBGVPj6A9BoaxFqldGvKLLqBGV(qcHy)EFtt0163ec6Su3Wca(MSB)mtoaV(qcbA79(MSB)mtoaVPawndl7MqqVeYGnmdtegTevJv0JvHs1nnrxRFtdkmNL9cHS3xF9138vgQR1pKcLQqPIQqekD3mSb9Yh03K2mkyHntWk6Wkt016yvU0ToHJFZa4Iwz(MXcRamVlbRO9yRbIv0(EnaSXXJfwbS7anLiYipunqWFsSriRRiWS116cOH2iRRiboESWkANnowHqiOgRcLQqPchhhpwyfLaqZhynLioESWkkdRglcHjyfTRCcwrBaYCi5eoESWkkdRglcHjyfTR6AW6ADSkx6oHJhlSIYWQXIqycwfBM2RmwbyExcwnbwCMGvJ1xVWFSbR2GUwpHJhlSIYWQX(RSJvrlKXkByaYAD9kNhhRgyNHwZyfGRZy1eyXzcwPBtaGoHJJJhlSASt5SaSzcw9z0fYyLyJ(wJvFEOCDcRglHGdAnw5RtzanyekygRmrxRRXQ1ZJNWXnrxRRtbqwSrFRFqZMgaCCt0166uaKfB03AkEqgDxcoUj6ADDkaYIn6BnfpiBGdrS3wxRJJhlSA6wGg42yf0kcw9brrzcwPBR1y1NrxiJvIn6Bnw95HY1yL5eSkaYuwW2D5dyvPXkY6Cch3eDTUofazXg9TMIhK1UfObUTu3wRXXnrxRRtbqwSrFRP4b5GTR1XXXXJfwn2PCwa2mbR4xz44yvxrmw1azSYe9cXQsJv2RwLTFMt44MOR11prLtKOqMdjJJBIUwxtXdY)8UejkiCCQl0hXUzYg2teZfLpiHGoldZwW6jiBKXPbXVi2nt2WE6N3LqGLdadtq2iJpA0lTLzVt)8UecSCayyID7NzcIWXnrxRRP4b5pd1meGYhWXnrxRRP4bzdkmNLbGzntDH(yIUELLSZrfRP)j0rJGGohdc0ab9sid2Wmmry0sun9ukv44MOR11u8GCUga2A5yliziI9M6c95dIIMaDGBECPUHSp0atGb44MOR11u8GS5cw3qllfwoJJBIUwxtXdYOfK)5Dj44MOR11u8G83gKlQSHLaanoUj6ADnfpidQzz1CKM6c9rSBMSH9eXCr5dsiOZYWSfSEcYrw5A6PTuHJBIUwxtXdYGAwwnhrTBr8d0cjb0bql)1GeYe5hS71XXnrxRRP4bzqnlRMJO2Ti(rmUiVnC9si)zt3uxOpIDZKnSNiMlkFqcbDwgMTG1tqoYkxtZlFqu0eXCr5dsiOZYWSfSEcmGgiOZPUIyzVYqqVW0TSRigh3eDTUMIhKb1SSAoIA3I4hlKAGg00s01B5Ikd2WmK6c9bXIDZKnSNiMlkFqcbDwgMTG1tqoYkxhdD00gCG7uxrSSxjPy6rGoenAeI7kIL9kjfhdTcbIWXnrxRRP4bzqnlRMJO2Ti(jIHmanqtlrnFG6c9bXIDZKnSNiMlkFqcbDwgMTG1tqoYkxtZlFqu0eXCr5dsiOZYWSfSEcmGgiOZPUIyzVYqqpTqeoUj6ADnfpidQzz1Ce1UfXpMg4RMZAj0c5cLIfAzQl0hc)brrtqlKlukwOLLe(dIIMiByhh3eDTUMIhKb1SSAoIA3I4htd8vZzTeAHCHsXcTm1f6tBWbUtazl3atbIogAHanCSfSccysIaR)px(GSCacwcoUj6ADnfpidQzz1Ce1UfXpMg4RMZAj0c5cLIfAzQl0NpikAIyUO8bje0zzy2cwpbgqdH)GOOjOfYfkfl0Ysc)brrtGb08chBbRGaMKiW6)ZLpilhGGLGJBIUwxtXdYbBxRtDH(8brrteZfLpiHGoldZwW6jWaCCt016AkEqMyUO8bje0zzy2cwN6c95L2YS3PFExcbwoammXU9Zmz0Oxe7MjByp9Z7siWYbGHjiBKXXXnrxRRP4b5EJ(6EDM6c95dIIM(RZsnWIZKKUnba0)qjXXnrxRRP4bzHLZst016YCPBQDlIFIQUgSUwN6c9PCXgv(GKyr2alPttpv44MOR11u8GSWYzPj6ADzU0n1UfXpSwZUG144MOR11u8GSWYzPj6ADzU0n1UfXp62CIbj4444MOR11jwRzxW6hX6c2BO1mrIMTiM6c9HSDsSUG9gAntKOzlILFqONGCKvUoMqP5LpikAIyUO8bje0zzy2cwpbgGJBIUwxNyTMDbRP4bzZRitUOscBnqQl0NpikA6vlkOGLq(Z7ssGb0GyOvej)k7DYieDIP8s36rJGwrK8RS3jJq0PYPhb6qeoUj6ADDI1A2fSMIhKJ4OfoUCrLzqrrKeiBrAQl0hiOZPUIyzVseOFqqObc6LqgSHzymHGkCCt0166eR1SlynfpihEHzYRC5siRx3CbJJBIUwxNyTMDbRP4bzyfeKzz5sDGjyQl0Nx(GOOjI5IYhKqqNLHzly9eyaoooUj6ADDkQ6AW6A9NxTOGcwc5pVlH6c9biB5gykq0XqhvJgH4xgGlyanazl3atbIogkLsreoESWkAtxSrLpGvelYgyScYXwWcYrS3yvPXQqPBSbRwuSkYOCSciB5giwP38snwrhvJny1IIvrgLJvazl3aXQYXkdRgGlyqch3eDTUofvDnyDTofpityRbk1nSaGPUqFkxSrLpijwKnWs600)qvIUXaKTCdmfzu(Ori(Lb4cgqt5InQ8bjXISbwsNM(hQsHs3yaYwUbMImkhr44XcRO9wp20yvMBSYCSIP8s3LpGvaM3LGvtGfNjyfbUbjCCt0166uu11G116u8GmHTgOu3WcaM6c9rBVYYFExIudS4mHMYfBu5dsIfzdSKon9urZhefn9Z7sKAGfNjjWaA(GOOPFExIudS4mjb5iRCDmiKOBmdccoUj6ADDkQ6AW6ADkEqUe8FbDIeDHD1GeM6c9biB5gykq0XqhvugIdLQX8brrt)8UePgyXzscmar4444MOR11jDBoXGKhcBnqPUHfam1f6de0lHmydZWeHrlr1X8Gav0G4xAlZEN(RZ6EHrj2TFMjJg9Iy3mzd7P)6SUxyucYgz8rJ(GOOjI5IYhKqqNLHzly9eyaIWXnrxRRt62CIbju8G8pVlHalhagsDH(8Yhefnrmxu(Gec6SmmBbRNadWXnrxRRt62CIbju8GCKbHByi7eQl0NpikA6Vol1alotsqoYkxhdcj6gZGGKykNfGnpAeI)GOOP)6SudS4mjb5iRCDmpqqNtDfXYEL0A0OpikA6Vol1alotsqoYkxhZdIheeke7MjByp9Z7siWYbGHjiBKXhtBz270pVlHalhagMy3(zMmMqr0OrFqu00FDwQbwCMK0TjaigAHiAGGEjKbBygMimAjQM(NqPch3eDTUoPBZjgKqXdYazd2swRzxWuxOpV8brrteZfLpiHGoldZwW6jWaCCt0166KUnNyqcfpi)Z7sK)TYuxOpcGgCG1suOj6ADlt)dcPyNge)brrta5Ov3MU0jDBcaI5bX0rz6aoNLTbh4wN(5DjY)wzenAKoGZzzBWbU1PFExI8VvM(qreoUj6ADDs3MtmiHIhKJmiCddzNqDH(8brrt)1zPgyXzss3MaGyEOuAAlZENwTg0GJNy3(zMqde0lHmydZWeHrlr10)GaD44MOR11jDBoXGekEq(VoR7fgrDH(ab9sid2WmK(heOIkAE5dIIMiMlkFqcbDwgMTG1tGb44MOR11jDBoXGekEqMWwduQBybatDH(ab9sid2Wmmry0suDmpigb6O4dIIMiMlkFqcbDwgMTG1tGbJHok0bColBdoWTobKnyl1nSaGhtBz27eq2G9hYgammXU9ZmzmHIOrJ6kIL9kjfhdcuHJBIUwxN0T5edsO4bzcBnqP5ejHf24uxOp6aoNLTbh4wNiS1aLMtKewyJt)dTWXnrxRRt62CIbju8Gme0zPUHfam1f6dIfan4aRLOqt016wM(hesX(OrFqu0eXCr5dsiOZYWSfSEcmar0abDo1vel7vsl6FgeeCCt0166KUnNyqcfpidKnyl1nSaGPUqF(GOOjI5IYhKqqNLHzly9eyWOrqqNtDfXYELHiMbbbh3eDTUoPBZjgKqXdY)8Ue5FRm1f6Zhefnrmxu(Gec6SmmBbRNadWXnrxRRt62CIbju8GmHTgO0CIKWcBCQl0NpikAsaRi96sTybHdCcmy0O2YS3jOfuejHfBuWQRUwpXU9Zmz0iDaNZY2GdCRte2AGsZjsclSXP)juCCt0166KUnNyqcfpilwxdgf01644MOR11jDBoXGekEq(N3Li)BLXXnrxRRt62CIbju8Gmq2GTu3WcaM6c9bc6CQRiw2RKwXmiiJg9brrt)1zPgyXzss3Maa6PuCCt0166KUnNyqcfpidQzz1Ce1UfXpdW1h0Yayfzzj0gyCCt0166KUnNyqcfpidbDwQBybaJJBIUwxN0T5edsO4bzdkmNL9cHS3uxOpqqVeYGnmdtegTevtFOuDtdSbUWBoRikbSIcSI2idqLRRV(oa]] )

end