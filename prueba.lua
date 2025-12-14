-- prueba.lua
local love = require("love")
package.path = package.path .. ";../?.lua;../?/init.lua;./?.lua;./?/init.lua"

local OBJ = require("objetos")

-- Cámara: usa la misma escala global que tu juego
local SCALE = OBJ.SCALE

-- ===== Config de la “ciudad” para esta prueba =====
local DRAW_SCALE   = 10            -- escala con la que “pegas” sprites dentro del canvas
local FONDO_W, FONDO_H = 128, 64   -- tamaño del sprite 'fondo' en pixeles de imagen
local FONDO_COLS   = 3             -- << quieres 3 fondos de ancho
local FONDO_ROWS   = 2             -- y 2 de alto (ajusta si quieres)

-- Tamaño REAL del canvas en pixeles (lo que de verdad dibujas)
local CANVAS_W = FONDO_W * FONDO_COLS * DRAW_SCALE
local CANVAS_H = FONDO_H * FONDO_ROWS * DRAW_SCALE

local city_canvas
local camX, camY = 0, 0         -- offset de cámara en unidades “mundo” (mundo = pixeles_canvas / SCALE)
local MOVE_SPEED = 40            -- velocidad de scroll en unidades de mundo/seg

-- Clamp de cámara basado en tamaño del canvas (no en WORLD_W/H de la casa)
local function clampCamera(x, y)
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / SCALE, wh / SCALE
  local contentW, contentH = CANVAS_W / SCALE, CANVAS_H / SCALE
  local minX, maxX = view_w - contentW, 0
  local minY, maxY = view_h - contentH, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

function love.load()
  OBJ.init() -- carga imágenes y quads (incluye city)
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Canvas del tamaño de lo que REALMENTE vas a dibujar (3x2 fondos a escala DRAW_SCALE)
  city_canvas = love.graphics.newCanvas(CANVAS_W, CANVAS_H)

  love.graphics.push("all")
  love.graphics.setCanvas(city_canvas)
  love.graphics.clear()

  -- ===== LAYER: Fondo (pegado a escala DRAW_SCALE) =====
  love.graphics.scale(DRAW_SCALE)
  for j = 0, FONDO_ROWS - 1 do
    for i = 0, FONDO_COLS - 1 do
      love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.fondo, FONDO_W * i, FONDO_H * j)
    end
  end
  love.graphics.scale(1/DRAW_SCALE);love.graphics.scale(15)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbol, 72, 1)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbol, 200, 1)
  

  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.posteluz, 220, 1)
  
  for i = 1,20 do
    love.graphics.draw(OBJ.city.sprite.imagen,OBJ.quads.city.piso, 15*(i-1), 50)
  end
  -- aquí puedes seguir “pegando” casas, postes, etc. con la misma lógica:

  for i = 1,30 do
    love.graphics.draw(OBJ.city.sprite.imagen,OBJ.quads.city.fence, 8*(i-1)+50, 35)
  end
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.casa1, 0, 2)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.casa2, 47, 2)

  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.casa3, 100, 2)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.casa4, 170, 2)

  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbusto, 72, 35)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbusto, 92, 35)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbusto, 82, 35)

  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.arbusto, 200, 35)

  

  love.graphics.scale(1/15);love.graphics.scale(12)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.carro1, 173, 34)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.carro2, 270, 34)

  love.graphics.scale(1/12);love.graphics.scale(15)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.pers2, 35, 20)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.pers1, 45, 20,0, -1, 1, 16, 0)

  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.pers3, 175, 20)
  love.graphics.draw(OBJ.city.sprite.imagen, OBJ.quads.city.pers7, 190, 20,0, -1, 1, 16, 0)

  

  

  love.graphics.pop()
  love.graphics.setCanvas()
end

function love.update(dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("a") then dx = dx + MOVE_SPEED * dt end
  if love.keyboard.isDown("d") then dx = dx - MOVE_SPEED * dt end
  if love.keyboard.isDown("w") then dy = dy + MOVE_SPEED * dt end
  if love.keyboard.isDown("s") then dy = dy - MOVE_SPEED * dt end

  if dx ~= 0 or dy ~= 0 then
    camX, camY = clampCamera(camX + dx, camY + dy)
  else
    camX, camY = clampCamera(camX, camY)
  end
end

function love.draw()
  love.graphics.clear(0.05, 0.06, 0.07)
  love.graphics.setColor(1, 1, 1, 1)
  -- Dibuja el canvas según la cámara (camX/camY en “mundo”; se multiplican por SCALE)
  love.graphics.draw(city_canvas, camX * SCALE, camY * SCALE)

  -- HUD debug
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.print(("camX=%.2f  camY=%.2f"):format(camX, camY), 8, 8)
  love.graphics.print("Mover: A/D/W/S", 8, 24)
  love.graphics.print(("Canvas: %dx%d  (cols=%d, rows=%d, scale=%d)")
      :format(CANVAS_W, CANVAS_H, FONDO_COLS, FONDO_ROWS, DRAW_SCALE), 8, 40)
end
