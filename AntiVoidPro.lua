```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIGURACIÓN
------------------------------------------------------------

workspace.FallenPartsDestroyHeight = -50000

local Config = {

	-- Anti-Stun
	anchor_dist = 30,
	max_anchored_time = 0.2,
	stunlock_threshold = 30,
	stunlock_time = 0.2,

	-- Anti-Caída
	fall_speed_threshold = -15,

	-- MUY IMPORTANTE:
	-- El rayo ahora es bastante más largo.
	min_ray_length = 25,

	-- Tiempo de predicción
	prediction_time = 0.30,

	-- Altura de emergencia
	void_height = -300,

	-- Velocidad máxima permitida
	max_velocity = 150,

	-- Protección de vida
	health_check_interval = 0.01
}

------------------------------------------------------------
-- COLLISION GROUPS
------------------------------------------------------------

pcall(function()

	if not PhysicsService:IsCollisionGroupRegistered("AntiflingPlayers") then
		PhysicsService:RegisterCollisionGroup("AntiflingPlayers")
	end

	if not PhysicsService:IsCollisionGroupRegistered("AntiflingMe") then
		PhysicsService:RegisterCollisionGroup("AntiflingMe")
	end

	PhysicsService:CollisionGroupSetCollidable(
		"AntiflingPlayers",
		"AntiflingMe",
		false
	)

	PhysicsService:CollisionGroupSetCollidable(
		"AntiflingMe",
		"Default",
		true
	)

end)

------------------------------------------------------------
-- NOTIFICACIÓN
------------------------------------------------------------

task.spawn(function()

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ImmortalNotif"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = PlayerGui

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 240, 0, 50)
	Frame.Position = UDim2.new(1, 260, 1, -60)
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Frame.BackgroundTransparency = 0.1
	Frame.BorderSizePixel = 0
	Frame.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 8)
	UICorner.Parent = Frame

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Color = Color3.fromRGB(0, 255, 0)
	UIStroke.Thickness = 2
	UIStroke.Parent = Frame

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -10, 0, 20)
	Title.Position = UDim2.new(0, 5, 0, 5)
	Title.BackgroundTransparency = 1
	Title.Text = "🟢 SYS://IMMORTAL"
	Title.TextColor3 = Color3.fromRGB(0, 255, 0)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Frame

	local Text = Instance.new("TextLabel")
	Text.Size = UDim2.new(1, -10, 0, 20)
	Text.Position = UDim2.new(0, 5, 0, 25)
	Text.BackgroundTransparency = 1
	Text.Text = "Estado: ACTIVO"
	Text.TextColor3 = Color3.fromRGB(200, 200, 200)
	Text.Font = Enum.Font.Gotham
	Text.TextSize = 12
	Text.TextXAlignment = Enum.TextXAlignment.Left
	Text.Parent = Frame

	local TweenIn = TweenService:Create(
		Frame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back),
		{
			Position = UDim2.new(1, -250, 1, -10)
		}
	)

	TweenIn:Play()

	task.wait(3)

	if not Frame or not Frame.Parent then
		return
	end

	local TweenOut = TweenService:Create(
		Frame,
		TweenInfo.new(
			0.3,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{
			Position = UDim2.new(1, 260, 1, -60)
		}
	)

	TweenOut:Play()
	TweenOut.Completed:Wait()

	if ScreenGui then
		ScreenGui:Destroy()
	end

end)

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------

local Character
local Humanoid
local HRP

local CharacterConnections = {}
local GlobalConnections = {}
local AntiFlingConnections = {}

local AnchoredTime = 0
local StunTime = 0

local LastPos = Vector3.zero
local LastMoveTime = 0

local IsVoiding = false

------------------------------------------------------------
-- LIMPIAR CONEXIONES
------------------------------------------------------------

local function DisconnectCharacterConnections()

	for _, connection in ipairs(CharacterConnections) do

		if connection then
			connection:Disconnect()
		end

	end

	table.clear(CharacterConnections)

end

------------------------------------------------------------
-- BREAK STUN
------------------------------------------------------------

local function BreakStun()

	if not HRP or not HRP.Parent then
		return
	end

	if not Humanoid or not Humanoid.Parent then
		return
	end

	Humanoid.PlatformStand = false
	Humanoid.Sit = false

	pcall(function()
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	HRP.AssemblyLinearVelocity = Vector3.zero
	HRP.AssemblyAngularVelocity = Vector3.zero

	local cf = HRP.CFrame

	HRP.CFrame =
		cf + Vector3.new(0, 0.1, 0)

	HRP.Anchored = false

end

------------------------------------------------------------
-- CONFIGURAR COLLISION GROUP
------------------------------------------------------------

local function SetCollisionGroup(char, groupName)

	for _, part in ipairs(char:GetDescendants()) do

		if part:IsA("BasePart") then

			pcall(function()

				part.CollisionGroup = groupName

				if groupName == "AntiflingPlayers" then
					part.CanCollide = false
				end

			end)

		end

	end

	local connection =
		char.DescendantAdded:Connect(function(part)

			if not part:IsA("BasePart") then
				return
			end

			pcall(function()

				part.CollisionGroup = groupName

				if groupName == "AntiflingPlayers" then
					part.CanCollide = false
				end

			end)

		end)

	table.insert(
		CharacterConnections,
		connection
	)

end

------------------------------------------------------------
-- RAYCAST
------------------------------------------------------------

local RaycastParams = RaycastParams.new()

RaycastParams.FilterType =
	Enum.RaycastFilterType.Exclude

RaycastParams.IgnoreWater = true

local function GetGroundDistance()

	if not HRP or not HRP.Parent then
		return nil
	end

	if not Character or not Character.Parent then
		return nil
	end

	RaycastParams.FilterDescendantsInstances = {
		Character
	}

	local direction = Vector3.new(
		0,
		-Config.min_ray_length,
		0
	)

	local result = workspace:Raycast(
		HRP.Position,
		direction,
		RaycastParams
	)

	if result then

		return (
			HRP.Position -
			result.Position
		).Magnitude

	end

	return nil

end

------------------------------------------------------------
-- ANTI-CAÍDA
------------------------------------------------------------

local function AntiFall()

	if not HRP or not HRP.Parent then
		return
	end

	if not Humanoid or not Humanoid.Parent then
		return
	end

	local velocity =
		HRP.AssemblyLinearVelocity

	--------------------------------------------------------
	-- DETECTAR SI ESTÁ CAYENDO
	--------------------------------------------------------

	if velocity.Y >= Config.fall_speed_threshold then
		return
	end

	--------------------------------------------------------
	-- RAYCAST PREDICTIVO
	--------------------------------------------------------

	RaycastParams.FilterDescendantsInstances = {
		Character
	}

	local rayDistance = math.max(
		Config.min_ray_length,
		math.abs(velocity.Y) *
		Config.prediction_time
	)

	local result = workspace:Raycast(
		HRP.Position,
		Vector3.new(
			0,
			-rayDistance,
			0
		),
		RaycastParams
	)

	if result then

		----------------------------------------------------
		-- HAY SUELO DEBAJO
		----------------------------------------------------

		local currentVelocity =
			HRP.AssemblyLinearVelocity

		-- Cancelamos la velocidad vertical
		-- antes del siguiente paso de física.

		HRP.AssemblyLinearVelocity =
			Vector3.new(
				currentVelocity.X,
				0,
				currentVelocity.Z
			)

	end

end

------------------------------------------------------------
-- INMORTALIDAD
------------------------------------------------------------

local function SetupImmortality()

	if not Humanoid then
		return
	end

	--------------------------------------------------------
	-- DEAD DESACTIVADO
	--------------------------------------------------------

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Dead,
		false
	)

	--------------------------------------------------------
	-- ESTADOS QUE PUEDEN PROVOCAR STUN
	--------------------------------------------------------

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.FallingDown,
		false
	)

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Ragdoll,
		false
	)

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.PlatformStanding,
		false
	)

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Seated,
		false
	)

	--------------------------------------------------------
	-- MOSTRAR VIDA REAL
	--------------------------------------------------------

	Humanoid.HealthDisplayType =
		Enum.HumanoidHealthDisplayType.DisplayWhenDamaged

	--------------------------------------------------------
	-- PROTECCIÓN INSTANTÁNEA
	--------------------------------------------------------

	local HealthConnection =
		Humanoid.HealthChanged:Connect(
			function(health)

				if not Humanoid
					or not Humanoid.Parent then
					return
				end

				-- Si recibe cualquier daño,
				-- se restaura inmediatamente.

				if health < Humanoid.MaxHealth then

					Humanoid.Health =
						Humanoid.MaxHealth

				end

			end
		)

	table.insert(
		CharacterConnections,
		HealthConnection
	)

	--------------------------------------------------------
	-- SEGUNDA CAPA DE SEGURIDAD
	--------------------------------------------------------

	task.spawn(function()

		while Humanoid
			and Humanoid.Parent do

			if Humanoid.Health <
				Humanoid.MaxHealth then

				Humanoid.Health =
					Humanoid.MaxHealth

			end

			------------------------------------------------
			-- EVITAR PLATFORM STAND
			------------------------------------------------

			if Humanoid.PlatformStand then
				Humanoid.PlatformStand = false
			end

			------------------------------------------------
			-- EVITAR SIT
			------------------------------------------------

			if Humanoid.Sit then
				Humanoid.Sit = false
			end

			task.wait(
				Config.health_check_interval
			)

		end

	end)

end

------------------------------------------------------------
-- VOID RECOVERY
------------------------------------------------------------

local function RecoverFromVoid()

	if not HRP or not HRP.Parent then
		return
	end

	if IsVoiding then
		return
	end

	IsVoiding = true

	--------------------------------------------------------
	-- DETENER FÍSICA
	--------------------------------------------------------

	HRP.AssemblyLinearVelocity =
		Vector3.zero

	HRP.AssemblyAngularVelocity =
		Vector3.zero

	--------------------------------------------------------
	-- BUSCAR SPAWN
	--------------------------------------------------------

	local spawnLocation

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("SpawnLocation") then

			spawnLocation = object
			break

		end

	end

	--------------------------------------------------------
	-- TELETRANSPORTAR
	--------------------------------------------------------

	if spawnLocation then

		HRP.CFrame =
			spawnLocation.CFrame
			+ Vector3.new(0, 5, 0)

	else

		HRP.CFrame =
			CFrame.new(0, 100, 0)

	end

	--------------------------------------------------------
	-- LIMPIAR VELOCIDAD
	--------------------------------------------------------

	HRP.AssemblyLinearVelocity =
		Vector3.zero

	HRP.AssemblyAngularVelocity =
		Vector3.zero

	task.wait(0.1)

	IsVoiding = false

end

------------------------------------------------------------
-- CONFIGURAR PERSONAJE
------------------------------------------------------------

local function SetupCharacter(char)

	DisconnectCharacterConnections()

	Character = char

	Humanoid =
		char:WaitForChild("Humanoid")

	HRP =
		char:WaitForChild("HumanoidRootPart")

	--------------------------------------------------------
	-- RESET
	--------------------------------------------------------

	AnchoredTime = 0
	StunTime = 0
	IsVoiding = false

	LastPos =
		HRP.Position

	LastMoveTime =
		tick()

	HRP.Anchored = false

	--------------------------------------------------------
	-- COLLISION
	--------------------------------------------------------

	SetCollisionGroup(
		char,
		"AntiflingMe"
	)

	--------------------------------------------------------
	-- FÍSICAS
	--------------------------------------------------------

	pcall(function()

		HRP.CustomPhysicalProperties =
			PhysicalProperties.new(
				1,
				0.3,
				0.5
			)

	end)

	--------------------------------------------------------
	-- INMORTALIDAD
	--------------------------------------------------------

	SetupImmortality()

end

------------------------------------------------------------
-- LIMPIAR ANTI-FLING
------------------------------------------------------------

local function ClearAntiFling()

	for _, connection in ipairs(
		AntiFlingConnections
	) do

		if connection then
			connection:Disconnect()
		end

	end

	table.clear(AntiFlingConnections)

end

------------------------------------------------------------
-- ANTI-FLING
------------------------------------------------------------

local function AntiFling()

	ClearAntiFling()

	for _, v in ipairs(
		workspace:GetDescendants()
	) do

		if not v then
			continue
		end

		if not v:IsA("BasePart") then
			continue
		end

		if v.Parent == Character then
			continue
		end

		if v.Anchored then
			continue
		end

		if v.Name ~= "HumanoidRootPart" then
			continue
		end

		----------------------------------------------------
		-- COLLISION GROUP
		----------------------------------------------------

		pcall(function()

			v.CollisionGroup =
				"AntiflingPlayers"

			v.CanCollide = false

		end)

		----------------------------------------------------
		-- PROTECCIÓN CONTINUA
		----------------------------------------------------

		local connection

		connection =
			RunService.Heartbeat:Connect(
				function()

					if not v or not v.Parent then

						if connection then
							connection:Disconnect()
						end

						return

					end

					pcall(function()

						v.CustomPhysicalProperties =
							PhysicalProperties.new(
								0,
								0,
								0
							)

						v.AssemblyLinearVelocity =
							Vector3.zero

						v.AssemblyAngularVelocity =
							Vector3.zero

						v.CanCollide = false

					end)

				end
			)

		table.insert(
			AntiFlingConnections,
			connection
		)

	end

end

------------------------------------------------------------
-- PERSONAJE NUEVO
------------------------------------------------------------

table.insert(
	GlobalConnections,

	Player.CharacterAdded:Connect(
		function(newCharacter)

			task.wait(0.2)

			if newCharacter
				and newCharacter.Parent then

				SetupCharacter(
					newCharacter
				)

			end

			task.delay(
				0.5,
				function()

					if newCharacter
						and newCharacter.Parent then

						AntiFling()

					end

				end
			)

		end
	)
)

------------------------------------------------------------
-- NUEVOS HUMANOIDROOTPART
------------------------------------------------------------

table.insert(
	GlobalConnections,

	workspace.DescendantAdded:Connect(
		function(part)

			if not part:IsA("BasePart") then
				return
			end

			if part.Name ~=
				"HumanoidRootPart" then
				return
			end

			if Character
				and part.Parent == Character then
				return
			end

			pcall(function()

				part.CollisionGroup =
					"AntiflingPlayers"

				part.CanCollide = false

			end)

			task.delay(
				0.5,
				function()

					if part and part.Parent then
						AntiFling()
					end

				end
			)

		end
	)
)

------------------------------------------------------------
-- BUCLE PRINCIPAL
--
-- STEPPED = ANTES DE LA SIMULACIÓN DE FÍSICAS
------------------------------------------------------------

table.insert(
	GlobalConnections,

	RunService.Stepped:Connect(
		function(_, deltaTime)

			if not Character
				or not Character.Parent
				or not Humanoid
				or not Humanoid.Parent
				or not HRP
				or not HRP.Parent then

				AnchoredTime = 0
				StunTime = 0

				return

			end

			------------------------------------------------
			-- 1. VACÍO
			------------------------------------------------

			if HRP.Position.Y <
				Config.void_height then

				RecoverFromVoid()

				return

			end

			------------------------------------------------
			-- 2. ANTI-CAÍDA
			------------------------------------------------

			AntiFall()

			------------------------------------------------
			-- 3. ANTI-ANCHOR
			------------------------------------------------

			if HRP.Anchored then

				AnchoredTime =
					AnchoredTime + deltaTime

				if AnchoredTime >
					Config.max_anchored_time
					and not IsVoiding then

					BreakStun()

					AnchoredTime = 0

				end

				return

			else

				AnchoredTime = 0

			end

			------------------------------------------------
			-- 4. VELOCIDAD
			------------------------------------------------

			local vel =
				HRP.AssemblyLinearVelocity

			------------------------------------------------
			-- 5. DETECCIÓN DE STUN
			------------------------------------------------

			local moveDelta =
				(HRP.Position - LastPos).Magnitude

			if vel.Magnitude >
				Config.stunlock_threshold
				and moveDelta < 0.3 then

				StunTime =
					StunTime + deltaTime

				if StunTime >
					Config.stunlock_time then

					BreakStun()

					StunTime = 0

				end

			else

				StunTime = 0

			end

			------------------------------------------------
			-- 6. PERSONAJE ATASCADO
			------------------------------------------------

			if moveDelta < 0.1
				and vel.Magnitude > 20 then

				if tick() - LastMoveTime > 0.5 then

					BreakStun()

					LastMoveTime =
						tick()

				end

			else

				LastMoveTime =
					tick()

			end

			LastPos =
				HRP.Position

			------------------------------------------------
			-- 7. ROTACIÓN
			------------------------------------------------

			HRP.AssemblyAngularVelocity =
				Vector3.zero

			------------------------------------------------
			-- 8. VELOCIDAD EXTREMA
			------------------------------------------------

			if vel.Magnitude >
				Config.max_velocity then

				HRP.AssemblyLinearVelocity =
					Vector3.zero

			end

			------------------------------------------------
			-- 9. ANTI-FLING DE JUGADORES CERCANOS
			------------------------------------------------

			for _, plr in ipairs(
				Players:GetPlayers()
			) do

				if plr ~= Player
					and plr.Character then

					local OtherHRP =
						plr.Character:FindFirstChild(
							"HumanoidRootPart"
						)

					if OtherHRP then

						local Dist =
							(
								HRP.Position -
								OtherHRP.Position
							).Magnitude

						local OtherVel =
							OtherHRP.AssemblyLinearVelocity
							.Magnitude

						if Dist <
							Config.anchor_dist
							and OtherVel > 100 then

							HRP.Anchored = true

							task.delay(
								0.1,
								function()

									if HRP
										and HRP.Parent
										and HRP.Anchored then

										BreakStun()

									end

								end
							)

							break

						end

					end

				end

			end

		end
	)
)

------------------------------------------------------------
-- PERSONAJE ACTUAL
------------------------------------------------------------

if Player.Character then

	SetupCharacter(
		Player.Character
	)

end

------------------------------------------------------------
-- ESPERAR CARGA COMPLETA
------------------------------------------------------------

task.spawn(function()

	if not game:IsLoaded() then

		repeat
			task.wait()
		until game:IsLoaded()

	end

	task.wait(1)

	AntiFling()

end)
```
