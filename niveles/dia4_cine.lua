-- DIA 4: CINE - Pista sobre el incidente
-- Despertar → Cine → Sentarse → Escuchar pareja → Regresar

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")
local NPCs = require("data.npcs")

local Dia4 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa, objetos_interactivos_cine
local npcs_cine

-- Audio
local cine_sonido, puerta_sonido

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "cine" | "transicion_dia5"

-- Estados
local conversacion_activa
local dialogo_intro
local dialogo_intro_cine
local transicion_dia5
local esta_sentado = false
local conversacion_terminada = false

-- CONFIGURACION: Offset X para deteccion de cercania
-- Casa: usa detective.screen_x, Cine: usa detective.screen_x (igual que restaurante)
local DETECCION_OFFSET_X_CASA = 70  -- Ajustar si es necesario
local DETECCION_OFFSET_X_CINE = 0  -- Ajustar si es necesario

-- CONFIGURACION: Offset X para objetos especificos en cine
local DETECCION_OFFSET_X_ASIENTO = 70  -- Offset para asiento
local DETECCION_OFFSET_X_PUERTA_CINE = 0  -- Offset para puerta del cine
local DETECCION_OFFSET_X_PAREJA = 0  -- Offset para NPCs pareja

-- CONFIGURACION: Limites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0   -- Limite izquierdo en casa
local LIMITE_OFFSET_RIGHT_CASA = 0  -- Limite derecho en casa
local LIMITE_OFFSET_LEFT_CINE = 0   -- Limite izquierdo en cine (mismo que restaurante)
local LIMITE_OFFSET_RIGHT_CINE = 0  -- Limite derecho en cine (mismo que restaurante)

function Dia4.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio
  cine_sonido = audio.cinema
  puerta_sonido = audio.puerta

  -- Objetos interactivos casa dia 4
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia4_casa) do
    table.insert(objetos_interactivos_casa, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Objetos interactivos cine
  objetos_interactivos_cine = {}
  for _, obj_data in ipairs(Interactivos.dia4_cine) do
    table.insert(objetos_interactivos_cine, InteraccionSistema.crear_objeto(obj_data))
  end

  -- NPCs cine
  npcs_cine = {}
  for _, npc_data in ipairs(NPCs.dia4_cine) do
    local npc = {
      id = npc_data.id,
      x = npc_data.x,
      y = npc_data.y,
      radio = npc_data.radio,
      conversacion_id = npc_data.conversacion_id,
      objetivo_escuchar = npc_data.objetivo_escuchar,
      estado = {
        conversacion_escuchada = false
      },
      activo = false  -- La pareja solo se activa al sentarse
    }
    table.insert(npcs_cine, npc)
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
  conversacion_activa = nil
  dialogo_intro_cine = nil
  transicion_dia5 = nil
  esta_sentado = false
  conversacion_terminada = false

  -- Mostrar dialogo de intro cuando despierta en casa
  dialogo_intro = DialogoSistema.crear(Dialogos.dia4.intro, {
    activo = true,
    char_speed = 0.05,
    pause_at_newlines = true
  })
end

function Dia4.update(dt, tareas, musica_fade)
  -- Texto de intro dia 4 en casa
  if dialogo_intro and fase == "despertar_casa" then
    DialogoSistema.actualizar(dialogo_intro, dt)
    if dialogo_intro.completo then
      dialogo_intro.finished_timer = (dialogo_intro.finished_timer or 0) + dt
      if dialogo_intro.finished_timer >= 3.0 then
        dialogo_intro.alpha = math.max(0, dialogo_intro.alpha - dt * 2)
        if dialogo_intro.alpha <= 0 then
          dialogo_intro = nil
          -- No cambiar fase aqui, esperar a que vaya al cine
        end
      end
    end
  end

  -- Texto de intro en el cine
  if dialogo_intro_cine and fase == "cine" then
    DialogoSistema.actualizar(dialogo_intro_cine, dt)
    if dialogo_intro_cine.completo then
      dialogo_intro_cine.finished_timer = (dialogo_intro_cine.finished_timer or 0) + dt
      if dialogo_intro_cine.finished_timer >= 3.0 then
        dialogo_intro_cine.alpha = math.max(0, dialogo_intro_cine.alpha - dt * 2)
        if dialogo_intro_cine.alpha <= 0 then
          dialogo_intro_cine = nil
        end
      end
    end
  end

  -- Actualizar conversacion activa
  if conversacion_activa then
    DialogoSistema.Conversacion.actualizar(conversacion_activa, dt)
  end

  -- Transicion a dia 5
  if transicion_dia5 then
    Transiciones.actualizar(transicion_dia5, dt)
    if transicion_dia5.completa then
      return "day5_wake"
    end
  end

  return nil
end

function Dia4.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  if fase == "despertar_casa" then
    -- Dibujar casa con hoja3 en tablero
    camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CASA, LIMITE_OFFSET_RIGHT_CASA)

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

    -- Indicador [SPACE] para objetos interactivos en casa
    local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
    local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

    if objeto_cercano then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)
      local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
      love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- Dialogo intro en casa
    if dialogo_intro then
      DialogoSistema.dibujar(dialogo_intro, radio_font, {x=30, y=400, width=700})
    end

  elseif fase == "cine" then
    -- Dibujar cine (usa detective.screen_x como casa)
    camX, camY = OBJ.clampCineOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CINE, LIMITE_OFFSET_RIGHT_CINE)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.2, 0.2, 0.3})
    lighting_shader:send("ambient_strength", 0.5)
    love.graphics.draw(OBJ.cine_canvas, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective (siempre visible en el cine, usa detective.screen_x)
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Indicador [SPACE] simplificado
    if fase == "cine" and not dialogo_intro_cine and not (conversacion_activa and conversacion_activa.activa) then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)

      local texto
      if conversacion_terminada then
        texto = "[SPACE] Volver"
      elseif not esta_sentado then
        texto = "[SPACE] Sentarse"
      end

      if texto then
        love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      end

      love.graphics.setColor(1, 1, 1, 1)
    end

    -- Dialogo intro en cine
    if dialogo_intro_cine then
      DialogoSistema.dibujar(dialogo_intro_cine, radio_font, {x=30, y=400, width=700})
    end

    -- Conversacion activa
    if conversacion_activa and conversacion_activa.activa then
      DialogoSistema.Conversacion.dibujar(conversacion_activa, radio_font, {x=30, y=400, width=700})
    end
  end

  -- Transicion dia 5 encima
  if transicion_dia5 then
    Transiciones.dibujar(transicion_dia5, love.graphics.getFont())
  end
end

function Dia4.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local puerta = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if puerta and puerta.id == "puerta_cine" then
        -- Ir al cine
        puerta_sonido:play()
        fase = "cine"  -- Cambiar directamente a cine
        detective.screen_x = 50
        detective.x = 0
        detective.y = 25
        cine_sonido:setVolume(0.35)  -- Bajar volumen del cine
        cine_sonido:play()
        tareas.actual = 15  -- Activar objetivo: "Sentarse y ver la pelicula"

        -- Limpiar dialogo de intro de la casa
        dialogo_intro = nil

        -- Mostrar dialogo de intro del cine
        dialogo_intro_cine = DialogoSistema.crear(Dialogos.dia4.intro_cine, {
          activo = true,
          char_speed = 0.05,
          pause_at_newlines = true
        })
      end

    elseif fase == "cine" then
      if conversacion_activa and conversacion_activa.activa then
        -- Avanzar conversacion
        DialogoSistema.Conversacion.avanzar(conversacion_activa)
        return nil
      end

      -- Simplificado: SPACE en cualquier parte del cine
      if conversacion_terminada then
        -- La conversacion ya termino, regresar a casa
        cine_sonido:stop()
        puerta_sonido:play()
        fase = "transicion_dia5"
        detective.x = 20
        detective.screen_x = 50
        detective.y = 21
        detective.visible = true

        transicion_dia5 = Transiciones.crear_transicion_dia(5, function()
          -- Callback
        end)
      elseif not esta_sentado then
        -- Sentarse y empezar a escuchar (sin verificar posicion) - detective sigue visible
        esta_sentado = true
        tareas.actual = 15  -- "Sentarse y ver la pelicula"

        -- Limpiar dialogo de intro del cine para evitar superposicion
        dialogo_intro_cine = nil

        -- Iniciar conversacion de pareja automaticamente
        for _, npc in ipairs(npcs_cine) do
          if npc.id == "pareja" then
            npc.activo = true

            if not npc.estado.conversacion_escuchada then
              local dialogos_conv = Dialogos.get(npc.conversacion_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_conv, {
                on_complete = function()
                  npc.estado.conversacion_escuchada = true
                  tareas.actual = 16  -- "Volver a casa y anotar pruebas"
                  conversacion_terminada = true  -- Marcar que termino

                  -- Levantarse
                  esta_sentado = false
                end
              })
              DialogoSistema.Conversacion.iniciar(conversacion_activa)
            end
          end
        end
        return nil
      end
    end
  end

  return nil
end

function Dia4.get_fase()
  return fase
end

function Dia4.is_movimiento_bloqueado()
  -- NO bloquear movimiento durante dialogos ni conversaciones (permitir explorar libremente)
  if transicion_dia5 then
    return true
  end
  return false
end

return Dia4
