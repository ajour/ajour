-- DemonHunterHavoc.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'DEMONHUNTER' then
    local spec = Hekili:NewSpecialization( 581 )

    spec:RegisterResource( Enum.PowerType.Pain, {
        metamorphosis = {
            aura = "metamorphosis",

            last = function ()
                local app = state.buff.metamorphosis.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 8,
        },
    } )

    -- Talents
    spec:RegisterTalents( {
        abyssal_strike = 22502, -- 207550
        agonizing_flames = 22503, -- 207548
        razor_spikes = 22504, -- 209400

        feast_of_souls = 22505, -- 207697
        fallout = 22766, -- 227174
        burning_alive = 22507, -- 207739

        flame_crash = 22324, -- 227322
        charred_flesh = 22541, -- 264002
        felblade = 22540, -- 232893

        soul_rending = 22508, -- 217996
        feed_the_demon = 22509, -- 218612
        fracture = 22770, -- 263642

        concentrated_sigils = 22546, -- 207666
        quickened_sigils = 22510, -- 209281
        sigil_of_chains = 22511, -- 202138

        gluttony = 22512, -- 264004
        spirit_bomb = 22513, -- 247454
        fel_devastation = 22768, -- 212084

        last_resort = 22543, -- 209258
        void_reaver = 22548, -- 268175
        soul_barrier = 21902, -- 263648
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3544, -- 208683
        relentless = 3545, -- 196029
        adaptation = 3546, -- 214027

        cleansed_by_flame = 814, -- 205625
        demonic_trample = 3423, -- 205629
        detainment = 3430, -- 205596
        everlasting_hunt = 815, -- 205626
        illidans_grasp = 819, -- 205630
        jagged_spikes = 816, -- 205627
        reverse_magic = 3429, -- 205604
        sigil_mastery = 1948, -- 211489
        solitude = 802, -- 211509
        tormentor = 1220, -- 207029
        unending_hatred = 3727, -- 213480
    } )


    -- Auras
    spec:RegisterAuras( {
        chaos_brand = {
            id = 281242,
            duration = 3600,
            max_stack = 1,
        },
        demon_spikes = {
            id = 203819,
            duration = 6,
            max_stack = 1,
        },
        demonic_wards = {
            id = 203513,
        },
        double_jump = {
            id = 196055,
        },
        feast_of_souls = {
            id = 207693,
            duration = 6,
            max_stack = 1,
        },
        fel_devastation = {
            id = 212084,
        },
        fiery_brand = {
            id = 207771,
            duration = function () return azerite.revel_in_pain.enabled and 10 or 8 end,
            max_stack = 1,
        },
        frailty = {
            id = 247456,
            duration = 26,
            type = "Magic",
            max_stack = 1,
        },
        glide = {
            id = 131347,
            duration = 3600,
            max_stack = 1,
        },
        immolation_aura = {
            id = 178740,
            duration = 6,
            max_stack = 1,
        },
        infernal_striking = {
            duration = 1,
            generate = function ()
                local is = buff.infernal_striking

                is.count = 1
                is.expires = last_infernal_strike + 1
                is.applied = last_infernal_strike
                is.caster = "player"
            end,
        },
        mana_divining_stone = {
            id = 227723,
            duration = 3600,
            max_stack = 1,
        },
        metamorphosis = {
            id = 187827,
            duration = 5,
            max_stack = 1,
        },
        shattered_souls = {
            id = 204254,
        },
        sigil_of_chains = {
            id = 204843,
            duration = function () return talent.concentrated_sigils.enabled and 8 or 6 end,
            max_stack = 1,
        },
        sigil_of_flame = {
            id = 204598,
            duration = function () return talent.concentrated_sigils.enabled and 8 or 6 end,
            max_stack = 1,
        },
        sigil_of_misery = {
            id = 207685,
            duration = function () return talent.concentrated_sigils.enabled and 22 or 20 end,
            max_stack = 1,
        },
        sigil_of_silence = {
            id = 204490,
            duration = function () return talent.concentrated_sigils.enabled and 8 or 6 end,
            max_stack = 1,
        },
        soul_barrier = {
            id = 263648,
            duration = 12,
            max_stack = 1,
        },
        soul_fragments = {
            id = 203981,
            duration = 3600,
            max_stack = 5,
        },
        spectral_sight = {
            id = 188501,
        },
        spirit_bomb = {
            id = 247454,
        },
        torment = {
            id = 185245,
            duration = 3,
            max_stack = 1,
        },
        void_reaver = {
            id = 268178,
            duration = 12,
            max_stack = 1,
        },


        -- PvP Talents
        demonic_trample = {
            id = 205629,
            duration = 3,
            max_stack = 1,
        },

        everlasting_hunt = {
            id = 208769,
            duration = 3,
            max_stack = 1,
        },

        focused_assault = {
            id = 206891,
            duration = 6,
            max_stack = 5,
        },

        illidans_grasp = {
            id = 205630,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },

        revel_in_pain = {
            id = 272987,
            duration = 15,
            max_stack = 1,
        },
    } )


    local sigils = setmetatable( {}, {
        __index = function( t, k )
            t[k] = 0
            return t[k]
        end
    } )

    spec:RegisterStateFunction( "create_sigil", function( sigil )
        sigils[ sigil ] = query_time + ( talent.quickened_sigils.enabled and 1 or 2 )
    end )

    spec:RegisterStateExpr( "soul_fragments", function ()
        return buff.soul_fragments.stack
    end )

    spec:RegisterStateExpr( "last_metamorphosis", function ()
        return action.metamorphosis.lastCast
    end )

    spec:RegisterStateExpr( "last_infernal_strike", function ()
        return action.infernal_strike.lastCast
    end )

    
    local activation_time = function ()
        return talent.quickened_sigils.enabled and 1 or 2
    end

    spec:RegisterStateExpr( "activation_time", activation_time )
    spec:RegisterStateExpr( "sigil_placed", activation_time )

    local sigil_placed = function ()
        return sigils.flame > query_time
    end

    spec:RegisterStateExpr( "sigil_placed", sigil_placed )
    -- Also add to infernal_strike, sigil_of_flame.

    spec:RegisterStateTable( "fragments", {
        real = 0,
        realTime = 0,
    } )

    spec:RegisterStateFunction( "queue_fragments", function( num )
        fragments.real = fragments.real + num
        fragments.realTime = GetTime() + 1.25
    end )

    spec:RegisterStateFunction( "purge_fragments", function()
        fragments.real = 0
        fragments.realTime = 0            
    end )


    local queued_frag_modifier = 0

    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceGUID == GUID then
            if subtype == "SPELL_CAST_SUCCESS" then
                -- Fracture:  Generate 2 frags.
                if spellID == 263642 then
                    queue_fragments( 2 ) end

                -- Shear:  Generate 1 frag.
                if spellID == 203782 then 
                    queue_fragments( 1 ) end

                --[[ Spirit Bomb:  Up to 5 frags.
                if spellID == 247454 then
                    local name, _, count = FindUnitBuffByID( "player", 203981 )
                    if name then queue_fragments( -1 * count ) end
                end

                -- Soul Cleave:  Up to 2 frags.
                if spellID == 228477 then 
                    local name, _, count = FindUnitBuffByID( "player", 203981 )
                    if name then queue_fragments( -1 * min( 2, count ) ) end
                end ]]

            -- We consumed or generated a fragment for real, so let's purge the real queue.
            elseif spellID == 203981 and fragments.real > 0 and ( subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_APPLIED_DOSE" ) then
                fragments.real = fragments.real - 1

            end
        end
    end )

    
    local sigil_types = { "chains", "flame", "misery", "silence" }

    spec:RegisterHook( "reset_precast", function ()
        last_metamorphosis = nil
        last_infernal_strike = nil
        
        for i, sigil in ipairs( sigil_types ) do
            local activation = ( action[ "sigil_of_" .. sigil ].lastCast or 0 ) + ( talent.quickened_sigils.enabled and 2 or 1 )
            if activation > now then sigils[ sigil ] = activation
            else sigils[ sigil ] = 0 end            
        end

        if talent.flame_crash.enabled then
            -- Infernal Strike is also a trigger for Sigil of Flame.
            local activation = ( action.infernal_strike.lastCast or 0 ) + ( talent.quickened_sigils.enabled and 2 or 1 )
            if activation > now and activation > sigils[ sigil ] then sigils.flame = activation end
        end

        if fragments.realTime > 0 and fragments.realTime < now then
            fragments.real = 0
            fragments.realTime = 0
        end

        if buff.demonic_trample.up then
            setCooldown( "global_cooldown", max( cooldown.global_cooldown.remains, buff.demonic_trample.remains ) )
        end

        if buff.illidans_grasp.up then
            setCooldown( "illidans_grasp", 0 )
        end

        if buff.soul_fragments.down then
            -- Apply the buff with zero stacks.
            applyBuff( "soul_fragments", nil, 0 + fragments.real )
        elseif fragments.real > 0 then
            addStack( "soul_fragments", nil, fragments.real )
        end
    end )

    spec:RegisterHook( "advance_end", function( time )
        if query_time - time < sigils.flame and query_time >= sigils.flame then
            -- SoF should've applied.
            applyDebuff( "target", "sigil_of_flame", debuff.sigil_of_flame.duration - ( query_time - sigils.flame ) )
            active_dot.sigil_of_flame = active_enemies
            sigils.flame = 0
        end
    end )


    -- Gear Sets
    spec:RegisterGear( "tier19", 138375, 138376, 138377, 138378, 138379, 138380 )
    spec:RegisterGear( "tier20", 147130, 147132, 147128, 147127, 147129, 147131 )
    spec:RegisterGear( "tier21", 152121, 152123, 152119, 152118, 152120, 152122 )
    spec:RegisterGear( "class", 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722 )

    spec:RegisterGear( "convergence_of_fates", 140806 )

    spec:RegisterGear( "achor_the_eternal_hunger", 137014 )
    spec:RegisterGear( "anger_of_the_halfgiants", 137038 )
    spec:RegisterGear( "chaos_theory", 151798 )
    spec:RegisterGear( "cloak_of_fel_flames", 137066 )
    spec:RegisterGear( "cinidaria_the_symbiote", 133976 )
    spec:RegisterGear( "delusions_of_grandeur", 144279 )
    spec:RegisterGear( "fragment_of_the_betrayers_prison", 138854 )
    spec:RegisterGear( "kirel_narak", 138949 )
    spec:RegisterGear( "loramus_thalipedes_sacrifice", 137022 )
    spec:RegisterGear( "moarg_bionic_stabilizers", 137090 )
    spec:RegisterGear( "oblivions_embrace", 151799 )
    spec:RegisterGear( "raddons_cascading_eyes", 137061 )
    spec:RegisterGear( "runemasters_pauldrons", 137071 )
    spec:RegisterGear( "soul_of_the_slayer", 151639 )
    spec:RegisterGear( "spirit_of_the_darkness_flame", 144292 )
        spec:RegisterAura( "spirit_of_the_darkness_flame", {
            id = 235543,
            duration = 3600,
            max_stack = 15
        } )


    -- Abilities
    spec:RegisterAbilities( {
        consume_magic = {
            id = 278326,
            cast = 0,
            cooldown = 10,
            gcd = "spell",

            startsCombat = true,
            texture = 828455,

            toggle = "interrupts",

            usable = function () return buff.dispellable_magic.up end,
            handler = function ()
                removeBuff( "dispellable_magic" )
                gain( buff.solitude.up and 22 or 20, "pain" )
            end,
        },


        demon_spikes = {
            id = 203720,
            cast = 0,
            charges = function () return ( ( level < 116 and equipped.oblivions_embrace ) and 3 or 2 ) end,
            cooldown = 20,
            recharge = 20,
            hasteCD = true,
            gcd = "off",

            defensive = true,

            startsCombat = false,
            texture = 1344645,

            toggle = "defensives",

            readyTime = function ()
                return max( 0, ( 1 + action.demon_spikes.lastCast ) - query_time )
            end, 
                -- ICD

            handler = function ()
                applyBuff( "demon_spikes", buff.demon_spikes.remains + buff.demon_spikes.duration )
            end,
        },


        demonic_trample = {
            id = 205629,
            cast = 0,
            charges = 2,
            cooldown = 12,
            recharge = 12,
            gcd = "spell",

            pvptalent = "demonic_trample",
            nobuff = "demonic_trample",

            startsCombat = false,
            texture = 134294,

            handler = function ()
                spendCharges( "infernal_strike", 1 )
                setCooldown( "global_cooldown", 3 )
                applyBuff( "demonic_trample" )
            end,
        },


        disrupt = {
            id = 183752,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            interrupt = true,

            startsCombat = true,
            texture = 1305153,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                gain( buff.solitude.up and 33 or 30, "pain" )
                interrupt()
            end,
        },


        fel_devastation = {
            id = 212084,
            cast = 2,
            fixedCast = true,
            channeled = true,
            cooldown = 60,
            gcd = "spell",

            -- toggle = "cooldowns",

            startsCombat = true,
            texture = 1450143,

            talent = "fel_devastation",

            start = function ()
                applyBuff( "fel_devastation" )
            end,
        },


        felblade = {
            id = 232893,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            spend = function () return buff.solitude.enabled and -33 or -30 end,
            spendType = "pain",

            startsCombat = true,
            texture = 1344646,

            talent = "felblade",

            handler = function ()
                setDistance( 5 )
            end,
        },


        fiery_brand = {
            id = 204021,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1344647,

            handler = function ()
                applyDebuff( "target", "fiery_brand" )
            end,
        },


        fracture = {
            id = 263642,
            cast = 0,
            charges = 2,
            cooldown = 4.5,
            recharge = 4.5,
            hasteCD = true,
            gcd = "spell",

            spend = function () return ( buff.solitude.up and -27 or -25 ) + ( buff.metamorphosis.up and -20 or 0 ) end,
            spendType = "pain",            

            startsCombat = true,
            texture = 1388065,

            handler = function ()
                -- gain( buff.solitude.up and 27 or 25, "pain" )
                addStack( "soul_fragments", nil, 2 )
            end,
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


        illidans_grasp = {
            id = function () return debuff.illidans_grasp.up and 208173 or 205630 end,
            known = 205630,
            cast = 0,
            cooldown = function () return buff.illidans_grasp.up and ( 54 + buff.illidans_grasp.remains ) or 0 end,
            gcd = "off",

            pvptalent = "illidans_grasp",
            aura = "illidans_grasp",
            breakable = true,
            channeled = true,

            startsCombat = true,
            texture = function () return buff.illidans_grasp.up and 252175 or 1380367 end,

            start = function ()
                if buff.illidans_grasp.up then removeBuff( "illidans_grasp" )
                else applyBuff( "illidans_grasp" ) end
            end,

            copy = { 205630, 208173 }
        },


        immolation_aura = {
            id = 178740,
            cast = 0,
            cooldown = 15,
            gcd = "spell",

            startsCombat = true,
            texture = 1344649,

            handler = function ()
                applyBuff( "immolation_aura" )

                if level < 116 and equipped.kirel_narak then
                    cooldown.fiery_brand.expires = cooldown.fiery_brand.expires - ( 2 * active_enemies )
                end

                if pvptalent.cleansed_by_flame.enabled then
                    removeDebuff( "player", "reversible_magic" )
                end
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


        infernal_strike = {
            id = 189110,
            cast = 0,
            charges = 2,
            cooldown = function () return talent.abyssal_strike.enabled and 12 or 20 end,
            recharge = function () return talent.abyssal_strike.enabled and 12 or 20 end,
            gcd = "off",

            startsCombat = true,
            texture = 1344650,

            nobuff = "infernal_striking",

            sigil_placed = sigil_placed,

            handler = function ()
                setDistance( 5 )
                spendCharges( "demonic_trample", 1 )
                applyBuff( "infernal_striking" )

                if talent.flame_crash.enabled then
                    create_sigil( "flame" )
                end
            end,
        },


        metamorphosis = {
            id = 187827,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1247263,

            handler = function ()
                applyBuff( "metamorphosis" )
                gain( 8, "pain" )

                if level < 116 and equipped.runemasters_pauldrons then
                    setCooldown( "sigil_of_chains", 0 )
                    setCooldown( "sigil_of_flame", 0 )
                    setCooldown( "sigil_of_misery", 0 )
                    setCooldown( "sigil_of_silence", 0 )
                    gainCharges( "demon_spikes", 1 )
                end

                last_metamorphosis = query_time
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


        shear = {
            id = 203782,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return ( buff.solitude.up and -11 or -10 ) + ( buff.metamorphosis.up and -20 or 0 ) end,
            spendType = "pain",

            startsCombat = true,
            texture = 1344648,

            notalent = "fracture",

            handler = function ()
                addStack( "soul_fragments", nil, 1 )
            end,
        },


        sigil_of_chains = {
            id = 202138,
            cast = 0,
            cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 90 end,
            gcd = "spell",

            startsCombat = true,
            texture = 1418286,

            talent = "sigil_of_chains",

            handler = function ()
                create_sigil( "chains" )

                if level < 116 and equipped.spirit_of_the_darkness_flame then
                    addStack( "spirit_of_the_darkness_flame", nil, active_enemies )
                end
            end,
        },


        sigil_of_flame = {
            id = function () return talent.concentrated_sigils.enabled and 204513 or 204596 end,
            known = 204596,
            cast = 0,
            cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 30 end,
            gcd = "spell",

            startsCombat = true,
            texture = 1344652,

            readyTime = function ()
                return sigils.flame - query_time
            end,

            sigil_placed = sigil_placed,

            handler = function ()
                create_sigil( "flame" )                
            end,

            copy = { 204596, 204513 }
        },


        sigil_of_misery = {
            id = function () return talent.concentrated_sigils.enabled and 202140 or 207684 end,
            known = 207684,
            cast = 0,
            cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 90 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 1418287,

            handler = function ()
                create_sigil( "misery" )
            end,

            copy = { 207684, 202140 }
        },


        sigil_of_silence = {
            id = function () return talent.concentrated_sigils.enabled and 207682 or 202137 end,
            known = 202137,
            cast = 0,
            cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 60 end,
            gcd = "spell",

            startsCombat = true,
            texture = 1418288,

            toggle = "interrupts",

            usable = function () return debuff.casting.remains > ( talent.quickened_sigils.enabled and 1 or 2 ) end,
            handler = function ()
                interrupt() -- early, but oh well.
                create_sigil( "silence" )
            end,

            copy = { 207682, 202137 },
        },


        soul_barrier = {
            id = 263648,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 2065625,

            talent = "soul_barrier",

            toggle = "defensives",

            handler = function ()
                if talent.feed_the_demon.enabled then
                    gainChargeTime( "demon_spikes", 0.5 * buff.soul_fragments.stack )
                end

                buff.soul_fragments.count = 0
                applyBuff( "soul_barrier" )
            end,
        },


        soul_cleave = {
            id = 228477,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "pain",

            startsCombat = true,
            texture = 1344653,

            handler = function ()
                if talent.feed_the_demon.enabled then
                    gainChargeTime( "demon_spikes", 0.5 * buff.soul_fragments.stack )
                end

                removeStack( "soul_fragments", min( buff.soul_fragments.stack, 2 ) )
                if talent.void_reaver.enabled then applyDebuff( "target", "void_reaver" ) end
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
            end,
        }, ]]


        spirit_bomb = {
            id = 247454,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "pain",

            startsCombat = true,
            texture = 1097742,

            buff = "soul_fragments",

            handler = function ()
                if talent.feed_the_demon.enabled then
                    gainChargeTime( "demon_spikes", 0.5 * buff.soul_fragments.stack )
                end

                buff.soul_fragments.count = 0
            end,
        },


        throw_glaive = {
            id = 204157,
            cast = 0,
            cooldown = 3,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 1305159,

            handler = function ()
            end,
        },


        torment = {
            id = 185245,
            cast = 0,
            cooldown = 8,
            gcd = "off",

            startsCombat = true,
            texture = 1344654,

            nopvptalent = "tormentor",

            handler = function ()
                applyDebuff( "target", "torment" )
            end,
        },


        tormentor = {
            id = 207029,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 1344654,

            pvptalent = "tormentor",

            handler = function ()
                applyDebuff( "target", "focused_assault" )
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

        potion = "superior_steelskin_potion",

        package = "Vengeance",
    } )


    spec:RegisterPack( "Vengeance", 20200124, [[dq0ADaqiGu9iksBsQKrjvQtjvXQqusVcrAwuIULuLAxG8lPIHHO6yavwgfXZOKmnkPCnku2gqk9nPkPXrjv15KQeRdOkEhfQkZdi5EaAFikoiLuzHaLhcKIjcuvxeOkzJuOQAKavPojfQYkbLDcelfrjEQuMQuvBLsQYEv5VcnyuomPfJWJrAYcUmXMv0Nby0uuNMQxdQmBuDBf2TOFR0WPGLd1ZHmDjxNsTDqvFNcz8ik15PewpfQmFeX(v1h4U(xlOLCGyc5Mqo5GZeRbrEVyf5gZyxRSWGCndkfofGCTuhY1SEscq0KkxZGAbF1W1)AO1gtLRzUkdiWtNoa8YSnbeDhDq(WMRLVjfRZQdYh0oxJW25LXlpIRf0soqmHCtiNCWzI1GiVxmPxmXyxdzqOhigZ6dURz2dbjpIRfee9AM(mRNKaenPYZaFzS5ZaVTZsWpmtFM5QmGapD6aWlZ2eq0D0b5dBUw(MuSoRoiFq78Wm9zW00wXw8mtmXYNzc5Mq(d7Hz6ZanM1eGGappmtFwVFM1fcs4zGVJW2gQNv7ZcYuT51ZuA5B(mUJkOhMPpR3pd0Sj8cUKWZSrs0lz8mjlSlONnx8ZkSNWjf6z1(mBKe9sgiJVNHLXcVeEgDZGx(MiOhMPpR3pZ6cbj8m0oKN5jDhEc4zbDOaKN15zuZkgG8mk2lb76ZQ9zGVm28zndoCcc6Hz6Z69ZilcsWWlptFg1SIbipBNpZ4LtbNk)zTc7WjptRNPC(ZkFiiOhMPpR3pZ6cbj8S2AZFgykg7cg6AgW705Y1m9zwpjbiAsLNb(YyZNbEBNLGFyM(mZvzabE60bGxMTjGO7OdYh2CT8nPyDwDq(G25Hz6ZGPPTIT4zMyILpZeYnH8h2dZ0NbAmRjabbEEyM(SE)mRleKWZaFhHTnupR2NfKPAZRNP0Y38zChvqpmtFwVFgOzt4fCjHNzJKOxY4zswyxqpBU4NvypHtk0ZQ9z2ij6LmqgFpdlJfEj8m6MbV8nrqpmtFwVFM1fcs4zODipZt6o8eWZc6qbipRZZOMvma5zuSxc21Nv7ZaFzS5ZAgC4ee0dZ0N17NrweKGHxEM(mQzfdqE2oFMXlNcov(ZAf2HtEMwpt58Nv(qqqpmtFwVFM1fcs4zT1M)mWum2fm0d7Hz6ZaViBHAxs4zeYCXYZO7GqRNria8eb9mRJsfdf6z5M92SIhtB(ZuA5BIE2MClGEyM(mLw(MiidyHUdcTao5kcUhMPptPLVjcYawO7Gqlsb2rTbmKS0Y38Hz6ZuA5BIGmGf6oi0IuGDM7gEyM(SwQgqM36zy1dpJWEoLWZqLwONriZflpJUdcTEgHaWt0Z0m8mdyP3g2Q8eWZC0ZcBkqpmtFMslFteKbSq3bHwKcSdkvdiZBfrLwOhMslFteKbSq3bHwKcSJnsIEjdltDiavJdzwXkko3SI7mAynsWpmLw(MiidyHUdcTifyhdB5B(WEyM(mWlYwO2LeEMaVGT4zLpKNvMLNP0AXpZrptHxDUsWfOhMslFteWGJW2gQhMslFtePa7q3ezpK4qb40hMslFtePa7yJKOxYa9WuA5BIifyhQY5rLw(MrUJkltDiajWAgS0NalLlzbrnRySeItUGmdjPsWLWdtPLVjIuGDOkNhvA5Bg5oQSm1Hamitjro8cYsFc0t6o8eqmOdfGengImK)WuA5BIifyhQY5rLw(MrUJkltDiaP7YdRrj6HP0Y3erkWouLZJkT8nJChvwM6qaMlEO8h2dZ0Nz87c2INbgwZWZilBPLV5dtPLVjcIaRzaiYb484oJtUoel9jq6U8WAucnDbBrKaRzacld1teOm5HP0Y3ebrG1mqkWoEofCQ8iQWoCIL(eiDxEynkHMUGTisG1maHLH6jci5pmLw(MiicSMbsb2z6c2IibwZWdtPLVjcIaRzGuGD8Xy5A5BgvBSAPpbg2cA6c2IibwZau5u48eWdtPLVjcIaRzGuGDMcpge4vuPLVPL(eyylOPlylIeyndqLtHZtapmLw(MiicSMbsb2XZPGtLhrf2HtS0NadBbnDbBrKaRzaQCkCEc4HP0Y3ebrG1mqkWoihGZJ7mo56qS0NadBbnDbBrKaRzaQCkCEc4H9Wm9zGMD5H1Oe9WuA5BIGO7YdRrjcOHT8nFykT8nrq0D5H1OerkWo0nPswyTKqCY1HyPpb2nOh2cIUjvYcRLeItUoKiHnoHkNcNNa6c0vA5Bcr3KkzH1scXjxhcKNXj3byUiHKPnNhXc1SIbiXYhcOaqdqdLS75HP0Y3ebr3LhwJsePa7y0I5b4fpJybTPMuXsFcKWEoH4(ui47gGqLsHduw9WuA5BIGO7YdRrjIuGDgYyXwe3zKBt9qmGfDGEyM(mWxMQnVE2u5CcLc3ZMl(z2iLGlptqijPcc6HP0Y3ebr3LhwJsePa7ywuCffessQ8WuA5BIGO7YdRrjIuGDSrs0lzyPmNcTIPoeGulO8TWB60ibxrLL(eiH9CcnKXITiUZi3M6Hyal6abfwJYhMslFteeDxEynkrKcSJnsIEjdltDiavKz41uqrSAClosxSYT0NadcH9CcHvJBXr6IvEmie2ZjuynkjHKGqypNq0nd20YHxIEcxmie2ZjKTHUkfdqkiZIYlZqgOfOScCKqs5djwBm4cOmH8hMPpd8LPAZRNnvoNqPW9S5IFMnsj4YZ8sgiOhMslFteeDxEynkrKcSJnsIEjd0d7Hz6ZaFzkjYHxqpmLw(MiOGmLe5WliGbzSzezWHtqw6tGDpT58iwOMvmajw(qaf46Yt6o8eqmOdfGeTc1djK0TslhEjkPmCbrgR6Yt6o8eqmOdfGeTc1fH9CcfKXMrKbhobbfwJYEiHKU9KUdpbed6qbirJHid5qMymYQzr5LzOHs298WuA5BIGcYusKdVGaIwBEKqXyxWw6tGDR0YHxIskdxqKXQU8KUdpbed6qbirRqDrypNqbzSzezWHtqqH1OShsiPBpP7WtaXGouas0yiYqoK1iRMfLxMHgkz3ZdtPLVjckitjro8cIuGDgsPJfBW8IC0dtPLVjckitjro8cIuGDMUGTisG1m8WEyM(mqw8q5pJSSLw(MpShMslFteuU4HYb65uWPYJOc7Wjw6tGtBopIfQzfdqILpeqbUU6g0lLlzbn56qIuSImdjPsWLajK0DyliKdW5XDgNCDiqyzOEIaLvDb6kT8nH8Ck4u5ruHD4eiKdW5rdCLkHE65HP0Y3ebLlEOCsb2bzWXEfj2bHL(ey3DtypNqdP0XInyErocY2qxO1MhNyfWqYcrgGw1djKGwBECIvadjlezaATEEykT8nrq5IhkNuGDqRnps5IcVyPpb2nOxkxYcczWXEfj2bbKKkbxcD1D3e2Zj0qkDSydMxKJGSn0fAT5XjwbmKSqKbOv9qcjO1MhNyfWqYcrgGwRNEEykT8nrq5IhkNuGDqRnps5IcVyPpbwkxYcczWXEfj2bbKKkbxcDHwBECIvadjleqYFykT8nrq5IhkNuGD8Xy5A5BgvBSAPpbAq9eua7fYFykT8nrq5IhkNuGDMcNGRbXsFc0G6jOa2RK)WuA5BIGYfpuoPa7mXkTSXIL(eiAT5XjwbmKSqGcOvpmLw(MiOCXdLtkWotHhdc8kQ0Y38HP0Y3ebLlEOCsb2b5aCECNXjxhYdtPLVjckx8q5KcSdYSO4hMslFteuU4HYjfyNYmEnkcGRo8Y1GxWiFZdeti3eYjhCMyTRzKItpbGUMXByyXLeEgO9zkT8nFg3rfc6HDn1UmV4R18bO5AChvOR)1iWAgU(hiG76FnjvcUeoWUgf7LGD9A0D5H1OeA6c2IibwZaewgQNONbQNzY1uA5BEnKdW5XDgNCDixDGyY1)AsQeCjCGDnk2lb761O7YdRrj00fSfrcSMbiSmuprpd4Zi)AkT8nVMNtbNkpIkSdNC1bIvx)RP0Y38AtxWwejWAgUMKkbxchyxDGyTR)1Kuj4s4a7AuSxc21Rf2cA6c2IibwZau5u48eW1uA5BEnFmwUw(Mr1gRxDGySR)1Kuj4s4a7AuSxc21Rf2cA6c2IibwZau5u48eW1uA5BETPWJbbEfvA5BE1bcO96FnjvcUeoWUgf7LGD9AHTGMUGTisG1mavofopbCnLw(MxZZPGtLhrf2HtU6aPxV(xtsLGlHdSRrXEjyxVwylOPlylIeyndqLtHZtaxtPLV51qoaNh3zCY1HC1vxlit1Mxx)deWD9VMslFZRfCe22qDnjvcUeoWU6aXKR)1uA5BEn6Mi7HehkaNEnjvcUeoWU6aXQR)1uA5BEnBKe9sgORjPsWLWb2vhiw76FnjvcUeoWUMslFZRrvopQ0Y3mYDuDnk2lb761kLlzbrnRySeItUGmdjPsWLW14oQIPoKRrG1mC1bIXU(xtsLGlHdSRP0Y38AuLZJkT8nJChvxJI9sWUEnpP7WtaXGouas0yONrMNr(14oQIPoKRfKPKihEbD1bcO96FnjvcUeoWUMslFZRrvopQ0Y3mYDuDnUJQyQd5A0D5H1OeD1bsVE9VMKkbxchyxtPLV51OkNhvA5Bg5oQUg3rvm1HCTCXdLF1vxZawO7GqRR)bc4U(xtsLGlHdSRL6qUMACiZkwrX5MvCNrdRrc(AkT8nVMACiZkwrX5MvCNrdRrc(QdetU(xtPLV51mSLV51Kuj4s4a7QRUgDxEynkrx)deWD9VMslFZRzylFZRjPsWLWb2vhiMC9VMKkbxchyxJI9sWUETUFgO)SWwq0nPswyTKqCY1HejSXju5u48eWZ66zG(ZuA5Bcr3KkzH1scXjxhcKNXj3byUEgjK8SPnNhXc1SIbiXYhYZa1ZaqdqdLSFwpxtPLV51OBsLSWAjH4KRd5QdeRU(xtsLGlHdSRrXEjyxVgH9CcX9PqW3naHkLc3Za1ZS6AkT8nVMrlMhGx8mIf0MAsLRoqS21)AkT8nV2qgl2I4oJCBQhIbSOd01Kuj4s4a7QdeJD9VMslFZRzwuCffessQCnjvcUeoWU6ab0E9VMKkbxchyxJI9sWUEnc75eAiJfBrCNrUn1dXaw0bckSgLxtPLV51Owq5BH30PrcUIQRjZPqRyQd5AulO8TWB60ibxr1vhi961)AsQeCjCGDTuhY1uKz41uqrSAClosxSYVMslFZRPiZWRPGIy14wCKUyLFnk2lb761ccH9CcHvJBXr6IvEmie2ZjuynkFgjK8SGqypNq0nd20YHxIEcxmie2ZjKTHN11ZkfdqkiZIYlZqgO1Za1ZScCpJesEw5djwBm4YZa1ZmH8RoqS(x)RP0Y38A2ij6LmqxtsLGlHdSRU6AbzkjYHxqx)deWD9VMKkbxchyxJI9sWUETUF20MZJyHAwXaKy5d5zG6zG7zD9mpP7WtaXGouas0k0Z65zKqYZ6(zkTC4LOKYWf0ZiZZS6zD9mpP7WtaXGouas0k0Z66ze2ZjuqgBgrgC4eeuynkFwppJesEw3pZt6o8eqmOdfGeng6zK5zKdzIXEgz9zMfLxMHgkz)SEUMslFZRfKXMrKbhobD1bIjx)RjPsWLWb21OyVeSRxR7NP0YHxIskdxqpJmpZQN11Z8KUdpbed6qbirRqpRRNrypNqbzSzezWHtqqH1O8z98msi5zD)mpP7WtaXGouas0yONrMNroK1Egz9zMfLxMHgkz)SEUMslFZRHwBEKqXyxWxDGy11)AkT8nV2qkDSydMxKJUMKkbxchyxDGyTR)1uA5BETPlylIeyndxtsLGlHdSRU6A5Ihk)6FGaUR)1Kuj4s4a7AuSxc21RnT58iwOMvmajw(qEgOEg4EwxpR7Nb6pRuUKf0KRdjsXkYmKKkbxcpJesEw3plSfeYb484oJtUoeiSmuprpdupZQN11Za9NP0Y3eYZPGtLhrf2HtGqoaNhnWvQeEwppRNRP0Y38AEofCQ8iQWoCYvhiMC9VMKkbxchyxJI9sWUETUFw3pJWEoHgsPJfBW8ICeKTHN11ZqRnpoXkGHKf6zKb4ZS6z98msi5zO1MhNyfWqYc9mYa8zw7z9CnLw(MxdzWXEfj2bXvhiwD9VMKkbxchyxJI9sWUETUFgO)Ss5swqido2RiXoiGKuj4s4zD9SUFw3pJWEoHgsPJfBW8ICeKTHN11ZqRnpoXkGHKf6zKb4ZS6z98msi5zO1MhNyfWqYc9mYa8zw7z98SEUMslFZRHwBEKYffE5QdeRD9VMKkbxchyxJI9sWUETs5swqido2RiXoiGKuj4s4zD9m0AZJtScyizHEgWNr(1uA5BEn0AZJuUOWlxDGySR)1Kuj4s4a7AuSxc21Rzq98zGc4Z6fYVMslFZR5JXY1Y3mQ2y9Qdeq71)AsQeCjCGDnk2lb761mOE(mqb8z9k5xtPLV51McNGRb5QdKE96FnjvcUeoWUgf7LGD9AO1MhNyfWqYc9mqb8zwDnLw(MxBIvAzJLRoqS(x)RP0Y38AtHhdc8kQ0Y38AsQeCjCGD1bsVC9VMslFZRHCaopUZ4KRd5AsQeCjCGD1bc4i)6FnLw(Mxdzwu81Kuj4s4a7QdeWbUR)1uA5BETYmEnkcGRo8Y1Kuj4s4a7QRU6QRUd]] )


end
