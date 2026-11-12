--[[ Nursultan-style menu (только визуалы)
     LocalScript -> StarterPlayer > StarterPlayerScripts
     RightShift — открыть/закрыть, ПКМ по модулю — настройки ]]

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local TextService  = game:GetService("TextService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CLIENT_NAME = "Nursultan"
local TOGGLE_KEY  = Enum.KeyCode.RightShift

local THEME = {
	Bg        = Color3.fromRGB(17, 17, 22),
	Sidebar   = Color3.fromRGB(13, 13, 17),
	Card      = Color3.fromRGB(24, 24, 31),
	CardHover = Color3.fromRGB(31, 31, 40),
	Stroke    = Color3.fromRGB(42, 42, 55),
	Text      = Color3.fromRGB(235, 235, 245),
	SubText   = Color3.fromRGB(130, 130, 150),
	Accent1   = Color3.fromRGB(125, 90, 255),
	Accent2   = Color3.fromRGB(70, 165, 255),
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
local function stroke(c) return create("UIStroke", {Color = c or THEME.Stroke, Thickness = 1}) end
local function accentGradient(rot)
	return create("UIGradient", {Color = ColorSequence.new(THEME.Accent1, THEME.Accent2), Rotation = rot or 0})
end
local function text(props, children)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamMedium
	props.TextColor3 = props.TextColor3 or THEME.Text
	props.TextSize = props.TextSize or 14
	return create("TextLabel", props, children)
end
local function tween(obj, t, goal)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function textWidth(s, size, font)
	return TextService:GetTextSize(s, size, font, Vector2.new(1000, 100)).X
end

---------------------------------------------------------------- HUD
local gui = create("ScreenGui", {
	Name = "NursultanUI", ResetOnSpawn = false, DisplayOrder = 50,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui,
})

-- Watermark
local watermark = create("Frame", {
	Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(0, 28),
	AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = THEME.Bg, Visible = false, Parent = gui,
}, {
	corner(6), stroke(),
	create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}),
	create("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
})
text({Text = CLIENT_NAME, Font = Enum.Font.GothamBlack, TextColor3 = WHITE, Size = UDim2.fromOffset(0, 28),
	AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 1, Parent = watermark}, {accentGradient()})
local wmInfo = text({Text = "", TextSize = 13, TextColor3 = THEME.SubText, Size = UDim2.fromOffset(0, 28),
	AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = watermark})

-- ArrayList
local arrayFrame = create("Frame", {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(250, 0),
	AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = gui,
}, {
	create("UIListLayout", {HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder}),
})

-- Уведомления
local notifHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -10), Size = UDim2.fromOffset(240, 400),
	BackgroundTransparency = 1, Parent = gui,
}, {
	create("UIListLayout", {VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder}),
})

-- Эффекты (локальные, видит только игрок)
local blur = create("BlurEffect", {Size = 0, Parent = Lighting})
local cc = create("ColorCorrectionEffect", {Enabled = false, Parent = Lighting})

local menuOpened = false
local Modules = {}

---------------------------------------------------------------- модули
local CATEGORIES = {
	{Name = "Render", Icon = "👁", Modules = {
		{Name = "Watermark", Desc = "Водяной знак с FPS и пингом", Default = true,
			OnToggle = function(_, on) watermark.Visible = on end},
		{Name = "ArrayList", Desc = "Список включённых модулей", Default = true,
			OnToggle = function(_, on) arrayFrame.Visible = on end},
		{Name = "CustomFOV", Desc = "Изменяет угол обзора камеры",
			Settings = {{Name = "FOV", Min = 30, Max = 120, Default = 90}},
			OnToggle = function(m, on)
				local cam = workspace.CurrentCamera
				if on then m._old = cam.FieldOfView elseif m._old then cam.FieldOfView = m._old end
			end},
	}},
	{Name = "World", Icon = "🌍", Modules = {
		{Name = "TimeChanger", Desc = "Меняет время суток", Settings = {{Name = "Время", Min = 0, Max = 24, Default = 0, Step = 0.5}},
			OnToggle = function(m, on)
				if on then m._old = Lighting.ClockTime elseif m._old then Lighting.ClockTime = m._old end
			end},
		{Name = "ColorCorrection", Desc = "Насыщенность и контраст картинки",
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
		{Name = "MenuBlur", Desc = "Размытие фона при открытом меню", Default = true,
			Settings = {{Name = "Сила", Min = 0, Max = 30, Default = 16}},
			OnToggle = function(m, on) tween(blur, 0.3, {Size = (on and menuOpened) and m.Values["Сила"] or 0}) end,
			OnChange = function(m) if m.Enabled and menuOpened then blur.Size = m.Values["Сила"] end end},
		{Name = "Notifications", Desc = "Уведомления о модулях", Default = true},
	}},
}

---------------------------------------------------------------- arraylist / notify
local function updateArrayList()
	for _, c in ipairs(arrayFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local list = {}
	for _, cat in ipairs(CATEGORIES) do
		for _, m in ipairs(cat.Modules) do
			if m.Enabled then table.insert(list, m) end
		end
	end
	local font = Enum.Font.GothamBold
	table.sort(list, function(a, b) return textWidth(a.Name, 13, font) > textWidth(b.Name, 13, font) end)
	for i, m in ipairs(list) do
		local row = create("Frame", {Size = UDim2.fromOffset(textWidth(m.Name, 13, font) + 18, 20),
			BackgroundColor3 = THEME.Bg, BackgroundTransparency = 0.15, BorderSizePixel = 0, LayoutOrder = i, Parent = arrayFrame})
		create("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = row}, {accentGradient(90)})
		text({Text = m.Name, Font = font, TextSize = 13, TextColor3 = WHITE, Size = UDim2.new(1, -2, 1, 0), Parent = row},
			{accentGradient()})
	end
end

local function notify(title, on)
	local nm = Modules.Notifications
	if not (nm and nm.Enabled) then return end
	local holder = create("Frame", {Size = UDim2.fromOffset(240, 50), BackgroundTransparency = 1, Parent = notifHolder})
	local box = create("Frame", {Position = UDim2.fromOffset(260, 0), Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = THEME.Bg, Parent = holder}, {corner(8), stroke()})
	text({Text = title, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	text({Text = on and "Модуль включён" or "Модуль выключен", TextSize = 12, TextColor3 = on and THEME.On or THEME.Off,
		Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
	local bar = create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = box}, {accentGradient()})
	tween(box, 0.35, {Position = UDim2.fromOffset(0, 0)})
	TweenService:Create(bar, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
	task.delay(2, function()
		tween(box, 0.35, {Position = UDim2.fromOffset(260, 0)})
		task.wait(0.35)
		holder:Destroy()
	end)
end

local function setModule(m, on, silent)
	m.Enabled = on
	m._grad.Enabled = on
	tween(m._switch, 0.25, {BackgroundColor3 = on and WHITE or THEME.Stroke})
	tween(m._knob, 0.25, {Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
	tween(m._title, 0.25, {TextColor3 = on and WHITE or THEME.Text})
	if m.OnToggle then m.OnToggle(m, on) end
	updateArrayList()
	if not silent then notify(m.Name, on) end
end

---------------------------------------------------------------- окно меню
local main = create("CanvasGroup", {
	Size = UDim2.fromOffset(660, 430), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.Bg, GroupTransparency = 1, Visible = false, Parent = gui,
}, {corner(12)})
local mainScale = create("UIScale", {Scale = 0.9, Parent = main})
-- Освобождает курсор в first-person, пока меню открыто
create("TextButton", {Modal = true, Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = main})
create("Frame", {Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3, Parent = main},
	{accentGradient()})

-- Sidebar
local sidebar = create("Frame", {Size = UDim2.new(0, 170, 1, 0), BackgroundColor3 = THEME.Sidebar, BorderSizePixel = 0, Parent = main})
local logoGrad = accentGradient()
text({Text = CLIENT_NAME, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = WHITE,
	Size = UDim2.new(1, 0, 0, 64), Parent = sidebar}, {logoGrad})

local catList = create("Frame", {Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 1, -140),
	BackgroundTransparency = 1, Parent = sidebar},
	{create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})

-- Профиль
local profile = create("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12),
	Size = UDim2.new(1, -24, 0, 48), BackgroundColor3 = THEME.Card, Parent = sidebar}, {corner(8), stroke()})
local avatar = create("ImageLabel", {Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(32, 32),
	BackgroundColor3 = THEME.Stroke, Parent = profile}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
text({Text = player.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.fromOffset(48, 8),
	Size = UDim2.new(1, -54, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = profile})
text({Text = "Premium", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = WHITE, Position = UDim2.fromOffset(48, 25),
	Size = UDim2.new(1, -54, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = profile}, {accentGradient()})
task.spawn(function()
	local ok, img = pcall(Players.GetUserThumbnailAsync, Players, player.UserId,
		Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	if ok then avatar.Image = img end
end)

-- Контент
local content = create("Frame", {Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -170, 1, 0),
	BackgroundTransparency = 1, Parent = main})
local header = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 20, Position = UDim2.fromOffset(20, 14),
	Size = UDim2.new(1, -220, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = content})
text({Text = "ПКМ по модулю — настройки", TextSize = 12, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(20, 38),
	Size = UDim2.new(1, -220, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = content})
local search = create("TextBox", {
	PlaceholderText = "Поиск...", Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 13,
	TextColor3 = THEME.Text, PlaceholderColor3 = THEME.SubText, TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundColor3 = THEME.Card, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 18),
	Size = UDim2.fromOffset(170, 30), Parent = content,
}, {corner(8), stroke(), create("UIPadding", {PaddingLeft = UDim.new(0, 10)})})

---------------------------------------------------------------- элементы
local function makeSlider(parent, m, s, order)
	local holder = create("Frame", {Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent})
	text({Text = s.Name, TextSize = 12, TextColor3 = THEME.SubText, Size = UDim2.new(0.6, 0, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = holder})
	local valueLbl = text({Text = "", Font = Enum.Font.GothamBold, TextSize = 12, Position = UDim2.fromScale(0.6, 0),
		Size = UDim2.new(0.4, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = holder})
	local bar = create("Frame", {Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 5),
		BackgroundColor3 = THEME.Stroke, Parent = holder}, {corner(3)})
	local fill = create("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, Parent = bar}, {corner(3), accentGradient()})
	local knob = create("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12), BackgroundColor3 = WHITE, Parent = bar}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})

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

	local dragging = false
	local function fromX(x)
		set(s.Min + (x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X * (s.Max - s.Min))
	end
	holder.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local function makeModule(page, m, order)
	m.Values = {}
	m.Enabled = false
	Modules[m.Name] = m

	local card = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Card, LayoutOrder = order, Parent = page},
		{corner(8), stroke(), create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
	m._card = card

	local top = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1, LayoutOrder = 1, Parent = card})
	m._title = text({Text = m.Name, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -110, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
	text({Text = m.Desc or "", TextSize = 12, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -110, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = top})

	m._switch = create("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(38, 20), BackgroundColor3 = THEME.Stroke, Parent = top},
		{create("UICorner", {CornerRadius = UDim.new(1, 0)})})
	m._grad = accentGradient()
	m._grad.Enabled = false
	m._grad.Parent = m._switch
	m._knob = create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14), BackgroundColor3 = WHITE, Parent = m._switch},
		{create("UICorner", {CornerRadius = UDim.new(1, 0)})})

	top.MouseButton1Click:Connect(function() setModule(m, not m.Enabled) end)
	top.MouseEnter:Connect(function() tween(card, 0.2, {BackgroundColor3 = THEME.CardHover}) end)
	top.MouseLeave:Connect(function() tween(card, 0.2, {BackgroundColor3 = THEME.Card}) end)

	if m.Settings then
		local settingsFrame = create("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Visible = false, LayoutOrder = 2, Parent = card}, {
			create("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}),
			create("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12)}),
		})
		for i, s in ipairs(m.Settings) do makeSlider(settingsFrame, m, s, i) end

		local arrow = create("TextButton", {Text = "▾", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = THEME.SubText,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -60, 0.5, 0),
			Size = UDim2.fromOffset(24, 24), Parent = top})
		local function expand()
			settingsFrame.Visible = not settingsFrame.Visible
			tween(arrow, 0.25, {Rotation = settingsFrame.Visible and 180 or 0})
		end
		arrow.MouseButton1Click:Connect(expand)
		top.MouseButton2Click:Connect(expand)
	end
end

---------------------------------------------------------------- категории
local currentCat
local function selectCategory(cat)
	currentCat = cat
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
	local btn = create("TextButton", {Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Card, BackgroundTransparency = 1, LayoutOrder = i, Parent = catList}, {corner(8)})
	cat._btn = btn
	cat._ind = create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(3, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, Parent = btn}, {corner(2), accentGradient(90)})
	text({Text = cat.Icon, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0, 20, 1, 0), Parent = btn})
	cat._lbl = text({Text = cat.Name, TextColor3 = THEME.SubText, Position = UDim2.fromOffset(40, 0),
		Size = UDim2.new(1, -40, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
	btn.MouseButton1Click:Connect(function() selectCategory(cat) end)

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

---------------------------------------------------------------- перетаскивание
-- Зона не перекрывает поиск справа
local dragZone = create("Frame", {Size = UDim2.new(1, -200, 0, 58), BackgroundTransparency = 1, ZIndex = 2, Parent = main})
local dragging, dragStart, startPos
dragZone.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, main.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

---------------------------------------------------------------- открытие/закрытие
local function setMenu(state)
	menuOpened = state
	if state then main.Visible = true end
	tween(main, 0.3, {GroupTransparency = state and 0 or 1})
	tween(mainScale, 0.3, {Scale = state and 1 or 0.9})
	local mb = Modules.MenuBlur
	tween(blur, 0.3, {Size = (state and mb.Enabled) and mb.Values["Сила"] or 0})
	if not state then
		task.delay(0.3, function() if not menuOpened then main.Visible = false end end)
	end
end

UIS.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == TOGGLE_KEY then setMenu(not menuOpened) end
end)

---------------------------------------------------------------- цикл: эффекты, FPS, анимация логотипа
local frames, last = 0, os.clock()
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if Modules.CustomFOV.Enabled then cam.FieldOfView = Modules.CustomFOV.Values.FOV end
	if Modules.TimeChanger.Enabled then Lighting.ClockTime = Modules.TimeChanger.Values["Время"] end
	if Modules.ColorCorrection.Enabled then
		cc.Saturation = Modules.ColorCorrection.Values["Насыщенность"]
		cc.Contrast = Modules.ColorCorrection.Values["Контраст"]
	end

	logoGrad.Rotation = (logoGrad.Rotation + dt * 60) % 360

	frames += 1
	local now = os.clock()
	if now - last >= 0.5 then
		local fps = math.floor(frames / (now - last) + 0.5)
		frames, last = 0, now
		local ping = math.floor(player:GetNetworkPing() * 1000 + 0.5)
		wmInfo.Text = string.format("%s  •  %d fps  •  %d ms", player.Name, fps, ping)
	end
end)

---------------------------------------------------------------- старт
for _, cat in ipairs(CATEGORIES) do
	for _, m in ipairs(cat.Modules) do
		if m.Default then setModule(m, true, true) end
	end
end
selectCategory(CATEGORIES[1])
setMenu(true)
