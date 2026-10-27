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
--   Pruebas de entrega6_importacion.sql y entrega6_apis.sql:
--     PARTE 1: APIs (tipos de cambio y PBI per cápita, vigentes e históricos).
--     PARTE 2: datos obtenidos por scraping de Wikipedia (imports/scraping/*.json, que genera
--              entrega6_scraping.py): sedes, selecciones y planteles.
--     PARTE 3: datasets de imports/datasets/ en archivos CSV (teams.csv, players.csv), JSON (worldcup.json) y
--              XML (tarifas_publicidad.xml, con conversión de moneda a USD).
--     PARTE 4: reimportación: no genera duplicados (una prueba por proceso).
--     PARTE 5: importación con errores parciales (CSV, JSON y XML) y orígenes rechazados.
--
-- IDENTIFICACIÓN DE LOS LOTES:
--   Cada prueba es un lote encabezado por un bloque de comentario "PRUEBA <id> - <qué prueba>"
--   (las partes, por uno "PARTE n"), que empieza con PRINT '--- <id> <descripción>', seguido de
--   "-- Resultado esperado" y "-- Requiere", e informa OK o FALLO en Mensajes.
--     Lote 0    preparación de la sesión: carpeta de los archivos, tabla #resultado y
--               procedimientos #ruta, #preparar e #informar
--     1.1-1.4   APIs                       2.1-2.3   scraping (archivos JSON)
--     3.1-3.4   archivos CSV, JSON y XML   4.1-4.7   reimportación de cada proceso
--     5.1-5.7   errores parciales y orígenes rechazados
--     RESUMEN   lotes ejecutados y resultado de todas las pruebas
--
-- CÓMO EJECUTARLO:
--   1) Recrear la base con los scripts de creación de la Entrega 5 y ejecutar en orden:
--      entrega6_importacion.sql y entrega6_apis.sql.
--   2) Generar los archivos de scraping: python3 src/entrega6/entrega6_scraping.py
--      (escribe imports/scraping/sedes.json, selecciones.json y planteles.json).
--   3) Copiar la carpeta imports del repositorio (con imports/datasets/) a una carpeta que pueda leer
--      el servicio de SQL Server: por defecto C:\mundial2026\imports\ en Windows (/bbdd/imports/ en el
--      contenedor Linux de sqlserver-docker). Si es otra, ajustar el Lote 0.
--   4) Todo junto: ejecutar este script completo. Una prueba sola: ejecutar el Lote 0 y el
--      lote de la prueba (buscar su id con Ctrl+F), en la misma ventana. Cada lote importa
--      antes, si faltan, los datos que necesita (#preparar), y se puede repetir.
--   Requiere conexión a internet (APIs). Los conteos suponen la base sólo con datos importados.
-- =======================================================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

-- =====================================================================================
-- LOTE 0: PREPARACIÓN DE LA SESIÓN
-- =====================================================================================
PRINT '--- Lote 0: preparación de la sesión';
-- Ejecutar primero, en la misma ventana que el resto de los lotes. Se puede volver a ejecutar.
IF OBJECT_ID('importacion.lote', 'U') IS NULL OR OBJECT_ID('torneo.importar_sedes', 'P') IS NULL
   OR OBJECT_ID('torneo.consultar_api_banco_mundial', 'P') IS NULL
BEGIN
    RAISERROR('Ejecutar primero los scripts de creación de las entregas 5 y 6. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;

-- Carpeta de los archivos a importar, vista desde el servidor (con el separador final).
IF SESSION_CONTEXT(N'dir_importacion') IS NULL
BEGIN
    DECLARE @imports NVARCHAR(200) = IIF(@@VERSION LIKE '%Linux%', N'/bbdd/imports/', N'C:\mundial2026\imports\');
    EXEC sp_set_session_context N'dir_importacion', @imports;
END;
PRINT CONCAT('Carpeta de importación: ', CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200)));

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10) COLLATE DATABASE_DEFAULT,
                         descripcion VARCHAR(120) COLLATE DATABASE_DEFAULT, resultado VARCHAR(5) COLLATE DATABASE_DEFAULT,
                         detalle VARCHAR(2100) COLLATE DATABASE_DEFAULT);
GO

-- (Las variables de un procedimiento temporal usan la intercalación de tempdb: por eso los COLLATE.)
IF OBJECT_ID('tempdb..#ruta') IS NOT NULL DROP PROCEDURE #ruta;
GO
-- Ruta completa de un archivo de imports/, escrita con '/' (se adapta al separador de la carpeta).
-- Los datasets van en imports/datasets/ ('datasets/teams.csv'); los JSON de scraping, en imports/scraping/.
CREATE PROCEDURE #ruta
    @relativa VARCHAR(200),
    @ruta     VARCHAR(500) OUTPUT
AS
BEGIN
    DECLARE @dir VARCHAR(200) = CAST(SESSION_CONTEXT(N'dir_importacion') AS VARCHAR(200));
    SET @ruta = @dir COLLATE DATABASE_DEFAULT
              + REPLACE(@relativa COLLATE DATABASE_DEFAULT, '/', RIGHT(@dir COLLATE DATABASE_DEFAULT, 1));
END;
GO

IF OBJECT_ID('tempdb..#preparar') IS NOT NULL DROP PROCEDURE #preparar;
GO
-- Importa un requisito de una prueba sólo si todavía no está cargado (y antes, lo que él necesita).
CREATE PROCEDURE #preparar
    @que VARCHAR(20)
AS
BEGIN
    DECLARE @ruta VARCHAR(500), @q VARCHAR(20) = @que COLLATE DATABASE_DEFAULT;
    IF @q COLLATE DATABASE_DEFAULT = 'cambios' AND NOT EXISTS (SELECT 1 FROM publicidad.tipo_cambio)
        EXEC publicidad.consultar_api_frankfurter;
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'pbi' AND NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pbi_per_capita > 0)
        EXEC torneo.consultar_api_banco_mundial;
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'sedes' AND NOT EXISTS (SELECT 1 FROM torneo.sede)
    BEGIN
        EXEC #ruta 'scraping/sedes.json', @ruta OUTPUT;
        EXEC torneo.importar_sedes @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'selecciones' AND NOT EXISTS (SELECT 1 FROM torneo.seleccion)
    BEGIN
        EXEC #ruta 'scraping/selecciones.json', @ruta OUTPUT;
        EXEC torneo.importar_selecciones @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'planteles' AND NOT EXISTS (SELECT 1 FROM plantel.convocatoria)
    BEGIN
        EXEC #preparar 'selecciones';
        EXEC #ruta 'scraping/planteles.json', @ruta OUTPUT;
        EXEC plantel.importar_planteles @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'teams' AND NOT EXISTS (SELECT 1 FROM torneo.seleccion_estadistica_kaggle)
    BEGIN
        EXEC #preparar 'selecciones';
        EXEC #ruta 'datasets/teams.csv', @ruta OUTPUT;
        EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'players' AND NOT EXISTS (SELECT 1 FROM plantel.jugador_estadistica_kaggle)
    BEGIN
        EXEC #preparar 'planteles';
        EXEC #ruta 'datasets/players.csv', @ruta OUTPUT;
        EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'fixture' AND NOT EXISTS (SELECT 1 FROM torneo.partido)
    BEGIN
        EXEC #preparar 'sedes';
        EXEC #preparar 'selecciones';
        EXEC #ruta 'datasets/worldcup.json', @ruta OUTPUT;
        EXEC torneo.importar_fixture @ruta;
    END
    ELSE IF @q COLLATE DATABASE_DEFAULT = 'tarifas' AND NOT EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria)
    BEGIN
        EXEC #preparar 'cambios';
        EXEC #ruta 'datasets/tarifas_publicidad.xml', @ruta OUTPUT;
        EXEC publicidad.importar_tarifas @ruta;
    END;
END;
GO

IF OBJECT_ID('tempdb..#informar') IS NOT NULL DROP PROCEDURE #informar;
GO
-- Informa con OK o FALLO al comienzo de la línea el resultado que registró la prueba en #resultado.
CREATE PROCEDURE #informar
    @prueba VARCHAR(10)
AS
BEGIN
    DECLARE @linea VARCHAR(2500), @orden INT = 0;
    WHILE 1 = 1
    BEGIN
        SELECT TOP (1) @orden = orden,
               @linea = CONCAT(LEFT(resultado + '      ', 6), prueba, ' ', descripcion,
                               IIF(detalle = '', '', CHAR(13) + CHAR(10) + '      ' + detalle))
        FROM #resultado WHERE prueba = @prueba COLLATE DATABASE_DEFAULT AND orden > @orden ORDER BY orden;
        IF @@ROWCOUNT = 0 BREAK;
        PRINT @linea;
    END;
    IF NOT EXISTS (SELECT 1 FROM #resultado WHERE prueba = @prueba COLLATE DATABASE_DEFAULT)
        PRINT CONCAT('FALLO ', @prueba COLLATE DATABASE_DEFAULT, ' no registró ningún resultado');
END;
GO

-- =====================================================================================
-- PARTE 1: APIs
-- =====================================================================================
PRINT '################ PARTE 1: APIs ################';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 1.1 - Frankfurter: cotizaciones del día (base USD)
-- -------------------------------------------------------------------------------------
PRINT '--- 1.1 Frankfurter: cotizaciones del día (base USD)';
-- Resultado esperado: lote completo con más de 20 monedas cotizadas contra el dólar (nuevas o ya registradas hoy).
-- Requiere: Lote 0.
EXEC publicidad.consultar_api_frankfurter;
INSERT INTO #resultado SELECT '1.1', 'frankfurter: cotizaciones del día',
       IIF(estado = 'completo' AND insertados + actualizados + sin_cambios > 20, 'OK', 'FALLO'),
       CONCAT(insertados + actualizados + sin_cambios, ' cotizaciones')
FROM importacion.vw_ultimo_lote WHERE proceso = 'publicidad.consultar_api_frankfurter';
EXEC #informar '1.1';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 1.2 - Frankfurter: cotizaciones históricas por fecha (11/06/2025)
-- -------------------------------------------------------------------------------------
PRINT '--- 1.2 Frankfurter: cotizaciones históricas por fecha (11/06/2025)';
-- Resultado esperado: las cotizaciones del 11/06/2025 se agregan sin pisar las de otras fechas.
-- Requiere: Lote 0 (si no hay cotizaciones del día, las importa antes).
EXEC #preparar 'cambios';
EXEC publicidad.consultar_api_frankfurter @fecha = '2025-06-11';
SELECT fecha, COUNT(*) AS monedas FROM publicidad.tipo_cambio GROUP BY fecha ORDER BY fecha;
INSERT INTO #resultado SELECT '1.2', 'frankfurter: histórico por fecha sin pisar otras fechas',
       IIF(COUNT(DISTINCT fecha) >= 2 AND SUM(IIF(fecha = '2025-06-11', 1, 0)) > 20, 'OK', 'FALLO'),
       CONCAT(COUNT(DISTINCT fecha), ' fechas registradas')
FROM publicidad.tipo_cambio;
EXEC #informar '1.2';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 1.3 - Banco Mundial: PBI per cápita 2020-2025
-- -------------------------------------------------------------------------------------
PRINT '--- 1.3 Banco Mundial: PBI per cápita 2020-2025';
-- Resultado esperado: indicadores de varios años por país, y el más reciente copiado a torneo.pais (todos
-- los países salvo Inglaterra y Escocia, que el Banco Mundial no publica por separado).
-- Requiere: Lote 0.
EXEC torneo.consultar_api_banco_mundial;
SELECT TOP 10 codigo_iso, nombre, pbi_per_capita FROM torneo.pais ORDER BY pbi_per_capita DESC;
INSERT INTO #resultado SELECT '1.3', 'banco mundial: PBI per cápita 2020-2025',
       IIF(estado = 'completo' AND (SELECT COUNT(*) FROM torneo.pais WHERE pbi_per_capita > 0) >= 44
           AND (SELECT COUNT(DISTINCT anio) FROM torneo.indicador_economico) >= 3, 'OK', 'FALLO'),
       CONCAT((SELECT COUNT(*) FROM torneo.pais WHERE pbi_per_capita > 0), ' países con PBI')
FROM importacion.vw_ultimo_lote WHERE proceso = 'torneo.consultar_api_banco_mundial';
EXEC #informar '1.3';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 1.4 - Banco Mundial: serie histórica anterior (2015-2019)
-- -------------------------------------------------------------------------------------
PRINT '--- 1.4 Banco Mundial: serie histórica anterior (2015-2019)';
-- Resultado esperado: se importan los años 2015-2019 en torneo.indicador_economico sin pisar el PBI
-- vigente (más reciente) registrado en torneo.pais.
-- Requiere: Lote 0 (si no hay PBI vigente, lo importa antes).
EXEC #preparar 'pbi';
DECLARE @pbi_arg NUMERIC(12,2) = (SELECT pbi_per_capita FROM torneo.pais WHERE codigo_iso = 'ARG');
EXEC torneo.consultar_api_banco_mundial @anio_desde = 2015, @anio_hasta = 2019;
INSERT INTO #resultado SELECT '1.4', 'banco mundial: histórico 2015-2019 sin pisar el vigente',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios >= 200
           AND (SELECT pbi_per_capita FROM torneo.pais WHERE codigo_iso = 'ARG') = @pbi_arg
           AND EXISTS (SELECT 1 FROM torneo.indicador_economico i JOIN torneo.pais p ON p.pais_id = i.pais_id
                       WHERE p.codigo_iso = 'ARG' AND i.anio = 2015), 'OK', 'FALLO'),
       CONCAT(l.insertados + l.actualizados + l.sin_cambios, ' indicadores históricos')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.consultar_api_banco_mundial';
EXEC #informar '1.4';
GO

-- =====================================================================================
-- PARTE 2: SCRAPING DE WIKIPEDIA (imports/scraping/*.json)
-- =====================================================================================
PRINT '################ PARTE 2: SCRAPING DE WIKIPEDIA (imports/scraping/*.json) ################';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 2.1 - Sedes (sedes.json)
-- -------------------------------------------------------------------------------------
PRINT '--- 2.1 Sedes (sedes.json)';
-- Resultado esperado: las 16 sedes del torneo en 3 países, con 4 husos horarios distintos.
-- Requiere: Lote 0 y los archivos de entrega6_scraping.py.
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'scraping/sedes.json', @ruta OUTPUT;
EXEC torneo.importar_sedes @ruta;
SELECT s.nombre, s.ciudad, p.codigo_iso, s.capacidad, s.huso_horario FROM torneo.sede s
JOIN torneo.pais p ON p.pais_id = s.pais_id ORDER BY s.huso_horario, s.ciudad;
INSERT INTO #resultado SELECT '2.1', 'sedes: 16 sedes, 3 países, 4 husos',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 16
           AND (SELECT COUNT(*) FROM torneo.sede) = 16
           AND (SELECT COUNT(DISTINCT pais_id) FROM torneo.sede) = 3
           AND (SELECT COUNT(DISTINCT huso_horario) FROM torneo.sede) = 4, 'OK', 'FALLO'),
       CONCAT(l.insertados, ' insertadas, ', l.actualizados, ' actualizadas, ', l.sin_cambios, ' sin cambios')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_sedes';
EXEC #informar '2.1';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 2.2 - Selecciones (selecciones.json)
-- -------------------------------------------------------------------------------------
PRINT '--- 2.2 Selecciones (selecciones.json)';
-- Resultado esperado: 48 selecciones en 12 grupos de 4 y 6 confederaciones, con su tabla final:
-- España primera con 22 puntos (7 ganados, 1 empate).
-- Requiere: Lote 0 y los archivos de entrega6_scraping.py.
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'scraping/selecciones.json', @ruta OUTPUT;
EXEC torneo.importar_selecciones @ruta;
SELECT e.posicion_final, p.nombre, s.grupo, c.nombre AS confederacion, e.partidos, e.ganados, e.empatados,
       e.perdidos, e.goles_a_favor, e.goles_en_contra, e.puntos
FROM torneo.seleccion_estadistica e JOIN torneo.seleccion s ON s.seleccion_id = e.seleccion_id
JOIN torneo.pais p ON p.pais_id = s.pais_id JOIN torneo.confederacion c ON c.confederacion_id = s.confederacion_id
ORDER BY e.posicion_final, p.nombre;
INSERT INTO #resultado SELECT '2.2', 'selecciones: 48 en 12 grupos, con tabla final',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 48
           AND (SELECT COUNT(*) FROM torneo.seleccion) = 48
           AND NOT EXISTS (SELECT 1 FROM torneo.seleccion GROUP BY grupo HAVING COUNT(*) <> 4)
           AND (SELECT COUNT(DISTINCT confederacion_id) FROM torneo.seleccion) = 6
           AND (SELECT COUNT(*) FROM torneo.seleccion_estadistica) = 48
           AND EXISTS (SELECT 1 FROM torneo.seleccion_estadistica WHERE seleccion_id = importacion.fn_seleccion_id('ESP')
                       AND posicion_final = 1 AND puntos = 22), 'OK', 'FALLO'),
       CONCAT(l.insertados, ' insertadas, ', l.actualizados, ' actualizadas, ', l.sin_cambios, ' sin cambios')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_selecciones';
EXEC #informar '2.2';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 2.3 - Planteles (planteles.json)
-- -------------------------------------------------------------------------------------
PRINT '--- 2.3 Planteles (planteles.json)';
-- Resultado esperado: 26 convocados vigentes (mínimo exigido: 23) y el director técnico de cada selección.
-- Requiere: Lote 0 y los archivos de entrega6_scraping.py (si faltan las selecciones, las importa antes).
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'scraping/planteles.json', @ruta OUTPUT;
EXEC plantel.importar_planteles @ruta;
SELECT TOP 27 c.dorsal, j.nombre, j.apellido, j.posicion_habitual, j.fecha_nacimiento, j.club_origen
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = importacion.fn_seleccion_id('ARG') ORDER BY c.dorsal;
INSERT INTO #resultado SELECT '2.3', 'planteles: 23+ convocados y DT en cada selección',
       IIF(l.estado = 'completo'
           AND NOT EXISTS (SELECT 1 FROM torneo.seleccion s
                           WHERE (SELECT COUNT(*) FROM plantel.convocatoria c WHERE c.seleccion_id = s.seleccion_id AND c.fecha_baja IS NULL) < 23
                              OR NOT EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico ct WHERE ct.seleccion_id = s.seleccion_id AND ct.rol = 'director_tecnico')),
           'OK', 'FALLO'),
       CONCAT(l.insertados, ' insertados, ', l.sin_cambios, ' sin cambios, ', l.rechazados, ' rechazados')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_planteles';
EXEC #informar '2.3';
GO

-- =====================================================================================
-- PARTE 3: DATASETS EN ARCHIVOS (CSV, JSON Y XML)
-- =====================================================================================
PRINT '################ PARTE 3: DATASETS EN ARCHIVOS (CSV, JSON Y XML) ################';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 3.1 - Estadísticas de equipos (teams.csv, CSV)
-- -------------------------------------------------------------------------------------
PRINT '--- 3.1 Estadísticas de equipos (teams.csv, CSV)';
-- Resultado esperado: las 48 filas de teams.csv vinculadas a su selección del modelo.
-- Requiere: Lote 0 (si faltan las selecciones, las importa antes).
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'datasets/teams.csv', @ruta OUTPUT;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
SELECT TOP 10 k.pais_equipo, k.posesion, k.tiros, k.tiros_al_arco, k.amarillas, k.rojas, k.atajadas
FROM torneo.seleccion_estadistica_kaggle k ORDER BY k.goles DESC;
INSERT INTO #resultado SELECT '3.1', 'kaggle teams.csv: 48 selecciones vinculadas',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 48
           AND (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle) = 48, 'OK', 'FALLO'),
       CONCAT(l.insertados + l.actualizados + l.sin_cambios, ' selecciones')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026';
EXEC #informar '3.1';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 3.2 - Estadísticas de jugadores (players.csv, CSV)
-- -------------------------------------------------------------------------------------
PRINT '--- 3.2 Estadísticas de jugadores (players.csv, CSV)';
-- Resultado esperado: las 1248 filas, todas vinculadas a su selección y la gran mayoría a su jugador
-- (las que no coinciden por nombre, ej. 'Flaco López', quedan vinculadas sólo a la selección).
-- Requiere: Lote 0 (si faltan las selecciones o los planteles, los importa antes).
EXEC #preparar 'planteles';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'datasets/players.csv', @ruta OUTPUT;
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
SELECT TOP 10 k.jugador, k.pais_equipo, k.goles, k.asistencias, k.minutos, j.fecha_nacimiento
FROM plantel.jugador_estadistica_kaggle k LEFT JOIN plantel.jugador j ON j.jugador_id = k.jugador_id
ORDER BY k.goles DESC;
INSERT INTO #resultado SELECT '3.2', 'kaggle players.csv: estadísticas vinculadas al modelo',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 1248
           AND (SELECT COUNT(jugador_id) FROM plantel.jugador_estadistica_kaggle) >= 1100, 'OK', 'FALLO'),
       CONCAT((SELECT COUNT(jugador_id) FROM plantel.jugador_estadistica_kaggle), ' de 1248 vinculadas a un jugador')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
EXEC #informar '3.2';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 3.3 - Fixture y resultados (worldcup.json, JSON)
-- -------------------------------------------------------------------------------------
PRINT '--- 3.3 Fixture y resultados (worldcup.json, JSON)';
-- Resultado esperado: los 104 partidos del torneo finalizados con su resultado (alargue y penales incluidos);
-- la final, España 1 - Argentina 0.
-- Requiere: Lote 0 (si faltan las sedes o las selecciones, las importa antes).
EXEC #preparar 'sedes';
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'datasets/worldcup.json', @ruta OUTPUT;
EXEC torneo.importar_fixture @ruta;
SELECT fase, COUNT(*) AS partidos, SUM(IIF(estado = 'finalizado', 1, 0)) AS finalizados,
       SUM(IIF(penales_local IS NOT NULL, 1, 0)) AS por_penales
FROM torneo.partido GROUP BY fase ORDER BY MIN(fecha_hora_utc);
INSERT INTO #resultado SELECT '3.3', 'fixture worldcup.json: 104 partidos finalizados',
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 104
           AND (SELECT COUNT(*) FROM torneo.partido WHERE estado = 'finalizado') = 104
           AND EXISTS (SELECT 1 FROM torneo.partido p JOIN torneo.seleccion s ON s.seleccion_id = p.seleccion_local_id
                       JOIN torneo.pais x ON x.pais_id = s.pais_id
                       WHERE p.fase = 'final' AND x.codigo_iso = 'ESP' AND p.goles_local = 1 AND p.goles_visitante = 0),
           'OK', 'FALLO'),
       CONCAT(l.insertados + l.actualizados + l.sin_cambios, ' partidos')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_fixture';
EXEC #informar '3.3';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 3.4 - Tarifario publicitario (tarifas_publicidad.xml, XML con conversión de monedas a USD)
-- -------------------------------------------------------------------------------------
PRINT '--- 3.4 Tarifario publicitario (tarifas_publicidad.xml, XML con conversión de monedas a USD)';
-- Resultado esperado: 30 piezas publicitarias convertidas a USD con las cotizaciones de publicidad.tipo_cambio
-- importadas desde Frankfurter (ej. la pieza de Coca-Cola en España de 26000 EUR).
-- Requiere: Lote 0 (si faltan las cotizaciones, las importa antes).
EXEC #preparar 'cambios';
DECLARE @ruta VARCHAR(500), @esperado NUMERIC(12,2);
EXEC #ruta 'datasets/tarifas_publicidad.xml', @ruta OUTPUT;
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
       IIF(l.estado = 'completo' AND l.insertados + l.actualizados + l.sin_cambios = 30
           AND EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                       JOIN torneo.pais p ON p.pais_id = pz.pais_mercado_id
                       WHERE c.nombre = 'Conferencia' AND p.codigo_iso = 'ESP' AND pz.costo_tarifa = @esperado)
           AND EXISTS (SELECT 1 FROM publicidad.anunciante WHERE nombre = 'Emirates'), 'OK', 'FALLO'),
       CONCAT('30 piezas, ESP = USD ', @esperado)
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'publicidad.importar_tarifas';
EXEC #informar '3.4';
GO

-- =====================================================================================
-- PARTE 4: REIMPORTACIÓN SIN DUPLICADOS
-- =====================================================================================
PRINT '################ PARTE 4: REIMPORTACIÓN SIN DUPLICADOS ################';
GO

-- Cada prueba importa el archivo una vez (deja la base igual al archivo) y lo vuelve a importar: la segunda
-- importación no da de alta ni modifica nada y la tabla queda con la misma cantidad de filas.

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.1 - Reimportación de sedes
-- -------------------------------------------------------------------------------------
PRINT '--- 4.1 Reimportación de sedes';
-- Resultado esperado: la segunda importación deja las 16 sedes sin cambios.
-- Requiere: Lote 0.
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'scraping/sedes.json', @ruta OUTPUT;
EXEC torneo.importar_sedes @ruta;
SET @antes = (SELECT COUNT(*) FROM torneo.sede);
EXEC torneo.importar_sedes @ruta;
INSERT INTO #resultado SELECT '4.1', 'reimportación de sedes: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 16
           AND (SELECT COUNT(*) FROM torneo.sede) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM torneo.sede))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_sedes';
EXEC #informar '4.1';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.2 - Reimportación de selecciones
-- -------------------------------------------------------------------------------------
PRINT '--- 4.2 Reimportación de selecciones';
-- Resultado esperado: la segunda importación deja las 48 selecciones sin cambios.
-- Requiere: Lote 0.
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'scraping/selecciones.json', @ruta OUTPUT;
EXEC torneo.importar_selecciones @ruta;
SET @antes = (SELECT COUNT(*) FROM torneo.seleccion);
EXEC torneo.importar_selecciones @ruta;
INSERT INTO #resultado SELECT '4.2', 'reimportación de selecciones: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 48
           AND (SELECT COUNT(*) FROM torneo.seleccion) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM torneo.seleccion))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_selecciones';
EXEC #informar '4.2';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.3 - Reimportación de planteles
-- -------------------------------------------------------------------------------------
PRINT '--- 4.3 Reimportación de planteles';
-- Resultado esperado: la segunda importación no da de alta, de baja ni modifica jugadores, convocatorias ni DT.
-- Requiere: Lote 0 (si faltan las selecciones, las importa antes).
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500), @antes VARCHAR(50);
EXEC #ruta 'scraping/planteles.json', @ruta OUTPUT;
EXEC plantel.importar_planteles @ruta;
SET @antes = CONCAT((SELECT COUNT(*) FROM plantel.jugador), '/', (SELECT COUNT(*) FROM plantel.convocatoria), '/',
                    (SELECT COUNT(*) FROM plantel.cuerpo_tecnico));
EXEC plantel.importar_planteles @ruta;
INSERT INTO #resultado SELECT '4.3', 'reimportación de planteles: sin altas, bajas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0
           AND CONCAT((SELECT COUNT(*) FROM plantel.jugador), '/', (SELECT COUNT(*) FROM plantel.convocatoria), '/',
                      (SELECT COUNT(*) FROM plantel.cuerpo_tecnico)) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; jugadores/convocatorias/DT: ', @antes)
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_planteles';
EXEC #informar '4.3';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.4 - Reimportación de teams.csv
-- -------------------------------------------------------------------------------------
PRINT '--- 4.4 Reimportación de teams.csv';
-- Resultado esperado: la segunda importación deja las 48 filas sin cambios.
-- Requiere: Lote 0 (si faltan las selecciones, las importa antes).
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'datasets/teams.csv', @ruta OUTPUT;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
SET @antes = (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle);
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
INSERT INTO #resultado SELECT '4.4', 'reimportación de teams.csv: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 48
           AND (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM torneo.seleccion_estadistica_kaggle))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026';
EXEC #informar '4.4';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.5 - Reimportación de players.csv
-- -------------------------------------------------------------------------------------
PRINT '--- 4.5 Reimportación de players.csv';
-- Resultado esperado: la segunda importación deja las 1248 filas sin cambios.
-- Requiere: Lote 0 (si faltan las selecciones o los planteles, los importa antes).
EXEC #preparar 'planteles';
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'datasets/players.csv', @ruta OUTPUT;
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
SET @antes = (SELECT COUNT(*) FROM plantel.jugador_estadistica_kaggle);
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
INSERT INTO #resultado SELECT '4.5', 'reimportación de players.csv: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 1248
           AND (SELECT COUNT(*) FROM plantel.jugador_estadistica_kaggle) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM plantel.jugador_estadistica_kaggle))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
EXEC #informar '4.5';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.6 - Reimportación de worldcup.json
-- -------------------------------------------------------------------------------------
PRINT '--- 4.6 Reimportación de worldcup.json';
-- Resultado esperado: la segunda importación deja los 104 partidos sin cambios.
-- Requiere: Lote 0 (si faltan las sedes o las selecciones, las importa antes).
EXEC #preparar 'sedes';
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'datasets/worldcup.json', @ruta OUTPUT;
EXEC torneo.importar_fixture @ruta;
SET @antes = (SELECT COUNT(*) FROM torneo.partido);
EXEC torneo.importar_fixture @ruta;
INSERT INTO #resultado SELECT '4.6', 'reimportación de worldcup.json: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 104
           AND (SELECT COUNT(*) FROM torneo.partido) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM torneo.partido))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_fixture';
EXEC #informar '4.6';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 4.7 - Reimportación de tarifas_publicidad.xml
-- -------------------------------------------------------------------------------------
PRINT '--- 4.7 Reimportación de tarifas_publicidad.xml';
-- Resultado esperado: la segunda importación deja las 30 piezas sin cambios.
-- Requiere: Lote 0 (si faltan las cotizaciones, las importa antes).
EXEC #preparar 'cambios';
DECLARE @ruta VARCHAR(500), @antes INT;
EXEC #ruta 'datasets/tarifas_publicidad.xml', @ruta OUTPUT;
EXEC publicidad.importar_tarifas @ruta;
SET @antes = (SELECT COUNT(*) FROM publicidad.pieza_publicitaria);
EXEC publicidad.importar_tarifas @ruta;
INSERT INTO #resultado SELECT '4.7', 'reimportación de tarifas XML: sin altas ni cambios',
       IIF(l.insertados + l.actualizados + l.rechazados = 0 AND l.sin_cambios = 30
           AND (SELECT COUNT(*) FROM publicidad.pieza_publicitaria) = @antes, 'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios; filas: ', @antes, ' -> ', (SELECT COUNT(*) FROM publicidad.pieza_publicitaria))
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'publicidad.importar_tarifas';
EXEC #informar '4.7';
GO

-- =====================================================================================
-- PARTE 5: ERRORES PARCIALES Y RECHAZOS
-- =====================================================================================
PRINT '################ PARTE 5: ERRORES PARCIALES Y RECHAZOS ################';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.1 - teams_con_errores.csv (importación parcial CSV de selecciones)
-- -------------------------------------------------------------------------------------
PRINT '--- 5.1 teams_con_errores.csv (importación parcial CSV de selecciones)';
-- 5 filas: Argentina con 99 goles (se actualiza), España igual a la importada (sin cambios), un país vacío,
-- un dato numérico inválido con goles negativos y un país sin selección ('Atlantis').
-- Resultado esperado: 1 actualizada, 1 sin cambios, 3 rechazadas con su motivo.
-- Requiere: Lote 0 (importa antes teams.csv, para partir de los datos originales).
EXEC #preparar 'selecciones';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'datasets/teams.csv', @ruta OUTPUT;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
EXEC #ruta 'con_errores/teams_con_errores.csv', @ruta OUTPUT;
EXEC torneo.importar_estadisticas_equipos_kaggle_2026 @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id
WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.1', 'kaggle teams CSV: importación parcial',
       IIF(l.estado = 'parcial' AND l.actualizados = 1 AND l.sin_cambios = 1 AND l.rechazados = 3
           AND (SELECT goles FROM torneo.seleccion_estadistica_kaggle WHERE pais_equipo = 'Argentina') = 99, 'OK', 'FALLO'),
       CONCAT(l.actualizados, ' actualizada, ', l.sin_cambios, ' sin cambios, ', l.rechazados, ' rechazadas')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_estadisticas_equipos_kaggle_2026';
EXEC #informar '5.1';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.2 - players_con_errores.csv (importación parcial CSV de jugadores)
-- -------------------------------------------------------------------------------------
PRINT '--- 5.2 players_con_errores.csv (importación parcial CSV de jugadores)';
-- 5 filas: Messi con otros goles (se actualiza), una fila igual a la importada (sin cambios), un nombre vacío,
-- un dato numérico inválido y un país sin selección.
-- Resultado esperado: 1 actualizada, 1 sin cambios, 3 rechazadas con su motivo.
-- Requiere: Lote 0 (importa antes players.csv, para partir de los datos originales).
EXEC #preparar 'planteles';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'datasets/players.csv', @ruta OUTPUT;
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
EXEC #ruta 'con_errores/players_con_errores.csv', @ruta OUTPUT;
EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id
WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.2', 'kaggle players CSV: importación parcial',
       IIF(l.estado = 'parcial' AND l.actualizados = 1 AND l.sin_cambios = 1 AND l.rechazados = 3
           AND (SELECT goles FROM plantel.jugador_estadistica_kaggle WHERE jugador = 'Lionel Messi') = 99, 'OK', 'FALLO'),
       CONCAT(l.actualizados, ' actualizada, ', l.sin_cambios, ' sin cambios, ', l.rechazados, ' rechazadas')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
EXEC #informar '5.2';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.3 - worldcup_con_errores.json (importación parcial JSON)
-- -------------------------------------------------------------------------------------
PRINT '--- 5.3 worldcup_con_errores.json (importación parcial JSON)';
-- 5 partidos: uno igual al registrado (sin cambios), el mismo con otro resultado (un partido finalizado no se
-- reescribe), una selección inexistente, hora y sede inválidas, y ronda/fecha inválidas.
-- Resultado esperado: 1 sin cambios, 4 rechazados; México - Sudáfrica sigue 2 a 0.
-- Requiere: Lote 0 (si falta el fixture, lo importa antes).
EXEC #preparar 'fixture';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'con_errores/worldcup_con_errores.json', @ruta OUTPUT;
EXEC torneo.importar_fixture @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id WHERE l.proceso = 'torneo.importar_fixture' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.3', 'fixture JSON: importación parcial, finalizado no se reescribe',
       IIF(l.estado = 'parcial' AND l.sin_cambios = 1 AND l.rechazados = 4
           AND EXISTS (SELECT 1 FROM torneo.partido p WHERE p.seleccion_local_id = importacion.fn_seleccion_id('MEX')
                       AND p.seleccion_visitante_id = importacion.fn_seleccion_id('ZAF') AND p.goles_local = 2 AND p.goles_visitante = 0),
           'OK', 'FALLO'),
       CONCAT(l.sin_cambios, ' sin cambios, ', l.rechazados, ' rechazados')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_fixture';
EXEC #informar '5.3';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.4 - tarifas_con_errores.xml (importación parcial XML)
-- -------------------------------------------------------------------------------------
PRINT '--- 5.4 tarifas_con_errores.xml (importación parcial XML)';
-- 5 piezas: ARS sin cotización, tarifa 'abc', mercado XXX, Brasil fuera de los países de interés (lo rechaza
-- publicidad.pieza_publicitaria_insertar, 50001) y una válida en EUR para Uruguay (convertida a USD).
-- Resultado esperado: la de Uruguay queda registrada (insertada, o sin cambios si ya estaba) y 4 rechazadas.
-- Requiere: Lote 0 (si faltan las cotizaciones o el tarifario, los importa antes).
EXEC #preparar 'tarifas';
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'con_errores/tarifas_con_errores.xml', @ruta OUTPUT;
EXEC publicidad.importar_tarifas @ruta;
SELECT e.fila, e.registro, e.numero_error, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id WHERE l.proceso = 'publicidad.importar_tarifas' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.4', 'tarifas XML: importación parcial y validación Entrega 5',
       IIF(l.estado = 'parcial' AND l.insertados + l.sin_cambios = 1 AND l.rechazados = 4
           AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.motivo LIKE '%ARS%')
           AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.numero_error = 50001), 'OK', 'FALLO'),
       CONCAT(l.insertados + l.sin_cambios, ' registrada, ', l.rechazados, ' rechazadas')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'publicidad.importar_tarifas';
EXEC #informar '5.4';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.5 - sedes_con_errores.json (importación parcial de datos de scraping)
-- -------------------------------------------------------------------------------------
PRINT '--- 5.5 sedes_con_errores.json (importación parcial de datos de scraping)';
-- 5 sedes con el formato de imports/scraping/sedes.json: Estadio Azteca igual a la importada (sin cambios),
-- MetLife con otra capacidad (se actualiza), un país inexistente, una capacidad no numérica y una ciudad sin huso.
-- Resultado esperado: 1 actualizada, 1 sin cambios, 3 rechazadas con su motivo.
-- Requiere: Lote 0 (importa antes sedes.json, para partir de los datos originales).
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'scraping/sedes.json', @ruta OUTPUT;
EXEC torneo.importar_sedes @ruta;
EXEC #ruta 'con_errores/sedes_con_errores.json', @ruta OUTPUT;
EXEC torneo.importar_sedes @ruta;
SELECT e.fila, e.registro, e.motivo FROM importacion.error e
JOIN importacion.vw_ultimo_lote l ON l.lote_id = e.lote_id WHERE l.proceso = 'torneo.importar_sedes' ORDER BY e.fila;
INSERT INTO #resultado SELECT '5.5', 'sedes de scraping: importación parcial',
       IIF(l.estado = 'parcial' AND l.actualizados = 1 AND l.sin_cambios = 1 AND l.rechazados = 3
           AND (SELECT capacidad FROM torneo.sede WHERE nombre = 'MetLife Stadium') = 82500, 'OK', 'FALLO'),
       CONCAT(l.actualizados, ' actualizada, ', l.sin_cambios, ' sin cambios, ', l.rechazados, ' rechazadas')
FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'torneo.importar_sedes';
EXEC #informar '5.5';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.6 - Archivo inexistente
-- -------------------------------------------------------------------------------------
PRINT '--- 5.6 Archivo inexistente';
-- Resultado esperado: THROW 50003 con la ruta en el mensaje; el lote queda rechazado y con su error.
-- Requiere: Lote 0.
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'no_existe.csv', @ruta OUTPUT;
BEGIN TRY
    EXEC plantel.importar_estadisticas_jugadores_kaggle_2026 @ruta;
    INSERT INTO #resultado VALUES ('5.6', 'archivo inexistente', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado SELECT '5.6', 'archivo inexistente',
           IIF(ERROR_NUMBER() = 50003 AND l.estado = 'rechazado'
               AND EXISTS (SELECT 1 FROM importacion.error e WHERE e.lote_id = l.lote_id AND e.fila IS NULL), 'OK', 'FALLO'),
           ERROR_MESSAGE()
    FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_estadisticas_jugadores_kaggle_2026';
END CATCH;
EXEC #informar '5.6';
GO

-- -------------------------------------------------------------------------------------
-- PRUEBA 5.7 - Archivo de scraping sin planteles
-- -------------------------------------------------------------------------------------
PRINT '--- 5.7 Archivo de scraping sin planteles';
-- Se importa sedes.json como si fuera el archivo de planteles.
-- Resultado esperado: THROW 50003 (no trae el arreglo "planteles"); no se procesa ninguna fila y el lote queda rechazado.
-- Requiere: Lote 0 y los archivos de entrega6_scraping.py.
DECLARE @ruta VARCHAR(500);
EXEC #ruta 'scraping/sedes.json', @ruta OUTPUT;
BEGIN TRY
    EXEC plantel.importar_planteles @ruta;
    INSERT INTO #resultado VALUES ('5.7', 'archivo de scraping sin planteles', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado SELECT '5.7', 'archivo de scraping sin planteles',
           IIF(ERROR_NUMBER() = 50003 AND l.estado = 'rechazado' AND l.leidos = 0, 'OK', 'FALLO'), ERROR_MESSAGE()
    FROM importacion.vw_ultimo_lote l WHERE l.proceso = 'plantel.importar_planteles';
END CATCH;
EXEC #informar '5.7';
GO

-- =====================================================================================
-- RESUMEN
-- =====================================================================================
PRINT '################ RESUMEN ################';
-- Todos los lotes ejecutados, con sus contadores, y el resultado de las pruebas.
-- Resultado esperado: todas las pruebas en OK y ninguna en FALLO.
SELECT lote_id, proceso, origen, leidos, insertados, actualizados, sin_cambios, rechazados, estado
FROM importacion.lote ORDER BY lote_id;
-- Una prueba sin resultado no se ejecutó o su lote se cortó por un error no previsto (ver Mensajes).
DECLARE @sin_resultado VARCHAR(200) = (
            SELECT STRING_AGG(p.prueba, ', ') WITHIN GROUP (ORDER BY p.orden)
            FROM (VALUES (1, '1.1'), (2, '1.2'), (3, '1.3'), (4, '1.4'), (5, '2.1'), (6, '2.2'), (7, '2.3'),
                         (8, '3.1'), (9, '3.2'), (10, '3.3'), (11, '3.4'), (12, '4.1'), (13, '4.2'), (14, '4.3'),
                         (15, '4.4'), (16, '4.5'), (17, '4.6'), (18, '4.7'), (19, '5.1'), (20, '5.2'), (21, '5.3'),
                         (22, '5.4'), (23, '5.5'), (24, '5.6'), (25, '5.7')) p (orden, prueba)
            WHERE NOT EXISTS (SELECT 1 FROM #resultado r WHERE r.prueba = p.prueba)),
        @ok INT = (SELECT COUNT(*) FROM #resultado WHERE resultado = 'OK'),
        @fallo INT = (SELECT COUNT(*) FROM #resultado WHERE resultado <> 'OK');
PRINT CONCAT('TOTAL: ', @ok, ' OK, ', @fallo, ' FALLO', IIF(@sin_resultado IS NULL, '', '; sin resultado: ' + @sin_resultado));
SELECT orden, prueba, descripcion, resultado, detalle FROM #resultado ORDER BY orden;
IF @fallo > 0
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, descripcion, detalle FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE IF @sin_resultado IS NULL
    PRINT 'Todas las pruebas finalizaron con el resultado esperado.';
GO

SET NOEXEC OFF;
GO
