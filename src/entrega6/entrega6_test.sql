-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 6: Procesos de importación - LOTES DE PRUEBA
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Pruebas de entrega6_importacion.sql, entrega6_scraping.sql y entrega6_apis.sql:
--     PARTE 1: APIs (tipos de cambio y PBI per cápita, vigentes e históricos).
--     PARTE 2: scraping de Wikipedia en vivo (sedes, selecciones y planteles).
--     PARTE 3: datasets en archivos CSV (teams.csv, players.csv), JSON (worldcup.json) y
--              XML (tarifas_publicidad.xml, con conversión de moneda a USD).
--     PARTE 4: reimportación: no genera duplicados.
--     PARTE 5: importación con errores parciales desde archivos (CSV, JSON y XML) y
--              orígenes rechazados.
--   Cada prueba indica en un comentario "Resultado esperado". Al final se lista un
--   resumen: todas las pruebas deben figurar con resultado OK.
--
-- CÓMO EJECUTARLO:
--   1) Recrear la base con los scripts de creación de la Entrega 5 y ejecutar en orden:
--      entrega6_importacion.sql, entrega6_scraping.sql y entrega6_apis.sql.
--   2) Copiar la carpeta imports\ del repositorio a una carpeta que pueda leer el servicio
--      de SQL Server (por defecto C:\mundial2026\imports\) y ajustar el
--      sp_set_session_context de abajo si es otra.
--   3) Ejecutar este script completo, de una vez y en la misma ventana de consulta.
--   Requiere conexión a internet (APIs y Wikipedia).
-- =======================================================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

-- Carpeta de los archivos a importar, vista desde el servidor (con la barra final).
EXEC sp_set_session_context N'dir_importacion', N'C:\mundial2026\imports\';
GO

-- El script necesita la base recién creada, sin datos importados.

IF OBJECT_ID('importacion.lote', 'U') IS NULL OR EXISTS (SELECT 1 FROM torneo.seleccion)
BEGIN
    RAISERROR('Ejecutar primero los scripts de creación de las entregas 5 y 6 sobre una base recién creada. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10), descripcion VARCHAR(120),
                         resultado VARCHAR(5), detalle VARCHAR(2100));
GO

PRINT '################ PARTE 1: APIs ################';
GO

PRINT '--- 1.1 Frankfurter: cotizaciones del día (base USD)';
-- Resultado esperado: lote completo con más de 20 monedas cotizadas contra el dólar.
EXEC publicidad.consultar_api_frankfurter;
INSERT INTO #resultado SELECT '1.1', 'frankfurter: cotizaciones del día',
       IIF(estado = 'completo' AND insertados > 20, 'OK', 'FALLO'), CONCAT(insertados, ' cotizaciones')
FROM importacion.vw_ultimo_lote WHERE proceso = 'publicidad.consultar_api_frankfurter';
GO

PRINT '--- 1.2 Frankfurter: cotizaciones históricas por fecha (11/06/2025)';
-- Resultado esperado: se agregan las cotizaciones históricas del 11/06/2025 sin pisar las del día: quedan dos fechas.
EXEC publicidad.consultar_api_frankfurter @fecha = '2025-06-11';
SELECT fecha, COUNT(*) AS monedas FROM publicidad.tipo_cambio GROUP BY fecha ORDER BY fecha;
INSERT INTO #resultado SELECT '1.2', 'frankfurter: histórico por fecha sin pisar las del día',
       IIF(COUNT(DISTINCT fecha) = 2 AND SUM(IIF(fecha = '2025-06-11', 1, 0)) > 20, 'OK', 'FALLO'),
       CONCAT(COUNT(DISTINCT fecha), ' fechas registradas')
FROM publicidad.tipo_cambio;
GO

PRINT '--- 1.3 Banco Mundial: PBI per cápita 2020-2025';
-- Resultado esperado: indicadores de varios años por país, y el más reciente copiado a torneo.pais (todos
-- los países salvo Inglaterra y Escocia, que el Banco Mundial no publica por separado).
EXEC torneo.consultar_api_banco_mundial;
SELECT TOP 10 codigo_iso, nombre, pbi_per_capita FROM torneo.pais ORDER BY pbi_per_capita DESC;
INSERT INTO #resultado SELECT '1.3', 'banco mundial: PBI per cápita 2020-2025',
       IIF(estado = 'completo' AND (SELECT COUNT(*) FROM torneo.pais WHERE pbi_per_capita > 0) >= 44
           AND (SELECT COUNT(DISTINCT anio) FROM torneo.indicador_economico) >= 3, 'OK', 'FALLO'),
       CONCAT((SELECT COUNT(*) FROM torneo.pais WHERE pbi_per_capita > 0), ' países con PBI')
FROM importacion.vw_ultimo_lote WHERE proceso = 'torneo.consultar_api_banco_mundial';
GO

PRINT '--- 1.4 Banco Mundial: serie histórica anterior (2015-2019)';
-- Resultado esperado: se importan desde la API los años 2015-2019 en torneo.indicador_economico sin pisar
-- el PBI vigente (más reciente) ya registrado en torneo.pais.
DECLARE @pbi_arg NUMERIC(12,2) = (SELECT pbi_per_capita FROM torneo.pais WHERE codigo_iso = 'ARG');
EXEC torneo.consultar_api_banco_mundial @anio_desde = 2015, @anio_hasta = 2019;
INSERT INTO #resultado SELECT '1.4', 'banco mundial: histórico 2015-2019 sin pisar el vigente',
       IIF(l.estado = 'completo' AND l.insertados >= 200
           AND (SELECT pbi_per_capita FROM torneo.pais WHERE codigo_iso = 'ARG') = @pbi_arg
           AND EXISTS (SELECT 1 FROM torneo.indicador_economico i JOIN torneo.pais p ON p.pais_id = i.pais_id
                       WHERE p.codigo_iso = 'ARG' AND i.anio = 2015), 'OK', 'FALLO'),
       CONCAT(l.insertados, ' indicadores históricos')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.consultar_api_banco_mundial';
GO

PRINT '################ PARTE 2: SCRAPING DE WIKIPEDIA ################';
GO

PRINT '--- 2.1 Sedes';
-- Resultado esperado: las 16 sedes del torneo en 3 países, con 4 husos horarios distintos.
EXEC torneo.scrapear_sedes;
SELECT s.nombre, s.ciudad, p.codigo_iso, s.capacidad, s.huso_horario FROM torneo.sede s
JOIN torneo.pais p ON p.pais_id = s.pais_id ORDER BY s.huso_horario, s.ciudad;
INSERT INTO #resultado SELECT '2.1', 'sedes: 16 sedes, 3 países, 4 husos',
       IIF(l.estado = 'completo' AND (SELECT COUNT(*) FROM torneo.sede) = 16
           AND (SELECT COUNT(DISTINCT pais_id) FROM torneo.sede) = 3
           AND (SELECT COUNT(DISTINCT huso_horario) FROM torneo.sede) = 4, 'OK', 'FALLO'),
       CONCAT(l.insertados, ' sedes')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.scrapear_sedes';
GO

PRINT '--- 2.2 Selecciones (teams)';
-- Resultado esperado: 48 selecciones en 12 grupos de 4 y 6 confederaciones, con su tabla final:
-- España primera con 22 puntos (7 ganados, 1 empate).
EXEC torneo.scrapear_selecciones;
SELECT e.posicion_final, p.nombre, s.grupo, c.nombre AS confederacion, e.partidos, e.ganados, e.empatados,
       e.perdidos, e.goles_a_favor, e.goles_en_contra, e.puntos
FROM torneo.seleccion_estadistica e JOIN torneo.seleccion s ON s.seleccion_id = e.seleccion_id
JOIN torneo.pais p ON p.pais_id = s.pais_id JOIN torneo.confederacion c ON c.confederacion_id = s.confederacion_id
ORDER BY e.posicion_final, p.nombre;
INSERT INTO #resultado SELECT '2.2', 'selecciones: 48 en 12 grupos, con tabla final',
       IIF(l.estado = 'completo' AND (SELECT COUNT(*) FROM torneo.seleccion) = 48
           AND NOT EXISTS (SELECT 1 FROM torneo.seleccion GROUP BY grupo HAVING COUNT(*) <> 4)
           AND (SELECT COUNT(DISTINCT confederacion_id) FROM torneo.seleccion) = 6
           AND (SELECT COUNT(*) FROM torneo.seleccion_estadistica) = 48
           AND EXISTS (SELECT 1 FROM torneo.seleccion_estadistica WHERE seleccion_id = importacion.fn_seleccion_id('ESP')
                       AND posicion_final = 1 AND puntos = 22), 'OK', 'FALLO'),
       CONCAT(l.insertados, ' selecciones')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.scrapear_selecciones';
GO

PRINT '--- 2.3 Planteles';
-- Resultado esperado: 26 convocados vigentes (mínimo exigido: 23) y el director técnico de cada selección.
EXEC plantel.scrapear_planteles;
SELECT TOP 27 c.dorsal, j.nombre, j.apellido, j.posicion_habitual, j.fecha_nacimiento, j.club_origen
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = importacion.fn_seleccion_id('ARG') ORDER BY c.dorsal;
INSERT INTO #resultado SELECT '2.3', 'planteles: 23+ convocados y DT en cada selección',
       IIF(l.estado = 'completo'
           AND NOT EXISTS (SELECT 1 FROM torneo.seleccion s
                           WHERE (SELECT COUNT(*) FROM plantel.convocatoria c WHERE c.seleccion_id = s.seleccion_id AND c.fecha_baja IS NULL) < 23
                              OR NOT EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico ct WHERE ct.seleccion_id = s.seleccion_id AND ct.rol = 'director_tecnico')),
           'OK', 'FALLO'),
       CONCAT(l.insertados, ' insertados, ', l.rechazados, ' rechazados')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.scrapear_planteles';
GO

PRINT '################ PARTE 3: DATASETS EN ARCHIVOS (CSV, JSON Y XML) ################';
GO

PRINT '--- 3.1 Estadísticas de equipos (teams.csv, CSV)';
-- Resultado esperado: las 48 filas de teams.csv vinculadas a su selección del modelo.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'teams.csv';
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
SELECT TOP 10 k.pais_equipo, k.posesion, k.tiros, k.tiros_al_arco, k.amarillas, k.rojas, k.atajadas
FROM torneo.seleccion_estadistica_kaggle k ORDER BY k.goles DESC;
INSERT INTO #resultado SELECT '3.1', 'kaggle teams.csv: 48 selecciones vinculadas',
       IIF(l.estado = 'completo' AND l.insertados = 48
           AND (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle) = 48, 'OK', 'FALLO'),
       CONCAT(l.insertados, ' selecciones')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026';
GO

PRINT '--- 3.2 Estadísticas de jugadores (players.csv, CSV)';
-- Resultado esperado: las 1248 filas, todas vinculadas a su selección y la gran mayoría a su jugador
-- (las que no coinciden por nombre, ej. 'Flaco López', quedan vinculadas sólo a la selección).
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'players.csv';
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
SELECT TOP 10 k.jugador, k.pais_equipo, k.goles, k.asistencias, k.minutos, j.fecha_nacimiento
FROM plantel.jugador_estadistica_kaggle k LEFT JOIN plantel.jugador j ON j.jugador_id = k.jugador_id
ORDER BY k.goles DESC;
INSERT INTO #resultado SELECT '3.2', 'kaggle players.csv: estadísticas vinculadas al modelo',
       IIF(l.estado = 'completo' AND l.insertados = 1248
           AND (SELECT COUNT(jugador_id) FROM plantel.jugador_estadistica_kaggle) >= 1100, 'OK', 'FALLO'),
       CONCAT((SELECT COUNT(jugador_id) FROM plantel.jugador_estadistica_kaggle), ' de 1248 vinculadas a un jugador')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
GO

PRINT '--- 3.3 Fixture y resultados (worldcup.json, JSON)';
-- Resultado esperado: los 104 partidos del torneo finalizados con su resultado (alargue y penales incluidos);
-- la final, España 1 - Argentina 0.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'worldcup.json';
EXEC torneo.importar_fixture @ruta;
SELECT fase, COUNT(*) AS partidos, SUM(IIF(estado = 'finalizado', 1, 0)) AS finalizados,
       SUM(IIF(penales_local IS NOT NULL, 1, 0)) AS por_penales
FROM torneo.partido GROUP BY fase ORDER BY MIN(fecha_hora_utc);
INSERT INTO #resultado SELECT '3.3', 'fixture worldcup.json: 104 partidos finalizados',
       IIF(l.estado = 'completo' AND l.insertados = 104
           AND (SELECT COUNT(*) FROM torneo.partido WHERE estado = 'finalizado') = 104
           AND EXISTS (SELECT 1 FROM torneo.partido p JOIN torneo.seleccion s ON s.seleccion_id = p.seleccion_local_id
                       JOIN torneo.pais x ON x.pais_id = s.pais_id
                       WHERE p.fase = 'final' AND x.codigo_iso = 'ESP' AND p.goles_local = 1 AND p.goles_visitante = 0),
           'OK', 'FALLO'),
       CONCAT(l.insertados, ' partidos')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_fixture';
GO

PRINT '--- 3.4 Tarifario publicitario (tarifas_publicidad.xml, XML con conversión de monedas a USD)';
-- Resultado esperado: 30 piezas publicitarias convertidas a USD con las cotizaciones de publicidad.tipo_cambio
-- importadas desde Frankfurter (ej. la pieza de Coca-Cola en España de 26000 EUR).
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'tarifas_publicidad.xml',
        @esperado NUMERIC(12,2);
EXEC publicidad.importar_tarifas @ruta;
SELECT TOP 1 @esperado = ROUND(26000 / tipo_cambio, 2)
FROM publicidad.tipo_cambio
WHERE moneda_base = 'USD' AND moneda_cotizada = 'EUR'
ORDER BY ABS(DATEDIFF(DAY, fecha, '2026-06-11')), fecha DESC;
SELECT a.nombre AS anunciante, c.nombre AS campania, pz.idioma, p.codigo_iso AS mercado, pz.costo_tarifa AS tarifa_usd
FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id JOIN torneo.pais p ON p.pais_id = pz.pais_mercado_id
ORDER BY a.nombre, p.codigo_iso;
INSERT INTO #resultado SELECT '3.4', 'tarifas XML: 30 piezas convertidas a USD',
       IIF(l.estado = 'completo' AND l.insertados = 30
           AND EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                       JOIN torneo.pais p ON p.pais_id = pz.pais_mercado_id
                       WHERE c.nombre = 'Conferencia' AND p.codigo_iso = 'ESP' AND pz.costo_tarifa = @esperado)
           AND EXISTS (SELECT 1 FROM publicidad.anunciante WHERE nombre = 'Emirates'), 'OK', 'FALLO'),
       CONCAT('30 piezas, ESP = USD ', @esperado)
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'publicidad.importar_tarifas';
GO

PRINT '################ PARTE 4: REIMPORTACIÓN SIN DUPLICADOS ################';
GO

PRINT '--- 4.1 Se importa todo de nuevo';
-- Resultado esperado: ningún alta ni cambio (todo "sin cambios") y las tablas con la misma cantidad de filas.
DECLARE @dir VARCHAR(200) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)),
        @ruta_teams VARCHAR(500), @ruta_players VARCHAR(500), @ruta_fixture VARCHAR(500), @ruta_tarifas VARCHAR(500),
        @antes VARCHAR(150), @despues VARCHAR(150), @primer_lote INT = (SELECT MAX(lote_id) + 1 FROM importacion.lote);
SELECT @ruta_teams = @dir + 'teams.csv', @ruta_players = @dir + 'players.csv',
       @ruta_fixture = @dir + 'worldcup.json', @ruta_tarifas = @dir + 'tarifas_publicidad.xml';
SET @antes = CONCAT((SELECT COUNT(*) FROM torneo.sede), '/', (SELECT COUNT(*) FROM torneo.seleccion), '/',
                    (SELECT COUNT(*) FROM plantel.jugador), '/', (SELECT COUNT(*) FROM plantel.convocatoria), '/',
                    (SELECT COUNT(*) FROM torneo.partido), '/', (SELECT COUNT(*) FROM publicidad.pieza_publicitaria), '/',
                    (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle), '/',
                    (SELECT COUNT(*) FROM plantel.jugador_estadistica_kaggle));
EXEC torneo.scrapear_sedes;
EXEC torneo.scrapear_selecciones;
EXEC plantel.scrapear_planteles;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta_teams;
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta_players;
EXEC torneo.importar_fixture @ruta_fixture;
EXEC publicidad.importar_tarifas @ruta_tarifas;
SET @despues = CONCAT((SELECT COUNT(*) FROM torneo.sede), '/', (SELECT COUNT(*) FROM torneo.seleccion), '/',
                      (SELECT COUNT(*) FROM plantel.jugador), '/', (SELECT COUNT(*) FROM plantel.convocatoria), '/',
                      (SELECT COUNT(*) FROM torneo.partido), '/', (SELECT COUNT(*) FROM publicidad.pieza_publicitaria), '/',
                      (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle), '/',
                      (SELECT COUNT(*) FROM plantel.jugador_estadistica_kaggle));
INSERT INTO #resultado SELECT '4.1', 'reimportación: sin altas, sin cambios, mismas filas',
       IIF(COUNT(*) = 7 AND SUM(insertados + actualizados + rechazados) = 0 AND @antes = @despues, 'OK', 'FALLO'),
       CONCAT('filas antes/después: ', @antes, ' -> ', @despues)
FROM importacion.lote WHERE lote_id >= @primer_lote;
GO

PRINT '################ PARTE 5: ERRORES PARCIALES Y RECHAZOS ################';
GO

PRINT '--- 5.1 teams_con_errores.csv (importación parcial CSV de selecciones)';
-- 5 filas: Argentina con 99 goles (se actualiza), España igual a la importada (sin cambios), un país vacío,
-- un dato numérico inválido con goles negativos y un país sin selección ('Atlantis').
-- Resultado esperado: 1 actualizada, 1 sin cambios, 3 rechazadas con su motivo.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'con_errores\teams_con_errores.csv';
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id
WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.1', 'kaggle teams CSV: importación parcial',
       IIF(l.estado = 'parcial' AND l.actualizados = 1 AND l.sin_cambios = 1 AND l.rechazados = 3
           AND (SELECT goles FROM torneo.seleccion_estadistica_kaggle WHERE pais_equipo = 'Argentina') = 99, 'OK', 'FALLO'), ''
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026';
GO

PRINT '--- 5.2 players_con_errores.csv (importación parcial CSV de jugadores)';
-- 5 filas: Messi con otros goles (se actualiza), una fila igual a la importada (sin cambios), un nombre vacío,
-- un dato numérico inválido y un país sin selección.
-- Resultado esperado: 1 actualizada, 1 sin cambios, 3 rechazadas con su motivo.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'con_errores\players_con_errores.csv';
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id
WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.2', 'kaggle players CSV: importación parcial',
       IIF(l.estado = 'parcial' AND l.actualizados = 1 AND l.sin_cambios = 1 AND l.rechazados = 3
           AND (SELECT goles FROM plantel.jugador_estadistica_kaggle WHERE jugador = 'Lionel Messi') = 99, 'OK', 'FALLO'), ''
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
GO

PRINT '--- 5.3 worldcup_con_errores.json (importación parcial JSON)';
-- 5 partidos: uno igual al registrado (sin cambios), el mismo con otro resultado (un partido finalizado no se
-- reescribe), una selección inexistente, hora y sede inválidas, y ronda/fecha inválidas.
-- Resultado esperado: 1 sin cambios, 4 rechazados; México - Sudáfrica sigue 2 a 0.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'con_errores\worldcup_con_errores.json';
EXEC torneo.importar_fixture @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id WHERE l.proceso = 'torneo.importar_fixture' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.3', 'fixture JSON: importación parcial, finalizado no se reescribe',
       IIF(l.estado = 'parcial' AND l.sin_cambios = 1 AND l.rechazados = 4
           AND EXISTS (SELECT 1 FROM torneo.partido p WHERE p.seleccion_local_id = importacion.fn_seleccion_id('MEX')
                       AND p.seleccion_visitante_id = importacion.fn_seleccion_id('ZAF') AND p.goles_local = 2 AND p.goles_visitante = 0),
           'OK', 'FALLO'), ''
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_fixture';
GO

PRINT '--- 5.4 tarifas_con_errores.xml (importación parcial XML)';
-- 5 piezas: ARS sin cotización, tarifa 'abc', mercado XXX, Brasil fuera de los países de interés (lo rechaza
-- publicidad.pieza_publicitaria_insertar, 50001) y una válida en EUR para Uruguay (convertida a USD).
-- Resultado esperado: 1 insertada, 4 rechazadas con su motivo.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'con_errores\tarifas_con_errores.xml';
EXEC publicidad.importar_tarifas @ruta;
SELECT e.fila, e.registro, e.numero_error, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id WHERE l.proceso = 'publicidad.importar_tarifas' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.4', 'tarifas XML: importación parcial y validación Entrega 5',
       IIF(l.estado = 'parcial' AND l.insertados = 1 AND l.rechazados = 4
           AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.motivo LIKE '%ARS%')
           AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.numero_error = 50001), 'OK', 'FALLO'), ''
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'publicidad.importar_tarifas';
GO

PRINT '--- 5.5 Archivo inexistente';
-- Resultado esperado: THROW 50003 con la ruta en el mensaje; el lote queda rechazado y con su error.
DECLARE @ruta VARCHAR(500) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)) + 'no_existe.csv';
BEGIN TRY
    EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
    INSERT INTO #resultado VALUES ('5.5', 'archivo inexistente', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado SELECT '5.5', 'archivo inexistente',
           IIF(ERROR_NUMBER() = 50003 AND l.estado = 'rechazado'
               AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.fila IS NULL), 'OK', 'FALLO'),
           ERROR_MESSAGE()
    FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
END CATCH;
GO

PRINT '--- 5.6 Página inexistente y página sin planteles';
-- Resultado esperado: THROW 50003 en los dos casos; no se procesa ninguna fila y el lote queda rechazado.
DECLARE @mensaje VARCHAR(2100), @ok BIT = 0;
BEGIN TRY
    EXEC plantel.scrapear_planteles N'Pagina_que_no_existe_TP_Mundial_2026';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    SELECT @ok = IIF(ERROR_NUMBER() = 50003, 1, 0), @mensaje = ERROR_MESSAGE();
END CATCH;
BEGIN TRY
    EXEC plantel.scrapear_planteles N'FIFA';
    SET @ok = 0;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    SET @ok = IIF(@ok = 1 AND ERROR_NUMBER() = 50003, 1, 0);
END CATCH;
INSERT INTO #resultado SELECT '5.6', 'página inexistente y página sin planteles',
       IIF(@ok = 1 AND l.estado = 'rechazado' AND l.leidos = 0, 'OK', 'FALLO'), @mensaje
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.scrapear_planteles';
GO

-- ============================================================
-- TRAZABILIDAD Y RESUMEN
-- ============================================================

PRINT '################ TRAZABILIDAD ################';
-- Todos los lotes ejecutados, con sus contadores.
SELECT lote_id, proceso, origen, leidos, insertados, actualizados, sin_cambios, rechazados, estado
FROM importacion.lote ORDER BY lote_id;
GO

PRINT '################ RESUMEN ################';
-- Resultado esperado: todas las pruebas en OK y ninguna en FALLO.
SELECT resultado, COUNT(*) AS pruebas FROM #resultado GROUP BY resultado;
SELECT orden, prueba, descripcion, resultado, detalle FROM #resultado ORDER BY orden;
IF EXISTS (SELECT 1 FROM #resultado WHERE resultado <> 'OK')
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, descripcion, detalle FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE
    PRINT 'Todas las pruebas finalizaron con el resultado esperado.';
GO

SET NOEXEC OFF;
GO
