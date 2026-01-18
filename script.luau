local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // SETTINGS
local _G = {
    Aimbot = false,
    SilentAim = false,
    ESP = true,
    TeamCheck = true,
    FOV = 150,
    Smoothing = 0.4,
    AimPart = "Head"
}

-- // THE CRITICAL FIX: OFFSET CALCULATION
-- This function converts World Position to EXACT Screen Position for Drawing objects
local function GetCorrectedPos(WorldPos)
    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(WorldPos)
    local Inset = GuiService:GetGuiInset()
    
    -- Subtract the TopBar inset from the Y axis to align with Drawing API
    return Vector2.new(ScreenPos.X, ScreenPos.Y - Inset.Y), OnScreen
end

-- // WINDOW SETUP
local Window = Rayfield:CreateWindow({
    Name = "Gemini Hub | Final Alignment",
    LoadingTitle = "Calculating Insets...",
    ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)

-- // UI ELEMENTS
MainTab:CreateToggle({Name = "Aimbot", CurrentValue = _G.Aimbot, Callback = function(v) _G.Aimbot = v end})
MainTab:CreateSlider({Name = "FOV", Range = {30, 800}, CurrentValue = 150, Callback = function(v) _G.FOV = v end})

VisualsTab:CreateToggle({Name = "ESP Master", CurrentValue = _G.ESP, Callback = function(v) _G.ESP = v end})
VisualsTab:CreateToggle({Name = "Team Check", CurrentValue = _G.TeamCheck, Callback = function(v) _G.TeamCheck = v end})

-- // DRAWING API: FOV CIRCLE
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- // HELPER: TARGETING
local function GetClosestPlayer()
    local Target = nil
    local ShortestDistance = _G.FOV
    local MousePos = UserInputService:GetMouseLocation() -- Native Mouse Pos includes Inset

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
            if _G.TeamCheck and v.Team == LocalPlayer.Team then continue end
            
            local ScreenPos, OnScreen = GetCorrectedPos(v.Character[_G.AimPart].Position)
            if OnScreen then
                local Distance = (ScreenPos - MousePos).Magnitude
                if Distance < ShortestDistance then
                    ShortestDistance = Distance
                    Target = v
                end
            end
        end
    end
    return Target
end

-- // ESP CREATION
local function CreateESP(Player)
    local Box = Drawing.new("Square")
    Box.Thickness = 1
    Box.Filled = false

    local Render
    Render = RunService.RenderStepped:Connect(function()
        if _G.ESP and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") and Player ~= LocalPlayer then
            if _G.TeamCheck and Player.Team == LocalPlayer.Team then Box.Visible = false return end

            local Root = Player.Character.HumanoidRootPart
            local ScreenPos, OnScreen = GetCorrectedPos(Root.Position)

            if OnScreen then
                -- Get Top and Bottom for Box Height
                local TopPos = GetCorrectedPos(Root.Position + Vector3.new(0, 3.5, 0))
                local BottomPos = GetCorrectedPos(Root.Position + Vector3.new(0, -4.5, 0))
                local SizeY = math.abs(TopPos.Y - BottomPos.Y)
                local SizeX = SizeY / 1.5

                Box.Visible = true
                Box.Size = Vector2.new(SizeX, SizeY)
                -- Center the box by subtracting half size from the corrected position
                Box.Position = Vector2.new(ScreenPos.X - SizeX / 2, ScreenPos.Y - SizeY / 2)
                Box.Color = Player.TeamColor.Color
            else
                Box.Visible = false
            end
        else
            if not Player.Parent then Box:Remove() Render:Disconnect() end
            Box.Visible = false
        end
    end)
end

-- // MAIN UPDATE LOOP
RunService.RenderStepped:Connect(function()
    local MousePos = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOV
    FOVCircle.Position = MousePos
    FOVCircle.Visible = _G.Aimbot

    if _G.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local Target = GetClosestPlayer()
        if Target then
            local TargetScreenPos = GetCorrectedPos(Target.Character[_G.AimPart].Position)
            -- Aimbot math: Move mouse toward the CORRECTED screen point
            mousemoverel((TargetScreenPos.X - MousePos.X) * _G.Smoothing, (TargetScreenPos.Y - MousePos.Y) * _G.Smoothing)
        end
    end
end)

-- Initialize
for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
