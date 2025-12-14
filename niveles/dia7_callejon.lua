-- DIA 7: CALLEJON CASARES - Descubrimiento final
-- Despertar → Ir al callejón → Investigar basura

local DialogoSistema = require("core.dialogo_sistema")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")
local Transiciones = require("core.transiciones")

local Dia7 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa
local objetos_interactivos_callejon

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "en_callejon"

-- Estados
local dialogo_llegada
local dialogo_basura
local dialogo_revelacion
local mostrar_imagen_basura = false
local imagen_basura
local tiempo_espera_revelacion = 0
local TIEMPO_ANTES_REVELACION = 1.5  -- Segundos antes de mostrar la revelacion
local transicion_final  -- Transicion al final del juego

-- CONFIGURACION: Offset X para deteccion de cercania
local DETECCION_OFFSET_X_CASA = 70
local DETECCION_OFFSET_X_CALLEJON = 70

-- CONFIGURACION: Limites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0
local LIMITE_OFFSET_RIGHT_CASA = 0
local LIMITE_OFFSET_LEFT_CALLEJON = 0
local LIMITE_OFFSET_RIGHT_CALLEJON = 0

-- DEBUG: Mostrar información de posición
local DEBUG_MOSTRAR_POSICIONES = false

function Dia7.init(obj_ref, detective_ref, audio, tareas)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio

  -- Objetos interactivos casa dia 7
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia7_casa) do
    table.insert(objetos_interactivos_casa, InteraccionSistema.crear_objeto(obj_data))
  end

  -- Objetos interactivos callejon dia 7
  objetos_interactivos_callejon = {}
  for _, obj_data in ipairs(Interactivos.dia7_callejon) do
    table.insert(objetos_interactivos_callejon, InteraccionSistema.crear_objeto(obj_data))
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
  dialogo_llegada = nil
  dialogo_basura = nil
  dialogo_revelacion = nil
  mostrar_imagen_basura = false
  tiempo_espera_revelacion = 0
  transicion_final = nil

  -- Cargar imagen de basura
  imagen_basura = love.graphics.newImage("sprites/basura.png")

  -- Establecer objetivo inicial del día 7
  if tareas then
    tareas.actual = 22  -- "Visita el callejon Casares"
  end
end

function Dia7.update(dt, tareas, musica_fade)
  -- Dialogo de llegada al callejon
  if dialogo_llegada and fase == "en_callejon" then
    DialogoSistema.actualizar(dialogo_llegada, dt)
    if dialogo_llegada.completo then
      dialogo_llegada.finished_timer = (dialogo_llegada.finished_timer or 0) + dt
      if dialogo_llegada.finished_timer >= 2.0 then
        dialogo_llegada.alpha = math.max(0, dialogo_llegada.alpha - dt * 3)
        if dialogo_llegada.alpha <= 0 then
          dialogo_llegada = nil

          -- Activar basura para investigar
          for _, obj in ipairs(objetos_interactivos_callejon) do
            if obj.id == "basura" then
              obj.activo = true
            end
          end

          tareas.actual = 24  -- "Investigar basura"
        end
      end
    end
  end

  -- Dialogo de investigar basura
  if dialogo_basura and fase == "en_callejon" then
    DialogoSistema.actualizar(dialogo_basura, dt)
    if dialogo_basura.completo then
      dialogo_basura.finished_timer = (dialogo_basura.finished_timer or 0) + dt
      if dialogo_basura.finished_timer >= 2.0 then
        dialogo_basura.alpha = math.max(0, dialogo_basura.alpha - dt * 3)
        if dialogo_basura.alpha <= 0 then
          dialogo_basura = nil
          -- Mostrar imagen de basura y esperar antes de la revelación
          mostrar_imagen_basura = true
          tiempo_espera_revelacion = 0
        end
      end
    end
  end

  -- Esperar antes de mostrar la revelación "EL CADAVER SOY YO"
  if mostrar_imagen_basura and not dialogo_revelacion then
    tiempo_espera_revelacion = tiempo_espera_revelacion + dt
    if tiempo_espera_revelacion >= TIEMPO_ANTES_REVELACION then
      dialogo_revelacion = DialogoSistema.crear(Dialogos.dia7.revelacion_cadaver, {
        activo = true,
        char_speed = 0.05,
        pause_at_newlines = true
      })
    end
  end

  -- Actualizar dialogo de revelación
  if dialogo_revelacion then
    DialogoSistema.actualizar(dialogo_revelacion, dt)

    -- Después del diálogo de revelación, esperar 3 segundos y crear transición con glitch
    if dialogo_revelacion.completo and not transicion_final then
      dialogo_revelacion.finished_timer = (dialogo_revelacion.finished_timer or 0) + dt
      if dialogo_revelacion.finished_timer >= 3.0 then
        -- Ocultar la imagen de basura antes de la transición
        mostrar_imagen_basura = false
        -- Crear transición con glitch: DÍA 8 → DÍA 1
        transicion_final = Transiciones.crear_transicion_glitch_dia8_a_1(function()
          -- Callback cuando la transición completa
        end)
      end
    end
  end

  -- Actualizar transición final
  if transicion_final then
    Transiciones.actualizar(transicion_final, dt)
    if transicion_final.completa then
      return "day1_final_loop"  -- Ir al loop final del día 1
    end
  end

  return nil
end

function Dia7.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  -- Si hay transición final activa, solo dibujar la transición (pantalla negra con glitch)
  if transicion_final then
    Transiciones.dibujar(transicion_final, radio_font)
    return
  end

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

    if objeto_cercano and objeto_cercano.activo then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)
      local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
      love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      love.graphics.setColor(1, 1, 1, 1)
    end

  elseif fase == "en_callejon" then
    -- Dibujar callejon
    camX, camY = OBJ.clampCallejonOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CALLEJON, LIMITE_OFFSET_RIGHT_CALLEJON)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.15, 0.12, 0.1})
    lighting_shader:send("ambient_strength", 0.85)  -- Aumentar iluminación del callejón
    love.graphics.draw(OBJ.callejon_canvas, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Calcular la posición del detective relativa al canvas (para detección y debug)
    local detective_canvas_x = detective.screen_x - camX
    local detective_canvas_y = detective.y - camY

    -- Indicador [SPACE] para objetos interactivos en callejon (usar coordenadas de canvas)
    local det_x, det_y = detective_canvas_x, detective_canvas_y
    local objeto_cercano = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_callejon)

    if objeto_cercano and objeto_cercano.activo and not dialogo_llegada and not dialogo_basura then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)
      local texto = "[SPACE] " .. (objeto_cercano.nombre or objeto_cercano.id)
      love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- DEBUG: Mostrar posiciones de basura y distancias
    if DEBUG_MOSTRAR_POSICIONES then
      love.graphics.setColor(1, 1, 0, 1)
      love.graphics.print("Detective: screen_x=" .. math.floor(detective.screen_x) .. " y=" .. math.floor(detective.y), 10, 10)
      love.graphics.print("Detective: x=" .. math.floor(detective.x), 10, 25)
      love.graphics.print("Detective canvas: x=" .. math.floor(detective_canvas_x) .. " y=" .. math.floor(detective_canvas_y), 10, 40)
      love.graphics.print("camX=" .. math.floor(camX) .. " camY=" .. math.floor(camY), 10, 55)

      local y_offset = 80
      for i, obj in ipairs(objetos_interactivos_callejon) do
        local distancia = math.sqrt((detective_canvas_x - obj.x)^2 + (detective_canvas_y - obj.y)^2)
        local texto_debug = obj.id .. ": x=" .. obj.x .. " y=" .. obj.y .. " dist=" .. math.floor(distancia) .. " activo=" .. tostring(obj.activo)
        love.graphics.print(texto_debug, 10, y_offset)
        y_offset = y_offset + 20

        -- Dibujar círculo en la posición del objeto
        love.graphics.setColor(1, 0, 0, 0.5)
        local circle_x = (camX + obj.x) * SCALE
        local circle_y = (camY + obj.y) * SCALE
        love.graphics.circle("line", circle_x, circle_y, obj.radio * SCALE)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- Dialogo de llegada
    if dialogo_llegada then
      DialogoSistema.dibujar(dialogo_llegada, radio_font, {x=30, y=400, width=700})
    end

    -- Dialogo de basura
    if dialogo_basura then
      DialogoSistema.dibujar(dialogo_basura, radio_font, {x=30, y=400, width=700})
    end
  end

  -- Mostrar imagen de basura en pantalla completa
  if mostrar_imagen_basura then
    local ww, wh = love.graphics.getDimensions()
    love.graphics.setColor(1, 1, 1, 1)

    -- Escalar la imagen para cubrir toda la pantalla
    local img_w = imagen_basura:getWidth()
    local img_h = imagen_basura:getHeight()
    local scale_x = ww / img_w
    local scale_y = wh / img_h
    local scale = math.max(scale_x, scale_y)  -- Usar el mayor para cubrir toda la pantalla

    love.graphics.draw(imagen_basura, 0, 0, 0, scale, scale)

    -- Dialogo de revelación sobre la imagen (texto grande y centrado con fondo oscuro)
    if dialogo_revelacion and dialogo_revelacion.activo then
      -- Usar el texto visible (con efecto de escritura) del sistema de diálogo
      local texto_visible = dialogo_revelacion.texto_visible or ""

      -- Crear fuente más grande (sin cambiar el estilo)
      local fuente_grande = love.graphics.newFont(48)
      love.graphics.setFont(fuente_grande)

      -- Calcular tamaño del texto completo para el fondo (no solo lo visible)
      local texto_completo = Dialogos.dia7.revelacion_cadaver
      local texto_width = fuente_grande:getWidth(texto_completo)
      local texto_height = fuente_grande:getHeight()
      local x = (ww - texto_width) / 2
      local y = wh * 0.75  -- Posición más abajo (75% desde arriba)

      -- Dibujar fondo oscuro semi-transparente
      local padding = 30
      love.graphics.setColor(0, 0, 0, 0.7)
      love.graphics.rectangle("fill", x - padding, y - padding, texto_width + padding * 2, texto_height + padding * 2)

      -- Dibujar texto centrado y grande (solo lo que se ha escrito hasta ahora)
      love.graphics.setColor(1, 1, 1, dialogo_revelacion.alpha or 1)
      love.graphics.print(texto_visible, x, y)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end

end

function Dia7.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      -- No hacer nada si hay dialogo activo
      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local objeto = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if objeto and objeto.id == "puerta_salir" then
        -- Ir al callejón (teletransporte directo)
        fase = "en_callejon"
        detective.screen_x = 50
        detective.x = 0
        detective.y = 25
        detective.animation.direction = "right"
        detective.visible = true

        -- Mostrar dialogo de llegada
        dialogo_llegada = DialogoSistema.crear(Dialogos.dia7.llegada_callejon, {
          activo = true,
          char_speed = 0.05,
          pause_at_newlines = true
        })

        tareas.actual = 23  -- "Investigar"
      end

    elseif fase == "en_callejon" then
      -- No hacer nada si hay dialogo activo
      if dialogo_llegada or dialogo_basura then
        return nil
      end

      -- Calcular coordenadas relativas al canvas
      local camX, camY = OBJ.clampCallejonOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CALLEJON, LIMITE_OFFSET_RIGHT_CALLEJON)
      local detective_canvas_x = detective.screen_x - camX
      local detective_canvas_y = detective.y - camY

      local det_x, det_y = detective_canvas_x, detective_canvas_y
      local objeto = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_callejon)

      if objeto and objeto.id == "basura" and objeto.activo then
        -- Investigar basura
        dialogo_basura = DialogoSistema.crear(Dialogos.dia7.investigar_basura, {
          activo = true,
          char_speed = 0.05,
          pause_at_newlines = true
        })
      end
    end
  end

  return nil
end

function Dia7.get_fase()
  return fase
end

function Dia7.is_movimiento_bloqueado()
  -- No bloquear movimiento durante dialogos (permitir explorar libremente)
  return false
end

return Dia7
