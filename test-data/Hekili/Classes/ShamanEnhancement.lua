-- ShamanEnhancement.lua
-- May 2018

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


-- Generate the Enhancement spec database only if you're actually a Shaman.
if select( 2, UnitClass( 'player' ) ) == 'SHAMAN' then
    local spec = Hekili:NewSpecialization( 263 )

    spec:RegisterResource( Enum.PowerType.Mana )   
    spec:RegisterResource( Enum.PowerType.Maelstrom, {
        mainhand = {
            last = function ()
                local swing = state.swings.mainhand
                local speed = state.swings.mainhand_speed
                local t = state.query_time

                if speed == 0 then return swing end

                return swing + ( floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed )
            end,

            stop = function () return state.time == 0 or state.swings.mainhand == 0 end,
            interval = 'mainhand_speed',
            value = 5
        },

        offhand = {
            last = function ()
                local swing = state.swings.offhand
                local speed = state.swings.offhand_speed
                local t = state.query_time

                if speed == 0 then return swing end

                return swing + ( floor( ( t - swing ) / state.swings.offhand_speed ) * state.swings.offhand_speed )
            end,

            stop = function () return state.time == 0 or state.swings.offhand == 0 end,
            interval = 'offhand_speed',
            value = 5
        },

        fury_of_air = {
            aura = 'fury_of_air',

            last = function ()
                local app = state.buff.fury_of_air.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            stop = function( x )
                return x < 3
            end,

            interval = 1,
            value = -3,
        },

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


    -- TALENTS
    spec:RegisterTalents( {
        boulderfist = 22354,
        hot_hand = 22355,
        lightning_shield = 22353,

        landslide = 22636,
        forceful_winds = 22150,
        totem_mastery = 23109,

        spirit_wolf = 23165,
        earth_shield = 19260,
        static_charge = 23166,

        searing_assault = 23089,
        hailstorm = 23090,
        overcharge = 22171,

        natures_guardian = 22144,
        feral_lunge = 22149,
        wind_rush_totem = 21966,

        crashing_storm = 21973,
        fury_of_air = 22352,
        sundering = 22351,

        elemental_spirits = 21970,
        earthen_spike = 22977,
        ascendance = 21972
    } )


    -- PvP Talents
    spec:RegisterPvpTalents( { 
        relentless = 3553, -- 196029
        adaptation = 3552, -- 214027
        gladiators_medallion = 3551, -- 208683

        forked_lightning = 719, -- 204349
        static_cling = 720, -- 211062
        thundercharge = 725, -- 204366
        shamanism = 722, -- 193876
        spectral_recovery = 3519, -- 204261
        ride_the_lightning = 721, -- 204357
        grounding_totem = 3622, -- 204336
        swelling_waves = 3623, -- 204264
        ethereal_form = 1944, -- 210918
        skyfury_totem = 3487, -- 204330
        counterstrike_totem = 3489, -- 204331
        purifying_waters = 3492, -- 204247
    } )


    spec:RegisterAuras( {
        ascendance = {
            id = 114051,
            duration = 15,
        },

        astral_shift = { 
            id = 108271,
            duration = 8,
        },

        boulderfist = {
            id = 218825,
            duration = 10,
        },

        chill_of_the_twisting_nether = {
            id = 207998,
            duration = 8,
        },

        crackling_surge = {
            id = 224127,
            duration = 15,
        },

        crash_lightning = {
            id = 187878,
            duration = 10,
        },

        crashing_lightning = {
            id = 242286,
            duration = 16,
            max_stack = 15,
        },

        earthen_spike = {
            id = 188089,
            duration = 10,
        },

        ember_totem = {
            id = 262399,
            duration = 120,
            max_stack =1 ,
        },

        feral_spirit = {            
            name = "Feral Spirit",
            duration = 15,
            generate = function ()
                local cast = rawget( class.abilities.feral_spirit, "lastCast" ) or 0
                local up = cast + 15 > query_time

                local fs = buff.feral_spirit
                fs.name = "Feral Spirit"

                if up then
                    fs.count = 1
                    fs.expires = cast + 15
                    fs.applied = cast
                    fs.caster = "player"
                    return
                end
                fs.count = 0
                fs.expires = 0
                fs.applied = 0
                fs.caster = "nobody"
            end,
        },

        fire_of_the_twisting_nether = {
            id = 207995,
            duration = 8,
        },

        flametongue = {
            id = 194084,
            duration = 16,
        },

        frostbrand = {
            id = 196834,
            duration = 16,
        },

        fury_of_air = {
            id = 197211,
            duration = 3600,
        },

        gathering_storms = {
            id = 198300,
            duration = 12,
            max_stack = 1,
        },

        hot_hand = {
            id = 215785,
            duration = 15,
        },

        icy_edge = {
            id = 224126,
            duration = 15,
            max_stack = 1,
        },

        landslide = {
            id = 202004,
            duration = 10,
        },

        lashing_flames = {
            id = 240842,
            duration = 10,
            max_stack = 99,
        },

        lightning_crash = {
            id = 242284,
            duration = 16
        },

        lightning_shield = {
            id = 192106,
            duration = 3600,
            max_stack = 20,
        },

        lightning_shield_overcharge = {
            id = 273323,
            duration = 10,
            max_stack = 1,
        },

        molten_weapon = {
            id = 271924,
            duration = 4,
        },

        resonance_totem = {
            id = 262417,
            duration = 120,
            max_stack =1 ,
        },

        shock_of_the_twisting_nether = {
            id = 207999,
            duration = 8,
        },

        storm_totem = {
            id = 262397,
            duration = 120,
            max_stack =1 ,
        },

        stormbringer = {
            id = 201846,
            duration = 12,
            max_stack = 1,
        },

        tailwind_totem = {
            id = 262400,
            duration = 120,
            max_stack =1 ,
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

                if up then
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

                removeBuff( "resonance_totem" )
                removeBuff( "tailwind_totem" )
                removeBuff( "storm_totem" )
                removeBuff( "ember_totem" )
            end,
        },


        -- Azerite Powers
        ancestral_resonance = {
            id = 277943,
            duration = 15,
            max_stack = 1,
        },

        lightning_conduit = {
            id = 275391,
            duration = 60,
            max_stack = 1
        },

        primal_primer = {
            id = 273006,
            duration = 30,
            max_stack = 10,
        },

        roiling_storm = {
            id = 278719,
            duration = 3600,
            max_stack = 1,
        },

        strength_of_earth = {
            id = 273465,
            duration = 10,
            max_stack = 1,
        },

        thunderaans_fury = {
            id = 287802,
            duration = 6,
            max_stack = 1,
        },

        -- PvP Talents
        earth_shield = {
            id = 204288,
            duration = 600,
            max_stack = 4,
        },

        thundercharge = {
            id = 204366,
            duration = 10,
            max_stack = 1,
        },
    } )


    spec:RegisterStateTable( 'feral_spirit', setmetatable( { onReset = function( self ) self.cast_time = nil end }, {
        __index = function( t, k )
            if k == 'cast_time' then
                t.cast_time = class.abilities.feral_spirit.lastCast or 0
                return t.cast_time
            elseif k == 'active' or k == 'up' then
                return query_time < t.cast_time + 15
            elseif k == 'remains' then
                return max( 0, t.cast_time + 15 - query_time )
            end

            return false
        end 
    } ) )

    spec:RegisterStateTable( 'twisting_nether', setmetatable( { onReset = function( self ) end }, { 
        __index = function( t, k )
            if k == 'count' then
                return ( buff.fire_of_the_twisting_nether.up and 1 or 0 ) + ( buff.chill_of_the_twisting_nether.up and 1 or 0 ) + ( buff.shock_of_the_twisting_nether.up and 1 or 0 )
            end

            return 0
        end 
    } ) )


    spec:RegisterHook( "reset_precast", function ()
        class.auras.totem_mastery.generate()
    end )


    spec:RegisterGear( 'waycrest_legacy', 158362, 159631 )
    spec:RegisterGear( 'electric_mail', 161031, 161034, 161032, 161033, 161035 )

    spec:RegisterGear( 'tier21', 152169, 152171, 152167, 152166, 152168, 152170 )
        spec:RegisterAura( 'force_of_the_mountain', {
            id = 254308,
            duration = 10
        } )
        spec:RegisterAura( 'exposed_elements', {
            id = 252151,
            duration = 4.5
        } )

    spec:RegisterGear( 'tier20', 147175, 147176, 147177, 147178, 147179, 147180 )
        spec:RegisterAura( "lightning_crash", {
            id = 242284,
            duration = 16
        } )
        spec:RegisterAura( "crashing_lightning", {
            id = 242286,
            duration = 16,
            max_stack = 15
        } )

    spec:RegisterGear( 'tier19', 138341, 138343, 138345, 138346, 138348, 138372 )
    spec:RegisterGear( 'class', 139698, 139699, 139700, 139701, 139702, 139703, 139704, 139705 )



    spec:RegisterGear( 'akainus_absolute_justice', 137084 )
    spec:RegisterGear( 'emalons_charged_core', 137616 )
    spec:RegisterGear( 'eye_of_the_twisting_nether', 137050 )
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

    spec:RegisterGear( 'smoldering_heart', 151819 )
    spec:RegisterGear( 'soul_of_the_farseer', 151647 )
    spec:RegisterGear( 'spiritual_journey', 138117 )
    spec:RegisterGear( 'storm_tempests', 137103 )
    spec:RegisterGear( 'uncertain_reminder', 143732 )

    spec:RegisterAbilities( {
        ascendance = {
            id = 114051,
            cast = 0,
            cooldown = 180,
            gcd = 'off',

            readyTime = function() return buff.ascendance.remains end,
            recheck = function () return buff.ascendance.remains end,

            nobuff = 'ascendance',
            talent = 'ascendance',
            toggle = 'cooldowns',

            startsCombat = false,

            handler = function ()
                applyBuff( 'ascendance', 15 )
                setCooldown( 'stormstrike', 0 )
                setCooldown( 'windstrike', 0 )
            end,
        },

        astral_shift = {
            id = 108271,
            cast = 0,
            cooldown = 90,
            gcd = 'off',

            startsCombat = false,

            handler = function ()
                applyBuff( 'astral_shift', 8 )
            end,
        },

        bloodlust = {
            id = function () return pvptalent.shamanism.enabled and 204361 or 2825 end,
            known = 2825,
            cast = 0,
            cooldown = 300,
            gcd = 'spell', -- Ugh.

            spend = 0.215,
            spendType = 'mana',

            startsCombat = false,

            handler = function ()
                applyBuff( 'bloodlust', 40 )
            end,

            copy = { 204361, 2825 }
        },

        crash_lightning = {
            id = 187874,
            cast = 0,
            cooldown = function () return 6 * haste end,
            gcd = 'spell',

            spend = 20,
            spendType = 'maelstrom',

            recheck = function () return buff.crash_lightning.remains end,

            startsCombat = true,

            handler = function ()
                if active_enemies >= 2 then
                    applyBuff( 'crash_lightning', 10 )
                    applyBuff( "gathering_storms" )
                end

                removeBuff( 'crashing_lightning' )

                if level < 116 then 
                    if equipped.emalons_charged_core and spell_targets.crash_lightning >= 3 then
                        applyBuff( 'emalons_charged_core', 10 )
                    end

                    if set_bonus.tier20_2pc > 1 then
                        applyBuff( 'lightning_crash' )
                    end

                    if equipped.eye_of_the_twisting_nether then
                        applyBuff( 'shock_of_the_twisting_nether', 8 )
                    end

                    if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end
                    if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end
                    if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_nature" ) end
                end
            end,
        },

        earth_elemental = {
            id = 198103,
            cast = 0,
            cooldown = 300,
            gcd = "spell",

            startsCombat = false,
            texture = 136024,

            toggle = "defensives",            

            handler = function ()
                summonPet( "greater_earth_elemental", 60 )
            end,
        },

        earth_shield = {
            id = 204288,
            cast = 0,
            cooldown = 6,
            gcd = "spell",

            startsCombat = false,
            -- texture = ,

            pvptalent = "earth_shield",

            handler = function ()
                applyBuff( "earth_shield" )
            end,
        },

        earthen_spike = {
            id = 188089,
            cast = 0,
            cooldown = function () return 20 * haste end,
            gcd = 'spell',

            spend = 20,
            spendType = 'maelstrom',

            startsCombat = true,

            handler = function ()
                applyDebuff( 'target', 'earthen_spike' )

                if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end
                if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end
                if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_nature" ) end
        end,
        },

        feral_spirit = {
            id = 51533,
            cast = 0,
            cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * ( 120 - ( talent.elemental_spirits.enabled and 30 or 0 ) ) end,
            gcd = "spell",

            startsCombat = false,
            toggle = "cooldowns",

            handler = function () feral_spirit.cast_time = query_time; applyBuff( "feral_spirit" ) end
        },

        flametongue = {
            id = 193796,
            cast = 0,
            cooldown = function () return 12 * haste end,
            gcd = 'spell',

            startsCombat = true,

            handler = function ()
                applyBuff( 'flametongue', 16 + min( 4.8, buff.flametongue.remains ) )

                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'fire_of_the_twisting_nether', 8 )
                end

                if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end

                removeBuff( "strength_of_earth" )
            end,
        },


        frostbrand = {
            id = 196834,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = 20,
            spendType = 'maelstrom',

            startsCombat = true,

            handler = function ()
                applyBuff( 'frostbrand', 16 + min( 4.8, buff.frostbrand.remains ) )

                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'chill_of_the_twisting_nether', 8 )
                end

                if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end

                removeBuff( "strength_of_earth" )
            end,
        },


        fury_of_air = {
            id = 197211,
            cast = 0,
            cooldown = 0,
            gcd = function( x )
                if buff.fury_of_air.up then return 'off' end
                return "spell"
            end,

            spend = 3,
            spendType = "maelstrom",

            talent = 'fury_of_air',

            startsCombat = false,

            handler = function ()
                if buff.fury_of_air.up then removeBuff( 'fury_of_air' )
                else applyBuff( 'fury_of_air', 3600 ) end

                if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_nature" ) end
        end,
        },


        healing_surge = {
            id = 188070,
            cast = function() return maelstrom.current >= 20 and 0 or ( 2 * haste ) end,
            cooldown = 0,
            gcd = "spell",

            spend = function () return maelstrom.current >= 20 and 20 or 0 end,
            spendType = "maelstrom",

            startsCombat = false,
        },


        heroism = {
            id = function () return pvptalent.shamanism.enabled and 204362 or 32182 end,
            cast = 0,
            cooldown = 300,
            gcd = "spell", -- Ugh.

            spend = 0.215,
            spendType = 'mana',

            startsCombat = false,
            toggle = 'cooldowns',

            handler = function ()
                applyBuff( 'heroism' )
                applyDebuff( 'player', 'exhaustion', 600 )
            end,

            copy = { 204362, 32182 }
        },


        lava_lash = {
            id = 60103,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            spend = function() return buff.hot_hand.up and 0 or 40 end,
            spendType = "maelstrom",

            startsCombat = true,

            handler = function ()
                removeBuff( 'hot_hand' )
                removeDebuff( "target", "primal_primer" )

                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'fire_of_the_twisting_nether' )
                    if buff.crash_lightning.up then applyBuff( 'shock_of_the_twisting_nether' ) end
                end

                if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end
                if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_fire" ) end
                if azerite.natural_harmony.enabled and buff.crash_lightning.up then applyBuff( "natural_harmony_nature" ) end
            end,
        },


        lightning_bolt = {
            id = 187837,
            cast = 0,
            cooldown = function() return talent.overcharge.enabled and ( 12 * haste ) or 0 end,
            gcd = "spell",

            spend = function() return talent.overcharge.enabled and min( maelstrom.current, 40 ) or 0 end,
            spendType = 'maelstrom',

            startsCombat = true,

            handler = function ()
                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'shock_of_the_twisting_nether' )
                end

                if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_nature" ) end
        end,
        },


        lightning_shield = {
            id = 192106,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            talent = 'lightning_shield',
            essential = true,

            readyTime = function () return buff.lightning_shield.remains - 120 end,
            usable = function () return buff.lightning_shield.remains < 120 and ( time == 0 or buff.lightning_shield.stack == 1 ) end,
            handler = function () applyBuff( 'lightning_shield', nil, 1 ) end,
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

            toggle = "interrupts",
            interrupt = true,

            usable = function () return buff.dispellable_magic.up, "requires dispellable magic aura" end,
            handler = function ()
                removeBuff( "dispellable_magic" )
            end,
        },


        rockbiter = {
            id = 193786,
            cast = 0,
            cooldown = function() local x = 6 * haste; return talent.boulderfist.enabled and ( x * 0.85 ) or x end,
            recharge = function() local x = 6 * haste; return talent.boulderfist.enabled and ( x * 0.85 ) or x end,
            charges = 2,
            gcd = "spell",

            spend = -25,
            spendType = "maelstrom",

            startsCombat = true,

            recheck = function () return ( 1.7 - charges_fractional ) * recharge end,

            handler = function ()
                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'shock_of_the_twisting_nether' )
                end
                removeBuff( 'force_of_the_mountain' )
                if set_bonus.tier21_4pc > 0 then applyDebuff( 'target', 'exposed_elements', 4.5 ) end

                if azerite.natural_harmony.enabled then applyBuff( "natural_harmony_nature" ) end

                if azerite.strength_of_earth.enabled then applyBuff( "strength_of_earth" ) end
            end,
        },


        stormstrike = {
            id = 17364,
            cast = 0,
            cooldown = function()
                if buff.stormbringer.up then return 0 end
                if buff.ascendance.up then return 3 * haste end
                return 9 * haste
            end,
            gcd = "spell",

            spend = function()
                if buff.stormbringer.up then return 0 end
                return max( 0,  buff.ascendance.up and 10 or 30 )
            end,

            spendType = 'maelstrom',

            startsCombat = true,
            texture = 132314,

            cycle = function () return azerite.lightning_conduit.enabled and "lightning_conduit" or nil end,

            usable = function() return buff.ascendance.down end,
            handler = function ()
                if buff.lightning_shield.up then
                    addStack( "lightning_shield", 3600, 2 )
                    if buff.lightning_shield.stack >= 20 then
                        applyBuff( "lightning_shield" )
                        applyBuff( "lightning_shield_overcharge" )
                    end
                end

                setCooldown( 'windstrike', action.stormstrike.cooldown )
                setCooldown( 'strike', action.stormstrike.cooldown )

                if buff.stormbringer.up then
                    removeBuff( 'stormbringer' )
                end

                removeBuff( "gathering_storms" )

                if azerite.lightning_conduit.enabled then
                    applyDebuff( "target", "lightning_conduit" )
                end

                removeBuff( "strength_of_earth" )

                if level < 116 then
                    if equipped.storm_tempests then
                        applyDebuff( 'target', 'storm_tempests', 15 )
                    end

                    if set_bonus.tier20_4pc > 0 then
                        addStack( 'crashing_lightning', 16, 1 )
                    end

                    if equipped.eye_of_the_twisting_nether and buff.crash_lightning.up then
                        applyBuff( 'shock_of_the_twisting_nether', 8 )
                    end
                end

                if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end
                if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end
                if azerite.natural_harmony.enabled and buff.crash_lightning.up then applyBuff( "natural_harmony_nature" ) end
            end,                    

            copy = "strike", -- copies this ability to this key or keys (if a table value)
        },


        sundering = {
            id = 197214,
            cast = 0,
            cooldown = 40,
            gcd = "spell",

            spend = 20,
            spendType = "maelstrom",

            startsCombat = true,
            talent = 'sundering',

            handler = function ()
                if level < 116 and equipped.eye_of_the_twisting_nether then
                    applyBuff( 'fire_of_the_twisting_nether' )
                end

                if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end
            end,
        },


        thundercharge = {
            id = 204366,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            startsCombat = true,
            texture = 1385916,

            pvptalent = function () return not essence.conflict_and_strife.major and "thundercharge" or nil end,
            
            handler = function ()
                applyBuff( "thundercharge" )
            end,
        },


        totem_mastery = {
            id = 262395,
            cast = 0,
            cooldown = 0,
            gcd = "spell",

            startsCombat = false,
            talent = "totem_mastery",
            essential = true,

            readyTime = function () return buff.totem_mastery.remains - 15 end,

            handler = function ()
                applyBuff( 'resonance_totem', 120 )
                applyBuff( 'storm_totem', 120 )
                applyBuff( 'ember_totem', 120 )
                if buff.tailwind_totem.down then stat.spell_haste = stat.spell_haste + 0.02 end
                applyBuff( 'tailwind_totem', 120 )
                applyBuff( 'totem_mastery', 120 )
            end,
        },


        wind_shear = {
            id = 57994,
            cast = 0,
            cooldown = 12,
            gcd = "off",

            startsCombat = true,
            toggle = "interrupts",

            usable = function () return debuff.casting.up end,

            debuff = "casting",
            readyTime = state.timeToInterrupt,

            handler = function () interrupt() end,
        },

        windstrike = {
            id = 115356,
            cast = 0,
            cooldown = function() return buff.stormbringer.up and 0 or ( 3 * haste ) end,
            gcd = "spell",

            spend = function() return buff.stormbringer.up and 0 or 10 end,
            spendType = "maelstrom",

            texture = 1029585,

            known = 17364,
            usable = function () return buff.ascendance.up end,
            handler = function ()
                setCooldown( 'stormstrike', action.stormstrike.cooldown )
                setCooldown( 'strike', action.stormstrike.cooldown )

                if buff.stormbringer.up then
                    removeBuff( 'stormbringer' )
                end

                removeBuff( "gathering_storms" )

                removeBuff( "strength_of_earth" )

                if level < 116 then
                    if equipped.storm_tempests then
                        applyDebuff( 'target', 'storm_tempests', 15 )
                    end

                    if set_bonus.tier20_4pc > 0 then
                        addStack( 'crashing_lightning', 16, 1 )
                    end

                    if equipped.eye_of_the_twisting_nether and buff.crash_lightning.up then
                        applyBuff( 'shock_of_the_twisting_nether', 8 )
                    end
                end

                if azerite.natural_harmony.enabled and buff.frostbrand.up then applyBuff( "natural_harmony_frost" ) end
                if azerite.natural_harmony.enabled and buff.flametongue.up then applyBuff( "natural_harmony_fire" ) end
                if azerite.natural_harmony.enabled and buff.crash_lightning.up then applyBuff( "natural_harmony_nature" ) end
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

        potion = "superior_battle_potion_of_agility",

        package = "Enhancement",
    } )


    spec:RegisterPack( "Enhancement", 20200124, [[dKePDbqiQk5rKuXMOk9jsQknkskNIK0Qqa9kvPMfI4wuvk2fv(fQsdJQIJPkAziqpdvrMMQqDnsQY2ufY3OQunoufvNdvrzDiayEQc6Ekv7tvYbPQuAHikpebnrea5IiaTrsQQgjcaPtssvbRuf1mPQQBIaqTtsIFssLgQQalfbG4PImvePVssvH2lWFf1GP4WelwLEmPMSQ6YqBwjFgHgTs50cRgbq9AvKzd62Ky3k(nkdhv1YL65uA6sUoQSDv47OkmEsQk68ufRNQkZhr1(rAWtaPG0xkeOcb9HG(4Ztc(yNp8m1Z35jEoivE4JGeFrFsiIG0ikiiraNnz0OcofiXx8azYhqkizzCTgbPTQ4BjaWlVeJAJ760mfETHchuQGn6wwfV2qrZliD5cyP(WaUG0xkeOcb9HG(4Ztc(yNp8m1Z35j1dKeUAJ1Guku4GsfSHWwwfiTf)poGli9rRgKuhQHaoBYOrfCkQjTjkYqpRouZwv8Tea4LxIrTXDDAMcV2qHdkvWgDlRIxBOO5LEwDOMZYWjThQHGpjHAiOpe0h6z6z1HAiCtgIOLaa9S6qn(gQX3()4NA43OMPCLIAiLvOc1qaSylS94ONvhQX3qneGyJ6BrnCwKAiGsxBudbeIk4ucKAuZkhi1ef1Syn1WvbmkpQ6ajyyllGuqIXhhSbKcu5jGuqch5cXpGmqs3rHDiGKIGqB1mfQ5HuZt1JA8snvOGuZdPgI6pij6kydi1m9PBuydkqbsksmfoYOraPavEcifKWrUq8didK0Duyhci5lQ5YTwUfuuWIne5qhhFqs0vWgqAbffSydroeuaviiGuqch5cXpGmqs3rHDiGujqCk3MeqBXAfhoYfIFQXl14lQ5YTwUvZS1TL5744tnEPMdPd5cr3IR9q4gQpLv)KbsIUc2asRMzRBlZhuGcKwbeInGuGkpbKcs4ixi(bKbs6okSdbKAj(z8aNYj)V1fd18IAESpGKORGnGKLB(yhdrqbuHGasbjCKle)aYajDhf2HasTe)mEGt5K)36IHAErn8mFOgVuJVOMl3A5eRgNVmA0XXNA8sn(IAUCRLtHblCY8af(SXXXNA8sn(IAUCRLl0EY4Ni644tnEPgFrnxU1YPBrFcgdXSLRjIoo(uJxQXxuZhVCRLdLU2WjB5hNqhhFqs0vWgqAX0Cw8Nf)WokmFrrbuav4jaPGeoYfIFazGKUJc7qaPwIFgpWPCY)BDXqnVOMh5dij6kydiXNRJLNyiMVqXwGcOYJbKcs4ixi(bKbs6okSdbKAj(z8aNYj)V1fd18IAEKpGKORGnGuh85dXCmzlFrJGcOI6bifKeDfSbKQnU5JTEtAIiiHJCH4hqgOaQ8iaPGKORGnGKMnACQwk8NxqrbbjCKle)aYafqfFhqkij6kydi1OWpgI5fuuqliHJCH4hqgOaQWZbKcsIUc2asxHyMTYvh6twqch5cXpGmqbuHNbifKWrUq8didK0DuyhcivceNYTyTgxCWmpI5BD4ixi(PgVuJOR4aZ4GkbAPMxuZtQXl1CiDixi6wCThc3q9PmH(dsIUc2as6wSBzyqCRMyickGkp9bqkiHJCH4hqgiP7OWoeqQeioLZIshdXSyTchSC4ixi(bjrxbBaPfuuWIne5qqbu55taPGeoYfIFazGKUJc7qajFrnIFyhf643HIaZ87qbBhoYfIFQXl1uceNYTXQ8MmFhoYfIFQXl1C5wl3gRYBY8Dnk6cKeDfSbKGYHKHIDduavEsqaPGeoYfIFazGKUJc7qajrxXbMXbvc0snVOMNuJxQ5q6qUq0T4ApeUH6tzc9hKeDfSbK0Ty3YWG4wnXqeuavEYtasbjCKle)aYajDhf2HaskccTvZuOMhsn(UpuJxQXxuZLBTC2QXHyTLzRmkDT544dsIUc2asntF6gf2GcOYZhdifKWrUq8didK0DuyhciPg1uceNYPBXUfdXSTyTIdh5cXp1qo5utjqCk3I1ACXbZ8iMV1HJCH4NAuLA8snhshYfIo1LWhWyWmH(dsIUc2as6wSBzyqCRMyickGkpvpaPGeoYfIFazGKUJc7qaPdPd5crN6s4dymy2F)PgVuZH0HCHOBX1EiCd1NY(7pij6kydibLdjdf7gOaQ88rasbjrxbBajfuH1EYSvgYPJF(3OOybjCKle)aYafqLN(oGuqs0vWgqQz6t3OWgKWrUq8diduavEYZbKcs4ixi(bKbs6okSdbKkbIt52KaAlwR4WrUq8tnEPMl3A5wnZw3wMVRrfjgl18qQ5XoEo18MAiQ)uJxQ5q6qUq0T4ApeUH6tz1pzGKORGnG0Qz262Y8bfqLN8maPGKORGnG0ckkyXgICiiHJCH4hqgOafiTAe9d7lxpznRraPavEcifKWrUq8didKeDfSbKGYHKHIDdK0Duyhcij(HDuOJFhkcmZVdfSDTmNOMx7udbPgVuZhVCRLJFhkcmZVdfSD2s0NOMDQ5PpuJxQ5q6qUq0T4ApeUH6tz)9NA8snhshYfIoc9)bmgm7V)GK2JgI5sAIyzbQ8euaviiGuqch5cXpGmqs3rHDiG0H0HCHOBX1EiCd1NYeWeij6kydiHsxB4KT8JtiOaQWtasbjCKle)aYajrxbBajBXAfB1XjeK0Duyhcij6koWmoOsGwQ5f18KA8snIFyhf6GbXTAIHywZMpxuoCKle)uJxQXxuZhVCRLdge3QjgIznB(Cr544tnEPMdPd5cr3IR9q4gQpLtjqs7rdXCjnrSSavEckGkpgqkiHJCH4hqgiP7OWoeq6YTwoBXALBhdrSDC8PgYjNAuJAeDfhyghujql18IAEsnEPMl3A5ik1g2XqmBlwRyDC8PgVuZH0HCHOBX1EiCd1NYPe1Okij6kydizlwRyRooHGcOI6bifKWrUq8didK0Duyhcij6koWmoOsGwQ51o1WtuJxQ5q6qUq0T4ApeUH6tzc9hKeDfSbK0Ty3YWG4wnXqeuavEeGuqch5cXpGmqs3rHDiGujqCkh7aB9M0erhoYfIFQXl1i6koWmoOsGwQzNAEsnEPMdPd5cr3IR9q4gQpL9NmQXl1Oii0wntHAETtnp2hqs0vWgqcge3QjgI5ldwGcOIVdifKWrUq8didK0Duyhcij(HDuOJFhkcmZVdfSDTmNOMx7udbPgVuZhVCRLJFhkcmZVdfSD2s0NOMxuJVtnEPMdPd5cr3IR9q4gQpL93FQXl1CiDixi6i0)hWyWS)(dsIUc2asq5qYqXUbkGk8CaPGeoYfIFazGKUJc7qaPdPd5crN6s4dymyoLOgVuZH0HCHOBX1EiCd1NYPe14LAoKoKleDe6)dymyoLajrxbBajBXAfB1Xjeuav4zasbjCKle)aYajDhf2HasF8YTwo(DOiWm)ouW2zlrFIA2PMN(qnEPMdPd5cr3IR9q4gQpL93Fqs0vWgqckhsgk2nqbkq6JlHdwasbQ8eqkij6kydiXJy(z7gkniHJCH4hqgOaQqqaPGeoYfIFazGeJpizXcKeDfSbKoKoKlebPdbYHGKAutjqCkNy148LrJoCKle)uJxQrnQ5YTwoXQX5lJgDC8PgYjNA0mg8Z4X4eRgNVmA01OIeJLAErnQNpuJQuJQud5KtnQrn(IAkbIt5eRgNVmA0HJCH4NA8snQrnlSfy2Yp6OCnQiXyPMxuJ6rnKto1Ozm4NXJXTWwGzl)OJY1OIeJLAErnQNpuJQuJQG0H05ruqqsZyWpJht26z0GcOcpbifKWrUq8didKy8bjlwGKORGnG0H0HCHiiDiqoeKueeARMPqnV2Pg1OMsG4uUfx7jZwzjAhoYfIFQHaPg1OMhrnVPgrxbBC2I1k2QJtOtZSf1Ok1OkiDiDEefeKwCThc3q9PCkbkGkpgqkiHJCH4hqgiX4dswSajrxbBaPdPd5crq6qGCiiPii0wntHAETtnQrnLaXPClU2tMTYs0oCKle)udbsnQrnpIAEtnIUc24GYHKHIDZPz2IAuLAufKoKopIccslU2dHBO(u2F)bfqf1dqkiHJCH4hqgiX4dswSajrxbBaPdPd5crq6qGCiiPii0wntHAETtnQrnLaXPClU2tMTYs0oCKle)udbsnQrnpIAEtnIUc240Ty3YWG4wnXq0Pz2IAuLAufKoKopIccslU2dHBO(uMq)bfqLhbifKWrUq8didKy8bjlwGKORGnG0H0HCHiiDiqoeKueeARMPqnV2Pg1OMsG4uUfx7jZwzjAhoYfIFQHaPg1OMhrnVPgrxbBCRMzRBlZ3Pz2IAuLAufKoKopIccslU2dHBO(uw9tgOaQ47asbjCKle)aYajgFqYIfij6kydiDiDixicshcKdbjfbH2QzkuZRDQrnQPeioLBX1EYSvwI2HJCH4NAiqQrnQ5ruZBQr0vWghkDTHt2YpoHonZwuJQuJQG0H05ruqqAX1EiCd1NYeWeOaQWZbKcs4ixi(bKbsm(GKflqs0vWgq6q6qUqeKoeihcskccTvZuOMx7uJAutjqCk3IR9KzRSeTdh5cXp1qGuJAuZJOM3uZJ9HAuLAufKoKopIccslU2dHBO(u2FYafqfEgGuqch5cXpGmqIXhKSybsIUc2ashshYfIG0Ha5qqsnQr0vCGzCqLaTuZlQ5j1qo5uJAuJMXGFgpghmiUvtmeZxgSCnQiXyPMx7udbPgcKAiQ)uJQuJQG0H05ruqqsDj8bmgeuavE6dGuqch5cXpGmqIXhKSybsIUc2ashshYfIG0Ha5qqsnQ5q6qUq0PUe(agdsnKto1Oii0wntHAETtnQrnLaXPCSdS1BsteD4ixi(PgcKAuJAESpuZBQr0vWgNTyTIT64e60mBrnQsnQsnQcshsNhrbbj1LWhWyWCkbkGkpFcifKWrUq8didKy8bjlwGKORGnG0H0HCHiiDiqoeKuJAoKoKleDQlHpGXGud5KtnkccTvZuOMx7uJAutjqCkh7aB9M0erhoYfIFQHaPg1OMh7d18MAeDfSXbLdjdf7MtZSf1Ok1Ok1OkiDiDEefeKuxcFaJbZ(7pOaQ8KGasbjCKle)aYajgFqYIfij6kydiDiDixicshcKdbj1OMdPd5crN6s4dymi1qo5uJIGqB1mfQ51o1Og1uceNYXoWwVjnr0HJCH4NAiqQrnQ5X(qnVPgrxbBC6wSBzyqCRMyi60mBrnQsnQsnQcshsNhrbbj1LWhWyWmH(dkGkp5jaPGeoYfIFazGeJpizXcKeDfSbKoKoKlebPdbYHGKAuZH0HCHOtDj8bmgKAiNCQrrqOTAMc18ANAuJAkbIt5yhyR3KMi6WrUq8tnei1Og18yFOM3uJORGnUvZS1TL570mBrnQsnQsnQcshsNhrbbj1LWhWyWS6Nmqbu55JbKcs4ixi(bKbsm(GKflqs0vWgq6q6qUqeKoeihcsIUIdmJdQeOLA2PMNud5KtnkccTvZuOMx7uJAuJORGnoDl2TmmiUvtmeDAMTOM3uJORGnoOCizOy3CAMTOgvbPdPZJOGGeH()agdM93Fqbu5P6bifKWrUq8didKy8bjlwGKORGnG0H0HCHiiDiqoeKeDfhyghujql1StnpPgYjNAueeARMPqnV2Pg1OgrxbBC6wSBzyqCRMyi60mBrnVPgrxbBC2I1k2QJtOtZSf1OkiDiDEefeKi0)hWyWCkbkGkpFeGuqch5cXpGmqIXhKSybsIUc2ashshYfIG0Ha5qqsnQPeioLBJv5nz(oCKle)uJxQPeioLBtcOTyTIdh5cXp14LAe)Wok0XVdfbM53Hc2oCKle)uJQG0H05ruqqA1i6h2xUEY4ixi(bfqLN(oGuqch5cXpGmqIXhKSybsIUc2ashshYfIG0Ha5qqsnQXxuZH0HCHOB1i6h2xUEY4ixi(PgVuJAutjqCk3LXb)yVcB5WrUq8tnEPMsG4uoOmFlm(Odh5cXp14LAe)Wok0zRghI1wMTYO01Mdh5cXp1Ok1OkiDiDEefeKAM(KfgFmJJCH4huavEYZbKcs4ixi(bKbsIUc2asAbcZIUc2KHHTajyyR8ikiiX4Jd2GcOYtEgGuqch5cXpGmqs3rHDiG0LBTCIvJZxgn644dsIUc2asAbcZIUc2KHHTajyyR8ikiijwnOaQqqFaKcs4ixi(bKbsIUc2asAbcZIUc2KHHTajyyR8ikiiXVdwhLhqbuHGpbKcs4ixi(bKbs6okSdbKeDfhyghujql18qQHNajrxbBajTaHzrxbBYWWwGemSvEefeKuKykCKrJGcOcbjiGuqch5cXpGmqs0vWgqslqyw0vWMmmSfibdBLhrbbj93ckGkeKNaKcs4ixi(bKbs6okSdbKoKoKleDRgr)W(Y1tgh5cXpij6kydiPfiml6kytgg2cKGHTYJOGG0Qr0pSVC9K1Sgbfqfc(yaPGeoYfIFazGKUJc7qajFrnhshYfIUvJOFyF56jJJCH4hKeDfSbK0ceMfDfSjddBbsWWw5ruqq6JlHdwznRrqbuHGQhGuqch5cXpGmqs3rHDiGKOR4aZ4GkbAPMx7udpbsIUc2asAbcZIUc2KHHTajyyR8ikiiPiXu4iJgbfqfc(iaPGeoYfIFazGKORGnGKwGWSORGnzyylqcg2kpIccsRacXguGcK43OMPCLcqkqLNasbjrxbBaPIvOswrSf2EajCKle)aYafqfccifKeDfSbKGbXTAIHy2Ufi8ds4ixi(bKbkGk8eGuqs0vWgqIpRc2as4ixi(bKbkqbs6VfqkqLNasbjCKle)GliP7OWoeqs8d7OqNmA0wTaZnAzJmA0HJCH4hKeDfSbKUqg7d5SfOaQqqaPGKORGnGepyn8FGXKB0Ygz0iiHJCH4hqgOaQWtasbjCKle)aYajDhf2HashshYfIonJb)mEmzRNrdsIUc2asxSTyFkgIGcOYJbKcs4ixi(bKbsJOGGK4NDtAXMxSPYSvMpJhydsIUc2asIF2nPfBEXMkZwz(mEGnOaQOEasbjCKle)aYajDhf2HashshYfIonJb)mEmzRNrdsIUc2asxiJ9ZlU2dOaQ8iaPGeoYfIFazGKUJc7qaPdPd5crNMXGFgpMS1ZObjrxbBaPv04fYyFqbuX3bKcs4ixi(bKbs6okSdbKoKoKleDAgd(z8yYwpJgKeDfSbKKrJ2QfywlqiOaQWZbKcs4ixi(bKbs6okSdbKUCRLtSAC(YOrhhFQHCYPgFrnLaXPCIvJZxgn6WrUq8tnEPMf2cmB5hDuUgvKySuZlQr9OgYjNAkPjILRcfmxS8pqQ5H7uZJ8bKeDfSbK4ZQGnGcOcpdqkij6kydirKt6FitMTYIFyZQnqch5cXpGmqbu5PpasbjrxbBaPf2cmB5hDuGeoYfIFazGcOYZNasbjCKle)aYajDhf2HasTe)mEGt5K)36IHAErn8mFOgYjNAeDfhyghujql18IAEcsIUc2asxiJ9ZSvU2WmoOIhqbu5jbbKcs4ixi(bKbs6okSdbK0mg8Z4X4SvhNqxJksmwQ5f14dij6kydijwnoFz0iOaQ8KNaKcs4ixi(bKbsIUc2asID7qg0MBXpwN1SwGGKUJc7qaPpE5wlxl(X6SM1cm)Xl3A5(mEmud5KtnQrnL0eXYvHcMlw(hi18qQHG(qnEPMpE5wlxl(X6SM1cm)Xl3A5SLOprnVOgcsnQcsJOGGKy3oKbT5w8J1znRfiOaQ88XasbjCKle)aYajrxbBajXUDidAZT4hRZAwlqqs3rHDiG0hVCRLRf)yDwZAbM)4LBTC2s0NOMxudbPgVuZhVCRLtZMpNUIdmhZP8hVCRL7Z4XqnEPg1OMl3A5eRgNVmA01OIeJLAErnp9HAiNCQ5YTwofgSWjZdu4ZgxJksmwQ5f180hQHCYPMl3A50TOpbJHy2Y1erxJksmwQ5f180hQHCYPMl3A5cTNm(jIUgvKySuZlQ5Ppud5KtnF8YTwou6AdNSLFCcDnQiXyPMxuZJOgvbPruqqsSBhYG2Cl(X6SM1ceuavEQEasbjCKle)aYajrxbBajXUDidAZT4hRZAwlqqs3rHDiGKAuZhVCRLtZMpNUIdmhZP8hVCRLJJp1qo5uZLBTCIvJZxgn6AurIXsnVOMN(qnKto1C5wlNcdw4K5bk8zJRrfjgl18IAE6d1qo5uZLBTC6w0NGXqmB5AIORrfjgl18IAE6d1qo5uZLBTCH2tg)erxJksmwQ5f180hQHCYPMpE5wlhkDTHt2YpoHUgvKySuZlQ5ruJQuJxQPKMiwUnuG1MJVUOMhsn80tqAefeKe72HmOn3IFSoRzTabfqLNpcqkij6kydiXzXCuOIfKWrUq8diduGcK43bRJYdGuGkpbKcs4ixi(bKbs6okSdbKeDfhyghujql18ANAuJA45uJVHAuJAkbIt5wSwJloyMhX8ToCKle)udbsn8e1Ok1Ok14LAoKoKleDRgr)W(Y1tgh5cXp14LAoKoKleDlU2dHBO(uMq)bjrxbBajDl2TmmiUvtmebfqfccifKWrUq8didK0DuyhciD5wlxJ6tq0AZlwRrhhFQHCYPMkuqQ5HuJ6bsIUc2as1gM5MlJB(5fR1iOaQWtasbjCKle)aYajDhf2HasIFyhf643HIaZ87qbBxlZjQ51o1qqQXl18Xl3A543HIaZ87qbBNTe9jQzNAE6d14LAeDfhyghujql1StnpPgVuZH0HCHOB1i6h2xUEY4ixi(PgVuZH0HCHOBX1EiCd1NY(7pij6kydibLdjdf7gOaQ8yaPGeoYfIFazGKUJc7qaPdPd5cr3Qr0pSVC9KXrUq8tnEPMl3A5wqrbl2qKdDnQiXyPMhsne1FQXl1i6koWmoOsGwQ5f18eKeDfSbKwqrbl2qKdbfqf1dqkiHJCH4hqgiP7OWoeq6q6qUq0TAe9d7lxpzCKle)uJxQ5YTwUvZS1TL57AurIXsnpKAiQ)uJxQr0vCGzCqLaTuZlQ5jij6kydiTAMTUTmFqbu5rasbjCKle)aYajDhf2Has(IAUCRLt3IDlddIB1edrhhFQXl1i6koWmoOsGwQ5f18KA8snhshYfIUfx7HWnuFktO)GKORGnGKUf7wgge3QjgIGcOIVdifKWrUq8didK0Duyhci5lQ5YTwUfx7jZwzjAhhFQXl1Oii0wntHAETtne0hQXl1y5JqyUKMiww3IR9KzRSeD(lkcrKAETtnQrnpPM3uZH0HCHOB1i6h2xUEY4ixi(PgvbjrxbBaPfx7jZwzjAqbuHNdifKWrUq8didK0DuyhciD5wl3IR9KzRSeTJJp14LAS8rimxstelRBX1EYSvwIo)ffHisnpKAuJAEsnVPMdPd5cr3Qr0pSVC9KXrUq8tnQcsIUc2aslU2tMTYs0GcOcpdqkiHJCH4hqgiP7OWoeq6YTwUgTSrgnMlwHkUgvKySuZd3Pgcsnei1qu)bjrxbBaPIvOswrSf2EafqLN(aifKWrUq8didK0Duyhcij6koWmoOsGwQ51o1WtuJxQrnQXxudAT4Or3fYy)mBLRnmJdQ4XPieGzn1qo5uJAudAT4Or3fYy)mBLRnmJdQ4XPieGzn14LAuJAUCRLZIyTfdXClerhhFQHCYPgnJb)mEmUlKX(z2kxByghuXJRrfjgl18IAESpuJQuJQuJQGKORGnGKLB(yhdrqbu55taPGeoYfIFazGKUJc7qajrxXbMXbvc0snVOMNGKORGnG0IP5S4pl(HDuy(IIcOaQ8KGasbjCKle)aYajDhf2HasIUIdmJdQeOLAErnpbjrxbBaj(CDS8edX8fk2cuavEYtasbjCKle)aYajDhf2HasIUIdmJdQeOLAErnpbjrxbBaPo4ZhI5yYw(IgbfqLNpgqkiHJCH4hqgiP7OWoeqQeioLdkZ3cJp6WrUq8tnEPgFrnxU1YbL5BHXhDC8PgVuJEtAIOnVArxbBei18IAE68Dqs0vWgqQz6t3OWguavEQEasbjCKle)aYajDhf2HasQrnIFyhf6gP4AbM3KwHnEC4ixi(PgVuZLBTCJuCTaZBsRWgp5vZSLRrfjgl18WDQHGudbsne1FQrvQXl1uceNYTjb0wSwXHJCH4NA8snhshYfIUfx7HWnuFkR(jdKeDfSbKwnZw3wMpOaQ88rasbjCKle)aYajDhf2HasQrnIFyhf6gP4AbM3KwHnEC4ixi(PgVuZLBTCJuCTaZBsRWgp5v0ORrfjgl18WDQHGudbsne1FQrvqs0vWgqAbffSydroeuavE67asbjCKle)aYajDhf2HasQrnIFyhf6gP4AbM3KwHnEC4ixi(PgVuZLBTCJuCTaZBsRWgp5rkUgDnQiXyPMhUtneKAiqQHO(tnQsnEPgfbH2QzkuZdPgF3hqs0vWgqQz6t3OWguGcK(4s4GvwZAeqkqLNasbjCKle)aYajDhf2HashshYfIUfx7HWnuFktatGKORGnGekDTHt2YpoHGcOcbbKcs4ixi(bKbsIUc2as2I1k2QJtiiP7OWoeqs0vCGzCqLaTuZlQ5j14LAe)Wok0bdIB1edXSMnFUOC4ixi(PgVuJVOMpE5wlhmiUvtmeZA285IYXXNA8snhshYfIUfx7HWnuFkNsGK2JgI5sAIyzbQ8euav4jaPGeoYfIFazGKUJc7qaPl3A5SfRvUDmeX2XXNAiNCQrnQr0vCGzCqLaTuZlQ5j14LAUCRLJOuByhdXSTyTI1XXNA8snhshYfIUfx7HWnuFkNsuJQGKORGnGKTyTIT64eckGkpgqkiHJCH4hqgiP7OWoeqs0vCGzCqLaTuZRDQHNOgVuZH0HCHOBX1EiCd1NYe6pij6kydiPBXULHbXTAIHiOaQOEasbjCKle)aYajDhf2HasLaXPCSdS1BsteD4ixi(PgVuJOR4aZ4GkbAPMDQ5j14LAoKoKleDlU2dHBO(u2FYOgVuJIGqB1mfQ51o18yFajrxbBajyqCRMyiMVmybkGkpcqkiHJCH4hqgiP7OWoeq6q6qUq0PUe(agdMtjQXl1CiDixi6wCThc3q9PCkbsIUc2as2I1k2QJtiOafijwnGuGkpbKcs4ixi(bKbs6okSdbK8f1C5wlNUf7wgge3QjgIoo(uJxQr0vCGzCqLaTuZlQ5j14LAoKoKleDlU2dHBO(uMq)bjrxbBajDl2TmmiUvtmebfqfccifKWrUq8didK0DuyhcivceNYbL5BHXhD4ixi(PgVuJVOMl3A5GY8TW4Joo(uJxQrVjnr0MxTORGncKAErnpD(oij6kydi1m9PBuydkGk8eGuqs0vWgqIhX8TvhNqqch5cXpGmqbkqbshyBd2auHG(8KN5dp)PpGepKEIHOfKuFqHpRl8tnp9HAeDfSHAGHTSo6zqYYh1avi4J4jqIFZwbebj1HAiGZMmAubNIAsBIIm0ZQd1SvfFlbaE5LyuBCxNMPWRnu4GsfSr3YQ41gkAEPNvhQ5SmCs7HAi4tsOgc6db9HEMEwDOgc3KHiAjaqpRouJVHA8T)p(Pg(nQzkxPOgszfQqneal2cBpo6z1HA8nudbi2O(wudNfPgcO01g1qaHOcoLaPg1SYbsnrrnlwtnCvaJYJQo6z6z1HAiGQprnxHFQ5IlwJuJMPCLIAUiXySoQX3Q1i)YsndB8nBsRS4GuJORGnwQHnqpo6z1HAeDfSX643OMPCLAFbf7j6z1HAeDfSX643OMPCL69oVlg7tpRouJORGnwh)g1mLRuV35v4iQGtjvWg6z1HAsJW3UXkQPL4tnxU1c)uJTKYsnxCXAKA0mLRuuZfjgJLAK5tn8B03WNvvmePMWsnF2Go6z1HAeDfSX643OMPCL69oV2r4B3yv2wszPNfDfSX643OMPCL69oVfRqLSIylS9qpl6kyJ1XVrnt5k17DEHbXTAIHy2Ufi8tpl6kyJ1XVrnt5k17DE5ZQGn0Z0ZQd1qavFIAUc)udEGThQPcfKAQnKAeDXAQjSuJCibuUq0rpl6kyJDNhX8Z2nuA6z1HA8TvHk8lQPyuJ1ZOPMw0HaPgnJb)mEmwQHhrTrn(wRgNVmAKAyn1O(XwGutIF0rzjHAyn1WzrQHnuJMXGFgpgQjwuJvoIHi1uBOc1WJacPMgTCWIAIHASbXjwHwMIA0mg8Z4Xqn8qSfspl6kyJ99oVhshYfIKmIcURzm4NXJjB9mAsoeihURwjqCkNy148LrJoCKle)Ev7YTwoXQX5lJgDC8jNCnJb)mEmoXQX5lJgDnQiXyFPE(OQQKtUA(QeioLtSAC(YOrhoYfIFVQTWwGzl)OJY1OIeJ9L6ro5Agd(z8yClSfy2Yp6OCnQiXyFPE(OQQ0ZQd1qaIrndROgolsnc1Oii0wntX3Oz2kgIuJCdyuEOMyrnrrn8iGqQ52XqKA8W4OMIrn(qnkccTvZuOgz(uJwgncPMfx7HAylQrI2rpl6kyJ99oVhshYfIKmIcUV4ApeUH6t5uIKdbYH7kccTvZuETRwjqCk3IR9KzRSeTdh5cXpbQ2JEl6kyJZwSwXwDCcDAMTuvv6zrxbBSV359q6qUqKKruW9fx7HWnuFk7V)KCiqoCxrqOTAMYRD1kbIt5wCTNmBLLOD4ixi(jq1E0BrxbBCq5qYqXU50mBPQQ0ZIUc2yFVZ7H0HCHijJOG7lU2dHBO(uMq)j5qGC4UIGqB1mLx7QvceNYT4Apz2klr7WrUq8tGQ9O3IUc240Ty3YWG4wnXq0Pz2svvPNfDfSX(EN3dPd5crsgrb3xCThc3q9PS6NmsoeihURii0wnt51UALaXPClU2tMTYs0oCKle)eOAp6TORGnUvZS1TL570mBPQQ0ZIUc2yFVZ7H0HCHijJOG7lU2dHBO(uMaMi5qGC4UIGqB1mLx7QvceNYT4Apz2klr7WrUq8tGQ9O3IUc24qPRnCYw(Xj0Pz2svvPNfDfSX(EN3dPd5crsgrb3xCThc3q9PS)KrYHa5WDfbH2QzkV2vReioLBX1EYSvwI2HJCH4Nav7rVFSpQQk9S6qn(2Qqf(f1umQHpJbPgfbH2QzkuJLrnEyCQVqi1CrQrUqKAkg1OfBrnc1S4Gqp(g(mEGn(PgyqCRMyisnxgSOgXsnwgBOgXsnrP(APg5qcOCHi1WJnCOMvqCRIHi1WgKAkPjILJEw0vWg77DEpKoKlejzefCxDj8bmgKKdbYH7Qj6koWmoOsG2xpjNC10mg8Z4X4GbXTAIHy(YGLRrfjg7RDcsGe1FvvLEw0vWg77DEpKoKlejzefCxDj8bmgmNsKCiqoCxTdPd5crN6s4dymi5KRii0wnt51UALaXPCSdS1BsteD4ixi(jq1ESpVfDfSXzlwRyRooHonZwQQQQ0ZIUc2yFVZ7H0HCHijJOG7QlHpGXGz)9NKdbYH7QDiDixi6uxcFaJbjNCfbH2QzkV2vReioLJDGTEtAIOdh5cXpbQ2J95TORGnoOCizOy3CAMTuvvvPNfDfSX(EN3dPd5crsgrb3vxcFaJbZe6pjhcKd3v7q6qUq0PUe(agdso5kccTvZuETRwjqCkh7aB9M0erhoYfIFcuTh7ZBrxbBC6wSBzyqCRMyi60mBPQQQspl6kyJ99oVhshYfIKmIcURUe(agdMv)KrYHa5WD1oKoKleDQlHpGXGKtUIGqB1mLx7QvceNYXoWwVjnr0HJCH4Nav7X(8w0vWg3Qz262Y8DAMTuvvvPNvhQX3wfQWVOMIrn8zmi1Oii0wntHAwSMAiSf7g14FqCRMyisnXIAu4GvWhIutjnrSSuJ0i1WVrloLJEw0vWg77DEpKoKlejzefCNq)FaJbZ(7pjhcKd3fDfhyghujq7(tYjxrqOTAMYRD1eDfSXPBXULHbXTAIHOtZS1BrxbBCq5qYqXU50mBPk9SORGn2378EiDixisYik4oH()agdMtjsoeihUl6koWmoOsG29NKtUIGqB1mLx7Qj6kyJt3IDlddIB1edrNMzR3IUc24SfRvSvhNqNMzlvPNfDfSX(EN3dPd5crsgrb3xnI(H9LRNmoYfIFsoeihURwjqCk3gRYBY8D4ixi(9wceNYTjb0wSwXHJCH43R4h2rHo(DOiWm)ouW2HJCH4xv6zrxbBSV359q6qUqKKruW9MPpzHXhZ4ixi(j5qGC4UA(6q6qUq0TAe9d7lxpzCKle)EvReioL7Y4GFSxHTC4ixi(9wceNYbL5BHXhD4ixi(9k(HDuOZwnoeRTmBLrPRnhoYfIFvvLEw0vWg77DE1ceMfDfSjddBrYik4oJpoytpl6kyJ99oVAbcZIUc2KHHTizefCxSAsI1(LBTCIvJZxgn644tpl6kyJ99oVAbcZIUc2KHHTizefCNFhSokp0ZIUc2yFVZRwGWSORGnzyylsgrb3vKykCKrJKeRDrxXbMXbvc0(qEIEw0vWg77DE1ceMfDfSjddBrYik4U(BPNfDfSX(ENxTaHzrxbBYWWwKmIcUVAe9d7lxpznRrsI1(H0HCHOB1i6h2xUEY4ixi(PNfDfSX(ENxTaHzrxbBYWWwKmIcU)XLWbRSM1ijXA3xhshYfIUvJOFyF56jJJCH4NEw0vWg77DE1ceMfDfSjddBrYik4UIetHJmAKKyTl6koWmoOsG2x78e9SORGn2378Qfiml6kytgg2IKruW9vaHytptpl6kyJ1jw9UUf7wgge3QjgIKeRDFD5wlNUf7wgge3QjgIoo(EfDfhyghujq7RNEpKoKleDlU2dHBO(uMq)PNfDfSX6eR(9oVntF6gf2KeR9sG4uoOmFlm(Odh5cXVxFD5wlhuMVfgF0XX3REtAIOnVArxbBe4RNoFNEw0vWgRtS6378YJy(2QJti9m9S6qnek2IAidYyFiNTOgfz4ei0d1elQP2qQX36h2rHudPTef14BhnARwGudbqqlBKrJutyPg(nAXPC0ZIUc2yD6VD)czSpKZwKeRDXpSJcDYOrB1cm3OLnYOrhoYfIF6zrxbBSo93(ENxEWA4)aJj3OLnYOr6zrxbBSo93(EN3l2wSpfdrsI1(H0HCHOtZyWpJht26z00ZIUc2yD6V99oVCwmhfQqYik4U4NDtAXMxSPYSvMpJhytpl6kyJ1P)2378EHm2pV4ApKeR9dPd5crNMXGFgpMS1ZOPNfDfSX60F77DExrJxiJ9jjw7hshYfIonJb)mEmzRNrtpl6kyJ1P)2378kJgTvlWSwGqsI1(H0HCHOtZyWpJht26z00ZQd14BRcv4xutXOgRNrtnEyCn1qa6bjQHpRc2qn8iQnQrOgnJb)mEmKqnCdeTwQP2qQPKMiwutyPg5Y4kQPyuZpqh9SORGnwN(BFVZlFwfSHKyTF5wlNy148LrJoo(KtUVkbIt5eRgNVmA0HJCH437cBbMT8JokxJksm2xQh5KxstelxfkyUy5FGpC)r(qpl6kyJ1P)2378sKt6FitMTYIFyZQn6zrxbBSo93(EN3f2cmB5hDu0ZIUc2yD6V99oVxiJ9ZSvU2WmoOIhsI1ElXpJh4uo5)TUyEXZ8HCYfDfhyghujq7RN0ZIUc2yD6V99oVIvJZxgnssS21mg8Z4X4SvhNqxJksm2x(qpl6kyJ1P)2378YzXCuOcjJOG7ID7qg0MBXpwN1SwGKeR9pE5wlxl(X6SM1cm)Xl3A5(mEmKtUAL0eXYvHcMlw(h4djOpE)4LBTCT4hRZAwlW8hVCRLZwI(0lcQk9SORGnwN(BFVZlNfZrHkKmIcUl2TdzqBUf)yDwZAbssS2)4LBTCT4hRZAwlW8hVCRLZwI(0lc69JxU1YPzZNtxXbMJ5u(JxU1Y9z8y8Q2LBTCIvJZxgn6AurIX(6PpKt(LBTCkmyHtMhOWNnUgvKySVE6d5KF5wlNUf9jymeZwUMi6AurIX(6PpKt(LBTCH2tg)erxJksm2xp9HCY)4LBTCO01gozl)4e6AurIX(6rQspl6kyJ1P)2378YzXCuOcjJOG7ID7qg0MBXpwN1SwGKeRD1(4LBTCA2850vCG5yoL)4LBTCC8jN8l3A5eRgNVmA01OIeJ91tFiN8l3A5uyWcNmpqHpBCnQiXyF90hYj)YTwoDl6tWyiMTCnr01OIeJ91tFiN8l3A5cTNm(jIUgvKySVE6d5K)Xl3A5qPRnCYw(Xj01OIeJ91Ju1BjnrSCBOaRnhFD9qE6j9SORGnwN(BFVZlNfZrHkw6z1HAeDfSX60F77DErPRTmcrfCkbsptpl6kyJ19XLWbRSM14okDTHt2YpoHKeR9dPd5cr3IR9q4gQpLjGj6zrxbBSUpUeoyL1SgFVZRTyTIT64esI2JgI5sAIyz3FssS2fDfhyghujq7RNEf)Wok0bdIB1edXSMnFUOC4ixi(96RpE5wlhmiUvtmeZA285IYXX37H0HCHOBX1EiCd1NYPe9SORGnw3hxchSYAwJV351wSwXwDCcjjw7xU1YzlwRC7yiITJJp5KRMOR4aZ4GkbAF907LBTCeLAd7yiMTfRvSoo(EpKoKleDlU2dHBO(uoLuLEw0vWgR7JlHdwznRX378QBXULHbXTAIHijXAx0vCGzCqLaTV25jVhshYfIUfx7HWnuFktO)0ZIUc2yDFCjCWkRzn(ENxyqCRMyiMVmyrsS2lbIt5yhyR3KMi6WrUq87v0vCGzCqLaT7p9EiDixi6wCThc3q9PS)K5vrqOTAMYR9h7d9SORGnw3hxchSYAwJV351wSwXwDCcjjw7hshYfIo1LWhWyWCk59q6qUq0T4ApeUH6t5uIEMEw0vWgRBfqi27wU5JDmejjw7Te)mEGt5K)36I51J9HEw0vWgRBfqi2V35DX0Cw8Nf)WokmFrrHKyT3s8Z4boLt(FRlMx8mF86Rl3A5eRgNVmA0XX3RVUCRLtHblCY8af(SXXX3RVUCRLl0EY4Ni64471xxU1YPBrFcgdXSLRjIoo(E91hVCRLdLU2WjB5hNqhhF6zrxbBSUvaHy)ENx(CDS8edX8fk2IKyT3s8Z4boLt(FRlMxpYh6zrxbBSUvaHy)EN3o4ZhI5yYw(Igjjw7Te)mEGt5K)36I51J8HEw0vWgRBfqi2V35T24Mp26nPjI0ZIUc2yDRacX(9oVA2OXPAPWFEbffKEw0vWgRBfqi2V35TrHFmeZlOOGw6zrxbBSUvaHy)EN3RqmZw5Qd9jl9SORGnw3kGqSFVZRUf7wgge3QjgIKeR9sG4uUfR14IdM5rmFRdh5cXVxrxXbMXbvc0(6P3dPd5cr3IR9q4gQpLj0F6zrxbBSUvaHy)EN3fuuWIne5qsI1EjqCkNfLogIzXAfoy5WrUq8tpl6kyJ1Tcie7378cLdjdf7gjXA3xIFyhf643HIaZ87qbBhoYfIFVLaXPCBSkVjZ3HJCH437LBTCBSkVjZ31OOl6zrxbBSUvaHy)ENxDl2TmmiUvtmejjw7IUIdmJdQeO91tVhshYfIUfx7HWnuFktO)0ZIUc2yDRacX(9oVntF6gf2KeRDfbH2Qzkp039XRVUCRLZwnoeRTmBLrPRnhhF6zrxbBSUvaHy)ENxDl2TmmiUvtmejjw7QvceNYPBXUfdXSTyTIdh5cXp5KxceNYTyTgxCWmpI5BD4ixi(v17H0HCHOtDj8bmgmtO)0ZIUc2yDRacX(9oVq5qYqXUrsS2pKoKleDQlHpGXGz)937H0HCHOBX1EiCd1NY(7p9SORGnw3kGqSFVZRcQWApz2kd50Xp)BuuS0ZIUc2yDRacX(9oVntF6gf20ZIUc2yDRacX(9oVRMzRBlZNKyTxceNYTjb0wSwXHJCH437LBTCRMzRBlZ31OIeJ9Hp2XZFtu)9EiDixi6wCThc3q9PS6Nm6zrxbBSUvaHy)EN3fuuWIne5q6z6zrxbBSUvJOFyF56jRznUdLdjdf7gjApAiMlPjILD)jjXAx8d7Oqh)oueyMFhky7Azo9ANGE)4LBTC87qrGz(DOGTZwI(0(tF8EiDixi6wCThc3q9PS)(79q6qUq0rO)pGXGz)9NEw0vWgRB1i6h2xUEYAwJV35fLU2WjB5hNqsI1(H0HCHOBX1EiCd1NYeWe9SORGnw3Qr0pSVC9K1SgFVZRTyTIT64esI2JgI5sAIyz3FssS2fDfhyghujq7RNEf)Wok0bdIB1edXSMnFUOC4ixi(96RpE5wlhmiUvtmeZA285IYXX37H0HCHOBX1EiCd1NYPe9SORGnw3Qr0pSVC9K1SgFVZRTyTIT64essS2VCRLZwSw52XqeBhhFYjxnrxXbMXbvc0(6P3l3A5ik1g2XqmBlwRyDC89EiDixi6wCThc3q9PCkPk9SORGnw3Qr0pSVC9K1SgFVZRUf7wgge3QjgIKeRDrxXbMXbvc0(ANN8EiDixi6wCThc3q9PmH(tpl6kyJ1TAe9d7lxpznRX378cdIB1edX8LblsI1EjqCkh7aB9M0erhoYfIFVIUIdmJdQeOD)P3dPd5cr3IR9q4gQpL9NmVkccTvZuET)yFONfDfSX6wnI(H9LRNSM147DEHYHKHIDJKyTl(HDuOJFhkcmZVdfSDTmNETtqVF8YTwo(DOiWm)ouW2zlrF6LV79q6qUq0T4ApeUH6tz)937H0HCHOJq)FaJbZ(7p9SORGnw3Qr0pSVC9K1SgFVZRTyTIT64essS2pKoKleDQlHpGXG5uY7H0HCHOBX1EiCd1NYPK3dPd5crhH()agdMtj6zrxbBSUvJOFyF56jRzn(ENxOCizOy3ijw7F8YTwo(DOiWm)ouW2zlrFA)PpEpKoKleDlU2dHBO(u2F)PNPNfDfSX6uKykCKrJ7lOOGfBiYHKeRDFD5wl3ckkyXgICOJJp9SORGnwNIetHJmA89oVRMzRBlZNKyTxceNYTjb0wSwXHJCH43RVUCRLB1mBDBz(oo(EpKoKleDlU2dHBO(uw9tg9m9SORGnwhJpoyV3m9PBuytsS2veeARMP8WNQN3kuWhsu)PNPNfDfSX643bRJYZUUf7wgge3QjgIKeRDrxXbMXbvc0(AxnEUVrTsG4uUfR14IdM5rmFRdh5cXpbYtQQQ3dPd5cr3Qr0pSVC9KXrUq879q6qUq0T4ApeUH6tzc9NEw0vWgRJFhSokpV35T2Wm3CzCZpVyTgjjw7xU1Y1O(eeT28I1A0XXNCYRqbFO6rpl6kyJ1XVdwhLN378cLdjdf7gjXAx8d7Oqh)oueyMFhky7Azo9ANGE)4LBTC87qrGz(DOGTZwI(0(tF8k6koWmoOsG29NEpKoKleDRgr)W(Y1tgh5cXV3dPd5cr3IR9q4gQpL93F6zrxbBSo(DW6O88EN3fuuWIne5qsI1(H0HCHOB1i6h2xUEY4ixi(9E5wl3ckkyXgICORrfjg7djQ)EfDfhyghujq7RN0ZIUc2yD87G1r559oVRMzRBlZNKyTFiDixi6wnI(H9LRNmoYfIFVxU1YTAMTUTmFxJksm2hsu)9k6koWmoOsG2xpPNfDfSX643bRJYZ7DE1Ty3YWG4wnXqKKyT7Rl3A50Ty3YWG4wnXq0XX3ROR4aZ4GkbAF907H0HCHOBX1EiCd1NYe6p9SORGnwh)oyDuEEVZ7IR9KzRSenjXA3xxU1YT4Apz2klr7447vrqOTAMYRDc6JxlFecZL0eXY6wCTNmBLLOZFrriIV2v757dPd5cr3Qr0pSVC9KXrUq8Rk9SORGnwh)oyDuEEVZ7IR9KzRSenjXA)YTwUfx7jZwzjAhhFVw(ieMlPjIL1T4Apz2klrN)IIqeFOApFFiDixi6wnI(H9LRNmoYfIFvPNfDfSX643bRJYZ7DElwHkzfXwy7HKyTF5wlxJw2iJgZfRqfxJksm2hUtqcKO(tpl6kyJ1XVdwhLN378A5Mp2XqKKyTl6koWmoOsG2x78Kx18fAT4Or3fYy)mBLRnmJdQ4XPieGzn5KRgAT4Or3fYy)mBLRnmJdQ4XPieGzTx1UCRLZIyTfdXClerhhFYjxZyWpJhJ7czSFMTY1gMXbv84AurIX(6X(OQQQspl6kyJ1XVdwhLN378UyAol(ZIFyhfMVOOqsS2fDfhyghujq7RN0ZIUc2yD87G1r559oV856y5jgI5luSfjXAx0vCGzCqLaTVEspl6kyJ1XVdwhLN3782bF(qmht2Yx0ijXAx0vCGzCqLaTVEspl6kyJ1XVdwhLN3782m9PBuytsS2lbIt5GY8TW4JoCKle)E91LBTCqz(wy8rhhFV6nPjI28QfDfSrGVE68D6z1HAuFmQnQrfP4AbsneavAf24HeQbH4Hui1uBi1WVdwhLhQHTOgeIk4ucKAKQe9jl1ed1W6p2utXOgfjMsIHAQnKAUCRLLA4XgoutTHEuFBKAKlJROMIrnO6t(rJo6zrxbBSo(DW6O88EN3vZS1TL5tsS2vt8d7Oq3ifxlW8M0kSXJdh5cXV3l3A5gP4AbM3KwHnEYRMzlxJksm2hUtqcKO(RQ3sG4uUnjG2I1koCKle)EpKoKleDlU2dHBO(uw9tg9SORGnwh)oyDuEEVZ7ckkyXgICijXAxnXpSJcDJuCTaZBsRWgpoCKle)EVCRLBKIRfyEtAf24jVIgDnQiXyF4objqI6VQ0ZIUc2yD87G1r559oVntF6gf2KeRD1e)Wok0nsX1cmVjTcB84WrUq879YTwUrkUwG5nPvyJN8ifxJUgvKySpCNGeir9xvVkccTvZuEOV7dOafaa]] )


end
