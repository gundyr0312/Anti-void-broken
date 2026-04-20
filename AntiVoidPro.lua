local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local OriginalFallHeight = workspace.FallenPartsDestroyHeight

-- 🔹 Anti-void global permanente
workspace.FallenPartsDestroyHeight = 0/0

-- 🔹 Notificación (3 segundos)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "IMMORTAL MODE",
        Text = "Protección activada",
        Duration = 3
    })
end)

local function ProtectCharacter(char)
    local Humanoid = char:WaitForChild("Humanoid")
    local Root = char:WaitForChild("HumanoidRootPart")

    -- 🔹 Anti muerte
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

    Humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Dead then
            Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end)

    -- 🔹 Anti ragdoll y estados molestos
    local blockedStates = {
        Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.PlatformStand,
        Enum.HumanoidStateType.Seated
    }

    for _, state in pairs(blockedStates) do
        Humanoid:SetStateEnabled(state, false)
    end

    -- 🔹 Auto curación constante
    Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health < Humanoid.MaxHealth then
            Humanoid.Health = Humanoid.MaxHealth
        end
    end)

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

    -- 🔹 Anti caída
    Humanoid.UseJumpPower = true
    Humanoid.JumpPower = 50
end

-- 🔹 Aplicar siempre (aunque mueras)
if Player.Character then
    task.spawn(function()
        ProtectCharacter(Player.Character)
    end)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5) -- evita bugs de carga
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
