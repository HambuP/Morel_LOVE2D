-- DÍA 2: CIUDAD - Investigación en el pueblo
-- Despertar → Ciudad → Conversaciones con NPCs → Regresar a casa

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")
local NPCs = require("data.npcs")

local Dia2 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa, objetos_interactivos_ciudad
local npcs_ciudad

-- Audio
local ciudad_sonido, puerta_sonido

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "ciudad" | "transicion_dia3"

-- Conversaciones activas
local conversacion_activa
local transicion_dia3

-- CONFIGURACIÓN: Offset X para detección de cercanía
-- Casa: usa detective.screen_x, Ciudad: usa detective.x
local DETECCION_OFFSET_X_CASA = 70  -- Ajustar si es necesario
local DETECCION_OFFSET_X_CIUDAD = 50  -- Ajustar si es necesario

-- CONFIGURACIÓN: Offset X para detección de NPCs específicos
local DETECCION_OFFSET_X_TRANSEUNTES = -50  -- Offset para transeúntes hombres
local DETECCION_OFFSET_X_VIEJAS = 50       -- Offset para viejas/mujeres

-- CONFIGURACIÓN: Límites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0   -- Límite izquierdo en casa
local LIMITE_OFFSET_RIGHT_CASA = 0  -- Límite derecho en casa
local LIMITE_OFFSET_LEFT_CIUDAD = 0   -- Límite izquierdo en ciudad

-- DEBUG: Mostrar información de NPCs
local DEBUG_MOSTRAR_NPCS = false
local LIMITE_OFFSET_RIGHT_CIUDAD = 0  -- Límite derecho en ciudad

function Dia2.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio
  ciudad_sonido = audio.ciudad
  puerta_sonido = audio.puerta

  -- Objetos interactivos casa día 2
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia2_casa) do
    table.insert(objetos_interactivos_casa, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Objetos interactivos ciudad
  objetos_interactivos_ciudad = {}
  for _, obj_data in ipairs(Interactivos.dia2_ciudad) do
    table.insert(objetos_interactivos_ciudad, InteraccionSistema.crear_objeto(obj_data))
  end

  -- NPCs
  npcs_ciudad = {}
  for _, npc_data in ipairs(NPCs.dia2_ciudad) do
    local npc = {
      id = npc_data.id,
      x = npc_data.x,
      y = npc_data.y,
      radio = npc_data.radio,
      conversacion_id = npc_data.conversacion_id,
      pregunta_id = npc_data.pregunta_id,
      objetivo_escuchar = npc_data.objetivo_escuchar,
      objetivo_preguntar = npc_data.objetivo_preguntar,
      estado = {
        conversacion_escuchada = false,
        pregunta_hecha = false
      },
      activo = (npc_data.id == "transeuntes")  -- Solo transeúntes activos al inicio
    }
    table.insert(npcs_ciudad, npc)
  end

  -- Reset posición detective
  detective.x = 20
  detective.screen_x = 50
  detective.y = 21
  detective.animation.direction = "left"
  detective.animation.idle = true
  detective.animation.frame = 1

  fase = "despertar_casa"
  conversacion_activa = nil
  transicion_dia3 = nil
end

function Dia2.update(dt, tareas, musica_fade)
  -- Actualizar conversación activa
  if conversacion_activa then
    DialogoSistema.Conversacion.actualizar(conversacion_activa, dt)
  end

  -- Transición a día 3
  if transicion_dia3 then
    Transiciones.actualizar(transicion_dia3, dt)
    if transicion_dia3.completa then
      return "day3_wake"
    end
  end

  return nil
end

function Dia2.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  if fase == "despertar_casa" then
    -- Dibujar casa con hoja1 en tablero
    camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CASA, LIMITE_OFFSET_RIGHT_CASA)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.draw(OBJ.casa_hoja1, camX * SCALE, camY * SCALE)
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

  elseif fase == "ciudad" then
    -- Dibujar ciudad (usa detective.screen_x como casa)
    camX, camY = OBJ.clampCityOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CIUDAD, LIMITE_OFFSET_RIGHT_CIUDAD)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.65, 0.63, 0.58})
    lighting_shader:send("ambient_strength", 0.9)  -- Aumentar iluminación en la ciudad
    love.graphics.draw(OBJ.city_canvas, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective en ciudad (usa detective.screen_x como casa)
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Indicador [SPACE] para objetos interactivos y NPCs en ciudad
    if not (conversacion_activa and conversacion_activa.activa) then
      -- Para objetos interactivos: usar detective.screen_x (coordenadas de pantalla)
      local det_screen_x, det_screen_y = detective.screen_x + DETECCION_OFFSET_X_CIUDAD, detective.y
      local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_screen_x, y=det_screen_y}, objetos_interactivos_ciudad)

      if objeto_cercano then
        love.graphics.setFont(radio_font)
        love.graphics.setColor(1, 1, 1, 0.8)
        local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
        love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
        love.graphics.setColor(1, 1, 1, 1)
      else
        -- Para NPCs: usar posición absoluta en el mundo
        local det_world_y = detective.y

        for _, npc in ipairs(npcs_ciudad) do
          -- Usar offset específico según el NPC
          local offset_x = (npc.id == "transeuntes") and DETECCION_OFFSET_X_TRANSEUNTES or DETECCION_OFFSET_X_VIEJAS
          local det_world_x = detective.screen_x - detective.x + offset_x

          if npc.activo and InteraccionSistema.esta_cerca(det_world_x, det_world_y, npc.x, npc.y, npc.radio) then
            love.graphics.setFont(radio_font)
            love.graphics.setColor(1, 1, 1, 0.8)
            local npc_nombre = (npc.id == "transeuntes") and "Transeúntes" or "Viejas"
            local texto = "[SPACE] " .. npc_nombre
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

    -- DEBUG: Mostrar información de NPCs
    if DEBUG_MOSTRAR_NPCS then
      love.graphics.setFont(love.graphics.newFont(14))
      love.graphics.setColor(1, 1, 0, 1)

      -- Posición del detective
      love.graphics.print("Detective: x=" .. math.floor(detective.x) .. " screen_x=" .. math.floor(detective.screen_x) .. " y=" .. math.floor(detective.y), 10, 10)

      -- Información de cada NPC
      local y_offset = 30
      for _, npc in ipairs(npcs_ciudad) do
        local offset_x = (npc.id == "transeuntes") and DETECCION_OFFSET_X_TRANSEUNTES or DETECCION_OFFSET_X_VIEJAS
        local det_world_x = detective.screen_x - detective.x + offset_x
        local det_world_y = detective.y
        local distancia = math.sqrt((det_world_x - npc.x)^2 + (det_world_y - npc.y)^2)

        local texto = npc.id .. ": x=" .. npc.x .. " y=" .. npc.y .. " activo=" .. tostring(npc.activo) .. " dist=" .. math.floor(distancia) .. " radio=" .. npc.radio
        love.graphics.print(texto, 10, y_offset)
        y_offset = y_offset + 20

        -- Dibujar círculo en la posición del NPC (convertir coordenadas del mundo a pantalla)
        love.graphics.setColor(npc.activo and {0, 1, 0, 0.5} or {1, 0, 0, 0.5})
        local npc_screen_x = (npc.x - (detective.x - detective.screen_x)) * SCALE
        local npc_screen_y = npc.y * SCALE
        love.graphics.circle("line", npc_screen_x, npc_screen_y, npc.radio * SCALE)
      end

      love.graphics.setColor(1, 1, 1, 1)
    end
  end

  -- Transición día 3 encima
  if transicion_dia3 then
    Transiciones.dibujar(transicion_dia3, love.graphics.getFont())
  end
end

function Dia2.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local puerta = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if puerta and puerta.id == "puerta_salir" then
        -- Ir a la ciudad
        puerta_sonido:play()
        fase = "ciudad"
        detective.x = 20  -- Posición inicial en ciudad
        detective.y = 20
        ciudad_sonido:setVolume(0.3)  -- Bajar volumen de la ciudad
        ciudad_sonido:play()
        tareas.actual = 5  -- Activar objetivo: "Escuchar conversaciones de transeuntes hombres"
      end

    elseif fase == "ciudad" then
      if conversacion_activa and conversacion_activa.activa then
        -- Avanzar conversación
        DialogoSistema.Conversacion.avanzar(conversacion_activa)
        return nil
      end

      -- Para NPCs: usar posición absoluta en el mundo
      local det_world_y = detective.y

      -- Verificar NPCs
      for _, npc in ipairs(npcs_ciudad) do
        -- Usar offset específico según el NPC
        local offset_x = (npc.id == "transeuntes") and DETECCION_OFFSET_X_TRANSEUNTES or DETECCION_OFFSET_X_VIEJAS
        local det_world_x = detective.screen_x - detective.x + offset_x

        if npc.activo and InteraccionSistema.esta_cerca(det_world_x, det_world_y, npc.x, npc.y, npc.radio) then

          -- Transeúntes
          if npc.id == "transeuntes" then
            if not npc.estado.conversacion_escuchada then
              -- Escuchar conversación
              local dialogos_conv = Dialogos.get(npc.conversacion_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_conv, {
                on_complete = function()
                  npc.estado.conversacion_escuchada = true
                  tareas.actual = 6
                end
              })
              DialogoSistema.Conversacion.iniciar(conversacion_activa)
            elseif not npc.estado.pregunta_hecha then
              -- Preguntar
              local dialogos_preg = Dialogos.get(npc.pregunta_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_preg, {
                on_complete = function()
                  npc.estado.pregunta_hecha = true
                  npc.activo = false  -- Desactivar transeúntes después de ambas conversaciones
                  tareas.actual = 7

                  -- Activar viejas para la siguiente conversación
                  for _, otro_npc in ipairs(npcs_ciudad) do
                    if otro_npc.id == "viejas" then
                      otro_npc.activo = true
                    end
                  end
                end
              })
              DialogoSistema.Conversacion.iniciar(conversacion_activa)
            end

          -- Viejas
          elseif npc.id == "viejas" then
            if not npc.estado.conversacion_escuchada then
              local dialogos_conv = Dialogos.get(npc.conversacion_id)
              conversacion_activa = DialogoSistema.Conversacion.crear(dialogos_conv, {
                on_complete = function()
                  npc.estado.conversacion_escuchada = true
                  npc.activo = false  -- Desactivar viejas después de la conversación
                  tareas.actual = 8
                  -- Activar puerta para regresar
                  for _, obj in ipairs(objetos_interactivos_ciudad) do
                    if obj.id == "puerta_regresar" then
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

      -- Verificar puerta de regreso (usar coordenadas de pantalla)
      local det_screen_x = detective.screen_x + DETECCION_OFFSET_X_CIUDAD
      local puerta = InteraccionSistema.encontrar_objeto_cercano({x=det_screen_x, y=detective.y}, objetos_interactivos_ciudad)
      if puerta and puerta.id == "puerta_regresar" then
        -- Regresar a casa y activar transición día 3
        ciudad_sonido:stop()
        puerta_sonido:play()
        fase = "transicion_dia3"
        detective.x = 20
        detective.screen_x = 50
        detective.y = 21

        transicion_dia3 = Transiciones.crear_transicion_dia(3, function()
          -- Callback
        end)
      end
    end
  end

  return nil
end

function Dia2.get_fase()
  return fase
end

return Dia2
