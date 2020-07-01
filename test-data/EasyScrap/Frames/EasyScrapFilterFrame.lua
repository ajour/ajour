local EasyScrap = EasyScrap
local filterEntryFrames = {}

local filterFrame = CreateFrame('Frame', nil, EasyScrap.parentFrame)
filterFrame:SetAllPoints()
filterFrame:Hide()

filterFrame.header = filterFrame:CreateFontString()
filterFrame.header:SetFontObject('GameFontNormalLarge')
filterFrame.header:SetText('Manage Filters')
filterFrame.header:SetPoint('TOP', 0, -24)

local filterListFrame = CreateFrame('Frame', 'EasyScrapFilterListFrame', filterFrame)
filterListFrame:SetPoint('TOPLEFT', 12, -50)
filterListFrame:SetSize(273, 200)
filterListFrame:SetBackdrop({
    -- bgFile="Interface\\FrameGeneral\\UI-Background-Marble", 
    edgeFile='Interface/Tooltips/UI-Tooltip-Border', 
    tile = false, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }})
filterListFrame:SetBackdropBorderColor(.9, .9, .9, 1)

filterListFrame.bg = filterListFrame:CreateTexture(nil, 'BACKGROUND')
filterListFrame.bg:SetPoint('TOPLEFT', 4, -4)
filterListFrame.bg:SetPoint('BOTTOMRIGHT', -4, 4)
filterListFrame.bg:SetColorTexture(0, 0, 0, 1)

local filterListScrollFrame = CreateFrame('ScrollFrame', nil, filterListFrame, 'UIPanelScrollFrameTemplate')
filterListScrollFrame:SetPoint('TOPLEFT', 0, -4)
filterListScrollFrame:SetPoint('BOTTOMRIGHT', 0, 4)
filterListScrollFrame:SetClipsChildren(false)

filterListScrollFrame:SetScript('OnScrollRangeChanged', ScrollFrame_OnScrollRangeChanged_EasyScrap)
filterListScrollFrame.ScrollBar.scrollStep = 10
filterListScrollFrame.ScrollBar.t = filterListScrollFrame.ScrollBar:CreateTexture(nil, 'BACKGROUND')
filterListScrollFrame.ScrollBar.t:SetAllPoints()
filterListScrollFrame.ScrollBar.t:SetColorTexture(0, 0, 0, 0.6)

filterListScrollFrame.contentFrame = CreateFrame('Frame', nil, filterListScrollFrame)
filterListScrollFrame.contentFrame:SetWidth(filterListScrollFrame:GetWidth())
filterListScrollFrame.contentFrame:SetHeight(filterListScrollFrame:GetHeight())
filterListScrollFrame:SetScrollChild(filterListScrollFrame.contentFrame)

local function createFilterFrame(i)
    local frame = CreateFrame('Frame', nil, filterListScrollFrame.contentFrame)
    frame:SetSize(filterListScrollFrame:GetWidth()-8, 24)
    if i == 0 then
        frame:SetPoint('TOP', 0, -4)
    else
        frame:SetPoint('TOP', filterEntryFrames[i-1], 'BOTTOM', 0, 0)
    end
    
    frame.name = frame:CreateFontString()
    frame.name:SetFontObject('GameFontNormal')
    frame.name:SetText('Filter#123')
    --frame.name:SetTextColor(1, 1, 1, 1)
    frame.name.r, frame.name.g, frame.name.b = frame.name:GetTextColor() 
    frame.name:SetPoint('LEFT', 18, 0)
    
    frame.selectButton = CreateFrame('Button', nil, frame)
    frame.selectButton:SetPoint('LEFT', 2, 0)
    frame.selectButton:SetSize(134, frame:GetHeight())
    frame.selectButton:SetScript('OnEnter', function()
        frame.name:SetTextColor(1, 1, 1, 1)
        if frame.filterID ~= EasyScrap.saveData.addonSettings.defaultFilter then
            --frame.defaultFilterSelected:SetTexCoord(0.00390625, 0.08593750, 0.71093750, 0.87500000)
            --filterEntryFrames[EasyScrap.saveData.addonSettings.defaultFilter].defaultFilterSelected:SetAlpha(0.33)
        end
    end)
    
    frame.selectButton:SetScript('OnLeave', function()
        frame.name:SetTextColor(frame.name.r, frame.name.g, frame.name.b)
        if frame.filterID ~= EasyScrap.saveData.addonSettings.defaultFilter then
            --frame.defaultFilterSelected:SetTexCoord(0.09375000, 0.17578125, 0.71093750, 0.87500000)
            --filterEntryFrames[EasyScrap.saveData.addonSettings.defaultFilter].defaultFilterSelected:SetAlpha(1)
        end
    end)
    
    frame.selectButton:SetScript('OnClick', function()
        --filterEntryFrames[EasyScrap.saveData.addonSettings.defaultFilter].defaultFilterSelected:SetAlpha(1)
        filterEntryFrames[EasyScrap.saveData.addonSettings.defaultFilter].defaultFilterSelected:SetTexCoord(0.09375000, 0.17578125, 0.71093750, 0.87500000)
        EasyScrap.saveData.addonSettings.defaultFilter = frame.filterID
        frame.defaultFilterSelected:SetTexCoord(0.00390625, 0.08593750, 0.71093750, 0.87500000)
        filterFrame:drawFilters()
    end)
    
    frame.defaultFilterSelected = frame:CreateTexture(nil, 'ARTWORK')
    frame.defaultFilterSelected:SetSize(14, 14)
    frame.defaultFilterSelected:SetTexture('Interface/PlayerFrame/MonkUI')
    frame.defaultFilterSelected:SetTexCoord(0.09375000, 0.17578125, 0.71093750, 0.87500000)
    frame.defaultFilterSelected:SetPoint('LEFT', 2, 0)
    
    frame.deleteButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
    frame.deleteButton:SetSize(32, 18)
    frame.deleteButton:SetPoint('RIGHT', -8, 0)
    frame.deleteButton:SetText('X')
    frame.deleteButton:SetScript('OnClick', function(self) EasyScrap:deleteCustomFilter(frame.filterID) filterFrame:drawFilters() end)
    
    frame.editButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
    frame.editButton:SetSize(48, 18)
    frame.editButton:SetPoint('RIGHT', frame.deleteButton, 'LEFT', -2, 0)
    frame.editButton:SetText('Edit')
    frame.editButton:SetScript('OnClick', function(self) filterFrame:Hide() EasyScrap.editFilterFrame.filterID = frame.filterID EasyScrap.editFilterFrame:Show() end)
    return frame
end

filterEntryFrames[0] = createFilterFrame(0)
filterEntryFrames[0].name:SetText(EasyScrap.defaultFilter.name)
filterEntryFrames[0].deleteButton:Disable()
filterEntryFrames[0].editButton:Disable()
filterEntryFrames[0].filterID = 0

local infoFrame = CreateFrame('Frame', nil, filterListScrollFrame.contentFrame)
infoFrame:SetSize(filterListScrollFrame.contentFrame:GetWidth(), 24)
infoFrame:SetPoint('TOP', 0, -4)

infoFrame.line = infoFrame:CreateTexture(nil, 'BACKGROUND')
infoFrame.line:SetColorTexture(filterEntryFrames[0].name.r, filterEntryFrames[0].name.g, filterEntryFrames[0].name.b, 0.75)
infoFrame.line:SetSize(filterListScrollFrame.contentFrame:GetWidth()-24, 1)
infoFrame.line:SetPoint('TOP', 0, 0)

infoFrame.subText = infoFrame:CreateFontString()
infoFrame.subText:SetFontObject("GameFontNormalSmall")
infoFrame.subText:SetText("Click on the name of a filter to set it as the default filter.")
infoFrame.subText:SetTextColor(1, 1, 1, 1)
infoFrame.subText:SetWidth(filterListScrollFrame.contentFrame:GetWidth()-24)
infoFrame.subText:SetPoint('TOP', infoFrame.line, 'BOTTOM', 0, -4)

function filterFrame:drawFilters()
    local lastFilterFrame
    for i = 1, #EasyScrap.saveData.customFilters do
        if not filterEntryFrames[i] then filterEntryFrames[i] = createFilterFrame(i) end
        
        local filterEntryFrame = filterEntryFrames[i]
        local filterData = EasyScrap.saveData.customFilters[i]
        
        filterEntryFrame:Show()
        filterEntryFrame.filterID = i
        filterEntryFrame.name:SetText(filterData.name)
        filterEntryFrame.deleteButton:Enable()
        filterEntryFrame.editButton:Enable()     
        filterEntryFrame.defaultFilterSelected:SetTexCoord(0.09375000, 0.17578125, 0.71093750, 0.87500000)    

        lastFilterFrame = filterEntryFrame
    end
    
    if #filterEntryFrames > #EasyScrap.saveData.customFilters then
        for i = #EasyScrap.saveData.customFilters+1, #filterEntryFrames do
            filterEntryFrames[i]:Hide()
        end
    end
    
    infoFrame:ClearAllPoints()
    infoFrame:SetPoint('TOP', lastFilterFrame, 'BOTTOM', 0, -4)
    
    --Set default filter graphic
    filterEntryFrames[EasyScrap.saveData.addonSettings.defaultFilter].defaultFilterSelected:SetTexCoord(0.00390625, 0.08593750, 0.71093750, 0.87500000)
    
    local maxScroll = (#EasyScrap.saveData.customFilters+1)*filterEntryFrames[0]:GetHeight()+12+28
    maxScroll = maxScroll - filterListScrollFrame:GetHeight()
    
    if maxScroll < 0 then maxScroll = 0 end
    if filterListScrollFrame.ScrollBar:GetValue() > maxScroll then filterListScrollFrame.ScrollBar:SetValue(maxScroll) end
    filterListScrollFrame.ScrollBar:SetMinMaxValues(0, maxScroll)  

    filterFrame.header:SetText('Manage Filters ('..#EasyScrap.saveData.customFilters..')')
end

filterFrame:SetScript('OnShow', function(self)
    filterListScrollFrame.ScrollBar:SetValue(0)
    self:drawFilters() 
end)


filterFrame.createNewButton = CreateFrame('Button', nil, filterFrame, 'GameMenuButtonTemplate')
filterFrame.createNewButton:SetSize(108, 24)
filterFrame.createNewButton:SetPoint('BOTTOMLEFT', 16, 12)
filterFrame.createNewButton:SetText('Create Filter')
filterFrame.createNewButton:SetScript('OnClick', function()
    local filterID = EasyScrap:createNewCustomFilter()
    filterFrame:Hide()
    EasyScrap.editFilterFrame.filterID = filterID
    EasyScrap.editFilterFrame:Show()
end)

filterFrame.dismissButton = CreateFrame('Button', nil, filterFrame, 'GameMenuButtonTemplate')
filterFrame.dismissButton:SetSize(96, 24)
filterFrame.dismissButton:SetPoint('BOTTOMRIGHT', -16, 12)
filterFrame.dismissButton:SetText('Okay')
filterFrame.dismissButton:SetScript('OnClick', function()
    filterFrame:Hide()
    EasyScrap.mainFrame:Show()
end)

filterFrame.filterEntryFrames = filterEntryFrames
EasyScrap.filterFrame = filterFrame