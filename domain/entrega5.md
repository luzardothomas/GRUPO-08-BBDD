# Análisis — Entrega 5 (Base de Datos)

Estado: **implementada** en la carpeta `src/entrega5/`: `entrega5_db_definition.sql`, `entrega5_sp_ABM.sql` y
`entrega5_sp_logica_negocio.sql` (creación) y `entrega5_test_exitosos.sql` y `entrega5_test_fallidos.sql` (pruebas). Este documento resume qué pide el
enunciado, cómo se resolvió cada punto y las decisiones de diseño que hay que poder defender en el coloquio.

## Qué pide el enunciado y dónde está resuelto

| # | Requisito | Dónde |
|---|---|---|
| 1 | Generación de la base de datos y esquemas | `entrega5_db_definition.sql`, secciones iniciales |
| 2 | Generación de tablas y restricciones | `entrega5_db_definition.sql`, secciones 0 a H + sección I (`torneo.parametro`) |
| 3 | SP de ABM para **cada** tabla; ninguna alta, baja o modificación por acceso directo | `entrega5_sp_ABM.sql`, sección II: `_insertar`, `_modificar` y `_eliminar` de las 26 tablas |
| 4 | Mínimo 10 validaciones, informadas en un único mensaje agrupado por SP y operación | `entrega5_sp_ABM.sql`: 317 condiciones entre todas las tablas (y 62 más en los SP de negocio); ver "Validaciones" |
| 5 | Sin SQL dinámico, sin CLR, todo en T-SQL | Única excepción: `EXEC('CREATE SCHEMA ...')` (`CREATE SCHEMA` debe ser la primera sentencia de su lote) |
| 6 | SP de lógica de negocio, multi-tabla y transaccionales, separados de los de ABM | `entrega5_sp_logica_negocio.sql`, sección III (9 procedimientos) |
| 7 | Testing 1:1, con casos exitosos (con evidencia) y de validaciones fallidas | `entrega5_test_exitosos.sql` y `entrega5_test_fallidos.sql`: Parte 1 (ABM), Parte 2 (negocio) y Parte 3 (casos detallados por SP) |
| 8 | Encabezado con fecha, integrantes y descripción | Al inicio de cada archivo |
| 9 | Dos dígitos numéricos en el nombre del archivo; solución de SSMS | **Pendiente**, ver "Pendientes para la entrega formal" |

## Organización de los scripts

Los scripts están en `src/entrega5/`, divididos en secciones:

| Archivo | Sección | Contenido |
|---|---|---|
| `entrega5_db_definition.sql` | 0 a H | Base, esquemas, tablas y restricciones del modelo de la Entrega 3 |
| | I | `torneo.parametro`, tipo tabla `plantel.tt_formacion_jugador`, vistas `plantel.vw_formacion` y `plantel.vw_persona_partido` |
| `entrega5_sp_ABM.sql` | II | SP de ABM, agrupados por módulo |
| `entrega5_sp_logica_negocio.sql` | III | SP de lógica de negocio |
| | IV | Carga de los parámetros iniciales con `torneo.parametro_cargar_defaults`, que inserta sólo las claves que faltan (no pisa valores ya ajustados) |
| `entrega5_test_exitosos.sql` | Parte 1 | Casos que los SP de ABM deben aceptar, sobre un escenario encadenado (lotes `E-1.x.nn`) |
| | Parte 2 | Casos válidos de los SP de negocio, incluidos los casos obligatorios de la sección IV del TP (`E-2.x.nn`) |
| | Parte 3 | Casos válidos detallados por SP: bordes y variantes (`E-3.x.nn`), con sus preparaciones (`P-3.nn`) |
| `entrega5_test_fallidos.sql` | Parte 1 | Rechazos de los SP de ABM (`F-1.x.nn`), sobre el mismo escenario (que arma con lotes `P-1.x.nn`) |
| | Parte 2 | Rechazos de los SP de negocio (`F-2.x.nn`) |
| | Parte 3 | Rechazos detallados por SP: cada condición de error y sus combinaciones (`F-3.x.nn`) |

### Cómo ejecutarlos

1. Ejecutar, en este orden, `entrega5_db_definition.sql`, `entrega5_sp_ABM.sql` y `entrega5_sp_logica_negocio.sql`.
   El primero elimina la base `mundial_2026` si existe y la recrea desde cero (lo que se pide hacer en vivo en el
   coloquio). Tarda unos segundos.
2. Ejecutar `entrega5_test_exitosos.sql` completo, de una vez y en la misma ventana de consulta (usa tablas
   temporales para pasar los id generados entre lotes). Termina con un resumen de pruebas en `OK` y en `FALLO`.
3. Recrear la base (paso 1) y ejecutar `entrega5_test_fallidos.sql` de la misma forma. Es independiente del
   anterior: vuelve a armar el escenario con sus lotes de preparación. Cada prueba muestra en Mensajes el mensaje
   con el que el SP rechaza la entrada (no hay resumen de `OK`/`FALLO`).

Cada archivo exige la base recién creada: si ya tiene datos avisa y no ejecuta nada. Cada lote empieza con
`PRINT '--- <id> <descripción>'` y un comentario con el resultado esperado y lo que requiere, de modo que también
se puede ejecutar una prueba puntual (el encabezado de cada archivo tiene el índice de ids y el procedimiento).
Con el contenedor de `sqlserver-docker/` (local, no versionado), `./entrega5.sh` recrea la base y ejecuta ambos.

## Norma de nombres de los procedimientos

- ABM: `<esquema>.<tabla>_insertar`, `_modificar`, `_eliminar`.
- `<esquema>.<tabla>_validar`: SP **interno** con las condiciones comunes al alta y a la modificación. Devuelve los
  errores acumulados en un parámetro `OUTPUT`; no se invoca desde afuera.
- Negocio: `<esquema>.<verbo>_<objeto>` (`registrar_tarjeta`, `cargar_formacion`, `designar_arbitros`...).
- Sin prefijo `sp_` (reservado a los procedimientos de sistema).
- Variables y parámetros en `snake_case`, con el mismo nombre que la columna que representan.

## Validaciones y mensaje único agrupado

Cada SP acumula las condiciones incumplidas y lanza una única excepción al final, sin cortar en la primera:

```sql
DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

IF @dorsal IS NULL OR @dorsal NOT BETWEEN 1 AND 99
    SET @errores += '- El dorsal debe estar entre 1 y 99.' + @nl;

IF EXISTS (SELECT 1 FROM plantel.convocatoria
           WHERE seleccion_id = @seleccion_id AND dorsal = @dorsal AND fecha_baja IS NULL)
    SET @errores += '- El dorsal ya está en uso en la convocatoria vigente de la selección.' + @nl;

-- ... más condiciones ...

IF @errores <> ''
BEGIN
    SET @errores = 'plantel.convocatoria_insertar - alta rechazada:' + @nl + @errores;
    THROW 50001, @errores, 1;
END;
```

- Error **50001**: validación de un SP de ABM. Error **50002**: validación de un SP de negocio.
- Cuidado al agregar condiciones: concatenar una variable `NULL` anula todo el mensaje; por eso los valores que
  pueden venir nulos se envuelven en `ISNULL(...)`.
- Las bajas son físicas y se rechazan si hay filas dependientes, indicando cuáles (no se llega al error de FK).
- Se informan **todas** las condiciones incumplidas. Sólo se omite una condición cuando no se puede evaluar porque
  depende de un dato que ya es inválido (por ejemplo, el rango del minuto con un período inválido, o si la
  selección juega el partido cuando la tarjeta no existe).
- Si un `_modificar` recibe un id inexistente, informa "No existe..." **y además** los errores de los datos
  recibidos: llama al `_validar` con `@solo_datos = 1`, que omite sólo lo que depende del registro (su partido, su
  formación, sus jugadores). Lo mismo hacen `registrar_sustitucion`, `registrar_gol` y `registrar_tarjeta` cuando
  no pueden identificar la formación, el jugador o la persona.
- No se valida lo que ya garantiza el tipo de dato: un parámetro del mismo largo que la columna no necesita un
  control de longitud (SQL Server trunca el valor al recibirlo). Sí se controla cuando el parámetro es más largo
  que la columna (clave, idioma, esquema), para no truncar en silencio.
- Los formatos fijos usan `DATALENGTH` o patrones `LIKE '%[^...]%'`: `LEN` y `LIKE` con patrón fijo ignoran los
  espacios finales (`'UTC-03 '` pasaría). Los duplicados se comparan con el valor recortado, que es el que se guarda.

Reglas destacadas, además de las de formato, dominio, existencia y unicidad de cada tabla:

| Tabla | Regla |
|---|---|
| `partido` | Hora local en el huso de la sede y mismo instante que la UTC; en fase de grupos ambas selecciones del mismo grupo; cruce no repetido; sede libre ese día; ninguna selección con otro partido a menos de 24 horas |
| `convocatoria` | Dorsal 1–99 no repetido entre los vigentes; un jugador no puede estar vigente en dos selecciones; cupo máximo de convocados |
| `formacion` | Esquema de 3 a 5 líneas que suman 10 jugadores de campo |
| `formacion_jugador` | Convocado vigente a la fecha del partido; no suspendido para ese partido; máximo de titulares y de suplentes |
| `sustitucion` | El que sale está en cancha y no fue expulsado; el que entra está en el banco y no participó; máximo de cambios y ventanas, con el adicional del alargue; ventanas en orden; minuto coherente con el período |
| `gol` | Autor y asistente ingresaron al campo; gol en contra y gol de tanda sin asistencia; minuto coherente con el período |
| `tarjeta` | La persona participa del partido; no estaba ya expulsada; la doble amarilla exige una amarilla previa |
| `suspension` | La selección del sancionado juega el partido afectado, que es posterior al de la tarjeta |
| `designacion_arbitral` | Conflicto de nacionalidad; rol y árbitro no repetidos en el partido; no dirige dos partidos en 24 horas |
| `pieza_publicitaria` | El mercado debe ser un país de interés de la campaña |
| `espacio_publicitario` | Espacio 1–4 no repetido; campaña vigente en la fecha del partido; un espacio facturado no se modifica ni elimina |

## SP de lógica de negocio

Todos validan primero (un único mensaje agrupado) y después abren la transacción con `SET XACT_ABORT ON` y
`TRY...CATCH` + `ROLLBACK` + `THROW`. Si son invocados dentro de una transacción ya abierta no abren otra ni hacen
`ROLLBACK` por su cuenta: esa decisión queda para quien la abrió.

| Caso del enunciado | Procedimiento | Tablas que modifica |
|---|---|---|
| Partidos y resultados | `torneo.registrar_resultado` | `partido` (resultado y estado) y `espacio_publicitario` (fecha de exhibición) |
| Altas y bajas de último momento | `plantel.reemplazar_convocado` | `convocatoria` (baja del saliente + alta del entrante) |
| Alineaciones y formaciones | `plantel.cargar_formacion` | `formacion` y `formacion_jugador` (titulares y banco) |
| Cambios durante el partido | `evento.registrar_sustitucion` | `sustitucion` (calcula la ventana) |
| Goles | `evento.registrar_gol` | `gol` y `partido` (marcador) |
| Amonestaciones, expulsiones y suspensión | `evento.registrar_tarjeta` | `tarjeta` y `suspension` |
| Designación de árbitros | `arbitraje.designar_arbitros` | `designacion_arbitral` (los cinco roles) |
| Las cuatro piezas publicitarias | `publicidad.asignar_espacios_partido` | `espacio_publicitario` (los cuatro espacios) |
| Historial para facturar | `publicidad.facturar_espacios_partido` | `espacio_publicitario` |
| Importación de datos externos | — | Corresponde a la Entrega 6 (ver `entrega6.md`), que reutiliza estos SP |

## Decisiones de diseño a documentar y defender

1. **Parámetros del reglamento en una tabla** (`torneo.parametro`): cupo mínimo y máximo de convocados, titulares
   y suplentes, cambios y ventanas (más los adicionales del alargue), partidos de suspensión por roja y franja de
   prime time. Es la única tabla agregada al modelo; conviene sumarla al DER.
2. **Marcador desnormalizado.** `partido.goles_*` y `penales_*` son un resumen de `evento.gol`. Los SP de gol lo
   recalculan en su misma transacción (`torneo.partido_actualizar_marcador`), por lo que no puede quedar
   desincronizado. El gol en contra suma al rival; los goles de la tanda van a `penales_*`.
3. **Cierre del partido.** `torneo.registrar_resultado` es la única forma de pasar a `finalizado`. Si el partido
   tiene formaciones, el resultado sale del detalle y lo informado debe coincidir; si no las tiene (resultado
   importado), se usa lo informado. Un partido finalizado no admite más eventos.
4. **Doble amarilla.** La primera amarilla es una fila `amarilla`; la segunda en el mismo partido se registra como
   una única fila `roja` / `doble_amarilla` (`registrar_tarjeta` hace la conversión).
5. **Acumulación de amarillas.** Se cuentan las amarillas en partidos distintos posteriores a la última suspensión
   por acumulación de la persona, sin contar las de partidos donde terminó expulsada por doble amarilla. Se aplica
   el criterio activo más específico para la fase y el tipo de persona. La suspensión recae en el próximo partido
   programado de su selección; si aún no existe queda con partido `NULL` hasta completarla.
6. **Advertencia arbitral desde dieciseisavos.** Se interpreta "país que puede cruzarse" como: el país del árbitro
   tiene una selección que todavía no perdió un partido de eliminación directa. No bloquea: se devuelve en un
   parámetro `OUTPUT` y por `PRINT`.
7. **Criterio de priorización publicitaria** (el enunciado lo deja a definir por el grupo). Son candidatas las
   piezas de campañas vigentes en la fecha del partido, ordenadas por:
   1. el mercado de la pieza es el país de una de las dos selecciones;
   2. el mercado es el de mayor PBI per cápita entre los países de interés de su campaña;
   3. el horario del partido cae en prime time en el huso del mercado;
   4. desempate: mayor PBI per cápita, mayor tarifa.

   Entra a lo sumo una pieza por campaña. `orden_prioridad` guarda el criterio que ubicó a la pieza (1 a 4).
8. **Ventanas de cambio.** Las calcula `registrar_sustitucion`: los cambios del mismo equipo en el mismo minuto y
   período comparten ventana. No se modela la excepción reglamentaria del entretiempo.

## Testing

Las pruebas están en dos archivos: `entrega5_test_exitosos.sql` (lo que los SP deben aceptar, con evidencia) y
`entrega5_test_fallidos.sql` (lo que deben rechazar). Ambos cargan sus datos a través de los SP; las únicas
sentencias directas son las de algunas preparaciones de la Parte 3, que dejan partidos de prueba en estado
`finalizado`. Exitosos registra cada comprobación en una tabla temporal y termina con un resumen de `OK`/`FALLO`.

En fallidos cada prueba es un comentario con la entrada inválida y la cantidad de errores que debe informar el SP,
un `PRINT` con su id y la llamada al SP dentro de `TRY...CATCH`, que muestra el mensaje de rechazo:

```sql
-- F-3.1.01 Clave vacia => 1 error
PRINT '--- F-3.1.01 torneo.parametro_insertar: Clave vacia';
BEGIN TRY EXEC torneo.parametro_insertar '', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
```

- Partes 1 y 2: un escenario encadenado (Argentina, Francia, México y Japón; partidos P1 a P4). En exitosos cada
  lote verifica su resultado; en fallidos las mismas operaciones se repiten como lotes de preparación (`P-...`) y
  cada rechazo es un lote propio, en el punto del escenario en que corresponde.
- Parte 3: casos detallados por SP (bordes, cada condición de error y sus combinaciones), incluidos
  suspensiones y todo el módulo de arbitraje (árbitros, idiomas, designaciones e informes). En fallidos hay un lote
  por SP; los casos que necesitan una operación válida previa la hacen en una transacción que se deshace.

Resultado al 27/10/2026 sobre SQL Server 2025 (CU10): exitosos 372 `OK`, sin `FALLO`; en fallidos las 1240 pruebas
muestran su mensaje de rechazo con la cantidad de errores que indica su comentario.
Las pruebas F-3.2.23, F-3.8.23, F-3.8.41 y F-3.12.18 detectaron validaciones que dejaban pasar espacios (huso
`'UTC-03 '`, esquema `'4 -3-3'` y árbitro duplicado con espacios al inicio), ya corregidas en los SP. Las pruebas
F-3.11.156 a F-3.11.164 verifican que se informen todos los errores juntos (registro inexistente y SP de negocio
que no identifican al jugador o la persona).

Casos obligatorios de la sección IV del TP cubiertos:

| Caso obligatorio | Prueba |
|---|---|
| Cambio por lesión dentro de los primeros 20 minutos | E-2.3.01 |
| Partido con roja directa | E-2.5.02 |
| Partido con expulsión por doble amonestación | E-2.8.02 |
| Suspendido por acumulación de amarillas, fuera de la formación del siguiente partido | E-2.8.01 y E-2.8.04; rechazos F-2.8.01 y F-2.8.02 |
| Prime time simultáneo en más de cuatro mercados, con priorización | E-2.6.01 |
| Designación arbitral descartada por conflicto de nacionalidad | F-2.9.01 |
| Importación con errores parciales | Entrega 6 (`entrega6_test.sql`, pruebas 5.1 y 5.2) |

Las pruebas E-2.11.01 y F-2.11.01 muestran la atomicidad: una operación que afecta dos tablas se deshace completa, y
un error a mitad de una transacción revierte también lo ya hecho.

## Pendientes para la entrega formal

- **Numerar los archivos.** El enunciado pide que cada archivo empiece con dos dígitos según el orden de
  ejecución (por ejemplo `01_entrega5_db_definition.sql`, `02_entrega5_sp_ABM.sql`, ...). Vale también para la
  Entrega 6. Las vistas y el tipo tabla podrían ir a un script propio de vistas y funciones: hoy están en la
  sección I de `entrega5_db_definition.sql`.
- **Solución de SSMS** que agrupe esos archivos.
- **Juego de datos de la sección IV.** La Entrega 6 ya importa 16 sedes, 48 selecciones con su tabla final y los
  26 convocados más el DT de cada una (además de las estadísticas individuales de Kaggle). Faltan los partidos,
  las formaciones de cada partido, los árbitros con sus designaciones y la asignación de espacios publicitarios,
  que se cargan con los SP de negocio (seed de la Entrega 7).
- Sumar `torneo.parametro` al DER y al documento de la Entrega 3.
