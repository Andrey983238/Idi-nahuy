-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SigmaGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ====== ПЕРЕТАСКИВАНИЕ ======
local function makeDraggable(frame, dragBar)
    local dragging = false
    local dragStart, startPos

    dragBar.MouseButton1Down:Connect(function()
        dragging = true
        dragStart = UserInputService:GetMouseLocation()
        startPos = frame.Position
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ====== УТИЛИТЫ (всегда берут текущий персонаж) ======
local function getRoot(player)
    local char = player.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHumanoid(player)
    local char = player.Character
    if char then
        return char:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function getPlayerFromPart(part)
    if not part then return nil end
    local char = part.Parent
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return Players:GetPlayerFromCharacter(char)
    end
    return nil
end

-- ====== ФЛИНГ (применяется к ЦЕЛИ, не к вам) ======
local flingConns = {}

local function flingPlayer(targetPlayer)
    -- Останавливаем старые
    for _, c in pairs(flingConns) do
        if c then c:Disconnect() end
    end
    flingConns = {}

    local targetRoot = getRoot(targetPlayer)
    if not targetRoot then return end

    -- BodyAngularVelocity на ЦЕЛЬ
    local bav = Instance.new("BodyAngularVelocity")
    bav.AngularVelocity = Vector3.new(0, 9999, 0)
    bav.MaxTorque = Vector3.new(0, math.huge, 0)
    bav.P = math.huge
    bav.Name = "FlingBAV"
    bav.Parent = targetRoot

    -- BodyVelocity — подбрасываем ЦЕЛЬ вверх
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(math.random(-50, 50), 300, math.random(-50, 50))
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = math.huge
    bv.Name = "FlingBV"
    bv.Parent = targetRoot

    local elapsed = 0
    local duration = 3

    flingConns[1] = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed >= duration then
            for _, c in pairs(flingConns) do
                if c then c:Disconnect() end
            end
            flingConns = {}
            if bav then bav:Destroy() end
            if bv then bv:Destroy() end
            print("Флинг завершён: " .. targetPlayer.Name)
            return
        end
        -- Поддерживаем вращение и подбрасывание
        local root = getRoot(targetPlayer)
        if root then
            if not root:FindFirstChild("FlingBAV") then
                bav.Parent = root
            end
            if not root:FindFirstChild("FlingBV") then
                bv.Parent = root
            end
        end
    end)

    print("Флинг запущен на: " .. targetPlayer.Name)
end

-- ====== ГЛАВНОЕ ОКНО ======
local windowContainer = Instance.new("Frame")
windowContainer.Name = "WindowContainer"
windowContainer.Size = UDim2.new(0, 280, 0, 420)
windowContainer.Position = UDim2.new(1, -300, 0.5, -210)
windowContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
windowContainer.BackgroundTransparency = 1
windowContainer.BorderSizePixel = 0
windowContainer.Parent = screenGui

local titleLabel = Instance.new("TextButton")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Сигма чит"
titleLabel.TextColor3 = Color3.fromRGB(128, 0, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 20
titleLabel.AutoButtonColor = false
titleLabel.Parent = windowContainer

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(1, 0, 0, 390)
mainWindow.Position = UDim2.new(0, 0, 0, 30)
mainWindow.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainWindow.BorderSizePixel = 0
mainWindow.Parent = windowContainer

local titleBar = Instance.new("TextButton")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
titleBar.BorderSizePixel = 0
titleBar.Text = "  SIGMA MENU"
titleBar.TextColor3 = Color3.fromRGB(128, 0, 255)
titleBar.Font = Enum.Font.SourceSansBold
titleBar.TextSize = 18
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.AutoButtonColor = false
titleBar.Parent = mainWindow

makeDraggable(windowContainer, titleBar)
makeDraggable(windowContainer, titleLabel)

local closeMenuBtn = Instance.new("TextButton")
closeMenuBtn.Size = UDim2.new(0, 30, 0, 30)
closeMenuBtn.Position = UDim2.new(1, -32, 0, 2)
closeMenuBtn.Text = "X"
closeMenuBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeMenuBtn.Font = Enum.Font.SourceSansBold
closeMenuBtn.TextSize = 16
closeMenuBtn.Parent = titleBar

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainWindow

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 6)
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
uiListLayout.Parent = contentFrame

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 8)
uiPadding.Parent = contentFrame

-- ====== КНОПКА ОТКРЫТИЯ/ЗАКРЫТИЯ ======
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 130, 0, 35)
toggleBtn.Position = UDim2.new(1, -140, 0, 20)
toggleBtn.Text = "Скрыть меню"
toggleBtn.BackgroundColor3 = Color3.fromRGB(128, 0, 255)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.Parent = screenGui

local menuOpen = true

toggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    windowContainer.Visible = menuOpen
    toggleBtn.Text = menuOpen and "Скрыть меню" or "Открыть меню"
end)

closeMenuBtn.MouseButton1Click:Connect(function()
    windowContainer.Visible = false
    menuOpen = false
    toggleBtn.Text = "Открыть меню"
end)

-- ====== ФУНКЦИЯ СОЗДАНИЯ КНОПКИ ======
local function createMenuButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = contentFrame
    return btn
end

-- ====== КНОПКА 1: ТЕЛЕПОРТ (список игроков) ======
local tpBtn = createMenuButton("ТП к игроку", Color3.fromRGB(40, 100, 160))

-- Контейнер для списка игроков
local tpListContainer = Instance.new("ScrollingFrame")
tpListContainer.Size = UDim2.new(1, -20, 0, 150)
tpListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tpListContainer.BorderSizePixel = 0
tpListContainer.ScrollBarThickness = 4
tpListContainer.Visible = false
tpListContainer.Parent = contentFrame

local tpListLayout = Instance.new("UIListLayout")
tpListLayout.Padding = UDim.new(0, 3)
tpListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpListLayout.Parent = tpListContainer

local tpListPadding = Instance.new("UIPadding")
tpListPadding.PaddingTop = UDim.new(0, 3)
tpListPadding.PaddingBottom = UDim.new(0, 3)
tpListPadding.Parent = tpListContainer

local tpListVisible = false
local tpListButtons = {}

local function refreshTpList()
    -- Очищаем старые кнопки
    for _, btn in pairs(tpListButtons) do
        if btn then btn:Destroy() end
    end
    tpListButtons = {}

    -- Добавляем текущих игроков
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Text = "  " .. plr.Name
            btn.Parent = tpListContainer

            btn.MouseButton1Click:Connect(function()
                local targetRoot = getRoot(plr)
                local localRoot = getRoot(LocalPlayer)
                if targetRoot and localRoot then
                    localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
                    print("ТП к: " .. plr.Name)
                end
            end)

            table.insert(tpListButtons, btn)
        end
    end

    -- Обновляем размер
    tpListContainer.CanvasSize = UDim2.new(0, 0, 0, #tpListButtons * 31 + 6)
end

tpBtn.MouseButton1Click:Connect(function()
    tpListVisible = not tpListVisible
    tpListContainer.Visible = tpListVisible
    if tpListVisible then
        refreshTpList()
    end
end)

-- Обновляем список при входе/выходе игроков
Players.PlayerAdded:Connect(function()
    if tpListVisible then refreshTpList() end
end)
Players.PlayerRemoving:Connect(function()
    if tpListVisible then refreshTpList() end
end)

-- ====== КНОПКА 2: ПИСТОЛЕТ ======
local pistolBtn = createMenuButton("Выдать пистолет", Color3.fromRGB(60, 120, 50))
local pistolGiven = false

local function createPistol()
    local tool = Instance.new("Tool")
    tool.Name = "Визуал Пистолет"
    tool.RequiresHandle = true
    tool.ToolTip = "Стреляй — флинг!"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 0.4, 1.8)
    handle.Color = Color3.fromRGB(40, 40, 45)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.Parent = tool

    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(0.25, 0.25, 1.2)
    barrel.Color = Color3.fromRGB(25, 25, 30)
    barrel.Material = Enum.Material.Metal
    barrel.CanCollide = false
    barrel.CFrame = handle.CFrame * CFrame.new(0, 0.15, -1.4)
    barrel.Parent = tool

    local weld1 = Instance.new("WeldConstraint")
    weld1.Part0 = handle
    weld1.Part1 = barrel
    weld1.Parent = handle

    local grip = Instance.new("Part")
    grip.Name = "Grip"
    grip.Size = Vector3.new(0.35, 0.9, 0.45)
    grip.Color = Color3.fromRGB(30, 30, 35)
    grip.Material = Enum.Material.Metal
    grip.CanCollide = false
    grip.CFrame = handle.CFrame * CFrame.new(0, -0.55, 0.3)
    grip.Parent = tool

    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = handle
    weld2.Part1 = grip
    weld2.Parent = handle

    local triggerPart = Instance.new("Part")
    triggerPart.Name = "Trigger"
    triggerPart.Size = Vector3.new(0.12, 0.25, 0.18)
    triggerPart.Color = Color3.fromRGB(50, 50, 55)
    triggerPart.Material = Enum.Material.Metal
    triggerPart.CanCollide = false
    triggerPart.CFrame = handle.CFrame * CFrame.new(0, -0.1, -0.25)
    triggerPart.Parent = tool

    local weld3 = Instance.new("WeldConstraint")
    weld3.Part0 = handle
    weld3.Part1 = triggerPart
    weld3.Parent = handle

    tool.Activated:Connect(function()
        local localRoot = getRoot(LocalPlayer)
        if not localRoot then return end

        -- Вспышка
        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.4, 0.4, 0.4)
        flash.Shape = Enum.PartType.Ball
        flash.Color = Color3.fromRGB(255, 220, 80)
        flash.Material = Enum.Material.Neon
        flash.CanCollide = false
        flash.Transparency = 0.2
        flash.CFrame = handle.CFrame * CFrame.new(0, 0.15, -2.2)
        flash.Parent = workspace

        local flashWeld = Instance.new("WeldConstraint")
        flashWeld.Part0 = handle
        flashWeld.Part1 = flash
        flashWeld.Parent = handle

        local shootSound = Instance.new("Sound")
        shootSound.SoundId = "rbxassetid://130835443"
        shootSound.Volume = 1
        shootSound.Parent = handle
        shootSound:Play()

        task.spawn(function()
            for i = 1, 8 do
                if not flash or not flash.Parent then break end
                flash.Transparency = 0.2 + (i / 8) * 0.8
                flash.Size = flash.Size + Vector3.new(0.15, 0.15, 0.15)
                task.wait(0.02)
            end
            if flash then flash:Destroy() end
        end)

        localRoot.AssemblyLinearVelocity = localRoot.CFrame.LookVector * -15

        -- Raycast
        local mouse = LocalPlayer:GetMouse()
        local rayOrigin = handle.Position
        local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * 500

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {LocalPlayer.Character}
        for _, part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(filterList, part)
            end
        end
        raycastParams.FilterDescendantsInstances = filterList

        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        if rayResult then
            local hitPlayer = getPlayerFromPart(rayResult.Instance)
            if hitPlayer and hitPlayer ~= LocalPlayer then
                print("Попадание по: " .. hitPlayer.Name .. " — флинг!")
                flingPlayer(hitPlayer)
            else
                print("Промах")
            end
        else
            print("Промах")
        end

        -- Луч
        local beam = Instance.new("Part")
        beam.Anchored = true
        beam.CanCollide = false
        beam.Material = Enum.Material.Neon
        beam.Color = Color3.fromRGB(255, 200, 50)
        beam.Transparency = 0.3
        beam.Size = Vector3.new(0.1, 0.1, 500)
        beam.CFrame = CFrame.new(rayOrigin, rayOrigin + rayDirection) * CFrame.new(0, 0, -250)
        beam.Parent = workspace

        task.spawn(function()
            for i = 1, 10 do
                beam.Transparency = 0.3 + (i / 10) * 0.7
                task.wait(0.02)
            end
            beam:Destroy()
        end)
    end)

    return tool
end

pistolBtn.MouseButton1Click:Connect(function()
    if pistolGiven then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        backpack = LocalPlayer:WaitForChild("Backpack")
    end
    local tool = createPistol()
    tool.Parent = backpack
    pistolGiven = true
    print("Пистолет выдан!")
end)

-- ====== КНОПКА 3: Я СИГМА ======
local sigmaBtn = createMenuButton("Я СИГМА", Color3.fromRGB(128, 0, 255))

local sigmaSound = nil
local sigmaPlaying = false
local sigmaAuraConn = nil
local sigmaPoseConn = nil

local function removeSigmaEffectsFromChar(char)
    if not char then return end
    local hl = char:FindFirstChild("SigmaHighlight")
    if hl then hl:Destroy() end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local light = root:FindFirstChild("SigmaLight")
        if light then light:Destroy() end
        local particles = root:FindFirstChild("SigmaParticles")
        if particles then particles:Destroy() end
    end
end

local function applySigmaToChar(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Name = "SigmaHighlight"
    hl.FillColor = Color3.fromRGB(128, 0, 255)
    hl.OutlineColor = Color3.fromRGB(180, 80, 255)
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = char

    local light = Instance.new("PointLight")
    light.Name = "SigmaLight"
    light.Color = Color3.fromRGB(128, 0, 255)
    light.Brightness = 5
    light.Range = 15
    light.Parent = root

    local particles = Instance.new("ParticleEmitter")
    particles.Name = "SigmaParticles"
    particles.Texture = "rbxassetid://243660364"
    particles.Color = ColorSequence.new(Color3.fromRGB(180, 80, 255))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Lifetime = NumberRange.new(1, 2)
    particles.Rate = 40
    particles.Speed = NumberRange.new(2, 4)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Rotation = NumberRange.new(0, 360)
    particles.RotSpeed = NumberRange.new(180, 360)
    particles.LightEmission = 1
    particles.Parent = root
end

sigmaBtn.MouseButton1Click:Connect(function()
    if sigmaPlaying then
        sigmaPlaying = false
        if sigmaSound then sigmaSound:Stop() sigmaSound:Destroy() sigmaSound = nil end
        if sigmaAuraConn then sigmaAuraConn:Disconnect() sigmaAuraConn = nil end
        if sigmaPoseConn then sigmaPoseConn:Disconnect() sigmaPoseConn = nil end
        removeSigmaEffectsFromChar(LocalPlayer.Character)
        sigmaBtn.Text = "Я СИГМА"
        return
    end

    local char = LocalPlayer.Character
    local localRoot = getRoot(LocalPlayer)
    if not char or not localRoot then return end

    sigmaSound = Instance.new("Sound")
    sigmaSound.SoundId = "rbxassetid://9046865451"
    sigmaSound.Volume = 2
    sigmaSound.Looped = true
    sigmaSound.Parent = localRoot
    sigmaSound:Play()
    sigmaPlaying = true
    sigmaBtn.Text = "Я СИГМА (ВКЛ)"

    applySigmaToChar(char)

    -- Поза
    sigmaPoseConn = RunService.RenderStepped:Connect(function()
        if not sigmaPlaying then return end
        local c = LocalPlayer.Character
        if not c then return end

        local upperTorso = c:FindFirstChild("UpperTorso")
        if upperTorso then
            local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
            local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
            local head = c:FindFirstChild("Head")
            local neck = head and head:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck")

            if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(40), math.rad(-60)) end
            if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(-40), math.rad(60)) end
            if neck then neck.Transform = CFrame.Angles(math.rad(-20), 0, 0) end
        else
            local torso = c:FindFirstChild("Torso")
            if torso then
                local rightShoulder = torso:FindFirstChild("Right Shoulder")
                local leftShoulder = torso:FindFirstChild("Left Shoulder")
                local head = c:FindFirstChild("Head")
                local neck = head and head:FindFirstChild("Neck")

                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(40), math.rad(-60)) end
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(-40), math.rad(60)) end
                if neck then neck.Transform = CFrame.Angles(math.rad(-20), 0, 0) end
            end
        end
    end)

    -- Пульсация света
    sigmaAuraConn = RunService.Heartbeat:Connect(function()
        if not sigmaPlaying then return end
        local root = getRoot(LocalPlayer)
        if not root then return end
        local light = root:FindFirstChild("SigmaLight")
        if light then
            local t = os.clock()
            light.Brightness = 3 + math.sin(t * 4) * 2
            light.Range = 12 + math.sin(t * 3) * 3
        end
    end)
end)

-- ====== КНОПКА 4: ПОЛЁТ ======
local flyBtn = createMenuButton("Полёт [50]", Color3.fromRGB(0, 150, 200))

local flySpeedPanel = Instance.new("Frame")
flySpeedPanel.Size = UDim2.new(1, -20, 0, 36)
flySpeedPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
flySpeedPanel.BorderSizePixel = 0
flySpeedPanel.Visible = false
flySpeedPanel.Parent = contentFrame

local flySpeedDown = Instance.new("TextButton")
flySpeedDown.Size = UDim2.new(0, 36, 0, 30)
flySpeedDown.Position = UDim2.new(0, 5, 0, 3)
flySpeedDown.Text = "−"
flySpeedDown.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
flySpeedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedDown.Font = Enum.Font.SourceSansBold
flySpeedDown.TextSize = 20
flySpeedDown.Parent = flySpeedPanel

local flySpeedLabel = Instance.new("TextLabel")
flySpeedLabel.Size = UDim2.new(1, -82, 0, 30)
flySpeedLabel.Position = UDim2.new(0, 41, 0, 3)
flySpeedLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
flySpeedLabel.Text = "Скорость: 50"
flySpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedLabel.Font = Enum.Font.SourceSans
flySpeedLabel.TextSize = 14
flySpeedLabel.Parent = flySpeedPanel

local flySpeedUp = Instance.new("TextButton")
flySpeedUp.Size = UDim2.new(0, 36, 0, 30)
flySpeedUp.Position = UDim2.new(1, -41, 0, 3)
flySpeedUp.Text = "+"
flySpeedUp.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
flySpeedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
flySpeedUp.Font = Enum.Font.SourceSansBold
flySpeedUp.TextSize = 20
flySpeedUp.Parent = flySpeedPanel

local flying = false
local flyConn = nil
local flyPoseConn = nil
local flySpeed = 50

local function updateFlyLabel()
    flyBtn.Text = "Полёт [" .. flySpeed .. "]"
    flySpeedLabel.Text = "Скорость: " .. flySpeed
end

flySpeedDown.MouseButton1Click:Connect(function()
    flySpeed = math.max(10, flySpeed - 10)
    updateFlyLabel()
end)

flySpeedUp.MouseButton1Click:Connect(function()
    flySpeed = math.min(500, flySpeed + 10)
    updateFlyLabel()
end)

flyBtn.MouseButton1Click:Connect(function()
    flying = not flying
    local root = getRoot(LocalPlayer)
    local humanoid = getHumanoid(LocalPlayer)
    if not root or not humanoid then return end

    if flying then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        flyBtn.Text = "Полёт [" .. flySpeed .. "] ВКЛ"
        flySpeedPanel.Visible = true

        local camera = workspace.CurrentCamera

        flyConn = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local root2 = getRoot(LocalPlayer)
            if not root2 then return end

            local camCFrame = camera.CFrame
            local forward = camCFrame.LookVector
            local right = camCFrame.RightVector
            local moveVec = Vector3.new(0, 0, 0)

            local keys = UserInputService:GetKeysPressed()
            for _, key in ipairs(keys) do
                if key.KeyCode == Enum.KeyCode.W then moveVec += forward
                elseif key.KeyCode == Enum.KeyCode.S then moveVec -= forward
                elseif key.KeyCode == Enum.KeyCode.A then moveVec -= right
                elseif key.KeyCode == Enum.KeyCode.D then moveVec += right
                elseif key.KeyCode == Enum.KeyCode.Space then moveVec += Vector3.new(0, 1, 0)
                elseif key.KeyCode == Enum.KeyCode.LeftShift then moveVec -= Vector3.new(0, 1, 0) end
            end

            if moveVec.Magnitude > 0 then moveVec = moveVec.Unit * flySpeed end
            root2.AssemblyLinearVelocity = moveVec
        end)

        flyPoseConn = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local c = LocalPlayer.Character
            if not c then return end

            local upperTorso = c:FindFirstChild("UpperTorso")
            if upperTorso then
                local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
                local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
                local waist = upperTorso.Parent:FindFirstChild("LowerTorso") and upperTorso.Parent.LowerTorso:FindFirstChild("Waist")
                local head = c:FindFirstChild("Head")
                local neck = head and (head:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck"))

                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-120), 0, math.rad(20)) end
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-120), 0, math.rad(-20)) end
                if waist then waist.Transform = CFrame.Angles(math.rad(15), 0, 0) end
                if neck then neck.Transform = CFrame.Angles(math.rad(10), 0, 0) end
            else
                local torso = c:FindFirstChild("Torso")
                if torso then
                    local rightShoulder = torso:FindFirstChild("Right Shoulder")
                    local leftShoulder = torso:FindFirstChild("Left Shoulder")
                    local head = c:FindFirstChild("Head")
                    local neck = head and head:FindFirstChild("Neck")
                    local rootJoint = c:FindFirstChild("HumanoidRootPart") and c.HumanoidRootPart:FindFirstChild("RootJoint")

                    if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-120), 0, math.rad(20)) end
                    if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-120), 0, math.rad(-20)) end
                    if neck then neck.Transform = CFrame.Angles(math.rad(10), 0, 0) end
                    if rootJoint then rootJoint.Transform = CFrame.Angles(math.rad(15), 0, 0) end
                end
            end
        end)
    else
        if flyConn then flyConn:Disconnect() end
        if flyPoseConn then flyPoseConn:Disconnect() end
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
        flyBtn.Text = "Полёт [" .. flySpeed .. "]"
        flySpeedPanel.Visible = false
    end
end)

-- ====== КНОПКА 5: МНЕ ПОВЕЗЁТ ======
local luckyBtn = createMenuButton("Мне повезёт", Color3.fromRGB(255, 180, 0))

local luckyRolling = false
local godModeConn = nil

local function applyGodMode()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.MaxHealth = math.huge
    humanoid.Health = math.huge
    humanoid.BreakJointsOnDeath = false

    if godModeConn then godModeConn:Disconnect() end
    godModeConn = RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.Health = h.MaxHealth end
    end)

    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local goldLight = Instance.new("PointLight")
        goldLight.Color = Color3.fromRGB(255, 215, 0)
        goldLight.Brightness = 8
        goldLight.Range = 20
        goldLight.Name = "GodModeLight"
        goldLight.Parent = root

        local goldHighlight = Instance.new("Highlight")
        goldHighlight.FillColor = Color3.fromRGB(255, 215, 0)
        goldHighlight.OutlineColor = Color3.fromRGB(255, 255, 100)
        goldHighlight.FillTransparency = 0.8
        goldHighlight.OutlineTransparency = 0
        goldHighlight.Name = "GodModeHighlight"
        goldHighlight.Parent = char
    end
end

luckyBtn.MouseButton1Click:Connect(function()
    if luckyRolling then return end
    luckyRolling = true
    luckyBtn.Text = "Крутим..."
    luckyBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 0)

    local rouletteFrame = Instance.new("Frame")
    rouletteFrame.Size = UDim2.new(0, 260, 0, 80)
    rouletteFrame.Position = UDim2.new(0.5, -130, 0.5, -40)
    rouletteFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    rouletteFrame.BorderSizePixel = 0
    rouletteFrame.Parent = screenGui

    local rouletteLabel = Instance.new("TextLabel")
    rouletteLabel.Size = UDim2.new(1, 0, 0, 50)
    rouletteLabel.Position = UDim2.new(0, 0, 0, 10)
    rouletteLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    rouletteLabel.BorderSizePixel = 0
    rouletteLabel.Text = "🎲"
    rouletteLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    rouletteLabel.Font = Enum.Font.SourceSansBold
    rouletteLabel.TextSize = 28
    rouletteLabel.Parent = rouletteFrame

    local rouletteResult = Instance.new("TextLabel")
    rouletteResult.Size = UDim2.new(1, 0, 0, 25)
    rouletteResult.Position = UDim2.new(0, 0, 0, 50)
    rouletteResult.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    rouletteResult.BorderSizePixel = 0
    rouletteResult.Text = ""
    rouletteResult.TextColor3 = Color3.fromRGB(255, 255, 255)
    rouletteResult.Font = Enum.Font.SourceSansBold
    rouletteResult.TextSize = 18
    rouletteResult.Parent = rouletteFrame

    local results = { "РЕЖИМ БОГА", "RESET", "РЕЖИМ БОГА", "RESET" }
    local ticks = 0
    local maxTicks = 20

    task.spawn(function()
        while ticks < maxTicks do
            ticks += 1
            local idx = (ticks % #results) + 1
            rouletteLabel.Text = results[idx]
            rouletteLabel.TextColor3 = (idx % 2 == 1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 80, 80)
            local delay = 0.03 + (ticks / maxTicks) * 0.15
            task.wait(delay)
        end

        local roll = math.random(1, 2)
        if roll == 1 then
            rouletteLabel.Text = "РЕЖИМ БОГА"
            rouletteLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
            rouletteResult.Text = "✨ Ты бессмертен! ✨"
            rouletteResult.TextColor3 = Color3.fromRGB(255, 215, 0)
            applyGodMode()
        else
            rouletteLabel.Text = "RESET"
            rouletteLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            rouletteResult.Text = "💥 Перезагрузка... 💥"
            rouletteResult.TextColor3 = Color3.fromRGB(255, 80, 80)

            task.wait(1.5)
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Health = 0 end
            end
        end

        task.wait(2.5)
        rouletteFrame:Destroy()
        luckyRolling = false
        luckyBtn.Text = "Мне повезёт"
        luckyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    end)
end)

-- ====== КНОПКА 6: КРАШ ======
local crashBtn = createMenuButton("Краш игры", Color3.fromRGB(160, 30, 30))

crashBtn.MouseButton1Click:Connect(function()
    task.wait(3)
    task.spawn(function()
        while true do
            for i = 1, 500 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(100, 100, 100)
                p.Anchored = false
                p.CanCollide = true
                p.Position = Vector3.new(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))
                p.Parent = workspace
            end
            task.wait(0.01)
        end
    end)
    task.spawn(function()
        while true do
            for i = 1, 200 do
                local f = Instance.new("Frame")
                f.Size = UDim2.new(1, 0, 1, 0)
                f.Parent = screenGui
            end
            task.wait(0.01)
        end
    end)
end)

-- ====== КНОПКА ЗАКРЫТИЯ ======
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(0, 130, 0, 30)
killBtn.Position = UDim2.new(1, -140, 0, 60)
killBtn.Text = "Закрыть скрипт"
killBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.SourceSans
killBtn.TextSize = 14
killBtn.Parent = screenGui

killBtn.MouseButton1Click:Connect(function()
    if sigmaSound then sigmaSound:Stop() sigmaSound:Destroy() end
    if sigmaAuraConn then sigmaAuraConn:Disconnect() end
    if sigmaPoseConn then sigmaPoseConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    if flyPoseConn then flyPoseConn:Disconnect() end
    if godModeConn then godModeConn:Disconnect() end
    for _, c in pairs(flingConns) do if c then c:Disconnect() end end
    removeSigmaEffectsFromChar(LocalPlayer.Character)
    screenGui:Destroy()
end)

-- ====== РЕСПАВН: переустановка эффектов после смерти ======
LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Ждём пока персонаж прогрузится
    newChar:WaitForChild("HumanoidRootPart")

    -- Если сигма активна — заново накладываем эффекты на новый персонаж
    if sigmaPlaying then
        task.wait(0.5)
        local newRoot = newChar:FindFirstChild("HumanoidRootPart")
        if newRoot then
            -- Переносим звук
            if sigmaSound then
                sigmaSound.Parent = newRoot
                sigmaSound:Play()
            end
            applySigmaToChar(newChar)
        end
    end

    -- Если полёт активен — заново обнуляем скорость
    if flying then
        local h = newChar:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = 0
            h.JumpPower = 0
            h.JumpHeight = 0
        end
    end

    -- Если режим бога активен — заново даём бессмертие
    local h = newChar:FindFirstChildOfClass("Humanoid")
    if h and godModeConn and godModeConn.Connected then
        task.wait(0.5)
        h.MaxHealth = math.huge
        h.Health = math.huge
        h.BreakJointsOnDeath = false

        local root = newChar:FindFirstChild("HumanoidRootPart")
        if root and not root:FindFirstChild("GodModeLight") then
            local goldLight = Instance.new("PointLight")
            goldLight.Color = Color3.fromRGB(255, 215, 0)
            goldLight.Brightness = 8
            goldLight.Range = 20
            goldLight.Name = "GodModeLight"
            goldLight.Parent = root
        end
        if not newChar:FindFirstChild("GodModeHighlight") then
            local goldHighlight = Instance.new("Highlight")
            goldHighlight.FillColor = Color3.fromRGB(255, 215, 0)
            goldHighlight.OutlineColor = Color3.fromRGB(255, 255, 100)
            goldHighlight.FillTransparency = 0.8
            goldHighlight.OutlineTransparency = 0
            goldHighlight.Name = "GodModeHighlight"
            goldHighlight.Parent = newChar
        end
    end

    -- Пистолет заново выдаётся в Backpack автоматически при респавне,
    -- но pistolGiven = true мешает. Сбрасываем, чтобы можно было выдать снова.
    pistolGiven = false
end)
