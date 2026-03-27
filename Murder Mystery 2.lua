if getgenv().MM2Admin_Cleanup then
    getgenv().MM2Admin_Cleanup()
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/StarsationSetanya/main/refs/heads/main/framework.lua"))()

local plrs = game:GetService("Players")
local lplayer = plrs.LocalPlayer
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

getgenv().MM2Admin_Run = true
local flying = false
local noclip = false
local InfiniteJump = false
local ESPToggle = false
local CoinFarmToggle = false
local XrayToggle = false
-- local AimlockToggle = false
-- local SilentAimToggle = false
local AutoShootToggle = false
local TriggerBotToggle = false
local HighlightGunsToggle = false
local ReturnDelay = 3
local LastCFrame = nil
local AntiAFKConnection

local FOVSettings = {
    Enabled = false,
    Visible = false,
    Amount = 90,
    Color = Color3.fromRGB(255, 255, 255),
    Transparency = 0.5,
    Thickness = 1,
    Filled = false
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.ZIndex = 1
getgenv().MM2Admin_FOVCircle = FOVCircle

local speedfly = 1
local Mouse = lplayer:GetMouse()

-- [Helper Functions]
local function GetMurderer()
    for i,v in pairs(plrs:GetPlayers()) do
        if v.Character and (v.Character:FindFirstChild("Knife") or v.Backpack:FindFirstChild("Knife")) then
            return v
        end
    end
end

local function GetSheriff()
    for i,v in pairs(plrs:GetPlayers()) do
        if v.Character and (v.Character:FindFirstChild("Gun") or v.Backpack:FindFirstChild("Gun")) then
            return v
        end
    end
end

local function GetPlayerNames()
    local names = {}
    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= lplayer then
            table.insert(names, v.Name)
        end
    end
    return names
end

local function ShootAt(targetPart)
    if not targetPart then return end
    if lplayer.Character then
        for _, tool in pairs(lplayer.Character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name == "Gun") then
                local remote = tool:FindFirstChild("Remote") or tool:FindFirstChild("Shoot") or tool:FindFirstChild("Fire")
                if remote then
                    remote:FireServer(targetPart.Position, targetPart.Position)
                end
                break
            end
        end
    end
end

local GunHighlights = {}
local function CreateGunHighlight(gun)
    if GunHighlights[gun] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "GunHighlight"
    highlight.FillColor = Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gun
    GunHighlights[gun] = highlight
end

local function ScanDroppedGuns()
    for gun, highlight in pairs(GunHighlights) do
        if not gun or not gun.Parent then
            if highlight then highlight:Destroy() end
            GunHighlights[gun] = nil
        end
    end

    if not HighlightGunsToggle then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower() == "gundrop" then
            CreateGunHighlight(obj)
        end
    end
end

local function AutoCollectCoins()
    if not CoinFarmToggle or not lplayer.Character or not lplayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = lplayer.Character.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name:lower():find("coin") then
            local dist = (obj.Position - myPos).magnitude
            if dist < 30 then
                firetouchinterest(lplayer.Character.HumanoidRootPart, obj, 0)
                firetouchinterest(lplayer.Character.HumanoidRootPart, obj, 1)
            end
        end
    end
end

local function SavePosition()
    if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
        LastCFrame = lplayer.Character.HumanoidRootPart.CFrame
    end
end

local function ReturnToPosition()
    if LastCFrame and lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
        lplayer.Character.HumanoidRootPart.CFrame = LastCFrame
    end
end

local function TeleportToGun()
    local gunDrop = workspace:FindFirstChild("GunDrop")
    if gunDrop then
        SavePosition()
        lplayer.Character.HumanoidRootPart.CFrame = gunDrop.CFrame
        task.wait(ReturnDelay)
        ReturnToPosition()
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "MM2 Admin",
            Text = "รอให้เชอริฟตายก่อนถึงจะเก็บปืนได้",
            Duration = 2
        })
    end
end

local faces = {"Back","Bottom","Front","Left","Right","Top"}
local function ClearESP()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == ("EGUI") then
            v:Destroy()
        end
    end
end

getgenv().MM2Admin_Cleanup = function()
    getgenv().MM2Admin_Run = false
    if getgenv().MM2Admin_FOVCircle then
        getgenv().MM2Admin_FOVCircle:Remove()
    end
    ClearESP()

    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end

    local function findAndDestroy(parent)
        if not parent then return end
        for _, obj in pairs(parent:GetChildren()) do
            if obj:IsA("ScreenGui") and (obj.Name == "Starsation" or obj:FindFirstChild("Main")) then
                obj:Destroy()
            end
        end
    end

    pcall(function() findAndDestroy(game:GetService("CoreGui")) end)
    pcall(function() findAndDestroy(lplayer:FindFirstChild("PlayerGui")) end)
end

local function MakeESP()
    local isMurderer = lplayer.Backpack:FindFirstChild("Knife") or (lplayer.Character and lplayer.Character:FindFirstChild("Knife"))
    local isSheriff = lplayer.Backpack:FindFirstChild("Gun") or (lplayer.Character and lplayer.Character:FindFirstChild("Gun"))

    for _, v in pairs(plrs:GetPlayers()) do 
        if v.Name ~= lplayer.Name and v.Character and v.Character:FindFirstChild("Head") then
            local targetIsMurderer = v.Backpack:FindFirstChild("Knife") or v.Character:FindFirstChild("Knife")
            local targetIsSheriff = v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Gun")

            local shouldShow = false
            local color = Color3.new(1, 1, 1)

            if isMurderer then
                shouldShow = true
                if targetIsSheriff then
                    color = Color3.new(0, 0, 1)
                end
            elseif isSheriff then
                if targetIsMurderer then
                    shouldShow = true
                    color = Color3.new(1, 0, 0)
                end
            else
                if targetIsMurderer then
                    shouldShow = true
                    color = Color3.new(1, 0, 0)
                elseif targetIsSheriff then
                    shouldShow = true
                    color = Color3.new(0, 0, 1)
                end
            end

            if shouldShow then
                local bgui = Instance.new("BillboardGui", v.Character.Head)
                bgui.Name = ("EGUI")
                bgui.AlwaysOnTop = true
                bgui.ExtentsOffset = Vector3.new(0,2,0)
                bgui.Size = UDim2.new(0,200,0,50)
                local nam = Instance.new("TextLabel", bgui)
                nam.Text = v.Name
                nam.BackgroundTransparency = 1
                nam.TextSize = 15
                nam.Font = Enum.Font.GothamBold
                nam.TextColor3 = color
                nam.Size = UDim2.new(0,200,0,50)

                for _, p in pairs(v.Character:GetChildren()) do
                    if p:IsA("BasePart") then
                        for _, f in pairs(faces) do
                            local m = Instance.new("SurfaceGui", p)
                            m.Name = ("EGUI")
                            m.Face = f
                            m.AlwaysOnTop = true
                            local mf = Instance.new("Frame", m)
                            mf.Size = UDim2.new(1, 0, 1, 0)
                            mf.BorderSizePixel = 0
                            mf.BackgroundTransparency = 0.5
                            mf.BackgroundColor3 = color
                        end
                    end
                end
            end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if getgenv().MM2Admin_Run and InfiniteJump and lplayer.Character and lplayer.Character:FindFirstChildOfClass('Humanoid') then
        lplayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState("Jumping")
    end
end)

local function ToggleFly()
    flying = not flying
    if flying then
        local T = lplayer.Character.HumanoidRootPart
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
                if not getgenv().MM2Admin_Run then break end
                if lplayer.Character:FindFirstChild("Humanoid") then
                    lplayer.Character.Humanoid.PlatformStand = true
                end
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                    SPEED = speedfly * 50
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
            until not flying or not getgenv().MM2Admin_Run
            BG:Destroy()
            BV:Destroy()
            if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
                lplayer.Character.Humanoid.PlatformStand = false
            end
        end)

        local w_conn, s_conn, a_conn, d_conn
        local w_up, s_up, a_up, d_up

        w_conn = Mouse.KeyDown:Connect(function(key) if key:lower() == "w" then CONTROL.F = 1 end end)
        s_conn = Mouse.KeyDown:Connect(function(key) if key:lower() == "s" then CONTROL.B = -1 end end)
        a_conn = Mouse.KeyDown:Connect(function(key) if key:lower() == "a" then CONTROL.L = -1 end end)
        d_conn = Mouse.KeyDown:Connect(function(key) if key:lower() == "d" then CONTROL.R = 1 end end)

        w_up = Mouse.KeyUp:Connect(function(key) if key:lower() == "w" then CONTROL.F = 0 end end)
        s_up = Mouse.KeyUp:Connect(function(key) if key:lower() == "s" then CONTROL.B = 0 end end)
        a_up = Mouse.KeyUp:Connect(function(key) if key:lower() == "a" then CONTROL.L = 0 end end)
        d_up = Mouse.KeyUp:Connect(function(key) if key:lower() == "d" then CONTROL.R = 0 end end)

        task.spawn(function()
            repeat task.wait() until not flying or not getgenv().MM2Admin_Run
            w_conn:Disconnect() s_conn:Disconnect() a_conn:Disconnect() d_conn:Disconnect()
            w_up:Disconnect() s_up:Disconnect() a_up:Disconnect() d_up:Disconnect()
        end)
    end
end

local function XrayOn(obj)
    for _,v in pairs(obj:GetChildren()) do
        if not getgenv().MM2Admin_Run then break end
        if (v:IsA("BasePart")) and not v.Parent:FindFirstChild("Humanoid") then
            v.LocalTransparencyModifier = 0.75
        end
        XrayOn(v)
    end
end

local function XrayOff(obj)
    for _,v in pairs(obj:GetChildren()) do
        if not getgenv().MM2Admin_Run then break end
        if (v:IsA("BasePart")) and not v.Parent:FindFirstChild("Humanoid") then
            v.LocalTransparencyModifier = 0
        end
        XrayOff(v)
    end
end

local function GetClosestToMouse()
    local target = nil
    local maxDist = FOVSettings.Enabled and FOVSettings.Amount or 5000

    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= lplayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") then
            if v.Character.Humanoid.Health <= 0 then continue end

            local hasKnife = v.Character:FindFirstChild("Knife") or v.Backpack:FindFirstChild("Knife")
            if not hasKnife then continue end

            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    target = v
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if not getgenv().MM2Admin_Run then return end
    FOVCircle.Visible = FOVSettings.Enabled and FOVSettings.Visible
    FOVCircle.Radius = FOVSettings.Amount
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Color = FOVSettings.Color
    FOVCircle.Transparency = FOVSettings.Transparency
    FOVCircle.Thickness = FOVSettings.Thickness
    FOVCircle.Filled = FOVSettings.Filled

    if AimlockToggle then
        local hasGun = lplayer.Backpack:FindFirstChild("Gun") or (lplayer.Character and lplayer.Character:FindFirstChild("Gun"))
        if hasGun then
            local target = GetClosestToMouse()
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character.Humanoid.Health > 0 then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Character.HumanoidRootPart.Position)
            end
        end
    end

    -- Silent Aim & Auto Shoot Logic
    if SilentAimToggle or AutoShootToggle then
        local target = GetClosestToMouse()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if AutoShootToggle then
                ShootAt(target.Character.HumanoidRootPart)
            end
        end
    end

    -- Trigger Bot Logic
    if TriggerBotToggle then
        local target = Mouse.Target
        if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
            local plr = plrs:GetPlayerFromCharacter(target.Parent)
            if plr and plr ~= lplayer then
                local targetIsMurderer = plr.Backpack:FindFirstChild("Knife") or plr.Character:FindFirstChild("Knife")
                if targetIsMurderer then
                    ShootAt(target)
                end
            end
        end
    end
end)

task.spawn(function()
    while getgenv().MM2Admin_Run and task.wait(0.25) do
        AutoCollectCoins()
        ScanDroppedGuns()
    end
end)

-- [UI Setup]
local Window = Library:Window({
    Title = "Murder Mystery 2 Admin Panel",
    Desc = "by atl4ntic. | Menu Edition",
    Icon = "box",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.fromOffset(550, 430)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Menu"
    }
})

local Tabs = {
    Main = Window:Tab({Title = "หลัก", Icon = "home"}),
    Aim = Window:Tab({Title = "ล็อคเป้า", Icon = "target"}),
    Visuals = Window:Tab({Title = "มองทะลุ", Icon = "eye"}),
    Teleport = Window:Tab({Title = "วาร์ป", Icon = "map"}),
    Player = Window:Tab({Title = "ผู้เล่น", Icon = "user"})
}

-- [Main Tab]
Tabs.Main:Section({Title = "Farming"})

Tabs.Main:Toggle({
    Title = "เก็บเหรียญอัตโนมัติ (รัศมี 30 เมตร)",
    Value = false,
    Callback = function(Value)
        CoinFarmToggle = Value
    end
})

Tabs.Main:Section({Title = "Combat"})

Tabs.Main:Button({
    Title = "วาปไปฆ่าฆาตกร (คุณต้องมีปืนถึงจะใช้ได้)",
    Callback = function()
        local hasGun = lplayer.Backpack:FindFirstChild("Gun") or lplayer.Character:FindFirstChild("Gun")
        if not hasGun then
            game.StarterGui:SetCore("SendNotification", {
                Title = "MM2 Admin",
                Text = "คุณต้องมีปืนถึงจะใช้ได้",
                Duration = 3
            })
            return
        end

        local Murderer = GetMurderer()
        if Murderer and Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") then
            repeat task.wait()
                if not getgenv().MM2Admin_Run then break end
                if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
                    lplayer.Character.HumanoidRootPart.CFrame = Murderer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                    workspace.CurrentCamera.CFrame = Murderer.Character.HumanoidRootPart.CFrame
                end
            until Murderer.Character.Humanoid.Health <= 0 or not getgenv().MM2Admin_Run
        end
    end
})

Tabs.Main:Button({
    Title = "วาปไปฆ่าทุกคน (คุณต้องมีมีดถึงจะใช้ได้)",
    Callback = function()
        local hasKnife = lplayer.Backpack:FindFirstChild("Knife") or lplayer.Character:FindFirstChild("Knife")
        if not hasKnife then
            game.StarterGui:SetCore("SendNotification", {
                Title = "MM2 Admin",
                Text = "คุณต้องมีมีดถึงจะใช้ได้!",
                Duration = 3
            })
            return
        end

        for _, Victim in pairs(plrs:GetPlayers()) do
            if not getgenv().MM2Admin_Run then break end
            if Victim ~= lplayer and Victim.Character and Victim.Character:FindFirstChild("HumanoidRootPart") then
                repeat task.wait()
                    if not getgenv().MM2Admin_Run then break end
                    if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
                        lplayer.Character.HumanoidRootPart.CFrame = Victim.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                    end
                until Victim.Character.Humanoid.Health <= 0 or not getgenv().MM2Admin_Run
            end
        end
    end
})

Tabs.Main:Button({
    Title = "วาปไปเก็บปืน (Auto Return)",
    Callback = function()
        TeleportToGun()
    end
})

Tabs.Main:Slider({
    Title = "ระยะเวลากลับมาที่เดิม (วินาที)",
    Min = 1,
    Max = 10,
    Rounding = 0,
    Value = 3,
    Callback = function(Value)
        ReturnDelay = Value
    end
})

Tabs.Main:Section({Title = "Misc"})

Tabs.Main:Toggle({
    Title = "X-Ray",
    Value = false,
    Callback = function(Value)
        if Value then XrayOn(workspace) else XrayOff(workspace) end
    end
})

Tabs.Main:Toggle({
    Title = "กันหลุด (Anti-AFK)",
    Value = true,
    Callback = function(Value)
        if Value then
            local bb = game:GetService("VirtualUser")
            AntiAFKConnection = lplayer.Idled:Connect(function()
                bb:CaptureController()
                bb:ClickButton2(Vector2.new())
                Window:Notify({
                    Title = "MM2 Admin",
                    Desc = "ขยับให้แล้วไม่ต้องกลัวหลุด!",
                    Time = 2
                })
            end)
        else
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end
        end
    end
})

Tabs.Main:Button({
    Title = "ลดแลค bootfps",
    Callback = function()
        local removedecals = false
        local g = game
        local w = g.Workspace
        local l = g.Lighting
        local t = w.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
        settings().Rendering.QualityLevel = "Level01"
        for i, v in pairs(g:GetDescendants()) do
            if not getgenv().MM2Admin_Run then break end
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") and removedecals then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
                v.TextureID = 10385902758728957
            end
        end
        for i, e in pairs(l:GetChildren()) do
            if not getgenv().MM2Admin_Run then break end
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
                e.Enabled = false
            end
        end
    end
})

-- [Aim Tab]
Tabs.Aim:Section({Title = "Aimlock"})

Tabs.Aim:Toggle({
    Title = "เปิดใช้งาน Aimlock (ล็อคเฉพาะมีปืนเท่านั้น)",
    Value = false,
    Callback = function(Value)
        AimlockToggle = Value
    end
})

-- Tabs.Aim:Toggle({
--     Title = "Silent Aim (ยิงอัตโนมัติเมื่อเล็งใกล้เป้าหมาย)",
--     Value = false,
--     Callback = function(Value)
--         SilentAimToggle = Value
--     end
-- })

-- Tabs.Aim:Toggle({
--     Title = "Auto Shoot (ยิงฆาตกรอัตโนมัติ)",
--     Value = false,
--     Callback = function(Value)
--         AutoShootToggle = Value
--     end
-- })

-- Tabs.Aim:Toggle({
--     Title = "Trigger Bot (ยิงเมื่อศัตรูอยู่ในเป้า)",
--     Value = false,
--     Callback = function(Value)
--         TriggerBotToggle = Value
--     end
-- })

Tabs.Aim:Section({Title = "FOV Settings"})

Tabs.Aim:Toggle({
    Title = "เปิดใช้งาน FOV",
    Value = false,
    Callback = function(Value)
        FOVSettings.Enabled = Value
    end
})

Tabs.Aim:Toggle({
    Title = "แสดงวง FOV",
    Value = false,
    Callback = function(Value)
        FOVSettings.Visible = Value
    end
})

Tabs.Aim:Slider({
    Title = "ขนาด FOV",
    Min = 10,
    Max = 800,
    Rounding = 0,
    Value = 90,
    Callback = function(Value)
        FOVSettings.Amount = Value
    end
})

Tabs.Aim:Slider({
    Title = "ความโปร่งใส",
    Min = 0,
    Max = 1,
    Rounding = 2,
    Value = 0.5,
    Callback = function(Value)
        FOVSettings.Transparency = Value
    end
})

Tabs.Aim:ColorPicker({
    Title = "สีวง FOV",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        FOVSettings.Color = Value
    end
})

-- [Visuals Tab]
Tabs.Visuals:Section({Title = "ESP"})

Tabs.Visuals:Toggle({
    Title = "ESP อัจฉริยะแบบอิงตามบทบาท",
    Value = false,
    Callback = function(Value)
        ESPToggle = Value
        if Value then
            MakeESP()
        else
            ClearESP()
        end
    end
})

Tabs.Visuals:Toggle({
    Title = "Highlight Guns (ไฮไลท์ปืนที่ตกพื้น)",
    Value = false,
    Callback = function(Value)
        HighlightGunsToggle = Value
        if not Value then
            for gun, highlight in pairs(GunHighlights) do
                if highlight then highlight:Destroy() end
                GunHighlights[gun] = nil
            end
        end
    end
})

Tabs.Visuals:Button({
    Title = "รีเฟรช ESP",
    Callback = function()
        if ESPToggle then
            ClearESP()
            MakeESP()
        end
    end
})

task.spawn(function()
    while getgenv().MM2Admin_Run and task.wait(5) do
        if ESPToggle then
            ClearESP()
            MakeESP()
        end
    end
end)

-- [Teleport Tab]
Tabs.Teleport:Section({Title = "Locations"})

Tabs.Teleport:Button({
    Title = "TP ไปยังล็อบบี้",
    Callback = function()
        if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
            lplayer.Character.HumanoidRootPart.CFrame = CFrame.new(-108.5, 145, 0.6)
        end
    end
})

Tabs.Teleport:Button({
    Title = "TP ไปยังแผนที่",
    Callback = function()
        for _, v in pairs(workspace:GetChildren()) do
            local spawns = v:FindFirstChild("Spawns")
            local spawnPoint = spawns and spawns:FindFirstChild("Spawn")
            if spawnPoint then
                lplayer.Character.HumanoidRootPart.CFrame = spawnPoint.CFrame
                break
            end
        end
    end
})

Tabs.Teleport:Section({Title = "Players"})

local PlayerDropdown = Tabs.Teleport:Dropdown({
    Title = "เลือกชื่อตัวละคร",
    Options = GetPlayerNames(),
    Default = {},
    MultiSelect = false,
    Callback = function(Options)
        local TargetName = Options[1]
        local Target = plrs:FindFirstChild(TargetName)
        if Target and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart") then
            if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
                lplayer.Character.HumanoidRootPart.CFrame = Target.Character.HumanoidRootPart.CFrame
            end
        end
    end,
})

Tabs.Teleport:Button({
    Title = "รีเฟรชรายชื่อตัวละคร",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayerNames())
    end
})

Tabs.Teleport:Button({
    Title = "TP ไปยังฆาตกร",
    Callback = function()
        local Murderer = GetMurderer()
        if Murderer and Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") then
            lplayer.Character.HumanoidRootPart.CFrame = Murderer.Character.HumanoidRootPart.CFrame
        end
    end
})

Tabs.Teleport:Button({
    Title = "TP ไปยังนายอำเภอ",
    Callback = function()
        local Sheriff = GetSheriff()
        if Sheriff and Sheriff.Character and Sheriff.Character:FindFirstChild("HumanoidRootPart") then
            lplayer.Character.HumanoidRootPart.CFrame = Sheriff.Character.HumanoidRootPart.CFrame
        end
    end
})

-- [Player Tab]
Tabs.Player:Section({Title = "Movement"})

Tabs.Player:Toggle({
    Title = "บิน",
    Value = false,
    Callback = function(Value)
        if flying ~= Value then ToggleFly() end
    end
})

Tabs.Player:Slider({
    Title = "ความเร็วในการบิน",
    Min = 1,
    Max = 10,
    Rounding = 1,
    Value = 1,
    Callback = function(Value)
        speedfly = Value
    end
})

Tabs.Player:Toggle({
    Title = "กระโดดไม่จำกัด",
    Value = false,
    Callback = function(Value)
        InfiniteJump = Value
    end
})

Tabs.Player:Section({Title = "Stats"})

Tabs.Player:Slider({
    Title = "ความเร็วในการเดิน",
    Min = 16,
    Max = 250,
    Rounding = 0,
    Value = 16,
    Callback = function(Value)
        if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
            lplayer.Character.Humanoid.WalkSpeed = Value
        end
    end
})

Tabs.Player:Button({
    Title = "รีเซ็ตความเร็วในการเดิน",
    Callback = function()
        if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
            lplayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

Tabs.Player:Slider({
    Title = "พลังกระโดด",
    Min = 50,
    Max = 500,
    Rounding = 0,
    Value = 50,
    Callback = function(Value)
        if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
            lplayer.Character.Humanoid.JumpPower = Value
        end
    end
})

Tabs.Player:Button({
    Title = "รีเซ็ตพลังกระโดด",
    Callback = function()
        if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
            lplayer.Character.Humanoid.JumpPower = 50
        end
    end
})
