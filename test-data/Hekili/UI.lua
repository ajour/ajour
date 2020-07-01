-- UI.lua
-- Dynamic UI Elements

local addon, ns = ...
local Hekili = _G[addon]

local class = Hekili.Class
local state = Hekili.State

local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID

-- Atlas/Textures
local AddTexString, GetTexString, AtlasToString, GetAtlasFile, GetAtlasCoords = ns.AddTexString, ns.GetTexString, ns.AtlasToString, ns.GetAtlasFile, ns.GetAtlasCoords

local frameStratas = ns.FrameStratas
local getInverseDirection = ns.getInverseDirection
local multiUnpack = ns.multiUnpack
local orderedPairs = ns.orderedPairs
local round = ns.round

local format, insert = string.format, table.insert

local HasVehicleActionBar, HasOverrideActionBar, IsInPetBattle, UnitHasVehicleUI, UnitOnTaxi = HasVehicleActionBar, HasOverrideActionBar, C_PetBattles.IsInBattle, UnitHasVehicleUI, UnitOnTaxi

local Masque, MasqueGroup
local _


function Hekili:GetScale()
    return PixelUtil.GetNearestPixelSize( 1, PixelUtil.GetPixelToUIUnitFactor(), 1 )
    --[[ local monitorIndex = (tonumber(GetCVar("gxMonitor")) or 0) + 1
    local resolutions = {GetScreenResolutions()}
    local resolution = resolutions[GetCurrentResolution()] or GetCVar("gxWindowedResolution")

    return (GetCVar("UseUIScale") == "1" and (GetScreenHeight() / resolution:match("%d+x(%d+)")) or 1) ]]
end


local movementData = {}

local function startScreenMovement(frame)
    _, _, _, movementData.origX, movementData.origY = frame:GetPoint()
    frame:StartMoving()
    _, _, _, movementData.fromX, movementData.fromY = frame:GetPoint()
    frame.Moving = true
end

local function stopScreenMovement(frame)
    local monitor = (tonumber(GetCVar("gxMonitor")) or 0) + 1
    local resolutions = {GetScreenResolutions()}
    local resolution = resolutions[GetCurrentResolution()] or GetCVar("gxWindowedResolution")
    local scrW, scrH = resolution:match("(%d+)x(%d+)")

    local scale, pScale = Hekili:GetScale(), UIParent:GetScale()

    scrW = scrW / ( scale * pScale )
    scrH = scrH / ( scale * pScale )

    local limitX = (scrW - frame:GetWidth() ) / 2
    local limitY = (scrH - frame:GetHeight()) / 2

    _, _, _, movementData.toX, movementData.toY = frame:GetPoint()
    frame:StopMovingOrSizing()
    frame.Moving = false
    frame:ClearAllPoints()
    frame:SetPoint( "CENTER", nil, "CENTER",
        max(-limitX, min(limitX, movementData.origX + (movementData.toX - movementData.fromX))),
        max(-limitY, min(limitY, movementData.origY + (movementData.toY - movementData.fromY))) )
    Hekili:SaveCoordinates()
end

local function Mover_OnMouseUp(self, btn)
    local obj = self.moveObj or self

    if (btn == "LeftButton" and obj.Moving) then
        stopScreenMovement(obj)
        Hekili:SaveCoordinates()
    elseif btn == "RightButton" then
        if obj:GetName() == "HekiliNotification" then
            LibStub( "AceConfigDialog-3.0" ):SelectGroup( "Hekili", "displays", "nPanel" )
            return
        elseif obj and obj.id then
            LibStub( "AceConfigDialog-3.0" ):SelectGroup( "Hekili", "displays", obj.id, obj.id )
            return
        else
            print( obj, obj:GetName(), obj.id )
        end
    end
end

local function Mover_OnMouseDown( self, btn )
    local obj = self.moveObj or self

    if Hekili.Config and btn == "LeftButton" and not obj.Moving then
        startScreenMovement(obj)
    end
end

local function Button_OnMouseUp( self, btn )
    local display = self.display
    local mover = _G[ "HekiliDisplay" .. display ]

    if (btn == "LeftButton" and mover.Moving) then
        stopScreenMovement(mover)

    elseif (btn == "RightButton") then
        if mover.Moving then
            stopScreenMovement(mover)
        end
        local mouseInteract = Hekili.Pause or Hekili.Config
        for i = 1, #ns.UI.Buttons do
            for j = 1, #ns.UI.Buttons[i] do
                ns.UI.Buttons[i][j]:EnableMouse(mouseInteract)
            end
        end
        ns.UI.Notification:EnableMouse( Hekili.Config )
        -- Hekili:SetOption( { "locked" }, true )
        GameTooltip:Hide()

    end

    Hekili:SaveCoordinates()
end

local function Button_OnMouseDown(self, btn)
    local display = self.display
    local mover = _G[ "HekiliDisplay" .. display ]

    if Hekili.Config and btn == "LeftButton" and not mover.Moving then
        startScreenMovement(mover)

    end
end


function ns.StartConfiguration( external )
    if Hekili.NewSpellInfo then Hekili:EmbedAbilityOptions(); Hekili:EmbedSpecOptions() end
    if Hekili.NewItemInfo  then Hekili:EmbedItemOptions()    end

    Hekili.Config = true

    local scaleFactor = Hekili:GetScale()
    local ccolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]

    -- Notification Panel
    ns.UI.Notification:EnableMouse( true )
    ns.UI.Notification:SetMovable( true )
    ns.UI.Notification.Mover = ns.UI.Notification.Mover or CreateFrame( "Frame", "HekiliNotificationMover", ns.UI.Notification )
    ns.UI.Notification.Mover:SetAllPoints(HekiliNotification)
    ns.UI.Notification.Mover:SetBackdrop( {
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    } )

    ns.UI.Notification.Mover:SetBackdropColor( 0, 0, 0, .8 )
    ns.UI.Notification.Mover:SetBackdropBorderColor( ccolor.r, ccolor.g, ccolor.b, 1 )
    ns.UI.Notification.Mover:Show()

    local f = ns.UI.Notification.Mover

    if not f.Header then
        f.Header = f:CreateFontString( "HekiliNotificationHeader", "OVERLAY", "GameFontNormal" )
        local path, size = f.Header:GetFont()
        f.Header:SetFont( path, size, "OUTLINE" )
    end
    f.Header:SetAllPoints( HekiliNotificationMover )
    f.Header:SetText( "Notifications" )
    f.Header:SetJustifyH( "CENTER" )
    f.Header:Show()

    HekiliNotification:SetScript( "OnMouseDown", Mover_OnMouseDown )
    HekiliNotification:SetScript( "OnMouseUp", Mover_OnMouseUp )
    HekiliNotification:SetScript( "OnEnter", function( self )
        local H = Hekili

        if not H.Pause and H.Config then
            GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" )
        
            GameTooltip:SetText( "Hekili: Notifications" )
            GameTooltip:AddLine( "Left-click and hold to move.", 1, 1, 1 )
            GameTooltip:AddLine( "Right-click to open Notification panel settings.", 1, 1, 1 )
            GameTooltip:Show()
        end
    end )
    HekiliNotification:SetScript( "OnLeave", function(self)
        GameTooltip:Hide()
    end )

    Hekili:ProfileFrame( "NotificationFrame", HekiliNotification )    

    for i, v in pairs( ns.UI.Displays ) do
        if v.Backdrop then
            v.Backdrop:Hide()
        end

        if v.Header then
            v.Header:Hide()
        end

        if ns.UI.Buttons[ i ][ 1 ] and Hekili.DB.profile.displays[ i ] then
            -- if not Hekili:IsDisplayActive( i ) then v:Show() end

            v:EnableMouse( true )
            v:SetMovable( true )

            v.Backdrop = v.Backdrop or CreateFrame( "Frame", v:GetName().. "_Backdrop", UIParent ) --, v )
            v.Backdrop:ClearAllPoints()
            
            local left, right, top, bottom = v:GetPerimeterButtons()
            if left and right and top and bottom then
                v.Backdrop:SetPoint( "LEFT", left, "LEFT", -2, 0 )
                v.Backdrop:SetPoint( "RIGHT", right, "RIGHT", 2, 0 )
                v.Backdrop:SetPoint( "TOP", top, "TOP", 0, 2 )
                v.Backdrop:SetPoint( "BOTTOM", bottom, "BOTTOM", 0, -2 )
            else
                v.Backdrop:SetWidth( v:GetWidth() + 2 )
                v.Backdrop:SetHeight( v:GetHeight() + 2 )
                v.Backdrop:SetPoint( "CENTER", v, "CENTER" )
            end

            v.Backdrop:SetFrameStrata( v:GetFrameStrata() )
            v.Backdrop:SetFrameLevel( v:GetFrameLevel() + 1 )

            v.Backdrop.moveObj = v
    
            v.Backdrop:SetBackdrop( {
                bgFile = "Interface/Buttons/WHITE8X8",
                edgeFile = "Interface/Buttons/WHITE8X8",
                tile = false,
                tileSize = 0,
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            } )

            local ccolor = RAID_CLASS_COLORS[ select(2, UnitClass("player")) ]

            if Hekili:IsDisplayActive( v.id, true ) then
                v.Backdrop:SetBackdropBorderColor( ccolor.r, ccolor.g, ccolor.b, 1 )
            else
                v.Backdrop:SetBackdropBorderColor( 0.5, 0.5, 0.5, 0.5 )
            end
            v.Backdrop:SetBackdropColor( 0, 0, 0, 0.8 )
            v.Backdrop:Show()

            v.Backdrop:SetScript( "OnMouseDown", Mover_OnMouseDown )
            v.Backdrop:SetScript( "OnMouseUp", Mover_OnMouseUp )
            v.Backdrop:SetScript( "OnEnter", function( self )
                local H = Hekili
        
                if not H.Pause and H.Config then
                    GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" )
        
                    GameTooltip:SetText( "Hekili: " .. i )
                    GameTooltip:AddLine( "Left-click and hold to move.", 1, 1, 1 )
                    GameTooltip:AddLine( "Right-click to open " .. i .. " display settings.", 1, 1, 1 )
                    if not H:IsDisplayActive( i, true, "OnEnter" ) then GameTooltip:AddLine( "This display is not currently active.", 0.5, 0.5, 0.5 ) end
                    GameTooltip:Show()
                end
            end )
            v.Backdrop:SetScript( "OnLeave", function( self )
                GameTooltip:Hide()
            end )
            v:Show()

            if not v.Header then
                v.Header = v.Backdrop:CreateFontString( "HekiliDisplay" .. i .. "Header", "OVERLAY", "GameFontNormal" )            
                local path, size = v.Header:GetFont()
                v.Header:SetFont( path, size, "OUTLINE" )
            end
            v.Header:ClearAllPoints()
            v.Header:SetAllPoints( v.Backdrop )

            if i == "Defensives" then v.Header:SetText( AtlasToString( "nameplates-InterruptShield", 20, 20 ) )
            elseif i == "Interrupts" then v.Header:SetText( AtlasToString( "communities-icon-redx", 20, 20 ) )
            else v.Header:SetText( i ) end
            
            v.Header:SetJustifyH("CENTER")
            v.Header:Show()
        else
            v:Hide()
        end
    end

    -- HekiliNotification:EnableMouse(true)
    -- HekiliNotification:SetMovable(true)
    if not external then
        local ACD = LibStub( "AceConfigDialog-3.0" )
        ACD:SetDefaultSize( "Hekili", 800, 600 )
        ACD:Open( "Hekili" )

        local oFrame = ACD.OpenFrames["Hekili"].frame
        oFrame:SetMinResize(800,600)

        ns.OnHideFrame = ns.OnHideFrame or CreateFrame( "Frame" )
        ns.OnHideFrame:SetParent( oFrame )
        ns.OnHideFrame:SetScript( "OnHide", function(self)
            ns.StopConfiguration()
            self:SetScript( "OnHide", nil )
            collectgarbage()
            Hekili:UpdateDisplayVisibility()
        end )

        Hekili:ProfileFrame( "CloseOptionsFrame", ns.OnHideFrame )
    end

    Hekili:UpdateDisplayVisibility()
end

function ns.StopConfiguration()
    Hekili.Config = false

    local scaleFactor = Hekili:GetScale()
    local mouseInteract = Hekili.Pause

    for i, v in ipairs( ns.UI.Buttons ) do
        for j, btn in ipairs( v ) do
            btn:EnableMouse( mouseInteract )
            btn:SetMovable( false )
        end
    end

    HekiliNotification:EnableMouse( false )
    HekiliNotification:SetMovable( false )
    HekiliNotification.Mover:Hide()
    -- HekiliNotification.Mover.Header:Hide()

    for i, v in pairs( ns.UI.Displays ) do
        v:EnableMouse( false )
        v:SetMovable( true )
        v:SetBackdrop( nil )
        if v.Header then
            v.Header:Hide()
        end
        if v.Backdrop then
            v.Backdrop:Hide()
        end
    end

    Hekili.MakeDefaults = false
end

local function MasqueUpdate( Addon, Group, SkinID, Gloss, Backdrop, Colors, Disabled )
    if Disabled then
        for dispID, display in ipairs( ns.UI.Buttons ) do
            for btnID, button in ipairs( display ) do
                button.__MSQ_NormalTexture:Hide()
                button.Texture:SetAllPoints( button )
            end
        end
    end
end


do
    ns.UI.Menu = ns.UI.Menu or CreateFrame( "Frame", "HekiliMenu", UIParent, "UIDropDownMenuTemplate" )
    local menu = ns.UI.Menu

    menu.info = {}

    menu.AddButton = UIDropDownMenu_AddButton
    menu.AddSeparator = UIDropDownMenu_AddSeparator

    local function SetDisplayMode( mode )
        Hekili.DB.profile.toggles.mode.value = mode
        if WeakAuras and WeakAuras.ScanEvents then WeakAuras.ScanEvents( "HEKILI_TOGGLE", "mode", mode ) end
        if ns.UI.Minimap then ns.UI.Minimap:RefreshDataText() end
        Hekili:UpdateDisplayVisibility()
        Hekili:ForceUpdate( "HEKILI_TOGGLE", true )
    end

    local function IsDisplayMode( p, mode )
        return Hekili.DB.profile.toggles.mode.value == mode
    end

    local menuData = {
        {
            isTitle = 1,
            text = "Hekili",
            notCheckable = 1,
        },

        {
            text = "Enable",
            func = function () Hekili:Toggle() end,
            checked = function () return Hekili.DB.profile.enabled end,
        },

        {
            text = "Pause",
            func = function () return Hekili:TogglePause() end,
            checked = function () return Hekili.Pause end,
        },
        
        {
            isSeparator = 1,
        },

        {
            isTitle = 1,
            text = "Display Mode",
            notCheckable = 1,
        },

        {
            text = "Auto",
            func = function () SetDisplayMode( "automatic" ) end,
            checked = function () return IsDisplayMode( p, "automatic" ) end,
        },

        {
            text = "Single",
            func = function () SetDisplayMode( "single" ) end,
            checked = function () return IsDisplayMode( p, "single" ) end,
        },

        {
            text = "AOE",
            func = function () SetDisplayMode( "aoe" ) end,
            checked = function () return IsDisplayMode( p, "aoe" ) end,
        },

        {
            text = "Dual",
            func = function () SetDisplayMode( "dual" ) end,
            checked = function () return IsDisplayMode( p, "dual" ) end,
        },

        {
            text = "Reactive",
            func = function () SetDisplayMode( "reactive" ) end,
            checked = function () return IsDisplayMode( p, "reactive" ) end,
        },

        {
            isSeparator = 1,
        },

        {
            isTitle = 1,
            text = "Toggles",
            notCheckable = 1,
        },

        {
            text = "Cooldowns",
            func = function() Hekili:FireToggle( "cooldowns" ); ns.UI.Minimap:RefreshDataText() end,
            checked = function () return Hekili.DB.profile.toggles.cooldowns.value end,
        },

        {
            text = "Essences",
            func = function() Hekili:FireToggle( "essences" ); ns.UI.Minimap:RefreshDataText() end,
            checked = function () return Hekili.DB.profile.toggles.essences.value end,
        },

        {
            text = "Interrupts",
            func = function() Hekili:FireToggle( "interrupts" ); ns.UI.Minimap:RefreshDataText() end,
            checked = function () return Hekili.DB.profile.toggles.interrupts.value end,
        },

        {
            text = "Defensives",
            func = function() Hekili:FireToggle( "defensives" ); ns.UI.Minimap:RefreshDataText() end,
            checked = function () return Hekili.DB.profile.toggles.defensives.value end,
        },

        {
            text = "Potions",
            func = function() Hekili:FireToggle( "potions" ); ns.UI.Minimap:RefreshDataText() end,
            checked = function () return Hekili.DB.profile.toggles.potions.value end,
        },

    }

    local specsParsed = false
    menu.args = {}

    function menu:initialize( level )
        if not level then return end

        if level == 1 then
            if not specsParsed then
                -- Add specialization toggles where applicable.
                for i, spec in pairs( Hekili.Class.specs ) do
                    if i > 0 then
                        local titled = false
    
                        -- Check for Toggles.
                        for n, setting in pairs( spec.settings ) do
                            if setting.info.type == "toggle" then
                                if not titled then
                                    insert( menuData, { 
                                        isSeparator = 1,
                                        hidden = function () return Hekili.State.spec.id ~= i end,
                                    } )
                                    insert( menuData, {
                                        isTitle = 1,
                                        text = spec.name,
                                        notCheckable = 1,
                                        hidden = function () return Hekili.State.spec.id ~= i end,
                                    } )
                                    titled = true
                                end

                                insert( menuData, {
                                    text = setting.info.name,
                                    func = function ()
                                        menu.args[1] = setting.name
                                        setting.info.set( menu.args, not setting.info.get( menu.args ) )

                                        if Hekili.DB.profile.notifications.enabled then
                                            Hekili:Notify( setting.info.name .. ": " .. ( setting.info.get( menu.args ) and "ON" or "OFF" ) )
                                        else
                                            self:Print( setting.info.name .. ": " .. ( setting.info.get( menu.args ) and " |cFF00FF00ENABLED|r." or " |cFFFF0000DISABLED|r." ) )
                                        end
                                    end,
                                    checked = function ()
                                        menu.args[1] = setting.name
                                        return setting.info.get( menu.args )
                                    end,
                                    hidden = function () return Hekili.State.spec.id ~= i end,
                                } )
                            end
                        end
                    end
                end
                specsParsed = true
            end
            
            for i, data in ipairs( menuData ) do
                if not data.hidden or ( type( data.hidden ) == 'function' and not data.hidden() ) then
                    if data.isSeparator then
                        menu.AddSeparator( level )
                    else
                        menu.AddButton( data, level )
                    end
                end
            end
        end
    end
end


 


do
    ns.UI.Displays = ns.UI.Displays or {}
    local dPool = ns.UI.Displays
    Hekili.DisplayPool = dPool

    local alphaUpdateEvents = {
        PET_BATTLE_OPENING_START = 1,
        PET_BATTLE_CLOSE = 1,
        BARBER_SHOP_OPEN = 1,
        BARBER_SHOP_CLOSE = 1,

        PLAYER_GAINS_VEHICLE_DATA = 1,
        PLAYER_LOSES_VEHICLE_DATA = 1,        
        UNIT_ENTERING_VEHICLE = 1,
        UNIT_ENTERED_VEHICLE = 1,
        UNIT_EXITED_VEHICLE = 1,
        UNIT_EXITING_VEHICLE = 1,
        VEHICLE_ANGLE_SHOW = 1,
        VEHICLE_UPDATE = 1,
        UPDATE_VEHICLE_ACTIONBAR = 1,
        UNIT_FLAGS = 1,

        PLAYER_TARGET_CHANGED = 1,

        PLAYER_ENTERING_WORLD = 1,
        PLAYER_REGEN_ENABLED = 1,
        PLAYER_REGEN_DISABLED = 1,

        ACTIVE_TALENT_GROUP_CHANGED = 1,

        ZONE_CHANGED = 1,
        ZONE_CHANGED_INDOORS = 1,
        ZONE_CHANGED_NEW_AREA = 1,

        PLAYER_CONTROL_LOST = 1,
        PLAYER_CONTROL_GAINED = 1,

        PLAYER_MOUNT_DISPLAY_CHANGED = 1,
        UPDATE_ALL_UI_WIDGETS = 1,
    }

    
    local function CalculateAlpha( id )
        if IsInPetBattle() or Hekili.Barber or UnitHasVehicleUI("player") or HasVehicleActionBar() or HasOverrideActionBar() or UnitOnTaxi("player") or not Hekili:IsDisplayActive( id ) then
            return 0
        end

        local prof = Hekili.DB.profile
        local conf, mode = prof.displays[ id ], prof.toggles.mode.value

        local _, zoneType = IsInInstance()
    
        -- Switch Type:
        --   0 = Auto - AOE
        --   1 = ST - AOE

        if ( not conf.enabled ) or ( not conf.visibility.mode[ mode ] ) then
            return 0

        elseif zoneType == "pvp" or zoneType == "arena" then
            if not conf.visibility.advanced then return conf.visibility.pvp.alpha end

            if conf.visibility.pvp.hideMounted and IsMounted() then return 0 end

            if conf.visibility.pvp.combatTarget > 0 and state.combat > 0 and UnitExists( "target" ) and not UnitIsDead( "target" ) and UnitCanAttack( "player", "target" ) then return conf.visibility.pvp.combatTarget
            elseif conf.visibility.pvp.combat > 0 and state.combat > 0 then return conf.visibility.pvp.combat
            elseif conf.visibility.pvp.target > 0 and UnitExists( "target" ) and not UnitIsDead( "target" ) and UnitCanAttack( "player", "target" ) then return conf.visibility.pvp.target
            elseif conf.visibility.pvp.always > 0 then return conf.visibility.pvp.always end

            return 0            
        end

        if not conf.visibility.advanced then return conf.visibility.pve.alpha end
        
        if conf.visibility.pve.hideMounted and IsMounted() then return 0 end

        if conf.visibility.pve.combatTarget > 0 and state.combat > 0 and UnitExists( "target" ) and not UnitIsDead( "target" ) and UnitCanAttack( "player", "target" ) then return conf.visibility.pve.combatTarget
        elseif conf.visibility.pve.combat > 0 and state.combat > 0 then return conf.visibility.pve.combat
        elseif conf.visibility.pve.target > 0 and UnitExists( "target" ) and not UnitIsDead( "target" ) and UnitCanAttack( "player", "target" ) then return conf.visibility.pve.target
        elseif conf.visibility.pve.always > 0 then return conf.visibility.pve.always end

        return 0
    end

    local kbEvents = {
        ACTIONBAR_SLOT_CHANGED = 1,
        ACTIONBAR_PAGE_CHANGED = 1,
        ACTIONBAR_UPDATE_STATE = 1,
        SPELLS_CHANGED = 1,
        UPDATE_SHAPESHIFT_FORM = 1
    }

    local function Display_UpdateKeybindings( self )
        local conf = Hekili.DB.profile.displays[ self.id ]

        if conf.keybindings and conf.keybindings.enabled then
            local cPort = conf.keybindings.cPortOverride and ConsolePort ~= nil

            for i, b in ipairs( self.Buttons ) do
                local r = self.Recommendations[i]
                if r then
                    local a = r.actionName

                    if a then                        
                        r.keybind = Hekili:GetBindingForAction( r.actionName, conf )
                    end

                    if i == 1 or ( conf.keybindings.queued and not cPort ) then
                        b.Keybinding:SetText( r.keybind )
                    else
                        b.Keybinding:SetText( nil )
                    end
                end
            end
        end
    end

    local pulseAuras = 0.1
    local pulseDelay = 0.05
    local pulseGlow = 0.25
    local pulseTargets = 0.1
    local pulseRange = TOOLTIP_UPDATE_TIME
    local pulseFlash = 0.5

    local oocRefresh = 1
    local icRefresh = {
        Primary = 0.5,
        AOE = 0.5,
        Interrupts = 1,
        Defensives = 1
    }

    local LRC = LibStub("LibRangeCheck-2.0")
    local LSF = SpellFlashCore
    local LSR = LibStub("SpellRange-1.0")
    local Glower = LibStub("LibCustomGlow-1.0")

    local function Display_OnUpdate( self, elapsed )
        if not self.Recommendations or not Hekili.PLAYER_ENTERING_WORLD then
            return
        end

        local profile = Hekili.DB.profile
        local conf = profile.displays[ self.id ]

        self.alphaCheck = self.alphaCheck - elapsed

        if self.alpha == 0 then
            if self.alphaCheck <= 0 then
                self.alphaCheck = 0.5
                self:UpdateAlpha()
            end
            return
        end

        if Hekili.Pause then
            if not self.paused then
                self.Buttons[ 1 ].Overlay:Show()
                self.paused = true
            end
        elseif self.paused then            
            self.Buttons[ 1 ].Overlay:Hide()
            self.paused = false
        end

        local now = GetTime()


        self.recTimer = self.recTimer - elapsed

        if self.NewRecommendations or self.recTimer < 0 then
            local alpha = self.alpha

            for i, b in ipairs( self.Buttons ) do
                local rec = self.Recommendations[ i ]

                local action = rec.actionName
                local caption = rec.caption
                local indicator = rec.indicator
                local keybind = rec.keybind

                local ability = class.abilities[ action ]

                if ability then
                    if ( conf.flash.enabled and conf.flash.suppress ) then b:Hide()
                    else b:Show() end

                    if action ~= b.lastAction or self.NewRecommendations then
                        b.Texture:SetTexture( rec.texture or ability.texture or GetSpellTexture( ability.id ) )
                        b.Texture:SetTexCoord( unpack( b.texCoords ) )
                        b.lastAction = action
                    end

                    b.Texture:Show()

                    if conf.indicators.enabled and indicator then
                        if indicator == "cycle" then
                            b.Icon:SetTexture("Interface\\Addons\\Hekili\\Textures\\Cycle")
                        end
                        if indicator == "cancel" then
                            b.Icon:SetTexture("Interface\\Addons\\Hekili\\Textures\\Cancel")
                        end
                        b.Icon:Show()
                    else
                        b.Icon:Hide()
                    end

                    if ( conf.captions.enabled or ability.caption ) and ( i == 1 or conf.captions.queued ) then
                        b.Caption:SetText( caption )
                    else
                        b.Caption:SetText(nil)
                    end

                    if conf.keybindings.enabled and ( i == 1 or conf.keybindings.queued and not ( conf.keybindings.cPortOverride and ConsolePort ~= nil ) ) then
                        b.Keybinding:SetText( keybind )
                    else
                        b.Keybinding:SetText(nil)
                    end

                    if conf.glow.enabled and ( i == 1 or conf.glow.queued ) and IsSpellOverlayed( ability.id ) then
                        b.glowColor = b.glowColor or {}

                        if conf.glow.coloring == "class" then
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = RAID_CLASS_COLORS[ class.file ]:GetRGBA()
                        elseif conf.glow.coloring == "custom" then
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = unpack(conf.glow.color)
                        else
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = 0.95, 0.95, 0.32, 1
                        end

                        if conf.glow.mode == "default" then
                            Glower.ButtonGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.ButtonGlow_Stop
                        elseif conf.glow.mode == "autocast" then
                            Glower.AutoCastGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.AutoCastGlow_Stop
                        elseif conf.glow.mode == "pixel" then
                            Glower.PixelGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.PixelGlow_Stop
                        end
                        
                        b.glowing = true
                    elseif b.glowing then
                        if b.glowStop then b:glowStop() end
                        b.glowing = false
                    end
                else
                    b:Hide()
                end
            end

            -- Force glow, range, SpellFlash updates.
            self.glowTimer = -1
            self.rangeTimer = -1
            self.flashTimer = -1
            self.delayTimer = -1

            self.recTimer = 1
            self.alphaCheck = 0.5

            self:RefreshCooldowns()
            self.NewRecommendations = false
        end


        self.refreshTimer = self.refreshTimer - elapsed

        if not Hekili.Pause then
            local spec = Hekili.DB.profile.specs[ state.spec.id ]
            local throttle = spec.throttleRefresh and ( 1 / spec.maxRefresh ) or ( 1 / 20 )
            local refreshRate = max( throttle, state.combat == 0 and oocRefresh or icRefresh[ self.id ] )

            if self.refreshTimer < 0 or Hekili.freshFrame and ( self.superUpdate and ( self.id == "Primary" or self.id == "AOE" ) or self.criticalUpdate and ( now - self.lastUpdate > throttle ) ) then
                Hekili:ProcessHooks( self.id )
                self.lastUpdate = now
                self.criticalUpdate = false
                self.superUpdate = false
                self.refreshTimer = refreshRate
                table.wipe( self.eventsTriggered )
            end
        end


        self.glowTimer = self.glowTimer - elapsed

        if self.glowTimer < 0 then
            if conf.glow.enabled then
                for i, b in ipairs( self.Buttons ) do
                    local r = self.Recommendations[ i ]

                    if not r.actionName then
                        break
                    end

                    local a = class.abilities[ r.actionName ]

                    if i == 1 or conf.glow.queued then
                        local glowing = not a.item and IsSpellOverlayed( a.id )

                        if glowing and not b.glowing then
                            b.glowColor = b.glowColor or {}

                            if conf.glow.coloring == "class" then
                                b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = RAID_CLASS_COLORS[ class.file ]:GetRGBA()
                            elseif conf.glow.coloring == "custom" then
                                b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = unpack(conf.glow.color)
                            else
                                b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = 0.95, 0.95, 0.32, 1
                            end
    
                            if conf.glow.mode == "default" then
                                Glower.ButtonGlow_Start( b, b.glowColor )
                                b.glowStop = Glower.ButtonGlow_Stop
                            elseif conf.glow.mode == "autocast" then
                                Glower.AutoCastGlow_Start( b, b.glowColor )
                                b.glowStop = Glower.AutoCastGlow_Stop
                            elseif conf.glow.mode == "pixel" then
                                Glower.PixelGlow_Start( b, b.glowColor )
                                b.glowStop = Glower.PixelGlow_Stop
                            end
                            
                            b.glowing = true
                        elseif not glowing and b.glowing then
                            b:glowStop()
                            b.glowing = false
                        end
                    else
                        if b.glowing then
                            b:glowStop()
                            b.glowing = false
                        end
                    end
                end
            end
        end


        self.rangeTimer = self.rangeTimer - elapsed

        if self.rangeTimer < 0 then
            for i, b in ipairs( self.Buttons ) do
                local r = self.Recommendations[ i ]
                local a = class.abilities[ r.actionName ]

                if a and a.id then
                    local outOfRange = false

                    if conf.range.enabled then
                        if conf.range.type == "melee" and UnitExists( "target" ) then
                            outOfRange = ( LRC:GetRange( "target" ) or 50 ) > 7
                        elseif conf.range.type == "ability" and UnitExists( "target" ) and UnitCanAttack( "player", "target" ) then
                            if a.item then
                                outOfRange = IsItemInRange( a.itemCd or a.item, "target" ) == false
                            else
                                local name = a.range and class.abilities[ a.range ] and class.abilities[ a.range ].name
                                name = name or a.actualName or a.name
                                outOfRange = LSR.IsSpellInRange( name, "target" ) == 0
                            end
                        end
                    end

                    if outOfRange and not b.outOfRange then
                        b.Texture:SetDesaturated(true)
                        b.Texture:SetVertexColor(1.0, 0.0, 0.0, 1.0)
                        b.outOfRange = true
                    elseif b.outOfRange and not outOfRange then
                        b.Texture:SetDesaturated(false)
                        b.Texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
                        b.outOfRange = false
                    end

                    if not b.outOfRange then
                        local _, unusable

                        if a.itemCd or a.item then
                            unusable = not IsUsableItem(a.itemCd or a.item)
                        else
                            _, unusable = IsUsableSpell(a.actualName or a.name)
                        end

                        if i == 1 and conf.delays.fade then
                            local delay = r.exact_time - now            
                            local moment = 0
                
                            local start, duration = GetSpellCooldown( 61304 )
                            if start > 0 then moment = start + duration - now end
    
                            local rStart, rDuration
                            if a.item then
                                rStart, rDuration = GetItemCooldown( a.id )
                            else
                                rStart, rDuration = GetSpellCooldown( a.id )
                            end
                            if rStart > 0 then moment = max( moment, rStart + rDuration - now ) end
                
                            _, _, _, start, duration = UnitCastingInfo( "player" )
                            if start and start > 0 then moment = max( ( start / 1000 ) + ( duration / 1000 ) - now, moment ) end
    
                            if delay > moment + 0.05 then
                                unusable = true
                            end
                        end    

                        if unusable and not b.unusable then
                            b.Texture:SetVertexColor(0.4, 0.4, 0.4, 1.0)
                            b.unusable = true
                        elseif b.unusable and not unusable then
                            b.Texture:SetVertexColor(1.0, 1.0, 1.0, 1.0)
                            b.unusable = false
                        end
                    end
                end
            end
            
            self.rangeTimer = pulseRange
        end

        
        if conf.flash.enabled and LSF then
            self.flashTimer = self.flashTimer - elapsed

            if self.flashTimer < 0 then
                local a = self.Recommendations and self.Recommendations[ 1 ] and self.Recommendations[ 1 ].actionName

                if a then
                    local ability = class.abilities[ a ]

                    self.flashColor = self.flashColor or {}
                    self.flashColor.r, self.flashColor.g, self.flashColor.b = unpack( conf.flash.color )

                    if self.lastFlash ~= a or now - self.lastFlashTime > 0.5 then
                        if ability.item then
                            local iname = LSF.ItemName( ability.item )
                            LSF.FlashItem( iname, self.flashColor )
                        else
                            if ability.flash then
                                LSF.FlashAction( ability.flash, self.flashColor )
                            else
                                local id = ability.known
                                
                                if id == nil or type( id ) ~= "number" then
                                    id = ability.id
                                end

                                local sname = LSF.SpellName( id )
                                LSF.FlashAction( sname, self.flashColor )
                            end
                        end
                        self.lastFlash = a
                        self.lastFlashTime = now
                    end
                end
            end

            self.flashTimer = pulseFlash
        end


        self.targetTimer = self.targetTimer - elapsed

        if self.targetTimer < 0 then
            local b = self.Buttons[ 1] 

            if conf.targets.enabled then
                local tMin, tMax = 0, 0
                local mode = profile.toggles.mode.value
                local spec = state.spec.id and profile.specs[ state.spec.id ]

                if self.id == 'Primary' then
                    if ( mode == 'dual' or mode == 'single' or mode == 'reactive' ) then tMax = 1
                    elseif mode == 'aoe' then tMin = spec and spec.aoe or 3 end
                elseif self.id == 'AOE' then tMin = spec and spec.aoe or 3 end

                local detected = ns.getNumberTargets()
                local shown = detected

                if tMin > 0 then
                    shown = max(tMin, shown)
                end
                if tMax > 0 then
                    shown = min(tMax, shown)
                end

                if tMax == 1 or shown > 1 then
                    local color = detected < shown and "|cFFFF0000" or ( shown < detected and "|cFF00C0FF" or "" )
                    b.Targets:SetText( color .. shown .. "|r")
                    b.targetShown = true
                else
                    b.Targets:SetText(nil)
                    b.targetShown = false
                end
            elseif b.targetShown then
                b.Targets:SetText(nil)
            end

            self.targetTimer = pulseTargets
        end


        local rec = self.Recommendations[ 1 ]

        self.delayTimer = self.delayTimer - elapsed

        if rec.exact_time and self.delayTimer < 0 then
            local b = self.Buttons[ 1 ]
            local a = class.abilities[ rec.actionName ]

            local delay = rec.exact_time - now
            local moment = 0

            if delay > 0 then
                local start, duration = GetSpellCooldown( 61304 )
                if start > 0 then moment = start + duration - now end

                _, _, _, start, duration = UnitCastingInfo( "player" )
                if start and start > 0 then moment = max( ( start / 1000 ) + ( duration / 1000 ) - now, moment ) end

                local rStart, rDuration
                if a.item then
                    rStart, rDuration = GetItemCooldown( a.id )
                else
                    rStart, rDuration = GetSpellCooldown( a.id )
                end
                if rStart > 0 then moment = max( moment, rStart + rDuration - now ) end
            end

            if conf.delays.type == "TEXT" then
                if self.delayIconShown then
                    b.DelayIcon:Hide()
                    self.delayIconShown = false
                end

                if delay > moment + 0.05 then
                    b.DelayText:SetText( format( "%.1f", delay ) )
                    self.delayTextShown = true
                else
                    b.DelayText:SetText( nil )
                    self.delayTextShown = false
                end

            elseif conf.delays.type == "ICON" then
                if self.delayTextShown then
                    b.DelayText:SetText(nil)
                    self.delayTextShown = false
                end

                if delay > moment + 0.05 then
                    b.DelayIcon:Show()
                    b.DelayIcon:SetAlpha( self.alpha )

                    self.delayIconShown = true

                    if delay < 0.5 then
                        b.DelayIcon:SetVertexColor( 0.0, 1.0, 0.0, 1.0 )
                    elseif delay < 1.5 then
                        b.DelayIcon:SetVertexColor( 1.0, 1.0, 0.0, 1.0 )
                    else
                        b.DelayIcon:SetVertexColor( 1.0, 0.0, 0.0, 1.0)
                    end                       
                else
                    b.DelayIcon:Hide()
                    b.delayIconShown = false

                end
            else
                if self.delayTextShown then
                    b.DelayText:SetText( nil )
                    self.delayTextShown = false
                end
                if self.delayIconShown then
                    b.DelayIcon:Hide()
                    self.delayIconShown = false
                end
            end

            self.delayTimer = pulseDelay
        end        
    end
    ns.cpuProfile.Display_OnUpdate = Display_OnUpdate

    local function Display_UpdateAlpha( self )
        if self.Backdrop then
            if not Hekili:IsDisplayActive( self.id, true ) then self.Backdrop:SetBackdropBorderColor( 0.5, 0.5, 0.5, 0.5 )
            else
                self.Backdrop:SetBackdropBorderColor( RAID_CLASS_COLORS[ class.file ]:GetRGBA() )
            end
        end

        if not self.Active then
            self:SetAlpha(0)
            self:Hide()
            self.alpha = 0
            return
        end

        local preAlpha = self.alpha or 0
        local newAlpha = CalculateAlpha( self.id )

        if preAlpha > 0 and newAlpha == 0 then
            -- self:Deactivate()
            self:SetAlpha( 0 )
            self.alphaCheck = 0.5
        else
            if preAlpha == 0 and newAlpha > 0 then                
                Hekili:ForceUpdate( "DISPLAY_ALPHA_CHANGED" )
            end
            self:SetAlpha( newAlpha )
            self:Show()
        end

        self.alpha = newAlpha
    end

    local function Display_RefreshCooldowns( self )
        local gStart, gDuration = GetSpellCooldown( 61304 )
        local gExpires = gStart + gDuration

        local now = GetTime()
        local conf = Hekili.DB.profile.displays[ self.id ]

        for i, rec in ipairs( self.Recommendations ) do
            if not rec.actionName then
                break
            end

            local ability = class.abilities[ rec.actionName ]
            local cd = self.Buttons[ i ].Cooldown

            if ability then
                local start, duration = 0, 0

                if ability.item then
                    start, duration = GetItemCooldown( ability.item )
                else
                    start, duration = GetSpellCooldown( ability.id )
                end

                if ability.gcd ~= "off" and start + duration < gExpires then
                    start = gStart
                    duration = gDuration
                end

                if i == 1 and conf.delays.extend and rec.delay and rec.delay > 0 and rec.exact_time > max( now, start + duration ) then
                    start = start > 0 and start or state.gcd.lastStart
                    duration = rec.exact_time - start
                end

                if cd.lastStart ~= start or cd.lastDuration ~= duration then
                    cd:SetCooldown( start, duration )
                    cd.lastStart = start
                    cd.lastDuration = duration
                end
            end
        end
    end

    local function Display_OnEvent(self, event, ...)
        if not self.Recommendations then
            return
        end
        local conf = Hekili.DB.profile.displays[ self.id ]

        -- Update the CDs.
        if event == "SPELL_UPDATE_USABLE" or event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_USABLE" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
            self:RefreshCooldowns()

        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            if conf.glow.enabled then
                for i, r in ipairs( self.Recommendations ) do
                    if i > 1 and not conf.glow.queued then
                        break
                    end
                    if not r.actionName then
                        break
                    end

                    local b = self.Buttons[ i ]
                    local a = class.abilities[ r.actionName ]

                    if not b.glowing and a and not a.item and IsSpellOverlayed( a.id ) then
                        b.glowColor = b.glowColor or {}

                        if conf.glow.coloring == "class" then
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = RAID_CLASS_COLORS[ class.file ]:GetRGBA()
                        elseif conf.glow.coloring == "custom" then
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = unpack(conf.glow.color)
                        else
                            b.glowColor[1], b.glowColor[2], b.glowColor[3], b.glowColor[4] = 0.95, 0.95, 0.32, 1
                        end

                        if conf.glow.mode == "default" then
                            Glower.ButtonGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.ButtonGlow_Stop
                        elseif conf.glow.mode == "autocast" then
                            Glower.AutoCastGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.AutoCastGlow_Stop
                        elseif conf.glow.mode == "pixel" then
                            Glower.PixelGlow_Start( b, b.glowColor )
                            b.glowStop = Glower.PixelGlow_Stop
                        end
                        
                        b.glowing = true
                    end
                end
            end
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            if conf.glow.enabled then
                for i, r in ipairs(self.Recommendations) do
                    if i > 1 and not conf.glow.queued then
                        break
                    end

                    if not r.actionName then
                        break
                    end

                    local b = self.Buttons[ i ]
                    local a = class.abilities[ r.actionName ]

                    if b.glowing and ( not a or a.item or not IsSpellOverlayed( a.id ) ) then
                        b:glowStop()
                        b.glowing = false
                    end
                end
            end
        elseif kbEvents[ event ] then
            self:UpdateKeybindings()

        elseif alphaUpdateEvents[ event ] then
            self:UpdateAlpha()

        elseif event == "SPELLS_CHANGED" then
            for i, rec in ipairs( self.Recommendations ) do                
                rec.texture = nil
            end
            self.NewRecommendations = true

        end
    end
    ns.cpuProfile.Display_OnEvent = Display_OnEvent


    local function Display_Activate( self )
        if not self.Active then
            self.Active = true

            self.Recommendations = self.Recommendations or ( ns.queue and ns.queue[ self.id ] )
            self.NewRecommendations = true

            self.alphaCheck = 0
            self.auraTimer = 0
            self.delayTimer = 0
            self.flashTimer = 0
            self.lastFlashTime = 0
            self.glowTimer = 0
            self.rangeTimer = 0
            self.recTimer = 0
            self.refreshTimer = 0
            self.targetTimer = 0

            self.lastUpdate = 0

            self:SetScript( "OnUpdate", Display_OnUpdate )
            self:SetScript( "OnEvent", Display_OnEvent )

            if not self.Initialized then
                -- Update Cooldown Wheels.
                self:RegisterEvent( "ACTIONBAR_UPDATE_USABLE" )
                self:RegisterEvent( "ACTIONBAR_UPDATE_COOLDOWN" )
                self:RegisterEvent( "SPELL_UPDATE_COOLDOWN" )
                self:RegisterEvent( "SPELL_UPDATE_USABLE" )

                -- Show/Hide Overlay Glows.
                self:RegisterEvent( "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" )
                self:RegisterEvent( "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" )

                -- Recalculate Alpha/Visibility.
                for e in pairs( alphaUpdateEvents ) do
                    self:RegisterEvent( e )
                end

                -- Recheck spell displays if spells have changed.
                self:RegisterEvent( "SPELLS_CHANGED" )

                -- Update keybindings.
                for k in pairs( kbEvents ) do
                    self:RegisterEvent( k )
                end

                self.Initialized = true
            end

            Hekili:ProcessHooks( self.id )
        end
    end

    local function Display_Deactivate( self )
        self.Active = false

        self:SetScript( "OnUpdate", nil )
        self:SetScript( "OnEvent", nil )

        for i, b in ipairs( self.Buttons ) do
            b:Hide()
        end
    end


    local function Display_GetPerimeterButtons( self )
        local left, right, top, bottom
        local lPos, rPos, tPos, bPos

        for i = 1, self.numIcons do
            local button = self.Buttons[ i ]

            if i == 1 then
                lPos = button:GetLeft()
                rPos = button:GetRight()
                tPos = button:GetTop()
                bPos = button:GetBottom()

                left = button
                right = button
                top = button
                bottom = button
            else
                if button:GetLeft() < lPos then
                    lPos = button:GetLeft()
                    left = button
                end

                if button:GetRight() > rPos then
                    rPos = button:GetRight()
                    right = button
                end

                if button:GetTop() > tPos then
                    tPos = button:GetTop()
                    top = button
                end

                if button:GetBottom() < bPos then
                    bPos = button:GetBottom()
                    bottom = button
                end
            end
        end

        return left, right, top, bottom
    end

    function Display_UpdatePerformance( self, now, used )
        if self.combatTime.samples == 0 then
            self.combatTime.fastest = used
            self.combatTime.slowest = used
            self.combatTime.average = used

            self.combatTime.samples = 1
        else
            if used < self.combatTime.fastest then self.combatTime.fastest = used end
            if used > self.combatTime.slowest then self.combatTime.slowest = used end

            self.combatTime.average = ( ( self.combatTime.average * self.combatTime.samples ) + used ) / ( self.combatTime.samples + 1 )
            self.combatTime.samples = self.combatTime.samples + 1
        end

        if self.combatUpdates.samples == 0 then
            if self.combatUpdates.last == 0 then
                self.combatUpdates.last = now
            else
                local interval = now - self.combatUpdates.last
                self.combatUpdates.last = now

                self.combatUpdates.shortest = interval
                self.combatUpdates.longest = interval
                self.combatUpdates.average = interval

                self.combatUpdates.samples = 1
            end
        else
            local interval = now - self.combatUpdates.last
            self.combatUpdates.last = now
            
            if interval < self.combatUpdates.shortest then
                self.combatUpdates.shortest = interval
                self.combatUpdates.shortEvents = nil
                
                local e = 0
                for k in pairs( self.eventsTriggered ) do
                    if e == 0 then self.combatUpdates.shortEvents = k; e = 1
                    else self.combatUpdates.shortEvents = self.combatUpdates.shortEvents .. "|" .. k end
                end
            end

            if interval > self.combatUpdates.longest  then
                self.combatUpdates.longest = interval
                self.combatUpdates.longEvents = nil
                
                local e = 0
                for k in pairs( self.eventsTriggered ) do
                    if e == 0 then self.combatUpdates.longEvents = k; e = 1
                    else self.combatUpdates.longEvents = self.combatUpdates.longEvents .. "|" .. k end
                end
            end

            self.combatUpdates.average = ( ( self.combatUpdates.average * self.combatUpdates.samples ) + interval ) / ( self.combatUpdates.samples + 1 )
            self.combatUpdates.samples = self.combatUpdates.samples + 1
        end
    end


    local numDisplays = 0

    function Hekili:CreateDisplay( id )
        local conf = rawget( self.DB.profile.displays, id )
        if not conf then return end

        if not dPool[ id ] then
            numDisplays = numDisplays + 1
            dPool[ id ] = CreateFrame( "Frame", "HekiliDisplay" .. id, UIParent )
            dPool[ id ].index = numDisplays

            Hekili:ProfileFrame( "HekiliDisplay" .. id, dPool[ id ] )            
        end
        local d = dPool[ id ]

        d.id = id
        d.alpha = 0
        d.numIcons = conf.numIcons
        d.firstForce = 0

        local scale = self:GetScale()
        local border = 2

        d:SetSize( scale * ( border + ( conf.primaryWidth or 50 ) ), scale * ( border + ( conf.primaryHeight or 50 ) ) )
        d:SetPoint( "CENTER", nil, "CENTER", conf.x or 0, conf.y or -225 )
        d:SetFrameStrata( conf.frameStrata or "MEDIUM" )
        d:SetFrameLevel( conf.frameLevel or ( 10 * d.index ) )
        d:SetClampedToScreen( true )
        d:EnableMouse( false )
        d:SetMovable( true )

        d.Activate = Display_Activate
        d.Deactivate = Display_Deactivate
        d.GetPerimeterButtons = Display_GetPerimeterButtons
        
        d.UpdatePerformance = Display_UpdatePerformance
        
        d.RefreshCooldowns = Display_RefreshCooldowns
        d.UpdateAlpha = Display_UpdateAlpha
        d.UpdateKeybindings = Display_UpdateKeybindings

        ns.queue[id] = ns.queue[id] or {}
        d.Recommendations = ns.queue[id]

        ns.UI.Buttons[id] = ns.UI.Buttons[id] or {}
        d.Buttons = ns.UI.Buttons[id]

        for i = 1, 10 do
            d.Buttons[ i ] = self:CreateButton( id, i )
            d.Buttons[ i ]:Hide()

            if conf.enabled and self:IsDisplayActive( id ) and i <= conf.numIcons then
                if d.Recommendations[ i ] and d.Recommendations[ i ].actionName then
                    d.Buttons[ i ]:Show()
                end
            end

            if MasqueGroup then
                MasqueGroup:AddButton( d.Buttons[i], { Icon = d.Buttons[ i ].Texture, Cooldown = d.Buttons[ i ].Cooldown } )
            end
        end

        -- Performance Information
        -- Time Spent
        d.combatTime = {
            fastest = 0,
            slowest = 0,
            average = 0,

            samples = 0
        }

        -- Time Between Updates
        d.combatUpdates = {
            last = 0,
            
            longest = 0,
            shortest = 0,
            average = 0,

            samples = 0,
        }

        d.eventsTriggered = {}
    end
    
    
    function Hekili:CreateCustomDisplay( id )
        local conf = rawget( self.DB.profile.displays, id )
        if not conf then return end

        dPool[ id ] = dPool[ id ] or CreateFrame( "Frame", "HekiliDisplay" .. id, UIParent )
        local d = dPool[ id ]

        d.id = id

        local scale = self:GetScale()
        local border = 2

        d:SetSize( scale * ( border + conf.primaryWidth ), scale * (border + conf.primaryHeight ) )
        d:SetPoint( "CENTER", nil, "CENTER", conf.x, conf.y )
        d:SetFrameStrata( "MEDIUM" )
        d:SetClampedToScreen( true )
        d:EnableMouse( false )
        d:SetMovable( true )

        d.Activate = Display_Activate
        d.Deactivate = Display_Deactivate
        d.RefreshCooldowns = Display_RefreshCooldowns
        d.UpdateAlpha = Display_UpdateAlpha
        d.UpdateKeybindings = Display_UpdateKeybindings

        ns.queue[id] = ns.queue[id] or {}
        d.Recommendations = ns.queue[id]

        ns.UI.Buttons[id] = ns.UI.Buttons[id] or {}
        d.Buttons = ns.UI.Buttons[id]

        for i = 1, 10 do
            d.Buttons[i] = self:CreateButton(id, i)
            d.Buttons[i]:Hide()

            if self.DB.profile.enabled and self:IsDisplayActive(id) and i <= conf.numIcons then
                if d.Recommendations[i] and d.Recommendations[i].actionName then
                    d.Buttons[i]:Show()
                end
            end

            if MasqueGroup then
                MasqueGroup:AddButton(d.Buttons[i], {Icon = d.Buttons[i].Texture, Cooldown = d.Buttons[i].Cooldown})
            end
        end
    end

    local dispActive = {}
    local listActive = {}
    local actsActive = {}

    function Hekili:UpdateDisplayVisibility()
        local profile = self.DB.profile
        local displays = ns.UI.Displays

        for key in pairs( dispActive ) do
            dispActive[ key ] = nil
        end

        for list in pairs( listActive ) do
            listActive[ list ] = nil
        end

        for a in pairs( actsActive ) do
            actsActive[ a ] = nil
        end

        local specEnabled = GetSpecialization()
        specEnabled = specEnabled and GetSpecializationInfo( specEnabled )
        specEnabled = specEnabled and profile.specs[ specEnabled ]
        specEnabled = specEnabled and specEnabled.enabled or false

        if profile.enabled and specEnabled then
            for i, display in pairs( profile.displays ) do
                if display.enabled then
                    if i == 'AOE' then
                        dispActive[i] = ( profile.toggles.mode.value == 'dual' or profile.toggles.mode.value == "reactive" ) and 1 or nil
                    elseif i == 'Interrupts' then
                        dispActive[i] = ( profile.toggles.interrupts.value and profile.toggles.interrupts.separate ) and 1 or nil
                    elseif i == 'Defensives' then
                        dispActive[i] = ( profile.toggles.defensives.value and profile.toggles.defensives.separate ) and 1 or nil
                    else
                        dispActive[i] = 1
                    end

                    if dispActive[i] == nil and self.Config then
                        dispActive[i] = 2
                    end
                    
                    if dispActive[i] and displays[i] then
                        if not displays[i].Active then displays[i]:Activate() end
                        displays[i].NewRecommendations = true
                    end
                else
                    if displays[i] and displays[i].Active then
                        displays[i]:Deactivate()
                    end
                end
            end

            for packName, pack in pairs( profile.packs ) do
                if pack.spec == 0 or pack.spec == state.spec.id then
                    for listName, list in pairs( pack.lists ) do
                        listActive[ packName .. ":" .. listName ] = true

                        -- NYI:  We can cache if abilities are disabled here as well to reduce checking in ProcessHooks.
                        for a, entry in ipairs( list ) do
                            if entry.enabled and entry.action then
                                actsActive[ packName .. ":" .. listName .. ":" .. a ] = true
                            end
                        end
                    end
                end
            end
        end

        for i, d in pairs(ns.UI.Displays) do
            d:UpdateAlpha()
        end
    end

    function Hekili:ReviewPacks()
        local profile = self.DB.profile

        for list in pairs( listActive ) do
            listActive[ list ] = nil
        end

        for a in pairs( actsActive ) do
            actsActive[ a ] = nil
        end

        for packName, pack in pairs( profile.packs ) do
            if pack.spec == 0 or pack.spec == state.spec.id then
                for listName, list in pairs( pack.lists ) do
                    listActive[ packName .. ":" .. listName ] = true

                    -- NYI:  We can cache if abilities are disabled here as well to reduce checking in ProcessHooks.
                    for a, entry in ipairs( list ) do
                        if entry.enabled and entry.action and class.abilities[ entry.action ] then
                            actsActive[ packName .. ":" .. listName .. ":" .. a ] = true
                        end
                    end
                end
            end
        end
    end

    function Hekili:IsDisplayActive( display, config )
        if config then
            return dispActive[ display ] == 1
        end
        return dispActive[display] ~= nil
    end

    function Hekili:IsListActive( pack, list )
        return pack == "UseItems" or ( listActive[ pack .. ":" .. list ] == true )
    end

    function Hekili:IsActionActive( pack, list, action )
        return pack == "UseItems" or ( actsActive[ pack .. ":" .. list .. ":" .. action ] == true )
    end

    function Hekili:DumpActionActive()
        DevTools_Dump( actsActive )
    end


    local firstForceRequest = 0

    function Hekili:ForceUpdate( event, super )
        Hekili.freshFrame = false

        for i, d in pairs( ns.UI.Displays ) do        
            d.criticalUpdate = true
            if super then d.superUpdate = true end
            if d.firstForce == 0 then d.firstForce = GetTime() end
            if event then d.eventsTriggered[ event ] = true end
        end
    end    

    
    local LSM = LibStub("LibSharedMedia-3.0", true)
    local LRC = LibStub("LibRangeCheck-2.0")
    local LSR = LibStub("SpellRange-1.0")

    function Hekili:CreateButton( dispID, id )
        local d = dPool[ dispID ]
        if not d then
            return
        end

        local conf = rawget( self.DB.profile.displays, dispID )
        if not conf then return end
        
        ns.queue[ dispID ][ id ] = ns.queue[ dispID ][ id ] or {}

        local bName = "Hekili_" .. dispID .. "_B" .. id
        local b = d.Buttons[ id ] or CreateFrame( "Button", bName, d )
        
        b.display = dispID
        b.index = id

        local scale = self:GetScale()

        local borderOffset = 0

        if conf.border.enabled and conf.border.fit then
            borderOffset = 2
        end

        if id == 1 then
            b:SetHeight( scale * ( ( conf.primaryHeight or 50 ) - borderOffset ) )
            b:SetWidth( scale * ( ( conf.primaryWidth or 50 ) - borderOffset  ) )
        else
            b:SetHeight( scale * ( ( conf.queue.height or 30 ) - borderOffset  ) )
            b:SetWidth( scale * ( ( conf.queue.width or 50 ) - borderOffset  ) )
        end

        -- Texture
        if not b.Texture then
            b.Texture = b:CreateTexture( nil, "LOW" )
            b.Texture:SetTexture( "Interface\\ICONS\\Spell_Nature_BloodLust" )
            b.Texture:SetAllPoints( b )
        end

        b.texCoords = b.texCoords or {}
        local zoom = 1 - ( ( conf.zoom or 0) / 200 )

        if conf.keepAspectRatio then
            local biggest = id == 1 and max( conf.primaryHeight, conf.primaryWidth ) or max( conf.queue.height, conf.queue.width )
            local height = 0.5 * zoom * ( id == 1 and conf.primaryHeight or conf.queue.height ) / biggest
            local width = 0.5 * zoom * ( id == 1 and conf.primaryWidth or conf.queue.width ) / biggest

            b.texCoords[1] = 0.5 - width
            b.texCoords[2] = 0.5 + width
            b.texCoords[3] = 0.5 - height
            b.texCoords[4] = 0.5 + height

            b.Texture:SetTexCoord( unpack( b.texCoords ) )
        else
            local zoom = zoom / 2

            b.texCoords[1] = 0.5 - zoom
            b.texCoords[2] = 0.5 + zoom
            b.texCoords[3] = 0.5 - zoom
            b.texCoords[4] = 0.5 + zoom

            b.Texture:SetTexCoord( unpack( b.texCoords ) )
        end


        -- Initialize glow/noop if button has not yet been glowed.
        b.glowing = b.glowing or false
        b.glowStop = b.glowStop or function () end


        -- Indicator Icons.
        b.Icon = b.Icon or b:CreateTexture( nil, "OVERLAY" )
        b.Icon: SetSize( max( 10, b:GetWidth() / 3 ), max( 10, b:GetHeight() / 3 ) )
        
        if conf.keepAspectRatio and b.Icon:GetHeight() ~= b.Icon:GetWidth() then
            local biggest = max( b.Icon:GetHeight(), b.Icon:GetWidth() )
            local height = 0.5 * b.Icon:GetHeight() / biggest
            local width = 0.5 * b.Icon:GetWidth() / biggest

            b.Icon:SetTexCoord( 0.5 - width, 0.5 + width, 0.5 - height, 0.5 + height )
        else
            b.Icon:SetTexCoord( 0, 1, 0, 1 )
        end
        
        local iconAnchor = conf.indicators.anchor or "RIGHT"
        
        b.Icon:ClearAllPoints()
        b.Icon:SetPoint( iconAnchor, b, iconAnchor, conf.indicators.x or 0, conf.indicators.y or 0 )
        b.Icon:Hide()


        -- Caption Text.
        b.Caption = b.Caption or b:CreateFontString( bName .. "_Caption", "OVERLAY" )

        local captionFont = conf.captions.font or conf.font
        b.Caption:SetFont( LSM:Fetch("font", captionFont), conf.captions.fontSize or 12, conf.captions.fontStyle or "OUTLINE" )

        local capAnchor = conf.captions.anchor or "BOTTOM"
        b.Caption:ClearAllPoints()
        b.Caption:SetPoint( capAnchor, b, capAnchor, conf.captions.x or 0, conf.captions.y or 0 )
        b.Caption:SetSize( b:GetWidth(), max( 12, b:GetHeight() / 2 ) )
        b.Caption:SetJustifyV( capAnchor )
        b.Caption:SetJustifyH( conf.captions.align or "CENTER" )
        b.Caption:SetTextColor( unpack( conf.captions.color ) )

        local capText = b.Caption:GetText()
        b.Caption:SetText( nil )
        b.Caption:SetText( capText )


        -- Keybinding Text
        b.Keybinding = b.Keybinding or b:CreateFontString(bName .. "_KB", "OVERLAY")
        local kbFont = conf.keybindings.font or conf.font
        b.Keybinding:SetFont( LSM:Fetch("font", kbFont), conf.keybindings.fontSize or 12, conf.keybindings.fontStyle or "OUTLINE" )

        local kbAnchor = conf.keybindings.anchor or "TOPRIGHT"
        b.Keybinding:ClearAllPoints()
        b.Keybinding:SetPoint( kbAnchor, b, kbAnchor, conf.keybindings.x or 0, conf.keybindings.y or 0 )
        b.Keybinding:SetSize( 0, 0 )
        b.Keybinding:SetTextColor( unpack( conf.keybindings.color ) )

        local kbText = b.Keybinding:GetText()
        b.Keybinding:SetText( nil )
        b.Keybinding:SetText( kbText )

        
        -- Cooldown Wheel
        b.Cooldown = b.Cooldown or CreateFrame( "Cooldown", bName .. "_Cooldown", b, "CooldownFrameTemplate" )
        b.Cooldown:ClearAllPoints()
        b.Cooldown:SetAllPoints( b )
        -- b.Cooldown:SetFrameStrata( "MEDIUM" )
        -- b.Cooldown:SetFrameLevel( 50 )
        b.Cooldown:SetDrawBling( false )
        b.Cooldown:SetDrawEdge( false )

        -- Backdrop (for borders)
        b.Backdrop = b.Backdrop or CreateFrame("Frame", bName .. "_Backdrop", b )
        b.Backdrop:ClearAllPoints()
        b.Backdrop:SetWidth( b:GetWidth() + 2 )
        b.Backdrop:SetHeight( b:GetHeight() + 2 )

        local framelevel = b:GetFrameLevel()
        if framelevel > 0 then
            -- b.Backdrop:SetFrameStrata( "MEDIUM" )
            b.Backdrop:SetFrameLevel( framelevel - 1 )
        else
            local lowerStrata = frameStratas[ b:GetFrameStrata() ]
            lowerStrata = frameStratas[ lowerStrata - 1 ]
            b.Backdrop:SetFrameStrata( lowerStrata or "LOW" )
        end

        b.Backdrop:SetPoint( "CENTER", b, "CENTER" )
        b.Backdrop:Hide()

        if conf.border.enabled then
            b.Backdrop:SetBackdrop( {
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = false,
                tileSize = 0,
                edgeSize = 1,
                insets = { left = -1, right = -1, top = -1, bottom = -1 }
            } )
            if conf.border.coloring == 'custom' then
                b.Backdrop:SetBackdropBorderColor( unpack( conf.border.color ) )
            else
                b.Backdrop:SetBackdropBorderColor( RAID_CLASS_COLORS[ class.file ]:GetRGBA() )
            end
            b.Backdrop:Show()
        else
            b.Backdrop:SetBackdrop( nil )
            b.Backdrop:SetBackdropColor( 0, 0, 0, 0 )
            b.Backdrop:Hide()
        end


        -- Primary Icon Stuff
        if id == 1 then
            -- Anchoring stuff for the queue.
            b:ClearAllPoints()
            b:SetPoint( "CENTER", d, "CENTER" )

            -- Target Counter
            b.Targets = b.Targets or b:CreateFontString( bName .. "_Targets", "OVERLAY" )

            local tarFont = conf.targets.font or conf.font
            b.Targets:SetFont( LSM:Fetch( "font", tarFont ), conf.targets.fontSize or 12, conf.targets.fontStyle or "OUTLINE" )

            local tarAnchor = conf.targets.anchor or "BOTTOM"
            b.Targets:ClearAllPoints()
            b.Targets:SetPoint( tarAnchor, b, tarAnchor, conf.targets.x or 0, conf.targets.y or 0 )
            b.Targets:SetSize( b:GetWidth(), b:GetHeight() / 2 )
            b.Targets:SetJustifyH( tarAnchor:match("RIGHT") and "RIGHT" or ( tarAnchor:match( "LEFT" ) and "LEFT" or "CENTER" ) )
            b.Targets:SetJustifyV( tarAnchor:match("TOP") and "TOP" or ( tarAnchor:match( "BOTTOM" ) and "BOTTOM" or "MIDDLE" ) )
            b.Targets:SetTextColor( unpack( conf.targets.color ) )

            local tText = b.Targets:GetText()
            b.Targets:SetText( nil )
            b.Targets:SetText( tText )                
            
            -- Aura Counter
            -- Disabled for Now
            --[[ b.Auras = b.Auras or b:CreateFontString(bName .. "_Auras", "OVERLAY")

            local auraFont = conf.auraFont or (ElvUI and "PT Sans Narrow" or "Arial Narrow")
            b.Auras:SetFont(LSM:Fetch("font", auraFont), conf.auraFontSize or 12, conf.auraFontStyle or "OUTLINE")
            b.Auras:SetSize(b:GetWidth(), b:GetHeight() / 2)

            local auraAnchor = conf.auraAnchor or "BOTTOM"
            b.Auras:ClearAllPoints()
            b.Auras:SetPoint(auraAnchor, b, auraAnchor, conf.xOffsetAuras or 0, conf.yOffsetAuras or 0)

            b.Auras:SetJustifyH(
                auraAnchor:match("RIGHT") and "RIGHT" or (auraAnchor:match("LEFT") and "LEFT" or "CENTER")
            )
            b.Auras:SetJustifyV(
                auraAnchor:match("TOP") and "TOP" or (auraAnchor:match("BOTTOM") and "BOTTOM" or "MIDDLE")
            )
            b.Auras:SetTextColor(1, 1, 1, 1) ]]


            -- Delay Counter
            b.DelayText = b.DelayText or b:CreateFontString( bName .. "_DelayText", "OVERLAY" )

            local delayFont = conf.delays.font or conf.font
            b.DelayText:SetFont( LSM:Fetch("font", delayFont), conf.delays.fontSize or 12, conf.delays.fontStyle or "OUTLINE" )

            local delayAnchor = conf.delays.anchor or "TOPLEFT"
            b.DelayText:ClearAllPoints()
            b.DelayText:SetPoint( delayAnchor, b, delayAnchor, conf.delays.x, conf.delays.y or 0 )
            b.DelayText:SetSize( b:GetWidth(), b:GetHeight() / 2 )

            b.DelayText:SetJustifyH( delayAnchor:match( "RIGHT" ) and "RIGHT" or ( delayAnchor:match( "LEFT" ) and "LEFT" or "CENTER") )
            b.DelayText:SetJustifyV( delayAnchor:match( "TOP" ) and "TOP" or ( delayAnchor:match( "BOTTOM" ) and "BOTTOM" or "MIDDLE") )
            b.DelayText:SetTextColor( unpack( conf.delays.color ) )

            local dText = b.DelayText:GetText()
            b.DelayText:SetText( nil )
            b.DelayText:SetText( dText )
            

            -- Delay Icon
            b.DelayIcon = b.DelayIcon or b:CreateTexture( bName .. "_DelayIcon", "OVERLAY" )
            b.DelayIcon:SetSize( min( 20, max( 10, b:GetSize() / 3 ) ), min( 20, max( 10, b:GetSize() / 3 ) ) )
            b.DelayIcon:SetTexture( "Interface\\FriendsFrame\\StatusIcon-Online" )
            b.DelayIcon:SetDesaturated( true )
            b.DelayIcon:SetVertexColor( 1, 0, 0, 1 )

            b.DelayIcon:ClearAllPoints()
            b.DelayIcon:SetPoint( delayAnchor, b, delayAnchor, conf.delays.x or 0, conf.delays.y or 0 )
            b.DelayIcon:Hide()

            -- Overlay (for Pause)
            b.Overlay = b.Overlay or b:CreateTexture( nil, "OVERLAY" )
            b.Overlay:SetAllPoints( b )
            b.Overlay:SetTexture( "Interface\\Addons\\Hekili\\Textures\\Pause.blp" )
            b.Overlay:SetTexCoord( unpack( b.texCoords ) )
            b.Overlay:Hide()

        elseif id == 2 then
            -- Anchoring for the remainder.
            local queueAnchor = conf.queue.anchor or "RIGHT"
            local qOffsetX = ( conf.queue.offsetX or 5 )
            local qOffsetY = ( conf.queue.offsetY or 0 )

            b:ClearAllPoints()

            if queueAnchor:sub( 1, 5 ) == "RIGHT" then
                local dir, align = "RIGHT", queueAnchor:sub(6)
                b:SetPoint( align .. getInverseDirection(dir), "Hekili_" .. dispID .. "_B1", align .. dir, ( borderOffset + qOffsetX ) * scale, qOffsetY * scale )
            elseif queueAnchor:sub( 1, 4 ) == "LEFT" then
                local dir, align = "LEFT", queueAnchor:sub(5)
                b:SetPoint( align .. getInverseDirection(dir), "Hekili_" .. dispID .. "_B1", align .. dir, -1 * ( borderOffset + qOffsetX ) * scale, qOffsetY * scale )
            elseif queueAnchor:sub( 1, 3)  == "TOP" then
                local dir, align = "TOP", queueAnchor:sub(4)
                b:SetPoint( getInverseDirection(dir) .. align, "Hekili_" .. dispID .. "_B1", dir .. align, 0, ( borderOffset + qOffsetY ) * scale )
            else -- BOTTOM
                local dir, align = "BOTTOM", queueAnchor:sub(7)
                b:SetPoint( getInverseDirection(dir) .. align, "Hekili_" .. dispID .. "_B1", dir .. align, 0, -1 * ( borderOffset + qOffsetY ) * scale )
            end
        else
            local queueDirection = conf.queue.direction or "RIGHT"
            local btnSpacing = borderOffset + ( conf.queue.spacing or 5 )

            b:ClearAllPoints()

            if queueDirection == "RIGHT" then
                b:SetPoint( getInverseDirection(queueDirection), "Hekili_" .. dispID .. "_B" .. id - 1, queueDirection, btnSpacing * scale, 0 )
            elseif queueDirection == "LEFT" then
                b:SetPoint( getInverseDirection(queueDirection), "Hekili_" .. dispID .. "_B" .. id - 1, queueDirection, -1 * btnSpacing * scale, 0 )
            elseif queueDirection == "TOP" then
                b:SetPoint( getInverseDirection(queueDirection), "Hekili_" .. dispID .. "_B" .. id - 1, queueDirection, 0, btnSpacing * scale )
            else -- BOTTOM
                b:SetPoint( getInverseDirection(queueDirection), "Hekili_" .. dispID .. "_B" .. id - 1, queueDirection, 0, -1 * btnSpacing * scale )
            end
        end

        -- Mover Stuff.
        b:SetScript("OnMouseDown", Button_OnMouseDown)
        b:SetScript("OnMouseUp", Button_OnMouseUp)

        b:SetScript( "OnEnter", function( self )
            local H = Hekili

            --[[ if H.Config then
                GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" )
                GameTooltip:SetBackdropColor( 0, 0, 0, 0.8 )

                GameTooltip:SetText( "Hekili: " .. dispID  )
                GameTooltip:AddLine( "Left-click and hold to move.", 1, 1, 1 )
                GameTooltip:Show()
                self:SetMovable( true )

            else ]]
            if ( H.Pause and ns.queue[ dispID ] and ns.queue[ dispID ][ id ] ) then
                H:ShowDiagnosticTooltip( ns.queue[ dispID ][ id ] )
            end
        end )

        b:SetScript( "OnLeave", function(self)
            GameTooltip:Hide()
        end )

        Hekili:ProfileFrame( bName, b )

        b:EnableMouse( false )
        b:SetMovable( false )

        return b
    end
end

-- Builds and maintains the visible UI elements.
-- Buttons (as frames) are never deleted, but should get reused effectively.

local builtIns = {
    "Primary", "AOE", "Interrupts", "Defensives"
}

function Hekili:BuildUI()
    if not Masque then
        Masque = LibStub( "Masque", true )

        if Masque then
            Masque:Register( addon, MasqueUpdate, self )
            MasqueGroup = Masque:Group( addon )
        end
    end

    local LSM = LibStub( "LibSharedMedia-3.0" )

    ns.UI.Keyhandler = ns.UI.Keyhandler or CreateFrame( "Button", "Hekili_Keyhandler", UIParent )
    ns.UI.Keyhandler:RegisterForClicks( "AnyDown" )
    ns.UI.Keyhandler:SetScript( "OnClick", function( self, button, down )
        Hekili:FireToggle( button )
    end )

    Hekili:ProfileFrame( "KeyhandlerFrame", ns.UI.Keyhandler )

    local scaleFactor = self:GetScale()
    local mouseInteract = self.Pause

    -- Notification Panel
    local notif = self.DB.profile.notifications

    local f = ns.UI.Notification or CreateFrame( "Frame", "HekiliNotification", UIParent )

    f:SetSize( notif.width * scaleFactor, notif.height * scaleFactor )
    f:SetClampedToScreen( true )
    f:ClearAllPoints()
    f:SetPoint("CENTER", nil, "CENTER", notif.x, notif.y )

    f.Text = f.Text or f:CreateFontString( "HekiliNotificationText", "OVERLAY" )
    f.Text:SetAllPoints( f )
    f.Text:SetFont( LSM:Fetch( "font", notif.font ), notif.fontSize * scaleFactor, notif.fontStyle )
    f.Text:SetJustifyV("MIDDLE")
    f.Text:SetJustifyH("CENTER")
    f.Text:SetTextColor(1, 1, 1, 1)

    if not notif.enabled then f:Hide()
    else f.Text:SetText(nil); f:Show() end

    ns.UI.Notification = f
    -- End Notification Panel

    -- Dropdown Menu.
    ns.UI.Menu = ns.UI.Menu or CreateFrame("Frame", "HekiliMenu", UIParent, "UIDropDownMenuTemplate")

    -- Displays
    for disp in pairs( self.DB.profile.displays ) do
        self:CreateDisplay( disp )
    end

    self:UpdateDisplayVisibility()

    --if Hekili.Config then ns.StartConfiguration() end
    if MasqueGroup then
        MasqueGroup:ReSkin()
    end

    -- Check for a display that has been removed.
    for display, buttons in ipairs(ns.UI.Buttons) do
        if not Hekili.DB.profile.displays[display] then
            for i, _ in ipairs(buttons) do
                buttons[i]:Hide()
            end
        end
    end

    if Hekili.Config then
        ns.StartConfiguration(true)
    end
end

local T = ns.lib.Format.Tokens
local SyntaxColors = {}

function ns.primeTooltipColors()
    T = ns.lib.Format.Tokens
    --- Assigns a color to multiple tokens at once.
    local function Color(Code, ...)
        for Index = 1, select("#", ...) do
            SyntaxColors[select(Index, ...)] = Code
        end
    end
    Color( "|cffB266FF", T.KEYWORD ) -- Reserved Words

    Color( "|cffffffff", T.LEFTCURLY, T.RIGHTCURLY, T.LEFTBRACKET, T.RIGHTBRACKET, T.LEFTPAREN, T.RIGHTPAREN )

    Color( "|cffFF66FF", T.UNKNOWN,
        T.ADD,
        T.SUBTRACT,
        T.MULTIPLY,
        T.DIVIDE,
        T.POWER,
        T.MODULUS,
        T.CONCAT,
        T.VARARG,
        T.ASSIGNMENT,
        T.PERIOD,
        T.COMMA,
        T.SEMICOLON,
        T.COLON,
        T.SIZE,
        T.EQUALITY,
        T.NOTEQUAL,
        T.LT,
        T.LTE,
        T.GT,
        T.GTE )

    Color( "|cFFB2FF66", multiUnpack(ns.keys, ns.attr) )

    Color( "|cffFFFF00", T.NUMBER )
    Color( "|cff888888", T.STRING, T.STRING_LONG )
    Color( "|cff55cc55", T.COMMENT_SHORT, T.COMMENT_LONG )
    Color( "|cff55ddcc", -- Minimal standard Lua functions
        "assert",
        "error",
        "ipairs",
        "next",
        "pairs",
        "pcall",
        "print",
        "select",
        "tonumber",
        "tostring",
        "type",
        "unpack",
        -- Libraries
        "bit",
        "coroutine",
        "math",
        "string",
        "table"
    )
    Color( "|cffddaaff", -- Some of WoW's aliases for standard Lua functions
        -- math
        "abs",
        "ceil",
        "floor",
        "max",
        "min",
        -- string
        "format",
        "gsub",
        "strbyte",
        "strchar",
        "strconcat",
        "strfind",
        "strjoin",
        "strlower",
        "strmatch",
        "strrep",
        "strrev",
        "strsplit",
        "strsub",
        "strtrim",
        "strupper",
        "tostringall",
        -- table
        "sort",
        "tinsert",
        "tremove",
        "wipe" )
end


local SpaceLeft = {"(%()"}
local SpaceRight = {"(%))"}
local DoubleSpace = {"(!=)", "(~=)", "(>=*)", "(<=*)", "(&)", "(||)", "(+)", "(*)", "(-)", "(/)"}


local function Format(Code)
    for Index = 1, #SpaceLeft do
        Code = Code:gsub("%s-" .. SpaceLeft[Index] .. "%s-", " %1")
    end

    for Index = 1, #SpaceRight do
        Code = Code:gsub("%s-" .. SpaceRight[Index] .. "%s-", "%1 ")
    end

    for Index = 1, #DoubleSpace do
        Code = Code:gsub("%s-" .. DoubleSpace[Index] .. "%s-", " %1 ")
    end

    Code = Code:gsub("([^<>~!])(=+)", "%1 %2 ")
    Code = Code:gsub("%s+", " "):trim()
    return Code
end


local key_cache = setmetatable( {}, {
    __index = function( t, k )
        t[k] = k:gsub( "(%S+)%[(%d+)]", "%1.%2" )
        return t[k]
    end
})


function Hekili:ShowDiagnosticTooltip( q )
    local tt = GameTooltip
    local fmt = ns.lib.Format

    -- Grab the default backdrop and copy it with a solid background.
    local backdrop = GameTooltip:GetBackdrop()

    if backdrop then
        backdrop.bgFile = [[Interface\Buttons\WHITE8X8]]
        tt:SetBackdrop(backdrop)
        tt:SetBackdropColor(0, 0, 0, 1)
    end

    tt:SetOwner(UIParent, "ANCHOR_CURSOR")
    tt:SetText(class.abilities[q.actionName].name)
    tt:AddDoubleLine(q.listName .. " #" .. q.action, "+" .. ns.formatValue(round(q.time or 0, 2)), 1, 1, 1, 1, 1, 1)

    if q.resources and q.resources[q.resource_type] then
        tt:AddDoubleLine(q.resource_type, ns.formatValue(q.resources[q.resource_type]), 1, 1, 1, 1, 1, 1)
    end

    if q.HookHeader or (q.HookScript and q.HookScript ~= "") then
        if q.HookHeader then
            tt:AddLine("\n" .. q.HookHeader)
        else
            tt:AddLine("\nHook Criteria")
        end

        if q.HookScript and q.HookScript ~= "" then
            local Text = Format(q.HookScript)
            tt:AddLine(fmt.FormatCode(Text, 0, SyntaxColors), 1, 1, 1, 1)
        end

        if q.HookElements then
            local applied = false
            for k, v in orderedPairs(q.HookElements) do
                if not applied then
                    tt:AddLine("Values")
                    applied = true
                end
                if not key_cache[k]:find( "safebool" ) and not key_cache[k]:find( "safenum" ) then
                    tt:AddDoubleLine( key_cache[ k ], ns.formatValue(v), 1, 1, 1, 1, 1, 1)
                end
            end
        end
    end

    if q.ReadyScript and q.ReadyScript ~= "" then
        tt:AddLine("\nTime Script")

        local Text = Format(q.ReadyScript)
        tt:AddLine(fmt.FormatCode(Text, 0, SyntaxColors), 1, 1, 1, 1)

        if q.ReadyElements then
            tt:AddLine("Values")
            for k, v in orderedPairs(q.ReadyElements) do
                if not key_cache[k]:find( "safebool" ) and not key_cache[k]:find( "safenum" ) then
                    tt:AddDoubleLine( key_cache[ k ], ns.formatValue(v), 1, 1, 1, 1, 1, 1)
                end
            end
        end
    end

    if q.ActScript and q.ActScript ~= "" then
        tt:AddLine("\nAction Criteria")

        local Text = Format(q.ActScript)
        tt:AddLine(fmt.FormatCode(Text, 0, SyntaxColors), 1, 1, 1, 1)

        if q.ActElements then
            tt:AddLine("Values")
            for k, v in orderedPairs(q.ActElements) do
                if not key_cache[k]:find( "safebool" ) and not key_cache[k]:find( "safenum" ) then
                    tt:AddDoubleLine( key_cache[ k ], ns.formatValue(v), 1, 1, 1, 1, 1, 1)
                end
            end
        end
    end
    tt:Show()
end

function Hekili:SaveCoordinates()
    for i in pairs(Hekili.DB.profile.displays) do
        local _, _, rel, x, y = ns.UI.Displays[i]:GetPoint()

        self.DB.profile.displays[i].rel = "CENTER"
        self.DB.profile.displays[i].x = x
        self.DB.profile.displays[i].y = y
    end

    _, _, _, self.DB.profile.notifications.x, self.DB.profile.notifications.y = HekiliNotification:GetPoint()
end
