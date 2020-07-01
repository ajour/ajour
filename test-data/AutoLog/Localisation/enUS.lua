local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("AutoLog", "enUS", true)
if not L then return end

-- Chat commands
L["autolog"] = true
L["al"] = true

-- Configuration strings
L["Enable auto logging"] = true
L["If unchecked, AutoLog will never enable Combat Logging"] = true
L["Ignore LFR Raids"] = true
L["Log 5 player heroic instances"] = true
L["Normal Raids"] = true
L["Heroic Raids"] = true
L["Mythic Raids"] = true
L["LFR Raids"] = true
L["Raid finder instances where you want to log combat"] = true
L["Raid instances where you want to log combat"] = true
L["The Dragon Wastes"] = true
L["Only log guild runs"] = true
L["Start/Stop logging"] = true
L["Logging state"] = true
L["Checked if combat logging is currently on"] = true
L["Hide Cataclysm raids"] = true
L["Hide Mists of Pandaria raids"] = true
L["Hide Warlords of Draenor raids"] = true
L["Hide Legion raids"] = true
L["Show combat log status on screen"] = true
L["Log 5 player challenge mode instances"] = true
L["Log 5 player mythic dungeons"] = true
L["On"] = true
L["Off"] = true

-- Load/Disable strings
L[" loaded."] = true
L["AutoLog Disabled"] = true

-- others
L["Combat logging turned on"] = true
L["Combat logging turned off"] = true
L["AutoLog's settings have changed from character based to account based. Please check your settings now."] = true
L["Log all raids"] = true
L["Log all raids regardless of individual raid settings"] = true
L["Display in chat"] = true
L["Display the logging status in the chat window"] = true
L["Minimum level"] = true
L["Logging will not be enabled for mythic levels lower than this."] = true
