local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1335542673217683487/WVZXojQQewOGicu6hhnNTWMWpmH2-HpTzjIJMwJbINAD7KHMjWKFYiVtDF0iM12afLtr" -- Thay webhook

local petHatchNotifyEvent = ReplicatedStorage:FindFirstChild("PetHatchNotify") or Instance.new("RemoteEvent")
petHatchNotifyEvent.Name = "PetHatchNotify"
petHatchNotifyEvent.Parent = ReplicatedStorage

local rejoinRemoteEvent = ReplicatedStorage:FindFirstChild("RejoinUIEvent") or Instance.new("RemoteEvent")
rejoinRemoteEvent.Name = "RejoinUIEvent"
rejoinRemoteEvent.Parent = ReplicatedStorage

local AUTO_HATCH = true
local AUTO_PLANT = true
local DELETE_WEIGHT_THRESHOLD = 5
local LOOP_DELAY = 0.3
local REJOIN_DELAY = 40

local ZEN_PETS_TO_DELETE = {
    ["Shiba Inu"] = true,
    ["Nihonzaru"] = true,
    ["Tanuki"] = true,
    ["Tanchozuru"] = true,
    ["Kappa"] = true
}

local rejoinStatus = {}

local function sendWebhook(playerName, petName, petWeight)
    local data = {
        username = "GrowAGarden Bot",
        content = string.format("Người chơi **%s** vừa hatch được pet **%s** với cân nặng %.2f kg", playerName, petName, petWeight),
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    local jsonData = HttpService:JSONEncode(data)

    local success, response = pcall(function()
        return HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)

    if success then
        print("[Webhook] Đã gửi thông báo hatch pet thành công")
    else
        warn("[Webhook] Lỗi gửi thông báo hatch pet:", response)
    end
end

petHatchNotifyEvent.OnServerEvent:Connect(function(player, petName, petWeight)
    if petName == "Kitsune" or (petWeight and petWeight > DELETE_WEIGHT_THRESHOLD) then
        sendWebhook(player.Name, petName, petWeight)
    end
end)

local function remoteCall(player, eventName, ...)
    local event = ReplicatedStorage:FindFirstChild(eventName, true)
    if event and event:IsA("RemoteEvent") then
        event:FireClient(player, ...)
    else
        warn("[RemoteEvent] Không tìm thấy:", eventName)
    end
end

local function autoDeleteZenPets(player)
    local petsFolder = player:FindFirstChild("Pets") or (player.Backpack and player.Backpack:FindFirstChild("Pets"))
    if petsFolder then
        for _, pet in ipairs(petsFolder:GetChildren()) do
            local name = pet.Name
            if name == "Kitsune" then
                -- Giữ Kitsune
            elseif ZEN_PETS_TO_DELETE[name] then
                local weight = pet:GetAttribute("Weight") or (pet:FindFirstChild("Weight") and pet.Weight.Value) or 0
                if weight <= DELETE_WEIGHT_THRESHOLD then
                    remoteCall(player, "DeletePet", pet)
                end
            end
        end
    end
end

local function safeRejoin(player)
    if rejoinStatus[player] and rejoinStatus[player].isRejoining then return end
    rejoinStatus[player] = {isRejoining = true, countdown = REJOIN_DELAY}

    rejoinRemoteEvent:FireClient(player, "start", REJOIN_DELAY)

    while rejoinStatus[player].countdown > 0 and rejoinStatus[player].isRejoining do
        wait(1)
        rejoinStatus[player].countdown = rejoinStatus[player].countdown - 1
        rejoinRemoteEvent:FireClient(player, "update", rejoinStatus[player].countdown)
    end

    if rejoinStatus[player].isRejoining then
        TeleportService:Teleport(game.PlaceId, player)
    else
        rejoinRemoteEvent:FireClient(player, "cancel")
    end

    rejoinStatus[player].isRejoining = false
end

rejoinRemoteEvent.OnServerEvent:Connect(function(player, action)
    if action == "cancel" and rejoinStatus[player] then
        rejoinStatus[player].isRejoining = false
    end
end)

RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if not player.Character or not player.Character.Parent then
            if not (rejoinStatus[player] and rejoinStatus[player].isRejoining) then
                spawn(function()
                    while player and player.Parent and (not player.Character or not player.Character.Parent) do
                        safeRejoin(player)
                        wait(REJOIN_DELAY + 1)
                    end
                end)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    spawn(function()
        while player and player.Parent do
            if AUTO_HATCH then
                for i = 1, 8 do
                    remoteCall(player, "HatchZenEgg")
                    wait(0.05)
                end
            end
            if AUTO_PLANT then
                for i = 1, 8 do
                    remoteCall(player, "PlantZenEgg")
                    wait(0.05)
                end
            end
            wait(LOOP_DELAY)
        end
    end)

    spawn(function()
        while player and player.Parent do
            autoDeleteZenPets(player)
            wait(5)
        end
    end)
end)
