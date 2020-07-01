local EasyScrap = EasyScrap

local parentFrame = CreateFrame('Frame', 'EasyScrapParentFrame', ScrappingMachineFrame)
parentFrame:SetPoint('TOP', ScrappingMachineFrame, 'BOTTOM', 0, 16)
parentFrame:SetSize(ScrappingMachineFrame:GetWidth()-16, 294) --264
parentFrame:EnableMouse(true)
parentFrame:SetFrameLevel(ScrappingMachineFrame:GetFrameLevel()-1)
parentFrame:RegisterEvent("PLAYER_LOGOUT")
parentFrame:RegisterEvent("ADDON_LOADED")
parentFrame:SetBackdrop({
      bgFile="Interface\\FrameGeneral\\UI-Background-Marble", 
      edgeFile='Interface/Tooltips/UI-Tooltip-Border', 
      tile = false, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }}
)

local mainFrame = CreateFrame('Frame', 'EasyScrapMainFrame', parentFrame)
mainFrame:SetAllPoints()

mainFrame.searchBox = CreateFrame('EditBox', nil, mainFrame, 'SearchBoxTemplate')
mainFrame.searchBox:SetPoint('TOPLEFT', 22, -22)
mainFrame.searchBox:SetSize(100, 18)
mainFrame.searchBox.Instructions:SetText('Search')
mainFrame.searchBox.isEmpty = true

mainFrame.searchBox:SetScript('OnTextChanged', function(searchBox, value)
	if ( not searchBox:HasFocus() and searchBox:GetText() == "" ) then
		searchBox.searchIcon:SetVertexColor(0.6, 0.6, 0.6);
		searchBox.clearButton:Hide();
	else
		searchBox.searchIcon:SetVertexColor(1.0, 1.0, 1.0);
		searchBox.clearButton:Show();
	end
	InputBoxInstructions_OnTextChanged(searchBox);

    if value then
        local text = searchBox:GetText()
        if string.len(text) > 0 then
            searchBox.isEmpty = false
            EasyScrap:searchItem(text)
            EasyScrap:filterScrappableItems()
            EasyScrap.itemFrame:displayState()
        else
            --Clear results
            searchBox.isEmpty = true
            EasyScrap:searchItem()
            EasyScrap:filterScrappableItems()
            EasyScrap.itemFrame:displayState()
        end
    else
        --Clear results
        searchBox.isEmpty = true
        EasyScrap:searchItem()
        EasyScrap:filterScrappableItems()
        EasyScrap.itemFrame:displayState()
    end
end)



local optionsButton = CreateFrame('Button', nil, mainFrame, 'GameMenuButtonTemplate')
optionsButton:SetSize(32, 24)
optionsButton:SetPoint('BOTTOM', 0, 8)
--optionsButton:SetText('Config')
optionsButton:SetScript('OnClick', function()
    if not EasyScrap.scrapInProgress then
        EasyScrap:clearQueue()
        mainFrame:Hide()
        EasyScrap.optionsFrame:Show()
    else
        DEFAULT_CHAT_FRAME:AddMessage('Easy Scrap: Cannot switch menu while scrapping items.')
    end
end)

optionsButton:SetScript('OnEnter', function(self) self.t:SetDesaturated(false) end)
optionsButton:SetScript('OnLeave', function(self) self.t:SetDesaturated(true) end)


optionsButton.t = optionsButton:CreateTexture(nil, 'ARTWORK')
optionsButton.t:SetSize(22, 22)
optionsButton.t:SetPoint('CENTER', 0, -1)
optionsButton.t:SetTexture('Interface/HelpFrame/HelpIcon-CharacterStuck')
optionsButton.t:SetDesaturated(true)





local filterSelection = CreateFrame("Frame", "EasyScrapFilterSelectionMenu", mainFrame, "UIDropDownMenuTemplate")
filterSelection.Middle:SetWidth(96)
filterSelection:SetPoint("LEFT", mainFrame.searchBox, "RIGHT", 56, -4) --32

filterSelection.text = filterSelection:CreateFontString()
filterSelection.text:SetFontObject('GameFontNormal')
filterSelection.text:SetText('Filter:')
filterSelection.text:SetPoint('RIGHT', filterSelection, 'LEFT', 16, 4)

filterSelection.Button:SetScript('OnClick', function() 
    if DropDownList1:IsVisible() then
        DropDownList1:Hide()
    else
        if not EasyScrap.scrapInProgress then
            EasyMenu(EasyScrap.filterSelectionMenuTable, filterSelection, filterSelection, 16, 8, nil, 3)
        else
            DEFAULT_CHAT_FRAME:AddMessage('Easy Scrap: Cannot switch filters while scrapping items.')
        end
    end
end)
UIDropDownMenu_SetText(filterSelection, "Default")


local queueAllButton = CreateFrame('Button', nil, mainFrame, 'GameMenuButtonTemplate')
queueAllButton:SetSize(96, 24)
queueAllButton:SetPoint('BOTTOMLEFT', 16, 12)
queueAllButton:SetText('Queue All')
queueAllButton:SetScript('OnClick', function()
    EasyScrapItemFrame:queueAllItems()
end)

local filtersButton = CreateFrame('Button', nil, mainFrame, 'GameMenuButtonTemplate')
filtersButton:SetSize(96, 24)
filtersButton:SetPoint('BOTTOMRIGHT', -16, 12)
filtersButton:SetText('Filters')
filtersButton:SetScript('OnClick', function()
    if not EasyScrap.scrapInProgress then
        EasyScrap:clearQueue()
        mainFrame:Hide()
        EasyScrap.filterFrame:Show()
    else
        DEFAULT_CHAT_FRAME:AddMessage('Easy Scrap: Cannot switch menu while scrapping items.')
    end
end)

mainFrame.queueAllButton = queueAllButton


local updateOverlay = CreateFrame('Frame', nil, parentFrame)
updateOverlay:SetAllPoints()

updateOverlay.header = updateOverlay:CreateFontString()
updateOverlay.header:SetFontObject('GameFontNormalLarge')
updateOverlay.header:SetText('Easy Scrap |cFF00FF00'..EasyScrap.addonVersion..'|r')
updateOverlay.header:SetPoint('TOP', 0, -32)

updateOverlay.subHeader = updateOverlay:CreateFontString()
updateOverlay.subHeader:SetFontObject('GameFontNormal')
updateOverlay.subHeader:SetText("What's new?")
updateOverlay.subHeader:SetTextColor(1, 1, 1, 1)
updateOverlay.subHeader:SetPoint('TOP', updateOverlay.header, 'BOTTOM', 0, -4)

updateOverlay.content = updateOverlay:CreateFontString()
updateOverlay.content:SetFontObject('GameFontNormal')
updateOverlay.content:SetJustifyH("LEFT")
updateOverlay.content:SetJustifyV("TOP")
updateOverlay.content:SetText("- Blabla bla \n- Bloeoeoeoe")
updateOverlay.content:SetWidth(updateOverlay:GetWidth()-16)
updateOverlay.content:SetHeight(updateOverlay:GetHeight()*0.75)
updateOverlay.content:SetTextColor(1, 1, 1, 1)
updateOverlay.content:SetPoint('TOP', updateOverlay, 0, -80)

updateOverlay.dismissButton = CreateFrame('Button', nil, updateOverlay, 'GameMenuButtonTemplate')
updateOverlay.dismissButton:SetSize(96, 24)
updateOverlay.dismissButton:SetPoint('BOTTOM', 0, 12)
updateOverlay.dismissButton:SetText('Okay')
updateOverlay.dismissButton:SetScript('OnClick', function()
    EasyScrap.saveData.showWhatsNew = nil
    updateOverlay:Hide()
    mainFrame:Show()
end)

mainFrame:SetScript('OnShow', function()
    EasyScrap:generateFilterDropdown()
    EasyScrap:filterScrappableItems()
    EasyScrapItemFrame:updateContent()
end)

updateOverlay:Hide()

EasyScrap.mainFrame = mainFrame
EasyScrap.parentFrame = parentFrame
EasyScrap.updateOverlay = updateOverlay

