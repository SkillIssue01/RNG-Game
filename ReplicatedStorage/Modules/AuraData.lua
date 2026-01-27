-- ReplicatedStorage.Modules.AuraData
-- Script Module
local AuraData = {}

AuraData.Biomes = {
	["Plaine"] = {
		Color = Color3.fromRGB(100, 200, 100),
		Auras = {
			{Name = "Herbe", Chance = 1, Rarity = "Commun"},
			{Name = "Sable", Chance = 5, Rarity = "Commun"}, 
			{Name = "Vent", Chance = 50, Rarity = "Peu Commun"}
		}
	}, -- Virgule ajoutée entre les biomes
	["Wasteland"] = {
		Color = Color3.fromRGB(200, 100, 50),
		Auras = {
			{Name = "Déchet", Chance = 1, Rarity = "Commun"},
			{Name = "Radiatif", Chance = 500, Rarity = "Rare"},
			{Name = "Mutation", Chance = 5000, Rarity = "Épique"}
		}
	}
}

-- Correction de la boucle de tri
for biome, data in pairs(AuraData.Biomes) do
	-- On cible 'data.Auras' et non 'data' tout court
	table.sort(data.Auras, function(a, b)
		return a.Chance > b.Chance
	end)
end

return AuraData