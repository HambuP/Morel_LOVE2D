-- Pantalla de Menú/Inicio
-- "LA INVENCIÓN DE MOREL"

local Menu = {}

-- Estado local del menú
local blink_timer = 0
local space_pressed = false

function Menu.init()
  blink_timer = 0
  space_pressed = false
end

function Menu.update(dt, tareas, musica_fade)
  blink_timer = blink_timer + dt

  if love.keyboard.isDown("space") then
    if not space_pressed then
      space_pressed = true
      -- Fade de música (pasado desde main.lua)
      return "day1_title"  -- Cambiar a título del día 1
    end
  else
    space_pressed = false
  end

  return nil  -- Permanecer en menú (nil = no cambiar estado)
end

function Menu.draw(title_font, subtitle_font)
  love.graphics.clear(0, 0, 0)

  -- Título principal
  love.graphics.setFont(title_font)
  local title = "Que pesadilla..."
  local w = title_font:getWidth(title)
  local h = title_font:getHeight()
  local screen_w = love.graphics.getWidth()
  local screen_h = love.graphics.getHeight()

  love.graphics.setColor(0.9, 0.85, 0.75)
  love.graphics.print(title, (screen_w - w) / 2, screen_h / 2 - h)

  -- Subtítulo parpadeante "Press SPACE to start"
  love.graphics.setFont(subtitle_font)
  local blink_alpha = math.abs(math.sin(blink_timer * 2))
  love.graphics.setColor(0.7, 0.7, 0.7, blink_alpha)
  local subtitle = "Press SPACE to start"
  local sw = subtitle_font:getWidth(subtitle)
  love.graphics.print(subtitle, (screen_w - sw) / 2, screen_h / 2 + h + 20)

  love.graphics.setColor(1, 1, 1, 1)
end

function Menu.keypressed(key)
  -- Manejar input si es necesario
end

return Menu
