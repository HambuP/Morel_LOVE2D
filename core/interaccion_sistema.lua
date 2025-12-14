-- Sistema de Interacciones
-- Detección de proximidad genérica y manejo de objetos interactivos

local InteraccionSistema = {}

-- Calcula la distancia entre dos puntos
function InteraccionSistema.distancia(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Verifica si el detective está cerca de un objeto
function InteraccionSistema.esta_cerca(detective_x, detective_y, objeto_x, objeto_y, radio)
    local dist = InteraccionSistema.distancia(detective_x, detective_y, objeto_x, objeto_y)
    return dist < radio
end

-- Crea un objeto interactivo
function InteraccionSistema.crear_objeto(config)
    return {
        id = config.id,
        x = config.x,
        y = config.y,
        radio = config.radio or 20,
        accion = config.accion,
        activo = config.activo ~= false, -- Por defecto activo
        visible = config.visible ~= false,
        on_interact = config.on_interact,
        datos = config.datos or {}
    }
end

-- Verifica si el detective puede interactuar con un objeto
function InteraccionSistema.puede_interactuar(detective, objeto)
    if not objeto.activo then return false end

    -- Para objetos en ciudad, usar detective.x como posición en el mundo
    -- Para objetos en casa, usar detective.screen_x
    local det_x = detective.x or detective.screen_x
    local det_y = detective.y

    return InteraccionSistema.esta_cerca(det_x, det_y, objeto.x, objeto.y, objeto.radio)
end

-- Encuentra el objeto más cercano con el que se puede interactuar
function InteraccionSistema.encontrar_objeto_cercano(detective, objetos)
    local det_x = detective.x or detective.screen_x
    local det_y = detective.y

    local mas_cercano = nil
    local distancia_minima = math.huge

    for _, objeto in ipairs(objetos) do
        if objeto.activo then
            local dist = InteraccionSistema.distancia(det_x, det_y, objeto.x, objeto.y)
            if dist < objeto.radio and dist < distancia_minima then
                mas_cercano = objeto
                distancia_minima = dist
            end
        end
    end

    return mas_cercano
end

-- Ejecuta la interacción con un objeto
function InteraccionSistema.interactuar(objeto, detective, nivel)
    if not objeto or not objeto.activo then return false end

    if objeto.on_interact then
        objeto.on_interact(detective, nivel)
        return true
    end

    return false
end

-- Dibuja indicador de interacción (opcional, para debug)
function InteraccionSistema.dibujar_indicador(detective, objetos, scale)
    scale = scale or 15

    local det_x = detective.x or detective.screen_x
    local det_y = detective.y

    for _, objeto in ipairs(objetos) do
        if objeto.activo and objeto.visible then
            if InteraccionSistema.esta_cerca(det_x, det_y, objeto.x, objeto.y, objeto.radio) then
                -- Dibujar círculo verde indicando que se puede interactuar
                love.graphics.setColor(0, 1, 0, 0.3)
                love.graphics.circle("fill", objeto.x * scale, objeto.y * scale, objeto.radio * scale)
                love.graphics.setColor(0, 1, 0, 1)
                love.graphics.circle("line", objeto.x * scale, objeto.y * scale, objeto.radio * scale)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end
end

-- Sistema de restricciones de movimiento
InteraccionSistema.Restricciones = {}

function InteraccionSistema.Restricciones.crear(config)
    return {
        min_x = config.min_x or 0,
        max_x = config.max_x or 160,
        min_y = config.min_y or 0,
        max_y = config.max_y or 96,
        margen_izquierdo = config.margen_izquierdo or 20,
        margen_derecho = config.margen_derecho or 12
    }
end

function InteraccionSistema.Restricciones.aplicar_casa(detective, restricciones, view_w)
    view_w = view_w or 160

    -- Clamp screen_x
    if detective.screen_x < restricciones.margen_izquierdo then
        detective.screen_x = restricciones.margen_izquierdo
    end
    if detective.screen_x > view_w - restricciones.margen_derecho then
        detective.screen_x = view_w - restricciones.margen_derecho
    end

    -- Clamp offset (detective.x es el offset de la cámara)
    if detective.x < restricciones.min_x then
        detective.x = restricciones.min_x
    end
    if detective.x > restricciones.max_x then
        detective.x = restricciones.max_x
    end
end

function InteraccionSistema.Restricciones.aplicar_ciudad(detective, restricciones)
    -- Para ciudad, detective.x es la posición en píxeles del mundo
    if detective.x < restricciones.min_x then
        detective.x = restricciones.min_x
    end
    if detective.x > restricciones.max_x then
        detective.x = restricciones.max_x
    end
end

return InteraccionSistema
