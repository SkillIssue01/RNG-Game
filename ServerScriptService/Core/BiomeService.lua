-- Script basique
local BiomeService = {}

-- Paramètres de détection
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

function BiomeService.GetCurrentBiome(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		return "Plaine" 
	end

	-- On cherche les zones dans Workspace.Zones
	overlapParams.FilterDescendantsInstances = {workspace.Zones}

	local rootPart = character.HumanoidRootPart
	local parts = workspace:GetPartBoundsInRadius(rootPart.Position, 2, overlapParams)

	for _, part in ipairs(parts) do
		-- On récupère le nom du biome via l'attribut que nous avons créé
		local biomeName = part:GetAttribute("BiomeName")
		if biomeName then
			return biomeName
		end
	end

	return "Plaine" -- Biome par défaut
end

return BiomeService