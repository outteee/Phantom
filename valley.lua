local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Valley Prison Phantom",
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

-- Configuration
local CONFIG = {
    Color = Color3.fromRGB(255, 45, 85),          -- Reddish Pink
    FillOpacity = 0.5,                            -- 0 (solid) to 1 (invisible)
    OutlineColor = Color3.fromRGB(100, 18, 33),   -- Darker version of reddish pink
    OutlineOpacity = 0.2,                         -- Transparent subtle outline
}

-- Case/space insensitive target team mapping
local function normalize(str)
    if not str then return "" end
    return string.lower(string.gsub(str, "%s+", ""))
end

local TARGET_TEAMS = {
    ["minimumsecurity"] = true,
    ["mediumsecurity"] = true,
    ["maximumsecurity"] = true,
}

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- State Storage
local activeChams = {}
local activeConnections = {}

-- Safely clean up all highlights and disconnect all active event listeners
local function cleanUp()
    -- Disconnect listeners
    for _, connection in ipairs(activeConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    table.clear(activeConnections)

    -- Destroy highlights
    for character, highlight in pairs(activeChams) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    table.clear(activeChams)
end

-- Checks if a target player meets all criteria for highlighting
local function shouldHighlight(player)
    if player == LocalPlayer then return false end

    -- 1. Local player must be on the Guard team ("Department of Corrections")
    local localTeam = LocalPlayer.Team
    if not localTeam or normalize(localTeam.Name) ~= "departmentofcorrections" then
        return false
    end

    -- 2. Target player must be on one of the prisoner teams
    local targetTeam = player.Team
    if not targetTeam or not TARGET_TEAMS[normalize(targetTeam.Name)] then
        return false
    end

    -- 3. Target must have "Shiv" or "Screwdriver" in their Backpack or Character (equipped)
    local hasContraband = false
    
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        if backpack:FindFirstChild("Shiv") or backpack:FindFirstChild("Screwdriver") then
            hasContraband = true
        end
    end
    
    local character = player.Character
    if character then
        if character:FindFirstChild("Shiv") or character:FindFirstChild("Screwdriver") then
            hasContraband = true
        end
    end

    if not hasContraband then
        return false
    end

    return true
end

-- Safely applies or removes a cham on a player based on criteria
local function updatePlayerCham(player)
    local character = player.Character
    if not character then return end

    if not shouldHighlight(player) then
        -- If they shouldn't be highlighted, destroy any existing cham
        if activeChams[character] then
            pcall(function() activeChams[character]:Destroy() end)
            activeChams[character] = nil
        end
        return
    end

    -- If already highlighted, don't recreate
    if activeChams[character] then return end

    -- Create modern Highlight instance
    local highlight = Instance.new("Highlight")
    highlight.Name = "Cham_" .. player.Name
    highlight.FillColor = CONFIG.Color
    highlight.FillTransparency = CONFIG.FillOpacity
    highlight.OutlineColor = CONFIG.OutlineColor
    highlight.OutlineTransparency = CONFIG.OutlineOpacity
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Always render through walls

    -- Parent the Highlight
    highlight.Parent = character
    activeChams[character] = highlight

    -- Watch for character destruction/ancestry changes to clean up references
    local ancestryConn
    ancestryConn = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            activeChams[character] = nil
            if ancestryConn then ancestryConn:Disconnect() end
        end
    end)
    table.insert(activeConnections, ancestryConn)
end

-- Force updates highlighting on all players
local function updateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerCham(player)
    end
end

-- Monitors a player's states dynamically (Team, Character, Backpack, Equipped items)
local function monitorPlayer(player)
    local function check()
        updatePlayerCham(player)
    end

    -- Hook backpack additions/removals
    local function watchBackpack(bp)
        local bpAdded = bp.ChildAdded:Connect(check)
        local bpRemoved = bp.ChildRemoved:Connect(check)
        table.insert(activeConnections, bpAdded)
        table.insert(activeConnections, bpRemoved)
    end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        watchBackpack(backpack)
    end
    
    local bpFolderAdded = player.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            watchBackpack(child)
            check()
        end
    end)
    table.insert(activeConnections, bpFolderAdded)

    -- Monitor character additions/removals (checking equipped tools)
    local function watchCharacter(char)
        local charChildAdded = char.ChildAdded:Connect(check)
        local charChildRemoved = char.ChildRemoved:Connect(check)
        table.insert(activeConnections, charChildAdded)
        table.insert(activeConnections, charChildRemoved)
    end

    local charAdded = player.CharacterAdded:Connect(function(char)
        watchCharacter(char)
        task.defer(check)
    end)
    local charRemoving = player.CharacterRemoving:Connect(function(char)
        if activeChams[char] then
            pcall(function() activeChams[char]:Destroy() end)
            activeChams[char] = nil
        end
    end)
    table.insert(activeConnections, charAdded)
    table.insert(activeConnections, charRemoving)
    
    if player.Character then
        watchCharacter(player.Character)
    end

    -- Monitor team changes
    local teamChanged = player:GetPropertyChangedSignal("Team"):Connect(check)
    table.insert(activeConnections, teamChanged)

    -- Initial check
    check()
end

-- Expose buildChams function globally or locally
local function buildChams(state: boolean)
    cleanUp() -- Completely reset prior setup

    if state ~= true then
        print("[Madium Chams] Chams disabled and cleaned up.")
        return
    end

    -- Initialize tracking on active players
    for _, player in ipairs(Players:GetPlayers()) do
        monitorPlayer(player)
    end

    -- Watch new players joining
    local playerAdded = Players.PlayerAdded:Connect(function(player)
        monitorPlayer(player)
    end)
    table.insert(activeConnections, playerAdded)

    -- Cleanup references when players leave
    local playerRemoving = Players.PlayerRemoving:Connect(function(player)
        if player.Character and activeChams[player.Character] then
            pcall(function() activeChams[player.Character]:Destroy() end)
            activeChams[player.Character] = nil
        end
    end)
    table.insert(activeConnections, playerRemoving)

    -- Monitor local player's team status to toggle highlight tracking dynamically
    local localTeamConn = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(updateAllPlayers)
    table.insert(activeConnections, localTeamConn)

    print("[Madium Chams] Chams initialized and tracking.")
end

local InnoChams = MainTab:CreateToggle({
   Name = "Item Cham",
   CurrentValue = false,
   Callback = function(Value)
        buildChams(Value)
   end,
})

local MiscTab = Window:CreateTab("Misc")

local DestroyButton = MiscTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        buildChams(false)
        Rayfield:Destroy()
    end,
})