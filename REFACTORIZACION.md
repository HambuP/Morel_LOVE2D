# REFACTORIZACIÓN - LA INVENCIÓN DE MOREL

## 📁 Nueva Estructura del Proyecto

```
MOREL_love/
├── main.lua                    # State machine simplificado (~335 líneas vs 1646 original)
├── conf.lua                    # Configuración LÖVE (sin cambios)
├── main_backup.lua            # Backup del main.lua original
│
├── core/                       # Sistemas core reutilizables
│   ├── objetos.lua            # Canvas, recursos, sprites (movido desde raíz)
│   ├── dialogo_sistema.lua    # Sistema de typewriter + conversaciones
│   ├── transiciones.lua       # Fade to black, títulos de día
│   └── interaccion_sistema.lua# Detección de proximidad genérica
│
├── niveles/                    # Módulos de niveles (auto-contenidos)
│   ├── menu.lua               # Pantalla de inicio
│   ├── dia1_casa.lua          # Día 1: Radio → Tablero → Cama
│   ├── dia2_ciudad.lua        # Día 2: Ciudad + NPCs
│   ├── dia3_restaurante.lua   # Día 3: Restaurante + borrachos
│   └── dia4_despertar.lua     # Día 4: Placeholder
│
├── data/                       # Datos separados del código
│   ├── dialogos.lua           # Todos los textos del juego
│   ├── objetivos.lua          # 13 objetivos con metadata
│   ├── interactivos.lua       # Objetos interactivos (radio, puertas, etc.)
│   └── npcs.lua               # NPCs con posiciones y conversaciones
│
└── assets/                     # Recursos (sin cambios)
    ├── sprites/
    ├── sonidos/
    └── fonts/
```

## 🎯 Ventajas de la Nueva Estructura

### 1. **main.lua Simplificado (335 líneas vs 1646)**
- Solo contiene el state machine básico
- Delega toda la lógica a los módulos de niveles
- Maneja únicamente: input global, movimiento del detective, fade de música

### 2. **Niveles Modulares**
Cada nivel es un módulo independiente con su propia lógica:
```lua
local Dia1Casa = require("niveles.dia1_casa")

-- Cada nivel expone:
Dia1Casa.init(OBJ, detective, audio)  -- Inicialización
Dia1Casa.update(dt, tareas)           -- Actualización
Dia1Casa.draw(SCALE, shader, font)    -- Renderizado
Dia1Casa.keypressed(key, tareas)      -- Input
```

**Agregar un nuevo día es tan simple como:**
1. Crear `niveles/dia5_biblioteca.lua`
2. Agregarlo al mapeo de estados en main.lua
3. ¡Listo!

### 3. **Sistema de Diálogos Reutilizable**
Ya no duplicas código de typewriter. Una sola función:
```lua
local DialogoSistema = require("core.dialogo_sistema")

-- Crear diálogo simple
local dialogo = DialogoSistema.crear("Texto aquí", {
  char_speed = 0.05,
  pause_at_newlines = true
})

-- Crear conversación multi-mensaje
local conv = DialogoSistema.Conversacion.crear(mensajes, {
  on_complete = function() print("Terminó!") end
})
```

### 4. **Datos Separados del Código**
Cambiar diálogos, objetivos o posiciones de objetos **sin tocar código**:
```lua
-- data/dialogos.lua
Dialogos.dia1.radio = "Nuevo texto de la radio..."

-- data/objetivos.lua
{id = 14, dia = 5, descripcion = "Investiga la biblioteca"}

-- data/npcs.lua
{id = "sospechoso", x = 100, y = 50, conversacion_id = "dia5.sospechoso"}
```

### 5. **Sistema de Transiciones Genérico**
```lua
local Transiciones = require("core.transiciones")

-- Transición completa de día (fade + título + fade)
transicion = Transiciones.crear_transicion_dia(5, function()
  print("Día 5 iniciado!")
end)
```

## 📝 Cómo Agregar un Nuevo Nivel

### Ejemplo: Día 5 - Biblioteca

**Paso 1:** Crear `niveles/dia5_biblioteca.lua`
```lua
local DialogoSistema = require("core.dialogo_sistema")
local Interactivos = require("data.interactivos")
local Dialogos = require("data.dialogos")

local Dia5 = {}

function Dia5.init(obj_ref, detective_ref, audio)
  -- Tu lógica de inicialización
end

function Dia5.update(dt, tareas)
  -- Tu lógica de actualización
  return nil  -- O retornar nuevo estado para cambiar nivel
end

function Dia5.draw(SCALE, lighting_shader, radio_font)
  -- Tu lógica de renderizado
end

function Dia5.keypressed(key, tareas)
  -- Tu lógica de input
end

return Dia5
```

**Paso 2:** Agregar datos en `data/`
```lua
-- data/dialogos.lua
Dialogos.dia5 = {
  bibliotecaria = "Bienvenido a la biblioteca...",
  pista_libro = "Este libro tiene una mancha sospechosa..."
}

-- data/objetivos.lua
{id = 14, dia = 5, nivel = "dia5_biblioteca", descripcion = "Busca pistas en la biblioteca"}

-- data/interactivos.lua
Interactivos.dia5_biblioteca = {
  {id = "libro", x = 80, y = 30, radio = 20, accion = "revisar_libro"}
}
```

**Paso 3:** Agregar al main.lua
```lua
local Dia5Biblioteca = require("niveles.dia5_biblioteca")

local niveles = {
  -- ... niveles existentes ...
  day5_wake = Dia5Biblioteca
}
```

**¡Eso es todo!** No necesitas tocar ningún otro archivo.

## 🔧 Cambios Técnicos Importantes

### Sistema de Coordenadas
- **Casa**: Usa `detective.screen_x` + `detective.x` (offset de cámara)
- **Ciudad/Restaurante**: Usa `detective.x` directamente (posición en mundo)

### Audio Management
Cada nivel recibe referencias de audio en `init()`:
```lua
function Nivel.init(obj_ref, detective_ref, audio)
  local radio = audio.radio
  local pasos = audio.pasos
  -- etc.
end
```

### Shader Configuration
Cada nivel configura su propio lighting:
```lua
lighting_shader:send("ambient_color", {0.65, 0.63, 0.58})  -- Día cálido
lighting_shader:send("ambient_strength", 0.58)
```

## 🐛 Debugging

### Si el juego no carga:
1. Revisa la consola: `love .`
2. Verifica que todos los `require()` apunten a rutas correctas
3. Asegúrate que los módulos tengan `return ModuleName` al final

### Si un nivel no funciona:
1. Verifica que esté en el mapeo de `niveles` en main.lua
2. Asegúrate que tenga las funciones `init`, `update`, `draw`, `keypressed`
3. Revisa que los datos en `data/` coincidan con los IDs usados

## 📊 Comparación Antes/Después

| Métrica | Antes | Después |
|---------|-------|---------|
| **main.lua** | 1646 líneas | 335 líneas |
| **Diálogo duplicado** | 5+ copias | 1 sistema |
| **Agregar nivel** | Editar main.lua 100+ líneas | Crear 1 archivo nuevo |
| **Cambiar diálogo** | Buscar en 1646 líneas | Editar data/dialogos.lua |
| **Mantenibilidad** | ⚠️ Difícil | ✅ Fácil |

## 🎮 Estado Actual

**Niveles Completos:**
- ✅ Menú
- ✅ Día 1: Casa (Radio → Tablero → Cama)
- ✅ Día 2: Ciudad (NPCs, conversaciones)
- ✅ Día 3: Restaurante (Borrachos, pista clave)
- 📝 Día 4: Placeholder (estructura lista para implementar)

**Días 5-7:** Estructura preparada, solo necesitas:
1. Crear archivo en `niveles/`
2. Agregar datos en `data/`
3. Agregarlo al mapeo en main.lua

## 📚 Archivos Importantes

- **[main.lua](main.lua)** - State machine principal
- **[core/dialogo_sistema.lua](core/dialogo_sistema.lua)** - Sistema de diálogos
- **[data/dialogos.lua](data/dialogos.lua)** - Todos los textos
- **[niveles/dia1_casa.lua](niveles/dia1_casa.lua)** - Ejemplo de nivel completo

## 🔄 Backup

Tu código original está guardado en:
- `main_backup.lua` - Main.lua original completo

Si necesitas volver atrás:
```bash
mv main.lua main_refactorizado.lua
mv main_backup.lua main.lua
mv core/objetos.lua objetos.lua
```

---

**¡Ahora agregar niveles es tan fácil como agregar una línea de código!** 🎉
