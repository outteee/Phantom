local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Phantom",
   Icon = "ghost",
   LoadingTitle = "Phantom (Demonology)",
   LoadingSubtitle = "by outtee",
   ShowText = "Phantom",
   Theme = "Amethyst",

   ToggleUIKeybind = "K",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ScriptID = "sid_9j805m4cxkw3",

   ConfigurationSaving = {
      Enabled = true,
      FolderName = "Phantom",
      FileName = "demonConfig"
   },

   Discord = {Enabled = false},

   KeySystem = false,

   Rayfield:LoadConfiguration()
})

local Main = Window:CreateTab("Tab Example", 4483362458)

local RoomLabel 

local GhostRoomButton = Main:CreateButton({
    Name = "Ghost Room",
    Callback = function()
        local Ghost = workspace:FindFirstChild("Ghost")
        if not Ghost then
            RoomLabel:Set("No Ghost Found") 
            return
        end
        local roomValue = Ghost:GetAttribute("FavoriteRoom")
        RoomLabel:Set("Ghost Room: " .. tostring(roomValue))
    end
})

RoomLabel = Main:CreateLabel("Click Button Above", 4483362458)