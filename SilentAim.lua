--[[
    SilentAim.lua
    A configurable targeting assist (silent aim) script with Rayfield UI.
    Attuned for the Potassium dev environment.
]]

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Global Environment Setup for Potassium (getgenv support)
local getgenv = getgenv or function() return _G end
local sharedEnv = getgenv()

-- Clean up any existing connection, drawing object, outline highlights, or previous Rayfield instances
if sharedEnv.SilentAimCleanup then
    sharedEnv.SilentAimCleanup()
end

-- Configuration Options
local Config = {
    Enabled = true,
    WallCheck = true,
    TargetPart = "Head",       -- "Head", "HumanoidRootPart", etc.
    FOVRadius = 120,          -- FOV circle radius in pixels
    FOVCircleVisible = true,
    FOVCircleColor = Color3.fromRGB(255, 255, 255),
    FOVCircleTransparency = 0.7, -- Transparency setting (0 is fully opaque, 1 is fully transparent)
    
    -- Visual Highlight (Outline) Settings
    HighlightEnabled = true,
    OutlineColor = Color3.fromRGB(180, 150, 0),   -- Color of the silhouette outline (darker yellow)
    OutlineTransparency = 0,                    -- Transparency of the outline (0 is fully visible)
    FillColor = Color3.fromRGB(255, 220, 50),      -- Inner overlay fill color (medium yellow)
    FillTransparency = 0.85,                     -- Inner fill transparency (highly transparent)
}

-- Store Config in the global environment so it can be dynamically modified
sharedEnv.SilentAimConfig = Config

-- Create Highlight instance for the target outline
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "TargetingHighlight"
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.Parent = nil

-- Drawing library support (for FOV visualizer if executed in environments that support Drawing)
local FOVCircle = nil
if Drawing then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Config.FOVRadius
    FOVCircle.Filled = false
    FOVCircle.Visible = Config.FOVCircleVisible
    FOVCircle.Color = Config.FOVCircleColor
    FOVCircle.Transparency = 1 - Config.FOVCircleTransparency
end

-- Check if a target character is alive and valid
local function isValidTarget(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local targetPart = character:FindFirstChild(Config.TargetPart)
    if not targetPart then return false end
    
    return true
end

-- Raycast check to ensure target is visible
local function isVisible(targetPart, localCharacter)
    if not localCharacter then return false end
    local originPart = localCharacter:FindFirstChild("Head") or localCharacter:FindFirstChild("HumanoidRootPart")
    if not originPart then return false end
    
    local origin = originPart.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localCharacter}
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    if not result then
        return true
    elseif result.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    
    return false
end

-- Find the closest valid target relative to the screen cursor
local function getClosestTarget()
    if not Config.Enabled then return nil end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter then return nil end
    
    local mouseLocation = UserInputService:GetMouseLocation()
    local closestTarget = nil
    local shortestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isValidTarget(player.Character) then
            local character = player.Character
            local targetPart = character[Config.TargetPart]
            
            -- Project target onto viewport screen
            local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local distance2D = (Vector2.new(screenPoint.X, screenPoint.Y) - mouseLocation).Magnitude
                if distance2D <= Config.FOVRadius then
                    -- Perform obstacle check
                    local passWallCheck = not Config.WallCheck or isVisible(targetPart, localCharacter)
                    if passWallCheck and distance2D < shortestDistance then
                        shortestDistance = distance2D
                        closestTarget = targetPart
                    end
                end
            end
        end
    end
    
    return closestTarget
end

-- Hook/Interceptor interface for external integration or manual call
-- This returns the targeted position if a target is found, otherwise the fallback position
function GetAimTarget(fallbackPosition)
    local targetPart = getClosestTarget()
    if targetPart then
        return targetPart.Position
    end
    return fallbackPosition
end

-- Hook standard raycasting or return the target finder globally for Potassium testing
sharedEnv.GetAimTarget = GetAimTarget

-- Update loop for visual outline highlight & FOV visualizer position/properties
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    local targetPart = getClosestTarget()
    
    -- Update the Highlight outline on the target character
    if targetPart and Config.HighlightEnabled then
        local targetCharacter = targetPart.Parent
        if targetCharacter and targetCharacter:IsA("Model") then
            TargetHighlight.Parent = targetCharacter
            TargetHighlight.OutlineColor = Config.OutlineColor
            TargetHighlight.OutlineTransparency = Config.OutlineTransparency
            TargetHighlight.FillColor = Config.FillColor
            TargetHighlight.FillTransparency = Config.FillTransparency
            TargetHighlight.Enabled = true
        else
            TargetHighlight.Parent = nil
        end
    else
        TargetHighlight.Parent = nil
    end

    -- Update FOV circle properties
    if FOVCircle then
        local mouseLocation = UserInputService:GetMouseLocation()
        FOVCircle.Position = mouseLocation
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Color = Config.FOVCircleColor
        FOVCircle.Transparency = 1 - Config.FOVCircleTransparency
        FOVCircle.Visible = Config.Enabled and Config.FOVCircleVisible
    end
end)

-- Initialize Rayfield Window
local Window = Rayfield:CreateWindow({
   Name = "Phantom Silent Aim",
   Icon = "ghost",
   LoadingTitle = "Phantom",
   LoadingSubtitle = "by outtee",
   ShowText = "Phantom",
   Theme = "Amethyst",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ScriptID = "sid_9j805m4cxkw3",

   ConfigurationSaving = {
      Enabled = true,
      FolderName = Phantom,
      FileName = "SilentAimCfg",
   },

   Discord = {Enabled = false},

   KeySystem = false,
})

-- Create Tab
local MainTab = Window:CreateTab("Settings", "settings")

-- Main Tab Elements
MainTab:CreateToggle({
   Name = "Silent Aim",
   CurrentValue = Config.Enabled,
   Flag = "SilentAimEnabled",
   Callback = function(Value)
       Config.Enabled = Value
   end,
})

MainTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = Config.WallCheck,
   Flag = "WallCheck",
   Callback = function(Value)
       Config.WallCheck = Value
   end,
})

MainTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "HumanoidRootPart"},
   CurrentOption = {Config.TargetPart},
   MultipleOptions = false,
   Flag = "TargetPart",
   Callback = function(Options)
       Config.TargetPart = Options[1]
   end,
})

MainTab:CreateSlider({
   Name = "FOV Radius",
   Range = {10, 800},
   Increment = 5,
   Suffix = "px",
   CurrentValue = Config.FOVRadius,
   Flag = "FOVRadius",
   Callback = function(Value)
       Config.FOVRadius = Value
   end,
})

MainTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = Config.FOVCircleVisible,
   Flag = "FOVCircleVisible",
   Callback = function(Value)
       Config.FOVCircleVisible = Value
   end,
})

MainTab:CreateSlider({
   Name = "FOV Transparency",
   Range = {0, 100},
   Increment = 1,
   Suffix = "%",
   CurrentValue = math.floor(Config.FOVCircleTransparency * 100),
   Flag = "FOVTransparency",
   Callback = function(Value)
       Config.FOVCircleTransparency = Value / 100
   end,
})

MainTab:CreateToggle({
   Name = "Target Highlight",
   CurrentValue = Config.HighlightEnabled,
   Flag = "HighlightEnabled",
   Callback = function(Value)
       Config.HighlightEnabled = Value
   end,
})

-- Cleanup routine to allow re-running the script cleanly
sharedEnv.SilentAimCleanup = function()
    if renderConnection then
        renderConnection:Disconnect()
    end
    if FOVCircle then
        FOVCircle:Remove()
    end
    if TargetHighlight then
        TargetHighlight:Destroy()
    end
    Rayfield:Destroy()
    print("SilentAim.lua cleaned up previous instances.")
end

Rayfield:LoadConfiguration()
print("SilentAim.lua with Rayfield GUI successfully loaded.")
return GetAimTarget