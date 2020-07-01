--[[
LibItemBuffs-1.0 - buff-to-item database.
(c) 2013-2018 Adirelle (adirelle@gmail.com)

This file is part of LibItemBuffs-1.0.

LibItemBuffs-1.0 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

LibItemBuffs-1.0 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with LibItemBuffs-1.0. If not, see <http://www.gnu.org/licenses/>.
--]]

local MAJOR, MINOR, lib = "LibItemBuffs-1.0", 9
if LibStub then
	lib = LibStub:NewLibrary(MAJOR, MINOR)
	if not lib then return end
else
	lib = {}
end

lib.__itemBuffs = lib.__itemBuffs or {}
lib.__databaseVersion = lib.__databaseVersion or 0

lib.trinkets = lib.trinkets or {}
lib.consumables = lib.consumables or {}
lib.enchantments = lib.enchantments or {}
lib.slots = lib.slots or {}

--- Tell whether a spell is an item buff or not.
-- @name LibItemBuffs:IsItemBuff
-- @param spellID number Spell identifier.
-- @return boolean True if the spell is a buff given by an item.
function lib:IsItemBuff(spellID)
	return not not (spellID and (lib.enchantments[spellID] or lib.trinkets[spellID] or lib.consumables[spellID]))
end

--- Return the inventory slot containing the item that can apply the given buff.
-- @name LibItemBuffs:GetBuffInventorySlot
-- @param spellID number Spell identifier.
-- @return number The inventory slot of matching item (see INVSLOT_* values), returns nil for items in bags.
function lib:GetBuffInventorySlot(spellID)
	if not spellID then return end

	local invSlot = lib.enchantments[spellID]
	if invSlot then
		return invSlot
	end

	local itemID = lib.trinkets[spellID]
	if not itemID then return end

	local trinket1 = GetInventoryItemID("player", INVSLOT_TRINKET1)
	local trinket2 = GetInventoryItemID("player", INVSLOT_TRINKET2)
	if type(itemID) == "table" then
		for i, realID in ipairs(itemID) do
			if realID == trinket1 then
				return INVSLOT_TRINKET1
			end
			if realID == trinket2 then
				return INVSLOT_TRINKET2
			end
		end
	end
	if itemID == trinket1 then
		return INVSLOT_TRINKET1
	end
	if itemID == trinket2 then
		return INVSLOT_TRINKET2
	end
end

--- Return the identifier of the item that can apply the given buff.
-- @name LibItemBuffs:GetBuffItemID
-- @param spellID number Spell identifier.
-- @return number The item identifier(s) or nil.
function lib:GetBuffItemID(spellID)
	if not spellID then return end

	local itemID = lib.trinkets[spellID] or lib.consumables[spellID]
	if type(itemID) == "table" then
		return unpack(itemID)
	elseif itemID then
		return itemID
	end

	local invSlot = lib.enchantments[spellID]
	return invSlot and GetInventoryItemID("player", invSlot)
end

--- Get the list of inventory slots for which the library has information.
-- @name LibItemBuffs:GetInventorySlotList
-- @return table A list of INVSLOT_* values.
function lib:GetInventorySlotList()
	return lib.slots
end

--- Return the buffs provided by then given item, excluding any enchant.
-- @name LibItemBuffs:GetItemBuffs
-- @param itemID number Item identifier.
-- @return number, ... A list of spell identifiers.
function lib:GetItemBuffs(itemID)
	if not itemID then return end
	local buffs = lib.__itemBuffs[itemID]
	if type(buffs) == "table" then
		return unpack(buffs)
	end
	return buffs
end

local function AddReverseEntry(reverse, spellID, itemID)
	if type(itemID) == "table" then
		for i, value in ipairs(itemID) do
			AddReverseEntry(reverse, spellID, value)
		end
		return
	end
	local previous = reverse[itemID]
	if not previous then
		reverse[itemID] = spellID
	elseif type(previous) == "table" then
		tinsert(previous, spellID)
	else
		reverse[itemID] = { previous, spellID }
	end
end

-- Add the content of the given table into the reverse table.
-- Create a table when an item can provide several buffs.
local function FeedReverseTable(reverse, data)
	for spellID, itemID in pairs(data) do
		AddReverseEntry(reverse, spellID, itemID)
	end
end

function lib:GetDatabaseVersion()
	return floor(lib.__databaseVersion/10)
end

-- Upgrade the trinket and consumables database if needed
function lib:__UpgradeDatabase(version, trinkets, consumables, enchantments)
	assert(
		type(version) == "number" and type(trinkets) == "table" and
		type(consumables) == "table" and type(enchantments) == "table",
		format('Usage: LibStub("%s"):__UpgradeDatabase(version, trinkets, consumables, enchantments)', MAJOR)
	)
	version = version*10 + MINOR -- Factor in the library revision
	if version <= lib.__databaseVersion then return end

	-- Upgrade the tables
	lib.__databaseVersion = version
	lib.trinkets = trinkets
	lib.consumables = consumables
	lib.enchantments = enchantments

	-- Rebuild the reverse database
	wipe(lib.__itemBuffs)
	FeedReverseTable(lib.__itemBuffs, trinkets)
	FeedReverseTable(lib.__itemBuffs, consumables)

	-- Rebuild the slot list
	wipe(lib.slots)
	local slotSet = {}
	for _, slot in pairs(enchantments) do
		slotSet[slot] = true
	end
	for slot in pairs(slotSet) do
		tinsert(lib.slots, slot)
	end
end

return lib
