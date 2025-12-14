-- CRÉDITOS - Pantalla final del juego
-- Muestra los créditos y vuelve al menú principal

local Creditos = {}

-- Estados
local fade_in_alpha
local creditos_timer
local fade_out_alpha
local fase  -- "fade_in" | "mostrar" | "fade_out" | "completado"

-- Configuración
local FADE_IN_DURACION = 1.5
local CREDITOS_DURACION = 8.0
local FADE_OUT_DURACION = 1.5

-- Créditos (textos)
local creditos_texto = {
  {nombre = "LORENZO GALLET", rol = "Artista"},
  {nombre = "YOUSSEF YASSIR", rol = "Guionista"},
  {nombre = "SANTIAGO FORERO", rol = "Programador"}
}

function Creditos.init(obj_ref, detective_ref, audio, tareas)
  fade_in_alpha = 0
  fade_out_alpha = 0
  creditos_timer = 0
  fase = "fade_in"
end

function Creditos.update(dt, tareas, musica_fade)
  if fase == "fade_in" then
    -- Fade in desde negro
    fade_in_alpha = math.min(1, fade_in_alpha + (dt / FADE_IN_DURACION))
    if fade_in_alpha >= 1 then
      fase = "mostrar"
      creditos_timer = 0
    end

  elseif fase == "mostrar" then
    -- Mostrar créditos por CREDITOS_DURACION segundos
    creditos_timer = creditos_timer + dt
    if creditos_timer >= CREDITOS_DURACION then
      fase = "fade_out"
      creditos_timer = 0
    end

  elseif fase == "fade_out" then
    -- Fade out a negro
    fade_out_alpha = math.min(1, fade_out_alpha + (dt / FADE_OUT_DURACION))
    if fade_out_alpha >= 1 then
      fase = "completado"
    end

  elseif fase == "completado" then
    -- Volver al menú principal
    return "menu"
  end

  return nil
end

function Creditos.draw(SCALE, lighting_shader, radio_font)
  local ww, wh = love.graphics.getDimensions()

  -- Fondo negro
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 0, 0, ww, wh)

  -- Dibujar créditos con fade in (si no estamos en fade out completo)
  if fase ~= "completado" and fade_in_alpha > 0 then
    local alpha = fade_in_alpha * (1 - fade_out_alpha)  -- Combinar fade in y fade out
    love.graphics.setColor(1, 1, 1, alpha)

    -- Calcular posición vertical centrada
    local total_height = #creditos_texto * 100  -- Aproximado
    local start_y = (wh - total_height) / 2

    -- Dibujar cada crédito
    for i, credito in ipairs(creditos_texto) do
      local y_offset = start_y + (i - 1) * 100

      -- Nombre (más grande)
      love.graphics.setFont(radio_font)
      local nombre_width = radio_font:getWidth(credito.nombre)
      love.graphics.print(credito.nombre, (ww - nombre_width) / 2, y_offset)

      -- Rol (más pequeño, debajo del nombre)
      love.graphics.setFont(love.graphics.newFont(18))
      local rol_width = love.graphics.getFont():getWidth(credito.rol)
      love.graphics.print(credito.rol, (ww - rol_width) / 2, y_offset + 30)
    end

    love.graphics.setColor(1, 1, 1, 1)
  end

  -- Overlay de fade out (negro encima)
  if fade_out_alpha > 0 then
    love.graphics.setColor(0, 0, 0, fade_out_alpha)
    love.graphics.rectangle("fill", 0, 0, ww, wh)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function Creditos.keypressed(key, tareas)
  -- No hacer nada
  return nil
end

return Creditos
