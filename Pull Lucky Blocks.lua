local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/StarsationSetanya/main/refs/heads/main/framework.lua"))()

-- [services]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes")
local DumbellRemote = Remotes:WaitForChild("Activate Dumbell")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local CollectRemote = Remotes:WaitForChild("Collect Earnings")
local UpgradeFriendRemote = Remotes:WaitForChild("Upgrade Friend")
local BuyDumbellRemote = Remotes:WaitForChild("Buy Dumbell")
local UpgradeCarryRemote = Remotes:WaitForChild("Upgrade Carry Limit")

-- [to find your base]
local function getPlayerBase()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for i = 1, 5 do
        local base = plots:FindFirstChild("BasePos" .. i)
        if base then
            local owner = base:FindFirstChild("owner")
            if owner and owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
                return base
            end
        end
    end
    return nil
end

-- [Settings State]
local Settings = {
    AutoPower = false,
    VIPDoors = false,
    AutoRebirth = false,
    AutoCollect = false,
    MaxUpgradeLevel = 10,
    AutoUpgrade = false,
    AutoDumbell = false,
    AutoCarry = false,
    ExcludeRarities = {},
    AutoSteal = false,
    AntiAFK = false,
    Fly = false,
    FlySpeed = 50
}

local function ToggleFly()
    if not Settings.Fly then return end
    local T = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not T then return end
    
    local CONTROL = {F = 0, B = 0, L = 0, R = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
    local SPEED = 0

    local BG = Instance.new('BodyGyro', T)
    local BV = Instance.new('BodyVelocity', T)
    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = T.CFrame
    BV.velocity = Vector3.new(0, 0.1, 0)
    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

    task.spawn(function()
        repeat task.wait()
            if not LocalPlayer.Character:FindFirstChild("Humanoid") then break end
            LocalPlayer.Character.Humanoid.PlatformStand = true
            
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                SPEED = Settings.FlySpeed
            else
                SPEED = 0
            end
            
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
                BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif SPEED == 0 then
                BV.velocity = Vector3.new(0, 0.1, 0)
            else
                BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
            end
            BG.cframe = workspace.CurrentCamera.CoordinateFrame
        until not Settings.Fly
        BG:Destroy()
        BV:Destroy()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end)

    local Mouse = LocalPlayer:GetMouse()
    local connections = {}
    table.insert(connections, Mouse.KeyDown:Connect(function(key) 
        if key:lower() == "w" then CONTROL.F = 1 
        elseif key:lower() == "s" then CONTROL.B = -1 
        elseif key:lower() == "a" then CONTROL.L = -1 
        elseif key:lower() == "d" then CONTROL.R = 1 
        end 
    end))
    table.insert(connections, Mouse.KeyUp:Connect(function(key) 
        if key:lower() == "w" then CONTROL.F = 0 
        elseif key:lower() == "s" then CONTROL.B = 0 
        elseif key:lower() == "a" then CONTROL.L = 0 
        elseif key:lower() == "d" then CONTROL.R = 0 
        end 
    end))

    task.spawn(function()
        repeat task.wait() until not Settings.Fly
        for _, c in ipairs(connections) do c:Disconnect() end
    end)
end

local Window = Library:Window({
    Title = "Pull Lucky Blocks Script",
    Desc = "by Phemonaz | Stellar Edition",
    Icon = "box",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.fromOffset(550, 430)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Stellar"
    }
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Farm = Window:Tab({ Title = "Farm", Icon = "bot" }),
    Upgrade = Window:Tab({ Title = "Upgrade", Icon = "wrench" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "cog" })
}

local connections = {}

-- [Main Tab]
do
    Tabs.Main:Section({Title = "Automation"})

    Tabs.Main:Toggle({
        Title = "Auto Power",
        Desc = "Automatically fires dumbell remote",
        Value = false,
        Callback = function(v)
            Settings.AutoPower = v
            if v then
                local lastFire = 0
                connections.power = RunService.Heartbeat:Connect(function()
                    if tick() - lastFire >= 0.05 then
                        lastFire = tick()
                        DumbellRemote:FireServer()
                    end
                end)
            else
                if connections.power then connections.power:Disconnect() connections.power = nil end
            end
        end
    })

    local storedDoors = {}
    Tabs.Main:Toggle({
        Title = "Unlock VIP Doors",
        Desc = "Temporarily removes VIP doors from the map",
        Value = false,
        Callback = function(v)
            Settings.VIPDoors = v
            if v then
                local Map = workspace:FindFirstChild("Map")
                local VIPDoors = Map and Map:FindFirstChild("VIPDoors")
                if VIPDoors then
                    for _, part in ipairs(VIPDoors:GetChildren()) do
                        table.insert(storedDoors, {
                            instance = part,
                            parent = part.Parent
                        })
                        part.Parent = nil
                    end
                end
            else
                for _, data in ipairs(storedDoors) do
                    data.instance.Parent = data.parent
                end
                storedDoors = {}
            end
        end
    })

    Tabs.Main:Toggle({
        Title = "Auto Rebirth",
        Desc = "Automatically rebirths every second",
        Value = false,
        Callback = function(v)
            Settings.AutoRebirth = v
            if v then
                local last = 0
                connections.rebirth = RunService.Heartbeat:Connect(function()
                    if tick() - last >= 1 then
                        last = tick()
                        RebirthRemote:FireServer()
                    end
                end)
            else
                if connections.rebirth then connections.rebirth:Disconnect() connections.rebirth = nil end
            end
        end
    })

    Tabs.Main:Toggle({
        Title = "Auto Collect Cash",
        Desc = "Collects earnings from your base stands",
        Value = false,
        Callback = function(v)
            Settings.AutoCollect = v
            if v then
                local last = 0
                local index = 1
                connections.collect = RunService.Heartbeat:Connect(function()
                    if tick() - last >= 0.1 then
                        last = tick()
                        local base = getPlayerBase()
                        if not base then return end
                        local stands = base.Stands:GetChildren()
                        while index <= #stands and not stands[index]:FindFirstChild("Upgrade") do
                            index = index + 1
                        end
                        if index > #stands then
                            index = 1
                            return
                        end
                        local stand = stands[index]
                        LocalPlayer.Character:PivotTo(stand:GetPivot())
                        CollectRemote:FireServer(stand.Name)
                        index = index + 1
                    end
                end)
            else
                if connections.collect then connections.collect:Disconnect() connections.collect = nil end
            end
        end
    })

    Tabs.Main:Section({Title = "Misc Automation"})

    Tabs.Main:Toggle({
        Title = "Anti-AFK",
        Desc = "Prevents you from being kicked for inactivity",
        Value = false,
        Callback = function(v)
            Settings.AntiAFK = v
            if v then
                local bb = game:GetService("VirtualUser")
                connections.afk = LocalPlayer.Idled:Connect(function()
                    bb:CaptureController()
                    bb:ClickButton2(Vector2.new())
                    Window:Notify({
                        Title = "Anti-AFK",
                        Desc = "Simulated activity to prevent kick!",
                        Time = 2
                    })
                end)
            else
                if connections.afk then connections.afk:Disconnect() connections.afk = nil end
            end
        end
    })

    Tabs.Main:Toggle({
        Title = "Fly",
        Desc = "Allows you to fly around the map",
        Value = false,
        Callback = function(v)
            Settings.Fly = v
            if v then ToggleFly() end
        end
    })

    Tabs.Main:Slider({
        Title = "Fly Speed",
        Desc = "Adjust how fast you fly",
        Min = 10,
        Max = 300,
        Rounding = 0,
        Value = 50,
        Callback = function(v)
            Settings.FlySpeed = v
        end
    })
end

-- [Upgrade Tab]
do
    Tabs.Upgrade:Section({Title = "Upgrades"})

    Tabs.Upgrade:Textbox({
        Title = "Max Upgrade Level",
        Desc = "Set target level for auto upgrade",
        Placeholder = "10",
        Value = "10",
        Callback = function(v)
            Settings.MaxUpgradeLevel = tonumber(v) or 10
        end
    })

    Tabs.Upgrade:Toggle({
        Title = "Auto Upgrade Brainrots",
        Desc = "Upgrades stands up to max level",
        Value = false,
        Callback = function(v)
            Settings.AutoUpgrade = v
            if v then
                local last = 0
                local pendingUpgrade = {}
                connections.upgrade = RunService.Heartbeat:Connect(function()
                    if tick() - last >= 0.1 then
                        last = tick()
                        local base = getPlayerBase()
                        if not base then return end
                        local targetLevel = Settings.MaxUpgradeLevel
                        local stands = base.Stands
                        for _, stand in ipairs(stands:GetChildren()) do
                            if stand:FindFirstChild("Upgrade") then
                                local levelLabel = stand.Upgrade
                                    :FindFirstChild("SurfaceGui")
                                    and stand.Upgrade.SurfaceGui
                                    :FindFirstChild("Frame")
                                    and stand.Upgrade.SurfaceGui.Frame
                                    :FindFirstChild("Button")
                                    and stand.Upgrade.SurfaceGui.Frame.Button
                                    :FindFirstChild("Level")
                                if levelLabel then
                                    local currentLevel = tonumber(levelLabel.Text:match("Lvl%s*(%d+)"))
                                    if currentLevel then
                                        if pendingUpgrade[stand.Name] and currentLevel ~= pendingUpgrade[stand.Name] then
                                            pendingUpgrade[stand.Name] = nil
                                        end
                                        if not pendingUpgrade[stand.Name] and currentLevel < targetLevel then
                                            pendingUpgrade[stand.Name] = currentLevel
                                            UpgradeFriendRemote:FireServer(stand.Name)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                if connections.upgrade then connections.upgrade:Disconnect() connections.upgrade = nil end
            end
        end
    })

    Tabs.Upgrade:Toggle({
        Title = "Auto Buy Dumbells",
        Desc = "Buys all dumbells up to index 20",
        Value = false,
        Callback = function(v)
            Settings.AutoDumbell = v
            if v then
                local last = 0
                connections.dumbell = RunService.Heartbeat:Connect(function()
                    if tick() - last >= 0.1 then
                        last = tick()
                        for i = 1, 20 do
                            BuyDumbellRemote:FireServer("Dumbell_" .. i)
                        end
                    end
                end)
            else
                if connections.dumbell then connections.dumbell:Disconnect() connections.dumbell = nil end
            end
        end
    })

    Tabs.Upgrade:Toggle({
        Title = "Auto Upgrade Pull Limit",
        Desc = "Automatically upgrades carry capacity",
        Value = false,
        Callback = function(v)
            Settings.AutoCarry = v
            if v then
                local last = 0
                connections.carry = RunService.Heartbeat:Connect(function()
                    if tick() - last >= 1 then
                        last = tick()
                        UpgradeCarryRemote:FireServer()
                    end
                end)
            else
                if connections.carry then connections.carry:Disconnect() connections.carry = nil end
            end
        end
    })
end

-- [Farm Tab] (Auto Steal)
do
    Tabs.Farm:Section({Title = "Lucky Block Farm"})

    local rarityThresholds = {
        {name = "OG",           value = 48500000},
        {name = "Brainrot God", value = 9500000},
        {name = "Secret",       value = 2450000},
        {name = "Mythic",       value = 290000},
        {name = "Legendary",    value = 45000},
        {name = "Epic",         value = 9500},
        {name = "Rare",         value = 500},
        {name = "Common",       value = 150},
    }
    local rarityRank = {}
    for rank, tier in ipairs(rarityThresholds) do rarityRank[tier.name] = rank end

    local function parseStrength(str)
        str = tostring(str):gsub(",", ""):gsub("%s", "")
        local num, suffix = str:match("^([%d%.]+)([KkMmBbTt]?)$")
        if not num then return 0 end
        num = tonumber(num) or 0
        suffix = suffix:upper()
        if suffix == "K" then num = num * 1000
        elseif suffix == "M" then num = num * 1000000
        elseif suffix == "B" then num = num * 1000000000
        end
        return num
    end

    local function isBeingStolen(model)
        local mass = model:FindFirstChild("Mass")
        if not mass then return false end
        local stealing = mass:FindFirstChild("STEALING")
        return stealing ~= nil and stealing:IsA("RopeConstraint")
    end

    local function getRarityText(model)
        local text = nil
        pcall(function() text = model.FriendBillboard.Frame.Rarity.Text end)
        return text
    end

    local function isRagdolled()
        local char = LocalPlayer.Character
        if not char then return false end
        local ragdolled = char:FindFirstChild("Ragdolled")
        return ragdolled and ragdolled:IsA("BoolValue") and ragdolled.Value == true
    end

    local function waitForRagdollEnd()
        while Settings.AutoSteal and isRagdolled() do task.wait(0.1) end
        if not Settings.AutoSteal then return false end
        task.wait(0.5)
        return true
    end

    local function attemptSteal(model, rootPart, prompt)
        local MAX_RETRIES = 6
        for attempt = 1, MAX_RETRIES do
            if not Settings.AutoSteal then return "skip" end
            if not model.Parent then return "skip" end
            if isBeingStolen(model) then return "skip" end
            if isRagdolled() then return "ragdoll" end
            pcall(function() LocalPlayer.Character:PivotTo(rootPart.CFrame) end)
            task.wait(0.67)
            if not Settings.AutoSteal then return "skip" end
            if not model.Parent then return "skip" end
            if isBeingStolen(model) then return "skip" end
            if isRagdolled() then return "ragdoll" end
            pcall(function() fireproximityprompt(prompt) end)
            task.wait(1.18)
            if not Settings.AutoSteal then return "skip" end
            if not model.Parent then return "skip" end
            if isBeingStolen(model) then return "skip" end
            if isRagdolled() then return "ragdoll" end
        end
        return "skip"
    end

    Tabs.Farm:Dropdown({
        Title = "Exclude Rarities",
        Desc = "Rarities to ignore during auto collect",
        List = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Brainrot God", "OG"},
        Multi = true,
        Value = {},
        Callback = function(v)
            Settings.ExcludeRarities = {}
            for _, name in ipairs(v) do
                Settings.ExcludeRarities[name] = true
            end
        end
    })

    Tabs.Farm:Toggle({
        Title = "Auto Collect Lucky Blocks",
        Desc = "Automatically steals lucky blocks from Live folder",
        Value = false,
        Callback = function(v)
            Settings.AutoSteal = v
            if v then
                task.spawn(function()
                    while Settings.AutoSteal do
                        if isRagdolled() then
                            local ok = waitForRagdollEnd()
                            if not ok then break end
                            continue
                        end
                        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                        local strengthStat = leaderstats and leaderstats:FindFirstChild("Strength")
                        if not strengthStat then task.wait(1) continue end
                        local strength = parseStrength(strengthStat.Value)
                        local eligibleRarities = {}
                        for _, tier in ipairs(rarityThresholds) do
                            if strength >= tier.value and not Settings.ExcludeRarities[tier.name] then
                                eligibleRarities[tier.name] = true
                            end
                        end
                        if not next(eligibleRarities) then task.wait(1) continue end
                        local Live = workspace:FindFirstChild("Live")
                        local friendsFolder = Live and Live:FindFirstChild("Friends")
                        if not friendsFolder then task.wait(1) continue end
                        local candidates = {}
                        for _, model in ipairs(friendsFolder:GetChildren()) do
                            if model:IsA("Model") then
                                local rarity = getRarityText(model)
                                if rarity and eligibleRarities[rarity] and not isBeingStolen(model) then
                                    local rootPart = model:FindFirstChild("RootPart")
                                    local prompt = rootPart and rootPart:FindFirstChild("StealPrompt")
                                    if prompt then
                                        table.insert(candidates, {
                                            model  = model,
                                            root   = rootPart,
                                            prompt = prompt,
                                            rank   = rarityRank[rarity] or 999,
                                        })
                                    end
                                end
                            end
                        end
                        if #candidates == 0 then task.wait(1) continue end
                        table.sort(candidates, function(a, b) return a.rank < b.rank end)
                        local bestRank = candidates[1].rank
                        local targets = {}
                        for _, c in ipairs(candidates) do if c.rank == bestRank then table.insert(targets, c) end end

                        local ragdolledMidLoop = false
                        for _, target in ipairs(targets) do
                            if not Settings.AutoSteal then break end
                            if not target.model.Parent or isBeingStolen(target.model) then continue end
                            local result = attemptSteal(target.model, target.root, target.prompt)
                            if result == "ragdoll" then
                                local ok = waitForRagdollEnd()
                                ragdolledMidLoop = true
                                if not ok then Settings.AutoSteal = false end
                                break
                            end
                            if Settings.AutoSteal and target.model and target.model.Parent then
                                local HOME = CFrame.new(287, 11, 304)
                                local giveUp = tick() + 5
                                while Settings.AutoSteal and target.model and target.model.Parent and tick() < giveUp do
                                    if isRagdolled() then
                                        local ok = waitForRagdollEnd()
                                        ragdolledMidLoop = true
                                        if not ok then Settings.AutoSteal = false end
                                        break
                                    end
                                    pcall(function() LocalPlayer.Character:PivotTo(HOME) end)
                                    task.wait(0.1)
                                end
                                if ragdolledMidLoop then break end
                            end
                            task.wait(0.5)
                        end
                        if Settings.AutoSteal and not ragdolledMidLoop then task.wait(0.5) end
                    end
                end)
            end
        end
    })
end

-- [Settings Tab]
do
    Tabs.Settings:Section({Title = "Script Information"})
    Tabs.Settings:Button({
        Title = "Destroy UI",
        Desc = "Closes the library and stops all scripts",
        Callback = function()
            Settings.AutoPower = false
            Settings.AutoRebirth = false
            Settings.AutoCollect = false
            Settings.AutoUpgrade = false
            Settings.AutoDumbell = false
            Settings.AutoCarry = false
            Settings.AutoSteal = false
            for _, conn in pairs(connections) do conn:Disconnect() end
            -- Assuming the library has a way to destroy, but usually simply stopping loops is enough.
        end
    })
end

Window:Notify({
    Title = "Script Loaded",
    Desc = "Targeting Lucky Blocks. Good luck!",
    Time = 5
})
