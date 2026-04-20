local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

workspace.FallenPartsDestroyHeight = 0/0

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "IMMORTAL MODE",
        Text = "Sistema activado",
        Duration = 3
    })
end)

local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔹 Guardar vida anterior
    local lastHealth = Humanoid.Health

    -- 🔥 DETECTOR DE DAÑO (cura instantánea)
    Humanoid.HealthChanged:Connect(function(h)
        if h < lastHealth then
            -- Si recibió daño → lo curamos al instante
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

    -- 🔥 ANTI CAÍDA REAL (3 en 1)
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end

        local vel = Root.Velocity

        -- 1. Limitar velocidad de caída (CLAVE)
        if vel.Y < -40 then
            Root.Velocity = Vector3.new(vel.X, -10, vel.Z)
        end

        -- 2. Rebote suave
        if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and vel.Y < -35 then
            Root.Velocity = Vector3.new(vel.X, 60, vel.Z)
        end

        -- 3. Anti fuerzas externas
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

-- 🔹 Persistente
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
