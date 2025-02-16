fx_version 'cerulean'
game 'gta5'

author 'itrox'

description 'Money Laundering Script'

lua54 'yes'

client_scripts {
    'config/config.lua',
    'client/client.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
    'config/config.lua',
    'server/server.lua'
}

dependencies {
    'ox_lib'
}