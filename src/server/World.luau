local Lighting = game:GetService("Lighting")
local World = {}
local root
local C = {
	asphalt = Color3.fromRGB(29, 32, 39), concrete = Color3.fromRGB(67, 68, 73),
	black = Color3.fromRGB(15, 17, 23), red = Color3.fromRGB(235, 54, 62),
	gold = Color3.fromRGB(240, 186, 95), blue = Color3.fromRGB(76, 196, 235),
}
local function part(name, size, pos, color, material, parent)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, pos
	p.Anchored = true
	p.Color, p.Material = color or C.concrete, material or Enum.Material.Concrete
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent or root
	return p
end
local function sign(text, size, pos, color)
	local p = part("Sign", size, pos, C.black, Enum.Material.Metal)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.PixelsPerStud = Enum.NormalId.Front, 32
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.Parent = p
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	t.Font, t.TextScaled, t.Text = Enum.Font.GothamBlack, true, text
	t.TextColor3 = color or C.gold
	t.Parent = gui
	local back = gui:Clone()
	back.Face, back.Parent = Enum.NormalId.Back, p
	return p
end
local function light(pos, color, brightness, reach)
	local p = part("Light", Vector3.new(0.6, 0.6, 0.6), pos, color, Enum.Material.Neon)
	p.CanCollide = false
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = color, brightness or 1.5, reach or 28, true
	l.Parent = p
end
local function cylinder(name, radius, height, pos, color, material)
	local p = part(name, Vector3.new(height, radius * 2, radius * 2), pos, color, material)
	p.Shape, p.Orientation = Enum.PartType.Cylinder, Vector3.new(0, 0, 90)
	return p
end
local function portal(name, pos, target, color)
	local p = part(name, Vector3.new(9, 0.25, 9), pos, color, Enum.Material.Neon)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "Travel", name, 0.25
	prompt.MaxActivationDistance = 12
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char:PivotTo(CFrame.new(target))
		end
	end)
	sign(name, Vector3.new(14, 3, 0.5), pos + Vector3.new(0, 5, -5), color)
end
function World.Build()
	local old = workspace:FindFirstChild("BakiWorld")
	if old then old:Destroy() end
	root = Instance.new("Folder")
	root.Name, root.Parent = "BakiWorld", workspace
	workspace.FallenPartsDestroyHeight = -180
	Lighting.ClockTime, Lighting.Brightness = 20.3, 2
	Lighting.Ambient = Color3.fromRGB(55, 60, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(72, 77, 100)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmosphere.Density, atmosphere.Offset = 0.28, 0.15
	atmosphere.Color, atmosphere.Decay = Color3.fromRGB(155, 166, 198), Color3.fromRGB(45, 45, 68)
	local bloom = Lighting:FindFirstChild("BakiBloom") or Instance.new("BloomEffect", Lighting)
	bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "BakiBloom", 0.45, 24, 1.4
	part("City foundation", Vector3.new(290, 4, 260), Vector3.new(0, -2, 0), C.asphalt)
	-- Raised perimeter contains the playable city without invisible walls.
	for _, x in {-145, 145} do part("Perimeter", Vector3.new(3, 9, 260), Vector3.new(x, 3, 0), C.black) end
	for _, z in {-130, 130} do part("Perimeter", Vector3.new(290, 9, 3), Vector3.new(0, 3, z), C.black) end
	part("Main road", Vector3.new(26, 0.12, 240), Vector3.new(0, 0.08, 0), C.black, Enum.Material.Asphalt)
	for z = -112, 112, 14 do part("Lane marking", Vector3.new(0.35, 0.08, 6), Vector3.new(0, 0.2, z), C.gold) end
	for _, x in {-18, 18} do part("Sidewalk", Vector3.new(8, 0.5, 240), Vector3.new(x, 0.2, 0)) end
	for z = -105, 105, 35 do
		for _, x in {-20, 20} do
			part("Lamp post", Vector3.new(0.5, 16, 0.5), Vector3.new(x, 8, z), C.black, Enum.Material.Metal)
			part("Lamp arm", Vector3.new(5, 0.4, 0.4), Vector3.new(x + (x < 0 and 2 or -2), 16, z), C.black, Enum.Material.Metal)
			light(Vector3.new(x, 15.5, z), C.gold, 1.2, 32)
		end
	end
	-- Deterministic skyline with lit windows, roof trims and shop awnings.
	local rng = Random.new(188528)
	for _, x in {-112, -75, 75, 112} do
		for _, z in {-100, -65, 65, 100} do
			local h = rng:NextInteger(22, 62)
			local col = Color3.fromRGB(rng:NextInteger(36, 55), rng:NextInteger(39, 57), rng:NextInteger(48, 67))
			part("City building", Vector3.new(28, h, 25), Vector3.new(x, h / 2, z), col)
			part("Roof cap", Vector3.new(30, 1, 27), Vector3.new(x, h, z), C.black, Enum.Material.Metal)
			for y = 7, h - 3, 7 do
				for dx = -8, 8, 8 do
					part("Window", Vector3.new(3.4, 3, 0.15), Vector3.new(x + dx, y, z + 12.6), rng:NextNumber() > 0.3 and C.gold or C.black, Enum.Material.Neon)
				end
			end
			part("Shop canopy", Vector3.new(28, 0.7, 5), Vector3.new(x, 5, z + 14), C.red, Enum.Material.Metal)
		end
	end
	sign("UNDERGROUND\nCOMBAT DISTRICT", Vector3.new(26, 7, 1), Vector3.new(0, 19, 111), C.red)
	for _, x in {-15, 15} do part("Entrance gate", Vector3.new(1, 22, 1), Vector3.new(x, 11, 111), C.black, Enum.Material.Metal) end
	-- Street fighting court.
	part("Street court", Vector3.new(48, 0.25, 48), Vector3.new(-48, 0.2, 18), Color3.fromRGB(60, 65, 75))
	for _, x in {-72, -24} do part("Court edge", Vector3.new(0.3, 0.1, 48), Vector3.new(x, 0.4, 18), C.blue, Enum.Material.Neon) end
	sign("01 / STREET TRIALS", Vector3.new(26, 3, 0.5), Vector3.new(-48, 6, -8), C.blue)
	-- Open-front dojo, visible from the street.
	part("Dojo platform", Vector3.new(54, 1, 50), Vector3.new(79, 0.5, -8), Color3.fromRGB(107, 74, 51), Enum.Material.WoodPlanks)
	part("Tatami", Vector3.new(40, 0.15, 36), Vector3.new(79, 1.1, -8), Color3.fromRGB(135, 143, 102), Enum.Material.Fabric)
	part("Dojo rear wall", Vector3.new(54, 17, 1), Vector3.new(79, 9, -33), Color3.fromRGB(123, 104, 85), Enum.Material.WoodPlanks)
	for _, x in {52, 106} do part("Dojo side", Vector3.new(1, 17, 50), Vector3.new(x, 9, -8), C.black, Enum.Material.Wood) end
	part("Dojo roof", Vector3.new(60, 2, 56), Vector3.new(79, 18, -8), C.black, Enum.Material.Slate)
	for _, x in {55, 103} do part("Dojo pillar", Vector3.new(2, 18, 2), Vector3.new(x, 9, 17), C.red, Enum.Material.Wood) end
	sign("02 / IRON WILL DOJO", Vector3.new(35, 4, 0.5), Vector3.new(79, 14, 18), C.gold)
	light(Vector3.new(79, 15, -8), C.gold, 2, 40)
	-- Training park: bags, benches, planted cherry trees.
	sign("TRAINING / EARN YOUR STRENGTH", Vector3.new(36, 3, 0.5), Vector3.new(-83, 5, -39), C.gold)
	for x = -108, -60, 16 do
		part("Bag frame", Vector3.new(0.8, 12, 0.8), Vector3.new(x, 6, -30), C.black, Enum.Material.Metal)
		part("Bag arm", Vector3.new(0.8, 0.8, 8), Vector3.new(x, 12, -27), C.black, Enum.Material.Metal)
		local bag = cylinder("Punch bag", 1.5, 6, Vector3.new(x, 7.5, -23), C.red, Enum.Material.Fabric)
		-- Cylinder is horizontal by default; rotate upright for the bag.
		bag.Orientation = Vector3.new(0, 0, 90)
		bag:SetAttribute("TrainingBag", true)
		local train = Instance.new("ProximityPrompt")
		train.ActionText, train.ObjectText, train.HoldDuration = "Train / +1 Strength", "IRON BODY TRAINING", 0.8
		train.MaxActivationDistance, train.Parent = 10, bag
	end
	for _, x in {-117, -49} do
		part("Park bench seat", Vector3.new(8, 0.6, 3), Vector3.new(x, 2, -9), Color3.fromRGB(110, 77, 50), Enum.Material.WoodPlanks)
		part("Park bench back", Vector3.new(8, 3, 0.5), Vector3.new(x, 3.5, -10.5), Color3.fromRGB(110, 77, 50), Enum.Material.WoodPlanks)
		for _, dx in {-3, 3} do part("Bench leg", Vector3.new(0.5, 2, 2), Vector3.new(x + dx, 1, -9), C.black, Enum.Material.Metal) end
	end
	for _, pos in {Vector3.new(-120, 0, 44), Vector3.new(120, 0, 38), Vector3.new(-36, 0, 100)} do
		part("Tree planter", Vector3.new(10, 2, 10), pos + Vector3.new(0, 1, 0))
		part("Tree trunk", Vector3.new(2, 13, 2), pos + Vector3.new(0, 7, 0), Color3.fromRGB(81, 57, 47), Enum.Material.Wood)
		local crown = part("Cherry canopy", Vector3.new(17, 10, 16), pos + Vector3.new(0, 16, 0), Color3.fromRGB(168, 96, 123), Enum.Material.Grass)
		crown.Shape, crown.CanCollide = Enum.PartType.Ball, false
	end
	-- Underground bowl: a ring, stepped galleries and structural ribs.
	cylinder("Arena foundation", 60, 4, Vector3.new(0, -28, -100), C.black)
	cylinder("Sand ring", 29, 0.5, Vector3.new(0, -25.7, -100), Color3.fromRGB(158, 134, 99), Enum.Material.Sand)
	for i = 0, 47 do
		local a = i * math.pi * 2 / 48
		local p = part("Arena retaining wall", Vector3.new(8, 21, 2), Vector3.new(math.sin(a) * 59, -17, -100 + math.cos(a) * 59), C.concrete)
		p.CFrame = CFrame.lookAt(p.Position, Vector3.new(0, -17, -100))
		for tier = 1, 3 do
			local radius = 34 + tier * 6
			local seat = part("Gallery tier", Vector3.new(7, 1.5 + tier * 2, 5), Vector3.new(math.sin(a) * radius, -25 + tier, -100 + math.cos(a) * radius), C.black)
			seat.CFrame = CFrame.lookAt(seat.Position, Vector3.new(0, seat.Position.Y, -100))
		end
		if i % 6 == 0 then light(Vector3.new(math.sin(a) * 32, -10, -100 + math.cos(a) * 32), C.gold, 2, 38) end
	end
	sign("03 / THE UNDERGROUND", Vector3.new(34, 5, 0.5), Vector3.new(0, -12, -140), C.red)
	portal("ENTER THE ARENA", Vector3.new(32, 0.7, -62), Vector3.new(0, -22, -78), C.red)
	portal("RETURN TO CITY", Vector3.new(0, -25.2, -63), Vector3.new(32, 4, -51), C.blue)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name, spawn.Size, spawn.Position = "District Spawn", Vector3.new(12, 0.4, 12), Vector3.new(0, 0.4, 86)
	spawn.Anchored, spawn.Neutral, spawn.Duration = true, true, 3
	spawn.Color, spawn.Material, spawn.Parent = C.gold, Enum.Material.Neon, root
	return root
end
return World
