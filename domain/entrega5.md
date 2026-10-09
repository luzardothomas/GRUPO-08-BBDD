# Análisis — Entrega 5 (Base de Datos)

Estado: **implementada** en `doc/entrega5_definition.sql` y `doc/entrega5_sp.sql` (creación) y `doc/entrega5_test.sql` (pruebas). Este documento
resume qué pide el enunciado, cómo se resolvió cada punto y las decisiones de diseño que hay que poder defender
en el coloquio.

## Qué pide el enunciado y dónde está resuelto

| # | Requisito | Dónde |
|---|---|---|
| 1 | Generación de la base de datos y esquemas | `entrega5_definition.sql`, secciones iniciales (contenido de `db_definition.sql`) |
| 2 | Generación de tablas y restricciones | `entrega5_definition.sql`, secciones 0 a H (ídem) + sección I (`torneo.parametro`) |
| 3 | SP de ABM para **cada** tabla; ninguna alta, baja o modificación por acceso directo | `entrega5_sp.sql`, sección II: `_insertar`, `_modificar` y `_eliminar` de las 26 tablas |
| 4 | Mínimo 10 validaciones, informadas en un único mensaje agrupado por SP y operación | Sección II: más de 300 condiciones entre todas las tablas; ver "Validaciones" |
| 5 | Sin SQL dinámico, sin CLR, todo en T-SQL | Única excepción: `EXEC('CREATE SCHEMA ...')`, heredada de `db_definition.sql` (`CREATE SCHEMA` debe ser la primera sentencia de su lote) |
| 6 | SP de lógica de negocio, multi-tabla y transaccionales, separados de los de ABM | `entrega5_sp.sql`, sección III (9 procedimientos) |
| 7 | Testing 1:1, con casos exitosos (con evidencia) y de validaciones fallidas | `entrega5_test.sql`: Parte 1 (ABM) y Parte 2 (negocio) |
| 8 | Encabezado con fecha, integrantes y descripción | Al inicio de ambos archivos |
| 9 | Dos dígitos numéricos en el nombre del archivo; solución de SSMS | **Pendiente**, ver "Pendientes para la entrega formal" |

## Organización de los scripts

Por decisión del grupo todo el código de creación está en un único archivo, dividido en secciones:

| Archivo | Sección | Contenido |
|---|---|---|
| `doc/entrega5_definition.sql` y `doc/entrega5_sp.sql` | 0 a H | Base, esquemas, tablas y restricciones: el contenido de `db_definition.sql`, sin cambios |
| | I | `torneo.parametro`, tipo tabla `plantel.tt_formacion_jugador`, vistas `plantel.vw_formacion` y `plantel.vw_persona_partido` |
| | II | SP de ABM, agrupados por módulo |
| | III | SP de lógica de negocio |
| | IV | Carga de los parámetros iniciales (mediante su SP de ABM) |
| `doc/entrega5_test.sql` | Parte 1 | Pruebas de los SP de ABM |
| | Parte 2 | Pruebas de los SP de negocio, incluidos los casos obligatorios de la sección IV del TP |

`db_definition.sql` se conserva como referencia del modelo (Entrega 3); `entrega5_definition.sql` lo contiene completo.

### Cómo ejecutarlos

1. Ejecutar `entrega5_definition.sql` y luego `entrega5_sp.sql`. Elimina la base `mundial_2026` si existe y la recrea desde cero (lo que se pide hacer
   en vivo en el coloquio). Tarda unos segundos.
2. Ejecutar `entrega5_test.sql` completo, de una vez y en la misma ventana de consulta (usa tablas temporales para
   pasar los id generados entre lotes). Termina con un resumen: todas las pruebas deben figurar en `OK`.

El script de pruebas exige la base recién creada: si ya tiene datos avisa y no ejecuta nada.

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

`entrega5_test.sql` carga todos sus datos a través de los SP (ningún `INSERT` directo a tablas de la base) y
registra cada comprobación en una tabla temporal; el resumen final debe mostrar 115 comprobaciones en `OK`.
Los rechazos verifican el número de error y, cuando corresponde, la cantidad exacta de condiciones agrupadas.

Casos obligatorios de la sección IV del TP cubiertos:

| Caso obligatorio | Prueba |
|---|---|
| Cambio por lesión dentro de los primeros 20 minutos | 2.3.a |
| Partido con roja directa | 2.5.b |
| Partido con expulsión por doble amonestación | 2.8.b |
| Suspendido por acumulación de amarillas, fuera de la formación del siguiente partido | 2.8.a y 2.8.d |
| Prime time simultáneo en más de cuatro mercados, con priorización | 2.6.a |
| Designación arbitral descartada por conflicto de nacionalidad | 2.9.a |
| Importación con errores parciales | Entrega 6 |

Las pruebas 2.11.a y 2.11.b muestran la atomicidad: una operación que afecta dos tablas se deshace completa, y
un error a mitad de una transacción revierte también lo ya hecho.

## Pendientes para la entrega formal

- **Dividir en archivos numerados.** El enunciado pide que cada archivo empiece con dos dígitos según el orden de
  ejecución, y scripts separados para tablas, SP de ABM, SP de negocio, vistas/funciones y testing. Las secciones
  de `entrega5_sp.sql` están delimitadas para poder cortarlo sin reescribir nada, por ejemplo:
  `01_base_y_esquemas.sql`, `02_tablas.sql`, `03_vistas_y_tipos.sql`, `04_sp_abm.sql`, `05_sp_negocio.sql`,
  `06_parametros_iniciales.sql`, `07_test_abm.sql`, `08_test_negocio.sql`.
- **Solución de SSMS** que agrupe esos archivos.
- **Juego de datos completo** de la sección IV (8 sedes, 16 selecciones con 23 convocados, 24 partidos, 15
  árbitros): el script de pruebas carga un subconjunto mínimo; el volumen final llega con la Entrega 6.
- Sumar `torneo.parametro` al DER y al documento de la Entrega 3.
