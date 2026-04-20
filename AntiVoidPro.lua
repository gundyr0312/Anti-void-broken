local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer

workspace.FallenPartsDestroyHeight = 0/0

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "VOID MODE",
        Text = "Vida negativa activada",
        Duration = 3
    })
end)

local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔥 VIDA NEGATIVA (SIN MORIR)
    task.spawn(function()
        task.wait(0.3)

        if Humanoid then
            Humanoid.Health = -1
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)

    -- 🔹 Evitar muerte real
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    Humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Dead then
            Humanoid.Health = -1
            Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)

    -- 🔹 Anti estados molestos
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, false)

    -- 🔥 Mantener vida negativa constante
    RunService.Heartbeat:Connect(function()
        if Humanoid and Humanoid.Health < 0 then
            Humanoid.Health = -1
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

    -- 🔹 Anti caída
    RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then return end

        local vel = Root.Velocity

        if vel.Y < -40 then
            Root.Velocity = Vector3.new(vel.X, -10, vel.Z)
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
        return warn("[VOID MODE]: Kick bloqueado")
    end
    return oldNamecall(self, ...)
end)
