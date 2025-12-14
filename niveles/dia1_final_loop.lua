-- DÍA 1 FINAL LOOP - Escena final de despertar
-- Muestra transición "DIA 1" → Josuelito en cama → Diálogo → Fade a créditos

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local Dialogos = require("data.dialogos")

local Dia1FinalLoop = {}

-- Referencias
local OBJ, detective

-- Estados
local day1_title_state
local sleeping_state
local transicion_creditos
local fase  -- "day1_title" | "sleeping" | "fade_to_credits"

function Dia1FinalLoop.init(obj_ref, detective_ref, audio, tareas)
  OBJ = obj_ref
  detective = detective_ref

  -- Reset posición detective (en la cama)
  detective.x = 20
  detective.screen_x = 50
  detective.y = 21
  detective.animation.direction = "left"
  detective.animation.idle = true
  detective.animation.frame = 1
  detective.visible = true

  -- Estado del título "DÍA 1"
  day1_title_state = {
    activo = true,
    alpha = 0,
    fade_speed = 1.2,
    timer = 0,
    hold = 1.4,
    fase = "in"  -- "in" → "hold" → "out"
  }

  -- Estado de dormir/despertar (mismo diálogo que día 1)
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

  transicion_creditos = nil
  fase = "day1_title"
end

function Dia1FinalLoop.update(dt, tareas, musica_fade)
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
          sleeping_state.activo = false
          fase = "fade_to_credits"

          -- Crear transición a créditos
          transicion_creditos = Transiciones.fade_a_negro(2.0, function()
            -- Callback cuando el fade completa
          end)
        end
      end
    end
    return nil
  end

  -- ===== TRANSICIÓN A CRÉDITOS =====
  if fase == "fade_to_credits" and transicion_creditos then
    Transiciones.actualizar(transicion_creditos, dt)
    if transicion_creditos.completa then
      return "creditos"  -- Ir a pantalla de créditos
    end
  end

  return nil
end

function Dia1FinalLoop.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  -- ===== DIBUJAR TÍTULO "DÍA 1" =====
  if fase == "day1_title" then
    -- Dibujar título "DÍA 1"
    love.graphics.clear(0, 0, 0)
    -- Usar la fuente grande del título (igual que dia1_casa.lua)
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

  -- ===== DIBUJAR ESCENA DE DORMIR =====
  if fase == "sleeping" or fase == "fade_to_credits" then
    -- Dibujar escena de dormir (igual que dia1_casa.lua)
    love.graphics.clear(0, 0, 0)

    -- Cama (dibujar con sprite, igual que dia1_casa.lua)
    local camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, 0, 0)
    love.graphics.setColor(1, 1, 1, sleeping_state.cama_alpha)

    -- Obtener sprite y quad de la cama
    local sprite_casa = OBJ.sprite_casa
    local quad_cama = OBJ.quads.casa.cama_dormi

    if sprite_casa and quad_cama then
      love.graphics.draw(sprite_casa, quad_cama, (12 + camX) * SCALE, (46 + camY) * SCALE, 0, SCALE, SCALE)
    end

    -- Diálogo de despertar
    if sleeping_state.activo then
      DialogoSistema.dibujar(sleeping_state, radio_font, {x=30, y=400, width=700})
    end

    love.graphics.setColor(1, 1, 1, 1)

    -- Transición a créditos
    if transicion_creditos then
      Transiciones.dibujar(transicion_creditos, radio_font)
    end
  end
end

function Dia1FinalLoop.keypressed(key, tareas)
  -- No permitir ninguna interacción
  return nil
end

function Dia1FinalLoop.is_movimiento_bloqueado()
  -- Bloquear todo movimiento
  return true
end

return Dia1FinalLoop
