local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

workspace.FallenPartsDestroyHeight = 0/0

-- 🟢 NOTIFICACIÓN ABAJO A LA DERECHA - 3 SEGUNDOS
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
    noclip_distance = 6,
    anchor_dist = 30
}

local Character, Humanoid, HRP
local OtherPlayers = {}
local OriginalCollisions = {}

-- 🔥 VOID
local function VoidDrop(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local original = Root.CFrame

    for i = 1, 20 do
        if not Root or not Root.Parent then return end
        Root.CFrame = original - Vector3.new(0, 500, 0)
        task.wait(0.02)
    end

    Root.Anchored = true
    task.wait(5)
    Root.Anchored = false
    Root.CFrame = original + Vector3.new(0, 5, 0)
end

local function SetupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")

    HRP.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)

    -- Vida infinita persistente
    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
            task.wait()
        end
    end)

    -- Anti estados
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    -- Partes
    table.clear(OriginalCollisions)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            OriginalCollisions[part] = part.CanCollide
            part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
        end
    end

    -- Detectar partes nuevas
    char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            OriginalCollisions[part] = part.CanCollide
            part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
        end
    end)

    task.spawn(function()
        task.wait(0.3)
        VoidDrop(char)
    end)
end

-- 🔹 CACHE JUGADORES
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= Player and plr.Character then
        OtherPlayers[plr] = plr.Character
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        OtherPlayers[plr] = char
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    OtherPlayers[plr] = nil
end)

-- 🔥 LOOP PRINCIPAL - PERSISTENTE HASTA SALIR DEL JUEGO
RunService.Heartbeat:Connect(function()
    -- Si no tienes character, no hacer nada pero el loop sigue vivo
    if not Character or not Character.Parent or not HRP or not HRP.Parent then return end
    if HRP.Anchored then return end

    local ShouldNoclip = false

    for _, char in pairs(OtherPlayers) do
        if char and char.Parent then
            local OtherHRP = char:FindFirstChild("HumanoidRootPart")
            if OtherHRP then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end

                if (HRP.Position - OtherHRP.Position).Magnitude < Config.noclip_distance then
                    ShouldNoclip = true
                end
            end
        end
    end

    for part, original in pairs(OriginalCollisions) do
        if part and part.Parent then
            part.CanCollide = ShouldNoclip and false or original
        end
    end

    HRP.AssemblyAngularVelocity = Vector3.zero

    local vel = HRP.AssemblyLinearVelocity
    if vel.Magnitude > 150 then
        HRP.AssemblyLinearVelocity = Vector3.zero
    end

    for _, char in pairs(OtherPlayers) do
        if char and char.Parent then
            local OtherHRP = char:FindFirstChild("HumanoidRootPart")
            if OtherHRP then
                local Dist = (HRP.Position - OtherHRP.Position).Magnitude
                local OtherVel = OtherHRP.AssemblyLinearVelocity.Magnitude
                if Dist < Config.anchor_dist and OtherVel > 100 then
                    HRP.Anchored = true
                    task.delay(0.1, function()
                        if HRP and HRP.Parent then HRP.Anchored = false end
                    end)
                    break
                end
            end
        end
    end
end)

-- 🔹 INIT + RE-CONEXIÓN AUTOMÁTICA AL MORIR/RESPAWNEAR
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
