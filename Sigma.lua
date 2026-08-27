-- LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerToolGui"
screenGui.ResetOnSpawn = false
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

    frame.InputChanged:Connect(function(input)
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

-- ====== СОЗДАНИЕ ПАНЕЛИ ======
local function createPanel(yOffset, buttonText, actionFunc)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 90)
    frame.Position = UDim2.new(0, 20, 0, yOffset)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = false
    frame.Parent = screenGui

    -- Заголовок-перетаскиватель
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
    textBox.PlaceholderText = "Введите ник игрока..."
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

    -- Перетаскивание работает при зажатии в любом месте панели
    makeDraggable(frame)

    button.MouseButton1Click:Connect(function()
        local targetName = textBox.Text
        if targetName == "" then
            warn("Введите ник игрока!")
            return
        end

        local targetPlayer
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower():find(targetName:lower()) then
                targetPlayer = plr
                break
            end
        end

        if not targetPlayer then
            warn("Игрок '" .. targetName .. "' не найден!")
            return
        end

        actionFunc(targetPlayer)
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

-- ====== ПАНЕЛЬ 1: ТЕЛЕПОРТ ======
createPanel(30, "ТП к игроку", function(targetPlayer)
    local targetRoot = getRoot(targetPlayer)
    local localRoot = getRoot(LocalPlayer)
    if targetRoot and localRoot then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 4)
        print("ТП к: " .. targetPlayer.Name)
    end
end)

-- ====== ПАНЕЛЬ 2: ФЛИНГ (метод спина) ======
createPanel(130, "Флинг", function(targetPlayer)
    local targetRoot = getRoot(targetPlayer)
    local localRoot = getRoot(LocalPlayer)
    if not (targetRoot and localRoot) then return end

    -- Сохраняем исходную позицию, чтобы вернуться обратно
    local originalCFrame = localRoot.CFrame

    -- Телепортируемся внутрь цели
    localRoot.CFrame = targetRoot.CFrame

    -- Быстро вращаемся на месте — это создаёт сильное физическое отбрасывание
    local spinSpeed = math.rad(7200) -- очень быстрое вращение
    local elapsed = 0
    local duration = 1.5

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if elapsed >= duration then
            conn:Disconnect()
            -- Возвращаемся на исходную позицию
            localRoot.CFrame = originalCFrame
            print("Флинг завершён: " .. targetPlayer.Name)
            return
        end
        -- Вращаемся вокруг цели
        localRoot.CFrame = targetRoot.CFrame * CFrame.Angles(0, spinSpeed * dt, 0)
    end)
end)
