-- PRUEBA RESTAURANTE - Para ajustar la escala del restaurante

-- Variables de escala que puedes ajustar en tiempo real
local ESCALA_RESTAURANTE = 10  -- Cambia este número para ajustar el tamaño
local usar_restaurante_sen = false  -- Presiona TAB para cambiar entre restaurante/restaurante_sen

-- Sprites
local restaurante_img
local restaurante_sen_img
local detective_img

-- Canvas
local restaurante_canvas
local restaurante_sen_canvas

-- Detective
local detective = {
  x = 80, y = 48, visible = true,
  animation = { frame = 1, direction = "left" }
}

-- Quads del detective
local detective_quads = {}

function love.load()
  -- Cargar imágenes
  restaurante_img = love.graphics.newImage("sprites/restaurante.png")
  restaurante_sen_img = love.graphics.newImage("sprites/restaurante_sen.png")
  detective_img = love.graphics.newImage("sprites/personaje.png")

  -- Crear quads del detective
  for i = 0, 3 do
    detective_quads[i+1] = love.graphics.newQuad(i*16, 0, 16, 16, 64, 32)
  end

  -- Construir canvas inicial
  construirCanvas()

  print("=== CONTROLES ===")
  print("FLECHAS ARRIBA/ABAJO: Ajustar escala del restaurante")
  print("TAB: Cambiar entre restaurante normal/sentado")
  print("A/D: Mover detective")
  print("R: Reconstruir canvas")
  print("Escala actual: " .. ESCALA_RESTAURANTE)
end

function construirCanvas()
  -- Dimensiones del canvas (basado en 160x96 escalado)
  local WORLD_W = 160
  local WORLD_H = 96

  -- Canvas restaurante normal
  restaurante_canvas = love.graphics.newCanvas(WORLD_W * ESCALA_RESTAURANTE, WORLD_H * ESCALA_RESTAURANTE)
  love.graphics.setCanvas(restaurante_canvas)
  love.graphics.clear()
  love.graphics.scale(ESCALA_RESTAURANTE)
  love.graphics.draw(restaurante_img, 0, 0)
  love.graphics.setCanvas()

  -- Canvas restaurante sentado
  restaurante_sen_canvas = love.graphics.newCanvas(WORLD_W * ESCALA_RESTAURANTE, WORLD_H * ESCALA_RESTAURANTE)
  love.graphics.setCanvas(restaurante_sen_canvas)
  love.graphics.clear()
  love.graphics.scale(ESCALA_RESTAURANTE)
  love.graphics.draw(restaurante_sen_img, 0, 0)
  love.graphics.setCanvas()

  print("Canvas reconstruido con escala: " .. ESCALA_RESTAURANTE)
end

function love.update(dt)
  -- Movimiento del detective
  if love.keyboard.isDown("a") then
    detective.x = detective.x + 50 * dt
    detective.animation.direction = "right"
  elseif love.keyboard.isDown("d") then
    detective.x = detective.x - 50 * dt
    detective.animation.direction = "left"
  end

  -- Animar detective
  detective.animation.frame = math.floor(love.timer.getTime() * 4) % 4 + 1
end

function love.keypressed(key)
  -- Ajustar escala
  if key == "up" then
    ESCALA_RESTAURANTE = ESCALA_RESTAURANTE + 1
    construirCanvas()
  elseif key == "down" then
    ESCALA_RESTAURANTE = math.max(1, ESCALA_RESTAURANTE - 1)
    construirCanvas()
  elseif key == "tab" then
    usar_restaurante_sen = not usar_restaurante_sen
    print("Cambiado a: " .. (usar_restaurante_sen and "restaurante_sen" or "restaurante"))
  elseif key == "r" then
    construirCanvas()
  elseif key == "escape" then
    love.event.quit()
  end
end

function love.draw()
  local ww, wh = love.graphics.getDimensions()

  -- Fondo negro
  love.graphics.clear(0, 0, 0)

  -- Dibujar canvas del restaurante centrado en pantalla
  local canvas = usar_restaurante_sen and restaurante_sen_canvas or restaurante_canvas
  local canvas_w, canvas_h = canvas:getWidth(), canvas:getHeight()
  local offset_x = (ww - canvas_w) / 2
  local offset_y = (wh - canvas_h) / 2

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(canvas, offset_x, offset_y)

  -- Dibujar detective (solo si es restaurante normal)
  if not usar_restaurante_sen and detective.visible then
    love.graphics.push()
    love.graphics.translate(offset_x, offset_y)
    love.graphics.scale(ESCALA_RESTAURANTE)

    if detective.animation.direction == "left" then
      love.graphics.draw(detective_img, detective_quads[detective.animation.frame], detective.x, detective.y)
    else
      love.graphics.draw(detective_img, detective_quads[detective.animation.frame], detective.x, detective.y, 0, -1, 1, 16, 0)
    end

    love.graphics.pop()
  end

  -- Info en pantalla
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Escala actual: " .. ESCALA_RESTAURANTE, 10, 10)
  love.graphics.print("Canvas: " .. (usar_restaurante_sen and "RESTAURANTE_SEN" or "RESTAURANTE"), 10, 30)
  love.graphics.print("Dimensiones canvas: " .. canvas_w .. "x" .. canvas_h, 10, 50)
  love.graphics.print("Dimensiones ventana: " .. ww .. "x" .. wh, 10, 70)
  love.graphics.print("Dimensiones sprite: " .. restaurante_img:getWidth() .. "x" .. restaurante_img:getHeight(), 10, 90)
  love.graphics.print("", 10, 110)
  love.graphics.print("ARRIBA/ABAJO: Ajustar escala", 10, 130)
  love.graphics.print("TAB: Cambiar canvas", 10, 150)
  love.graphics.print("A/D: Mover detective", 10, 170)
  love.graphics.print("R: Reconstruir canvas", 10, 190)

  -- Líneas de referencia para ver el tamaño de pantalla
  love.graphics.setColor(1, 0, 0, 0.5)
  love.graphics.line(0, wh/2, ww, wh/2)  -- Línea horizontal centro
  love.graphics.line(ww/2, 0, ww/2, wh)  -- Línea vertical centro
end
