TODO:
Favourites menu
Roll only through favourites
]]--

local mod = RegisterMod("RandomRainbowMaggy", 1)
local rng = RNG() --RNG is non-inclusive
local SaveState = {}

local debug_ = false -- Enable debug MCM option


----------------------------------------------------------------
--------------------------Default-Settings----------------------

local modSettings = {
	--Color
	["random"] = true,
	["gradient"] = false,
	["monochrome"] = false,

	--Triggers
	["updateOnFloor"] = false,
	["updateOnRoom"] = true, 
	["updateOnDmg"] = true,
	--["updateOnCollectiblePickup"] = false,
	["updateOnUse"] = false,
	["updateOnFrame"] = false,
	["onFrameDelay"] = 10,

	["manual"] = false,
	["manual_locks"] = {0, 0, 0, 0, 0, 0}, --Must be multiplied by 10, see MCM TODO

	--Locks
	["locks_enabled"] = {true, true, true, true, true, true},
	
	--Debug
	["debug"] = false,
	
	["current"] = {0, 0, 0, 0, 0, 0}
}


----------------------------------------------------------------
------------------------------Init------------------------------

local costume_count = 6

--Costumes Array
local Locks = {}
local DefaultLocks = {}
for i = 1, costume_count do
	Locks[i] = {}

	local defaultfile = "gfx/characters/lock_" .. i .. ".anm2"
	DefaultLocks[i] = Isaac.GetCostumeIdByPath(defaultfile)

	for j = 0, 350, 10 do
		local file = "gfx/characters/lock_" .. i .. "_" .. j .. ".anm2"
		Locks[i][j] = Isaac.GetCostumeIdByPath(file)
	end
end


----------------------------------------------------------------
---------------------------Callbacks----------------------------

function mod:onStart()
	mod:AddCostumes(false)
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onStart)

function mod:onFloor()
	if modSettings["updateOnFloor"] then
		mod:AddCostumes(false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.onFloor)

function mod:onRoom()
	if modSettings["updateOnRoom"] then
		mod:AddCostumes(false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onRoom)

function mod:onDmg()
	if modSettings["updateOnDmg"] then
		mod:AddCostumes(false)
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onDmg, EntityType.ENTITY_PLAYER)

function mod:onUse()
	if modSettings["updateOnUse"] then
		mod:AddCostumes(false)
	end
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.onUse)

local delay = 1
function mod:onFrame()
	if delay == 0 then
		if modSettings["updateOnFrame"]  then
			mod:AddCostumes(false)
		end
		delay = modSettings["onFrameDelay"]
	end
	delay = delay - 1
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.onFrame)

--Protect Costume
local protect_count = 1
function mod:protect()
	local player = Isaac.GetPlayer(0)

	if player:GetPlayerType() == 1 and player:GetCollectibleCount() ~= protect_count then --1: Maggy
		mod:AddCostumes(true)
		protect_count = player:GetCollectibleCount()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.protect)

--TODO: Whitelist for non-conflicting costumes
function mod:protectUse()
	local player = Isaac.GetPlayer(0)
	
	if player:GetPlayerType() == 1 then
		for i = 0, 121 do
			player:TryRemoveNullCostume(i) --NullItemID
		end
		mod:AddCostumes(true)
	end
end
mod:AddCallback(ModCallbacks.MC_USE_PILL, mod.protectUse)
mod:AddCallback(ModCallbacks.MC_USE_CARD, mod.protectUse)
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.protectUse)


----------------------------------------------------------------
---------------------Costume-Application------------------------

--TODO: Add multiple player support
--TODO: Refactor settings handling for this function
function mod:AddCostumes(readd)
	
	local player = Isaac.GetPlayer(0)

	local readd = false or readd

	local direction = 1
	local hue = 0
	
	if player:GetPlayerType() == 1 then --1: Maggy
		player:TryRemoveNullCostume(NullItemID.ID_MAGDALENE)
		
		for i = 1, costume_count do
			
			if readd then
				--Reapply costumes
				hue = modSettings["current"][i]
				player:AddNullCostume(Locks[i][hue])
			else
				--Hue logic
				if modSettings["gradient"] then
					if i == 1 then
						hue = rng:RandomInt(36) * 10
						direction = rng:RandomInt(2) == 1 and 1 or -1
						gradient_step = (rng:RandomInt(5)+1) * 10 * direction			
					else
						hue = (hue + gradient_step) % 360
					end

				elseif modSettings["monochrome"] then
					if i == 1 then
						hue = rng:RandomInt(36) * 10
					end
				
				elseif modSettings["manual"] then
					hue = modSettings["manual_locks"][i] * 10
				
				else
					hue = rng:RandomInt(36) * 10
				end
				
				--Enable Locks
				if modSettings["locks_enabled"][i] == true then
					player:AddNullCostume(Locks[i][hue])
				else
					player:AddNullCostume(DefaultLocks[i])
				end
				
				--Store current costume hues
				modSettings["current"][i] = hue
				modSettings["manual_locks"][i] = math.floor(modSettings["current"][i]/10)
			end
		end

		if modSettings["debug"] then
			str = ""
			for i = 1, costume_count do str = str .. " " .. modSettings["current"][i] end
			print("Hue:" .. str)
			if modSettings["gradient"] then
				print("Gradient step: " .. gradient_step)
			end
		end
		
		--Reload Manual Menu
		if ModConfigMenu then
			mod:makeMenu()
		end
	end
end


----------------------------------------------------------------
-------------------------Mod Config Menu------------------------

function mod:makeMenu()
	local modname = "Random Maggy"

	ModConfigMenu.RemoveCategory(modname)

-----------
--Color
-----------
	--Random: Bool
	ModConfigMenu.AddSetting(modname, "Color", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["random"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["random"] then
				onOff = "True"
			end
			return "Random: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["random"] = currentBool
			modSettings["monochrome"] = false
			modSettings["manual"] = false
			modSettings["gradient"] = not currentBool --Fallback MCM option
			mod:AddCostumes()
		end,
		Info = {"Randomly chosen colors! The default."}
	})
	
	--Gradient: Bool
	ModConfigMenu.AddSetting(modname, "Color", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["gradient"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["gradient"] then
				onOff = "True"
			end
			return "Gradient: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["gradient"] = currentBool
			
			modSettings["monochrome"] = false
			modSettings["manual"] = false
			
			if modSettings["gradient"] == false then
				modSettings["random"] = true
			else
				modSettings["random"] = false
			end
			
			mod:AddCostumes()
		end,
		Info = {"Gradual colour shift, the shift strength is random."}
	})
	
	--Monochrome: Bool
	ModConfigMenu.AddSetting(modname, "Color", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["monochrome"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["monochrome"] then
				onOff = "True"
			end
			return "Monochrome: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["monochrome"] = currentBool
			
			modSettings["gradient"] = false
			modSettings["random"] = false
			modSettings["manual"] = false
			
			if modSettings["monochrome"] == false then
				modSettings["random"] = true
			else
				modSettings["random"] = false
			end
			
			mod:AddCostumes()
		end,
		Info = {"A singular color."}
	})

-----------
--Manual
-----------
	ModConfigMenu.AddSpace(modname, "Color")
	
	--TODO: Fix ModConfigMenu Steps
	--Manual: Bool
	ModConfigMenu.AddSetting(modname, "Color", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["manual"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["manual"] then
				onOff = "True"
			end
			return "Manual: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["manual"] = currentBool
			modSettings["monochrome"] = false
			modSettings["gradient"] = false
			modSettings["updateOnFloor"] = false
			modSettings["updateOnRoom"] = false
			modSettings["updateOnDmg"] = false
			modSettings["updateOnUse"] = false
			modSettings["updateOnFrame"] = false
			
			if modSettings["manual"] == false then
				modSettings["random"] = true
			else
				modSettings["random"] = false
			end
			
			mod:AddCostumes()
		end,
		Info = {"Enable manual color, choose the hues below."}
	})
	
	--Strands: Int
	for i = 1, costume_count-1 do
		ModConfigMenu.AddSetting(modname, "Color", {
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return modSettings["manual_locks"][i]
			end,
			Minimum = 0,
			Maximum = 34,
			Display = function()
				local currentNum = modSettings["manual_locks"][i]
				return "Strand " .. i .. ": " .. currentNum*10
			end,
			OnChange = function(currentNum)
				modSettings["manual_locks"][i] = currentNum
				if modSettings["manual"] then
					mod:AddCostumes()
				end
			end,
			Info = {"Manual hue for strand " .. i .. "."}
		})
	end
	
	--Bow: Int
	ModConfigMenu.AddSetting(modname, "Color", {
		Type = ModConfigMenu.OptionType.NUMBER,
		CurrentSetting = function()
			return modSettings["manual_locks"][6]
		end,
		Minimum = 0,
		Maximum = 34,
		Display = function()
			local currentNum = modSettings["manual_locks"][6]
			return "Bow: " .. currentNum*10
		end,
		OnChange = function(currentNum)
			modSettings["manual_locks"][6] = currentNum
			if modSettings["manual"] then
				mod:AddCostumes()
			end
		end,
		Info = {"Manual hue for the bow."}
	})

-----------
--Triggers
-----------
	--updateOnFloor: Bool
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["updateOnFloor"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["updateOnFloor"] then
				onOff = "True"
			end
			return "Floor: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["updateOnFloor"] = currentBool
			
			if modSettings["manual"] then
				modSettings["random"] = true
				modSettings["manual"] = false
				mod:AddCostumes()
			end
		end,
		Info = {"Change hair color on entering a new floor."}
	})
	
	--updateOnRoom: Bool
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["updateOnRoom"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["updateOnRoom"] then
				onOff = "True"
			end
			return "Room: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["updateOnRoom"] = currentBool
			
			if modSettings["manual"] then
				modSettings["random"] = true
				modSettings["manual"] = false
				mod:AddCostumes()
			end
		end,
		Info = {"Change hair color on entering a new room."}
	})
	
	--updateOnDmg: Bool
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["updateOnDmg"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["updateOnDmg"] then
				onOff = "True"
			end
			return "Hurt: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["updateOnDmg"] = currentBool
			
			if modSettings["manual"] then
				modSettings["random"] = true
				modSettings["manual"] = false
				mod:AddCostumes()
			end
		end,
		Info = {"Change hair color on taking damage."}
	})
	
	--updateOnUse: Bool
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["updateOnUse"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["updateOnUse"] then
				onOff = "True"
			end
			return "Active: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["updateOnUse"] = currentBool
			
			if modSettings["manual"] then
				modSettings["random"] = true
				modSettings["manual"] = false
				mod:AddCostumes()
			end
		end,
		Info = {"Change hair color on using an active item."}
	})
	
	--TODO: Text color
	ModConfigMenu.AddSpace(modname, "Triggers")
	ModConfigMenu.AddText(modname, "Triggers", "Warning: May cause instability")
	
	--updateOnFrame: Bool
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["updateOnFrame"]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["updateOnFrame"] then
				onOff = "True"
			end
			return "Frame: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["updateOnFrame"] = currentBool
			
			if modSettings["manual"] then
				modSettings["random"] = true
				modSettings["manual"] = false
				mod:AddCostumes()
			end
		end,
		Info = {"Change hair color on every frame."}
	})
	
	--onFrameDelay: Int
	ModConfigMenu.AddSetting(modname, "Triggers", {
		Type = ModConfigMenu.OptionType.NUMBER,
		CurrentSetting = function()
			return modSettings["onFrameDelay"]
		end,
		Minimum = 1,
		Maximum = 120,
		Display = function()
			local currentNum = modSettings["onFrameDelay"]
			return "Delay: " .. currentNum
		end,
		OnChange = function(currentNum)
			modSettings["onFrameDelay"] = currentNum
			if modSettings["updateOnFrame"] then
				mod:AddCostumes()
			end
		end,
		Info = {"Number of game updates to delay for frame trigger. 60 = 1 second."}
	})


-----------
--Toggle
-----------
	--Strands: Bool
	for i = 1, costume_count-1 do
		ModConfigMenu.AddSetting(modname, "Toggle", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return modSettings["locks_enabled"][i]
			end,
			Display = function()
				local onOff = "False"
				if modSettings["locks_enabled"][i] then
					onOff = "True"
				end
				return "Strand "..i.. ": " .. onOff
			end,
			OnChange = function(currentBool)
				modSettings["locks_enabled"][i] = currentBool
			end,
			Info = {"Enable colors for strand "..i.. "."}
		})
	end

	--Bow: Bool
	ModConfigMenu.AddSetting(modname, "Toggle", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSettings["locks_enabled"][6]
		end,
		Display = function()
			local onOff = "False"
			if modSettings["locks_enabled"][6] then
				onOff = "True"
			end
			return "Bow: " .. onOff
		end,
		OnChange = function(currentBool)
			modSettings["locks_enabled"][6] = currentBool
		end,
		Info = {"Enable colors for the bow."}
	})
	
	ModConfigMenu.AddSpace(modname, "Toggle")
	
	--Enable ALL
	ModConfigMenu.AddSetting(modname, "Toggle", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return 0
		end,
		Display = function()
			return "Enable ALL"
		end,
		OnChange = function(currentBool)
			for i = 1, costume_count do
				modSettings["locks_enabled"][i] = true
			end
			mod:AddCostumes()
		end,
		Info = {"Enable all colors."}
	})
	
	--Disable ALL
	ModConfigMenu.AddSetting(modname, "Toggle", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return 0
		end,
		Display = function()
			return "Disable ALL"
		end,
		OnChange = function(currentBool)
			for i = 1, costume_count do
				modSettings["locks_enabled"][i] = false
			end
			mod:AddCostumes()
		end,
		Info = {"Disable all colors."}
	})
	
-----------
--Debug
-----------
	if debug_ then
		ModConfigMenu.AddSetting(modname, "Debug", {
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return modSettings["debug"]
			end,
			Display = function()
				local onOff = "False"
				if modSettings["debug"] then
					onOff = "True"
				end
				return "Debug: " .. onOff
			end,
			OnChange = function(currentBool)
				modSettings["debug"] = currentBool
			end,
			Info = {"Debug"}
		})
	end
end


----------------------------------------------------------------
----------------------------Savedata----------------------------

local json = require("json")

function mod:SaveGame()
	SaveState.Settings = {}
	
	for i, v in pairs(modSettings) do
		SaveState.Settings[tostring(i)] = modSettings[i]
	end
    mod:SaveData(json.encode(SaveState))
end
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.SaveGame)

function mod:OnGameStart(isSave)
	if defaultsChanged then
		mod:SaveGame()
	end	
	
    if mod:HasData() then	
		SaveState = json.decode(mod:LoadData())	
		
        for i, v in pairs(SaveState.Settings) do
			modSettings[tostring(i)] = SaveState.Settings[i]
		end

    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnGameStart)
