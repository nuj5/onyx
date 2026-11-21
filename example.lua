local Onyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/Onyx.lua"))()

local Window = Onyx:CreateWindow({
    Id        = "OnyxExample",
    Title     = "Onyx Hub",
    Subtitle  = "v7  ·  by JustH0bo",
    Logo      = "O",
    Splash    = "H0bo Scripts",
    ToggleKey = Enum.KeyCode.RightAlt,
    Theme     = "winter",
    Credits   = { Name = "JustH0bo", Version = "Onyx v7" },
    OnUnload  = function()
        -- restore anything your script changed here
    end,
})

local Main = Window:AddTab("Main")

local Modules = Main:AddCard({ Title = "Modules", Subtitle = "Enable or disable features", Column = "Left" })
Modules:AddToggle({
    Label = "Speed", Default = true, Flag = "Speed",
    Callback = function(on) print("Speed", on) end,
})
Modules:AddToggle({ Label = "Animations", Default = true, Flag = "Anim" })

local Tuning = Main:AddCard({ Title = "Tuning", Subtitle = "Numbers", Column = "Right" })
local Multiplier = Tuning:AddNumber({
    Label = "Multiplier", Default = 8, Min = 0.1, Max = 200, Flag = "Multiplier",
    Callback = function(v) print("Multiplier", v) end,
})
Tuning:AddKeybind({
    Label = "Panic Key", Default = Enum.KeyCode.V,
    Pressed = function()
        Window:Notify("Stopped", "Everything is off")
        Window:SetStatus("STOPPED", Onyx.Colors.Bad)
    end,
})

local Status = Main:AddCard({ Title = "Status", Subtitle = "Live readout", Column = "Wide" })
local StatusText = Status:AddLabel({ Text = "running", Height = 40 })
Status:AddButton({ Label = "Say hi", Callback = function() Window:Notify("Hi", "Button clicked") end })

task.spawn(function()
    while Window.Alive do
        StatusText:SetText(("multiplier %g | speed %s"):format(Multiplier:Get(), tostring(Window.Flags.Speed)))
        task.wait(0.5)
    end
end)
