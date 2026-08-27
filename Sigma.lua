-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Forward-declare переменные, которые используются в разных секциях
local flying = false
local flyConn = nil
local flyPoseConn = nil
local flySpeed = 50
local speedActive = false
local walkSpeed = 16
local speedMaintainConn = nil

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

-- ====== KILASIK FLING ======
local FlingActive = false
local OldPos = nil
local FPDH = workspace.FallenPartsDestroyHeight

local function KilasikFling(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not (Character and Humanoid and RootPart) then return end

    if RootPart.Velocity.Magnitude < 50 then
        OldPos = RootPart.CFrame
    end

    if THumanoid and THumanoid.Sit then return end

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end

    if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            end
        until Time + TimeToWait < tick() or not FlingActive
    end

    workspace.FallenPartsDestroyHeight = 0 / 0

    local BV = Instance.new("BodyVelocity")
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(0, 0, 0)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid

    if OldPos then
        repeat
            RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
            Character:SetPrimaryPartCFrame(OldPos * CFrame.new(0, 0.5, 0))
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity = Vector3.new()
                    part.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - OldPos.p).Magnitude < 25
        workspace.FallenPartsDestroyHeight = FPDH
    end
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
    for _, btn in pairs(tpListButtons) do
        if btn then btn:Destroy() end
    end
    tpListButtons = {}

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
                end
            end)

            table.insert(tpListButtons, btn)
        end
    end
    tpListContainer.CanvasSize = UDim2.new(0, 0, 0, #tpListButtons * 31 + 6)
end

tpBtn.MouseButton1Click:Connect(function()
    tpListVisible = not tpListVisible
    tpListContainer.Visible = tpListVisible
    if tpListVisible then refreshTpList() end
end)

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
    tool.ToolTip = "Стреляй — KILASIK флинг!"

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
                FlingActive = true
                task.spawn(function()
                    KilasikFling(hitPlayer)
                    FlingActive = false
                end)
            end
        end

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

-- ====== КРАСНЫЕ ГЛАЗА ======
local function addRedEyes(char)
    local head = char:FindFirstChild("Head")
    if not head then return end

    local existing = char:FindFirstChild("RedEyeLeft")
    if existing then existing:Destroy() end
    local existing2 = char:FindFirstChild("RedEyeRight")
    if existing2 then existing2:Destroy() end

    local eyeL = Instance.new("Part")
    eyeL.Name = "RedEyeLeft"
    eyeL.Size = Vector3.new(0.15, 0.15, 0.05)
    eyeL.Color = Color3.fromRGB(255, 0, 0)
    eyeL.Material = Enum.Material.Neon
    eyeL.CanCollide = false
    eyeL.Anchored = false
    eyeL.CFrame = head.CFrame * CFrame.new(-0.2, 0.1, -0.5)
    eyeL.Parent = char

    local weldL = Instance.new("WeldConstraint")
    weldL.Part0 = head
    weldL.Part1 = eyeL
    weldL.Parent = eyeL

    local lightL = Instance.new("PointLight")
    lightL.Color = Color3.fromRGB(255, 0, 0)
    lightL.Brightness = 3
    lightL.Range = 5
    lightL.Parent = eyeL

    local eyeR = Instance.new("Part")
    eyeR.Name = "RedEyeRight"
    eyeR.Size = Vector3.new(0.15, 0.15, 0.05)
    eyeR.Color = Color3.fromRGB(255, 0, 0)
    eyeR.Material = Enum.Material.Neon
    eyeR.CanCollide = false
    eyeR.Anchored = false
    eyeR.CFrame = head.CFrame * CFrame.new(0.2, 0.1, -0.5)
    eyeR.Parent = char

    local weldR = Instance.new("WeldConstraint")
    weldR.Part0 = head
    weldR.Part1 = eyeR
    weldR.Parent = eyeR

    local lightR = Instance.new("PointLight")
    lightR.Color = Color3.fromRGB(255, 0, 0)
    lightR.Brightness = 3
    lightR.Range = 5
    lightR.Parent = eyeR
end

local function removeRedEyes(char)
    if not char then return end
    local eL = char:FindFirstChild("RedEyeLeft")
    if eL then eL:Destroy() end
    local eR = char:FindFirstChild("RedEyeRight")
    if eR then eR:Destroy() end
end

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
    local char = LocalPlayer.Character
    if not root or not humanoid or not char then return end

    if flying then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        flyBtn.Text = "Полёт [" .. flySpeed .. "] ВКЛ"
        flySpeedPanel.Visible = true
        addRedEyes(char)

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

            local t = os.clock()
            local sway = math.sin(t * 6) * 0.03
            local armSway = math.sin(t * 6) * math.rad(3)

            local upperTorso = c:FindFirstChild("UpperTorso")
            if upperTorso then
                local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
                local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
                local waist = c:FindFirstChild("LowerTorso") and c.LowerTorso:FindFirstChild("Waist")
                local head = c:FindFirstChild("Head")
                local neck = head and (head:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck"))
                local rightHip = c:FindFirstChild("RightLeg") and c:FindFirstChild("RightHip")
                local leftHip = c:FindFirstChild("LeftLeg") and c:FindFirstChild("LeftHip")
                local rightKnee = c:FindFirstChild("RightLeg") and c.RightLeg:FindFirstChild("RightKnee")
                local leftKnee = c:FindFirstChild("LeftLeg") and c.LeftLeg:FindFirstChild("LeftKnee")
                local rightAnkle = c:FindFirstChild("RightFoot") and c.RightFoot:FindFirstChild("RightAnkle")
                local leftAnkle = c:FindFirstChild("LeftFoot") and c.LeftFoot:FindFirstChild("LeftAnkle")

                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-90), math.rad(15) + armSway, math.rad(-5)) end
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-90), math.rad(-15) - armSway, math.rad(5)) end
                if rightHip then rightHip.Transform = CFrame.Angles(math.rad(-5 + sway * 10), 0, math.rad(-3)) end
                if leftHip then leftHip.Transform = CFrame.Angles(math.rad(-5 - sway * 10), 0, math.rad(3)) end
                if rightKnee then rightKnee.Transform = CFrame.Angles(0, 0, 0) end
                if leftKnee then leftKnee.Transform = CFrame.Angles(0, 0, 0) end
                if rightAnkle then rightAnkle.Transform = CFrame.Angles(math.rad(-10), 0, 0) end
                if leftAnkle then leftAnkle.Transform = CFrame.Angles(math.rad(-10), 0, 0) end
                if waist then waist.Transform = CFrame.Angles(math.rad(80), 0, 0) end
                if neck then neck.Transform = CFrame.Angles(math.rad(-80), 0, 0) end
            else
                local torso = c:FindFirstChild("Torso")
                if torso then
                    local rightShoulder = torso:FindFirstChild("Right Shoulder")
                    local leftShoulder = torso:FindFirstChild("Left Shoulder")
                    local rightHip = torso:FindFirstChild("Right Hip")
                    local leftHip = torso:FindFirstChild("Left Hip")
                    local head = c:FindFirstChild("Head")
                    local neck = head and head:FindFirstChild("Neck")
                    local rootJoint = c:FindFirstChild("HumanoidRootPart") and c.HumanoidRootPart:FindFirstChild("RootJoint")

                    if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-90), math.rad(15) + armSway, math.rad(-5)) end
                    if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-90), math.rad(-15) - armSway, math.rad(5)) end
                    if rightHip then rightHip.Transform = CFrame.Angles(math.rad(-5 + sway * 10), 0, math.rad(-3)) end
                    if leftHip then leftHip.Transform = CFrame.Angles(math.rad(-5 - sway * 10), 0, math.rad(3)) end
                    if neck then neck.Transform = CFrame.Angles(math.rad(-80), 0, 0) end
                    if rootJoint then rootJoint.Transform = CFrame.Angles(math.rad(80), 0, 0) end
                end
            end
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyPoseConn then flyPoseConn:Disconnect() flyPoseConn = nil end
        if speedActive then
            humanoid.WalkSpeed = walkSpeed
        else
            humanoid.WalkSpeed = 16
        end
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
        flyBtn.Text = "Полёт [" .. flySpeed .. "]"
        flySpeedPanel.Visible = false
        removeRedEyes(LocalPlayer.Character)
    end
end)

-- ====== КНОПКА 5: СКОРОСТЬ ХОДЬБЫ ======
local speedBtn = createMenuButton("Скорость [16]", Color3.fromRGB(255, 140, 0))

local speedPanel = Instance.new("Frame")
speedPanel.Size = UDim2.new(1, -20, 0, 36)
speedPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
speedPanel.BorderSizePixel = 0
speedPanel.Visible = false
speedPanel.Parent = contentFrame

local speedDown = Instance.new("TextButton")
speedDown.Size = UDim2.new(0, 36, 0, 30)
speedDown.Position = UDim2.new(0, 5, 0, 3)
speedDown.Text = "−"
speedDown.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
speedDown.TextColor3 = Color3.fromRGB(255, 255, 255)
speedDown.Font = Enum.Font.SourceSansBold
speedDown.TextSize = 20
speedDown.Parent = speedPanel

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -82, 0, 30)
speedLabel.Position = UDim2.new(0, 41, 0, 3)
speedLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
speedLabel.Text = "Скорость: 16"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 14
speedLabel.Parent = speedPanel

local speedUp = Instance.new("TextButton")
speedUp.Size = UDim2.new(0, 36, 0, 30)
speedUp.Position = UDim2.new(1, -41, 0, 3)
speedUp.Text = "+"
speedUp.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
speedUp.TextColor3 = Color3.fromRGB(255, 255, 255)
speedUp.Font = Enum.Font.SourceSansBold
speedUp.TextSize = 20
speedUp.Parent = speedPanel

local speedPanelVisible = false

local function updateSpeedLabel()
    speedBtn.Text = "Скорость [" .. walkSpeed .. "]"
    speedLabel.Text = "Скорость: " .. walkSpeed
end

local function applyWalkSpeed()
    local humanoid = getHumanoid(LocalPlayer)
    if humanoid and speedActive and not flying then
        humanoid.WalkSpeed = walkSpeed
    end
end

speedDown.MouseButton1Click:Connect(function()
    walkSpeed = math.max(16, walkSpeed - 10)
    updateSpeedLabel()
    applyWalkSpeed()
end)

speedUp.MouseButton1Click:Connect(function()
    walkSpeed = math.min(500, walkSpeed + 10)
    updateSpeedLabel()
    applyWalkSpeed()
end)

speedBtn.MouseButton1Click:Connect(function()
    speedPanelVisible = not speedPanelVisible
    speedPanel.Visible = speedPanelVisible

    if speedPanelVisible then
        speedActive = true
        speedBtn.Text = "Скорость [" .. walkSpeed .. "] ВКЛ"
        applyWalkSpeed()
    else
        speedActive = false
        speedBtn.Text = "Скорость [" .. walkSpeed .. "]"
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid and not flying then
            humanoid.WalkSpeed = 16
        end
    end
end)

speedMaintainConn = RunService.Heartbeat:Connect(function()
    if speedActive and not flying then
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid then
            humanoid.WalkSpeed = walkSpeed
        end
    end
end)

-- ====== КНОПКА 6: МНЕ ПОВЕЗЁТ ======
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

-- ====== КНОПКА 7: ПУЛЬТ ОТ ЯДЕРКИ ======
local nukeBtn = createMenuButton("Пульт от ядерки", Color3.fromRGB(200, 50, 50))
local nukeGiven = false

local function createNukeRemote()
    local tool = Instance.new("Tool")
    tool.Name = "Пульт от ядерки"
    tool.RequiresHandle = true
    tool.ToolTip = "Нажми ЛКМ — запустить ядерку!"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.5, 0.3, 0.8)
    handle.Color = Color3.fromRGB(30, 30, 35)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.Parent = tool

    local redBtn = Instance.new("Part")
    redBtn.Name = "RedButton"
    redBtn.Size = Vector3.new(0.3, 0.1, 0.3)
    redBtn.Color = Color3.fromRGB(255, 0, 0)
    redBtn.Material = Enum.Material.Neon
    redBtn.CanCollide = false
    redBtn.CFrame = handle.CFrame * CFrame.new(0, 0.2, 0)
    redBtn.Parent = tool

    local weld1 = Instance.new("WeldConstraint")
    weld1.Part0 = handle
    weld1.Part1 = redBtn
    weld1.Parent = handle

    local antenna = Instance.new("Part")
    antenna.Name = "Antenna"
    antenna.Size = Vector3.new(0.05, 0.5, 0.05)
    antenna.Color = Color3.fromRGB(100, 100, 110)
    antenna.Material = Enum.Material.Metal
    antenna.CanCollide = false
    antenna.CFrame = handle.CFrame * CFrame.new(0, 0.4, -0.3)
    antenna.Parent = tool

    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = handle
    weld2.Part1 = antenna
    weld2.Parent = handle

    local indicator = Instance.new("Part")
    indicator.Name = "Indicator"
    indicator.Size = Vector3.new(0.08, 0.08, 0.08)
    indicator.Shape = Enum.PartType.Ball
    indicator.Color = Color3.fromRGB(0, 255, 0)
    indicator.Material = Enum.Material.Neon
    indicator.CanCollide = false
    indicator.CFrame = handle.CFrame * CFrame.new(0, 0.15, 0.25)
    indicator.Parent = tool

    local weld3 = Instance.new("WeldConstraint")
    weld3.Part0 = handle
    weld3.Part1 = indicator
    weld3.Parent = handle

    local indicatorLight = Instance.new("PointLight")
    indicatorLight.Color = Color3.fromRGB(0, 255, 0)
    indicatorLight.Brightness = 2
    indicatorLight.Range = 3
    indicatorLight.Parent = indicator

    tool.Activated:Connect(function()
        local localRoot = getRoot(LocalPlayer)
        if not localRoot then return end

        indicator.Color = Color3.fromRGB(255, 0, 0)
        indicatorLight.Color = Color3.fromRGB(255, 0, 0)

        local siren = Instance.new("Sound")
        siren.SoundId = "rbxassetid://130835443"
        siren.Volume = 2
        siren.Parent = handle
        siren:Play()

        local bombPos = localRoot.Position + Vector3.new(math.random(-30, 30), 200, math.random(-30, 30))
        local bomb = Instance.new("Part")
        bomb.Name = "NukeBomb"
        bomb.Size = Vector3.new(4, 8, 4)
        bomb.Color = Color3.fromRGB(40, 40, 50)
        bomb.Material = Enum.Material.Metal
        bomb.CanCollide = false
        bomb.Anchored = false
        bomb.CFrame = CFrame.new(bombPos)
        bomb.Parent = workspace

        local tail = Instance.new("Part")
        tail.Size = Vector3.new(2, 3, 2)
        tail.Color = Color3.fromRGB(60, 60, 70)
        tail.Material = Enum.Material.Metal
        tail.CanCollide = false
        tail.CFrame = bomb.CFrame * CFrame.new(0, 4, 0)
        tail.Parent = bomb

        local tailWeld = Instance.new("WeldConstraint")
        tailWeld.Part0 = bomb
        tailWeld.Part1 = tail
        tailWeld.Parent = bomb

        local bombLight = Instance.new("PointLight")
        bombLight.Color = Color3.fromRGB(255, 0, 0)
        bombLight.Brightness = 5
        bombLight.Range = 20
        bombLight.Parent = bomb

        local smoke = Instance.new("ParticleEmitter")
        smoke.Texture = "rbxassetid://243660364"
        smoke.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
        smoke.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 3),
            NumberSequenceKeypoint.new(1, 8),
        })
        smoke.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        smoke.Lifetime = NumberRange.new(1, 2)
        smoke.Rate = 50
        smoke.Speed = NumberRange.new(1, 3)
        smoke.Parent = bomb

        local blinkOn = true
        local bombSound = Instance.new("Sound")
        bombSound.SoundId = "rbxassetid://130835443"
        bombSound.Volume = 1.5
        bombSound.Parent = bomb

        local blinkConn
        blinkConn = RunService.Heartbeat:Connect(function()
            if not bomb or not bomb.Parent then
                if blinkConn then blinkConn:Disconnect() end
                return
            end

            blinkOn = not blinkOn
            bomb.Color = blinkOn and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 50)
            bombLight.Brightness = blinkOn and 10 or 2

            if blinkOn then
                bombSound:Play()
            end

            local root = getRoot(LocalPlayer)
            if root then
                local heightDiff = bomb.Position.Y - root.Position.Y
                if heightDiff < 15 then
                    if blinkConn then blinkConn:Disconnect() end

                    smoke.Enabled = false
                    bomb:Destroy()

                    local explosion = Instance.new("Explosion")
                    explosion.Position = root.Position
                    explosion.BlastRadius = 100
                    explosion.BlastPressure = 500000
                    explosion.DestroyJointRadiusPercent = 1
                    explosion.Parent = workspace

                    local blastBall = Instance.new("Part")
                    blastBall.Shape = Enum.PartType.Ball
                    blastBall.Size = Vector3.new(10, 10, 10)
                    blastBall.Color = Color3.fromRGB(255, 200, 50)
                    blastBall.Material = Enum.Material.Neon
                    blastBall.Anchored = true
                    blastBall.CanCollide = false
                    blastBall.CFrame = CFrame.new(root.Position)
                    blastBall.Parent = workspace

                    local boomSound = Instance.new("Sound")
                    boomSound.SoundId = "rbxassetid://130835443"
                    boomSound.Volume = 5
                    boomSound.Parent = blastBall
                    boomSound:Play()

                    task.spawn(function()
                        for i = 1, 30 do
                            if not blastBall or not blastBall.Parent then break end
                            blastBall.Size = blastBall.Size + Vector3.new(8, 8, 8)
                            blastBall.Transparency = i / 30
                            task.wait(0.03)
                        end
                        if blastBall then blastBall:Destroy() end
                    end)

                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(
                            math.random(-100, 100),
                            300,
                            math.random(-100, 100)
                        )
                    end

                    local humanoid = getHumanoid(LocalPlayer)
                    if humanoid then
                        humanoid.Health = 0
                    end

                    indicator.Color = Color3.fromRGB(0, 255, 0)
                    indicatorLight.Color = Color3.fromRGB(0, 255, 0)
                end
            end
        end)
    end)

    return tool
end

nukeBtn.MouseButton1Click:Connect(function()
    if nukeGiven then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        backpack = LocalPlayer:WaitForChild("Backpack")
    end
    local tool = createNukeRemote()
    tool.Parent = backpack
    nukeGiven = true
end)

-- ====== КНОПКА 8: КРАШ ======
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
    FlingActive = false
    speedActive = false
    if sigmaSound then sigmaSound:Stop() sigmaSound:Destroy() end
    if sigmaAuraConn then sigmaAuraConn:Disconnect() end
    if sigmaPoseConn then sigmaPoseConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    if flyPoseConn then flyPoseConn:Disconnect() end
    if godModeConn then godModeConn:Disconnect() end
    if speedMaintainConn then speedMaintainConn:Disconnect() end
    removeSigmaEffectsFromChar(LocalPlayer.Character)
    removeRedEyes(LocalPlayer.Character)
    screenGui:Destroy()
end)

-- ====== РЕСПАВН ======
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("HumanoidRootPart")

    if sigmaPlaying then
        task.wait(0.5)
        local newRoot = newChar:FindFirstChild("HumanoidRootPart")
        if newRoot then
            if sigmaSound then
                sigmaSound.Parent = newRoot
                sigmaSound:Play()
            end
            applySigmaToChar(newChar)
        end
    end

    if flying then
        local h = newChar:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed = 0
            h.JumpPower = 0
            h.JumpHeight = 0
        end
        task.wait(0.3)
        addRedEyes(newChar)
    end

    if speedActive then
        local h = newChar:FindFirstChildOfClass("Humanoid")
        if h then
            task.wait(0.5)
            h.WalkSpeed = walkSpeed
        end
    end

    if godModeConn and godModeConn.Connected then
        local h = newChar:FindFirstChildOfClass("Humanoid")
        if h then
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
    end

    pistolGiven = false
    nukeGiven = false
end)
