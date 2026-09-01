-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Forward-declare
local flying = false
local flyConn = nil
local flyPoseConn = nil
local flySpeed = 50
local speedActive = false
local walkSpeed = 16
local speedMaintainConn = nil
local nukeCooldown = false
local nukeAiming = false
local flyLaserActive = false
local flyLaserInputConn = nil
local flyLaserCooldown = false

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
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
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
tpListContainer.Size = UDim2.new(1, -20, 0, 200)
tpListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tpListContainer.BorderSizePixel = 0
tpListContainer.ScrollBarThickness = 4
tpListContainer.Visible = false
tpListContainer.Parent = contentFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, 30)
searchBox.Position = UDim2.new(0, 5, 0, 5)
searchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.SourceSans
searchBox.TextSize = 14
searchBox.Text = ""
searchBox.PlaceholderText = "Поиск ника..."
searchBox.ClearTextOnFocus = false
searchBox.Parent = tpListContainer

local searchHint = Instance.new("TextLabel")
searchHint.Size = UDim2.new(0, 80, 0, 30)
searchHint.Position = UDim2.new(0, 10, 0, 5)
searchHint.BackgroundTransparency = 1
searchHint.Text = "Поиск ника..."
searchHint.TextColor3 = Color3.fromRGB(150, 150, 160)
searchHint.Font = Enum.Font.SourceSans
searchHint.TextSize = 14
searchHint.TextXAlignment = Enum.TextXAlignment.Left
searchHint.Parent = tpListContainer
searchHint.Visible = true

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchHint.Visible = searchBox.Text == ""
end)

local tpPlayerList = Instance.new("ScrollingFrame")
tpPlayerList.Size = UDim2.new(1, 0, 0, 160)
tpPlayerList.Position = UDim2.new(0, 0, 0, 40)
tpPlayerList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tpPlayerList.BorderSizePixel = 0
tpPlayerList.ScrollBarThickness = 4
tpPlayerList.Parent = tpListContainer

local tpListLayout = Instance.new("UIListLayout")
tpListLayout.Padding = UDim.new(0, 3)
tpListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tpListLayout.Parent = tpPlayerList

local tpListPadding = Instance.new("UIPadding")
tpListPadding.PaddingTop = UDim.new(0, 3)
tpListPadding.PaddingBottom = UDim.new(0, 3)
tpListPadding.Parent = tpPlayerList

local tpListVisible = false
local tpListButtons = {}

local function refreshTpList()
    for _, btn in pairs(tpListButtons) do
        if btn then btn:Destroy() end
    end
    tpListButtons = {}

    local query = searchBox.Text:lower()
    local matchCount = 0

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local nameLower = plr.Name:lower()
            local displayNameLower = plr.DisplayName and plr.DisplayName:lower() or ""

            if query == "" or nameLower:find(query, 1, true) or displayNameLower:find(query, 1, true) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Font = Enum.Font.SourceSans
                btn.TextSize = 14
                btn.Text = "  " .. plr.Name
                btn.Parent = tpPlayerList

                btn.MouseButton1Click:Connect(function()
                    local targetRoot = getRoot(plr)
                    local localRoot = getRoot(LocalPlayer)
                    if targetRoot and localRoot then
                        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
                    end
                end)

                table.insert(tpListButtons, btn)
                matchCount += 1
            end
        end
    end

    if matchCount == 0 and query ~= "" then
        local noResult = Instance.new("TextLabel")
        noResult.Size = UDim2.new(1, -6, 0, 28)
        noResult.BackgroundTransparency = 1
        noResult.Text = "  Ничего не найдено"
        noResult.TextColor3 = Color3.fromRGB(200, 80, 80)
        noResult.Font = Enum.Font.SourceSans
        noResult.TextSize = 14
        noResult.TextXAlignment = Enum.TextXAlignment.Left
        noResult.Parent = tpPlayerList
        table.insert(tpListButtons, noResult)
        matchCount = 1
    end

    tpPlayerList.CanvasSize = UDim2.new(0, 0, 0, matchCount * 31 + 6)
end

tpBtn.MouseButton1Click:Connect(function()
    tpListVisible = not tpListVisible
    tpListContainer.Visible = tpListVisible
    if tpListVisible then refreshTpList() end
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
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
    tool.Name = "Пистолет"
    tool.RequiresHandle = true
    tool.ToolTip = "ЛКМ — стрелять + флинг"

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 0.35, 1.2)
    handle.Color = Color3.fromRGB(35, 35, 40)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.Parent = tool

    local barrel = Instance.new("Part")
    barrel.Name = "Barrel"
    barrel.Size = Vector3.new(0.15, 0.15, 1.5)
    barrel.Color = Color3.fromRGB(20, 20, 25)
    barrel.Material = Enum.Material.Metal
    barrel.CanCollide = false
    barrel.CFrame = handle.CFrame * CFrame.new(0, 0.05, -1.2)
    barrel.Parent = tool

    local weld1 = Instance.new("WeldConstraint")
    weld1.Part0 = handle
    weld1.Part1 = barrel
    weld1.Parent = handle

    local grip = Instance.new("Part")
    grip.Name = "Grip"
    grip.Size = Vector3.new(0.28, 0.7, 0.35)
    grip.Color = Color3.fromRGB(25, 25, 30)
    grip.Material = Enum.Material.Metal
    grip.CanCollide = false
    grip.CFrame = handle.CFrame * CFrame.new(0, -0.4, 0.25) * CFrame.Angles(math.rad(15), 0, 0)
    grip.Parent = tool

    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = handle
    weld2.Part1 = grip
    weld2.Parent = handle

    local guard = Instance.new("Part")
    guard.Name = "TriggerGuard"
    guard.Size = Vector3.new(0.1, 0.25, 0.3)
    guard.Color = Color3.fromRGB(40, 40, 45)
    guard.Material = Enum.Material.Metal
    guard.CanCollide = false
    guard.CFrame = handle.CFrame * CFrame.new(0, -0.15, -0.15)
    guard.Parent = tool

    local weld3 = Instance.new("WeldConstraint")
    weld3.Part0 = handle
    weld3.Part1 = guard
    weld3.Parent = handle

    local muzzle = Instance.new("Part")
    muzzle.Name = "Muzzle"
    muzzle.Size = Vector3.new(0.2, 0.2, 0.15)
    muzzle.Color = Color3.fromRGB(15, 15, 20)
    muzzle.Material = Enum.Material.Metal
    muzzle.CanCollide = false
    muzzle.CFrame = barrel.CFrame * CFrame.new(0, 0, -0.8)
    muzzle.Parent = tool

    local weld4 = Instance.new("WeldConstraint")
    weld4.Part0 = barrel
    weld4.Part1 = muzzle
    weld4.Parent = barrel

    tool.Activated:Connect(function()
        local localRoot = getRoot(LocalPlayer)
        if not localRoot then return end

        local flash = Instance.new("Part")
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.Shape = Enum.PartType.Ball
        flash.Color = Color3.fromRGB(255, 230, 100)
        flash.Material = Enum.Material.Neon
        flash.CanCollide = false
        flash.Transparency = 0.1
        flash.CFrame = muzzle.CFrame * CFrame.new(0, 0, -0.5)
        flash.Parent = workspace

        local flashWeld = Instance.new("WeldConstraint")
        flashWeld.Part0 = muzzle
        flashWeld.Part1 = flash
        flashWeld.Parent = muzzle

        local muzzleLight = Instance.new("PointLight")
        muzzleLight.Color = Color3.fromRGB(255, 220, 100)
        muzzleLight.Brightness = 8
        muzzleLight.Range = 10
        muzzleLight.Parent = flash

        local muzzleSmoke = Instance.new("ParticleEmitter")
        muzzleSmoke.Texture = "rbxassetid://243660364"
        muzzleSmoke.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
        muzzleSmoke.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 2),
        })
        muzzleSmoke.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        muzzleSmoke.Lifetime = NumberRange.new(0.3, 0.6)
        muzzleSmoke.Rate = 0
        muzzleSmoke.Speed = NumberRange.new(3, 5)
        muzzleSmoke.Parent = muzzle
        muzzleSmoke:Emit(10)

        local shootSound = Instance.new("Sound")
        shootSound.SoundId = "rbxassetid://130835443"
        shootSound.Volume = 1.5
        shootSound.PlaybackSpeed = 0.8
        shootSound.Parent = handle
        shootSound:Play()

        task.spawn(function()
            for i = 1, 6 do
                if not flash or not flash.Parent then break end
                flash.Transparency = 0.1 + (i / 6) * 0.9
                flash.Size = flash.Size + Vector3.new(0.2, 0.2, 0.2)
                muzzleLight.Brightness = math.max(0, muzzleLight.Brightness - 1.5)
                task.wait(0.02)
            end
            if flash then flash:Destroy() end
        end)

        localRoot.AssemblyLinearVelocity = localRoot.CFrame.LookVector * -8

        local mouse = LocalPlayer:GetMouse()
        local rayOrigin = muzzle.Position
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
            local hitPart = rayResult.Instance
            local hitPos = rayResult.Position

            local bulletHole = Instance.new("Part")
            bulletHole.Size = Vector3.new(0.15, 0.15, 0.05)
            bulletHole.Color = Color3.fromRGB(10, 10, 10)
            bulletHole.Material = Enum.Material.Metal
            bulletHole.CanCollide = false
            bulletHole.Anchored = true
            bulletHole.CFrame = CFrame.new(hitPos, rayDirection) * CFrame.new(0, 0, -0.05)
            bulletHole.Parent = workspace

            game:GetService("Debris"):AddItem(bulletHole, 3)

            local hitPlayer = getPlayerFromPart(hitPart)
            if hitPlayer and hitPlayer ~= LocalPlayer then
                local targetHumanoid = hitPlayer.Character and hitPlayer.Character:FindFirstChildOfClass("Humanoid")
                if targetHumanoid then
                    targetHumanoid:TakeDamage(25)
                end

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
        beam.Color = Color3.fromRGB(255, 220, 80)
        beam.Transparency = 0.2
        local beamLength = (rayResult and (rayResult.Position - rayOrigin).Magnitude or 500)
        beam.Size = Vector3.new(0.08, 0.08, beamLength)
        beam.CFrame = CFrame.new(rayOrigin, rayOrigin + rayDirection) * CFrame.new(0, 0, -beamLength / 2)
        beam.Parent = workspace

        task.spawn(function()
            for i = 1, 8 do
                beam.Transparency = 0.2 + (i / 8) * 0.8
                beam.Size = Vector3.new(beam.Size.X * 0.9, beam.Size.Y * 0.9, beam.Size.Z)
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

-- ====== ФУНКЦИЯ ЛАЗЕРА ИЗ ГЛАЗ ======
local function shootEyeLaser()
    local char = LocalPlayer.Character
    if not char then return end
    local eyeL = char:FindFirstChild("RedEyeLeft")
    local eyeR = char:FindFirstChild("RedEyeRight")
    if not eyeL or not eyeR then return end

    local camera = workspace.CurrentCamera
    local rayOrigin = camera.CFrame.Position
    local rayDir = camera.CFrame.LookVector * 1000

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char}

    local result = workspace:Raycast(rayOrigin, rayDir, raycastParams)
    local hitPos = result and result.Position or (rayOrigin + rayDir)

    for _, eye in ipairs({eyeL, eyeR}) do
        local beam = Instance.new("Part")
        beam.Name = "FlyLaser"
        beam.Anchored = true
        beam.CanCollide = false
        beam.Material = Enum.Material.Neon
        beam.Color = Color3.fromRGB(255, 0, 0)
        beam.Transparency = 0.15
        local dist = (hitPos - eye.Position).Magnitude
        beam.Size = Vector3.new(0.2, 0.2, dist)
        beam.CFrame = CFrame.new(eye.Position, hitPos) * CFrame.new(0, 0, -dist / 2)
        beam.Parent = workspace

        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 0, 0)
        light.Brightness = 8
        light.Range = 12
        light.Parent = beam

        task.spawn(function()
            for i = 1, 8 do
                beam.Transparency = 0.15 + (i / 8) * 0.85
                light.Brightness = math.max(0, 8 - i)
                task.wait(0.02)
            end
            beam:Destroy()
        end)
    end

    local zap = Instance.new("Sound")
    zap.SoundId = "rbxassetid://130835443"
    zap.Volume = 1
    zap.PlaybackSpeed = 2.5
    local root = char:FindFirstChild("HumanoidRootPart")
    zap.Parent = root or char
    zap:Play()
    game:GetService("Debris"):AddItem(zap, 2)

    if result and result.Instance then
        local hitPlayer = getPlayerFromPart(result.Instance)
        if hitPlayer and hitPlayer ~= LocalPlayer then
            local targetHumanoid = hitPlayer.Character and hitPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(40)
                local targetRoot = getRoot(hitPlayer)
                if targetRoot then
                    targetRoot.AssemblyLinearVelocity = camera.CFrame.LookVector * 120 + Vector3.new(0, 50, 0)
                end
            end
        end
    end
end

-- ====== КНОПКА 4: ПОЛЁТ (СУПЕРМЕН) ======
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

-- Кнопка лазера (видна только в полёте)
local flyLaserBtn = createMenuButton("Лазер из глаз", Color3.fromRGB(200, 0, 0))
flyLaserBtn.Visible = false

local flyBodyVel = nil
local flyBodyGyro = nil

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

flyLaserBtn.MouseButton1Click:Connect(function()
    flyLaserActive = not flyLaserActive
    if flyLaserActive then
        flyLaserBtn.Text = "Лазер из глаз (ВКЛ)"
        flyLaserBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)

        flyLaserInputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not flying or not flyLaserActive then return end
            if flyLaserCooldown then return end
            flyLaserCooldown = true
            task.delay(0.3, function() flyLaserCooldown = false end)
            shootEyeLaser()
        end)
    else
        flyLaserBtn.Text = "Лазер из глаз"
        flyLaserBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        if flyLaserInputConn then flyLaserInputConn:Disconnect() flyLaserInputConn = nil end
    end
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
        flyLaserBtn.Visible = true
        addRedEyes(char)

        local camera = workspace.CurrentCamera

        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVel.Velocity = Vector3.new(0, 0, 0)
        flyBodyVel.Parent = root

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.D = 100
        flyBodyGyro.CFrame = root.CFrame
        flyBodyGyro.Parent = root

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

            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * flySpeed
            else
                moveVec = Vector3.new(0, 0, 0)
            end

            if flyBodyVel and flyBodyVel.Parent then
                flyBodyVel.Velocity = moveVec
            end

            if flyBodyGyro and flyBodyGyro.Parent then
                if moveVec.Magnitude > 0 then
                    flyBodyGyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), moveVec) * CFrame.Angles(math.rad(-90), 0, 0)
                else
                    local lookDir = camCFrame.LookVector
                    lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
                    if lookDir.Magnitude > 0 then
                        flyBodyGyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), lookDir) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                end
            end
        end)

        -- Поза Супермена: прямые руки вперёд, прямые ноги назад
        flyPoseConn = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local c = LocalPlayer.Character
            if not c then return end

            local t = os.clock()
            local sway = math.sin(t * 4) * 0.02
            local armSway = math.sin(t * 4) * math.rad(2)

            local upperTorso = c:FindFirstChild("UpperTorso")
            if upperTorso then
                -- R15
                local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
                local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
                local rightUpperArm = c:FindFirstChild("RightUpperArm")
                local leftUpperArm = c:FindFirstChild("LeftUpperArm")
                local rightElbow = rightUpperArm and rightUpperArm:FindFirstChild("RightElbow")
                local leftElbow = leftUpperArm and leftUpperArm:FindFirstChild("LeftElbow")
                local lowerTorso = c:FindFirstChild("LowerTorso")
                local neck = upperTorso:FindFirstChild("Neck")
                local waist = lowerTorso and lowerTorso:FindFirstChild("Waist")
                local rightHip = lowerTorso and lowerTorso:FindFirstChild("RightHip")
                local leftHip = lowerTorso and lowerTorso:FindFirstChild("LeftHip")
                local rightUpperLeg = c:FindFirstChild("RightUpperLeg")
                local leftUpperLeg = c:FindFirstChild("LeftUpperLeg")
                local rightKnee = rightUpperLeg and rightUpperLeg:FindFirstChild("RightKnee")
                local leftKnee = leftUpperLeg and leftUpperLeg:FindFirstChild("LeftKnee")
                local rightLowerLeg = c:FindFirstChild("RightLowerLeg")
                local leftLowerLeg = c:FindFirstChild("LeftLowerLeg")
                local rightAnkle = rightLowerLeg and rightLowerLeg:FindFirstChild("RightAnkle")
                local leftAnkle = leftLowerLeg and leftLowerLeg:FindFirstChild("LeftAnkle")

                -- Обе руки прямо вперёд (180° — из -Y в +Y = вперёд при наклоне тела)
                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(180) + armSway, 0, 0) end
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(180) - armSway, 0, 0) end
                -- Локти прямые
                if rightElbow then rightElbow.Transform = CFrame.Angles(0, 0, 0) end
                if leftElbow then leftElbow.Transform = CFrame.Angles(0, 0, 0) end
                -- Ноги прямые назад (0° = висят прямо = назад при наклоне)
                if rightHip then rightHip.Transform = CFrame.Angles(sway * 5, 0, 0) end
                if leftHip then leftHip.Transform = CFrame.Angles(-sway * 5, 0, 0) end
                if rightKnee then rightKnee.Transform = CFrame.Angles(0, 0, 0) end
                if leftKnee then leftKnee.Transform = CFrame.Angles(0, 0, 0) end
                if rightAnkle then rightAnkle.Transform = CFrame.Angles(0, 0, 0) end
                if leftAnkle then leftAnkle.Transform = CFrame.Angles(0, 0, 0) end
                -- Голова смотрит вперёд
                if neck then neck.Transform = CFrame.Angles(math.rad(90), 0, 0) end
                -- Тело прямое
                if waist then waist.Transform = CFrame.Angles(0, 0, sway) end
            else
                -- R6
                local torso = c:FindFirstChild("Torso")
                if torso then
                    local rightShoulder = torso:FindFirstChild("Right Shoulder")
                    local leftShoulder = torso:FindFirstChild("Left Shoulder")
                    local rightHip = torso:FindFirstChild("Right Hip")
                    local leftHip = torso:FindFirstChild("Left Hip")
                    local neck = torso:FindFirstChild("Neck")

                    -- Обе руки прямо вперёд
                    if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(180) + armSway, 0, 0) end
                    if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(180) - armSway, 0, 0) end
                    -- Ноги прямые назад (без разведения)
                    if rightHip then rightHip.Transform = CFrame.Angles(sway * 5, 0, 0) end
                    if leftHip then leftHip.Transform = CFrame.Angles(-sway * 5, 0, 0) end
                    -- Голова смотрит вперёд
                    if neck then neck.Transform = CFrame.Angles(math.rad(90), 0, 0) end
                end
            end
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyPoseConn then flyPoseConn:Disconnect() flyPoseConn = nil end
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        if speedActive then
            humanoid.WalkSpeed = walkSpeed
        else
            humanoid.WalkSpeed = 16
        end
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
        flyBtn.Text = "Полёт [" .. flySpeed .. "]"
        flySpeedPanel.Visible = false
        flyLaserBtn.Visible = false
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

-- ====== КНОПКА 7: ЯДЕРКА ======
local function cleanupNukeEffects()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "NukeBomb" or obj.Name == "NukeShockwave" or obj.Name == "NukeMarker" or obj.Name == "NukeFireball" or obj.Name == "NoseCone" or obj.Name == "NukeSmokeRoot" or obj.Name == "NukeBeam" or obj.Name == "NukeDebris") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") and obj.Name and obj.Name:find("Nuke") then
            obj:Destroy()
        end
    end
end

local function createNukeModel(spawnPos, targetPos)
    local bomb = Instance.new("Part")
    bomb.Name = "NukeBomb"
    bomb.Size = Vector3.new(3, 8, 3)
    bomb.Color = Color3.fromRGB(80, 80, 90)
    bomb.Material = Enum.Material.Metal
    bomb.CanCollide = false
    bomb.Anchored = true
    bomb.CFrame = CFrame.new(spawnPos, targetPos)
    bomb.Parent = workspace

    local nose = Instance.new("Part")
    nose.Name = "NoseCone"
    nose.Size = Vector3.new(3, 4, 3)
    nose.Color = Color3.fromRGB(60, 60, 70)
    nose.Material = Enum.Material.Plastic
    nose.CanCollide = false
    nose.Anchored = false
    nose.CFrame = bomb.CFrame * CFrame.new(0, 4, 0)
    nose.Parent = bomb

    local noseWeld = Instance.new("WeldConstraint")
    noseWeld.Part0 = bomb
    noseWeld.Part1 = nose
    noseWeld.Parent = bomb

    for i = 1, 4 do
        local fin = Instance.new("Part")
        fin.Size = Vector3.new(0.4, 2.5, 2.5)
        fin.Color = Color3.fromRGB(50, 50, 60)
        fin.Material = Enum.Material.Metal
        fin.CanCollide = false
        fin.Anchored = false

        local angle = (i - 1) * 90
        local offset = CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(2, -3, 0)
        fin.CFrame = bomb.CFrame * offset
        fin.Parent = bomb

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = bomb
        weld.Part1 = fin
        weld.Parent = bomb
    end

    local stripe = Instance.new("Part")
    stripe.Size = Vector3.new(3.2, 0.8, 3.2)
    stripe.Color = Color3.fromRGB(200, 30, 30)
    stripe.Material = Enum.Material.Neon
    stripe.CanCollide = false
    stripe.Anchored = false
    stripe.CFrame = bomb.CFrame
    stripe.Parent = bomb

    local stripeWeld = Instance.new("WeldConstraint")
    stripeWeld.Part0 = bomb
    stripeWeld.Part1 = stripe
    stripeWeld.Parent = bomb

    return bomb
end

local function createExplosionEffects(impactPos)
    local shockwave = Instance.new("Part")
    shockwave.Name = "NukeShockwave"
    shockwave.Size = Vector3.new(10, 1, 10)
    shockwave.Color = Color3.fromRGB(255, 100, 100)
    shockwave.Material = Enum.Material.Neon
    shockwave.Transparency = 0.3
    shockwave.CanCollide = false
    shockwave.Anchored = true
    shockwave.Position = impactPos + Vector3.new(0, 1, 0)
    shockwave.Parent = workspace

    task.spawn(function()
        for i = 1, 30 do
            shockwave.Size = Vector3.new(shockwave.Size.X + 20, shockwave.Size.Y, shockwave.Size.Z + 20)
            shockwave.Transparency = math.clamp(shockwave.Transparency + 0.03, 0, 1)
            task.wait(0.04)
        end
        shockwave:Destroy()
    end)

    local fireball = Instance.new("Part")
    fireball.Name = "NukeFireball"
    fireball.Size = Vector3.new(40, 40, 40)
    fireball.Shape = Enum.PartType.Ball
    fireball.Color = Color3.fromRGB(255, 120, 0)
    fireball.Material = Enum.Material.Neon
    fireball.Transparency = 0.15
    fireball.CanCollide = false
    fireball.Anchored = true
    fireball.Position = impactPos + Vector3.new(0, 20, 0)
    fireball.Parent = workspace

    local flashLight = Instance.new("PointLight")
    flashLight.Brightness = 30
    flashLight.Range = 200
    flashLight.Color = Color3.fromRGB(255, 220, 150)
    flashLight.Parent = fireball

    task.spawn(function()
        for i = 1, 20 do
            fireball
