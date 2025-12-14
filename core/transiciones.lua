-- Sistema de Transiciones entre Niveles
-- Maneja fade to black, títulos de día, cambios de nivel

local Transiciones = {}

-- Estado de transición activa
Transiciones.activa = false
Transiciones.tipo = nil
Transiciones.progreso = 0

-- Transición de fade a negro simple
function Transiciones.fade_a_negro(duracion, callback)
    return {
        tipo = "fade_negro",
        alpha = 0,
        target_alpha = 1,
        duracion = duracion or 1.0,
        tiempo_transcurrido = 0,
        callback = callback,
        completa = false
    }
end

-- Transición de fade desde negro
function Transiciones.fade_desde_negro(duracion, callback)
    return {
        tipo = "fade_desde_negro",
        alpha = 1,
        target_alpha = 0,
        duracion = duracion or 1.0,
        tiempo_transcurrido = 0,
        callback = callback,
        completa = false
    }
end

-- Transición completa de día: fade out → título → fade in
function Transiciones.crear_transicion_dia(numero_dia, callback)
    return {
        tipo = "transicion_dia",
        numero_dia = numero_dia,
        fase = "iniciado",

        -- Fade a negro
        fade_alpha = 0,
        fade_duracion = 1.5,

        -- Título del día
        titulo_alpha = 0,
        titulo_hold_time = 2.5,
        titulo_fade_speed = 2.0,

        -- Timers
        timer = 0,

        callback = callback,
        completa = false
    }
end

-- Transición con glitch: DÍA 8 que se convierte en DÍA 1
function Transiciones.crear_transicion_glitch_dia8_a_1(callback)
    return {
        tipo = "transicion_glitch",
        fase = "iniciado",

        -- Fade a negro
        fade_alpha = 0,
        fade_duracion = 1.5,

        -- Título que cambia de 8 a 1
        titulo_alpha = 0,
        titulo_hold_time = 2.0,
        titulo_fade_speed = 2.0,
        numero_mostrado = 8,  -- Empieza en 8
        glitch_timer = 0,
        glitch_interval = 0.15,  -- Cada cuanto hacer glitch
        glitch_active = false,

        -- Timers
        timer = 0,

        callback = callback,
        completa = false
    }
end

-- Actualiza una transición simple (fade)
function Transiciones.actualizar_fade(trans, dt)
    if trans.completa then return end

    trans.tiempo_transcurrido = trans.tiempo_transcurrido + dt
    local progreso = math.min(trans.tiempo_transcurrido / trans.duracion, 1.0)

    if trans.tipo == "fade_negro" then
        trans.alpha = progreso
    elseif trans.tipo == "fade_desde_negro" then
        trans.alpha = 1 - progreso
    end

    if progreso >= 1.0 then
        trans.completa = true
        if trans.callback then
            trans.callback()
        end
    end
end

-- Actualiza una transición de día completa
function Transiciones.actualizar_transicion_dia(trans, dt)
    if trans.completa then return end

    trans.timer = trans.timer + dt

    if trans.fase == "iniciado" then
        -- Fade a negro
        trans.fade_alpha = math.min(trans.fade_alpha + (dt / trans.fade_duracion), 1.0)

        if trans.fade_alpha >= 1.0 then
            trans.fase = "pantalla_negra"
            trans.timer = 0
        end

    elseif trans.fase == "pantalla_negra" then
        -- Esperar un momento en negro
        if trans.timer >= 0.5 then
            trans.fase = "mostrar_titulo"
            trans.timer = 0
        end

    elseif trans.fase == "mostrar_titulo" then
        -- Fade in del título
        trans.titulo_alpha = math.min(trans.titulo_alpha + trans.titulo_fade_speed * dt, 1.0)

        if trans.titulo_alpha >= 1.0 and trans.timer >= trans.titulo_hold_time then
            trans.fase = "titulo_fade_out"
            trans.timer = 0
        end

    elseif trans.fase == "titulo_fade_out" then
        -- Fade out del título
        trans.titulo_alpha = math.max(trans.titulo_alpha - trans.titulo_fade_speed * dt, 0)

        if trans.titulo_alpha <= 0 then
            trans.fase = "fade_in_juego"
            trans.timer = 0
        end

    elseif trans.fase == "fade_in_juego" then
        -- Fade desde negro de vuelta al juego
        trans.fade_alpha = math.max(trans.fade_alpha - (dt / trans.fade_duracion), 0)

        if trans.fade_alpha <= 0 then
            trans.fase = "transicion_completa"
            trans.completa = true
            if trans.callback then
                trans.callback()
            end
        end
    end
end

-- Actualiza transición con glitch (DÍA 8 → DÍA 1)
function Transiciones.actualizar_transicion_glitch(trans, dt)
    if trans.completa then return end

    trans.timer = trans.timer + dt
    trans.glitch_timer = trans.glitch_timer + dt

    if trans.fase == "iniciado" then
        -- Fade a negro
        trans.fade_alpha = math.min(trans.fade_alpha + (dt / trans.fade_duracion), 1.0)

        if trans.fade_alpha >= 1.0 then
            trans.fase = "pantalla_negra"
            trans.timer = 0
        end

    elseif trans.fase == "pantalla_negra" then
        -- Esperar un momento en negro
        if trans.timer >= 0.5 then
            trans.fase = "mostrar_titulo"
            trans.timer = 0
        end

    elseif trans.fase == "mostrar_titulo" then
        -- Fade in del título
        trans.titulo_alpha = math.min(trans.titulo_alpha + trans.titulo_fade_speed * dt, 1.0)

        -- Sistema de glitch: titilar entre 8 y 1
        if trans.glitch_timer >= trans.glitch_interval then
            trans.glitch_timer = 0

            -- Generar número que gradualmente se acerca a 1
            local progreso_glitch = math.min(trans.timer / trans.titulo_hold_time, 1.0)

            if progreso_glitch < 0.3 then
                -- Al principio, mostrar solo 8
                trans.numero_mostrado = 8
            elseif progreso_glitch < 0.8 then
                -- En medio, titilar entre 8 y 1
                trans.numero_mostrado = (trans.numero_mostrado == 8) and 1 or 8
            else
                -- Al final, quedarse en 1
                trans.numero_mostrado = 1
            end
        end

        if trans.titulo_alpha >= 1.0 and trans.timer >= trans.titulo_hold_time then
            trans.numero_mostrado = 1  -- Asegurar que termina en 1
            trans.fase = "titulo_fade_out"
            trans.timer = 0
        end

    elseif trans.fase == "titulo_fade_out" then
        -- Fade out del título
        trans.titulo_alpha = math.max(trans.titulo_alpha - trans.titulo_fade_speed * dt, 0)

        if trans.titulo_alpha <= 0 then
            trans.fase = "fade_in_juego"
            trans.timer = 0
        end

    elseif trans.fase == "fade_in_juego" then
        -- Fade desde negro de vuelta al juego
        trans.fade_alpha = math.max(trans.fade_alpha - (dt / trans.fade_duracion), 0)

        if trans.fade_alpha <= 0 then
            trans.fase = "transicion_completa"
            trans.completa = true
            if trans.callback then
                trans.callback()
            end
        end
    end
end

-- Dibuja una transición simple (fade)
function Transiciones.dibujar_fade(trans)
    if trans.alpha > 0 then
        love.graphics.setColor(0, 0, 0, trans.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Dibuja una transición de día completa
function Transiciones.dibujar_transicion_dia(trans, font)
    -- Fade negro
    if trans.fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0, trans.fade_alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    -- Título del día
    if trans.titulo_alpha > 0 and (trans.fase == "mostrar_titulo" or trans.fase == "titulo_fade_out") then
        local titulo_texto = "DIA " .. trans.numero_dia
        -- Crear fuente grande para el título
        local title_font_temp = love.graphics.newFont("fonts/serif.ttf", 96)
        love.graphics.setFont(title_font_temp)
        local w = title_font_temp:getWidth(titulo_texto)
        local h = title_font_temp:getHeight()
        local x = (love.graphics.getWidth() - w) / 2
        local y = (love.graphics.getHeight() - h) / 2

        love.graphics.setColor(1, 1, 1, trans.titulo_alpha)
        love.graphics.print(titulo_texto, x, y)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Dibuja una transición con glitch (DÍA 8 → DÍA 1)
function Transiciones.dibujar_transicion_glitch(trans, font)
    -- Fade negro
    if trans.fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0, trans.fade_alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    -- Título del día con glitch
    if trans.titulo_alpha > 0 and (trans.fase == "mostrar_titulo" or trans.fase == "titulo_fade_out") then
        local titulo_texto = "DIA " .. trans.numero_mostrado
        -- Crear fuente grande para el título
        local title_font_temp = love.graphics.newFont("fonts/serif.ttf", 96)
        love.graphics.setFont(title_font_temp)
        local w = title_font_temp:getWidth(titulo_texto)
        local h = title_font_temp:getHeight()
        local x = (love.graphics.getWidth() - w) / 2
        local y = (love.graphics.getHeight() - h) / 2

        -- Dibujar texto sin movimiento, solo el número cambia
        love.graphics.setColor(1, 1, 1, trans.titulo_alpha)
        love.graphics.print(titulo_texto, x, y)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Función helper para determinar qué tipo de actualización usar
function Transiciones.actualizar(trans, dt)
    if trans.tipo == "transicion_dia" then
        Transiciones.actualizar_transicion_dia(trans, dt)
    elseif trans.tipo == "transicion_glitch" then
        Transiciones.actualizar_transicion_glitch(trans, dt)
    else
        Transiciones.actualizar_fade(trans, dt)
    end
end

-- Función helper para determinar qué tipo de dibujado usar
function Transiciones.dibujar(trans, font)
    if trans.tipo == "transicion_dia" then
        Transiciones.dibujar_transicion_dia(trans, font)
    elseif trans.tipo == "transicion_glitch" then
        Transiciones.dibujar_transicion_glitch(trans, font)
    else
        Transiciones.dibujar_fade(trans)
    end
end

return Transiciones
