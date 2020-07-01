-- DemonHunterHavoc.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DEMONHUNTER' then
    local spec = Hekili:NewSpecialization( 577 )

    spec:RegisterResource( Enum.PowerType.Fury, {
        prepared = {
            talent = "momentum",
            aura   = "prepared",

            last = function ()
                local app = state.buff.prepared.applied
                local t = state.query_time

                local step = 0.1

                return app + floor( t - app )
            end,

            interval = 1,
            value = 8
        },

        immolation_aura = {
            talent  = "immolation_aura",
            aura    = "immolation_aura",

            last = function ()
                local app = state.buff.immolation_aura.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 7
        },

        blind_fury = {
            talent = "blind_fury",
            aura = "eye_beam",

            last = function ()
                local app = state.buff.eye_beam.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 40,
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        blind_fury = 21854, -- 203550
        demonic_appetite = 22493, -- 206478
        felblade = 22416, -- 232893

        insatiable_hunger = 21857, -- 258876
        demon_blades = 22765, -- 203555
        immolation_aura = 22799, -- 258920

        trail_of_ruin = 22909, -- 258881
        fel_mastery = 22494, -- 192939
        fel_barrage = 21862, -- 258925

        soul_rending = 21863, -- 204909
        desperate_instincts = 21864, -- 205411
        netherwalk = 21865, -- 196555

        cycle_of_hatred = 21866, -- 258887
        first_blood = 21867, -- 206416
        dark_slash = 21868, -- 258860

        unleashed_power = 21869, -- 206477
        master_of_the_glaive = 21870, -- 203556
        fel_eruption = 22767, -- 211881

        demonic = 21900, -- 213410
        momentum = 21901, -- 206476
        nemesis = 22547, -- 206491
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3426, -- 208683
        relentless = 3427, -- 196029
        adaptation = 3428, -- 214027

        cover_of_darkness = 1206, -- 227635
        demonic_origins = 810, -- 235893
        detainment = 812, -- 205596
        eye_of_leotheras = 807, -- 206649
        glimpse = 1204, -- 203468
        mana_break = 813, -- 203704
        mana_rift = 809, -- 235903
        rain_from_above = 811, -- 206803
        reverse_magic = 806, -- 205604
        solitude = 805, -- 211509
        unending_hatred = 1218, -- 213480
    } )


    -- Auras
    spec:RegisterAuras( {
        blade_dance = {
            id = 188499,
            duration = 1,
            max_stack = 1,
        },
        blur = {
            id = 212800,
            duration = 10,
            max_stack = 1,
        },
        chaos_brand = {
            id = 1490,
            duration = 60,
            max_stack = 1,
        },
        chaos_nova = {
            id = 179057,
            duration = 2,
            type = "Magic",
            max_stack = 1,
        },
        dark_slash = {
            id = 258860,
            duration = 8,
            max_stack = 1,
        },
        darkness = {
            id = 196718,
            duration = 7.917,
            max_stack = 1,
        },
        death_sweep = {
            id = 210152,
        },
        demon_blades = {
            id = 203555,
        },
        demonic_wards = {
            id = 278386,
        },
        double_jump = {
            id = 196055,
        },
        eye_beam = {
            id = 198013,
        },
        fel_barrage = {
            id = 258925,
        },
        fel_eruption = {
            id = 211881,
            duration = 4,
            max_stack = 1,
        },
        glide = {
            id = 131347,
            duration = 3600,
            max_stack = 1,
        },
        immolation_aura = {
            id = 258920,
            duration = 10,
            max_stack = 1,
        },
        master_of_the_glaive = {
            id = 213405,
            duration = 6,
            max_stack = 1,
        },
        metamorphosis = {
            id = 162264,
            duration = function () return pvptalent.demonic_origins.enabled and 15 or 30 end,
            max_stack = 1,
            meta = {
                extended_by_demonic = function ()
                    return false -- disabled in 8.0:  talent.demonic.enabled and ( buff.metamorphosis.up and buff.metamorphosis.duration % 15 > 0 and buff.metamorphosis.duration > ( action.eye_beam.cast + 8 ) )
                end,
            },
        },
        momentum = {
            id = 208628,
            duration = 6,
            max_stack = 1,
        },
        nemesis = {
            id = 206491,
            duration = 60,
            max_stack = 1,
        },
        netherwalk = {
            id = 196555,
            duration = 5,
            max_stack = 1,
        },
        prepared = {
            id = 203650,
            duration = 10,
            max_stack = 1,
        },
        shattered_souls = {
            id = 178940,
        },
        spectral_sight = {
            id = 188501,
            duration = 10,
            max_stack = 1,
        },
        torment = {
            id = 281854,
            duration = 3,
            max_stack = 1,
        },
        trail_of_ruin = {
            id = 258883,
            duration = 4,
            max_stack = 1,
        },
        vengeful_retreat = {
            id = 198793,
            duration = 3,
            max_stack = 1,
        },

        -- PvP Talents
        eye_of_leotheras = {
            id = 206649,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },

        mana_break = {
            id = 203704,
            duration = 10,
            max_stack = 1,
        },

        rain_from_above_launch = {
            id = 206803,
            duration = 1,
            max_stack = 1,
        },

        rain_from_above = {
            id = 206804,
            duration = 10,
            max_stack = 1,
        },

        solitude = {
            id = 211510,
            duration = 3600,
            max_stack = 1
        },

        -- Azerite
        thirsting_blades = {
            id = 278736,
            duration = 30,
            max_stack = 40,
            meta = {
                stack = function ( t )
                    if t.down then return 0 end
                    local appliedBuffer = ( now - t.applied ) % 1
                    return min( 40, t.count + floor( offset + delay + appliedBuffer ) )
                end,
            }
        }
    } )


    local last_darkness = 0
    local last_metamorphosis = 0
    local last_eye_beam = 0

    spec:RegisterStateExpr( "darkness_applied", function ()
        return max( class.abilities.darkness.lastCast, last_darkness )
    end )

    spec:RegisterStateExpr( "metamorphosis_applied", function ()
        return max( class.abilities.darkness.lastCast, last_metamorphosis )
    end )

    spec:RegisterStateExpr( "eye_beam_applied", function ()
        return max( class.abilities.eye_beam.lastCast, last_eye_beam )
    end )

    spec:RegisterStateExpr( "extended_by_demonic", function ()
        return buff.metamorphosis.up and buff.metamorphosis.extended_by_demonic
    end )


    spec:RegisterStateExpr( "meta_cd_multiplier", function ()
        return 1
    end )

    spec:RegisterHook( "reset_precast", function ()
        last_darkness = 0
        last_metamorphosis = 0
        last_eye_beam = 0

        local rps = 0

        if equipped.convergence_of_fates then
            rps = rps + ( 3 / ( 60 / 4.35 ) )
        end

        if equipped.delusions_of_grandeur then
            -- From SimC model, 1/13/2018.
            local fps = 10.2 + ( talent.demonic.enabled and 1.2 or 0 ) + ( ( level < 116 and equipped.anger_of_the_halfgiants ) and 1.8 or 0 )

            if level < 116 and set_bonus.tier19_2pc > 0 then fps = fps * 1.1 end

            -- SimC uses base haste, we'll use current since we recalc each time.
            fps = fps / haste

            -- Chaos Strike accounts for most Fury expenditure.
            fps = fps + ( ( fps * 0.9 ) * 0.5 * ( 40 / 100 ) )

            rps = rps + ( fps / 30 ) * ( 1 )
        end

        meta_cd_multiplier = 1 / ( 1 + rps )
    end )


    spec:RegisterHook( "spend", function( amt, resource )
        if level < 116 and equipped.delusions_of_grandeur and resource == 'fury' then
            -- revisit this if really needed... 
            cooldown.metamorphosis.expires = cooldown.metamorphosis.expires - ( amt / 30 )
        end
    end )

    spec:RegisterCycle( function ()
        if active_enemies == 1 then return end

        -- For Nemesis, we want to cast it on the lowest health enemy.
        if this_action == "nemesis" and Hekili:GetNumTTDsWithin( target.time_to_die ) > 1 then return "cycle" end
    end )


    -- Gear Sets
    spec:RegisterGear( 'tier19', 138375, 138376, 138377, 138378, 138379, 138380 )
    spec:RegisterGear( 'tier20', 147130, 147132, 147128, 147127, 147129, 147131 )
    spec:RegisterGear( 'tier21', 152121, 152123, 152119, 152118, 152120, 152122 )
        spec:RegisterAura( 'havoc_t21_4pc', {
            id = 252165,
            duration = 8 
        } )

    spec:RegisterGear( 'class', 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722 )

    spec:RegisterGear( 'convergence_of_fates', 140806 )

    spec:RegisterGear( 'achor_the_eternal_hunger', 137014 )
    spec:RegisterGear( 'anger_of_the_halfgiants', 137038 )
    spec:RegisterGear( 'cinidaria_the_symbiote', 133976 )
    spec:RegisterGear( 'delusions_of_grandeur', 144279 )
    spec:RegisterGear( 'kiljaedens_burning_wish', 144259 )
    spec:RegisterGear( 'loramus_thalipedes_sacrifice', 137022 )
    spec:RegisterGear( 'moarg_bionic_stabilizers', 137090 )
    spec:RegisterGear( 'prydaz_xavarics_magnum_opus', 132444 )
    spec:RegisterGear( 'raddons_cascading_eyes', 137061 )
    spec:RegisterGear( 'sephuzs_secret', 132452 )
    spec:RegisterGear( 'the_sentinels_eternal_refuge', 146669 )

    spec:RegisterGear( "soul_of_the_slayer", 151639 )
    spec:RegisterGear( "chaos_theory", 151798 )
    spec:RegisterGear( "oblivions_embrace", 151799 )



    -- Abilities
    spec:RegisterAbilities( {
        annihilation = {
            id = 201427,
            known = 162794,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 40 - buff.thirsting_blades.stack end,
            spendType = "fury",

            startsCombat = true,
            texture = 1303275,

            bind = "chaos_strike",
            buff = "metamorphosis",

            handler = function ()
                removeBuff( "thirsting_blades" )
                if azerite.thirsting_blades.enabled then applyBuff( "thirsting_blades", nil, 0 ) end
            end,
        },


        blade_dance = {
            id = 188499,
            cast = 0,
            cooldown = 9,
            hasteCD = true,
            gcd = "spell",

            spend = function () return 35 - ( talent.first_blood.enabled and 20 or 0 ) end,
            spendType = "fury",

            startsCombat = true,
            texture = 1305149,

            bind = "death_sweep",
            nobuff = "metamorphosis",

            handler = function ()
                applyBuff( "blade_dance" )
                setCooldown( "death_sweep", 9 * haste )
                if level < 116 and set_bonus.tier20_2pc == 1 and target.within8 then gain( buff.solitude.up and 22 or 20, 'fury' ) end
            end,
        },


        blur = {
            id = 198589,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            toggle = "defensives",

            startsCombat = false,
            texture = 1305150,

            handler = function ()
                applyBuff( "blur" )
            end,
        },


        chaos_nova = {
            id = 179057,
            cast = 0,
            cooldown = function () return talent.unleashed_power.enabled and 40 or 60 end,
            gcd = "spell",

            spend = function () return talent.unleashed_power.enabled and 0 or 30 end,
            spendType = "fury",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 135795,

            handler = function ()
                applyDebuff( "target", "chaos_nova" )
            end,
        },


        chaos_strike = {
            id = 162794,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return 40 - buff.thirsting_blades.stack end,
            spendType = "fury",

            startsCombat = true,
            texture = 1305152,

            bind = "annihilation",
            nobuff = "metamorphosis",

            handler = function ()
                removeBuff( "thirsting_blades" )
                if azerite.thirsting_blades.enabled then applyBuff( "thirsting_blades", nil, 0 ) end
            end,
        },


        consume_magic = {
            id = 278326,
            cast = 0,
            cooldown = 10,
            gcd = "off",

            startsCombat = true,
            texture = 828455,

            usable = function () return buff.dispellable_magic.up end,
            handler = function ()
                removeBuff( "dispellable_magic" )
                gain( buff.solitude.up and 22 or 20, "fury" )
            end,
        },


        dark_slash = {
            id = 258860,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 136189,

            talent = "dark_slash",

            handler = function ()
                applyDebuff( "target", "dark_slash" )
            end,
        },


        darkness = {
            id = 196718,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = true,
            texture = 1305154,

            handler = function ()
                last_darkness = query_time
                applyBuff( "darkness" )
            end,
        },


        death_sweep = {
            id = 210152,
            known = 188499,
            cast = 0,
            cooldown = 9,
            hasteCD = true,
            gcd = "spell",

            spend = function () return 35 - ( talent.first_blood.enabled and 20 or 0 ) end,
            spendType = "fury",

            startsCombat = true,
            texture = 1309099,

            bind = "blade_dance",
            buff = "metamorphosis",

            handler = function ()
                applyBuff( "death_sweep" )
                setCooldown( "blade_dance", 9 * haste )
                if level < 116 and set_bonus.tier20_2pc == 1 and target.within8 then gain( buff.solitude.up and 22 or 20, "fury" ) end
            end,
        },


        demons_bite = {
            id = 162243,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.solitude.up and -22 or -20 end,
            spendType = "fury",

            startsCombat = true,
            texture = 135561,

            notalent = "demon_blades",

            handler = function ()
                if level < 116 and equipped.anger_of_the_halfgiants then gain( 1, "fury" ) end
            end,
        },


        disrupt = {
            id = 183752,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 1305153,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
                gain( buff.solitude.up and 33 or 30, "fury" )
            end,
        },


        eye_beam = {
            id = 198013,
            cast = function () return 2 + ( talent.blind_fury.enabled and 1 or 0 ) end,
            cooldown = function ()
                if level < 116 and equipped.raddons_cascading_eyes then return 30 - active_enemies end
                return 30
            end,
            channeled = true,
            gcd = "spell",

            spend = 30,
            spendType = "fury",

            startsCombat = true,
            texture = 1305156,

            start = function ()
                -- not sure if we need to model blind_fury gains.
                -- if talent.blind_fury.enabled then gain( 120, "fury" ) end

                last_eye_beam = query_time

                if talent.demonic.enabled then
                    if buff.metamorphosis.up then
                        buff.metamorphosis.duration = buff.metamorphosis.remains + 8
                        buff.metamorphosis.expires = buff.metamorphosis.expires + 8
                    else
                        applyBuff( "metamorphosis", action.eye_beam.cast + 8 )
                        buff.metamorphosis.duration = action.eye_beam.cast + 8
                        stat.haste = stat.haste + 25
                    end
                end
            end,
        },


        eye_of_leotheras = {
            id = 206649,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            pvptalent = "eye_of_leotheras",

            startsCombat = true,
            texture = 1380366,

            handler = function ()
                applyDebuff( "target", "eye_of_leotheras" )
            end,
        },


        fel_barrage = {
            id = 258925,
            cast = 2,
            cooldown = 60,
            channeled = true,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 2065580,

            talent = "fel_barrage",

            start = function ()
                applyBuff( "fel_barrage", 2 )
            end,
        },


        fel_eruption = {
            id = 211881,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            spend = 10,
            spendType = "fury",

            startsCombat = true,
            texture = 1118739,

            talent = "fel_eruption",

            handler = function ()
                applyDebuff( "target", "fel_eruption" )
            end,
        },


        fel_rush = {
            id = 195072,
            cast = 0,
            charges = 2,
            cooldown = 10,
            recharge = 10,
            gcd = "spell",

            startsCombat = true,
            texture = 1247261,

            usable = function ()
                if settings.recommend_movement ~= true then return false, "fel_rush movement is disabled" end
                return not prev_gcd[1].fel_rush
            end,            
            handler = function ()
                if talent.momentum.enabled then applyBuff( "momentum" ) end
                if cooldown.vengeful_retreat.remains < 1 then setCooldown( 'vengeful_retreat', 1 ) end
                setDistance( 5 )
                setCooldown( "global_cooldown", 0.25 )
            end,
        },


        felblade = {
            id = 232893,
            cast = 0,
            cooldown = 15,
            hasteCD = true,
            gcd = "spell",

            spend = function () return buff.solitude.up and -44 or -40 end,
            spendType = "fury",

            startsCombat = true,
            texture = 1344646,

            -- usable = function () return target.within15 end,        
            handler = function ()
                setDistance( 5 )
            end,
        },


        fel_lance = {
            id = 206966,
            cast = 1,
            cooldown = 0,
            gcd = "spell",

            pvptalent = "rain_from_above",
            buff = "rain_from_above",

            startsCombat = true,
        },


        --[[ glide = {
            id = 131347,
            cast = 0,
            cooldown = 1.5,
            gcd = "spell",

            startsCombat = true,
            texture = 1305157,

            handler = function ()
            end,
        }, ]]


        immolation_aura = {
            id = 258920,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 1344649,

            talent = "immolation_aura",

            handler = function ()
                applyBuff( "immolation_aura" )
                gain( buff.solitude.up and 11 or 10, "fury" )
            end,
        },


        imprison = {
            id = 217832,
            cast = 0,
            cooldown = function () return pvptalent.detainment.enabled and 60 or 45 end,
            gcd = "spell",

            startsCombat = false,
            texture = 1380368,

            handler = function ()
                applyDebuff( "target", "imprison" )
            end,
        },


        mana_break = {
            id = 203704,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 50,
            spendType = "fury",

            pvptalent = "mana_break",

            startsCombat = true,
            texture = 1380369,

            handler = function ()
                applyDebuff( "target", "mana_break" )
            end,
        },


        mana_rift = {
            id = 235903,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            spend = 50,
            spendType = "fury",

            pvptalent = "mana_rift",

            startsCombat = true,
            texture = 1033912,

            handler = function ()
            end,
        },


        metamorphosis = {
            id = 191427,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( pvptalent.demonic_origins.up and 120 or 240 ) end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 1247262,

            handler = function ()
                applyBuff( "metamorphosis" )
                last_metamorphosis = query_time
                stat.haste = stat.haste + 25
                setDistance( 5 )

                if azerite.chaotic_transformation.enabled then
                    setCooldown( "eye_beam", 0 )
                    setCooldown( "blade_dance", 0 )
                    setCooldown( "death_sweep", 0 )
                end
            end,

            meta = {
                adjusted_remains = function ()
                    if level < 116 and ( equipped.delusions_of_grandeur or equipped.convergeance_of_fates ) then
                        return cooldown.metamorphosis.remains * meta_cd_multiplier
                    end

                    return cooldown.metamorphosis.remains
                end
            }
        },


        nemesis = {
            id = 206491,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 236299,

            talent = "nemesis",

            handler = function ()
                applyDebuff( "target", "nemesis" )
            end,
        },


        netherwalk = {
            id = 196555,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = true,
            texture = 463284,

            talent = "netherwalk",

            handler = function ()
                applyBuff( "netherwalk" )
                setCooldown( "global_cooldown", 5 )
            end,
        },


        rain_from_above = {
            id = 206803,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            pvptalent = "rain_from_above",

            startsCombat = false,
            texture = 1380371,

            handler = function ()
                applyBuff( "rain_from_above" )
            end,
        },


        reverse_magic = {
            id = 205604,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            -- toggle = "cooldowns",
            pvptalent = "reverse_magic",

            startsCombat = false,
            texture = 1380372,

            handler = function ()
                if debuff.reversible_magic.up then removeDebuff( "player", "reversible_magic" ) end
            end,
        },


        --[[ spectral_sight = {
            id = 188501,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 1247266,

            handler = function ()
                -- applies spectral_sight (188501)
            end,
        }, ]]


        throw_glaive = {
            id = 185123,
            cast = 0,
            charges = function () return talent.master_of_the_glaive.enabled and 2 or nil end,
            cooldown = 9,
            recharge = 9,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 1305159,

            handler = function ()
                if talent.master_of_the_glaive.enabled then applyDebuff( "target", "master_of_the_glaive" ) end
            end,
        },


        torment = {
            id = 281854,
            cast = 0,
            cooldown = 8,
            gcd = "off",

            startsCombat = true,
            texture = 1344654,

            handler = function ()
                applyDebuff( "target", "torment" )
            end,
        },


        vengeful_retreat = {
            id = 198793,
            cast = 0,
            cooldown = function () return talent.momentum.enabled and 20 or 25 end,
            gcd = "spell",

            startsCombat = true,
            texture = 1348401,

            usable = function ()
                if settings.recommend_movement ~= true then return false, "vengeful_retreat movement is disabled" end
                return true
            end,

            handler = function ()
                if target.within8 then
                    applyDebuff( "target", "vengeful_retreat" )
                    if talent.momentum.enabled then applyBuff( "prepared" ) end
                end

                if pvptalent.glimpse.enabled then applyBuff( "blur", 3 ) end
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 2,

        nameplates = true,
        nameplateRange = 7,

        damage = true,
        damageExpiration = 8,

        potion = "potion_of_unbridled_fury",

        package = "Havoc",
    } )


    spec:RegisterSetting( "recommend_movement", false, {
        name = "Recommend Movement",
        desc = "If checked, the addon will recommend |T1247261:0|t Fel Rush / |T1348401:0|t Vengeful Retreat when it is a potential DPS gain.\n\n" ..
            "These abilities are critical for DPS when using the Momentum talent.\n\n" ..
            "If not using Momentum, you may want to leave this disabled to avoid unnecessary movement in combat.",
        type = "toggle",
        width = "full"
    } )


    spec:RegisterPack( "Havoc", 20200410, [[dOeKnbqisHfPqu9ifcBcegfvOtrfzvkeLxrL0SiLClerTlk9lsPggI0XifTmquptHKPHi4AujABub8neHACubY5OcuRtHu17OcQY8Os4EiQ9bHoivqzHur9qfIyIubvUiIiYgviv(iIiQrIicNuHi1kvOUjIqStsvTuer6PGAQKQCveH0xPcQQXQqKyVO6VcgmshMyXk6Xu1Kj5YQ2mK(mcgnPYPL8AqKzJYTfA3I(TsdhHoUcrslhQNtX0L66ky7G03PsnEfs58qW6PcY8HO9dmxtUECyL0NRpKjfYKskjOjPwsDWKGdqcKyoCJaXZHjkEijeohoL45WKec01ZHjkiWwrX1JdB2bS)CyDDt0m61wBcvRByA9BuBtfhysxB6XcARTPIET5WZHI1J0jFYHvsFU(qMuitkPKGMKAj1btcoWOCWCydX7567ssmjMdRRuQN8jhwDJNdpcaLKqGUEa1H7XnbusIHSpgmEeaQUUjAg9ARnHQ1nmT(nQTPIdmPRn9ybT12urV2GXJaqDyeXfdq1KuTauitkKjfmgmEeaQdFbNvsWm6bJhbGsYakjQPscaQd3JBcOoZe1naAuG0naACnnGo6gWiaOeEES01MakXb8ziaOKu9jjdOkCb9jGkPcqhsI4RkFlt21cqDRR86au3fJbOvKO4BaT1DaDK6GWQgbaDrbu89Bm(ujDTPXcgpcaLKbusutLeausKn(ShIaAza0CBafF)gJpvx5WdqhDNbOK0bJoa1DXya68ak((ngFQUcqLubOTUdOgb9nca6IcOJUZaus6GrhG6Lm3gqNhqvVVVVcqNiaOIsTPXcgdgpcaDKOtsc3m6bJhbGsYaQdtPUcqhjBAgIhqjrecL3cgpcaLKbus6Jl0Ra0wWeEhkua1R7EibOOlgq1)XBkdGkZIvncwW4raOKmGssFCHEfGgxOp(SbuzwSQRBauu8gbuI4AXvJaG6w3tan3gqhmxbOOlgqjr24ZEiAbJhbGsYaQdtPUcqjrnhqhP7hnaAVa6tfGUOa6izxMADNgav8DTjRmTfmEeakjdOJKnHECFfGoY97YuR7CKdO9cOJCX31M2rkw)Um16oh5aQBDhFavisKvEzYULdZktB46XHZfhfgxpU(AY1Jd)uMSR4oZH94QpUeoClSNTnUXN9q0(uMSRauia05akQLi(ef8vw16obuia0UIhqreq1Kdl(U2Kdd9jHJoWc434lnV56dzUEC4NYKDf3zoShx9XLWHDeqHk4sMSBDlvxjHa6IdXn(ShIaksKaAlSNTf9Squm9XiyFkt2vaQtakeaQJaQxNGjCdGsgqHmGIejG6iGILsfo0NTnUqF8zBReqreq1KuafcaflLkCOpBROugBLakIaQMKcOobOoXHfFxBYHrplGhm64nx)rX1Jd)uMSR4oZH94QpUeoSgakubxYKDRBP6kjeqxCiUXN9qeqHaqDeqfFxqF45J1nakIaQ6McFvOfmH3gafjsaflLkCOpBROugBLakIa6OifqDIdl(U2KdJEwykySq48MRpjW1Jd)uMSR4oZH94QpUeomubxYKD7KjQhus6phw8DTjhwDP1fmU)jYBU(UKRhhw8DTjhUIXLjDTzqgWch(PmzxXDM3C9DaUEC4NYKDf3zoShx9XLWHfFxqF45J1nakIaQMakeaQJaQgakwkv4qF2wrPm2pALPnaksKakwkv4qF2wrPm2bIaQtakeaQgakubxYKDRBP6kjeqxCiUXN9qKdl(U2KdFeEyEjYBU(KyUEC4NYKDf3zoShx9XLWHHk4sMSBNmr9Gss)5WIVRn5WtMOEqjP)8MRVdIRhh(PmzxXDMd7XvFCjCy0bmcw1rlF1akIKbusGuoS47Atom6ztMOoV567G56XHFkt2vCN5WEC1hxchwdaTf2Z2ozvQcOdyeSpLj7kafcavdafQGlzYU1TuDLecOloOemKcgMy0bOqaOyPuHd9zBfLYyReqreqfFxBApcpmVeT(DzQ1DYHfFxBYHpcpmVe5nxFnjLRhh(PmzxXDMd7XvFCjCyhb0wypBR6XndtMOUX(uMSRauKibunauOcUKj7w3s1vsiGU4qCJp7HiGIejGIoGrWQoA5RgqDbGoksbuKib05akQn(wIlMOU1ugl(rPsdG6ca1LaQtakeaQgakubxYKDlXDzvsiGU4WKjQhus6pGcbGQbGcvWLmz36wQUscb0fhucgsbdtm64WIVRn5WsMLUIjDTjV56RPMC94WpLj7kUZCypU6JlHd7iG2c7zBvpUzyYe1n2NYKDfGIejGQbGcvWLmz36wQUscb0fhIB8zpebuKibu0bmcw1rlF1aQla0rrkG6eGcbGQbGcvWLmz3sCxwLecOloeFlakeaQgakubxYKDlXDzvsiGU4WKjQhus6pGcbGQbGcvWLmz36wQUscb0fhucgsbdtm64WIVRn5WEDYAcMgxq68MRVMqMRhh(PmzxXDMd7XvFCjC4wypB7KvPkGoGrW(uMSRauiauSuQWH(STIszSvcOicOIVRnThHhMxIw)Um16o5WIVRn5WhHhMxI8MRVMJIRhhw8DTjhw94MMWS6ZHFkt2vCN5nxFnjbUEC4NYKDf3zoShx9XLWH1aqBH9STXn(ShI2NYKDfGcbGILsfo0NTnUqF8zBReqreq96emHBa0rgGQjPakeaAlSNTv94MHjtu3yFkt2vCyX31MCy0Zc4bJoEZ1xtxY1Jd)uMSR4oZH94QpUeoCCH(4Z2QktlP)akIaQMUeqrIeqNdOO2DOdlAaljHBhiYHfFxBYHrpBYe15nxFnDaUEC4NYKDf3zoShx9XLWHJl0hF2wvzAj9hqreq10LaksKaQJa6Caf1UdDyrdyjjC7arafcavdaTf2Z2g34ZEiAFkt2vaQtCyX31MCy0Zc4bJoEZ1xtsmxpo8tzYUI7mh2JR(4s4WXf6JpBRQmTK(dOicOA6soS47Atom0Neo6alGFJV08MRVMoiUEC4NYKDf3zoShx9XLWHBH9STQh3mmzI6g7tzYUIdl(U2Kd36WR7abMuqpV5nh(gZt)nC946Rjxpo8tzYUI7mhEjYHnV5WIVRn5WqfCjt25Wqf2W5W(DzQ1DArplmfmwiCl(Icbafca1ra1ra1ravdaTf2Z2QECZYBFkt2vaksKa6Caf1gFlXftu3AkJDGiG6eGcbGQbGcvWLmz36wQUscb0fhIB8zpebuiauSuQWH(STIszSvcOicOJIua1jafjsav8Db9HNpw3aOicOQBk8vHwWeEBauN4WEC1hxchUf2Z2IEwykySq42NYKDfhgQGdPephg9SWuWyHWdgespV56dzUEC4NYKDf3zoShx9XLWHDeq1aqvBB9B6F2yPVkGYK4dZbCA7YdPkjaOqaOAaOIVRnT(n9pBS0xfqzs82kdOSIGUgqrIeqrhySa(EDcMWdDfpG6caLGxzJYObOoXHfFxBYH9B6F2yPVkGYK45nx)rX1Jd)uMSR4oZH94QpUeoSJaQgaAlSNTf9SWuWyHWTpLj7kafjsa1VltTUtl6zHPGXcHBXpkvAauebusWLaQtakeaQgakubxYKDRBP6kjeqxCiUXN9qeqHaqDeqDeq1aqBH9STQh3S82NYKDfGIejGohqrTX3sCXe1TMYyhicOqaOAaO(DzQ1DANmr9Gss)T4lkeauNauKib0UIp0BqvhqDbzavtsbuN4WIVRn5Wt2UQWIgADp88re4nxFsGRhh(PmzxXDMd7XvFCjC4wypBl6zHPGXcHBFkt2vakeakubxYKDl6zHPGXcHhmiKEoS47Ato8KTRkSOHw3dpFebEZ13LC94WpLj7kUZCypU6JlHdBiEgl0cMWBJDYe1dkj9xtafrYakKbuKibuSuQWH(STIszSvcOicOoaPCyX31MCy01pyUkio0Xv)W8sK3C9DaUEC4NYKDf3zoShx9XLWHnepJfAbt4TXozI6bLK(RjGIizafYaksKakwkv4qF2wrPm2kbuebuhGuoS47AtomXbCHIqLectMyAEZ1NeZ1Jd)uMSR4oZH94QpUeo8Caf1IVhsSBmb0f7VDGiGIejGohqrT47He7gtaDX(h87q2hBnT4HeG6cavts5WIVRn5WTUhgY5oKQa6I9N3C9DqC94WIVRn5W4Iir2dvgmef)5WpLj7kUZ8MRVdMRhh(PmzxXDMd7XvFCjC45akQn(wIlMOU1ug7arafjsafQGlzYUf9SWuWyHWdgesphw8DTjh29IzkOVYa(MnL0FEZ1xts56XHFkt2vCN5WEC1hxchgDaJaG6caLeifqHaqNdOO24BjUyI6wtzSde5WIVRn5WXhxmcHfnWg8LkOWxIgEZ1xtn56XHFkt2vCN5WIVRn5W4leRKqaLjXB4WEC1hxchUfmH32UIp0BqvhqDbGQP1LaksKaQJaQJaAlycVT6UWADwI(gqreqDqKcOircOTGj82Q7cR1zj6Ba1fKbuitkG6eGcbG6iGk(UG(WZhRBauYaQMaksKaAlycVTDfFO3GQoGIiGczhmG6eG6eGIejG6iG2cMWBBxXh6nq03bitkGIiGoksbuiauhbuX3f0hE(yDdGsgq1eqrIeqBbt4TTR4d9gu1buebusGeauNauN4WEe8ShAbt4THRVM8M3Cy1rLbwZ1JRVMC94WpLj7kUZC4Lih28Mdl(U2KddvWLmzNddvydNd3c7zBrlSPdt2Uk7tzYUcqrIeqnepJfAbt4TXozI6bLK(RjGIiza1raDuakjdOTWE22glflSOb8qL2NYKDfG6ehgQGdPephEYe1dkj9N3C9Hmxpo8tzYUI7mhEjYHnV5WIVRn5WqfCjt25Wqf2W5WAaOocOAaOTWE228XBkJ9PmzxbOircO(DzQ1DAZhVPmw8ffcaksKaQFxMADN28XBkJf)OuPbqreqBbt4TTR4d9gu1buKibu)Um16oT5J3ugl(rPsdGIiG6aKcOoXHHk4qkXZHDlvxjHa6Id5J3ugEZ1FuC94WpLj7kUZC4Lih28Mdl(U2KddvWLmzNddvydNdRbG2c7zBvpUz5TpLj7kafca1VltTUtB8TexmrDRPmw8JsLga1faQdaOqaOOdyeSQJw(Qbueb0rrkGcbG6iGQbGcvWLmz36wQUscb0fhYhVPmaksKaQFxMADN28XBkJf)OuPbqDbGQjPaQtCyOcoKs8CyI7YQKqaDXH4BH3C9jbUEC4NYKDf3zo8sKdBEZHfFxBYHHk4sMSZHHkSHZHHk4sMSBNmr9Gss)buiauhbu0bmcaQlausSlbusgqBH9STOf20HjBxL9PmzxbOJmafYKcOoXHHk4qkXZHjUlRscb0fhMmr9Gss)5nxFxY1Jd)uMSR4oZHxICyZBoS47AtomubxYKDomuHnCoClSNTv94ML3(uMSRauiauna0wypB7KvPkGoGrW(uMSRauiau)Um16oThHhMxIw8JsLga1faQJakbVYgLrdqhzakKbuNauiau0bmcw1rlF1akIakKjLddvWHuINdtCxwLecOloCeEyEjYBU(oaxpo8tzYUI7mhEjYHnV5WIVRn5WqfCjt25Wqf2W5WTWE2wLGHuWWeJo7tzYUcqHaq1aqHk4sMSBjUlRscb0fhMmr9Gss)buiaunauOcUKj7wI7YQKqaDXH4BbqHaq97YuR70QemKcgMy0zhiYHHk4qkXZHDlvxjHa6IdkbdPGHjgD8MRpjMRhh(PmzxXDMdVe5WM3CyX31MCyOcUKj7CyOcB4C4wypBBCJp7HO9PmzxbOqaOAaOZbuuBCJp7HODGihgQGdPeph2TuDLecOloe34ZEiYBU(oiUECyX31MCyvzWdeBo8tzYUI7mV567G56XHfFxBYH9BAgIpefcLNd)uMSR4oZBU(Askxpo8tzYUI7mh2JR(4s4We8kl(rPsdGsgqjLdl(U2Kd7fgli(U2mWktZHzLPdPeph2VltTUtEZ1xtn56XHFkt2vCN5WEC1hxchUf2Z2QemKcgMy0zFkt2vakeaQJakubxYKDRBP6kjeqxCqjyifmmXOdqrIeqvFoGIAvcgsbdtm6SdebuN4WIVRn5WEHXcIVRndSY0Cywz6qkXZHvcgsbdtm64nxFnHmxpo8tzYUI7mh2JR(4s4WTWE2w1JBwE7tzYUIdl(U2KdJhYG47AZaRmnhMvMoKs8Cy1JBwEEZ1xZrX1Jd)uMSR4oZHfFxBYHXdzq8DTzGvMMdZkthsjEoCU4OW4nV5WeX3VXP0C946Rjxpo8tzYUI7mhoL45WIdz0jyXeq3SdlAG46(yoS47AtoS4qgDcwmb0n7WIgiUUpM3C9HmxpoS47AtomXTRn5WpLj7kUZ8MR)O46XHFkt2vCN5WEC1hxchwdavCOJR(wVoz7YhASKg0fhLU20(uMSR4WIVRn5WX3sCXe1TMYWBEZHvpUz556X1xtUEC4NYKDf3zoShx9XLWHHk4sMSBNmr9Gss)5WIVRn5WQlTUGX9prEZ1hYC94WpLj7kUZCypU6JlHdJLsfo0NTvukJDGiGIejGILsfo0NTvukJTsafrafYUKdl(U2KdFeEyEjYBU(JIRhh(PmzxXDMd7XvFCjCyhb05akQn(wIlMOU1ug7arafcaflLkCOpBROugBLakIa6OifqDcqrIeqfFxqF45J1nakIaQ6McFvOfmH3goS47Atom6zHPGXcHZBU(Kaxpo8tzYUI7mh2JR(4s4WqfCjt2TtMOEqjP)akeaQgaQFxMADN24BjUyI6wtzS4lkeauiauhbu)Um16oThHhMxIw8JsLgafra1ra1LakjdOIdDC13Ip0LbTscHjtu3yXscjaDKbOJcqDcqrIeqDeqXsPch6Z2kkLXwjGIiGk(U20ozI6bLK(B97YuR7eqHaqXsPch6Z2kkLXwjG6cafYUeqDcqDIdl(U2KdpzI6bLK(ZBU(UKRhhw8DTjhUIXLjDTzqgWch(PmzxXDM3C9DaUEC4NYKDf3zoShx9XLWH1aqHk4sMSBjUlRscb0fhMmr9Gss)5WIVRn5WsMLUIjDTjV56tI56XHFkt2vCN5WEC1hxchgDaJGvD0YxnGIizaLeiLdl(U2KdJE2KjQZBU(oiUEC4NYKDf3zoShx9XLWH1aqHk4sMSBjUlRscb0fhMmr9Gss)buiaunauOcUKj7wI7YQKqaDXHJWdZlroS47AtoSxNSMGPXfKoV567G56XHFkt2vCN5WEC1hxchUf2Z2QECZWKjQBSpLj7kafcavda1VltTUt7r4H5LOfFrHaGcbG6iG61jyc3aOKbuidOircOocOyPuHd9zBJl0hF22kbuebunjfqHaqXsPch6Z2kkLXwjGIiGQjPaQtaQtCyX31MCy0Zc4bJoEZ1xts56XHfFxBYHvpUPjmR(C4NYKDf3zEZ1xtn56XHFkt2vCN5WEC1hxchEoGIA3HoSObSKeUDGihw8DTjhU1Hx3bcmPGEEZ1xtiZ1Jd)uMSR4oZH94QpUeoCCH(4Z2QktlP)akIaQMUeqrIeqNdOO2DOdlAaljHBhiYHfFxBYHrplGhm64nxFnhfxpo8tzYUI7mh2JR(4s4WXf6JpBRQmTK(dOicOA6soS47Atom0Neo6alGFJV08MRVMKaxpo8tzYUI7mh2JR(4s4WTWE2w1JBgMmrDJ9PmzxXHfFxBYHBD41DGatkON38Md73LPw3jxpU(AY1Jd)uMSR4oZH94QpUeoSgaQJaAlSNTv94ML3(uMSRauKibuOcUKj7wI7YQKqaDXH4BbqrIeqHk4sMSBDlvxjHa6Id5J3uga1jafjsaTR4d9gu1buxaOq2LCyX31MC44BjUyI6wtz4nxFiZ1Jd)uMSR4oZH94QpUeoClSNTv94ML3(uMSRauiauhbunauXHoU6B96KTlFOXsAqxCu6At7tzYUcqrIeqDeq97YuR70EeEyEjAXpkvAauebuitkGcbG6iGQbGcvWLmz3ozI6bLK(dOircO(DzQ1DANmr9Gss)T4hLknakIakbVYgLrdqDcqDcqDIdl(U2KdhFlXftu3AkdV56pkUEC4NYKDf3zoShx9XLWHXsPch6Z2kkLX(rRmTbqHaqvFoGIAZhVPmw16obuiauhbuX3f0hE(yDdGIiGQUPWxfAbt4TbqrIeqXsPch6Z2kkLXwjGIiG6aKcOoXHfFxBYHZhVPm8MRpjW1Jd)uMSR4oZH94QpUeoSgakwkv4qF2wrPm2pALPnCyX31MC48XBkdV567sUEC4NYKDf3zoShx9XLWHNdOO24BjUyI6wtzS4hLknakIakKDjGIejG2v8HEdQ6aQlauhGuoS47AtomXTRn5nxFhGRhh(PmzxXDMdl(U2Kdtqy3lm2XMWC3Kd7XvFCjCyna0wypBl6zHPGXcHBFkt2vaksKaQFxMADNw0ZctbJfc3IVOqGdNs8Cycc7EHXo2eM7M8MRpjMRhh(PmzxXDMdl(U2Kd7rWZ2gVz5dtMyAoShx9XLWHNdOO24BjUyI6wtzSdebuia05akQn(4IriSOb2GVubf(s0yvR7eqHaqDeq1aqHk4sMSBNmr9Gss)buKibunau)Um16oTtMOEqjP)w8ffcaQtC4JIEFhsjEoShbpBB8MLpmzIP5nxFhexpo8tzYUI7mhw8DTjhwm6Gk5nbS4qlo4xSW4WEC1hxchw95akQflo0Id(flSG6ZbuuRADNaksKaQJaQ6ZbuuRFt1GVlOpujKcQphqrTdebuKib05akQn(wIlMOU1ugl(rPsdGIiGczsbuNauia0wWeEB1DH16Se9nG6caDuAcOircODfFO3GQoG6cafYKYHtjEoSy0bvYBcyXHwCWVyHXBU(oyUEC4NYKDf3zoS47AtoS4qgDcwmb0n7WIgiUUpMd7XvFCjCy)Um16oTX3sCXe1TMYyXpkvAauxaOAskGIejG63LPw3Pn(wIlMOU1ugl(rPsdGIiG6aKYHtjEoS4qgDcwmb0n7WIgiUUpM3C91KuUEC4NYKDf3zoShx9XLWHNdOO24BjUyI6wtzSde5WIVRn5WdMhQ(rdV56RPMC94WpLj7kUZCyX31MCyVWybX31MbwzAomRmDiL45W3yE6VH38MdRemKcgMy0X1JRVMC94WpLj7kUZCypU6JlHdJoGraqrKmG6GifqHaqDeq1aqHk4sMSBNmr9Gss)buKibunau)Um16oTtMOEqjP)w8ffcaQtCyX31MCyLGHuWWeJoEZ1hYC94WpLj7kUZCypU6JlHdR(Caf1QemKcgMy0zhiYHfFxBYHLmlDft6AtEZ1FuC94WpLj7kUZCypU6JlHdR(Caf1QemKcgMy0zhiYHfFxBYH96K1emnUG05nV5nhg6XMAtU(qMuitkPAc5rXHDl4Sscgo8iDK4I7RausmGk(U2eqzLPnwWyoSm06wmhgUIdmPRnhjybT5WeXlAXohEeakjHaD9aQd3JBcOKedzFmy8iauDDt0m61wBcvRByA9BuBtfhysxB6XcARTPIETbJhbG6WiIlgGQjPAbOqMuitkymy8iauh(coRKGz0dgpcaLKbusutLeauhUh3eqDMjQBa0OaPBa04AAaD0nGraqj88yPRnbuId4ZqaqjP6tsgqv4c6tavsfGoKeXxv(wMSRfG6wx51bOUlgdqRirX3aAR7a6i1bHvnca6IcO473y8Ps6AtJfmEeakjdOKOMkjaOKiB8zpeb0YaO52ak((ngFQUYHhGo6odqjPdgDaQ7IXa05bu89Bm(uDfGkPcqBDhqnc6Bea0ffqhDNbOK0bJoa1lzUnGopGQEFFFfGoraqfLAtJfmgmEea6irNKeUz0dgpcaLKbuhMsDfGos20mepGsIiekVfmEeakjdOK0hxOxbOTGj8ouOaQx39qcqrxmGQ)J3ugavMfRAeSGXJaqjzaLK(4c9kanUqF8zdOYSyvx3aOO4ncOeX1IRgba1TUNaAUnGoyUcqrxmGsISXN9q0cgpcaLKbuhMsDfGsIAoGos3pAa0Eb0NkaDrb0rYUm16onaQ47AtwzAly8iausgqhjBc94(kaDK73LPw35ihq7fqh5IVRnTJuS(DzQ1DoYbu36o(aQqKiR8YKDlymy8iaussJ29d9va68Ol(aQFJtPb05juPXcOomV)eBdGMBsY6eCeDGbOIVRnna6MmeSGXJaqfFxBASeX3VXP0KrzIbsGXJaqfFxBASeX3VXP0UswBzGq8zlDTjy8iauX31Mglr89BCkTRK1gDxfy8iau4uiA0TnGILsbOZbu0RautlTbqNhDXhq9BCknGopHknaQKkaLi(KmXT7kjaOLbqvBEly8iauX31Mglr89BCkTRK12KcrJUTdMwAdyS47AtJLi((noL2vYApyEO6h1kL4jloKrNGftaDZoSObIR7JbJfFxBASeX3VXP0UswBIBxBcgl(U20yjIVFJtPDLS2X3sCXe1TMYOvHswdXHoU6B96KTlFOXsAqxCu6At7tzYUcmgmEeakjPr7(H(ka9qpgbaTR4b0w3buX3lgqldGkqLIjt2TGXIVRnnUswBOcUKj7ALs8KNmr9Gss)1cQWgo5wypBlAHnDyY2vzFkt2virAiEgl0cMWBJDYe1dkj9xtej74Oi5wypBBJLIfw0aEOs7tzYUYjWyX31MgxjRnubxYKDTsjEYULQRKqaDXH8XBkJwqf2WjRHJA0c7zBZhVPm2NYKDfsK(DzQ1DAZhVPmw8ffcir63LPw3PnF8MYyXpkvAqSfmH32UIp0Bqvhjs)Um16oT5J3ugl(rPsdIoaPobgl(U204kzTHk4sMSRvkXtM4USkjeqxCi(w0cQWgoznAH9STQh3S82NYKDfe(DzQ1DAJVL4IjQBnLXIFuQ04chac0bmcw1rlF1ioksHWrnGk4sMSBDlvxjHa6Id5J3ugKi97YuR70MpEtzS4hLknUqtsDcmw8DTPXvYAdvWLmzxRuINmXDzvsiGU4WKjQhus6Vwqf2WjdvWLmz3ozI6bLK(dHJOdyeCbj2LKClSNTfTWMomz7QSpLj7QrgKj1jWyX31MgxjRnubxYKDTsjEYe3LvjHa6IdhHhMxIAbvydNClSNTv94ML3(uMSRGqJwypB7KvPkGoGrW(uMSRGWVltTUt7r4H5LOf)OuPXfosWRSrz0gzq2jiqhWiyvhT8vJiKjfmw8DTPXvYAdvWLmzxRuINSBP6kjeqxCqjyifmmXOtlOcB4KBH9STkbdPGHjgD2NYKDfeAavWLmz3sCxwLecOlomzI6bLK(dHgqfCjt2Te3LvjHa6IdX3ce(DzQ1DAvcgsbdtm6SdebJfFxBACLS2qfCjt21kL4j7wQUscb0fhIB8zpe1cQWgo5wypBBCJp7HO9PmzxbHgZbuuBCJp7HODGiyS47AtJRK1wvg8aXgmw8DTPXvYA730meFikekpyS47AtJRK12lmwq8DTzGvMwRuINSFxMADNAvOKj4vw8JsLgYKcgpcav8DTPXvYAtS8qkmqmGIfcXNTwfkz0bmcw1rlF1isEuUech1qCOJR(2JWnHfnGfc3(uMSRqI0VltTUt7r4H5LOf)OuPbrnTKGtGXIVRnnUswBVWybX31MbwzATsjEYkbdPGHjgDAvOKBH9STkbdPGHjgD2NYKDfeocvWLmz36wQUscb0fhucgsbdtm6qIu95akQvjyifmmXOZoq0jWyX31MgxjRnEidIVRndSY0ALs8KvpUz51Qqj3c7zBvpUz5TpLj7kWyX31MgxjRnEidIVRndSY0ALs8KZfhfgymyS47AtJ1VltTUtYX3sCXe1TMYOvHswdhBH9STQh3S82NYKDfsKqfCjt2Te3LvjHa6IdX3csKqfCjt2TULQRKqaDXH8XBkJtir2v8HEdQ6UaYUemw8DTPX63LPw3PRK1o(wIlMOU1ugTkuYTWE2w1JBwE7tzYUcch1qCOJR(wVoz7YhASKg0fhLU20(uMSRqI0r)Um16oThHhMxIw8JsLgeHmPq4OgqfCjt2TtMOEqjP)ir63LPw3PDYe1dkj93IFuQ0GibVYgLrZjNCcmw8DTPX63LPw3PRK1oF8MYOvHsglLkCOpBROug7hTY0giuFoGIAZhVPmw16oHWrX3f0hE(yDdIQBk8vHwWeEBqIelLkCOpBROugBLi6aK6eyS47AtJ1VltTUtxjRD(4nLrRcLSgyPuHd9zBfLYy)OvM2agl(U20y97YuR70vYAtC7AtTkuYZbuuB8TexmrDRPmw8JsLgeHSlrISR4d9gu1DHdqkyS47AtJ1VltTUtxjR9G5HQFuRuINmbHDVWyhBcZDtTkuYA0c7zBrplmfmwiC7tzYUcjs)Um16oTONfMcgleUfFrHayS47AtJ1VltTUtxjR9G5HQFuRJIEFhsjEYEe8STXBw(WKjMwRcL8Caf1gFlXftu3AkJDGieZbuuB8XfJqyrdSbFPck8LOXQw3jeoQbubxYKD7KjQhus6psKA43LPw3PDYe1dkj93IVOqWjWyX31MgRFxMADNUsw7bZdv)OwPepzXOdQK3eWIdT4GFXctRcLS6ZbuulwCOfh8lwyb1NdOOw16orI0r1NdOOw)MQbFxqFOsifuFoGIAhiIe5Caf1gFlXftu3AkJf)OuPbritQtq0cMWBRUlSwNLOVDXO0ejYUIp0Bqv3fqMuWyX31MgRFxMADNUsw7bZdv)OwPepzXHm6eSycOB2HfnqCDFSwfkz)Um16oTX3sCXe1TMYyXpkvACHMKIePFxMADN24BjUyI6wtzS4hLkni6aKcgpca1H7OYaRbuuHXMIhsak6Ib0bJmzhqR(rJfmw8DTPX63LPw3PRK1EW8q1pA0QqjphqrTX3sCXe1TMYyhicgl(U20y97YuR70vYA7fgli(U2mWktRvkXt(gZt)nGXGXIVRnnwLGHuWWeJoYkbdPGHjgDAvOKrhWiGizhePq4OgqfCjt2TtMOEqjP)irQHFxMADN2jtupOK0Fl(IcbNaJfFxBASkbdPGHjgDUswBjZsxXKU2uRcLS6ZbuuRsWqkyyIrNDGiyS47AtJvjyifmmXOZvYA71jRjyACbPRvHsw95akQvjyifmmXOZoqemgmw8DTPXQECZYtwDP1fmU)jQvHsgQGlzYUDYe1dkj9hmw8DTPXQECZY7kzTpcpmVe1QqjJLsfo0NTvukJDGisKyPuHd9zBfLYyReri7sWyX31MgR6XnlVRK1g9SWuWyHW1Qqj74Caf1gFlXftu3AkJDGieyPuHd9zBfLYyReXrrQtirk(UG(WZhRBquDtHVk0cMWBdyS47AtJv94ML3vYApzI6bLK(RvHsgQGlzYUDYe1dkj9hcn87YuR70gFlXftu3AkJfFrHaeo63LPw3P9i8W8s0IFuQ0GOJUKKfh64QVfFOldALectMOUXILesJSr5esKoILsfo0NTvukJTsefFxBANmr9Gss)T(DzQ1Dcbwkv4qF2wrPm2kDbKDPtobgl(U20yvpUz5DLS2vmUmPRndYawaJfFxBASQh3S8UswBjZsxXKU2uRcLSgqfCjt2Te3LvjHa6IdtMOEqjP)GXIVRnnw1JBwExjRn6ztMOUwfkz0bmcw1rlF1isMeifmw8DTPXQECZY7kzT96K1emnUG01QqjRbubxYKDlXDzvsiGU4WKjQhus6peAavWLmz3sCxwLecOloCeEyEjcgl(U20yvpUz5DLS2ONfWdgDAvOKBH9STQh3mmzI6g7tzYUccn87YuR70EeEyEjAXxuiaHJEDcMWnKHmsKoILsfo0NTnUqF8zBRernjfcSuQWH(STIszSvIOMK6KtGXIVRnnw1JBwExjRT6XnnHz1hmw8DTPXQECZY7kzTBD41DGatkOxRcL8Caf1UdDyrdyjjC7arWyX31MgR6XnlVRK1g9SaEWOtRcLCCH(4Z2QktlP)iQPlrICoGIA3HoSObSKeUDGiyS47AtJv94ML3vYAd9jHJoWc434lTwfk54c9XNTvvMws)rutxcgl(U20yvpUz5DLS2To86oqGjf0RvHsUf2Z2QECZWKjQBSpLj7kWyWyX31Mg7nMN(BidvWLmzxRuINm6zHPGXcHhmiKETkuYTWE2w0ZctbJfc3(uMSR0cQWgoz)Um16oTONfMcgleUfFrHaeo6OJA0c7zBvpUz5TpLj7kKiNdOO24BjUyI6wtzSdeDccnGk4sMSBDlvxjHa6IdXn(ShIqGLsfo0NTvukJTsehfPoHeP47c6dpFSUbr1nf(QqlycVnobgl(U20yVX80FJRK12VP)zJL(QaktIxRcLSJAO22630)SXsFvaLjXhMd402LhsvsacneFxBA9B6F2yPVkGYK4TvgqzfbDnsKOdmwaFVobt4HUI3fe8kBugnNaJhbG6W6(rInG2lGAqi9aQ7Q1bOJUZauNfmwiCaDXaQdBjjbOfkGwnG6UymaDEaDWCfG6UADvcOTUdO5hTgqjbxcOM73uz0cq3w3XUlZb0bZbu1aUscaAU4OWa05a20aQsIcHBbJfFxBAS3yE6VXvYApz7QclAO19WZhrqRcLSJA0c7zBrplmfmwiC7tzYUcjs)Um16oTONfMcgleUf)OuPbrsWLobHgqfCjt2TULQRKqaDXH4gF2driC0rnAH9STQh3S82NYKDfsKZbuuB8TexmrDRPm2bIqOHFxMADN2jtupOK0Fl(IcbNqISR4d9gu1Dbznj1jWyX31Mg7nMN(BCLS2t2UQWIgADp88re0Qqj3c7zBrplmfmwiC7tzYUccOcUKj7w0ZctbJfcpyqi9GXIVRnn2Bmp934kzTrx)G5QG4qhx9dZlrTkuYgINXcTGj82yNmr9Gss)1erYqgjsSuQWH(STIszSvIOdqkyS47AtJ9gZt)nUswBId4cfHkjeMmX0AvOKnepJfAbt4TXozI6bLK(RjIKHmsKyPuHd9zBfLYyRerhGuWyX31Mg7nMN(BCLS2TUhgY5oKQa6I9xRcL8Caf1IVhsSBmb0f7VDGisKZbuul(EiXUXeqxS)b)oK9XwtlEi5cnjfmw8DTPXEJ5P)gxjRnUisK9qLbdrXFWyX31Mg7nMN(BCLS2Uxmtb9vgW3SPK(RvHsEoGIAJVL4IjQBnLXoqejsOcUKj7w0ZctbJfcpyqi9GXIVRnn2Bmp934kzTJpUyeclAGn4lvqHVenAvOKrhWi4csGuiMdOO24BjUyI6wtzSdebJhbGssSmfGssVqSsca6OJjXBau0fdOF0UFOpGILKWb0fdOqQymaDoGIA0cqluaL4Am1KDlG6WyUfemaAJraq7fqj8gqBDhqzR7BAa1VltTUtaDkMRa0nbubQumzYoG(8X6glyS47AtJ9gZt)nUswB8fIvsiGYK4nA5rWZEOfmH3gYAQvHsUfmH32UIp0Bqv3fAADjsKo6ylycVT6UWADwI(grhePir2cMWBRUlSwNLOVDbzitQtq4O47c6dpFSUHSMir2cMWBBxXh6nOQJiKDWo5esKo2cMWBBxXh6nq03bitkIJIuiCu8Db9HNpw3qwtKiBbt4TTR4d9gu1rKeibNCcmgmw8DTPXMlokmYqFs4OdSa(n(sRvHsUf2Z2g34ZEiAFkt2vqmhqrTeXNOGVYQw3jeDfpIAcgl(U20yZfhfMRK1g9SaEWOtRcLSJqfCjt2TULQRKqaDXH4gF2drKiBH9STONfIIPpgb7tzYUYjiC0RtWeUHmKrI0rSuQWH(STXf6JpBBLiQjPqGLsfo0NTvukJTse1KuNCcmw8DTPXMlokmxjRn6zHPGXcHRvHswdOcUKj7w3s1vsiGU4qCJp7Hieok(UG(WZhRBquDtHVk0cMWBdsKyPuHd9zBfLYyReXrrQtGXIVRnn2CXrH5kzTvxADbJ7FIAvOKHk4sMSBNmr9Gss)bJfFxBAS5IJcZvYAxX4YKU2midybmw8DTPXMlokmxjR9r4H5LOwfkzX3f0hE(yDdIAcHJAGLsfo0NTvukJ9JwzAdsKyPuHd9zBfLYyhi6eeAavWLmz36wQUscb0fhIB8zpebJfFxBAS5IJcZvYApzI6bLK(RvHsgQGlzYUDYe1dkj9hmw8DTPXMlokmxjRn6ztMOUwfkz0bmcw1rlF1isMeifmw8DTPXMlokmxjR9r4H5LOwfkznAH9STtwLQa6agb7tzYUccnGk4sMSBDlvxjHa6IdkbdPGHjgDqGLsfo0NTvukJTsefFxBApcpmVeT(DzQ1Dcgl(U20yZfhfMRK1wYS0vmPRn1Qqj7ylSNTv94MHjtu3yFkt2virQbubxYKDRBP6kjeqxCiUXN9qejs0bmcw1rlF1UyuKIe5Caf1gFlXftu3AkJf)OuPXfU0ji0aQGlzYUL4USkjeqxCyYe1dkj9hcnGk4sMSBDlvxjHa6IdkbdPGHjgDGXIVRnn2CXrH5kzT96K1emnUG01Qqj7ylSNTv94MHjtu3yFkt2virQbubxYKDRBP6kjeqxCiUXN9qejs0bmcw1rlF1UyuK6eeAavWLmz3sCxwLecOloeFlqObubxYKDlXDzvsiGU4WKjQhus6peAavWLmz36wQUscb0fhucgsbdtm6aJfFxBAS5IJcZvYAFeEyEjQvHsUf2Z2ozvQcOdyeSpLj7kiWsPch6Z2kkLXwjIIVRnThHhMxIw)Um16obJfFxBAS5IJcZvYARECttyw9bJfFxBAS5IJcZvYAJEwapy0PvHswJwypBBCJp7HO9Pmzxbbwkv4qF224c9XNTTse96emHBgzAskeTWE2w1JBgMmrDJ9Pmzxbgl(U20yZfhfMRK1g9SjtuxRcLCCH(4Z2QktlP)iQPlrICoGIA3HoSObSKeUDGiyS47AtJnxCuyUswB0Zc4bJoTkuYXf6JpBRQmTK(JOMUejshNdOO2DOdlAaljHBhicHgTWE224gF2dr7tzYUYjWyX31MgBU4OWCLS2qFs4OdSa(n(sRvHsoUqF8zBvLPL0Fe10LGXIVRnn2CXrH5kzTBD41DGatkOxRcLClSNTv94MHjtu3yFkt2v8M3Coa]] )


end
