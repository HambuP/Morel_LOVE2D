-- main.lua
local love = require("love")

package.path = package.path .. ";../?.lua;../?/init.lua;./?.lua;./?/init.lua"
local inspect = require("inspect")

-- Módulo de recursos/prerender
local OBJ = require("objetos")

-- === GAME STATE MACHINE ===
local game_state = "menu" -- "menu" | "day1_title" | "sleeping" | "playing" | "day2_wake" | "city"

-- === Cámara / mundo (desde el módulo) ===
-- Usamos referencias directas a OBJ para que se actualicen después de init()
local TILE, WORLD_W, WORLD_H = OBJ.TILE, OBJ.WORLD_W, OBJ.WORLD_H

-- Referencias que llenamos tras OBJ.init()
local detective, quads_casa, quads_detective, casa_canvas, city_canvas

-- Helpers centralizados
local function clampHouseOffset(x, y) return OBJ.clampHouseOffset(x, y) end
local function clampCityOffset(x, y) return OBJ.clampCityOffset(x, y) end
local function getDetectiveWorldPos() return OBJ.getDetectiveWorldPos() end

-- ================== ESTADOS / DATOS ==================
-- Audio
local sonido_pasos, radio_sonido, musica_fondo, ciudad_sonido, puerta_sonido, restaurante_sonido
local musica_fade = { current_volume = 0.6, target_volume = 0.6, fade_speed = 0.5 }

local radio_fade = { is_fading=false, duration=2.0, timer=0, original_volume=1.0 }

-- Radio
local radio_state = {
  x = 85 * (10/15), y = 46 * (10/15),
  usado = false, radio_cercania = 15,
  mostrar_texto = false,
  texto_completo = "Radio:\n\n* Se ha reportado la desaparicion de un joven de 23 anos tras haber salido a festejar el cumpleanos de uno de sus amigos.\n\n* Las autoridades han declarado que aun no han logrado encontrar al joven y que si alguien tiene informacion que por favor venga a compartirla en la estacion de policia del pueblo.",
  texto_visible = "", char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_at_newlines = true, pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20
}

-- Texto detective tras radio
local detective_text_state = {
  mostrar_texto = false,
  texto_completo = "Josuelito:\n\n* Supongo que me pediran en la estacion hacer la investigacion sobre este caso...\n\nMejor me pongo a trabajar para ganar tiempo.",
  texto_visible = "", char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_at_newlines = true, pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20,
  finished_timer = 0, finished_delay = 3.0
}

-- Texto tras tablero
local tablero_text_state = {
  mostrar_texto = false,
  texto_completo = "Josuelito:\n\n* Con esto podre seguir investigando sin problemas de organizacion.\n\nLo voy a dejar hasta aqui por hoy... manana saldre al pueblo para encontrar pruebas.",
  texto_visible = "", char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_at_newlines = true, pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20,
  finished_timer = 0, finished_delay = 3.0
}

-- Objetivos
local tareas = {
  actual = 1,
  lista  = {
    "Escucha las noticias de la Radio",           -- 1: DIA 1
    "Construir plan de investigacion",            -- 2: DIA 1
    "Ir a la cama",                               -- 3: DIA 1
    "Ve a investigar en el pueblo",               -- 4: DIA 2
    "Escuchar conversaciones de transeuntes hombres",  -- 5: DIA 2
    "Intenta pedir informacion",                  -- 6: DIA 2
    "Escucha otra conversacion",                  -- 7: DIA 2
    "Volver a casa y anotar resultados",          -- 8: DIA 2
    "Ve a restaurante",                           -- 9: DIA 3
    "Sentarse",                                   -- 10: DIA 3
    "Escucha conversacion cercana",               -- 11: DIA 3
    "Ve y habla con ellos",                       -- 12: DIA 3
    "Volver a casa y anotar pruebas"              -- 13: DIA 3
  },
  alpha = 0, fade_speed = 1.5
}

-- Interactuables
local tablero_state = { x = 148*(10/15), y = 18*(10/15), usado=false, cercania=20, hoja_visible=false }
local cama_state    = { x = 12, y = 46, cercania=30, puede_dormir=false }
local puerta_state  = { x = 136, y = 50, cercania=35, puede_salir=false }
local puerta_ciudad_state = { x = 140, y = 50, cercania=35, puede_entrar=false }  -- Puerta para regresar a casa desde ciudad
local puerta_restaurante_state = { x = 136, y = 50, cercania=35, puede_salir_rest=false, puede_entrar_rest=false }  -- Puerta del restaurante
local silla_state = { x = 50, y = 25, cercania=20, puede_sentarse=false, esta_sentado=false }  -- Silla en restaurante (movida más a la izquierda)
local puerta_casa_dia3_state = { x = 136, y = 50, cercania=35, puede_salir_dia3=false }  -- Puerta casa dia 3

-- Transeuntes en la ciudad (coordenadas en escala 15)
local transeuntes_state = {
  x = 40, y = 20, cercania = 25,  -- Centro entre pers1 y pers2
  conversacion_escuchada = false,
  pregunta_hecha = false,
  dialogo_activo = false,
  dialogo_index = 0,
  dialogo_completo = false
}

-- Dialogos de transeuntes
local transeuntes_dialogo = {
  mostrar_texto = false,
  texto_completo = "",
  texto_visible = "",
  char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_at_newlines = true, pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20,
  hablante = ""  -- "PNG1", "PNG2", o "JOSUELITO"
}

-- Conversacion completa
local conversacion_transeuntes = {
  {hablante = "PNG1", texto = "Oye viste las noticias de ayer?"},
  {hablante = "PNG2", texto = "Pues claro que las vi ya sabes como soy. La verdad me da miedo pensar en el hecho de que nuestro pueblo sea tan inseguro... Es que ya es la septima vez que desaparece alguien por la noche!"},
  {hablante = "PNG1", texto = "Tocara tener mucho mas cuidado al salir por la noche que nadie sabe cuando le podra pasar a uno."}
}

local pregunta_josuelito = {
  {hablante = "JOSUELITO", texto = "Buenas tardes soy un detective y busco informacion sobre la desaparicion del joven de 23 anos. Sera que alguno de ustedes a visto o escuchado algo esa noche?"},
  {hablante = "SILENCIO", texto = "..."},
  {hablante = "JOSUELITO", texto = "Que groseros ni siquiera me prestaron atencion. Supongo que ire a buscar informacion en otro lado."}
}

-- Estado de viejas (PNG3 y PNG4)
local viejas_state = {
  x = 190, y = 20, cercania = 25,  -- Posicion de las viejas en el lado derecho
  conversacion_escuchada = false,
  dialogo_activo = false,
  dialogo_index = 0
}

local conversacion_viejas = {
  {hablante = "PNG3", texto = "Oye amiga ayer por la noche escuche sonidos muy extranos en el callejon cerca de mi casa."},
  {hablante = "PNG4", texto = "Ay que miedo amiga! Crees que tenga algo que ver con lo que paso ayer por la noche?"},
  {hablante = "PNG3", texto = "La verdad no lo se amiga, pero espero que no... Imaginate que vuelva a pasar algo como eso y me pase a mi... ay no amiga que miedo prefiero no pensar en eso!"}
}

-- Estado de borrachos en restaurante (PNG5 y PNG6)
local borrachos_state = {
  x = 50, y = 20, cercania = 25,  -- Posicion de los borrachos
  conversacion_escuchada = false,
  pregunta_hecha = false,
  dialogo_activo = false,
  dialogo_index = 0
}

-- DEBUG: Variable global para mostrar en pantalla
local debug_info = ""

local conversacion_borrachos = {
  {hablante = "PNG5", texto = "Uf que buena cerveza en serio es la mejor de todo el pais."},
  {hablante = "PNG6", texto = "Se me fue todo el estres del trabajo."},
  {hablante = "PNG5", texto = "Oye si te conte lo de ayer?"},
  {hablante = "PNG6", texto = "Como me lo vas a haber contado si no nos vimos desde hace un mes imbecil?"},
  {hablante = "PNG5", texto = "Jajajaja se me olvido perdon. Pues fijate que al volver a mi casa vi a un man saliendo de un callejon corriendo y tenia como manchas de sangre sobre su camisa de unicornio. Era re extraño."},
  {hablante = "PNG6", texto = "Jajajajaja este man de que me habla, seguro que no estabas borracho esa noche tambien?"},
  {hablante = "PNG5", texto = "Uno no puede hablarle de cosas serias... bueno pues hablemos de otra cosa ya que no me va a tomar enserio."},
  {hablante = "PNG6", texto = "Esta noche vayamos a una discoteca para emborracharnos mas. Seguro sera mas interesante que tus mentiras."},
  {hablante = "PNG5", texto = "Que no son mentiras imbecil... pero bueno me parece el plan."},
  {hablante = "PNG6", texto = "Esa es la actitud!"}
}

local pregunta_borrachos = {
  {hablante = "JOSUELITO", texto = "Perdon buenas tardes, soy un detective y estoy buscando informacion sobre la desaparicion del joven de 23 anos. Sera que alguno de ustedes a visto o escuchado algo esa noche?"},
  {hablante = "SILENCIO", texto = "..."},
  {hablante = "JOSUELITO", texto = "La gente ya no respeta, es la segunda vez que me ignoran esta semana. Igual la informacion que escuche es util, entonces no dire nada."}
}

-- Texto inicio dia 3
local dia3_text_state = {
  mostrar_texto = false,
  texto_completo = "En general los borrachos suelen hablar mas de lo que tienen. Quizas pueda sacarles informacion en alguno de los restaurantes del pueblo.",
  texto_visible = "",
  char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_at_newlines = true, pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20,
  finished = false
}

-- Título "DÍA 1"
local day1_state = {
  activo = false, alpha = 0, fade_speed = 1.2,
  timer = 0, hold = 1.4, fase = "in" -- "in" -> "hold" -> "out"
}

-- Transición a "DÍA 2"
local dia2_state = {
  iniciado=false, pantalla_negra=false, fade_alpha=0, fade_speed=1.0,
  mostrar_titulo=false, titulo_alpha=0, titulo_timer=0, titulo_duration=2.5,
  titulo_fade_out=false, fade_out_timer=0, transicion_completa=false
}

-- Transición a "DÍA 3"
local dia3_state = {
  iniciado=false, pantalla_negra=false, fade_alpha=0, fade_speed=1.0,
  mostrar_titulo=false, titulo_alpha=0, titulo_timer=0, titulo_duration=2.5,
  titulo_fade_out=false, fade_out_timer=0, transicion_completa=false
}

-- Transición a "DÍA 4"
local dia4_state = {
  iniciado=false, pantalla_negra=false, fade_alpha=0, fade_speed=1.0,
  mostrar_titulo=false, titulo_alpha=0, titulo_timer=0, titulo_duration=2.5,
  titulo_fade_out=false, fade_out_timer=0, transicion_completa=false
}

-- Fuente UI
local title_font, subtitle_font, radio_font, tarea_font

-- Shader
local lighting_shader

-- Vars auxiliares
local menu_blink_timer = 0
local prevX, prevY = 0, 0
local space_pressed = false

-- ================== LOVE.LOAD ==================
function love.load()
  -- Cargar todos los recursos gráficos del módulo
  OBJ.init()

  detective       = OBJ.detective
  quads_casa      = OBJ.quads.casa
  quads_detective = OBJ.quads.detective
  casa_canvas     = OBJ.casa_canvas   -- canvas activo (se cambiará a OBJ.casa_hoja1 tras el plan)
  city_canvas     = OBJ.city_canvas   -- canvas de la ciudad

  -- Audio
  sonido_pasos = love.audio.newSource("sonidos/Pasos madera.mp3", "stream")
  radio_sonido = love.audio.newSource("sonidos/Radio.wav", "stream")
  musica_fondo = love.audio.newSource("sonidos/Musica de fondo.mp3", "stream")
  ciudad_sonido = love.audio.newSource("sonidos/Ciudad.wav", "stream")
  puerta_sonido = love.audio.newSource("sonidos/Puerta.mp3", "stream")

  -- Intentar cargar restaurante_sonido con manejo de errores
  local success, result = pcall(function()
    return love.audio.newSource("sonidos/Restaurante.wav", "static")
  end)
  if success then
    restaurante_sonido = result
  else
    print("Warning: Could not load Restaurante.wav, using Ciudad.wav as fallback")
    restaurante_sonido = ciudad_sonido  -- Usar ciudad como fallback
  end

  musica_fondo:setLooping(true)
  musica_fondo:setVolume(musica_fade.current_volume)
  musica_fondo:play()
  ciudad_sonido:setLooping(true)
  ciudad_sonido:setVolume(0.5)
  if restaurante_sonido ~= ciudad_sonido then
    restaurante_sonido:setLooping(true)
    restaurante_sonido:setVolume(0.5)
  end

  -- Fuentes
  title_font    = love.graphics.newFont("fonts/serif.ttf", 96)
  subtitle_font = love.graphics.newFont(28)
  radio_font    = love.graphics.newFont(18)
  tarea_font    = love.graphics.newFont(16)

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
end

-- ================== HELPERS DE DISTANCIA ==================
local function isNearRadio()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, radio_state.x,   radio_state.y,   radio_state.radio_cercania)
end
local function isNearTablero()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, tablero_state.x, tablero_state.y, tablero_state.cercania)
end
local function isNearCama()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, cama_state.x,    cama_state.y,    cama_state.cercania)
end
local function isNearPuerta()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, puerta_state.x,  puerta_state.y,  puerta_state.cercania)
end
local function isNearTranseuntes()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, transeuntes_state.x, transeuntes_state.y, transeuntes_state.cercania)
end
local function isNearViejas()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, viejas_state.x, viejas_state.y, viejas_state.cercania)
end
local function isNearPuertaCiudad()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, puerta_ciudad_state.x, puerta_ciudad_state.y, puerta_ciudad_state.cercania)
end
local function isNearSilla()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, silla_state.x, silla_state.y, silla_state.cercania)
end
local function isNearBorrachos()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, borrachos_state.x, borrachos_state.y, borrachos_state.cercania)
end
local function isNearPuertaRestaurante()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, puerta_restaurante_state.x, puerta_restaurante_state.y, puerta_restaurante_state.cercania)
end
local function isNearPuertaCasaDia3()
  local dx, dy = getDetectiveWorldPos()
  return OBJ.isNear(dx, dy, puerta_casa_dia3_state.x, puerta_casa_dia3_state.y, puerta_casa_dia3_state.cercania)
end
local function clampRestauranteOffset(x, y) return OBJ.clampRestauranteOffset(x, y) end

-- ================== LOVE.UPDATE ==================
function love.update(dt)
  -- Música (fade suave)
  if musica_fade.current_volume ~= musica_fade.target_volume then
    if musica_fade.current_volume < musica_fade.target_volume then
      musica_fade.current_volume = math.min(musica_fade.target_volume, musica_fade.current_volume + musica_fade.fade_speed * dt)
    else
      musica_fade.current_volume = math.max(musica_fade.target_volume, musica_fade.current_volume - musica_fade.fade_speed * dt)
    end
    musica_fondo:setVolume(musica_fade.current_volume)
  end

  -- ===== MENÚ =====
  if game_state == "menu" then
    menu_blink_timer = menu_blink_timer + dt
    if love.keyboard.isDown("space") then
      if not space_pressed then
        -- Ir a título DÍA 1 antes de la escena de dormir
        game_state = "day1_title"
        day1_state.activo = true
        day1_state.alpha = 0
        day1_state.timer = 0
        day1_state.fase  = "in"
        musica_fade.target_volume = 0.02
        space_pressed = true
      end
    else
      space_pressed = false
    end
    return
  end

  -- ===== TÍTULO "DÍA 1" =====
  if game_state == "day1_title" then
    if day1_state.fase == "in" then
      day1_state.alpha = math.min(1, day1_state.alpha + day1_state.fade_speed * dt)
      if day1_state.alpha >= 1 then
        day1_state.fase = "hold"
        day1_state.timer = 0
      end
    elseif day1_state.fase == "hold" then
      day1_state.timer = day1_state.timer + dt
      if day1_state.timer >= day1_state.hold then
        day1_state.fase = "out"
      end
    else -- "out"
      day1_state.alpha = math.max(0, day1_state.alpha - day1_state.fade_speed * dt)
      if day1_state.alpha <= 0 then
        game_state = "sleeping"
        -- activar texto de despertar
        sleeping_state.mostrar_texto = true
      end
    end
    return
  end

  -- ===== ESCENA DORMIR =====
  if game_state == "sleeping" then
    -- animación del texto de dormir
    if sleeping_state.mostrar_texto then
      if sleeping_state.alpha < 1 then
        sleeping_state.alpha = math.min(1, sleeping_state.alpha + sleeping_state.fade_speed * dt)
      end
      if sleeping_state.char_index < #sleeping_state.texto_completo then
        if sleeping_state.is_paused then
          sleeping_state.pause_timer = sleeping_state.pause_timer + dt
          if sleeping_state.pause_timer >= sleeping_state.pause_duration then
            sleeping_state.is_paused, sleeping_state.pause_timer = false, 0
          end
        else
          sleeping_state.char_timer = sleeping_state.char_timer + dt
          if sleeping_state.char_timer >= sleeping_state.char_speed then
            sleeping_state.char_timer = 0
            sleeping_state.char_index = sleeping_state.char_index + 1
            sleeping_state.texto_visible = string.sub(sleeping_state.texto_completo, 1, sleeping_state.char_index)
            if sleeping_state.char_index > 1 then
              local prev = string.sub(sleeping_state.texto_completo, sleeping_state.char_index-1, sleeping_state.char_index-1)
              local curr = string.sub(sleeping_state.texto_completo, sleeping_state.char_index, sleeping_state.char_index)
              if prev == "\n" and curr == "\n" then sleeping_state.is_paused = true end
            end
          end
        end
      else
        sleeping_state.finished_timer = sleeping_state.finished_timer + dt
        if sleeping_state.finished_timer >= sleeping_state.finished_delay then
          sleeping_state.cama_alpha = sleeping_state.cama_alpha - dt * 2
          if sleeping_state.cama_alpha <= 0 then
            sleeping_state.cama_alpha = 0
            game_state = "playing"
            sleeping_state.mostrar_texto = false
            sleeping_state.alpha = 0
          end
        end
      end
    end
    return
  end

  -- ===== TRANSICIÓN DÍA 2 =====
  if dia2_state.iniciado then
    if not dia2_state.pantalla_negra then
      dia2_state.fade_alpha = math.min(1, dia2_state.fade_alpha + dia2_state.fade_speed * dt)
      if dia2_state.fade_alpha >= 1 then
        dia2_state.pantalla_negra = true
        dia2_state.mostrar_titulo = true
      end
    else
      if dia2_state.mostrar_titulo and not dia2_state.titulo_fade_out then
        dia2_state.titulo_alpha = math.min(1, dia2_state.titulo_alpha + dia2_state.fade_speed * dt)
        dia2_state.titulo_timer = dia2_state.titulo_timer + dt
        if dia2_state.titulo_timer >= dia2_state.titulo_duration then
          dia2_state.titulo_fade_out = true
        end
      elseif dia2_state.titulo_fade_out then
        dia2_state.titulo_alpha = math.max(0, dia2_state.titulo_alpha - dia2_state.fade_speed * dt)
        dia2_state.fade_out_timer = dia2_state.fade_out_timer + dt
        if dia2_state.fade_out_timer >= 1.0 and not dia2_state.transicion_completa then
          dia2_state.transicion_completa = true
          -- Preparar día 2: despertar en casa con hoja ya puesta
          game_state = "day2_wake"
          casa_canvas = OBJ.casa_hoja1
          tareas.actual = 4  -- Nueva tarea
          tareas.alpha = 0
          puerta_state.puede_salir = true
          
          -- Usar las mismas coordenadas iniciales del día 1 (de OBJ.detective)
          detective.x = OBJ.detective.x
          detective.screen_x = OBJ.detective.screen_x
          detective.y = OBJ.detective.y
          detective.animation.direction = "left"
          detective.animation.idle = true
          detective.animation.frame = 1
          
          -- IMPORTANTE: Resetear el estado de transición para que no bloquee el render
          dia2_state.iniciado = false
          dia2_state.fade_alpha = 0
        end
      end
    end
    return
  end

  -- ===== TRANSICIÓN DÍA 3 =====
  if dia3_state.iniciado then
    if not dia3_state.pantalla_negra then
      dia3_state.fade_alpha = math.min(1, dia3_state.fade_alpha + dia3_state.fade_speed * dt)
      if dia3_state.fade_alpha >= 1 then
        dia3_state.pantalla_negra = true
        dia3_state.mostrar_titulo = true
        -- Detener audio de ciudad
        ciudad_sonido:stop()
      end
    else
      if dia3_state.mostrar_titulo and not dia3_state.titulo_fade_out then
        dia3_state.titulo_alpha = math.min(1, dia3_state.titulo_alpha + dia3_state.fade_speed * dt)
        dia3_state.titulo_timer = dia3_state.titulo_timer + dt
        if dia3_state.titulo_timer >= dia3_state.titulo_duration then
          dia3_state.titulo_fade_out = true
        end
      elseif dia3_state.titulo_fade_out then
        dia3_state.titulo_alpha = math.max(0, dia3_state.titulo_alpha - dia3_state.fade_speed * dt)
        dia3_state.fade_out_timer = dia3_state.fade_out_timer + dt
        if dia3_state.fade_out_timer >= 1.0 and not dia3_state.transicion_completa then
          dia3_state.transicion_completa = true
          -- Preparar día 3: despertar en casa con hoja1 y hoja2 en el tablero
          game_state = "day3_wake"
          casa_canvas = OBJ.casa_hoja2
          tareas.actual = 0  -- Sin tarea por ahora
          tareas.alpha = 0

          -- Activar texto de Josuelito al despertar
          dia3_text_state.mostrar_texto = true
          dia3_text_state.alpha = 0
          dia3_text_state.char_index = 0
          dia3_text_state.texto_visible = ""
          dia3_text_state.finished = false

          -- Resetear posición del detective
          detective.x = OBJ.detective.x
          detective.screen_x = OBJ.detective.screen_x
          detective.y = OBJ.detective.y
          detective.animation.direction = "left"
          detective.animation.idle = true
          detective.animation.frame = 1

          -- Resetear el estado de transición
          dia3_state.iniciado = false
          dia3_state.fade_alpha = 0
        end
      end
    end
    return
  end

  -- ===== TYPEWRITERS (deben ejecutarse siempre, incluso cuando estás sentado) =====
  -- Typewriter transeúntes
  if transeuntes_dialogo.mostrar_texto then
    transeuntes_dialogo.alpha = math.min(1, transeuntes_dialogo.alpha + transeuntes_dialogo.fade_speed * dt)

    -- DEBUG en pantalla
    if game_state == "restaurante" and borrachos_state.dialogo_activo then
      debug_info = "UPDATE: alpha=" .. string.format("%.2f", transeuntes_dialogo.alpha) ..
                   " char=" .. transeuntes_dialogo.char_index .. "/" .. #transeuntes_dialogo.texto_completo ..
                   " texto_visible=" .. transeuntes_dialogo.texto_visible
    end

    if transeuntes_dialogo.char_index < #transeuntes_dialogo.texto_completo then
      if transeuntes_dialogo.is_paused then
        transeuntes_dialogo.pause_timer = transeuntes_dialogo.pause_timer + dt
        if transeuntes_dialogo.pause_timer >= transeuntes_dialogo.pause_duration then
          transeuntes_dialogo.is_paused, transeuntes_dialogo.pause_timer = false, 0
        end
      else
        transeuntes_dialogo.char_timer = transeuntes_dialogo.char_timer + dt
        if transeuntes_dialogo.char_timer >= transeuntes_dialogo.char_speed then
          transeuntes_dialogo.char_timer = 0
          transeuntes_dialogo.char_index = transeuntes_dialogo.char_index + 1
          transeuntes_dialogo.texto_visible = string.sub(transeuntes_dialogo.texto_completo, 1, transeuntes_dialogo.char_index)
        end
      end
    end
  end

  -- ===== GAMEPLAY =====
  -- Si estamos en día 2/3 despertando o en la ciudad/restaurante, mismo control
  if game_state ~= "playing" and game_state ~= "day2_wake" and game_state ~= "day3_wake" and game_state ~= "city" and game_state ~= "restaurante" then
    return
  end

  -- Movimiento del detective (solo si NO está sentado)
  if not (game_state == "restaurante" and silla_state.esta_sentado) then
    local movement = 0
    if love.keyboard.isDown("a") then
      detective.animation.idle = false
      detective.animation.direction = "right"
      movement = detective.animation.speed * dt
      sonido_pasos:play()
    elseif love.keyboard.isDown("d") then
      detective.animation.idle = false
      detective.animation.direction = "left"
      movement = -detective.animation.speed * dt
      sonido_pasos:play()
    else
      detective.animation.idle = true
      detective.animation.frame = 1
      sonido_pasos:stop()
    end

    if not detective.animation.idle then
      detective.animation.timer = detective.animation.timer + dt
      if detective.animation.timer > 0.2 then
        detective.animation.timer = 0.1
        detective.animation.frame = detective.animation.frame + 1
        if detective.animation.frame > detective.animation.max_frames then
          detective.animation.frame = 1
        end
      end
      -- Calcular view_w basado en dimensiones reales de pantalla
      local ww = love.graphics.getDimensions()
      local view_w = ww / OBJ.SCALE
      -- Usar el ancho del mundo correcto según el estado del juego
      local world_width = WORLD_W  -- default: casa
      if game_state == "city" then
        world_width = (OBJ.CITY_W_PX / OBJ.SCALE)
      end
      local minX, maxX = view_w - world_width, 0
      local margin_left, margin_right = 20, view_w - 12
      local center_pos, center_threshold = 50, 2
      local isNearCenter = math.abs(detective.screen_x - center_pos) < center_threshold
      if isNearCenter then
        local newWorldX = detective.x + movement
        if newWorldX >= minX and newWorldX <= maxX then
          detective.x = newWorldX
        else
          detective.x = math.max(minX, math.min(maxX, newWorldX))
          local newScreenX = detective.screen_x - movement
          detective.screen_x = math.max(margin_left, math.min(margin_right, newScreenX))
        end
      else
        local newScreenX = detective.screen_x - movement
        detective.screen_x = math.max(margin_left, math.min(margin_right, newScreenX))
      end
    end
  end

  -- Interacciones (SPACE)
  if love.keyboard.isDown("space") then
    if not space_pressed then
      if not radio_state.usado and isNearRadio() then
        radio_sonido:setVolume(radio_fade.original_volume)
        radio_sonido:play()
        radio_state.usado = true
        radio_state.mostrar_texto = true
        space_pressed = true

      elseif radio_state.mostrar_texto and radio_state.char_index >= #radio_state.texto_completo then
        radio_sonido:stop()
        radio_state.mostrar_texto = false
        detective_text_state.mostrar_texto = true
        tareas.alpha = 0
        space_pressed = true

      -- === HACER EL PLAN EN EL TABLERO ===
      elseif tareas.actual == 2 and not tablero_state.usado and isNearTablero() then
        tablero_state.usado = true
        tablero_text_state.mostrar_texto = true
        tareas.alpha = 0
        -- Cambiar canvas activo: coloca la hoja en el tablero
        casa_canvas = OBJ.casa_hoja1
        -- Desactiva el papel "fake" dibujado a mano
        tablero_state.hoja_visible = false
        space_pressed = true

      elseif cama_state.puede_dormir and isNearCama() and game_state == "playing" then
        dia2_state.iniciado = true
        space_pressed = true
        
      -- === SALIR DE CASA AL PUEBLO ===
      elseif puerta_state.puede_salir and isNearPuerta() and game_state == "day2_wake" then
        game_state = "city"
        -- Usar las mismas coordenadas iniciales que en día 1
        detective.x = OBJ.detective.x
        detective.screen_x = OBJ.detective.screen_x
        detective.y = OBJ.detective.y
        detective.animation.direction = "left"
        detective.animation.idle = true
        detective.animation.frame = 1
        tareas.actual = 5  -- Activar tarea de escuchar conversaciones
        tareas.alpha = 0
        -- Reproducir sonido de puerta y empezar audio de ciudad
        puerta_sonido:play()
        ciudad_sonido:play()
        space_pressed = true

      -- === DIA 3: CERRAR TEXTO INICIAL ===
      elseif game_state == "day3_wake" and dia3_text_state.mostrar_texto and dia3_text_state.finished then
        dia3_text_state.mostrar_texto = false
        dia3_text_state.alpha = 0
        tareas.actual = 9  -- Activar tarea "Ve a restaurante"
        tareas.alpha = 0
        puerta_casa_dia3_state.puede_salir_dia3 = true
        space_pressed = true

      -- === DIA 3: IR AL RESTAURANTE ===
      elseif puerta_casa_dia3_state.puede_salir_dia3 and isNearPuertaCasaDia3() and game_state == "day3_wake" then
        game_state = "restaurante"
        detective.x = OBJ.detective.x + 250  -- Mover mucho más hacia atrás
        detective.screen_x = OBJ.detective.screen_x
        detective.y = OBJ.detective.y
        detective.animation.direction = "left"
        detective.animation.idle = true
        detective.animation.frame = 1
        tareas.actual = 10  -- Activar tarea "Sentarse"
        tareas.alpha = 1  -- Mostrar objetivo inmediatamente
        puerta_sonido:play()
        restaurante_sonido:play()
        silla_state.puede_sentarse = true
        space_pressed = true

      -- === DIA 3: SENTARSE EN SILLA ===
      elseif silla_state.puede_sentarse and isNearSilla() and game_state == "restaurante" and not silla_state.esta_sentado then
        silla_state.esta_sentado = true
        detective.visible = false
        tareas.actual = 11  -- "Escucha conversacion cercana"
        tareas.alpha = 1  -- Mostrar objetivo inmediatamente
        borrachos_state.conversacion_escuchada = true
        borrachos_state.dialogo_activo = true
        borrachos_state.dialogo_index = 1
        -- Iniciar primer diálogo
        local primer_dialogo = conversacion_borrachos[1]
        transeuntes_dialogo.mostrar_texto = true
        transeuntes_dialogo.hablante = primer_dialogo.hablante
        transeuntes_dialogo.texto_completo = primer_dialogo.texto
        transeuntes_dialogo.texto_visible = ""
        transeuntes_dialogo.char_index = 0
        transeuntes_dialogo.char_timer = 0
        transeuntes_dialogo.alpha = 0
        transeuntes_dialogo.is_paused = false
        transeuntes_dialogo.pause_timer = 0

        -- DEBUG en pantalla
        debug_info = "SENTADO! mostrar_texto=" .. tostring(transeuntes_dialogo.mostrar_texto) ..
                     " dialogo_activo=" .. tostring(borrachos_state.dialogo_activo) ..
                     " hablante=" .. primer_dialogo.hablante

        space_pressed = true

      -- === AVANZAR DIÁLOGOS DE TRANSEÚNTES Y VIEJAS ===
      -- PRIORIDAD: Si hay un diálogo activo que continuar, hacerlo primero
      elseif transeuntes_dialogo.mostrar_texto and transeuntes_dialogo.char_index >= #transeuntes_dialogo.texto_completo then
        -- PRIORIDAD 1: Viejas (debe procesarse primero si está activa)
        if viejas_state.conversacion_escuchada and viejas_state.dialogo_activo then
          -- Avanzar en la conversación de las viejas
          if viejas_state.dialogo_index < #conversacion_viejas then
            viejas_state.dialogo_index = viejas_state.dialogo_index + 1
            local dialogo = conversacion_viejas[viejas_state.dialogo_index]
            transeuntes_dialogo.hablante = dialogo.hablante
            transeuntes_dialogo.texto_completo = dialogo.texto
            transeuntes_dialogo.texto_visible = ""
            transeuntes_dialogo.char_index = 0
            transeuntes_dialogo.alpha = 0
          else
            -- Terminó la conversación, activar tarea 8 y permitir regresar a casa
            transeuntes_dialogo.mostrar_texto = false
            viejas_state.dialogo_activo = false
            tareas.actual = 8
            tareas.alpha = 0
            puerta_ciudad_state.puede_entrar = true
          end

        -- PRIORIDAD 2: Borrachos (día 3)
        elseif borrachos_state.conversacion_escuchada and borrachos_state.dialogo_activo then
          -- Avanzar en la conversación de los borrachos
          if borrachos_state.dialogo_index < #conversacion_borrachos then
            borrachos_state.dialogo_index = borrachos_state.dialogo_index + 1
            local dialogo = conversacion_borrachos[borrachos_state.dialogo_index]
            transeuntes_dialogo.hablante = dialogo.hablante
            transeuntes_dialogo.texto_completo = dialogo.texto
            transeuntes_dialogo.texto_visible = ""
            transeuntes_dialogo.char_index = 0
            transeuntes_dialogo.alpha = 0
          else
            -- Terminó la conversación de borrachos, activar tarea 12 y permitir levantarse
            transeuntes_dialogo.mostrar_texto = false
            borrachos_state.dialogo_activo = false
            tareas.actual = 12  -- "Ve y habla con ellos"
            tareas.alpha = 0
            silla_state.puede_sentarse = false  -- Ya no puede volver a sentarse
          end

        elseif transeuntes_state.conversacion_escuchada and not transeuntes_state.dialogo_completo then
          -- Avanzar en la conversación entre PNG1 y PNG2
          if transeuntes_state.dialogo_index < #conversacion_transeuntes then
            transeuntes_state.dialogo_index = transeuntes_state.dialogo_index + 1
            local dialogo = conversacion_transeuntes[transeuntes_state.dialogo_index]
            transeuntes_dialogo.hablante = dialogo.hablante
            transeuntes_dialogo.texto_completo = dialogo.texto
            transeuntes_dialogo.texto_visible = ""
            transeuntes_dialogo.char_index = 0
            transeuntes_dialogo.alpha = 0
          else
            -- Terminó la conversación, activar tarea 6
            transeuntes_dialogo.mostrar_texto = false
            transeuntes_state.dialogo_completo = true
            transeuntes_state.dialogo_activo = false
            tareas.actual = 6
            tareas.alpha = 0
          end

        elseif transeuntes_state.pregunta_hecha then
          -- Avanzar en la pregunta de Josuelito
          if transeuntes_state.dialogo_index < #pregunta_josuelito then
            transeuntes_state.dialogo_index = transeuntes_state.dialogo_index + 1
            local dialogo = pregunta_josuelito[transeuntes_state.dialogo_index]
            transeuntes_dialogo.hablante = dialogo.hablante
            transeuntes_dialogo.texto_completo = dialogo.texto
            transeuntes_dialogo.texto_visible = ""
            transeuntes_dialogo.char_index = 0
            transeuntes_dialogo.alpha = 0
          else
            -- Terminó todo el diálogo, activar tarea 7
            transeuntes_dialogo.mostrar_texto = false
            transeuntes_state.dialogo_activo = false
            tareas.actual = 7
            tareas.alpha = 0
          end

        -- PRIORIDAD 3: Pregunta a borrachos (día 3)
        elseif borrachos_state.pregunta_hecha then
          -- Avanzar en la pregunta de Josuelito a los borrachos
          if borrachos_state.dialogo_index < #pregunta_borrachos then
            borrachos_state.dialogo_index = borrachos_state.dialogo_index + 1
            local dialogo = pregunta_borrachos[borrachos_state.dialogo_index]
            transeuntes_dialogo.hablante = dialogo.hablante
            transeuntes_dialogo.texto_completo = dialogo.texto
            transeuntes_dialogo.texto_visible = ""
            transeuntes_dialogo.char_index = 0
            transeuntes_dialogo.alpha = 0
          else
            -- Terminó la ignorada, activar tarea 13 y permitir volver a casa
            transeuntes_dialogo.mostrar_texto = false
            borrachos_state.dialogo_activo = false
            tareas.actual = 13  -- "Volver a casa y anotar pruebas"
            tareas.alpha = 0
            puerta_restaurante_state.puede_salir_rest = true
          end
        end
        space_pressed = true

      -- === DIA 3: LEVANTARSE DE LA SILLA ===
      elseif silla_state.esta_sentado and tareas.actual == 12 and game_state == "restaurante" then
        silla_state.esta_sentado = false
        detective.visible = true
        tareas.alpha = 0
        space_pressed = true

      -- === DIA 3: HABLAR CON BORRACHOS ===
      elseif game_state == "restaurante" and isNearBorrachos() and tareas.actual == 12 and not silla_state.esta_sentado then
        borrachos_state.pregunta_hecha = true
        borrachos_state.dialogo_activo = true
        borrachos_state.dialogo_index = 1
        local primer_dialogo = pregunta_borrachos[1]
        transeuntes_dialogo.mostrar_texto = true
        transeuntes_dialogo.hablante = primer_dialogo.hablante
        transeuntes_dialogo.texto_completo = primer_dialogo.texto
        transeuntes_dialogo.texto_visible = ""
        transeuntes_dialogo.char_index = 0
        transeuntes_dialogo.alpha = 0
        transeuntes_dialogo.mostrar_texto = true
        space_pressed = true

      -- === DIA 3: VOLVER A CASA DESDE RESTAURANTE ===
      elseif puerta_restaurante_state.puede_salir_rest and isNearPuertaRestaurante() and game_state == "restaurante" and tareas.actual == 13 then
        game_state = "day3_wake"  -- Volver a casa pero en estado day3
        detective.x = OBJ.detective.x
        detective.screen_x = OBJ.detective.screen_x
        detective.y = OBJ.detective.y
        detective.animation.direction = "left"
        detective.animation.idle = true
        detective.animation.frame = 1
        puerta_sonido:play()
        restaurante_sonido:stop()  -- Detener sonido del restaurante
        -- Iniciar transición a día 4
        dia4_state.iniciado = true
        dia4_state.pantalla_negra = false
        dia4_state.fade_alpha = 0
        space_pressed = true

      -- === INICIAR INTERACCIÓN CON TRANSEÚNTES ===
      -- Solo si NO hay un diálogo activo
      elseif game_state == "city" and isNearTranseuntes() then
        -- Escuchar conversación (tarea 5)
        if tareas.actual == 5 and not transeuntes_state.conversacion_escuchada then
          transeuntes_state.conversacion_escuchada = true
          transeuntes_state.dialogo_activo = true
          transeuntes_state.dialogo_index = 1
          -- Iniciar primer diálogo
          local dialogo = conversacion_transeuntes[1]
          transeuntes_dialogo.hablante = dialogo.hablante
          transeuntes_dialogo.texto_completo = dialogo.texto
          transeuntes_dialogo.texto_visible = ""
          transeuntes_dialogo.char_index = 0
          transeuntes_dialogo.mostrar_texto = true
          transeuntes_dialogo.alpha = 0
          space_pressed = true

        -- Hacer pregunta (tarea 6)
        elseif tareas.actual == 6 and not transeuntes_state.pregunta_hecha then
          transeuntes_state.pregunta_hecha = true
          transeuntes_state.dialogo_activo = true
          transeuntes_state.dialogo_index = 1
          -- Iniciar pregunta de Josuelito
          local dialogo = pregunta_josuelito[1]
          transeuntes_dialogo.hablante = dialogo.hablante
          transeuntes_dialogo.texto_completo = dialogo.texto
          transeuntes_dialogo.texto_visible = ""
          transeuntes_dialogo.char_index = 0
          transeuntes_dialogo.mostrar_texto = true
          transeuntes_dialogo.alpha = 0
          space_pressed = true
        end

      -- === INTERACCIÓN CON VIEJAS (PNG3 y PNG4) ===
      elseif game_state == "city" and tareas.actual == 7 and isNearViejas() and not viejas_state.conversacion_escuchada then
        viejas_state.conversacion_escuchada = true
        viejas_state.dialogo_activo = true
        viejas_state.dialogo_index = 1
        -- Iniciar primer diálogo
        local dialogo = conversacion_viejas[1]
        transeuntes_dialogo.hablante = dialogo.hablante
        transeuntes_dialogo.texto_completo = dialogo.texto
        transeuntes_dialogo.texto_visible = ""
        transeuntes_dialogo.char_index = 0
        transeuntes_dialogo.mostrar_texto = true
        transeuntes_dialogo.alpha = 0
        space_pressed = true

      -- === REGRESAR A CASA DESDE CIUDAD ===
      elseif puerta_ciudad_state.puede_entrar and isNearPuertaCiudad() and game_state == "city" then
        dia3_state.iniciado = true
        dia3_state.pantalla_negra = false
        dia3_state.fade_alpha = 0
        dia3_state.mostrar_titulo = false
        dia3_state.titulo_alpha = 0
        dia3_state.titulo_timer = 0
        dia3_state.titulo_fade_out = false
        dia3_state.fade_out_timer = 0
        dia3_state.transicion_completa = false
        space_pressed = true
      end
    end
  else
    space_pressed = false
  end

  -- Fades de objetivos
  if tareas.actual == 1 and not radio_state.mostrar_texto then
    tareas.alpha = math.min(1, tareas.alpha + tareas.fade_speed * dt)
  elseif tareas.actual >= 2 and tareas.actual <= 13 then
    tareas.alpha = math.min(1, tareas.alpha + tareas.fade_speed * dt)
  end

  -- Typewriter radio
  if radio_state.mostrar_texto then
    radio_state.alpha = math.min(1, radio_state.alpha + radio_state.fade_speed * dt)
    if radio_state.char_index < #radio_state.texto_completo then
      if radio_state.is_paused then
        radio_state.pause_timer = radio_state.pause_timer + dt
        if radio_state.pause_timer >= radio_state.pause_duration then
          radio_state.is_paused, radio_state.pause_timer = false, 0
        end
      else
        radio_state.char_timer = radio_state.char_timer + dt
        if radio_state.char_timer >= radio_state.char_speed then
          radio_state.char_timer = 0
          radio_state.char_index = radio_state.char_index + 1
          radio_state.texto_visible = string.sub(radio_state.texto_completo, 1, radio_state.char_index)
          if radio_state.char_index > 1 then
            local prev = string.sub(radio_state.texto_completo, radio_state.char_index-1, radio_state.char_index-1)
            local curr = string.sub(radio_state.texto_completo, radio_state.char_index, radio_state.char_index)
            if prev == "\n" and curr == "\n" then radio_state.is_paused = true end
          end
        end
      end
    else
      if radio_sonido:isPlaying() and not radio_fade.is_fading then
        radio_fade.is_fading, radio_fade.timer = true, 0
      end
    end
  end

  -- Fade out radio audio
  if radio_fade.is_fading then
    radio_fade.timer = radio_fade.timer + dt
    local k = radio_fade.timer / radio_fade.duration
    if k >= 1.0 then
      radio_sonido:stop()
      radio_fade.is_fading, radio_fade.timer = false, 0
    else
      radio_sonido:setVolume(radio_fade.original_volume * (1.0 - k))
    end
  end

  -- Typewriter detective
  if detective_text_state.mostrar_texto then
    detective_text_state.alpha = math.min(1, detective_text_state.alpha + detective_text_state.fade_speed * dt)
    if detective_text_state.char_index < #detective_text_state.texto_completo then
      if detective_text_state.is_paused then
        detective_text_state.pause_timer = detective_text_state.pause_timer + dt
        if detective_text_state.pause_timer >= detective_text_state.pause_duration then
          detective_text_state.is_paused, detective_text_state.pause_timer = false, 0
        end
      else
        detective_text_state.char_timer = detective_text_state.char_timer + dt
        if detective_text_state.char_timer >= detective_text_state.char_speed then
          detective_text_state.char_timer = 0
          detective_text_state.char_index = detective_text_state.char_index + 1
          detective_text_state.texto_visible = string.sub(detective_text_state.texto_completo, 1, detective_text_state.char_index)
          if detective_text_state.char_index > 1 then
            local prev = string.sub(detective_text_state.texto_completo, detective_text_state.char_index-1, detective_text_state.char_index-1)
            local curr = string.sub(detective_text_state.texto_completo, detective_text_state.char_index, detective_text_state.char_index)
            if prev == "\n" and curr == "\n" then detective_text_state.is_paused = true end
          end
        end
      end
    else
      if detective_text_state.mostrar_texto then
        detective_text_state.finished_timer = detective_text_state.finished_timer + dt
        if detective_text_state.finished_timer >= detective_text_state.finished_delay then
          detective_text_state.mostrar_texto = false
          detective_text_state.alpha = 0
          tareas.actual, tareas.alpha = 2, 0
        end
      end
    end
  end

  -- Typewriter tablero
  if tablero_text_state.mostrar_texto then
    tablero_text_state.alpha = math.min(1, tablero_text_state.alpha + tablero_text_state.fade_speed * dt)
    if tablero_text_state.char_index < #tablero_text_state.texto_completo then
      if tablero_text_state.is_paused then
        tablero_text_state.pause_timer = tablero_text_state.pause_timer + dt
        if tablero_text_state.pause_timer >= tablero_text_state.pause_duration then
          tablero_text_state.is_paused, tablero_text_state.pause_timer = false, 0
        end
      else
        tablero_text_state.char_timer = tablero_text_state.char_timer + dt
        if tablero_text_state.char_timer >= tablero_text_state.char_speed then
          tablero_text_state.char_timer = 0
          tablero_text_state.char_index = tablero_text_state.char_index + 1
          tablero_text_state.texto_visible = string.sub(tablero_text_state.texto_completo, 1, tablero_text_state.char_index)
          if tablero_text_state.char_index > 1 then
            local prev = string.sub(tablero_text_state.texto_completo, tablero_text_state.char_index-1, tablero_text_state.char_index-1)
            local curr = string.sub(tablero_text_state.texto_completo, tablero_text_state.char_index, tablero_text_state.char_index)
            if prev == "\n" and curr == "\n" then tablero_text_state.is_paused = true end
          end
        end
      end
    else
      if tablero_text_state.mostrar_texto then
        tablero_text_state.finished_timer = tablero_text_state.finished_timer + dt
        if tablero_text_state.finished_timer >= tablero_text_state.finished_delay then
          tablero_text_state.mostrar_texto = false
          tablero_text_state.alpha = 0
          tareas.actual, tareas.alpha = 3, 0
          cama_state.puede_dormir = true
        end
      end
    end
  end

  -- Typewriter dia3 texto inicial
  if dia3_text_state.mostrar_texto then
    dia3_text_state.alpha = math.min(1, dia3_text_state.alpha + dia3_text_state.fade_speed * dt)
    if dia3_text_state.char_index < #dia3_text_state.texto_completo then
      if dia3_text_state.is_paused then
        dia3_text_state.pause_timer = dia3_text_state.pause_timer + dt
        if dia3_text_state.pause_timer >= dia3_text_state.pause_duration then
          dia3_text_state.is_paused, dia3_text_state.pause_timer = false, 0
        end
      else
        dia3_text_state.char_timer = dia3_text_state.char_timer + dt
        if dia3_text_state.char_timer >= dia3_text_state.char_speed then
          dia3_text_state.char_timer = 0
          dia3_text_state.char_index = dia3_text_state.char_index + 1
          dia3_text_state.texto_visible = string.sub(dia3_text_state.texto_completo, 1, dia3_text_state.char_index)
          if dia3_text_state.char_index > 1 then
            local prev = string.sub(dia3_text_state.texto_completo, dia3_text_state.char_index-1, dia3_text_state.char_index-1)
            local curr = string.sub(dia3_text_state.texto_completo, dia3_text_state.char_index, dia3_text_state.char_index)
            if prev == "\n" and curr == "\n" then dia3_text_state.is_paused = true end
          end
        end
      end
    else
      -- Termino de escribir, marcar como terminado
      if not dia3_text_state.finished then
        dia3_text_state.finished = true
      end
    end
  end

  -- Transición día 4
  if dia4_state.iniciado and not dia4_state.transicion_completa then
    -- Fase 1: Fade a negro
    if not dia4_state.pantalla_negra then
      dia4_state.fade_alpha = math.min(1, dia4_state.fade_alpha + dia4_state.fade_speed * dt)
      if dia4_state.fade_alpha >= 1 then
        dia4_state.pantalla_negra = true
        dia4_state.mostrar_titulo = true
        dia4_state.titulo_alpha = 0
        dia4_state.titulo_timer = 0
        -- Cambiar canvas a casa_hoja3
        OBJ.buildCasaHoja3()
      end
    -- Fase 2: Mostrar título "DIA 4"
    elseif dia4_state.mostrar_titulo and not dia4_state.titulo_fade_out then
      dia4_state.titulo_alpha = math.min(1, dia4_state.titulo_alpha + dia4_state.fade_speed * dt)
      dia4_state.titulo_timer = dia4_state.titulo_timer + dt
      if dia4_state.titulo_timer >= dia4_state.titulo_duration then
        dia4_state.titulo_fade_out = true
        dia4_state.fade_out_timer = 0
      end
    -- Fase 3: Fade out del título y pantalla negra
    elseif dia4_state.titulo_fade_out then
      dia4_state.titulo_alpha = math.max(0, dia4_state.titulo_alpha - dia4_state.fade_speed * dt)
      dia4_state.fade_out_timer = dia4_state.fade_out_timer + dt
      if dia4_state.fade_out_timer >= 1.0 then
        dia4_state.fade_alpha = math.max(0, dia4_state.fade_alpha - dia4_state.fade_speed * dt)
        if dia4_state.fade_alpha <= 0 then
          dia4_state.transicion_completa = true
          game_state = "day4_wake"
        end
      end
    end
  end
end

-- ================== LOVE.DRAW ==================
function love.draw()
  -- ===== MENÚ =====
  if game_state == "menu" then
    local ww, wh = love.graphics.getDimensions()
    love.graphics.clear(0.02, 0.03, 0.05)
    love.graphics.setFont(title_font)
    love.graphics.setColor(0.9, 0.9, 0.95, 1)
    local title = "Que pesadilla..."
    local tw = title_font:getWidth(title)
    love.graphics.print(title, (ww - tw)/2, wh/2 - 100)
    love.graphics.setFont(subtitle_font)
    local a = (math.sin(menu_blink_timer * 3) + 1)/2
    love.graphics.setColor(0.7, 0.8, 0.9, a)
    local sub = "Presiona SPACE para continuar"
    local sw = subtitle_font:getWidth(sub)
    love.graphics.print(sub, (ww - sw)/2, wh/2 + 60)
    love.graphics.setColor(1,1,1,1)
    return
  end

  -- ===== TÍTULO "DÍA 1" =====
  if game_state == "day1_title" then
    local ww, wh = love.graphics.getDimensions()
    -- fondo de la casa detrás
    local cx, cy = clampHouseOffset(detective.x, detective.y)
    lighting_shader:send("light_pos", {detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.setShader(lighting_shader)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(casa_canvas, cx*OBJ.SCALE, cy*OBJ.SCALE)
    love.graphics.setShader()

    -- overlay negro suave
    love.graphics.setColor(0,0,0, 0.35)
    love.graphics.rectangle("fill", 0,0, ww, wh)

    -- título
    love.graphics.setFont(title_font)
    love.graphics.setColor(0.9, 0.9, 0.95, day1_state.alpha)
    local t = "DIA 1"
    local tw = title_font:getWidth(t)
    love.graphics.print(t, (ww - tw)/2, wh/2 - 50)
    love.graphics.setColor(1,1,1,1)
    return
  end

  -- ===== TRANSICIÓN DÍA 2 =====
  if dia2_state.iniciado then
    local ww, wh = love.graphics.getDimensions()
    if not dia2_state.pantalla_negra then
      local cx, cy = clampHouseOffset(detective.x, detective.y)
      lighting_shader:send("light_pos", {detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE})
      lighting_shader:send("ambient_strength", 0.75)
      love.graphics.setShader(lighting_shader)
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(casa_canvas, cx*OBJ.SCALE, cy*OBJ.SCALE)
      love.graphics.setShader()
      love.graphics.scale(OBJ.SCALE)
      if detective.animation.direction == "left" then
        love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y)
      else
        love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y, 0, -1, 1, OBJ.detective.sprite.quad_width, 0)
      end
      love.graphics.scale(1/OBJ.SCALE)
    end
    love.graphics.setColor(0,0,0, dia2_state.fade_alpha)
    love.graphics.rectangle("fill", 0,0, ww, wh)
    if dia2_state.mostrar_titulo then
      love.graphics.setFont(title_font)
      love.graphics.setColor(0.9,0.9,0.95, dia2_state.titulo_alpha)
      local t = "DIA 2"; local tw = title_font:getWidth(t)
      love.graphics.print(t, (ww - tw)/2, wh/2 - 50)
    end
    love.graphics.setColor(1,1,1,1)
    return
  end

  -- ===== TRANSICIÓN DÍA 3 (DIBUJO) =====
  if dia3_state.iniciado then
    local ww, wh = love.graphics.getDimensions()
    if not dia3_state.pantalla_negra then
      local cx, cy = clampCityOffset(detective.x, detective.y)
      lighting_shader:send("light_pos", {detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE})
      lighting_shader:send("ambient_strength", 0.58)
      lighting_shader:send("ambient_color", {0.65, 0.63, 0.58})
      lighting_shader:send("light_radius", 900.0)
      love.graphics.setShader(lighting_shader)
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(city_canvas, cx*OBJ.SCALE, cy*OBJ.SCALE)
      love.graphics.setShader()
      love.graphics.scale(OBJ.SCALE)
      if detective.animation.direction == "left" then
        love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y)
      else
        love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y, 0, -1, 1, OBJ.detective.sprite.quad_width, 0)
      end
      love.graphics.scale(1/OBJ.SCALE)
    end
    love.graphics.setColor(0,0,0, dia3_state.fade_alpha)
    love.graphics.rectangle("fill", 0,0, ww, wh)
    if dia3_state.mostrar_titulo then
      love.graphics.setFont(title_font)
      love.graphics.setColor(0.9,0.9,0.95, dia3_state.titulo_alpha)
      local t = "DIA 3"; local tw = title_font:getWidth(t)
      love.graphics.print(t, (ww - tw)/2, wh/2 - 50)
    end
    love.graphics.setColor(1,1,1,1)
    return
  end

  -- ===== ESCENA DORMIR =====
  if game_state == "sleeping" then
    local cx, cy = clampHouseOffset(detective.x, detective.y)
    lighting_shader:send("light_pos", {detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE})
    lighting_shader:send("ambient_strength", 0.85)
    love.graphics.setShader(lighting_shader)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(casa_canvas, cx*OBJ.SCALE, cy*OBJ.SCALE)
    love.graphics.setShader()

    love.graphics.scale(OBJ.SCALE)
    love.graphics.setColor(1,1,1, sleeping_state.cama_alpha)
    love.graphics.draw(OBJ.casa.sprite.imagen, quads_casa.cama_dormi, 0 - cx, 38 - cy)
    love.graphics.scale(1/OBJ.SCALE)

    if sleeping_state.mostrar_texto then
      love.graphics.setFont(radio_font)
      local ww, wh = love.graphics.getDimensions()
      local bw, bh = 400, 150
      local bx, by = ww/2 - bw/2, wh/2 - bh/2
      love.graphics.setColor(0.15, 0.1, 0.1, sleeping_state.alpha * 0.95)
      love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
      love.graphics.setColor(0.7, 0.5, 0.3, sleeping_state.alpha * 0.8)
      love.graphics.setLineWidth(3); love.graphics.rectangle("line", bx, by, bw, bh, 10,10)
      love.graphics.setColor(0.9, 0.7, 0.5, sleeping_state.alpha * 0.6)
      love.graphics.setLineWidth(2); love.graphics.line(bx+15, by+8, bx+bw-15, by+8)
      love.graphics.setColor(0.95, 0.9, 0.85, sleeping_state.alpha)
      love.graphics.printf(sleeping_state.texto_visible, bx+sleeping_state.box_padding, by+sleeping_state.box_padding, bw - sleeping_state.box_padding*2, "left")
    end
    love.graphics.setColor(1,1,1,1)
    return
  end

  -- ===== GAMEPLAY =====
  -- Determinar qué canvas usar según el estado
  local current_canvas = casa_canvas
  if game_state == "city" then
    current_canvas = city_canvas
  elseif game_state == "restaurante" then
    if silla_state.esta_sentado then
      current_canvas = OBJ.restaurante_sen_canvas
    else
      current_canvas = OBJ.restaurante_canvas
    end
  elseif game_state == "day3_wake" then
    current_canvas = casa_canvas  -- Usa casa_canvas que fue establecido a casa_hoja2
  elseif game_state == "day4_wake" then
    current_canvas = OBJ.casa_hoja3  -- Casa con 3 hojas en tablero
  end

  -- Usar el clamp correcto según el estado del juego
  local cx, cy
  if game_state == "city" then
    cx, cy = clampCityOffset(detective.x, detective.y)
  elseif game_state == "restaurante" then
    cx, cy = clampRestauranteOffset(detective.x, detective.y)
  else
    cx, cy = clampHouseOffset(detective.x, detective.y)
  end

  lighting_shader:send("light_pos", {detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE})

  -- Configuración de iluminación según el estado del juego
  if game_state == "city" then
    -- Luz de día en la ciudad (tenue y atmosférica)
    lighting_shader:send("ambient_strength", 0.58)
    lighting_shader:send("ambient_color", {0.65, 0.63, 0.58})  -- Color más apagado
    lighting_shader:send("light_radius", 900.0)  -- Radio más contenido
  elseif game_state == "restaurante" then
    -- Luz del restaurante (similar a ciudad pero más cálida)
    lighting_shader:send("ambient_strength", 0.65)
    lighting_shader:send("ambient_color", {0.7, 0.65, 0.55})  -- Color cálido
    lighting_shader:send("light_radius", 700.0)
  else
    -- Luz tenebrosa en la casa
    lighting_shader:send("ambient_strength", 0.75)
    lighting_shader:send("ambient_color", {0.1, 0.15, 0.2})  -- Color frío oscuro
    lighting_shader:send("light_radius", 550.0)
  end

  love.graphics.setShader(lighting_shader)

  if math.abs(cx - prevX) > 0.1 then
    love.graphics.setColor(1,1,1,0.35)
    love.graphics.draw(current_canvas, prevX*OBJ.SCALE, prevY*OBJ.SCALE)
  end
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(current_canvas, cx*OBJ.SCALE, cy*OBJ.SCALE)
  prevX, prevY = cx, cy
  love.graphics.setShader()

  love.graphics.scale(OBJ.SCALE)
  if detective.visible then
    if detective.animation.direction == "left" then
      love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y)
    else
      love.graphics.draw(OBJ.detective.sprite.imagen, quads_detective[detective.animation.frame], detective.screen_x, detective.y, 0, -1, 1, OBJ.detective.sprite.quad_width, 0)
    end
  end
  love.graphics.scale(1/OBJ.SCALE)

  -- Prompts
  if isNearRadio() and not radio_state.usado and game_state == "playing" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Radio", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end
  if tareas.actual == 2 and isNearTablero() and not tablero_state.usado and game_state == "playing" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Tablero", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end
  if cama_state.puede_dormir and isNearCama() and game_state == "playing" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Dormir", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end
  if puerta_state.puede_salir and isNearPuerta() and game_state == "day2_wake" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Salir al pueblo", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end
  if radio_state.mostrar_texto and radio_state.char_index >= #radio_state.texto_completo then
    love.graphics.setColor(1,1,1, 0.8 * (math.sin(love.timer.getTime()*4)*0.5 + 0.5))
    love.graphics.print("[SPACE] Continuar", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts ciudad - Transeúntes
  if game_state == "city" and isNearTranseuntes() then
    if tareas.actual == 5 and not transeuntes_state.conversacion_escuchada then
      love.graphics.setColor(1,1,1,0.8)
      love.graphics.print("[SPACE] Escuchar conversacion", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
    elseif tareas.actual == 6 and not transeuntes_state.pregunta_hecha then
      love.graphics.setColor(1,1,1,0.8)
      love.graphics.print("[SPACE] Pedir informacion", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
    end
  end
  if transeuntes_dialogo.mostrar_texto and transeuntes_dialogo.char_index >= #transeuntes_dialogo.texto_completo then
    love.graphics.setColor(1,1,1, 0.8 * (math.sin(love.timer.getTime()*4)*0.5 + 0.5))
    love.graphics.print("[SPACE] Continuar", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts ciudad - Viejas
  if game_state == "city" and tareas.actual == 7 and isNearViejas() and not viejas_state.conversacion_escuchada then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Escuchar conversacion", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts ciudad - Regresar a casa
  if puerta_ciudad_state.puede_entrar and isNearPuertaCiudad() and game_state == "city" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Regresar a casa", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts día 3 - Casa
  if dia3_text_state.mostrar_texto and dia3_text_state.finished then
    love.graphics.setColor(1,1,1, 0.8 * (math.sin(love.timer.getTime()*4)*0.5 + 0.5))
    love.graphics.print("[SPACE] Continuar", love.graphics.getWidth()/2 - 50, love.graphics.getHeight() - 100)
  end
  if puerta_casa_dia3_state.puede_salir_dia3 and isNearPuertaCasaDia3() and game_state == "day3_wake" then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Ir a restaurante", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts restaurante - Silla
  if silla_state.puede_sentarse and isNearSilla() and game_state == "restaurante" and not silla_state.esta_sentado then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Sentarse", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts restaurante - Levantarse
  if silla_state.esta_sentado and tareas.actual == 12 and game_state == "restaurante" then
    love.graphics.setColor(1,1,1, 0.8 * (math.sin(love.timer.getTime()*4)*0.5 + 0.5))
    love.graphics.print("[SPACE] Levantarse", love.graphics.getWidth()/2 - 50, love.graphics.getHeight() - 100)
  end

  -- Prompts restaurante - Hablar con borrachos
  if game_state == "restaurante" and isNearBorrachos() and tareas.actual == 12 and not silla_state.esta_sentado then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Hablar", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- Prompts restaurante - Volver a casa
  if puerta_restaurante_state.puede_salir_rest and isNearPuertaRestaurante() and game_state == "restaurante" and tareas.actual == 13 then
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.print("[SPACE] Volver a casa", detective.screen_x*OBJ.SCALE+10, (detective.y-10)*OBJ.SCALE+50)
  end

  -- DEBUG: Mostrar posición del detective y distancia a la puerta en día 2
  if game_state == "day2_wake" then
    local dx, dy = getDetectiveWorldPos()
    local dist = math.sqrt((dx - puerta_state.x)^2 + (dy - puerta_state.y)^2)
    love.graphics.setColor(1,1,0,0.8)
    --love.graphics.print(string.format("Det: %.1f, %.1f | Puerta: %.1f, %.1f | Dist: %.1f", 
      --dx, dy, puerta_state.x, puerta_state.y, dist), 10, 10)
    
    -- Dibujar círculo en la posición de la puerta
    --love.graphics.setColor(0,1,0,0.5)
    local px, py = (puerta_state.x + cx)*OBJ.SCALE, (puerta_state.y + cy)*OBJ.SCALE
    --love.graphics.circle("line", px, py, puerta_state.cercania*OBJ.SCALE)
  end

  -- Caja texto radio
  if radio_state.mostrar_texto then
    love.graphics.setFont(radio_font)
    local rsx, rsy = (radio_state.x + cx)*OBJ.SCALE, (radio_state.y + cy)*OBJ.SCALE
    local bw, bh = 600, 280
    local bx, by = rsx - bw/2, rsy - bh - 30
    local ww, wh = love.graphics.getDimensions()
    if bx < 10 then bx = 10 end
    if bx + bw > ww - 10 then bx = ww - bw - 10 end
    if by < 10 then by = 10 end
    love.graphics.setColor(0.1,0.1,0.15, radio_state.alpha*0.95)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.3,0.5,0.7, radio_state.alpha*0.8)
    love.graphics.setLineWidth(3); love.graphics.rectangle("line", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.5,0.7,0.9, radio_state.alpha*0.6)
    love.graphics.setLineWidth(2); love.graphics.line(bx+15, by+8, bx+bw-15, by+8)
    love.graphics.setColor(0.9,0.9,0.95, radio_state.alpha)
    love.graphics.printf(radio_state.texto_visible, bx+radio_state.box_padding, by+radio_state.box_padding, bw - radio_state.box_padding*2, "left")
  end

  -- Caja texto detective
  if detective_text_state.mostrar_texto then
    love.graphics.setFont(radio_font)
    local dsx, dsy = detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE
    local bw, bh = 400, 200
    local bx, by = dsx + 20, dsy - bh/2 - 20
    local ww, wh = love.graphics.getDimensions()
    if bx + bw > ww - 10 then bx = dsx - bw - 20 end
    if bx < 10 then bx = 10 end
    if by < 10 then by = 10 end
    if by + bh > wh - 10 then by = wh - bh - 10 end
    love.graphics.setColor(0.15,0.1,0.1, detective_text_state.alpha*0.95)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.7,0.5,0.3, detective_text_state.alpha*0.8)
    love.graphics.setLineWidth(3); love.graphics.rectangle("line", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.9,0.7,0.5, detective_text_state.alpha*0.6)
    love.graphics.setLineWidth(2); love.graphics.line(bx+15, by+8, bx+bw-15, by+8)
    love.graphics.setColor(0.95,0.9,0.85, detective_text_state.alpha)
    love.graphics.printf(detective_text_state.texto_visible, bx+detective_text_state.box_padding, by+detective_text_state.box_padding, bw - detective_text_state.box_padding*2, "left")
  end

  -- Caja texto tablero
  if tablero_text_state.mostrar_texto then
    love.graphics.setFont(radio_font)
    local dsx, dsy = detective.screen_x*OBJ.SCALE, detective.y*OBJ.SCALE
    local bw, bh = 450, 220
    local bx, by = dsx + 20, dsy - bh/2 - 20
    local ww, wh = love.graphics.getDimensions()
    if bx + bw > ww - 10 then bx = dsx - bw - 20 end
    if bx < 10 then bx = 10 end
    if by < 10 then by = 10 end
    if by + bh > wh - 10 then by = wh - bh - 10 end
    love.graphics.setColor(0.15,0.1,0.1, tablero_text_state.alpha*0.95)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.7,0.5,0.3, tablero_text_state.alpha*0.8)
    love.graphics.setLineWidth(3); love.graphics.rectangle("line", bx, by, bw, bh, 10,10)
    love.graphics.setColor(0.9,0.7,0.5, tablero_text_state.alpha*0.6)
    love.graphics.setLineWidth(2); love.graphics.line(bx+15, by+8, bx+bw-15, by+8)
    love.graphics.setColor(0.95,0.9,0.85, tablero_text_state.alpha)
    love.graphics.printf(tablero_text_state.texto_visible, bx+tablero_text_state.box_padding, by+tablero_text_state.box_padding, bw - tablero_text_state.box_padding*2, "left")
  end

  -- Caja texto transeuntes/borrachos
  if transeuntes_dialogo.mostrar_texto then
    love.graphics.setFont(radio_font)

    -- DEBUG
    if game_state == "restaurante" and borrachos_state.dialogo_activo then
      print("DRAW - Dibujando dialogo | Alpha: " .. transeuntes_dialogo.alpha .. " | Hablante: " .. transeuntes_dialogo.hablante)
    end

    local bw, bh = 550, 250
    local ww, wh = love.graphics.getDimensions()
    local bx, by

    -- En restaurante, centrar la caja en pantalla (sin depender de coordenadas)
    if game_state == "restaurante" and borrachos_state.dialogo_activo then
      bx = (ww - bw) / 2
      by = wh - bh - 50  -- Cerca del fondo de la pantalla
    else
      -- En ciudad, usar coordenadas de transeuntes/viejas
      local tsx, tsy = (transeuntes_state.x + cx)*OBJ.SCALE, (transeuntes_state.y + cy)*OBJ.SCALE
      bx, by = tsx - bw/2, tsy - bh - 40
      -- Ajustar posicion para que no se salga de pantalla
      if bx < 10 then bx = 10 end
      if bx + bw > ww - 10 then bx = ww - bw - 10 end
      if by < 10 then by = 10 end
    end

    -- Colores segun quien habla
    local bg_color, border_color, line_color, text_color
    if transeuntes_dialogo.hablante == "PNG1" then
      bg_color = {0.12, 0.14, 0.18}
      border_color = {0.5, 0.6, 0.7}
      line_color = {0.6, 0.7, 0.8}
      text_color = {0.9, 0.92, 0.95}
    elseif transeuntes_dialogo.hablante == "PNG2" then
      bg_color = {0.18, 0.15, 0.12}
      border_color = {0.7, 0.6, 0.5}
      line_color = {0.8, 0.7, 0.6}
      text_color = {0.95, 0.92, 0.9}
    elseif transeuntes_dialogo.hablante == "JOSUELITO" then
      bg_color = {0.15, 0.1, 0.1}
      border_color = {0.7, 0.5, 0.3}
      line_color = {0.9, 0.7, 0.5}
      text_color = {0.95, 0.9, 0.85}
    elseif transeuntes_dialogo.hablante == "SILENCIO" then
      bg_color = {0.08, 0.08, 0.08}
      border_color = {0.3, 0.3, 0.3}
      line_color = {0.4, 0.4, 0.4}
      text_color = {0.6, 0.6, 0.6}
    elseif transeuntes_dialogo.hablante == "PNG3" then
      bg_color = {0.14, 0.10, 0.14}  -- Tonos púrpura oscuro
      border_color = {0.6, 0.4, 0.6}
      line_color = {0.7, 0.5, 0.7}
      text_color = {0.92, 0.88, 0.92}
    elseif transeuntes_dialogo.hablante == "PNG4" then
      bg_color = {0.10, 0.14, 0.12}  -- Tonos verde oscuro
      border_color = {0.4, 0.6, 0.5}
      line_color = {0.5, 0.7, 0.6}
      text_color = {0.88, 0.92, 0.90}
    elseif transeuntes_dialogo.hablante == "PNG5" then
      bg_color = {0.14, 0.12, 0.10}  -- Tonos marron/ambar
      border_color = {0.7, 0.5, 0.3}
      line_color = {0.8, 0.6, 0.4}
      text_color = {0.95, 0.90, 0.85}
    elseif transeuntes_dialogo.hablante == "PNG6" then
      bg_color = {0.10, 0.12, 0.16}  -- Tonos azul oscuro
      border_color = {0.3, 0.5, 0.7}
      line_color = {0.4, 0.6, 0.8}
      text_color = {0.85, 0.90, 0.95}
    end

    -- Dibujar caja
    love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3], transeuntes_dialogo.alpha*0.95)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
    love.graphics.setColor(border_color[1], border_color[2], border_color[3], transeuntes_dialogo.alpha*0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", bx, by, bw, bh, 10, 10)

    -- Linea decorativa superior
    love.graphics.setColor(line_color[1], line_color[2], line_color[3], transeuntes_dialogo.alpha*0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(bx+15, by+8, bx+bw-15, by+8)

    -- Nombre del hablante
    love.graphics.setColor(line_color[1], line_color[2], line_color[3], transeuntes_dialogo.alpha)
    love.graphics.printf(transeuntes_dialogo.hablante, bx+transeuntes_dialogo.box_padding, by+5, bw - transeuntes_dialogo.box_padding*2, "left")

    -- Texto del dialogo
    love.graphics.setColor(text_color[1], text_color[2], text_color[3], transeuntes_dialogo.alpha)
    love.graphics.printf(transeuntes_dialogo.texto_visible, bx+transeuntes_dialogo.box_padding, by+transeuntes_dialogo.box_padding+25, bw - transeuntes_dialogo.box_padding*2, "left")
  end

  -- Caja texto dia3 inicial
  if dia3_text_state.mostrar_texto then
    love.graphics.setFont(radio_font)
    local ww, wh = love.graphics.getDimensions()
    local bw, bh = 600, 180
    local bx, by = (ww - bw)/2, (wh - bh)/2
    love.graphics.setColor(0.15, 0.1, 0.1, dia3_text_state.alpha*0.95)
    love.graphics.rectangle("fill", bx, by, bw, bh, 10, 10)
    love.graphics.setColor(0.7, 0.5, 0.3, dia3_text_state.alpha*0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", bx, by, bw, bh, 10, 10)
    love.graphics.setColor(0.9, 0.7, 0.5, dia3_text_state.alpha*0.6)
    love.graphics.setLineWidth(2)
    love.graphics.line(bx+15, by+8, bx+bw-15, by+8)
    love.graphics.setColor(0.95, 0.9, 0.85, dia3_text_state.alpha)
    love.graphics.printf(dia3_text_state.texto_visible, bx+dia3_text_state.box_padding, by+dia3_text_state.box_padding, bw - dia3_text_state.box_padding*2, "left")
  end

  -- Transicion dia 4
  if dia4_state.iniciado and not dia4_state.transicion_completa then
    local ww, wh = love.graphics.getDimensions()
    -- Pantalla negra
    love.graphics.setColor(0, 0, 0, dia4_state.fade_alpha)
    love.graphics.rectangle("fill", 0, 0, ww, wh)
    -- Titulo "DIA 4"
    if dia4_state.mostrar_titulo then
      love.graphics.setFont(title_font)
      love.graphics.setColor(0.9, 0.9, 0.95, dia4_state.titulo_alpha)
      local titulo = "DIA 4"
      local tw = title_font:getWidth(titulo)
      love.graphics.print(titulo, (ww - tw)/2, wh/2 - 40)
    end
  end

  -- Objetivos (arriba-derecha)
  if tareas.actual > 0 and tareas.actual <= #tareas.lista then
    love.graphics.setFont(tarea_font)
    local ww, wh = love.graphics.getDimensions()
    local texto = "Objetivo: " .. tareas.lista[tareas.actual]
    local padding = 15
    local bw = tarea_font:getWidth(texto) + padding*2
    local bh = tarea_font:getHeight() + padding*2
    local bx, by = ww - bw - 20, 20
    love.graphics.setColor(0.1,0.1,0.15, tareas.alpha*0.9)
    love.graphics.rectangle("fill", bx, by, bw, bh, 8,8)
    love.graphics.setColor(0.4,0.6,0.8, tareas.alpha*0.8)
    love.graphics.setLineWidth(2); love.graphics.rectangle("line", bx, by, bw, bh, 8,8)
    love.graphics.setColor(0.9,0.95,1, tareas.alpha)
    love.graphics.print(texto, bx+padding, by+padding)
  end

  -- DEBUG: Mostrar info en pantalla
  if debug_info ~= "" then
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(debug_info, 10, 300)
  end

  love.graphics.setColor(1,1,1,1)
end

-- ================== ESTADO DE DORMIR ==================
sleeping_state = {
  mostrar_texto = false,
  texto_completo = "Josuelito:\n\n* Que horrible pesadilla...",
  texto_visible = "",
  char_index = 0, char_timer = 0, char_speed = 0.05,
  pause_timer = 0, pause_duration = 0.8, is_paused = false,
  alpha = 0, fade_speed = 2, box_padding = 20,
  finished_timer = 0, finished_delay = 2.0,
  cama_alpha = 1.0
}