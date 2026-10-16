-- LocalScript: đặt trong StarterPlayer > StarterPlayerScripts
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer

local SPEED_VALUE, JUMP_VALUE, FLY_SPEED = 50, 120, 60
local DEFAULT_SPEED, DEFAULT_JUMP = 16, 50

local state = { Fly = false, Speed = false, HighJump = false, InfJump = false, ESP = false, FPS = false, Aimbot = false }
local savedPosition = nil
local travelSpeed = 60
local stepDistance = 8
local travelToken = 0
local travelBusy = false

-- ===== HELPERS =====
local function getChar()
	local c = player.Character
	if not c then return end
	return c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function stopTravel()
	travelToken += 1
	travelBusy = false
	local hum = getChar()
	if hum then hum.PlatformStand = false end
end

local function savePosition()
	local _, root = getChar()
	if root then
		savedPosition = root.CFrame
		return true
	end
	return false
end

local function teleportToSaved()
	local _, root = getChar()
	if root and savedPosition then
		stopTravel()
		root.CFrame = savedPosition
		return true
	end
	return false
end

local function flyToSaved()
	local hum, root = getChar()
	if not hum or not root or not savedPosition or travelBusy then return end
	travelToken += 1
	local token = travelToken
	travelBusy = true
	hum.PlatformStand = true
	task.spawn(function()
		while token == travelToken do
			local currentHum, currentRoot = getChar()
			if not currentHum or not currentRoot then break end
			local offset = savedPosition.Position - currentRoot.Position
			local distance = offset.Magnitude
			if distance <= 2 then
				currentRoot.CFrame = savedPosition
				break
			end
			local dt = RunService.Heartbeat:Wait()
			if token ~= travelToken then break end
			local step = math.min(distance, math.max(1, travelSpeed) * math.min(dt, 0.05))
			local nextPosition = currentRoot.Position + offset.Unit * step
			currentRoot.CFrame = CFrame.new(nextPosition, nextPosition + currentRoot.CFrame.LookVector)
		end
		local currentHum = getChar()
		if currentHum then currentHum.PlatformStand = false end
		if token == travelToken then travelBusy = false end
	end)
end

local function stepTeleportToSaved()
	local _, root = getChar()
	if not root or not savedPosition or travelBusy then return end
	travelToken += 1
	local token = travelToken
	travelBusy = true
	task.spawn(function()
		while token == travelToken do
			local _, currentRoot = getChar()
			if not currentRoot then break end
			local offset = savedPosition.Position - currentRoot.Position
			local distance = offset.Magnitude
			if distance <= stepDistance then
				currentRoot.CFrame = savedPosition
				break
			end
			currentRoot.CFrame = currentRoot.CFrame + offset.Unit * stepDistance
			task.wait(0.08)
		end
		if token == travelToken then travelBusy = false end
	end)
end

local function applyStats()
	local hum = getChar()
	if not hum then return end
	hum.WalkSpeed = state.Speed and SPEED_VALUE or DEFAULT_SPEED
	hum.UseJumpPower = true
	hum.JumpPower = state.HighJump and JUMP_VALUE or DEFAULT_JUMP
end

-- ===== FLY =====
local flyConn, bv
local function setFly(on)
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if bv then bv:Destroy(); bv = nil end
	local hum, root = getChar()
	if hum then hum.PlatformStand = false end
	if not on or not root then return end

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Velocity = Vector3.zero
	bv.Parent = root

	flyConn = RunService.Heartbeat:Connect(function()
		local h = getChar()
		if not h or not bv or not bv.Parent then return end
		local v = h.MoveDirection * FLY_SPEED
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			v = v + Vector3.new(0, FLY_SPEED, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			v = v - Vector3.new(0, FLY_SPEED, 0)
		end
		bv.Velocity = v
	end)
end

-- ===== INF JUMP =====
UIS.JumpRequest:Connect(function()
	if state.InfJump then
		local hum = getChar()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- ===== AIMBOT =====
local aimbotConn
local function getClosestPlayer()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local mouseLocation = UIS:GetMouseLocation()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local head = p.Character:FindFirstChild("Head")
			local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
			if head and humanoid and humanoid.Health > 0 then
				local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
				if onScreen then
					local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closestPlayer = p
					end
				end
			end
		end
	end
	return closestPlayer
end

local function setAimbot(on)
	if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
	if not on then return end
	aimbotConn = RunService.RenderStepped:Connect(function()
		if state.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local target = getClosestPlayer()
			if target and target.Character then
				local head = target.Character:FindFirstChild("Head")
				if head then
					Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
				end
			end
		end
	end)
end

-- ===== ESP =====
local highlights = {}
local function addESP(p)
	if p == player or not p.Character then return end
	if highlights[p] then highlights[p]:Destroy() end
	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = Color3.fromRGB(255, 60, 60)
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = p.Character
	highlights[p] = h
end
local function clearESP()
	for _, h in pairs(highlights) do h:Destroy() end
	table.clear(highlights)
end
local function setESP(on)
	clearESP()
	if on then for _, p in ipairs(Players:GetPlayers()) do addESP(p) end end
end
local function watch(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.5)
		if state.ESP then addESP(p) end
	end)
end
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerAdded:Connect(watch)

-- ===== FIX LAG =====
local disabled = {}
local oldShadows = Lighting.GlobalShadows
local function setFPS(on)
	if on then
		oldShadows = Lighting.GlobalShadows
		Lighting.GlobalShadows = false
		pcall(function()
			local UserSettings = UserSettings and UserSettings() or nil
			if UserSettings then
				local gameSettings = UserSettings:GetService("UserGameSettings")
				if gameSettings then
					gameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
				end
			end
		end)
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
				if d.Enabled then d.Enabled = false; table.insert(disabled, d) end
			end
		end
		for _, e in ipairs(Lighting:GetChildren()) do
			if e:IsA("PostEffect") and e.Enabled then e.Enabled = false; table.insert(disabled, e) end
		end
	else
		Lighting.GlobalShadows = oldShadows
		for _, d in ipairs(disabled) do if d.Parent then d.Enabled = true end end
		table.clear(disabled)
	end
end

local handlers = {
	Fly = setFly, Speed = applyStats, HighJump = applyStats,
	InfJump = function() end, ESP = setESP, FPS = setFPS, Aimbot = setAimbot,
}

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyStats()
	if state.Fly then setFly(true) end
end)

-- ===== GIAO DIỆN =====
local C = {
	bg      = Color3.fromRGB(20, 20, 26),
	bar     = Color3.fromRGB(30, 30, 40),
	off     = Color3.fromRGB(48, 48, 60),
	on      = Color3.fromRGB(46, 170, 92),
	action  = Color3.fromRGB(58, 90, 140),
	danger  = Color3.fromRGB(190, 60, 60),
	input   = Color3.fromRGB(38, 38, 48),
	text    = Color3.fromRGB(240, 240, 245),
	sub     = Color3.fromRGB(150, 150, 165),
}

local function round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
	return c
end

local function style(obj, bg)
	obj.BackgroundColor3 = bg
	obj.TextColor3 = C.text
	obj.Font = Enum.Font.GothamMedium
	obj.TextSize = 14
	obj.AutoButtonColor = true
	round(obj, 8)
end

local gui = Instance.new("ScreenGui")
gui.Name = "AdminPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local FULL_W, FULL_H, BAR_H = 560, 232, 34

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(FULL_W, FULL_H)
main.BackgroundColor3 = C.bg
main.ClipsDescendants = true
main.Parent = gui
round(main, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 70, 90)
stroke.Thickness = 1
stroke.Parent = main

local uiScale = Instance.new("UIScale")
uiScale.Parent = main
local function updateScale()
	local vp = Camera.ViewportSize
	uiScale.Scale = math.clamp(math.min((vp.X - 20) / FULL_W, (vp.Y - 20) / FULL_H), 0.5, 1)
end
updateScale()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- thanh tiêu đề
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, BAR_H)
bar.BackgroundColor3 = C.bar
bar.BorderSizePixel = 0
bar.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Text = "ADMIN PANEL"
title.TextColor3 = C.text
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

local mini = Instance.new("TextButton")
mini.Size = UDim2.fromOffset(30, 24)
mini.Position = UDim2.new(1, -40, 0.5, -12)
mini.Text = "–"
style(mini, C.off)
mini.TextSize = 16
mini.Parent = bar

-- kéo thả
do
	local dragging, dragStart, startPos
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = (input.Position - dragStart) / uiScale.Scale
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- thân panel
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -BAR_H)
body.Position = UDim2.fromOffset(0, BAR_H)
body.BackgroundTransparency = 1
body.Parent = main

local function makeColumn(xScale, xOffset, headerText)
	local col = Instance.new("Frame")
	col.Size = UDim2.new(0.5, -15, 1, -20)
	col.Position = UDim2.new(xScale, xOffset, 0, 10)
	col.BackgroundTransparency = 1
	col.Parent = body

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = headerText
	header.TextColor3 = C.sub
	header.Font = Enum.Font.GothamBold
	header.TextSize = 11
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = col

	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1, 0, 1, -20)
	grid.Position = UDim2.fromOffset(0, 20)
	grid.BackgroundTransparency = 1
	grid.Parent = col

	local g = Instance.new("UIGridLayout")
	g.CellSize = UDim2.new(0.5, -3, 0, 38)
	g.CellPadding = UDim2.fromOffset(6, 6)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.Parent = grid
	return grid
end

local leftGrid  = makeColumn(0, 10, "CHỨC NĂNG")
local rightGrid = makeColumn(0.5, 5, "TỌA ĐỘ / DI CHUYỂN")

-- nút bật/tắt
local toggles = {
	{ "Fly", "Fly" }, { "Speed", "Tốc độ" },
	{ "HighJump", "Nhảy cao" }, { "InfJump", "Nhảy vô tận" },
	{ "ESP", "ESP viền" }, { "FPS", "Fix lag" },
	{ "Aimbot", "Aimbot" },
}
for i, item in ipairs(toggles) do
	local key, label = item[1], item[2]
	local b = Instance.new("TextButton")
	b.LayoutOrder = i
	b.Text = label
	style(b, C.off)
	b.Parent = leftGrid

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.new(1, -16, 0.5, -4)
	dot.BackgroundColor3 = Color3.fromRGB(110, 110, 125)
	dot.Parent = b
	round(dot, 4)

	b.MouseButton1Click:Connect(function()
		state[key] = not state[key]
		b.BackgroundColor3 = state[key] and C.on or C.off
		dot.BackgroundColor3 = state[key] and Color3.new(1, 1, 1) or Color3.fromRGB(110, 110, 125)
		handlers[key](state[key])
	end)
end

-- ô nhập số
local function makeBox(order, placeholder, initial, minV, maxV, onChange)
	local box = Instance.new("TextBox")
	box.LayoutOrder = order
	box.PlaceholderText = placeholder
	box.Text = tostring(initial)
	box.ClearTextOnFocus = false
	style(box, C.input)
	box.TextSize = 13
	box.Parent = rightGrid
	box.FocusLost:Connect(function()
		local v = tonumber(box.Text)
		if v then onChange(math.clamp(v, minV, maxV)) end
		box.Text = tostring(order == 1 and travelSpeed or stepDistance)
	end)
	return box
end

makeBox(1, "Tốc độ bay", travelSpeed, 5, 300, function(v) travelSpeed = v end)
makeBox(2, "Độ dài bước", stepDistance, 2, 50, function(v) stepDistance = v end)

-- nút hành động
local function makeAction(order, label, color, callback)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Text = label
	style(b, color)
	b.TextSize = 13
	b.Parent = rightGrid
	b.MouseButton1Click:Connect(function() callback(b) end)
	return b
end

makeAction(3, "Lưu vị trí", C.action, function(b)
	if savePosition() then
		b.Text = "Đã lưu!"
		task.delay(1.2, function()
			if b.Parent then b.Text = "Lưu vị trí" end
		end)
	end
end)
makeAction(4, "TP thẳng", C.action, teleportToSaved)
makeAction(5, "Bay đến vị trí", C.action, flyToSaved)
makeAction(6, "TP từng đoạn", C.action, stepTeleportToSaved)
makeAction(7, "DỪNG", C.danger, stopTravel)

-- thu gọn / mở rộng
local collapsed = false
mini.MouseButton1Click:Connect(function()
	collapsed = not collapsed
	body.Visible = not collapsed
	main.Size = collapsed and UDim2.fromOffset(FULL_W, BAR_H) or UDim2.fromOffset(FULL_W, FULL_H)
	mini.Text = collapsed and "+" or "–"
end)
