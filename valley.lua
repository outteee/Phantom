--[[
    Valley Prison
    by outtee

    Main      - Quick Bin / Quick Keycards prompt HoldDuration toggles + Item Cham
    Highlight - highlight players by username
    Misc      - Destroy Rayfield (resets prompts, clears chams + highlights, tears down UI)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Valley Prison",
    Icon = "ghost",
    LoadingTitle = "Valley Prison",
    LoadingSubtitle = "by outtee",
    ShowText = "Valley Prison",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ScriptID = "sid_9j805m4cxkw3",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Phantom",
        FileName = "PrisonPhantomCfg",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", "home")
local HighlightTab = Window:CreateTab("Highlight", "eye")
local MiscTab = Window:CreateTab("Misc", "settings")

--=====================================================
-- MAIN TAB: Quick Bin / Quick Keycards
--=====================================================

--// Path resolution: Searchable contains multiple sibling "Bin" instances
local function getBins()
    local Map = workspace:WaitForChild("Map", 5)
    if not Map then return {} end

    local Functional = Map:WaitForChild("Functional", 5)
    if not Functional then return {} end

    local Storages = Functional:WaitForChild("Storages", 5)
    if not Storages then return {} end

    local Searchable = Storages:WaitForChild("Searchable", 5)
    if not Searchable then return {} end

    local bins = {}
    for _, obj in ipairs(Searchable:GetChildren()) do
        if obj.Name == "Bin" then
            table.insert(bins, obj)
        end
    end

    return bins
end

--// Sets HoldDuration on every ProximityPrompt found under every Bin
local function setBinHoldDuration(duration)
    local bins = getBins()
    if #bins == 0 then
        Rayfield:Notify({
            Title = "Quick Bin",
            Content = "Could not find any Bin instances.",
            Duration = 4,
        })
        return
    end

    local count = 0
    for _, bin in ipairs(bins) do
        for _, obj in ipairs(bin:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                obj.HoldDuration = duration
                count += 1
            end
        end
    end

    Rayfield:Notify({
        Title = "Quick Bin",
        Content = string.format("Set HoldDuration to %d on %d prompt(s) across %d bin(s).", duration, count, #bins),
        Duration = 4,
    })
end

--// Finds every ProximityPrompt named with "Keycard" in it, nested under any
--// "Handle" instance inside workspace.Map.Keycards
local function getKeycardPrompts()
    local Map = workspace:WaitForChild("Map", 5)
    if not Map then return {} end

    local Keycards = Map:WaitForChild("Keycards", 5)
    if not Keycards then return {} end

    local prompts = {}
    for _, obj in ipairs(Keycards:GetDescendants()) do
        if obj.Name == "Handle" then
            for _, descendant in ipairs(obj:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") and string.find(descendant.Name, "Keycard") then
                    table.insert(prompts, descendant)
                end
            end
        end
    end

    return prompts
end

--// Sets HoldDuration on every matching keycard ProximityPrompt
local function setKeycardHoldDuration(duration)
    local prompts = getKeycardPrompts()

    for _, prompt in ipairs(prompts) do
        prompt.HoldDuration = duration
    end

    Rayfield:Notify({
        Title = "Quick Keycards",
        Content = string.format("Set HoldDuration to %d on %d keycard prompt(s).", duration, #prompts),
        Duration = 4,
    })
end

MainTab:CreateToggle({
    Name = "Quick Bin",
    CurrentValue = false,
    Flag = "QuickBin",
    Callback = function(Value)
        if Value then
            setBinHoldDuration(0)
        else
            setBinHoldDuration(3)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Quick Keycards",
    CurrentValue = false,
    Flag = "QuickKeycards",
    Callback = function(Value)
        if Value then
            setKeycardHoldDuration(0)
        else
            setKeycardHoldDuration(1)
        end
    end,
})

--=====================================================
-- MAIN TAB: Item Cham (logic lives here, toggle moved to Highlight tab)
--=====================================================

local CHAM_CONFIG = {
    Color = Color3.fromRGB(255, 45, 85),
    FillOpacity = 0.7,
    OutlineColor = Color3.fromRGB(100, 18, 33),
    OutlineOpacity = 0.2,
}

local chamsEnabled = false

local function normalize(str)
    if not str then return "" end
    return string.lower(string.gsub(str, "%s+", ""))
end

local TARGET_TEAMS = {
    ["minimumsecurity"] = true,
    ["mediumsecurity"] = true,
    ["maximumsecurity"] = true,
}

local activeChams = {}
local chamConnections = {}

local function cleanUpChams()
    for _, connection in ipairs(chamConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    table.clear(chamConnections)

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

local function checkContainerForContraband(container)
    if not container then return false end

    for _, child in ipairs(container:GetChildren()) do
        if child:FindFirstChild("ToggleInnocence") then
            return true
        end
    end

    return false
end

local function shouldCham(player)
    if player == LocalPlayer then return false end

    local targetTeam = player.Team
    if not targetTeam or not TARGET_TEAMS[normalize(targetTeam.Name)] then
        return false
    end

    local hasContraband = checkContainerForContraband(player:FindFirstChild("Backpack"))
        or checkContainerForContraband(player.Character)

    return hasContraband
end

local function updatePlayerCham(player)
    if not chamsEnabled then return end

    local character = player.Character
    if not character then return end

    if not shouldCham(player) then
        if activeChams[character] then
            pcall(function() activeChams[character]:Destroy() end)
            activeChams[character] = nil
        end
        return
    end

    if activeChams[character] then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "Cham_" .. player.Name
    highlight.FillColor = CHAM_CONFIG.Color
    highlight.FillTransparency = CHAM_CONFIG.FillOpacity
    highlight.OutlineColor = CHAM_CONFIG.OutlineColor
    highlight.OutlineTransparency = CHAM_CONFIG.OutlineOpacity
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
    table.insert(chamConnections, ancestryConn)
end

local function updateAllChamPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerCham(player)
    end
end

local function monitorChamPlayer(player)
    local function check()
        task.defer(updatePlayerCham, player)
    end

    local function watchBackpack(bp)
        local bpAdded = bp.DescendantAdded:Connect(check)
        local bpRemoved = bp.DescendantRemoving:Connect(check)
        table.insert(chamConnections, bpAdded)
        table.insert(chamConnections, bpRemoved)
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
    table.insert(chamConnections, bpFolderAdded)

    local function watchCharacter(char)
        local charChildAdded = char.DescendantAdded:Connect(check)
        local charChildRemoved = char.DescendantRemoving:Connect(check)
        table.insert(chamConnections, charChildAdded)
        table.insert(chamConnections, charChildRemoved)
    end

    local charAdded = player.CharacterAdded:Connect(function(char)
        watchCharacter(char)
        check()
    end)
    local charRemoving = player.CharacterRemoving:Connect(function(char)
        if activeChams[char] then
            pcall(function() activeChams[char]:Destroy() end)
            activeChams[char] = nil
        end
    end)
    table.insert(chamConnections, charAdded)
    table.insert(chamConnections, charRemoving)

    if player.Character then
        watchCharacter(player.Character)
    end

    local teamChanged = player:GetPropertyChangedSignal("Team"):Connect(check)
    table.insert(chamConnections, teamChanged)

    check()
end

local function buildChams(state)
    chamsEnabled = state
    cleanUpChams()

    if state ~= true then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        monitorChamPlayer(player)
    end

    local playerAdded = Players.PlayerAdded:Connect(function(player)
        monitorChamPlayer(player)
    end)
    table.insert(chamConnections, playerAdded)

    local playerRemoving = Players.PlayerRemoving:Connect(function(player)
        if player.Character and activeChams[player.Character] then
            pcall(function() activeChams[player.Character]:Destroy() end)
            activeChams[player.Character] = nil
        end
    end)
    table.insert(chamConnections, playerRemoving)
end

--=====================================================
-- HIGHLIGHT TAB
--=====================================================

local HighlightEnabled = false
local ActiveHighlights = {}   -- [Player] = Highlight instance
local TargetUsernames = {}    -- [lowercased username] = true
local PlayerConnections = {}  -- [Player] = CharacterAdded connection

local HIGHLIGHT_COLOR = Color3.fromRGB(220, 170, 255)
local OUTLINE_COLOR = Color3.fromRGB(160, 90, 220)

local function clearHighlight(plr)
    local h = ActiveHighlights[plr]
    if h then
        h:Destroy()
        ActiveHighlights[plr] = nil
    end
end

local function clearAllHighlights()
    for _, h in pairs(ActiveHighlights) do
        h:Destroy()
    end
    table.clear(ActiveHighlights)
end

local function shouldHighlight(plr)
    return TargetUsernames[plr.Name:lower()] == true
end

local function applyHighlight(plr)
    if not HighlightEnabled then return end
    local char = plr.Character
    if not char then return end

    clearHighlight(plr)

    local h = Instance.new("Highlight")
    h.FillColor = HIGHLIGHT_COLOR
    h.OutlineColor = OUTLINE_COLOR
    h.FillTransparency = 0.75
    h.OutlineTransparency = 0.4
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Adornee = char
    h.Parent = char

    ActiveHighlights[plr] = h
end

local function refreshAllTargets()
    if not HighlightEnabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if shouldHighlight(plr) then
            applyHighlight(plr)
        else
            clearHighlight(plr)
        end
    end
end

local function setupPlayerConnections(plr)
    if PlayerConnections[plr] then return end

    PlayerConnections[plr] = plr.CharacterAdded:Connect(function()
        task.wait(0.1)
        if HighlightEnabled and shouldHighlight(plr) then
            applyHighlight(plr)
        end
    end)

    if plr.Character and HighlightEnabled and shouldHighlight(plr) then
        applyHighlight(plr)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayerConnections(plr)
end

local PlayerAddedConn = Players.PlayerAdded:Connect(function(plr)
    setupPlayerConnections(plr)
end)

local PlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
    clearHighlight(plr)
    if PlayerConnections[plr] then
        PlayerConnections[plr]:Disconnect()
        PlayerConnections[plr] = nil
    end
end)

HighlightTab:CreateInput({
    Name = "Usernames",
    CurrentValue = "",
    PlaceholderText = "username, username, username",
    RemoveTextAfterFocusLost = false,
    Flag = "Usernames",
    Callback = function(Text)
        table.clear(TargetUsernames)
        for name in string.gmatch(Text, "([^,]+)") do
            local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed ~= "" then
                TargetUsernames[trimmed:lower()] = true
            end
        end
        refreshAllTargets()
    end,
})

HighlightTab:CreateToggle({
    Name = "Enable Highlights",
    CurrentValue = false,
    Flag = "EnableHighlights",
    Callback = function(Value)
        HighlightEnabled = Value
        if HighlightEnabled then
            refreshAllTargets()
        else
            clearAllHighlights()
        end
    end,
})

HighlightTab:CreateToggle({
    Name = "Item Cham",
    CurrentValue = false,
    Flag = "ItemCham",
    Callback = function(Value)
        buildChams(Value)
    end,
})

--=====================================================
-- MISC TAB
--=====================================================

MiscTab:CreateButton({
    Name = "Destroy Rayfield",
    Callback = function()
        -- reset prompts back to normal
        setBinHoldDuration(3)
        setKeycardHoldDuration(1)

        -- disable + clean up item chams
        buildChams(false)

        -- reset + tear down username highlights
        HighlightEnabled = false
        clearAllHighlights()

        if PlayerAddedConn then PlayerAddedConn:Disconnect() end
        if PlayerRemovingConn then PlayerRemovingConn:Disconnect() end
        for _, conn in pairs(PlayerConnections) do
            conn:Disconnect()
        end
        table.clear(PlayerConnections)

        Rayfield:Destroy()
    end,
})

Rayfield:LoadConfiguration()    