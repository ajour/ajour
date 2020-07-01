local itemFrame = EasyScrapItemFrame
local contentFrame = itemFrame.contentFrame
local EasyScrap = EasyScrap
local itemButtonsVisible = 0

contentFrame.itemButtons = {}

local function updateQueueTab()
    itemFrame.tabButtons[1]:SetCount(#EasyScrap.queueItems)
end

local function itemInQueue(itemRef)
    for k,v in pairs(EasyScrap.queueItems) do
        if v == itemRef then return true end
    end
    return false
end

local function addItemToQueue(itemButton)
    table.insert(EasyScrap.queueItems, itemButton.itemRef)
    
    SetItemButtonDesaturated(itemButton, true)
    itemButton.IconBorder:Hide()
    AutoCastShine_AutoCastStart(itemButton.shineFrame)

    updateQueueTab()
end

local function removeItemFromQueue(itemButton)
    for k,v in pairs(EasyScrap.queueItems) do
        if v == itemButton.itemRef then table.remove(EasyScrap.queueItems, k) break end
    end
    SetItemButtonDesaturated(itemButton, false)
    itemButton.IconBorder:Show()
    AutoCastShine_AutoCastStop(itemButton.shineFrame)       

    if itemFrame.contentState == 1 then
        itemFrame:updateContent()
    else
        updateQueueTab()
    end
end

local function selectItemForScrapping(self)
    local scrappableItems = EasyScrap.scrappableItems
    --CHECK IF BUTTON IS STILL THE SAME ITEM?
    local itemInScrapper = EasyScrap:itemInScrapper(scrappableItems[self.itemRef].bag, scrappableItems[self.itemRef].slot)
    local itemInQueue = itemInQueue(self.itemRef)
    
    if not itemInScrapper and not itemInQueue and #EasyScrap.itemsInScrapper < 9 and not EasyScrap.scrapInProgress then
        UseContainerItem(scrappableItems[self.itemRef].bag, scrappableItems[self.itemRef].slot)
    elseif itemInScrapper and not itemInQueue then
        EasyScrap:removeItemFromScrapper(scrappableItems[self.itemRef].bag, scrappableItems[self.itemRef].slot)
        if #EasyScrap.itemsInScrapper == 0 and #EasyScrap.queueItems > 0 then
            EasyScrap.queueItems = {}
            EasyScrapItemFrame:updateContent()
        end
    elseif itemInQueue and not itemInScrapper then
        removeItemFromQueue(self)
    else
        addItemToQueue(self)
    end  
end

local function selectItemToIgnore(self)
    local itemRef = self.itemRef
    local itemInScrapper = EasyScrap:itemInScrapper(EasyScrap.scrappableItems[itemRef].bag, EasyScrap.scrappableItems[itemRef].slot)
    local itemInQueue = itemInQueue(itemRef)
    if itemInScrapper then EasyScrap:removeItemFromScrapper(EasyScrap.scrappableItems[itemRef].bag, EasyScrap.scrappableItems[itemRef].slot) end
    if itemInQueue then removeItemFromQueue(self) end

    if itemRef > 0 then
        itemFrame.ignoreItemFrame.itemRef = itemRef
        
        itemFrame.ignoreItemFrame:Show()
        itemFrame.contentFrame:Hide()

    end
end

local function itemButtonOnClick(self, button)
    if button == 'LeftButton' then
        selectItemForScrapping(self)
    elseif button == 'RightButton' then
        --Ignore item options
        if not EasyScrap.scrapInProgress then
            selectItemToIgnore(self)
        end
    end
end

local function createItemButton(i)
    --local frame = CreateFrame('Button', 'EasyScrapItemButton'..i, contentFrame, "ItemButtonTemplate")
    local frame = CreateFrame('Button', 'EasyScrapItemButton'..i, contentFrame, "EasyScrapItemButtonTemplate")
    frame:SetScale(0.95, 0.95)
    frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    frame:SetScript('OnClick', itemButtonOnClick)
    frame:SetScript('OnEnter', function(self)
        EasyScrap.mouseInItem = true
        EasyScrap.mouseInItemRef = self.itemRef
        --Ugly hack to deal with addons that are redrawing tooltips? Is now located in the tooltip item set hookscript in EasyScrap.lua
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        --GameTooltip:SetPoint("BOTTOMLEFT", frame, "TOPRIGHT");
        GameTooltip:SetBagItem(EasyScrap.scrappableItems[self.itemRef].bag, EasyScrap.scrappableItems[self.itemRef].slot)
        GameTooltip:Show()
    end)
    frame:SetScript('OnLeave', function(self) GameTooltip_Hide() EasyScrap.mouseInItem = false EasyScrap.mouseInItemRef = 0 end)
    
    frame.shineFrame = CreateFrame('Frame', 'EasyScrapItemButton'..i..'Shine', frame, 'AutoCastShineTemplate')
    frame.shineFrame:SetPoint('TOPLEFT', 1, -1)
    frame.shineFrame:SetPoint('BOTTOMRIGHT', -1, 1)

    local spacing = 1.05*((contentFrame:GetWidth()-(7*frame:GetWidth()))/7)
    local perRow = 7
    local x = 8 + (spacing/2) + (i-1)%perRow*(frame:GetWidth()+spacing)
    local y = -4 - math.floor((i-1)/7)*42
    
    frame.defaultX = x
    frame.defaultY = y

    frame:SetPoint('TOPLEFT', x, y)   
    
    frame.bg = frame:CreateTexture(nil, 'BACKGROUND')
    frame.bg:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
    frame.bg:SetSize(54, 54)
    frame.bg:SetPoint('CENTER')
    frame.itemRef = 0
    frame:Hide()
    
    return frame    
end

local function displayIgnoredItemButtons()
    itemButtonsVisible = 0
    
    contentFrame.ignoreHeader:Show()
    contentFrame.filterHeader:Show()
    
    local itemTable = EasyScrap.ignoredItems
    for i = 1, #itemTable do
        if not contentFrame.itemButtons[i] then contentFrame.itemButtons[i] = createItemButton(i) end
        local itemButton = contentFrame.itemButtons[i]
        
        local scrappableItem = EasyScrap.scrappableItems[itemTable[i]]
        
        SetItemButtonTexture(itemButton, scrappableItem.itemTexture)
        SetItemButtonCount(itemButton, scrappableItem.itemCount);
        SetItemButtonQuality(itemButton, scrappableItem.itemQuality, scrappableItem.itemLink)
        
        if EasyScrap.mainFrame.searchBox.isEmpty then
            itemButton.searchOverlay:Hide()
        else
            if EasyScrap.scrappableItems[itemTable[i]].searchMatch then              
                itemButton.searchOverlay:Hide()
            else
                itemButton.searchOverlay:Show()
            end       
        end
            
        itemButton.itemRef = itemTable[i]
        
        itemButton:ClearAllPoints()
        itemButton:SetPoint('TOPLEFT', contentFrame.ignoreHeader, 'BOTTOMLEFT', itemButton.defaultX, itemButton.defaultY)       

        itemButton:Show()
        itemButtonsVisible = itemButtonsVisible + 1
    end
    
    if itemButtonsVisible == 0 then
        contentFrame.ignoreHeader.subText:Show()
    else
        contentFrame.ignoreHeader.subText:Hide()
    end
    
    contentFrame.filterHeader:ClearAllPoints()
    if itemButtonsVisible > 0 then
        local _,_,_,x,y = contentFrame.itemButtons[itemButtonsVisible]:GetPoint()
        contentFrame.filterHeader:SetPoint('TOP', contentFrame.ignoreHeader, 0, y-contentFrame.itemButtons[itemButtonsVisible]:GetHeight()-24)
    else
        contentFrame.filterHeader:SetPoint('TOP', contentFrame.ignoreHeader, 0, -48)
    end
    
    local filteredButtonsVisible = 0
    local index = itemButtonsVisible
    
    local itemTable = EasyScrap.filteredItems
    for i = 1, #itemTable do
        if not contentFrame.itemButtons[i+index] then contentFrame.itemButtons[i+index] = createItemButton(i+index) end
        local itemButton = contentFrame.itemButtons[i+index]
        
        local scrappableItem = EasyScrap.scrappableItems[itemTable[i]]
        
        SetItemButtonTexture(itemButton, scrappableItem.itemTexture)
        SetItemButtonCount(itemButton, scrappableItem.itemCount);
        SetItemButtonQuality(itemButton, scrappableItem.itemQuality, scrappableItem.itemLink)
        
        if EasyScrap.mainFrame.searchBox.isEmpty then
            itemButton.searchOverlay:Hide()
        else
            if EasyScrap.scrappableItems[itemTable[i]].searchMatch then              
                itemButton.searchOverlay:Hide()
            else
                itemButton.searchOverlay:Show()
            end       
        end
            
        itemButton.itemRef = itemTable[i]
        
        itemButton:ClearAllPoints()
        itemButton:SetPoint('TOPLEFT', contentFrame.filterHeader, 'BOTTOMLEFT', contentFrame.itemButtons[filteredButtonsVisible+1].defaultX, contentFrame.itemButtons[filteredButtonsVisible+1].defaultY)       

        itemButton:Show()
        itemButtonsVisible = itemButtonsVisible + 1
        filteredButtonsVisible = filteredButtonsVisible + 1
    end   
    
    if filteredButtonsVisible == 0 then
        contentFrame.filterHeader.subText:Show()
    else
        contentFrame.filterHeader.subText:Hide()
    end
end

local function displayItemButtons()
    contentFrame.ignoreHeader:Hide()
    contentFrame.filterHeader:Hide()

    local itemTable = EasyScrap.eligibleItems
    if itemFrame.contentState == 1 then
        itemTable = EasyScrap.queueItems
    end
    itemButtonsVisible = 0
      
    for i = 1, #itemTable do
        if not contentFrame.itemButtons[i] then contentFrame.itemButtons[i] = createItemButton(i) end
        local itemButton = contentFrame.itemButtons[i]
        
        local scrappableItem = EasyScrap.scrappableItems[itemTable[i]]
        
        SetItemButtonTexture(itemButton, scrappableItem.itemTexture)
        SetItemButtonCount(itemButton, scrappableItem.itemCount);
        SetItemButtonQuality(itemButton, scrappableItem.itemQuality, scrappableItem.itemLink)
        
        if EasyScrap.mainFrame.searchBox.isEmpty then
            itemButton.searchOverlay:Hide()
        else
            if EasyScrap.scrappableItems[itemTable[i]].searchMatch then              
                itemButton.searchOverlay:Hide()
            else
                itemButton.searchOverlay:Show()
            end       
        end
            
        itemButton.itemRef = itemTable[i]
        
        itemButton:ClearAllPoints()
        itemButton:SetPoint('TOPLEFT', itemButton.defaultX, itemButton.defaultY)
        itemButton:Show()
        
        itemButtonsVisible = itemButtonsVisible + 1
    end
end

local function hideItemButtons()
    for i = 1, #contentFrame.itemButtons do
        contentFrame.itemButtons[i]:Hide()

        SetItemButtonDesaturated(contentFrame.itemButtons[i], false)
        contentFrame.itemButtons[i].NewActionTexture:Hide()
        contentFrame.itemButtons[i].IconBorder:Show()
        AutoCastShine_AutoCastStop(contentFrame.itemButtons[i].shineFrame)
    end
end

function EasyScrapItemFrame:displayState()
    hideItemButtons()
    itemFrame.ignoreItemFrame:Hide()
    contentFrame.tabInfo:Hide()
    contentFrame.noEligibleInfo:Hide()
    itemFrame.contentFrame:Show()
    self:moveQueueTabSparks()
    EasyScrap.mainFrame.queueAllButton:SetEnabled(false)  
    if self.contentState == 1 then
        if #EasyScrap.queueItems == 0 then
            contentFrame.tabInfo:SetText("This tab shows you all items currently queued for scrapping. To queue items for scrapping simply keep adding items to the scrapper when it's full.")
            contentFrame.tabInfo:Show()
        end
    elseif self.contentState == 2 then
        if #EasyScrap.eligibleItems > 0 then
            EasyScrap.mainFrame.queueAllButton:SetEnabled(true)
        else
            contentFrame.noEligibleInfo:Show()
        end
    elseif self.contentState == 3 then
    end
    
    if self.contentState == 3 then
        displayIgnoredItemButtons()
    else
        displayItemButtons()
    end
    self:highlightItemsForScrapping()
end

EasyScrapItemFrame.switchContentState = function(newState)
    PanelTemplates_DeselectTab(itemFrame.tabButtons[itemFrame.contentState])
    itemFrame.contentState = newState
    PanelTemplates_SelectTab(itemFrame.tabButtons[itemFrame.contentState])
    
    EasyScrapItemFrame:updateContent()
end

local function updateSlider()
    local maxScroll = 0
    if itemFrame.contentState == 1 then
        maxScroll = (math.ceil(#EasyScrap.queueItems / 7)*40)
    elseif itemFrame.contentState == 2 then
        maxScroll = (math.ceil(#EasyScrap.eligibleItems / 7)*40)
    elseif itemFrame.contentState == 3 then
        maxScroll = 48
        if contentFrame.ignoreHeader.subText:IsVisible() then maxScroll = maxScroll + 24 end
        if contentFrame.filterHeader.subText:IsVisible() then maxScroll = maxScroll + 24 end
        maxScroll = maxScroll + (math.ceil(#EasyScrap.ignoredItems / 7)*40)
        maxScroll = maxScroll + (math.ceil(#EasyScrap.filteredItems / 7)*40)
    end
    
    maxScroll = maxScroll - itemFrame.scrollFrame:GetHeight() + 16
    if maxScroll < 0 then maxScroll = 0 end
    
    if itemFrame.scrollFrame.ScrollBar:GetValue() > maxScroll then itemFrame.scrollFrame.ScrollBar:SetValue(maxScroll) end
    itemFrame.scrollFrame.ScrollBar:SetMinMaxValues(0, maxScroll)   
end

function EasyScrapItemFrame:updateContent()
    itemButtonsVisible = 0
    self:displayState()
    updateSlider()
    
    self.tabButtons[1]:SetCount(#EasyScrap.queueItems)
    self.tabButtons[2]:SetCount(#EasyScrap.eligibleItems)
    self.tabButtons[3]:SetCount(#EasyScrap.ignoredItems+#EasyScrap.filteredItems)
end

function EasyScrapItemFrame:moveQueueTabSparks()
    if self.contentState == 1 then
        itemFrame.tabButtons[1].shineFrame:ClearAllPoints()
        itemFrame.tabButtons[1].shineFrame:SetPoint('CENTER', 1, 24)   
    else
        itemFrame.tabButtons[1].shineFrame:ClearAllPoints()
        itemFrame.tabButtons[1].shineFrame:SetPoint('CENTER', 1, 28)   
    end
end

function EasyScrapItemFrame:highlightItemsForScrapping()
    local itemTable = {}
    if itemFrame.contentState == 1 then
        itemTable = EasyScrap.queueItems
    elseif itemFrame.contentState == 2 then
        itemTable = EasyScrap.eligibleItems
    elseif itemFrame.contentState == 3 then
        itemTable = EasyScrap.ignoredItems
    end

    for i = 1, #itemTable do
        if EasyScrap:itemInScrapper(EasyScrap.scrappableItems[itemTable[i]].bag, EasyScrap.scrappableItems[itemTable[i]].slot) then
            SetItemButtonDesaturated(contentFrame.itemButtons[i], true)
            contentFrame.itemButtons[i].IconBorder:Hide()
            contentFrame.itemButtons[i].NewActionTexture:Show()
        elseif itemInQueue(itemTable[i]) then
            SetItemButtonDesaturated(contentFrame.itemButtons[i], true)
            contentFrame.itemButtons[i].IconBorder:Hide()
            AutoCastShine_AutoCastStart(contentFrame.itemButtons[i].shineFrame)       
        else
            SetItemButtonDesaturated(contentFrame.itemButtons[i], false)
            contentFrame.itemButtons[i].NewActionTexture:Hide()
            contentFrame.itemButtons[i].IconBorder:Show()
        end
    end
    
    if itemFrame.contentState == 3 and #EasyScrap.filteredItems > 0 then
        itemTable = EasyScrap.filteredItems
        local index = #EasyScrap.ignoredItems
         for i = 1, #itemTable do
            if EasyScrap:itemInScrapper(EasyScrap.scrappableItems[itemTable[i]].bag, EasyScrap.scrappableItems[itemTable[i]].slot) then
                SetItemButtonDesaturated(contentFrame.itemButtons[i+index], true)
                contentFrame.itemButtons[i+index].IconBorder:Hide()
                contentFrame.itemButtons[i+index].NewActionTexture:Show()
            elseif itemInQueue(itemTable[i]) then
                SetItemButtonDesaturated(contentFrame.itemButtons[i+index], true)
                contentFrame.itemButtons[i+index].IconBorder:Hide()
                AutoCastShine_AutoCastStart(contentFrame.itemButtons[i+index].shineFrame)       
            else
                SetItemButtonDesaturated(contentFrame.itemButtons[i+index], false)
                contentFrame.itemButtons[i+index].NewActionTexture:Hide()
                contentFrame.itemButtons[i+index].IconBorder:Show()
            end
        end   
    end
end

function EasyScrapItemFrame:queueAllItems()
    if not EasyScrap.scrapInProgress then
        for i = 1, itemButtonsVisible do
            if contentFrame.itemButtons[i].IconBorder:IsVisible() then
                addItemToQueue(contentFrame.itemButtons[i])
            end
        end
        EasyScrap.addingItems = true
        EasyScrap:addQueueItems()
    end
end

-- contentFrame.itemButtons[i].newitemglowAnim:Play()
-- contentFrame.itemButtons[i].newitemglowAnim:Stop()

-- AutoCastShine_AutoCastStart(contentFrame.itemButtons[i].shineFrame)
-- AutoCastShine_AutoCastStop(contentFrame.itemButtons[i].shineFrame);