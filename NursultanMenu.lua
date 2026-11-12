--[[
	Nursultan-style visuals для Roblox (ПК + телефон), только визуал.
	LocalScript -> StarterPlayer > StarterPlayerScripts

	Открыть меню: круглая кнопка "N" на экране (её можно двигать) или RightShift.
	Настройки модуля: стрелка ▾ справа на карточке (или ПКМ на ПК).
	Пока меню открыто, HUD (ватермарка, инфо, таргет худ, список модулей) можно перетаскивать.
]]

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local TextService  = game:GetService("TextService")
local Debris       = game:GetService("Debris")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CLIENT_NAME = "Nursultan"
local VERSION     = "2.0"
local TOGGLE_KEY  = Enum.KeyCode.RightShift
local IS_MOBILE   = UIS.TouchEnabled and not UIS.KeyboardEnabled

local THEMES = {
	{Name = "Nursultan", A = Color3.fromRGB(125, 90, 255), B = Color3.fromRGB(70, 165, 255)},
	{Name = "Sakura",    A = Color3.fromRGB(255, 105, 180), B = Color3.fromRGB(255, 175, 120)},
	{Name = "Mint",      A = Color3.fromRGB(50, 225, 165),  B = Color3.fromRGB(60, 150, 255)},
	{Name = "Blood",     A = Color3.fromRGB(255, 55, 80),   B = Color3.fromRGB(150, 40, 255)},
	{Name = "Gold",      A = Color3.fromRGB(255, 205, 70),  B = Color3.fromRGB(255, 110, 60)},
}
local THEME_NAMES = {}
for i, t in ipairs(THEMES) do THEME_NAMES[i] = t.Name end

local THEME = {
	Bg        = Color3.fromRGB(16, 16, 21),
	Sidebar   = Color3.fromRGB(12, 12, 16),
	Card      = Color3.fromRGB(23, 23, 30),
	CardHover = Color3.fromRGB(30, 30, 39),
	Stroke    = Color3.fromRGB(42, 42, 55),
	Text      = Color3.fromRGB(235, 235, 245),
	SubText   = Color3.fromRGB(130, 130, 150),
	Accent1   = THEMES[1].A,
	Accent2   = THEMES[1].B,
	On        = Color3.fromRGB(110, 230, 140),
	Off       = Color3.fromRGB(240, 95, 95),
}
local WHITE = Color3.new(1, 1, 1)

---------------------------------------------------------------- helpers
local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then inst[k] = v end
	end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(r) return create("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function round() return create("UICorner", {CornerRadius = UDim.new(1, 0)}) end
local function stroke(c, t) return create("UIStroke", {Color = c or THEME.Stroke, Thickness = t or 1}) end

-- Все градиенты акцента запоминаются, чтобы смена темы перекрашивала весь интерфейс
local gradients = {}
local function accentGradient(rot)
	local g = create("UIGradient", {Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), Rotation = rot or 0})
	gradients[g] = true
	return g
end
local function gradientStroke(thickness)
	local s = create("UIStroke", {Color = WHITE, Thickness = thickness or 1.5})
	accentGradient(45).Parent = s
	return s
end

local function text(props, children)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.TextSize = props.TextSize or 14
	return create("TextLabel", props, children)
end
local function tween(obj, t, goal, style)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function textWidth(s, size, font)
	return TextService:GetTextSize(s, size, font, Vector2.new(1000, 100)).X
end
local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

-- Перетаскивание с поддержкой мультитача (джойстик не мешает): следим только за своим касанием
local function trackDrag(handle, cb)
	local active, touchInput = false, nil
	handle.InputBegan:Connect(function(input)
		if not isPress(input) then return end
		if cb.Can and not cb.Can() then return end
		active = true
		touchInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
		if cb.Start then cb.Start(input.Position) end
	end)
	UIS.InputChanged:Connect(function(input)
		if not active then return end
		if (touchInput and input == touchInput) or (not touchInput and input.UserInputType == Enum.UserInputType.MouseMovement) then
			cb.Move(input.Position)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if not active then return end
		if (touchInput and input == touchInput) or (not touchInput and input.UserInputType == Enum.UserInputType.MouseButton1) then
			active = false
			if cb.End then cb.End() end
		end
	end)
end

local function makeDraggable(target, handle, canDrag)
	local state = {moved = false}
	local startIn, startPos
	trackDrag(handle, {
		Can = canDrag,
		Start = function(p) state.moved = false; startIn = p; startPos = target.Position end,
		Move = function(p)
			local d = p - startIn
			if d.Magnitude > 6 then state.moved = true end
			if state.moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end,
	})
	return state
end

---------------------------------------------------------------- общее состояние
local menuOpened = false
local Modules = {}
local char, hum, root
local function canDragHud() return menuOpened end

local fxFolder = create("Folder", {Name = "NursultanFX", Parent = workspace})
local function fxPart(props)
	local p = create("Part", {Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		CastShadow = false, Material = Enum.Material.Neon})
	for k, v in pairs(props or {}) do p[k] = v end
	return p
end

---------------------------------------------------------------- GUI
local gui = create("ScreenGui", {Name = "NursultanUI", ResetOnSpawn = false, DisplayOrder = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
-- Отдельный слой без отступа топбара, чтобы прицел был ровно по центру экрана
local overlay = create("ScreenGui", {Name = "NursultanOverlay", ResetOnSpawn = false, DisplayOrder = 49,
	IgnoreGuiInset = true, Parent = playerGui})

---------------------------------------------------------------- Watermark
local watermark = create("Frame", {
	Name = "Watermark", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.05,
	Visible = false, Parent = gui,
}, {
	corner(9),
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
	create("UIPadding", {PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 10)}),
})
local wmStroke = gradientStroke(1.5)
wmStroke.Parent = watermark
local wmStrokeGrad = wmStroke:FindFirstChildOfClass("UIGradient")

local badge = create("Frame", {Size = UDim2.fromOffset(22, 22), BackgroundColor3 = WHITE, LayoutOrder = 1, Parent = watermark},
	{corner(6), accentGradient(45)})
text({Text = "N", Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1), Parent = badge})
local wmNameGrad = accentGradient()
text({Text = CLIENT_NAME, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = WHITE, Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = watermark}, {wmNameGrad})

local function wmSegment(icon, order)
	local seg = create("Frame", {Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1, LayoutOrder = order, Parent = watermark}, {
		create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	create("Frame", {Size = UDim2.fromOffset(1, 14), BackgroundColor3 = THEME.Stroke, BorderSizePixel = 0, LayoutOrder = 1, Parent = seg})
	text({Text = icon, TextSize = 12, Size = UDim2.fromOffset(16, 32), LayoutOrder = 2, Parent = seg})
	local value = text({Text = "", TextSize = 13, Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 3, Parent = seg})
	return seg, value
end
local wmUserSeg, wmUser = wmSegment("👤", 3)
local wmFpsSeg, wmFps   = wmSegment("⚡", 4)
local wmPingSeg, wmPing = wmSegment("📶", 5)
local wmTimeSeg, wmTime = wmSegment("🕒", 6)
wmUser.Text = player.DisplayName
makeDraggable(watermark, watermark, canDragHud)

---------------------------------------------------------------- Information
local info = create("Frame", {
	Name = "Information", Position = UDim2.fromOffset(10, 50), Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.05,
	Visible = false, Parent = gui,
}, {
	corner(8), stroke(),
	create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
	create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}),
})
local function infoLine(order)
	return text({Text = "", TextSize = 13, RichText = true, Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, Parent = info})
end
local infoXYZ, infoBPS, infoPlayers = infoLine(1), infoLine(2), infoLine(3)
makeDraggable(info, info, canDragHud)

---------------------------------------------------------------- ArrayList
local arrayFrame = create("Frame", {
	Name = "ArrayList", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(250, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = gui,
}, {
	create("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}),
})
makeDraggable(arrayFrame, arrayFrame, canDragHud)
local arrayRows = {}

local function arraySet(m, on)
	local font = Enum.Font.GothamBold
	local row = arrayRows[m]
	if not row then
		local w = textWidth(m.Name, 13, font) + 20
		row = create("Frame", {Size = UDim2.fromOffset(w, 0), BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.15,
			BorderSizePixel = 0, ClipsDescendants = true, LayoutOrder = -w, Visible = false, Parent = arrayFrame})
		create("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = row}, {accentGradient(90)})
		local g = accentGradient()
		text({Text = m.Name, Font = font, TextSize = 13, TextColor3 = WHITE, Size = UDim2.new(1, -2, 1, 0), Parent = row}, {g})
		arrayRows[m] = row
		row:SetAttribute("w", w)
		m._rowGrad = g
	end
	local w = row:GetAttribute("w")
	if on then
		row.Visible = true
		tween(row, 0.3, {Size = UDim2.fromOffset(w, 20)})
	else
		tween(row, 0.3, {Size = UDim2.fromOffset(w, 0)})
		task.delay(0.3, function() if not m.Enabled then row.Visible = false end end)
	end
end

---------------------------------------------------------------- Уведомления
local notifHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	-- на телефоне выше кнопки прыжка
	Position = IS_MOBILE and UDim2.new(1, -10, 1, -170) or UDim2.new(1, -10, 1, -10),
	Size = UDim2.fromOffset(250, 400), BackgroundTransparency = 1, Parent = gui,
}, {
	create("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder}),
})

local function notify(title, on)
	local nm = Modules.Notifications
	if not (nm and nm.Enabled) then return end
	local holder = create("Frame", {Size = UDim2.fromOffset(250, 52), BackgroundTransparency = 1, Parent = notifHolder})
	local box = create("Frame", {Position = UDim2.fromOffset(270, 0), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg, Parent = holder}, {corner(9), stroke()})
	local icon = create("Frame", {Position = UDim2.fromOffset(10, 11), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = WHITE, Parent = box}, {corner(8), accentGradient(45)})
	text({Text = on and "✓" or "✕", Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = WHITE,
		Size = UDim2.fromScale(1, 1), Parent = icon})
	text({Text = title, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(50, 10), Size = UDim2.new(1, -60, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	text({Text = on and "Модуль включён" or "Модуль выключен", TextSize = 12, TextColor3 = on and THEME.On or THEME.Off,
		Position = UDim2.fromOffset(50, 28), Size = UDim2.new(1, -60, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	local bar = create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -1), Size = UDim2.new(1, -16, 0, 2),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = box}, {accentGradient()})
	tween(box, 0.4, {Position = UDim2.fromOffset(0, 0)})
	TweenService:Create(bar, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
	task.delay(2, function()
		tween(box, 0.4, {Position = UDim2.fromOffset(270, 0)})
		task.wait(0.4)
		holder:Destroy()
	end)
end

---------------------------------------------------------------- Target HUD
local thHolder = create("Frame", {Name = "TargetHUD", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 60),
	Size = UDim2.fromOffset(240, 74), BackgroundTransparency = 1, Parent = gui}, {corner(10)})
local thStroke = gradientStroke(1.5)
thStroke.Transparency = 1
thStroke.Parent = thHolder
local thScale = create("UIScale", {Scale = 0.85, Parent = thHolder})
local thGroup = create("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, GroupTransparency = 1,
	Parent = thHolder}, {corner(10)})
local thAvatar = create("ImageLabel", {Position = UDim2.fromOffset(12, 13), Size = UDim2.fromOffset(48, 48),
	BackgroundColor3 = THEME.Stroke, Parent = thGroup}, {corner(10)})
local thLetter = text({Text = "", Font = Enum.Font.GothamBlack, TextSize = 22, Size = UDim2.fromScale(1, 1), Parent = thAvatar})
local thName = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 15, Position = UDim2.fromOffset(72, 11),
	Size = UDim2.new(1, -130, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = thGroup})
local thWin = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 12, AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 13), Size = UDim2.fromOffset(50, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = thGroup})
local thSub = text({Text = "", TextSize = 12, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(72, 31),
	Size = UDim2.new(1, -84, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = thGroup})
local thBar = create("Frame", {Position = UDim2.fromOffset(72, 51), Size = UDim2.new(1, -84, 0, 8),
	BackgroundColor3 = THEME.Stroke, Parent = thGroup}, {corner(4)})
local thGhost = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.6,
	Parent = thBar}, {corner(4)})
local thFill = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = thBar},
	{corner(4), accentGradient()})
makeDraggable(thHolder, thHolder, canDragHud)

local thShown, thCurrent, thFrac = false, nil, -1
local thumbCache = {}
local function setTHVisible(v)
	if v == thShown then return end
	thShown = v
	tween(thGroup, 0.3, {GroupTransparency = v and 0 or 1})
	tween(thStroke, 0.3, {Transparency = v and 0 or 1})
	tween(thScale, 0.3, {Scale = v and 1 or 0.85}, Enum.EasingStyle.Back)
	if not v then thCurrent = nil end
end

local function updateTargetHUD(h, model, dist)
	local plr = Players:GetPlayerFromCharacter(model)
	if h ~= thCurrent then
		thCurrent, thFrac = h, -1
		thName.Text = plr and plr.DisplayName or model.Name
		thAvatar.Image = ""
		thLetter.Text = plr and "" or string.upper(string.sub(model.Name, 1, 1))
		if plr then
			local id = plr.UserId
			if thumbCache[id] then
				thAvatar.Image = thumbCache[id]
			else
				task.spawn(function()
					local ok, img = pcall(Players.GetUserThumbnailAsync, Players, id,
						Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					if ok then
						thumbCache[id] = img
						if thCurrent == h then thAvatar.Image = img end
					end
				end)
			end
		end
	end
	local frac = math.clamp(h.Health / math.max(h.MaxHealth, 1), 0, 1)
	if math.abs(frac - thFrac) > 0.001 then
		tween(thFill, 0.3, {Size = UDim2.fromScale(frac, 1)})
		TweenService:Create(thGhost, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.25),
			{Size = UDim2.fromScale(frac, 1)}):Play()
		thFrac = frac
	end
	thSub.Text = string.format("HP %.1f  •  %.1f m", h.Health, dist)
	if h == hum then
		thWin.Text = ""
	else
		local win = hum and hum.Health >= h.Health
		thWin.Text = win and "Win" or "Lose"
		thWin.TextColor3 = win and THEME.On or THEME.Off
	end
end

---------------------------------------------------------------- Target ESP
local espBillboard = create("BillboardGui", {Size = UDim2.fromScale(5, 5), AlwaysOnTop = true, LightInfluence = 0,
	Enabled = false, ResetOnSpawn = false, Parent = playerGui})
local espSquare = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.6, 0.6), BackgroundColor3 = WHITE, BackgroundTransparency = 0.85, Parent = espBillboard},
	{corner(10), accentGradient(45)})
gradientStroke(2.5).Parent = espSquare
local espFlash = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 60, 60),
	BackgroundTransparency = 1, Parent = espSquare}, {corner(10)})

local GHOSTS, GHOST_LEN = 3, 12
local RING_N, RING_TAIL = 28, 3
local FAR = CFrame.new(0, -1e5, 0)
local espParts, espMode, espCount, espHidden = {}, "none", 0, true

local function espEnsure(n)
	while #espParts < n do
		table.insert(espParts, fxPart({Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Transparency = 1,
			CFrame = FAR, Parent = fxFolder}))
	end
end

local function espConfigure(mode)
	espMode = mode
	for _, p in ipairs(espParts) do p.Transparency = 1 end
	espCount = 0
	if mode == "Призраки" then
		espEnsure(GHOSTS * GHOST_LEN)
		for g = 0, GHOSTS - 1 do
			for k = 0, GHOST_LEN - 1 do
				local a = k / (GHOST_LEN - 1)
				local p = espParts[g * GHOST_LEN + k + 1]
				p.Size = Vector3.one * (0.55 * (1 - a) + 0.08)
				p.Color = THEME.Accent1:Lerp(THEME.Accent2, a)
				p.Transparency = 0.1 + a * 0.8
			end
		end
		espCount = GHOSTS * GHOST_LEN
	elseif mode == "Кольцо" then
		espEnsure(RING_N * RING_TAIL)
		for r = 0, RING_TAIL - 1 do
			for i = 0, RING_N - 1 do
				local p = espParts[r * RING_N + i + 1]
				p.Size = Vector3.one * (0.24 - r * 0.05)
				p.Color = THEME.Accent1:Lerp(THEME.Accent2, math.abs(i / RING_N * 2 - 1))
				p.Transparency = 0.1 + r * 0.3
			end
		end
		espCount = RING_N * RING_TAIL
	end
	espHidden = false
end

local function espHide()
	espBillboard.Enabled = false
	if espHidden or espCount == 0 then return end
	local parts, cfs = {}, {}
	for i = 1, espCount do parts[i] = espParts[i]; cfs[i] = FAR end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	espHidden = true
end

local function espUpdate(targetRoot, t, dt)
	local mode = Modules.TargetESP.Values["Режим"]
	if mode ~= espMode then espConfigure(mode) end
	if not targetRoot then espHide() return end

	if mode == "Квадрат" then
		espBillboard.Adornee = targetRoot
		espBillboard.Enabled = true
		espSquare.Rotation = (espSquare.Rotation + dt * 120) % 360
		local s = 0.55 + math.sin(t * 4) * 0.05
		espSquare.Size = UDim2.fromScale(s, s)
		return
	end
	espBillboard.Enabled = false
	espHidden = false

	local parts, cfs = {}, {}
	local pos = targetRoot.Position
	if mode == "Призраки" then
		for g = 0, GHOSTS - 1 do
			for k = 0, GHOST_LEN - 1 do
				local tt = t * 2.2 - k * 0.06
				local ang = tt + g * (math.pi * 2 / GHOSTS)
				local h = math.sin(tt * 1.3 + g * 2) * 1.4
				table.insert(parts, espParts[g * GHOST_LEN + k + 1])
				table.insert(cfs, CFrame.new(pos + Vector3.new(math.cos(ang) * 2, h, math.sin(ang) * 2)))
			end
		end
	else
		for r = 0, RING_TAIL - 1 do
			local y = -0.6 + math.sin(t * 2 - r * 0.15) * 2.1
			for i = 0, RING_N - 1 do
				local ang = i / RING_N * math.pi * 2 + t * 0.6
				table.insert(parts, espParts[r * RING_N + i + 1])
				table.insert(cfs, CFrame.new(pos + Vector3.new(math.cos(ang) * 1.8, y, math.sin(ang) * 1.8)))
			end
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

---------------------------------------------------------------- Hit effects
local function hitEffect(pos, damage)
	local m = Modules.HitEffect
	local p = fxPart({Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(pos), Parent = fxFolder})
	local pe = create("ParticleEmitter", {
		Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), LightEmission = 1,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(180, 180), Drag = 4, Acceleration = Vector3.new(0, -8, 0), Rate = 0, Parent = p,
	})
	pe:Emit(m.Values["Частицы"])
	if m.Values["Цифры урона"] then
		local bb = create("BillboardGui", {Size = UDim2.fromOffset(90, 30), AlwaysOnTop = true, LightInfluence = 0,
			StudsOffset = Vector3.new(math.random(-10, 10) / 10, 1.5, 0), Parent = p})
		local lbl = text({Text = string.format("-%.1f", damage), Font = Enum.Font.GothamBlack, TextSize = 20,
			TextColor3 = WHITE, Size = UDim2.fromScale(1, 1), Parent = bb},
			{accentGradient(), create("UIStroke", {Thickness = 1.5, Transparency = 0.3})})
		tween(bb, 1, {StudsOffset = bb.StudsOffset + Vector3.new(0, 2.5, 0)})
		TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.5),
			{TextTransparency = 1}):Play()
	end
	Debris:AddItem(p, 1.5)
end

local function onTargetDamaged(h, damage, targetRoot)
	if Modules.HitEffect.Enabled and targetRoot then hitEffect(targetRoot.Position, damage) end
	if Modules.TargetESP.Enabled then
		espFlash.BackgroundTransparency = 0.4
		tween(espFlash, 0.4, {BackgroundTransparency = 1})
	end
end

---------------------------------------------------------------- Crosshair
local crosshair = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Visible = false, Parent = overlay})
local function chLine(anchor)
	return create("Frame", {AnchorPoint = anchor, BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = crosshair},
		{accentGradient(90), create("UIStroke", {Thickness = 1, Transparency = 0.5})})
end
local chTop, chBottom = chLine(Vector2.new(0.5, 1)), chLine(Vector2.new(0.5, 0))
local chLeft, chRight = chLine(Vector2.new(1, 0.5)), chLine(Vector2.new(0, 0.5))
local chDot = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = WHITE,
	Parent = crosshair}, {round(), accentGradient()})

---------------------------------------------------------------- эффекты Lighting (локальные)
local blur = create("BlurEffect", {Size = 0, Parent = Lighting})
local cc = create("ColorCorrectionEffect", {Enabled = false, Parent = Lighting})

---------------------------------------------------------------- косметика
local function clearObj(m)
	if not m._obj then return end
	for _, o in ipairs(m._obj) do
		if typeof(o) == "Instance" then o:Destroy() else o:Disconnect() end
	end
	m._obj = nil
end

local function spawnJumpCircle(r, h)
	local y = r.Position.Y - h.HipHeight - r.Size.Y / 2 + 0.05
	local p = fxPart({Transparency = 1, Size = Vector3.new(1, 0.05, 1), CFrame = CFrame.new(r.Position.X, y, r.Position.Z),
		Parent = fxFolder})
	local sg = create("SurfaceGui", {Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(256, 256), LightInfluence = 0, Parent = p})
	local ring = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8,
		Parent = sg}, {round(), accentGradient(45)})
	local rs = create("UIStroke", {Thickness = 14, Color = WHITE, Parent = ring})
	accentGradient(45).Parent = rs
	local size = Modules.JumpCircles.Values["Размер"]
	tween(p, 1, {Size = Vector3.new(size, 0.05, size)})
	tween(rs, 1, {Transparency = 1})
	tween(ring, 1, {BackgroundTransparency = 1})
	Debris:AddItem(p, 1.1)
end

---------------------------------------------------------------- модули
local CATEGORIES = {
	{Name = "Render", Icon = "👁", Modules = {
		{Name = "Watermark", Desc = "Красивая ватермарка", Default = true,
			Settings = {
				{Type = "Check", Name = "FPS", Default = true},
				{Type = "Check", Name = "Пинг", Default = true},
				{Type = "Check", Name = "Время", Default = true},
			},
			OnToggle = function(_, on) watermark.Visible = on end,
			OnChange = function(m)
				wmFpsSeg.Visible = m.Values["FPS"] ~= false
				wmPingSeg.Visible = m.Values["Пинг"] ~= false
				wmTimeSeg.Visible = m.Values["Время"] ~= false
			end},
		{Name = "ArrayList", Desc = "Список включённых модулей", Default = true,
			OnToggle = function(_, on) arrayFrame.Visible = on end},
		{Name = "Information", Desc = "Координаты, скорость, игроки", Default = true,
			OnToggle = function(_, on) info.Visible = on end},
		{Name = "TargetHUD", Desc = "Панель с HP ближайшей цели", Default = true,
			Settings = {{Name = "Дистанция", Min = 10, Max = 150, Default = 40}}},
		{Name = "TargetESP", Desc = "Анимированная метка на цели", Default = true,
			Settings = {{Type = "Mode", Name = "Режим", Options = {"Призраки", "Кольцо", "Квадрат"}, Default = 1}},
			OnToggle = function(_, on) if not on then espHide(); espConfigure("none") end end},
		{Name = "Crosshair", Desc = "Свой прицел",
			Settings = {
				{Name = "Отступ", Min = 0, Max = 20, Default = 5},
				{Name = "Длина", Min = 2, Max = 20, Default = 7},
				{Type = "Check", Name = "Динамический", Default = true},
				{Type = "Check", Name = "Вращение", Default = false},
				{Type = "Check", Name = "Точка", Default = true},
			},
			OnToggle = function(_, on) crosshair.Visible = on end},
	}},
	{Name = "Cosmetics", Icon = "✨", Modules = {
		{Name = "ChinaHat", Desc = "Китайская шляпа над головой", Default = true,
			Apply = function(m, c)
				local head = c:FindFirstChild("Head")
				if not head then return end
				local model = create("Model", {Name = "ChinaHat"})
				local layers = 8
				for i = 0, layers - 1 do
					local a = i / (layers - 1)
					local d = 2.7 * (1 - a) + 0.25
					local p = fxPart({Anchored = false, Massless = true, Shape = Enum.PartType.Cylinder,
						Size = Vector3.new(0.08, d, d), Color = THEME.Accent1:Lerp(THEME.Accent2, a), Transparency = 0.3,
						CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + 0.15 + i * 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)),
						Parent = model})
					create("WeldConstraint", {Part0 = head, Part1 = p, Parent = p})
				end
				model.Parent = c
				m._obj = {model}
			end},
		{Name = "Trails", Desc = "Шлейф за персонажем", Default = true,
			Settings = {{Name = "Длина", Min = 0.1, Max = 2, Default = 0.6, Step = 0.1}},
			Apply = function(m, _, _, r)
				local a0 = create("Attachment", {Position = Vector3.new(0, 0.9, 0), Parent = r})
				local a1 = create("Attachment", {Position = Vector3.new(0, -0.9, 0), Parent = r})
				local t = create("Trail", {Attachment0 = a0, Attachment1 = a1, Color = ColorSequence.new(THEME.Accent1, THEME.Accent2),
					Transparency = NumberSequence.new(0.25, 1), WidthScale = NumberSequence.new(1, 0.2),
					Lifetime = m.Values["Длина"], LightEmission = 1, FaceCamera = true, Parent = r})
				m._obj = {t, a0, a1}
			end,
			OnChange = function(m) if m._obj then m._obj[1].Lifetime = m.Values["Длина"] end end},
		{Name = "JumpCircles", Desc = "Круги при прыжке", Default = true,
			Settings = {{Name = "Размер", Min = 3, Max = 15, Default = 8}},
			Apply = function(m, _, h, r)
				m._obj = {h.StateChanged:Connect(function(_, new)
					if new == Enum.HumanoidStateType.Jumping then spawnJumpCircle(r, h) end
				end)}
			end},
		{Name = "HitEffect", Desc = "Частицы и цифры урона по цели", Default = true,
			Settings = {
				{Name = "Частицы", Min = 5, Max = 60, Default = 25},
				{Type = "Check", Name = "Цифры урона", Default = true},
			}},
		{Name = "Aura", Desc = "Светящиеся частицы вокруг тебя",
			Apply = function(m, _, _, r)
				local pe = create("ParticleEmitter", {
					Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), LightEmission = 1, Rate = 18,
					Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0)}),
					Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(0.5, 1.5),
					SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 1.5, 0), Parent = r,
				})
				m._obj = {pe}
			end},
		{Name = "SelfChams", Desc = "Подсветка своего персонажа",
			Settings = {{Name = "Заливка", Min = 0, Max = 1, Default = 0.6, Step = 0.05}},
			Apply = function(m, c)
				m._obj = {create("Highlight", {FillColor = THEME.Accent1, OutlineColor = THEME.Accent2,
					FillTransparency = m.Values["Заливка"], DepthMode = Enum.HighlightDepthMode.Occluded, Parent = c})}
			end,
			OnChange = function(m) if m._obj then m._obj[1].FillTransparency = m.Values["Заливка"] end end},
	}},
	{Name = "World", Icon = "🌍", Modules = {
		{Name = "CustomFOV", Desc = "Угол обзора камеры",
			Settings = {{Name = "FOV", Min = 30, Max = 120, Default = 90}},
			OnToggle = function(m, on)
				local cam = workspace.CurrentCamera
				if on then m._old = cam.FieldOfView elseif m._old then cam.FieldOfView = m._old end
			end},
		{Name = "TimeChanger", Desc = "Время суток", Settings = {{Name = "Время", Min = 0, Max = 24, Default = 0, Step = 0.5}},
			OnToggle = function(m, on)
				if on then m._old = Lighting.ClockTime elseif m._old then Lighting.ClockTime = m._old end
			end},
		{Name = "ColorCorrection", Desc = "Насыщенность и контраст",
			Settings = {
				{Name = "Насыщенность", Min = -1, Max = 1, Default = 0.3, Step = 0.05},
				{Name = "Контраст", Min = -1, Max = 1, Default = 0.1, Step = 0.05},
			},
			OnToggle = function(_, on) cc.Enabled = on end},
		{Name = "NoFog", Desc = "Убирает туман и атмосферу",
			OnToggle = function(m, on)
				local atm = Lighting:FindFirstChildOfClass("Atmosphere")
				if on then
					m._fog = Lighting.FogEnd; Lighting.FogEnd = 1e6
					if atm then m._atm, m._dens = atm, atm.Density; atm.Density = 0 end
				else
					if m._fog then Lighting.FogEnd = m._fog end
					if m._atm then m._atm.Density = m._dens end
				end
			end},
	}},
	{Name = "Interface", Icon = "🖥", Modules = {
		{Name = "ClientTheme", Desc = "Цвет интерфейса и эффектов", Default = true,
			Settings = {{Type = "Mode", Name = "Тема", Options = THEME_NAMES, Default = 1}}},
		{Name = "MenuBlur", Desc = "Размытие фона при открытом меню", Default = true,
			Settings = {{Name = "Сила", Min = 0, Max = 30, Default = 16}},
			OnToggle = function(m, on) tween(blur, 0.3, {Size = (on and menuOpened) and m.Values["Сила"] or 0}) end,
			OnChange = function(m) if m.Enabled and menuOpened then blur.Size = m.Values["Сила"] end end},
		{Name = "Notifications", Desc = "Уведомления о модулях", Default = true},
	}},
}

---------------------------------------------------------------- темы
local function applyTheme(name)
	for _, t in ipairs(THEMES) do
		if t.Name == name then THEME.Accent1, THEME.Accent2 = t.A, t.B end
	end
	local seq = ColorSequence.new(THEME.Accent1, THEME.Accent2)
	for g in pairs(gradients) do
		if g.Parent then g.Color = seq else gradients[g] = nil end
	end
	-- 3D-эффекты пересоздаём в новых цветах
	for _, m in pairs(Modules) do
		if m.Apply and m.Enabled and char and root then clearObj(m); m.Apply(m, char, hum, root) end
	end
	if espMode ~= "none" then espConfigure(espMode) end
end

local themeMod = CATEGORIES[4].Modules[1]
themeMod.OnToggle = function(m, on) applyTheme(on and m.Values["Тема"] or THEMES[1].Name) end
themeMod.OnChange = function(m) if m.Enabled then applyTheme(m.Values["Тема"]) end end

local function setModule(m, on, silent)
	m.Enabled = on
	m._grad.Enabled = on
	tween(m._switch, 0.25, {BackgroundColor3 = on and WHITE or THEME.Stroke})
	tween(m._knob, 0.25, {Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
	tween(m._title, 0.25, {TextColor3 = on and WHITE or THEME.Text})
	if m.Apply then
		clearObj(m)
		if on and char and root then m.Apply(m, char, hum, root) end
	end
	if m.OnToggle then m.OnToggle(m, on) end
	arraySet(m, on)
	if not silent then notify(m.Name, on) end
end

---------------------------------------------------------------- окно меню
local MENU_W, MENU_H = 680, 440
local menuHolder = create("Frame", {Size = UDim2.fromOffset(MENU_W, MENU_H), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui})
local fitScale = create("UIScale", {Parent = menuHolder})
local main = create("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, GroupTransparency = 1,
	Parent = menuHolder}, {corner(12)})
local mainScale = create("UIScale", {Scale = 0.9, Parent = main})
-- Освобождает курсор в first-person, пока меню открыто
create("TextButton", {Modal = true, Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = main})
create("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3, Parent = main},
	{accentGradient()})

local function updateFit()
	local vp = workspace.CurrentCamera.ViewportSize
	fitScale.Scale = math.min(1, (vp.X - 20) / MENU_W, (vp.Y - 70) / MENU_H)
end
updateFit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit)

-- Sidebar
local sidebar = create("Frame", {Size = UDim2.new(0, 175, 1, 0), BackgroundColor3 = THEME.Sidebar, BorderSizePixel = 0, Parent = main})
local logoGrad = accentGradient()
text({Text = CLIENT_NAME, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = WHITE, Position = UDim2.fromOffset(0, 14),
	Size = UDim2.new(1, 0, 0, 28), Parent = sidebar}, {logoGrad})
text({Text = "v" .. VERSION .. "  •  visuals", TextSize = 11, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(0, 42),
	Size = UDim2.new(1, 0, 0, 14), Parent = sidebar})

local catList = create("Frame", {Position = UDim2.fromOffset(12, 76), Size = UDim2.new(1, -24, 1, -146),
	BackgroundTransparency = 1, Parent = sidebar},
	{create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})

local profile = create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12),
	Size = UDim2.new(1, -24, 0, 50), BackgroundColor3 = THEME.Card, Parent = sidebar}, {corner(9), stroke()})
local avatar = create("ImageLabel", {Position = UDim2.fromOffset(9, 9), Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = THEME.Stroke, Parent = profile}, {round()})
text({Text = player.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(50, 9),
	Size = UDim2.new(1, -56, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile})
text({Text = "Premium", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, Position = UDim2.fromOffset(50, 27),
	Size = UDim2.new(1, -56, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = profile}, {accentGradient()})
task.spawn(function()
	local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
		Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	if ok then avatar.Image = img end
end)

-- Контент
local content = create("Frame", {Position = UDim2.fromOffset(175, 0), Size = UDim2.new(1, -175, 1, 0),
	BackgroundTransparency = 1, Parent = main})
local header = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 20, Position = UDim2.fromOffset(20, 14),
	Size = UDim2.new(1, -250, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = content})
text({Text = IS_MOBILE and "Нажми ▾ для настроек" or "ПКМ или ▾ — настройки", TextSize = 12, TextColor3 = THEME.SubText,
	Position = UDim2.fromOffset(20, 38), Size = UDim2.new(1, -250, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = content})
local search = create("TextBox", {
	PlaceholderText = "Поиск...", Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 13,
	TextColor3 = THEME.Text, PlaceholderColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = THEME.Card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 18),
	Size = UDim2.fromOffset(150, 32), Parent = content,
}, {corner(8), stroke(), create("UIPadding", {PaddingLeft = UDim.new(0, 10)})})
local closeBtn = create("TextButton", {Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.SubText,
	AutoButtonColor = false, BackgroundColor3 = THEME.Card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
	Size = UDim2.fromOffset(32, 32), Parent = content}, {corner(8), stroke()})

---------------------------------------------------------------- элементы настроек
local function makeSlider(parent, page, m, s, order)
	local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(0.6, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local valueLbl = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.fromScale(0.6, 0),
		Size = UDim2.new(0.4, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = holder})
	local bar = create("Frame", {Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = THEME.Stroke, Parent = holder}, {corner(3)})
	local fill = create("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, Parent = bar}, {corner(3), accentGradient()})
	local knob = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, Parent = bar}, {round()})

	local step = s.Step or 1
	local function set(v)
		v = math.clamp(math.floor(v / step + 0.5) * step, s.Min, s.Max)
		m.Values[s.Name] = v
		local a = (v - s.Min) / (s.Max - s.Min)
		tween(fill, 0.1, {Size = UDim2.fromScale(a, 1)})
		tween(knob, 0.1, {Position = UDim2.fromScale(a, 0.5)})
		valueLbl.Text = step < 1 and string.format("%.2f", v) or tostring(v)
		if m.OnChange then m.OnChange(m, s.Name, v) end
	end
	set(s.Default)

	local function fromX(x)
		set(s.Min + (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (s.Max - s.Min))
	end
	trackDrag(holder, {
		Start = function(p) page.ScrollingEnabled = false; fromX(p.X) end,
		Move = function(p) fromX(p.X) end,
		End = function() page.ScrollingEnabled = true end,
	})
end

local function makeMode(parent, m, s, order)
	local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(0.4, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local btn = create("TextButton", {Text = "", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, AutoButtonColor = false,
		BackgroundColor3 = THEME.Stroke, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(140, 26), Parent = holder}, {corner(7), gradientStroke(1)})
	local idx = s.Default or 1
	local function set(i)
		idx = i
		m.Values[s.Name] = s.Options[i]
		btn.Text = "‹   " .. s.Options[i] .. "   ›"
		if m.OnChange then m.OnChange(m, s.Name, s.Options[i]) end
	end
	set(idx)
	btn.Activated:Connect(function() set(idx % #s.Options + 1) end)
end

local function makeCheck(parent, m, s, order)
	local holder = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1, LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(1, -30, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local box = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = THEME.Stroke, Parent = holder}, {corner(6)})
	local mark = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 0),
		BackgroundColor3 = WHITE, Parent = box}, {corner(5), accentGradient(45)})
	text({Text = "✓", Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1), Parent = mark})
	local function set(v)
		m.Values[s.Name] = v
		tween(mark, 0.2, {Size = v and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0)})
		if m.OnChange then m.OnChange(m, s.Name, v) end
	end
	set(s.Default == true)
	holder.Activated:Connect(function() set(not m.Values[s.Name]) end)
end

local function makeModule(page, m, order)
	m.Values = {}
	m.Enabled = false
	Modules[m.Name] = m

	local card = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Card, LayoutOrder = order, Parent = page},
		{corner(9), stroke(), create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
	m._card = card

	local top = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
	m._title = text({Text = m.Name, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(14, 11),
		Size = UDim2.new(1, -120, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
	text({Text = m.Desc or "", TextSize = 12, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(14, 30),
		Size = UDim2.new(1, -120, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = top})

	m._switch = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(40, 22), BackgroundColor3 = THEME.Stroke, Parent = top}, {round()})
	m._grad = accentGradient()
	m._grad.Enabled = false
	m._grad.Parent = m._switch
	m._knob = create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = WHITE, Parent = m._switch}, {round()})

	top.Activated:Connect(function() setModule(m, not m.Enabled) end)
	top.MouseEnter:Connect(function() tween(card, 0.2, {BackgroundColor3 = THEME.CardHover}) end)
	top.MouseLeave:Connect(function() tween(card, 0.2, {BackgroundColor3 = THEME.Card}) end)

	if m.Settings then
		local settingsFrame = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = card}, {
			create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
			create("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12)}),
		})
		for i, s in ipairs(m.Settings) do
			if s.Type == "Mode" then makeMode(settingsFrame, m, s, i)
			elseif s.Type == "Check" then makeCheck(settingsFrame, m, s, i)
			else makeSlider(settingsFrame, page, m, s, i) end
		end

		-- крупная зона нажатия для пальца
		local arrow = create("TextButton", {Text = "▾", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = THEME.SubText,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0),
			Size = UDim2.fromOffset(40, 40), Parent = top})
		local function expand()
			settingsFrame.Visible = not settingsFrame.Visible
			tween(arrow, 0.25, {Rotation = settingsFrame.Visible and 180 or 0})
		end
		arrow.Activated:Connect(expand)
		top.MouseButton2Click:Connect(expand)
	end
end

---------------------------------------------------------------- категории
local function selectCategory(cat)
	header.Text = cat.Name
	for _, c in ipairs(CATEGORIES) do
		local active = c == cat
		tween(c._btn, 0.25, {BackgroundTransparency = active and 0 or 1})
		tween(c._ind, 0.25, {Size = UDim2.fromOffset(3, active and 18 or 0)})
		tween(c._lbl, 0.25, {TextColor3 = active and WHITE or THEME.SubText})
		c._page.Visible = active
	end
	cat._page.Position = UDim2.fromOffset(20, 76)
	tween(cat._page, 0.3, {Position = UDim2.fromOffset(20, 64)})
end

for i, cat in ipairs(CATEGORIES) do
	local btn = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = THEME.Card, BackgroundTransparency = 1, LayoutOrder = i, Parent = catList}, {corner(8)})
	cat._btn = btn
	cat._ind = create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(3, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = btn}, {corner(2), accentGradient(90)})
	text({Text = cat.Icon, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 20, 1, 0), Parent = btn})
	cat._lbl = text({Text = cat.Name, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
	btn.Activated:Connect(function() selectCategory(cat) end)

	cat._page = create("ScrollingFrame", {
		Position = UDim2.fromOffset(20, 64), Size = UDim2.new(1, -40, 1, -80), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.Accent1,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content,
	}, {
		create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
		create("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8)}),
	})
	for j, m in ipairs(cat.Modules) do makeModule(cat._page, m, j) end
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	local q = search.Text:lower()
	for _, cat in ipairs(CATEGORIES) do
		for _, m in ipairs(cat.Modules) do
			m._card.Visible = q == "" or m.Name:lower():find(q, 1, true) ~= nil
		end
	end
end)

-- Зона перетаскивания окна (не перекрывает поиск и крестик)
local dragZone = create("Frame", {Size = UDim2.new(1, -240, 0, 60), BackgroundTransparency = 1, ZIndex = 2, Parent = main})
makeDraggable(menuHolder, dragZone)

---------------------------------------------------------------- открытие/закрытие
local function setMenu(state)
	menuOpened = state
	if state then
		updateFit()
		menuHolder.Visible = true
	end
	tween(main, 0.3, {GroupTransparency = state and 0 or 1})
	tween(mainScale, 0.35, {Scale = state and 1 or 0.9}, Enum.EasingStyle.Back)
	local mb = Modules.MenuBlur
	tween(blur, 0.3, {Size = (state and mb.Enabled) and mb.Values["Сила"] or 0})
	if not state then
		task.delay(0.3, function() if not menuOpened then menuHolder.Visible = false end end)
	end
end

closeBtn.Activated:Connect(function() setMenu(false) end)
UIS.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == TOGGLE_KEY then setMenu(not menuOpened) end
end)

-- Плавающая кнопка открытия (для телефона), её можно перетаскивать
local openBtn = create("TextButton", {Text = "",
	AutoButtonColor = false, BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.45, 0),
	Size = UDim2.fromOffset(50, 50), ZIndex = 10, Parent = gui},
	{round(), accentGradient(45), create("UIStroke", {Color = WHITE, Thickness = 2, Transparency = 0.6})})
-- Буква отдельным лейблом: градиент кнопки иначе перекрасил бы и текст
text({Text = "N", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1), ZIndex = 11, Parent = openBtn})
local openDrag = makeDraggable(openBtn, openBtn)
openBtn.Activated:Connect(function()
	if openDrag.moved then return end
	setMenu(not menuOpened)
end)

---------------------------------------------------------------- цели
local humanoids = {}
local function track(d) if d:IsA("Humanoid") then humanoids[d] = true end end
for _, d in ipairs(workspace:GetDescendants()) do track(d) end
workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(d) humanoids[d] = nil end)

local function getRoot(model)
	return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
end

local function findTarget(range)
	if not root then return nil end
	local best, bestD
	for h in pairs(humanoids) do
		local model = h.Parent
		if model and model ~= char and h.Health > 0 then
			local r = getRoot(model)
			if r then
				local d = (r.Position - root.Position).Magnitude
				if d <= range and (not bestD or d < bestD) then best, bestD = h, d end
			end
		end
	end
	return best
end

---------------------------------------------------------------- главный цикл
local frames, lastFps, fps = 0, os.clock(), 60
local t, searchT, infoT = 0, 0, 0
local target, lastTarget, lastTargetHp = nil, nil, nil

local function updateWatermark()
	wmFps.Text = fps .. " fps"
	wmPing.Text = math.floor(player:GetNetworkPing() * 1000 + 0.5) .. " ms"
	wmTime.Text = os.date("%H:%M")
end

RunService.RenderStepped:Connect(function(dt)
	t += dt

	frames += 1
	local now = os.clock()
	if now - lastFps >= 0.5 then
		fps = math.floor(frames / (now - lastFps) + 0.5)
		frames, lastFps = 0, now
		updateWatermark()
	end

	-- анимированные градиенты
	wmStrokeGrad.Rotation = (wmStrokeGrad.Rotation + dt * 90) % 360
	wmNameGrad.Offset = Vector2.new(math.sin(t * 2) * 0.5, 0)
	logoGrad.Rotation = (logoGrad.Rotation + dt * 60) % 360
	thStroke:FindFirstChildOfClass("UIGradient").Rotation = (t * 90) % 360
	for m, row in pairs(arrayRows) do
		if row.Visible and m._rowGrad then
			m._rowGrad.Offset = Vector2.new(math.sin(t * 2 + row.AbsolutePosition.Y * 0.03) * 0.5, 0)
		end
	end

	-- мир
	local cam = workspace.CurrentCamera
	if Modules.CustomFOV.Enabled then cam.FieldOfView = Modules.CustomFOV.Values.FOV end
	if Modules.TimeChanger.Enabled then Lighting.ClockTime = Modules.TimeChanger.Values["Время"] end
	if Modules.ColorCorrection.Enabled then
		cc.Saturation = Modules.ColorCorrection.Values["Насыщенность"]
		cc.Contrast = Modules.ColorCorrection.Values["Контраст"]
	end

	-- цель
	local needTarget = Modules.TargetHUD.Enabled or Modules.TargetESP.Enabled or Modules.HitEffect.Enabled
	searchT += dt
	if not needTarget then
		target = nil
	elseif searchT >= 0.1 then
		searchT = 0
		target = findTarget(Modules.TargetHUD.Values["Дистанция"])
	end
	if target and (not target.Parent or target.Health <= 0) then target = nil end
	local tRoot = target and getRoot(target.Parent)
	if not tRoot then target = nil end

	if target ~= lastTarget then
		lastTarget, lastTargetHp = target, target and target.Health
	elseif target then
		local hp = target.Health
		if hp < lastTargetHp - 0.01 then onTargetDamaged(target, lastTargetHp - hp, tRoot) end
		lastTargetHp = hp
	end

	if Modules.TargetHUD.Enabled then
		local h, model, dist = target, target and target.Parent, 0
		if tRoot and root then dist = (tRoot.Position - root.Position).Magnitude end
		-- превью на себе, пока меню открыто и цели нет
		if not h and menuOpened and hum and char then h, model = hum, char end
		if h and model then
			setTHVisible(true)
			updateTargetHUD(h, model, dist)
		else
			setTHVisible(false)
		end
	else
		setTHVisible(false)
	end

	if Modules.TargetESP.Enabled then espUpdate(tRoot, t, dt) end

	-- прицел
	if Modules.Crosshair.Enabled then
		local v = Modules.Crosshair.Values
		local speed = root and (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude or 0
		local gap = v["Отступ"] + (v["Динамический"] and math.min(speed * 0.35, 12) or 0)
		local len, th = v["Длина"], 2
		chTop.Size, chTop.Position = UDim2.fromOffset(th, len), UDim2.fromOffset(0, -gap)
		chBottom.Size, chBottom.Position = UDim2.fromOffset(th, len), UDim2.fromOffset(0, gap)
		chLeft.Size, chLeft.Position = UDim2.fromOffset(len, th), UDim2.fromOffset(-gap, 0)
		chRight.Size, chRight.Position = UDim2.fromOffset(len, th), UDim2.fromOffset(gap, 0)
		chDot.Visible = v["Точка"] == true
		crosshair.Rotation = v["Вращение"] and (crosshair.Rotation + dt * 90) % 360 or 0
	end

	-- информация
	infoT += dt
	if Modules.Information.Enabled and infoT >= 0.1 then
		infoT = 0
		local hex = "#" .. THEME.Accent1:ToHex()
		if root then
			local p = root.Position
			infoXYZ.Text = string.format('<font color="%s"><b>XYZ</b></font>  %d, %d, %d', hex, math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
			local bps = (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
			infoBPS.Text = string.format('<font color="%s"><b>BPS</b></font>  %.1f', hex, bps)
		end
		infoPlayers.Text = string.format('<font color="%s"><b>Players</b></font>  %d', hex, #Players:GetPlayers())
	end
end)

---------------------------------------------------------------- персонаж
local function onCharacter(c)
	local h = c:WaitForChild("Humanoid", 10)
	local r = c:WaitForChild("HumanoidRootPart", 10)
	c:WaitForChild("Head", 10)
	if not (h and r) then return end
	char, hum, root = c, h, r
	for _, m in pairs(Modules) do
		if m.Apply and m.Enabled then clearObj(m); m.Apply(m, c, h, r) end
	end
end
player.CharacterAdded:Connect(onCharacter)

---------------------------------------------------------------- старт
for _, cat in ipairs(CATEGORIES) do
	for _, m in ipairs(cat.Modules) do
		if m.Default then setModule(m, true, true) end
	end
end
if player.Character then task.spawn(onCharacter, player.Character) end
updateWatermark()
selectCategory(CATEGORIES[1])
setMenu(not IS_MOBILE)
