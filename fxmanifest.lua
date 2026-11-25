fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kipchak_sobriety'
author 'Kipchak Studios'
description 'Kipchak Sobriety - Breathalyzer and drug test for police'
version '1.0.1'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/tr.lua',
    'shared/utils.lua',
    'bridge/init.lua'
}

server_scripts {
    'server/sv_config.lua',
    'bridge/framework/qbox.lua',
    'bridge/framework/qbcore.lua',
    'bridge/framework/esx.lua',
    'bridge/inventory/ox.lua',
    'bridge/inventory/qb.lua',
    'bridge/inventory/esx.lua',
    'server/levels.lua',
    'server/items.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

dependencies {
    'ox_lib'
}
