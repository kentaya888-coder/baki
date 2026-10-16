local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("Baki"):WaitForChild("Config"))
local remote = RS.Baki:WaitForChild("Combat")
local gold, red = Color3.fromRGB(239, 190, 112), Color3.fromRGB(230, 64, 73)
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "BakiHUD", false, false
gui.Parent = player:WaitForChild("PlayerGui")
local function label(parent, text, size, pos, color, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency, t.Text, t.Size, t.Position = 1, text, size, pos
	t.Font, t.TextSize, t.TextColor3 = font or Enum.Font.GothamBold, 14, color or Color3.new(1, 1, 1)
	t.TextXAlignment, t.Parent = Enum.TextXAlignment.Left, parent
	return t
end
local panel = Instance.new("Frame")
panel.Size, panel.Position = UDim2.new(0.42, 0, 0, 182), UDim2.new(0, 18, 1, -200)
panel.BackgroundColor3, panel.BackgroundTransparency, panel.BorderSizePixel = Color3.fromRGB(12, 14, 20), 0.12, 0
panel.Parent = gui
local constraint = Instance.new("UISizeConstraint", panel)
constraint.MaxSize, constraint.MinSize = Vector2.new(410, 182), Vector2.new(205, 182)
local corner = Instance.new("UICorner", panel)
corner.CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", panel)
stroke.Color, stroke.Transparency = gold, 0.6
label(panel, "BAKI / UNDERGROUND", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 10), gold).TextSize = 18
local district = label(panel, "COMBAT DISTRICT", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(14, 37), Color3.fromRGB(148, 157, 176))
local function bar(name, y, color)
	local bg = Instance.new("Frame")
	bg.BackgroundColor3, bg.BorderSizePixel = Color3.fromRGB(38, 41, 51), 0
	bg.Size, bg.Position, bg.Parent = UDim2.new(1, -28, 0, 9), UDim2.fromOffset(14, y + 20), panel
	local fill = Instance.new("Frame")
	fill.BackgroundColor3, fill.BorderSizePixel, fill.Size, fill.Parent = color, 0, UDim2.fromScale(1, 1), bg
	local txt = label(panel, name, UDim2.new(1, -28, 0, 18), UDim2.fromOffset(14, y), Color3.fromRGB(203, 208, 220))
	return fill, txt
end
local hp, hpText = bar("HEALTH", 60, red)
local stamina, staminaText = bar("STAMINA", 99, gold)
local stats = label(panel, "STRENGTH 0  /  KOs 0", UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 147), gold)
local mission = label(gui, "FIRST BLOOD / DEFEAT 3 OPPONENTS / BONUS +100", UDim2.new(0.92, 0, 0, 28), UDim2.new(0.04, 0, 0, 12), gold)
mission.TextXAlignment, mission.TextScaled = Enum.TextXAlignment.Center, true
local limit = Instance.new("UITextSizeConstraint", mission)
limit.MaxTextSize = 16
local notice = label(gui, "WELCOME / TRAIN. FIGHT. BECOME THE STRONGEST.", UDim2.new(0.92, 0, 0, 30), UDim2.new(0.04, 0, 0, 48), Color3.new(1, 1, 1))
notice.TextXAlignment, notice.TextScaled = Enum.TextXAlignment.Center, true
local noticeLimit = Instance.new("UITextSizeConstraint", notice)
noticeLimit.MaxTextSize = 15
local hint = label(gui, "LMB / X  PUNCH     F / L2  BLOCK     Q / B  DASH", UDim2.new(0.94, 0, 0, 22), UDim2.new(0.03, 0, 1, -28), Color3.fromRGB(170, 177, 194))
hint.TextXAlignment, hint.TextScaled = Enum.TextXAlignment.Center, true
local hintLimit = Instance.new("UITextSizeConstraint", hint)
hintLimit.MaxTextSize = 13

local holdingAttack = false
local function action(name, state)
	if name == "BakiPunch" then
		if state == Enum.UserInputState.Begin then
			if not holdingAttack then
				holdingAttack = true
				task.spawn(function()
					while holdingAttack do remote:FireServer("Attack"); task.wait(Config.AttackCooldown + 0.025) end
				end)
			end
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then holdingAttack = false end
	elseif name == "BakiBlock" then
		if state == Enum.UserInputState.Begin then remote:FireServer("Block", true)
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then remote:FireServer("Block", false) end
	elseif name == "BakiDash" and state == Enum.UserInputState.Begin then remote:FireServer("Dash") end
	return Enum.ContextActionResult.Sink
end
CAS:BindAction("BakiPunch", action, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX)
CAS:BindAction("BakiBlock", action, true, Enum.KeyCode.F, Enum.KeyCode.ButtonL2)
CAS:BindAction("BakiDash", action, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
for _, entry in {{"BakiPunch", "PUNCH", UDim2.new(1, -100, 1, -195)}, {"BakiBlock", "BLOCK", UDim2.new(1, -185, 1, -130)}, {"BakiDash", "DASH", UDim2.new(1, -100, 1, -275)}} do
	CAS:SetTitle(entry[1], entry[2])
	CAS:SetPosition(entry[1], entry[3])
end

local function refreshStamina()
	local value = player:GetAttribute("Stamina") or Config.MaxStamina
	stamina.Size = UDim2.fromScale(value / Config.MaxStamina, 1)
	staminaText.Text = (player:GetAttribute("Blocking") and "GUARD" or "STAMINA") .. " / " .. math.floor(value)
end
player:GetAttributeChangedSignal("Stamina"):Connect(refreshStamina)
player:GetAttributeChangedSignal("Blocking"):Connect(refreshStamina)
local function onCharacter(char)
	holdingAttack = false
	local hum = char:WaitForChild("Humanoid")
	local function health()
		hp.Size = UDim2.fromScale(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 1)
		hpText.Text = "HEALTH / " .. math.ceil(hum.Health)
	end
	hum.HealthChanged:Connect(health)
	hum.Died:Connect(function() holdingAttack = false end)
	health()
	refreshStamina()
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter, player.Character) end
task.spawn(function()
	local ls = player:WaitForChild("leaderstats")
	local strength, kos = ls:WaitForChild("Strength"), ls:WaitForChild("KOs")
	local function refresh()
		stats.Text = "STRENGTH " .. strength.Value .. "  /  KOs " .. kos.Value
		mission.Text = kos.Value >= 3 and "FIRST BLOOD COMPLETE / CHALLENGE THE ARENA CHAMPION" or "FIRST BLOOD / " .. kos.Value .. "/3 OPPONENTS / BONUS +100"
	end
	strength.Changed:Connect(refresh)
	kos.Changed:Connect(refresh)
	refresh()
end)

local noticeId = 0
local activeSwings = setmetatable({}, {__mode = "k"})
remote.OnClientEvent:Connect(function(event, a, b)
	if event == "Notice" then
		noticeId += 1
		local current = noticeId
		notice.Text, notice.TextTransparency = a, 0
		task.delay(5, function() if current == noticeId then TweenService:Create(notice, TweenInfo.new(1), {TextTransparency = 1}):Play() end end)
	elseif event == "Swing" then
		if typeof(a) ~= "Instance" or not a.Parent then return end
		local torso = a:FindFirstChild("UpperTorso") or a:FindFirstChild("Torso")
		if not torso then return end
		local shoulder = torso:FindFirstChild(b % 2 == 0 and "Left Shoulder" or "Right Shoulder")
		if not shoulder then
			local arm = a:FindFirstChild(b % 2 == 0 and "LeftUpperArm" or "RightUpperArm")
			shoulder = arm and arm:FindFirstChild(b % 2 == 0 and "LeftShoulder" or "RightShoulder")
		end
		if shoulder and shoulder:IsA("Motor6D") and not activeSwings[shoulder] then
			local original = shoulder.C0
			activeSwings[shoulder] = true
			TweenService:Create(shoulder, TweenInfo.new(0.09), {C0 = original * CFrame.Angles(math.rad(-100), 0, math.rad(b % 2 == 0 and -15 or 15))}):Play()
			task.delay(0.12, function()
				if shoulder.Parent then TweenService:Create(shoulder, TweenInfo.new(0.16), {C0 = original}):Play() end
				task.delay(0.17, function() activeSwings[shoulder] = nil end)
			end)
		end
	elseif event == "Impact" then
		if typeof(a) ~= "Vector3" then return end
		local p = Instance.new("Part")
		p.Name, p.Shape, p.Material = "Hit flash", Enum.PartType.Ball, Enum.Material.Neon
		p.Color, p.Size, p.CFrame = b and red or gold, Vector3.one * 0.5, CFrame.new(a)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Parent = workspace
		TweenService:Create(p, TweenInfo.new(0.2), {Size = Vector3.one * (b and 6 or 3), Transparency = 1}):Play()
		Debris:AddItem(p, 0.25)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - a).Magnitude < 10 then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				local offset = Vector3.new(b and 0.3 or 0.12, 0, 0)
				hum.CameraOffset = offset
				TweenService:Create(hum, TweenInfo.new(0.16), {CameraOffset = Vector3.zero}):Play()
			end
		end
	elseif event == "Dash" then
		local camera = workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.09), {FieldOfView = 80}):Play()
			task.delay(0.18, function() TweenService:Create(camera, TweenInfo.new(0.2), {FieldOfView = 70}):Play() end)
		end
	end
end)
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.3 then return end
	elapsed = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local p = root.Position
		district.Text = p.Y < -8 and "03 / THE UNDERGROUND" or (p.X > 45 and math.abs(p.Z + 8) < 35 and "02 / IRON WILL DOJO" or (p.X < -20 and p.Z < -12 and "TRAINING PARK" or "01 / COMBAT DISTRICT"))
	end
end)
