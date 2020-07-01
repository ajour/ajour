-- PriestShadow.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local FindUnitBuffByID = ns.FindUnitBuffByID


local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'PRIEST' then
    local spec = Hekili:NewSpecialization( 258, true )

    spec:RegisterResource( Enum.PowerType.Insanity, {
        mind_flay = {
            aura = 'mind_flay',
            debuff = true,

            last = function ()
                local app = state.debuff.mind_flay.applied
                local t = state.query_time

                return app + floor( ( t - app ) / class.auras.mind_flay.tick_time ) * class.auras.mind_flay.tick_time
            end,

            interval = function () return class.auras.mind_flay.tick_time end,
            value = function () return ( state.talent.fortress_of_the_mind.enabled and 1.2 or 1 ) * 3 end,
        },

        mind_sear = {
            aura = 'mind_sear',
            debuff = true,

            last = function ()
                local app = state.debuff.mind_sear.applied
                local t = state.query_time

                return app + floor( ( t - app ) / class.auras.mind_sear.tick_time ) * class.auras.mind_sear.tick_time
            end,

            interval = function () return class.auras.mind_sear.tick_time end,
            value = function () return ( state.talent.fortress_of_the_mind.enabled and 1.2 or 1 ) * 1.25 * state.active_enemies end,
        },

        -- need to revise the value of this, void decay ticks up and is impacted by void torrent.
        voidform = {
            aura = "voidform",

            last = function ()
                local app = state.buff.voidform.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            stop = function( x )
                return x == 0
            end,

            interval = 1,
            value = function ()
                return ( state.debuff.void_torrent.up or state.debuff.dispersion.up ) and 0 or ( -6 - ( 0.8 * state.debuff.voidform.stacks ) )
            end,
        },

        void_torrent = {
            aura = "void_torrent",

            last = function ()
                local app = state.buff.void_torrent.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            stop = function( x )
                return x == 0
            end,

            interval = 1,
            value = 7.5,
        },

        vamp_touch_t19 = {
            aura = "vampiric_touch",
            set_bonus = "tier19_2pc",
            debuff = true,

            last = function ()
                local app = state.debuff.vampiric_touch.applied
                local t = state.query_time

                return app + floor( ( t - app ) / class.auras.vampiric_touch.tick_time ) * class.auras.vampiric_touch.tick_time
            end,

            interval = function () return state.debuff.vampiric_touch.tick_time end,
            value = 1
        },

        mindbender = {
            aura = "mindbender",

            last = function ()
                local app = state.buff.mindbender.expires - 15
                local t = state.query_time

                return app + floor( ( t - app ) / ( 1.5 * state.haste ) ) * ( 1.5 * state.haste )
            end,

            interval = function () return 1.5 * state.haste end,
            value = function () return state.debuff.surrendered_to_madness.up and 0 or ( state.buff.surrender_to_madness.up and 12 or 6 ) end,
        },

        shadowfiend = {
            aura = "shadowfiend",

            last = function ()
                local app = state.buff.shadowfiend.expires - 15
                local t = state.query_time

                return app + floor( ( t - app ) / ( 1.5 * state.haste ) ) * ( 1.5 * state.haste )
            end,

            interval = function () return 1.5 * state.haste end,
            value = function () return state.debuff.surrendered_to_madness.up and 0 or ( state.buff.surrender_to_madness.up and 6 or 3 ) end,
        },
    } )
    spec:RegisterResource( Enum.PowerType.Mana )


    -- Talents
    spec:RegisterTalents( {
        fortress_of_the_mind = 22328, -- 193195
        shadowy_insight = 22136, -- 162452
        shadow_word_void = 22314, -- 205351

        body_and_soul = 22315, -- 64129
        sanlayn = 23374, -- 199855
        intangibility = 21976, -- 288733

        twist_of_fate = 23125, -- 109142
        misery = 23126, -- 238558
        dark_void = 23127, -- 263346

        last_word = 23137, -- 263716
        mind_bomb = 23375, -- 205369
        psychic_horror = 21752, -- 64044

        auspicious_spirits = 22310, -- 155271
        shadow_word_death = 22311, -- 32379
        shadow_crash = 21755, -- 205385

        lingering_insanity = 21718, -- 199849
        mindbender = 21719, -- 200174
        void_torrent = 21720, -- 263165

        legacy_of_the_void = 21637, -- 193225
        dark_ascension = 21978, -- 280711
        surrender_to_madness = 21979, -- 193223
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3476, -- 208683
        adaptation = 3477, -- 214027
        relentless = 3478, -- 196029

        void_shift = 128, -- 108968
        hallucinations = 3736, -- 280752
        psychic_link = 119, -- 199484
        void_origins = 739, -- 228630
        mind_trauma = 113, -- 199445
        edge_of_insanity = 110, -- 199408
        driven_to_madness = 106, -- 199259
        pure_shadow = 103, -- 199131
        void_shield = 102, -- 280749
        psyfiend = 763, -- 211522
        shadow_mania = 764, -- 280750
    } )


    spec:RegisterTotem( "mindbender", 136214 )
    spec:RegisterTotem( "shadowfiend", 136199 )


    local hadShadowform = false

    spec:RegisterHook( "reset_precast", function ()
        if time > 0 then
            applyBuff( "shadowform" )
        end

        if pet.mindbender.active then
            applyBuff( "mindbender", pet.mindbender.remains )
            buff.mindbender.applied = action.mindbender.lastCast
            buff.mindbender.duration = 15
            buff.mindbender.expires = action.mindbender.lastCast + 15
        elseif pet.shadowfiend.active then
            applyBuff( "shadowfiend", pet.shadowfiend.remains )
            buff.shadowfiend.applied = action.shadowfiend.lastCast
            buff.shadowfiend.duration = 15
            buff.shadowfiend.expires = action.shadowfiend.lastCast + 15
        end

        if action.void_bolt.in_flight then
            runHandler( "void_bolt" )
        end
    end )


    spec:RegisterHook( 'pregain', function( amount, resource, overcap )
        if amount > 0 and resource == "insanity" and state.buff.memory_of_lucid_dreams.up then
            amount = amount * 2
        end

        return amount, resource, overcap
    end )


    spec:RegisterHook( 'runHandler', function( ability )
        -- Make sure only the correct debuff is applied for channels to help resource forecasting.
        if ability == "mind_sear" then
            removeDebuff( "target", "mind_flay" )
        elseif ability == "mind_flay" then
            removeDebuff( "target", "mind_sear" )
        else
            removeDebuff( "target", "mind_flay" )
            removeDebuff( "target", "mind_sear" )
        end
    end )


    -- Auras
    spec:RegisterAuras( {
        body_and_soul = {
            id = 65081,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },
        dispersion = {
            id = 47585,
            duration = 6,
            max_stack = 1,
        },
        fade = {
            id = 586,
            duration = 10,
            max_stack = 1,
        },
        focused_will = {
            id = 45242,
            duration = 8,
            max_stack = 2,
        },
        levitate = {
            id = 111759,
            duration = 600,
            type = "Magic",
            max_stack = 1,
        },
        lingering_insanity = {
            id = 197937,
            duration = 60,
            max_stack = 8,
        },
        mind_bomb = {
            id = 226943,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },
        mind_flay = {
            id = 15407,
            duration = function () return 3 * haste end,
            max_stack = 1,
            tick_time = function () return 0.75 * haste end,
        },
        mind_sear = {
            id = 48045,
            duration = function () return 3 * haste end,
            max_stack = 1,
            tick_time = function () return 0.75 * haste end,
        },
        mind_vision = {
            id = 2096,
            duration = 60,
            max_stack = 1,
        },
        mindbender = {
            duration = 15,
            max_stack = 1,
        },
        power_word_fortitude = {
            id = 21562,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
            shared = "player", -- use anyone's buff on the player, not just player's.
        },
        power_word_shield = {
            id = 17,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },
        psychic_horror = {
            id = 64044,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        psychic_scream = {
            id = 8122,
            duration = 8,
            type = "Magic",
            max_stack = 1,
        },
        shackle_undead = {
            id = 9484,
            duration = 50,
            type = "Magic",
            max_stack = 1,
        },
        shadow_word_pain = {
            id = 589,
            duration = 16,
            type = "Magic",
            max_stack = 1,
            tick_time = function () return 2 * haste end,
        },
        shadowfiend = {
            duration = 15,
            max_stack = 1
        },
        shadowform = {
            id = 232698,
            duration = 3600,
            max_stack = 1,
        },
        shadowy_apparitions = {
            id = 78203,
        },
        shadowy_insight = {
            id = 124430,
            duration = 12,
            type = "Magic",
            max_stack = 1,
        },
        silence = {
            id = 15487,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        surrender_to_madness = {
            id = 193223,
            duration = 60,
            max_stack = 1,
        },
        surrendered_to_madness = {
            id = 263406,
            duration = 15,
            max_stack = 1,
        },
        vampiric_embrace = {
            id = 15286,
            duration = 15,
            max_stack = 1,
        },
        vampiric_touch = {
            id = 34914,
            duration = 21,
            type = "Magic",
            max_stack = 1,
            tick_time = function () return 3 * haste end,
        },
        void_bolt = {
            id = 228266,
        },
        void_torrent = {
            id = 263165,
            duration = 4,
            max_stack = 1,
            tick_time = 1,
        },
        voidform = {
            id = 194249,
            duration = 3600,
            max_stack = 99,
            generate = function( t )
                local name, _, count, _, duration, expires, caster, _, _, spellID, _, _, _, _, timeMod, v1, v2, v3 = FindUnitBuffByID( "player", 194249 )

                if name then
                    t.name = name
                    t.count = max( 1, count )
                    t.applied = max( action.void_eruption.lastCast, action.dark_ascension.lastCast, now )
                    t.expires = t.applied + 3600
                    t.duration = 3600
                    t.caster = "player"
                    t.timeMod = 1
                    t.v1 = v1
                    t.v2 = v2
                    t.v3 = v3
                    t.unit = "player"
                    return
                end

                t.name = nil
                t.count = 0
                t.expires = 0
                t.applied = 0
                t.duration = 3600
                t.caster = 'nobody'
                t.timeMod = 1
                t.v1 = 0
                t.v2 = 0
                t.v3 = 0
                t.unit = 'player'
            end,
            meta = {
                up = function ()
                    return buff.voidform.applied > 0 and buff.voidform.drop_time > query_time
                end,

                drop_time = function ()
                    if buff.voidform.applied == 0 then return 0 end

                    local app = buff.voidform.applied
                    app = app + floor( query_time - app )

                    local drain = 6 + ( 0.8 * buff.voidform.stacks )
                    local amt = insanity.current

                    while ( amt > 0 ) do
                        amt = amt - drain
                        drain = drain + 0.8
                        app = app + 1
                    end

                    return app
                end,

                stacks = function ()
                    return buff.voidform.applied > 0 and ( buff.voidform.count + floor( offset + delay ) ) or 0
                end,

                remains = function ()                    
                    return max( 0, buff.voidform.drop_time - query_time )
                end,
            },
        },
        weakened_soul = {
            id = 6788,
            duration = function () return 7.5 * haste end,
            max_stack = 1,
        },


        -- Azerite Powers
        chorus_of_insanity = {
            id = 279572,
            duration = 120,
            max_stack = 120,
        },

        death_denied = {
            id = 287723,
            duration = 10,
            max_stack = 1,
        },

        depth_of_the_shadows = {
            id = 275544,
            duration = 12,
            max_stack = 30
        },

        --[[ harvested_thoughts = {
            id = 273321,
            duration = 15,
            max_stack = 1,
        }, ]]

        searing_dialogue = {
            id = 288371,
            duration = 1,
            max_stack = 1
        },

        thought_harvester = {
            id = 288343,
            duration = 20,
            max_stack = 1,
            copy = "harvested_thoughts" -- SimC uses this name (carryover from Legion?)
        },

    } )


    spec:RegisterHook( "advance_end", function ()
        if buff.voidform.up and insanity.current == 0 then
            insanity.regen = 0
            removeBuff( "voidform" )
            if buff.surrender_to_madness.up then
                removeBuff( "surrender_to_madness" )
                applyDebuff( "player", "surrendered_to_madness" )
            end
            applyBuff( "shadowform" )
        end
    end )


    spec:RegisterGear( "tier21", 152154, 152155, 152156, 152157, 152158, 152159 )
    spec:RegisterGear( "tier20", 147163, 147164, 147165, 147166, 147167, 147168 )
        spec:RegisterAura( "empty_mind", {
            id = 247226,
            duration = 12,
            max_stack = 10,
        } )
    spec:RegisterGear( "tier19", 138310, 138313, 138316, 138319, 138322, 138370 )


    spec:RegisterGear( "anunds_seared_shackles", 132409 )
        spec:RegisterAura( "anunds_last_breath", {
            id = 215210,
            duration = 15,
            max_stack = 50,
        } )
    spec:RegisterGear( "heart_of_the_void", 151814 )
    spec:RegisterGear( "mangazas_madness", 132864 )
    spec:RegisterGear( "mother_shahrazs_seduction", 132437 )
    spec:RegisterGear( "soul_of_the_high_priest", 151646 )
    spec:RegisterGear( "the_twins_painful_touch", 133973 )
    spec:RegisterGear( "zenkaram_iridis_anadem", 133971 )
    spec:RegisterGear( "zeks_exterminatus", 144438 )
        spec:RegisterAura( "zeks_exterminatus", {
            id = 236546,
            duration = 15,
            max_stack = 1,
        } )


    spec:RegisterStateExpr( "current_insanity_drain", function ()
        return buff.voidform.up and ( 6 + ( 0.8 * buff.voidform.stacks ) ) or 0
    end )


    -- Abilities
    spec:RegisterAbilities( {
        dark_ascension = {
            id = 280711,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = -50,
            spendType = "insanity",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1711336,

            talent = "dark_ascension",

            handler = function ()
                applyBuff( "voidform", nil, ( level < 116 and equipped.mother_shahrazs_seduction ) and 3 or 1 )
            end,
        },


        dark_void = {
            id = 263346,
            cast = 2,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 132851,

            talent = "dark_void",

            handler = function ()
                applyDebuff( "target", "shadow_word_pain" )
                active_dot.shadow_word_pain = max( active_dot.shadow_word_pain, active_enemies )
            end,
        },


        dispel_magic = {
            id = 528,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.016,
            spendType = "mana",

            startsCombat = true,
            texture = 136066,

            usable = function () return buff.dispellable_magic.up end,
            handler = function ()
                removeBuff( "dispellable_magic" )
                gain( 6, "insanity" )
            end,
        },


        dispersion = {
            id = 47585,
            cast = 0,
            cooldown = function () return talent.intangibility.enabled and 90 or 120 end,
            gcd = "spell",

            toggle = "defensives",
            defensive = true,

            startsCombat = false,
            texture = 237563,

            handler = function ()
                applyBuff( "dispersion" )
                setCooldown( "global_cooldown", 6 )
            end,
        },


        fade = {
            id = 586,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 135994,

            handler = function ()
                applyBuff( "fade" )
            end,
        },


        leap_of_faith = {
            id = 73325,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = false,
            texture = 463835,

            handler = function ()
                if azerite.death_denied.enabled then applyBuff( "death_denied" ) end
            end,
        },


        levitate = {
            id = 1706,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135928,

            handler = function ()
                applyBuff( "levitate" )
            end,
        },


        mass_dispel = {
            id = 32375,
            cast = 1.5,
            cooldown = 45,
            gcd = "spell",

            spend = 0.08,
            spendType = "mana",

            startsCombat = true,
            texture = 135739,

            usable = function () return buff.dispellable_magic.up or debuff.dispellable_magic.up end,
            handler = function ()
                removeBuff( "dispellable_magic" )
                removeDebuff( "player", "dispellable_magic" )
                gain( 6, "insanity" )
            end,
        },


        -- SimulationCraft module for Shadow Word: Void automatically substitutes SW:V for MB when talented.
        mind_blast = {
            id = function () return talent.shadow_word_void.enabled and 205351 or 8092 end,
            cast = function () return haste * ( buff.shadowy_insight.up and 0 or 1.5 ) end,
            charges = function ()
                local n = 1
                if talent.shadow_word_void.enabled then n = n + 1 end
                if level < 116 and equipped.mangazas_madness then n = n + 1 end
                return n > 1 and n or nil
            end,
            cooldown = function () return ( talent.shadow_word_void.enabled and 9 or 7.5 ) * haste end,
            recharge = function () return ( talent.shadow_word_void.enabled and 9 or 7.5 ) * haste end,
            gcd = "spell",

            velocity = 15,

            spend = function () return ( talent.fortress_of_the_mind.enabled and 1.2 or 1 ) * ( ( talent.shadow_word_void.enabled and -15 or -12 ) - buff.empty_mind.stack ) * ( buff.surrender_to_madness.up and 2 or 1 ) * ( debuff.surrendered_to_madness.up and 0 or 1 ) end,
            spendType = "insanity",

            startsCombat = true,
            texture = function () return talent.shadow_word_void.enabled and 610679 or 136224 end,

            -- notalent = "shadow_word_void",

            handler = function ()
                removeBuff( "harvested_thoughts" )
                removeBuff( "shadowy_insight" )
                removeBuff( "empty_mind" )
            end,

            copy = { "shadow_word_void", 205351, 8092 },
        },


        mind_bomb = {
            id = 205369,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 136173,

            talent = "mind_bomb",

            handler = function ()
                applyDebuff( "target", "mind_bomb" )
            end,
        },


        --[[ mind_control = {
            id = 605,
            cast = 1.8,
            cooldown = 0,
            gcd = "spell",

            spend = 100,
            spendType = "mana",

            startsCombat = true,
            texture = 136206,

            handler = function ()
            end,
        }, ]]


        mind_flay = {
            id = 15407,
            cast = 3,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "insanity",

            channeled = true,
            breakable = true,
            breakchannel = function ()
                removeDebuff( "target", "mind_flay" )
            end,
            prechannel = true,

            startsCombat = true,
            texture = 136208,

            aura = 'mind_flay',

            start = function ()
                applyDebuff( "target", "mind_flay" )
                channelSpell( "mind_flay" )

                if level < 116 then
                    if equipped.the_twins_painful_touch and action.mind_flay.lastCast < max( action.dark_ascension.lastCast, action.void_eruption.lastCast ) then
                        if debuff.shadow_word_pain.up and active_dot.shadow_word_pain < min( 4, active_enemies ) then
                            active_dot.shadow_word_pain = min( 4, active_enemies )
                        end
                        if debuff.vampiric_touch.up and active_dot.vampiric_touch < min( 4, active_enemies ) then
                            active_dot.vampiric_touch = min( 4, active_enemies )
                        end
                    end

                    if set_bonus.tier20_2pc == 1 then
                        addStack( "empty_mind", nil, 3 )
                    end
                end

                forecastResources( "insanity" )
            end,
        },


        mind_sear = {
            id = 48045,
            cast = 3,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "insanity",

            channeled = true,
            breakable = true,
            breakchannel = function ()
                removeDebuff( "target", "mind_sear" )
            end,            
            prechannel = true,

            startsCombat = true,
            texture = 237565,

            aura = 'mind_sear',

            start = function ()
                applyDebuff( "target", "mind_sear" )
                channelSpell( "mind_sear" )

                if azerite.searing_dialogue.enabled then applyDebuff( "target", "searing_dialogue" ) end
                
                removeBuff( "thought_harvester" )
                forecastResources( "insanity" )
            end,
        },


        --[[ mind_vision = {
            id = 2096,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135934,

            handler = function ()
                -- applies mind_vision (2096)
            end,
        }, ]]


        -- SimulationCraft module: Mindbender and Shadowfiend are interchangeable.
        mindbender = {
            id = function () return talent.mindbender.enabled and 200174 or 34433 end,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( talent.mindbender.enabled and 60 or 180 ) end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = function () return talent.mindbender.enabled and 136214 or 136199 end,

            -- talent = "mindbender",

            handler = function ()
                summonPet( talent.mindbender.enabled and "mindbender" or "shadowfiend", 15 )
                applyBuff( talent.mindbender.enabled and "mindbender" or "shadowfiend" )
            end,

            copy = { "shadowfiend", 200174, 34433 }
        },

        --[[ shadowfiend = {
            id = 34433,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "cooldowns",
            notalent = "mindbender",

            startsCombat = true,
            texture = 136199,

            handler = function ()
                summonPet( "shadowfiend", 15 )
                applyBuff( "shadowfiend" )
            end,
        }, ]]                

        power_word_fortitude = {
            id = 21562,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = false,
            texture = 135987,

            usable = function () return buff.power_word_fortitude.down end,
            handler = function ()
                applyBuff( "power_word_fortitude" )
            end,
        },


        power_word_shield = {
            id = 17,
            cast = 0,
            cooldown = 6,
            hasteCD = true,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            nodebuff = "weakened_soul",

            startsCombat = false,
            texture = 135940,

            handler = function ()
                applyBuff( "power_word_shield" )
                applyDebuff( "weakened_soul" )
                if talent.body_and_soul.enabled then applyBuff( "body_and_soul" ) end
                gain( 6, "insanity" )
            end,
        },


        psychic_horror = {
            id = 64044,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 237568,

            talent = "psychic_horror",

            handler = function ()
                applyDebuff( "target", "psychic_horror" )
            end,
        },


        psychic_scream = {
            id = 8122,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0.012,
            spendType = "mana",

            startsCombat = true,
            texture = 136184,

            notalent = "mind_bomb",

            handler = function ()
                applyDebuff( "target", "psychic_scream" )
            end,
        },


         purify_disease = {
            id = 213634,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135935,

            usable = function () return debuff.dispellable_disease.up end,
            handler = function ()
                removeBuff( "player", "dispellable_disease" )
            end,
        },


        --[[ resurrection = {
            id = 2006,
            cast = 10,
            cooldown = 0,
            gcd = "spell",

            spend = 0.01,
            spendType = "mana",

            startsCombat = true,
            texture = 135955,

            handler = function ()
            end,
        }, ]]


        shackle_undead = {
            id = 9484,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.012,
            spendType = "mana",

            startsCombat = true,
            texture = 136091,

            handler = function ()
                applyDebuff( "target", "shackle_undead" )
            end,
        },


        shadow_crash = {
            id = 205385,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = -20,
            spendType = "insanity",

            startsCombat = true,
            texture = 136201,

            handler = function ()
            end,
        },


        shadow_mend = {
            id = 186263,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = 0.03,
            spendType = "mana",

            startsCombat = true,
            texture = 136202,

            handler = function ()
                removeBuff( "depth_of_the_shadows" )
            end,
        },


        shadow_word_death = {
            id = 32379,
            cast = 0,
            charges = 2,
            cooldown = 9,
            recharge = 9,
            gcd = "spell",

            spend = 15,
            spendType = "insanity",

            startsCombat = true,
            texture = 136149,

            talent = "shadow_word_death",

            usable = function () return buff.zeks_exterminatus.up or target.health.pct < 20 end,
            handler = function ()
                removeBuff( "zeks_exterminatus" )
            end,
        },


        shadow_word_pain = {
            id = 589,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = -4,
            spendType = "insanity",

            startsCombat = true,
            texture = 136207,

            cycle = "shadow_word_pain",

            handler = function ()
                applyDebuff( "target", "shadow_word_pain" )
            end,
        },


        --[[ shadow_word_void = {
            id = 205351,
            cast = 1.5,
            charges = 2,
            cooldown = 9,
            recharge = 9,
            hasteCD = true,
            gcd = "spell",

            velocity = 15,

            spend = function () return ( talent.fortress_of_the_mind.enabled and 1.2 or 1 ) * ( -15 - buff.empty_mind.stack ) * ( buff.surrender_to_madness.up and 2 or 1 ) * ( debuff.surrendered_to_madness.up and 0 or 1 ) end,
            spendType = "insanity",

            startsCombat = true,
            texture = 610679,

            talent = "shadow_word_void",

            handler = function ()
                -- applies voidform (194249)
                -- applies mind_flay (15407)
                -- removes shadow_word_pain (589)
            end,
        }, ]]


        --[[ shadowfiend = {
            id = 34433,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "cooldowns",
            notalent = "mindbender",

            startsCombat = true,
            texture = 136199,

            handler = function ()
                summonPet( "shadowfiend", 15 )
                applyBuff( "shadowfiend" )
            end,
        }, ]]


        shadowform = {
            id = 232698,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 136200,

            essential = true,
            nobuff = function () return buff.voidform.up and 'voidform' or 'shadowform' end,

            handler = function ()
                applyBuff( "shadowform" )
            end,
        },


        silence = {
            id = 15487,
            cast = 0,
            cooldown = 45,
            gcd = "off",

            startsCombat = true,
            texture = 458230,

            toggle = "interrupts",
            interrupt = true,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
                applyDebuff( "target", "silence" )
            end,
        },


        surrender_to_madness = {
            id = 193223,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 254090,

            handler = function ()
                applyBuff( "surrender_to_madness" )
            end,
        },


        vampiric_embrace = {
            id = 15286,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            startsCombat = false,
            texture = 136230,

            handler = function ()
                applyBuff( "vampiric_embrace" )
            end,
        },


        vampiric_touch = {
            id = 34914,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            spend = -6,
            spendType = "insanity",

            startsCombat = true,
            texture = 135978,

            cycle = function () return talent.misery.enabled and 'shadow_word_pain' or 'vampiric_touch' end,

            handler = function ()
                applyDebuff( "target", "vampiric_touch" )
                if talent.misery.enabled then
                    applyDebuff( "target", "shadow_word_pain" )
                end
                -- Thought Harvester is a 20% chance to proc, consumed by Mind Sear.
                -- if azerite.thought_harvester.enabled then applyBuff( "harvested_thoughts" ) end
            end,
        },


        void_bolt = {
            id = 205448,
            known = 228260,
            cast = 0,
            cooldown = function ()
                if level < 116 and set_bonus.tier19_4pc > 0 and query_time - buff.voidform.applied < 2.5 then return 0 end
                return haste * 4.5
            end,
            gcd = "spell",

            spend = function ()
                if debuff.surrendered_to_madness.up then return 0 end
                return buff.surrender_to_madness.up and -40 or -20
            end,
            spendType = "insanity",

            startsCombat = true,
            texture = 1035040,

            velocity = 40,
            buff = "voidform",
            bind = "void_eruption",

            handler = function ()
                if debuff.shadow_word_pain.up then debuff.shadow_word_pain.expires = debuff.shadow_word_pain.expires + 3 end
                if debuff.vampiric_touch.up then debuff.vampiric_touch.expires = debuff.vampiric_touch.expires + 3 end
                removeBuff( "anunds_last_breath" )
            end,
        },


        void_eruption = {
            id = 228260,
            cast = function ()
                if pvptalent.void_origins.enabled then return 0 end
                return haste * ( talent.legacy_of_the_void.enabled and 0.6 or 1 ) * 2.5 
            end,
            cooldown = 0,
            gcd = "spell",

            spend = function ()
                return talent.legacy_of_the_void.enabled and 60 or 90
            end,
            spendType = "insanity",

            startsCombat = true,
            texture = 1386548,

            nobuff = "voidform",
            bind = "void_bolt",

            -- ready = function () return insanity.current >= ( talent.legacy_of_the_void.enabled and 60 or 90 ) end,
            handler = function ()
                applyBuff( "voidform", nil, ( level < 116 and equipped.mother_shahrazs_seduction ) and 3 or 1 )
                gain( talent.legacy_of_the_void.enabled and 60 or 90, "insanity" )
            end,
        },


        void_torrent = {
            id = 263165,
            cast = 4,
            channeled = true,
            fixedCast = true,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 1386551,

            aura = "void_torrent",
            talent = "void_torrent",
            buff = "voidform",

            start = function ()
                applyDebuff( "target", "void_torrent" )
            end,
        },
    } )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageExpiration = 6,

        potion = "unbridled_fury",

        package = "Shadow",
    } )


    spec:RegisterPack( "Shadow", 20200525, [[dOuacbqifH6rIiDjKqvTjruJcj1PqvSkkPEfOywGs3srWUOQFbQmmrvhdv1YOe9mrettrIRPi12qc8nKqgNIK6CucP1rjunpkb3de7dj5GiHklevPhQiKjIeuxKsOOnQijvJejufNejiwPuPzQijLBIeK2js0qPek9ufMkOQRIekBvrs8vfjj7fYFPyWqDyslMs9yQmzuUmXMrLpdsJwKoTKvtju41IkZwk3gP2Tk)wvdxrDCKqvA5aphX0fUUOSDPQVlcJNsiopLK1RiA(sf7xPr8rWJgmneeLwM3Y85N2YP985BjfzjAewnlOXS6YPqf04uAbngPk7tGgZQvTxzi4rdYNbCcAKgXmXIdhCqRinZ27EA4ifDwtJ6phq5c4ifTdo0WoRAbfYHSrdMgcIslZBz(8tB50E(8TKI4trOHMfPpangf9eHgPfJjhYgnycXHgjDXJuL9jwSflOesSDt6ItJyMyXHdoOvKMz7DpnCKIoRPr9NdOCbCKI2b32nPlMcvTAXwonSl2Y8wMF7UDt6INOu9Gkel(2nPlEclMIJXe2IhvtoN43UjDXtyXt0F9cie2IdfavctXTyIvxOwe)2nPlEclEI(RxaHWwCOaOs4JIwmXByLS44xCu0IjEdRKfNivaYI155w5u7M4rJwrcccE0Guh0MGGhrjFe8OH6I6p0O)lMrazZr9hAiNA3egIxuGO0se8OHCQDtyiErdhOcbukAyNXX57)IX9aAp7tCOH6I6p0GPGCgL4KJu)HceLjbbpAOUO(dn6)IzS)wGgYP2nHH4ffikNccE0qo1UjmeVOH6I6p0WPTMrDr9NPvKanAfjmNslOHJrqbIYPrWJgYP2nHH4fnCGkeqPOHDghNpvb9cjeMjs)mOPbXNnV4KxS7)g7tC((Vyg7VfEGqR1rwmvqwmF)0lo5fRtkGkepruqDqnSsBp0mXd0l3IPcYI5JgQlQ)qd66ygIOauGOKcqWJgYP2nHH4fnCGkeqPOrOaOs4JIwmXByLSylS4KS4oDwS7)g7tCEsQY(eMepGzyIgPExQcGkKfdzXwU4oDwm1l29FJ9jopjvzFctIhWmmrJuVlvbqfYIHSy(lo5f7(VX(eNNKQSpHjXdygMOrQhi0ADKfBHfd1X80QfzX8GgQlQ)qdsQY(eMepGzyIgPOarjfHGhnKtTBcdXlA4aviGsrd7mooF)xmUhq7jH6YTyQwm)8lgMft9I5NFXwVy7mooVD7FwlJe(S5fZdAOUO(dnizaGCmbyI3qRStieuGOCQrWJgYP2nHH4fnCGkeqPObqlMr6Ll8kJr81TyQwm)8OH6I6p0GPGCM(VyOarPffbpAiNA3egIx0WbQqaLIgH2Kl801XSLJjaVCQDtylUtNft9ITZ4489FX4EaTNeQl3IPAX8N6f3PZIJIwmXByLSylSy(tVyEqd1f1FObDDmB5ycafik5NhbpAiNA3egIx0WbQqaLIgt8ITZ4489FX4EaTpBEXD6SyQxS7)g7tCEsQY(eMepGzyIgPExQcGkKfdzXwU4KxSDghNV)lg3dO9KqD5wSfwm)PxmpOH6I6p0GKQSpHjXdygMOrkkquYNpcE0qo1UjmeVOHduHakfnaAXmsVCHxzmIVUft1INEXjVyGwmJ0lx4vgJ4zzanQ)wSfwSL5rd1f1FObjvzFcJdOKuuGOKVLi4rd5u7MWq8IgoqfcOu0OxbLA3ep7dIjBEXjVyQxm1lgOfZi9YfE6VxOLl81TyQwStjHjkAzXWS48(PxCYlgOfZi9YfE6VxOLl81TylS4PSyEwCNolEIxCOn5cpjvzFctIhWm9FX8YP2nHT4oDwSDghNV)lg3dO9SpXT4oDwSDghNV)lg3dO9KqD5wmvlM)uwCYlM6fxhrVkSAXwyXuu(f3PZIDPkaQqmCa1f1FABXuTy((KKKfZZI70zX2zCC((VyCpG2tc1LBXwaYI5pLfN8IPEX1r0RcRwSfwmfKFXD6SyxQcGkedhqDr9N2wmvlMVpjjzX8SyEqd1f1FObDDmJDtjbkquYpji4rd5u7MWq8IgoqfcOu0G9HNKQSpHjXdyMzTopqO16ilMQfpLfN8IzF47v65cuot8zUupqO16ilMQfpLfN8ITZ4489FX4EaTpBgnuxu)Hg9FXmXdaYfOarj)PGGhnKtTBcdXlA4aviGsrdGWbesQA3KfN8IJIwmXByLSyQw8uwCYlEIxCOn5cpDreGvE5u7MWwCYlEIxCOn5cptb5m9FX8YP2nHHgQlQ)qdsQY(eMepGzM16qbIs(tJGhnKtTBcdXlA4aviGsrdGWbesQA3KfN8IJIwmXByLSyQwmfS4oDwm1lo0MCHNUicWkVCQDtylo5fZ(Wtsv2NWK4bmZSwNhiCaHKQ2nzX8GgQlQ)qJELEUaLZeFMlffik5tbi4rd5u7MWq8IgQlQ)qd66ygUMAfAuxiaq2Cyko0ikxocvqSmzQD)3yFIZ3)fZy)TWNn3PJ7)g7tCE66yg7MscF2mpOrDHaazZHPOPfwPHGg8rdxQwhAWhfik5tri4rd1f1FObjvzFctIhWmZADOHCQDtyiErbkqdMWPzTabpIs(i4rd1f1FObPAY5e0qo1UjmeVOarPLi4rd1f1FOrgrmvi0e0qo1UjmeVOarzsqWJgYP2nHH4fnCGkeqPOHDghN3U9pRLrcpquxS4oDwCu0IjEdRKfBbilEQZV4oDwCOaOs4tfTfP(zxSylS4KmnAOUO(dnM)O(dfikNccE0qo1UjmeVOXpJgejqd1f1FOrVck1UjOrV2Ye0G9HNKQSpHjXdyMzToFuUC1bDXjVy2h(ELEUaLZeFMl1hLlxDqrJEfyoLwqd2het2mkquoncE0qo1UjmeVOHduHakfnSZ4489FX4EaTpBgnuxu)HgCfqSB)ZqbIskabpAOUO(dnSfara5QdkAiNA3egIxuGOKIqWJgQlQ)qJwbnniglgzmO0YfOHCQDtyiErbIYPgbpAiNA3egIx0WbQqaLIg2zCC((VyCpG2NnJgQlQ)qd9CcjaAZ40wdfikTOi4rd1f1FOHTc18CMauUCe0qo1UjmeVOarj)8i4rd5u7MWq8IgoqfcOu0qDr1lg5e6silMQfZhnuxu)HgGSZOUO(Z0ksGgTIeMtPf0W1eTxqbIs(8rWJgYP2nHH4fnCGkeqPOH6IQxmYj0LqwmKfZhnuxu)HgGSZOUO(Z0ksGgTIeMtPf0Guh0MGcuGgZaX902AGGhrjFe8OH6I6p0y(J6p0qo1UjmeVOarPLi4rd5u7MWq8Ig)mAqKanuxu)Hg9kOu7MGg9AltqdU2)Gft9IPEXtXp9IHzX6KcOcXNiTiZcGyEotKkgMsFcZd0l3I5zXu8xm1lM)IHzX59wsrl26fRtkGkepruqDqnSsBp0mXd0l3I5zX8Gg9kWCkTGg01Xm2nLeMqbqLGGceLjbbpAiNA3egIx04NrdIeOH6I6p0OxbLA3e0OxBzcAq9I5V4jS48(8u0ITEX6KcOcXZensnrk4fIhOxUfdZIZ7TCXwVyDsbuH4J0pdAAysvqVqcb4b6LBX8SyRxm1lM)INWIZ7ZBrxS1lwNuavi(i9ZGMgMuf0lKqaEGE5wS1lwNuaviEIOG6GAyL2EOzIhOxUfZdA0RaZP0cAqsmBcGwHbOxoIXLkUCOar5uqWJgYP2nHH4fn(z0GibAOUO(dn6vqP2nbn61wMGguVy(lEcloVp)uwS1lwNuavi(i9ZGMgMuf0lKqaEGE5w8ewCEF(PxS1lwNuaviEYCfcxwZOZZkOI6pIhOxUfZdA0RaZP0cA0hMaOvya6LJyCPIlhkquoncE0qo1UjmeVOXpJgejqd1f1FOrVck1UjOrV2Ye0G6fZFXtyX595POfB9I1jfqfINjAKAIuWlepqVClEcloVpFswS1lwNuavi(i9ZGMgMuf0lKqaEGE5w8ewCEF(PNEXwVyDsbuH4jZviCznJopRGkQ)iEGE5wmpl26ft9I5V4jS48(8wsrl26fRtkGkeFK(zqtdtQc6fsiapqVCl26fRtkGkepruqDqnSsBp0mXd0l3I5bn6vG5uAbn6ddDrmbqRWa0lhX4sfxouGOKcqWJgYP2nHH4fn(z0GibAOUO(dn6vqP2nbn61wMGg8x8ewCEFE(tzXwVyDsbuH4jIcQdQHvA7HMjEGE5qJEfyoLwqJ(WqxedHzCPIlhkqusri4rd5u7MWq8IgoqfcOu0yIxSDghNNKQSpb3dO9zZOH6I6p0GKQSpb3dOrbIYPgbpAiNA3egIx04uAbn0jjPkqjgU)cZZzM)ecanuxu)Hg6KKufOed3FH55mZFcbGceLwue8OHCQDtyiErdhOcbukAqMLwZekaQeepDDmdruWITWITCXD6SyDsbuH4J0pdAAysvqVqcb4b6LBXqwCE0qDr9hAqxhZy3usGceL8ZJGhnuxu)Hg9k9CbkNj(mxkAiNA3egIxuGc0WXii4ruYhbpAiNA3egIx0WbQqaLIguVy7mooF)xmUhq7jH6YTyQwSL5xCYlUoIEvy1ITaKfpD(fZZI70zXuVyxgaixyQJOxfwzyaTUfB9IPEXuVyOoMNwTil26fB5I5zXWSy1f1FE66yg7MscVtjHjkAzX8SyEwmvlUoIEvyfAOUO(dnOf6hyL55mTmxXmmGO0euGO0se8OH6I6p0WU9pZ8CMivmYj0wHgYP2nHH4ffiktccE0qo1UjmeVOHduHakfnSZ4489FX4EaTNeQl3IPAX8Ngnuxu)HgqZuaR0Z8CgDsb8rkkquofe8OHCQDtyiErd1f1FObTEfNqI38CgALDcHGgoqfcOu0GmlTMjuaujiE66ygIOGftfKfB5I70zXaTygPxUWRmgXx3IPAXuqE04uAbnO1R4es8MNZqRStieuGOCAe8OHCQDtyiErdhOcbukAqMLwZekaQeepDDmdruWIPcYITCXD6SyGwmJ0lx4vgJ4RBXuTykipAOUO(dn4ExgrygDsbuHySfLgfikPae8OHCQDtyiErdhOcbukAqMLwZekaQeepDDmdruWIPcYITCXD6SyGwmJ0lx4vgJ4RBXuTykipAOUO(dnMZafNv1b1y3usGceLuecE0qo1UjmeVOH6I6p0W9NtUaOHWmCnLwqdhOcbukAefTSylazX8ZV4oDwm1l2oJJZ7sFqgX8CM6i6vHvEsOUClMkilM)0lo5fBNXX57)IX9aAF28I5zXD6SyUSwZaexQcGkMOOLfBHfd1XwCNolokAXeVHvYITWINgnA1jghdnOauGOCQrWJgQlQ)qdqnp3etDgYS6e0qo1UjmeVOarPffbpAOUO(dnaIoxhudxtPfcAiNA3egIxuGOKFEe8OH6I6p0iXdASEPodqi)PNtqd5u7MWq8IceL85JGhnKtTBcdXlA4aviGsrdQxSDghNV)lg3dO9zZlo5fBNXX5DPpiJyEotDe9QWkpjuxUft1ITm)I5zXD6SyDsbuH4DPpiJyEotDe9QWkpqVClgYIZJgQlQ)qdN2Ag1f1FMwrc0OvKWCkTGgoqfghJGceL8TebpAOUO(dnYiIPcHMGgYP2nHH4ffOanCnr7fe8ik5JGhnuxu)Hg9FXmciBoQ)qd5u7MWq8IceLwIGhnKtTBcdXlA4aviGsrd7mooF)xmUhq7zFIdnuxu)HgmfKZOeNCK6puGOmji4rd5u7MWq8IgoqfcOu0yIxCuUC1bDXjVyDsbuH4J0pdAAysvqVqcb4b6LBXubzX8rd1f1FOrVspxGYzIpZLIceLtbbpAiNA3egIx0WbQqaLIg2zCC(uf0lKqyMi9ZGMgeF2mAOUO(dnORJziIcqbIYPrWJgQlQ)qJ(Vyg7VfOHCQDtyiErbIskabpAiNA3egIx0qDr9hA40wZOUO(Z0ksGgTIeMtPf0WXiOarjfHGhnKtTBcdXlAOUO(dniPk7tys8aMHjAKIgoqfcOu0ikAXeVHvYITWItYI70zX2zCC((VyCpG2Z(ehA4SY1etOaOsqquYhfikNAe8OHCQDtyiErdhOcbukAyNXX57)IX9aApjuxUft1I5NFXWSyQxm)8l26fBNXX5TB)ZAzKWNnVyEqd1f1FObjdaKJjat8gALDcHGceLwue8OHCQDtyiErdhOcbukAa0IzKE5cVYyeFDlMQfZp)ItEXuVy2hEsQY(eMepGzM168aHdiKu1UjlUtNfhfTyI3WkzXuT4KKFX8GgQlQ)qdMcYz6)IHceL8ZJGhnuxu)Hg01XSLJja0qo1UjmeVOarjF(i4rd5u7MWq8IgQlQ)qd66yg7Msc0WbQqaLIgKzP1mHcGkbXtxhZqefSylS4EfuQDt801Xm2nLeMqbqLGGgoRCnXekaQeeeL8rbIs(wIGhnKtTBcdXlA4aviGsrdQxmqlMr6Ll8kJr81TyQw80lo5fd0IzKE5cVYyepldOr93ITWITCX8S4oDwmqlMr6Ll8kJr8SmGg1FlMQfBjAOUO(dniPk7tyCaLKIceL8tccE0qo1UjmeVOH6I6p0GKQSpHjXdyMzTo0WbQqaLIgt8IdTjx4PlIaSYlNA3e2ItEXaHdiKu1Ujlo5fhfTyI3WkzXuTyQxm1lEclMV3YfdZItIpjl26ftMLwZekaQeepDDmdruWI5zXwV4EfuQDt8KeZMaOvya6LJyCPIl3ITEXuVy(lEcloVppFlxS1lwNuaviEIOG6GAyL2EOzIhOxUfB9IjZsRzcfavcINUoMHikyX8SyEqdNvUMycfavccIs(Oarj)PGGhnKtTBcdXlAOUO(dn6v65cuot8zUu0WbQqaLIgaHdiKu1Ujlo5fhfTyI3WkzXuTyQxm1lM)IHzXjXNKfB9IjZsRzcfavcINUoMHikyX8SyRxCVck1Uj((WeaTcdqVCeJlvC5wS1lM6fZFXWS48E(5xS1lwNuaviEIOG6GAyL2EOzIhOxUfB9IjZsRzcfavcINUoMHikyX8SyEqdNvUMycfavccIs(Oarj)PrWJgYP2nHH4fnuxu)Hg9k9CbkNj(mxkA4aviGsrd2hEsQY(eMepGzM168aHdiKu1Ujlo5ft9IdTjx4PlIaSYlNA3e2ItEXrrlM4nSswmvlM6ft9I57ZVyywSL(8l26ftMLwZekaQeepDDmdruWI5zXwV4EfuQDt89HHUiMaOvya6LJyCPIl3ITEXuV4EfuQDt89HHUigcZ4sfxUfB9IjZsRzcfavcINUoMHikyX8SyEwmpOHZkxtmHcGkbbrjFuGOKpfGGhnKtTBcdXlA4aviGsrd7mooF)xmUhq7ZMrd1f1FOr)xmt8aGCbkquYNIqWJgYP2nHH4fnuxu)Hg01XmerbOrDHaazZHP4qJOC5iubXs0OUqaGS5Wu00cR0qqd(OHduHakfniZsRzcfavcINUoMHikyXuTy(OHlvRdn4JceL8NAe8OHCQDtyiErd1f1FObDDmdxtTcnQleaiBomfhAeLlhHkiwMm1U)BSpX57)IzS)w4ZM70X9FJ9jopDDmJDtjHpBMh0OUqaGS5Wu00cR0qqd(OHlvRdn4JceL8TOi4rd1f1FObjvzFctIhWmZADOHCQDtyiErbkqdhOcJJrqWJOKpcE0qo1UjmeVOXP0cAOtssvGsmC)fMNZm)jeaAOUO(dn0jjPkqjgU)cZZzM)ecafikTebpAiNA3egIx0qDr9hA4SY1(a8x5m2nLeOHWXjUWCkTGgoRCTpa)voJDtjbkqbkqJEbqQ)quAzElZNFk8ZJgjuWvhucAqHqp)GqylMcwS6I6Vf3ksq8Bx0GmloeLwo9uJgZGNRAcAK0fpsv2NyXwSGsiX2nPlonIzIfho4GwrAMT390Wrk6SMg1FoGYfWrkAhCB3KUyku1QfB50WUylZBz(T72nPlEIs1dQqS4B3KU4jSykogtylEun5CIF7M0fpHfpr)1lGqylouaujmf3IjwDHAr8B3KU4jS4j6VEbecBXHcGkHpkAXeVHvYIJFXrrlM4nSswCIubilwNNBLtTBIF7UDt6ITyArexwiSfBlCpqwS7PT1yX2c06i(ftX5CYCqw893esvanxwBXQlQ)il(VMv(TBsxS6I6pIFgiUN2wdiCnLKB7M0fRUO(J4NbI7PT1agiWX9pB7M0fRUO(J4NbI7PT1agiWPzqPLl0O(B7M0fpoDMK(XIbAXwSDghNWwmj0GSyBH7bYIDpTTgl2wGwhzX6Xw8mqMW8hrDqxCrwm7pXVDt6Ivxu)r8ZaX902Aade4iNots)WqcniBx1f1Fe)mqCpTTgWabU5pQ)2UQlQ)i(zG4EABnGbcC9kOu7Ma7P0ce66yg7MsctOaOsqG9NHqKa2ETLjq4A)dOM6P4NggDsbuH4tKwKzbqmpNjsfdtPpH5b6LJhk(uZhM8ElPiR1jfqfINikOoOgwPThAM4b6LJhE2UQlQ)i(zG4EABnGbcC9kOu7Ma7P0cesIzta0kma9YrmUuXLd2Fgcrcy71wMaHA(tiVppfzToPaQq8mrJutKcEH4b6LdM8ElTwNuavi(i9ZGMgMuf0lKqaEGE54XAQ5pH8(8wuR1jfqfIps)mOPHjvb9cjeGhOxoR1jfqfINikOoOgwPThAM4b6LJNTR6I6pIFgiUN2wdyGaxVck1UjWEkTaPpmbqRWa0lhX4sfxoy)ziejGTxBzceQ5pH8(8tXADsbuH4J0pdAAysvqVqcb4b6LBc595N2ADsbuH4jZviCznJopRGkQ)iEGE54z7QUO(J4NbI7PT1agiW1RGsTBcSNslq6ddDrmbqRWa0lhX4sfxoy)ziejGTxBzceQ5pH8(8uK16KcOcXZensnrk4fIhOxUjK3NpjwRtkGkeFK(zqtdtQc6fsiapqVCtiVp)0tBToPaQq8K5keUSMrNNvqf1FepqVC8yn18NqEFElPiR1jfqfIps)mOPHjvb9cjeGhOxoR1jfqfINikOoOgwPThAM4b6LJNTR6I6pIFgiUN2wdyGaxVck1UjWEkTaPpm0fXqygxQ4Yb7pdHibS9AltGWFc5955pfR1jfqfINikOoOgwPThAM4b6LB7QUO(J4NbI7PT1agiWrsv2NG7b0WwCqMy7moopjvzFcUhq7ZM3UQlQ)i(zG4EABnGbcCzeXuHqd7P0ceDssQcuIH7VW8CM5pHa2UQlQ)i(zG4EABnGbcC01Xm2nLeWwCqiZsRzcfavcINUoMHikWcw2PJoPaQq8r6NbnnmPkOxiHa8a9Ybj)2vDr9hXpde3tBRbmqGRxPNlq5mXN5s3UB3KUylMweXLfcBXsVaSAXrrllosLfRU4blUilw71QP2nXVDvxu)rGqQMCoz7QUO(Jade4YiIPcHMSDvxu)rGbcCZFu)bBXbXoJJZB3(N1YiHhiQl60jkAXeVHvIfGm1570juauj8PI2Iu)SlSqsME7QUO(Jade46vqP2nb2tPfiSpiMSzy)ziejGTxBzce2hEsQY(eMepGzM168r5Yvh0KzF47v65cuot8zUuFuUC1bD7QUO(Jade44kGy3(NbBXbXoJJZ3)fJ7b0(S5TR6I6pcmqGZwaebKRoOBx1f1FeyGaxRGMgeJfJmguA5ITR6I6pcmqGtpNqcG2moT1GT4GyNXX57)IX9aAF282vDr9hbgiWzRqnpNjaLlhz7QUO(Jade4azNrDr9NPvKa2tPfiUMO9cSfhe1fvVyKtOlHqf)TR6I6pcmqGdKDg1f1FMwrcypLwGqQdAtGT4GOUO6fJCcDjei83UB3KUykgrwmfQq)aRw8ZT4PAzUITykmquAYIbf00yX2c3dKfB1NTyfilwT)SyXXVyoT1w8Nfl(5w8u5lg3dO3UQlQ)iEhJaHwOFGvMNZ0YCfZWaIstGT4GqTDghNV)lg3dO9KqD5OYY8jxhrVkSYcqMoppD6qTldaKlm1r0RcRmmGwN1utnuhZtRweRTKhyuxu)5PRJzSBkj8oLeMOOfE4HQ6i6vHvBx1f1FeVJrGbcC2T)zMNZePIroH2QTR6I6pI3XiWaboOzkGv6zEoJoPa(if2IdIDghNV)lg3dO9KqD5OI)0Bx1f1FeVJrGbcCzeXuHqd7P0ceA9koHeV55m0k7ecb2IdczwAntOaOsq801XmerbubXYoDaAXmsVCHxzmIVoQOG8Bx1f1FeVJrGbcCCVlJimJoPaQqm2IsdBXbHmlTMjuaujiE66ygIOaQGyzNoaTygPxUWRmgXxhvuq(TR6I6pI3XiWabU5mqXzvDqn2nLeWwCqiZsRzcfavcINUoMHikGkiw2PdqlMr6Ll8kJr81rffKF7M0fpvPvSynwCtusSykGSyBjsiYTyNsI6GU4jAQUFXumIS4ivwmxbiXIDkjwmf3GIZIDXXVyOsS4kw8FlEIOWWU4ivUfl9cWQftYSjcfVzYfl2PKyXK0pRXwSTS4mIWwCIu5w8eL(GmYIFUftHCe9QWQfxKfRUO6Lf)GfxXItuT2IbIlvbqLfx3IJuzXNyrIfd1XGDXpyXrQS4qbqLyXfzXQ9Nflo(fZkXVDvxu)r8ogbgiW5(Zjxa0qygUMslW2Qtmogeka2Idsu0IfGWpFNouBNXX5DPpiJyEotDe9QWkpjuxoQGWF6KTZ4489FX4EaTpBMNoD4YAndqCPkaQyIIwSauhRtNOOft8gwjwy6TR6I6pI3XiWaboqnp3etDgYS6KTR6I6pI3XiWaboGOZ1b1W1uAHSDvxu)r8ogbgiWL4bnwVuNbiK)0ZjB3KUykgrwCKkezXU)BSpXrwCDl2wIeICl2QpdSy(KyX6XwSLhBXtLVylM3VflUUfB1NbwSLhBXtLVyCpGEXjsLBXw9zlov7LfprPpiJS4NBXuihrVkSAXQlQEz7QUO(J4DmcmqGZPTMrDr9NPvKa2tPfioqfghJaBXbHA7mooF)xmUhq7ZMt2oJJZ7sFqgX8CM6i6vHvEsOUCuzzEE60rNuaviEx6dYiMNZuhrVkSYd0lhK8B3KUykSWPzTyXCARzRUClM7bloJO2nzXvi0el(IPyezX)Ty3)n2N48Bx1f1FeVJrGbcCzeXuHqt2UBx1f1FeVRjAVaP)lMrazZr932vDr9hX7AI2lWaboMcYzuItos9hSfhe7mooF)xmUhq7zFIB7QUO(J4Dnr7fyGaxVspxGYzIpZLcBXbzIJYLRoOjRtkGkeFK(zqtdtQc6fsiapqVCubH)2vDr9hX7AI2lWabo66ygIOayloi2zCC(uf0lKqyMi9ZGMgeF282vDr9hX7AI2lWabU(Vyg7VfBx1f1FeVRjAVade4CARzuxu)zAfjG9uAbIJr2UQlQ)iExt0EbgiWrsv2NWK4bmdt0ifwNvUMycfavcce(WwCqIIwmXByLyHK0PJDghNV)lg3dO9SpXTDvxu)r8UMO9cmqGJKbaYXeGjEdTYoHqGT4GyNXX57)IX9aApjuxoQ4NhgQ5N3A7mooVD7FwlJe(SzE2UjDXumISykScYT4PYxSf)3INik8IZUMqilwzmYIvGS46CpDDqxCDlMFEYIFWIBcH43UQlQ)iExt0EbgiWXuqot)xmyloiaTygPxUWRmgXxhv8ZNm1Sp8KuL9jmjEaZmR15bchqiPQDt60jkAXeVHvcvjjppBx1f1FeVRjAVade4ORJzlhtaBx1f1FeVRjAVade4ORJzSBkjG1zLRjMqbqLGaHpSfheYS0AMqbqLG4PRJziIcSqVck1UjE66yg7MsctOaOsq2UQlQ)iExt0EbgiWrsv2NW4akjf2Idc1aTygPxUWRmgXxhvtNmqlMr6Ll8kJr8SmGg1FwWsE60bOfZi9YfELXiEwgqJ6pQSC7QUO(J4Dnr7fyGahjvzFctIhWmZADW6SY1etOaOsqGWh2IdYehAtUWtxebyLxo1UjSKbchqiPQDtsokAXeVHvcvut9e47TeMK4tI1KzP1mHcGkbXtxhZqefWJ19kOu7M4jjMnbqRWa0lhX4sfxoRPM)eY7ZZ3sR1jfqfINikOoOgwPThAM4b6LZAYS0AMqbqLG4PRJziIc4HNTR6I6pI31eTxGbcC9k9CbkNj(mxkSoRCnXekaQeei8HT4GaeoGqsv7MKCu0IjEdReQOMA(WKeFsSMmlTMjuaujiE66ygIOaESUxbLA3eFFycGwHbOxoIXLkUCwtnFyY75N3ADsbuH4jIcQdQHvA7HMjEGE5SMmlTMjuaujiE66ygIOaE4z7QUO(J4Dnr7fyGaxVspxGYzIpZLcRZkxtmHcGkbbcFyloiSp8KuL9jmjEaZmR15bchqiPQDtsM6qBYfE6IiaR8YP2nHLCu0IjEdReQOMA((8WyPpV1KzP1mHcGkbXtxhZqefWJ19kOu7M47ddDrmbqRWa0lhX4sfxoRPUxbLA3eFFyOlIHWmUuXLZAYS0AMqbqLG4PRJziIc4HhE2UQlQ)iExt0EbgiW1)fZepaixaBXbXoJJZ3)fJ7b0(S5TR6I6pI31eTxGbcC01XmerbWwCqiZsRzcfavcINUoMHikGk(W6s16GWh26cbaYMdtrtlSsdbcFyRleaiBomfhKOC5iubXYTR6I6pI31eTxGbcC01XmCn1kyDPADq4dBDHaazZHPOPfwPHaHpS1fcaKnhMIdsuUCeQGyzYu7(VX(eNV)lMX(BHpBUth3)n2N4801Xm2nLe(SzE2UQlQ)iExt0EbgiWrsv2NWK4bmZSw32D7QUO(J4DGkmogbsgrmvi0WEkTarNKKQaLy4(lmpNz(tiGTR6I6pI3bQW4yeyGaxgrmvi0WkCCIlmNslqCw5AFa(RCg7MsIT72vDr9hXtQdAtG0)fZiGS5O(B7QUO(J4j1bTjWaboMcYzuItos9hSfhe7mooF)xmUhq7zFIB7QUO(J4j1bTjWabU(Vyg7VfBx1f1FepPoOnbgiW50wZOUO(Z0ksa7P0cehJSDt6IPyezXuO1Xw8quWI)BXd4x8FnRwCXTyR(SfdvIfRlg(0pdAASykEuqVqcbSylwW7wCIksxSglUjkjwm)fpefuh0ftHlT9qZKfdpqRWVDvxu)r8K6G2eyGahDDmdruaSfhe7mooFQc6fsimtK(zqtdIpBoz3)n2N489FXm2Fl8aHwRJqfe((PtwNuaviEIOG6GAyL2EOzIhOxoQGWF7M0ftXiYIhtvu4fBlCpqwStNNRd6IDPkaQqGDXpyXrQS4qbqLyXfzXQ9Nflo(fZkXVDvxu)r8K6G2eyGahjvzFctIhWmmrJuyloiHcGkHpkAXeVHvIfssNoU)BSpX5jPk7tys8aMHjAK6DPkaQqGyzNou7(VX(eNNKQSpHjXdygMOrQ3LQaOcbc)KD)3yFIZtsv2NWK4bmdt0i1deAToIfG6yEA1IWZ2vDr9hXtQdAtGbcCKmaqoMamXBOv2jecSfhe7mooF)xmUhq7jH6Yrf)8Wqn)8wBNXX5TB)ZAzKWNnZZ2fMfN0ftXiYIPWki3INkFXw8FlEIOWlo7AcHSyLXilwbYIRZ901bDX1Ty(5jl(blUjeIF7QUO(J4j1bTjWaboMcYz6)IbBXbbOfZi9YfELXi(6OIF(TBsxmfJilMcToMTCmbSynwmFl6IFWIPFGSysOUCeyx8dwCXT4ivwCOaOsS4evRTywjlUUf3eczXrQElM)0e)2vDr9hXtQdAtGbcC01XSLJjayloiH2Kl801XSLJjaVCQDtyD6qTDghNV)lg3dO9KqD5OI)u3Ptu0IjEdRelWFAE2UQlQ)iEsDqBcmqGJKQSpHjXdygMOrkSfhKj2oJJZ3)fJ7b0(S5oDO29FJ9jopjvzFctIhWmmrJuVlvbqfcelt2oJJZ3)fJ7b0EsOUCwG)08SDt6IPyezXJuL9jw8ebus6I)BXtefEXzxtiKfhPcqwScKfRmgzX15E66G63UQlQ)iEsDqBcmqGJKQSpHXbuskSfheGwmJ0lx4vgJ4RJQPtgOfZi9YfELXiEwgqJ6plyz(TBsxmV6LBXrQS4rQY(elEQ6bml(INkFXwSlvbqfYI5EWI1fBxXIJFXbWQfRhBXA)xSf)9cWPZZ1bDX)TykKJOxfw53UQlQ)iEsDqBcmqGJUoMXUPKa2IdsVck1UjE2het2CYutnqlMr6Ll80FVqlx4RJkNsctu0cm59tNmqlMr6Ll80FVqlx4RZctHNoDM4qBYfEsQY(eMepGz6)I5LtTBcRth7mooF)xmUhq7zFIRth7mooF)xmUhq7jH6Yrf)PKm11r0RcRSafLVthxQcGkedhqDr9N2OIVpjjHNoDSZ4489FX4EaTNeQlNfGWFkjtDDe9QWklqb570XLQaOcXWbuxu)PnQ47tss4HNTR6I6pINuh0Made46)IzIhaKlGT4GW(Wtsv2NWK4bmZSwNhi0ADeQMsYSp89k9CbkNj(mxQhi0ADeQMsY2zCC((VyCpG2NnVDvxu)r8K6G2eyGahjvzFctIhWmZADWwCqachqiPQDtsokAXeVHvcvtj5jo0MCHNUicWkVCQDtyjpXH2Kl8mfKZ0)fZlNA3e22vDr9hXtQdAtGbcC9k9CbkNj(mxkSfheGWbesQA3KKJIwmXByLqff0Pd1H2Kl80fraw5LtTBclz2hEsQY(eMepGzM168aHdiKu1Uj8SDvxu)r8K6G2eyGahDDmdxtTcwxQwhe(Wwxiaq2CykAAHvAiq4dBDHaazZHP4GeLlhHkiwMm1U)BSpX57)IzS)w4ZM70X9FJ9jopDDmJDtjHpBMNTR6I6pINuh0Made4iPk7tys8aMzwRdfOaHa]] )


end
