local EasyScrap = EasyScrap

local optionsFrame = CreateFrame('Frame', nil, EasyScrap.parentFrame)
optionsFrame:SetAllPoints()
optionsFrame:Hide()



optionsFrame.header = optionsFrame:CreateFontString()
optionsFrame.header:SetFontObject('GameFontNormalLarge')
optionsFrame.header:SetText('Options')
optionsFrame.header:SetPoint('TOP', 0, -24)

local checkButtons = {}

checkButtons[1] = CreateFrame('CheckButton', nil, optionsFrame, 'EasyScrapCheckButtonTemplate')
checkButtons[1]:SetPoint('TOPLEFT', 16, -48)
checkButtons[1].text:SetText('Display "|cff87a9fe'..ITEM_SCRAPABLE..'|r" in tooltips.')
checkButtons[1].subText = checkButtons[1]:CreateFontString()
checkButtons[1].subText:SetFontObject("GameFontNormalSmall")
checkButtons[1].subText:SetText('Adds |cff87a9fe'..ITEM_SCRAPABLE..'|r to tooltips when not at the scrapper.\n(Experimental)')
checkButtons[1].subText:SetJustifyH("LEFT")
checkButtons[1].subText:SetPoint('BOTTOMLEFT', 2, -20)

checkButtons[1]:SetScript('OnClick', function(self)
    EasyScrap.saveData.addonSettings.canScrapTooltip = self:GetChecked()
end)




optionsFrame.dismissButton = CreateFrame('Button', nil, optionsFrame, 'GameMenuButtonTemplate')
optionsFrame.dismissButton:SetSize(96, 24)
optionsFrame.dismissButton:SetPoint('BOTTOM', 0, 12)
optionsFrame.dismissButton:SetText('Okay')
optionsFrame.dismissButton:SetScript('OnClick', function()
    optionsFrame:Hide()
    EasyScrap.mainFrame:Show()
end)

optionsFrame:SetScript('OnShow', function()
    checkButtons[1]:SetChecked(EasyScrap.saveData.addonSettings.canScrapTooltip)
end)

EasyScrap.optionsFrame = optionsFrame