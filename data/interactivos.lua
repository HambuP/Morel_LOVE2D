-- Objetos interactivos del juego
-- Definidos por nivel/día con sus posiciones y radios de interacción

local Interactivos = {}

-- ===============================================
-- DÍA 1: CASA - Investigación inicial
-- ===============================================

Interactivos.dia1_casa = {
  -- Radio: Primera interacción del día 1
  {
    id = "radio",
    nombre = "Radio",
    x = 67 * (10/15),  -- 56.67
    y = 46 * (10/15),  -- 30.67
    radio = 11,
    tipo = "dialogo",
    accion = "escuchar_radio",
    objetivo_id = 1,
    activo = true
  },

  -- Tablero de investigación: Segunda interacción
  {
    id = "tablero",
    nombre = "Tablero",
    x = 108 * (10/15),  -- 98.67
    y = 18 * (10/15),   -- 12
    radio = 20,
    tipo = "dialogo",
    accion = "revisar_tablero",
    objetivo_id = 2,
    activo = false  -- Se activa después de escuchar radio
  },

  -- Cama: Dormir para terminar día 1
  {
    id = "cama",
    nombre = "Cama",
    x = 12,
    y = 46,
    radio = 30,
    tipo = "transicion",
    accion = "dormir",
    objetivo_id = 3,
    activo = false  -- Se activa después del tablero
  }
}

-- ===============================================
-- DÍA 2: DESPERTAR EN CASA
-- ===============================================

Interactivos.dia2_casa = {
  -- Puerta: Salir a la ciudad
  {
    id = "puerta_salir",
    nombre = "Puerta",
    x = 156,
    y = 25,
    radio = 15,
    tipo = "transicion",
    accion = "salir_ciudad",
    objetivo_id = 4,
    activo = true
  }
}

-- ===============================================
-- DÍA 2: CIUDAD - Investigación en pueblo
-- ===============================================

Interactivos.dia2_ciudad = {
  -- Puerta para regresar a casa desde ciudad
  {
    id = "puerta_regresar",
    nombre = "Puerta",
    x = 70,
    y = 50,
    radio = 305,
    tipo = "transicion",
    accion = "regresar_casa",
    objetivo_id = 8,
    activo = false  -- Se activa después de escuchar ambas conversaciones
  }
}

-- ===============================================
-- DÍA 3: DESPERTAR EN CASA
-- ===============================================

Interactivos.dia3_casa = {
  -- Puerta: Ir al restaurante
  {
    id = "puerta_restaurante",
    nombre = "Puerta",
    x = 156,
    y = 25,
    radio = 15,
    tipo = "transicion",
    accion = "ir_restaurante",
    objetivo_id = 9,
    activo = true
  }
}

-- ===============================================
-- DÍA 3: RESTAURANTE - Pista clave
-- ===============================================

Interactivos.dia3_restaurante = {
  -- Silla: Sentarse en el restaurante
  {
    id = "silla",
    nombre = "Silla",
    x = 50,
    y = 25,
    radio = 20,
    tipo = "interaccion",
    accion = "sentarse",
    objetivo_id = 10,
    activo = true
  },

  -- Puerta para regresar a casa desde restaurante
  {
    id = "puerta_salir_rest",
    nombre = "Puerta",
    x = 136,
    y = 50,
    radio = 305,
    tipo = "transicion",
    accion = "regresar_casa_dia3",
    objetivo_id = 13,
    activo = false  -- Se activa después de hablar con borrachos
  }
}

-- ===============================================
-- DIA 4: CINE
-- ===============================================

Interactivos.dia4_casa = {
  -- Puerta para ir al cine
  {
    id = "puerta_cine",
    nombre = "Ir al Cine",
    x = 156,
    y = 25,
    radio = 15,
    tipo = "transicion",
    accion = "ir_cine",
    objetivo_id = 14,
    activo = true
  }
}

Interactivos.dia4_cine = {
  -- Asiento para sentarse en el cine
  {
    id = "asiento",
    nombre = "Asiento",
    x = 50,
    y = 25,
    radio = 20,
    tipo = "interaccion",
    accion = "sentarse",
    objetivo_id = 15,
    activo = true
  },

  -- Puerta para salir del cine
  {
    id = "puerta_salir_cine",
    nombre = "Puerta",
    x = 136,
    y = 50,
    radio = 35,
    tipo = "transicion",
    accion = "regresar_casa_dia4",
    objetivo_id = 16,
    activo = false  -- Se activa despues de escuchar la conversacion
  }
}

-- ===============================================
-- DIA 5: BIBLIOTECA
-- ===============================================

Interactivos.dia5_casa = {
  -- Puerta para ir a la biblioteca
  {
    id = "puerta_biblioteca",
    nombre = "Ir a la Biblioteca",
    x = 156,
    y = 25,
    radio = 15,
    tipo = "transicion",
    accion = "ir_biblioteca",
    objetivo_id = 17,
    activo = true
  }
}

-- ===============================================
-- DIA 6: CASA (Investigacion)
-- ===============================================

Interactivos.dia6_casa = {
  -- Tablero de investigación
  {
    id = "tablero",
    nombre = "Analizar pistas",
    x = 208 * (10/15),  -- 98.67
    y = 30 * (10/15),   -- 12
    radio = 20,
    tipo = "interaccion",
    accion = "analizar_pistas",
    objetivo_id = 20,
    activo = true
  },
  -- Cama (misma posición X que tablero para facilitar acceso)
  {
    id = "cama",
    nombre = "Dormir",
    x = 148 * (10 / 15),  -- Misma X que tablero
    y = 46,
    radio = 30,
    tipo = "transicion",
    accion = "dormir",
    objetivo_id = 21,
    activo = false  -- Se activa después de analizar pistas
  }
}

-- ===============================================
-- DÍA 7: CASA Y CALLEJÓN
-- ===============================================

-- Objetos interactivos en casa día 7 (despertar)
Interactivos.dia7_casa = {
  {
    id = "puerta_salir",
    nombre = "Ir al callejon",
    x = 156,
    y = 25,
    radio = 15,
    tipo = "transicion",
    accion = "ir_callejon",
    objetivo_id = 22,
    activo = true
  }
}

-- Objetos interactivos en el callejón día 7
Interactivos.dia7_callejon = {
  {
    id = "basura",
    nombre = "Investigar basura",
    x = 90,  -- Ajustar según posición de la basura en callejon.png
    y = 25,  -- Ajustar según posición de la basura en callejon.png
    radio = 10,
    tipo = "investigacion",
    accion = "investigar_basura",
    objetivo_id = 24,
    activo = false  -- Se activa después del diálogo de llegada
  }
}

-- ===============================================
-- HELPERS
-- ===============================================

-- Obtener objetos interactivos de un nivel
function Interactivos.get_nivel(nombre_nivel)
  return Interactivos[nombre_nivel] or {}
end

-- Buscar objeto interactivo por ID en un nivel
function Interactivos.find(nombre_nivel, id)
  local objetos = Interactivos.get_nivel(nombre_nivel)
  for _, obj in ipairs(objetos) do
    if obj.id == id then
      return obj
    end
  end
  return nil
end

-- Activar objeto interactivo
function Interactivos.activar(nombre_nivel, id)
  local obj = Interactivos.find(nombre_nivel, id)
  if obj then
    obj.activo = true
  end
end

-- Desactivar objeto interactivo
function Interactivos.desactivar(nombre_nivel, id)
  local obj = Interactivos.find(nombre_nivel, id)
  if obj then
    obj.activo = false
  end
end

return Interactivos
