-- Todos los diálogos y textos del juego "LA INVENCIÓN DE MOREL"
-- Separados por día y tipo de interacción

local Dialogos = {}

-- ===============================================
-- DÍA 1: CASA - INVESTIGACIÓN
-- ===============================================

Dialogos.dia1 = {}

-- Radio: Noticia sobre desaparición
Dialogos.dia1.radio = "Radio:\n\n Se ha reportado la desaparicion de un joven de 23 anos que habia salido a festejar el cumpleanos de uno de sus amigos.\n\n Las autoridades han declarado que aun no logran encontrar al joven y piden a cualquiera con algo de informacion de porfavor dirigirse a la comisaria a comentarla."

-- Detective después de escuchar radio
Dialogos.dia1.detective_radio = "Josuelito:\n\n Supongo que me pediran en la estacion investigar este caso...\n\nMejor me ahorro el viaje y me pongo a trabajar para ganar tiempo."

-- Detective después de hacer plan en tablero
Dialogos.dia1.detective_tablero = "Josuelito:\n\n Con esto podre seguir investigando sin problemas de organizacion.\n\nLo voy a dejar hasta aqui por hoy... manana saldre al pueblo para encontrar pruebas."

-- Texto al despertar (inicio del día 1)
Dialogos.dia1.despertar = "Josuelito:\n\n Que horrible pesadilla..."

-- ===============================================
-- DÍA 2: CIUDAD - INVESTIGACIÓN EN PUEBLO
-- ===============================================

Dialogos.dia2 = {}

-- Conversación entre transeúntes (Hombre 1 y Hombre 2)
Dialogos.dia2.conversacion_transeuntes = {
  {hablante = "Hombre 1", texto = "Oye viste las noticias de ayer?"},
  {hablante = "Hombre 2", texto = "Pues claro que las vi ya sabes como soy. La verdad me da miedo pensar en el hecho de que nuestro pueblo sea tan inseguro... Es que ya es la septima vez que desaparece alguien por la noche!"},
  {hablante = "Hombre 1", texto = "Tocara tener mucho mas cuidado al salir por la noche que nadie sabe cuando le podra pasar a uno."}
}

-- Detective intenta preguntar a transeúntes
Dialogos.dia2.pregunta_transeuntes = {
  {hablante = "JOSUELITO", texto = "Buenas tardes soy un detective y busco informacion sobre la desaparicion del joven de 23 anos. Sera que alguno de ustedes a visto o escuchado algo esa noche?"},
  {hablante = "SILENCIO", texto = "..."},
  {hablante = "JOSUELITO", texto = "Que groseros ni siquiera me prestaron atencion. Supongo que ire a buscar informacion en otro lado."}
}

-- Conversación entre viejas (Mujer 1 y Mujer 2)
Dialogos.dia2.conversacion_viejas = {
  {hablante = "Mujer 1", texto = "Oye amiga ayer por la noche escuche sonidos muy extranos en el callejon cerca de mi casa."},
  {hablante = "Mujer 2", texto = "Ay que miedo amiga! Crees que tenga algo que ver con lo que paso ayer por la noche?"},
  {hablante = "Mujer 1", texto = "La verdad no lo se amiga, pero espero que no... Imaginate que vuelva a pasar algo como eso y me pase a mi... ay no amiga que miedo prefiero no pensar en eso!"}
}

-- ===============================================
-- DÍA 3: RESTAURANTE - PISTA CLAVE
-- ===============================================

Dialogos.dia3 = {}

-- Texto de introduccion dia 3
Dialogos.dia3.intro = "JOSUELITO:\n\n En general los borrachos suelen soltar informacion sin darse cuenta. Quizas pueda sacarles datos utiles en alguno de los restaurantes del pueblo."

-- Conversacion entre borrachos (Borracho 1 y Borracho 2) - PISTA IMPORTANTE
Dialogos.dia3.conversacion_borrachos = {
  {hablante = "Borracho 1", texto = "Uf que buena cerveza en serio es la mejor de todo el pais."},
  {hablante = "Borracho 2", texto = "Tienes razon, se me fue todo el estres del trabajo."},
  {hablante = "Borracho 1", texto = "Oye si te conte lo de ayer?"},
  {hablante = "Borracho 2", texto = "Como me lo vas a haber contado si no nos vimos desde hace un mes imbecil?"},
  {hablante = "Borracho 1", texto = "Jajajaja se me olvido perdon. Pues fijate que al volver a mi casa vi a un man saliendo de un callejon corriendo y lleno de manchas de sangre sobre su camisa. Era re extrano."},
  {hablante = "Borracho 2", texto = "Jajajajaja este man de que me habla, seguro que no estabas borracho esa noche tambien?"},
  {hablante = "Borracho 1", texto = "Uno no puede hablarle de cosas serias... bueno pues hablemos de otra cosa ya que no me va a tomar enserio."},
  {hablante = "Borracho 2", texto = "Esta noche vayamos a una discoteca para emborracharnos mas. Seguro sera mas interesante que tus mentiras."},
  {hablante = "Borracho 1", texto = "Que no son mentiras imbecil... pero bueno me parece el plan."},
  {hablante = "Borracho 2", texto = "Esa es la actitud!"}
}

-- Detective intenta hablar con borrachos
Dialogos.dia3.pregunta_borrachos = {
  {hablante = "JOSUELITO", texto = "Perdon buenas tardes, soy un detective y estoy buscando informacion sobre la desaparicion del joven de 23 anos. Sera que alguno de ustedes a visto o escuchado algo esa noche?"},
  {hablante = "SILENCIO", texto = "..."},
  {hablante = "JOSUELITO", texto = "La gente ya no respeta, es la segunda vez que me ignoran esta semana. Igual la informacion que escuche es util, entonces no dire nada."}
}

-- ===============================================
-- DÍA 4 EN ADELANTE (PLACEHOLDER)
-- ===============================================

-- ===============================================
-- DIA 4: CINE - Pista sobre el incidente
-- ===============================================

Dialogos.dia4 = {}

-- Texto de introduccion dia 4 (en casa)
Dialogos.dia4.intro = "JOSUELITO:\n\n ya que me dejaron el dia libre supongo que ire a ver esa pelicula que me habia llamado la atencion"

-- Texto cuando entra al cine
Dialogos.dia4.intro_cine = "JOSUELITO:\n\n esta pelicula tiene muy buena historia y la calidad de la animacion es excelente. El problema es que la gente no deja de hablar... Acaso no saben que uno se tiene que quedar callado en un cine?"

-- Conversacion de la pareja en el cine
Dialogos.dia4.conversacion_pareja = {
  {hablante = "Novia", texto = "Amor que miedo... porque me llevaste a ver esta pelicula? Tu ya sabes que no soy buena para este tipo de peliculas."},
  {hablante = "Novio", texto = "Pero si me dijiste que podiamos verla ya sabes que me la queria ver desde hace mucho tiempo"},
  {hablante = "Novia", texto = "Pues si, pero vi las resenas en internet y la gente dice que la historia esta basada en hechos reales... Ademas, pensando en lo que paso el domingo pasado por la noche no puedo dejar de pensar que es la misma cosa que sucede en el pueblo."},
  {hablante = "Novio", texto = "Te estas preocupando mucho por eso amor. Ademas, la historia en la que esta basada esta pelicula es un incidente que paso hace decenas de anos."},
  {hablante = "Novia", texto = "Bueno si tu lo dices amor..."}
}

-- ===============================================
-- DIA 5: BIBLIOTECA
-- ===============================================

Dialogos.dia5 = {}

Dialogos.dia5.intro = "JOSUELITO:\n\n Hmm... entonces la pelicula de ayer esta basada en hechos reales... Mejor me dirijo a la libreria para investigar noticias viejas sobre algun caso similar. Espero encontrar alguna pista sobre este caso alla."

Dialogos.dia5.hoja_arte = "JOSUELITO:\n\n No creo que esto me funcione, son noticias sobre arte"

Dialogos.dia5.hoja_deportes = "JOSUELITO:\n\n Interesante el deporte, pero no creo que sea lo que necesito"

Dialogos.dia5.hoja_noticias_1 = "JOSUELITO:\n\n De pronto esta noticia me ayude a encontrar pistas. Se nota que es vieja de hace 20 anos, voy a ver que dice..."

Dialogos.dia5.hoja_noticias_2 = "\n\n \"El callejon de la fatalidad\"... que titulo tan extrano"

Dialogos.dia5.hoja_noticias_3 = "JOSUELITO:\n\n No sera ese el callejon del que hablaba la chica del pueblo? De hecho, el hombre borracho tambien vio un hombre sospechosos salir de un callejon corriendo"

Dialogos.dia6 = {}

Dialogos.dia6.intro = "JOSUELITO:\n\n Hoy voy a intentar organizar todas las pistas que recolecte a lo largo de la semana. Estoy seguro de que manana encuentro a ese joven."

Dialogos.dia6.tablero = "JOSUELITO:\n\n HHmmm, todas las pistas indican que si quiero encontrar al joven tendre que ir al callejon Casares... No se que tiene de especial ese lugar... Pero todas las pistas dirigen a aquel sitio de alguna manera u otra. Supongo que manana visitare aquel callejon para ver si logro encontrar al joven."

Dialogos.dia7 = {}

-- Texto al llegar al callejon
Dialogos.dia7.llegada_callejon = "JOSUELITO:\n\n Que es este olor tan horrible?! Creo que viene de esa basura...."

-- Texto al investigar la basura
Dialogos.dia7.investigar_basura = "JOSUELITO:\n\n Con que aqui estaba el joven... que horrendo....\n\nEspera un segundo...."

-- Texto al revelar el cadaver
Dialogos.dia7.revelacion_cadaver = "Ese es mi cuerpo....."

-- ===============================================
-- HELPERS
-- ===============================================

-- Función para obtener diálogo por ID (opcional, para facilitar acceso)
function Dialogos.get(id)
  local partes = {}
  for parte in string.gmatch(id, "[^.]+") do
    table.insert(partes, parte)
  end

  local resultado = Dialogos
  for _, parte in ipairs(partes) do
    resultado = resultado[parte]
    if not resultado then return nil end
  end

  return resultado
end

return Dialogos
