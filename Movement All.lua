local plrs = game:GetService("Players")
local lplayer = plrs.LocalPlayer
local Mouse = lplayer:GetMouse()
local UserInputService = game:GetService("UserInputService")

--// Cleanup previous execution
if getgenv().FlyScript_Run then
    getgenv().FlyScript_Run = false
    task.wait(0.2)
end
if getgenv().FlyScript_AntiAFK then
    getgenv().FlyScript_AntiAFK:Disconnect()
    getgenv().FlyScript_AntiAFK = nil
end
getgenv().FlyScript_Run = true

--// Variables
local flying = false
local speedfly = 20
local InfiniteJump = false
local NoclipOnFly = false
local noclipConn
local originalCanCollide = {}
local isSetup = true
task.delay(1, function() isSetup = false end)

--// Infinite Jump Logic
UserInputService.JumpRequest:Connect(function()
    if getgenv().FlyScript_Run and InfiniteJump and lplayer.Character and lplayer.Character:FindFirstChildOfClass('Humanoid') then
        lplayer.Character:FindFirstChildOfClass('Humanoid'):ChangeState("Jumping")
    end
end)

--// Fly & Noclip Logic
local function SetFly(v)
    if isSetup then return end
    if flying == v then return end
    flying = v
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
                if not getgenv().FlyScript_Run then break end
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
            until not flying or not getgenv().FlyScript_Run
            BG:Destroy()
            BV:Destroy()
            if lplayer.Character and lplayer.Character:FindFirstChild("Humanoid") then
                lplayer.Character.Humanoid.PlatformStand = false
            end
            if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
            end
            for part, original in pairs(originalCanCollide) do
                if part and part.Parent then
                    part.CanCollide = original
                end
            end
            originalCanCollide = {}
        end)

        if NoclipOnFly then
            noclipConn = game:GetService("RunService").Stepped:Connect(function()
                if not flying or not getgenv().FlyScript_Run then return end
                if lplayer.Character then
                    for _, v in pairs(lplayer.Character:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide then
                            originalCanCollide[v] = v.CanCollide
                            v.CanCollide = false
                        end
                    end
                end
            end)
        end

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
            repeat task.wait() until not flying or not getgenv().FlyScript_Run
            w_conn:Disconnect() s_conn:Disconnect() a_conn:Disconnect() d_conn:Disconnect()
            w_up:Disconnect() s_up:Disconnect() a_up:Disconnect() d_up:Disconnect()
        end)
    end
end

--// UI Implementation
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/StarsationSetanya/main/refs/heads/main/framework.lua"))()

local Window = Library:Window({
    Title = "MOVEMENT | ALL GAME",
    Desc = "by atl4ntic",
    Icon = "zap",
    Theme = "Dark",
    Config = { Keybind = Enum.KeyCode.RightControl, Size = UDim2.fromOffset(500, 420) },
    CloseUIButton = { Enabled = true, Text = "Menu" }
})

local Tabs = {
    Player = Window:Tab({Title = "Movement", Icon = "zap"}),
}

-- [Movement Tab]
Tabs.Player:Section({Title = "Fly & Jump"})

Tabs.Player:Keybind({
    Title = "บิน (Fly)",
    Value = false,
    Key = Enum.KeyCode.F,
    Callback = function(Key, Value)
        SetFly(Value)
    end
})

Tabs.Player:Slider({
    Title = "ความเร็วในการบิน",
    Min = 0,
    Max = 20,
    Rounding = 1,
    Value = 20,
    Callback = function(Value)
        speedfly = Value
    end
})

Tabs.Player:Toggle({
    Title = "กระโดดไม่จำกัด (Infinite Jump)",
    Value = false,
    Callback = function(Value)
        InfiniteJump = Value
    end
})

Tabs.Player:Toggle({
    Title = "เดินทะลุขณะบิน (Noclip on Fly)",
    Value = true,
    Callback = function(Value)
        NoclipOnFly = Value
    end
})

Tabs.Player:Section({Title = "Speed & JumpPower"})

Tabs.Player:Slider({
    Title = "ความเร็วในการเดิน (WalkSpeed)",
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
    Title = "พลังกระโดด (JumpPower)",
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

Tabs.Player:Section({Title = "Misc"})

Tabs.Player:Toggle({
    Title = "ระบบกันหลุด (Anti-AFK)",
    Value = true,
    Callback = function(Value)
        if Value then
            local bb = game:GetService("VirtualUser")
            getgenv().FlyScript_AntiAFK = lplayer.Idled:Connect(function()
                bb:CaptureController()
                bb:ClickButton2(Vector2.new())
            end)
        else
            if getgenv().FlyScript_AntiAFK then
                getgenv().FlyScript_AntiAFK:Disconnect()
                getgenv().FlyScript_AntiAFK = nil
            end
        end
    end
})
