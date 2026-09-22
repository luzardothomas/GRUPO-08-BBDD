# Análisis — Entrega 3 (DER) y Entrega 4 (Instalación y Configuración)

## Entrega 3 — Diagrama de Entidad-Relación

### Qué pide el enunciado

- Formato imagen (JPG/PNG), legible.
- Análisis de la **totalidad** del enunciado (los 9 módulos A–I) para derivar la estructura.
- Aplicación de las **tres primeras Formas Normales**; donde no se apliquen, justificar por escrito.
- Nivel de detalle libre, pero como mínimo deben figurar **entidades, relaciones y cardinalidades**.

Este es un entregable de diseño conceptual/lógico, por lo tanto es el punto donde conviene razonar en términos
puramente relacionales (ANSI), sin mezclar todavía particularidades de SQL Server. El DER debe poder explicarse
sin nombrar el motor.

### Checklist de cobertura por módulo

Usando la grilla de `analisis_modelo_negocio.md`, cada módulo del TP debería resolver en el DER como:

- **A. Sedes/Partidos**: `sede` 1—N `partido` (vía local y visitante, dos FK a `seleccion`); huso horario en
  `pais` y `sede` como offset fijo respecto de UTC (`CHAR(6)`, ver más abajo), doble timestamp (local/UTC) en
  `partido`, y `partido.estado` para poder identificar el próximo partido aún no jugado de cada selección.
- **B. Selecciones/Convocatoria**: `pais` 1—1 `seleccion` (un país participa una sola vez), `seleccion` 1—N
  `cuerpo_tecnico`, `seleccion` N—M `jugador` resuelta con entidad asociativa `convocatoria` que además historiza
  altas/bajas (atributos `fecha_alta`, `motivo_alta`, `fecha_baja`, `motivo_baja`).
- **C. Formaciones**: `partido` × `seleccion` → `formacion` (entidad con atributo `esquema_tactico`); `formacion`
  1—N `formacion_jugador` (con flag titular/suplente).
- **D. Cambios**: `sustitucion` como entidad de evento, con dos FK a `jugador` (sale/entra) y FK a `partido` y
  `seleccion`.
- **E. Goles**: `gol` como entidad de evento, FK a `jugador` (autor) y FK opcional a `jugador` (asistencia).
- **F. Amonestaciones**: `tarjeta` (evento) → dispara `suspension` (derivada), parametrizada por
  `criterio_suspension`.
- **G. Árbitros**: `arbitro` 1—N `arbitro_idioma` (multivaluado → tabla aparte, resuelve 1FN), `partido` N—M
  `arbitro` resuelta por `designacion_arbitral` (con atributo `rol`), y `designacion_arbitral` 1—N
  `informe_arbitral`.
- **H. Publicidad**: `anunciante` 1—N `campania`, `campania` N—M `pais` (interés) vía `campania_pais_interes`,
  `campania` 1—N `pieza_publicitaria`, `partido` 1—N `espacio_publicitario` (máx. 4) con FK opcional a
  `pieza_publicitaria`.
- **I. Importación**: no necesariamente requiere entidades propias en el DER de negocio; si se modela staging,
  conviene mostrarlo como un subconjunto aparte (o ni incluirlo, y documentarlo solo en Entrega 6).

### Análisis de Formas Normales sobre el modelo existente

Tomando como base `doc/db_definition.sql`:

- **1FN**: se cumple de forma consistente — no hay grupos repetitivos ni atributos multivaluados embebidos.
  Los casos que en una planilla real serían multivaluados (idiomas de árbitro, convocados de una selección, países
  de interés de una campaña) están correctamente resueltos como tablas aparte (`arbitro_idioma`, `convocatoria`,
  `campania_pais_interes`).
- **2FN**: exige que no haya dependencias parciales de la clave en tablas con clave compuesta. Revisar
  puntualmente `formacion_jugador` (PK compuesta `formacion_id, jugador_id`): los atributos `dorsal` y `posicion`
  dependen de la combinación completa (posición **en ese partido**, no del jugador en general), por lo que la 2FN
  se sostiene. Igual análisis en `arbitro_idioma` y `campania_pais_interes`, que no tienen atributos adicionales más
  allá de la clave, por lo que 2FN es trivial.
- **3FN**: exige eliminar dependencias transitivas (atributo no clave dependiendo de otro atributo no clave). Punto
  a documentar explícitamente: `sede.huso_horario` es independiente de `sede.pais_id` porque un país extenso puede
  tener sedes en distintos husos (caso concreto del Mundial 2026 con Estados Unidos y México), por lo que su
  presencia en `sede` no constituye una dependencia transitiva.
- **Atributo derivado eliminado**: `convocatoria.activo` se quitó del modelo por ser derivable de
  `fecha_baja IS NULL`. Mantener ambos permitía estados contradictorios (un registro con `activo = 1` y
  `fecha_baja` informada) sin aportar información nueva. Es el ejemplo más claro de corrección por normalización
  que conviene señalar en el informe.

**Desnormalizaciones intencionales** (excepciones a 3FN que hay que justificar explícitamente, porque el enunciado
pide aplicar las tres primeras formas normales y fundamentar los casos donde no se apliquen):

1. `partido.goles_local` / `goles_visitante` son derivables por agregación de `gol`. Se mantienen porque el fixture
   y el reporte de resultados los consultan de forma intensiva; la consistencia con el detalle de goles queda a
   cargo del SP transaccional de registro de gol (Entrega 5).
2. `pais.pbi_per_capita` es una medida que varía en el tiempo alojada en una entidad estática. Se acepta porque el
   sistema sólo necesita el valor vigente para priorizar piezas publicitarias, no la serie histórica. La
   alternativa normalizada —una tabla `indicador_economico(pais_id, anio, indicador, valor)`— se difiere a la
   Entrega 6, cuando se importe efectivamente el indicador `NY.GDP.PCAP.CD` del Banco Mundial.

**Restricción que no se puede declarar y se valida por SP** (conviene tenerla explicada para el coloquio): las FK
de `formacion_jugador`, `gol`, `tarjeta` y `sustitucion` apuntan directamente a `jugador`, de modo que a nivel
declarativo nada impide registrar un evento de un jugador no convocado por esa selección. No es resoluble con una
FK compuesta hacia `convocatoria` porque esa tabla está historizada: el par `(seleccion_id, jugador_id)` puede
tener varias filas por sucesivas altas y bajas, y por lo tanto no es una clave candidata estable a la que
referenciar. La validación se hace en los SP de la Entrega 5.

### Cardinalidades mínimas a marcar en el diagrama

| Relación | Cardinalidad |
|---|---|
| pais — sede | 1 — N |
| pais — seleccion | 1 — 1 (un país participa una vez) |
| seleccion — partido (local/visitante) | 1 — N (dos roles) |
| seleccion — jugador (vía convocatoria) | N — M |
| partido — formacion | 1 — N (una por selección) |
| formacion — jugador (vía formacion_jugador) | N — M |
| partido — gol / tarjeta / sustitucion | 1 — N |
| jugador — suspension | 1 — N |
| arbitro — partido (vía designacion_arbitral) | N — M |
| partido — espacio_publicitario | 1 — 4 (cardinalidad acotada, a marcar explícitamente) |
| anunciante — campania | 1 — N |
| campania — pieza_publicitaria | 1 — N |

### Entregable

Generar el diagrama (herramienta libre: dbdiagram.io, MySQL Workbench, draw.io, pgModeler, etc. — cualquiera
sirve porque el diagrama es agnóstico de motor) a partir del esquema anterior, exportarlo como PNG/JPG legible y
acompañarlo, en el documento PDF, de la justificación de las decisiones de normalización arriba señaladas.

**Estado actual**: los diagramas viejos (`doc/er-diagram.png`, `doc/schema.png`) quedaron obsoletos y se
reemplazaron por `doc/herramienta1.mmd`/`.png` y `doc/herramienta2.mmd`/`.png` — DER en formato Mermaid (`erDiagram`)
generado directamente desde `doc/db_definition.sql`, con las 24 entidades, sus columnas PK/FK y la cardinalidad de
cada relación. Falta confirmar que la imagen final entregada sea legible como archivo único (JPG/PNG) tal como pide
el enunciado, no solo el `.mmd` fuente.

---

## Entrega 4 — Instalación y Configuración

### Qué pide el enunciado

Documento técnico dirigido a un **DBA** (no a un desarrollador ni a un cliente comercial), sin capturas de
pantalla, que detalle:

- Instalación del motor (en este caso, obligatoriamente **SQL Server**, según lo asignado/confirmado en las
  Entregas 1–2).
- Configuración de memoria.
- Configuración de seguridad.
- Ubicación de archivos.

### Cómo encararlo en términos académicos

Aunque el motor esté fijado por el enunciado, conviene redactar cada sección explicando primero **el concepto
general de administración de bases de datos** (aplicable a cualquier RDBMS) y luego el parámetro concreto de
SQL Server que lo materializa. Esto muestra comprensión de fondo, no solo transcripción de un instructivo de
instalación:

1. **Instalación**: edición elegida (Developer/Express, justificando por qué no una edición paga en este contexto
   académico), *features* seleccionados (Database Engine, sin necesidad de Analysis/Reporting Services salvo que
   se use para la Entrega 9), modo de autenticación (mixto vs. Windows — justificar según el escenario de LAN
   descripto en las Entregas 1–2).
2. **Memoria**: concepto general de *buffer pool* / caché de páginas en cualquier RDBMS → en SQL Server,
   `max server memory` / `min server memory`, y por qué fijar un techo es una práctica estándar en cualquier motor
   compartiendo el host con otros servicios.
3. **Seguridad**: principio de menor privilegio, separación entre autenticación (login) y autorización (permisos
   sobre objetos) — concepto ANSI-SQL de roles y `GRANT`/`REVOKE` — y su instanciación en SQL Server
   (server logins, database users, server roles vs. database roles). Esto sienta la base conceptual que después se
   implementa en la Entrega 8.
4. **Ubicación de archivos**: separación física de datos (`.mdf`), log (`.ldf`) y, si corresponde, tempdb, en
   discos/volúmenes distintos — principio general de I/O en cualquier motor, no exclusivo de SQL Server.

### Decisiones ya tomadas y reflejadas en `doc/db_definition.sql`

La Sección 1 del script implementa la configuración que este documento debe explicarle al DBA. Las decisiones
concretas adoptadas son:

| Parámetro | Valor | Justificación |
|---|---|---|
| Collation | `Latin1_General_CI_AI` | Es la familia de collation estándar en **inglés** de SQL Server: viene del code page 1252, el mismo que usa una instalación "English (United States)" ([mssqltips.com](https://www.mssqltips.com/sqlservertip/6386/sql-server-collation-overview-and-examples/), [sqlservercentral.com](https://www.sqlservercentral.com/blogs/revised-difference-between-collation-sql_latin1_general_cp1_ci_as-and-latin1_general_ci_as)). El nombre "Latin1" no tiene relación con español/Latinoamérica: es el nombre del code page ISO 8859-1; la collation en español sería `Modern_Spanish_CI_AS` o `Traditional_Spanish_CI_AS`, que es justamente lo que se descartó. CI: los valores de dominio de los `CHECK` se aceptan con cualquier capitalización, lo que evita normalizar los archivos de origen en la importación. AI: `'Peru' = 'Perú'`, `'Mbappe' = 'Mbappé'`, clave para deduplicar en el upsert de la Entrega 6, donde los datasets de FIFA y Wikipedia conviven con y sin tildes. |
| Recovery model | `FULL` | Habilita backup de log y restauración a un punto en el tiempo; es el prerrequisito de la política de RPO de la Entrega 8, necesaria por el pico de escritura en días de partido. |
| Tamaño inicial | 1024 MB datos / 512 MB log | Pre-asignado para evitar autogrowth durante los partidos: el crecimiento de archivo es bloqueante y coincidiría con el pico de escritura. |
| Autogrowth | MB fijos (256 / 128), no porcentaje | El crecimiento porcentual se encarece progresivamente a medida que el archivo crece. |
| Ubicación de archivos | `.mdf` y `.ldf` en volúmenes distintos | El archivo de datos tiene acceso aleatorio y el de log secuencial; competir por el mismo cabezal degrada ambos. |
| Tipos numéricos | `INT` (no `INTEGER`) | `INTEGER` es el sinónimo ANSI de `INT` en T-SQL; se usa la forma nativa del motor por consistencia de estilo en todo el script. |
| Tipos de texto | `VARCHAR` en todo el script, sin `NVARCHAR` | Las fuentes reales del proyecto (fifa.com, Wikipedia, datasets de GitHub/Kaggle) publican los nombres de jugadores, árbitros y cuerpos técnicos ya romanizados en alfabeto latino, y la collation `CI_AI` ya cubre los acentos de español/portugués/francés/alemán/italiano. Se revisó y se descartó `NVARCHAR` incluso para nombres de persona: duplicar el ancho de almacenamiento no aporta nada si ninguna fuente real va a traer escritura no latina (coreano, japonés, árabe). |
| Huso horario | `CHAR(6)` con offset fijo (`'UTC-03'`) en `pais.huso_horario` y `sede.huso_horario`, en vez de nombres de zona | Ver desarrollo completo más abajo. |

**Norma de fechas del grupo**: independientemente de la configuración de idioma de la instancia (que queda a
criterio del DBA y no se fija en el script), se adopta como norma escribir **todas** las fechas en ISO 8601
(`'2026-06-11T18:00:00'`), porque es el único formato inequívoco sin importar el `LANGUAGE`/`DATEFORMAT` de la
sesión que ejecute el script. Conviene enunciarlo en el documento junto a la norma de nomenclatura, porque aplica
a todos los scripts de las entregas siguientes.

**Efecto colateral de AI a dejar asentado**: las restricciones `UNIQUE` sobre nombres propios (`uq_arbitro`,
`uq_cuerpo_tecnico`) pasan a considerar iguales dos grafías que difieren sólo en acentos. En este dominio es el
comportamiento buscado, pero es una consecuencia que el DBA debe conocer.

### Dimensionamiento de `VARCHAR`/`CHAR` (auditoría columna por columna)

Regla aplicada: para toda columna con dominio cerrado por `CHECK IN (...)`, el ancho se fija en el largo exacto
del valor más largo de la lista (no una cifra redonda "por las dudas"); para texto libre sin dominio cerrado, un
ancho realista según el caso de uso real, verificado con fuentes externas cuando correspondía (confederaciones,
sedes del Mundial 2026, nombres de países).

| Columna | Antes | Ahora | Motivo |
|---|---|---|---|
| `confederacion.nombre` | `VARCHAR(50)` | `VARCHAR(8)` + `CHECK IN (...)` | Sólo existen 6 confederaciones FIFA (AFC, CAF, CONCACAF, CONMEBOL, OFC, UEFA); la más larga tiene 8 caracteres ([Wikipedia](https://en.wikipedia.org/wiki/FIFA)). No tenía `CHECK` antes; se agregó, ya que el dominio es cerrado y conocido. |
| `pais.nombre` | `VARCHAR(100)` | `VARCHAR(80)` | Nombre común, no el oficial largo. El país con nombre común más largo ronda 33 caracteres (`Saint Vincent and the Grenadines`, `Democratic Republic of the Congo`); no tiene `CHECK` que lo gobierne (es un catálogo abierto), así que se deja margen real por encima del máximo conocido ([WorldAtlas](https://www.worldatlas.com/geography/what-is-the-longest-country-name-in-the-world-50109.html)). |
| `sede.nombre` | `VARCHAR(150)` | `VARCHAR(80)` | Estadios del Mundial 2026 confirmados; el nombre más largo entre los 16 (`Lincoln Financial Field`, Philadelphia) tiene 23 caracteres, pero el nombre puede cambiar por naming rights durante el proyecto, así que se deja margen. |
| `sede.ciudad` | `VARCHAR(100)` | `VARCHAR(80)` | Nombres de ciudad sede, ninguno cerca de 80 caracteres. |
| `jugador.club_origen` | `VARCHAR(150)` | `VARCHAR(120)` | Nombre de club (no razón social legal), rara vez supera 40-50 caracteres; sin `CHECK` que lo acote, se deja margen. |
| `partido.fase` / `criterio_suspension.fase_aplicable` | `VARCHAR(20)` | `VARCHAR(13)` | Dominio cerrado; máximo `'dieciseisavos'`/`'tercer_puesto'` = 13. |
| `partido.estado` | `VARCHAR(20)` | `VARCHAR(10)` | Dominio cerrado; los tres valores miden exactamente 10. |
| `cuerpo_tecnico.rol` | `VARCHAR(30)` | `VARCHAR(17)` | Dominio cerrado; máximo `'preparador_fisico'` = 17. |
| `jugador.posicion_habitual` | `VARCHAR(30)` | `VARCHAR(13)` | Dominio cerrado; máximo `'mediocampista'` = 13. |
| `sustitucion.periodo` | `VARCHAR(20)` | `VARCHAR(9)` | Dominio cerrado; máximo `'alargue_1'`/`'alargue_2'` = 9. |
| `sustitucion.motivo` | `VARCHAR(20)` | `VARCHAR(10)` | Dominio cerrado; máximo `'precaucion'` = 10. |
| `gol.tipo_gol` | `VARCHAR(20)` | `VARCHAR(10)` | Dominio cerrado; máximo `'tiro_libre'` = 10. |
| `gol.periodo` | `VARCHAR(20)` | `VARCHAR(17)` | Dominio cerrado; máximo `'adicional_alargue'` = 17. |
| `tarjeta.tipo` | `VARCHAR(10)` | `VARCHAR(8)` | Dominio cerrado; máximo `'amarilla'` = 8. |
| `tarjeta.tipo_expulsion` | `VARCHAR(20)` | `VARCHAR(14)` | Dominio cerrado; máximo `'doble_amarilla'` = 14. |
| `arbitro.categoria` | `VARCHAR(30)` | `VARCHAR(13)` | Dominio cerrado; máximo `'confederacion'` = 13. |
| `designacion_arbitral.rol` | `VARCHAR(20)` | `VARCHAR(11)` | Dominio cerrado; máximo `'asistente_1'`/`'asistente_2'` = 11. |
| `arbitro_idioma.idioma` / `pieza_publicitaria.idioma` | `VARCHAR(30)` | `VARCHAR(10)` | Nombre de idioma; es un catálogo conocido (no libre), y el más largo entre los idiomas usuales (`'Neerlandés'`) mide exactamente 10. |
| `convocatoria.motivo_alta/motivo_baja`, `tarjeta.motivo`, `suspension.motivo`, `informe_arbitral.sancion` | `VARCHAR(200)` | `VARCHAR(150)` | Texto libre corto (una justificación de una oración); no tiene dominio cerrado, así que no hay un "exacto", pero 200 era generoso sin razón. |
| `anunciante.nombre`, `campania.nombre` | `VARCHAR(150)` | `VARCHAR(100)` | Nombre comercial/de campaña, no la razón social legal. |
| `anunciante.contacto` | `VARCHAR(150)` | `VARCHAR(100)` | Dato de contacto (nombre, email o teléfono en texto libre). |
| `anunciante.razon_social` | `VARCHAR(150)` | sin cambio | Es el único de este grupo que se deja ancho: una razón social legal puede incluir sufijos societarios largos (S.A., S.R.L., Ltd., GmbH, y denominaciones extensas en ciertas jurisdicciones), a diferencia del nombre comercial. |

Las columnas con `IDENTITY`/`INT`, las `NUMERIC(12,2)` (montos, PBI per cápita) y `CHAR(1)`/`CHAR(3)`/`CHAR(6)`
(grupo, código ISO, huso horario) ya estaban correctamente dimensionadas y no se modificaron.

### Nota sobre husos horarios (decisión que cruza modelo y configuración)

`pais.huso_horario` y `sede.huso_horario` se modelaron primero con el nombre de zona (IANA + el nombre de
`sys.time_zone_info` que exige `AT TIME ZONE` en SQL Server, duplicado en dos columnas) para poder resolver el
prime time del módulo H con la hora oficial de cada mercado en cualquier fecha del año. Se revisó esa decisión
por sobre-ingeniería: el sistema **no necesita ese caso general**, porque los 64 partidos del torneo transcurren
en una única ventana de cinco semanas (junio–julio de 2026). Dentro de esa ventana el estado de horario de verano
de cada país no cambia, así que alcanza con un **offset fijo respecto de UTC**, calculado una sola vez para la
fecha del torneo.

Se optó por `CHAR(6)` con el formato `'UTC±HH'` (ej. `'UTC-03'`, `'UTC+09'`): longitud fija porque el offset
siempre ocupa esos 6 caracteres, y evita tanto la duplicación de columnas como la dependencia del catálogo de
zonas específico de Windows — el prime time pasa a calcularse con aritmética simple sobre `fecha_hora_utc`, sin
`AT TIME ZONE`. La restricción `chk_pais_huso_horario` / `chk_sede_huso_horario` valida el formato con `LIKE`.

**Limitación asumida y documentada**: el formato sólo admite offsets de hora entera (UTC-12 a UTC+14). Un país
con offset de media hora (India UTC+5:30, Irán UTC+3:30, partes de Australia) no entra en `CHAR(6)`; ninguno de
ellos es sede del Mundial 2026, pero si se cargara como mercado publicitario de interés habría que redondear el
offset o extender el formato a `CHAR(9)` (`'UTC+05:30'`). Se deja señalado para decidirlo si el caso aparece en
los datos reales que se importen en la Entrega 6.

### Vínculo con el escenario de negocio

El documento debería retomar el escenario ya definido en las Entregas 1–2 (aprox. 1 GB acumulado durante el
torneo, picos de escritura simultánea en horario de partidos, alta disponibilidad, uso en LAN) para justificar
las decisiones de memoria y almacenamiento con números concretos, en lugar de valores genéricos de manual.

### Formato

Documento técnico puro (sin diapositivas, sin video — a diferencia de las Entregas 1 y 2), sin capturas de
pantalla según exigencia explícita del enunciado; se recomienda usar diagramas o tablas de configuración en su
lugar.
