-- DIA 6: INVESTIGACION - Organizar pistas
-- Despertar → Analizar pistas en tablero → Dormir

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")

local Dia6 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "transicion_dia7"

-- Estados
local dialogo_intro
local dialogo_tablero
local transicion_dia7
local analisis_completo = false

-- CONFIGURACION: Offset X para deteccion de cercania
local DETECCION_OFFSET_X_CASA = 70

-- CONFIGURACION: Limites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0
local LIMITE_OFFSET_RIGHT_CASA = 0

function Dia6.init(obj_ref, detective_ref, audio, tareas)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio

  -- Objetos interactivos casa dia 6
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia6_casa) do
    table.insert(objetos_interactivos_casa, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Reset posicion detective
  detective.x = 20
  detective.screen_x = 50
  detective.y = 21
  detective.animation.direction = "left"
  detective.animation.idle = true
  detective.animation.frame = 1
  detective.visible = true

  fase = "despertar_casa"
  dialogo_tablero = nil
  transicion_dia7 = nil
  analisis_completo = false

  -- Establecer objetivo inicial del día 6
  if tareas then
    tareas.actual = 20  -- "Analiza las pistas que tienes"
  end

  -- Mostrar dialogo de intro cuando despierta en casa
  dialogo_intro = DialogoSistema.crear(Dialogos.dia6.intro, {
    activo = true,
    char_speed = 0.05,
    pause_at_newlines = true
  })
end

function Dia6.update(dt, tareas, musica_fade)
  -- Texto de intro dia 6 en casa
  if dialogo_intro and fase == "despertar_casa" then
    DialogoSistema.actualizar(dialogo_intro, dt)
    if dialogo_intro.completo then
      dialogo_intro.finished_timer = (dialogo_intro.finished_timer or 0) + dt
      if dialogo_intro.finished_timer >= 2.0 then
        dialogo_intro.alpha = math.max(0, dialogo_intro.alpha - dt * 3)
        if dialogo_intro.alpha <= 0 then
          dialogo_intro = nil
        end
      end
    end
  end

  -- Dialogo de tablero
  if dialogo_tablero and fase == "despertar_casa" then
    DialogoSistema.actualizar(dialogo_tablero, dt)
    if dialogo_tablero.completo then
      dialogo_tablero.finished_timer = (dialogo_tablero.finished_timer or 0) + dt
      if dialogo_tablero.finished_timer >= 2.0 then
        dialogo_tablero.alpha = math.max(0, dialogo_tablero.alpha - dt * 3)
        if dialogo_tablero.alpha <= 0 then
          dialogo_tablero = nil
          analisis_completo = true

          -- Desactivar tablero y activar cama para dormir
          for _, obj in ipairs(objetos_interactivos_casa) do
            if obj.id == "tablero" then
              obj.activo = false
            elseif obj.id == "cama" then
              obj.activo = true
            end
          end

          tareas.actual = 21  -- "Ve a dormir"
        end
      end
    end
  end

  -- Transicion a dia 7
  if transicion_dia7 then
    Transiciones.actualizar(transicion_dia7, dt)
    if transicion_dia7.completa then
      return "day7_wake"
    end
  end

  return nil
end

function Dia6.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  if fase == "despertar_casa" then
    -- Dibujar casa con hoja5 en tablero
    camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CASA, LIMITE_OFFSET_RIGHT_CASA)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.draw(OBJ.casa_hoja5, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Indicador [SPACE] para objetos interactivos en casa
    local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
    local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

    if objeto_cercano and not dialogo_intro and not dialogo_tablero then
      -- Solo mostrar indicador si el objeto está activo o es el tablero y no se ha completado
      if objeto_cercano.activo or (objeto_cercano.id == "tablero" and not analisis_completo) then
        love.graphics.setFont(radio_font)
        love.graphics.setColor(1, 1, 1, 0.8)
        local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
        love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end

    -- Dialogo intro en casa
    if dialogo_intro then
      DialogoSistema.dibujar(dialogo_intro, radio_font, {x=30, y=400, width=700})
    end

    -- Dialogo tablero
    if dialogo_tablero then
      DialogoSistema.dibujar(dialogo_tablero, radio_font, {x=30, y=400, width=700})
    end
  end

  -- Transicion dia 7 encima
  if transicion_dia7 then
    Transiciones.dibujar(transicion_dia7, love.graphics.getFont())
  end
end

function Dia6.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      -- No hacer nada si hay dialogo activo
      if dialogo_intro or dialogo_tablero then
        return nil
      end

      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local objeto = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if objeto then
        if objeto.id == "tablero" and not analisis_completo then
          -- Analizar pistas en el tablero
          dialogo_tablero = DialogoSistema.crear(Dialogos.dia6.tablero, {
            activo = true,
            char_speed = 0.05,
            pause_at_newlines = true
          })
        elseif objeto.id == "cama" and analisis_completo then
          -- Ir a dormir y transición a día 7
          fase = "transicion_dia7"
          detective.x = 20
          detective.screen_x = 50
          detective.y = 21
          detective.visible = true

          transicion_dia7 = Transiciones.crear_transicion_dia(7, function()
            -- Callback
          end)
        end
      end
    end
  end

  return nil
end

function Dia6.get_fase()
  return fase
end

function Dia6.is_movimiento_bloqueado()
  -- No bloquear movimiento durante dialogos (permitir explorar libremente)
  if transicion_dia7 then
    return true
  end
  return false
end

return Dia6
