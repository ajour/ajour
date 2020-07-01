-- MonkMistweaver.lua
-- May 2020

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State

local PTR = ns.PTR


if UnitClassBase( 'player' ) == 'MONK' then
    local spec = Hekili:NewSpecialization( 270 )

    spec:RegisterResource( Enum.PowerType.Mana )
    spec:RegisterResource( Enum.PowerType.Energy )
    spec:RegisterResource( Enum.PowerType.Chi )
    
    -- Talents
    spec:RegisterTalents( {
        mist_wrap = 19823, -- 197900
        chi_wave = 19820, -- 115098
        chi_burst = 20185, -- 123986

        celerity = 19304, -- 115173
        chi_torpedo = 19818, -- 115008
        tigers_lust = 19302, -- 116841

        lifecycles = 22168, -- 197915
        spirit_of_the_crane = 22167, -- 210802
        mana_tea = 22166, -- 197908

        tiger_tail_sweep = 19993, -- 264348
        song_of_chiji = 22219, -- 198898
        ring_of_peace = 19995, -- 116844

        healing_elixir = 23371, -- 122281
        diffuse_magic = 20173, -- 122783
        dampen_harm = 20175, -- 122278

        summon_jade_serpent_statue = 23107, -- 115313
        refreshing_jade_wind = 22101, -- 196725
        invoke_chiji_the_red_crane = 22214, -- 198664

        focused_thunder = 22218, -- 197895
        upwelling = 22169, -- 274963
        rising_mist = 22170, -- 274909
    } )

    -- PvP Talents
    spec:RegisterPvpTalents( { 
        adaptation = 3575, -- 214027
        relentless = 3576, -- 196029
        gladiators_medallion = 3577, -- 208683
        eminence = 70, -- 216255
        way_of_the_crane = 676, -- 216113
        grapple_weapon = 3732, -- 233759
        dome_of_mist = 680, -- 202577
        healing_sphere = 683, -- 205234
        surging_mist = 681, -- 227344
        chrysalis = 678, -- 202424
        zen_focus_tea = 1928, -- 209584
        counteract_magic = 679, -- 202428
        refreshing_breeze = 682, -- 202523
    } )

    -- Auras
    spec:RegisterAuras( {
        chi_torpedo = {
            id = 119085,
            duration = 10,
            max_stack = 1,
        },
        crackling_jade_lightning = {
            id = 117952,
            duration = 4,
            max_stack = 1,
        },
        dampen_harm = {
            id = 122278,
            duration = 10,
            max_stack = 1,
        },
        diffuse_magic = {
            id = 122783,
            duration = 6,
            max_stack = 1,
        },
        enveloping_mist = {
            id = 124682,
            duration = function ()
                return talent.mist_wrap.enabled and 7 or 6
            end,
            type = "Magic",
            max_stack = 1,
            friendly = true,
        },
        essence_font = {
            id = 191840,
            duration = function () return talent.upwelling.enabled and 14 or 8 end,
            max_stack = 1,
            friendly = true,
        },
        fortifying_brew = {
            id = 243435,
            duration = 15,
            max_stack = 1,
        },
        impressive_influence = {
            id = 328136,
            duration = 3600,
            max_stack = 1,
        },
        leg_sweep = {
            id = 119381,
            duration = 3,
            max_stack = 1,
        },
        life_cocoon = {
            id = 116849,
            duration = 12,
            max_stack = 1,
        },
        lifecycles_enveloping_mist = {
            id = 197919,
            duration = 15,
            max_stack = 1,
        },
        lifecycles_vivify = {
            id = 197916,
            duration = 15,
            max_stack = 1,
        },
        mana_divining_stone = {
            id = 227723,
            duration = 3600,
            max_stack = 1,
        },
        mana_tea = {
            id = 197908,
            duration = 12,
            max_stack = 1,
        },
        mystic_touch = {
            id = 113746,
            duration = 3600,
            max_stack = 1,
        },
        paralysis = {
            id = 115078,
            duration = 60,
            max_stack = 1,
        },
        provoke = {
            id = 116189,
            duration = 3,
            max_stack = 1,
        },
        refreshing_jade_wind = {
            id = 196725,
            duration = 9,
            max_stack = 1,
        },
        renewing_mist = {
            id = 119611,
            duration = 20,
            type = "Magic",
            max_stack = 1,
            friendly = true,
        },
        song_of_chiji = {
            id = 198909,
            duration = 20,
            type = "Magic",
            max_stack = 1,
        },
        soothing_mist = {
            id = 115175,
            duration = 8,
            max_stack = 1,
            friendly = true,
        },
        spinning_crane_kick = {
            id = 101546,
        },
        teachings_of_the_monastery = {
            id = 202090,
            duration = 20,
            max_stack = 3,
        },
        thunder_focus_tea = {
            id = 116680,
            duration = 30,
            max_stack = 2,
        },
        tiger_tail_sweep = {
            id = 264348,
        },
        tigers_lust = {
            id = 116841,
            duration = 6,
            max_stack = 1,
        },
        transcendence = {
            id = 101643,
            duration = 900,
            max_stack = 1,
        },
        transcendence_transfer = {
            id = 119996,
        },
        zen_pilgrimage = {
            id = 126892,
        },
    } )


    -- What do we need to know to do effective Fistweaving via Rising Mist?
    -- 1.  How many HOTs are rolling right now?
    -- 2.  How many HOTs can be extended?
    -- 3.  How many HOTs refreshable HOTs can be gained from casting Essence Font?

    do
        
        local hotPool = {}

        local function NewHOT( guid, expires, refreshes )            
            local t = table.remove( hotPool, 1 ) or {}

            t.guid = guid
            t.expires = expires
            t.refreshes = refreshes or 0

            return t
        end

        local function RemoveHOT( aura, index )
            table.insert( hotPool, table.remove( aura, index ) )
        end

        local mistweaver = setmetatable( {
            enveloping_mist = {
                maximum = 2,
                real = {},
                virtual = {},
            },

            essence_font = {
                maximum = 2,
                real = {},
                virtual = {},
            },

            renewing_mists = {
                maximum = 5,
                real = {},
                virtual = {},
            },

            apply_hot = function( aura, guid, expires, real )
                local t = mistweaver[ aura ]
                if not t then return end

                local maximum = t.maximum

                if real then t = t.real
                else t = t.virtual end

                for i = #t, -1, 1 do
                    if t[ i ].guid == guid then
                        RemoveHOT( t, i )
                    end
                end

                local n = NewHOT()

                n.guid = guid
                n.expires = expires
                n.refreshes = maximum

                table.insert( t, n )
            end,

            remove_hot = function( aura, guid, real )
                if aura == nil then
                    mistweaver.remove_hot( "enveloping_mist", guid, real )
                    mistweaver.remove_hot( "essence_font", guid, real )
                    mistweaver.remove_hot( "renewing_mists", guid, real )
                else
                    local t = mistweaver[ aura ]

                    for i = #t, -1, 1 do
                        if t[ i ].guid == guid then
                            RemoveHOT( t, i )
                        end
                    end
                end
            end,
        }, {
            __index = function( t, k )

            end,
        } )

        spec:RegisterStateTable( "mistweaver", mistweaver )
    
    end




    local ENVELOPING_MIST = 124682
    local ESSENCE_FONT    = 191840
    local RENEWING_MIST   = 119611

    spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
        if sourceGUID == GUID then
            if subtype == "SPELL_CAST_SUCCESS" and spellID == 107428 and talent.rising_mists.enabled then
                mistweaver.extend_hots()
                
            elseif subtype == "SPELL_AURA_APPLIED" then
                if spellID == 119611 then
                    newHOT( "__renewing_mist", destGUID, GetTime() + 20 )
                elseif spellID == 124682 then
                    newHOT( "__enveloping_mist", destGUID, GetTime() + ( talent.mist_wrap.enabled and 7 or 6 ) )
                elseif spellID == 191840 then
                    newHOT( "__essence_font", destGUID, GetTime() + 8 )
                end
            end
        end
    end )

    -- What else would be useful?
    -- 1.  

    -- Special healer stuff and options.
    spec:RegisterStateTable( "mistweaver", setmetatable( {}, {
        __index = function( t, k )
        end,
    } ) )


    spec:RegisterHook( "reset_precast", function ()
        if buff.thunder_focus_tea.up then
            setCooldown( "thunder_focus_tea", buff.thunder_focus_tea.remains + action.thunder_focus_tea.cooldown )
        end
    end )


    -- Abilities
    spec:RegisterAbilities( {
        blackout_kick = {
            id = 100784,
            cast = 0,
            cooldown = 3,
            gcd = "spell",
            
            spend = 0,
            spendType = "chi",
            
            startsCombat = true,
            texture = 574575,
            
            handler = function ()
                removeBuff( "teachings_of_the_monastery" )
            end,
        },
        

        chi_burst = {
            id = 123986,
            cast = 1,
            cooldown = 30,
            gcd = "spell",
            
            startsCombat = true,
            texture = 135734,

            talent = "chi_burst",
            
            handler = function ()                
            end,
        },
        

        chi_torpedo = {
            id = 115008,
            cast = 0,
            charges = 2,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",
            
            startsCombat = true,
            texture = 607849,

            talent = "chi_torpedo",
            
            handler = function ()
                -- applies chi_torpedo (119085)
                applyBuff( "chi_torpedo" )
            end,
        },
        

        chi_wave = {
            id = 115098,
            cast = 0,
            cooldown = 15,
            gcd = "spell",
            
            startsCombat = true,
            texture = 606541,

            talent = "chi_wave",
            
            handler = function ()
                applyDebuff( "target", "chi_wave" )
            end,
        },
        

        crackling_jade_lightning = {
            id = 117952,
            cast = 4,
            cooldown = 0,
            gcd = "spell",

            channeled = true,
            
            spend = 0,
            spendType = "energy",
            
            startsCombat = true,
            texture = 606542,
            
            handler = function ()
                -- applies crackling_jade_lightning (117952)
                applyDebuff( "target", "crackling_jade_lightning" )
            end,
        },
        

        dampen_harm = {
            id = 122278,
            cast = 0,
            cooldown = 120,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 620827,

            talent = "dampen_harm",
            
            handler = function ()
                -- applies dampen_harm (122278)
                applyBuff( "dampen_harm" )
            end,
        },
        

        detox = {
            id = 115450,
            cast = 0,
            charges = 1,
            cooldown = 8,
            recharge = 8,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = true,
            texture = 460692,

            handler = function ()
                -- NYI.
            end,
        },
        

        diffuse_magic = {
            id = 122783,
            cast = 0,
            cooldown = 90,
            gcd = "spell",
            
            startsCombat = true,
            texture = 775460,

            talent = "diffuse_magic",
            
            handler = function ()
                applyBuff( "diffuse_magic" )
                removeBuff( "dispellable_magic" )
            end,
        },
        

        enveloping_mist = {
            id = 124682,
            cast = 2,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.05,
            spendType = "mana",
            
            startsCombat = true,
            texture = 775461,
            
            handler = function ()
                applyBuff( "enveloping_mist" )

                if buff.thunder_focus_tea.up then
                    removeStack( "thunder_focus_tea" )
                    if buff.thunder_focus_tea.down then setCooldown( "thunder_focus_tea", action.thunder_focus_tea.cooldown ) end
                end

                if talent.lifecycles.enabled then
                    applyBuff( "lifecycles_vivify" )
                    removeBuff( "lifecycles_enveloping_mist" )
                end
            end,
        },
        

        essence_font = {
            id = 191837,
            cast = 3,
            cooldown = 12,
            gcd = "spell",
            
            spend = 0.07,
            spendType = "mana",
            
            startsCombat = true,
            texture = 1360978,
            
            handler = function ()
                applyBuff( "essence_font" )
            end,
        },
        

        fortifying_brew = {
            id = 243435,
            cast = 0,
            cooldown = 90,
            gcd = "spell",
            
            startsCombat = true,
            texture = 1616072,
            
            handler = function ()
                -- 243453
                applyBuff( "fortifying_brew" )
            end,
        },
        

        healing_elixir = {
            id = 122281,
            cast = 0,
            charges = 2,
            cooldown = 30,
            recharge = 30,
            gcd = "spell",
            
            startsCombat = true,
            texture = 608939,

            talent = "healing_elixir",
            
            handler = function ()
                gain( 0.15 * health.max, "health" )
            end,
        },
        

        invoke_chiji_the_red_crane = {
            id = 198664,
            cast = 0,
            cooldown = 180,
            gcd = "spell",
            
            startsCombat = true,
            texture = 877514,

            talent = "invoke_chiji_the_red_crane",
            
            handler = function ()
                summonPet( "chiji" )
            end,
        },
        

        leg_sweep = {
            id = 119381,
            cast = 0,
            cooldown = 60,
            gcd = "spell",
            
            startsCombat = true,
            texture = 642414,
            
            handler = function ()
                -- applies leg_sweep (119381)
                applyDebuff( "target", "leg_sweep" )
                interrupt()
            end,
        },
        

        life_cocoon = {
            id = 116849,
            cast = 0,
            cooldown = 120,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 627485,
            
            handler = function ()
                -- 116849
                applyBuff( "life_cocoon" )
            end,
        },
        

        mana_tea = {
            id = 197908,
            cast = 0,
            cooldown = 90,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 608949,
            
            handler = function ()
                -- 197908
                applyBuff( "mana_tea" )
            end,
        },
        

        paralysis = {
            id = 115078,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            spend = 0,
            spendType = "energy",
            
            startsCombat = true,
            texture = 629534,
            
            handler = function ()
                -- applies paralysis (115078)
                applyDebuff( "paralysis" )
            end,
        },
        

        provoke = {
            id = 115546,
            cast = 0,
            cooldown = 8,
            gcd = "off",
            
            startsCombat = true,
            texture = 620830,
            
            handler = function ()
                -- applies provoke (116189)
                applyDebuff( "target", "provoke" )  
            end,
        },
        

        reawaken = {
            id = 212051,
            cast = 10,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = true,
            texture = 1056569,
            
            handler = function ()
                -- Mass Resurrection.
            end,
        },
        

        refreshing_jade_wind = {
            id = 196725,
            cast = 0,
            cooldown = 9,
            gcd = "spell",
            
            spend = 0.04,
            spendType = "mana",
            
            startsCombat = true,
            texture = 606549,

            talent = "refreshing_jade_wind",
            
            handler = function ()
                applyBuff( "refreshing_jade_wind" )
            end,
        },
        

        renewing_mist = {
            id = 115151,
            cast = 0,
            charges = 2,
            cooldown = 9,
            recharge = 9,
            gcd = "spell",
            
            spend = 0.02,
            spendType = "mana",
            
            startsCombat = true,
            texture = 627487,
            
            handler = function ()
                -- 119611
                applyBuff( "renewing_mist", buff.thunder_focus_tea.up and 30 or 20 )

                if buff.thunder_focus_tea.up then
                    removeStack( "thunder_focus_tea" )
                    if buff.thunder_focus_tea.down then setCooldown( "thunder_focus_tea", action.thunder_focus_tea.cooldown ) end
                end
            end,
        },
        

        resuscitate = {
            id = 115178,
            cast = 10,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0.01,
            spendType = "mana",
            
            startsCombat = true,
            texture = 132132,
            
            handler = function ()
                -- Resurrection.
            end,
        },
        

        revival = {
            id = 115310,
            cast = 0,
            cooldown = 180,
            gcd = "spell",
            
            spend = 0.04,
            spendType = "mana",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 1020466,
            
            handler = function ()
                removeDebuff( "dispellable_magic" )
                removeDebuff( "dispellable_poison" )
                removeDebuff( "dispellable_disease" )
            end,
        },
        

        ring_of_peace = {
            id = 116844,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            startsCombat = true,
            texture = 839107,

            talent = "ring_of_peace",
            
            handler = function ()
                interrupt()
            end,
        },
        

        rising_sun_kick = {
            id = 107428,
            cast = 0,
            cooldown = function () return buff.thunder_focus_tea.up and 3 or 12 end,
            gcd = "spell",
            
            spend = 0,
            spendType = "chi",
            
            startsCombat = true,
            texture = 642415,
            
            handler = function ()
                if talent.rising_mist.enabled then
                    if buff.renewing_mist.up and ( buff.renewing_mist.expires - buff.renewing_mist.applied < 2 * buff.renewing_mist.duration ) then buff.renewing_mist.expires = buff.renewing_mist.expires + 4 end
                    if buff.enveloping_mist.up and ( buff.enveloping_mist.expires - buff.enveloping_mist.applied < 2 * buff.enveloping_mist.duration ) then buff.enveloping_mist.expires = buff.enveloping_mist.expires + 4 end
                    if buff.essence_font.up and ( buff.essence_font.expires - buff.essence_font.applied < 2 * buff.essence_font.duration ) then buff.essence_font.expires = buff.essence_font.expires + 4 end
                end

                if buff.thunder_focus_tea.up then
                    removeStack( "thunder_focus_tea" )
                    if buff.thunder_focus_tea.down then setCooldown( "thunder_focus_tea", action.thunder_focus_tea.cooldown ) end
                end
            end,
        },
        

        roll = {
            id = 109132,
            cast = 0,
            charges = 2,
            cooldown = 20,
            recharge = 20,
            gcd = "spell",
            
            startsCombat = true,
            texture = 574574,
            
            handler = function ()
            end,
        },
        

        song_of_chiji = {
            id = 198898,
            cast = 1.8,
            cooldown = 30,
            gcd = "spell",
            
            startsCombat = true,
            texture = 332402,

            talent = "song_of_chiji",
            
            handler = function ()
                applyDebuff( "target", "song_of_chiji" )
            end,
        },
        

        soothing_mist = {
            id = 115175,
            cast = 8,
            cooldown = 0,
            gcd = "spell",

            channeled = true,
            
            spend = 0,
            spendType = "mana",
            
            startsCombat = true,
            texture = 606550,
            
            handler = function ()
                applyBuff( "soothing_mist" )
                -- Think about casting while channeling...
            end,
        },
        

        spinning_crane_kick = {
            id = 101546,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",

            channeled = true,
            
            spend = 0,
            spendType = "chi",
            
            startsCombat = true,
            texture = 606543,
            
            handler = function ()
            end,
        },
        

        summon_jade_serpent_statue = {
            id = 115313,
            cast = 0,
            cooldown = 10,
            gcd = "spell",
            
            startsCombat = true,
            texture = 620831,

            talent = "summon_jade_serpent_statue",
            
            handler = function ()
                summonPet( "jade_serpent_statue" )
            end,
        },
        

        thunder_focus_tea = {
            id = 116680,
            cast = 0,
            charges = function () return talent.focused_thunder.enabled and 2 or 1 end,
            cooldown = 30,
            recharge = 30,
            gcd = "off",
            
            startsCombat = true,
            texture = 611418,
            
            handler = function ()
                applyBuff( "thunder_focus_tea" )
            end,
        },
        

        tiger_palm = {
            id = 100780,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            spend = 0,
            spendType = "energy",
            
            startsCombat = true,
            texture = 606551,
            
            handler = function ()
                -- applies teachings_of_the_monastery (202090)
                addStack( "teachings_of_the_monastery", nil, 1 )
            end,
        },
        

        tigers_lust = {
            id = 116841,
            cast = 0,
            cooldown = 30,
            gcd = "spell",
            
            startsCombat = true,
            texture = 651727,

            talent = "tigers_lust",
            
            handler = function ()
                -- applies tigers_lust (116841)
                applyBuff( "tigers_lust" )
            end,
        },
        

        transcendence = {
            id = 101643,
            cast = 0,
            cooldown = 10,
            gcd = "spell",
            
            startsCombat = false,
            texture = 627608,
            
            handler = function ()
                -- applies transcendence (101643)
                applyBuff( "transcendance" )
            end,
        },
        

        transcendence_transfer = {
            id = 119996,
            cast = 0,
            cooldown = 45,
            gcd = "spell",
            
            startsCombat = false,
            texture = 237585,
            
            handler = function ()
            end,
        },
        

        vivify = {
            id = 116670,
            cast = 1.5,
            cooldown = 0,
            gcd = "spell",
            
            spend = function () return buff.thunder_focus_tea.up and 0 or 0.035 end,
            spendType = "mana",
            
            startsCombat = true,
            texture = 1360980,
            
            handler = function ()
                -- removes lifecycles_vivify (197916)
                -- applies lifecycles_enveloping_mist (197919)
                if talent.lifecycles.enabled then
                    removeBuff( "lifecycles_vivify" )
                    applyBuff( "lifecycles_enveloping_mist" )
                end

                if buff.thunder_focus_tea.up then
                    removeStack( "thunder_focus_tea" )
                    if buff.thunder_focus_tea.down then setCooldown( "thunder_focus_tea", action.thunder_focus_tea.cooldown ) end
                end
            end,
        },
        

        --[[
            wartime_ability = {
            id = 264739,
            cast = 0,
            cooldown = 0,
            gcd = "spell",
            
            startsCombat = true,
            texture = 1518639,
            
            handler = function ()
            end,
        },  ]]
        

        zen_pilgrimage = {
            id = 126892,
            cast = 10,
            cooldown = 60,
            gcd = "spell",
            
            toggle = "cooldowns",

            startsCombat = true,
            texture = 775462,
            
            handler = function ()
            end,
        },
    } )

end