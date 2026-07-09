local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Lurking Giants Phantom",
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
      Enabled = false,
   },

   Discord = {Enabled = false},

   KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)

local CONFIG = {
    Color = Color3.fromRGB(255, 45, 85),
    FillOpacity = 0.7,
    OutlineColor = Color3.fromRGB(100, 18, 33),
    OutlineOpacity = 0.2,
}

local TEAM_COLORS = {
    ["lobby"] = {Fill = Color3.fromRGB(255, 255, 255), Outline = Color3.fromRGB(150, 150, 150)},
    ["giant"] = {Fill = Color3.fromRGB(255, 45, 85), Outline = Color3.fromRGB(100, 18, 33)},
    ["round"] = {Fill = Color3.fromRGB(0, 255, 100), Outline = Color3.fromRGB(0, 100, 35)},
}

local isEnabled = false
local isFullbrightEnabled = false
local originalLighting = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

local activeChams = {}
local activeConnections = {}

local function normalize(str)
    if not str then return "" end
    return string.lower(string.gsub(str, "%s+", ""))
end

local function getPlayerColors(player)
    local team = player.Team
    if team then
        local normalizedTeam = normalize(team.Name)
        local colors = TEAM_COLORS[normalizedTeam]
        if colors then
            return colors.Fill, colors.Outline
        end
    end
    return CONFIG.Color, CONFIG.OutlineColor
end

local function cleanUp()
    for _, connection in ipairs(activeConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    table.clear(activeConnections)

    for character, highlight in pairs(activeChams) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    table.clear(activeChams)

    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("Highlight") and string.sub(child.Name, 1, 5) == "Cham_" then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function shouldHighlight(player)
    return player ~= LocalPlayer
end

local function updatePlayerCham(player)
    if not isEnabled then return end
    
    local character = player.Character
    if not character then return end

    if not shouldHighlight(player) then
        if activeChams[character] then
            pcall(function() activeChams[character]:Destroy() end)
            activeChams[character] = nil
        end
        return
    end

    local fillColor, outlineColor = getPlayerColors(player)

    if activeChams[character] then
        activeChams[character].FillColor = fillColor
        activeChams[character].OutlineColor = outlineColor
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Cham_" .. player.Name
    highlight.FillColor = fillColor
    highlight.FillTransparency = CONFIG.FillOpacity
    highlight.OutlineColor = outlineColor
    highlight.OutlineTransparency = CONFIG.OutlineOpacity
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.Parent = character
    activeChams[character] = highlight

    local ancestryConn
    ancestryConn = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            activeChams[character] = nil
            if ancestryConn then ancestryConn:Disconnect() end
        end
    end)
    table.insert(activeConnections, ancestryConn)
end

local function monitorPlayer(player)
    local function check()
        task.defer(updatePlayerCham, player)
    end

    local charAdded = player.CharacterAdded:Connect(function(char)
        check()
    end)
    local charRemoving = player.CharacterRemoving:Connect(function(char)
        if activeChams[char] then
            pcall(function() activeChams[char]:Destroy() end)
            activeChams[char] = nil
        end
    end)
    table.insert(activeConnections, charAdded)
    table.insert(activeConnections, charRemoving)

    local teamChanged = player:GetPropertyChangedSignal("Team"):Connect(check)
    table.insert(activeConnections, teamChanged)

    check()
end

local function buildChams(state: boolean)
    isEnabled = state
    cleanUp()

    if state ~= true then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        monitorPlayer(player)
    end

    local playerAdded = Players.PlayerAdded:Connect(function(player)
        monitorPlayer(player)
    end)
    table.insert(activeConnections, playerAdded)

    local playerRemoving = Players.PlayerRemoving:Connect(function(player)
        if player.Character and activeChams[player.Character] then
            pcall(function() activeChams[player.Character]:Destroy() end)
            activeChams[player.Character] = nil
        end
    end)
    table.insert(activeConnections, playerRemoving)
end

local function toggleFullbright(state)
    isFullbrightEnabled = state
    if state then
        originalLighting.Ambient = Lighting.Ambient
        originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        originalLighting.Brightness = Lighting.Brightness
        originalLighting.GlobalShadows = Lighting.GlobalShadows
        originalLighting.ClockTime = Lighting.ClockTime
        originalLighting.FogEnd = Lighting.FogEnd
        originalLighting.FogStart = Lighting.FogStart
        
        task.spawn(function()
            while isFullbrightEnabled do
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Brightness = 2
                Lighting.GlobalShadows = false
                Lighting.ClockTime = 14
                Lighting.FogEnd = 999999
                task.wait()
            end
        end)
    else
        if originalLighting.Ambient then
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.Brightness = originalLighting.Brightness
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart
        end
    end
end

local Chams = MainTab:CreateToggle({
   Name = "Chams",
   CurrentValue = false,
   Callback = function(Value)
        buildChams(Value)
   end,
})

local Fullbright = MainTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(Value)
        toggleFullbright(Value)
    end,
})

local MiscTab = Window:CreateTab("Misc")

local DestroyButton = MiscTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        buildChams(false)
        toggleFullbright(false)
        Rayfield:Destroy()
    end,
})