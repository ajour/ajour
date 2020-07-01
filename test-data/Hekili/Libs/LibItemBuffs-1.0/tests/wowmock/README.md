wowmock
=======

WoW environment mock for unit testing.

[![Build Status](https://travis-ci.org/Adirelle/wowmock.svg?branch=master)](https://travis-ci.org/Adirelle/wowmock)

Dependencies
------------

wowmock has been designed to work with [luaunit 2.1](https://github.com/rjpcomputing/luaunit) and [mockagne 1.0+](https://github.com/PunchWolf/mockagne), which you can install using [LuaRocks](http://luarocks.org/), but any testing framework and mock libraries that mimics mockagne interface should work.

Usage
-----

wowmock allows you to load a Lua file into a controlled environnement using [setfenv](http://www.lua.org/manual/5.1/manual.html#pdf-setfenv). The code has access to standard Lua globals as well as a small subsets of [WoW Lua functions](http://wowpedia.org/Lua_functions) (most are not implemented yet).

Most specific WoW API functions are *not* available, as they should be mocked.

```lua
function wowmock(filepath, globals, ...)
```

* `filepath` is the path to the file to load.
* `globals` will be used as a fallback _G. You pass a mock to define and check the call to WoW API
* The other parameters are passed as is to the file. With WoW file, you usually pass the addon name and a "private" table, which also can be a mock.

Sample
------

```lua
local LuaUnit = require('luaunit')
local mockagne = require('mockagne')
local wowmock = require('wowmock')

local when, verify = mockagne.when, mockagne.verify

-- Mocks
local globals, addon

-- The test "class"
tests = {}

-- Setup, before every test
function tests:setup()
	-- Prepare an addon mock
	addon = mockagne:getMock()
	
	-- Prepare a globals mock
	globals = mockagne:getMock()
	
	-- Load the file to test 
	wowmock("FileToTest.lua", globals, "MyAddon", addon)
end

-- A test
function tests:test_addon_doSomething()
	-- When UnitSpeed("player") is called, return 7
	when(globals.UnitSpeed("player")).thenAnswer(7)
	
	-- Call the function to test
	local result = addon.doSomething()
	
	-- Ensure UnitSpeed("player") has been called
	verify(globals.UnitSpeed("player"))
	
	-- Ensure the result returned the expected result
	assertEquals("expectedResult", result)
end

-- Run the tests
os.exit(LuaUnit:Run())
```
