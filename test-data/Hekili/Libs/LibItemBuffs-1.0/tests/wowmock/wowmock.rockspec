rockspec_format = "1.0"
package = "wowmock"
version = "master"
source = {
	url = "https://github.com/Adirelle/wowmock/archive/master.zip",
	dir = "wowmock-master"
}
description = {
	summary = "WoW environment mock for unit testing.",
	detailed = "Emulates the Lua environment with mocking possibilities.",
	homepage = "https://github.com/Adirelle/wowmock",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "builtin",
	modules = {
		wowmock = "wowmock.lua",
		wowlua = "wowlua.lua"
	}
}
