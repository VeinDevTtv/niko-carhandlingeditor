Config = {}

-- Permission settings
Config.RequirePermission = false -- Set to true to enable ACE permission check
Config.PermissionAce = "carhandlingeditor" -- ACE permission name

-- Persistence settings
Config.PersistAcrossRestarts = true -- Whether vehicle handling changes persist after server restart
Config.SavePath = "data/handling.json" -- Where to save handling data

-- UI settings
Config.AccentColor = "#40b6ff" -- Light-blue accent color
Config.MobileWidth = 360 -- Mobile UI width for Steam Deck compatibility

-- Notification settings
Config.UseOxLib = false -- Set to true if ox_lib is available for notifications 