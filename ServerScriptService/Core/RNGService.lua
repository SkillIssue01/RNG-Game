-- Script basique
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraData = require(ReplicatedStorage.Modules.AuraData)

local RNGService = {}

-- Fonction principale de tirage
function RNGService.Roll(player, biomeName)
	local biomeAuras = AuraData.Biomes[biomeName] or AuraData.Biomes["Plaine"]
	
	-- On génère un nombre aléatoire (on peut utiliser Random.new() pour plus de précision)
	local rng = Random.new()
	
	-- On parcourt les auras du biome (déjà triées de la plus rare à la plus commune)
	for _, aura in ipairs(biomeAuras) do
		-- On vérifie si le joueur "tombe" sur la chance (1 sur aura.Chance)
		-- Exemple : si Chance = 5000, on a 1 chance sur 5000 que l'id soit 1
		if rng:NextInteger(1, aura.Chance) == 1 then
			return aura -- Le joueur a gagné cette aura !
		end
	end
	-- Si par miracle rien n'est tombé, on donne l'aura par défaut (la première du biome)
	return biomeAuras[#biomeAuras]
end

return RNGService