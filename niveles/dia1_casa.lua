-- DÍA 1: CASA - Investigación inicial
-- Radio → Tablero → Cama

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")

local Dia1Casa = {}

-- Referencias que se inicializarán
local OBJ, detective, objetos_interactivos

-- Estados de diálogos
local dialogo_radio, dialogo_detective_radio, dialogo_tablero
local sleeping_state, day1_title_state

-- Audio
local radio_sonido, sonido_pasos
local radio_fade

-- Transición a día 2
local transicion_dia2

-- Estado del juego en este nivel
local fase = "day1_title"  -- "day1_title" | "sleeping" | "playing"
local inicializado = false
local canvas_actual = "casa_canvas"  -- "casa_canvas" | "casa_hoja1"

-- CONFIGURACIÓN: Offset X para detección de cercanía
-- Ajusta este valor si los objetos no se detectan correctamente
local DETECCION_OFFSET_X = 0  -- Cambiar si es necesario (ej: -30, 20, etc.)

-- CONFIGURACIÓN: Límites del canvas (ajusta el área visible de la cámara)
-- offset_left: Ajusta el límite izquierdo (valores positivos = más a la derecha)
-- offset_right: Ajusta el límite derecho (valores positivos = más a la derecha)
local LIMITE_OFFSET_LEFT = 0   -- Ajustar si el canvas se sale por la izquierda
local LIMITE_OFFSET_RIGHT = 0  -- Ajustar si el canvas se sale por la derecha

function Dia1Casa.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio (siempre actualizar para evitar referencias nulas)
  radio_sonido = audio.radio
  sonido_pasos = audio.pasos

  -- Solo inicializar objetos interactivos una vez
  if inicializado then return end
  inicializado = true

  radio_fade = {
    is_fading = false,
    duration = 2.0,
    timer = 0,
    original_volume = 1.0
  }

  -- Copiar objetos interactivos de data
  objetos_interactivos = {}
  for _, obj_data in ipairs(Interactivos.dia1_casa) do
    table.insert(objetos_interactivos, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Estado del título "DÍA 1"
  day1_title_state = {
    activo = true,
    alpha = 0,
    fade_speed = 1.2,
    timer = 0,
    hold = 1.4,
    fase = "in"  -- "in" → "hold" → "out"
  }

  -- Estado de dormir/despertar
  sleeping_state = DialogoSistema.crear(Dialogos.dia1.despertar, {
    activo = false,
    alpha_inicial = 0,
    char_speed = 0.05,
    pause_at_newlines = true,
    on_complete = function()
      sleeping_state.finished_timer = 0
    end
  })
  sleeping_state.finished_timer = 0
  sleeping_state.finished_delay = 2.0
  sleeping_state.cama_alpha = 1.0

  -- Diálogos
  dialogo_radio = nil
  dialogo_detective_radio = nil
  dialogo_tablero = nil

  -- Transición
  transicion_dia2 = nil

  fase = "day1_title"
end

function Dia1Casa.update(dt, tareas, musica_fade)
  -- ===== TÍTULO "DÍA 1" =====
  if fase == "day1_title" then
    if day1_title_state.fase == "in" then
      day1_title_state.alpha = math.min(1, day1_title_state.alpha + day1_title_state.fade_speed * dt)
      if day1_title_state.alpha >= 1 then
        day1_title_state.fase = "hold"
        day1_title_state.timer = 0
      end
    elseif day1_title_state.fase == "hold" then
      day1_title_state.timer = day1_title_state.timer + dt
      if day1_title_state.timer >= day1_title_state.hold then
        day1_title_state.fase = "out"
      end
    else  -- "out"
      day1_title_state.alpha = math.max(0, day1_title_state.alpha - day1_title_state.fade_speed * dt)
      if day1_title_state.alpha <= 0 then
        fase = "sleeping"
        sleeping_state.activo = true
      end
    end
    return nil
  end

  -- ===== ESCENA DORMIR/DESPERTAR =====
  if fase == "sleeping" then
    DialogoSistema.actualizar(sleeping_state, dt)

    if sleeping_state.completo then
      sleeping_state.finished_timer = sleeping_state.finished_timer + dt
      if sleeping_state.finished_timer >= sleeping_state.finished_delay then
        sleeping_state.cama_alpha = sleeping_state.cama_alpha - dt * 2
        if sleeping_state.cama_alpha <= 0 then
          sleeping_state.cama_alpha = 0
          fase = "playing"
          sleeping_state.activo = false
          return "playing"  -- Notificar al main que cambie a estado "playing"
        end
      end
    end
    return nil
  end

  -- ===== TRANSICIÓN DÍA 2 =====
  if transicion_dia2 then
    Transiciones.actualizar(transicion_dia2, dt)
    if transicion_dia2.completa then
      return "day2_wake"  -- Cambiar a día 2
    end
    return nil
  end

  -- ===== JUGANDO =====
  -- Actualizar diálogos activos
  if dialogo_radio then
    DialogoSistema.actualizar(dialogo_radio, dt)

    -- Fade del audio de radio
    if radio_fade.is_fading then
      radio_fade.timer = radio_fade.timer + dt
      local progress = math.min(radio_fade.timer / radio_fade.duration, 1.0)
      radio_sonido:setVolume(radio_fade.original_volume * (1.0 - progress))
      if progress >= 1.0 then
        radio_sonido:stop()
        radio_fade.is_fading = false
      end
    end

    if dialogo_radio.completo then
      -- Iniciar fade de radio
      if not radio_fade.is_fading and not dialogo_radio.fading_out then
        radio_fade.is_fading = true
        radio_fade.timer = 0
        radio_fade.original_volume = radio_sonido:getVolume()
        dialogo_radio.fading_out = true
      end

      -- Fade out del diálogo de radio
      if dialogo_radio.fading_out then
        dialogo_radio.finished_timer = (dialogo_radio.finished_timer or 0) + dt
        if dialogo_radio.finished_timer >= 2.0 then
          dialogo_radio.alpha = math.max(0, dialogo_radio.alpha - dt * 3)
          if dialogo_radio.alpha <= 0 then
            dialogo_radio = nil
            -- Iniciar diálogo del detective
            dialogo_detective_radio = DialogoSistema.crear(Dialogos.dia1.detective_radio, {
              activo = true,
              char_speed = 0.05,
              pause_at_newlines = true
            })
          end
        end
      end
    end
  end

  if dialogo_detective_radio then
    DialogoSistema.actualizar(dialogo_detective_radio, dt)
    if dialogo_detective_radio.completo then
      -- Esperar 2 segundos y hacer fade out
      dialogo_detective_radio.finished_timer = (dialogo_detective_radio.finished_timer or 0) + dt
      if dialogo_detective_radio.finished_timer >= 2.0 then
        dialogo_detective_radio.alpha = math.max(0, dialogo_detective_radio.alpha - dt * 3)
        if dialogo_detective_radio.alpha <= 0 then
          dialogo_detective_radio = nil
          -- Activar tablero y avanzar tarea
          for _, obj in ipairs(objetos_interactivos) do
            if obj.id == "tablero" then
              obj.activo = true
            end
          end
          tareas.actual = 2
        end
      end
    end
  end

  if dialogo_tablero then
    DialogoSistema.actualizar(dialogo_tablero, dt)
    if dialogo_tablero.completo then
      dialogo_tablero.finished_timer = (dialogo_tablero.finished_timer or 0) + dt
      if dialogo_tablero.finished_timer >= 2.0 then
        dialogo_tablero.alpha = math.max(0, dialogo_tablero.alpha - dt * 3)
        if dialogo_tablero.alpha <= 0 then
          dialogo_tablero = nil
          -- Activar cama y avanzar tarea
          for _, obj in ipairs(objetos_interactivos) do
            if obj.id == "cama" then
              obj.activo = true
            end
          end
          tareas.actual = 3
        end
      end
    end
  end

  return nil
end

function Dia1Casa.draw(SCALE, lighting_shader, radio_font)
  if fase == "day1_title" then
    -- Dibujar título "DÍA 1"
    love.graphics.clear(0, 0, 0)
    -- Obtener la fuente grande del título (necesitamos pasarla como parámetro)
    -- Por ahora usar una fuente temporal grande
    local title_font_temp = love.graphics.newFont("fonts/serif.ttf", 96)
    love.graphics.setFont(title_font_temp)
    love.graphics.setColor(1, 1, 1, day1_title_state.alpha)
    local text = "DIA 1"
    local w = title_font_temp:getWidth(text)
    local h = title_font_temp:getHeight()
    love.graphics.print(text, (love.graphics.getWidth() - w) / 2, (love.graphics.getHeight() - h) / 2)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end

  if fase == "sleeping" then
    -- Dibujar escena de dormir
    love.graphics.clear(0, 0, 0)

    -- Cama (dibujar con sprite)
    local camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT, LIMITE_OFFSET_RIGHT)
    love.graphics.setColor(1, 1, 1, sleeping_state.cama_alpha)

    -- Obtener sprite y quad de la cama
    local sprite_casa = OBJ.sprite_casa
    local quad_cama = OBJ.quads.casa.cama_dormi

    if sprite_casa and quad_cama then
      love.graphics.draw(sprite_casa, quad_cama, (12 + camX) * SCALE, (46 + camY) * SCALE, 0, SCALE, SCALE)
    end

    -- Texto
    if sleeping_state.activo then
      DialogoSistema.dibujar(sleeping_state, radio_font, {x=30, y=400, width=700})
    end

    love.graphics.setColor(1, 1, 1, 1)
    return
  end

  -- ===== TRANSICIÓN DÍA 2 =====
  if transicion_dia2 then
    -- Dibujar nivel normalmente
    local camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT, LIMITE_OFFSET_RIGHT)
    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    love.graphics.draw(OBJ.casa_canvas, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Transición encima
    Transiciones.dibujar(transicion_dia2, love.graphics.getFont())
    return
  end

  -- ===== JUGANDO =====
  local camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT, LIMITE_OFFSET_RIGHT)

  -- Shader
  love.graphics.setShader(lighting_shader)
  lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
  lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
  lighting_shader:send("ambient_strength", 0.75)

  -- Casa (usar canvas correcto según el progreso)
  local canvas = (canvas_actual == "casa_hoja1") and OBJ.casa_hoja1 or OBJ.casa_canvas
  love.graphics.draw(canvas, camX * SCALE, camY * SCALE)
  love.graphics.setShader()

  -- Detective
  if detective.visible then
    local frame = detective.animation.frame
    local sx = (detective.animation.direction == "left") and -SCALE or SCALE
    local ox = (detective.animation.direction == "left") and 16 or 0
    love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
  end

  -- Indicador [SPACE] para objetos interactivos
  if not dialogo_radio and not dialogo_detective_radio and not dialogo_tablero then
    local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X, detective.y
    local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos)

    if objeto_cercano then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)
      local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
      love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end

  -- Diálogos
  if dialogo_radio then
    DialogoSistema.dibujar(dialogo_radio, radio_font, {x=30, y=400, width=700})
  end
  if dialogo_detective_radio then
    DialogoSistema.dibujar(dialogo_detective_radio, radio_font, {x=30, y=400, width=700})
  end
  if dialogo_tablero then
    DialogoSistema.dibujar(dialogo_tablero, radio_font, {x=30, y=400, width=700})
  end
end

function Dia1Casa.keypressed(key, tareas)
  if fase ~= "playing" then return nil end

  if key == "space" then
    local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X, detective.y

    -- Buscar objeto cercano
    local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos)

    if objeto_cercano then
      if objeto_cercano.id == "radio" and not dialogo_radio then
        -- Activar radio
        objeto_cercano.activo = false
        radio_sonido:play()
        dialogo_radio = DialogoSistema.crear(Dialogos.dia1.radio, {
          activo = true,
          char_speed = 0.05,
          pause_at_newlines = true
        })
        tareas.actual = 2

      elseif objeto_cercano.id == "tablero" and not dialogo_tablero then
        -- Revisar tablero
        objeto_cercano.activo = false
        canvas_actual = "casa_hoja1"  -- Cambiar a canvas con hoja1 inmediatamente
        dialogo_tablero = DialogoSistema.crear(Dialogos.dia1.detective_tablero, {
          activo = true,
          char_speed = 0.05,
          pause_at_newlines = true
        })
        tareas.actual = 3

      elseif objeto_cercano.id == "cama" then
        -- Dormir → transición a día 2
        objeto_cercano.activo = false
        tareas.actual = 4  -- Avanzar al objetivo del día 2
        transicion_dia2 = Transiciones.crear_transicion_dia(2, function()
          -- Callback cuando la transición termine
        end)
      end
    end
  end

  return nil
end

function Dia1Casa.get_canvas()
  return OBJ.casa_canvas
end

function Dia1Casa.get_detective_inicial()
  return {
    x = 20,
    screen_x = 50,
    y = 21
  }
end

return Dia1Casa
