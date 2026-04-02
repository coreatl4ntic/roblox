
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/coreatl4ntic/library/refs/heads/main/framework.lua"))()

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer

local S = {
    AnimalAimbot   = false,
    PlayerAimbot   = false,
    AimbotPriority = "Closest",
    AimbotFOV      = 150,
    AimbotSmooth   = 0.10,
    AimbotPart     = "Head",
    AimbotKey      = Enum.UserInputType.MouseButton2,
    ShowFOV        = true,
    WallCheck      = false,

    AnimalESP      = false,
    ABoxes         = true,
    ACorner        = false,
    ANames         = true,
    ADist          = true,
    AHealth        = true,
    ATracer        = false,
    ATSrc          = "Bottom",
    AColor         = Color3.fromRGB(255, 170, 0),

    PlayerESP      = false,
    PBoxes         = true,
    PCorner        = false,
    PNames         = true,
    PDist          = true,
    PHealth        = true,
    PTracer        = false,
    PTSrc          = "Bottom",
    PColor         = Color3.fromRGB(220, 50, 50),

    MaxDist        = 1500,
    ESPRate        = 2,

    AnimalChams    = false,
    PlayerChams    = false,
    ACFill         = Color3.fromRGB(255, 170, 0),
    ACOut          = Color3.fromRGB(255, 255, 255),
    PCFill         = Color3.fromRGB(220, 50, 50),
    PCOut          = Color3.fromRGB(255, 255, 255),
    CFillTrans     = 0.5,
    COutTrans      = 0,
    CDepth         = "AlwaysOnTop",

    HitboxExtender = false,
    HitboxTarget   = "Both", 
    HitboxColor    = Color3.fromRGB(0, 255, 0),
    HitboxTransparency = 0.5,
    HitboxSize     = 2, 
}

local function GetCam()      return Workspace.CurrentCamera end
local function GetHum(m)     return m and m:FindFirstChildOfClass("Humanoid") end
local function GetRoot(m)
    return m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso"))
end
local function IsAlive(m)
    local h = GetHum(m)
    return h ~= nil and h.Health > 0
end

local function W2S(worldPos)
    local cam = GetCam()
    if not cam then return Vector2.new(0,0), false, -1 end
    local ok, sp = pcall(function() return cam:WorldToViewportPoint(worldPos) end)
    if not ok then return Vector2.new(0,0), false, -1 end
    local sv = Vector2.new(sp.X, sp.Y)
    local on = sp.X > 0 and sp.X < cam.ViewportSize.X
           and sp.Y > 0 and sp.Y < cam.ViewportSize.Y
    return sv, on, sp.Z
end

local function Mid()
    local cam = GetCam()
    return cam and Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        or Vector2.new(960, 540)
end

local function Bounds(model)
    local root = GetRoot(model)
    if not root then return nil end

    local pos = root.Position
    local hum = GetHum(model)

    local hipH = hum and hum.HipHeight or 0
    local charH = hipH > 0 and (hipH * 2 + 1.5) or 5.0

    local top3 = pos + Vector3.new(0, charH * 0.6,  0)
    local bot3 = pos - Vector3.new(0, charH * 0.35, 0)

    local topV, topOn, topZ = W2S(top3)
    local botV, botOn, botZ = W2S(bot3)

    if topZ < 0 and botZ < 0 then return nil end

    if not topOn and not botOn then
        local rootV, rootOn, rootZ = W2S(pos)
        if not rootOn or rootZ < 0 then return nil end
        topV = Vector2.new(rootV.X, rootV.Y - 30)
        botV = Vector2.new(rootV.X, rootV.Y + 10)
    elseif not topOn then
        topV = Vector2.new(botV.X, botV.Y - 40)
    elseif not botOn then
        botV = Vector2.new(topV.X, topV.Y + 40)
    end

    local h  = math.abs(botV.Y - topV.Y)
    if h < 4 then h = 40 end   
    local w  = math.max(h * 0.45, 18)
    local cx = (topV.X + botV.X) / 2

    return cx - w, cx + w, math.min(topV.Y, botV.Y), math.max(topV.Y, botV.Y), cx, pos
end

local ANIMALS = {
    {"albino crocodile",       "Albino Crocodile"},
    {"albino_crocodile",       "Albino Crocodile"},
    {"albinocroc",             "Albino Crocodile"},
    {"colossal rattle snake",  "Colossal Rattle Snake"},
    {"colossalrattlesnake",    "Colossal Rattle Snake"},
    {"colossal_rattle",        "Colossal Rattle Snake"},
    {"colossal rattle",        "Colossal Rattle Snake"},
    {"colossal crab",          "Colossal Crab"},
    {"colossalcrab",           "Colossal Crab"},
    {"colossal_crab",          "Colossal Crab"},
    {"huge scorpion",          "Huge Scorpion"},
    {"hugescorpion",           "Huge Scorpion"},
    {"huge_scorpion",          "Huge Scorpion"},
    {"alpha scorpion",         "Alpha Scorpion"},
    {"alphascorpion",          "Alpha Scorpion"},
    {"alpha_scorpion",         "Alpha Scorpion"},
    {"cave bear",              "Cave Bear"},
    {"cavebear",               "Cave Bear"},
    {"cave_bear",              "Cave Bear"},
    {"snow fox",               "Snow Fox"},
    {"snowfox",                "Snow Fox"},
    {"snow_fox",               "Snow Fox"},
    {"snow wolf",              "Snow Wolf"},
    {"snowwolf",               "Snow Wolf"},
    {"snow_wolf",              "Snow Wolf"},
    {"titan frog",             "Titan Frog"},
    {"titanfrog",              "Titan Frog"},
    {"titan_frog",             "Titan Frog"},
    {"sandy frog",             "Sandy Frog"},
    {"sandyfrog",              "Sandy Frog"},
    {"sandy_frog",             "Sandy Frog"},
    {"desert bunny",           "Desert Bunny"},
    {"desertbunny",            "Desert Bunny"},
    {"desert_bunny",           "Desert Bunny"},
    {"rabbit",                 "Rabbit"},
    {"bunny",                  "Rabbit"},
    {"hare",                   "Rabbit"},
    {"fox",                    "Fox"},
    {"frog",                   "Frog"},
    {"crocodile",              "Crocodile"},
    {"croc",                   "Crocodile"},
    {"ram",                    "Ram"},
    {"boar",                   "Boar"},
    {"bear",                   "Bear"},
    {"antylopy",               "Antylopy"},
    {"antelope",               "Antylopy"},
    {"crab",                   "Crab"},
    {"wolf",                   "Wolf"},
    {"scorpion",               "Scorpion"},
    {"rattlesnake",            "Colossal Rattle Snake"},
    {"snake",                  "Snake"},
    {"deer",                   "Deer"},
    {"elk",                    "Elk"},
    {"moose",                  "Moose"},
    {"buck",                   "Buck"},
    {"doe",                    "Doe"},
    {"pig",                    "Boar"},
    {"cougar",                 "Cougar"},
    {"lion",                   "Lion"},
    {"tiger",                  "Tiger"},
    {"goat",                   "Goat"},
    {"sheep",                  "Sheep"},
    {"bird",                   "Bird"},
    {"turkey",                 "Turkey"},
    {"duck",                   "Duck"},
}

local function LookupAnimal(rawName)
    local lower = rawName:lower()
    for _, entry in ipairs(ANIMALS) do
        if lower:find(entry[1], 1, true) then
            return true, entry[2]
        end
    end
    return false, nil
end

local function Clean(raw)
    local s = tostring(raw or "")
    s = s:gsub("%s*%b()%s*", "")         
    s = s:gsub("[_%-]+", " ")             
    s = s:gsub("%d+", "")                 
    s = s:gsub("(%l)(%u)", "%1 %2")       
    s = s:gsub("(%u+)(%u%l)", "%1 %2")    
    s = s:gsub("(%a)([%a]*)", function(f,r) return f:upper()..r:lower() end)
    s = s:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    return s ~= "" and s or tostring(raw)
end

local function GetLabel(model)
    if not model then return "Unknown" end
    local isA, display = LookupAnimal(model.Name)
    if isA and display then return display end
    local hum = GetHum(model)
    if hum then
        local dn = hum.DisplayName
        if dn and dn ~= "" and not dn:match("^%d+$") then
            return Clean(dn)
        end
    end
    return Clean(model.Name)
end

local Animals     = {}
local PlayerChars = {}

local function RebuildPChars()
    PlayerChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then PlayerChars[p.Character] = true end
    end
end
RebuildPChars()

local function HookPlayer(p)
    p.CharacterAdded:Connect(function(c)
        PlayerChars[c] = true
        Animals[c] = nil
    end)
    p.CharacterRemoving:Connect(function(c)
        PlayerChars[c] = nil
    end)
end
Players.PlayerAdded:Connect(HookPlayer)
for _, p in ipairs(Players:GetPlayers()) do HookPlayer(p) end

local function IsAnimalModel(model)
    if not model or not model.Parent then return false end
    if not model:IsA("Model") then return false end
    if PlayerChars[model] then return false end
    local hum = GetHum(model)
    if not hum then return false end
    if not GetRoot(model) then return false end

    local isA, _ = LookupAnimal(model.Name)
    if isA then return true end

    for _, c in ipairs(model:GetChildren()) do
        if c.Name == "Animate" and (c:IsA("Script") or c:IsA("LocalScript")) then
            return true
        end
    end

    if hum.WalkSpeed > 0 then return true end

    return false
end

local _nextId = 0
local ModelId  = {}

local function GetModelId(model)
    if not ModelId[model] then
        _nextId = _nextId + 1
        ModelId[model] = _nextId
    end
    return ModelId[model]
end

local function RegisterModel(model)
    if not model then return end
    if Animals[model] or PlayerChars[model] then return end
    task.delay(0.15, function()
        if not model or not model.Parent then return end
        if PlayerChars[model] or Animals[model] then return end
        if IsAnimalModel(model) then
            Animals[model] = true
        end
    end)
end

local function Reclassify(model)
    if not model or not model.Parent then return end
    if PlayerChars[model] then return end
    if IsAnimalModel(model) then
        Animals[model] = true
    else
        Animals[model] = nil  
    end
end

for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("Model") and not PlayerChars[d] then
        local isA, _ = LookupAnimal(d.Name)
        if isA and GetHum(d) and GetRoot(d) then
            Animals[d] = true
        else
            RegisterModel(d)
        end
    end
end

Workspace.DescendantAdded:Connect(function(d)
    if d:IsA("Model") then
        if not PlayerChars[d] then
            local isA, _ = LookupAnimal(d.Name)
            if isA then
                task.defer(function()
                    if d and d.Parent and GetHum(d) and GetRoot(d) then
                        Animals[d] = true
                    end
                end)
            else
                RegisterModel(d)
            end
        end
    elseif d:IsA("Humanoid") then
        local m = d.Parent
        if m and m:IsA("Model") then
            RegisterModel(m)
            d:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if m and m.Parent then Reclassify(m) end
            end)
        end  
    elseif d.Name == "HumanoidRootPart" and d:IsA("BasePart") then
        local m = d.Parent
        if m and m:IsA("Model") then RegisterModel(m) end
    elseif d.Name == "Animate" and (d:IsA("Script") or d:IsA("LocalScript")) then
        local m = d.Parent
        if m and m:IsA("Model") and not PlayerChars[m] then
            Animals[m] = true
        end
    end
end)

Workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("Model") then
        Animals[d] = nil; ModelId[d] = nil
    end
end)

task.spawn(function()
    while task.wait(5) do
        RebuildPChars()
        for m in pairs(Animals) do
            if not m or not m.Parent then Animals[m]=nil; ModelId[m]=nil end
        end
    end
end)

local CFolder = CoreGui:FindFirstChild("ForestoChams_v8")
if CFolder then CFolder:Destroy() end
CFolder        = Instance.new("Folder")
CFolder.Name   = "ForestoChams_v8"
CFolder.Parent = CoreGui

local Hlights = {}  

local function GetHL(key, adornee, fill, outline)
    local hl = Hlights[key]
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name   = key
        hl.Parent = CFolder
        Hlights[key] = hl
    end
    pcall(function()
        hl.Adornee             = adornee
        hl.FillColor           = fill
        hl.OutlineColor        = outline
        hl.FillTransparency    = S.CFillTrans
        hl.OutlineTransparency = S.COutTrans
        hl.DepthMode           = Enum.HighlightDepthMode[S.CDepth]
                              or Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled             = true
    end)
end

local function HideHL(key)
    local hl = Hlights[key]
    if hl then pcall(function() hl.Enabled = false end) end
end

local function KillHL(key)
    local hl = Hlights[key]
    if not hl then return end
    pcall(function() hl:Destroy() end)
    Hlights[key] = nil
end

local HitboxVisualsFolder = CoreGui:FindFirstChild("ForestoHitboxVisuals")
if HitboxVisualsFolder then HitboxVisualsFolder:Destroy() end
HitboxVisualsFolder        = Instance.new("Folder")
HitboxVisualsFolder.Name   = "ForestoHitboxVisuals"
HitboxVisualsFolder.Parent = CoreGui

local OriginalSizes    = {}  
local HitboxHighlights = {}  
local ExtendedParts    = {}  

local function GetHitboxHL(model)
    local hl = HitboxHighlights[model]
    if not hl or not hl.Parent then
        if hl then pcall(function() hl:Destroy() end) end
        hl = Instance.new("Highlight")
        hl.Adornee             = model   
        hl.FillColor           = S.HitboxColor
        hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency    = S.HitboxTransparency
        hl.OutlineTransparency = 0
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled             = true
        hl.Parent              = HitboxVisualsFolder
        HitboxHighlights[model] = hl
    else
        pcall(function()
            hl.FillColor        = S.HitboxColor
            hl.FillTransparency = S.HitboxTransparency
            hl.Enabled          = true
        end)
    end
    return hl
end

local function HideHitboxHL(model)
    local hl = HitboxHighlights[model]
    if hl then pcall(function() hl.Enabled = false end) end
end

local function KillHitboxHL(model)
    local hl = HitboxHighlights[model]
    if not hl then return end
    pcall(function() hl:Destroy() end)
    HitboxHighlights[model] = nil
end

local function RemoveHitboxVisual(part)
    if not part then return end
    if OriginalSizes[part] then
        pcall(function() part.Size = OriginalSizes[part] end)
        OriginalSizes[part] = nil
    end
    ExtendedParts[part] = nil
end

local function ClearAllHitboxVisuals()
    local snapshot = {}
    for model, hl in pairs(HitboxHighlights) do snapshot[model] = hl end
    for model, hl in pairs(snapshot) do
        pcall(function() hl:Destroy() end)
    end
    HitboxHighlights = {}

    local sizeSnapshot = {}
    for part, origSize in pairs(OriginalSizes) do sizeSnapshot[part] = origSize end
    for part, origSize in pairs(sizeSnapshot) do
        pcall(function() part.Size = origSize end)
    end
    OriginalSizes = {}
    ExtendedParts = {}
end

local function ProcessHitboxExtender(model, isAnimal)
    if not model or not model.Parent then return end

    local seen = {}
    local partsToExtend = {}
    local head = model:FindFirstChild("Head")
    local root = GetRoot(model)
    for _, part in ipairs({head, root}) do
        if part and part:IsA("BasePart") and not seen[part] then
            seen[part] = true
            table.insert(partsToExtend, part)
        end
    end

    for _, part in ipairs(partsToExtend) do
        if not OriginalSizes[part] then
            OriginalSizes[part] = part.Size
        end
        pcall(function()
            part.Size = OriginalSizes[part] * S.HitboxSize
            ExtendedParts[part] = true
        end)
    end

    GetHitboxHL(model)
end

local function CleanupHitboxExtender(model)
    if not model then return end
    KillHitboxHL(model)
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            RemoveHitboxVisual(part)
        end
    end
end

Workspace.DescendantRemoving:Connect(function(d)
    if d:IsA("Model") then
        CleanupHitboxExtender(d)
    elseif d:IsA("BasePart") then
        RemoveHitboxVisual(d)
    end
end)

local Entries = {}  

local W  = Color3.fromRGB(255,255,255)
local DK = Color3.fromRGB(20,20,20)
local GR = Color3.fromRGB(80,220,60)
local V2 = Vector2.new

local function L(col, thick)
    local d=Drawing.new("Line")
    d.Visible=false; d.Color=col; d.Thickness=thick or 1.5; d.ZIndex=5
    return d
end
local function T(col, sz)
    local d=Drawing.new("Text")
    d.Visible=false; d.Color=col; d.Size=sz or 13
    d.Outline=true; d.Center=true; d.ZIndex=6
    return d
end

local function NewEntry(key, col)
    if Entries[key] then return end
    Entries[key] = {
        bT=L(col), bB=L(col), bL=L(col), bR=L(col),
        tr=L(col,1.2),
        nm=T(col,13), ds=T(W,11), hpPct=T(GR,11),
        hpBg=L(DK,5), hpFg=L(GR,3),
    }
end

local function HideEntry(key)
    local e=Entries[key]; if not e then return end
    e.bT.Visible=false; e.bB.Visible=false; e.bL.Visible=false; e.bR.Visible=false
    e.tr.Visible=false; e.nm.Visible=false; e.ds.Visible=false
    e.hpPct.Visible=false; e.hpBg.Visible=false; e.hpFg.Visible=false
end

local function KillEntry(key)
    local e=Entries[key]; if not e then return end
    pcall(function()
        e.bT:Remove();e.bB:Remove();e.bL:Remove();e.bR:Remove()
        e.tr:Remove();e.nm:Remove();e.ds:Remove()
        e.hpPct:Remove();e.hpBg:Remove();e.hpFg:Remove()
    end)
    Entries[key]=nil
end

local function ClearEntries()
    for k in pairs(Entries) do KillEntry(k) end
end

local CLEN = 0.22

local function DrawFull(e,L_,R_,T_,B_,col)
    e.bT.From=V2(L_,T_); e.bT.To=V2(R_,T_); e.bT.Color=col; e.bT.Visible=true
    e.bB.From=V2(L_,B_); e.bB.To=V2(R_,B_); e.bB.Color=col; e.bB.Visible=true
    e.bL.From=V2(L_,T_); e.bL.To=V2(L_,B_); e.bL.Color=col; e.bL.Visible=true
    e.bR.From=V2(R_,T_); e.bR.To=V2(R_,B_); e.bR.Color=col; e.bR.Visible=true
end

local function DrawCorn(e,L_,R_,T_,B_,col)
    local cw=(R_-L_)*CLEN; local ch=(B_-T_)*CLEN
    e.bT.From=V2(L_,T_);     e.bT.To=V2(L_+cw,T_); e.bT.Color=col; e.bT.Visible=true
    e.bL.From=V2(L_,T_);     e.bL.To=V2(L_,T_+ch); e.bL.Color=col; e.bL.Visible=true
    e.bB.From=V2(R_-cw,B_);  e.bB.To=V2(R_,B_);    e.bB.Color=col; e.bB.Visible=true
    e.bR.From=V2(R_,B_-ch);  e.bR.To=V2(R_,B_);   e.bR.Color=col; e.bR.Visible=true
end

local function Render(key, model, hum, label, col, c)
    local e = Entries[key]
    if not e then return end

    local bL, bR, bT, bB, cx, wpos = Bounds(model)
    if not bL then HideEntry(key); return end

    local lroot = GetRoot(LocalPlayer.Character)
    local dist  = 9999
    if lroot then
        dist = math.floor((lroot.Position - wpos).Magnitude)
    end
    if dist > S.MaxDist then HideEntry(key); return end

    if c.boxes then
        if c.corner then DrawCorn(e,bL,bR,bT,bB,col)
        else              DrawFull(e,bL,bR,bT,bB,col) end
    else
        e.bT.Visible=false;e.bB.Visible=false;e.bL.Visible=false;e.bR.Visible=false
    end

    if c.tracer then
        local cam = GetCam()
        local src = c.tsrc=="Center" and Mid()
                 or V2(cam.ViewportSize.X/2, cam.ViewportSize.Y)
        e.tr.From=src; e.tr.To=V2(cx,bB); e.tr.Color=col; e.tr.Visible=true
    else e.tr.Visible=false end

    if c.names then
        e.nm.Text=label; e.nm.Color=col
        e.nm.Position=V2(cx, bT-16); e.nm.Visible=true
    else e.nm.Visible=false end

    if c.dist then
        e.ds.Text=tostring(dist).."m"
        e.ds.Position=V2(cx, bB+3); e.ds.Visible=true
    else e.ds.Visible=false end

    if c.health and hum then
        local maxH = math.max(hum.MaxHealth, 1)
        local hp   = math.clamp(hum.Health/maxH, 0, 1)
        local bx   = bL - 7
        local fY   = bT + (bB-bT)*(1-hp)
        local hcol = Color3.fromRGB(math.floor(255*(1-hp)), math.floor(255*hp), 0)
        e.hpBg.From=V2(bx,bT);  e.hpBg.To=V2(bx,bB); e.hpBg.Visible=true
        e.hpFg.From=V2(bx,fY);  e.hpFg.To=V2(bx,bB); e.hpFg.Color=hcol; e.hpFg.Visible=true
        e.hpPct.Text=math.floor(hp*100).."%"
        e.hpPct.Color=hcol; e.hpPct.Position=V2(bx,bT-14); e.hpPct.Visible=true
    else
        e.hpBg.Visible=false; e.hpFg.Visible=false; e.hpPct.Visible=false
    end
end

local FovCircle = Drawing.new("Circle")
FovCircle.Thickness=1.5; FovCircle.Color=W
FovCircle.Filled=false;  FovCircle.NumSides=64
FovCircle.Radius=S.AimbotFOV; FovCircle.Visible=false

local function AimHeld()
    local k = S.AimbotKey; if not k then return false end
    local ok, r = pcall(function()
        if k.EnumType==Enum.UserInputType then return UserInputService:IsMouseButtonPressed(k) end
        if k.EnumType==Enum.KeyCode       then return UserInputService:IsKeyDown(k)            end
        return false
    end)
    return ok and r or false
end

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local function HasLOS(targetPart)
    local cam = GetCam()
    if not cam or not targetPart or not targetPart.Parent then return true end

    local exclude = {}
    if LocalPlayer.Character then table.insert(exclude, LocalPlayer.Character) end
    local targetModel = targetPart:FindFirstAncestorOfClass("Model")
    if targetModel then table.insert(exclude, targetModel) end
    RayParams.FilterDescendantsInstances = exclude

    local origin    = cam.CFrame.Position
    local direction = targetPart.Position - origin

    local result = Workspace:Raycast(origin, direction, RayParams)
    if not result then return true end
    if targetModel and result.Instance:IsDescendantOf(targetModel) then return true end
    return false
end

local function MakeCands(registry)
    local list = {}
    for m in pairs(registry) do
        if m and m.Parent and IsAlive(m) then
            local p = m:FindFirstChild(S.AimbotPart) or m:FindFirstChild("Head") or GetRoot(m)
            if p then table.insert(list, {part=p}) end
        end
    end
    return list
end

local function PlCands()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and IsAlive(p.Character) then
            local pt = p.Character:FindFirstChild(S.AimbotPart)
                    or p.Character:FindFirstChild("Head")
                    or GetRoot(p.Character)
            if pt then table.insert(list, {part=pt}) end
        end
    end
    return list
end

local function FindBest(cands)
    local best, bd = nil, math.huge
    local mid = Mid()

    for _, c in ipairs(cands) do
        local p = c.part
        local model = p and p.Parent

        if p and p.Parent then
            local sp, on, dz = W2S(p.Position)
            if on and dz > 0 then
                local d = (sp - mid).Magnitude
                if d < S.AimbotFOV and d < bd then
                    if S.WallCheck and not HasLOS(p) then continue end
                    bd=d; best=p
                end
            end
        end
    end

    return best
end

local function SmoothAim(part)
    if not part or not part.Parent then return end
    local cam = GetCam(); if not cam then return end
    pcall(function()
        local dir  = (part.Position - cam.CFrame.Position).Unit
        local goal = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + dir)
        cam.CFrame = cam.CFrame:Lerp(goal, S.AimbotSmooth)
    end)
end

local frame      = 0
local prevAnK   = {}
local prevPlK   = {}

RunService.RenderStepped:Connect(function()
    frame=frame+1

    FovCircle.Position=Mid()
    FovCircle.Radius=S.AimbotFOV
    FovCircle.Visible=S.ShowFOV and (S.AnimalAimbot or S.PlayerAimbot)

    if AimHeld() then
        local anC=S.AnimalAimbot and MakeCands(Animals) or {}
        local plC=S.PlayerAimbot and PlCands()          or {}

        local targetPart

        if S.AimbotPriority=="Animal" then
            targetPart=FindBest(anC)
            if not targetPart then targetPart=FindBest(plC) end
        elseif S.AimbotPriority=="Player" then
            targetPart=FindBest(plC)
            if not targetPart then targetPart=FindBest(anC) end
        else
            local m={}
            for _,c in ipairs(anC) do m[#m+1]=c end
            for _,c in ipairs(plC) do m[#m+1]=c end
            targetPart=FindBest(m)
        end

        SmoothAim(targetPart)
    end

    if frame % math.max(S.ESPRate,1) ~=0 then return end

    local aC={boxes=S.ABoxes,corner=S.ACorner,names=S.ANames,dist=S.ADist,health=S.AHealth,tracer=S.ATracer,tsrc=S.ATSrc}
    local pC={boxes=S.PBoxes,corner=S.PCorner,names=S.PNames,dist=S.PDist,health=S.PHealth,tracer=S.PTracer,tsrc=S.PTSrc}

    local newAK={}
    for model in pairs(Animals) do
        if model and model.Parent then
            local hum=GetHum(model)
            if hum and hum.Health>0 then
                local id=GetModelId(model)
                local key="an"..id
                newAK[key]=true

                if S.AnimalESP then
                    NewEntry(key,S.AColor)
                    Render(key,model,hum,GetLabel(model),S.AColor,aC)
                else HideEntry(key) end

                if S.AnimalChams then GetHL("ch"..key,model,S.ACFill,S.ACOut)
                else                  HideHL("ch"..key) end

                if S.HitboxExtender and (S.HitboxTarget == "Animals" or S.HitboxTarget == "Both") then
                    ProcessHitboxExtender(model, true)
                else
                    HideHitboxHL(model)
                end
            end
        end
    end
    for k in pairs(prevAnK) do
        if not newAK[k] then KillEntry(k); KillHL("ch"..k) end
    end
    prevAnK=newAK

    local newPK={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local char=p.Character
            local key="pl"..tostring(p.UserId)
            newPK[key]=true

            if char and IsAlive(char) then
                if S.PlayerESP then
                    NewEntry(key,S.PColor)
                    local dn=(p.DisplayName~="" and p.DisplayName) or p.Name
                    Render(key,char,GetHum(char),dn,S.PColor,pC)
                else HideEntry(key) end

                if S.PlayerChams then GetHL("ch"..key,char,S.PCFill,S.PCOut)
                else                  HideHL("ch"..key) end

                if S.HitboxExtender and (S.HitboxTarget == "Players" or S.HitboxTarget == "Both") then
                    ProcessHitboxExtender(char, false)
                else
                    HideHitboxHL(char)
                end
            else
                HideEntry(key); HideHL("ch"..key)
                if char then
                    CleanupHitboxExtender(char)
                end
            end
        end
    end
    for k in pairs(prevPlK) do
        if not newPK[k] then KillEntry(k); KillHL("ch"..k) end
    end
    prevPlK=newPK
end)

Players.PlayerRemoving:Connect(function(p)
    local key="pl"..tostring(p.UserId)
    KillEntry(key); KillHL("ch"..key)
    prevPlK[key]=nil

    if p.Character then
        CleanupHitboxExtender(p.Character)
    end
end)

local Win = Library:Window({
    Title = "Foresto Hunting Game",
    Desc = "by atl4ntic",
    Icon = 105059922903197,
    Theme = "Dark",
    Config = { Keybind = Enum.KeyCode.RightControl, Size = UDim2.fromOffset(580, 450) },
    CloseUIButton = { Enabled = true, Text = "Menu" }
})

local TAim = Win:Tab({Title = "Aimbot", Icon = "target"})
TAim:Section({Title = "Targets"})
TAim:Toggle({Title="Animal Aimbot",Value=false,Callback=function(v)S.AnimalAimbot=v end})
TAim:Toggle({Title="Player Aimbot",Value=false,Callback=function(v)S.PlayerAimbot=v end})
TAim:Dropdown({Title="Priority",List={"Closest","Animal","Player"},Value="Closest",Callback=function(v)S.AimbotPriority=v end})
TAim:Section({Title = "Settings"})
TAim:Slider({Title="FOV Radius",Min=10,Max=600,Rounding=0,Value=S.AimbotFOV,Callback=function(v)S.AimbotFOV=v end})
TAim:Slider({Title="Smoothing (%)",Min=1,Max=100,Rounding=0,Value=math.floor(S.AimbotSmooth*100),Callback=function(v)S.AimbotSmooth=v/100 end})
TAim:Dropdown({Title="Target Part",List={"Head","HumanoidRootPart","UpperTorso","Torso"},Value="Head",Callback=function(v)S.AimbotPart=v end})
TAim:Dropdown({Title="Aim Key",List={"Right Click (RMB)","Left Click (LMB)","Q","E","LeftShift"},Value="Right Click (RMB)",Callback=function(v)
    local m={["Right Click (RMB)"]=Enum.UserInputType.MouseButton2,["Left Click (LMB)"]=Enum.UserInputType.MouseButton1,Q=Enum.KeyCode.Q,E=Enum.KeyCode.E,LeftShift=Enum.KeyCode.LeftShift}
    S.AimbotKey=m[v]or Enum.UserInputType.MouseButton2
end})
TAim:Toggle({Title="Show FOV Circle",Value=true,Callback=function(v)S.ShowFOV=v end})
TAim:Toggle({Title="Wall Check (LOS Only)",Value=false,Callback=function(v)S.WallCheck=v end})

local TEsp = Win:Tab({Title = "ESP", Icon = "eye"})

TEsp:Section({Title = "Animal ESP"})
TEsp:Toggle({Title="Animal ESP",Value=false,Callback=function(v)S.AnimalESP=v;if not v then for k in pairs(prevAnK)do HideEntry(k)end end end})
TEsp:Toggle({Title="Show Box",Value=true,Callback=function(v)S.ABoxes=v end})
TEsp:Toggle({Title="Corner Style",Value=false,Callback=function(v)S.ACorner=v end})
TEsp:Toggle({Title="Show Name",Value=true,Callback=function(v)S.ANames=v end})
TEsp:Toggle({Title="Show Distance",Value=true,Callback=function(v)S.ADist=v end})
TEsp:Toggle({Title="Show Health Bar",Value=true,Callback=function(v)S.AHealth=v end})
TEsp:Toggle({Title="Tracer Line",Value=false,Callback=function(v)S.ATracer=v end})
TEsp:Dropdown({Title="Animal Tracer Origin",List={"Bottom","Center"},Value="Bottom",Callback=function(v)S.ATSrc=v end})

TEsp:Section({Title = "Player ESP"})
TEsp:Toggle({Title="Player ESP",Value=false,Callback=function(v)S.PlayerESP=v;if not v then for k in pairs(prevPlK)do HideEntry(k)end end end})
TEsp:Toggle({Title="Show Box",Value=true,Callback=function(v)S.PBoxes=v end})
TEsp:Toggle({Title="Corner Style",Value=false,Callback=function(v)S.PCorner=v end})
TEsp:Toggle({Title="Show Name",Value=true,Callback=function(v)S.PNames=v end})
TEsp:Toggle({Title="Show Distance",Value=true,Callback=function(v)S.PDist=v end})
TEsp:Toggle({Title="Show Health Bar",Value=true,Callback=function(v)S.PHealth=v end})
TEsp:Toggle({Title="Tracer Line",Value=false,Callback=function(v)S.PTracer=v end})
TEsp:Dropdown({Title="Player Tracer Origin",List={"Bottom","Center"},Value="Bottom",Callback=function(v)S.PTSrc=v end})

TEsp:Section({Title = "Visuals"})

TEsp:Toggle({Title="No Fog",Value=false,Callback=function(v)
    local Lighting=game:GetService("Lighting")
    if v then pcall(function()
            Lighting.FogEnd=100000 Lighting.FogStart=99999
            for _,obj in ipairs(Lighting:GetChildren())do if obj:IsA("Atmosphere")then obj.Density=0 obj.Haze=0 obj.Glare=0 obj.Offset=0 end end
        end)
    else pcall(function()
            Lighting.FogEnd=100000 Lighting.FogStart=0
            for _,obj in ipairs(Lighting:GetChildren())do if obj:IsA("Atmosphere")then obj.Density=0.395 obj.Haze=0 obj.Glare=0 obj.Offset=0 end end
        end)end
end})

TEsp:Toggle({Title="Loop Fullbright",Value=false,Callback=function(v)
    if v then if _G.FBConn then _G.FBConn:Disconnect()end local Lighting=game:GetService("Lighting")
        _G.FBConn=game:GetService("RunService").RenderStepped:Connect(function()
            pcall(function()
                Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=100000 Lighting.FogStart=0 Lighting.GlobalShadows=false Lighting.Ambient=Color3.fromRGB(178,178,178) Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
                for _,obj in ipairs(Lighting:GetChildren())do if obj:IsA("Atmosphere")then obj.Density=0 obj.Haze=0 obj.Glare=0 elseif obj:IsA("BloomEffect")or obj:IsA("SunRaysEffect")or obj:IsA("ColorCorrectionEffect")or obj:IsA("DepthOfFieldEffect")then obj.Enabled=false end end
            end)
        end)
    else if _G.FBConn then _G.FBConn:Disconnect() _G.FBConn=nil end end
end})

local THitbox = Win:Tab({Title = "Hitbox", Icon = "plus"})
THitbox:Section({Title = "Hitbox Extender"})
THitbox:Toggle({
    Title="Enable Hitbox Extender",
    Value=false,
    Callback=function(v)
        S.HitboxExtender=v
        if not v then
            ClearAllHitboxVisuals()
            Win:Notify({Title="Hitbox Disabled",Desc="All hitbox visuals removed and sizes restored.",Time=3})
        else
            Win:Notify({Title="Hitbox Enabled",Desc="Hitboxes will be enlarged for easier shooting.",Time=3})
        end
    end
})

THitbox:Dropdown({
    Title="Target Type",
    List={"Both","Animals","Players"},
    Value="Both",
    Callback=function(v)
        S.HitboxTarget=v
        ClearAllHitboxVisuals()
        Win:Notify({Title="Target Type Changed",Desc="Hitbox target set to: " .. S.HitboxTarget,Time=3})
    end
})

THitbox:ColorPicker({
    Title="Hitbox Visual Color",
    Value=S.HitboxColor,
    Callback=function(r, g, b)
        S.HitboxColor = Color3.fromRGB(r, g, b)
        for model, hl in pairs(HitboxHighlights) do
            if hl and hl.Parent then
                pcall(function()
                    hl.FillColor = S.HitboxColor
                end)
            end
        end
    end
})

THitbox:Slider({
    Title="Hitbox Size Multiplier",
    Min=1,
    Max=5,
    Rounding=1,
    Value=S.HitboxSize,
    Callback=function(v)
        S.HitboxSize=v
        for part, originalSize in pairs(OriginalSizes) do
            if part and part.Parent then
                pcall(function()
                    part.Size = originalSize * v
                end)
            end
        end
        Win:Notify({Title="Hitbox Size Updated",Desc="Hitbox size set to " .. v .. "x",Time=3})
    end
})

THitbox:Slider({
    Title="Visual Transparency (%)",
    Min=0,
    Max=100,
    Rounding=0,
    Value=math.floor(S.HitboxTransparency*100),
    Callback=function(v)
        S.HitboxTransparency=v/100
        for model, hl in pairs(HitboxHighlights) do
            if hl and hl.Parent then
                pcall(function()
                    hl.FillTransparency = S.HitboxTransparency
                end)
            end
        end
    end
})

THitbox:Section({Title = "Enlarges Head and RootPart for easier hitting"})
THitbox:Section({Title = "Highlight covers entire model"})
THitbox:Section({Title = "Set transparency to 0 for solid, 100 for invisible"})

local TCh = Win:Tab({Title = "Chams", Icon = "star"})
TCh:Section({Title = "Animal Chams"})
TCh:Toggle({Title="Animal Chams",Value=false,Callback=function(v)S.AnimalChams=v;if not v then for k in pairs(prevAnK)do HideHL("ch"..k)end end end})
TCh:Section({Title = "Player Chams"})
TCh:Toggle({Title="Player Chams",Value=false,Callback=function(v)S.PlayerChams=v;if not v then for k in pairs(prevPlK)do HideHL("ch"..k)end end end})
TCh:Section({Title = "Settings"})
TCh:Slider({Title="Fill Transparency (%)",Min=0,Max=100,Rounding=0,Value=math.floor(S.CFillTrans*100),
    Callback=function(v)S.CFillTrans=v/100;for _,hl in pairs(Hlights)do pcall(function()hl.FillTransparency=S.CFillTrans end)end end})
TCh:Slider({Title="Outline Transparency (%)",Min=0,Max=100,Rounding=0,Value=math.floor(S.COutTrans*100),
    Callback=function(v)S.COutTrans=v/100;for _,hl in pairs(Hlights)do pcall(function()hl.OutlineTransparency=S.COutTrans end)end end})
TCh:Dropdown({Title="Depth Mode",List={"AlwaysOnTop","Occluded"},Value="AlwaysOnTop",
    Callback=function(v)
        S.CDepth=v
        local dm=Enum.HighlightDepthMode[S.CDepth]or Enum.HighlightDepthMode.AlwaysOnTop for _,hl in pairs(Hlights)do pcall(function()hl.DepthMode=dm end)end
    end})
TCh:Section({Title = "AlwaysOnTop=visible thru walls. Fill 100=outline only"})

local TTp = Win:Tab({Title = "Teleport", Icon = "zap"})

local function TeleportTo(pos)
    local char=LocalPlayer.Character if not char then return end local root=char:FindFirstChild("HumanoidRootPart")if not root then return end pcall(function()root.CFrame=CFrame.new(pos+Vector3.new(0,3,0))end)
end

TTp:Section({Title = "Teleport to NPC"})
TTp:Button({Title="Refresh NPC List",Callback=function()
    _G.ForestoNPCList={} for _,d in ipairs(Workspace:GetDescendants())do if d:IsA("Model")and not PlayerChars[d]and not Animals[d]then local hum=GetHum(d)local root=GetRoot(d)if hum and root then table.insert(_G.ForestoNPCList,d)end end end local count=#(_G.ForestoNPCList or{})
    Win:Notify({Title="NPC List Refreshed",Desc=count.." NPCs found.",Time=3})
end})

TTp:Button({Title="Teleport to Nearest NPC",Callback=function()
    local char=LocalPlayer.Character local myRoot=char and GetRoot(char)if not myRoot then return end local bestModel,bestDist=nil,math.huge for _,d in ipairs(Workspace:GetDescendants())do if d:IsA("Model")and not PlayerChars[d]and not Animals[d]then local hum=GetHum(d)local root=GetRoot(d)if hum and root then local dist=(myRoot.Position-root.Position).Magnitude if dist<bestDist then bestDist=dist bestModel=root end end end end if bestModel then TeleportTo(bestModel.Position)Win:Notify({Title="Teleported",Desc="Teleported to nearest NPC.",Time=3})else Win:Notify({Title="No NPC Found",Desc="No NPCs detected nearby.",Time=3})end
end})

TTp:Button({Title="Teleport to Nearest Animal",Callback=function()
    local char=LocalPlayer.Character local myRoot=char and GetRoot(char)if not myRoot then return end local bestPart,bestDist=nil,math.huge for model in pairs(Animals)do if model and model.Parent then local root=GetRoot(model)if root then local dist=(myRoot.Position-root.Position).Magnitude if dist<bestDist then bestDist=dist bestPart=root end end end end if bestPart then TeleportTo(bestPart.Position)Win:Notify({Title="Teleported",Desc="Teleported to nearest animal.",Time=3})else Win:Notify({Title="No Animal Found",Desc="No animals detected.",Time=3})end
end})

TTp:Button({Title="Teleport to Nearest Player",Callback=function()
    local char=LocalPlayer.Character local myRoot=char and GetRoot(char)if not myRoot then return end local bestPos,bestDist,bestName=nil,math.huge,""for _,p in ipairs(Players:GetPlayers())do if p~=LocalPlayer and p.Character then local root=GetRoot(p.Character)if root then local dist=(myRoot.Position-root.Position).Magnitude if dist<bestDist then bestDist=dist bestPos=root.Position bestName=p.Name end end end end if bestPos then TeleportTo(bestPos)Win:Notify({Title="Teleported",Desc="Teleported to "..bestName,Time=3})else Win:Notify({Title="No Player Found",Desc="No other players found.",Time=3})end
end})

TTp:Section({Title = "Teleport to Places"})
local PLACES={
    {name="Spawn",pos=Vector3.new(0,5,0)},
    {name="Miner's Camp",pos=Vector3.new(-701,39,-177)},
    {name="Scorpion Nest",pos=Vector3.new(-2326,47,-313)},
    {name="Desert",pos=Vector3.new(-1554,42,411)},
    {name="Snow Biome",pos=Vector3.new(1805,39,-760)},
    {name="Cave",pos=Vector3.new(-1068,3,609)},
    {name="Swamp",pos=Vector3.new(856,8,737)},
    {name="Sunken Cave",pos=Vector3.new(-1732,-40,856)},
    {name="Birch Land",pos=Vector3.new(403,3,-1439)},
    {name="Forest Camp",pos=Vector3.new(-51,4,22)},
    {name="The Void Orb",pos=Vector3.new(2138,45,-1769)},
    {name="King's Crown",pos=Vector3.new(-1136,3,-1991)},
}
for _,place in ipairs(PLACES)do local p=place TTp:Button({Title="→ "..p.name,Callback=function()TeleportTo(p.pos)Win:Notify({Title="Teleported",Desc="Moved to "..p.name,Time=3})end})end

local function grabKnife()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    for _, v in ipairs(char:GetChildren()) do
        local skinRem = v:FindFirstChild("Scripts") and v.Scripts:FindFirstChild("System") and v.Scripts.System:FindFirstChild("Skin")
        local hitRem = v:FindFirstChild("Scripts") and v.Scripts:FindFirstChild("System") and v.Scripts.System:FindFirstChild("Hit")
        if skinRem and hitRem then
            return skinRem, hitRem
        end
    end
    return nil, nil
end

local function grabGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        local hit = v:FindFirstChild("Scripts") and v.Scripts:FindFirstChild("System") and v.Scripts.System:FindFirstChild("Hit")
        if hit then return hit end
    end
    return nil
end

local function grabBullet()
    local b = nil
    pcall(function() b = ReplicatedStorage.Stuff.Bullets.NormalBullet end)
    return b
end

local function grabTorso(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

local function shootFucker(target)
    local hitRem = grabGun()
    if not hitRem then return end
    local bullet = grabBullet()
    if not bullet then return end
    local torso = grabTorso(target)
    if not torso then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local startPos = myRoot.Position
    local hitPos = torso.Position
    local dir = (hitPos - startPos).Unit
    local hum = target:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hitRem:FireServer({
            DistanceMade = vector.create(hitPos.X - startPos.X, hitPos.Y - startPos.Y, hitPos.Z - startPos.Z),
            StartPosition = vector.create(startPos.X, startPos.Y, startPos.Z),
            HitMaterial = Enum.Material.Plastic,
            Ray = nil,
            ShootDirection = vector.create(dir.X, dir.Y, dir.Z),
            HitPos = vector.create(hitPos.X, hitPos.Y, hitPos.Z),
            RayHit = torso,
            HitPart = hum,
            Bullet = bullet,
        })
    end)
end

local function getAliveAnimals()
    local list = {}
    local folder = nil
    pcall(function() folder = Workspace.Living.Animals end)
    if not folder then return list end
    for _, a in ipairs(folder:GetChildren()) do
        local hum = a:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            table.insert(list, a)
        end
    end
    return list
end

local function getAlivePlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(list, plr.Character)
            end
        end
    end
    return list
end

local TFarm = Win:Tab({Title = "Automation", Icon = "sword"})

TFarm:Section({Title = "Looting"})
local PickConn = nil
TFarm:Toggle({Title="Auto Pickup",Value=false,Callback=function(state)
    if state then
        PickConn = RunService.Heartbeat:Connect(function()
            local rem = nil
            pcall(function() rem = ReplicatedStorage.Events.Player.PickUp end)
            if not rem then return end
            local ground = Workspace:FindFirstChild("ItemsOnTheGround")
            if not ground then return end
            for _, item in ipairs(ground:GetChildren()) do
                pcall(function() rem:FireServer(item) end)
            end
        end)
    else
        if PickConn then PickConn:Disconnect() PickConn = nil end
    end
end})

-- local SellConn = nil
-- local SellTick = 0
-- TFarm:Toggle({Title="Auto Sell",Value=false,Callback=function(state)
--     if state then
--         SellTick = 0
--         SellConn = RunService.Heartbeat:Connect(function(dt)
--             SellTick = SellTick + dt
--             if SellTick < 1 then return end
--             SellTick = 0
--             local rem = nil
--             pcall(function() rem = ReplicatedStorage.Events.Player.Sell end)
--             if not rem then return end
--             local inv = LocalPlayer:FindFirstChild("Inventory")
--             if not inv then return end
--             local items = inv:GetChildren()
--             if #items == 0 then return end
--             local batch = {}
--             for i = 1, math.min(50, #items) do
--                 table.insert(batch, items[i])
--             end
--             pcall(function() rem:InvokeServer(batch) end)
--         end)
--     else
--         if SellConn then SellConn:Disconnect() SellConn = nil end
--     end
-- end})

TFarm:Section({Title = "Combat"})
S.KillRange = 200
TFarm:Slider({Title="Kill Range",Min=50,Max=5000,Rounding=0,Value=S.KillRange,Callback=function(v)S.KillRange=v end})

S.KillTarget = "Animals"
TFarm:Dropdown({Title="Kill Target",List={"Animals","Players","All"},Value=S.KillTarget,Callback=function(v)S.KillTarget=v end})

local KillConn = nil
TFarm:Toggle({Title="Kill Aura",Value=false,Callback=function(state)
    if state then
        KillConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local targets = {}
            if S.KillTarget == "Animals" or S.KillTarget == "All" then
                for _, t in ipairs(getAliveAnimals()) do table.insert(targets, t) end
            end
            if S.KillTarget == "Players" or S.KillTarget == "All" then
                for _, t in ipairs(getAlivePlayers()) do table.insert(targets, t) end
            end
            for _, target in ipairs(targets) do
                local torso = grabTorso(target)
                if torso and (root.Position - torso.Position).Magnitude <= S.KillRange then
                    shootFucker(target)
                end
            end
        end)
    else
        if KillConn then KillConn:Disconnect() KillConn = nil end
    end
end})

local ProcRunning = false
TFarm:Toggle({Title="Auto Process Corpse",Value=false,Callback=function(state)
    ProcRunning = state
    if not state then return end
    task.spawn(function()
        while ProcRunning do
            local skinRem, knifeRem = grabKnife()
            if skinRem and knifeRem then
                local folder = nil
                pcall(function() folder = Workspace.Living.Animals end)
                if folder then
                    for _, animal in ipairs(folder:GetChildren()) do
                        local hum = animal:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then
                            local mdlFolder = animal:FindFirstChild("Model")
                            local mdlPart = mdlFolder and mdlFolder:FindFirstChildWhichIsA("BasePart")
                            if mdlPart then
                                for _ = 1, 10 do
                                    pcall(function() skinRem:FireServer(animal, mdlPart, mdlPart.CFrame) end)
                                end
                            end

                            for _, child in ipairs(animal:GetChildren()) do
                                if child.Name:sub(1, 5) == "Limb_" then
                                    local lp = child:FindFirstChildWhichIsA("BasePart") or child
                                    for _ = 1, 10 do
                                        pcall(function() knifeRem:FireServer(child, "LightAttack1", lp.CFrame) end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end})

local TMisc = Win:Tab({Title = "Misc", Icon = "tag"})
TMisc:Section({Title = "Distance & Rate"})  
TMisc:Slider({Title="Max ESP Distance (m)",Min=100,Max=5000,Rounding=0,Value=S.MaxDist,Callback=function(v)S.MaxDist=v end})
TMisc:Slider({Title="Update Every N Frames",Min=1,Max=8,Rounding=0,Value=S.ESPRate,Callback=function(v)S.ESPRate=v end})
TMisc:Section({Title = "Actions"})
TMisc:Button({Title="Re-Scan Animals",Callback=function()
    Animals={};ModelId={}for _,d in ipairs(Workspace:GetDescendants())do if d:IsA("Model")and not PlayerChars[d]then local isA,_=LookupAnimal(d.Name)if isA and GetHum(d)and GetRoot(d)then Animals[d]=true else RegisterModel(d)end end end task.delay(0.5,function()local na=0 for _ in pairs(Animals)do na=na+1 end Win:Notify({Title="Re-Scanned",Desc=na.." animals found.",Time=4})end)
end})
TMisc:Button({Title="Clear All ESP",Callback=function()
    ClearEntries();prevAnK={};prevPlK={}Win:Notify({Title="ESP Cleared",Desc="All drawings removed.",Time=3})
end})
TMisc:Button({Title="Clear All Chams",Callback=function()
    for k in pairs(Hlights)do KillHL(k)end Win:Notify({Title="Chams Cleared",Desc="All highlights removed.",Time=3})
end})
TMisc:Button({Title="Clear All Hitboxes",Callback=function()
    ClearAllHitboxVisuals()
    Win:Notify({Title="Hitboxes Cleared",Desc="All hitbox visuals removed and sizes restored.",Time=3})
end})
TMisc:Button({Title="Disable Everything",Callback=function()
    S.AnimalAimbot=false;S.PlayerAimbot=false S.AnimalESP=false;S.PlayerESP=false S.AnimalChams=false;S.PlayerChams=false S.HitboxExtender=false FovCircle.Visible=false for k in pairs(Entries)do HideEntry(k)end for _,hl in pairs(Hlights)do pcall(function()hl.Enabled=false end)end ClearAllHitboxVisuals() Win:Notify({Title="All Off",Desc="Everything disabled.",Time=3})
end})
