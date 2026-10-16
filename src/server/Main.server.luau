local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Config = require(RS:WaitForChild("Baki"):WaitForChild("Config"))
require(script.Parent.World).Build()

local remote = Instance.new("RemoteEvent")
remote.Name, remote.Parent = "Combat", RS.Baki
local states, enemies = {}, {}
local enemyFolder = Instance.new("Folder")
enemyFolder.Name, enemyFolder.Parent = "Opponents", workspace
local function live(model)
	if not model then return end
	local hum, hrp = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	if hum and hrp and hum.Health > 0 then return hum, hrp end
end
local function message(player, text)
	remote:FireClient(player, "Notice", text)
end
local function impact(position, finisher)
	remote:FireAllClients("Impact", position, finisher)
end
local function reward(player, amount)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Strength.Value += amount
		stats.KOs.Value += 1
		local s = states[player]
		if s and not s.questDone and stats.KOs.Value >= 3 then
			s.questDone = true
			stats.Strength.Value += 100
			message(player, "FIRST BLOOD COMPLETE / +100 STRENGTH")
		else message(player, "+" .. amount .. " STRENGTH / DEFEAT 3 OPPONENTS FOR A BONUS") end
	end
end
local function makeEnemy(def)
	-- A local, asset-free R6 rig avoids HTTP/avatar asset dependencies.
	local model = Instance.new("Model")
	model.Name = def.Name
	local function body(name, size, offset, color, transparent)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, CFrame.new(def.Position + offset)
		p.Color, p.CanCollide = color, name == "Torso"
		p.Transparency = transparent and 1 or 0
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local skin = Color3.fromRGB(189, 142, 111)
	local hrp = body("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero, skin, true)
	local torso = body("Torso", Vector3.new(2, 2, 1), Vector3.zero, def.Color)
	local head = body("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0), skin)
	local left = body("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0), skin)
	local right = body("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0), skin)
	local ll = body("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0), def.Color)
	local rl = body("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0), def.Color)
	local function joint(name, a, b, c0, c1)
		local m = Instance.new("Motor6D")
		m.Name, m.Part0, m.Part1, m.C0, m.C1, m.Parent = name, a, b, c0, c1, a
	end
	joint("RootJoint", hrp, torso, CFrame.new(), CFrame.new())
	joint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	joint("Left Shoulder", torso, left, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	joint("Right Shoulder", torso, right, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	joint("Left Hip", torso, ll, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	joint("Right Hip", torso, rl, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
	local hum = Instance.new("Humanoid")
	hum.MaxHealth, hum.Health, hum.WalkSpeed, hum.HipHeight = def.Health, def.Health, 12, 0
	hum.DisplayName, hum.Parent = def.Name, model
	model.PrimaryPart, model.Parent = hrp, enemyFolder
	hrp:SetNetworkOwner(nil)
	local state = { model = model, def = def, home = def.Position, lastAttack = 0 }
	enemies[model] = state
	hum.Died:Connect(function()
		enemies[model] = nil
		if state.lastHitter and states[state.lastHitter] and os.clock() - (state.hitAt or 0) < 15 then reward(state.lastHitter, def.Reward) end
		Debris:AddItem(model, 4)
		task.delay(10, function() makeEnemy(def) end)
	end)
	return model
end
for _, def in Config.Enemies do makeEnemy(def) end

local function addPlayer(player)
	states[player] = { stamina = 100, lastAttack = 0, lastDash = 0, combo = 0, block = false, lastRemote = 0 }
	local stats = Instance.new("Folder")
	stats.Name, stats.Parent = "leaderstats", player
	for _, name in {"Strength", "KOs"} do local v = Instance.new("IntValue"); v.Name, v.Parent = name, stats end
	local function spawnCharacter(char)
		local hum = char:WaitForChild("Humanoid")
		local s = states[player]
		if not s then return end
		s.stamina, s.block, s.combo = Config.MaxStamina, false, 0
		hum.WalkSpeed = Config.WalkSpeed
		player:SetAttribute("Stamina", s.stamina)
		player:SetAttribute("Blocking", false)
		hum.Died:Connect(function() s.block = false; player:SetAttribute("Blocking", false) end)
	end
	player.CharacterAdded:Connect(spawnCharacter)
	if player.Character then task.spawn(spawnCharacter, player.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
for _, p in Players:GetPlayers() do addPlayer(p) end
Players.PlayerRemoving:Connect(function(player) states[player] = nil end)

for _, bag in workspace.BakiWorld:GetDescendants() do
	if bag:GetAttribute("TrainingBag") then
		bag.ProximityPrompt.Triggered:Connect(function(player)
			local s = states[player]
			local hum, hrp = live(player.Character)
			local now = os.clock()
			if not s or not hum or (hrp.Position - bag.Position).Magnitude > 12 then return end
			if now - (s.lastTrain or 0) < 1.3 or s.stamina < 10 then return end
			s.lastTrain, s.stamina = now, s.stamina - 10
			player.leaderstats.Strength.Value += 1
			remote:FireAllClients("Swing", player.Character, 1)
			impact(bag.Position, false)
			message(player, "IRON BODY TRAINING / +1 STRENGTH")
		end)
	end
end

remote.OnServerEvent:Connect(function(player, action, flag)
	local s = states[player]
	local hum, hrp = live(player.Character)
	if not s or not hum then return end
	local now = os.clock()
	-- The client sends intent only. Timing, target, damage and rewards live here.
	-- Always accept guard release, including taps shorter than the rate limit.
	if action == "Block" and flag == false then
		s.block = false
		player:SetAttribute("Blocking", false)
		hum.WalkSpeed = Config.WalkSpeed
		return
	end
	if action ~= "Attack" and action ~= "Dash" and action ~= "Block" then return end
	if now - s.lastRemote < 0.045 then return end
	s.lastRemote = now
	if action == "Block" and typeof(flag) == "boolean" then
		s.block = flag and s.stamina > 5
		player:SetAttribute("Blocking", s.block)
		hum.WalkSpeed = s.block and Config.BlockSpeed or Config.WalkSpeed
	elseif action == "Dash" then
		if now - s.lastDash < 1.2 or s.stamina < Config.DashCost or s.block then return end
		s.lastDash, s.stamina = now, s.stamina - Config.DashCost
		local dir = hum.MoveDirection
		if dir.Magnitude < 0.1 then dir = hrp.CFrame.LookVector end
		local attachment = Instance.new("Attachment", hrp)
		local velocity = Instance.new("LinearVelocity")
		velocity.Attachment0, velocity.MaxForce = attachment, 45000
		velocity.VectorVelocity, velocity.Parent = dir * Config.DashSpeed, hrp
		Debris:AddItem(velocity, Config.DashDuration)
		Debris:AddItem(attachment, Config.DashDuration)
		remote:FireClient(player, "Dash")
	elseif action == "Attack" then
		if now - s.lastAttack < Config.AttackCooldown or s.stamina < Config.AttackCost or s.block then return end
		s.combo = now - s.lastAttack < Config.ComboWindow and s.combo % 4 + 1 or 1
		s.lastAttack, s.stamina = now, s.stamina - Config.AttackCost
		remote:FireAllClients("Swing", player.Character, s.combo)
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {player.Character}
		local hit = {}
		for _, p in workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, 0, -4), Vector3.new(6, 6, 7), params) do
			local model = p:FindFirstAncestorOfClass("Model")
			local targetHum, targetRoot = live(model)
			if not model or hit[model] or not targetHum or (targetRoot.Position - hrp.Position).Magnitude > Config.AttackRange then continue end
			if not enemies[model] and not Players:GetPlayerFromCharacter(model) then continue end
			local ray = RaycastParams.new()
			ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {player.Character, model}
			if workspace:Raycast(hrp.Position, targetRoot.Position - hrp.Position, ray) then continue end
			hit[model] = true
			local damage = Config.Damage[s.combo]
			local targetPlayer = Players:GetPlayerFromCharacter(model)
			local ts = targetPlayer and states[targetPlayer]
			if ts and ts.block and targetRoot.CFrame.LookVector:Dot((hrp.Position - targetRoot.Position).Unit) > 0 then
				damage *= 0.2
				ts.stamina = math.max(0, ts.stamina - 12)
			end
			if enemies[model] then enemies[model].lastHitter, enemies[model].hitAt = player, now end
			targetHum:TakeDamage(damage)
			impact(targetRoot.Position, s.combo == 4)
			if s.combo == 4 then targetRoot:ApplyImpulse((hrp.CFrame.LookVector * 28 + Vector3.new(0, 9, 0)) * targetRoot.AssemblyMass) end
		end
	end
	player:SetAttribute("Stamina", s.stamina)
end)

local tickTime = 0
RunService.Heartbeat:Connect(function(dt)
	tickTime += dt
	if tickTime < 0.15 then return end
	local step = math.min(tickTime, 0.5)
	tickTime = 0
	local now = os.clock()
	for player, s in states do
		local hum = live(player.Character)
		if hum then
			s.stamina = math.clamp(s.stamina + (s.block and -7 or Config.StaminaRegen) * step, 0, Config.MaxStamina)
			if s.stamina <= 0 and s.block then s.block = false; hum.WalkSpeed = Config.WalkSpeed; player:SetAttribute("Blocking", false) end
			player:SetAttribute("Stamina", math.floor(s.stamina))
		end
	end
	for model, enemy in enemies do
		local hum, hrp = live(model)
		if not hum then continue end
		local nearest, distance = nil, 26
		for player in states do
			local ph, pr = live(player.Character)
			if ph and (pr.Position - enemy.home).Magnitude < 38 then
				local d = (pr.Position - hrp.Position).Magnitude
				if d < distance then nearest, distance = player, d end
			end
		end
		if nearest then
			local ph, pr = live(nearest.Character)
			hum:MoveTo(pr.Position)
			if distance < 5.5 and now - enemy.lastAttack > 1.25 then
				enemy.lastAttack = now
				remote:FireAllClients("Swing", model, 1)
				-- Windup gives players time to block or leave the attack range.
				task.delay(0.25, function()
					local eh, er = live(model)
					local th, tr = live(nearest.Character)
					if not eh or not th or (tr.Position - er.Position).Magnitude > 6 then return end
					local ray = RaycastParams.new()
					ray.FilterType, ray.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {model, nearest.Character}
					if workspace:Raycast(er.Position, tr.Position - er.Position, ray) then return end
					local ps = states[nearest]
					local block = ps and ps.block and tr.CFrame.LookVector:Dot((er.Position - tr.Position).Unit) > 0
					th:TakeDamage(enemy.def.Damage * (block and 0.2 or 1))
					if block then ps.stamina = math.max(0, ps.stamina - 10) end
					impact(tr.Position, false)
				end)
			end
		else hum:MoveTo(enemy.home) end
	end
end)
