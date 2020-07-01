--[[
wowmock - WoW environment mock
Copyright 2014 Adirelle (adirelle@gmail.com)
See LICENSE for usage.
--]]

local wowlua = require('wowlua')

local cache = {}

return function(path, globals, ...)
	local env = {}
	if globals then
		setmetatable(env, {
			__index = function(self, name)
				local value = wowlua[name]
				if value == nil then
					value = globals[name]
				end
				self[name] = value
				return value
			end
		})
	else
		setmetatable(env, { __index = wowlua })
	end
	env._G = env
	local chunk = cache[path]
	if not chunk then
		local msg
		chunk, msg = loadfile(path)
		if not chunk then
			error(msg, 2)
		end
		cache[path] = chunk
	end
	setfenv(chunk, env)
	return chunk(...)
end
