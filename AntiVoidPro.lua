local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIGURACIÓN GENERAL
------------------------------------------------------------

-- Evita que Roblox destruya las partes del personaje por caer al vacío.
workspace.FallenPartsDestroyHeight = -50000

local Config = {
	-- Anti-stun
	anchor_dist = 30,
	max_anchored_time = 0.2,
	stunlock_threshold = 30,
	stunlock_time = 0.2,

	-- Anti-caída
	fall_speed_threshold = -30,
	min_ray_length = 15,
	prediction_time = 0.15,

	-- Vacío
	void_height = -300,
	void_buffer = 50,

	-- Anti-velocidad extrema
	max_velocity = 150,

	-- Seguridad
	health_check_interval = 0.05
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
-- VARIABLES DEL PERSONAJE
------------------------------------------------------------

local Character
local Humanoid
local HRP

local CharacterConnections = {}
local GlobalConnections = {}
local HeartbeatLoops = {}

local AnchoredTime = 0
local IsVoiding = false
local StunTime = 0

local LastPos = Vector3.zero
local LastMoveTime = 0

------------------------------------------------------------
-- LIMPIAR CONEXIONES DEL PERSONAJE
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

	HRP.CFrame = cf + Vector3.new(0, 0.1, 0)

	HRP.Anchored = false

end

------------------------------------------------------------
-- VOID DROP
------------------------------------------------------------

local function VoidDrop(char)

	if IsVoiding then
		return
	end

	IsVoiding = true

	local Root = char:FindFirstChild("HumanoidRootPart")

	if not Root then
		IsVoiding = false
		return
	end

	local original = Root.CFrame

	for i = 1, 20 do

		if not Root or not Root.Parent then
			IsVoiding = false
			return
		end

		Root.CFrame = original - Vector3.new(0, 500, 0)

		task.wait(0.02)

	end

	if Root and Root.Parent then

		Root.Anchored = true

		task.wait(5)

		if Root and Root.Parent then

			Root.Anchored = false

			Root.CFrame =
				original + Vector3.new(0, 5, 0)

			Root.AssemblyLinearVelocity = Vector3.zero
			Root.AssemblyAngularVelocity = Vector3.zero

		end

	end

	IsVoiding = false

end

------------------------------------------------------------
-- COLLISION GROUP
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

	-- IMPORTANTE:
	-- Los nuevos objetos añadidos al personaje también reciben
	-- automáticamente el CollisionGroup.

	local connection

	connection = char.DescendantAdded:Connect(function(part)

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

	table.insert(CharacterConnections, connection)

end

------------------------------------------------------------
-- RAYCAST ANTI-CAÍDA
------------------------------------------------------------

local RaycastParams = RaycastParams.new()

RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true

local function AntiFall()

	if not HRP or not HRP.Parent then
		return
	end

	if not Character or not Character.Parent then
		return
	end

	RaycastParams.FilterDescendantsInstances = {
		Character
	}

	local velocity = HRP.AssemblyLinearVelocity

	-- Solo nos interesa cuando realmente está cayendo.
	if velocity.Y >= Config.fall_speed_threshold then
		return
	end

	--------------------------------------------------------
	-- LONGITUD PREDICTIVA
	--------------------------------------------------------

	local rayDistance = math.max(
		Config.min_ray_length,
		math.abs(velocity.Y) * Config.prediction_time
	)

	local direction = Vector3.new(
		0,
		-rayDistance,
		0
	)

	local result = workspace:Raycast(
		HRP.Position,
		direction,
		RaycastParams
	)

	if result then

		-- Evita que el personaje llegue al suelo
		-- con una velocidad vertical peligrosa.

		local currentVelocity =
			HRP.AssemblyLinearVelocity

		HRP.AssemblyLinearVelocity = Vector3.new(
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
	-- DESACTIVAR ESTADO DEAD
	--------------------------------------------------------

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Dead,
		false
	)

	--------------------------------------------------------
	-- OTROS ESTADOS PELIGROSOS
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
	-- HEALTH CHANGED
	--------------------------------------------------------

	local HealthConnection = Humanoid.HealthChanged:Connect(
		function(health)

			if not Humanoid or not Humanoid.Parent then
				return
			end

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
	-- PROTECCIÓN CONTINUA
	--------------------------------------------------------

	task.spawn(function()

		while Humanoid and Humanoid.Parent do

			if Humanoid.Health < Humanoid.MaxHealth then

				Humanoid.Health =
					Humanoid.MaxHealth

			end

			if Humanoid.PlatformStand then
				Humanoid.PlatformStand = false
			end

			if Humanoid.Sit then
				Humanoid.Sit = false
			end

			task.wait(Config.health_check_interval)

		end

	end)

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
	-- REINICIAR VARIABLES
	--------------------------------------------------------

	HRP.Anchored = false

	AnchoredTime = 0
	StunTime = 0

	LastPos = HRP.Position
	LastMoveTime = tick()

	IsVoiding = false

	--------------------------------------------------------
	-- COLLISION GROUP
	--------------------------------------------------------

	SetCollisionGroup(
		char,
		"AntiflingMe"
	)

	--------------------------------------------------------
	-- PROPIEDADES FÍSICAS
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
-- ANTI-FLING DE OTROS JUGADORES
------------------------------------------------------------

local function StopAntiFlingLoops()

	for _, connection in ipairs(HeartbeatLoops) do

		if connection then
			connection:Disconnect()
		end

	end

	table.clear(HeartbeatLoops)

end

local function AntiFling()

	StopAntiFlingLoops()

	for _, v in ipairs(game:GetDescendants()) do

		if not v then
			continue
		end

		if not v:IsA("BasePart") then
			continue
		end

		if v.Parent == Player.Character then
			continue
		end

		if v.Anchored then
			continue
		end

		if v.Name ~= "HumanoidRootPart" then
			continue
		end

		pcall(function()

			v.CollisionGroup =
				"AntiflingPlayers"

			v.CanCollide = false

		end)

		local connection

		connection =
			RunService.Heartbeat:Connect(function()

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

			end)

		table.insert(
			HeartbeatLoops,
			connection
		)

	end

end

------------------------------------------------------------
-- DETECCIÓN DE NUEVOS HUMANOIDROOTPART
------------------------------------------------------------

table.insert(
	GlobalConnections,

	workspace.DescendantAdded:Connect(function(part)

		if not part:IsA("BasePart") then
			return
		end

		if part.Name ~= "HumanoidRootPart" then
			return
		end

		if Character and part.Parent == Character then
			return
		end

		pcall(function()

			part.CollisionGroup =
				"AntiflingPlayers"

			part.CanCollide = false

		end)

		task.delay(0.5, function()

			if part and part.Parent then
				AntiFling()
			end

		end)

	end)
)

------------------------------------------------------------
-- BUCLE PRINCIPAL DE FÍSICAS
--
-- STEPPED:
-- se ejecuta antes del paso de simulación física.
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
			-- A. RECUPERACIÓN DEL VACÍO
			------------------------------------------------

			local posY =
				HRP.Position.Y

			if posY <
				(Config.void_height + Config.void_buffer) then

				if not IsVoiding then

					-- Recuperación inmediata.
					--
					-- Primero detenemos la física para
					-- evitar que continúe cayendo.

					HRP.AssemblyLinearVelocity =
						Vector3.zero

					HRP.AssemblyAngularVelocity =
						Vector3.zero

					-- Intentamos usar el SpawnLocation
					-- como punto seguro.

					local spawnLocation

					for _, object in ipairs(
						workspace:GetDescendants()
					) do

						if object:IsA("SpawnLocation") then

							spawnLocation = object
							break

						end

					end

					if spawnLocation then

						HRP.CFrame =
							spawnLocation.CFrame
							+ Vector3.new(0, 5, 0)

					else

						-- Punto de emergencia.

						HRP.CFrame =
							CFrame.new(0, 100, 0)

					end

				end

				return

			end

			------------------------------------------------
			-- B. ANTI-CAÍDA POR RAYCAST
			------------------------------------------------

			AntiFall()

			------------------------------------------------
			-- C. ANTI-ANCHOR
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
			-- D. DETECCIÓN DE STUN
			------------------------------------------------

			local vel =
				HRP.AssemblyLinearVelocity

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
			-- E. PERSONAJE INMOVILIZADO
			------------------------------------------------

			if moveDelta < 0.1
				and vel.Magnitude > 20 then

				if tick() - LastMoveTime > 0.5 then

					BreakStun()

					LastMoveTime = tick()

				end

			else

				LastMoveTime = tick()

			end

			LastPos = HRP.Position

			------------------------------------------------
			-- F. ANULAR ROTACIÓN
			------------------------------------------------

			HRP.AssemblyAngularVelocity =
				Vector3.zero

			------------------------------------------------
			-- G. PROTECCIÓN CONTRA VELOCIDAD EXTREMA
			------------------------------------------------

			if vel.Magnitude >
				Config.max_velocity then

				HRP.AssemblyLinearVelocity =
					Vector3.zero

			end

			------------------------------------------------
			-- H. ANTI-FLING POR PROXIMIDAD
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
							(HRP.Position -
								OtherHRP.Position).Magnitude

						local OtherVel =
							OtherHRP.AssemblyLinearVelocity.Magnitude

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
-- CHARACTER ADDED
------------------------------------------------------------

table.insert(
	GlobalConnections,

	Player.CharacterAdded:Connect(
		function(newChar)

			task.wait(0.2)

			if newChar and newChar.Parent then
				SetupCharacter(newChar)
			end

			-- Reiniciar AntiFling después del respawn.

			task.delay(
				0.5,
				function()

					if newChar
						and newChar.Parent then

						AntiFling()

					end

				end
			)

		end
	)
)

------------------------------------------------------------
-- CONFIGURAR PERSONAJE ACTUAL
------------------------------------------------------------

if Player.Character then

	SetupCharacter(
		Player.Character
	)

end

------------------------------------------------------------
-- ESPERAR A QUE EL JUEGO ESTÉ COMPLETAMENTE CARGADO
------------------------------------------------------------

task.spawn(function()

	if not game:IsLoaded() then

		repeat
			task.wait()
		until game:IsLoaded()

	end

	task.wait(2)

	AntiFling()

end)
