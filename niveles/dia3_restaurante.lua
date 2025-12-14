-- DÍA 3: RESTAURANTE - Pista clave sobre camisa de unicornio
-- Despertar → Restaurante → Sentarse → Escuchar borrachos → Regresar

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")
local NPCs = require("data.npcs")

local Dia3 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa, objetos_interactivos_restaurante
local npcs_restaurante

-- Audio
local restaurante_sonido, puerta_sonido

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "intro_text" | "restaurante" | "transicion_dia4"

-- Estados
local conversacion_activa
local dialogo_intro
local transicion_dia4
local esta_sentado = false
local canvas_actual = "parado"  -- "parado" | "sentado"

-- CONFIGURACIÓN: Offset X para detección de cercanía
-- Casa: usa detective.screen_x, Restaurante: usa detective.x
local DETECCION_OFFSET_X_CASA = 70  -- Ajustar si es necesario
local DETECCION_OFFSET_X_RESTAURANTE = 0  -- Ajustar si es necesario

-- CONFIGURACIÓN: Offset X para objetos específicos en restaurante
local DETECCION_OFFSET_X_SILLA = 40  -- Offset para silla
local DETECCION_OFFSET_X_PUERTA_REST = 40  -- Offset para puerta del restaurante
local DETECCION_OFFSET_X_BORRACHOS = 0  -- Offset para NPCs borrachos

-- CONFIGURACIÓN: Límites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0   -- Límite izquierdo en casa
local LIMITE_OFFSET_RIGHT_CASA = 0  -- Límite derecho en casa
local LIMITE_OFFSET_LEFT_RESTAURANTE = 0   -- Límite izquierdo en restaurante (usar 0 para movimiento suave)
local LIMITE_OFFSET_RIGHT_RESTAURANTE = 0  -- Límite derecho en restaurante (usar 0 para movimiento suave)

function Dia3.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio
  restaurante_sonido = audio.restaurante
  puerta_sonido = audio.puerta

  -- Objetos interactivos casa día 3
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia3_casa) do
    table.insert(objetos_interactivos_casa, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Objetos interactivos restaurante
  objetos_interactivos_restaurante = {}
  for _, obj_data in ipairs(Interactivos.dia3_restaurante) do
    table.insert(objetos_interactivos_restaurante, InteraccionSistema.crear_objeto(obj_data))
  end

  -- NPCs restaurante
  npcs_restaurante = {}
  for _, npc_data in ipairs(NPCs.dia3_restaurante) do
    local npc = {
      id = npc_data.id,
      x = npc_data.x,
      y = npc_data.y,
      radio = npc_data.radio,
      conversacion_id = npc_data.conversacion_id,
      pregunta_id = npc_data.pregunta_id,
      objetivo_escuchar = npc_data.objetivo_escuchar,
      objetivo_hablar = npc_data.objetivo_hablar,
      estado = {
        conversacion_escuchada = false,
        pregunta_hecha = false
      },
      activo = false  -- Los borrachos solo se activan al sentarse
    }
    table.insert(npcs_restaurante, npc)
  end

  -- Reset posición detective
  detective.x = 20
  detective.screen_x = 50
  detective.y = 21
  detective.animation.direction = "left"
  detective.animation.idle = true
  detective.animation.frame = 1
  detective.visible = true

  fase = "despertar_casa"
  conversacion_activa = nil
  transicion_dia4 = nil
  esta_sentado = false
  canvas_actual = "parado"

  -- Mostrar diálogo de intro cuando despierta en casa
  dialogo_intro = DialogoSistema.crear(Dialogos.dia3.intro, {
    activo = true,
    char_speed = 0.05,
    pause_at_newlines = true
  })
end

function Dia3.update(dt, tareas, musica_fade)
  -- Texto de intro día 3 en casa
  if dialogo_intro and fase == "despertar_casa" then
    DialogoSistema.actualizar(dialogo_intro, dt)
    if dialogo_intro.completo then
      dialogo_intro.finished_timer = (dialogo_intro.finished_timer or 0) + dt
      if dialogo_intro.finished_timer >= 3.0 then
        dialogo_intro.alpha = math.max(0, dialogo_intro.alpha - dt * 2)
        if dialogo_intro.alpha <= 0 then
          dialogo_intro = nil
          -- No cambiar fase aquí, esperar a que vaya al restaurante
        end
      end
    end
  end

  -- Texto de intro en el restaurante (fase intro_text)
  if dialogo_intro and fase == "intro_text" then
    DialogoSistema.actualizar(dialogo_intro, dt)
    if dialogo_intro.completo then
      dialogo_intro.finished_timer = (dialogo_intro.finished_timer or 0) + dt
      if dialogo_intro.finished_timer >= 2.0 then
        dialogo_intro.alpha = math.max(0, dialogo_intro.alpha - dt * 2)
        if dialogo_intro.alpha <= 0 then
          dialogo_intro = nil
          fase = "restaurante"
        end
      end
    end
  end

  -- Actualizar conversación activa
  if conversacion_activa then
    DialogoSistema.Conversacion.actualizar(conversacion_activa, dt)
  end

  -- Transición a día 4
  if transicion_dia4 then
    Transiciones.actualizar(transicion_dia4, dt)
    if transicion_dia4.completa then
      return "day4_wake"
    end
  end

  return nil
end

function Dia3.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  if fase == "despertar_casa" then
    -- Dibujar casa con hoja1 y hoja2 en tablero
    camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CASA, LIMITE_OFFSET_RIGHT_CASA)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.draw(OBJ.casa_hoja2, camX * SCALE, camY * SCALE)
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

    -- Diálogo intro en casa
    if dialogo_intro then
      DialogoSistema.dibujar(dialogo_intro, radio_font, {x=30, y=400, width=700})
    end

  elseif fase == "restaurante" then
    -- Dibujar restaurante (usa detective.screen_x como casa)
    local canvas_rest = (canvas_actual == "sentado") and OBJ.restaurante_sen_canvas or OBJ.restaurante_canvas
    camX, camY = OBJ.clampRestauranteOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_RESTAURANTE, LIMITE_OFFSET_RIGHT_RESTAURANTE)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.7, 0.65, 0.55})
    lighting_shader:send("ambient_strength", 0.65)
    love.graphics.draw(canvas_rest, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective (solo si no está sentado, usa detective.screen_x)
    if detective.visible and not esta_sentado then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Indicador [SPACE] para objetos interactivos y NPCs en restaurante (usa detective.screen_x)
    if fase == "restaurante" and not dialogo_intro and not (conversacion_activa and conversacion_activa.activa) then
      -- Verificar objetos interactivos (silla, puerta) con offsets específicos
      local objeto_encontrado = false

      for _, obj in ipairs(objetos_interactivos_restaurante) do
        -- Saltar silla si ya está sentado
        if obj.id == "silla" and esta_sentado then
          goto continue
        end

        if obj.activo then
          -- Usar offset específico según el objeto
          local offset_x = DETECCION_OFFSET_X_RESTAURANTE
          if obj.id == "silla" then
            offset_x = DETECCION_OFFSET_X_SILLA
          elseif obj.id == "puerta_salir_rest" then
            offset_x = DETECCION_OFFSET_X_PUERTA_REST
          end

          local det_x = detective.screen_x + offset_x

          if InteraccionSistema.esta_cerca(det_x, detective.y, obj.x, obj.y, obj.radio) then
            love.graphics.setFont(radio_font)
            love.graphics.setColor(1, 1, 1, 0.8)
            local texto = "[SPACE] " .. (obj.nombre or obj.id)
            love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
            love.graphics.setColor(1, 1, 1, 1)
            objeto_encontrado = true
            break
          end
        end

        ::continue::
      end

      if not objeto_encontrado then
        -- Verificar NPCs (borrachos)
        local det_x_borrachos = detective.screen_x + DETECCION_OFFSET_X_BORRACHOS

        for _, npc in ipairs(npcs_restaurante) do
          if npc.activo and InteraccionSistema.esta_cerca(det_x_borrachos, detective.y, npc.x, npc.y, npc.radio) then
            love.graphics.setFont(radio_font)
            love.graphics.setColor(1, 1, 1, 0.8)
            local texto = "[SPACE] Borrachos"
            love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
            love.graphics.setColor(1, 1, 1, 1)
            break
          end
        end
      end
    end

    -- Conversación activa
    if conversacion_activa and conversacion_activa.activa then
      DialogoSistema.Conversacion.dibujar(conversacion_activa, radio_font, {x=30, y=400, width=700})
    end
  end

  -- Transición día 4 encima
  if transicion_dia4 then
    Transiciones.dibujar(transicion_dia4, love.graphics.getFont())
  end
end

function Dia3.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local puerta = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if puerta and puerta.id == "puerta_restaurante" then
        -- Ir al restaurante
        puerta_sonido:play()
        fase = "restaurante"  -- Cambiar directamente a restaurante
        detective.screen_x = 50
        detective.x = 0
        detective.y = 25
        restaurante_sonido:setVolume(0.35)  -- Bajar volumen del restaurante
        restaurante_sonido:play()
        tareas.actual = 10  -- Activar objetivo: "Sentarse"

        -- Limpiar diálogo de intro de la casa
        dialogo_intro = nil
      end

    elseif fase == "restaurante" then
      if conversacion_activa and conversacion_activa.activa then
        -- Avanzar conversación
        DialogoSistema.Conversacion.avanzar(conversacion_activa)
        return nil
      end

      -- Verificar silla con offset específico
      local det_x_silla = detective.screen_x + DETECCION_OFFSET_X_SILLA

      for _, obj in ipairs(objetos_interactivos_restaurante) do
        if obj.id == "silla" and obj.activo and not esta_sentado then
          if InteraccionSistema.esta_cerca(det_x_silla, detective.y, obj.x, obj.y, obj.radio) then
            -- Sentarse
            esta_sentado = true
            detective.visible = false
            canvas_actual = "sentado"
            obj.activo = false
            tareas.actual = 11

            -- Activar borrachos e INICIAR conversación automáticamente
            for _, npc in ipairs(npcs_restaurante) do
              if npc.id == "borrachos" then
                npc.activo = true

                -- Iniciar conversación de borrachos automáticamente
                if not npc.estado.conversacion_escuchada then
                  local dialogos_conv = Dialogos.get(npc.conversacion_id)
                  conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_conv, {
                    on_complete = function()
                      npc.estado.conversacion_escuchada = true
                      tareas.actual = 12

                      -- Levantarse para poder hablar con ellos
                      esta_sentado = false
                      detective.visible = true
                      canvas_actual = "parado"
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

      -- Verificar NPCs (borrachos) con offset específico
      local det_x_borrachos = detective.screen_x + DETECCION_OFFSET_X_BORRACHOS
      for _, npc in ipairs(npcs_restaurante) do
        if npc.activo and InteraccionSistema.esta_cerca(det_x_borrachos, detective.y, npc.x, npc.y, npc.radio) then
          if npc.id == "borrachos" then
            if not npc.estado.conversacion_escuchada then
              -- Escuchar conversación de borrachos (PISTA CLAVE)
              local dialogos_conv = Dialogos.get(npc.conversacion_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_conv, {
                on_complete = function()
                  npc.estado.conversacion_escuchada = true
                  tareas.actual = 12

                  -- Levantarse para poder hablar con ellos
                  esta_sentado = false
                  detective.visible = true
                  canvas_actual = "parado"
                end
              })
              DialogoSistema.Conversacion.iniciar(conversacion_activa)

            elseif not npc.estado.pregunta_hecha and not esta_sentado then
              -- Hablar con borrachos
              local dialogos_preg = Dialogos.get(npc.pregunta_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_preg, {
                on_complete = function()
                  npc.estado.pregunta_hecha = true
                  tareas.actual = 13

                  -- Activar puerta para regresar
                  for _, obj in ipairs(objetos_interactivos_restaurante) do
                    if obj.id == "puerta_salir_rest" then
                      obj.activo = true
                    end
                  end
                end
              })
              DialogoSistema.Conversacion.iniciar(conversacion_activa)
            end
          end
          return nil
        end
      end

      -- Verificar puerta de regreso con offset específico
      local det_x_puerta = detective.screen_x + DETECCION_OFFSET_X_PUERTA_REST
      local puerta_rest = InteraccionSistema.encontrar_objeto_cercano({x=det_x_puerta, y=detective.y}, objetos_interactivos_restaurante)
      if puerta_rest and puerta_rest.id == "puerta_salir_rest" then
        -- Regresar a casa y activar transición día 4
        restaurante_sonido:stop()
        puerta_sonido:play()
        fase = "transicion_dia4"
        detective.x = 20
        detective.screen_x = 50
        detective.y = 21
        detective.visible = true

        transicion_dia4 = Transiciones.crear_transicion_dia(4, function()
          -- Callback
        end)
      end
    end
  end

  return nil
end

function Dia3.get_fase()
  return fase
end

function Dia3.is_movimiento_bloqueado()
  -- Bloquear movimiento cuando está sentado
  return esta_sentado
end

return Dia3
