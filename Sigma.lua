-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SigmaGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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

-- ====== УТИЛИТЫ ======
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

local function findPlayer(name)
    if not name or name == "" then
        warn("Введите ник игрока!")
        return nil
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(name:lower()) then
            return plr
        end
    end
    warn("Игрок '" .. tostring(name) .. "' не найден!")
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

-- ====== ФЛИНГ (исправленный — через BodyAngularVelocity) ======
local flingConn = nil
local flingBAV = nil

local function flingPlayer(targetPlayer)
    -- Останавливаем предыдущий флинг если есть
    if flingConn then flingConn:Disconnect() flingConn = nil end
    if flingBAV then flingBAV:Destroy() flingBAV = nil end

    local targetRoot = getRoot(targetPlayer)
    local localRoot = getRoot(LocalPlayer)
    if not targetRoot or not localRoot then return end

    local originalCFrame = localRoot.CFrame

    -- BodyAngularVelocity — реальное физическое вращение
    flingBAV = Instance.new("BodyAngularVelocity")
    flingBAV.AngularVelocity = Vector3.new(0, 9999, 0)
    flingBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    flingBAV.P = math.huge
    flingBAV.Name = "FlingBAV"
    flingBAV.Parent = localRoot

    local elapsed = 0
    local duration = 3

    flingConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed >= duration then
            flingConn:Disconnect()
            flingConn = nil
            if flingBAV then
                flingBAV:Destroy()
                flingBAV = nil
            end
            -- Возвращаемся на исходную позицию
            localRoot.CFrame = originalCFrame
            print("Флинг завершён: " .. targetPlayer.Name)
            return
        end
        -- Постоянно телепортируемся в цель — держим контакт
        local currentTarget = getRoot(targetPlayer)
        if currentTarget then
            localRoot.CFrame = currentTarget.CFrame * CFrame.new(0, 0, 0)
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

-- ====== КНОПКА 1: ТЕЛЕПОРТ ======
local tpBtn = createMenuButton("ТП к игроку", Color3.fromRGB(40, 100, 160))

local tpInputContainer = Instance.new("Frame")
tpInputContainer.Size = UDim2.new(1, -20, 0, 70)
tpInputContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tpInputContainer.BorderSizePixel = 0
tpInputContainer.Visible = false
tpInputContainer.Parent = contentFrame

local tpTextBox = Instance.new("TextBox")
tpTextBox.Size = UDim2.new(1, -10, 0, 30)
tpTextBox.Position = UDim2.new(0, 5, 0, 5)
tpTextBox.PlaceholderText = "Введите ник игрока..."
tpTextBox.Text = ""
tpTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
tpTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
tpTextBox.Font = Enum.Font.SourceSans
tpTextBox.TextSize = 16
tpTextBox.ClearTextOnFocus = false
tpTextBox.Parent = tpInputContainer

local tpSubmitBtn = Instance.new("TextButton")
tpSubmitBtn.Size = UDim2.new(1, -10, 0, 28)
tpSubmitBtn.Position = UDim2.new(0, 5, 0, 38)
tpSubmitBtn.Text = "Телепортироваться"
tpSubmitBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 160)
tpSubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSubmitBtn.Font = Enum.Font.SourceSansBold
tpSubmitBtn.TextSize = 14
tpSubmitBtn.Parent = tpInputContainer

local tpInputVisible = false

tpBtn.MouseButton1Click:Connect(function()
    tpInputVisible = not tpInputVisible
    tpInputContainer.Visible = tpInputVisible
end)

tpSubmitBtn.MouseButton1Click:Connect(function()
    local targetPlayer = findPlayer(tpTextBox.Text)
    if not targetPlayer then return end
    local targetRoot = getRoot(targetPlayer)
    local localRoot = getRoot(LocalPlayer)
    if targetRoot and localRoot then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
        print("ТП к: " .. targetPlayer.Name)
    end
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
                -- Небольшая задержка чтобы отдача не мешала
                task.wait(0.1)
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
local sigmaHighlight = nil
local sigmaLight = nil
local sigmaParticles = nil

local function removeSigmaEffects()
    if sigmaHighlight then sigmaHighlight:Destroy() sigmaHighlight = nil end
    if sigmaLight then sigmaLight:Destroy() sigmaLight = nil end
    if sigmaParticles then sigmaParticles:Destroy() sigmaParticles = nil end
end

sigmaBtn.MouseButton1Click:Connect(function()
    if sigmaPlaying then
        sigmaPlaying = false
        if sigmaSound then sigmaSound:Stop() sigmaSound:Destroy() sigmaSound = nil end
        if sigmaAuraConn then sigmaAuraConn:Disconnect() end
        if sigmaPoseConn then sigmaPoseConn:Disconnect() end
        removeSigmaEffects()
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

    sigmaHighlight = Instance.new("Highlight")
    sigmaHighlight.FillColor = Color3.fromRGB(128, 0, 255)
    sigmaHighlight.OutlineColor = Color3.fromRGB(180, 80, 255)
    sigmaHighlight.FillTransparency = 0.7
    sigmaHighlight.OutlineTransparency = 0
    sigmaHighlight.Parent = char

    sigmaLight = Instance.new("PointLight")
    sigmaLight.Color = Color3.fromRGB(128, 0, 255)
    sigmaLight.Brightness = 5
    sigmaLight.Range = 15
    sigmaLight.Parent = localRoot

    sigmaParticles = Instance.new("ParticleEmitter")
    sigmaParticles.Texture = "rbxassetid://243660364"
    sigmaParticles.Color = ColorSequence.new(Color3.fromRGB(180, 80, 255))
    sigmaParticles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.5),
        NumberSequenceKeypoint.new(1, 0),
    })
    sigmaParticles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    sigmaParticles.Lifetime = NumberRange.new(1, 2)
    sigmaParticles.Rate = 40
    sigmaParticles.Speed = NumberRange.new(2, 4)
    sigmaParticles.SpreadAngle = Vector2.new(360, 360)
    sigmaParticles.Rotation = NumberRange.new(0, 360)
    sigmaParticles.RotSpeed = NumberRange.new(180, 360)
    sigmaParticles.LightEmission = 1
    sigmaParticles.Parent = localRoot

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

            if rightShoulder then
                rightShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(40), math.rad(-60))
            end
            if leftShoulder then
                leftShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(-40), math.rad(60))
            end
            if neck then
                neck.Transform = CFrame.Angles(math.rad(-20), 0, 0)
            end
        else
            local torso = c:FindFirstChild("Torso")
            if torso then
                local rightShoulder = torso:FindFirstChild("Right Shoulder")
                local leftShoulder = torso:FindFirstChild("Left Shoulder")
                local head = c:FindFirstChild("Head")
                local neck = head and head:FindFirstChild("Neck")

                if rightShoulder then
                    rightShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(40), math.rad(-60))
                end
                if leftShoulder then
                    leftShoulder.Transform = CFrame.Angles(math.rad(-30), math.rad(-40), math.rad(60))
                end
                if neck then
                    neck.Transform = CFrame.Angles(math.rad(-20), 0, 0)
                end
            end
        end
    end)

    sigmaAuraConn = RunService.Heartbeat:Connect(function()
        if not sigmaPlaying or not sigmaLight then return end
        local t = os.clock()
        sigmaLight.Brightness = 3 + math.sin(t * 4) * 2
        sigmaLight.Range = 12 + math.sin(t * 3) * 3
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

local function removeGodMode()
    if godModeConn then godModeConn:Disconnect() godModeConn = nil end
    local char = LocalPlayer.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            h.MaxHealth = 100
            h.Health = 100
            h.BreakJointsOnDeath = true
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            local gl = root:FindFirstChild("GodModeLight")
            if gl then gl:Destroy() end
        end
        local hl = char:FindFirstChild("GodModeHighlight")
        if hl then hl:Destroy() end
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

    local results = { "РЕЖИМ БОГА", "RESET", "РЕЖИМ БОГА", "RESET", "РЕЖИМ БОГА", "RESET" }
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
    if flingConn then flingConn:Disconnect() end
    if flingBAV then flingBAV:Destroy() end
    removeSigmaEffects()
    removeGodMode()
    screenGui:Destroy()
end)
