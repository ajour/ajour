--[[
wowmock - WoW environment mock
Copyright 2014 Adirelle (adirelle@gmail.com)
See LICENSE for usage.
--]]

local function strsplit(delim, str, count)
	if count and count <= 1 then return str end
	local a, b = str:find(delim, 1, true)
	if not a then return str end
	return str:sub(1, a-1), strsplit(delim, str:sub(b+1), count and (count-1))
end

local t = {}
local function strjoin(delim, ...)
	for i = 1, select('#', ...) do
		t[i] = select(i, ...)
	end
	return table.concat(t, delim, 1, select('#', ...))
end

local function strconcat(...)
	return strjoin("", ...)
end

local function tContains(t, value)
	for k, v in pairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

local function tostringall(...)
	if select('#', ...) > 0 then
		return tostring(...), tostringall(select(2, ...))
	end
end

local function strtrim(str, chars)
	if not chars then
		chars = " 	\r\n"
	end
	local re = '['..chars:gsub("([%]%.%^%-%%])", "%%%1")..']*'
	return str:gsub('^'..re, ''):gsub(re..'$', '')
end

local function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end

local funcs = {
	format = string.format,
	gsub = string.gsub,
	strsplit = strsplit,
	strjoin = strjoin,
	strconcat = strconcat,
	strtrim = strtrim,
	tostringall = tostringall,

	tinsert = table.insert,
	tremove = table.remove,
	tconcat = table.concat,
	tContains = tContains,
	tconcat = table.concat,
	sort = table.sort,
	wipe = wipe,

	acos = function(value) return math.deg(math.acos(value)) end,
	asin = function(value) return math.deg(math.asin(value)) end,
	atan = function(value) return math.deg(math.atan(value)) end,
	atan2 = function(y, x) return math.deg(math.atan2(y, x)) end,
	cos = function(degrees) return math.cos(math.rad(degrees)) end,
	sin = function(degrees) return math.sin(math.rad(degrees)) end,
	tan = function(degrees) return math.tan(math.rad(degrees)) end,

	bit = assert(require('bit'), 'Either bitlib or luabitop is required.')
}

for key, func in pairs(string) do
	funcs["str"..key] = func
end
for key, func in pairs(math) do
	if not funcs[key] then
		funcs[key] = func
	end
end

return setmetatable(funcs, { __index = _G })
