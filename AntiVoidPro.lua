local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

-- 🔹 Anti-void permanente
workspace.FallenPartsDestroyHeight = 0/0

-- 🔹 Notificación
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "IMMORTAL MODE",
        Text = "Sistema activado",
        Duration = 3
    })
end)

-- 🔹 Regeneración constante
local function ConstantRegen(Humanoid)
    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health > 0 and Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = math.min(Humanoid.Health + 2, Humanoid.MaxHealth)
            end
            task.wait(0.1)
        end
    end)
end

-- 🔹 Protección completa
local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔥 TU BLOQUE (MEJORADO)
    local FallDamageScript = char:FindFirstChild("FallDamageScript")
    if FallDamageScript then
        FallDamageScript:Destroy()
    end

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, false)

    -- 🔹 Anti muerte directa
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    Humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Dead then
            Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)

    -- 🔹 Regeneración
    ConstantRegen(Humanoid)

    -- 🔹 Anti fuerzas externas (meteoritos, explosiones, empujes)
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end
        if Root then
            Root.Velocity = Vector3.new(0,0,0)
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
        end
    end)
end

-- 🔹 Persistencia tras morir
if Player.Character then
    task.spawn(function()
        ProtectCharacter(Player.Character)
    end)
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
