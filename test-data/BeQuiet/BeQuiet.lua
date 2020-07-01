--Initialize variables if they are not saved
if ENABLED == nil then
	ENABLED = 1
end

if ASHRAN == nil then
	ASHRAN = 0
end

if ISLANDS == nil then
	ISLANDS = 0
end

if NAZJATAR == nil then
	NAZJATAR = 0
end

version = "v2.0.3"

--Define withered army training zones
withered =	{
		"Temple of Fal'adora",
		"Falanaar Tunnels",
		"Shattered Locus"
		}

--Define island expedition zones
islands =	{
		"Crestfall",
		"Snowblossom Village",
		"Havenswood",
		"Jorundall",
		"Molten Cay",
		"Un'gol Ruins",
		"The Rotting Mire",
		"Whispering Reef",
		"Verdant Wilds",
		"The Dread Chain",
		"Skittering Hollow"
		}

--Create the frame
local f = CreateFrame("Frame")

--Main function
function f:OnEvent(event, addon)
	--Check if the talkinghead addon is being loaded
	if addon == "Blizzard_TalkingHeadUI" then
		hooksecurefunc("TalkingHeadFrame_PlayCurrent", function()
			--Query current zone and subzone when talking head is triggered
			zoneName = GetSubZoneText();
			mainZoneName = GetZoneText();
			--Only run this logic if the functionality is turned on
			if ENABLED == 1 then
				--Block the talking head unless we have a whitelisted condition
				if not (mainZoneName == 'Ashran' and ASHRAN == 1) and
					not (has_value(islands, mainZoneName) and ISLANDS == 1) and
					not (has_value(withered, zoneName)) and
					not (mainZoneName == 'Nazjatar' and NAZJATAR == 1) then
					--Close the talking head
					TalkingHeadFrame_CloseImmediately()
				end
			end
		end)
	self:UnregisterEvent(event)
	end
end

--Function to check if value in array
function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

--Slash command function
local function MyAddonCommands(arg)
	if arg == 'off' then
		ENABLED = 0
		print('Now allowing talking heads')
	elseif arg == 'on' then
		ENABLED = 1
		print('Now blocking talking heads except for permitted zones')
	elseif arg == 'ashran' then
		if ASHRAN == 0 then
			ASHRAN = 1
			print('Talking heads will now be allowed in Ashran')
		elseif ASHRAN == 1 then
			ASHRAN = 0
			print ('Talking heads will now be blocked in Ashran')
		end
	elseif arg == 'islands' then
		if ISLANDS == 0 then
			ISLANDS = 1
			print('Talking heads will now be allowed in Island Expeditions')
		elseif ISLANDS == 1 then
			ISLANDS = 0
			print('Talking heads will now be blocked in Island Expeditions')
		end
	elseif arg == 'nazjatar' then
		if NAZJATAR == 0 then
			NAZJATAR = 1
			print('Talking heads will now be allowed in Nazjatar')
		elseif NAZJATAR == 1 then
			NAZJATAR = 0
			print('Talking heads will now be blocked in Nazjatar')
		end
	else
		if ENABLED == 0 then
			print('BeQuiet ' .. version .. ' is currently disabled')
		elseif ENABLED == 1 then
			print('BeQuiet ' .. version .. ' is currently enabled')
			if ASHRAN == 0 then
				print('Talking heads are currently blocked in Ashran')
			elseif ASHRAN == 1 then
				print('Talking heads are currently allowed in Ashran')
			end
			if ISLANDS == 0 then
				print('Talking heads are currently blocked in Island Expeditions')
			elseif ISLANDS == 1 then
				print('Talking heads are currently allowed in Island Expeditions')
			end
			if NAZJATAR == 0 then
				print('Talking heads are currently blocked in Nazjatar')
			elseif NAZJATAR == 1 then
				print('Talking heads are currently allowed in Nazjatar')
			end
		end
		print('-----------')
		print('<on | off> to enable or disable BeQuiet')
		print('<ashran | islands | nazjatar> to toggle talking heads in Ashran/Islands/Nazjatar')
	end
end

--Add /bq to slash command list and register its function
SLASH_BQ1 = '/bq'
SlashCmdList["BQ"] = MyAddonCommands

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)
