if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

pcall(function() PlayerGui:FindFirstChild("VertexHub"):Destroy() end)

local function GetChar() return LocalPlayer.Character end

local State = { ActiveLoops = {} }
local function StopEffect(id)
    if State.ActiveLoops[id] then
        pcall(function() State.ActiveLoops[id]:Disconnect() end)
        State.ActiveLoops[id] = nil
    end
end

-- ============ THEME PRESETS ============
local Themes = {
    Dark = {
        BG_DARK = Color3.fromRGB(16, 15, 24), BG_MID = Color3.fromRGB(22, 20, 32),
        BG_LIGHT = Color3.fromRGB(28, 26, 40), ACCENT = Color3.fromRGB(130, 90, 255),
        TRANSPARENCY = 0
    },
    BlueGlass = {
        BG_DARK = Color3.fromRGB(10, 20, 45), BG_MID = Color3.fromRGB(15, 30, 60),
        BG_LIGHT = Color3.fromRGB(25, 45, 85), ACCENT = Color3.fromRGB(0, 170, 255),
        TRANSPARENCY = 0.25
    },
    RedGlass = {
        BG_DARK = Color3.fromRGB(35, 10, 15), BG_MID = Color3.fromRGB(50, 15, 20),
        BG_LIGHT = Color3.fromRGB(70, 25, 30), ACCENT = Color3.fromRGB(255, 60, 60),
        TRANSPARENCY = 0.25
    },
    Purple = {
        BG_DARK = Color3.fromRGB(20, 10, 30), BG_MID = Color3.fromRGB(30, 15, 45),
        BG_LIGHT = Color3.fromRGB(45, 20, 65), ACCENT = Color3.fromRGB(190, 60, 255),
        TRANSPARENCY = 0.15
    },
    Emerald = {
        BG_DARK = Color3.fromRGB(8, 22, 18), BG_MID = Color3.fromRGB(14, 32, 26),
        BG_LIGHT = Color3.fromRGB(20, 45, 36), ACCENT = Color3.fromRGB(50, 220, 150),
        TRANSPARENCY = 0.1
    },
}

local CurrentTheme = Themes.Dark
local TEXT_BRIGHT = Color3.fromRGB(240, 240, 250)
local TEXT_DIM = Color3.fromRGB(150, 150, 170)

local ThemeRegistry = { bg_dark = {}, bg_mid = {}, bg_light = {}, accent_bg = {}, accent_stroke = {} }
local function Reg(bucket, obj) table.insert(ThemeRegistry[bucket], obj) end

-- ============ ROOT GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VertexHub"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- ============ TOP PILL ============
local TopPill = Instance.new("TextButton")
TopPill.Parent = ScreenGui
TopPill.BackgroundColor3 = CurrentTheme.BG_MID
TopPill.Position = UDim2.new(0.5, -95, 0, 10)
TopPill.Size = UDim2.new(0, 190, 0, 38)
TopPill.AutoButtonColor = false
TopPill.Text = ""
TopPill.BorderSizePixel = 0
Instance.new("UICorner", TopPill).CornerRadius = UDim.new(0, 10)
Reg("bg_mid", TopPill)

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = CurrentTheme.ACCENT
pillStroke.Thickness = 1.5
pillStroke.Transparency = 0.35
pillStroke.Parent = TopPill
Reg("accent_stroke", pillStroke)

local pillDot = Instance.new("Frame")
pillDot.Parent = TopPill
pillDot.BackgroundColor3 = Color3.fromRGB(120, 255, 150)
pillDot.Position = UDim2.new(0, 12, 0.5, -4)
pillDot.Size = UDim2.new(0, 8, 0, 8)
pillDot.BorderSizePixel = 0
Instance.new("UICorner", pillDot).CornerRadius = UDim.new(1, 0)

local pillText = Instance.new("TextLabel")
pillText.Parent = TopPill
pillText.BackgroundTransparency = 1
pillText.Position = UDim2.new(0, 28, 0, 0)
pillText.Size = UDim2.new(1, -60, 1, 0)
pillText.Font = Enum.Font.GothamBold
pillText.Text = "Vertex Hub"
pillText.TextColor3 = TEXT_BRIGHT
pillText.TextSize = 12
pillText.TextXAlignment = Enum.TextXAlignment.Left

local pillChevron = Instance.new("TextLabel")
pillChevron.Parent = TopPill
pillChevron.BackgroundTransparency = 1
pillChevron.Position = UDim2.new(1, -28, 0, 0)
pillChevron.Size = UDim2.new(0, 20, 1, 0)
pillChevron.Font = Enum.Font.GothamBold
pillChevron.Text = "▾"
pillChevron.TextColor3 = TEXT_DIM
pillChevron.TextSize = 12

-- ============ MAIN CONTAINER ============
local Container = Instance.new("Frame")
Container.Parent = ScreenGui
Container.BackgroundColor3 = CurrentTheme.BG_DARK
Container.Position = UDim2.new(0.5, -340, 0, 58)
Container.Size = UDim2.new(0, 680, 0, 450)
Container.BorderSizePixel = 0
Container.ClipsDescendants = true
Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 14)
Reg("bg_dark", Container)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = CurrentTheme.ACCENT
mainStroke.Thickness = 1
mainStroke.Transparency = 0.5
mainStroke.Parent = Container
Reg("accent_stroke", mainStroke)

local function ToggleMenu()
    Container.Visible = not Container.Visible
    pillChevron.Text = Container.Visible and "▴" or "▾"
end

TopPill.MouseButton1Click:Connect(ToggleMenu)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then ToggleMenu() end
end)

-- ============ DRAG ENGINE ============
local dragging, dragStart, startPos = false, nil, nil

local function BeginDrag(input)
    dragging = true
    dragStart = input.Position
    startPos = Container.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
    end)
end

local function UpdateDrag(input)
    if dragging and dragStart then
        local delta = input.Position - dragStart
        Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        UpdateDrag(input)
    end
end)

local function HookDragHandle(handle)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            BeginDrag(input)
        end
    end)
end

-- ============ SIDEBAR ============
local Sidebar = Instance.new("Frame")
Sidebar.Parent = Container
Sidebar.BackgroundColor3 = CurrentTheme.BG_MID
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BorderSizePixel = 0
Reg("bg_mid", Sidebar)

local SidebarHeader = Instance.new("Frame")
SidebarHeader.Parent = Sidebar
SidebarHeader.BackgroundTransparency = 1
SidebarHeader.Size = UDim2.new(1, 0, 0, 52)
SidebarHeader.Active = true
HookDragHandle(SidebarHeader)

local logoBox = Instance.new("Frame")
logoBox.Parent = SidebarHeader
logoBox.BackgroundColor3 = CurrentTheme.ACCENT
logoBox.Position = UDim2.new(0, 14, 0, 12)
logoBox.Size = UDim2.new(0, 28, 0, 28)
logoBox.BorderSizePixel = 0
Instance.new("UICorner", logoBox).CornerRadius = UDim.new(0, 8)
Reg("accent_bg", logoBox)

local logoTxt = Instance.new("TextLabel")
logoTxt.Parent = logoBox
logoTxt.BackgroundTransparency = 1
logoTxt.Size = UDim2.new(1, 0, 1, 0)
logoTxt.Font = Enum.Font.GothamBlack
logoTxt.Text = "V"
logoTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
logoTxt.TextSize = 15

local nameLabel = Instance.new("TextLabel")
nameLabel.Parent = SidebarHeader
nameLabel.BackgroundTransparency = 1
nameLabel.Position = UDim2.new(0, 50, 0, 10)
nameLabel.Size = UDim2.new(1, -60, 0, 18)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Text = "Vertex Hub"
nameLabel.TextColor3 = TEXT_BRIGHT
nameLabel.TextSize = 13
nameLabel.TextXAlignment = Enum.TextXAlignment.Left

local verLabel = Instance.new("TextLabel")
verLabel.Parent = SidebarHeader
verLabel.BackgroundTransparency = 1
verLabel.Position = UDim2.new(0, 50, 0, 27)
verLabel.Size = UDim2.new(1, -60, 0, 14)
verLabel.Font = Enum.Font.Gotham
verLabel.Text = "Universal • v2.0"
verLabel.TextColor3 = TEXT_DIM
verLabel.TextSize = 9
verLabel.TextXAlignment = Enum.TextXAlignment.Left

local SearchBox = Instance.new("TextBox")
SearchBox.Parent = Sidebar
SearchBox.BackgroundColor3 = CurrentTheme.BG_LIGHT
SearchBox.Position = UDim2.new(0, 10, 0, 54)
SearchBox.Size = UDim2.new(1, -20, 0, 26)
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "Search..."
SearchBox.Text = ""
SearchBox.TextColor3 = TEXT_BRIGHT
SearchBox.PlaceholderColor3 = TEXT_DIM
SearchBox.TextSize = 11
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 7)
Reg("bg_light", SearchBox)
local searchPad = Instance.new("UIPadding")
searchPad.PaddingLeft = UDim.new(0, 8)
searchPad.Parent = SearchBox

local NavList = Instance.new("ScrollingFrame")
NavList.Parent = Sidebar
NavList.BackgroundTransparency = 1
NavList.Position = UDim2.new(0, 0, 0, 88)
NavList.Size = UDim2.new(1, 0, 1, -88)
NavList.ScrollBarThickness = 2
NavList.BorderSizePixel = 0
NavList.CanvasSize = UDim2.new(0, 0, 0, 0)
NavList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local navListLayout = Instance.new("UIListLayout")
navListLayout.Parent = NavList
navListLayout.Padding = UDim.new(0, 3)
navListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local navPad = Instance.new("UIPadding")
navPad.PaddingLeft = UDim.new(0, 8)
navPad.PaddingRight = UDim.new(0, 8)
navPad.PaddingTop = UDim.new(0, 2)
navPad.Parent = NavList

-- ============ RIGHT SIDE ============
local RightSide = Instance.new("Frame")
RightSide.Parent = Container
RightSide.BackgroundTransparency = 1
RightSide.Position = UDim2.new(0, 180, 0, 0)
RightSide.Size = UDim2.new(1, -180, 1, 0)

local TopBar = Instance.new("Frame")
TopBar.Parent = RightSide
TopBar.BackgroundColor3 = CurrentTheme.BG_MID
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BorderSizePixel = 0
TopBar.Active = true
HookDragHandle(TopBar)
Reg("bg_mid", TopBar)

local breadcrumb = Instance.new("TextLabel")
breadcrumb.Parent = TopBar
breadcrumb.BackgroundTransparency = 1
breadcrumb.Position = UDim2.new(0, 14, 0, 0)
breadcrumb.Size = UDim2.new(0, 160, 1, 0)
breadcrumb.Font = Enum.Font.GothamMedium
breadcrumb.Text = "Cosmetics"
breadcrumb.TextColor3 = TEXT_BRIGHT
breadcrumb.TextSize = 12
breadcrumb.TextXAlignment = Enum.TextXAlignment.Left

local themeContainer = Instance.new("Frame")
themeContainer.Parent = TopBar
themeContainer.BackgroundTransparency = 1
themeContainer.Position = UDim2.new(1, -180, 0.5, -9)
themeContainer.Size = UDim2.new(0, 140, 0, 18)

local themeList = Instance.new("UIListLayout")
themeList.Parent = themeContainer
themeList.FillDirection = Enum.FillDirection.Horizontal
themeList.Padding = UDim.new(0, 6)
themeList.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function ApplyTheme(themeKey)
    local t = Themes[themeKey]
    if not t then return end
    CurrentTheme = t

    local tw = TweenInfo.new(0.25)
    for _, obj in ipairs(ThemeRegistry.bg_dark) do
        TweenService:Create(obj, tw, {BackgroundColor3 = t.BG_DARK, BackgroundTransparency = t.TRANSPARENCY}):Play()
    end
    for _, obj in ipairs(ThemeRegistry.bg_mid) do
        TweenService:Create(obj, tw, {BackgroundColor3 = t.BG_MID, BackgroundTransparency = t.TRANSPARENCY}):Play()
    end
    for _, obj in ipairs(ThemeRegistry.bg_light) do
        TweenService:Create(obj, tw, {BackgroundColor3 = t.BG_LIGHT, BackgroundTransparency = t.TRANSPARENCY}):Play()
    end
    for _, obj in ipairs(ThemeRegistry.accent_bg) do
        TweenService:Create(obj, tw, {BackgroundColor3 = t.ACCENT}):Play()
    end
    for _, obj in ipairs(ThemeRegistry.accent_stroke) do
        TweenService:Create(obj, tw, {Color = t.ACCENT}):Play()
    end
end

local themeButtons = {
    {color = Color3.fromRGB(25, 25, 35), key = "Dark"},
    {color = Color3.fromRGB(0, 150, 255), key = "BlueGlass"},
    {color = Color3.fromRGB(255, 60, 60), key = "RedGlass"},
    {color = Color3.fromRGB(180, 60, 255), key = "Purple"},
    {color = Color3.fromRGB(50, 220, 150), key = "Emerald"},
}

for _, tb in ipairs(themeButtons) do
    local btn = Instance.new("TextButton")
    btn.Parent = themeContainer
    btn.BackgroundColor3 = tb.color
    btn.Size = UDim2.new(0, 18, 0, 18)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local ts = Instance.new("UIStroke")
    ts.Color = Color3.fromRGB(255, 255, 255)
    ts.Thickness = 1
    ts.Transparency = 0.7
    ts.Parent = btn
    btn.MouseButton1Click:Connect(function() ApplyTheme(tb.key) end)
end

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = TopBar
closeBtn.BackgroundTransparency = 1
closeBtn.Position = UDim2.new(1, -34, 0, 0)
closeBtn.Size = UDim2.new(0, 34, 1, 0)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.TextColor3 = TEXT_DIM
closeBtn.TextSize = 14
closeBtn.MouseButton1Click:Connect(function() Container.Visible = false end)

local Pages = Instance.new("Frame")
Pages.Parent = RightSide
Pages.BackgroundTransparency = 1
Pages.Position = UDim2.new(0, 0, 0, 42)
Pages.Size = UDim2.new(1, 0, 1, -42)

-- ============ PAGE GENERATOR ============
local navButtons, pages, currentPage = {}, {}, nil

local function CreatePage(id, navLabel, iconChar)
    local navBtn = Instance.new("TextButton")
    navBtn.Parent = NavList
    navBtn.BackgroundColor3 = CurrentTheme.BG_LIGHT
    navBtn.BackgroundTransparency = 1
    navBtn.Size = UDim2.new(1, 0, 0, 30)
    navBtn.Font = Enum.Font.GothamMedium
    navBtn.Text = ""
    navBtn.AutoButtonColor = false
    navBtn.BorderSizePixel = 0
    Instance.new("UICorner", navBtn).CornerRadius = UDim.new(0, 7)

    local navIcon = Instance.new("TextLabel")
    navIcon.Parent = navBtn
    navIcon.BackgroundTransparency = 1
    navIcon.Position = UDim2.new(0, 8, 0, 0)
    navIcon.Size = UDim2.new(0, 20, 1, 0)
    navIcon.Font = Enum.Font.GothamBold
    navIcon.Text = iconChar
    navIcon.TextColor3 = TEXT_DIM
    navIcon.TextSize = 12

    local navText = Instance.new("TextLabel")
    navText.Parent = navBtn
    navText.BackgroundTransparency = 1
    navText.Position = UDim2.new(0, 30, 0, 0)
    navText.Size = UDim2.new(1, -35, 1, 0)
    navText.Font = Enum.Font.GothamMedium
    navText.Text = navLabel
    navText.TextColor3 = TEXT_DIM
    navText.TextSize = 11
    navText.TextXAlignment = Enum.TextXAlignment.Left

    local page = Instance.new("ScrollingFrame")
    page.Parent = Pages
    page.BackgroundTransparency = 1
    page.Size = UDim2.new(1, 0, 1, 0)
    page.ScrollBarThickness = 3
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false

    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingTop = UDim.new(0, 12)
    pagePad.PaddingLeft = UDim.new(0, 14)
    pagePad.PaddingRight = UDim.new(0, 14)
    pagePad.PaddingBottom = UDim.new(0, 12)
    pagePad.Parent = page

    local pageGrid = Instance.new("UIListLayout")
    pageGrid.Parent = page
    pageGrid.Padding = UDim.new(0, 8)
    pageGrid.SortOrder = Enum.SortOrder.LayoutOrder

    navButtons[id] = navBtn
    pages[id] = page

    local function Select()
        for pid, btn in pairs(navButtons) do
            btn.BackgroundTransparency = 1
            for _, c in pairs(btn:GetChildren()) do
                if c:IsA("TextLabel") then c.TextColor3 = TEXT_DIM end
            end
            pages[pid].Visible = false
        end
        navBtn.BackgroundTransparency = 0.2
        navBtn.BackgroundColor3 = CurrentTheme.BG_LIGHT
        navIcon.TextColor3 = CurrentTheme.ACCENT
        navText.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
        breadcrumb.Text = navLabel
        currentPage = id
    end

    navBtn.MouseButton1Click:Connect(Select)
    if not currentPage then Select() end
    return page
end

-- ============ CARD BUILDERS ============
local function AddSectionLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(180, 150, 255)
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function AddCard(parent, text, callback)
    local card = Instance.new("TextButton")
    card.Parent = parent
    card.BackgroundColor3 = CurrentTheme.BG_MID
    card.Size = UDim2.new(1, 0, 0, 36)
    card.AutoButtonColor = false
    card.Text = ""
    card.BorderSizePixel = 0
    card:SetAttribute("SearchText", text:lower())
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    Reg("bg_mid", card)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(55, 50, 75)
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.5
    cardStroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Parent = card
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = TEXT_BRIGHT
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    card.MouseButton1Click:Connect(function()
        cardStroke.Transparency = 0
        TweenService:Create(cardStroke, TweenInfo.new(0.15), {Color = CurrentTheme.ACCENT}):Play()
        task.wait(0.08)
        pcall(callback)
    end)
    card.MouseEnter:Connect(function() cardStroke.Transparency = 0 end)
    card.MouseLeave:Connect(function() cardStroke.Transparency = 0.5 end)

    return card
end

local function AddToggleCard(parent, text, callback)
    local card = Instance.new("Frame")
    card.Parent = parent
    card.BackgroundColor3 = CurrentTheme.BG_MID
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BorderSizePixel = 0
    card:SetAttribute("SearchText", text:lower())
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    Reg("bg_mid", card)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(55, 50, 75)
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local label = Instance.new("TextLabel")
    label.Parent = card
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = TEXT_BRIGHT
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switchBg = Instance.new("Frame")
    switchBg.Parent = card
    switchBg.BackgroundColor3 = Color3.fromRGB(60, 55, 75)
    switchBg.Position = UDim2.new(1, -44, 0.5, -9)
    switchBg.Size = UDim2.new(0, 32, 0, 18)
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Parent = switchBg
    knob.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Parent = card
    clickBtn.BackgroundTransparency = 1
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.Text = ""

    local enabled = false
    clickBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = CurrentTheme.ACCENT}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 18, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
        else
            TweenService:Create(switchBg, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 55, 75)}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(180,180,200)}):Play()
        end
        pcall(function() callback(enabled) end)
    end)

    return card
end

-- ============ ALL PAGES ============
local pgShaders = CreatePage("shaders", "Shaders", "🎨")
local pgTrails = CreatePage("trails", "Trails", "💫")
local pgCosmetics = CreatePage("cosmetics", "Cosmetics", "👑")
local pgVisual = CreatePage("visual", "Visuals", "🔮")
local pgSky = CreatePage("sky", "Skybox", "☁")
local pgMove = CreatePage("move", "Movement", "⚡")
local pgChar = CreatePage("char", "Character", "👤")
local pgMisc = CreatePage("misc", "Settings", "⚙")

-- ============ SHADERS & POST-PROCESSING ============
local GFX_DEFAULTS = {}
for _, p in ipairs({"Brightness", "ExposureCompensation", "ClockTime", "OutdoorAmbient", "Ambient"}) do
    pcall(function() GFX_DEFAULTS[p] = Lighting[p] end)
end

local function CleanShaders()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj.Name:sub(1, 6) == "Shader" then
            obj:Destroy()
        end
    end
end

local function GetShaderFX(class, name)
    local e = Lighting:FindFirstChild(name)
    if not e or e.ClassName ~= class then
        if e then e:Destroy() end
        e = Instance.new(class)
        e.Name = name
        e.Parent = Lighting
    end
    return e
end

local SHADER_TWEEN = TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

AddSectionLabel(pgShaders, "Full Shader Presets")

AddCard(pgShaders, "RTX Ultra (Bloom + DOF + Rays)", function()
    CleanShaders()

    local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
    TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.55, Size = 26, Threshold = 0.85}):Play()

    local dof = GetShaderFX("DepthOfFieldEffect", "ShaderDOF")
    dof.FarIntensity = 0.15
    dof.FocusDistance = 20
    dof.InFocusRadius = 30
    dof.NearIntensity = 0.1

    local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
    TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0.05, Contrast = 0.22, Saturation = 0.28}):Play()

    local rays = GetShaderFX("SunRaysEffect", "ShaderRays")
    TweenService:Create(rays, SHADER_TWEEN, {Intensity = 0.28, Spread = 0.8}):Play()

    TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 3.4, ExposureCompensation = 0.3, ClockTime = 14}):Play()
end)

AddCard(pgShaders, "Cinematic Film Grain", function()
    CleanShaders()
    local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
    TweenService:Create(cc, SHADER_TWEEN, {Brightness = -0.02, Contrast = 0.35, Saturation = -0.15, TintColor = Color3.fromRGB(235, 225, 210)}):Play()
    local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
    TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.35, Size = 18, Threshold = 1.6}):Play()
    TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.4, ExposureCompensation = 0.2, ClockTime = 16}):Play()
end)

AddCard(pgShaders, "Neon Vivid", function()
    CleanShaders()
    local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
    TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0.06, Contrast = 0.32, Saturation = 0.55, TintColor = Color3.fromRGB(255, 250, 250)}):Play()
    local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
    TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 1.5, Size = 32, Threshold = 0.75}):Play()
    TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.8, ExposureCompensation = 0.5, ClockTime = 0.5}):Play()
end)

AddCard(pgShaders, "Soft Realism", function()
    CleanShaders()
    local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
    TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0.02, Contrast = 0.2, Saturation = 0.12, TintColor = Color3.fromRGB(253, 251, 249)}):Play()
    local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
    TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.4, Size = 16, Threshold = 1.9}):Play()
    TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 3.0, ExposureCompensation = 0.2, ClockTime = 15.5}):Play()
end)

AddCard(pgShaders, "Foggy Horror", function()
    CleanShaders()
    local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
    TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0, Contrast = 0.15, Saturation = -0.35, TintColor = Color3.fromRGB(215, 225, 215)}):Play()
    local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
    TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.3, Size = 16, Threshold = 2.0}):Play()
    local atmo = GetShaderFX("Atmosphere", "ShaderAtmo")
    TweenService:Create(atmo, SHADER_TWEEN, {Density = 0.55, Glare = 0.1, Haze = 2.2, Color = Color3.fromRGB(160, 170, 160), Decay = Color3.fromRGB(70, 80, 65)}):Play()
    TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.4, ExposureCompensation = 0.25, ClockTime = 5}):Play()
end)

AddSectionLabel(pgShaders, "Manage")
AddCard(pgShaders, "Reset Shaders", function()
    CleanShaders()
    local atmo = Lighting:FindFirstChild("ShaderAtmo")
    if atmo then atmo:Destroy() end
    TweenService:Create(Lighting, SHADER_TWEEN, GFX_DEFAULTS):Play()
end)

-- ============ TRAILS ============
AddSectionLabel(pgTrails, "Character Trails")

local function ClearTrail()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Trail") or (v:IsA("Attachment") and v.Name:sub(1, 5) == "Trail") then
            v:Destroy()
        end
    end
end

local function MakeTrail(colorSeq, lifetime, widthScale)
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    ClearTrail()

    local a0 = Instance.new("Attachment")
    a0.Name = "TrailA0"
    a0.Position = Vector3.new(0, 1, 0)
    a0.Parent = root

    local a1 = Instance.new("Attachment")
    a1.Name = "TrailA1"
    a1.Position = Vector3.new(0, -1, 0)
    a1.Parent = root

    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Color = colorSeq
    trail.Lifetime = lifetime or 0.8
    trail.WidthScale = widthScale or NumberSequence.new(1)
    trail.Parent = root
end

AddCard(pgTrails, "Rainbow Trail", function()
    MakeTrail(ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255)),
    }), 1.0)
end)

AddCard(pgTrails, "Purple Trail", function()
    MakeTrail(ColorSequence.new(Color3.fromRGB(170, 90, 255)), 0.8)
end)

AddCard(pgTrails, "Cyan Trail", function()
    MakeTrail(ColorSequence.new(Color3.fromRGB(0, 220, 255)), 0.8)
end)

AddCard(pgTrails, "Gold Trail", function()
    MakeTrail(ColorSequence.new(Color3.fromRGB(255, 210, 90)), 0.9)
end)

AddCard(pgTrails, "Fire Trail", function()
    MakeTrail(ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 30, 0)),
    }), 0.6)
end)

AddCard(pgTrails, "Ghost Trail (fading white)", function()
    MakeTrail(ColorSequence.new(Color3.fromRGB(255, 255, 255)), 1.4)
end)

AddCard(pgTrails, "Remove Trail", function()
    ClearTrail()
end)

-- ============ COSMETICS ============
AddSectionLabel(pgCosmetics, "Headwear")

AddCard(pgCosmetics, "China Hat", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("ChinaHat")
        if old then old:Destroy() end
    end)

    local holder = Instance.new("Model")
    holder.Name = "ChinaHat"

    local function Lerp(c1, c2, t)
        return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
    end

    local colorBottom = Color3.fromRGB(150, 80, 220)
    local colorTop = Color3.fromRGB(255, 210, 120)

    local brim = Instance.new("Part")
    brim.Name = "Brim"
    brim.Shape = Enum.PartType.Cylinder
    brim.Size = Vector3.new(0.25, 5.6, 5.6)
    brim.Material = Enum.Material.SmoothPlastic
    brim.Color = Color3.fromRGB(20, 18, 25)
    brim.CanCollide = false
    brim.Massless = true
    brim.Orientation = Vector3.new(0, 0, 90)
    local brimWeld = Instance.new("Weld")
    brimWeld.Part0 = head
    brimWeld.Part1 = brim
    brimWeld.C0 = CFrame.new(0, 1.0, 0)
    brimWeld.Parent = brim
    brim.Parent = holder

    local LAYERS = 16
    local coneHeight = 2.0
    local baseRadius = 4.5
    for i = 1, LAYERS do
        local t = (i - 1) / (LAYERS - 1)
        local radius = math.max(baseRadius * (1 - t), 0.12)
        local yOffset = 1.08 + t * coneHeight
        local layer = Instance.new("Part")
        layer.Name = "Layer" .. i
        layer.Shape = Enum.PartType.Cylinder
        layer.Size = Vector3.new(0.16, radius * 2, radius * 2)
        layer.Material = Enum.Material.SmoothPlastic
        layer.Color = Lerp(colorBottom, colorTop, t)
        layer.CanCollide = false
        layer.Massless = true
        layer.Orientation = Vector3.new(0, 0, 90)
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = layer
        weld.C0 = CFrame.new(0, yOffset, 0)
        weld.Parent = layer
        layer.Parent = holder
    end

    local tip = Instance.new("Part")
    tip.Name = "Tip"
    tip.Shape = Enum.PartType.Ball
    tip.Size = Vector3.new(0.3, 0.3, 0.3)
    tip.Material = Enum.Material.Neon
    tip.Color = colorTop
    tip.CanCollide = false
    tip.Massless = true
    local tipWeld = Instance.new("Weld")
    tipWeld.Part0 = head
    tipWeld.Part1 = tip
    tipWeld.C0 = CFrame.new(0, 1.08 + coneHeight + 0.15, 0)
    tipWeld.Parent = tip
    tip.Parent = holder

    holder.Parent = char
end)

AddCard(pgCosmetics, "Party Cone", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("PartyCone")
        if old then old:Destroy() end
    end)
    local cone = Instance.new("Part")
    cone.Name = "PartyCone"
    cone.Size = Vector3.new(1, 1, 1)
    cone.Material = Enum.Material.SmoothPlastic
    cone.Color = Color3.fromRGB(255, 40, 150)
    cone.CanCollide = false
    cone.Massless = true
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Pyramid
    mesh.Scale = Vector3.new(2.2, 3.4, 2.2)
    mesh.Parent = cone
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = cone
    weld.C0 = CFrame.new(0, 2.1, 0)
    weld.Parent = cone
    cone.Parent = char
end)

AddCard(pgCosmetics, "Neon Halo", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("Halo")
        if old then old:Destroy() end
    end)
    local halo = Instance.new("Part")
    halo.Name = "Halo"
    halo.Shape = Enum.PartType.Cylinder
    halo.Size = Vector3.new(0.12, 2.2, 2.2)
    halo.Material = Enum.Material.Neon
    halo.Color = Color3.fromRGB(0, 255, 255)
    halo.CanCollide = false
    halo.Massless = true
    halo.Rotation = Vector3.new(0, 0, 90)
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = halo
    weld.C0 = CFrame.new(0, 1.6, 0)
    weld.Parent = halo
    halo.Parent = char
end)

AddCard(pgCosmetics, "Gold Crown", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("Crown")
        if old then old:Destroy() end
    end)
    local crown = Instance.new("Part")
    crown.Name = "Crown"
    crown.Shape = Enum.PartType.Cylinder
    crown.Size = Vector3.new(0.25, 1.5, 1.5)
    crown.Material = Enum.Material.Metal
    crown.Color = Color3.fromRGB(255, 215, 0)
    crown.CanCollide = false
    crown.Massless = true
    crown.Rotation = Vector3.new(0, 0, 90)
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = crown
    weld.C0 = CFrame.new(0, 1.4, 0)
    weld.Parent = crown
    crown.Parent = char
end)

AddCard(pgCosmetics, "Wizard Hat", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("WizardHat")
        if old then old:Destroy() end
    end)
    local hat = Instance.new("Part")
    hat.Name = "WizardHat"
    hat.Size = Vector3.new(1, 1, 1)
    hat.Material = Enum.Material.SmoothPlastic
    hat.Color = Color3.fromRGB(70, 20, 140)
    hat.CanCollide = false
    hat.Massless = true
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.Pyramid
    mesh.Scale = Vector3.new(2.4, 4, 2.4)
    mesh.Parent = hat
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = hat
    weld.C0 = CFrame.new(0, 2.6, 0)
    weld.Parent = hat
    hat.Parent = char
end)

AddCard(pgCosmetics, "Devil Horns", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("DevilHorns")
        if old then old:Destroy() end
    end)
    local holder = Instance.new("Model")
    holder.Name = "DevilHorns"
    for _, side in ipairs({-1, 1}) do
        local horn = Instance.new("Part")
        horn.Size = Vector3.new(1, 1, 1)
        horn.Material = Enum.Material.SmoothPlastic
        horn.Color = Color3.fromRGB(180, 0, 0)
        horn.CanCollide = false
        horn.Massless = true
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Pyramid
        mesh.Scale = Vector3.new(0.7, 1.2, 0.7)
        mesh.Parent = horn
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = horn
        weld.C0 = CFrame.new(0.45 * side, 0.9, 0) * CFrame.Angles(0, 0, math.rad(15 * side))
        weld.Parent = horn
        horn.Parent = holder
    end
    holder.Parent = char
end)

AddCard(pgCosmetics, "Flower Crown", function()
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end
    pcall(function()
        local old = char:FindFirstChild("FlowerCrown")
        if old then old:Destroy() end
    end)
    local holder = Instance.new("Model")
    holder.Name = "FlowerCrown"
    local petalColors = {
        Color3.fromRGB(255, 130, 180), Color3.fromRGB(255, 210, 100),
        Color3.fromRGB(180, 130, 255), Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 170, 120),
    }
    for i = 1, 6 do
        local ang = (i - 1) * (math.pi * 2 / 6)
        local flower = Instance.new("Part")
        flower.Shape = Enum.PartType.Ball
        flower.Size = Vector3.new(0.45, 0.45, 0.45)
        flower.Material = Enum.Material.SmoothPlastic
        flower.Color = petalColors[i]
        flower.CanCollide = false
        flower.Massless = true
        local weld = Instance.new("Weld")
        weld.Part0 = head
        weld.Part1 = flower
        weld.C0 = CFrame.new(math.cos(ang) * 1.05, 0.55, math.sin(ang) * 1.05)
        weld.Parent = flower
        flower.Parent = holder
    end
    holder.Parent = char
end)

AddSectionLabel(pgCosmetics, "Manage")
AddCard(pgCosmetics, "Remove All Hats", function()
    local char = GetChar()
    if not char then return end
    for _, v in pairs(char:GetChildren()) do
        if v.Name == "ChinaHat" or v.Name == "PartyCone" or v.Name == "Halo" or v.Name == "Crown" or v.Name == "WizardHat" or v.Name == "DevilHorns" or v.Name == "FlowerCrown" then
            pcall(function() v:Destroy() end)
        end
    end
end)

-- ============ CHARACTER ============
AddSectionLabel(pgChar, "Materials")
AddCard(pgChar, "Rainbow Neon", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromHSV(math.random(), 0.9, 1)
        end
    end
end)
AddCard(pgChar, "Gold Metal", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Metal
            part.Color = Color3.fromRGB(255, 215, 0)
        end
    end
end)
AddCard(pgChar, "Cyan Neon", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Neon
            part.Color = Color3.fromRGB(0, 255, 255)
        end
    end
end)
AddCard(pgChar, "Glass Body", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Glass
            part.Transparency = 0.5
        end
    end
end)
AddCard(pgChar, "Chrome Body", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.Foil
            part.Color = Color3.fromRGB(220, 220, 230)
        end
    end
end)
AddCard(pgChar, "Pastel Pink", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Material = Enum.Material.SmoothPlastic
            part.Color = Color3.fromRGB(255, 195, 220)
        end
    end
end)

AddSectionLabel(pgChar, "Visibility")
AddCard(pgChar, "Invisible", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency = 0.9 end
    end
end)
AddCard(pgChar, "Visible", function()
    local char = GetChar()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency = 0 end
    end
end)

AddSectionLabel(pgChar, "Size")
AddCard(pgChar, "Giant Size (3x)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then
        for _, s in pairs(h:GetChildren()) do
            if s.Name:match("Scale") then s.Value = 3 end
        end
    end
end)
AddCard(pgChar, "Tiny Size (0.3x)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then
        for _, s in pairs(h:GetChildren()) do
            if s.Name:match("Scale") then s.Value = 0.3 end
        end
    end
end)
AddCard(pgChar, "Normal Size (1x)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then
        for _, s in pairs(h:GetChildren()) do
            if s.Name:match("Scale") then s.Value = 1 end
        end
    end
end)

-- ============ VISUALS ============
AddSectionLabel(pgVisual, "Orbit Effects")
AddCard(pgVisual, "Orbit Cubes (XY)", function()
    StopEffect("cubesXY"); StopEffect("cubesXZ")
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "OrbitCubes" then v:Destroy() end
    end
    local folder = Instance.new("Folder", Workspace)
    folder.Name = "OrbitCubes"
    for i = 1, 8 do
        local cube = Instance.new("Part", folder)
        cube.Shape = Enum.PartType.Block
        cube.Size = Vector3.new(0.5, 0.5, 0.5)
        cube.Material = Enum.Material.Neon
        cube.Color = Color3.fromHSV(i / 8, 1, 1)
        cube.CanCollide = false
        cube.Anchored = true
    end
    local angle = 0
    State.ActiveLoops["cubesXY"] = RunService.RenderStepped:Connect(function(dt)
        local char = GetChar()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not folder.Parent then return end
        angle = angle + dt * 3.5
        for i, cube in pairs(folder:GetChildren()) do
            local ang = angle + i * (math.pi * 2 / 8)
            cube.Position = root.Position + Vector3.new(math.cos(ang) * 5, math.sin(ang) * 5, 0)
        end
    end)
end)
AddCard(pgVisual, "Orbit Cubes (XZ)", function()
    StopEffect("cubesXY"); StopEffect("cubesXZ")
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "OrbitCubes" then v:Destroy() end
    end
    local folder = Instance.new("Folder", Workspace)
    folder.Name = "OrbitCubes"
    for i = 1, 8 do
        local cube = Instance.new("Part", folder)
        cube.Shape = Enum.PartType.Block
        cube.Size = Vector3.new(0.5, 0.5, 0.5)
        cube.Material = Enum.Material.Neon
        cube.Color = Color3.fromHSV(i / 8, 1, 1)
        cube.CanCollide = false
        cube.Anchored = true
    end
    local angle = 0
    State.ActiveLoops["cubesXZ"] = RunService.RenderStepped:Connect(function(dt)
        local char = GetChar()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not folder.Parent then return end
        angle = angle + dt * 3.5
        for i, cube in pairs(folder:GetChildren()) do
            local ang = angle + i * (math.pi * 2 / 8)
            cube.Position = root.Position + Vector3.new(math.cos(ang) * 5, 0, math.sin(ang) * 5)
        end
    end)
end)
AddCard(pgVisual, "Stop Orbits", function()
    StopEffect("cubesXY"); StopEffect("cubesXZ")
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "OrbitCubes" then v:Destroy() end
    end
end)

AddSectionLabel(pgVisual, "Auras")
AddCard(pgVisual, "Fire Aura", function()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
    end
    local fire = Instance.new("Fire")
    fire.Parent = root
    fire.Color = Color3.fromRGB(255, 100, 0)
    fire.SecondaryColor = Color3.fromRGB(255, 50, 0)
    fire.Size = 15
    fire.Heat = 15
end)
AddCard(pgVisual, "Smoke Aura", function()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
    end
    local smoke = Instance.new("Smoke")
    smoke.Parent = root
    smoke.Color = Color3.fromRGB(80, 80, 80)
    smoke.Size = 12
    smoke.Opacity = 0.8
end)
AddCard(pgVisual, "Sparkles Aura", function()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
    end
    local sp = Instance.new("Sparkles")
    sp.Parent = root
    sp.SparkleColor = Color3.fromRGB(255, 255, 150)
end)
AddCard(pgVisual, "Clear Aura", function()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
    end
end)

-- ============ SKYBOX ============
AddSectionLabel(pgSky, "Atmosphere Themes")
AddCard(pgSky, "Purple Nebula", function()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atm.Parent = Lighting
    atm.Color = Color3.fromRGB(150, 80, 220)
    atm.Decay = Color3.fromRGB(100, 40, 180)
    atm.Density = 0.4
    atm.Glare = 0.2
    atm.Haze = 2.2
    Lighting.ClockTime = 18
end)
AddCard(pgSky, "Red Sunset", function()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atm.Parent = Lighting
    atm.Color = Color3.fromRGB(220, 100, 60)
    atm.Decay = Color3.fromRGB(150, 50, 30)
    atm.Density = 0.35
    atm.Glare = 0.1
    atm.Haze = 2.8
    Lighting.ClockTime = 18
end)
AddCard(pgSky, "Cyan Sky", function()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atm.Parent = Lighting
    atm.Color = Color3.fromRGB(100, 200, 255)
    atm.Decay = Color3.fromRGB(50, 120, 200)
    atm.Density = 0.25
    atm.Glare = 0.4
    atm.Haze = 1.5
    Lighting.ClockTime = 12
end)
AddCard(pgSky, "Dark Green", function()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atm.Parent = Lighting
    atm.Color = Color3.fromRGB(80, 150, 100)
    atm.Decay = Color3.fromRGB(40, 100, 60)
    atm.Density = 0.5
    atm.Glare = 0.1
    atm.Haze = 3
    Lighting.ClockTime = 6
end)
AddCard(pgSky, "Clear Sky", function()
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    if atm then atm:Destroy() end
    Lighting.ClockTime = 12
    Lighting.Brightness = 2
end)

AddSectionLabel(pgSky, "Brightness & Time")
AddCard(pgSky, "Bright (5)", function() Lighting.Brightness = 5 end)
AddCard(pgSky, "Normal (2)", function() Lighting.Brightness = 2 end)
AddCard(pgSky, "Dark (0.4)", function() Lighting.Brightness = 0.4 end)
AddCard(pgSky, "Fullbright", function()
    Lighting.Brightness = 6
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
end)
AddCard(pgSky, "Sunrise (6:00)", function() Lighting.ClockTime = 6 end)
AddCard(pgSky, "Noon (12:00)", function() Lighting.ClockTime = 12 end)
AddCard(pgSky, "Sunset (18:00)", function() Lighting.ClockTime = 18 end)
AddCard(pgSky, "Midnight (0:00)", function() Lighting.ClockTime = 0 end)

-- ============ MOVEMENT ============
AddSectionLabel(pgMove, "Speed")
AddCard(pgMove, "Speed x2 (32)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 32 end
end)
AddCard(pgMove, "Speed x3 (48)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 48 end
end)
AddCard(pgMove, "Speed Normal (16)", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = 16 end
end)

AddSectionLabel(pgMove, "Gravity")
AddCard(pgMove, "Moon Gravity", function() Workspace.Gravity = 25 end)
AddCard(pgMove, "Low Gravity", function() Workspace.Gravity = 50 end)
AddCard(pgMove, "Normal Gravity", function() Workspace.Gravity = 196.2 end)

AddSectionLabel(pgMove, "Jump")
AddCard(pgMove, "Jump Power Boost", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = 200 end
end)
AddCard(pgMove, "Jump Normal", function()
    local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = 50 end
end)

AddSectionLabel(pgMove, "Utility")
AddCard(pgMove, "Teleport to Mouse", function()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and Mouse.Target then
        root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
    end
end)

-- ============ SETTINGS ============
AddSectionLabel(pgMisc, "Options")
AddToggleCard(pgMisc, "Auto-hide on Respawn", function(enabled)
    if enabled then
        State.ActiveLoops["autoHide"] = LocalPlayer.CharacterAdded:Connect(function()
            Container.Visible = false
        end)
    else
        StopEffect("autoHide")
    end
end)

AddSectionLabel(pgMisc, "Field of View")
AddCard(pgMisc, "Wide FOV (100)", function()
    local camera = Workspace.CurrentCamera
    TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 100}):Play()
end)
AddCard(pgMisc, "Normal FOV (70)", function()
    local camera = Workspace.CurrentCamera
    TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
end)
AddCard(pgMisc, "Narrow FOV (50)", function()
    local camera = Workspace.CurrentCamera
    TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 50}):Play()
end)

AddSectionLabel(pgMisc, "About")
local infoCard = Instance.new("Frame")
infoCard.Parent = pgMisc
infoCard.BackgroundColor3 = CurrentTheme.BG_MID
infoCard.Size = UDim2.new(1, 0, 0, 84)
infoCard.BorderSizePixel = 0
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 9)
Reg("bg_mid", infoCard)
local infoText = Instance.new("TextLabel")
infoText.Parent = infoCard
infoText.BackgroundTransparency = 1
infoText.Position = UDim2.new(0, 12, 0, 8)
infoText.Size = UDim2.new(1, -24, 1, -16)
infoText.Font = Enum.Font.Gotham
infoText.Text = "Vertex Hub — universal cosmetics & shaders for any Roblox game.\nClick the top pill (or press RightShift) to hide/show.\nDrag the menu from the header or top bar.\nSwitch themes using the dots in the top-right corner."
infoText.TextColor3 = TEXT_DIM
infoText.TextSize = 10
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true

-- ============ SEARCH FILTERING ============
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = SearchBox.Text:lower()

    if query == "" then
        for pid, btn in pairs(navButtons) do btn.Visible = true end
        for pid, page in pairs(pages) do
            for _, card in pairs(page:GetChildren()) do
                if card:GetAttribute("SearchText") then card.Visible = true end
            end
        end
        return
    end

    local firstMatchPage = nil
    for pid, page in pairs(pages) do
        local anyMatch = false
        for _, card in pairs(page:GetChildren()) do
            local searchText = card:GetAttribute("SearchText")
            if searchText then
                local match = searchText:find(query, 1, true) ~= nil
                card.Visible = match
                if match then anyMatch = true end
            end
        end
        if anyMatch and not firstMatchPage then firstMatchPage = pid end
        navButtons[pid].Visible = anyMatch
    end

    if firstMatchPage and currentPage ~= firstMatchPage then
        for pid, page in pairs(pages) do page.Visible = (pid == firstMatchPage) end
        for pid, btn in pairs(navButtons) do btn.BackgroundTransparency = (pid == firstMatchPage) and 0.2 or 1 end
        currentPage = firstMatchPage
        breadcrumb.Text = "Search: " .. SearchBox.Text
    end
end)

print("✅ [VERTEX HUB v2.0] Loaded — shaders, trails, cosmetics, themes all ready.")
