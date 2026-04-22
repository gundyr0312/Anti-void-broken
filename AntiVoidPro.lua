local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Evitar que las partes se destruyan en el vacío
workspace.FallenPartsDestroyHeight = -99999 -- Cambiado de 0/0 a un número seguro

-- 🔥 REGISTRO SEGURO DE GRUPOS (Evita errores al re-ejecutar)
local function SafeRegisterGroup(name)
    pcall(function()
        PhysicsService:RegisterCollisionGroup(name)
    end)
end

SafeRegisterGroup("AntiflingPlayers")
SafeRegisterGroup("AntiflingMe")
pcall(function()
    PhysicsService:CollisionGroupSetCollidable("AntiflingPlayers", "AntiflingMe", false)
    PhysicsService:CollisionGroupSetCollidable("AntiflingMe", "Default", true)
end)

-- 🟢 NOTIFICACIÓN MEJORADA
local function Notify()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ImmortalNotif_Fixed"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = UDim2.new(0, 240, 0, 50)
    Frame.Position = UDim2.new(1, 260, 1, -60)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = Color3.fromRGB(0, 255, 0)
    Stroke.Thickness = 2

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, -10, 0, 20); Title.Position = UDim2.new(0, 5, 0, 5)
    Title.Text = "🟢 SYS://IMMORTAL V2"; Title.TextColor3 = Color3.fromRGB(0, 255, 0)
    Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.TextSize = 14

    TweenService:Create(Frame, TweenInfo.new(0.5), {Position = UDim2.new(1, -250, 1, -10)}):Play()
    task.delay(3, function()
        if ScreenGui then ScreenGui:Destroy() end
    end)
end

-- =========================================================================
-- LÓGICA DE INMORTALIDAD Y SEGURIDAD
-- =========================================================================

local Character, Humanoid, HRP
local IsVoiding = false
local HeartbeatLoops = {}

local function BreakStun()
    if not HRP or not Humanoid then return end
    Humanoid.PlatformStand = false
    Humanoid.Sit = false
    Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    HRP.AssemblyLinearVelocity = Vector3.zero
    HRP.Anchored = false
end

-- 🔥 VOID DROP SEGURO: Ahora comprueba si realmente estás vivo
local function VoidDrop(char)
    if IsVoiding then return end
    local Root = char:WaitForChild("HumanoidRootPart", 5)
    local Hum = char:WaitForChild("Humanoid", 5)
    if not Root or not Hum then return end

    IsVoiding = true
    local original = Root.CFrame

    -- Solo baja si tienes vida completa (evita el bucle de muerte)
    if Hum.Health > 0 then
        for i = 1, 15 do
            if not Root or not Root.Parent then break end
            Root.CFrame = CFrame.new(original.Position - Vector3.new(0, 450, 0))
            task.wait(0.01)
        end
        
        Root.Anchored = true
        task.wait(2) -- Reducido tiempo de espera para evitar lag del server
        if Root and Root.Parent then
            Root.Anchored = false
            Root.CFrame = original + Vector3.new(0, 3, 0)
        end
    end
    IsVoiding = false
end

local function SetCollisionGroup(char, groupName)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function() part.CollisionGroup = groupName end)
        end
    end
end

local function SetupCharacter(char)
    if not char then return end
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    
    -- Limpiar estados previos
    HRP.Anchored = false
    SetCollisionGroup(char, "AntiflingMe")

    -- Bucle de Inmortalidad (Solo si el Humanoid existe)
    task.spawn(function()
        while char and char.Parent and Humanoid and Humanoid.Parent do
            if Humanoid.Health > 0 and Humanoid.Health < Humanoid.MaxHealth then
                Humanoid.Health = Humanoid.MaxHealth
            end
            task.wait(0.1)
        end
    end)

    -- Configuración de estados
    local states = {Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead}
    for _, state in pairs(states) do
        Humanoid:SetStateEnabled(state, false)
    end

    -- Ejecutar VoidDrop con un retraso mayor para asegurar carga
    task.delay(2, function()
        if not IsVoiding then VoidDrop(char) end
    end)
end

-- Reiniciar al morir
Player.CharacterAdded:Connect(SetupCharacter)
if Player.Character then SetupCharacter(Player.Character) end

-- 🔥 ANTI-FLING CORREGIDO (Sin bucles infinitos)
function AntiFling()
    for _, conn in pairs(HeartbeatLoops) do conn:Disconnect() end
    HeartbeatLoops = {}

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function() root.CollisionGroup = "AntiflingPlayers" end)
            end
        end
    end
end

-- Monitor de nuevos jugadores
workspace.DescendantAdded:Connect(function(part)
    if part.Name == "HumanoidRootPart" then
        task.wait(1)
        AntiFling()
    end
end)

-- Ejecución inicial
task.wait(5)
Notify()
AntiFling()
