```lua
------------------------------------------------------------
-- SYS://IMMORTAL
-- CLIENT ONLY
-- Inmortalidad + AntiCaída + AntiFling + AntiStun
------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- CONFIGURACIÓN
------------------------------------------------------------

pcall(function()
	workspace.FallenPartsDestroyHeight = -50000
end)

local Config = {

	-- AntiStun
	AnchorDistance = 30,
	MaxAnchoredTime = 0.20,
	StunlockThreshold = 30,
	StunlockTime = 0.20,

	-- Anti caída
	FallSpeedThreshold = -10,

	-- Raycast mínimo
	MinRayLength = 30,

	-- Predicción
	PredictionTime = 0.35,

	-- Vacío
	VoidHeight = -300,

	-- Velocidad máxima
	MaxVelocity = 150
}

------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------

local Character = nil
local Humanoid = nil
local HRP = nil

local CharacterConnections = {}
local AntiFlingConnections = {}

local AnchoredTime = 0
local StunTime = 0

local LastPosition = Vector3.zero
local LastMoveTime = 0

------------------------------------------------------------
-- COLLISION GROUPS
------------------------------------------------------------

pcall(function()
	PhysicsService:RegisterCollisionGroup("AntiflingPlayers")
end)

pcall(function()
	PhysicsService:RegisterCollisionGroup("AntiflingMe")
end)

pcall(function()
	PhysicsService:CollisionGroupSetCollidable(
		"AntiflingPlayers",
		"AntiflingMe",
		false
	)
end)

pcall(function()
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

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Frame

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(0, 255, 0)
	Stroke.Thickness = 2
	Stroke.Parent = Frame

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

	if Frame and Frame.Parent then

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

	end

	if ScreenGui then
		ScreenGui:Destroy()
	end

end)

------------------------------------------------------------
-- LIMPIAR CONEXIONES DEL PERSONAJE
------------------------------------------------------------

local function ClearCharacterConnections()

	for _, Connection in ipairs(CharacterConnections) do

		if Connection then
			Connection:Disconnect()
		end

	end

	table.clear(CharacterConnections)

end

------------------------------------------------------------
-- LIMPIAR ANTI-FLING
------------------------------------------------------------

local function ClearAntiFling()

	for _, Connection in ipairs(AntiFlingConnections) do

		if Connection then
			Connection:Disconnect()
		end

	end

	table.clear(AntiFlingConnections)

end

------------------------------------------------------------
-- BREAK STUN
------------------------------------------------------------

local function BreakStun()

	if not Character
		or not Character.Parent then
		return
	end

	if not Humanoid
		or not Humanoid.Parent then
		return
	end

	if not HRP
		or not HRP.Parent then
		return
	end

	Humanoid.PlatformStand = false
	Humanoid.Sit = false

	pcall(function()
		Humanoid:ChangeState(
			Enum.HumanoidStateType.GettingUp
		)
	end)

	HRP.AssemblyLinearVelocity = Vector3.zero
	HRP.AssemblyAngularVelocity = Vector3.zero

	HRP.Anchored = false

end

------------------------------------------------------------
-- COLLISION GROUP DEL PERSONAJE
------------------------------------------------------------

local function SetCharacterCollisionGroup()

	if not Character then
		return
	end

	for _, Object in ipairs(
		Character:GetDescendants()
	) do

		if Object:IsA("BasePart") then

			pcall(function()
				Object.CollisionGroup = "AntiflingMe"
			end)

		end

	end

	local Connection =
		Character.DescendantAdded:Connect(
			function(Object)

				if Object:IsA("BasePart") then

					pcall(function()
						Object.CollisionGroup =
							"AntiflingMe"
					end)

				end

			end
		)

	table.insert(
		CharacterConnections,
		Connection
	)

end

------------------------------------------------------------
-- RAYCAST PARAMETERS
------------------------------------------------------------

local RayParams = RaycastParams.new()

RayParams.FilterType =
	Enum.RaycastFilterType.Exclude

RayParams.IgnoreWater = true

------------------------------------------------------------
-- ANTI CAÍDA
------------------------------------------------------------

local function AntiFall()

	if not Character
		or not Character.Parent then
		return
	end

	if not HRP
		or not HRP.Parent then
		return
	end

	local Velocity =
		HRP.AssemblyLinearVelocity

	--------------------------------------------------------
	-- NO ESTÁ CAYENDO
	--------------------------------------------------------

	if Velocity.Y >=
		Config.FallSpeedThreshold then

		return

	end

	--------------------------------------------------------
	-- IGNORAR PERSONAJE
	--------------------------------------------------------

	RayParams.FilterDescendantsInstances = {
		Character
	}

	--------------------------------------------------------
	-- CALCULAR DISTANCIA
	--------------------------------------------------------

	local RayLength = math.max(
		Config.MinRayLength,
		math.abs(Velocity.Y) *
		Config.PredictionTime
	)

	--------------------------------------------------------
	-- RAYCAST
	--------------------------------------------------------

	local Result = workspace:Raycast(
		HRP.Position,
		Vector3.new(
			0,
			-RayLength,
			0
		),
		RayParams
	)

	if Result then

		----------------------------------------------------
		-- SUELO DETECTADO
		----------------------------------------------------

		local CurrentVelocity =
			HRP.AssemblyLinearVelocity

		HRP.AssemblyLinearVelocity =
			Vector3.new(
				CurrentVelocity.X,
				0,
				CurrentVelocity.Z
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
	-- DESACTIVAR DEAD
	--------------------------------------------------------

	Humanoid:SetStateEnabled(
		Enum.HumanoidStateType.Dead,
		false
	)

	--------------------------------------------------------
	-- DESACTIVAR ESTADOS DE RAGDOLL/STUN
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
	-- VIDA REAL
	--
	-- NO SE CREA UNA VIDA FALSA.
	-- ROBLOX SIGUE MOSTRANDO Humanoid.Health.
	--------------------------------------------------------

	Humanoid.HealthDisplayType =
		Enum.HumanoidHealthDisplayType.DisplayWhenDamaged

	--------------------------------------------------------
	-- RECUPERACIÓN INMEDIATA
	--------------------------------------------------------

	local HealthConnection =
		Humanoid.HealthChanged:Connect(
			function(NewHealth)

				if not Humanoid
					or not Humanoid.Parent then
					return
				end

				if NewHealth <
					Humanoid.MaxHealth then

					Humanoid.Health =
						Humanoid.MaxHealth

				end

			end
		)

	table.insert(
		CharacterConnections,
		HealthConnection
	)

end

------------------------------------------------------------
-- RECUPERACIÓN DEL VACÍO
------------------------------------------------------------

local function RecoverFromVoid()

	if not HRP
		or not HRP.Parent then
		return
	end

	--------------------------------------------------------
	-- BUSCAR SPAWN
	--------------------------------------------------------

	local SpawnLocation = nil

	for _, Object in ipairs(
		workspace:GetDescendants()
	) do

		if Object:IsA("SpawnLocation") then

			SpawnLocation = Object
			break

		end

	end

	--------------------------------------------------------
	-- DETENER FÍSICA
	--------------------------------------------------------

	HRP.AssemblyLinearVelocity =
		Vector3.zero

	HRP.AssemblyAngularVelocity =
		Vector3.zero

	--------------------------------------------------------
	-- TELETRANSPORTAR
	--------------------------------------------------------

	if SpawnLocation then

		HRP.CFrame =
			SpawnLocation.CFrame
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

end

------------------------------------------------------------
-- CONFIGURAR PERSONAJE
------------------------------------------------------------

local function SetupCharacter(NewCharacter)

	ClearCharacterConnections()

	Character = NewCharacter

	Humanoid =
		Character:WaitForChild(
			"Humanoid"
		)

	HRP =
		Character:WaitForChild(
			"HumanoidRootPart"
		)

	--------------------------------------------------------
	-- RESET
	--------------------------------------------------------

	AnchoredTime = 0
	StunTime = 0

	LastPosition =
		HRP.Position

	LastMoveTime =
		tick()

	HRP.Anchored = false

	--------------------------------------------------------
	-- COLLISION
	--------------------------------------------------------

	SetCharacterCollisionGroup()

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
-- ANTI-FLING
------------------------------------------------------------

local function AntiFling()

	ClearAntiFling()

	for _, Object in ipairs(
		workspace:GetDescendants()
	) do

		if not Object:IsA("BasePart") then
			continue
		end

		if Object.Parent == Character then
			continue
		end

		if Object.Anchored then
			continue
		end

		if Object.Name ~=
			"HumanoidRootPart" then
			continue
		end

		----------------------------------------------------
		-- COLLISION
		----------------------------------------------------

		pcall(function()

			Object.CollisionGroup =
				"AntiflingPlayers"

			Object.CanCollide = false

		end)

		----------------------------------------------------
		-- CONTROL DE VELOCIDAD
		----------------------------------------------------

		local Connection

		Connection =
			RunService.Heartbeat:Connect(
				function()

					if not Object
						or not Object.Parent then

						if Connection then
							Connection:Disconnect()
						end

						return

					end

					pcall(function()

						Object.AssemblyLinearVelocity =
							Vector3.zero

						Object.AssemblyAngularVelocity =
							Vector3.zero

						Object.CanCollide = false

					end)

				end
			)

		table.insert(
			AntiFlingConnections,
			Connection
		)

	end

end

------------------------------------------------------------
-- CHARACTER ADDED
------------------------------------------------------------

Player.CharacterAdded:Connect(
	function(NewCharacter)

		task.wait(0.15)

		if NewCharacter
			and NewCharacter.Parent then

			SetupCharacter(
				NewCharacter
			)

		end

		task.wait(0.3)

		AntiFling()

	end
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
-- NUEVOS HUMANOIDROOTPART
------------------------------------------------------------

workspace.DescendantAdded:Connect(
	function(Object)

		if not Object:IsA("BasePart") then
			return
		end

		if Object.Name ~=
			"HumanoidRootPart" then
			return
		end

		if Character
			and Object.Parent == Character then
			return
		end

		pcall(function()

			Object.CollisionGroup =
				"AntiflingPlayers"

			Object.CanCollide = false

		end)

	end
)

------------------------------------------------------------
-- BUCLE PRINCIPAL
------------------------------------------------------------

RunService.Stepped:Connect(
	function(_, DeltaTime)

		if not Character
			or not Character.Parent then
			return
		end

		if not Humanoid
			or not Humanoid.Parent then
			return
		end

		if not HRP
			or not HRP.Parent then
			return
		end

		----------------------------------------------------
		-- 1. VIDA
		----------------------------------------------------

		-- Segunda capa de protección.
		-- HealthChanged es la primera.

		if Humanoid.Health <
			Humanoid.MaxHealth then

			Humanoid.Health =
				Humanoid.MaxHealth

		end

		----------------------------------------------------
		-- 2. ESTADOS
		----------------------------------------------------

		Humanoid.PlatformStand = false
		Humanoid.Sit = false

		----------------------------------------------------
		-- 3. VACÍO
		----------------------------------------------------

		if HRP.Position.Y <
			Config.VoidHeight then

			RecoverFromVoid()

			return

		end

		----------------------------------------------------
		-- 4. ANTI CAÍDA
		----------------------------------------------------

		AntiFall()

		----------------------------------------------------
		-- 5. ANTI ANCHOR
		----------------------------------------------------

		if HRP.Anchored then

			AnchoredTime =
				AnchoredTime + DeltaTime

			if AnchoredTime >
				Config.MaxAnchoredTime then

				BreakStun()

				AnchoredTime = 0

			end

			return

		else

			AnchoredTime = 0

		end

		----------------------------------------------------
		-- 6. VELOCIDAD
		----------------------------------------------------

		local Velocity =
			HRP.AssemblyLinearVelocity

		----------------------------------------------------
		-- 7. MOVIMIENTO
		----------------------------------------------------

		local MoveDelta =
			(
				HRP.Position -
				LastPosition
			).Magnitude

		----------------------------------------------------
		-- 8. STUNLOCK
		----------------------------------------------------

		if Velocity.Magnitude >
			Config.StunlockThreshold
			and MoveDelta < 0.3 then

			StunTime =
				StunTime + DeltaTime

			if StunTime >
				Config.StunlockTime then

				BreakStun()

				StunTime = 0

			end

		else

			StunTime = 0

		end

		----------------------------------------------------
		-- 9. ATASCADO
		----------------------------------------------------

		if MoveDelta < 0.1
			and Velocity.Magnitude > 20 then

			if tick() - LastMoveTime > 0.5 then

				BreakStun()

				LastMoveTime =
					tick()

			end

		else

			LastMoveTime =
				tick()

		end

		LastPosition =
			HRP.Position

		----------------------------------------------------
		-- 10. ROTACIÓN
		----------------------------------------------------

		HRP.AssemblyAngularVelocity =
			Vector3.zero

		----------------------------------------------------
		-- 11. VELOCIDAD EXTREMA
		----------------------------------------------------

		if Velocity.Magnitude >
			Config.MaxVelocity then

			HRP.AssemblyLinearVelocity =
				Vector3.zero

		end

		----------------------------------------------------
		-- 12. ANTI-FLING CERCANO
		----------------------------------------------------

		for _, OtherPlayer in ipairs(
			Players:GetPlayers()
		) do

			if OtherPlayer ~= Player
				and OtherPlayer.Character then

				local OtherHRP =
					OtherPlayer.Character:
					FindFirstChild(
						"HumanoidRootPart"
					)

				if OtherHRP then

					local Distance =
						(
							HRP.Position -
							OtherHRP.Position
						).Magnitude

					local OtherVelocity =
						OtherHRP.AssemblyLinearVelocity
						.Magnitude

					if Distance <
						Config.AnchorDistance
						and OtherVelocity > 100 then

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

------------------------------------------------------------
-- INICIAR ANTI-FLING
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
