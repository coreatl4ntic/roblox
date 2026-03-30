local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/coreatl4ntic/library/refs/heads/main/framework.lua"))()

local Window = Library:Window({
    Title = "Swing Obby for Brainrots!",
    Desc = "by atl4ntic.",
    Icon = 105059922903197,
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
    Farm = Window:Tab({ Title = "Farm", Icon = "star" }),
    Upgrades = Window:Tab({ Title = "Upgrades", Icon = "dollar-sign" }),
    Automation = Window:Tab({ Title = "Automation", Icon = "folder-cog" }),
    Misc = Window:Tab({ Title = "Miscellaneous", Icon = "box" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "wrench" })
}

do
    ---------
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local running = false
    local suffixes = {
        k = 1e3, m = 1e6, b = 1e9, t = 1e12,
        qa = 1e15, qi = 1e18, sx = 1e21,
        sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33
    }
    local function parseMoney(text)
        if not text then return 0 end
        text = text:lower():gsub("%$", ""):gsub(",", "")
        local num, suf = text:match("([%d%.]+)(%a*)")
        num = tonumber(num)
        if not num then return 0 end
        return num * (suffixes[suf] or 1)
    end

    Tabs.Farm:Section({Title = "Brainrots Farm"})

    local excludedRarities = {}
    Tabs.Farm:Dropdown({
        Title = "Exclude Rarities",
        List = {"COMMON","UNCOMMON","RARE","EPIC","LEGENDARY","MYTHIC","SECRET","ANCIENT","DIVINE"},
        Value = {},
        Multi = true,
        Callback = function(Value)
            excludedRarities = Value
        end
    })

    local excludedRanks = {}
    Tabs.Farm:Dropdown({
        Title = "Exclude Ranks",
        List = {"NORMAL","GOLDEN","DIAMOND","EMERALD","RUBY","RAINBOW","VOID","ETHEREAL","CELESTIAL"},
        Value = {},
        Multi = true,
        Callback = function(Value)
            excludedRanks = Value
        end
    })

    local levelLimit = 0
    Tabs.Farm:Textbox({
        Title = "Minimum Brainrot Level",
        Placeholder = "Enter number",
        Value = "0",
        Callback = function(Value)
            levelLimit = tonumber(Value) or 0
        end
    })

    local function getBest()
        local bestPart = nil
        local bestModel = nil
        local bestValue = 0
        for _, part in pairs(workspace.ActiveBrainrots:GetChildren()) do
            if part:IsA("BasePart") then
                local model = part:FindFirstChildOfClass("Model")
                if not model then continue end
                local success, data = pcall(function()
                    local frame = model.LevelBoard.Frame
                    return {
                        earnings = frame.CurrencyFrame.Earnings.Text,
                        rarity = frame.Rarity.Text,
                        rank = frame.Rank.Text,
                        level = frame.Level.Text
                    }
                end)
                if success and data then
                    if excludedRarities[data.rarity] then continue end
                    if excludedRanks[data.rank] then continue end
                    local levelNumber = tonumber(string.match(data.level, "%d+")) or 0
                    if levelNumber <= levelLimit then continue end
                    local value = parseMoney(data.earnings)
                    if value > bestValue then
                        bestValue = value
                        bestPart = part
                        bestModel = model
                    end
                end
            end
        end
        return bestPart, bestModel
    end

    local function teleport(cf)
        local char = player.Character or player.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart")
        root.CFrame = cf
    end

    local function process()
        local part, model = getBest()
        if not part or not model then return end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        teleport(hrp.CFrame + Vector3.new(0, 3, 0))
        task.wait(0.3)
        local attachment = part:FindFirstChild("Attachment")
        if attachment then
            local prompt = attachment:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                fireproximityprompt(prompt)
            end
        end
        task.wait(0.3)
        teleport(CFrame.new(-18, -10, -57))
    end

    Tabs.Farm:Toggle({
        Title = "Farm Brainrots",
        Desc = "Automatically collect the best brainrots",
        Value = false,
        Callback = function(Value)
            running = Value
            if running then
                task.spawn(function()
                    while running do
                        pcall(process)
                        task.wait(1.5)
                    end
                end)
            end
        end
    })

    ---------
    local runningUpgrade = false
    local busy = false
    local interval = 1

    Tabs.Upgrades:Section({Title = "Stat Upgrades"})

    local selectedUpgrades = {}
    Tabs.Upgrades:Dropdown({
        Title = "Select Upgrades",
        List = {"Power", "Reach", "Carry"},
        Value = {},
        Multi = true,
        Callback = function(Value)
            selectedUpgrades = Value
        end
    })

    local powerAmount = 5
    Tabs.Upgrades:Dropdown({
        Title = "Power Amount",
        List = {"5", "25", "50"},
        Value = "5",
        Callback = function(Value)
            powerAmount = tonumber(Value) or 5
        end
    })

    local reachAmount = 5
    Tabs.Upgrades:Dropdown({
        Title = "Reach Amount",
        List = {"5", "25", "50"},
        Value = "5",
        Callback = function(Value)
            reachAmount = tonumber(Value) or 5
        end
    })

    Tabs.Upgrades:Slider({
        Title = "Upgrade Interval",
        Min = 0,
        Max = 5,
        Rounding = 1,
        Value = 1,
        Callback = function(Value)
            interval = Value
        end
    })

    local upgradeRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("Packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("StatUpgradeService")
        :WaitForChild("RF")
        :WaitForChild("Upgrade")

    local function doUpgrade()
        if busy then return end
        busy = true
        if selectedUpgrades["Power"] then
            pcall(function()
                upgradeRemote:InvokeServer("Power", powerAmount)
            end)
        end
        if selectedUpgrades["Reach"] then
            pcall(function()
                upgradeRemote:InvokeServer("Reach_Distance", reachAmount)
            end)
        end
        if selectedUpgrades["Carry"] then
            pcall(function()
                upgradeRemote:InvokeServer("GrabAmount", 1)
            end)
        end
        busy = false
    end

    Tabs.Upgrades:Toggle({
        Title = "Auto Upgrade Selected",
        Value = false,
        Callback = function(Value)
            runningUpgrade = Value
            if runningUpgrade then
                task.spawn(function()
                    while runningUpgrade do
                        doUpgrade()
                        task.wait(interval)
                    end
                end)
            end
        end
    })

    ---------
    Tabs.Upgrades:Section({Title = "Brainrots"})
    local runningPodUpgrade = false
    local podBusy = false
    local maxLevel = 100

    Tabs.Upgrades:Textbox({
        Title = "Max Brainrot Level",
        Placeholder = "Enter max level",
        Value = "100",
        Callback = function(Value)
            maxLevel = tonumber(Value) or 100
        end
    })

    local podUpgradeRemote = game:GetService("ReplicatedStorage")
        :WaitForChild("Packages")
        :WaitForChild("Knit")
        :WaitForChild("Services")
        :WaitForChild("PlotService")
        :WaitForChild("RF")
        :WaitForChild("Upgrade")

    local function getMyPlot()
        local myName = string.upper(player.Name)
        for i = 1, 5 do
            local plot = workspace.Plots:FindFirstChild("Plot"..i)
            if plot then
                local success, ownerText = pcall(function()
                    return plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName.Text
                end)
                if success and ownerText == myName then
                    return plot
                end
            end
        end
    end

    local function getPodLevel(pod)
        local success, levelText = pcall(function()
            local model = pod:FindFirstChild("BrainrotModel")
            if not model then return nil end
            local visual = model:FindFirstChild("VisualAnchor")
            if not visual then return nil end
            local brainrot = visual:GetChildren()[1]
            if not brainrot then return nil end
            return brainrot.LevelBoard.Frame.Level.Text
        end)
        if success and levelText then
            return tonumber(string.match(levelText, "%d+")) or 0
        end
        return nil
    end

    local function processPods()
        if podBusy then return end
        podBusy = true
        local plot = getMyPlot()
        if not plot then
            podBusy = false
            return
        end
        local pods = plot:FindFirstChild("Pods")
        if not pods then
            podBusy = false
            return
        end
        for _, pod in pairs(pods:GetChildren()) do
            if not runningPodUpgrade then break end
            local level = getPodLevel(pod)
            if level and level < maxLevel then
                pcall(function()
                    podUpgradeRemote:InvokeServer(pod)
                end)
                task.wait(0.1)
            end
        end
        podBusy = false
    end

    Tabs.Upgrades:Toggle({
        Title = "Auto Upgrade Brainrots",
        Value = false,
        Callback = function(Value)
            runningPodUpgrade = Value
            if runningPodUpgrade then
                task.spawn(function()
                    while runningPodUpgrade do
                        processPods()
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    ---------
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TIERS = {
        "Normal", "Golden", "Diamond", "Emerald", "Ruby",
        "Rainbow", "Void", "Ethereal", "Celestial"
    }
    local runningClaim = false

    local function getButtons()
        local buttons = {}
        local path = player:WaitForChild("PlayerGui")
            :WaitForChild("ScreenGui")
            :WaitForChild("FrameIndex")
            :WaitForChild("Main")
            :WaitForChild("ScrollingFrame")
        for _, v in ipairs(path:GetChildren()) do
            if v:IsA("ImageButton") then
                table.insert(buttons, v)
            end
        end
        return buttons
    end

    local function runClaim()
        while runningClaim do
            local buttons = getButtons()
            for _, button in ipairs(buttons) do
                if not runningClaim then break end
                local brainrotName = button.Name
                for _, tier in ipairs(TIERS) do
                    if not runningClaim then break end
                    ReplicatedStorage
                        :WaitForChild("Remotes")
                        :WaitForChild("NewBrainrotIndex")
                        :WaitForChild("ClaimBrainrotIndex")
                        :FireServer(brainrotName, tier)
                    task.wait(0.1)
                end
            end
            task.wait(1)
        end
    end

    Tabs.Automation:Toggle({
        Title = "Auto Claim Index Rewards",
        Value = false,
        Callback = function(value)
            runningClaim = value
            if runningClaim then
                task.spawn(runClaim)
            end
        end
    })

    ---------
    local RS = game:GetService("ReplicatedStorage")
    local rebirthEnabled = false
    local function autoRebirthLoop()
        while rebirthEnabled do
            pcall(function()
                RS
                    :WaitForChild("Packages")
                    :WaitForChild("Knit")
                    :WaitForChild("Services")
                    :WaitForChild("StatUpgradeService")
                    :WaitForChild("RF")
                    :WaitForChild("Rebirth")
                    :InvokeServer()
            end)
            task.wait(0.1)
        end
    end

    Tabs.Automation:Toggle({
        Title = "Auto Rebirth",
        Value = false,
        Callback = function(state)
            rebirthEnabled = state
            if rebirthEnabled then
                task.spawn(autoRebirthLoop)
            end
        end
    })

    ---------
    Tabs.Automation:Section({Title = "Collecting"})
    local TweenService = game:GetService("TweenService")
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    local collectionActive = false
    local collectionMode = "Teleport"

    Tabs.Automation:Dropdown({
        Title = "Collection Method",
        List = {"Teleport", "Tween"},
        Value = "Teleport",
        Callback = function(Value)
            collectionMode = Value
        end
    })

    local function getMyPlot2()
        for i = 1, 5 do
            local plot = workspace:WaitForChild("Plots"):FindFirstChild("Plot"..i)
            if plot then
                local label = plot.MainSign.ScreenFrame.SurfaceGui.Frame.Owner.PlayerName
                if label and label.Text == string.upper(player.Name) then
                    return plot
                end
            end
        end
    end

    local function teleportTo(cf)
        root.CFrame = cf
    end

    local function tweenTo(cf)
        local tween = TweenService:Create(
            root,
            TweenInfo.new(0.15, Enum.EasingStyle.Linear),
            {CFrame = cf}
        )
        tween:Play()
        tween.Completed:Wait()
    end

    local function moveTo(cf)
        if collectionMode == "Tween" then
            tweenTo(cf)
        else
            teleportTo(cf)
        end
    end

    local function collectRun()
        while collectionActive do
            local plot = getMyPlot2()
            if not plot then
                task.wait(1)
                continue
            end
            local startPart = plot.MainSign.ScreenFrame
            moveTo(startPart.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.5)
            local pods = plot:WaitForChild("Pods")
            for i = 1, 40 do
                if not collectionActive then break end
                local pod = pods:FindFirstChild(tostring(i))
                if pod and pod:FindFirstChild("TouchPart") then
                    local touch = pod.TouchPart
                    moveTo(touch.CFrame + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                end
            end
            task.wait(1)
        end
    end

    Tabs.Automation:Toggle({
        Title = "Auto Collect Money",
        Value = false,
        Callback = function(v)
            collectionActive = v
            if collectionActive then
                task.spawn(collectRun)
            end
        end
    })

    ---------
    local reachStat = player:WaitForChild("updateStatsFolder"):WaitForChild("Reach_Distance")
    local reachEnabled = false
    local originalReach = reachStat.Value
    local MAX_VALUE = 1e9

    local function enforceReach()
        while reachEnabled do
            if reachStat.Value ~= MAX_VALUE then
                reachStat.Value = MAX_VALUE
            end
            task.wait(0.1)
        end
    end

    Tabs.Misc:Toggle({
        Title = "Inf Rope Reach",
        Value = false,
        Callback = function(state)
            reachEnabled = state
            if reachEnabled then
                originalReach = reachStat.Value
                reachStat.Value = MAX_VALUE
                task.spawn(enforceReach)
            else
                reachStat.Value = originalReach
            end
        end
    })

    ---------
    local powerStat = player:WaitForChild("updateStatsFolder"):WaitForChild("Power")
    local powerEnabled = false
    local originalPower = powerStat.Value
    local sliderPowerValue = 10

    Tabs.Misc:Slider({
        Title = "Custom Power",
        Min = 5,
        Max = 15000,
        Rounding = 1,
        Value = 10,
        Callback = function(Value)
            sliderPowerValue = Value
        end
    })

    local function enforcePower()
        while powerEnabled do
            if powerStat.Value ~= sliderPowerValue then
                powerStat.Value = sliderPowerValue
            end
            task.wait(0.1)
        end
    end

    Tabs.Misc:Toggle({
        Title = "Enable Custom Power",
        Value = false,
        Callback = function(state)
            powerEnabled = state
            if powerEnabled then
                originalPower = powerStat.Value
                powerStat.Value = sliderPowerValue
                task.spawn(enforcePower)
            else
                powerStat.Value = originalPower
            end
        end
    })

    Tabs.Misc:Button({
        Title = "Tp to End",
        Desc = "Teleport to the end of the obby",
        Callback = function()
            local char = player.Character or player.CharacterAdded:Wait()
            local rootPart = char:WaitForChild("HumanoidRootPart")
            rootPart.CFrame = CFrame.new(21, -10, -34044)
        end
    })

    ---------
    -- Tabs.Settings:Button({
    --     Title = "Unload Script",
    --     Desc = "Click to remove the UI",
    --     Callback = function()
    --         -- Add unload logic if library supports it
    --         -- For now, notifying
    --         Window:Notify({
    --             Title = "Settings",
    --             Desc = "Unload functionality not implemented in UI library yet.",
    --             Time = 3
    --         })
    --     end
    -- })

    Window:Notify({
        Title = "Swing Obby for Brainrots!",
        Desc = "Script loaded successfully!",
        Time = 4
    })
end
