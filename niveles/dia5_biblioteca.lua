-- DIA 5: BIBLIOTECA - Investigacion de hechos reales
-- Despertar → Biblioteca

local DialogoSistema = require("core.dialogo_sistema")
local Transiciones = require("core.transiciones")
local InteraccionSistema = require("core.interaccion_sistema")
local Dialogos = require("data.dialogos")
local Interactivos = require("data.interactivos")

local Dia5 = {}

-- Referencias
local OBJ, detective
local objetos_interactivos_casa
local noticia_imagen

-- Audio
local puerta_sonido

-- Fase del nivel
local fase = "despertar_casa"  -- "despertar_casa" | "biblioteca" | "transicion_dia6"

-- Estados
local dialogo_intro
local dialogo_hoja  -- Dialogo al interactuar con hojas
local mostrar_noticia = false
local noticia_timer = 0
local dialogo_post_noticia
local transicion_dia6
local hojas_leidas = {arte = false, deportes = false, noticias = false}
local todas_hojas_leidas = false

-- CONFIGURACION: Offset X para deteccion de cercania
local DETECCION_OFFSET_X_CASA = 70

-- CONFIGURACION: Limites del canvas
local LIMITE_OFFSET_LEFT_CASA = 0
local LIMITE_OFFSET_RIGHT_CASA = 0
local LIMITE_OFFSET_LEFT_BIBLIOTECA = 0
local LIMITE_OFFSET_RIGHT_BIBLIOTECA = 0

-- CONFIGURACION: Posiciones de las hojas en biblioteca
-- Estas son posiciones estimadas, ajustar según sprite
local HOJAS_BIBLIOTECA = {
  {id = "arte", x = 35, y = 25, radio = 15, nombre = "Arte"},
  {id = "deportes", x = 65, y = 25, radio = 15, nombre = "Deportes"},
  {id = "noticias", x = 95, y = 25, radio = 15, nombre = "Noticias"}
}

-- DEBUG: Mostrar información de posición
local DEBUG_MOSTRAR_POSICIONES = false

function Dia5.init(obj_ref, detective_ref, audio)
  OBJ = obj_ref
  detective = detective_ref

  -- Audio
  puerta_sonido = audio.puerta

  -- Cargar imagen de noticia
  noticia_imagen = love.graphics.newImage("sprites/noticia.png")

  -- Objetos interactivos casa dia 5
  objetos_interactivos_casa = {}
  for _, obj_data in ipairs(Interactivos.dia5_casa) do
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
  dialogo_hoja = nil
  mostrar_noticia = false
  noticia_timer = 0
  dialogo_post_noticia = nil
  transicion_dia6 = nil
  hojas_leidas = {arte = false, deportes = false, noticias = false}
  todas_hojas_leidas = false

  -- Mostrar dialogo de intro cuando despierta en casa
  dialogo_intro = DialogoSistema.crear(Dialogos.dia5.intro, {
    activo = true,
    char_speed = 0.05,
    pause_at_newlines = true
  })
end

function Dia5.update(dt, tareas, musica_fade)
  -- Texto de intro dia 5 en casa
  if dialogo_intro and fase == "despertar_casa" then
    DialogoSistema.actualizar(dialogo_intro, dt)
    if dialogo_intro.completo then
      dialogo_intro.finished_timer = (dialogo_intro.finished_timer or 0) + dt
      if dialogo_intro.finished_timer >= 3.0 then
        dialogo_intro.alpha = math.max(0, dialogo_intro.alpha - dt * 2)
        if dialogo_intro.alpha <= 0 then
          dialogo_intro = nil
        end
      end
    end
  end

  -- Dialogo de hojas en biblioteca
  if dialogo_hoja and fase == "biblioteca" then
    DialogoSistema.actualizar(dialogo_hoja, dt)
    if dialogo_hoja.completo then
      dialogo_hoja.finished_timer = (dialogo_hoja.finished_timer or 0) + dt
      if dialogo_hoja.finished_timer >= 1.5 then
        dialogo_hoja.alpha = math.max(0, dialogo_hoja.alpha - dt * 3)
        if dialogo_hoja.alpha <= 0 then
          dialogo_hoja = nil

          -- Si acabamos de leer noticias, mostrar imagen
          if hojas_leidas.noticias and not mostrar_noticia and not dialogo_post_noticia then
            mostrar_noticia = true
            noticia_timer = 0
          end
        end
      end
    end
  end

  -- Mostrar imagen de noticia por 10 segundos
  if mostrar_noticia then
    noticia_timer = noticia_timer + dt
    if noticia_timer >= 15.0 then
      mostrar_noticia = false

      -- Mostrar dialogo post-noticia
      dialogo_post_noticia = DialogoSistema.crear(Dialogos.dia5.hoja_noticias_3, {
        activo = true,
        char_speed = 0.05,
        pause_at_newlines = true
      })
    end
  end

  -- Dialogo post-noticia
  if dialogo_post_noticia and fase == "biblioteca" then
    DialogoSistema.actualizar(dialogo_post_noticia, dt)
    if dialogo_post_noticia.completo then
      dialogo_post_noticia.finished_timer = (dialogo_post_noticia.finished_timer or 0) + dt
      if dialogo_post_noticia.finished_timer >= 2.0 then
        dialogo_post_noticia.alpha = math.max(0, dialogo_post_noticia.alpha - dt * 3)
        if dialogo_post_noticia.alpha <= 0 then
          dialogo_post_noticia = nil
          todas_hojas_leidas = true
          tareas.actual = 19  -- Cambiar objetivo a "Volver a casa y anotar pistas"
        end
      end
    end
  end

  -- Transicion a dia 6
  if transicion_dia6 then
    Transiciones.actualizar(transicion_dia6, dt)
    if transicion_dia6.completa then
      return "day6_wake"
    end
  end

  return nil
end

function Dia5.draw(SCALE, lighting_shader, radio_font)
  local camX, camY

  if fase == "despertar_casa" then
    -- Dibujar casa con hoja4 en tablero
    camX, camY = OBJ.clampHouseOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_CASA, LIMITE_OFFSET_RIGHT_CASA)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.draw(OBJ.casa_hoja4, camX * SCALE, camY * SCALE)
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

  elseif fase == "biblioteca" then
    -- Dibujar biblioteca (placeholder por ahora)
    camX, camY = OBJ.clampBibliotecaOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_BIBLIOTECA, LIMITE_OFFSET_RIGHT_BIBLIOTECA)

    love.graphics.setShader(lighting_shader)
    lighting_shader:send("light_pos", {detective.screen_x * SCALE, detective.y * SCALE})
    lighting_shader:send("ambient_color", {0.2, 0.15, 0.1})
    lighting_shader:send("ambient_strength", 0.7)
    love.graphics.draw(OBJ.biblioteca_canvas, camX * SCALE, camY * SCALE)
    love.graphics.setShader()

    -- Detective (siempre visible)
    if detective.visible then
      local frame = detective.animation.frame
      local sx = (detective.animation.direction == "left") and -SCALE or SCALE
      local ox = (detective.animation.direction == "left") and 16 or 0
      love.graphics.draw(OBJ.sprite_detective, OBJ.quads.detective[frame], detective.screen_x * SCALE, detective.y * SCALE, 0, sx, SCALE, ox, 0)
    end

    -- Calcular la posición del detective relativa al canvas (para detección y debug)
    local detective_canvas_x = detective.screen_x - camX
    local detective_canvas_y = detective.y - camY

    -- Indicadores [SPACE] para hojas en biblioteca (solo si no hay dialogo activo y no ha terminado)
    if not dialogo_hoja and not mostrar_noticia and not dialogo_post_noticia and not todas_hojas_leidas then
      love.graphics.setFont(radio_font)
      local hoja_cercana = nil
      local distancia_minima = math.huge

      for _, hoja in ipairs(HOJAS_BIBLIOTECA) do
        local distancia = math.sqrt((detective_canvas_x - hoja.x)^2 + (detective_canvas_y - hoja.y)^2)

        if distancia < hoja.radio and distancia < distancia_minima then
          distancia_minima = distancia
          hoja_cercana = hoja
        end
      end

      if hoja_cercana then
        love.graphics.setColor(1, 1, 1, 0.8)
        local texto = "[SPACE] " .. hoja_cercana.nombre
        love.graphics.print(texto, detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end

    -- Mostrar indicador "[SPACE] Volver" si ya leyo noticias
    if todas_hojas_leidas and not dialogo_post_noticia and not mostrar_noticia then
      love.graphics.setFont(radio_font)
      love.graphics.setColor(1, 1, 1, 0.8)
      love.graphics.print("[SPACE] Volver", detective.screen_x * SCALE + 10, (detective.y - 10) * SCALE)
      love.graphics.setColor(1, 1, 1, 1)
    end

    -- Dialogo de hoja
    if dialogo_hoja then
      DialogoSistema.dibujar(dialogo_hoja, radio_font, {x=30, y=400, width=700})
    end

    -- Dialogo post-noticia
    if dialogo_post_noticia then
      DialogoSistema.dibujar(dialogo_post_noticia, radio_font, {x=30, y=400, width=700})
    end

    -- Imagen de noticia encima de todo (escalada 3x)
    if mostrar_noticia then
      love.graphics.setColor(0, 0, 0, 0.8)
      love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
      love.graphics.setColor(1, 1, 1, 1)

      local scale_factor = 4
      local img_w = noticia_imagen:getWidth() * scale_factor
      local img_h = noticia_imagen:getHeight() * scale_factor
      local x = (love.graphics.getWidth() - img_w) / 2
      local y = (love.graphics.getHeight() - img_h) / 2
      love.graphics.draw(noticia_imagen, x, y, 0, scale_factor, scale_factor)
    end

    -- DEBUG: Mostrar posiciones de hojas y distancias
    if DEBUG_MOSTRAR_POSICIONES then
      love.graphics.setColor(1, 1, 0, 1)
      love.graphics.print("Detective: screen_x=" .. math.floor(detective.screen_x) .. " y=" .. math.floor(detective.y), 10, 10)
      love.graphics.print("Detective: x=" .. math.floor(detective.x), 10, 25)
      love.graphics.print("Detective canvas: x=" .. math.floor(detective_canvas_x) .. " y=" .. math.floor(detective_canvas_y), 10, 40)

      local y_offset = 65
      for i, hoja in ipairs(HOJAS_BIBLIOTECA) do
        local distancia = math.sqrt((detective_canvas_x - hoja.x)^2 + (detective_canvas_y - hoja.y)^2)
        local texto_debug = hoja.nombre .. ": x=" .. hoja.x .. " y=" .. hoja.y .. " dist=" .. math.floor(distancia)
        love.graphics.print(texto_debug, 10, y_offset)
        y_offset = y_offset + 20

        -- Dibujar círculo en la posición de la hoja (deben moverse igual que el canvas)
        -- Los círculos usan el mismo offset de cámara (camX, camY) que el canvas
        love.graphics.setColor(1, 0, 0, 0.5)
        -- Las coordenadas son relativas al canvas, igual que cuando dibujamos el canvas
        local circle_x = (camX + hoja.x) * SCALE
        local circle_y = (camY + hoja.y) * SCALE
        love.graphics.circle("line", circle_x, circle_y, hoja.radio * SCALE)
      end
      love.graphics.setColor(1, 1, 1, 1)
    end
  end

  -- Transicion dia 6 encima
  if transicion_dia6 then
    Transiciones.dibujar(transicion_dia6, love.graphics.getFont())
  end
end

function Dia5.keypressed(key, tareas)
  if key == "space" then
    if fase == "despertar_casa" then
      local det_x, det_y = detective.screen_x + DETECCION_OFFSET_X_CASA, detective.y
      local puerta = InteraccionSistema.encontrar_objeto_cercano({x=det_x, y=det_y}, objetos_interactivos_casa)

      if puerta and puerta.id == "puerta_biblioteca" then
        -- Ir a la biblioteca
        print("Entrando a biblioteca...")
        fase = "biblioteca"
        detective.screen_x = 50
        detective.x = 0
        detective.y = 25
        tareas.actual = 18  -- Cambiar objetivo a "Buscar pistas"

        -- Limpiar dialogo de intro de la casa
        dialogo_intro = nil
      end

    elseif fase == "biblioteca" then
      -- Si ya termino todo, volver a casa
      if todas_hojas_leidas and not dialogo_post_noticia and not mostrar_noticia then
        puerta_sonido:play()  -- Añadir sonido de puerta al volver
        fase = "transicion_dia6"
        detective.x = 20
        detective.screen_x = 50
        detective.y = 21
        detective.visible = true

        transicion_dia6 = Transiciones.crear_transicion_dia(6, function()
          -- Callback
        end)
        return nil
      end

      -- No hacer nada si hay un dialogo activo o se muestra la noticia
      if dialogo_hoja or mostrar_noticia or dialogo_post_noticia then
        return nil
      end

      -- Detectar hoja cercana
      local camX, camY = OBJ.clampBibliotecaOffset(detective.x, detective.y, LIMITE_OFFSET_LEFT_BIBLIOTECA, LIMITE_OFFSET_RIGHT_BIBLIOTECA)
      local detective_canvas_x = detective.screen_x - camX
      local detective_canvas_y = detective.y - camY

      local hoja_cercana = nil
      local distancia_minima = math.huge

      for _, hoja in ipairs(HOJAS_BIBLIOTECA) do
        local distancia = math.sqrt((detective_canvas_x - hoja.x)^2 + (detective_canvas_y - hoja.y)^2)

        if distancia < hoja.radio and distancia < distancia_minima then
          distancia_minima = distancia
          hoja_cercana = hoja
        end
      end

      if hoja_cercana then
        -- Mostrar dialogo segun la hoja
        if hoja_cercana.id == "arte" then
          hojas_leidas.arte = true
          dialogo_hoja = DialogoSistema.crear(Dialogos.dia5.hoja_arte, {
            activo = true,
            char_speed = 0.05,
            pause_at_newlines = true
          })
        elseif hoja_cercana.id == "deportes" then
          hojas_leidas.deportes = true
          dialogo_hoja = DialogoSistema.crear(Dialogos.dia5.hoja_deportes, {
            activo = true,
            char_speed = 0.05,
            pause_at_newlines = true
          })
        elseif hoja_cercana.id == "noticias" then
          hojas_leidas.noticias = true
          -- Para noticias, mostrar dos dialogos en secuencia
          dialogo_hoja = DialogoSistema.crear(Dialogos.dia5.hoja_noticias_1 .. "\n\n" .. Dialogos.dia5.hoja_noticias_2, {
            activo = true,
            char_speed = 0.05,
            pause_at_newlines = true
          })
        end
      end
    end
  end

  return nil
end

function Dia5.get_fase()
  return fase
end

function Dia5.is_movimiento_bloqueado()
  -- Bloquear movimiento durante imagen de noticia y transiciones
  if mostrar_noticia or transicion_dia6 then
    return true
  end
  return false
end

return Dia5
