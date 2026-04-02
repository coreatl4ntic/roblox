local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local cam: Camera = workspace.CurrentCamera
local lp: Player = Players.LocalPlayer
local mob: boolean = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local TK = {
	esp = if mob then 1.8 else 1.0,
	obj = if mob then 2.5 else 1.5,
	prompt = 0.3, energy = 0.4,
	nostun = 0.15, god = 0.1,
	safe = 1.0, trap = 1.5,
}
local MAXD = if mob then 160 else 280

local S = {
	espPlayer=false, espGen=false, espBat=false,
	espTrap=false, espExit=false, killerAlert=false,
	instantPrompt=false, noStun=false, infEnergy=false,
	godMode=false, antiTrap=false, autoHeal=false,
	autoEscape=false, infAbility=false,
	speedOn=false, speedVal=25,
	fly=false, flySpeed=50,
	jumpForce=false, noclip=false,
	tpGen=false, tpTeam=false,
	fullbright=false, fovOn=false, fovVal=100,
	doorBlock=false, mouseLock=false,
	antiAfk=true, guiShow=true, tab="esp",
}

local espC: {[string]:BillboardGui} = {}
local objC: {[Instance]:BillboardGui} = {}
local conn: {[string]:RBXScriptConnection} = {}
local T = {esp=0,obj=0,prompt=0,energy=0,nostun=0,god=0,safe=0,trap=0}
local bn = 0
local flyBV: BodyVelocity? = nil
local flyBG: BodyGyro? = nil
local alertCooldown = 0
local safeSpots: {Vector3} = {}

local oL = {
	B=Lighting.Brightness, CT=Lighting.ClockTime,
	FE=Lighting.FogEnd, GS=Lighting.GlobalShadows, A=Lighting.Ambient,
}
local oFOV = cam.FieldOfView

local gp: Instance
do local ok,h = pcall(function() return (gethui :: () -> Instance)() end)
	gp = if ok and h then h else game:GetService("CoreGui") end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/coreatl4ntic/library/refs/heads/main/framework.lua"))()

local sg = Instance.new("ScreenGui")
sg.Name="TC6_Overlay"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=gp

local alertSound = Instance.new("Sound")
alertSound.SoundId = "rbxassetid://6895079853"
alertSound.Volume = 0.5
alertSound.Parent = sg

local Window = Library:Window({
    Title = "[BETA] Bite By Night",
    Desc = "by atl4ntic",
    Icon = 105059922903197,
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.RightShift,
        Size = UDim2.new(0, 500, 0, 400)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "Menu"
    }
})

local EspTab = Window:Tab({Title = "ESP", Icon = "star"}) do
    EspTab:Section({Title = "JOUEURS"})
    EspTab:Toggle({
        Title = "Player ESP",
        Desc = "Voir les joueurs ?� travers les murs",
        Value = false,
        Callback = function(on)
            S.espPlayer=on
            if not on then for _,b in espC do b.Enabled=false end end
        end
    })
    EspTab:Toggle({
        Title = "Killer Alert",
        Desc = "Alarme quand killer < 40m",
        Value = false,
        Callback = function(on) S.killerAlert=on end
    })

    EspTab:Section({Title = "OBJECTIFS"})
    EspTab:Toggle({
        Title = "Generator ESP",
        Desc = "Voir les g??n??rateurs",
        Value = false,
        Callback = function(on) S.espGen=on end
    })
    EspTab:Toggle({
        Title = "Battery ESP",
        Desc = "Voir les batteries",
        Value = false,
        Callback = function(on) S.espBat=on end
    })
    EspTab:Toggle({
        Title = "Trap ESP",
        Desc = "Bear traps Springtrap en violet",
        Value = false,
        Callback = function(on) S.espTrap=on end
    })
    EspTab:Toggle({
        Title = "Exit ESP",
        Desc = "Voir les sorties",
        Value = false,
        Callback = function(on) S.espExit=on end
    })
end

local SurvTab = Window:Tab({Title = "Survie", Icon = "shield"}) do
    SurvTab:Section({Title = "IMMORTALITE"})
    SurvTab:Toggle({
        Title = "God Mode",
        Desc = "HP infini + anti-mort",
        Value = false,
        Callback = function(on) S.godMode=on end
    })
    SurvTab:Toggle({
        Title = "No Stun / No Grab",
        Desc = "Anti stun",
        Value = false,
        Callback = function(on) S.noStun=on end
    })
    SurvTab:Toggle({
        Title = "Anti Trap",
        Desc = "Detruit les pieges proches",
        Value = false,
        Callback = function(on) S.antiTrap=on end
    })

    SurvTab:Section({Title = "RESSOURCES"})
    SurvTab:Toggle({
        Title = "Inf Stamina",
        Desc = "Stamina infinie",
        Value = false,
        Callback = function(on) S.infEnergy=on end
    })
    SurvTab:Toggle({
        Title = "Inf Abilities (Q/E)",
        Desc = "Cooldown Q et E a 0",
        Value = false,
        Callback = function(on) S.infAbility=on end
    })

    SurvTab:Section({Title = "AUTOMATIQUE"})
    SurvTab:Toggle({
        Title = "Instant Prompt",
        Desc = "Generators instantanes",
        Value = false,
        Callback = function(on) S.instantPrompt=on end
    })
    SurvTab:Toggle({
        Title = "Auto Safe TP",
        Desc = "TP safe quand HP < 30%",
        Value = false,
        Callback = function(on) S.autoHeal=on end
    })
    SurvTab:Toggle({
        Title = "Auto Escape",
        Desc = "S'??chappe automatiquement",
        Value = false,
        Callback = function(on) S.autoEscape=on end
    })

    SurvTab:Section({Title = "PORTE"})
    SurvTab:Toggle({
        Title = "Door Block (C)",
        Desc = "Bloque la porte",
        Value = false,
        Callback = function(on) S.doorBlock=on end
    })
end

local MoveTab = Window:Tab({Title = "Move", Icon = "airplane"}) do
    MoveTab:Section({Title = "VITESSE"})
    MoveTab:Toggle({
        Title = "Speed Boost",
        Desc = "Active le speed hack",
        Value = false,
        Callback = function(on) S.speedOn=on end
    })
    MoveTab:Slider({
        Title = "Vitesse",
        Min = 10,
        Max = 100,
        Rounding = 0,
        Value = 25,
        Callback = function(val) S.speedVal=val end
    })

    MoveTab:Section({Title = "VOL"})
    MoveTab:Toggle({
        Title = "Fly",
        Desc = "Vol actif",
        Value = false,
        Callback = function(on)
            S.fly=on
            local c=lp.Character; if not c then return end
            local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not r then return end
            if on then
                flyBV=Instance.new("BodyVelocity")
                flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
                flyBV.Velocity=Vector3.zero
                flyBV.Parent=r
                flyBG=Instance.new("BodyGyro")
                flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
                flyBG.D=100; flyBG.P=1e4
                flyBG.Parent=r
            else
                if flyBV then flyBV:Destroy(); flyBV=nil end
                if flyBG then flyBG:Destroy(); flyBG=nil end
            end
        end
    })
    MoveTab:Slider({
        Title = "Fly Speed",
        Min = 10,
        Max = 150,
        Rounding = 0,
        Value = 50,
        Callback = function(val) S.flySpeed=val end
    })

    MoveTab:Section({Title = "SAUT"})
    MoveTab:Toggle({
        Title = "Jump Force",
        Desc = "Sauter meme si bloque",
        Value = false,
        Callback = function(on) S.jumpForce=on end
    })

    MoveTab:Section({Title = "TRAVERSER"})
    MoveTab:Toggle({
        Title = "Noclip",
        Desc = "Passe a travers les murs",
        Value = false,
        Callback = function(on) S.noclip=on end
    })

    MoveTab:Section({Title = "TELEPORT"})
    MoveTab:Button({
        Title = "TP au Gen le + proche",
        Desc = "Teleporte au generateur proche",
        Callback = function()
            local c=lp.Character; local r=c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not r then return end
            local best: BasePart?=nil; local bestD=math.huge
            for _,d in workspace:GetDescendants() do
                local n=string.lower(d.Name)
                if d:IsA("BasePart") and (string.find(n,"generator") or string.find(n,"gen_") or string.find(n,"power")) then
                    local dist=(d.Position-r.Position).Magnitude
                    if dist<bestD and dist>8 then bestD=dist; best=d end
                elseif d:IsA("Model") and (string.find(n,"generator") or string.find(n,"gen_")) then
                    local pp=d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")
                    if pp then local dist=(pp.Position-r.Position).Magnitude
                        if dist<bestD and dist>8 then bestD=dist; best=pp :: BasePart end
                    end
                end
            end
            if best then r.CFrame=best.CFrame+Vector3.new(0,4,3) end
        end
    })
    MoveTab:Button({
        Title = "TP au Teammate le + proche",
        Desc = "Teleporte a un allie",
        Callback = function()
            local c=lp.Character; local r=c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not r then return end
            local best: BasePart?=nil; local bestD=math.huge
            for _,p in Players:GetPlayers() do
                if p==lp or isKillerGlobal(p) then continue end
                local pc=p.Character; local ph=pc and pc:FindFirstChild("HumanoidRootPart") :: BasePart?
                if ph then local dist=(ph.Position-r.Position).Magnitude
                    if dist<bestD and dist>5 then bestD=dist; best=ph end
                end
            end
            if best then r.CFrame=best.CFrame+Vector3.new(3,0,3) end
        end
    })
end

local VisTab = Window:Tab({Title = "Visuel", Icon = "eye"}) do
    VisTab:Section({Title = "VISION"})
    VisTab:Toggle({
        Title = "Fullbright",
        Desc = "Vision claire",
        Value = false,
        Callback = function(on)
            S.fullbright=on
            if on then
                Lighting.Brightness=3; Lighting.ClockTime=12
                Lighting.FogEnd=100000; Lighting.GlobalShadows=false
                Lighting.Ambient=Color3.fromRGB(200,200,200)
                for _,e in Lighting:GetChildren() do
                    if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect") then e.Enabled=false end
                    if e:IsA("Atmosphere") then e.Density=0 end
                end
            else
                Lighting.Brightness=oL.B; Lighting.ClockTime=oL.CT
                Lighting.FogEnd=oL.FE; Lighting.GlobalShadows=oL.GS
                Lighting.Ambient=oL.A
                for _,e in Lighting:GetChildren() do
                    if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("SunRaysEffect") then e.Enabled=true end
                end
            end
        end
    })
    VisTab:Toggle({
        Title = "FOV Boost",
        Desc = "Agrandit le champ de vision",
        Value = false,
        Callback = function(on) S.fovOn=on; cam.FieldOfView=if on then S.fovVal else oFOV end
    })
    VisTab:Slider({
        Title = "FOV",
        Min = 70,
        Max = 120,
        Rounding = 0,
        Value = 100,
        Callback = function(v) S.fovVal=v; if S.fovOn then cam.FieldOfView=v end end
    })

    VisTab:Section({Title = "DIVERS"})
    VisTab:Toggle({
        Title = "Anti-AFK",
        Desc = "Emp??che d'??tre kick",
        Value = true,
        Callback = function(on) S.antiAfk=on end
    })
end

Window:Notify({
    Title = "Tiger Cheat",
    Desc = "Loaded successfully!",
    Time = 4
})

local KW = {"killer","animatronic","springtrap","mimic","monster","freddy","bonnie","chica","foxy","beast","puppet","mangle","ennard","monsterrat"}

function isKillerGlobal(p: Player): boolean
	for _,a in {"Role","Team","PlayerRole","GameRole","Class","PlayerType","role","team","class","type"} do
		local v=p:GetAttribute(a); if v then local s=string.lower(tostring(v))
			for _,k in KW do if s==k or string.find(s,k) then return true end end end
	end
	if p.Team then local t=string.lower(p.Team.Name)
		for _,k in KW do if t==k or string.find(t,k) then return true end end end
	local c=p.Character; if c then
		local h=c:FindFirstChild("Humanoid") :: Humanoid?
		if h and h.WalkSpeed>22 then return true end
		for _,ch in c:GetChildren() do local n=string.lower(ch.Name)
			for _,k in KW do if string.find(n,k) then return true end end end
	end
	for _,ch in p:GetChildren() do local n=string.lower(ch.Name)
		if ch:IsA("StringValue") and (string.find(n,"role") or string.find(n,"killer") or string.find(n,"type")) then
			local v=string.lower(ch.Value)
			for _,k in KW do if v==k then return true end end
		elseif ch:IsA("BoolValue") and ch.Value then
			for _,k in KW do if string.find(n,k) then return true end end
		end
	end
	return false
end

local function cleanE(n) if espC[n] then espC[n]:Destroy(); espC[n]=nil end end

local function updESP()
	if not S.espPlayer then return end
	local mr=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not mr then return end
	local act: {[string]:boolean}={}
	for _,p in Players:GetPlayers() do
		if p==lp then continue end
		local c=p.Character; local h=c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not h then continue end; act[p.Name]=true
		local d=(h.Position-mr.Position).Magnitude
		if d>MAXD then if espC[p.Name] then espC[p.Name].Enabled=false end; continue end
		if not espC[p.Name] then
			local bb=Instance.new("BillboardGui")
			bb.Size=UDim2.fromOffset(120,26); bb.StudsOffset=Vector3.new(0,3.5,0)
			bb.AlwaysOnTop=true; bb.MaxDistance=MAXD; bb.Parent=gp
			local tl=Instance.new("TextLabel",bb); tl.Name="L"
			tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=0.2
			tl.Font=Enum.Font.GothamBold; tl.TextSize=12; tl.TextStrokeTransparency=0.2
			Instance.new("UICorner",tl).CornerRadius=UDim.new(0,5)
			espC[p.Name]=bb
		end
		local bb=espC[p.Name]; bb.Adornee=h; bb.Enabled=true
		local l=bb:FindFirstChild("L") :: TextLabel
		local dm=math.floor(d).."m"; local kl=isKillerGlobal(p)
		l.Text=if kl then "??? KILLER "..dm else "???? "..p.DisplayName.." "..dm
		l.TextColor3=if kl then CL.red else CL.grn
		l.BackgroundColor3=if kl then Color3.fromRGB(60,0,0) else Color3.fromRGB(0,35,10)

		if kl and S.killerAlert and d<40 and (tick()-alertCooldown)>3 then
			alertCooldown=tick()
			pcall(function() alertSound:Play() end)
			local flash=Instance.new("Frame",sg)
			flash.Size=UDim2.new(1,0,1,0); flash.BackgroundColor3=CL.red
			flash.BackgroundTransparency=0.7; flash.ZIndex=100
			task.delay(0.3,function() if flash.Parent then flash:Destroy() end end)
		end
	end
	for n,_ in espC do if not act[n] then cleanE(n) end end
end

local function cleanO(i) if objC[i] then objC[i]:Destroy(); objC[i]=nil end end

local function updObj()
	local mr=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not mr then return end
	for i,b in objC do if not i.Parent then cleanO(i) end end

	local function scan(parent,depth)
		if depth>4 then return end
		for _,ch in parent:GetChildren() do
			if ch:FindFirstChild("Humanoid") then continue end
			local n=string.lower(ch.Name)

			local isGen = string.find(n,"generator") or string.find(n,"gen_") or string.find(n,"fuse")
				or string.find(n,"power") or string.find(n,"machine") or string.find(n,"panel")
				or string.find(n,"circuit") or string.find(n,"breaker") or string.find(n,"electrical")
			local isBat = string.find(n,"battery") or string.find(n,"batt") or string.find(n,"cell")
			local isTrap = string.find(n,"trap") or string.find(n,"bear") or string.find(n,"snare")
				or string.find(n,"mine")
			local isExit = string.find(n,"exit") or string.find(n,"escape") or string.find(n,"gate")
				or string.find(n,"leave") or string.find(n,"door_exit")

			local show = (isGen and S.espGen) or (isBat and S.espBat)
				or (isTrap and S.espTrap) or (isExit and S.espExit)

			if show then
				local part: BasePart?=nil
				if ch:IsA("BasePart") then part=ch :: BasePart
				elseif ch:IsA("Model") then
					part=(ch :: Model).PrimaryPart or ch:FindFirstChildWhichIsA("BasePart") :: BasePart?
				end
				if part then
					local d=(part.Position-mr.Position).Magnitude
					if d<MAXD then
						if not objC[ch] then
							local bb=Instance.new("BillboardGui")
							bb.Size=UDim2.fromOffset(90,20); bb.StudsOffset=Vector3.new(0,4,0)
							bb.AlwaysOnTop=true; bb.MaxDistance=MAXD; bb.Parent=gp
							local tl=Instance.new("TextLabel",bb); tl.Name="L"
							tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=0.25
							tl.Font=Enum.Font.GothamBold; tl.TextSize=10; tl.TextStrokeTransparency=0.3
							Instance.new("UICorner",tl).CornerRadius=UDim.new(0,4)
							objC[ch]=bb
						end
						local bb=objC[ch]; bb.Adornee=part; bb.Enabled=true
						local l=bb:FindFirstChild("L") :: TextLabel
						local dm=math.floor(d).."m"
						if isTrap then
							l.Text="??�??� TRAP "..dm; l.TextColor3=CL.purple
							l.BackgroundColor3=Color3.fromRGB(40,10,55)
						elseif isExit then
							l.Text="???? EXIT "..dm; l.TextColor3=CL.pink
							l.BackgroundColor3=Color3.fromRGB(50,15,35)
						elseif isBat then
							l.Text="??�? BAT "..dm; l.TextColor3=CL.cyan
							l.BackgroundColor3=Color3.fromRGB(0,30,50)
						else
							l.Text="??? GEN "..dm; l.TextColor3=CL.gold
							l.BackgroundColor3=Color3.fromRGB(50,40,0)
						end
					end
				end
			end
			if #ch:GetChildren()>0 then scan(ch,depth+1) end
		end
	end
	scan(workspace,0)
end

local function doGod()
	if not S.godMode then return end
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("Humanoid") :: Humanoid?
	if not h then return end
	h.Health=h.MaxHealth
	if not c:FindFirstChild("ForceField") and S.godMode then
	end
	h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
end

local function doNoStun()
	if not S.noStun then return end
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("Humanoid") :: Humanoid?
	if not h then return end
	for _,tk in h:GetPlayingAnimationTracks() do
		local n=string.lower(tk.Name)
		if string.find(n,"stun") or string.find(n,"grab") or string.find(n,"caught")
			or string.find(n,"down") or string.find(n,"fall") or string.find(n,"hit")
			or string.find(n,"knock") or string.find(n,"trap") or string.find(n,"death")
			or string.find(n,"die") then
			tk:Stop(0)
		end
	end
	h.PlatformStand=false
	if h.WalkSpeed<5 then h.WalkSpeed=16 end
	if h.JumpPower<10 then h.JumpPower=50 end
	local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if r then for _,ch in r:GetChildren() do
		if (ch:IsA("BodyPosition") or ch:IsA("BodyGyro") or ch:IsA("BodyVelocity")) then
			local nn=string.lower(ch.Name)
			if string.find(nn,"stun") or string.find(nn,"grab") or string.find(nn,"knock") then
				ch:Destroy() end
		end
	end end
end

local function doAntiTrap()
	if not S.antiTrap then return end
	local c=lp.Character; if not c then return end
	local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r then return end
	for _,d in workspace:GetDescendants() do
		local n=string.lower(d.Name)
		if (string.find(n,"trap") or string.find(n,"bear") or string.find(n,"snare") or string.find(n,"mine")) then
			if d:IsA("BasePart") then
				local dist=(d.Position-r.Position).Magnitude
				if dist<8 then
					d.CanCollide=false; d.Transparency=0.8
					for _,ch in d:GetDescendants() do
						if ch:IsA("TouchTransmitter") then ch:Destroy() end
					end
				end
			end
		end
	end
end

local function doEnergy()
	if not S.infEnergy and not S.infAbility then return end
	local c=lp.Character; if not c then return end
	if S.infEnergy then
		for _,target in {lp,c} do
			for _,a in {"Energy","Stamina","Sprint","Run","Endurance",
				"energy","stamina","sprint","run","endurance",
				"SprintStamina","RunEnergy","PlayerEnergy","Hunger","hunger"} do
				local v=target:GetAttribute(a)
				if v and type(v)=="number" then target:SetAttribute(a,100) end
			end
			for _,ch in target:GetChildren() do
				if ch:IsA("NumberValue") or ch:IsA("IntValue") then
					local n=string.lower(ch.Name)
					if string.find(n,"energy") or string.find(n,"stamina")
						or string.find(n,"sprint") or string.find(n,"endurance") then
						ch.Value=100
					end
				end
			end
		end
	end
	if S.infAbility then
		for _,target in {lp,c} do
			for _,a in {"Cooldown","CooldownQ","CooldownE","cooldown",
				"AbilityCooldown","SkillTimer","QTimer","ETimer",
				"cooldown_q","cooldown_e","ability_timer"} do
				local v=target:GetAttribute(a)
				if v and type(v)=="number" then target:SetAttribute(a,0) end
			end
			for _,ch in target:GetChildren() do
				if (ch:IsA("NumberValue") or ch:IsA("IntValue")) then
					local n=string.lower(ch.Name)
					if string.find(n,"cooldown") or string.find(n,"timer")
						or string.find(n,"cd") then
						ch.Value=0
					end
				end
			end
		end
	end
end

local function doPrompt()
	if not S.instantPrompt then return end
	for _,d in workspace:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			d.HoldDuration=0
			if d.MaxActivationDistance<20 then d.MaxActivationDistance=20 end
		end
	end
end

local function buildSafeSpots()
	safeSpots = {}
	for _,d in workspace:GetDescendants() do
		if d:IsA("SpawnLocation") then
			table.insert(safeSpots, d.Position)
		end
	end
	local parts = workspace:GetDescendants()
	for _,d in parts do
		if d:IsA("BasePart") and d.Anchored and d.Size.Magnitude>10 then
			local n=string.lower(d.Name)
			if string.find(n,"floor") or string.find(n,"ground")
				or string.find(n,"room") or string.find(n,"safe")
				or string.find(n,"lobby") or string.find(n,"spawn") then
				table.insert(safeSpots, d.Position+Vector3.new(0,3,0))
			end
		end
	end
end

local function doAutoSafe()
	if not S.autoHeal then return end
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("Humanoid") :: Humanoid?
	local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not h or not r then return end
	if h.Health/h.MaxHealth > 0.3 then return end

	local killerPos: Vector3?=nil
	for _,p in Players:GetPlayers() do
		if p~=lp and isKillerGlobal(p) then
			local pc=p.Character; local ph=pc and pc:FindFirstChild("HumanoidRootPart") :: BasePart?
			if ph then killerPos=ph.Position; break end
		end
	end

	if #safeSpots==0 then buildSafeSpots() end

	local bestSpot: Vector3?=nil; local bestDist=0
	for _,spot in safeSpots do
		if killerPos then
			local distFromKiller=(spot-killerPos).Magnitude
			if distFromKiller>bestDist then bestDist=distFromKiller; bestSpot=spot end
		else
			bestSpot=spot; break
		end
	end
	if bestSpot then r.CFrame=CFrame.new(bestSpot) end
end

local function doEscape()
	if not S.autoEscape then return end
	local c=lp.Character; local r=c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r then return end
	for _,d in workspace:GetDescendants() do
		local n=string.lower(d.Name)
		if (string.find(n,"exit") or string.find(n,"escape") or string.find(n,"leave")) and d:IsA("BasePart") then
			local pp=d:FindFirstChildWhichIsA("ProximityPrompt")
			if pp and pp.Enabled then
				r.CFrame=d.CFrame+Vector3.new(0,3,0)
				pcall(function() (fireproximityprompt :: any)(pp) end)
				return
			end
		end
	end
end

local function doFly()
	if not S.fly or not flyBV or not flyBG then return end
	local c=lp.Character; if not c then return end
	local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not r then return end
	local dir=Vector3.zero
	local cf=cam.CFrame
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.new(0,1,0) end
	if mob then
		local h=c:FindFirstChild("Humanoid") :: Humanoid?
		if h and h.MoveDirection.Magnitude>0 then
			dir=cf.LookVector*h.MoveDirection.Z + cf.RightVector*h.MoveDirection.X
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then dir+=Vector3.new(0,1,0) end
	end
	if dir.Magnitude>0 then dir=dir.Unit end
	flyBV.Velocity=dir*S.flySpeed
	flyBG.CFrame=cf
end

local function doJump()
	if not S.jumpForce then return end
	local c=lp.Character; if not c then return end
	local h=c:FindFirstChild("Humanoid") :: Humanoid?
	if h then
		h.JumpPower=55; h.JumpHeight=7.5
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

local function doNoclip()
	if not S.noclip then return end
	local c=lp.Character; if not c then return end
	for _,p in c:GetDescendants() do
		if p:IsA("BasePart") then p.CanCollide=false end
	end
end

conn["spd"]=RunService.Heartbeat:Connect(function(dt)
	if not S.speedOn then return end
	local c=lp.Character; if not c then return end
	local r=c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local h=c:FindFirstChild("Humanoid") :: Humanoid?
	if r and h and h.MoveDirection.Magnitude>0 then
		r.CFrame+=h.MoveDirection*S.speedVal*dt
	end
end)

conn["iB"]=UserInputService.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode==Enum.KeyCode.C and S.doorBlock then S.mouseLock=true
	elseif i.KeyCode==Enum.KeyCode.RightShift then
		S.guiShow=not S.guiShow; mf.Visible=S.guiShow
	elseif i.KeyCode==Enum.KeyCode.Space and S.jumpForce then
		local c=lp.Character; local h=c and c:FindFirstChild("Humanoid") :: Humanoid?
		if h then h.Jump=true end
	end
end)
conn["iE"]=UserInputService.InputEnded:Connect(function(i,g)
	if g then return end
	if i.KeyCode==Enum.KeyCode.C then S.mouseLock=false end
end)

conn["afk"]=lp.Idled:Connect(function()
	if S.antiAfk then pcall(function()
		VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
	end) end
end)

conn["pR"]=Players.PlayerRemoving:Connect(function(p) cleanE(p.Name) end)

task.defer(buildSafeSpots)

local fc=0
conn["M"]=RunService.Heartbeat:Connect(function()
	fc+=1; local now=tick()

	if S.espPlayer and (now-T.esp)>=TK.esp then T.esp=now; updESP() end

	if (S.espGen or S.espBat or S.espTrap or S.espExit) and (now-T.obj)>=TK.obj then
		T.obj=now; updObj() end

	if S.godMode and (now-T.god)>=TK.god then T.god=now; doGod() end

	if S.noStun and (now-T.nostun)>=TK.nostun then T.nostun=now; doNoStun() end

	if S.antiTrap and fc%30==0 then doAntiTrap() end

	if S.instantPrompt and (now-T.prompt)>=TK.prompt then T.prompt=now; doPrompt() end

	if (S.infEnergy or S.infAbility) and (now-T.energy)>=TK.energy then T.energy=now; doEnergy() end

	if S.autoHeal and (now-T.safe)>=TK.safe then T.safe=now; doAutoSafe() end

	if S.autoEscape and fc%120==0 then doEscape() end

	if S.fly then doFly() end

	if S.jumpForce and fc%60==0 then doJump() end

	if S.noclip then doNoclip() end

	if S.mouseLock then pcall(function()
		local fn=(mousemoveabs :: (number,number)->())
		local vp=cam.ViewportSize; local ins=GuiService:GetGuiInset()
		fn(vp.X/2,(vp.Y/2)+ins.Y)
	end) end

	if S.fovOn and fc%30==0 then cam.FieldOfView=S.fovVal end
end)

local function destroy()
	for n,c in conn do c:Disconnect(); conn[n]=nil end
	for n,_ in espC do cleanE(n) end
	for i,_ in objC do cleanO(i) end
	if flyBV then flyBV:Destroy() end
	if flyBG then flyBG:Destroy() end
	Lighting.Brightness=oL.B; Lighting.ClockTime=oL.CT
	Lighting.FogEnd=oL.FE; Lighting.GlobalShadows=oL.GS
	Lighting.Ambient=oL.A; cam.FieldOfView=oFOV; if sg then sg:Destroy() end
end
conn["anc"]=lp.AncestryChanged:Connect(function()
	if not lp:IsDescendantOf(game) then destroy() end end)

