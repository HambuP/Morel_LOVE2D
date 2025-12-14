-- objetos.lua
local love = require("love")

local M = {}

-- ====== Constantes de mundo/pixel ======
-- SCALE se calcula dinámicamente en init() basado en resolución
M.SCALE   = 15  -- valor por defecto, se recalcula en init()
M.TILE    = 16
M.WORLD_W = 10 * M.TILE  -- 160px de mundo lógico
M.WORLD_H = 6  * M.TILE  -- 96px de mundo lógico
M.CITY_W = 300

-- ====== Definiciones de sprites y objetos ======
M.tablero = {
  sprite = { path = "sprites/hojas_tablero.png", width = 64, height = 32 },
  objetos = {
    hoja1 = {0,0,16,16}, hoja2 = {16,0,16,16}, hoja3 = {32,0,16,16}, hoja4 = {48,0,16,16},
    hoja5 = {0,16,16,16}, hoja6 = {16,16,16,16}, hoja7 = {32,16,16,16}
  }
}

M.detective = {
  x = 0, y = 21, screen_x = 50,
  visible = true,  -- El detective es visible por defecto
  sprite = { path = "sprites/personaje.png", width = 64, height = 32, quad_width = 16 },
  animation = { direction = "right", idle = true, frame = 1, max_frames = 4, speed = 0.2, timer = 0 }
}

M.casa = {
  sprite = { path = "sprites/casa.png", width = 128, height = 64 },
  objetos = {
    radio = {0,0,16,12},
    mesa_noche = {0,12,16,20},
    cama = {16,0,25,16},
    cama_dormi = {48,0,28,16},
    pared = {16,16,16,16},
    piso = {32,32,16,7},
    puerta = {48,32,16,32},
    tablero = {80,0,45,39},
    mueble1_coc = {0,44,16,20},
    mueble2_coc = {32,44,16,20},
    lampara = {16,32,16,16},
    ventana = {32,16,16,16}
  }
}

M.city = {
  sprite = {path = "sprites/city.png", width = 265, height = 128},
  objetos = {
    fondo   = {0,0,128,64},
    casa1   = {0,64,49,48},
    casa2   = {49,64,33,48},
    casa3   = {82,64,50,48},
    casa4   = {132,64,33,48},
    pers1   = {134,0,16,32},
    pers2   = {150,0,16,32},
    pers3   = {166,0,16,32},
    pers4   = {182,0,16,32},
    pers5   = {198,0,16,32},
    pers6   = {214,0,16,32},
    pers7   = {230,0,16,32},
    pers8   = {246,0,16,32},
    carro1  = {133,32,48,32},
    carro2  = {181,32,48,32},
    posteluz= {230,32,36,64},
    arbol   = {166,64,32,50},
    arbusto = {198,64,16,16},
    fence   = {207,80,16,16},
    piso    = {67,112,15,16},
    pizza   = {48,112,16,16},
    basurita= {32,112,16,16},
    silla   = {16,112,16,16},
    mesa    = {0,112,16,16}
  }
}

M.restaurante = {
  sprite = {path = "sprites/restaurante.png", width = 160, height = 96}
}

M.restaurante_sen = {
  sprite = {path = "sprites/restaurante_sen.png", width = 160, height = 96}
}

M.cine = {
  sprite = {path = "sprites/cine.png", width = 160, height = 96}
}

M.biblioteca = {
  sprite = {path = "sprites/biblioteca.png", width = 160, height = 96}
}

M.callejon = {
  sprite = {path = "sprites/callejon.png", width = 160, height = 96}
}

-- ====== Config del canvas de ciudad (igual a tu prueba.lua) ======
M.city_cfg = {
  DRAW_SCALE = 10,        -- escala con la que “pegas” sprites dentro del canvas
  FONDO_W    = 128,
  FONDO_H    = 64,
  COLS       = 3,         -- 3 fondos a lo ancho
  ROWS       = 2          -- 2 fondos a lo alto
}

-- Contenedores que llenaremos en init()
M.quads       = { casa = {}, tablero = {}, detective = {}, city = {} }
M.casa_canvas = nil
M.casa_hoja1  = nil
M.casa_hoja2  = nil
M.casa_hoja3  = nil
M.casa_hoja4  = nil
M.casa_hoja5  = nil
M.city_canvas = nil
M.restaurante_canvas = nil
M.restaurante_sen_canvas = nil
M.cine_canvas = nil
M.biblioteca_canvas = nil
M.callejon_canvas = nil

-- Tamaño real del canvas de ciudad en pixeles
M.CITY_W_PX = M.city_cfg.FONDO_W * M.city_cfg.COLS * M.city_cfg.DRAW_SCALE
M.CITY_H_PX = M.city_cfg.FONDO_H * M.city_cfg.ROWS * M.city_cfg.DRAW_SCALE

-- ====== Helpers ======
local function buildQuads(defs, w, h)
  local q = {}
  for nombre, d in pairs(defs) do
    q[nombre] = love.graphics.newQuad(d[1], d[2], d[3], d[4], w, h)
  end
  return q
end

-- ====== Construir canvas de CASA base ======
local function buildCasaCanvas()
  M.casa_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_canvas)
  love.graphics.clear()

  -- Base a escala 15
  love.graphics.scale(15)
  for i = 1,6 do
    for j = 1,10 do
      love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.pared, 16*(j-1), 16*(i-1))
    end
  end
  for i = 1,10 do
    love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.piso, 16*(i-1), 50)
  end
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.cama,   0,   38)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.puerta, 140, 19)

  -- Objetos a "escala 10"
  love.graphics.scale(1/15); love.graphics.scale(10)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.mesa_noche, 45, 58)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.radio,      85, 46)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.tablero,   148, 18)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.mueble1_coc, 85, 58)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.mueble1_coc,117, 58)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.mueble2_coc,101, 58)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.lampara,    45, 42)

  -- Ventana a "escala 20"
  love.graphics.scale(1/10); love.graphics.scale(20)
  love.graphics.draw(M.casa.sprite.imagen, M.quads.casa.ventana, 3, 12)

  love.graphics.pop()
end

-- ====== Construir canvas de CASA con hoja1 en tablero ======
local function buildCasaHoja1()
  local HOJA_OFFSET_X_10 = 15
  local HOJA_OFFSET_Y_10 = 12
  local TABLERO_X_10, TABLERO_Y_10 = 148, 18

  M.casa_hoja1 = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_hoja1)
  love.graphics.clear()
  love.graphics.draw(M.casa_canvas, 0, 0)

  love.graphics.scale(10)
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA_OFFSET_X_10,
    TABLERO_Y_10 + HOJA_OFFSET_Y_10
  )
  love.graphics.pop()
end

-- ====== Construir canvas de CASA con hoja1 y hoja2 en tablero ======
local function buildCasaHoja2()
  local HOJA1_OFFSET_X_10 = 15
  local HOJA1_OFFSET_Y_10 = 12
  local HOJA2_OFFSET_X_10 = 25  -- Desplazada un poco más a la derecha
  local HOJA2_OFFSET_Y_10 = 18  -- Desplazada un poco más abajo
  local TABLERO_X_10, TABLERO_Y_10 = 148, 18

  M.casa_hoja2 = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_hoja2)
  love.graphics.clear()
  love.graphics.draw(M.casa_canvas, 0, 0)

  love.graphics.scale(10)
  -- Dibujar hoja1
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA1_OFFSET_X_10,
    TABLERO_Y_10 + HOJA1_OFFSET_Y_10
  )
  -- Dibujar hoja2
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja2,
    TABLERO_X_10 + HOJA2_OFFSET_X_10,
    TABLERO_Y_10 + HOJA2_OFFSET_Y_10
  )
  love.graphics.pop()
end

-- ====== Construir canvas de CASA con hoja1, hoja2 y hoja3 en tablero ======
local function buildCasaHoja3()
  local HOJA1_OFFSET_X_10 = 15
  local HOJA1_OFFSET_Y_10 = 12
  local HOJA2_OFFSET_X_10 = 25
  local HOJA2_OFFSET_Y_10 = 18
  local HOJA3_OFFSET_X_10 = 35  -- Tercera hoja más a la derecha
  local HOJA3_OFFSET_Y_10 = 24  -- Tercera hoja más abajo
  local TABLERO_X_10, TABLERO_Y_10 = 148, 18

  M.casa_hoja3 = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_hoja3)
  love.graphics.clear()
  love.graphics.draw(M.casa_canvas, 0, 0)

  love.graphics.scale(10)
  -- Dibujar hoja1
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA1_OFFSET_X_10,
    TABLERO_Y_10 + HOJA1_OFFSET_Y_10
  )
  -- Dibujar hoja2
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja2,
    TABLERO_X_10 + HOJA2_OFFSET_X_10,
    TABLERO_Y_10 + HOJA2_OFFSET_Y_10
  )
  -- Dibujar hoja3
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja3,
    TABLERO_X_10 + HOJA3_OFFSET_X_10,
    TABLERO_Y_10 + HOJA3_OFFSET_Y_10
  )
  love.graphics.pop()
end

local function buildCasaHoja4()
  local HOJA1_OFFSET_X_10 = 15
  local HOJA1_OFFSET_Y_10 = 12
  local HOJA2_OFFSET_X_10 = 25
  local HOJA2_OFFSET_Y_10 = 18
  local HOJA3_OFFSET_X_10 = 35
  local HOJA3_OFFSET_Y_10 = 24
  local HOJA4_OFFSET_X_10 = 18  -- Cuarta hoja
  local HOJA4_OFFSET_Y_10 = 35  -- Cuarta hoja más abajo
  local TABLERO_X_10, TABLERO_Y_10 = 148, 18

  M.casa_hoja4 = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_hoja4)
  love.graphics.clear()
  love.graphics.draw(M.casa_canvas, 0, 0)

  love.graphics.scale(10)
  -- Dibujar hoja1
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA1_OFFSET_X_10,
    TABLERO_Y_10 + HOJA1_OFFSET_Y_10
  )
  -- Dibujar hoja2
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja2,
    TABLERO_X_10 + HOJA2_OFFSET_X_10,
    TABLERO_Y_10 + HOJA2_OFFSET_Y_10
  )
  -- Dibujar hoja3
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja3,
    TABLERO_X_10 + HOJA3_OFFSET_X_10,
    TABLERO_Y_10 + HOJA3_OFFSET_Y_10
  )
  -- Dibujar hoja4
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja4,
    TABLERO_X_10 + HOJA4_OFFSET_X_10,
    TABLERO_Y_10 + HOJA4_OFFSET_Y_10
  )
  love.graphics.pop()
end

-- ====== Construir canvas de RESTAURANTE (parado) ======
local function buildRestauranteCanvas()
  M.restaurante_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.restaurante_canvas)
  love.graphics.clear()

  -- Escala ajustada para que coincida con el tamaño de ventana (escala 7)
  love.graphics.scale(7)
  love.graphics.draw(M.restaurante.sprite.imagen, 0, 0)

  love.graphics.pop()
end

-- ====== Construir canvas de RESTAURANTE (sentado) ======
local function buildRestauranteSenCanvas()
  M.restaurante_sen_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.restaurante_sen_canvas)
  love.graphics.clear()

  -- Escala ajustada para que coincida con el tamaño de ventana (escala 7)
  love.graphics.scale(7)
  love.graphics.draw(M.restaurante_sen.sprite.imagen, 0, 0)

  love.graphics.pop()
end

-- ====== Construir canvas de CINE ======
local function buildCineCanvas()
  M.cine_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.cine_canvas)
  love.graphics.clear()

  -- Escala ajustada para que coincida con el tamaño de ventana (escala 7)
  love.graphics.scale(7)
  love.graphics.draw(M.cine.sprite.imagen, 0, 0)

  love.graphics.pop()
end

local function buildBibliotecaCanvas()
  M.biblioteca_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.biblioteca_canvas)
  love.graphics.clear()

  -- Escala ajustada para que coincida con el tamaño de ventana (escala 7)
  love.graphics.scale(7)
  love.graphics.draw(M.biblioteca.sprite.imagen, 0, 0)

  love.graphics.pop()
end

-- ====== Construir canvas de CALLEJON ======
local function buildCallejonCanvas()
  M.callejon_canvas = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.callejon_canvas)
  love.graphics.clear()

  -- Escala ajustada para que coincida con el tamaño de ventana (escala 14)
  love.graphics.scale(14)
  love.graphics.draw(M.callejon.sprite.imagen, 0, 0)

  love.graphics.pop()
end

-- ====== Construir canvas de CASA con 5 HOJAS ======
local function buildCasaHoja5()
  local TABLERO_X_10, TABLERO_Y_10 = 148, 18

  M.casa_hoja5 = love.graphics.newCanvas(M.WORLD_W * M.SCALE, M.WORLD_H * M.SCALE)
  love.graphics.push("all")
  love.graphics.setCanvas(M.casa_hoja5)
  love.graphics.clear()

  -- Dibujar el canvas de casa base
  love.graphics.draw(M.casa_canvas, 0, 0)

  -- Escalar a 10 para dibujar las hojas en el tablero
  love.graphics.scale(10)

  -- Hoja 1
  local HOJA1_OFFSET_X_10 = 0
  local HOJA1_OFFSET_Y_10 = 0
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA1_OFFSET_X_10,
    TABLERO_Y_10 + HOJA1_OFFSET_Y_10
  )

  -- Hoja 2
  local HOJA2_OFFSET_X_10 = 5
  local HOJA2_OFFSET_Y_10 = 6
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja2,
    TABLERO_X_10 + HOJA2_OFFSET_X_10,
    TABLERO_Y_10 + HOJA2_OFFSET_Y_10
  )

  -- Hoja 3
  local HOJA3_OFFSET_X_10 = 10
  local HOJA3_OFFSET_Y_10 = 12
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja3,
    TABLERO_X_10 + HOJA3_OFFSET_X_10,
    TABLERO_Y_10 + HOJA3_OFFSET_Y_10
  )

  -- Hoja 4
  local HOJA4_OFFSET_X_10 = 15
  local HOJA4_OFFSET_Y_10 = 18
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja4,
    TABLERO_X_10 + HOJA4_OFFSET_X_10,
    TABLERO_Y_10 + HOJA4_OFFSET_Y_10
  )

  -- Hoja 5
  local HOJA5_OFFSET_X_10 = 20
  local HOJA5_OFFSET_Y_10 = 24
  love.graphics.draw(
    M.tablero.sprite.imagen,
    M.quads.tablero.hoja1,
    TABLERO_X_10 + HOJA5_OFFSET_X_10,
    TABLERO_Y_10 + HOJA5_OFFSET_Y_10
  )
  love.graphics.pop()
end

-- ====== Construir canvas de CIUDAD (como en tu prueba.lua) ======
local function buildCityCanvas()
  local cfg = M.city_cfg
  M.CITY_W_PX = cfg.FONDO_W * cfg.COLS * cfg.DRAW_SCALE
  M.CITY_H_PX = cfg.FONDO_H * cfg.ROWS * cfg.DRAW_SCALE

  M.city_canvas = love.graphics.newCanvas(M.CITY_W_PX, M.CITY_H_PX)
  love.graphics.push("all")
  love.graphics.setCanvas(M.city_canvas)
  love.graphics.clear()

  -- Fondo tilado a escala DRAW_SCALE
  love.graphics.scale(cfg.DRAW_SCALE)
  for j = 0, cfg.ROWS - 1 do
    for i = 0, cfg.COLS - 1 do
      love.graphics.draw(M.city.sprite.imagen, M.quads.city.fondo, cfg.FONDO_W * i, cfg.FONDO_H * j)
    end
  end

  -- Repite tus mismos "bloques de escalas" y coordenadas
  love.graphics.scale(1/cfg.DRAW_SCALE); love.graphics.scale(15)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbol,     72,  1)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbol,     200, 1)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.posteluz,  220, 1)

  for i = 1,20 do
    love.graphics.draw(M.city.sprite.imagen, M.quads.city.piso, 15*(i-1), 50)
  end
  for i = 1,30 do
    love.graphics.draw(M.city.sprite.imagen, M.quads.city.fence, 8*(i-1)+50, 35)
  end

  love.graphics.draw(M.city.sprite.imagen, M.quads.city.casa1,  0,   2)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.casa2,  47,  2)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.casa3,  100, 2)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.casa4,  170, 2)

  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbusto, 72, 35)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbusto, 92, 35)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbusto, 82, 35)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.arbusto, 200, 35)

  love.graphics.scale(1/15); love.graphics.scale(12)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.carro1, 173, 34)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.carro2, 270, 34)

  love.graphics.scale(1/12); love.graphics.scale(15)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.pers2, 35, 20)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.pers1, 45, 20, 0, -1, 1, 16, 0)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.pers3, 175, 20)
  love.graphics.draw(M.city.sprite.imagen, M.quads.city.pers7, 190, 20, 0, -1, 1, 16, 0)

  love.graphics.pop()
  love.graphics.setCanvas()
end

-- ====== API: inicializar recursos y prerender ======
function M.init()
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- SCALE fijo (el que funcionaba originalmente)
  M.SCALE = 15

  -- Cargar imágenes
  M.tablero.sprite.imagen   = love.graphics.newImage(M.tablero.sprite.path)
  M.detective.sprite.imagen = love.graphics.newImage(M.detective.sprite.path)
  M.casa.sprite.imagen      = love.graphics.newImage(M.casa.sprite.path)
  M.city.sprite.imagen      = love.graphics.newImage(M.city.sprite.path)
  M.restaurante.sprite.imagen = love.graphics.newImage(M.restaurante.sprite.path)
  M.restaurante_sen.sprite.imagen = love.graphics.newImage(M.restaurante_sen.sprite.path)
  M.cine.sprite.imagen = love.graphics.newImage(M.cine.sprite.path)
  M.biblioteca.sprite.imagen = love.graphics.newImage(M.biblioteca.sprite.path)
  M.callejon.sprite.imagen = love.graphics.newImage(M.callejon.sprite.path)

  -- Quads
  M.quads.tablero = buildQuads(M.tablero.objetos, M.tablero.sprite.width, M.tablero.sprite.height)
  M.quads.casa    = buildQuads(M.casa.objetos,    M.casa.sprite.width,    M.casa.sprite.height)
  M.quads.city    = buildQuads(M.city.objetos,    M.city.sprite.width,    M.city.sprite.height)

  -- Quads del detective (animación)
  for i = 1, M.detective.animation.max_frames do
    M.quads.detective[i] = love.graphics.newQuad(
      M.detective.sprite.quad_width * (i-1), 0,
      M.detective.sprite.quad_width, M.detective.sprite.height,
      M.detective.sprite.width, M.detective.sprite.height
    )
  end

  -- Canvases prerender
  buildCasaCanvas()
  buildCasaHoja1()
  buildCasaHoja2()
  buildCasaHoja3()
  buildCasaHoja4()
  buildCasaHoja5()
  buildCityCanvas()
  buildRestauranteCanvas()
  buildRestauranteSenCanvas()
  buildCineCanvas()
  buildBibliotecaCanvas()
  buildCallejonCanvas()

  -- Alias para facilitar acceso a sprites
  M.sprite_casa = M.casa.sprite.imagen
  M.sprite_detective = M.detective.sprite.imagen
  M.sprite_city = M.city.sprite.imagen
  M.sprite_tablero = M.tablero.sprite.imagen
end

-- ====== Utilidades para el main ======
function M.clampHouseOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 0
  offset_right = offset_right or 0
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local minX = (view_w - M.WORLD_W) + offset_left
  local maxX = 0 + offset_right
  local minY, maxY = view_h - M.WORLD_H, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

-- Clamp específico para el canvas de ciudad (usa su tamaño real)
function M.clampCityOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 0
  offset_right = offset_right or 0
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local contentW, contentH = (M.CITY_W_PX)/M.SCALE, (M.CITY_H_PX)/M.SCALE
  local minX = (view_w - contentW) + offset_left
  local maxX = 0 + offset_right
  local minY, maxY = view_h - contentH, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

-- Clamp para restaurante (ajustado para evitar bordes negros sin trabar el movimiento)
function M.clampRestauranteOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 5  -- Default margen izquierdo
  offset_right = offset_right or -5  -- Default margen derecho (negativo)
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local minX = (view_w - M.WORLD_W) + offset_left
  local maxX = offset_right
  local minY, maxY = view_h - M.WORLD_H, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

function M.clampCineOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 0  -- Default margen izquierdo (mismo que restaurante)
  offset_right = offset_right or 0  -- Default margen derecho (mismo que restaurante)
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local minX = (view_w - M.WORLD_W) + offset_left
  local maxX = offset_right
  local minY, maxY = view_h - M.WORLD_H, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

function M.clampBibliotecaOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 0  -- Default margen izquierdo
  offset_right = offset_right or 0  -- Default margen derecho
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local minX = (view_w - M.WORLD_W) + offset_left
  local maxX = offset_right
  local minY, maxY = view_h - M.WORLD_H, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

function M.clampCallejonOffset(x, y, offset_left, offset_right)
  offset_left = offset_left or 0  -- Default margen izquierdo
  offset_right = offset_right or 0  -- Default margen derecho
  local ww, wh = love.graphics.getDimensions()
  local view_w, view_h = ww / M.SCALE, wh / M.SCALE
  local minX = (view_w - M.WORLD_W) + offset_left
  local maxX = offset_right
  local minY, maxY = view_h - M.WORLD_H, 0
  local cx = math.max(minX, math.min(maxX, x))
  local cy = math.max(minY, math.min(maxY, y))
  return cx, cy
end

function M.getDetectiveWorldPos()
  local world_x = M.detective.screen_x - M.detective.x
  local world_y = M.detective.y
  return world_x, world_y
end

function M.distance(ax, ay, bx, by)
  local dx, dy = ax-bx, ay-by
  return math.sqrt(dx*dx + dy*dy)
end

function M.isNear(ax, ay, bx, by, r)
  local dx, dy = ax-bx, ay-by
  return dx*dx + dy*dy <= r*r
end

return M
