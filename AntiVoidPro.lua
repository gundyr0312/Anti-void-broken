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
        Text = "Ghost + Protección activada",
        Duration = 3
    })
end)

local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔹 VIDA SIEMPRE AL MÁXIMO (sin bug visual)
    task.spawn(function()
        while Humanoid and Humanoid.Parent do
            if Humanoid.Health > 0 then
                Humanoid.Health = Humanoid.MaxHealth
            end
            task.wait(0.2)
        end
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

    -- 🔥 GHOST MODE (CLAVE)
    local function NoClip()
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    RunService.Stepped:Connect(function()
        if not char or not char.Parent then return end
        NoClip()
    end)

    -- 🔥 ANTI FLING REAL
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end

        local vel = Root.Velocity

        -- Cancelar velocidades raras
        if vel.Magnitude > 50 then
            Root.Velocity = Vector3.new(0,0,0)
        end

        -- Limitar movimiento
        Root.Velocity = Vector3.new(
            math.clamp(vel.X, -25, 25),
            math.clamp(vel.Y, -30, 30),
            math.clamp(vel.Z, -25, 25)
        )

        -- Quitar rotación
        Root.RotVelocity = Vector3.new(0,0,0)

        -- Eliminar fuerzas externas
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

    -- 🔥 ANTI CAÍDA TOTAL
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end

        local vel = Root.Velocity

        if vel.Y < -40 then
            Root.Velocity = Vector3.new(vel.X, -10, vel.Z)
        end

        if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and vel.Y < -35 then
            Root.Velocity = Vector3.new(vel.X, 60, vel.Z)
        end
    end)
end

-- 🔹 Persistente tras morir
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
