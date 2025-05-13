fx_version 'cerulean'
game 'gta5'

author 'niko'
description 'Live handling editor with clean NUI'
version '1.0.0'

ui_page 'html/index.html'

client_scripts { 'Config.lua', 'client/client.lua' }
server_scripts { 'Config.lua', 'server/server.lua' }

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
} 