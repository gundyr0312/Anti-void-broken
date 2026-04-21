local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

workspace.FallenPartsDestroyHeight = 0/0

-- 🟢 NOTIFICACIÓN (NEGRO + VERDE)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "🟢 IMMORTAL SYSTEM",
        Text = "AntiVoid + Ghost + Protección activa",
        Duration = 3,
        Icon = "rbxassetid://6023426915" -- icono opcional
    })
end)

-- ⚙️ CONFIG
local Config = {
    disable_rotation = true,
    limit_velocity = true,
    limit_velocity_sensitivity = 150,
    limit_velocity_slow = 0,
    anti_ragdoll = true,
    smart_anchor = true,
    anchor_dist = 30,
    noclip_others = true,
    noclip_distance = 6
}

local Character, Humanoid, HRP
local OtherPlayers = {}
local OriginalCollisions = {}

-- 🔥 VOID METHOD
local function VoidDrop(char)
    local Root = char:WaitForChild("HumanoidRootPart")
    local original = Root.CFrame

    for i = 1, 20 do
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

    -- 🔥 PROTECCIÓN ROOT
    HRP.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)

    -- 🔥 SEMI INMORTALIDAD
    local lastHealth = Humanoid.Health
    Humanoid.HealthChanged:Connect(function(h)
        if h < lastHealth then
            Humanoid.Health = Humanoid.MaxHealth
        end
        lastHealth = Humanoid.Health
    end)

    -- 🔥 ANTI ESTADOS
    if Config.anti_ragdoll then
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end

    -- 🔥 HITBOX + ANTI TOUCH
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            OriginalCollisions[part] = part.CanCollide
            part.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
            part.Touched:Connect(function() end)
        end
    end

    -- 🔥 ACTIVAR VOID AL SPAWN
    task.spawn(function()
        task.wait(0.3)
        pcall(function()
            VoidDrop(char)
        end)
    end)
end

-- 🔹 CACHE JUGADORES
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        OtherPlayers[plr] = char
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    OtherPlayers[plr] = nil
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= Player and plr.Character then
        OtherPlayers[plr] = plr.Character
    end
end

-- 🔥 LOOP PRINCIPAL
RunService.Heartbeat:Connect(function()
    if not Character or not Humanoid or not HRP or HRP.Anchored then return end

    local ShouldNoclip = false

    -- 👻 GHOST SOLO JUGADORES
    if Config.noclip_others then
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
    end

    for part, original in pairs(OriginalCollisions) do
        if part and part.Parent then
            part.CanCollide = ShouldNoclip and false or original
        end
    end

    -- 🔹 Anti rotación
    if Config.disable_rotation then
        HRP.AssemblyAngularVelocity = Vector3.zero
    end

    -- 🔹 Anti velocidad
    if Config.limit_velocity then
        local Vel = HRP.AssemblyLinearVelocity
        if Vel.Magnitude > Config.limit_velocity_sensitivity then
            HRP.AssemblyLinearVelocity = Vector3.zero
        end
    end

    -- 🔹 Smart anchor
    if Config.smart_anchor then
        for _, char in pairs(OtherPlayers) do
            if char and char.Parent then
                local OtherHRP = char:FindFirstChild("HumanoidRootPart")
                if OtherHRP then
                    local Dist = (HRP.Position - OtherHRP.Position).Magnitude
                    local OtherVel = OtherHRP.AssemblyLinearVelocity.Magnitude
                    if Dist < Config.anchor_dist and OtherVel > 100 then
                        HRP.Anchored = true
                        task.delay(0.1, function()
                            if HRP then HRP.Anchored = false end
                        end)
                        break
                    end
                end
            end
        end
    end
end)

-- 🔹 INICIO
if Player.Character then SetupCharacter(Player.Character) end
Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetupCharacter(char)
end)

-- 🔹 ANTI KICK
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    if getnamecallmethod() == "Kick" then
        return warn("[IMMORTAL]: Kick bloqueado")
    end
    return oldNamecall(self, ...)
end)
