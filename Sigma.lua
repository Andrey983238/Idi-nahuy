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
local function createPanel(yOffset, buttonText, actionFunc, placeholder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 90)
    frame.Position = UDim2.new(0, 20, 0, yOffset)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.
