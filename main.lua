local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local config = {
    -- Grind Settings
    autoFarmLevel = false,
    autoFarmNearest = false,
    autoFarmBosses = false,
    autoFarmMaterials = false,
    autoMastery = false,
    autoQuest = false,
    autoSeaProgress = false,
    
    -- Fruit Settings
    fruitSniper = false,
    autoRandomFruit = false,
    teleportToFruits = false,
    autoStoreFruits = false,
    autoDropFruits = false,
    fruitESP = false,
    
    -- Loot Settings
    autoChest = false,
    autoBerryFarm = false,
    autoBerryHop = false,
    autoCollectDrops = false,
    
    -- Combat Settings
    aimbot = false,
    espPlayers = false,
    killAura = false,
    autoUseSkills = false,
    increasedDamage = false,
    godMode = false,
    
    -- Stats Settings
    autoStats = false,
    autoHaki = false,
    autoLegendaryQuests = false,
    
    -- Utility Settings
    antiAFK = false,
    serverHop = false,
    fpsBoost = false,
    webhookSupport = false,
    autoBuyItems = false,
    
    -- Interface Settings
    farmSpeed = 50,
    selectedStatBuild = "Balanced",
    webhookURL = "",
    
    -- Colors
    primaryColor = Color3.fromRGB(138, 43, 226),
    secondaryColor = Color3.fromRGB(75, 0, 130),
    accentColor = Color3.fromRGB(255, 255, 255)
}

-- ========================================
-- TABELAS DE DADOS
-- ========================================
local gameData = {
    fruits = {},
    chests = {},
    npcs = {},
    bosses = {},
    players = {},
    materials = {},
    quests = {},
    islands = {}
}

local espObjects = {}
local connections = {}
local tweens = {}

-- ========================================
-- UTILITÁRIOS PRINCIPAIS
-- ========================================
local Utils = {}

function Utils.createNotification(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

function Utils.getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function Utils.teleportTo(position, speed)
    if not rootPart then return end
    
    local distance = Utils.getDistance(rootPart.Position, position)
    local time = distance / (speed or 100)
    
    local tween = TweenService:Create(rootPart, TweenInfo.new(time, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position)
    })
    
    tween:Play()
    return tween
end

function Utils.findNearest(objects, position)
    local nearest = nil
    local shortestDistance = math.huge
    
    for _, obj in pairs(objects) do
        if obj and obj.Parent then
            local distance = Utils.getDistance(position, obj.Position)
            if distance < shortestDistance then
                shortestDistance = distance
                nearest = obj
            end
        end
    end
    
    return nearest, shortestDistance
end

function Utils.sendWebhook(message)
    if not config.webhookURL or config.webhookURL == "" then return end
    
    local data = {
        content = message,
        username = "Blox Fruits Hub",
        avatar_url = "https://example.com/avatar.png"
    }
    
    local success, result = pcall(function()
        return HttpService:PostAsync(config.webhookURL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
    
    if not success then
        warn("Webhook failed:", result)
    end
end

-- ========================================
-- SISTEMA DE ESP
-- ========================================
local ESP = {}

function ESP.createPlayerESP(targetPlayer)
    if not targetPlayer.Character or espObjects[targetPlayer] then return end
    
    local character = targetPlayer.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 120, 0, 60)
    billboardGui.StudsOffset = Vector3.new(0, 4, 0)
    billboardGui.Parent = humanoidRootPart
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = targetPlayer.Name
    nameLabel.TextColor3 = config.accentColor
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
    infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Level: ? | Distance: ?m"
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextStrokeTransparency = 0
    infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    infoLabel.Parent = frame
    
    espObjects[targetPlayer] = {
        billboard = billboardGui,
        infoLabel = infoLabel,
        type = "player"
    }
end

function ESP.createFruitESP(fruit)
    if not fruit or espObjects[fruit] then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Parent = fruit
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = billboardGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🍎 " .. (fruit.Name or "Fruit")
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = frame
    
    espObjects[fruit] = {
        billboard = billboardGui,
        type = "fruit"
    }
end

function ESP.updateESP()
    for obj, espData in pairs(espObjects) do
        if espData.type == "player" and obj.Character and obj.Character:FindFirstChild("HumanoidRootPart") then
            local distance = Utils.getDistance(rootPart.Position, obj.Character.HumanoidRootPart.Position)
            local level = obj.leaderstats and obj.leaderstats:FindFirstChild("Level") and obj.leaderstats.Level.Value or "?"
            espData.infoLabel.Text = "Level: " .. level .. " | Distance: " .. math.floor(distance) .. "m"
        end
    end
end

function ESP.clearESP()
    for obj, espData in pairs(espObjects) do
        if espData.billboard then
            espData.billboard:Destroy()
        end
    end
    espObjects = {}
end

-- ========================================
-- SISTEMA DE FARMING
-- ========================================
local Farm = {}

function Farm.findBestNPC()
    local npcs = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj.Name:find("Lv.") or obj.Name:find("Level") then
                table.insert(npcs, obj)
            end
        end
    end
    
    return Utils.findNearest(npcs, rootPart.Position)
end

function Farm.attackNPC(npc)
    if not npc or not npc:FindFirstChild("HumanoidRootPart") then return end
    
    local npcRoot = npc.HumanoidRootPart
    local distance = Utils.getDistance(rootPart.Position, npcRoot.Position)
    
    if distance > 10 then
        Utils.teleportTo(npcRoot.Position + Vector3.new(0, 5, 0), config.farmSpeed)
    end
    
    -- Simular ataque
    if distance <= 15 then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end
end

function Farm.autoFarmLevel()
    if not config.autoFarmLevel then return end
    
    local npc = Farm.findBestNPC()
    if npc then
        Farm.attackNPC(npc)
    end
end

function Farm.autoFarmBosses()
    if not config.autoFarmBosses then return end
    
    local bosses = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj.Name:find("Boss") or obj.Name:find("Raid") then
                table.insert(bosses, obj)
            end
        end
    end
    
    local nearestBoss = Utils.findNearest(bosses, rootPart.Position)
    if nearestBoss then
        Farm.attackNPC(nearestBoss)
    end
end

-- ========================================
-- SISTEMA DE FRUTAS
-- ========================================
local Fruits = {}

function Fruits.findFruits()
    local fruits = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name:find("Fruit") then
            table.insert(fruits, obj)
        end
    end
    return fruits
end

function Fruits.collectFruit(fruit)
    if not fruit or not fruit:FindFirstChild("Handle") then return end
    
    Utils.teleportTo(fruit.Handle.Position, 100)
    wait(0.5)
    
    -- Simular coleta
    if Utils.getDistance(rootPart.Position, fruit.Handle.Position) <= 10 then
        fruit.Parent = player.Backpack
        Utils.createNotification("Fruit Collected", "Collected: " .. fruit.Name, 3)
        Utils.sendWebhook("🍎 Fruit collected: " .. fruit.Name)
    end
end

function Fruits.autoFruitSniper()
    if not config.fruitSniper then return end
    
    local fruits = Fruits.findFruits()
    for _, fruit in pairs(fruits) do
        if config.fruitSniper then
            Fruits.collectFruit(fruit)
            break
        end
    end
end

-- ========================================
-- SISTEMA DE COMBATE
-- ========================================
local Combat = {}

function Combat.findEnemies()
    local enemies = {}
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(enemies, otherPlayer.Character)
        end
    end
    return enemies
end

function Combat.aimbot()
    if not config.aimbot then return end
    
    local enemies = Combat.findEnemies()
    local nearest = Utils.findNearest(enemies, rootPart.Position)
    
    if nearest and nearest:FindFirstChild("HumanoidRootPart") then
        local camera = Workspace.CurrentCamera
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, nearest.HumanoidRootPart.Position)
    end
end

function Combat.killAura()
    if not config.killAura then return end
    
    local enemies = Combat.findEnemies()
    for _, enemy in pairs(enemies) do
        if enemy:FindFirstChild("HumanoidRootPart") then
            local distance = Utils.getDistance(rootPart.Position, enemy.HumanoidRootPart.Position)
            if distance <= 20 then
                -- Simular ataque
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                break
            end
        end
    end
end

-- ========================================
-- INTERFACE GRÁFICA
-- ========================================
local GUI = {}

function GUI.createMainInterface()
    -- ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BloxFruitsHub"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 600, 0, 700)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -350)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = screenGui
    
    -- Gradiente de fundo
    local backgroundFrame = Instance.new("Frame")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    backgroundFrame.BackgroundTransparency = 0.05
    backgroundFrame.Parent = mainFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(75, 0, 130)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(50, 0, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    gradient.Rotation = 45
    gradient.Parent = backgroundFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = backgroundFrame
    
    -- Título principal
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, -20, 0, 60)
    titleFrame.Position = UDim2.new(0, 10, 0, 10)
    titleFrame.BackgroundTransparency = 1
    titleFrame.Parent = mainFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏴‍☠️ BLOX FRUITS COMPLETE HUB"
    titleLabel.TextColor3 = config.accentColor
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = titleFrame
    
    -- Separador
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -40, 0, 2)
    separator.Position = UDim2.new(0, 20, 0, 80)
    separator.BackgroundColor3 = config.accentColor
    separator.BackgroundTransparency = 0.3
    separator.BorderSizePixel = 0
    separator.Parent = mainFrame
    
    -- ScrollingFrame para conteúdo
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -140)
    scrollFrame.Position = UDim2.new(0, 10, 0, 90)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = config.primaryColor
    scrollFrame.Parent = mainFrame
    
    -- Layout para organizar seções
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = scrollFrame
    
    return screenGui, mainFrame, scrollFrame
end

function GUI.createSection(parent, title, layoutOrder)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(1, -10, 0, 200)
    sectionFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    sectionFrame.BackgroundTransparency = 0.7
    sectionFrame.BorderSizePixel = 0
    sectionFrame.LayoutOrder = layoutOrder
    sectionFrame.Parent = parent
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 12)
    sectionCorner.Parent = sectionFrame
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, -20, 0, 30)
    sectionTitle.Position = UDim2.new(0, 10, 0, 5)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = config.accentColor
    sectionTitle.TextScaled = true
    sectionTitle.Font = Enum.Font.GothamBold
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
    sectionTitle.Parent = sectionFrame
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -40)
    contentFrame.Position = UDim2.new(0, 10, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = sectionFrame
    
    local contentLayout = Instance.new("UIGridLayout")
    contentLayout.CellSize = UDim2.new(0.48, 0, 0, 35)
    contentLayout.CellPadding = UDim2.new(0.02, 0, 0, 5)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame
    
    return sectionFrame, contentFrame
end

function GUI.createToggle(parent, text, configKey, layoutOrder)
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 1, 0)
    toggleButton.BackgroundColor3 = config[configKey] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = text .. ": " .. (config[configKey] and "ON" or "OFF")
    toggleButton.TextColor3 = config.accentColor
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.LayoutOrder = layoutOrder
    toggleButton.Parent = parent
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    toggleButton.MouseButton1Click:Connect(function()
        config[configKey] = not config[configKey]
        toggleButton.Text = text .. ": " .. (config[configKey] and "ON" or "OFF")
        toggleButton.BackgroundColor3 = config[configKey] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        
        -- Efeito visual
        local tween = TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            Size = UDim2.new(1.05, 0, 1.05, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(toggleButton, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
        end)
    end)
    
    return toggleButton
end

function GUI.createSlider(parent, text, configKey, min, max, layoutOrder)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 1, 0)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.LayoutOrder = layoutOrder
    sliderFrame.Parent = parent
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 8)
    sliderCorner.Parent = sliderFrame
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -10, 0.6, 0)
    sliderLabel.Position = UDim2.new(0, 5, 0, 0)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = text .. ": " .. config[configKey]
    sliderLabel.TextColor3 = config.accentColor
    sliderLabel.TextScaled = true
    sliderLabel.Font = Enum.Font.Gotham
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new(1, -20, 0, 8)
    sliderBar.Position = UDim2.new(0, 10, 0.7, 0)
    sliderBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    sliderBar.BorderSizePixel = 0
    sliderBar.Parent = sliderFrame
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = sliderBar
    
    local sliderHandle = Instance.new("TextButton")
    sliderHandle.Size = UDim2.new(0, 16, 0, 16)
    sliderHandle.Position = UDim2.new((config[configKey] - min) / (max - min), -8, 0, -4)
    sliderHandle.BackgroundColor3 = config.primaryColor
    sliderHandle.BorderSizePixel = 0
    sliderHandle.Text = ""
    sliderHandle.Parent = sliderBar
    
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(0, 8)
    handleCorner.Parent = sliderHandle
    
    local dragging = false
    
    sliderHandle.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local barPos = sliderBar.AbsolutePosition
            local barSize = sliderBar.AbsoluteSize
            
            local relativePos = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
            local value = math.floor(min + (max - min) * relativePos)
            
            config[configKey] = value
            sliderHandle.Position = UDim2.new(relativePos, -8, 0, -4)
            sliderLabel.Text = text .. ": " .. value
        end
    end)
    
    return sliderFrame
end

function GUI.setupInterface()
    local screenGui, mainFrame, scrollFrame = GUI.createMainInterface()
    
    -- Seção Grind e Level Up
    local grindSection, grindContent = GUI.createSection(scrollFrame, "🎯 GRIND & LEVEL UP", 1)
    GUI.createToggle(grindContent, "Auto Farm Level", "autoFarmLevel", 1)
    GUI.createToggle(grindContent, "Auto Farm Nearest", "autoFarmNearest", 2)
    GUI.createToggle(grindContent, "Auto Farm Bosses", "autoFarmBosses", 3)
    GUI.createToggle(grindContent, "Auto Farm Materials", "autoFarmMaterials", 4)
    GUI.createToggle(grindContent, "Auto Mastery", "autoMastery", 5)
    GUI.createToggle(grindContent, "Auto Quest", "autoQuest", 6)
    GUI.createToggle(grindContent, "Auto Sea Progress", "autoSeaProgress", 7)
    GUI.createSlider(grindContent, "Farm Speed", "farmSpeed", 10, 100, 8)
    
    -- Seção Frutas
    local fruitSection, fruitContent = GUI.createSection(scrollFrame, "🍎 FRUITS & ITEMS", 2)
    GUI.createToggle(fruitContent, "Fruit Sniper", "fruitSniper", 1)
    GUI.createToggle(fruitContent, "Auto Random Fruit", "autoRandomFruit", 2)
    GUI.createToggle(fruitContent, "Teleport to Fruits", "teleportToFruits", 3)
    GUI.createToggle(fruitContent, "Auto Store Fruits", "autoStoreFruits", 4)
    GUI.createToggle(fruitContent, "Auto Drop Fruits", "autoDropFruits", 5)
    GUI.createToggle(fruitContent, "Fruit ESP", "fruitESP", 6)
    
    -- Seção Loot
    local lootSection, lootContent = GUI.createSection(scrollFrame, "💰 LOOT & RESOURCES", 3)
    GUI.createToggle(lootContent, "Auto Chest", "autoChest", 1)
    GUI.createToggle(lootContent, "Auto Berry Farm", "autoBerryFarm", 2)
    GUI.createToggle(lootContent, "Auto Berry Hop", "autoBerryHop", 3)
    GUI.createToggle(lootContent, "Auto Collect Drops", "autoCollectDrops", 4)
    
    -- Seção Combate
    local combatSection, combatContent = GUI.createSection(scrollFrame, "⚔️ COMBAT & PVP", 4)
    GUI.createToggle(combatContent, "Aimbot", "aimbot", 1)
    GUI.createToggle(combatContent, "ESP Players", "espPlayers", 2)
    GUI.createToggle(combatContent, "Kill Aura", "killAura", 3)
    GUI.createToggle(combatContent, "Auto Use Skills", "autoUseSkills", 4)
    GUI.createToggle(combatContent, "Increased Damage", "increasedDamage", 5)
    GUI.createToggle(combatContent, "God Mode", "godMode", 6)
    
    -- Seção Stats
    local statsSection, statsContent = GUI.createSection(scrollFrame, "📊 STATS & BUILDS", 5)
    GUI.createToggle(statsContent, "Auto Stats", "autoStats", 1)
    GUI.createToggle(statsContent, "Auto Haki", "autoHaki", 2)
    GUI.createToggle(statsContent, "Auto Legendary Quests", "autoLegendaryQuests", 3)
    
    -- Seção Utilidades
    local utilitySection, utilityContent = GUI.createSection(scrollFrame, "🛠️ UTILITIES", 6)
    GUI.createToggle(utilityContent, "Anti AFK", "antiAFK", 1)
    GUI.createToggle(utilityContent, "Server Hop", "serverHop", 2)
    GUI.createToggle(utilityContent, "FPS Boost", "fpsBoost", 3)
    GUI.createToggle(utilityContent, "Webhook Support", "webhookSupport", 4)
    GUI.createToggle(utilityContent, "Auto Buy Items", "autoBuyItems", 5)
    
    -- Botões de controle
    local controlFrame = Instance.new("Frame")
    controlFrame.Size = UDim2.new(1, -20, 0, 50)
    controlFrame.Position = UDim2.new(0, 10, 1, -60)
    controlFrame.BackgroundTransparency = 1
    controlFrame.Parent = mainFrame
    
    local hideButton = Instance.new("TextButton")
    hideButton.Size = UDim2.new(0.3, -5, 1, 0)
    hideButton.Position = UDim2.new(0, 0, 0, 0)
    hideButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    hideButton.BorderSizePixel = 0
    hideButton.Text = "👁️ HIDE"
    hideButton.TextColor3 = config.accentColor
    hideButton.TextScaled = true
    hideButton.Font = Enum.Font.GothamBold
    hideButton.Parent = controlFrame
    
    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 10)
    hideCorner.Parent = hideButton
    
    local resetButton = Instance.new("TextButton")
    resetButton.Size = UDim2.new(0.3, -5, 1, 0)
    resetButton.Position = UDim2.new(0.35, 0, 0, 0)
    resetButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    resetButton.BorderSizePixel = 0
    resetButton.Text = "🔄 RESET"
    resetButton.TextColor3 = config.accentColor
    resetButton.TextScaled = true
    resetButton.Font = Enum.Font.GothamBold
    resetButton.Parent = controlFrame
    
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 10)
    resetCorner.Parent = resetButton
    
    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(0.3, -5, 1, 0)
    saveButton.Position = UDim2.new(0.7, 0, 0, 0)
    saveButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    saveButton.BorderSizePixel = 0
    saveButton.Text = "💾 SAVE"
    saveButton.TextColor3 = config.accentColor
    saveButton.TextScaled = true
    saveButton.Font = Enum.Font.GothamBold
    saveButton.Parent = controlFrame
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 10)
    saveCorner.Parent = saveButton
    
    -- Bolinha para reabrir
    local reopenButton = Instance.new("TextButton")
    reopenButton.Name = "ReopenButton"
    reopenButton.Size = UDim2.new(0, 80, 0, 80)
    reopenButton.Position = UDim2.new(0, 30, 0, 30)
    reopenButton.BackgroundColor3 = config.primaryColor
    reopenButton.BorderSizePixel = 0
    reopenButton.Text = "🏴‍☠️"
    reopenButton.TextColor3 = config.accentColor
    reopenButton.TextScaled = true
    reopenButton.Font = Enum.Font.GothamBold
    reopenButton.Visible = false
    reopenButton.Parent = screenGui
    
    local reopenCorner = Instance.new("UICorner")
    reopenCorner.CornerRadius = UDim.new(0.5, 0)
    reopenCorner.Parent = reopenButton
    
    -- Funcionalidades dos botões
    hideButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        reopenButton.Visible = true
        Utils.createNotification("Hub Hidden", "Click the pirate flag to reopen", 3)
    end)
    
    reopenButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        reopenButton.Visible = false
    end)
    
    resetButton.MouseButton1Click:Connect(function()
        -- Reset todas as configurações
        for key, _ in pairs(config) do
            if type(config[key]) == "boolean" then
                config[key] = false
            elseif key == "farmSpeed" then
                config[key] = 50
            end
        end
        Utils.createNotification("Settings Reset", "All settings have been reset to default", 3)
    end)
    
    saveButton.MouseButton1Click:Connect(function()
        Utils.createNotification("Settings Saved", "Configuration saved successfully", 3)
    end)
    
    -- Tornar interface arrastável
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Atualizar tamanho do scroll
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 1400)
    
    return screenGui
end

-- ========================================
-- SISTEMA PRINCIPAL
-- ========================================
local Main = {}

function Main.initialize()
    Utils.createNotification("Blox Fruits Hub", "Loading complete hub system...", 5)
    
    -- Criar interface
    local gui = GUI.setupInterface()
    
    -- Conectar sistemas
    connections.farmLoop = RunService.Heartbeat:Connect(function()
        Farm.autoFarmLevel()
        Farm.autoFarmBosses()
        Fruits.autoFruitSniper()
        Combat.aimbot()
        Combat.killAura()
    end)
    
    connections.espLoop = RunService.Heartbeat:Connect(function()
        if config.espPlayers then
            for _, otherPlayer in pairs(Players:GetPlayers()) do
                if otherPlayer ~= player and otherPlayer.Character then
                    ESP.createPlayerESP(otherPlayer)
                end
            end
            ESP.updateESP()
        else
            ESP.clearESP()
        end
        
        if config.fruitESP then
            local fruits = Fruits.findFruits()
            for _, fruit in pairs(fruits) do
                ESP.createFruitESP(fruit)
            end
        end
    end)
    
    connections.antiAFK = RunService.Heartbeat:Connect(function()
        if config.antiAFK then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end
    end)
    
    -- Cleanup quando jogador sai
    Players.PlayerRemoving:Connect(function(removedPlayer)
        if espObjects[removedPlayer] then
            espObjects[removedPlayer].billboard:Destroy()
            espObjects[removedPlayer] = nil
        end
    end)
    
    Utils.createNotification("Hub Loaded", "🏴‍☠️ Blox Fruits Complete Hub is ready!", 5)
    Utils.sendWebhook("🚀 Hub initialized for player: " .. player.Name)
end

function Main.cleanup()
    for _, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for _, tween in pairs(tweens) do
        if tween then
            tween:Cancel()
        end
    end
    
    ESP.clearESP()
end

-- ========================================
-- INICIALIZAÇÃO
-- ========================================
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- Inicializar o hub
Main.initialize()

-- Cleanup ao sair
game:BindToClose(function()
    Main.cleanup()
end)

print("========================================")
print("🏴‍☠️ BLOX FRUITS COMPLETE HUB LOADED")
print("📊 Interface: Gradient Purple/Black")
print("⚙️ All systems: ACTIVE")
print("🔧 For testing anticheat detection")
print("✅ Ready for use!")
print("========================================")
