fx_version 'cerulean'
game 'gta5'

name 'survival-cooking'
description 'Sistema de cocina de supervivencia con minijuego interactivo'
author 'Tu Nombre'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'
