-- ========= [Phần 2: LocalScript Client] =========
-- Đặt trong StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local rejoinRemoteEvent = ReplicatedStorage:WaitForChild("RejoinUIEvent")

local screenGui, frame, countdownLabel, cancelButton

local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RejoinUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = gui

    frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 70)
    frame.Position = UDim2.new(0, 10, 1, -80)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(1, -20, 0, 30)
    countdownLabel.Position = UDim2.new(0, 10, 0, 10)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.new(1,1,1)
    countdownLabel.Font = Enum.Font.SourceSansBold
    countdownLabel.TextSize = 18
    countdownLabel.Text = "Rejoin trong: 0 giây"
    countdownLabel.Parent = frame

    cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(1, -20, 0, 30)
    cancelButton.Position = UDim2.new(0, 10, 0, 40)
    cancelButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    cancelButton.TextColor3 = Color3.new(1,1,1)
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.TextSize = 18
    cancelButton.Text = "Huỷ rejoin"
    cancelButton.Parent = frame

    cancelButton.MouseButton1Click:Connect(function()
        rejoinRemoteEvent:FireServer("cancel")
        if screenGui then
            screenGui:Destroy()
            screenGui = nil
        end
    end)
end

rejoinRemoteEvent.OnClientEvent:Connect(function(action, data)
    if action == "start" then
        if not screenGui then
            createUI()
        end
        countdownLabel.Text = "Rejoin trong: " .. tostring(data) .. " giây"
    elseif action == "update" then
        if screenGui then
            countdownLabel.Text = "Rejoin trong: " .. tostring(data) .. " giây"
        end
    elseif action == "cancel" then
        if screenGui then
            screenGui:Destroy()
            screenGui = nil
        end
    end
end)
