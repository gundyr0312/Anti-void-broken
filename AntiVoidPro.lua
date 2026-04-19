--[[
    Anti-Void Standalone | Extraído de SystemBroken v2
    Función: Evita morir en el vacío de Roblox
    Autor original: SystemBroken | Limpieza: Meta AI
    
    Uso: Ejecutar con loadstring o pegar en exploit
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local AntiVoidEnabled = true -- Cambia a false para desactivar
local OriginalFallHeight = workspace.FallenPartsDestroyHeight
local StateConnection = nil

local function EnableAntiVoid()
    -- 1. Truco principal: desactivar el vacío con NaN
    workspace.FallenPartsDestroyHeight = 0/0
    
    -- 2. Refuerzo: evitar que el Humanoid entre en estado Dead
    local function ProtectHumanoid(char)
        local Humanoid = char:WaitForChild("Humanoid")
        
        -- Desactiva el estado Dead completamente
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        
        -- Si por alguna razón intenta morir, lo forzamos a Physics
        StateConnection = Humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.Dead then
                Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            end
        end)
    end
    
    -- Aplicar al personaje actual y a futuros respawns
    if Player.Character then
        ProtectHumanoid(Player.Character)
    end
    Player.CharacterAdded:Connect(ProtectHumanoid)
end

local function DisableAntiVoid()
    -- Restaurar todo a la normalidad
    workspace.FallenPartsDestroyHeight = OriginalFallHeight
    if StateConnection then
        StateConnection:Disconnect()
        StateConnection = nil
    end
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end
end

-- Toggle principal
if AntiVoidEnabled then
    EnableAntiVoid()
    print("[Anti-Void]: Activado. Ya no morirás en el vacío.")
else
    DisableAntiVoid()
    print("[Anti-Void]: Desactivado.")
end

-- Anti kick por si el juego detecta el NaN
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "Kick" then
        return warn("[Anti-Void]: Kick bloqueado")
    end
    return oldNamecall(self, ...)
end)
