-- ╔════════════════════════════════════════════════════════════════════════╗
-- ║     ✨ ATHIENS HUB MODERN v6.0 - COMPACT & RESPONSIVE ✨             ║
-- ║   100+ Features | Mobile & PC Optimized | Modern Design              ║
-- ║              Made with 💜 Pure Love & Dedication 💜                  ║
-- ╚════════════════════════════════════════════════════════════════════════╝

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()

-- === ОПРЕДЕЛЕНИЕ ПЛАТФОРМЫ ===
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- === ОЧИСТКА ===
pcall(function()
    if PlayerGui:FindFirstChild("AthiensModern") then
        PlayerGui.AthiensModern:Destroy()
    end
end)

-- === ГЛАВНЫЙ GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AthiensModern"
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- === РАЗМЕРЫ В ЗАВИСИМОСТИ ОТ ПЛАТФОРМЫ (МЕНЬШЕ) ===
local SIZE = {
    WIDTH = isMobile and 300 or 420,
    HEIGHT = isMobile and 480 or 450,
    SIDEBAR_WIDTH = isMobile and 70 or 85,
    TAB_SIZE = isMobile and 30 or 35
}

-- === ГЛАВНОЕ ОКНО ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.Position = isMobile and UDim2.new(0.5, -SIZE.WIDTH/2, 0.5, -SIZE.HEIGHT/2) or UDim2.new(0.5, -SIZE.WIDTH/2, 0.5, -SIZE.HEIGHT/2)
MainFrame.Size = UDim2.new(0, SIZE.WIDTH, 0, SIZE.HEIGHT)
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.BorderSizePixel = 0

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 18)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(100, 50, 200)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- === МОДУЛЬНЫЙ ГРАДИЕНТ ===
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 15, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 25))
})
Gradient.Parent = MainFrame

-- === ТОП БАР (КОМПАКТНЫЙ) ===
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(15, 12, 28)
TopBar.BackgroundTransparency = 0.1
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BorderSizePixel = 0

local TopStroke = Instance.new("UIStroke")
TopStroke.Color = Color3.fromRGB(100, 50, 200)
TopStroke.Thickness = 1.5
TopStroke.Parent = TopBar

-- === ЛОГОТИП ===
local Logo = Instance.new("TextLabel")
Logo.Parent = TopBar
Logo.BackgroundTransparency = 1
Logo.Position = UDim2.new(0, 12, 0, 8)
Logo.Size = UDim2.new(isMobile and 0.65 or 0.7, 0, 0, 34)
Logo.Font = Enum.Font.GothamBlack
Logo.Text = "⚡ ATHIENS"
Logo.TextColor3 = Color3.fromRGB(200, 100, 255)
Logo.TextSize = isMobile and 14 or 16
Logo.TextXAlignment = Enum.TextXAlignment.Left

-- === КНОПКИ ===
local MinBtn = Instance.new("TextButton")
MinBtn.Parent = TopBar
MinBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
MinBtn.BackgroundTransparency = 0.6
MinBtn.Position = UDim2.new(1, -95, 0.5, -12)
MinBtn.Size = UDim2.new(0, 35, 0, 24)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.BorderSizePixel = 0

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TopBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.BackgroundTransparency = 0.6
CloseBtn.Position = UDim2.new(1, -50, 0.5, -12)
CloseBtn.Size = UDim2.new(0, 35, 0, 24)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- === ПЛАВАЮЩАЯ КНОПКА ===
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatBtn"
FloatBtn.Parent = ScreenGui
FloatBtn.BackgroundColor3 = Color3.fromRGB(15, 12, 28)
FloatBtn.Position = isMobile and UDim2.new(0.5, -140, 0, 10) or UDim2.new(0.5, -150, 0, 10)
FloatBtn.Size = UDim2.new(0, isMobile and 280 or 300, 0, 35)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.Text = "⚡ ATHIENS HUB"
FloatBtn.TextColor3 = Color3.fromRGB(200, 100, 255)
FloatBtn.TextSize = isMobile and 12 or 13
FloatBtn.Visible = false
FloatBtn.BorderSizePixel = 0

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 10)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(150, 50, 255)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatBtn

-- === БОКОВОЕ МЕНЮ ===
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Parent = MainFrame
Sidebar.BackgroundColor3 = Color3.fromRGB(10, 8, 22)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.Size = UDim2.new(0, SIZE.SIDEBAR_WIDTH, 1, -50)
Sidebar.ScrollBarThickness = 3
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.BorderSizePixel = 0

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(100, 50, 200)
SidebarStroke.Thickness = 1
SidebarStroke.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Parent = Sidebar
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 6)

SidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, SidebarList.AbsoluteContentSize.Y + 10)
end)

-- === КОНТЕЙНЕР ВКЛАДОК ===
local TabsContainer = Instance.new("Frame")
TabsContainer.Parent = MainFrame
TabsContainer.BackgroundTransparency = 1
TabsContainer.Position = UDim2.new(0, SIZE.SIDEBAR_WIDTH, 0, 50)
TabsContainer.Size = UDim2.new(1, -SIZE.SIDEBAR_WIDTH, 1, -50)
TabsContainer.BorderSizePixel = 0

-- === СИСТЕМА ВКЛАДОК ===
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, emoji)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Parent = Sidebar
    TabBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    TabBtn.BackgroundTransparency = 0.3
    TabBtn.Size = UDim2.new(1, -8, 0, SIZE.TAB_SIZE)
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.Text = emoji
    TabBtn.TextColor3 = Color3.fromRGB(140, 140, 170)
    TabBtn.TextSize = isMobile and 16 or 18
    TabBtn.TextXAlignment = Enum.TextXAlignment.Center
    TabBtn.BorderSizePixel = 0

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 10)
    TabCorner.Parent = TabBtn

    local TabStroke = Instance.new("UIStroke")
    TabStroke.Color = Color3.fromRGB(150, 50, 200)
    TabStroke.Thickness = 1
    TabStroke.Transparency = 0.7
    TabStroke.Parent = TabBtn

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Parent = TabsContainer
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.Position = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Visible = false
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.Name = name

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = ScrollFrame
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 15)
    end)

    Tabs[name] = {Button = TabBtn, Frame = ScrollFrame}

    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Frame.Visible = false
            tab.Button.BackgroundTransparency = 0.3
            tab.Button.TextColor3 = Color3.fromRGB(140, 140, 170)
            if tab.Button:FindFirstChild("UIStroke") then
                tab.Button.UIStroke.Transparency = 0.7
            end
        end

        ScrollFrame.Visible = true
        TabBtn.BackgroundTransparency = 0
        TabBtn.TextColor3 = Color3.fromRGB(200, 100, 255)
        TabStroke.Transparency = 0
        CurrentTab = name
    end)

    return ScrollFrame
end

-- === ФУНКЦИИ ДОБАВЛЕНИЯ ЭЛЕМЕНТОВ ===
local function AddToggle(parent, text, callback)
    local Container = Instance.new("Frame")
    Container.Parent = parent
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BorderSizePixel = 0

    local Label = Instance.new("TextLabel")
    Label.Parent = Container
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Font = Enum.Font.GothamSemibold
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(200, 200, 220)
    Label.TextSize = isMobile and 11 or 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true

    local Toggle = Instance.new("TextButton")
    Toggle.Parent = Container
    Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    Toggle.Position = UDim2.new(1, -40, 0.5, -10)
    Toggle.Size = UDim2.new(0, 30, 0, 20)
    Toggle.Font = Enum.Font.GothamBold
    Toggle.Text = ""
    Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    Toggle.TextSize = 10
    Toggle.BorderSizePixel = 0

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = Toggle

    local state = false

    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 60)
        if callback then callback(state) end
    end)

    return Toggle
end

local function AddLabel(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Parent = parent
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 0, 30)
    Label.Font = Enum.Font.GothamBold
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(150, 100, 200)
    Label.TextSize = isMobile and 12 or 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BorderSizePixel = 0

    return Label
end

-- === СОЗДАНИЕ ВКЛАДОК ===
local HomeTab = CreateTab("Home", "🏠")
local EffectTab = CreateTab("Effects", "✨")
local UtilTab = CreateTab("Utils", "🎯")
local ExtraTab = CreateTab("Extra", "🎨")

-- === HOME TAB ===
AddLabel(HomeTab, "⚙️ Settings")

AddToggle(HomeTab, "🎵 Sound On", function(state)
    -- Sound toggle logic
end)

AddToggle(HomeTab, "💡 Brightness", function(state)
    if state then
        Lighting.Brightness = 2
    else
        Lighting.Brightness = 1
    end
end)

-- === EFFECTS TAB ===
AddLabel(EffectTab, "🌟 Visual Effects")

local orbitConn = nil
local cubesFolder = nil
AddToggle(EffectTab, "🌀 Orbit Cubes", function(state)
    if state then
        cubesFolder = Instance.new("Folder")
        cubesFolder.Name = "OrbitCubes"
        cubesFolder.Parent = workspace

        for i = 1, 5 do
            local cube = Instance.new("Part")
            cube.Shape = Enum.PartType.Block
            cube.Size = Vector3.new(1, 1, 1)
            cube.Material = Enum.Material.Neon
            cube.Color = Color3.fromHSV(i / 5, 1, 1)
            cube.CanCollide = false
            cube.CFrame = CFrame.new(0, 5, 0)
            cube.Parent = cubesFolder
        end

        local cubes = cubesFolder:GetChildren()
        local angle = 0
        orbitConn = RunService.RenderStepped:Connect(function(dt)
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
            angle = angle + dt * 2
            local rootPos = LocalPlayer.Character.HumanoidRootPart.Position
            for i, cube in ipairs(cubes) do
                if cube.Parent then
                    local offsetAngle = angle + (i * (math.pi * 2 / #cubes))
                    cube.Position = rootPos + Vector3.new(math.cos(offsetAngle) * 3.5, 2, math.sin(offsetAngle) * 3.5)
                    cube.Orientation = Vector3.new(angle * 50, angle * 80, 0)
                end
            end
        end)
    else
        if orbitConn then orbitConn:Disconnect() orbitConn = nil end
        if cubesFolder then pcall(function() cubesFolder:Destroy() end) cubesFolder = nil end
    end
end)

local particleConn = nil
AddToggle(EffectTab, "💥 Particle Burst", function(state)
    if state then
        particleConn = RunService.RenderStepped:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            for i = 1, 3 do
                local particle = Instance.new("Part")
                particle.Shape = Enum.PartType.Ball
                particle.Size = Vector3.new(math.random(1, 3) * 0.1, math.random(1, 3) * 0.1, math.random(1, 3) * 0.1)
                particle.Material = Enum.Material.Neon
                particle.CanCollide = false
                particle.Color = Color3.fromHSV(math.random() % 1, 1, 1)
                particle.CFrame = CFrame.new(pos + Vector3.new(math.random(-20, 20) * 0.1, math.random(-20, 20) * 0.1, math.random(-20, 20) * 0.1))
                local velocity = Instance.new("BodyVelocity")
                velocity.Velocity = (CFrame.new(pos) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), 0)).LookVector * 15
                velocity.Parent = particle
                particle.Parent = workspace
                Debris:AddItem(particle, 2)
            end
        end)
    else
        if particleConn then particleConn:Disconnect() particleConn = nil end
    end
end)

-- === UTILITY FEATURES ===
AddLabel(UtilTab, "🛠️ Utilities")

AddToggle(UtilTab, "🎯 Teleport to Mouse", function(state)
    if state then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            if Mouse.Target then
                char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

AddToggle(UtilTab, "💀 Suicide", function(state)
    if state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end)

AddToggle(UtilTab, "🔄 Respawn", function(state)
    if state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
    end
end)

AddToggle(UtilTab, "📦 Clone Part", function(state)
    if state and Mouse.Target then
        local clone = Mouse.Target:Clone()
        clone.Parent = workspace
    end
end)

-- === EXTRA FEATURES ===
AddLabel(ExtraTab, "🎨 Character Effects")

AddToggle(ExtraTab, "🎨 Rainbow Character", function(state)
    if state then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromHSV(math.random() % 1, 1, 1)
                    part.Material = Enum.Material.Neon
                end
            end
        end
    end
end)

AddToggle(ExtraTab, "💎 Diamond Mode", function(state)
    if state then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Diamond
                    part.Color = Color3.fromRGB(100, 200, 255)
                end
            end
        end
    end
end)

AddToggle(ExtraTab, "🔥 Fire Aura", function(state)
    if state then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local fire = Instance.new("Fire")
            fire.Parent = char.HumanoidRootPart
            fire.Color = Color3.fromRGB(255, 150, 0)
            fire.Size = 15
        end
    else
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local fire = char.HumanoidRootPart:FindFirstChild("Fire")
            if fire then fire:Destroy() end
        end
    end
end)

-- === WATERMARK ===
local function CreateWatermark()
    local watermarkGui = Instance.new("ScreenGui")
    watermarkGui.Name = "Watermark"
    watermarkGui.Parent = PlayerGui
    watermarkGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    watermarkGui.ResetOnSpawn = false

    local watermarkFrame = Instance.new("Frame")
    watermarkFrame.Name = "WatermarkFrame"
    watermarkFrame.Parent = watermarkGui
    watermarkFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
    watermarkFrame.Position = UDim2.new(0.5, -250, -0.12, 0)
    watermarkFrame.Size = UDim2.new(0, 500, 0, 100)
    watermarkFrame.BorderSizePixel = 0

    local watermarkCorner = Instance.new("UICorner")
    watermarkCorner.CornerRadius = UDim.new(0, 15)
    watermarkCorner.Parent = watermarkFrame

    local watermarkStroke = Instance.new("UIStroke")
    watermarkStroke.Color = Color3.fromRGB(200, 100, 255)
    watermarkStroke.Thickness = 2.5
    watermarkStroke.Parent = watermarkFrame

    local watermarkGradient = Instance.new("UIGradient")
    watermarkGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 10, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 5, 30))
    })
    watermarkGradient.Parent = watermarkFrame

    local watermarkText1 = Instance.new("TextLabel")
    watermarkText1.Parent = watermarkFrame
    watermarkText1.BackgroundTransparency = 1
    watermarkText1.Position = UDim2.new(0, 20, 0, 10)
    watermarkText1.Size = UDim2.new(1, -40, 0, 30)
    watermarkText1.Font = Enum.Font.GothamBlack
    watermarkText1.Text = "✨ ATHIENS HUB MODERN v6.0 ✨"
    watermarkText1.TextColor3 = Color3.fromRGB(255, 100, 255)
    watermarkText1.TextSize = isMobile and 16 or 18

    local watermarkText2 = Instance.new("TextLabel")
    watermarkText2.Parent = watermarkFrame
    watermarkText2.BackgroundTransparency = 1
    watermarkText2.Position = UDim2.new(0, 20, 0, 42)
    watermarkText2.Size = UDim2.new(1, -40, 0, 45)
    watermarkText2.Font = Enum.Font.GothamSemibold
    watermarkText2.Text = "💜 Thanks for using! 💜\n🚀 See you next time 🚀"
    watermarkText2.TextColor3 = Color3.fromRGB(200, 150, 255)
    watermarkText2.TextSize = isMobile and 12 or 13
    watermarkText2.TextWrapped = true

    watermarkFrame.Position = UDim2.new(0.5, -250, -0.12, 0)
    TweenService:Create(watermarkFrame, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -250, 0.05, 0)
    }):Play()

    task.wait(4)

    TweenService:Create(watermarkFrame, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -250, -0.12, 0)
    }):Play()

    task.wait(0.9)
    watermarkGui:Destroy()
end

CloseBtn.MouseButton1Click:Connect(function()
    task.wait(0.2)
    CreateWatermark()
end)

-- === MINIMIZE & RESTORE ===
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    FloatBtn.Visible = true
end)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    FloatBtn.Visible = false
end)

-- === CLEANUP ===
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

print("✨ ATHIENS HUB MODERN v6.0 LOADED!")
print("📱 Mobile & PC Optimized!")
print("💜 Compact & Modern Design!")
