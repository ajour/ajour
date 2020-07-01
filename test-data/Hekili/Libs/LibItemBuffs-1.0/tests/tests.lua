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

package.path = package.path .. ";./tests/wowmock/?.lua"
local LuaUnit = require('luaunit')
local mockagne = require('mockagne')
local wowmock = require('wowmock')

local when, verify = mockagne.when, mockagne.verify

local lib

INVSLOT_TRINKET1 = "INVSLOT_TRINKET1"
INVSLOT_TRINKET2 = "INVSLOT_TRINKET2"

LibStub = false

local function setup()
	G = mockagne:getMock()
	lib = wowmock("./LibItemBuffs-1.0.lua", G)
end

testUpgradeDatabase = { setup = setup }

function testUpgradeDatabase:test_first_data()
	lib:__UpgradeDatabase(10, {}, {}, {})
	assertEquals(lib:GetDatabaseVersion(), 10)
end

function testUpgradeDatabase:test_newer_data()
	lib:__UpgradeDatabase(10, {}, {}, {})
	lib:__UpgradeDatabase(15, {}, {}, {})
	assertEquals(lib:GetDatabaseVersion(), 15)
end

function testUpgradeDatabase:test_older_data()
	lib:__UpgradeDatabase(10, {}, {}, {})
	lib:__UpgradeDatabase(5, {}, {}, {})
	assertEquals(lib:GetDatabaseVersion(), 10)
end

function testUpgradeDatabase:test_invalid_version()
	local success, msg = pcall(lib.__UpgradeDatabase, lib, "bla")
	assertEquals(success, false)
	assertEquals(msg:match('Usage:'), 'Usage:')
end

function testUpgradeDatabase:test_invalid_trinkets()
	local success, msg = pcall(lib.__UpgradeDatabase, lib, 10, "bla")
	assertEquals(success, false)
	assertEquals(msg:match('Usage:'), 'Usage:')
end

function testUpgradeDatabase:test_invalid_consumables()
	local success, msg = pcall(lib.__UpgradeDatabase, lib, 10, {}, "bla")
	assertEquals(success, false)
	assertEquals(msg:match('Usage:'), 'Usage:')
end

function testUpgradeDatabase:test_invalid_enchantments()
	local success, msg = pcall(lib.__UpgradeDatabase, lib, 10, {}, {}, "bla")
	assertEquals(success, false)
	assertEquals(msg:match('Usage:'), 'Usage:')
end

testIsItemBuff = { setup = setup }

function testIsItemBuff:test_trinkets()
	lib:__UpgradeDatabase(10, {[20] = 10}, {}, {})
	assertEquals(lib:IsItemBuff(20), true)
end

function testIsItemBuff:test_consumables()
	lib:__UpgradeDatabase(10, {}, {[20] = 10}, {})
	assertEquals(lib:IsItemBuff(20), true)
end

function testIsItemBuff:test_enchantments()
	lib:__UpgradeDatabase(10, {}, {}, {[20] = 10})
	assertEquals(lib:IsItemBuff(20), true)
end

function testIsItemBuff:test_unknown()
	lib:__UpgradeDatabase(10, {}, {}, {})
	assertEquals(lib:IsItemBuff(20), false)
end

testGetBuffInventorySlot = { setup = setup }

function testGetBuffInventorySlot:test_no_spell()
	assertEquals(lib:GetBuffInventorySlot(), nil)
end

function testGetBuffInventorySlot:test_enchantments()
	lib:__UpgradeDatabase(10, {}, {}, {[10] = INVSLOT_TRINKET1})
	assertEquals(lib:GetBuffInventorySlot(10), INVSLOT_TRINKET1)
end

function testGetBuffInventorySlot:test_trinket1()
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET1)).thenAnswer(500)
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET2)).thenAnswer(200)

	lib:__UpgradeDatabase(10, {[10] = 500}, {}, {})

	local slot = lib:GetBuffInventorySlot(10)

	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET1))
	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET2))

	assertEquals(slot, INVSLOT_TRINKET1)
end

function testGetBuffInventorySlot:test_trinket2()
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET1)).thenAnswer(200)
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET2)).thenAnswer(500)

	lib:__UpgradeDatabase(10, {[10] = 500}, {}, {})

	local slot = lib:GetBuffInventorySlot(10)

	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET1))
	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET2))

	assertEquals(slot, INVSLOT_TRINKET2)
end

function testGetBuffInventorySlot:test_multiple_trinkets()
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET1)).thenAnswer(500)
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET2)).thenAnswer(200)

	lib:__UpgradeDatabase(10, {[10] = 500, [12] = 500}, {}, {})

	local slot10 = lib:GetBuffInventorySlot(10)
	local slot12 = lib:GetBuffInventorySlot(12)

	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET1))
	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET2))

	assertEquals(slot10, INVSLOT_TRINKET1)
	assertEquals(slot12, INVSLOT_TRINKET1)
end

testGetBuffItemID = { setup = setup }

function testGetBuffItemID:test_no_spell()
	assertEquals(lib:GetBuffItemID(), nil)
end

function testGetBuffItemID:test_trinket()
	lib:__UpgradeDatabase(10, {[10] = 500}, {}, {})
	assertEquals(lib:GetBuffItemID(10), 500)
end

function testGetBuffItemID:test_consumable()
	lib:__UpgradeDatabase(10, {}, {[10] = 500}, {})
	assertEquals(lib:GetBuffItemID(10), 500)
end

function testGetBuffItemID:test_enchantement()
	when(G.GetInventoryItemID("player", INVSLOT_TRINKET1)).thenAnswer(500)

	lib:__UpgradeDatabase(10, {}, {}, {[10] = INVSLOT_TRINKET1})

	local itemID = lib:GetBuffItemID(10)

	verify(G.GetInventoryItemID("player", INVSLOT_TRINKET1))

	assertEquals(itemID, 500)
end

function testGetBuffItemID:test_multiple_trinkets()
	lib:__UpgradeDatabase(10, {[10] = { 200, 500 }}, {}, {})
	assertEquals({lib:GetBuffItemID(10)}, {200, 500})
end

function testGetBuffItemID:test_multiple_consumables()
	lib:__UpgradeDatabase(10, {}, {[10] = { 200, 500 }}, {})
	assertEquals({lib:GetBuffItemID(10)}, {200, 500})
end

testGetInventorySlotList = { setup = setup }

function testGetInventorySlotList:test_different_slots()
	lib:__UpgradeDatabase(10, {}, {}, {[10] = INVSLOT_TRINKET1, [12] = INVSLOT_TRINKET2})
	assertEquals(lib:GetInventorySlotList(10), {INVSLOT_TRINKET2, INVSLOT_TRINKET1})
end

function testGetInventorySlotList:test_same_slot()
	lib:__UpgradeDatabase(10, {}, {}, {[10] = INVSLOT_TRINKET1, [12] = INVSLOT_TRINKET1})
	assertEquals(lib:GetInventorySlotList(10), {INVSLOT_TRINKET1})
end

testGetItemBuffs = { setup = setup }

function testGetItemBuffs:test_on_spell()
	assertEquals(lib:GetItemBuffs(), nil)
end

function testGetItemBuffs:test_trinkets()
	lib:__UpgradeDatabase(10, {[10] = 500}, {}, {})
	assertEquals(lib:GetItemBuffs(500), 10)
end

function testGetItemBuffs:test_consumables()
	lib:__UpgradeDatabase(10, {}, {[10] = 500}, {})
	assertEquals(lib:GetItemBuffs(500), 10)
end

function testGetItemBuffs:test_multiple_trinkets()
	lib:__UpgradeDatabase(10, {}, {[10] = 500, [12] = 500}, {})
	assertEquals({lib:GetItemBuffs(500)}, {10, 12})
end

function testGetItemBuffs:test_multiple_consumables()
	lib:__UpgradeDatabase(10, {}, {[10] = 500, [12] = 500}, {})
	assertEquals({lib:GetItemBuffs(500)}, {10, 12})
end

function testGetItemBuffs:test_multiple_mixed()
	lib:__UpgradeDatabase(10, {[10] = 500}, {[12] = 500}, {})
	assertEquals({lib:GetItemBuffs(500)}, {10, 12})
end

function testGetItemBuffs:test_complex()
	lib:__UpgradeDatabase(10, {[10] = {500, 502}}, {[12] = 500, [14] = 502}, {})
	assertEquals({lib:GetItemBuffs(500)}, {10, 12})
	assertEquals({lib:GetItemBuffs(502)}, {10, 14})
end

function testGetItemBuffs:test_GH_37()
	lib:__UpgradeDatabase(10, {
		[146046] = { -- Expanded Mind
			105422, -- Purified Bindings of Immerseus
			104426, -- Purified Bindings of Immerseus
			105173, -- Purified Bindings of Immerseus
			102293, -- Purified Bindings of Immerseus
			104675, -- Purified Bindings of Immerseus
			104924, -- Purified Bindings of Immerseus
		}
	}, {}, {})
	assertEquals(lib:GetItemBuffs(105422), 146046)
	assertEquals(lib:GetItemBuffs(104426), 146046)
	assertEquals(lib:GetItemBuffs(105173), 146046)
	assertEquals(lib:GetItemBuffs(102293), 146046)
	assertEquals(lib:GetItemBuffs(104675), 146046)
	assertEquals(lib:GetItemBuffs(104924), 146046)
end

os.exit(LuaUnit:Run())
