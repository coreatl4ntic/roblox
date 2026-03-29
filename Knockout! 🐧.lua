local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local LocalPlayer = Players.LocalPlayer

local platformEnabled = false
local freezeEnabled = false
local platformPart = nil
local freezeBox = nil
local platformConnection = nil
local freezeConnection = nil
local freezePosition = nil
local frozenBodyPos = nil
local frozenBodyGyro = nil
local characterCheckConnection = nil

local function getCharacterRoot()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            return char, hrp, hum
        end
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
                or obj:FindFirstChild("Torso")
                or obj:FindFirstChild("UpperTorso")
                or obj:FindFirstChild("Root")
                or obj:FindFirstChild("RootPart")
                or obj.PrimaryPart

            if hum and hrp then

                local isOurs = false

                if obj.Name == LocalPlayer.Name then
                    isOurs = true
                end

                if not isOurs then
                    local cam = workspace.CurrentCamera
                    if cam and cam.CameraSubject then
                        if cam.CameraSubject == hum or cam.CameraSubject:IsDescendantOf(obj) then
                            isOurs = true
                        end
                    end
                end

                if not isOurs and LocalPlayer.Character == obj then
                    isOurs = true
                end

                if isOurs then
                    return obj, hrp, hum
                end
            end
        end
    end

    local cam = workspace.CurrentCamera
    if cam and cam.CameraSubject then
        local subject = cam.CameraSubject
        local model = nil

        if subject:IsA("Humanoid") then
            model = subject.Parent
        elseif subject:IsA("BasePart") then
            model = subject.Parent
        end

        if model and model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local hrp = model:FindFirstChild("HumanoidRootPart")
                or model:FindFirstChild("Torso")
                or model:FindFirstChild("UpperTorso")
                or model:FindFirstChild("Root")
                or model:FindFirstChild("RootPart")
                or model.PrimaryPart

            if hum and not hrp then
                for _, child in pairs(model:GetChildren()) do
                    if child:IsA("BasePart") then
                        hrp = child
                        break
                    end
                end
            end

            if hum and hrp then
                return model, hrp, hum
            end
        end
    end

    return nil, nil, nil
end

local function getAllCharacterParts(characterModel)
    local parts = {}
    if not characterModel then return parts end
    for _, obj in pairs(characterModel:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj)
        end
    end
    return parts
end

local function setCollisionForPart(part, characterModel)
    if not part then return end

    part.CanCollide = true
    
    pcall(function()
        
        PhysicsService:RegisterCollisionGroup("ScriptPlatform")
        PhysicsService:RegisterCollisionGroup("OtherPlayers")
    end)

    pcall(function()
        
        PhysicsService:CollisionGroupSetCollidable("ScriptPlatform", "OtherPlayers", false)
        PhysicsService:CollisionGroupSetCollidable("ScriptPlatform", "Default", false)
        PhysicsService:CollisionGroupSetCollidable("ScriptPlatform", "ScriptPlatform", false)
    end)

    pcall(function()
        part.CollisionGroup = "ScriptPlatform"
    end)
end


local function setupCharacterCollision(characterModel)
    if not characterModel then return end

    pcall(function()
        PhysicsService:RegisterCollisionGroup("MyCharacter")
    end)

    pcall(function()
        PhysicsService:CollisionGroupSetCollidable("ScriptPlatform", "MyCharacter", true)
    end)

    local parts = getAllCharacterParts(characterModel)
    for _, part in pairs(parts) do
        pcall(function()
            part.CollisionGroup = "MyCharacter"
        end)
    end

    
    characterModel.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            pcall(function()
                desc.CollisionGroup = "MyCharacter"
            end)
        end
    end)
end

local function setupOtherPlayersCollision()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            for _, part in pairs(getAllCharacterParts(player.Character)) do
                pcall(function()
                    part.CollisionGroup = "OtherPlayers"
                end)
            end
        end
    end
end

local function createPlatform()
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end

    local charModel, hrp, hum = getCharacterRoot()
    if not hrp or not hum then return end

    platformPart = Instance.new("Part")
    platformPart.Name = "AntiFullPlatform_KO"
    platformPart.Size = Vector3.new(8, 1.2, 8) 
    platformPart.Color = Color3.fromRGB(200, 0, 0)
    platformPart.Material = Enum.Material.Neon
    platformPart.Transparency = 0.3
    platformPart.Anchored = true
    platformPart.CanCollide = true
    platformPart.Parent = workspace

    setupCharacterCollision(charModel)
    setCollisionForPart(platformPart, charModel)
    setupOtherPlayersCollision()

    local rootPos = hrp.Position
    local hipHeight = hum.HipHeight or 2
    local rootPartYSize = hrp.Size.Y
    local legOffset = hipHeight + (rootPartYSize / 2) + (platformPart.Size.Y / 2)
    platformPart.Position = Vector3.new(rootPos.X, rootPos.Y - legOffset, rootPos.Z)
end

local function startPlatformTracking()
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end

    local lastGroundY = nil
    local initialized = false

    platformConnection = RunService.Heartbeat:Connect(function()
        if not platformEnabled then return end
        if not platformPart or not platformPart.Parent then

            createPlatform()
            if not platformPart then return end
        end

        local charModel, hrp, hum = getCharacterRoot()
        if not hrp or not hum then return end

        pcall(function()
            setupCharacterCollision(charModel)
        end)

        local rootPos = hrp.Position
        local hipHeight = hum.HipHeight or 2
        local rootPartYSize = hrp.Size.Y
        local legOffset = hipHeight + (rootPartYSize / 2) + (platformPart.Size.Y / 2)
        local currentPlatY = rootPos.Y - legOffset

        local state = hum:GetState()
        local isOnGround = (
            state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
            or state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.None
            or state == Enum.HumanoidStateType.Seated
        )

        
        if not isOnGround then
            local rayResult = workspace:Raycast(
                hrp.Position,
                Vector3.new(0, -(legOffset + 1), 0),
                RaycastParams.new()
            )
            if rayResult then
                isOnGround = true
            end
        end

        if not initialized then
            lastGroundY = currentPlatY
            initialized = true
        end

        if isOnGround then
            lastGroundY = currentPlatY
        end

        if currentPlatY < lastGroundY - 0.5 then
            lastGroundY = currentPlatY
        end

        local finalY = lastGroundY

        platformPart.Position = Vector3.new(rootPos.X, finalY, rootPos.Z)
        platformPart.CanCollide = true

        
        local charBottom = rootPos.Y - legOffset
        local platTop = platformPart.Position.Y + (platformPart.Size.Y / 2)

        if charBottom < platTop and charBottom > platTop - 3 then
            
            local newY = platTop + legOffset + 0.1
            hrp.CFrame = CFrame.new(rootPos.X, newY, rootPos.Z) *
                (hrp.CFrame - hrp.CFrame.Position)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    math.max(0, hrp.AssemblyLinearVelocity.Y),
                    hrp.AssemblyLinearVelocity.Z
                )
            end)
        end
    end)
end

local function stopPlatform()
    if platformConnection then
        platformConnection:Disconnect()
        platformConnection = nil
    end
    if platformPart then
        platformPart:Destroy()
        platformPart = nil
    end
end


local function createFreezeBox()
    if freezeBox then
        freezeBox:Destroy()
        freezeBox = nil
    end

    local charModel = getCharacterRoot()

    freezeBox = Instance.new("Model")
    freezeBox.Name = "FreezeBox_KO"
    freezeBox.Parent = workspace

    local boxSize = 8
    local wallThickness = 1.0 
    local boxTransparency = 0.6
    local boxColor = Color3.fromRGB(0, 150, 255)

    local walls = {
        
        {Vector3.new(boxSize, wallThickness * 2, boxSize), CFrame.new(0, -boxSize / 2, 0)},
        
        {Vector3.new(boxSize, wallThickness, boxSize), CFrame.new(0, boxSize / 2, 0)},
        
        {Vector3.new(boxSize, boxSize, wallThickness), CFrame.new(0, 0, boxSize / 2)},
        
        {Vector3.new(boxSize, boxSize, wallThickness), CFrame.new(0, 0, -boxSize / 2)},
        
        {Vector3.new(wallThickness, boxSize, boxSize), CFrame.new(-boxSize / 2, 0, 0)},
       
        {Vector3.new(wallThickness, boxSize, boxSize), CFrame.new(boxSize / 2, 0, 0)},
    }

    for i, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = "FreezeWall_" .. i
        wall.Size = wallData[1]
        wall.Anchored = true
        wall.CanCollide = true
        wall.Transparency = boxTransparency
        wall.Color = boxColor
        wall.Material = Enum.Material.ForceField
        wall.CFrame = CFrame.new(freezePosition) * wallData[2]

        setupCharacterCollision(charModel)
        setCollisionForPart(wall, charModel)

        wall.Parent = freezeBox
    end

    setupOtherPlayersCollision()
end

local function updateFreezeBoxPosition()
    if not freezeBox or not freezeBox.Parent then return end
    if not freezePosition then return end

    local boxSize = 8
    local wallThickness = 1.0

    local offsets = {
        CFrame.new(0, -boxSize / 2, 0),
        CFrame.new(0, boxSize / 2, 0),
        CFrame.new(0, 0, boxSize / 2),
        CFrame.new(0, 0, -boxSize / 2),
        CFrame.new(-boxSize / 2, 0, 0),
        CFrame.new(boxSize / 2, 0, 0),
    }

    local walls = freezeBox:GetChildren()
    for i, wall in ipairs(walls) do
        if offsets[i] then
            wall.CFrame = CFrame.new(freezePosition) * offsets[i]
            wall.CanCollide = true
        end
    end
end

local function removeAllConstraints(hrp)
    if not hrp then return end
    for _, child in pairs(hrp:GetChildren()) do
        if child:IsA("BodyPosition") or child:IsA("BodyGyro")
            or child:IsA("BodyVelocity") or child:IsA("BodyForce")
            or child:IsA("BodyThrust") or child:IsA("BodyAngularVelocity") then
            if child.Name == "FreezeBodyPos" or child.Name == "FreezeBodyGyro" then

            else

            end
        end
    end
end

local function applyFreezeConstraints()
    local charModel, hrp, hum = getCharacterRoot()
    if not hrp or not hum then return end

    if frozenBodyPos then
        pcall(function() frozenBodyPos:Destroy() end)
        frozenBodyPos = nil
    end
    if frozenBodyGyro then
        pcall(function() frozenBodyGyro:Destroy() end)
        frozenBodyGyro = nil
    end

    for _, child in pairs(hrp:GetChildren()) do
        if child:IsA("BodyPosition") or child:IsA("BodyGyro")
            or child:IsA("BodyVelocity") or child:IsA("BodyForce")
            or child:IsA("BodyThrust") or child:IsA("BodyAngularVelocity")
            or child:IsA("LinearVelocity") or child:IsA("AlignPosition")
            or child:IsA("AlignOrientation") or child:IsA("VectorForce") then
            if child.Name ~= "FreezeBodyPos" and child.Name ~= "FreezeBodyGyro" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    for _, part in pairs(getAllCharacterParts(charModel)) do
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("BodyPosition") or child:IsA("BodyVelocity")
                or child:IsA("BodyForce") or child:IsA("LinearVelocity")
                or child:IsA("AlignPosition") or child:IsA("VectorForce") then
                if child.Name ~= "FreezeBodyPos" and child.Name ~= "FreezeBodyGyro" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end

    -- BodyPosition — супер сильный
    frozenBodyPos = Instance.new("BodyPosition")
    frozenBodyPos.Name = "FreezeBodyPos"
    frozenBodyPos.Position = freezePosition
    frozenBodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    frozenBodyPos.P = 1000000
    frozenBodyPos.D = 100000
    frozenBodyPos.Parent = hrp

    -- BodyGyro — предотвращает вращение
    frozenBodyGyro = Instance.new("BodyGyro")
    frozenBodyGyro.Name = "FreezeBodyGyro"
    frozenBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    frozenBodyGyro.P = 1000000
    frozenBodyGyro.D = 100000
    frozenBodyGyro.CFrame = CFrame.new(freezePosition)
    frozenBodyGyro.Parent = hrp

    -- Anchored для максимальной надёжности
    hrp.Anchored = true

    -- Блокируем движение
    pcall(function()
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.JumpHeight = 0
        hum.PlatformStand = true
    end)

    -- Устанавливаем коллизию
    setupCharacterCollision(charModel)
end

local function startFreezeTracking()
    if freezeConnection then
        freezeConnection:Disconnect()
        freezeConnection = nil
    end

    applyFreezeConstraints()

    local tickCounter = 0
    local lastCharModel = nil

    freezeConnection = RunService.Heartbeat:Connect(function()
        if not freezeEnabled then return end

        local charModel, hrp, hum = getCharacterRoot()
        if not hrp or not hum then return end

        tickCounter = tickCounter + 1

        if charModel ~= lastCharModel then
            lastCharModel = charModel
            freezePosition = freezePosition or hrp.Position
            applyFreezeConstraints()
            createFreezeBox()
        end

        hrp.Anchored = true
        hrp.CFrame = CFrame.new(freezePosition) * (hrp.CFrame - hrp.CFrame.Position)

        pcall(function()
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)

        for _, part in pairs(getAllCharacterParts(charModel)) do
            pcall(function()
                part.Velocity = Vector3.zero
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end)
        end

        if tickCounter % 15 == 0 then
            if not frozenBodyPos or not frozenBodyPos.Parent then
                applyFreezeConstraints()
            end

            for _, child in pairs(hrp:GetChildren()) do
                if (child:IsA("BodyPosition") or child:IsA("BodyVelocity")
                    or child:IsA("BodyForce") or child:IsA("LinearVelocity")
                    or child:IsA("AlignPosition") or child:IsA("VectorForce"))
                    and child.Name ~= "FreezeBodyPos" and child.Name ~= "FreezeBodyGyro" then
                    pcall(function() child:Destroy() end)
                end
            end

            pcall(function()
                hum.WalkSpeed = 0
                hum.JumpPower = 0
                hum.JumpHeight = 0
                hum.PlatformStand = true
            end)

            setupOtherPlayersCollision()
        end

        updateFreezeBoxPosition()
    end)

    if frozenBodyPos then
        frozenBodyPos.AncestryChanged:Connect(function()
            if freezeEnabled then
                task.wait()
                applyFreezeConstraints()
            end
        end)
    end
end

local function stopFreeze()
    if freezeConnection then
        freezeConnection:Disconnect()
        freezeConnection = nil
    end

    if frozenBodyPos then
        pcall(function() frozenBodyPos:Destroy() end)
        frozenBodyPos = nil
    end

    if frozenBodyGyro then
        pcall(function() frozenBodyGyro:Destroy() end)
        frozenBodyGyro = nil
    end

    if freezeBox then
        pcall(function() freezeBox:Destroy() end)
        freezeBox = nil
    end

    local charModel, hrp, hum = getCharacterRoot()

    if hum then
        pcall(function()
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
            hum.PlatformStand = false
        end)
    end

    if hrp then
        pcall(function()
            hrp.Anchored = false
        end)
    end

    freezePosition = nil
end

local function startCharacterWatcher()
    if characterCheckConnection then
        characterCheckConnection:Disconnect()
    end

    local lastKnownChar = nil

    characterCheckConnection = RunService.Heartbeat:Connect(function()
        local charModel, hrp, hum = getCharacterRoot()

        if charModel and charModel ~= lastKnownChar then
            lastKnownChar = charModel

            task.wait(0.3)

            if platformEnabled then
                stopPlatform()
                task.wait(0.1)
                createPlatform()
                startPlatformTracking()
            end

            if freezeEnabled then
                if not freezePosition then
                    local _, newHrp = getCharacterRoot()
                    if newHrp then
                        freezePosition = newHrp.Position
                    end
                end
                applyFreezeConstraints()
                createFreezeBox()
                if not freezeConnection then
                    startFreezeTracking()
                end
            end
        end
    end)
end

startCharacterWatcher()

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    if platformEnabled then
        stopPlatform()
        task.wait(0.1)
        createPlatform()
        startPlatformTracking()
    end

    if freezeEnabled then
        local _, hrp = getCharacterRoot()
        if hrp then
            freezePosition = freezePosition or hrp.Position
        end
        applyFreezeConstraints()
        createFreezeBox()
        if not freezeConnection then
            startFreezeTracking()
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        setupOtherPlayersCollision()
    end)
end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/coreatl4ntic/library/refs/heads/main/framework.lua"))()

local Window = Library:Window({
    Title = "Knockout Anti-Fall",
    Desc = "by atl4ntic",
    Icon = "box",
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightControl,
        Size = UDim2.new(0, 520, 0, 420)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Menu"
    }
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "home" }),
}

Tabs.Main:Section({ Title = "Knockout Utilities" })

Tabs.Main:Toggle({
    Title = "Platform",
    Desc = "สร้างแพลตฟอร์มสีแดงหนาใต้ตัวคุณ",
    Value = false,
    Callback = function(value)
        platformEnabled = value

        if value then
            local charModel, hrp, hum = getCharacterRoot()
            if hrp and hum then
                createPlatform()
                startPlatformTracking()
                Window:Notify({
                    Title = "Platform",
                    Desc = "แพลตฟอร์มสีแดงทำงานแล้ว! ใช้ได้แม้แต่ตอนเป็นเพนกวิน",
                    Time = 3,
                })
            else
                Window:Notify({
                    Title = "Platform",
                    Desc = "ไม่พบอักขระใดๆ ระบบจะทำงานเมื่อตรวจพบ",
                    Time = 3,
                })
            end
        else
            stopPlatform()
            Window:Notify({
                Title = "Platform",
                Desc = "ยกเลิกการทำงานของแพลตฟอร์ม",
                Time = 3,
            })
        end
    end,
})

Tabs.Main:Toggle({
    Title = "Freeze",
    Desc = "แช่แข็งคุณอย่างสมบูรณ์",
    Value = false,
    Callback = function(value)
        freezeEnabled = value

        if value then
            local charModel, hrp, hum = getCharacterRoot()
            if hrp and hum then
                freezePosition = hrp.Position
                createFreezeBox()
                startFreezeTracking()
                Window:Notify({
                    Title = "Freeze",
                    Desc = "แช่แข็ง! แม้แต่เพนกวินก็หนีไม่พ้น",
                    Time = 3,
                })
            else
                Window:Notify({
                    Title = "Freeze",
                    Desc = "ไม่พบอักขระใดๆ ระบบจะทำงานเมื่อตรวจพบ",
                    Time = 3,
                })
            end
        else
            stopFreeze()
            Window:Notify({
                Title = "Freeze",
                Desc = "ยกเลิกการแช่แข็ง คุณสามารถเคลื่อนไหวได้อีกครั้ง",
                Time = 3,
            })
        end
    end,
})

Tabs.Main:Section({ Title = "Information" })

Tabs.Main:Label({
    Title = "How to use",
    Desc = "แพลตฟอร์ม: สร้างแพลตฟอร์มสีแดงหนาใต้ตัวคุณ ใช้ได้เฉพาะเมื่อคุณเป็นเพนกวิน! มีเพียงคุณเท่านั้นที่จะชนกับมัน ผู้เล่นคนอื่นจะเดินผ่านไปได้\n\nแช่แข็ง: แช่แข็งคุณอย่างสมบูรณ์ (แม้จะเป็นเพนกวิน) สร้างกล่องน้ำแข็งรอบตัวคุณ ป้องกันการเทเลพอร์ต ป้องกันการผลัก ป้องกันทุกอย่าง เกมไม่สามารถปลดล็อกคุณได้\n\n🐧 ตรวจจับการแปลงร่างเป็นเพนกวินโดยอัตโนมัติ!"
})
