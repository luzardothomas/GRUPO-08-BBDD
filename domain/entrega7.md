# Análisis — Entrega 7 (Reportes)

## Qué pide el enunciado

- Antes de generar los reportes, garantizar **volumen de datos representativo** en todas las tablas (importación,
  APIs, testing manual o datos aleatorios).
- Generar SP específicos para cada uno de los siguientes reportes; **al menos dos deben devolver XML** (alcanza
  con que el `SELECT` lo muestre al ejecutarse, no hace falta escribir el archivo a disco):
  1. Goleadores por selección, fase y torneo.
  2. Tarjetas (amarillas/rojas) por selección y jugador, con detalle de suspensiones activas por acumulación.
  3. Designaciones arbitrales: partidos dirigidos por árbitro, con amonestaciones/expulsiones que señaló.
  4. Ocupación publicitaria por sede y partido: anunciantes en los 4 espacios, ingresos generados.
  5. Matriz de prime time: tabla cruzada (pivot) partido × mercado.
  6. Selecciones y plantillas: listado con vector anidado de convocados (nombre, posición, club, dorsal).
  7. Resultados de los encuentros.

## Encuadre conceptual: cada reporte es una consulta relacional, la forma de salida es lo variable

Es importante separar, para el informe, dos capas:
- **La lógica de agregación/consulta**, que es SQL estándar (`GROUP BY`, funciones de agregación, joins,
  funciones de ventana) y sería idéntica en cualquier motor.
- **El formato de salida** (tabular, XML, pivot), que sí usa extensiones propias de T-SQL (`FOR XML`, `PIVOT`) y
  debe documentarse como tal, explicando cuál sería el equivalente ANSI-SQL conceptual si se portara a otro motor.

### 1. Goleadores por selección, fase y torneo

Consulta de agregación estándar sobre `gol`, con tres niveles de `GROUP BY` (torneo completo, por selección, por
fase), resolubles con `GROUP BY jugador_id, seleccion_id` y `GROUP BY jugador_id, fase` (requiere join con
`partido` para conocer la fase). Candidato natural para exponerse como **vista** además de SP, ya que es una
consulta reutilizable sin parámetros de negocio complejos.

### 2. Tarjetas con detalle de suspensiones activas

Join entre `tarjeta`, `jugador`, `seleccion`, y la tabla `suspension` ya prevista en el modelo (que registra
`partido_afectado_id`). El estado de "suspensión activa" se resuelve comparando `suspension.partido_afectado_id`
contra el próximo partido no jugado de la selección — es el mismo cálculo que debe hacer el SP de negocio de la
Entrega 5 al insertar la tarjeta, por lo que conviene que el reporte **reutilice** esa lógica (vista o función) en
lugar de reimplementarla.

### 3. Designaciones arbitrales con incidentes señalados

Join de `designacion_arbitral` con `partido`, y de ahí con `tarjeta` filtrando por el `partido_id` de cada
designación del árbitro (no hay FK directa árbitro→tarjeta, la relación es transitiva vía partido). Buen candidato
para el segundo reporte en XML, dado que naturalmente tiene estructura jerárquica (árbitro → partidos → tarjetas
de ese partido).

### 4. Ocupación publicitaria e ingresos por sede/partido

Join de `espacio_publicitario` con `pieza_publicitaria`, `campania`, `anunciante`, agrupado por `sede_id` (vía
`partido`) y `partido_id`. El campo `monto_facturado` ya previsto en `espacio_publicitario` permite el cálculo de
ingresos directamente por `SUM`.

### 5. Matriz de prime time (pivot)

Requiere primero la función/SP de simulación de prime time del módulo H (convertir `partido.fecha_hora_utc` al
huso de cada `pais`, y evaluar si cae en la franja configurada). El resultado base es una tabla
`partido_id, pais_id, es_prime_time` (formato "largo"/*long*), que luego se pivotea a formato "ancho" (partido en
filas, país en columnas). En T-SQL esto se resuelve con el operador `PIVOT`; el equivalente ANSI-SQL portable
(sin `PIVOT`, que no es estándar) es `SUM(CASE WHEN pais_id = X THEN 1 ELSE 0 END)` repetido por columna —
vale la pena mencionar ambas formas en el informe para mostrar que se entiende la operación relacional detrás
del operador propietario.

### 6. Selecciones y plantillas con convocados anidados

Este es el segundo candidato natural para salida **XML**: la estructura pedida (selección → lista de convocados)
es jerárquica por naturaleza y no se representa bien en una grilla plana. En T-SQL se resuelve con
`FOR XML PATH`/`FOR XML AUTO` anidado. Documentar en el informe que el equivalente conceptual portable sería
`JSON` anidado (soportado por ANSI SQL:2016 en adelante en varios motores) o una agregación de cadenas
(`STRING_AGG`), aunque el enunciado pide específicamente XML.

### 7. Resultados de los encuentros

El más simple: `SELECT` de `partido` con joins a `sede` y `seleccion` (local/visitante), formato libre ("en la
forma que vean más ilustrativa" — el enunciado no exige tabular).

## Requisito de volumen de datos previo

Antes de poder mostrar reportes representativos, el grupo debe asegurar que el seed data (sección IV del TP) y las
importaciones de la Entrega 6 ya estén cargadas: sin al menos 24 partidos con goles, tarjetas y formaciones
completas, reportes como el de goleadores o la matriz de prime time van a quedar vacíos o triviales y no van a
demostrar la lógica ante el docente. Conviene ejecutar este check de volumen como primer paso documentado del
informe de la Entrega 7, no dejarlo implícito.

## Recomendación de implementación

Cada reporte como **un SP con parámetros opcionales** (ej. `@seleccion_id = NULL` para "todas"), de forma que un
mismo SP sirva tanto para el reporte agregado como para el filtrado — reduce la cantidad de objetos y facilita el
testing. Documentar en el informe, para cada SP, cuál es el resultado esperado dado el juego de datos de la
sección IV (por ejemplo, qué jugador debería aparecer como goleador del torneo con los datos cargados), para que
el docente pueda verificar en el coloquio sin ambigüedad.
