-- Script basique
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RNGService = require(script.Parent:WaitForChild("RNGService"))
local BiomeService = require(script.Parent:WaitForChild("BiomeService"))

local RequestRoll = ReplicatedStorage.Events.RequestRoll

-- Cette fonction s'exécute quand le joueur clique sur "Roll" (Côté Client)
RequestRoll.OnServerInvoke = function(player)
	-- 1. On identifie le biome
	local currentBiome = BiomeService.GetCurrentBiome(player)

	-- 2. On lance le dé
	local rolledAura = RNGService.Roll(player, currentBiome)

	-- 3. On retourne l'aura gagnée au client (pour l'affichage UI)
	print(player.Name .. " a obtenu : " .. rolledAura.Name .. " dans le biome " .. currentBiome)
	return rolledAura
end