# Niko's Car Handling Editor

A FiveM resource that allows players to modify vehicle handling parameters in real-time through a sleek, browser-based UI.

## Features

- Live edit all vehicle handling parameters (mass, acceleration, traction, etc.)
- Organized interface with categories: Dynamics, Traction, Suspension, Damage, and Flags
- Instant preview of changes in-game
- Save and load handling configurations across server restarts
- Permission-based access control
- Mobi`le-friendly UI (works well on Steam Deck)

## Installation

1. Download or clone this repository
2. Place the `niko-carhandlingeditor` folder in your server's `resources` directory
3. Add `ensure niko-carhandlingeditor` to your server.cfg
4. (Optional) Configure permissions with ACE: `add_ace group.admin carhandlingeditor true`

> **Note**: If you rename this resource, make sure to keep the original name in your server.cfg ensure line. 
> Alternatively, adjust all event names in the code to match your new resource name.

## Usage

1. Get in a vehicle as the driver
2. Type `/handling` or `/carhandling` in the chat
3. Use the UI to modify handling parameters:
   - Sliders and number inputs for most values
   - Checkboxes for flag bits
   - Click the category tabs on the left to navigate
4. Changes apply instantly for real-time testing
5. Click "Save" to persist changes across restarts
6. Click "Reset" to revert to original handling
7. Click "Close" to exit the editor (or press ESC)

## Configuration

All configuration options are in `Config.lua`:

```lua
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
```

## Technical Notes

- Handling data is saved based on vehicle hash
- All changes are client-side until saved to the server
- Includes safety limits to prevent exploits
- Vector and flag-based handling parameters fully supported

## Known Issues

- Vector handling bug fixed in v1.0.1 - previous version would return 0 for all vector components

## Version History

- **v1.0.1**: Fixed vector handling bug, improved cross-platform compatibility, added ESC key support
- **v1.0.0**: Initial release

## License

This resource is available under the MIT License. Feel free to modify and share.

## Credits

Developed by Niko 