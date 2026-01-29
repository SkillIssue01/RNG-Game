-- Local Script 

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Supprimer l'écran de base Roblox
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- 2. Création de l'interface (Ton design)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Name = "Background"
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
bg.Parent = screenGui

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.fromScale(0.4, 0.2)
container.Position = UDim2.fromScale(0.5, 0.5)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundTransparency = 1
container.Parent = bg

local title = Instance.new("TextLabel")
title.Text = "PREPARING RNG..."
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 32
title.Size = UDim2.fromScale(1, 0.4)
title.BackgroundTransparency = 1
title.Parent = container

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, 0, 0, 10)
barBg.Position = UDim2.fromScale(0, 0.6)
barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
barBg.Parent = container
Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
fill.Parent = barBg
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

-- 3. Attente que le jeu soit chargé techniquement
if not game:IsLoaded() then game.Loaded:Wait() end

-- 4. SIMULATION DE CHARGEMENT (Plus fiable et rapide)
-- Au lieu de charger tous les descendants (trop lourd), on simule une progression
local loadingTime = 3 -- Le chargement durera environ 3 secondes
local steps = 50

for i = 1, steps do
	local progress = i / steps
	TweenService:Create(fill, TweenInfo.new(loadingTime/steps, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(progress, 1)}):Play()
	task.wait(loadingTime / steps)
end

-- 5. Fin du chargement
title.Text = "READY!"
task.wait(0.1)

local loadingComplete = Instance.new("StringValue")
loadingComplete.Name = "LoadingComplete"
loadingComplete.Parent = ReplicatedFirst
print("LoadingController : Signal envoyé, début du fondu.")

-- Animation de disparition
local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
TweenService:Create(bg, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(title, fadeInfo, {TextTransparency = 1}):Play()
TweenService:Create(barBg, fadeInfo, {BackgroundTransparency = 1}):Play()
TweenService:Create(fill, fadeInfo, {BackgroundTransparency = 1}):Play()

task.delay(0.6, function()
	screenGui:Destroy()
end)