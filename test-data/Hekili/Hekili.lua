-- Hekili.lua
-- April 2014

local addon, ns = ...
Hekili = LibStub("AceAddon-3.0"):NewAddon( "Hekili", "AceConsole-3.0", "AceSerializer-3.0" )
Hekili.Version = GetAddOnMetadata("Hekili", "Version")

if Hekili.Version == ( "@" .. "project-version" .. "@" ) then Hekili.Version = "Development-" .. date("%Y%m%d" ) end

Hekili.AllowSimCImports = true

local format = string.format
local upper  = string.upper


ns.PTR = select( 4, GetBuildInfo() ) > 80300


ns.Patrons = {
    -- Expecto
	"Akh270",
	"Brugrabud",
	"Elmner",
	"Rusah",
	"Spaten",
	"Spy",
	"SuperRsk",

    -- Supreme
	"Annddyypandy",
	"Ash",
	"av8ordoc",
	"Belatar",
	"Borelia",
	"Bsirk",
	"cortland",
	"DarkosKiLLz",
	"Dele",
	"Dez",
	"Garumako",
	"Goobkill",
	"GSMarketing",
	"Harkun",
	"Hollaputt",
	"Kyatastrophe",
	"Manni",
	"marcusawereally",
	"Meeat",
	"mojodisu.",
	"ODB/Tilt",
	"PJ",
	"Ramen",
	"Rivertam",
	"skrrskrr",
	"Stalorirn",
	"Torsti",
	"unlaern",
	"zvda",
	"Zyon",

	-- Patron
	"Abra",
	"Aern",
	"Alarius",
	"Alvi",
	"ApexPlatypus",
	"cafasdon",
	"chckxy",
	"djthomp",
	"doboro",
	"Electricfury (Vagos)",
	"Fastobreiko",
	"Grayscale",
	"Guycrush Fleetwood",
	"Hexel",
	"Ingrathis",
	"jawj",
	"Kretol",
	"Leorus",
	"Loraniden",
	"MrBean73",
	"muze",
	"neurolol",
	"Opie",
	"Sarthol",
	"Sebstar",
	"Seniroth",
	"Sym",
	"Ted",
	"Tekfire",
	"Tic",
	"Tohr",
	"twiggs",
	"Twiss",
	"Wargus (Just 'Gus)",
	"Weedwalker",
	"Yeitzo",
	"zeus",
}
table.sort( ns.Patrons, function( a, b ) return upper( a ) < upper( b ) end  )



do
    local cpuProfileDB = {}

    function Hekili:ProfileCPU( name, func )
        cpuProfileDB[ name ] = func
    end

	ns.cpuProfile = cpuProfileDB
	

	local frameProfileDB = {}

	function Hekili:ProfileFrame( name, f )
		frameProfileDB[ name ] = f
	end

	ns.frameProfile = frameProfileDB
end


ns.lib = {
    Format = {}
}


-- 04072017:  Let's go ahead and cache aura information to reduce overhead.
ns.auras = {
    target = {
        buff = {},
        debuff = {}
    },
    player = {
        buff = {},
        debuff = {}
    }
}

Hekili.Class = {
    specs = {},
    num = 0,

    file = "NONE",

	resources = {},
    talents = {},
    pvptalents = {},
	auras = {},
	auraList = {},
    powers = {},
	gear = {},
	
	knownAuraAttributes = {},

    stateExprs = {},
    stateFuncs = {},
    stateTables = {},

	abilities = {},
	abilityByName = {},
    abilityList = {},
    itemList = {},
    itemMap = {},
    itemPack = {
        lists = {
            items = {}
        }
    },

    packs = {},

    pets = {},
    totems = {},

    potions = {},
    potionList = {},

	hooks = {},
    range = 8,
	settings = {},
    stances = {},
	toggles = {},
	variables = {},
}

Hekili.Scripts = {
    DB = {},
    Channels = {},
    PackInfo = {},
}

Hekili.State = {}

ns.hotkeys = {}
ns.keys = {}
ns.queue = {}
ns.targets = {}
ns.TTD = {}

ns.UI = {
    Displays = {},
    Buttons = {}
}

ns.debug = {}
ns.snapshots = {}


function Hekili:Query( ... )

	local output = ns

	for i = 1, select( '#', ... ) do
		output = output[ select( i, ... ) ]
    end

    return output
end


function Hekili:Run( ... )

	local n = select( "#", ... )
	local fn = select( n, ... )

	local func = ns

	for i = 1, fn - 1 do
		func = func[ select( i, ... ) ]
    end

    return func( select( fn, ... ) )

end


local debug = ns.debug
local active_debug
local current_display

local lastIndent = 0

function Hekili:SetupDebug( display )
    if not self.ActiveDebug then return end
    if not display then return end

    current_display = display

    debug[ current_display ] = debug[ current_display ] or {
        log = {},
        index = 1
    }
    active_debug = debug[ current_display ]
	active_debug.index = 1
	
	lastIndent = 0
	
	local pack = self.State.system.packName

	self:Debug( "New Recommendations for [ %s ] requested at %s ( %.2f ); using %s( %s ) priority.", display, date( "%H:%M:%S"), GetTime(), self.DB.profile.packs[ pack ].builtIn and "built-in " or "", pack )
end


function Hekili:Debug( ... )
    if not self.ActiveDebug then return end
	if not active_debug then return end
	
	local indent, text = ...
	local start

	if type( indent ) ~= "number" then
		indent = lastIndent
		text = ...
		start = 2
	else
		lastIndent = indent
		start = 3
	end

	local prepend = format( indent > 0 and ( "%" .. ( indent * 4 ) .. "s" ) or "%s", "" )
	text = text:gsub("\n", "\n" .. prepend )

	active_debug.log[ active_debug.index ] = format( "%" .. ( indent > 0 and ( 4 * indent ) or "" ) .. "s" .. text, "", select( start, ... ) )
    active_debug.index = active_debug.index + 1
end


local snapshots = ns.snapshots

function Hekili:SaveDebugSnapshot( dispName )

	for k, v in pairs( debug ) do
		
		if dispName == nil or dispName == k then
			if not snapshots[ k ] then
				snapshots[ k ] = {}
			end

			for i = #v.log, v.index, -1 do
				v.log[ i ] = nil
			end

			table.insert( v.log, 1, self:GenerateProfile() )
			table.insert( snapshots[ k ], table.concat( v.log, "\n" ) )
		end

    end

end

Hekili.Snapshots = ns.snapshots



ns.Tooltip = CreateFrame( "GameTooltip", "HekiliTooltip", UIParent, "GameTooltipTemplate" )
