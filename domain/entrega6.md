# Análisis — Entrega 6 (Procesos de Importación)

Estado: **implementada** en la carpeta `src/entrega6/`. Este documento resume qué pide el enunciado, cómo se
resolvió cada punto y las decisiones de diseño que hay que poder defender en el coloquio.

## Qué pide el enunciado y dónde está resuelto

| # | Requisito | Dónde |
|---|---|---|
| 1 | Importar información masiva mediante SP | Un SP por fuente, ver "Datasets y APIs" |
| 2 | Al menos dos datasets, en al menos dos formatos | **CSV**: `teams.csv` y `players.csv` (Kaggle). **JSON**: `worldcup.json` (openfootball) y wikitext de Wikipedia. **XML**: `tarifas_publicidad.xml` (tarifario comercial) |
| 3 | Al menos uno obtenido por scraping, documentando técnica y página | Sedes, selecciones y planteles, scrapeados de Wikipedia en T-SQL (`entrega6_scraping.sql`) |
| 4 | Al menos dos APIs, documentando sus límites | Banco Mundial y Frankfurter (`entrega6_apis.sql`) |
| 5 | Procesar los archivos tal cual se proveen | `teams.csv` y `players.csv` con `BULK INSERT`; `worldcup.json` y `tarifas_publicidad.xml` con `OPENROWSET(BULK ..., SINGLE_BLOB)` |
| 6 | Descargar o scrapear en vivo durante la defensa | Los SP `scrapear_*` descargan y procesan la página en el momento |
| 7 | Upsert sin duplicados | Clave natural de cada fila + `EXISTS`, sin `MERGE`. Prueba 4.1: reimportar todo no inserta ni cambia nada |
| 8 | Mantener el registro de la información histórica | Convocatorias (bajas con fecha y motivo), partidos finalizados, PBI por año, tipos de cambio por fecha, lotes y errores |
| 9 | Usar los SP de la Entrega 5 | Sedes, selecciones, jugadores, convocatorias, cuerpo técnico, partidos, resultados, anunciantes, campañas y piezas publicitarias se dan de alta y se modifican con sus SP de la Entrega 5 |
| 10 | Importar los registros correctos y reportar los que no | Cada fila en su propio `TRY...CATCH` y su propia transacción; las rechazadas quedan en `importacion.error` con el motivo |
| 11 | El nombre del archivo es un parámetro | `@ruta_archivo` en los importadores de CSV, JSON y XML; `@pagina` en los de scraping |
| 12 | Errores con excepciones (`THROW`) | 50003 rechaza el archivo o la página entera; 50004 rechaza una fila por formato o datos incompletos; 50001/50002 vienen de los SP de la Entrega 5 |
| 13 | Conversión de moneda en T-SQL | `publicidad.convertir_moneda` convierte a USD en T-SQL los montos de `tarifas_publicidad.xml` (EUR, MXN, BRL, GBP, CAD, JPY, KRW, AUD) usando `publicidad.tipo_cambio` |
| 14 | Caso obligatorio "importación con errores parciales" | Pruebas 5.1 (`teams_con_errores.csv`), 5.2 (`players_con_errores.csv`), 5.3 (`worldcup_con_errores.json`) y 5.4 (`tarifas_con_errores.xml`) |
| 15 | Scripts de importación separados de los demás | Carpeta `src/entrega6/`, aparte de la Entrega 5 |

## Organización de los scripts

| Archivo | Orden | Contenido |
|---|---|---|
| `entrega6_importacion.sql` | 1° | Habilita `external rest endpoint enabled`; esquema `importacion` (lotes, errores, equivalencias de país); tablas de datos importados; vista `importacion.vw_ultimo_lote`; funciones `fn_pais_id` y `fn_seleccion_id`; datos de referencia (confederaciones y países); utilidades comunes (lectura CSV/JSON/XML y conversión de moneda); importadores de `teams.csv`, `players.csv`, `worldcup.json` y `tarifas_publicidad.xml` |
| `entrega6_scraping.sql` | 2° | Scraping de Wikipedia en T-SQL: sedes, selecciones y planteles |
| `entrega6_apis.sql` | 3° | Banco Mundial y Frankfurter |
| `entrega6_test.sql` | 4° | Pruebas, con el resultado esperado de cada una y un resumen final |

En `imports/`: `teams.csv` y `players.csv` (CSV de Kaggle, sin modificar), `worldcup.json` (JSON de openfootball con los 104 partidos y resultados), `tarifas_publicidad.xml` (XML del tarifario comercial en 9 monedas) y en `con_errores/` cuatro archivos con errores a propósito para las pruebas de importación parcial en cada dataset (`teams_con_errores.csv`, `players_con_errores.csv`, `worldcup_con_errores.json` y `tarifas_con_errores.xml`).

### Cómo ejecutarlos

1. Recrear la base con los tres scripts de creación de la Entrega 5 (`entrega5_db_definition.sql`,
   `entrega5_sp_ABM.sql`, `entrega5_sp_logica_negocio.sql`).
2. Copiar `imports\` a una carpeta que pueda leer la cuenta del servicio de SQL Server (por defecto
   `C:\mundial2026\imports\`; `C:\` y sus subcarpetas lo permiten). Si es otra, cambiarla en el
   `sp_set_session_context` del comienzo de `entrega6_test.sql`.
3. Ejecutar en SSMS en orden: `entrega6_importacion.sql`, `entrega6_scraping.sql`, `entrega6_apis.sql` y
   `entrega6_test.sql`.
4. El resumen final debe mostrar todas las pruebas en `OK`.

Requisitos: SQL Server 2025 (17.x), por `sp_invoke_external_rest_endpoint`, `REGEXP_SUBSTR` y `STRING_SPLIT`
con ordinal; conexión a internet; un login `sysadmin` la primera vez (habilita la opción de servidor y usa
`BULK INSERT`).

### Defensa en vivo

```sql
EXEC publicidad.consultar_api_frankfurter;             -- tipos de cambio (necesarios antes de tarifas XML)
EXEC torneo.consultar_api_banco_mundial;               -- PBI per cápita
EXEC torneo.scrapear_sedes;                            -- descarga y procesa Wikipedia en el momento
EXEC torneo.scrapear_selecciones;
EXEC plantel.scrapear_planteles;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 'C:\mundial2026\imports\teams.csv';
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 'C:\mundial2026\imports\players.csv';
EXEC torneo.importar_fixture 'C:\mundial2026\imports\worldcup.json';
EXEC publicidad.importar_tarifas 'C:\mundial2026\imports\tarifas_publicidad.xml';
SELECT * FROM importacion.vw_ultimo_lote;              -- resultado de cada importación
SELECT * FROM importacion.error ORDER BY error_id DESC;
```

## Datasets y APIs

| Fuente | Formato | Importa | Destino en el modelo |
|---|---|---|---|
| Wikipedia, `https://en.wikipedia.org/wiki/2026_FIFA_World_Cup` (sección Venues) | JSON (wikitext) | `torneo.scrapear_sedes` | `torneo.sede` |
| Wikipedia, `https://en.wikipedia.org/wiki/2026_FIFA_World_Cup` (Qualification y Tournament ranking) + `https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_squads` (grupos) | JSON (wikitext) | `torneo.scrapear_selecciones` | `torneo.seleccion`, `torneo.seleccion_estadistica` |
| Wikipedia, `https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_squads` | JSON (wikitext) | `plantel.scrapear_planteles` | `plantel.jugador`, `plantel.convocatoria`, `plantel.cuerpo_tecnico` |
| Kaggle (`https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-matches`, `teams.csv`) | CSV | `torneo.importar_estadisticas_equipos_kaggle_2026` | `torneo.seleccion_estadistica_kaggle`, vinculada a `torneo.seleccion` |
| Kaggle (`https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-players`, `players.csv`) | CSV | `plantel.importar_estadisticas_jugadores_kaggle_2026` | `plantel.jugador_estadistica_kaggle`, vinculada a selección y jugador |
| openfootball (`https://github.com/openfootball/worldcup.json`, `worldcup.json`) | JSON | `torneo.importar_fixture` | `torneo.partido` (104 partidos y resultados con alargue y penales) |
| Tarifario comercial (`https://dossiermundial.netlify.app/`, `tarifas_publicidad.xml`) | XML | `publicidad.importar_tarifas` | `publicidad.anunciante`, `publicidad.campania`, `publicidad.campania_pais_interes`, `publicidad.pieza_publicitaria` (en USD) |
| API Banco Mundial (`https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD`) | JSON | `torneo.consultar_api_banco_mundial` | `torneo.indicador_economico`, `torneo.pais.pbi_per_capita` |
| API Frankfurter (`https://api.frankfurter.dev/v1`) | JSON | `publicidad.consultar_api_frankfurter` | `publicidad.tipo_cambio` |

Cómo se complementan los datasets CSV de Kaggle (`teams.csv` y `players.csv`) con el scraping de Wikipedia:
el TP exige al menos un dataset obtenido por scraping web y usar los SP de la Entrega 5. Como los CSV de Kaggle no traen
la confederación ni el grupo de las selecciones, ni el dorsal o la fecha de nacimiento exacta de los jugadores (y su
fuente original, FBref, bloquea el scraping automatizado con 403 de Cloudflare), las sedes, las selecciones (con grupo,
confederación y tabla de posiciones final) y los planteles completos se obtienen mediante scraping en vivo de Wikipedia
dando de alta en el modelo con los SP de la Entrega 5. Sobre esas selecciones y jugadores ya registrados, `teams.csv` y
`players.csv` aportan las estadísticas detalladas de juego (posesión, tiros, faltas, atajadas, minutos, goles y
tarjetas) vinculadas por clave foránea a `torneo.seleccion` y `plantel.jugador` (1185 de 1248).

Límites de uso:

- **API de MediaWiki** (`en.wikipedia.org/w/api.php`): sin clave. Pide un User-Agent identificable y no
  hacer pedidos en paralelo; cada scraping hace una o dos llamadas.
- **Banco Mundial** (`api.worldbank.org/v2`): sin clave ni límite publicado; respuestas paginadas
  (`per_page` hasta 20000). Publica por país soberano: no hay datos de Inglaterra y Escocia por separado.
- **Frankfurter**: sin clave ni límite publicado. Cotizaciones del Banco Central Europeo, sólo días hábiles
  y unas 30 monedas (no cotiza el peso argentino).
- Las tres se consumen desde T-SQL con `sp_invoke_external_rest_endpoint`, que exige la opción de servidor
  `external rest endpoint enabled` y sólo admite HTTPS.

## Técnica de scraping

Todo en T-SQL. `importacion.obtener_wikitext` pide a la API de MediaWiki el texto fuente de la página
(`action=parse&prop=wikitext`), que llega dentro de un JSON. El texto se parte en líneas con `STRING_SPLIT`, se
ubica cada sección por su encabezado (`==Venues==`, `===Tournament ranking===`, `==Group A==`,
`===Argentina===`) y de cada línea se extraen los campos con `REGEXP_SUBSTR`:

- **Sedes:** cada fila de la tabla de estadios empieza con `! ... {{#invoke:flag|icon|MEX}} [[Mexico City]]`;
  la línea siguiente es el estadio y la tercera, la capacidad. La tabla no informa el huso: se calcula con
  `AT TIME ZONE` (zonas horarias de Windows) para el 15/06/2026, según la zona de cada ciudad.
- **Selecciones:** la confederación sale de la sección de clasificados (`'''[[...|AFC]]'''` seguido de
  `* {{#invoke:flag|fb|AUS}}`). La tabla final sale de `|team_order=ESP, ARG, ...`, `|pos_MAR={{=}}7` (puestos
  compartidos) y `|win_ARG=7 |draw_ARG=0 |loss_ARG=1 |gf_ARG=19|ga_ARG=8`. El grupo, de la página de planteles.
- **Planteles:** una plantilla por jugador, `{{nat fs g player|no=1|pos=GK|name=[[Matěj Kovář]]|sortname=Kovar,
  Matej|age={{birth date and age2|...|2000|5|17}}|club=[[PSV Eindhoven]]|...}}`, y una línea `Coach: [[...]]`
  por selección.

Las selecciones aparecen con su código FIFA (`GER`, `NED`, `KSA`) o con su nombre en inglés;
`importacion.fn_pais_id` los traduce con `importacion.pais_equivalencia`.

Cada `scrapear_*` abre el lote en `importacion.lote`, descarga la página en vivo con `importacion.obtener_wikitext` y
procesa los registros en el mismo SP; si la página no existe o no trae la sección esperada, el lote queda registrado
como `rechazado` (`THROW 50003`).

## Norma común de los importadores

- **Lote.** Cada ejecución abre una fila en `importacion.lote` (proceso, archivo o URL, fecha) y la cierra con
  leídos / insertados / actualizados / sin cambios / rechazados y un estado: `completo`, `parcial` o `rechazado`.
- **Origen inválido.** Archivo que no se puede leer, página inexistente o texto sin la estructura esperada: se
  registra el error, el lote queda `rechazado` y se lanza `THROW 50003`.
- **Fila.** Se valida (todas las faltas juntas, en un único `THROW 50004`, igual que en la Entrega 5) y se procesa
  en su propia transacción. Si algo falla, incluido un rechazo de un SP de la Entrega 5, se deshace sólo esa fila
  y se registra en `importacion.error`. La importación sigue con la siguiente.
- **Upsert.** Se busca la fila por su clave natural: si no existe, `_insertar`; si existe y cambió, `_modificar`;
  si está igual no se toca. Para las tablas de estadísticas el cambio se detecta con `EXCEPT`.
- **SQL dinámico.** Sólo para `BULK INSERT`, que no acepta la ruta en una variable.
- **Sin cursores.** Las filas se recorren con `WHILE` sobre una tabla temporal numerada, como en la Entrega 5.

| Proceso | Clave natural |
|---|---|
| Sedes | estadio + ciudad |
| Selecciones | país |
| Jugadores | nombre + apellido + fecha de nacimiento |
| Convocatoria | selección + jugador, vigente |
| Director técnico | selección + rol |
| Estadísticas de equipos (Kaggle) | selección (`team_country`) |
| Estadísticas de jugadores (Kaggle) | país + nombre del jugador |
| Fixture y resultados (`worldcup.json`) | fase + selección local + selección visitante |
| Tarifario publicitario (`tarifas_publicidad.xml`) | campaña + idioma + país mercado |
| PBI | país + indicador + año |
| Tipo de cambio | fecha + moneda base + moneda cotizada |

## Decisiones de diseño a documentar y defender

1. **Países de referencia.** Ninguna fuente trae juntos el código ISO, el nombre en castellano y el huso, y sin
   huso no se puede dar de alta un país. `importacion.cargar_datos_referencia` carga los 48 países con los SP de
   la Entrega 5. El huso es el de la capital durante el torneo; Irán (UTC+03:30) queda como UTC+03 porque el
   modelo admite sólo horas enteras. Inglaterra y Escocia usan sus códigos FIFA (`ENG`, `SCO`).
2. **Nombre y apellido:** el apellido son las últimas tantas palabras del nombre completo como palabras tenga la
   parte anterior a la coma de `sortname` ("De Paul, Rodrigo" → apellido "De Paul"). Sin nombre de pila
   (ej. "Casemiro"), van iguales.
3. **Lista completa e historial.** La página trae la lista completa de cada selección: los convocados vigentes
   que ya no figuran se dan de baja con fecha y motivo (la fila queda). Las bajas se procesan antes que las altas
   (para liberar cupo y dorsal) y sólo en selecciones sin filas mal formadas.
4. **Tabla final:** los partidos definidos por penales cuentan como empate (convención de la página) y los puntos
   se calculan (3 por victoria, 1 por empate).
5. **Texto en `VARCHAR`.** Los caracteres que no existen en Latin-1 se aproximan al convertir
   ("Matěj Kovář" → "Matej Kovár").
6. **Tablas nuevas.** Además de `torneo.parametro` (Entrega 5): `importacion.lote`, `importacion.error`,
   `importacion.pais_equivalencia`, `torneo.indicador_economico`, `publicidad.tipo_cambio`,
   `torneo.seleccion_estadistica`, `torneo.seleccion_estadistica_kaggle` y `plantel.jugador_estadistica_kaggle`.
   Conviene sumarlas al DER.

## Cambios respecto del boceto anterior (`HEAD` — `branch_eksztein`)

- Se conserva la estructura original de tres archivos de creación (`entrega6_importacion.sql`,
  `entrega6_scraping.sql`, `entrega6_apis.sql`) y se agrega por separado el script de pruebas (`entrega6_test.sql`,
  exigido por las pautas generales del TP).
- Se conservan los dos datasets CSV de `imports/` (`teams.csv` y `players.csv` de Kaggle), agregando el importador
  `torneo.importar_estadisticas_equipos_kaggle_2026` para `teams.csv` (que no tenía SP en el commit anterior) junto con
  `plantel.importar_estadisticas_jugadores_kaggle_2026` para `players.csv`, vinculando ambos con `torneo.seleccion` y
  `plantel.jugador`, registrando lote/errores y evitando `UPDATE` innecesarios cuando no hay cambios.
- Las sedes, selecciones (con grupo, confederación y tabla final) y planteles completos se obtienen mediante **scraping
  en vivo desde Wikipedia en T-SQL** (formato JSON/wikitext devuelto por la API de MediaWiki), dando de alta y
  modificando en las tablas del modelo a través de los SP de ABM de la Entrega 5.
- El scraping pasa a hacerse completo en T-SQL (`sp_invoke_external_rest_endpoint` + `REGEXP_SUBSTR`): el boceto de
  `entrega6_scraping.sql` sólo definía `torneo.importar_sedes_scraping` recibiendo `@datos_json` ya armado por
  parámetro y dejaba la descarga y el parseo afuera del motor.
- Un único esquema `importacion` con una tabla de lotes (`importacion.lote`) y una de errores (`importacion.error`),
  en lugar de tres esquemas (`apis`, `scraping` e `importacion`) con tres tablas de error distintas y sin registro
  de lotes.
- Frankfurter se consulta en base USD y con fecha opcional; en Banco Mundial, importar un año histórico anterior ya
  no pisa `torneo.pais.pbi_per_capita` si existe un año más reciente cargado.
- Números de error unificados (50003 para origen inválido, 50004 con validación agrupada por fila) en lugar de un
  código distinto por condición individual.

## Testing

`entrega6_test.sql` necesita la base recién creada (si ya tiene selecciones, avisa y no ejecuta nada).

| Parte | Pruebas |
|---|---|
| 1. APIs | 1.1 Frankfurter del día (base USD); 1.2 Frankfurter histórico por fecha (`2025-06-11`); 1.3 PBI per cápita 2020-2025; 1.4 serie histórica 2015-2019 sin pisar el PBI vigente |
| 2. Scraping | 2.1 sedes (16, 3 países, 4 husos); 2.2 selecciones (48 en 12 grupos, con tabla final); 2.3 planteles (26 convocados y DT por selección) |
| 3. Archivos (CSV, JSON, XML) | 3.1 `teams.csv`: 48 filas vinculadas a su selección; 3.2 `players.csv`: 1248 filas vinculadas a su selección y 1185 a su jugador; 3.3 `worldcup.json`: 104 partidos finalizados; 3.4 `tarifas_publicidad.xml`: 30 piezas convertidas a USD con las tasas reales de Frankfurter |
| 4. Reimportación | 4.1 se repiten los 7 procesos (3 de scraping + 4 de archivos): ningún alta ni cambio, mismas filas |
| 5. Errores | 5.1 `teams_con_errores.csv` (parcial CSV de equipos); 5.2 `players_con_errores.csv` (parcial CSV de jugadores); 5.3 `worldcup_con_errores.json` (parcial JSON, partido finalizado no se reescribe); 5.4 `tarifas_con_errores.xml` (parcial XML y validación 50001 de Entrega 5); 5.5 archivo inexistente; 5.6 página de Wikipedia inexistente y página sin planteles |

Resultado verificado el 23/10/2026 en SQL Server 2025 Express (Windows 11), en SSMS: 18 pruebas en `OK`.

## Pendientes

- **Numerar los archivos** con dos dígitos y armar la **solución de SSMS**, igual que en la Entrega 5.
- **Sumar las tablas nuevas al DER.**
