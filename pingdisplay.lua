--[[
	PingDisplay.lua
	A movable, dark-mode GUI that displays live ping (ms),
	color-coded by connection quality. Updates every 0.1 seconds.

	USAGE:
	Place this as a LocalScript inside StarterPlayerScripts
	(StarterPlayer > StarterPlayerScripts > this script).
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local UPDATE_INTERVAL = 0.1
local BG_COLOR = Color3.fromRGB(25, 25, 25)
local ACCENT_COLOR = Color3.fromRGB(45, 45, 45)
local FONT = Enum.Font.GothamBold

-- Ping quality thresholds (ms) and their colors
-- ping <= GOOD_MS            -> green
-- GOOD_MS < ping <= BAD_MS   -> yellow
-- ping > BAD_MS              -> red
local GOOD_MS = 100
local BAD_MS = 250
local COLOR_GOOD = Color3.fromRGB(90, 220, 120)   -- green
local COLOR_OK = Color3.fromRGB(240, 200, 60)     -- yellow
local COLOR_BAD = Color3.fromRGB(235, 70, 70)      -- red
local COLOR_UNKNOWN = Color3.fromRGB(160, 160, 160) -- gray, when ping is unavailable

----------------------------------------------------------------
-- CLEANUP OLD INSTANCE (so re-running this script replaces it)
----------------------------------------------------------------
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local existing = playerGui:FindFirstChild("PingDisplay")
if existing then
	existing:Destroy()
end

----------------------------------------------------------------
-- GUI CREATION
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PingDisplay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(1, 1)
mainFrame.Size = UDim2.new(0, 90, 0, 40)
mainFrame.Position = UDim2.new(1, -20, 1, -20)
mainFrame.BackgroundColor3 = BG_COLOR
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = ACCENT_COLOR
stroke.Thickness = 1.5
stroke.Parent = mainFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "PingLabel"
pingLabel.Size = UDim2.new(1, 0, 1, 0)
pingLabel.Position = UDim2.new(0, 0, 0, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "0"
pingLabel.TextColor3 = COLOR_UNKNOWN
pingLabel.TextXAlignment = Enum.TextXAlignment.Center
pingLabel.TextYAlignment = Enum.TextYAlignment.Center
pingLabel.Font = FONT
pingLabel.TextSize = 20
pingLabel.Parent = mainFrame

----------------------------------------------------------------
-- DRAGGING LOGIC (drag the whole GUI)
----------------------------------------------------------------
local dragging = false
local dragInput
local dragStart
local startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

----------------------------------------------------------------
-- PING TRACKING
----------------------------------------------------------------
local function getPing()
	local ok, pingValue = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and pingValue then
		return math.floor(pingValue + 0.5)
	end
	return -1
end

local function getPingColor(ms)
	if ms < 0 then
		return COLOR_UNKNOWN
	elseif ms <= GOOD_MS then
		return COLOR_GOOD
	elseif ms <= BAD_MS then
		return COLOR_OK
	else
		return COLOR_BAD
	end
end

----------------------------------------------------------------
-- UPDATE LOOP (every 0.1s)
----------------------------------------------------------------
task.spawn(function()
	while screenGui.Parent do
		local ping = getPing()

		pingLabel.Text = ping >= 0 and (tostring(ping) .. "ms") or "N/A"
		pingLabel.TextColor3 = getPingColor(ping)

		task.wait(UPDATE_INTERVAL)
	end
end)