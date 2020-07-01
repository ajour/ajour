--[[
wowmock - WoW environment mock
Copyright 2014 Adirelle (adirelle@gmail.com)
See LICENSE for usage.
--]]

package.path = package.path .. ';../?.lua'
local LuaUnit = require('luaunit')
local wowmock = require('wowmock')

tests = {}

function tests:test_pass_arguments()
	assertEquals(wowmock('fixtures/checkargs.lua', nil, "a", "b", "c"), { "a", "b", "c" })
end

function tests:test_isolation()
	local g1, g2 = {}, {}
	wowmock('fixtures/write_global.lua', g1, "a", 4)
	wowmock('fixtures/write_global.lua', g2, "a", 8)
	assertEquals(g1.a, nil)
	assertEquals(g2.a, nil)
end

function tests:test_globals()
	local g = { a = 5 }
	assertEquals(wowmock('fixtures/read_global.lua', g), 5)
end

function tests:test_wowlua()
	assertEquals(type(wowmock('fixtures/get_func.lua')), "function")
end

os.exit(LuaUnit:Run())
