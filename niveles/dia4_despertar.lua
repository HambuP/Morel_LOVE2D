-- DÍA 4: DESPERTAR EN CASA (PLACEHOLDER)
-- Este nivel es un placeholder para futura implementación

local Dia4 = {}

-- Referencias
local OBJ, detective

-- CONFIGURACIÓN: Límites del canvas
local LIMITE_OFFSET_LEFT = 0   -- Límite izquierdo
local LIMITE_OFFSET_RIGHT = 0  -- Límite derecho

function Dia4.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Reset posición detective
  detective.x = 20
  detective.screen_x = 50
  detective.y = 21
  detective.animation.direction = "left"
  detective.animation.idle = true
  detective.animation.frame = 1
  detective.visible = true
end

function Dia4.update(dt, tareas, musica_fade)
  -- Por ahora, solo permanecer en este nivel
  return nil
end

function Dia4.draw(SCALE, lighting_shader, radio_font)
  -- Dibujar casa con hoja1, hoja2 y hoja3 en tablero
  local camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT, LIMITE_OFFSET_RIGHT)

  love.graphics.setShader(lighting_shader)
  lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
  lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
  lighting_shader:send("ambient_strength", 0.85)
  love.graphics.draw(OBJ.casa_hoja3, camX * SCALE, camY * SCALE)
  love.graphics.setShader()

  -- Detective
  if detective.visible then
    local frame = detective.animation.frame
    local sx = (detective.animation.direction == "left") and -SCALE or SCALE
    local ox = (detective.animation.direction == "left") and 16 or 0
    love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
  end

  -- Mensaje de "Día 4 - Por implementar"
  love.graphics.setFont(radio_font)
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.printf("DIA 4 - Por implementar\n\nPresiona ESC para salir", 30, 200, 700, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

function Dia4.keypressed(key, tareas)
  -- No hay interacciones por ahora
  return nil
end

return Dia4
