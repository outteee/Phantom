local CalmLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/IcantAffordSynapse/calmlib/refs/heads/main/src.lua"))()
local window = CalmLib:win("Phantom Pilgrammed")
local section1 = window:tab("Main", "rbxassetid://109121102062195")

local MOB_FOLDER_NAME = "Mobs"
local TARGET_NAMES = {}

local CHAM_COLOR = Color3.fromRGB(255, 0, 0)
local CHAM_TRANSPARENCY = 0.5
local activeHighlights = {}
local espEnabled = false

local RollEvent = game:GetService("ReplicatedStorage").Remotes.Roll
local semiInvincible = false

local function isTarget(name)
    for _, t in pairs(TARGET_NAMES) do
        if t == name then return true end
    end
    return false
end

local function addChams(model)
    if activeHighlights[model] then return end
    if not model or not model.Parent then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = CHAM_COLOR
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = CHAM_TRANSPARENCY
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = workspace
    activeHighlights[model] = highlight

    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local box = Instance.new("SelectionBox")
            box.Adornee = part
            box.Color3 = CHAM_COLOR
            box.LineThickness = 0.05
            box.SurfaceTransparency = CHAM_TRANSPARENCY
            box.SurfaceColor3 = CHAM_COLOR
            box.Parent = workspace
            activeHighlights[part] = box
        end
    end
end

local function removeChams(model)
    if activeHighlights[model] then
        activeHighlights[model]:Destroy()
        activeHighlights[model] = nil
    end
    if typeof(model) == "Instance" and model:IsA("Model") then
        for _, part in pairs(model:GetDescendants()) do
            if activeHighlights[part] then
                activeHighlights[part]:Destroy()
                activeHighlights[part] = nil
            end
        end
    end
end

local function removeAllChams()
    for obj, highlight in pairs(activeHighlights) do
        pcall(function() highlight:Destroy() end)
        activeHighlights[obj] = nil
    end
    table.clear(activeHighlights)
end

local function isValidTarget(obj)
    return isTarget(obj.Name)
        and obj.Parent
        and obj.Parent.Parent
        and obj.Parent.Parent.Name == MOB_FOLDER_NAME
        and obj.Parent.Parent.Parent == workspace
end

local function scanForMobs()
    local mobFolder = workspace:FindFirstChild(MOB_FOLDER_NAME)
    if not mobFolder then return end
    for _, zone in pairs(mobFolder:GetChildren()) do
        for _, mob in pairs(zone:GetChildren()) do
            if isTarget(mob.Name) then
                addChams(mob)
            end
        end
    end
end

local function parseTargets(text)
    local names = {}
    for name in text:gmatch("[^,]+") do
        local trimmed = name:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
            table.insert(names, trimmed)
        end
    end
    return names
end

section1:textbox("Mob Names (comma separated, make sure to click enter.)", "", function(text)
    if text and text ~= "" then
        TARGET_NAMES = parseTargets(text)
        if espEnabled then
            removeAllChams()
            scanForMobs()
        end
    end
end)

section1:toggle("ESP", false, function(bool)
    espEnabled = bool
    if bool then
        scanForMobs()
    else
        removeAllChams()
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if not espEnabled then return end
    if isValidTarget(obj) then
        task.defer(function()
            if obj and obj.Parent then
                addChams(obj)
            end
        end)
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    removeChams(obj)
end)

section1:toggle("Semi Invinicible", false, function(bool)
    semiInvincible = bool
    if bool then
        task.spawn(function()
            while semiInvincible do
                RollEvent:FireServer()
                task.wait(0.1)
            end
        end)
    end
end)