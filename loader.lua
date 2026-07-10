local ID = game.GameId

local StarterGui = game:GetService("StarterGui")

local gamee = nil

if ID == 6170143659 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/demonology.lua"))()
    gamee = "Demonology"
elseif ID == 2548183080 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/pilgr.lua"))()
    gamee = "Pilgrimed"
elseif ID == 5456952508 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/valley.lua"))()
    gamee = "Valley Prison"
elseif ID == nil then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/lurkgiants.lua"))()
    gamee = "Lurking Giants"
end

if gamee ~= nil then
    StarterGui:SetCore("SendNotification", {
        Title = "Phantom Loading",
        Text = "Loading " .. gamee .. " script...",
        Duration = 5,
    })
end

if gamee == nil then
    StarterGui:SetCore("SendNotification", {
        Title = "Unsupported Game",
        Text = "Phantom does not support this game.",
        Duration = 5,
    })
end