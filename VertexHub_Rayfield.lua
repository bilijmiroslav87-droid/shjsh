if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function GetChar() return LocalPlayer.Character end

local State = { ActiveLoops = {} }
local function StopEffect(id)
    if State.ActiveLoops[id] then
        pcall(function() State.ActiveLoops[id]:Disconnect() end)
        State.ActiveLoops[id] = nil
    end
end

-- ============ LOAD RAYFIELD (proven, widely-used UI library) ============
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Vertex Hub",
    LoadingTitle = "Vertex Hub",
    LoadingSubtitle = "Universal cosmetics & visuals",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ============ RELIABLE COSMETIC ATTACHMENT ============
-- Anchored parts repositioned every frame from the head's CFrame — offsetCFrame
-- must include ANY rotation needed (e.g. CFrame.Angles for cylinder discs),
-- because assigning .CFrame each frame overwrites .Orientation entirely.
local function ClearCosmetic(name)
    StopEffect("cosmetic_" .. name)
    local char = GetChar()
    if char then
        local old = char:FindFirstChild(name)
        if old then old:Destroy() end
    end
end

local function AttachCosmetic(name, parts)
    ClearCosmetic(name)
    local char = GetChar()
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    local holder = Instance.new("Model")
    holder.Name = name
    for _, entry in ipairs(parts) do
        entry.part.Anchored = true
        entry.part.CanCollide = false
        entry.part.Massless = true
        entry.part.Parent = holder
    end
    holder.Parent = char

    State.ActiveLoops["cosmetic_" .. name] = RunService.Heartbeat:Connect(function()
        if not head.Parent then
            StopEffect("cosmetic_" .. name)
            return
        end
        local headCF = head.CFrame
        for _, entry in ipairs(parts) do
            if entry.part.Parent then
                entry.part.CFrame = headCF * entry.offsetCFrame
            end
        end
    end)
end

-- ============ TAB: COSMETICS ============
local CosmeticsTab = Window:CreateTab("Cosmetics", 4483362458)
local HeadwearSection = CosmeticsTab:CreateSection("Headwear")

CosmeticsTab:CreateButton({
    Name = "China Hat",
    Callback = function()
        local function Lerp(c1, c2, t)
            return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
        end

        local colorBottom = Color3.fromRGB(150, 80, 220)
        local colorTop = Color3.fromRGB(255, 210, 120)
        local rot90 = CFrame.Angles(0, 0, math.rad(90))
        local parts = {}

        local brim = Instance.new("Part")
        brim.Name = "Brim"
        brim.Shape = Enum.PartType.Cylinder
        brim.Size = Vector3.new(0.25, 5.6, 5.6)
        brim.Material = Enum.Material.SmoothPlastic
        brim.Color = Color3.fromRGB(20, 18, 25)
        table.insert(parts, {part = brim, offsetCFrame = CFrame.new(0, 1.0, 0) * rot90})

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
            table.insert(parts, {part = layer, offsetCFrame = CFrame.new(0, yOffset, 0) * rot90})
        end

        local tip = Instance.new("Part")
        tip.Name = "Tip"
        tip.Shape = Enum.PartType.Ball
        tip.Size = Vector3.new(0.3, 0.3, 0.3)
        tip.Material = Enum.Material.Neon
        tip.Color = colorTop
        table.insert(parts, {part = tip, offsetCFrame = CFrame.new(0, 1.08 + coneHeight + 0.15, 0)})

        AttachCosmetic("ChinaHat", parts)
    end,
})

CosmeticsTab:CreateButton({
    Name = "Party Cone",
    Callback = function()
        local cone = Instance.new("Part")
        cone.Name = "Cone"
        cone.Size = Vector3.new(1, 1, 1)
        cone.Material = Enum.Material.SmoothPlastic
        cone.Color = Color3.fromRGB(255, 40, 150)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Pyramid
        mesh.Scale = Vector3.new(2.2, 3.4, 2.2)
        mesh.Parent = cone

        AttachCosmetic("PartyCone", {
            {part = cone, offsetCFrame = CFrame.new(0, 2.1, 0)}
        })
    end,
})

CosmeticsTab:CreateButton({
    Name = "Neon Halo",
    Callback = function()
        local halo = Instance.new("Part")
        halo.Name = "Halo"
        halo.Shape = Enum.PartType.Cylinder
        halo.Size = Vector3.new(0.12, 2.2, 2.2)
        halo.Material = Enum.Material.Neon
        halo.Color = Color3.fromRGB(0, 255, 255)

        AttachCosmetic("Halo", {
            {part = halo, offsetCFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))}
        })
    end,
})

CosmeticsTab:CreateButton({
    Name = "Gold Crown",
    Callback = function()
        local crown = Instance.new("Part")
        crown.Name = "Crown"
        crown.Shape = Enum.PartType.Cylinder
        crown.Size = Vector3.new(0.25, 1.5, 1.5)
        crown.Material = Enum.Material.Metal
        crown.Color = Color3.fromRGB(255, 215, 0)

        AttachCosmetic("Crown", {
            {part = crown, offsetCFrame = CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90))}
        })
    end,
})

CosmeticsTab:CreateButton({
    Name = "Wizard Hat",
    Callback = function()
        local hat = Instance.new("Part")
        hat.Name = "Hat"
        hat.Size = Vector3.new(1, 1, 1)
        hat.Material = Enum.Material.SmoothPlastic
        hat.Color = Color3.fromRGB(70, 20, 140)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Pyramid
        mesh.Scale = Vector3.new(2.4, 4, 2.4)
        mesh.Parent = hat

        AttachCosmetic("WizardHat", {
            {part = hat, offsetCFrame = CFrame.new(0, 2.6, 0)}
        })
    end,
})

CosmeticsTab:CreateButton({
    Name = "Devil Horns",
    Callback = function()
        local parts = {}
        for _, side in ipairs({-1, 1}) do
            local horn = Instance.new("Part")
            horn.Name = "Horn"
            horn.Size = Vector3.new(1, 1, 1)
            horn.Material = Enum.Material.SmoothPlastic
            horn.Color = Color3.fromRGB(180, 0, 0)
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Pyramid
            mesh.Scale = Vector3.new(0.7, 1.2, 0.7)
            mesh.Parent = horn
            table.insert(parts, {
                part = horn,
                offsetCFrame = CFrame.new(0.45 * side, 0.9, 0) * CFrame.Angles(0, 0, math.rad(15 * side))
            })
        end
        AttachCosmetic("DevilHorns", parts)
    end,
})

CosmeticsTab:CreateButton({
    Name = "Flower Crown",
    Callback = function()
        local petalColors = {
            Color3.fromRGB(255, 130, 180), Color3.fromRGB(255, 210, 100),
            Color3.fromRGB(180, 130, 255), Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 170, 120),
        }
        local parts = {}
        for i = 1, 6 do
            local ang = (i - 1) * (math.pi * 2 / 6)
            local flower = Instance.new("Part")
            flower.Name = "Flower"
            flower.Shape = Enum.PartType.Ball
            flower.Size = Vector3.new(0.45, 0.45, 0.45)
            flower.Material = Enum.Material.SmoothPlastic
            flower.Color = petalColors[i]
            table.insert(parts, {
                part = flower,
                offsetCFrame = CFrame.new(math.cos(ang) * 1.05, 0.55, math.sin(ang) * 1.05)
            })
        end
        AttachCosmetic("FlowerCrown", parts)
    end,
})

local ManageHatsSection = CosmeticsTab:CreateSection("Manage")
CosmeticsTab:CreateButton({
    Name = "Remove All Hats",
    Callback = function()
        for _, name in ipairs({"ChinaHat", "PartyCone", "Halo", "Crown", "WizardHat", "DevilHorns", "FlowerCrown"}) do
            ClearCosmetic(name)
        end
    end,
})

-- ============ TAB: CHARACTER ============
local CharTab = Window:CreateTab("Character", 4483362458)
local MaterialsSection = CharTab:CreateSection("Materials")

CharTab:CreateButton({
    Name = "Rainbow Neon",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromHSV(math.random(), 0.9, 1)
            end
        end
    end,
})
CharTab:CreateButton({
    Name = "Gold Metal",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Metal
                part.Color = Color3.fromRGB(255, 215, 0)
            end
        end
    end,
})
CharTab:CreateButton({
    Name = "Cyan Neon",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Neon
                part.Color = Color3.fromRGB(0, 255, 255)
            end
        end
    end,
})
CharTab:CreateButton({
    Name = "Glass Body",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Glass
                part.Transparency = 0.5
            end
        end
    end,
})
CharTab:CreateButton({
    Name = "Chrome Body",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Material = Enum.Material.Foil
                part.Color = Color3.fromRGB(220, 220, 230)
            end
        end
    end,
})

local VisibilitySection = CharTab:CreateSection("Visibility")
CharTab:CreateButton({
    Name = "Invisible",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Transparency = 0.9 end
        end
    end,
})
CharTab:CreateButton({
    Name = "Visible",
    Callback = function()
        local char = GetChar()
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.Transparency = 0 end
        end
    end,
})

local SizeSection = CharTab:CreateSection("Size")
CharTab:CreateSlider({
    Name = "Body Scale",
    Range = {0.3, 3},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(value)
        local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
        if h then
            for _, s in pairs(h:GetChildren()) do
                if s.Name:match("Scale") then s.Value = value end
            end
        end
    end,
})

-- ============ TAB: VISUALS ============
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local OrbitSection = VisualTab:CreateSection("Orbit Effects")

local function ClearOrbits()
    StopEffect("cubesXY"); StopEffect("cubesXZ")
    for _, v in pairs(Workspace:GetChildren()) do
        if v.Name == "OrbitCubes" then v:Destroy() end
    end
end

VisualTab:CreateButton({
    Name = "Orbit Cubes (XY)",
    Callback = function()
        ClearOrbits()
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
    end,
})
VisualTab:CreateButton({
    Name = "Orbit Cubes (XZ)",
    Callback = function()
        ClearOrbits()
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
    end,
})
VisualTab:CreateButton({
    Name = "Stop Orbits",
    Callback = ClearOrbits,
})

local AuraSection = VisualTab:CreateSection("Auras")
local function ClearAura()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, v in pairs(root:GetChildren()) do
        if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v:Destroy() end
    end
end

VisualTab:CreateButton({
    Name = "Fire Aura",
    Callback = function()
        ClearAura()
        local root = GetChar() and GetChar():FindFirstChild("HumanoidRootPart")
        if not root then return end
        local fire = Instance.new("Fire")
        fire.Parent = root
        fire.Color = Color3.fromRGB(255, 100, 0)
        fire.SecondaryColor = Color3.fromRGB(255, 50, 0)
        fire.Size = 15
        fire.Heat = 15
    end,
})
VisualTab:CreateButton({
    Name = "Smoke Aura",
    Callback = function()
        ClearAura()
        local root = GetChar() and GetChar():FindFirstChild("HumanoidRootPart")
        if not root then return end
        local smoke = Instance.new("Smoke")
        smoke.Parent = root
        smoke.Color = Color3.fromRGB(80, 80, 80)
        smoke.Size = 12
        smoke.Opacity = 0.8
    end,
})
VisualTab:CreateButton({
    Name = "Sparkles Aura",
    Callback = function()
        ClearAura()
        local root = GetChar() and GetChar():FindFirstChild("HumanoidRootPart")
        if not root then return end
        local sp = Instance.new("Sparkles")
        sp.Parent = root
        sp.SparkleColor = Color3.fromRGB(255, 255, 150)
    end,
})
VisualTab:CreateButton({
    Name = "Clear Aura",
    Callback = ClearAura,
})

local TrailSection = VisualTab:CreateSection("Trails")
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

local function MakeTrail(colorSeq, lifetime)
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
    trail.Parent = root
end

VisualTab:CreateButton({
    Name = "Rainbow Trail",
    Callback = function()
        MakeTrail(ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 150)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255)),
        }), 1.0)
    end,
})
VisualTab:CreateButton({
    Name = "Purple Trail",
    Callback = function() MakeTrail(ColorSequence.new(Color3.fromRGB(170, 90, 255)), 0.8) end,
})
VisualTab:CreateButton({
    Name = "Fire Trail",
    Callback = function()
        MakeTrail(ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 30, 0)),
        }), 0.6)
    end,
})
VisualTab:CreateButton({
    Name = "Remove Trail",
    Callback = ClearTrail,
})

local ParticleSection = VisualTab:CreateSection("World Particles")

local function ClearWorldParticles()
    StopEffect("worldParticles")
    local old = Workspace:FindFirstChild("WorldParticleEmitter")
    if old then old:Destroy() end
end

local function SpawnWorldParticles(preset)
    ClearWorldParticles()
    local char = GetChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local emitterPart = Instance.new("Part")
    emitterPart.Name = "WorldParticleEmitter"
    emitterPart.Size = Vector3.new(40, 1, 40)
    emitterPart.Transparency = 1
    emitterPart.Anchored = true
    emitterPart.CanCollide = false
    emitterPart.Parent = Workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = preset.rate
    emitter.Lifetime = preset.lifetime
    emitter.Speed = preset.speed
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Size = preset.size
    emitter.Color = ColorSequence.new(preset.color)
    emitter.Transparency = NumberSequence.new(preset.transparency)
    emitter.Acceleration = preset.acceleration
    emitter.Parent = emitterPart

    State.ActiveLoops["worldParticles"] = RunService.Heartbeat:Connect(function()
        if not root.Parent then
            ClearWorldParticles()
            return
        end
        emitterPart.Position = root.Position + Vector3.new(0, 15, 0)
    end)
end

VisualTab:CreateButton({
    Name = "Snowfall",
    Callback = function()
        SpawnWorldParticles({
            rate = 40, lifetime = NumberRange.new(3, 5), speed = NumberRange.new(2, 4),
            size = NumberSequence.new(0.3), color = Color3.fromRGB(255, 255, 255),
            transparency = 0.2, acceleration = Vector3.new(0, -5, 0)
        })
    end,
})
VisualTab:CreateButton({
    Name = "Falling Embers",
    Callback = function()
        SpawnWorldParticles({
            rate = 30, lifetime = NumberRange.new(2, 4), speed = NumberRange.new(1, 3),
            size = NumberSequence.new(0.25), color = Color3.fromRGB(255, 140, 40),
            transparency = 0.3, acceleration = Vector3.new(0, -3, 0)
        })
    end,
})
VisualTab:CreateButton({
    Name = "Magic Sparkles",
    Callback = function()
        SpawnWorldParticles({
            rate = 35, lifetime = NumberRange.new(1.5, 3), speed = NumberRange.new(1, 2),
            size = NumberSequence.new(0.35), color = Color3.fromRGB(190, 120, 255),
            transparency = 0.2, acceleration = Vector3.new(0, 0, 0)
        })
    end,
})
VisualTab:CreateButton({
    Name = "Clear World Particles",
    Callback = ClearWorldParticles,
})

local JumpCircleSection = VisualTab:CreateSection("Jump Circle")

local function EnableJumpCircle(ringColor)
    StopEffect("jumpCircle")
    local char = GetChar()
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    State.ActiveLoops["jumpCircle"] = humanoid.StateChanged:Connect(function(_, newState)
        if newState ~= Enum.HumanoidStateType.Jumping then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local ring = Instance.new("Part")
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.2, 0.2, 0.2)
        ring.Material = Enum.Material.Neon
        ring.Color = ringColor
        ring.Anchored = true
        ring.CanCollide = false
        ring.Transparency = 0.2
        ring.CFrame = root.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
        ring.Parent = Workspace

        TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
            Size = Vector3.new(0.2, 6, 6),
            Transparency = 1
        }):Play()

        task.delay(0.5, function() ring:Destroy() end)
    end)
end

VisualTab:CreateButton({
    Name = "Jump Circle: Purple",
    Callback = function() EnableJumpCircle(Color3.fromRGB(170, 90, 255)) end,
})
VisualTab:CreateButton({
    Name = "Jump Circle: Gold",
    Callback = function() EnableJumpCircle(Color3.fromRGB(255, 210, 90)) end,
})
VisualTab:CreateButton({
    Name = "Disable Jump Circle",
    Callback = function() StopEffect("jumpCircle") end,
})

-- ============ TAB: SHADERS ============
local ShaderTab = Window:CreateTab("Shaders", 4483362458)
local ShaderPresetSection = ShaderTab:CreateSection("Full Presets")

local GFX_DEFAULTS = {}
for _, p in ipairs({"Brightness", "ExposureCompensation", "ClockTime", "OutdoorAmbient", "Ambient"}) do
    pcall(function() GFX_DEFAULTS[p] = Lighting[p] end)
end

local function CleanShaders()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj.Name:sub(1, 6) == "Shader" then obj:Destroy() end
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

ShaderTab:CreateButton({
    Name = "RTX Ultra (Bloom + DOF + Rays)",
    Callback = function()
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
    end,
})
ShaderTab:CreateButton({
    Name = "Cinematic Film Grain",
    Callback = function()
        CleanShaders()
        local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
        TweenService:Create(cc, SHADER_TWEEN, {Brightness = -0.02, Contrast = 0.35, Saturation = -0.15, TintColor = Color3.fromRGB(235, 225, 210)}):Play()
        local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
        TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.35, Size = 18, Threshold = 1.6}):Play()
        TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.4, ExposureCompensation = 0.2, ClockTime = 16}):Play()
    end,
})
ShaderTab:CreateButton({
    Name = "Neon Vivid",
    Callback = function()
        CleanShaders()
        local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
        TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0.06, Contrast = 0.32, Saturation = 0.55, TintColor = Color3.fromRGB(255, 250, 250)}):Play()
        local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
        TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 1.5, Size = 32, Threshold = 0.75}):Play()
        TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.8, ExposureCompensation = 0.5, ClockTime = 0.5}):Play()
    end,
})
ShaderTab:CreateButton({
    Name = "Foggy Horror",
    Callback = function()
        CleanShaders()
        local cc = GetShaderFX("ColorCorrectionEffect", "ShaderCC")
        TweenService:Create(cc, SHADER_TWEEN, {Brightness = 0, Contrast = 0.15, Saturation = -0.35, TintColor = Color3.fromRGB(215, 225, 215)}):Play()
        local bloom = GetShaderFX("BloomEffect", "ShaderBloom")
        TweenService:Create(bloom, SHADER_TWEEN, {Intensity = 0.3, Size = 16, Threshold = 2.0}):Play()
        local atmo = GetShaderFX("Atmosphere", "ShaderAtmo")
        TweenService:Create(atmo, SHADER_TWEEN, {Density = 0.55, Glare = 0.1, Haze = 2.2, Color = Color3.fromRGB(160, 170, 160), Decay = Color3.fromRGB(70, 80, 65)}):Play()
        TweenService:Create(Lighting, SHADER_TWEEN, {Brightness = 2.4, ExposureCompensation = 0.25, ClockTime = 5}):Play()
    end,
})

local ManageShaderSection = ShaderTab:CreateSection("Manage")
ShaderTab:CreateButton({
    Name = "Reset Shaders",
    Callback = function()
        CleanShaders()
        local atmo = Lighting:FindFirstChild("ShaderAtmo")
        if atmo then atmo:Destroy() end
        TweenService:Create(Lighting, SHADER_TWEEN, GFX_DEFAULTS):Play()
    end,
})

-- ============ TAB: SKYBOX ============
local SkyTab = Window:CreateTab("Skybox", 4483362458)
local AtmoSection = SkyTab:CreateSection("Atmosphere Themes")

SkyTab:CreateButton({
    Name = "Purple Nebula",
    Callback = function()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
        atm.Parent = Lighting
        atm.Color = Color3.fromRGB(150, 80, 220)
        atm.Decay = Color3.fromRGB(100, 40, 180)
        atm.Density = 0.4
        atm.Glare = 0.2
        atm.Haze = 2.2
        Lighting.ClockTime = 18
    end,
})
SkyTab:CreateButton({
    Name = "Red Sunset",
    Callback = function()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
        atm.Parent = Lighting
        atm.Color = Color3.fromRGB(220, 100, 60)
        atm.Decay = Color3.fromRGB(150, 50, 30)
        atm.Density = 0.35
        atm.Glare = 0.1
        atm.Haze = 2.8
        Lighting.ClockTime = 18
    end,
})
SkyTab:CreateButton({
    Name = "Cyan Sky",
    Callback = function()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
        atm.Parent = Lighting
        atm.Color = Color3.fromRGB(100, 200, 255)
        atm.Decay = Color3.fromRGB(50, 120, 200)
        atm.Density = 0.25
        atm.Glare = 0.4
        atm.Haze = 1.5
        Lighting.ClockTime = 12
    end,
})
SkyTab:CreateButton({
    Name = "Clear Sky",
    Callback = function()
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm:Destroy() end
        Lighting.ClockTime = 12
        Lighting.Brightness = 2
    end,
})

local TimeSection = SkyTab:CreateSection("Time & Brightness")
SkyTab:CreateSlider({
    Name = "Time of Day",
    Range = {0, 24},
    Increment = 0.5,
    CurrentValue = 12,
    Callback = function(value) Lighting.ClockTime = value end,
})
SkyTab:CreateSlider({
    Name = "Brightness",
    Range = {0, 8},
    Increment = 0.2,
    CurrentValue = 2,
    Callback = function(value) Lighting.Brightness = value end,
})

-- ============ TAB: MOVEMENT ============
local MoveTab = Window:CreateTab("Movement", 4483362458)
local SpeedSection = MoveTab:CreateSection("Speed & Jump")

MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(value)
        local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = value end
    end,
})
MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 250},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(value)
        local h = GetChar() and GetChar():FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = value end
    end,
})

local GravitySection = MoveTab:CreateSection("Gravity")
MoveTab:CreateButton({ Name = "Moon Gravity", Callback = function() Workspace.Gravity = 25 end })
MoveTab:CreateButton({ Name = "Low Gravity", Callback = function() Workspace.Gravity = 50 end })
MoveTab:CreateButton({ Name = "Normal Gravity", Callback = function() Workspace.Gravity = 196.2 end })

local UtilSection = MoveTab:CreateSection("Utility")
MoveTab:CreateButton({
    Name = "Teleport to Mouse",
    Callback = function()
        local char = GetChar()
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and Mouse.Target then
            root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end,
})

-- ============ TAB: SETTINGS ============
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local FOVSection = SettingsTab:CreateSection("Camera")

SettingsTab:CreateSlider({
    Name = "Field of View",
    Range = {40, 120},
    Increment = 5,
    CurrentValue = 70,
    Callback = function(value)
        Workspace.CurrentCamera.FieldOfView = value
    end,
})

Rayfield:Notify({
    Title = "Vertex Hub",
    Content = "Loaded successfully — all cosmetics fixed and working.",
    Duration = 5,
})
