-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerToolGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ====== ПЕРЕТАСКИВАНИЕ ======
local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ====== ПАНЕЛЬ С ТЕКСТОВЫМ ПОЛЕМ (для телепорта) ======
local function createPanelWithInput(yOffset, buttonText, actionFunc, placeholder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 90)
    frame.Position = UDim2.new(0, 20, 0, yOffset)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local topBar = Instance.new("TextLabel")
    topBar.Size = UDim2.new(1, 0, 0, 20)
    topBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    topBar.BorderSizePixel = 0
    topBar.Text = "≡ Перетащи"
    topBar.TextColor3 = Color3.fromRGB(160, 160, 180)
    topBar.Font = Enum.Font.SourceSans
    topBar.TextSize = 14
    topBar.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 28)
    textBox.Position = UDim2.new(0, 10, 0, 26)
    textBox.PlaceholderText = placeholder or "Введите ник игрока..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 16
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 28)
    button.Position = UDim2.new(0, 10, 0, 58)
    button.Text = buttonText
    button.BackgroundColor3 = Color3.fromRGB(60, 130, 210)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Parent = frame

    makeDraggable(frame)

    button.MouseButton1Click:Connect(function()
        actionFunc(textBox.Text)
    end)

    return frame
end

-- ====== ПАНЕЛЬ БЕЗ ТЕКСТОВОГО ПОЛЯ (кнопка только) ======
local function createPanelNoInput(yOffset, buttonText, actionFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 50)
    frame.Position = UDim2.new(0, 20, 0, yOffset)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui

    local topBar = Instance.new("TextLabel")
    topBar.Size = UDim2.new(1, 0, 0, 18)
    topBar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    topBar.BorderSizePixel = 0
    topBar.Text = "≡ Перетащи"
    topBar.TextColor3 = Color3.fromRGB(160, 160, 180)
    topBar.Font = Enum.Font.SourceSans
    topBar.TextSize = 14
    topBar.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 28)
    button.Position = UDim2.new(0, 10, 0, 22)
    button.Text = buttonText
    button.BackgroundColor3 = Color3.fromRGB(60, 130, 210)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Parent = frame

    makeDraggable(frame)

    button.MouseButton1Click:Connect(function()
        actionFunc()
    end)

    return frame
end

-- ====== ПОИСК HRP ======
local function getRoot(player)
    local char = player.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

-- ====== ПОИСК ИГРОКА ПО НИКУ ======
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

-- ====== ПАНЕЛЬ 1: ТЕЛЕПОРТ ======
createPanelWithInput(30, "ТП к игроку", function(text)
    local targetPlayer = findPlayer(text)
    if not targetPlayer then return end
    local targetRoot = getRoot(targetPlayer)
    local localRoot = getRoot(LocalPlayer)
    if targetRoot and localRoot then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
        print("ТП к: " .. targetPlayer.Name)
    else
        warn("Не удалось найти HumanoidRootPart!")
    end
end)

-- ====== ПАНЕЛЬ 2: ВИЗУАЛЬНЫЙ ПИСТОЛЕТ ======
local pistolGiven = false

local function createPistol()
    local tool = Instance.new("Tool")
    tool.Name = "Визуал Пистолет"
    tool.RequiresHandle = true
    tool.ToolTip = "Визуал Пистолет"

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

    local trigger = Instance.new("Part")
    trigger.Name = "Trigger"
    trigger.Size = Vector3.new(0.12, 0.25, 0.18)
    trigger.Color = Color3.fromRGB(50, 50, 55)
    trigger.Material = Enum.Material.Metal
    trigger.CanCollide = false
    trigger.CFrame = handle.CFrame * CFrame.new(0, -0.1, -0.25)
    trigger.Parent = tool

    local weld3 = Instance.new("WeldConstraint")
    weld3.Part0 = handle
    weld3.Part1 = trigger
    weld3.Parent = handle

    tool.Activated:Connect(function()
        local flash = Instance.new("Part")
        flash.Name = "Flash"
        flash.Size = Vector3.new(0.4, 0.4, 0.4)
        flash.Shape = Enum.PartType.Ball
        flash.Color = Color3.fromRGB(255, 220, 80)
        flash.Material = Enum.Material.Neon
        flash.CanCollide = false
        flash.Anchored = false
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

        local localRoot = getRoot(LocalPlayer)
        if localRoot then
            localRoot.AssemblyLinearVelocity = localRoot.CFrame.LookVector * -15
        end
    end)

    return tool
end

createPanelNoInput(130, "Выдать пистолет", function()
    if pistolGiven then
        warn("Пистолет уже выдан!")
        return
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then
        backpack = LocalPlayer:WaitForChild("Backpack")
    end
    local tool = createPistol()
    tool.Parent = backpack
    pistolGiven = true
    print("Пистолет выдан! Экипируйте его из инвентаря.")
end)

-- ====== ПАНЕЛЬ 3: Я СИГМА (МУЗЫКА) ======
local sigmaSound = nil
local sigmaPlaying = false
local sigmaAuraConn = nil

createPanelNoInput(190, "Я СИГМА", function()
    if sigmaPlaying and sigmaSound then
        sigmaSound:Stop()
        sigmaSound:Destroy()
        sigmaSound = nil
        sigmaPlaying = false
        if sigmaAuraConn then
            sigmaAuraConn:Disconnect()
            sigmaAuraConn = nil
        end
        print("Музыка остановлена")
        return
    end

    local localRoot = getRoot(LocalPlayer)
    if not localRoot then return end

    sigmaSound = Instance.new("Sound")
    sigmaSound.SoundId = "rbxassetid://9046865451"
    sigmaSound.Volume = 2
    sigmaSound.Looped = true
    sigmaSound.Parent = localRoot
    sigmaSound:Play()
    sigmaPlaying = true
    print("Я СИГМА — музыка включена!")

    sigmaAuraConn = RunService.Heartbeat:Connect(function()
        if not sigmaPlaying then return end
        local root = getRoot(LocalPlayer)
        if not root then return end

        local aura = Instance.new("Part")
        aura.Shape = Enum.PartType.Ball
        aura.Size = Vector3.new(6, 6, 6)
        aura.Color = Color3.fromRGB(128, 0, 255)
        aura.Material = Enum.Material.Neon
        aura.Transparency = 0.5
        aura.CanCollide = false
        aura.Anchored = false
        aura.CFrame = root.CFrame
        aura.Parent = workspace

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = aura
        weld.Parent = root

        task.spawn(function()
            for i = 1, 15 do
                if not aura or not aura.Parent then break end
                aura.Transparency = 0.5 + (i / 15) * 0.5
                aura.Size = aura.Size + Vector3.new(0.3, 0.3, 0.3)
                task.wait(0.04)
            end
            if aura then aura:Destroy() end
        end)
    end)
end)

-- ====== ПАНЕЛЬ 4: КРАШ КЛИЕНТА ======
createPanelNoInput(250, "Краш игры", function()
    print("Краш через 3 секунды...")
    task.wait(3)

    task.spawn(function()
        while true do
            for i = 1, 500 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(100, 100, 100)
                p.Anchored = false
                p.CanCollide = true
                p.Position = Vector3.new(
                    math.random(-500, 500),
                    math.random(-500, 500),
                    math.random(-500, 500)
                )
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
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = screenGui

closeButton.MouseButton1Click:Connect(function()
    if sigmaSound then
        sigmaSound:Stop()
        sigmaSound:Destroy()
    end
    if sigmaAuraConn then
        sigmaAuraConn:Disconnect()
    end
    screenGui:Destroy()
end)
