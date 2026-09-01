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

        -- BodyVelocity активно удерживает скорость = противодействует гравитации
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVel.Velocity = Vector3.new(0, 0, 0)
        flyBodyVel.Parent = root

        -- BodyGyro удерживает тело горизонтально (как Супермен)
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
                -- Зависание: BodyVelocity держит (0,0,0) — гравитация не тянет вниз
                moveVec = Vector3.new(0, 0, 0)
            end

            if flyBodyVel and flyBodyVel.Parent then
                flyBodyVel.Velocity = moveVec
            end

            -- Тело наклонено горизонтально по направлению движения/камеры
            if flyBodyGyro and flyBodyGyro.Parent then
                if moveVec.Magnitude > 0 then
                    flyBodyGyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), moveVec) * CFrame.Angles(math.rad(90), 0, 0)
                else
                    -- Когда стоим на месте — наклон по камере
                    local lookDir = camCFrame.LookVector
                    lookDir = Vector3.new(lookDir.X, 0, lookDir.Z)
                    if lookDir.Magnitude > 0 then
                        flyBodyGyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), lookDir) * CFrame.Angles(math.rad(90), 0, 0)
                    end
                end
            end
        end)

        -- Поза Супермена через Motor6D Transform
        flyPoseConn = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local c = LocalPlayer.Character
            if not c then return end

            local t = os.clock()
            local sway = math.sin(t * 4) * 0.02
            local armSway = math.sin(t * 4) * math.rad(2)

            local upperTorso = c:FindFirstChild("UpperTorso")
            if upperTorso then
                -- R15: ищем суставы в правильных местах
                local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
                local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
                local lowerTorso = c:FindFirstChild("LowerTorso")
                local waist = lowerTorso and lowerTorso:FindFirstChild("Waist")
                local neck = upperTorso:FindFirstChild("Neck")
                -- RightHip и LeftHip находятся в LowerTorso, а не в RightUpperLeg!
                local rightHip = lowerTorso and lowerTorso:FindFirstChild("RightHip")
                local leftHip = lowerTorso and lowerTorso:FindFirstChild("LeftHip")
                -- RightKnee и LeftKnee в RightUpperLeg / LeftUpperLeg
                local rightUpperLeg = c:FindFirstChild("RightUpperLeg")
                local leftUpperLeg = c:FindFirstChild("LeftUpperLeg")
                local rightKnee = rightUpperLeg and rightUpperLeg:FindFirstChild("RightKnee")
                local leftKnee = leftUpperLeg and leftUpperLeg:FindFirstChild("LeftKnee")
                local rightLowerLeg = c:FindFirstChild("RightLowerLeg")
                local leftLowerLeg = c:FindFirstChild("LeftLowerLeg")
                local rightAnkle = rightLowerLeg and rightLowerLeg:FindFirstChild("RightAnkle")
                local leftAnkle = leftLowerLeg and leftLowerLeg:FindFirstChild("LeftAnkle")

                -- Правая рука вытянута вперёд (кулак Супермена)
                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-90) + armSway, 0, 0) end
                -- Левая рука отведена назад-в сторону
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-30) - armSway, math.rad(-45), math.rad(-30)) end
                -- Ноги вытянуты назад, слегка разведены
                if rightHip then rightHip.Transform = CFrame.Angles(math.rad(-10) + sway * 5, 0, math.rad(-8)) end
                if leftHip then leftHip.Transform = CFrame.Angles(math.rad(-10) - sway * 5, 0, math.rad(8)) end
                if rightKnee then rightKnee.Transform = CFrame.Angles(math.rad(5), 0, 0) end
                if leftKnee then leftKnee.Transform = CFrame.Angles(math.rad(5), 0, 0) end
                if rightAnkle then rightAnkle.Transform = CFrame.Angles(math.rad(-5), 0, 0) end
                if leftAnkle then leftAnkle.Transform = CFrame.Angles(math.rad(-5), 0, 0) end
                -- Тело наклонено горизонтально
                if waist then waist.Transform = CFrame.Angles(math.rad(80), 0, sway) end
                -- Голова смотрит вперёд
                if neck then neck.Transform = CFrame.Angles(math.rad(-80), 0, 0) end
            else
                -- R6
                local torso = c:FindFirstChild("Torso")
                if torso then
                    local rightShoulder = torso:FindFirstChild("Right Shoulder")
                    local leftShoulder = torso:FindFirstChild("Left Shoulder")
                    local rightHip = torso:FindFirstChild("Right Hip")
                    local leftHip = torso:FindFirstChild("Left Hip")
                    local head = c:FindFirstChild("Head")
                    local neck = head and head:FindFirstChild("Neck")
                    local rootJoint = c:FindFirstChild("HumanoidRootPart") and c.HumanoidRootPart:FindFirstChild("RootJoint")

                    if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-90) + armSway, 0, 0) end
                    if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-30) - armSway, math.rad(-45), math.rad(-30)) end
                    if rightHip then rightHip.Transform = CFrame.Angles(math.rad(-10) + sway * 5, 0, math.rad(-8)) end
                    if leftHip then leftHip.Transform = CFrame.Angles(math.rad(-10) - sway * 5, 0, math.rad(8)) end
                    if neck then neck.Transform = CFrame.Angles(math.rad(-80), 0, 0) end
                    if rootJoint then rootJoint.Transform = CFrame.Angles(math.rad(80), 0, sway) end
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
            fireball.Size = fireball.Size * 1.12
            fireball.Transparency = math.clamp(fireball.Transparency + 0.04, 0, 1)
            flashLight.Brightness = math.max(0, flashLight.Brightness - 1.2)
            task.wait(0.05)
        end
        fireball:Destroy()
    end)

    local smokeRoot = Instance.new("Part")
    smokeRoot.Name = "NukeSmokeRoot"
    smokeRoot.Size = Vector3.new(1, 1, 1)
    smokeRoot.Transparency = 1
    smokeRoot.CanCollide = false
    smokeRoot.Anchored = true
    smokeRoot.Position = impactPos
    smokeRoot.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "NukeSmokeEmitter"
    emitter.Texture = "rbxassetid://243660364"
    emitter.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.fromRGB(30, 30, 30))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 5),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Lifetime = NumberRange.new(4, 7)
    emitter.Rate = 100
    emitter.Speed = NumberRange.new(8, 20)
    emitter.SpreadAngle = Vector2.new(90, 90)
    emitter.Rotation = NumberRange.new(-45, 45)
    emitter.RotSpeed = NumberRange.new(-180, 180)
    emitter.Parent = smokeRoot

    task.delay(8, function()
        if smokeRoot then smokeRoot:Destroy() end
    end)

    local boom = Instance.new("Sound")
    boom.SoundId = "rbxassetid://130835443"
    boom.Volume = 5
    boom.Parent = smokeRoot
    boom:Play()

    task.spawn(function()
        task.wait(0.1)
        for _, plr in ipairs(Players:GetPlayers()) do
            local pChar = plr.Character
            if pChar then
                local pRoot = pChar:FindFirstChild("HumanoidRootPart")
                local humanoid = pChar:FindFirstChildOfClass("Humanoid")
                if pRoot and humanoid then
                    local dist = (pRoot.Position - impactPos).Magnitude
                    if dist < 150 then
                        pRoot.AssemblyLinearVelocity = (pRoot.Position - impactPos).Unit * 300 + Vector3.new(0, 200, 0)
                        humanoid.Health = 0
                    end
                end
            end
        end
    end)

    task.spawn(function()
        for i = 1, 20 do
            local debris = Instance.new("Part")
            debris.Name = "NukeDebris"
            debris.Size = Vector3.new(math.random(1, 3), math.random(1, 3), math.random(1, 3))
            debris.Color = Color3.fromRGB(80, 80, 80)
            debris.Material = Enum.Material.Metal
            debris.CanCollide = false
            debris.Anchored = false
            debris.Position = impactPos + Vector3.new(0, 5, 0)
            debris.AssemblyLinearVelocity = Vector3.new(
                math.random(-80, 80),
                math.random(50, 150),
                math.random(-80, 80)
            )
            debris.Parent = workspace

            game:GetService("Debris"):AddItem(debris, 3)
        end
    end)
end

local nukeBtn = createMenuButton("ЯДЕРКА: ПРИЦЕЛ", Color3.fromRGB(200, 0, 0))

nukeBtn.MouseButton1Click:Connect(function()
    if nukeCooldown then return end
    if nukeAiming then return end
    nukeAiming = true
    nukeBtn.Text = "КЛИКАЙ ПО ЗЕМЛЕ!"
    nukeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)

    local mouse = LocalPlayer:GetMouse()

    local marker = Instance.new("Part")
    marker.Name = "NukeMarker"
    marker.Size = Vector3.new(16, 0.2, 16)
    marker.Color = Color3.fromRGB(255, 0, 0)
    marker.Material = Enum.Material.Neon
    marker.Transparency = 0.4
    marker.CanCollide = false
    marker.Anchored = true
    marker.Shape = Enum.PartType.Cylinder
    marker.Parent = workspace

    local beam = Instance.new("Part")
    beam.Name = "NukeBeam"
    beam.Size = Vector3.new(0.15, 200, 0.15)
    beam.Color = Color3.fromRGB(255, 50, 50)
    beam.Material = Enum.Material.Neon
    beam.Transparency = 0.5
    beam.CanCollide = false
    beam.Anchored = true
    beam.Parent = workspace

    local followConn = RunService.RenderStepped:Connect(function()
        if not nukeAiming or not marker or not marker.Parent then
            followConn:Disconnect()
            return
        end
        local unitRay = mouse.UnitRay
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, marker, beam}
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 5000, raycastParams)
        if result then
            local hitPos = result.Position
            marker.Position = hitPos + Vector3.new(0, 0.1, 0)
            beam.Position = hitPos + Vector3.new(0, 100, 0)
        end
    end)

    task.wait()
    if not nukeAiming then return end

    local clickConn
    clickConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not nukeAiming then
            clickConn:Disconnect()
            return
        end
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        nukeAiming = false
        clickConn:Disconnect()
        followConn:Disconnect()

        if not marker or not marker.Parent then
            nukeCooldown = false
            return
        end

        local targetPos = marker.Position
        marker:Destroy()
        beam:Destroy()

        nukeCooldown = true
        nukeBtn.Text = "ЯДЕРКА ЛЕТИТ!"
        nukeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

        local spawnPos = targetPos + Vector3.new(0, 250, 0)
        local bomb = createNukeModel(spawnPos, targetPos)

        local whistle = Instance.new("Sound")
        whistle.SoundId = "rbxassetid://130835443"
        whistle.Volume = 1.5
        whistle.Parent = bomb
        whistle:Play()

        local fallSpeed = 50
        local gravity = 40
        local currentPos = spawnPos

        local fallConn = nil
        fallConn = RunService.Heartbeat:Connect(function(dt)
            if not bomb or not bomb.Parent then
                if fallConn then fallConn:Disconnect() end
                return
            end

            currentPos = currentPos - Vector3.new(0, fallSpeed * dt, 0)
            fallSpeed = fallSpeed + gravity * dt
            bomb.CFrame = CFrame.new(currentPos, targetPos)

            if currentPos.Y <= targetPos.Y + 2 then
                if fallConn then fallConn:Disconnect() end
                bomb:Destroy()

                createExplosionEffects(targetPos)

                task.wait(5)
                nukeCooldown = false
                nukeBtn.Text = "ЯДЕРКА: ПРИЦЕЛ"
                nukeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            end
        end)
    end)

    local cancelConn
    cancelConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not nukeAiming then
            cancelConn:Disconnect()
            return
        end
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end

        nukeAiming = false
        clickConn:Disconnect()
        followConn:Disconnect()
        cancelConn:Disconnect()

        if marker then marker:Destroy() end
        if beam then beam:Destroy() end

        nukeBtn.Text = "ЯДЕРКА: ПРИЦЕЛ"
        nukeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end)
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

-- ====== КНОПКА 9: ESP ИГРОКОВ ======
local espBtn = createMenuButton("ESP игроков", Color3.fromRGB(0, 200, 100))

local espActive = false
local espConn = nil
local espChars = {}

local function clearESP()
    for plr, hl in pairs(espChars) do
        if hl then hl:Destroy() end
    end
    espChars = {}
end

local function applyESPToChar(plr, char)
    if not char or not plr or plr == LocalPlayer then return end
    if espChars[plr] and espChars[plr].Parent then return end
    local hl = Instance.new("Highlight")
    hl.Name = "EspHighlight"
    hl.FillColor = Color3.fromRGB(255, 50, 50)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    espChars[plr] = hl
end

espBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    if espActive then
        espBtn.Text = "ESP игроков (ВКЛ)"
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                applyESPToChar(plr, plr.Character)
            end
        end
        espConn = RunService.Heartbeat:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not espChars[plr] or not espChars[plr].Parent then
                        applyESPToChar(plr, plr.Character)
                    end
                end
            end
        end)
    else
        espBtn.Text = "ESP игроков"
        if espConn then espConn:Disconnect() espConn = nil end
        clearESP()
    end
end)

-- ====== КНОПКА 10: ХИТБОКСЫ NPC ======
local hitboxBtn = createMenuButton("Хитбоксы NPC", Color3.fromRGB(255, 200, 0))

local hitboxActive = false
local hitboxConn = nil
local hitboxAdornments = {}

local function isPlayerCharacter(model)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then return true end
    end
    return false
end

local function clearHitboxes()
    for _, adornments in pairs(hitboxAdornments) do
        for _, ad in ipairs(adornments) do
            if ad then ad:Destroy() end
        end
    end
    hitboxAdornments = {}
end

local function applyHitboxToModel(model)
    if not model then return end
    if isPlayerCharacter(model) then return end
    if hitboxAdornments[model] then return end
    local adornments = {}
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local adornment = Instance.new("BoxHandleAdornment")
            adornment.Name = "HitboxAdornment"
            adornment.Adornee = part
            adornment.Size = part.Size + Vector3.new(0.1, 0.1, 0.1)
            adornment.Color3 = Color3.fromRGB(0, 255, 0)
            adornment.Transparency = 0.5
            adornment.AlwaysOnTop = true
            adornment.ZIndex = 5
            adornment.Parent = game:GetService("CoreGui")
            table.insert(adornments, adornment)
        end
    end
    if #adornments > 0 then
        hitboxAdornments[model] = adornments
    end
end

local function scanForNPCs()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            if humanoid and not isPlayerCharacter(obj) then
                applyHitboxToModel(obj)
            end
        end
    end
end

hitboxBtn.MouseButton1Click:Connect(function()
    hitboxActive = not hitboxActive
    if hitboxActive then
        hitboxBtn.Text = "Хитбоксы NPC (ВКЛ)"
        scanForNPCs()
        hitboxConn = RunService.Heartbeat:Connect(function()
            if not hitboxActive then return end
            for model, adornments in pairs(hitboxAdornments) do
                if not model or not model.Parent then
                    for _, ad in ipairs(adornments) do
                        if ad then ad:Destroy() end
                    end
                    hitboxAdornments[model] = nil
                end
            end
            scanForNPCs()
        end)
    else
        hitboxBtn.Text = "Хитбоксы NPC"
        if hitboxConn then hitboxConn:Disconnect() hitboxConn = nil end
        clearHitboxes()
    end
end)

-- ====== КНОПКА 11: МОНСТР САРАНЧА ======
local monsterBtn = createMenuButton("МОНСТР: САРАНЧА", Color3.fromRGB(100, 150, 30))

local monsterActive = false
local monsterConn = nil
local monsterSound = nil
local monsterParts = {}
local originalColors = {}

local function removeMonsterFromChar(char)
    if not char then return end
    for _, p in ipairs(monsterParts) do
        if p and p.Parent then p:Destroy() end
    end
    monsterParts = {}
    for part, color in pairs(originalColors) do
        if part and part.Parent then
            part.Color = color
            part.Material = Enum.Material.Plastic
        end
    end
    originalColors = {}
    local hl = char:FindFirstChild("MonsterHighlight")
    if hl then hl:Destroy() end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local light = root:FindFirstChild("MonsterLight")
        if light then light:Destroy() end
        local particles = root:FindFirstChild("MonsterParticles")
        if particles then particles:Destroy() end
    end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if speedActive then
            humanoid.WalkSpeed = walkSpeed
        else
            humanoid.WalkSpeed = 16
        end
    end
end

local function applyMonsterToChar(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not head or not humanoid then return end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if not originalColors[part] then
                originalColors[part] = part.Color
            end
            part.Color = Color3.fromRGB(80, 120, 20)
            part.Material = Enum.Material.Grass
        end
    end

    local hl = Instance.new("Highlight")
    hl.Name = "MonsterHighlight"
    hl.FillColor = Color3.fromRGB(100, 180, 20)
    hl.OutlineColor = Color3.fromRGB(200, 255, 50)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.Parent = char

    local light = Instance.new("PointLight")
    light.Name = "MonsterLight"
    light.Color = Color3.fromRGB(100, 200, 30)
    light.Brightness = 6
    light.Range = 18
    light.Parent = root

    local particles = Instance.new("ParticleEmitter")
    particles.Name = "MonsterParticles"
    particles.Texture = "rbxassetid://243660364"
    particles.Color = ColorSequence.new(Color3.fromRGB(120, 200, 30))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Rate = 30
    particles.Speed = NumberRange.new(1, 3)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Parent = root

    if not speedActive then
        humanoid.WalkSpeed = 32
    end

    local wingL = Instance.new("Part")
    wingL.Name = "LocustWingL"
    wingL.Size = Vector3.new(0.1, 1.5, 3)
    wingL.Color = Color3.fromRGB(60, 100, 15)
    wingL.Material = Enum.Material.SmoothPlastic
    wingL.Transparency = 0.3
    wingL.CanCollide = false
    wingL.Anchored = false
    wingL.CFrame = root.CFrame * CFrame.new(-1.5, 0, 0) * CFrame.Angles(0, 0, math.rad(-20))
    wingL.Parent = char
    table.insert(monsterParts, wingL)

    local wingWeldL = Instance.new("WeldConstraint")
    wingWeldL.Part0 = root
    wingWeldL.Part1 = wingL
    wingWeldL.Parent = wingL

    local wingR = Instance.new("Part")
    wingR.Name = "LocustWingR"
    wingR.Size = Vector3.new(0.1, 1.5, 3)
    wingR.Color = Color3.fromRGB(60, 100, 15)
    wingR.Material = Enum.Material.SmoothPlastic
    wingR.Transparency = 0.3
    wingR.CanCollide = false
    wingR.Anchored = false
    wingR.CFrame = root.CFrame * CFrame.new(1.5, 0, 0) * CFrame.Angles(0, 0, math.rad(20))
    wingR.Parent = char
    table.insert(monsterParts, wingR)

    local wingWeldR = Instance.new("WeldConstraint")
    wingWeldR.Part0 = root
    wingWeldR.Part1 = wingR
    wingWeldR.Parent = wingR

    local antennaL = Instance.new("Part")
    antennaL.Name = "LocustAntennaL"
    antennaL.Size = Vector3.new(0.05, 1.2, 0.05)
    antennaL.Color = Color3.fromRGB(50, 80, 10)
    antennaL.Material = Enum.Material.SmoothPlastic
    antennaL.CanCollide = false
    antennaL.Anchored = false
    antennaL.CFrame = head.CFrame * CFrame.new(-0.2, 0.6, 0) * CFrame.Angles(math.rad(-15), 0, math.rad(-10))
    antennaL.Parent = char
    table.insert(monsterParts, antennaL)

    local antWeldL = Instance.new("WeldConstraint")
    antWeldL.Part0 = head
    antWeldL.Part1 = antennaL
    antWeldL.Parent = antennaL

    local antennaR = Instance.new("Part")
    antennaR.Name = "LocustAntennaR"
    antennaR.Size = Vector3.new(0.05, 1.2, 0.05)
    antennaR.Color = Color3.fromRGB(50, 80, 10)
    antennaR.Material = Enum.Material.SmoothPlastic
    antennaR.CanCollide = false
    antennaR.Anchored = false
    antennaR.CFrame = head.CFrame * CFrame.new(0.2, 0.6, 0) * CFrame.Angles(math.rad(-15), 0, math.rad(10))
    antennaR.Parent = char
    table.insert(monsterParts, antennaR)

    local antWeldR = Instance.new("WeldConstraint")
    antWeldR.Part0 = head
    antWeldR.Part1 = antennaR
    antWeldR.Parent = antennaR

    if not monsterSound or not monsterSound.Parent then
        monsterSound = Instance.new("Sound")
        monsterSound.SoundId = "rbxassetid://9046865451"
        monsterSound.Volume = 1.5
        monsterSound.PlaybackSpeed = 1.5
        monsterSound.Looped = true
        monsterSound.Parent = root
        monsterSound:Play()
    end
end

monsterBtn.MouseButton1Click:Connect(function()
    monsterActive = not monsterActive
    if monsterActive then
        monsterBtn.Text = "МОНСТР: САРАНЧА (ВКЛ)"
        local char = LocalPlayer.Character
        if char then
            applyMonsterToChar(char)
        end
        monsterConn = RunService.Heartbeat:Connect(function()
            if not monsterActive then return end
            local c = LocalPlayer.Character
            if not c then return end
            local root = c:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local t = os.clock()

            local wingL = c:FindFirstChild("LocustWingL")
            local wingR = c:FindFirstChild("LocustWingR")
            local flap = math.sin(t * 15) * math.rad(25)
            if wingL and wingL.Parent then
                wingL.CFrame = root.CFrame * CFrame.new(-1.5, 0, 0) * CFrame.Angles(0, 0, math.rad(-20) + flap)
            end
            if wingR and wingR.Parent then
                wingR.CFrame = root.CFrame * CFrame.new(1.5, 0, 0) * CFrame.Angles(0, 0, math.rad(20) - flap)
            end

            local light = root:FindFirstChild("MonsterLight")
            if light then
                light.Brightness = 4 + math.sin(t * 6) * 2
                light.Range = 15 + math.sin(t * 4) * 3
            end

            local upperTorso = c:FindFirstChild("UpperTorso")
            if upperTorso then
                local rightShoulder = upperTorso:FindFirstChild("RightShoulder")
                local leftShoulder = upperTorso:FindFirstChild("LeftShoulder")
                local head = c:FindFirstChild("Head")
                local neck = head and (head:FindFirstChild("Neck") or upperTorso:FindFirstChild("Neck"))

                local hunch = math.sin(t * 4) * math.rad(5)
                if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-45) + hunch, math.rad(30), math.rad(-40)) end
                if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-45) - hunch, math.rad(-30), math.rad(40)) end
                if neck then neck.Transform = CFrame.Angles(math.rad(-35), 0, 0) end
            else
                local torso = c:FindFirstChild("Torso")
                if torso then
                    local rightShoulder = torso:FindFirstChild("Right Shoulder")
                    local leftShoulder = torso:FindFirstChild("Left Shoulder")
                    local head = c:FindFirstChild("Head")
                    local neck = head and head:FindFirstChild("Neck")

                    local hunch = math.sin(t * 4) * math.rad(5)
                    if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(-45) + hunch, math.rad(30), math.rad(-40)) end
                    if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(-45) - hunch, math.rad(-30), math.rad(40)) end
                    if neck then neck.Transform = CFrame.Angles(math.rad(-35), 0, 0) end
                end
            end
        end)
    else
        monsterBtn.Text = "МОНСТР: САРАНЧА"
        if monsterConn then monsterConn:Disconnect() monsterConn = nil end
        if monsterSound then monsterSound:Stop() monsterSound:Destroy() monsterSound = nil end
        removeMonsterFromChar(LocalPlayer.Character)
    end
end)

-- ====== КНОПКА 12: УДАРНАЯ ВОЛНА ПРИ ПАДЕНИИ ======
local shockwaveBtn = createMenuButton("Ударная волна", Color3.fromRGB(200, 100, 50))

local shockwaveActive = false
local shockwaveConn = nil
local liftedBlocks = {}

local function createLandingShockwave(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pos = root.Position

    local wave = Instance.new("Part")
    wave.Name = "ShockwaveRing"
    wave.Size = Vector3.new(2, 0.2, 2)
    wave.Shape = Enum.PartType.Cylinder
    wave.Color = Color3.fromRGB(255, 200, 100)
    wave.Material = Enum.Material.Neon
    wave.Transparency = 0.2
    wave.CanCollide = false
    wave.Anchored = true
    wave.CFrame = CFrame.new(pos.X, pos.Y - 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
    wave.Parent = workspace

    local flashLight = Instance.new("PointLight")
    flashLight.Color = Color3.fromRGB(255, 180, 80)
    flashLight.Brightness = 10
    flashLight.Range = 25
    flashLight.Parent = wave

    local boom = Instance.new("Sound")
    boom.SoundId = "rbxassetid://130835443"
    boom.Volume = 3
    boom.PlaybackSpeed = 0.6
    boom.Parent = wave
    boom:Play()

    task.spawn(function()
        for i = 1, 25 do
            wave.Size = Vector3.new(2 + i * 3, 0.2, 2 + i * 3)
            wave.Transparency = math.clamp(0.2 + (i / 25) * 0.8, 0, 1)
            flashLight.Brightness = math.max(0, 10 - i * 0.5)
            wave.CFrame = CFrame.new(pos.X, pos.Y - 2, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
            task.wait(0.03)
        end
        wave:Destroy()
    end)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {char}

    local radius = 20
    local scanHeight = 15

    for xOffset = -radius, radius, 3 do
        for zOffset = -radius, radius, 3 do
            local rayOrigin = Vector3.new(pos.X + xOffset, pos.Y + 1, pos.Z + zOffset)
            local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -scanHeight, 0), raycastParams)
            if rayResult and rayResult.Instance then
                local part = rayResult.Instance
                if not part.Anchored and part:IsA("BasePart") then
                    local isPlayerPart = false
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr.Character and part:IsDescendantOf(plr.Character) then
                            isPlayerPart = true
                            break
                        end
                    end
                    if not isPlayerPart then
                        local alreadyLifted = false
                        for _, entry in ipairs(liftedBlocks) do
                            if entry.part == part then
                                alreadyLifted = true
                                break
                            end
                        end
                        if not alreadyLifted then
                            local dist = (part.Position - pos).Magnitude
                            local liftPower = math.max(50, 200 - dist * 5)
                            part.AssemblyLinearVelocity = Vector3.new(
                                math.random(-20, 20),
                                liftPower,
                                math.random(-20, 20)
                            )
                            part.AssemblyAngularVelocity = Vector3.new(
                                math.random(-10, 10),
                                math.random(-10, 10),
                                math.random(-10, 10)
                            )

                            local entry = {part = part, timer = 1}
                            table.insert(liftedBlocks, entry)
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        task.wait(1)
        for i = #liftedBlocks, 1, -1 do
            local entry = liftedBlocks[i]
            if entry.part and entry.part.Parent then
                entry.part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                entry.part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            table.remove(liftedBlocks, i)
        end
    end)
end

shockwaveBtn.MouseButton1Click:Connect(function()
    shockwaveActive = not shockwaveActive
    if shockwaveActive then
        shockwaveBtn.Text = "Ударная волна (ВКЛ)"
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            shockwaveConn = humanoid.StateChanged:Connect(function(_, newState)
                if not shockwaveActive then return end
                if newState == Enum.HumanoidStateType.Landed then
                    local c = LocalPlayer.Character
                    if c then
                        createLandingShockwave(c)
                    end
                end
            end)
        end
    else
        shockwaveBtn.Text = "Ударная волна"
        if shockwaveConn then shockwaveConn:Disconnect() shockwaveConn = nil end
    end
end)

-- ====== КНОПКА 13: НОУКЛИП ======
local noclipBtn = createMenuButton("Ноуклип", Color3.fromRGB(150, 0, 150))

local noclipActive = false
local noclipConn = nil

local function setNoclip(enabled)
    noclipActive = enabled
    if enabled then
        noclipBtn.Text = "Ноуклип (ВКЛ)"

        local toggleEvent = ReplicatedStorage:FindFirstChild("ToggleNoClip")
        if toggleEvent then
            toggleEvent:FireServer(true)
        end

        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    else
        noclipBtn.Text = "Ноуклип"
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end

        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end

        local toggleEvent = ReplicatedStorage:FindFirstChild("ToggleNoClip")
        if toggleEvent then
            toggleEvent:FireServer(false)
        end
    end
end

noclipBtn.MouseButton1Click:Connect(function()
    setNoclip(not noclipActive)
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
    nukeCooldown = false
    nukeAiming = false
    espActive = false
    hitboxActive = false
    monsterActive = false
    shockwaveActive = false
    noclipActive = false
    if sigmaSound then sigmaSound:Stop() sigmaSound:Destroy() end
    if sigmaAuraConn then sigmaAuraConn:Disconnect() end
    if sigmaPoseConn then sigmaPoseConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    if flyPoseConn then flyPoseConn:Disconnect() end
    if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    if godModeConn then godModeConn:Disconnect() end
    if speedMaintainConn then speedMaintainConn:Disconnect() end
    if espConn then espConn:Disconnect() end
    if hitboxConn then hitboxConn:Disconnect() end
    if monsterConn then monsterConn:Disconnect() end
    if monsterSound then monsterSound:Stop() monsterSound:Destroy() end
    if shockwaveConn then shockwaveConn:Disconnect() end
    if noclipConn then noclipConn:Disconnect() end
    clearESP()
    clearHitboxes()
    cleanupNukeEffects()
    removeSigmaEffectsFromChar(LocalPlayer.Character)
    removeRedEyes(LocalPlayer.Character)
    removeMonsterFromChar(LocalPlayer.Character)
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

        -- Пересоздаём BodyVelocity и BodyGyro после респавна
        local newRoot = newChar:FindFirstChild("HumanoidRootPart")
        if newRoot then
            if flyBodyVel then flyBodyVel:Destroy() end
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVel.Velocity = Vector3.new(0, 0, 0)
            flyBodyVel.Parent = newRoot

            if flyBodyGyro then flyBodyGyro:Destroy() end
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.D = 100
            flyBodyGyro.CFrame = newRoot.CFrame
            flyBodyGyro.Parent = newRoot
        end
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

    if espActive then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                applyESPToChar(plr, plr.Character)
            end
        end
    end

    if monsterActive then
        task.wait(0.5)
        applyMonsterToChar(newChar)
    end

    if shockwaveActive then
        local h = newChar:FindFirstChildOfClass("Humanoid")
        if h then
            task.wait(0.3)
            if shockwaveConn then shockwaveConn:Disconnect() end
            shockwaveConn = h.StateChanged:Connect(function(_, newState)
                if not shockwaveActive then return end
                if newState == Enum.HumanoidStateType.Landed then
                    local c = LocalPlayer.Character
                    if c then
                        createLandingShockwave(c)
                    end
                end
            end)
        end
    end

    if noclipActive then
        task.wait(0.3)
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end

    pistolGiven = false
end)
