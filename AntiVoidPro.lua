-- =========================================================================
-- Anti-Fling Hub UI + Lógica Anti-Stunlock
-- =========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

workspace.FallenPartsDestroyHeight = 0/0

-- 🔥 COLLISION GROUPS: Fantasma para jugadores, sólido para mapa
pcall(function()
    PhysicsService:RegisterCollisionGroup("AntiflingPlayers")
    PhysicsService:RegisterCollisionGroup("AntiflingMe")
    PhysicsService:CollisionGroupSetCollidable("AntiflingPlayers", "AntiflingMe", false)
    PhysicsService:CollisionGroupSetCollidable("AntiflingMe", "Default", true)
end)

-- =========================================================================
-- UI BASE TUYA MODIFICADA
-- =========================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiFlingHubUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Position = UDim2.new(1, -MainFrame.Size.X.Offset - 10, 0.5, -MainFrame.Size.Y.Offset / 2)
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 25)
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -25, 1, 0)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 18
TitleLabel.Text = "Anti-Fling Hub"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 25, 1, 0)
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.Text = "X"
CloseButton.Parent = TitleBar

CloseButton.MouseButton1Click:Connect(function()
    if _G.positionCheckConnection then
        _G.positionCheckConnection:Disconnect()
        _G.positionCheckConnection = nil
    end
    if _G.antiFlingActive and rootPart then
        pcall(function()
            rootPart:SetNetworkOwner(player)
        end)
    end
    ScreenGui:Destroy()
    print("Anti-Fling Hub e Script Desativados Completamente.")
end)

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ContentFrame
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function AddToggle(parentFrame, name, defaultValue, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(0.95, 0, 0, 30)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Parent = parentFrame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 5, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.SourceSans
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = name
    Label.Parent = ToggleFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 50, 0, 20)
    ToggleButton.Position = UDim2.new(1, -55, 0.5, -10)
    ToggleButton.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.TextSize = 14
    ToggleButton.Text = defaultValue and "ATIVO" or "INATIVO"
    ToggleButton.Parent = ToggleFrame

    local currentValue = defaultValue
    ToggleButton.MouseButton1Click:Connect(function()
        currentValue = not currentValue
        ToggleButton.BackgroundColor3 = currentValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        ToggleButton.Text = currentValue and "ATIVO" or "INATIVO"
        if callback then
            callback(currentValue)
        end
    end)
    return { SetValue = function(value) currentValue = value; ToggleButton.BackgroundColor3 = value and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0); ToggleButton.Text = value and "ATIVO" or "INATIVO" end }
end

-- =========================================================================
-- LÓGICA ANTI-FLING + ANTI-STUNLOCK
-- =========================================================================

_G.antiFlingActive = false
_G.lastPosition = Vector3.new(0, 0, 0)
_G.positionCheckConnection = nil

local Config = {
    anchor_dist = 30,
    max_anchored_time = 0.2,
    stunlock_threshold = 30,
    stunlock_time = 0.2
}

local AnchoredTime = 0
local IsVoiding = false
local StunTime = 0
local LastPos = Vector3.zero
local LastMoveTime = 0

local function SetCollisionGroup(char, groupName)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CollisionGroup = groupName
                if groupName == "AntiflingPlayers" then
                    part.CanCollide = false
                end
            end)
        end
    end
    
    char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            pcall(function()
                part.CollisionGroup = groupName
                if groupName == "AntiflingPlayers" then
                    part.CanCollide = false
                end
            end)
        end
    end)
end

-- 🔥 ANTI-STUCK BRUTAL: ROMPE PlatformStand, velocidad, y stun del servidor
local function BreakStun()
    if not rootPart or not character then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    hum.PlatformStand = false
    hum.Sit = false
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    
    local cf = rootPart.CFrame
    rootPart.CFrame = cf + Vector3.new(0, 0.1, 0)
    
    rootPart.Anchored = false
end

local function SetupCharacter(char)
    character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    
    rootPart.Anchored = false
    AnchoredTime = 0
    StunTime = 0
    LastPos = rootPart.Position
    LastMoveTime = tick()

    SetCollisionGroup(char, "AntiflingMe")
    rootPart.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)

    task.spawn(function()
        while hum and hum.Parent do
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
            hum.PlatformStand = false
            hum.Sit = false
            task.wait()
        end
    end)

    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
end

player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    SetupCharacter(newChar)
end)

if character then
    SetupCharacter(character)
end

-- =========================================================================
-- TU ANTI-FLING NUEVO - REEMPLAZA AL VIEJO
-- =========================================================================

local HeartbeatLoops = {}

function AntiFling()
   -- Limpiar loops viejos
   for _, conn in pairs(HeartbeatLoops) do
       if conn then conn:Disconnect() end
   end
   HeartbeatLoops = {}
   
   for _, v in next, game:GetDescendants() do
       if v and v:IsA("Part") and v.Parent ~= player.Character and v.Anchored == false and v.Name == "HumanoidRootPart" then 
           -- Meter al collision group
           pcall(function()
               v.CollisionGroup = "AntiflingPlayers"
           end)
           
           local HeartbeatLoop = RunService.Heartbeat:Connect(function()
               v.CustomPhysicalProperties = PhysicalProperties.new(0,0,0)
               v.Velocity = Vector3.new(0,0,0)
               v.RotVelocity = Vector3.new(0,0,0)
               v.CanCollide = false
               task.wait(1)
           end)
           table.insert(HeartbeatLoops, HeartbeatLoop)
       end
   end
   
   character.Humanoid.Died:Connect(function()
       for _, conn in pairs(HeartbeatLoops) do
           if conn then conn:Disconnect() end
       end
       HeartbeatLoops = {}
   end)
end

workspace.DescendantAdded:Connect(function(part) 
    if part:IsA("Part") and part.Name == "HumanoidRootPart" and part.Parent ~= game.Players.LocalPlayer.Character then 
        pcall(function()
            part.CollisionGroup = "AntiflingPlayers"
        end)
        task.wait(2) 
        AntiFling()
    end
end)

-- 🔥 CHECK POSITION + ANTI-STUNLOCK
_G.checkPositionAndTeleport = function(dt)
    if not _G.antiFlingActive or not rootPart.Parent then
        AnchoredTime = 0
        StunTime = 0
        return
    end

    if rootPart.Anchored then
        AnchoredTime = AnchoredTime + dt
        if AnchoredTime > Config.max_anchored_time and not IsVoiding then
            BreakStun()
            AnchoredTime = 0
        end
        return
    else
        AnchoredTime = 0
    end

    local vel = rootPart.AssemblyLinearVelocity
    local moveDelta = (rootPart.Position - LastPos).Magnitude
    
    -- Detectar stunlock: velocidad alta pero no te mueves
    if vel.Magnitude > Config.stunlock_threshold and moveDelta < 0.3 then
        StunTime = StunTime + dt
        if StunTime > Config.stunlock_time then
            BreakStun()
            StunTime = 0
        end
    else
        StunTime = 0
    end
    
    -- Si no te has movido en 0.5s pero tienes velocidad, estás stuneado
    if moveDelta < 0.1 and vel.Magnitude > 20 then
        if tick() - LastMoveTime > 0.5 then
            BreakStun()
            LastMoveTime = tick()
        end
    else
        LastMoveTime = tick()
    end
    
    LastPos = rootPart.Position

    rootPart.AssemblyAngularVelocity = Vector3.zero

    if vel.Magnitude > 150 then
        rootPart.AssemblyLinearVelocity = Vector3.zero
    end

    -- Smart anchor
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local OtherHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if OtherHRP then
                local Dist = (rootPart.Position - OtherHRP.Position).Magnitude
                local OtherVel = OtherHRP.AssemblyLinearVelocity.Magnitude
                if Dist < Config.anchor_dist and OtherVel > 100 then
                    rootPart.Anchored = true
                    task.delay(0.1, function()
                        if rootPart and rootPart.Parent and rootPart.Anchored then 
                            BreakStun()
                        end
                    end)
                    break
                end
            end
        end
    end

    -- Teleport de recuperación si te fuiste muy lejos
    local currentPosition = rootPart.Position
    local distance = (currentPosition - _G.lastPosition).Magnitude
    local flingThreshold = 60
    local minMovementForTeleport = 0.5

    if distance > flingThreshold and (currentPosition - _G.lastPosition).Magnitude > minMovementForTeleport then
        pcall(function()
            rootPart.CFrame = CFrame.new(_G.lastPosition)
        end)
    end
    _G.lastPosition = currentPosition
end

-- Toggle del Anti-Fling
local AntiFlingToggle = AddToggle(ContentFrame, "Anti-Fling", false, function(state)
    _G.antiFlingActive = state

    if _G.antiFlingActive then
        character = player.Character or player.CharacterAdded:Wait()
        rootPart = character:WaitForChild("HumanoidRootPart")

        pcall(function()
            rootPart:SetNetworkOwner(nil)
        end)

        _G.lastPosition = rootPart.Position
        LastPos = rootPart.Position
        
        -- Ejecutar tu anti-fling nuevo
        AntiFling()
        
        if not _G.positionCheckConnection then
            _G.positionCheckConnection = RunService.Heartbeat:Connect(function(dt)
                _G.checkPositionAndTeleport(dt)
            end)
        end
        print("Anti-Fling Primário Ativado.")
    else
        if rootPart then
            pcall(function()
                rootPart:SetNetworkOwner(player)
            end)
        end
        if _G.positionCheckConnection then
            _G.positionCheckConnection:Disconnect()
            _G.positionCheckConnection = nil
        end
        for _, conn in pairs(HeartbeatLoops) do
            if conn then conn:Disconnect() end
        end
        HeartbeatLoops = {}
        print("Anti-Fling Desativado!")
    end
end)
