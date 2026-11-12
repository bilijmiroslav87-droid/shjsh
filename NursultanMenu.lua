--[[
	Nursultan-style visuals для Roblox (ПК + телефон), только визуал.
	LocalScript -> StarterPlayer > StarterPlayerScripts

	Меню: кнопка "N" на экране (её можно двигать) или RightShift.
	Настройки модуля: три точки справа на строке модуля (или ПКМ на ПК).
	Пока меню открыто, элементы HUD можно перетаскивать.
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
local TOGGLE_KEY  = Enum.KeyCode.RightShift
local IS_MOBILE   = UIS.TouchEnabled and not UIS.KeyboardEnabled

local THEMES = {
	{Name = "Nursultan", A = Color3.fromRGB(110, 120, 255), B = Color3.fromRGB(170, 100, 255)},
	{Name = "Aqua",      A = Color3.fromRGB(60, 200, 255),  B = Color3.fromRGB(70, 110, 255)},
	{Name = "Sakura",    A = Color3.fromRGB(255, 120, 180), B = Color3.fromRGB(255, 180, 140)},
	{Name = "Mint",      A = Color3.fromRGB(70, 225, 160),  B = Color3.fromRGB(60, 160, 230)},
	{Name = "Blood",     A = Color3.fromRGB(255, 70, 80),   B = Color3.fromRGB(160, 40, 90)},
	{Name = "Gold",      A = Color3.fromRGB(255, 200, 80),  B = Color3.fromRGB(255, 130, 60)},
	{Name = "Mono",      A = Color3.fromRGB(235, 235, 240), B = Color3.fromRGB(130, 130, 140)},
}
local THEME_NAMES = {}
for i, t in ipairs(THEMES) do THEME_NAMES[i] = t.Name end

local THEME = {
	Bg      = Color3.fromRGB(17, 17, 19),
	Side    = Color3.fromRGB(13, 13, 15),
	Row     = Color3.fromRGB(26, 26, 29),
	RowOn   = Color3.fromRGB(34, 34, 39),
	Stroke  = Color3.fromRGB(44, 44, 50),
	Text    = Color3.fromRGB(232, 232, 236),
	SubText = Color3.fromRGB(125, 125, 135),
	Accent1 = THEMES[1].A,
	Accent2 = THEMES[1].B,
}
local SUB_HEX = "#" .. THEME.SubText:ToHex()
local WHITE = Color3.new(1, 1, 1)
local FONT, FONT_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold

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
local function stroke() return create("UIStroke", {Color = THEME.Stroke, Thickness = 1}) end

-- Всё, что красится в цвет темы, запоминается, чтобы смена темы перекрашивала интерфейс
local gradients, flats = {}, {}
local function accentGradient(rot)
	local g = create("UIGradient", {Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), Rotation = rot or 0})
	gradients[g] = true
	return g
end
local function flat(inst, prop)
	inst[prop] = THEME.Accent1
	table.insert(flats, {inst, prop})
	return inst
end

local function text(props, children)
	props.BackgroundTransparency = 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.TextSize = props.TextSize or 13
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

-- Перетаскивание с мультитачем: следим только за своим касанием, джойстик не мешает
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

local gui = create("ScreenGui", {Name = "NursultanUI", ResetOnSpawn = false, DisplayOrder = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui})
-- Отдельный слой без отступа топбара, чтобы прицел был ровно по центру экрана
local overlay = create("ScreenGui", {Name = "NursultanOverlay", ResetOnSpawn = false, DisplayOrder = 49,
	IgnoreGuiInset = true, Parent = playerGui})

---------------------------------------------------------------- Watermark
local watermark = create("Frame", {Name = "Watermark", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = THEME.Bg, BackgroundTransparency = 1, Visible = false, Parent = gui},
	{corner(6)})
local wmLine = flat(create("Frame", {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -12, 0, 1), BorderSizePixel = 0,
	Visible = false, Parent = watermark}), "BackgroundColor3")
local wmInner = create("Frame", {Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1, Parent = watermark})
local wmLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder, Parent = wmInner})

local wmSegs = {}
local function wmSeg(key, order)
	local frame = create("Frame", {Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = THEME.Bg, LayoutOrder = order, Parent = wmInner},
		{corner(6), create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})})
	local label = text({Text = "", RichText = true, Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
		TextStrokeTransparency = 1, Parent = frame})
	wmSegs[key] = {frame = frame, label = label}
	return label
end
local wmName = wmSeg("name", 1)
wmName.Text, wmName.Font, wmName.TextColor3 = CLIENT_NAME, FONT_BOLD, WHITE
local wmNameGrad = accentGradient()
wmNameGrad.Parent = wmName
wmSeg("nick", 2).Text = player.Name
wmSeg("fps", 3)
wmSeg("ping", 4)
wmSeg("time", 5)
makeDraggable(watermark, watermark, canDragHud)

---------------------------------------------------------------- Information
local info = create("Frame", {Name = "Information", Position = UDim2.fromOffset(10, 46), Size = UDim2.fromOffset(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = THEME.Bg, Visible = false, Parent = gui}, {
	corner(6),
	create("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
	create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}),
})
local function infoLine(order)
	return text({Text = "", RichText = true, Size = UDim2.fromOffset(0, 15), AutomaticSize = Enum.AutomaticSize.X,
		TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order, Parent = info})
end
local infoXYZ, infoBPS, infoPlayers, infoTime = infoLine(1), infoLine(2), infoLine(3), infoLine(4)
makeDraggable(info, info, canDragHud)

---------------------------------------------------------------- Keystrokes
local keysFrame = create("Frame", {Name = "Keystrokes", Position = UDim2.fromOffset(10, 130), Size = UDim2.fromOffset(98, 92),
	BackgroundTransparency = 1, Visible = false, Parent = gui})
local keys = {}
local function makeKey(name, x, y, w)
	local frame = create("Frame", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 30),
		BackgroundColor3 = THEME.Bg, Parent = keysFrame}, {corner(5)})
	text({Text = name, Font = FONT_BOLD, TextSize = 12, Size = UDim2.fromScale(1, 1), Parent = frame})
	keys[name] = {frame = frame, on = false}
end
makeKey("W", 34, 0, 30)
makeKey("A", 0, 34, 30)
makeKey("S", 34, 34, 30)
makeKey("D", 68, 34, 30)
makeKey("SPACE", 0, 68, 98)
makeDraggable(keysFrame, keysFrame, canDragHud)
local function setKey(name, on)
	local k = keys[name]
	if k.on == on then return end
	k.on = on
	tween(k.frame, 0.12, {BackgroundColor3 = on and THEME.Accent1 or THEME.Bg})
end

---------------------------------------------------------------- ArrayList
local arrayFrame = create("Frame", {Name = "ArrayList", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.fromOffset(220, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = gui},
	{create("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder})})
makeDraggable(arrayFrame, arrayFrame, canDragHud)
local arrayRows = {}

local function arrayRefresh()
	local al = Modules.ArrayList
	if not (al and al._ready) then return end
	local v = al.Values
	local size = v["Размер текста"]
	local h = size + 8
	local list = {}
	for _, m in pairs(Modules) do
		local row = arrayRows[m]
		if not row then
			local frame = create("Frame", {Size = UDim2.fromOffset(0, 0), BackgroundColor3 = THEME.Bg, BorderSizePixel = 0,
				ClipsDescendants = true, Visible = false, Parent = arrayFrame})
			local bar = create("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = frame}, {accentGradient(90)})
			local grad = accentGradient()
			local label = text({Text = m.Name, Font = FONT_BOLD, TextColor3 = WHITE, Parent = frame}, {grad})
			row = {frame = frame, bar = bar, label = label, grad = grad}
			arrayRows[m] = row
		end
		row.w = textWidth(m.Name, size, FONT_BOLD) + 16
		row.label.TextSize = size
		row.label.Size = UDim2.new(1, -2, 0, h)
		row.frame.BackgroundTransparency = v["Фон"] and 0.2 or 1
		row.bar.Visible = v["Полоска"] == true
		table.insert(list, m)
	end
	if v["Сортировка"] == "По алфавиту" then
		table.sort(list, function(a, b) return a.Name < b.Name end)
	else
		table.sort(list, function(a, b)
			local wa, wb = arrayRows[a].w, arrayRows[b].w
			if wa == wb then return a.Name < b.Name end
			return wa > wb
		end)
	end
	for i, m in ipairs(list) do
		local row = arrayRows[m]
		row.frame.LayoutOrder = i
		if m.Enabled then
			row.frame.Visible = true
			tween(row.frame, 0.25, {Size = UDim2.fromOffset(row.w, h)})
		elseif row.frame.Visible then
			tween(row.frame, 0.25, {Size = UDim2.fromOffset(row.w, 0)})
			task.delay(0.25, function() if not m.Enabled then row.frame.Visible = false end end)
		end
	end
end

---------------------------------------------------------------- Уведомления
local notifHolder = create("Frame", {AnchorPoint = Vector2.new(1, 1),
	-- на телефоне выше кнопки прыжка
	Position = IS_MOBILE and UDim2.new(1, -10, 1, -170) or UDim2.new(1, -10, 1, -10),
	Size = UDim2.fromOffset(210, 300), BackgroundTransparency = 1, Parent = gui},
	{create("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder})})

local function notify(title, on)
	local nm = Modules.Notifications
	if not (nm and nm.Enabled) then return end
	local life = nm.Values["Время"]
	local holder = create("Frame", {Size = UDim2.fromOffset(210, 40), BackgroundTransparency = 1, Parent = notifHolder})
	local box = create("Frame", {Position = UDim2.fromOffset(230, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg,
		ClipsDescendants = true, Parent = holder}, {corner(6)})
	text({Text = title, Font = FONT_BOLD, Position = UDim2.fromOffset(11, 6), Size = UDim2.new(1, -22, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	text({Text = on and "включён" or "выключен", TextSize = 11, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(11, 21),
		Size = UDim2.new(1, -22, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	local bar = create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = THEME.Accent1, BorderSizePixel = 0, Parent = box})
	tween(box, 0.35, {Position = UDim2.fromOffset(0, 0)})
	TweenService:Create(bar, TweenInfo.new(life, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 1)}):Play()
	task.delay(life, function()
		tween(box, 0.35, {Position = UDim2.fromOffset(230, 0)})
		task.wait(0.35)
		holder:Destroy()
	end)
end

---------------------------------------------------------------- Target HUD
local thHolder = create("Frame", {Name = "TargetHUD", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 70),
	Size = UDim2.fromOffset(210, 60), BackgroundTransparency = 1, Parent = gui})
local thScale = create("UIScale", {Scale = 0.9, Parent = thHolder})
local thGroup = create("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, GroupTransparency = 1,
	Parent = thHolder}, {corner(8)})
local thAvatar = create("ImageLabel", {Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = THEME.Row, Parent = thGroup}, {corner(6)})
local thLetter = text({Text = "", Font = FONT_BOLD, TextSize = 18, Size = UDim2.fromScale(1, 1), Parent = thAvatar})
local thName = text({Text = "", Font = FONT_BOLD, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Parent = thGroup})
local thSub = text({Text = "", TextSize = 11, TextColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Left, Parent = thGroup})
local thBar = create("Frame", {BackgroundColor3 = THEME.Row, Parent = thGroup}, {corner(3)})
local thGhost = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.65,
	Parent = thBar}, {corner(3)})
local thFill = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, Parent = thBar},
	{corner(3), accentGradient()})
makeDraggable(thHolder, thHolder, canDragHud)

local function layoutTargetHUD(withAvatar)
	local x = withAvatar and 60 or 12
	thAvatar.Visible = withAvatar
	thHolder.Size = UDim2.fromOffset(withAvatar and 210 or 170, 60)
	thName.Position, thName.Size = UDim2.fromOffset(x, 9), UDim2.new(1, -x - 12, 0, 16)
	thSub.Position, thSub.Size = UDim2.fromOffset(x, 26), UDim2.new(1, -x - 12, 0, 12)
	thBar.Position, thBar.Size = UDim2.fromOffset(x, 44), UDim2.new(1, -x - 12, 0, 6)
end

local thShown, thCurrent, thFrac = false, nil, -1
local thumbCache = {}
local function setTHVisible(v)
	if v == thShown then return end
	thShown = v
	tween(thGroup, 0.25, {GroupTransparency = v and 0 or 1})
	tween(thScale, 0.25, {Scale = v and 1 or 0.9})
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
	thSub.Text = string.format("%.1f HP   %.1f m", h.Health, dist)
end

---------------------------------------------------------------- Target ESP
local espBillboard = create("BillboardGui", {Size = UDim2.fromScale(5, 5), AlwaysOnTop = true, LightInfluence = 0,
	Enabled = false, ResetOnSpawn = false, Parent = playerGui})
local espSquare = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.6, 0.6), BackgroundTransparency = 1, Parent = espBillboard}, {corner(8)})
local espSquareStroke = create("UIStroke", {Color = WHITE, Thickness = 2.5, Parent = espSquare}, {accentGradient(45)})
local espFlash = create("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 60, 60),
	BackgroundTransparency = 1, Parent = espSquare}, {corner(8)})

local GHOSTS, GHOST_LEN = 3, 12
local RING_N, RING_TAIL = 28, 3
local FAR = CFrame.new(0, -1e5, 0)
local espParts, espMode, espCount, espHidden = {}, "none", 0, true
local espFlashUntil = 0

local function espEnsure(n)
	while #espParts < n do
		table.insert(espParts, fxPart({Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Transparency = 1,
			CFrame = FAR, Parent = fxFolder}))
	end
end

local function espColor(a)
	if os.clock() < espFlashUntil then return Color3.fromRGB(255, 60, 60) end
	return THEME.Accent1:Lerp(THEME.Accent2, a)
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
				p.Size = Vector3.one * (0.5 * (1 - a) + 0.08)
				p.Color = espColor(a)
				p.Transparency = 0.1 + a * 0.8
			end
		end
		espCount = GHOSTS * GHOST_LEN
	elseif mode == "Кольцо" then
		espEnsure(RING_N * RING_TAIL)
		for r = 0, RING_TAIL - 1 do
			for i = 0, RING_N - 1 do
				local p = espParts[r * RING_N + i + 1]
				p.Size = Vector3.one * (0.22 - r * 0.05)
				p.Color = espColor(math.abs(i / RING_N * 2 - 1))
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

local espClock = 0
local function espUpdate(targetRoot, dt)
	local v = Modules.TargetESP.Values
	local mode = v["Режим"]
	if mode ~= espMode then espConfigure(mode) end
	if not targetRoot then espHide() return end
	espClock += dt * v["Скорость"]
	local t, size = espClock, v["Размер"]

	if mode == "Квадрат" then
		espBillboard.Adornee = targetRoot
		espBillboard.Enabled = true
		espSquare.Rotation = (t * 110) % 360
		local s = (0.5 + math.sin(t * 4) * 0.04) * size / 2
		espSquare.Size = UDim2.fromScale(s, s)
		espSquareStroke.Thickness = v["Толщина"]
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
				table.insert(cfs, CFrame.new(pos + Vector3.new(math.cos(ang) * size, h, math.sin(ang) * size)))
			end
		end
	else
		for r = 0, RING_TAIL - 1 do
			local y = -0.6 + math.sin(t * 2 - r * 0.15) * 2.1
			for i = 0, RING_N - 1 do
				local ang = i / RING_N * math.pi * 2 + t * 0.6
				table.insert(parts, espParts[r * RING_N + i + 1])
				table.insert(cfs, CFrame.new(pos + Vector3.new(math.cos(ang) * size, y, math.sin(ang) * size)))
			end
		end
	end
	workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

---------------------------------------------------------------- Hit particles
local function hitEffect(pos, damage)
	local v = Modules.HitParticles.Values
	local p = fxPart({Transparency = 1, Size = Vector3.one * 0.2, CFrame = CFrame.new(pos), Parent = fxFolder})
	local s = v["Размер"]
	local pe = create("ParticleEmitter", {
		Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), LightEmission = 1,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, s), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(8, 16),
		SpreadAngle = Vector2.new(180, 180), Drag = 4, Acceleration = Vector3.new(0, -8, 0), Rate = 0, Parent = p,
	})
	pe:Emit(v["Количество"])
	if v["Цифры урона"] then
		local bb = create("BillboardGui", {Size = UDim2.fromOffset(90, 30), AlwaysOnTop = true, LightInfluence = 0,
			StudsOffset = Vector3.new(math.random(-10, 10) / 10, 1.5, 0), Parent = p})
		local lbl = text({Text = string.format("-%.1f", damage), Font = FONT_BOLD, TextSize = 18, TextColor3 = WHITE,
			TextStrokeTransparency = 0.6, Size = UDim2.fromScale(1, 1), Parent = bb}, {accentGradient()})
		tween(bb, 1, {StudsOffset = bb.StudsOffset + Vector3.new(0, 2.5, 0)})
		TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.5),
			{TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	end
	Debris:AddItem(p, 1.5)
end

local function onTargetDamaged(damage, targetRoot)
	if Modules.HitParticles.Enabled and targetRoot then hitEffect(targetRoot.Position, damage) end
	local esp = Modules.TargetESP
	if esp.Enabled and esp.Values["Вспышка при ударе"] then
		espFlash.BackgroundTransparency = 0.5
		tween(espFlash, 0.4, {BackgroundTransparency = 1})
		espFlashUntil = os.clock() + 0.25
		if espMode ~= "Квадрат" then
			espConfigure(espMode)
			task.delay(0.3, function() if espMode ~= "none" then espConfigure(espMode) end end)
		end
	end
end

---------------------------------------------------------------- Crosshair
local crosshair = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Visible = false, Parent = overlay})
local chStrokes = {}
local function chPiece(anchor)
	local f = flat(create("Frame", {AnchorPoint = anchor, BorderSizePixel = 0, Parent = crosshair}), "BackgroundColor3")
	table.insert(chStrokes, create("UIStroke", {Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = f}))
	return f
end
local chTop, chBottom = chPiece(Vector2.new(0.5, 1)), chPiece(Vector2.new(0.5, 0))
local chLeft, chRight = chPiece(Vector2.new(1, 0.5)), chPiece(Vector2.new(0, 0.5))
local chDot = chPiece(Vector2.new(0.5, 0.5))

---------------------------------------------------------------- эффекты Lighting (локальные)
local blur  = create("BlurEffect", {Size = 0, Parent = Lighting})
local cc    = create("ColorCorrectionEffect", {Enabled = false, Parent = Lighting})
local bloom = create("BloomEffect", {Enabled = false, Parent = Lighting})

---------------------------------------------------------------- косметика
local function clearObj(m)
	if not m._obj then return end
	for _, o in ipairs(m._obj) do
		if typeof(o) == "Instance" then o:Destroy() else o:Disconnect() end
	end
	m._obj = nil
end

-- Треугольник из двух клиньев: из таких собирается гладкий конус шляпы
local function setTriangle(a, b, c, w1, w2)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	w1.Size = Vector3.new(0.02, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back)
	w2.Size = Vector3.new(0.02, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back)
end

local HAT_SEGMENTS = 32
local HAT_MATERIALS = {["Матовый"] = Enum.Material.SmoothPlastic, ["Неон"] = Enum.Material.Neon}

local function buildChinaHat(m, c)
	local head = c:FindFirstChild("Head")
	if not head then return end
	local v = m.Values
	local model = create("Model", {Name = "ChinaHat"})
	local radius, baseY = v["Радиус"], head.Size.Y / 2 + v["Посадка"]
	local hcf = head.CFrame
	local apex = hcf * Vector3.new(0, baseY + v["Высота"], 0)
	local function rim(i)
		local a = i / HAT_SEGMENTS * math.pi * 2
		return hcf * Vector3.new(math.cos(a) * radius, baseY, math.sin(a) * radius)
	end
	local function attach(p)
		p.Anchored, p.Massless, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, true, false, false, false, false
		create("WeldConstraint", {Part0 = head, Part1 = p, Parent = p})
		p.Parent = model
	end
	m._segs = {}
	for i = 0, HAT_SEGMENTS - 1 do
		local a, b = rim(i), rim(i + 1)
		local seg = {}
		local w1, w2 = Instance.new("WedgePart"), Instance.new("WedgePart")
		setTriangle(apex, a, b, w1, w2)
		for _, w in ipairs({w1, w2}) do
			w.Material = HAT_MATERIALS[v["Материал"]] or Enum.Material.SmoothPlastic
			w.Transparency = v["Прозрачность"]
			attach(w)
			table.insert(seg, w)
		end
		if v["Обводка"] then
			local edge = Instance.new("Part")
			edge.Material = Enum.Material.Neon
			edge.Size = Vector3.new(0.04, 0.04, (b - a).Magnitude + 0.02)
			edge.CFrame = CFrame.lookAt((a + b) / 2, b)
			attach(edge)
			table.insert(seg, edge)
		end
		m._segs[i + 1] = seg
	end
	model.Parent = c
	m._obj = {model}
end

local function updateHatColors(m, t)
	if not (m._obj and m._segs) then return end
	local shift = m.Values["Перелив"] and t * 1.5 or 0
	for i, seg in ipairs(m._segs) do
		local color = THEME.Accent1:Lerp(THEME.Accent2, (math.sin(i / HAT_SEGMENTS * math.pi * 2 + shift) + 1) / 2)
		for _, p in ipairs(seg) do p.Color = color end
	end
end

local function spawnJumpCircle(r)
	local v = Modules.JumpCircles.Values
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char, fxFolder}
	local hit = workspace:Raycast(r.Position, Vector3.new(0, -12, 0), params)
	local y = hit and hit.Position.Y + 0.06 or r.Position.Y - 3
	local p = fxPart({Transparency = 1, Size = Vector3.new(1, 0.05, 1), CFrame = CFrame.new(r.Position.X, y, r.Position.Z),
		Parent = fxFolder})
	local sg = create("SurfaceGui", {Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = Vector2.new(256, 256), LightInfluence = 0, Parent = p})
	local ring = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -28, 1, -28), BackgroundColor3 = WHITE, BackgroundTransparency = v["Заливка"] and 0.8 or 1,
		Parent = sg}, {round(), accentGradient(45)})
	local rs = create("UIStroke", {Thickness = 10, Color = WHITE, Parent = ring}, {accentGradient(45)})
	local life, size = v["Время"], v["Размер"]
	tween(p, life, {Size = Vector3.new(size, 0.05, size)})
	tween(rs, life, {Transparency = 1})
	tween(ring, life, {BackgroundTransparency = 1})
	Debris:AddItem(p, life + 0.1)
end

---------------------------------------------------------------- модули
-- Sync(m) вызывается при включении/выключении и при любом изменении настроек.
-- Apply(m, char, hum, root) пересоздаёт объекты на персонаже (и после респавна).
local function saveOnce(m, getter)
	if not m._saved then m._saved = getter() end
end

local applyTheme
local currentTheme = THEMES[1].Name

local CATEGORIES = {
	{Name = "Render", Modules = {
		{Name = "Watermark", Desc = "Название клиента, ник, FPS, пинг и время", Default = true,
			Settings = {
				{Type = "Mode", Name = "Стиль", Options = {"Плашки", "Панель", "Текст"}, Default = 1},
				{Type = "Check", Name = "Ник", Default = true},
				{Type = "Check", Name = "FPS", Default = true},
				{Type = "Check", Name = "Пинг", Default = true},
				{Type = "Check", Name = "Время", Default = false},
			},
			Sync = function(m)
				local v = m.Values
				watermark.Visible = m.Enabled
				local style = v["Стиль"]
				watermark.BackgroundTransparency = style == "Панель" and 0 or 1
				wmLine.Visible = style == "Панель"
				wmLayout.Padding = UDim.new(0, style == "Плашки" and 4 or 0)
				for _, seg in pairs(wmSegs) do
					seg.frame.BackgroundTransparency = style == "Плашки" and 0 or 1
					seg.label.TextStrokeTransparency = style == "Текст" and 0.5 or 1
				end
				wmSegs.nick.frame.Visible = v["Ник"] == true
				wmSegs.fps.frame.Visible = v["FPS"] == true
				wmSegs.ping.frame.Visible = v["Пинг"] == true
				wmSegs.time.frame.Visible = v["Время"] == true
			end},
		{Name = "ArrayList", Desc = "Список включённых модулей", Default = true,
			Settings = {
				{Type = "Mode", Name = "Сортировка", Options = {"По длине", "По алфавиту"}, Default = 1},
				{Name = "Размер текста", Min = 10, Max = 18, Default = 13},
				{Type = "Check", Name = "Фон", Default = true},
				{Type = "Check", Name = "Полоска", Default = true},
			},
			Sync = function(m) arrayFrame.Visible = m.Enabled; arrayRefresh() end},
		{Name = "Information", Desc = "Координаты, скорость, число игроков",
			Settings = {
				{Type = "Check", Name = "Координаты", Default = true},
				{Type = "Check", Name = "Скорость", Default = true},
				{Type = "Check", Name = "Игроки", Default = true},
				{Type = "Check", Name = "Время", Default = false},
				{Type = "Check", Name = "Фон", Default = true},
			},
			Sync = function(m)
				local v = m.Values
				info.Visible = m.Enabled
				info.BackgroundTransparency = v["Фон"] and 0 or 1
				infoXYZ.Visible, infoBPS.Visible = v["Координаты"] == true, v["Скорость"] == true
				infoPlayers.Visible, infoTime.Visible = v["Игроки"] == true, v["Время"] == true
			end},
		{Name = "Keystrokes", Desc = "Показывает нажатые клавиши движения",
			Settings = {{Type = "Check", Name = "Пробел", Default = true}},
			Sync = function(m)
				keysFrame.Visible = m.Enabled
				keys.SPACE.frame.Visible = m.Values["Пробел"] == true
			end},
		{Name = "TargetHUD", Desc = "Панель с HP ближайшей цели", Default = true,
			Settings = {
				{Name = "Дистанция", Min = 10, Max = 150, Default = 40},
				{Type = "Check", Name = "Аватар", Default = true},
				{Type = "Check", Name = "Только игроки", Default = false},
			},
			Sync = function(m) layoutTargetHUD(m.Values["Аватар"] == true) end},
		{Name = "TargetESP", Desc = "Анимированная метка на цели", Default = true,
			Settings = {
				{Type = "Mode", Name = "Режим", Options = {"Призраки", "Кольцо", "Квадрат"}, Default = 1},
				{Name = "Скорость", Min = 0.3, Max = 3, Default = 1, Step = 0.1},
				{Name = "Размер", Min = 1, Max = 4, Default = 2, Step = 0.1},
				{Name = "Толщина", Min = 1, Max = 6, Default = 2.5, Step = 0.5},
				{Type = "Check", Name = "Вспышка при ударе", Default = true},
			},
			Sync = function(m) if not m.Enabled then espHide(); espConfigure("none") end end},
		{Name = "Crosshair", Desc = "Свой прицел по центру экрана",
			Settings = {
				{Name = "Отступ", Min = 0, Max = 20, Default = 5},
				{Name = "Длина", Min = 2, Max = 20, Default = 7},
				{Name = "Толщина", Min = 1, Max = 6, Default = 2},
				{Type = "Check", Name = "Динамический", Default = true},
				{Type = "Check", Name = "Вращение", Default = false},
				{Type = "Check", Name = "Точка", Default = false},
				{Type = "Check", Name = "Обводка", Default = true},
			},
			Sync = function(m)
				crosshair.Visible = m.Enabled
				chDot.Visible = m.Values["Точка"] == true
				for _, s in ipairs(chStrokes) do s.Enabled = m.Values["Обводка"] == true end
			end},
	}},
	{Name = "Visuals", Modules = {
		{Name = "ChinaHat", Desc = "Конусная шляпа над головой", Default = true,
			Settings = {
				{Type = "Mode", Name = "Материал", Options = {"Матовый", "Неон"}, Default = 1},
				{Name = "Радиус", Min = 0.8, Max = 3, Default = 1.5, Step = 0.05},
				{Name = "Высота", Min = 0.2, Max = 2, Default = 0.7, Step = 0.05},
				{Name = "Посадка", Min = -0.3, Max = 1, Default = 0.15, Step = 0.05},
				{Name = "Прозрачность", Min = 0, Max = 0.9, Default = 0.3, Step = 0.05},
				{Type = "Check", Name = "Обводка", Default = false},
				{Type = "Check", Name = "Перелив", Default = true},
			},
			Apply = buildChinaHat},
		{Name = "Trails", Desc = "Шлейф за персонажем",
			Settings = {
				{Name = "Длина", Min = 0.1, Max = 3, Default = 0.6, Step = 0.1},
				{Name = "Ширина", Min = 0.2, Max = 4, Default = 1.8, Step = 0.1},
				{Name = "Прозрачность", Min = 0, Max = 0.9, Default = 0.3, Step = 0.05},
			},
			Apply = function(m, _, _, r)
				local v = m.Values
				local a0 = create("Attachment", {Position = Vector3.new(0, v["Ширина"] / 2, 0), Parent = r})
				local a1 = create("Attachment", {Position = Vector3.new(0, -v["Ширина"] / 2, 0), Parent = r})
				local trail = create("Trail", {Attachment0 = a0, Attachment1 = a1,
					Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), Transparency = NumberSequence.new(v["Прозрачность"], 1),
					Lifetime = v["Длина"], LightEmission = 0.6, FaceCamera = true, Parent = r})
				m._obj = {trail, a0, a1}
			end},
		{Name = "JumpCircles", Desc = "Круг на земле при прыжке", Default = true,
			Settings = {
				{Name = "Размер", Min = 3, Max = 16, Default = 8},
				{Name = "Время", Min = 0.3, Max = 3, Default = 1, Step = 0.1},
				{Type = "Check", Name = "Заливка", Default = true},
			},
			Apply = function(m, _, h, r)
				m._obj = {h.StateChanged:Connect(function(_, new)
					if new == Enum.HumanoidStateType.Jumping then spawnJumpCircle(r) end
				end)}
			end},
		{Name = "HitParticles", Desc = "Частицы и цифры урона, когда цель теряет HP", Default = true,
			Settings = {
				{Name = "Количество", Min = 5, Max = 60, Default = 25},
				{Name = "Размер", Min = 0.1, Max = 1, Default = 0.35, Step = 0.05},
				{Type = "Check", Name = "Цифры урона", Default = true},
			}},
		{Name = "WorldParticles", Desc = "Частицы в воздухе вокруг тебя",
			Settings = {
				{Type = "Mode", Name = "Движение", Options = {"Парение", "Вверх", "Снег"}, Default = 1},
				{Name = "Количество", Min = 5, Max = 120, Default = 40},
				{Name = "Размер", Min = 0.05, Max = 0.6, Default = 0.2, Step = 0.05},
			},
			Apply = function(m, _, _, r)
				local v = m.Values
				local accel = ({["Парение"] = Vector3.zero, ["Вверх"] = Vector3.new(0, 1, 0), ["Снег"] = Vector3.new(0, -2, 0)})[v["Движение"]]
				local p = fxPart({Transparency = 1, Size = Vector3.new(50, 24, 50), CFrame = CFrame.new(r.Position), Parent = fxFolder})
				create("ParticleEmitter", {
					Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), LightEmission = 1, Rate = v["Количество"],
					Size = NumberSequence.new(v["Размер"]), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.3, 1.2),
					SpreadAngle = Vector2.new(180, 180), Acceleration = accel or Vector3.zero,
					Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0),
						NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1)}),
					Parent = p,
				})
				m._obj = {p}
			end},
		{Name = "SelfChams", Desc = "Подсветка своего персонажа",
			Settings = {
				{Name = "Заливка", Min = 0, Max = 1, Default = 0.6, Step = 0.05},
				{Name = "Контур", Min = 0, Max = 1, Default = 0, Step = 0.05},
			},
			Apply = function(m, c)
				m._obj = {create("Highlight", {FillColor = THEME.Accent1, OutlineColor = THEME.Accent2,
					FillTransparency = m.Values["Заливка"], OutlineTransparency = m.Values["Контур"],
					DepthMode = Enum.HighlightDepthMode.Occluded, Parent = c})}
			end},
	}},
	{Name = "World", Modules = {
		{Name = "CustomFOV", Desc = "Угол обзора камеры",
			Settings = {{Name = "FOV", Min = 30, Max = 120, Default = 90}},
			Sync = function(m)
				local cam = workspace.CurrentCamera
				if m.Enabled then
					saveOnce(m, function() return cam.FieldOfView end)
				elseif m._saved then
					cam.FieldOfView = m._saved
					m._saved = nil
				end
			end},
		{Name = "TimeChanger", Desc = "Время суток",
			Settings = {{Name = "Время", Min = 0, Max = 24, Default = 0, Step = 0.5}},
			Sync = function(m)
				if m.Enabled then
					saveOnce(m, function() return Lighting.ClockTime end)
				elseif m._saved then
					Lighting.ClockTime = m._saved
					m._saved = nil
				end
			end},
		{Name = "ColorCorrection", Desc = "Насыщенность, контраст, яркость, оттенок",
			Settings = {
				{Name = "Насыщенность", Min = -1, Max = 1, Default = 0.25, Step = 0.05},
				{Name = "Контраст", Min = -1, Max = 1, Default = 0.1, Step = 0.05},
				{Name = "Яркость", Min = -0.5, Max = 0.5, Default = 0, Step = 0.05},
				{Name = "Оттенок темы", Min = 0, Max = 0.6, Default = 0, Step = 0.05},
			},
			Sync = function(m)
				local v = m.Values
				cc.Enabled = m.Enabled
				cc.Saturation, cc.Contrast, cc.Brightness = v["Насыщенность"], v["Контраст"], v["Яркость"]
				cc.TintColor = WHITE:Lerp(THEME.Accent1, v["Оттенок темы"])
			end},
		{Name = "Fog", Desc = "Убирает туман или красит его в цвет темы",
			Settings = {
				{Type = "Mode", Name = "Режим", Options = {"Убрать", "Цвет темы"}, Default = 1},
				{Name = "Дальность", Min = 50, Max = 1000, Default = 300, Step = 10},
			},
			Sync = function(m)
				if m.Enabled then
					saveOnce(m, function()
						local atm = Lighting:FindFirstChildOfClass("Atmosphere")
						-- Atmosphere перекрывает обычный туман, на время убираем её
						if atm then atm.Parent = nil end
						return {Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor, atm}
					end)
					Lighting.FogStart = 0
					if m.Values["Режим"] == "Убрать" then
						Lighting.FogEnd = 1e6
					else
						Lighting.FogEnd, Lighting.FogColor = m.Values["Дальность"], THEME.Accent1
					end
				elseif m._saved then
					local s = m._saved
					Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor = s[1], s[2], s[3]
					if s[4] then s[4].Parent = Lighting end
					m._saved = nil
				end
			end},
		{Name = "FullBright", Desc = "Равномерное освещение без тёмных мест",
			Settings = {
				{Name = "Яркость", Min = 1, Max = 5, Default = 2, Step = 0.1},
				{Type = "Check", Name = "Без теней", Default = true},
			},
			Sync = function(m)
				if m.Enabled then
					saveOnce(m, function()
						return {Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows}
					end)
					Lighting.Brightness = m.Values["Яркость"]
					Lighting.Ambient, Lighting.OutdoorAmbient = WHITE, WHITE
					Lighting.GlobalShadows = not m.Values["Без теней"]
				elseif m._saved then
					local s = m._saved
					Lighting.Brightness, Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.GlobalShadows = s[1], s[2], s[3], s[4]
					m._saved = nil
				end
			end},
		{Name = "Bloom", Desc = "Свечение ярких объектов",
			Settings = {
				{Name = "Сила", Min = 0, Max = 3, Default = 1, Step = 0.1},
				{Name = "Размер", Min = 5, Max = 56, Default = 24},
				{Name = "Порог", Min = 0, Max = 3, Default = 1, Step = 0.1},
			},
			Sync = function(m)
				bloom.Enabled = m.Enabled
				bloom.Intensity, bloom.Size, bloom.Threshold = m.Values["Сила"], m.Values["Размер"], m.Values["Порог"]
			end},
	}},
	{Name = "Client", Modules = {
		{Name = "ClientTheme", Desc = "Цвет интерфейса и всех эффектов", Default = true,
			Settings = {
				{Type = "Mode", Name = "Тема", Options = THEME_NAMES, Default = 1},
				{Name = "Скорость перелива", Min = 0, Max = 4, Default = 1.5, Step = 0.1},
			},
			Sync = function(m)
				local name = m.Enabled and m.Values["Тема"] or THEMES[1].Name
				if name ~= currentTheme then applyTheme(name) end
			end},
		{Name = "MenuBlur", Desc = "Размытие фона при открытом меню", Default = true,
			Settings = {{Name = "Сила", Min = 0, Max = 30, Default = 14}},
			Sync = function(m) tween(blur, 0.25, {Size = (m.Enabled and menuOpened) and m.Values["Сила"] or 0}) end},
		{Name = "Notifications", Desc = "Уведомления о включении модулей", Default = true,
			Settings = {{Name = "Время", Min = 0.5, Max = 5, Default = 1.5, Step = 0.1}}},
	}},
}

local function syncModule(m)
	if m.Apply then
		clearObj(m)
		if m.Enabled and char and root then m.Apply(m, char, hum, root) end
	end
	if m.Sync then m.Sync(m) end
end

applyTheme = function(name)
	currentTheme = name
	for _, t in ipairs(THEMES) do
		if t.Name == name then THEME.Accent1, THEME.Accent2 = t.A, t.B end
	end
	local seq = ColorSequence.new(THEME.Accent1, THEME.Accent2)
	for g in pairs(gradients) do
		if g.Parent then g.Color = seq else gradients[g] = nil end
	end
	for i = #flats, 1, -1 do
		local f = flats[i]
		if f[1].Parent then f[1][f[2]] = THEME.Accent1 else table.remove(flats, i) end
	end
	-- эффекты пересоздаются в новых цветах
	for _, m in pairs(Modules) do
		if m.Name ~= "ClientTheme" and m._ready then syncModule(m) end
	end
	if espMode ~= "none" then espConfigure(espMode) end
end

local function setModule(m, on, silent)
	m.Enabled = on
	m._paint()
	syncModule(m)
	arrayRefresh()
	if not silent then notify(m.Name, on) end
end

---------------------------------------------------------------- окно меню
local MENU_W, MENU_H = 620, 370
local ROW_H = 34
local menuHolder = create("Frame", {Size = UDim2.fromOffset(MENU_W, MENU_H), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui})
local fitScale = create("UIScale", {Parent = menuHolder})
local main = create("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.Bg, GroupTransparency = 1,
	Parent = menuHolder}, {corner(10)})
local mainScale = create("UIScale", {Scale = 0.95, Parent = main})
-- Освобождает курсор в first-person, пока меню открыто
create("TextButton", {Modal = true, Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = main})

local function updateFit()
	local vp = workspace.CurrentCamera.ViewportSize
	fitScale.Scale = math.min(1, (vp.X - 20) / MENU_W, (vp.Y - 30) / MENU_H)
end
updateFit()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFit)

-- Боковая панель
local sidebar = create("Frame", {Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = THEME.Side, BorderSizePixel = 0, Parent = main})
text({Text = CLIENT_NAME, Font = FONT_BOLD, TextSize = 18, TextColor3 = WHITE, Position = UDim2.fromOffset(16, 14),
	Size = UDim2.new(1, -16, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = sidebar}, {accentGradient()})
local catList = create("Frame", {Position = UDim2.fromOffset(8, 54), Size = UDim2.new(1, -16, 1, -100),
	BackgroundTransparency = 1, Parent = sidebar},
	{create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})})
text({Text = player.Name, TextSize = 12, TextColor3 = THEME.SubText, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -12), Size = UDim2.new(1, -24, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Parent = sidebar})

-- Правая часть
local content = create("Frame", {Position = UDim2.fromOffset(140, 0), Size = UDim2.new(1, -140, 1, 0),
	BackgroundTransparency = 1, Parent = main})
local header = text({Text = "", Font = FONT_BOLD, TextSize = 15, Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(1, -220, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = content})
local search = create("TextBox", {PlaceholderText = "Поиск", Text = "", ClearTextOnFocus = false, Font = FONT, TextSize = 12,
	TextColor3 = THEME.Text, PlaceholderColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = THEME.Row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 12),
	Size = UDim2.fromOffset(140, 26), Parent = content},
	{corner(6), create("UIPadding", {PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})})
local closeBtn = create("TextButton", {Text = "x", Font = FONT_BOLD, TextSize = 13, TextColor3 = THEME.SubText,
	AutoButtonColor = false, BackgroundColor3 = THEME.Row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(26, 26), Parent = content}, {corner(6)})
local footer = text({Text = "", TextSize = 11, TextColor3 = THEME.SubText, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 14, 1, -8), Size = UDim2.new(1, -28, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, Parent = content})
local DEFAULT_HINT = IS_MOBILE and "Три точки на модуле открывают настройки" or "ПКМ или три точки на модуле открывают настройки"

---------------------------------------------------------------- виджеты настроек
local WIDGET_H = {Slider = 34, Mode = 28, Check = 24}

local function onSettingChanged(m)
	if m._ready then
		syncModule(m)
	end
end

local function makeSlider(parent, page, m, s, order)
	local holder = create("Frame", {Size = UDim2.new(1, 0, 0, WIDGET_H.Slider), BackgroundTransparency = 1,
		LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(0.7, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local valueLbl = text({Text = "", TextSize = 12, Position = UDim2.fromScale(0.7, 0), Size = UDim2.new(0.3, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Right, Parent = holder})
	local bar = create("Frame", {Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = THEME.Stroke, Parent = holder}, {corner(2)})
	local fill = flat(create("Frame", {Size = UDim2.fromScale(0, 1), Parent = bar}, {corner(2)}), "BackgroundColor3")
	local knob = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 10), BackgroundColor3 = THEME.Text, Parent = bar}, {round()})

	local step = s.Step or 1
	local fmt = step >= 1 and "%d" or (step >= 0.1 and "%.1f" or "%.2f")
	local function set(v)
		v = math.clamp(math.floor(v / step + 0.5) * step, s.Min, s.Max)
		if m.Values[s.Name] == v then return end
		m.Values[s.Name] = v
		local a = (v - s.Min) / (s.Max - s.Min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		valueLbl.Text = string.format(fmt, v)
		onSettingChanged(m)
	end
	set(s.Default)

	local function fromX(x)
		set(s.Min + (x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1) * (s.Max - s.Min))
	end
	trackDrag(holder, {
		Start = function(p) page.ScrollingEnabled = false; fromX(p.X) end,
		Move = function(p) fromX(p.X) end,
		End = function() page.ScrollingEnabled = true end,
	})
end

local function makeMode(parent, m, s, order)
	local holder = create("Frame", {Size = UDim2.new(1, 0, 0, WIDGET_H.Mode), BackgroundTransparency = 1,
		LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(0.45, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local btn = create("TextButton", {Text = "", Font = FONT, TextSize = 12, TextColor3 = THEME.Text, AutoButtonColor = false,
		BackgroundColor3 = THEME.Bg, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.55, 0, 0, 24), Parent = holder}, {corner(5), stroke()})
	local idx = s.Default or 1
	local function set(i)
		idx = i
		m.Values[s.Name] = s.Options[i]
		btn.Text = s.Options[i]
		onSettingChanged(m)
	end
	set(idx)
	btn.Activated:Connect(function() set(idx % #s.Options + 1) end)
end

local function makeCheck(parent, m, s, order)
	local holder = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, WIDGET_H.Check),
		BackgroundTransparency = 1, LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(1, -24, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local box = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = THEME.Bg, Parent = holder}, {corner(4), stroke()})
	local mark = flat(create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0), Parent = box}, {corner(2)}), "BackgroundColor3")
	local function set(v)
		m.Values[s.Name] = v
		tween(mark, 0.15, {Size = v and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0)})
		onSettingChanged(m)
	end
	set(s.Default == true)
	holder.Activated:Connect(function() set(not m.Values[s.Name]) end)
end

---------------------------------------------------------------- строки модулей
local function layoutPage(cat)
	local maxH = 0
	for c = 1, 2 do
		local h = 0
		for _, m in ipairs(cat.Modules) do
			if m._col == c and m._card.Visible then h += m._curH + 6 end
		end
		cat._cols[c].Size = UDim2.new(0.5, -3, 0, h)
		maxH = math.max(maxH, h)
	end
	cat._page.CanvasSize = UDim2.fromOffset(0, maxH + 4)
end

local function makeModule(cat, m, index)
	m.Values, m.Enabled = {}, false
	m._col = (index - 1) % 2 + 1
	m._curH = ROW_H
	Modules[m.Name] = m

	local card = create("Frame", {Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = THEME.Row, ClipsDescendants = true,
		LayoutOrder = index, Parent = cat._cols[m._col]}, {corner(6)})
	m._card = card
	local top = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, ROW_H),
		BackgroundTransparency = 1, Parent = card})
	local bar = flat(create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 14), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = top}), "BackgroundColor3")
	local title = text({Text = m.Name, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -50, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})

	m._paint = function()
		local on = m.Enabled
		tween(title, 0.2, {TextColor3 = on and THEME.Text or THEME.SubText})
		tween(bar, 0.2, {BackgroundTransparency = on and 0 or 1})
		tween(card, 0.2, {BackgroundColor3 = on and THEME.RowOn or THEME.Row})
	end

	top.Activated:Connect(function()
		footer.Text = m.Desc or ""
		setModule(m, not m.Enabled)
	end)
	top.MouseEnter:Connect(function() footer.Text = m.Desc or "" end)

	if m.Settings then
		local sh = 12
		local settingsFrame = create("Frame", {Position = UDim2.fromOffset(0, ROW_H), Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1, Parent = card}, {
			create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
			create("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2)}),
		})
		for i, s in ipairs(m.Settings) do
			local kind = s.Type or "Slider"
			if kind == "Mode" then makeMode(settingsFrame, m, s, i)
			elseif kind == "Check" then makeCheck(settingsFrame, m, s, i)
			else makeSlider(settingsFrame, cat._page, m, s, i) end
			sh += WIDGET_H[kind] + (i > 1 and 6 or 0)
		end
		settingsFrame.Size = UDim2.new(1, 0, 0, sh)

		-- три точки, крупная зона нажатия под палец
		local dots = create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(38, ROW_H), Parent = top})
		for i = -1, 1 do
			create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, i * 5, 0.5, 0),
				Size = UDim2.fromOffset(3, 3), BackgroundColor3 = THEME.SubText, Parent = dots}, {round()})
		end
		local open = false
		local function expand()
			open = not open
			footer.Text = m.Desc or ""
			m._curH = ROW_H + (open and sh or 0)
			tween(card, 0.25, {Size = UDim2.new(1, 0, 0, m._curH)})
			layoutPage(cat)
		end
		dots.Activated:Connect(expand)
		top.MouseButton2Click:Connect(expand)
	end
	m._ready = true
end

---------------------------------------------------------------- категории
local function selectCategory(cat)
	header.Text = cat.Name
	footer.Text = DEFAULT_HINT
	for _, c in ipairs(CATEGORIES) do
		local active = c == cat
		tween(c._btn, 0.2, {BackgroundTransparency = active and 0 or 1})
		tween(c._bar, 0.2, {BackgroundTransparency = active and 0 or 1})
		tween(c._lbl, 0.2, {TextColor3 = active and THEME.Text or THEME.SubText})
		c._page.Visible = active
	end
end

for i, cat in ipairs(CATEGORIES) do
	local btn = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Row, BackgroundTransparency = 1, LayoutOrder = i, Parent = catList}, {corner(6)})
	cat._btn = btn
	cat._bar = flat(create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(2, 14), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = btn}), "BackgroundColor3")
	cat._lbl = text({Text = cat.Name, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
	btn.Activated:Connect(function() selectCategory(cat) end)

	cat._page = create("ScrollingFrame", {Position = UDim2.fromOffset(14, 48), Size = UDim2.new(1, -24, 1, -78),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = THEME.Stroke,
		CanvasSize = UDim2.new(), Visible = false, Parent = content})
	cat._cols = {}
	for c = 1, 2 do
		cat._cols[c] = create("Frame", {Position = c == 1 and UDim2.fromOffset(0, 0) or UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.new(0.5, -3, 0, 0), BackgroundTransparency = 1, Parent = cat._page},
			{create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
	end
	for j, m in ipairs(cat.Modules) do makeModule(cat, m, j) end
	layoutPage(cat)
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	local q = search.Text:lower()
	for _, cat in ipairs(CATEGORIES) do
		for _, m in ipairs(cat.Modules) do
			m._card.Visible = q == "" or m.Name:lower():find(q, 1, true) ~= nil
		end
		layoutPage(cat)
	end
end)

-- Окно таскается за шапку (поиск и кнопка закрытия не перекрыты)
makeDraggable(menuHolder, create("Frame", {Size = UDim2.new(1, -200, 0, 46), BackgroundTransparency = 1, ZIndex = 2, Parent = main}))

---------------------------------------------------------------- открытие/закрытие
local function setMenu(state)
	menuOpened = state
	if state then
		updateFit()
		menuHolder.Visible = true
	end
	tween(main, 0.2, {GroupTransparency = state and 0 or 1})
	tween(mainScale, 0.2, {Scale = state and 1 or 0.95})
	syncModule(Modules.MenuBlur)
	if not state then
		task.delay(0.2, function() if not menuOpened then menuHolder.Visible = false end end)
	end
end

closeBtn.Activated:Connect(function() setMenu(false) end)
UIS.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == TOGGLE_KEY then setMenu(not menuOpened) end
end)

-- Кнопка открытия для телефона, её можно перетаскивать
local openBtn = create("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = THEME.Bg,
	AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.4, 0), Size = UDim2.fromOffset(42, 42), ZIndex = 10,
	Parent = gui}, {corner(10), stroke()})
text({Text = "N", Font = FONT_BOLD, TextSize = 18, TextColor3 = WHITE, Size = UDim2.fromScale(1, 1), ZIndex = 11,
	Parent = openBtn}, {accentGradient(45)})
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

local function findTarget(range, playersOnly)
	if not root then return nil end
	local best, bestD
	for h in pairs(humanoids) do
		local model = h.Parent
		if model and model ~= char and h.Health > 0 and (not playersOnly or Players:GetPlayerFromCharacter(model)) then
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
	wmSegs.fps.label.Text = string.format('%d <font color="%s">fps</font>', fps, SUB_HEX)
	wmSegs.ping.label.Text = string.format('%d <font color="%s">ms</font>', math.floor(player:GetNetworkPing() * 1000 + 0.5), SUB_HEX)
	wmSegs.time.label.Text = os.date("%H:%M")
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

	-- перелив градиента в названии клиента и в списке модулей
	local flow = t * Modules.ClientTheme.Values["Скорость перелива"]
	wmNameGrad.Offset = Vector2.new(math.sin(flow) * 0.5, 0)
	if arrayFrame.Visible then
		for _, row in pairs(arrayRows) do
			if row.frame.Visible then
				row.grad.Offset = Vector2.new(math.sin(flow + row.frame.LayoutOrder * 0.35) * 0.5, 0)
			end
		end
	end

	-- мир
	if Modules.CustomFOV.Enabled then workspace.CurrentCamera.FieldOfView = Modules.CustomFOV.Values.FOV end
	if Modules.TimeChanger.Enabled then Lighting.ClockTime = Modules.TimeChanger.Values["Время"] end

	-- косметика
	if Modules.ChinaHat.Enabled then updateHatColors(Modules.ChinaHat, t) end
	local wp = Modules.WorldParticles
	if wp.Enabled and wp._obj and root then wp._obj[1].CFrame = CFrame.new(root.Position) end

	-- цель
	local thv = Modules.TargetHUD.Values
	local needTarget = Modules.TargetHUD.Enabled or Modules.TargetESP.Enabled or Modules.HitParticles.Enabled
	searchT += dt
	if not needTarget then
		target = nil
	elseif searchT >= 0.1 then
		searchT = 0
		target = findTarget(thv["Дистанция"], thv["Только игроки"])
	end
	if target and (not target.Parent or target.Health <= 0) then target = nil end
	local tRoot = target and getRoot(target.Parent)
	if not tRoot then target = nil end

	if target ~= lastTarget then
		lastTarget, lastTargetHp = target, target and target.Health
	elseif target then
		local hp = target.Health
		if hp < lastTargetHp - 0.01 then onTargetDamaged(lastTargetHp - hp, tRoot) end
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

	if Modules.TargetESP.Enabled then espUpdate(tRoot, dt) end

	-- прицел
	if Modules.Crosshair.Enabled then
		local v = Modules.Crosshair.Values
		local speed = root and (root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude or 0
		local gap = v["Отступ"] + (v["Динамический"] and math.min(speed * 0.35, 12) or 0)
		local len, th = v["Длина"], v["Толщина"]
		chTop.Size, chTop.Position = UDim2.fromOffset(th, len), UDim2.fromOffset(0, -gap)
		chBottom.Size, chBottom.Position = UDim2.fromOffset(th, len), UDim2.fromOffset(0, gap)
		chLeft.Size, chLeft.Position = UDim2.fromOffset(len, th), UDim2.fromOffset(-gap, 0)
		chRight.Size, chRight.Position = UDim2.fromOffset(len, th), UDim2.fromOffset(gap, 0)
		chDot.Size = UDim2.fromOffset(th, th)
		crosshair.Rotation = v["Вращение"] and (crosshair.Rotation + dt * 90) % 360 or 0
	end

	-- клавиши: по направлению движения, поэтому работает и с джойстиком на телефоне
	if Modules.Keystrokes.Enabled and hum then
		local mv = workspace.CurrentCamera.CFrame:VectorToObjectSpace(hum.MoveDirection)
		setKey("W", mv.Z < -0.3)
		setKey("S", mv.Z > 0.3)
		setKey("A", mv.X < -0.3)
		setKey("D", mv.X > 0.3)
		setKey("SPACE", hum.Jump or UIS:IsKeyDown(Enum.KeyCode.Space))
	end

	-- информация
	infoT += dt
	if Modules.Information.Enabled and infoT >= 0.1 then
		infoT = 0
		local hex = "#" .. THEME.Accent1:ToHex()
		if root then
			local p = root.Position
			infoXYZ.Text = string.format('<font color="%s">XYZ</font>  %d, %d, %d', hex,
				math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
			infoBPS.Text = string.format('<font color="%s">BPS</font>  %.1f', hex,
				(root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude)
		end
		infoPlayers.Text = string.format('<font color="%s">Players</font>  %d', hex, #Players:GetPlayers())
		infoTime.Text = string.format('<font color="%s">Time</font>  %s', hex, os.date("%H:%M:%S"))
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
for _, m in pairs(Modules) do
	if m.Default then m.Enabled = true end
	m._paint()
end
for _, m in pairs(Modules) do syncModule(m) end
arrayRefresh()
if player.Character then task.spawn(onCharacter, player.Character) end
updateWatermark()
selectCategory(CATEGORIES[1])
setMenu(not IS_MOBILE)
