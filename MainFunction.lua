warn("NextWave Chassis v2.0 initiating on bus "..script.Parent.Parent.Parent.Parent.Name..". v1.x made by RedLightning725, v2.1 Scripted by thyssenkrupp234, based off v1.")
local InputBegan = script.Parent.InputBegan
local InputEnded = script.Parent.InputEnded

local TS = game:GetService("TweenService")

ValueTable.FDoorTIOpen = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
ValueTable.FDoorTIClose =  TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
ValueTable.R = false
ValueTable.M = false
ValueTable.LichtNum = 0

local GearboxGui = script.Parent.Parent.Dash.Gearbox.G.Gear

local RDLights = script.Parent.Parent.Lights.RearDoor

local LeftBlinker = false
local RightBlinker = false
local Hazards = false

local ServerOn = false

local Throttle = false
local Smoke = script.Parent.Parent.ExhaustEmitter.Smoke

local BlinkerSound = script.Parent.Parent.SoundSystem.Horn.Blinker

local RampIP = false
local RDoorIP = false
local RDoorT = 0
local RDoorUT1 = nil
local RDoorUT2 = nil

local FDoorIP = false

local CurrentOccupant = nil

local busconfig = require(script.Parent.Parent.Parent.Parent.BUS_CONFIG)

local UseSmoke = busconfig.General.UseSmokeEmitter

local Timer = busconfig.Doors.RearDoorUnlockTimer

local KneelProtect = busconfig.General.DontAllowKneelingIfMoving
local KeepKneelLightOn = busconfig.General.KeepKneelLightOnWhileKneeled

local MinimumAirPressure = busconfig.Doors.MinimumAirPressure
local Increment = busconfig.Doors.Increment
local MaxPressure = busconfig.Doors.MaxPressure
local UseAirPressureOnRearDoor = busconfig.Doors.UseAirPressureOnRearDoor
local UseAirPressureOnFrontDoor = busconfig.Doors.UseAirPressureOnFrontDoor
local UseAirPressureOnKneel = busconfig.Doors.UseAirPressureOnKneel
local AirPressureSystemEnabled = busconfig.Doors.AirPressureSystemEnabled
local DownIncrement = busconfig.Doors.DownIncrement

local debugmode = busconfig.General.debugmode

local FunctionTable = {
	-- example function
	--HVAC
	V = function()
		local HVACDash = script.Parent.Parent.HUD.DashLights.HVAC
		local value = ValueTable["V"]
		if not value then
			local t = TS:Create(script.Parent.Parent.SoundSystem.EN1.HVAC, TweenInfo.new(1, Enum.EasingStyle.Linear), {Volume = 0})
			t:Play()
			t.Completed:Wait()
			script.Parent.Parent.SoundSystem.EN1.HVAC:Stop()
			HVACDash.SurfaceGui.Enabled = false
		else
			script.Parent.Parent.SoundSystem.EN1.HVAC.Volume = 0
			script.Parent.Parent.SoundSystem.EN1.HVAC:Play()
			local t = TS:Create(script.Parent.Parent.SoundSystem.EN1.HVAC, TweenInfo.new(1, Enum.EasingStyle.Linear), {Volume = 2})
			t:Play()
			t.Completed:Wait()
			HVACDash.SurfaceGui.Enabled = true
		end
	end,

	-- horn
	H = function()
		local val = ValueTable["H"]
		if val then
			script.Parent.Parent.SoundSystem.Horn.Horn:Play()
		else
			script.Parent.Parent.SoundSystem.Horn.Horn:Stop()
		end
	end,

	-- ramp
	R = function()
		local RampDash = script.Parent.Parent.HUD.DashLights.Ramp
		if ValueTable["R"] then
			if ValueTable["M"] == false then return end
			if RampIP then return end
			RampIP = true
			local t = TS:Create(script.Parent.Parent.RampM.HingeConstraint, TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {TargetAngle = 179})
			t:Play()
			t.Completed:Wait()
			--script.Parent.Parent.RampM.HingeConstraint.TargetAngle = "179"
			--task.wait(2)
			RampDash.SurfaceGui.Enabled = true
			RampIP = false
		else
			if RampIP then return end
			RampIP = true
			--script.Parent.Parent.RampM.HingeConstraint.TargetAngle = "0"
			local t = TS:Create(script.Parent.Parent.RampM.HingeConstraint, TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {TargetAngle = 0})
			t:Play()
			t.Completed:Wait()
			RampDash.SurfaceGui.Enabled = false
			RampIP = false
		end
	end,

	-- brake release
	W = function()
		if script.Parent.Parent.Horn.Velocity.Magnitude < 5 then
			script.Parent.Parent.SoundSystem.Horn.BrakeRelease:Play()
		elseif script.Parent.Parent.Horn.Velocity.Magnitude > 5 then
			script.Parent.Parent.SoundSystem.Horn.BrakeRelease:Stop()
		end
	end,

	-- front doors
	M = function()
		if FDoorIP then return end
		local FDLight = script.Parent.Parent.Lights.FrontDoor
		local FDash = script.Parent.Parent.HUD.DashLights.FrontDoor
		local RDoorWeld1 = script.Parent.Parent.Parent.Misc.FDoors.FD1.Base.MotorWeld
		local RDoorWeld2 = script.Parent.Parent.Parent.Misc.FDoors.FD2.Base.MotorWeld
		if RampIP == true then return end
		if (AirPressureSystemEnabled) and (UseAirPressureOnFrontDoor) and (script.Parent.AirPressure.Value < MinimumAirPressure) then
			ValueTable["M"] = not ValueTable["M"]
			return
		end
		if AirPressureSystemEnabled and UseAirPressureOnFrontDoor then
			if debugmode then print("Old air pressure = "..tostring(script.Parent.AirPressure.Value)) end
			script.Parent.AirPressure.Value = script.Parent.AirPressure.Value - DownIncrement
			print("New air pressure = "..tostring(script.Parent.AirPressure.Value))
		end
		if ValueTable["M"] == false then
			--door is closing
			if ValueTable["R"] == true then return end
			script.Parent.RDoor.Value = ValueTable["M"]
			FDoorIP = true
			script.Parent.Parent.SoundSystem.S1.FDC:Play()
			script.Parent.Parent.FMotor1.HingeConstraint.AngularSpeed = 1.3
			script.Parent.Parent.FMotor2.HingeConstraint.AngularSpeed = 1.3
			RDoorWeld1.Enabled = false
			RDoorWeld2.Enabled = false
			TS:Create(script.Parent.Parent.FMotor1.HingeConstraint, ValueTable["FDoorTIClose"], {TargetAngle = 0}):Play()
			TS:Create(script.Parent.Parent.FMotor2.HingeConstraint, ValueTable["FDoorTIClose"], {TargetAngle = 0}):Play()
			repeat game["Run Service"].Heartbeat:Wait() until script.Parent.Parent.FMotor2.HingeConstraint.CurrentAngle >= -0.5
			FDash.SurfaceGui.Enabled = false
			FDLight.FD.Material = Enum.Material.SmoothPlastic
			FDLight.FD.BrickColor = BrickColor.new("Smoky grey")
			FDLight.Int.Material = Enum.Material.SmoothPlastic
			RDoorWeld1.Enabled = true
			RDoorWeld2.Enabled = true
			for i,v in pairs(script.Parent.Parent.Parent.Misc.FDoors:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = true
				end
			end
			task.wait(0.5)
			FDoorIP = false
		else --if true
			--door is opening
			-- revert value back if angle is alr -90
			script.Parent.RDoor.Value = ValueTable["M"]
			FDoorIP = true
			script.Parent.Parent.SoundSystem.S1.FDO:Play()
			FDash.SurfaceGui.Enabled = true
			FDLight.FD.Material = Enum.Material.Neon
			FDLight.FD.BrickColor = BrickColor.new("Burlap")
			FDLight.Int.Material = Enum.Material.Neon
			for i,v in pairs(script.Parent.Parent.Parent.Misc.FDoors:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
			RDoorWeld1.Enabled = false
			RDoorWeld2.Enabled = false
			TS:Create(script.Parent.Parent.FMotor1.HingeConstraint, ValueTable["FDoorTIOpen"], {TargetAngle = -90}):Play()
			TS:Create(script.Parent.Parent.FMotor2.HingeConstraint, ValueTable["FDoorTIOpen"], {TargetAngle = -90}):Play()
			repeat game["Run Service"].Heartbeat:Wait() until script.Parent.Parent.FMotor2.HingeConstraint.CurrentAngle <= -89.5
			RDoorWeld1.Enabled = true
			RDoorWeld2.Enabled = true
			task.wait(0.5)
			FDoorIP = false
		end
	end,

	-- back door
	N = function()
		if RDoorIP then return end
		local RDash = script.Parent.Parent.HUD.DashLights.RearDoor
		local RDoorWeld1 = script.Parent.Parent.Parent.Misc.RDoors.RD1.Base.MotorWeld
		local RDoorWeld2 = script.Parent.Parent.Parent.Misc.RDoors.RD2.Base.MotorWeld
		if (AirPressureSystemEnabled == true) and (UseAirPressureOnRearDoor == true) and (script.Parent.AirPressure.Value < MinimumAirPressure) then
			ValueTable["N"] = not ValueTable["N"]
			return
		end
		RDoorIP = true
		if AirPressureSystemEnabled and UseAirPressureOnRearDoor then
			if debugmode then print("Old air pressure = "..tostring(script.Parent.AirPressure.Value)) end
			script.Parent.AirPressure.Value = script.Parent.AirPressure.Value - DownIncrement
			if debugmode then print("New air pressure = "..tostring(script.Parent.AirPressure.Value)) end
		end
		if ValueTable["N"] == false then
			--door is closed
			script.Parent.Parent.SoundSystem.S2.RDC:Play()
			if not script.Parent.RDoorUnlocked.Value then
				RDLights.Union.BrickColor = BrickColor.new("Really black")
				RDLights.Union.Material = Enum.Material.SmoothPlastic
			end
			RDoorWeld1.Enabled = false
			RDoorWeld2.Enabled = false
			for i,part in pairs(script.Parent.Parent.Parent.Misc.RDoors:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
			TS:Create(script.Parent.Parent.RMotor1.HingeConstraint, ValueTable["FDoorTIClose"], {TargetAngle = 0}):Play()
			TS:Create(script.Parent.Parent.RMotor2.HingeConstraint, ValueTable["FDoorTIClose"], {TargetAngle = 0}):Play()
			repeat game["Run Service"].Heartbeat:Wait() until script.Parent.Parent.RMotor2.HingeConstraint.CurrentAngle >= -0.5
			RDoorWeld1.Enabled = true
			RDoorWeld2.Enabled = true
			script.Parent.RDoor.Value = false
			RDash.SurfaceGui.Enabled = false
			for i,part in pairs(script.Parent.Parent.Parent.Misc.RDoors:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
			task.wait(0.5)
			RDoorIP = false
		else --if true
			--door is opend
			RDoorIP = true
			for i,part in pairs(script.Parent.Parent.Parent.Misc.RDoors:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
			script.Parent.Parent.SoundSystem.S2.RDO:Play()
			if not script.Parent.RDoorUnlocked.Value then
				RDLights.Union.BrickColor = BrickColor.new("Lime green")
				RDLights.Union.Material = Enum.Material.Neon
			end
			RDoorWeld1.Enabled = false
			RDoorWeld2.Enabled = false
			TS:Create(script.Parent.Parent.RMotor1.HingeConstraint, ValueTable["FDoorTIOpen"], {TargetAngle = -90}):Play()
			TS:Create(script.Parent.Parent.RMotor2.HingeConstraint, ValueTable["FDoorTIOpen"], {TargetAngle = -90}):Play()
			repeat game["Run Service"].Heartbeat:Wait() until script.Parent.Parent.RMotor2.HingeConstraint.CurrentAngle <= -89.5
			RDoorWeld1.Enabled = true
			RDoorWeld2.Enabled = true
			script.Parent.RDoor.Value = true
			RDash.SurfaceGui.Enabled = true
			for i,part in pairs(script.Parent.Parent.Parent.Misc.RDoors:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
			task.wait(0.5)
			RDoorIP = false
		end
	end,

	-- kneeling
	-- ONE THAT ADJUSTS 2 VALUES
	K = function()
		if KneelProtect and script.Parent.Parent.FMotor1.Velocity.Magnitude > 3 then
			ValueTable["K"] = not ValueTable["K"]
			return
		end
		local KneDash = script.Parent.Parent.HUD.DashLights.Kneel
		local KneelSounds = script.Parent.Parent.SoundSystem.S1
		local KneelLight = script.Parent.Parent.Lights.Kneel.Light

		local FRSC = script.Parent.Parent.Parent.Wheels.FR.Spring
		local RRSC = script.Parent.Parent.Parent.Wheels.RR.Spring

		local KneelAmount = 50
		local KneelIP = false
		if AirPressureSystemEnabled and UseAirPressureOnKneel then
			if debugmode then print("Old air pressure = "..tostring(script.Parent.AirPressure.Value)) end
			script.Parent.AirPressure.Value = script.Parent.AirPressure.Value - DownIncrement
			if debugmode then print("New air pressure = "..tostring(script.Parent.AirPressure.Value)) end
		end
		if ValueTable["K"] == true then
			KneDash.SurfaceGui.Enabled = true
			KneelIP = true
			local t = TS:Create(script.Parent.Parent.Parent.Wheels.FR.Spring, TweenInfo.new(3.25, Enum.EasingStyle.Linear), {MaxLength = FRSC.MaxLength - (KneelAmount * 0.015), MinLength = FRSC.MinLength - (KneelAmount * 0.015)})
			TS:Create(script.Parent.Parent.Parent.Wheels.RR.Spring, TweenInfo.new(3.25, Enum.EasingStyle.Linear), {MaxLength = RRSC.MaxLength - (KneelAmount * 0.015), MinLength = RRSC.MinLength - (KneelAmount * 0.015)}):Play()
			t:Play()
			KneelSounds.Kneel:Play()
			task.spawn(function()
				repeat
					if not KneelIP then break end
					KneelLight.BrickColor = BrickColor.new("New Yeller")
					KneelLight.Material = Enum.Material.Neon
					task.wait(0.35)
					if not KneelIP then break end
					KneelLight.BrickColor = BrickColor.new("CGA brown")
					KneelLight.Material = Enum.Material.SmoothPlastic
					task.wait(0.2)
				until not KneelIP
			end)
			t.Completed:Wait()
			if KeepKneelLightOn then
				KneelLight.Material = Enum.Material.Neon
				KneelLight.BrickColor = BrickColor.new("New Yeller")
			end
			KneelIP = false
		else
			KneDash.SurfaceGui.Enabled = false
			KneelIP = true
			local t = TS:Create(script.Parent.Parent.Parent.Wheels.FR.Spring, TweenInfo.new(3.25, Enum.EasingStyle.Linear), {MaxLength = FRSC.MaxLength + (KneelAmount * 0.015), MinLength = FRSC.MinLength + (KneelAmount * 0.015)})
			TS:Create(script.Parent.Parent.Parent.Wheels.RR.Spring, TweenInfo.new(3.25, Enum.EasingStyle.Linear), {MaxLength = RRSC.MaxLength + (KneelAmount * 0.015), MinLength = RRSC.MinLength + (KneelAmount * 0.015)}):Play()
			t:Play()
			KneelSounds.Unkneel:Play()
			local loop = true
			task.spawn(function()
				repeat
					if not KneelIP then break end
					KneelLight.BrickColor = BrickColor.new("New Yeller")
					KneelLight.Material = Enum.Material.Neon
					task.wait(0.35)
					if not KneelIP then break end
					KneelLight.BrickColor = BrickColor.new("CGA brown")
					KneelLight.Material = Enum.Material.SmoothPlastic
					task.wait(0.2)
				until not KneelIP
			end)
			t.Completed:Wait()
			KneelLight.BrickColor = BrickColor.new("CGA brown")
			KneelLight.Material = Enum.Material.SmoothPlastic
			KneelIP = false
		end
	end,

	-- pbrake
	P = function()
		local PBDash = script.Parent.Parent.HUD.DashLights.ParkingBrake
		if ValueTable["P"] == false then
			script.Parent.Parent.SoundSystem.EN1.POff:Play()
			PBDash.SurfaceGui.Enabled = false

		else
			script.Parent.Parent.SoundSystem.EN1.POn:Play()
			PBDash.SurfaceGui.Enabled = true
		end
	end,

	-- engine start
	Z = function()
		if debugmode then warn("Z called") end
		local EngDash = script.Parent.Parent.HUD.DashLights.EngDash
		if ValueTable["Z"] == false then
			if debugmode then warn("Z called - turning off") end
			ValueTable["Electrics"] = false
			script.Parent.Parent.SoundSystem.EN1.Idle.Volume = 0
			script.Parent.Parent.SoundSystem.EN1.Engine.Volume = 0
			ValueTable["Engine"] = false
			EngDash.SurfaceGui.Enabled = false
			script.Parent.Parent.SRSystem.Started.Value = false
			script.Parent.Parent.SRSystem.Screen.SurfaceGui.Enabled = false
			task.wait(0.1)
			script.Parent.Parent.SoundSystem.EN1.Hiss.Volume = 0
			script.Parent.Parent.Parent["A-Chassis Tune"]["A-Chassis Interface"].IsOn.Value = false
			if CurrentOccupant then
				if debugmode then warn("Occupant found") end
				CurrentOccupant.PlayerGui["A-Chassis Interface"].IsOn.Value = false

			elseif script.Parent.Parent.Parent.DriveSeat.Occupant then
				game.Players:GetPlayerFromCharacter(script.Parent.Parent.Parent.DriveSeat.Occupant.Parent).PlayerGui["A-Chassis Interface"].IsOn.Value = false
			end
			if UseSmoke then
				script.Parent.Parent.ExhaustEmitter.Smoke.Enabled = false
			end
			ServerOn = false
			if debugmode then warn("ServerOn should be false. ServerOn value: "..tostring(ServerOn)) end
		else --if true
			if debugmode then warn("Z called - turning on") end
			task.wait(2)
			script.Parent.Parent.SRSystem.Screen.SurfaceGui.Enabled = true
			script.Parent.Parent.SRSystem.Screen.SurfaceGui.TextLabel.StartScript.Enabled = true
			task.wait(8.5)
			script.Parent.Parent.SRSystem.Screen.SurfaceGui.TextLabel.StartScript.Enabled = false
			ValueTable["Engine"] = true
			task.wait(4)
			script.Parent.Parent.SoundSystem.EN1.Engine.Volume = 2.5
			script.Parent.Parent.SoundSystem.EN1.Idle.Volume = 2.5
			script.Parent.Parent.SoundSystem.EN1.Hiss.Volume = 4
			EngDash.SurfaceGui.Enabled = true
			script.Parent.Parent.Parent["A-Chassis Tune"]["A-Chassis Interface"].IsOn.Value = true
			if CurrentOccupant then
				if debugmode then warn("Occupant found") end
				CurrentOccupant.PlayerGui["A-Chassis Interface"].IsOn.Value = true

			elseif script.Parent.Parent.Parent.DriveSeat.Occupant then
				game.Players:GetPlayerFromCharacter(script.Parent.Parent.Parent.DriveSeat.Occupant.Parent).PlayerGui["A-Chassis Interface"].IsOn.Value = true
			end
			if UseSmoke then
				script.Parent.Parent.ExhaustEmitter.Smoke.Enabled = true
			end
			ServerOn = true
		end
	end,

	-- driver light (G)
	G = function()
		local DL = script.Parent.Parent.Lights.DriverLight
		if ValueTable["G"] == true then
			DL.Union.Material = Enum.Material.Neon
			DL.Union.BrickColor = BrickColor.new("Burlap")
			DL.Union.Light.Brightness = 0
			DL.Union.Light.Enabled = true
			TS:Create(DL.Union.Light, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Brightness = 8}):Play()
		else
			DL.Union.Material = Enum.Material.SmoothPlastic
			DL.Union.BrickColor = BrickColor.new("Dark stone grey")
			local t = TS:Create(DL.Union.Light, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Brightness = 0})
			t:Play()
			t.Completed:Wait()
			DL.Union.Light.Enabled = false
		end
	end,

	-- brake lights (S)
	S = function()
		local BL = script.Parent.Parent.Lights.Brakes:GetChildren()
		local BLD = script.Parent.Parent.HUD.DashLights.Brake
		if ValueTable["S"] == true then
			for i,part in pairs(BL) do
				part.BrickColor = BrickColor.new("Really red")
				part.Material = Enum.Material.Neon
			end
			BLD.SurfaceGui.Enabled = true
		else
			for i,part in pairs(BL) do
				part.BrickColor = BrickColor.new("Really black")
				part.Material = Enum.Material.SmoothPlastic
			end
			BLD.SurfaceGui.Enabled = false
		end
	end,

	-- headlight
	L = function()
		local HeadLi = script.Parent.Parent.Lights.LowBeams
		local HeaDash = script.Parent.Parent.HUD.DashLights.HeadLight
		if ValueTable["L"] == true then
			HeadLi.LL.Material = Enum.Material.Neon
			HeadLi.LL.BrickColor = BrickColor.new("Institutional white")
			HeadLi.LL.Light.Enabled = true
			HeaDash.SurfaceGui.Enabled = true
		else
			HeadLi.LL.Material = Enum.Material.SmoothPlastic
			HeadLi.LL.BrickColor = BrickColor.new("Dark stone grey")
			HeadLi.LL.Light.Enabled = false
			HeaDash.SurfaceGui.Enabled = false
		end
	end,

	-- high beams
	F = function()
		local HighLi = script.Parent.Parent.Lights.HighBeams
		local HighDash = script.Parent.Parent.HUD.DashLights.HighBeam
		if ValueTable["F"] == true then
			HighLi.HL.Material = Enum.Material.Neon
			HighLi.HL.BrickColor = BrickColor.new("Institutional white")
			HighLi.HL.Light.Enabled = true
			HighLi.TopLights.Material = Enum.Material.Neon
			HighDash.SurfaceGui.Enabled = true
		else
			HighLi.HL.Material = Enum.Material.SmoothPlastic
			HighLi.HL.BrickColor = BrickColor.new("Dark stone grey")
			HighLi.HL.Light.Enabled = false
			HighLi.TopLights.Material = Enum.Material.SmoothPlastic
			HighDash.SurfaceGui.Enabled = false
		end
	end,

	-- left blinker

	Q = function()
		local LeftSi = script.Parent.Parent.Lights.Left
		local LeftDash = script.Parent.Parent.HUD.DashLights.LeftSignal
		local LS1 = LeftSi.LightSet1:GetChildren()
		local LS2 = LeftSi.LightSet2:GetChildren()

		if LeftBlinker == false then -- enable left
			LeftBlinker = true
			RightBlinker = false
			Hazards = false
			repeat
				BlinkerSound:Play()
				for i,part:BasePart in pairs(LS1) do
					part.Material = Enum.Material.Neon
					part.BrickColor = BrickColor.new("Deep orange")
					if LS2[i] then
						LS2[i].Material = Enum.Material.Neon
					end
					LeftDash.SurfaceGui.Enabled = true
				end
				task.wait(0.5)
				for i,part:BasePart in pairs(LS1) do
					part.Material = Enum.Material.SmoothPlastic
					part.BrickColor = BrickColor.new("Reddish brown")
					if LS2[i] then
						LS2[i].Material = Enum.Material.SmoothPlastic
					end
					LeftDash.SurfaceGui.Enabled = false
				end
				task.wait(0.5)
			until LeftBlinker == false
		else
			LeftBlinker = false
			BlinkerSound:Stop()
			for i,part:BasePart in pairs(LS1) do
				part.Material = Enum.Material.SmoothPlastic
				part.BrickColor = BrickColor.new("Reddish brown")
				if LS2[i] then
					LS2[i].Material = Enum.Material.SmoothPlastic
				end
				LeftDash.SurfaceGui.Enabled = false
			end
		end
	end,

	-- right blinker
	E = function()
		local RightSi = script.Parent.Parent.Lights.Right
		local RightDash = script.Parent.Parent.HUD.DashLights.RightSignal
		local RS1 = RightSi.LightSet1:GetChildren()
		local RS2 = RightSi.LightSet2:GetChildren()

		if RightBlinker == false then -- enable right
			RightBlinker = true
			LeftBlinker = false
			Hazards = false
			repeat
				BlinkerSound:Play()
				for i,part:BasePart in pairs(RS1) do
					part.Material = Enum.Material.Neon
					part.BrickColor = BrickColor.new("Deep orange")
					if RS2[i] then
						RS2[i].Material = Enum.Material.Neon
					end
				end
				RightDash.SurfaceGui.Enabled = true
				task.wait(0.5)
				for i,part:BasePart in pairs(RS1) do
					part.Material = Enum.Material.SmoothPlastic
					part.BrickColor = BrickColor.new("Reddish brown")
					if RS2[i] then
						RS2[i].Material = Enum.Material.SmoothPlastic
					end
				end
				RightDash.SurfaceGui.Enabled = false
				task.wait(0.5)
			until RightBlinker == false
		else
			RightBlinker = false
			BlinkerSound:Stop()
			for i,part:BasePart in pairs(RS1) do
				part.Material = Enum.Material.SmoothPlastic
				part.BrickColor = BrickColor.new("Reddish brown")
				if RS2[i] then
					RS2[i].Material = Enum.Material.SmoothPlastic
				end
				RightDash.SurfaceGui.Enabled = false
			end
		end
	end,

	-- hazards
	X = function()
		if Hazards == false then
			LeftBlinker = false
			RightBlinker = false
			Hazards = true
			task.spawn(function()
				local RightSi = script.Parent.Parent.Lights.Right
				local RightDash = script.Parent.Parent.HUD.DashLights.RightSignal
				local RS1 = RightSi.LightSet1:GetChildren()
				local RS2 = RightSi.LightSet2:GetChildren()
				repeat
					for i,part:BasePart in pairs(RS1) do
						part.Material = Enum.Material.Neon
						part.BrickColor = BrickColor.new("Deep orange")
						if RS2[i] then
							RS2[i].Material = Enum.Material.Neon
						end
					end
					RightDash.SurfaceGui.Enabled = true
					task.wait(0.5)
					for i,part:BasePart in pairs(RS1) do
						part.Material = Enum.Material.SmoothPlastic
						part.BrickColor = BrickColor.new("Reddish brown")
						if RS2[i] then
							RS2[i].Material = Enum.Material.SmoothPlastic
						end
					end
					RightDash.SurfaceGui.Enabled = false
					task.wait(0.5)
				until Hazards == false
			end)
			task.spawn(function()
				local LeftSi = script.Parent.Parent.Lights.Left
				local LeftDash = script.Parent.Parent.HUD.DashLights.LeftSignal
				local LS1 = LeftSi.LightSet1:GetChildren()
				local LS2 = LeftSi.LightSet2:GetChildren()
				repeat
					BlinkerSound:Play()
					for i,part:BasePart in pairs(LS1) do
						part.Material = Enum.Material.Neon
						part.BrickColor = BrickColor.new("Deep orange")
						if LS2[i] then
							LS2[i].Material = Enum.Material.Neon
						end
						LeftDash.SurfaceGui.Enabled = true
					end
					task.wait(0.5)
					for i,part:BasePart in pairs(LS1) do
						part.Material = Enum.Material.SmoothPlastic
						part.BrickColor = BrickColor.new("Reddish brown")
						if LS2[i] then
							LS2[i].Material = Enum.Material.SmoothPlastic
						end
						LeftDash.SurfaceGui.Enabled = false
					end
					task.wait(0.5)
				until Hazards == false
			end)
		else
			Hazards = false
			BlinkerSound:Stop()
			task.spawn(function()
				local RightSi = script.Parent.Parent.Lights.Right
				local RightDash = script.Parent.Parent.HUD.DashLights.RightSignal
				local RS1 = RightSi.LightSet1:GetChildren()
				local RS2 = RightSi.LightSet2:GetChildren()
				for i,part:BasePart in pairs(RS1) do
					part.Material = Enum.Material.SmoothPlastic
					part.BrickColor = BrickColor.new("Reddish brown")
					if RS2[i] then
						RS2[i].Material = Enum.Material.SmoothPlastic
					end
					RightDash.SurfaceGui.Enabled = false
				end
			end)
			task.spawn(function()
				local LeftSi = script.Parent.Parent.Lights.Left
				local LeftDash = script.Parent.Parent.HUD.DashLights.LeftSignal
				local LS1 = LeftSi.LightSet1:GetChildren()
				local LS2 = LeftSi.LightSet2:GetChildren()
				for i,part:BasePart in pairs(LS1) do
					part.Material = Enum.Material.SmoothPlastic
					part.BrickColor = BrickColor.new("Reddish brown")
					if LS2[i] then
						LS2[i].Material = Enum.Material.SmoothPlastic
					end
					LeftDash.SurfaceGui.Enabled = false
				end
			end)
		end
	end,

	-- unlock rear

	B = function()
		script.Parent.RDoorUnlocked.Value = ValueTable["B"]
		RDLights.Union.BrickColor = ValueTable["B"] and BrickColor.new("Lime green") or BrickColor.new("Really black")
		RDLights.Union.Material = ValueTable["B"] and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end,

	C = function()
		local Engine = script.Parent.Parent.SoundSystem.EN1.Idle
		local HighDash = script.Parent.Parent.HUD.DashLights.Hidle.SurfaceGui
		if ValueTable["C"] == true then
			Engine.PlaybackSpeed = 1.4
			HighDash.Enabled = true
		else
			Engine.PlaybackSpeed = 1
			HighDash.Enabled = false
		end
	end,
	-- custom interior functions
	InL = function()
		local IL = script.Parent.Parent.Lights.LeftInterior
		local ILD = script.Parent.Parent.HUD.DashLights.Interiors
		if ValueTable["INL"] == true then
			IL.Bulb.Material = Enum.Material.Neon
			IL.Bulb.BrickColor = BrickColor.new("Institutional white")
			IL.Bulb.Light.Enabled = true
			ILD.SurfaceGui.Enabled = true
		else
			IL.Bulb.Material = Enum.Material.SmoothPlastic
			IL.Bulb.BrickColor = BrickColor.new("Fossil")
			IL.Bulb.Light.Enabled = false
			ILD.SurfaceGui.Enabled = false
		end
	end,

	InR = function()
		local IR = script.Parent.Parent.Lights.RightInterior
		if ValueTable["INR"] then
			IR.Bulb.Material = Enum.Material.Neon
			IR.Bulb.BrickColor = BrickColor.new("Institutional white")
			IR.Bulb.Light.Enabled = true
		else
			IR.Bulb.Material = Enum.Material.SmoothPlastic
			IR.Bulb.BrickColor = BrickColor.new("Fossil")
			IR.Bulb.Light.Enabled = false
		end
	end,
}

for i,CustomFunction in pairs(CustomFunctions) do
	if FunctionTable[i] then
		if debugmode then warn("Found custom function that needs to over-write default function. Function key: "..i) end
		FunctionTable[i] = CustomFunction
	else
		if debugmode then warn("Found custom function that doesn't need to overwrite. Adding custom function: "..i) end
		FunctionTable[i] = CustomFunction
	end
end

InputBegan.OnServerEvent:Connect(function(player, key)
	if key == "M" and FDoorIP then return end
	if key == "N" and RDoorIP then return end
	if key == "R" and RampIP then return end
	if (ValueTable[key]) then
		ValueTable[key] = not ValueTable[key]
	else
		ValueTable[key] = true
	end
	if key == "L" then
		if ValueTable["LichtNum"] == 0 then
			ValueTable["LichtNum"] = 1
			ValueTable["L"] = true
			FunctionTable["L"]()
		elseif ValueTable["LichtNum"] == 1 then
			ValueTable["LichtNum"] = 2
			ValueTable["L"] = true
			FunctionTable["L"]()
		elseif ValueTable["LichtNum"] == 2 then
			ValueTable["LichtNum"] = 3
			ValueTable["F"] = true
			FunctionTable["F"]()
		elseif ValueTable["LichtNum"] == 3 then
			ValueTable["LichtNum"] = 1
			ValueTable["L"] = false
			ValueTable["F"] = false
			FunctionTable["F"]()
			FunctionTable["L"]()
		end
	elseif key == "J" then
		if ValueTable["LichtNum"] == 0 then
			ValueTable["LichtNum"] = 1
			ValueTable["INL"] = true
			FunctionTable["InL"]()
		elseif ValueTable["LichtNum"] == 1 then
			ValueTable["LichtNum"] = 2
			ValueTable["INL"] = true
			FunctionTable["InL"]()
		elseif ValueTable["LichtNum"] == 2 then
			ValueTable["LichtNum"] = 3
			ValueTable["INR"] = true
			FunctionTable["InR"]()
		elseif ValueTable["LichtNum"] == 3 then
			ValueTable["LichtNum"] = 1
			ValueTable["INL"] = false
			ValueTable["INR"] = false
			FunctionTable["InL"]()
			FunctionTable["InR"]()

		end
	end
	if FunctionTable[key] and key ~= "L" and key ~= "J" then
		FunctionTable[key]()
	end
end)


InputEnded.OnServerEvent:Connect(function(player, key)
	if key == "H" or key == "S" then
		ValueTable[key] = false
		if FunctionTable[key] then
			FunctionTable[key]()
		end
	end
end)

if AirPressureSystemEnabled then
	game["Run Service"].Heartbeat:Connect(function()
		if script.Parent.IsOn.Value then
			if script.Parent.AirPressure.Value < MaxPressure then
				script.Parent.AirPressure.Value  = script.Parent.AirPressure.Value + Increment
			end
		end
	end)
end

-- general rear door unlock functionality

for i,doorPart in pairs(script.Parent.Parent.Parent.Misc.RDoors:GetDescendants()) do
	if doorPart:IsA("BasePart") then
		local c = Instance.new("ObjectValue")
		c.Name = "HighlightRedirect"
		c.Value = script.Parent.Parent.Parent.Misc.RDoors
		c.Parent = doorPart
		local n = Instance.new("ClickDetector")
		n.MaxActivationDistance = 10
		n.Parent = doorPart
		n.MouseClick:Connect(function()
			if RDoorIP then return end
			if ValueTable["B"] then -- if rear door is unlocked
				RDoorT = Timer
				local o = ValueTable["N"]
				ValueTable["N"] = true
				FunctionTable["N"]()
				ValueTable["N"] = o
				o = nil
			end
		end)
		if debugmode then print("setup rear door HighlightRedirect #"..tostring(i)) end
	end
end


task.spawn(function()
	while task.wait(0.25) do
		if RDoorT > 0 then
			RDoorT = RDoorT - 0.25
		elseif RDoorT == 0 then
			if script.Parent.RDoor.Value == true and script.Parent.RDoorUnlocked.Value == true then
				if AirPressureSystemEnabled and script.Parent.AirPressure.Value <= 2 then
					repeat task.wait() until script.Parent.AirPressure.Value >= 2
				end
				local o = ValueTable["N"]
				ValueTable["N"] = false
				FunctionTable["N"]()
				ValueTable["N"] = o
				o = nil
			end
		end
	end
end)


-- open front doors at spawn


script.Parent.BusStatusChange.OnServerEvent:Connect(function(player, valueName, value)
	if script.Parent:FindFirstChild(valueName) then
		script.Parent[valueName].Value = value
	end
	if valueName == "Gear" then
		if value == 0 then
			GearboxGui.Text = "N"
		elseif value == -1 then
			GearboxGui.Text = "R"
		elseif value >= 1 then
			GearboxGui.Text = "D"..value
		end
	elseif valueName == "PBrake" then
		ValueTable["P"] = value
		FunctionTable["P"]()
	elseif valueName == "RPM" and script.Parent.Parent.Parent["A-Chassis Tune"]["A-Chassis Interface"].IsOn.Value and UseSmoke then
		Smoke.Size = value/1000+tonumber(Throttle and 5 or 0)
		Smoke.TimeScale = value/1000

	elseif valueName == "Throttle" and value == 1 then
		Throttle = true
	elseif ValueTable == "Throttle" and value == 0 then
		Throttle = false
	end
end)



if busconfig.General.HighlightsEnabled then
	
	game.Players.PlayerAdded:Connect(function(playr)
		if not playr.Character then playr.CharacterAdded:Wait() end
		local c = script:WaitForChild("HighlightScript"):Clone()
		c.Enabled = true
		local g = Instance.new("ScreenGui")
		g.Name = "HighlightGuiContainer"
		g.Parent = playr.PlayerGui
		c.Parent = g
		g.Enabled = true
		local h = script.HoverGui:Clone()
		h.Parent = playr.PlayerGui
	end)
	for i,playr in pairs(game.Players:GetPlayers()) do
		if not playr.Character then playr.CharacterAdded:Wait() end
		if playr.PlayerGui:FindFirstChild("HighlightGuiContainer") == nil then
			local c = script:WaitForChild("HighlightScript"):Clone()
			c.Enabled = true
			local g = Instance.new("ScreenGui")
			g.Name = "HighlightGuiContainer"
			g.Parent = playr.PlayerGui
			c.Parent = g
			g.Enabled = true
			local h = script.HoverGui:Clone()
			h.Parent = playr.PlayerGui
		end
	end
end



if busconfig.Doors.OpenFrontDoorsAtSpawn then
	task.spawn(function()
		task.wait(2)
		ValueTable["M"] = true
		FunctionTable["M"]()
	end)
end

-- assign fleet function

if busconfig.FleetGeneration.FleetGenEnabled then
	local NumbersFolder = script.Parent.Parent.FleetNumbers
	local lower = busconfig.FleetGeneration.LowestPossibleFleet
	local higher = busconfig.FleetGeneration.HighestPossibleFleet

	if not busconfig.FleetGeneration.PreventDuplicateFleet then -- if prevent system is disabled
		local fleet = tostring(math.random(lower, higher))

		for i,FleetNumber in pairs(NumbersFolder:GetChildren()) do
			if FleetNumber.Name == "FleetNo" and FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel") then -- if it's a fleet number thing
				FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel").Text = fleet
			end
		end

	else -- prevent

		local UnUsedFleets = {}

		for i=lower,higher do
			if workspace:FindFirstChild(i) == nil then
				table.insert(UnUsedFleets, i)
			end
		end

		if #UnUsedFleets >= 1 then
			local fleet = UnUsedFleets[math.random(1, #UnUsedFleets)]
			for i,FleetNumber in pairs(NumbersFolder:GetChildren()) do
				if FleetNumber.Name == "FleetNo" and FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel") then -- if it's a fleet number thing
					FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel").Text = fleet
				end
			end

		else -- no fleets available

			if busconfig.FleetGeneration.Behaviour == "DontAssign" then return end
			if busconfig.FleetGeneration.Behaviour == "AssignRandom" then
				local fleet = tostring(math.random(lower, higher))

				for i,FleetNumber in pairs(NumbersFolder:GetChildren()) do
					if FleetNumber.Name == "FleetNo" and FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel") then -- if it's a fleet number thing
						FleetNumber:FindFirstChildWhichIsA("SurfaceGui"):FindFirstChildWhichIsA("TextLabel").Text = fleet
					end
				end
			end
			if busconfig.FleetGeneration.Behaviour == "RemoveBus" then
				warn("All fleets are taken, and behaviour is to destroy bus. Destroying!")
				task.wait(0.5)
				script.Parent.Parent.Parent.Parent:Destroy()
			end

		end
	end
end

script.Parent.Parent.Parent.DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	if debugmode then warn("SERVER - OCCUPANT CHANGE") end
	if debugmode then warn(script.Parent.Parent.Parent.DriveSeat.Occupant) end
	task.wait()
	if script.Parent.Parent.Parent.DriveSeat.Occupant ~= nil then
		local player = game.Players:GetPlayerFromCharacter(script.Parent.Parent.Parent.DriveSeat.Occupant.Parent)
		CurrentOccupant = player
		if debugmode then warn("SERVER - GOT PLAYER") end
		if debugmode then warn("Is bus on? "..tostring(ServerOn)) end
		if ServerOn then
			if debugmode then warn("Bus seems to be on. Starting it up.") end
			script.Parent.Parent.Parent["A-Chassis Tune"]["A-Chassis Interface"].IsOn.Value = true
			if debugmode then warn("SERVER - REQUESTED FOR CLIENT TO STARTUP") end
		end
	end
end)

warn("NextWave Chassis v2.0 has successfully started up on bus "..script.Parent.Parent.Parent.Parent.Name..". Enjoy ;D")
