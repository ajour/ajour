-- ShamanElemental.lua
-- May 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'SHAMAN' then
    local spec = Hekili:NewSpecialization( 262, true )

    spec:RegisterResource( Enum.PowerType.Maelstrom, {
        resonance_totem = {
            aura = 'resonance_totem',

            last = function ()
                local app = state.buff.resonance_totem.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = 1,
            value = 1,
        },
    } )
    spec:RegisterResource( Enum.PowerType.Mana )

    -- Talents
    spec:RegisterTalents( {
        earthen_rage = 22356, -- 170374
        echo_of_the_elements = 22357, -- 108283
        elemental_blast = 22358, -- 117014

        aftershock = 23108, -- 273221
        call_the_thunder = 22139, -- 260897
        totem_mastery = 23190, -- 210643

        spirit_wolf = 23162, -- 260878
        earth_shield = 23163, -- 974
        static_charge = 23164, -- 265046

        master_of_the_elements = 19271, -- 16166
        storm_elemental = 19272, -- 192249
        liquid_magma_totem = 19273, -- 192222

        natures_guardian = 22144, -- 30884
        ancestral_guidance = 22172, -- 108281
        wind_rush_totem = 21966, -- 192077

        surge_of_power = 22145, -- 262303
        primal_elementalist = 19266, -- 117013
        icefury = 23111, -- 210714

        unlimited_power = 21198, -- 260895
        stormkeeper = 22153, -- 191634
        ascendance = 21675, -- 114050
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3596, -- 196029
        adaptation = 3597, -- 214027
        gladiators_medallion = 3598, -- 208683

        spectral_recovery = 3062, -- 204261
        control_of_lava = 728, -- 204393
        earthfury = 729, -- 204398
        traveling_storms = 730, -- 204403
        lightning_lasso = 731, -- 204437
        elemental_attunement = 727, -- 204385
        skyfury_totem = 3488, -- 204330
        grounding_totem = 3620, -- 204336
        counterstrike_totem = 3490, -- 204331
        purifying_waters = 3491, -- 204247
        swelling_waves = 3621, -- 204264
    } )

    -- Auras
    spec:RegisterAuras( {
        ancestral_guidance = {
            id = 108281,
            duration = 10,
            max_stack = 1,
        },

        ascendance = {
            id = 114050,
            duration = 15,
            max_stack = 1,
        },

        astral_shift = {
            id = 108271,
            duration = 8,
            max_stack = 1,
        },

        earth_shield = {
            id = 974,
            duration = 600,
            type = "Magic",
            max_stack = 9,
        },

        earthbind = {
            id = 3600,
            duration = 5,
            type = "Magic",
            max_stack = 1,
        },

        earthquake = {
            id = 61882,
            duration = 3600,
            max_stack = 1,
        },

        elemental_blast = {
            duration = 10,
            type = "Magic",
            max_stack = 3,
            generate = function ()
                local eb = buff.elemental_blast

                local count = ( buff.elemental_blast_critical_strike.up and 1 or 0 ) +
                              ( buff.elemental_blast_haste.up and 1 or 0 ) +
                              ( buff.elemental_blast_mastery.up and 1 or 0 )
                local applied = max( buff.elemental_blast_critical_strike.applied,
                                buff.elemental_blast_haste.applied,
                                buff.elemental_blast_mastery.applied )

                eb.name = class.abilities.elemental_blast.name or "Elemental Blast"
                eb.count = count
                eb.applied = applied
                eb.expires = applied + 15
                eb.caster = count > 0 and 'player' or 'nobody'
            end
        },

        elemental_blast_critical_strike = {
            id = 118522,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },

        elemental_blast_haste = {
            id = 173183,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },

        elemental_blast_mastery = {
            id = 173184,
            duration = 10,
            type = "Magic",
            max_stack = 1,
        },

        ember_totem = {
            id = 210658,
            duration = 0,
            max_stack = 1,
        },

        exposed_elements = {
            id = 269808,
            duration = 15,
            max_stack = 1,
        },

        far_sight = {
            id = 6196,
            duration = 60,
            max_stack = 1,
        },

        flame_shock = {
            id = 188389,
            duration = 24,
            tick_time = function () return 2 * haste end,
            type = "Magic",
            max_stack = 1,
        },

        frost_shock = {
            id = 196840,
            duration = 6,
            type = "Magic",
            max_stack = 1,
        },

        ghost_wolf = {
            id = 2645,
            duration = 3600,
            type = "Magic",
            max_stack = 1,
        },

        icefury = {
            id = 210714,
            duration = 15,
            max_stack = 4,
        },

        lava_surge = {
            id = 77762,
            duration = 10,
            max_stack = 1,
        },

        lightning_lasso = {
            id = 305484,
            duration = 5,
            max_stack = 1
        },

        master_of_the_elements = {
            id = 260734,
            duration = 15,
            type = "Magic",
            max_stack = 1,
        },

        resonance_totem = {
            id = 202192,
            duration = 120,
            max_stack = 1,
        },

        spirit_wolf = {
            id = 260881,
            duration = 3600,
            max_stack = 4,
        },

        static_charge = {
            id = 265046,
            duration = 3,
            type = "Magic",
            max_stack = 1,
        },

        storm_totem = {
            id = 210652,
            duration = 120,
            max_stack = 1,
        },

        stormkeeper = {
            id = 191634,
            duration = 15,
            max_stack = 2,
        },

        surge_of_power = {
            id = 285514,
            duration = 15,
            max_stack = 1,
        },

        surge_of_power_debuff = {
            id = 285515,
            duration = 6,
            max_stack = 1,
        },

        tailwind_totem = {
            id = 210659,
            duration = 120,
            max_stack = 1,
        },

        thunderstorm = {
            id = 51490,
            duration = 5,
            max_stack = 1,
        },

        unlimited_power = {
            id = 272737,
            duration = 10,
            max_stack = 10, -- this is a guess.
        },        

        water_walking = {
            id = 546,
            duration = 600,
            max_stack = 1,
        },

        wind_rush = {
            id = 192082,
            duration = 5,
            max_stack = 1,
        },

        totem_mastery = {
            duration = 120,
            generate = function ()
                local expires, remains = 0, 0

                for i = 1, 5 do
                    local _, name, cast, duration = GetTotemInfo(i)

                    if name == class.abilities.totem_mastery.name then
                        if cast + duration > expires then
                            expires = cast + duration
                            remains = expires - now
                        end
                    end
                end

                local up = PlayerBuffUp( "resonance_totem" ) and remains > 0

                local tm = buff.totem_mastery
                tm.name = class.abilities.totem_mastery.name

                if expires > 0 and up then
                    tm.count = 4
                    tm.expires = expires
                    tm.applied = expires - 120
                    tm.caster = "player"

                    applyBuff( "resonance_totem", remains )
                    applyBuff( "tailwind_totem", remains )
                    applyBuff( "storm_totem", remains )
                    applyBuff( "ember_totem", remains )
                    return
                end

                tm.count = 0
                tm.expires = 0
                tm.applied = 0
                tm.caster = "nobody"

                removeBuff( 'resonance_totem' )
                removeBuff( 'storm_totem' )
                removeBuff( 'ember_totem' )
                removeBuff( 'tailwind_totem' )
            end,
        },

        wind_gust = {
            id = 263806,
            duration = 30,
            max_stack = 20
        },


        -- Azerite Powers
        ancestral_resonance = {
            id = 277943,
            duration = 15,
            max_stack = 1,
        },

        tectonic_thunder = {
            id = 286976,
            duration = 15,
            max_stack = 1,
        },


        -- Pet aura.
        call_lightning = {
            duration = 15,
            generate = function( t, db )
                if storm_elemental.up then
                    local name, _, count, _, duration, expires = FindUnitBuffByID( "pet", 157348 )

                    if name then
                        t.count = count
                        t.expires = expires
                        t.applied = expires - duration
                        t.caster = "pet"
                        return
                    end    
                end

                t.count = 0
                t.expires = 0
                t.applied = 0
                t.caster = "nobody"
            end,
        },        
    } )


    -- Pets
    spec:RegisterPet( "primal_storm_elemental", 77942, "storm_elemental", 30 )
    spec:RegisterTotem( "greater_storm_elemental", 1020304 ) -- Texture ID

    spec:RegisterPet( "primal_fire_elemental", 61029, "fire_elemental", 30 )
    spec:RegisterTotem( "greater_fire_elemental", 135790 ) -- Texture ID

    spec:RegisterPet( "primal_earth_elemental", 61056, "earth_elemental", 60 )
    spec:RegisterTotem( "greater_earth_elemental", 136024 ) -- Texture ID


    spec:RegisterStateTable( 'fire_elemental', setmetatable( { onReset = function( self ) self.cast_time = nil end }, {
        __index = function( t, k )
            if k == 'cast_time' then
                t.cast_time = class.abilities.fire_elemental.lastCast or 0
                return t.cast_time
            end

            local elem = talent.primal_elementalist.enabled and pet.primal_fire_elemental or pet.greater_fire_elemental

            if k == 'active' or k == 'up' then
                return elem.up

            elseif k == 'down' then
                return not elem.up

            elseif k == 'remains' then
                return max( 0, elem.remains )

            end

            return false
        end 
    } ) )

    spec:RegisterStateTable( 'storm_elemental', setmetatable( { onReset = function( self ) self.cast_time = nil end }, {
        __index = function( t, k )
            if k == 'cast_time' then
                t.cast_time = class.abilities.storm_elemental.lastCast or 0
                return t.cast_time
            end

            local elem = talent.primal_elementalist.enabled and pet.primal_storm_elemental or pet.greater_storm_elemental

            if k == 'active' or k == 'up' then
                return elem.up

            elseif k == 'down' then
                return not elem.up

            elseif k == 'remains' then
                return max( 0, elem.remains )

            end

            return false
        end 
    } ) )

    spec:RegisterStateTable( 'earth_elemental', setmetatable( { onReset = function( self ) self.cast_time = nil end }, {
        __index = function( t, k )
            if k == 'cast_time' then
                t.cast_time = class.abilities.earth_elemental.lastCast or 0
                return t.cast_time
            end

            local elem = talent.primal_elementalist.enabled and pet.primal_earth_elemental or pet.greater_earth_elemental

            if k == 'active' or k == 'up' then
                return elem.up

            elseif k == 'down' then
                return not elem.up

            elseif k == 'remains' then
                return max( 0, elem.remains )

            end

            return false
        end 
    } ) )


    local function natural_harmony( elem1, elem2, elem3 )
        if not azerite.natural_harmony.enabled then return end

        if elem1 then applyBuff( "natural_harmony_" .. elem1 ) end
        if elem2 then applyBuff( "natural_harmony_" .. elem2 ) end
        if elem3 then applyBuff( "natural_harmony_" .. elem3 ) end
    end

    setfenv( natural_harmony, state )


    local hadTotem = false
    local hadTotemAura = false

    spec:RegisterHook( "reset_precast", function ()
        class.auras.totem_mastery.generate()

        if talent.master_of_the_elements.enabled and action.lava_burst.in_flight and buff.master_of_the_elements.down then
            applyBuff( "master_of_the_elements" )
        end
    end )


    spec:RegisterGear( "the_deceivers_blood_pact", 137035 ) -- 20% chance; not modeled.
    spec:RegisterGear( "alakirs_acrimony", 137102 ) -- passive dmg increase.
    spec:RegisterGear( "echoes_of_the_great_sundering", 137074 )
        spec:RegisterAura( "echoes_of_the_great_sundering", {
            id = 208723, 
            duration =  10
        } )

    spec:RegisterGear( "pristine_protoscale_girdle", 137083 ) -- not modeled.
    spec:RegisterGear( "eye_of_the_twisting_nether", 137050 )
        spec:RegisterAura( "fire_of_the_twisting_nether", {
            id = 207995,
            duration = 8 
        } )
        spec:RegisterAura( "chill_of_the_twisting_nether", {
            id = 207998,
            duration = 8 
        } )
        spec:RegisterAura( "shock_of_the_twisting_nether", {
            id = 207999,
            duration = 8 
        } )

        spec:RegisterStateTable( "twisting_nether", setmetatable( {}, {
            __index = function( t, k )
                if k == 'count' then
                    return ( buff.fire_of_the_twisting_nether.up and 1 or 0 ) + ( buff.chill_of_the_twisting_nether.up and 1 or 0 ) + ( buff.shock_of_the_twisting_nether.up and 1 or 0 )
                end

                return 0
            end
        } ) )

    spec:RegisterGear( "uncertain_reminder", 143732 )


    -- Abilities
    spec:RegisterAbilities( {
        ancestral_guidance = {
            id = 108281,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            talent = 'ancestral_guidance',

            startsCombat = false,
            texture = 538564,

            handler = function ()
                applyBuff( 'ancestral_guidance' )
            end,
        },


        ancestral_spirit = {
            id = 2008,
            cast = 10.000215022888,
            cooldown = 0,
            gcd = "spell",

            spend = 0.04,
            spendType = "mana",

            startsCombat = false,
            texture = 136077,

            handler = function ()
            end,
        },


        ascendance = {
            id = 114050,
            cast = 0,
            cooldown = 180,
            gcd = "spell",

            toggle = 'cooldowns',
            talent = 'ascendance',

            startsCombat = false,
            texture = 135791,

            handler = function ()
                applyBuff( 'ascendance' )
                gainCharges( "lava_burst", 2 )
            end,
        },


        astral_recall = {
            id = 556,
            cast = function () return 10 * haste end,
            cooldown = 600,
            gcd = "spell",

            startsCombat = false,
            texture = 136010,

            handler = function ()
            end,
        },


        astral_shift = {
            id = 108271,
            cast = 0,
            cooldown = 90,
            gcd = "spell",

            startsCombat = false,
            texture = 538565,

            handler = function ()
                applyBuff( 'astral_shift' )
            end,
        },


        --[[ bloodlust = {
            id = 2825,
            cast = 0,
            cooldown = 300,
            gcd = "spell",

            spend = 0.22,
            spendType = "mana",

            startsCombat = false,
            texture = 136012,

            handler = function ()
                applyBuff( 'bloodlust' )
                applyDebuff( 'player', 'sated' )
            end,
        }, ]]


        capacitor_totem = {
            id = 192058,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            startsCombat = false,
            texture = 136013,

            handler = function ()
            end,
        },


        chain_lightning = {
            id = 188443,
            cast = function () return ( buff.tectonic_thunder.up or buff.stormkeeper.up ) and 0 or ( 2 * haste ) end,
            cooldown = 0,
            gcd = "spell",

            spend = function () return -4 * ( min( 5, active_enemies ) ) end,
            spendType = 'maelstrom',

            nobuff = 'ascendance',
            bind = 'lava_beam',

            startsCombat = true,
            texture = 136015,

            handler = function ()
                removeBuff( "master_of_the_elements" )

                if buff.stormkeeper.up then
                    gain( 2 * min( 5, active_enemies ), "maelstrom" )
                    removeStack( "stormkeeper" )
                else
                    removeBuff( "tectonic_thunder" )
                end

                if pet.storm_elemental.up then
                    addStack( "wind_gust", nil, 1 )
                end

                natural_harmony( "nature" )

                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "shock_of_the_twisting_nether" ) end
            end,
        },


        cleanse_spirit = {
            id = 51886,
            cast = 0,
            cooldown = 8,
            gcd = "spell",

            spend = 0.06,
            spendType = "mana",

            startsCombat = false,
            texture = 236288,

            handler = function ()
            end,
        },


        earth_elemental = {
            id = 198103,
            cast = 0,
            cooldown = 300,
            gcd = "spell",

            startsCombat = false,
            texture = 136024,

            handler = function ()
                summonPet( talent.primal_elementalist.enabled and "primal_earth_elemental" or "greater_earth_elemental", 60 )
            end,
        },


        earth_shield = {
            id = 974,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            talent = 'earth_shield',

            startsCombat = false,
            texture = 136089,

            handler = function ()
                applyBuff( 'earth_shield' )                
            end,
        },


        earth_shock = {
            id = 8042,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 60,
            spendType = "maelstrom",

            startsCombat = true,
            texture = 136026,

            handler = function ()
                if talent.exposed_elements.enabled then applyBuff( 'exposed_elements' ) end
                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "shock_of_the_twisting_nether" ) end
                if talent.surge_of_power.enabled then applyBuff( "surge_of_power" ) end

                natural_harmony( "nature" )
            end,
        },


        earthbind_totem = {
            id = 2484,
            cast = 0,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 136102,

            handler = function ()
            end,
        },


        earthquake = {
            id = 61882,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function () return buff.echoes_of_the_great_sundering.up and 0 or 60 end,
            spendType = "maelstrom",

            startsCombat = true,
            texture = 451165,

            handler = function ()
                removeBuff( "echoes_of_the_great_sundering" )
                removeBuff( "master_of_the_elements" )
                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "shock_of_the_twisting_nether" ) end
                natural_harmony( "nature" )
            end,
        },


        elemental_blast = {
            id = 117014,
            cast = function () return 2 * haste end,
            cooldown = 12,
            gcd = "spell",

            startsCombat = true,
            texture = 651244,

            handler = function ()
                applyBuff( 'elemental_blast' )

                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( "fire_of_the_twisting_nether" )
                    applyBuff( "chill_of_the_twisting_nether" )
                    applyBuff( "shock_of_the_twisting_nether" )
                end

                natural_harmony( "fire", "frost", "nature" )
            end,
        },


        far_sight = {
            id = 6196,
            cast = function () return 2 * haste end,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 136034,

            handler = function ()
            end,
        },


        fire_elemental = {
            id = 198067,
            cast = 0,
            charges = 1,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.9 or 1 ) * 150 end,
            recharge = function () return ( essence.vision_of_perfection.enabled and 0.9 or 1 ) * 150 end,
            gcd = "spell",

            toggle = 'cooldowns',
            notalent = 'storm_elemental',

            startsCombat = false,
            texture = 135790,

            handler = function ()
                summonPet( talent.primal_elementalist.enabled and "primal_fire_elemental" or "greater_fire_elemental", 30 )
            end,
        },


        flame_shock = {
            id = 188389,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = true,
            texture = 135813,

            cycle = "flame_shock",
            min_ttd = function () return debuff.flame_shock.duration / 3 end,

            handler = function ()
                applyDebuff( 'target', 'flame_shock' )
                if buff.surge_of_power.up then
                    active_dot.surge_of_power = min( active_enemies, active_dot.flame_shock + 1 )
                    removeBuff( "surge_of_power" )
                end
                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "fire_of_the_twisting_nether" ) end
                natural_harmony( "fire" )
            end,
        },


        frost_shock = {
            id = 196840,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = true,
            texture = 135849,

            handler = function ()
                removeBuff( 'master_of_the_elements' )
                applyDebuff( 'target', 'frost_shock' )

                if buff.icefury.up then
                    gain( 8, "maelstrom" )
                    removeStack( "icefury", 1 )
                end

                if buff.surge_of_power.up then
                    applyDebuff( "target", "surge_of_power_debuff" )
                    removeBuff( "surge_of_power" )
                end

                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "chill_of_the_twisting_nether" ) end
                natural_harmony( "frost" )
            end,
        },


        ghost_wolf = {
            id = 2645,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 136095,

            handler = function ()
                applyBuff( 'ghost_wolf' )
                if talent.spirit_wolf.enabled then applyBuff( 'spirit_wolf' ) end
            end,
        },


        healing_surge = {
            id = 8004,
            cast = function () return 1.5 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = 0.2,
            spendType = "mana",

            startsCombat = false,
            texture = 136044,

            handler = function ()
            end,
        },


        hex = {
            id = 51514,
            cast = function () return 1.7 * haste end,
            cooldown = 30,
            gcd = "spell",

            startsCombat = false,
            texture = 237579,

            handler = function ()
                applyDebuff( 'target', 'hex' )
            end,
        },


        icefury = {
            id = 210714,
            cast = 1.9996204751587,
            cooldown = 30,
            gcd = "spell",

            spend = -25,
            spendType = 'maelstrom',

            startsCombat = true,
            texture = 135855,

            handler = function ()
                removeBuff( 'master_of_the_elements' )
                applyBuff( 'icefury', 15, 4 )
                natural_harmony( "frost" )
            end,
        },


        lava_beam = {
            id = 114074,
            cast = function () return 2 * haste end,
            cooldown = 0,
            gcd = "spell",

            spend = function () return -4 * ( min( 5, active_enemies ) ) end,
            spendType = 'maelstrom',

            buff = 'ascendance',
            bind = 'chain_lightning',

            startsCombat = true,
            texture = 236216,

            handler = function ()
                removeStack( 'stormkeeper' )
                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "fire_of_the_twisting_nether" ) end
                natural_harmony( "fire" )
            end,
        },


        lava_burst = {
            id = 51505,
            cast = function () return buff.lava_surge.up and 0 or ( 2 * haste ) end,
            charges = function () return talent.echo_of_the_elements.enabled and 2 or nil end,
            cooldown = function () return buff.ascendance.up and 0 or ( 8 * haste ) end,
            recharge = function () return buff.ascendance.up and 0 or ( 8 * haste ) end,
            gcd = "spell",

            spend = -10,
            spendType = "maelstrom",

            startsCombat = true,
            texture = 237582,

            handler = function ()
                removeBuff( "lava_surge" )
                if talent.master_of_the_elements.enabled then applyBuff( "master_of_the_elements" ) end
                if talent.surge_of_power.enabled then
                    gainChargeTime( "fire_elemental", 6 )
                    removeBuff( "surge_of_power" )
                end
                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "fire_of_the_twisting_nether" ) end
                natural_harmony( "fire" )
            end,
        },


        lightning_bolt = {
            id = 188196,
            cast = function () return buff.stormkeeper.up and 0 or ( 2 * haste ) end,
            cooldown = 0,
            gcd = "spell",

            spend = -8,
            spendType = "maelstrom",

            startsCombat = true,
            texture = 136048,

            handler = function ()
                removeBuff( "master_of_the_elements" )

                if buff.stormkeeper.up then
                    gain( 3, "maelstrom" )
                    removeStack( 'stormkeeper' )
                end

                if buff.surge_of_power.up then
                    gain( 3, "maelstrom" )
                    removeBuff( "surge_of_power" )
                end

                if pet.storm_elemental.up then
                    addStack( "wind_gust", nil, 1 )
                end

                if level < 116 and equipped.eye_of_the_twisting_nether then applyBuff( "shock_of_the_twisting_nether" ) end
                natural_harmony( "nature" )
            end,
        },


        lightning_lasso = {
            id = 305483,
            cast = 5,
            channeled = true,
            cooldown = 30,
            gcd = "spell",

            startsCombat = true,
            texture = 1385911,

            pvptalent = function ()
                if essence.conflict_and_strife.major then return end
                return "lightning_lasso"
            end,

            start = function ()
                applyDebuff( "target", "lightning_lasso" )
            end,
        },


        liquid_magma_totem = {
            id = 192222,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            startsCombat = true,
            texture = 971079,

            handler = function ()
            end,
        },


        purge = {
            id = 370,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 0.1,
            spendType = "mana",

            startsCombat = true,
            texture = 136075,

            handler = function ()
            end,
        },


        storm_elemental = {
            id = 192249,
            cast = 0,
            charges = 1,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 150 end,
            recharge = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 150 end,
            gcd = "spell",

            toggle = 'cooldowns',
            talent = 'storm_elemental',

            startsCombat = true,
            texture = 2065626,

            handler = function ()
                summonPet( talent.primal_elementalist.enabled and "primal_storm_elemental" or "greater_storm_elemental", 30 )
            end,
        },


        stormkeeper = {
            id = 191634,
            cast = function () return 1.5 * haste end,
            cooldown = 60,
            gcd = "spell",

            talent = 'stormkeeper',

            startsCombat = false,
            texture = 839977,

            handler = function ()
                applyBuff( 'stormkeeper', 20, 2 )
            end,
        },


        thunderstorm = {
            id = 51490,
            cast = 0,
            cooldown = 45,
            gcd = "spell",

            startsCombat = true,
            texture = 237589,

            handler = function ()
                if target.within10 then applyDebuff( 'target', 'thunderstorm' ) end
            end,
        },


        totem_mastery = {
            id = 210643,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            talent = 'totem_mastery',
            essential = true,

            startsCombat = false,
            texture = 511726,

            readyTime = function () return buff.totem_mastery.remains - 15 end,
            usable = function () return query_time - action.totem_mastery.lastCast > 3 end,
            handler = function ()
                applyBuff( 'resonance_totem', 120 )
                applyBuff( 'storm_totem', 120 )
                applyBuff( 'ember_totem', 120 )
                if buff.tailwind_totem.down then stat.spell_haste = stat.spell_haste + 0.02 end
                applyBuff( 'tailwind_totem', 120 )
                applyBuff( 'totem_mastery', 120 )
            end,
        },


        tremor_totem = {
            id = 8143,
            cast = 0,
            cooldown = 60,
            gcd = "spell",

            spend = 0.02,
            spendType = "mana",

            startsCombat = true,
            texture = 136108,

            handler = function ()
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


        water_walking = {
            id = 546,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            texture = 135863,

            handler = function ()
                applyBuff( 'water_walking' )
            end,
        },


        wind_rush_totem = {
            id = 192077,
            cast = 0,
            cooldown = 120,
            gcd = "spell",

            talent = 'wind_rush_totem',

            startsCombat = false,
            texture = 538576,

            handler = function ()                
            end,
        },


        wind_shear = {
            id = 57994,
            cast = 0,
            cooldown = 12,
            gcd = "spell",

            startsCombat = true,
            texture = 136018,

            toggle = 'interrupts',

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function ()
                interrupt()
            end,
        },


        -- Pet Abilities
        meteor = {
            id = 117588,
            known = function () return talent.primal_elementalist.enabled and not talent.storm_elemental.enabled and fire_elemental.up end,
            cast = 0,
            cooldown = 60,
            gcd = "off",

            startsCombat = true,
            texture = 1033911,

            talent = "primal_elementalist",

            usable = function () return fire_elemental.up end,
            handler = function () end,
        },

        eye_of_the_storm = {
            id = 157375,
            known = function () return talent.primal_elementalist.enabled and talent.storm_elemental.enabled and storm_elemental.up end,
            cast = 0,
            cooldown = 40,
            gcd = "off",

            startsCombat = true,
            -- texture = ,

            talent = "primal_elementalist",

            usable = function () return storm_elemental.up and buff.call_lightning.remains >= 8 end,
            handler = function () end,
        },
    } )


    spec:RegisterSetting( "funnel_damage", false, {
        name = "Funnel AOE -> Target",
        desc = function ()
            local s = "If checked, the addon's default priority will encourage you to spread |T135813:0|t Flame Shock but will focus damage on your current target, using |T136026:0|t Earth Shock rather than |T451165:0|t Earthquake."

            if not Hekili.DB.profile.specs[ spec.id ].cycle then
                s = s .. "\n\n|cFFFF0000Requires 'Recommend Target Swaps' on Targeting tab.|r"
            end

            return s
        end, 
        type = "toggle",
        width = 1.5
    } )


    spec:RegisterStateExpr( "funneling", function ()
        return active_enemies > 1 and settings.cycle and settings.funnel_damage
    end )


    spec:RegisterSetting( "stack_buffer", 1.1, {
        name = "Icefury and Stormkeeper Padding",
        desc = "The default priority tries to avoid wasting Stormkeeper and Icefury stacks with a grace period of 1.1 GCDs per stack.\n\n" ..
                "Increasing this number will reduce the likelihood of wasted Icefury / Stormkeeper stacks due to other procs taking priority, and leave you with more time to react.",
        type = "range",
        min = 1,
        max = 2,
        step = 0.01,        
    } )


    spec:RegisterPack( "Elemental", 20190810.2145, [[devlfcqib4rcexsGu2Kq5tkQQgfOYPaLwfkkVsrXSeOUfOWUi1VuuAykQCmqvldfvpJeQPPOkxtrW2iH4BOquJtrvX5ibP1HcP6DKqs08afDpfP9rc8puis1bjHulur0djbXefivxurOnscj(ikKIrscjHtIcLwjkYlrHizMcKCtuizNkP8tuiIHIcHLIcP0tfYuvs1vvuv6RKqsnwsijDwuiszVk1FLQbl6WuTyu6XszYq1LvTzq(mjnAbDAKETq1SbUTc7wYVHmCL44OqXYr8CunDIRdLTJc(UsY4jb15fqRhfQMpjA)uEd)E9DeUlFVgZNdEf6CZh4NtZC4N38H57ijWLVJw8wCx97OYhFhnrWhVehSJw8abihFV(oIJWiTVJcfzHZOp7SQujeJv3qJz50bgWfkQAehsMLthTz3rSyuGWyRn7oc3LVxJ5ZbVcDU5d8ZPzo8ZJrwXkEhXxEBVgZveMVJcP44V2S7i8ZB7OGy5ebF8sCGLrH(WlJPGyzOilCg9zNvLkHyS6gAmlNoWaUqrvJ4qYSC6OnRXuqSurJPIXflHFUGTK5ZbVc1syyjZHNrFU5mMmMcILkKqVupNr3ykiwcdlNV8BPIQ9d(4L4an2ILexcpXsj0llBHVfNwQw2qiaoAvXTuqwY)TKcz5bF8sCa3sNCl9Mqz4AJPGyjmSmOt5ol44worNiHworWhVehy5lHqpxBmfelHHLmA)aXWTurZBVW9QDlf64Zozqzzl8T4AJPGyjmSurJJB5ed8wIGSucVLrcImSCwlzuxoIOnMcILWWsgBjxL4YTecRQdOLQL0sqwkH3sfnJiOSeUXjQNBjGYfUL0YYggH8sSmIouiWQ3rleeef8DuqSCIGpEjoWYOqF4LXuqSmuKfoJ(SZQsLqmwDdnMLthyaxOOQrCizwoD0M1ykiwQOXuX4ILWpxWwY85GxHAjmSK5WZOp3CgtgtbXsfsOxQNZOBmfelHHLZx(Tur1(bF8sCGgBXsIlHNyPe6LLTW3ItlvlBieahTQ4wkil5)wsHS8GpEjoGBPtULEtOmCTXuqSegwg0PCNfCClNOtKqlNi4JxIdS8LqONRnMcILWWsgTFGy4wQO5Tx4E1ULcD8zNmOSSf(wCTXuqSegwQOXXTCIbElrqwkH3YibrgwoRLmQlhr0gtbXsyyjJTKRsC5wcHv1b0s1sAjilLWBPIMreuwc34e1ZTeq5c3sAzzdJqEjwgrhkey1gtgtbXYjQWVHjh3s2dHi3YgAW6ILSxLwCTLk6w7lc3YcvWi0jdimGLEtOOIBjQabQnMcILEtOOIRxiVHgSUmfc484gtbXsVjuuX1lK3qdwxMz6SqieUXuqS0BcfvC9c5n0G1LzMoRJPoEjUqrLXuqSmQ8fEisSK4uClzXGGoULCXfULShcrULn0G1flzVkT4w6fULlKdJfKi0s1sk3sCuDTXuqS0BcfvC9c5n0G1LzMolV8fEis6CXfUXK3ekQ46fYBObRlZmDwbjF0hoxojqJPGyP3ekQ46fYBObRlZmD27ejSFWhVehemfAAaIdEj6fcD4G(bF8sCaLl6xol44gtgtbXY5l)wgjiYi()YjwUqEdnyDXsScCo3soAClDCCULROaGL8fFvzjhHkTXK3ekQ46fYBObRlZmDwUGiJ4)lNemfAQ4GxIMliYi()Yj6xol44XGJ4u8(z4LODCCUUHWkbMkwPsItX7NHxI2XX5AAPGjmhSgtgtEtOOIRxiVHgSUmZ0zHOK3p4JxIdcMcnnaXbVenxqKr)GpEjoq)Yzbh3yYBcfvC9c5n0G1LzMolxqKr)GpEjoiyk0uXbVenxqKr)GpEjoq)Yzbh3yYBcfvC9c5n0G1LzMo7csOOYyYBcfvC9c5n0G1LzMo7bF8sCqNf4Cjyk0uXbVe9bF8sCqNf4Cr)Yzbh3yYBcfvC9c5n0G1LzMolWzW7SyeUemfAAaIdEj6d(4L4GolW5I(LZcoEm(YbGU4e1lCDl0PvhqvdLIwQWuXgtEtOOIRxiVHgSUmZ0zBHoT6aQAOu0snyk0u(YbGU4e1lCDl0PvhqvdLIwQkG5gtgtbXYjQWVHjh3YZWjbAPqh3sj8w6nbrSKYT0zWPaNfCTXuqSuH4CXYjbieoaJlwo8cZbGaTKczPeElv0m(ju5wUoXPILk6QDUqCGLmAphvE1ULuULlKZFjAJjVjuuXNYcqiCagxcMcn1z8tOY1E1oxioOtohvE1U(LZcoUXuqSKXwWOHgSUy5csOOYsk3YfYHo5LqDaiqlb0k(XTuqwgicJy5ebF8sCqWwIvGZ5w2qdwxSCffaS8fUL8qerabAm5nHIk(mtNDbjuufmfA6v4L3KJ3BObRlDWlvjegcDCyQ45uQeIsE)GpEjoqJTOujxqKr)GpEjoqJTymfelzSLCcbBrSebzzZ5cxBm5nHIk(mtNDfTW78W7eJjVjuuXNz6Scs(OpCUCsGbtHMko4LOfK8rF4C5Ka1VCwWXJXIbbPjNJkVAVli5dn5dNwCyYCJjVjuuXNz6Sy83PYhCJjVjuuXNz6SquY7h8XlXbbtHMgG4GxIMliYOFWhVehOF5SGJBm5nHIk(mtNLliYOFWhVehemfAQ4GxIMliYOFWhVehOF5SGJhdUaeh8s002HWibQF5SGJRuzaSyqqAA7qyKa1ylXcOHqaC0QstBhcJeOgBb2yWfG4GxI25Tx4E1U(LZcoUsLb0qiaoAvPDE7fUxTRXwG1ykiw6nHIk(mtN9orc7h8XlXbbtHMgG4GxIEHqhoOFWhVehq5I(LZcoUsLIdEj6fcD4G(bF8sCaLl6xol44XGdIsE)GpEjoqJJwvXcqCWlrZfez0p4JxId0VCwWXvQKliYOFWhVehOXrRQyIdEjAUGiJ(bF8sCG(LZcooSgtEtOOIpZ0zBOQ9siUC8oeWh3yYBcfv8zMollaHW7iOUe((Rpc0yYBcfv8zMoRkMtWPE1rqDNXpbjHgtEtOOIpZ0zHqnm(X7oJFcvEN9(WyYBcfv8zMo7cgHcfiTu7SaNlgtEtOOIpZ0zLW3XkwewH3HqK2nM8MqrfFMPZo(arcSJG6aSgfVJtUp4gtEtOOIpZ0zj0LfW70QZx82nM8MqrfFMPZUcra4mCA1jNJkVA3yYBcfv8zMollaHW7qyKadMcnnaXbVeTZBVW9QD9lNfCCLkzXGG0oV9c3R21ylkv2qiaoAvPDE7fUxTRjF40IRGjmNXK3ekQ4ZmDw2t4NeNwQbtHMgG4GxI25Tx4E1U(LZcoUsLSyqqAN3EH7v7ASfJjVjuuXNz6SquYzbieEWuOPbio4LODE7fUxTRF5SGJRujlgeK25Tx4E1UgBrPYgcbWrRkTZBVW9QDn5dNwCfmH5mM8MqrfFMPZ6v7CH4GEZbGGPqtdqCWlr782lCVAx)YzbhxPswmiiTZBVW9QDn2IsLnecGJwvAN3EH7v7AYhoT4kycZzm5nHIk(mtN9b(ocQlHVZfezemfAkxqKr)GpEjoqJTeJfdcs3CaOdOQHsrlvn5dNwCfmD(ym5nHIk(mtNDC5iIXK3ekQ4ZmDwcw19Mqrvhq5sWLp(uh9GPqt9Mqz49xFqpxbmpwaqyvDaTunM8MqrfFMPZsWQU3ekQ6akxcU8XNYPLk4DXjQxmMmMcILmkmGqTuCI6fl9MqrLLlekIqLaTeq5IXK3ekQ4Ah9PCbrgX)xojyk0uXbVenxqKr8)Lt0VCwWXnMcILrlK74wQOa8XTmke1IBjTSeMtTCEwkor9ILqu1qHhSLSyILfsSehJqlvlJMOLylcD8GXkW5CldeHn)KBjevnuOLQLk2sXjQx4w6fULHod3sW5ClLqVSe(5zPIAAHBjJgmUyjx8wCU2yYBcfvCTJ(mtNfc4J35HOw8GBb2aVlor9cFk8btHMsoe58qNf8yWXxoa0fNOEHRBHoT6aQAOu0sfMWnbyeG4GxIwqYh9HZLtcu)YzbhhwLkdqCWlrZfez0p4JxId0VCwWXJbheL8(bF8sCGM8HtlUcGd(5Xm(YbGEOZLdRsLnecGJwvAik59d(4L4an5dNwCychZNhmGFEmJVCaOh6C5WclSXGlaXbVenxqKr)GpEjoq)YzbhxPsUGiJ(bF8sCGghTQuQKVCaOlor9cx3cDA1bu1qPOL6ufhJfdcsVIw4DvmUO5I3Idt4NhSgtEtOOIRD0Nz6SoV9c3R2dMcnvCWlr782lCVAx)YzbhpgCIdEjAUGiJ(bF8sCG(LZcoEmUGiJ(bF8sCGghTQI1qiaoAvP5cIm6h8XlXbAYhoT4ka(jOuzaIdEjAUGiJ(bF8sCG(LZcooSXGlaXbVenTDimsG6xol44kvgalgeKM2oegjqn2sSaAieahTQ002HWibQXwG1yYBcfvCTJ(mtNfqzmyu8(WvhExqYhbtHMko4LObugdgfVpC1H3fK8H(LZcoUXKXuqSCDsGwkilv9XTCIorczmyE8B5kQeAjJY5YjwIGSucVLte8XlHBjlgeKLRcFzjevnuOLQLk2sXjQx4Ald6OA(flrmCsZxSKr5hWfcAeGXK3ekQ4Ah9zMo7DIeYyW84pyk00aeh8s0dNlN0rqDj89d(4LW1VCwWXTuPslzXGG0CbrgX)xorJTyPsLwo8d4cbnuWu4GFU5GX8ygF5aqxCI6fUUf60QdOQHsrlvyTuPslzXGG0dNlN0rqDj89d(4LW1ylwQuPL8LdaDXjQx46wOtRoGQgkfTuvGInM8Mqrfx7OpZ0zVtKqgdMh)btHMcxaIdEj6HZLt6iOUe((bF8s46xol44kvYIbbPhoxoPJG6s47h8XlHRXwuQKfdcsdCg8ohJOEnoAvPujF5aqxCI6fU(orczmyE8RGPZd2yWXIbbP5cImI)VCIgBrPYHFaxiOHcMch8ZnhmMhZ4lha6ItuVW1TqNwDavnukAPcRsLSyqq6HZLt6iOUe((bF8s4ASfLk5lha6ItuVW1TqNwDavnukAPQafdRXuqSKr5XVLCmYTmqeML4OA(flbi(T0TmsqKr8)Lt0gtEtOOIRD0Nz6STqNwDavnukAPgmfAklgeKMliYi()YjAYhoT4WuXmtTHZmwmiinxqKr8)Lt0CXBXnMmMcILmskqGw2CUyzq5m4wojgHlwIklLqYVLItuVWTKczjvSKYT0llPfx8sS0lClJeezy5ebF8sCGLuULRXizDl9Mqz4AJjVjuuX1o6ZmDwGZG3zXiCjyk0uwmiinWzW7CmI61ylX4lha6ItuVW1TqNwDavnukAPcZ5fdUaeh8s0Cbrg9d(4L4a9lNfCCLk5cIm6h8XlXbAC0Qc2y4irdb8X78qulUwOT40s1yYBcfvCTJ(mtNL2oegjWGPqt5lha6ItuVW1TqNwDavnukAPcZ5flawmiiTZBVW9QDn2IXK3ekQ4Ah9zMolebXLope1IhmfAkF5aqxCI6fUUf60QdOQHsrlvyoVySyqqAA7qyKa1ylXcGfdcs782lCVAxJTymzmfelNV8B5ebF8sCGLtcCUyPR60IlwITyPGSuXwkor9c3sNBjavQw6ClJeezy5ebF8sCGLuULfsS0BcLHRnM8Mqrfx7OpZ0zp4JxId6SaNlbtHMko4LOp4JxId6SaNl6xol44X4lha6ItuVW1TqNwDavnukAPcZ5fdUaeh8s0Cbrg9d(4L4a9lNfCCLk5cIm6h8XlXbAC0QcwJjVjuuX1o6ZmDwGZG3zVpcMcnvCWlr782lCVAx)Yzbh3yYBcfvCTJ(mtNTf60QdOQHsrlvJjVjuuX1o6ZmDwGZG3zXiCj4bIbAPof(GPqtfh8s0oV9c3R21VCwWXnM8Mqrfx7OpZ0zHa(4DEiQfp4bIbAPof(GBb2aVlor9cFk8btHMsoe58qNfCJjVjuuX1o6ZmDwicIlDEiQfp4bIbAPofEJjJPGyzq)qogqSur3ekQSKrqOicvc0YGIYfJPGyPI6BjoQMFXY6h3sbzjhBzbrelNFgCc1zbxdHv1b0sD(TegWWshhhvwg6ClNFiSQoGwQZVL0soPCaiWGTK15h3suzjF5nl5xeAPY1gtbXsVjuuX1CAPcExCI6LPm4eQZcEWLp(uiSQoGwQbZGdW(uVjugE)1h0Zva8XGJVCaOlor9cx3cDA1bu1qPOLkmzUsL8LdaDXjQx4AGZG3zVpGjZH1ykiwoXIJrULkkrws5w6nHYWTeRaNZTmqeMLHod3s4NNLiILde5wYfVfNBjcYsf10c3sgnyCXsicAyzKGidlNi4JxId0wc3eXvVLnNFgDlXwAObTuTurZBwYIjw6nHYWTmAIkQ0sCun)ILWAm5nHIkUMtlvW7ItuVmfc4J35HOw8GBb2aVlor9cFk8btHMcxacTfNwQkvko4LO5cIm6h8XlXb6xol44XAieahTQ0Cbrg9d(4L4an5dNwCyYCMP2WvQehjAiGpENhIAX1KpCAXH5u1gUsLIdEjAN3EH7v76xol44XWrIgc4J35HOwCn5dNwCycxdHa4OvL25Tx4E1UM8Htl(mSyqqAN3EH7v7ACmIluubBSgcbWrRkTZBVW9QDn5dNwCyoVyWfG4GxIMliYOFWhVehOF5SGJRuP4GxIMliYOFWhVehOF5SGJhJliYOFWhVehOXrRkyHngCSyqq6v0cVRIXfnx8wCyc)8uQ0z8tOY1u16imEFbjVeQd0eVIRGPmxPswmiinWzW7CmI61ylkvgalgeKMfGq4amUOXwGnwaSyqqAogr9DeuFbT6en2IXuqSC(YVLkAE7fUxTBPdjNyzGiS5NHBjF5LyPdawguodULtIr4ILTqNOEULEHBjQabAjfYY6uj8elJeezy5ebF8sCGLfIyjJTDimsGw6KBzdJqEjGaT0BcLHRnM8MqrfxZPLk4DXjQxMz6SoV9c3R2dMcnvCWlr782lCVAx)YzbhpwdHa4OvLg4m4Dwmcx0KpCAXvWCXGJliYOFWhVehOXrRkLkdqCWlrZfez0p4JxId0VCwWXHngCbio4LOPTdHrcu)YzbhxPYayXGG002HWibQXwIfqdHa4OvLM2oegjqn2cSgtbXYGoQMFXsm(TCIGpEjoWYjboxSKczzGimlBimaULnNlw6wYOCUCILiilLWB5ebF8s4w(XcA1jh3Yj6ej0YOqulUL0Il3X1wg0r18lw2CUy5ebF8sCGLtcCUyjogHwQwgjiYWYjc(4L4alXkW5CldeHzzOZWTuXkSLR5cgXbwQOcNmqvGAlNetSKwwkHuULnNFl5cAXsmoTuTCIGpEjoWYjboxSevTBzGimlj3BHwc)8SKlElo3seKLkQPfULmAW4I2yYBcfvCnNwQG3fNOEzMPZEWhVeh0zboxcMcnvCWlrFWhVeh0zbox0VCwWXJbN4GxIE4C5KocQlHVFWhVeU(LZcoEmwmii9W5YjDeuxcF)GpEjCn2sSHFaxiObmvK5uQmaXbVe9W5YjDeuxcF)GpEjC9lNfCCyJbxaWXfez0p4JxId0ylXeh8s0Cbrg9d(4L4a9lNfCCyvQ0z8tOY1Llyeh0dDYavbQjEfFQIJXIbbPxrl8Ukgx0CXBXHj8ZdwJPGyjJu)lwgXiLLqiILaNOElrel5iuzPJJB5kNHZ1woFlW5CldeHzzOZWTmcJOElrqwYiqRojylPLLRcPTqlBo)wgicZYvEjwkilXrySGBjlgeKLbfvnukAPA5KiGyjBGwUGqaAPAjJYpGle0Ws2dHip0lCTLtuH9Xc4wYpJb7v7m6wc)CZXOIc2YjgfSLrmsfSLb1KbBzqXWKbB5eJc2YGAsJjVjuuX1CAPcExCI6LzMolxqKr8)LtcMcnvCWlrZfeze)F5e9lNfC8yWrCkE)m8s0ooox3qyLatfRujXP49ZWlr744CnTuWeMd2yWfG4GxIMJruFhb1xqRor)YzbhxPswmiinhJO(ocQVGwDIgBrPYHFaxiOHcMoV5bRXK3ekQ4AoTubVlor9YmtNfqzmyu8(WvhExqYhbtHMko4LObugdgfVpC1H3fK8H(LZcoEm4iofVFgEjAhhNRBiSsGPIvQK4u8(z4LODCCUMwkycZbRXuqSuHGgS06wgjiYi()YjwUIkHwYOCUCILiilLWB5ebF8s4wIiwgHruVLiilzeOvNyjwboNBzGimldDgULs4TmOCgClJcrT4wkeNkw6fULdmGqxa3sU4T48GTeRaNZTecRQdOLQ2yYBcfvCnNwQG3fNOEzMPZcOQHsrl1olcibtHMgaewvhql1ySyqqAUGiJ4)lNOXwIXxoa0fNOEHRBHoT6aQAOu0sfMmpgCoJFcvUg4m4DEiQfxt8koZyXGG0aNbVZdrT4AU4T4WctMRiXGJfdcspCUCshb1LW3p4JxcxJTelaXbVenhJO(ocQVGwDI(LZcoUsLSyqqAogr9DeuFbT6en2cSgtbXYiF8GTKftSCv4llHWQ6aAPgSLnNlwgutAjwboNBPeEYT0j3sfzglfNOEHRnM8MqrfxZPLk4DXjQxMz6STqNwDavnukAPgmfAkewvhql1ySyqqAUGiJ4)lNOXwIbNZ4NqLRbodENhIAX1eVIZmwmiinWzW78qulUMlEloSWuXksm4yXGG0dNlN0rqDj89d(4LW1ylXcqCWlrZXiQVJG6lOvNOF5SGJRujlgeKMJruFhb1xqRorJTaRXuqSKXczzHelHWQ6aAPgSLy8B5eDIeYyW843sgoHJXTK5wkor9cpylXkW5CldeHzzOZWTmOCgClJcrT4AlNV8B5eDIeYyW843sgoHJXTeElfNOEXskKLbIWSm0z4wU(BcQOnlxpeRWpXsfBPqhNBPx4wUgJelJWiQ3seKLmc0QtS8LZcoULEHB5AmsSmOCgClJcrT4AJjVjuuX1CAPcExCI6LzMo7DIeYyW84pyk00aGWQ6aAPgdo44lha6ItuVW1TqNwDavnukAPQa4vQ0z8tOY1YBcQOTUeIv4NOjEfxbtvCSaeh8s0CmI67iO(cA1j6xol44XCg)eQCnWzW78qulUM4vCycpSXCg)eQCnWzW78qulUM4vCMXIbbPbodENhIAX1CXBXHjCkwrMrXmZz8tOY1YBcQOTUeIv4NOjEfNz8LdaDXjQx46wOtRoGQgkfTuHngCbio4LO5ye13rq9f0Qt0VCwWXvQmaCKOHa(4DEiQfxtoe58qNfCLk5cIm6h8XlXbASfyJbxaIdEj6HZLt6iOUe((bF8s46xol44kvYIbbPhoxoPJG6s47h8XlHRXwuQSHqaC0QsdCg8olgHlAYhoT4kyUyd)aUqqdfmvHY8zu8CmtCWlr3CaOlHVlHyf(j6xol44WcRXuqSuH4CXYj6ej0YOqulULROsOLmkNlNyjcYsj8worWhVeULIdEjwYIjwwil9Mqz4wgHruVLiilzeOvNyjlgeuWw6fULEtOmClJeeze)F5elzXGGS0lCldkNb3YjXiCXYgAqlvlrqqwQqc6wUIkH0Ysj8wwxHflz0Oqc6bBPx4wEQeEILEtOmClzuoxoXseKLs4TCIGpEjClzXGGc2seXYczPZGtbol4wguodULtIr4ILRcPGBzDNyjJkYYMVeSLiILCAPcULItuVyPx4woWacDbCldkNb3YOqulULcXPc3sVWTC4vGwYfVfNRnM8MqrfxZPLk4DXjQxMz6S3jsyNhIAXdMcnnaiSQoGwQXcGfdcsZXiQVJG6lOvNOXwIjo4LOhoxoPJG6s47h8XlHRF5SGJhdowmii9W5YjDeuxcF)GpEjCn2IsLnecGJwvAGZG3zXiCrt(WPfxbZfB4hWfcAOGPkuMpJINJzIdEj6MdaDj8DjeRWpr)YzbhxPs(YbGU4e1lCDl0PvhqvdLIwQWK5XGZz8tOY1aNbVZdrT4AIxXzglgeKg4m4DEiQfxZfVfhMmxrGnglgeKMliYi()YjASLynecGJwvAGZG3zXiCrt(WPfhMtvB4WAmfelJ8XT05wUqoduegpylzXelxrLqeMyjCKdBl8T40s1sfsqzP4e1lClxfsb3siSQoGwQAJjVjuuX1CAPcExCI6LzMo7DIe25HOw8GPqtHWQ6aAPglawmiinhJO(ocQVGwDIgBjM4GxIE4C5KocQlHVFWhVeU(LZcoEm4yXGG0dNlN0rqDj89d(4LW1ylkv2qiaoAvPbodENfJWfn5dNwCfmxSHFaxiOHcMQqz(mkEoMjo4LOBoa0LW3LqSc)e9lNfCCLkHZz8tOY1aNbVZdrT4AIxXzglgeKg4m4DEiQfxZfVfhMkwrGnglgeKMliYi()YjASLynecGJwvAGZG3zXiCrt(WPfhMtvB4WAmfelviyeYlXYjc(4L4alv0mIGYYvOA(flX43YGY5CKLRcPGBjewvhql1GTKJSKXo)dljNV8MqlvlLqxSm8KRnM8MqrfxZPLk4DXjQxMz6SaQAOu0sTdCohzmfelzKgcZY4fALLRcDHr6wYyTm0XTKJg3sEiIiwEfEb4Lluuzz4j3su1U2YjXelLWxwkH3YgQWPcfvwQs(QGT0lClzSwg64wkil5laQyPeElr1TCIorcTmke1IBjGw3sAjilHqyeTwZrwgicZYqNHBPGSe)oWYvuj0sjKYT0zrdA5cfvwwOvm6wQqCUy5eDIeAzuiQf3YvujeHjwYOCUCILiilLWB5ebF8s4wko4LeSLEHB5kQeIWeldDgOLQLcHUaULmw16imULmcK8sOoWsVWT0BcLHBPIM3EH7v7bBPx4w6nHYWTmsqKr8)LtSKfdcYseXY6oXsgvKLnFjylrelJeezy5ebF8sCGLuUL0YBcLHhSLEHB5QBzZR5xS8k8YBILcYs1lw6LLooovOOYbwIXVLiilJeezy5ebF8sCGL0Ysj8ws(WPfTuTeIQgkwcrqdlJWiQ3seKLmc0Qt0gtEtOOIR50sf8U4e1lZmD27ejSZdrT4btHMgG4GxIE4C5KocQlHVFWhVeU(LZcoESaGZz8tOY1u16imEFbjVeQd0eVIRaMhJfdcs782lCVAxJTaBm4yXGG0CbrgX)xorJTOu5WpGle0qbtvOZnJINJzIdEj6MdaDj8DjeRWpr)YzbhxPYaGJliYOFWhVehOXwIjo4LO5cIm6h8XlXb6xol44Wg7k8YBYX7n0G1Lo4LQecdHoomAieahTQ0Cbrg9d(4L4an5dNwCya)eMJzqaeIahCxHxEtoEVHgSU0bVuLqyi0XHrdHa4OvLMliYOFWhVehOjF40IdBqd(jmhSkyQINJzWb)mW5m(ju563crDeuxcF)GpEjoGRjEfxbtzoSWcRXuqSC(YVLt0jsOLrHOwClPqwgHruVLiilzeOvNyjLBP4GxYXd2swmXY6uj8elPILfIyPBzqNrez5ebF8sCGLuULEtOmClDXsj8woqJxsWw6fULbLZGB5KyeUyjLBj5oEGwIiwUIcawYElj3Xd0YvujKwwkH3Y6kSyjJgfsqxBm5nHIkUMtlvW7ItuVmZ0zVtKWope1IhmfAQ4GxIMJruFhb1xqRor)YzbhpwaSyqqAogr9DeuFbT6en2sSgcbWrRknWzW7SyeUOjF40IdZPQn8yWfG4GxIMliYOFWhVehOF5SGJhla4GOK3p4JxId0ylWQuP4GxIMliYOFWhVehOF5SGJhla44cIm6h8XlXbASfyH1yYBcfvCnNwQG3fNOEzMPZcOQHsrl1oW5CuWuOP4irdb8X78qulUwOT40svPYgcbWrRkneWhVZdrT4AYhoT4gtbXsglKLfsSecRQdOLAWwYx8HLbfvnukAPA5KiGWTehJqlvlJeezy5ebF8sCGL4yexOOkylPqwgicZsCun)ILHod3sgRADeg3sgbsEjuhyjIyzOZWTKkwIkqGwIQ2d2sVWTehvZVyjg)wguu1qPOLQLtIaIL4yeAPA5KaechGXflPqwgicZYqNHBPBzq5m4wgHruVLmccQPnM8MqrfxZPLk4DXjQxMz6SaQAOu0sTZIasWuOPbaHv1b0sngxqKr)GpEjoqJTetCWlrZfez0p4JxId0VCwWXJbNZ4NqLRPQ1ry8(csEjuhOjEfhMmxPYayXGG0aNbVZXiQxJTeJfdcsZcqiCagx0ylWAmfelzSqwwiXsiSQoGwQbBzZ5ILbfvnukAPA5KiGyj5QobhCo3seKLs4TCHCgOimULnuHtfkQSKczzGiS5h3saIFlDlJeeze)F5el5I3IBjIyzOZWTmsqKr8)LtS0lClzuoxoXseKLs4TCIGpEjCl9Mqz4AJjVjuuX1CAPcExCI6LzMolGQgkfTu7SiGemfAAaqyvDaTuJbhlgeKMliYi()YjAYhoT4WeEn8mtTHZmwmiinxqKr8)Lt0CXBXvQKfdcsZfeze)F5en2smwmii9W5YjDeuxcF)GpEjCn2cSgtbXsglKLqyvDaTud2s(IpSuHe60YYGIQgkfTuTehJqlvlJeezy5ebF8sCGL4yexOOkylPqwgicZsCun)ILHod3sgRADeg3sgbsEjuhyjIyzOZWTKkwIkqGwIQ2d2sVWTehvZVyjg)wguu1qPOLQLtIaIL4yeAPA5KaechGXflPqwgicZYqNHBPBzq5m4wgHruVLmccQPnM8MqrfxZPLk4DXjQxMz6STqNwDavnukAPgmfAkewvhql1yCbrg9d(4L4an2smXbVenxqKr)GpEjoq)YzbhpgCoJFcvUMQwhHX7li5LqDGM4vCyYCLkdGfdcsdCg8ohJOEn2smwmiinlaHWbyCrJTaRXuqSuH4CXsfsOtlldkQAOu0s1sYvDco4CULiilLWB5c5mqryClBOcNkuuzjfYYaryZpULae)w6wgjiYi()YjwYfVf3seXYqNHBzKGiJ4)lNyPx4wYOCUCILiilLWB5ebF8s4w6nHYW1gtEtOOIR50sf8U4e1lZmD2wOtRoGQgkfTudMcnfcRQdOLAm4yXGG0CbrgX)xort(WPfhMWRHNzQnCMXIbbP5cImI)VCIMlElUsLSyqqAUGiJ4)lNOXwIXIbbPhoxoPJG6s47h8XlHRXwG1ykiwoF53sffcIlwgfIAXTCfvcTKX2oegjql9c3sgLZLtSebzPeElNi4JxcxBm5nHIkUMtlvW7ItuVmZ0zHiiU05HOw8GPqtfh8s002HWibQF5SGJhtCWlrpCUCshb1LW3p4Jxcx)YzbhpglgeKM2oegjqn2smwmii9W5YjDeuxcF)GpEjCn2IXK3ekQ4AoTubVlor9YmtNf4m4DwmcxcMcnLfdcs782lCVAxJTymfelNVcfqz8Bzegr9wIGSKrGwDILcYs(c5oULkkaFClJcrT4wsHSCGbe6c4w(6d65w6KB5c58xI2yYBcfvCnNwQG3fNOEzMPZcb8X78qulEWTaBG3fNOEHpf(GPqtjhICEOZcEmVjugE)1h0Zva8XyXGG0CmI67iO(cA1jASfJPGy58LFldkNb3YjXiCXYvuj0YimI6TebzjJaT6elPqwkH3sGZflxqYlH6alX4U6TebzzKGidlNi4JxIdSm0518lw6wcHbawIJrCHIklzKWO1skKLbIWSSHWa4wQEXsVqs4jwIXD1BjcYsj8wg0zerworWhVehyjfYsj8ws(WPfTuTeIQgkwUY5wcVIe0SeGk1t0gtEtOOIR50sf8U4e1lZmDwGZG3zXiCjyk0uXbVenxqKr)GpEjoq)YzbhpwdHa4OvvNCVjXyXGG0CmI67iO(cA1jASLyWDfE5n549gAW6sh8svcHHqhhgnecGJwvAUGiJ(bF8sCGM8HtlomGFcZXmiacrGdURWlVjhV3qdwx6GxQsime64WOHqaC0QsZfez0p4JxId0KpCAXHnOb)eMdwyQ45ygCWpdCoJFcvU(Tquhb1LW3p4JxId4AIxXvWuMdlSkvch8A4veMb3v4L3KJ3BObRlDWlvjegcDCyHrdHa4OvLMliYOFWhVehOjF40Idd4NWCmdcGqe4GdEn8kcZG7k8YBYX7n0G1Lo4LQecdHooSWOHqaC0QsZfez0p4JxId0KpCAXHnOb)eMdwyHjCxHxEtoEVHgSU0bVuLqyi0XHrdHa4OvLMliYOFWhVehOjF40Idd4NWCmdcGqe4G7k8YBYX7n0G1Lo4LQecdHoomAieahTQ0Cbrg9d(4L4an5dNwCydAWpH5GfwynMcILZx(TmOCgClNeJWflxrLqlJWiQ3seKLmc0QtSKczPeElboxSCbjVeQdSeJ7Q3seKLkkuYTCIGpEjoWYqNxZVyPBjegayjogXfkQSKrcJwlPqwgicZYgcdGBP6fl9cjHNyjg3vVLiilLWBzqNrez5ebF8sCGLuilLWBj5dNw0s1siQAOy5kNBj8ksqZsaQuprBm5nHIkUMtlvW7ItuVmZ0zbodENfJWLGPqtdqCWlrZfez0p4JxId0VCwWXJ1qiaoAv1j3BsmwmiinhJO(ocQVGwDIgBjgCxHxEtoEVHgSU0bVuLqyi0XHrdHa4OvLgIsE)GpEjoqt(WPfhgWpH5ygeaHiWb3v4L3KJ3BObRlDWlvjegcDCy0qiaoAvPHOK3p4JxId0KpCAXHnOb)eMdwyQ45ygCWpdCoJFcvU(Tquhb1LW3p4JxId4AIxXvWuMdlSkvch8A4veMb3v4L3KJ3BObRlDWlvjegcDCyHrdHa4OvLgIsE)GpEjoqt(WPfhgWpH5ygeaHiWbh8A4veMb3v4L3KJ3BObRlDWlvjegcDCyHrdHa4OvLgIsE)GpEjoqt(WPfh2Gg8tyoyHfMWDfE5n549gAW6sh8svcHHqhhgnecGJwvAik59d(4L4an5dNwCya)eMJzqaeIahCxHxEtoEVHgSU0bVuLqyi0XHrdHa4OvLgIsE)GpEjoqt(WPfh2Gg8tyoyHfwJjVjuuX1CAPcExCI6LzMolGQgkfTu7SiGemfAklgeKMJruFhb1xqRorJTym5nHIkUMtlvW7ItuVmZ0zbodENfJWLGPqtBieahTQ6K7njwaIdEj6HZLt6iOUe((bF8s46xol44gtbXYiavnuabAPQpULm22HWibAjlgeKLcYYq0YHWaGaTKfdcYsoACl)ybT6KJBPIcbXflJcrT4ClxrLqlzuoxoXseKLs4TCIGpEjCTXK3ekQ4AoTubVlor9YmtNL2oegjWGPqtfh8s002HWibQF5SGJhla4g(bCHGgkGrEcXAieahTQ0aNbVZIr4IM8HtlomNohSXGlaXbVenxqKr)GpEjoq)YzbhxPsUGiJ(bF8sCGghTQG1yYBcfvCnNwQG3fNOEzMPZcCg8olgHlbtHM2qiaoAv1j3BsSwOtupxbIdEj63crDeuxcF)GpEjC9lNfCCJPGyzeGQgkGaTe)apqlX40s1sgB7qyKaT8Jf0QtoULkkeexSmke1IZTuqw(XcA1jwkHFy5kQeAjJY5YjwIGSucVLte8XlHBPGqAJjVjuuX1CAPcExCI6LzMolebXLope1IhmfAQ4GxIM2oegjq9lNfC8ySyqqAA7qyKa1ylXyXGG002HWibQjF40Idt41WZm1goZyXGG002HWibQ5I3IBm5nHIkUMtlvW7ItuVmZ0zbodENfJWLGPqtBieahTQ6K7nXykiwg0r18lw6Tgf)L4aqGwIXVLrye1BjcYsgbA1jwUIkHwQOa8XTmke1IBjogHwQwYPLk4wkor9I2yYBcfvCnNwQG3fNOEzMPZcb8X78qulEWTaBG3fNOEHpf(GPqtjhICEOZcESayXGG0CmI67iO(cA1jASfJjVjuuX1CAPcExCI6LzMoRGKp6dNlNeyWuOPIdEjAbjF0hoxojq9lNfC8yWXIbbPjNJkVAVli5dn5dNwCyQikvchlgeKMCoQ8Q9UGKp0KpCAXHjCSyqqAN3EH7v7ACmIluuntdHa4OvL25Tx4E1UM8HtloSXAieahTQ0oV9c3R21KpCAXHj8tawynM8MqrfxZPLk4DXjQxMz6Sqeex68qulEWuOPIdEjAA7qyKa1VCwWXJXIbbPPTdHrcuJTedowmiinTDimsGAYhoT4WuTHZS5XmwmiinTDimsGAU4T4kvYIbbP5cImI)VCIgBrPYaeh8s0dNlN0rqDj89d(4LW1VCwWXH1ykiwUE4Te)qogqSmIouiwQOzebLLRqyaCllKyzZ5ILkKGYYvHuWTecRQdOLAWwYIjwU6ww)4wsflHqelfNOEXs8lVjuuzPx4wYOI0gtEtOOIR50sf8U4e1lZmD2wOtRoGQgkfTudMcnLfdcslVjOI26siwHFIgBjwaSyqqAUGiJ4)lNOXwIXxoa0fNOEHRBHoT6aQAOu0svbWBm5nHIkUMtlvW7ItuVmZ0zbu1qPOLANfbeJjVjuuX1CAPcExCI6LzMoleWhVZdrT4bpqmql1PWhClWg4DXjQx4tHpyk0uYHiNh6SGBm5nHIkUMtlvW7ItuVmZ0zHa(4DEiQfp4bIbAPof(GPqthig(4LOXPCXR2vGIymfelvuiiUyzuiQf3sk3segXYbIHpEjwcrbGt0gtEtOOIR50sf8U4e1lZmDwicIlDEiQfp4bIbAPof(DedNWPOAVgZNdEf6CZh4NBhTYjfTu57ig7ybrKJB58S0BcfvwcOCHRnM2rakx4713rCAPcExCI6L9671GFV(o6LZco(EYDK3ekQ2rqaF8ope1IVJAeQCc13rWzzawk0wCAPAPsLwko4LO5cIm6h8XlXb6xol44wgZYgcbWrRknxqKr)GpEjoqt(WPf3syAjZTKzwQ2WTuPslXrIgc4J35HOwCn5dNwClH5ulvB4wQuPLIdEjAN3EH7v76xol44wgZsCKOHa(4DEiQfxt(WPf3syAjCw2qiaoAvPDE7fUxTRjF40IB5mwYIbbPDE7fUxTRXXiUqrLLWAzmlBieahTQ0oV9c3R21KpCAXTeMwoplJzjCwgGLIdEjAUGiJ(bF8sCG(LZcoULkvAP4GxIMliYOFWhVehOF5SGJBzml5cIm6h8XlXbAC0QYsyTewlJzjCwYIbbPxrl8Ukgx0CXBXTeMwc)8SuPslDg)eQCnvTocJ3xqYlH6anXR4wQGPwYClvQ0swmiinWzW7CmI61ylwQuPLbyjlgeKMfGq4amUOXwSewlJzzawYIbbP5ye13rq9f0Qt0yl7OwGnW7ItuVW3Rb)w2RX8967Oxol447j3rncvoH67iXbVeTZBVW9QD9lNfCClJzzdHa4OvLg4m4Dwmcx0KpCAXTubwoNLXSeol5cIm6h8XlXbAC0QYsLkTmalfh8s0Cbrg9d(4L4a9lNfCClH1YywcNLbyP4GxIM2oegjq9lNfCClvQ0YaSKfdcstBhcJeOgBXYywgGLnecGJwvAA7qyKa1ylwc7oYBcfv7iN3EH7v7BzVMI3RVJE5SGJVNCh1iu5eQVJeh8s0h8XlXbDwGZf9lNfCClJzjCwko4LOhoxoPJG6s47h8XlHRF5SGJBzmlzXGG0dNlN0rqDj89d(4LW1ylwgZYHFaxiOHLW0sfzolvQ0YaSuCWlrpCUCshb1LW3p4Jxcx)Yzbh3syTmMLWzzawcNLCbrg9d(4L4an2ILXSuCWlrZfez0p4JxId0VCwWXTewlvQ0sNXpHkxxUGrCqp0jdufOM4vClNAPITmMLSyqq6v0cVRIXfnx8wClHPLWpplHDh5nHIQD0bF8sCqNf4Czl71M3E9D0lNfC89K7OgHkNq9DK4GxIMliYi()Yj6xol44wgZs4SK4u8(z4LODCCUUHWkXsyAPITuPsljofVFgEjAhhNRPLLkWYjmNLWAzmlHZYaSuCWlrZXiQVJG6lOvNOF5SGJBPsLwYIbbP5ye13rq9f0Qt0ylwQuPLd)aUqqdlvWulN38Se2DK3ekQ2rCbrgX)xozl71MWE9D0lNfC89K7OgHkNq9DK4GxIgqzmyu8(WvhExqYh6xol44wgZs4SK4u8(z4LODCCUUHWkXsyAPITuPsljofVFgEjAhhNRPLLkWYjmNLWUJ8Mqr1ocqzmyu8(WvhExqYhBzVMISxFh9YzbhFp5oQrOYjuFhfGLqyvDaTuTmMLSyqqAUGiJ4)lNOXwSmML8LdaDXjQx46wOtRoGQgkfTuTeMwYClJzjCw6m(ju5AGZG35HOwCnXR4wYmlzXGG0aNbVZdrT4AU4T4wcRLW0sMRiwgZs4SKfdcspCUCshb1LW3p4JxcxJTyzmldWsXbVenhJO(ocQVGwDI(LZcoULkvAjlgeKMJruFhb1xqRorJTyjS7iVjuuTJau1qPOLANfbKTSxJrEV(o6LZco(EYDuJqLtO(occRQdOLQLXSKfdcsZfeze)F5en2ILXSeolDg)eQCnWzW78qulUM4vClzMLSyqqAGZG35HOwCnx8wClH1syAPIvelJzjCwYIbbPhoxoPJG6s47h8XlHRXwSmMLbyP4GxIMJruFhb1xqRor)Yzbh3sLkTKfdcsZXiQVJG6lOvNOXwSe2DK3ekQ2rTqNwDavnukAPUL9AZN967Oxol447j3rncvoH67OaSecRQdOLQLXSeolHZs(YbGU4e1lCDl0PvhqvdLIwQwQalH3sLkT0z8tOY1YBcQOTUeIv4NOjEf3sfm1sfBzmldWsXbVenhJO(ocQVGwDI(LZcoULXS0z8tOY1aNbVZdrT4AIxXTeMwcVLWAzmlDg)eQCnWzW78qulUM4vClzMLSyqqAGZG35HOwCnx8wClHPLWzPIvelNXsfBjZS0z8tOY1YBcQOTUeIv4NOjEf3sMzjF5aqxCI6fUUf60QdOQHsrlvlH1YywcNLbyP4GxIMJruFhb1xqRor)Yzbh3sLkTmalXrIgc4J35HOwCn5qKZdDwWTuPsl5cIm6h8XlXbASflH1YywcNLbyP4GxIE4C5KocQlHVFWhVeU(LZcoULkvAjlgeKE4C5KocQlHVFWhVeUgBXsLkTSHqaC0QsdCg8olgHlAYhoT4wQalNZYywo8d4cbnSubtTuHYClNXsfpNLmZsXbVeDZbGUe(UeIv4NOF5SGJBjSwc7oYBcfv7O7ejKXG5X)w2RPq3RVJE5SGJVNCh1iu5eQVJcWsiSQoGwQwgZYaSKfdcsZXiQVJG6lOvNOXwSmMLIdEj6HZLt6iOUe((bF8s46xol44wgZs4SKfdcspCUCshb1LW3p4JxcxJTyPsLw2qiaoAvPbodENfJWfn5dNwClvGLZzzmlh(bCHGgwQGPwQqzULZyPINZsMzP4GxIU5aqxcFxcXk8t0VCwWXTuPsl5lha6ItuVW1TqNwDavnukAPAjmTK5wgZs4S0z8tOY1aNbVZdrT4AIxXTKzwYIbbPbodENhIAX1CXBXTeMwYCfXsyTmMLSyqqAUGiJ4)lNOXwSmMLnecGJwvAGZG3zXiCrt(WPf3syo1s1gULWUJ8Mqr1o6orc78qul(w2Rb)C713rVCwWX3tUJAeQCc13rqyvDaTuTmMLbyjlgeKMJruFhb1xqRorJTyzmlfh8s0dNlN0rqDj89d(4LW1VCwWXTmMLWzjlgeKE4C5KocQlHVFWhVeUgBXsLkTSHqaC0QsdCg8olgHlAYhoT4wQalNZYywo8d4cbnSubtTuHYClNXsfpNLmZsXbVeDZbGUe(UeIv4NOF5SGJBPsLwcNLoJFcvUg4m4DEiQfxt8kULmZswmiinWzW78qulUMlElULW0sfRiwcRLXSKfdcsZfeze)F5en2ILXSSHqaC0QsdCg8olgHlAYhoT4wcZPwQ2WTe2DK3ekQ2r3jsyNhIAX3YEn4HFV(oYBcfv7iavnukAP2boNJ2rVCwWX3tUL9AWZ8967Oxol447j3rncvoH67OaSuCWlrpCUCshb1LW3p4Jxcx)Yzbh3YywgGLWzPZ4NqLRPQ1ry8(csEjuhOjEf3sfyjZTmMLSyqqAN3EH7v7ASflH1YywcNLSyqqAUGiJ4)lNOXwSuPslh(bCHGgwQGPwQqNZYzSuXZzjZSuCWlr3CaOlHVlHyf(j6xol44wQuPLbyjCwYfez0p4JxId0ylwgZsXbVenxqKr)GpEjoq)Yzbh3syTmMLxHxEtoEVHgSU0bVuLqlHHLcDClHHLnecGJwvAUGiJ(bF8sCGM8HtlULWWs4NWCwYmlHaieXs4SeolVcV8MC8EdnyDPdEPkHwcdlf64wcdlBieahTQ0Cbrg9d(4L4an5dNwClH1YGMLWpH5SewlvWulv8CwYmlHZs4TCglHZsNXpHkx)wiQJG6s47h8XlXbCnXR4wQGPwYClH1syTe2DK3ekQ2r3jsyNhIAX3YEn4v8E9D0lNfC89K7OgHkNq9DK4GxIMJruFhb1xqRor)Yzbh3YywgGLSyqqAogr9DeuFbT6en2ILXSSHqaC0QsdCg8olgHlAYhoT4wcZPwQ2WTmMLWzzawko4LO5cIm6h8XlXb6xol44wgZYaSeolHOK3p4JxId0ylwcRLkvAP4GxIMliYOFWhVehOF5SGJBzmldWs4SKliYOFWhVehOXwSewlHDh5nHIQD0DIe25HOw8TSxd(5TxFh9YzbhFp5oQrOYjuFhHJeneWhVZdrT4AH2ItlvlvQ0YgcbWrRkneWhVZdrT4AYhoT47iVjuuTJau1qPOLAh4CoAl71GFc713rVCwWX3tUJAeQCc13rbyjewvhqlvlJzjxqKr)GpEjoqJTyzmlfh8s0Cbrg9d(4L4a9lNfCClJzjCw6m(ju5AQADegVVGKxc1bAIxXTeMwYClvQ0YaSKfdcsdCg8ohJOEn2ILXSKfdcsZcqiCagx0ylwc7oYBcfv7iavnukAP2zrazl71Gxr2RVJE5SGJVNCh1iu5eQVJcWsiSQoGwQwgZs4SKfdcsZfeze)F5en5dNwClHPLWRH3sMzPAd3sMzjlgeKMliYi()YjAU4T4wQuPLSyqqAUGiJ4)lNOXwSmMLSyqq6HZLt6iOUe((bF8s4ASflHDh5nHIQDeGQgkfTu7SiGSL9AWZiVxFh9YzbhFp5oQrOYjuFhbHv1b0s1YywYfez0p4JxId0ylwgZsXbVenxqKr)GpEjoq)Yzbh3YywcNLoJFcvUMQwhHX7li5LqDGM4vClHPLm3sLkTmalzXGG0aNbVZXiQxJTyzmlzXGG0SaechGXfn2ILWUJ8Mqr1oQf60QdOQHsrl1TSxd(5ZE9D0lNfC89K7OgHkNq9DeewvhqlvlJzjCwYIbbP5cImI)VCIM8HtlULW0s41WBjZSuTHBjZSKfdcsZfeze)F5enx8wClvQ0swmiinxqKr8)Lt0ylwgZswmii9W5YjDeuxcF)GpEjCn2ILWUJ8Mqr1oQf60QdOQHsrl1TSxdEf6E9D0lNfC89K7OgHkNq9DK4GxIM2oegjq9lNfCClJzP4GxIE4C5KocQlHVFWhVeU(LZcoULXSKfdcstBhcJeOgBXYywYIbbPhoxoPJG6s47h8XlHRXw2rEtOOAhbrqCPZdrT4BzVgZNBV(o6LZco(EYDuJqLtO(oIfdcs782lCVAxJTSJ8Mqr1oc4m4Dwmcx2YEnMd)E9D0lNfC89K7iVjuuTJGa(4DEiQfFh1iu5eQVJihICEOZcULXS0BcLH3F9b9ClvGLWBzmlzXGG0CmI67iO(cA1jASLDulWg4DXjQx471GFl71yoZ3RVJE5SGJVNCh1iu5eQVJeh8s0Cbrg9d(4L4a9lNfCClJzzdHa4OvvNCVjwgZswmiinhJO(ocQVGwDIgBXYywcNLxHxEtoEVHgSU0bVuLqlHHLcDClHHLnecGJwvAUGiJ(bF8sCGM8HtlULWWs4NWCwYmlHaieXs4SeolVcV8MC8EdnyDPdEPkHwcdlf64wcdlBieahTQ0Cbrg9d(4L4an5dNwClH1YGMLWpH5SewlHPLkEolzMLWzj8woJLWzPZ4NqLRFle1rqDj89d(4L4aUM4vClvWulzULWAjSwQuPLWzj8A4velzMLWz5v4L3KJ3BObRlDWlvj0syyPqh3syTegw2qiaoAvP5cIm6h8XlXbAYhoT4wcdlHFcZzjZSecGqelHZs4SeEn8kILmZs4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjSwcdlBieahTQ0Cbrg9d(4L4an5dNwClH1YGMLWpH5SewlH1syAjCwEfE5n549gAW6sh8svcTegwk0XTegw2qiaoAvP5cIm6h8XlXbAYhoT4wcdlHFcZzjZSecGqelHZs4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjmSSHqaC0QsZfez0p4JxId0KpCAXTewldAwc)eMZsyTewlHDh5nHIQDeWzW7SyeUSL9AmxX713rVCwWX3tUJAeQCc13rbyP4GxIMliYOFWhVehOF5SGJBzmlBieahTQ6K7nXYywYIbbP5ye13rq9f0Qt0ylwgZs4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjmSSHqaC0QsdrjVFWhVehOjF40IBjmSe(jmNLmZsiacrSeolHZYRWlVjhV3qdwx6GxQsOLWWsHoULWWYgcbWrRkneL8(bF8sCGM8HtlULWAzqZs4NWCwcRLW0sfpNLmZs4SeElNXs4S0z8tOY1VfI6iOUe((bF8sCaxt8kULkyQLm3syTewlvQ0s4SeEn8kILmZs4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjSwcdlBieahTQ0quY7h8XlXbAYhoT4wcdlHFcZzjZSecGqelHZs4SeEn8kILmZs4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjSwcdlBieahTQ0quY7h8XlXbAYhoT4wcRLbnlHFcZzjSwcRLW0s4S8k8YBYX7n0G1Lo4LQeAjmSuOJBjmSSHqaC0QsdrjVFWhVehOjF40IBjmSe(jmNLmZsiacrSeolHZYRWlVjhV3qdwx6GxQsOLWWsHoULWWYgcbWrRkneL8(bF8sCGM8HtlULWAzqZs4NWCwcRLWAjS7iVjuuTJaodENfJWLTSxJ5ZBV(o6LZco(EYDuJqLtO(oIfdcsZXiQVJG6lOvNOXw2rEtOOAhbOQHsrl1olciBzVgZNWE9D0lNfC89K7OgHkNq9DudHa4OvvNCVjwgZYaSuCWlrpCUCshb1LW3p4Jxcx)YzbhFh5nHIQDeWzW7SyeUSL9Amxr2RVJE5SGJVNCh1iu5eQVJeh8s002HWibQF5SGJBzmldWs4SC4hWfcAyPcSKrEcwgZYgcbWrRknWzW7SyeUOjF40IBjmNA5CwcRLXSeoldWsXbVenxqKr)GpEjoq)Yzbh3sLkTKliYOFWhVehOXrRklHDh5nHIQDeTDimsGBzVgZzK3RVJE5SGJVNCh1iu5eQVJAieahTQ6K7nXYyw2cDI65wQalfh8s0VfI6iOUe((bF8s46xol447iVjuuTJaodENfJWLTSxJ5ZN967Oxol447j3rncvoH67iXbVenTDimsG6xol44wgZswmiinTDimsGASflJzjlgeKM2oegjqn5dNwClHPLWRH3sMzPAd3sMzjlgeKM2oegjqnx8w8DK3ekQ2rqeex68qul(w2RXCf6E9D0lNfC89K7OgHkNq9DudHa4OvvNCVj7iVjuuTJaodENfJWLTSxtXZTxFh9YzbhFp5oYBcfv7iiGpENhIAX3rncvoH67iYHiNh6SGBzmldWswmiinhJO(ocQVGwDIgBzh1cSbExCI6f(En43YEnfd)E9D0lNfC89K7OgHkNq9DK4GxIwqYh9HZLtcu)Yzbh3YywcNLSyqqAY5OYR27cs(qt(WPf3syAPIyPsLwcNLSyqqAY5OYR27cs(qt(WPf3syAjCwYIbbPDE7fUxTRXXiUqrLLZyzdHa4OvL25Tx4E1UM8HtlULWAzmlBieahTQ0oV9c3R21KpCAXTeMwc)eSewlHDh5nHIQDKGKp6dNlNe4w2RPyMVxFh9YzbhFp5oQrOYjuFhjo4LOPTdHrcu)Yzbh3YywYIbbPPTdHrcuJTyzmlHZswmiinTDimsGAYhoT4wctlvB4wYmlNNLmZswmiinTDimsGAU4T4wQuPLSyqqAUGiJ4)lNOXwSuPsldWsXbVe9W5YjDeuxcF)GpEjC9lNfCClHDh5nHIQDeebXLope1IVL9AkwX713rVCwWX3tUJAeQCc13rSyqqA5nbv0wxcXk8t0ylwgZYaSKfdcsZfeze)F5en2ILXSKVCaOlor9cx3cDA1bu1qPOLQLkWs43rEtOOAh1cDA1bu1qPOL6w2RP45TxFh5nHIQDeGQgkfTu7SiGSJE5SGJVNCl71u8e2RVJE5SGJVNCh5nHIQDeeWhVZdrT47OwGnW7ItuVW3Rb)oQrOYjuFhroe58qNf8D0aXaTu3rWVL9Akwr2RVJE5SGJVNCh1iu5eQVJgig(4LOXPCXR2TubwQi7iVjuuTJGa(4DEiQfFhnqmql1De8BzVMIzK3RVJgigOL6oc(DK3ekQ2rqeex68qul(o6LZco(EYTSLDKJ(E99AWVxFh9YzbhFp5oQrOYjuFhjo4LO5cImI)VCI(LZco(oYBcfv7iUGiJ4)lNSL9AmFV(o6LZco(EYDK3ekQ2rqaF8ope1IVJAeQCc13rKdrop0zb3YywcNL8LdaDXjQx46wOtRoGQgkfTuTeMwcNLtWsyyzawko4LOfK8rF4C5Ka1VCwWXTewlvQ0YaSuCWlrZfez0p4JxId0VCwWXTmMLWzjeL8(bF8sCGM8HtlULkWs4Se(5zjZSKVCaOh6C5wcRLkvAzdHa4OvLgIsE)GpEjoqt(WPf3syAjCwY85zjmSe(5zjZSKVCaOh6C5wcRLWAjSwgZs4Smalfh8s0Cbrg9d(4L4a9lNfCClvQ0sUGiJ(bF8sCGghTQSuPsl5lha6ItuVW1TqNwDavnukAPA5ulvSLXSKfdcsVIw4DvmUO5I3IBjmTe(5zjS7OwGnW7ItuVW3Rb)w2RP4967Oxol447j3rncvoH67iXbVeTZBVW9QD9lNfCClJzjCwko4LO5cIm6h8XlXb6xol44wgZsUGiJ(bF8sCGghTQSmMLnecGJwvAUGiJ(bF8sCGM8HtlULkWs4NGLkvAzawko4LO5cIm6h8XlXb6xol44wcRLXSeoldWsXbVenTDimsG6xol44wQuPLbyjlgeKM2oegjqn2ILXSmalBieahTQ002HWibQXwSe2DK3ekQ2roV9c3R23YET5TxFh9YzbhFp5oQrOYjuFhjo4LObugdgfVpC1H3fK8H(LZco(oYBcfv7iaLXGrX7dxD4DbjFSL9AtyV(o6LZco(EYDuJqLtO(okalfh8s0dNlN0rqDj89d(4LW1VCwWXTuPslzXGG0CbrgX)xorJTyPsLwo8d4cbnSubtTeolHFU5SegwoplzML8LdaDXjQx46wOtRoGQgkfTuTewlvQ0swmii9W5YjDeuxcF)GpEjCn2ILkvAjF5aqxCI6fUUf60QdOQHsrlvlvGLkEh5nHIQD0DIeYyW84Fl71uK967Oxol447j3rncvoH67i4Smalfh8s0dNlN0rqDj89d(4LW1VCwWXTuPslzXGG0dNlN0rqDj89d(4LW1ylwQuPLSyqqAGZG35ye1RXrRklvQ0s(YbGU4e1lC9DIeYyW843sfm1Y5zjSwgZs4SKfdcsZfeze)F5en2ILkvA5WpGle0Wsfm1s4Se(5MZsyy58SKzwYxoa0fNOEHRBHoT6aQAOu0s1syTuPslzXGG0dNlN0rqDj89d(4LW1ylwQuPL8LdaDXjQx46wOtRoGQgkfTuTubwQylHDh5nHIQD0DIeYyW84Fl71yK3RVJE5SGJVNCh1iu5eQVJyXGG0CbrgX)xort(WPf3syAPITKzwQ2WTKzwYIbbP5cImI)VCIMlEl(oYBcfv7OwOtRoGQgkfTu3YET5ZE9D0lNfC89K7OgHkNq9DelgeKg4m4Dogr9ASflJzjF5aqxCI6fUUf60QdOQHsrlvlHPLZZYywcNLbyP4GxIMliYOFWhVehOF5SGJBPsLwYfez0p4JxId04OvLLWAzmlXrIgc4J35HOwCTqBXPL6oYBcfv7iGZG3zXiCzl71uO713rVCwWX3tUJAeQCc13r8LdaDXjQx46wOtRoGQgkfTuTeMwoplJzzawYIbbPDE7fUxTRXw2rEtOOAhrBhcJe4w2Rb)C713rVCwWX3tUJAeQCc13r8LdaDXjQx46wOtRoGQgkfTuTeMwoplJzjlgeKM2oegjqn2ILXSmalzXGG0oV9c3R21yl7iVjuuTJGiiU05HOw8TSxdE43RVJE5SGJVNCh1iu5eQVJeh8s0h8XlXbDwGZf9lNfCClJzjF5aqxCI6fUUf60QdOQHsrlvlHPLZZYywcNLbyP4GxIMliYOFWhVehOF5SGJBPsLwYfez0p4JxId04OvLLWUJ8Mqr1o6GpEjoOZcCUSL9AWZ8967Oxol447j3rncvoH67iXbVeTZBVW9QD9lNfC8DK3ekQ2raNbVZEFSL9AWR4967iVjuuTJAHoT6aQAOu0sDh9YzbhFp5w2Rb)82RVJE5SGJVNCh1iu5eQVJeh8s0oV9c3R21VCwWX3rEtOOAhbCg8olgHl7ObIbAPUJGFl71GFc713rVCwWX3tUJ8Mqr1occ4J35HOw8DulWg4DXjQx471GFh1iu5eQVJihICEOZc(oAGyGwQ7i43YEn4vK967ObIbAPUJGFh5nHIQDeebXLope1IVJE5SGJVNClBzhHFihdi713Rb)E9D0lNfC8n7oQrOYjuFh5m(ju5AVANleh0jNJkVAx)YzbhFh5nHIQDelaHWbyCzl71y(E9D0lNfC89K7OgHkNq9D0v4L3KJ3BObRlDWlvj0syyPqh3syAPINZsLkTeIsE)GpEjoqJTyPsLwYfez0p4JxId0yl7iVjuuTJwqcfvBzVMI3RVJ8Mqr1oAfTW78W7KD0lNfC89KBzV282RVJE5SGJVNCh1iu5eQVJeh8s0cs(OpCUCsG6xol44wgZswmiin5Cu5v7DbjFOjF40IBjmTK57iVjuuTJeK8rF4C5Ka3YETjSxFh5nHIQDeg)DQ8bFh9YzbhFp5w2RPi713rVCwWX3tUJAeQCc13rbyP4GxIMliYOFWhVehOF5SGJVJ8Mqr1ocIsE)GpEjoyl71yK3RVJE5SGJVNCh1iu5eQVJeh8s0Cbrg9d(4L4a9lNfCClJzjCwgGLIdEjAA7qyKa1VCwWXTuPsldWswmiinTDimsGASflJzzaw2qiaoAvPPTdHrcuJTyjSwgZs4Smalfh8s0oV9c3R21VCwWXTuPsldWYgcbWrRkTZBVW9QDn2ILWUJ8Mqr1oIliYOFWhVehSL9AZN967iVjuuTJAOQ9siUC8oeWhFh9YzbhFp5w2RPq3RVJ8Mqr1oIfGq4DeuxcF)1hbUJE5SGJVNCl71GFU967iVjuuTJuXCco1RocQ7m(jijCh9YzbhFp5w2Rbp8713rEtOOAhbHAy8J3Dg)eQ8o79Xo6LZco(EYTSxdEMVxFh5nHIQD0cgHcfiTu7SaNl7Oxol447j3YEn4v8E9DK3ekQ2rs47yflcRW7qis77Oxol447j3YEn4N3E9DK3ekQ2rJpqKa7iOoaRrX74K7d(o6LZco(EYTSxd(jSxFh5nHIQDeHUSaENwD(I3(o6LZco(EYTSxdEfzV(oYBcfv7OvicaNHtRo5Cu5v77Oxol447j3YEn4zK3RVJE5SGJVNCh1iu5eQVJcWsXbVeTZBVW9QD9lNfCClvQ0swmiiTZBVW9QDn2ILkvAzdHa4OvL25Tx4E1UM8HtlULkWYjm3oYBcfv7iwacH3HWibUL9AWpF2RVJE5SGJVNCh1iu5eQVJcWsXbVeTZBVW9QD9lNfCClvQ0swmiiTZBVW9QDn2YoYBcfv7i2t4NeNwQBzVg8k0967Oxol447j3rncvoH67OaSuCWlr782lCVAx)Yzbh3sLkTKfdcs782lCVAxJTyPsLw2qiaoAvPDE7fUxTRjF40IBPcSCcZTJ8Mqr1ocIsolaHW3YEnMp3E9D0lNfC89K7OgHkNq9Duawko4LODE7fUxTRF5SGJBPsLwYIbbPDE7fUxTRXwSuPslBieahTQ0oV9c3R21KpCAXTubwoH52rEtOOAh5v7CH4GEZbGTSxJ5WVxFh9YzbhFp5oQrOYjuFhXfez0p4JxId0ylwgZswmiiDZbGoGQgkfTu1KpCAXTubtTC(SJ8Mqr1o6b(ocQlHVZfezSL9AmN5713rEtOOAhnUCezh9YzbhFp5w2RXCfVxFh9YzbhFp5oQrOYjuFh5nHYW7V(GEULkWsMBzmldWsiSQoGwQ7iVjuuTJiyv3BcfvDaLl7iaLl9YhFh5OVL9AmFE713rVCwWX3tUJ8Mqr1oIGvDVjuu1buUSJauU0lF8DeNwQG3fNOEzlBzhTqEdnyDzV(En43RVJ8Mqr1osqYh9HZLtcCh9YzbhFp5w2RX8967Oxol447j3rncvoH67iXbVenxqKr8)Lt0VCwWXTmMLWzjXP49ZWlr744CDdHvILW0sfBPsLwsCkE)m8s0oooxtllvGLtyolHDh5nHIQDexqKr8)Lt2YEnfVxFh9YzbhFp5oQrOYjuFhfGLIdEjAUGiJ(bF8sCG(LZco(oYBcfv7iik59d(4L4GTSxBE713rVCwWX3tUJAeQCc13rIdEjAUGiJ(bF8sCG(LZco(oYBcfv7iUGiJ(bF8sCWw2RnH967iVjuuTJwqcfv7Oxol447j3YEnfzV(o6LZco(EYDuJqLtO(osCWlrFWhVeh0zbox0VCwWX3rEtOOAhDWhVeh0zbox2YEng5967Oxol447j3rncvoH67OaSuCWlrFWhVeh0zbox0VCwWXTmML8LdaDXjQx46wOtRoGQgkfTuTeMwQ4DK3ekQ2raNbVZIr4Yw2RnF2RVJE5SGJVNCh1iu5eQVJ4lha6ItuVW1TqNwDavnukAPAPcSK57iVjuuTJAHoT6aQAOu0sDlBzl7ihtcrKDueDGbCHIkfcXHKTSL9g]] )


    spec:RegisterOptions( {
        enabled = true,

        aoe = 3,

        nameplates = false,
        nameplateRange = 8,

        damage = true,
        damageDots = true,
        damageExpiration = 8,

        potion = "potion_of_unbridled_fury",

        package = "Elemental",
    } )

    --[[ spec:RegisterSetting( "micromanage_pets", true, {
        name = "Micromanage Primal Elemental Pets",
        desc = "If checked, Meteor, Eye of the Storm, etc. will appear in your recommendations.",
        type = "toggle",
        width = 1.5
    } ) ]]

end
