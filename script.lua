--[[
    XANDOWN HUB - ILHA PRÉ-HISTÓRICA V4.0
    Sistema Avançado de Caça em Grupo com Múltiplos Barcos
    Suporte a Game Passes e Barcos Especiais
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================
-- LISTA DE BARCOS DISPONÍVEIS
-- ============================================

local Boats = {
    -- Barcos Comuns (Coin)
    {Name = "Milagre", DisplayName = "🚤 Milagre", Price = 50000, Currency = "Money", GamePassId = nil, Speed = 80, ModelName = "Milagre"},
    {Name = "Sentinel", DisplayName = "⚓ Sentinel", Price = 100000, Currency = "Money", GamePassId = nil, Speed = 100, ModelName = "Sentinel"},
    {Name = "Terror", DisplayName = "💀 Terror", Price = 250000, Currency = "Money", GamePassId = nil, Speed = 120, ModelName = "Terror"},
    
    -- Barcos de Game Pass (Robux)
    {Name = "Dragon Boat", DisplayName = "🐉 Dragon Boat", Price = 399, Currency = "Robux", GamePassId = 12345678, Speed = 200, ModelName = "DragonBoat", GamePassOnly = true},
    {Name = "Phantom", DisplayName = "👻 Phantom Ship", Price = 499, Currency = "Robux", GamePassId = 12345679, Speed = 220, ModelName = "PhantomShip", GamePassOnly = true},
    {Name = "Leviathan", DisplayName = "🐋 Leviathan", Price = 699, Currency = "Robux", GamePassId = 12345680, Speed = 250, ModelName = "Leviathan", GamePassOnly = true},
    {Name = "Golden Kraken", DisplayName = "🦑 Golden Kraken", Price = 899, Currency = "Robux", GamePassId = 12345681, Speed = 280, ModelName = "GoldenKraken", GamePassOnly = true},
    {Name = "Void Seeker", DisplayName = "🌌 Void Seeker", Price = 1299, Currency = "Robux", GamePassId = 12345682, Speed = 300, ModelName = "VoidSeeker", GamePassOnly = true},
    
    -- Barcos Especiais (Evento/Rank)
    {Name = "Sea King", DisplayName = "👑 Sea King", Price = 0, Currency = "None", GamePassId = nil, Speed = 180, ModelName = "SeaKing", Special = true, UnlockCondition = "Rank 1000+"},
    {Name = "Cursed Ferry", DisplayName = "⚰️ Cursed Ferry", Price = 0, Currency = "None", GamePassId = nil, Speed = 160, ModelName = "CursedFerry", Special = true, UnlockCondition = "Evento Especial"},
}

-- Verificar barcos desbloqueados pelo jogador
local function checkOwnedBoats()
    local ownedBoats = {}
    
    for _, boat in pairs(Boats) do
        local isOwned = false
        
        if boat.GamePassOnly and boat.GamePassId then
            -- Verificar se possui a Game Pass
            local success, hasPass = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(LP.UserId, boat.GamePassId)
            end)
            if success and hasPass then
                isOwned = true
            end
        elseif boat.Special then
            -- Para barcos especiais, verificar condições (exemplo)
            local rank = LP:GetAttribute("Rank") or 0
            if boat.Name == "Sea King" and rank >= 1000 then
                isOwned = true
            elseif boat.Name == "Cursed Ferry" then
                -- Verificar se completou evento
                isOwned = LP:GetAttribute("CursedEventComplete") or false
            end
        else
            -- Barcos comuns estão sempre disponíveis para compra
            isOwned = true
        end
        
        if isOwned then
            table.insert(ownedBoats, boat)
        end
    end
    
    return ownedBoats
end

-- ============================================
-- CONFIGURAÇÕES AJUSTÁVEIS
-- ============================================

local Config = {
    SelectedBoat = "Milagre",   -- Barco selecionado
    BoatSpeed = 150,             -- Velocidade do barco (será sobrescrita pelo barco escolhido)
    TweenSpeed = 0.3,
    TeleportRadius = 8,
    AutoGroup = true,
    AutoBoat = true,
    AutoHunt = true,
    IslandDetectionRange = 5000,
    NotifyGroup = true,
    AvailableBoats = {},
}

-- ============================================
-- GUI MODERNA
-- ============================================

local gui = Instance.new("ScreenGui")
gui.Name = "XandownHub_Prehistoric"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 550)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -275)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 100, 50)
stroke.Thickness = 1.5
stroke.Parent = mainFrame

-- Barra Superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🦕 XANDOWN HUB | ILHA PRÉ-HISTÓRICA V4"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = topBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- Abas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 40)
tabBar.Position = UDim2.new(0, 0, 0, 45)
tabBar.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
tabBar.BackgroundTransparency = 0.3
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -20, 1, -105)
contentFrame.Position = UDim2.new(0, 10, 0, 90)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, -20, 0, 80)
statusFrame.Position = UDim2.new(0, 10, 1, -90)
statusFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
statusFrame.BackgroundTransparency = 0.5
statusFrame.BorderSizePixel = 0
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -10, 0, 20)
statusText.Position = UDim2.new(0, 5, 0, 5)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ Pronto para explorar"
statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
statusText.TextSize = 11
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusFrame

local boatStatus = Instance.new("TextLabel")
boatStatus.Size = UDim2.new(1, -10, 0, 20)
boatStatus.Position = UDim2.new(0, 5, 0, 28)
boatStatus.BackgroundTransparency = 1
boatStatus.Text = "🚤 Barco: Nenhum selecionado"
boatStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
boatStatus.TextSize = 11
boatStatus.Font = Enum.Font.Gotham
boatStatus.TextXAlignment = Enum.TextXAlignment.Left
boatStatus.Parent = statusFrame

local groupStatus = Instance.new("TextLabel")
groupStatus.Size = UDim2.new(1, -10, 0, 20)
groupStatus.Position = UDim2.new(0, 5, 0, 51)
groupStatus.BackgroundTransparency = 1
groupStatus.Text = "👥 Grupo: Formando..."
groupStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
groupStatus.TextSize = 11
groupStatus.Font = Enum.Font.Gotham
groupStatus.TextXAlignment = Enum.TextXAlignment.Left
groupStatus.Parent = statusFrame

local boatInfoStatus = Instance.new("TextLabel")
boatInfoStatus.Size = UDim2.new(1, -10, 0, 20)
boatInfoStatus.Position = UDim2.new(0, 5, 0, 74)
boatInfoStatus.BackgroundTransparency = 1
boatInfoStatus.Text = "📊 Info: ---"
boatInfoStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
boatInfoStatus.TextSize = 10
boatInfoStatus.Font = Enum.Font.Gotham
boatInfoStatus.TextXAlignment = Enum.TextXAlignment.Left
boatInfoStatus.Parent = statusFrame

-- Criar Abas
local tabs = {"🌊 EXPEDIÇÃO", "🛥️ BARCOS", "⚙ CONFIG", "👥 GRUPO"}
local tabButtons = {}

for i, tabName in pairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -2, 1, -8)
    btn.Position = UDim2.new((i-1)*0.25, 4, 0, 4)
    btn.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    tabButtons[tabName] = btn
end

-- ============================================
-- SISTEMA DE BARCO MELHORADO COM MÚLTIPLAS OPÇÕES
-- ============================================

local BoatSystem = {
    CurrentBoat = nil,
    IsSailing = false,
    SelectedBoatData = nil,
    
    UpdateAvailableBoats = function()
        Config.AvailableBoats = checkOwnedBoats()
        return Config.AvailableBoats
    end,
    
    SelectBoat = function(boatName)
        for _, boat in pairs(Config.AvailableBoats) do
            if boat.Name == boatName then
                Config.SelectedBoat = boatName
                BoatSystem.SelectedBoatData = boat
                Config.BoatSpeed = boat.Speed
                boatStatus.Text = "🚤 Barco: " .. boat.DisplayName .. " (Vel: " .. boat.Speed .. ")"
                boatInfoStatus.Text = "📊 " .. (boat.GamePassOnly and "🎫 Game Pass" or (boat.Special and "✨ Especial" or "💰 Moedas"))
                statusText.Text = "✅ Barco selecionado: " .. boat.DisplayName
                return true
            end
        end
        return false
    end,
    
    BuySelectedBoat = function()
        if not BoatSystem.SelectedBoatData then
            statusText.Text = "❌ Nenhum barco selecionado"
            return false
        end
        
        local boat = BoatSystem.SelectedBoatData
        statusText.Text = "🚤 Comprando " .. boat.DisplayName .. "..."
        
        if boat.GamePassOnly and boat.GamePassId then
            -- Abrir janela de compra da Game Pass
            MarketplaceService:PromptGamePassPurchase(LP, boat.GamePassId)
            statusText.Text = "🎫 Abrindo janela de compra da Game Pass"
            return false
        else
            -- Compra com moedas do jogo
            local remote = ReplicatedStorage:FindFirstChild("Remotes", true)
            if remote and remote:FindFirstChild("BuyBoat") then
                remote.BuyBoat:FireServer(boat.Name)
                task.wait(2)
            end
        end
        
        task.wait(2)
        
        local boatModel = Workspace:FindFirstChild(boat.ModelName)
        if boatModel then
            BoatSystem.CurrentBoat = boatModel
            boatStatus.Text = "🚤 Barco: " .. boat.DisplayName .. " adquirido"
            boatStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
            return true
        end
        
        statusText.Text = "❌ Falha ao comprar " .. boat.DisplayName
        return false
    end,
    
    BoardBoat = function()
        local boat = BoatSystem.CurrentBoat
        if not boat then return false end
        
        local seat = boat:FindFirstChild("Seat") or boat:FindFirstChild("VehicleSeat")
        if not seat then return false end
        
        local playersOnBoard = 0
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local angle = playersOnBoard * (math.pi * 2 / math.max(Players:GetPlayers().Count - 1, 1))
                    local offset = Vector3.new(math.cos(angle) * 3.5, 2, math.sin(angle) * 3.5)
                    local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.3), {CFrame = seat.CFrame + offset})
                    tween:Play()
                    playersOnBoard = playersOnBoard + 1
                end
            end
        end
        
        VirtualInputManager:SendKeyEvent(true, "F", false, game)
        task.wait(0.3)
        VirtualInputManager:SendKeyEvent(false, "F", false, game)
        
        groupStatus.Text = "👥 Grupo: " .. playersOnBoard + 1 .. " exploradores"
        return true
    end,
    
    SailToIsland = function(islandPosition)
        if not BoatSystem.CurrentBoat or BoatSystem.IsSailing then return end
        
        BoatSystem.IsSailing = true
        statusText.Text = "⛵ Navegando com " .. (BoatSystem.SelectedBoatData and BoatSystem.SelectedBoatData.DisplayName or "barco") .. " para ilha..."
        
        local boat = BoatSystem.CurrentBoat
        local boatRoot = boat:FindFirstChild("HumanoidRootPart") or boat.PrimaryPart
        
        if boatRoot then
            local boatSeat = boat:FindFirstChild("Seat") or boat:FindFirstChild("VehicleSeat")
            if boatSeat and boatSeat:FindFirstChild("Throttle") then
                boatSeat.Throttle = Config.BoatSpeed
            end
            
            local distance = (boatRoot.Position - islandPosition).Magnitude
            local duration = distance / Config.BoatSpeed
            
            local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(boatRoot, tweenInfo, {CFrame = CFrame.new(islandPosition)})
            tween:Play()
            tween.Completed:Wait()
        end
        
        BoatSystem.IsSailing = false
        statusText.Text = "🏝️ Chegou na ilha pré-histórica!"
        return true
    end,
    
    SpawnBoat = function()
        local remote = ReplicatedStorage:FindFirstChild("Remotes", true)
        if remote and remote:FindFirstChild("SpawnBoat") then
            remote.SpawnBoat:FireServer(Config.SelectedBoat)
            task.wait(1)
            local boat = Workspace:FindFirstChild(Config.SelectedBoat)
            if boat then
                BoatSystem.CurrentBoat = boat
                return true
            end
        end
        return false
    end,
}

-- ============================================
-- SISTEMA DE GRUPO E TELEPORTE PERFEITO
-- ============================================

local GroupSystem = {
    GroupMembers = {},
    IsFormingGroup = false,
    
    FormExpeditionGroup = function()
        if GroupSystem.IsFormingGroup then return end
        GroupSystem.IsFormingGroup = true
        
        groupStatus.Text = "👥 Formando grupo de exploração..."
        
        GroupSystem.GroupMembers = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LP then
                table.insert(GroupSystem.GroupMembers, player)
            end
        end
        
        local remote = ReplicatedStorage:FindFirstChild("Remotes", true)
        if remote and remote:FindFirstChild("PartyInvite") then
            for _, member in pairs(GroupSystem.GroupMembers) do
                remote.PartyInvite:FireServer(member.Name)
                task.wait(0.3)
            end
        end
        
        groupStatus.Text = "👥 Grupo: " .. #GroupSystem.GroupMembers + 1 .. " expedicionários"
        GroupSystem.IsFormingGroup = false
        return true
    end,
    
    TeleportGroupToBoat = function()
        if not BoatSystem.CurrentBoat then
            BoatSystem.BuySelectedBoat()
            task.wait(2)
        end
        
        local boat = BoatSystem.CurrentBoat
        if not boat then return false end
        
        local seat = boat:FindFirstChild("Seat") or boat:FindFirstChild("VehicleSeat")
        if not seat then return false end
        
        local teleported = 0
        local boatCFrame = seat.CFrame
        
        for _, player in pairs(GroupSystem.GroupMembers) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local angle = teleported * (math.pi * 2 / math.max(#GroupSystem.GroupMembers, 1))
                local offset = Vector3.new(math.cos(angle) * 3, 2, math.sin(angle) * 3)
                
                local tweenInfo = TweenInfo.new(Config.TweenSpeed, Enum.EasingStyle.Quad)
                local tween = TweenService:Create(char.HumanoidRootPart, tweenInfo, {CFrame = boatCFrame + offset})
                tween:Play()
                
                teleported = teleported + 1
                task.wait(0.1)
            end
        end
        
        groupStatus.Text = "👥 " .. teleported .. " membros no barco"
        return teleported
    end,
    
    TeleportToIsland = function(islandPosition)
        local teleported = 0
        
        for _, player in pairs(GroupSystem.GroupMembers) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local angle = teleported * (math.pi * 2 / math.max(#GroupSystem.GroupMembers, 1))
                local offset = Vector3.new(math.cos(angle) * 2, 0, math.sin(angle) * 2)
                
                local tweenInfo = TweenInfo.new(Config.TweenSpeed, Enum.EasingStyle.Quad)
                local tween = TweenService:Create(char.HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(islandPosition + offset)})
                tween:Play()
                
                teleported = teleported + 1
                task.wait(0.15)
            end
        end
        
        return teleported
    end,
}

-- ============================================
-- DETECÇÃO DA ILHA PRÉ-HISTÓRICA
-- ============================================

local IslandDetection = {
    CurrentIsland = nil,
    IslandPosition = nil,
    
    FindPrehistoricIsland = function()
        local possibleNames = {"Prehistoric", "Jurassic", "Dino", "Fossil", "Ancient", "Volcano", "Vulcao"}
        
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Model") then
                local nameLower = part.Name:lower()
                for _, islandName in pairs(possibleNames) do
                    if nameLower:find(islandName:lower()) then
                        local position = part:IsA("BasePart") and part.Position or 
                                        (part:FindFirstChild("HumanoidRootPart") and part.HumanoidRootPart.Position) or
                                        (part.PrimaryPart and part.PrimaryPart.Position)
                        
                        if position then
                            IslandDetection.CurrentIsland = part
                            IslandDetection.IslandPosition = position
                            return position
                        end
                    end
                end
            end
        end
        return nil
    end,
    
    MonitorIsland = function(callback)
        spawn(function()
            while true do
                local islandPos = IslandDetection.FindPrehistoricIsland()
                if islandPos and callback then
                    callback(islandPos)
                end
                task.wait(2)
            end
        end)
    end,
}

-- ============================================
-- EXPEDIÇÃO COMPLETA
-- ============================================

local Expedition = {
    IsRunning = false,
    
    StartExpedition = function()
        if Expedition.IsRunning then
            statusText.Text = "⚠️ Expedição já em andamento"
            return
        end
        
        if not BoatSystem.SelectedBoatData then
            statusText.Text = "❌ Selecione um barco primeiro na aba BARCOS"
            return
        end
        
        Expedition.IsRunning = true
        statusText.Text = "🚀 Iniciando expedição marítiva..."
        
        spawn(function()
            if Config.AutoGroup then
                GroupSystem.FormExpeditionGroup()
                task.wait(2)
            end
            
            if Config.AutoBoat then
                BoatSystem.BuySelectedBoat()
                task.wait(3)
            end
            
            GroupSystem.TeleportGroupToBoat()
            task.wait(2)
            
            statusText.Text = "🔍 Procurando ilha pré-histórica..."
            local islandPos = nil
            
            while not islandPos and Expedition.IsRunning do
                islandPos = IslandDetection.FindPrehistoricIsland()
                if not islandPos then
                    statusText.Text = "🌊 Ilha não encontrada, continuando busca..."
                end
                task.wait(3)
            end
            
            if islandPos then
                statusText.Text = "🏝️ Ilha encontrada! Navegando..."
                statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
                
                BoatSystem.SailToIsland(islandPos)
                task.wait(1)
                
                GroupSystem.TeleportToIsland(islandPos)
                
                statusText.Text = "✅ Expedição concluída com sucesso!"
            else
                statusText.Text = "❌ Falha ao encontrar ilha pré-histórica"
                statusText.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
            
            Expedition.IsRunning = false
        end)
    end,
    
    StopExpedition = function()
        Expedition.IsRunning = false
        statusText.Text = "⏹️ Expedição encerrada"
    end,
}

-- ============================================
-- COMPONENTES DA GUI
-- ============================================

local function createButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, 10)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createSlider(parent, text, min, max, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. defaultValue
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -10, 0, 4)
    slider.Position = UDim2.new(0, 5, 0, 35)
    slider.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 12, 0, 12)
    button.Position = UDim2.new((defaultValue - min) / (max - min), -6, 0.5, -6)
    button.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    button.Text = ""
    button.BorderSizePixel = 0
    button.Parent = slider
    
    local dragging = false
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    button.InputEnded:Connect(function()
        dragging = false
    end)
    
    local function updateSlider(inputPos)
        local pos = math.clamp((inputPos - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        local value = min + (max - min) * pos
        fill.Size = UDim2.new(pos, 0, 1, 0)
        button.Position = UDim2.new(pos, -6, 0.5, -6)
        label.Text = text .. ": " .. math.floor(value)
        callback(value)
    end
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input.Position.X)
        end
    end)
    
    return frame
end

local function createBoatList(parent)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -50)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #Config.AvailableBoats * 55)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.Parent = parent
    
    local uiList = Instance.new("UIListLayout")
    uiList.Padding = UDim.new(0, 5)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Parent = scrollFrame
    
    for i, boat in pairs(Config.AvailableBoats) do
        local boatFrame = Instance.new("Frame")
        boatFrame.Size = UDim2.new(1, -10, 0, 50)
        boatFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
        boatFrame.BackgroundTransparency = 0.3
        boatFrame.BorderSizePixel = 0
        boatFrame.Parent = scrollFrame
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = boatFrame
        
        local boatIcon = Instance.new("TextLabel")
        boatIcon.Size = UDim2.new(0, 40, 1, 0)
        boatIcon.BackgroundTransparency = 1
        boatIcon.Text = boat.DisplayName:sub(1, 2)
        boatIcon.TextColor3 = Color3.fromRGB(255, 200, 100)
        boatIcon.TextSize = 18
        boatIcon.Font = Enum.Font.GothamBold
        boatIcon.Parent = boatFrame
        
        local boatName = Instance.new("TextLabel")
        boatName.Size = UDim2.new(0, 150, 0, 20)
        boatName.Position = UDim2.new(0, 45, 0, 5)
        boatName.BackgroundTransparency = 1
        boatName.Text = boat.DisplayName
        boatName.TextColor3 = Color3.fromRGB(255, 255, 255)
        boatName.TextSize = 12
        boatName.Font = Enum.Font.GothamSemibold
        boatName.TextXAlignment = Enum.TextXAlignment.Left
        boatName.Parent = boatFrame
        
        local boatInfo = Instance.new("TextLabel")
        boatInfo.Size = UDim2.new(0, 200, 0, 15)
        boatInfo.Position = UDim2.new(0, 45, 0, 25)
        boatInfo.BackgroundTransparency = 1
        local infoText = "⚡ Vel: " .. boat.Speed
        if boat.GamePassOnly then
            infoText = infoText .. " | 🎫 Game Pass"
        elseif boat.Special then
            infoText = infoText .. " | ✨ " .. (boat.UnlockCondition or "Especial")
        else
            infoText = infoText .. " | 💰 " .. boat.Price .. " moedas"
        end
        boatInfo.Text = infoText
        boatInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
        boatInfo.TextSize = 10
        boatInfo.Font = Enum.Font.Gotham
        boatInfo.TextXAlignment = Enum.TextXAlignment.Left
        boatInfo.Parent = boatFrame
        
        local selectBtn = Instance.new("TextButton")
        selectBtn.Size = UDim2.new(0, 80, 0, 30)
        selectBtn.Position = UDim2.new(1, -90, 0.5, -15)
        selectBtn.BackgroundColor3 = (Config.SelectedBoat == boat.Name) and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(255, 100, 50)
        selectBtn.Text = (Config.SelectedBoat == boat.Name) and "✓ SELECIONADO" or "SELECIONAR"
        selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        selectBtn.TextSize = 10
        selectBtn.Font = Enum.Font.GothamBold
        selectBtn.BorderSizePixel = 0
        selectBtn.Parent = boatFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = selectBtn
        
        selectBtn.MouseButton1Click:Connect(function()
            BoatSystem.SelectBoat(boat.Name)
            for _, frame in pairs(scrollFrame:GetChildren()) do
                if frame:IsA("Frame") then
                    local btn = frame:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
                        btn.Text = "SELECIONAR"
                    end
                end
            end
            selectBtn.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
            selectBtn.Text = "✓ SELECIONADO"
        end)
    end
    
    return scrollFrame
end

-- ============================================
-- POPULAR ABAS
-- ============================================

local expeditionContent = Instance.new("ScrollingFrame")
expeditionContent.Size = UDim2.new(1, 0, 1, 0)
expeditionContent.BackgroundTransparency = 1
expeditionContent.CanvasSize = UDim2.new(0, 0, 0, 220)
expeditionContent.ScrollBarThickness = 4
expeditionContent.Parent = contentFrame

local boatsContent = Instance.new("ScrollingFrame")
boatsContent.Size = UDim2.new(1, 0, 1, 0)
boatsContent.BackgroundTransparency = 1
boatsContent.Visible = false
boatsContent.ScrollBarThickness = 4
boatsContent.Parent = contentFrame

local configContent = Instance.new("ScrollingFrame")
configContent.Size = UDim2.new(1, 0, 1, 0)
configContent.BackgroundTransparency = 1
configContent.Visible = false
configContent.CanvasSize = UDim2.new(0, 0, 0, 180)
configContent.ScrollBarThickness = 4
configContent.Parent = contentFrame

local groupContent = Instance.new("ScrollingFrame")
groupContent.Size = UDim2.new(1, 0, 1, 0)
groupContent.BackgroundTransparency = 1
groupContent.Visible = false
groupContent.CanvasSize = UDim2.new(0, 0, 0, 150)
groupContent.ScrollBarThickness = 4
groupContent.Parent = contentFrame

-- Aba Expedição
createButton(expeditionContent, "🚀 INICIAR EXPEDIÇÃO COMPLETA", Color3.fromRGB(255, 100, 50), function()
    Expedition.StartExpedition()
end)

createButton(expeditionContent, "⏹️ PARAR EXPEDIÇÃO", Color3.fromRGB(200, 50, 50), function()
    Expedition.StopExpedition()
end)

createButton(expeditionContent, "🛥️ COMPRAR BARCO SELECIONADO", Color3.fromRGB(50, 100, 200), function()
    BoatSystem.BuySelectedBoat()
end)

createButton(expeditionContent, "👥 TELEPORTAR GRUPO PARA BARCO", Color3.fromRGB(100, 100, 200), function()
    GroupSystem.TeleportGroupToBoat()
end)

-- Aba Barcos
local boatListContainer = Instance.new("Frame")
boatListContainer.Size = UDim2.new(1, 0, 1, 0)
boatListContainer.BackgroundTransparency = 1
boatListContainer.Parent = boatsContent

local refreshBoatsBtn = Instance.new("TextButton")
refreshBoatsBtn.Size = UDim2.new(1, -20, 0, 35)
refreshBoatsBtn.Position = UDim2.new(0, 10, 1, -45)
refreshBoatsBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
refreshBoatsBtn.Text = "🔄 ATUALIZAR BARCOS DESBLOQUEADOS"
refreshBoatsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBoatsBtn.TextSize = 11
refreshBoatsBtn.Font = Enum.Font.GothamBold
refreshBoatsBtn.BorderSizePixel = 0
refreshBoatsBtn.Parent = boatsContent

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = refreshBoatsBtn

local function refreshBoatList()
    BoatSystem.UpdateAvailableBoats()
    if boatListContainer:FindFirstChild("BoatList") then
        boatListContainer.BoatList:Destroy()
    end
    local boatList = createBoatList(boatListContainer)
    boatList.Name = "BoatList"
    boatList.Position = UDim2.new(0, 0, 0, 0)
    boatList.Size = UDim2.new(1, 0, 1, -50)
    boatList.Parent = boatListContainer
end

refreshBoatsBtn.MouseButton1Click:Connect(refreshBoatList)
refreshBoatList()

-- Aba Configurações
createSlider(configContent, "Velocidade do Tween", 0.1, 1, Config.TweenSpeed, function(value)
    Config.TweenSpeed = value
end)

createSlider(configContent, "Raio de Teleporte", 3, 15, Config.TeleportRadius, function(value)
    Config.TeleportRadius = math.floor(value)
end)

-- Aba Grupo
createButton(groupContent, "👥 FORMAR GRUPO DE EXPEDIÇÃO", Color3.fromRGB(50, 150, 100), function()
    GroupSystem.FormExpeditionGroup()
end)

createButton(groupContent, "📍 TELEPORTAR GRUPO PARA ILHA", Color3.fromRGB(150, 100, 50), function()
    if IslandDetection.IslandPosition then
        GroupSystem.TeleportToIsland(IslandDetection.IslandPosition)
    else
        statusText.Text = "❌ Ilha não encontrada para teleporte"
    end
end)

createButton(groupContent, "🔍 ATUALIZAR LISTA DO GRUPO", Color3.fromRGB(100, 100, 150), function()
    GroupSystem.GroupMembers = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(GroupSystem.GroupMembers, player)
        end
    end
    groupStatus.Text = "👥 Grupo: " .. #GroupSystem.GroupMembers + 1 .. " membros"
end)

-- Trocar abas
for tabName, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for _, child in pairs(contentFrame:GetChildren()) do
            child.Visible = false
        end
        
        if tabName == "🌊 EXPEDIÇÃO" then
            expeditionContent.Visible = true
        elseif tabName == "🛥️ BARCOS" then
            boatsContent.Visible = true
        elseif tabName == "⚙ CONFIG" then
            configContent.Visible = true
        elseif tabName == "👥 GRUPO" then
            groupContent.Visible = true
        end
        
        for _, tb in pairs(tabButtons) do
            tb.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
            tb.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        btn.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

-- Fechar GUI
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Inicializar
BoatSystem.UpdateAvailableBoats()

-- Detecção de ilha em segundo plano
IslandDetection.MonitorIsland(function(pos)
    if pos then
        statusText.Text = "🏝️ ILHA PRÉ-HISTÓRICA DETECTADA!"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 0)
        boatStatus.Text = "🎯 Alvo localizado!"
    end
end)

-- Atualizar status periodicamente
spawn(function()
    while gui.Parent do
        groupStatus.Text = "👥 Servidor: " .. #Players:GetPlayers() .. " jogadores"
        task.wait(5)
    end
end)

print("✅ XANDOWN HUB V4 - Sistema de Múltiplos Barcos carregado!")
print("🎫 Verifique seus barcos desbloqueados na aba BARCOS")