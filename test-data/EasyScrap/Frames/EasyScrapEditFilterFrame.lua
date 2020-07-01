local EasyScrap = EasyScrap
local filterChoiceMenu = nil

local editFilterFrame = CreateFrame('Frame', 'EasyScrapEditFilterFrame', EasyScrap.parentFrame)
editFilterFrame:SetAllPoints()
editFilterFrame:Hide()

editFilterFrame.header = editFilterFrame:CreateFontString()
editFilterFrame.header:SetFontObject('GameFontNormalLarge')
editFilterFrame.header:SetText('Edit Filter')
editFilterFrame.header:SetPoint('TOP', 0, -24)

local filterEntriesFrame = CreateFrame('Frame', nil, editFilterFrame)
filterEntriesFrame:SetPoint('TOPLEFT', 12, -50)
filterEntriesFrame:SetSize(273, 204)
filterEntriesFrame:SetBackdrop({
    -- bgFile="Interface\\FrameGeneral\\UI-Background-Marble", 
    edgeFile='Interface/Tooltips/UI-Tooltip-Border', 
    tile = false, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }})
filterEntriesFrame:SetBackdropBorderColor(.9, .9, .9, 1)

filterEntriesFrame.bg = filterEntriesFrame:CreateTexture(nil, 'BACKGROUND')
filterEntriesFrame.bg:SetPoint('TOPLEFT', 4, -4)
filterEntriesFrame.bg:SetPoint('BOTTOMRIGHT', -4, 4)
filterEntriesFrame.bg:SetColorTexture(0, 0, 0, 1)

local filterEntriesScrollFrame = CreateFrame('ScrollFrame', nil, filterEntriesFrame, 'UIPanelScrollFrameTemplate')
filterEntriesScrollFrame:SetPoint('TOPLEFT', 0, -4)
filterEntriesScrollFrame:SetPoint('BOTTOMRIGHT', 0, 4)
filterEntriesScrollFrame:SetClipsChildren(false)

filterEntriesScrollFrame:SetScript('OnScrollRangeChanged', ScrollFrame_OnScrollRangeChanged_EasyScrap)
filterEntriesScrollFrame.ScrollBar.scrollStep = 10
filterEntriesScrollFrame.ScrollBar.t = filterEntriesScrollFrame.ScrollBar:CreateTexture(nil, 'BACKGROUND')
filterEntriesScrollFrame.ScrollBar.t:SetAllPoints()
filterEntriesScrollFrame.ScrollBar.t:SetColorTexture(0, 0, 0, 0.6)

filterEntriesScrollFrame.contentFrame = CreateFrame('Frame', 'EasyScrapEditFilterContentFrame', filterEntriesScrollFrame)
filterEntriesScrollFrame.contentFrame:SetWidth(filterEntriesScrollFrame:GetWidth())
filterEntriesScrollFrame.contentFrame:SetHeight(filterEntriesScrollFrame:GetHeight())
filterEntriesScrollFrame:SetScrollChild(filterEntriesScrollFrame.contentFrame)

filterEntriesScrollFrame:SetScript('OnVerticalScroll', function() if DropDownList1:IsVisible() then DropDownList1:Hide() end end) 

local filterNameFrame = CreateFrame('Button', nil, filterEntriesScrollFrame.contentFrame)
filterNameFrame:SetSize(filterEntriesScrollFrame.contentFrame:GetWidth()-8, 24)
filterNameFrame:SetPoint('TOP', 0, -4)  

filterNameFrame.ruleDescription = filterNameFrame:CreateFontString()
filterNameFrame.ruleDescription:SetFontObject('GameFontNormalSmall')
filterNameFrame.ruleDescription:SetText('Filter name:')
filterNameFrame.ruleDescription:SetPoint('LEFT', 8, 0)

filterNameFrame.customData = CreateFrame('EditBox', nil, filterNameFrame, 'InputBoxTemplate')
filterNameFrame.customData:SetPoint('RIGHT', -20, 0) --8
filterNameFrame.customData:SetSize(100, 24)
filterNameFrame.customData:SetScript('OnEscapePressed', EditBox_ClearFocus)
filterNameFrame.customData:SetScript('OnEnterPressed', EditBox_ClearFocus)
filterNameFrame.customData:SetAutoFocus(false)
filterNameFrame.customData:SetMaxLetters(12)

local function saveRules()
    local customFilter = EasyScrap.saveData.customFilters[editFilterFrame.filterID]
    customFilter.name = filterNameFrame.customData:GetText()
    for i = 1, #customFilter.rules do
        if EasyScrap.filterTypes[customFilter.rules[i].filterType].frame.saveData then
            EasyScrap.filterTypes[customFilter.rules[i].filterType].frame:saveData(editFilterFrame.filterID)
        end
    end
end

local function updateRules(ruleAdded)
    local customFilter = EasyScrap.saveData.customFilters[editFilterFrame.filterID]   
    filterNameFrame.customData:SetText(customFilter.name)
    
    local maxScroll = 42
    local filterTypesVisible = {}
    local latestRuleFrame = nil
    for i = 1, #customFilter.rules do
        local rule = customFilter.rules[i]
        local ruleFrame = EasyScrap.filterTypes[rule.filterType].frame
        
        ruleFrame:ClearAllPoints()
        
        if not latestRuleFrame then
            ruleFrame:SetPoint('TOP', 0, -42)            
        else
            ruleFrame:SetPoint('TOP', latestRuleFrame, 'BOTTOM', 0, -12)
        end
        latestRuleFrame = ruleFrame
        
        ruleFrame:Show()
        if rule.data and ruleFrame.populateData then ruleFrame:populateData(rule.data) end
        ruleFrame.ruleIndex = i
        ruleFrame.deleteButton.ruleID = i
        
        --Disable entry in menu since we already have it
        for i = 2, #filterChoiceMenu do if filterChoiceMenu[i].filterType == rule.filterType then filterChoiceMenu[i].disabled = true end end
        
        filterTypesVisible[rule.filterType] = true
        maxScroll = maxScroll + latestRuleFrame:GetHeight()+12
    end
    
    for filterType, v in pairs(EasyScrap.filterTypes) do
        if not filterTypesVisible[filterType] then
            if v.frame then
                v.frame:Hide()
                --Enable entry
                for i = 2, #filterChoiceMenu do if filterChoiceMenu[i].filterType == filterType then filterChoiceMenu[i].disabled = false end end
            end
        end
    end
    
    maxScroll = maxScroll - filterEntriesScrollFrame:GetHeight()
    
    if maxScroll < 0 then maxScroll = 0 end
    if filterEntriesScrollFrame.ScrollBar:GetValue() > maxScroll then filterEntriesScrollFrame.ScrollBar:SetValue(maxScroll) end
    filterEntriesScrollFrame.ScrollBar:SetMinMaxValues(0, maxScroll)
    
    if ruleAdded then
        filterEntriesScrollFrame.ScrollBar:SetValue(9999)
    end
end

editFilterFrame.deleteRuleEntry = function(ruleID)
    local customFilter = EasyScrap.saveData.customFilters[editFilterFrame.filterID]   

    table.remove(customFilter.rules, ruleID)
    updateRules()
end

local function addRuleEntry(filterType)
    saveRules()
    local customFilter = EasyScrap.saveData.customFilters[editFilterFrame.filterID]
    local filterData = EasyScrap.filterTypes[filterType]
    local newRule = {}
    newRule.filterType = filterType

    if filterData.data then
        newRule.data = {}
        for k,v in pairs(filterData.data) do
            newRule.data[k] = v
        end
    end

    table.insert(customFilter.rules, newRule)
    
    if DropDownList1:IsVisible() then DropDownList1:Hide() end

    updateRules(true)
end

editFilterFrame:SetScript('OnShow', function(self)
    if not filterChoiceMenu then
        filterChoiceMenu = {}
        filterChoiceMenu[1] = {text="Categories", notCheckable = true, isTitle = true}
        for k,v in pairs(EasyScrap.filterTypes) do
            local newEntry = {}
            newEntry.text = v.menuText
            newEntry.filterType = k
            newEntry.notCheckable = true
            newEntry.hasArrow = false
            newEntry.menuList = {}
            newEntry.func = function() addRuleEntry(k) end
    
            filterChoiceMenu[v.order+1] = newEntry
        end   
    end
    updateRules()
end)

editFilterFrame.addRule = CreateFrame('Button', nil, editFilterFrame, 'GameMenuButtonTemplate')
editFilterFrame.addRule:SetSize(96, 24)
editFilterFrame.addRule:SetPoint('BOTTOMLEFT', 16, 12)
editFilterFrame.addRule:SetText('Add Rule')
editFilterFrame.addRule.dropDown = CreateFrame("Frame", "EasyScrap_AddFilterEntryDropDown", editFilterFrame.addRule, "UIDropDownMenuTemplate")
editFilterFrame.addRule:SetScript('OnClick', function()
    if DropDownList1:IsVisible() then 
        DropDownList1:Hide() 
    else
        EasyMenu(filterChoiceMenu, editFilterFrame.addRule.dropDown, editFilterFrame.addRule, 0, 0, "MENU", 1)
    end
end)

editFilterFrame.dismissButton = CreateFrame('Button', nil, editFilterFrame, 'GameMenuButtonTemplate')
editFilterFrame.dismissButton:SetSize(96, 24)
editFilterFrame.dismissButton:SetPoint('BOTTOMRIGHT', -16, 12)
editFilterFrame.dismissButton:SetText('Done')
editFilterFrame.dismissButton:SetScript('OnClick', function()
    saveRules()
    
    editFilterFrame:Hide()
    EasyScrap.filterFrame:Show()
end)

EasyScrap.editFilterFrame = editFilterFrame