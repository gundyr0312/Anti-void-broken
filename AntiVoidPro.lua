local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

workspace.FallenPartsDestroyHeight = 0/0

-- 🔥 COLLISION GROUPS: Fantasma para jugadores, sólido para mapa
pcall(function()
    PhysicsService:RegisterCollisionGroup("AntiflingPlayers")
    PhysicsService:RegisterCollisionGroup("AntiflingMe")
    PhysicsService:CollisionGroupSetCollidable("AntiflingPlayers", "AntiflingMe", false)
    PhysicsService:CollisionGroupSetCollidable("AntiflingMe", "Default", true)
end)

-- 🟢 TU NOTIFICACIÓN ORIGINAL - SOLO ESO SE MUESTRA
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

-- =========================================================================
-- TODO SE ACTIVA AUTOMÁTICO - SIN BOTONES
-- =========================================================================

local Character, Humanoid, HRP
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
local HeartbeatLoops = {}

-- 🔥 ANTI-STUCK BRUTAL: ROMPE PlatformStand, velocidad, y stun del servidor
local function BreakStun()
    if not HRP or not Humanoid then return end
    
    Humanoid.PlatformStand = false
    Humanoid.Sit = false
    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    
    HRP.AssemblyLinearVelocity = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    
    local cf = HRP.CFrame
    HRP.CFrame = cf + Vector3.new(0, 0.1, 0)
    
    HRP.Anchored = false
end

-- 🔥 VOID DROP PARA BUGEAR VIDA E INMORTALIDAD
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

    -- INMORTALIDAD
    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
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

    -- PRIMERO BUG DE VIDA BAJO TIERRA
    task.spawn(function()
        task.wait(0.3)
        VoidDrop(char)
    end)
end

Player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    SetupCharacter(newChar)
end)

if Player.Character then
    SetupCharacter(Player.Character)
end

-- =========================================================================
-- TU ANTI-FLING ORIGINAL - SE ACTIVA SOLO
-- =========================================================================

function AntiFling()
   for _, conn in pairs(HeartbeatLoops) do
       if conn then conn:Disconnect() end
   end
   HeartbeatLoops = {}
   
   for _, v in next, game:GetDescendants() do
       if v and v:IsA("Part") and v.Parent ~= Player.Character and v.Anchored == false and v.Name == "HumanoidRootPart" then 
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
   
   Humanoid.Died:Connect(function()
       for _, conn in pairs(HeartbeatLoops) do
           if conn then conn:Disconnect() end
       end
       HeartbeatLoops = {}
   end)
end

workspace.DescendantAdded:Connect(function(part) 
    if part:IsA("Part") and part.Name == "HumanoidRootPart" and part.Parent ~= Player.Character then 
        pcall(function()
            part.CollisionGroup = "AntiflingPlayers"
        end)
        task.wait(2) 
        AntiFling()
    end
end)

-- 🔥 CHECK ANTI-STUNLOCK AUTOMÁTICO
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

    local vel = HRP.AssemblyLinearVelocity
    local moveDelta = (HRP.Position - LastPos).Magnitude
    
    if vel.Magnitude > Config.stunlock_threshold and moveDelta < 0.3 then
        StunTime = StunTime + dt
        if StunTime > Config.stunlock_time then
            BreakStun()
            StunTime = 0
        end
    else
        StunTime = 0
    end
    
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

-- =========================================================================
-- EJECUCIÓN AUTOMÁTICA DESPUÉS DE 10S
-- =========================================================================

wait(10)

if not game.IsLoaded(game) then
   repeat task.wait() until game.IsLoaded(game)
end

AntiFling()
