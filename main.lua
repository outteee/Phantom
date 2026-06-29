local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Phantom",
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
      FolderName = "Phantom",
      FileName = "mainConfig"
   },

   Discord = {Enabled = false},

   KeySystem = false,

   Rayfield:LoadConfiguration()
})

local Main = Window:CreateTab("Tab Example", 4483362458)

local Button = Main:CreateButton({
    Name = "Button",
    Callback = function()
        print("Clicked!")
    end
})