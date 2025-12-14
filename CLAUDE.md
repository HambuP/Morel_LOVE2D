# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a LÖVE2D (Lua game framework) narrative detective game titled "LA INVENCION DE MOREL". The game follows a detective character named Josuelito through a multi-day investigation involving interactive dialogue, task completion, and exploration.

## Running the Game

```bash
# Run the main game
love .

# Run the city test scene
love prueba.lua
```

The game requires LÖVE2D (Love2D) to be installed and in your PATH.

## Core Architecture

### Module System

The codebase uses a modular architecture with resource management centralized in `objetos.lua`:

- **main.lua**: Game loop, state machine, and gameplay logic
- **objetos.lua**: Resource module that handles sprite loading, canvas prerendering, and utility functions
- **conf.lua**: LÖVE2D window configuration
- **prueba.lua**: Test file for city scene development (not part of main game)

### Game State Machine

The game uses a string-based state machine (`game_state` variable in main.lua:11):

- `"menu"` - Title screen
- `"day1_title"` - Day 1 transition screen
- `"sleeping"` - Bedroom sleep/wake scene
- `"playing"` - Day 1 gameplay in house
- `"day2_wake"` - Day 2 wake up in house
- `"city"` - Day 2 city exploration

### Rendering Architecture

The game uses a **prerendered canvas system** for performance:

1. **Base canvases** are created in `objetos.lua` during `OBJ.init()`:
   - `OBJ.casa_canvas` - Base house scene (no investigation board paper)
   - `OBJ.casa_hoja1` - House with paper on investigation board
   - `OBJ.city_canvas` - Full city scene with tiled backgrounds

2. **Canvas switching** happens dynamically in main.lua:
   - Line 109: `casa_canvas` starts as `OBJ.casa_canvas`
   - Line 384: Switches to `OBJ.casa_hoja1` after investigation board interaction
   - Line 286: Switches to `OBJ.casa_hoja1` when waking up on Day 2

3. **Scaling system**:
   - Global scale: `SCALE = 15` (used for final render)
   - Different sprite layers use different internal scales (10, 15, 20) for pixel-perfect placement
   - Camera offset is calculated in world units, then multiplied by SCALE for rendering

### Character Movement System

Located in main.lua:314-358:

- **Dual coordinate system**:
  - `detective.x`: World X offset (how far the world has scrolled)
  - `detective.screen_x`: Character's screen position (stays near center)
  - `detective.y`: Y position (fixed, no vertical movement)

- **Movement logic**:
  - When character is near center (`center_pos = 50`), world scrolls instead of character moving
  - When at world boundaries, character moves on screen instead
  - Clamped to margins: `margin_left = 20`, `margin_right = view_w - 12`

### Interaction System

Interactions use proximity detection (main.lua:148-164):

- Each interactive object has `x`, `y`, and `cercania` (proximity radius)
- Helper functions like `isNearRadio()`, `isNearTablero()`, etc. check distance
- SPACE key triggers interactions when near objects
- `space_pressed` flag prevents repeated triggers

### Text/Dialogue System

The game uses a typewriter effect for all dialogue:

- **Text state objects** (e.g., `radio_state`, `detective_text_state`, `tablero_text_state`) contain:
  - `texto_completo`: Full text to display
  - `texto_visible`: Currently displayed text (substring)
  - `char_index`, `char_timer`, `char_speed`: Typewriter animation state
  - `pause_at_newlines`, `pause_timer`: Pause on double newlines for dramatic effect
  - `alpha`, `fade_speed`: Fade in/out animation
  - `box_padding`: Text box padding

- Update logic in main.lua:417-525 advances the typewriter effect
- Draw logic in main.lua:704-764 renders styled text boxes

### Lighting System

Custom shader for dynamic lighting (main.lua:127-145):

- Light follows detective position (`lighting_shader:send("light_pos", ...)`)
- Radial attenuation with exponential glow
- Ambient color and strength configurable
- Applied during canvas rendering (main.lua:647-658)

### Task/Objective System

Task progression tracked in `tareas` table (main.lua:62-71):

- Linear progression through 4 tasks
- Each task completion triggers next task and state changes
- Tasks fade in/out with alpha animation
- Displayed in top-right corner (main.lua:767-781)

## Important Coordinate Systems

### House Scene
- World size: `WORLD_W = 160px` (10 tiles × 16), `WORLD_H = 96px` (6 tiles × 16)
- Tile size: `TILE = 16px`
- Detective starts at `x=0, screen_x=50, y=21`

### City Scene
- Canvas size: `CITY_W_PX = 3840px` (128×3 backgrounds × 10 scale)
- `CITY_H_PX = 1280px` (64×2 backgrounds × 10 scale)
- Uses 3×2 tiled backgrounds

### Sprite Coordinates
All sprite quads defined in `objetos.lua` use pixel coordinates from sprite sheets:
- `casa.png`: 128×64 sprite sheet
- `city.png`: 265×128 sprite sheet
- `personaje.png`: 64×32 sprite sheet (4 animation frames)
- `hojas_tablero.png`: 64×32 sprite sheet

## Audio System

Three audio sources managed in main.lua:

- `sonido_pasos`: Footstep sound (plays during movement)
- `radio_sonido`: Radio sound effect (plays during radio interaction)
- `musica_fondo`: Looping background music with fade system

Music fade uses `musica_fade` table (main.lua:26) with smooth interpolation in update loop (main.lua:169-176).

## Day/Scene Transitions

### Day 1 → Day 2
Handled by `dia2_state` (main.lua:85-89):
1. Fade to black (`fade_alpha`)
2. Show "DIA 2" title with fade in/out
3. Reset detective position
4. Switch canvas to `casa_hoja1`
5. Enable door exit (`puerta_state.puede_salir = true`)

### House → City
Triggered at puerta (main.lua:394-403):
1. Change state to `"city"`
2. Reset detective coordinates
3. Render switches to `city_canvas`

## File Structure Notes

- **fonts/**: Contains `serif.ttf` and `serif-soft.ttf` for title/UI text
- **sprites/**: All PNG sprite sheets
- **sonidos/**: All audio files (MP3 and WAV formats)
- **prueba.lua**: Standalone test file for city scene development (separate from main game flow)

## Key Functions in objetos.lua

- `OBJ.init()`: Loads all sprites, creates quads, prerenders all canvases
- `OBJ.clampHouseOffset(x, y)`: Clamps camera for house scene
- `OBJ.clampCityOffset(x, y)`: Clamps camera for city scene
- `OBJ.getDetectiveWorldPos()`: Calculates detective's world position
- `OBJ.isNear(ax, ay, bx, by, r)`: Fast proximity check using squared distance

## Development Patterns

### Adding New Interactive Objects

1. Add object coordinates and proximity radius to main.lua state (e.g., `new_object_state = { x=..., y=..., cercania=... }`)
2. Create proximity helper function (e.g., `isNearNewObject()`)
3. Add interaction logic in SPACE key handler (main.lua:362-408)
4. Add prompt rendering in draw function (main.lua:668-688)

### Adding New Text Dialogues

1. Create text state object with required fields (see radio_state as template)
2. Add typewriter update logic in love.update (follow pattern at main.lua:417-444)
3. Add text box rendering in love.draw (follow pattern at main.lua:704-722)

### Modifying Canvases

To change prerendered scenes, edit the `build*Canvas()` functions in objetos.lua:
- `buildCasaCanvas()`: Base house without investigation board paper
- `buildCasaHoja1()`: House with paper on board
- `buildCityCanvas()`: City scene composition

Remember to use appropriate scales when drawing (10, 12, 15, 20) to match existing pixel alignment.
