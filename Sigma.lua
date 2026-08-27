-- LocalScript (поместить в StarterPlayerScripts или использовать через executor)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Создаём GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerToolGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Функция для создания кнопки с текстовым полем
local function createPanel(yOffset, buttonText, actionText)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 80)
    frame.Position = UDim2.new(0, 20, 0, yOffset)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 30)
    textBox.Position = UDim2.new(0, 10, 0, 10)
    textBox.PlaceholderText = "Введите ник игрока..."
    textBox.Text = ""
    textBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18
    textBox.ClearTextOnFocus = false
    textBox.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, 45)
    button.Text = buttonText
    button.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.Parent = frame

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
            warn("Игрок '" .. targetName .. "' не найден на сервере!")
            return
        end

        actionText(targetPlayer)
    end)

    return frame
end

-- Панель 1: Телепорт к игроку
createPanel(20, "ТП к игроку", function(targetPlayer)
    local targetChar = targetPlayer.Character
    local localChar = LocalPlayer.Character
    if targetChar and localChar then
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if targetRoot and localRoot then
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            print("Телепортирован к: " .. targetPlayer.Name)
        end
    end
end)

-- Панель 2: Флинг игрока
createPanel(110, "Флинг игрока", function(targetPlayer)
    local targetChar = targetPlayer.Character
    local localChar = LocalPlayer.Character
    if targetChar and localChar then
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if targetRoot and localRoot then
            -- Записываем позицию цели
            local originalPos = targetRoot.CFrame
            -- Меняем CFrame на огромную позицию и обратно (стандартный метод флинга)
            for _ = 1, 10 do
                targetRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 10000, 0))
                task.wait()
                targetRoot.CFrame = originalPos
                task.wait()
            end
            print("Флинг применён к: " .. targetPlayer.Name)
        end
    end
end)
