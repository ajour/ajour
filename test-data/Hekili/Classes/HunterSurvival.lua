-- HunterSurvival.lua
-- June 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'HUNTER' then
    local spec = Hekili:NewSpecialization( 255 )

    spec:RegisterResource( Enum.PowerType.Focus, {
        terms_of_engagement = {
            aura = "terms_of_engagement",

            last = function ()
                local app = state.buff.terms_of_engagement.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 2,
        }
    } )

    -- Talents
    spec:RegisterTalents( {
        vipers_venom = 22275, -- 268501
        terms_of_engagement = 22283, -- 265895
        alpha_predator = 22296, -- 269737

        guerrilla_tactics = 21997, -- 264332
        hydras_bite = 22769, -- 260241
        butchery = 22297, -- 212436

        trailblazer = 19347, -- 199921
        natural_mending = 19348, -- 270581
        camouflage = 23100, -- 199483

        bloodseeker = 22277, -- 260248
        steel_trap = 19361, -- 162488
        a_murder_of_crows = 22299, -- 131894

        born_to_be_wild = 22268, -- 266921
        posthaste = 22276, -- 109215
        binding_shot = 22499, -- 109248

        tip_of_the_spear = 22300, -- 260285
        mongoose_bite = 22278, -- 259387
        flanking_strike = 22271, -- 269751

        birds_of_prey = 22272, -- 260331
        wildfire_infusion = 22301, -- 271014
        chakrams = 23105, -- 259391
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        gladiators_medallion = 3568, -- 208683
        relentless = 3567, -- 196029
        adaptation = 3566, -- 214027

        trackers_net = 665, -- 212638
        roar_of_sacrifice = 663, -- 53480
        mending_bandage = 662, -- 212640
        hunting_pack = 661, -- 203235
        viper_sting = 3615, -- 202797
        sticky_tar = 664, -- 203264
        dragonscale_armor = 3610, -- 202589
        scorpid_sting = 3609, -- 202900
        spider_sting = 3608, -- 202914
        diamond_ice = 686, -- 203340
        hiexplosive_trap = 3606, -- 236776
        survival_tactics = 3607, -- 202746
    } )

    -- Auras
    spec:RegisterAuras( {
        a_murder_of_crows = {
            id = 131894,
            duration = 15,
            max_stack = 1,
        },
        aspect_of_the_cheetah = {
            id = 186258,
            duration = 9,
            max_stack = 1,
        },
        aspect_of_the_cheetah_sprint = {
            id = 186257, 
            duration = 3,
            max_stack = 1,
        },
        aspect_of_the_eagle = {
            id = 186289,
            duration = 15,
            max_stack = 1,
        },
        aspect_of_the_turtle = {
            id = 186265,
            duration = 8,
            max_stack = 1,
        },
        binding_shot = {
            id = 117405,
            duration = 3600,
            max_stack = 1,
        },
        camouflage = {
            id = 199483,
            duration = 60,
            max_stack = 1,
        },
        coordinated_assault = {
            id = 266779,
            duration = 20,
            max_stack = 1,
        },
        eagle_eye = {
            id = 6197,
        },
        feign_death = {
            id = 5384,
            duration = 360,
            max_stack = 1,
        },
        freezing_trap = {
            id = 3355,
            duration = 60,
            type = "Magic",
            max_stack = 1,
        },
        growl = {
            id = 2649,
            duration = 3,
            max_stack = 1,
        },
        harpoon = {
            id = 190927,
            duration = 3,
            max_stack = 1,
        },
        internal_bleeding = {
            id = 270343,
            duration = 9,
            max_stack = 3
        },
        intimidation = {
            id = 24394,
            duration = 5,
            max_stack = 1,
        },
        kill_command = {
            id = 259277,
            duration = 8,
            max_stack = 1,
            generate = function ()
                local kc = debuff.kill_command
                local name, _, count, _, duration, expires, caster = FindUnitDebuffByID( "target", 259277, "PLAYER" )

                if name then
                    kc.name = name
                    kc.count = 1
                    kc.expires = expires
                    kc.applied = expires - duration
                    kc.caster = caster
                    return
                end

                kc.count = 0
                kc.expires = 0
                kc.applied = 0
                kc.caster = "nobody"
            end,
            copy = "bloodseeker"
        },
        masters_call = {
            id = 54216,
            duration = 4,
            type = "Magic",
            max_stack = 1,
        },
        misdirection = {
            id = 35079,
            duration = 8,
            max_stack = 1,
        },
        mongoose_fury = {
            id = 259388,
            duration = 14,
            max_stack = 5,
        },
        pathfinding = {
            id = 264656,
            duration = 3600,
            max_stack = 1,
        },
        pheromone_bomb = {
            id = 270332,
            duration = 6,
            max_stack = 1,
        },
        posthaste = {
            id = 118922,
            duration = 4,
            max_stack = 1,
        },
        predator = {
            id = 260249,
            duration = 3600,
            max_stack = 2,
        },
        serpent_sting = {
            id = 259491,
            duration = function () return 12 * haste end,
            tick_time = function () return 3 * haste end,
            type = "Poison",
            max_stack = 1,
        },
        shrapnel_bomb = {
            id = 270339,
            duration = 6,
            max_stack = 1,
        },
        steel_trap = {
            id = 162480,
            duration = 20,
            max_stack = 1,
        },
        tar_trap = {
            id = 135299,
            duration = 3600,
            max_stack = 1,
        },
        terms_of_engagement = {
            id = 265898,
            duration = 10,
            max_stack = 1,
        },
        tip_of_the_spear = {
            id = 260286,
            duration = 10,
            max_stack = 3,
        },
        trailblazer = {
            id = 231390,
            duration = 3600,
            max_stack = 1,
        },
        vipers_venom = {
            id = 268552,
            duration = 8,
            max_stack = 1,
        },
        volatile_bomb = {
            id = 271049,
            duration = 6,
            max_stack = 1,
        },
        wildfire_bomb_dot = {
            id = 269747,
            duration = 6,
            max_stack = 1,
        },
        wildfire_bomb = {
            alias = { "wildfire_bomb_dot", "shrapnel_bomb", "pheromone_bomb", "volatile_bomb" },
            aliasType = "debuff",
            aliasMode = "longest"
        },
        wing_clip = {
            id = 195645,
            duration = 15,
            max_stack = 1,
        },

        -- AZERITE POWERS
        blur_of_talons = {
            id = 277969,
            duration = 6,
            max_stack = 5,
        },

        latent_poison = {
            id = 273286,
            duration = 20,
            max_stack = 10
        },

        primeval_intuition = {
            id = 288573,
            duration = 12,
            max_stack = 5,
        },
    } )


    spec:RegisterHook( "runHandler", function( action, pool )
        if buff.camouflage.up and action ~= "camouflage" then removeBuff( "camouflage" ) end
        if buff.feign_death.up and action ~= "feign_death" then removeBuff( "feign_death" ) end
    end )


    spec:RegisterStateExpr( "current_wildfire_bomb", function () return "wildfire_bomb" end )


    local function IsActiveSpell( id )
        local slot = FindSpellBookSlotBySpellID( id )
        if not slot then return false end

        local _, _, spellID = GetSpellBookItemName( slot, "spell" )
        return id == spellID 
    end

    state.IsActiveSpell = IsActiveSpell


    local pheromoneReset = false
    local FindUnitDebuffByID = ns.FindUnitDebuffByID

    spec:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", function ()
        local _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName = CombatLogGetCurrentEventInfo()

        if sourceGUID == state.GUID and spellID == 259489 and subtype == "SPELL_CAST_SUCCESS" then
            pheromoneReset = FindUnitDebuffByID( "target", 270332 ) and true or false
        end
    end )


    spec:RegisterHook( "reset_precast", function()
        if talent.wildfire_infusion.enabled then
            if IsActiveSpell( 270335 ) then current_wildfire_bomb = "shrapnel_bomb"
            elseif IsActiveSpell( 270323 ) then current_wildfire_bomb = "pheromone_bomb"
            elseif IsActiveSpell( 271045 ) then current_wildfire_bomb = "volatile_bomb"
            else current_wildfire_bomb = "wildfire_bomb" end                
        else
            current_wildfire_bomb = "wildfire_bomb"
        end

        if prev_gcd[1].kill_command and pheromoneReset and cooldown.kill_command.remains > 0 and ( now - action.kill_command.lastCast < 0.25 ) then
            setCooldown( "kill_command", 0 )
        end

        if now - action.harpoon.lastCast < 1.5 then
            setDistance( 5 )
        end
    end )

    spec:RegisterHook( "specializationChanged", function ()
        current_wildfire_bomb = nil
    end )

    spec:RegisterStateTable( "next_wi_bomb", setmetatable( {}, {
        __index = function( t, k )
            if k == "shrapnel" then return current_wildfire_bomb == "shrapnel_bomb"
            elseif k == "pheromone" then return current_wildfire_bomb == "pheromone_bomb"
            elseif k == "volatile" then return current_wildfire_bomb == "volatile_bomb" end
            return false
        end
    } ) )

    spec:RegisterStateTable( "bloodseeker", setmetatable( {}, {
        __index = function( t, k )
            if k == "count" then
                return active_dot.kill_command
            end

            return debuff.kill_command[ k ]
        end,
    } ) )


    spec:RegisterStateExpr( "bloodseeker", function () return debuff.bloodseeker end )


    -- Abilities
    spec:RegisterAbilities( {
        a_murder_of_crows = {
            id = 131894,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            toggle = "cooldowns",

            startsCombat = true,
            texture = 645217,

            talent = "a_murder_of_crows",

            handler = function ()
                applyDebuff( "target", "a_murder_of_crows" )
            end,
        },


        aspect_of_the_cheetah = {
            id = 186257,
            cast = 0,
            cooldown = function () return talent.born_to_be_wild.enabled and 144 or 180 end,
            gcd = "spell",

            startsCombat = false,
            texture = 132242,

            handler = function ()
                applyBuff( "aspect_of_the_cheetah_sprint" )
                applyBuff( "aspect_of_the_cheetah", 12 )
            end,
        },


        aspect_of_the_eagle = {
            id = 186289,
            cast = 0,
            cooldown = function () return talent.born_to_be_wild.enabled and 72 or 90 end,
            gcd = "off",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 612363,

            handler = function ()
                applyBuff( "aspect_of_the_eagle" )
            end,
        },


        aspect_of_the_turtle = {
            id = 186265,
            cast = 0,
            cooldown = function () return talent.born_to_be_wild.enabled and 144 or 180 end,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 132199,

            handler = function ()
                applyBuff( "aspect_of_the_turtle" )
                setCooldown( "global_cooldown", 8 )
            end,
        },


        binding_shot = {
            id = 109248,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = false,
            texture = 462650,

            handler = function ()
                applyDebuff( "target", "binding_shot" )
            end,
        },


        butchery = {
            id = 212436,
            cast = 0,
            charges = 3,
            cooldown = 9,
            recharge = 9,
            hasteCD = true,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 999948,

            aura = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,
            cycle = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,

            talent = "butchery",

            usable = function () return charges > 1 or active_enemies > 1 or target.time_to_die < ( 9 * haste ) end,
            handler = function ()
                gainChargeTime( "wildfire_bomb", min( 5, active_enemies ) )
                gainChargeTime( "shrapnel_bomb", min( 5, active_enemies ) )
                gainChargeTime( "volatile_bomb", min( 5, active_enemies ) )
                gainChargeTime( "pheromone_bomb", min( 5, active_enemies ) )

                if level < 116 and equipped.frizzos_fingertrap and active_dot.lacerate > 0 then
                    active_dot.lacerate = active_dot.lacerate + 1
                end

                if talent.birds_of_prey.enabled and buff.coordinated_assault.up and UnitIsUnit( "pettarget", "target" ) then
                    buff.coordinated_assault.expires = buff.coordinated_assault.expires + 1.5
                end

                if debuff.shrapnel_bomb.up then applyDebuff( "target", "internal_bleeding", 9, min( 3, debuff.internal_bleeding.stack + 1 ) ) end
            end,
        },


        camouflage = {
            id = 199483,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 461113,

            talent = "camouflage",

            usable = function () return time == 0 end,
            handler = function ()
                applyBuff( "camouflage" )
            end,
        },


        carve = {
            id = 187708,
            cast = 0,
            cooldown = 6,
            hasteCD = true,
            gcd = "spell",

            spend = 35,
            spendType = "focus",

            startsCombat = true,
            texture = 1376039,

            -- aura = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,
            -- cycle = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,

            notalent = "butchery",

            handler = function ()
                gainChargeTime( "wildfire_bomb", min( 5, active_enemies ) )
                gainChargeTime( "shrapnel_bomb", min( 5, active_enemies ) )
                gainChargeTime( "volatile_bomb", min( 5, active_enemies ) )
                gainChargeTime( "pheromone_bomb", min( 5, active_enemies ) )

                if level < 116 and equipped.frizzos_fingertrap and active_dot.lacerate > 0 then
                    active_dot.lacerate = active_dot.lacerate + 1
                end

                if debuff.shrapnel_bomb.up then applyDebuff( "target", "internal_bleeding", 9, min( 3, debuff.internal_bleeding.stack + 1 ) ) end

                if talent.birds_of_prey.enabled and buff.coordinated_assault.up and UnitIsUnit( "pettarget", "target" ) then
                    buff.coordinated_assault.expires = buff.coordinated_assault.expires + 1.5
                end
            end,
        },


        chakrams = {
            id = 259391,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 648707,

            talent = "chakrams",

            handler = function ()
            end,
        },


        coordinated_assault = {
            id = 266779,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 120 end,
            gcd = "spell",

            toggle = "cooldowns",

            startsCombat = false,
            texture = 2065565,

            nobuff = function ()
                if settings.ca_vop_overlap then return end
                return "coordinated_assault"
            end,

            usable = function () return pet.alive end,
            handler = function ()
                applyBuff( "coordinated_assault" )
            end,
        },


        disengage = {
            id = 781,
            cast = 0,
            charges = 1,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",

            startsCombat = false,
            texture = 132294,

            handler = function ()
                setDistance( 15 )
                if talent.posthaste.enabled then applyBuff( "posthaste" ) end
            end,
        },


        --[[ eagle_eye = {
            id = 6197,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 132172,

            handler = function ()
            end,
        }, ]]


        exhilaration = {
            id = 109304,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            toggle = "defensives",

            startsCombat = false,
            texture = 461117,

            handler = function ()
                gain( 0.3 * health.max, "health" )
            end,
        },


        feign_death = {
            id = 5384,
            cast = 0,
            cooldown = 30,
            gcd = "off",

            startsCombat = false,
            texture = 132293,

            handler = function ()
                applyBuff( "feign_death" )
            end,
        },


        flanking_strike = {
            id = 269751,
            cast = 0,
            cooldown = 40,
            gcd = "spell",

            startsCombat = true,
            texture = 236184,

            talent = "flanking_strike",

            usable = function () return pet.alive end,
            handler = function ()
                gain( 30, "focus" )
            end,
        },


        --[[ flare = {
            id = 1543,
            cast = 0,
            cooldown = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 135815,

            handler = function ()
            end,
        }, ]]


        freezing_trap = {
            id = 187650,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 135834,

            handler = function ()
                applyDebuff( "target", "freezing_trap" )
            end,
        },


        harpoon = {
            id = 190925,
            cast = 0,
            charges = 1,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",

            startsCombat = true,
            texture = 1376040,

            usable = function () return settings.use_harpoon and target.distance > 8 end,
            handler = function ()
                applyDebuff( "target", "harpoon" )
                if talent.terms_of_engagement.enabled then applyBuff( "terms_of_engagement" ) end
                setDistance( 5 )
            end,
        },


        intimidation = {
            id = 19577,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 132111,

            usable = function () return pet.alive end,
            handler = function ()
                applyDebuff( "target", "intimidation" )
            end,
        },


        kill_command = {
            id = 259489,
            cast = 0,
            charges = function () return talent.alpha_predator.enabled and 2 or nil end,
            cooldown = 6,
            recharge = 6,
            hasteCD = true,
            gcd = "spell",

            spend = -15,
            spendType = "focus",

            startsCombat = true,
            texture = 132176,

            cycle = function () return talent.bloodseeker.enabled and "kill_command" or nil end,

            usable = function () return pet.alive end,
            handler = function ()
                if talent.bloodseeker.enabled then
                    applyBuff( "predator", 8 )
                    applyDebuff( "target", "kill_command", 8 )
                end
                if talent.tip_of_the_spear.enabled then addStack( "tip_of_the_spear", 20, 1 ) end

                if debuff.pheromone_bomb.up then 
                    if talent.alpha_predator.enabled then gainCharges( "kill_command", 1 )
                    else setCooldown( "kill_command", 0 ) end
                end

                if debuff.shrapnel_bomb.up then applyDebuff( "internal_bleeding", 9, min( 3, debuff.internal_bleeding.stack + 1 ) ) end
            end,
        },


        masters_call = {
            id = 272682,
            cast = 0,
            cooldown = 45,
            gcd = "off",

            startsCombat = false,
            texture = 236189,

            usable = function () return pet.alive end,
            handler = function ()
                applyBuff( "masters_call" )
            end,
        },


        misdirection = {
            id = 34477,
            cast = 0,
            cooldown = 30,
            gcd = "off",

            startsCombat = false,
            texture = 132180,

            handler = function ()
                applyBuff( "misdirection" )
            end,
        },


        mongoose_bite = {
            id = 259387,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 1376044,

            aura = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,
            cycle = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,

            talent = "mongoose_bite",

            handler = function ()
                if buff.mongoose_fury.down then applyBuff( "mongoose_fury" )
                else applyBuff( "mongoose_fury", buff.mongoose_fury.remains, min( 5, buff.mongoose_fury.stack + 1 ) ) end
                if debuff.shrapnel_bomb.up then
                    if debuff.internal_bleeding.up then applyDebuff( "target", "internal_bleeding", 9, debuff.internal_bleeding.stack + 1 ) end
                end

                removeDebuff( "target", "latent_poison" )

                if azerite.wilderness_survival.enabled then
                    gainChargeTime( "wildfire_bomb", 1 )
                    if talent.wildfire_infusion.enabled then
                        gainChargeTime( "shrapnel_bomb", 1 )
                        gainChargeTime( "pheromone_bomb", 1 )
                        gainChargeTime( "volatile_bomb", 1 )
                    end
                end

                if azerite.primeval_intuition.enabled then
                    addStack( "primeval_intuition", nil, 1 )
                end

                if azerite.blur_of_talons.enabled and buff.coordinated_assault.up then
                    addStack( "blur_of_talons", nil, 1)
                end
            end,

            copy = { 265888, "mongoose_bite_eagle" }
        },


        muzzle = {
            id = 187707,
            cast = 0,
            cooldown = 15,
            gcd = "off",

            startsCombat = true,
            texture = 1376045,

            toggle = "interrupts",

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        pheromone_bomb = {
            -- id = 270323,            
            known = 259495,
            cast = 0,
            charges = function () return talent.guerrilla_tactics.enabled and 2 or nil end,
            cooldown = 18,
            recharge = 18,
            gcd = "spell",

            startsCombat = true,
            texture = 2065635,

            bind = "wildfire_bomb",
            talent = "wildfire_infusion",

            usable = function () return current_wildfire_bomb == "pheromone_bomb" end,
            handler = function ()
                applyDebuff( "target", "pheromone_bomb" )
                current_wildfire_bomb = "wildfire_bomb"
            end,
        },


        raptor_strike = {
            id = 186270,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 1376046,

            aura = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,
            cycle = function () return debuff.shrapnel_bomb.up and "internal_bleeding" or nil end,

            notalent = "mongoose_bite",

            handler = function ()
                removeBuff( "tip_of_the_spear" )

                if debuff.shrapnel_bomb.up then
                    if debuff.internal_bleeding.up then applyDebuff( "target", "internal_bleeding", 9, debuff.internal_bleeding.stack + 1 ) end
                end

                if talent.birds_of_prey.enabled and buff.coordinated_assault.up and UnitIsUnit( "pettarget", "target" ) then
                    buff.coordinated_assault.expires = buff.coordinated_assault.expires + 1.5
                end

                removeDebuff( "target", "latent_poison" )

                if azerite.wilderness_survival.enabled then
                    gainChargeTime( "wildfire_bomb", 1 )
                    if talent.wildfire_infusion.enabled then
                        gainChargeTime( "shrapnel_bomb", 1 )
                        gainChargeTime( "pheromone_bomb", 1 )
                        gainChargeTime( "volatile_bomb", 1 )
                    end
                end

                if azerite.primeval_intuition.enabled then
                    addStack( "primeval_intuition", nil, 1 )
                end

                if azerite.blur_of_talons.enabled and buff.coordinated_assault.up then
                    addStack( "blur_of_talons", nil, 1)
                end
            end,

            copy = { "raptor_strike_eagle", 265189 },
        },


        serpent_sting = {
            id = 259491,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.vipers_venom.up and 0 or 20 end,
            spendType = "focus",

            startsCombat = true,
            texture = 1033905,

            handler = function ()
                removeBuff( "vipers_venom" )
                applyDebuff( "target", "serpent_sting" )

                if azerite.latent_poison.enabled then
                    applyDebuff( "target", "latent_poison" )
                end
            end,
        },


        shrapnel_bomb = {
            -- id = 270335,
            known = 259495,
            cast = 0,
            charges = function () return talent.guerrilla_tactics.enabled and 2 or nil end,
            cooldown = 18,
            recharge = 18,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 2065637,

            bind = "wildfire_bomb",

            usable = function () return current_wildfire_bomb == "shrapnel_bomb" end,
            handler = function ()
                applyDebuff( "target", "shrapnel_bomb" )
                current_wildfire_bomb = "wildfire_bomb"
            end,
        },


        steel_trap = {
            id = 162488,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 1467588,

            handler = function ()
                applyDebuff( "target", "steel_trap" )
            end,
        },


        summon_pet = {
            id = 883,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0,
            spendType = "focus",

            startsCombat = false,
            texture = 'Interface\\ICONS\\Ability_Hunter_BeastCall',

            essential = true,
            nomounted = true,

            usable = function () return not pet.exists end,
            handler = function ()
                summonPet( 'made_up_pet', 3600, 'ferocity' )
            end,
        },


        tar_trap = {
            id = 187698,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 576309,

            handler = function ()
                applyDebuff( "target", "tar_trap" )
            end,
        },


        volatile_bomb = {
            -- id = 271045,
            known = 259495,
            cast = 0,
            charges = function () return talent.guerrilla_tactics.enabled and 2 or nil end,
            cooldown = 18,
            recharge = 18,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = 2065636,

            bind = "wildfire_bomb",

            usable = function () return current_wildfire_bomb == "volatile_bomb" end,
            handler = function ()
                if debuff.serpent_sting.up then applyDebuff( "target", "serpent_sting" ) end
                current_wildfire_bomb = "wildfire_bomb"
            end,
        },


        wildfire_bomb = {
            id = function ()
                if current_wildfire_bomb == "wildfire_bomb" then return 259495
                elseif current_wildfire_bomb == "pheromone_bomb" then return 270323
                elseif current_wildfire_bomb == "shrapnel_bomb" then return 270335
                elseif current_wildfire_bomb == "volatile_bomb" then return 271045 end 
                return 259495
            end,
            flash = { 270335, 270323, 271045, 259495 },
            known = 259495,
            cast = 0,
            charges = function () return talent.guerrilla_tactics.enabled and 2 or nil end,
            cooldown = 18,
            recharge = 18,
            hasteCD = true,
            gcd = "spell",

            startsCombat = true,
            texture = function ()
                local a = current_wildfire_bomb and current_wildfire_bomb or "wildfire_bomb"
                if a == "wildfire_bomb" or not action[ a ] then return 2065634 end                
                return action[ a ].texture
            end,

            aura = "wildfire_bomb",
            bind = function () return current_wildfire_bomb end,

            usable = function () return current_wildfire_bomb ~= "pheromone_bomb" or debuff.serpent_sting.up end,
            handler = function ()
                if current_wildfire_bomb ~= "wildfire_bomb" then
                    runHandler( current_wildfire_bomb )
                    current_wildfire_bomb = "wildfire_bomb"
                    return
                end
                applyDebuff( "target", "wildfire_bomb_dot" )
            end,

            copy = { 271045, 270335, 270323, 259495 }
        },


        wing_clip = {
            id = 195645,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 30,
            spendType = "focus",

            startsCombat = true,
            texture = 132309,

            handler = function ()
                applyDebuff( "target", "wing_clip" )
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

        potion = "unbridled_fury",

        package = "Survival"
    } )

    
    spec:RegisterSetting( "use_harpoon", true, {
        name = "|T1376040:0|t Use Harpoon",
        desc = "If checked, the addon will recommend |T1376040:0|t Harpoon when you are out of range and Harpoon is available.",
        type = "toggle",
        width = 1.49
    } )
    
    spec:RegisterSetting( "ca_vop_overlap", false, {
        name = "|T2065565:0|t Coordinated Assault Overlap (Vision of Perfection)",
        desc = "If checked, the addon will recommend |T2065565:0|t Coordinated Assault even if the buff is already applied due to a Vision of Perfection proc.\n" ..
            "This may be preferred when delaying Coordinated Assault would cost you one or more uses of Coordinated Assault in a given fight.",
        type = "toggle",
        width = "full"
    } )

    spec:RegisterPack( "Survival", 20200525, [[dOKn)bqiiWJueLlrOKQnPq(eKkOrjc1PerSkrKELIQzjcULik2fP(fbmmrihdISmcfptevttrexdcABkI03erPgNIO6CqQO1rOeZdI6Ee0(Gu1bHuHwib6HekjUiHsHpsOKIrsOKsNKqPuRecntivGBsOuzNqIHsOKulLqPQNQQMkK0xjusYyjukzVq9xIgmjhMYIvXJrmzrDzuBMQ(SinAfLtlz1IOKxdPmBQCBvz3k9BPgUcooHsrlh0ZbMUW1vPTRi9DfQXRiCEcvRhsLMpHSFKgJegv8pBbJrrmjsmjkriumiuJuIqk5tYKG)H4dm(pye0Sug)x7X4))cNwtnh(pyI7AlJrf)b9fsy8FwedaXIacKwXS7rt6NaG6DDwu9sGMpeaupIa4)5wUqS9Ip4F2cgJIysKysuIqOyqOgPeHuYNeXG)2nM1q8)xVRZIQxXkqZh4)SkN5fFW)mdi4)Krv)lCAn1CuLyT3nyifXjJQMfXaqSiGaPvm7E0K(jaOExNfvVeO5dba1JiafXjJQe7mXPkXGWeOkXKiXKikIueNmQsSYmBtzGyHI4KrvjdvHoMZCMQe7UOl66yQkAQkZE76cQYir1lv5kqOPiozuvYqvIvMzBkNPQWGPCilpvXtmazaO6fqvrtveXjowggmLdGMI4Krvjdvj215YxCMQigCkljzivfnvnUHOrvVgYufBGYjovnUIzuvmJPklN7fDiGQQ3GJF8gwu9svTNQMAWYoowtrCYOQKHQqhZzotv3OCviovHokwn6an(7kqaWOI)2aiWOIrbjmQ4pV2XXzSG4pbwbdld)pxVxt6gMR1colnaWUUqFhOQruvIPQZ171KUH5ATGZsdaSRl0q(z1cOkKPkK0iKQskvLsYuLiru15696J7cLTxgMRxG(oqvJOQZ171h3fkBVmmxVanKFwTaQczQcjncPQKsvPKmvLe83ir1l()6nTBalpvW4aJIyWOI)8AhhNXcI)eyfmSm8)C9EnPByUwl4S0aa76c9DGQgrvjMQoxVxt6gMR1colnaWUUqd5NvlGQqMQqsJqQkPuvkjtvIervNR3RpUlu2EzyUEb67avnIQoxVxFCxOS9YWC9c0q(z1cOkKPkK0iKQskvLsYuvsWFJevV4p0gIgkbbSqJXbgLKJrf)51oooJfe)jWkyyz4VVjxavnNQigiKqoLxQczQY3Klq)SjWFJevV4V3zlA1MkbbSqJXbgLjbJk(ZRDCCgli(BKO6f)rRCojPFpBZ4pbwbdld)9xNtczYmdMYYOEmvHmvHKgHuvsPQusMQgrv(MCbu1CQIyGqc5uEPkKPkFtUa9ZMa)jItCSmmykhamkiHdmkieJk(ZRDCCgli(tGvWWYWFFtUaQAovrmqiHCkVufYuLVjxG(ztG)gjQEXFqWStgqBahyuMumQ4pV2XXzSG4pbwbdld)9n5cOQ5ufXaHeYP8svitv(MCb6NnbvnIQqavffbTAtPQrufcOQZ171p(1qXLTx6UKklZq2Ea9DGQgrvjMQ8xNtczYmdMYYOEmvHmvHKgHuvsPQusMQejIQqavL7qpUCzFbz5PFhDue0QnLQgrviGQoxVxt6gMR1colnaWUUqFhOkrIOkeqv5o0Jlx2xqwE63rhfbTAtPQru15696xVPDdyP)cfxdcJGgvHmvHevLeQsKiQkQhlJwMlMQqMQqAYPQrufcOQCh6XLl7lilp97OJIGwTP4VrIQx8FC5Y(cYYt)o4aJsYgJk(ZRDCCgli(tGvWWYWFeqv5o0agoWBibrTP6OiOvBkvnIQqavDUEVM0nmxRfCwAaGDDH(oG)gjQEXFadh4nKGO2uCGrzYXOI)8AhhNXcI)gjQEXF0kNts63Z2m(tGvWWYWFFtUaQAovrmqiHCkVufYuLVjxG(ztqvJOQetvNR3RF9M2nGL(luCnimcAufYufcPkrIOkFtUaQczQYir1R(1BA3awEQG1KgeuvsWFI4ehlddMYbaJcs4aJc6eJk(ZRDCCgli(tGvWWYWFi7HmyMDCmvnIQqavDUEVM0nmxRfCwAaGDDH(oqvJOQZ171VEt7gWs)fkUgegbnQczQcH4VrIQx8hWWbEdjiQnfhyuqkryuXFETJJZybXFcScgwg(JaQ6C9EnPByUwl4S0aa76c9Da)nsu9I)M8DHzgkBVKa7XaCGrbjKWOI)8AhhNXcI)eyfmSm8hbu1569As3WCTwWzPba21f67a(BKO6f)jDdZ1AbNLgayxxGdmkijgmQ4pV2XXzSG4pbwbdld)pxVx)6nTBal9xO467avjsev5BYfqvZPkIbcjKt5LQqpv5BYfOF2euvYqviLiQsKiQ6C9EnPByUwl4S0aa76c9Da)nsu9I)VEt7gWYtfmoWOGuYXOI)gjQEXFOnenuccyHgJ)8AhhNXcIdmkinjyuXFETJJZybXFcScgwg(JaQkkcA1MI)gjQEX)XLl7lilp97GdCG)ehBtzmQyuqcJk(ZRDCCgli(3d4pGJYJ)gjQEX)PgSSJJX)PguU2JXFIbNYssgI)eyfmSm83irnLL8YVIbufYufcX)PM7Ys2by8hH4)uZDz83irnLL8YVIb4aJIyWOI)8AhhNXcI)eyfmSm83qxgwbRpUlu2EzyUEbAOTOrvONQsevnIQsmvDUEVM0nmxRfCwAaGDDH(oqvJOQetvNR3RjDdZ1AbNLgayxxOH8ZQfqvitviPrivLuQkLKPkrIOQZ171h3fkBVmmxVa9DGQgrvNR3RpUlu2EzyUEbAi)SAbufYufsAesvjLQsjzQsKiQ6C9EnPByUwl4S0aa76cnKFwTaQAevHaQ6C9E9XDHY2ldZ1lqd5NvlGQscvLe83ir1l()6nTBalpvW4aJsYXOI)8AhhNXcI)gjQEX)xVPDdy5Pcg)jWkyyz4FMpxVx7SG3qo0fOxnimcAuf6PQetvgjQPSKx(vmGQejIQqNuvsOQruvyWuo0r9yz0YCXufYuLrIAkl5LFfdOQKsvPKm(hgmLdz5XFCGrzsWOI)gjQEXFt(UWmdLTxsG9ya(ZRDCCglioWOGqmQ4VrIQx8N0nmxRfCwAaGDDb(ZRDCCglioWOmPyuXFETJJZybXFcScgwg(N7qdMbTHLDYt)o6OiOvBkvnIQqavfMJ3qpt8m0aYtfSMx744mvjsevL7qdMbTHLDYt)o6OiOvBkvnIQmsutzjV8RyavHEQcH4VrIQx8NyWPmoWOKSXOI)8AhhNXcI)eyfmSm8hbuvyoEdD6LHWY5mzyKOianV2XXzQsKiQYFDojKjZmyklJ6XufYuvkjtvIervqRYsEkVH2YzGgYpRwavHmvnPu1iQcAvwYt5n0wod08efia4VrIQx8FC5Y(cYYt)o4aJYKJrf)51oooJfe)jWkyyz4pzMbtzG0dnsu9AoQc9uLy0iKQejIQYDObZG2WYo5PFhDue0QnLQejIQiD7Y94vpUCzFbz5PFhnKFwTaQc9uLrIAkl5LFfdOQKHQsjzQsKiQkZNR3RpUUZY2lJzSKx(jUgYpRwavjsevbTkl5P8gAlNbAi)SAbufYufcPQruf0QSKNYBOTCgO5jkqaWFJevV4)5gKzmuCCGrbDIrf)51oooJfe)nsu9I)VEt7gWYtfm(tGvWWYW)mFUEV2zbVHCOlqVAqye0Ok0tvto(hgmLdz5XFCGrbPeHrf)nsu9I)KzgAq7bWFETJJZybXbgfKqcJk(ZRDCCgli(BKO6f)rRCojPFpBZ4pbwbdld)9n5cOQ5ufXaHeYP8svitv(MCb6Nnb(teN4yzyWuoayuqchyuqsmyuXFETJJZybXFcScgwg(hMJ3qhm8bKTxYBQLYpEdnV2XXz83ir1l(pZGdDV4aJcsjhJk(ZRDCCgli(tGvWWYW)WC8g60ldHLZzYWirraAETJJZ4VrIQx8NyWPmoWOG0KGrf)51oooJfe)jWkyyz4pPBxUhV6XLl7lilp97OH8ZQfqvONQsmvzKOMYsE5xXaQsKiQcHuvsWFJevV4)5gKzmuCCGrbjeIrf)51oooJfe)jWkyyz4VVjxavnNQigiKqoLxQczQY3Klq)SjWFJevV4V3zlA1MkbbSqJXbgfKMumQ4pV2XXzSG4pbwbdld)ZDOhxUSVGS80VJgYEidMzhhtvIervH54n0Jlx2xqwwR)cQE18AhhNXFJevV4)4YL9fKLN(DWbgfKs2yuXFETJJZybXFJevV4pGHd8gsquBk(tGvWWYW)Z171tRbgcKt5TFAiBKa)jItCSmmykhamkiHdmkin5yuXFETJJZybXFcScgwg(t62L7XREC5Y(cYYt)oAi)SAbuf6PQPgSSJJ1edoLLKmKQeRtvIb)nsu9I)edoLXbgfKqNyuXFJevV4piy2jdOnG)8AhhNXcIdmkIjryuXFETJJZybXFJevV4pGHd8gsquBk(tGvWWYWFi7HmyMDCmvnIQoxVxh1GS9YyglbdSb1GWiOrvitvjNQgrvlprihxYt)o6PTZIYXuLirufK9qgmZooMQgrvg6YWkyTZcEd5qxGE1qBrJQqpvLi8NioXXYWGPCaWOGeoWOigKWOI)8AhhNXcI)gjQEX)xVPDdy5Pcg)jItCSmmykhamkiHdmkIrmyuXFETJJZybXFJevV4p0gIgkbbSqJXFI4ehlddMYbaJcs4ah4piWOIrbjmQ4pV2XXzSG4pbwbdld)dZXBOdg(aY2l5n1s5hVHMx744m(BKO6f)NzWHUxCGrrmyuXFETJJZybXFcScgwg(7BYfqvZPkIbcjKt5LQqMQ8n5c0pBc83ir1l(7D2IwTPsqal0yCGrj5yuXFETJJZybXFcScgwg(FUEVM0nmxRfCwAaGDDH(oqvJOQetvNR3RjDdZ1AbNLgayxxOH8ZQfqvitviPrivLuQkLKPkrIOQZ171h3fkBVmmxVa9DGQgrvNR3RpUlu2EzyUEbAi)SAbufYufsAesvjLQsjzQkj4VrIQx8hAdrdLGawOX4aJYKGrf)51oooJfe)jWkyyz4)569As3WCTwWzPba21f67avnIQsmvDUEVM0nmxRfCwAaGDDHgYpRwavHmvHKgHuvsPQusMQejIQoxVxFCxOS9YWC9c03bQAevDUEV(4Uqz7LH56fOH8ZQfqvitviPrivLuQkLKPQKG)gjQEX)xVPDdy5Pcghyuqigv8Nx744mwq83ir1l(Jw5Css)E2MXFcScgwg(7BYfqvZPkIbcjKt5LQqMQ8n5c0pBc8NioXXYWGPCaWOGeoWOmPyuXFETJJZybXFcScgwg(FUEVEAnWqGCkV9tFhOQru15696P1adbYP82pnKFwTaQczQcjQkPuvkjJ)gjQEXFadh4nKGO2uCGrjzJrf)51oooJfe)jWkyyz4VVjxavnNQigiKqoLxQczQY3Klq)SjWFJevV4piy2jdOnGdmktogv8Nx744mwq8NaRGHLH)(MCbu1CQIyGqc5uEPkKPkFtUa9ZMGQgrvq2dzWm74yQAev5VoNeYKzgmLLr9yQczQkLKPQrufcOQZ171p(1qXLTx6UKklZq2Ea9DGQejIQ8n5cOQ5ufXaHeYP8svitv(MCb6NnbvnIQsmvHaQk3HEC5Y(cYYt)o6OiOvBkvnIQsmvHaQ6C9EnPByUwl4S0aa76c9DGQejIQoxVx)6nTBal9xO4Aqye0OkKPkKOkrIOQOESmAzUyQczQcPjNQejIQqavL7qpUCzFbz5PFhDue0QnLQgrvg6YWky94YLz4YaGeCHtRPMtdTfnQc9uvIOQKqvjHQgrviGQoxVx)4xdfx2EP7sQSmdz7b03b83ir1l(pUCzFbz5PFhCGrbDIrf)51oooJfe)jWkyyz4)5696P1adbYP82p9DGQgrv5o0agoWBibrTPAi)SAbufYu1KqvjLQsjzQsKiQk3HgWWbEdjiQnvdzpKbZSJJPQrufcOQZ171KUH5ATGZsdaSRl03b83ir1l(dy4aVHee1MIdmkiLimQ4pV2XXzSG4pbwbdld)ravDUEVM0nmxRfCwAaGDDH(oG)gjQEXFt(UWmdLTxsG9yaoWOGesyuXFETJJZybXFcScgwg(JaQ6C9EnPByUwl4S0aa76c9Da)nsu9I)KUH5ATGZsdaSRlWbgfKedgv8Nx744mwq8NaRGHLH)NR3RF9M2nGL(luC9DGQejIQ8n5cOQ5ufXaHeYP8svONQ8n5c0pBcQkzOkXKiQAevfMJ3qpTgyiqoL3(P51oootvIerv(MCbu1CQIyGqc5uEPk0tv(MCb6NnbvLmufsu1iQkmhVHoy4diBVK3ulLF8gAETJJZuLiru1569As3WCTwWzPba21f67a(BKO6f)F9M2nGLNkyCGrbPKJrf)nsu9I)qBiAOeeWcng)51oooJfehyuqAsWOI)8AhhNXcI)eyfmSm8p3HEC5Y(cYYt)oAi7HmyMDCm(BKO6f)hxUSVGS80VdoWOGecXOI)8AhhNXcI)eyfmSm8)C9E90AGHa5uE7N(oG)gjQEXFadh4nKGO2uCGd8FSVWOIrbjmQ4pV2XXzSG4pbwbdld)9n5cOQ5ufXaHeYP8svitv(MCb6NnbvnIQcZXBOdg(aY2l5n1s5hVHMx744m(BKO6f)NzWHUxCGrrmyuXFETJJZybXFcScgwg(FUEV(4Uqz7LH56fOVdu1iQ6C9E9XDHY2ldZ1lqd5NvlGQqMQsjz83ir1l()6nTBalpvW4aJsYXOI)8AhhNXcI)eyfmSm8)C9E9XDHY2ldZ1lqFhOQru15696J7cLTxgMRxGgYpRwavHmvLsY4VrIQx8hAdrdLGawOX4aJYKGrf)51oooJfe)jWkyyz4)5696P1adbYP82p9DGQgrvNR3RNwdmeiNYB)0q(z1cOkKPkK0iKQskvLsYuLirufcOQChAadh4nKGO2uDue0Qnf)nsu9I)agoWBibrTP4aJccXOI)8AhhNXcI)eyfmSm83FDojKjZmyklJ6XufYufsAesvjLQsjzQAev5BYfqvZPkIbcjKt5LQqMQ8n5c0pBcQsKiQkXu1YteYXL80VJEA7SOCmvnIQYDObmCG3qcIAt1rrqR2uQAevL7qdy4aVHee1MQHShYGz2XXuLiru1YteYXL80VJEygd7xVmvnIQqavDUEV(1BA3aw6VqX13bQAev5BYfqvZPkIbcjKt5LQqMQ8n5c0pBcQkzOkJevVA0kNts63Z2SMyGqc5uEPQKsvjNQsc(BKO6f)hxUSVGS80VdoWOmPyuXFETJJZybXFJevV4pALZjj97zBg)jWkyyz4VVjxavnNQigiKqoLxQczQY3Klq)SjOQKHQ8n5c0qoLx8NioXXYWGPCaWOGeoWOKSXOI)gjQEXFt(UWmdLTxsG9ya(ZRDCCglioWOm5yuXFETJJZybXFcScgwg(7BYfqvZPkIbcjKt5LQqMQ8n5c0pBc83ir1l(dcMDYaAd4aJc6eJk(ZRDCCgli(tGvWWYWF)15KqMmZGPSmQhtvitviPrivLuQkLKXFJevV4)4YL9fKLN(DWbgfKsegv83ir1l(t6gMR1colnaWUUa)51oooJfehyuqcjmQ4pV2XXzSG4pbwbdld)pxVxpTgyiqoL3(PVdu1iQk3HgWWbEdjiQnvd5NvlGQqMQMeQkPuvkjJ)gjQEXFadh4nKGO2uCGrbjXGrf)51oooJfe)jWkyyz4FUdnyg0gw2jp97OJIGwTPuLiru15696xVPDdyP)cfxdcJGgvjKQqi(BKO6f)F9M2nGLNkyCGrbPKJrf)51oooJfe)jWkyyz4)YteYXL80VJgmdAdl7OQruvUdnGHd8gsquBQgYpRwavHEQcHuvsPQusg)nsu9I)Jlx2xqwE63bhyuqAsWOI)8AhhNXcI)eyfmSm8hYEidMzhhJ)gjQEXFadh4nKGO2uCGrbjeIrf)51oooJfe)jWkyyz4pcOQZ171VEt7gWs)fkUgYpRwa(BKO6f)jZm0G2dGdmkinPyuXFJevV4)R30UbS8ubJ)8AhhNXcIdmkiLSXOI)gjQEXFOnenuccyHgJ)8AhhNXcIdmkin5yuXFETJJZybXFcScgwg(FUEVEAnWqGCkV9tFhWFJevV4pGHd8gsquBkoWOGe6eJk(ZRDCCgli(tGvWWYW)LNiKJl5PFh902zr5yQAevL7qdy4aVHee1MQJIGwTPuLiru1YteYXL80VJEygd7xVmvjsevT8eHCCjp97ObZG2WYo83ir1l(pUCzFbz5PFhCGd83gg7lmQyuqcJk(ZRDCCgli(tGvWWYW)Z171h3fkBVmmxVa9DGQgrvNR3RpUlu2EzyUEbAi)SAbufYuvkjJ)gjQEX)xVPDdy5Pcghyuedgv8Nx744mwq8NaRGHLH)NR3RpUlu2EzyUEb67avnIQoxVxFCxOS9YWC9c0q(z1cOkKPQusg)nsu9I)qBiAOeeWcnghyusogv8Nx744mwq8NaRGHLH)iGQYDObmCG3qcIAt1rrqR2u83ir1l(dy4aVHee1MIdmktcgv83ir1l(BY3fMzOS9scShdWFETJJZybXbgfeIrf)51oooJfe)jWkyyz4V)6CsitMzWuwg1JPkKPkK0iKQskvLsYuLiruLVjxavnNQigiKqoLxQczQY3Klq)SjOQruvIPQLNiKJl5PFh902zr5yQAevL7qdy4aVHee1MQJIGwTPu1iQk3HgWWbEdjiQnvdzpKbZSJJPkrIOQLNiKJl5PFh9Wmg2VEzQAevHaQ6C9E9R30UbS0FHIRVdu1iQY3KlGQMtvedesiNYlvHmv5BYfOF2euvYqvgjQE1OvoNK0VNTznXaHeYP8svjLQsovLe83ir1l(pUCzFbz5PFhCGrzsXOI)gjQEXFs3WCTwWzPba21f4pV2XXzSG4aJsYgJk(ZRDCCgli(tGvWWYW)Z171VEt7gWs)fkUgYpRwavnIQwEIqoUKN(D0dZyy)6LXFJevV4)R30UbS8ubJdmktogv8Nx744mwq83ir1l(Jw5Css)E2MXFcScgwg(7VoNeYKzgmLLr9yQczQcjncPQKsvPKmvnIQ8n5cOQ5ufXaHeYP8svitv(MCb6NnbvLmuLyse(hgmLdz5XFCGrbDIrf)51oooJfe)jWkyyz4VVjxavnNQigiKqoLxQczQY3Klq)SjWFJevV4piy2jdOnGdmkiLimQ4pV2XXzSG4pbwbdld)pxVxh1GS9YyglbdSb1GWiOrvcPQKtvIerv5o0GzqByzN80VJokcA1MI)gjQEXFOnenuccyHgJdmkiHegv8Nx744mwq8NaRGHLH)5o0GzqByzN80VJokcA1MI)gjQEX)xVPDdy5PcghyuqsmyuXFETJJZybXFcScgwg(V8eHCCjp97ObZG2WYoQAev5BYfqvONQsEIOQruvUdnGHd8gsquBQgYpRwavHEQcHuvsPQusg)nsu9I)Jlx2xqwE63bhyuqk5yuXFETJJZybXFcScgwg(JaQ6C9E9R30UbS0FHIRH8ZQfG)gjQEXFYmdnO9a4aJcstcgv8Nx744mwq8NaRGHLH)q2dzWm74y83ir1l(dy4aVHee1MIdmkiHqmQ4pV2XXzSG4VrIQx8hTY5KK(9SnJ)eyfmSm833KlGQMtvedesiNYlvHmv5BYfOF2eu1iQkXu15696xVPDdyP)cfxdcJGgvHmvHqQsKiQY3KlGQqMQmsu9QF9M2nGLNkynPbbvLe8pmykhYYJ)4aJcstkgv83ir1l(dTHOHsqal0y8Nx744mwqCGrbPKngv8Nx744mwq8NaRGHLH)NR3RF9M2nGL(luC9DGQejIQ8n5cOk0tvtsIOkrIOQChAWmOnSStE63rhfbTAtXFJevV4)R30UbS8ubJdmkin5yuXFETJJZybXFcScgwg(V8eHCCjp97ON2olkhtvJOQChAadh4nKGO2uDue0QnLQejIQwEIqoUKN(D0dZyy)6LPkrIOQLNiKJl5PFhnyg0gw2rvJOkFtUaQc9ufcte(BKO6f)hxUSVGS80VdoWb(pazs)owGrfJcsyuXFJevV4p4(E9kh4a)51oooJfehyuedgv8Nx744mwq8FThJ)g6cMzqdi99gY2lh6Xme)nsu9I)g6cMzqdi99gY2lh6Xmehyusogv8Nx744mwq83ir1l(teN46a2BrKhNbc8NaRGHLH)iGQGwLL8uEdDTtVULH2XXAEIcea8N9EMeY1Em(teN46a2BrKhNbcCGrzsWOI)gjQEX)0RbZLTY2ln0LHDmd)51oooJfehyuqigv83ir1l(t6gMR1colnaWUUa)51oooJfehyuMumQ4VrIQx8FCdD5PCTsid61wcJ)8AhhNXcIdmkjBmQ4pV2XXzSG4VrIQx8FOJQx8pl(AVIihG8qh4ps4aJYKJrf)nsu9I)GGzNmG2a(ZRDCCglioWOGoXOI)gjQEX)zgCO7f)51oooJfeh4a)jzagvmkiHrf)51oooJfe)jWkyyz4pPBxUhVAs3WCTwWzPba21fAi)SAbuf6PQKNi83ir1l(FCDNL(luCCGrrmyuXFETJJZybXFcScgwg(t62L7XRM0nmxRfCwAaGDDHgYpRwavHEQk5jc)nsu9I)2syqanNKyohoWOKCmQ4pV2XXzSG4pbwbdld)jD7Y94vt6gMR1colnaWUUqd5NvlGQqpvL8eH)gjQEXFFb5JR7moWOmjyuXFJevV4VRsNfazY6MtF8g4pV2XXzSG4aJccXOI)8AhhNXcI)eyfmSm8N0Tl3JxnPByUwl4S0aa76cnKFwTaQc9u1KMiQsKiQkQhlJwMlMQqMQqk54VrIQx8)WqadrR2uCGrzsXOI)8AhhNXcI)eyfmSm8)C9ED61G5Ywz7Lg6YWoMPVdu1iQkXu15696ddbmeTAt13bQsKiQ6C9E9X1Dw6VqX13bQsKiQcbuf0iSoGTZrvjHQejIQsmvr6fCF2XX6HoQELTxE3dSYool9xO4u1iQkQhlJwMlMQqMQMuKOkrIOQOESmAzUyQczQsmtkvLeQsKiQcbufda8synP3mVaolDLN9nKW6NLSAivnIQoxVxt6gMR1colnaWUUqFhWFJevV4)qhvV4aJsYgJk(ZRDCCgli(tGvWWYW)WGPCOZfiSLWuf6fsvtk(BKO6f)nWatcz7LXmwYwQJXbgLjhJk(ZRDCCgli(BKO6f)nWSP2Yaj0q3gkjn0C4pbwbdld)pxVx)4xdfx2EP7sQSmdz7b03bQAevfgmLdDupwgTmxmvHmvr62L7XR(XVgkUS9s3LuzzgY2dOH8ZQfqvZPkKqivjsevDUEVo9AWCzRS9sdDzyhZ0GWiOrvcPkesvJOQWGPCOJ6XYOL5IPkKPks3UCpE1PxdMlBLTxAOld7yMgYpRwavnNQetIOkrIOQmFUEVgAOBdLKgAozMpxVxN7XlvjsevfgmLdDupwgTmxmvHmvjgKOkrIOQZ171JBOlpLRvczqV2synKFwTaQAevfgmLdDupwgTmxmvHmvr62L7XRECdD5PCTsid61wcRH8ZQfqvZPkKMCQsKiQcbuvyoEd9PGzGS9YbilUMx744mvnIQcdMYHoQhlJwMlMQqMQiD7Y94vt6gMR1colnaWUUqd5NvlGQMtvIjru1iQ6C9EnPByUwl4S0aa76cnKFwTa8FThJ)gy2uBzGeAOBdLKgAoCGrbDIrf)51oooJfe)nsu9I)PMJjMZXqG809I)eyfmSm8N0Tl3Jx9JFnuCz7LUlPYYmKThqd5NvlGQejIQcZXBOhxUSVGSSw)fu9Q51oootvJOks3UCpE1KUH5ATGZsdaSRl0q(z1cOkrIOkeqvmaWlH1p(1qXLTx6UKklZq2Ea9ZswnKQgrvKUD5E8QjDdZ1AbNLgayxxOH8ZQfG)R9y8p1CmXCogcKNUxCGrbPeHrf)51oooJfe)x7X4VHUGzg0asFVHS9YHEmdXFJevV4VHUGzg0asFVHS9YHEmdXbgfKqcJk(ZRDCCgli(tGvWWYWFOvzjpL3qB5mqxlvHEQcDMiQAev5BYfqvitv(MCb6NnbvLmuLyqivjsevLyQYirnLL8YVIbuf6PkKOQrufcOQWC8g6tbZaz7LdqwCnV2XXzQsKiQYirnLL8YVIbuf6PkXqvjHQgrvjMQoxVxFCxOS9YWC9c03bQAevDUEV(4Uqz7LH56fOH8ZQfqvONQsovLuQkLKPkrIOkeqvNR3RpUlu2EzyUEb67avLe83ir1l(7BYfWzPHUmScwEy7HdmkijgmQ4pV2XXzSG4pbwbdld)tmvLyQcAvwYt5n0wod0q(z1cOk0tvOZervIerviGQGwLL8uEdTLZanprbcavLeQsKiQkXuLrIAkl5LFfdOk0tvirvJOkeqvH54n0NcMbY2lhGS4AETJJZuLiruLrIAkl5LFfdOk0tvIHQscvLeQAev5BYfqvitv(MCb6Nnb(BKO6f)pUUZY2lJzSKx(jooWOGuYXOI)8AhhNXcI)eyfmSm8pXuvIPkOvzjpL3qB5mqd5NvlGQqpvnPjIQejIQqavbTkl5P8gAlNbAEIceaQkjuLiruvIPkJe1uwYl)kgqvONQqIQgrviGQcZXBOpfmdKTxoazX18AhhNPkrIOkJe1uwYl)kgqvONQedvLeQkju1iQY3KlGQqMQ8n5c0pBc83ir1l(pCHLx8AtLhNbcCGrbPjbJk(BKO6f)tVgmx2kBV0qxg2Xm8Nx744mwqCGrbjeIrf)nsu9I)WAyWXYALGbJW4pV2XXzSG4aJcstkgv8Nx744mwq8NaRGHLH)(RZjHmzMbtzzupMQqMQqIQskvLsY4VrIQx8N0lH3aAbNLEN9yCGrbPKngv8Nx744mwq8NaRGHLH)NR3RHmbnhdasFdjS(oG)gjQEX)yglV7PVBw6BiHXbgfKMCmQ4VrIQx8FCdD5PCTsid61wcJ)8AhhNXcIdmkiHoXOI)8AhhNXcI)eyfmSm8pmykh6zS5Iz6bsqvONQM8ervIervHbt5qpJnxmtpqcQczHuLysevjsevfgmLdDupwgTCGesXKiQc9uvYte(BKO6f)HSnuBQ07ShdWbgfXKimQ4pV2XXzSG4pbwbdld)zaGxcRF8RHIlBV0DjvwMHS9a6NLSAivnIQGShYGz2XXu1iQ6C9E90AGHa5uE7N(oqvJOkeqvKUD5E8QF8RHIlBV0DjvwMHS9aAi)SAb4VrIQx8hWWbEdjiQnfhyuedsyuXFETJJZybXFcScgwg(ZaaVew)4xdfx2EP7sQSmdz7b0plz1qQAevHaQI0Tl3Jx9JFnuCz7LUlPYYmKThqd5Nvla)nsu9I)VEt7gWYtfmoWOigXGrf)51oooJfe)jWkyyz4pda8sy9JFnuCz7LUlPYYmKThq)SKvdPQruL)6CsitMzWuwg1JPkKPkK0iKQskvLsYu1iQY3KlGQqMQmsu9QF9M2nGLNkynPbbvnIQqavr62L7XR(XVgkUS9s3LuzzgY2dOH8ZQfG)gjQEX)XLl7lilp97GdmkIj5yuXFETJJZybXFcScgwg(7BYfqvitvgjQE1VEt7gWYtfSM0GGQgrvNR3RjDdZ1AbNLgayxxOVd4VrIQx8)XVgkUS9s3LuzzgY2dGdCG)z2BxxGrfJcsyuXFETJJZybXFcScgwg(N5Z171ede1MQVduLiru15696CbgyNZoow(S0IOVduLiru15696CbgyNZoowYl0sz9Da)nsu9I)eZ5KgjQELUce4VRaHCThJ)3OCviooWOigmQ4VrIQx8)cyzf8dG)8AhhNXcIdmkjhJk(ZRDCCgli(BKO6f)jMZjnsu9kDfiWFxbc5Apg)jzaoWOmjyuXFETJJZybXFcScgwg(BKOMYsE5xXaQsivHevnIQcdMYHoQhlJwMlMQqMQ8n5cOkX6uvIPkJevV6xVPDdy5PcwtAqqvjdvrmqiHCkVuvsOQKsvPKm(BKO6f)F9M2nGLNkyCGrbHyuXFETJJZybXFcScgwg(BKOMYsE5xXaQczQk5u1iQkmhVHMmZqdApGMx744mvnIQcZXBOn3Wmtoa5SfnuZRDCCg)nsu9I)eZ5KgjQELUce4VRaHCThJ)2WyFHdmktkgv8Nx744mwq8NaRGHLH)gjQPSKx(vmGQqMQsovnIQcZXBOjZm0G2dO51oooJ)gjQEXFI5CsJevVsxbc83vGqU2JX)X(chyus2yuXFETJJZybXFcScgwg(BKOMYsE5xXaQczQk5u1iQcbuvyoEdT5gMzYbiNTOHAETJJZu1iQcbuvyoEd94YL9fKL16VGQxnV2XXz83ir1l(tmNtAKO6v6kqG)UceY1Em(dcCGrzYXOI)8AhhNXcI)eyfmSm83irnLL8YVIbufYuvYPQruvyoEdT5gMzYbiNTOHAETJJZu1iQcbuvyoEd94YL9fKL16VGQxnV2XXz83ir1l(tmNtAKO6v6kqG)UceY1Em(BdGahyuqNyuXFETJJZybXFcScgwg(BKOMYsE5xXaQczQk5u1iQkmhVH2CdZm5aKZw0qnV2XXzQAevfMJ3qpUCzFbzzT(lO6vZRDCCg)nsu9I)eZ5KgjQELUce4VRaHCThJ)2WyFHdmkiLimQ4pV2XXzSG4pbwbdld)nsutzjV8RyavHmvLCQAevHaQkmhVH2CdZm5aKZw0qnV2XXzQAevfMJ3qpUCzFbzzT(lO6vZRDCCg)nsu9I)eZ5KgjQELUce4VRaHCThJ)J9foWOGesyuXFETJJZybXFcScgwg(BKOMYsE5xXaQc9ufsu1iQcbuvyoEd9PGzGS9YbilUMx744mvjsevzKOMYsE5xXaQc9uLyWFJevV4pXCoPrIQxPRab(7kqix7X4pXX2ughyuqsmyuXFJevV4pPxcVb0col9o7X4pV2XXzSG4aJcsjhJk(BKO6f)niXwwgneYBG)8AhhNXcIdmkinjyuXFJevV4)XsLTxgWIGga)51oooJfeh4a)Vr5QqCmQyuqcJk(BKO6f)Fx0fDDm(ZRDCCglioWOigmQ4VrIQx8hWqERqCz(cc8Nx744mwqCGrj5yuXFJevV4pyOHSK46Bg)51oooJfehyuMemQ4VrIQx8h0DmR2u5ylyi(ZRDCCglioWOGqmQ4VrIQx8h0BrKhNbc8Nx744mwqCGrzsXOI)gjQEX)LJzmucM1e0WFETJJZybXbgLKngv83ir1l(tMvjRcidOTInVLRcXXFETJJZybXbgLjhJk(BKO6f)bdfScjywtqd)51oooJfehyuqNyuXFJevV4)AXfYazk0im(ZRDCCglioWboW)Pmeu9IrrmjsmjkriePjb)hBWT2ua(lwf6OypkITrrSgXcvrvOoJPQ6n0WGQ8nKQqhsCSnLrhsvqwS5TGCMQa9JPk7g9ZcotvKz2MYanfr0b1YuvYfluLyp)6PCMQE1kweBrvKzmbnQkXBhuLn1kNDCmvvlvXVRZIQ3KqvjgPjsIMIi6GAzQcDkwOkXE(1t5mv9SjelITOkYmMGgvL4TdQYMALZooMQQLQ431zr1BsOQeJ0ejrtrKIOyvOJI9Oi2gfXAelufvH6mMQQ3qddQY3qQcDOnm2xOdPkil28wqotvG(XuLDJ(zbNPkYmBtzGMIi6GAzQAYfluLyp)6PCMQE1kweBrvKzmbnQkXBhuLn1kNDCmvvlvXVRZIQ3KqvjgPjsIMIi6GAzQcjekwOkXE(1t5mv9QvSi2IQiZycAuvI3oOkBQvo74yQQwQIFxNfvVjHQsmstKenfrkIITFdnm4mvHoPkJevVuLRabqtre)hGTVCm(pzu1)cNwtnhvjw7DdgsrCYOQzrmaelciqAfZUhnPFcaQ31zr1lbA(qaq9icqrCYOkXotCQsmimbQsmjsmjIIifXjJQeRmZ2ugiwOiozuvYqvOJ5mNPkXUl6IUoMQIMQYS3UUGQmsu9svUceAkItgvLmuLyLz2MYzQkmykhYYtv8edqgaQEbuv0ufrCIJLHbt5aOPiozuvYqvIDDU8fNPkIbNYssgsvrtvJBiAu1RHmvXgOCItvJRygvfZyQYY5ErhcOQ6n44hVHfvVuv7PQPgSSJJ1ueNmQkzOk0XCMZu1nkxfItvOJIvJoqtrKI4KrvInMGj3GZu1H9nKPks)owqvhoTwGMQqhjeEiau12BYmZGp)1rvgjQEbuvVoX1ueNmQYir1lqpazs)owi07maAueNmQYir1lqpazs)owmxOa2n9XByr1lfXjJQmsu9c0dqM0VJfZfkGV7mfrJevVa9aKj97yXCHcaUVxVYboOiozu1FTbWSoOkOvzQ6C9EotvGWcavDyFdzQI0VJfu1HtRfqv2MPQbiNmdDe1MsvfGQY9YAkItgvzKO6fOhGmPFhlMluaWAdGzDibHfakIgjQEb6bit63XI5cf4cyzf8lH1ESqdDbZmObK(Edz7Ld9ygsr0ir1lqpazs)owmxOaxalRGFjWEptc5ApwirCIRdyVfrECgisO8cra0QSKNYBORD61Tm0oowZtuGaqr0ir1lqpazs)owmxOaPxdMlBLTxAOld7ygfrJevVa9aKj97yXCHcq6gMR1colnaWUUGIOrIQxGEaYK(DSyUqbg3qxEkxReYGETLWuensu9c0dqM0VJfZfkWqhvVjKfFTxrKdqEOdHirr0ir1lqpazs)owmxOaGGzNmG2afrJevVa9aKj97yXCHcmZGdDVuePiAKO6fOVr5QqCHVl6IUoMIOrIQxG(gLRcXNluaad5TcXL5liOiAKO6fOVr5Qq85cfam0qwsC9ntr0ir1lqFJYvH4ZfkaO7ywTPYXwWqkIgjQEb6BuUkeFUqba9we5XzGGIOrIQxG(gLRcXNluGLJzmucM1e0OiAKO6fOVr5Qq85cfGmRswfqgqBfBElxfItr0ir1lqFJYvH4ZfkayOGvibZAcAuensu9c03OCvi(CHcSwCHmqMcnctrKI4KrvInMGj3GZufpLHItvr9yQkMXuLrIgsvfGQSPw5SJJ1uensu9cesmNtAKO6v6kqKWApw4nkxfINq5fM5Z171ede1MQVdIeDUEVoxGb25SJJLplTi67GirNR3RZfyGDo74yjVqlL13bkIgjQEbZfkWfWYk4hGIOrIQxWCHcqmNtAKO6v6kqKWApwijdOiAKO6fmxOaVEt7gWYtfCcLxOrIAkl5LFfdeI0OWGPCOJ6XYOL5Ir23KlqSEInsu9QF9M2nGLNkynPbrYqmqiHCkVjjPPKmfrJevVG5cfGyoN0ir1R0vGiH1ESqBySVsO8cnsutzjV8RyaYjFuyoEdnzMHg0EanV2XX5rH54n0MByMjhGC2IgQ51oootr0ir1lyUqbiMZjnsu9kDfisyThlCSVsO8cnsutzjV8RyaYjFuyoEdnzMHg0EanV2XXzkIgjQEbZfkaXCoPrIQxPRarcR9yHGiHYl0irnLL8YVIbiN8riimhVH2CdZm5aKZw0qnV2XX5riimhVHEC5Y(cYYA9xq1RMx744mfrJevVG5cfGyoN0ir1R0vGiH1ESqBaejuEHgjQPSKx(vma5KpkmhVH2CdZm5aKZw0qnV2XX5riimhVHEC5Y(cYYA9xq1RMx744mfrJevVG5cfGyoN0ir1R0vGiH1ESqBySVsO8cnsutzjV8RyaYjFuyoEdT5gMzYbiNTOHAETJJZJcZXBOhxUSVGSSw)fu9Q51oootr0ir1lyUqbiMZjnsu9kDfisyThlCSVsO8cnsutzjV8RyaYjFeccZXBOn3Wmtoa5SfnuZRDCCEuyoEd94YL9fKL16VGQxnV2XXzkIgjQEbZfkaXCoPrIQxPRarcR9yHehBt5ekVqJe1uwYl)kgGEKgHGWC8g6tbZaz7LdqwCnV2XXzrImsutzjV8Rya6fdfrJevVG5cfG0lH3aAbNLEN9ykIgjQEbZfkGbj2YYOHqEdkIgjQEbZfkWXsLTxgWIGgGIifrJevVaTnacHVEt7gWYtfCcLx4569As3WCTwWzPba21f67WOeFUEVM0nmxRfCwAaGDDHgYpRwaYiPrystjzrIoxVxFCxOS9YWC9c03HrNR3RpUlu2EzyUEbAi)SAbiJKgHjnLKtcfrJevVaTnaI5cfaAdrdLGawOXjuEHNR3RjDdZ1AbNLgayxxOVdJs8569As3WCTwWzPba21fAi)SAbiJKgHjnLKfj6C9E9XDHY2ldZ1lqFhgDUEV(4Uqz7LH56fOH8ZQfGmsAeM0usojuensu9c02aiMluaVZw0QnvccyHgNq5f6BYfmNyGqc5uEr23Klq)SjOiAKO6fOTbqmxOaOvoNK0VNT5eiItCSmmykhaHiLq5f6VoNeYKzgmLLr9yKrsJWKMsYJ8n5cMtmqiHCkVi7BYfOF2euensu9c02aiMluaqWStgqBiHYl03KlyoXaHeYP8ISVjxG(ztqr0ir1lqBdGyUqbgxUSVGS80VtcLxOVjxWCIbcjKt5fzFtUa9ZMyecIIGwTPJqW5696h)AO4Y2lDxsLLziBpG(omkX(RZjHmzMbtzzupgzK0imPPKSirii3HEC5Y(cYYt)o6OiOvB6ieCUEVM0nmxRfCwAaGDDH(oisecYDOhxUSVGS80VJokcA1Mo6C9E9R30UbS0FHIRbHrqdzKsIirr9yz0YCXiJ0Kpcb5o0Jlx2xqwE63rhfbTAtPiAKO6fOTbqmxOaagoWBibrTPjuEHii3HgWWbEdjiQnvhfbTAthHGZ171KUH5ATGZsdaSRl03bkIgjQEbABaeZfkaALZjj97zBobI4ehlddMYbqisjuEH(MCbZjgiKqoLxK9n5c0pBIrj(C9E9R30UbS0FHIRbHrqdzeksKVjxaYgjQE1VEt7gWYtfSM0Gijuensu9c02aiMluaadh4nKGO20ekVqi7HmyMDC8ieCUEVM0nmxRfCwAaGDDH(om6C9E9R30UbS0FHIRbHrqdzesr0ir1lqBdGyUqbm57cZmu2Ejb2JbjuEHi4C9EnPByUwl4S0aa76c9DGIOrIQxG2gaXCHcq6gMR1colnaWUUiHYlebNR3RjDdZ1AbNLgayxxOVduensu9c02aiMluGxVPDdy5PcoHYl8C9E9R30UbS0FHIRVdIe5BYfmNyGqc5uErVVjxG(ztKmiLirIoxVxt6gMR1colnaWUUqFhOiAKO6fOTbqmxOaqBiAOeeWcnMIOrIQxG2gaXCHcmUCzFbz5PFNekVqeefbTAtPisr0ir1lqBdJ9LWxVPDdy5PcoHYl8C9E9XDHY2ldZ1lqFhgDUEV(4Uqz7LH56fOH8ZQfGCkjtr0ir1lqBdJ91CHcaTHOHsqal04ekVWZ171h3fkBVmmxVa9Dy05696J7cLTxgMRxGgYpRwaYPKmfrJevVaTnm2xZfkaGHd8gsquBAcLxicYDObmCG3qcIAt1rrqR2ukIgjQEbABySVMluat(UWmdLTxsG9yafrJevVaTnm2xZfkW4YL9fKLN(DsO8c9xNtczYmdMYYOEmYiPrystjzrI8n5cMtmqiHCkVi7BYfOF2eJs8YteYXL80VJEA7SOC8OChAadh4nKGO2uDue0QnDuUdnGHd8gsquBQgYEidMzhhls0YteYXL80VJEygd7xV8ieCUEV(1BA3aw6VqX13Hr(MCbZjgiKqoLxK9n5c0pBIKXir1RgTY5KK(9SnRjgiKqoL3KM8Kqr0ir1lqBdJ91CHcq6gMR1colnaWUUGIOrIQxG2gg7R5cf41BA3awEQGtO8cpxVx)6nTBal9xO4Ai)SAbJwEIqoUKN(D0dZyy)6LPiAKO6fOTHX(AUqbqRCojPFpBZjegmLdz5f(QvSCCDNbmJgd1q(z1csO8c9xNtczYmdMYYOEmYiPrystj5r(MCbZjgiKqoLxK9n5c0pBIKrmjIIOrIQxG2gg7R5cfaem7Kb0gsO8c9n5cMtmqiHCkVi7BYfOF2euensu9c02WyFnxOaqBiAOeeWcnoHYl8C9EDudY2lJzSemWgudcJGMWKlsuUdnyg0gw2jp97OJIGwTPuensu9c02WyFnxOaVEt7gWYtfCcLxyUdnyg0gw2jp97OJIGwTPuensu9c02WyFnxOaJlx2xqwE63jHYlC5jc54sE63rdMbTHLDJ8n5cqFYt0OChAadh4nKGO2unKFwTa0JWKMsYuensu9c02WyFnxOaKzgAq7bsO8crW5696xVPDdyP)cfxd5NvlGIOrIQxG2gg7R5cfaWWbEdjiQnnHYleYEidMzhhtr0ir1lqBdJ91CHcGw5Css)E2MtimykhYYl8vRy546odygngQH8ZQfKq5f6BYfmNyGqc5uEr23Klq)SjgL4Z171VEt7gWs)fkUgegbnKrOir(MCbiBKO6v)6nTBalpvWAsdIKqr0ir1lqBdJ91CHcaTHOHsqal0ykIgjQEbABySVMluGxVPDdy5PcoHYl8C9E9R30UbS0FHIRVdIe5BYfG(jjrIeL7qdMbTHLDYt)o6OiOvBkfrJevVaTnm2xZfkW4YL9fKLN(DsO8cxEIqoUKN(D0tBNfLJhL7qdy4aVHee1MQJIGwTPIeT8eHCCjp97OhMXW(1lls0YteYXL80VJgmdAdl7g5BYfGEeMikIuensu9c0Kmq4X1Dw6VqXtO8cjD7Y94vt6gMR1colnaWUUqd5Nvla9jpruensu9c0KmyUqbSLWGaAojXCUekVqs3UCpE1KUH5ATGZsdaSRl0q(z1cqFYtefrJevVanjdMluaFb5JR7CcLxiPBxUhVAs3WCTwWzPba21fAi)SAbOp5jIIOrIQxGMKbZfkGRsNfazY6MtF8guensu9c0KmyUqbomeWq0QnnHYlK0Tl3JxnPByUwl4S0aa76cnKFwTa0pPjsKOOESmAzUyKrk5uensu9c0KmyUqbg6O6nHYl8C9ED61G5Ywz7Lg6YWoMPVdJs85696ddbmeTAt13brIoxVxFCDNL(luC9DqKieancRdy7CjrKOet6fCF2XX6HoQELTxE3dSYool9xO4JI6XYOL5IrEsrsKOOESmAzUyKfZKMerIqada8synP3mVaolDLN9nKW6NLSA4OZ171KUH5ATGZsdaSRl03bkIgjQEbAsgmxOagyGjHS9Yyglzl1XjuEHHbt5qNlqylHrVWjLIOrIQxGMKbZfkWfWYk4xcR9yHgy2uBzGeAOBdLKgAUekVWZ171p(1qXLTx6UKklZq2Ea9DyuyWuo0r9yz0YCXit62L7XR(XVgkUS9s3LuzzgY2dOH8ZQfmhjeks056960RbZLTY2ln0LHDmtdcJGMqeokmykh6OESmAzUyKjD7Y94vNEnyUSv2EPHUmSJzAi)SAbZftIejkZNR3RHg62qjPHMtM5Z1715E8ksuyWuo0r9yz0YCXilgKej6C9E94g6Yt5ALqg0RTewd5NvlyuyWuo0r9yz0YCXit62L7XRECdD5PCTsid61wcRH8ZQfmhPjxKieeMJ3qFkygiBVCaYIR51ooopkmykh6OESmAzUyKjD7Y94vt6gMR1colnaWUUqd5NvlyUys0OZ171KUH5ATGZsdaSRl0q(z1cOiAKO6fOjzWCHcCbSSc(LWApwyQ5yI5CmeipDVjuEHKUD5E8QF8RHIlBV0DjvwMHS9aAi)SAbIefMJ3qpUCzFbzzT(lO6vZRDCCEePBxUhVAs3WCTwWzPba21fAi)SAbIeHaga4LW6h)AO4Y2lDxsLLziBpG(zjRgoI0Tl3JxnPByUwl4S0aa76cnKFwTakIgjQEbAsgmxOaxalRGFjS2JfAOlyMbnG03BiBVCOhZqkIgjQEbAsgmxOa(MCbCwAOldRGLh2EjuEHqRYsEkVH2YzGUw0Jot0iFtUaK9n5c0pBIKrmiuKOeBKOMYsE5xXa0J0ieeMJ3qFkygiBVCaYIR51ooolsKrIAkl5LFfdqVysYOeFUEV(4Uqz7LH56fOVdJoxVxFCxOS9YWC9c0q(z1cqFYtAkjlsecoxVxFCxOS9YWC9c03HKqr0ir1lqtYG5cf446olBVmMXsE5N4juEHjoXqRYsEkVH2YzGgYpRwa6rNjsKieaTkl5P8gAlNbAEIceGKisuInsutzjV8Rya6rAeccZXBOpfmdKTxoazX18AhhNfjYirnLL8YVIbOxmjjjJ8n5cq23Klq)SjOiAKO6fOjzWCHcmCHLx8AtLhNbIekVWeNyOvzjpL3qB5mqd5Nvla9tAIejcbqRYsEkVH2YzGMNOabijIeLyJe1uwYl)kgGEKgHGWC8g6tbZaz7LdqwCnV2XXzrImsutzjV8Rya6ftssYiFtUaK9n5c0pBckIgjQEbAsgmxOaPxdMlBLTxAOld7ygfrJevVanjdMluaynm4yzTsWGrykIgjQEbAsgmxOaKEj8gql4S07ShNq5f6VoNeYKzgmLLr9yKrkPPKmfrJevVanjdMluGyglV7PVBw6BiHtO8cpxVxdzcAogaK(gsy9DGIOrIQxGMKbZfkW4g6Yt5ALqg0RTeMIOrIQxGMKbZfkaKTHAtLEN9yqcLxyyWuo0ZyZfZ0dKa9tEIejkmykh6zS5Iz6bsGSqXKirIcdMYHoQhlJwoqcPyse6tEIOiAKO6fOjzWCHcay4aVHee1MMq5fYaaVew)4xdfx2EP7sQSmdz7b0plz1Wrq2dzWm744rNR3RNwdmeiNYB)03HriG0Tl3Jx9JFnuCz7LUlPYYmKThqd5NvlGIOrIQxGMKbZfkWR30UbS8ubNq5fYaaVew)4xdfx2EP7sQSmdz7b0plz1WriG0Tl3Jx9JFnuCz7LUlPYYmKThqd5NvlGIOrIQxGMKbZfkW4YL9fKLN(DsO8czaGxcRF8RHIlBV0DjvwMHS9a6NLSA4i)15KqMmZGPSmQhJmsAeM0usEKVjxaYgjQE1VEt7gWYtfSM0GyeciD7Y94v)4xdfx2EP7sQSmdz7b0q(z1cOiAKO6fOjzWCHc84xdfx2EP7sQSmdz7bsO8c9n5cq2ir1R(1BA3awEQG1KgeJoxVxt6gMR1colnaWUUqFhOisr0ir1lqtCSnLfo1GLDCCcR9yHedoLLKmmHEqiGJYNWuZDzHgjQPSKx(vmiHPM7Ys2byHimbsV5kQEfAKOMYsE5xXaKrifrJevVanXX2uEUqbE9M2nGLNk4ekVqdDzyfS(4Uqz7LH56fOH2Ig6t0OeFUEVM0nmxRfCwAaGDDH(omkXNR3RjDdZ1AbNLgayxxOH8ZQfGmsAeM0uswKOZ171h3fkBVmmxVa9Dy05696J7cLTxgMRxGgYpRwaYiPrystjzrIoxVxt6gMR1colnaWUUqd5NvlyecoxVxFCxOS9YWC9c0q(z1csssOiAKO6fOjo2MYZfkWR30UbS8ubNqyWuoKLx4RwXsupwgTmxCcLxyMpxVx7SG3qo0fOxnimcAOpXgjQPSKx(vmqKi0zsgfgmLdDupwgTmxmYgjQPSKx(vmiPPKmfrJevVanXX2uEUqbm57cZmu2Ejb2Jbuensu9c0ehBt55cfG0nmxRfCwAaGDDbfrJevVanXX2uEUqbigCkNq5fM7qdMbTHLDYt)o6OiOvB6ieeMJ3qpt8m0aYtfSMx744Sir5o0GzqByzN80VJokcA1MoYirnLL8YVIbOhHuensu9c0ehBt55cfyC5Y(cYYt)ojuEHiimhVHo9Yqy5CMmmsueGMx744Sir(RZjHmzMbtzzupg5uswKiOvzjpL3qB5mqd5Nvla5jDe0QSKNYBOTCgO5jkqaOiAKO6fOjo2MYZfkW5gKzmu8ekVqYmdMYaPhAKO61COxmAeksuUdnyg0gw2jp97OJIGwTPIer62L7XREC5Y(cYYt)oAi)SAbO3irnLL8YVIbjtkjlsuMpxVxFCDNLTxgZyjV8tCnKFwTarIGwLL8uEdTLZanKFwTaKr4iOvzjpL3qB5mqZtuGaqr0ir1lqtCSnLNluGxVPDdy5PcoHWGPCilVWNnHyjZNR3RDwWBih6c0RgegbTekVWmFUEV2zbVHCOlqVAqye0q)Ktr0ir1lqtCSnLNluaYmdnO9auensu9c0ehBt55cfaTY5KK(9SnNarCIJLHbt5aiePekVqFtUG5edesiNYlY(MCb6NnbfrJevVanXX2uEUqbMzWHU3ekVWWC8g6GHpGS9sEtTu(XBO51oootr0ir1lqtCSnLNluaIbNYjuEHH54n0PxgclNZKHrIIa08AhhNPiAKO6fOjo2MYZfkW5gKzmu8ekVqs3UCpE1Jlx2xqwE63rd5Nvla9j2irnLL8YVIbIeHWKqr0ir1lqtCSnLNluaVZw0QnvccyHgNq5f6BYfmNyGqc5uEr23Klq)SjOiAKO6fOjo2MYZfkW4YL9fKLN(DsO8cZDOhxUSVGS80VJgYEidMzhhlsuyoEd94YL9fKL16VGQxnV2XXzkIgjQEbAIJTP8CHcay4aVHee1MMarCIJLHbt5aiePekVWZ171tRbgcKt5TFAiBKGIOrIQxGM4yBkpxOaedoLtO8cjD7Y94vpUCzFbz5PFhnKFwTa0p1GLDCSMyWPSKKHI1fdfrJevVanXX2uEUqbabZozaTbkIgjQEbAIJTP8CHcay4aVHee1MMarCIJLHbt5aiePekVqi7HmyMDC8OZ171rniBVmMXsWaBqnimcAiN8rlprihxYt)o6PTZIYXIebzpKbZSJJhzOldRG1ol4nKdDb6vdTfn0NikItgvHAtvG6DDwWu1fyPmv5Bivj21BA3aMQeScMQAivj2BdrdPQFal0yQkFH1MsvOJGbMeuv7PQygtvInSuhNavr6bXPk2iZOQMqUqiVeMQApvfZyQYir1lvzBMQSHbEZuLKTuhtvrtvXmMQmsu9svR9ynfrJevVanXX2uEUqbE9M2nGLNk4eiItCSmmykhaHirr0ir1lqtCSnLNluaOnenuccyHgNarCIJLHbt5aiejkIuensu9c0Gq4mdo09Mq5fgMJ3qhm8bKTxYBQLYpEdnV2XXzkIgjQEbAqmxOaENTOvBQeeWcnoHYl03KlyoXaHeYP8ISVjxG(ztqr0ir1lqdI5cfaAdrdLGawOXjuEHNR3RjDdZ1AbNLgayxxOVdJs8569As3WCTwWzPba21fAi)SAbiJKgHjnLKfj6C9E9XDHY2ldZ1lqFhgDUEV(4Uqz7LH56fOH8ZQfGmsAeM0usojueNmQc1MQa176SGPQlWszQY3qQsSR30Ubmvjyfmv1qQsS3gIgsv)awOXuv(cRnLQqhbdmjOQ2tvXmMQeByPoobQI0dItvSrMrvnHCHqEjmv1EQkMXuLrIQxQY2mvzdd8MPkjBPoMQIMQIzmvzKO6LQw7XAkIgjQEbAqmxOaVEt7gWYtfCcLx4569As3WCTwWzPba21f67WOeFUEVM0nmxRfCwAaGDDHgYpRwaYiPrystjzrIoxVxFCxOS9YWC9c03HrNR3RpUlu2EzyUEbAi)SAbiJKgHjnLKtcfrJevVaniMlua0kNts63Z2CceXjowggmLdGqKsO8c9n5cMtmqiHCkVi7BYfOF2euensu9c0GyUqbamCG3qcIAttO8cpxVxpTgyiqoL3(PVdJoxVxpTgyiqoL3(PH8ZQfGmsjnLKPiAKO6fObXCHcacMDYaAdjuEH(MCbZjgiKqoLxK9n5c0pBckIgjQEbAqmxOaJlx2xqwE63jHYl03KlyoXaHeYP8ISVjxG(ztmcYEidMzhhpYFDojKjZmyklJ6XiNsYJqW5696h)AO4Y2lDxsLLziBpG(oisKVjxWCIbcjKt5fzFtUa9ZMyuIrqUd94YL9fKLN(D0rrqR20rjgbNR3RjDdZ1AbNLgayxxOVdIeDUEV(1BA3aw6VqX1GWiOHmsIef1JLrlZfJmstUirii3HEC5Y(cYYt)o6OiOvB6idDzyfSEC5YmCzaqcUWP1uZPH2Ig6tussYieCUEV(XVgkUS9s3LuzzgY2dOVduensu9c0GyUqbamCG3qcIAttO8cpxVxpTgyiqoL3(PVdJYDObmCG3qcIAt1q(z1cqEssAkjlsuUdnGHd8gsquBQgYEidMzhhpcbNR3RjDdZ1AbNLgayxxOVduensu9c0GyUqbm57cZmu2Ejb2JbjuEHi4C9EnPByUwl4S0aa76c9DGIOrIQxGgeZfkaPByUwl4S0aa76IekVqeCUEVM0nmxRfCwAaGDDH(oqr0ir1lqdI5cf41BA3awEQGtO8cpxVx)6nTBal9xO467Gir(MCbZjgiKqoLx07BYfOF2ejJys0OWC8g6P1adbYP82pnV2XXzrI8n5cMtmqiHCkVO33Klq)SjsgKgfMJ3qhm8bKTxYBQLYpEdnV2XXzrIoxVxt6gMR1colnaWUUqFhOiAKO6fObXCHcaTHOHsqal0ykIgjQEbAqmxOaJlx2xqwE63jHYlm3HEC5Y(cYYt)oAi7HmyMDCmfrJevVaniMluaadh4nKGO20ekVWZ171tRbgcKt5TF67afrkIgjQEb6X(s4mdo09Mq5f6BYfmNyGqc5uEr23Klq)SjgfMJ3qhm8bKTxYBQLYpEdnV2XXzkIgjQEb6X(AUqbE9M2nGLNk4ekVWZ171h3fkBVmmxVa9Dy05696J7cLTxgMRxGgYpRwaYPKmfrJevVa9yFnxOaqBiAOeeWcnoHYl8C9E9XDHY2ldZ1lqFhgDUEV(4Uqz7LH56fOH8ZQfGCkjtr0ir1lqp2xZfkaGHd8gsquBAcLx45696P1adbYP82p9Dy05696P1adbYP82pnKFwTaKrsJWKMsYIeHGChAadh4nKGO2uDue0QnLIOrIQxGESVMluGXLl7lilp97Kq5f6VoNeYKzgmLLr9yKrsJWKMsYJ8n5cMtmqiHCkVi7BYfOF2eIeL4LNiKJl5PFh902zr54r5o0agoWBibrTP6OiOvB6OChAadh4nKGO2unK9qgmZoowKOLNiKJl5PFh9Wmg2VE5ri4C9E9R30UbS0FHIRVdJ8n5cMtmqiHCkVi7BYfOF2ejJrIQxnALZjj97zBwtmqiHCkVjn5jHIOrIQxGESVMlua0kNts63Z2CceXjowggmLdGqKsO8c9n5cMtmqiHCkVi7BYfOF2ejJVjxGgYP8sr0ir1lqp2xZfkGjFxyMHY2ljWEmGIOrIQxGESVMluaqWStgqBiHYl03KlyoXaHeYP8ISVjxG(ztqr0ir1lqp2xZfkW4YL9fKLN(DsO8c9xNtczYmdMYYOEmYiPrystjzkIgjQEb6X(AUqbiDdZ1AbNLgayxxqr0ir1lqp2xZfkaGHd8gsquBAcLx45696P1adbYP82p9DyuUdnGHd8gsquBQgYpRwaYtsstjzkIgjQEb6X(AUqbE9M2nGLNk4ekVWChAWmOnSStE63rhfbTAtfj6C9E9R30UbS0FHIRbHrqticPiAKO6fOh7R5cfyC5Y(cYYt)ojuEHlprihxYt)oAWmOnSSBuUdnGHd8gsquBQgYpRwa6rystjzkIgjQEb6X(AUqbamCG3qcIAttO8cHShYGz2XXuensu9c0J91CHcqMzObThiHYlebNR3RF9M2nGL(luCnKFwTakIgjQEb6X(AUqbE9M2nGLNkykIgjQEb6X(AUqbG2q0qjiGfAmfrJevVa9yFnxOaagoWBibrTPjuEHNR3RNwdmeiNYB)03bkIgjQEb6X(AUqbgxUSVGS80VtcLx4YteYXL80VJEA7SOC8OChAadh4nKGO2uDue0QnvKOLNiKJl5PFh9Wmg2VEzrIwEIqoUKN(D0GzqByzh(dgycgfXGqeIdCGXa]] )


end