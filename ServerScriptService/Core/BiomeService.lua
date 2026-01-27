-- Module Script
local BiomeService = {} -- Étape 1 : On crée la table

-- Étape 2 : On attache la fonction à la table (BIEN UTILISER LE POINT)
function BiomeService.GetCurrentBiome(player) 
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then 
		return "Plaine" 
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = {workspace:WaitForChild("Zones")} -- Ajout de sécurité

	local rootPart = character.HumanoidRootPart
	local parts = workspace:GetPartBoundsInRadius(rootPart.Position, 2, overlapParams)

	for _, part in ipairs(parts) do
		local biomeName = part:GetAttribute("BiomeName")
		if biomeName then
			return biomeName
		end
	end

	return "Plaine"
end

return BiomeService -- Étape 3 : ON REVOIE LA TABLE (Indispensable)