local select, tonumber, tostring, pcall, getgenv, next, type, loadstring = select, tonumber, tostring, pcall, getgenv, next, type, loadstring
local Vector2new, Vector3new, CFramenew, Color3fromRGB, Drawingnew = Vector2.new, Vector3.new, CFrame.new, Color3.fromRGB, Drawing.new
local mathclamp, mathfloor = math.clamp, math.floor
local stringupper, stringmatch = string.upper, string.match
local mousemoverel = mousemoverel or (Input and Input.MouseMove)
local coroutinewrap = coroutine.wrap

--// Environment

getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

--// Variables

local ServiceConnections = {}
local OriginalSensitivity = UserInputService.MouseDeltaSensitivity
local Running = false
local Typing = false
local Animation = nil

--// Script Settings

Environment.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    WallBang = false,
    NoclipOnFly = false,
    Sensitivity = 0,
    ThirdPerson = false,
    ThirdPersonSensitivity = 3,
    TriggerKey = "MouseButton2",
    Toggle = false,
    RandomizePart = false,
    LockPart = "Head",
    SendNotifications = true,
    SaveSettings = true,
    ReloadOnTeleport = true
}

Environment.FOVSettings = {
    Enabled = false,
    Visible = false,
    Amount = 90,
    Color = Color3.fromRGB(255, 255, 255),
    LockedColor = Color3.fromRGB(255, 70, 70),
    Transparency = 0.5,
    Sides = 60,
    Thickness = 1,
    Filled = false
}

Environment.FOVCircle = Drawingnew("Circle")

Environment.FlySettings = {
    ToggleKey = "F"
}

Environment.Fly = {
    State = false,
    Ctrl = {f = 0, b = 0, l = 0, r = 0},
    LastCtrl = {f = 0, b = 0, l = 0, r = 0},
    Speed = 0,
    MaxSpeed = 50,
    BodyGyro = nil,
    BodyVelocity = nil
}

Environment.Movement = {
    WalkSpeedMultiplier = 1
}

Environment.Noclip = {
    Enabled = false,
    OriginalCollide = {}
}

Environment.WrappedPlayers = {}

Environment.Visuals = {
    ESPSettings = {
        Enabled = false,
        TextColor = "20, 90, 255",
        TextSize = 14,
        Center = false,
        Outline = false,
        OutlineColor = "0, 0, 0",
        TextTransparency = 0.7,
        TextFont = (Drawing and Drawing.Fonts and Drawing.Fonts.Monospace) or 2,
        DisplayDistance = false,
        DisplayHealth = false,
        DisplayName = false,
        Rainbow = false
    },
    TracersSettings = {
        Enabled = false,
        Type = 1,
        Transparency = 0.7,
        Thickness = 1,
        Color = "50, 120, 255",
        Rainbow = false
    },
    -- BoxSettings = {
    --     Enabled = false,
    --     Type = 1,
    --     Color = "50, 120, 255",
    --     Transparency = 0.7,
    --     Thickness = 1,
    --     Filled = false,
    --     Increase = 1,
    --     Rainbow = false
    -- },
    HeadDotSettings = {
        Enabled = false,
        Color = "50, 120, 255",
        Transparency = 0.5,
        Thickness = 1,
        Filled = false,
        Sides = 30,
        Size = 2,
        Rainbow = false
    }
}

Environment.Crosshair = {
    CrosshairSettings = {
        Enabled = false,
        Type = 1,
        Size = 12,
        Thickness = 1,
        Color = "0, 255, 0",
        Transparency = 1,
        GapSize = 5,
        CenterDot = false,
        CenterDotColor = "0, 255, 0",
        CenterDotSize = 1,
        CenterDotTransparency = 1,
        CenterDotFilled = false,
        Rainbow = false
    },
    Parts = {
        LeftLine = Drawingnew("Line"),
        RightLine = Drawingnew("Line"),
        TopLine = Drawingnew("Line"),
        BottomLine = Drawingnew("Line"),
        CenterDot = Drawingnew("Circle")
    }
}

--// Helper Functions

local function GetColor(Color)
    if type(Color) == "userdata" then return Color end
    local R = tonumber(stringmatch(Color, "([%d]+)[%s]*,[%s]*[%d]+[%s]*,[%s]*[%d]+"))
    local G = tonumber(stringmatch(Color, "[%d]+[%s]*,[%s]*([%d]+)[%s]*,[%s]*[%d]+"))
    local B = tonumber(stringmatch(Color, "[%d]+[%s]*,[%s]*[%d]+[%s]*,[%s]*([%d]+)"))
    return Color3fromRGB(R or 255, G or 255, B or 255)
end

local function GetRainbowColor()
    return Color3.fromHSV(tick() % 5 / 5, 1, 1)
end

local function GetPlayerTable(Player)
    for _, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then
            return v
        end
    end
end

local function FlyKeyMatches(Input)
    local Key = #Environment.FlySettings.ToggleKey == 1 and stringupper(Environment.FlySettings.ToggleKey) or Environment.FlySettings.ToggleKey
    if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key then
        return true
    end
    if Input.UserInputType.Name == Key then
        return true
    end
    return false
end

local function Fly_Stop()
    Environment.Fly.State = false
    if Environment.Fly.BodyGyro then Environment.Fly.BodyGyro:Destroy() Environment.Fly.BodyGyro = nil end
    if Environment.Fly.BodyVelocity then Environment.Fly.BodyVelocity:Destroy() Environment.Fly.BodyVelocity = nil end
    Environment.Fly.Ctrl = {f = 0, b = 0, l = 0, r = 0}
    Environment.Fly.LastCtrl = {f = 0, b = 0, l = 0, r = 0}
    Environment.Fly.Speed = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
    if ServiceConnections.FlyRender then ServiceConnections.FlyRender:Disconnect() ServiceConnections.FlyRender = nil end
    if ServiceConnections.FlyMoveBegin then ServiceConnections.FlyMoveBegin:Disconnect() ServiceConnections.FlyMoveBegin = nil end
    if ServiceConnections.FlyMoveEnd then ServiceConnections.FlyMoveEnd:Disconnect() ServiceConnections.FlyMoveEnd = nil end
    if ServiceConnections.NoclipStepped then ServiceConnections.NoclipStepped:Disconnect() ServiceConnections.NoclipStepped = nil end
    for part, original in next, Environment.Noclip.OriginalCollide do
        if part and part.Parent then
            part.CanCollide = original
        end
    end
    Environment.Noclip.OriginalCollide = {}
    Environment.Noclip.Enabled = false
end

local function Fly_Start()
    local plr = LocalPlayer
    if not plr or not plr.Character then return end
    local torso = plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
    if not torso or not humanoid then return end
    local bg = Instance.new("BodyGyro", torso)
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = torso.CFrame
    local bv = Instance.new("BodyVelocity", torso)
    bv.Velocity = Vector3.new(0, 0.1, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Environment.Fly.BodyGyro = bg
    Environment.Fly.BodyVelocity = bv
    Environment.Fly.State = true
    humanoid.PlatformStand = true

    if Environment.Settings.NoclipOnFly and not ServiceConnections.NoclipStepped then
        Environment.Noclip.Enabled = true
        Environment.Noclip.OriginalCollide = {}
        ServiceConnections.NoclipStepped = RunService.Stepped:Connect(function()
            if not Environment.Noclip.Enabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in next, char:GetDescendants() do
                if p:IsA("BasePart") then
                    if Environment.Noclip.OriginalCollide[p] == nil then
                        Environment.Noclip.OriginalCollide[p] = p.CanCollide
                    end
                    p.CanCollide = false
                end
            end
        end)
    end

    ServiceConnections.FlyRender = RunService.RenderStepped:Connect(function()
        if not Environment.Fly.State then return end
        if Environment.Fly.Ctrl.l + Environment.Fly.Ctrl.r ~= 0 or Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b ~= 0 then
            Environment.Fly.Speed = Environment.Fly.Speed + .5 + (Environment.Fly.Speed / Environment.Fly.MaxSpeed)
            if Environment.Fly.Speed > Environment.Fly.MaxSpeed then
                Environment.Fly.Speed = Environment.Fly.MaxSpeed
            end
        elseif not (Environment.Fly.Ctrl.l + Environment.Fly.Ctrl.r ~= 0 or Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b ~= 0) and Environment.Fly.Speed ~= 0 then
            Environment.Fly.Speed = Environment.Fly.Speed - 1
            if Environment.Fly.Speed < 0 then
                Environment.Fly.Speed = 0
            end
        end
        if (Environment.Fly.Ctrl.l + Environment.Fly.Ctrl.r) ~= 0 or (Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b) ~= 0 then
            Environment.Fly.BodyVelocity.Velocity = ((workspace.CurrentCamera.CoordinateFrame.LookVector * (Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(Environment.Fly.Ctrl.l + Environment.Fly.Ctrl.r, (Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b) * .2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * Environment.Fly.Speed
            Environment.Fly.LastCtrl = {f = Environment.Fly.Ctrl.f, b = Environment.Fly.Ctrl.b, l = Environment.Fly.Ctrl.l, r = Environment.Fly.Ctrl.r}
        elseif (Environment.Fly.Ctrl.l + Environment.Fly.Ctrl.r) == 0 and (Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b) == 0 and Environment.Fly.Speed ~= 0 then
            Environment.Fly.BodyVelocity.Velocity = ((workspace.CurrentCamera.CoordinateFrame.LookVector * (Environment.Fly.LastCtrl.f + Environment.Fly.LastCtrl.b)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(Environment.Fly.LastCtrl.l + Environment.Fly.LastCtrl.r, (Environment.Fly.LastCtrl.f + Environment.Fly.LastCtrl.b) * .2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * Environment.Fly.Speed
        else
            Environment.Fly.BodyVelocity.Velocity = Vector3.new(0, 0.1, 0)
        end
        Environment.Fly.BodyGyro.CFrame = workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((Environment.Fly.Ctrl.f + Environment.Fly.Ctrl.b) * 50 * Environment.Fly.Speed / Environment.Fly.MaxSpeed), 0, 0)
    end)

    ServiceConnections.FlyMoveBegin = UserInputService.InputBegan:Connect(function(Input, gp)
        if gp then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            local n = Input.KeyCode.Name
            if n == "W" then Environment.Fly.Ctrl.f = 1
            elseif n == "S" then Environment.Fly.Ctrl.b = -1
            elseif n == "A" then Environment.Fly.Ctrl.l = -1
            elseif n == "D" then Environment.Fly.Ctrl.r = 1 end
        end
    end)

    ServiceConnections.FlyMoveEnd = UserInputService.InputEnded:Connect(function(Input, gp)
        if gp then return end
        if Input.UserInputType == Enum.UserInputType.Keyboard then
            local n = Input.KeyCode.Name
            if n == "W" then Environment.Fly.Ctrl.f = 0
            elseif n == "S" then Environment.Fly.Ctrl.b = 0
            elseif n == "A" then Environment.Fly.Ctrl.l = 0
            elseif n == "D" then Environment.Fly.Ctrl.r = 0 end
        end
    end)
end

local function GetHumanoid()
    if LocalPlayer and LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end

local function ApplyWalkSpeed()
    local h = GetHumanoid()
    if h then
        h.WalkSpeed = 16 * Environment.Movement.WalkSpeedMultiplier
    end
end

--// Visuals

local function AddESP(Player)
    local PlayerTable = GetPlayerTable(Player)
    if not PlayerTable then return end
    PlayerTable.ESP = Drawingnew("Text")
    PlayerTable.Connections.ESP = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("HumanoidRootPart") and Environment.Settings.Enabled then
            local Vector, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
            PlayerTable.ESP.Visible = Environment.Visuals.ESPSettings.Enabled
            if OnScreen then
                PlayerTable.ESP.Size = Environment.Visuals.ESPSettings.TextSize
                PlayerTable.ESP.Center = Environment.Visuals.ESPSettings.Center
                PlayerTable.ESP.Outline = Environment.Visuals.ESPSettings.Outline
                PlayerTable.ESP.OutlineColor = GetColor(Environment.Visuals.ESPSettings.OutlineColor)
                PlayerTable.ESP.Color = Environment.Visuals.ESPSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.ESPSettings.TextColor)
                PlayerTable.ESP.Transparency = Environment.Visuals.ESPSettings.TextTransparency
                PlayerTable.ESP.Font = Environment.Visuals.ESPSettings.TextFont
                PlayerTable.ESP.Position = Vector2new(Vector.X, Vector.Y - 25)
                local Content = ""
                if Environment.Visuals.ESPSettings.DisplayName then Content = Player.Name .. " " end
                if Environment.Visuals.ESPSettings.DisplayHealth then Content = Content .. "(" .. tostring(mathfloor(Player.Character.Humanoid.Health)) .. ") " end
                if Environment.Visuals.ESPSettings.DisplayDistance then 
                    local dist = (Player.Character.HumanoidRootPart.Position - (LocalPlayer.Character.HumanoidRootPart.Position or Vector3new(0, 0, 0))).Magnitude
                    Content = Content .. "[" .. tostring(mathfloor(dist)) .. "]" 
                end
                PlayerTable.ESP.Text = Content
                local Alive = (Player.Character.Humanoid.Health > 0)
                local Team = true
                if Environment.Settings.TeamCheck then Team = (Player.TeamColor ~= LocalPlayer.TeamColor) end
                PlayerTable.ESP.Visible = Alive and Team and Environment.Visuals.ESPSettings.Enabled
            else
                PlayerTable.ESP.Visible = false
            end
        else
            PlayerTable.ESP.Visible = false
        end
    end)
end

local function AddTracer(Player)
    local PlayerTable = GetPlayerTable(Player)
    if not PlayerTable then return end
    PlayerTable.Tracer = Drawingnew("Line")
    PlayerTable.Connections.Tracer = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Environment.Settings.Enabled then
            local HRPCFrame, HRPSize = Player.Character.HumanoidRootPart.CFrame, Player.Character.HumanoidRootPart.Size
            local Vector, OnScreen = Camera:WorldToViewportPoint(HRPCFrame * CFramenew(0, -HRPSize.Y, 0).Position)
            if OnScreen then
                PlayerTable.Tracer.Visible = Environment.Visuals.TracersSettings.Enabled
                PlayerTable.Tracer.Thickness = Environment.Visuals.TracersSettings.Thickness
                PlayerTable.Tracer.Color = Environment.Visuals.TracersSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.TracersSettings.Color)
                PlayerTable.Tracer.Transparency = Environment.Visuals.TracersSettings.Transparency
                PlayerTable.Tracer.To = Vector2new(Vector.X, Vector.Y)
                if Environment.Visuals.TracersSettings.Type == 1 then
                    PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                elseif Environment.Visuals.TracersSettings.Type == 2 then
                    PlayerTable.Tracer.From = Vector2new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                else
                    PlayerTable.Tracer.From = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
                end
                local Alive = (Player.Character.Humanoid.Health > 0)
                local Team = true
                if Environment.Settings.TeamCheck then Team = (Player.TeamColor ~= LocalPlayer.TeamColor) end
                PlayerTable.Tracer.Visible = Alive and Team and Environment.Visuals.TracersSettings.Enabled
            else
                PlayerTable.Tracer.Visible = false
            end
        else
            PlayerTable.Tracer.Visible = false
        end
    end)
end

local function AddBox(Player)
    local PlayerTable = GetPlayerTable(Player)
    if not PlayerTable then return end
    PlayerTable.Box.Square = Drawingnew("Square")
    PlayerTable.Box.TopLeftLine = Drawingnew("Line")
    PlayerTable.Box.TopRightLine = Drawingnew("Line")
    PlayerTable.Box.BottomLeftLine = Drawingnew("Line")
    PlayerTable.Box.BottomRightLine = Drawingnew("Line")
    PlayerTable.Connections.Box = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("Head") and Player.Character:FindFirstChild("HumanoidRootPart") and Environment.Settings.Enabled then
            local Vector, OnScreen = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position)
            if OnScreen then
                local HRPCFrame, HRPSize = Player.Character.HumanoidRootPart.CFrame, Player.Character.HumanoidRootPart.Size * Environment.Visuals.BoxSettings.Increase
                local TopLeftPosition = Camera:WorldToViewportPoint(HRPCFrame * CFramenew(HRPSize.X,  HRPSize.Y, 0).Position)
                local TopRightPosition = Camera:WorldToViewportPoint(HRPCFrame * CFramenew(-HRPSize.X,  HRPSize.Y, 0).Position)
                local BottomLeftPosition = Camera:WorldToViewportPoint(HRPCFrame * CFramenew(HRPSize.X, -HRPSize.Y, 0).Position)
                local BottomRightPosition = Camera:WorldToViewportPoint(HRPCFrame * CFramenew(-HRPSize.X, -HRPSize.Y, 0).Position)
                local HeadOffset = Camera:WorldToViewportPoint(Player.Character.Head.Position + Vector3new(0, 0.5, 0))
                local LegsOffset = Camera:WorldToViewportPoint(Player.Character.HumanoidRootPart.Position - Vector3new(0, 3, 0))
                
                local Alive = (Player.Character.Humanoid.Health > 0)
                local Team = true
                if Environment.Settings.TeamCheck then Team = (Player.TeamColor ~= LocalPlayer.TeamColor) end
                local Visible = Alive and Team and Environment.Visuals.BoxSettings.Enabled

                if Environment.Visuals.BoxSettings.Type == 1 then
                    PlayerTable.Box.Square.Visible = false
                    PlayerTable.Box.TopLeftLine.Visible = Visible
                    PlayerTable.Box.TopRightLine.Visible = Visible
                    PlayerTable.Box.BottomLeftLine.Visible = Visible
                    PlayerTable.Box.BottomRightLine.Visible = Visible
                    PlayerTable.Box.TopLeftLine.Thickness = Environment.Visuals.BoxSettings.Thickness
                    PlayerTable.Box.TopLeftLine.Transparency = Environment.Visuals.BoxSettings.Transparency
                    PlayerTable.Box.TopLeftLine.Color = Environment.Visuals.BoxSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.BoxSettings.Color)
                    PlayerTable.Box.TopRightLine.Thickness = Environment.Visuals.BoxSettings.Thickness
                    PlayerTable.Box.TopRightLine.Transparency = Environment.Visuals.BoxSettings.Transparency
                    PlayerTable.Box.TopRightLine.Color = Environment.Visuals.BoxSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.BoxSettings.Color)
                    PlayerTable.Box.BottomLeftLine.Thickness = Environment.Visuals.BoxSettings.Thickness
                    PlayerTable.Box.BottomLeftLine.Transparency = Environment.Visuals.BoxSettings.Transparency
                    PlayerTable.Box.BottomLeftLine.Color = Environment.Visuals.BoxSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.BoxSettings.Color)
                    PlayerTable.Box.BottomRightLine.Thickness = Environment.Visuals.BoxSettings.Thickness
                    PlayerTable.Box.BottomRightLine.Transparency = Environment.Visuals.BoxSettings.Transparency
                    PlayerTable.Box.BottomRightLine.Color = Environment.Visuals.BoxSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.BoxSettings.Color)
                    PlayerTable.Box.TopLeftLine.From = Vector2new(TopLeftPosition.X, TopLeftPosition.Y)
                    PlayerTable.Box.TopLeftLine.To = Vector2new(TopRightPosition.X, TopRightPosition.Y)
                    PlayerTable.Box.TopRightLine.From = Vector2new(TopRightPosition.X, TopRightPosition.Y)
                    PlayerTable.Box.TopRightLine.To = Vector2new(BottomRightPosition.X, BottomRightPosition.Y)
                    PlayerTable.Box.BottomLeftLine.From = Vector2new(BottomLeftPosition.X, BottomLeftPosition.Y)
                    PlayerTable.Box.BottomLeftLine.To = Vector2new(TopLeftPosition.X, TopLeftPosition.Y)
                    PlayerTable.Box.BottomRightLine.From = Vector2new(BottomRightPosition.X, BottomRightPosition.Y)
                    PlayerTable.Box.BottomRightLine.To = Vector2new(BottomLeftPosition.X, BottomLeftPosition.Y)
                else
                    PlayerTable.Box.Square.Visible = Visible
                    PlayerTable.Box.TopLeftLine.Visible = false
                    PlayerTable.Box.TopRightLine.Visible = false
                    PlayerTable.Box.BottomLeftLine.Visible = false
                    PlayerTable.Box.BottomRightLine.Visible = false
                    PlayerTable.Box.Square.Thickness = Environment.Visuals.BoxSettings.Thickness
                    PlayerTable.Box.Square.Color = GetColor(Environment.Visuals.BoxSettings.Color)
                    PlayerTable.Box.Square.Transparency = Environment.Visuals.BoxSettings.Transparency
                    PlayerTable.Box.Square.Filled = Environment.Visuals.BoxSettings.Filled
                    PlayerTable.Box.Square.Size = Vector2new(2000 / Vector.Z, HeadOffset.Y - LegsOffset.Y)
                    PlayerTable.Box.Square.Position = Vector2new(Vector.X - PlayerTable.Box.Square.Size.X / 2, Vector.Y - PlayerTable.Box.Square.Size.Y / 2)
                end
            else
                PlayerTable.Box.Square.Visible = false
                PlayerTable.Box.TopLeftLine.Visible = false
                PlayerTable.Box.TopRightLine.Visible = false
                PlayerTable.Box.BottomLeftLine.Visible = false
                PlayerTable.Box.BottomRightLine.Visible = false
            end
        else
            PlayerTable.Box.Square.Visible = false
            PlayerTable.Box.TopLeftLine.Visible = false
            PlayerTable.Box.TopRightLine.Visible = false
            PlayerTable.Box.BottomLeftLine.Visible = false
            PlayerTable.Box.BottomRightLine.Visible = false
        end
    end)
end

local function AddHeadDot(Player)
    local PlayerTable = GetPlayerTable(Player)
    if not PlayerTable then return end
    PlayerTable.HeadDot = Drawingnew("Circle")
    PlayerTable.Connections.HeadDot = RunService.RenderStepped:Connect(function()
        if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("Head") and Environment.Settings.Enabled then
            local Vector, OnScreen = Camera:WorldToViewportPoint(Player.Character.Head.Position)
            if OnScreen then
                PlayerTable.HeadDot.Visible = Environment.Visuals.HeadDotSettings.Enabled
                PlayerTable.HeadDot.Thickness = Environment.Visuals.HeadDotSettings.Thickness
                PlayerTable.HeadDot.Color = Environment.Visuals.HeadDotSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Visuals.HeadDotSettings.Color)
                PlayerTable.HeadDot.Transparency = Environment.Visuals.HeadDotSettings.Transparency
                PlayerTable.HeadDot.NumSides = Environment.Visuals.HeadDotSettings.Sides
                PlayerTable.HeadDot.Filled = Environment.Visuals.HeadDotSettings.Filled
                PlayerTable.HeadDot.Radius = Environment.Visuals.HeadDotSettings.Size
                PlayerTable.HeadDot.Position = Vector2new(Vector.X, Vector.Y)
                local Alive = (Player.Character.Humanoid.Health > 0)
                local Team = true
                if Environment.Settings.TeamCheck then Team = (Player.TeamColor ~= LocalPlayer.TeamColor) end
                PlayerTable.HeadDot.Visible = Alive and Team and Environment.Visuals.HeadDotSettings.Enabled
            else
                PlayerTable.HeadDot.Visible = false
            end
        else
            PlayerTable.HeadDot.Visible = false
        end
    end)
end

local function AddCrosshair()
    local AxisX, AxisY = nil, nil
    pcall(function()
        ServiceConnections.AxisConnection = RunService.RenderStepped:Connect(function()
            if Environment.Crosshair.CrosshairSettings.Type == 1 then
                AxisX, AxisY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
            else
                AxisX, AxisY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
            end
        end)
        ServiceConnections.CrosshairConnection = RunService.RenderStepped:Connect(function()
            if not AxisX or not AxisY then return end
            local CrosshairColor = Environment.Crosshair.CrosshairSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Crosshair.CrosshairSettings.Color)
            local Enabled = Environment.Settings.Enabled and Environment.Crosshair.CrosshairSettings.Enabled
            Environment.Crosshair.Parts.LeftLine.Visible = Enabled
            Environment.Crosshair.Parts.LeftLine.Color = CrosshairColor
            Environment.Crosshair.Parts.LeftLine.Thickness = Environment.Crosshair.CrosshairSettings.Thickness
            Environment.Crosshair.Parts.LeftLine.Transparency = Environment.Crosshair.CrosshairSettings.Transparency
            Environment.Crosshair.Parts.LeftLine.From = Vector2new(AxisX + Environment.Crosshair.CrosshairSettings.GapSize, AxisY)
            Environment.Crosshair.Parts.LeftLine.To = Vector2new(AxisX + Environment.Crosshair.CrosshairSettings.Size, AxisY)
            Environment.Crosshair.Parts.RightLine.Visible = Enabled
            Environment.Crosshair.Parts.RightLine.Color = CrosshairColor
            Environment.Crosshair.Parts.RightLine.Thickness = Environment.Crosshair.CrosshairSettings.Thickness
            Environment.Crosshair.Parts.RightLine.Transparency = Environment.Crosshair.CrosshairSettings.Transparency
            Environment.Crosshair.Parts.RightLine.From = Vector2new(AxisX - Environment.Crosshair.CrosshairSettings.GapSize, AxisY)
            Environment.Crosshair.Parts.RightLine.To = Vector2new(AxisX - Environment.Crosshair.CrosshairSettings.Size, AxisY)
            Environment.Crosshair.Parts.TopLine.Visible = Enabled
            Environment.Crosshair.Parts.TopLine.Color = CrosshairColor
            Environment.Crosshair.Parts.TopLine.Thickness = Environment.Crosshair.CrosshairSettings.Thickness
            Environment.Crosshair.Parts.TopLine.Transparency = Environment.Crosshair.CrosshairSettings.Transparency
            Environment.Crosshair.Parts.TopLine.From = Vector2new(AxisX, AxisY + Environment.Crosshair.CrosshairSettings.GapSize)
            Environment.Crosshair.Parts.TopLine.To = Vector2new(AxisX, AxisY + Environment.Crosshair.CrosshairSettings.Size)
            Environment.Crosshair.Parts.BottomLine.Visible = Enabled
            Environment.Crosshair.Parts.BottomLine.Color = CrosshairColor
            Environment.Crosshair.Parts.BottomLine.Thickness = Environment.Crosshair.CrosshairSettings.Thickness
            Environment.Crosshair.Parts.BottomLine.Transparency = Environment.Crosshair.CrosshairSettings.Transparency
            Environment.Crosshair.Parts.BottomLine.From = Vector2new(AxisX, AxisY - Environment.Crosshair.CrosshairSettings.GapSize)
            Environment.Crosshair.Parts.BottomLine.To = Vector2new(AxisX, AxisY - Environment.Crosshair.CrosshairSettings.Size)
            Environment.Crosshair.Parts.CenterDot.Visible = Enabled and Environment.Crosshair.CrosshairSettings.CenterDot
            Environment.Crosshair.Parts.CenterDot.Color = Environment.Crosshair.CrosshairSettings.Rainbow and GetRainbowColor() or GetColor(Environment.Crosshair.CrosshairSettings.CenterDotColor)
            Environment.Crosshair.Parts.CenterDot.Radius = Environment.Crosshair.CrosshairSettings.CenterDotSize
            Environment.Crosshair.Parts.CenterDot.Transparency = Environment.Crosshair.CrosshairSettings.CenterDotTransparency
            Environment.Crosshair.Parts.CenterDot.Filled = Environment.Crosshair.CrosshairSettings.CenterDotFilled
            Environment.Crosshair.Parts.CenterDot.Position = Vector2new(AxisX, AxisY)
        end)
    end)
end

--// Aimbot Functions

local function CancelLock()
    Environment.Locked = nil
    if Animation then Animation:Cancel() end
    UserInputService.MouseDeltaSensitivity = OriginalSensitivity
end

local function GetClosestPlayer()
    if not Environment.Locked then
        local RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 5000)
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
                if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if Environment.Settings.WallCheck and not Environment.Settings.WallBang then
                    local TargetPart = v.Character[Environment.Settings.LockPart]
                    local CameraPosition = Camera.CFrame.Position
                    local Direction = (TargetPart.Position - CameraPosition)
                    local RaycastParams = RaycastParams.new()
                    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    RaycastParams.FilterDescendantsInstances = {v.Character, LocalPlayer.Character}
                    local RaycastResult = workspace:Raycast(CameraPosition, Direction, RaycastParams)
                    if RaycastResult and RaycastResult.Instance and not RaycastResult.Instance:IsDescendantOf(v.Character) then continue end
                end
                local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
                local MousePos = UserInputService:GetMouseLocation()
                local Distance = (Vector2new(MousePos.X, MousePos.Y) - Vector2new(Vector.X, Vector.Y)).Magnitude
                if Distance < RequiredDistance and OnScreen then
                    RequiredDistance = Distance
                    Environment.Locked = v
                    if Environment.Settings.RandomizePart then
                        local Parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
                        Environment.Settings.LockPart = Parts[math.random(1, #Parts)]
                    end
                end
            end
        end
    elseif (UserInputService:GetMouseLocation() - (function()
            local Vector, _ = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
            return Vector2new(Vector.X, Vector.Y)
        end)()).Magnitude > (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 5000) then
        CancelLock()
    end
end

local function SaveSettings()
    -- Add saving logic if needed
end

local function Wrap(Player)
    local Value = { Name = Player.Name, Connections = {}, ESP = nil, Tracer = nil, HeadDot = nil, Box = {Square = nil, TopLeftLine = nil, TopRightLine = nil, BottomLeftLine = nil, BottomRightLine = nil} }
    Environment.WrappedPlayers[#Environment.WrappedPlayers + 1] = Value
    AddESP(Player)
    AddTracer(Player)
    AddBox(Player)
    AddHeadDot(Player)
end

local function UnWrap(Player)
    local Table, Index = nil, nil
    for i, v in next, Environment.WrappedPlayers do
        if v.Name == Player.Name then Table, Index = v, i; break end
    end
    if Table then
        for _, v in next, Table.Connections do v:Disconnect() end
        if Table.ESP then Table.ESP:Remove() end
        if Table.Tracer then Table.Tracer:Remove() end
        if Table.HeadDot then Table.HeadDot:Remove() end
        for _, v in next, Table.Box do if v then v:Remove() end end
        table.remove(Environment.WrappedPlayers, Index)
    end
end

local function Load()
    OriginalSensitivity = UserInputService.MouseDeltaSensitivity
    for _, v in next, Players:GetPlayers() do if v ~= LocalPlayer then Wrap(v) end end
    ServiceConnections.PlayerAddedConnection = Players.PlayerAdded:Connect(function(v) if v ~= LocalPlayer then Wrap(v) end end)
    ServiceConnections.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(v) if v ~= LocalPlayer then UnWrap(v) end end)
    ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
        if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
            Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
            Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
            Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
            Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
            Environment.FOVCircle.Color = Environment.Locked and Environment.FOVSettings.LockedColor or Environment.FOVSettings.Color
            Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
            Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
            Environment.FOVCircle.Position = Vector2new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        else
            Environment.FOVCircle.Visible = false
        end
        if Running and Environment.Settings.Enabled then
            GetClosestPlayer()
            if Environment.Locked then
                if Environment.Settings.ThirdPerson then
                    local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
                    if mousemoverel then
                        mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
                    end
                else
                    if Environment.Settings.Sensitivity > 0 then
                        Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
                        Animation:Play()
                    else
                        Camera.CFrame = CFramenew(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
                    end
                    UserInputService.MouseDeltaSensitivity = 0
                end
            end
        end
    end)
    ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
        if not Typing then
            local Key = #Environment.Settings.TriggerKey == 1 and stringupper(Environment.Settings.TriggerKey) or Environment.Settings.TriggerKey
            if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key) or (Input.UserInputType.Name == Key) then
                if Environment.Settings.Toggle then Running = not Running if not Running then CancelLock() end else Running = true end
            end
        end
    end)
    ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
        if not Typing and not Environment.Settings.Toggle then
            local Key = #Environment.Settings.TriggerKey == 1 and stringupper(Environment.Settings.TriggerKey) or Environment.Settings.TriggerKey
            if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key) or (Input.UserInputType.Name == Key) then
                Running = false; CancelLock()
            end
        end
    end)
    ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function() Typing = true end)
    ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)
    AddCrosshair()
    ServiceConnections.FlyToggleConnection = UserInputService.InputBegan:Connect(function(Input, gp) if not gp and FlyKeyMatches(Input) then if Environment.Fly.State then Fly_Stop() else Fly_Start() end end end)
    ApplyWalkSpeed()
    ServiceConnections.WalkSpeedHeartbeat = RunService.Heartbeat:Connect(function()
        local h = GetHumanoid()
        if h and not h.PlatformStand then
            local target = 16 * Environment.Movement.WalkSpeedMultiplier
            if h.WalkSpeed ~= target then h.WalkSpeed = target end
        end
    end)
end

Load()

--// UI Implementation (Stellar UI)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/StarsationSetanya/main/refs/heads/main/framework.lua"))()

local Window = Library:Window({
    Title = "AIMBOT | ALL GAME",
    Desc = "by atl4ntic",
    Icon = "target",
    Theme = "Dark",
    Config = { Keybind = Enum.KeyCode.RightControl, Size = UDim2.fromOffset(580, 450) },
    CloseUIButton = { Enabled = true, Text = "Menu" }
})

local Tabs = {
    Aimbot = Window:Tab({Title = "Aimbot", Icon = "target"}),
    Visuals = Window:Tab({Title = "Visuals", Icon = "eye"}),
    Fly = Window:Tab({Title = "Fly & Movement", Icon = "zap"}),
    Crosshair = Window:Tab({Title = "Crosshair", Icon = "plus"}),
}

Tabs.Aimbot:Section({Title = "Settings"})
Tabs.Aimbot:Toggle({
    Title = "Enabled",
    Value = Environment.Settings.Enabled,
    Callback = function(Value) Environment.Settings.Enabled = Value end
})

Tabs.Aimbot:Dropdown({
    Title = "Trigger Key",
    List = {"MouseButton1", "MouseButton2", "E", "Q", "F", "X", "Z", "LeftControl", "LeftShift"},
    Value = Environment.Settings.TriggerKey,
    Callback = function(Value) Environment.Settings.TriggerKey = Value end
})

Tabs.Aimbot:Toggle({
    Title = "Toggle Mode",
    Value = Environment.Settings.Toggle,
    Callback = function(Value) Environment.Settings.Toggle = Value end
})

Tabs.Aimbot:Slider({
    Title = "Sensitivity",
    Min = 0, Max = 1, Rounding = 2, Value = Environment.Settings.Sensitivity,
    Callback = function(Value) Environment.Settings.Sensitivity = Value end
})

Tabs.Aimbot:Section({Title = "FOV"})
Tabs.Aimbot:Toggle({
    Title = "FOV Enabled",
    Value = Environment.FOVSettings.Enabled,
    Callback = function(Value) Environment.FOVSettings.Enabled = Value end
})
Tabs.Aimbot:Toggle({
    Title = "FOV Visible",
    Value = Environment.FOVSettings.Visible,
    Callback = function(Value) Environment.FOVSettings.Visible = Value end
})
Tabs.Aimbot:Slider({
    Title = "FOV Radius",
    Min = 10, Max = 800, Rounding = 0, Value = Environment.FOVSettings.Amount,
    Callback = function(Value) Environment.FOVSettings.Amount = Value end
})
Tabs.Aimbot:ColorPicker({
    Title = "FOV Color",
    Value = Environment.FOVSettings.Color,
    Callback = function(r, g, b) Environment.FOVSettings.Color = Color3.fromRGB(r, g, b) end
})
Tabs.Aimbot:ColorPicker({
    Title = "FOV Locked Color",
    Value = Environment.FOVSettings.LockedColor,
    Callback = function(r, g, b) Environment.FOVSettings.LockedColor = Color3.fromRGB(r, g, b) end
})

Tabs.Aimbot:Section({Title = "Filters"})
Tabs.Aimbot:Toggle({
    Title = "Team Check",
    Value = Environment.Settings.TeamCheck,
    Callback = function(Value) Environment.Settings.TeamCheck = Value end
})
Tabs.Aimbot:Toggle({
    Title = "Alive Check",
    Value = Environment.Settings.AliveCheck,
    Callback = function(Value) Environment.Settings.AliveCheck = Value end
})
Tabs.Aimbot:Toggle({
    Title = "Wall Check",
    Value = Environment.Settings.WallCheck,
    Callback = function(Value) Environment.Settings.WallCheck = Value end
})
Tabs.Aimbot:Toggle({
    Title = "Wall Bang",
    Value = Environment.Settings.WallBang,
    Callback = function(Value) Environment.Settings.WallBang = Value end
})

-- [Visuals Tab]
Tabs.Visuals:Section({Title = "ESP Settings"})
Tabs.Visuals:Toggle({
    Title = "ESP Enabled",
    Value = Environment.Visuals.ESPSettings.Enabled,
    Callback = function(Value) Environment.Visuals.ESPSettings.Enabled = Value end
})
Tabs.Visuals:Toggle({
    Title = "Show Names",
    Value = Environment.Visuals.ESPSettings.DisplayName,
    Callback = function(Value) Environment.Visuals.ESPSettings.DisplayName = Value end
})
Tabs.Visuals:Toggle({
    Title = "Show Health",
    Value = Environment.Visuals.ESPSettings.DisplayHealth,
    Callback = function(Value) Environment.Visuals.ESPSettings.DisplayHealth = Value end
})
Tabs.Visuals:Toggle({
    Title = "Show Distance",
    Value = Environment.Visuals.ESPSettings.DisplayDistance,
    Callback = function(Value) Environment.Visuals.ESPSettings.DisplayDistance = Value end
})
Tabs.Visuals:ColorPicker({
    Title = "ESP Color",
    Value = GetColor(Environment.Visuals.ESPSettings.TextColor),
    Callback = function(r, g, b) Environment.Visuals.ESPSettings.TextColor = tostring(r)..", "..tostring(g)..", "..tostring(b) end
})

Tabs.Visuals:Section({Title = "Tracers"})
Tabs.Visuals:Toggle({
    Title = "Tracers Enabled",
    Value = Environment.Visuals.TracersSettings.Enabled,
    Callback = function(Value) Environment.Visuals.TracersSettings.Enabled = Value end
})

-- Tabs.Visuals:Section({Title = "Box ESP"})
-- Tabs.Visuals:Toggle({
--     Title = "Box Enabled",
--     Value = Environment.Visuals.BoxSettings.Enabled,
--     Callback = function(Value) Environment.Visuals.BoxSettings.Enabled = Value end
-- })
-- Tabs.Visuals:Dropdown({
--     Title = "Box Type",
--     List = {"3D", "2D"},
--     Value = Environment.Visuals.BoxSettings.Type == 1 and "3D" or "2D",
--     Callback = function(Value) Environment.Visuals.BoxSettings.Type = (Value == "3D" and 1 or 2) end
-- })

-- [Fly Tab]
Tabs.Fly:Section({Title = "Fly Settings"})
Tabs.Fly:Toggle({
    Title = "Fly Enabled",
    Value = Environment.Fly.State,
    Callback = function(Value) if Value then Fly_Start() else Fly_Stop() end end
})
Tabs.Fly:Dropdown({
    Title = "Fly Key",
    List = {"F", "E", "Q", "X", "Z", "I"},
    Value = Environment.FlySettings.ToggleKey,
    Callback = function(Value) Environment.FlySettings.ToggleKey = Value end
})
Tabs.Fly:Toggle({
    Title = "Noclip on Fly",
    Value = Environment.Settings.NoclipOnFly,
    Callback = function(Value) Environment.Settings.NoclipOnFly = Value end
})

Tabs.Fly:Section({Title = "Movement"})
Tabs.Fly:Slider({
    Title = "Speed Multiplier",
    Min = 1, Max = 10, Rounding = 1, Value = Environment.Movement.WalkSpeedMultiplier,
    Callback = function(Value) Environment.Movement.WalkSpeedMultiplier = Value; ApplyWalkSpeed() end
})

-- [Crosshair Tab]
Tabs.Crosshair:Section({Title = "Settings"})
Tabs.Crosshair:Toggle({
    Title = "Enabled",
    Value = Environment.Crosshair.CrosshairSettings.Enabled,
    Callback = function(Value) Environment.Crosshair.CrosshairSettings.Enabled = Value end
})
Tabs.Crosshair:Slider({
    Title = "Size",
    Min = 5, Max = 50, Rounding = 0, Value = Environment.Crosshair.CrosshairSettings.Size,
    Callback = function(Value) Environment.Crosshair.CrosshairSettings.Size = Value end
})
Tabs.Crosshair:ColorPicker({
    Title = "Color",
    Value = GetColor(Environment.Crosshair.CrosshairSettings.Color),
    Callback = function(r, g, b) Environment.Crosshair.CrosshairSettings.Color = tostring(r)..", "..tostring(g)..", "..tostring(b) end
})
