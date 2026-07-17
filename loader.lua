local ID = game.GameId

local StarterGui = game:GetService("StarterGui")

local gamee = nil

local function dateCheck()
	local currentTime = os.date("*t")
	local currentMonth = currentTime.month
	local currentDay = currentTime.day

	local targetMonth = 7
	local targetDay = 22

	if currentMonth > targetMonth then
		return true
	elseif currentMonth == targetMonth and currentDay >= targetDay then
		return true
	else
		return false
	end
end

if ID == 6170143659 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/demonology.lua"))()
    gamee = "Demonology"
elseif ID == 2548183080 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/pilgr.lua"))()
    gamee = "Pilgrimed"
elseif ID == 5456952508 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/valley.lua"))()
    gamee = "Valley Prison"
elseif ID == 2339944792 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/lurkgiants.lua"))()
    gamee = "Lurking Giants"
end

if dateCheck() then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/outteee/Phantom/main/valley2.lua"))()
    gamee = "Valley Prison Gen 2"
end

if gamee ~= nil then
    StarterGui:SetCore("SendNotification", {
        Title = "Phantom Loaded",
        Text = "Loaded " .. gamee .. " script...",
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