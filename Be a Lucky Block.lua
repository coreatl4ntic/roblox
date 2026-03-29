local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/coreatl4ntic/library/refs/heads/main/framework.lua"))()

local Window = Library:Window({
    Title = "Be a Lucky Block",
    Desc = "by atl4ntic",
    Icon = "box",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.new(0, 550, 0, 430)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Menu"
    }
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "home" }),
    Upgrades = Window:Tab({ Title = "Upgrades", Icon = "trending-up" }),
    Brainrots = Window:Tab({ Title = "Brainrots", Icon = "bot" }),
    Stats = Window:Tab({ Title = "Stats", Icon = "bar-chart" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" })
}

do
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local claimGift = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("PlaytimeRewardService")
    :WaitForChild("RF")
    :WaitForChild("ClaimGift")
local autoClaiming = false
local ACPR = Tabs.Main:Toggle({
    Title = "Auto Claim Playtime Rewards",
    Desc = "Automatically claim rewards based on playtime",
    Value = false,
    Callback = function(state)
        autoClaiming = state
        if not state then return end
        task.spawn(function()
            while autoClaiming do
                for reward = 1, 12 do
                    if not autoClaiming then break end
                    local success, err = pcall(function()
                        claimGift:InvokeServer(reward)
                    end)
                    task.wait(0.25)
                end
                task.wait(1)
            end
        end)
    end
})
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rebirth = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("RebirthService")
    :WaitForChild("RF")
    :WaitForChild("Rebirth")
local running = false
local AR = Tabs.Main:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirth when possible",
    Value = false,
    Callback = function(state)
        running = state
        if not state then return end
        task.spawn(function()
            while running do
                pcall(function()
                    rebirth:InvokeServer()
                end)
                task.wait(1)
            end
        end)
    end
})
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local claim = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("SeasonPassService")
    :WaitForChild("RF")
    :WaitForChild("ClaimPassReward")
local running = false
local ACEPR = Tabs.Main:Toggle({
    Title = "Auto Claim Event Pass Rewards",
    Desc = "Automatically claim free event pass rewards",
    Value = false,
    Callback = function(state)
        running = state
        if not state then return end
        task.spawn(function()
            while running do
                local gui = player:WaitForChild("PlayerGui")
                    :WaitForChild("Windows")
                    :WaitForChild("Event")
                    :WaitForChild("Frame")
                    :WaitForChild("Frame")
                    :WaitForChild("Windows")
                    :WaitForChild("Pass")
                    :WaitForChild("Main")
                    :WaitForChild("ScrollingFrame")
                for i = 1, 10 do
                    if not running then break end
                    local item = gui:FindFirstChild(tostring(i))
                    if item and item:FindFirstChild("Frame") and item.Frame:FindFirstChild("Free") then
                        local free = item.Frame.Free
                        local locked = free:FindFirstChild("Locked")
                        local claimed = free:FindFirstChild("Claimed")
                        while running and locked and locked.Visible do
                            task.wait(0.2)
                        end
                        if running and claimed and claimed.Visible then
                            continue
                        end
                        if running and locked and not locked.Visible then
                            pcall(function()
                                claim:InvokeServer("Free", i)
                            end)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
})
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local redeem = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("CodesService")
    :WaitForChild("RF")
    :WaitForChild("RedeemCode")
local codes = {
    "release"
    -- add more codes here
}
Tabs.Main:Button({
    Title = "Redeem All Codes",
    Desc = "Redeem all available working codes",
    Callback = function()
        for _, code in ipairs(codes) do
            pcall(function()
                redeem:InvokeServer(code)
            end)
            task.wait(1)
        end
    end
})
-----
-----
Tabs.Upgrades:Section({ Title = "Speed Upgrades" })
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local upgrade = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("UpgradesService")
    :WaitForChild("RF")
    :WaitForChild("Upgrade")
local amount = 1
local delayTime = 0.5
local running = false
local IMS = Tabs.Upgrades:Textbox({
    Title = "Speed Amount",
    Desc = "Enter the amount of speed to upgrade each time",
    Placeholder = "Number",
    Value = "1",
    Callback = function(Value)
        amount = tonumber(Value) or 1
    end
})

local SMS = Tabs.Upgrades:Slider({
    Title = "Upgrade Interval",
    Desc = "Time between each upgrade (seconds)",
    Value = 1,
    Min = 0,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        delayTime = Value
    end
})

local AMS = Tabs.Upgrades:Toggle({
    Title = "Auto Upgrade Speed",
    Desc = "Automatically upgrade speed at the set interval",
    Value = false,
    Callback = function(state)
        running = state
        if not state then return end
        task.spawn(function()
            while running do
                pcall(function()
                    upgrade:InvokeServer("MovementSpeed", amount)
                end)
                task.wait(delayTime)
            end
        end)
    end
})
-----
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local buy = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_knit@1.7.0")
    :WaitForChild("knit")
    :WaitForChild("Services")
    :WaitForChild("SkinService")
    :WaitForChild("RF")
    :WaitForChild("BuySkin")
local skins = {
    "prestige_mogging_luckyblock",
    "mogging_luckyblock",
    "colossus _luckyblock",
    "inferno_luckyblock",
    "divine_luckyblock",
    "spirit_luckyblock",
    "cyborg_luckyblock",
    "void_luckyblock",
    "gliched_luckyblock",
    "lava_luckyblock",
    "freezy_luckyblock",
    "fairy_luckyblock"
}
local suffix = {
    K = 1e3,
    M = 1e6,
    B = 1e9,
    T = 1e12,
    Qa = 1e15,
    Qi = 1e18,
    Sx = 1e21,
    Sp = 1e24,
    Oc = 1e27,
    No = 1e30,
    Dc = 1e33
}
local function parseCash(text)
    text = text:gsub("%$", ""):gsub(",", ""):gsub("%s+", "")
    local num = tonumber(text:match("[%d%.]+"))
    local suf = text:match("%a+")
    if not num then return 0 end
    if suf and suffix[suf] then
        return num * suffix[suf]
    end
    return num
end
local running = false
local ABL = Tabs.Main:Toggle({
    Title = "Auto Buy Best Luckyblock",
    Desc = "Automatically buy the most expensive pickaxe/luckyblock you can afford",
    Value = false,
    Callback = function(state)
        running = state
        if not state then return end
        task.spawn(function()
            while running do
                local gui = player.PlayerGui:FindFirstChild("Windows")
                if not gui then 
                    task.wait(1)
                    continue 
                end
                local pickaxeShop = gui:FindFirstChild("PickaxeShop")
                if not pickaxeShop then 
                    task.wait(1)
                    continue 
                end
                local shopContainer = pickaxeShop:FindFirstChild("ShopContainer")
                if not shopContainer then 
                    task.wait(1)
                    continue 
                end
                local scrollingFrame = shopContainer:FindFirstChild("ScrollingFrame")
                if not scrollingFrame then 
                    task.wait(1)
                    continue 
                end
                local cash = player.leaderstats.Cash.Value
                local bestSkin = nil
                local bestPrice = 0
                for i = 1, #skins do
                    local name = skins[i]
                    local item = scrollingFrame:FindFirstChild(name)
                    if item then
                        local main = item:FindFirstChild("Main")
                        if main then
                            local buyFolder = main:FindFirstChild("Buy")
                            if buyFolder then
                                local buyButton = buyFolder:FindFirstChild("BuyButton")
                                if buyButton and buyButton.Visible then
                                    local cashLabel = buyButton:FindFirstChild("Cash")
                                    if cashLabel then
                                        local price = parseCash(cashLabel.Text)
                                        if cash >= price and price > bestPrice then
                                            bestSkin = name
                                            bestPrice = price
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if bestSkin then
                    pcall(function()
                        buy:InvokeServer(bestSkin)
                    end)
                end
                task.wait(0.5)
            end
        end)
    end
})
-----
-----
Tabs.Main:Button({
    Title = "Sell Held Brainrot",
    Desc = "Sell the Brainrot you are currently holding",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Sale",
            Button1 = {
                Title = "Confirm",
                Callback = function()
                    local player = game:GetService("Players").LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local tool = character:FindFirstChildOfClass("Tool")
                    if not tool then
                        Window:Notify({
                            Title = "ERROR!",
                            Desc = "Equip the Brainrot you want to Sell",
                            Time = 5
                        })
                        return
                    end
                    local entityId = tool:GetAttribute("EntityId")
                    if not entityId then return end
                    local args = {
                        entityId
                    }
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Packages")
                        :WaitForChild("_Index")
                        :WaitForChild("sleitnick_knit@1.7.0")
                        :WaitForChild("knit")
                        :WaitForChild("Services")
                        :WaitForChild("InventoryService")
                        :WaitForChild("RF")
                        :WaitForChild("SellBrainrot")
                        :InvokeServer(unpack(args))
                    Window:Notify({
                        Title = "SOLD!",
                        Desc = "Sold: " .. tool.Name,
                        Time = 5
                    })

                end
            },
            Button2 = {
                Title = "Cancel",
                Callback = function()
                end
            }
        })
    end
})
-----
-----
Tabs.Main:Button({
    Title = "Pickup All Your Brainrots",
    Desc = "Pick up all your Brainrots from your plot",
    Callback = function()
        Window:Dialog({
            Title = "Confirm Pickup!",
            Button1 = {
                Title = "Confirm",
                Callback = function()
                    local player = game:GetService("Players").LocalPlayer
                    local username = player.Name
                    local plotsFolder = workspace:WaitForChild("Plots")
                    local myPlot
                    for i = 1, 5 do
                        local plot = plotsFolder:FindFirstChild(tostring(i))
                        if plot and plot:FindFirstChild(tostring(i)) then
                            local inner = plot[tostring(i)]
                            for _, v in pairs(inner:GetDescendants()) do
                                if v:IsA("BillboardGui") and string.find(v.Name, username) then
                                    myPlot = inner
                                    break
                                end
                            end
                        end
                        if myPlot then break end
                    end
                    if not myPlot then return end
                    local containers = myPlot:FindFirstChild("Containers")
                    if not containers then return end
                    for i = 1, 30 do
                        local containerFolder = containers:FindFirstChild(tostring(i))
                        if containerFolder and containerFolder:FindFirstChild(tostring(i)) then
                            local container = containerFolder[tostring(i)]
                            local innerModel = container:FindFirstChild("InnerModel")
                            if innerModel and #innerModel:GetChildren() > 0 then
                                local args = {
                                    tostring(i)
                                }
                                game:GetService("ReplicatedStorage")
                                    :WaitForChild("Packages")
                                    :WaitForChild("_Index")
                                    :WaitForChild("sleitnick_knit@1.7.0")
                                    :WaitForChild("knit")
                                    :WaitForChild("Services")
                                    :WaitForChild("ContainerService")
                                    :WaitForChild("RF")
                                    :WaitForChild("PickupBrainrot")
                                    :InvokeServer(unpack(args))
                                task.wait(0.1)
                            end
                        end
                    end
                    Window:Notify({
                        Title = "Done!",
                        Desc = "Picked up all Brainrots",
                        Time = 5
                    })
                end
            },
            Button2 = {
                Title = "Cancel",
                Callback = function()
                end
            }
        })
    end
})
-----
-----
local storedParts = {}
local folder = workspace:WaitForChild("BossTouchDetectors")
local RBTD = Tabs.Brainrots:Toggle({
    Title = "Remove Bad Boss Touch Detectors",
    Desc = "will make it so only the last boss can capture you",
    Value = false,
    Callback = function(state)
        if state then
            storedParts = {}
            for _, obj in ipairs(folder:GetChildren()) do
                if obj.Name ~= "base14" then
                    table.insert(storedParts, obj)
                    obj.Parent = nil
                end
            end
        else
            for _, obj in ipairs(storedParts) do
                if obj then
                    obj.Parent = folder
                end
            end
            storedParts = {}
        end
    end
})
-----
-----
Tabs.Brainrots:Button({
    Title = "Teleport to End",
    Desc = "Teleport all Brainrots to the collection zone",
    Callback = function()
        local modelsFolder = workspace:WaitForChild("RunningModels")
        local target = workspace:WaitForChild("CollectZones"):WaitForChild("base14")
        for _, obj in ipairs(modelsFolder:GetChildren()) do
            if obj:IsA("Model") then
                if obj.PrimaryPart then
                    obj:SetPrimaryPartCFrame(target.CFrame)
                else
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        part.CFrame = target.CFrame
                    end
                end
            elseif obj:IsA("BasePart") then
                obj.CFrame = target.CFrame
            end
        end
    end
})
-----
-----
Tabs.Brainrots:Section({ Title = "Farming" })
local running = false
local AutoFarmToggle = Tabs.Brainrots:Toggle({
    Title = "Auto Farm Best Brainrots",
    Desc = "Automatically spawn and collect the best Brainrots",
    Value = false,
    Callback = function(state)
        running = state
        if state then
            task.spawn(function()
                while running do
                    local player = game.Players.LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local root = character:WaitForChild("HumanoidRootPart")
                    local humanoid = character:WaitForChild("Humanoid")
                    local userId = player.UserId
                    local modelsFolder = workspace:WaitForChild("RunningModels")
                    local target = workspace:WaitForChild("CollectZones"):WaitForChild("base14")
                    root.CFrame = CFrame.new(715, 39, -2122)
                    task.wait(0.3)
                    humanoid:MoveTo(Vector3.new(710, 39, -2122))
                    local ownedModel = nil
                    repeat
                        task.wait(0.3)
                        for _, obj in ipairs(modelsFolder:GetChildren()) do
                            if obj:IsA("Model") and obj:GetAttribute("OwnerId") == userId then
                                ownedModel = obj
                                break
                            end
                        end
                    until ownedModel ~= nil or not running
                    if not running then break end
                    if ownedModel.PrimaryPart then
                        ownedModel:SetPrimaryPartCFrame(target.CFrame)
                    else
                        local part = ownedModel:FindFirstChildWhichIsA("BasePart")
                        if part then
                            part.CFrame = target.CFrame
                        end
                    end
                    task.wait(0.7)
                    if ownedModel and ownedModel.Parent == modelsFolder then
                        if ownedModel.PrimaryPart then
                            ownedModel:SetPrimaryPartCFrame(target.CFrame * CFrame.new(0, -5, 0))
                        else
                            local part = ownedModel:FindFirstChildWhichIsA("BasePart")
                            if part then
                                part.CFrame = target.CFrame * CFrame.new(0, -5, 0)
                            end
                        end
                    end
                    repeat
                        task.wait(0.3)
                    until not running or (ownedModel == nil or ownedModel.Parent ~= modelsFolder)
                    if not running then break end
                    local oldCharacter = player.Character
                    repeat
                        task.wait(0.2)
                    until not running or (player.Character ~= oldCharacter and player.Character ~= nil)
                    if not running then break end
                    task.wait(0.4)
                    local newChar = player.Character
                    local newRoot = newChar:WaitForChild("HumanoidRootPart")
                    newRoot.CFrame = CFrame.new(737, 39, -2118)
                    task.wait(2.1)
                end
            end)
        end
    end
})
-----
-----
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local running = false
local sliderValue = 1000
local originalSpeed = nil
local currentModel = nil
local function getMyModel()
    local folder = workspace:FindFirstChild("RunningModels")
    if not folder then return nil end
    for _, model in ipairs(folder:GetChildren()) do
        if model:GetAttribute("OwnerId") == player.UserId then
            return model
        end
    end
    return nil
end
local function applySpeed()
    local model = getMyModel()
    if not model then
        currentModel = nil
        return
    end
    if model ~= currentModel then
        currentModel = model
        originalSpeed = model:GetAttribute("MovementSpeed")
    end
    if running then
        if originalSpeed == nil then
            originalSpeed = model:GetAttribute("MovementSpeed")
        end
        model:SetAttribute("MovementSpeed", sliderValue)
    end
end
task.spawn(function()
    while true do
        if running then
            applySpeed()
        end
        task.wait(0.2)
    end
end)
local Toggle = Tabs.Stats:Toggle({
    Title = "Enable Custom Lucky Block Speed",
    Desc = "Enable custom movement speed for your Lucky Block",
    Value = false,
    Callback = function(state)
        running = state
        if not running then
            local model = getMyModel()
            if model and originalSpeed ~= nil then
                model:SetAttribute("MovementSpeed", originalSpeed)
            end
            originalSpeed = nil
            currentModel = nil
        end
    end
})

local Slider = Tabs.Stats:Slider({
    Title = "Lucky Block Speed",
    Desc = "Adjust the movement speed of your Lucky Block",
    Value = 1000,
    Min = 50,
    Max = 3000,
    Rounding = 0,
    Callback = function(Value)
        sliderValue = Value
    end
})
-----
-----
Tabs.Settings:Section({ Title = "Misc" })

Tabs.Settings:Toggle({
    Title = "Anti-AFK",
    Desc = "Prevents you from being kicked for being idle",
    Value = true,
    Callback = function(Value)
        if Value then
            local VirtualUser = game:GetService("VirtualUser")
            getgenv().AntiAFK_Connection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if getgenv().AntiAFK_Connection then
                getgenv().AntiAFK_Connection:Disconnect()
                getgenv().AntiAFK_Connection = nil
            end
        end
    end
})

Window:Notify({
    Title = "Loaded",
    Desc = "Be a Lucky Block script loaded successfully!",
    Time = 5
})
end
