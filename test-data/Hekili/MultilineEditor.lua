-- MultilineEditor.lua
-- Revised MultiLineEditBox, to allow for my own tweaks.

local addon, ns = ...
local Hekili = _G[ addon ]

local Type, Version = "HekiliCustomEditor", 2
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local GetCursorInfo, GetSpellInfo, ClearCursor = GetCursorInfo, GetSpellInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = _G

-- local utilities
local multiUnpack = ns.multiUnpack
local formatValue = ns.lib.formatValue
local orderedPairs = ns.orderedPairs

local class   = Hekili.Class
local scripts = Hekili.Scripts
local state   = Hekili.State

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: ACCEPT, ChatFontNormal

local wowMoP
do
  local _, _, _, interface = GetBuildInfo()
  wowMoP = (interface >= 50000)
end


--[[-----------------------------------------------------------------------------

Support functions

-------------------------------------------------------------------------------]]

if not HekiliCustomEditorInsertLink then
  -- upgradeable hook
  hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.HekiliCustomEditorInsertLink(...) end)
end

function _G.HekiliCustomEditorInsertLink(text)
  for i = 1, AceGUI:GetWidgetCount(Type) do
    local editbox = _G[("HekiliCustomEditor%uEdit"):format(i)]
    if editbox and editbox:IsVisible() and editbox:HasFocus() then
      editbox:Insert(text)
      return true
    end
  end
end


local function Layout(self)
  self:SetHeight(self.numlines * 14 + (self.disablebutton and 19 or 41) + self.labelHeight)

  if self.labelHeight == 0 then
    self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
  else
    self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
  end

  if self.disablebutton then
    self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
    self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
  else
    self.scrollBar:SetPoint("BOTTOM", self.button, "TOP", 0, 18)
    self.scrollBG:SetPoint("BOTTOMLEFT", self.button, "TOPLEFT")
  end
end

--[[-----------------------------------------------------------------------------

Scripts

-------------------------------------------------------------------------------]]
local function OnClick(self)                                                     -- Button
  self = self.obj
  self.editBox:ClearFocus()
  if not self:Fire("OnEnterPressed", self.editBox:GetText()) then
    self.button:Disable()
  end
end

local function OnCursorChanged(self, _, y, _, cursorHeight)                      -- EditBox
  self, y = self.obj.scrollFrame, -y
  local offset = self:GetVerticalScroll()
  if y < offset then
    self:SetVerticalScroll(y)
  else
    y = y + cursorHeight - self:GetHeight()
    if y > offset then
      self:SetVerticalScroll(y)
    end
  end
end

local function OnEditFocusLost(self)                                             -- EditBox
  self:HighlightText(0, 0)
  self.obj:Fire("OnEditFocusLost")
end


--Is the member Inherited from parent options
local isInherited = {
  set = true,
  get = true,
  func = true,
  confirm = true,
  validate = true,
  disabled = true,
  hidden = true
}

--Does a string type mean a literal value, instead of the default of a method of the handler
local stringIsLiteral = {
  name = true,
  desc = true,
  icon = true,
  usage = true,
  width = true,
  image = true,
  fontSize = true,
}

--Is Never a function or method
local allIsLiteral = {
  type = true,
  descStyle = true,
  imageWidth = true,
  imageHeight = true,
}


--gets an option from a given group, checking plugins
local function GetSubOption(group, key)
  if group.plugins then
    for plugin, t in pairs(group.plugins) do
      if t[key] then
        return t[key]
      end
    end
  end

  return group.args[key]
end


local function GetOptionsMemberValue(membername, option, options, path, appName, ...)
  --get definition for the member
  local inherits = isInherited[membername]

  --get the member of the option, traversing the tree if it can be inherited
  local member

  if inherits then
    local group = options
    if group[membername] ~= nil then
      member = group[membername]
    end
    for i = 1, #path do
      group = GetSubOption(group, path[i])
      if group[membername] ~= nil then
        member = group[membername]
      end
    end
  else
    member = option[membername]
  end

  --check if we need to call a functon, or if we have a literal value
  if ( not allIsLiteral[membername] ) and ( type(member) == "function" or ((not stringIsLiteral[membername]) and type(member) == "string") ) then
    --We have a function to call
    local info = {}
    --traverse the options table, picking up the handler and filling the info with the path
    local handler
    local group = options
    handler = group.handler or handler

    for i = 1, #path do
      group = GetSubOption(group, path[i])
      info[i] = path[i]
      handler = group.handler or handler
    end

    info.options = options
    info.appName = appName
    info[0] = appName
    info.arg = option.arg
    info.handler = handler
    info.option = option
    info.type = option.type
    info.uiType = "dialog"
    info.uiName = appName

    local a, b, c ,d
    --using 4 returns for the get of a color type, increase if a type needs more
    if type(member) == "function" then
      --Call the function
      a,b,c,d = member(info, ...)
    else
      --Call the method
      if handler and handler[member] then
        a,b,c,d = handler[member](handler, info, ...)
      else
        error(format("Method %s doesn't exist in handler for type %s", member, membername))
      end
    end
    table.wipe(info)
    return a,b,c,d
  else
    --The value isnt a function to call, return it
    return member
  end
end


local key_cache = setmetatable( {}, {
    __index = function( t, k )
        t[k] = k:gsub( "(%S+)%[(%d+)%]", "%1.%2" )
        return t[k]
    end
} )


local function GenerateDiagnosticTooltip( widget, event )
    --show a tooltip/set the status bar to the desc text
    local user = widget:GetUserDataTable()
    local opt = user.option
    local options = user.options
    local path = user.path
    local appName = user.appName

    local name    = GetOptionsMemberValue( "name",  opt, options, path, appName )
    local arg, listName, actID = GetOptionsMemberValue( "arg", opt, options, path, appName )
    local desc    = GetOptionsMemberValue( "desc",  opt, options, path, appName )
    local usage   = GetOptionsMemberValue( "usage", opt, options, path, appName )
    local descStyle = opt.descStyle

    if descStyle and descStyle ~= "tooltip" then return end

    GameTooltip:SetOwner( widget.frame, "ANCHOR_TOPRIGHT" )
    GameTooltip:SetText(name, 1, .82, 0, 1)

    if type( arg ) == "string" then
        GameTooltip:AddLine(arg, 1, 1, 1, 1)
    end

    local tested = false

    local packName, script = path[ 2 ], path[ #path ]
    -- print( unpack( path ) )

    local pack = rawget( Hekili.DB.profile.packs, packName )
    local list = pack and pack.lists[ listName ]
    local entry = list and list[ actID ]

    if pack and list and entry then
        local scriptID = packName .. ":" .. listName .. ":" .. actID
        local action = entry.action

        if script == 'criteria' then
            local result, warning = scripts:CheckScript( scriptID, action )

            GameTooltip:AddDoubleLine( "Shown", ns.formatValue( result ), 1, 1, 1, 1, 1, 1 )

            if warning then GameTooltip:AddLine( warning, 1, 0, 0 ) end

        else
            local result, warning = scripts:CheckScript( scriptID, action, script )

            GameTooltip:AddLine( ns.formatValue( result ), 1, 1, 1, 1 )

            if warning then GameTooltip:AddLine( warning, 1, 0, 0 ) end
            -- handle other types.
        end

        tested = true
    end

    local has_args = arg and ( next(arg) ~= nil )

    if has_args then
        if tested then GameTooltip:AddLine(" ") end

        GameTooltip:AddLine( "Values" )
        for k, v in orderedPairs( arg ) do
          if not key_cache[k]:find( "safebool" ) and not key_cache[k]:find( "safenum" ) then
            GameTooltip:AddDoubleLine( key_cache[ k ], ns.formatValue( v ), 1, 1, 1, 1, 1, 1 )
          end
        end
    end

    if type( usage ) == "string" then
        GameTooltip:AddLine( "Usage: "..usage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1 )
    end

    GameTooltip:Show()

end



local function OnEnter(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if not self.entered then
    self.entered = true
    GenerateDiagnosticTooltip(self, "OnEnter")
  end
end


local function OnLeave(self)                                                     -- EditBox / ScrollFrame
  self = self.obj
  if self.entered then
    self.entered = nil
    GameTooltip:Hide()
    self:Fire("OnLeave")
  end
end

local function OnMouseUp(self)                                                   -- ScrollFrame
  self = self.obj.editBox
  self:SetFocus()
  self:SetCursorPosition(self:GetNumLetters())
end

local function OnReceiveDrag(self)                                               -- EditBox / ScrollFrame
  local type, id, info = GetCursorInfo()
  if type == "spell" then
    info = GetSpellInfo(id, info)
  elseif type ~= "item" then
    return
  end
  ClearCursor()
  self = self.obj
  local editBox = self.editBox
  if not editBox:HasFocus() then
    editBox:SetFocus()
    editBox:SetCursorPosition(editBox:GetNumLetters())
  end
  editBox:Insert(info)
  self.button:Enable()
end

local function OnSizeChanged(self, width, height)                                -- ScrollFrame
  self.obj.editBox:SetWidth(width)
end

local function OnTextChanged(self, userInput)                                    -- EditBox
  if userInput then
    self = self.obj
    self:Fire("OnTextChanged", self.editBox:GetText())
    self.button:Enable()
end
end

local function OnTextSet(self)                                                   -- EditBox
  self:HighlightText(0, 0)
  self:SetCursorPosition(self:GetNumLetters())
  self:SetCursorPosition(0)
  if self.Coloring then
    self.Coloring = nil
  else
    self.obj.button:Disable()
  end
end

local function OnVerticalScroll(self, offset)                                    -- ScrollFrame
  local editBox = self.obj.editBox
  editBox:SetHitRectInsets(0, 0, offset, editBox:GetHeight() - offset - self:GetHeight())
end

local function OnShowFocus(frame)
  frame.obj.editBox:SetFocus()
  frame:SetScript("OnShow", nil)
end

local function OnEditFocusGained(frame)
  AceGUI:SetFocus(frame.obj)
  frame.obj:Fire("OnEditFocusGained")
end

--[[-----------------------------------------------------------------------------

Methods

-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self.editBox:SetText("")
    self:SetDisabled(false)
    self:SetWidth(200)
    self:DisableButton(false)
    self:SetNumLines()
    self.entered = nil
    self:SetMaxLetters(0)
  end,

  ["OnRelease"] = function(self)
    self:ClearFocus()
  end,

  ["SetDisabled"] = function(self, disabled)
    local editBox = self.editBox
    if disabled then
      editBox:ClearFocus()
      editBox:EnableMouse(false)
      editBox:SetTextColor(0.5, 0.5, 0.5)
      self.label:SetTextColor(0.5, 0.5, 0.5)
      self.scrollFrame:EnableMouse(false)
      self.button:Disable()
    else
      editBox:EnableMouse(true)
      editBox:SetTextColor(1, 1, 1)
      self.label:SetTextColor(1, 0.82, 0)
      self.scrollFrame:EnableMouse(true)
    end
  end,

  ["SetLabel"] = function(self, text)
    if text and text ~= "" then
      self.label:SetText(text)
      if self.labelHeight ~= 10 then
        self.labelHeight = 10
        self.label:Show()
      end
    elseif self.labelHeight ~= 0 then
      self.labelHeight = 0
      self.label:Hide()
    end
    Layout(self)
  end,

  ["SetNumLines"] = function(self, value)
    if not value or value < 4 then
      value = 4
    end
    self.numlines = value
    Layout(self)
  end,

  ["SetText"] = function(self, text)
    self.editBox:SetText(text)
  end,

  ["GetText"] = function(self)
    return self.editBox:GetText()
  end,

  ["SetMaxLetters"] = function (self, num)
    self.editBox:SetMaxLetters(num or 0)
  end,

  ["DisableButton"] = function(self, disabled)
    self.disablebutton = disabled
    if disabled then
      self.button:Hide()
    else
      self.button:Show()
    end
    Layout(self)
  end,

  ["ClearFocus"] = function(self)
    self.editBox:ClearFocus()
    self.frame:SetScript("OnShow", nil)
  end,

  ["SetFocus"] = function(self)
    self.editBox:SetFocus()
    if not self.frame:IsShown() then
      self.frame:SetScript("OnShow", OnShowFocus)
    end
  end,

  ["GetCursorPosition"] = function(self)
    return self.editBox:GetCursorPosition()
  end,

  ["SetCursorPosition"] = function(self, ...)
    return self.editBox:SetCursorPosition(...)
  end,


}

--[[-----------------------------------------------------------------------------

Constructor

-------------------------------------------------------------------------------]]
local backdrop = {
  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
  edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
  insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)
  frame:Hide()

  local widgetNum = AceGUI:GetNextWidgetNum(Type)

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
  label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
  label:SetJustifyH("LEFT")
  label:SetText(ACCEPT)
  label:SetHeight(10)

  local button = CreateFrame("Button", ("%s%dButton"):format(Type, widgetNum), frame, wowMoP and "UIPanelButtonTemplate" or "UIPanelButtonTemplate2")
  button:SetPoint("BOTTOMLEFT", 0, 4)
  button:SetHeight(22)
  button:SetWidth(label:GetStringWidth() + 24)
  button:SetText(ACCEPT)
  button:SetScript("OnClick", OnClick)
  button:Disable()

  local text = button:GetFontString()
  text:ClearAllPoints()
  text:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
  text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
  text:SetJustifyV("MIDDLE")

  local scrollBG = CreateFrame("Frame", nil, frame)
  scrollBG:SetBackdrop(backdrop)
  scrollBG:SetBackdropColor(0, 0, 0)
  scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

  --scrollBG:SetBackdropBorderColor(1,0,0)

  local scrollFrame = CreateFrame("ScrollFrame", ("%s%dScrollFrame"):format(Type, widgetNum), frame, "UIPanelScrollFrameTemplate")

  local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
  scrollBar:ClearAllPoints()
  scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
  scrollBar:SetPoint("BOTTOM", button, "TOP", 0, 18)
  scrollBar:SetPoint("RIGHT", frame, "RIGHT")

  scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
  scrollBG:SetPoint("BOTTOMLEFT", button, "TOPLEFT")

  scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
  scrollFrame:SetScript("OnEnter", OnEnter)
  scrollFrame:SetScript("OnLeave", OnLeave)
  scrollFrame:SetScript("OnMouseUp", OnMouseUp)
  scrollFrame:SetScript("OnReceiveDrag", OnReceiveDrag)
  scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
  scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll)

  local editBox = CreateFrame("EditBox", ("%s%dEdit"):format(Type, widgetNum), scrollFrame)
  editBox:SetAllPoints()
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetMultiLine(true)
  editBox:EnableMouse(true)
  editBox:SetAutoFocus(false)
  editBox:SetCountInvisibleLetters(false)
  editBox:SetScript("OnCursorChanged", OnCursorChanged)
  editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
  editBox:SetScript("OnEnter", OnEnter)
  editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
  editBox:SetScript("OnLeave", OnLeave)
  editBox:SetScript("OnMouseDown", OnReceiveDrag)
  editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
  editBox:SetScript("OnTextChanged", OnTextChanged)
  editBox:SetScript("OnTextSet", OnTextSet)
  editBox:SetScript("OnEditFocusGained", OnEditFocusGained)

  if ns.lib.Format then
    local T = ns.lib.Format.Tokens;

    local SyntaxColors = {};
    --- Assigns a color to multiple tokens at once.
    local function Color ( Code, ... )
      for Index = 1, select( "#", ... ) do
        SyntaxColors[ select( Index, ... ) ] = Code;
      end
    end
    Color( "|cffB266FF", T.KEYWORD ) -- Reserved words

    Color( "|cffffffff", T.LEFTCURLY, T.RIGHTCURLY,
      T.LEFTBRACKET, T.RIGHTBRACKET,
      T.LEFTPAREN, T.RIGHTPAREN )

    Color( "|cffFF66FF", T.UNKNOWN, T.ADD, T.SUBTRACT, T.MULTIPLY, T.DIVIDE, T.POWER, T.MODULUS,
      T.CONCAT, T.VARARG, T.ASSIGNMENT, T.PERIOD, T.COMMA, T.SEMICOLON, T.COLON, T.SIZE,
      T.EQUALITY, T.NOTEQUAL, T.LT, T.LTE, T.GT, T.GTE )

    Color( "|cFFB2FF66", unpack( ns.keys ) )

    Color( "|cffFFFF00", T.NUMBER )
    Color( "|cff888888", T.STRING, T.STRING_LONG )
    Color( "|cff55cc55", T.COMMENT_SHORT, T.COMMENT_LONG )

    Color( "|cff55ddcc", -- Minimal standard Lua functions
      "assert", "error", "ipairs", "next", "pairs", "pcall", "print", "select",
      "tonumber", "tostring", "type", "unpack",
      -- Libraries
      "bit", "coroutine", "math", "string", "table" )

    Color( "|cffddaaff", -- Some of WoW's aliases for standard Lua functions
      -- math
      "abs", "ceil", "floor", "max", "min",
      -- string
      "format", "gsub", "strbyte", "strchar", "strconcat", "strfind", "strjoin",
      "strlower", "strmatch", "strrep", "strrev", "strsplit", "strsub", "strtrim",
      "strupper", "tostringall",
      -- table
      "sort", "tinsert", "tremove", "wipe" )

    ns.lib.Format.Enable( editBox, 4, SyntaxColors, true )
  end

  scrollFrame:SetScrollChild(editBox)

  local widget = {
    button      = button,
    editBox     = editBox,
    frame       = frame,
    label       = label,
    labelHeight = 10,
    numlines    = 4,
    scrollBar   = scrollBar,
    scrollBG    = scrollBG,
    scrollFrame = scrollFrame,
    type        = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end
  button.obj, editBox.obj, scrollFrame.obj = widget, widget, widget

  local hcv = AceGUI:RegisterAsWidget(widget)

  if ElvUI then
    local E = ElvUI[1]

    if E.private.skins.ace3.enable then
      local S = E:GetModule('Skins')

      local frame = hcv.frame

      if not hcv.scrollBG.template then
        hcv.scrollBG:SetTemplate()
      end

      S:HandleButton(hcv.button)
      S:HandleScrollBar(hcv.scrollBar)
      hcv.scrollBar:Point('RIGHT', frame, 'RIGHT', 0 -4)
      hcv.scrollBG:Point('TOPRIGHT', hcv.scrollBar, 'TOPLEFT', -2, 19)
      hcv.scrollBG:Point('BOTTOMLEFT', hcv.button, 'TOPLEFT')
      hcv.scrollFrame:Point('BOTTOMRIGHT', hcv.scrollBG, 'BOTTOMRIGHT', -4, 8)
    end
  end

  return hcv
end


AceGUI:RegisterWidgetType(Type, Constructor, Version)
