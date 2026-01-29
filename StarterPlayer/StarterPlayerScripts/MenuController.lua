local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local UpdateSpinsEvent = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("UpdateSpins")

-- --- CONFIGURATION ---
local COLORS = {
	BackgroundDark = Color3.fromRGB(8, 8, 10),
	PanelDark = Color3.fromRGB(15, 15, 20),
	PanelLight = Color3.fromRGB(25, 25, 30),

	ButtonNormal = Color3.fromRGB(25, 28, 35),
	ButtonHover = Color3.fromRGB(65, 70, 85),

	AccentBlue = Color3.fromRGB(0, 140, 255),
	AccentBlueHover = Color3.fromRGB(80, 180, 255),

	AccentRed = Color3.fromRGB(200, 40, 40),
	AccentGreen = Color3.fromRGB(40, 200, 80),
	AccentGold = Color3.fromRGB(255, 180, 0),

	TextWhite = Color3.fromRGB(240, 240, 240),
	TextGray = Color3.fromRGB(150, 150, 160),
	Locked = Color3.fromRGB(40, 40, 40),
	Glow = Color3.fromRGB(255, 255, 255)
}

local currentSpins = 20 

-- Variables Logic
local currentEquippedFamilyData = nil 
local skippedFamilies = {} 

local familiesData = {
	{name = "Rookie", rarity = "COMMON", chanceVal = 79.37, displayChance = "79.37 %", color = Color3.fromRGB(180, 180, 180)},
	{name = "Explorer", rarity = "RARE", chanceVal = 19.00, displayChance = "19.00 %", color = Color3.fromRGB(0, 190, 255)},
	{name = "Gambler", rarity = "EPIC", chanceVal = 1.00, displayChance = "1.00 %", color = Color3.fromRGB(200, 0, 255)},
	{name = "Hunter", rarity = "LEGENDARY", chanceVal = 0.50, displayChance = "0.50 %", color = Color3.fromRGB(255, 180, 0)},
	{name = "Visionary", rarity = "MYTHIC", chanceVal = 0.10, displayChance = "0.10 %", color = Color3.fromRGB(255, 0, 80)}, 
	{name = "Aura Farmer", rarity = "SECRET", chanceVal = 0.03, displayChance = "0.03 %", color = Color3.fromRGB(255, 255, 255)}, 
}

local SAFETY_RARITIES = {
	["EPIC"] = true,      
	["LEGENDARY"] = true,
	["MYTHIC"] = true,
	["SECRET"] = true
}

local function toggleCoreUI(visible)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, visible)
	end)
end

local function applyProStyle(guiObject, cornerRadius, strokeColor, strokeThickness)
	local corner = guiObject:FindFirstChild("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 6)
	corner.Parent = guiObject

	if strokeColor then
		local stroke = guiObject:FindFirstChild("UIStroke") or Instance.new("UIStroke")
		stroke.Color = strokeColor
		stroke.Thickness = strokeThickness or 1.5
		stroke.Transparency = 0.2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = guiObject
		return stroke
	end
	return nil
end

-- === EFFETS VISUELS ===

local function applyScrollingMythicEffect(uiStroke, textLabels)
	uiStroke.Color = Color3.fromRGB(255, 120, 0)
	uiStroke.Transparency = 0
	uiStroke.Thickness = 2

	local gradientMaster = Instance.new("UIGradient")
	gradientMaster.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 30, 30)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 160, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 30, 30)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 160, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 30, 30))
	})
	gradientMaster.Rotation = 0 

	local activeGradients = {}

	for _, lbl in ipairs(textLabels) do
		lbl.TextColor3 = Color3.new(1,1,1) 
		local grad = gradientMaster:Clone()
		grad.Parent = lbl
		table.insert(activeGradients, grad)
	end

	task.spawn(function()
		local offsetTimer = 0
		local speed = 0.7 
		while uiStroke and uiStroke.Parent do 
			local dt = RunService.RenderStepped:Wait()
			offsetTimer = offsetTimer - (dt * speed)
			local currentOffset = offsetTimer % 1
			local finalOffsetX = currentOffset - 1
			for _, grad in ipairs(activeGradients) do
				if grad and grad.Parent then grad.Offset = Vector2.new(finalOffsetX, 0) end
			end
		end
	end)
end

local function applySecretSpin(uiStroke)
	uiStroke.Thickness = 2.5
	uiStroke.Transparency = 0
	uiStroke.Color = Color3.new(1,1,1)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	gradient.Parent = uiStroke

	task.spawn(function()
		local rotation = 0
		while uiStroke and uiStroke.Parent do
			local dt = RunService.RenderStepped:Wait()
			rotation = rotation + (120 * dt)
			if rotation > 360 then rotation = 0 end
			gradient.Rotation = rotation
		end
	end)
end

local function triggerGlitchEffect(realLabel, rollWindow)
	if not realLabel or not rollWindow then return end
	realLabel.TextTransparency = 1
	local fakeLabel = realLabel:Clone()
	fakeLabel.Name = "GLITCH_MAIN"
	fakeLabel.Parent = rollWindow 
	fakeLabel.TextTransparency = 0
	fakeLabel.BackgroundTransparency = 1
	fakeLabel.Size = UDim2.new(1, 0, 0, 120) 
	fakeLabel.Position = UDim2.fromScale(0.5, 0.5)
	fakeLabel.AnchorPoint = Vector2.new(0.5, 0.5)

	local ghostRed = fakeLabel:Clone(); ghostRed.Name = "G_RED"; ghostRed.TextColor3 = Color3.new(1,0,0); ghostRed.TextTransparency=0.5; ghostRed.Parent=rollWindow
	local ghostCyan = fakeLabel:Clone(); ghostCyan.Name = "G_CYAN"; ghostCyan.TextColor3 = Color3.new(0,1,1); ghostCyan.TextTransparency=0.5; ghostCyan.Parent=rollWindow

	task.spawn(function()
		local startTime = tick()
		local originalPos = UDim2.fromScale(0.5, 0.5)
		while tick() - startTime < 1.5 do
			RunService.RenderStepped:Wait()
			local i = math.random(2, 6)
			fakeLabel.Position = originalPos + UDim2.fromOffset(math.random(-i,i), math.random(-i,i))
			fakeLabel.Rotation = math.random(-2, 2)
			ghostRed.Position = originalPos + UDim2.fromOffset(math.random(-i*2,i*2), math.random(-i,i))
			ghostRed.Visible = (math.random()>0.3)
			ghostCyan.Position = originalPos + UDim2.fromOffset(math.random(-i*2,i*2), math.random(-i,i))
			ghostCyan.Visible = (math.random()>0.3)
			if math.random()>0.9 then fakeLabel.TextColor3 = Color3.new(0,0,0) else fakeLabel.TextColor3 = Color3.new(1,1,1) end
		end
		fakeLabel:Destroy(); ghostRed:Destroy(); ghostCyan:Destroy()
		if realLabel then realLabel.TextTransparency = 0; realLabel.TextColor3 = Color3.new(1,1,1) end
	end)
end

local function createConfettiExplosion(color, centerZone)
	local centerPos = UDim2.new(0.5, 0, 0.35, 0)
	for i = 1, 50 do
		local p = Instance.new("Frame")
		p.BackgroundColor3 = color
		p.Size = UDim2.fromOffset(math.random(6, 12), math.random(6, 12))
		p.Position = centerPos
		p.Rotation = math.random(0, 360)
		p.BorderSizePixel = 0
		p.Parent = centerZone 
		local a = math.rad(math.random(0, 360))
		local d = math.random(150, 400)
		local target = centerPos + UDim2.fromOffset(math.cos(a)*d, math.sin(a)*d)
		local t = TweenService:Create(p, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position=target, Rotation=p.Rotation+math.random(90,180), BackgroundTransparency=1, Size=UDim2.new()})
		t:Play(); Debris:AddItem(p, 1.1)
	end
end

-- --- DÉBUT UI ---
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainMenuPro"
screenGui.Enabled = false 
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local slot1Label = nil 
local statsLabels = {} 

-- ====================================================================
-- INTERFACE PRINCIPALE
-- ====================================================================

local familyFrame = Instance.new("Frame")
familyFrame.Name = "FamilyInterface"
familyFrame.Size = UDim2.fromScale(1, 1)
familyFrame.BackgroundColor3 = COLORS.BackgroundDark
familyFrame.Visible = false
familyFrame.Parent = screenGui

local bgGradient = Instance.new("UIGradient")
bgGradient.Rotation = 45
bgGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, COLORS.BackgroundDark), ColorSequenceKeypoint.new(1, COLORS.PanelDark)})
bgGradient.Parent = familyFrame

-- --- BOUTON AUTOSKIP (INTÉGRÉ DANS LA BARRE) ---
-- Barre du bas
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, 0, 0.15, 0)
bottomBar.Position = UDim2.new(0, 0, 1, 0)
bottomBar.AnchorPoint = Vector2.new(0, 1)
bottomBar.BackgroundColor3 = COLORS.PanelDark
bottomBar.Parent = familyFrame

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, 0, 0, 2)
sep.BackgroundColor3 = COLORS.AccentBlue
sep.BorderSizePixel = 0
sep.Parent = bottomBar

local autoSkipBtn = Instance.new("TextButton")
autoSkipBtn.Name = "AutoSkipBtn"
autoSkipBtn.Text = "AUTOSKIP"
autoSkipBtn.Size = UDim2.new(0, 130, 0, 60)
autoSkipBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
autoSkipBtn.AnchorPoint = Vector2.new(0, 0.5)
autoSkipBtn.BackgroundColor3 = COLORS.ButtonNormal
autoSkipBtn.TextColor3 = COLORS.TextGray
autoSkipBtn.Font = Enum.Font.GothamBold
autoSkipBtn.TextSize = 14
autoSkipBtn.ZIndex = 20 
autoSkipBtn.Parent = bottomBar
applyProStyle(autoSkipBtn, 6, COLORS.TextGray, 1)

-- --- CALCUL DE LA TAILLE DU MENU AUTOSKIP ---
-- 1. Compter les items valides
local validItemsCount = 0
for _, fam in ipairs(familiesData) do
	if SAFETY_RARITIES[fam.rarity] then
		validItemsCount = validItemsCount + 1
	end
end

-- 2. Calculer la hauteur (Items * 30px + Padding + Marges)
local ITEM_HEIGHT_SK = 30
local PADDING_SK = 5
local MARGIN_SK = 10 -- 5 top + 5 bottom
local calculatedHeight = (validItemsCount * ITEM_HEIGHT_SK) + ((validItemsCount - 1) * PADDING_SK) + MARGIN_SK

-- MENU AUTOSKIP (TAILLE ADAPTÉE)
local autoSkipMenu = Instance.new("Frame")
autoSkipMenu.Name = "AutoSkipMenu"
-- On applique la hauteur calculée
autoSkipMenu.Size = UDim2.fromOffset(200, calculatedHeight)
autoSkipMenu.Position = UDim2.new(0.5, 0, 0, -25) -- 25 pixels au dessus du bouton
autoSkipMenu.AnchorPoint = Vector2.new(0.5, 1)
autoSkipMenu.BackgroundColor3 = COLORS.PanelDark
autoSkipMenu.Visible = false
autoSkipMenu.ZIndex = 50 
autoSkipMenu.Parent = autoSkipBtn
applyProStyle(autoSkipMenu, 6, COLORS.AccentBlue, 1)

local asList = Instance.new("ScrollingFrame")
asList.Size = UDim2.new(1, -10, 1, -10)
asList.Position = UDim2.fromOffset(5, 5)
asList.BackgroundTransparency = 1
asList.BorderSizePixel = 0
asList.ScrollBarThickness = 0 -- Scrollbar cachée car inutile (taille parfaite)
asList.ZIndex = 51
asList.Parent = autoSkipMenu
local asLayout = Instance.new("UIListLayout"); asLayout.Padding = UDim.new(0, PADDING_SK); asLayout.Parent = asList

-- Génération Checkboxes Autoskip
for _, fam in ipairs(familiesData) do
	if SAFETY_RARITIES[fam.rarity] then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT_SK)
		row.BackgroundTransparency = 1
		row.ZIndex = 52
		row.Parent = asList

		local lbl = Instance.new("TextLabel")
		lbl.Text = fam.name
		lbl.TextColor3 = fam.color
		lbl.Size = UDim2.new(0.7, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextSize = 12
		lbl.ZIndex = 52
		lbl.Parent = row

		local box = Instance.new("TextButton")
		box.Size = UDim2.fromOffset(20, 20)
		box.Position = UDim2.new(1, -10, 0.5, 0)
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.BackgroundColor3 = COLORS.ButtonNormal
		box.Text = ""
		box.ZIndex = 52
		box.Parent = row
		applyProStyle(box, 4, COLORS.TextGray, 1)

		box.MouseButton1Click:Connect(function()
			if skippedFamilies[fam.name] then
				skippedFamilies[fam.name] = false
				box.BackgroundColor3 = COLORS.ButtonNormal
				box.Text = ""
			else
				skippedFamilies[fam.name] = true
				box.BackgroundColor3 = COLORS.AccentBlue
				box.Text = "✓"
				box.TextColor3 = COLORS.TextWhite
			end
		end)
	end
end
asList.CanvasSize = UDim2.new(0,0,0, 0) -- Pas de scroll

autoSkipBtn.MouseButton1Click:Connect(function()
	autoSkipMenu.Visible = not autoSkipMenu.Visible
end)


-- --- WARNING POPUP ---
local warningFrame = Instance.new("Frame")
warningFrame.Name = "WarningFrame"
warningFrame.Size = UDim2.fromScale(1, 1)
warningFrame.BackgroundColor3 = Color3.new(0,0,0)
warningFrame.BackgroundTransparency = 0.85 -- Transparence augmentée
warningFrame.Visible = false
warningFrame.ZIndex = 100 
warningFrame.Parent = screenGui 

local warnBox = Instance.new("Frame")
warnBox.Size = UDim2.fromOffset(450, 220)
warnBox.Position = UDim2.fromScale(0.5, 0.5)
warnBox.AnchorPoint = Vector2.new(0.5, 0.5)
warnBox.BackgroundColor3 = COLORS.PanelDark
warnBox.Parent = warningFrame
applyProStyle(warnBox, 10, COLORS.AccentRed, 2)

local warnTitle = Instance.new("TextLabel")
warnTitle.Text = "WARNING!"
warnTitle.Font = Enum.Font.GothamBlack
warnTitle.TextColor3 = COLORS.AccentRed
warnTitle.TextSize = 36
warnTitle.Size = UDim2.new(1, 0, 0.3, 0)
warnTitle.BackgroundTransparency = 1
warnTitle.Parent = warnBox

local warnDesc = Instance.new("TextLabel")
warnDesc.Name = "Desc"
warnDesc.Text = "Desc"
warnDesc.Font = Enum.Font.GothamBold
warnDesc.TextColor3 = COLORS.TextWhite
warnDesc.TextSize = 18
warnDesc.TextWrapped = true
warnDesc.RichText = true
warnDesc.Size = UDim2.new(0.9, 0, 0.3, 0)
warnDesc.Position = UDim2.fromScale(0.5, 0.45)
warnDesc.AnchorPoint = Vector2.new(0.5, 0.5)
warnDesc.BackgroundTransparency = 1
warnDesc.Parent = warnBox

local warnYes = Instance.new("TextButton")
warnYes.Text = "SKIP ANYWAY"
warnYes.Size = UDim2.fromOffset(140, 45)
warnYes.Position = UDim2.new(0.25, 0, 0.85, 0)
warnYes.AnchorPoint = Vector2.new(0.5, 0.5)
warnYes.BackgroundColor3 = COLORS.ButtonNormal
warnYes.TextColor3 = COLORS.TextGray
warnYes.Font = Enum.Font.GothamBold
warnYes.TextSize = 14
warnYes.Parent = warnBox
applyProStyle(warnYes, 6, COLORS.TextGray, 1)

local warnNo = Instance.new("TextButton")
warnNo.Text = "KEEP"
warnNo.Size = UDim2.fromOffset(140, 45)
warnNo.Position = UDim2.new(0.75, 0, 0.85, 0)
warnNo.AnchorPoint = Vector2.new(0.5, 0.5)
warnNo.BackgroundColor3 = COLORS.AccentGreen
warnNo.TextColor3 = COLORS.TextWhite
warnNo.Font = Enum.Font.GothamBlack
warnNo.TextSize = 16
warnNo.Parent = warnBox
applyProStyle(warnNo, 6, COLORS.Glow, 1)


-- --- DROITE : INFOS & ODDS ---
local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(0.3, 0, 0.85, 0)
rightPanel.Position = UDim2.new(0.7, 0, 0, 0)
rightPanel.BackgroundColor3 = COLORS.PanelDark
rightPanel.BorderSizePixel = 0
rightPanel.Parent = familyFrame

local dbTitle = Instance.new("TextLabel")
dbTitle.Text = "ODDS DATABASE"
dbTitle.Font = Enum.Font.GothamBlack
dbTitle.TextSize = 24
dbTitle.TextColor3 = COLORS.TextGray
dbTitle.Size = UDim2.new(1, 0, 0, 60)
dbTitle.BackgroundTransparency = 1
dbTitle.Parent = rightPanel

local oddsList = Instance.new("ScrollingFrame")
oddsList.Size = UDim2.new(0.9, 0, 0.60, 0) 
oddsList.Position = UDim2.new(0.5, 0, 0, 70)
oddsList.AnchorPoint = Vector2.new(0.5, 0)
oddsList.BackgroundTransparency = 1
oddsList.BorderSizePixel = 0
oddsList.ScrollBarThickness = 4
oddsList.ScrollBarImageColor3 = COLORS.AccentBlue
oddsList.Parent = rightPanel

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 10)
listPadding.Parent = oddsList

local oddsLayout = Instance.new("UIListLayout")
oddsLayout.Padding = UDim.new(0, 8)
oddsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
oddsLayout.Parent = oddsList

for _, data in ipairs(familiesData) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -2, 0, 35)
	row.BackgroundColor3 = COLORS.ButtonNormal
	row.BorderSizePixel = 0
	row.Parent = oddsList
	local stroke = applyProStyle(row, 6, data.color, 1)

	local nameL = Instance.new("TextLabel")
	nameL.Text = data.name
	nameL.TextColor3 = data.color
	nameL.Font = Enum.Font.GothamBold
	nameL.TextSize = 14
	nameL.Size = UDim2.new(0.5, -10, 1, 0)
	nameL.Position = UDim2.new(0, 10, 0, 0)
	nameL.TextXAlignment = Enum.TextXAlignment.Left
	nameL.BackgroundTransparency = 1
	nameL.Parent = row

	local chanceL = Instance.new("TextLabel")
	chanceL.Text = data.displayChance 
	chanceL.TextColor3 = COLORS.TextWhite
	chanceL.Font = Enum.Font.RobotoMono
	chanceL.TextSize = 14
	chanceL.Size = UDim2.new(0.5, -10, 1, 0)
	chanceL.Position = UDim2.new(1, -10, 0, 0)
	chanceL.AnchorPoint = Vector2.new(1, 0)
	chanceL.TextXAlignment = Enum.TextXAlignment.Right
	chanceL.BackgroundTransparency = 1
	chanceL.Parent = row

	if data.name == "Visionary" then
		applyScrollingMythicEffect(stroke, {nameL, chanceL})
	elseif data.name == "Aura Farmer" then
		applySecretSpin(stroke)
		nameL.TextColor3 = Color3.new(1,1,1)
		chanceL.TextColor3 = Color3.new(1,1,1)
	end
end
oddsList.CanvasSize = UDim2.new(0, 0, 0, oddsLayout.AbsoluteContentSize.Y + 20)


-- Slots
local slotsContainer = Instance.new("Frame")
slotsContainer.AnchorPoint = Vector2.new(0.5, 1)
slotsContainer.Position = UDim2.new(0.5, 0, 0.98, 0)
slotsContainer.Size = UDim2.new(0.9, 0, 0.25, 0)
slotsContainer.BackgroundColor3 = COLORS.PanelLight
slotsContainer.BackgroundTransparency = 0.5
slotsContainer.Parent = rightPanel
applyProStyle(slotsContainer, 8, nil, 0)

local slotsLayout = Instance.new("UIListLayout")
slotsLayout.Padding = UDim.new(0, 8)
slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
slotsLayout.Parent = slotsContainer

local function createSlot(id, isLocked)
	local sFrame = Instance.new("Frame")
	sFrame.Size = UDim2.new(0.9, 0, 0, 40)
	sFrame.BackgroundColor3 = isLocked and COLORS.Locked or COLORS.ButtonNormal
	sFrame.Parent = slotsContainer
	applyProStyle(sFrame, 6, isLocked and Color3.new(0,0,0) or COLORS.AccentBlue, 1)

	local txt = Instance.new("TextLabel")
	txt.TextColor3 = isLocked and Color3.fromRGB(100,100,100) or COLORS.TextWhite
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 14 
	txt.Size = UDim2.new(1, -10, 1, 0)
	txt.Position = UDim2.new(0, 10, 0, 0)
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.BackgroundTransparency = 1
	txt.Parent = sFrame

	if isLocked then
		txt.Text = "LOCKED [GAMEPASS]"
		local lock = Instance.new("ImageLabel")
		lock.Image = "rbxassetid://3926305904"
		lock.Size = UDim2.fromOffset(20, 20)
		lock.Position = UDim2.new(1, -30, 0.5, 0)
		lock.AnchorPoint = Vector2.new(0, 0.5)
		lock.ImageColor3 = Color3.fromRGB(100,100,100)
		lock.BackgroundTransparency = 1
		lock.Parent = sFrame
	else
		txt.Text = "SLOT " .. id .. ": None"
		slot1Label = txt 
	end
end
createSlot(1, false)
createSlot(2, true)
createSlot(3, true)


-- --- CENTRE ---
local centerZone = Instance.new("Frame")
centerZone.Size = UDim2.new(0.7, 0, 1, 0)
centerZone.BackgroundTransparency = 1
centerZone.Parent = familyFrame

local rollTitle = Instance.new("TextLabel")
rollTitle.Text = "CURRENT FAMILY"
rollTitle.Font = Enum.Font.GothamBlack
rollTitle.TextSize = 30
rollTitle.TextColor3 = COLORS.TextWhite
rollTitle.Size = UDim2.new(1, 0, 0, 80)
rollTitle.Position = UDim2.new(0, 0, 0.05, 0)
rollTitle.BackgroundTransparency = 1
rollTitle.Parent = centerZone

-- Fenêtre Roll
local rollWindow = Instance.new("Frame")
rollWindow.Name = "RollWindow"
rollWindow.Size = UDim2.fromOffset(300, 120)
rollWindow.Position = UDim2.fromScale(0.5, 0.35)
rollWindow.AnchorPoint = Vector2.new(0.5, 0.5)
rollWindow.BackgroundColor3 = COLORS.PanelDark
rollWindow.ClipsDescendants = true 
rollWindow.Parent = centerZone
applyProStyle(rollWindow, 12, COLORS.AccentBlue, 2)

local rollStrip = Instance.new("Frame")
rollStrip.Name = "RollStrip"
rollStrip.Size = UDim2.new(1, 0, 0, 0) 
rollStrip.BackgroundTransparency = 1
rollStrip.Parent = rollWindow

local stripLayout = Instance.new("UIListLayout")
stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
stripLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
stripLayout.Parent = rollStrip

-- Stats
local statsPanel = Instance.new("Frame")
statsPanel.Name = "StatsPanel"
statsPanel.Size = UDim2.fromOffset(300, 100)
statsPanel.Position = UDim2.fromScale(0.5, 0.60)
statsPanel.AnchorPoint = Vector2.new(0.5, 0.5)
statsPanel.BackgroundColor3 = COLORS.PanelLight
statsPanel.Parent = centerZone
applyProStyle(statsPanel, 8, COLORS.TextGray, 1)

local statsTitle = Instance.new("TextLabel")
statsTitle.Text = "FAMILY STATS"
statsTitle.Size = UDim2.new(1, 0, 0, 25)
statsTitle.BackgroundTransparency = 1
statsTitle.TextColor3 = COLORS.TextGray
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 12
statsTitle.Parent = statsPanel

local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, 0, 0.7, 0)
statsContainer.Position = UDim2.new(0, 0, 0.3, 0)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = statsPanel

local statsLayout = Instance.new("UIListLayout")
statsLayout.FillDirection = Enum.FillDirection.Horizontal
statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statsLayout.Padding = UDim.new(0, 15)
statsLayout.Parent = statsContainer

local statNames = {"Luck", "Cash", "XP"}
for _, statName in ipairs(statNames) do
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(80, 50)
	frame.BackgroundTransparency = 1
	frame.Parent = statsContainer

	local val = Instance.new("TextLabel")
	val.Text = "-" 
	val.Size = UDim2.new(1, 0, 0.6, 0)
	val.TextColor3 = COLORS.AccentGold
	val.Font = Enum.Font.GothamBlack
	val.TextSize = 18
	val.BackgroundTransparency = 1
	val.Parent = frame
	statsLabels[statName] = val 

	local lbl = Instance.new("TextLabel")
	lbl.Text = statName:upper()
	lbl.Size = UDim2.new(1, 0, 0.4, 0)
	lbl.Position = UDim2.new(0, 0, 0.6, 0)
	lbl.TextColor3 = COLORS.TextGray
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.BackgroundTransparency = 1
	lbl.Parent = frame
end

local rerollBtn = Instance.new("TextButton")
rerollBtn.Text = "SPINS (" .. currentSpins .. ")"
rerollBtn.Size = UDim2.new(0, 250, 0, 60)
rerollBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
rerollBtn.AnchorPoint = Vector2.new(0.5, 0.5)
rerollBtn.BackgroundColor3 = COLORS.AccentBlue
rerollBtn.TextColor3 = COLORS.TextWhite
rerollBtn.Font = Enum.Font.GothamBlack
rerollBtn.TextSize = 28
rerollBtn.Parent = bottomBar
applyProStyle(rerollBtn, 6, COLORS.Glow, 2)

local returnBtn = Instance.new("TextButton")
returnBtn.Text = "RETURN"
returnBtn.Size = UDim2.new(0, 150, 0, 50)
returnBtn.Position = UDim2.new(0.95, 0, 0.5, 0)
returnBtn.AnchorPoint = Vector2.new(1, 0.5)
returnBtn.BackgroundColor3 = COLORS.ButtonNormal
returnBtn.TextColor3 = COLORS.TextGray
returnBtn.Font = Enum.Font.GothamBold
returnBtn.TextSize = 18
returnBtn.Parent = bottomBar
applyProStyle(returnBtn, 6, COLORS.TextGray, 1)

-- --- LOGIQUE ROLL ---
local ITEM_HEIGHT = 120
local FILLER_COUNT = 40
local isRolling = false

local function pickRandomFamily()
	local rand = math.random() * 100
	local cumulative = 0
	for _, fam in ipairs(familiesData) do
		cumulative = cumulative + fam.chanceVal
		if rand <= cumulative then return fam end
	end
	return familiesData[1]
end

local function createRollItem(family, order)
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Item_" .. order
	lbl.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
	lbl.BackgroundTransparency = 1
	lbl.Text = family.name
	lbl.TextColor3 = family.color
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 32
	lbl.LayoutOrder = order
	lbl.Parent = rollStrip

	if family.name == "Aura Farmer" then
		lbl.TextColor3 = Color3.new(1,1,1)
	end
	return lbl
end

-- Fonction d'exécution du Spin
local function executeSpin()
	isRolling = true
	currentSpins = currentSpins - 1
	if UpdateSpinsEvent then UpdateSpinsEvent:FireServer(1) end

	local result = pickRandomFamily()

	for _, lbl in pairs(statsLabels) do lbl.Text = "-" end
	for _, c in ipairs(rollStrip:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
	rollStrip.Position = UDim2.new(0, 0, 0, 0) 

	for i = 1, FILLER_COUNT do
		local randomFam = familiesData[math.random(1, #familiesData)]
		local item = createRollItem(randomFam, i)
		item.TextTransparency = 0.5 
		item.TextColor3 = Color3.fromRGB(100, 100, 100) 
	end

	local winnerItem = createRollItem(result, FILLER_COUNT + 1)
	winnerItem.TextTransparency = 0
	winnerItem.TextSize = 40 

	for i = 1, 3 do createRollItem(familiesData[math.random(1, #familiesData)], FILLER_COUNT + 1 + i) end
	stripLayout:ApplyLayout()

	local targetY = -(FILLER_COUNT) * ITEM_HEIGHT 
	local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(rollStrip, tweenInfo, {Position = UDim2.new(0, 0, 0, targetY)})

	rerollBtn.Text = "ROLLING..."
	rerollBtn.BackgroundColor3 = COLORS.ButtonNormal

	tween:Play()
	tween.Completed:Wait()

	if result.name == "Hunter" or result.name == "Visionary" or result.name == "Aura Farmer" then
		createConfettiExplosion(result.color, centerZone)
	end
	if result.name == "Aura Farmer" then
		triggerGlitchEffect(winnerItem, rollWindow)
	end

	rerollBtn.Text = "SPINS (" .. currentSpins .. ")"
	rerollBtn.BackgroundColor3 = COLORS.AccentBlue

	currentEquippedFamilyData = result 
	if slot1Label then
		slot1Label.Text = "SLOT 1: " .. string.upper(result.name)
		local oldColor = slot1Label.TextColor3
		slot1Label.TextColor3 = COLORS.AccentGold
		TweenService:Create(slot1Label, TweenInfo.new(0.5), {TextColor3 = oldColor}):Play()
	end

	isRolling = false
end

local function performRoll()
	if isRolling then return end

	if currentSpins <= 0 then
		rerollBtn.Text = "NO SPINS!"
		rerollBtn.BackgroundColor3 = COLORS.AccentRed
		task.wait(1)
		rerollBtn.Text = "SPINS (" .. currentSpins .. ")"
		rerollBtn.BackgroundColor3 = COLORS.AccentBlue
		return
	end

	if currentEquippedFamilyData then
		local famName = currentEquippedFamilyData.name
		local rarity = currentEquippedFamilyData.rarity
		if SAFETY_RARITIES[rarity] and not skippedFamilies[famName] then
			warnDesc.Text = "You have <font color='#FFCC00'>" .. string.upper(famName) .. "</font>.<br/>Are you sure you want to reroll?"
			warningFrame.Visible = true
			return 
		end
	end

	executeSpin()
end

warnYes.MouseButton1Click:Connect(function()
	warningFrame.Visible = false
	executeSpin()
end)
warnNo.MouseButton1Click:Connect(function()
	warningFrame.Visible = false
end)

rerollBtn.MouseButton1Click:Connect(performRoll)

-- ====================================================================
-- MENU PRINCIPAL
-- ====================================================================

local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.fromScale(0.5, 0.5)
settingsFrame.Position = UDim2.fromScale(0.5, 0.5)
settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
settingsFrame.BackgroundColor3 = COLORS.PanelDark
settingsFrame.Visible = false
settingsFrame.Parent = screenGui
applyProStyle(settingsFrame, 8, COLORS.Glow, 1)

local setClose = Instance.new("TextButton")
setClose.Text = "CLOSE"
setClose.Size = UDim2.fromOffset(100, 40)
setClose.Position = UDim2.fromScale(0.5, 0.9)
setClose.AnchorPoint = Vector2.new(0.5, 0)
setClose.BackgroundColor3 = COLORS.AccentRed
setClose.TextColor3 = COLORS.TextWhite
setClose.Parent = settingsFrame
applyProStyle(setClose, 6)

local setLbl = Instance.new("TextLabel")
setLbl.Text = "SETTINGS"
setLbl.TextColor3 = COLORS.TextGray
setLbl.Size = UDim2.fromScale(1, 0.2)
setLbl.BackgroundTransparency = 1
setLbl.Font = Enum.Font.GothamBlack
setLbl.TextSize = 24
setLbl.Parent = settingsFrame

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local gameTitle = Instance.new("TextLabel")
gameTitle.Text = "RNG ASCENSION"
gameTitle.Font = Enum.Font.GothamBlack
gameTitle.TextSize = 60
gameTitle.TextColor3 = COLORS.TextWhite
gameTitle.Size = UDim2.new(1, 0, 0, 100)
gameTitle.Position = UDim2.new(0, 0, 0.15, 0)
gameTitle.BackgroundTransparency = 1
gameTitle.Parent = mainFrame
local shadow = gameTitle:Clone()
shadow.Position = UDim2.new(0, 4, 0.15, 4)
shadow.TextColor3 = COLORS.AccentBlue
shadow.ZIndex = 0
shadow.TextTransparency = 0.8
shadow.Parent = mainFrame

local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.fromOffset(300, 300)
buttonContainer.Position = UDim2.new(0.5, 0, 0.80, 0) 
buttonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10) 
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonContainer

local function createMenuButton(name, text, order, isPrimary)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.LayoutOrder = order
	btn.Size = UDim2.new(1, 0, 0, 60)

	local normalColor = isPrimary and COLORS.AccentBlue or COLORS.ButtonNormal
	local hoverColor = isPrimary and COLORS.AccentBlueHover or COLORS.ButtonHover

	btn.BackgroundColor3 = normalColor
	btn.Text = text
	btn.TextColor3 = COLORS.TextWhite
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 24
	btn.Parent = buttonContainer
	applyProStyle(btn, 6, isPrimary and COLORS.Glow or COLORS.TextGray, 1)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
	end)

	return btn
end

local playBtn = createMenuButton("Play", "PLAY", 1, true)
local famBtn = createMenuButton("Family", "FAMILY DATABASE", 2, false)
local setBtn = createMenuButton("Settings", "SYSTEM SETTINGS", 3, false)

local function toggleMain(visible) mainFrame.Visible = visible end

famBtn.MouseButton1Click:Connect(function()
	toggleMain(false)
	familyFrame.Visible = true
	if #rollStrip:GetChildren() <= 1 then
		local startItem = createRollItem(familiesData[1], 1)
		startItem.Parent = rollStrip
	end
end)

setBtn.MouseButton1Click:Connect(function() toggleMain(false); settingsFrame.Visible = true end)
returnBtn.MouseButton1Click:Connect(function() familyFrame.Visible = false; toggleMain(true) end)
setClose.MouseButton1Click:Connect(function() settingsFrame.Visible = false; toggleMain(true) end)

playBtn.MouseButton1Click:Connect(function() 
	screenGui.Enabled = false
	toggleCoreUI(true) 
	camera.CameraType = Enum.CameraType.Custom 
end)

local CAMERA_OFFSET = Vector3.new(0, 60, 60)
local LOOK_AT_TARGET = Vector3.new(0, 0, 0)
local startTick = tick()

RunService.RenderStepped:Connect(function()
	if screenGui.Enabled and mainFrame.Visible then
		local t = tick() - startTick
		local bob = Vector3.new(math.sin(t*0.5)*2, math.cos(t*0.3)*2, 0)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(CAMERA_OFFSET + bob, LOOK_AT_TARGET)
	end
end)

task.spawn(function()
	toggleCoreUI(false)

	if not ReplicatedFirst:FindFirstChild("LoadingComplete") then
		local success = pcall(function()
			ReplicatedFirst:WaitForChild("LoadingComplete", 60)
		end)
	end
	screenGui.Enabled = true
end)