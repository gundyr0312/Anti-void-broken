local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

workspace.FallenPartsDestroyHeight = 0/0

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "IMMORTAL MODE",
        Text = "Ghost players + anti-hitbox activo",
        Duration = 3
    })
end)

-- 🔥 CREAR GRUPOS DE COLISIÓN
pcall(function()
    PhysicsService:CreateCollisionGroup("Players")
    PhysicsService:CreateCollisionGroup("LocalGhost")
end)

PhysicsService:CollisionGroupSetCollidable("Players", "LocalGhost", false)

-- 🔥 ASIGNAR GRUPO A OTROS JUGADORES
local function SetPlayerGroup(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "Players")
        end
    end
end

-- 🔥 TU PERSONAJE → GRUPO GHOST
local function SetLocalGhost(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, "LocalGhost")
        end
    end
end

-- 🔥 ANTI HITBOX (reduce tamaño real)
local function ReduceHitbox(character)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Size = part.Size * 0.3 -- reduce hitbox
            part.Massless = true
        end
    end
end

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

local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔥 Aplicar ghost y hitbox
    SetLocalGhost(char)
    ReduceHitbox(char)

    -- 🔥 Activar void
    task.spawn(function()
        task.wait(0.2)
        VoidDrop(char)
    end)

    -- 🔹 Anti daño
    local lastHealth = Humanoid.Health
    Humanoid.HealthChanged:Connect(function(h)
        if h < lastHealth then
            Humanoid.Health = Humanoid.MaxHealth
        end
        lastHealth = Humanoid.Health
    end)

    -- 🔹 Anti estados
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    Humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Dead then
            Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)

    -- 🔹 Anti fuerzas
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end

        Root.RotVelocity = Vector3.new(0,0,0)

        for _, v in pairs(Root:GetChildren()) do
            if v:IsA("BodyVelocity") 
            or v:IsA("BodyForce") 
            or v:IsA("BodyAngularVelocity")
            or v:IsA("VectorForce")
            then
                v:Destroy()
            end
        end
    end)
end

-- 🔹 Aplicar a jugadores
for _, p in pairs(Players:GetPlayers()) do
    if p ~= Player and p.Character then
        SetPlayerGroup(p.Character)
    end
    p.CharacterAdded:Connect(SetPlayerGroup)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(SetPlayerGroup)
end)

-- 🔹 Tu personaje
if Player.Character then
    ProtectCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    ProtectCharacter(char)
end)

-- 🔹 Anti kick
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    if getnamecallmethod() == "Kick" then
        return warn("[IMMORTAL]: Kick bloqueado")
    end
    return oldNamecall(self, ...)
end)
