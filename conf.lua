local love = require("love")
function love.conf(t)
    --t.identity = "data/saves" -- donde queremos guardar cosas
    --t.version = "1.0.0" -- permite guardar la versión del juego
    --t.console = true --establece si la consola se ejecuta al ejecutar el juego
    --t.externalstorage = true --quieres guardar cosas afuera
    --t.gammacorrect = true --es una cosa de iluminación toda raar
    --t.audio.mic = true -- te pregunta si puedes usar el mic

    t.window.title = "Morel" -- nombre del juego en la ventana
    --t.window.icon = "Icon.jpg" -- le pone icono a la aplicación
    -- NO establecemos width/height fijos, dejamos que fullscreen use la resolución nativa
    --t.window.resizable = true -- permite cambiar el tamaño de ventana
    --t.window.minwidth = 200 -- pone limite
    --t.window.minheight = 200 -- pone limite
    t.window.borderless = true -- le quita el borde de arriba
    t.window.fullscreen = true -- pues fullscreen
    --t.window.fullscreentype = "desktop" -- usa la resolución nativa del monitor
    t.window.display = 1
    --t.window.vsync = 1 -- establece vysinc
    -- No forzamos display específico, usa el monitor donde está la ventana
    --t.window.x = 100 -- si lo quieres poner en un lugar esp
    --t.window.y = 100 -- lo mismo

    --t.modules.timer = False -- desactiva el dt 
end
