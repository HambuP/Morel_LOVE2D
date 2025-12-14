-- NPCs y sus conversaciones
-- Posiciones y datos de personajes no jugables

local NPCs = {}

-- ===============================================
-- DÍA 2: CIUDAD - NPCs
-- ===============================================

NPCs.dia2_ciudad = {
  -- Transeúntes (PNG1 y PNG2) - Primera conversación
  {
    id = "transeuntes",
    nombre = "Dos Hombres",
    x = 3,  -- Centro entre ambos
    y = 25,
    radio = 15,
    conversacion_id = "dia2.conversacion_transeuntes",
    pregunta_id = "dia2.pregunta_transeuntes",
    objetivo_escuchar = 5,  -- Escuchar conversación
    objetivo_preguntar = 6,  -- Intentar pedir información
    estado = {
      conversacion_escuchada = false,
      pregunta_hecha = false
    }
  },

  -- Viejas (PNG3 y PNG4) - Segunda conversación
  {
    id = "viejas",
    nombre = "Dos Mujeres",
    x = 230,
    y = 25,
    radio = 25,
    conversacion_id = "dia2.conversacion_viejas",
    objetivo_escuchar = 7,  -- Escuchar otra conversación
    estado = {
      conversacion_escuchada = false
    }
  }
}

-- ===============================================
-- DÍA 3: RESTAURANTE - NPCs
-- ===============================================

NPCs.dia3_restaurante = {
  -- Borrachos (PNG5 y PNG6) - Conversación con pista clave
  {
    id = "borrachos",
    nombre = "Dos Borrachos",
    x = 50,
    y = 20,
    radio = 10,
    conversacion_id = "dia3.conversacion_borrachos",
    pregunta_id = "dia3.pregunta_borrachos",
    objetivo_escuchar = 11,  -- Escuchar conversación cercana
    objetivo_hablar = 12,    -- Ve y habla con ellos
    estado = {
      conversacion_escuchada = false,
      pregunta_hecha = false
    },
    pista_importante = true  -- Esta conversación tiene la pista clave (camisa de unicornio)
  }
}

-- ===============================================
-- DIA 4: CINE
-- ===============================================

NPCs.dia4_cine = {
  -- Pareja en el cine (PNG7 y PNG8)
  {
    id = "pareja",
    nombre = "Pareja",
    x = 50,
    y = 20,
    radio = 25,
    conversacion_id = "dia4.conversacion_pareja",
    objetivo_escuchar = 15,  -- Escuchar conversacion en el cine
    estado = {
      conversacion_escuchada = false
    },
    pista_importante = true  -- Esta conversacion tiene pista sobre el incidente
  }
}

-- ===============================================
-- DÍA 5 EN ADELANTE (PLACEHOLDER)
-- ===============================================

NPCs.dia5 = {}
NPCs.dia6 = {}
NPCs.dia7 = {}

-- ===============================================
-- HELPERS
-- ===============================================

-- Obtener NPCs de un nivel
function NPCs.get_nivel(nombre_nivel)
  return NPCs[nombre_nivel] or {}
end

-- Buscar NPC por ID en un nivel
function NPCs.find(nombre_nivel, id)
  local npcs = NPCs.get_nivel(nombre_nivel)
  for _, npc in ipairs(npcs) do
    if npc.id == id then
      return npc
    end
  end
  return nil
end

-- Actualizar estado de NPC
function NPCs.actualizar_estado(nombre_nivel, id, estado_nuevo)
  local npc = NPCs.find(nombre_nivel, id)
  if npc then
    for k, v in pairs(estado_nuevo) do
      npc.estado[k] = v
    end
  end
end

return NPCs
