fx_version 'cerulean'
game 'gta5'

author 'Revisor System'
description 'Revisor / Hvidvask job med multi-framework bridge'
version '1.4.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'bridge/shared.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/revisor-terminal-logo.png'
}
