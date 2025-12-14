-- Sistema de Diálogos con efecto Typewriter
-- Maneja texto carácter por carácter, pausas, fade in/out y conversaciones

local DialogoSistema = {}

-- Crea un nuevo estado de diálogo
function DialogoSistema.crear(texto_completo, opciones)
    opciones = opciones or {}

    return {
        texto_completo = texto_completo or "",
        texto_visible = "",
        char_index = 0,
        char_timer = 0,
        char_speed = opciones.char_speed or 0.05,

        -- Fade in/out
        alpha = opciones.alpha_inicial or 0,
        fade_speed = opciones.fade_speed or 2.0,
        target_alpha = opciones.target_alpha or 1.0,

        -- Pausas en saltos de línea
        pause_at_newlines = opciones.pause_at_newlines or false,
        pause_timer = 0,
        pause_duration = opciones.pause_duration or 0.8,
        en_pausa = false,

        -- Padding del cuadro de texto
        box_padding = opciones.box_padding or 20,

        -- Callbacks
        on_complete = opciones.on_complete,

        -- Estado
        completo = false,
        activo = opciones.activo or false
    }
end

-- Actualiza el estado del diálogo (typewriter + fade)
function DialogoSistema.actualizar(state, dt)
    if not state.activo then return end

    -- Fade in/out
    if state.alpha < state.target_alpha then
        state.alpha = math.min(state.alpha + state.fade_speed * dt, state.target_alpha)
    elseif state.alpha > state.target_alpha then
        state.alpha = math.max(state.alpha - state.fade_speed * dt, state.target_alpha)
    end

    -- Si ya se mostró todo el texto, marcar como completo
    if state.char_index >= #state.texto_completo then
        if not state.completo then
            state.completo = true
            if state.on_complete then
                state.on_complete()
            end
        end
        return
    end

    -- Manejo de pausas en saltos de línea
    if state.en_pausa then
        state.pause_timer = state.pause_timer + dt
        if state.pause_timer >= state.pause_duration then
            state.en_pausa = false
            state.pause_timer = 0
        end
        return
    end

    -- Efecto typewriter
    state.char_timer = state.char_timer + dt
    if state.char_timer >= state.char_speed then
        state.char_timer = 0
        state.char_index = state.char_index + 1
        state.texto_visible = string.sub(state.texto_completo, 1, state.char_index)

        -- Detectar doble salto de línea para pausar
        if state.pause_at_newlines and state.char_index >= 2 then
            local prev_chars = string.sub(state.texto_completo, state.char_index - 1, state.char_index)
            if prev_chars == "\n\n" then
                state.en_pausa = true
            end
        end
    end
end

-- Dibuja el diálogo en pantalla
function DialogoSistema.dibujar(state, font, posicion)
    if not state.activo or state.alpha <= 0 then return end

    posicion = posicion or {}
    local x = posicion.x or 30
    local y = posicion.y or 400
    local width = posicion.width or 700
    local padding = state.box_padding

    love.graphics.setColor(1, 1, 1, state.alpha)
    love.graphics.setFont(font)

    -- Calcular altura del texto
    local _, wrapped_lines = font:getWrap(state.texto_visible, width)
    local text_height = #wrapped_lines * font:getHeight()

    -- Fondo del cuadro de diálogo
    love.graphics.setColor(0, 0, 0, state.alpha * 0.8)
    love.graphics.rectangle("fill", x - padding, y - padding, width + padding * 2, text_height + padding * 2)

    -- Texto
    love.graphics.setColor(1, 1, 1, state.alpha)
    love.graphics.printf(state.texto_visible, x, y, width, "left")

    love.graphics.setColor(1, 1, 1, 1)
end

-- Sistema de conversaciones (múltiples diálogos en secuencia)
DialogoSistema.Conversacion = {}

function DialogoSistema.Conversacion.crear(mensajes, opciones)
    opciones = opciones or {}

    return {
        mensajes = mensajes, -- Array de {hablante="", texto=""}
        indice_actual = 0,
        dialogo_actual = nil,
        completa = false,
        activa = false,
        on_complete = opciones.on_complete
    }
end

function DialogoSistema.Conversacion.iniciar(conv)
    conv.activa = true
    conv.indice_actual = 1
    DialogoSistema.Conversacion.cargar_dialogo(conv)
end

function DialogoSistema.Conversacion.cargar_dialogo(conv)
    if conv.indice_actual <= #conv.mensajes then
        local mensaje = conv.mensajes[conv.indice_actual]
        conv.dialogo_actual = DialogoSistema.crear(mensaje.texto, {
            activo = true,
            alpha_inicial = 0,
            char_speed = 0.05,
            pause_at_newlines = true
        })
        conv.dialogo_actual.hablante = mensaje.hablante
    else
        conv.completa = true
        conv.activa = false
        if conv.on_complete then
            conv.on_complete()
        end
    end
end

function DialogoSistema.Conversacion.avanzar(conv)
    if not conv.activa then return false end

    if conv.dialogo_actual and conv.dialogo_actual.completo then
        conv.indice_actual = conv.indice_actual + 1
        DialogoSistema.Conversacion.cargar_dialogo(conv)
        return true
    end
    return false
end

function DialogoSistema.Conversacion.actualizar(conv, dt)
    if conv.activa and conv.dialogo_actual then
        DialogoSistema.actualizar(conv.dialogo_actual, dt)
    end
end

function DialogoSistema.Conversacion.dibujar(conv, font, posicion)
    if conv.activa and conv.dialogo_actual then
        DialogoSistema.dibujar(conv.dialogo_actual, font, posicion)

        -- Opcionalmente mostrar nombre del hablante
        if conv.dialogo_actual.hablante and conv.dialogo_actual.alpha > 0 then
            posicion = posicion or {}
            local x = posicion.x or 30
            local y = posicion.y or 400

            love.graphics.setColor(1, 1, 0.5, conv.dialogo_actual.alpha)
            love.graphics.setFont(font)
            love.graphics.print(conv.dialogo_actual.hablante .. ":", x, y - 25)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return DialogoSistema
