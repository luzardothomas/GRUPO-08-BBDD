# Análisis — Entrega 7 (Reportes)

## Qué pide el enunciado

- Antes de generar los reportes, garantizar **volumen de datos representativo** en todas las tablas (importación,
  APIs, testing manual o datos aleatorios).
- Generar un **SP por reporte**; **al menos dos deben devolver XML** (alcanza con que se muestre al ejecutarse, no hace
  falta escribir el archivo a disco):
  1. Goleadores por selección, fase y torneo.
  2. Tarjetas (amarillas y rojas) por selección y jugador, con detalle de suspensiones activas por acumulación.
  3. Designaciones arbitrales: partidos dirigidos por cada árbitro, con las amonestaciones/expulsiones que señaló.
  4. Ocupación publicitaria por sede y partido: anunciantes exhibidos en los cuatro espacios, e ingresos generados.
  5. Matriz de prime time: tabla cruzada (pivot) que muestre, para cada partido, en qué mercados/países su horario cae
     en prime time.
  6. Selecciones y plantillas: listado de selecciones con un vector anidado de convocados (nombre, posición, club,
     dorsal).
  7. Resultados de los encuentros (en la forma que sea más ilustrativa).
- Reglas generales del TP que también aplican: scripts de testing **separados**, con el **resultado esperado en
  comentarios**; encabezado con universidad, materia, integrantes, fecha y objetivo; validar existencia de objetos;
  sin SQL dinámico salvo que sea estrictamente necesario; norma de nomenclatura documentada.

## Encuadre conceptual: cada reporte es una consulta relacional, la forma de salida es lo variable

Para el informe conviene separar dos capas:
- **La lógica de agregación/consulta**, que es SQL estándar (`GROUP BY`, `GROUPING SETS`, funciones de agregación,
  joins, funciones de ventana) y sería igual en cualquier motor.
- **El formato de salida** (tabular, XML, pivot), que usa extensiones propias de T-SQL (`FOR XML`, `PIVOT`) y se
  documenta como tal, con su equivalente ANSI conceptual si se portara a otro motor.

## Cómo se relaciona cada reporte con el modelo (corregido)

Las notas anteriores suponían columnas que el modelo ya no tiene (`gol.seleccion_id`, `tarjeta.jugador_id`,
`tarjeta.seleccion_id`). Desde la revisión del 02-10-2026 (ver `doc/changelog.md`) los eventos cuelgan de la
formación o de la persona, y la selección **se deriva**:

| Dato | De dónde sale |
|---|---|
| Selección de un gol | `evento.gol.formacion_id` → `plantel.vw_formacion.seleccion_id` (formación del autor) |
| Fase de un gol | `plantel.vw_formacion.fase` |
| Selección de una tarjeta | `evento.tarjeta.persona_id` + `partido_id` → `plantel.vw_persona_partido.seleccion_id` (jugador o cuerpo técnico) |
| Nombre de quien recibe la tarjeta | `plantel.jugador` o `plantel.cuerpo_tecnico` por `persona_id` |
| Mercado de una pieza | `publicidad.pieza_publicitaria.pais_mercado_id` → `torneo.pais.huso_horario` |

### 1. Goleadores por selección, fase y torneo — `evento.reporte_goleadores` (XML)

- Base: `evento.gol` + `vw_formacion`, **excluyendo `tipo_gol = 'en_contra'` y `periodo = 'penales'`** (un gol en
  contra no es del autor para el goleador y la tanda de penales no cuenta). Esta regla faltaba en las notas.
- Tres niveles en un mismo XML: `<torneo>` (ranking con puesto, desempate por asistencias), `<por_seleccion>` y
  `<por_fase>` (en orden de torneo, no alfabético). La versión anterior sólo agrupaba por fase y no daba ni el ranking
  del torneo ni el total por selección, que el enunciado pide.
- Se agrupa por `jugador_id`, no por nombre (dos jugadores pueden llamarse igual).

### 2. Tarjetas con detalle de suspensiones activas — `evento.reporte_tarjetas`

- Una fila **por persona** (jugador o cuerpo técnico) y un `TOTAL SELECCIÓN` por selección (`GROUPING SETS`). La
  versión anterior agrupaba por `tarjeta_id`, así que mostraba una fila por tarjeta y nunca acumulaba.
- **Suspensión activa** = la de `evento.suspension` cuyo `partido_afectado_id` sigue `'programado'`, **o** que todavía
  no tiene partido asignado (`NULL`: la selección no tenía otro partido programado). La versión anterior no contaba
  este segundo caso.
- El detalle muestra el motivo (acumulación o expulsión) y qué partido se pierde. No se recalcula la acumulación: se
  usa lo que ya generó `evento.registrar_tarjeta` (Entrega 5), que es la única fuente de verdad.

### 3. Designaciones arbitrales — `arbitraje.reporte_designaciones` (XML)

- Jerarquía natural árbitro → designaciones → tarjetas (+ informes post-partido), por eso es el tercer reporte XML.
- No hay FK árbitro→tarjeta: la relación es transitiva vía partido. Las tarjetas se le atribuyen **sólo al árbitro
  principal** (es quien las señala); asistentes, cuarto y VAR figuran con sus designaciones sin tarjetas.
- La versión anterior agrupaba por rol (el mismo árbitro salía en varias filas) y no listaba los partidos.

### 4. Ocupación publicitaria e ingresos — `publicidad.reporte_ocupacion`

- Parte de `torneo.partido` con `LEFT JOIN` a `espacio_publicitario`, así un partido sin espacios cuenta con
  ocupación 0 en lugar de desaparecer.
- Por partido: los anunciantes de los 4 espacios, `ocupados / 4`, ingreso **facturado** (`monto_facturado`, importe
  histórico) e ingreso **estimado** (facturado + tarifa vigente de lo asignado y aún no facturado). Subtotal por sede
  y total general con `GROUPING SETS`. Con `@detalle = 1`, una fila por espacio.

### 5. Matriz de prime time (pivot) — `publicidad.reporte_matriz_prime_time`

- Hora local del mercado = hora UTC del partido + offset de `pais.huso_horario`, con **la misma fórmula** que usa
  `publicidad.asignar_espacios_partido`, para que la matriz y la asignación de espacios coincidan.
- Franja: `[prime_time_hora_desde, prime_time_hora_hasta)` de `torneo.parametro` (19 incluida, 23 **excluida**). La
  versión anterior tenía `BETWEEN 19 AND 23` fijo en el código: incluía las 23 y no respetaba el parámetro.
- Mercados = países con piezas publicitarias (los candidatos reales), no una lista fija. La versión anterior tenía
  5 países escritos a mano (ARG, BRA, ESP, MEX, FRA) cuando había 11 mercados.
- Como las columnas salen de los datos, el `PIVOT` se arma con **SQL dinámico** (`sp_executesql`, columnas con
  `QUOTENAME`, valores como parámetros). Es el caso de "estrictamente necesario" que admite el TP y se documenta en el
  script. Equivalente ANSI sin `PIVOT`: `MAX(CASE WHEN mercado = 'ARG' THEN en_prime_time END)` por cada columna.
- Con `@partido_id` sirve también como la "simulación de prime time de un partido" del módulo H.

### 6. Selecciones y plantillas — `plantel.reporte_plantillas` (XML)

- Selección → convocados vigentes (`fecha_baja IS NULL`): quien fue dado de baja no aparece y sí quien lo reemplazó.
- Un club desconocido se omite (la versión anterior inventaba el valor `'Agente Libre'`).
- Equivalente portable: JSON anidado (SQL:2016) o `STRING_AGG`, aunque el enunciado pide específicamente XML.

### 7. Resultados de los encuentros — `torneo.reporte_resultados`

- Fixture con resultado, penales, ganador, asistencia, ocupación del estadio y lista de goles. Un partido
  `'finalizado'` sin marcador muestra `'sin datos'` (la versión anterior mostraba `NULL`).
- Como forma "más ilustrativa", un segundo resultado con la **tabla de posiciones** de la fase de grupos.

## Decisiones comunes

- **Nombres**: `snake_case` con prefijo `reporte_`, en el esquema del módulo que consultan (la versión anterior usaba
  PascalCase, fuera de la norma del grupo). El script borra los SP viejos con `DROP PROCEDURE IF EXISTS`.
- **Parámetros opcionales** como filtros (`NULL` = todos). Los inválidos se informan en un único `THROW 50002`, igual
  que los SP de la Entrega 5.
- Los reportes XML devuelven además el documento en un parámetro `OUTPUT @resultado`: `INSERT ... EXEC` no admite un
  SP cuyo `SELECT` final use `FOR XML`, y así los tests (y la aplicación de la Entrega 9) pueden procesarlo.

## Requisito de volumen de datos previo

Las notas anteriores daban por hecho un "seed data" que no existía: `entrega5_test_exitosos.sql` deja la base vacía
con su bloque RESET. Por eso se agregó `src/entrega7/entrega7_carga_datos.sql`, que carga la sección IV del TP
**a través de los SP de la Entrega 5** (8 sedes en 4 husos, 16 selecciones × 23 convocados, 32 partidos con
formaciones, cambios, goles y tarjetas, 22 árbitros con terna completa, 8 anunciantes de 8 países) e incluye todos los
casos obligatorios (doble amarilla, roja directa, suspensión por acumulación que deja al jugador fuera de la formación
siguiente, cambio por lesión antes de los 20', partidos con prime time en más de 4 mercados, designación rechazada por
nacionalidad). Al final imprime un cuadro "mínimo exigido / cargado".

Limitación conocida: el modelo no tiene país del anunciante; el país se indica en la razón social.

## Comparación con el enunciado (estado actual)

| Requisito del PDF | Cobertura |
|---|---|
| Datos suficientes antes de los reportes | `entrega7_carga_datos.sql` (cuadro de control al final) |
| 1 SP por reporte | 7 SP en `entrega7_reportes.sql` |
| Al menos 2 en XML | 3: goleadores, designaciones arbitrales, plantillas |
| Goleadores por selección, fase y torneo | `<torneo>`, `<por_seleccion>`, `<por_fase>` |
| Tarjetas con suspensiones activas por acumulación | Columnas `Suspension_activa` y `Detalle_suspension` |
| Designaciones con tarjetas señaladas | `<designacion>` → `<tarjetas>` (sólo como principal) |
| Ocupación de los 4 espacios e ingresos | Resumen por partido/sede/total + detalle por espacio |
| Matriz de prime time (pivot) | `PIVOT` dinámico sobre todos los mercados candidatos |
| Plantillas con vector anidado | `<seleccion>` → `<convocados>` (nombre, posición, club, dorsal) |
| Resultados | Fixture + tabla de posiciones |
| Tests con resultado esperado | `entrega7_test_reportes.sql`: esperado en comentarios + chequeo OK/FALLO automático + pruebas de validación |

## Orden de ejecución

1. `entrega5_db_definition.sql`, `entrega5_sp_ABM.sql`, `entrega5_sp_logica_negocio.sql` (base recién creada).
2. `entrega7_carga_datos.sql`.
3. `entrega7_reportes.sql`.
4. `entrega7_test_reportes.sql` (todas las pruebas deben imprimir `OK`).
