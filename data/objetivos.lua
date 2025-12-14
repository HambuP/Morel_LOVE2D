-- Lista de objetivos/tareas del juego
-- Progresión lineal a través de los días

local Objetivos = {}

-- Lista completa de objetivos (13 objetivos para 3 días completos)
Objetivos.lista = {
  -- DÍA 1: CASA - Investigación inicial
  {
    id = 1,
    dia = 1,
    nivel = "dia1_casa",
    descripcion = "Escucha las noticias de la Radio"
  },
  {
    id = 2,
    dia = 1,
    nivel = "dia1_casa",
    descripcion = "Construir plan de investigacion"
  },
  {
    id = 3,
    dia = 1,
    nivel = "dia1_casa",
    descripcion = "Ir a la cama"
  },

  -- DÍA 2: CIUDAD - Investigación en el pueblo
  {
    id = 4,
    dia = 2,
    nivel = "dia2_ciudad",
    descripcion = "Ve a investigar en el pueblo"
  },
  {
    id = 5,
    dia = 2,
    nivel = "dia2_ciudad",
    descripcion = "Escuchar conversaciones de transeuntes hombres"
  },
  {
    id = 6,
    dia = 2,
    nivel = "dia2_ciudad",
    descripcion = "Intenta pedir informacion"
  },
  {
    id = 7,
    dia = 2,
    nivel = "dia2_ciudad",
    descripcion = "Escucha otra conversacion"
  },
  {
    id = 8,
    dia = 2,
    nivel = "dia2_ciudad",
    descripcion = "Volver a casa y anotar resultados"
  },

  -- DÍA 3: RESTAURANTE - Pista clave
  {
    id = 9,
    dia = 3,
    nivel = "dia3_restaurante",
    descripcion = "Ve a restaurante"
  },
  {
    id = 10,
    dia = 3,
    nivel = "dia3_restaurante",
    descripcion = "Sentarse"
  },
  {
    id = 11,
    dia = 3,
    nivel = "dia3_restaurante",
    descripcion = "Escucha conversacion cercana"
  },
  {
    id = 12,
    dia = 3,
    nivel = "dia3_restaurante",
    descripcion = "Ve y habla con ellos"
  },
  {
    id = 13,
    dia = 3,
    nivel = "dia3_restaurante",
    descripcion = "Volver a casa y anotar pruebas"
  },

  -- DIA 4: Cine
  {
    id = 14,
    dia = 4,
    nivel = "dia4_cine",
    descripcion = "Ve al cine"
  },
  {
    id = 15,
    dia = 4,
    nivel = "dia4_cine",
    descripcion = "Sentarse y ver la pelicula"
  },
  {
    id = 16,
    dia = 4,
    nivel = "dia4_cine",
    descripcion = "Volver a casa y anotar pruebas"
  },

  -- DIA 5: Biblioteca
  {
    id = 17,
    dia = 5,
    nivel = "dia5_biblioteca",
    descripcion = "Ve a la biblioteca"
  },
  {
    id = 18,
    dia = 5,
    nivel = "dia5_biblioteca",
    descripcion = "Buscar pistas"
  },
  {
    id = 19,
    dia = 5,
    nivel = "dia5_biblioteca",
    descripcion = "Volver a casa y anotar pistas"
  },

  -- DIA 6: Investigacion
  {
    id = 20,
    dia = 6,
    nivel = "dia6_investigacion",
    descripcion = "Analiza las pistas que tienes"
  },
  {
    id = 21,
    dia = 6,
    nivel = "dia6_investigacion",
    descripcion = "Ve a dormir"
  },

  -- DIA 7: Callejon Casares
  {
    id = 22,
    dia = 7,
    nivel = "dia7_callejon",
    descripcion = "Visita el callejon Casares"
  },
  {
    id = 23,
    dia = 7,
    nivel = "dia7_callejon",
    descripcion = "Investigar"
  },
  {
    id = 24,
    dia = 7,
    nivel = "dia7_callejon",
    descripcion = "Investigar basura"
  }
}

-- Helpers para obtener objetivos por día
function Objetivos.get_por_dia(dia_num)
  local objetivos_dia = {}
  for _, obj in ipairs(Objetivos.lista) do
    if obj.dia == dia_num then
      table.insert(objetivos_dia, obj)
    end
  end
  return objetivos_dia
end

-- Obtener objetivo por ID
function Objetivos.get_por_id(id)
  for _, obj in ipairs(Objetivos.lista) do
    if obj.id == id then
      return obj
    end
  end
  return nil
end

-- Obtener siguiente objetivo
function Objetivos.get_siguiente(id_actual)
  if id_actual >= #Objetivos.lista then
    return nil -- No hay más objetivos
  end
  return Objetivos.get_por_id(id_actual + 1)
end

return Objetivos
