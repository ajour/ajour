-- Hekili.lua
-- April 2014

local addon, ns = ...
local Hekili = _G[ addon ]

local class = Hekili.Class
local state = Hekili.State
local scripts = Hekili.Scripts

local callHook = ns.callHook
local clashOffset = ns.clashOffset
local formatKey = ns.formatKey
local getSpecializationID = ns.getSpecializationID
local getResourceName = ns.getResourceName
local orderedPairs = ns.orderedPairs
local tableCopy = ns.tableCopy
local timeToReady = ns.timeToReady

local GetItemInfo = ns.CachedGetItemInfo

local trim = string.trim


local tcopy = ns.tableCopy
local tinsert, tremove, twipe = table.insert, table.remove, table.wipe


-- checkImports()
-- Remove any displays or action lists that were unsuccessfully imported.
local function checkImports()
end
ns.checkImports = checkImports


local function EmbedBlizOptions()
    local panel = CreateFrame( "Frame", "HekiliDummyPanel", UIParent )
    panel.name = "Hekili"

    local open = CreateFrame( "Button", "HekiliOptionsButton", panel, "UIPanelButtonTemplate" )
    open:SetPoint( "CENTER", panel, "CENTER", 0, 0 )
    open:SetWidth( 250 )
    open:SetHeight( 25 )
    open:SetText( "Open Hekili Options Panel" )

    open:SetScript( "OnClick", function ()
        InterfaceOptionsFrameOkay:Click()
        GameMenuButtonContinue:Click()

        ns.StartConfiguration()
    end )

    Hekili:ProfileFrame( "OptionsEmbedFrame", open )

    InterfaceOptions_AddCategory( panel )
end


local hookOnce = false

-- OnInitialize()
-- Addon has been loaded by the WoW client (1x).
function Hekili:OnInitialize()
    self.DB = LibStub( "AceDB-3.0" ):New( "HekiliDB", self:GetDefaults() )

    self.Options = self:GetOptions()
    self.Options.args.profiles = LibStub( "AceDBOptions-3.0" ):GetOptionsTable( self.DB )

    -- Reimplement LibDualSpec; some folks want different layouts w/ specs of the same class.
    local LDS = LibStub( "LibDualSpec-1.0" )
    LDS:EnhanceDatabase( self.DB, "Hekili" )
    LDS:EnhanceOptions( self.Options.args.profiles, self.DB )

    self.DB.RegisterCallback( self, "OnProfileChanged", "TotalRefresh" )
    self.DB.RegisterCallback( self, "OnProfileCopied", "TotalRefresh" )
    self.DB.RegisterCallback( self, "OnProfileReset", "TotalRefresh" )

    local AceConfig = LibStub( "AceConfig-3.0" )
    AceConfig:RegisterOptionsTable( "Hekili", self.Options )

    local AceConfigDialog = LibStub( "AceConfigDialog-3.0" )
    -- self.optionsFrame = AceConfigDialog:AddToBlizOptions( "Hekili", "Hekili" )
    EmbedBlizOptions()

    self:RegisterChatCommand( "hekili", "CmdLine" )
    self:RegisterChatCommand( "hek", "CmdLine" )

    local LDB = LibStub( "LibDataBroker-1.1", true )
    local LDBIcon = LDB and LibStub( "LibDBIcon-1.0", true )
    if LDB then
        ns.UI.Minimap = ns.UI.Minimap or LDB:NewDataObject( "Hekili", {
            type = "launcher",
            text = "Hekili",
            icon = "Interface\\ICONS\\spell_nature_bloodlust",
            OnClick = function( f, button )
                if button == "RightButton" then ns.StartConfiguration()
                else
                    if not hookOnce then 
                        hooksecurefunc("UIDropDownMenu_InitializeHelper", function(frame)
                            for i = 1, UIDROPDOWNMENU_MAXLEVELS do
                                if _G["DropDownList"..i.."Backdrop"].SetTemplate then _G["DropDownList"..i.."Backdrop"]:SetTemplate( "Transparent" ) end
                                if _G["DropDownList"..i.."MenuBackdrop"].SetTemplate then _G["DropDownList"..i.."MenuBackdrop"]:SetTemplate( "Transparent" ) end
                            end
                        end )
                        hookOnce = true
                    end
                    ToggleDropDownMenu( 1, nil, ns.UI.Menu, "cursor", 0, 0 )
                end
                GameTooltip:Hide()
            end,
            OnTooltipShow = function( tt )
                tt:AddDoubleLine( "Hekili", ns.UI.Minimap.text )
                tt:AddLine( "|cFFFFFFFFLeft-click to make quick adjustments.|r" )
                tt:AddLine( "|cFFFFFFFFRight-click to open the options interface.|r" )
            end,
        } )

        function ns.UI.Minimap:RefreshDataText()
            local p = Hekili.DB.profile
            local m = p.toggles.mode.value
            local color = "FFFFD100"

            if p.toggles.essences.override then
                -- Don't show Essences here if it's overridden by CDs anyway?
                self.text = format( "|c%s%s|r %sCD|r %sInt|r %sDef|r", color,
                    m == "single" and "ST" or ( m == "aoe" and "AOE" or ( m == "dual" and "Dual" or ( m == "reactive" and "rAOE" or "Auto" ) ) ),
                    p.toggles.cooldowns.value and "|cFF00FF00" or "|cFFFF0000",
                    p.toggles.interrupts.value and "|cFF00FF00" or "|cFFFF0000",
                    p.toggles.defensives.value and "|cFF00FF00" or "|cFFFF0000" )
            else
                self.text = format( "|c%s%s|r %sCD|r %sAzE|r %sInt|r",
                    color,
                    m == "single" and "ST" or ( m == "aoe" and "AOE" or ( m == "dual" and "Dual" or ( m == "reactive" and "rAOE" or "Auto" ) ) ),
                    p.toggles.cooldowns.value and "|cFF00FF00" or "|cFFFF0000",
                    p.toggles.essences.value and "|cFF00FF00" or "|cFFFF0000",
                    p.toggles.interrupts.value and "|cFF00FF00" or "|cFFFF0000" )
            end
        end

        ns.UI.Minimap:RefreshDataText()

        if LDBIcon then
            LDBIcon:Register( "Hekili", ns.UI.Minimap, self.DB.profile.iconStore )
        end
    end


    --[[ NEED TO PUT VERSION UPDATING STUFF HERE.
    if not self.DB.profile.Version or self.DB.profile.Version < 7 or not self.DB.profile.Release or self.DB.profile.Release < 20161000 then
        self.DB:ResetDB()
    end

    self.DB.profile.Release = self.DB.profile.Release or 20170416.0 ]]

    -- initializeClassModule()
    self:RestoreDefaults()
    self:RunOneTimeFixes()
    checkImports()

    -- self:RefreshOptions()

    ns.updateTalents()

    ns.primeTooltipColors()

    self:UpdateDisplayVisibility()

    callHook( "onInitialize" )
end


function Hekili:ReInitialize()
    self:OverrideBinds()
    self:RestoreDefaults()

    checkImports()
    self:RunOneTimeFixes()

    self:SpecializationChanged()

    ns.updateTalents()

    self:UpdateDisplayVisibility()

    callHook( "onInitialize" )

    if self.DB.profile.enabled == false and self.DB.profile.AutoDisabled then 
        self.DB.profile.AutoDisabled = nil
        self.DB.profile.enabled = true
        self:Enable()
    end
end 


function Hekili:OnEnable()
    ns.StartEventHandler()

    self:TotalRefresh()

    ns.ReadKeybindings()
    self:ForceUpdate( "ADDON_ENABLED" )
    ns.Audit()    
end


Hekili:ProfileCPU( "StartEventHandler", ns.StartEventHandler )
Hekili:ProfileCPU( "BuildUI", Hekili.BuildUI )
Hekili:ProfileCPU( "SpecializationChanged", Hekili.SpecializationChanged )
Hekili:ProfileCPU( "OverrideBinds", Hekili.OverrideBinds )
Hekili:ProfileCPU( "TotalRefresh", Hekili.TotalRefresh )


function Hekili:OnDisable()
    self:UpdateDisplayVisibility()
    self:BuildUI()

    ns.StopEventHandler()
end


function Hekili:Toggle()
    self.DB.profile.enabled = not self.DB.profile.enabled

    if self.DB.profile.enabled then
        self:Enable()
    else
        self:Disable() 
    end

    self:UpdateDisplayVisibility()
end


-- Texture Caching,
local s_textures = setmetatable( {},
{
    __index = function(t, k)
        local a = _G[ 'GetSpellTexture' ](k)
        if a and k ~= GetSpellInfo( 115698 ) then t[k] = a end
        return (a)
    end
} )

local i_textures = setmetatable( {},
{
    __index = function(t, k)
        local a = select(10, GetItemInfo(k))
        if a then t[k] = a end
        return a
    end
} )

-- Insert textures that don't work well with predictions.
s_textures[ 115356 ] = 1029585 -- Windstrike
s_textures[ 17364 ] = 132314 -- Stormstrike
-- NYI: Need Chain Lightning/Lava Beam here.

local function GetSpellTexture( spell )
    -- if class.abilities[ spell ].item then return i_textures[ spell ] end
    return ( s_textures[ spell ] )
end


local z_PVP = {
    arena = true,
    pvp = true
}


local listStack = {}    -- listStack for a given index returns the scriptID of its caller (or 0 if called by a display).

local listCache = {}    -- listCache is a table of return values for a given scriptID at various times.
local listValue = {}    -- listValue shows the cached values from the listCache.

local lcPool = {}
local lvPool = {}

local Stack = {}
local Block = {}
local InUse = {}

local StackPool = {}


function Hekili:AddToStack( script, list, parent, run )
    local entry = tremove( StackPool ) or {}

    entry.script = script
    entry.list   = list
    entry.parent = parent
    entry.run    = run

    tinsert( Stack, entry )

    if self.ActiveDebug then
        local path = "+"
        
        for n, entry in ipairs( Stack ) do
            if entry.run then
                path = format( "%s%s [%s]", path, ( n > 1 and "," or "" ), entry.list )
            else
                path = format( "%s%s %s", path,( n > 1 and "," or "" ), entry.list )
            end
        end

        self:Debug( path )
    end

    -- if self.ActiveDebug then self:Debug( "Adding " .. list .. " to stack, parent is " .. ( parent or "(none)" ) .. " (RAL = " .. tostring( run ) .. ".") end

    InUse[ list ] = true
end


function Hekili:PopStack()
    local x = tremove( Stack, #Stack )

    if self.ActiveDebug then
        if x.run then
            self:Debug( "- [%s]", x.list )
        else
            self:Debug( "- %s", x.list )
        end
    end

    -- if self.ActiveDebug then self:Debug( "Removed " .. x.list .. " from stack." ) end

    for i = #Block, 1, -1 do
        if Block[ i ].parent == x.script then
            if self.ActiveDebug then self:Debug( "Removed " .. Block[ i ].list .. " from blocklist as " .. x.list .. " was its parent." ) end
            tinsert( StackPool, tremove( Block, i ) )
        end
    end

    if x.run then
        -- This was called via Run Action List; we have to make sure it DOESN'T PASS until we exit this list.
        if self.ActiveDebug then self:Debug( "Added " .. x.list .. " to blocklist as it was called via RAL." ) end
        tinsert( Block, x )
    end

    InUse[ x.list ] = nil
end


function Hekili:CheckStack()
    local t = state.query_time

    for i, b in ipairs( Block ) do
        listCache[ b.script ] = listCache[ b.script ] or tremove( lcPool ) or {}
        local cache = listCache[ b.script ]

        if cache[ t ] == nil then cache[ t ] = scripts:CheckScript( b.script ) end

        if self.ActiveDebug then
            listValue[ b.script ] = listValue[ b.script ] or tremove( lvPool ) or {}
            local values = listValue[ b.script ]

            values[ t ] = values[ t ] or scripts:GetConditionsAndValues( b.script )
            self:Debug( "Blocking list ( %s ) called from ( %s ) would %s at %.2f.", b.list, b.script, cache[ t ] and "BLOCK" or "NOT BLOCK", state.delay )
            self:Debug( values[ t ] )
        end

        if cache[ t ] then
            return false
        end
    end


    for i, s in ipairs( Stack ) do
        listCache[ s.script ] = listCache[ s.script ] or tremove( lcPool ) or {}
        local cache = listCache[ s.script ]

        if cache[ t ] == nil then cache[ t ] = scripts:CheckScript( s.script ) end

        if self.ActiveDebug then
            listValue[ s.script ] = listValue[ s.script ] or tremove( lvPool ) or {}
            local values = listValue[ s.script ]

            values[ t ] = values[ t ] or scripts:GetConditionsAndValues( s.script )
            self:Debug( "List ( %s ) called from ( %s ) would %s at %.2f.", s.list, s.script, cache[ t ] and "PASS" or "FAIL", state.delay )
            self:Debug( values[ t ] )
        end

        if not cache[ t ] then
            return false
        end
    end

    return true
end


local default_modifiers = {
    early_chain_if = false,
    chain = false,
    interrupt_if = false,
    interrupt = false
}

function Hekili:CheckChannel( ability, prio )
    if not state.channeling then return true end

    local channel = state.channel
    local aura = class.auras[ channel ]
    if not aura or not aura.tick_time then return true end

    local modifiers = scripts.Channels[ state.system.packName ]
    modifiers = modifiers and modifiers[ channel ] or default_modifiers

    local tick_time = aura.tick_time
    local remains = state.channel_remains

    if channel == ability then
        if prio <= remains + 0.01 then
            return false
        end
        if modifiers.early_chain_if then
            return state.cooldown.global_cooldown.up and ( remains < tick_time or ( ( remains - state.delay ) / tick_time ) % 1 <= 0.5 ) and modifiers.early_chain_if()
        end
        if modifiers.chain then
            return state.cooldown.global_cooldown.up and ( remains < tick_time ) and modifiers.chain()
        end

    else
        -- If interrupt_global is flagged, we interrupt for any potential cast.  Don't bother with additional testing.
        -- REVISIT THIS:  Interrupt Global allows entries from any action list rather than just the current (sub) list.
        -- That means interrupt / interrupt_if should narrow their scope to the current APL (at some point, anyway).
        if modifiers.interrupt_global and modifiers.interrupt_global() then
            return true
        end

        local act = state.this_action
        state.this_action = channel

        -- We are concerned with chain and early_chain_if.
        if modifiers.interrupt_if and modifiers.interrupt_if() then
            local val = state.cooldown.global_cooldown.up and ( modifiers.interrupt_immediate() or ( remains < tick_time or ( ( remains - state.delay ) / tick_time ) % 1 <= 0.5 ) )
            state.this_action = act
            return val
        end

        if modifiers.interrupt and modifiers.interrupt() then
            local val = state.cooldown.global_cooldown.up and ( remains < tick_time or ( ( remains - state.delay ) / tick_time ) % 1 <= 0.5 )
            state.this_action = act
            return val
        end

        state.this_action = act
    end

    return true
end


do
    local knownCache = {}
    local reasonCache = {}

    function Hekili:IsSpellKnown( spell )
        if knownCache[ spell ] ~= nil then return knownCache[ spell ], reasonCache[ spell ] end
        knownCache[ spell ], reasonCache[ spell ] = state:IsKnown( spell )
        return knownCache[ spell ], reasonCache[ spell ]
    end


    local disabledCache = {}

    function Hekili:IsSpellEnabled( spell )
        if disabledCache[ spell ] ~= nil then return disabledCache[ spell ] end
        disabledCache[ spell ] = not state:IsDisabled( spell )
        return disabledCache[ spell ]
    end


    function Hekili:ResetSpellCaches()
        twipe( knownCache )
        twipe( reasonCache )
        twipe( disabledCache )
    end
end


local waitBlock = {}
local listDepth = 0

function Hekili:GetPredictionFromAPL( dispName, packName, listName, slot, action, wait, depth, caller )

    local display = self.DB.profile.displays[ dispName ]

    local specID = state.spec.id
    local spec = rawget( self.DB.profile.specs, specID )
    local module = class.specs[ specID ]

    packName = packName or self.DB.profile.specs[ specID ].package

    local pack
    if ( packName == "UseItems" ) then pack = class.itemPack
    else pack = self.DB.profile.packs[ packName ] end

    local list = pack.lists[ listName ]

    local debug = self.ActiveDebug

    if debug then self:Debug( "Current recommendation was %s at +%.2fs.", action or "NO ACTION", wait or 60 ) end
    -- if debug then self:Debug( "ListCheck: Success(%s-%s)", packName, listName ) end

    local precombatFilter = listName == "precombat" and state.time > 0

    local rAction = action
    local rWait = wait or 60
    local rDepth = depth or 0

    local strict = false -- disabled for now.
    local force_channel = false
    local stop = false


    if self:IsListActive( packName, listName ) then
        local actID = 1

        while actID <= #list do
            -- if not state.channel or rWait >= state.channel_remains then
            -- Watch this section, may impact usage of off-GCD abilities.
            if rWait <= state.cooldown.global_cooldown.remains and not state.spec.canCastWhileCasting then
                if debug then self:Debug( "The recommended action (%s) would be ready before the next GCD (%.2f < %.2f); exiting list (%s).", rAction, rWait, state.cooldown.global_cooldown.remains, listName ) end
                break

            elseif rWait <= 0.2 then
                if debug then self:Debug( "The recommended action (%s) is ready in less than 0.2s; exiting list (%s).", rAction, listName ) end
                break

            elseif stop then
                if debug then self:Debug( "The action list reached a stopping point; exiting list (%s).", listName ) end
                break

            end
            -- end

            if self:IsActionActive( packName, listName, actID ) then
                -- Check for commands before checking actual actions.
                local entry = list[ actID ]

                local action = entry.action

                state.this_action = action
                state.delay = nil

                local ability = class.abilities[ action ]

                if state.whitelist and not state.whitelist[ action ] and ( ability.id < -99 or ability.id > 0 ) then
                    -- if debug then self:Debug( "[---] %s ( %s - %d) not castable while casting a spell; skipping...", action, listName, actID ) end

                else
                    local entryReplaced = false
                    
                    if action == "heart_essence" and class.essence_unscripted and class.active_essence then
                        action = class.active_essence
                        ability = class.abilities[ action ]
                        state.this_action = action
                        entryReplaced = true
                    end

                    rDepth = rDepth + 1
                    -- if debug then self:Debug( "[%03d] %s ( %s - %d )", rDepth, action, listName, actID ) end

                    local wait_time = 60
                    local clash = 0

                    local known, reason = self:IsSpellKnown( action )
                    local enabled = self:IsSpellEnabled( action )

                    if debug then
                        local d = ""
                        if entryReplaced then d = d .. format( "Substituting %s for Heart of Azeroth action; it is otherwise not included in the priority.\n", action ) end
                        
                        d = d .. format( "\n%-4s %s ( %s - %d )", rDepth .. ".", action, listName, actID )                        

                        if not known then d = d .. " - " .. ( reason or "ability unknown" )
                        elseif not enabled then d = d .. " - ability disabled." end
                        self:Debug( d )
                    end

                    -- if debug then self:Debug( "%s is %sknown and %senabled.", action, known and "" or "NOT ", enabled and "" or "NOT " ) end

                    if ability and known and enabled then
                        local scriptID = packName .. ":" .. listName .. ":" .. actID
                        state.scriptID = scriptID

                        local script = scripts:GetScript( scriptID )

                        wait_time = state:TimeToReady()
                        clash = state.ClashOffset()

                        state.delay = wait_time

                        if script.Error then
                            if debug then self:Debug( "The conditions for this entry contain an error.  Skipping.\n" ) end
                        elseif wait_time > state.delayMax then
                            if debug then self:Debug( "The action is not ready ( %.2f ) before our maximum delay window ( %.2f ) for this query.\n", wait_time, state.delayMax ) end
                        elseif ( rWait - state.ClashOffset( rAction ) ) - ( wait_time - clash ) <= 0.05 then
                            if debug then self:Debug( "The action is not ready in time ( %.2f vs. %.2f ) [ Clash: %.2f vs. %.2f ] - padded by 0.05s.\n", wait_time, rWait, clash, state.ClashOffset( rAction ) ) end
                        else
                            if state.channeling then
                                if debug then self:Debug( "NOTE:  We are channeling ( %s ) until %.2f.", state.player.channelSpell, state.player.channelEnd - state.query_time ) end
                            end

                            -- APL checks.
                            if precombatFilter and not ability.essential then
                                if debug then self:Debug( "We are already in-combat and this pre-combat action is not essential.  Skipping." ) end
                            else
                                if action == 'call_action_list' or action == 'run_action_list' or action == 'use_items' then
                                    -- We handle these here to avoid early forking between starkly different APLs.
                                    local aScriptPass = true
                                    local ts = not strict and entry.strict ~= 1 and scripts:IsTimeSensitive( scriptID )

                                    if not entry.criteria or entry.criteria == "" then
                                        if debug then self:Debug( "There is no criteria for %s.", action == 'use_items' and "Use Items" or "this action list." ) end
                                        -- aScriptPass = ts or self:CheckStack()
                                    else
                                        aScriptPass = ts or scripts:CheckScript( scriptID ) -- and self:CheckStack() -- we'll check the stack with the list's entries.

                                        if debug then 
                                            self:Debug( "%sCriteria %s at +%.2f - %s", ts and "Time-sensitive " or "", ts and "deferred" or ( aScriptPass and "PASS" or "FAIL" ), state.offset, scripts:GetConditionsAndValues( scriptID ) )
                                        end

                                        -- aScriptPass = ts or aScriptPass
                                    end

                                    if aScriptPass then
                                        if action == "use_items" then
                                            self:AddToStack( scriptID, "items", caller )
                                            rAction, rWait, rDepth = self:GetPredictionFromAPL( dispName, "UseItems", "items", slot, rAction, rWait, rDepth, scriptID )
                                            if debug then self:Debug( "Returned from Use Items; current recommendation is %s (+%.2f).", rAction or "NO ACTION", rWait ) end
                                            self:PopStack()
                                        else
                                            local name = state.args.list_name

                                            if InUse[ name ] then
                                                if debug then self:Debug( "Action list (%s) was found, but would cause a loop.", name ) end

                                            elseif name and pack.lists[ name ] then
                                                if debug then self:Debug( "Action list (%s) was found.", name ) end
                                                self:AddToStack( scriptID, name, caller, action == "run_action_list" )

                                                rAction, rWait, rDepth = self:GetPredictionFromAPL( dispName, packName, name, slot, rAction, rWait, rDepth, scriptID )
                                                if debug then self:Debug( "Returned from list (%s), current recommendation is %s (+%.2f).", name, rAction or "NO ACTION", rWait ) end

                                                self:PopStack()

                                                -- REVISIT THIS:  IF A RUN_ACTION_LIST CALLER IS NOT TIME SENSITIVE, DON'T BOTHER LOOPING THROUGH IT IF ITS CONDITIONS DON'T PASS.
                                                -- if action == 'run_action_list' and not ts then
                                                --    if debug then self:Debug( "This entry was not time-sensitive; exiting loop." ) end
                                                --    break
                                                -- end

                                            else
                                                if debug then self:Debug( "Action list (%s) not found.  Skipping.", name or "no name" ) end

                                            end
                                        end
                                    end

                                elseif action == 'variable' then
                                    local name = state.args.var_name

                                    if name ~= nil then
                                        state:RegisterVariable( name, scriptID, Stack, Block )
                                        if debug then self:Debug( " - variable.%s will check this script entry ( %s ).", name, scriptID ) end
                                    else
                                        if debug then self:Debug( " - variable name not provided, skipping." ) end
                                    end

                                else
                                    -- Target Cycling.
                                    -- We have to determine *here* whether the ability would be used on the current target or a different target.
                                    if state.args.cycle_targets == 1 and state.settings.cycle and state.spell_targets[ action ] > 1 then
                                        state.SetupCycle( ability )
                                    else
                                        state.ClearCycle()
                                    end

                                    local usable, why = state:IsUsable()
                                    if debug then
                                        if usable then
                                            self:Debug( "The action (%s) is usable at (%.2f + %.2f) with cost of %d.", action, state.offset, state.delay, state.action[ action ].cost or 0 )
                                        else
                                            self:Debug( "The action (%s) is unusable at (%.2f + %.2f) because %s.", action, state.offset, state.delay, why or "IsUsable returned false" )
                                        end
                                    end

                                    if usable then
                                        local waitValue = max( 0, rWait - state:ClashOffset( rAction ) )
                                        local readyFirst = state.delay - clash < waitValue

                                        if debug then self:Debug( " - the action is %sready before the current recommendation (at +%.2f vs. +%.2f).", readyFirst and "" or "NOT ", state.delay, waitValue ) end

                                        if readyFirst then
                                            local hasResources = true

        
                                            if hasResources then
                                                local aScriptPass = self:CheckStack()
                                                local channelPass = not state.channeling or self:CheckChannel( action, rWait )

                                                if not aScriptPass then
                                                    if debug then self:Debug( " - this entry would not be reached at the current time via the current action list path (%.2f).", state.delay ) end

                                                else
                                                    if not entry.criteria or entry.criteria == '' then 
                                                        if debug then
                                                            self:Debug( " - this entry has no criteria to test." ) 
                                                            if not channelPass then self:Debug( "   - however, criteria not met to break current channeled spell." )  end
                                                        end
                                                    else 
                                                        aScriptPass = scripts:CheckScript( scriptID )

                                                        if debug then
                                                            self:Debug( " - this entry's criteria %s: %s", aScriptPass and "PASSES" or "FAILS", scripts:GetConditionsAndValues( scriptID ) )
                                                            if not channelPass then self:Debug( "   - however, criteria not met to break current channeled spell." )  end
                                                        end
                                                    end
                                                    aScriptPass = aScriptPass and channelPass

                                                end

                                                -- NEW:  If the ability's conditions didn't pass, but the ability can report on times when it should recheck, let's try that now.                                        
                                                if not aScriptPass then
                                                    state.recheck( action, script, Stack )

                                                    if #state.recheckTimes == 0 then
                                                        if debug then self:Debug( "There were no recheck events to check." ) end
                                                    else
                                                        local base_delay = state.delay

                                                        if debug then self:Debug( "There are " .. #state.recheckTimes .. " recheck events." ) end

                                                        local first_rechannel = 0

                                                        for i, step in pairs( state.recheckTimes ) do
                                                            local new_wait = base_delay + step

                                                            if new_wait >= 10 then
                                                                if debug then self:Debug( "Rechecking stopped at step #%d.  The recheck ( %.2f ) isn't ready within a reasonable time frame ( 10s ).", i, new_wait ) end
                                                                break
                                                            elseif ( action ~= state.channel ) and waitValue <= base_delay + step + 0.05 then
                                                                if debug then self:Debug( "Rechecking stopped at step #%d.  The previously chosen ability is ready before this recheck would occur ( %.2f <= %.2f + 0.05 ).", i, waitValue, new_wait ) end
                                                                break
                                                            end

                                                            state.delay = base_delay + step

                                                            local usable, why = state:IsUsable()
                                                            if debug then
                                                                if not usable then
                                                                    self:Debug( "The action (%s) is no longer usable at (%.2f + %.2f) because %s.", action, state.offset, state.delay, why or "IsUsable returned false" )
                                                                    state.delay = base_delay
                                                                    break
                                                                end
                                                            end

                                                            if self:CheckStack() then
                                                                aScriptPass = scripts:CheckScript( scriptID )
                                                                channelPass = self:CheckChannel( action, rWait )

                                                                if debug then
                                                                    self:Debug( "Recheck #%d ( +%.2f ) %s: %s", i, state.delay, aScriptPass and "MET" or "NOT MET", scripts:GetConditionsAndValues( scriptID ) )
                                                                    if not channelPass then self:Debug( " - however, criteria not met to break current channeled spell." ) end
                                                                end

                                                                aScriptPass = aScriptPass and channelPass
                                                            else
                                                                if debug then self:Debug( "Unable to recheck #%d at %.2f, as APL conditions would not pass.", i, state.delay ) end
                                                            end

                                                            if aScriptPass then
                                                                if first_rechannel == 0 and state.channel and action == state.channel then
                                                                    first_rechannel = state.delay
                                                                    if debug then self:Debug( "This is the currently channeled spell; it would be rechanneled at this time, will check end of channel.  " .. state.channel_remains ) end
                                                                elseif first_rechannel > 0 and ( not state.channel or state.channel_remains < 0.05 ) then
                                                                    if debug then self:Debug( "Appears that the ability would be cast again at the end of the channel, stepping back to first rechannel point.  " .. state.channel_remains ) end
                                                                    state.delay = first_rechannel
                                                                    waitValue = first_rechannel
                                                                    break
                                                                else break end
                                                            else state.delay = base_delay end
                                                        end
                                                    end
                                                end

                                                -- Need to revisit this, make sure that lower priority abilities are only tested after the channel is over.
                                                if action == state.channel then
                                                    if ( state.now + state.offset + rWait <= state.player.channelEnd + 0.05 ) then 
                                                        -- If a higher priority ability is selected, we should stop here.
                                                        if debug then self:Debug( "Our prior recommendation ( " .. rAction .. " ) can break or finish our channel; stopping." ) end
                                                        aScriptPass = false
                                                        stop = true
                                                    elseif aScriptPass and ( state.now + state.offset + waitValue <= state.player.channelEnd + 0.05 ) then
                                                        if debug then self:Debug( "Rechanneling " .. state.channel .. " criteria passed; stop here." ) end
                                                        stop = true
                                                    end
                                                end

                                                if aScriptPass then
                                                    if action == 'potion' then
                                                        local potionName = state.args.potion or state.args.name
                                                        if not potionName or potionName == "default" then potionName = class.potion end
                                                        local potion = class.potions[ potionName ]

                                                        if debug then
                                                            if not potionName then self:Debug( "No potion name set." )
                                                            elseif not potion then self:Debug( "Unable to find potion '" .. potionName .. "'." ) end
                                                        end

                                                        if potion then
                                                            slot.scriptType = 'simc'
                                                            slot.script = scriptID
                                                            slot.hook = caller

                                                            slot.display = dispName
                                                            slot.pack = packName
                                                            slot.list = listName
                                                            slot.listName = listName
                                                            slot.action = actID
                                                            slot.actionName = state.this_action
                                                            slot.actionID = -1 * potion.item

                                                            slot.texture = select( 10, GetItemInfo( potion.item ) )
                                                            slot.caption = ability.caption or entry.caption
                                                            slot.item = potion.item

                                                            slot.wait = state.delay
                                                            slot.resource = state.GetResourceType( rAction )

                                                            -- slot.indicator = ( entry.Indicator and entry.Indicator ~= 'none' ) and entry.Indicator

                                                            rAction = state.this_action
                                                            rWait = state.delay

                                                            state.selectionTime = state.delay
                                                            state.selectedAction = rAction
                                                        end

                                                    elseif action == 'wait' then
                                                        -- local args = scripts:GetModifiers()
                                                        -- local args = ns.getModifiers( listID, actID )
                                                        local sec = state.args.sec or 0.5

                                                        if sec > 0 then
                                                            if waitBlock[ scriptID ] then
                                                                if debug then self:Debug( "Criteria for Wait action (" .. scriptID .. ") were met, but would be a loop.  Skipping." ) end
                                                            else
                                                                if debug then self:Debug( "Criteria for Wait action were met, advancing by %.2f and restarting this list.", sec ) end
                                                                -- NOTE, WE NEED TO TELL OUR INCREMENT FUNCTION ABOUT THIS...
                                                                waitBlock[ scriptID ] = true
                                                                state.advance( sec )
                                                                actID = 0
                                                            end
                                                        end

                                                    elseif action == 'pool_resource' then
                                                        if state.args.for_next == 1 and false then
                                                            -- Pooling for the next entry in the list.
                                                            local next_entry  = list[ actID + 1 ]
                                                            local next_action = next_entry and next_action
                                                            local next_id     = next_action and class.abilities[ next_action ] and class.abilities[ next_action ].id

                                                            local extra_amt   = state.args.extra_amount or 0

                                                            local next_known  = next_action and state:IsKnown( next_action )
                                                            local next_usable, next_why = next_action and state:IsUsable( next_action )
                                                            local next_cost   = next_action and state.action[ next_action ].cost or 0
                                                            local next_res    = next_action and state.GetResourceType( next_action ) or class.primaryResource                                                    

                                                            if not next_entry then
                                                                if debug then self:Debug( "Attempted to Pool Resources for non-existent next entry in the APL.  Skipping." ) end
                                                            elseif not next_action or not next_id or next_id < 0 then
                                                                if debug then self:Debug( "Attempted to Pool Resources for invalid next entry in the APL.  Skipping." ) end
                                                            elseif not next_known then
                                                                if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but the next entry is not known.  Skipping.", next_action ) end
                                                            elseif not next_usable then
                                                                if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but the next entry is not usable because %s.  Skipping.", next_action, next_why ) end
                                                            else
                                                                local next_wait = max( state:TimeToReady( next_action, true ), state[ next_res ][ "time_to_" .. ( next_cost + extra_amt ) ] )

                                                                if next_wait <= 0 then
                                                                    if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but there is no need to wait.  Skipping.", next_action ) end
                                                                elseif next_wait >= rWait then
                                                                    if debug then self:Debug( "The currently chosen action ( %s ) is ready at or before the next action ( %.2fs <= %.2fs ).  Skipping.", ( rAction or "???" ), rWait, next_wait ) end
                                                                elseif state.delayMax and next_wait >= state.delayMax then
                                                                    if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but we would exceed our time ceiling in %.2fs.  Skipping.", next_action, next_wait ) end
                                                                elseif next_wait >= 10 then
                                                                    if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but we'd have to wait much too long ( %.2f ).  Skipping.", next_action, next_wait ) end
                                                                else
                                                                    -- Pad the wait value slightly, to make sure the resource is actually generated.
                                                                    next_wait = next_wait + 0.01
                                                                    state.offset = state.offset + next_wait

                                                                    aScriptPass = not next_entry.criteria or next_entry.criteria == '' or scripts:CheckScript( packName .. ':' .. listName .. ':' .. ( actID + 1 ) )

                                                                    if not aScriptPass then
                                                                        if debug then self:Debug( "Attempted to Pool Resources for Next Entry ( %s ), but its conditions would not be met.  Skipping.", next_action ) end
                                                                        state.offset = state.offset - next_wait
                                                                    else
                                                                        if debug then self:Debug( "Pooling Resources for Next Entry ( %s ), delaying by %.2f ( extra %d ).", next_action, next_wait, extra_amt ) end
                                                                        state.offset = state.offset - next_wait
                                                                        state.advance( next_wait )
                                                                    end
                                                                end
                                                            end

                                                        else
                                                            -- Pooling for a Wait Value.
                                                            -- NYI.
                                                            -- if debug then self:Debug( "Pooling for a specified period of time is not supported yet.  Skipping." ) end
                                                            if debug then self:Debug( "pool_resource is disabled as pooling is automatically accounted for by the forecasting engine." ) end
                                                        end

                                                        -- if entry.PoolForNext or state.args.for_next == 1 then
                                                        --    if debug then self:Debug( "Pool Resource is not used in the Predictive Engine; ignored." ) end
                                                        -- end

                                                    else
                                                        slot.scriptType = 'simc'
                                                        slot.script = scriptID
                                                        slot.hook = caller

                                                        slot.display = dispName
                                                        slot.pack = packName
                                                        slot.list = listName
                                                        slot.listName = listName
                                                        slot.action = actID
                                                        slot.actionName = state.this_action
                                                        slot.actionID = ability.id

                                                        slot.caption = ability.caption or entry.caption
                                                        slot.texture = ability.texture
                                                        slot.indicator = ability.indicator

                                                        slot.wait = state.delay

                                                        slot.resource = state.GetResourceType( rAction )

                                                        rAction = state.this_action
                                                        rWait = state.delay

                                                        state.selectionTime = state.delay
                                                        state.selectedAction = rAction

                                                        if debug then
                                                            self:Debug( "Action chosen:  %s at %.2f!", rAction, state.delay )
                                                        end

                                                        if state.IsCycling() then
                                                            slot.indicator = 'cycle'
                                                        elseif module and module.cycle then
                                                            slot.indicator = module.cycle()
                                                        end
                                                    end
                                                end

                                                state.ClearCycle()
                                            end
                                        end
                                    end

                                    if rWait == 0 or force_channel then break end

                                end
                            end
                        end
                    end
                end
            else
                if debug then self:Debug( "\nEntry #%d in list ( %s ) is not set or not enabled.  Skipping.", actID, listName ) end
            end

            actID = actID + 1

        end

    else
        if debug then self:Debug( "ListActive: N (%s-%s)", packName, listName ) end
    end

    local scriptID = listStack[ listName ]
    listStack[ listName ] = nil

    if listCache[ scriptID ] then twipe( listCache[ scriptID ] ) end
    if listValue[ scriptID ] then twipe( listValue[ scriptID ] ) end

    return rAction, rWait, rDepth
end


function Hekili:GetNextPrediction( dispName, packName, slot )

    local debug = self.ActiveDebug

    -- This is the entry point for the prediction engine.
    -- Any cache-wiping should happen here.
    twipe( Stack )
    twipe( Block )
    twipe( InUse )

    twipe( listStack )    
    twipe( waitBlock )

    for k, v in pairs( listCache ) do tinsert( lcPool, v ); twipe( v ); listCache[ k ] = nil end
    for k, v in pairs( listValue ) do tinsert( lvPool, v ); twipe( v ); listValue[ k ] = nil end

    self:ResetSpellCaches()
    state:ResetVariables()
    scripts:ResetCache()

    local display = rawget( self.DB.profile.displays, dispName )
    local pack = rawget( self.DB.profile.packs, packName )

    local action, wait, depth = nil, 60, 0

    state.this_action = nil

    state.selectionTime = 60
    state.selectedAction = nil

    if state.buff.casting.up and state.spec.canCastWhileCasting then
        state:SetWhitelist( state.spec.castableWhileCasting )
    else
        state:SetWhitelist( nil )
    end

    if pack.lists.precombat then
        local list = pack.lists.precombat
        local listName = "precombat"

        if debug then self:Debug( 1, "\nProcessing precombat action list [ %s - %s ].", packName, listName ); self:Debug( 2, "" ) end        
        action, wait, depth = self:GetPredictionFromAPL( dispName, packName, "precombat", slot, action, wait, depth )
        if debug then self:Debug( 1, "\nCompleted precombat action list [ %s - %s ].", packName, listName ) end
    else
        if debug then
            if state.time > 0 then
                self:Debug( "Precombat APL not processed because combat time is %.2f.", state.time )
            end
        end
    end

    if pack.lists.default and wait > 0 then
        local list = pack.lists.default
        local listName = "default"

        if debug then self:Debug( 1, "\nProcessing default action list [ %s - %s ].", packName, listName ); self:Debug( 2, "" ) end
        action, wait, depth = self:GetPredictionFromAPL( dispName, packName, "default", slot, action, wait, depth )
        if debug then self:Debug( 1, "\nCompleted default action list [ %s - %s ].", packName, listName ) end
    end

    if debug then self:Debug( "Recommendation is %s at %.2f + %.2f.", action or "NO ACTION", state.offset, wait ) end

    return action, wait, depth
end


local pvpZones = {
    arena = true,
    pvp = true
}


function Hekili:GetDisplayByName( name )
    return rawget( self.DB.profile.displays, name ) and name or nil
end


function Hekili:ProcessHooks( dispName, packName )

    if self.Pause then return end
    if not self.PLAYER_ENTERING_WORLD then return end -- In 8.2.5, we can start resetting before our character information is loaded apparently.

    dispName = dispName or "Primary"
    local display = rawget( self.DB.profile.displays, dispName )

    local specID = state.spec.id
    if not specID then return end

    local spec = rawget( self.DB.profile.specs, specID )
    if not spec then return end

    local UI = ns.UI.Displays[ dispName ]
    local Queue = UI.Recommendations

    if Queue then
        for k, v in pairs( Queue ) do
            for l, w in pairs( v ) do
                if type( Queue[ k ][ l ] ) ~= 'table' then
                    Queue[ k ][ l ] = nil
                end
            end
        end
    end

    if dispName == "AOE" and self:GetToggleState( "mode" ) == "reactive" then
        if ns.getNumberTargets() < ( spec and spec.aoe or 3 ) then
            UI.RecommendationsStr = nil
            UI.NewRecommendations = true
            return
        end
    end

    local checkstr = nil

    local packName = packName or spec.package
    local pack = rawget( self.DB.profile.packs, packName )

    if not pack then
        UI.RecommendationsStr = nil
        UI.NewRecommendations = true 
        return 
    end

    state.system.specID   = specID
    state.system.specInfo = spec
    state.system.packName = packName
    state.system.packInfo = pack
    state.system.display  = dispName
    state.system.dispInfo = display

    local debug = self.ActiveDebug

    if debug then
        self:SetupDebug( dispName )
        -- self:Debug( "*** START OF NEW DISPLAY: %s ***", dispName ) 
    end

    state.reset( dispName )

    local numRecs = display.numIcons or 4

    if display.flash.enabled and display.flash.suppress then
        numRecs = 1
    end

    local actualStartTime = debugprofilestop()
    local maxTime

    if state.settings.throttleTime then
        maxTime = state.settings.maxTime or 50
    end

    for i = 1, numRecs do
        if i > 1 and actualStartTime then
            local usedTime = debugprofilestop() - actualStartTime

            if maxTime and usedTime > maxTime then
                if debug then self:Debug( -100, "Addon used %.2fms CPU time (of %.2fms softcap) before recommendation #%d; stopping early.", usedTime, maxTime, i-1 ) end
                break
            end
            
            if debug then self:Debug( "Used %.2fms of CPU on %d prediction(s).", usedTime, i-1 ) end
        end

        local chosen_action
        local chosen_depth = 0

        Queue[ i ] = Queue[ i ] or {}        
        local slot = Queue[ i ]
        slot.index = i
        state.index = i

        local attempts = 0
        local iterated = false

        if debug then self:Debug( "\nRECOMMENDATION #%d ( Offset: %.2f, GCD: %.2f, %s: %.2f ).\n", i, state.offset, state.cooldown.global_cooldown.remains, ( state.buff.casting.v3 and "Channeling" or "Casting" ), state.buff.casting.remains ) end

        --[[ if debug then
            for k in pairs( class.resources ) do
                self:Debug( "[ ** ] %s, %d / %d", k, state[ k ].current, state[ k ].max )
            end
            if state.channeling then
                self:Debug( "[ ** ] Currently channeling ( %s ) until ( %.2f ).", state.player.channelSpell, state.player.channelEnd - state.query_time )
            end
        end ]]

        local action, wait, depth

        state.delay = 0
        state.delayMin = 0
        state.delayMax = 0

        local hadProj = false

        local events = state:GetQueue()
        local event = events[ 1 ]
        local n = 1


        while( event ) do
            local eStart
            
            if debug then
                eStart = debugprofilestop()
                
                local resources

                for k in orderedPairs( class.resources ) do
                    resources = ( resources and ( resources .. ", " ) or "" ) .. string.format( "%s[ %.2f / %.2f ]", k, state[ k ].current, state[ k ].max )
                end
                self:Debug( 1, "Resources: %s\n", resources )

                if state.channeling then
                    self:Debug( 1, "Currently channeling ( %s ) until ( %.2f ).\n", state.player.channelSpell, state.player.channelEnd - state.query_time )
                end
            end

            local t = event.time - state.now - state.offset

            local casting, shouldCheck = ( state:IsCasting() or state:IsChanneling() ), true

            if casting then
                if not state.spec.canCastWhileCasting then
                    if debug then self:Debug( 1, "Finishing queued event #%d ( %s of %s ) due at %.2f as player is casting and cannot cast.\n", n, event.type, event.action, t ) end
                    if t > 0 then state.advance( t ) end
                    event = events[ 1 ]
                    n = n + 1
                    shouldCheck = false
                else
                    shouldCheck = false

                    for spell in pairs( state.spec.castableWhileCasting ) do
                        if state:IsKnown( spell ) and state:IsUsable( spell ) and state:TimeToReady( spell ) <= t then
                            shouldCheck = true
                        end
                    end

                    if not shouldCheck then
                        if debug then self:Debug( 1, "Finishing queued event #%d ( %s of %s ) due at %.2f as player is casting and castable spells are not ready.\n", n, event.type, event.action, t ) end
                        state.advance( t )
                        event = events[ 1 ]
                        n = n + 1
                    end
                end
            end

            if shouldCheck then
                state:SetConstraint( 0, t - 0.01 )

                hadProj = true

                if debug then self:Debug( 1, "Queued event #%d (%s %s) due at %.2f; checking pre-event recommendations.\n", n, event.action, event.type, t ) end

                if state:IsCasting() then
                    state:ApplyCastingAuraFromQueue()
                    if debug then self:Debug( 2, "Player is casting for %.2f seconds.  Only abilities that can be cast while casting will be tested.", state:QueuedCastRemains() ) end
                else
                    state.removeBuff( "casting" )
                end

                action, wait, depth = self:GetNextPrediction( dispName, packName, slot )

                if not action then
                    if debug then self:Debug( "Time spent on event #%d PREADVANCE: %.2fms...", n, debugprofilestop() - eStart ) end
                    if debug then self:Debug( 1, "No recommendation found before event #%d (%s %s) at %.2f; triggering event and continuing ( %.2f ).\n", n, event.action, event.type, t, state.offset + state.delay ) end
                    
                    state.advance( t )
                    if debug then self:Debug( "Time spent on event #%d POSTADVANCE: %.2fms...", n, debugprofilestop() - eStart ) end

                    event = events[ 1 ]
                    n = n + 1
                else
                    break
                end
            end

            if n > 10 then
                if debug then Hekili:Debug( "WARNING:  Attempted to process 10+ events; breaking to avoid CPU wastage." ) end
                break
            end

            if debug then self:Debug( "Time spent on event #%d: %.2fms...", n - 1, debugprofilestop() - eStart ) end
        end

        if not action then
            if class.file == "DEATHKNIGHT" then
                state:SetConstraint( 0, max( 0.01 + state.rune.cooldown * 2, 15 ) )
            else
                state:SetConstraint( 0, 15 )
            end

            if hadProj and debug then self:Debug( "[ ** ] No recommendation before queued event(s), checking recommendations after %.2f.", state.offset ) end

            if debug then
                local resources

                for k in orderedPairs( class.resources ) do
                    resources = ( resources and ( resources .. ", " ) or "" ) .. string.format( "%s[ %.2f / %.2f ]", k, state[ k ].current, state[ k ].max )
                end
                self:Debug( 1, "Resources: %s", resources )
                
                if state.channeling then
                    self:Debug( " - Channeling ( %s ) until ( %.2f ).", state.player.channelSpell, state.player.channelEnd - state.query_time )
                end
            end    

            action, wait, depth = self:GetNextPrediction( dispName, packName, slot )
        end

        local gcd_remains = state.cooldown.global_cooldown.remains
        state.delay = wait

        -- if debug then self:Debug( "Prediction engine would recommend %s at +%.2fs (%.2fs).\n", action or "NO ACTION", wait or 60, state.offset + state.delay ) end
        if debug then self:Debug( "Recommendation #%d is %s at %.2fs (%.2fs).", i, action or "NO ACTION", wait or 60, state.offset + state.delay ) end

        if not debug and not Hekili.Config and not Hekili.HasSnapped and ( dispName == "Primary" or dispName == "AOE" ) and action == nil and Hekili.DB.profile.autoSnapshot then
            Hekili:MakeSnapshot( dispName )
            Hekili.HasSnapped = true
            return
        end

        if action then
            if debug then scripts:ImplantDebugData( slot ) end

            slot.time = state.offset + wait
            slot.exact_time = state.now + state.offset + wait
            slot.delay = wait
            slot.since = i > 1 and slot.time - Queue[ i - 1 ].time or 0
            slot.resources = slot.resources or {}
            slot.depth = chosen_depth

            checkstr = checkstr and ( checkstr .. ':' .. action ) or action

            slot.keybind = self:GetBindingForAction( action, display )
            slot.resource_type = state.GetResourceType( action )

            for k,v in pairs( class.resources ) do
                slot.resources[ k ] = state[ k ].current 
            end                            

            if i < display.numIcons then
                -- Advance through the wait time.
                state.this_action = action

                if state.delay > 0 then state.advance( state.delay ) end

                state.cycle = slot.indicator == 'cycle'

                local ability = class.abilities[ action ]
                local cast = ability.cast

                if not state.spec.canCastWhileCasting then state.stopChanneling() end

                if ability.gcd ~= 'off' and state.cooldown.global_cooldown.remains == 0 then
                    state.setCooldown( 'global_cooldown', state.gcd.execute )
                end

                state.stopChanneling()

                if ability.charges and ability.charges > 1 and ability.recharge > 0 then
                    state.spendCharges( action, 1 )
                
                elseif action ~= 'global_cooldown' and ability.cooldown > 0 then
                    state.setCooldown( action, ability.cooldown )
                
                end

                if ability.cast > 0 and not ability.channeled then
                    if debug then Hekili:Debug( "Queueing %s cast finish at %.2f.", action, state.query_time + cast ) end
                    state:QueueEvent( action, state.query_time, state.query_time + cast, "CAST_FINISH" )

                else
                    ns.spendResources( action )

                    state:RunHandler( action )

                    if ability.channeled then
                        if debug then Hekili:Debug( "Queueing %s channel finish at %.2f.", action, state.query_time + cast ) end
                        state:QueueEvent( action, state.query_time, state.query_time + cast, "CHANNEL_FINISH" )
    
                        if ability.tick and ability.tick_time then
                            local ticks = floor( cast / ability.tick_time )
    
                            for i = 1, ticks do
                                if debug then Hekili:Debug( "Queueing %s channel tick (%d of %d) at %.2f.", action, i, ticks, state.query_time + ( i * ability.tick_time ) ) end
                                state:QueueEvent( action, state.query_time, state.query_time + ( i * ability.tick_time ), "CHANNEL_TICK" )
                            end
                        end
                    end
                end

                -- Projectile spells have two handlers, effectively.  An onCast handler, and then an onImpact handler.
                if ability.isProjectile then
                    state:QueueEvent( action, state.query_time + cast, nil, "PROJECTILE_IMPACT", state.target.GUID )
                    -- state:QueueEvent( action, "projectile", true )
                end

                if ability.item and not ability.essence then
                    state.putTrinketsOnCD( ability.cooldown / 6 )
                end
            end

        else
            for n = i, numRecs do
                action = action or ''
                checkstr = checkstr and ( checkstr .. ':' .. action ) or action
                slot[n] = nil
            end
            break
        end

    end

    if debug then
        self:Debug( "Time spent generating recommendations:  %.2fms",  debugprofilestop() - actualStartTime )
    elseif InCombatLockdown() then
        -- We don't track debug/snapshot recommendations because the additional debug info ~40% more CPU intensive.
        -- We don't track out of combat because who cares?
        UI:UpdatePerformance( GetTime(), debugprofilestop() - actualStartTime )
    end

    UI.NewRecommendations = true
    UI.RecommendationsStr = checkstr
    Hekili.freshFrame     = false
end

Hekili:ProfileCPU( "ProcessHooks", Hekili.ProcessHooks )


function Hekili_GetRecommendedAbility( display, entry )
    entry = entry or 1

    if not rawget( Hekili.DB.profile.displays, display ) then
        return nil, "Display not found."
    end

    if not ns.queue[ display ] then
        return nil, "No queue for that display."
    end

    local slot = ns.queue[ display ][ entry ]

    if not slot or not slot.actionID then
        return nil, "No entry #" .. entry .. " for that display."
    end

    return slot.actionID
end


function Hekili:DumpProfileInfo()
    local output = ""

    for k, v in orderedPairs( ns.cpuProfile ) do
        local usage, calls = GetFunctionCPUUsage( v, true )

        calls = self.ECount[ k ] or calls

        if usage then
            -- usage = usage / 1000
            output = format(    "%s\n" ..
                                "%d %s %.3f %.3f", output, calls, k, usage, usage / ( calls == 0 and 1 or calls ) )
        else
            output = output(    "%s\nNo information for function `%s'.", output, k )
        end
    end

    print( output )
end


function Hekili:DumpFrameInfo()
    local output

    local cpu = GetAddOnCPUUsage( "Hekili" )

    output = format( "Hekili %.3f", cpu )

    for k, v in orderedPairs( ns.frameProfile ) do
        local usage, calls = GetFrameCPUUsage( v, true )

        -- calls = self.ECount[ k ] or calls

        if usage then
            -- usage = usage / 1000
            output = format(    "%s\n" ..
                                "%d %s %.3f %.3f", output, calls, k, usage, usage / ( calls == 0 and 1 or calls ) )
        else
            output = output(    "%s\nNo information for frame `%s'.", output, k )
        end
    end

    print( output )
end