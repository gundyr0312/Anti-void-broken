local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

workspace.FallenPartsDestroyHeight = 0/0

-- 🔥 COLLISION GROUPS
pcall(function()
    PhysicsService:RegisterCollisionGroup("AntiflingPlayers")
    PhysicsService:RegisterCollisionGroup("AntiflingMe")
    PhysicsService:CollisionGroupSetCollidable("AntiflingPlayers", "AntiflingMe", false)
    PhysicsService:CollisionGroupSetCollidable("AntiflingMe", "Default", true)
end)

-- 🟢 NOTIFICACIÓN
task.spawn(function()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ImmortalNotif"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 240, 0, 50)
    Frame.Position = UDim2.new(1, 260, 1, -60)
    Frame.AnchorPoint = Vector2.new(0, 1)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BackgroundTransparency = 0.1
    Frame.BorderSizePixel = 0

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 8)

    local UIStroke = Instance.new("UIStroke", Frame)
    UIStroke.Color = Color3.fromRGB(0, 255, 0)
    UIStroke.Thickness = 2

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "🟢 SYS://IMMORTAL"
    Title.TextColor3 = Color3.fromRGB(0, 255, 0)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Text = Instance.new("TextLabel", Frame)
    Text.Size = UDim2.new(1, -10, 0, 20)
    Text.Position = UDim2.new(0, 5, 0, 25)
    Text.BackgroundTransparency = 1
    Text.Text = "Estado: ACTIVO"
    Text.TextColor3 = Color3.fromRGB(200, 200, 200)
    Text.Font = Enum.Font.Gotham
    Text.TextSize = 12
    Text.TextXAlignment = Enum.TextXAlignment.Left

    local TweenIn = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -250, 1, -10)
    })
    TweenIn:Play()

    task.wait(3)

    local TweenOut = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 260, 1, -60)
    })
    TweenOut:Play()
    TweenOut.Completed:Wait()

    ScreenGui:Destroy()
end)

-- ⚙️ CONFIG
local Config = {
    anchor_dist = 30,
    max_anchored_time = 0.2,
    stunlock_threshold = 30,
    stunlock_time = 0.2 -- 🔥 MÁS AGRESIVO: 0.2s
}

local Character, Humanoid, HRP
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

local function VoidDrop(char)
    if IsVoiding then return end
    IsVoiding = true
    local Root = char:WaitForChild("HumanoidRootPart")
    local original = Root.CFrame

    for i = 1, 20 do
        if not Root or not Root.Parent then IsVoiding = false return end
        Root.CFrame = original - Vector3.new(0, 500, 0)
        task.wait(0.02)
    end

    Root.Anchored = true
    task.wait(5)
    if Root and Root.Parent then
        Root.Anchored = false
        Root.CFrame = original + Vector3.new(0, 5, 0)
    end
    IsVoiding = false
end

-- 🔥 FUNCIÓN ANTI-STUCK BRUTAL
local function BreakStun()
    if not HRP or not Humanoid then return end
    
    -- 1. Forzar estados
    Humanoid.PlatformStand = false
    Humanoid.Sit = false
    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    -- 2. Reset velocidades
    HRP.AssemblyLinearVelocity = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    
    -- 3. Micro-teleport para romper stun del servidor
    local cf = HRP.CFrame
    HRP.CFrame = cf + Vector3.new(0, 0.1, 0)
    
    -- 4. Desanclar a la fuerza
    HRP.Anchored = false
end

local function SetupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    
    HRP.Anchored = false
    AnchoredTime = 0
    StunTime = 0
    LastPos = HRP.Position
    LastMoveTime = tick()

    SetCollisionGroup(char, "AntiflingMe")
    HRP.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)

    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
            -- 🔥 FORZAR PLATFORMSTAND = FALSE CADA FRAME
            Humanoid.PlatformStand = false
            Humanoid.Sit = false
            task.wait()
        end
    end)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    task.spawn(function()
        task.wait(0.3)
        VoidDrop(char)
    end)
end

local function NukeAllPlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            SetCollisionGroup(plr.Character, "AntiflingPlayers")
        end
    end
end

-- 🔥 LOOP PRINCIPAL ULTRA AGRESIVO
RunService.Heartbeat:Connect(function(dt)
    if not Character or not Character.Parent or not HRP.Parent then 
        AnchoredTime = 0
        StunTime = 0
        return 
    end

    if HRP.Anchored then
        AnchoredTime = AnchoredTime + dt
        if AnchoredTime > Config.max_anchored_time and not IsVoiding then
            BreakStun()
            AnchoredTime = 0
        end
        return
    else
        AnchoredTime = 0
    end

    NukeAllPlayers()

    local vel = HRP.AssemblyLinearVelocity
    local moveDelta = (HRP.Position - LastPos).Magnitude
    
    -- 🔥 DETECCIÓN DE STUNLOCK MEJORADA
    if vel.Magnitude > Config.stunlock_threshold and moveDelta < 0.3 then
        StunTime = StunTime + dt
        if StunTime > Config.stunlock_time then
            BreakStun() -- 🔥 ROMPER STUN A LA FUERZA
            StunTime = 0
        end
    else
        StunTime = 0
    end
    
    -- 🔥 SI NO TE HAS MOVIDO EN 0.5s Y HAY VELOCIDAD, ESTÁS STUNEADO
    if moveDelta < 0.1 and vel.Magnitude > 20 then
        if tick() - LastMoveTime > 0.5 then
            BreakStun()
            LastMoveTime = tick()
        end
    else
        LastMoveTime = tick()
    end
    
    LastPos = HRP.Position

    HRP.AssemblyAngularVelocity = Vector3.zero

    if vel.Magnitude > 150 then
        HRP.AssemblyLinearVelocity = Vector3.zero
    end

    -- Smart anchor
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local OtherHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if OtherHRP then
                local Dist = (HRP.Position - OtherHRP.Position).Magnitude
                local OtherVel = OtherHRP.AssemblyLinearVelocity.Magnitude
                if Dist < Config.anchor_dist and OtherVel > 100 then
                    HRP.Anchored = true
                    task.delay(0.1, function()
                        if HRP and HRP.Parent and HRP.Anchored then 
                            BreakStun()
                        end
                    end)
                    break
                end
            end
        end
    end
end)

local function ConnectCharacter()
    if Player.Character then
        SetupCharacter(Player.Character)
    end
end

ConnectCharacter()
Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    ConnectCharacter()
end)

-- 🔹 ANTI KICK
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self,...)
    if getnamecallmethod() == "Kick" then
        return warn("Kick bloqueado")
    end
    return oldNamecall(self,...)
end)
