-- main.lua - Versión Refactorizada
-- LA INVENCIÓN DE MOREL
-- Sistema modular simplificado

local love = require("love")

-- ==================== CONFIGURACIÓN DE DEBUG ====================
-- Cambiar este valor para saltar directamente a un día específico
-- Valores: nil (juego normal desde menú), 1, 2, 3, 4, etc.
local DEBUG_SALTAR_A_DIA = nil  -- Cambiar a 2, 3, 4, etc. para testear

-- ==================== CORE SYSTEMS ====================
local OBJ = require("core.objetos")
local Objetivos = require("data.objetivos")

-- Niveles
local Menu = require("niveles.menu")
local Dia1Casa = require("niveles.dia1_casa")
local Dia2Ciudad = require("niveles.dia2_ciudad")
local Dia3Restaurante = require("niveles.dia3_restaurante")
local Dia4Cine = require("niveles.dia4_cine")
local Dia5Biblioteca = require("niveles.dia5_biblioteca")
local Dia6Investigacion = require("niveles.dia6_investigacion")
local Dia7Callejon = require("niveles.dia7_callejon")
local Dia1FinalLoop = require("niveles.dia1_final_loop")
local Creditos = require("niveles.creditos")

-- ==================== CONSTANTES ====================
local SCALE = 15

-- ==================== STATE MACHINE ====================
local game_state = "menu"  -- Estado actual del juego
local nivel_actual = nil   -- Módulo del nivel activo

-- Mapeo de estados a niveles
local niveles = {
  menu = Menu,
  day1_title = Dia1Casa,
  sleeping = Dia1Casa,
  playing = Dia1Casa,
  day2_wake = Dia2Ciudad,
  city = Dia2Ciudad,
  day3_wake = Dia3Restaurante,
  restaurante = Dia3Restaurante,
  day4_wake = Dia4Cine,
  cine = Dia4Cine,
  day5_wake = Dia5Biblioteca,
  biblioteca = Dia5Biblioteca,
  day6_wake = Dia6Investigacion,
  investigacion = Dia6Investigacion,
  day7_wake = Dia7Callejon,
  callejon = Dia7Callejon,
  day1_final_loop = Dia1FinalLoop,
  creditos = Creditos
}

-- ==================== VARIABLES GLOBALES ====================
local detective
local tareas = {
  actual = 1,
  alpha = 0,
  fade_speed = 1.5
}

-- Audio
local sonido_pasos, radio_sonido, musica_fondo, ciudad_sonido, puerta_sonido, restaurante_sonido
local musica_fade = {
  current_volume = 0.6,
  target_volume = 0.6,
  fade_speed = 0.5
}

-- Fuentes
local title_font, subtitle_font, radio_font, tarea_font

-- Shader
local lighting_shader

-- Input tracking
local prevX, prevY = 0, 0
local teclas_presionadas = {}

-- ==================== FORWARD DECLARATIONS ====================
local cambiar_estado
local actualizar_movimiento_detective
local dibujar_objetivos

-- ==================== LOVE.LOAD ====================
function love.load()
  -- Inicializar recursos (OBJ)
  OBJ.init()

  detective = OBJ.detective

  -- Cargar audio
  sonido_pasos = love.audio.newSource("sonidos/Pasos madera.mp3", "stream")
  radio_sonido = love.audio.newSource("sonidos/Radio.wav", "stream")
  musica_fondo = love.audio.newSource("sonidos/Musica de fondo.mp3", "stream")
  ciudad_sonido = love.audio.newSource("sonidos/Ciudad.wav", "stream")
  puerta_sonido = love.audio.newSource("sonidos/Puerta.mp3", "stream")

  -- Intentar cargar restaurante_sonido con fallback
  local success, result = pcall(function()
    return love.audio.newSource("sonidos/Restaurante.wav", "static")
  end)
  if success then
    restaurante_sonido = result
  else
    print("Warning: Could not load Restaurante.wav, using Ciudad.wav as fallback")
    restaurante_sonido = ciudad_sonido
  end

  -- Cargar cinema_sonido
  cinema_sonido = love.audio.newSource("sonidos/Cinema gente.wav", "stream")

  -- Configurar audio
  musica_fondo:setLooping(true)
  musica_fondo:setVolume(musica_fade.current_volume)
  musica_fondo:play()
  ciudad_sonido:setLooping(true)
  ciudad_sonido:setVolume(0.5)
  if restaurante_sonido ~= ciudad_sonido then
    restaurante_sonido:setLooping(true)
    restaurante_sonido:setVolume(0.5)
  end
  cinema_sonido:setLooping(true)
  cinema_sonido:setVolume(0.5)

  -- Fuentes
  title_font = love.graphics.newFont("fonts/serif.ttf", 96)
  subtitle_font = love.graphics.newFont(28)
  radio_font = love.graphics.newFont(18)
  tarea_font = love.graphics.newFont(16)

  -- Shader de iluminación
  local shader_code = [[
    extern vec2  light_pos;
    extern float light_radius;
    extern vec3  ambient_color;
    extern float ambient_strength;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc){
      vec4 px = Texel(tex, tc);
      float d = length(sc - light_pos);
      float att = 1.0 - smoothstep(0.0, light_radius, d);
      float glow = exp(-d / (light_radius * 0.3)) * 0.4;
      att += glow;
      vec3 lit = px.rgb * (ambient_color * ambient_strength + vec3(1.0) * att);
      return vec4(lit, px.a) * color;
    }
  ]]
  lighting_shader = love.graphics.newShader(shader_code)
  lighting_shader:send("light_radius", 550.0)
  lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})
  lighting_shader:send("ambient_strength", 0.75)

  -- Inicializar primer nivel (o saltar a día específico si DEBUG_SALTAR_A_DIA está configurado)
  if DEBUG_SALTAR_A_DIA then
    -- Saltar directamente al día configurado
    local estados_dias = {
      [1] = "day1_title",
      [2] = "day2_wake",
      [3] = "day3_wake",
      [4] = "day4_wake",
      [5] = "day5_wake",
      [6] = "day6_wake",
      [7] = "day7_wake"
    }

    local estado_inicial = estados_dias[DEBUG_SALTAR_A_DIA]
    if estado_inicial then
      print("DEBUG: Saltando directamente al día " .. DEBUG_SALTAR_A_DIA)

      -- Configurar tarea inicial del día
      local objetivos_dia = Objetivos.get_por_dia(DEBUG_SALTAR_A_DIA)
      if #objetivos_dia > 0 then
        tareas.actual = objetivos_dia[1].id
      end

      -- Ajustar música según el día
      musica_fade.target_volume = 0.02
      musica_fade.current_volume = 0.02
      musica_fondo:setVolume(0.02)

      game_state = estado_inicial
      nivel_actual = niveles[estado_inicial]

      -- Inicializar el nivel con los recursos necesarios
      local audio = {
        ciudad = ciudad_sonido,
        puerta = puerta_sonido,
        restaurante = restaurante_sonido,
        cinema = cinema_sonido
      }

      if nivel_actual.init then
        nivel_actual.init(OBJ, detective, audio, tareas)
      end
    else
      print("DEBUG: Día " .. DEBUG_SALTAR_A_DIA .. " no existe, iniciando desde menú")
      Menu.init()
      nivel_actual = Menu
    end
  else
    -- Juego normal: iniciar desde menú
    Menu.init()
    nivel_actual = Menu
  end
end

-- ==================== LOVE.UPDATE ====================
function love.update(dt)
  -- Fade de música
  if musica_fade.current_volume ~= musica_fade.target_volume then
    if musica_fade.current_volume < musica_fade.target_volume then
      musica_fade.current_volume = math.min(musica_fade.target_volume, musica_fade.current_volume + musica_fade.fade_speed * dt)
    else
      musica_fade.current_volume = math.max(musica_fade.target_volume, musica_fade.current_volume - musica_fade.fade_speed * dt)
    end
    musica_fondo:setVolume(musica_fade.current_volume)
  end

  -- Fade de objetivos
  if tareas.actual > 0 then
    if tareas.alpha < 1 then
      tareas.alpha = math.min(1, tareas.alpha + tareas.fade_speed * dt)
    end
  end

  -- Actualizar nivel actual
  if nivel_actual and nivel_actual.update then
    local nuevo_estado = nivel_actual.update(dt, tareas, musica_fade)
    if nuevo_estado and nuevo_estado ~= game_state then
      -- Cambiar de estado/nivel
      -- Fade de música al entrar al juego
      if nuevo_estado == "day1_title" then
        musica_fade.target_volume = 0.02
      end
      cambiar_estado(nuevo_estado)
      return  -- Salir para que el nuevo nivel se inicialice en el próximo frame
    end
  end

  -- Movimiento del detective (solo en estados de juego)
  if game_state == "playing" or game_state == "city" or game_state == "day2_wake" or
     game_state == "restaurante" or game_state == "day3_wake" or
     game_state == "day4_wake" or game_state == "cine" or
     game_state == "day5_wake" or game_state == "biblioteca" or
     game_state == "day6_wake" or game_state == "investigacion" or
     game_state == "day7_wake" or game_state == "callejon" then

    -- Verificar si el nivel bloquea movimiento
    local movimiento_bloqueado = false
    if nivel_actual and nivel_actual.is_movimiento_bloqueado then
      movimiento_bloqueado = nivel_actual.is_movimiento_bloqueado()
    end

    if not movimiento_bloqueado then
      actualizar_movimiento_detective(dt)
    end
  end

  prevX, prevY = detective.x, detective.y
end

-- ==================== LOVE.DRAW ====================
function love.draw()
  love.graphics.clear(0, 0, 0)

  -- Delegar dibujado al nivel actual
  if nivel_actual and nivel_actual.draw then
    if game_state == "menu" then
      -- Menú necesita title_font y subtitle_font
      nivel_actual.draw(title_font, subtitle_font)
    else
      -- Otros niveles usan SCALE, shader y radio_font
      nivel_actual.draw(SCALE, lighting_shader, radio_font)
    end
  end

  -- Dibujar HUD de objetivos (en estados de juego)
  if tareas.actual > 0 and tareas.actual <= #Objetivos.lista and
     (game_state ~= "menu" and game_state ~= "day1_title" and game_state ~= "sleeping" and
      game_state ~= "day1_final_loop" and game_state ~= "creditos") then
    dibujar_objetivos()
  end
end

-- ==================== LOVE.KEYPRESSED ====================
function love.keypressed(key)
  teclas_presionadas[key] = true

  -- Delegar input al nivel actual
  if nivel_actual and nivel_actual.keypressed then
    local nuevo_estado = nivel_actual.keypressed(key, tareas)
    if nuevo_estado and nuevo_estado ~= game_state then
      cambiar_estado(nuevo_estado)
    end
  end
end

function love.keyreleased(key)
  teclas_presionadas[key] = false
end

-- ==================== FUNCIONES AUXILIARES ====================

cambiar_estado = function(nuevo_estado)
  print("Cambiando estado: " .. game_state .. " → " .. nuevo_estado)
  game_state = nuevo_estado

  -- Obtener módulo del nuevo nivel
  nivel_actual = niveles[nuevo_estado]

  -- Inicializar nivel si tiene init
  if nivel_actual and nivel_actual.init then
    local audio = {
      pasos = sonido_pasos,
      radio = radio_sonido,
      ciudad = ciudad_sonido,
      puerta = puerta_sonido,
      restaurante = restaurante_sonido,
      cinema = cinema_sonido
    }
    nivel_actual.init(OBJ, detective, audio, tareas)
  end
end

actualizar_movimiento_detective = function(dt)
  local movement = 0  -- Movimiento del MUNDO (no del detective)
  local speed = 30  -- Velocidad de movimiento

  -- Detectar teclas presionadas
  -- movement representa cuánto queremos DECREMENTAR detective.x
  -- (cuando movement > 0, detective.x disminuye = canvas va a la izquierda)
  if love.keyboard.isDown("a") then
    movement = -speed * dt  -- Incrementar detective.x = canvas va a la derecha, detective a la izquierda
    detective.animation.direction = "left"
    detective.animation.idle = false
  elseif love.keyboard.isDown("d") then
    movement = speed * dt  -- Decrementar detective.x = canvas va a la izquierda, detective a la derecha
    detective.animation.direction = "right"
    detective.animation.idle = false
  else
    detective.animation.idle = true
  end

  -- Aplicar movimiento
  if movement ~= 0 then
    -- Reproducir sonido de pasos
    if not sonido_pasos:isPlaying() then
      sonido_pasos:play()
    end

    -- Movimiento según el estado
    -- Sistema de cámara unificado para casa, ciudad y restaurante
    local ww = love.graphics.getDimensions()
    local view_w = ww / SCALE
    local world_w = OBJ.WORLD_W  -- Default: casa

    -- Detectar si estamos en ciudad, restaurante, cine o biblioteca para ajustar el ancho del mundo
    local fase_actual = nivel_actual.get_fase and nivel_actual.get_fase() or ""
    local en_ciudad = (game_state == "city") or (game_state == "day2_wake" and fase_actual == "ciudad")
    local en_restaurante = (game_state == "restaurante") or (game_state == "day3_wake" and (fase_actual == "restaurante" or fase_actual == "intro_text"))
    local en_cine = (game_state == "cine") or (game_state == "day4_wake" and fase_actual == "cine")
    local en_biblioteca = (game_state == "biblioteca") or (game_state == "day5_wake" and fase_actual == "biblioteca")

    if en_ciudad then
      world_w = (OBJ.CITY_W_PX / OBJ.SCALE)
    elseif en_restaurante then
      world_w = OBJ.WORLD_W  -- Restaurante usa el mismo ancho que casa
    elseif en_cine then
      world_w = OBJ.WORLD_W  -- Cine usa el mismo ancho que casa
    elseif en_biblioteca then
      world_w = OBJ.WORLD_W  -- Biblioteca usa el mismo ancho que casa
    end

    -- Límites de la cámara
    local min_cam_x = view_w - world_w  -- Límite izquierdo del mundo
    local max_cam_x = 0  -- Límite derecho del mundo

    -- Márgenes en pantalla
    local margin_left = 20
    local margin_right = view_w - 12

    -- Posición central donde el detective debería permanecer
    local center_pos = 50
    local center_threshold = 2
    local is_near_center = math.abs(detective.screen_x - center_pos) < center_threshold

    -- Si está cerca del centro, mover el mundo; si no, mover el detective
    if is_near_center then
      -- Mover el mundo (cámara)
      local new_world_x = detective.x - movement
      if new_world_x >= min_cam_x and new_world_x <= max_cam_x then
        detective.x = new_world_x
      else
        -- Llegamos al límite del mundo, mover detective
        detective.x = math.max(min_cam_x, math.min(max_cam_x, new_world_x))
        local new_screen_x = detective.screen_x + movement
        detective.screen_x = math.max(margin_left, math.min(margin_right, new_screen_x))
      end
    else
      -- Mover detective en pantalla
      local new_screen_x = detective.screen_x + movement
      detective.screen_x = math.max(margin_left, math.min(margin_right, new_screen_x))
    end

    -- Animación más rápida (cambié de 0.2 a 0.15)
    detective.animation.timer = detective.animation.timer + dt
    if detective.animation.timer >= 0.15 then
      detective.animation.timer = 0
      detective.animation.frame = detective.animation.frame + 1
      if detective.animation.frame > 4 then
        detective.animation.frame = 1
      end
    end
  else
    -- Idle
    detective.animation.frame = 1
    detective.animation.timer = 0

    -- Detener sonido de pasos
    if sonido_pasos:isPlaying() then
      sonido_pasos:stop()
    end
  end
end

dibujar_objetivos = function()
  local objetivo = Objetivos.get_por_id(tareas.actual)
  if not objetivo then return end

  love.graphics.setFont(tarea_font)
  love.graphics.setColor(1, 1, 1, tareas.alpha)

  local texto = "Objetivo: " .. objetivo.descripcion
  local screen_w = love.graphics.getWidth()
  local text_w = tarea_font:getWidth(texto)

  -- Dibujar en esquina superior derecha
  love.graphics.print(texto, screen_w - text_w - 20, 20)
  love.graphics.setColor(1, 1, 1, 1)
end
